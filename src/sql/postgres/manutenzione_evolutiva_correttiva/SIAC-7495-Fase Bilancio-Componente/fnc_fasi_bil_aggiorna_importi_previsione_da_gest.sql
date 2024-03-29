/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 07.04.2016 Sofia - predisposizione bilancio di previsione da gestione precedente
-- 07.07.2016 Sofia - adeguamento per backup e aggiornamento importi
-- bilancio gestione annoBilancio-1
-- importo previsione annoBilancio  = importo gestione annoBilancio,   del bilancio annoBilancio-1
-- importo previsione annoBilancio+1= importo gestione annoBilancio+1, del bilancio annoBilancio-1
-- importo previsione annoBilancio+2=0
CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_prev_apertura_importi
(
  annobilancio    integer,
  euElemTipo      varchar,
  bilElemPrevTipo varchar,
  bilElemGestTipo varchar,
  elemPrevEq      boolean, -- trattamento capitoli di gestione equivalenti esistenti
  importiGest     boolean, -- impostazione importi di previsione da gestione anno precedente
  faseBilElabId   integer, -- identificativo elaborazione
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp, -- deve essere passato con now() o clock_timepstamp()
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	APE_PREV_DA_GEST CONSTANT varchar:='APE_PREV';
    SY_PER_TIPO      CONSTANT varchar:='SY';
    STI_DET_TIPO     CONSTANT varchar:='STI';
    SRI_DET_TIPO     CONSTANT varchar:='SRI';
    SCI_DET_TIPO     CONSTANT varchar:='SCI';

    STA_DET_TIPO     CONSTANT varchar:='STA';
    STR_DET_TIPO     CONSTANT varchar:='STR';
    SCA_DET_TIPO     CONSTANT varchar:='SCA';
    STASS_DET_TIPO   CONSTANT varchar:='STASS';
    STCASS_DET_TIPO  CONSTANT varchar:='STCASS';
    STRASS_DET_TIPO  CONSTANT varchar:='STRASS';

    -- SIAC-5788
    MI_DET_TIPO      CONSTANT varchar:='MI';

    -- SIAC-7495 Sofia 09.09.2020
    CAP_UG_ST CONSTANT varchar:='CAP-UG';
    CAP_UP_ST CONSTANT varchar:='CAP-UP';

	prevEqEsiste      integer:=null;
    prevEqApri     integer:=null;
    prevEqEsisteNoGest  integer:=null;
    codResult         integer:=null;
	dataInizioVal     timestamp:=null;

    bilancioId        integer:=null;

    periodoId        integer:=null;
    periodoAnno1Id   integer:=null;
    periodoAnno2Id   integer:=null;

    detTipoStaId     integer:=null;
    detTipoScaId     integer:=null;
    detTipoStrId     integer:=null;

    detTipoStiId     integer:=null;
    detTipoSciId     integer:=null;
    detTipoSriId     integer:=null;

    detTipoStassId     integer:=null;
    detTipoStcassId     integer:=null;
    detTipoStrassId     integer:=null;

    detTipoMiId       integer:=null;


BEGIN

	messaggioRisultato:='';
    codiceRisultato:=0;


    dataInizioVal:=clock_timestamp();-- usato al posto di now() per essere certi di riconoscere i record inseriti dopo la chiamata della funzione;

	strMessaggioFinale:='Apertura bilancio di previsione.Aggiornamento importi Previsione '||bilElemPrevTipo||' da Gestione anno precedente'||bilElemGEstTipo||
    					'.Anno bilancio='||annoBilancio::varchar||'.';

    strMessaggio:='Lettura validita'' identificativo tipo importo '||STI_DET_TIPO||'.';
	select tipo.elem_det_tipo_id into strict detTipoStiId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=STI_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

	strMessaggio:='Lettura validita'' identificativo tipo importo '||STA_DET_TIPO||'.';
	select tipo.elem_det_tipo_id into strict detTipoStaId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=STA_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura validita'' identificativo tipo importo '||SCI_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoSciId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=SCI_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura validita'' identificativo tipo importo '||SCA_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoScaId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=SCA_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;


    strMessaggio:='Lettura validita'' identificativo tipo importo '||SRI_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoSriId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=SRI_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura validita'' identificativo tipo importo '||STR_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoStrId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=STR_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;


    --- stanziamenti assestamento di gestione 'STASS','STCASS','STRASS'
    strMessaggio:='Lettura validita'' identificativo tipo importo '||STASS_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoStassId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=STASS_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

	strMessaggio:='Lettura validita'' identificativo tipo importo '||STCASS_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoStcassId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=STCASS_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura validita'' identificativo tipo importo '||STRASS_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoStrassId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=STRASS_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura validita'' identificativo tipo importo '||MI_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoMiId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=MI_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;


    strMessaggio:='Lettura validita'' identificativo elaborazione faseBilElabId='||faseBilElabId||'.';
    codResult:=null;
	select  1 into codResult
    from fase_bil_t_elaborazione fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.ente_proprietario_id=enteProprietarioId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   fase.fase_bil_elab_esito!='IN2';

    if codResult is not null then
    	raise exception ' Identificatvo elab. non valido.';
    end if;


  	strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
    select bil.bil_id,per.periodo_id into strict bilancioId, periodoId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio
    and   per.data_cancellazione is null;

  	strMessaggio:='Lettura periodoAnno1Id  per annoBilancio+1='||(annoBilancio+1)::varchar||'.';
    select per.periodo_id into strict periodoAnno1Id
    from siac_t_periodo per, siac_d_periodo_tipo tipo
    where per.ente_proprietario_id=enteProprietarioId
    and   per.anno::INTEGER=annoBilancio+1
    and   tipo.periodo_tipo_id=per.periodo_tipo_id
    and   tipo.periodo_tipo_code=SY_PER_TIPO
    and   per.data_cancellazione is null;


  	strMessaggio:='Lettura periodoAnno2Id  per annoBilancio+2='||(annoBilancio+2)::varchar||'.';
    select per.periodo_id into strict periodoAnno2Id
    from siac_t_periodo per, siac_d_periodo_tipo tipo
    where per.ente_proprietario_id=enteProprietarioId
    and   per.anno::INTEGER=annoBilancio+2
    and   tipo.periodo_tipo_id=per.periodo_tipo_id
    and   tipo.periodo_tipo_code=SY_PER_TIPO
    and   per.data_cancellazione is null;


	codResult:=null;
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;


    -- cancellazione logica importi di previsione equivalente esistente
    if elemPrevEq=true then
        strMessaggio:='Verifica esistenza elementi di bilancio di previsione equivalenti da aggiornare da gestione anno precedente.';

    	select distinct 1 into prevEqEsiste
        from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null
        and   fase.elem_gest_id is not null
        limit 1;

        codResult:=null;
   	    insert into fase_bil_t_elaborazione_log
        (fase_bil_elab_id,fase_bil_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
        values
        (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
        returning fase_bil_elab_log_id into codResult;

        if codResult is null then
        	raise exception ' Errore in inserimento LOG.';
        end if;

        if prevEqEsiste is not null then
	    /* 07.07.2016 Sostituito con backup di seguito
         strMessaggio:='Cancellazione logica importi capitoli di previsione equivalenti esistenti.';
    	 update siac_t_bil_elem_det det
	      set data_cancellazione=now(), validita_inizio=now(), login_operazione=loginOperazione
    	 from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
	     where  fase.ente_proprietario_id=enteProprietarioId
         and    fase.bil_id=bilancioId
         and    fase.fase_bil_elab_id=faseBilElabId
    	 and    fase.data_cancellazione is null
         and    fase.validita_fine is null
	     and    fase.elem_gest_id is not null
         and    det.elem_id=fase.elem_prev_id
         and    det.data_cancellazione is null
         and    det.validita_fine is null; */

	     -- 07.07.2016 Sofia inserimento backup
		 strMessaggio:='Inserimento backup importi capitoli di previsione equivalenti esistenti.';
         insert into bck_fase_bil_t_prev_apertura_bil_elem_det
         (elem_bck_id,
		  elem_bck_det_id,
		  elem_bck_det_importo,
		  elem_bck_det_flag,
		  elem_bck_det_tipo_id,
		  elem_bck_periodo_id,
		  elem_bck_data_creazione,
		  elem_bck_data_modifica,
		  elem_bck_login_operazione,
	      elem_bck_validita_inizio,
		  elem_bck_validita_fine,
	      fase_bil_elab_id,
		  validita_inizio,
          login_operazione,
          ente_proprietario_id
          )
          (select det.elem_id, det.elem_det_id, det.elem_det_importo,det.elem_det_flag,det.elem_det_tipo_id,
                  det.periodo_id,det.data_creazione,det.data_modifica,det.login_operazione,det.validita_inizio,
                  det.validita_fine, fase.fase_bil_elab_id,now(),loginOperazione,fase.ente_proprietario_id
           from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det
           where fase.ente_proprietario_id=enteProprietarioId
	       and   fase.bil_id=bilancioId
    	   and   fase.fase_bil_elab_id=faseBilElabId
    	   and   fase.data_cancellazione is null
	       and   fase.validita_fine is null
		   and   fase.elem_gest_id is not null
           and   det.elem_id=fase.elem_prev_id
	       and   det.data_cancellazione is null
     	   and   det.validita_fine is null
          );

          codResult:=null;
          strmessaggio:=strMessaggio||' Verifica inserimento.';
          select 1  into codResult
          from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det
          where fase.ente_proprietario_id=enteProprietarioId
	       and   fase.bil_id=bilancioId
    	   and   fase.fase_bil_elab_id=faseBilElabId
    	   and   fase.data_cancellazione is null
	       and   fase.validita_fine is null
		   and   fase.elem_gest_id is not null
           and   det.elem_id=fase.elem_prev_id
	       and   det.data_cancellazione is null
     	   and   det.validita_fine is null
           and   not exists (select 1 from bck_fase_bil_t_prev_apertura_bil_elem_det bck
                             where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                             and   bck.elem_bck_id=det.elem_id
                             and   bck.data_cancellazione is null
                             and   bck.validita_fine is null);
           if codResult is not null then raise exception ' Elementi senza backup importi.'; end if;

         codResult:=null;
   	     insert into fase_bil_t_elaborazione_log
         (fase_bil_elab_id,fase_bil_elab_log_operazione,
          validita_inizio, login_operazione, ente_proprietario_id
         )
         values
         (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
          returning fase_bil_elab_log_id into codResult;

          if codResult is null then
        	raise exception ' Errore in inserimento LOG.';
          end if;

         -- SIAC-7495 Sofia 08.09.2020 - inizio
 		 if bilElemPrevTipo=CAP_UP_ST then
           -- Sofia inserimento backup componenti
           -- per capitoli di previsione esistenti relativi a capitoli di gestione esistenti in anno prec
           strMessaggio:='Inserimento backup importi capitoli di previsione equivalenti esistenti.Componenti.';
           insert into bck_fase_bil_t_prev_apertura_bil_elem_det_comp
           (
            elem_bck_det_comp_id,
            elem_bck_det_id,
            elem_bck_det_comp_tipo_id,
            elem_bck_det_importo,
            elem_bck_data_creazione,
            elem_bck_data_modifica,
            elem_bck_login_operazione,
            elem_bck_validita_inizio,
            elem_bck_validita_fine,
            fase_bil_elab_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
            )
            (select comp.elem_det_comp_id,
                    comp.elem_det_id,
                    comp.elem_det_comp_tipo_id,
                    comp.elem_det_importo,
                    comp.data_creazione,comp.data_modifica,comp.login_operazione,comp.validita_inizio,
                    comp.validita_fine, fase.fase_bil_elab_id,clock_timestamp(),loginOperazione,fase.ente_proprietario_id
             from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det,
                  siac_t_bil_elem_det_comp comp
             where fase.ente_proprietario_id=enteProprietarioId
             and   fase.bil_id=bilancioId
             and   fase.fase_bil_elab_id=faseBilElabId
             and   fase.data_cancellazione is null
             and   fase.validita_fine is null
             and   fase.elem_gest_id is not null
             and   det.elem_id=fase.elem_prev_id
             and   comp.elem_det_id=det.elem_det_id
             and   det.data_cancellazione is null
             and   det.validita_fine is null
             and   comp.data_cancellazione is null
             and   comp.validita_fine is null
            );

            codResult:=null;
            strmessaggio:=strMessaggio||' Verifica inserimento.';
            select 1  into codResult
            from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det,siac_t_bil_elem_det_comp comp
            where fase.ente_proprietario_id=enteProprietarioId
             and   fase.bil_id=bilancioId
             and   fase.fase_bil_elab_id=faseBilElabId
             and   fase.data_cancellazione is null
             and   fase.validita_fine is null
             and   fase.elem_gest_id is not null
             and   det.elem_id=fase.elem_prev_id
             and   comp.elem_det_id=det.elem_det_id
             and   det.data_cancellazione is null
             and   det.validita_fine is null
             and   comp.data_cancellazione is null
             and   comp.validita_fine is null
             and   not exists (select 1 from bck_fase_bil_t_prev_apertura_bil_elem_det_comp bck
                               where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                               and   bck.elem_bck_det_comp_id=comp.elem_det_comp_id
                               and   bck.data_cancellazione is null
                               and   bck.validita_fine is null);
           if codResult is not null then raise exception ' Elementi senza backup importi componenti.'; end if;

           codResult:=null;
           insert into fase_bil_t_elaborazione_log
           (fase_bil_elab_id,fase_bil_elab_log_operazione,
            validita_inizio, login_operazione, ente_proprietario_id
           )
           values
           (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
            returning fase_bil_elab_log_id into codResult;

            if codResult is null then
              raise exception ' Errore in inserimento LOG.';
            end if;
          end if;
          -- SIAC-7495 Sofia 08.09.2020 - fine
       end if;
    end if;

    strMessaggio:='Verifica esistenza elementi di bilancio di previsione equivalenti da aprire.';

	select distinct 1 into prevEqApri
    from fase_bil_t_prev_apertura_str_elem_prev_nuovo fase
    where fase.ente_proprietario_id=enteProprietarioId
    and   fase.bil_id=bilancioId
    and   fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    limit 1;

	codResult:=null;
   	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    if prevEqApri is not null then
     strMessaggio:='Inserimento  importi capitoli di previsione da gestione equivalenti anno precedente per annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
     --- inserimento nuovi importi
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
      validita_inizio, ente_proprietario_id, login_operazione)
     (select fase.elem_prev_id,
            (case when importiGest=true then det.elem_det_importo
    			  else 0 END),
            det.elem_det_tipo_id,
            det.periodo_id,
            dataInizioVal,det.ente_proprietario_id,loginOperazione
      from fase_bil_t_prev_apertura_str_elem_prev_nuovo fase,
           siac_t_bil_elem_det det
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   det.elem_id=fase.elem_id
      and   det.elem_det_tipo_id not in (detTipoSciId,detTipoSriId,detTipoStiId)
      and   det.elem_det_tipo_id not in (detTipoStassId,detTipoStcassId,detTipoStrassId) -- esclusione importi assestamento di gestione
      and   det.elem_det_tipo_id not in (detTipoMiId) -- esclusione importi massimo impegnabile SIAC-5788
      and   det.periodo_id in (periodoId, periodoAnno1Id) -- impostazione degli importi dalla gestione anno prec per anno e anno+1
      and   det.data_cancellazione is null
      and   det.validita_fine is null
     );

     strMessaggio:='Inserimento  importi iniziali capitoli di previsione da gestione attuali equivalenti anno precedente per annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
      validita_inizio, ente_proprietario_id, login_operazione)
     (select fase.elem_prev_id,
            (case when importiGest=true then det.elem_det_importo
    			  else 0 END),
            (case when det.elem_det_tipo_id=detTipoScaId then detTipoSciId
                  when det.elem_det_tipo_id=detTipoStaId then detTipoStiId
                  when det.elem_det_tipo_id=detTipoStrId then detTipoSriId end),
            det.periodo_id,
            dataInizioVal,det.ente_proprietario_id,loginOperazione
      from fase_bil_t_prev_apertura_str_elem_prev_nuovo fase,
           siac_t_bil_elem_det det
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   det.elem_id=fase.elem_id
      and   det.elem_det_tipo_id in (detTipoScaId,detTipoStrId,detTipoStaId)
      and   det.periodo_id in (periodoId, periodoAnno1Id) -- impostazione degli importi dalla gestione anno prec per anno e anno+1
      and   det.data_cancellazione is null
      and   det.validita_fine is null
     );

     strMessaggio:='Inserimento  importi capitoli di previsione per annoBilancio+2='||(annoBilancio+2)::varchar||'.';
     --- inserimento nuovi importi
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
      validita_inizio, ente_proprietario_id, login_operazione)
     (select fase.elem_prev_id,
             0,
             det.elem_det_tipo_id,
             periodoAnno2Id,
             dataInizioVal,det.ente_proprietario_id,loginOperazione
      from fase_bil_t_prev_apertura_str_elem_prev_nuovo fase,
           siac_t_bil_elem_det det
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   det.elem_id=fase.elem_prev_id
      and   det.periodo_id=periodoId
      and   det.data_cancellazione is null
      and   det.validita_fine is null
     );

     codResult:=null;
     insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
       raise exception ' Errore in inserimento LOG.';
     end if;

     --- controllo inserimento importi prec
     codResult:=null;
     strMessaggio:='Inserimento  importi capitoli di previsione da gestione equivalenti anno precedente.Verifica inserimento.';
     select 1  into codResult
     from siac_t_bil_elem_det det , fase_bil_t_prev_apertura_str_elem_prev_nuovo fase
     where fase.ente_proprietario_id=enteProprietarioId
     and   fase.bil_id=bilancioId
     and   fase.fase_bil_elab_id=faseBilElabId
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null
     and   det.elem_id=fase.elem_prev_id
     and   det.data_cancellazione is null
     and   det.validita_fine is null
     limit 1;

     if codResult is null then
    	raise exception ' Non effettuato.';
     end if;

     codResult:=null;
     insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
        	raise exception ' Errore in inserimento LOG.';
     end if;


     -- SIAC-7495 Sofia 08.09.2020 - inizio
     if bilElemPrevTipo=CAP_UP_ST then
       -- inserimento componenti per nuovi capitolid i bilancio di previsione
       strMessaggio:='Inserimento  importi capitoli componenti di previsione annoBilancio='
                    ||annoBilancio::varchar
                    ||' e annoBilancio+1='
                    ||(annoBilancio+1)::varchar
                    ||'.';
       --- inserimento nuovi importi componenti
       insert into siac_t_bil_elem_det_comp
       (elem_det_id,
        elem_det_comp_tipo_id,
        elem_det_importo,
        validita_inizio, ente_proprietario_id, login_operazione)
       (select det.elem_det_id,
               tipo_comp.elem_det_comp_tipo_id,
               compgest.elem_det_importo,
               dataInizioVal,det.ente_proprietario_id,loginOperazione
        from fase_bil_t_prev_apertura_str_elem_prev_nuovo fase,
             siac_t_bil_elem_det det,
             siac_t_bil_elem_det detGest,
             siac_t_bil_elem_det_comp compGest,siac_d_bil_elem_det_comp_tipo tipo_comp
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null
        and   det.elem_id=fase.elem_prev_id
        and   det.periodo_id in ( periodoId, periodoAnno1Id)
        and   detGest.elem_id=fase.elem_id
        and   detGest.periodo_id=det.periodo_id
        and   detGest.elem_det_tipo_id=det.elem_det_tipo_id
        and   compGest.elem_det_id=detGest.elem_det_id
        and   tipo_comp.elem_det_comp_tipo_id=compGest.elem_det_comp_tipo_id
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   detGest.data_cancellazione is null
        and   detGest.validita_fine is null
        and   compGest.data_cancellazione is null
        and   compGest.validita_fine is null
        and   tipo_comp.data_cancellazione is null
       );

       strMessaggio:='Inserimento  importi capitoli componenti di previsione annoBilancio+2='
                    ||(annoBilancio+2)::varchar
                    ||'.';

       insert into siac_t_bil_elem_det_comp
       (elem_det_id,
        elem_det_comp_tipo_id,
        elem_det_importo,
        validita_inizio, ente_proprietario_id, login_operazione)
       (select det.elem_det_id,
               tipo_comp.elem_det_comp_tipo_id,
               0,
               dataInizioVal,det.ente_proprietario_id,loginOperazione
        from fase_bil_t_prev_apertura_str_elem_prev_nuovo fase,
             siac_t_bil_elem_det det,
             siac_t_bil_elem_det detGest,
             siac_t_bil_elem_det_comp compGest,siac_d_bil_elem_det_comp_tipo tipo_comp
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null
        and   det.elem_id=fase.elem_prev_id
        and   det.periodo_id = periodoAnno2Id
        and   detGest.elem_id=fase.elem_id
        and   detGest.periodo_id=periodoId
        and   detGest.elem_det_tipo_id=det.elem_det_tipo_id
        and   compGest.elem_det_id=detGest.elem_det_id
        and   tipo_comp.elem_det_comp_tipo_id=compGest.elem_det_comp_tipo_id
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   detGest.data_cancellazione is null
        and   detGest.validita_fine is null
        and   compGest.data_cancellazione is null
        and   compGest.validita_fine is null
        and   tipo_comp.data_cancellazione is null
       );

       codResult:=null;
       insert into fase_bil_t_elaborazione_log
       (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
       )
       values
       (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
       returning fase_bil_elab_log_id into codResult;

       if codResult is null then
         raise exception ' Errore in inserimento LOG.';
       end if;

       --- controllo inserimento importi prec
       codResult:=null;
       strMessaggio:='Inserimento  importi componenti capitoli di previsione da gestione equivalenti anno precedente.Verifica inserimento.';
       select 1  into codResult
       from siac_t_bil_elem_det det , fase_bil_t_prev_apertura_str_elem_prev_nuovo fase,
            siac_t_bil_elem_det_comp comp,siac_d_bil_elem_det_comp_tipo tipo
       where fase.ente_proprietario_id=enteProprietarioId
       and   fase.bil_id=bilancioId
       and   fase.fase_bil_elab_id=faseBilElabId
       and   fase.data_cancellazione is null
       and   fase.validita_fine is null
       and   det.elem_id=fase.elem_prev_id
       and   comp.elem_det_id=det.elem_det_id
       and   tipo.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
       and   det.data_cancellazione is null
       and   det.validita_fine is null
       and   comp.data_cancellazione is null
       and   comp.validita_fine is null
       and   tipo.data_cancellazione is null
       limit 1;

       if codResult is null then
          raise exception ' Non effettuato.';
       end if;

       codResult:=null;
       insert into fase_bil_t_elaborazione_log
       (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
       )
       values
       (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
       returning fase_bil_elab_log_id into codResult;

       if codResult is null then
              raise exception ' Errore in inserimento LOG.';
       end if;
     end if;
     -- SIAC-7495 Sofia 08.09.2020 - fine
    end if;

--	raise notice 'elemPrevEq=% prevEqEsiste=%', elemPrevEq,prevEqEsiste;
	if elemPrevEq=true and prevEqEsiste is not null then
        -- sostituire con update

	    /* 07.07.2016 Sofia - sostituito con update di seguito
        strMessaggio:='Inserimento importi capitoli di previsione esistenti da gestione equivalenti anno precedente annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
    	--- inserimento nuovi importi
	    insert into siac_t_bil_elem_det
    	(elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
	     validita_inizio, ente_proprietario_id, login_operazione)
    	(select fase.elem_prev_id,
            (case when importiGest=true then det.elem_det_importo
    			  else 0 END),
            det.elem_det_tipo_id,
            det.periodo_id,
            dataInizioVal,det.ente_proprietario_id,loginOperazione
	     from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
	     and   fase.elem_gest_id is not null
    	 and   det.elem_id=fase.elem_gest_id
         and   det.periodo_id in (periodoId, periodoAnno1Id)
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
	    );*/

        strMessaggio:='Aggiornamento importi capitoli di previsione esistenti da gestione equivalenti anno precedente annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
        update siac_t_bil_elem_det detCor
        set elem_det_importo=det.elem_det_importo,
            elem_det_flag=det.elem_det_flag,
            data_modifica=now(),
            login_operazione=loginOperazione
        from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det
         where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
	     and   fase.elem_gest_id is not null
   	     and   fase.elem_prev_id is not null
         and   detCor.elem_id=fase.elem_prev_id
         and   detCor.periodo_id in (periodoId, periodoAnno1Id)
    	 and   det.elem_id=fase.elem_gest_id
         and   det.periodo_id in (periodoId, periodoAnno1Id)
         and   det.elem_det_tipo_id not in (detTipoSciId,detTipoSriId,detTipoStiId)
         and   det.elem_det_tipo_id not in (detTipoMiId)-- esclusione importi massimo impegnabile SIAC-5788
         and   detCor.elem_det_tipo_id=det.elem_det_tipo_id
         and   detCor.periodo_id=det.periodo_id
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
   	     and   detCor.data_cancellazione is null
    	 and   detCor.validita_fine is null;

        strMessaggio:='Aggiornamento importi cassa iniziale capitoli di previsione esistenti da gestione cassa attuale equivalenti anno precedente annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
        update siac_t_bil_elem_det detCor
        set elem_det_importo=det.elem_det_importo,
            elem_det_flag=det.elem_det_flag,
            data_modifica=now(),
            login_operazione=loginOperazione
        from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det
         where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
	     and   fase.elem_gest_id is not null
   	     and   fase.elem_prev_id is not null
         and   detCor.elem_id=fase.elem_prev_id
         and   detCor.periodo_id in (periodoId, periodoAnno1Id)
    	 and   det.elem_id=fase.elem_gest_id
         and   det.periodo_id in (periodoId, periodoAnno1Id)
         and   det.elem_det_tipo_id=detTipoScaId
         and   detCor.elem_det_tipo_id=detTipoSciId
         and   detCor.periodo_id=det.periodo_id
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
   	     and   detCor.data_cancellazione is null
    	 and   detCor.validita_fine is null;


		strMessaggio:='Aggiornamento importi competenza  iniziale capitoli di previsione esistenti da gestione competenza attuale equivalenti anno precedente annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
        update siac_t_bil_elem_det detCor
        set elem_det_importo=det.elem_det_importo,
            elem_det_flag=det.elem_det_flag,
            data_modifica=now(),
            login_operazione=loginOperazione
        from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det
         where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
	     and   fase.elem_gest_id is not null
   	     and   fase.elem_prev_id is not null
         and   detCor.elem_id=fase.elem_prev_id
         and   detCor.periodo_id in (periodoId, periodoAnno1Id)
    	 and   det.elem_id=fase.elem_gest_id
         and   det.periodo_id in (periodoId, periodoAnno1Id)
         and   det.elem_det_tipo_id=detTipoStaId
         and   detCor.elem_det_tipo_id=detTipoStiId
         and   detCor.periodo_id=det.periodo_id
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
   	     and   detCor.data_cancellazione is null
    	 and   detCor.validita_fine is null;

		strMessaggio:='Aggiornamento importi residui  iniziale capitoli di previsione esistenti da gestione residua attuale equivalenti anno precedente annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
        update siac_t_bil_elem_det detCor
        set elem_det_importo=det.elem_det_importo,
            elem_det_flag=det.elem_det_flag,
            data_modifica=now(),
            login_operazione=loginOperazione
        from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det
         where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
	     and   fase.elem_gest_id is not null
   	     and   fase.elem_prev_id is not null
         and   detCor.elem_id=fase.elem_prev_id
         and   detCor.periodo_id in (periodoId, periodoAnno1Id)
    	 and   det.elem_id=fase.elem_gest_id
         and   det.periodo_id in (periodoId, periodoAnno1Id)
         and   det.elem_det_tipo_id=detTipoStrId
         and   detCor.elem_det_tipo_id=detTipoSriId
         and   detCor.periodo_id=det.periodo_id
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
   	     and   detCor.data_cancellazione is null
    	 and   detCor.validita_fine is null;


        -- sostituire con update
        /* 07.07.2016 Sofia - sostituito con update sotto
        strMessaggio:='Inserimento importi capitoli di previsione esistenti da gestione equivalenti anno precedente annoBilancio+2='||(annoBilancio+2)::varchar||'.';
    	--- inserimento nuovi importi
	    insert into siac_t_bil_elem_det
    	(elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
	     validita_inizio, ente_proprietario_id, login_operazione)
    	(select fase.elem_prev_id,
                0,
                det.elem_det_tipo_id,
                periodoAnno2Id,
                dataInizioVal,det.ente_proprietario_id,loginOperazione
	     from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
	     and   fase.elem_gest_id is not null
    	 and   det.elem_id=fase.elem_prev_id
         and   det.periodo_id =periodoId
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
	    ); */

        /* 07.07.2016 Sofia - aggiornamento a 0 degli importi del terzo anno  */
        strMessaggio:='Aggiornamento importi capitoli di previsione esistenti da gestione equivalenti anno precedente annoBilancio+2='||(annoBilancio+2)::varchar||'.';
        update siac_t_bil_elem_det detCor
        set  elem_det_importo=0,
             data_modifica=now(),
             login_operazione=loginOperazione
        from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
        where fase.ente_proprietario_id=enteProprietarioId
         and  fase.bil_id=bilancioId
         and  fase.fase_bil_elab_id=faseBilElabId
	     and  fase.data_cancellazione is null
    	 and  fase.validita_fine is null
	     and  fase.elem_gest_id is not null
    	 and  detCor.elem_id=fase.elem_prev_id
         and  detCor.periodo_id =periodoAnno2Id
	     and  detCor.data_cancellazione is null
    	 and  detCor.validita_fine is null;

		codResult:=null;
   	    insert into fase_bil_t_elaborazione_log
        (fase_bil_elab_id,fase_bil_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
        values
        (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
        returning fase_bil_elab_log_id into codResult;

        if codResult is null then
        	raise exception ' Errore in inserimento LOG.';
        end if;

    	--- controllo inserimento importi prec
	    /* 07.07.2016 Sofia - non serve controllare inserimento perche sopra solo update
        codResult:=null;
    	strMessaggio:='Inserimento importi capitoli di previsione esistenti da gestione equivalenti anno precedente.Verifica inserimento.';
	    select 1  into codResult
    	from siac_t_bil_elem_det det , fase_bil_t_prev_apertura_str_elem_prev_esiste fase
	    where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
    	and   fase.data_cancellazione is null
	    and   fase.validita_fine is null
    	and   fase.elem_gest_id is not null
	    and   det.elem_id=fase.elem_prev_id
    	and   det.data_cancellazione is null
	    and   det.validita_fine is null
        limit 1;

    	if codResult is null then
    		raise exception ' Non effettuato.';
	    end if;

        codResult:=null;
   	    insert into fase_bil_t_elaborazione_log
        (fase_bil_elab_id,fase_bil_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
        values
        (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
        returning fase_bil_elab_log_id into codResult;

        if codResult is null then
        	raise exception ' Errore in inserimento LOG.';
        end if; */

	    -- 08.09.2020 Sofia - SIAC-7495 - inizio
       if bilElemPrevTipo=CAP_UP_ST then
          -- aggiornamento delle componenti per i capitoli di previsione presenti
          -- relativi a capitoli di gestione presenti in anno prec
          strMessaggio:='Aggiornamento importi componenti capitoli di previsione esistenti da gestione equivalenti anno precedente annoBilancio='||annoBilancio::varchar
                       ||' e annoBilancio+2='||(annoBilancio+2)::varchar
                       ||'. Aggiornamento componenti esistenti in previsione.';
          update siac_t_bil_elem_det_comp detCompCor
          set  elem_det_importo=compGest.elem_det_importo,
               data_modifica=now(),
               login_operazione=loginOperazione
          from fase_bil_t_prev_apertura_str_elem_prev_esiste fase,
               siac_t_bil_elem_det detPrev,
               siac_t_bil_elem_det detGest, siac_t_bil_elem_det_comp compGest,
               siac_d_bil_elem_det_comp_tipo tipo_comp
          where fase.ente_proprietario_id=enteProprietarioId
           and  fase.bil_id=bilancioId
           and  fase.fase_bil_elab_id=faseBilElabId
           and  fase.data_cancellazione is null
           and  fase.validita_fine is null
           and  fase.elem_gest_id is not null
           and  detPrev.elem_id=fase.elem_prev_id
           and  detPrev.periodo_id in ( periodoId,periodoAnno1Id)
           and  detGest.elem_id=fase.elem_gest_id
           and  detGest.periodo_id=detPrev.periodo_id
           and  detGest.elem_det_tipo_id=detprev.elem_det_tipo_id
           and  compGest.elem_det_id=detGest.elem_det_id
           and  detcompcor.elem_det_id=detPrev.elem_det_id
           and  compGest.elem_det_comp_tipo_id=detcompCor.elem_det_comp_tipo_id
           and  tipo_comp.elem_det_comp_tipo_id=detcompCor.elem_det_comp_tipo_id
           and  detPrev.data_cancellazione is null
           and  detPrev.validita_fine is null
           and  detGest.data_cancellazione is null
           and  detGest.validita_fine is null
           and  compGest.data_cancellazione is null
           and  compGest.validita_fine is null
           and  detCompCor.data_cancellazione is null
           and  detCompCor.validita_fine is null
           and  tipo_comp.data_cancellazione is null;

          codResult:=null;
          insert into fase_bil_t_elaborazione_log
          (fase_bil_elab_id,fase_bil_elab_log_operazione,
           validita_inizio, login_operazione, ente_proprietario_id
          )
          values
          (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
          returning fase_bil_elab_log_id into codResult;

          if codResult is null then
              raise exception ' Errore in inserimento LOG.';
          end if;


          strMessaggio:='Aggiornamento importi componenti capitoli di previsione esistenti da gestione equivalenti anno precedente annoBilancio+2='
          			  ||(annoBilancio+2)::varchar
                      ||'. Aggiornamento componenti esistenti in previsione.';
          update siac_t_bil_elem_det_comp detCompCor
          set  elem_det_importo=0,
               data_modifica=now(),
               login_operazione=loginOperazione
          from fase_bil_t_prev_apertura_str_elem_prev_esiste fase,
               siac_t_bil_elem_det detPrev,
               siac_t_bil_elem_det detGest, siac_t_bil_elem_det_comp compGest,
               siac_d_bil_elem_det_comp_tipo tipo_comp
          where fase.ente_proprietario_id=enteProprietarioId
           and  fase.bil_id=bilancioId
           and  fase.fase_bil_elab_id=faseBilElabId
           and  fase.data_cancellazione is null
           and  fase.validita_fine is null
           and  fase.elem_gest_id is not null
           and  detPrev.elem_id=fase.elem_prev_id
           and  detPrev.periodo_id =periodoAnno2Id
           and  detGest.elem_id=fase.elem_gest_id
           and  detGest.periodo_id=periodoId
           and  compGest.elem_det_id=detGest.elem_det_id
           and  detcompcor.elem_det_id=detPrev.elem_det_id
           and  compGest.elem_det_comp_tipo_id=detcompCor.elem_det_comp_tipo_id
           and  tipo_comp.elem_det_comp_tipo_id=detcompCor.elem_det_comp_tipo_id
           and  detPrev.data_cancellazione is null
           and  detPrev.validita_fine is null
           and  detGest.data_cancellazione is null
           and  detGest.validita_fine is null
           and  compGest.data_cancellazione is null
           and  compGest.validita_fine is null
           and  detCompCor.data_cancellazione is null
           and  detCompCor.validita_fine is null
           and  tipo_comp.data_cancellazione is null;

          codResult:=null;
          insert into fase_bil_t_elaborazione_log
          (fase_bil_elab_id,fase_bil_elab_log_operazione,
           validita_inizio, login_operazione, ente_proprietario_id
          )
          values
          (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
          returning fase_bil_elab_log_id into codResult;

          if codResult is null then
              raise exception ' Errore in inserimento LOG.';
          end if;

          -- azzeramento comp in prev non esistenti in gest
          strMessaggio:='Aggiornamento importi componenti capitoli di previsione esistenti da gestione equivalenti anno precedente annoBilancio='
                        ||(annoBilancio)::varchar
                        ||'. Azzeramento componenti previsione non esistenti in gestione.';
          update siac_t_bil_elem_det_comp detCompCor
          set  elem_det_importo=0,
               data_modifica=now(),
               login_operazione=loginOperazione
          from fase_bil_t_prev_apertura_str_elem_prev_esiste fase,
               siac_t_bil_elem_det detPrev,
               siac_d_bil_elem_det_comp_tipo tipo_comp
          where fase.ente_proprietario_id=enteProprietarioId
           and  fase.bil_id=bilancioId
           and  fase.fase_bil_elab_id=faseBilElabId
           and  fase.data_cancellazione is null
           and  fase.validita_fine is null
           and  fase.elem_gest_id is not null
           and  detPrev.elem_id=fase.elem_prev_id
           and  detcompcor.elem_det_id=detPrev.elem_det_id
           and  tipo_comp.elem_det_comp_tipo_id=detcompCor.elem_det_comp_tipo_id
           and  not exists
           (
           select 1
           from siac_t_bil_elem_det detGest, siac_t_bil_elem_det_comp compGest
           where detGest.elem_id=fase.elem_gest_id
           and   detGest.elem_det_tipo_id=detprev.elem_det_tipo_id
           and   compGest.elem_det_id=detGest.elem_det_id
           and   compGest.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
           and   detGest.data_cancellazione is null
           and   detGest.validita_fine is null
           and   compGest.data_cancellazione is null
           and   compGest.validita_fine is null
           )
           and  detPrev.data_cancellazione is null
           and  detPrev.validita_fine is null
           and  detCompCor.data_cancellazione is null
           and  detCompCor.validita_fine is null;
           --and  tipo_comp.data_cancellazione is null;

          codResult:=null;
          insert into fase_bil_t_elaborazione_log
          (fase_bil_elab_id,fase_bil_elab_log_operazione,
           validita_inizio, login_operazione, ente_proprietario_id
          )
          values
          (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
          returning fase_bil_elab_log_id into codResult;

          if codResult is null then
              raise exception ' Errore in inserimento LOG.';
          end if;

          -- inserimento comp da gest  in prev non esistenti in prev
          strMessaggio:='Inserimento importi componenti capitoli di previsione esistenti da gestione equivalenti anno precedente annoBilancio='
                       ||(annoBilancio)::varchar
                       ||' e annoBilancio+1='||(annoBilancio+1)::varchar
                       ||'.';
          insert into siac_t_bil_elem_det_comp
          (
              elem_det_id,
              elem_det_comp_tipo_id,
              elem_det_importo,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
          )
          select
               detPrev.elem_det_id,
               tipo_comp.elem_det_comp_tipo_id,
               compGest.elem_det_importo,
               dataInizioVal,
               loginOperazione,
               fase.ente_proprietario_id
          from fase_bil_t_prev_apertura_str_elem_prev_esiste fase,
               siac_t_bil_elem_det detPrev,
               siac_d_bil_elem_det_comp_tipo tipo_comp,
               siac_t_bil_elem_det detGest,
               siac_t_bil_elem_det_comp compGest
          where fase.ente_proprietario_id=enteProprietarioId
           and  fase.bil_id=bilancioId
           and  fase.fase_bil_elab_id=faseBilElabId
           and  fase.data_cancellazione is null
           and  fase.validita_fine is null
           and  fase.elem_gest_id is not null
           and  detPrev.elem_id=fase.elem_prev_id
           and  detPrev.periodo_id in (periodoId,periodoAnno1Id)
           and  detgest.elem_id=fase.elem_gest_id
           and  detGest.periodo_id=detPrev.periodo_id
           and  detGest.elem_det_tipo_id=detPrev.elem_det_tipo_id
           and  compGest.elem_det_id=detGest.elem_det_id
           and  tipo_comp.elem_det_comp_tipo_id=compGest.elem_det_comp_tipo_id
           and  not exists
           (
           select 1
           from  siac_t_bil_elem_det_comp compPrev
           where compPrev.elem_det_id=detPrev.elem_det_id
           and   compPrev.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
           and   compPrev.data_cancellazione is null
           and   compPrev.validita_fine is null
           )
           and  detPrev.data_cancellazione is null
           and  detPrev.validita_fine is null
           and  detGest.data_cancellazione is null
           and  detGest.validita_fine is null
           and  compGest.data_cancellazione is null
           and  compGest.validita_fine is null
           and  tipo_comp.data_cancellazione is null;

          codResult:=null;
          insert into fase_bil_t_elaborazione_log
          (fase_bil_elab_id,fase_bil_elab_log_operazione,
           validita_inizio, login_operazione, ente_proprietario_id
          )
          values
          (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
          returning fase_bil_elab_log_id into codResult;

          if codResult is null then
              raise exception ' Errore in inserimento LOG.';
          end if;

          strMessaggio:='Inserimento importi componenti capitoli di previsione esistenti da gestione equivalenti anno precedente annoBilancio+2='
                       ||(annoBilancio+2)::varchar||'.';
          insert into siac_t_bil_elem_det_comp
          (
              elem_det_id,
              elem_det_comp_tipo_id,
              elem_det_importo,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
          )
          select
               detPrev.elem_det_id,
               tipo_comp.elem_det_comp_tipo_id,
               0,
               dataInizioVal,
               loginOperazione,
               fase.ente_proprietario_id
          from fase_bil_t_prev_apertura_str_elem_prev_esiste fase,
               siac_t_bil_elem_det detPrev,
               siac_d_bil_elem_det_comp_tipo tipo_comp,
               siac_t_bil_elem_det detGest,
               siac_t_bil_elem_det_comp compGest
          where fase.ente_proprietario_id=enteProprietarioId
           and  fase.bil_id=bilancioId
           and  fase.fase_bil_elab_id=faseBilElabId
           and  fase.data_cancellazione is null
           and  fase.validita_fine is null
           and  fase.elem_gest_id is not null
           and  detPrev.elem_id=fase.elem_prev_id
           and  detPrev.periodo_id=periodoAnno2Id
           and  detgest.elem_id=fase.elem_gest_id
           and  detGest.periodo_id=periodoId
           and  detGest.elem_det_tipo_id=detPrev.elem_det_tipo_id
           and  compGest.elem_det_id=detGest.elem_det_id
           and  tipo_comp.elem_det_comp_tipo_id=compGest.elem_det_comp_tipo_id
           and  not exists
           (
           select 1
           from  siac_t_bil_elem_det_comp compPrev
           where compPrev.elem_det_id=detPrev.elem_det_id
           and   compPrev.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
           and   compPrev.data_cancellazione is null
           and   compPrev.validita_fine is null
           )
           and  detPrev.data_cancellazione is null
           and  detPrev.validita_fine is null
           and  detGest.data_cancellazione is null
           and  detGest.validita_fine is null
           and  compGest.data_cancellazione is null
           and  compGest.validita_fine is null
           and  tipo_comp.data_cancellazione is null;

          codResult:=null;
          insert into fase_bil_t_elaborazione_log
          (fase_bil_elab_id,fase_bil_elab_log_operazione,
           validita_inizio, login_operazione, ente_proprietario_id
          )
          values
          (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
          returning fase_bil_elab_log_id into codResult;

          if codResult is null then
              raise exception ' Errore in inserimento LOG.';
          end if;
        enD if;
        -- 08.09.2020 Sofia - SIAC-7495 - fine

	end if;

    if elemPrevEq=true then

        strMessaggio:='Verifica esistenza elementi di bilancio di previsione equivalenti non presenti in gestione anno precedente.';

    	select  1 into prevEqEsisteNoGest
        from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null
        and   fase.elem_gest_id is null
        limit 1;
--raise notice 'prevEqEsisteNoGest=%', prevEqEsisteNoGest;

		codResult:=null;
   	    insert into fase_bil_t_elaborazione_log
        (fase_bil_elab_id,fase_bil_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
        values
        (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
        returning fase_bil_elab_log_id into codResult;

        if codResult is null then
        	raise exception ' Errore in inserimento LOG.';
        end if;

		if prevEqEsisteNoGest is not null then
        -- inserire backup
        strMessaggio:='Inserimento  backup importi  capitoli di previsione esistenti senza gestione equivalente anno precedente.';
        insert into bck_fase_bil_t_prev_apertura_bil_elem_det
         (elem_bck_id,
		  elem_bck_det_id,
		  elem_bck_det_importo,
		  elem_bck_det_flag,
		  elem_bck_det_tipo_id,
		  elem_bck_periodo_id,
		  elem_bck_data_creazione,
		  elem_bck_data_modifica,
		  elem_bck_login_operazione,
	      elem_bck_validita_inizio,
		  elem_bck_validita_fine,
	      fase_bil_elab_id,
		  validita_inizio,
          login_operazione,
          ente_proprietario_id
          )
          (select det.elem_id, det.elem_det_id, det.elem_det_importo,det.elem_det_flag,det.elem_det_tipo_id,
                  det.periodo_id,det.data_creazione,det.data_modifica,det.login_operazione,det.validita_inizio,
                  det.validita_fine, fase.fase_bil_elab_id,now(),loginOperazione,fase.ente_proprietario_id
           from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det
           where fase.ente_proprietario_id=enteProprietarioId
	       and   fase.bil_id=bilancioId
    	   and   fase.fase_bil_elab_id=faseBilElabId
    	   and   fase.data_cancellazione is null
	       and   fase.validita_fine is null
		   and   fase.elem_gest_id is null
           and   det.elem_id=fase.elem_prev_id
	       and   det.data_cancellazione is null
     	   and   det.validita_fine is null
          );

          codResult:=null;
          strmessaggio:=strMessaggio||' Verifica inserimento.';
          select 1  into codResult
          from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det
          where fase.ente_proprietario_id=enteProprietarioId
	      and   fase.bil_id=bilancioId
    	  and   fase.fase_bil_elab_id=faseBilElabId
    	  and   fase.data_cancellazione is null
	      and   fase.validita_fine is null
		  and   fase.elem_gest_id is null
          and   det.elem_id=fase.elem_prev_id
	      and   det.data_cancellazione is null
     	  and   det.validita_fine is null
          and   not exists (select 1 from bck_fase_bil_t_prev_apertura_bil_elem_det bck
                             where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                             and   bck.elem_bck_id=det.elem_id
                             and   bck.data_cancellazione is null
                             and   bck.validita_fine is null);

           if codResult is not null then raise exception ' Elementi senza backup importi.'; end if;

           strMessaggio:='Aggiornamento importi a zero per capitoli di previsione esistenti senza gestione equivalente anno precedente.';
           update siac_t_bil_elem_det detCor
           set elem_det_importo=0,
               data_modifica=now(),
               login_operazione=loginOperazione
           from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
           where fase.ente_proprietario_id=enteProprietarioId
 	       and   fase.bil_id=bilancioId
     	   and   fase.fase_bil_elab_id=faseBilElabId
    	   and   fase.data_cancellazione is null
	       and   fase.validita_fine is null
		   and   fase.elem_gest_id is null
           and   detCor.elem_id=fase.elem_prev_id
	       and   detCor.data_cancellazione is null
     	   and   detCor.validita_fine is null;

         -- sostituire con update
   	     /* 07.07.2016 Sofia - sostituito con bck e update sopra
         strMessaggio:='Inserimento importi a zero per capitoli di previsione esistenti senza gestione equivalente anno precedente.';
  	     insert into siac_t_bil_elem_det
	     (elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
    	  validita_inizio, ente_proprietario_id, login_operazione)
	     (select fase.elem_prev_id, 0,
   		         det.elem_det_tipo_id,
	             det.periodo_id,
    	         dataInizioVal,det.ente_proprietario_id,loginOperazione
	      from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det
    	  where fase.ente_proprietario_id=enteProprietarioId
          and   fase.bil_id=bilancioId
          and   fase.fase_bil_elab_id=faseBilElabId
    	  and   fase.data_cancellazione is null
          and   fase.validita_fine is null
	      and   fase.elem_gest_id is null
    	  and   det.elem_id=fase.elem_prev_id
	      and   det.data_cancellazione is null
    	  and   det.validita_fine is null
	     ); */

		 codResult:=null;
   	     insert into fase_bil_t_elaborazione_log
         (fase_bil_elab_id,fase_bil_elab_log_operazione,
          validita_inizio, login_operazione, ente_proprietario_id
         )
         values
         (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
         returning fase_bil_elab_log_id into codResult;

         if codResult is null then
        	raise exception ' Errore in inserimento LOG.';
         end if;

		-- commentare tutte queste update
	    /*  07.07.2016 Sofia sostituito con back e update sopra
         strMessaggio:='Cancellazione logica importi capitoli di previsione esistenti senza gestione equivalente anno precedente.';

    	 update siac_t_bil_elem_det det
	      set data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
    	 from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
	     where  fase.ente_proprietario_id=enteProprietarioId
         and    fase.bil_id=bilancioId
         and    fase.fase_bil_elab_id=faseBilElabId
    	 and    fase.data_cancellazione is null
         and    fase.validita_fine is null
	     and    fase.elem_gest_id is null
         and    det.elem_id=fase.elem_prev_id
         and    det.data_cancellazione is null
         and    dataElaborazione>det.validita_inizio -- date_trunc('DAY',det.validita_inizio) -- solo > per escludere quelli appena inseriti
         and    det.validita_fine is null;

		 codResult:=null;
   	     insert into fase_bil_t_elaborazione_log
         (fase_bil_elab_id,fase_bil_elab_log_operazione,
          validita_inizio, login_operazione, ente_proprietario_id
         )
         values
         (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
         returning fase_bil_elab_log_id into codResult;

         if codResult is null then
        	raise exception ' Errore in inserimento LOG.';
         end if; */

         --- controllo inserimento importi prec
         /* 07.07.2016 Sofia non serve non sono inseriti ma aggiornati
         codResult:=null;
	     strMessaggio:='Inserimento importi a zero per capitoli di previsione esistenti senza gestione equivalente anno precedente.Verifica inserimento.';


    	 select  1  into codResult
	     from siac_t_bil_elem_det det , fase_bil_t_prev_apertura_str_elem_prev_esiste fase
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
	     and   fase.elem_gest_id is null
    	 and   det.elem_id=fase.elem_prev_id
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
         limit 1;

	     if codResult is null then
    		raise exception ' Non effettuato.';
	     end if;

         codResult:=null;
   	     insert into fase_bil_t_elaborazione_log
         (fase_bil_elab_id,fase_bil_elab_log_operazione,
          validita_inizio, login_operazione, ente_proprietario_id
         )
         values
         (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
         returning fase_bil_elab_log_id into codResult;

         if codResult is null then
        	raise exception ' Errore in inserimento LOG.';
         end if; */

        -- 09.09.2020 Sofia SIAC-7495 - inizio
        if bilElemPrevTipo=CAP_UP_ST then
          -- inserire backup
          strMessaggio:='Inserimento  backup importi componenti capitoli di previsione esistenti senza gestione equivalente anno precedente.';
          insert into bck_fase_bil_t_prev_apertura_bil_elem_det_comp
          (
            elem_bck_det_comp_id,
            elem_bck_det_id,
            elem_bck_det_comp_tipo_id,
            elem_bck_det_importo,
            elem_bck_data_creazione,
            elem_bck_data_modifica,
            elem_bck_login_operazione,
            elem_bck_validita_inizio,
            elem_bck_validita_fine,
            fase_bil_elab_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
           )
           (select  comp.elem_det_comp_id,
                    comp.elem_det_id,
                    comp.elem_det_comp_tipo_id,
                    comp.elem_det_importo,
                    comp.data_creazione,comp.data_modifica,comp.login_operazione,comp.validita_inizio,
                    comp.validita_fine, fase.fase_bil_elab_id,clock_timestamp(),loginOperazione,fase.ente_proprietario_id
            from fase_bil_t_prev_apertura_str_elem_prev_esiste fase,
                 siac_t_bil_elem_det det,siac_t_bil_elem_det_comp comp
            where fase.ente_proprietario_id=enteProprietarioId
            and   fase.bil_id=bilancioId
            and   fase.fase_bil_elab_id=faseBilElabId
            and   fase.data_cancellazione is null
            and   fase.validita_fine is null
            and   fase.elem_gest_id is null
            and   det.elem_id=fase.elem_prev_id
            and   comp.elem_det_id=det.elem_det_id
            and   det.data_cancellazione is null
            and   det.validita_fine is null
            and   comp.data_cancellazione is null
            and   comp.validita_fine is null
           );

           codResult:=null;
           strmessaggio:=strMessaggio||' Verifica inserimento.';
           select 1  into codResult
           from fase_bil_t_prev_apertura_str_elem_prev_esiste fase,
                siac_t_bil_elem_det det,siac_t_bil_elem_det_comp comp
           where fase.ente_proprietario_id=enteProprietarioId
           and   fase.bil_id=bilancioId
           and   fase.fase_bil_elab_id=faseBilElabId
           and   fase.data_cancellazione is null
           and   fase.validita_fine is null
           and   fase.elem_gest_id is null
           and   det.elem_id=fase.elem_prev_id
           and   comp.elem_det_id=det.elem_det_id
           and   det.data_cancellazione is null
           and   det.validita_fine is null
           and   comp.data_cancellazione is null
           and   comp.validita_fine is null
           and   not exists (select 1 from bck_fase_bil_t_prev_apertura_bil_elem_det_comp bck
                              where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                              and   bck.elem_bck_det_comp_id=comp.elem_det_comp_id
                              and   bck.data_cancellazione is null
                              and   bck.validita_fine is null);

           if codResult is not null then raise exception ' Elementi senza backup importi.'; end if;


           strMessaggio:='Aggiornamento importi componenti a zero per capitoli di previsione esistenti senza gestione equivalente anno precedente.';
           update siac_t_bil_elem_det_comp detCompCor
           set elem_det_importo=0,
               data_modifica=now(),
               login_operazione=loginOperazione
           from fase_bil_t_prev_apertura_str_elem_prev_esiste fase,
                siac_t_bil_elem_det det
           where fase.ente_proprietario_id=enteProprietarioId
           and   fase.bil_id=bilancioId
           and   fase.fase_bil_elab_id=faseBilElabId
           and   fase.data_cancellazione is null
           and   fase.validita_fine is null
           and   fase.elem_gest_id is null
           and   det.elem_id=fase.elem_prev_id
           and   detCompCor.elem_det_id=det.elem_det_id
           and   detCompCor.data_cancellazione is null
           and   detCompCor.validita_fine is null;


           codResult:=null;
           insert into fase_bil_t_elaborazione_log
           (fase_bil_elab_id,fase_bil_elab_log_operazione,
            validita_inizio, login_operazione, ente_proprietario_id
           )
           values
           (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
           returning fase_bil_elab_log_id into codResult;

           if codResult is null then
              raise exception ' Errore in inserimento LOG.';
           end if;
         end if;
         -- 09.09.2020 Sofia SIAC-7495 - fine
       end if;
    end if;


   -- SIAC-7495 Sofia 05.10.2020 - inizio
   if bilElemPrevTipo=CAP_UP_ST then

       strMessaggio:='Aggiornamento importi componenti a zero per capitoli di previsione nuovi : '
                  ||' cancellazione logica componenti a zero non utilizzate.';
    update siac_t_bil_elem_det_comp detCompCor
    set --elem_det_importo=0,
        data_cancellazione=clock_timestamp(),
        login_operazione=loginOperazione||'-CANC-COMP-ZERO'
    from  fase_bil_t_prev_apertura_str_elem_prev_nuovo fase,
          siac_t_bil_elem_det det ,siac_t_periodo per,
          siac_d_bil_elem_det_comp_tipo tipo,
          (
          select tipo.elem_tipo_code,e.elem_code::integer,
                 e.elem_id,
                 tipo_comp.elem_det_comp_tipo_id,
                 tipo_comp.elem_det_comp_tipo_desc,
                 sum(comp.elem_det_importo)
          from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
               siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
               siac_d_bil_elem_det_comp_tipo tipo_comp,siac_t_periodo per
          where tipo.ente_proprietario_id=enteProprietarioId
          and   tipo.elem_tipo_code=CAP_UP_ST
          and   e.elem_tipo_id=tipo.elem_tipo_id
          and   e.bil_id=bilancioId
          and   det.elem_id=e.elem_id
          and   comp.elem_det_id=det.elem_det_id
          and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
          and   per.periodo_id=det.periodo_id
          and not exists
          (
          select 1
          from siac_t_bil_elem_det_comp comp_comp,
               siac_t_bil_elem_det_var_comp dvar_comp,siac_t_bil_elem_det_var dvar
          where comp_comp.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
          and   dvar_comp.elem_det_comp_id=comp_comp.elem_det_comp_id
          and   dvar.elem_det_var_id=dvar_comp.elem_det_var_id
          and   dvar.elem_id=e.elem_id
          and   comp_comp.data_cancellazione is null
          and   dvar_comp.data_cancellazione is null
          and   dvar.data_cancellazione is null
          )
          /* 09.10.2020 Sofia da scommentare con rilascio della SIAC-7349
		  and not exists
          (
          select 1
          from siac_r_movgest_bil_elem re
          where  re.elem_id=e.elem_id
          and    re.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
          and    re.data_cancellazione is null
          )*/
          and   e.data_cancellazione is null
          and   det.data_cancellazione is null
          and   det.validita_fine is null
          and   comp.data_cancellazione is null
          and   comp.validita_fine is null
          and   tipo_comp.data_cancellazione is null
          group by tipo.elem_tipo_code,e.elem_code::integer,
                   e.elem_id,
                   tipo_comp.elem_det_comp_tipo_id,
                   tipo_comp.elem_det_comp_tipo_desc
          having sum(comp.elem_det_importo)=0
          order by 1,2,3
          ) query
    where fase.ente_proprietario_id=enteProprietarioId
    and   fase.bil_id=bilancioId
    and   fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   det.elem_id=fase.elem_prev_id
    and   detCompCor.elem_Det_id=det.elem_det_id
    and   tipo.elem_Det_comp_tipo_id=detCompCor.elem_det_comp_tipo_id
    and   per.periodo_id=det.periodo_id
    and   query.elem_id=det.elem_id
    and   query.elem_det_comp_tipo_id=tipo.elem_Det_comp_tipo_id
    and   det.data_cancellazione is null
    and   detCompCor.data_cancellazione is null;


    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
    validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
      raise exception ' Errore in inserimento LOG.';
    end if;

    strMessaggio:='Aggiornamento importi componenti a zero per capitoli di previsione esistenti : '
                  ||' cancellazione logica componenti a zero non utilizzate.';
    update siac_t_bil_elem_det_comp detCompCor
    set --elem_det_importo=0,
        data_cancellazione=clock_timestamp(),
        login_operazione=loginOperazione||'-CANC-COMP-ZERO'
    from  fase_bil_t_prev_apertura_str_elem_prev_esiste fase,
          siac_t_bil_elem_det det ,siac_t_periodo per,
          siac_d_bil_elem_det_comp_tipo tipo,
          (
          select tipo.elem_tipo_code,e.elem_code::integer,
                 e.elem_id,
                 tipo_comp.elem_det_comp_tipo_id,
                 tipo_comp.elem_det_comp_tipo_desc,
                 sum(comp.elem_det_importo)
          from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
               siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
               siac_d_bil_elem_det_comp_tipo tipo_comp,siac_t_periodo per
          where tipo.ente_proprietario_id=enteProprietarioId
          and   tipo.elem_tipo_code=CAP_UP_ST
          and   e.elem_tipo_id=tipo.elem_tipo_id
          and   e.bil_id=bilancioId
          and   det.elem_id=e.elem_id
          and   comp.elem_det_id=det.elem_det_id
          and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
          and   per.periodo_id=det.periodo_id
          and not exists
          (
          select 1
          from siac_t_bil_elem_det_comp comp_comp,
               siac_t_bil_elem_det_var_comp dvar_comp,siac_t_bil_elem_det_var dvar
          where comp_comp.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
          and   dvar_comp.elem_det_comp_id=comp_comp.elem_det_comp_id
          and   dvar.elem_det_var_id=dvar_comp.elem_det_var_id
          and   dvar.elem_id=e.elem_id
          and   comp_comp.data_cancellazione is null
          and   dvar_comp.data_cancellazione is null
          and   dvar.data_cancellazione is null
          )
          /* 09.10.2020 Sofia da scommentare con rilascio della SIAC-7349
		  and not exists
          (
          select 1
          from siac_r_movgest_bil_elem re
          where  re.elem_id=e.elem_id
          and    re.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
          and    re.data_cancellazione is null
          )*/
          and   e.data_cancellazione is null
          and   det.data_cancellazione is null
          and   det.validita_fine is null
          and   comp.data_cancellazione is null
          and   comp.validita_fine is null
          and   tipo_comp.data_cancellazione is null
          group by tipo.elem_tipo_code,e.elem_code::integer,
                   e.elem_id,
                   tipo_comp.elem_det_comp_tipo_id,
                   tipo_comp.elem_det_comp_tipo_desc
          having sum(comp.elem_det_importo)=0
          order by 1,2,3
          ) query
    where fase.ente_proprietario_id=enteProprietarioId
    and   fase.bil_id=bilancioId
    and   fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   det.elem_id=fase.elem_prev_id
    and   detCompCor.elem_Det_id=det.elem_det_id
    and   tipo.elem_Det_comp_tipo_id=detCompCor.elem_det_comp_tipo_id
    and   per.periodo_id=det.periodo_id
    and   query.elem_id=det.elem_id
    and   query.elem_det_comp_tipo_id=tipo.elem_Det_comp_tipo_id
    and   det.data_cancellazione is null
    and   detCompCor.data_cancellazione is null;


    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
    validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
      raise exception ' Errore in inserimento LOG.';
    end if;

   end if;


   strMessaggio:='Aggiornamento elaborazione faseBilElabId='||faseBilElabId||' per conclusione OK.';
    update fase_bil_t_elaborazione set
       fase_bil_elab_esito='OK',
       fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_PREV_DA_GEST||' TERMINATA : AGGIORNAMENTO IMPORTI COMPLETATO.'
    where fase_bil_elab_id=faseBilElabId;

	codResult:=null;
   	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
       	raise exception ' Errore in inserimento LOG.';
    end if;

    messaggioRisultato:=strMessaggioFinale||'OK .';
    return;


exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter function siac.fnc_fasi_bil_prev_apertura_importi
(
   integer,
   varchar,
   varchar,
   varchar,
   boolean, 
   boolean, 
   integer, 
   integer,
   varchar,
   timestamp, 
   out  integer,
   out  varchar
) owner to siac;