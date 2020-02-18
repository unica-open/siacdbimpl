/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_programmi_elabora (
  fasebilelabid integer,
  enteproprietarioid integer,
  annobilancio integer,
  tipoapertura varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
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
    numeroProgr                      integer:=null;
    numeroCronop					 integer:=null;
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
      raise exception ' Nessun  programma da creare.';
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
 		   rattr.boolean,
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
	     cronop.usato_per_fpv,
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
 if tipoApertura=G_FASE then -- tutto da rivedere
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
      and   stato.programma_stato_code='VA'
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
      and   stato.programma_stato_code='VA'
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
     and    stato.cronop_stato_code='VA'
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
     and    pstato.programma_stato_code='VA'
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
     and    stato.cronop_stato_code='VA'
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
     and    pstato.programma_stato_code='VA'
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
     and    stato.cronop_stato_code='VA'
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
     and    pstato.programma_stato_code='VA'
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
     and    stato.cronop_stato_code='VA'
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
     and    pstato.programma_stato_code='VA'
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


 if codiceRisultato=0 then
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
COST 100;       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       t s . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) , 
 
         m o v _ p l u r i _ a n n o _ p r e c   a s 
 
         ( 
 
         s e l e c t   m o v . m o v g e s t _ a n n o : : i n t e g e r , m o v . m o v g e s t _ n u m e r o : : I N T E G E R , 
 
                       ( c a s e   w h e n   t i p o . m o v g e s t _ t s _ t i p o _ c o d e = ' T '   t h e n   0   e l s e   t s . m o v g e s t _ t s _ c o d e : : i n t e g e r   e n d )   m o v g e s t _ s u b n u m e r o , 
 
                       m o v . m o v g e s t _ t i p o _ i d ,   r . p r o g r a m m a _ i d 
 
         f r o m   s i a c _ t _ m o v g e s t   m o v , s i a c _ t _ m o v g e s t _ t s   t s , s i a c _ r _ m o v g e s t _ t s _ s t a t o   r s , s i a c _ d _ m o v g e s t _ s t a t o   s t a t o , 
 
                   s i a c _ d _ m o v g e s t _ T s _ t i p o   t i p o , s i a c _ r _ m o v g e s t _ t s _ p r o g r a m m a   r 
 
         w h e r e   m o v . b i l _ i d = b i l a n c i o P r e c I d 
 
         a n d       m o v . m o v g e s t _ a n n o : : i n t e g e r > = a n n o B i l a n c i o 
 
         a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
         a n d       r . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
         a n d       r s . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
         a n d       s t a t o . m o v g e s t _ s t a t o _ i d = r s . m o v g e s t _ s t a t o _ i d 
 
         a n d       s t a t o . m o v g e s t _ s t a t o _ c o d e ! = ' A ' 
 
         a n d       t i p o . m o v g e s t _ t s _ t i p o _ i d = t s . m o v g e s t _ t s _ t i p o _ i d 
 
         a n d       m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       m o v . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       t s . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) , 
 
         p r o g r   a s 
 
         ( 
 
             s e l e c t   p . p r o g r a m m a _ i d ,   p . p r o g r a m m a _ t i p o _ i d ,   p . p r o g r a m m a _ c o d e ,   p . b i l _ i d 
 
             f r o m   s i a c _ t _ p r o g r a m m a   p ,   s i a c _ r _ p r o g r a m m a _ s t a t o   r s , s i a c _ d _ p r o g r a m m a _ s t a t o   s t a t o ,   s i a c _ d _ p r o g r a m m a _ t i p o   t i p o 
 
             w h e r e   s t a t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
             a n d       s t a t o . p r o g r a m m a _ s t a t o _ c o d e = ' V A ' 
 
             a n d       r s . p r o g r a m m a _ s t a t o _ i d = s t a t o . p r o g r a m m a _ s t a t o _ i d 
 
             a n d       p . p r o g r a m m a _ i d = r s . p r o g r a m m a _ i d 
 
             a n d       t i p o . p r o g r a m m a _ t i p o _ i d = p . p r o g r a m m a _ t i p o _ i d 
 
             a n d       t i p o . p r o g r a m m a _ t i p o _ c o d e = G _ F A S E 
 
             a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       p . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) 
 
         s e l e c t   m o v _ p l u r i _ a n n o . m o v g e s t _ t s _ i d , 
 
                       p r o g r _ a n n o . p r o g r a m m a _ i d   p r o g r a m m a _ n e w _ i d 
 
         f r o m   m o v _ p l u r i _ a n n o , 
 
                   m o v _ p l u r i _ a n n o _ p r e c ,   p r o g r   p r o g r _ a n n o _ p r e c , 
 
                   p r o g r   p r o g r _ a n n o 
 
         w h e r e   m o v _ p l u r i _ a n n o . m o v g e s t _ a n n o = m o v _ p l u r i _ a n n o _ p r e c . m o v g e s t _ a n n o 
 
         a n d       m o v _ p l u r i _ a n n o . m o v g e s t _ n u m e r o = m o v _ p l u r i _ a n n o _ p r e c . m o v g e s t _ n u m e r o 
 
         a n d       m o v _ p l u r i _ a n n o . m o v g e s t _ s u b n u m e r o = m o v _ p l u r i _ a n n o _ p r e c . m o v g e s t _ s u b n u m e r o 
 
         a n d       m o v _ p l u r i _ a n n o . m o v g e s t _ t i p o _ i d = m o v _ p l u r i _ a n n o _ p r e c . m o v g e s t _ t i p o _ i d 
 
         a n d       p r o g r _ a n n o _ p r e c . p r o g r a m m a _ i d = m o v _ p l u r i _ a n n o _ p r e c . p r o g r a m m a _ i d 
 
         a n d       p r o g r _ a n n o . b i l _ i d = b i l a n c i o I d 
 
         a n d       p r o g r _ a n n o . p r o g r a m m a _ c o d e = p r o g r _ a n n o _ p r e c . p r o g r a m m a _ c o d e 
 
         )   q u e r y 
 
     ) ; 
 
     G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
     r a i s e   n o t i c e   ' %   s i a c _ r _ m o v g e s t _ t s _ p r o g r a m m a   r e s . i n s e r i m e n t i   = % ' ,   s t r M e s s a g g i o , c o d R e s u l t ; 
 
     s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   I n s e r i t e   n u m . = % ' | | c o a l e s c e ( c o d R e s u l t , 0 ) | | '   r i g h e . ' ; 
 
     c o d R e s u l t : = n u l l ; 
 
     i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
     ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
       v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
     ) 
 
     v a l u e s 
 
     ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | ' - ' | | s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
     r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
     i f   c o d R e s u l t   i s   n u l l   t h e n 
 
           r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
     e n d   i f ; 
 
 
 
 
 
     c o d R e s u l t : = n u l l ; 
 
     s t r M e s s a g g i o : = ' R i b a l t a m e n t o   l e g a m e   t r a   i m p e g n i   e   p r o g r a m m i - c r o n o p   -   i n s e r i m e n t o   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m     r e s i d u i . ' ; 
 
     - -   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m 
 
     i n s e r t   i n t o   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m 
 
     ( 
 
     	 m o v g e s t _ t s _ i d , 
 
         c r o n o p _ i d , 
 
         v a l i d i t a _ i n i z i o , 
 
         l o g i n _ o p e r a z i o n e , 
 
         e n t e _ p r o p r i e t a r i o _ i d 
 
     ) 
 
     ( 
 
     s e l e c t   q u e r y . m o v g e s t _ t s _ i d , 
 
                   q u e r y . c r o n o p _ n e w _ i d , 
 
                   c l o c k _ t i m e s t a m p ( ) , 
 
                   l o g i n O p e r a z i o n e , 
 
                   e n t e P r o p r i e t a r i o I d 
 
     f r o m 
 
     ( 
 
         w i t h 
 
         m o v _ r e s _ a n n o   a s 
 
         ( 
 
             s e l e c t   m o v . m o v g e s t _ a n n o : : i n t e g e r , m o v . m o v g e s t _ n u m e r o : : I N T E G E R , 
 
                           ( c a s e   w h e n   t i p o . m o v g e s t _ t s _ t i p o _ c o d e = ' T '   t h e n   0   e l s e   t s . m o v g e s t _ t s _ c o d e : : i n t e g e r   e n d   )   m o v g e s t _ s u b n u m e r o , 
 
                           m o v . m o v g e s t _ t i p o _ i d , 
 
                           t s . m o v g e s t _ t s _ i d 
 
             f r o m   s i a c _ t _ m o v g e s t   m o v , s i a c _ d _ m o v g e s t _ t i p o   t i p o m o v , 
 
                       s i a c _ t _ m o v g e s t _ t s   t s , s i a c _ r _ m o v g e s t _ t s _ s t a t o   r s , s i a c _ d _ m o v g e s t _ s t a t o   s t a t o , 
 
                       s i a c _ d _ m o v g e s t _ T s _ t i p o   t i p o 
 
             w h e r e   m o v . b i l _ i d = b i l a n c i o I d 
 
             a n d       t i p o m o v . m o v g e s t _ t i p o _ i d = m o v . m o v g e s t _ t i p o _ i d 
 
             a n d       t i p o m o v . m o v g e s t _ t i p o _ c o d e = ' I ' 
 
             a n d       m o v . m o v g e s t _ a n n o : : i n t e g e r < a n n o B i l a n c i o 
 
             a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
             a n d       r s . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
             a n d       s t a t o . m o v g e s t _ s t a t o _ i d = r s . m o v g e s t _ s t a t o _ i d 
 
             a n d       s t a t o . m o v g e s t _ s t a t o _ c o d e   i n   ( ' D ' , ' N ' ) 
 
             a n d       t i p o . m o v g e s t _ t s _ t i p o _ i d = t s . m o v g e s t _ t s _ t i p o _ i d 
 
             a n d       m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       m o v . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       t s . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) , 
 
         m o v _ r e s _ a n n o _ p r e c   a s 
 
         ( 
 
             s e l e c t   m o v . m o v g e s t _ a n n o : : i n t e g e r , m o v . m o v g e s t _ n u m e r o : : I N T E G E R , 
 
                           ( c a s e   w h e n   t i p o . m o v g e s t _ t s _ t i p o _ c o d e = ' T '   t h e n   0   e l s e   t s . m o v g e s t _ t s _ c o d e : : i n t e g e r   e n d )     m o v g e s t _ s u b n u m e r o , 
 
                           m o v . m o v g e s t _ t i p o _ i d ,   r . c r o n o p _ i d 
 
             f r o m   s i a c _ t _ m o v g e s t   m o v , s i a c _ d _ m o v g e s t _ t i p o   t i p o m o v , 
 
                       s i a c _ t _ m o v g e s t _ t s   t s , s i a c _ r _ m o v g e s t _ t s _ s t a t o   r s , s i a c _ d _ m o v g e s t _ s t a t o   s t a t o , 
 
                       s i a c _ d _ m o v g e s t _ T s _ t i p o   t i p o , s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m   r 
 
             w h e r e   m o v . b i l _ i d = b i l a n c i o P r e c I d 
 
             a n d       t i p o m o v . m o v g e s t _ t i p o _ i d = m o v . m o v g e s t _ t i p o _ i d 
 
             a n d       t i p o m o v . m o v g e s t _ t i p o _ c o d e = ' I ' 
 
             a n d       m o v . m o v g e s t _ a n n o : : i n t e g e r < a n n o B i l a n c i o 
 
             a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
             a n d       r . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
             a n d       r . c r o n o p _ e l e m _ i d   i s   n u l l 
 
             a n d       r s . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
             a n d       s t a t o . m o v g e s t _ s t a t o _ i d = r s . m o v g e s t _ s t a t o _ i d 
 
             a n d       s t a t o . m o v g e s t _ s t a t o _ c o d e   i n   ( ' D ' , ' N ' ) 
 
             a n d       t i p o . m o v g e s t _ t s _ t i p o _ i d = t s . m o v g e s t _ t s _ t i p o _ i d 
 
             a n d       m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       m o v . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       t s . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) , 
 
         c r o n o p   a s 
 
         ( 
 
           s e l e c t     c r o n o p . c r o n o p _ i d ,   c r o n o p . b i l _ i d , 
 
                           c r o n o p . c r o n o p _ c o d e , 
 
                           p r o g . p r o g r a m m a _ i d ,   p r o g . p r o g r a m m a _ c o d e 
 
           f r o m   s i a c _ t _ c r o n o p   c r o n o p , s i a c _ r _ c r o n o p _ s t a t o   r s , s i a c _ d _ c r o n o p _ s t a t o   s t a t o , 
 
                     s i a c _ t _ p r o g r a m m a   p r o g , s i a c _ r _ p r o g r a m m a _ s t a t o   r s p , s i a c _ d _ p r o g r a m m a _ s t a t o   p s t a t o ,   s i a c _ d _ p r o g r a m m a _ t i p o   t i p o 
 
       	   w h e r e     t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
           a n d         t i p o . p r o g r a m m a _ t i p o _ c o d e = G _ F A S E 
 
           a n d         p r o g . p r o g r a m m a _ t i p o _ i d = t i p o . p r o g r a m m a _ t i p o _ i d 
 
           a n d         c r o n o p . p r o g r a m m a _ i d = p r o g . p r o g r a m m a _ i d 
 
           a n d         r s . c r o n o p _ i d = c r o n o p . c r o n o p _ i d 
 
           a n d         s t a t o . c r o n o p _ s t a t o _ i d = r s . c r o n o p _ s t a t o _ i d 
 
           a n d         s t a t o . c r o n o p _ s t a t o _ c o d e = ' V A ' 
 
           a n d         r s p . p r o g r a m m a _ i d = p r o g . p r o g r a m m a _ i d 
 
           a n d         p s t a t o . p r o g r a m m a _ s t a t o _ i d = r s p . p r o g r a m m a _ s t a t o _ i d 
 
           a n d         p s t a t o . p r o g r a m m a _ s t a t o _ c o d e = ' V A ' 
 
           a n d         r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d         r s . v a l i d i t a _ f i n e   i s   n u l l 
 
           a n d         r s p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d         r s p . v a l i d i t a _ f i n e   i s   n u l l 
 
           a n d         p r o g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d         p r o g . v a l i d i t a _ f i n e   i s   n u l l 
 
           a n d         c r o n o p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d         c r o n o p . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) 
 
         s e l e c t   c r o n o p _ a n n o . c r o n o p _ i d   c r o n o p _ n e w _ i d , 
 
                       m o v _ r e s _ a n n o . m o v g e s t _ t s _ i d 
 
         f r o m   m o v _ r e s _ a n n o ,   m o v _ r e s _ a n n o _ p r e c ,   c r o n o p   c r o n o p _ a n n o ,   c r o n o p   c r o n o p _ a n n o _ p r e c 
 
         w h e r e   m o v _ r e s _ a n n o . m o v g e s t _ a n n o = m o v _ r e s _ a n n o _ p r e c . m o v g e s t _ a n n o 
 
         a n d       m o v _ r e s _ a n n o . m o v g e s t _ n u m e r o = m o v _ r e s _ a n n o _ p r e c . m o v g e s t _ n u m e r o 
 
         a n d       m o v _ r e s _ a n n o . m o v g e s t _ s u b n u m e r o = m o v _ r e s _ a n n o _ p r e c . m o v g e s t _ s u b n u m e r o 
 
         a n d       c r o n o p _ a n n o _ p r e c . c r o n o p _ i d = m o v _ r e s _ a n n o _ p r e c . c r o n o p _ i d 
 
         a n d       c r o n o p _ a n n o . b i l _ i d = b i l a n c i o I d 
 
         a n d       c r o n o p _ a n n o . p r o g r a m m a _ c o d e = c r o n o p _ a n n o _ p r e c . p r o g r a m m a _ c o d e 
 
         a n d       c r o n o p _ a n n o . c r o n o p _ c o d e = c r o n o p _ a n n o _ p r e c . c r o n o p _ c o d e 
 
       )   q u e r y 
 
     ) ; 
 
     G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
     r a i s e   n o t i c e   ' %   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m   r e s . i n s e r i m e n t i   = % ' ,   s t r M e s s a g g i o , c o d R e s u l t ; 
 
 
 
     s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   I n s e r i t e   n u m . = % ' | | c o a l e s c e ( c o d R e s u l t , 0 ) | | '   r i g h e . ' ; 
 
     c o d R e s u l t : = n u l l ; 
 
     i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
     ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
       v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
     ) 
 
     v a l u e s 
 
     ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | ' - ' | | s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
     r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
     i f   c o d R e s u l t   i s   n u l l   t h e n 
 
           r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
     e n d   i f ; 
 
 
 
 
 
     c o d R e s u l t : = n u l l ; 
 
     s t r M e s s a g g i o : = ' R i b a l t a m e n t o   l e g a m e   t r a   i m p e g n i   e   p r o g r a m m i - c r o n o p   -   i n s e r i m e n t o   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m     p l u r i e n n a l i . ' ; 
 
     - -   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m 
 
     i n s e r t   i n t o   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m 
 
     ( 
 
     	 m o v g e s t _ t s _ i d , 
 
         c r o n o p _ i d , 
 
         v a l i d i t a _ i n i z i o , 
 
         l o g i n _ o p e r a z i o n e , 
 
         e n t e _ p r o p r i e t a r i o _ i d 
 
     ) 
 
     ( 
 
     s e l e c t   q u e r y . m o v g e s t _ t s _ i d , 
 
                   q u e r y . c r o n o p _ n e w _ i d , 
 
                   c l o c k _ t i m e s t a m p ( ) , 
 
                   l o g i n O p e r a z i o n e , 
 
                   e n t e P r o p r i e t a r i o I d 
 
     f r o m 
 
     ( 
 
         w i t h 
 
         m o v _ r e s _ a n n o   a s 
 
         ( 
 
             s e l e c t   m o v . m o v g e s t _ a n n o : : i n t e g e r , m o v . m o v g e s t _ n u m e r o : : I N T E G E R , 
 
                           ( c a s e   w h e n   t i p o . m o v g e s t _ t s _ t i p o _ c o d e = ' T '   t h e n   0   e l s e   t s . m o v g e s t _ t s _ c o d e : : i n t e g e r   e n d   )   m o v g e s t _ s u b n u m e r o , 
 
                           m o v . m o v g e s t _ t i p o _ i d , 
 
                           t s . m o v g e s t _ t s _ i d 
 
             f r o m   s i a c _ t _ m o v g e s t   m o v , s i a c _ d _ m o v g e s t _ t i p o   t i p o m o v , 
 
                       s i a c _ t _ m o v g e s t _ t s   t s , s i a c _ r _ m o v g e s t _ t s _ s t a t o   r s , s i a c _ d _ m o v g e s t _ s t a t o   s t a t o , 
 
                       s i a c _ d _ m o v g e s t _ T s _ t i p o   t i p o 
 
             w h e r e   m o v . b i l _ i d = b i l a n c i o I d 
 
             a n d       t i p o m o v . m o v g e s t _ t i p o _ i d = m o v . m o v g e s t _ t i p o _ i d 
 
             a n d       t i p o m o v . m o v g e s t _ t i p o _ c o d e = ' I ' 
 
             a n d       m o v . m o v g e s t _ a n n o : : i n t e g e r > = a n n o B i l a n c i o 
 
             a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
             a n d       r s . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
             a n d       s t a t o . m o v g e s t _ s t a t o _ i d = r s . m o v g e s t _ s t a t o _ i d 
 
             a n d       s t a t o . m o v g e s t _ s t a t o _ c o d e ! = ' A ' 
 
             a n d       t i p o . m o v g e s t _ t s _ t i p o _ i d = t s . m o v g e s t _ t s _ t i p o _ i d 
 
             a n d       m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       m o v . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       t s . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) , 
 
         m o v _ r e s _ a n n o _ p r e c   a s 
 
         ( 
 
             s e l e c t   m o v . m o v g e s t _ a n n o : : i n t e g e r , m o v . m o v g e s t _ n u m e r o : : I N T E G E R , 
 
                           ( c a s e   w h e n   t i p o . m o v g e s t _ t s _ t i p o _ c o d e = ' T '   t h e n   0   e l s e   t s . m o v g e s t _ t s _ c o d e : : i n t e g e r   e n d )     m o v g e s t _ s u b n u m e r o , 
 
                           m o v . m o v g e s t _ t i p o _ i d ,   r . c r o n o p _ i d 
 
             f r o m   s i a c _ t _ m o v g e s t   m o v , s i a c _ d _ m o v g e s t _ t i p o   t i p o m o v , 
 
                       s i a c _ t _ m o v g e s t _ t s   t s , s i a c _ r _ m o v g e s t _ t s _ s t a t o   r s , s i a c _ d _ m o v g e s t _ s t a t o   s t a t o , 
 
                       s i a c _ d _ m o v g e s t _ T s _ t i p o   t i p o , s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m   r 
 
             w h e r e   m o v . b i l _ i d = b i l a n c i o P r e c I d 
 
             a n d       t i p o m o v . m o v g e s t _ t i p o _ i d = m o v . m o v g e s t _ t i p o _ i d 
 
             a n d       t i p o m o v . m o v g e s t _ t i p o _ c o d e = ' I ' 
 
             a n d       m o v . m o v g e s t _ a n n o : : i n t e g e r > = a n n o B i l a n c i o 
 
             a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
             a n d       r . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
             a n d       r . c r o n o p _ e l e m _ i d   i s   n u l l 
 
             a n d       r s . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
             a n d       s t a t o . m o v g e s t _ s t a t o _ i d = r s . m o v g e s t _ s t a t o _ i d 
 
             a n d       s t a t o . m o v g e s t _ s t a t o _ c o d e   ! = ' A ' 
 
             a n d       t i p o . m o v g e s t _ t s _ t i p o _ i d = t s . m o v g e s t _ t s _ t i p o _ i d 
 
             a n d       m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       m o v . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       t s . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) , 
 
         c r o n o p   a s 
 
         ( 
 
           s e l e c t     c r o n o p . c r o n o p _ i d ,   c r o n o p . b i l _ i d , 
 
                           c r o n o p . c r o n o p _ c o d e , 
 
                           p r o g . p r o g r a m m a _ i d ,   p r o g . p r o g r a m m a _ c o d e 
 
           f r o m   s i a c _ t _ c r o n o p   c r o n o p , s i a c _ r _ c r o n o p _ s t a t o   r s , s i a c _ d _ c r o n o p _ s t a t o   s t a t o , 
 
                     s i a c _ t _ p r o g r a m m a   p r o g , s i a c _ r _ p r o g r a m m a _ s t a t o   r s p , s i a c _ d _ p r o g r a m m a _ s t a t o   p s t a t o ,   s i a c _ d _ p r o g r a m m a _ t i p o   t i p o 
 
       	   w h e r e     t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
           a n d         t i p o . p r o g r a m m a _ t i p o _ c o d e = G _ F A S E 
 
           a n d         p r o g . p r o g r a m m a _ t i p o _ i d = t i p o . p r o g r a m m a _ t i p o _ i d 
 
           a n d         c r o n o p . p r o g r a m m a _ i d = p r o g . p r o g r a m m a _ i d 
 
           a n d         r s . c r o n o p _ i d = c r o n o p . c r o n o p _ i d 
 
           a n d         s t a t o . c r o n o p _ s t a t o _ i d = r s . c r o n o p _ s t a t o _ i d 
 
           a n d         s t a t o . c r o n o p _ s t a t o _ c o d e = ' V A ' 
 
           a n d         r s p . p r o g r a m m a _ i d = p r o g . p r o g r a m m a _ i d 
 
           a n d         p s t a t o . p r o g r a m m a _ s t a t o _ i d = r s p . p r o g r a m m a _ s t a t o _ i d 
 
           a n d         p s t a t o . p r o g r a m m a _ s t a t o _ c o d e = ' V A ' 
 
           a n d         r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d         r s . v a l i d i t a _ f i n e   i s   n u l l 
 
           a n d         r s p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d         r s p . v a l i d i t a _ f i n e   i s   n u l l 
 
           a n d         p r o g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d         p r o g . v a l i d i t a _ f i n e   i s   n u l l 
 
           a n d         c r o n o p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d         c r o n o p . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) 
 
         s e l e c t   c r o n o p _ a n n o . c r o n o p _ i d   c r o n o p _ n e w _ i d , 
 
                       m o v _ r e s _ a n n o . m o v g e s t _ t s _ i d 
 
         f r o m   m o v _ r e s _ a n n o ,   m o v _ r e s _ a n n o _ p r e c ,   c r o n o p   c r o n o p _ a n n o _ p r e c ,   c r o n o p   c r o n o p _ a n n o 
 
         w h e r e   m o v _ r e s _ a n n o . m o v g e s t _ a n n o = m o v _ r e s _ a n n o _ p r e c . m o v g e s t _ a n n o 
 
         a n d       m o v _ r e s _ a n n o . m o v g e s t _ n u m e r o = m o v _ r e s _ a n n o _ p r e c . m o v g e s t _ n u m e r o 
 
         a n d       m o v _ r e s _ a n n o . m o v g e s t _ s u b n u m e r o = m o v _ r e s _ a n n o _ p r e c . m o v g e s t _ s u b n u m e r o 
 
         a n d       c r o n o p _ a n n o _ p r e c . c r o n o p _ i d = m o v _ r e s _ a n n o _ p r e c . c r o n o p _ i d 
 
         a n d       c r o n o p _ a n n o . b i l _ i d = b i l a n c i o I d 
 
         a n d       c r o n o p _ a n n o . p r o g r a m m a _ c o d e = c r o n o p _ a n n o _ p r e c . p r o g r a m m a _ c o d e 
 
         a n d       c r o n o p _ a n n o . c r o n o p _ c o d e = c r o n o p _ a n n o _ p r e c . c r o n o p _ c o d e 
 
       )   q u e r y 
 
     ) ; 
 
     G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
     r a i s e   n o t i c e   ' %   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m   r e s . i n s e r i m e n t i   = % ' ,   s t r M e s s a g g i o , c o d R e s u l t ; 
 
 
 
     s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   I n s e r i t e   n u m . = % ' | | c o a l e s c e ( c o d R e s u l t , 0 ) | | '   r i g h e . ' ; 
 
     c o d R e s u l t : = n u l l ; 
 
     i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
     ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
       v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
     ) 
 
     v a l u e s 
 
     ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | ' - ' | | s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
     r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
     i f   c o d R e s u l t   i s   n u l l   t h e n 
 
           r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
     e n d   i f ; 
 
 
 
 
 
     c o d R e s u l t : = n u l l ; 
 
     s t r M e s s a g g i o : = ' R i b a l t a m e n t o   l e g a m e   t r a   i m p e g n i   e   p r o g r a m m i - c r o n o p   d e t t a g l i o   -   i n s e r i m e n t o   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m     r e s i d u i . ' ; 
 
     - -   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m 
 
     i n s e r t   i n t o   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m 
 
     ( 
 
     	 m o v g e s t _ t s _ i d , 
 
         c r o n o p _ i d , 
 
         c r o n o p _ e l e m _ i d , 
 
         v a l i d i t a _ i n i z i o , 
 
         l o g i n _ o p e r a z i o n e , 
 
         e n t e _ p r o p r i e t a r i o _ i d 
 
     ) 
 
     ( 
 
     s e l e c t   q u e r y . m o v g e s t _ t s _ i d , 
 
     	           q u e r y . c r o n o p _ n e w _ i d , 
 
                   q u e r y . c r o n o p _ e l e m _ n e w _ i d , 
 
                   c l o c k _ t i m e s t a m p ( ) , 
 
                   l o g i n O p e r a z i o n e , 
 
                   e n t e P r o p r i e t a r i o I d 
 
     f r o m 
 
     ( 
 
         w i t h 
 
         m o v _ r e s _ a n n o   a s 
 
         ( 
 
             s e l e c t   m o v . m o v g e s t _ a n n o : : i n t e g e r , m o v . m o v g e s t _ n u m e r o : : I N T E G E R , 
 
                           ( c a s e   w h e n   t i p o . m o v g e s t _ t s _ t i p o _ c o d e = ' T '   t h e n   0   e l s e   t s . m o v g e s t _ t s _ c o d e : : i n t e g e r   e n d   )   m o v g e s t _ s u b n u m e r o , 
 
                           m o v . m o v g e s t _ t i p o _ i d , 
 
                           t s . m o v g e s t _ t s _ i d 
 
             f r o m   s i a c _ t _ m o v g e s t   m o v , s i a c _ d _ m o v g e s t _ t i p o   t i p o m o v , 
 
                       s i a c _ t _ m o v g e s t _ t s   t s , s i a c _ r _ m o v g e s t _ t s _ s t a t o   r s , s i a c _ d _ m o v g e s t _ s t a t o   s t a t o , 
 
                       s i a c _ d _ m o v g e s t _ T s _ t i p o   t i p o 
 
             w h e r e   m o v . b i l _ i d = b i l a n c i o I d 
 
             a n d       t i p o m o v . m o v g e s t _ t i p o _ i d = m o v . m o v g e s t _ t i p o _ i d 
 
             a n d       t i p o m o v . m o v g e s t _ t i p o _ c o d e = ' I ' 
 
             a n d       m o v . m o v g e s t _ a n n o : : i n t e g e r < a n n o B i l a n c i o 
 
             a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
             a n d       r s . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
             a n d       s t a t o . m o v g e s t _ s t a t o _ i d = r s . m o v g e s t _ s t a t o _ i d 
 
             a n d       s t a t o . m o v g e s t _ s t a t o _ c o d e   i n   ( ' D ' , ' N ' ) 
 
             a n d       t i p o . m o v g e s t _ t s _ t i p o _ i d = t s . m o v g e s t _ t s _ t i p o _ i d 
 
             a n d       m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       m o v . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       t s . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) , 
 
         m o v _ r e s _ a n n o _ p r e c   a s 
 
         ( 
 
             s e l e c t   m o v . m o v g e s t _ a n n o : : i n t e g e r , m o v . m o v g e s t _ n u m e r o : : I N T E G E R , 
 
                           ( c a s e   w h e n   t i p o . m o v g e s t _ t s _ t i p o _ c o d e = ' T '   t h e n   0   e l s e   t s . m o v g e s t _ t s _ c o d e : : i n t e g e r   e n d )     m o v g e s t _ s u b n u m e r o , 
 
                           m o v . m o v g e s t _ t i p o _ i d ,   r . c r o n o p _ e l e m _ i d 
 
             f r o m   s i a c _ t _ m o v g e s t   m o v , s i a c _ d _ m o v g e s t _ t i p o   t i p o m o v , 
 
                       s i a c _ t _ m o v g e s t _ t s   t s , s i a c _ r _ m o v g e s t _ t s _ s t a t o   r s , s i a c _ d _ m o v g e s t _ s t a t o   s t a t o , 
 
                       s i a c _ d _ m o v g e s t _ T s _ t i p o   t i p o , s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m   r 
 
             w h e r e   m o v . b i l _ i d = b i l a n c i o P r e c I d 
 
             a n d       t i p o m o v . m o v g e s t _ t i p o _ i d = m o v . m o v g e s t _ t i p o _ i d 
 
             a n d       t i p o m o v . m o v g e s t _ t i p o _ c o d e = ' I ' 
 
             a n d       m o v . m o v g e s t _ a n n o : : i n t e g e r < a n n o B i l a n c i o 
 
             a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
             a n d       r . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
             a n d       r . c r o n o p _ e l e m _ i d   i s   n o t   n u l l 
 
             a n d       r s . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
             a n d       s t a t o . m o v g e s t _ s t a t o _ i d = r s . m o v g e s t _ s t a t o _ i d 
 
             a n d       s t a t o . m o v g e s t _ s t a t o _ c o d e   i n   ( ' D ' , ' N ' ) 
 
             a n d       t i p o . m o v g e s t _ t s _ t i p o _ i d = t s . m o v g e s t _ t s _ t i p o _ i d 
 
             a n d       m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       m o v . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       t s . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) , 
 
         c r o n o p _ e l e m   a s 
 
         ( 
 
           s e l e c t     c r o n o p . c r o n o p _ i d ,   c r o n o p . b i l _ i d , 
 
                           c r o n o p . c r o n o p _ c o d e , 
 
                           p r o g . p r o g r a m m a _ i d ,   p r o g . p r o g r a m m a _ c o d e , 
 
                           c e l e m . c r o n o p _ e l e m _ i d , 
 
                           c o a l e s c e ( c e l e m . c r o n o p _ e l e m _ c o d e , ' ' )     c r o n o p _ e l e m _ c o d e , 
 
                           c o a l e s c e ( c e l e m . c r o n o p _ e l e m _ c o d e 2 , ' ' )   c r o n o p _ e l e m _ c o d e 2 , 
 
                           c o a l e s c e ( c e l e m . c r o n o p _ e l e m _ c o d e 3 , ' ' )   c r o n o p _ e l e m _ c o d e 3 , 
 
                           c o a l e s c e ( c e l e m . e l e m _ t i p o _ i d , 0 )               e l e m _ t i p o _ i d , 
 
                           c o a l e s c e ( c e l e m . c r o n o p _ e l e m _ d e s c , ' ' )     c r o n o p _ e l e m _ d e s c , 
 
                           c o a l e s c e ( c e l e m . c r o n o p _ e l e m _ d e s c 2 , ' ' )   c r o n o p _ e l e m _ d e s c 2 , 
 
                           c o a l e s c e ( d e t . p e r i o d o _ i d , 0 )                       p e r i o d o _ i d , 
 
                           c o a l e s c e ( d e t . c r o n o p _ e l e m _ d e t _ i m p o r t o , 0 )   c r o n o p _ e l e m _ d e t _ i m p o r t o , 
 
                           c o a l e s c e ( d e t . c r o n o p _ e l e m _ d e t _ d e s c , ' ' )   c r o n o p _ e l e m _ d e t _ d e s c , 
 
                           c o a l e s c e ( d e t . a n n o _ e n t r a t a , ' ' )                 a n n o _ e n t r a t a , 
 
                           c o a l e s c e ( d e t . e l e m _ d e t _ t i p o _ i d , 0 )           e l e m _ d e t _ t i p o _ i d 
 
           f r o m   s i a c _ t _ c r o n o p   c r o n o p , s i a c _ r _ c r o n o p _ s t a t o   r s , s i a c _ d _ c r o n o p _ s t a t o   s t a t o , 
 
                     s i a c _ t _ p r o g r a m m a   p r o g , s i a c _ r _ p r o g r a m m a _ s t a t o   r s p , s i a c _ d _ p r o g r a m m a _ s t a t o   p s t a t o ,   s i a c _ d _ p r o g r a m m a _ t i p o   t i p o , 
 
                     s i a c _ t _ c r o n o p _ e l e m   c e l e m , s i a c _ t _ c r o n o p _ e l e m _ d e t   d e t 
 
       	   w h e r e     t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
           a n d         t i p o . p r o g r a m m a _ t i p o _ c o d e = G _ F A S E 
 
           a n d         p r o g . p r o g r a m m a _ t i p o _ i d = t i p o . p r o g r a m m a _ t i p o _ i d 
 
           a n d         c r o n o p . p r o g r a m m a _ i d = p r o g . p r o g r a m m a _ i d 
 
           a n d         c e l e m . c r o n o p _ i d = c r o n o p . c r o n o p _ i d 
 
           a n d         d e t . c r o n o p _ e l e m _ i d = c e l e m . c r o n o p _ e l e m _ i d 
 
           a n d         r s . c r o n o p _ i d = c r o n o p . c r o n o p _ i d 
 
           a n d         s t a t o . c r o n o p _ s t a t o _ i d = r s . c r o n o p _ s t a t o _ i d 
 
           a n d         s t a t o . c r o n o p _ s t a t o _ c o d e = ' V A ' 
 
           a n d         r s p . p r o g r a m m a _ i d = p r o g . p r o g r a m m a _ i d 
 
           a n d         p s t a t o . p r o g r a m m a _ s t a t o _ i d = r s p . p r o g r a m m a _ s t a t o _ i d 
 
           a n d         p s t a t o . p r o g r a m m a _ s t a t o _ c o d e = ' V A ' 
 
           a n d         r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d         r s . v a l i d i t a _ f i n e   i s   n u l l 
 
           a n d         r s p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d         r s p . v a l i d i t a _ f i n e   i s   n u l l 
 
           a n d         p r o g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d         p r o g . v a l i d i t a _ f i n e   i s   n u l l 
 
           a n d         c r o n o p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d         c r o n o p . v a l i d i t a _ f i n e   i s   n u l l 
 
           a n d         c e l e m . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d         c e l e m . v a l i d i t a _ f i n e   i s   n u l l 
 
           a n d         d e t . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d         d e t . v a l i d i t a _ f i n e   i s   n u l l 
 
 
 
         ) 
 
         s e l e c t   c r o n o p _ e l e m _ a n n o . c r o n o p _ e l e m _ i d   c r o n o p _ e l e m _ n e w _ i d , 
 
                       c r o n o p _ e l e m _ a n n o . c r o n o p _ i d   c r o n o p _ n e w _ i d , 
 
                       m o v _ r e s _ a n n o . m o v g e s t _ t s _ i d 
 
         f r o m   m o v _ r e s _ a n n o ,   m o v _ r e s _ a n n o _ p r e c ,   c r o n o p _ e l e m   c r o n o p _ e l e m _ a n n o _ p r e c ,   c r o n o p _ e l e m   c r o n o p _ e l e m _ a n n o 
 
         w h e r e   m o v _ r e s _ a n n o . m o v g e s t _ a n n o = m o v _ r e s _ a n n o _ p r e c . m o v g e s t _ a n n o 
 
         a n d       m o v _ r e s _ a n n o . m o v g e s t _ n u m e r o = m o v _ r e s _ a n n o _ p r e c . m o v g e s t _ n u m e r o 
 
         a n d       m o v _ r e s _ a n n o . m o v g e s t _ s u b n u m e r o = m o v _ r e s _ a n n o _ p r e c . m o v g e s t _ s u b n u m e r o 
 
         a n d       c r o n o p _ e l e m _ a n n o _ p r e c . c r o n o p _ e l e m _ i d = m o v _ r e s _ a n n o _ p r e c . c r o n o p _ e l e m _ i d 
 
         a n d       c r o n o p _ e l e m _ a n n o . b i l _ i d = b i l a n c i o I d 
 
         a n d       c r o n o p _ e l e m _ a n n o . p r o g r a m m a _ c o d e = c r o n o p _ e l e m _ a n n o _ p r e c . p r o g r a m m a _ c o d e 
 
         a n d       c r o n o p _ e l e m _ a n n o . c r o n o p _ c o d e = c r o n o p _ e l e m _ a n n o _ p r e c . c r o n o p _ c o d e 
 
         a n d       c r o n o p _ e l e m _ a n n o . c r o n o p _ e l e m _ c o d e = c r o n o p _ e l e m _ a n n o _ p r e c . c r o n o p _ e l e m _ c o d e 
 
         a n d       c r o n o p _ e l e m _ a n n o . c r o n o p _ e l e m _ c o d e 2 = c r o n o p _ e l e m _ a n n o _ p r e c . c r o n o p _ e l e m _ c o d e 2 
 
         a n d       c r o n o p _ e l e m _ a n n o . c r o n o p _ e l e m _ c o d e 3 = c r o n o p _ e l e m _ a n n o _ p r e c . c r o n o p _ e l e m _ c o d e 3 
 
         a n d       c r o n o p _ e l e m _ a n n o . e l e m _ t i p o _ i d = c r o n o p _ e l e m _ a n n o _ p r e c . e l e m _ t i p o _ i d 
 
         a n d       c r o n o p _ e l e m _ a n n o . c r o n o p _ e l e m _ d e s c = c r o n o p _ e l e m _ a n n o _ p r e c . c r o n o p _ e l e m _ d e s c 
 
         a n d       c r o n o p _ e l e m _ a n n o . c r o n o p _ e l e m _ d e s c 2 = c r o n o p _ e l e m _ a n n o _ p r e c . c r o n o p _ e l e m _ d e s c 2 
 
         a n d       c r o n o p _ e l e m _ a n n o . p e r i o d o _ i d = c r o n o p _ e l e m _ a n n o _ p r e c . p e r i o d o _ i d 
 
         a n d       c r o n o p _ e l e m _ a n n o . c r o n o p _ e l e m _ d e t _ i m p o r t o = c r o n o p _ e l e m _ a n n o _ p r e c . c r o n o p _ e l e m _ d e t _ i m p o r t o 
 
         a n d       c r o n o p _ e l e m _ a n n o . c r o n o p _ e l e m _ d e t _ d e s c = c r o n o p _ e l e m _ a n n o _ p r e c . c r o n o p _ e l e m _ d e t _ d e s c 
 
         a n d       c r o n o p _ e l e m _ a n n o . a n n o _ e n t r a t a = c r o n o p _ e l e m _ a n n o _ p r e c . a n n o _ e n t r a t a 
 
         a n d       c r o n o p _ e l e m _ a n n o . e l e m _ d e t _ t i p o _ i d = c r o n o p _ e l e m _ a n n o _ p r e c . e l e m _ d e t _ t i p o _ i d 
 
         a n d       e x i s t s 
 
         ( 
 
         	 s e l e c t   1 
 
                 f r o m   s i a c _ r _ c r o n o p _ e l e m _ c l a s s   r c , s i a c _ t _ c l a s s   c , s i a c _ d _ c l a s s _ t i p o   t i p o 
 
                 w h e r e   r c . c r o n o p _ e l e m _ i d = c r o n o p _ e l e m _ a n n o _ p r e c . c r o n o p _ e l e m _ i d 
 
                 a n d       c . c l a s s i f _ i d = r c . c l a s s i f _ i d 
 
                 a n d       t i p o . c l a s s i f _ t i p o _ i d = c . c l a s s i f _ t i p o _ i d 
 
                 a n d       e x i s t s 
 
                 ( 
 
                 	 s e l e c t   1 
 
                         f r o m   s i a c _ r _ c r o n o p _ e l e m _ c l a s s   r c 1 , s i a c _ t _ c l a s s   c 1 
 
                         w h e r e   r c 1 . c r o n o p _ e l e m _ i d = c r o n o p _ e l e m _ a n n o . c r o n o p _ e l e m _ i d 
 
                         a n d       c 1 . c l a s s i f _ i d = r c 1 . c l a s s i f _ i d 
 
                         a n d       c 1 . c l a s s i f _ t i p o _ i d = t i p o . c l a s s i f _ t i p o _ i d 
 
                         a n d       c 1 . c l a s s i f _ c o d e = c . c l a s s i f _ c o d e 
 
                         a n d       r c 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       r c 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
                 ) 
 
                 a n d       r c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       r c . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) 
 
         a n d   n o t   e x i s t s 
 
         ( 
 
         	 s e l e c t   1 
 
                 f r o m   s i a c _ r _ c r o n o p _ e l e m _ c l a s s   r c , s i a c _ t _ c l a s s   c , s i a c _ d _ c l a s s _ t i p o   t i p o 
 
                 w h e r e   r c . c r o n o p _ e l e m _ i d = c r o n o p _ e l e m _ a n n o _ p r e c . c r o n o p _ e l e m _ i d 
 
                 a n d       c . c l a s s i f _ i d = r c . c l a s s i f _ i d 
 
                 a n d       t i p o . c l a s s i f _ t i p o _ i d = c . c l a s s i f _ t i p o _ i d 
 
                 a n d       n o t   e x i s t s 
 
                 ( 
 
                 	 s e l e c t   1 
 
                         f r o m   s i a c _ r _ c r o n o p _ e l e m _ c l a s s   r c 1 , s i a c _ t _ c l a s s   c 1 
 
                         w h e r e   r c 1 . c r o n o p _ e l e m _ i d = c r o n o p _ e l e m _ a n n o . c r o n o p _ e l e m _ i d 
 
                         a n d       c 1 . c l a s s i f _ i d = r c 1 . c l a s s i f _ i d 
 
                         a n d       c 1 . c l a s s i f _ t i p o _ i d = t i p o . c l a s s i f _ t i p o _ i d 
 
                         a n d       c 1 . c l a s s i f _ c o d e = c . c l a s s i f _ c o d e 
 
                         a n d       r c 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       r c 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
                 ) 
 
                 a n d       r c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       r c . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) 
 
       )   q u e r y 
 
     ) ; 
 
     G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
     r a i s e   n o t i c e   ' %   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m   r e s . i n s e r i m e n t i   = % ' ,   s t r M e s s a g g i o , c o d R e s u l t ; 
 
 
 
     s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   I n s e r i t e   n u m . = % ' | | c o a l e s c e ( c o d R e s u l t , 0 ) | | '   r i g h e . ' ; 
 
     c o d R e s u l t : = n u l l ; 
 
     i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
     ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
       v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
     ) 
 
     v a l u e s 
 
     ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | ' - ' | | s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
     r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
     i f   c o d R e s u l t   i s   n u l l   t h e n 
 
           r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
     e n d   i f ; 
 
 
 
     c o d R e s u l t : = n u l l ; 
 
     s t r M e s s a g g i o : = ' R i b a l t a m e n t o   l e g a m e   t r a   i m p e g n i   e   p r o g r a m m i - c r o n o p   d e t t a g l i o   -   i n s e r i m e n t o   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m     p l u r i e n n a l i . ' ; 
 
     - -   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m 
 
     i n s e r t   i n t o   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m 
 
     ( 
 
     	 m o v g e s t _ t s _ i d , 
 
         c r o n o p _ i d , 
 
         c r o n o p _ e l e m _ i d , 
 
         v a l i d i t a _ i n i z i o , 
 
         l o g i n _ o p e r a z i o n e , 
 
         e n t e _ p r o p r i e t a r i o _ i d 
 
     ) 
 
     ( 
 
     s e l e c t   q u e r y . m o v g e s t _ t s _ i d , 
 
     	           q u e r y . c r o n o p _ n e w _ i d , 
 
                   q u e r y . c r o n o p _ e l e m _ n e w _ i d , 
 
                   c l o c k _ t i m e s t a m p ( ) , 
 
                   l o g i n O p e r a z i o n e , 
 
                   e n t e P r o p r i e t a r i o I d 
 
     f r o m 
 
     ( 
 
         w i t h 
 
         m o v _ r e s _ a n n o   a s 
 
         ( 
 
             s e l e c t   m o v . m o v g e s t _ a n n o : : i n t e g e r , m o v . m o v g e s t _ n u m e r o : : I N T E G E R , 
 
                           ( c a s e   w h e n   t i p o . m o v g e s t _ t s _ t i p o _ c o d e = ' T '   t h e n   0   e l s e   t s . m o v g e s t _ t s _ c o d e : : i n t e g e r   e n d   )   m o v g e s t _ s u b n u m e r o , 
 
                           m o v . m o v g e s t _ t i p o _ i d , 
 
                           t s . m o v g e s t _ t s _ i d 
 
             f r o m   s i a c _ t _ m o v g e s t   m o v , s i a c _ d _ m o v g e s t _ t i p o   t i p o m o v , 
 
                       s i a c _ t _ m o v g e s t _ t s   t s , s i a c _ r _ m o v g e s t _ t s _ s t a t o   r s , s i a c _ d _ m o v g e s t _ s t a t o   s t a t o , 
 
                       s i a c _ d _ m o v g e s t _ T s _ t i p o   t i p o 
 
             w h e r e   m o v . b i l _ i d = b i l a n c i o I d 
 
             a n d       t i p o m o v . m o v g e s t _ t i p o _ i d = m o v . m o v g e s t _ t i p o _ i d 
 
             a n d       t i p o m o v . m o v g e s t _ t i p o _ c o d e = ' I ' 
 
             a n d       m o v . m o v g e s t _ a n n o : : i n t e g e r > = a n n o B i l a n c i o 
 
             a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
             a n d       r s . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
             a n d       s t a t o . m o v g e s t _ s t a t o _ i d = r s . m o v g e s t _ s t a t o _ i d 
 
             a n d       s t a t o . m o v g e s t _ s t a t o _ c o d e ! = ' A ' 
 
             a n d       t i p o . m o v g e s t _ t s _ t i p o _ i d = t s . m o v g e s t _ t s _ t i p o _ i d 
 
             a n d       m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       m o v . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       t s . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) , 
 
         m o v _ r e s _ a n n o _ p r e c   a s 
 
         ( 
 
             s e l e c t   m o v . m o v g e s t _ a n n o : : i n t e g e r , m o v . m o v g e s t _ n u m e r o : : I N T E G E R , 
 
                           ( c a s e   w h e n   t i p o . m o v g e s t _ t s _ t i p o _ c o d e = ' T '   t h e n   0   e l s e   t s . m o v g e s t _ t s _ c o d e : : i n t e g e r   e n d )     m o v g e s t _ s u b n u m e r o , 
 
                           m o v . m o v g e s t _ t i p o _ i d ,   r . c r o n o p _ e l e m _ i d 
 
             f r o m   s i a c _ t _ m o v g e s t   m o v , s i a c _ d _ m o v g e s t _ t i p o   t i p o m o v , 
 
                       s i a c _ t _ m o v g e s t _ t s   t s , s i a c _ r _ m o v g e s t _ t s _ s t a t o   r s , s i a c _ d _ m o v g e s t _ s t a t o   s t a t o , 
 
                       s i a c _ d _ m o v g e s t _ T s _ t i p o   t i p o , s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m   r 
 
             w h e r e   m o v . b i l _ i d = b i l a n c i o P r e c I d 
 
             a n d       t i p o m o v . m o v g e s t _ t i p o _ i d = m o v . m o v g e s t _ t i p o _ i d 
 
             a n d       t i p o m o v . m o v g e s t _ t i p o _ c o d e = ' I ' 
 
             a n d       m o v . m o v g e s t _ a n n o : : i n t e g e r > = a n n o B i l a n c i o 
 
             a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
             a n d       r . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
             a n d       r . c r o n o p _ e l e m _ i d   i s   n o t   n u l l 
 
             a n d       r s . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
             a n d       s t a t o . m o v g e s t _ s t a t o _ i d = r s . m o v g e s t _ s t a t o _ i d 
 
             a n d       s t a t o . m o v g e s t _ s t a t o _ c o d e ! = ' A ' 
 
             a n d       t i p o . m o v g e s t _ t s _ t i p o _ i d = t s . m o v g e s t _ t s _ t i p o _ i d 
 
             a n d       m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       m o v . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       t s . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) , 
 
         c r o n o p _ e l e m   a s 
 
         ( 
 
           s e l e c t     c r o n o p . c r o n o p _ i d ,   c r o n o p . b i l _ i d , 
 
                           c r o n o p . c r o n o p _ c o d e , 
 
                           p r o g . p r o g r a m m a _ i d ,   p r o g . p r o g r a m m a _ c o d e , 
 
                           c e l e m . c r o n o p _ e l e m _ i d , 
 
                           c o a l e s c e ( c e l e m . c r o n o p _ e l e m _ c o d e , ' ' )     c r o n o p _ e l e m _ c o d e , 
 
                           c o a l e s c e ( c e l e m . c r o n o p _ e l e m _ c o d e 2 , ' ' )   c r o n o p _ e l e m _ c o d e 2 , 
 
                           c o a l e s c e ( c e l e m . c r o n o p _ e l e m _ c o d e 3 , ' ' )   c r o n o p _ e l e m _ c o d e 3 , 
 
                           c o a l e s c e ( c e l e m . e l e m _ t i p o _ i d , 0 )             e l e m _ t i p o _ i d , 
 
                           c o a l e s c e ( c e l e m . c r o n o p _ e l e m _ d e s c , ' ' )     c r o n o p _ e l e m _ d e s c , 
 
                           c o a l e s c e ( c e l e m . c r o n o p _ e l e m _ d e s c 2 , ' ' )     c r o n o p _ e l e m _ d e s c 2 , 
 
                           c o a l e s c e ( d e t . p e r i o d o _ i d , 0 )                       p e r i o d o _ i d , 
 
                           c o a l e s c e ( d e t . c r o n o p _ e l e m _ d e t _ i m p o r t o , 0 )   c r o n o p _ e l e m _ d e t _ i m p o r t o , 
 
                           c o a l e s c e ( d e t . c r o n o p _ e l e m _ d e t _ d e s c , ' ' )   c r o n o p _ e l e m _ d e t _ d e s c , 
 
                           c o a l e s c e ( d e t . a n n o _ e n t r a t a , ' ' )                 a n n o _ e n t r a t a , 
 
                           c o a l e s c e ( d e t . e l e m _ d e t _ t i p o _ i d , 0 )           e l e m _ d e t _ t i p o _ i d 
 
           f r o m   s i a c _ t _ c r o n o p   c r o n o p , s i a c _ r _ c r o n o p _ s t a t o   r s , s i a c _ d _ c r o n o p _ s t a t o   s t a t o , 
 
                     s i a c _ t _ p r o g r a m m a   p r o g , s i a c _ r _ p r o g r a m m a _ s t a t o   r s p , s i a c _ d _ p r o g r a m m a _ s t a t o   p s t a t o ,   s i a c _ d _ p r o g r a m m a _ t i p o   t i p o , 
 
                     s i a c _ t _ c r o n o p _ e l e m   c e l e m , s i a c _ t _ c r o n o p _ e l e m _ d e t   d e t 
 
       	   w h e r e     t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
           a n d         t i p o . p r o g r a m m a _ t i p o _ c o d e = G _ F A S E 
 
           a n d         p r o g . p r o g r a m m a _ t i p o _ i d = t i p o . p r o g r a m m a _ t i p o _ i d 
 
           a n d         c r o n o p . p r o g r a m m a _ i d = p r o g . p r o g r a m m a _ i d 
 
           a n d         c e l e m . c r o n o p _ i d = c r o n o p . c r o n o p _ i d 
 
           a n d         d e t . c r o n o p _ e l e m _ i d = c e l e m . c r o n o p _ e l e m _ i d 
 
           a n d         r s . c r o n o p _ i d = c r o n o p . c r o n o p _ i d 
 
           a n d         s t a t o . c r o n o p _ s t a t o _ i d = r s . c r o n o p _ s t a t o _ i d 
 
           a n d         s t a t o . c r o n o p _ s t a t o _ c o d e = ' V A ' 
 
           a n d         r s p . p r o g r a m m a _ i d = p r o g . p r o g r a m m a _ i d 
 
           a n d         p s t a t o . p r o g r a m m a _ s t a t o _ i d = r s p . p r o g r a m m a _ s t a t o _ i d 
 
           a n d         p s t a t o . p r o g r a m m a _ s t a t o _ c o d e = ' V A ' 
 
           a n d         r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d         r s . v a l i d i t a _ f i n e   i s   n u l l 
 
           a n d         r s p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d         r s p . v a l i d i t a _ f i n e   i s   n u l l 
 
           a n d         p r o g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d         p r o g . v a l i d i t a _ f i n e   i s   n u l l 
 
           a n d         c r o n o p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d         c r o n o p . v a l i d i t a _ f i n e   i s   n u l l 
 
           a n d         c e l e m . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d         c e l e m . v a l i d i t a _ f i n e   i s   n u l l 
 
           a n d         d e t . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d         d e t . v a l i d i t a _ f i n e   i s   n u l l 
 
 
 
         ) 
 
         s e l e c t   c r o n o p _ e l e m _ a n n o . c r o n o p _ e l e m _ i d   c r o n o p _ e l e m _ n e w _ i d , 
 
                       c r o n o p _ e l e m _ a n n o . c r o n o p _ i d   c r o n o p _ n e w _ i d , 
 
                       m o v _ r e s _ a n n o . m o v g e s t _ t s _ i d 
 
         f r o m   m o v _ r e s _ a n n o ,   m o v _ r e s _ a n n o _ p r e c ,   c r o n o p _ e l e m   c r o n o p _ e l e m _ a n n o _ p r e c ,   c r o n o p _ e l e m   c r o n o p _ e l e m _ a n n o 
 
         w h e r e   m o v _ r e s _ a n n o . m o v g e s t _ a n n o = m o v _ r e s _ a n n o _ p r e c . m o v g e s t _ a n n o 
 
         a n d       m o v _ r e s _ a n n o . m o v g e s t _ n u m e r o = m o v _ r e s _ a n n o _ p r e c . m o v g e s t _ n u m e r o 
 
         a n d       m o v _ r e s _ a n n o . m o v g e s t _ s u b n u m e r o = m o v _ r e s _ a n n o _ p r e c . m o v g e s t _ s u b n u m e r o 
 
         a n d       c r o n o p _ e l e m _ a n n o _ p r e c . c r o n o p _ e l e m _ i d = m o v _ r e s _ a n n o _ p r e c . c r o n o p _ e l e m _ i d 
 
         a n d       c r o n o p _ e l e m _ a n n o . b i l _ i d = b i l a n c i o I d 
 
         a n d       c r o n o p _ e l e m _ a n n o . p r o g r a m m a _ c o d e = c r o n o p _ e l e m _ a n n o _ p r e c . p r o g r a m m a _ c o d e 
 
         a n d       c r o n o p _ e l e m _ a n n o . c r o n o p _ c o d e = c r o n o p _ e l e m _ a n n o _ p r e c . c r o n o p _ c o d e 
 
         a n d       c r o n o p _ e l e m _ a n n o . c r o n o p _ e l e m _ c o d e = c r o n o p _ e l e m _ a n n o _ p r e c . c r o n o p _ e l e m _ c o d e 
 
         a n d       c r o n o p _ e l e m _ a n n o . c r o n o p _ e l e m _ c o d e 2 = c r o n o p _ e l e m _ a n n o _ p r e c . c r o n o p _ e l e m _ c o d e 2 
 
         a n d       c r o n o p _ e l e m _ a n n o . c r o n o p _ e l e m _ c o d e 3 = c r o n o p _ e l e m _ a n n o _ p r e c . c r o n o p _ e l e m _ c o d e 3 
 
         a n d       c r o n o p _ e l e m _ a n n o . e l e m _ t i p o _ i d = c r o n o p _ e l e m _ a n n o _ p r e c . e l e m _ t i p o _ i d 
 
         a n d       c r o n o p _ e l e m _ a n n o . c r o n o p _ e l e m _ d e s c = c r o n o p _ e l e m _ a n n o _ p r e c . c r o n o p _ e l e m _ d e s c 
 
         a n d       c r o n o p _ e l e m _ a n n o . c r o n o p _ e l e m _ d e s c 2 = c r o n o p _ e l e m _ a n n o _ p r e c . c r o n o p _ e l e m _ d e s c 2 
 
         a n d       c r o n o p _ e l e m _ a n n o . p e r i o d o _ i d = c r o n o p _ e l e m _ a n n o _ p r e c . p e r i o d o _ i d 
 
         a n d       c r o n o p _ e l e m _ a n n o . c r o n o p _ e l e m _ d e t _ i m p o r t o = c r o n o p _ e l e m _ a n n o _ p r e c . c r o n o p _ e l e m _ d e t _ i m p o r t o 
 
         a n d       c r o n o p _ e l e m _ a n n o . c r o n o p _ e l e m _ d e t _ d e s c = c r o n o p _ e l e m _ a n n o _ p r e c . c r o n o p _ e l e m _ d e t _ d e s c 
 
         a n d       c r o n o p _ e l e m _ a n n o . a n n o _ e n t r a t a = c r o n o p _ e l e m _ a n n o _ p r e c . a n n o _ e n t r a t a 
 
         a n d       c r o n o p _ e l e m _ a n n o . e l e m _ d e t _ t i p o _ i d = c r o n o p _ e l e m _ a n n o _ p r e c . e l e m _ d e t _ t i p o _ i d 
 
         a n d       e x i s t s 
 
         ( 
 
         	 s e l e c t   1 
 
                 f r o m   s i a c _ r _ c r o n o p _ e l e m _ c l a s s   r c , s i a c _ t _ c l a s s   c 
 
                 w h e r e   r c . c r o n o p _ e l e m _ i d = c r o n o p _ e l e m _ a n n o _ p r e c . c r o n o p _ e l e m _ i d 
 
                 a n d       c . c l a s s i f _ i d = r c . c l a s s i f _ i d 
 
                 a n d       e x i s t s 
 
                 ( 
 
                 	 s e l e c t   1 
 
                         f r o m   s i a c _ r _ c r o n o p _ e l e m _ c l a s s   r c 1 , s i a c _ t _ c l a s s   c 1 
 
                         w h e r e   r c 1 . c r o n o p _ e l e m _ i d = c r o n o p _ e l e m _ a n n o . c r o n o p _ e l e m _ i d 
 
                         a n d       c 1 . c l a s s i f _ i d = r c 1 . c l a s s i f _ i d 
 
                         a n d       c 1 . c l a s s i f _ t i p o _ i d = c . c l a s s i f _ t i p o _ i d 
 
                         a n d       c 1 . c l a s s i f _ c o d e = c . c l a s s i f _ c o d e 
 
                         a n d       r c 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       r c 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
                 ) 
 
                 a n d       r c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       r c . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) 
 
         a n d   n o t   e x i s t s 
 
         ( 
 
         	 s e l e c t   1 
 
                 f r o m   s i a c _ r _ c r o n o p _ e l e m _ c l a s s   r c , s i a c _ t _ c l a s s   c 
 
                 w h e r e   r c . c r o n o p _ e l e m _ i d = c r o n o p _ e l e m _ a n n o _ p r e c . c r o n o p _ e l e m _ i d 
 
                 a n d       c . c l a s s i f _ i d = r c . c l a s s i f _ i d 
 
                 a n d       n o t   e x i s t s 
 
                 ( 
 
                 	 s e l e c t   1 
 
                         f r o m   s i a c _ r _ c r o n o p _ e l e m _ c l a s s   r c 1 , s i a c _ t _ c l a s s   c 1 
 
                         w h e r e   r c 1 . c r o n o p _ e l e m _ i d = c r o n o p _ e l e m _ a n n o . c r o n o p _ e l e m _ i d 
 
                         a n d       c 1 . c l a s s i f _ i d = r c 1 . c l a s s i f _ i d 
 
                         a n d       c 1 . c l a s s i f _ t i p o _ i d = c . c l a s s i f _ t i p o _ i d 
 
                         a n d       c 1 . c l a s s i f _ c o d e = c . c l a s s i f _ c o d e 
 
                         a n d       r c 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       r c 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
                 ) 
 
                 a n d       r c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       r c . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) 
 
       )   q u e r y 
 
     ) ; 
 
     G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
     r a i s e   n o t i c e   ' %   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m   r e s . i n s e r i m e n t i   = % ' ,   s t r M e s s a g g i o , c o d R e s u l t ; 
 
 
 
     s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   I n s e r i t e   n u m . = % ' | | c o a l e s c e ( c o d R e s u l t , 0 ) | | '   r i g h e . ' ; 
 
     c o d R e s u l t : = n u l l ; 
 
     i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
     ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
       v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
     ) 
 
     v a l u e s 
 
     ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | ' - ' | | s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
     r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
     i f   c o d R e s u l t   i s   n u l l   t h e n 
 
           r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
     e n d   i f ; 
 
 
 
     s t r M e s s a g g i o : = ' R i b a l t a m e n t o   l e g a m e   t r a   m o v i m e n t i   d i   g e s t i o n e   e   p r o g r a m m i - c r o n o p   -   f i n e . ' ; 
 
     c o d R e s u l t : = n u l l ; 
 
     i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
     ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
         v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
     ) 
 
     v a l u e s 
 
     ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | ' - ' | | s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
     r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
     i f   c o d R e s u l t   i s   n u l l   t h e n 
 
     	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
     e n d   i f ; 
 
   e n d   i f ; 
 
   - -   0 6 . 0 5 . 2 0 1 9   S o f i a   s i a c - 6 2 5 5 
 
 
 
 
 
 
 
   s t r M e s s a g g i o : = ' I n s e r i m e n t o   L O G . ' ; 
 
   c o d R e s u l t : = n u l l ; 
 
   i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
   ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
     v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
   ) 
 
   v a l u e s 
 
   ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | ' - F I N E . ' , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
     r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
   i f   c o d R e s u l t   i s   n u l l   t h e n 
 
     	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
   e n d   i f ; 
 
 
 
 
 
   i f   c o d i c e R i s u l t a t o = 0   t h e n 
 
       	 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | ' -   F I N E . ' ; 
 
   e l s e   m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o ; 
 
   e n d   i f ; 
 
 
 
   r e t u r n ; 
 
 
 
 e x c e p t i o n 
 
         w h e n   R A I S E _ E X C E P T I O N   T H E N 
 
         	 r a i s e   n o t i c e   ' %   %   E R R O R E   :   % ' , s t r M e s s a g g i o F i n a l e , s t r M e s s a g g i o , 
 
 	                 	 s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   1 5 0 0 ) ; 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o | | ' E R R O R E   : ' | | '   ' | | s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   1 0 0 0 )   ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 r e t u r n ; 
 
 
 
 	 w h e n   n o _ d a t a _ f o u n d   T H E N 
 
 	 	 r a i s e   n o t i c e   '   %   %   N e s s u n   e l e m e n t o   t r o v a t o . '   , s t r M e s s a g g i o F i n a l e , s t r M e s s a g g i o ; 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o | | ' N e s s u n   e l e m e n t o   t r o v a t o . '   ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
 	 	 r e t u r n ; 
 
 	 w h e n   o t h e r s     T H E N 
 
 	 	 r a i s e   n o t i c e   ' %   %   E r r o r e   D B   %   % ' , s t r M e s s a g g i o F i n a l e , s t r M e s s a g g i o , S Q L S T A T E , 
 
 	                 	 s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   1 5 0 0 ) ; 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o | | ' E r r o r e   D B   ' | | S Q L S T A T E | | '   ' | | s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   1 0 0 0 )   ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 r e t u r n ; 
 
 E N D ; 
 
 $ b o d y $ 
 
 L A N G U A G E   ' p l p g s q l ' 
 
 V O L A T I L E 
 
 C A L L E D   O N   N U L L   I N P U T 
 
 S E C U R I T Y   I N V O K E R 
 
 C O S T   1 0 0 ; 