/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

-- 04.10.2022 Sofia - Jira SIAC-8816 - inizio 
drop function if exists siac.fnc_fasi_bil_gest_apertura_programmi_elabora
(
fasebilelabid integer, 
enteproprietarioid integer, 
annobilancio integer, 
tipoapertura varchar, 
loginoperazione varchar, 
dataelaborazione timestamp without time zone, 
ribalta_coll_mov boolean, 
OUT codicerisultato integer, 
OUT messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_programmi_elabora
(
fasebilelabid integer, 
enteproprietarioid integer, 
annobilancio integer, 
tipoapertura varchar, 
loginoperazione varchar, 
dataelaborazione timestamp without time zone, 
ribalta_coll_mov boolean DEFAULT true, 
OUT codicerisultato integer, 
OUT messaggiorisultato varchar
)
RETURNS record
AS $body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;


    bilancioElabId                   integer:=null;

    APE_GEST_PROGRAMMI    	    	 CONSTANT varchar:='APE_GEST_PROGRAMMI';

    P_FASE							 CONSTANT varchar:='P';
    G_FASE					    	 CONSTANT varchar:='G';

	STATO_AN 			    	     CONSTANT varchar:='AN';

	-- 21.01.2022 Sofia Jira SIAC-8536
    FL_RIL_FPV_ATTR                  CONSTANT varchar:='FlagRilevanteFPV';
    FlagRilevanteFPVAttrId           integer:=NULL;

    numeroProgr                      integer:=null;
    numeroCronop					 integer:=null;

     -- 30.07.2019 Sofia siac-6934
    flagDaRiaccAttrId                integer:=null;
    annoRiaccAttrId                  integer:=null;
    numeroRiaccAttrId                integer:=null;

   
   
BEGIN

   codiceRisultato:=null;
   messaggioRisultato:=null;

   dataInizioVal:= clock_timestamp();


   strmessaggiofinale:='Apertura Programmi-Cronoprogrammi di tipo '||tipoApertura||' per annoBilancio='||annoBilancio::varchar||'. Elaborazione.';


    codResult:=null;
    strMessaggio:='Verifica stato fase_bil_t_elaborazione.';
    select 1  into codResult
    from fase_bil_t_elaborazione fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_elab_esito like 'IN-%'
    and   fase.data_cancellazione is null;

    if codResult is null then
      raise exception ' Nessuna elaborazione in corso [IN-n].';
    end if;


    codResult:=null;
    strMessaggio:='Verifica esistenza programmi da creare in fase_bil_t_programmi.';
    select 1 into codResult
    from fase_bil_t_programmi fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null;

    if codResult is null then
--      raise exception ' Nessun  programma da creare.';
      -- 10.09.2019 Sofia SIAC-7023
      codiceRisultato:=0;
      messaggioRisultato:=strMessaggio||' Nessun  programma da creare.';
      return;
    end if;


   strMessaggio:='Inserimento LOG.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;


   strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
   select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
   from siac_t_bil bil, siac_t_periodo per
   where bil.ente_proprietario_id=enteProprietarioId
   and   per.periodo_id=bil.periodo_id
   and   per.anno::INTEGER=annoBilancio
   and   bil.data_cancellazione is null
   and   per.data_cancellazione is null;

   strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
   select bil.bil_id , per.periodo_id into strict bilancioPrecId, periodoPrecId
   from siac_t_bil bil, siac_t_periodo per
   where bil.ente_proprietario_id=enteProprietarioId
   and   per.periodo_id=bil.periodo_id
   and   per.anno::INTEGER=annoBilancio-1
   and   bil.data_cancellazione is null
   and   per.data_cancellazione is null;



   if tipoApertura=P_FASE THEN
   	bilancioElabId:=bilancioPrecId;
   else
   	bilancioElabId:=bilancioId;
   end if;

   -- 30.07.2019 Sofia siac-6934
   strMessaggio:='Lettura identificativi attributi riaccertamento.';
   SELECT attr.attr_id
   INTO   flagDaRiaccAttrId
   FROM   siac_t_attr attr
   WHERE  attr.attr_code ='flagDaRiaccertamento'
   AND    attr.ente_proprietario_id = enteproprietarioid;

   SELECT attr.attr_id
   INTO   annoRiaccAttrId
   FROM   siac_t_attr attr
   WHERE  attr.attr_code ='annoRiaccertato'
   AND    attr.ente_proprietario_id = enteproprietarioid;

   SELECT attr.attr_id
   INTO   numeroRiaccAttrId
   FROM   siac_t_attr attr
   WHERE  attr.attr_code ='numeroRiaccertato'
   AND    attr.ente_proprietario_id = enteproprietarioid;

  
  	
   -- 21.01.2022 Sofia Jira SIAC-8536
   strMessaggio:='Lettura identificativo attributo FlagRilevanteFPV.';
   SELECT attr.attr_id
   INTO   FlagRilevanteFPVAttrId
   FROM   siac_t_attr attr
   WHERE  attr.attr_code =FL_RIL_FPV_ATTR
   AND    attr.ente_proprietario_id = enteproprietarioid;
  
   strMessaggio:='Inizio inserimento dati programmi da  fase_bil_t_programmi - inizio.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;

   -- siac_t_programma

   strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_t_programma].';
   insert into siac_t_programma
   (
   	 programma_code,
	 programma_desc,
     programma_tipo_id,
     bil_id,
     programma_data_gara_indizione,
	 programma_data_gara_aggiudicazione,
	 investimento_in_definizione,
     programma_responsabile_unico,
	 programma_spazi_finanziari,
     programma_affidamento_id,
     login_operazione,
     validita_inizio,
     ente_proprietario_id
   )
   select  progr.programma_code,
           progr.programma_desc,
           tipo.programma_tipo_id,
           bilancioId,
           progr.programma_data_gara_indizione,
		   progr.programma_data_gara_aggiudicazione,
	   	   progr.investimento_in_definizione,
	       progr.programma_responsabile_unico,
	   	   progr.programma_spazi_finanziari,
	       progr.programma_affidamento_id,
           loginOperazione||'@'||fase.fase_bil_programma_id::varchar,
           clock_timestamp(),
           progr.ente_proprietario_id
   from fase_bil_t_programmi fase,siac_t_programma progr,
        siac_d_programma_tipo tipo
   where fase.fase_bil_elab_id=faseBilElabId
   and   progr.programma_id=fase.programma_id
   and   fase.fl_elab='N'
   and   tipo.ente_proprietario_id=progr.ente_proprietario_id
   and   tipo.programma_tipo_code=tipoApertura
   and   fase.data_cancellazione is null;

   GET DIAGNOSTICS numeroProgr = ROW_COUNT;


   strMessaggio:='Numero di programmi inseriti='||coalesce(numeroProgr,0)::varchar||'.';
   raise notice '%', strMessaggio;
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;

   -- inserimento dati programmi
   if coalesce(numeroProgr,0)!=0 then
    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi - aggiornamento fase_bil_t_programmi.';
    codResult:=null;
    update fase_bil_t_programmi fase
    set    programma_new_id=progr.programma_id,
           fl_elab='S'
    from   siac_t_programma progr
    where  fase.fase_bil_elab_id=faseBilElabId
    and    fase.fl_elab='N'
    and    progr.ente_proprietario_id=enteProprietarioId
    and    progr.bil_id=bilancioId -- 03.12.2021 Sofia SIAC-SIAC-8470
    and    progr.login_operazione like loginOperazione||'@%'
    and    substring(progr.login_operazione from position ('@' in progr.login_operazione)+1)::integer=fase.fase_bil_programma_id
    and    fase.data_cancellazione is null
    and    progr.data_cancellazione is null
    and    progr.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if coalesce(codResult,0)!=coalesce(numeroProgr,0) then
     raise exception ' Il numero di aggiornamenti non corrisponde al numero di programmi inseriti.';
    end if;


    -- siac_r_programma_stato
    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_r_programma_stato].';
    codResult:=null;
    insert into siac_r_programma_stato
    (
   	 programma_id,
     programma_stato_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select fase.programma_new_id,
           rs.programma_stato_id,
           clock_timestamp(),
           loginOperazione,
           fase.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_r_programma_stato rs
    where fase.fase_bil_elab_id=faseBilElabId
    and   rs.programma_id=fase.programma_id
    and   fase.programma_new_id is not null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   fase.data_cancellazione is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if coalesce(codResult,0)!=0 and coalesce(numeroProgr,0)=0 then
	   raise exception ' Il numero di stati inseriti non corrisponde al numero di programmi inseriti.';
    end if;
    raise notice '% numIns=%', strMessaggio,codResult;



    -- siac_r_programma_class
    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_r_programma_class].';
    codResult:=null;
    insert into siac_r_programma_class
    (
   	 programma_id,
     classif_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select fase.programma_new_id,
           rc.classif_id,
           clock_timestamp(),
           loginOperazione,
           fase.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_r_programma_class rc,siac_t_class c
    where fase.fase_bil_elab_id=faseBilElabId
    and   rc.programma_id=fase.programma_id
    and   c.classif_id=rc.classif_id
    and   fase.programma_new_id is not null
    and   c.data_cancellazione is null
    and   rc.data_cancellazione is null
    and   rc.validita_fine is null
    and   fase.data_cancellazione is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice '% numIns=%', strMessaggio,codResult;

 

    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_r_programma_attr].';
    -- siac_r_programma_attr
    codResult:=null;
    insert into siac_r_programma_attr
    (
   	 programma_id,
     attr_id,
     boolean,
     testo,
     percentuale,
     numerico,
     tabella_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select fase.programma_new_id,
   	       rattr.attr_id,
---   	       rattr.boolean     -- 21.01.2022 Sofia Jira SIAC-8563
   	       ( CASE WHEN tipoapertura=P_FASE AND rattr.attr_id=FlagRilevanteFPVAttrId THEN 'N'
   	         ELSE  rattr.boolean END 
   	       )  ,     -- 21.01.2022 Sofia Jira SIAC-8563
		   rattr.testo,
		   rattr.percentuale,
	       rattr.numerico,
	       rattr.tabella_id,
           clock_timestamp(),
           loginOperazione,
           fase.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_r_programma_attr rattr
    where fase.fase_bil_elab_id=faseBilElabId
    and   rattr.programma_id=fase.programma_id
    and   fase.programma_new_id is not null
    and   rattr.data_cancellazione is null
    and   rattr.validita_fine is null
    and   fase.data_cancellazione is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice '% numIns=%', strMessaggio,codResult;

   
   
    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_r_programma_atto_amm].';
    -- siac_r_programma_atto_amm
    codResult:=null;
    insert into siac_r_programma_atto_amm
    (
     programma_id,
     attoamm_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select fase.programma_new_id,
	       ratto.attoamm_id,
           clock_timestamp(),
           loginOperazione,
           fase.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_r_programma_atto_amm ratto
    where fase.fase_bil_elab_id=faseBilElabId
    and   ratto.programma_id=fase.programma_id
    and   fase.programma_new_id is not null
    and   ratto.data_cancellazione is null
    and   ratto.validita_fine is null
    and   fase.data_cancellazione is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice '% numIns=%', strMessaggio,codResult;
  end if;




  strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi - fine .';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
   	raise exception ' Errore in inserimento LOG.';
  end if;
  -- fine inserimento dati programmi

  strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop - verifica dati creare [fase_bil_t_cronop].';

  codResult:=null;
  select 1 into codResult
  from fase_bil_t_programmi fasep, fase_bil_t_cronop fasec
  where fasep.fase_bil_elab_id=faseBilElabId
  and   fasep.programma_new_id is not null
  and   fasep.fl_elab='S'
  and   fasec.fase_bil_elab_id=faseBilElabId
  and   fasec.programma_id=fasep.programma_id
  and   fasec.fl_elab='N'
  and   fasep.data_cancellazione is null
  and   fasec.data_cancellazione is null;

  raise notice '% numdaIns=%', strMessaggio,codResult;


  if codResult is not null then

   	strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop da inserire numero='||codResult::varchar||'- inizio.';
	codResult:=null;
	insert into fase_bil_t_elaborazione_log
	(fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
	)
    values
    (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;


    strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_t_cronop].';
    -- siac_t_cronop
   	insert into siac_t_cronop
    (
    	 cronop_code,
	     cronop_desc,
	     programma_id,
	     bil_id,
	     usato_per_fpv,
         cronop_data_approvazione_fattibilita,
	     cronop_data_approvazione_programma_def,
		 cronop_data_approvazione_programma_esec,
		 cronop_data_avvio_procedura,
		 cronop_data_aggiudicazione_lavori,
		 cronop_data_inizio_lavori,
		 cronop_data_fine_lavori,
		 cronop_giorni_durata,
		 cronop_data_collaudo,
	     gestione_quadro_economico,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
    )
    select
         cronop.cronop_code,
	     cronop.cronop_desc,
	     fasep.programma_new_id,
	     bilancioId,
--	     cronop.usato_per_fpv,      -- 04.10.2022 Sofia Jira SIAC-8816
   	       ( CASE WHEN tipoapertura=P_FASE  THEN false
   	         ELSE  cronop.usato_per_fpv END 
   	       )  ,     -- 04.10.2022 Sofia Jira SIAC-8816
         cronop.cronop_data_approvazione_fattibilita,
	     cronop.cronop_data_approvazione_programma_def,
		 cronop.cronop_data_approvazione_programma_esec,
		 cronop.cronop_data_avvio_procedura,
		 cronop.cronop_data_aggiudicazione_lavori,
		 cronop.cronop_data_inizio_lavori,
		 cronop.cronop_data_fine_lavori,
		 cronop.cronop_giorni_durata,
		 cronop.cronop_data_collaudo,
	     cronop.gestione_quadro_economico,
         clock_timestamp(),
         loginOperazione||'@'||fasec.fase_bil_cronop_id::varchar,
         cronop.ente_proprietario_id
    from fase_bil_t_programmi fasep, fase_bil_t_cronop fasec,siac_t_cronop cronop
    where fasep.fase_bil_elab_id=faseBilElabId
    and   fasep.programma_new_id is not null
    and   fasep.fl_elab='S'
    and   fasec.fase_bil_elab_id=faseBilElabId
    and   fasec.programma_id=fasep.programma_id
    and   fasec.fl_elab='N'
    and   cronop.cronop_id=fasec.cronop_id
    and   fasep.data_cancellazione is null
    and   fasec.data_cancellazione is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null;
    GET DIAGNOSTICS numeroCronop = ROW_COUNT;

    if coalesce(numeroCronop,0)!=0 then

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop inseriti numero='||coalesce(numeroCronop,0)::varchar||'.';
	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
	 (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
	 )
     values
     (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;
     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  - aggiornamento fase_bil_t_cronop.';
     codResult:=null;
     update fase_bil_t_cronop fase
     set    cronop_new_id=cronop.cronop_id,
           fl_elab='S'
     from   siac_t_cronop cronop
     where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='N'
     and    cronop.ente_proprietario_id=enteProprietarioId
     and    cronop.login_operazione like loginOperazione||'@%'
     and    substring(cronop.login_operazione from position ('@' in cronop.login_operazione)+1)::integer=fase.fase_bil_cronop_id
     and    fase.data_cancellazione is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     if coalesce(codResult,0)!=coalesce(numeroCronop,0) then
	      raise exception ' Il numero di aggiornamenti non corrisponde al numero di crono-programmi inseriti.';
     end if;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_stato].';
     -- siac_r_cronop_stato
     codResult:=null;
     insert into siac_r_cronop_stato
     (
    	cronop_id,
        cronop_stato_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
     )
     select fase.cronop_new_id,
            rs.cronop_stato_id,
            clock_timestamp(),
            loginOperazione,
            rs.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_r_cronop_stato rs
   	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    rs.cronop_id=fase.cronop_id
     and    fase.data_cancellazione is null
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     if coalesce(codResult,0)!=coalesce(numeroCronop,0) then
      raise exception ' Il numero di stati inseriti non corrisponde al numero di crono-programmi inseriti.';
     end if;


     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_atto_amm].';
     -- siac_r_cronop_atto_amm
     codResult:=null;
     insert into siac_r_cronop_atto_amm
     (
    	cronop_id,
        attoamm_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
     )
     select fase.cronop_new_id,
            ratto.attoamm_id,
            clock_timestamp(),
            loginOperazione,
            ratto.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_r_cronop_atto_amm ratto
   	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    ratto.cronop_id=fase.cronop_id
     and    fase.data_cancellazione is null
     and    ratto.data_cancellazione is null
     and    ratto.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
/*     if coalesce(codResult,0)!=coalesce(numeroCronop,0) then
      raise exception ' Il numero di stati inseriti non corrisponde al numero di crono-programmi inseriti.';
     end if;*/

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_attr].';

     -- siac_r_cronop_attr
     codResult:=null;
     insert into siac_r_cronop_attr
     (
    	cronop_id,
		attr_id,
	    boolean,
	    testo,
    	percentuale,
	    numerico,
    	tabella_id,
	    validita_inizio,
    	login_operazione,
	    ente_proprietario_id
     )
     select
        fase.cronop_new_id,
        rattr.attr_id,
	    rattr.boolean,
    	rattr.testo,
	    rattr.percentuale,
	    rattr.numerico,
    	rattr.tabella_id,
	    clock_timestamp(),
    	loginOperazione,
	    rattr.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_r_cronop_attr rattr
 	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    rattr.cronop_id=fase.cronop_id
     and    fase.data_cancellazione is null
     and    rattr.data_cancellazione is null
     and    rattr.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     raise notice '% numdaIns=%', strMessaggio,codResult;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_t_cronop_elem].';
	 codResult:=null;
     -- siac_t_cronop_elem
     insert into siac_t_cronop_elem
     (
	    cronop_elem_code,
	    cronop_elem_code2,
	    cronop_elem_code3,
	    cronop_elem_desc,
	    cronop_elem_desc2,
	    cronop_id,
--	    cronop_elem_id_padre,
        cronop_elem_is_ava_amm,
	    elem_tipo_id,
	    ordine,
	    livello,
   	    login_operazione,
	    validita_inizio,
	    ente_proprietario_id
     )
     select
        celem.cronop_elem_code,
	    celem.cronop_elem_code2,
	    celem.cronop_elem_code3,
	    celem.cronop_elem_desc,
	    celem.cronop_elem_desc2,
        fase.cronop_new_id,
