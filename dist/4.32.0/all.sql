/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-8158 - Start

CREATE OR REPLACE FUNCTION siac.fnc_dba_add_check_constraint (
	table_in text,
	constraint_in text,
	check_definition text
)
RETURNS text AS
$body$
DECLARE
	table_in_trunc text;
	constraint_in_trunc text;

	query_in text;
	esito text;
BEGIN
	esito := '';

	table_in_trunc := table_in;
	IF LENGTH(table_in_trunc) > 63 THEN
		table_in_trunc := LEFT(table_id, 63);
		esito := esito || '- TRUNCATE table_in TO ' || table_in_trunc;
	END IF;
	
	constraint_in_trunc := constraint_in;
	IF LENGTH(constraint_in_trunc) > 63 THEN
		constraint_in_trunc := LEFT(constraint_in, 63);
		esito := esito || '- TRUNCATE constraint_in TO ' || constraint_in_trunc;
	END IF;
 	
	SELECT 'ALTER TABLE ' || table_in_trunc || ' ADD CONSTRAINT ' || constraint_in_trunc || ' CHECK (' || check_definition || ');'
	INTO query_in
	WHERE NOT EXISTS (
		SELECT 1
		FROM information_schema.check_constraints
		WHERE constraint_name = constraint_in_trunc
	);
	IF query_in IS NOT NULL THEN
		esito := esito || '- check contraint creato';
		EXECUTE query_in;
	ELSE
		esito := '- check contraint ' || constraint_in_trunc || ' gia'' presente';
	END IF;
	
	RETURN esito;

	EXCEPTION
		WHEN RAISE_EXCEPTION THEN
			esito := esito || '- raise_exception - ' || substring(upper(SQLERRM) from 1 for 2500);
			RETURN esito;
		WHEN others THEN
			esito := esito || '- others - ' ||substring(upper(SQLERRM) from 1 for 2500);
			RETURN esito;
	END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION siac.fnc_dba_add_column_params (
	table_in text,
	field_in text,
	data_type_in text
)
RETURNS text AS
$body$
DECLARE
	table_in_trunc text;
	field_in_trunc text;

	query_in text;
	esito text;
BEGIN
	esito := '';

	table_in_trunc := table_in;
	IF LENGTH(table_in_trunc) > 63 THEN
		table_in_trunc := LEFT(table_in, 63);
		esito := esito || '- TRUNCATE table_in TO ' || table_in_trunc;
	END IF;
	
	field_in_trunc := field_in;
	IF LENGTH(field_in_trunc) > 63 THEN
		field_in_trunc := LEFT(field_in, 63);
		esito := esito || '- TRUNCATE field_in TO ' || field_in_trunc;
	END IF;

	SELECT 'ALTER TABLE ' || table_in_trunc || ' ADD COLUMN ' || field_in_trunc || ' ' || data_type_in || ';'
	INTO query_in
	WHERE NOT EXISTS (
		SELECT 1
		FROM information_schema.columns
		WHERE table_name = table_in_trunc
		AND column_name = field_in_trunc
	);

	IF query_in IS NOT NULL THEN
		esito := esito || '- colonna creata';
		execute query_in;
	ELSE
		esito := esito || '- colonna ' || table_in_trunc || '.' || field_in_trunc || ' gia'' presente';
	END IF;

	RETURN esito;
	EXCEPTION
		WHEN RAISE_EXCEPTION THEN
			esito := esito || '- raise_exception - ' || substring(upper(SQLERRM) from 1 for 2500);
			RETURN esito;
		WHEN others THEN
			esito := esito || '- others - ' ||substring(upper(SQLERRM) from 1 for 2500);
			RETURN esito;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION fnc_dba_add_fk_constraint (
	table_in text,
	constraint_in text,
	column_in text,
	table_ref text,
	column_ref text
)
RETURNS text AS
$body$
DECLARE
	table_in_trunc text;
	constraint_in_trunc text;
	column_in_trunc text;
	table_ref_trunc text;
	column_ref_trunc text;

	query_in text;
	esito text;
BEGIN
	esito := '';

	table_in_trunc := table_in;
	IF LENGTH(table_in_trunc) > 63 THEN
		table_in_trunc := LEFT(table_in, 63);
		esito := esito || '- TRUNCATE table_in TO ' || table_in_trunc;
	END IF;

	constraint_in_trunc := constraint_in;
	IF LENGTH(constraint_in_trunc) > 63 THEN
		constraint_in_trunc := LEFT(constraint_in, 63);
		esito := esito || '- TRUNCATE constraint_in TO ' || constraint_in_trunc;
	END IF;

	column_in_trunc := column_in;
	IF LENGTH(column_in_trunc) > 63 THEN
		column_in_trunc := LEFT(column_in, 63);
		esito := esito || '- TRUNCATE column_in TO ' || column_in_trunc;
	END IF;

	table_ref_trunc := table_ref;
	IF LENGTH(table_ref_trunc) > 63 THEN
		table_ref_trunc := LEFT(table_ref, 63);
		esito := esito || '- TRUNCATE table_ref TO ' || table_ref_trunc;
	END IF;

	column_ref_trunc := column_ref;
	IF LENGTH(column_ref_trunc) > 63 THEN
		column_ref_trunc := LEFT(column_ref, 63);
		esito := esito || '- TRUNCATE column_ref TO ' || column_ref_trunc;
	END IF;

	SELECT  'ALTER TABLE ' || table_in_trunc || ' ADD CONSTRAINT ' || constraint_in_trunc || ' FOREIGN KEY (' || column_in_trunc ||') ' ||
		' REFERENCES ' || table_ref_trunc || '(' || column_ref_trunc || ') ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE'
	INTO query_in
	WHERE NOT EXISTS (
		SELECT 1
		FROM information_schema.table_constraints tc
		WHERE tc.constraint_schema = 'siac'
		AND tc.table_schema = 'siac'
		AND tc.constraint_type = 'FOREIGN KEY'
		AND tc.table_name = table_in_trunc
		AND tc.constraint_name = constraint_in_trunc
	);
	
	IF query_in IS NOT NULL THEN
		esito := esito || '- fk constraint creato';
		execute query_in;
	ELSE
		esito := esito || '- fk constraint ' || constraint_in_trunc || ' gia'' presente';
	END IF;

	RETURN esito;
	EXCEPTION
		WHEN RAISE_EXCEPTION THEN
			esito := esito || '- raise_exception - ' || substring(upper(SQLERRM) from 1 for 2500);
			RETURN esito;
		WHEN others THEN
			esito := esito || '- others - ' ||substring(upper(SQLERRM) from 1 for 2500);
			RETURN esito;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION siac.fnc_dba_create_index (
	table_in text,
	index_in text,
	index_columns_in text,
	index_where_def_in text,
	index_unique_in boolean
)
RETURNS text AS
$body$
DECLARE
	table_in_trunc text;
	index_in_trunc text;

	query_var text;
	query_to_exe text;
	esito text;
BEGIN
	esito := '';

	table_in_trunc := table_in;
	IF LENGTH(table_in_trunc) > 63 THEN
		table_in_trunc := LEFT(table_id, 63);
		esito := esito || '- TRUNCATE table_in TO ' || table_in_trunc;
	END IF;

	index_in_trunc := index_in;
	IF LENGTH(index_in_trunc) > 63 THEN
		index_in_trunc := LEFT(index_in, 63);
		esito := esito || '- TRUNCATE index_in TO ' || index_in_trunc;
	END IF;

	query_var:= 'CREATE '
		|| (CASE WHEN index_unique_in = true THEN 'UNIQUE ' ELSE ' ' END)
		|| 'INDEX '
		|| index_in_trunc || ' ON ' || table_in_trunc || ' USING BTREE ( ' || index_columns_in || ' )'
		|| (CASE WHEN COALESCE(index_where_def_in, '') != '' THEN ' WHERE ( ' || index_where_def_in || ' );' ELSE ';' END);
	-- raise notice 'query_var=%',query_var;

	SELECT query_var
	INTO query_to_exe
	WHERE NOT EXISTS (
		SELECT 1
		FROM pg_class pg
		WHERE pg.relname = index_in
		and pg.relkind = 'i'
	);

	IF query_to_exe IS NOT NULL THEN
		esito := esito || '- indice creato';
		execute query_to_exe;
	ELSE
		esito := esito || '- indice ' || index_in_trunc || ' gia'' presente';
	END IF;
	
	RETURN esito;
	EXCEPTION
		WHEN RAISE_EXCEPTION THEN
			esito := esito || '- raise_exception - ' || substring(upper(SQLERRM) from 1 for 2500);
			RETURN esito;
		WHEN others THEN
			esito := esito || '- others - ' ||substring(upper(SQLERRM) from 1 for 2500);
			RETURN esito;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- SIAC-8158 - End

-- 16.04.2021 Sofia SIAC-8163 - inizio
drop FUNCTION if exists siac.fnc_pagopa_t_elaborazione_riconc
(
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out outpagopaelabid integer,
  out outpagopaelabprecid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);
CREATE OR REPLACE FUNCTION siac.fnc_pagopa_t_elaborazione_riconc (
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out outpagopaelabid integer,
  out outpagopaelabprecid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(2500):=''; -- 09.10.2019 Sofia
    strMessaggioBck  VARCHAR(2500):=''; -- 09.10.2019 Sofia
	strMessaggioFinale VARCHAR(1500):='';
	strErrore VARCHAR(1500):='';
	strMessaggioLog VARCHAR(2500):='';

	codResult integer:=null;
	annoBilancio integer:=null;
    annoBilancio_ini integer:=null;

    filePagoPaElabId integer:=null;
    filePagoPaElabPrecId integer:=null;

    elabRec record;
    elabResRec record;
    annoRec record;
    elabEsecResRec record;

    -- file XML caricato correttamente pronto x elaborazione
	ACQUISITO_ST              CONSTANT  varchar :='ACQUISITO';
    -- file XML caricato correttamente, elaborazione in corso, flussi in fase di elaborazione
    ELABORATO_IN_CORSO_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO'; -- senza errori  e scarti
    ELABORATO_IN_CORSO_ER_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_ER';  -- con errori
    ELABORATO_IN_CORSO_SC_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_SC'; -- con scarti


	ESERCIZIO_PROVVISORIO_ST CONSTANT  varchar :='E'; -- esercizio provvisorio
    ESERCIZIO_GESTIONE_ST    CONSTANT  varchar :='G'; -- esercizio gestione
	-- 18.01.2021 Sofia jira SIAC-7962
	ESERCIZIO_CONSUNTIVO_ST    CONSTANT  varchar :='O'; -- esercizio consuntivo

	---- 28.10.2020 Sofia SIAC-7672
    elabSvecchiaRec record;
BEGIN

	strMessaggioFinale:='Elaborazione PAGOPA.';
    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc - '||strMessaggioFinale;
    raise notice 'strMessaggioLog=%',strMessaggioLog;

	insert into pagopa_t_elaborazione_log
    (
     pagopa_elab_id,
     pagopa_elab_log_operazione,
     ente_proprietario_id,
     login_operazione,
     data_creazione
    )
    values
    (
     null,
     strMessaggioLog,
	 enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );

   	outPagoPaElabId:=null;
    outPagoPaElabPrecId:=null;
    codiceRisultato:=0;
    messaggioRisultato:='';

    strMessaggio:='Verifica esistenza elaborazione acquisita, in corso.';
    select 1 into codResult
    from pagopa_t_elaborazione pagopa, pagopa_d_elaborazione_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and   stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_ER_ST,ELABORATO_IN_CORSO_SC_ST)
    and   pagopa.pagopa_elab_stato_id=stato.pagopa_elab_stato_id
    and   pagopa.data_cancellazione is null
    and   pagopa.validita_fine is null;
    if codResult is not null then
         outPagoPaElabId:=-1;
         outPagoPaElabPrecId:=-1;
         messaggioRisultato:=upper(strMessaggioFinale||' Elaborazione acquisita, in corso esistente.');
         strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc - '||messaggioRisultato;
	     insert into pagopa_t_elaborazione_log
         (
     		pagopa_elab_id,
		    pagopa_elab_log_operazione,
		    ente_proprietario_id,
		    login_operazione,
            data_creazione
	     )
	     values
	     (
	      null,
	      strMessaggioLog,
	 	  enteProprietarioId,
     	  loginOperazione,
          clock_timestamp()
    	 );

         codiceRisultato:=-1;
    	 return;
    end if;




    annoBilancio:=extract('YEAR' from now())::integer;
    annoBilancio_ini:=annoBilancio;
    strMessaggio:='Verifica fase bilancio annoBilancio-1='||(annoBilancio-1)::varchar||'.';
    select 1 into codResult
    from siac_t_bil bil,siac_t_periodo per,
         siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
    where per.ente_proprietario_id=enteProprietarioid
    and   per.anno::integer=annoBilancio-1
    and   bil.periodo_id=per.periodo_id
    and   r.bil_id=bil.bil_id
    and   fase.fase_operativa_id=r.fase_operativa_id
     and   fase.fase_operativa_id=r.fase_operativa_id
    -- 18.01.2021 Sofia jira SIAC-7962
--    and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST);
    and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST,ESERCIZIO_CONSUNTIVO_ST);
    if codResult is not null then
    	annoBilancio_ini:=annoBilancio-1;
    end if;


    strMessaggio:='Verifica esistenza file da elaborare.';
    select 1 into codResult
    from siac_t_file_pagopa pagopa, siac_d_file_pagopa_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and   stato.file_pagopa_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
    and   pagopa.file_pagopa_stato_id=stato.file_pagopa_stato_id
    and   pagopa.file_pagopa_anno in (annoBilancio_ini,annoBilancio)
    and   pagopa.data_cancellazione is null
    and   pagopa.validita_fine is null;
    if codResult is null then
           outPagoPaElabId:=-1;
           outPagoPaElabPrecId:=-1;
           messaggioRisultato:=upper(strMessaggioFinale||' File da elaborare non esistenti.');
           codiceRisultato:=-1;
           strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc - '||messaggioRisultato;
	       insert into pagopa_t_elaborazione_log
           (
     		pagopa_elab_id,
		    pagopa_elab_log_operazione,
		    ente_proprietario_id,
		    login_operazione,
            data_creazione
	       )
	       values
	       (
	        null,
	        strMessaggioLog,
	 	    enteProprietarioId,
     	    loginOperazione,
            clock_timestamp()
    	   );

           return;
    end if;

   codResult:=null;
   strMessaggio:='Inizio elaborazioni anni.';
   strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc - '||strMessaggioFinale||strMessaggio;
   raise notice 'strMessaggioLog=%',strMessaggioLog;
   insert into pagopa_t_elaborazione_log
   (
      pagopa_elab_id,
      pagopa_elab_log_operazione,
      ente_proprietario_id,
      login_operazione,
      data_creazione
   )
   values
   (
    null,
    strMessaggioLog,
    enteProprietarioId,
    loginOperazione,
    clock_timestamp()
   );

   for annoRec in
   (
    select *
    from
   	(select annoBilancio_ini anno_elab
     union
     select annoBilancio anno_elab
    ) query
    where codiceRisultato=0
    order by 1
   )
   loop

    if annoRec.anno_elab>annoBilancio_ini then
    	filePagoPaElabPrecId:=filePagoPaElabId;
    end if;
    filePagoPaElabId:=null;
    strMessaggio:='Inizio elaborazione file PAGOPA per annoBilancio='||annoRec.anno_elab::varchar||'.';
    strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc - '||strMessaggioFinale||strMessaggio;
    raise notice 'strMessaggioLog=%',strMessaggioLog;
    insert into pagopa_t_elaborazione_log
    (
      pagopa_elab_id,
      pagopa_elab_log_operazione,
      ente_proprietario_id,
      login_operazione,
      data_creazione
    )
    values
    (
     null,
     strMessaggioLog,
     enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );

    for  elabRec in
    (
      select pagopa.*
      from siac_t_file_pagopa pagopa, siac_d_file_pagopa_stato stato
      where stato.ente_proprietario_id=enteProprietarioId
      and   stato.file_pagopa_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
      and   pagopa.file_pagopa_stato_id=stato.file_pagopa_stato_id
      and   pagopa.file_pagopa_anno=annoRec.anno_elab
      and   pagopa.data_cancellazione is null
      and   pagopa.validita_fine is null
      and   codiceRisultato=0
      order by pagopa.file_pagopa_id
    )
    loop
       strMessaggio:='Elaborazione File PAGOPA ID='||elabRec.file_pagopa_id||' Identificativo='||coalesce(elabRec.file_pagopa_code,' ')
                      ||' annoBilancio='||annoRec.anno_elab::varchar||'.';

       strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc - '||strMessaggioFinale||strMessaggio;
       raise notice '1strMessaggioLog=%',strMessaggioLog;
	   insert into pagopa_t_elaborazione_log
   	   (
	      pagopa_elab_id,
          pagopa_elab_file_id,
    	  pagopa_elab_log_operazione,
	      ente_proprietario_id,
    	  login_operazione,
          data_creazione
	   )
	   values
	   (
    	null,
        elabRec.file_pagopa_id,
	    strMessaggioLog,
	    enteProprietarioId,
	    loginOperazione,
        clock_timestamp()
	   );
       raise notice '2strMessaggioLog=%',strMessaggioLog;

       select * into elabResRec
       from fnc_pagopa_t_elaborazione_riconc_insert
       (
          elabRec.file_pagopa_id,
          null,--filepagopaFileXMLId     varchar,
          null,--filepagopaFileOra       varchar,
          null,--filepagopaFileEnte      varchar,
          null,--filepagopaFileFruitore  varchar,
          filePagoPaElabId,
          annoRec.anno_elab,
          enteProprietarioId,
          loginOperazione,
          dataElaborazione
       );
              raise notice '2strMessaggioLog dopo=%',elabResRec.messaggiorisultato;

       if elabResRec.codiceRisultato!=0 then
       	  codiceRisultato:=elabResRec.codiceRisultato;
          strMessaggio:=elabResRec.messaggiorisultato;
       else
          filePagoPaElabId:=elabResRec.outPagoPaElabId;
       end if;

		raise notice 'codiceRisultato=%',codiceRisultato;
        raise notice 'strMessaggio=%',strMessaggio;
    end loop;

	if codiceRisultato=0 and coalesce(filePagoPaElabId,0)!=0 then
    	strMessaggio:='Elaborazione documenti  annoBilancio='||annoRec.anno_elab::varchar
                      ||' Identificativo elab='||coalesce((filePagoPaElabId::varchar),' ')||'.';
        strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc - '||strMessaggioFinale||strMessaggio;
        raise notice 'strMessaggioLog=%',strMessaggioLog;
	    insert into pagopa_t_elaborazione_log
   	    (
	      pagopa_elab_id,
    	  pagopa_elab_log_operazione,
	      ente_proprietario_id,
    	  login_operazione,
          data_creazione
	    )
	    values
	    (
     	  filePagoPaElabId,
	      strMessaggioLog,
	      enteProprietarioId,
	      loginOperazione,
          clock_timestamp()
	    );

        select * into elabEsecResRec
       	from fnc_pagopa_t_elaborazione_riconc_esegui
		(
		  filePagoPaElabId,
	      annoRec.anno_elab,
  		  enteProprietarioId,
		  loginOperazione,
	      dataElaborazione
        );
        if elabEsecResRec.codiceRisultato!=0 then
       	  codiceRisultato:=elabEsecResRec.codiceRisultato;
          strMessaggio:=elabEsecResRec.messaggiorisultato;
        end if;
    end if;

    -- 28.10.2020 Sofia SIAC-7672 - inizio
--	if codiceRisultato=0 and coalesce(filePagoPaElabId,0)!=0 then
--  16.04.2021 Sofia Jira 	SIAC-8163 - attivazione svecchiamento puntuale
    if coalesce(filePagoPaElabId,0)!=0 then
        select * into elabSvecchiaRec
       	from fnc_pagopa_t_elaborazione_riconc_svecchia_err
		(
		  filePagoPaElabId,
	      annoRec.anno_elab,
  		  enteProprietarioId,
		  loginOperazione,
	      dataElaborazione
        );
        if elabSvecchiaRec.codiceRisultato!=0 then
       	  codiceRisultato:=elabSvecchiaRec.codiceRisultato;
          strMessaggio:=elabSvecchiaRec.messaggiorisultato;
        end if;
    end if;
    -- 28.10.2020 Sofia SIAC-7672 - fine

   end loop;

   if codiceRisultato=0 then
	    outPagoPaElabId:=filePagoPaElabId;
        outPagoPaElabPrecId:=filePagoPaElabPrecId;
    	messaggioRisultato:=upper(strMessaggioFinale||' TERMINE OK.');
   else
    	outPagoPaElabId:=-1;
       	outPagoPaElabPrecId:=-1;
    	messaggioRisultato:=upper(strMessaggioFinale||'TERMINE KO.'||strMessaggio);
   end if;

   strMessaggioLog:='Fine fnc_pagopa_t_elaborazione_riconc - '||messaggioRisultato;
   insert into pagopa_t_elaborazione_log
   (
    pagopa_elab_id,
    pagopa_elab_log_operazione,
    ente_proprietario_id,
    login_operazione,
    data_creazione
   )
   values
   (
    filePagoPaElabId ,
    strMessaggioLog,
    enteProprietarioId,
    loginOperazione,
    clock_timestamp()
   );

   return;
exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);
       	outPagoPaElabId:=-1;
       	outPagoPaElabPrecId:=-1;

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	outPagoPaElabId:=-1;
       	outPagoPaElabPrecId:=-1;
        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
      	outPagoPaElabId:=-1;
       	outPagoPaElabPrecId:=-1;
        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	outPagoPaElabId:=-1;
       	outPagoPaElabPrecId:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter function
siac.fnc_pagopa_t_elaborazione_riconc
(
 integer,
 varchar,
 timestamp,
 out integer,
 out integer,
 out integer,
 out varchar
) OWNER to siac;
-- 16.04.2021 Sofia SIAC-8163 - fine

-- 21.04.2021 Sofia SIAC-8127 riallineamento codice  - inizio 
drop function if exists siac.fnc_siac_dwh_impegno
(
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_impegno (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
declare
v_user_table varchar;
params varchar;
-- 24.02.2021 Sofia Jira SIAC-8020
h_esito integer:=null;
begin

select fnc_siac_random_user()
into	v_user_table;

IF p_data IS NULL THEN
   IF p_anno_bilancio::integer < to_char(now(),'YYYY')::integer THEN
      p_data = to_timestamp('31/12/'||p_anno_bilancio, 'dd/mm/yyyy');
   ELSE
      p_data := now();
   END IF;
END IF;

params := p_anno_bilancio||' - '||p_ente_proprietario_id::varchar||' - '||p_data::varchar;


insert into
siac_dwh_log_elaborazioni (
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values (
p_ente_proprietario_id,
'fnc_siac_dwh_impegno',
params,
clock_timestamp(),
v_user_table
);

-- 24.02.2021 Sofia Jira SIAC-8020 - inizio
select
fnc_siac_vincoli_pending
(
  p_ente_proprietario_id,
  p_anno_bilancio::integer,
  v_user_table,
  null::integer,--p_movgest_anno  integer,
  null::integer,--p_movgest_numero integer,
  'fnc_siac_dwh_impegno'::varchar,--p_login_operazione varchar,
  p_data::timestamp
) into h_esito;
raise notice 'esito fnc_siac_vincoli_pending=%',h_esito::varchar;
-- 24.02.2021 Sofia Jira SIAC-8020 - fine



delete from siac_dwh_impegno where
ente_proprietario_id=p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
delete from siac_dwh_subimpegno where
ente_proprietario_id=p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;

INSERT INTO
  siac.siac_dwh_impegno
(
  ente_proprietario_id,  ente_denominazione,  bil_anno,  cod_fase_operativa,  desc_fase_operativa,
  anno_impegno,  num_impegno,  desc_impegno,  cod_impegno,  cod_stato_impegno,  desc_stato_impegno,
  data_scadenza,  parere_finanziario,  cod_capitolo,  cod_articolo,  cod_ueb,  desc_capitolo,  desc_articolo,
  soggetto_id, cod_soggetto, desc_soggetto,  cf_soggetto,  cf_estero_soggetto, p_iva_soggetto,  cod_classe_soggetto,  desc_classe_soggetto,
  cod_tipo_impegno,  desc_tipo_impegno,   cod_spesa_ricorrente,  desc_spesa_ricorrente,  cod_perimetro_sanita_spesa,  desc_perimetro_sanita_spesa,
  cod_transazione_ue_spesa,  desc_transazione_ue_spesa,  cod_politiche_regionali_unit,  desc_politiche_regionali_unit,
  cod_pdc_finanziario_i,  desc_pdc_finanziario_i,  cod_pdc_finanziario_ii,  desc_pdc_finanziario_ii,
  cod_pdc_finanziario_iii,  desc_pdc_finanziario_iii,  cod_pdc_finanziario_iv,  desc_pdc_finanziario_iv,
  cod_pdc_finanziario_v,  desc_pdc_finanziario_v,  cod_pdc_economico_i,  desc_pdc_economico_i,
  cod_pdc_economico_ii,  desc_pdc_economico_ii,  cod_pdc_economico_iii,  desc_pdc_economico_iii,
  cod_pdc_economico_iv,  desc_pdc_economico_iv,  cod_pdc_economico_v,  desc_pdc_economico_v,
  cod_cofog_divisione,  desc_cofog_divisione,  cod_cofog_gruppo,  desc_cofog_gruppo,
  classificatore_1,  classificatore_1_valore,  classificatore_1_desc_valore,
  classificatore_2,  classificatore_2_valore,  classificatore_2_desc_valore,
  classificatore_3,  classificatore_3_valore,  classificatore_3_desc_valore,
  classificatore_4,  classificatore_4_valore,  classificatore_4_desc_valore,
  classificatore_5,  classificatore_5_valore,  classificatore_5_desc_valore,
  annocapitoloorigine,  numcapitoloorigine,  annoorigineplur, numarticoloorigine,  annoriaccertato,  numriaccertato,  numorigineplur,
  flagdariaccertamento,
  flagdareanno,-- 19.02.2020 Sofia jira siac-7292
  anno_atto_amministrativo,  num_atto_amministrativo,  oggetto_atto_amministrativo,  note_atto_amministrativo,
  cod_tipo_atto_amministrativo, desc_tipo_atto_amministrativo, desc_stato_atto_amministrativo,
  importo_iniziale,  importo_attuale,  importo_utilizzabile,
  note,  anno_finanziamento,  cig,  cup,  num_ueb_origine,  validato,
  num_accertamento_finanziamento,  importo_liquidato,  importo_quietanziato,  importo_emesso,
  --data_elaborazione,
  flagcassaeconomale,  data_inizio_val_stato_imp,  data_inizio_val_imp,
  data_creazione_imp,  data_modifica_imp,
  cod_cdc_atto_amministrativo,  desc_cdc_atto_amministrativo,
  cod_cdr_atto_amministrativo,  desc_cdr_atto_amministrativo,
  cod_programma, desc_programma,
  flagPrenotazione, flagPrenotazioneLiquidabile, flagFrazionabile,
  cod_siope_tipo_debito, desc_siope_tipo_debito, desc_siope_tipo_debito_bnkit,
  cod_siope_assenza_motivazione, desc_siope_assenza_motivazione, desc_siope_assenza_motiv_bnkit,
  flag_attiva_gsa, -- 28.05.2018 Sofia siac-6202
  -- 23.10.2018 Sofia siac-6336
  stato_programma,
  versione_cronop,
  desc_cronop,
  anno_cronop,
  -- SIAC-7541 23.04.2020 Sofia
  cod_cdr_struttura_comp,
  desc_cdr_struttura_comp,
  cod_cdc_struttura_comp,
  desc_cdc_struttura_comp,
  -- SIAC-7899 Sofia 26.11.2020
  comp_tipo_id,
  -- SIAC-7593 Sofia 06.05.2020 - INIZIO
  comp_tipo_code,
  comp_tipo_desc,
  comp_tipo_macro_code,
  comp_tipo_macro_desc,
  comp_tipo_sotto_tipo_code,
  comp_tipo_sotto_tipo_desc,
  comp_tipo_ambito_code,
  comp_tipo_ambito_desc,
  comp_tipo_fonte_code,
  comp_tipo_fonte_desc,
  comp_tipo_fase_code ,
  comp_tipo_fase_desc,
  comp_tipo_def_code,
  comp_tipo_def_desc ,
  comp_tipo_gest_aut,
  comp_tipo_anno,
  -- SIAC-7593 Sofia 06.05.2020 - FINE
  -- SIAC-6865 Sofia 04.08.2020 - aggiudicazioni
  annoprenotazioneorigine,
  anno_impegno_aggiudicazione,
  num_impegno_aggiudicazione,
  num_modif_aggiudicazione
  )
select
xx.ente_proprietario_id, xx.ente_denominazione, xx.anno,xx.fase_operativa_code, xx.fase_operativa_desc ,
xx.movgest_anno, xx.movgest_numero, xx.movgest_desc, xx.movgest_ts_code, --xx.movgest_ts_desc,
xx.movgest_stato_code, xx.movgest_stato_desc, xx.movgest_ts_scadenza_data,
case when xx.parere_finanziario=false then 'F' else 'S' end parere_finanziario
,-- xx.movgest_id, xx.movgest_ts_id, xx.movgest_ts_tipo_code,
xx.elem_code, xx.elem_code2, xx.elem_code3, xx.elem_desc, xx.elem_desc2, --xx.bil_id,
xx.soggetto_id, xx.soggetto_code, xx.soggetto_desc, xx.codice_fiscale,xx.codice_fiscale_estero, xx.partita_iva, xx.soggetto_classe_code, xx.soggetto_classe_desc,
xx.tipoimpegno_classif_code,xx.tipoimpegno_classif_desc,xx.ricorrentespesa_classif_code,xx.ricorrentespesa_classif_desc,
xx.persaspesa_classif_code,xx.persaspesa_classif_desc, xx.truespesa_classif_code, xx.truespesa_classif_desc, xx.polregunitarie_classif_code,xx.polregunitarie_classif_desc,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_I else xx.pdc4_codice_pdc_finanziario_I end codice_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_I else xx.pdc4_descrizione_pdc_finanziario_I end descrizione_pdc_finanziario_I,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_II else xx.pdc4_codice_pdc_finanziario_II end codice_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_II else xx.pdc4_descrizione_pdc_finanziario_II end descrizione_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_III else xx.pdc4_codice_pdc_finanziario_III end codice_pdc_finanziario_III,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_III else xx.pdc4_descrizione_pdc_finanziario_III end descrizione_pdc_finanziario_III,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_IV else xx.pdc4_codice_pdc_finanziario_IV end codice_pdc_finanziario_IV  ,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_IV else xx.pdc4_descrizione_pdc_finanziario_IV end descrizione_pdc_finanziario_IV,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_V end codice_pdc_finanziario_V  ,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_V end descrizione_pdc_finanziario_V,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_I else xx.pce4_codice_pdc_economico_I end codice_pdc_economico_I,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_I else xx.pce4_descrizione_pdc_economico_I end descrizione_pdc_economico_I,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_II else xx.pce4_codice_pdc_economico_II end codice_pdc_economico_II,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_II else xx.pce4_descrizione_pdc_economico_II end descrizione_pdc_economico_II,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_III else xx.pce4_codice_pdc_economico_III end codice_pdc_economico_III,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_III else xx.pce4_descrizione_pdc_economico_III end descrizione_pdc_economico_III,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_IV else xx.pce4_codice_pdc_economico_IV end codice_pdc_economico_IV  ,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_IV else xx.pce4_descrizione_pdc_economico_IV end descrizione_pdc_economico_IV,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_V end codice_pdc_economico_V  ,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_V end descrizione_pdc_economico_V,
xx.codice_cofog_divisione, xx.descrizione_cofog_divisione,xx.codice_cofog_gruppo,xx.descrizione_cofog_gruppo,
xx.cla11_classif_tipo_desc,xx.cla11_classif_code,xx.cla11_classif_desc,
xx.cla12_classif_tipo_desc,xx.cla12_classif_code,xx.cla12_classif_desc,
xx.cla13_classif_tipo_desc,xx.cla13_classif_code,xx.cla13_classif_desc,
xx.cla14_classif_tipo_desc,xx.cla14_classif_code,xx.cla14_classif_desc,
xx.cla15_classif_tipo_desc,xx.cla15_classif_code,xx.cla15_classif_desc,
xx.annoCapitoloOrigine,xx.numeroCapitoloOrigine,xx.annoOriginePlur,xx.numeroArticoloOrigine,xx.annoRiaccertato,xx.numeroRiaccertato,
xx.numeroOriginePlur, xx.flagDaRiaccertamento,
xx.flagDaReanno, -- 19.02.2020 Sofia jira siac-7292
xx.attoamm_anno, xx.attoamm_numero, xx.attoamm_oggetto, xx.attoamm_note,
xx.attoamm_tipo_code, xx.attoamm_tipo_desc, xx.attoamm_stato_desc,
xx.importo_iniziale, xx.importo_attuale, xx.importo_utilizzabile,
xx.NOTE_MOVGEST,  xx.annoFinanziamento, xx.cig,xx.cup, xx.numeroUEBOrigine,  xx.validato,
--xx.attoamm_id,
xx.numeroAccFinanziamento,  xx.importo_liquidato,  xx.importo_quietanziato, xx.importo_emesso,
xx.flagCassaEconomale,
xx.data_inizio_val_stato_subimp, xx.data_inizio_val_imp,
xx.data_creazione_imp, xx.data_modifica_imp,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdc_code::varchar else xx.cdr_cdc_code::varchar end cdc_code,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdc_desc::varchar else xx.cdr_cdc_desc::varchar end cdc_desc,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdr_code::varchar else xx.cdr_cdr_code::varchar end cdr_code,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdr_desc::varchar else xx.cdr_cdr_desc::varchar end cdr_desc,
xx.programma_code, xx.programma_desc,
xx.flagPrenotazione, xx.flagPrenotazioneLiquidabile, xx.flagFrazionabile,
xx.siope_tipo_debito_code, xx.siope_tipo_debito_desc, xx.siope_tipo_debito_desc_bnkit,
xx.siope_assenza_motivazione_code, xx.siope_assenza_motivazione_desc, xx.siope_assenza_motivazione_desc_bnkit,
xx.flag_attiva_gsa, -- 28.05.2018 Sofia siac-6102
/*xx.data_inizio_val_stato_subimp, xx.data_inizio_val_subimp,
xx.data_creazione_subimp, xx.data_modifica_subimp,*/
-- 23.10.2018 Sofia SIAC-6336
xx.programma_stato,
xx.versione_cronop,
xx.desc_cronop,
xx.anno_cronop,
-- SIAC-7541 23.04.2020 Sofia
xx.cod_cdr_struttura_comp,
xx.desc_cdr_struttura_comp,
xx.cod_cdc_struttura_comp,
xx.desc_cdc_struttura_comp,
-- SIAC-7899 Sofia 26.11.2020 - INIZIO
xx.comp_tipo_id,
-- SIAC-7593 Sofia 06.05.2020 - INIZIO
xx.comp_tipo_code,
xx.comp_tipo_desc,
xx.comp_tipo_macro_code,
xx.comp_tipo_macro_desc,
xx.comp_tipo_sotto_tipo_code,
xx.comp_tipo_sotto_tipo_desc,
xx.comp_tipo_ambito_code,
xx.comp_tipo_ambito_desc,
xx.comp_tipo_fonte_code,
xx.comp_tipo_fonte_desc,
xx.comp_tipo_fase_code ,
xx.comp_tipo_fase_desc,
xx.comp_tipo_def_code,
xx.comp_tipo_def_desc ,
xx.comp_tipo_gest_aut,
xx.comp_tipo_anno,
-- SIAC-7593 Sofia 06.05.2020 - FINE,
-- SIAC-6865 Sofia 04.08.2020 - aggiudicazioni
xx.annoprenotazioneorigine,
xx.anno_impegno_aggiudicazione,
xx.num_impegno_aggiudicazione,
xx.num_modif_aggiudicazione
 from (
with imp as (
SELECT
e.ente_proprietario_id, e.ente_denominazione, d.anno,
       b.movgest_anno, b.movgest_numero, b.movgest_desc, a.movgest_ts_code, a.movgest_ts_desc,
       i.movgest_stato_code, i.movgest_stato_desc,
       a.movgest_ts_scadenza_data, b.parere_finanziario, b.movgest_id, a.movgest_ts_id,
       g.movgest_ts_tipo_code,    c.bil_id,
       h.validita_inizio as data_inizio_val_stato_subimp,
       a.data_creazione as data_creazione_subimp,
       a.validita_inizio as  data_inizio_val_subimp,
       a.data_modifica as data_modifica_subimp,
       b.data_creazione as data_creazione_imp,
       b.validita_inizio as data_inizio_val_imp,
       b.data_modifica as data_modifica_imp,
       m.fase_operativa_code, m.fase_operativa_desc,
       n.siope_tipo_debito_code, n.siope_tipo_debito_desc, n.siope_tipo_debito_desc_bnkit,
       o.siope_assenza_motivazione_code, o.siope_assenza_motivazione_desc, o.siope_assenza_motivazione_desc_bnkit
FROM
siac_t_movgest_ts a
left join siac_d_siope_tipo_debito n on n.siope_tipo_debito_id = a.siope_tipo_debito_id
                                     and n.data_cancellazione is null
                                     and n.validita_fine is null
left join siac_d_siope_assenza_motivazione o on o.siope_assenza_motivazione_id = a.siope_assenza_motivazione_id
                                             and o.data_cancellazione is null
                                             and o.validita_fine is null
, siac_t_movgest b
, siac_t_bil c
, siac_t_periodo d
, siac_t_ente_proprietario e
, siac_d_movgest_tipo f
, siac_d_movgest_ts_tipo g
, siac_r_movgest_ts_stato h
, siac_d_movgest_stato i,
siac_r_bil_fase_operativa l, siac_d_fase_operativa m
where a.movgest_id=  b.movgest_id and
 b.bil_id = c.bil_id and
 d.periodo_id = c.periodo_id and
 e.ente_proprietario_id = b.ente_proprietario_id   and
 b.movgest_tipo_id = f.movgest_tipo_id and
 a.movgest_ts_tipo_id = g.movgest_ts_tipo_id      and
 h.movgest_ts_id = a.movgest_ts_id   and
 h.movgest_stato_id = i.movgest_stato_id
and e.ente_proprietario_id = p_ente_proprietario_id
AND d.anno = p_anno_bilancio
AND f.movgest_tipo_code = 'I'
--and b.movgest_anno::integer in (2021,2022)
--and b.movgest_numero::integer between 2550 and 3000
-- 22.11.2018 Sofia jira SIAC-6548
-- AND p_data BETWEEN h.validita_inizio AND COALESCE(h.validita_fine, p_data)
and l.bil_id=c.bil_id
and m.fase_operativa_id=l.fase_operativa_id
--AND p_data BETWEEN l.validita_inizio AND COALESCE(l.validita_fine, p_data)
--and  b.movgest_anno::integer=2020
--and  b.movgest_numero::integer <=100
--and  exists ( select 1 from siac_r_movgest_aggiudicazione r where r.movgest_id_a=a.movgest_id )
--and  exists ( select 1 from siac_r_movgest_bil_elem r where r.movgest_id=a.movgest_id and  r.elem_det_comp_tipo_id is not null and r.validita_fine is null and r.data_cancellazione is null)
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND c.data_cancellazione IS NULL
AND d.data_cancellazione IS NULL
AND e.data_cancellazione IS NULL
AND f.data_cancellazione IS NULL
AND g.data_cancellazione IS NULL
AND h.data_cancellazione IS NULL
AND i.data_cancellazione IS NULL
AND a.validita_fine IS NULL
AND b.validita_fine IS NULL
AND c.validita_fine IS NULL
AND d.validita_fine IS NULL
AND e.validita_fine IS NULL
AND f.validita_fine IS NULL
AND g.validita_fine IS NULL
AND h.validita_fine IS NULL
AND i.validita_fine IS NULL
--limit 100
)
,
-- SIAC-7593 Sofia 06.05.2020
cap as
(
with
-- SIAC-7593 Sofia 06.05.2020
cap_elem as
(
select
      l.movgest_id,m.elem_code, m.elem_code2, m.elem_code3, m.elem_desc, m.elem_desc2,
      l.elem_det_comp_tipo_id -- SIAC-7593 Sofia 06.05.2020
From siac_r_movgest_bil_elem l, siac_t_bil_elem m
where l.elem_id=m.elem_id
and l.ente_proprietario_id=p_ente_proprietario_id
--AND p_data BETWEEN l.validita_inizio AND COALESCE(l.validita_fine, p_data)
--and l.elem_det_comp_tipo_id is not null
AND l.data_cancellazione IS NULL
AND m.data_cancellazione IS NULL
AND l.validita_fine IS NULL
AND m.validita_fine IS NULL
),
-- SIAC-7593 Sofia 06.05.2020
comp_tipo_imp as
(
select
     tipo.elem_det_comp_tipo_id comp_tipo_id, -- Sofia 26.11.2020 SIAC-7899
     --tipo.elem_det_comp_tipo_code comp_tipo_code, Sofia 26.11.2020 SIAC-7899
	 tipo.elem_det_comp_tipo_id::varchar(200) comp_tipo_code, -- Sofia 26.11.2020 SIAC-7899
     tipo.elem_det_comp_tipo_desc comp_tipo_desc,
     macro.elem_det_comp_macro_tipo_code comp_tipo_macro_code,
     macro.elem_det_comp_macro_tipo_desc comp_tipo_macro_desc,
     sotto_tipo.elem_det_comp_sotto_tipo_code comp_tipo_sotto_tipo_code,
     sotto_tipo.elem_det_comp_sotto_tipo_desc comp_tipo_sotto_tipo_desc,
     ambito_tipo.elem_det_comp_tipo_ambito_code comp_tipo_ambito_code,
     ambito_tipo.elem_det_comp_tipo_ambito_desc comp_tipo_ambito_desc,
     fonte_tipo.elem_det_comp_tipo_fonte_code comp_tipo_fonte_code,
     fonte_tipo.elem_det_comp_tipo_fonte_desc comp_tipo_fonte_desc,
     fase_tipo.elem_det_comp_tipo_fase_code comp_tipo_fase_code ,
     fase_tipo.elem_det_comp_tipo_fase_desc comp_tipo_fase_desc,
     def_tipo.elem_det_comp_tipo_def_code comp_tipo_def_code,
     def_tipo.elem_det_comp_tipo_def_desc comp_tipo_def_desc ,
     (case when tipo.elem_det_comp_tipo_gest_aut=true then 'Solo automatica'
        else 'Manuale' end)::varchar(50) comp_tipo_gest_aut,
     per.anno::integer comp_tipo_anno
from siac_d_bil_elem_det_comp_macro_tipo macro,
     siac_d_bil_elem_det_comp_tipo tipo
        left join siac_d_bil_elem_det_comp_sotto_tipo  sotto_tipo  on (tipo.elem_det_comp_sotto_tipo_id  =sotto_tipo.elem_det_comp_sotto_tipo_id)
        left join siac_d_bil_elem_det_comp_tipo_ambito ambito_tipo on (tipo.elem_det_comp_tipo_ambito_id =ambito_tipo.elem_det_comp_tipo_ambito_id)
        left join siac_d_bil_elem_det_comp_tipo_fonte  fonte_tipo  on (tipo.elem_det_comp_tipo_fonte_id  =fonte_tipo.elem_det_comp_tipo_fonte_id)
        left join siac_d_bil_elem_det_comp_tipo_fase   fase_tipo   on (tipo.elem_det_comp_tipo_fase_id   =fase_tipo.elem_det_comp_tipo_fase_id)
        left join siac_d_bil_elem_det_comp_tipo_def    def_tipo    on (tipo.elem_det_comp_tipo_def_id    =def_tipo.elem_det_comp_tipo_def_id)
        left join siac_t_periodo per                               on (tipo.periodo_id                   =per.periodo_id)
where macro.elem_det_comp_macro_tipo_id=tipo.elem_det_comp_macro_tipo_id
)
select
     cap_elem.movgest_id,
     cap_elem.elem_code,
     cap_elem.elem_code2,
     cap_elem.elem_code3,
     cap_elem.elem_desc,
     cap_elem.elem_desc2,
	 -- 26.11.2020 Sofia SIAC-7899
	 comp_tipo_imp.comp_tipo_id,
     comp_tipo_imp.comp_tipo_code,
     comp_tipo_imp.comp_tipo_desc,
     comp_tipo_imp.comp_tipo_macro_code,
     comp_tipo_imp.comp_tipo_macro_desc,
     comp_tipo_imp.comp_tipo_sotto_tipo_code,
     comp_tipo_imp.comp_tipo_sotto_tipo_desc,
     comp_tipo_imp.comp_tipo_ambito_code,
     comp_tipo_imp.comp_tipo_ambito_desc,
     comp_tipo_imp.comp_tipo_fonte_code,
     comp_tipo_imp.comp_tipo_fonte_desc,
     comp_tipo_imp.comp_tipo_fase_code ,
     comp_tipo_imp.comp_tipo_fase_desc,
     comp_tipo_imp.comp_tipo_def_code,
     comp_tipo_imp.comp_tipo_def_desc ,
     comp_tipo_imp.comp_tipo_gest_aut,
     comp_tipo_imp.comp_tipo_anno
from cap_elem left join comp_tipo_imp on (cap_elem.elem_det_comp_tipo_id=comp_tipo_imp.comp_tipo_id) -- 26.11.2020 Sofia SIAC-7899
),-- SIAC-7593 Sofia 06.05.2020
sogg as (SELECT
a.movgest_ts_id,
b.soggetto_code, b.soggetto_desc, b.codice_fiscale,
b.codice_fiscale_estero, b.partita_iva, b.soggetto_id
/*INTO v_codice_soggetto, v_descrizione_soggetto, v_codice_fiscale_soggetto,
v_codice_fiscale_estero_soggetto, v_partita_iva_soggetto, v_soggetto_id*/
FROM siac_r_movgest_ts_sog a, siac_t_soggetto b
WHERE a.soggetto_id = b.soggetto_id
and a.ente_proprietario_id=p_ente_proprietario_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
),
sogcla as (SELECT
a.movgest_ts_id,b.soggetto_classe_code, b.soggetto_classe_desc
--INTO v_codice_classe_soggetto, v_descrizione_classe_soggetto
FROM siac_r_movgest_ts_sogclasse a, siac.siac_d_soggetto_classe b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.soggetto_classe_id = b.soggetto_classe_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
),
--classificatori non gerarchici
tipoimpegno as (
SELECT
a.movgest_ts_id,b.classif_code tipoimpegno_classif_code,b.classif_desc tipoimpegno_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TIPO_IMPEGNO'
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
ricorrentespesa as (
SELECT
a.movgest_ts_id,b.classif_code ricorrentespesa_classif_code,b.classif_desc ricorrentespesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='RICORRENTE_SPESA'
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
truespesa as (
SELECT
a.movgest_ts_id,b.classif_code truespesa_classif_code,b.classif_desc truespesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
persaspesa as (
SELECT
a.movgest_ts_id,b.classif_code persaspesa_classif_code,b.classif_desc persaspesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='PERIMETRO_SANITARIO_SPESA'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
polregunitarie as (
SELECT
a.movgest_ts_id,b.classif_code polregunitarie_classif_code,b.classif_desc polregunitarie_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='POLITICHE_REGIONALI_UNITARIE'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
cla11 as (
SELECT
a.movgest_ts_id,b.classif_code cla11_classif_code,b.classif_desc cla11_classif_desc,
c.classif_tipo_desc cla11_classif_tipo_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_11'
-- AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla12 as (
SELECT
a.movgest_ts_id,b.classif_code cla12_classif_code,b.classif_desc cla12_classif_desc,
c.classif_tipo_desc cla12_classif_tipo_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_12'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla13 as (
SELECT
a.movgest_ts_id,b.classif_code cla13_classif_code,b.classif_desc cla13_classif_desc,
c.classif_tipo_desc cla13_classif_tipo_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_13'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla14 as (
SELECT
a.movgest_ts_id,b.classif_code cla14_classif_code,b.classif_desc cla14_classif_desc,
c.classif_tipo_desc cla14_classif_tipo_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_14'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla15 as (
SELECT
a.movgest_ts_id,b.classif_code cla15_classif_code,b.classif_desc cla15_classif_desc,
c.classif_tipo_desc cla15_classif_tipo_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_15'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
--sezione attributi
, t_annoCapitoloOrigine as (
SELECT
a.movgest_ts_id
, a.testo annoCapitoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoCapitoloOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroCapitoloOrigine as (
SELECT
a.movgest_ts_id
, a.testo numeroCapitoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroCapitoloOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoOriginePlur as (
SELECT
a.movgest_ts_id
, a.testo annoOriginePlur
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoOriginePlur' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroArticoloOrigine as (
SELECT
a.movgest_ts_id
, a.testo numeroArticoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroArticoloOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoRiaccertato as (
SELECT
a.movgest_ts_id
, a.testo annoRiaccertato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoRiaccertato' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroRiaccertato as (
SELECT
a.movgest_ts_id
, a.testo numeroRiaccertato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroRiaccertato' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroOriginePlur as (
SELECT
a.movgest_ts_id
, a.testo numeroOriginePlur
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroOriginePlur' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagDaRiaccertamento as (
SELECT
a.movgest_ts_id
, a."boolean" flagDaRiaccertamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagDaRiaccertamento' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
-- 19.02.2020 Sofia jira siac-7292
, t_flagDaReanno as (
SELECT
a.movgest_ts_id
, a."boolean" flagDaReanno
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagDaReanno' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroUEBOrigine as (
SELECT
a.movgest_ts_id
, a.testo numeroUEBOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroUEBOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_cig as (
SELECT
a.movgest_ts_id
, a.testo cig
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='cig' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_cup as (
SELECT
a.movgest_ts_id
, a.testo cup
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='cup' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_NOTE_MOVGEST as (
SELECT
a.movgest_ts_id
, a.testo NOTE_MOVGEST
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='NOTE_MOVGEST' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_validato as (
SELECT
a.movgest_ts_id
, a."boolean" validato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='validato' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoFinanziamento as (
SELECT
a.movgest_ts_id
, a.testo annoFinanziamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoFinanziamento' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroAccFinanziamento as (
SELECT
a.movgest_ts_id
, a.testo numeroAccFinanziamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroAccFinanziamento' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagCassaEconomale as (
SELECT
a.movgest_ts_id
, a."boolean" flagCassaEconomale
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagCassaEconomale' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagPrenotazione as (
SELECT
a.movgest_ts_id
, a."boolean" flagPrenotazione
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagPrenotazione' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagPrenotazioneLiquidabile as (
SELECT
a.movgest_ts_id
, a."boolean" flagPrenotazioneLiquidabile
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagPrenotazioneLiquidabile' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
),
t_flagFrazionabile as (
SELECT
a.movgest_ts_id
, a."boolean" flagFrazionabile
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagFrazionabile' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
),
--atto amm
attoamm as (
with atmc as (
with atm as (
SELECT
a.movgest_ts_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM
siac.siac_r_movgest_ts_atto_amm a,
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c,
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE
a.ente_proprietario_id=p_ente_proprietario_id--p_ente_proprietario_id
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
AND   d.validita_fine IS NULL
AND   e.validita_fine IS NULL
)
,
atmrclass as (select a.attoamm_id,a.classif_id from siac_r_atto_amm_class a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.data_cancellazione is null
and a.validita_fine is null
--and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
select atm.*,atmrclass.classif_id from atm left join atmrclass
on atmrclass.attoamm_id=atm.attoamm_id
)
,
cdc as (
select a.classif_id,a.classif_code cdc_cdc_code,a.classif_desc cdc_cdc_desc
,a2.classif_code cdc_cdr_code,a2.classif_desc cdc_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b, siac_r_class_fam_tree c,siaC_t_class a2
where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDC'
and c.classif_id=a.classif_id
and a2.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a2.data_cancellazione is null
/*and a.validita_fine is null
and b.validita_fine is null
and c.validita_fine is null
and a2.validita_fine is null*/
)
,cdr as (
select a.classif_id,null cdr_cdc_code,null cdr_cdc_desc
,a.classif_code cdr_cdr_code,a.classif_desc cdr_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b
 where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDR'
and a.data_cancellazione is null
and b.data_cancellazione is null
/*and a.validita_fine is null
and b.validita_fine is null*/
)
select
atmc.movgest_ts_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on
atmc.classif_id=cdc.classif_id
left join cdr on
atmc.classif_id=cdr.classif_id),
impattuale as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_attuale, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND a.validita_fine IS NULL
AND b.validita_fine IS NULL
and b.movgest_ts_det_tipo_code='A'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
)
,
impiniziale as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_iniziale, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND a.validita_fine IS NULL
AND b.validita_fine IS NULL
and b.movgest_ts_det_tipo_code='I'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
)
,
imputilizzabile as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_utilizzabile, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND a.validita_fine IS NULL
AND b.validita_fine IS NULL
and b.movgest_ts_det_tipo_code='U'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
),
impliquidatoemessoquietanziato as (select tz.* from (
with liquid as (
 SELECT sum(COALESCE(b.liq_importo,0)) importo_liquidato, a.movgest_ts_id,
b.liq_id
    FROM siac.siac_r_liquidazione_movgest a, siac.siac_t_liquidazione b,
    siac.siac_d_liquidazione_stato c, siac.siac_r_liquidazione_stato d
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id
    AND   a.liq_id = b.liq_id
    AND   b.liq_id = d.liq_id
    AND   d.liq_stato_id = c.liq_stato_id
    AND   c.liq_stato_code <> 'A'
    --AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
    --AND p_data BETWEEN d.validita_inizio AND COALESCE(d.validita_fine, p_data)
    AND a.data_cancellazione IS NULL
    AND b.data_cancellazione IS NULL
    AND c.data_cancellazione IS NULL
    AND d.data_cancellazione IS NULL
    AND a.validita_fine IS NULL
    AND b.validita_fine IS NULL
    AND c.validita_fine IS NULL
    AND d.validita_fine IS NULL
    group by a.movgest_ts_id, b.liq_id),
emes as (
  SELECT COALESCE(SUM(e.ord_ts_det_importo),0) importo_emesso, a.liq_id
            FROM
            siac_r_liquidazione_ord a,
            siac_t_ordinativo_ts b,
                 siac_r_ordinativo_stato c, siac_d_ordinativo_stato d,
                 siac_t_ordinativo_ts_det e, siac_d_ordinativo_ts_det_tipo f
            WHERE
            a.ente_proprietario_id=p_ente_proprietario_id and
            a.sord_id=b.ord_ts_id
            AND  c.ord_id = b.ord_id
            AND  c.ord_stato_id = d.ord_stato_id
            AND  e.ord_ts_id = b.ord_ts_id
            AND  f.ord_ts_det_tipo_id = e.ord_ts_det_tipo_id
            AND  d.ord_stato_code <> 'A'
            AND  f.ord_ts_det_tipo_code = 'A'
            --AND  p_data BETWEEN  a.validita_inizio  AND COALESCE(a.validita_fine, p_data)
            --AND  p_data BETWEEN  c.validita_inizio  AND COALESCE(c.validita_fine, p_data)
            AND  a.data_cancellazione IS NULL
            AND  b.data_cancellazione IS NULL
            AND  c.data_cancellazione IS NULL
            AND  d.data_cancellazione IS NULL
            AND  e.data_cancellazione IS NULL
            AND  f.data_cancellazione IS NULL
            AND  a.validita_fine IS NULL
            AND  b.validita_fine IS NULL
            AND  c.validita_fine IS NULL
            AND  d.validita_fine IS NULL
            AND  e.validita_fine IS NULL
            AND  f.validita_fine IS NULL
            group by a.liq_id),
quiet as (
  SELECT COALESCE(SUM(e.ord_ts_det_importo),0) importo_quietanziato, a.liq_id
            FROM
            siac_r_liquidazione_ord a,
            siac_t_ordinativo_ts b,
                 siac_r_ordinativo_stato c, siac_d_ordinativo_stato d,
                 siac_t_ordinativo_ts_det e, siac_d_ordinativo_ts_det_tipo f
            WHERE
            a.ente_proprietario_id=p_ente_proprietario_id and
            a.sord_id=b.ord_ts_id
            AND  c.ord_id = b.ord_id
            AND  c.ord_stato_id = d.ord_stato_id
            AND  e.ord_ts_id = b.ord_ts_id
            AND  f.ord_ts_det_tipo_id = e.ord_ts_det_tipo_id
            AND  d.ord_stato_code= 'Q'
            AND  f.ord_ts_det_tipo_code = 'A'
            --AND  p_data BETWEEN  a.validita_inizio  AND COALESCE(a.validita_fine, p_data)
            --AND  p_data BETWEEN  c.validita_inizio  AND COALESCE(c.validita_fine, p_data)
            AND  a.data_cancellazione IS NULL
            AND  b.data_cancellazione IS NULL
            AND  c.data_cancellazione IS NULL
            AND  d.data_cancellazione IS NULL
            AND  e.data_cancellazione IS NULL
            AND  f.data_cancellazione IS NULL
            AND  a.validita_fine IS NULL
            AND  b.validita_fine IS NULL
            AND  c.validita_fine IS NULL
            AND  d.validita_fine IS NULL
            AND  e.validita_fine IS NULL
            AND  f.validita_fine IS NULL
            group by a.liq_id)
select liquid.movgest_ts_id,coalesce(sum(liquid.importo_liquidato),0) importo_liquidato,
coalesce(sum(emes.importo_emesso),0) importo_emesso,
coalesce(sum(quiet.importo_quietanziato),0) importo_quietanziato
from liquid left join emes ON
liquid.liq_id=emes.liq_id
left join quiet ON
liquid.liq_id=quiet.liq_id
group by liquid.movgest_ts_id
) as tz),
cofog as (
select distinct r.movgest_ts_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
a2.classif_code codice_cofog_divisione,a2.classif_desc descrizione_cofog_divisione
from
siac_r_movgest_class r,
siac_t_class a,siac_d_class_tipo b,
--DIVISIONE_COFOG
siac_r_class_fam_tree d2,
siac_t_class a2
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='GRUPPO_COFOG'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
--and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
)
, pdc5 as (
select distinct
r.movgest_ts_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
a2.classif_code pdc5_codice_pdc_finanziario_IV,a2.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_movgest_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
-- SIAC-5883 Daniela 13.02.2018
-- and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
-- SIAC-5883 FINE Daniela 13.02.2018
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
--and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
AND   d5.data_cancellazione IS NULL
AND   a5.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL
AND   d5.validita_fine IS NULL
AND   a5.validita_fine IS NULL*/
)
, pdc4 as (
select distinct r.movgest_ts_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
a2.classif_code pdc4_codice_pdc_finanziario_III,a2.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_movgest_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
-- SIAC-5883 Daniela 13.02.2018
-- and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
-- SIAC-5883 FINE Daniela 13.02.2018
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL*/
)
, pce5 as (
select distinct r.movgest_ts_id,
--r.classif_id,
a.classif_code pce5_codice_pdc_economico_V,a.classif_desc pce5_descrizione_pdc_economico_V,
a2.classif_code pce5_codice_pdc_economico_IV,a2.classif_desc pce5_descrizione_pdc_economico_IV,
a3.classif_code pce5_codice_pdc_economico_III,a3.classif_desc pce5_descrizione_pdc_economico_III,
a4.classif_code pce5_codice_pdc_economico_II,a4.classif_desc pce5_descrizione_pdc_economico_II,
a5.classif_code pce5_codice_pdc_economico_I,a5.classif_desc pce5_descrizione_pdc_economico_I
 from siac_r_movgest_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
--and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
AND   d5.data_cancellazione IS NULL
AND   a5.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL
AND   d5.validita_fine IS NULL
AND   a5.validita_fine IS NULL*/
)
, pce4 as (
select distinct r.movgest_ts_id,
a.classif_code pce4_codice_pdc_economico_IV,a.classif_desc pce4_descrizione_pdc_economico_IV,
a2.classif_code pce4_codice_pdc_economico_III,a2.classif_desc pce4_descrizione_pdc_economico_III,
a3.classif_code pce4_codice_pdc_economico_II,a3.classif_desc pce4_descrizione_pdc_economico_II,
a4.classif_code pce4_codice_pdc_economico_I,a4.classif_desc pce4_descrizione_pdc_economico_I
 from siac_r_movgest_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL*/
),
-- 30.04.2019 Sofia siac-6255 - modificato tutto il pezzo per tirare su il programma-cronop secondo
-- nuovo collegamento o secondo vecchio collegamento se non esiste tramite nuovo
progr_all_all as
(
with
progr_all as
(
with
-- 23.10.2018 Sofia siac-6336
progetto_old as -- vecchio collegamento
(
with
 progr as
 (
  select rmtp.movgest_ts_id, tp.programma_code, tp.programma_desc,
         stato.programma_stato_code  programma_stato,
         rmtp.programma_id
  from   siac_r_movgest_ts_programma rmtp, siac_t_programma tp, siac_r_programma_stato rs, siac_d_programma_stato stato
  where  rmtp.programma_id = tp.programma_id
  --and    p_data BETWEEN rmtp.validita_inizio and COALESCE(rmtp.validita_fine,p_data)
  --and    p_data BETWEEN tp.validita_inizio and COALESCE(tp.validita_fine,p_data)
  and    rs.programma_id=tp.programma_id
  and    stato.programma_stato_id=rs.programma_stato_id
  and    rmtp.data_cancellazione IS NULL
  and    tp.data_cancellazione IS NULL
  and    rmtp.validita_fine IS NULL
  and    tp.validita_fine IS NULL
  and    rs.data_cancellazione is null
  and    rs.validita_fine is null
 ),
 -- 23.10.2018 Sofia siac-6336
 cronop as
 (
  select cronop.programma_id,
		 cronop.cronop_id,
         cronop.cronop_code versione_cronop,
         cronop.cronop_desc desc_cronop,
         per.anno::varchar  anno_cronop
  from siac_t_cronop cronop, siac_r_cronop_stato rs, siac_d_cronop_stato stato,
       siac_t_periodo per,siac_t_bil bil
  where stato.ente_proprietario_id=p_ente_proprietario_id
  and   stato.cronop_stato_code='VA'
  and   rs.cronop_stato_id=stato.cronop_stato_id
  and   cronop.cronop_id=rs.cronop_id
  and   bil.bil_id=cronop.bil_id
  and   per.periodo_id=bil.periodo_id
  and   per.anno::INTEGER=p_anno_bilancio::integer
  and   rs.data_cancellazione is null
  and   rs.validita_fine is null
  and   cronop.data_cancellazione is null
  and   cronop.validita_fine is null
  ),
  cronop_ultimo as
  (
  select cronop.programma_id,
		 max(cronop.cronop_id) cronop_id
  from siac_t_cronop cronop, siac_r_cronop_stato rs, siac_d_cronop_stato stato,
       siac_t_bil bil ,siac_t_periodo per
  where stato.ente_proprietario_id=p_ente_proprietario_id
  and   stato.cronop_stato_code='VA'
  and   rs.cronop_stato_id=stato.cronop_stato_id
  and   cronop.cronop_id=rs.cronop_id
  and   bil.bil_id=cronop.bil_id
  and   per.periodo_id=bil.periodo_id
  and   per.anno::INTEGER=p_anno_bilancio::integer
  and   rs.data_cancellazione is null
  and   rs.validita_fine is null
  and   cronop.data_cancellazione is null
  and   cronop.validita_fine is null
  group by cronop.programma_id
  )
  select 1 programma_tipo_coll,
         progr.movgest_ts_id, progr.programma_code, progr.programma_desc,
         progr.programma_stato ,
         cronop.versione_cronop,
         cronop.desc_cronop,
         cronop.anno_cronop
  from progr
   left join cronop join cronop_ultimo on (cronop.cronop_id=cronop_ultimo.cronop_id)
    on (progr.programma_id=cronop.programma_id)
),
-- 30.04.2019 Sofia siac-6255 - nuovo collegamento
progetto as
(
 with
 progr as
 (
  select tp.programma_code, tp.programma_desc,
         stato.programma_stato_code  programma_stato,
         tp.programma_id
  from   siac_t_programma tp, siac_r_programma_stato rs, siac_d_programma_stato stato
  where  stato.ente_proprietario_id=p_ente_proprietario_id
  and    rs.programma_stato_id=stato.programma_stato_id
  and    tp.programma_id=rs.programma_id
  and    tp.data_cancellazione IS NULL
  and    tp.validita_fine IS NULL
  and    rs.data_cancellazione is null
  and    rs.validita_fine is null
 ),
 cronop as
 (
  select rmov.movgest_ts_id,
         cronop.programma_id,
		 cronop.cronop_id,
         cronop.cronop_code versione_cronop,
         cronop.cronop_desc desc_cronop,
         per.anno::varchar  anno_cronop,
         rmov.data_creazione
  from siac_r_movgest_ts_cronop_elem rmov, siac_t_cronop_elem celem,
       siac_t_cronop cronop, siac_r_cronop_stato rs, siac_d_cronop_stato stato,
       siac_t_periodo per,siac_t_bil bil
  where stato.ente_proprietario_id=p_ente_proprietario_id
  and   stato.cronop_stato_code='VA'
  and   rs.cronop_stato_id=stato.cronop_stato_id
  and   cronop.cronop_id=rs.cronop_id
  and   bil.bil_id=cronop.bil_id
  and   per.periodo_id=bil.periodo_id
  and   per.anno::INTEGER=p_anno_bilancio::integer
  and   celem.cronop_id=cronop.cronop_id
  and   rmov.cronop_elem_id=celem.cronop_elem_id
  and   rs.data_cancellazione is null
  and   rs.validita_fine is null
  and   cronop.data_cancellazione is null
  and   cronop.validita_fine is null
  and   celem.data_cancellazione is null
  and   celem.validita_fine is null
  and   rmov.data_cancellazione is null
  and   rmov.validita_fine is null
 ),
 cronop_ultimo as
 (
  select rmov.movgest_ts_id,
         max(cronop.cronop_id) ult_cronop_id
  from siac_r_movgest_ts_cronop_elem rmov, siac_t_cronop_elem celem,
       siac_t_cronop cronop, siac_r_cronop_stato rs, siac_d_cronop_stato stato,
       siac_t_periodo per,siac_t_bil bil
  where stato.ente_proprietario_id=p_ente_proprietario_id
  and   stato.cronop_stato_code='VA'
  and   rs.cronop_stato_id=stato.cronop_stato_id
  and   cronop.cronop_id=rs.cronop_id
  and   bil.bil_id=cronop.bil_id
  and   per.periodo_id=bil.periodo_id
  and   per.anno::INTEGER=p_anno_bilancio::integer
  and   celem.cronop_id=cronop.cronop_id
  and   rmov.cronop_elem_id=celem.cronop_elem_id
  and   rs.data_cancellazione is null
  and   rs.validita_fine is null
  and   cronop.data_cancellazione is null
  and   cronop.validita_fine is null
  and   celem.data_cancellazione is null
  and   celem.validita_fine is null
  and   rmov.data_cancellazione is null
  and   rmov.validita_fine is null
  group by rmov.movgest_ts_id
 )
 select 2 programma_tipo_coll,
        cronop.movgest_ts_id,
        progr.programma_code, progr.programma_desc,
        progr.programma_stato ,
        cronop.versione_cronop,
        cronop.desc_cronop,
        cronop.anno_cronop
 from progr, cronop ,cronop_ultimo
 where cronop.programma_id=progr.programma_id
 and   cronop_ultimo.ult_cronop_id=cronop.cronop_id
 and   cronop_ultimo.movgest_ts_id=cronop.movgest_ts_id
)
select *
from progetto_old
union
select *
from progetto
)
select *
from progr_all p1
where
(  ( p1.programma_tipo_coll=1 and p1.movgest_ts_id is not null ) or
   (p1.programma_tipo_coll=2
    and   not exists (select 1 from progr_all p2 where p2.programma_tipo_coll=1 and p2.movgest_Ts_id is not null)
   )
)
),
-- 30.04.2019 Sofia siac-6255 - fine
impFlagAttivaGsa as -- 28.05.2018 Sofia siac-6102
(
select rattr.movgest_ts_id, rattr.boolean flag_attiva_gsa
from siac_r_movgest_ts_attr rattr, siac_t_attr attr
where attr.ente_proprietario_id=p_ente_proprietario_id
and   attr.attr_code='FlagAttivaGsa'
and   rattr.attr_id=attr.attr_id
and   rattr.data_cancellazione is null
and   rattr.validita_fine is null
),
-- SIAC-7541 23.04.2020 Sofia
cdc_struttura as
(
SELECT rc.movgest_ts_id,c.classif_code cod_cdc_struttura_comp,c.classif_desc desc_cdc_struttura_comp
from   siac_r_movgest_class rc, siac_t_class c, siac_d_class_tipo tipo
where rc.ente_proprietario_id = p_ente_proprietario_id
and   c.classif_id=rc.classif_id
and   tipo.classif_tipo_id=c.classif_tipo_id
and   tipo.classif_tipo_code='CDC'
AND   rc.data_cancellazione IS NULL
--AND   c.data_cancellazione IS NULL
AND   rc.validita_fine IS NULL
),
-- SIAC-7541 23.04.2020 Sofia
cdr_struttura as
(
SELECT rc.movgest_ts_id,c.classif_code cod_cdr_struttura_comp,c.classif_desc desc_cdr_struttura_comp
from   siac_r_movgest_class rc, siac_t_class c, siac_d_class_tipo tipo
where rc.ente_proprietario_id = p_ente_proprietario_id
and   c.classif_id=rc.classif_id
and   tipo.classif_tipo_id=c.classif_tipo_id
and   tipo.classif_tipo_code='CDR'
AND   rc.data_cancellazione IS NULL
--AND   c.data_cancellazione IS NULL
AND   rc.validita_fine IS NULL
),
-- SIAC-6865 Sofia 04.08.2020 - aggiudicazioni
imp_aggiudicazione_anno as
(
select rattr.movgest_ts_id, (case when coalesce(rattr.testo,'')!='' then rattr.testo::integer else 0 end) annoprenotazioneorigine
from siac_r_movgest_ts_attr rattr,siac_t_attr attr
where attr.ente_proprietario_id=p_ente_proprietario_id
and   attr.attr_code='annoPrenotazioneOrigine'
and   rattr.attr_id=attr.attr_id
and   rattr.data_cancellazione is null
and   rattr.validita_fine is null
),
imp_aggiudicazione as
(
select r.movgest_id_a,
       mov.movgest_anno::integer anno_impegno_da,
       mov.movgest_numero::integer numero_impegno_da,
       modif.mod_num::integer mod_num_da
from siac_r_movgest_aggiudicazione r,siac_t_movgest mov,
     siac_t_modifica modif
where r.ente_proprietario_id=p_ente_proprietario_id
and   mov.movgest_id=r.movgest_id_da
and   modif.mod_id=r.mod_id
and   r.data_cancellazione is null
and   r.validita_fine is null
and   modif.data_cancellazione is null
and   modif.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
)
select
imp.ente_proprietario_id, imp.ente_denominazione, imp.anno,
imp.movgest_anno, imp.movgest_numero, imp.movgest_desc, imp.movgest_ts_code, imp.movgest_ts_desc,
imp.movgest_stato_code, imp.movgest_stato_desc,
imp.movgest_ts_scadenza_data, imp.parere_finanziario, imp.movgest_id, imp.movgest_ts_id,
imp.movgest_ts_tipo_code,
cap.elem_code, cap.elem_code2, cap.elem_code3, cap.elem_desc, cap.elem_desc2,
-- SIAC-7899 Sofia 26.11.2020
cap.comp_tipo_id,
-- SIAC-7593 Sofia 06.05.2020 - INIZIO
cap.comp_tipo_code,
cap.comp_tipo_desc,
cap.comp_tipo_macro_code,
cap.comp_tipo_macro_desc,
cap.comp_tipo_sotto_tipo_code,
cap.comp_tipo_sotto_tipo_desc,
cap.comp_tipo_ambito_code,
cap.comp_tipo_ambito_desc,
cap.comp_tipo_fonte_code,
cap.comp_tipo_fonte_desc,
cap.comp_tipo_fase_code ,
cap.comp_tipo_fase_desc,
cap.comp_tipo_def_code,
cap.comp_tipo_def_desc ,
cap.comp_tipo_gest_aut,
cap.comp_tipo_anno,
-- SIAC-7593 Sofia 06.05.2020 - FINE
imp.bil_id,
imp.data_inizio_val_stato_subimp,
imp.data_creazione_subimp,
imp.data_inizio_val_subimp,
imp.data_modifica_subimp,
imp.data_creazione_imp,
imp.data_inizio_val_imp,
imp.data_modifica_imp,
imp.fase_operativa_code, imp.fase_operativa_desc ,
sogg.soggetto_code, sogg.soggetto_desc, sogg.codice_fiscale,
sogg.codice_fiscale_estero, sogg.partita_iva, sogg.soggetto_id
,sogcla.soggetto_classe_code, sogcla.soggetto_classe_desc,
tipoimpegno.tipoimpegno_classif_code,
tipoimpegno.tipoimpegno_classif_desc,
ricorrentespesa.ricorrentespesa_classif_code,
ricorrentespesa.ricorrentespesa_classif_desc,
truespesa.truespesa_classif_code,
truespesa.truespesa_classif_desc,
persaspesa.persaspesa_classif_code,
persaspesa.persaspesa_classif_desc,
polregunitarie.polregunitarie_classif_code,
polregunitarie.polregunitarie_classif_desc,
cla11.cla11_classif_code,
cla11.cla11_classif_desc,
cla11.cla11_classif_tipo_desc,
cla12.cla12_classif_code,
cla12.cla12_classif_desc,
cla12.cla12_classif_tipo_desc,
cla13.cla13_classif_code,
cla13.cla13_classif_desc,
cla13.cla13_classif_tipo_desc,
cla14.cla14_classif_code,
cla14.cla14_classif_desc,
cla14.cla14_classif_tipo_desc,
cla15.cla15_classif_code,
cla15.cla15_classif_desc,
cla15.cla15_classif_tipo_desc,
t_annoCapitoloOrigine.annoCapitoloOrigine,
t_numeroCapitoloOrigine.numeroCapitoloOrigine,
t_annoOriginePlur.annoOriginePlur,
t_numeroArticoloOrigine.numeroArticoloOrigine,
t_annoRiaccertato.annoRiaccertato,
t_numeroRiaccertato.numeroRiaccertato,
t_numeroOriginePlur.numeroOriginePlur,
t_flagDaRiaccertamento.flagDaRiaccertamento,
t_flagDaReanno.flagDaReanno, -- 19.02.2020 Sofia jira siac-7292
t_numeroUEBOrigine.numeroUEBOrigine,
t_cig.cig,
t_cup.cup,
t_NOTE_MOVGEST.NOTE_MOVGEST,
t_validato.validato,
t_annoFinanziamento.annoFinanziamento,
t_numeroAccFinanziamento.numeroAccFinanziamento,
t_flagCassaEconomale.flagCassaEconomale,
attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
impattuale.importo_attuale,
impiniziale.importo_iniziale,
imputilizzabile.importo_utilizzabile,
impliquidatoemessoquietanziato.importo_liquidato,
impliquidatoemessoquietanziato.importo_emesso,
impliquidatoemessoquietanziato,importo_quietanziato,
cofog.codice_cofog_gruppo,
cofog.descrizione_cofog_gruppo,
cofog.codice_cofog_divisione,
cofog.descrizione_cofog_divisione,
pdc5.pdc5_codice_pdc_finanziario_V,pdc5.pdc5_descrizione_pdc_finanziario_V,
pdc5.pdc5_codice_pdc_finanziario_IV,pdc5.pdc5_descrizione_pdc_finanziario_IV,
pdc5.pdc5_codice_pdc_finanziario_III,pdc5.pdc5_descrizione_pdc_finanziario_III,
pdc5.pdc5_codice_pdc_finanziario_II,pdc5.pdc5_descrizione_pdc_finanziario_II,
pdc5.pdc5_codice_pdc_finanziario_I,pdc5.pdc5_descrizione_pdc_finanziario_I,
pdc4.pdc4_codice_pdc_finanziario_IV,pdc4.pdc4_descrizione_pdc_finanziario_IV,
pdc4.pdc4_codice_pdc_finanziario_III,pdc4.pdc4_descrizione_pdc_finanziario_III,
pdc4.pdc4_codice_pdc_finanziario_II,pdc4.pdc4_descrizione_pdc_finanziario_II,
pdc4.pdc4_codice_pdc_finanziario_I,pdc4.pdc4_descrizione_pdc_finanziario_I,
pce5.pce5_codice_pdc_economico_V,pce5.pce5_descrizione_pdc_economico_V,
pce5.pce5_codice_pdc_economico_IV,pce5.pce5_descrizione_pdc_economico_IV,
pce5.pce5_codice_pdc_economico_III,pce5.pce5_descrizione_pdc_economico_III,
pce5.pce5_codice_pdc_economico_II,pce5.pce5_descrizione_pdc_economico_II,
pce5.pce5_codice_pdc_economico_I,pce5.pce5_descrizione_pdc_economico_I,
pce4.pce4_codice_pdc_economico_IV,pce4.pce4_descrizione_pdc_economico_IV,
pce4.pce4_codice_pdc_economico_III,pce4.pce4_descrizione_pdc_economico_III,
pce4.pce4_codice_pdc_economico_II,pce4.pce4_descrizione_pdc_economico_II,
pce4.pce4_codice_pdc_economico_I,pce4.pce4_descrizione_pdc_economico_I,
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,
-- 30.04.2019 Sofia siac-6255 - cambiato qui solo nome alias progr_all_all
progr_all_all.programma_code, progr_all_all.programma_desc,
t_flagPrenotazione.flagPrenotazione, t_flagPrenotazioneLiquidabile.flagPrenotazioneLiquidabile,
t_flagFrazionabile.flagFrazionabile,
imp.siope_tipo_debito_code, imp.siope_tipo_debito_desc, imp.siope_tipo_debito_desc_bnkit,
imp.siope_assenza_motivazione_code, imp.siope_assenza_motivazione_desc, imp.siope_assenza_motivazione_desc_bnkit,
coalesce(impFlagAttivaGsa.flag_attiva_gsa,'N') flag_attiva_gsa, -- 28.05.2018 Sofia siac-6102
-- 23.10.2018 Sofia SIAC-6336
-- 30.04.2019 Sofia siac-6255 - cambiato qui solo nome alias progr_all_all
progr_all_all.programma_stato,
progr_all_all.versione_cronop,
progr_all_all.desc_cronop,
progr_all_all.anno_cronop,
-- SIAC-7541 23.04.2020 Sofia
cdr_struttura.cod_cdr_struttura_comp,
cdr_struttura.desc_cdr_struttura_comp,
cdc_struttura.cod_cdc_struttura_comp,
cdc_struttura.desc_cdc_struttura_comp,
-- SIAC-6865 Sofia 04.08.2020 - aggiudicazioni
--0 annoprenotazioneorigine,
imp_aggiudicazione_anno.annoprenotazioneorigine,
imp_aggiudicazione.anno_impegno_da anno_impegno_aggiudicazione,
imp_aggiudicazione.numero_impegno_da num_impegno_aggiudicazione,
imp_aggiudicazione.mod_num_da num_modif_aggiudicazione
from
imp left join cap
on
imp.movgest_id=cap.movgest_id
left join sogg
on
imp.movgest_ts_id=sogg.movgest_ts_id
left join sogcla
on
imp.movgest_ts_id=sogcla.movgest_ts_id
left join tipoimpegno
on
imp.movgest_ts_id=tipoimpegno.movgest_ts_id
left join ricorrentespesa
on
imp.movgest_ts_id=ricorrentespesa.movgest_ts_id
left join truespesa
on
imp.movgest_ts_id=truespesa.movgest_ts_id
left join persaspesa
on
imp.movgest_ts_id=persaspesa.movgest_ts_id
left join polregunitarie
on
imp.movgest_ts_id=polregunitarie.movgest_ts_id
left join cla11
on
imp.movgest_ts_id=cla11.movgest_ts_id
left join cla12
on
imp.movgest_ts_id=cla12.movgest_ts_id
left join cla13
on
imp.movgest_ts_id=cla13.movgest_ts_id
left join cla14
on
imp.movgest_ts_id=cla14.movgest_ts_id
left join cla15
on
imp.movgest_ts_id=cla15.movgest_ts_id
left join t_annoCapitoloOrigine
on
imp.movgest_ts_id=t_annoCapitoloOrigine.movgest_ts_id
left join t_numeroCapitoloOrigine
on
imp.movgest_ts_id=t_numeroCapitoloOrigine.movgest_ts_id
left join t_annoOriginePlur
on
imp.movgest_ts_id=t_annoOriginePlur.movgest_ts_id
left join t_numeroArticoloOrigine
on
imp.movgest_ts_id=t_numeroArticoloOrigine.movgest_ts_id
left join t_annoRiaccertato
on
imp.movgest_ts_id=t_annoRiaccertato.movgest_ts_id
left join t_numeroRiaccertato
on
imp.movgest_ts_id=t_numeroRiaccertato.movgest_ts_id
left join t_numeroOriginePlur
on
imp.movgest_ts_id=t_numeroOriginePlur.movgest_ts_id
left join t_flagDaRiaccertamento
on
imp.movgest_ts_id=t_flagDaRiaccertamento.movgest_ts_id
-- 19.02.2020 Sofia jira siac-7292
left join t_flagDaReanno
on
imp.movgest_ts_id=t_flagDaReanno.movgest_ts_id
left join t_numeroUEBOrigine
on
imp.movgest_ts_id=t_numeroUEBOrigine.movgest_ts_id
left join t_cig
on
imp.movgest_ts_id=t_cig.movgest_ts_id
left join t_cup
on
imp.movgest_ts_id=t_cup.movgest_ts_id
left join t_NOTE_MOVGEST
on
imp.movgest_ts_id=t_NOTE_MOVGEST.movgest_ts_id
left join t_validato
on
imp.movgest_ts_id=t_validato.movgest_ts_id
left join t_annoFinanziamento
on
imp.movgest_ts_id=t_annoFinanziamento.movgest_ts_id
left join t_numeroAccFinanziamento
on
imp.movgest_ts_id=t_numeroAccFinanziamento.movgest_ts_id
left join t_flagCassaEconomale
on
imp.movgest_ts_id=t_flagCassaEconomale.movgest_ts_id
left join attoamm
on
imp.movgest_ts_id=attoamm.movgest_ts_id
left join impattuale
on
imp.movgest_ts_id=impattuale.movgest_ts_id
left join impiniziale
on
imp.movgest_ts_id=impiniziale.movgest_ts_id
left join imputilizzabile
on
imp.movgest_ts_id=imputilizzabile.movgest_ts_id
left join impliquidatoemessoquietanziato
on
imp.movgest_ts_id=impliquidatoemessoquietanziato.movgest_ts_id
left join cofog
on
imp.movgest_ts_id=cofog.movgest_ts_id
left join pdc5
on
imp.movgest_ts_id=pdc5.movgest_ts_id
left join pdc4
on
imp.movgest_ts_id=pdc4.movgest_ts_id
left join pce5
on
imp.movgest_ts_id=pce5.movgest_ts_id
left join pce4
on
imp.movgest_ts_id=pce4.movgest_ts_id
left join progr_all_all
on
imp.movgest_ts_id=progr_all_all.movgest_ts_id
left join t_flagPrenotazione
on
imp.movgest_ts_id=t_flagPrenotazione.movgest_ts_id
left join t_flagPrenotazioneLiquidabile
on
imp.movgest_ts_id=t_flagPrenotazioneLiquidabile.movgest_ts_id
left join t_flagFrazionabile
on
imp.movgest_ts_id=t_flagFrazionabile.movgest_ts_id
left join impFlagAttivaGsa
on
imp.movgest_ts_id=impFlagAttivaGsa.movgest_ts_id -- 28.05.2018 Sofia siac-6102
-- SIAC-7541 23.04.2020 Sofia
left join cdr_struttura on
imp.movgest_ts_id=cdr_struttura.movgest_ts_id
left join cdc_struttura on
imp.movgest_ts_id=cdc_struttura.movgest_ts_id
-- SIAC-6865 Sofia 04.08.2020 - aggiudicazioni
left join imp_aggiudicazione_anno on
imp.movgest_ts_id=imp_aggiudicazione_anno.movgest_ts_id
left join imp_aggiudicazione on
imp.movgest_id=imp_aggiudicazione.movgest_id_a
) xx
where xx.movgest_ts_tipo_code='T';



--------subimp

INSERT INTO
  siac.siac_dwh_subimpegno
(
  ente_proprietario_id,  ente_denominazione,  bil_anno,  cod_fase_operativa,  desc_fase_operativa,
  anno_impegno,  num_impegno,  desc_impegno,  cod_subimpegno,  cod_stato_subimpegno,  desc_stato_subimpegno,
  data_scadenza,  parere_finanziario,  cod_capitolo,  cod_articolo,  cod_ueb,  desc_capitolo,  desc_articolo,
  soggetto_id, cod_soggetto, desc_soggetto,  cf_soggetto,  cf_estero_soggetto, p_iva_soggetto,  cod_classe_soggetto,  desc_classe_soggetto,
  cod_tipo_impegno,  desc_tipo_impegno,   cod_spesa_ricorrente,  desc_spesa_ricorrente,  cod_perimetro_sanita_spesa,  desc_perimetro_sanita_spesa,
  cod_transazione_ue_spesa,  desc_transazione_ue_spesa,  cod_politiche_regionali_unit,  desc_politiche_regionali_unit,
  cod_pdc_finanziario_i,  desc_pdc_finanziario_i,  cod_pdc_finanziario_ii,  desc_pdc_finanziario_ii,
  cod_pdc_finanziario_iii,  desc_pdc_finanziario_iii,  cod_pdc_finanziario_iv,  desc_pdc_finanziario_iv,
  cod_pdc_finanziario_v,  desc_pdc_finanziario_v,  cod_pdc_economico_i,  desc_pdc_economico_i,
  cod_pdc_economico_ii,  desc_pdc_economico_ii,  cod_pdc_economico_iii,  desc_pdc_economico_iii,
  cod_pdc_economico_iv,  desc_pdc_economico_iv,  cod_pdc_economico_v,  desc_pdc_economico_v,
  cod_cofog_divisione,  desc_cofog_divisione,  cod_cofog_gruppo,  desc_cofog_gruppo,
  classificatore_1,  classificatore_1_valore,  classificatore_1_desc_valore,
  classificatore_2,  classificatore_2_valore,  classificatore_2_desc_valore,
  classificatore_3,  classificatore_3_valore,  classificatore_3_desc_valore,
  classificatore_4,  classificatore_4_valore,  classificatore_4_desc_valore,
  classificatore_5,  classificatore_5_valore,  classificatore_5_desc_valore,
  annocapitoloorigine,  numcapitoloorigine,  annoorigineplur, numarticoloorigine,  annoriaccertato,  numriaccertato,  numorigineplur,
  flagdariaccertamento,
  flagdareanno, -- 19.02.2020 Sofia jira siac-7292
  anno_atto_amministrativo,  num_atto_amministrativo,  oggetto_atto_amministrativo,  note_atto_amministrativo,
  cod_tipo_atto_amministrativo, desc_tipo_atto_amministrativo, desc_stato_atto_amministrativo,
   importo_iniziale,  importo_attuale,  importo_utilizzabile,
  note,  anno_finanziamento,  cig,  cup,  num_ueb_origine,  validato,
  num_accertamento_finanziamento,  importo_liquidato,  importo_quietanziato,  importo_emesso,
  --data_elaborazione,
  flagcassaeconomale,  data_inizio_val_stato_subimp,  data_inizio_val_subimp,
  data_creazione_subimp,  data_modifica_subimp,
  cod_cdc_atto_amministrativo,  desc_cdc_atto_amministrativo,
  cod_cdr_atto_amministrativo,  desc_cdr_atto_amministrativo,
  flagPrenotazione, flagPrenotazioneLiquidabile, flagFrazionabile,
  cod_siope_tipo_debito, desc_siope_tipo_debito, desc_siope_tipo_debito_bnkit,
  cod_siope_assenza_motivazione, desc_siope_assenza_motivazione, desc_siope_assenza_motiv_bnkit,
  flag_attiva_gsa, -- 28.05.2018 Sofia siac-6202
  -- SIAC-7541 23.04.2020 Sofia
  cod_cdr_struttura_comp,
  desc_cdr_struttura_comp,
  cod_cdc_struttura_comp,
  desc_cdc_struttura_comp,
  -- SIAC-7899 Sofia 26.11.2020
  comp_tipo_id,
  -- SIAC-7593 Sofia 11.05.2020 - INIZIO
  comp_tipo_code,
  comp_tipo_desc,
  comp_tipo_macro_code,
  comp_tipo_macro_desc,
  comp_tipo_sotto_tipo_code,
  comp_tipo_sotto_tipo_desc,
  comp_tipo_ambito_code,
  comp_tipo_ambito_desc,
  comp_tipo_fonte_code,
  comp_tipo_fonte_desc,
  comp_tipo_fase_code ,
  comp_tipo_fase_desc,
  comp_tipo_def_code,
  comp_tipo_def_desc ,
  comp_tipo_gest_aut,
  comp_tipo_anno
  -- SIAC-7593 Sofia 11.05.2020 - FINE
  )
select
xx.ente_proprietario_id, xx.ente_denominazione, xx.anno,xx.fase_operativa_code, xx.fase_operativa_desc ,
xx.movgest_anno, xx.movgest_numero, xx.movgest_desc, xx.movgest_ts_code, --xx.movgest_ts_desc,
xx.movgest_stato_code, xx.movgest_stato_desc, xx.movgest_ts_scadenza_data,
case when xx.parere_finanziario=false then 'F' else 'S' end parere_finanziario,-- xx.movgest_id, xx.movgest_ts_id, xx.movgest_ts_tipo_code,
xx.elem_code, xx.elem_code2, xx.elem_code3, xx.elem_desc, xx.elem_desc2, --xx.bil_id,
xx.soggetto_id, xx.soggetto_code, xx.soggetto_desc, xx.codice_fiscale,xx.codice_fiscale_estero, xx.partita_iva, xx.soggetto_classe_code, xx.soggetto_classe_desc,
xx.tipoimpegno_classif_code,xx.tipoimpegno_classif_desc,xx.ricorrentespesa_classif_code,xx.ricorrentespesa_classif_desc,
xx.persaspesa_classif_code,xx.persaspesa_classif_desc, xx.truespesa_classif_code, xx.truespesa_classif_desc, xx.polregunitarie_classif_code,xx.polregunitarie_classif_desc,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_I else xx.pdc4_codice_pdc_finanziario_I end codice_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_I else xx.pdc4_descrizione_pdc_finanziario_I end descrizione_pdc_finanziario_I,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_II else xx.pdc4_codice_pdc_finanziario_II end codice_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_II else xx.pdc4_descrizione_pdc_finanziario_II end descrizione_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_III else xx.pdc4_codice_pdc_finanziario_III end codice_pdc_finanziario_III,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_III else xx.pdc4_descrizione_pdc_finanziario_III end descrizione_pdc_finanziario_III,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_IV else xx.pdc4_codice_pdc_finanziario_IV end codice_pdc_finanziario_IV  ,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_IV else xx.pdc4_descrizione_pdc_finanziario_IV end descrizione_pdc_finanziario_IV,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_V end codice_pdc_finanziario_V  ,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_V end descrizione_pdc_finanziario_V,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_I else xx.pce4_codice_pdc_economico_I end codice_pdc_economico_I,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_I else xx.pce4_descrizione_pdc_economico_I end descrizione_pdc_economico_I,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_II else xx.pce4_codice_pdc_economico_II end codice_pdc_economico_II,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_II else xx.pce4_descrizione_pdc_economico_II end descrizione_pdc_economico_II,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_III else xx.pce4_codice_pdc_economico_III end codice_pdc_economico_III,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_III else xx.pce4_descrizione_pdc_economico_III end descrizione_pdc_economico_III,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_IV else xx.pce4_codice_pdc_economico_IV end codice_pdc_economico_IV  ,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_IV else xx.pce4_descrizione_pdc_economico_IV end descrizione_pdc_economico_IV,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_V end codice_pdc_economico_V  ,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_V end descrizione_pdc_economico_V,
xx.codice_cofog_divisione, xx.descrizione_cofog_divisione,xx.codice_cofog_gruppo,xx.descrizione_cofog_gruppo,
xx.cla11_classif_tipo_code,xx.cla11_classif_code,xx.cla11_classif_desc,xx.cla12_classif_tipo_code,xx.cla12_classif_code,xx.cla12_classif_desc,
xx.cla13_classif_tipo_code,xx.cla13_classif_code,xx.cla13_classif_desc,xx.cla14_classif_tipo_code,xx.cla14_classif_code,xx.cla14_classif_desc,
xx.cla15_classif_tipo_code,xx.cla15_classif_code,xx.cla15_classif_desc,
xx.annoCapitoloOrigine,xx.numeroCapitoloOrigine,xx.annoOriginePlur,xx.numeroArticoloOrigine,xx.annoRiaccertato,xx.numeroRiaccertato,
xx.numeroOriginePlur, xx.flagDaRiaccertamento,
xx.flagDaReanno, -- 19.02.2020 Sofia jira siac-7292
xx.attoamm_anno, xx.attoamm_numero, xx.attoamm_oggetto, xx.attoamm_note,
xx.attoamm_tipo_code, xx.attoamm_tipo_desc, xx.attoamm_stato_desc,
xx.importo_iniziale, xx.importo_attuale, xx.importo_utilizzabile,
xx.NOTE_MOVGEST,  xx.annoFinanziamento, xx.cig,xx.cup, xx.numeroUEBOrigine,  xx.validato,
--xx.attoamm_id,
xx.numeroAccFinanziamento,  xx.importo_liquidato,  xx.importo_quietanziato, xx.importo_emesso,
xx.flagCassaEconomale,
xx.data_inizio_val_stato_subimp, xx.data_inizio_val_subimp,
xx.data_creazione_subimp, xx.data_modifica_subimp,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdc_code::varchar else xx.cdr_cdc_code::varchar end cdc_code,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdc_desc::varchar else xx.cdr_cdc_desc::varchar end cdc_desc,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdr_code::varchar else xx.cdr_cdr_code::varchar end cdr_code,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdr_desc::varchar else xx.cdr_cdr_desc::varchar end cdr_desc,
xx.flagPrenotazione, xx.flagPrenotazioneLiquidabile, xx.flagFrazionabile,
xx.siope_tipo_debito_code, xx.siope_tipo_debito_desc, xx.siope_tipo_debito_desc_bnkit,
xx.siope_assenza_motivazione_code, xx.siope_assenza_motivazione_desc, xx.siope_assenza_motivazione_desc_bnkit,
xx.flag_attiva_gsa, -- 28.05.2018 Sofia siac-6202
/*xx.data_inizio_val_stato_subimp, xx.data_inizio_val_subimp,
xx.data_creazione_subimp, xx.data_modifica_subimp,*/
-- SIAC-7541 23.04.2020 Sofia
xx.cod_cdr_struttura_comp,
xx.desc_cdr_struttura_comp,
xx.cod_cdc_struttura_comp,
xx.desc_cdc_struttura_comp,
-- SIAC-7899 Sofia 26.11.2020
xx.comp_tipo_id,
-- SIAC-7593 Sofia 11.05.2020 - INIZIO
xx.comp_tipo_code,
xx.comp_tipo_desc,
xx.comp_tipo_macro_code,
xx.comp_tipo_macro_desc,
xx.comp_tipo_sotto_tipo_code,
xx.comp_tipo_sotto_tipo_desc,
xx.comp_tipo_ambito_code,
xx.comp_tipo_ambito_desc,
xx.comp_tipo_fonte_code,
xx.comp_tipo_fonte_desc,
xx.comp_tipo_fase_code ,
xx.comp_tipo_fase_desc,
xx.comp_tipo_def_code,
xx.comp_tipo_def_desc ,
xx.comp_tipo_gest_aut,
xx.comp_tipo_anno
-- SIAC-7593 Sofia 11.05.2020 - FINE
 from (
with imp as (
SELECT
e.ente_proprietario_id, e.ente_denominazione, d.anno,
       b.movgest_anno, b.movgest_numero, b.movgest_desc, a.movgest_ts_code, a.movgest_ts_desc,
       i.movgest_stato_code, i.movgest_stato_desc,
       a.movgest_ts_scadenza_data, b.parere_finanziario, b.movgest_id, a.movgest_ts_id,
       g.movgest_ts_tipo_code,    c.bil_id,
       h.validita_inizio as data_inizio_val_stato_subimp,
       a.data_creazione as data_creazione_subimp,
       a.validita_inizio as  data_inizio_val_subimp,
       a.data_modifica as data_modifica_subimp,
       b.data_creazione as data_creazione_imp,
       b.validita_inizio as data_inizio_val_imp,
       b.data_modifica as data_modifica_imp,
       m.fase_operativa_code, m.fase_operativa_desc,
       n.siope_tipo_debito_code, n.siope_tipo_debito_desc, n.siope_tipo_debito_desc_bnkit,
       o.siope_assenza_motivazione_code, o.siope_assenza_motivazione_desc, o.siope_assenza_motivazione_desc_bnkit
FROM
siac_t_movgest_ts a
left join siac_d_siope_tipo_debito n on n.siope_tipo_debito_id = a.siope_tipo_debito_id
                                     and n.data_cancellazione is null
                                     and n.validita_fine is null
left join siac_d_siope_assenza_motivazione o on o.siope_assenza_motivazione_id = a.siope_assenza_motivazione_id
                                             and o.data_cancellazione is null
                                             and o.validita_fine is null
, siac_t_movgest b
, siac_t_bil c
,  siac_t_periodo d
, siac_t_ente_proprietario e
,  siac_d_movgest_tipo f
,  siac_d_movgest_ts_tipo g
,  siac_r_movgest_ts_stato h
,  siac_d_movgest_stato i,
siac_r_bil_fase_operativa l, siac_d_fase_operativa m
where a.movgest_id=  b.movgest_id and
 b.bil_id = c.bil_id and
 d.periodo_id = c.periodo_id and
 e.ente_proprietario_id = b.ente_proprietario_id   and
 b.movgest_tipo_id = f.movgest_tipo_id and
 a.movgest_ts_tipo_id = g.movgest_ts_tipo_id      and
 h.movgest_ts_id = a.movgest_ts_id   and
 h.movgest_stato_id = i.movgest_stato_id
and e.ente_proprietario_id = p_ente_proprietario_id
AND d.anno = p_anno_bilancio
AND f.movgest_tipo_code = 'I'
--AND p_data BETWEEN h.validita_inizio AND COALESCE(h.validita_fine, p_data)
--and  b.movgest_anno::integer=2020
--and  exists ( select 1 from siac_r_movgest_aggiudicazione r where r.movgest_id_a=a.movgest_id )
--and  exists ( select 1 from siac_r_movgest_bil_elem r where r.movgest_id=a.movgest_id and  r.elem_det_comp_tipo_id is not null and r.validita_fine is null and r.data_cancellazione is null)
--and  b.movgest_numero::integer IN (5116,5138,5126)
and l.bil_id=c.bil_id
and m.fase_operativa_id=l.fase_operativa_id
--AND p_data BETWEEN l.validita_inizio AND COALESCE(l.validita_fine, p_data)
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND c.data_cancellazione IS NULL
AND d.data_cancellazione IS NULL
AND e.data_cancellazione IS NULL
AND f.data_cancellazione IS NULL
AND g.data_cancellazione IS NULL
AND h.data_cancellazione IS NULL
AND i.data_cancellazione IS NULL
AND a.validita_fine IS NULL
AND b.validita_fine IS NULL
AND c.validita_fine IS NULL
AND d.validita_fine IS NULL
AND e.validita_fine IS NULL
AND f.validita_fine IS NULL
AND g.validita_fine IS NULL
AND h.validita_fine IS NULL
AND i.validita_fine IS NULL
--limit 100
),
cap as -- SIAC-7593 Sofia 11.05.2020
(
with  -- SIAC-7593 Sofia 11.05.2020
cap_elem as
(
select l.movgest_id,
       m.elem_code, m.elem_code2, m.elem_code3, m.elem_desc, m.elem_desc2,
       l.elem_det_comp_tipo_id
From siac_r_movgest_bil_elem l, siac_t_bil_elem m
where l.elem_id=m.elem_id
and l.ente_proprietario_id=p_ente_proprietario_id
--AND p_data BETWEEN l.validita_inizio AND COALESCE(l.validita_fine, p_data)
--and l.elem_det_comp_tipo_id is not null
AND l.data_cancellazione IS NULL
AND m.data_cancellazione IS NULL
AND l.validita_fine IS NULL
AND m.validita_fine IS NULL
),
-- SIAC-7593 Sofia 11.05.2020
comp_tipo_imp as
(
select
     tipo.elem_det_comp_tipo_id comp_tipo_id,-- 26.11.2020 Sofia SIAC-7899
     --tipo.elem_det_comp_tipo_code comp_tipo_code, -- 26.11.2020 Sofia SIAC-7899
	 tipo.elem_det_comp_tipo_id::varchar(200) comp_tipo_code, -- -- 26.11.2020 Sofia SIAC-7899
     tipo.elem_det_comp_tipo_desc comp_tipo_desc,
     macro.elem_det_comp_macro_tipo_code comp_tipo_macro_code,
     macro.elem_det_comp_macro_tipo_desc comp_tipo_macro_desc,
     sotto_tipo.elem_det_comp_sotto_tipo_code comp_tipo_sotto_tipo_code,
     sotto_tipo.elem_det_comp_sotto_tipo_desc comp_tipo_sotto_tipo_desc,
     ambito_tipo.elem_det_comp_tipo_ambito_code comp_tipo_ambito_code,
     ambito_tipo.elem_det_comp_tipo_ambito_desc comp_tipo_ambito_desc,
     fonte_tipo.elem_det_comp_tipo_fonte_code comp_tipo_fonte_code,
     fonte_tipo.elem_det_comp_tipo_fonte_desc comp_tipo_fonte_desc,
     fase_tipo.elem_det_comp_tipo_fase_code comp_tipo_fase_code ,
     fase_tipo.elem_det_comp_tipo_fase_desc comp_tipo_fase_desc,
     def_tipo.elem_det_comp_tipo_def_code comp_tipo_def_code,
     def_tipo.elem_det_comp_tipo_def_desc comp_tipo_def_desc ,
     (case when tipo.elem_det_comp_tipo_gest_aut=true then 'Solo automatica'
        else 'Manuale' end)::varchar(50) comp_tipo_gest_aut,
     per.anno::integer comp_tipo_anno
from siac_d_bil_elem_det_comp_macro_tipo macro,
     siac_d_bil_elem_det_comp_tipo tipo
        left join siac_d_bil_elem_det_comp_sotto_tipo  sotto_tipo  on (tipo.elem_det_comp_sotto_tipo_id  =sotto_tipo.elem_det_comp_sotto_tipo_id)
        left join siac_d_bil_elem_det_comp_tipo_ambito ambito_tipo on (tipo.elem_det_comp_tipo_ambito_id =ambito_tipo.elem_det_comp_tipo_ambito_id)
        left join siac_d_bil_elem_det_comp_tipo_fonte  fonte_tipo  on (tipo.elem_det_comp_tipo_fonte_id  =fonte_tipo.elem_det_comp_tipo_fonte_id)
        left join siac_d_bil_elem_det_comp_tipo_fase   fase_tipo   on (tipo.elem_det_comp_tipo_fase_id   =fase_tipo.elem_det_comp_tipo_fase_id)
        left join siac_d_bil_elem_det_comp_tipo_def    def_tipo    on (tipo.elem_det_comp_tipo_def_id    =def_tipo.elem_det_comp_tipo_def_id)
        left join siac_t_periodo per                               on (tipo.periodo_id                   =per.periodo_id)

where macro.elem_det_comp_macro_tipo_id=tipo.elem_det_comp_macro_tipo_id
)
select
     cap_elem.movgest_id,
     cap_elem.elem_code,
     cap_elem.elem_code2,
     cap_elem.elem_code3,
     cap_elem.elem_desc,
     cap_elem.elem_desc2,
     comp_tipo_imp.comp_tipo_id, -- SIAC-7899 Sofia 26.11.2020
     comp_tipo_imp.comp_tipo_code,
     comp_tipo_imp.comp_tipo_desc,
     comp_tipo_imp.comp_tipo_macro_code,
     comp_tipo_imp.comp_tipo_macro_desc,
     comp_tipo_imp.comp_tipo_sotto_tipo_code,
     comp_tipo_imp.comp_tipo_sotto_tipo_desc,
     comp_tipo_imp.comp_tipo_ambito_code,
     comp_tipo_imp.comp_tipo_ambito_desc,
     comp_tipo_imp.comp_tipo_fonte_code,
     comp_tipo_imp.comp_tipo_fonte_desc,
     comp_tipo_imp.comp_tipo_fase_code ,
     comp_tipo_imp.comp_tipo_fase_desc,
     comp_tipo_imp.comp_tipo_def_code,
     comp_tipo_imp.comp_tipo_def_desc ,
     comp_tipo_imp.comp_tipo_gest_aut,
     comp_tipo_imp.comp_tipo_anno
from cap_elem left join comp_tipo_imp on (cap_elem.elem_det_comp_tipo_id=comp_tipo_imp.comp_tipo_id) -- SIAC-7899 Sofia 26.11.2020
), -- SIAC-7593 Sofia 11.05.2020
sogg as (SELECT
a.movgest_ts_id,
b.soggetto_code, b.soggetto_desc, b.codice_fiscale,
b.codice_fiscale_estero, b.partita_iva, b.soggetto_id
/*INTO v_codice_soggetto, v_descrizione_soggetto, v_codice_fiscale_soggetto,
v_codice_fiscale_estero_soggetto, v_partita_iva_soggetto, v_soggetto_id*/
FROM siac_r_movgest_ts_sog a, siac_t_soggetto b
WHERE a.soggetto_id = b.soggetto_id
and a.ente_proprietario_id=p_ente_proprietario_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
),
sogcla as (SELECT
a.movgest_ts_id,b.soggetto_classe_code, b.soggetto_classe_desc
--INTO v_codice_classe_soggetto, v_descrizione_classe_soggetto
FROM siac_r_movgest_ts_sogclasse a, siac.siac_d_soggetto_classe b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.soggetto_classe_id = b.soggetto_classe_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
)
,
--classificatori non gerarchici
tipoimpegno as (
SELECT
a.movgest_ts_id,b.classif_code tipoimpegno_classif_code,b.classif_desc tipoimpegno_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TIPO_IMPEGNO'
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
ricorrentespesa as (
SELECT
a.movgest_ts_id,b.classif_code ricorrentespesa_classif_code,b.classif_desc ricorrentespesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='RICORRENTE_SPESA'
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
truespesa as (
SELECT
a.movgest_ts_id,b.classif_code truespesa_classif_code,b.classif_desc truespesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
persaspesa as (
SELECT
a.movgest_ts_id,b.classif_code persaspesa_classif_code,b.classif_desc persaspesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='PERIMETRO_SANITARIO_SPESA'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
polregunitarie as (
SELECT
a.movgest_ts_id,b.classif_code polregunitarie_classif_code,b.classif_desc polregunitarie_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='POLITICHE_REGIONALI_UNITARIE'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
cla11 as (
SELECT
a.movgest_ts_id,b.classif_code cla11_classif_code,b.classif_desc cla11_classif_desc, c.classif_tipo_code cla11_classif_tipo_code
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_11'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla12 as (
SELECT
a.movgest_ts_id,b.classif_code cla12_classif_code,b.classif_desc cla12_classif_desc, c.classif_tipo_code cla12_classif_tipo_code
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_12'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla13 as (
SELECT
a.movgest_ts_id,b.classif_code cla13_classif_code,b.classif_desc cla13_classif_desc, c.classif_tipo_code cla13_classif_tipo_code
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_13'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla14 as (
SELECT
a.movgest_ts_id,b.classif_code cla14_classif_code,b.classif_desc cla14_classif_desc, c.classif_tipo_code cla14_classif_tipo_code
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_14'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla15 as (
SELECT
a.movgest_ts_id,b.classif_code cla15_classif_code,b.classif_desc cla15_classif_desc, c.classif_tipo_code cla15_classif_tipo_code
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_15'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
--sezione attributi
, t_annoCapitoloOrigine as (
SELECT
a.movgest_ts_id
, a.testo annoCapitoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoCapitoloOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroCapitoloOrigine as (
SELECT
a.movgest_ts_id
, a.testo numeroCapitoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroCapitoloOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoOriginePlur as (
SELECT
a.movgest_ts_id
, a.testo annoOriginePlur
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoOriginePlur' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroArticoloOrigine as (
SELECT
a.movgest_ts_id
, a.testo numeroArticoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroArticoloOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoRiaccertato as (
SELECT
a.movgest_ts_id
, a.testo annoRiaccertato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoRiaccertato' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroRiaccertato as (
SELECT
a.movgest_ts_id
, a.testo numeroRiaccertato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroRiaccertato' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroOriginePlur as (
SELECT
a.movgest_ts_id
, a.testo numeroOriginePlur
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroOriginePlur' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagDaRiaccertamento as (
SELECT
a.movgest_ts_id
, a."boolean" flagDaRiaccertamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagDaRiaccertamento' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
-- 19.02.2020 Sofia jira siac-7292
, t_flagDaReanno as (
SELECT
a.movgest_ts_id
, a."boolean" flagDaReanno
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagDaReanno' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)

, t_numeroUEBOrigine as (
SELECT
a.movgest_ts_id
, a.testo numeroUEBOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroUEBOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_cig as (
SELECT
a.movgest_ts_id
, a.testo cig
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='cig' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_cup as (
SELECT
a.movgest_ts_id
, a.testo cup
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='cup' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_NOTE_MOVGEST as (
SELECT
a.movgest_ts_id
, a.testo NOTE_MOVGEST
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='NOTE_MOVGEST' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_validato as (
SELECT
a.movgest_ts_id
, a."boolean" validato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='validato' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoFinanziamento as (
SELECT
a.movgest_ts_id
, a.testo annoFinanziamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoFinanziamento' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroAccFinanziamento as (
SELECT
a.movgest_ts_id
, a.testo numeroAccFinanziamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroAccFinanziamento' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagCassaEconomale as (
SELECT
a.movgest_ts_id
, a."boolean" flagCassaEconomale
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagCassaEconomale' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagPrenotazione as (
SELECT
a.movgest_ts_id
, a."boolean" flagPrenotazione
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagPrenotazione' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagPrenotazioneLiquidabile as (
SELECT
a.movgest_ts_id
, a."boolean" flagPrenotazioneLiquidabile
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagPrenotazioneLiquidabile' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
),
t_flagFrazionabile as (
SELECT
a.movgest_ts_id
, a."boolean" flagFrazionabile
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagFrazionabile' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
),
--atto amm
attoamm as (
with atmc as (
with atm as (
SELECT
a.movgest_ts_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM
siac.siac_r_movgest_ts_atto_amm a,
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c,
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE
a.ente_proprietario_id=p_ente_proprietario_id--p_ente_proprietario_id
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
AND   d.validita_fine IS NULL
AND   e.validita_fine IS NULL
)
, atmrclass as (select a.attoamm_id,a.classif_id from siac_r_atto_amm_class a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.data_cancellazione is null
AND   a.validita_fine IS NULL
--and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
select atm.*,atmrclass.classif_id from atm left join atmrclass
on atmrclass.attoamm_id=atm.attoamm_id
)
,
cdc as (
select a.classif_id,a.classif_code cdc_cdc_code,a.classif_desc cdc_cdc_desc
,a2.classif_code cdc_cdr_code,a2.classif_desc cdc_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b, siac_r_class_fam_tree c,siaC_t_class a2
where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDC'
and c.classif_id=a.classif_id
--and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
and a2.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a2.data_cancellazione is null
and a2.classif_id=c.classif_id_padre
/*and a.validita_fine is null
and b.validita_fine is null
and c.validita_fine is null
and a2.validita_fine is null*/
)
,cdr as (
select a.classif_id,null cdr_cdc_code,null cdr_cdc_desc
,a.classif_code cdr_cdr_code,a.classif_desc cdr_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b
 where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDR'
and a.data_cancellazione is null
and b.data_cancellazione is null
/*and a.validita_fine is null
and b.validita_fine is null*/
)
select
atmc.movgest_ts_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on
atmc.classif_id=cdc.classif_id
left join cdr on
atmc.classif_id=cdr.classif_id),
impattuale as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_attuale, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
and a.validita_fine is null
and b.validita_fine is null
and b.movgest_ts_det_tipo_code='A'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
)
,
impiniziale as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_iniziale, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
and a.validita_fine is null
and b.validita_fine is null
and b.movgest_ts_det_tipo_code='I'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
)
,
imputilizzabile as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_utilizzabile, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
and a.validita_fine is null
and b.validita_fine is null
and b.movgest_ts_det_tipo_code='U'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
),
impliquidatoemessoquietanziato as (select tz.* from (
with liquid as (
 SELECT sum(COALESCE(b.liq_importo,0)) importo_liquidato, a.movgest_ts_id,
b.liq_id
    FROM siac.siac_r_liquidazione_movgest a, siac.siac_t_liquidazione b,
    siac.siac_d_liquidazione_stato c, siac.siac_r_liquidazione_stato d
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id
    AND   a.liq_id = b.liq_id
    AND   b.liq_id = d.liq_id
    AND   d.liq_stato_id = c.liq_stato_id
    AND   c.liq_stato_code <> 'A'
    --AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
    --AND p_data BETWEEN d.validita_inizio AND COALESCE(d.validita_fine, p_data)
    AND a.data_cancellazione IS NULL
    AND b.data_cancellazione IS NULL
    AND c.data_cancellazione IS NULL
    AND d.data_cancellazione IS NULL
    AND a.validita_fine IS NULL
    AND b.validita_fine IS NULL
    AND c.validita_fine IS NULL
    AND d.validita_fine IS NULL
    group by a.movgest_ts_id, b.liq_id),
emes as (
  SELECT COALESCE(SUM(e.ord_ts_det_importo),0) importo_emesso, a.liq_id
            FROM
            siac_r_liquidazione_ord a,
            siac_t_ordinativo_ts b,
                 siac_r_ordinativo_stato c, siac_d_ordinativo_stato d,
                 siac_t_ordinativo_ts_det e, siac_d_ordinativo_ts_det_tipo f
            WHERE
            a.ente_proprietario_id=p_ente_proprietario_id and
            a.sord_id=b.ord_ts_id
            AND  c.ord_id = b.ord_id
            AND  c.ord_stato_id = d.ord_stato_id
            AND  e.ord_ts_id = b.ord_ts_id
            AND  f.ord_ts_det_tipo_id = e.ord_ts_det_tipo_id
            AND  d.ord_stato_code <> 'A'
            AND  f.ord_ts_det_tipo_code = 'A'
            --AND  p_data BETWEEN  a.validita_inizio  AND COALESCE(a.validita_fine, p_data)
            --AND  p_data BETWEEN  c.validita_inizio  AND COALESCE(c.validita_fine, p_data)
            AND  a.data_cancellazione IS NULL
            AND  b.data_cancellazione IS NULL
            AND  c.data_cancellazione IS NULL
            AND  d.data_cancellazione IS NULL
            AND  e.data_cancellazione IS NULL
            AND  f.data_cancellazione IS NULL
            AND  a.validita_fine IS NULL
            AND  b.validita_fine IS NULL
            AND  c.validita_fine IS NULL
            AND  d.validita_fine IS NULL
            AND  e.validita_fine IS NULL
            AND  f.validita_fine IS NULL
            group by a.liq_id),
quiet as (
  SELECT COALESCE(SUM(e.ord_ts_det_importo),0) importo_quietanziato, a.liq_id
            FROM
            siac_r_liquidazione_ord a,
            siac_t_ordinativo_ts b,
                 siac_r_ordinativo_stato c, siac_d_ordinativo_stato d,
                 siac_t_ordinativo_ts_det e, siac_d_ordinativo_ts_det_tipo f
            WHERE
            a.ente_proprietario_id=p_ente_proprietario_id and
            a.sord_id=b.ord_ts_id
            AND  c.ord_id = b.ord_id
            AND  c.ord_stato_id = d.ord_stato_id
            AND  e.ord_ts_id = b.ord_ts_id
            AND  f.ord_ts_det_tipo_id = e.ord_ts_det_tipo_id
            AND  d.ord_stato_code= 'Q'
            AND  f.ord_ts_det_tipo_code = 'A'
            --AND  p_data BETWEEN  a.validita_inizio  AND COALESCE(a.validita_fine, p_data)
            --AND  p_data BETWEEN  c.validita_inizio  AND COALESCE(c.validita_fine, p_data)
            AND  a.data_cancellazione IS NULL
            AND  b.data_cancellazione IS NULL
            AND  c.data_cancellazione IS NULL
            AND  d.data_cancellazione IS NULL
            AND  e.data_cancellazione IS NULL
            AND  f.data_cancellazione IS NULL
            AND  a.validita_fine IS NULL
            AND  b.validita_fine IS NULL
            AND  c.validita_fine IS NULL
            AND  d.validita_fine IS NULL
            AND  e.validita_fine IS NULL
            AND  f.validita_fine IS NULL
            group by a.liq_id)
select liquid.movgest_ts_id,coalesce(sum(liquid.importo_liquidato),0) importo_liquidato,
coalesce(sum(emes.importo_emesso),0) importo_emesso,
coalesce(sum(quiet.importo_quietanziato),0) importo_quietanziato
from liquid left join emes ON
liquid.liq_id=emes.liq_id
left join quiet ON
liquid.liq_id=quiet.liq_id
group by liquid.movgest_ts_id
) as tz),
cofog as (
select distinct r.movgest_ts_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
a2.classif_code codice_cofog_divisione,a2.classif_desc descrizione_cofog_divisione
from
siac_r_movgest_class r,
siac_t_class a,siac_d_class_tipo b,
--DIVISIONE_COFOG
siac_r_class_fam_tree d2,
siac_t_class a2
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='GRUPPO_COFOG'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
--and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
)
, pdc5 as (
select distinct
r.movgest_ts_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
a2.classif_code pdc5_codice_pdc_finanziario_IV,a2.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_movgest_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
-- SIAC-5883 Daniela 13.02.2018
-- and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
-- FINE SIAC-5883 Daniela 13.02.2018
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
--and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
AND   d5.data_cancellazione IS NULL
AND   a5.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL
AND   d5.validita_fine IS NULL
AND   a5.validita_fine IS NULL*/
)
, pdc4 as (
select distinct r.movgest_ts_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
a2.classif_code pdc4_codice_pdc_finanziario_III,a2.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_movgest_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
-- SIAC-5883 Daniela 13.02.2018
-- and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
-- FINE SIAC-5883 Daniela 13.02.2018
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL*/
)
, pce5 as (
select distinct r.movgest_ts_id,
--r.classif_id,
a.classif_code pce5_codice_pdc_economico_V,a.classif_desc pce5_descrizione_pdc_economico_V,
a2.classif_code pce5_codice_pdc_economico_IV,a2.classif_desc pce5_descrizione_pdc_economico_IV,
a3.classif_code pce5_codice_pdc_economico_III,a3.classif_desc pce5_descrizione_pdc_economico_III,
a4.classif_code pce5_codice_pdc_economico_II,a4.classif_desc pce5_descrizione_pdc_economico_II,
a5.classif_code pce5_codice_pdc_economico_I,a5.classif_desc pce5_descrizione_pdc_economico_I
 from siac_r_movgest_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
--and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
AND   d5.data_cancellazione IS NULL
AND   a5.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL
AND   d5.validita_fine IS NULL
AND   a5.validita_fine IS NULL*/
)
, pce4 as (
select distinct r.movgest_ts_id,
a.classif_code pce4_codice_pdc_economico_IV,a.classif_desc pce4_descrizione_pdc_economico_IV,
a2.classif_code pce4_codice_pdc_economico_III,a2.classif_desc pce4_descrizione_pdc_economico_III,
a3.classif_code pce4_codice_pdc_economico_II,a3.classif_desc pce4_descrizione_pdc_economico_II,
a4.classif_code pce4_codice_pdc_economico_I,a4.classif_desc pce4_descrizione_pdc_economico_I
 from siac_r_movgest_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL*/
),
impFlagAttivaGsa as -- 28.05.2018 Sofia siac-6102
(
select rattr.movgest_ts_id, rattr.boolean flag_attiva_gsa
from siac_r_movgest_ts_attr rattr, siac_t_attr attr
where attr.ente_proprietario_id=p_ente_proprietario_id
and   attr.attr_code='FlagAttivaGsa'
and   rattr.attr_id=attr.attr_id
and   rattr.data_cancellazione is null
and   rattr.validita_fine is null
),
-- SIAC-7541 23.04.2020 Sofia
struttura_comp as
(
 with
 impegno_ts as
 (
  select ts.movgest_id, ts.movgest_ts_id
  from siac_t_movgest_Ts ts,siac_d_movgest_ts_tipo tipo
  where tipo.ente_proprietario_id=p_ente_proprietario_id
  and   tipo.movgest_ts_tipo_code='T'
  and   ts.movgest_ts_tipo_id=tipo.movgest_ts_tipo_id
  and   ts.data_cancellazione is null
  and   ts.validita_fine is null
 ),
 cdc_struttura_comp as
 (
 select rc.movgest_ts_id, c.classif_code, c.classif_desc
 from siac_r_movgest_class rc,siac_t_class c,siac_d_class_tipo tipo
 where tipo.ente_proprietario_id=p_ente_proprietario_id
 and   tipo.classif_tipo_code='CDC'
 and   c.classif_tipo_id=tipo.classif_tipo_id
 and   rc.classif_id=c.classif_id
 and   rc.data_cancellazione is null
 and   rc.validita_fine is null
 ),
 cdr_struttura_comp as
 (
 select rc.movgest_ts_id, c.classif_code, c.classif_desc
 from siac_r_movgest_class rc,siac_t_class c,siac_d_class_tipo tipo
 where tipo.ente_proprietario_id=p_ente_proprietario_id
 and   tipo.classif_tipo_code='CDR'
 and   c.classif_tipo_id=tipo.classif_tipo_id
 and   rc.classif_id=c.classif_id
 and   rc.data_cancellazione is null
 and   rc.validita_fine is null
 )
 select impegno_Ts.movgest_id,
        cdr_struttura_comp.classif_code cod_cdr_struttura_comp,
        cdr_struttura_comp.classif_desc desc_cdr_struttura_comp,
        cdc_struttura_comp.classif_code cod_cdc_struttura_comp,
        cdc_struttura_comp.classif_code desc_cdc_struttura_comp
 from impegno_ts
      left join cdc_struttura_comp on  impegno_ts.movgest_ts_id=cdc_struttura_comp.movgest_ts_id
      left join cdr_struttura_comp on  impegno_ts.movgest_ts_id=cdr_struttura_comp.movgest_ts_id
) -- SIAC-7541 23.04.2020 Sofia
select
imp.ente_proprietario_id, imp.ente_denominazione, imp.anno,
imp.movgest_anno, imp.movgest_numero, imp.movgest_desc, imp.movgest_ts_code, imp.movgest_ts_desc,
imp.movgest_stato_code, imp.movgest_stato_desc,
imp.movgest_ts_scadenza_data, imp.parere_finanziario, imp.movgest_id, imp.movgest_ts_id,
imp.movgest_ts_tipo_code,
cap.elem_code, cap.elem_code2, cap.elem_code3, cap.elem_desc, cap.elem_desc2,
imp.bil_id,
imp.data_inizio_val_stato_subimp,
imp.data_creazione_subimp,
imp.data_inizio_val_subimp,
imp.data_modifica_subimp,
imp.data_creazione_imp,
imp.data_inizio_val_imp,
imp.data_modifica_imp,
imp.fase_operativa_code, imp.fase_operativa_desc ,
sogg.soggetto_code, sogg.soggetto_desc, sogg.codice_fiscale,
sogg.codice_fiscale_estero, sogg.partita_iva, sogg.soggetto_id
,sogcla.soggetto_classe_code, sogcla.soggetto_classe_desc,
tipoimpegno.tipoimpegno_classif_code,
tipoimpegno.tipoimpegno_classif_desc,
ricorrentespesa.ricorrentespesa_classif_code,
ricorrentespesa.ricorrentespesa_classif_desc,
truespesa.truespesa_classif_code,
truespesa.truespesa_classif_desc,
persaspesa.persaspesa_classif_code,
persaspesa.persaspesa_classif_desc,
polregunitarie.polregunitarie_classif_code,
polregunitarie.polregunitarie_classif_desc,
cla11.cla11_classif_code,
cla11.cla11_classif_desc,
cla11.cla11_classif_tipo_code,
cla12.cla12_classif_code,
cla12.cla12_classif_desc,
cla12.cla12_classif_tipo_code,
cla13.cla13_classif_code,
cla13.cla13_classif_desc,
cla13.cla13_classif_tipo_code,
cla14.cla14_classif_code,
cla14.cla14_classif_desc,
cla14.cla14_classif_tipo_code,
cla15.cla15_classif_code,
cla15.cla15_classif_desc,
cla15.cla15_classif_tipo_code,
t_annoCapitoloOrigine.annoCapitoloOrigine,
t_numeroCapitoloOrigine.numeroCapitoloOrigine,
t_annoOriginePlur.annoOriginePlur,
t_numeroArticoloOrigine.numeroArticoloOrigine,
t_annoRiaccertato.annoRiaccertato,
t_numeroRiaccertato.numeroRiaccertato,
t_numeroOriginePlur.numeroOriginePlur,
t_flagDaRiaccertamento.flagDaRiaccertamento,
-- 19.02.2020 Sofia jira siac-7292
t_flagDaReanno.flagDaReanno,
t_numeroUEBOrigine.numeroUEBOrigine,
t_cig.cig,
t_cup.cup,
t_NOTE_MOVGEST.NOTE_MOVGEST,
t_validato.validato,
t_annoFinanziamento.annoFinanziamento,
t_numeroAccFinanziamento.numeroAccFinanziamento,
t_flagCassaEconomale.flagCassaEconomale,
attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
impattuale.importo_attuale,
impiniziale.importo_iniziale,
imputilizzabile.importo_utilizzabile,
impliquidatoemessoquietanziato.importo_liquidato,
impliquidatoemessoquietanziato.importo_emesso,
impliquidatoemessoquietanziato,importo_quietanziato,
cofog.codice_cofog_gruppo,
cofog.descrizione_cofog_gruppo,
cofog.codice_cofog_divisione,
cofog.descrizione_cofog_divisione,
pdc5.pdc5_codice_pdc_finanziario_V,pdc5.pdc5_descrizione_pdc_finanziario_V,
pdc5.pdc5_codice_pdc_finanziario_IV,pdc5.pdc5_descrizione_pdc_finanziario_IV,
pdc5.pdc5_codice_pdc_finanziario_III,pdc5.pdc5_descrizione_pdc_finanziario_III,
pdc5.pdc5_codice_pdc_finanziario_II,pdc5.pdc5_descrizione_pdc_finanziario_II,
pdc5.pdc5_codice_pdc_finanziario_I,pdc5.pdc5_descrizione_pdc_finanziario_I,
pdc4.pdc4_codice_pdc_finanziario_IV,pdc4.pdc4_descrizione_pdc_finanziario_IV,
pdc4.pdc4_codice_pdc_finanziario_III,pdc4.pdc4_descrizione_pdc_finanziario_III,
pdc4.pdc4_codice_pdc_finanziario_II,pdc4.pdc4_descrizione_pdc_finanziario_II,
pdc4.pdc4_codice_pdc_finanziario_I,pdc4.pdc4_descrizione_pdc_finanziario_I,
pce5.pce5_codice_pdc_economico_V,pce5.pce5_descrizione_pdc_economico_V,
pce5.pce5_codice_pdc_economico_IV,pce5.pce5_descrizione_pdc_economico_IV,
pce5.pce5_codice_pdc_economico_III,pce5.pce5_descrizione_pdc_economico_III,
pce5.pce5_codice_pdc_economico_II,pce5.pce5_descrizione_pdc_economico_II,
pce5.pce5_codice_pdc_economico_I,pce5.pce5_descrizione_pdc_economico_I,
pce4.pce4_codice_pdc_economico_IV,pce4.pce4_descrizione_pdc_economico_IV,
pce4.pce4_codice_pdc_economico_III,pce4.pce4_descrizione_pdc_economico_III,
pce4.pce4_codice_pdc_economico_II,pce4.pce4_descrizione_pdc_economico_II,
pce4.pce4_codice_pdc_economico_I,pce4.pce4_descrizione_pdc_economico_I,
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,
t_flagPrenotazione.flagPrenotazione, t_flagPrenotazioneLiquidabile.flagPrenotazioneLiquidabile,
t_flagFrazionabile.flagFrazionabile,
imp.siope_tipo_debito_code, imp.siope_tipo_debito_desc, imp.siope_tipo_debito_desc_bnkit,
imp.siope_assenza_motivazione_code, imp.siope_assenza_motivazione_desc, imp.siope_assenza_motivazione_desc_bnkit,
coalesce(impFlagAttivaGsa.flag_attiva_gsa,'N') flag_attiva_gsa, -- 28.05.2018 Sofia siac-6102
-- SIAC-7541 23.04.2020 Sofia
struttura_comp.cod_cdr_struttura_comp,
struttura_comp.desc_cdr_struttura_comp,
struttura_comp.cod_cdc_struttura_comp,
struttura_comp.desc_cdc_struttura_comp,
-- SIAC-7899 26.11.2020 Sofia
cap.comp_tipo_id,
-- SIAC-7593 11.05.2020 Sofia
cap.comp_tipo_code,
cap.comp_tipo_desc,
cap.comp_tipo_macro_code,
cap.comp_tipo_macro_desc,
cap.comp_tipo_sotto_tipo_code,
cap.comp_tipo_sotto_tipo_desc,
cap.comp_tipo_ambito_code,
cap.comp_tipo_ambito_desc,
cap.comp_tipo_fonte_code,
cap.comp_tipo_fonte_desc,
cap.comp_tipo_fase_code ,
cap.comp_tipo_fase_desc,
cap.comp_tipo_def_code,
cap.comp_tipo_def_desc ,
cap.comp_tipo_gest_aut,
cap.comp_tipo_anno
-- SIAC-7593 11.05.2020 Sofia
from
imp left join cap
on
imp.movgest_id=cap.movgest_id
left join sogg
on
imp.movgest_ts_id=sogg.movgest_ts_id
left join sogcla
on
imp.movgest_ts_id=sogcla.movgest_ts_id
left join tipoimpegno
on
imp.movgest_ts_id=tipoimpegno.movgest_ts_id
left join ricorrentespesa
on
imp.movgest_ts_id=ricorrentespesa.movgest_ts_id
left join truespesa
on
imp.movgest_ts_id=truespesa.movgest_ts_id
left join persaspesa
on
imp.movgest_ts_id=persaspesa.movgest_ts_id
left join polregunitarie
on
imp.movgest_ts_id=polregunitarie.movgest_ts_id
left join cla11
on
imp.movgest_ts_id=cla11.movgest_ts_id
left join cla12
on
imp.movgest_ts_id=cla12.movgest_ts_id
left join cla13
on
imp.movgest_ts_id=cla13.movgest_ts_id
left join cla14
on
imp.movgest_ts_id=cla14.movgest_ts_id
left join cla15
on
imp.movgest_ts_id=cla15.movgest_ts_id
left join t_annoCapitoloOrigine
on
imp.movgest_ts_id=t_annoCapitoloOrigine.movgest_ts_id
left join t_numeroCapitoloOrigine
on
imp.movgest_ts_id=t_numeroCapitoloOrigine.movgest_ts_id
left join t_annoOriginePlur
on
imp.movgest_ts_id=t_annoOriginePlur.movgest_ts_id
left join t_numeroArticoloOrigine
on
imp.movgest_ts_id=t_numeroArticoloOrigine.movgest_ts_id
left join t_annoRiaccertato
on
imp.movgest_ts_id=t_annoRiaccertato.movgest_ts_id
left join t_numeroRiaccertato
on
imp.movgest_ts_id=t_numeroRiaccertato.movgest_ts_id
left join t_numeroOriginePlur
on
imp.movgest_ts_id=t_numeroOriginePlur.movgest_ts_id
left join t_flagDaRiaccertamento
on
imp.movgest_ts_id=t_flagDaRiaccertamento.movgest_ts_id
-- 19.02.2020 Sofia jira siac-7292
left join t_flagDaReanno
on
imp.movgest_ts_id=t_flagDaReanno.movgest_ts_id

left join t_numeroUEBOrigine
on
imp.movgest_ts_id=t_numeroUEBOrigine.movgest_ts_id
left join t_cig
on
imp.movgest_ts_id=t_cig.movgest_ts_id
left join t_cup
on
imp.movgest_ts_id=t_cup.movgest_ts_id
left join t_NOTE_MOVGEST
on
imp.movgest_ts_id=t_NOTE_MOVGEST.movgest_ts_id
left join t_validato
on
imp.movgest_ts_id=t_validato.movgest_ts_id
left join t_annoFinanziamento
on
imp.movgest_ts_id=t_annoFinanziamento.movgest_ts_id
left join t_numeroAccFinanziamento
on
imp.movgest_ts_id=t_numeroAccFinanziamento.movgest_ts_id
left join t_flagCassaEconomale
on
imp.movgest_ts_id=t_flagCassaEconomale.movgest_ts_id
left join attoamm
on
imp.movgest_ts_id=attoamm.movgest_ts_id
left join impattuale
on
imp.movgest_ts_id=impattuale.movgest_ts_id
left join impiniziale
on
imp.movgest_ts_id=impiniziale.movgest_ts_id
left join imputilizzabile
on
imp.movgest_ts_id=imputilizzabile.movgest_ts_id
left join impliquidatoemessoquietanziato
on
imp.movgest_ts_id=impliquidatoemessoquietanziato.movgest_ts_id
left join cofog
on
imp.movgest_ts_id=cofog.movgest_ts_id
left join pdc5
on
imp.movgest_ts_id=pdc5.movgest_ts_id
left join pdc4
on
imp.movgest_ts_id=pdc4.movgest_ts_id
left join pce5
on
imp.movgest_ts_id=pce5.movgest_ts_id
left join pce4
on
imp.movgest_ts_id=pce4.movgest_ts_id
left join t_flagPrenotazione
on
imp.movgest_ts_id=t_flagPrenotazione.movgest_ts_id
left join t_flagPrenotazioneLiquidabile
on
imp.movgest_ts_id=t_flagPrenotazioneLiquidabile.movgest_ts_id
left join t_flagFrazionabile
on
imp.movgest_ts_id=t_flagFrazionabile.movgest_ts_id
left join impFlagAttivaGsa  -- 28.05.2018 Sofia siac-6102
on
imp.movgest_ts_id=impFlagAttivaGsa.movgest_ts_id
-- SIAC-7541 23.04.2020 Sofia
left join struttura_comp
on
imp.movgest_id=struttura_comp.movgest_id
) xx
where xx.movgest_ts_tipo_code='S';

update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;

esito:='ok';

EXCEPTION
WHEN others THEN
  esito:='Funzione carico impegni (FNC_SIAC_DWH_IMPEGNO) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;


alter FUNCTION siac.fnc_siac_dwh_impegno (varchar,integer,timestamp) owner to siac;
-- 21.04.2021 Sofia SIAC-8127 riallineamento codice  - fine

-- SIAC-8151 - Maurizio - INIZIO
CREATE OR REPLACE FUNCTION siac.fnc_siac_capitoli_from_variazioni (
  p_uid_variazione integer
)
RETURNS TABLE (
  stato_variazione varchar,
  anno_capitolo varchar,
  numero_capitolo varchar,
  numero_articolo varchar,
  numero_ueb varchar,
  tipo_capitolo varchar,
  descrizione_capitolo varchar,
  descrizione_articolo varchar,
  missione varchar,
  programma varchar,
  titolo_uscita varchar,
  macroaggregato varchar,
  titolo_entrata varchar,
  tipologia varchar,
  categoria varchar,
  var_competenza numeric,
  var_residuo numeric,
  var_cassa numeric,
  var_competenza1 numeric,
  var_residuo1 numeric,
  var_cassa1 numeric,
  var_competenza2 numeric,
  var_residuo2 numeric,
  var_cassa2 numeric,
  cap_competenza numeric,
  cap_residuo numeric,
  cap_cassa numeric,
  cap_competenza1 numeric,
  cap_residuo1 numeric,
  cap_cassa1 numeric,
  cap_competenza2 numeric,
  cap_residuo2 numeric,
  cap_cassa2 numeric,
  tipologiafinanziamento varchar,
  sac varchar,
  variazione_num integer
) AS
$body$
DECLARE
	v_ente_proprietario_id INTEGER;
    v_bil_id INTEGER;
    v_anno VARCHAR;
    v_applicazione VARCHAR;
    tipo_cap_ent VARCHAR;
    tipo_cap_spe VARCHAR;
BEGIN

	-- Utilizzo l'ente per migliorare la performance delle CTE nella query successiva
   /* SELECT ente_proprietario_id
	INTO v_ente_proprietario_id
	FROM siac_t_variazione
	WHERE siac_t_variazione.variazione_id = p_uid_variazione;*/
    
    --SIAC-8151 19/04/2021.
    --Per ottimizzare le prestazioni della procedura leggo l'id del bilancio, l'anno e
    --l'applicazione (PREVISIONE/GESTIONE).
	SELECT v.ente_proprietario_id, v.bil_id, per.anno, var_appl.applicazione_code
	INTO v_ente_proprietario_id, v_bil_id, v_anno, v_applicazione
	FROM siac_t_variazione v, 
    	siac_t_bil bil, 
        siac_t_periodo per,
        siac_d_variazione_applicazione var_appl
	WHERE v.bil_id=bil.bil_id
    	and bil.periodo_id=per.periodo_id
        and v.applicazione_id=var_appl.applicazione_id
    	and v.variazione_id = p_uid_variazione
        and bil.data_cancellazione IS NULL;	    
	
    --SIAC-8151 19/04/2021.
    --Carico su 2 variabili le tipologie di capitolo che devo considerare.
    if v_applicazione = 'PREVISIONE' then  
    	tipo_cap_ent:='CAP-EP';
        tipo_cap_spe:='CAP-UP';
    else 
    	tipo_cap_ent:='CAP-EG';
        tipo_cap_spe:='CAP-UG';
    end if;
    
	RETURN QUERY
		-- CTE per uscita
		WITH missione AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc missione_tipo_desc,
				siac_t_class.classif_id missione_id,
				siac_t_class.classif_code missione_code,
				siac_t_class.classif_desc missione_desc,
				siac_t_class.validita_inizio missione_validita_inizio,
				siac_t_class.validita_fine missione_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR missione_code_desc
			FROM siac_t_class
			JOIN siac_d_class_tipo ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code = 'MISSIONE'
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		programma AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc programma_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre missione_id,
				siac_t_class.classif_id programma_id,
				siac_t_class.classif_code programma_code,
				siac_t_class.classif_desc programma_desc,
				siac_t_class.validita_inizio programma_validita_inizio,
				siac_t_class.validita_fine programma_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR programma_code_desc,
				siac_r_bil_elem_class.elem_id programma_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id       AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id       AND siac_r_bil_elem_class.data_cancellazione is null)
			WHERE siac_d_class_tipo.classif_tipo_code = 'PROGRAMMA'
			AND siac_t_class.data_cancellazione is null
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		titusc AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc titusc_tipo_desc,
				siac_t_class.classif_id titusc_id,
				siac_t_class.classif_code titusc_code,
				siac_t_class.classif_desc titusc_desc,
				siac_t_class.validita_inizio titusc_validita_inizio,
				siac_t_class.validita_fine titusc_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titusc_code_desc
			FROM siac_t_class
			JOIN siac_d_class_tipo ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code = 'TITOLO_SPESA'
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		macroag AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc macroag_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre titusc_id,
				siac_t_class.classif_id macroag_id,
				siac_t_class.classif_code macroag_code,
				siac_t_class.classif_desc macroag_desc,
				siac_t_class.validita_inizio macroag_validita_inizio,
				siac_t_class.validita_fine macroag_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR macroag_code_desc,
				siac_r_bil_elem_class.elem_id macroag_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id       AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id       AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code = 'MACROAGGREGATO'
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		-- CTE per entrata
		titent AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc titent_tipo_desc,
				siac_t_class.classif_id titent_id,
				siac_t_class.classif_code titent_code,
				siac_t_class.classif_desc titent_desc,
				siac_t_class.validita_inizio titent_validita_inizio,
				siac_t_class.validita_fine titent_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titent_code_desc
			FROM siac_t_class
			JOIN siac_d_class_tipo ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code = 'TITOLO_ENTRATA'
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		tipologia AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc tipologia_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre titent_id,
				siac_t_class.classif_id tipologia_id,
				siac_t_class.classif_code tipologia_code,
				siac_t_class.classif_desc tipologia_desc,
				siac_t_class.validita_inizio tipologia_validita_inizio,
				siac_t_class.validita_fine tipologia_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR tipologia_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id       AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code = 'TIPOLOGIA'
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		categoria AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc categoria_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre tipologia_id,
				siac_t_class.classif_id categoria_id,
				siac_t_class.classif_code categoria_code,
				siac_t_class.classif_desc categoria_desc,
				siac_t_class.validita_inizio categoria_validita_inizio,
				siac_t_class.validita_fine categoria_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR categoria_code_desc,
				siac_r_bil_elem_class.elem_id categoria_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id       AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id       AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code = 'CATEGORIA'
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		tipofinanziamento AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc tipofinanziamento_tipo_desc,
				siac_t_class.classif_id tipofinanziamento_id,
				siac_t_class.classif_code tipofinanziamento_code,
				siac_t_class.classif_desc tipofinanziamento_desc,
				siac_t_class.validita_inizio tipofinanziamento_validita_inizio,
				siac_t_class.validita_fine tipofinanziamento_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR tipofinanziamento_code_desc,
				siac_r_bil_elem_class.elem_id tipofinanziamento_elem_id
			FROM siac_t_class
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id  AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id        AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code = 'TIPO_FINANZIAMENTO'
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		sac AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc sar_tipo_desc,
				siac_t_class.classif_id sac_id,
				siac_t_class.classif_code sac_code,
				siac_t_class.classif_desc sac_desc,
				siac_t_class.validita_inizio sac_validita_inizio,
				siac_t_class.validita_fine sac_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR sac_code_desc,
				siac_r_bil_elem_class.elem_id sac_elem_id
			FROM siac_t_class
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id  AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id        AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code in ('CDC','CDR')
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		-- CTE importi variazione
		comp_variaz AS (
			SELECT
				siac_t_bil_elem_det_var.elem_id,
				siac_t_bil_elem_det_var.elem_det_var_id,
				siac_r_variazione_stato.variazione_stato_id,
				siac_t_bil_elem_det_var.elem_det_importo impSta,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil 
			JOIN siac_t_variazione        ON (siac_t_bil.bil_id = siac_t_variazione.bil_id    AND siac_t_variazione.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_t_bil_elem_det_var  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			-- SIAC-6883
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det_var.periodo_id = siac_t_periodo.periodo_id                            AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil.data_cancellazione IS NULL
			AND siac_t_variazione.variazione_id = p_uid_variazione
            
		),
		residuo_variaz AS (
			SELECT
				siac_t_bil_elem_det_var.elem_id,
				siac_t_bil_elem_det_var.elem_det_var_id,
				siac_r_variazione_stato.variazione_stato_id,
				siac_t_bil_elem_det_var.elem_det_importo impRes,
				siac_t_periodo.anno::integer
			FROM siac_t_bil 
			JOIN siac_t_variazione        ON (siac_t_bil.bil_id = siac_t_variazione.bil_id                                              AND siac_t_variazione.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_t_bil_elem_det_var  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione  IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			-- SIAC-6883
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det_var.periodo_id = siac_t_periodo.periodo_id                            AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil.data_cancellazione IS NULL
			AND siac_t_variazione.variazione_id = p_uid_variazione           
		),
		cassa_variaz AS (
			SELECT
				siac_t_bil_elem_det_var.elem_id,
				siac_t_bil_elem_det_var.elem_det_var_id,
				siac_r_variazione_stato.variazione_stato_id,
				siac_t_bil_elem_det_var.elem_det_importo impSca,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil 
			JOIN siac_t_variazione        ON (siac_t_bil.bil_id = siac_t_variazione.bil_id     AND siac_t_variazione.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_t_bil_elem_det_var  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			-- SIAC-6883
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det_var.periodo_id = siac_t_periodo.periodo_id                            AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA'
			AND siac_t_bil.data_cancellazione IS NULL
			AND siac_t_variazione.variazione_id = p_uid_variazione          
		),
		-- CTE importi capitolo
        
        --SIAC-8151 19/04/2021.
        --Per ottimizzare le prestazioni le query che estraggono gli importi dei capitoli
        --per competenza (comp_capitolo), residuo (residuo_capitolo) e cassa 
        --(cassa_capitolo) sono state triplicate mettendo il filtro sull'anno relativo
        --agli importi.
        --Inoltre è stato aggiunto il filtro sull'id del bilancio che mancava e
        --quello per estrarre solo le tipologie di capitolo coinvolte (PREVISONE o GESTIONE). 
		comp_capitolo AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impSta,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_tipo     ON (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id)
            WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
            --SIAC-8151 19/04/2021.
            --Aggiunti filtri per id bilancio, anno importo e tipologia capitolo.
            AND siac_t_bil_elem.bil_id = v_bil_id
            and siac_t_periodo.anno = v_anno
            and siac_d_bil_elem_tipo.elem_tipo_code in (tipo_cap_ent, tipo_cap_spe)
		),
         comp_capitolo1 AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impSta,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_tipo     ON (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id)
            WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
            AND siac_t_bil_elem.bil_id = v_bil_id
            and siac_t_periodo.anno::INTEGER = v_anno::INTEGER+1
            and siac_d_bil_elem_tipo.elem_tipo_code in (tipo_cap_ent, tipo_cap_spe)
		),
        comp_capitolo2 AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impSta,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_tipo     ON (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id)
            WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
            AND siac_t_bil_elem.bil_id = v_bil_id
            and siac_t_periodo.anno::INTEGER = v_anno::INTEGER+2
            and siac_d_bil_elem_tipo.elem_tipo_code in (tipo_cap_ent, tipo_cap_spe)
		),
		residuo_capitolo AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impRes,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_tipo     ON (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id)
            WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
             --SIAC-8151 19/04/2021.
            --Aggiunti filtri per id bilancio, anno importo e tipologia capitolo.
            AND siac_t_bil_elem.bil_id = v_bil_id
            and siac_t_periodo.anno = v_anno
            and siac_d_bil_elem_tipo.elem_tipo_code in (tipo_cap_ent, tipo_cap_spe)
		),
        residuo_capitolo1 AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impRes,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_tipo     ON (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id)
            WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
            AND siac_t_bil_elem.bil_id = v_bil_id
            and siac_t_periodo.anno::INTEGER = v_anno::INTEGER+1
            and siac_d_bil_elem_tipo.elem_tipo_code in (tipo_cap_ent, tipo_cap_spe)
		),
        residuo_capitolo2 AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impRes,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_tipo     ON (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id)
            WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
            AND siac_t_bil_elem.bil_id = v_bil_id
            and siac_t_periodo.anno::INTEGER = v_anno::INTEGER+2
            and siac_d_bil_elem_tipo.elem_tipo_code in (tipo_cap_ent, tipo_cap_spe)
		),
		cassa_capitolo AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impSca,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_tipo     ON (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id)
            WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
             --SIAC-8151 19/04/2021.
            --Aggiunti filtri per id bilancio, anno importo e tipologia capitolo.
            AND siac_t_bil_elem.bil_id = v_bil_id
            and siac_t_periodo.anno = v_anno
            and siac_d_bil_elem_tipo.elem_tipo_code in (tipo_cap_ent, tipo_cap_spe)
		),
        cassa_capitolo1 AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impSca,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_tipo     ON (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id)
            WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
            AND siac_t_bil_elem.bil_id = v_bil_id
            and siac_t_periodo.anno::INTEGER = v_anno::INTEGER+1
            and siac_d_bil_elem_tipo.elem_tipo_code in (tipo_cap_ent, tipo_cap_spe)
		),
        cassa_capitolo2 AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impSca,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_tipo     ON (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id)
            WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
            AND siac_t_bil_elem.bil_id = v_bil_id
            and siac_t_periodo.anno::INTEGER = v_anno::INTEGER+2
            and siac_d_bil_elem_tipo.elem_tipo_code in (tipo_cap_ent, tipo_cap_spe)
		)
		SELECT
			 siac_d_variazione_stato.variazione_stato_tipo_desc stato_variazione
			,siac_t_periodo.anno                               anno_capitolo
			,siac_t_bil_elem.elem_code                         numero_capitolo
			,siac_t_bil_elem.elem_code2                        numero_articolo
			,siac_t_bil_elem.elem_code3                        numero_ueb
			,siac_d_bil_elem_tipo.elem_tipo_code               tipo_capitolo
			,siac_t_bil_elem.elem_desc                         descrizione_capitolo
			,siac_t_bil_elem.elem_desc2                        descrizione_articolo
			-- Dati uscita
			,missione.missione_code_desc   missione
			,programma.programma_code_desc programma
			
			,titusc.titusc_code_desc       titolo_uscita
			,macroag.macroag_code_desc     macroaggregato
			-- Dati entrata
			,titent.titent_code_desc       titolo_entrata
			,tipologia.tipologia_code_desc tipologia
			,categoria.categoria_code_desc categoria
			-- Importi variazione
			,comp_variaz.impSta     var_competenza
			,residuo_variaz.impRes  var_residuo
			,cassa_variaz.impSca    var_cassa
			
			,comp_variaz1.impSta    var_competenza1
			,residuo_variaz1.impRes var_residuo1
			,cassa_variaz1.impSca   var_cassa1
			,comp_variaz2.impSta    var_competenza2
			,residuo_variaz2.impRes var_residuo2
			,cassa_variaz2.impSca   var_cassa2
			-- Importi capitolo
			,comp_capitolo.impSta     cap_competenza
			,residuo_capitolo.impRes  cap_residuo
			,cassa_capitolo.impSca    cap_cassa
			,comp_capitolo1.impSta    cap_competenza1
			
			,residuo_capitolo1.impRes cap_residuo1
			,cassa_capitolo1.impSca   cap_cassa1
			,comp_capitolo2.impSta    cap_competenza2
			,residuo_capitolo2.impRes cap_residuo2 
			,cassa_capitolo2.impSca   cap_cassa2
			,tipofinanziamento.tipofinanziamento_code_desc tipologiaFinanziamento
			,sac.sac_code_desc sac
			,siac_t_variazione.variazione_num

		FROM siac_t_variazione
		JOIN siac_r_variazione_stato           ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                             AND siac_r_variazione_stato.data_cancellazione IS NULL)
		JOIN siac_d_variazione_stato           ON (siac_r_variazione_stato.variazione_stato_tipo_id = siac_d_variazione_stato.variazione_stato_tipo_id AND siac_d_variazione_stato.data_cancellazione IS NULL)
		JOIN siac_t_bil_elem_det_var           ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id           AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
		JOIN siac_t_bil_elem                   ON (siac_t_bil_elem_det_var.elem_id = siac_t_bil_elem.elem_id                                           AND siac_t_bil_elem.data_cancellazione IS NULL)
		JOIN siac_t_bil                        ON (siac_t_bil_elem.bil_id = siac_t_bil.bil_id                                                          AND siac_t_bil.data_cancellazione IS NULL)
		JOIN siac_t_periodo                    ON (siac_t_bil.periodo_id = siac_t_periodo.periodo_id                                                   AND siac_t_periodo.data_cancellazione IS NULL)
		JOIN siac_d_bil_elem_tipo              ON (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id                                    AND siac_d_bil_elem_tipo.data_cancellazione IS NULL)
		JOIN siac_d_bil_elem_det_tipo          ON (siac_d_bil_elem_det_tipo.elem_det_tipo_id = siac_t_bil_elem_det_var.elem_det_tipo_id                AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
		
		--JOIN siac_t_bil     bil_variazione     ON (bil_variazione.bil_id = siac_t_variazione.bil_id                                                    AND bil_variazione.data_cancellazione IS NULL)
		--JOIN siac_t_periodo periodo_variazione ON (bil_variazione.periodo_id = periodo_variazione.periodo_id                                           AND periodo_variazione.data_cancellazione IS NULL)
		-- SIAC-6883
		--JOIN siac_t_periodo periodo_variazione ON (siac_t_variazione.periodo_id = periodo_variazione.periodo_id                                          AND periodo_variazione.data_cancellazione IS NULL)
		
		-- Importi variazione, anno 0
		JOIN comp_variaz    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz.variazione_stato_id    AND siac_t_bil_elem_det_var.elem_id = comp_variaz.elem_id    AND comp_variaz.anno = siac_t_periodo.anno::INTEGER)
		JOIN residuo_variaz ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz.elem_id AND residuo_variaz.anno = siac_t_periodo.anno::INTEGER)
		JOIN cassa_variaz   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz.elem_id   AND cassa_variaz.anno = siac_t_periodo.anno::INTEGER)
		-- Importi variazione, anno +1
		JOIN comp_variaz    comp_variaz1    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz1.variazione_stato_id    AND siac_t_bil_elem_det_var.elem_id = comp_variaz1.elem_id    AND comp_variaz1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN residuo_variaz residuo_variaz1 ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz1.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz1.elem_id AND residuo_variaz1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN cassa_variaz   cassa_variaz1   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz1.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz1.elem_id   AND cassa_variaz1.anno = siac_t_periodo.anno::INTEGER + 1)
		-- Importi variazione, anno +2
		JOIN comp_variaz    comp_variaz2    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz2.variazione_stato_id    AND siac_t_bil_elem_det_var.elem_id = comp_variaz2.elem_id    AND comp_variaz2.anno = siac_t_periodo.anno::INTEGER + 2)
		LEFT OUTER JOIN residuo_variaz residuo_variaz2 ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz2.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz2.elem_id AND residuo_variaz2.anno = siac_t_periodo.anno::INTEGER + 2)
		LEFT OUTER JOIN cassa_variaz   cassa_variaz2   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz2.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz2.elem_id   AND cassa_variaz2.anno = siac_t_periodo.anno::INTEGER + 2)
		-- Importi capitolo, anno 0
		JOIN comp_capitolo    ON (siac_t_bil_elem.elem_id = comp_capitolo.elem_id)--    AND comp_capitolo.anno = siac_t_periodo.anno::INTEGER)
		JOIN residuo_capitolo ON (siac_t_bil_elem.elem_id = residuo_capitolo.elem_id)-- AND residuo_capitolo.anno = siac_t_periodo.anno::INTEGER)
		JOIN cassa_capitolo   ON (siac_t_bil_elem.elem_id = cassa_capitolo.elem_id)--   AND cassa_capitolo.anno = siac_t_periodo.anno::INTEGER)
		-- Importi capitolo, anno +1
		--JOIN comp_capitolo    comp_capitolo1    ON (siac_t_bil_elem.elem_id = comp_capitolo1.elem_id    AND comp_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
        JOIN comp_capitolo1    ON (siac_t_bil_elem.elem_id = comp_capitolo1.elem_id)
		--JOIN residuo_capitolo residuo_capitolo1 ON (siac_t_bil_elem.elem_id = residuo_capitolo1.elem_id AND residuo_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
        JOIN residuo_capitolo1 ON (siac_t_bil_elem.elem_id = residuo_capitolo1.elem_id)-- AND residuo_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		--JOIN cassa_capitolo   cassa_capitolo1   ON (siac_t_bil_elem.elem_id = cassa_capitolo1.elem_id   AND cassa_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
        JOIN  cassa_capitolo1   ON (siac_t_bil_elem.elem_id = cassa_capitolo1.elem_id)--   AND cassa_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		-- Importi capitolo, anno +2
		--JOIN comp_capitolo    comp_capitolo2    ON (siac_t_bil_elem.elem_id = comp_capitolo2.elem_id    AND comp_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
        JOIN comp_capitolo2    ON (siac_t_bil_elem.elem_id = comp_capitolo2.elem_id)
		--JOIN residuo_capitolo residuo_capitolo2 ON (siac_t_bil_elem.elem_id = residuo_capitolo2.elem_id AND residuo_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
        JOIN  residuo_capitolo2 ON (siac_t_bil_elem.elem_id = residuo_capitolo2.elem_id)-- AND residuo_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		--JOIN cassa_capitolo   cassa_capitolo2   ON (siac_t_bil_elem.elem_id = cassa_capitolo2.elem_id   AND cassa_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
        JOIN  cassa_capitolo2   ON (siac_t_bil_elem.elem_id = cassa_capitolo2.elem_id)--   AND cassa_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		-- Classificatori
		LEFT OUTER JOIN macroag   ON (macroag.macroag_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN programma ON (programma.programma_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN missione  ON (missione.missione_id = programma.missione_id)
		LEFT OUTER JOIN titusc    ON (titusc.titusc_id = macroag.titusc_id)
		LEFT OUTER JOIN categoria ON (categoria.categoria_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN tipologia ON (tipologia.tipologia_id = categoria.tipologia_id)
		LEFT OUTER JOIN titent    ON (tipologia.titent_id = titent.titent_id)
		-- SIAC-6468
		LEFT OUTER JOIN tipofinanziamento ON (tipofinanziamento.tipofinanziamento_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN sac ON (sac.sac_elem_id = siac_t_bil_elem.elem_id)
		
		-- WHERE clause
		WHERE siac_t_variazione.variazione_id = p_uid_variazione
		AND siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
		AND siac_t_bil_elem_det_var.periodo_id = siac_t_periodo.periodo_id
		ORDER BY tipo_capitolo DESC, anno_capitolo, siac_t_bil_elem.elem_code::integer, siac_t_bil_elem.elem_code2::integer, siac_t_bil_elem.elem_code3::integer;
		
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-8151 - Maurizio - FINE



-- SIAC-8064 - Haitham - INIZIO
CREATE OR REPLACE FUNCTION siac.fnc_770_estrai_tracciato_quadro_c_f(p_anno_elab character varying, p_ente_proprietario_id integer, p_quadro_c_f character varying)
 RETURNS table (riga_tracciato text)
 LANGUAGE plpgsql
AS $function$
DECLARE

RTN_MESSAGGIO text;

BEGIN

	
IF p_quadro_c_f IS NULL THEN
    RTN_MESSAGGIO := 'Parametro Quadro C-F nullo.';
END IF;


IF upper(p_quadro_c_f) = 'C' THEN
 return query
 select a.tipo_record||a.codice_fiscale_ente||a.codice_fiscale_percipiente||a.tipo_percipiente||a.cognome_denominazione||a.nome||a.sesso||
        a.data_nascita||a.comune_nascita||a.provincia_nascita||a.sigla_stato_nascita||a.colonna_1||a.colonna_2||
        a.comune_domicilio_fiscale_prec||a.comune_domicilio_spedizione||a.provincia_domicilio_spedizione||a.colonna_3||
        a.esclusione_precompilata||a.categorie_particolari||a.indirizzo_domicilio_spedizione||a.cap_domicilio_spedizione||
        a.colonna_4||a.codice_sede||a.comune_domicilio_fiscale||a.rappresentante_codice_fiscale||a.percipienti_esteri_no_res||
        a.percipienti_esteri_localita||a.percipienti_esteri_stato||a.percipienti_esteri_cod_fiscale||a.ex_causale||
        a.ammontare_lordo_corrisposto||a.somme_no_ritenute_regime_conv||a.altre_somme_no_ritenute||
        a.imponibile_b||a.ritenute_titolo_acconto_b||a.ritenute_titolo_imposta_b||a.ritenute_sospese_b||
        a.anticipazione||a.anno||a.add_reg_titolo_acconto_b||a.add_reg_titolo_imposta_b||a.add_reg_sospesa_b||
        a.imponibile_anni_prec||a.ritenute_operate_anni_prec||a.contr_prev_carico_sog_erogante||a.contr_prev_carico_sog_percipie||
        a.spese_rimborsate||a.ritenute_rimborsate||a.colonna_5||a.percipienti_esteri_via_numciv||a.colonna_6||a.eventi_eccezionali||
        a.somme_prima_data_fallimento||a.somme_curatore_commissario||colonna_7||a.colonna_8||a.codice||a.colonna_9||a.codice_fiscale_e||
        a.imponibile_e||a.ritenute_titolo_acconto_e||ritenute_titolo_imposta_e||ritenute_sospese_e||add_reg_titolo_acconto_e||add_reg_titolo_imposta_e||
        a.add_reg_sospesa_e||a.add_com_titolo_acconto_e||a.add_com_titolo_imposta_e||a.add_com_sospesa_e||a.add_com_titolo_acconto_b||
        a.add_com_titolo_imposta_b||a.add_com_sospesa_b||a.colonna_10||a.codice_fiscale_redd_diversi_f||a.codice_fiscale_pignoramento_f||
        a.codice_fiscale_esproprio_f||a.colonna_11||a.colonna_12||a.colonna_13||a.colonna_14||a.colonna_15||a.colonna_16||a.colonna_17||
        a.colonna_18||a.colonna_19||a.colonna_20||a.colonna_21||a.colonna_22||a.colonna_23||a.codice_fiscale_ente_prev||a.denominazione_ente_prev ||
        a.codice_ente_prev||a.codice_azienda||a.categoria||a.altri_contributi||a.importo_altri_contributi||a.contributi_dovuti||a.contributi_versati||
        a.causale||a.somma_restituite||a.colonna_24||a.colonna_25||a.colonna_26||a.colonna_27||anno_competenza||a.ex_ente||a.progressivo||a.matricola||
        a.codice_tributo||a.versione_tracciato_procsi||a.colonna_28||a.caratteri_controllo_1 riga_tracciato
 from tracciato_770_quadro_c a
 where 0=0
 and   a.elab_id = (select max(elab_id)
                    from  tracciato_770_quadro_c b
                    where a.ente_proprietario_id = b.ente_proprietario_id
                    and   a.anno_competenza = b.anno_competenza
                   )
 and   a.ente_proprietario_id = p_ente_proprietario_id
 and   a.anno_competenza = p_anno_elab
 order by a.codice_fiscale_percipiente;

ELSIF upper(p_quadro_c_f) = 'F' THEN
 return query
 select a.tipo_record||a.codice_fiscale_ente||a.codice_fiscale_percipiente||a.tipo_percipiente||a.cognome_denominazione||a.nome||a.sesso||
        a.data_nascita||a.comune_nascita||a.provincia_nascita||a.comune_domicilio_fiscale||a.provincia_domicilio_fiscale||a.indirizzo_domicilio_fiscale||
        a.colonna_1||a.colonna_2||a.colonna_3||a.colonna_4||a.cap_domicilio_spedizione||a.colonna_5||a.codice_stato_estero||a.codice_identif_fiscale_estero||
        a.causale||a.ammontare_lordo_corrisposto||a.somme_no_soggette_ritenuta||a.aliquota||a.ritenute_operate||a.ritenute_sospese||a.codice_fiscale_rappr_soc||
        a.cognome_denom_rappr_soc||a.nome_rappr_soc||a.sesso_rappr_soc||a.data_nascita_rappr_soc||a.comune_nascita_rappr_soc||a.provincia_nascita_rappr_soc||
        a.comune_dom_fiscale_rappr_soc||a.provincia_rappr_soc||a.indirizzo_rappr_soc||a.codice_stato_estero_rappr_soc||a.rimborsi||a.colonna_6||a.colonna_7||
        a.colonna_8||a.colonna_9||a.colonna_10||a.colonna_11||a.colonna_12||a.colonna_13||a.colonna_14||a.colonna_15||a.colonna_16||a.colonna_17||a.colonna_18||
        a.colonna_19||a.colonna_20||a.colonna_21||a.colonna_22||a.colonna_23||a.anno_competenza||a.ex_ente||a.progressivo||a.matricola||a.codice_tributo||
        a.versione_tracciato_procsi||a.colonna_28||a.caratteri_controllo_1 riga_tracciato
 from  tracciato_770_quadro_f a
 where 0=0
 and   a.elab_id = (select max(elab_id)
                    from  tracciato_770_quadro_f b
                    where a.ente_proprietario_id = b.ente_proprietario_id
                    and   a.anno_competenza = b.anno_competenza
                   )
 and   a.ente_proprietario_id = p_ente_proprietario_id
 and   a.anno_competenza = p_anno_elab
 order by a.codice_fiscale_percipiente;
END IF;


exception
	when no_data_found THEN
		raise notice 'Nessun dato trovato';
		return;
	when others  THEN
		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
		return;


END;
$function$
;

-- SIAC-8064 - Haitham - FINE


-- SIAC-8129- Haitham - INIZIO
CREATE OR REPLACE VIEW siac.siac_v_dwh_variazione_bil_comp
AS SELECT tb.bil_anno,
    tb.numero_variazione,
    tb.desc_variazione,
    tb.cod_stato_variazione,
    tb.desc_stato_variazione,
    tb.cod_tipo_variazione,
    tb.desc_tipo_variazione,
    tb.anno_atto_amministrativo,
    tb.numero_atto_amministrativo,
    tb.cod_tipo_atto_amministrativo,
    tb.cod_capitolo,
    tb.cod_articolo,
    tb.cod_ueb,
    tb.cod_tipo_capitolo,
    tb.importo,
    tb.tipo_importo,
    tb.anno_variazione,
    tb.attoamm_id,
    tb.ente_proprietario_id,
    tb.cod_sac,
    tb.desc_sac,
    tb.tipo_sac,
    tb.data_definizione,
    tb.data_apertura_proposta,
    tb.data_chiusura_proposta,
    tb.cod_sac_proposta,
    tb.desc_sac_proposta,
    tb.tipo_sac_proposta,
    tb.elem_det_comp_tipo_code,
    tb.elem_det_comp_macro_tipo_code,
    tb.elem_det_comp_sotto_tipo_code,
    tb.elem_det_comp_tipo_ambito_code,
    tb.elem_det_comp_tipo_fonte_code,
    tb.elem_det_comp_tipo_fase_code,
    tb.elem_det_comp_tipo_def_code,
    tb.elem_det_comp_tipo_gest_aut,
    tb.componente,
    tb.importo_componente
   FROM ( WITH variaz AS (
                 SELECT p.anno AS bil_anno,
                    e.variazione_num AS numero_variazione,
                    e.variazione_desc AS desc_variazione,
                    d.variazione_stato_tipo_code AS cod_stato_variazione,
                    d.variazione_stato_tipo_desc AS desc_stato_variazione,
                    f.variazione_tipo_code AS cod_tipo_variazione,
                    f.variazione_tipo_desc AS desc_tipo_variazione,
                    a.elem_code AS cod_capitolo,
                    a.elem_code2 AS cod_articolo,
                    a.elem_code3 AS cod_ueb,
                    i.elem_tipo_code AS cod_tipo_capitolo,
                    b.elem_det_importo AS importo,
                    h.elem_det_tipo_desc AS tipo_importo,
                    l.anno AS anno_variazione,
                    c.attoamm_id,
                    a.ente_proprietario_id,
                        CASE
                            WHEN d.variazione_stato_tipo_code::text = 'D'::text THEN c.validita_inizio
                            ELSE NULL::timestamp without time zone
                        END AS data_definizione,
                    e.data_apertura_proposta,
                    e.data_chiusura_proposta,
                    e.classif_id,
                    b.elem_det_var_id AS importo_var_id
                   FROM siac_t_bil_elem a,
                    siac_t_bil_elem_det_var b,
                    siac_r_variazione_stato c,
                    siac_d_variazione_stato d,
                    siac_t_variazione e,
                    siac_d_variazione_tipo f,
                    siac_t_bil g,
                    siac_d_bil_elem_det_tipo h,
                    siac_d_bil_elem_tipo i,
                    siac_t_periodo l,
                    siac_t_periodo p
                  WHERE a.elem_id = b.elem_id AND c.variazione_stato_id = b.variazione_stato_id AND c.variazione_stato_tipo_id = d.variazione_stato_tipo_id AND c.variazione_id = e.variazione_id AND f.variazione_tipo_id = e.variazione_tipo_id AND b.data_cancellazione IS NULL AND a.data_cancellazione IS NULL AND c.data_cancellazione IS NULL AND g.bil_id = e.bil_id AND h.elem_det_tipo_id = b.elem_det_tipo_id AND i.elem_tipo_id = a.elem_tipo_id AND l.periodo_id = b.periodo_id AND p.periodo_id = g.periodo_id
                ), attoamm AS (
                 SELECT m.attoamm_id,
                    m.attoamm_anno AS anno_atto_amministrativo,
                    m.attoamm_numero AS numero_atto_amministrativo,
                    q.attoamm_tipo_code AS cod_tipo_atto_amministrativo
                   FROM siac_t_atto_amm m,
                    siac_d_atto_amm_tipo q
                  WHERE q.attoamm_tipo_id = m.attoamm_tipo_id AND m.data_cancellazione IS NULL AND q.data_cancellazione IS NULL
                ), sac AS (
                 SELECT i.attoamm_id,
                    l.classif_id,
                    l.classif_code,
                    l.classif_desc,
                    m.classif_tipo_code
                   FROM siac_r_atto_amm_class i,
                    siac_t_class l,
                    siac_d_class_tipo m,
                    siac_r_class_fam_tree n,
                    siac_t_class_fam_tree o,
                    siac_d_class_fam p
                  WHERE i.classif_id = l.classif_id AND m.classif_tipo_id = l.classif_tipo_id AND n.classif_id = l.classif_id AND n.classif_fam_tree_id = o.classif_fam_tree_id AND o.classif_fam_id = p.classif_fam_id AND p.classif_fam_code::text = '00005'::text AND i.data_cancellazione IS NULL AND l.data_cancellazione IS NULL AND n.data_cancellazione IS NULL
                ), str_proposta AS (
                 SELECT tipo.classif_tipo_code,
                    c.classif_code,
                    c.classif_desc,
                    c.classif_id
                   FROM siac_t_class c,
                    siac_d_class_tipo tipo
                  WHERE (tipo.classif_tipo_code::text = ANY (ARRAY['CDC'::character varying::text, 'CDR'::character varying::text])) AND c.classif_tipo_id = tipo.classif_tipo_id AND c.data_cancellazione IS NULL
                ), componente AS (
                 SELECT macro.elem_det_comp_macro_tipo_code,
                    macro.elem_det_comp_macro_tipo_desc,
                    sotto_tipo.elem_det_comp_sotto_tipo_code,
                    sotto_tipo.elem_det_comp_sotto_tipo_desc,
                    tipo.elem_det_comp_tipo_desc,
                    ambito_tipo.elem_det_comp_tipo_ambito_code,
                    ambito_tipo.elem_det_comp_tipo_ambito_desc,
                    fonte_tipo.elem_det_comp_tipo_fonte_code,
                    fonte_tipo.elem_det_comp_tipo_fonte_desc,
                    fase_tipo.elem_det_comp_tipo_fase_code,
                    fase_tipo.elem_det_comp_tipo_fase_desc,
                    def_tipo.elem_det_comp_tipo_def_code,
                    def_tipo.elem_det_comp_tipo_def_desc,
                        CASE
                            WHEN tipo.elem_det_comp_tipo_gest_aut = true THEN 'Solo automatica'::text
                            ELSE 'Manuale'::text
                        END::character varying(50) AS elem_det_comp_tipo_gest_aut,
                    imp_tipo.elem_det_comp_tipo_imp_code,
                    imp_tipo.elem_det_comp_tipo_imp_desc,
                    per.anno::integer AS elem_det_comp_tipo_anno,
                    tipo.elem_det_comp_tipo_id,
                    per.periodo_id AS elem_det_comp_periodo_id,
                    comp.elem_det_comp_id
                   FROM siac_d_bil_elem_det_comp_tipo_stato stato,
                    siac_d_bil_elem_det_comp_macro_tipo macro,
                    siac_d_bil_elem_det_comp_tipo tipo
                     LEFT JOIN siac_d_bil_elem_det_comp_sotto_tipo sotto_tipo ON tipo.elem_det_comp_sotto_tipo_id = sotto_tipo.elem_det_comp_sotto_tipo_id
                     LEFT JOIN siac_d_bil_elem_det_comp_tipo_ambito ambito_tipo ON tipo.elem_det_comp_tipo_ambito_id = ambito_tipo.elem_det_comp_tipo_ambito_id
                     LEFT JOIN siac_d_bil_elem_det_comp_tipo_fonte fonte_tipo ON tipo.elem_det_comp_tipo_fonte_id = fonte_tipo.elem_det_comp_tipo_fonte_id
                     LEFT JOIN siac_d_bil_elem_det_comp_tipo_fase fase_tipo ON tipo.elem_det_comp_tipo_fase_id = fase_tipo.elem_det_comp_tipo_fase_id
                     LEFT JOIN siac_d_bil_elem_det_comp_tipo_def def_tipo ON tipo.elem_det_comp_tipo_def_id = def_tipo.elem_det_comp_tipo_def_id
                     LEFT JOIN siac_d_bil_elem_det_comp_tipo_imp imp_tipo ON tipo.elem_det_comp_tipo_imp_id = imp_tipo.elem_det_comp_tipo_imp_id
                     LEFT JOIN siac_t_periodo per ON tipo.periodo_id = per.periodo_id
                     LEFT JOIN siac_t_bil_elem_det_comp comp ON tipo.elem_det_comp_tipo_id = comp.elem_det_comp_tipo_id
                  WHERE stato.elem_det_comp_tipo_stato_id = tipo.elem_det_comp_tipo_stato_id AND macro.elem_det_comp_macro_tipo_id = tipo.elem_det_comp_macro_tipo_id AND tipo.data_cancellazione IS NULL
                )
         SELECT variaz.bil_anno,
            variaz.numero_variazione,
            variaz.desc_variazione,
            variaz.cod_stato_variazione,
            variaz.desc_stato_variazione,
            variaz.cod_tipo_variazione,
            variaz.desc_tipo_variazione,
            attoamm.anno_atto_amministrativo,
            attoamm.numero_atto_amministrativo,
            attoamm.cod_tipo_atto_amministrativo,
            variaz.cod_capitolo,
            variaz.cod_articolo,
            variaz.cod_ueb,
            variaz.cod_tipo_capitolo,
            variaz.importo,
            variaz.tipo_importo,
            variaz.anno_variazione,
            variaz.attoamm_id,
            variaz.ente_proprietario_id,
            sac.classif_code AS cod_sac,
            sac.classif_desc AS desc_sac,
            sac.classif_tipo_code AS tipo_sac,
            variaz.data_definizione,
            variaz.data_apertura_proposta,
            variaz.data_chiusura_proposta,
            str_proposta.classif_code AS cod_sac_proposta,
            str_proposta.classif_desc AS desc_sac_proposta,
            str_proposta.classif_tipo_code AS tipo_sac_proposta,
            componente.elem_det_comp_tipo_id::character varying(200) AS elem_det_comp_tipo_code,
            componente.elem_det_comp_macro_tipo_code,
            componente.elem_det_comp_sotto_tipo_code,
            componente.elem_det_comp_tipo_ambito_code,
            componente.elem_det_comp_tipo_fonte_code,
            componente.elem_det_comp_tipo_fase_code,
            componente.elem_det_comp_tipo_def_code,
            componente.elem_det_comp_tipo_gest_aut,
            componente.elem_det_comp_tipo_desc AS componente,
            comp_var.elem_det_importo AS importo_componente
           FROM variaz
             LEFT JOIN attoamm ON variaz.attoamm_id = attoamm.attoamm_id
             LEFT JOIN sac ON variaz.attoamm_id = sac.attoamm_id
             LEFT JOIN str_proposta ON variaz.classif_id = str_proposta.classif_id
             LEFT JOIN siac_t_bil_elem_det_var_comp comp_var ON variaz.importo_var_id = comp_var.elem_det_var_id
             LEFT JOIN componente ON comp_var.elem_det_comp_id = componente.elem_det_comp_id) tb
  ORDER BY tb.ente_proprietario_id, tb.bil_anno, tb.numero_variazione, tb.cod_capitolo, tb.anno_variazione;

-- Permissions

ALTER TABLE siac.siac_v_dwh_variazione_bil_comp OWNER TO siac;

-- SIAC-8129 - Haitham - FINE

--- SIAC-8175 - Sofia inizio
drop FUNCTION if exists siac.fnc_fasi_bil_gest_reimputa_elabora 
(
  p_fasebilelabid integer,
  enteproprietarioid integer,
  annobilancio integer,
  impostaprovvedimento boolean,
  loginoperazione varchar,
  dataelaborazione timestamp,
  p_movgest_tipo_code varchar,
  motivo varchar,
  out outfasebilelabretid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_reimputa_elabora (
  p_fasebilelabid integer,
  enteproprietarioid integer,
  annobilancio integer,
  impostaprovvedimento boolean,
  loginoperazione varchar,
  dataelaborazione timestamp,
  p_movgest_tipo_code varchar,
  motivo varchar,
  out outfasebilelabretid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
  DECLARE
    strmessaggiotemp   				VARCHAR(1000):='';
    tipomovgestid      				INTEGER:=NULL;
    movgesttstipoid    				INTEGER:=NULL;
    tipomovgesttssid   				INTEGER:=NULL;
    tipomovgesttstid   				INTEGER:=NULL;
    tipocapitologestid 				INTEGER:=NULL;
    bilancioid         				INTEGER:=NULL;
    bilancioprecid     				INTEGER:=NULL;
    periodoid          				INTEGER:=NULL;
    periodoprecid      				INTEGER:=NULL;
    datainizioval      				timestamp:=NULL;
    movgestidret      				INTEGER:=NULL;
    movgesttsidret    				INTEGER:=NULL;
    v_elemid          				INTEGER:=NULL;
    movgesttstipotid  				INTEGER:=NULL;
    movgesttstiposid  				INTEGER:=NULL;
    movgesttstipocode 				VARCHAR(10):=NULL;
    movgeststatoaid   				INTEGER:=NULL;
    v_importomodifica 				NUMERIC;
    movgestrec 						RECORD;
    aggprogressivi 					RECORD;
    cleanrec						RECORD;
    v_movgest_numero                INTEGER;
    v_prog_id                       INTEGER;
    v_flagdariaccertamento_attr_id  INTEGER;
    v_annoriaccertato_attr_id       INTEGER;
    v_numeroriaccertato_attr_id     INTEGER;
    v_numero_el                     integer;
    -- tipo periodo annuale
    sy_per_tipo CONSTANT VARCHAR:='SY';
    -- tipo anno ordinario annuale
    bil_ord_tipo        CONSTANT VARCHAR:='BIL_ORD';
    imp_movgest_tipo    CONSTANT VARCHAR:='I';
    acc_movgest_tipo    CONSTANT VARCHAR:='A';
    sim_movgest_ts_tipo CONSTANT VARCHAR:='SIM';
    sac_movgest_ts_tipo CONSTANT VARCHAR:='SAC';
    a_mov_gest_stato    CONSTANT VARCHAR:='A';
    strmessaggio        VARCHAR(1500):='';
    strmessaggiofinale  VARCHAR(1500):='';
    codresult           INTEGER;
    v_bil_attr_id       INTEGER;
    v_attr_code         VARCHAR;
    movgest_ts_t_tipo   CONSTANT VARCHAR:='T';
    movgest_ts_s_tipo   CONSTANT VARCHAR:='S';
    cap_ug_tipo         CONSTANT VARCHAR:='CAP-UG';
    cap_eg_tipo         CONSTANT VARCHAR:='CAP-EG';
    ape_gest_reimp      CONSTANT VARCHAR:='APE_GEST_REIMP';
    faserec RECORD;
    faseelabrec RECORD;
    recmovgest RECORD;
    v_maxcodgest      INTEGER;
    v_movgest_ts_id   INTEGER;
    v_ambito_id       INTEGER;
    v_inizio          VARCHAR;
    v_fine            VARCHAR;
    v_bil_tipo_id     INTEGER;
    v_periodo_id      INTEGER;
    v_periodo_tipo_id INTEGER;
    v_tmp             VARCHAR;


    -- 15.02.2017 Sofia SIAC-4425
	FRAZIONABILE_ATTR CONSTANT varchar:='flagFrazionabile';
    flagFrazAttrId integer:=null;
-- SIAC-6997 ---------------- INIZIO --------------------
	DAREANNO_ATTR CONSTANT varchar:='flagDaReanno';
    v_flagdareanno_attr_id  integer:=null;
-- SIAC-6997 ---------------- FINE --------------------
	-- 07.03.2017 Sofia SIAC-4568
    dataEmissione     timestamp:=null;

	-- 07.02.2018 Sofia siac-5368
    movGestStatoId INTEGER:=null;
    movGestStatoPId INTEGER:=null;
	MOVGEST_STATO_CODE_P CONSTANT VARCHAR:='P';

  BEGIN
    codicerisultato:=NULL;
    messaggiorisultato:=NULL;
    strmessaggiofinale:='Inizio.';
    datainizioval:= clock_timestamp();
    -- 07.03.2017 Sofia SIAC-4568
    dataEmissione:=(annoBilancio::varchar||'-01-01')::timestamp;

    SELECT attr.attr_id
    INTO   v_flagdariaccertamento_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code ='flagDaRiaccertamento'
    AND    attr.ente_proprietario_id = enteproprietarioid;

-- SIAC-6997 ---------------- INIZIO --------------------

    SELECT attr.attr_id
    INTO   v_flagdareanno_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code = DAREANNO_ATTR
    AND    attr.ente_proprietario_id = enteproprietarioid;

-- SIAC-6997 ---------------- FINE --------------------

    SELECT attr.attr_id
    INTO   v_annoriaccertato_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code ='annoRiaccertato'
    AND    attr.ente_proprietario_id = enteproprietarioid;

    SELECT attr.attr_id
    INTO   v_numeroriaccertato_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code ='numeroRiaccertato'
    AND    attr.ente_proprietario_id = enteproprietarioid;

    -- estraggo il bilancio nuovo
    SELECT bil_id
    INTO   strict bilancioid
    FROM   siac_t_bil
    WHERE  bil_code = 'BIL_'
                  ||annobilancio::VARCHAR
    AND    ente_proprietario_id = enteproprietarioid;

	-- 07.02.2018 Sofia siac-5368
    strMessaggio:='Lettura identificativo per stato='||MOVGEST_STATO_CODE_P||'.';
	select stato.movgest_stato_id
    into   strict movGestStatoPId
    from siac_d_movgest_stato stato
    where stato.ente_proprietario_id=enteproprietarioid
    and   stato.movgest_stato_code=MOVGEST_STATO_CODE_P;

    -- 15.02.2017 Sofia Sofia SIAC-4425
	if p_movgest_tipo_code=imp_movgest_tipo then
    	strMessaggio:='Lettura identificativo per flagFrazAttrCode='||FRAZIONABILE_ATTR||'.';
     	select attr.attr_id into strict flagFrazAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FRAZIONABILE_ATTR
        and   attr.data_cancellazione is null
        and   attr.validita_fine is null;

        strMessaggio:='Lettura identificativo per movGestTipoCode='||imp_movgest_tipo||'.';
        select tipo.movgest_tipo_id into strict tipoMovGestId
        from siac_d_movgest_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.movgest_tipo_code=imp_movgest_tipo
        and   tipo.data_cancellazione is null
        and   tipo.validita_fine is null;

        strMessaggio:='Lettura identificativo per movGestTsTTipoCode='||movgest_ts_t_tipo||'.';
        select tipo.movgest_ts_tipo_id into strict tipoMovGestTsTId
        from siac_d_movgest_ts_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.movgest_ts_tipo_code=movgest_ts_t_tipo
        and   tipo.data_cancellazione is null
        and   tipo.validita_fine is null;

    end if;


    FOR movgestrec IN
    (
           SELECT reimputazione_id ,
                  bil_id ,
                  elemid_old ,
                  elem_code ,
                  elem_code2 ,
                  elem_code3 ,
                  elem_tipo_code ,
                  movgest_id ,
                  movgest_anno ,
                  movgest_numero ,
                  movgest_desc ,
                  movgest_tipo_id ,
                  parere_finanziario ,
                  parere_finanziario_data_modifica ,
                  parere_finanziario_login_operazione ,
                  movgest_ts_id ,
                  movgest_ts_code ,
                  movgest_ts_desc ,
                  movgest_ts_tipo_id ,
                  movgest_ts_id_padre ,
                  ordine ,
                  livello ,
                  movgest_ts_scadenza_data ,
                  movgest_ts_det_tipo_id ,
                  impoinizimpegno ,
                  impoattimpegno ,
                  importomodifica ,
                  tipo ,
                  movgest_ts_det_tipo_code ,
                  movgest_ts_det_importo ,
                  mtdm_reimputazione_anno ,
                  mtdm_reimputazione_flag ,
                  mod_tipo_code ,
                  attoamm_id,       -- 07.02.2018 Sofia siac-5368
                  movgest_stato_id, -- 07.02.2018 Sofia siac-5368
                  importo_reimputato, -- 05.06.2020 Sofia SIAC-7593
                  importo_modifica_entrata, -- 05.06.2020 Sofia SIAC-7593
                  coll_mod_entrata,  -- 05.06.2020 Sofia SIAC-7593
                  elem_det_comp_tipo_id, -- 05.06.2020 Sofia SIAC-7593
                  login_operazione ,
                  ente_proprietario_id,
                  siope_tipo_debito_id,
		          siope_assenza_motivazione_id
           FROM   fase_bil_t_reimputazione
           WHERE  ente_proprietario_id = enteproprietarioid
           AND    fasebilelabid = p_fasebilelabid
           AND    fl_elab = 'N'
           order by  1) -- 19.04.2019 Sofia JIRA SIAC-6788
    LOOP
      movgesttsidret:=NULL;
      movgestidret:=NULL;
      codresult:=NULL;
      v_elemid:=NULL;
      v_inizio := movgestrec.mtdm_reimputazione_anno::VARCHAR ||'-01-01';
      v_fine := movgestrec.mtdm_reimputazione_anno::VARCHAR ||'-12-31';

	  --caso in cui si tratta di impegno/ accertamento creo la struttua a partire da movgest
      --tipots.movgest_ts_tipo_code tipo

      IF movgestrec.tipo !='S' THEN

        v_movgest_ts_id = NULL;
        --v_maxcodgest= movgestrec.movgest_ts_code::INTEGER;

        IF p_movgest_tipo_code = 'I' THEN
          strmessaggio:='progressivo per Impegno ' ||'imp_'||movgestrec.mtdm_reimputazione_anno::VARCHAR ||'.';
          SELECT prog_value + 1 ,
                 prog_id
          INTO   strict v_movgest_numero ,
                 v_prog_id
          FROM   siac_t_progressivo ,
                 siac_d_ambito
          WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
          AND    siac_t_progressivo.ente_proprietario_id = enteproprietarioid
          AND    siac_t_progressivo.prog_key = 'imp_'||movgestrec.mtdm_reimputazione_anno::VARCHAR
          AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          IF v_movgest_numero IS NULL THEN
            strmessaggio:='aggiungo progressivo per anno ' ||'imp_' ||movgestrec.mtdm_reimputazione_anno::VARCHAR ||'.';
            SELECT ambito_id
            INTO   strict v_ambito_id
            FROM   siac_d_ambito
            WHERE  ambito_code = 'AMBITO_FIN'
            AND    ente_proprietario_id = enteproprietarioid
            AND    data_cancellazione IS NULL;

            INSERT INTO siac_t_progressivo
            (
                        prog_value,
                        prog_key ,
                        ambito_id ,
                        validita_inizio ,
                        validita_fine ,
                        ente_proprietario_id ,
                        data_cancellazione ,
                        login_operazione
            )
            VALUES
            (
                        0,
                        'imp_'||movgestrec.mtdm_reimputazione_anno::VARCHAR,
                        v_ambito_id ,
                        v_inizio::timestamp,
                        v_fine::timestamp,
                        enteproprietarioid ,
                        NULL,
                        loginoperazione
            )
            returning   prog_id  INTO        v_prog_id ;

            SELECT prog_value + 1 ,
                   prog_id
            INTO   v_movgest_numero ,
                   v_prog_id
            FROM   siac_t_progressivo ,
                   siac_d_ambito
            WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
            AND    siac_t_progressivo.ente_proprietario_id = enteproprietarioid
            AND    siac_t_progressivo.prog_key = 'imp_'||movgestrec.mtdm_reimputazione_anno::VARCHAR
            AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          END IF;

        ELSE --IF p_movgest_tipo_code = 'I'

          --Accertamento
          SELECT prog_value + 1,
                 prog_id
          INTO   v_movgest_numero,
                 v_prog_id
          FROM   siac_t_progressivo ,
                 siac_d_ambito
          WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
          AND    siac_t_progressivo.ente_proprietario_id = enteproprietarioid
          AND    siac_t_progressivo.prog_key = 'acc_'||movgestrec.mtdm_reimputazione_anno::VARCHAR
          AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          IF v_movgest_numero IS NULL THEN

            strmessaggio:='aggiungo progressivo per anno ' ||'acc_' ||movgestrec.mtdm_reimputazione_anno::VARCHAR ||'.';
            SELECT ambito_id
            INTO   v_ambito_id
            FROM   siac_d_ambito
            WHERE  ambito_code = 'AMBITO_FIN'
            AND    ente_proprietario_id = enteproprietarioid
            AND    data_cancellazione IS NULL;

            v_inizio := movgestrec.mtdm_reimputazione_anno::VARCHAR||'-01-01'; v_fine := movgestrec.mtdm_reimputazione_anno::VARCHAR||'-12-31';
            INSERT INTO siac_t_progressivo
			(
				prog_value ,
				prog_key ,
				ambito_id ,
				validita_inizio ,
				validita_fine ,
				ente_proprietario_id ,
				data_cancellazione ,
				login_operazione
			)
			VALUES
			(
				0,
				'acc_'||movgestrec.mtdm_reimputazione_anno::VARCHAR,
				v_ambito_id ,
				v_inizio::timestamp,
				v_fine::timestamp,
				enteproprietarioid ,
				NULL,
				loginoperazione
			)
            returning   prog_id INTO        v_prog_id ;

            SELECT prog_value + 1 ,
                   prog_id
            INTO   strict v_movgest_numero ,
                   v_prog_id
            FROM   siac_t_progressivo ,
                   siac_d_ambito
            WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
            AND    siac_t_progressivo.ente_proprietario_id = enteproprietarioid
            AND    siac_t_progressivo.prog_key = 'acc_'||movgestrec.mtdm_reimputazione_anno::VARCHAR
            AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          END IF; --fine if v_movgest_numero

        END IF;

        strmessaggio:='inserisco il siac_t_movgest.';
        INSERT INTO siac_t_movgest
        (
			movgest_anno,
			movgest_numero,
			movgest_desc,
			movgest_tipo_id,
			bil_id,
			validita_inizio,
			ente_proprietario_id,
			login_operazione,
			parere_finanziario,
			parere_finanziario_data_modifica,
			parere_finanziario_login_operazione
        )
        VALUES
        (
			movgestrec.mtdm_reimputazione_anno,
            v_movgest_numero,
			movgestrec.movgest_desc,
			movgestrec.movgest_tipo_id,
			bilancioid,
			datainizioval,
			enteproprietarioid,
			loginoperazione,
			movgestrec.parere_finanziario,
			movgestrec.parere_finanziario_data_modifica,
			movgestrec.parere_finanziario_login_operazione
        )
        returning   movgest_id INTO        movgestidret;

        IF movgestidret IS NULL THEN
          strmessaggiotemp:=strmessaggio;
          codresult:=-1;
        END IF;

        RAISE notice 'dopo inserimento siac_t_movgest movGestIdRet=%',movgestidret;

        strmessaggio:='aggiornamento progressivo v_prog_id ' ||v_prog_id::VARCHAR;
        UPDATE siac_t_progressivo
        SET    prog_value = prog_value + 1
        WHERE  prog_id = v_prog_id;

        strmessaggio:='estraggo il capitolo =elem_code ' || movgestrec.elem_code ||' elem_code2 ' || movgestrec.elem_code2 ||' elem_code3' || movgestrec.elem_code3 ||' elem_tipo_code =' || movgestrec.elem_tipo_code ||' bilancioId='||bilancioid::VARCHAR ||'.';
        --raise notice 'strMessaggio=%',strMessaggio;
        SELECT be.elem_id
        INTO   v_elemid
        FROM   siac_t_bil_elem be,
               siac_r_bil_elem_stato rbes,
               siac_d_bil_elem_stato bbes,
               siac_d_bil_elem_tipo bet
        WHERE  be.elem_tipo_id = bet.elem_tipo_id
        AND    be.elem_code=movgestrec.elem_code
        AND    be.elem_code2=movgestrec.elem_code2
        AND    be.elem_code3=movgestrec.elem_code3
        AND    bet.elem_tipo_code = movgestrec.elem_tipo_code
        AND    be.elem_id = rbes.elem_id
        AND    rbes.elem_stato_id = bbes.elem_stato_id
        AND    bbes.elem_stato_code !='AN'
        AND    rbes.data_cancellazione IS NULL
        AND    be.bil_id = bilancioid
        AND    be.ente_proprietario_id = enteproprietarioid
        AND    be.data_cancellazione IS NULL
        AND    be.validita_fine IS NULL;

        IF v_elemid IS NULL THEN
          codresult:=-1;
          strmessaggio:= ' impegno/accertamento privo di capitolo nel nuovo bilancio elem_code ' || movgestrec.elem_code ||' elem_code2 ' || movgestrec.elem_code2 ||' elem_code3' || movgestrec.elem_code3 ||' elem_tipo_code =' || movgestrec.elem_tipo_code ||' bilancioId='||bilancioid::VARCHAR ||'.';

          update fase_bil_t_reimputazione
          set fl_elab='X'
            ,movgestnew_ts_id = movgesttsidret
            ,movgestnew_id    = movgestidret
            ,data_modifica = clock_timestamp()
            ,scarto_code='IMAC1'
            ,scarto_desc=' impegno/accertamento privo di capitolo nel nuovo bilancio elem_code ' || movgestrec.elem_code ||' elem_code2 ' || movgestrec.elem_code2 ||' elem_code3' || movgestrec.elem_code3 ||' elem_tipo_code =' || movgestrec.elem_tipo_code ||' bilancioId='||bilancioid::VARCHAR ||'.'
      	  where
      	  	fase_bil_t_reimputazione.reimputazione_id = movgestrec.reimputazione_id;
          continue;
        END IF;


        -- relazione tra capitolo e movimento
        strmessaggio:='Inserimento relazione movimento capitolo anno='||movgestrec.movgest_anno ||' numero=' ||movgestrec.movgest_numero || ' v_elemId='||v_elemid::varchar ||' [siac_r_movgest_bil_elem]';

        INSERT INTO siac_r_movgest_bil_elem
        (
          movgest_id,
          elem_id,
          elem_det_comp_tipo_id, -- 05.06.2020 Sofia SIAC-7593
          validita_inizio,
          ente_proprietario_id,
          login_operazione
        )
        VALUES
        (
          movgestidret,
          v_elemid,--movGestRec.elemId_old,
          -- 05.06.2020 Sofia SIAC-7593
          (case when p_movgest_tipo_code='I' then movgestrec.elem_det_comp_tipo_id else null end ),
          datainizioval,
          enteproprietarioid,
          loginoperazione
        )
        returning   movgest_atto_amm_id  INTO        codresult;

        IF codresult IS NULL THEN
          codresult:=-1;
          strmessaggiotemp:=strmessaggio;
        ELSE
          codresult:=NULL;
        END IF;
        strmessaggio:='Inserimento movimento movGestTipo=' ||movgestrec.tipo || ' anno=' ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero|| ' sub=' ||movgestrec.movgest_ts_code || ' [siac_t_movgest_ts].';
        RAISE notice 'strMessaggio=% ',strmessaggio;

        v_maxcodgest := v_movgest_numero;



      ELSE --caso in cui si tratta di subimpegno/ subaccertamento estraggo il movgest_id padre e movgest_ts_id_padre IF movgestrec.tipo =='S'

        -- todo calcolare il papa' sel subimpegno movgest_id  del padre  ed anche movgest_ts_id_padre
        strmessaggio:='caso SUB movGestTipo=' ||movgestrec.tipo ||'.';

        SELECT count(*)
        INTO v_numero_el
        FROM   fase_bil_t_reimputazione
        WHERE  fase_bil_t_reimputazione.movgest_anno = movgestrec.movgest_anno
        AND    fase_bil_t_reimputazione.movgest_numero = movgestrec.movgest_numero
        AND    fase_bil_t_reimputazione.fasebilelabid = p_fasebilelabid
--        and   fase_bil_t_reimputazione.fasebilelabid=370 -- Sofia 27.04.2021 Jira SIAC-8175 per elaborare solo sub impostare elabId dei movimenti padre
--        and   fase_bil_t_reimputazione.fasebilelabid=369 -- Sofia 27.04.2021 Jira SIAC-8175 per elaborare solo sub impostare elabId dei movimenti padre
        AND    fase_bil_t_reimputazione.mod_tipo_code =  movgestrec.mod_tipo_code
        AND    fase_bil_t_reimputazione.tipo = 'T'
        and    fase_bil_t_reimputazione.mtdm_reimputazione_anno=movgestrec.mtdm_reimputazione_anno -- 28.02.2018 Sofia jira siac-5964
       and    (case when p_movgest_tipo_code='I'  -- 08.06.2020 Sofia Jira siac-7593
---                  then fase_bil_t_reimputazione.elem_det_comp_tipo_id= movgestrec.elem_det_comp_tipo_id - Sofia 27.04.2021 Jira SIAC-8175
	 				 --- Sofia 27.04.2021  modifica per sbloccare sub	SIAC-8175
	                 then fase_bil_t_reimputazione.elem_det_comp_tipo_id = fase_bil_t_reimputazione.elem_det_comp_tipo_id  
                     else p_movgest_tipo_code='A' end);

 --       raise notice 'strMessaggio anno=% numero=% v_numero_el=%', movgestrec.movgest_anno, movgestrec.movgest_numero,v_numero_el;

        SELECT fase_bil_t_reimputazione.movgestnew_id ,
               fase_bil_t_reimputazione.movgestnew_ts_id
        INTO strict  movgestidret ,
               v_movgest_ts_id
        FROM   fase_bil_t_reimputazione
        WHERE  fase_bil_t_reimputazione.movgest_anno = movgestrec.movgest_anno
        AND    fase_bil_t_reimputazione.movgest_numero = movgestrec.movgest_numero
        AND    fase_bil_t_reimputazione.fasebilelabid = p_fasebilelabid
--        and    fase_bil_t_reimputazione.fasebilelabid=370 -- Sofia 27.04.2021 Jira SIAC-8175 per elaborare solo sub impostare elabId dei movimenti padre
--        and    fase_bil_t_reimputazione.fasebilelabid=369 -- Sofia 27.04.2021 Jira SIAC-8175 per elaborare solo sub impostare elabId dei movimenti padre

        AND    fase_bil_t_reimputazione.mod_tipo_code =  movgestrec.mod_tipo_code
        AND    fase_bil_t_reimputazione.tipo = 'T'
        and    fase_bil_t_reimputazione.mtdm_reimputazione_anno=movgestrec.mtdm_reimputazione_anno -- 28.02.2018 Sofia jira siac-5964
	    and    (case when p_movgest_tipo_code='I'  -- 08.06.2020 Sofia Jira siac-7593
--                      then fase_bil_t_reimputazione.elem_det_comp_tipo_id= movgestrec.elem_det_comp_tipo_id - Sofia 27.04.2021 Jira SIAC-8175
				     --- Sofia 27.04.2021 modifica per sbloccare sub Jira SIAC-8175
                     then fase_bil_t_reimputazione.elem_det_comp_tipo_id = fase_bil_t_reimputazione.elem_det_comp_tipo_id  
                     else p_movgest_tipo_code='A' end)
        order by fase_bil_t_reimputazione.fasebilelabid  -- Sofia 27.04.2021 modifica per sbloccare sub
        limit 1;   -- Sofia 27.04.2021 modifica per sbloccare sub Jira SIAC-8175

   --  raise notice 'strMessaggio anno=% numero=% movgestidret=%', movgestrec.movgest_anno, movgestrec.movgest_numero,movgestidret;
        if movgestidret is null then
          update fase_bil_t_reimputazione
          set fl_elab        ='X'
            ,scarto_code      ='IMACNP'
            ,scarto_desc      =' subimpegno/subaccertamento privo di testata modificata movGestTipo=' ||movgestrec.tipo || ' anno=' ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero|| ' v_numero_el = ' ||v_numero_el::varchar||'.'
      	    ,movgestnew_ts_id = movgesttsidret
            ,movgestnew_id    = movgestidret
            ,data_modifica = clock_timestamp()
          from
          	siac_t_bil_elem elem
      	  where
      	  	fase_bil_t_reimputazione.reimputazione_id = movgestrec.reimputazione_id;
        	continue;
        end if;


        strmessaggio:=' estraggo movGest padre movGestRec.movgest_id='||movgestrec.movgest_id::VARCHAR ||' p_fasebilelabid'||p_fasebilelabid::VARCHAR ||'' ||'.';
        --strMessaggio:='calcolo il max siac_t_movgest_ts.movgest_ts_code  movGestIdRet='||movGestIdRet::varchar ||'.';

        SELECT max(siac_t_movgest_ts.movgest_ts_code::INTEGER)
        INTO   v_maxcodgest
        FROM   siac_t_movgest ,
               siac_t_movgest_ts ,
               siac_d_movgest_tipo,
               siac_d_movgest_ts_tipo
        WHERE  siac_t_movgest.movgest_id = siac_t_movgest_ts.movgest_id
        AND    siac_t_movgest.movgest_tipo_id = siac_d_movgest_tipo.movgest_tipo_id
        AND    siac_d_movgest_tipo.movgest_tipo_code = p_movgest_tipo_code
        AND    siac_t_movgest_ts.movgest_ts_tipo_id = siac_d_movgest_ts_tipo.movgest_ts_tipo_id
        AND    siac_d_movgest_ts_tipo.movgest_ts_tipo_code = 'S'
        AND    siac_t_movgest.bil_id = bilancioid
        AND    siac_t_movgest.ente_proprietario_id = enteproprietarioid
        AND    siac_t_movgest.movgest_id = movgestidret;

        IF v_maxcodgest IS NULL THEN
          v_maxcodgest:=0;
        END IF;
        v_maxcodgest := v_maxcodgest+1;

     END IF; -- fine cond se sub o non sub





      -- caso di sub



      INSERT INTO siac_t_movgest_ts
      (
        movgest_ts_code,
        movgest_ts_desc,
        movgest_id,
        movgest_ts_tipo_id,
        movgest_ts_id_padre,
        movgest_ts_scadenza_data,
        ordine,
        livello,
        validita_inizio,
        ente_proprietario_id,
        login_operazione,
        login_creazione,
		siope_tipo_debito_id,
		siope_assenza_motivazione_id
      )
      VALUES
      (
        v_maxcodgest::VARCHAR, --movGestRec.movgest_ts_code,
        movgestrec.movgest_ts_desc,
        movgestidret, -- inserito se I/A, per SUB ricavato
        movgestrec.movgest_ts_tipo_id,
        v_movgest_ts_id, -- ????? valorizzato se SUB come quello da cui deriva diversamente null
        movgestrec.movgest_ts_scadenza_data,
        movgestrec.ordine,
        movgestrec.livello,
--        dataelaborazione, -- 07.03.2017 Sofia SIAC-4568
		dataEmissione,      -- 07.03.2017 Sofia SIAC-4568
        enteproprietarioid,
        loginoperazione,
        loginoperazione,
        movgestrec.siope_tipo_debito_id,
		movgestrec.siope_assenza_motivazione_id
      )
      returning   movgest_ts_id
      INTO        movgesttsidret;

      IF movgesttsidret IS NULL THEN
        codresult:=-1;
        strmessaggiotemp:=strmessaggio;
      END IF;
      RAISE notice 'dopo inserimento siac_t_movgest_ts movGestTsIdRet=% codResult=%', movgesttsidret,codresult;

      -- siac_r_movgest_ts_stato
      strmessaggio:='Inserimento movimento ' || ' anno='  ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero || ' sub=' ||movgestrec.movgest_ts_code || ' [siac_r_movgest_ts_stato].';
      -- 07.02.2018 Sofia siac-5368
      /*INSERT INTO siac_r_movgest_ts_stato
	  (
          movgest_ts_id,
          movgest_stato_id,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
	  )
	  (
         SELECT movgesttsidret,
                r.movgest_stato_id,
                datainizioval,
                enteproprietarioid,
                loginoperazione
         FROM   siac_r_movgest_ts_stato r,
                siac_d_movgest_stato stato
         WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
         AND    stato.movgest_stato_id=r.movgest_stato_id
         AND    r.data_cancellazione IS NULL
         AND    r.validita_fine IS NULL
         AND    stato.data_cancellazione IS NULL
         AND    stato.validita_fine IS NULL )
      returning   movgest_stato_r_id INTO        codresult;*/

      -- 07.02.2018 Sofia siac-5368
	  if impostaProvvedimento=true then
      	     movGestStatoId:=movGestRec.movgest_stato_id;
      else   movGestStatoId:=movGestStatoPId;
      end if;

      INSERT INTO siac_r_movgest_ts_stato
	  (
          movgest_ts_id,
          movgest_stato_id,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
	  )
      values
      (
      	movgesttsidret,
        movGestStatoId,
        datainizioval,
        enteProprietarioId,
        loginoperazione
      )
      returning   movgest_stato_r_id INTO        codresult;


      IF codresult IS NULL THEN
        codresult:=-1;
        strmessaggiotemp:=strmessaggio;
      ELSE
        codresult:=NULL;
      END IF;
      RAISE notice 'dopo inserimento siac_r_movgest_ts_stato movGestTsIdRet=% codResult=%', movgesttsidret,codresult;
      -- siac_t_movgest_ts_det
      strmessaggio:='Inserimento movimento ' || ' anno=' ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero || ' sub=' ||movgestrec.movgest_ts_code|| ' [siac_t_movgest_ts_det].';
      RAISE notice ' inserimento siac_t_movgest_ts_det movGestTsIdRet=% movGestRec.movgest_ts_id=%', movgesttsidret,movgestrec.movgest_ts_id;
      -- 05.06.2020 Sofia Jira SIAC-7593
      --v_importomodifica := movgestrec.importomodifica * -1;
      -- 05.06.2020 Sofia Jira SIAC-7593
      v_importomodifica:= movgestrec.importo_reimputato;
      INSERT INTO siac_t_movgest_ts_det
	  (
        movgest_ts_id,
        movgest_ts_det_tipo_id,
        movgest_ts_det_importo,
        validita_inizio,
        ente_proprietario_id,
        login_operazione
	  )
	  (
       SELECT movgesttsidret,
              r.movgest_ts_det_tipo_id,
              v_importomodifica,
              datainizioval,
              enteproprietarioid,
              loginoperazione
       FROM   siac_t_movgest_ts_det r
       WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
       AND    r.data_cancellazione IS NULL
       AND    r.validita_fine IS NULL );

      IF codresult IS NULL THEN
        codresult:=-1;
        strmessaggiotemp:=strmessaggio;
      ELSE
        codresult:=NULL;
      END IF;
      strmessaggio:='Inserimento classificatori  movgest_ts_id='||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_class].';
      -- siac_r_movgest_class
      INSERT INTO siac_r_movgest_class
	  (
				  movgest_ts_id,
				  classif_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.classif_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_class r,
					siac_t_class class
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    class.classif_id=r.classif_id
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL
			 AND    class.data_cancellazione IS NULL
			 AND    class.validita_fine IS NULL );

      strmessaggio:='Inserimento attributi  movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_attr].';
      -- siac_r_movgest_ts_attr
      INSERT INTO siac_r_movgest_ts_attr
	  (
        movgest_ts_id,
        attr_id,
        tabella_id,
        BOOLEAN,
        percentuale,
        testo,
        numerico,
        validita_inizio,
        ente_proprietario_id,
        login_operazione
	  )
	  (
         SELECT movgesttsidret,
                r.attr_id,
                r.tabella_id,
                r.BOOLEAN,
                r.percentuale,
                r.testo,
                r.numerico,
                datainizioval,
                enteproprietarioid,
                loginoperazione
         FROM   siac_r_movgest_ts_attr r,
                siac_t_attr attr
         WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
         AND    attr.attr_id=r.attr_id
         AND    r.data_cancellazione IS NULL
         AND    r.validita_fine IS NULL
         AND    attr.data_cancellazione IS NULL
         AND    attr.validita_fine IS NULL
         AND    attr.attr_code NOT IN ('flagDaRiaccertamento',
                                       'annoRiaccertato',
                                       'numeroRiaccertato',
									   'flagDaReanno') ); -- 02.10.2020 SIAC-7593

-- SIAC-6997 ---------------- INIZIO --------------------
    if motivo = 'REIMP' then
-- SIAC-6997 ---------------- FINE --------------------

      INSERT INTO siac_r_movgest_ts_attr
	  (
				  movgest_ts_id ,
				  attr_id ,
				  tabella_id ,
				  "boolean" ,
				  percentuale,
				  testo,
				  numerico ,
				  validita_inizio ,
				  validita_fine ,
				  ente_proprietario_id ,
				  data_cancellazione ,
				  login_operazione
	  )  VALUES (
				  movgesttsidret ,
				  v_flagdariaccertamento_attr_id ,
				  NULL,
				  'S',
				  NULL,
				  NULL ,
				  NULL,
				  now() ,
				  NULL ,
				  enteproprietarioid ,
				  NULL ,
				  loginoperazione
	  );
-- SIAC-6997 ---------------- INIZIO --------------------
    else
      INSERT INTO siac_r_movgest_ts_attr
	  (
				  movgest_ts_id ,
				  attr_id ,
				  tabella_id ,
				  "boolean" ,
				  percentuale,
				  testo,
				  numerico ,
				  validita_inizio ,
				  validita_fine ,
				  ente_proprietario_id ,
				  data_cancellazione ,
				  login_operazione
	  )  VALUES (
				  movgesttsidret ,
				  v_flagdareanno_attr_id ,
				  NULL,
				  'S',
				  NULL,
				  NULL ,
				  NULL,
				  now() ,
				  NULL ,
				  enteproprietarioid ,
				  NULL ,
				  loginoperazione
	  );
    end if;
-- SIAC-6997 ----------------  FINE --------------------

      INSERT INTO siac_r_movgest_ts_attr
	  (
        movgest_ts_id ,
        attr_id ,
        tabella_id ,
        "boolean" ,
        percentuale,
        testo,
        numerico ,
        validita_inizio ,
        validita_fine ,
        ente_proprietario_id ,
        data_cancellazione ,
        login_operazione
	  )
	  VALUES
	  (
        movgesttsidret ,
        v_annoriaccertato_attr_id,
        NULL,
        NULL,
        NULL,
        movgestrec.movgest_anno ,
        NULL ,
        now() ,
        NULL,
        enteproprietarioid,
        NULL,
        loginoperazione
	  );

      INSERT INTO siac_r_movgest_ts_attr
	  (
        movgest_ts_id ,
        attr_id ,
        tabella_id ,
        "boolean" ,
        percentuale,
        testo,
        numerico ,
        validita_inizio ,
        validita_fine ,
        ente_proprietario_id ,
        data_cancellazione ,
        login_operazione
	  )
	  VALUES
	  (
        movgesttsidret ,
        v_numeroriaccertato_attr_id ,
        NULL,
        NULL,
        NULL,
        movgestrec.movgest_numero ,
        NULL,
        now() ,
        NULL ,
        enteproprietarioid ,
        NULL,
        loginoperazione
	  );

      -- siac_r_movgest_ts_atto_amm
      /*strmessaggio:='Inserimento   movgest_ts_id='
      ||movgestrec.movgest_ts_id::VARCHAR
      || ' [siac_r_movgest_ts_atto_amm].';
      INSERT INTO siac_r_movgest_ts_atto_amm
	  (
				  movgest_ts_id,
				  attoamm_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.attoamm_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_atto_amm r,
					siac_t_atto_amm atto
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    atto.attoamm_id=r.attoamm_id
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL
       );*/
--			 AND    atto.data_cancellazione IS NULL Sofia HD-INC000001535447
--			 AND    atto.validita_fine IS NULL );

	   -- 07.02.2018 Sofia siac-5368
	   if impostaProvvedimento=true then
       	strmessaggio:='Inserimento   movgest_ts_id='
	      ||movgestrec.movgest_ts_id::VARCHAR
    	  || ' [siac_r_movgest_ts_atto_amm].';
       	INSERT INTO siac_r_movgest_ts_atto_amm
	  	(
		 movgest_ts_id,
	     attoamm_id,
	     validita_inizio,
	     ente_proprietario_id,
	     login_operazione
	  	)
        values
        (
         movgesttsidret,
         movgestrec.attoamm_id,
         datainizioval,
	 	 enteproprietarioid,
	 	 loginoperazione
        );
       end if;


      -- siac_r_movgest_ts_sog
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_sog].';
      INSERT INTO siac_r_movgest_ts_sog
	  (
				  movgest_ts_id,
				  soggetto_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.soggetto_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_sog r,
					siac_t_soggetto sogg
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    sogg.soggetto_id=r.soggetto_id
			 AND    sogg.data_cancellazione IS NULL
			 AND    sogg.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_movgest_ts_sogclasse
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_sogclasse].';
      INSERT INTO siac_r_movgest_ts_sogclasse
	  (
				  movgest_ts_id,
				  soggetto_classe_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.soggetto_classe_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_sogclasse r,
					siac_d_soggetto_classe classe
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    classe.soggetto_classe_id=r.soggetto_classe_id
			 AND    classe.data_cancellazione IS NULL
			 AND    classe.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_movgest_ts_programma
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_programma].';
      INSERT INTO siac_r_movgest_ts_programma
	  (
				  movgest_ts_id,
				  programma_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.programma_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_programma r,
					siac_t_programma prog
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    prog.programma_id=r.programma_id
			 AND    prog.data_cancellazione IS NULL
			 AND    prog.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

     --- 18.06.2019 Sofia SIAC-6702
	 if p_movgest_tipo_code=imp_movgest_tipo then
      -- siac_r_movgest_ts_storico_imp_acc
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_storico_imp_acc].';
      INSERT INTO siac_r_movgest_ts_storico_imp_acc
	  (
			movgest_ts_id,
            movgest_anno_acc,
            movgest_numero_acc,
            movgest_subnumero_acc,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.movgest_anno_acc,
             		r.movgest_numero_acc,
		            r.movgest_subnumero_acc,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_storico_imp_acc r
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );
      end if;

      -- siac_r_mutuo_voce_movgest
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_mutuo_voce_movgest].';
      INSERT INTO siac_r_mutuo_voce_movgest
	  (
				  movgest_ts_id,
				  mut_voce_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.mut_voce_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_mutuo_voce_movgest r,
					siac_t_mutuo_voce voce
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    voce.mut_voce_id=r.mut_voce_id
			 AND    voce.data_cancellazione IS NULL
			 AND    voce.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_causale_movgest_ts
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_causale_movgest_ts].';
      INSERT INTO siac_r_causale_movgest_ts
	  (
				  movgest_ts_id,
				  caus_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.caus_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_causale_movgest_ts r,
					siac_d_causale caus
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    caus.caus_id=r.caus_id
			 AND    caus.data_cancellazione IS NULL
			 AND    caus.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- 05.05.2017 Sofia HD-INC000001737424
      -- siac_r_subdoc_movgest_ts
      /*
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_subdoc_movgest_ts].';
      INSERT INTO siac_r_subdoc_movgest_ts
	  (
				  movgest_ts_id,
				  subdoc_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.subdoc_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_subdoc_movgest_ts r,
					siac_t_subdoc sub
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    sub.subdoc_id=r.subdoc_id
			 AND    sub.data_cancellazione IS NULL
			 AND    sub.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_predoc_movgest_ts
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_predoc_movgest_ts].';
      INSERT INTO siac_r_predoc_movgest_ts
                  (
                              movgest_ts_id,
                              predoc_id,
                              validita_inizio,
                              ente_proprietario_id,
                              login_operazione
                  )
                  (
                         SELECT movgesttsidret,
                                r.predoc_id,
                                datainizioval,
                                enteproprietarioid,
                                loginoperazione
                         FROM   siac_r_predoc_movgest_ts r,
                                siac_t_predoc sub
                         WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
                         AND    sub.predoc_id=r.predoc_id
                         AND    sub.data_cancellazione IS NULL
                         AND    sub.validita_fine IS NULL
                         AND    r.data_cancellazione IS NULL
                         AND    r.validita_fine IS NULL );
	  */
      -- 05.05.2017 Sofia HD-INC000001737424


      strmessaggio:='aggiornamento tabella di appoggio';
      UPDATE fase_bil_t_reimputazione
      SET   movgestnew_ts_id =movgesttsidret
      		,movgestnew_id =movgestidret
            ,data_modifica = clock_timestamp()
       		,fl_elab='S'
      WHERE  reimputazione_id = movgestrec.reimputazione_id;



    END LOOP;

    -- bonifica eventuali scarti
    select * into cleanrec from fnc_fasi_bil_gest_reimputa_clean(  p_fasebilelabid ,enteproprietarioid );

	-- 15.02.2017 Sofia Sofia SIAC-4425
	if p_movgest_tipo_code=imp_movgest_tipo and cleanrec.codicerisultato =0 then
     -- insert N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
     -- essendo reimputazioni consideriamo solo mov.movgest_anno::integer>annoBilancio
     -- che non hanno ancora attributo
	 strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore N per impegni pluriennali.';
     INSERT INTO siac_r_movgest_ts_attr
	 (
	  movgest_ts_id,
	  attr_id,
	  boolean,
	  validita_inizio,
	  ente_proprietario_id,
	  login_operazione
	 )
	 select ts.movgest_ts_id,
	        flagFrazAttrId,
            'N',
		    dataInizioVal,
		    ts.ente_proprietario_id,
		    loginOperazione
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio)
     and   mov.movgest_anno::integer>annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   not exists (select 1 from siac_r_movgest_ts_attr r1
       		           where r1.movgest_ts_id=ts.movgest_ts_id
                       and   r1.attr_id=flagFrazAttrId
                       and   r1.data_cancellazione is null
                       and   r1.validita_fine is null);

     -- insert S per impegni mov.movgest_anno::integer=annoBilancio
     -- che non hanno ancora attributo
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore S per impegni di competenza senza atto amministrativo antecedente.';
	 INSERT INTO siac_r_movgest_ts_attr
	 (
	  movgest_ts_id,
	  attr_id,
	  boolean,
	  validita_inizio,
	  ente_proprietario_id,
	  login_operazione
	 )
	 select ts.movgest_ts_id,
	        flagFrazAttrId,
            'S',
	        dataInizioVal,
	        ts.ente_proprietario_id,
	        loginOperazione
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where mov.bil_id=bilancioId
	 and   mov.movgest_anno::integer=annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   not exists (select 1 from siac_r_movgest_ts_attr r1
       		           where r1.movgest_ts_id=ts.movgest_ts_id
                       and   r1.attr_id=flagFrazAttrId
                       and   r1.data_cancellazione is null
                       and   r1.validita_fine is null)
     and  not exists (select 1 from siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
					  where ra.movgest_ts_id=ts.movgest_ts_id
					  and   atto.attoamm_id=ra.attoamm_id
				 	  and   atto.attoamm_anno::integer < annoBilancio
		     		  and   ra.data_cancellazione is null
				      and   ra.validita_fine is null);

     -- aggiornamento N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
     -- essendo reimputazioni consideriamo solo mov.movgest_anno::integer>annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni pluriennali.';
	 update  siac_r_movgest_ts_attr r set boolean='N'
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where  mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<2017 or mov.movgest_anno::integer>2017)
	 and   mov.movgest_anno::integer>annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   r.movgest_ts_id=ts.movgest_ts_id
     and   r.attr_id=flagFrazAttrId
	 and   r.boolean='S'
     and   r.login_operazione=loginOperazione
     and   r.data_cancellazione is null
     and   r.validita_fine is null;

     -- aggiornamento N per impegni mov.movgest_anno::integer=annoBilancio e atto.attoamm_anno::integer < annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni di competenza con atto amministrativo antecedente.';
     update siac_r_movgest_ts_attr r set boolean='N'
  	 from siac_t_movgest mov, siac_t_movgest_ts ts,
	      siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
  	 where mov.bil_id=bilancioId
	 and   mov.movgest_anno::INTEGER=annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   r.movgest_ts_id=ts.movgest_ts_id
     and   r.attr_id=flagFrazAttrId
	 and   ra.movgest_ts_id=ts.movgest_ts_id
	 and   atto.attoamm_id=ra.attoamm_id
	 and   atto.attoamm_anno::integer < annoBilancio
	 and   r.boolean='S'
     and   r.login_operazione=loginOperazione
     and   r.data_cancellazione is null
     and   r.validita_fine is null
     and   ra.data_cancellazione is null
     and   ra.validita_fine is null;
    end if;
    -- 15.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile


    outfasebilelabretid:=p_fasebilelabid;
    if cleanrec.codicerisultato = -1 then
	    codicerisultato:=cleanrec.codicerisultato;
	    messaggiorisultato:=cleanrec.messaggiorisultato;
    else
	    codicerisultato:=0;
	    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||' FINE';
    end if;



    outfasebilelabretid:=p_fasebilelabid;
    codicerisultato:=0;
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||' FINE';
    RETURN;
  EXCEPTION
  WHEN raise_exception THEN
    RAISE notice '% % ERRORE : %',strmessaggiofinale,strmessaggio,substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'ERRORE :' ||' ' ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice ' % % Nessun elemento trovato.' ,strmessaggiofinale,strmessaggio;
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'Nessun elemento trovato.' ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE,substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'Errore DB ' ||SQLSTATE ||' ' ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter function
siac.fnc_fasi_bil_gest_reimputa_elabora 
(
  integer,
  integer,
  integer,
  boolean,
  varchar,
  timestamp,
  varchar,
  varchar,
  out  integer,
  out  integer,
  out  varchar
) OWNER to siac;

--- SIAC-8175 - Sofia fine

-- SIAC-7518 - Sofia inizio
drop table if exists siac.siac_dwh_st_documento_spesa;
CREATE TABLE siac.siac_dwh_st_documento_spesa
(
  ente_proprietario_id INTEGER,
  ente_denominazione VARCHAR(500),
  anno_atto_amministrativo VARCHAR(4),
  num_atto_amministrativo VARCHAR(200),
  oggetto_atto_amministrativo VARCHAR(500),
  cod_tipo_atto_amministrativo VARCHAR(200),
  desc_tipo_atto_amministrativo VARCHAR(200),
  cod_cdr_atto_amministrativo VARCHAR(200),
  desc_cdr_atto_amministrativo VARCHAR(500),
  cod_cdc_atto_amministrativo VARCHAR(200),
  desc_cdc_atto_amministrativo VARCHAR(500),
  note_atto_amministrativo VARCHAR(500),
  cod_stato_atto_amministrativo VARCHAR(200),
  desc_stato_atto_amministrativo VARCHAR(200),
  causale_atto_allegato VARCHAR(500),
  altri_allegati_atto_allegato VARCHAR(500),
  dati_sensibili_atto_allegato VARCHAR(1),
  data_scadenza_atto_allegato TIMESTAMP WITHOUT TIME ZONE,
  note_atto_allegato VARCHAR(500),
  annotazioni_atto_allegato VARCHAR(500),
  pratica_atto_allegato VARCHAR(500),
  resp_amm_atto_allegato VARCHAR(500),
  resp_contabile_atto_allegato VARCHAR(500),
  anno_titolario_atto_allegato INTEGER,
  num_titolario_atto_allegato VARCHAR(500),
  vers_invio_firma_atto_allegato INTEGER,
  cod_stato_atto_allegato VARCHAR(200),
  desc_stato_atto_allegato VARCHAR(200),
  sogg_id_atto_allegato INTEGER,
  cod_sogg_atto_allegato VARCHAR(200),
  tipo_sogg_atto_allegato VARCHAR(500),
  stato_sogg_atto_allegato VARCHAR(500),
  rag_sociale_sogg_atto_allegato VARCHAR(500),
  p_iva_sogg_atto_allegato VARCHAR(500),
  cf_sogg_atto_allegato VARCHAR(16),
  cf_estero_sogg_atto_allegato VARCHAR(500),
  nome_sogg_atto_allegato VARCHAR(500),
  cognome_sogg_atto_allegato VARCHAR(500),
  anno_doc INTEGER,
  num_doc VARCHAR(200),
  desc_doc VARCHAR(500),
  importo_doc NUMERIC,
  beneficiario_multiplo_doc VARCHAR(1),
  data_emissione_doc TIMESTAMP WITHOUT TIME ZONE,
  data_scadenza_doc TIMESTAMP WITHOUT TIME ZONE,
  codice_bollo_doc VARCHAR(200),
  desc_codice_bollo_doc VARCHAR(500),
  collegato_cec_doc VARCHAR(200),
  cod_pcc_doc VARCHAR(200),
  desc_pcc_doc VARCHAR(500),
  cod_ufficio_doc VARCHAR(200),
  desc_ufficio_doc VARCHAR(500),
  cod_stato_doc VARCHAR(200),
  desc_stato_doc VARCHAR(500),
  anno_elenco_doc INTEGER,
  num_elenco_doc INTEGER,
  data_trasmissione_elenco_doc TIMESTAMP WITHOUT TIME ZONE,
  tot_quote_entrate_elenco_doc NUMERIC,
  tot_quote_spese_elenco_doc NUMERIC,
  tot_da_pagare_elenco_doc NUMERIC,
  tot_da_incassare_elenco_doc NUMERIC,
  cod_stato_elenco_doc VARCHAR(200),
  desc_stato_elenco_doc VARCHAR(500),
  cod_gruppo_doc VARCHAR(200),
  desc_famiglia_doc VARCHAR(500),
  cod_famiglia_doc VARCHAR(200),
  desc_gruppo_doc VARCHAR(500),
  cod_tipo_doc VARCHAR(200),
  desc_tipo_doc VARCHAR(500),
  sogg_id_doc INTEGER,
  cod_sogg_doc VARCHAR(200),
  tipo_sogg_doc VARCHAR(500),
  stato_sogg_doc VARCHAR(500),
  rag_sociale_sogg_doc VARCHAR(500),
  p_iva_sogg_doc VARCHAR(500),
  cf_sogg_doc VARCHAR(16),
  cf_estero_sogg_doc VARCHAR(500),
  nome_sogg_doc VARCHAR(500),
  cognome_sogg_doc VARCHAR(500),
  num_subdoc INTEGER,
  desc_subdoc VARCHAR(500),
  importo_subdoc NUMERIC,
  num_reg_iva_subdoc VARCHAR(500),
  data_scadenza_subdoc TIMESTAMP WITHOUT TIME ZONE,
  convalida_manuale_subdoc VARCHAR(1),
  importo_da_dedurre_subdoc NUMERIC,
  splitreverse_importo_subdoc NUMERIC,
  pagato_cec_subdoc VARCHAR(1),
  data_pagamento_cec_subdoc TIMESTAMP WITHOUT TIME ZONE,
  note_tesoriere_subdoc VARCHAR(500),
  cod_distinta_subdoc VARCHAR(200),
  desc_distinta_subdoc VARCHAR(500),
  tipo_commissione_subdoc VARCHAR(500),
  conto_tesoreria_subdoc VARCHAR(500),
  rilevante_iva VARCHAR(1),
  ordinativo_singolo VARCHAR(1),
  ordinativo_manuale VARCHAR(1),
  esproprio VARCHAR(1),
  note VARCHAR(500),
  cig VARCHAR(500),
  cup VARCHAR(500),
  causale_sospensione VARCHAR(500),
  data_sospensione VARCHAR(500),
  data_riattivazione VARCHAR(500),
  causale_ordinativo VARCHAR(500),
  num_mutuo INTEGER,
  annotazione VARCHAR(500),
  certificazione VARCHAR(1),
  data_certificazione VARCHAR(500),
  note_certificazione VARCHAR(500),
  num_certificazione VARCHAR(500),
  data_scadenza_dopo_sospensione VARCHAR(500),
  data_esecuzione_pagamento VARCHAR(500),
  avviso VARCHAR(1),
  cod_tipo_avviso VARCHAR(200),
  desc_tipo_avviso VARCHAR(500),
  sogg_id_subdoc INTEGER,
  cod_sogg_subdoc VARCHAR(200),
  tipo_sogg_subdoc VARCHAR(500),
  stato_sogg_subdoc VARCHAR(500),
  rag_sociale_sogg_subdoc VARCHAR(500),
  p_iva_sogg_subdoc VARCHAR(500),
  cf_sogg_subdoc VARCHAR(16),
  cf_estero_sogg_subdoc VARCHAR(500),
  nome_sogg_subdoc VARCHAR(500),
  cognome_sogg_subdoc VARCHAR(500),
  sede_secondaria_subdoc VARCHAR(1),
  bil_anno VARCHAR(4),
  anno_impegno INTEGER,
  num_impegno NUMERIC,
  cod_impegno VARCHAR(200),
  desc_impegno VARCHAR(500),
  cod_subimpegno VARCHAR(200),
  desc_subimpegno VARCHAR(500),
  num_liquidazione NUMERIC,
  cod_tipo_accredito VARCHAR(200),
  desc_tipo_accredito VARCHAR(200),
  mod_pag_id INTEGER,
  quietanziante VARCHAR(500),
  data_nascita_quietanziante TIMESTAMP WITHOUT TIME ZONE,
  luogo_nascita_quietanziante VARCHAR(500),
  stato_nascita_quietanziante VARCHAR(500),
  bic VARCHAR(500),
  contocorrente VARCHAR(500),
  intestazione_contocorrente VARCHAR(500),
  iban VARCHAR(500),
  note_mod_pag VARCHAR(500),
  data_scadenza_mod_pag TIMESTAMP WITHOUT TIME ZONE,
  sogg_id_mod_pag INTEGER,
  cod_sogg_mod_pag VARCHAR(200),
  tipo_sogg_mod_pag VARCHAR(500),
  stato_sogg_mod_pag VARCHAR(500),
  rag_sociale_sogg_mod_pag VARCHAR(500),
  p_iva_sogg_mod_pag VARCHAR(500),
  cf_sogg_mod_pag VARCHAR(16),
  cf_estero_sogg_mod_pag VARCHAR(500),
  nome_sogg_mod_pag VARCHAR(500),
  cognome_sogg_mod_pag VARCHAR(500),
  anno_liquidazione INTEGER,
  bil_anno_ord VARCHAR(4),
  anno_ord INTEGER,
  num_ord NUMERIC,
  num_subord VARCHAR(200),
  data_elaborazione TIMESTAMP WITHOUT TIME ZONE,
  registro_repertorio VARCHAR(200),
  anno_repertorio VARCHAR(4),
  num_repertorio VARCHAR(200),
  data_repertorio VARCHAR(200),
  data_ricezione_portale VARCHAR(200),
  doc_contabilizza_genpcc VARCHAR(200),
  rudoc_registrazione_anno INTEGER,
  rudoc_registrazione_numero INTEGER,
  rudoc_registrazione_data TIMESTAMP WITHOUT TIME ZONE,
  cod_cdc_doc VARCHAR(200),
  desc_cdc_doc VARCHAR(500),
  cod_cdr_doc VARCHAR(200),
  desc_cdr_doc VARCHAR(500),
  data_operazione_pagamentoincasso VARCHAR(500),
  pagataincassata VARCHAR(500),
  note_pagamentoincasso VARCHAR(500),
  cod_tipo_splitrev VARCHAR(200),
  desc_tipo_splitrev VARCHAR(200),
  stato_liquidazione VARCHAR(200),
  arrotondamento NUMERIC,
  cod_siope_tipo_debito_subdoc VARCHAR(200),
  desc_siope_tipo_debito_subdoc VARCHAR(500),
  desc_siope_tipo_deb_bnkit_sub VARCHAR(500),
  cod_siope_ass_motiv_subdoc VARCHAR(200),
  desc_siope_ass_motiv_subdoc VARCHAR(500),
  desc_siope_ass_motiv_bnkit_sub VARCHAR(500),
  cod_siope_scad_motiv_subdoc VARCHAR(200),
  desc_siope_scad_motiv_subdoc VARCHAR(500),
  desc_siope_scad_moti_bnkit_sub VARCHAR(500),
  sdi_lotto_siope_doc VARCHAR(200),
  cod_siope_tipo_doc VARCHAR(200),
  desc_siope_tipo_doc VARCHAR(500),
  desc_siope_tipo_bnkit_doc VARCHAR(500),
  cod_siope_tipo_analogico_doc VARCHAR(200),
  desc_siope_tipo_analogico_doc VARCHAR(500),
  desc_siope_tipo_ana_bnkit_doc VARCHAR(500),
  data_ins_atto_allegato TIMESTAMP WITHOUT TIME ZONE,
  data_completa_atto_allegato TIMESTAMP WITHOUT TIME ZONE,
  data_convalida_atto_allegato TIMESTAMP WITHOUT TIME ZONE,
  data_sosp_atto_allegato TIMESTAMP WITHOUT TIME ZONE,
  data_riattiva_atto_allegato TIMESTAMP WITHOUT TIME ZONE,
  causale_sosp_atto_allegato VARCHAR(250),
  data_storico TIMESTAMP WITHOUT TIME ZONE not null default now(),
  doc_id INTEGER
)
WITH (oids = false);

alter table if exists
siac.siac_dwh_st_documento_spesa OWNER to siac;

insert into siac_d_gestione_tipo
  (
  	gestione_tipo_code,
    gestione_tipo_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  select 'ANNO_STORICO_DWH_DOC_SPESA_ATTIVO',
         'Impostazione anno storico in scarico dwh documenti di spesa',
         now(),
         'SIAC-7518',
         ente.ente_Proprietario_id
  from siac_t_ente_proprietario ente
  where ente.ente_proprietario_id =2
  and   not exists
  (
  select 1
  from siac_d_gestione_tipo tipo
  where tipo.ente_proprietario_id=ente.ente_proprietario_id
  and   tipo.gestione_tipo_code='ANNO_STORICO_DWH_DOC_SPESA_ATTIVO'
  );

  insert into siac_d_gestione_livello
  (
  	gestione_livello_code,
    gestione_livello_desc,
    gestione_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  select
	'2018_'||tipo.gestione_tipo_code,
    tipo.gestione_tipo_desc,
    tipo.gestione_tipo_id,
    now(),
    tipo.login_operazione,
    tipo.ente_proprietario_id
  from siac_d_gestione_tipo tipo,siac_t_ente_proprietario ente
  where ente.ente_Proprietario_id =2
  and   tipo.ente_proprietario_id=ente.ente_proprietario_id
  and   tipo.gestione_tipo_code='ANNO_STORICO_DWH_DOC_SPESA_ATTIVO'
  and   not exists
  (
  select 1
  from siac_d_gestione_livello liv
  where liv.ente_proprietario_id=ente.ente_proprietario_id
  and   liv.gestione_tipo_id=tipo.gestione_tipo_id
  and   liv.gestione_livello_code='2018_'||tipo.gestione_tipo_code
  );


  insert into siac_d_gestione_tipo
  (
  	gestione_tipo_code,
    gestione_tipo_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  select 'CARICA_STORICO_DWH_DOC_SPESA_ATTIVO',
         'Attivazione caricamento dati di storico in scarico dwh documenti di spesa',
         now(),
         'SIAC-7518',
         ente.ente_Proprietario_id
  from siac_t_ente_proprietario ente
  where ente.ente_proprietario_id =2
  and   not exists
  (
  select 1
  from siac_d_gestione_tipo tipo
  where tipo.ente_proprietario_id=ente.ente_proprietario_id
  and   tipo.gestione_tipo_code='CARICA_STORICO_DWH_DOC_SPESA_ATTIVO'
  );

  insert into siac_d_gestione_livello
  (
  	gestione_livello_code,
    gestione_livello_desc,
    gestione_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  select
	tipo.gestione_tipo_code,
    tipo.gestione_tipo_desc,
    tipo.gestione_tipo_id,
    now(),
    tipo.login_operazione,
    tipo.ente_proprietario_id
  from siac_d_gestione_tipo tipo,siac_t_ente_proprietario ente
  where ente.ente_Proprietario_id =2
  and   tipo.ente_proprietario_id=ente.ente_proprietario_id
  and   tipo.gestione_tipo_code='CARICA_STORICO_DWH_DOC_SPESA_ATTIVO'
  and   not exists
  (
  select 1
  from siac_d_gestione_livello liv
  where liv.ente_proprietario_id=ente.ente_proprietario_id
  and   liv.gestione_tipo_id=tipo.gestione_tipo_id
  and   liv.gestione_livello_code=tipo.gestione_tipo_code
  );


  insert into siac_d_gestione_tipo
  (
  	gestione_tipo_code,
    gestione_tipo_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  select 'ELABORA_STORICO_DWH_DOC_SPESA_ATTIVO',
         'Attivazione elaborazione caricamento dati di storico documenti di spesa per dwh',
         now(),
         'SIAC-7518',
         ente.ente_Proprietario_id
  from siac_t_ente_proprietario ente
  where ente.ente_proprietario_id=2
  and   not exists
  (
  select 1
  from siac_d_gestione_tipo tipo
  where tipo.ente_proprietario_id=ente.ente_proprietario_id
  and   tipo.gestione_tipo_code='ELABORA_STORICO_DWH_DOC_SPESA_ATTIVO'
  );

  insert into siac_d_gestione_livello
  (
  	gestione_livello_code,
    gestione_livello_desc,
    gestione_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  select
	tipo.gestione_tipo_code,
    tipo.gestione_tipo_desc,
    tipo.gestione_tipo_id,
    now(),
    tipo.login_operazione,
    tipo.ente_proprietario_id
  from siac_d_gestione_tipo tipo,siac_t_ente_proprietario ente
  where ente.ente_Proprietario_id =2
  and   tipo.ente_proprietario_id=ente.ente_proprietario_id
  and   tipo.gestione_tipo_code='ELABORA_STORICO_DWH_DOC_SPESA_ATTIVO'
  and   not exists
  (
  select 1
  from siac_d_gestione_livello liv
  where liv.ente_proprietario_id=ente.ente_proprietario_id
  and   liv.gestione_tipo_id=tipo.gestione_tipo_id
  and   liv.gestione_livello_code=tipo.gestione_tipo_code
  );
  
  
drop FUNCTION if exists siac.fnc_siac_dwh_documento_spesa
(
  p_ente_proprietario_id integer,
  p_data timestamp
);

drop FUNCTION if exists siac.fnc_siac_dwh_st_documento_spesa
(
  p_ente_proprietario_id integer,
  p_data timestamp
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_documento_spesa
(
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

v_user_table varchar;
params varchar;
fnc_eseguita integer;

-- 26.01.2021 Sofia Jira SIAC-7518
annoStorico INTEGER:=2018;
caricaDatiStorico integer:=null;
BEGIN

SET local work_mem = '64MB'; -- 22.04.2021 Sofia - indicazioni di Meo B.


select count(*) into fnc_eseguita
from siac_dwh_log_elaborazioni
a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.fnc_elaborazione_inizio >= (now() - interval '13 hours')::timestamp -- non deve esistere  una elaborazione uguale nelle 13 ore che precedono la chimata
and a.fnc_name='fnc_siac_dwh_documento_spesa' ;

-- 13.03.2020 Sofia jira 	SIAC-7513
fnc_eseguita:=0;
if fnc_eseguita> 0 then

return;

else

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

-- 26.01.2021 Sofia JIRA siac-7518
select substr(liv.gestione_livello_code,1,4)::integer into annoStorico
from siac_d_gestione_livello liv,siac_d_gestione_tipo tipo
where tipo.ente_proprietario_id=p_ente_proprietario_id
and   tipo.gestione_tipo_code='ANNO_STORICO_DWH_DOC_SPESA_ATTIVO'
and   liv.gestione_tipo_id=tipo.gestione_tipo_id
and   tipo.data_cancellazione is null
and   liv.data_cancellazione  is null;

if annoStorico is null then
--	annoStorico:=extract( year from now()::timestamp)-3;
    annoStorico:=2000;
end if;
-- 26.01.2021 Sofia JIRA siac-7518
select fnc_siac_random_user()
into	v_user_table;

-- 26.01.2021 Sofia Jira SIAC-7518
--params := p_ente_proprietario_id::varchar||' - '||p_data::varchar;
-- 26.01.2021 Sofia Jira SIAC-7518
params := p_ente_proprietario_id::varchar||' - annoStorico '||annoStorico::varchar||' - '||p_data::varchar;
insert into
siac_dwh_log_elaborazioni (
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values (
p_ente_proprietario_id,
'fnc_siac_dwh_documento_spesa',
params,
clock_timestamp(),
v_user_table
);


esito:= params||' - Inizio funzione carico documenti spesa (FNC_SIAC_DWH_DOCUMENTO_SPESA) - '||clock_timestamp();
RETURN NEXT;

DELETE FROM siac.siac_dwh_documento_spesa
WHERE ente_proprietario_id = p_ente_proprietario_id;
esito:= 'In funzione carico documenti spesa (FNC_SIAC_DWH_DOCUMENTO_SPESA) - fine eliminazione dati pregressi - '||clock_timestamp();

-- 20.01.2021 Sofia jira SIAC-7967
update siac_dwh_log_elaborazioni   log
set    fnc_elaborazione_fine = clock_timestamp(),
       fnc_durata=clock_timestamp()-log.fnc_elaborazione_inizio,
       fnc_parameters=log.fnc_parameters||' - '||esito
where fnc_user=v_user_table;
RETURN NEXT;


INSERT INTO
  siac.siac_dwh_documento_spesa
(
  ente_proprietario_id,
  ente_denominazione,
  anno_atto_amministrativo,
  num_atto_amministrativo,
  oggetto_atto_amministrativo,
  cod_tipo_atto_amministrativo,
  desc_tipo_atto_amministrativo,
  cod_cdr_atto_amministrativo,
  desc_cdr_atto_amministrativo,
  cod_cdc_atto_amministrativo,
  desc_cdc_atto_amministrativo,
  note_atto_amministrativo,
  cod_stato_atto_amministrativo,
  desc_stato_atto_amministrativo,
  causale_atto_allegato,
  altri_allegati_atto_allegato,
  dati_sensibili_atto_allegato,
  data_scadenza_atto_allegato,
  note_atto_allegato,
  annotazioni_atto_allegato,
  pratica_atto_allegato,
  resp_amm_atto_allegato,
  resp_contabile_atto_allegato,
  anno_titolario_atto_allegato,
  num_titolario_atto_allegato,
  vers_invio_firma_atto_allegato,
  cod_stato_atto_allegato,
  desc_stato_atto_allegato,
  sogg_id_atto_allegato,
  cod_sogg_atto_allegato,
  tipo_sogg_atto_allegato,
  stato_sogg_atto_allegato,
  rag_sociale_sogg_atto_allegato,
  p_iva_sogg_atto_allegato,
  cf_sogg_atto_allegato,
  cf_estero_sogg_atto_allegato,
  nome_sogg_atto_allegato,
  cognome_sogg_atto_allegato,
  anno_doc,
  num_doc,
  desc_doc,
  importo_doc,
  beneficiario_multiplo_doc,
  data_emissione_doc,
  data_scadenza_doc,
  codice_bollo_doc,
  desc_codice_bollo_doc,
  collegato_cec_doc,
  cod_pcc_doc,
  desc_pcc_doc,
  cod_ufficio_doc,
  desc_ufficio_doc,
  cod_stato_doc,
  desc_stato_doc,
  anno_elenco_doc,
  num_elenco_doc,
  data_trasmissione_elenco_doc,
  tot_quote_entrate_elenco_doc,
  tot_quote_spese_elenco_doc,
  tot_da_pagare_elenco_doc,
  tot_da_incassare_elenco_doc,
  cod_stato_elenco_doc,
  desc_stato_elenco_doc,
  cod_gruppo_doc,
  desc_famiglia_doc,
  cod_famiglia_doc,
  desc_gruppo_doc,
  cod_tipo_doc,
  desc_tipo_doc,
  sogg_id_doc,
  cod_sogg_doc,
  tipo_sogg_doc,
  stato_sogg_doc,
  rag_sociale_sogg_doc,
  p_iva_sogg_doc,
  cf_sogg_doc,
  cf_estero_sogg_doc,
  nome_sogg_doc,
  cognome_sogg_doc,
  num_subdoc,
  desc_subdoc,
  importo_subdoc,
  num_reg_iva_subdoc,
  data_scadenza_subdoc,
  convalida_manuale_subdoc,
  importo_da_dedurre_subdoc,
  splitreverse_importo_subdoc,
  pagato_cec_subdoc,
  data_pagamento_cec_subdoc,
  note_tesoriere_subdoc,
  cod_distinta_subdoc,
  desc_distinta_subdoc,
  tipo_commissione_subdoc,
  conto_tesoreria_subdoc,
  rilevante_iva,
  ordinativo_singolo,
  ordinativo_manuale,
  esproprio,
  note,
  cig,
  cup,
  causale_sospensione,
  data_sospensione,
  data_riattivazione,
  causale_ordinativo,
  num_mutuo,
  annotazione,
  certificazione,
  data_certificazione,
  note_certificazione,
  num_certificazione,
  data_scadenza_dopo_sospensione,
  data_esecuzione_pagamento,
  avviso,
  cod_tipo_avviso,
  desc_tipo_avviso,
  sogg_id_subdoc,
  cod_sogg_subdoc,
  tipo_sogg_subdoc,
  stato_sogg_subdoc,
  rag_sociale_sogg_subdoc,
  p_iva_sogg_subdoc,
  cf_sogg_subdoc,
  cf_estero_sogg_subdoc,
  nome_sogg_subdoc,
  cognome_sogg_subdoc,
  sede_secondaria_subdoc,
  bil_anno,
  anno_impegno,
  num_impegno,
  cod_impegno,
  desc_impegno,
  cod_subimpegno,
  desc_subimpegno,
  num_liquidazione,
  cod_tipo_accredito,
  desc_tipo_accredito,
  mod_pag_id,
  quietanziante,
  data_nascita_quietanziante,
  luogo_nascita_quietanziante,
  stato_nascita_quietanziante,
  bic,
  contocorrente,
  intestazione_contocorrente,
  iban,
  note_mod_pag,
  data_scadenza_mod_pag,
  sogg_id_mod_pag,
  cod_sogg_mod_pag,
  tipo_sogg_mod_pag,
  stato_sogg_mod_pag,
  rag_sociale_sogg_mod_pag,
  p_iva_sogg_mod_pag,
  cf_sogg_mod_pag,
  cf_estero_sogg_mod_pag,
  nome_sogg_mod_pag,
  cognome_sogg_mod_pag,
  anno_liquidazione,
  bil_anno_ord,
  anno_ord,
  num_ord,
  num_subord,
  registro_repertorio,
  anno_repertorio,
  num_repertorio,
  data_repertorio,
  data_ricezione_portale,
  doc_contabilizza_genpcc,
  rudoc_registrazione_anno,
  rudoc_registrazione_numero,
  rudoc_registrazione_data,
  cod_cdc_doc,
  desc_cdc_doc,
  cod_cdr_doc,
  desc_cdr_doc,
  data_operazione_pagamentoincasso,
  pagataincassata,
  note_pagamentoincasso,
  -- 	SIAC-5229
  arrotondamento,
  cod_tipo_splitrev,
  desc_tipo_splitrev,
  stato_liquidazione,
  sdi_lotto_siope_doc,
  cod_siope_tipo_doc,
  desc_siope_tipo_doc,
  desc_siope_tipo_bnkit_doc,
  cod_siope_tipo_analogico_doc,
  desc_siope_tipo_analogico_doc,
  desc_siope_tipo_ana_bnkit_doc,
  cod_siope_tipo_debito_subdoc,
  desc_siope_tipo_debito_subdoc,
  desc_siope_tipo_deb_bnkit_sub,
  cod_siope_ass_motiv_subdoc,
  desc_siope_ass_motiv_subdoc,
  desc_siope_ass_motiv_bnkit_sub,
  cod_siope_scad_motiv_subdoc,
  desc_siope_scad_motiv_subdoc,
  desc_siope_scad_moti_bnkit_sub,
  doc_id, -- SIAC-5573,
  data_ins_atto_allegato,
  data_sosp_atto_allegato,
  causale_sosp_atto_allegato,
  data_riattiva_atto_allegato,
  data_completa_atto_allegato,
  data_convalida_atto_allegato
  )
select
tb.v_ente_proprietario_id::INTEGER,
trim(tb.v_ente_denominazione::VARCHAR)::VARCHAR,
trim(tb.v_anno_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_num_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_oggetto_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_tipo_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_cdr_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_cdr_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_cdc_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_cdc_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_note_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_stato_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_causale_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_altri_allegati_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_dati_sensibili_atto_allegato::VARCHAR)::VARCHAR,
tb.v_data_scadenza_atto_allegato::timestamp,
trim(tb.v_note_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_annotazioni_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_pratica_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_resp_amm_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_resp_contabile_atto_allegato::VARCHAR)::VARCHAR,
tb.v_anno_titolario_atto_allegato::INTEGER,
trim(tb.v_num_titolario_atto_allegato::VARCHAR)::VARCHAR,
tb.v_vers_invio_firma_atto_allegato::INTEGER,
trim(tb.v_cod_stato_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_atto_allegato::VARCHAR)::VARCHAR,
tb.v_sogg_id_atto_allegato::INTEGER,
trim(tb.v_cod_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_atto_allegato::VARCHAR)::VARCHAR,
tb.v_anno_doc::INTEGER,
trim(tb.v_num_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_doc::VARCHAR)::VARCHAR,
tb.v_importo_doc::NUMERIC,
trim(tb.v_beneficiario_multiplo_doc::VARCHAR)::VARCHAR,
tb.v_data_emissione_doc::TIMESTAMP,
tb.v_data_scadenza_doc::TIMESTAMP,
trim(tb.v_codice_bollo_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_codice_bollo_doc::VARCHAR)::VARCHAR,
tb.v_collegato_cec_doc,
trim(tb.v_cod_pcc_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_pcc_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_ufficio_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_ufficio_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_stato_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_doc::VARCHAR)::VARCHAR,
tb.v_anno_elenco_doc::INTEGER,
tb.v_num_elenco_doc::INTEGER,
tb.v_data_trasmissione_elenco_doc::TIMESTAMP,
tb.v_tot_quote_entrate_elenco_doc::NUMERIC,
tb.v_tot_quote_spese_elenco_doc::NUMERIC,
tb.v_tot_da_pagare_elenco_doc::NUMERIC,
tb.v_tot_da_incassare_elenco_doc::NUMERIC,
trim(tb.v_cod_stato_elenco_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_elenco_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_gruppo_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_famiglia_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_famiglia_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_gruppo_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_tipo_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_doc::VARCHAR)::VARCHAR,
tb.v_sogg_id_doc::INTEGER,
trim(tb.v_cod_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_doc::VARCHAR)::VARCHAR,
tb.v_num_subdoc::INTEGER,
trim(tb.v_desc_subdoc::VARCHAR)::VARCHAR,
tb.v_importo_subdoc::NUMERIC,
trim(tb.v_num_reg_iva_subdoc::VARCHAR)::VARCHAR,
tb.v_data_scadenza_subdoc::TIMESTAMP,
trim(tb.v_convalida_manuale_subdoc::VARCHAR)::VARCHAR,
tb.v_importo_da_dedurre_subdoc::NUMERIC,
tb.v_splitreverse_importo_subdoc::NUMERIC,
tb.v_pagato_cec_subdoc,
tb.v_data_pagamento_cec_subdoc::TIMESTAMP,
trim(tb.v_note_tesoriere_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cod_distinta_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_desc_distinta_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_tipo_commissione_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_conto_tesoreria_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_rilevante_iva::VARCHAR)::VARCHAR,
trim(tb.v_ordinativo_singolo::VARCHAR)::VARCHAR,
trim(tb.v_ordinativo_manuale::VARCHAR)::VARCHAR,
trim(tb.v_esproprio::VARCHAR)::VARCHAR,
trim(tb.v_note::VARCHAR)::VARCHAR,
trim(tb.v_cig::VARCHAR)::VARCHAR,
trim(tb.v_cup::VARCHAR)::VARCHAR,
trim(tb.v_causale_sospensione::VARCHAR)::VARCHAR,
trim(tb.v_data_sospensione::VARCHAR)::VARCHAR,
trim(tb.v_data_riattivazione::VARCHAR)::VARCHAR,
trim(tb.v_causale_ordinativo::VARCHAR)::VARCHAR,
tb.v_num_mutuo::INTEGER,
trim(tb.v_annotazione::VARCHAR)::VARCHAR,
trim(tb.v_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_data_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_note_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_num_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_data_scadenza_dopo_sospensione::VARCHAR)::VARCHAR,
trim(tb.v_data_esecuzione_pagamento::VARCHAR)::VARCHAR,
trim(tb.v_avviso::VARCHAR)::VARCHAR,
trim(tb.v_cod_tipo_avviso::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_avviso::VARCHAR)::VARCHAR,
tb.v_soggetto_id::INTEGER,
trim(tb.v_cod_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_sede_secondaria_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_bil_anno::VARCHAR)::VARCHAR,
tb.v_anno_impegno::INTEGER,
tb.v_num_impegno::NUMERIC,
trim(tb.v_cod_impegno::VARCHAR)::VARCHAR,
trim(tb.v_desc_impegno::VARCHAR)::VARCHAR,
trim(tb.v_cod_subimpegno::VARCHAR)::VARCHAR,
trim(tb.v_desc_subimpegno::VARCHAR)::VARCHAR,
tb.v_num_liquidazione::NUMERIC,
trim(tb.v_cod_tipo_accredito::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_accredito::VARCHAR)::VARCHAR,
tb.v_mod_pag_id::INTEGER,
trim(tb.v_quietanziante::VARCHAR)::VARCHAR,
tb.v_data_nasciata_quietanziante::TIMESTAMP,
trim(tb.v_luogo_nascita_quietanziante::VARCHAR)::VARCHAR,
trim(tb.v_stato_nascita_quietanziante::VARCHAR)::VARCHAR,
trim(tb.v_bic::VARCHAR)::VARCHAR,
trim(tb.v_contocorrente::VARCHAR)::VARCHAR,
trim(tb.v_intestazione_contocorrente::VARCHAR)::VARCHAR,
trim(tb.v_iban::VARCHAR)::VARCHAR,
trim(tb.v_note_mod_pag::VARCHAR)::VARCHAR,
tb.v_data_scadenza_mod_pag::TIMESTAMP,
tb.v_soggetto_id_modpag::INTEGER,
trim(tb.v_cod_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_mod_pag::VARCHAR)::VARCHAR,
tb.v_anno_liquidazione::INTEGER,
trim(tb.v_bil_anno_ord::VARCHAR)::VARCHAR,
tb.v_anno_ord::INTEGER,
tb.v_num_ord::NUMERIC,
trim(tb.v_num_subord::VARCHAR)::VARCHAR,
--nuova sezione coge 26-09-2016
trim(tb.v_registro_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_anno_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_num_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_data_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_data_ricezione_portale::VARCHAR)::VARCHAR,
trim(tb.v_doc_contabilizza_genpcc::VARCHAR)::VARCHAR,
-- CR 854
tb.rudoc_registrazione_anno::INTEGER,
tb.rudoc_registrazione_numero::INTEGER,
tb.rudoc_registrazione_data::TIMESTAMP,
trim(tb.cdc_code::VARCHAR)::VARCHAR,
trim(tb.cdc_desc::VARCHAR)::VARCHAR,
trim(tb.cdr_code::VARCHAR)::VARCHAR,
trim(tb.cdr_desc::VARCHAR)::VARCHAR,
trim(tb.v_dataOperazionePagamentoIncasso::VARCHAR)::VARCHAR,
trim(tb.v_flagPagataIncassata::VARCHAR)::VARCHAR,
trim(tb.v_notePagamentoIncasso::VARCHAR)::VARCHAR,
---- SIAC-5229
tb.v_arrotondamento,
-------------
trim(tb.v_cod_tipo_splitrev::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_splitrev::VARCHAR)::VARCHAR,
trim(tb.v_liq_stato_desc::VARCHAR)::VARCHAR,
tb.doc_sdi_lotto_siope,
tb.siope_documento_tipo_code,
tb.siope_documento_tipo_desc,
tb.siope_documento_tipo_desc_bnkit,
tb.siope_documento_tipo_analogico_code,
tb.siope_documento_tipo_analogico_desc,
tb.siope_documento_tipo_analogico_desc_bnkit,
tb.siope_tipo_debito_code,
tb.siope_tipo_debito_desc,
tb.siope_tipo_debito_desc_bnkit,
tb.siope_assenza_motivazione_code,
tb.siope_assenza_motivazione_desc,
tb.siope_assenza_motivazione_desc_bnkit,
tb.siope_scadenza_motivo_code,
tb.siope_scadenza_motivo_desc,
tb.siope_scadenza_motivo_desc_bnkit ,
tb.doc_id, -- SIAC-5573,
--- 15.05.2018 Sofia SIAC-6124
tb.data_ins_atto_allegato::timestamp,
tb.data_sosp_atto_allegato::timestamp,
tb.causale_sosp_atto_allegato,
tb.data_riattiva_atto_allegato::timestamp,
tb.data_completa_atto_allegato::timestamp,
tb.data_convalida_atto_allegato::timestamp
from (
with doc as (
  with doc1 as
  (
      with
      doc_totale as
      (
        select distinct
        --h.subdoc_id,a.doc_id,b.doc_tipo_id,c.doc_fam_tipo_id,d.doc_gruppo_tipo_id,e.doc_stato_r_id,f.doc_stato_id,
        b.doc_gruppo_tipo_id,
        g.ente_proprietario_id, g.ente_denominazione,
        a.doc_anno, a.doc_numero, a.doc_desc, a.doc_importo,
        case when a.doc_beneficiariomult= false then 'F' else 'T' end doc_beneficiariomult,
        a.doc_data_emissione, a.doc_data_scadenza,
        case when a.doc_collegato_cec = false then 'F' else 'T' end doc_collegato_cec,
        f.doc_stato_code, f.doc_stato_desc,
        c.doc_fam_tipo_code, c.doc_fam_tipo_desc, b.doc_tipo_code, b.doc_tipo_desc,
        a.doc_id, a.pcccod_id, a.pccuff_id,
        case when a.doc_contabilizza_genpcc= false then 'F' else 'T' end doc_contabilizza_genpcc,
        h.subdoc_numero, h.subdoc_desc, h.subdoc_importo, h.subdoc_nreg_iva, h.subdoc_data_scadenza,
        h.subdoc_convalida_manuale, h.subdoc_importo_da_dedurre, h.subdoc_splitreverse_importo,
        case when h.subdoc_pagato_cec = false then 'F' else 'T' end subdoc_pagato_cec,
        h.subdoc_data_pagamento_cec,
        a.codbollo_id, h.subdoc_id,h.comm_tipo_id,
        h.notetes_id,h.dist_id,h.contotes_id,
        a.doc_sdi_lotto_siope,
        n.siope_documento_tipo_code, n.siope_documento_tipo_desc, n.siope_documento_tipo_desc_bnkit,
        o.siope_documento_tipo_analogico_code, o.siope_documento_tipo_analogico_desc, o.siope_documento_tipo_analogico_desc_bnkit,
        i.siope_tipo_debito_code, i.siope_tipo_debito_desc, i.siope_tipo_debito_desc_bnkit,
        l.siope_assenza_motivazione_code, l.siope_assenza_motivazione_desc, l.siope_assenza_motivazione_desc_bnkit,
        m.siope_scadenza_motivo_code, m.siope_scadenza_motivo_desc, m.siope_scadenza_motivo_desc_bnkit
        from siac_t_doc a
        left join siac_d_siope_documento_tipo n on n.siope_documento_tipo_id = a.siope_documento_tipo_id
                                           and n.data_cancellazione is null
                                           and n.validita_fine is null
        left join siac_d_siope_documento_tipo_analogico o on o.siope_documento_tipo_analogico_id = a.siope_documento_tipo_analogico_id
                                                   and o.data_cancellazione is null
                                                   and o.validita_fine is null
        ,siac_d_doc_tipo b,siac_d_doc_fam_tipo c,
        --siac_d_doc_gruppo d,
        siac_r_doc_stato e,
        siac_d_doc_stato f,
        siac_t_ente_proprietario g,
        siac_t_subdoc h
        left join siac_d_siope_tipo_debito i on i.siope_tipo_debito_id = h.siope_tipo_debito_id
                                           and i.data_cancellazione is null
                                           and i.validita_fine is null
        left join siac_d_siope_assenza_motivazione l on l.siope_assenza_motivazione_id = h.siope_assenza_motivazione_id
                                                   and l.data_cancellazione is null
                                                   and l.validita_fine is null
        left join siac_d_siope_scadenza_motivo m on m.siope_scadenza_motivo_id = h.siope_scadenza_motivo_id
                                                   and m.data_cancellazione is null
                                                   and m.validita_fine is null
        where b.doc_tipo_id=a.doc_tipo_id
        and c.doc_fam_tipo_id=b.doc_fam_tipo_id
        --and b.doc_gruppo_tipo_id=d.doc_gruppo_tipo_id
        and e.doc_id=a.doc_id
        and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
        and f.doc_stato_id=e.doc_stato_id
        and g.ente_proprietario_id=a.ente_proprietario_id
        and g.ente_proprietario_id=p_ente_proprietario_id--p_ente_proprietario_id
        AND c.doc_fam_tipo_code in ('S','IS')
        and h.doc_id=a.doc_id
        -- 19.01.2021 Sofia Jira SIAC_7966 - inizio
        -- and date_trunc('DAY',a.data_creazione)=date_trunc('DAY',now())
        -- 26.01.2021 Sofia JIRA SIAC-7518 - inizio
        -- 1 esclusione pagamenti su mandato antecedente annoStorico
        and  not exists
        (
         select 1
         from  siac_t_bil anno,siac_t_periodo per,
               siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
               siac_r_ordinativo_stato rs,siac_d_ordinativo_Stato stato,
               siac_t_ordinativo_ts ts,siac_r_subdoc_ordinativo_ts rsub
         where f.doc_stato_code='EM'
         and   rsub.subdoc_id=h.subdoc_id
         and   ts.ord_ts_id=rsub.ord_ts_id
         and   ord.ord_id=ts.ord_id
         and   tipo.ord_tipo_id=ord.ord_tipo_id
         and   tipo.ord_tipo_code='P'
         and   anno.bil_id=ord.bil_id
         and   per.periodo_id=anno.periodo_id
         and   per.anno::integer<=annoStorico
         and   rs.ord_id=ord.ord_id
         and   stato.ord_stato_id=rs.ord_stato_id
         and   stato.ord_stato_code!='A'
         and   not exists
         (
          select 1
          from siac_t_subdoc sub1,siac_r_subdoc_ordinativo_ts rsub1,
               siac_t_ordinativo_ts ts1,siac_t_ordinativo ord1,
               siac_t_bil anno1,siac_t_periodo per1
          where sub1.doc_id=a.doc_id
          and   rsub1.subdoc_id=sub1.subdoc_id
          and   ts1.ord_ts_id=rsub1.ord_ts_id
          and   ord1.ord_id=ts1.ord_id
          and   anno1.bil_id=ord1.bil_id
          and   per1.periodo_id=anno1.bil_id
          and   per1.anno::integer>=annoStorico+1
          and   rsub1.data_cancellazione is null
          and   rsub1.validita_fine is null
         )
         and   rsub.data_cancellazione is null
         and   rsub.validita_fine is null
         and   ts.data_cancellazione is null
         and   ts.validita_fine is null
         and   rs.data_cancellazione is null
         and   rs.validita_fine is null
        )
        -- 2 esclusione pagamenti manuali dataOperazionePagamentoIncasso antecedente annoStorico
        and not exists
        (
          with
          doc_paga_man as
          (
          select rattr.doc_id,
                 substring(coalesce(rattrDataPAga.testo,'01/01/'||(annoStorico+1)::varchar||''),7,4)::integer annoDataPaga
          from siac_r_doc_attr rattr,siac_t_attr attr,
               siac_r_doc_Stato rs,siac_d_doc_Stato stato,
               siac_r_doc_attr rattrDataPaga,siac_t_attr attrDataPaga
          where rattr.doc_id=a.doc_id
          and   attr.attr_id=rattr.attr_id
          and   attr.attr_code='flagPagataIncassata'
          and   rattr.boolean='S'
          and   rs.doc_id=a.doc_id
          and   stato.doc_stato_id=rs.doc_stato_id
          and   stato.doc_stato_code='EM'
          and   rattrDataPaga.doc_id=a.doc_id
          and   attrDataPaga.attr_id=rattrDataPaga.attr_id
          and   attrdatapaga.attr_code='dataOperazionePagamentoIncasso'
          and   rattr.data_cancellazione is null
          and   rs.data_cancellazione is null
          and   rs.validita_fine is null
          )
          select query_doc_paga_man.*
          from doc_paga_man  query_doc_paga_man
          where query_doc_paga_man.annoDataPaga<=annoStorico
        )
        -- 3 - esclusione documenti ANNULLATI IN ANNI ANTECEDENTI annoStorico
        and not exists
        (
           select 1
           where f.doc_stato_code='A'
           and  extract (year from e.validita_inizio)::integer<=annoStorico
        )
 	    -- 4 - esclusione documenti STORNATI IN ANNI ANTECEDENTI annoStorico
        and not exists
        (
           select 1
           where f.doc_stato_code='ST'
           and  extract (year from e.validita_inizio)::integer<=annoStorico
        )
        -- 19.01.2021 Sofia Jira SIAC_7966 - fine
        -- 26.01.2021 Sofia JIRA SIAC-7518 - fine
        AND a.data_cancellazione IS NULL
        AND b.data_cancellazione IS NULL
        AND c.data_cancellazione IS NULL
        AND e.data_cancellazione IS NULL
        AND f.data_cancellazione IS NULL
        AND g.data_cancellazione IS NULL
        AND h.data_cancellazione IS NULL
  --      order by a.doc_anno::integer desc
     )
     select doc_tot.*
     from doc_totale doc_tot
--     limit 10
)
, docgru as  (
select a.doc_gruppo_tipo_id, a.doc_gruppo_tipo_code, a.doc_gruppo_tipo_desc
 from siac_d_doc_gruppo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null)
select doc1.*, docgru.* from doc1 left join docgru on
docgru.doc_gruppo_tipo_id = doc1.doc_gruppo_tipo_id
  )
  ,bollo as (
  select a.codbollo_id,a.codbollo_code, a.codbollo_desc from siac_d_codicebollo a
  where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null)
  ,sogg as (
  with sogg1 as (
  select distinct a.doc_id,b.soggetto_code,
  --d.soggetto_tipo_desc,
  f.soggetto_stato_desc,
  b.partita_iva, b.codice_fiscale, b.codice_fiscale_estero,
   b.soggetto_id
   from
  siac_r_doc_sog a, siac_t_soggetto b ,/*siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d,*/siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.soggetto_id=b.soggetto_id
 /* and c.soggetto_id=b.soggetto_id
  and d.soggetto_tipo_id=c.soggetto_tipo_id*/
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  /*and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)*/
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
/*  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL*/
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  --and b.soggetto_id=1862
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  ),
  sogg5 as (select
c.soggetto_id,d.soggetto_tipo_desc
 from siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d where c.ente_proprietario_id=p_ente_proprietario_id and
  d.soggetto_tipo_id=c.soggetto_tipo_id
  and c.data_cancellazione is null
  and d.data_cancellazione is NULL
  AND p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  )
  select sogg1.*, sogg2.ragione_sociale,sogg3.nome, sogg3.cognome, sogg5.soggetto_tipo_desc
  from sogg1 left join sogg2 on sogg1.soggetto_id=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id=sogg3.soggetto_id
  left join sogg5 on sogg1.soggetto_id=sogg5.soggetto_id
  )
  , reguni as (select a.doc_id,a.rudoc_registrazione_anno,
  a.rudoc_registrazione_numero,a.rudoc_registrazione_data
  from siac_t_registrounico_doc a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , cdr as (
  select a.doc_id, b.classif_code doc_cdr_cdr_code, b.classif_desc doc_cdr_cdr_desc ,
  null   doc_cdr_cdc_code, null  doc_cdr_cdc_desc
  from siac_r_doc_class a, siac_t_class b, siac_d_class_tipo c
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDR'
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  ),
  cdc as (
  select a.doc_id, b.classif_code doc_cdc_cdc_code, b.classif_desc doc_cdc_cdc_desc,
  d.classif_code doc_cdc_cdr_code, d.classif_desc doc_cdc_cdr_desc
  from siac_r_doc_class a, siac_t_class b, siac_d_class_tipo c, siac_t_class d,siac_r_class_fam_tree e
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDC'
  and b.classif_id=e.classif_id
  and d.classif_id=e.classif_id_padre
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL)
  ,pcccod as (select a.pcccod_id,a.pcccod_code,a.pcccod_desc from
  siac_d_pcc_codice  a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , pccuff as (
  select a.pccuff_id,a.pccuff_code,a.pccuff_desc from
  siac_d_pcc_ufficio  a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , attoamm as (
  with attoamm1 as (
  select
  b.attoamm_id,
  a.subdoc_id,  b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
  d.attoamm_stato_code, d.attoamm_stato_desc,
  e.attoamm_tipo_code, e.attoamm_tipo_desc
  from
  siac_r_subdoc_atto_amm a ,siac_t_atto_amm b ,siac_r_atto_amm_stato c ,siac_d_atto_amm_stato d,
  siac_d_atto_amm_tipo e
  where
  a.ente_proprietario_id=p_ente_proprietario_id and
  a.attoamm_id=b.attoamm_id and c.attoamm_id=b.attoamm_id
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and d.attoamm_stato_id=c.attoamm_stato_id
  and e.attoamm_tipo_id=b.attoamm_tipo_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.data_cancellazione is null
  ),
cdr as (
  select a.attoamm_id, b.classif_code attoamm_cdr_cdr_code, b.classif_desc attoamm_cdr_cdr_desc ,
  null::varchar  attoamm_cdr_cdc_code, null::varchar attoamm_cdr_cdc_desc
  from siac_r_atto_amm_class a, siac_t_class b, siac_d_class_tipo c
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDR'
  -- and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) -- SIAC-5494
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  ),
  cdc as (
  select a.attoamm_id, b.classif_code attoamm_cdc_cdc_code, b.classif_desc attoamm_cdc_cdc_desc,
  d.classif_code attoamm_cdc_cdr_code, d.classif_desc attoamm_cdc_cdr_desc
  from siac_r_atto_amm_class a, siac_t_class b, siac_d_class_tipo c, siac_t_class d,siac_r_class_fam_tree e
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDC'
  and b.classif_id=e.classif_id
  and d.classif_id=e.classif_id_padre
  -- and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data) -- SIAC-5494
  -- and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) -- SIAC-5494
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  )
  select   attoamm1.*,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdc_code::varchar else null::varchar end attoamm_cdc_code,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdc_desc::varchar else null::varchar end attoamm_cdc_desc,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdr_code::varchar else cdr.attoamm_cdr_cdr_code::varchar end attoamm_cdr_code,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdr_desc::varchar else cdr.attoamm_cdr_cdr_desc::varchar end attoamm_cdr_desc
  from attoamm1
  left join cdc on attoamm1.attoamm_id=cdc.attoamm_id
  left join cdr on attoamm1.attoamm_id=cdr.attoamm_id
  ),
  commt as (select a.comm_tipo_id,a.comm_tipo_code,a.comm_tipo_desc
   from siac_d_commissione_tipo a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  ,
  eldocattall as (
  with eldoc as (
  select a.subdoc_id,a.eldoc_id,
  b.eldoc_anno, b.eldoc_numero, b.eldoc_data_trasmissione, b.eldoc_tot_quoteentrate,
  b.eldoc_tot_quotespese, b.eldoc_tot_dapagare, b.eldoc_tot_daincassare,
  d.eldoc_stato_code, d.eldoc_stato_desc
   from
  siac_r_elenco_doc_subdoc a,siac_t_elenco_doc b, siac_r_elenco_doc_stato c,
  siac_d_elenco_doc_stato d
  where
  a.ente_proprietario_id=p_ente_proprietario_id and
  b.eldoc_id=a.eldoc_id
  and c.eldoc_id=b.eldoc_id
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and d.eldoc_stato_id=c.eldoc_stato_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  ),
  attoal as (with attoall as (
select distinct
  a.eldoc_id,b.attoal_id,
  b.attoal_causale, b.attoal_altriallegati, b.attoal_dati_sensibili,
         b.attoal_data_scadenza, b.attoal_note, b.attoal_annotazioni, b.attoal_pratica,
         b.attoal_responsabile_amm, b.attoal_responsabile_con, b.attoal_titolario_anno,
         b.attoal_titolario_numero, b.attoal_versione_invio_firma,
         d.attoal_stato_code, d.attoal_stato_desc,
         b.data_creazione data_ins_atto_allegato,   -- 15.05.2018 Sofia siac-6124
	     fnc_siac_attoal_getDataStato(b.attoal_id,'C') data_completa_atto_allegato, -- 22.05.2018 Sofia siac-6124
         fnc_siac_attoal_getDataStato(b.attoal_id,'CV') data_convalida_atto_allegato  -- 22.05.2018 Sofia siac-6124
   from
  siac_r_atto_allegato_elenco_doc a, siac_t_atto_allegato b,
  siac_r_atto_allegato_stato c ,siac_d_atto_allegato_stato d
  where a.ente_proprietario_id=p_ente_proprietario_id and
  a.attoal_id=b.attoal_id
  and c.attoal_id=b.attoal_id
  and d.attoal_stato_id=c.attoal_stato_id
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  ),
  soggattoall as (
  with sogg1 as (
  select distinct a.attoal_id,b.soggetto_code soggetto_code_atto_allegato,
  /*d.soggetto_tipo_desc soggetto_tipo_desc_atto_allegato, */
  f.soggetto_stato_desc soggetto_stato_desc_atto_allegato,
  b.partita_iva partita_iva_atto_allegato, b.codice_fiscale codice_fiscale_atto_allegato,
  b.codice_fiscale_estero codice_fiscale_estero_atto_allegato,
  b.soggetto_id soggetto_id_atto_allegato,
  -- 16.05.2018 Sofia siac-6124
  a.attoal_sog_data_sosp data_sosp_atto_allegato,
  a.attoal_sog_causale_sosp causale_sosp_atto_allegato,
  a.attoal_sog_data_riatt data_riattiva_atto_allegato
   from
  siac_r_atto_allegato_sog a, siac_t_soggetto b ,/*siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d,*/siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.soggetto_id=b.soggetto_id
  /*and c.soggetto_id=b.soggetto_id
  and d.soggetto_tipo_id=c.soggetto_tipo_id*/
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  /*and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)*/
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
/*  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL*/
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  --and b.soggetto_id=1862
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale  from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  ),
  sogg5 as (select
	c.soggetto_id,d.soggetto_tipo_desc
 from siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d where c.ente_proprietario_id=p_ente_proprietario_id and
  d.soggetto_tipo_id=c.soggetto_tipo_id
  and c.data_cancellazione is null
  and d.data_cancellazione is NULL
  AND p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  )
  select sogg1.*, sogg2.ragione_sociale ragione_sociale_atto_allegato,sogg3.nome nome_atto_allegato,
  sogg3.cognome cognome_atto_allegato, sogg5.soggetto_tipo_desc soggetto_tipo_desc_atto_allegato
  from sogg1 left join sogg2 on sogg1.soggetto_id_atto_allegato=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id_atto_allegato=sogg3.soggetto_id
  left join sogg5 on sogg1.soggetto_id_atto_allegato=sogg5.soggetto_id
  )
  select attoall.*,soggattoall.ragione_sociale_atto_allegato,soggattoall.nome_atto_allegato,
  soggattoall.cognome_atto_allegato,   soggattoall.soggetto_code_atto_allegato,
  soggattoall.soggetto_tipo_desc_atto_allegato,
  soggattoall.soggetto_stato_desc_atto_allegato,
  soggattoall.partita_iva_atto_allegato, soggattoall.codice_fiscale_atto_allegato,
  soggattoall.codice_fiscale_estero_atto_allegato,
  soggattoall.soggetto_id_atto_allegato ,
  -- 16.05.2018 Sofia siac-6124
  soggattoall.data_sosp_atto_allegato,
  soggattoall.causale_sosp_atto_allegato,
  soggattoall.data_riattiva_atto_allegato
  from attoall left join soggattoall
  on attoall.attoal_id=soggattoall.attoal_id
  )
  select distinct eldoc.*,
  attoal.attoal_id,
  attoal.attoal_causale, attoal.attoal_altriallegati, attoal.attoal_dati_sensibili,
         attoal.attoal_data_scadenza, attoal.attoal_note, attoal.attoal_annotazioni, attoal.attoal_pratica,
         attoal.attoal_responsabile_amm, attoal.attoal_responsabile_con, attoal.attoal_titolario_anno,
         attoal.attoal_titolario_numero, attoal.attoal_versione_invio_firma,
         attoal.attoal_stato_code, attoal.attoal_stato_desc,
   attoal.ragione_sociale_atto_allegato,attoal.nome_atto_allegato,attoal.cognome_atto_allegato,
   attoal.soggetto_code_atto_allegato,
  attoal.soggetto_tipo_desc_atto_allegato,
  attoal.soggetto_stato_desc_atto_allegato,
  attoal.partita_iva_atto_allegato, attoal.codice_fiscale_atto_allegato,
  attoal.codice_fiscale_estero_atto_allegato,
  attoal.soggetto_id_atto_allegato,
  -- 15.05.2018 Sofia siac-6124
  attoal.data_ins_atto_allegato,
  attoal.data_sosp_atto_allegato,
  attoal.causale_sosp_atto_allegato,
  attoal.data_riattiva_atto_allegato,
  attoal.data_completa_atto_allegato,
  attoal.data_convalida_atto_allegato
  from eldoc left join attoal
  on eldoc.eldoc_id=attoal.eldoc_id
  ),
  notes as (
  select a.notetes_id,a.notetes_desc from
  siac.siac_d_note_tesoriere a
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , dist as (
  select a.dist_id,a.dist_code, a.dist_desc from siac_d_distinta a
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , contes as (
  select a.contotes_id,a.contotes_desc from siac_d_contotesoreria  a
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null),
  split as (select
  a.subdoc_id,b.sriva_tipo_code , b.sriva_tipo_desc from  siac_r_subdoc_splitreverse_iva_tipo a,
  siac_d_splitreverse_iva_tipo b
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null
  and b.sriva_tipo_id=a.sriva_tipo_id
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  )
  , liq as (  select  a.subdoc_id,b.liq_anno,b.liq_numero ,d.liq_stato_desc
  from siac.siac_r_subdoc_liquidazione a ,siac_t_liquidazione b,siac_r_liquidazione_stato c ,
  siac_d_liquidazione_stato d
  where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and b.liq_id=a.liq_id
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and c.liq_id=b.liq_id
  and d.liq_stato_id=c.liq_stato_id
  --and d.liq_stato_code<>'A'
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
),
subcltipoavviso as (select a.subdoc_id,b.classif_code cod_tipo_avviso,b.classif_desc desc_tipo_avviso
 from siac_r_subdoc_class a, siac_t_class b,siac_d_class_tipo c
where a.ente_proprietario_id=p_ente_proprietario_id and b.classif_id=a.classif_id
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and c.classif_tipo_id=b.classif_tipo_id
and c.classif_tipo_code='TIPO_AVVISO'
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
),
docattr1 as (
SELECT distinct a.doc_id,
a.testo v_registro_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'registro_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr2 as (
SELECT distinct a.doc_id,
a.numerico v_anno_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'anno_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr3 as (
SELECT distinct a.doc_id,
a.testo v_num_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'num_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr4 as (
SELECT distinct a.doc_id,
a.testo v_data_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'data_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr5 as (
SELECT distinct a.doc_id,
a.testo v_data_ricezione_portale
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataRicezionePortale' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr6 as (
SELECT distinct a.doc_id,
a.testo v_dataOperazionePagamentoIncasso
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataOperazionePagamentoIncasso' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr7 as (
SELECT distinct a.doc_id,
a."boolean" v_flagPagataIncassata
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagPagataIncassata' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr8 as (
SELECT distinct a.doc_id,
a.testo v_notePagamentoIncasso
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'notePagamentoIncasso' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr9 as (
SELECT distinct a.doc_id,
a.numerico v_arrotondamento
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'arrotondamento' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)

,subdocattr1 as (
SELECT distinct a.subdoc_id,
a."boolean" v_rilevante_iva
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagRilevanteIVA' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr2 as (
SELECT a.subdoc_id, a.subdoc_attr_id,
a."boolean" v_ordinativo_singolo
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagOrdinativoSingolo' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)

,subdocattr3 as (
SELECT distinct a.subdoc_id,
a."boolean" v_esproprio
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagEsproprio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr4 as (
SELECT distinct a.subdoc_id,
a."boolean" v_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr5 as (
SELECT distinct a.subdoc_id,
a."boolean" v_ordinativo_manuale
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagOrdinativoManuale' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr6 as (
SELECT distinct a.subdoc_id,
a."boolean" v_avviso
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagAvviso' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr7 as (
SELECT distinct a.subdoc_id,
a.numerico v_num_mutuo
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'numeroMutuo' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr8 as (
SELECT distinct a.subdoc_id,
a.testo v_cup
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'cup' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr9 as (
SELECT distinct a.subdoc_id,
a.testo v_cig
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'cig' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr10 as (
SELECT distinct a.subdoc_id,
a.testo v_note_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'noteCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
/* JIRA 5764
,subdocattr11 as (
*/
/*SELECT distinct a.subdoc_id,
a.testo v_data_sospensione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'data_sospensione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)*/
/* JIRA 5764
select a.subdoc_id,to_char(a.subdoc_sosp_data,'dd/mm/yyyy') v_data_sospensione from
siac_t_subdoc_sospensione a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)*/
,subdocattr12 as (
SELECT distinct a.subdoc_id,
a.testo v_data_esecuzione_pagamento
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataEsecuzionePagamento' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr13 as (
SELECT distinct a.subdoc_id,
a.testo v_annotazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'annotazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr14 as (
SELECT distinct a.subdoc_id,
a.testo v_num_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'numeroCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr15 as (
SELECT distinct a.subdoc_id,
a.testo v_data_scadenza_dopo_sospensione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataScadenzaDopoSospensione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
/* JIRA 5764
,subdocattr16 as (
*/
/*SELECT distinct a.subdoc_id,
a.testo v_data_riattivazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'data_riattivazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)*/
/* JIRA 5764
select a.subdoc_id,to_char(a.subdoc_sosp_data_riattivazione,'dd/mm/yyyy')  v_data_riattivazione
from
siac_t_subdoc_sospensione a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
*/
,subdocattr17 as (
SELECT distinct a.subdoc_id,
a.testo v_causale_ordinativo
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'causaleOrdinativo' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr18 as (
SELECT distinct a.subdoc_id,
a.testo v_note
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'Note' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr19 as (
SELECT distinct a.subdoc_id,
a.testo v_data_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
/* JIRA 5764
,subdocattr20 as (*/
/*SELECT distinct a.subdoc_id,
a.testo v_causale_sospensione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'causale_sospensione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)*/
/* JIRA 5764
select
	    a.subdoc_id
		,to_char(a.subdoc_sosp_data,'dd/mm/yyyy') v_data_sospensione
		,to_char(a.subdoc_sosp_data_riattivazione,'dd/mm/yyyy')  v_data_riattivazione
        ,a.subdoc_sosp_causale v_causale_sospensione from
siac_t_subdoc_sospensione a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)*/
,soggsub as (
  with sogg1 as (
  select distinct a.subdoc_id,b.soggetto_code soggetto_code_subdoc,
  f.soggetto_stato_desc soggetto_stato_desc_subdoc,
  b.partita_iva partita_iva_subdoc, b.codice_fiscale codice_fiscale_subdoc,
  b.codice_fiscale_estero codice_fiscale_estero_subdoc,
   b.soggetto_id soggetto_id_subdoc
   from
  siac_r_subdoc_sog a, siac_t_soggetto b ,siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.soggetto_id=b.soggetto_id
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
    AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  --and b.soggetto_id=1862
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale ragione_sociale_subdoc  from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome nome_subdoc, h.cognome cognome_subdoc from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  ),
  sogg4 as (
  SELECT a.soggetto_id_da, a.soggetto_id_a
    FROM siac.siac_r_soggetto_relaz a, siac.siac_d_relaz_tipo b
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and
    a.relaz_tipo_id = b.relaz_tipo_id
    AND   b.relaz_tipo_code  = 'SEDE_SECONDARIA'
    AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
    AND   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
    AND   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL)
    ,
sogg5 as (select
c.soggetto_id,d.soggetto_tipo_desc soggetto_tipo_desc_subdoc
 from siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d where c.ente_proprietario_id=p_ente_proprietario_id and
  d.soggetto_tipo_id=c.soggetto_tipo_id
  and c.data_cancellazione is null
  and d.data_cancellazione is NULL
  AND p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  )
  select sogg1.*, sogg2.ragione_sociale_subdoc,sogg3.nome_subdoc, sogg3.cognome_subdoc,
  case when sogg4.soggetto_id_da is not null then 'S' else NULL::varchar end v_sede_secondaria_subdoc
  , sogg5.soggetto_tipo_desc_subdoc
  from sogg1 left join sogg2 on sogg1.soggetto_id_subdoc=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id_subdoc=sogg3.soggetto_id
  left join sogg4 on sogg1.soggetto_id_subdoc=sogg4.soggetto_id_a
  left join sogg5 on sogg1.soggetto_id_subdoc=sogg5.soggetto_id
  ),
  imp as (select distinct
  c.movgest_id,b.movgest_ts_id,
a.subdoc_id,
case when g.movgest_ts_tipo_code ='T' then b.movgest_ts_code else NULL::varchar end v_cod_impegno,
case when g.movgest_ts_tipo_code ='T' then c.movgest_desc else NULL::varchar end v_desc_impegno,
case when g.movgest_ts_tipo_code ='S' then b.movgest_ts_code else NULL::varchar end v_cod_subimpegno,
case when g.movgest_ts_tipo_code ='S' then b.movgest_ts_desc else NULL::varchar end v_desc_subimpegno,
e.anno v_bil_anno,
c.movgest_anno v_anno_impegno,
c.movgest_numero v_num_impegno,
g.movgest_ts_tipo_code
from
siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, siac_t_movgest c, siac_t_bil d,
siac_t_periodo e, siac_d_movgest_tipo f, siac_d_movgest_ts_tipo g
where b.movgest_ts_id=A.movgest_ts_id
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and c.movgest_id=b.movgest_id
and d.bil_id=c.bil_id
and e.periodo_id=d.periodo_id
and f.movgest_tipo_id=c.movgest_tipo_id
and g.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and f.movgest_tipo_code = 'I'
and a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null),
modpag as (
with modpag0 as (
with modpag1 as (
SELECT
a.subdoc_id,b.quietanziante, b.quietanzante_nascita_data, b.quietanziante_nascita_luogo, b.quietanziante_nascita_stato,
b.bic, b.contocorrente ,b.contocorrente_intestazione,b.iban , b.note , b.data_scadenza,b.accredito_tipo_id,
 b.soggetto_id,a.soggrelmpag_id, b.modpag_id
FROM siac.siac_r_subdoc_modpag a, siac.siac_t_modpag b where
a.ente_proprietario_id=p_ente_proprietario_id and
b.modpag_id = a.modpag_id
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is NULL
and b.data_cancellazione is NULL
)
,actipo as (
select a.accredito_tipo_id,
a.accredito_tipo_code ,
a.accredito_tipo_desc
 from siac.siac_d_accredito_tipo a where a.ente_proprietario_id=p_ente_proprietario_id and
a.data_cancellazione is NULL),
relmodpag as ( SELECT
 a.soggrelmpag_id,
b.soggetto_id_a v_soggetto_id_modpag_cess
 FROM  siac.siac_r_soggrel_modpag a, siac.siac_r_soggetto_relaz b
 WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.soggetto_relaz_id = b.soggetto_relaz_id
 AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
 AND   a.data_cancellazione IS NULL
 AND   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
 AND   b.data_cancellazione IS NULL
 )
 select
modpag1.subdoc_id,
modpag1.quietanziante v_quietanziante,
modpag1.quietanzante_nascita_data v_data_nasciata_quietanziante,
modpag1.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
modpag1.quietanziante_nascita_stato v_stato_nascita_quietanziante,
modpag1.bic v_bic, modpag1.contocorrente v_contocorrente,
modpag1.contocorrente_intestazione v_intestazione_contocorrente,
modpag1.iban v_iban, modpag1.note v_note_mod_pag, modpag1.data_scadenza v_data_scadenza_mod_pag,
modpag1.accredito_tipo_id,
 modpag1.soggetto_id v_soggetto_id_modpag_nocess,
modpag1.soggrelmpag_id v_soggrelmpag_id, modpag1.modpag_id v_mod_pag_id,
actipo.accredito_tipo_code v_cod_tipo_accredito,
actipo.accredito_tipo_desc v_desc_tipo_accredito,
case when modpag1.soggrelmpag_id IS NULL THEN modpag1.soggetto_id else relmodpag.v_soggetto_id_modpag_cess
 end v_soggetto_id_modpag
 from modpag1 left join actipo
on modpag1.accredito_tipo_id=actipo.accredito_tipo_id
left join relmodpag on relmodpag.soggrelmpag_id=modpag1.soggrelmpag_id
)
,
 soggmodpag as (
  with sogg1 as (
  select distinct b.soggetto_code, d.soggetto_tipo_desc, f.soggetto_stato_desc,
  b.partita_iva, b.codice_fiscale, b.codice_fiscale_estero,
   b.soggetto_id
   from
  siac_t_soggetto b ,siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d,siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  b.ente_proprietario_id=p_ente_proprietario_id
  and c.soggetto_id=b.soggetto_id
  and d.soggetto_tipo_id=c.soggetto_tipo_id
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  --and b.soggetto_id=1862
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  )
  select sogg1.*, sogg2.ragione_sociale,sogg3.nome, sogg3.cognome
  from sogg1 left join sogg2 on sogg1.soggetto_id=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id=sogg3.soggetto_id
  )
select modpag0.*,soggmodpag.soggetto_code v_cod_sogg_mod_pag, soggmodpag.soggetto_tipo_desc v_tipo_sogg_mod_pag,
soggmodpag.soggetto_stato_desc v_stato_sogg_mod_pag, soggmodpag.ragione_sociale v_rag_sociale_sogg_mod_pag,
soggmodpag.partita_iva v_p_iva_sogg_mod_pag, soggmodpag.codice_fiscale v_cf_sogg_mod_pag,
soggmodpag.codice_fiscale_estero v_cf_estero_sogg_mod_pag,
soggmodpag.nome v_nome_sogg_mod_pag, soggmodpag.cognome v_cognome_sogg_mod_pag
 from modpag0
left join soggmodpag on soggmodpag.soggetto_id=modpag0.v_soggetto_id_modpag
),
ord as (
SELECT
a.subdoc_id,
c.ord_anno, c.ord_numero, b.ord_ts_code, g.anno
    FROM  siac_r_subdoc_ordinativo_ts a, siac_t_ordinativo_ts b, siac_t_ordinativo c,
          siac_r_ordinativo_stato d, siac_d_ordinativo_stato e,
          siac.siac_t_bil f, siac.siac_t_periodo g
    WHERE b.ord_ts_id = a.ord_ts_id
    AND   c.ord_id = b.ord_id
    AND   d.ord_id = c.ord_id
    AND   d.ord_stato_id = e.ord_stato_id
    AND   c.bil_id = f.bil_id
    AND   g.periodo_id = f.periodo_id
    AND   e.ord_stato_code <> 'A'
    AND   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL
    AND   c.data_cancellazione IS NULL
    AND   d.data_cancellazione IS NULL
    AND   e.data_cancellazione IS NULL
    AND   f.data_cancellazione IS NULL
    AND   g.data_cancellazione IS NULL
    AND   p_data between a.validita_inizio and COALESCE(a.validita_fine,p_data)
    AND   p_data between d.validita_inizio and COALESCE(d.validita_fine,p_data)
    )
  select doc.ente_proprietario_id v_ente_proprietario_id,
  doc.ente_denominazione v_ente_denominazione,
  doc.subdoc_id,
  doc.doc_anno v_anno_doc, doc.doc_numero v_num_doc,
  doc.doc_desc v_desc_doc,
  doc.doc_importo v_importo_doc,
  doc.doc_beneficiariomult v_beneficiario_multiplo_doc,
  doc.doc_data_emissione v_data_emissione_doc,
  doc.doc_data_scadenza v_data_scadenza_doc,
  bollo.codbollo_code v_codice_bollo_doc, bollo.codbollo_desc v_desc_codice_bollo_doc,
 doc.doc_collegato_cec v_collegato_cec_doc,
  pcccod.pcccod_code v_cod_pcc_doc,pcccod.pcccod_desc v_desc_pcc_doc
  ,pccuff.pccuff_code v_cod_ufficio_doc,pccuff.pccuff_desc v_desc_ufficio_doc,
  doc.doc_stato_code v_cod_stato_doc, doc.doc_stato_desc v_desc_stato_doc,
   doc.doc_fam_tipo_code v_cod_famiglia_doc, doc.doc_fam_tipo_desc v_desc_famiglia_doc,
doc.doc_tipo_code v_cod_tipo_doc, doc.doc_tipo_desc v_desc_tipo_doc,
doc.subdoc_numero v_num_subdoc, doc.subdoc_desc v_desc_subdoc,doc.subdoc_importo v_importo_subdoc,
doc.subdoc_nreg_iva v_num_reg_iva_subdoc, doc.subdoc_data_scadenza v_data_scadenza_subdoc,
doc.subdoc_convalida_manuale v_convalida_manuale_subdoc, doc.subdoc_importo_da_dedurre v_importo_da_dedurre_subdoc,
doc.subdoc_splitreverse_importo v_splitreverse_importo_subdoc,
doc.subdoc_pagato_cec v_pagato_cec_subdoc,
doc.subdoc_data_pagamento_cec v_data_pagamento_cec_subdoc,
doc.doc_contabilizza_genpcc v_doc_contabilizza_genpcc,
sogg.soggetto_id v_sogg_id_doc,sogg.soggetto_code v_cod_sogg_doc, sogg.soggetto_tipo_desc v_tipo_sogg_doc,
sogg.soggetto_stato_desc v_stato_sogg_doc,sogg.ragione_sociale v_rag_sociale_sogg_doc,
sogg.partita_iva v_p_iva_sogg_doc,
sogg.codice_fiscale v_cf_sogg_doc,
sogg.codice_fiscale_estero v_cf_estero_sogg_doc,
sogg.nome v_nome_sogg_doc, sogg.cognome v_cognome_sogg_doc,
reguni.rudoc_registrazione_anno,reguni.rudoc_registrazione_numero,reguni.rudoc_registrazione_data,
case when cdr.doc_cdr_cdr_code is not null then null::varchar else cdc.doc_cdc_cdc_code::varchar end cdc_code,
case when cdr.doc_cdr_cdr_code is not null then null::varchar else cdc.doc_cdc_cdc_desc::varchar end cdc_desc,
case when cdr.doc_cdr_cdr_code is not null then cdr.doc_cdr_cdr_code::varchar else cdc.doc_cdc_cdr_code::varchar end cdr_code,
-- 13.06.2018 SIAC-6246
-- case when cdr.doc_cdr_cdr_code is not null then cdc.doc_cdc_cdr_code::varchar else cdc.doc_cdc_cdr_desc::varchar end cdr_desc,
-- 13.06.2018 SIAC-6246
case when cdr.doc_cdr_cdr_code is not null then cdr.doc_cdr_cdr_desc::varchar else cdc.doc_cdc_cdr_desc::varchar end cdr_desc,
attoamm.attoamm_anno v_anno_atto_amministrativo, attoamm.attoamm_numero v_num_atto_amministrativo,
attoamm.attoamm_oggetto v_oggetto_atto_amministrativo, attoamm.attoamm_note v_note_atto_amministrativo,
attoamm.attoamm_stato_code v_cod_stato_atto_amministrativo, attoamm.attoamm_stato_desc v_desc_stato_atto_amministrativo,
attoamm.attoamm_tipo_code v_cod_tipo_atto_amministrativo, attoamm.attoamm_tipo_desc v_desc_tipo_atto_amministrativo,
attoamm.attoamm_cdc_code v_cod_cdc_atto_amministrativo,attoamm.attoamm_cdc_desc v_desc_cdc_atto_amministrativo,
attoamm.attoamm_cdr_code v_cod_cdr_atto_amministrativo,attoamm.attoamm_cdr_desc v_desc_cdr_atto_amministrativo,
commt.comm_tipo_code,commt.comm_tipo_desc v_tipo_commissione_subdoc,
eldocattall.subdoc_id,eldocattall.eldoc_id,
eldocattall.eldoc_anno v_anno_elenco_doc,
eldocattall.eldoc_numero v_num_elenco_doc,
eldocattall.eldoc_data_trasmissione v_data_trasmissione_elenco_doc,
eldocattall.eldoc_tot_quoteentrate v_tot_quote_entrate_elenco_doc,
eldocattall.eldoc_tot_quotespese v_tot_quote_spese_elenco_doc,
eldocattall.eldoc_tot_dapagare v_tot_da_pagare_elenco_doc,
eldocattall.eldoc_tot_daincassare v_tot_da_incassare_elenco_doc,
eldocattall.eldoc_stato_code v_cod_stato_elenco_doc,
eldocattall.eldoc_stato_desc v_desc_stato_elenco_doc,
eldocattall.attoal_id,
eldocattall.attoal_causale v_causale_atto_allegato,
eldocattall.attoal_altriallegati v_altri_allegati_atto_allegato, eldocattall.attoal_dati_sensibili v_dati_sensibili_atto_allegato,
eldocattall.attoal_data_scadenza v_data_scadenza_atto_allegato, eldocattall.attoal_note v_note_atto_allegato,
eldocattall.attoal_annotazioni v_annotazioni_atto_allegato, eldocattall.attoal_pratica v_pratica_atto_allegato,
eldocattall.attoal_responsabile_amm v_resp_amm_atto_allegato, eldocattall.attoal_responsabile_con v_resp_contabile_atto_allegato,
eldocattall.attoal_titolario_anno v_anno_titolario_atto_allegato,
eldocattall.attoal_titolario_numero v_num_titolario_atto_allegato, eldocattall.attoal_versione_invio_firma v_vers_invio_firma_atto_allegato,
eldocattall.attoal_stato_code v_cod_stato_atto_allegato, eldocattall.attoal_stato_desc v_desc_stato_atto_allegato,
eldocattall.ragione_sociale_atto_allegato v_rag_sociale_sogg_atto_allegato,
eldocattall.nome_atto_allegato v_nome_sogg_atto_allegato,
eldocattall.cognome_atto_allegato v_cognome_sogg_atto_allegato,
eldocattall.soggetto_code_atto_allegato v_cod_sogg_atto_allegato,
eldocattall.soggetto_tipo_desc_atto_allegato v_tipo_sogg_atto_allegato,
eldocattall.soggetto_stato_desc_atto_allegato v_stato_sogg_atto_allegato,
eldocattall.partita_iva_atto_allegato v_p_iva_sogg_atto_allegato,
eldocattall.codice_fiscale_atto_allegato v_cf_sogg_atto_allegato,
eldocattall.codice_fiscale_estero_atto_allegato v_cf_estero_sogg_atto_allegato,
eldocattall.soggetto_id_atto_allegato v_sogg_id_atto_allegato,
doc.doc_gruppo_tipo_code v_cod_gruppo_doc, doc.doc_gruppo_tipo_desc v_desc_gruppo_doc,
notes.notetes_desc v_note_tesoriere_subdoc,
dist.dist_code v_cod_distinta_subdoc, dist.dist_desc v_desc_distinta_subdoc,
contes.contotes_desc v_conto_tesoreria_subdoc,
split.sriva_tipo_code v_cod_tipo_splitrev , split.sriva_tipo_desc v_desc_tipo_splitrev,
liq.liq_anno v_anno_liquidazione,liq.liq_numero v_num_liquidazione,liq.liq_stato_desc v_liq_stato_desc,
subcltipoavviso.cod_tipo_avviso v_cod_tipo_avviso,subcltipoavviso.desc_tipo_avviso v_desc_tipo_avviso,
docattr1.v_registro_repertorio,
docattr2.v_anno_repertorio,
docattr3.v_num_repertorio,
docattr4.v_data_repertorio,
docattr5.v_data_ricezione_portale,
docattr6.v_dataOperazionePagamentoIncasso,
docattr7.v_flagPagataIncassata,
docattr8.v_notePagamentoIncasso,
-- 	SIAC-5229
docattr9.v_arrotondamento,
--
subdocattr1.v_rilevante_iva,
subdocattr2.v_ordinativo_singolo,
subdocattr3.v_esproprio,
subdocattr4.v_certificazione,
subdocattr5.v_ordinativo_manuale,
subdocattr6.v_avviso,
subdocattr7.v_num_mutuo,
subdocattr8.v_cup,
subdocattr9.v_cig,
subdocattr10.v_note_certificazione,
null::varchar v_data_sospensione, --subdocattr20.v_data_sospensione,--subdocattr11.v_data_sospensione, JIRA 5764
subdocattr12.v_data_esecuzione_pagamento,
subdocattr13.v_annotazione,
subdocattr14.v_num_certificazione,
subdocattr15.v_data_scadenza_dopo_sospensione,
null::varchar v_data_riattivazione,--subdocattr20.v_data_riattivazione,--subdocattr16.v_data_riattivazione, JIRA 5764
subdocattr17.v_causale_ordinativo,
subdocattr18.v_note,
subdocattr19.v_data_certificazione,
null::varchar v_causale_sospensione, --subdocattr20.v_causale_sospensione,JIRA 5764
soggsub.soggetto_code_subdoc v_cod_sogg_subdoc,
soggsub.soggetto_tipo_desc_subdoc v_tipo_sogg_subdoc,
soggsub.soggetto_stato_desc_subdoc v_stato_sogg_subdoc,
soggsub.partita_iva_subdoc v_p_iva_sogg_subdoc,
soggsub.codice_fiscale_subdoc v_cf_sogg_subdoc,
soggsub.codice_fiscale_estero_subdoc v_cf_estero_sogg_subdoc,
soggsub.soggetto_id_subdoc v_soggetto_id,
soggsub.nome_subdoc v_nome_sogg_subdoc,
soggsub.cognome_subdoc v_cognome_sogg_subdoc, soggsub.ragione_sociale_subdoc v_rag_sociale_sogg_subdoc,
soggsub.v_sede_secondaria_subdoc v_sede_secondaria_subdoc,
imp.v_cod_impegno v_cod_impegno,
imp.v_desc_impegno v_desc_impegno,
imp.v_cod_subimpegno v_cod_subimpegno,
imp.v_desc_subimpegno v_desc_subimpegno,
imp.v_bil_anno v_bil_anno,
imp.v_anno_impegno v_anno_impegno,
imp.v_num_impegno v_num_impegno,
imp.movgest_ts_tipo_code,
modpag.v_quietanziante v_quietanziante,
modpag.v_data_nasciata_quietanziante,
modpag.v_luogo_nascita_quietanziante,
modpag.v_stato_nascita_quietanziante,
modpag.v_bic, modpag.v_contocorrente,
modpag.v_intestazione_contocorrente,
modpag.v_iban, modpag.v_note_mod_pag, modpag.v_data_scadenza_mod_pag,
modpag.accredito_tipo_id,
modpag.v_soggetto_id_modpag_nocess,
modpag.v_soggrelmpag_id, modpag.v_mod_pag_id,
modpag.v_cod_tipo_accredito v_cod_tipo_accredito,
modpag.v_desc_tipo_accredito v_desc_tipo_accredito,
modpag.v_soggetto_id_modpag,
modpag.v_cod_sogg_mod_pag, modpag.v_tipo_sogg_mod_pag,
modpag.v_stato_sogg_mod_pag, modpag.v_rag_sociale_sogg_mod_pag,
modpag.v_p_iva_sogg_mod_pag, modpag.v_cf_sogg_mod_pag,
modpag.v_cf_estero_sogg_mod_pag,
modpag.v_nome_sogg_mod_pag, modpag.v_cognome_sogg_mod_pag,
ord.subdoc_id,
ord.ord_anno v_anno_ord, ord.ord_numero v_num_ord, ord.ord_ts_code v_num_subord, ord.anno v_bil_anno_ord,
doc.doc_sdi_lotto_siope,
doc.siope_documento_tipo_code, doc.siope_documento_tipo_desc, doc.siope_documento_tipo_desc_bnkit,
doc.siope_documento_tipo_analogico_code, doc.siope_documento_tipo_analogico_desc, doc.siope_documento_tipo_analogico_desc_bnkit,
doc.siope_tipo_debito_code, doc.siope_tipo_debito_desc, doc.siope_tipo_debito_desc_bnkit,
doc.siope_assenza_motivazione_code, doc.siope_assenza_motivazione_desc, doc.siope_assenza_motivazione_desc_bnkit,
doc.siope_scadenza_motivo_code, doc.siope_scadenza_motivo_desc, doc.siope_scadenza_motivo_desc_bnkit,
doc.doc_id, -- SIAC-5573,
-- 15.05.2018 Sofia siac-6124
eldocattall.data_ins_atto_allegato,
eldocattall.data_sosp_atto_allegato,
eldocattall.causale_sosp_atto_allegato,
eldocattall.data_riattiva_atto_allegato,
eldocattall.data_completa_atto_allegato,
eldocattall.data_convalida_atto_allegato
from doc
left join bollo on doc.codbollo_id=bollo.codbollo_id
left join sogg on doc.doc_id=sogg.doc_id
left join reguni on doc.doc_id=reguni.doc_id
left join cdc on doc.doc_id=cdc.doc_id
left join cdr on doc.doc_id=cdr.doc_id
left join pcccod on doc.pcccod_id=pcccod.pcccod_id
left join pccuff on doc.pccuff_id=pccuff.pccuff_id
left join attoamm on doc.subdoc_id=attoamm.subdoc_id
left join commt on doc.comm_tipo_id=commt.comm_tipo_id
left join eldocattall on doc.subdoc_id=eldocattall.subdoc_id
left join notes on doc.notetes_id=notes.notetes_id
left join dist  on doc.dist_id=dist.dist_id
left join contes on doc.contotes_id=contes.contotes_id
left join split on doc.subdoc_id=split.subdoc_id
left join liq on doc.subdoc_id=liq.subdoc_id --origina multipli
left join  subcltipoavviso on doc.subdoc_id=subcltipoavviso.subdoc_id
left join docattr1 on doc.doc_id=docattr1.doc_id
left join docattr2 on doc.doc_id=docattr2.doc_id
left join docattr3 on doc.doc_id=docattr3.doc_id
left join docattr4 on doc.doc_id=docattr4.doc_id
left join docattr5 on doc.doc_id=docattr5.doc_id
left join docattr6 on doc.doc_id=docattr6.doc_id
left join docattr7 on doc.doc_id=docattr7.doc_id
left join docattr8 on doc.doc_id=docattr8.doc_id
left join docattr9 on doc.doc_id=docattr9.doc_id
left join subdocattr1 on doc.subdoc_id=subdocattr1.subdoc_id
left join subdocattr2 on doc.subdoc_id=subdocattr2.subdoc_id
left join subdocattr3 on doc.subdoc_id=subdocattr3.subdoc_id
left join subdocattr4 on doc.subdoc_id=subdocattr4.subdoc_id
left join subdocattr5 on doc.subdoc_id=subdocattr5.subdoc_id
left join subdocattr6 on doc.subdoc_id=subdocattr6.subdoc_id
left join subdocattr7 on doc.subdoc_id=subdocattr7.subdoc_id
left join subdocattr8 on doc.subdoc_id=subdocattr8.subdoc_id
left join subdocattr9 on doc.subdoc_id=subdocattr9.subdoc_id
left join subdocattr10 on doc.subdoc_id=subdocattr10.subdoc_id
--left join subdocattr11 on doc.subdoc_id=subdocattr11.subdoc_id
left join subdocattr12 on doc.subdoc_id=subdocattr12.subdoc_id
left join subdocattr13 on doc.subdoc_id=subdocattr13.subdoc_id
left join subdocattr14 on doc.subdoc_id=subdocattr14.subdoc_id
left join subdocattr15 on doc.subdoc_id=subdocattr15.subdoc_id
--left join subdocattr16 on doc.subdoc_id=subdocattr16.subdoc_id
left join subdocattr17 on doc.subdoc_id=subdocattr17.subdoc_id
left join subdocattr18 on doc.subdoc_id=subdocattr18.subdoc_id
left join subdocattr19 on doc.subdoc_id=subdocattr19.subdoc_id
--left join subdocattr20 on doc.subdoc_id=subdocattr20.subdoc_id jira 5764
left join soggsub on soggsub.subdoc_id = doc.subdoc_id
left join imp on imp.subdoc_id=doc.subdoc_id
left join modpag on modpag.subdoc_id=doc.subdoc_id
left join ord on ord.subdoc_id = doc.subdoc_id
) as tb;


esito:= 'In funzione carico documenti spesa (FNC_SIAC_DWH_DOCUMENTO_SPESA) - fine dati variabili - '||clock_timestamp();
RETURN NEXT;

-- 20.01.2021 Sofia jira SIAC-7967
update siac_dwh_log_elaborazioni   log
set    fnc_elaborazione_fine = clock_timestamp(),
       fnc_durata=clock_timestamp()-log.fnc_elaborazione_inizio,
       fnc_parameters=log.fnc_parameters||' - '||esito
where fnc_user=v_user_table;
/*update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;*/

-- 26.01.2021 Sofia JIRA siac-7518
select 1 into caricaDatiStorico
from siac_d_gestione_livello liv,siac_d_gestione_tipo tipo
where tipo.ente_proprietario_id=p_ente_proprietario_id
and   tipo.gestione_tipo_code='CARICA_STORICO_DWH_DOC_SPESA_ATTIVO'
and   liv.gestione_tipo_id=tipo.gestione_tipo_id
and   tipo.data_cancellazione is null
and   liv.data_cancellazione  is null;

-- 26.01.2021 Sofia Jira SIAC-7518
if caricaDatiStorico is not null then

  -- 20.01.2021 Sofia jira SIAC-7967 - inizio
  INSERT INTO siac.siac_dwh_documento_spesa
  (
    ente_proprietario_id,
    ente_denominazione,
    anno_atto_amministrativo,
    num_atto_amministrativo,
    oggetto_atto_amministrativo,
    cod_tipo_atto_amministrativo,
    desc_tipo_atto_amministrativo,
    cod_cdr_atto_amministrativo,
    desc_cdr_atto_amministrativo,
    cod_cdc_atto_amministrativo,
    desc_cdc_atto_amministrativo,
    note_atto_amministrativo,
    cod_stato_atto_amministrativo,
    desc_stato_atto_amministrativo,
    causale_atto_allegato,
    altri_allegati_atto_allegato,
    dati_sensibili_atto_allegato,
    data_scadenza_atto_allegato,
    note_atto_allegato,
    annotazioni_atto_allegato,
    pratica_atto_allegato,
    resp_amm_atto_allegato,
    resp_contabile_atto_allegato,
    anno_titolario_atto_allegato,
    num_titolario_atto_allegato,
    vers_invio_firma_atto_allegato,
    cod_stato_atto_allegato,
    desc_stato_atto_allegato,
    sogg_id_atto_allegato,
    cod_sogg_atto_allegato,
    tipo_sogg_atto_allegato,
    stato_sogg_atto_allegato,
    rag_sociale_sogg_atto_allegato,
    p_iva_sogg_atto_allegato,
    cf_sogg_atto_allegato,
    cf_estero_sogg_atto_allegato,
    nome_sogg_atto_allegato,
    cognome_sogg_atto_allegato,
    anno_doc,
    num_doc,
    desc_doc,
    importo_doc,
    beneficiario_multiplo_doc,
    data_emissione_doc,
    data_scadenza_doc,
    codice_bollo_doc,
    desc_codice_bollo_doc,
    collegato_cec_doc,
    cod_pcc_doc,
    desc_pcc_doc,
    cod_ufficio_doc,
    desc_ufficio_doc,
    cod_stato_doc,
    desc_stato_doc,
    anno_elenco_doc,
    num_elenco_doc,
    data_trasmissione_elenco_doc,
    tot_quote_entrate_elenco_doc,
    tot_quote_spese_elenco_doc,
    tot_da_pagare_elenco_doc,
    tot_da_incassare_elenco_doc,
    cod_stato_elenco_doc,
    desc_stato_elenco_doc,
    cod_gruppo_doc,
    desc_famiglia_doc,
    cod_famiglia_doc,
    desc_gruppo_doc,
    cod_tipo_doc,
    desc_tipo_doc,
    sogg_id_doc,
    cod_sogg_doc,
    tipo_sogg_doc,
    stato_sogg_doc,
    rag_sociale_sogg_doc,
    p_iva_sogg_doc,
    cf_sogg_doc,
    cf_estero_sogg_doc,
    nome_sogg_doc,
    cognome_sogg_doc,
    num_subdoc,
    desc_subdoc,
    importo_subdoc,
    num_reg_iva_subdoc,
    data_scadenza_subdoc,
    convalida_manuale_subdoc,
    importo_da_dedurre_subdoc,
    splitreverse_importo_subdoc,
    pagato_cec_subdoc,
    data_pagamento_cec_subdoc,
    note_tesoriere_subdoc,
    cod_distinta_subdoc,
    desc_distinta_subdoc,
    tipo_commissione_subdoc,
    conto_tesoreria_subdoc,
    rilevante_iva,
    ordinativo_singolo,
    ordinativo_manuale,
    esproprio,
    note,
    cig,
    cup,
    causale_sospensione,
    data_sospensione,
    data_riattivazione,
    causale_ordinativo,
    num_mutuo,
    annotazione,
    certificazione,
    data_certificazione,
    note_certificazione,
    num_certificazione,
    data_scadenza_dopo_sospensione,
    data_esecuzione_pagamento,
    avviso,
    cod_tipo_avviso,
    desc_tipo_avviso,
    sogg_id_subdoc,
    cod_sogg_subdoc,
    tipo_sogg_subdoc,
    stato_sogg_subdoc,
    rag_sociale_sogg_subdoc,
    p_iva_sogg_subdoc,
    cf_sogg_subdoc,
    cf_estero_sogg_subdoc,
    nome_sogg_subdoc,
    cognome_sogg_subdoc,
    sede_secondaria_subdoc,
    bil_anno,
    anno_impegno,
    num_impegno,
    cod_impegno,
    desc_impegno,
    cod_subimpegno,
    desc_subimpegno,
    num_liquidazione,
    cod_tipo_accredito,
    desc_tipo_accredito,
    mod_pag_id,
    quietanziante,
    data_nascita_quietanziante,
    luogo_nascita_quietanziante,
    stato_nascita_quietanziante,
    bic,
    contocorrente,
    intestazione_contocorrente,
    iban,
    note_mod_pag,
    data_scadenza_mod_pag,
    sogg_id_mod_pag,
    cod_sogg_mod_pag,
    tipo_sogg_mod_pag,
    stato_sogg_mod_pag,
    rag_sociale_sogg_mod_pag,
    p_iva_sogg_mod_pag,
    cf_sogg_mod_pag,
    cf_estero_sogg_mod_pag,
    nome_sogg_mod_pag,
    cognome_sogg_mod_pag,
    anno_liquidazione,
    bil_anno_ord,
    anno_ord,
    num_ord,
    num_subord,
    registro_repertorio,
    anno_repertorio,
    num_repertorio,
    data_repertorio,
    data_ricezione_portale,
    doc_contabilizza_genpcc,
    rudoc_registrazione_anno,
    rudoc_registrazione_numero,
    rudoc_registrazione_data,
    cod_cdc_doc,
    desc_cdc_doc,
    cod_cdr_doc,
    desc_cdr_doc,
    data_operazione_pagamentoincasso,
    pagataincassata,
    note_pagamentoincasso,
    arrotondamento,
    cod_tipo_splitrev,
    desc_tipo_splitrev,
    stato_liquidazione,
    sdi_lotto_siope_doc,
    cod_siope_tipo_doc,
    desc_siope_tipo_doc,
    desc_siope_tipo_bnkit_doc,
    cod_siope_tipo_analogico_doc,
    desc_siope_tipo_analogico_doc,
    desc_siope_tipo_ana_bnkit_doc,
    cod_siope_tipo_debito_subdoc,
    desc_siope_tipo_debito_subdoc,
    desc_siope_tipo_deb_bnkit_sub,
    cod_siope_ass_motiv_subdoc,
    desc_siope_ass_motiv_subdoc,
    desc_siope_ass_motiv_bnkit_sub,
    cod_siope_scad_motiv_subdoc,
    desc_siope_scad_motiv_subdoc,
    desc_siope_scad_moti_bnkit_sub,
    doc_id,
    data_ins_atto_allegato,
    data_sosp_atto_allegato,
    causale_sosp_atto_allegato,
    data_riattiva_atto_allegato,
    data_completa_atto_allegato,
    data_convalida_atto_allegato
    )
  select
    dw.ente_proprietario_id,
    dw.ente_denominazione,
    dw.anno_atto_amministrativo,
    dw.num_atto_amministrativo,
    dw.oggetto_atto_amministrativo,
    dw.cod_tipo_atto_amministrativo,
    dw.desc_tipo_atto_amministrativo,
    dw.cod_cdr_atto_amministrativo,
    dw.desc_cdr_atto_amministrativo,
    dw.cod_cdc_atto_amministrativo,
    dw.desc_cdc_atto_amministrativo,
    dw.note_atto_amministrativo,
    dw.cod_stato_atto_amministrativo,
    dw.desc_stato_atto_amministrativo,
    dw.causale_atto_allegato,
    dw.altri_allegati_atto_allegato,
    dw.dati_sensibili_atto_allegato,
    dw.data_scadenza_atto_allegato,
    dw.note_atto_allegato,
    dw.annotazioni_atto_allegato,
    dw.pratica_atto_allegato,
    dw.resp_amm_atto_allegato,
    dw.resp_contabile_atto_allegato,
    dw.anno_titolario_atto_allegato,
    dw.num_titolario_atto_allegato,
    dw.vers_invio_firma_atto_allegato,
    dw.cod_stato_atto_allegato,
    dw.desc_stato_atto_allegato,
    dw.sogg_id_atto_allegato,
    dw.cod_sogg_atto_allegato,
    dw.tipo_sogg_atto_allegato,
    dw.stato_sogg_atto_allegato,
    dw.rag_sociale_sogg_atto_allegato,
    dw.p_iva_sogg_atto_allegato,
    dw.cf_sogg_atto_allegato,
    dw.cf_estero_sogg_atto_allegato,
    dw.nome_sogg_atto_allegato,
    dw.cognome_sogg_atto_allegato,
    dw.anno_doc,
    dw.num_doc,
    dw.desc_doc,
    dw.importo_doc,
    dw.beneficiario_multiplo_doc,
    dw.data_emissione_doc,
    dw.data_scadenza_doc,
    dw.codice_bollo_doc,
    dw.desc_codice_bollo_doc,
    dw.collegato_cec_doc,
    dw.cod_pcc_doc,
    dw.desc_pcc_doc,
    dw.cod_ufficio_doc,
    dw.desc_ufficio_doc,
    dw.cod_stato_doc,
    dw.desc_stato_doc,
    dw.anno_elenco_doc,
    dw.num_elenco_doc,
    dw.data_trasmissione_elenco_doc,
    dw.tot_quote_entrate_elenco_doc,
    dw.tot_quote_spese_elenco_doc,
    dw.tot_da_pagare_elenco_doc,
    dw.tot_da_incassare_elenco_doc,
    dw.cod_stato_elenco_doc,
    dw.desc_stato_elenco_doc,
    dw.cod_gruppo_doc,
    dw.desc_famiglia_doc,
    dw.cod_famiglia_doc,
    dw.desc_gruppo_doc,
    dw.cod_tipo_doc,
    dw.desc_tipo_doc,
    dw.sogg_id_doc,
    dw.cod_sogg_doc,
    dw.tipo_sogg_doc,
    dw.stato_sogg_doc,
    dw.rag_sociale_sogg_doc,
    dw.p_iva_sogg_doc,
    dw.cf_sogg_doc,
    dw.cf_estero_sogg_doc,
    dw.nome_sogg_doc,
    dw.cognome_sogg_doc,
    dw.num_subdoc,
    dw.desc_subdoc,
    dw.importo_subdoc,
    dw.num_reg_iva_subdoc,
    dw.data_scadenza_subdoc,
    dw.convalida_manuale_subdoc,
    dw.importo_da_dedurre_subdoc,
    dw.splitreverse_importo_subdoc,
    dw.pagato_cec_subdoc,
    dw.data_pagamento_cec_subdoc,
    dw.note_tesoriere_subdoc,
    dw.cod_distinta_subdoc,
    dw.desc_distinta_subdoc,
    dw.tipo_commissione_subdoc,
    dw.conto_tesoreria_subdoc,
    dw.rilevante_iva,
    dw.ordinativo_singolo,
    dw.ordinativo_manuale,
    dw.esproprio,
    dw.note,
    dw.cig,
    dw.cup,
    dw.causale_sospensione,
    dw.data_sospensione,
    dw.data_riattivazione,
    dw.causale_ordinativo,
    dw.num_mutuo,
    dw.annotazione,
    dw.certificazione,
    dw.data_certificazione,
    dw.note_certificazione,
    dw.num_certificazione,
    dw.data_scadenza_dopo_sospensione,
    dw.data_esecuzione_pagamento,
    dw.avviso,
    dw.cod_tipo_avviso,
    dw.desc_tipo_avviso,
    dw.sogg_id_subdoc,
    dw.cod_sogg_subdoc,
    dw.tipo_sogg_subdoc,
    dw.stato_sogg_subdoc,
    dw.rag_sociale_sogg_subdoc,
    dw.p_iva_sogg_subdoc,
    dw.cf_sogg_subdoc,
    dw.cf_estero_sogg_subdoc,
    dw.nome_sogg_subdoc,
    dw.cognome_sogg_subdoc,
    dw.sede_secondaria_subdoc,
    dw.bil_anno,
    dw.anno_impegno,
    dw.num_impegno,
    dw.cod_impegno,
    dw.desc_impegno,
    dw.cod_subimpegno,
    dw.desc_subimpegno,
    dw.num_liquidazione,
    dw.cod_tipo_accredito,
    dw.desc_tipo_accredito,
    dw.mod_pag_id,
    dw.quietanziante,
    dw.data_nascita_quietanziante,
    dw.luogo_nascita_quietanziante,
    dw.stato_nascita_quietanziante,
    dw.bic,
    dw.contocorrente,
    dw.intestazione_contocorrente,
    dw.iban,
    dw.note_mod_pag,
    dw.data_scadenza_mod_pag,
    dw.sogg_id_mod_pag,
    dw.cod_sogg_mod_pag,
    dw.tipo_sogg_mod_pag,
    dw.stato_sogg_mod_pag,
    dw.rag_sociale_sogg_mod_pag,
    dw.p_iva_sogg_mod_pag,
    dw.cf_sogg_mod_pag,
    dw.cf_estero_sogg_mod_pag,
    dw.nome_sogg_mod_pag,
    dw.cognome_sogg_mod_pag,
    dw.anno_liquidazione,
    dw.bil_anno_ord,
    dw.anno_ord,
    dw.num_ord,
    dw.num_subord,
    dw.registro_repertorio,
    dw.anno_repertorio,
    dw.num_repertorio,
    dw.data_repertorio,
    dw.data_ricezione_portale,
    dw.doc_contabilizza_genpcc,
    dw.rudoc_registrazione_anno,
    dw.rudoc_registrazione_numero,
    dw.rudoc_registrazione_data,
    dw.cod_cdc_doc,
    dw.desc_cdc_doc,
    dw.cod_cdr_doc,
    dw.desc_cdr_doc,
    dw.data_operazione_pagamentoincasso,
    dw.pagataincassata,
    dw.note_pagamentoincasso,
    dw.arrotondamento,
    dw.cod_tipo_splitrev,
    dw.desc_tipo_splitrev,
    dw.stato_liquidazione,
    dw.sdi_lotto_siope_doc,
    dw.cod_siope_tipo_doc,
    dw.desc_siope_tipo_doc,
    dw.desc_siope_tipo_bnkit_doc,
    dw.cod_siope_tipo_analogico_doc,
    dw.desc_siope_tipo_analogico_doc,
    dw.desc_siope_tipo_ana_bnkit_doc,
    dw.cod_siope_tipo_debito_subdoc,
    dw.desc_siope_tipo_debito_subdoc,
    dw.desc_siope_tipo_deb_bnkit_sub,
    dw.cod_siope_ass_motiv_subdoc,
    dw.desc_siope_ass_motiv_subdoc,
    dw.desc_siope_ass_motiv_bnkit_sub,
    dw.cod_siope_scad_motiv_subdoc,
    dw.desc_siope_scad_motiv_subdoc,
    dw.desc_siope_scad_moti_bnkit_sub,
    dw.doc_id,
    dw.data_ins_atto_allegato,
    dw.data_sosp_atto_allegato,
    dw.causale_sosp_atto_allegato,
    dw.data_riattiva_atto_allegato,
    dw.data_completa_atto_allegato,
    dw.data_convalida_atto_allegato
  from siac_dwh_st_documento_spesa dw
  where dw.ente_proprietario_id=p_ente_proprietario_id;
--  limit 100;

  esito:= 'In funzione carico documenti spesa (FNC_SIAC_DWH_DOCUMENTO_SPESA) - fine dati storici - '||clock_timestamp();
  RETURN NEXT;

  update siac_dwh_log_elaborazioni   log
  set    fnc_elaborazione_fine = clock_timestamp(),
         fnc_durata=clock_timestamp()-log.fnc_elaborazione_inizio,
         fnc_parameters=log.fnc_parameters||' - '||esito
  where fnc_user=v_user_table;
  -- 20.01.2021 Sofia jira SIAC-7967 - fine

end if;
-- 26.01.2021 Sofia Jira SIAC-7518

esito:= 'Fine funzione carico documenti spesa (FNC_SIAC_DWH_DOCUMENTO_SPESA) - '||clock_timestamp();
update siac_dwh_log_elaborazioni   log
set    fnc_elaborazione_fine = clock_timestamp(),
       fnc_durata=clock_timestamp()-log.fnc_elaborazione_inizio,
       fnc_parameters=log.fnc_parameters||' - '||esito
where fnc_user=v_user_table;

end if;



EXCEPTION
WHEN others THEN
  esito:='Funzione carico documenti spesa (FNC_SIAC_DWH_DOCUMENTO_SPESA) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;
alter FUNCTION siac.fnc_siac_dwh_documento_spesa(integer,timestamp) owner to siac;

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_st_documento_spesa
(
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

v_user_table varchar;
params varchar;

annoStorico INTEGER:=2018;
elaboraStorico integer:=null;

BEGIN

SET local work_mem = '64MB'; -- 22.04.2021 Sofia - indicazioni di Meo B.

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;


select substr(liv.gestione_livello_code,1,4)::integer into annoStorico
from siac_d_gestione_livello liv,siac_d_gestione_tipo tipo
where tipo.ente_proprietario_id=p_ente_proprietario_id
and   tipo.gestione_tipo_code='ANNO_STORICO_DWH_DOC_SPESA_ATTIVO'
and   liv.gestione_tipo_id=tipo.gestione_tipo_id
and   tipo.data_cancellazione is null
and   liv.data_cancellazione  is null;

if annoStorico is null then
--	annoStorico:=extract( year from now()::timestamp)-3;
    annoStorico:=2000;

end if;

select fnc_siac_random_user()
into	v_user_table;

params := p_ente_proprietario_id::varchar||' - annoStorico '||annoStorico::varchar||' - '||p_data::varchar;


insert into
siac_dwh_log_elaborazioni (
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values (
p_ente_proprietario_id,
'fnc_siac_dwh_st_documento_spesa',
params,
clock_timestamp(),
v_user_table
);


esito:= 'Inizio funzione carico storico documenti spesa (FNC_SIAC_DWH_ST_DOCUMENTO_SPESA) - '||clock_timestamp();
RETURN NEXT;

select 1 into elaboraStorico
from siac_d_gestione_livello liv,siac_d_gestione_tipo tipo
where tipo.ente_proprietario_id=p_ente_proprietario_id
and   tipo.gestione_tipo_code='ELABORA_STORICO_DWH_DOC_SPESA_ATTIVO'
and   liv.gestione_tipo_id=tipo.gestione_tipo_id
and   tipo.data_cancellazione is null
and   liv.data_cancellazione  is null;

if elaboraStorico is null then
  esito:='Fine funzione carico storico documenti spesa (FNC_SIAC_DWH_ST_DOCUMENTO_SPESA) - elaborazione non attiva - '||clock_timestamp();
  update siac_dwh_log_elaborazioni   log
  set    fnc_elaborazione_fine = clock_timestamp(),
         fnc_durata=clock_timestamp()-log.fnc_elaborazione_inizio,
         fnc_parameters=log.fnc_parameters||' - '||esito
  where fnc_user=v_user_table;
  RETURN next;
  return;

end if;

DELETE FROM siac.siac_dwh_st_documento_spesa
WHERE ente_proprietario_id = p_ente_proprietario_id;
esito:= 'In funzione carico storico documenti spesa (FNC_SIAC_DWH_ST_DOCUMENTO_SPESA) - fine eliminazione dati pregressi - '||clock_timestamp();
update siac_dwh_log_elaborazioni   log
set    fnc_elaborazione_fine = clock_timestamp(),
       fnc_durata=clock_timestamp()-log.fnc_elaborazione_inizio,
       fnc_parameters=log.fnc_parameters||' - '||esito
where fnc_user=v_user_table;
RETURN NEXT;


INSERT INTO
  siac.siac_dwh_st_documento_spesa
(
  ente_proprietario_id,
  ente_denominazione,
  anno_atto_amministrativo,
  num_atto_amministrativo,
  oggetto_atto_amministrativo,
  cod_tipo_atto_amministrativo,
  desc_tipo_atto_amministrativo,
  cod_cdr_atto_amministrativo,
  desc_cdr_atto_amministrativo,
  cod_cdc_atto_amministrativo,
  desc_cdc_atto_amministrativo,
  note_atto_amministrativo,
  cod_stato_atto_amministrativo,
  desc_stato_atto_amministrativo,
  causale_atto_allegato,
  altri_allegati_atto_allegato,
  dati_sensibili_atto_allegato,
  data_scadenza_atto_allegato,
  note_atto_allegato,
  annotazioni_atto_allegato,
  pratica_atto_allegato,
  resp_amm_atto_allegato,
  resp_contabile_atto_allegato,
  anno_titolario_atto_allegato,
  num_titolario_atto_allegato,
  vers_invio_firma_atto_allegato,
  cod_stato_atto_allegato,
  desc_stato_atto_allegato,
  sogg_id_atto_allegato,
  cod_sogg_atto_allegato,
  tipo_sogg_atto_allegato,
  stato_sogg_atto_allegato,
  rag_sociale_sogg_atto_allegato,
  p_iva_sogg_atto_allegato,
  cf_sogg_atto_allegato,
  cf_estero_sogg_atto_allegato,
  nome_sogg_atto_allegato,
  cognome_sogg_atto_allegato,
  anno_doc,
  num_doc,
  desc_doc,
  importo_doc,
  beneficiario_multiplo_doc,
  data_emissione_doc,
  data_scadenza_doc,
  codice_bollo_doc,
  desc_codice_bollo_doc,
  collegato_cec_doc,
  cod_pcc_doc,
  desc_pcc_doc,
  cod_ufficio_doc,
  desc_ufficio_doc,
  cod_stato_doc,
  desc_stato_doc,
  anno_elenco_doc,
  num_elenco_doc,
  data_trasmissione_elenco_doc,
  tot_quote_entrate_elenco_doc,
  tot_quote_spese_elenco_doc,
  tot_da_pagare_elenco_doc,
  tot_da_incassare_elenco_doc,
  cod_stato_elenco_doc,
  desc_stato_elenco_doc,
  cod_gruppo_doc,
  desc_famiglia_doc,
  cod_famiglia_doc,
  desc_gruppo_doc,
  cod_tipo_doc,
  desc_tipo_doc,
  sogg_id_doc,
  cod_sogg_doc,
  tipo_sogg_doc,
  stato_sogg_doc,
  rag_sociale_sogg_doc,
  p_iva_sogg_doc,
  cf_sogg_doc,
  cf_estero_sogg_doc,
  nome_sogg_doc,
  cognome_sogg_doc,
  num_subdoc,
  desc_subdoc,
  importo_subdoc,
  num_reg_iva_subdoc,
  data_scadenza_subdoc,
  convalida_manuale_subdoc,
  importo_da_dedurre_subdoc,
  splitreverse_importo_subdoc,
  pagato_cec_subdoc,
  data_pagamento_cec_subdoc,
  note_tesoriere_subdoc,
  cod_distinta_subdoc,
  desc_distinta_subdoc,
  tipo_commissione_subdoc,
  conto_tesoreria_subdoc,
  rilevante_iva,
  ordinativo_singolo,
  ordinativo_manuale,
  esproprio,
  note,
  cig,
  cup,
  causale_sospensione,
  data_sospensione,
  data_riattivazione,
  causale_ordinativo,
  num_mutuo,
  annotazione,
  certificazione,
  data_certificazione,
  note_certificazione,
  num_certificazione,
  data_scadenza_dopo_sospensione,
  data_esecuzione_pagamento,
  avviso,
  cod_tipo_avviso,
  desc_tipo_avviso,
  sogg_id_subdoc,
  cod_sogg_subdoc,
  tipo_sogg_subdoc,
  stato_sogg_subdoc,
  rag_sociale_sogg_subdoc,
  p_iva_sogg_subdoc,
  cf_sogg_subdoc,
  cf_estero_sogg_subdoc,
  nome_sogg_subdoc,
  cognome_sogg_subdoc,
  sede_secondaria_subdoc,
  bil_anno,
  anno_impegno,
  num_impegno,
  cod_impegno,
  desc_impegno,
  cod_subimpegno,
  desc_subimpegno,
  num_liquidazione,
  cod_tipo_accredito,
  desc_tipo_accredito,
  mod_pag_id,
  quietanziante,
  data_nascita_quietanziante,
  luogo_nascita_quietanziante,
  stato_nascita_quietanziante,
  bic,
  contocorrente,
  intestazione_contocorrente,
  iban,
  note_mod_pag,
  data_scadenza_mod_pag,
  sogg_id_mod_pag,
  cod_sogg_mod_pag,
  tipo_sogg_mod_pag,
  stato_sogg_mod_pag,
  rag_sociale_sogg_mod_pag,
  p_iva_sogg_mod_pag,
  cf_sogg_mod_pag,
  cf_estero_sogg_mod_pag,
  nome_sogg_mod_pag,
  cognome_sogg_mod_pag,
  anno_liquidazione,
  bil_anno_ord,
  anno_ord,
  num_ord,
  num_subord,
  registro_repertorio,
  anno_repertorio,
  num_repertorio,
  data_repertorio,
  data_ricezione_portale,
  doc_contabilizza_genpcc,
  rudoc_registrazione_anno,
  rudoc_registrazione_numero,
  rudoc_registrazione_data,
  cod_cdc_doc,
  desc_cdc_doc,
  cod_cdr_doc,
  desc_cdr_doc,
  data_operazione_pagamentoincasso,
  pagataincassata,
  note_pagamentoincasso,
  arrotondamento,
  cod_tipo_splitrev,
  desc_tipo_splitrev,
  stato_liquidazione,
  sdi_lotto_siope_doc,
  cod_siope_tipo_doc,
  desc_siope_tipo_doc,
  desc_siope_tipo_bnkit_doc,
  cod_siope_tipo_analogico_doc,
  desc_siope_tipo_analogico_doc,
  desc_siope_tipo_ana_bnkit_doc,
  cod_siope_tipo_debito_subdoc,
  desc_siope_tipo_debito_subdoc,
  desc_siope_tipo_deb_bnkit_sub,
  cod_siope_ass_motiv_subdoc,
  desc_siope_ass_motiv_subdoc,
  desc_siope_ass_motiv_bnkit_sub,
  cod_siope_scad_motiv_subdoc,
  desc_siope_scad_motiv_subdoc,
  desc_siope_scad_moti_bnkit_sub,
  doc_id,
  data_ins_atto_allegato,
  data_sosp_atto_allegato,
  causale_sosp_atto_allegato,
  data_riattiva_atto_allegato,
  data_completa_atto_allegato,
  data_convalida_atto_allegato
  )
select
tb.v_ente_proprietario_id::INTEGER,
trim(tb.v_ente_denominazione::VARCHAR)::VARCHAR,
trim(tb.v_anno_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_num_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_oggetto_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_tipo_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_cdr_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_cdr_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_cdc_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_cdc_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_note_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_stato_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_causale_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_altri_allegati_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_dati_sensibili_atto_allegato::VARCHAR)::VARCHAR,
tb.v_data_scadenza_atto_allegato::timestamp,
trim(tb.v_note_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_annotazioni_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_pratica_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_resp_amm_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_resp_contabile_atto_allegato::VARCHAR)::VARCHAR,
tb.v_anno_titolario_atto_allegato::INTEGER,
trim(tb.v_num_titolario_atto_allegato::VARCHAR)::VARCHAR,
tb.v_vers_invio_firma_atto_allegato::INTEGER,
trim(tb.v_cod_stato_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_atto_allegato::VARCHAR)::VARCHAR,
tb.v_sogg_id_atto_allegato::INTEGER,
trim(tb.v_cod_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_atto_allegato::VARCHAR)::VARCHAR,
tb.v_anno_doc::INTEGER,
trim(tb.v_num_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_doc::VARCHAR)::VARCHAR,
tb.v_importo_doc::NUMERIC,
trim(tb.v_beneficiario_multiplo_doc::VARCHAR)::VARCHAR,
tb.v_data_emissione_doc::TIMESTAMP,
tb.v_data_scadenza_doc::TIMESTAMP,
trim(tb.v_codice_bollo_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_codice_bollo_doc::VARCHAR)::VARCHAR,
tb.v_collegato_cec_doc,
trim(tb.v_cod_pcc_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_pcc_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_ufficio_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_ufficio_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_stato_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_doc::VARCHAR)::VARCHAR,
tb.v_anno_elenco_doc::INTEGER,
tb.v_num_elenco_doc::INTEGER,
tb.v_data_trasmissione_elenco_doc::TIMESTAMP,
tb.v_tot_quote_entrate_elenco_doc::NUMERIC,
tb.v_tot_quote_spese_elenco_doc::NUMERIC,
tb.v_tot_da_pagare_elenco_doc::NUMERIC,
tb.v_tot_da_incassare_elenco_doc::NUMERIC,
trim(tb.v_cod_stato_elenco_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_elenco_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_gruppo_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_famiglia_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_famiglia_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_gruppo_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_tipo_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_doc::VARCHAR)::VARCHAR,
tb.v_sogg_id_doc::INTEGER,
trim(tb.v_cod_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_doc::VARCHAR)::VARCHAR,
tb.v_num_subdoc::INTEGER,
trim(tb.v_desc_subdoc::VARCHAR)::VARCHAR,
tb.v_importo_subdoc::NUMERIC,
trim(tb.v_num_reg_iva_subdoc::VARCHAR)::VARCHAR,
tb.v_data_scadenza_subdoc::TIMESTAMP,
trim(tb.v_convalida_manuale_subdoc::VARCHAR)::VARCHAR,
tb.v_importo_da_dedurre_subdoc::NUMERIC,
tb.v_splitreverse_importo_subdoc::NUMERIC,
tb.v_pagato_cec_subdoc,
tb.v_data_pagamento_cec_subdoc::TIMESTAMP,
trim(tb.v_note_tesoriere_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cod_distinta_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_desc_distinta_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_tipo_commissione_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_conto_tesoreria_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_rilevante_iva::VARCHAR)::VARCHAR,
trim(tb.v_ordinativo_singolo::VARCHAR)::VARCHAR,
trim(tb.v_ordinativo_manuale::VARCHAR)::VARCHAR,
trim(tb.v_esproprio::VARCHAR)::VARCHAR,
trim(tb.v_note::VARCHAR)::VARCHAR,
trim(tb.v_cig::VARCHAR)::VARCHAR,
trim(tb.v_cup::VARCHAR)::VARCHAR,
trim(tb.v_causale_sospensione::VARCHAR)::VARCHAR,
trim(tb.v_data_sospensione::VARCHAR)::VARCHAR,
trim(tb.v_data_riattivazione::VARCHAR)::VARCHAR,
trim(tb.v_causale_ordinativo::VARCHAR)::VARCHAR,
tb.v_num_mutuo::INTEGER,
trim(tb.v_annotazione::VARCHAR)::VARCHAR,
trim(tb.v_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_data_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_note_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_num_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_data_scadenza_dopo_sospensione::VARCHAR)::VARCHAR,
trim(tb.v_data_esecuzione_pagamento::VARCHAR)::VARCHAR,
trim(tb.v_avviso::VARCHAR)::VARCHAR,
trim(tb.v_cod_tipo_avviso::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_avviso::VARCHAR)::VARCHAR,
tb.v_soggetto_id::INTEGER,
trim(tb.v_cod_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_sede_secondaria_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_bil_anno::VARCHAR)::VARCHAR,
tb.v_anno_impegno::INTEGER,
tb.v_num_impegno::NUMERIC,
trim(tb.v_cod_impegno::VARCHAR)::VARCHAR,
trim(tb.v_desc_impegno::VARCHAR)::VARCHAR,
trim(tb.v_cod_subimpegno::VARCHAR)::VARCHAR,
trim(tb.v_desc_subimpegno::VARCHAR)::VARCHAR,
tb.v_num_liquidazione::NUMERIC,
trim(tb.v_cod_tipo_accredito::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_accredito::VARCHAR)::VARCHAR,
tb.v_mod_pag_id::INTEGER,
trim(tb.v_quietanziante::VARCHAR)::VARCHAR,
tb.v_data_nasciata_quietanziante::TIMESTAMP,
trim(tb.v_luogo_nascita_quietanziante::VARCHAR)::VARCHAR,
trim(tb.v_stato_nascita_quietanziante::VARCHAR)::VARCHAR,
trim(tb.v_bic::VARCHAR)::VARCHAR,
trim(tb.v_contocorrente::VARCHAR)::VARCHAR,
trim(tb.v_intestazione_contocorrente::VARCHAR)::VARCHAR,
trim(tb.v_iban::VARCHAR)::VARCHAR,
trim(tb.v_note_mod_pag::VARCHAR)::VARCHAR,
tb.v_data_scadenza_mod_pag::TIMESTAMP,
tb.v_soggetto_id_modpag::INTEGER,
trim(tb.v_cod_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_mod_pag::VARCHAR)::VARCHAR,
tb.v_anno_liquidazione::INTEGER,
trim(tb.v_bil_anno_ord::VARCHAR)::VARCHAR,
tb.v_anno_ord::INTEGER,
tb.v_num_ord::NUMERIC,
trim(tb.v_num_subord::VARCHAR)::VARCHAR,
trim(tb.v_registro_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_anno_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_num_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_data_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_data_ricezione_portale::VARCHAR)::VARCHAR,
trim(tb.v_doc_contabilizza_genpcc::VARCHAR)::VARCHAR,
tb.rudoc_registrazione_anno::INTEGER,
tb.rudoc_registrazione_numero::INTEGER,
tb.rudoc_registrazione_data::TIMESTAMP,
trim(tb.cdc_code::VARCHAR)::VARCHAR,
trim(tb.cdc_desc::VARCHAR)::VARCHAR,
trim(tb.cdr_code::VARCHAR)::VARCHAR,
trim(tb.cdr_desc::VARCHAR)::VARCHAR,
trim(tb.v_dataOperazionePagamentoIncasso::VARCHAR)::VARCHAR,
trim(tb.v_flagPagataIncassata::VARCHAR)::VARCHAR,
trim(tb.v_notePagamentoIncasso::VARCHAR)::VARCHAR,
tb.v_arrotondamento,
trim(tb.v_cod_tipo_splitrev::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_splitrev::VARCHAR)::VARCHAR,
trim(tb.v_liq_stato_desc::VARCHAR)::VARCHAR,
tb.doc_sdi_lotto_siope,
tb.siope_documento_tipo_code,
tb.siope_documento_tipo_desc,
tb.siope_documento_tipo_desc_bnkit,
tb.siope_documento_tipo_analogico_code,
tb.siope_documento_tipo_analogico_desc,
tb.siope_documento_tipo_analogico_desc_bnkit,
tb.siope_tipo_debito_code,
tb.siope_tipo_debito_desc,
tb.siope_tipo_debito_desc_bnkit,
tb.siope_assenza_motivazione_code,
tb.siope_assenza_motivazione_desc,
tb.siope_assenza_motivazione_desc_bnkit,
tb.siope_scadenza_motivo_code,
tb.siope_scadenza_motivo_desc,
tb.siope_scadenza_motivo_desc_bnkit ,
tb.doc_id,
tb.data_ins_atto_allegato::timestamp,
tb.data_sosp_atto_allegato::timestamp,
tb.causale_sosp_atto_allegato,
tb.data_riattiva_atto_allegato::timestamp,
tb.data_completa_atto_allegato::timestamp,
tb.data_convalida_atto_allegato::timestamp
from (
with doc as (
  with doc1 as
  (
      with
      doc_totale as
      (
        select distinct
        b.doc_gruppo_tipo_id,
        g.ente_proprietario_id, g.ente_denominazione,
        a.doc_anno, a.doc_numero, a.doc_desc, a.doc_importo,
        case when a.doc_beneficiariomult= false then 'F' else 'T' end doc_beneficiariomult,
        a.doc_data_emissione, a.doc_data_scadenza,
        case when a.doc_collegato_cec = false then 'F' else 'T' end doc_collegato_cec,
        f.doc_stato_code, f.doc_stato_desc,
        c.doc_fam_tipo_code, c.doc_fam_tipo_desc, b.doc_tipo_code, b.doc_tipo_desc,
        a.doc_id, a.pcccod_id, a.pccuff_id,
        case when a.doc_contabilizza_genpcc= false then 'F' else 'T' end doc_contabilizza_genpcc,
        h.subdoc_numero, h.subdoc_desc, h.subdoc_importo, h.subdoc_nreg_iva, h.subdoc_data_scadenza,
        h.subdoc_convalida_manuale, h.subdoc_importo_da_dedurre, h.subdoc_splitreverse_importo,
        case when h.subdoc_pagato_cec = false then 'F' else 'T' end subdoc_pagato_cec,
        h.subdoc_data_pagamento_cec,
        a.codbollo_id, h.subdoc_id,h.comm_tipo_id,
        h.notetes_id,h.dist_id,h.contotes_id,
        a.doc_sdi_lotto_siope,
        n.siope_documento_tipo_code, n.siope_documento_tipo_desc, n.siope_documento_tipo_desc_bnkit,
        o.siope_documento_tipo_analogico_code, o.siope_documento_tipo_analogico_desc, o.siope_documento_tipo_analogico_desc_bnkit,
        i.siope_tipo_debito_code, i.siope_tipo_debito_desc, i.siope_tipo_debito_desc_bnkit,
        l.siope_assenza_motivazione_code, l.siope_assenza_motivazione_desc, l.siope_assenza_motivazione_desc_bnkit,
        m.siope_scadenza_motivo_code, m.siope_scadenza_motivo_desc, m.siope_scadenza_motivo_desc_bnkit
        from siac_t_doc a
        left join siac_d_siope_documento_tipo n on n.siope_documento_tipo_id = a.siope_documento_tipo_id
                                           and n.data_cancellazione is null
                                           and n.validita_fine is null
        left join siac_d_siope_documento_tipo_analogico o on o.siope_documento_tipo_analogico_id = a.siope_documento_tipo_analogico_id
                                                   and o.data_cancellazione is null
                                                   and o.validita_fine is null
        ,siac_d_doc_tipo b,siac_d_doc_fam_tipo c,
        siac_r_doc_stato e,
        siac_d_doc_stato f,
        siac_t_ente_proprietario g,
        siac_t_subdoc h
        left join siac_d_siope_tipo_debito i on i.siope_tipo_debito_id = h.siope_tipo_debito_id
                                           and i.data_cancellazione is null
                                           and i.validita_fine is null
        left join siac_d_siope_assenza_motivazione l on l.siope_assenza_motivazione_id = h.siope_assenza_motivazione_id
                                                   and l.data_cancellazione is null
                                                   and l.validita_fine is null
        left join siac_d_siope_scadenza_motivo m on m.siope_scadenza_motivo_id = h.siope_scadenza_motivo_id
                                                   and m.data_cancellazione is null
                                                   and m.validita_fine is null
        where b.doc_tipo_id=a.doc_tipo_id
        and c.doc_fam_tipo_id=b.doc_fam_tipo_id
        and e.doc_id=a.doc_id
        and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
        and f.doc_stato_id=e.doc_stato_id
        and g.ente_proprietario_id=a.ente_proprietario_id
        and g.ente_proprietario_id=p_ente_proprietario_id
        AND c.doc_fam_tipo_code in ('S','IS')
        and h.doc_id=a.doc_id
        and exists
        (
         select 1
         from
         (
         -- 1 - DOC. NON PAGATI - NON PAGATI INTERAMENTE O PAGATI A CAVALLO DI UN ANNO O DA QUELLO SUCCESSIVO
         (
         select distinct a.doc_id
         from  siac_t_bil anno,siac_t_periodo per,
               siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
               siac_r_ordinativo_stato rs,siac_d_ordinativo_Stato stato,
               siac_t_ordinativo_ts ts,siac_r_subdoc_ordinativo_ts rsub
         where f.doc_stato_code='EM'
         and   rsub.subdoc_id=h.subdoc_id
         and   ts.ord_ts_id=rsub.ord_ts_id
         and   ord.ord_id=ts.ord_id
         and   tipo.ord_tipo_id=ord.ord_tipo_id
         and   tipo.ord_tipo_code='P'
         and   anno.bil_id=ord.bil_id
         and   per.periodo_id=anno.periodo_id
         and   per.anno::integer<=annoStorico
         and   rs.ord_id=ord.ord_id
         and   stato.ord_stato_id=rs.ord_stato_id
         and   stato.ord_stato_code!='A'
         and   not exists
         (
          select 1
          from siac_t_subdoc sub1,siac_r_subdoc_ordinativo_ts rsub1,
               siac_t_ordinativo_ts ts1,siac_t_ordinativo ord1,
               siac_t_bil anno1,siac_t_periodo per1
          where sub1.doc_id=a.doc_id
          and   rsub1.subdoc_id=sub1.subdoc_id
          and   ts1.ord_ts_id=rsub1.ord_ts_id
          and   ord1.ord_id=ts1.ord_id
          and   anno1.bil_id=ord1.bil_id
          and   per1.periodo_id=anno1.bil_id
          and   per1.anno::integer>=annoStorico+1
          and   rsub1.data_cancellazione is null
          and   rsub1.validita_fine is null
         )
         and   rsub.data_cancellazione is null
         and   rsub.validita_fine is null
         and   ts.data_cancellazione is null
         and   ts.validita_fine is null
         and   rs.data_cancellazione is null
         and   rs.validita_fine is null
         )
         union
         (
          -- 2 DOCUMENTI PAGATI MANUALMENTE
          with
          doc_paga_man as
          (
          select rattr.doc_id,
                 substring(coalesce(rattrDataPAga.testo,'01/01/'||(annoStorico+1)::varchar||''),7,4)::integer annoDataPaga
          from siac_r_doc_attr rattr,siac_t_attr attr,
               siac_r_doc_Stato rs,siac_d_doc_Stato stato,
               siac_r_doc_attr rattrDataPaga,siac_t_attr attrDataPaga
          where rattr.doc_id=a.doc_id
          and   attr.attr_id=rattr.attr_id
          and   attr.attr_code='flagPagataIncassata'
          and   rattr.boolean='S'
          and   rs.doc_id=a.doc_id
          and   stato.doc_stato_id=rs.doc_stato_id
          and   stato.doc_stato_code='EM'
          and   rattrDataPaga.doc_id=a.doc_id
          and   attrDataPaga.attr_id=rattrDataPaga.attr_id
          and   attrdatapaga.attr_code='dataOperazionePagamentoIncasso'
          and   rattr.data_cancellazione is null
          and   rs.data_cancellazione is null
          and   rs.validita_fine is null
          )
          select distinct query_doc_paga_man.doc_id
          from doc_paga_man  query_doc_paga_man
          where query_doc_paga_man.annoDataPaga<=annoStorico
         )
         union
         (
           -- 3 - ANNULLATI IN ANNI ANTECEDENTI
           select a.doc_id
           where  f.doc_stato_code='A'
           and  extract (year from e.validita_inizio)::integer<=annoStorico
         )
         union
         (
           -- 4 - STORNATI IN ANNI ANTECEDENTI
           select a.doc_id
           where f.doc_stato_code='ST'
           and  extract (year from e.validita_inizio)::integer<=annoStorico
         )

         ) doc_storico
        )
        AND a.data_cancellazione IS NULL
        AND b.data_cancellazione IS NULL
        AND c.data_cancellazione IS NULL
        AND e.data_cancellazione IS NULL
        AND f.data_cancellazione IS NULL
        AND g.data_cancellazione IS NULL
        AND h.data_cancellazione IS NULL
     )
     select doc_tot.*
     from doc_totale doc_tot
)
, docgru as  (
select a.doc_gruppo_tipo_id, a.doc_gruppo_tipo_code, a.doc_gruppo_tipo_desc
 from siac_d_doc_gruppo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null)
select doc1.*, docgru.* from doc1 left join docgru on
docgru.doc_gruppo_tipo_id = doc1.doc_gruppo_tipo_id
  )
  ,bollo as (
  select a.codbollo_id,a.codbollo_code, a.codbollo_desc from siac_d_codicebollo a
  where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null)
  ,sogg as (
  with sogg1 as (
  select distinct a.doc_id,b.soggetto_code,
  f.soggetto_stato_desc,
  b.partita_iva, b.codice_fiscale, b.codice_fiscale_estero,
   b.soggetto_id
   from
  siac_r_doc_sog a, siac_t_soggetto b ,siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.soggetto_id=b.soggetto_id
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  ),
  sogg5 as (select
c.soggetto_id,d.soggetto_tipo_desc
 from siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d where c.ente_proprietario_id=p_ente_proprietario_id and
  d.soggetto_tipo_id=c.soggetto_tipo_id
  and c.data_cancellazione is null
  and d.data_cancellazione is NULL
  AND p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  )
  select sogg1.*, sogg2.ragione_sociale,sogg3.nome, sogg3.cognome, sogg5.soggetto_tipo_desc
  from sogg1 left join sogg2 on sogg1.soggetto_id=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id=sogg3.soggetto_id
  left join sogg5 on sogg1.soggetto_id=sogg5.soggetto_id
  )
  , reguni as (select a.doc_id,a.rudoc_registrazione_anno,
  a.rudoc_registrazione_numero,a.rudoc_registrazione_data
  from siac_t_registrounico_doc a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , cdr as (
  select a.doc_id, b.classif_code doc_cdr_cdr_code, b.classif_desc doc_cdr_cdr_desc ,
  null   doc_cdr_cdc_code, null  doc_cdr_cdc_desc
  from siac_r_doc_class a, siac_t_class b, siac_d_class_tipo c
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDR'
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  ),
  cdc as (
  select a.doc_id, b.classif_code doc_cdc_cdc_code, b.classif_desc doc_cdc_cdc_desc,
  d.classif_code doc_cdc_cdr_code, d.classif_desc doc_cdc_cdr_desc
  from siac_r_doc_class a, siac_t_class b, siac_d_class_tipo c, siac_t_class d,siac_r_class_fam_tree e
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDC'
  and b.classif_id=e.classif_id
  and d.classif_id=e.classif_id_padre
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL)
  ,pcccod as (select a.pcccod_id,a.pcccod_code,a.pcccod_desc from
  siac_d_pcc_codice  a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , pccuff as (
  select a.pccuff_id,a.pccuff_code,a.pccuff_desc from
  siac_d_pcc_ufficio  a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , attoamm as (
  with attoamm1 as (
  select
  b.attoamm_id,
  a.subdoc_id,  b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
  d.attoamm_stato_code, d.attoamm_stato_desc,
  e.attoamm_tipo_code, e.attoamm_tipo_desc
  from
  siac_r_subdoc_atto_amm a ,siac_t_atto_amm b ,siac_r_atto_amm_stato c ,siac_d_atto_amm_stato d,
  siac_d_atto_amm_tipo e
  where
  a.ente_proprietario_id=p_ente_proprietario_id and
  a.attoamm_id=b.attoamm_id and c.attoamm_id=b.attoamm_id
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and d.attoamm_stato_id=c.attoamm_stato_id
  and e.attoamm_tipo_id=b.attoamm_tipo_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.data_cancellazione is null
  ),
cdr as (
  select a.attoamm_id, b.classif_code attoamm_cdr_cdr_code, b.classif_desc attoamm_cdr_cdr_desc ,
  null::varchar  attoamm_cdr_cdc_code, null::varchar attoamm_cdr_cdc_desc
  from siac_r_atto_amm_class a, siac_t_class b, siac_d_class_tipo c
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDR'
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  ),
  cdc as (
  select a.attoamm_id, b.classif_code attoamm_cdc_cdc_code, b.classif_desc attoamm_cdc_cdc_desc,
  d.classif_code attoamm_cdc_cdr_code, d.classif_desc attoamm_cdc_cdr_desc
  from siac_r_atto_amm_class a, siac_t_class b, siac_d_class_tipo c, siac_t_class d,siac_r_class_fam_tree e
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDC'
  and b.classif_id=e.classif_id
  and d.classif_id=e.classif_id_padre
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  )
  select   attoamm1.*,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdc_code::varchar else null::varchar end attoamm_cdc_code,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdc_desc::varchar else null::varchar end attoamm_cdc_desc,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdr_code::varchar else cdr.attoamm_cdr_cdr_code::varchar end attoamm_cdr_code,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdr_desc::varchar else cdr.attoamm_cdr_cdr_desc::varchar end attoamm_cdr_desc
  from attoamm1
  left join cdc on attoamm1.attoamm_id=cdc.attoamm_id
  left join cdr on attoamm1.attoamm_id=cdr.attoamm_id
  ),
  commt as (select a.comm_tipo_id,a.comm_tipo_code,a.comm_tipo_desc
   from siac_d_commissione_tipo a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  ,
  eldocattall as (
  with eldoc as (
  select a.subdoc_id,a.eldoc_id,
  b.eldoc_anno, b.eldoc_numero, b.eldoc_data_trasmissione, b.eldoc_tot_quoteentrate,
  b.eldoc_tot_quotespese, b.eldoc_tot_dapagare, b.eldoc_tot_daincassare,
  d.eldoc_stato_code, d.eldoc_stato_desc
   from
  siac_r_elenco_doc_subdoc a,siac_t_elenco_doc b, siac_r_elenco_doc_stato c,
  siac_d_elenco_doc_stato d
  where
  a.ente_proprietario_id=p_ente_proprietario_id and
  b.eldoc_id=a.eldoc_id
  and c.eldoc_id=b.eldoc_id
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and d.eldoc_stato_id=c.eldoc_stato_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  ),
  attoal as (with attoall as (
select distinct
  a.eldoc_id,b.attoal_id,
  b.attoal_causale, b.attoal_altriallegati, b.attoal_dati_sensibili,
         b.attoal_data_scadenza, b.attoal_note, b.attoal_annotazioni, b.attoal_pratica,
         b.attoal_responsabile_amm, b.attoal_responsabile_con, b.attoal_titolario_anno,
         b.attoal_titolario_numero, b.attoal_versione_invio_firma,
         d.attoal_stato_code, d.attoal_stato_desc,
         b.data_creazione data_ins_atto_allegato,
	     fnc_siac_attoal_getDataStato(b.attoal_id,'C') data_completa_atto_allegato,
         fnc_siac_attoal_getDataStato(b.attoal_id,'CV') data_convalida_atto_allegato
   from
  siac_r_atto_allegato_elenco_doc a, siac_t_atto_allegato b,
  siac_r_atto_allegato_stato c ,siac_d_atto_allegato_stato d
  where a.ente_proprietario_id=p_ente_proprietario_id and
  a.attoal_id=b.attoal_id
  and c.attoal_id=b.attoal_id
  and d.attoal_stato_id=c.attoal_stato_id
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  ),
  soggattoall as (
  with sogg1 as (
  select distinct a.attoal_id,b.soggetto_code soggetto_code_atto_allegato,
  f.soggetto_stato_desc soggetto_stato_desc_atto_allegato,
  b.partita_iva partita_iva_atto_allegato, b.codice_fiscale codice_fiscale_atto_allegato,
  b.codice_fiscale_estero codice_fiscale_estero_atto_allegato,
  b.soggetto_id soggetto_id_atto_allegato,
  a.attoal_sog_data_sosp data_sosp_atto_allegato,
  a.attoal_sog_causale_sosp causale_sosp_atto_allegato,
  a.attoal_sog_data_riatt data_riattiva_atto_allegato
   from
  siac_r_atto_allegato_sog a, siac_t_soggetto b ,siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.soggetto_id=b.soggetto_id
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale  from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  ),
  sogg5 as (select
	c.soggetto_id,d.soggetto_tipo_desc
 from siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d where c.ente_proprietario_id=p_ente_proprietario_id and
  d.soggetto_tipo_id=c.soggetto_tipo_id
  and c.data_cancellazione is null
  and d.data_cancellazione is NULL
  AND p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  )
  select sogg1.*, sogg2.ragione_sociale ragione_sociale_atto_allegato,sogg3.nome nome_atto_allegato,
  sogg3.cognome cognome_atto_allegato, sogg5.soggetto_tipo_desc soggetto_tipo_desc_atto_allegato
  from sogg1 left join sogg2 on sogg1.soggetto_id_atto_allegato=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id_atto_allegato=sogg3.soggetto_id
  left join sogg5 on sogg1.soggetto_id_atto_allegato=sogg5.soggetto_id
  )
  select attoall.*,soggattoall.ragione_sociale_atto_allegato,soggattoall.nome_atto_allegato,
  soggattoall.cognome_atto_allegato,   soggattoall.soggetto_code_atto_allegato,
  soggattoall.soggetto_tipo_desc_atto_allegato,
  soggattoall.soggetto_stato_desc_atto_allegato,
  soggattoall.partita_iva_atto_allegato, soggattoall.codice_fiscale_atto_allegato,
  soggattoall.codice_fiscale_estero_atto_allegato,
  soggattoall.soggetto_id_atto_allegato ,
  soggattoall.data_sosp_atto_allegato,
  soggattoall.causale_sosp_atto_allegato,
  soggattoall.data_riattiva_atto_allegato
  from attoall left join soggattoall
  on attoall.attoal_id=soggattoall.attoal_id
  )
  select distinct eldoc.*,
  attoal.attoal_id,
  attoal.attoal_causale, attoal.attoal_altriallegati, attoal.attoal_dati_sensibili,
         attoal.attoal_data_scadenza, attoal.attoal_note, attoal.attoal_annotazioni, attoal.attoal_pratica,
         attoal.attoal_responsabile_amm, attoal.attoal_responsabile_con, attoal.attoal_titolario_anno,
         attoal.attoal_titolario_numero, attoal.attoal_versione_invio_firma,
         attoal.attoal_stato_code, attoal.attoal_stato_desc,
   attoal.ragione_sociale_atto_allegato,attoal.nome_atto_allegato,attoal.cognome_atto_allegato,
   attoal.soggetto_code_atto_allegato,
  attoal.soggetto_tipo_desc_atto_allegato,
  attoal.soggetto_stato_desc_atto_allegato,
  attoal.partita_iva_atto_allegato, attoal.codice_fiscale_atto_allegato,
  attoal.codice_fiscale_estero_atto_allegato,
  attoal.soggetto_id_atto_allegato,
  attoal.data_ins_atto_allegato,
  attoal.data_sosp_atto_allegato,
  attoal.causale_sosp_atto_allegato,
  attoal.data_riattiva_atto_allegato,
  attoal.data_completa_atto_allegato,
  attoal.data_convalida_atto_allegato
  from eldoc left join attoal
  on eldoc.eldoc_id=attoal.eldoc_id
  ),
  notes as (
  select a.notetes_id,a.notetes_desc from
  siac.siac_d_note_tesoriere a
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , dist as (
  select a.dist_id,a.dist_code, a.dist_desc from siac_d_distinta a
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , contes as (
  select a.contotes_id,a.contotes_desc from siac_d_contotesoreria  a
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null),
  split as (select
  a.subdoc_id,b.sriva_tipo_code , b.sriva_tipo_desc from  siac_r_subdoc_splitreverse_iva_tipo a,
  siac_d_splitreverse_iva_tipo b
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null
  and b.sriva_tipo_id=a.sriva_tipo_id
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  )
  , liq as (  select  a.subdoc_id,b.liq_anno,b.liq_numero ,d.liq_stato_desc
  from siac.siac_r_subdoc_liquidazione a ,siac_t_liquidazione b,siac_r_liquidazione_stato c ,
  siac_d_liquidazione_stato d
  where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and b.liq_id=a.liq_id
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and c.liq_id=b.liq_id
  and d.liq_stato_id=c.liq_stato_id
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
),
subcltipoavviso as (select a.subdoc_id,b.classif_code cod_tipo_avviso,b.classif_desc desc_tipo_avviso
 from siac_r_subdoc_class a, siac_t_class b,siac_d_class_tipo c
where a.ente_proprietario_id=p_ente_proprietario_id and b.classif_id=a.classif_id
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and c.classif_tipo_id=b.classif_tipo_id
and c.classif_tipo_code='TIPO_AVVISO'
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
),
docattr1 as (
SELECT distinct a.doc_id,
a.testo v_registro_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'registro_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr2 as (
SELECT distinct a.doc_id,
a.numerico v_anno_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'anno_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr3 as (
SELECT distinct a.doc_id,
a.testo v_num_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'num_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr4 as (
SELECT distinct a.doc_id,
a.testo v_data_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'data_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr5 as (
SELECT distinct a.doc_id,
a.testo v_data_ricezione_portale
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataRicezionePortale' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr6 as (
SELECT distinct a.doc_id,
a.testo v_dataOperazionePagamentoIncasso
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataOperazionePagamentoIncasso' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr7 as (
SELECT distinct a.doc_id,
a."boolean" v_flagPagataIncassata
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagPagataIncassata' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr8 as (
SELECT distinct a.doc_id,
a.testo v_notePagamentoIncasso
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'notePagamentoIncasso' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr9 as (
SELECT distinct a.doc_id,
a.numerico v_arrotondamento
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'arrotondamento' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)

,subdocattr1 as (
SELECT distinct a.subdoc_id,
a."boolean" v_rilevante_iva
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagRilevanteIVA' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr2 as (
SELECT a.subdoc_id, a.subdoc_attr_id,
a."boolean" v_ordinativo_singolo
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagOrdinativoSingolo' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)

,subdocattr3 as (
SELECT distinct a.subdoc_id,
a."boolean" v_esproprio
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagEsproprio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr4 as (
SELECT distinct a.subdoc_id,
a."boolean" v_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr5 as (
SELECT distinct a.subdoc_id,
a."boolean" v_ordinativo_manuale
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagOrdinativoManuale' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr6 as (
SELECT distinct a.subdoc_id,
a."boolean" v_avviso
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagAvviso' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr7 as (
SELECT distinct a.subdoc_id,
a.numerico v_num_mutuo
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'numeroMutuo' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr8 as (
SELECT distinct a.subdoc_id,
a.testo v_cup
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'cup' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr9 as (
SELECT distinct a.subdoc_id,
a.testo v_cig
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'cig' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr10 as (
SELECT distinct a.subdoc_id,
a.testo v_note_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'noteCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr12 as (
SELECT distinct a.subdoc_id,
a.testo v_data_esecuzione_pagamento
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataEsecuzionePagamento' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr13 as (
SELECT distinct a.subdoc_id,
a.testo v_annotazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'annotazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr14 as (
SELECT distinct a.subdoc_id,
a.testo v_num_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'numeroCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr15 as (
SELECT distinct a.subdoc_id,
a.testo v_data_scadenza_dopo_sospensione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataScadenzaDopoSospensione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr17 as (
SELECT distinct a.subdoc_id,
a.testo v_causale_ordinativo
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'causaleOrdinativo' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr18 as (
SELECT distinct a.subdoc_id,
a.testo v_note
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'Note' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr19 as (
SELECT distinct a.subdoc_id,
a.testo v_data_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,soggsub as (
  with sogg1 as (
  select distinct a.subdoc_id,b.soggetto_code soggetto_code_subdoc,
  f.soggetto_stato_desc soggetto_stato_desc_subdoc,
  b.partita_iva partita_iva_subdoc, b.codice_fiscale codice_fiscale_subdoc,
  b.codice_fiscale_estero codice_fiscale_estero_subdoc,
   b.soggetto_id soggetto_id_subdoc
   from
  siac_r_subdoc_sog a, siac_t_soggetto b ,siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.soggetto_id=b.soggetto_id
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
    AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale ragione_sociale_subdoc  from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome nome_subdoc, h.cognome cognome_subdoc from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  ),
  sogg4 as (
  SELECT a.soggetto_id_da, a.soggetto_id_a
    FROM siac.siac_r_soggetto_relaz a, siac.siac_d_relaz_tipo b
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and
    a.relaz_tipo_id = b.relaz_tipo_id
    AND   b.relaz_tipo_code  = 'SEDE_SECONDARIA'
    AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
    AND   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
    AND   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL)
    ,
sogg5 as (select
c.soggetto_id,d.soggetto_tipo_desc soggetto_tipo_desc_subdoc
 from siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d where c.ente_proprietario_id=p_ente_proprietario_id and
  d.soggetto_tipo_id=c.soggetto_tipo_id
  and c.data_cancellazione is null
  and d.data_cancellazione is NULL
  AND p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  )
  select sogg1.*, sogg2.ragione_sociale_subdoc,sogg3.nome_subdoc, sogg3.cognome_subdoc,
  case when sogg4.soggetto_id_da is not null then 'S' else NULL::varchar end v_sede_secondaria_subdoc
  , sogg5.soggetto_tipo_desc_subdoc
  from sogg1 left join sogg2 on sogg1.soggetto_id_subdoc=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id_subdoc=sogg3.soggetto_id
  left join sogg4 on sogg1.soggetto_id_subdoc=sogg4.soggetto_id_a
  left join sogg5 on sogg1.soggetto_id_subdoc=sogg5.soggetto_id
  ),
  imp as (select distinct
  c.movgest_id,b.movgest_ts_id,
a.subdoc_id,
case when g.movgest_ts_tipo_code ='T' then b.movgest_ts_code else NULL::varchar end v_cod_impegno,
case when g.movgest_ts_tipo_code ='T' then c.movgest_desc else NULL::varchar end v_desc_impegno,
case when g.movgest_ts_tipo_code ='S' then b.movgest_ts_code else NULL::varchar end v_cod_subimpegno,
case when g.movgest_ts_tipo_code ='S' then b.movgest_ts_desc else NULL::varchar end v_desc_subimpegno,
e.anno v_bil_anno,
c.movgest_anno v_anno_impegno,
c.movgest_numero v_num_impegno,
g.movgest_ts_tipo_code
from
siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, siac_t_movgest c, siac_t_bil d,
siac_t_periodo e, siac_d_movgest_tipo f, siac_d_movgest_ts_tipo g
where b.movgest_ts_id=A.movgest_ts_id
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and c.movgest_id=b.movgest_id
and d.bil_id=c.bil_id
and e.periodo_id=d.periodo_id
and f.movgest_tipo_id=c.movgest_tipo_id
and g.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and f.movgest_tipo_code = 'I'
and a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null),
modpag as (
with modpag0 as (
with modpag1 as (
SELECT
a.subdoc_id,b.quietanziante, b.quietanzante_nascita_data, b.quietanziante_nascita_luogo, b.quietanziante_nascita_stato,
b.bic, b.contocorrente ,b.contocorrente_intestazione,b.iban , b.note , b.data_scadenza,b.accredito_tipo_id,
 b.soggetto_id,a.soggrelmpag_id, b.modpag_id
FROM siac.siac_r_subdoc_modpag a, siac.siac_t_modpag b where
a.ente_proprietario_id=p_ente_proprietario_id and
b.modpag_id = a.modpag_id
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is NULL
and b.data_cancellazione is NULL
)
,actipo as (
select a.accredito_tipo_id,
a.accredito_tipo_code ,
a.accredito_tipo_desc
 from siac.siac_d_accredito_tipo a where a.ente_proprietario_id=p_ente_proprietario_id and
a.data_cancellazione is NULL),
relmodpag as ( SELECT
 a.soggrelmpag_id,
b.soggetto_id_a v_soggetto_id_modpag_cess
 FROM  siac.siac_r_soggrel_modpag a, siac.siac_r_soggetto_relaz b
 WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.soggetto_relaz_id = b.soggetto_relaz_id
 AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
 AND   a.data_cancellazione IS NULL
 AND   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
 AND   b.data_cancellazione IS NULL
 )
 select
modpag1.subdoc_id,
modpag1.quietanziante v_quietanziante,
modpag1.quietanzante_nascita_data v_data_nasciata_quietanziante,
modpag1.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
modpag1.quietanziante_nascita_stato v_stato_nascita_quietanziante,
modpag1.bic v_bic, modpag1.contocorrente v_contocorrente,
modpag1.contocorrente_intestazione v_intestazione_contocorrente,
modpag1.iban v_iban, modpag1.note v_note_mod_pag, modpag1.data_scadenza v_data_scadenza_mod_pag,
modpag1.accredito_tipo_id,
 modpag1.soggetto_id v_soggetto_id_modpag_nocess,
modpag1.soggrelmpag_id v_soggrelmpag_id, modpag1.modpag_id v_mod_pag_id,
actipo.accredito_tipo_code v_cod_tipo_accredito,
actipo.accredito_tipo_desc v_desc_tipo_accredito,
case when modpag1.soggrelmpag_id IS NULL THEN modpag1.soggetto_id else relmodpag.v_soggetto_id_modpag_cess
 end v_soggetto_id_modpag
 from modpag1 left join actipo
on modpag1.accredito_tipo_id=actipo.accredito_tipo_id
left join relmodpag on relmodpag.soggrelmpag_id=modpag1.soggrelmpag_id
)
,
 soggmodpag as (
  with sogg1 as (
  select distinct b.soggetto_code, d.soggetto_tipo_desc, f.soggetto_stato_desc,
  b.partita_iva, b.codice_fiscale, b.codice_fiscale_estero,
   b.soggetto_id
   from
  siac_t_soggetto b ,siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d,siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  b.ente_proprietario_id=p_ente_proprietario_id
  and c.soggetto_id=b.soggetto_id
  and d.soggetto_tipo_id=c.soggetto_tipo_id
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  )
  select sogg1.*, sogg2.ragione_sociale,sogg3.nome, sogg3.cognome
  from sogg1 left join sogg2 on sogg1.soggetto_id=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id=sogg3.soggetto_id
  )
select modpag0.*,soggmodpag.soggetto_code v_cod_sogg_mod_pag, soggmodpag.soggetto_tipo_desc v_tipo_sogg_mod_pag,
soggmodpag.soggetto_stato_desc v_stato_sogg_mod_pag, soggmodpag.ragione_sociale v_rag_sociale_sogg_mod_pag,
soggmodpag.partita_iva v_p_iva_sogg_mod_pag, soggmodpag.codice_fiscale v_cf_sogg_mod_pag,
soggmodpag.codice_fiscale_estero v_cf_estero_sogg_mod_pag,
soggmodpag.nome v_nome_sogg_mod_pag, soggmodpag.cognome v_cognome_sogg_mod_pag
 from modpag0
left join soggmodpag on soggmodpag.soggetto_id=modpag0.v_soggetto_id_modpag
),
ord as (
SELECT
a.subdoc_id,
c.ord_anno, c.ord_numero, b.ord_ts_code, g.anno
    FROM  siac_r_subdoc_ordinativo_ts a, siac_t_ordinativo_ts b, siac_t_ordinativo c,
          siac_r_ordinativo_stato d, siac_d_ordinativo_stato e,
          siac.siac_t_bil f, siac.siac_t_periodo g
    WHERE b.ord_ts_id = a.ord_ts_id
    AND   c.ord_id = b.ord_id
    AND   d.ord_id = c.ord_id
    AND   d.ord_stato_id = e.ord_stato_id
    AND   c.bil_id = f.bil_id
    AND   g.periodo_id = f.periodo_id
    AND   e.ord_stato_code <> 'A'
    AND   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL
    AND   c.data_cancellazione IS NULL
    AND   d.data_cancellazione IS NULL
    AND   e.data_cancellazione IS NULL
    AND   f.data_cancellazione IS NULL
    AND   g.data_cancellazione IS NULL
    AND   p_data between a.validita_inizio and COALESCE(a.validita_fine,p_data)
    AND   p_data between d.validita_inizio and COALESCE(d.validita_fine,p_data)
    )
  select doc.ente_proprietario_id v_ente_proprietario_id,
  doc.ente_denominazione v_ente_denominazione,
  doc.subdoc_id,
  doc.doc_anno v_anno_doc, doc.doc_numero v_num_doc,
  doc.doc_desc v_desc_doc,
  doc.doc_importo v_importo_doc,
  doc.doc_beneficiariomult v_beneficiario_multiplo_doc,
  doc.doc_data_emissione v_data_emissione_doc,
  doc.doc_data_scadenza v_data_scadenza_doc,
  bollo.codbollo_code v_codice_bollo_doc, bollo.codbollo_desc v_desc_codice_bollo_doc,
 doc.doc_collegato_cec v_collegato_cec_doc,
  pcccod.pcccod_code v_cod_pcc_doc,pcccod.pcccod_desc v_desc_pcc_doc
  ,pccuff.pccuff_code v_cod_ufficio_doc,pccuff.pccuff_desc v_desc_ufficio_doc,
  doc.doc_stato_code v_cod_stato_doc, doc.doc_stato_desc v_desc_stato_doc,
   doc.doc_fam_tipo_code v_cod_famiglia_doc, doc.doc_fam_tipo_desc v_desc_famiglia_doc,
doc.doc_tipo_code v_cod_tipo_doc, doc.doc_tipo_desc v_desc_tipo_doc,
doc.subdoc_numero v_num_subdoc, doc.subdoc_desc v_desc_subdoc,doc.subdoc_importo v_importo_subdoc,
doc.subdoc_nreg_iva v_num_reg_iva_subdoc, doc.subdoc_data_scadenza v_data_scadenza_subdoc,
doc.subdoc_convalida_manuale v_convalida_manuale_subdoc, doc.subdoc_importo_da_dedurre v_importo_da_dedurre_subdoc,
doc.subdoc_splitreverse_importo v_splitreverse_importo_subdoc,
doc.subdoc_pagato_cec v_pagato_cec_subdoc,
doc.subdoc_data_pagamento_cec v_data_pagamento_cec_subdoc,
doc.doc_contabilizza_genpcc v_doc_contabilizza_genpcc,
sogg.soggetto_id v_sogg_id_doc,sogg.soggetto_code v_cod_sogg_doc, sogg.soggetto_tipo_desc v_tipo_sogg_doc,
sogg.soggetto_stato_desc v_stato_sogg_doc,sogg.ragione_sociale v_rag_sociale_sogg_doc,
sogg.partita_iva v_p_iva_sogg_doc,
sogg.codice_fiscale v_cf_sogg_doc,
sogg.codice_fiscale_estero v_cf_estero_sogg_doc,
sogg.nome v_nome_sogg_doc, sogg.cognome v_cognome_sogg_doc,
reguni.rudoc_registrazione_anno,reguni.rudoc_registrazione_numero,reguni.rudoc_registrazione_data,
case when cdr.doc_cdr_cdr_code is not null then null::varchar else cdc.doc_cdc_cdc_code::varchar end cdc_code,
case when cdr.doc_cdr_cdr_code is not null then null::varchar else cdc.doc_cdc_cdc_desc::varchar end cdc_desc,
case when cdr.doc_cdr_cdr_code is not null then cdr.doc_cdr_cdr_code::varchar else cdc.doc_cdc_cdr_code::varchar end cdr_code,
case when cdr.doc_cdr_cdr_code is not null then cdr.doc_cdr_cdr_desc::varchar else cdc.doc_cdc_cdr_desc::varchar end cdr_desc,
attoamm.attoamm_anno v_anno_atto_amministrativo, attoamm.attoamm_numero v_num_atto_amministrativo,
attoamm.attoamm_oggetto v_oggetto_atto_amministrativo, attoamm.attoamm_note v_note_atto_amministrativo,
attoamm.attoamm_stato_code v_cod_stato_atto_amministrativo, attoamm.attoamm_stato_desc v_desc_stato_atto_amministrativo,
attoamm.attoamm_tipo_code v_cod_tipo_atto_amministrativo, attoamm.attoamm_tipo_desc v_desc_tipo_atto_amministrativo,
attoamm.attoamm_cdc_code v_cod_cdc_atto_amministrativo,attoamm.attoamm_cdc_desc v_desc_cdc_atto_amministrativo,
attoamm.attoamm_cdr_code v_cod_cdr_atto_amministrativo,attoamm.attoamm_cdr_desc v_desc_cdr_atto_amministrativo,
commt.comm_tipo_code,commt.comm_tipo_desc v_tipo_commissione_subdoc,
eldocattall.subdoc_id,eldocattall.eldoc_id,
eldocattall.eldoc_anno v_anno_elenco_doc,
eldocattall.eldoc_numero v_num_elenco_doc,
eldocattall.eldoc_data_trasmissione v_data_trasmissione_elenco_doc,
eldocattall.eldoc_tot_quoteentrate v_tot_quote_entrate_elenco_doc,
eldocattall.eldoc_tot_quotespese v_tot_quote_spese_elenco_doc,
eldocattall.eldoc_tot_dapagare v_tot_da_pagare_elenco_doc,
eldocattall.eldoc_tot_daincassare v_tot_da_incassare_elenco_doc,
eldocattall.eldoc_stato_code v_cod_stato_elenco_doc,
eldocattall.eldoc_stato_desc v_desc_stato_elenco_doc,
eldocattall.attoal_id,
eldocattall.attoal_causale v_causale_atto_allegato,
eldocattall.attoal_altriallegati v_altri_allegati_atto_allegato, eldocattall.attoal_dati_sensibili v_dati_sensibili_atto_allegato,
eldocattall.attoal_data_scadenza v_data_scadenza_atto_allegato, eldocattall.attoal_note v_note_atto_allegato,
eldocattall.attoal_annotazioni v_annotazioni_atto_allegato, eldocattall.attoal_pratica v_pratica_atto_allegato,
eldocattall.attoal_responsabile_amm v_resp_amm_atto_allegato, eldocattall.attoal_responsabile_con v_resp_contabile_atto_allegato,
eldocattall.attoal_titolario_anno v_anno_titolario_atto_allegato,
eldocattall.attoal_titolario_numero v_num_titolario_atto_allegato, eldocattall.attoal_versione_invio_firma v_vers_invio_firma_atto_allegato,
eldocattall.attoal_stato_code v_cod_stato_atto_allegato, eldocattall.attoal_stato_desc v_desc_stato_atto_allegato,
eldocattall.ragione_sociale_atto_allegato v_rag_sociale_sogg_atto_allegato,
eldocattall.nome_atto_allegato v_nome_sogg_atto_allegato,
eldocattall.cognome_atto_allegato v_cognome_sogg_atto_allegato,
eldocattall.soggetto_code_atto_allegato v_cod_sogg_atto_allegato,
eldocattall.soggetto_tipo_desc_atto_allegato v_tipo_sogg_atto_allegato,
eldocattall.soggetto_stato_desc_atto_allegato v_stato_sogg_atto_allegato,
eldocattall.partita_iva_atto_allegato v_p_iva_sogg_atto_allegato,
eldocattall.codice_fiscale_atto_allegato v_cf_sogg_atto_allegato,
eldocattall.codice_fiscale_estero_atto_allegato v_cf_estero_sogg_atto_allegato,
eldocattall.soggetto_id_atto_allegato v_sogg_id_atto_allegato,
doc.doc_gruppo_tipo_code v_cod_gruppo_doc, doc.doc_gruppo_tipo_desc v_desc_gruppo_doc,
notes.notetes_desc v_note_tesoriere_subdoc,
dist.dist_code v_cod_distinta_subdoc, dist.dist_desc v_desc_distinta_subdoc,
contes.contotes_desc v_conto_tesoreria_subdoc,
split.sriva_tipo_code v_cod_tipo_splitrev , split.sriva_tipo_desc v_desc_tipo_splitrev,
liq.liq_anno v_anno_liquidazione,liq.liq_numero v_num_liquidazione,liq.liq_stato_desc v_liq_stato_desc,
subcltipoavviso.cod_tipo_avviso v_cod_tipo_avviso,subcltipoavviso.desc_tipo_avviso v_desc_tipo_avviso,
docattr1.v_registro_repertorio,
docattr2.v_anno_repertorio,
docattr3.v_num_repertorio,
docattr4.v_data_repertorio,
docattr5.v_data_ricezione_portale,
docattr6.v_dataOperazionePagamentoIncasso,
docattr7.v_flagPagataIncassata,
docattr8.v_notePagamentoIncasso,
docattr9.v_arrotondamento,
subdocattr1.v_rilevante_iva,
subdocattr2.v_ordinativo_singolo,
subdocattr3.v_esproprio,
subdocattr4.v_certificazione,
subdocattr5.v_ordinativo_manuale,
subdocattr6.v_avviso,
subdocattr7.v_num_mutuo,
subdocattr8.v_cup,
subdocattr9.v_cig,
subdocattr10.v_note_certificazione,
null::varchar v_data_sospensione,
subdocattr12.v_data_esecuzione_pagamento,
subdocattr13.v_annotazione,
subdocattr14.v_num_certificazione,
subdocattr15.v_data_scadenza_dopo_sospensione,
null::varchar v_data_riattivazione,
subdocattr17.v_causale_ordinativo,
subdocattr18.v_note,
subdocattr19.v_data_certificazione,
null::varchar v_causale_sospensione,
soggsub.soggetto_code_subdoc v_cod_sogg_subdoc,
soggsub.soggetto_tipo_desc_subdoc v_tipo_sogg_subdoc,
soggsub.soggetto_stato_desc_subdoc v_stato_sogg_subdoc,
soggsub.partita_iva_subdoc v_p_iva_sogg_subdoc,
soggsub.codice_fiscale_subdoc v_cf_sogg_subdoc,
soggsub.codice_fiscale_estero_subdoc v_cf_estero_sogg_subdoc,
soggsub.soggetto_id_subdoc v_soggetto_id,
soggsub.nome_subdoc v_nome_sogg_subdoc,
soggsub.cognome_subdoc v_cognome_sogg_subdoc, soggsub.ragione_sociale_subdoc v_rag_sociale_sogg_subdoc,
soggsub.v_sede_secondaria_subdoc v_sede_secondaria_subdoc,
imp.v_cod_impegno v_cod_impegno,
imp.v_desc_impegno v_desc_impegno,
imp.v_cod_subimpegno v_cod_subimpegno,
imp.v_desc_subimpegno v_desc_subimpegno,
imp.v_bil_anno v_bil_anno,
imp.v_anno_impegno v_anno_impegno,
imp.v_num_impegno v_num_impegno,
imp.movgest_ts_tipo_code,
modpag.v_quietanziante v_quietanziante,
modpag.v_data_nasciata_quietanziante,
modpag.v_luogo_nascita_quietanziante,
modpag.v_stato_nascita_quietanziante,
modpag.v_bic, modpag.v_contocorrente,
modpag.v_intestazione_contocorrente,
modpag.v_iban, modpag.v_note_mod_pag, modpag.v_data_scadenza_mod_pag,
modpag.accredito_tipo_id,
modpag.v_soggetto_id_modpag_nocess,
modpag.v_soggrelmpag_id, modpag.v_mod_pag_id,
modpag.v_cod_tipo_accredito v_cod_tipo_accredito,
modpag.v_desc_tipo_accredito v_desc_tipo_accredito,
modpag.v_soggetto_id_modpag,
modpag.v_cod_sogg_mod_pag, modpag.v_tipo_sogg_mod_pag,
modpag.v_stato_sogg_mod_pag, modpag.v_rag_sociale_sogg_mod_pag,
modpag.v_p_iva_sogg_mod_pag, modpag.v_cf_sogg_mod_pag,
modpag.v_cf_estero_sogg_mod_pag,
modpag.v_nome_sogg_mod_pag, modpag.v_cognome_sogg_mod_pag,
ord.subdoc_id,
ord.ord_anno v_anno_ord, ord.ord_numero v_num_ord, ord.ord_ts_code v_num_subord, ord.anno v_bil_anno_ord,
doc.doc_sdi_lotto_siope,
doc.siope_documento_tipo_code, doc.siope_documento_tipo_desc, doc.siope_documento_tipo_desc_bnkit,
doc.siope_documento_tipo_analogico_code, doc.siope_documento_tipo_analogico_desc, doc.siope_documento_tipo_analogico_desc_bnkit,
doc.siope_tipo_debito_code, doc.siope_tipo_debito_desc, doc.siope_tipo_debito_desc_bnkit,
doc.siope_assenza_motivazione_code, doc.siope_assenza_motivazione_desc, doc.siope_assenza_motivazione_desc_bnkit,
doc.siope_scadenza_motivo_code, doc.siope_scadenza_motivo_desc, doc.siope_scadenza_motivo_desc_bnkit,
doc.doc_id,
eldocattall.data_ins_atto_allegato,
eldocattall.data_sosp_atto_allegato,
eldocattall.causale_sosp_atto_allegato,
eldocattall.data_riattiva_atto_allegato,
eldocattall.data_completa_atto_allegato,
eldocattall.data_convalida_atto_allegato
from doc
left join bollo on doc.codbollo_id=bollo.codbollo_id
left join sogg on doc.doc_id=sogg.doc_id
left join reguni on doc.doc_id=reguni.doc_id
left join cdc on doc.doc_id=cdc.doc_id
left join cdr on doc.doc_id=cdr.doc_id
left join pcccod on doc.pcccod_id=pcccod.pcccod_id
left join pccuff on doc.pccuff_id=pccuff.pccuff_id
left join attoamm on doc.subdoc_id=attoamm.subdoc_id
left join commt on doc.comm_tipo_id=commt.comm_tipo_id
left join eldocattall on doc.subdoc_id=eldocattall.subdoc_id
left join notes on doc.notetes_id=notes.notetes_id
left join dist  on doc.dist_id=dist.dist_id
left join contes on doc.contotes_id=contes.contotes_id
left join split on doc.subdoc_id=split.subdoc_id
left join liq on doc.subdoc_id=liq.subdoc_id
left join  subcltipoavviso on doc.subdoc_id=subcltipoavviso.subdoc_id
left join docattr1 on doc.doc_id=docattr1.doc_id
left join docattr2 on doc.doc_id=docattr2.doc_id
left join docattr3 on doc.doc_id=docattr3.doc_id
left join docattr4 on doc.doc_id=docattr4.doc_id
left join docattr5 on doc.doc_id=docattr5.doc_id
left join docattr6 on doc.doc_id=docattr6.doc_id
left join docattr7 on doc.doc_id=docattr7.doc_id
left join docattr8 on doc.doc_id=docattr8.doc_id
left join docattr9 on doc.doc_id=docattr9.doc_id
left join subdocattr1 on doc.subdoc_id=subdocattr1.subdoc_id
left join subdocattr2 on doc.subdoc_id=subdocattr2.subdoc_id
left join subdocattr3 on doc.subdoc_id=subdocattr3.subdoc_id
left join subdocattr4 on doc.subdoc_id=subdocattr4.subdoc_id
left join subdocattr5 on doc.subdoc_id=subdocattr5.subdoc_id
left join subdocattr6 on doc.subdoc_id=subdocattr6.subdoc_id
left join subdocattr7 on doc.subdoc_id=subdocattr7.subdoc_id
left join subdocattr8 on doc.subdoc_id=subdocattr8.subdoc_id
left join subdocattr9 on doc.subdoc_id=subdocattr9.subdoc_id
left join subdocattr10 on doc.subdoc_id=subdocattr10.subdoc_id
left join subdocattr12 on doc.subdoc_id=subdocattr12.subdoc_id
left join subdocattr13 on doc.subdoc_id=subdocattr13.subdoc_id
left join subdocattr14 on doc.subdoc_id=subdocattr14.subdoc_id
left join subdocattr15 on doc.subdoc_id=subdocattr15.subdoc_id
left join subdocattr17 on doc.subdoc_id=subdocattr17.subdoc_id
left join subdocattr18 on doc.subdoc_id=subdocattr18.subdoc_id
left join subdocattr19 on doc.subdoc_id=subdocattr19.subdoc_id
left join soggsub on soggsub.subdoc_id = doc.subdoc_id
left join imp on imp.subdoc_id=doc.subdoc_id
left join modpag on modpag.subdoc_id=doc.subdoc_id
left join ord on ord.subdoc_id = doc.subdoc_id
) as tb;


esito:= 'Fine funzione carico storico documenti spesa  (FNC_SIAC_DWH_ST_DOCUMENTO_SPESA) - '||clock_timestamp();
RETURN NEXT;


update siac_dwh_log_elaborazioni   log
set    fnc_elaborazione_fine = clock_timestamp(),
       fnc_durata=clock_timestamp()-log.fnc_elaborazione_inizio,
       fnc_parameters=log.fnc_parameters||' - '||esito
where fnc_user=v_user_table;


EXCEPTION
WHEN others THEN
  esito:='Funzione carico storico documenti spesa (FNC_SIAC_DWH_ST_DOCUMENTO_SPESA) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

alter FUNCTION siac.fnc_siac_dwh_st_documento_spesa(integer,timestamp) owner to siac;

-- SIAC-7518 - Sofia fine

-- INC000005001587 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR153_struttura_dca_spese" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_code varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_code varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_code varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_code varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  bil_ele_code3 varchar,
  code_cofog varchar,
  code_transaz_ue varchar,
  pdc_iv varchar,
  perim_sanitario_spesa varchar,
  ricorrente_spesa varchar,
  cup varchar,
  ord_id integer,
  ord_importo numeric,
  movgest_id integer,
  anno_movgest integer,
  movgest_importo numeric,
  fondo_plur_vinc numeric,
  movgest_importo_app numeric,
  tupla_group varchar
) AS
$body$
DECLARE

bilancio_id integer;
RTN_MESSAGGIO text;
anno_succ varchar;

BEGIN

/*
  SIAC-7702 16/09/2020.
  La funzione e' stata trasformata in funzione chiamante delle funzioni che
  estraggono i dati:
  - BILR153_struttura_dca_spese_dati_anno; estrae i dati come faceva prima 
    la funzione "BILR153_struttura_dca_spese";
  - BILR153_struttura_dca_spese_fpv_anno_succ; estrae i dati dell'FPV per 
    l'anno di bilancio successivo (come richiesto dalla jira SIAC-7702).
*/

anno_succ:=(p_anno::integer + 1);

return query
      select dati.bil_anno ,  dati.missione_tipo_code ,
        dati.missione_tipo_desc , dati.missione_code ,
        dati.missione_desc ,  dati.programma_tipo_code ,
        dati.programma_tipo_desc , 
        --29/04/2021 INC000005001587
        --Presi solo gli ultimi 2 caratteri del programma per risolvere un errore
        --nella generazione del file XBRL.
        --dati.programma_code,
        right(dati.programma_code,2)::varchar ,
        dati.programma_desc ,  dati.titusc_tipo_code ,
        dati.titusc_tipo_desc ,  dati.titusc_code ,
        dati.titusc_desc ,  dati.macroag_tipo_code ,
        dati.macroag_tipo_desc ,  dati.macroag_code ,
        dati.macroag_desc ,  dati.bil_ele_code ,
        dati.bil_ele_desc ,  dati.bil_ele_code2 ,
        dati.bil_ele_desc2 ,  dati.bil_ele_id ,
        dati.bil_ele_id_padre , dati.bil_ele_code3 ,
        dati.code_cofog ,  dati.code_transaz_ue ,
        dati.pdc_iv ,  dati.perim_sanitario_spesa ,
        dati.ricorrente_spesa ,  dati.cup ,
        dati.ord_id ,  dati.ord_importo ,
        dati.movgest_id ,  dati.anno_movgest ,
        dati.movgest_importo ,  
        case when LAG(dati.tupla_group,1) 
              OVER (order by dati.tupla_group) = dati.tupla_group then 0
              	else coalesce(dati_fpv_anno_succ.fondo_plur_vinc,0) 
              end fondo_plur_vinc,
        dati.movgest_importo_app, dati.tupla_group
    from "BILR153_struttura_dca_spese_dati_anno"(p_ente_prop_id, p_anno) dati
     left join (select *
    	from "BILR153_struttura_dca_spese_fpv_anno_succ" (p_ente_prop_id, 
        				anno_succ)) dati_fpv_anno_succ
    on dati.tupla_group=dati_fpv_anno_succ.tupla_group  ;

exception
	when no_data_found THEN
      raise notice 'Nessun dato trovato per per il DCD spese.';
      return;
	when others  THEN
      RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
      return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- INC000005001587 - Maurizio - FINE


-- 29.04.2021 Sofia SIAC-8099 - inizio

drop FUNCTION if exists fnc_fasi_bil_prev_ribaltamento_vincoli 
(
  p_annobilancio integer,
  p_enteproprietarioid integer,
  p_loginoperazione varchar,
  p_dataelaborazione timestamp,
  out faseBilElabIdRet integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

drop FUNCTION if exists fnc_fasi_bil_gest_ribaltamento_vincoli 
(
  p_tipo_ribaltamento varchar, --'GEST-GEST' 'PREV-GEST'
  p_annobilancio integer,
  p_enteproprietarioid integer,
  p_loginoperazione varchar,
  p_dataelaborazione timestamp,
  out faseBilElabIdRet integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);


CREATE OR REPLACE FUNCTION fnc_fasi_bil_prev_ribaltamento_vincoli (
  p_annobilancio integer,
  p_enteproprietarioid integer,
  p_loginoperazione varchar,
  p_dataelaborazione timestamp,
  out faseBilElabIdRet integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
) returns RECORD
AS
  $body$
  DECLARE
    strmessaggio       			VARCHAR(1500):='';
    strmessaggiofinale 			VARCHAR(1500):='';
    bilelemidret           		INTEGER  :=NULL;
    codresult              		INTEGER  :=NULL;
    datainizioval 				timestamp:=NULL;
    fasebilelabid    			INTEGER  :=NULL;
    categoriacapcode 			VARCHAR  :=NULL;
    bilelemstatoanid 			INTEGER  :=NULL;
    --v_dataprimogiornoanno 		timestamp:=NULL;
    ape_prev_da_gest            CONSTANT VARCHAR:='APE_PREV';
    rec_vincoli_gest  			RECORD;
    rec_capitoli_gest 			RECORD;
    _row_count 					INTEGER;
    v_periodo_id_gest           INTEGER;
    v_periodo_id_prev           INTEGER;
    v_bilancio_id_gest           INTEGER;
    v_bilancio_id_prev           INTEGER;

    v_vincolo_id                INTEGER;
    v_vincolo_tipo_id_prev      INTEGER;
    v_elem_id                   INTEGER;
    v_elem_tipo_code_prev       VARCHAR;
    v_elem_tipo_id_prev         INTEGER;
  BEGIN
    messaggiorisultato:='';
    codicerisultato:=0;
    fasebilelabidret:=0;
    datainizioval:= clock_timestamp();
    --v_dataprimogiornoanno:= (p_annobilancio||'-01-01')::timestamp;
    strmessaggiofinale:='Ribaltamento Vincoli da gestione precedente.';





    strmessaggio:='estraggo il periodo del bilancio di previsione periodo_code = anno'||p_annobilancio||'.';
    begin
      select per.periodo_id,bil.bil_id  into strict v_periodo_id_prev ,v_bilancio_id_prev
      from siac_t_periodo per, siac_t_bil bil
      where  bil.ente_proprietario_id=p_enteproprietarioid
      and    per.periodo_id=bil.periodo_id
      and    per.anno::integer = p_annobilancio;
    exception
		when NO_DATA_FOUND then
		 messaggiorisultato:=' periodo inesistente siac_t_periodo ( previsione) anno'||p_annobilancio||'.';
		 return;
		when TOO_MANY_ROWS THEN
		 messaggiorisultato:=' troppi periodi x siac_t_periodo ( previsione) anno'||p_annobilancio||'.';
		 return;
	end;

    strmessaggio:='estraggo il periodo del bilancio di gestione anno prec periodo_code = anno'||p_annobilancio-1||'.';
    begin
      select per.periodo_id,bil.bil_id  into strict v_periodo_id_gest ,v_bilancio_id_gest
      from siac_t_periodo per, siac_t_bil bil
      where  bil.ente_proprietario_id=p_enteproprietarioid
      and    per.periodo_id=bil.periodo_id
      and    per.anno::integer = p_annobilancio-1;
    exception
		when NO_DATA_FOUND then
		 messaggiorisultato:=' periodo inesistente siac_t_periodo ( prec gestione) anno'||p_annobilancio-1||'.';
		 return;
		when TOO_MANY_ROWS THEN
		 messaggiorisultato:=' troppi periodi x siac_t_periodo ( prec gestione) anno'||p_annobilancio-1||'.';
		 return;
	end;


    strmessaggio:='vincolo_tipo_id dei vincoli nuovi di previsione .';
	begin
      select siac_d_vincolo_tipo.vincolo_tipo_id
      into  strict v_vincolo_tipo_id_prev
      from  siac_d_vincolo_tipo
      where siac_d_vincolo_tipo.ente_proprietario_id = p_enteproprietarioid
      and   siac_d_vincolo_tipo.vincolo_tipo_code    = 'P'
      and   siac_d_vincolo_tipo.data_cancellazione is null;
    exception
		when NO_DATA_FOUND then
		 messaggiorisultato:=' vincolo_tipo_id inesistente con code P.';
		 return;
		when TOO_MANY_ROWS THEN
		 messaggiorisultato:=' vincolo_tipo_id troppi con code P.';
		 return;
	end;

/*    execute 'CREATE TABLE IF NOT EXISTS siac_t_vincolo_tmp(id INTEGER);';

    --cancello l'eventuale ribaltamento fatto precedentemente
    delete from siac_r_vincolo_bil_elem using siac_t_vincolo_tmp 	where  siac_r_vincolo_bil_elem.vincolo_id = siac_t_vincolo_tmp.id ;
    delete from siac_r_vincolo_genere using siac_t_vincolo_tmp 		where  siac_r_vincolo_genere.vincolo_id = siac_t_vincolo_tmp.id ;
    delete from siac_r_vincolo_attr using siac_t_vincolo_tmp 		where  siac_r_vincolo_attr.vincolo_id = siac_t_vincolo_tmp.id ;
    delete from siac_r_vincolo_stato using siac_t_vincolo_tmp 		where  siac_r_vincolo_stato.vincolo_id = siac_t_vincolo_tmp.id ;
    delete from siac_t_vincolo using siac_t_vincolo_tmp 			where  siac_t_vincolo.vincolo_id = siac_t_vincolo_tmp.id ;

    -- pulisco la tabella di bck
    execute 'delete from siac_t_vincolo_tmp;';*/

    -- pulizia dati presenti
    strMessaggio:='Pulizia vincoli di previsione. Cancellazione logica siac_r_vincolo_bil_elem.';
    update siac_r_vincolo_bil_elem r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='P'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id_prev
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

    strMessaggio:='Pulizia vincoli di previsione. Cancellazione logica siac_r_vincolo_attr.';
    update siac_r_vincolo_attr r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='P'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id_prev
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

	strMessaggio:='Pulizia vincoli di previsione. Cancellazione logica siac_r_vincolo_genere.';
    update siac_r_vincolo_genere r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='P'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id_prev
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

	-- 05.03.2021 Sofia Jira SIAC-790 - inizio

    strMessaggio:='Pulizia vincoli di previsione. Cancellazione logica siac_r_vincolo_risorse_vincolate.';
    update siac_r_vincolo_risorse_vincolate r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='P'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id_prev
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

	-- 05.03.2021 Sofia Jira SIAC-790 - fine

    strMessaggio:='Pulizia vincoli di previsione. Cancellazione logica siac_r_vincolo_stato.';
    update siac_r_vincolo_stato r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='P'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id_prev
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;



    strMessaggio:='Pulizia vincoli di previsione. Cancellazione logica siac_t_vincolo.';
    update siac_t_vincolo v
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=v.login_operazione||'-'||p_loginoperazione
    from siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='P'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id_prev
    and   v.data_cancellazione is null
    and   v.validita_fine is null;

    strmessaggio:='inizio ciclo sui vincoli di gestione anno precedente';
    FOR rec_vincoli_gest IN(
       select
           siac_t_vincolo.vincolo_id
          ,siac_t_vincolo.vincolo_code
          ,siac_t_vincolo.vincolo_desc
          ,siac_t_vincolo.vincolo_tipo_id
          ,siac_t_vincolo.periodo_id
--          ,siac_d_vincolo_genere.vincolo_gen_id 07.12.2017 Sofia JIRA SIAC-5630
      from
           siac_t_vincolo
          ,siac_d_vincolo_tipo
          ,siac_r_vincolo_stato
          ,siac_d_vincolo_stato
--          ,siac_r_vincolo_genere 07.12.2017 Sofia JIRA SIAC-5630
--          ,siac_d_vincolo_genere 07.12.2017 Sofia JIRA SIAC-5630
      where
            siac_t_vincolo.ente_proprietario_id=p_enteproprietarioid
      and   siac_d_vincolo_tipo.vincolo_tipo_id=siac_t_vincolo.vincolo_tipo_id
      and   siac_t_vincolo.vincolo_id = siac_r_vincolo_stato.vincolo_id
      and   siac_r_vincolo_stato.vincolo_stato_id = siac_d_vincolo_stato.vincolo_stato_id
--     and   siac_t_vincolo.vincolo_id =  siac_r_vincolo_genere.vincolo_id 07.12.2017 Sofia
--     and   siac_r_vincolo_genere.vincolo_gen_id = siac_d_vincolo_genere.vincolo_gen_id 07.12.2017 Sofia
      and   siac_d_vincolo_stato.vincolo_stato_code!='A'
      and   siac_d_vincolo_tipo.vincolo_tipo_code='G'
      and   siac_t_vincolo.periodo_id = v_periodo_id_gest
      and 	siac_r_vincolo_stato.data_cancellazione is null
      and 	siac_r_vincolo_stato.validita_fine is null
      and   siac_t_vincolo.data_cancellazione is null
      and   siac_t_vincolo.validita_fine is null
--      and   siac_r_vincolo_genere.data_cancellazione is null JIRA SIAC-5630

    )LOOP

    	strmessaggio:='inserimento nuovo vincolo su siac_t_vincolo v_vincolo_tipo_id_prev '||v_vincolo_tipo_id_prev||' v_periodo_id_prev '||v_periodo_id_prev||'.';

		insert into siac_t_vincolo (vincolo_code ,vincolo_desc ,vincolo_tipo_id ,periodo_id ,validita_inizio ,validita_fine ,ente_proprietario_id ,data_creazione ,data_modifica ,data_cancellazione ,login_operazione
        )VALUES(
           rec_vincoli_gest.vincolo_code
          ,rec_vincoli_gest.vincolo_desc
          ,v_vincolo_tipo_id_prev
          ,v_periodo_id_prev
          ,now()
          ,null
          ,p_enteproprietarioid
          ,now()
          ,now()
          ,null
          ,p_loginoperazione
        ) returning   vincolo_id INTO v_vincolo_id;

        --mi tengo un bck per sicurezza
        -- execute 'insert into siac_t_vincolo_tmp (id) values('||v_vincolo_id||');';

	    strmessaggio:='inserimento del genere.';
    	insert into siac_r_vincolo_genere
        (vincolo_id,
         vincolo_gen_id,
         validita_inizio,
         ente_proprietario_id,
         data_creazione,
         login_operazione
        )
        (
        select
           v_vincolo_id
          ,r.vincolo_gen_id
          ,now()
          ,p_enteproprietarioid
          ,now()
          ,p_loginoperazione
        from siac_r_vincolo_genere r
        where r.vincolo_id=rec_vincoli_gest.vincolo_id
        and   r.data_cancellazione is null
        and   r.validita_fine is null
        );


    	-- 05.03.2021 Sofia Jira SIAC-790 - inizio
    	strmessaggio:='inserimento risorse.';
    	insert into siac_r_vincolo_risorse_vincolate
        (vincolo_id,
         vincolo_risorse_vincolate_id,
         validita_inizio,
         ente_proprietario_id,
         data_creazione,
         login_operazione
        )
        (
        select
           v_vincolo_id
          ,r.vincolo_risorse_vincolate_id
          ,now()
          ,p_enteproprietarioid
          ,now()
          ,p_loginoperazione
        from siac_r_vincolo_risorse_vincolate r
        where r.vincolo_id=rec_vincoli_gest.vincolo_id
        and   r.data_cancellazione is null
        and   r.validita_fine is null
        );
        -- 05.03.2021 Sofia Jira SIAC-790 - fine

        strmessaggio:='inserimento attributi sul vincolo.';
        insert into siac_r_vincolo_attr (vincolo_id,attr_id,tabella_id,boolean ,percentuale,testo,numerico,validita_inizio ,validita_fine,ente_proprietario_id,data_creazione,data_modifica,data_cancellazione,login_operazione)
        select
           v_vincolo_id
          ,attr_id
          ,tabella_id
          ,boolean
          ,percentuale
          ,testo
          ,numerico
          ,now()
          ,null
          ,p_enteproprietarioid
          ,now()
          ,now()
          ,null
          ,p_loginoperazione
		from
        	siac_r_vincolo_attr
        where
        	siac_r_vincolo_attr.ente_proprietario_id = p_enteproprietarioid
    	and siac_r_vincolo_attr.vincolo_id =  rec_vincoli_gest.vincolo_id
        and siac_r_vincolo_attr.data_cancellazione is null
        and siac_r_vincolo_attr.validita_fine is null;

        strmessaggio:='inserimento dello stato siac_r_vincolo_stato.';
        insert into siac_r_vincolo_stato (vincolo_id,vincolo_stato_id,validita_inizio,validita_fine ,ente_proprietario_id ,data_creazione,data_modifica,data_cancellazione,login_operazione)
        select
           v_vincolo_id
          ,vincolo_stato_id
          ,now()
          ,null
          ,p_enteproprietarioid
          ,now()
          ,now()
          ,null
          ,p_loginoperazione
        from
        siac_r_vincolo_stato
         where
        	siac_r_vincolo_stato.ente_proprietario_id = p_enteproprietarioid
    	and siac_r_vincolo_stato.vincolo_id =  rec_vincoli_gest.vincolo_id
        and siac_r_vincolo_stato.data_cancellazione is null
        and siac_r_vincolo_stato.validita_fine is null;


        strmessaggio:='inserimento capitoli siac_r_vincolo_bil_elem capitoli di gestione vecchi.';
        FOR rec_capitoli_gest IN(
/*        29.04.2021 Sofia Jira SIAC-8099
          select siac_t_bil_elem.elem_id,siac_t_bil_elem.elem_code,siac_t_bil_elem.elem_code2,siac_t_bil_elem.elem_code3 ,siac_d_bil_elem_tipo.elem_tipo_code
          from siac_r_vincolo_bil_elem , siac_t_bil_elem ,siac_d_bil_elem_tipo
          where
              siac_r_vincolo_bil_elem.elem_id =  siac_t_bil_elem.elem_id
          and siac_t_bil_elem.elem_tipo_id    =  siac_d_bil_elem_tipo.elem_tipo_id
          and siac_t_bil_elem.bil_id          =  v_bilancio_id_gest
          and siac_r_vincolo_bil_elem.data_cancellazione is null
          and siac_r_vincolo_bil_elem.vincolo_id = rec_vincoli_gest.vincolo_id
          and siac_r_vincolo_bil_elem.ente_proprietario_id = p_enteproprietarioid
          and siac_r_vincolo_bil_elem.data_cancellazione is null
          and siac_r_vincolo_bil_elem.validita_fine is null*/
          --  29.04.2021 Sofia Jira SIAC-8099
          select e.elem_id,e.elem_code,e.elem_code2,e.elem_code3 ,tipo.elem_tipo_code
          from siac_r_vincolo_bil_elem rvinc, siac_t_bil_elem e ,siac_d_bil_elem_tipo tipo,
               siac_r_bil_elem_Stato rs,siac_d_bil_elem_stato stato
          where rvinc.vincolo_id = rec_vincoli_gest.vincolo_id
          and   rvinc.ente_proprietario_id = p_enteproprietarioid
          and   e.elem_id =  rvinc.elem_id
          and   e.elem_tipo_id    =  tipo.elem_tipo_id
          and   e.bil_id          =  v_bilancio_id_gest
          and   rs.elem_id=e.elem_id
          and   stato.elem_stato_id=rs.elem_stato_id
          and   stato.elem_stato_code!='AN'
          and   rs.data_cancellazione is NULL
          and   rs.validita_fine is null
          and   e.data_cancellazione is NULL
          and   e.validita_fine is null
          and   rvinc.data_cancellazione is null
          and   rvinc.validita_fine is null

        )LOOP

        	strmessaggio:='deduco il codice del capitolo di previsione nuovo.';

			if rec_capitoli_gest.elem_tipo_code = 'CAP-UG' THEN
            	v_elem_tipo_code_prev := 'CAP-UP';
            elseif rec_capitoli_gest.elem_tipo_code = 'CAP-EG' THEN
                v_elem_tipo_code_prev := 'CAP-EP';
        	else
				--messaggiorisultato:=' Errore tipo capitolo '||rec_capitoli_gest.elem_tipo_code||'.';
            	--RAISE EXCEPTION ' Errore tipo capitolo % diverso da CAP-UG e CAP-EG .',rec_capitoli_gest.elem_tipo_code;
                --RETURN;
                continue;
            end if;

        	strmessaggio:='estraggo il tipo nuovo di prev.';
			raise notice 'tipo=% elem_code=% elem_id=%' ,rec_capitoli_gest.elem_tipo_code,rec_capitoli_gest.elem_code,rec_capitoli_gest.elem_id;
            select elem_tipo_id into strict v_elem_tipo_id_prev
            from siac_d_bil_elem_tipo
            where
            ente_proprietario_id = p_enteproprietarioid
            and elem_tipo_code = v_elem_tipo_code_prev ;

    		strmessaggio:='estraggo elem_id v_elem_tipo_id_prev '|| v_elem_tipo_id_prev::varchar||' rec_capitoli_gest.elem_code '||rec_capitoli_gest.elem_code||' rec_capitoli_gest.elem_code2 '||rec_capitoli_gest.elem_code2||' rec_capitoli_gest.elem_code3 '||rec_capitoli_gest.elem_code3||'.';



 --           select siac_t_bil_elem.elem_id into strict v_elem_id
 			v_elem_id:=null;
            /* 29.04.2021 Sofia Jira SIAC-8099
            select siac_t_bil_elem.elem_id into v_elem_id
            FROM   siac_t_bil_elem,siac_t_bil
            where
                siac_t_bil_elem.bil_id         = siac_t_bil.bil_id
            and siac_t_bil.bil_code            = 'BIL_'||p_annobilancio
            and siac_t_bil_elem.elem_code      = rec_capitoli_gest.elem_code
            and siac_t_bil_elem.elem_code2     = rec_capitoli_gest.elem_code2
            and siac_t_bil_elem.elem_code3     = rec_capitoli_gest.elem_code3
            and siac_t_bil_elem.elem_tipo_id   = v_elem_tipo_id_prev
        	and siac_t_bil_elem.ente_proprietario_id = p_enteproprietarioid;*/

		    -- 29.04.2021 Sofia Jira SIAC-8099
			select e.elem_id into v_elem_id
            FROM   siac_t_bil_elem e,siac_t_bil bil,
                   siac_r_bil_elem_stato rs,siac_d_bil_elem_Stato stato
            where e.ente_proprietario_id = p_enteproprietarioid
            and   e.elem_tipo_id   = v_elem_tipo_id_prev
            and   e.bil_id         = bil.bil_id
            and   bil.bil_code            = 'BIL_'||p_annobilancio
            and   e.elem_code      = rec_capitoli_gest.elem_code
            and   e.elem_code2     = rec_capitoli_gest.elem_code2
            and   e.elem_code3     = rec_capitoli_gest.elem_code3
            and   rs.elem_id=e.elem_id
            and   stato.elem_stato_id=rs.elem_Stato_id
            and   stato.elem_Stato_code!='AN'
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   e.data_cancellazione is null
            and   e.validita_fine is null;

            if 	v_elem_id is not null then
             strmessaggio:='inizio inserimenti per i capitoli .';
  			 raise notice 'tipo=% elem_code=% elem_id=%' ,v_elem_tipo_code_prev,rec_capitoli_gest.elem_code,v_elem_id;

             insert into siac_r_vincolo_bil_elem ( vincolo_id,elem_id,validita_inizio,validita_fine,ente_proprietario_id,data_creazione,data_modifica,data_cancellazione ,login_operazione
             )values(
				 v_vincolo_id
                ,v_elem_id
                ,now()
                ,null
                ,p_enteproprietarioid
                ,now()
                ,now()
                ,null
                ,p_loginoperazione
             );
           end if;


        end LOOP;
    end LOOP;
    messaggiorisultato := 'vincoli ribaltati correttamente';
    codicerisultato := 0 ;
    RETURN;
  EXCEPTION
  WHEN raise_exception THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'ERRORE: . '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'Nessun elemento trovato. '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'Errore OTHERS DB '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  END;
  $body$ LANGUAGE 'plpgsql' volatile called ON NULL input security invoker cost 100;

 alter function siac.fnc_fasi_bil_prev_ribaltamento_vincoli(integer,integer, varchar, timestamp,  out integer, out  integer,  out varchar ) owner to siac;
 
 CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_ribaltamento_vincoli (
  p_tipo_ribaltamento varchar, --'GEST-GEST' 'PREV-GEST'
  p_annobilancio integer,
  p_enteproprietarioid integer,
  p_loginoperazione varchar,
  p_dataelaborazione timestamp,
  out faseBilElabIdRet integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
) returns RECORD
AS
  $body$
  DECLARE
    strmessaggio       			VARCHAR(1500)	:='';
    strmessaggiofinale 			VARCHAR(1500)	:='';
    bilelemidret           		INTEGER  		:=NULL;
    codresult              		INTEGER  		:=NULL;
    datainizioval 				timestamp		:=NULL;
    fasebilelabid    			INTEGER  		:=NULL;
    categoriacapcode 			VARCHAR  		:=NULL;
    bilelemstatoanid 			INTEGER  		:=NULL;
    ape_prev_da_gest            CONSTANT VARCHAR:='APE_PREV';
    --v_dataprimogiornoanno 		timestamp		:=NULL;
    rec_vincoli_prev            RECORD;
    rec_vincoli_gest  			RECORD;
    rec_capitoli_gest 			RECORD;
    rec_capitoli_prev 			RECORD;
    _row_count 					INTEGER;

    --v_vincolo_tipo_id_prev      INTEGER;
    v_vincolo_tipo_id_gest      INTEGER;

    v_bilancio_id          		INTEGER;
    v_bilancio_id_prec     		INTEGER;

    v_periodo_id           		INTEGER;
    v_periodo_id_prec      		INTEGER;

    v_vincolo_id                INTEGER;
    v_elem_id                   INTEGER;
    v_elem_tipo_code            VARCHAR;
    v_elem_tipo_id              INTEGER;
  BEGIN
    messaggiorisultato:='';
    codicerisultato:=0;
    fasebilelabidret:=0;
    datainizioval:= clock_timestamp();
    --v_dataprimogiornoanno:= (p_annobilancio||'-01-01')::timestamp;
    strmessaggiofinale:='Ribaltamento Vincoli.';

    -- inserimento fase_bil_t_elaborazione
    strmessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    INSERT INTO fase_bil_t_elaborazione
    (
      fase_bil_elab_esito,
      fase_bil_elab_esito_msg,
      fase_bil_elab_tipo_id,
      ente_proprietario_id,
      validita_inizio,
      login_operazione
    )
    (
    SELECT 'IN', 'ELABORAZIONE FASE BILANCIO  IN CORSO : RIBALTAMENTO VINCOLI.',
        tipo.fase_bil_elab_tipo_id,
        p_enteproprietarioid,
        datainizioval,
        p_loginoperazione
    FROM
    	fase_bil_d_elaborazione_tipo tipo
    WHERE  tipo.ente_proprietario_id=p_enteproprietarioid
    AND    tipo.fase_bil_elab_tipo_code='APE_GEST_VINCOLI'
    AND    tipo.data_cancellazione IS NULL
    AND    tipo.validita_fine IS NULL)
    returning   fase_bil_elab_id
    INTO        fasebilelabid;


    IF fasebilelabid IS NULL THEN
      RAISE EXCEPTION ' Inserimento non effettuato.';
    END IF;

    faseBilElabIdRet:= fasebilelabid;
    codresult:=NULL;
    INSERT INTO fase_bil_t_elaborazione_log
    (
      fase_bil_elab_id,
      fase_bil_elab_log_operazione,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )VALUES(
      fasebilelabid,
      strmessaggio,
      clock_timestamp(),
      p_loginoperazione,
      p_enteproprietarioid
    ) returning   fase_bil_elab_log_id INTO        codresult;

    IF codresult IS NULL THEN
      RAISE EXCEPTION ' Errore in inserimento LOG.';
    END IF;




	--inizio procedura
    strmessaggio:='estraggo il periodo del bilancio in esame = anno-->'||p_annobilancio||'.';
    begin
      select per.periodo_id,bil.bil_id
      into strict v_periodo_id ,v_bilancio_id
      from siac_t_periodo per, siac_t_bil bil
      where  bil.ente_proprietario_id=p_enteproprietarioid
      and    per.periodo_id=bil.periodo_id
      and    per.anno::integer = p_annobilancio;
    exception
		when NO_DATA_FOUND then
		 messaggiorisultato:=' periodo inesistente siac_t_periodo ( previsione) anno'||p_annobilancio||'.';
		 return;
		when TOO_MANY_ROWS THEN
		 messaggiorisultato:=' troppi periodi x siac_t_periodo ( previsione) anno'||p_annobilancio||'.';
		 return;
	end;

    strmessaggio:='estraggo il periodo del bilancio anno precedente periodo_code = anno'||p_annobilancio-1||'.';
    begin
      select per.periodo_id,bil.bil_id
      into strict v_periodo_id_prec ,v_bilancio_id_prec
      from siac_t_periodo per, siac_t_bil bil
      where  bil.ente_proprietario_id=p_enteproprietarioid
      and    per.periodo_id=bil.periodo_id
      and    per.anno::integer = p_annobilancio-1;
    exception
		when NO_DATA_FOUND then
		 messaggiorisultato:=' periodo inesistente siac_t_periodo ( prec gestione) anno'||p_annobilancio-1||'.';
		 return;
		when TOO_MANY_ROWS THEN
		 messaggiorisultato:=' troppi periodi x siac_t_periodo ( prec gestione) anno'||p_annobilancio-1||'.';
		 return;
	end;


    strmessaggio:='vincolo_tipo_id dei vincoli nuovi di gestione .';
	begin
      select siac_d_vincolo_tipo.vincolo_tipo_id
      into  strict v_vincolo_tipo_id_gest
      from  siac_d_vincolo_tipo
      where siac_d_vincolo_tipo.ente_proprietario_id = p_enteproprietarioid
      and   siac_d_vincolo_tipo.vincolo_tipo_code    = 'G'
      and   siac_d_vincolo_tipo.data_cancellazione is null;
    exception
		when NO_DATA_FOUND then
		 messaggiorisultato:=' vincolo_tipo_id inesistente con code G.';
		 return;
		when TOO_MANY_ROWS THEN
		 messaggiorisultato:=' vincolo_tipo_id troppi con code G.';
		 return;
	end;
/*
    strmessaggio:='vincolo_tipo_id dei vincoli di previsione .';
	begin
      select siac_d_vincolo_tipo.vincolo_tipo_id
      into  strict v_vincolo_tipo_id_prev
      from  siac_d_vincolo_tipo
      where siac_d_vincolo_tipo.ente_proprietario_id = p_enteproprietarioid
      and   siac_d_vincolo_tipo.vincolo_tipo_code    = 'P'
      and   siac_d_vincolo_tipo.data_cancellazione is null;
    exception
		when NO_DATA_FOUND then
		 messaggiorisultato:=' vincolo_tipo_id inesistente con code P.';
		 return;
		when TOO_MANY_ROWS THEN
		 messaggiorisultato:=' vincolo_tipo_id troppi con code P.';
		 return;
	end;
*/

   /* execute 'CREATE TABLE IF NOT EXISTS siac_t_vincolo_tmp(id INTEGER);';

    strmessaggio:='cancello eventuale ribaltamento fatto precedentemente';
    delete from siac_r_vincolo_bil_elem using siac_t_vincolo_tmp 	where  siac_r_vincolo_bil_elem.vincolo_id = siac_t_vincolo_tmp.id ;
    delete from siac_r_vincolo_genere using siac_t_vincolo_tmp 		where  siac_r_vincolo_genere.vincolo_id = siac_t_vincolo_tmp.id ;
    delete from siac_r_vincolo_attr using siac_t_vincolo_tmp 		where  siac_r_vincolo_attr.vincolo_id = siac_t_vincolo_tmp.id ;
    delete from siac_r_vincolo_stato using siac_t_vincolo_tmp 		where  siac_r_vincolo_stato.vincolo_id = siac_t_vincolo_tmp.id ;
    delete from siac_t_vincolo using siac_t_vincolo_tmp 			where  siac_t_vincolo.vincolo_id = siac_t_vincolo_tmp.id ;

    -- pulisco la tabella di bck
    execute 'delete from siac_t_vincolo_tmp;';*/


    -- pulizia dati presenti
    strMessaggio:='Pulizia vincoli di gestione. Cancellazione logica siac_r_vincolo_bil_elem.';
    update siac_r_vincolo_bil_elem r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='G'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

    strMessaggio:='Pulizia vincoli di gestione. Cancellazione logica siac_r_vincolo_attr.';
    update siac_r_vincolo_attr r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='G'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

	strMessaggio:='Pulizia vincoli di gestione. Cancellazione logica siac_r_vincolo_genere.';
    update siac_r_vincolo_genere r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='G'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

	-- 05.03.2021 Sofia Jira SIAC-790 - inizio
	strMessaggio:='Pulizia vincoli di gestione. Cancellazione logica siac_r_vincolo_risorse_vincolate.';
    update siac_r_vincolo_risorse_vincolate r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='G'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;
 	-- 05.03.2021 Sofia Jira SIAC-790 - fine


    strMessaggio:='Pulizia vincoli di gestione. Cancellazione logica siac_r_vincolo_stato.';
    update siac_r_vincolo_stato r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='G'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

    strMessaggio:='Pulizia vincoli di gestione. Cancellazione logica siac_t_vincolo.';
    update siac_t_vincolo v
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=v.login_operazione||'-'||p_loginoperazione
    from siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='G'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id
    and   v.data_cancellazione is null
    and   v.validita_fine is null;

	strmessaggio:='ribalto da gestione anno precedente a gestione anno in esame';
	if p_tipo_ribaltamento = 'GEST-GEST' THEN

            strmessaggio:='inizio ciclo sui vincoli di gestione anno precedente';
            FOR rec_vincoli_gest IN(
               select
                   siac_t_vincolo.vincolo_id
                  ,siac_t_vincolo.vincolo_code
                  ,siac_t_vincolo.vincolo_desc
                  ,siac_t_vincolo.vincolo_tipo_id
                  ,siac_t_vincolo.periodo_id
    --              ,siac_d_vincolo_genere.vincolo_gen_id
              from
                   siac_t_vincolo
                  ,siac_d_vincolo_tipo
                  ,siac_r_vincolo_stato
                  ,siac_d_vincolo_stato
--                  ,siac_r_vincolo_genere
  --                ,siac_d_vincolo_genere
              where
                    siac_t_vincolo.ente_proprietario_id=p_enteproprietarioid
              and   siac_d_vincolo_tipo.vincolo_tipo_id=siac_t_vincolo.vincolo_tipo_id
              and   siac_t_vincolo.vincolo_id = siac_r_vincolo_stato.vincolo_id
              and   siac_r_vincolo_stato.vincolo_stato_id = siac_d_vincolo_stato.vincolo_stato_id
--              and   siac_t_vincolo.vincolo_id =  siac_r_vincolo_genere.vincolo_id
--              and   siac_r_vincolo_genere.vincolo_gen_id = siac_d_vincolo_genere.vincolo_gen_id
              and   siac_d_vincolo_stato.vincolo_stato_code!='A'
              and   siac_d_vincolo_tipo.vincolo_tipo_code='G'
              and   siac_t_vincolo.periodo_id = v_periodo_id_prec
              and 	siac_r_vincolo_stato.data_cancellazione is null
              and 	siac_r_vincolo_stato.validita_fine is null
              and 	siac_t_vincolo.data_cancellazione is null
              and 	siac_t_vincolo.validita_fine is null
--              and   siac_r_vincolo_genere.data_cancellazione is null

            )LOOP

                strmessaggio:='inserimento nuovo vincolo su siac_t_vincolo v_vincolo_tipo_id_gest '||v_vincolo_tipo_id_gest||' v_periodo_id '||v_periodo_id||'.';

                insert into siac_t_vincolo (vincolo_code ,vincolo_desc ,vincolo_tipo_id ,periodo_id ,validita_inizio ,validita_fine ,ente_proprietario_id ,data_creazione ,data_modifica ,data_cancellazione ,login_operazione
                )VALUES(
                   rec_vincoli_gest.vincolo_code
                  ,rec_vincoli_gest.vincolo_desc
                  ,v_vincolo_tipo_id_gest
                  ,v_periodo_id
                  ,now()
                  ,null
                  ,p_enteproprietarioid
                  ,now()
                  ,now()
                  ,null
                  ,p_loginoperazione
                ) returning   vincolo_id INTO v_vincolo_id;

                --mi tengo un bck per sicurezza
                -- execute 'insert into siac_t_vincolo_tmp (id) values('||v_vincolo_id||');';

                strmessaggio:='inserimento del genere.';
                insert into siac_r_vincolo_genere
                ( vincolo_id,
                  vincolo_gen_id,
                  validita_inizio,
                  ente_proprietario_id,
                  login_operazione
                )
                (
                select
                   v_vincolo_id
                  ,r.vincolo_gen_id
                  ,now()
                  ,p_enteproprietarioid
                  ,p_loginoperazione
                from siac_r_vincolo_genere r
                where r.vincolo_id=rec_vincoli_gest.vincolo_id
                and   r.data_cancellazione is null
                and   r.validita_fine is null
                );

                -- 05.03.2021 Sofia Jira SIAC-790 - inizio
                strmessaggio:='inserimento risorse.';
                insert into siac_r_vincolo_risorse_vincolate
                (vincolo_id,
                 vincolo_risorse_vincolate_id,
                 validita_inizio,
                 ente_proprietario_id,
                 data_creazione,
                 login_operazione
                )
                (
                select
                   v_vincolo_id
                  ,r.vincolo_risorse_vincolate_id
                  ,now()
                  ,p_enteproprietarioid
                  ,now()
                  ,p_loginoperazione
                from siac_r_vincolo_risorse_vincolate r
                where r.vincolo_id=rec_vincoli_gest.vincolo_id
                and   r.data_cancellazione is null
                and   r.validita_fine is null
                );
                -- 05.03.2021 Sofia Jira SIAC-790 - fine

                strmessaggio:='inserimento attributi sul vincolo.';
                insert into siac_r_vincolo_attr (vincolo_id,attr_id,tabella_id,boolean ,percentuale,testo,numerico,validita_inizio ,validita_fine,ente_proprietario_id,data_creazione,data_modifica,data_cancellazione,login_operazione)
                select
                   v_vincolo_id
                  ,attr_id
                  ,tabella_id
                  ,boolean
                  ,percentuale
                  ,testo
                  ,numerico
                  ,now()
                  ,null
                  ,p_enteproprietarioid
                  ,now()
                  ,now()
                  ,null
                  ,p_loginoperazione
                from
                    siac_r_vincolo_attr
                where
                    siac_r_vincolo_attr.ente_proprietario_id = p_enteproprietarioid
                and siac_r_vincolo_attr.vincolo_id =  rec_vincoli_gest.vincolo_id
                and siac_r_vincolo_attr.data_cancellazione is null
                and siac_r_vincolo_attr.validita_fine is null;

                strmessaggio:='inserimento dello stato siac_r_vincolo_stato.';
                insert into siac_r_vincolo_stato (vincolo_id,vincolo_stato_id,validita_inizio,validita_fine ,ente_proprietario_id ,data_creazione,data_modifica,data_cancellazione,login_operazione)
                select
                   v_vincolo_id
                  ,vincolo_stato_id
                  ,now()
                  ,null
                  ,p_enteproprietarioid
                  ,now()
                  ,now()
                  ,null
                  ,p_loginoperazione
                from
                siac_r_vincolo_stato
                 where
                    siac_r_vincolo_stato.ente_proprietario_id = p_enteproprietarioid
                and siac_r_vincolo_stato.vincolo_id =  rec_vincoli_gest.vincolo_id
                and siac_r_vincolo_stato.data_cancellazione is null
                and siac_r_vincolo_stato.validita_fine is null;


                strmessaggio:='ciclo capitoli di gestione da ribaltare di  anno precedente .';
                FOR rec_capitoli_gest IN(
   /*               select siac_t_bil_elem.elem_id,siac_t_bil_elem.elem_code,siac_t_bil_elem.elem_code2,siac_t_bil_elem.elem_code3 ,siac_d_bil_elem_tipo.elem_tipo_code
                  from siac_r_vincolo_bil_elem , siac_t_bil_elem ,siac_d_bil_elem_tipo
                  where
                      siac_r_vincolo_bil_elem.elem_id =  siac_t_bil_elem.elem_id
                  and siac_t_bil_elem.elem_tipo_id    =  siac_d_bil_elem_tipo.elem_tipo_id
                  and siac_t_bil_elem.bil_id          =  v_bilancio_id_prec
                  and siac_r_vincolo_bil_elem.data_cancellazione is null
                  and siac_r_vincolo_bil_elem.validita_fine is null
                  and siac_r_vincolo_bil_elem.vincolo_id = rec_vincoli_gest.vincolo_id
                  and siac_r_vincolo_bil_elem.ente_proprietario_id = p_enteproprietarioid
SIAC-8099 Sofia 22.04.2021                  */
-- SIAC-8099 Sofia 22.04.2021
                  select e.elem_id,e.elem_code,e.elem_code2,e.elem_code3 ,tipo.elem_tipo_code
                  from siac_r_vincolo_bil_elem r,
                       siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
                       siac_r_bil_elem_stato rs,siac_d_bil_elem_stato stato
                  where r.ente_proprietario_id = p_enteproprietarioid
                  and   r.elem_id =  e.elem_id
                  and   e.elem_tipo_id    =  tipo.elem_tipo_id
                  and   e.bil_id          =  v_bilancio_id_prec
                  and   r.vincolo_id = rec_vincoli_gest.vincolo_id
                  and   rs.elem_id=e.elem_id
                  and   stato.elem_stato_id=rs.elem_stato_id
                  and   stato.elem_stato_code!='AN'
                  and   r.data_cancellazione is null
                  and   r.validita_fine is null
                  and   rs.data_cancellazione is null
                  and   rs.validita_fine is null
                  and   e.data_cancellazione is null
                  and   e.validita_fine is null
                )LOOP

                    strmessaggio:='estraggo il tipo nuovo di prev.';
                    raise notice 'tipo=% elem_code=% elem_id=%' ,rec_capitoli_gest.elem_tipo_code,rec_capitoli_gest.elem_code,rec_capitoli_gest.elem_id;

                    select elem_tipo_id into strict v_elem_tipo_id
                    from siac_d_bil_elem_tipo
                    where
                    ente_proprietario_id = p_enteproprietarioid
                    and elem_tipo_code = rec_capitoli_gest.elem_tipo_code;

                    v_elem_id:=null;
                    strmessaggio:='estraggo elem_id v_elem_tipo_id '|| v_elem_tipo_id::varchar||' rec_capitoli_gest.elem_code '||rec_capitoli_gest.elem_code||' rec_capitoli_gest.elem_code2 '||rec_capitoli_gest.elem_code2||' rec_capitoli_gest.elem_code3 '||rec_capitoli_gest.elem_code3||'.';
--                    select siac_t_bil_elem.elem_id into strict v_elem_id
/* 29.04.2021 Sofia Jira SIAC-8099
                    select siac_t_bil_elem.elem_id into v_elem_id
                    FROM   siac_t_bil_elem,siac_t_bil
                    where
                        siac_t_bil_elem.bil_id         = siac_t_bil.bil_id
                    and siac_t_bil.bil_code            = 'BIL_'||p_annobilancio
                    and siac_t_bil_elem.elem_code      = rec_capitoli_gest.elem_code
                    and siac_t_bil_elem.elem_code2     = rec_capitoli_gest.elem_code2
                    and siac_t_bil_elem.elem_code3     = rec_capitoli_gest.elem_code3
                    and siac_t_bil_elem.elem_tipo_id   = v_elem_tipo_id
                    and siac_t_bil_elem.ente_proprietario_id = p_enteproprietarioid;*/

					-- 29.04.2021 Sofia Jira SIAC-8099
					select e.elem_id into v_elem_id
                    FROM   siac_t_bil_elem e,siac_r_bil_elem_stato rs,siac_d_bil_elem_stato stato,
                           siac_t_bil bil
                    where e.ente_proprietario_id = p_enteproprietarioid
                    and   e.elem_tipo_id   = v_elem_tipo_id
                    and   e.bil_id         = bil.bil_id
                    and   bil.bil_code     = 'BIL_'||p_annobilancio
                    and   e.elem_code      = rec_capitoli_gest.elem_code
                    and   e.elem_code2     = rec_capitoli_gest.elem_code2
                    and   e.elem_code3     = rec_capitoli_gest.elem_code3
                    and   rs.elem_id       = e.elem_id
                    and   stato.elem_stato_id=rs.elem_Stato_id
                    and   stato.elem_stato_code!='AN'
                    and   e.data_cancellazione is null
                    and   e.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null;

					if v_elem_id is not null then
                     strmessaggio:='inizio inserimenti per i capitoli .';
                     raise notice 'tipo=% elem_code=% elem_id=%' ,v_elem_tipo_code,rec_capitoli_gest.elem_code,v_elem_id;

                     insert into siac_r_vincolo_bil_elem ( vincolo_id,elem_id,validita_inizio,validita_fine,ente_proprietario_id,data_creazione,data_modifica,data_cancellazione ,login_operazione
                     )values(
                         v_vincolo_id
                        ,v_elem_id
                        ,now()
                        ,null
                        ,p_enteproprietarioid
                        ,now()
                        ,now()
                        ,null
                        ,p_loginoperazione
                     );
                    end if;


                end LOOP;
            end LOOP;
 	end if;

	--ribalto da previsione anno in esame a gestione anno in esame

	if p_tipo_ribaltamento = 'PREV-GEST' THEN
    	      strmessaggio:='ribaltamento da previsiione a gestione dello stesso anno';
              FOR rec_vincoli_prev IN(
                 select
                     siac_t_vincolo.vincolo_id
                    ,siac_t_vincolo.vincolo_code
                    ,siac_t_vincolo.vincolo_desc
                    ,siac_t_vincolo.vincolo_tipo_id
                    ,siac_t_vincolo.periodo_id
--                    ,siac_d_vincolo_genere.vincolo_gen_id
                from
                     siac_t_vincolo
                    ,siac_d_vincolo_tipo
                    ,siac_r_vincolo_stato
                    ,siac_d_vincolo_stato
--                    ,siac_r_vincolo_genere
--                    ,siac_d_vincolo_genere
                where
                      siac_t_vincolo.ente_proprietario_id=p_enteproprietarioid
                and   siac_d_vincolo_tipo.vincolo_tipo_id=siac_t_vincolo.vincolo_tipo_id
                and   siac_t_vincolo.vincolo_id = siac_r_vincolo_stato.vincolo_id
                and   siac_r_vincolo_stato.vincolo_stato_id = siac_d_vincolo_stato.vincolo_stato_id
--                and   siac_t_vincolo.vincolo_id =  siac_r_vincolo_genere.vincolo_id
--                and   siac_r_vincolo_genere.vincolo_gen_id = siac_d_vincolo_genere.vincolo_gen_id
                and   siac_d_vincolo_stato.vincolo_stato_code!='A'
                and   siac_d_vincolo_tipo.vincolo_tipo_code='P'
                and   siac_t_vincolo.periodo_id = v_periodo_id
                and 	siac_r_vincolo_stato.data_cancellazione is null
                and 	siac_r_vincolo_stato.validita_fine is null
                and 	siac_t_vincolo.data_cancellazione is null
                and 	siac_t_vincolo.validita_fine is null
  --              and   siac_r_vincolo_genere.data_cancellazione is null

              )LOOP

                  strmessaggio:='inserimento nuovo vincolo su siac_t_vincolo v_vincolo_tipo_id_gest '||v_vincolo_tipo_id_gest||' v_periodo_id '||v_periodo_id||'.';
                  insert into siac_t_vincolo (vincolo_code ,vincolo_desc ,vincolo_tipo_id ,periodo_id ,validita_inizio ,validita_fine ,ente_proprietario_id ,data_creazione ,data_modifica ,data_cancellazione ,login_operazione
                  )VALUES(
                     rec_vincoli_prev.vincolo_code
                    ,rec_vincoli_prev.vincolo_desc
                    ,v_vincolo_tipo_id_gest
                    ,v_periodo_id
                    ,now()
                    ,null
                    ,p_enteproprietarioid
                    ,now()
                    ,now()
                    ,null
                    ,p_loginoperazione
                  ) returning   vincolo_id INTO v_vincolo_id;

                  --mi tengo un bck per sicurezza
                 -- execute 'insert into siac_t_vincolo_tmp (id) values('||v_vincolo_id||');';

                  strmessaggio:='inserimento del genere.';
                  insert into siac_r_vincolo_genere
                  ( vincolo_id,
                    vincolo_gen_id,
                    validita_inizio,
                    ente_proprietario_id,
                    login_operazione
                  )
                  (
                  select
                     v_vincolo_id
                    ,r.vincolo_gen_id
                    ,now()
                    ,p_enteproprietarioid
                    ,p_loginoperazione
                  from siac_r_vincolo_genere r
                  where r.vincolo_id=rec_vincoli_prev.vincolo_id
                  and   r.data_cancellazione is null
                  and   r.validita_fine is null
                  );

				-- 20.04.2021 Sofia Jira 	SIAC-8099 - inizio
                strmessaggio:='inserimento risorse.';
                insert into siac_r_vincolo_risorse_vincolate
                (vincolo_id,
                 vincolo_risorse_vincolate_id,
                 validita_inizio,
                 ente_proprietario_id,
                 data_creazione,
                 login_operazione
                )
                (
                select
                   v_vincolo_id
                  ,r.vincolo_risorse_vincolate_id
                  ,now()
                  ,p_enteproprietarioid
                  ,now()
                  ,p_loginoperazione
                from siac_r_vincolo_risorse_vincolate r
                where r.vincolo_id=rec_vincoli_prev.vincolo_id
                and   r.data_cancellazione is null
                and   r.validita_fine is null
                );
                -- 20.04.2021 Sofia Jira 	SIAC-8099 - fine

                  strmessaggio:='inserimento attributi sul vincolo.';
                  insert into siac_r_vincolo_attr (vincolo_id,attr_id,tabella_id,boolean ,percentuale,testo,numerico,validita_inizio ,validita_fine,ente_proprietario_id,data_creazione,data_modifica,data_cancellazione,login_operazione)
                  select
                     v_vincolo_id
                    ,attr_id
                    ,tabella_id
                    ,boolean
                    ,percentuale
                    ,testo
                    ,numerico
                    ,now()
                    ,null
                    ,p_enteproprietarioid
                    ,now()
                    ,now()
                    ,null
                    ,p_loginoperazione
                  from
                      siac_r_vincolo_attr
                  where
                      siac_r_vincolo_attr.ente_proprietario_id = p_enteproprietarioid
                  and siac_r_vincolo_attr.vincolo_id =  rec_vincoli_prev.vincolo_id
                  and siac_r_vincolo_attr.data_cancellazione is null
                  and siac_r_vincolo_attr.validita_fine is null;

                  strmessaggio:='inserimento dello stato siac_r_vincolo_stato.';
                  insert into siac_r_vincolo_stato (vincolo_id,vincolo_stato_id,validita_inizio,validita_fine ,ente_proprietario_id ,data_creazione,data_modifica,data_cancellazione,login_operazione)
                  select
                     v_vincolo_id
                    ,vincolo_stato_id
                    ,now()
                    ,null
                    ,p_enteproprietarioid
                    ,now()
                    ,now()
                    ,null
                    ,p_loginoperazione
                  from
                  siac_r_vincolo_stato
                   where
                      siac_r_vincolo_stato.ente_proprietario_id = p_enteproprietarioid
                  and siac_r_vincolo_stato.vincolo_id =  rec_vincoli_prev.vincolo_id
                  and siac_r_vincolo_stato.data_cancellazione is null
                  and siac_r_vincolo_stato.validita_fine is null;


                  strmessaggio:='ciclo capitoli di previsione da ribaltare dello stesso anno .';
                  FOR rec_capitoli_prev IN(
/*
                    select siac_t_bil_elem.elem_id,siac_t_bil_elem.elem_code,siac_t_bil_elem.elem_code2,siac_t_bil_elem.elem_code3 ,siac_d_bil_elem_tipo.elem_tipo_code
                    from siac_r_vincolo_bil_elem , siac_t_bil_elem ,siac_d_bil_elem_tipo
                    where
                        siac_r_vincolo_bil_elem.elem_id =  siac_t_bil_elem.elem_id
                    and siac_t_bil_elem.elem_tipo_id    =  siac_d_bil_elem_tipo.elem_tipo_id
                    and siac_t_bil_elem.bil_id          =  v_bilancio_id
                    and siac_r_vincolo_bil_elem.data_cancellazione is null
                    and siac_r_vincolo_bil_elem.validita_fine is null
                    and siac_r_vincolo_bil_elem.vincolo_id = rec_vincoli_prev.vincolo_id
                    and siac_r_vincolo_bil_elem.ente_proprietario_id = p_enteproprietarioid
SIAC-8099 Sofia 22.04.2021                    */
-- SIAC-8099 Sofia 22.04.2021
                    select e.elem_id,e.elem_code,e.elem_code2,e.elem_code3 ,tipo.elem_tipo_code
                    from siac_r_vincolo_bil_elem r, siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
                         siac_r_bil_elem_stato rs,siac_d_bil_elem_stato stato
                    where r.ente_proprietario_id = p_enteproprietarioid
                    and   r.elem_id =  e.elem_id
                    and   e.elem_tipo_id    =  tipo.elem_tipo_id
                    and   e.bil_id          =  v_bilancio_id
                    and   r.vincolo_id = rec_vincoli_prev.vincolo_id
                    and   rs.elemid=e.elem_id
                    and   stato.elem_stato_id=rs.elem_stato_id
                    and   stato.elem_stato_code!='AN'
                    and   r.data_cancellazione is null
                    and   r.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   e.data_cancellazione is null
                    and   e.validita_fine is null
                  )LOOP

                      strmessaggio:='deduco il codice del capitolo di gestione nuovo.';

                      if rec_capitoli_prev.elem_tipo_code = 'CAP-UP' THEN
                          v_elem_tipo_code := 'CAP-UG';
                      elseif rec_capitoli_prev.elem_tipo_code = 'CAP-EP' THEN
                          v_elem_tipo_code := 'CAP-EG';
                      end if;

                      strmessaggio:='estraggo il tipo nuovo di prev.';
                      raise notice 'tipo=% elem_code=% elem_id=%' ,rec_capitoli_prev.elem_tipo_code,rec_capitoli_prev.elem_code,rec_capitoli_prev.elem_id;
                      select elem_tipo_id into strict v_elem_tipo_id
                      from siac_d_bil_elem_tipo
                      where
                      ente_proprietario_id = p_enteproprietarioid
                      and elem_tipo_code = v_elem_tipo_code ;

                      strmessaggio:='estraggo elem_id v_elem_tipo_id '|| v_elem_tipo_id::varchar||' rec_capitoli_prev.elem_code '||rec_capitoli_prev.elem_code||' rec_capitoli_prev.elem_code2 '||rec_capitoli_prev.elem_code2||' rec_capitoli_prev.elem_code3 '||rec_capitoli_prev.elem_code3||'.';

--                      select siac_t_bil_elem.elem_id into strict v_elem_id
                      v_elem_id:=null;
/* 29.04.2021 Sofia Jira SIAC-8099
                      select siac_t_bil_elem.elem_id into v_elem_id
                      FROM   siac_t_bil_elem,siac_t_bil
                      where
                          siac_t_bil_elem.bil_id         = siac_t_bil.bil_id
                      and siac_t_bil.bil_code            = 'BIL_'||p_annobilancio
                      and siac_t_bil_elem.elem_code      = rec_capitoli_prev.elem_code
                      and siac_t_bil_elem.elem_code2     = rec_capitoli_prev.elem_code2
                      and siac_t_bil_elem.elem_code3     = rec_capitoli_prev.elem_code3
                      and siac_t_bil_elem.elem_tipo_id   = v_elem_tipo_id
                      and siac_t_bil_elem.ente_proprietario_id = p_enteproprietarioid;*/
					  -- 29.04.2021 Sofia Jira SIAC-8099
                      select siac_t_bil_elem.elem_id into v_elem_id
                      FROM   siac_t_bil_elem e,siac_t_bil bil,
                             siac_r_bil_elem_stato rs,siac_d_bil_elem_stato stato
                      where e.ente_proprietario_id = p_enteproprietarioid
                      and   e.elem_tipo_id   = v_elem_tipo_id
                      and   e.bil_id         = bil.bil_id
                      and   bil.bil_code     = 'BIL_'||p_annobilancio
                      and   e.elem_code      = rec_capitoli_prev.elem_code
                      and   e.elem_code2     = rec_capitoli_prev.elem_code2
                      and   e.elem_code3     = rec_capitoli_prev.elem_code3
                      and   rs.elem_id       =e.elem_id
                      and   stato.elem_stato_id=rs.elem_stato_id
                      and   stato.elem_stato_code='AN'
                      and   rs.data_cancellazione is null
                      and   rs.validita_fine is null
                      and   e.data_cancellazione is null
                      and   e.validita_fine is null;



                      if v_elem_id is not null then
                       strmessaggio:='inizio inserimenti per i capitoli .';
                       raise notice 'tipo=% elem_code=% elem_id=%' ,v_elem_tipo_code,rec_capitoli_prev.elem_code,v_elem_id;

                       insert into siac_r_vincolo_bil_elem ( vincolo_id,elem_id,validita_inizio,validita_fine,ente_proprietario_id,data_creazione,data_modifica,data_cancellazione ,login_operazione
                       )values(
                           v_vincolo_id
                          ,v_elem_id
                          ,now()
                          ,null
                          ,p_enteproprietarioid
                          ,now()
                          ,now()
                          ,null
                          ,p_loginoperazione
                       );
                      end if;

                  end LOOP;
              end LOOP;
/*    ELSE
      	RAISE notice 'PAREAMETRO p_tipo_ribaltamento non valorizzato correttamente valori ammessi GEST-GEST PREV-GEST. ';
      	messaggiorisultato:='PAREAMETRO p_tipo_ribaltamento non valorizzato correttamente valori ammessi GEST-GEST PROV-GEST. ' ;
      	codicerisultato:=-1;
    	return;*/
    end if;
	--Fine procedura

	strMessaggio:='Aggiornamento elaborazione faseBilElabId='||faseBilElabId||' per conclusione OK.';
    update fase_bil_t_elaborazione set
       fase_bil_elab_esito='OK',
       fase_bil_elab_esito_msg='ELABORAZIONE RIBALTAMENTO VINCOLI TERMINATA.'
    where fase_bil_elab_id=faseBilElabId;

	codResult:=null;
   	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),p_loginoperazione,p_enteproprietarioid)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
       	raise exception ' Errore in inserimento LOG.';
    end if;


    messaggiorisultato := 'vincoli ribaltati correttamente';
    codicerisultato := 0 ;
    RETURN;
  EXCEPTION
  WHEN raise_exception THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'ERRORE: . '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'Nessun elemento trovato. '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'Errore OTHERS DB '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  END;
  $body$ LANGUAGE 'plpgsql' volatile called ON NULL input security invoker cost 100;

 alter function siac.fnc_fasi_bil_gest_ribaltamento_vincoli (  varchar,  integer,  integer,  varchar,  timestamp,  out integer,  out integer,  out varchar) owner to siac;
-- 29.04.2021 Sofia SIAC-8099 - fine




-- SIAC-8046


--inserimento azioni
--insert azione OP-CRUSCOTTO-aggiornaAccPagopa
INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, verificauo, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-CRUSCOTTO-aggiornaAccPagopa', 'Aggiorna accertamento pagoPA', a.azione_tipo_id, b.gruppo_azioni_id, '/../siacbilapp/azioneRichiesta.do', FALSE, now(), a.ente_proprietario_id,  'admin'
FROM siac.siac_d_azione_tipo a JOIN siac.siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'AZIONE_SECONDARIA'
AND b.gruppo_azioni_code = 'FIN_BASE2'
AND NOT EXISTS (
  SELECT 1
  FROM siac.siac_t_azione z
  WHERE z.azione_code = 'OP-CRUSCOTTO-aggiornaAccPagopa'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);


-- FUNCTION: siac.fnc_siac_aggiornaaccertamentopagopa(integer, integer, integer, integer, integer)

-- DROP FUNCTION siac.fnc_siac_aggiornaaccertamentopagopa(integer, integer, integer, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_aggiornaaccertamentopagopa(
	p_pagopa_ric_id integer,
	p_pagopa_ric_flusso_anno_accertamento integer,
	p_pagopa_ric_flusso_num_accertamento integer,
	p_codice_ente integer,
	p_anno_esercizio integer)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE
	strMessaggio    			VARCHAR(1500):='';  
    codicerisultato 			integer:=null;
    messaggiorisultato 			VARCHAR(1500):='';
	v_cnt 						integer:=null;
	v_pagopa_ric_flusso_anno_accertamento integer:=null;
	v_pagopa_ric_flusso_num_accertamento integer:=null;
	v_pagopa_ric_flusso_stato_elab VARCHAR(1500):='';--character varying;
	v_file_pagopa_id 			integer:=null;
	v_file_pagopa_stato_id 		integer:=null;
	v_count_file_pagopa_id 		integer:=null;
	
BEGIN
     codicerisultato :=0;
	 v_cnt := 0;
	 messaggiorisultato :='Inizio.';
    
    -- 2 errore gestito (nessun record prima query/collegamento DE/DS)
    -- 1 errore generico
    --  0 ok	

	strMessaggio:= 'Verifica parametri di input.';
 	if (p_pagopa_ric_id is  null) 
	then
		codicerisultato :=2;	 
		messaggiorisultato := 'p_pagopa_ric_id NULL';
		return codicerisultato::varchar ||'-'||messaggiorisultato;
	end if;
	if (p_pagopa_ric_flusso_anno_accertamento is  null) 
	then
		codicerisultato :=2;	 
		messaggiorisultato := 'p_pagopa_ric_flusso_anno_accertamento NULL';
		return codicerisultato::varchar ||'-'||messaggiorisultato;
	end if;
	if (p_pagopa_ric_flusso_num_accertamento is  null) 
	then
		codicerisultato :=2;	 
		messaggiorisultato := 'p_pagopa_ric_flusso_num_accertamento NULL';
		return codicerisultato::varchar ||'-'||messaggiorisultato;
	end if;
	if (p_codice_ente is  null) 
	then
		codicerisultato :=2;	 
		messaggiorisultato := 'p_codice_ente NULL';
		return codicerisultato::varchar ||'-'||messaggiorisultato;
	end if;
	if (p_anno_esercizio is  null) 
	then
		codicerisultato :=2;	 
		messaggiorisultato := 'p_anno_esercizio NULL';
		return codicerisultato::varchar ||'-'||messaggiorisultato;
	end if;
	
	strMessaggio:= 'Lettura dati attuali.';
	select 
	pagopa_t_riconciliazione.pagopa_ric_flusso_anno_accertamento, 
	pagopa_t_riconciliazione.pagopa_ric_flusso_num_accertamento,
	pagopa_t_riconciliazione.pagopa_ric_flusso_stato_elab,
	pagopa_t_riconciliazione.file_pagopa_id
	into
	v_pagopa_ric_flusso_anno_accertamento,
	v_pagopa_ric_flusso_num_accertamento,
	v_pagopa_ric_flusso_stato_elab,
	v_file_pagopa_id
	from siac.pagopa_t_riconciliazione
	where pagopa_t_riconciliazione.ente_proprietario_id = p_codice_ente
		 and pagopa_t_riconciliazione.data_cancellazione is null
		 and pagopa_t_riconciliazione.pagopa_ric_flusso_anno_esercizio = p_anno_esercizio
		 and pagopa_t_riconciliazione.pagopa_ric_id = p_pagopa_ric_id;
	raise notice ' Letti: v_pagopa_ric_flusso_anno_accertamento=% v_pagopa_ric_flusso_num_accertamento=% v_pagopa_ric_flusso_stato_elab=% v_file_pagopa_id=%',
		v_pagopa_ric_flusso_anno_accertamento,
		v_pagopa_ric_flusso_num_accertamento,
		v_pagopa_ric_flusso_stato_elab,
		v_file_pagopa_id;

	strMessaggio:= 'Lettura v_file_pagopa_stato_id';
	select 
	siac_d_file_pagopa_stato.file_pagopa_stato_id
	into
	v_file_pagopa_stato_id
	from siac.siac_d_file_pagopa_stato
	where siac_d_file_pagopa_stato.ente_proprietario_id = p_codice_ente 
		and siac_d_file_pagopa_stato.data_cancellazione is null
		and siac_d_file_pagopa_stato.file_pagopa_stato_code = 'ELABORATO_IN_CORSO_SC';
	raise notice ' Letti: v_file_pagopa_stato_id=% ',
		v_file_pagopa_stato_id;
	
	strMessaggio:= 'Lettura v_count_file_pagopa_id';
	SELECT count(*)
	into
	v_count_file_pagopa_id
	FROM siac.pagopa_t_riconciliazione
	WHERE pagopa_t_riconciliazione.ente_proprietario_id = p_codice_ente
		 AND pagopa_t_riconciliazione.data_cancellazione is null
		 AND pagopa_t_riconciliazione.pagopa_ric_flusso_anno_esercizio = p_anno_esercizio
		 AND pagopa_t_riconciliazione.file_pagopa_id = v_file_pagopa_id
		 AND pagopa_t_riconciliazione.pagopa_ric_flusso_stato_elab = 'E'
		 AND pagopa_t_riconciliazione.pagopa_ric_id != p_pagopa_ric_id;
	raise notice ' Letti: v_count_file_pagopa_id=% ',
		v_count_file_pagopa_id;
		
	------------------------------------------------------------------------------------------- 
	--- Caso 1 - in cui esistono i valori per anno e numero accertamento
	------------------------------------------------------------------------------------------- 
	if((v_pagopa_ric_flusso_anno_accertamento is not null) 
	   and (v_pagopa_ric_flusso_num_accertamento is not null)
	  and (v_pagopa_ric_flusso_anno_accertamento != 0)
	  and (v_pagopa_ric_flusso_num_accertamento != 0))
	then
		v_cnt := 0;
		--update normale
		strMessaggio:= 'Update normale';

		UPDATE pagopa_t_riconciliazione
		SET pagopa_ric_flusso_anno_accertamento = p_pagopa_ric_flusso_anno_accertamento, 
			pagopa_ric_flusso_num_accertamento = p_pagopa_ric_flusso_num_accertamento,
			data_modifica = now(),
			login_operazione = '_'||login_operazione
		WHERE ente_proprietario_id = p_codice_ente
			 AND data_cancellazione is null
			 AND pagopa_ric_flusso_anno_esercizio = p_anno_esercizio
			 AND pagopa_ric_id = p_pagopa_ric_id;
		GET DIAGNOSTICS v_cnt = ROW_COUNT;
		raise notice ' MOdificati: v_cnt=% ', v_cnt;

		if v_cnt != 0 
		then
			codicerisultato :=0;	 
			messaggiorisultato := 'Aggiornamento andato a buon fine';
		else
			codicerisultato :=2;	 
			messaggiorisultato := 'Aggiornamento andato a buon fine';
		end if;

	------------------------------------------------------------------------------------------- 
	--- Caso 2 - in cui non esistono i valori per anno e numero accertamento e pagopa_ric_flusso_stato_elab = 'E'
	------------------------------------------------------------------------------------------- 
	elsif (((v_pagopa_ric_flusso_anno_accertamento is null) or (v_pagopa_ric_flusso_anno_accertamento = 0))
		   and ((v_pagopa_ric_flusso_num_accertamento is null) or (v_pagopa_ric_flusso_num_accertamento = 0))
		   and (v_pagopa_ric_flusso_stato_elab = 'E'))
	then
		v_cnt := 0;
		--casi particolari(caso 2)
		strMessaggio:= 'casi particolari(caso 2.1)';

		UPDATE pagopa_t_riconciliazione
		SET pagopa_ric_flusso_anno_accertamento = p_pagopa_ric_flusso_anno_accertamento, 
			pagopa_ric_flusso_num_accertamento = p_pagopa_ric_flusso_num_accertamento,
			pagopa_ric_errore_id = null,
			pagopa_ric_flusso_stato_elab = 'N',
			data_modifica = now(),
			login_operazione = '_'||login_operazione
		WHERE ente_proprietario_id = p_codice_ente
			 AND data_cancellazione is null
			 AND pagopa_ric_flusso_anno_esercizio = p_anno_esercizio
			 AND pagopa_ric_id = p_pagopa_ric_id;

		GET DIAGNOSTICS v_cnt = ROW_COUNT;
		if v_cnt != 0 
		then
			if v_count_file_pagopa_id = 0 	--vuol dire che si deve fare un'altra update 
											-- (non ci sono altri dettagli con pagopa_ric_flusso_stato_elab = 'E')
			then
				v_cnt := 0;
				strMessaggio:= 'Caso 2.2 si deve fare altra update';

				UPDATE siac.siac_t_file_pagopa
				SET validita_fine = null,
					file_pagopa_stato_id = v_file_pagopa_stato_id,
					data_modifica = now(),
					login_operazione = '_'||login_operazione
				WHERE ente_proprietario_id = p_codice_ente
					 AND data_cancellazione is null
					 AND file_pagopa_id = v_file_pagopa_id; 

				GET DIAGNOSTICS v_cnt = ROW_COUNT;
				if v_cnt != 0 
				then
					codicerisultato :=0;	 
					messaggiorisultato := 'Aggiornamento andato a buon fine';
				else
					codicerisultato :=2;	 
					messaggiorisultato := 'Aggiornamento non andato a buon fine';
				end if;
			else
				codicerisultato :=0;	 
				messaggiorisultato := 'Aggiornamento andato a buon fine';
			end if;
		else
			codicerisultato :=2;	 
			messaggiorisultato := 'Aggiornamento non andato a buon fine';
		end if;

 	------------------------------------------------------------------------------------------- 
	--- Caso NON GESTITO
	------------------------------------------------------------------------------------------- 
	else
		-- altro non gestito
		codicerisultato :=2;	 
		messaggiorisultato := 'Condizione non gestita. Aggiornamento non andato a buon fine';
	end if;

    return codicerisultato::varchar ||'-'||messaggiorisultato;

exception
    when RAISE_EXCEPTION THEN
    	raise notice 'ERRORE DB: % % %',strMessaggio,SQLSTATE, substring(upper(SQLERRM) from 1 for 2500);
        codicerisultato:=1;
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        return codicerisultato::varchar ||'-'||messaggiorisultato;
	when others  THEN
 		raise notice 'ERRORE DB: % % %',strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 2500);
        codicerisultato:=1;
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        return codicerisultato::varchar ||'-'||messaggiorisultato;
END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_aggiornaaccertamentopagopa(integer, integer, integer, integer, integer)
    OWNER TO siac;

GRANT EXECUTE ON FUNCTION siac.fnc_siac_aggiornaaccertamentopagopa(integer, integer, integer, integer, integer) TO siac_rw;

GRANT EXECUTE ON FUNCTION siac.fnc_siac_aggiornaaccertamentopagopa(integer, integer, integer, integer, integer) TO PUBLIC;

GRANT EXECUTE ON FUNCTION siac.fnc_siac_aggiornaaccertamentopagopa(integer, integer, integer, integer, integer) TO siac;



-- 30.04.2021 Sofia Jira SIAC-8074 - inizio
drop view if exists siac.siac_v_dwh_ricevuta_ordinativo;
CREATE OR REPLACE VIEW siac.siac_v_dwh_ricevuta_ordinativo
(
  ente_proprietario_id,
  bil_anno_ord,
  anno_ord,
  num_ord,
  cod_stato_ord,
  desc_stato_ord,
  cod_tipo_ord,
  desc_tipo_ord,
  data_ricevuta_ord,
  numero_ricevuta_ord,
  importo_ricevuta_ord,
  tipo_ricevuta_ord,
  validita_inizio,
  validita_fine
)
AS
SELECT
    tep.ente_proprietario_id, tp.anno AS bil_anno_ord,
    sto.ord_anno AS anno_ord, sto.ord_numero AS num_ord,
    dos.ord_stato_code AS cod_stato_ord,
    dos.ord_stato_desc AS desc_stato_ord,
    dot.ord_tipo_code AS cod_tipo_ord,
    dot.ord_tipo_desc AS desc_tipo_ord,
    roq.ord_quietanza_data AS data_ricevuta_ord,
    roq.ord_quietanza_numero AS numero_ricevuta_ord,
    roq.ord_quietanza_importo AS importo_ricevuta_ord,
    'Q'::text AS tipo_ricevuta_ord,
--    ros.validita_inizio,
--    ros.validita_fine
	-- 30.04.2021 Sofia Jira SIAC-8074
  roq.validita_inizio,
  roq.validita_fine

FROM siac_t_ordinativo sto
  JOIN siac_t_bil tb ON sto.bil_id = tb.bil_id
  JOIN siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
  JOIN siac_t_ente_proprietario tep ON tep.ente_proprietario_id = sto.ente_proprietario_id
  JOIN siac_d_ordinativo_tipo dot ON sto.ord_tipo_id = dot.ord_tipo_id
  JOIN siac_r_ordinativo_stato ros ON ros.ord_id = sto.ord_id
  JOIN siac_d_ordinativo_stato dos ON ros.ord_stato_id = dos.ord_stato_id
  JOIN siac_r_ordinativo_quietanza roq ON roq.ord_id = sto.ord_id AND roq.data_cancellazione IS NULL
WHERE sto.data_cancellazione IS NULL
AND   tb.data_cancellazione IS NULL
AND   tp.data_cancellazione IS NULL
AND   tep.data_cancellazione IS NULL
AND   dot.data_cancellazione IS NULL
AND   ros.data_cancellazione IS NULL
AND   dos.data_cancellazione IS NULL
-- 26.10.2018 jira siac-6477
and   ros.validita_fine is  null
UNION ALL
SELECT
  tep.ente_proprietario_id, tp.anno AS bil_anno_ord,
  sto.ord_anno AS anno_ord, sto.ord_numero AS num_ord,
  dos.ord_stato_code AS cod_stato_ord,
  dos.ord_stato_desc AS desc_stato_ord,
  dot.ord_tipo_code AS cod_tipo_ord,
  dot.ord_tipo_desc AS desc_tipo_ord,
  os.ord_storno_data AS data_ricevuta_ord,
  os.ord_storno_numero AS numero_ricevuta_ord,
  os.ord_storno_importo AS importo_ricevuta_ord,
  'S'::text AS tipo_ricevuta_ord,
--  ros.validita_inizio,
--  ros.validita_fine
-- 30.04.2021 Sofia Jira SIAC-8074
  os.validita_inizio,
  os.validita_fine
FROM siac_t_ordinativo sto
  JOIN siac_t_bil tb ON sto.bil_id = tb.bil_id
  JOIN siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
  JOIN siac_t_ente_proprietario tep ON tep.ente_proprietario_id =  sto.ente_proprietario_id
  JOIN siac_d_ordinativo_tipo dot ON sto.ord_tipo_id = dot.ord_tipo_id
  JOIN siac_r_ordinativo_stato ros ON ros.ord_id = sto.ord_id
  JOIN siac_d_ordinativo_stato dos ON ros.ord_stato_id = dos.ord_stato_id
  JOIN siac_r_ordinativo_storno os ON os.ord_id = sto.ord_id AND  os.data_cancellazione IS NULL
WHERE sto.data_cancellazione IS NULL
AND   tb.data_cancellazione IS NULL
AND   tp.data_cancellazione IS NULL
AND   tep.data_cancellazione IS NULL
AND   dot.data_cancellazione IS NULL
AND   ros.data_cancellazione IS NULL
AND   dos.data_cancellazione IS NULL
-- 26.10.2018 jira siac-6477
and   ros.validita_fine is null;

ALTER view siac.siac_v_dwh_ricevuta_ordinativo OWNER TO siac;
-- 30.04.2021 Sofia Jira SIAC-8074 - fine


--SIAC-8181 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR250_stato_patrimoniale_allegato_D_gsa" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_cod_bilancio varchar,
  p_data_pnota_da date,
  p_data_pnota_a date
)
RETURNS TABLE (
  classif_id integer,
  codice_voce varchar,
  descrizione_voce varchar,
  livello_codifica integer,
  padre varchar,
  foglia varchar,
  pdce_conto_code varchar,
  pdce_conto_descr varchar,
  pdce_conto_numerico varchar,
  pdce_fam_code varchar,
  importo_dare numeric,
  importo_avere numeric,
  importo_saldo numeric,
  segno integer,
  titolo varchar,
  tipo_stato varchar,
  ordinamento varchar,
  display_error varchar
) AS
$body$
DECLARE

classifGestione record;

v_imp_dare           NUMERIC :=0;
v_imp_avere          NUMERIC :=0;
v_imp_saldo		 	 NUMERIC :=0;
v_imp_dare_meno 	 NUMERIC :=0;
v_imp_avere_meno	 NUMERIC :=0;
v_imp_saldo_meno	 NUMERIC :=0;

v_importo 			 NUMERIC :=0;
v_pdce_fam_code      VARCHAR;
v_classificatori     VARCHAR;
v_classificatori1    VARCHAR;
v_codice_subraggruppamento VARCHAR;
v_anno_int integer;

DEF_NULL	constant VARCHAR:='';
RTN_MESSAGGIO 		 VARCHAR(1000):=DEF_NULL;
user_table			 VARCHAR;
conta_livelli integer;
maxLivello integer;
id_bil integer;
conta integer;

BEGIN


RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into   user_table;

v_anno_int := p_anno::integer;

classif_id:=0;
codice_voce := '';
descrizione_voce := '';
livello_codifica := 0;
padre := '';
foglia := '';
pdce_conto_code := '';
pdce_conto_descr := '';
importo_dare :=0;
importo_avere :=0;
display_error:='';

RTN_MESSAGGIO:='Inserimento nella tabella di appoggio.';
raise notice '1 - %' , clock_timestamp()::text;

v_classificatori  := '';
v_classificatori1 := '';
v_codice_subraggruppamento := '';
    
if (p_data_pnota_da IS NOT NULL and p_data_pnota_a IS NULL) OR
	(p_data_pnota_da IS NULL and p_data_pnota_a IS NOT NULL) then
    display_error:='Specificare entrambe le date della prima nota.';
    return next;
    return;
end if;
    

if p_data_pnota_da > p_data_pnota_a THEN
	display_error:='La data Da della prima nota non puo'' essere successiva alla data A.';
    return next;
    return;
end if;
    
v_anno_int:=p_anno::integer; 
conta:=0;
if p_cod_bilancio is not null and p_cod_bilancio <> '' then
	select count(*)
    	into conta
    from siac_t_class class,
        siac_d_class_tipo tipo_class
	where class.classif_tipo_id=tipo_class.classif_tipo_id
    	and class.ente_proprietario_id=p_ente_prop_id
        --SIAC-8181 05/05/2021
        --per lo stato patrimoniale non devo togliere il primo carattere.
        --and upper(right(class.classif_code,length(class.classif_code)-1))=
        --	upper(p_cod_bilancio)
        and upper(class.classif_code)=upper(p_cod_bilancio)
        and class.data_cancellazione IS NULL;       
    if conta = 0 then 
    	display_error:='Il codice bilancio '''||p_cod_bilancio|| ''' non esiste';
    	return next;
    	return;
    end if;
end if;

select a.bil_id
into id_bil
from siac_t_bil a,
	siac_t_periodo b
where a.periodo_id=b.periodo_id
and a.data_cancellazione IS NULL
and a.ente_proprietario_id=p_ente_prop_id
and b.anno =p_anno;

--cerco le voci di stato patrimoniale attivo e passivo e gli importi registrati sui 
--conti solo per le voci "foglia".  
--I dati sono salvati sulla tabella di appoggio "siac_rep_ce_sp_gsa".
with voci as(select class.classif_id, 
class.classif_code,
class.classif_desc, r_class_fam.livello,
 	COALESCE(padre.classif_code,'') padre, 
 	case when figlio.classif_id_padre is null then 'S' else 'N' end foglia,
    case when figlio.classif_id_padre is null then class.classif_id 
    	else 0 end classif_id_foglia, tipo_class.classif_tipo_code
    from siac_t_class class,
        siac_d_class_tipo tipo_class,
        siac_r_class_fam_tree r_class_fam
            left join (select r_fam1.classif_id, class1.classif_code
                        from siac_r_class_fam_tree r_fam1,
                            siac_t_class class1
                        where  r_fam1.classif_id=class1.classif_id
                            and r_fam1.ente_proprietario_id=p_ente_prop_id
                            and r_fam1.data_cancellazione IS NULL) padre
              on padre.classif_id=r_class_fam.classif_id_padre
             left join (select distinct r_tree2.classif_id_padre
                        from siac_r_class_fam_tree r_tree2
                        where r_tree2.ente_proprietario_id=p_ente_prop_id
                            and r_tree2.data_cancellazione IS NULL) figlio
                on r_class_fam.classif_id=figlio.classif_id_padre,
        siac_t_class_fam_tree t_class_fam        
    where class.classif_tipo_id=tipo_class.classif_tipo_id
    and class.classif_id=r_class_fam.classif_id
    and r_class_fam.classif_fam_tree_id=t_class_fam.classif_fam_tree_id
    and class.ente_proprietario_id=p_ente_prop_id
    and tipo_class.classif_tipo_code in('SPA_CODBIL_GSA','SPP_CODBIL_GSA')
	AND v_anno_int BETWEEN date_part('year',class.validita_inizio) AND
           date_part('year',COALESCE(class.validita_fine,now())) 
    and r_class_fam.data_cancellazione IS NULL
    and r_class_fam.validita_fine IS NULL
    AND v_anno_int BETWEEN date_part('year',r_class_fam.validita_inizio) AND
           date_part('year',COALESCE(r_class_fam.validita_fine,now())) ),
conti AS( SELECT fam.pdce_fam_code,fam.pdce_fam_segno, r.classif_id,
                   conto.pdce_conto_code, conto.pdce_conto_desc,
                   conto.pdce_conto_id
            from siac_r_pdce_conto_class r,  siac_t_pdce_conto conto,
                 siac_t_pdce_fam_tree famtree, siac_d_pdce_fam fam,siac_d_ambito ambito
            where conto.pdce_conto_id=r.pdce_conto_id
            and   famtree.pdce_fam_tree_id=conto.pdce_fam_tree_id
            and   fam.pdce_fam_id=famtree.pdce_fam_id
            and   ambito.ambito_id=conto.ambito_id
            and   r.ente_proprietario_id=p_ente_prop_id
            and   ambito.ambito_code='AMBITO_GSA'
            and   r.data_cancellazione is null
            and   conto.data_cancellazione is null
            and   v_anno_int BETWEEN date_part('year',r.validita_inizio)::integer and  coalesce (date_part('year',r.validita_fine)::integer ,v_anno_int)
            and   v_anno_int BETWEEN date_part('year',conto.validita_inizio) AND date_part('year',COALESCE(conto.validita_fine,now()))
           ),
           movimenti as
           (
            select det.pdce_conto_id,
                   sum( case  when det.movep_det_segno='Dare' then COALESCE(det.movep_det_importo,0) else 0 end ) as importo_dare,
                   sum( case  when det.movep_det_segno='Avere' then COALESCE(det.movep_det_importo,0) else 0 end ) as importo_avere
            from  siac_t_periodo per,   siac_t_bil bil,
                  siac_t_prima_nota pn, siac_r_prima_nota_stato rs, siac_d_prima_nota_stato stato,
                  siac_t_mov_ep ep, siac_t_mov_ep_det det,siac_d_ambito ambito
            where per.periodo_id=bil.periodo_id            
            and   pn.bil_id=bil.bil_id
            and   rs.pnota_id=pn.pnota_id
            and   stato.pnota_stato_id=rs.pnota_stato_id
            and   ep.regep_id=pn.pnota_id
            and   det.movep_id=ep.movep_id           
            and   ambito.ambito_id=pn.ambito_id 
            and   bil.ente_proprietario_id=p_ente_prop_id
            and   per.anno::integer=v_anno_int
            and   stato.pnota_stato_code='D'            
            and   ambito.ambito_code='AMBITO_GSA'    
            and   ((p_data_pnota_da is NOT NULL and 
    				trunc(pn.pnota_dataregistrazionegiornale) between 
    					  p_data_pnota_da and p_data_pnota_a) OR
            p_data_pnota_da IS NULL)                  
            and   pn.data_cancellazione is null
            and   pn.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   ep.data_cancellazione is null
            and   ep.validita_fine is null
            and   det.data_cancellazione is null
            and   det.validita_fine is null
            group by det.pdce_conto_id)      
insert into siac_rep_ce_sp_gsa                  
select voci.classif_id::integer, 
		voci.classif_code::varchar,
        voci.classif_desc::varchar,
        voci.livello::integer,
        voci.padre::varchar,
        voci.foglia::varchar,
        voci.classif_tipo_code::varchar,
        COALESCE(conti.pdce_conto_code,'')::varchar,
        COALESCE(conti.pdce_conto_desc,'')::varchar,
        COALESCE(replace(conti.pdce_conto_code,'.',''),'')::varchar,
        COALESCE(conti.pdce_fam_code,'')::varchar,
        COALESCE(movimenti.importo_dare,0)::numeric,
        COALESCE(movimenti.importo_avere,0)::numeric,
        --PP OP RE = Avere
        	--'PP','OP','OA','RE' = Ricavi
        case when UPPER(conti.pdce_fam_segno) ='AVERE' then 
        	COALESCE(movimenti.importo_avere,0) - COALESCE(movimenti.importo_dare,0)
        	--AP OA CE = Dare
            --'AP','CE' = Costi 
        else COALESCE(movimenti.importo_dare,0) - COALESCE(movimenti.importo_avere,0)
        end ::numeric,
        p_ente_prop_id::integer,
        user_table::varchar
from voci 
	left join conti 
    	on voci.classif_id_foglia = conti.classif_id              
	left join movimenti
    	on conti.pdce_conto_id=movimenti.pdce_conto_id
order by voci.classif_code;

  
--inserisco i record per i totali parziali
insert into siac_rep_ce_sp_gsa
values (0,'AZZ999',' D) TOTALE ATTIVO',1,'SPA_CODBIL_GSA','','S','','','','',
	0,0,0,p_ente_prop_id,user_table);
    
insert into siac_rep_ce_sp_gsa
values (0,'PZZ999',' F) TOTALE PASSIVO E PATRIMONIO NETTO',1,'SPP_CODBIL_GSA','','S','','','','',
	0,0,0,p_ente_prop_id,user_table);
        
    
RTN_MESSAGGIO:='Lettura livello massimo.';
--leggo qual e' il massimo livello per le voci di conto NON "foglia".
maxLivello:=0;
SELECT max(a.livello_codifica) 
	into maxLivello
from siac_rep_ce_sp_gsa a
where a.foglia='N'
	and a.utente = user_table
	and a.ente_proprietario_id = p_ente_prop_id;
    
raise notice 'maxLivello = %', maxLivello;

RTN_MESSAGGIO:='Ciclo sui livelli';
--ciclo sui livelli partendo dal massimo in quanto devo ricostruire
--al contrario gli importi per i conti che non sono "foglia".
for conta_livelli in reverse maxLivello..1
loop     
	RTN_MESSAGGIO:='Ciclo sui conti non foglia.';
	raise notice 'conta_livelli = %', conta_livelli;
    	--ciclo su tutti i conti non "foglia" del livello che sto gestendo.
    for classifGestione IN
    	select a.cod_voce, a.classif_id
        from siac_rep_ce_sp_gsa a
        where a.foglia='N'
          and a.livello_codifica=conta_livelli
          and a.utente = user_table
          and a.ente_proprietario_id = p_ente_prop_id
     	order by a.cod_voce
     loop
        v_imp_dare:=0;
        v_imp_avere:=0;
        RTN_MESSAGGIO:='Calcolo importi.';
        
        	--calcolo gli importi come somma dei suoi figli.
        select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
        	into v_imp_dare, v_imp_avere, v_imp_saldo
        from siac_rep_ce_sp_gsa a
        where a.padre=classifGestione.cod_voce
         	and a.utente = user_table
          	and a.ente_proprietario_id = p_ente_prop_id;
        
        raise notice 'codice_voce = % - importo_dare= %, importo_avere = %', 
        	classifGestione.cod_voce, v_imp_dare,v_imp_avere;
        RTN_MESSAGGIO:='Update importi.';
        
            --aggiorno gli importi 
        update siac_rep_ce_sp_gsa a
        	set imp_dare=v_imp_dare,
            	imp_avere=v_imp_avere,
                imp_saldo=v_imp_saldo
        where cod_voce=classifGestione.cod_voce
        	and utente = user_table
          	and ente_proprietario_id = p_ente_prop_id;
            
     end loop; --loop voci NON "foglie" del livello gestito.     
end loop; --loop livelli

--devo aggiornare alcuni importi totali secondo le seguenti formule.

--AZZ999= AAZ999+ABZ999+ACZ999
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('AAZ999','ABZ999','ACZ999')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare,
          imp_avere=v_imp_avere,
          imp_saldo=v_imp_saldo
where a.cod_voce= 'AZZ999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;
                   
--PZZ999= PAZ999+PBZ999+PCZ999+PDZ999+PEZ999
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('PAZ999','PBZ999','PCZ999','PDZ999','PEZ999')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare,
          imp_avere=v_imp_avere,
          imp_saldo=v_imp_saldo
where a.cod_voce= 'PZZ999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;
    
    /*
--CZ9999= CA0010+CA0050-CA0110-CA0150    
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
v_imp_dare_meno:=0;
v_imp_avere_meno:=0;
v_imp_saldo_meno:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('CA0010','CA0050')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;    
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare_meno, v_imp_avere_meno, v_imp_saldo_meno
from siac_rep_ce_sp_gsa a
where a.cod_voce in('CA0110','CA0150')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;     
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare-v_imp_dare_meno,
          imp_avere=v_imp_avere-v_imp_avere_meno,
          imp_saldo=v_imp_saldo-v_imp_saldo_meno
where a.cod_voce= 'CZ9999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;  
    */
    
        
--restituisco i dati presenti sulla tabella di appoggio.
return query
select tutto.classif_id::integer, 
    tutto.cod_voce::varchar,
    tutto.descrizione_voce::varchar,
    tutto.livello_codifica::integer,
    tutto.padre::varchar,
    tutto.foglia::varchar,
    tutto.pdce_conto_code::varchar,
    tutto.pdce_conto_descr::varchar,
    tutto.pdce_conto_numerico::varchar,
    tutto.pdce_fam_code::varchar,
    tutto.imp_dare::numeric,
    tutto.imp_avere::numeric,
    tutto.imp_saldo::numeric,
	COALESCE(config.segno,1)::integer segno, 
    COALESCE(config.titolo,'') titolo,
    tutto.classif_tipo_code::varchar,
    case when tutto.livello_codifica = 1 then left(tutto.cod_voce,2)||'0000'
    	else tutto.cod_voce end::varchar,
    ''::varchar
  /*  case when tutto.cod_voce='AAZ999' then 'AA0000'
    	else case when tutto.cod_voce='ABZ999' then 'AB0000' 
        else case when tutto.cod_voce='ACZ999' then 'AC0000' 
        else case when tutto.cod_voce='ADZ999' then 'AD0000'
        else case when tutto.cod_voce='PAZ999' then 'PA0000' 
    	else case when tutto.cod_voce='PBZ999' then 'PB0000'
        else case when tutto.cod_voce='PZZ999' then 'PFA00' 
        else case when tutto.cod_voce='PEZ999' then 'PE0000'
        else case when tutto.cod_voce='PFZ999' then 'PF0000'        
        else tutto.cod_voce end end end end end end end end end::varchar */
from (select a.classif_id::integer, 
  a.cod_voce::varchar cod_voce,
  a.descrizione_voce::varchar,
  a.livello_codifica::integer,
  a.padre::varchar,
  a.foglia::varchar,
  a.classif_tipo_code,
  COALESCE(a.pdce_conto_code,'')::varchar pdce_conto_code,
  COALESCE(a.pdce_conto_descr,'')::varchar pdce_conto_descr,
  COALESCE(a.pdce_conto_numerico,'')::varchar pdce_conto_numerico,
  COALESCE(a.pdce_fam_code,'')::varchar pdce_fam_code,
  COALESCE(a.imp_dare,0)::numeric imp_dare,
  COALESCE(a.imp_avere,0)::numeric imp_avere,
  COALESCE(a.imp_saldo,0)::numeric imp_saldo
from siac_rep_ce_sp_gsa a
where a.utente = user_table
	and a.ente_proprietario_id = p_ente_prop_id
    and ((p_cod_bilancio is null OR p_cod_bilancio = '') OR
    	 (p_cod_bilancio is not null and p_cod_bilancio <> '' and
          (a.cod_voce = p_cod_bilancio OR a.padre = p_cod_bilancio)))    
UNION
select b.classif_id::integer, 
  b.cod_voce::varchar cod_voce,
  b.descrizione_voce::varchar,
  b.livello_codifica::integer,
  b.padre::varchar,
  b.foglia::varchar,
  b.classif_tipo_code::varchar,
  ''::varchar pdce_conto_code,
  ''::varchar pdce_conto_descr,
  ''::varchar pdce_conto_numerico,
  ''::varchar pdce_fam_code,
  COALESCE(sum(b.imp_dare),0)::numeric imp_dare,
  COALESCE(sum(b.imp_avere),0)::numeric imp_avere,
  COALESCE(sum(b.imp_saldo),0)::numeric imp_saldo
from siac_rep_ce_sp_gsa b
where b.utente = user_table
	and b.ente_proprietario_id = p_ente_prop_id
    and b.foglia='S'
    and ((p_cod_bilancio is null OR p_cod_bilancio = '') OR
    	 (p_cod_bilancio is not null and p_cod_bilancio <> '' and
          (b.cod_voce = p_cod_bilancio OR b.padre = p_cod_bilancio)))
    and b.classif_id not in (select c.classif_id
    		from siac_rep_ce_sp_gsa c
            where c.utente = user_table
				and c.ente_proprietario_id = p_ente_prop_id
                and c.pdce_conto_code ='')
group by b.classif_id, b.cod_voce, b.descrizione_voce, b.livello_codifica,
  b.padre, b.foglia, b.classif_tipo_code) tutto 
  left join (select conf.cod_voce, conf.titolo, conf.segno
  			 from siac_t_config_rep_ce_sp_gsa conf
             where conf.bil_id=id_bil
             and conf.tipo_report = 'SP'
             and conf.data_cancellazione IS NULL) config
  	on tutto.cod_voce=config.cod_voce   
order by 2,6;
    
delete from siac_rep_ce_sp_gsa where utente = user_table;


raise notice '2 - %' , clock_timestamp()::text;
raise notice 'fine OK';

  EXCEPTION
  WHEN no_data_found THEN
  raise notice 'nessun dato trovato per rendiconto gestione GSA';
  return;
  WHEN others  THEN
  RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
  return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

--SIAC-8181 - Maurizio - FINE


-- SIAC-7905
ALTER TABLE siac.siac_t_xbrl_report ADD xbrl_rep_xsd_header text NULL;
-- fine 7905