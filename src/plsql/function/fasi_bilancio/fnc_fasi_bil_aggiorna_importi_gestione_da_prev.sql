/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 01.02.2016 Sofia -- verificare se inserire tab log
CREATE OR REPLACE FUNCTION fnc_fasi_bil_prev_approva_importi
(
  annobilancio    integer,
  euElemTipo      varchar,
  bilElemPrevTipo varchar,
  bilElemGestTipo varchar,
  elemGestEq      boolean, -- trattamento capitoli di gestione equivalenti esistenti
  importiPrev     boolean, -- impostazione importi di previsione su gestione
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

	APPROVA_PREV_SU_GEST CONSTANT varchar:='APROVA_PREV';

    STI_DET_TIPO     CONSTANT varchar:='STI';
    SRI_DET_TIPO     CONSTANT varchar:='SRI';
    SCI_DET_TIPO     CONSTANT varchar:='SCI';

    STA_DET_TIPO     CONSTANT varchar:='STA';
    STR_DET_TIPO     CONSTANT varchar:='STR';
    SCA_DET_TIPO     CONSTANT varchar:='SCA';

	gestEqEsiste      integer:=null;
    prevEqApprova     integer:=null;
    gestEqEsisteNoPrev  integer:=null;
    codResult         integer:=null;
	dataInizioVal     timestamp:=null;
    bilancioId        integer:=null;

    detTipoStaId     integer:=null;
    detTipoScaId     integer:=null;
    detTipoStrId     integer:=null;

    detTipoStiId     integer:=null;
    detTipoSciId     integer:=null;
    detTipoSriId     integer:=null;

BEGIN

	messaggioRisultato:='';
    codiceRisultato:=0;

   -- dataInizioVal:=date_trunc('DAY', now());
    dataInizioVal:=clock_timestamp();-- usato al posto di now() per essere certi di riconoscere i record inseriti dopo la chiamata della funzione;

	strMessaggioFinale:='Approvazione bilancio di previsione.Aggiornamento importi Gestione '||bilElemGestTipo||' da Previsione '||bilElemPrevTipo||
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
    select bil.bil_id into strict bilancioId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio
    order by bil.bil_id limit 1;
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


    -- cancellazione logica importi di gestione equivalente esistente
    if elemGestEq=true then
        strMessaggio:='Verifica esistenza elementi di bilancio di gestione equivalenti da aggiornare da previsione.';

    	select distinct 1 into gestEqEsiste
        from fase_bil_t_prev_approva_str_elem_gest_esiste fase
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null
        and   fase.elem_prev_id is not null
--        order by fase.fase_bil_prev_str_esiste_id
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

        if gestEqEsiste is not null then
         -- al posto di update inserire backup

	  /*   strMessaggio:='Cancellazione logica importi capitoli di gestione equivalenti esistenti.';
    	 update siac_t_bil_elem_det det
	      set data_cancellazione=now(), validita_inizio=now(), login_operazione=loginOperazione
    	 from fase_bil_t_prev_approva_str_elem_gest_esiste fase
	     where  fase.ente_proprietario_id=enteProprietarioId
         and    fase.bil_id=bilancioId
         and    fase.fase_bil_elab_id=faseBilElabId
    	 and    fase.data_cancellazione is null
         and    fase.validita_fine is null
	     and    fase.elem_prev_id is not null
         and    det.elem_id=fase.elem_gest_id
         and    det.data_cancellazione is null
         and    det.validita_fine is null; */

         strMessaggio:='Inserimento backup importi capitoli di gestione equivalenti esistenti.';
         insert into bck_fase_bil_t_prev_approva_bil_elem_det
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
           from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem_det det
           where fase.ente_proprietario_id=enteProprietarioId
	       and   fase.bil_id=bilancioId
    	   and   fase.fase_bil_elab_id=faseBilElabId
    	   and   fase.data_cancellazione is null
	       and   fase.validita_fine is null
		   and   fase.elem_prev_id is not null
           and   det.elem_id=fase.elem_gest_id
	       and   det.data_cancellazione is null
     	   and   det.validita_fine is null
          );

          codResult:=null;
          strmessaggio:=strMessaggio||' Verifica inserimento.';
          select 1  into codResult
          from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem_det det
          where fase.ente_proprietario_id=enteProprietarioId
	       and   fase.bil_id=bilancioId
    	   and   fase.fase_bil_elab_id=faseBilElabId
    	   and   fase.data_cancellazione is null
	       and   fase.validita_fine is null
		   and   fase.elem_prev_id is not null
           and   det.elem_id=fase.elem_gest_id
	       and   det.data_cancellazione is null
     	   and   det.validita_fine is null
           and   not exists (select 1 from bck_fase_bil_t_prev_approva_bil_elem_det bck
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

       end if;
    end if;

    strMessaggio:='Verifica esistenza elementi di bilancio di previsione equivalenti da approvare.';

	select distinct 1 into prevEqApprova
    from fase_bil_t_prev_approva_str_elem_gest_nuovo fase
    where fase.ente_proprietario_id=enteProprietarioId
    and   fase.bil_id=bilancioId
    and   fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
--    order by fase.fase_bil_prev_str_nuovo_id
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

    if prevEqApprova is not null then
     strMessaggio:='Inserimento  importi capitoli di previsione su gestione equivalenti non esistenti.';
     --- inserimento nuovi importi
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
      validita_inizio, ente_proprietario_id, login_operazione)
     (select fase.elem_gest_id,
            (case when importiPrev=true then det.elem_det_importo
    			  else 0 END),
            det.elem_det_tipo_id,
            det.periodo_id,
            dataInizioVal,det.ente_proprietario_id,loginOperazione
      from fase_bil_t_prev_approva_str_elem_gest_nuovo fase, siac_t_bil_elem_det det
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   det.elem_id=fase.elem_id
      and   det.elem_det_tipo_id not in (detTipoStiId,detTipoSriId,detTipoSciId) -- escluso iniziali gestiti di seguito
      and   det.data_cancellazione is null
      and   det.validita_fine is null
     );

     strMessaggio:='Inserimento  importi attuali capitoli di previsione su gestione iniziale  equivalenti non esistenti.';
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
      validita_inizio, ente_proprietario_id, login_operazione)
     (select fase.elem_gest_id,
            (case when importiPrev=true then det.elem_det_importo
    			  else 0 END),
            (case when det.elem_det_tipo_id=detTipoStaId then detTipoStiId
                  when det.elem_det_tipo_id=detTipoScaId then detTipoSciId
                  when det.elem_det_tipo_id=detTipoStrId then detTipoSriId end), -- attuali in iniziali
            det.periodo_id,
            dataInizioVal,det.ente_proprietario_id,loginOperazione
      from fase_bil_t_prev_approva_str_elem_gest_nuovo fase, siac_t_bil_elem_det det
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   det.elem_id=fase.elem_id
      and   det.elem_det_tipo_id in (detTipoStaId,detTipoStrId,detTipoScaId) -- attuali
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
     strMessaggio:='Inserimento  importi capitoli di previsione su gestione equivalenti non esistenti.Verifica inserimento.';
     select 1  into codResult
     from siac_t_bil_elem_det det , fase_bil_t_prev_approva_str_elem_gest_nuovo fase
     where fase.ente_proprietario_id=enteProprietarioId
     and   fase.bil_id=bilancioId
     and   fase.fase_bil_elab_id=faseBilElabId
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null
     and   det.elem_id=fase.elem_gest_id
     and   det.data_cancellazione is null
     and   det.validita_fine is null
--     order by fase.fase_bil_prev_str_nuovo_id
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

--	raise notice 'elemGestEq=% gestEqEsiste=%', elemGestEq,gestEqEsiste;
	if elemGestEq=true and gestEqEsiste is not null then
        -- sostituire insert con update
/*	    strMessaggio:='Inserimento importi capitoli di previsione su gestione equivalenti esistenti.';
    	--- inserimento nuovi importi
	    insert into siac_t_bil_elem_det
    	(elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
	     validita_inizio, ente_proprietario_id, login_operazione)
    	(select fase.elem_gest_id,
            (case when importiPrev=true then det.elem_det_importo
    			  else 0 END),
            det.elem_det_tipo_id,
            det.periodo_id,
            dataInizioVal,det.ente_proprietario_id,loginOperazione
	     from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem_det det
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
	     and   fase.elem_prev_id is not null
    	 and   det.elem_id=fase.elem_prev_id
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
	    ); */

        strMessaggio:='Aggiornamento importi capitoli di previsione su gestione equivalenti esistenti.';
		update siac_t_bil_elem_det detCor
        set elem_det_importo=det.elem_det_importo,
            elem_det_flag=det.elem_det_flag,
            data_modifica=now(),
            login_operazione=loginOperazione
        from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem_det det
     	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
	    and   fase.data_cancellazione is null
    	and   fase.validita_fine is null
	    and   fase.elem_prev_id is not null
    	and   det.elem_id=fase.elem_prev_id
        and   det.elem_det_tipo_id not in (detTipoStiId,detTipoSriId,detTipoSciId) -- escluso iniziali gestiti di seguito
        and   detCor.elem_id=fase.elem_gest_id
        and   detCor.elem_det_tipo_id=det.elem_det_tipo_id
        and   detCor.periodo_id=det.periodo_id
	    and   det.data_cancellazione is null
    	and   det.validita_fine is null
	    and   detCor.data_cancellazione is null
    	and   detCor.validita_fine is null;

		strMessaggio:='Aggiornamento importi competenza attuale capitoli di previsione  su gestione equivalenti esistenti competenza iniziale.';
		update siac_t_bil_elem_det detCor
        set elem_det_importo=det.elem_det_importo,
            elem_det_flag=det.elem_det_flag,
            data_modifica=now(),
            login_operazione=loginOperazione
        from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem_det det
     	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
	    and   fase.data_cancellazione is null
    	and   fase.validita_fine is null
	    and   fase.elem_prev_id is not null
    	and   det.elem_id=fase.elem_prev_id
        and   det.elem_det_tipo_id=detTipoStaId -- attuale
        and   detCor.elem_id=fase.elem_gest_id
        and   detCor.elem_det_tipo_id=detTipoStiId -- iniziale
        and   detCor.periodo_id=det.periodo_id
	    and   det.data_cancellazione is null
    	and   det.validita_fine is null
	    and   detCor.data_cancellazione is null
    	and   detCor.validita_fine is null;

		strMessaggio:='Aggiornamento importi cassa attuale capitoli di previsione  su gestione equivalenti esistenti cassa iniziale.';
		update siac_t_bil_elem_det detCor
        set elem_det_importo=det.elem_det_importo,
            elem_det_flag=det.elem_det_flag,
            data_modifica=now(),
            login_operazione=loginOperazione
        from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem_det det
     	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
	    and   fase.data_cancellazione is null
    	and   fase.validita_fine is null
	    and   fase.elem_prev_id is not null
    	and   det.elem_id=fase.elem_prev_id
        and   det.elem_det_tipo_id=detTipoScaId -- attuale
        and   detCor.elem_id=fase.elem_gest_id
        and   detCor.elem_det_tipo_id=detTipoSciId -- iniziale
        and   detCor.periodo_id=det.periodo_id
	    and   det.data_cancellazione is null
    	and   det.validita_fine is null
	    and   detCor.data_cancellazione is null
    	and   detCor.validita_fine is null;

		strMessaggio:='Aggiornamento importi residui attuale capitoli di previsione  su gestione equivalenti esistenti residui iniziale.';
		update siac_t_bil_elem_det detCor
        set elem_det_importo=det.elem_det_importo,
            elem_det_flag=det.elem_det_flag,
            data_modifica=now(),
            login_operazione=loginOperazione
        from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem_det det
     	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
	    and   fase.data_cancellazione is null
    	and   fase.validita_fine is null
	    and   fase.elem_prev_id is not null
    	and   det.elem_id=fase.elem_prev_id
        and   det.elem_det_tipo_id=detTipoStrId -- attuale
        and   detCor.elem_id=fase.elem_gest_id
        and   detCor.elem_det_tipo_id=detTipoSriId -- iniziale
        and   detCor.periodo_id=det.periodo_id
	    and   det.data_cancellazione is null
    	and   det.validita_fine is null
	    and   detCor.data_cancellazione is null
    	and   detCor.validita_fine is null;


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
/*	    commentato perche si fa update e non insert
        codResult:=null;
    	strMessaggio:='Inserimento importi capitoli di previsione su gestione equivalenti esistenti.Verifica inserimento.';
	    select 1  into codResult
    	from siac_t_bil_elem_det det , fase_bil_t_prev_approva_str_elem_gest_esiste fase
	    where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
    	and   fase.data_cancellazione is null
	    and   fase.validita_fine is null
    	and   fase.elem_prev_id is not null
	    and   det.elem_id=fase.elem_gest_id
    	and   det.data_cancellazione is null
	    and   det.validita_fine is null
--        order by fase.fase_bil_prev_str_esiste_id
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

	end if;

    if elemGestEq=true then

        strMessaggio:='Verifica esistenza elementi di bilancio di gestione equivalenti non presenti in previsione da aggiornare.';

    	select  1 into gestEqEsisteNoPrev
        from fase_bil_t_prev_approva_str_elem_gest_esiste fase
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null
        and   fase.elem_prev_id is null
--        order by fase.fase_bil_prev_str_esiste_id
        limit 1;
--raise notice 'gestEqEsisteNoPrev=%', gestEqEsisteNoPrev;

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

		if gestEqEsisteNoPrev is not null then
         --sostituire insert con backup e update
/*   	     strMessaggio:='Inserimento importi a zero per capitoli di gestione esistenti senza previsione equivalente.';
  	     insert into siac_t_bil_elem_det
	     (elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
    	  validita_inizio, ente_proprietario_id, login_operazione)
	     (select fase.elem_gest_id, 0,
   		        det.elem_det_tipo_id,
	            det.periodo_id,
    	        dataInizioVal,det.ente_proprietario_id,loginOperazione
	      from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem_det det
    	  where fase.ente_proprietario_id=enteProprietarioId
          and   fase.bil_id=bilancioId
          and   fase.fase_bil_elab_id=faseBilElabId
    	  and   fase.data_cancellazione is null
          and   fase.validita_fine is null
	      and   fase.elem_prev_id is null
    	  and   det.elem_id=fase.elem_gest_id
	      and   det.data_cancellazione is null
    	  and   det.validita_fine is null
	     );*/

         strMessaggio:='Inserimento backup importi per capitoli di gestione esistenti senza previsione equivalente.';
		 insert into bck_fase_bil_t_prev_approva_bil_elem_det
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
           from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem_det det
           where fase.ente_proprietario_id=enteProprietarioId
           and   fase.bil_id=bilancioId
           and   fase.fase_bil_elab_id=faseBilElabId
    	   and   fase.data_cancellazione is null
           and   fase.validita_fine is null
	       and   fase.elem_prev_id is null
    	   and   det.elem_id=fase.elem_gest_id
	       and   det.data_cancellazione is null
    	   and   det.validita_fine is null
          );

          strMessaggio:='Aggiornamento importi a zero per capitoli di gestione esistenti senza previsione equivalente.';
          update siac_t_bil_elem_det detCor
          set   elem_det_importo=0,
                data_modifica=now(),
                login_operazione=loginOperazione
          from fase_bil_t_prev_approva_str_elem_gest_esiste fase
    	  where fase.ente_proprietario_id=enteProprietarioId
          and   fase.bil_id=bilancioId
          and   fase.fase_bil_elab_id=faseBilElabId
    	  and   fase.data_cancellazione is null
          and   fase.validita_fine is null
	      and   fase.elem_prev_id is null
    	  and   detCor.elem_id=fase.elem_gest_id
	      and   detCor.data_cancellazione is null
    	  and   detCor.validita_fine is null;


          codResult:=null;
          strmessaggio:=strMessaggio||' Verifica inserimento.';
          select 1  into codResult
          from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem_det det
          where fase.ente_proprietario_id=enteProprietarioId
	       and   fase.bil_id=bilancioId
    	   and   fase.fase_bil_elab_id=faseBilElabId
    	   and   fase.data_cancellazione is null
	       and   fase.validita_fine is null
		   and   fase.elem_prev_id is null
           and   det.elem_id=fase.elem_gest_id
	       and   det.data_cancellazione is null
     	   and   det.validita_fine is null
           and   not exists (select 1 from bck_fase_bil_t_prev_approva_bil_elem_det bck
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

         -- commentare update --
	     /*strMessaggio:='Cancellazione logica importi capitoli di gestione esistenti senza previsione equivalente.';

    	 update siac_t_bil_elem_det det
	      set data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
    	 from fase_bil_t_prev_approva_str_elem_gest_esiste fase
	     where  fase.ente_proprietario_id=enteProprietarioId
         and    fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
    	 and    fase.data_cancellazione is null
         and    fase.validita_fine is null
	     and    fase.elem_prev_id is null
         and    det.elem_id=fase.elem_gest_id
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
	     strMessaggio:='Inserimento importi a zero per capitoli di gestione esistenti senza previsione equivalente.Verifica inserimento.';


    	 select  1  into codResult
	     from siac_t_bil_elem_det det , fase_bil_t_prev_approva_str_elem_gest_esiste fase
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
	     and   fase.elem_prev_id is null
    	 and   det.elem_id=fase.elem_gest_id
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
--         order by fase.fase_bil_prev_str_esiste_id
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
       end if;
    end if;

   strMessaggio:='Aggiornamento elaborazione faseBilElabId='||faseBilElabId||' per conclusione OK.';
    update fase_bil_t_elaborazione set
       fase_bil_elab_esito='OK',
       fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APPROVA_PREV_SU_GEST||' TERMINATA : AGGIORNAMENTO IMPORTI COMPLETATO.'
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