--        cronop_elem_id_padre,
	    celem.cronop_elem_is_ava_amm,
        tiponew.elem_tipo_id,
        celem.ordine,
	    celem.livello,
        loginOperazione||'@'||celem.cronop_elem_id::varchar,
        clock_timestamp(),
        celem.ente_proprietario_id
 	 from fase_bil_t_cronop fase,siac_t_cronop_elem celem,
          siac_d_bil_elem_tipo tipo, siac_d_bil_elem_tipo tiponew
 	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    celem.cronop_id=fase.cronop_id
     and    tipo.elem_tipo_id=celem.elem_tipo_id
     and    tiponew.ente_proprietario_id=tipo.ente_proprietario_id
     and    (case
              when tipoApertura=P_FASE and tipo.elem_tipo_code='CAP-UG' then tiponew.elem_tipo_code='CAP-UP'
    		  when tipoApertura=P_FASE and tipo.elem_tipo_code='CAP-EG' then tiponew.elem_tipo_code='CAP-EP'
              when tipoApertura=G_FASE and tipo.elem_tipo_code='CAP-UP' then tiponew.elem_tipo_code='CAP-UG'
              when tipoApertura=G_FASE and tipo.elem_tipo_code='CAP-EP' then tiponew.elem_tipo_code='CAP-EG'
            end
            )
     and    fase.data_cancellazione is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
	 raise notice '% numdaIns=%', strMessaggio,codResult;






     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_elem_class].';
	 codResult:=null;
	 -- siac_r_cronop_elem_class
     insert into siac_r_cronop_elem_class
     (
  	  	cronop_elem_id,
	    classif_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
     )
     select celem.cronop_elem_id,
            c.classif_id,
            clock_timestamp(),
            loginOperazione,
            c.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_t_cronop_elem celem,siac_r_cronop_elem_class r,siac_t_class c
	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    celem.cronop_id=fase.cronop_new_id
     and    celem.login_operazione like loginOperazione||'@%'
     and    r.cronop_elem_id=substring(celem.login_operazione from position('@' in celem.login_operazione)+1)::integer
     and    c.classif_id=r.classif_id
     and    c.data_cancellazione is null
     and    r.data_cancellazione is null
     and    r.validita_fine is null
     and    fase.data_cancellazione is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
	 raise notice '% numdaIns=%', strMessaggio,codResult;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_elem_bil_elem].';
	 codResult:=null;
     -- siac_r_cronop_elem_bil_elem
     insert into siac_r_cronop_elem_bil_elem
     (
	    cronop_elem_id,
	    elem_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
     )
     select celem.cronop_elem_id,
            enew.elem_id,
            clock_timestamp(),
            loginOperazione,
            enew.ente_proprietario_id
     from  fase_bil_t_cronop fase,siac_t_cronop_elem celem,siac_r_cronop_elem_bil_elem r,
           siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
           siac_t_bil_elem enew,siac_d_bil_elem_tipo tiponew,
           siac_r_bil_elem_stato rs,siac_d_bil_elem_Stato stato
     where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    celem.cronop_id=fase.cronop_new_id
     and    celem.login_operazione like loginOperazione||'@%'
     and    r.cronop_elem_id=substring(celem.login_operazione from position('@' in celem.login_operazione)+1)::integer
     and    e.elem_id=r.elem_id
     and    tipo.elem_tipo_id=e.elem_tipo_id
     and    enew.bil_id=bilancioId
     and    enew.elem_code=e.elem_code
     and    enew.elem_code2=e.elem_code2
     and    enew.elem_code3=e.elem_code3
     and    tiponew.elem_tipo_id=enew.elem_tipo_id
     and    (case
              when tipoApertura=P_FASE and tipo.elem_tipo_code='CAP-UG' then tiponew.elem_tipo_code='CAP-UP'
    		  when tipoApertura=P_FASE and tipo.elem_tipo_code='CAP-EG' then tiponew.elem_tipo_code='CAP-EP'
              when tipoApertura=G_FASE and tipo.elem_tipo_code='CAP-UP' then tiponew.elem_tipo_code='CAP-UG'
              when tipoApertura=G_FASE and tipo.elem_tipo_code='CAP-EP' then tiponew.elem_tipo_code='CAP-EG'
            end
            )
     and    rs.elem_id=enew.elem_id
     and    stato.elem_stato_id=rs.elem_stato_id
     and    stato.elem_stato_code!='AN'
     and    r.data_cancellazione is null
     and    r.validita_fine is null
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    fase.data_cancellazione is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null
     and    e.data_cancellazione is null
     and    enew.data_cancellazione is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
	 raise notice '% numdaIns=%', strMessaggio,codResult;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_t_cronop_elem_det].';
     codResult:=null;
     -- siac_t_cronop_elem_det
     insert into siac_t_cronop_elem_det
     (
	    cronop_elem_det_desc,
	    cronop_elem_id,
	    cronop_elem_det_importo,
	    elem_det_tipo_id,
	    periodo_id,
	    anno_entrata,
        quadro_economico_id_padre,
	    quadro_economico_id_figlio,
	    quadro_economico_det_importo,
        login_operazione,
        validita_inizio,
        ente_proprietario_id
     )
     select
         det.cronop_elem_det_desc,
	     celem.cronop_elem_id,
	     det.cronop_elem_det_importo,
	     det.elem_det_tipo_id,
	     det.periodo_id,
	     det.anno_entrata,
         det.quadro_economico_id_padre,
	     det.quadro_economico_id_figlio,
	     det.quadro_economico_det_importo,
         loginOperazione,
         clock_timestamp(),
         det.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_t_cronop_elem celem, siac_t_cronop_elem_det det
     where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    celem.cronop_id=fase.cronop_new_id
     and    celem.login_operazione like loginOperazione||'@%'
     and    det.cronop_elem_id=substring(celem.login_operazione from position('@' in celem.login_operazione)+1)::integer
     and    det.data_cancellazione is null
     and    det.validita_fine is null
     and    fase.data_cancellazione is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     raise notice '% numdaIns=%', strMessaggio,codResult;
   end if;
   strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop - fine.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
    validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
   	raise exception ' Errore in inserimento LOG.';
   end if;

 end if;

 --- inserimento collegamenti tra programma e siac_t_movgest_Ts [siac_r_movgest_ts_programma]
 --- inserimento collegamenti tra cronop    e siac_t_movgest_ts [siac_r_movgest_ts_cronop_elem]
 --  inserimento da effettuare solo per tipoApertura='G'
 --  quindi partendo da movimenti validi e programmi - cronop nuovi, riportare le relazioni da annoBilancioPrec
 --  convertendo gli id da annoPrec a annoBilancio
 -- 06.05.2019 Sofia siac-6255
