/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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
CREATE OR REPLACE FUNCTION siac.fnc_pagopa_t_elaborazione_riconc(enteproprietarioid integer, loginoperazione character varying, dataelaborazione timestamp without time zone, OUT outpagopaelabid integer, OUT outpagopaelabprecid integer, OUT codicerisultato integer, OUT messaggiorisultato character varying)
 RETURNS record
 AS $body$
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
   
   -- SIAC-8276 - inizio 
   strMessaggio:='Verifica esistenza file duplicati.';
   select count(*)  into codResult 
   from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato
   where stato.ente_proprietario_id=enteProprietarioId
   and   stato.file_pagopa_stato_code not in ( 'ANNULLATO','RIFIUTATO')
   and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
   and   file.file_pagopa_anno in (annoBilancio_ini,annoBilancio)
   and file.data_cancellazione is null
   group by file.file_pagopa_id_flusso
   having count(*)>1;

   if codResult is not null then
           outPagoPaElabId:=-1;
           outPagoPaElabPrecId:=-1;
           messaggioRisultato:=upper(strMessaggioFinale||' File duplicati esistenti.');
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
   
   -- SIAC-8276 - fine
   

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