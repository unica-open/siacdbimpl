/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 07.07.2016 Sofia - salvato versione senza ultime modifiche backup
--- 07.04.2016 Sofia - predisposizione bilancio di previsione da gestione precedente
-- bilancio gestione annoBilancio-1
-- importo previsione annoBilancio  = importo gestione annoBilancio,   del bilancio annoBilancio-1
-- importo previsione annoBilancio+1= importo gestione annoBilancio+1, del bilancio annoBilancio-1
-- importo previsione annoBilancio+2= 0

CREATE OR REPLACE FUNCTION fnc_fasi_bil_prev_apertura_importi
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

	prevEqEsiste      integer:=null;
    prevEqApri     integer:=null;
    prevEqEsisteNoGest  integer:=null;
    codResult         integer:=null;
	dataInizioVal     timestamp:=null;

    bilancioId        integer:=null;

    periodoId        integer:=null;
    periodoAnno1Id   integer:=null;
    periodoAnno2Id   integer:=null;




BEGIN

	messaggioRisultato:='';
    codiceRisultato:=0;

    dataInizioVal:=clock_timestamp();-- usato al posto di now() per essere certi di riconoscere i record inseriti dopo la chiamata della funzione;

	strMessaggioFinale:='Apertura bilancio di previsione.Aggiornamento importi Previsione '||bilElemPrevTipo||' da Gestione anno precedente'||bilElemGEstTipo||
    					'.Anno bilancio='||annoBilancio::varchar||'.';


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
          end if;

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
      from fase_bil_t_prev_apertura_str_elem_prev_nuovo fase, siac_t_bil_elem_det det
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   det.elem_id=fase.elem_id
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
    end if;

--	raise notice 'elemPrevEq=% prevEqEsiste=%', elemPrevEq,prevEqEsiste;
	if elemPrevEq=true and prevEqEsiste is not null then
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
	    );

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
        end if;

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
         end if;
         --- controllo inserimento importi prec
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
         end if;
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