-- if tipoApertura=G_FASE then -- tutto da rivedere
-- 06.02.2020 Sofia jira SIAC-7386 aggiunto par. non aggiornare tutti i collegamenti in caso di esecuzione da puntuale
 if tipoApertura=G_FASE and ribalta_coll_mov=true then

  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - inizio.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
    validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
  	raise exception ' Errore in inserimento LOG.';
  end if;

  -- inserimento legami aperti esistenti su impegni/accertamenti residui
  -- siac_r_movgest_ts_programma
  -- residui
  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - inserimento siac_r_movgest_ts_programma residui.';
  insert into siac_r_movgest_ts_programma
  (
  	movgest_ts_id,
    programma_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
    select query.movgest_ts_id,
           query.programma_new_id,
           clock_timestamp(),
           loginOperazione,
           enteProprietarioId
    from
    (
    with
    mov_res_anno as
    (
    select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
           (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
           mov.movgest_tipo_id,
           ts.movgest_ts_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_d_movgest_Ts_tipo tipo
    where mov.bil_id=bilancioId
    and   mov.movgest_anno::integer<annoBilancio
    and   ts.movgest_id=mov.movgest_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code in ('D','N')
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
    select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
           (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
           mov.movgest_tipo_id, r.programma_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_programma r
    where mov.bil_id=bilancioPrecId
    and   mov.movgest_anno::integer<annoBilancio
    and   ts.movgest_id=mov.movgest_id
    and   r.movgest_ts_id=ts.movgest_ts_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code in ('D','N')
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    ),
    progr as
    (
      select p.programma_id, p.programma_tipo_id, p.programma_code, p.bil_id
      from siac_t_programma p, siac_r_programma_stato rs,siac_d_programma_stato stato, siac_d_programma_tipo tipo
      where stato.ente_proprietario_id=enteProprietarioId
--      and   stato.programma_stato_code='VA'
      and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia siac-6934

      and   rs.programma_stato_id=stato.programma_stato_id
      and   p.programma_id=rs.programma_id
      and   tipo.programma_tipo_id=p.programma_tipo_id
      and   tipo.programma_tipo_code=G_FASE
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   p.data_cancellazione is null
      and   p.validita_fine is null
    )
    select mov_res_anno.movgest_ts_id,
           progr_anno.programma_id programma_new_id
    from mov_res_anno,
         mov_res_anno_prec, progr progr_anno, progr progr_anno_prec
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and   mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and   mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and   mov_res_anno.movgest_tipo_id=mov_res_anno_prec.movgest_tipo_id
    and   progr_anno_prec.programma_id=mov_res_anno_prec.programma_id
    and   progr_anno.bil_id=bilancioId
    and   progr_anno.programma_code=progr_anno_prec.programma_code
    ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_programma res.inserimenti =%', strMessaggio,codResult;
  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;

  -- pluriennali
  codResult:=null;
  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - inserimento siac_r_movgest_ts_programma pluriennali.';
  insert into siac_r_movgest_ts_programma
  (
  	movgest_ts_id,
    programma_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
    select query.movgest_ts_id,
           query.programma_new_id,
           clock_timestamp(),
           loginOperazione,
           enteProprietarioId
    from
    (
    with
    mov_pluri_anno as
    (
    select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
           ( case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
           mov.movgest_tipo_id,
           ts.movgest_ts_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_d_movgest_Ts_tipo tipo
    where mov.bil_id=bilancioId
    and   mov.movgest_anno::integer>=annoBilancio
    and   ts.movgest_id=mov.movgest_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    ),
    mov_pluri_anno_prec as
    (
    select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
           (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
           mov.movgest_tipo_id, r.programma_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_programma r
    where mov.bil_id=bilancioPrecId
    and   mov.movgest_anno::integer>=annoBilancio
    and   ts.movgest_id=mov.movgest_id
    and   r.movgest_ts_id=ts.movgest_ts_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    ),
    progr as
    (
      select p.programma_id, p.programma_tipo_id, p.programma_code, p.bil_id
      from siac_t_programma p, siac_r_programma_stato rs,siac_d_programma_stato stato, siac_d_programma_tipo tipo
      where stato.ente_proprietario_id=enteProprietarioId
--      and   stato.programma_stato_code='VA'
      and   stato.programma_stato_code!='AN'      -- 06.08.2019 Sofia siac-6934
      and   rs.programma_stato_id=stato.programma_stato_id
      and   p.programma_id=rs.programma_id
      and   tipo.programma_tipo_id=p.programma_tipo_id
      and   tipo.programma_tipo_code=G_FASE
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   p.data_cancellazione is null
      and   p.validita_fine is null
    )
    select mov_pluri_anno.movgest_ts_id,
           progr_anno.programma_id programma_new_id
    from mov_pluri_anno,
         mov_pluri_anno_prec, progr progr_anno_prec,
         progr progr_anno
    where mov_pluri_anno.movgest_anno=mov_pluri_anno_prec.movgest_anno
    and   mov_pluri_anno.movgest_numero=mov_pluri_anno_prec.movgest_numero
    and   mov_pluri_anno.movgest_subnumero=mov_pluri_anno_prec.movgest_subnumero
    and   mov_pluri_anno.movgest_tipo_id=mov_pluri_anno_prec.movgest_tipo_id
    and   progr_anno_prec.programma_id=mov_pluri_anno_prec.programma_id
    and   progr_anno.bil_id=bilancioId
    and   progr_anno.programma_code=progr_anno_prec.programma_code
    ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_programma res.inserimenti =%', strMessaggio,codResult;
  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;

  -- 30.07.2019 Sofia siac-6934
  -- riaccertati
  codResult:=null;
  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - inserimento siac_r_movgest_ts_programma riaccertati.';
  insert into siac_r_movgest_ts_programma
  (
  	movgest_ts_id,
    programma_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
    select query.movgest_ts_id,
           query.programma_new_id,
           clock_timestamp(),
           loginOperazione,
           enteProprietarioId
    from
    (
    with
    mov_riacc_anno as
    (
    with
    mov_anno as
    (
      select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
             ( case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,
           siac_r_movgest_ts_attr rattr
      where mov.bil_id=bilancioId
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   rattr.movgest_ts_id=ts.movgest_ts_id
      and   rattr.attr_id=flagDaRiaccAttrId
      and   rattr.boolean='S'
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   rattr.data_cancellazione is null
      and   rattr.validita_fine is null
    ),
    annoRiacc as
    (
    select rattr.movgest_ts_id, rattr.testo::integer annoRiacc
    from siac_r_movgest_ts_attr rattr
    where rattr.attr_id=annoRiaccAttrId
    and   rattr.testo is not null
    and   rattr.testo!='null'
    and   coalesce(rattr.testo ,'')!=''
    and   rattr.data_cancellazione is null
    and   rattr.validita_fine is null
    ),
    numeroRiacc as
    (
    select rattr.movgest_ts_id, rattr.testo::integer numeroRiacc
    from siac_r_movgest_ts_attr rattr
    where rattr.attr_id=numeroRiaccAttrId
    and   rattr.testo is not null
    and   rattr.testo!='null'
    and   coalesce(rattr.testo ,'')!=''
    and   rattr.data_cancellazione is null
    and   rattr.validita_fine is null
    )
    select  mov_anno.*, annoRiacc.annoRiacc, numeroRiacc.numeroRiacc
    from mov_anno, annoRiacc, numeroRiacc
    where mov_anno.movgest_ts_id=annoRiacc.movgest_ts_id
    and   mov_anno.movgest_ts_id=numeroRiacc.movgest_ts_id
    ),
    mov_riacc_anno_prec as
    (
    select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
           (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
           mov.movgest_tipo_id, r.programma_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_programma r
    where mov.bil_id=bilancioPrecId
    and   ts.movgest_id=mov.movgest_id
    and   r.movgest_ts_id=ts.movgest_ts_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   tipo.movgest_ts_tipo_code='T' -- non il legame ad un sub sugli attributi quindi associo solo i programmi del padre
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    ),
    progr as
    (
      select p.programma_id, p.programma_tipo_id, p.programma_code, p.bil_id
      from siac_t_programma p, siac_r_programma_stato rs,siac_d_programma_stato stato, siac_d_programma_tipo tipo
      where stato.ente_proprietario_id=enteProprietarioId
--      and   stato.programma_stato_code='VA'
      and   stato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
      and   rs.programma_stato_id=stato.programma_stato_id
      and   p.programma_id=rs.programma_id
      and   tipo.programma_tipo_id=p.programma_tipo_id
      and   tipo.programma_tipo_code=G_FASE
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   p.data_cancellazione is null
      and   p.validita_fine is null
    )
    select mov_riacc_anno.movgest_ts_id,
           progr_anno.programma_id programma_new_id
    from mov_riacc_anno,
         mov_riacc_anno_prec, progr progr_anno_prec,
         progr progr_anno
    where mov_riacc_anno.annoRiacc=mov_riacc_anno_prec.movgest_anno
    and   mov_riacc_anno.numeroRiacc=mov_riacc_anno_prec.movgest_numero
    and   mov_riacc_anno.movgest_tipo_id=mov_riacc_anno_prec.movgest_tipo_id
    and   progr_anno_prec.programma_id=mov_riacc_anno_prec.programma_id
    and   progr_anno.bil_id=bilancioId
    and   progr_anno.programma_code=progr_anno_prec.programma_code
    ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_programma res.inserimenti =%', strMessaggio,codResult;
  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;


  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop - inserimento siac_r_movgest_ts_cronop_elem  residui.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
         query.cronop_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_res_anno as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer<annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer<annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'
     and    pstato.programma_stato_code!='AN'      -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
    )
    select cronop_anno.cronop_id cronop_new_id,
           mov_res_anno.movgest_ts_id
    from mov_res_anno, mov_res_anno_prec, cronop cronop_anno, cronop cronop_anno_prec
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and   mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and   mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and   cronop_anno_prec.cronop_id=mov_res_anno_prec.cronop_id
    and   cronop_anno.bil_id=bilancioId
    and   cronop_anno.programma_code=cronop_anno_prec.programma_code
    and   cronop_anno.cronop_code=cronop_anno_prec.cronop_code
   ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem res.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;


  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop - inserimento siac_r_movgest_ts_cronop_elem  pluriennali.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
         query.cronop_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_res_anno as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer>=annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer>=annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code !='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'   -- 06.08.2019 Sofia siac-6934
     and    pstato.programma_stato_code!='AN'   -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
    )
    select cronop_anno.cronop_id cronop_new_id,
           mov_res_anno.movgest_ts_id
    from mov_res_anno, mov_res_anno_prec, cronop cronop_anno_prec, cronop cronop_anno
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and   mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and   mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and   cronop_anno_prec.cronop_id=mov_res_anno_prec.cronop_id
    and   cronop_anno.bil_id=bilancioId
    and   cronop_anno.programma_code=cronop_anno_prec.programma_code
    and   cronop_anno.cronop_code=cronop_anno_prec.cronop_code
   ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem res.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;

  --- 30.07.2019 Sofia siac-6934
  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop - inserimento siac_r_movgest_ts_cronop_elem  riaccertati.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
         query.cronop_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_riacc_anno as
    (
    with
    mov_anno as
    (
      select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_attr rattr
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   tipo.movgest_ts_tipo_code='T'
      and   rattr.movgest_ts_id=ts.movgest_ts_id
      and   rattr.attr_id=flagDaRiaccAttrId
      and   rattr.boolean='S'
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
    ),
    annoRiacc as
    (
    select rattr.movgest_ts_id, rattr.testo::integer annoRiacc
    from siac_r_movgest_ts_attr rattr
    where rattr.attr_id=annoRiaccAttrId
    and   rattr.testo is not null
    and   rattr.testo!='null'
    and   coalesce(rattr.testo ,'')!=''
    and   rattr.data_cancellazione is null
    and   rattr.validita_fine is null
    ),
    numeroRiacc as
    (
    select rattr.movgest_ts_id, rattr.testo::integer numeroRiacc
    from siac_r_movgest_ts_attr rattr
    where rattr.attr_id=numeroRiaccAttrId
    and   rattr.testo is not null
    and   rattr.testo!='null'
    and   coalesce(rattr.testo ,'')!=''
    and   rattr.data_cancellazione is null
    and   rattr.validita_fine is null
    )
    select  mov_anno.*, annoRiacc.annoRiacc, numeroRiacc.numeroRiacc
    from mov_anno, annoRiacc, numeroRiacc
    where mov_anno.movgest_ts_id=annoRiacc.movgest_ts_id
    and   mov_anno.movgest_ts_id=numeroRiacc.movgest_ts_id
    ),
    mov_riacc_anno_prec as
    (
      select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code !='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and    pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
    )
    select cronop_anno.cronop_id cronop_new_id,
           mov_riacc_anno.movgest_ts_id
    from mov_riacc_anno, mov_riacc_anno_prec, cronop cronop_anno_prec, cronop cronop_anno
    where mov_riacc_anno.annoRiacc=mov_riacc_anno_prec.movgest_anno
    and   mov_riacc_anno.numeroRiacc=mov_riacc_anno_prec.movgest_numero
    and   cronop_anno_prec.cronop_id=mov_riacc_anno_prec.cronop_id
    and   cronop_anno.bil_id=bilancioId
    and   cronop_anno.programma_code=cronop_anno_prec.programma_code
    and   cronop_anno.cronop_code=cronop_anno_prec.cronop_code
   ) query
   where
   not exists
   (select 1
    from siac_r_movgest_ts_cronop_elem r1
    where r1.movgest_ts_id=query.movgest_ts_id
    and   r1.cronop_id=query.cronop_new_id
    and   r1.cronop_elem_id is null
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
   )
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem riacc.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;


  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop dettaglio - inserimento siac_r_movgest_ts_cronop_elem  residui.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    cronop_elem_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
  	     query.cronop_new_id,
         query.cronop_elem_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_res_anno as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer<annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_elem_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer<annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is not null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop_elem as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code,
             celem.cronop_elem_id,
             coalesce(celem.cronop_elem_code,'')  cronop_elem_code,
             coalesce(celem.cronop_elem_code2,'') cronop_elem_code2,
             coalesce(celem.cronop_elem_code3,'') cronop_elem_code3,
             coalesce(celem.elem_tipo_id,0)       elem_tipo_id,
             coalesce(celem.cronop_elem_desc,'')  cronop_elem_desc,
             coalesce(celem.cronop_elem_desc2,'') cronop_elem_desc2,
             coalesce(det.periodo_id,0)           periodo_id,
             coalesce(det.cronop_elem_det_importo,0) cronop_elem_det_importo,
             coalesce(det.cronop_elem_det_desc,'') cronop_elem_det_desc,
             coalesce(det.anno_entrata,'')        anno_entrata,
             coalesce(det.elem_det_tipo_id,0)     elem_det_tipo_id
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo,
          siac_t_cronop_elem celem,siac_t_cronop_elem_det det
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    celem.cronop_id=cronop.cronop_id
     and    det.cronop_elem_id=celem.cronop_elem_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and    pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null
     and    det.data_cancellazione is null
     and    det.validita_fine is null

    )
    select cronop_elem_anno.cronop_elem_id cronop_elem_new_id,
           cronop_elem_anno.cronop_id cronop_new_id,
           mov_res_anno.movgest_ts_id
    from mov_res_anno, mov_res_anno_prec, cronop_elem cronop_elem_anno_prec, cronop_elem cronop_elem_anno
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and   mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and   mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and   cronop_elem_anno_prec.cronop_elem_id=mov_res_anno_prec.cronop_elem_id
    and   cronop_elem_anno.bil_id=bilancioId
    and   cronop_elem_anno.programma_code=cronop_elem_anno_prec.programma_code
    and   cronop_elem_anno.cronop_code=cronop_elem_anno_prec.cronop_code
    and   cronop_elem_anno.cronop_elem_code=cronop_elem_anno_prec.cronop_elem_code
    and   cronop_elem_anno.cronop_elem_code2=cronop_elem_anno_prec.cronop_elem_code2
    and   cronop_elem_anno.cronop_elem_code3=cronop_elem_anno_prec.cronop_elem_code3
    and   cronop_elem_anno.elem_tipo_id=cronop_elem_anno_prec.elem_tipo_id
    and   cronop_elem_anno.cronop_elem_desc=cronop_elem_anno_prec.cronop_elem_desc
    and   cronop_elem_anno.cronop_elem_desc2=cronop_elem_anno_prec.cronop_elem_desc2
    and   cronop_elem_anno.periodo_id=cronop_elem_anno_prec.periodo_id
    and   cronop_elem_anno.cronop_elem_det_importo=cronop_elem_anno_prec.cronop_elem_det_importo
    and   cronop_elem_anno.cronop_elem_det_desc=cronop_elem_anno_prec.cronop_elem_det_desc
    and   cronop_elem_anno.anno_entrata=cronop_elem_anno_prec.anno_entrata
    and   cronop_elem_anno.elem_det_tipo_id=cronop_elem_anno_prec.elem_det_tipo_id
    and   exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   tipo.classif_tipo_id=c.classif_tipo_id
        and   exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=tipo.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
    and not exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   tipo.classif_tipo_id=c.classif_tipo_id
        and   not exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=tipo.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
   ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem res.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;

  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop dettaglio - inserimento siac_r_movgest_ts_cronop_elem  pluriennali.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    cronop_elem_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
  	     query.cronop_new_id,
         query.cronop_elem_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_res_anno as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer>=annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_elem_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer>=annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is not null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop_elem as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code,
             celem.cronop_elem_id,
             coalesce(celem.cronop_elem_code,'')  cronop_elem_code,
             coalesce(celem.cronop_elem_code2,'') cronop_elem_code2,
             coalesce(celem.cronop_elem_code3,'') cronop_elem_code3,
             coalesce(celem.elem_tipo_id,0)      elem_tipo_id,
             coalesce(celem.cronop_elem_desc,'')  cronop_elem_desc,
             coalesce(celem.cronop_elem_desc2,'')  cronop_elem_desc2,
             coalesce(det.periodo_id,0)           periodo_id,
             coalesce(det.cronop_elem_det_importo,0) cronop_elem_det_importo,
             coalesce(det.cronop_elem_det_desc,'') cronop_elem_det_desc,
             coalesce(det.anno_entrata,'')        anno_entrata,
             coalesce(det.elem_det_tipo_id,0)     elem_det_tipo_id
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo,
          siac_t_cronop_elem celem,siac_t_cronop_elem_det det
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    celem.cronop_id=cronop.cronop_id
     and    det.cronop_elem_id=celem.cronop_elem_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and    pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null
     and    det.data_cancellazione is null
     and    det.validita_fine is null

    )
    select cronop_elem_anno.cronop_elem_id cronop_elem_new_id,
           cronop_elem_anno.cronop_id cronop_new_id,
           mov_res_anno.movgest_ts_id
    from mov_res_anno, mov_res_anno_prec, cronop_elem cronop_elem_anno_prec, cronop_elem cronop_elem_anno
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and   mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and   mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and   cronop_elem_anno_prec.cronop_elem_id=mov_res_anno_prec.cronop_elem_id
    and   cronop_elem_anno.bil_id=bilancioId
    and   cronop_elem_anno.programma_code=cronop_elem_anno_prec.programma_code
    and   cronop_elem_anno.cronop_code=cronop_elem_anno_prec.cronop_code
    and   cronop_elem_anno.cronop_elem_code=cronop_elem_anno_prec.cronop_elem_code
    and   cronop_elem_anno.cronop_elem_code2=cronop_elem_anno_prec.cronop_elem_code2
    and   cronop_elem_anno.cronop_elem_code3=cronop_elem_anno_prec.cronop_elem_code3
    and   cronop_elem_anno.elem_tipo_id=cronop_elem_anno_prec.elem_tipo_id
    and   cronop_elem_anno.cronop_elem_desc=cronop_elem_anno_prec.cronop_elem_desc
    and   cronop_elem_anno.cronop_elem_desc2=cronop_elem_anno_prec.cronop_elem_desc2
    and   cronop_elem_anno.periodo_id=cronop_elem_anno_prec.periodo_id
    and   cronop_elem_anno.cronop_elem_det_importo=cronop_elem_anno_prec.cronop_elem_det_importo
    and   cronop_elem_anno.cronop_elem_det_desc=cronop_elem_anno_prec.cronop_elem_det_desc
    and   cronop_elem_anno.anno_entrata=cronop_elem_anno_prec.anno_entrata
    and   cronop_elem_anno.elem_det_tipo_id=cronop_elem_anno_prec.elem_det_tipo_id
    and   exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=c.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
    and not exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   not exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=c.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
   ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem res.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;


  --- 31.07.2019 Sofia SIAC-6934
  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop dettaglio - inserimento siac_r_movgest_ts_cronop_elem  riaccertati.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    cronop_elem_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
  	     query.cronop_new_id,
         query.cronop_elem_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_riacc_anno as
    (
     with
     mov_anno as
     (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_attr rattr
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   tipo.movgest_ts_tipo_code='T'
      and   rattr.movgest_ts_id=ts.movgest_ts_id
      and   rattr.attr_id=flagDaRiaccAttrId
      and   rattr.boolean='S'
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   rattr.data_cancellazione is null
      and   rattr.validita_fine is null
     ),
     annoRiacc as
     (
      select rattr.movgest_ts_id, rattr.testo::integer annoRiacc
      from siac_r_movgest_ts_attr rattr
      where rattr.attr_id=annoRiaccAttrId
      and   rattr.testo is not null
      and   rattr.testo!='null'
      and   coalesce(rattr.testo ,'')!=''
      and   rattr.data_cancellazione is null
      and   rattr.validita_fine is null
     ),
     numeroRiacc as
     (
      select rattr.movgest_ts_id, rattr.testo::integer numeroRiacc
      from siac_r_movgest_ts_attr rattr
      where rattr.attr_id=numeroRiaccAttrId
      and   rattr.testo is not null
      and   rattr.testo!='null'
      and   coalesce(rattr.testo ,'')!=''
      and   rattr.data_cancellazione is null
      and   rattr.validita_fine is null
     )
     select  mov_anno.*, annoRiacc.annoRiacc, numeroRiacc.numeroRiacc
     from mov_anno, annoRiacc, numeroRiacc
     where mov_anno.movgest_ts_id=annoRiacc.movgest_ts_id
     and   mov_anno.movgest_ts_id=numeroRiacc.movgest_ts_id
    ),
    mov_riacc_anno_prec as
    (
      select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_elem_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is not null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop_elem as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code,
             celem.cronop_elem_id,
             coalesce(celem.cronop_elem_code,'')  cronop_elem_code,
             coalesce(celem.cronop_elem_code2,'') cronop_elem_code2,
             coalesce(celem.cronop_elem_code3,'') cronop_elem_code3,
             coalesce(celem.elem_tipo_id,0)       elem_tipo_id,
             coalesce(celem.cronop_elem_desc,'')  cronop_elem_desc,
             coalesce(celem.cronop_elem_desc2,'') cronop_elem_desc2,
             coalesce(det.periodo_id,0)           periodo_id,
             coalesce(det.cronop_elem_det_importo,0) cronop_elem_det_importo,
             coalesce(det.cronop_elem_det_desc,'') cronop_elem_det_desc,
             coalesce(det.anno_entrata,'')        anno_entrata,
             coalesce(det.elem_det_tipo_id,0)     elem_det_tipo_id
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo,
          siac_t_cronop_elem celem,siac_t_cronop_elem_det det
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    celem.cronop_id=cronop.cronop_id
     and    det.cronop_elem_id=celem.cronop_elem_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
---     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and    pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null
     and    det.data_cancellazione is null
     and    det.validita_fine is null

    )
    select cronop_elem_anno.cronop_elem_id cronop_elem_new_id,
           cronop_elem_anno.cronop_id cronop_new_id,
           mov_riacc_anno.movgest_ts_id
    from mov_riacc_anno, mov_riacc_anno_prec, cronop_elem cronop_elem_anno_prec, cronop_elem cronop_elem_anno
    where mov_riacc_anno.annoRiacc=mov_riacc_anno_prec.movgest_anno
    and   mov_riacc_anno.numeroRiacc=mov_riacc_anno_prec.movgest_numero
    and   cronop_elem_anno_prec.cronop_elem_id=mov_riacc_anno_prec.cronop_elem_id
    and   cronop_elem_anno.bil_id=bilancioId
    and   cronop_elem_anno.programma_code=cronop_elem_anno_prec.programma_code
    and   cronop_elem_anno.cronop_code=cronop_elem_anno_prec.cronop_code
    and   cronop_elem_anno.cronop_elem_code=cronop_elem_anno_prec.cronop_elem_code
    and   cronop_elem_anno.cronop_elem_code2=cronop_elem_anno_prec.cronop_elem_code2
    and   cronop_elem_anno.cronop_elem_code3=cronop_elem_anno_prec.cronop_elem_code3
    and   cronop_elem_anno.elem_tipo_id=cronop_elem_anno_prec.elem_tipo_id
    and   cronop_elem_anno.cronop_elem_desc=cronop_elem_anno_prec.cronop_elem_desc
    and   cronop_elem_anno.cronop_elem_desc2=cronop_elem_anno_prec.cronop_elem_desc2
    and   cronop_elem_anno.periodo_id=cronop_elem_anno_prec.periodo_id
    and   cronop_elem_anno.cronop_elem_det_importo=cronop_elem_anno_prec.cronop_elem_det_importo
    and   cronop_elem_anno.cronop_elem_det_desc=cronop_elem_anno_prec.cronop_elem_det_desc
    and   cronop_elem_anno.anno_entrata=cronop_elem_anno_prec.anno_entrata
    and   cronop_elem_anno.elem_det_tipo_id=cronop_elem_anno_prec.elem_det_tipo_id
    and   exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   tipo.classif_tipo_id=c.classif_tipo_id
        and   exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=tipo.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
    and not exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   tipo.classif_tipo_id=c.classif_tipo_id
        and   not exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=tipo.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
   ) query
   where not exists
   (
   select 1
   from siac_r_movgest_ts_cronop_elem r1
   where r1.movgest_ts_id=query.movgest_ts_id
   and   r1.cronop_id=query.cronop_new_id
   and   r1.cronop_elem_id=query.cronop_elem_new_id
   and   r1.data_cancellazione is null
   and   r1.validita_fine is null
   )
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem riacc.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;



  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - fine.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
    validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
  	raise exception ' Errore in inserimento LOG.';
  end if;
 end if;
 -- 06.05.2019 Sofia siac-6255



 strMessaggio:='Inserimento LOG.';
 codResult:=null;
 insert into fase_bil_t_elaborazione_log
 (fase_bil_elab_id,fase_bil_elab_log_operazione,
  validita_inizio, login_operazione, ente_proprietario_id
 )
 values
 (faseBilElabId,strMessaggioFinale||'-FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
 if codResult is null then
  	raise exception ' Errore in inserimento LOG.';
 end if;


 if coalesce(codiceRisultato,0)=0 then
   	messaggioRisultato:=strMessaggioFinale||'- FINE.';
 else messaggioRisultato:=strMessaggioFinale||strMessaggio;
 end if;

 return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1000) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1000) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter FUNCTION siac.fnc_fasi_bil_gest_apertura_programmi_elabora
(
integer, 
integer, 
integer, 
varchar, 
varchar, 
timestamp without time zone, 
boolean, 
OUT integer, 
OUT  varchar
) owner to siac;

-- 04.10.2022 Sofia - Jira SIAC-8816 - fine 


--SIAC-8664 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR262_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_assest" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_competenza varchar,
  p_afde_bil_id integer
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  codice_pdc varchar,
  importo_collb numeric,
  importo_collc numeric,
  flag_acc_cassa boolean
) AS
$body$
DECLARE
classifBilRec record;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
elemTipoCode varchar;
user_table	varchar;
flagAccantGrad varchar;
v_fam_titolotipologiacategoria varchar:='00003';
strpercAccantonamento varchar;
percAccantonamento numeric;
tipomedia varchar;
perc1 numeric;
perc2 numeric;
perc3 numeric;
perc4 numeric;
perc5 numeric;
fde_media_utente  numeric;
fde_media_semplice_totali numeric;
fde_media_semplice_rapporti  numeric;
fde_media_ponderata_totali  numeric;
fde_media_ponderata_rapporti  numeric;

perc_delta numeric;
perc_media numeric;
afde_bilancioId integer;
perc_massima numeric;

h_count integer :=0;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

flag_acc_cassa:= true;

/*
Funzione creata per la SIAC-8664 - 06/10/2022.
Parte come copia della "BILR009_Allegato_C_Fondo_Crediti_Dubbia_esigibilita"
ma e' modificata per gestire i dati dell'assestamento invece che della 
previsione.


*/

percAccantonamento:=0;
select COALESCE(fondi_bil.afde_bil_accantonamento_graduale,0),
	fondi_bil.afde_bil_id
	into percAccantonamento, afde_bilancioId
from siac_t_acc_fondi_dubbia_esig_bil fondi_bil,
	siac_d_acc_fondi_dubbia_esig_tipo tipo,
    siac_d_acc_fondi_dubbia_esig_stato stato,
    siac_t_bil bil,
    siac_t_periodo per
where fondi_bil.afde_tipo_id =tipo.afde_tipo_id
	and fondi_bil.afde_stato_id = stato.afde_stato_id
	and fondi_bil.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
    and fondi_bil.ente_proprietario_id = p_ente_prop_id
    and fondi_bil.afde_bil_id = p_afde_bil_id
    and fondi_bil.data_cancellazione IS NULL
    and tipo.data_cancellazione IS NULL
    and stato.data_cancellazione IS NULL;

TipoImpComp='STA';  -- competenza
elemTipoCode:='CAP-EG'; -- tipo capitolo gestione.

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
codice_pdc='';

select fnc_siac_random_user()
into	user_table;


insert into siac_rep_tit_tip_cat_riga_anni
select  *
from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno, 
	user_table);
 

insert into siac_rep_cap_ep
select 	cl.classif_id,
  		anno_eserc.anno anno_bilancio,
  		e.*, 
        user_table utente,
  		pdc.classif_code
 from 	siac_r_bil_elem_class rc, 
 		siac_t_bil_elem e, 
        siac_d_class_tipo ct,
		siac_t_class cl,
 		siac_t_bil bilancio, 
 		siac_t_periodo anno_eserc, 
 		siac_d_bil_elem_tipo tipo_elemento,
        siac_r_bil_elem_class r_capitolo_pdc,
     	siac_t_class pdc,
     	siac_d_class_tipo pdc_tipo, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.elem_id						=	rc.elem_id
and r_capitolo_pdc.classif_id 		= 	pdc.classif_id
and pdc.classif_tipo_id 			= 	pdc_tipo.classif_tipo_id
and e.elem_id 						= 	r_capitolo_pdc.elem_id
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and e.ente_proprietario_id			=	p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and ct.classif_tipo_code			=	'CATEGORIA' 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and pdc_tipo.classif_tipo_code like 'PDC_%'
and	stato_capitolo.elem_stato_code	=	'VA'
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and rc.data_cancellazione 				is null
and ct.data_cancellazione 				is null
and cl.data_cancellazione 				is null
and bilancio.data_cancellazione 		is null
and anno_eserc.data_cancellazione 		is null
and tipo_elemento.data_cancellazione 	is null
and r_capitolo_pdc.data_cancellazione 	is null
and pdc.data_cancellazione 				is null
and pdc_tipo.data_cancellazione 		is null
and stato_capitolo.data_cancellazione 	is null
and r_capitolo_stato.data_cancellazione is null
and cat_del_capitolo.data_cancellazione is null
and r_cat_capitolo.data_cancellazione 	is null;

insert into siac_rep_cap_ep_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo)       
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
             siac_d_bil_elem_tipo tipo_elemento,
             siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo--,
         --22/12/2021 SIAC-8254
         --I capitoli devono essere presi tutti e non solo quelli
         --coinvolti in FCDE per avere l'importo effettivo dello stanziato
         --nella colonna (a).
            --siac_t_acc_fondi_dubbia_esig fcde
    where 	bilancio.periodo_id						=	anno_eserc.periodo_id 								
        and	capitolo.bil_id							=	bilancio.bil_id 			 
        and	capitolo.elem_id						=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id					=	tipo_elemento.elem_tipo_id
        and	capitolo_importi.elem_det_tipo_id		=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=	capitolo_importi.periodo_id 			  
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		--and   fcde.elem_id						= capitolo.elem_id
        and capitolo_importi.ente_proprietario_id 	= 	p_ente_prop_id  
    	and	anno_eserc.anno							= 	p_anno				
        --and   fcde.afde_bil_id				=  afde_bilancioId
        and	tipo_elemento.elem_tipo_code 			= 	elemTipoCode
        and	capitolo_imp_periodo.anno in (p_anno_competenza)
        and	stato_capitolo.elem_stato_code		=	'VA'
		--and	cat_del_capitolo.elem_cat_code		=	'STD' 
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null 
       -- and fcde.data_cancellazione IS NULL     
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   	capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	0,
    	0,
   	 	0,
    	0,
    	0,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1
	where			tb1.periodo_anno = p_anno_competenza	
    				AND	tb1.tipo_imp =	TipoImpComp	
                    and tb1.utente 	= 	user_table;
               
for classifBilRec in
select 	v1.classif_tipo_desc1    		titoloe_TIPO_DESC,
       	v1.titolo_id              		titoloe_ID,
       	v1.titolo_code             		titoloe_CODE,
       	v1.titolo_desc             		titoloe_DESC,
       	v1.classif_tipo_desc2  			tipologia_TIPO_DESC,
       	v1.tipologia_id              	tipologia_ID,
       	v1.tipologia_code            	tipologia_CODE,
       	v1.tipologia_desc            	tipologia_DESC,
       	v1.classif_tipo_desc3     		categoria_TIPO_DESC,
      	v1.categoria_id              	categoria_ID,
       	v1.categoria_code            	categoria_CODE,
       	v1.categoria_desc            	categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
        tb.pdc							codice_pdc,
	   	COALESCE (tb1.stanziamento_prev_anno,0)		stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2
from  	siac_rep_tit_tip_cat_riga_anni v1
			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					----------and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_ep_imp_riga tb1  
            		on (tb1.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb1.utente	=	tb.utente)
    where v1.utente = user_table 	
			order by titoloe_CODE,tipologia_CODE,categoria_CODE

loop


titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
categoria_tipo_desc := classifBilRec.categoria_tipo_desc;
categoria_code := classifBilRec.categoria_code;
categoria_desc := classifBilRec.categoria_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
codice_pdc:=classifBilRec.codice_pdc;


-- SIAC-5854 INIZIO
SELECT true
INTO   flag_acc_cassa
FROM   siac_r_bil_elem_attr rbea, siac_t_attr ta
WHERE  rbea.attr_id = ta.attr_id
  AND    ta.ente_proprietario_id = p_ente_prop_id
  AND    rbea.elem_id = classifBilRec.bil_ele_id
  AND    ta.attr_code = 'FlagAccertatoPerCassa'

  AND    rbea."boolean" = 'S'
  AND    rbea.data_cancellazione IS NULL
  AND    ta.data_cancellazione IS NULL;

IF flag_acc_cassa IS NULL THEN
   flag_acc_cassa := false;
END IF;
-- SIAC-5854 FINE


raise notice 'bil_ele_id = %', classifBilRec.bil_ele_id;

fde_media_utente:=0;
fde_media_semplice_totali:=0; 
fde_media_semplice_rapporti:=0;
fde_media_ponderata_totali:=0; 
fde_media_ponderata_rapporti:=0;
perc_delta:=0;
perc_media:=0;
tipomedia:='';

if classifBilRec.bil_ele_id IS NOT NULL then
  select  datifcd.perc_delta, 1, tipo_media.afde_tipo_media_code,
  COALESCE(datifcd.acc_fde_media_utente,0), 
  COALESCE(datifcd.acc_fde_media_semplice_totali,0),
  COALESCE(datifcd.acc_fde_media_semplice_rapporti,0), 
  COALESCE(datifcd.acc_fde_media_ponderata_totali,0),
  COALESCE(datifcd.acc_fde_media_ponderata_rapporti,0),
  greatest (COALESCE(datifcd.acc_fde_media_semplice_totali,0),
  	 COALESCE(datifcd.acc_fde_media_semplice_rapporti,0),
  	COALESCE(datifcd.acc_fde_media_ponderata_totali,0),
    COALESCE(datifcd.acc_fde_media_ponderata_rapporti,0))
  into perc_delta, h_count, tipomedia,
  fde_media_utente, fde_media_semplice_totali, fde_media_semplice_rapporti,
  fde_media_ponderata_totali, fde_media_ponderata_rapporti, perc_massima
   FROM siac_t_acc_fondi_dubbia_esig datifcd, 
      siac_d_acc_fondi_dubbia_esig_tipo_media tipo_media
  where tipo_media.afde_tipo_media_id=datifcd.afde_tipo_media_id
    and datifcd.elem_id=classifBilRec.bil_ele_id 
    and datifcd.afde_bil_id  = afde_bilancioId
    and datifcd.data_cancellazione is null
    and tipo_media.data_cancellazione is null;
end if;

if tipomedia = 'SEMP_RAP' then
    perc_media = fde_media_semplice_rapporti;         
elsif tipomedia = 'SEMP_TOT' then
    perc_media = fde_media_semplice_totali;        
elsif tipomedia = 'POND_RAP' then
      perc_media = fde_media_ponderata_rapporti;  
elsif tipomedia = 'POND_TOT' then
      perc_media = fde_media_ponderata_totali;    
elsif tipomedia = 'UTENTE' then  --Media utente
      perc_media = fde_media_utente;   
end if;

raise notice 'tipomedia % - media: % - delta: % - massima %', tipomedia , perc_media, perc_delta, perc_massima ;

--- colonna b del report = stanziamento capitolo * percentualeAccantonamentoAnno(1,2) * perc_media
--- colonna c del report = stanziamento capitolo * perc_delta della tabella 

--SIAC-8154 14/10/2021
--la colonna C diventa quello che prima era la colonna B
--la colonna B invece della percentuale media deve usa la percentuale 
--che ha il valore massimo (esclusa quella utente).
--importo_collb:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_media/100) * percAccantonamento/100,2);
--importo_collc:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_delta/100) * percAccantonamento/100,2);   

--SIAC-8579 17/01/2022 l'accantonamento obbligatorio (Colonna B) diventa uguale
--all'accantonamento effettivo (Colonna C).
--importo_collb:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_massima/100) * percAccantonamento/100,2);
importo_collc:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_media/100) * percAccantonamento/100,2);
importo_collb:=importo_collc;

raise notice 'importo_collb % - %', classifBilRec.bil_ele_id , importo_collb;

raise notice 'percAccantonamento % - %', classifBilRec.bil_ele_id , percAccantonamento ;

if h_count is null or flag_acc_cassa = true then
  importo_collb:=0;
  importo_collc:=0;
  -- flag_acc_cassa:=true; -- SIAC-5854
END if;

-- importi capitolo

return next;

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
codice_pdc:=0;
importo_collb:=0;
importo_collc:=0;
flag_acc_cassa:=true;

end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_cap_ep where utente=user_table;

delete from siac_rep_cap_ep_imp where utente=user_table;

delete from siac_rep_cap_ep_imp_riga where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='Ricerca dati capitolo';
		 RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR262_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_assest" (p_ente_prop_id integer, p_anno varchar, p_anno_competenza varchar, p_afde_bil_id integer)
  OWNER TO siac;
  
  

CREATE OR REPLACE FUNCTION siac."BILR262_elenco_versione_fcde_assestamento" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  afde_bil_id integer,
  afde_bil_versione integer,
  versione_desc varchar
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;


BEGIN


/*
Funzione creata per la SIAC-8664 - 07/10/2022.
Restituisce l'elenco delle versioni FCDE di Assestamento disponibili.
E' stata creata una funzione per rendere piu' semplici eventuali modifiche sul
formato della descrizione da visualizzare nel report, sul filtro (solo DEFINITIVE
o anche BOZZA) e sull'ordinamento dei dati.

*/

return query
select fondi_bil.afde_bil_id, fondi_bil.afde_bil_versione,
('Versione #' || fondi_bil.afde_bil_versione|| ' del '||to_char(fondi_bil.validita_inizio,'dd/MM/yyyy')|| ' in stato ' ||stato.afde_stato_code)::varchar versione_desc
from siac_t_acc_fondi_dubbia_esig_bil fondi_bil,
	siac_d_acc_fondi_dubbia_esig_tipo tipo,
    siac_d_acc_fondi_dubbia_esig_stato stato,
    siac_t_bil bil,
    siac_t_periodo per
where fondi_bil.afde_tipo_id =tipo.afde_tipo_id
	and fondi_bil.afde_stato_id = stato.afde_stato_id
	and fondi_bil.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
	and fondi_bil.ente_proprietario_id = p_ente_prop_id
	and per.anno= p_anno
    and tipo.afde_tipo_code ='GESTIONE' -- = Assestamento
    and stato.afde_stato_code = 'DEFINITIVA'
    and fondi_bil.data_cancellazione IS NULL
    and tipo.data_cancellazione IS NULL
    and stato.data_cancellazione IS NULL
order by fondi_bil.afde_bil_versione desc;     


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'Nessun dato trovato.' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='Ricerca dati fcde';
		 RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR262_elenco_versione_fcde_assestamento" (p_ente_prop_id integer, p_anno varchar)
  OWNER TO siac;  
  
--SIAC-8664 - Maurizio - FINE




--SIAC-8656 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR066_prime_note_integrate"(p_ente_prop_id integer, p_anno varchar, p_data_reg_da date, p_data_reg_a date, p_num_prima_nota integer, p_num_prima_nota_def integer, p_tipologia varchar, p_tipo_evento varchar, p_evento varchar);

CREATE OR REPLACE FUNCTION siac."BILR066_prime_note_integrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_reg_da date,
  p_data_reg_a date,
  p_num_prima_nota integer,
  p_num_prima_nota_def integer,
  p_tipologia varchar,
  p_tipo_evento varchar,
  p_evento varchar
)
RETURNS TABLE (
  nome_ente varchar,
  num_movimento varchar,
  cod_beneficiario varchar,
  ragione_sociale varchar,
  num_capitolo varchar,
  num_articolo varchar,
  ueb varchar,
  classif_bilancio varchar,
  imp_movimento numeric,
  descr_movimento varchar,
  num_prima_nota integer,
  data_registrazione date,
  stato_prima_nota varchar,
  descr_prima_nota varchar,
  cod_causale varchar,
  num_riga integer,
  cod_conto varchar,
  descr_riga varchar,
  importo_dare numeric,
  importo_avere numeric,
  key_movimento integer,
  evento_tipo_code varchar,
  evento_code varchar,
  causale_ep_tipo_code varchar,
  pnota_stato_code varchar,
  num_prima_nota_def integer,
  data_registrazione_def date,
  code_missione varchar,
  desc_missione varchar,
  code_programma varchar,
  desc_programma varchar,
  miss_prog_display varchar
) AS
$body$
DECLARE
elenco_prime_note record;
dati_movimento record;
elenco_tipo_classif record;
dati_classif	record;
idMacroAggreg	integer;
idProgramma		integer;
idCategoria		integer;
prec_num_prima_nota integer;
prec_num_movimento_key integer;
prec_num_movimento varchar;
prec_num_capitolo varchar;
prec_num_articolo varchar;
prec_ueb varchar;
prec_descr_movimento varchar;
prec_cod_beneficiario varchar;
prec_ragione_sociale varchar;
prec_imp_movimento numeric;
prec_classif_bilancio varchar;
elem_id_curr integer;
elem_id_prec integer;
code_missione_prec varchar;
desc_missione_prec varchar;
code_programma_prec varchar;
desc_programma_prec varchar;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO 		varchar(1000):=DEF_NULL;
user_table			varchar;
v_fam_missioneprogramma varchar;
v_fam_titolomacroaggregato varchar;
sub_impegno VARCHAR;
soggetto_code_mod VARCHAR;
soggetto_desc_mod VARCHAR;

BEGIN
	nome_ente='';
    num_movimento='';
    cod_beneficiario='';
    ragione_sociale='';
    num_capitolo='';
    num_articolo='';
    ueb='';
    classif_bilancio='';
    imp_movimento=0;
    descr_movimento='';
    num_prima_nota=0;
    num_prima_nota_def=0;
    data_registrazione=NULL;
    data_registrazione_def=NULL;
    stato_prima_nota='';
    descr_prima_nota='';
    cod_causale='';
    num_riga=0;
    cod_conto='';
    descr_riga='';
    importo_dare=0;
    importo_avere=0;
    key_movimento=0;
    evento_tipo_code='';
    evento_code='';
    causale_ep_tipo_code='';
    pnota_stato_code='';
    
    
    prec_num_prima_nota=0;
	prec_num_movimento_key =0;
	prec_num_movimento ='';
    prec_descr_movimento='';
    prec_num_capitolo='';
	prec_num_articolo='';
    prec_ueb='';
    prec_cod_beneficiario='';
    prec_ragione_sociale='';
    prec_imp_movimento=0;
    prec_classif_bilancio='';
    
	v_fam_missioneprogramma :='00001';
	v_fam_titolomacroaggregato := '00002';
    sub_impegno='';
    soggetto_code_mod='';
    soggetto_desc_mod='';
    
    code_missione:='';
    desc_missione:='';
    code_programma:='';
    desc_programma:='';
    miss_prog_display:='';
                
    elem_id_prec:=0;
    code_missione_prec :='';
	desc_missione_prec  :='';
	code_programma_prec  :='';
	desc_programma_prec  :='';

    select fnc_siac_random_user()
	into	user_table;
	

-- 05/09/2016: sostituita la query di caricamento struttura del bilancio
--   per migliorare prestazioni
with missione as 
(select 
e.classif_tipo_desc missione_tipo_desc,
a.classif_id missione_id,
a.classif_code missione_code,
a.classif_desc missione_desc,
a.validita_inizio missione_validita_inizio,
a.validita_fine missione_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
--and to_timestamp('01/01/'||p_anno,'dd/mm/yyyy') between  v.titusc_validita_inizio and COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, programma as (
select 
e.classif_tipo_desc programma_tipo_desc,
b.classif_id_padre missione_id,
a.classif_id programma_id,
a.classif_code programma_code,
a.classif_desc programma_desc,
a.validita_inizio programma_validita_inizio,
a.validita_fine programma_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not  null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
,
titusc as (
select 
e.classif_tipo_desc titusc_tipo_desc,
a.classif_id titusc_id,
a.classif_code titusc_code,
a.classif_desc titusc_desc,
a.validita_inizio titusc_validita_inizio,
a.validita_fine titusc_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, macroag as (
select 
e.classif_tipo_desc macroag_tipo_desc,
b.classif_id_padre titusc_id,
a.classif_id macroag_id,
a.classif_code macroag_code,
a.classif_desc macroag_desc,
a.validita_inizio macroag_validita_inizio,
a.validita_fine macroag_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into siac_rep_mis_pro_tit_mac_riga_anni
select  missione.missione_tipo_desc,
missione.missione_id,
missione.missione_code,
missione.missione_desc,
missione.missione_validita_inizio,
missione.missione_validita_fine,
programma.programma_tipo_desc,
programma.programma_id,
programma.programma_code,
programma.programma_desc,
programma.programma_validita_inizio,
programma.programma_validita_fine,
titusc.titusc_tipo_desc,
titusc.titusc_id,
titusc.titusc_code,
titusc.titusc_desc,
titusc.titusc_validita_inizio,
titusc.titusc_validita_fine,
macroag.macroag_tipo_desc,
macroag.macroag_id,
macroag.macroag_code,
macroag.macroag_desc,
macroag.macroag_validita_inizio,
macroag.macroag_validita_fine,
missione.ente_proprietario_id
,user_table
from missione , programma,titusc, macroag
    /* 02/09/2016: start filtro per mis-prog-macro*/
   -- , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 02/09/2016: start filtro per mis-prog-macro*/
 --AND programma.programma_id = progmacro.classif_a_id
-- AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;
 


    /* carico su una tabella temporanea i dati della struttura dei capitolo di entrata */
insert into  siac_rep_tit_tip_cat_riga_anni
select v.*,user_table from
(SELECT v3.classif_tipo_desc AS classif_tipo_desc1, v3.classif_id AS titolo_id,
    v3.classif_code AS titolo_code, v3.classif_desc AS titolo_desc,
    v3.validita_inizio AS titolo_validita_inizio,
    v3.validita_fine AS titolo_validita_fine,
    v2.classif_tipo_desc AS classif_tipo_desc2, v2.classif_id AS tipologia_id,
    v2.classif_code AS tipologia_code, v2.classif_desc AS tipologia_desc,
    v2.validita_inizio AS tipologia_validita_inizio,
    v2.validita_fine AS tipologia_validita_fine,
    v1.classif_tipo_desc AS classif_tipo_desc3, v1.classif_id AS categoria_id,
    v1.classif_code AS categoria_code, v1.classif_desc AS categoria_desc,
    v1.validita_inizio AS categoria_validita_inizio,
    v1.validita_fine AS categoria_validita_fine, v1.ente_proprietario_id
FROM (SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v1,
-------------siac_v_tit_tip_cat_anni v1,
(SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v2, 
----------siac_v_tit_tip_cat_anni v2,
(SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id
     AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v3
---------------    siac_v_tit_tip_cat_anni v3
WHERE v1.classif_id_padre = v2.classif_id AND v1.classif_tipo_desc::text =
    'Categoria'::text AND v2.classif_tipo_desc::text = 'Tipologia'::text 
    AND v2.classif_id_padre = v3.classif_id AND v3.classif_tipo_desc::text = 'Titolo Entrata'::text 
    AND v1.ente_proprietario_id = v2.ente_proprietario_id AND v2.ente_proprietario_id = v3.ente_proprietario_id) v
---------siac_v_tit_tip_cat_riga_anni 
where v.ente_proprietario_id=p_ente_prop_id 
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.categoria_validita_inizio and
COALESCE(v.categoria_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.tipologia_validita_inizio and
COALESCE(v.tipologia_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.titolo_validita_inizio and
COALESCE(v.titolo_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
order by titolo_code, tipologia_code,categoria_code;

	/* estrazione dei dati delle prime note */
    

--if (p_data_reg_da is NULL OR p_data_reg_a is NULL)  THEN	    
    for elenco_prime_note IN
    select  ente_prop.ente_denominazione	nome_ente,
        r_ev_reg_movfin.campo_pk_id 	key_movimento,
        tipo_evento.evento_tipo_code, d_tipo_causale.causale_ep_tipo_code,  
        evento.evento_code,d_coll_tipo.collegamento_tipo_code,
        prima_nota.pnota_numero num_prima_nota, prima_nota.pnota_desc,prima_nota.pnota_data, 
        pnota_stato.pnota_stato_code, prima_nota.pnota_progressivogiornale num_prima_nota_def,
            pnota_stato.pnota_stato_desc,pdce_conto.pdce_conto_code codice_conto,
            pdce_conto.pdce_conto_desc descr_riga,
            prima_nota.pnota_dataregistrazionegiornale pnota_data_def,
             causale_ep.causale_ep_code cod_causale, causale_ep.causale_ep_desc, mov_ep.movep_code,
            mov_ep.movep_desc, mov_ep_det.movep_det_code num_riga, mov_ep_det.movep_det_desc,
            mov_ep_det.movep_det_segno, mov_ep_det.movep_det_importo,
            --INC000006526089 09/11/2022:
            --Missione e programma per le prime note libere sono 
            --gestite al fondo della procedura.
            prima_nota.pnota_id
          --  COALESCE(programmi.programma_code,'') programma_code_lib,
          --  COALESCE(programmi.programma_desc,'') programma_desc_lib,
          --  COALESCE(missioni.missione_code,'') missione_code_lib,
          --  COALESCE(missioni.missione_desc,'') missione_desc_lib
    from siac_t_ente_proprietario	ente_prop,
            siac_t_periodo	 		anno_eserc,	
            siac_t_bil	 			bilancio,
            siac_t_prima_nota prima_nota,
              --23/07/2021 SIAC-8295.
              -- Aggiunto il filtro sull'ambito FIN            
            siac_d_ambito amb,
            siac_t_mov_ep_det	mov_ep_det,
            --SIAC-8656 20/10/2022.
            --Aggiunta gestione di missione/programma per le prime
            --note libere.
            --INC000006526089 09/11/2022:
            --Missione e programma per le prime note libere sono 
            --gestite al fondo della procedura.
			/*	left join (select class_progr.classif_code programma_code,
                			class_progr.classif_desc programma_desc,
                            r_mov_ep_det_class_progr.movep_det_id
                          from siac_t_class class_progr,
                          	siac_d_class_tipo tipo_class_progr,
                            siac_r_mov_ep_det_class r_mov_ep_det_class_progr
                          where tipo_class_progr.classif_tipo_id=class_progr.classif_tipo_id
                          and r_mov_ep_det_class_progr.classif_id=class_progr.classif_id
                          and tipo_class_progr.ente_proprietario_id=p_ente_prop_id
                          and   tipo_class_progr.classif_tipo_code='PROGRAMMA'
                          and  r_mov_ep_det_class_progr.data_cancellazione IS NULL 
                          and class_progr.data_cancellazione IS NULL) programmi                          
                   on programmi.movep_det_id=mov_ep_det.movep_det_id
				left join (select class_miss.classif_code missione_code,
                			class_miss.classif_desc missione_desc,
                            r_mov_ep_det_class_miss.movep_det_id
                          from siac_t_class class_miss,
                          	siac_d_class_tipo tipo_class_miss,
                            siac_r_mov_ep_det_class r_mov_ep_det_class_miss
                          where tipo_class_miss.classif_tipo_id=class_miss.classif_tipo_id
                          and r_mov_ep_det_class_miss.classif_id=class_miss.classif_id
                          and tipo_class_miss.ente_proprietario_id=p_ente_prop_id
                          and   tipo_class_miss.classif_tipo_code='MISSIONE'
                          and  r_mov_ep_det_class_miss.data_cancellazione IS NULL 
                          and class_miss.data_cancellazione IS NULL) missioni                   
                  on missioni.movep_det_id=mov_ep_det.movep_det_id, */           
            siac_r_prima_nota_stato r_pnota_stato,
            siac_d_prima_nota_stato pnota_stato,
            siac_t_pdce_conto	pdce_conto,
            siac_t_causale_ep	causale_ep,
            siac_d_causale_ep_tipo d_tipo_causale,
            siac_t_mov_ep		mov_ep
            LEFT JOIN siac_t_reg_movfin	reg_movfin
            on (reg_movfin.regmovfin_id=mov_ep.regmovfin_id 
            	AND reg_movfin.data_cancellazione IS NULL) 
            LEFT JOIN siac_r_evento_reg_movfin  r_ev_reg_movfin        
            on (r_ev_reg_movfin.regmovfin_id=reg_movfin.regmovfin_id 
            	and r_ev_reg_movfin.data_cancellazione IS NULL)
            LEFT JOIN siac_d_evento		evento
            on (evento.evento_id=r_ev_reg_movfin.evento_id
            	AND evento.data_cancellazione IS NULL)
            LEFT JOIN siac_d_evento_tipo	tipo_evento
            on (tipo_evento.evento_tipo_id=evento.evento_tipo_id
            	AND tipo_evento.data_cancellazione IS NULL)  
            LEFT JOIN siac_d_collegamento_tipo    d_coll_tipo 
            on (d_coll_tipo.collegamento_tipo_id=evento.collegamento_tipo_id
            	and  d_coll_tipo.data_cancellazione is NULL) 
    where bilancio.periodo_id=anno_eserc.periodo_id
            and anno_eserc.ente_proprietario_id=ente_prop.ente_proprietario_id	
            and prima_nota.bil_id=bilancio.bil_id
            and prima_nota.ente_proprietario_id=ente_prop.ente_proprietario_id
            -- QUALE JOIN è corretto???
             and prima_nota.pnota_id=mov_ep.regep_id
            -- QUALE JOIN è corretto??? and prima_nota.pnota_id=mov_ep.regmovfin_id
            and mov_ep.movep_id=mov_ep_det.movep_id
            and r_pnota_stato.pnota_id=prima_nota.pnota_id
            and pnota_stato.pnota_stato_id=r_pnota_stato.pnota_stato_id
            and pdce_conto.pdce_conto_id=mov_ep_det.pdce_conto_id
            and causale_ep.causale_ep_id=mov_ep.causale_ep_id
            and d_tipo_causale.causale_ep_tipo_id=causale_ep.causale_ep_tipo_id 
            and amb.ambito_id=prima_nota.ambito_id
            and ente_prop.ente_proprietario_id=p_ente_prop_id   
            and anno_eserc.anno=p_anno 
            AND (((p_data_reg_da is NULL OR p_data_reg_a is NULL) 
            	OR (p_data_reg_da is NOT NULL AND p_data_reg_a is NOT NULL 
                	AND prima_nota.pnota_data BETWEEN p_data_reg_da ::timestamp AND (p_data_reg_a+1) ::timestamp))
 			/* 30/01/2017: il filtro sulle date avviene anche sulla data definitiva */
              OR ((p_data_reg_da is NULL OR p_data_reg_a is NULL) 
            	OR (p_data_reg_da is NOT NULL AND p_data_reg_a is NOT NULL 
                	AND (prima_nota.pnota_dataregistrazionegiornale is not null 
                     AND prima_nota.pnota_dataregistrazionegiornale BETWEEN p_data_reg_da ::timestamp AND (p_data_reg_a+1) ::timestamp))))                    
            /* 24/01/2017: aggiunto filtro sul numero provvisorio della prima nota */
            AND (p_num_prima_nota IS NULL OR (p_num_prima_nota IS NOT NULL    
            					AND prima_nota.pnota_numero =  p_num_prima_nota)) 
 			/* 24/01/2017: aggiunto filtro sul numero definitivo della prima nota */
            AND (p_num_prima_nota_def IS NULL OR (p_num_prima_nota_def IS NOT NULL    
            					AND prima_nota.pnota_progressivogiornale =  p_num_prima_nota_def))                                                     
			/* 30/01/2017: spostati nella procedura i filtri che prima erano sul report */
            AND ((trim(p_tipologia) <> 'Tutte' AND d_tipo_causale.causale_ep_tipo_code =p_tipologia) OR
            	(trim(p_tipologia) = 'Tutte'))
            AND ((trim(p_tipo_evento) <> 'Tutti' AND tipo_evento.evento_tipo_code =p_tipo_evento) OR
            	(trim(p_tipo_evento) = 'Tutti'))                   
            AND ((trim(p_evento) <> 'Tutti' AND  evento.evento_code = p_evento)  OR
					(trim(p_evento) = 'Tutti' ))            
            AND pnota_stato.pnota_stato_code <> 'A'  
              --23/07/2021 SIAC-8295.
              -- Aggiunto il filtro sull'ambito FIN            
            and amb.ambito_code='AMBITO_FIN'     
            and ente_prop.data_cancellazione is NULL
            and bilancio.data_cancellazione is NULL
            and anno_eserc.data_cancellazione is NULL
            and prima_nota.data_cancellazione is NULL
            and mov_ep.data_cancellazione is NULL
            and mov_ep_det.data_cancellazione is NULL
            and r_pnota_stato.data_cancellazione is NULL
            and pnota_stato.data_cancellazione is NULL
            and pdce_conto.data_cancellazione is NULL
            and causale_ep.data_cancellazione is NULL
            and d_tipo_causale.data_cancellazione is NULL
            ORDER BY num_prima_nota,  num_riga

        
            loop
            
            nome_ente=elenco_prime_note.nome_ente;    	    	
            num_prima_nota=elenco_prime_note.num_prima_nota;
            num_prima_nota_def= COALESCE(elenco_prime_note.num_prima_nota_def,0);
            data_registrazione=elenco_prime_note.pnota_data;
            data_registrazione_def=elenco_prime_note.pnota_data_def;
            stato_prima_nota=elenco_prime_note.pnota_stato_desc;
            descr_prima_nota=elenco_prime_note.pnota_desc;
            cod_causale=elenco_prime_note.cod_causale;
            num_riga=elenco_prime_note.num_riga::INTEGER;
            cod_conto=elenco_prime_note.codice_conto;
            descr_riga=elenco_prime_note.descr_riga;
            key_movimento=elenco_prime_note.key_movimento;
            evento_tipo_code=elenco_prime_note.evento_tipo_code;
            evento_code=elenco_prime_note.evento_code;
            causale_ep_tipo_code=elenco_prime_note.causale_ep_tipo_code;
            pnota_stato_code=elenco_prime_note.pnota_stato_code;
            
            if upper(elenco_prime_note.movep_det_segno)='AVERE' THEN                
                  importo_dare=0;
                  importo_avere=elenco_prime_note.movep_det_importo;
                
            ELSE                
                  importo_dare=elenco_prime_note.movep_det_importo;
                  importo_avere=0;                            
            end if;
                        
                /* Tipo Impegno o Tipo Accertamento */
--raise notice 'Gestisco tipo_code = %, evento_code =%, collegamento_code =%',
--	           elenco_prime_note.evento_tipo_code, elenco_prime_note.evento_code,
--                elenco_prime_note.collegamento_tipo_code;  

--raise notice 'CHIAVE MOV = %, NUM PN PROVV = %',   elenco_prime_note.key_movimento,elenco_prime_note.num_prima_nota;                  
--raise notice 'Tipo: %. Num mov % (prec %). numPnota % (prec %)',elenco_prime_note.evento_tipo_code, elenco_prime_note.key_movimento,prec_num_movimento_key, elenco_prime_note.num_prima_nota,prec_num_prima_nota;               
            if elenco_prime_note.evento_tipo_code='I' OR
                    elenco_prime_note.evento_tipo_code='A' THEN				                 
                
                    /* se il record precedente aveva gli stessi dati, non eseguo di nuovo la query */                                  
                  if prec_num_movimento_key=elenco_prime_note.key_movimento AND 
                      prec_num_prima_nota=elenco_prime_note.num_prima_nota THEN
                      num_movimento=prec_num_movimento;
                      num_capitolo=prec_num_capitolo;
                      num_articolo=prec_num_articolo;
                      ueb=prec_ueb;
                      descr_movimento=prec_descr_movimento;
                      cod_beneficiario=prec_cod_beneficiario;
                      ragione_sociale=prec_ragione_sociale;
                      imp_movimento=prec_imp_movimento;
                      classif_bilancio=prec_classif_bilancio;

                     -- raise notice 'Esiste già %',classif_bilancio;
                  ELSE
                    	/* impegno o accertamento: devo andare sulla tabella
                        	siac_t_movgest 
                           Devo testare tutti i possibili codici!!*/	
                       -- raise notice 'Evento %', elenco_prime_note.evento_code;
                   /* if elenco_prime_note.evento_code = 'IMP-INS' OR
                    	elenco_prime_note.evento_code = 'MIM-INS-I' OR
                        elenco_prime_note.evento_code = 'MIM-INS-S' OR
                        elenco_prime_note.evento_code = 'IMP-PRG' OR
                    	elenco_prime_note.evento_code = 'ACC-INS' OR
                        elenco_prime_note.evento_code = 'MAC-ANN' OR
                        elenco_prime_note.evento_code = 'MAC-INS-I' OR
                        elenco_prime_note.evento_code = 'MAC-INS-S' THEN  */   
                  -- raise notice 'COLL_TIPO = %', elenco_prime_note.collegamento_tipo_code;
                  -- raise notice 'tipo_EVENTO = %', elenco_prime_note.evento_tipo_code;
                    if elenco_prime_note.collegamento_tipo_code in('I','A') THEN                                                                  
                        SELECT movgest.movgest_numero, movgest.movgest_desc,movgest.movgest_anno,
                            bil_elem.elem_code cod_capitolo, bil_elem.elem_code2 num_articolo,bil_elem.elem_id,
                            bil_elem.elem_code3 ueb, soggetto.soggetto_desc, soggetto.soggetto_code,
                            ts_det_movgest.movgest_ts_det_importo imp_movimento,
                            d_soggetto_classe.soggetto_classe_desc,
                            d_soggetto_classe.soggetto_classe_code
                            INTO dati_movimento 
                              from siac_t_movgest movgest,                         
                               siac_t_movgest_ts_det ts_det_movgest,
                               siac_r_movgest_bil_elem  r_movgest_bil_elem,
                               siac_t_bil_elem		bil_elem,
                               siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                                siac_t_movgest_ts	ts_movgest                      
                               LEFT join siac_r_movgest_ts_sog	r_mov_gest_ts_sog
                              on (r_mov_gest_ts_sog.movgest_ts_id=ts_movgest.movgest_ts_id and r_mov_gest_ts_sog.data_cancellazione is NULL)  
                              LEFT join siac_t_soggetto		soggetto
                              on (soggetto.soggetto_id=r_mov_gest_ts_sog.soggetto_id 
                              	and soggetto.data_cancellazione is NULL)  
                              LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sogclasse
                             on (r_movgest_ts_sogclasse.movgest_ts_id=ts_movgest.movgest_ts_id
                                 AND r_movgest_ts_sogclasse.data_cancellazione IS NULL)
                            LEFT JOIN siac_d_soggetto_classe d_soggetto_classe
                                on (d_soggetto_classe.soggetto_classe_id=r_movgest_ts_sogclasse.soggetto_classe_id
                                and d_soggetto_classe.data_cancellazione IS NULL)
                              where ts_movgest.movgest_id=movgest.movgest_id
                              and ts_det_movgest.movgest_ts_id=  ts_movgest.movgest_ts_id
                              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=ts_det_movgest.movgest_ts_det_tipo_id
                              and r_movgest_bil_elem.movgest_id=movgest.movgest_id
                              and bil_elem.elem_id=r_movgest_bil_elem.elem_id
                              and movgest.movgest_id= elenco_prime_note.key_movimento
                              and bil_elem.ente_proprietario_id=p_ente_prop_id
                              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                              and movgest.data_cancellazione is null
                              and ts_movgest.data_cancellazione is null
                              and ts_det_movgest.data_cancellazione is null
                              and r_movgest_bil_elem.data_cancellazione is null
                              and bil_elem.data_cancellazione is null
                              and d_movgest_ts_det_tipo.data_cancellazione is null;                          
                        IF NOT FOUND THEN
                        	/* 25/02/2016: se non esiste il movimento non interrompo la procedura */
                           -- RAISE EXCEPTION 'Impegno/accertamento senza Periodo. Non esiste il movimento %', elenco_prime_note.key_movimento;
                           -- return;
                        	descr_movimento='Non esiste il movimento';	                  
                        END IF;
                        sub_impegno='';
                        soggetto_code_mod='';
    					soggetto_desc_mod='';
                        	-- SubImpegno o SubAccertamento
                    ELSIF elenco_prime_note.collegamento_tipo_code in('SI','SA') THEN                     
						SELECT movgest.movgest_numero, movgest.movgest_desc,movgest.movgest_anno,
                            bil_elem.elem_code cod_capitolo, bil_elem.elem_code2 num_articolo,bil_elem.elem_id,
                            bil_elem.elem_code3 ueb, soggetto.soggetto_desc, soggetto.soggetto_code,
                            ts_det_movgest.movgest_ts_det_importo imp_movimento, ts_movgest.movgest_ts_code,
                            d_soggetto_classe.soggetto_classe_desc,
                            d_soggetto_classe.soggetto_classe_code
                            INTO dati_movimento 
                              from siac_t_movgest movgest,                         
                               siac_t_movgest_ts_det ts_det_movgest,
                               siac_r_movgest_bil_elem  r_movgest_bil_elem,
                               siac_t_bil_elem		bil_elem,
                               siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                                siac_t_movgest_ts	ts_movgest                      
                              LEFT join siac_r_movgest_ts_sog	r_mov_gest_ts_sog
                              on (r_mov_gest_ts_sog.movgest_ts_id=ts_movgest.movgest_ts_id and r_mov_gest_ts_sog.data_cancellazione is NULL)  
                              LEFT join siac_t_soggetto		soggetto
                              on (soggetto.soggetto_id=r_mov_gest_ts_sog.soggetto_id 
                              	and soggetto.data_cancellazione is NULL)  
                              LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sogclasse
                             on (r_movgest_ts_sogclasse.movgest_ts_id=ts_movgest.movgest_ts_id
                                 AND r_movgest_ts_sogclasse.data_cancellazione IS NULL)
                            LEFT JOIN siac_d_soggetto_classe d_soggetto_classe
                                on (d_soggetto_classe.soggetto_classe_id=r_movgest_ts_sogclasse.soggetto_classe_id
                                and d_soggetto_classe.data_cancellazione IS NULL)
                              where ts_movgest.movgest_id=movgest.movgest_id
                              and ts_det_movgest.movgest_ts_id=  ts_movgest.movgest_ts_id
                              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=ts_det_movgest.movgest_ts_det_tipo_id
                              and r_movgest_bil_elem.movgest_id=movgest.movgest_id
                              and bil_elem.elem_id=r_movgest_bil_elem.elem_id
                              /* Accedo alla tabella della testata per
                              	sub-impegno e sub-accertamento */
                              --and movgest.movgest_id= elenco_prime_note.key_movimento
                              and ts_movgest.movgest_ts_id= elenco_prime_note.key_movimento
                              and bil_elem.ente_proprietario_id=p_ente_prop_id
                              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                              and movgest.data_cancellazione is null
                              and ts_movgest.data_cancellazione is null
                              and ts_det_movgest.data_cancellazione is null
                              and r_movgest_bil_elem.data_cancellazione is null
                              and bil_elem.data_cancellazione is null
                              and d_movgest_ts_det_tipo.data_cancellazione is null;                          
                        IF NOT FOUND THEN
                        /* 25/02/2016: se non esiste il movimento non interrompo la procedura */
                           -- RAISE EXCEPTION 'Sub-Impegno/Sub-Accertamento senza Periodo. Non esiste il movimento %', elenco_prime_note.key_movimento;
                           -- return;
                           descr_movimento='Non esiste il movimento';
                        ELSE 
                        	sub_impegno= COALESCE(dati_movimento.movgest_ts_code,'');
                            soggetto_code_mod='';
    					    soggetto_desc_mod='';
                        END IF;     
                    ELSIF elenco_prime_note.collegamento_tipo_code in('MMGS','MMGE') THEN      
                    --raise notice 'TIPO_CODE = % - KEY = %', elenco_prime_note.collegamento_tipo_code,elenco_prime_note.key_movimento;
                                      
                  SELECT t_modifica.mod_id,r_modifica_stato.mod_stato_id, movgest.movgest_numero, movgest.movgest_desc,movgest.movgest_anno,
                          bil_elem.elem_code cod_capitolo, bil_elem.elem_code2 num_articolo,bil_elem.elem_id,
                          bil_elem.elem_code3 ueb, 
                          soggetto.soggetto_desc, soggetto.soggetto_code,
                          soggetto_mod.soggetto_desc desc_sogg_mod,
                          soggetto_mod.soggetto_code code_sogg_mod,
                          d_soggetto_classe.soggetto_classe_desc,
                          d_soggetto_classe.soggetto_classe_code,
                          ts_det_movgest.movgest_ts_det_importo imp_movimento, ts_movgest.movgest_ts_code
                            INTO dati_movimento
                            from siac_t_movgest movgest,                         
                             siac_t_movgest_ts_det ts_det_movgest,
                             siac_r_movgest_bil_elem  r_movgest_bil_elem,
                             siac_t_bil_elem		bil_elem,
                             siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,            
                             siac_t_movgest_ts	ts_movgest   
                             LEFT join siac_r_movgest_ts_sog	r_mov_gest_ts_sog
                            on (r_mov_gest_ts_sog.movgest_ts_id=ts_movgest.movgest_ts_id 
                            and r_mov_gest_ts_sog.data_cancellazione is NULL) 
                            LEFT join siac_t_soggetto		soggetto
                            on (soggetto.soggetto_id=r_mov_gest_ts_sog.soggetto_id         	
                             and soggetto.data_cancellazione is NULL) 
                             LEFT JOIN siac_r_movgest_ts_sog_mod r_movgest_ts_sog_mod
                             on (r_movgest_ts_sog_mod.movgest_ts_id=ts_movgest.movgest_ts_id
                              AND  r_movgest_ts_sog_mod.data_cancellazione IS NULL)  
                             LEFT join siac_t_soggetto		soggetto_mod
                            on (soggetto_mod.soggetto_id=r_movgest_ts_sog_mod.soggetto_id_new          	
                             and soggetto_mod.data_cancellazione is NULL)  
                            LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sogclasse
                             on (r_movgest_ts_sogclasse.movgest_ts_id=ts_movgest.movgest_ts_id
                                 AND r_movgest_ts_sogclasse.data_cancellazione IS NULL)
                            LEFT JOIN siac_d_soggetto_classe d_soggetto_classe
                                on (d_soggetto_classe.soggetto_classe_id=r_movgest_ts_sogclasse.soggetto_classe_id
                                and d_soggetto_classe.data_cancellazione IS NULL),
                             siac_t_movgest_ts_det_mod t_movgest_ts_det_mod    
                              LEFT join  siac_r_modifica_stato  r_modifica_stato           
                             ON (t_movgest_ts_det_mod.mod_stato_r_id=r_modifica_stato.mod_stato_r_id
                              and r_modifica_stato.data_cancellazione is null)
                             LEFT JOIN siac_t_modifica t_modifica 
                             on (t_modifica.mod_id=r_modifica_stato.mod_id
                              AND t_modifica.data_cancellazione IS NULL)                           
                  where ts_movgest.movgest_id=movgest.movgest_id
                            and ts_det_movgest.movgest_ts_id=  ts_movgest.movgest_ts_id
                            and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=ts_det_movgest.movgest_ts_det_tipo_id
                            and r_movgest_bil_elem.movgest_id=movgest.movgest_id
                            and bil_elem.elem_id=r_movgest_bil_elem.elem_id                   
                            and t_movgest_ts_det_mod.movgest_ts_id=  ts_movgest.movgest_ts_id       
                            and t_modifica.mod_id= elenco_prime_note.key_movimento
                            and bil_elem.ente_proprietario_id=p_ente_prop_id
                            and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                            and movgest.data_cancellazione is null
                            and ts_movgest.data_cancellazione is null
                            and ts_det_movgest.data_cancellazione is null
                            and r_movgest_bil_elem.data_cancellazione is null
                            and bil_elem.data_cancellazione is null
                            and d_movgest_ts_det_tipo.data_cancellazione is null; 
                  		 IF NOT FOUND THEN
                           descr_movimento='Non esiste il movimento';
                         ELSE 
                         	sub_impegno= COALESCE(dati_movimento.movgest_ts_code,'');
                           	soggetto_code_mod=COALESCE(dati_movimento.code_sogg_mod,'');
    						soggetto_desc_mod=COALESCE(dati_movimento.desc_sogg_mod,'');
                         END IF;
                    END IF;
--raise notice 'Sogg=%, Sogg_mod=%, Fam_sogg=%', dati_movimento.soggetto_code,  
		--soggetto_code_mod, dati_movimento.soggetto_classe_code; 
        
--if soggetto_code_mod <>''then
	--raise notice 'SOGGETTO MODIF= X%X',soggetto_code_mod;
--end if;
                     
                    	/* 25/02/2016: se non esiste il movimento non carico i dati */
                    if descr_movimento ='' THEN      
                    --raise notice 'SONO SUB-IMPEGNO %/%',dati_movimento.movgest_numero,dati_movimento.movgest_ts_code;             
                        if elenco_prime_note.evento_tipo_code='I' THEN
                            num_movimento=concat('IMP/',dati_movimento.movgest_numero);
                        else
                            num_movimento=concat('ACC/',dati_movimento.movgest_numero);
                        end if;
                        
                        --raise notice 'SUB=%',num_movimento;
                        if sub_impegno  <> '' THEN
                        	num_movimento= concat(num_movimento,'-',sub_impegno);
                        end if;
                        
                        -- raise notice 'SUB=%',num_movimento;
                        num_capitolo=dati_movimento.cod_capitolo;
                        num_articolo=dati_movimento.num_articolo;
                        ueb=dati_movimento.ueb;
                        descr_movimento=dati_movimento.movgest_desc;
                        if soggetto_code_mod <> '' THEN
                        	cod_beneficiario=soggetto_code_mod;
                        else
                        	cod_beneficiario=COALESCE(dati_movimento.soggetto_code,COALESCE(dati_movimento.soggetto_classe_code,''));
                        end if;
                        if soggetto_desc_mod <> '' THEN
                        	ragione_sociale=dati_movimento.soggetto_desc;   
                        else
                        	ragione_sociale=COALESCE(dati_movimento.soggetto_desc,COALESCE(dati_movimento.soggetto_classe_desc,''));
                        end if;
                        imp_movimento=dati_movimento.imp_movimento;

                            
                            /* salvo i dati correnti per il prossimo record delle prime note */
                        prec_num_movimento_key=elenco_prime_note.key_movimento;
                        prec_num_prima_nota=elenco_prime_note.num_prima_nota;
                            
                        prec_num_movimento= num_movimento;
                        prec_num_capitolo=num_capitolo;
                        prec_num_articolo=num_articolo;
                        prec_ueb=ueb;
                        prec_descr_movimento=descr_movimento;
                        prec_cod_beneficiario=cod_beneficiario;
                        prec_ragione_sociale=ragione_sociale;
                        prec_imp_movimento=imp_movimento;

                        
                        if elenco_prime_note.evento_tipo_code='I' THEN
                            /* nel caso degli impegni devo leggere la classificazione delle spese */
                          idProgramma=0;
                          idMacroAggreg=0;
                              /* cerco la classificazione del capitolo.
                                  mi servono solo MACROAGGREGATO e  PROGRAMMA */
                          for elenco_tipo_classif in
                              select class_tipo.classif_tipo_code, classif.classif_id
                              from siac_t_class classif, siac_d_class_tipo class_tipo, 
                                  siac_r_bil_elem_class r_bil_class
                              where classif.classif_tipo_id=class_tipo.classif_tipo_id
                              and classif.classif_id=r_bil_class.classif_id
                              and r_bil_class.elem_id=dati_movimento.elem_id
                              and classif.ente_proprietario_id=p_ente_prop_id
                              and class_tipo.classif_tipo_code IN('MACROAGGREGATO','PROGRAMMA')
                              and classif.data_cancellazione is NULL
                              and class_tipo.data_cancellazione is NULL
                              and r_bil_class.data_cancellazione is NULL
                          loop
                              --raise notice 'Estraggo %',dati_movimento.elem_id;
                              if elenco_tipo_classif.classif_tipo_code='MACROAGGREGATO' THEN
                                  idMacroAggreg = elenco_tipo_classif.classif_id;
                              elsif elenco_tipo_classif.classif_tipo_code='PROGRAMMA' THEN
                                  idProgramma = elenco_tipo_classif.classif_id;
                              end if;                                                          
                              
                          end loop;
                             
                          classif_bilancio='';
                              /* cerco la classificazione del capitolo sulla tabella temporanea */
                          IF idMacroAggreg IS NOT NULL AND idProgramma IS NOT NULL THEN
                            SELECT missione_code||programma_code||'-'||titusc_code||macroag_code  classificazione_bil
                            INTO dati_classif
                            FROM siac_rep_mis_pro_tit_mac_riga_anni a
                            WHERE a.macroag_id = idMacroAggreg AND a.programma_id = idProgramma
                            	and a.ente_proprietario_id=p_ente_prop_id
                                and a.utente=user_table;
                            IF NOT FOUND THEN
                                RAISE notice 'Non esiste la classificazione del capitolo di spesa 1. Elem_id = %. Movimento %. TipoEvento = %. CodeEvento = %', dati_movimento.elem_id, elenco_prime_note.key_movimento, elenco_prime_note.evento_tipo_code, elenco_prime_note.evento_code;
                                --return;
                            ELSE
                                classif_bilancio=dati_classif.classificazione_bil;                    
                                prec_classif_bilancio=classif_bilancio;
                            END IF;
                          else
                            classif_bilancio='';                    
                            prec_classif_bilancio='';
                          end if;
                        else /* evento_code = 'A' */
                          idCategoria=0;
                              /* cerco la classificazione del capitolo.
                                  mi serve solo la CATEGORIA??? */
                          for elenco_tipo_classif in
                              select class_tipo.classif_tipo_code, classif.classif_id
                              from siac_t_class classif, siac_d_class_tipo class_tipo, 
                                  siac_r_bil_elem_class r_bil_class
                              where classif.classif_tipo_id=class_tipo.classif_tipo_id
                              and classif.classif_id=r_bil_class.classif_id
                              and r_bil_class.elem_id=dati_movimento.elem_id
                              and classif.ente_proprietario_id=p_ente_prop_id
                              and class_tipo.classif_tipo_code IN('CATEGORIA')
                              and classif.data_cancellazione is NULL
                              and class_tipo.data_cancellazione is NULL
                              and r_bil_class.data_cancellazione is NULL
                          loop
                              --raise notice 'Estraggo %',dati_movimento.elem_id;
                              if elenco_tipo_classif.classif_tipo_code='CATEGORIA' THEN
                                  idCategoria = elenco_tipo_classif.classif_id;                          
                              end if;                                                          
                              
                          end loop;
                             
                          classif_bilancio='';
                          if idCategoria is not null then
                                  /* cerco la classificazione del capitolo sulla tabella temporanea */
                              SELECT titolo_code||tipologia_code||'-'||categoria_code  classificazione_bil
                              INTO dati_classif
                              FROM siac_rep_tit_tip_cat_riga_anni a
                              WHERE a.categoria_id = idCategoria
                              and a.ente_proprietario_id=p_ente_prop_id
                              and a.utente=user_table;
                              IF NOT FOUND THEN
                                   RAISE notice 'Non esiste la classificazione del capitolo di entrata. Elem_id = %', dati_movimento.elem_id;
                                 -- return;
                              ELSE
                                  classif_bilancio=dati_classif.classificazione_bil;                    
                                  prec_classif_bilancio=classif_bilancio;
                              END IF;        
                          else
                            classif_bilancio='';                    
                            prec_classif_bilancio='';
                          end if;            
                           -- END IF;
                        END IF;
                        
                      end if; 
                  end if; --if descr_movimento ='' THEN
               
                /* evento = Liquidazione */
            elsif  elenco_prime_note.evento_tipo_code='L' THEN
                BEGIN
                    /* se il record precedente aveva gli stessi dati, non eseguo di nuovo la query */                
                  if prec_num_movimento_key=elenco_prime_note.key_movimento AND 
                      prec_num_prima_nota=elenco_prime_note.num_prima_nota THEN
                      num_movimento=prec_num_movimento;
                      num_capitolo=prec_num_capitolo;
                      num_articolo=prec_num_articolo;
                      ueb=prec_ueb;
                      descr_movimento=prec_descr_movimento;
                      cod_beneficiario=prec_cod_beneficiario;
                      ragione_sociale=prec_ragione_sociale;
                      imp_movimento=prec_imp_movimento;
                      classif_bilancio=prec_classif_bilancio;
                     
                     -- raise notice 'Esiste già %',classif_bilancio;
                  ELSE                                       		                      
                        /* record nuovo: estraggo i dati del capitolo */                
                    SELECT liquidazione.liq_numero,   movgest.movgest_numero, movgest.movgest_desc,movgest.movgest_anno,
                        bil_elem.elem_code cod_capitolo, bil_elem.elem_code2 num_articolo,bil_elem.elem_id,
                        bil_elem.elem_code3 ueb, soggetto.soggetto_desc, soggetto.soggetto_code,
                        liquidazione.liq_importo imp_movimento      
                    INTO dati_movimento         
                    FROM siac_t_movgest		movgest,                                            
                        siac_r_liquidazione_movgest  r_liquid_movgest,       	
                        siac_r_movgest_bil_elem  r_movgest_bil_elem,
                        siac_t_bil_elem		bil_elem,
                        siac_t_movgest_ts	ts_movgest,
                        siac_t_liquidazione			liquidazione  
                        LEFT join siac_r_liquidazione_soggetto	r_liquid_ts_sog
                          on (r_liquid_ts_sog.liq_id=liquidazione.liq_id
                          		AND r_liquid_ts_sog.data_cancellazione IS NULL)  
                          LEFT join siac_t_soggetto		soggetto
                          on (soggetto.soggetto_id=r_liquid_ts_sog.soggetto_id
                          	and soggetto.data_cancellazione is NULL)                    
                        WHERE r_movgest_bil_elem.movgest_id=movgest.movgest_id
                          and bil_elem.elem_id=r_movgest_bil_elem.elem_id
                          and liquidazione.liq_id=elenco_prime_note.key_movimento
                          and liquidazione.ente_proprietario_id=p_ente_prop_id
                          and ts_movgest.movgest_id=movgest.movgest_id      
                          and liquidazione.liq_id=r_liquid_movgest.liq_id
                          and r_liquid_movgest.movgest_ts_id=ts_movgest.movgest_ts_id                  
                          and r_movgest_bil_elem.data_cancellazione is NULL
                          and bil_elem.data_cancellazione is NULL
                          and ts_movgest.data_cancellazione is NULL
                          and movgest.data_cancellazione is NULL                                                
                          and liquidazione.data_cancellazione is NULL;
                         -- and r_liquid_movgest.data_cancellazione is NULL;            
                          
                    IF NOT FOUND THEN
                    /* 25/02/2016: se non esiste il movimento non interrompo la procedura */
                       -- RAISE EXCEPTION 'Liquidazione senza Periodo. Non esiste il movimento %', elenco_prime_note.key_movimento;
                       -- return;
                       descr_movimento='Non esiste il movimento';
                    ELSE
                    --raise notice ' LIQUID = %', dati_movimento.liq_numero;
                    --raise notice 'MOV = %', elenco_prime_note.key_movimento;
                        num_movimento=concat('LIQ/',dati_movimento.liq_numero);
                        num_capitolo=dati_movimento.cod_capitolo;
                        num_articolo=dati_movimento.num_articolo;
                        ueb=dati_movimento.ueb;
                        descr_movimento=dati_movimento.movgest_desc;
                        cod_beneficiario=dati_movimento.soggetto_code;
                        ragione_sociale=dati_movimento.soggetto_desc;   
                        imp_movimento=dati_movimento.imp_movimento;

                            /* salvo i dati correnti per il prossimo record delle prime note */
                        prec_num_movimento_key=elenco_prime_note.key_movimento;
                        prec_num_prima_nota=elenco_prime_note.num_prima_nota;
                        
                        prec_num_movimento= num_movimento;
                        prec_num_capitolo=num_capitolo;
                        prec_num_articolo=num_articolo;
                        prec_ueb=ueb;
                        prec_descr_movimento=descr_movimento;
                        prec_cod_beneficiario=cod_beneficiario;
                        prec_ragione_sociale=ragione_sociale;
                        prec_imp_movimento=imp_movimento;
                        
         
                      idProgramma=0;
                      idMacroAggreg=0;
                          /* cerco la classificazione del capitolo.
                              mi servono solo MACROAGGREGATO e  PROGRAMMA */
                      for elenco_tipo_classif in
                          select class_tipo.classif_tipo_code, classif.classif_id
                          from siac_t_class classif, siac_d_class_tipo class_tipo, 
                              siac_r_bil_elem_class r_bil_class
                          where classif.classif_tipo_id=class_tipo.classif_tipo_id
                          and classif.classif_id=r_bil_class.classif_id
                          and r_bil_class.elem_id=dati_movimento.elem_id
                          and classif.ente_proprietario_id=p_ente_prop_id
                          and class_tipo.classif_tipo_code IN('MACROAGGREGATO','PROGRAMMA')
                          and classif.data_cancellazione is NULL
                          and class_tipo.data_cancellazione is NULL
                          and r_bil_class.data_cancellazione is NULL
                      loop
                          --raise notice 'Estraggo %',dati_movimento.elem_id;
                          if elenco_tipo_classif.classif_tipo_code='MACROAGGREGATO' THEN
                              idMacroAggreg = elenco_tipo_classif.classif_id;
                          elsif elenco_tipo_classif.classif_tipo_code='PROGRAMMA' THEN
                              idProgramma = elenco_tipo_classif.classif_id;
                          end if;                                                          
                          
                      end loop;
                         
                      classif_bilancio='';
                          /* cerco la classificazione del capitolo sulla tabella temporanea */
                      IF idMacroAggreg IS NOT NULL AND idProgramma IS NOT NULL THEN 
                        SELECT missione_code||programma_code||'-'||titusc_code||macroag_code  classificazione_bil
                        INTO dati_classif
                        FROM siac_rep_mis_pro_tit_mac_riga_anni a
                        WHERE macroag_id = idMacroAggreg AND programma_id = idProgramma
                        and a.ente_proprietario_id=p_ente_prop_id
                        and a.utente=user_table;
                        IF NOT FOUND THEN
                             RAISE notice 'Non esiste la classificazione del capitolo di spesa 2. Elem_id = %, MacroAggr %, Programma %', dati_movimento.elem_id, idMacroAggreg, idProgramma;	
                           -- return;
                        ELSE
                            classif_bilancio=dati_classif.classificazione_bil;                    
                            prec_classif_bilancio=classif_bilancio;
                        END IF;
                      ELSE
                      	classif_bilancio='';                    
						prec_classif_bilancio='';
                      END IF;
                       -- else /* evento_code = 'A' */
                                         
                      --  END IF;
                    END IF;
                    --raise notice 'NON Esiste già %',classif_bilancio;
                  end if; 
                END;        
            elsif  elenco_prime_note.evento_tipo_code='OP' OR
            		elenco_prime_note.evento_tipo_code='OI' THEN /* Ordinativo */
                BEGIN
                    /* se il record precedente aveva gli stessi dati, non eseguo di nuovo la query */                
                  if prec_num_movimento_key=elenco_prime_note.key_movimento AND 
                      prec_num_prima_nota=elenco_prime_note.num_prima_nota THEN
                      num_movimento=prec_num_movimento;
                      num_capitolo=prec_num_capitolo;
                      num_articolo=prec_num_articolo;
                      ueb=prec_ueb;
                      descr_movimento=prec_descr_movimento;
                      cod_beneficiario=prec_cod_beneficiario;
                      ragione_sociale=prec_ragione_sociale;
                      imp_movimento=prec_imp_movimento;
                      classif_bilancio=prec_classif_bilancio;
                      
                     -- raise notice 'Esiste già %',classif_bilancio;
                  ELSE                                       		                      
                        /* record nuovo: estraggo i dati del capitolo */                
                    SELECT ordinativo.ord_numero,
                    	ordinativo.ord_desc,
                        bil_elem.elem_code cod_capitolo, 
                        bil_elem.elem_code2 num_articolo,bil_elem.elem_id,
                        bil_elem.elem_code3 ueb, 
                        ts_det_ordinativo.ord_ts_det_importo imp_movimento ,
                        t_soggetto.soggetto_desc,
                        t_soggetto.soggetto_code
                    INTO dati_movimento                                     
                    FROM    	
                        siac_r_ordinativo_bil_elem  r_ord_bil_elem,
                        siac_t_bil_elem		bil_elem,
                        siac_r_ordinativo_soggetto  r_ord_soggetto,
                        siac_t_soggetto  			t_soggetto,
                        siac_t_ordinativo			ordinativo ,                        
                        siac_t_ordinativo_ts		ts_ordinativo, 
                        siac_t_ordinativo_ts_det		ts_det_ordinativo,
                        siac_d_ordinativo_ts_det_tipo  d_ts_det_ord_tipo                   
                        WHERE r_ord_bil_elem.ord_id=ordinativo.ord_id
                          and bil_elem.elem_id=r_ord_bil_elem.elem_id
                          and ordinativo.ord_id=elenco_prime_note.key_movimento    
                          and  ordinativo.ente_proprietario_id=p_ente_prop_id                       
                          and ts_ordinativo.ord_id=ordinativo.ord_id   
                          and ts_det_ordinativo.ord_ts_id  =ts_ordinativo.ord_ts_id   
                          and d_ts_det_ord_tipo.ord_ts_det_tipo_id=ts_det_ordinativo.ord_ts_det_tipo_id
                          and r_ord_soggetto.ord_id=ordinativo.ord_id
                          and t_soggetto.soggetto_id=r_ord_soggetto.soggetto_id
                          and   d_ts_det_ord_tipo.ord_ts_det_tipo_code='A'
                          and bil_elem.data_cancellazione is NULL
                          and ordinativo.data_cancellazione is NULL
                          and ts_ordinativo.data_cancellazione is NULL
                          and ts_det_ordinativo.data_cancellazione is NULL
                          and d_ts_det_ord_tipo.data_cancellazione is NULL
                          and r_ord_soggetto.data_cancellazione is NULL
                          and t_soggetto.data_cancellazione is NULL
                          and r_ord_bil_elem.data_cancellazione is NULL;               
                          
                    IF NOT FOUND THEN
                    /* 25/02/2016: se non esiste l'ordinativo non interrompo la procedura */
                        --RAISE EXCEPTION 'Non esiste l''ordinativo %', elenco_prime_note.key_movimento;
                       -- return;
                        descr_movimento='Non esiste l''ordinativo';
                    ELSE

                        num_movimento=concat('ORD/',dati_movimento.ord_numero);
                        num_capitolo=dati_movimento.cod_capitolo;
                        num_articolo=dati_movimento.num_articolo;
                        ueb=dati_movimento.ueb;
                        descr_movimento=dati_movimento.ord_desc;
                        cod_beneficiario=dati_movimento.soggetto_code;
                        ragione_sociale=dati_movimento.soggetto_desc;   
                        imp_movimento=dati_movimento.imp_movimento;

                                            
                            /* salvo i dati correnti per il prossimo record delle prime note */
                        prec_num_movimento_key=elenco_prime_note.key_movimento;
                        prec_num_prima_nota=elenco_prime_note.num_prima_nota;
                        
                        prec_num_movimento= num_movimento;
                        prec_num_capitolo=num_capitolo;
                        prec_num_articolo=num_articolo;
                        prec_ueb=ueb;
                        prec_descr_movimento=descr_movimento;
                        prec_cod_beneficiario=cod_beneficiario;
                        prec_ragione_sociale=ragione_sociale;
                        prec_imp_movimento=imp_movimento;
                        
						/* ordinativo di pagamento */
                    if elenco_prime_note.evento_tipo_code='OP' THEN 
                        idProgramma=0;
                        idMacroAggreg=0;
                            /* cerco la classificazione del capitolo.
                                mi servono solo MACROAGGREGATO e  PROGRAMMA */
                        for elenco_tipo_classif in
                            select class_tipo.classif_tipo_code, classif.classif_id
                            from siac_t_class classif, siac_d_class_tipo class_tipo, 
                                siac_r_bil_elem_class r_bil_class
                            where classif.classif_tipo_id=class_tipo.classif_tipo_id
                            and classif.classif_id=r_bil_class.classif_id
                            and r_bil_class.elem_id=dati_movimento.elem_id
                            and  classif.ente_proprietario_id=p_ente_prop_id 
                            and class_tipo.classif_tipo_code IN('MACROAGGREGATO','PROGRAMMA')
                            and classif.data_cancellazione is NULL
                            and class_tipo.data_cancellazione is NULL
                            and r_bil_class.data_cancellazione is NULL
                        loop
                            --raise notice 'Estraggo %',dati_movimento.elem_id;
                            if elenco_tipo_classif.classif_tipo_code='MACROAGGREGATO' THEN
                                idMacroAggreg = elenco_tipo_classif.classif_id;
                            elsif elenco_tipo_classif.classif_tipo_code='PROGRAMMA' THEN
                                idProgramma = elenco_tipo_classif.classif_id;
                            end if;                                                          
                          
                        end loop;
                         
                        classif_bilancio='';
                            /* cerco la classificazione del capitolo sulla tabella temporanea */
                        IF idMacroAggreg IS NOT NULL AND idProgramma IS NOT NULL THEN
                          SELECT missione_code||programma_code||'-'||titusc_code||macroag_code  classificazione_bil
                          INTO dati_classif
                          FROM siac_rep_mis_pro_tit_mac_riga_anni a
                          WHERE a.macroag_id = idMacroAggreg 
                          AND a.programma_id = idProgramma
                          and a.ente_proprietario_id=p_ente_prop_id
                          and a.utente=user_table;
                          IF NOT FOUND THEN
                              RAISE notice 'Non esiste la classificazione del capitolo di spesa 3. Elem_id = %, MacroAggr %, Programma %', dati_movimento.elem_id, idMacroAggreg, idProgramma;	
                              --return;
                          ELSE
                              classif_bilancio=dati_classif.classificazione_bil;                    
                              prec_classif_bilancio=classif_bilancio;
                          END IF;
						ELSE
                        	classif_bilancio='';                    
							prec_classif_bilancio='';
                        END IF;
                    ELSE
                    	idCategoria=0;
                          /* cerco la classificazione del capitolo.
                              mi serve solo la CATEGORIA??? */
                      for elenco_tipo_classif in
                          select class_tipo.classif_tipo_code, classif.classif_id
                          from siac_t_class classif, siac_d_class_tipo class_tipo, 
                              siac_r_bil_elem_class r_bil_class
                          where classif.classif_tipo_id=class_tipo.classif_tipo_id
                          and classif.classif_id=r_bil_class.classif_id
                          and r_bil_class.elem_id=dati_movimento.elem_id
                          and classif.ente_proprietario_id=p_ente_prop_id
                          and class_tipo.classif_tipo_code IN('CATEGORIA')
                          and classif.data_cancellazione is NULL
                          and class_tipo.data_cancellazione is NULL
                          and r_bil_class.data_cancellazione is NULL
                      loop
                          --raise notice 'Estraggo %',dati_movimento.elem_id;
                          if elenco_tipo_classif.classif_tipo_code='CATEGORIA' THEN
                              idCategoria = elenco_tipo_classif.classif_id;                          
                          end if;                                                          
                          
                      end loop;
                         
                      classif_bilancio='';
                      if idCategoria is not null then
                              /* cerco la classificazione del capitolo sulla tabella temporanea */
                          SELECT titolo_code||tipologia_code||'-'||categoria_code  classificazione_bil
                          INTO dati_classif
                          FROM siac_rep_tit_tip_cat_riga_anni a
                          WHERE a.categoria_id = idCategoria
                          and a.ente_proprietario_id=p_ente_prop_id
                          and a.utente=user_table;
                          IF NOT FOUND THEN
                               RAISE notice 'Non esiste la classificazione del capitolo di entrata. Elem_id = %', dati_movimento.elem_id;
                             -- return;
                          ELSE
                              classif_bilancio=dati_classif.classificazione_bil;                    
                              prec_classif_bilancio=classif_bilancio;
                          END IF;        
                      else
                      	classif_bilancio='';                    
                        prec_classif_bilancio='';
                      end if;            
                    END IF;
                    END IF;
                    --raise notice 'NON Esiste già %',classif_bilancio;
                  end if; 
                END;         
            elsif  elenco_prime_note.evento_tipo_code='DE' OR
            		elenco_prime_note.evento_tipo_code='DS' THEN /* Documento */                
                    /* se il record precedente aveva gli stessi dati, non eseguo di nuovo la query */                
                  if prec_num_movimento_key=elenco_prime_note.key_movimento AND 
                      prec_num_prima_nota=elenco_prime_note.num_prima_nota THEN
                      num_movimento=prec_num_movimento;
                      num_capitolo=prec_num_capitolo;
                      num_articolo=prec_num_articolo;
                      ueb=prec_ueb;
                      descr_movimento=prec_descr_movimento;
                      cod_beneficiario=prec_cod_beneficiario;
                      ragione_sociale=prec_ragione_sociale;
                      imp_movimento=prec_imp_movimento;
                      classif_bilancio=prec_classif_bilancio;
                      
                     -- raise notice 'Esiste già %',classif_bilancio;
                  ELSE                                       		                      
                        /* record nuovo: estraggo i dati del capitolo */                
                           
           			 SELECT t_doc.doc_numero, t_subdoc.subdoc_numero,  t_doc.doc_desc,
                      movgest.movgest_numero, movgest.movgest_desc,movgest.movgest_anno,
                        bil_elem.elem_code cod_capitolo, bil_elem.elem_code2 num_articolo,bil_elem.elem_id,
                        bil_elem.elem_code3 ueb, soggetto.soggetto_desc, soggetto.soggetto_code,
                       t_doc.doc_importo imp_movimento, d_doc_tipo.doc_tipo_code 
                  	INTO dati_movimento           
                    FROM siac_t_movgest		movgest,                                            
                        siac_r_subdoc_movgest_ts  r_subdoc_movgest_ts,       	
                        siac_r_movgest_bil_elem  r_movgest_bil_elem,
                        siac_t_bil_elem		bil_elem,
                        siac_t_movgest_ts	ts_movgest,
                        siac_d_doc_tipo    d_doc_tipo,
                        siac_t_doc			t_doc
                        	LEFT JOIN siac_r_doc_sog r_doc_sog
                            	ON (r_doc_sog.doc_id=t_doc.doc_id
                                	AND r_doc_sog.data_cancellazione IS NULL)
                            LEFT JOIN siac_t_soggetto		soggetto
                        		ON (soggetto.soggetto_id=r_doc_sog.soggetto_id
                                	AND soggetto.data_cancellazione IS NULL), 
                        siac_t_subdoc		t_subdoc                      
                        WHERE r_movgest_bil_elem.movgest_id=movgest.movgest_id
                          and bil_elem.elem_id=r_movgest_bil_elem.elem_id
                          and t_doc.doc_id=t_subdoc.doc_id
                          and t_subdoc.subdoc_id= elenco_prime_note.key_movimento
                          and t_doc.ente_proprietario_id=p_ente_prop_id
                          --and t_doc.doc_id=elenco_prime_note.key_movimento
                          and ts_movgest.movgest_id=movgest.movgest_id      
                          and t_subdoc.subdoc_id=r_subdoc_movgest_ts.subdoc_id
                          and r_subdoc_movgest_ts.movgest_ts_id=ts_movgest.movgest_ts_id  
                          and d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id                
                          and r_movgest_bil_elem.data_cancellazione is NULL
                          and bil_elem.data_cancellazione is NULL
                          and ts_movgest.data_cancellazione is NULL
                          and movgest.data_cancellazione is NULL                      
                          AND t_doc.data_cancellazione IS NULL
                          and t_subdoc.data_cancellazione is NULL
                          and r_subdoc_movgest_ts.data_cancellazione IS NULL
                          AND d_doc_tipo.data_cancellazione IS NULL;               
                          
                    IF NOT FOUND THEN
                    /* 25/02/2016: se non esiste la fattura non interrompo la procedura */
                        --RAISE EXCEPTION 'Non esiste la Fattura % per la Pnota %', elenco_prime_note.key_movimento, elenco_prime_note.num_prima_nota;
                       -- return;
                       descr_movimento='Non esiste la Fattura';
                    ELSE
                    		/* per le fatture, il numero di riga è
                            	il numero di quota!!! */
						num_riga=dati_movimento.subdoc_numero;
                        num_movimento=concat(dati_movimento.doc_tipo_code,'/',dati_movimento.doc_numero);
                    	/* per le fatture non stampo il capitolo, perchè potrebbero
                        	essere più di 1 */
                       -- num_capitolo=dati_movimento.cod_capitolo;
                       -- num_articolo=dati_movimento.num_articolo;
                       -- ueb=dati_movimento.ueb;
                        num_capitolo='';
                        num_articolo='';
                        ueb='';
                        descr_movimento=dati_movimento.doc_desc;
                        cod_beneficiario=dati_movimento.soggetto_code;
                        ragione_sociale=dati_movimento.soggetto_desc;   
                        imp_movimento=dati_movimento.imp_movimento;

                                            
                            /* salvo i dati correnti per il prossimo record delle prime note */
                        prec_num_movimento_key=elenco_prime_note.key_movimento;
                        prec_num_prima_nota=elenco_prime_note.num_prima_nota;
                        
                        prec_num_movimento= num_movimento;
                        prec_num_capitolo=num_capitolo;
                        prec_num_articolo=num_articolo;
                        prec_ueb=ueb;
                        prec_descr_movimento=descr_movimento;
                        prec_cod_beneficiario=cod_beneficiario;
                        prec_ragione_sociale=ragione_sociale;
                        prec_imp_movimento=imp_movimento;
                        
						
                      /* per le fatture non stampo la classificazione di bilancio */                       
                    classif_bilancio='';
                    /*if elenco_prime_note.evento_tipo_code='DS' THEN 
                  			 /* Documento di spesa */
                        idProgramma=0;
                        idMacroAggreg=0;
                            /* cerco la classificazione del capitolo.
                                mi servono solo MACROAGGREGATO e  PROGRAMMA */
                        for elenco_tipo_classif in
                            select class_tipo.classif_tipo_code, classif.classif_id
                            from siac_t_class classif, siac_d_class_tipo class_tipo, 
                                siac_r_bil_elem_class r_bil_class
                            where classif.classif_tipo_id=class_tipo.classif_tipo_id
                            and classif.classif_id=r_bil_class.classif_id
                            and r_bil_class.elem_id=dati_movimento.elem_id
                            and class_tipo.classif_tipo_code IN('MACROAGGREGATO','PROGRAMMA')
                            and classif.data_cancellazione is NULL
                            and class_tipo.data_cancellazione is NULL
                            and r_bil_class.data_cancellazione is NULL
                        loop
                            --raise notice 'Estraggo %',dati_movimento.elem_id;
                            if elenco_tipo_classif.classif_tipo_code='MACROAGGREGATO' THEN
                                idMacroAggreg = elenco_tipo_classif.classif_id;
                            elsif elenco_tipo_classif.classif_tipo_code='PROGRAMMA' THEN
                                idProgramma = elenco_tipo_classif.classif_id;
                            end if;                                                          
                          
                        end loop;
                         
                        classif_bilancio='';
                      
                            /* cerco la classificazione del capitolo sulla tabella temporanea */
                        IF idMacroAggreg IS NOT NULL AND idProgramma IS NOT NULL THEN
                          SELECT missione_code||programma_code||'-'||titusc_code||macroag_code  classificazione_bil
                          INTO dati_classif
                          FROM siac_rep_mis_pro_tit_mac_riga_anni
                          WHERE macroag_id = idMacroAggreg AND programma_id = idProgramma;
                          IF NOT FOUND THEN
                              RAISE notice 'Non esiste la classificazione del capitolo di spesa 3. Elem_id = %, MacroAggr %, Programma %', dati_movimento.elem_id, idMacroAggreg, idProgramma;	
                              --return;
                          ELSE
                              classif_bilancio=dati_classif.classificazione_bil;                    
                              prec_classif_bilancio=classif_bilancio;
                          END IF;
						ELSE
                        	classif_bilancio='';                    
							prec_classif_bilancio='';
                        END IF;
                    ELSE /* documento di entrata */
                    	idCategoria=0;
                          /* cerco la classificazione del capitolo.
                              mi serve solo la CATEGORIA??? */
                      for elenco_tipo_classif in
                          select class_tipo.classif_tipo_code, classif.classif_id
                          from siac_t_class classif, siac_d_class_tipo class_tipo, 
                              siac_r_bil_elem_class r_bil_class
                          where classif.classif_tipo_id=class_tipo.classif_tipo_id
                          and classif.classif_id=r_bil_class.classif_id
                          and r_bil_class.elem_id=dati_movimento.elem_id
                          and class_tipo.classif_tipo_code IN('CATEGORIA')
                          and classif.data_cancellazione is NULL
                          and class_tipo.data_cancellazione is NULL
                          and r_bil_class.data_cancellazione is NULL
                      loop
                          --raise notice 'Estraggo %',dati_movimento.elem_id;
                          if elenco_tipo_classif.classif_tipo_code='CATEGORIA' THEN
                              idCategoria = elenco_tipo_classif.classif_id;                          
                          end if;                                                          
                          
                      end loop;
                         
                      classif_bilancio='';
                      if idCategoria is not null then
                              /* cerco la classificazione del capitolo sulla tabella temporanea */
                          SELECT titolo_code||tipologia_code||'-'||categoria_code  classificazione_bil
                          INTO dati_classif
                          FROM siac_rep_tit_tip_cat_riga_anni
                          WHERE categoria_id = idCategoria;
                          IF NOT FOUND THEN
                               RAISE notice 'Non esiste la classificazione del capitolo di entrata. Elem_id = %', dati_movimento.elem_id;
                             -- return;
                          ELSE
                              classif_bilancio=dati_classif.classificazione_bil;                    
                              prec_classif_bilancio=classif_bilancio;
                          END IF;        
                      else
                      	classif_bilancio='';                    
                        prec_classif_bilancio='';
                      end if;            
                    END IF;*/
                    END IF;
                    --raise notice 'NON Esiste già %',classif_bilancio;
                  end if;                                 
            end if;	/* fine IF su evento_tipo_code */
                    
--raise notice ' Tipo prima nota: %', elenco_prime_note.causale_ep_tipo_code;
--raise notice 'code_programma1 = %, code_programma_prec = %', 
	--code_programma, code_programma_prec;
    
--SIAC-8656 20/10/2022.
--Occorre visualizzare la missione e programma.
--Nel caso delle prime note libere sono lette nella prima query
--che estrae le prime note.
if elenco_prime_note.causale_ep_tipo_code = 'LIB' then
	/*
        --INC000006526089 09/11/2022:
        Missione e programma non possono essere lette in fase
        di estrazione delle prime note in quanto esistono solo
        per i movimenti "Dare".
        Invece devo caricare questi dati in entrambi i movimenti
        perche' nel report raggruppo per prima nota e se il record
        "Avere" e' il primo per una certa prima nota non visualizzo
        il dato di Missione/Programma.
    code_missione:=elenco_prime_note.missione_code_lib;
    desc_missione:=elenco_prime_note.missione_desc_lib;
    code_programma:=elenco_prime_note.programma_code_lib;
    desc_programma:=elenco_prime_note.programma_desc_lib;  
    
    */    
    select COALESCE(class_progr.classif_code,'') programma_code,
         	COALESCE(class_progr.classif_desc,'') programma_desc
  		into code_programma, desc_programma
        from siac_t_mov_ep		mov_ep,
            siac_t_mov_ep_det	mov_ep_det,
            siac_t_class class_progr,
            siac_d_class_tipo tipo_class_progr,
            siac_r_mov_ep_det_class r_mov_ep_det_class_progr
        where mov_ep.movep_id=mov_ep_det.movep_id     
        and tipo_class_progr.classif_tipo_id=class_progr.classif_tipo_id
        and r_mov_ep_det_class_progr.classif_id=class_progr.classif_id
        and r_mov_ep_det_class_progr.movep_det_id=mov_ep_det.movep_det_id
        and tipo_class_progr.ente_proprietario_id=p_ente_prop_id
        	--regep_id contiene l'id della prima nota
        and mov_ep.regep_id =elenco_prime_note.pnota_id 
        and tipo_class_progr.classif_tipo_code='PROGRAMMA'
        and r_mov_ep_det_class_progr.data_cancellazione IS NULL 
        and class_progr.data_cancellazione IS NULL  
        and mov_ep.data_cancellazione IS NULL   
        and mov_ep_det.data_cancellazione IS NULL;
          
        
        select COALESCE(class_progr.classif_code,'') missione_code,
               COALESCE(class_progr.classif_desc,'') missione_desc
          into code_missione, desc_missione
        from siac_t_mov_ep		mov_ep,
            siac_t_mov_ep_det	mov_ep_det,
            siac_t_class class_progr,
            siac_d_class_tipo tipo_class_progr,
            siac_r_mov_ep_det_class r_mov_ep_det_class_progr
        where mov_ep.movep_id=mov_ep_det.movep_id     
        and tipo_class_progr.classif_tipo_id=class_progr.classif_tipo_id
        and r_mov_ep_det_class_progr.classif_id=class_progr.classif_id
        and r_mov_ep_det_class_progr.movep_det_id=mov_ep_det.movep_det_id
        and tipo_class_progr.ente_proprietario_id=p_ente_prop_id
        	--regep_id contiene l'id della prima nota
        and mov_ep.regep_id =elenco_prime_note.pnota_id
        and tipo_class_progr.classif_tipo_code='MISSIONE'
        and r_mov_ep_det_class_progr.data_cancellazione IS NULL 
        and class_progr.data_cancellazione IS NULL  
        and mov_ep.data_cancellazione IS NULL   
        and mov_ep_det.data_cancellazione IS NULL;
else
	--nel caso delle prime note integrate occorre prendere la missione
    --e programma relative al capitolo.
    --Vale solo per i capitoli di spesa.
	--raise notice ' ELEM_ID = %, elem_id_prec = %', 
    	--dati_movimento.elem_id, elem_id_prec; 
        
    --eseguo la query solo se il capitolo e' diverso da quello del record
    --precedente in modo da appesantire meno la gestione.
    if elem_id_prec = dati_movimento.elem_id then     	        
        code_missione:=code_missione_prec;
		desc_missione:=desc_missione_prec;
		code_programma:=code_programma_prec;
		desc_programma:=desc_programma_prec;        
    else
      with capitoli as(
        select distinct programma.classif_id programma_id,
                macroaggr.classif_id macroaggregato_id,          
                capitolo.elem_id
        from siac_d_class_tipo programma_tipo,
             siac_t_class programma,
             siac_d_class_tipo macroaggr_tipo,
             siac_t_class macroaggr,
             siac_t_bil_elem capitolo,
             siac_d_bil_elem_tipo tipo_elemento,
             siac_r_bil_elem_class r_capitolo_programma,
             siac_r_bil_elem_class r_capitolo_macroaggr, 
             siac_d_bil_elem_stato stato_capitolo, 
             siac_r_bil_elem_stato r_capitolo_stato,
             siac_d_bil_elem_categoria cat_del_capitolo,
             siac_r_bil_elem_categoria r_cat_capitolo 
        where 	
            programma.classif_tipo_id=programma_tipo.classif_tipo_id 		
            and	programma.classif_id=r_capitolo_programma.classif_id			    
            and	macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 		
            and	macroaggr.classif_id=r_capitolo_macroaggr.classif_id			    
            and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 					
            and	capitolo.elem_id=r_capitolo_programma.elem_id					
            and	capitolo.elem_id=r_capitolo_macroaggr.elem_id						
            and	capitolo.elem_id				=	r_capitolo_stato.elem_id	
            and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
            and	capitolo.elem_id				=	r_cat_capitolo.elem_id		
            and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id	   	
            and	capitolo.ente_proprietario_id=p_ente_prop_id 											 
            and	programma_tipo.classif_tipo_code='PROGRAMMA'							
            and	macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						
            and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     	
            and	stato_capitolo.elem_stato_code	=	'VA'	
            and capitolo.elem_id = dati_movimento.elem_id					     							
            and	programma_tipo.data_cancellazione 			is null
            and	programma.data_cancellazione 				is null
            and	macroaggr_tipo.data_cancellazione 			is null
            and	macroaggr.data_cancellazione 				is null
            and	capitolo.data_cancellazione 				is null
            and	tipo_elemento.data_cancellazione 			is null
            and	r_capitolo_programma.data_cancellazione 	is null
            and	r_capitolo_macroaggr.data_cancellazione 	is null 
            and	stato_capitolo.data_cancellazione 			is null 
            and	r_capitolo_stato.data_cancellazione 		is null
            and	cat_del_capitolo.data_cancellazione 		is null
            and	r_cat_capitolo.data_cancellazione 			is null),
         strut_bilancio as(
              select *
              from siac_rep_mis_pro_tit_mac_riga_anni a
              where a.ente_proprietario_id=p_ente_prop_id
                  and a.utente=user_table)
        select COALESCE(strut_bilancio.missione_code,'') code_missione,
          COALESCE(strut_bilancio.missione_desc,'') desc_missione,
          COALESCE(strut_bilancio.programma_code,'') code_programma,
          COALESCE(strut_bilancio.programma_desc,'') desc_programma
        into code_missione, desc_missione, code_programma, desc_programma
        from capitoli  
          left JOIN strut_bilancio on (strut_bilancio.programma_id =  capitoli.programma_id
                          AND strut_bilancio.macroag_id =  capitoli.macroaggregato_id);         
		IF NOT FOUND THEN
        	code_missione:='';
          	desc_missione:='';
          	code_programma:='';
          	desc_programma:='';
         end if;
         
        code_missione_prec:=code_missione;
        desc_missione_prec:=desc_missione;
        code_programma_prec:=code_programma;
        desc_programma_prec:=desc_programma;
        elem_id_prec = dati_movimento.elem_id;
        
        --raise notice 'code_programma2 = % ', code_programma;
    end if;
    
    
end if;   


--Nel campo miss_prog_display carico il dato di missione/programma da
--visualizzare nel report.
--In questo modo sara' piu' semplice modificarlo se si vuole in un
--formato diverso.
miss_prog_display := code_programma;
      
    return next;
        
        nome_ente='';
        num_movimento='';
        cod_beneficiario='';
        ragione_sociale='';
        num_capitolo='';
        num_articolo='';
        ueb='';
        classif_bilancio='';
        imp_movimento=0;
        descr_movimento='';
        num_prima_nota=0;
        num_prima_nota_def=0;
        data_registrazione=NULL;
        data_registrazione_def=NULL;
        stato_prima_nota='';
        descr_prima_nota='';
        cod_causale='';
        num_riga=0;
        cod_conto='';
        descr_riga='';
        importo_dare=0;
        importo_avere=0;
        key_movimento=0;
        sub_impegno='';
        soggetto_code_mod='';
    	soggetto_desc_mod='';
        code_missione:='';
    	desc_missione:='';
    	code_programma:='';
    	desc_programma:='';
        miss_prog_display:='';
        
        end loop;
  
    	/* cancello le strutture temporanee dei capitoli */
	delete from siac_rep_mis_pro_tit_mac_riga_anni 	where utente=user_table;
  	delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;
  
exception
	when no_data_found THEN
		raise notice 'Prime note non trovate' ;
		--return next;
	when others  THEN
		--raise notice 'errore nella lettura delle prime note ';
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'PRIME NOTE',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR066_prime_note_integrate" (p_ente_prop_id integer, p_anno varchar, p_data_reg_da date, p_data_reg_a date, p_num_prima_nota integer, p_num_prima_nota_def integer, p_tipologia varchar, p_tipo_evento varchar, p_evento varchar)
  OWNER TO siac;
  
--SIAC-8656 - Maurizio - FINE

-- SIAC-8837 Sofia 27.10.2022 - inizio 
create table if not exists siac_bko_t_adeguamento_causali_2021 as 
select *
from siac_bko_t_adeguamento_causali bko 
where bko.ente_proprietario_id in (2,3,4,5,10,16);

delete
from siac_bko_t_adeguamento_causali bko 
where bko.ente_proprietario_id in (2,3,4,5,10,16);

insert into siac_bko_t_adeguamento_causali (codice_causale,tipo_operazione,ente_proprietario_id) select   'ACC-E.9.01.99.03.001','C',ente.ente_proprietario_id from siac_t_ente_proprietario ente where ente.ente_proprietario_id in (2,3,4,5,10,16)  and not exists ( select 1 from siac_bko_t_adeguamento_causali bko where bko.ente_proprietario_id=ente.ente_proprietario_id and bko.codice_causale='ACC-E.9.01.99.03.001');
insert into siac_bko_t_adeguamento_causali (codice_causale,tipo_operazione,ente_proprietario_id) select   'ROR-A-CM-E.9.01.99.03.001','C',ente.ente_proprietario_id from siac_t_ente_proprietario ente where ente.ente_proprietario_id in (2,3,4,5,10,16)  and not exists ( select 1 from siac_bko_t_adeguamento_causali bko where bko.ente_proprietario_id=ente.ente_proprietario_id and bko.codice_causale='ROR-A-CM-E.9.01.99.03.001');
insert into siac_bko_t_adeguamento_causali (codice_causale,tipo_operazione,ente_proprietario_id) select   'ROR-A-COM-E.9.01.99.03.001','C',ente.ente_proprietario_id from siac_t_ente_proprietario ente where ente.ente_proprietario_id in (2,3,4,5,10,16)  and not exists ( select 1 from siac_bko_t_adeguamento_causali bko where bko.ente_proprietario_id=ente.ente_proprietario_id and bko.codice_causale='ROR-A-COM-E.9.01.99.03.001');
insert into siac_bko_t_adeguamento_causali (codice_causale,tipo_operazione,ente_proprietario_id) select   'ROR-A-RM-E.9.01.99.03.001','C',ente.ente_proprietario_id from siac_t_ente_proprietario ente where ente.ente_proprietario_id in (2,3,4,5,10,16)  and not exists ( select 1 from siac_bko_t_adeguamento_causali bko where bko.ente_proprietario_id=ente.ente_proprietario_id and bko.codice_causale='ROR-A-RM-E.9.01.99.03.001');
insert into siac_bko_t_adeguamento_causali (codice_causale,tipo_operazione,ente_proprietario_id) select   'ROR-A-RP-E.9.01.99.03.001','C',ente.ente_proprietario_id from siac_t_ente_proprietario ente where ente.ente_proprietario_id in (2,3,4,5,10,16)  and not exists ( select 1 from siac_bko_t_adeguamento_causali bko where bko.ente_proprietario_id=ente.ente_proprietario_id and bko.codice_causale='ROR-A-RP-E.9.01.99.03.001');
insert into siac_bko_t_adeguamento_causali (codice_causale,tipo_operazione,ente_proprietario_id) select   'ROR-CC-A-CM-E.9.01.99.03.001','C',ente.ente_proprietario_id from siac_t_ente_proprietario ente where ente.ente_proprietario_id in (2,3,4,5,10,16)  and not exists ( select 1 from siac_bko_t_adeguamento_causali bko where bko.ente_proprietario_id=ente.ente_proprietario_id and bko.codice_causale='ROR-CC-A-CM-E.9.01.99.03.001');
insert into siac_bko_t_adeguamento_causali (codice_causale,tipo_operazione,ente_proprietario_id) select   'ROR-R-A-CM-E.9.01.99.03.001','C',ente.ente_proprietario_id from siac_t_ente_proprietario ente where ente.ente_proprietario_id in (2,3,4,5,10,16)  and not exists ( select 1 from siac_bko_t_adeguamento_causali bko where bko.ente_proprietario_id=ente.ente_proprietario_id and bko.codice_causale='ROR-R-A-CM-E.9.01.99.03.001');
insert into siac_bko_t_adeguamento_causali (codice_causale,tipo_operazione,ente_proprietario_id) select   'IMP-U.5.01.01.01.001','C',ente.ente_proprietario_id from siac_t_ente_proprietario ente where ente.ente_proprietario_id in (2,3,4,5,10,16)  and not exists ( select 1 from siac_bko_t_adeguamento_causali bko where bko.ente_proprietario_id=ente.ente_proprietario_id and bko.codice_causale='IMP-U.5.01.01.01.001');
insert into siac_bko_t_adeguamento_causali (codice_causale,tipo_operazione,ente_proprietario_id) select   'ROR-I-CM-U.5.01.01.01.001','C',ente.ente_proprietario_id from siac_t_ente_proprietario ente where ente.ente_proprietario_id in (2,3,4,5,10,16)  and not exists ( select 1 from siac_bko_t_adeguamento_causali bko where bko.ente_proprietario_id=ente.ente_proprietario_id and bko.codice_causale='ROR-I-CM-U.5.01.01.01.001');
insert into siac_bko_t_adeguamento_causali (codice_causale,tipo_operazione,ente_proprietario_id) select   'ROR-I-COM-U.5.01.01.01.001','C',ente.ente_proprietario_id from siac_t_ente_proprietario ente where ente.ente_proprietario_id in (2,3,4,5,10,16)  and not exists ( select 1 from siac_bko_t_adeguamento_causali bko where bko.ente_proprietario_id=ente.ente_proprietario_id and bko.codice_causale='ROR-I-COM-U.5.01.01.01.001');
insert into siac_bko_t_adeguamento_causali (codice_causale,tipo_operazione,ente_proprietario_id) select   'ROR-I-RM-U.5.01.01.01.001','C',ente.ente_proprietario_id from siac_t_ente_proprietario ente where ente.ente_proprietario_id in (2,3,4,5,10,16)  and not exists ( select 1 from siac_bko_t_adeguamento_causali bko where bko.ente_proprietario_id=ente.ente_proprietario_id and bko.codice_causale='ROR-I-RM-U.5.01.01.01.001');
insert into siac_bko_t_adeguamento_causali (codice_causale,tipo_operazione,ente_proprietario_id) select   'ROR-I-RP-U.5.01.01.01.001','C',ente.ente_proprietario_id from siac_t_ente_proprietario ente where ente.ente_proprietario_id in (2,3,4,5,10,16)  and not exists ( select 1 from siac_bko_t_adeguamento_causali bko where bko.ente_proprietario_id=ente.ente_proprietario_id and bko.codice_causale='ROR-I-RP-U.5.01.01.01.001');
insert into siac_bko_t_adeguamento_causali (codice_causale,tipo_operazione,ente_proprietario_id) select   'ROR-R-I-CM-U.5.01.01.01.001','C',ente.ente_proprietario_id from siac_t_ente_proprietario ente where ente.ente_proprietario_id in (2,3,4,5,10,16)  and not exists ( select 1 from siac_bko_t_adeguamento_causali bko where bko.ente_proprietario_id=ente.ente_proprietario_id and bko.codice_causale='ROR-R-I-CM-U.5.01.01.01.001');
insert into siac_bko_t_adeguamento_causali (codice_causale,tipo_operazione,ente_proprietario_id) select   'ROR-I-RM-U.7.01.99.01.001','C',ente.ente_proprietario_id from siac_t_ente_proprietario ente where ente.ente_proprietario_id in (2,3,4,5,10,16)  and not exists ( select 1 from siac_bko_t_adeguamento_causali bko where bko.ente_proprietario_id=ente.ente_proprietario_id and bko.codice_causale='ROR-I-RM-U.7.01.99.01.001');
insert into siac_bko_t_adeguamento_causali (codice_causale,tipo_operazione,ente_proprietario_id) select   'ROR-I-RP-U.7.01.99.01.001','C',ente.ente_proprietario_id from siac_t_ente_proprietario ente where ente.ente_proprietario_id in (2,3,4,5,10,16)  and not exists ( select 1 from siac_bko_t_adeguamento_causali bko where bko.ente_proprietario_id=ente.ente_proprietario_id and bko.codice_causale='ROR-I-RP-U.7.01.99.01.001');
insert into siac_bko_t_adeguamento_causali (codice_causale,tipo_operazione,ente_proprietario_id) select   'ROR-I-RM-U.7.01.99.02.001','C',ente.ente_proprietario_id from siac_t_ente_proprietario ente where ente.ente_proprietario_id in (2,3,4,5,10,16)  and not exists ( select 1 from siac_bko_t_adeguamento_causali bko where bko.ente_proprietario_id=ente.ente_proprietario_id and bko.codice_causale='ROR-I-RM-U.7.01.99.02.001');
insert into siac_bko_t_adeguamento_causali (codice_causale,tipo_operazione,ente_proprietario_id) select   'ROR-I-RP-U.7.01.99.02.001','C',ente.ente_proprietario_id from siac_t_ente_proprietario ente where ente.ente_proprietario_id in (2,3,4,5,10,16)  and not exists ( select 1 from siac_bko_t_adeguamento_causali bko where bko.ente_proprietario_id=ente.ente_proprietario_id and bko.codice_causale='ROR-I-RP-U.7.01.99.02.001');
insert into siac_bko_t_adeguamento_causali (codice_causale,tipo_operazione,ente_proprietario_id) select   'ROR-I-CM-U.7.02.05.01.001','C',ente.ente_proprietario_id from siac_t_ente_proprietario ente where ente.ente_proprietario_id in (2,3,4,5,10,16)  and not exists ( select 1 from siac_bko_t_adeguamento_causali bko where bko.ente_proprietario_id=ente.ente_proprietario_id and bko.codice_causale='ROR-I-CM-U.7.02.05.01.001');
insert into siac_bko_t_adeguamento_causali (codice_causale,tipo_operazione,ente_proprietario_id) select   'ROR-I-COM-U.7.02.05.01.001','C',ente.ente_proprietario_id from siac_t_ente_proprietario ente where ente.ente_proprietario_id in (2,3,4,5,10,16)  and not exists ( select 1 from siac_bko_t_adeguamento_causali bko where bko.ente_proprietario_id=ente.ente_proprietario_id and bko.codice_causale='ROR-I-COM-U.7.02.05.01.001');
insert into siac_bko_t_adeguamento_causali (codice_causale,tipo_operazione,ente_proprietario_id) select   'ROR-I-RM-U.7.02.05.01.001','C',ente.ente_proprietario_id from siac_t_ente_proprietario ente where ente.ente_proprietario_id in (2,3,4,5,10,16)  and not exists ( select 1 from siac_bko_t_adeguamento_causali bko where bko.ente_proprietario_id=ente.ente_proprietario_id and bko.codice_causale='ROR-I-RM-U.7.02.05.01.001');
insert into siac_bko_t_adeguamento_causali (codice_causale,tipo_operazione,ente_proprietario_id) select   'ROR-I-RP-U.7.02.05.01.001','C',ente.ente_proprietario_id from siac_t_ente_proprietario ente where ente.ente_proprietario_id in (2,3,4,5,10,16)  and not exists ( select 1 from siac_bko_t_adeguamento_causali bko where bko.ente_proprietario_id=ente.ente_proprietario_id and bko.codice_causale='ROR-I-RP-U.7.02.05.01.001');
insert into siac_bko_t_adeguamento_causali (codice_causale,tipo_operazione,ente_proprietario_id) select   'ROR-R-I-CM-U.7.02.05.01.001','C',ente.ente_proprietario_id from siac_t_ente_proprietario ente where ente.ente_proprietario_id in (2,3,4,5,10,16)  and not exists ( select 1 from siac_bko_t_adeguamento_causali bko where bko.ente_proprietario_id=ente.ente_proprietario_id and bko.codice_causale='ROR-R-I-CM-U.7.02.05.01.001');

update siac_t_causale_ep ep 
set    validita_fine='2022-12-31'::timestamp,
       login_operazione=ep.login_operazione||'-SIAC-8837'
from siac_bko_t_adeguamento_causali bko ,
     siac_d_ambito ambito
where bko.ente_proprietario_id in (2,3,4,5,10,14,16)
and   bko.tipo_operazione='C'
and   ep.ente_proprietario_id=bko.ente_proprietario_id
and   ep.causale_ep_code=bko.codice_causale
and   ambito.ambito_id=ep.ambito_id
and   ambito.ambito_code=bko.ambito 
and   ep.data_cancellazione is null;


update siac_r_evento_causale r
set    validita_fine='2022-12-31'::timestamp,
       login_operazione=r.login_operazione||'-SIAC-8837'
from siac_bko_t_adeguamento_causali bko ,
     siac_t_causale_ep ep ,siac_d_ambito ambito,
     siac_d_evento evento
where bko.ente_proprietario_id  in (2,3,4,5,10,14,16)
and   bko.tipo_operazione='C'
and   ep.ente_proprietario_id=bko.ente_proprietario_id
and   ep.causale_ep_code=bko.codice_causale
and   ambito.ambito_id=ep.ambito_id
and   ambito.ambito_code=bko.ambito 
and   r.causale_ep_id=ep.causale_ep_id
and   evento.evento_id=r.evento_id
and   ep.data_cancellazione is null 
and   R.data_cancellazione is null;

-- SIAC-8837 Sofia 27.10.2022 - fine 
