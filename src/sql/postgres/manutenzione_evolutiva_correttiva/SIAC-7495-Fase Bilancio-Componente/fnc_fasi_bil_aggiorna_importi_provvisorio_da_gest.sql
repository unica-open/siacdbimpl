/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 02.05.2016 Davide - predisposizione bilancio provvisorio da gestione precedente
-- bilancio gestione annoBilancio-1
-- importo previsione annoBilancio  = importo gestione annoBilancio,   del bilancio annoBilancio-1
-- importo previsione annoBilancio+1= importo gestione annoBilancio+1, del bilancio annoBilancio-1
-- importo previsione annoBilancio+2= 0
CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_provv_apertura_importi
(
  annobilancio    integer,
  euElemTipo      varchar,
  bilElemGestTipo varchar,
  elemGestEq      boolean, -- trattamento capitoli di gestione equivalenti esistenti
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

	APE_PROV_DA_GEST CONSTANT varchar:='APE_PROV';
    SY_PER_TIPO      CONSTANT varchar:='SY';
    STI_DET_TIPO     CONSTANT varchar:='STI';
    SRI_DET_TIPO     CONSTANT varchar:='SRI';
    SCI_DET_TIPO     CONSTANT varchar:='SCI';

    STA_DET_TIPO     CONSTANT varchar:='STA';
    STR_DET_TIPO     CONSTANT varchar:='STR';
    SCA_DET_TIPO     CONSTANT varchar:='SCA';

    -- SIAC-7495 Sofia 14.09.2020
    CAP_UG_ST CONSTANT varchar:='CAP-UG';

	gestEqEsiste      integer:=null;
    gestEqApri     integer:=null;
    gestEqEsisteNoGest  integer:=null;
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

BEGIN

	messaggioRisultato:='';
    codiceRisultato:=0;

    dataInizioVal:=clock_timestamp();-- usato al posto di now() per essere certi di riconoscere i record inseriti dopo la chiamata della funzione;

	strMessaggioFinale:='Apertura bilancio provvisorio di gestione.Aggiornamento importi Gestione '||bilElemGestTipo||' da Gestione anno precedente'||bilElemGEstTipo||
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
    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;



    -- backup -- aggiornamento importi di gestione equivalente esistente
    if elemGestEq=true then
        strMessaggio:='Verifica esistenza elementi di bilancio provvisorio di gestione equivalenti da aggiornare da gestione anno precedente.';

    	select distinct 1 into gestEqEsiste
        from fase_bil_t_gest_apertura_provv fase
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null
        and   fase.elem_id is not null       -- esistenti in gestione precedente
        and   fase.elem_prov_id is not null
        and   fase.elem_prov_new_id is null
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
         -- inserire backup importi gestione esistente che devono poi essere sovrascritti
         -- al posto di update qui
        /* strMessaggio:='Cancellazione logica importi capitoli di gestione provvisoria equivalenti esistenti.';
    	 update siac_t_bil_elem_det det
	      set data_cancellazione=now(), validita_inizio=now(), login_operazione=loginOperazione
    	 from fase_bil_t_gest_apertura_provv fase
	     where  fase.ente_proprietario_id=enteProprietarioId
         and    fase.bil_id=bilancioId
         and    fase.fase_bil_elab_id=faseBilElabId
    	 and    fase.data_cancellazione is null
         and    fase.validita_fine is null
         and    fase.elem_id is not null
         and    fase.elem_prov_new_id is null
	     and    fase.elem_prov_id is not null
         and    det.elem_id=fase.elem_prov_id
         and    det.data_cancellazione is null
         and    det.validita_fine is null;*/
         strMessaggio:='Inserimento backup importi capitoli di gestione provvisoria equivalenti esistenti.';
         insert into bck_fase_bil_t_gest_apertura_provv_bil_elem_det
         (elem_bck_id,elem_bck_det_id,elem_bck_det_importo,elem_bck_det_flag,elem_bck_det_tipo_id,elem_bck_periodo_id,
          elem_bck_data_creazione,elem_bck_data_modifica,elem_bck_login_operazione,
          elem_bck_validita_inizio,elem_bck_validita_fine,
		  fase_bil_elab_id, login_operazione, validita_inizio, ente_proprietario_id)
         (select  det.elem_id, det.elem_det_id, det.elem_det_importo, det.elem_det_flag, det.elem_det_tipo_id, det.periodo_id,
          	      det.data_creazione, det.data_modifica, det.login_operazione, det.validita_inizio,det.validita_fine,
                  fase.fase_bil_elab_id, loginoperazione, now(),enteProprietarioId
          from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
          where fase.ente_proprietario_id=enteProprietarioId
          and   fase.bil_id=bilancioId
          and   fase.fase_bil_elab_id=faseBilElabId
    	  and   fase.data_cancellazione is null
          and   fase.validita_fine is null
          and   fase.elem_id is not null      -- esistente in gestione precedente
          and   fase.elem_prov_new_id is null -- non nuovo
	      and   fase.elem_prov_id is not null -- esistente in gestione correge
          and   det.elem_id=fase.elem_prov_id -- bck del dato in gestione corrente
          and   det.data_cancellazione is null
          and   det.validita_fine is null);

         -- verifica inserimento backup
		 codResult:=null;
         strMessaggio:=strMessaggio||' Verifica inserimento.';
         select 1 into codResult
         from  fase_bil_t_gest_apertura_provv fase
         where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
    	 and   fase.data_cancellazione is null
         and   fase.validita_fine is null
         and   fase.elem_id is not null      -- esistente in gestione precedente
         and   fase.elem_prov_new_id is null -- non nuovo
	     and   fase.elem_prov_id is not null -- esistente in gestione correge
         and   not exists ( select 1 from bck_fase_bil_t_gest_apertura_provv_bil_elem_det bck
							where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                            and   bck.elem_bck_id=fase.elem_prov_id
					        and   bck.data_cancellazione is null
					        and   bck.validita_fine is null )
         limit 1;
         if codResult is not null then raise exception ' Elementi senza backup effettuato.'; end if;

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

        -- SIAC-7495 Sofia 14.09.2020 - inizio
        if bilElemGestTipo=CAP_UG_ST then
		-- bck_fase_bil_t_gest_ape_provv_bil_elem_det_comp
        strMessaggio:='Inserimento backup componenti importi capitoli di gestione provvisoria equivalenti esistenti.';
        insert into bck_fase_bil_t_gest_ape_provv_bil_elem_det_comp
        (elem_bck_det_comp_id,
		 elem_bck_det_id,
		 elem_bck_det_comp_tipo_id,
		 elem_bck_det_importo,
         elem_bck_data_creazione,elem_bck_data_modifica,elem_bck_login_operazione,
         elem_bck_validita_inizio,elem_bck_validita_fine,
		 fase_bil_elab_id, login_operazione, validita_inizio, ente_proprietario_id)
        (select  comp.elem_det_comp_id, comp.elem_det_id, comp.elem_det_comp_tipo_id, comp.elem_det_importo,
          	     comp.data_creazione, comp.data_modifica, comp.login_operazione, comp.validita_inizio,comp.validita_fine,
                 fase.fase_bil_elab_id, loginoperazione, clock_timestamp(),enteProprietarioId
          from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det,
               siac_t_bil_elem_det_comp comp--,siac_d_bil_elem_det_comp_tipo tipo
          where fase.ente_proprietario_id=enteProprietarioId
          and   fase.bil_id=bilancioId
          and   fase.fase_bil_elab_id=faseBilElabId
    	  and   fase.data_cancellazione is null
          and   fase.validita_fine is null
          and   fase.elem_id is not null      -- esistente in gestione precedente
          and   fase.elem_prov_new_id is null -- non nuovo
	      and   fase.elem_prov_id is not null -- esistente in gestione correge
          and   det.elem_id=fase.elem_prov_id -- bck del dato in gestione corrente
          and   comp.elem_det_id=det.elem_det_id
--          and   tipo.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
          and   det.data_cancellazione is null
          and   det.validita_fine is null
          and   comp.data_cancellazione is null
          and   comp.validita_fine is null);
--          and   tipo.data_cancellazione is null);

         -- verifica inserimento backup
		 codResult:=null;
         strMessaggio:=strMessaggio||' Verifica inserimento.';
         select 1 into codResult
         from  fase_bil_t_gest_apertura_provv fase,
               siac_t_bil_elem_det det,siac_t_bil_elem_det_comp comp--,siac_d_bil_elem_det_comp_tipo tipo
         where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
         and   det.elem_id=fase.elem_prov_id
         and   comp.elem_det_id=det.elem_det_id
         --and   tipo.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
    	 and   fase.data_cancellazione is null
         and   fase.validita_fine is null
         and   fase.elem_id is not null      -- esistente in gestione precedente
         and   fase.elem_prov_new_id is null -- non nuovo
	     and   fase.elem_prov_id is not null -- esistente in gestione correge
         and   det.data_cancellazione is null
         and   det.validita_fine is null
         and   comp.data_cancellazione is null
         and   comp.validita_fine is null
  --       and   tipo.data_cancellazione is null
         and   not exists ( select 1 from bck_fase_bil_t_gest_ape_provv_bil_elem_det_comp bck
							where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                            and   bck.elem_bck_det_comp_id=comp.elem_det_comp_id
					        and   bck.data_cancellazione is null
					        and   bck.validita_fine is null )
         limit 1;
         if codResult is not null then raise exception ' Elementi senza backup effettuato.'; end if;

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

        -- SIAC-7495 Sofia 14.09.2020 - fine
       end if;
    end if;

    strMessaggio:='Verifica esistenza elementi di bilancio provvisorio equivalenti da aprire.';

	select distinct 1 into gestEqApri
    from fase_bil_t_gest_apertura_provv fase
    where fase.ente_proprietario_id=enteProprietarioId
    and   fase.bil_id=bilancioId
    and   fase.fase_bil_elab_id=faseBilElabId
    and   fase.elem_id is not null
    and   fase.elem_prov_id is null
    and   fase.elem_prov_new_id is not null
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

    if gestEqApri is not null then
     strMessaggio:='Inserimento  importi capitoli di gestione provvisori da gestione equivalenti anno precedente per annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
     --- inserimento nuovi importi
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
      validita_inizio, ente_proprietario_id, login_operazione)
     (select fase.elem_prov_new_id,
            (case when importiGest=true then det.elem_det_importo
    			  else 0 END),
			det.elem_det_tipo_id,
            det.periodo_id,
            dataInizioVal,det.ente_proprietario_id,loginOperazione
      from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_id is not null
      and   fase.elem_prov_id is null
      and   fase.elem_prov_new_id is not null
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   det.elem_id=fase.elem_id
      and   det.periodo_id in (periodoId, periodoAnno1Id) -- impostazione degli importi dalla gestione anno prec per anno e anno+1
      and   det.elem_det_tipo_id not in (detTipoSciId,detTipoSriId,detTipoStiId)
      and   det.data_cancellazione is null
      and   det.validita_fine is null
     );

     strMessaggio:='Inserimento  importi iniziali capitoli di gestione provvisori da gestione equivalenti anno precedente per annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
     --- inserimento nuovi importi
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
      validita_inizio, ente_proprietario_id, login_operazione)
     (select fase.elem_prov_new_id,
            (case when importiGest=true then det.elem_det_importo
    			  else 0 END),
			(case when det.elem_det_tipo_id=detTipoScaId then detTipoSciId
                  when det.elem_det_tipo_id=detTipoStaId then detTipoStiId
                  when det.elem_det_tipo_id=detTipoStrId then detTipoSriId end),
            det.periodo_id,
            dataInizioVal,det.ente_proprietario_id,loginOperazione
      from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_id is not null
      and   fase.elem_prov_id is null
      and   fase.elem_prov_new_id is not null
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   det.elem_id=fase.elem_id
      and   det.periodo_id in (periodoId, periodoAnno1Id) -- impostazione degli importi dalla gestione anno prec per anno e anno+1
      and   det.elem_det_tipo_id in (detTipoScaId,detTipoStrId,detTipoStaId)
      and   det.data_cancellazione is null
      and   det.validita_fine is null
     );

     strMessaggio:='Inserimento  importi capitoli di gestione provvisori per annoBilancio+2='||(annoBilancio+2)::varchar||'.';
     --- inserimento nuovi importi
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
      validita_inizio, ente_proprietario_id, login_operazione)
     (select fase.elem_prov_new_id,
             0,
             det.elem_det_tipo_id,
             periodoAnno2Id,
             dataInizioVal,det.ente_proprietario_id,loginOperazione
      from fase_bil_t_gest_apertura_provv fase,
           siac_t_bil_elem_det det
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_id is not null
      and   fase.elem_prov_id is null
      and   fase.elem_prov_new_id is not null
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   det.elem_id=fase.elem_id
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
     from siac_t_bil_elem_det det , fase_bil_t_gest_apertura_provv fase
     where fase.ente_proprietario_id=enteProprietarioId
     and   fase.bil_id=bilancioId
     and   fase.fase_bil_elab_id=faseBilElabId
     and   fase.elem_id is not null
     and   fase.elem_prov_id is null
     and   fase.elem_prov_new_id is not null
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null
     and   det.elem_id=fase.elem_prov_new_id
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

     -- SIAC-7495 Sofia 14.09.2020 - inizio
     if bilElemGestTipo=CAP_UG_ST then

       strMessaggio:='Inserimento  componenti importi capitoli di gestione provvisori da gestione equivalenti anno precedente per annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
       --- inserimento nuovi importi
       insert into siac_t_bil_elem_det_comp
       (elem_det_id,elem_det_comp_tipo_id, elem_det_importo,
        validita_inizio, ente_proprietario_id, login_operazione)
       (select detGestNew.elem_det_id,
               tipo.elem_det_comp_tipo_id,
              (case when importiGest=true then comp.elem_det_importo
                    else 0 END),
              dataInizioVal,det.ente_proprietario_id,loginOperazione
        from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det,
             siac_t_bil_elem_det_comp comp,siac_d_bil_elem_det_comp_tipo tipo,
             siac_t_bil_elem_det detGestNew
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.elem_id is not null
        and   fase.elem_prov_id is null
        and   fase.elem_prov_new_id is not null
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null
        and   det.elem_id=fase.elem_id
        and   det.periodo_id in (periodoId, periodoAnno1Id) -- impostazione degli importi dalla gestione anno prec per anno e anno+1
        and   comp.elem_det_id=det.elem_det_id
        and   tipo.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
        and   detGestNew.elem_id=fase.elem_prov_new_id
        and   detGestNew.elem_det_tipo_id=det.elem_det_tipo_id
        and   detGestNew.periodo_id=det.periodo_id
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   comp.data_cancellazione is null
        and   comp.validita_fine is null
        and   detGestNew.data_cancellazione is null
        and   detGestNew.validita_fine is null
        and   tipo.data_cancellazione is null
       );

       strMessaggio:='Inserimento componenti importi capitoli di gestione provvisori per annoBilancio+2='||(annoBilancio+2)::varchar||'.';
       --- inserimento nuovi importi
       insert into siac_t_bil_elem_det_comp
       (elem_det_id,elem_det_comp_tipo_id, elem_det_importo,
        validita_inizio, ente_proprietario_id, login_operazione)
       (select detGestNew.elem_det_id,
       		   tipo.elem_det_comp_tipo_id,
               0,
               dataInizioVal,det.ente_proprietario_id,loginOperazione
        from fase_bil_t_gest_apertura_provv fase,
             siac_t_bil_elem_det det,
             siac_t_bil_elem_det_comp comp,siac_d_bil_elem_det_comp_tipo tipo,
             siac_t_bil_elem_det detGestNew
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.elem_id is not null
        and   fase.elem_prov_id is null
        and   fase.elem_prov_new_id is not null
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null
        and   det.elem_id=fase.elem_id
        and   det.periodo_id=periodoId
        and   comp.elem_det_id=det.elem_det_id
        and   tipo.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
        and   detGestNew.elem_id=fase.elem_prov_new_id
        and   detGestNew.elem_det_tipo_id=det.elem_det_tipo_id
        and   detGestNew.periodo_id=periodoAnno2Id
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   comp.data_cancellazione is null
        and   comp.validita_fine is null
        and   detGestNew.data_cancellazione is null
        and   detGestNew.validita_fine is null
        and   tipo.data_cancellazione is null
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
       from siac_t_bil_elem_det det , fase_bil_t_gest_apertura_provv fase,
            siac_t_bil_elem_det_comp comp, siac_d_bil_elem_det_comp_tipo tipo
       where fase.ente_proprietario_id=enteProprietarioId
       and   fase.bil_id=bilancioId
       and   fase.fase_bil_elab_id=faseBilElabId
       and   fase.elem_id is not null
       and   fase.elem_prov_id is null
       and   fase.elem_prov_new_id is not null
       and   fase.data_cancellazione is null
       and   fase.validita_fine is null
       and   det.elem_id=fase.elem_prov_new_id
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
     -- SIAC-7495 Sofia 14.09.2020 - fine
    end if;

--	raise notice 'elemGestEq=% gestEqEsiste=%', elemPrevEq,prevEqEsiste;
	if elemGestEq=true and gestEqEsiste is not null then
        -- sostituire insert di nuovi dettagli con update su quelli esistenti di cui fatto backup ad inizio
	    /*strMessaggio:='Inserimento importi capitoli di gestione provvisorio esistenti da gestione equivalenti anno precedente annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
    	--- inserimento nuovi importi
	    insert into siac_t_bil_elem_det
    	(elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
	     validita_inizio, ente_proprietario_id, login_operazione)
    	(select fase.elem_prov_id,
            (case when importiGest=true then det.elem_det_importo
    			  else 0 END),
            det.elem_det_tipo_id,
            det.periodo_id,
            dataInizioVal,det.ente_proprietario_id,loginOperazione
	     from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
         and   fase.elem_id is not null
         and   fase.elem_prov_id is not null
         and   fase.elem_prov_new_id is null
       	 and   det.elem_id=fase.elem_id
         and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
         and   det.periodo_id in (periodoId, periodoAnno1Id)
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
	    ); sostituito con update sotto */

        strMessaggio:='Aggiornamento importi capitoli di gestione provvisorio esistenti da gestione equivalenti anno precedente annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
		update siac_t_bil_elem_det detCor
        set elem_det_flag=det.elem_det_flag,
            elem_det_importo=det.elem_det_importo,
            data_modifica=dataInizioVal,
            login_operazione=loginOperazione
        from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.elem_id is not null          -- esistente in gestione equivalente prec
        and   fase.elem_prov_id is not null     -- esistente in gestione equivalente corr
        and   fase.elem_prov_new_id is null     -- non un nuovo inserimento
   	    and   det.elem_id=fase.elem_id          -- dato gestione equivalente prec
        and   det.periodo_id in (periodoId, periodoAnno1Id) -- annoBilancio, AnnoBilancio+1
        and   det.elem_det_tipo_id not in (detTipoSciId,detTipoSriId,detTipoStiId)
        and   detCor.elem_id=fase.elem_prov_id  -- dato gestione equivalente corrente
        and   detCor.elem_det_tipo_id=det.elem_det_tipo_id -- stesso tipo importo
        and   detCor.periodo_id=det.periodo_id             -- su stesso periodo
	    and   detCor.data_cancellazione is null
    	and   detCor.validita_fine is null
	    and   det.data_cancellazione is null
    	and   det.validita_fine is null
        and   fase.data_cancellazione is null
    	and   fase.validita_fine is null;

        strMessaggio:='Aggiornamento importi cassa inziale capitoli di gestione provvisorio esistenti da gestione cassa attuale equivalenti anno precedente annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
		update siac_t_bil_elem_det detCor
        set elem_det_flag=det.elem_det_flag,
            elem_det_importo=det.elem_det_importo,
            data_modifica=dataInizioVal,
            login_operazione=loginOperazione
        from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.elem_id is not null          -- esistente in gestione equivalente prec
        and   fase.elem_prov_id is not null     -- esistente in gestione equivalente corr
        and   fase.elem_prov_new_id is null     -- non un nuovo inserimento
   	    and   det.elem_id=fase.elem_id          -- dato gestione equivalente prec
        and   det.periodo_id in (periodoId, periodoAnno1Id) -- annoBilancio, AnnoBilancio+1
        and   det.elem_det_tipo_id=detTipoScaId
        and   detCor.elem_id=fase.elem_prov_id  -- dato gestione equivalente corrente
        and   detCor.elem_det_tipo_id=detTipoSciId
        and   detCor.periodo_id=det.periodo_id             -- su stesso periodo
	    and   detCor.data_cancellazione is null
    	and   detCor.validita_fine is null
	    and   det.data_cancellazione is null
    	and   det.validita_fine is null
        and   fase.data_cancellazione is null
    	and   fase.validita_fine is null;

		strMessaggio:='Aggiornamento importi residui inziale capitoli di gestione provvisorio esistenti da gestione residui attuale equivalenti anno precedente annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
		update siac_t_bil_elem_det detCor
        set elem_det_flag=det.elem_det_flag,
            elem_det_importo=det.elem_det_importo,
            data_modifica=dataInizioVal,
            login_operazione=loginOperazione
        from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.elem_id is not null          -- esistente in gestione equivalente prec
        and   fase.elem_prov_id is not null     -- esistente in gestione equivalente corr
        and   fase.elem_prov_new_id is null     -- non un nuovo inserimento
   	    and   det.elem_id=fase.elem_id          -- dato gestione equivalente prec
        and   det.periodo_id in (periodoId, periodoAnno1Id) -- annoBilancio, AnnoBilancio+1
        and   det.elem_det_tipo_id=detTipoStrId
        and   detCor.elem_id=fase.elem_prov_id  -- dato gestione equivalente corrente
        and   detCor.elem_det_tipo_id=detTipoSriId
        and   detCor.periodo_id=det.periodo_id             -- su stesso periodo
	    and   detCor.data_cancellazione is null
    	and   detCor.validita_fine is null
	    and   det.data_cancellazione is null
    	and   det.validita_fine is null
        and   fase.data_cancellazione is null
    	and   fase.validita_fine is null;

		strMessaggio:='Aggiornamento importi competenza inziale capitoli di gestione provvisorio esistenti da gestione competenza attuale equivalenti anno precedente annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
		update siac_t_bil_elem_det detCor
        set elem_det_flag=det.elem_det_flag,
            elem_det_importo=det.elem_det_importo,
            data_modifica=dataInizioVal,
            login_operazione=loginOperazione
        from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.elem_id is not null          -- esistente in gestione equivalente prec
        and   fase.elem_prov_id is not null     -- esistente in gestione equivalente corr
        and   fase.elem_prov_new_id is null     -- non un nuovo inserimento
   	    and   det.elem_id=fase.elem_id          -- dato gestione equivalente prec
        and   det.periodo_id in (periodoId, periodoAnno1Id) -- annoBilancio, AnnoBilancio+1
        and   det.elem_det_tipo_id=detTipoStaId
        and   detCor.elem_id=fase.elem_prov_id  -- dato gestione equivalente corrente
        and   detCor.elem_det_tipo_id=detTipoStiId
        and   detCor.periodo_id=det.periodo_id             -- su stesso periodo
	    and   detCor.data_cancellazione is null
    	and   detCor.validita_fine is null
	    and   det.data_cancellazione is null
    	and   det.validita_fine is null
        and   fase.data_cancellazione is null
    	and   fase.validita_fine is null;

        /*strMessaggio:='Inserimento importi capitoli di previsione esistenti da gestione equivalenti anno precedente annoBilancio+2='||(annoBilancio+2)::varchar||'.';
    	--- inserimento nuovi importi
	    insert into siac_t_bil_elem_det
    	(elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
	     validita_inizio, ente_proprietario_id, login_operazione)
    	(select fase.elem_prov_id,
                0,
                det.elem_det_tipo_id,
                periodoAnno2Id,
                dataInizioVal,det.ente_proprietario_id,loginOperazione
	     from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
         and   fase.elem_id is not null
         and   fase.elem_prov_id is not null
         and   fase.elem_prov_new_id is null
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
    	 and   det.elem_id=fase.elem_id
         and   det.periodo_id =periodoId
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
	    ); sostituito con update sotto */

        strMessaggio:='Aggiornamento importi capitoli di gestione provvisoria esistenti da gestione equivalenti anno precedente annoBilancio+2='||(annoBilancio+2)::varchar||'.';
        update siac_t_bil_elem_det detCor
        set elem_det_importo=0,
            data_modifica=dataInizioVal,
            login_operazione=loginOperazione
        from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
         and   fase.elem_id is not null       -- esistente in gestione eq prec
         and   fase.elem_prov_id is not null  -- esistente in gestione eq corr
         and   fase.elem_prov_new_id is null  -- non un nuovo inserimento
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
    	 and   det.elem_id=fase.elem_id       -- gestione eq prec
         and   det.periodo_id =periodoId
         and   detCor.elem_id=fase.elem_prov_id -- gestione eq cor
         and   detCor.elem_det_tipo_id=det.elem_det_tipo_id -- tipo uguale
         and   detCor.periodo_id=periodoAnno2Id  --annoBilancio+2
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
	     and   detCor.data_cancellazione is null
    	 and   detCor.validita_fine is null;


        -- fine-sostituire insert di nuovi dettagli con update su quelli esistenti di cui fatto backup ad inizio
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
	    /* non si puo fare andiamo in aggiornamento
        codResult:=null;
    	strMessaggio:='Inserimento importi capitoli di gestione provvisorio esistenti da gestione equivalenti anno precedente.Verifica inserimento.';
	    select 1  into codResult
    	from siac_t_bil_elem_det det , fase_bil_t_gest_apertura_provv fase
	    where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.elem_id is not null
        and   fase.elem_prov_id is not null
        and   fase.elem_prov_new_id is null
    	and   fase.data_cancellazione is null
	    and   fase.validita_fine is null
	    and   det.elem_id=fase.elem_prov_id
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
        end if;*/

	 -- SIAC-7495 Sofia 14.09.2020 - inizio
     if bilElemGestTipo=CAP_UG_ST then

        strMessaggio:='Aggiornamento componenti importi competenza capitoli di gestione provvisorio esistenti da gestione competenza attuale equivalenti anno precedente annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
		update siac_t_bil_elem_det_comp compCor
        set elem_det_importo=compPrec.elem_det_importo,
            data_modifica=dataInizioVal,
            login_operazione=loginOperazione
        from fase_bil_t_gest_apertura_provv fase,
             siac_t_bil_elem_det detGestPrec, siac_t_bil_elem_det_comp compPrec,
             siac_d_bil_elem_det_comp_tipo tipo,
             siac_t_bil_elem_det detCor
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.elem_id is not null          -- esistente in gestione equivalente prec
        and   fase.elem_prov_id is not null     -- esistente in gestione equivalente corr
        and   fase.elem_prov_new_id is null     -- non un nuovo inserimento
   	    and   detGestPrec.elem_id=fase.elem_id          -- dato gestione equivalente prec
        and   detGestPrec.periodo_id in (periodoId, periodoAnno1Id) -- annoBilancio, AnnoBilancio+1
		and   compPrec.elem_det_id=detGestPrec.elem_det_id
        and   tipo.elem_det_comp_tipo_id=compPrec.elem_det_comp_tipo_id
        and   detCor.elem_id=fase.elem_prov_id  -- dato gestione equivalente corrente
        and   detCor.elem_det_tipo_id=detGestPrec.elem_det_tipo_id
        and   detCor.periodo_id=detGestPrec.periodo_id             -- su stesso periodo
        and   compCor.elem_det_id=detCor.elem_det_id
        and   compCor.elem_det_comp_tipo_id=compPrec.elem_det_comp_tipo_id
	    and   detCor.data_cancellazione is null
    	and   detCor.validita_fine is null
	    and   compCor.data_cancellazione is null
    	and   compCor.validita_fine is null
	    and   detGestPrec.data_cancellazione is null
    	and   detGestPrec.validita_fine is null
	    and   compPrec.data_cancellazione is null
    	and   compPrec.validita_fine is null
        and   tipo.data_cancellazione is null
        and   fase.data_cancellazione is null
    	and   fase.validita_fine is null;

        strMessaggio:='Aggiornamento componenti importi capitoli di gestione provvisoria esistenti da gestione equivalenti anno precedente annoBilancio+2='||(annoBilancio+2)::varchar||'.';
        update siac_t_bil_elem_det_comp compCor
        set elem_det_importo=0,
            data_modifica=dataInizioVal,
            login_operazione=loginOperazione
        from fase_bil_t_gest_apertura_provv fase,
        	 siac_t_bil_elem_det detGestPrec, siac_t_bil_elem_det_comp compPrec,
             siac_d_bil_elem_det_comp_tipo tipo,
             siac_t_bil_elem_det detCor
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
         and   fase.elem_id is not null       -- esistente in gestione eq prec
         and   fase.elem_prov_id is not null  -- esistente in gestione eq corr
         and   fase.elem_prov_new_id is null  -- non un nuovo inserimento
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
    	 and   detGestPrec.elem_id=fase.elem_id       -- gestione eq prec
         and   detGestPrec.periodo_id =periodoId
         and   compPrec.elem_det_id=detGestPrec.elem_det_id
         and   tipo.elem_det_comp_tipo_id=compPrec.elem_det_comp_tipo_id
         and   detCor.elem_id=fase.elem_prov_id -- gestione eq cor
         and   detCor.elem_det_tipo_id=detGestPrec.elem_det_tipo_id -- tipo uguale
         and   detCor.periodo_id=periodoAnno2Id  --annoBilancio+2
         and   compCor.elem_det_id=detCor.elem_det_id
         and   compCor.elem_det_comp_tipo_id=compPrec.elem_det_comp_tipo_Id
	     and   detGestPrec.data_cancellazione is null
    	 and   detGestPrec.validita_fine is null
	     and   compPrec.data_cancellazione is null
    	 and   compPrec.validita_fine is null
	     and   detCor.data_cancellazione is null
    	 and   detCor.validita_fine is null
	     and   compCor.data_cancellazione is null
    	 and   compCor.validita_fine is null
	     and   tipo.data_cancellazione is null;


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


        strMessaggio:='Aggiornamento componenti importi capitoli di gestione provvisoria esistenti da gestione equivalenti anno precedente annoBilancio='
           ||(annoBilancio)::varchar
           || ' annoBilancio+1='||(annoBilancio+1)::varchar
           ||'. Azzeramento componenti non esistenti in anno prec.';
        update siac_t_bil_elem_det_comp compCor
        set elem_det_importo=0,
            data_modifica=dataInizioVal,
            login_operazione=loginOperazione
        from fase_bil_t_gest_apertura_provv fase,
             siac_t_bil_elem_det detCor,
             siac_d_bil_elem_det_comp_tipo tipo
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
         and   fase.elem_id is not null       -- esistente in gestione eq prec
         and   fase.elem_prov_id is not null  -- esistente in gestione eq corr
         and   fase.elem_prov_new_id is null  -- non un nuovo inserimento
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
    	 and   detCor.elem_id=fase.elem_prov_id   -- cap corr
         and   detCor.periodo_id in (periodoId,periodoAnno1Id)
         and   compCor.elem_det_id=detCor.elem_det_id
         and   tipo.elem_det_comp_tipo_id=compCor.elem_det_comp_tipo_id
         and   not exists
         (
         select 1
         from siac_t_bil_elem_det detGestPrec, siac_t_bil_elem_det_comp compGestPrec
         where detGestPrec.elem_id=fase.elem_id
         and   detGestPrec.elem_det_tipo_id=detCor.elem_det_tipo_id
         and   detGestPrec.periodo_id=detCor.periodo_id
         and   compGestPrec.elem_Det_id=detGestPrec.elem_det_id
         and   compGestPrec.elem_det_comp_tipo_id=tipo.elem_det_comp_tipo_id
         and   detGestPrec.data_cancellazione is null
         and   detGestPrec.validita_fine is null
         and   compGestPrec.data_cancellazione is null
         and   compGestPrec.validita_fine is null
         )
	     and   detCor.data_cancellazione is null
    	 and   detCor.validita_fine is null
	     and   compCor.data_cancellazione is null
    	 and   compCor.validita_fine is null;
	     --and   tipo.data_cancellazione is null;

        strMessaggio:='Aggiornamento componenti importi capitoli di gestione provvisoria esistenti da gestione equivalenti anno precedente annoBilancio+2='
           ||(annoBilancio+2)::varchar
           ||'. Azzeramento componenti non esistenti in anno prec.';
        update siac_t_bil_elem_det_comp compCor
        set elem_det_importo=0,
            data_modifica=dataInizioVal,
            login_operazione=loginOperazione
        from fase_bil_t_gest_apertura_provv fase,
             siac_t_bil_elem_det detCor,
             siac_d_bil_elem_det_comp_tipo tipo
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
         and   fase.elem_id is not null       -- esistente in gestione eq prec
         and   fase.elem_prov_id is not null  -- esistente in gestione eq corr
         and   fase.elem_prov_new_id is null  -- non un nuovo inserimento
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
    	 and   detCor.elem_id=fase.elem_prov_id   -- cap corr
         and   detCor.periodo_id =periodoAnno2Id
         and   compCor.elem_det_id=detCor.elem_det_id
         and   tipo.elem_det_comp_tipo_id=compCor.elem_det_comp_tipo_id
         and   not exists
         (
         select 1
         from siac_t_bil_elem_det detGestPrec, siac_t_bil_elem_det_comp compGestPrec
         where detGestPrec.elem_id=fase.elem_id
         and   detGestPrec.elem_det_tipo_id=detCor.elem_det_tipo_id
         and   detGestPrec.periodo_id=periodoId
         and   compGestPrec.elem_Det_id=detGestPrec.elem_det_id
         and   compGestPrec.elem_det_comp_tipo_id=tipo.elem_det_comp_tipo_id
         and   detGestPrec.data_cancellazione is null
         and   detGestPrec.validita_fine is null
         and   compGestPrec.data_cancellazione is null
         and   compGestPrec.validita_fine is null
         )
	     and   detCor.data_cancellazione is null
    	 and   detCor.validita_fine is null
	     and   compCor.data_cancellazione is null
    	 and   compCor.validita_fine is null;
--	     and   tipo.data_cancellazione is null;

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


        strMessaggio:='Aggiornamento componenti importi capitoli di gestione provvisoria esistenti da gestione equivalenti anno precedente annoBilancio='
           ||(annoBilancio)::varchar
           || ' annoBilancio+1='||(annoBilancio+1)::varchar
           ||'. Inserimento componenti non esistenti in anno corrente.';
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
            detCor.elem_det_id,
            tipo.elem_det_comp_tipo_id,
            compGestPrec.elem_det_importo,
            dataInizioVal,
            loginOperazione,
            tipo.ente_proprietario_id
        from fase_bil_t_gest_apertura_provv fase,
             siac_t_bil_elem_det detCor,
             siac_t_bil_elem_det detGestPrec,
             siac_t_bil_elem_det_comp compGestPrec,
             siac_d_bil_elem_det_comp_tipo tipo
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
         and   fase.elem_id is not null       -- esistente in gestione eq prec
         and   fase.elem_prov_id is not null  -- esistente in gestione eq corr
         and   fase.elem_prov_new_id is null  -- non un nuovo inserimento
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
    	 and   detCor.elem_id=fase.elem_prov_id   -- cap corr
         and   detCor.periodo_id in (periodoId,periodoAnno1Id)
         and   detGestPrec.elem_id=fase.elem_id
         and   detGestPrec.elem_det_tipo_id=detCor.elem_det_tipo_id
         and   detGestPrec.periodo_id=detCor.periodo_id
         and   compGestPrec.elem_det_id=detGestPrec.elem_det_id
         and   tipo.elem_det_comp_tipo_id=compGestPrec.elem_det_comp_tipo_id
         and   not exists
         (
         select 1
         from siac_t_bil_elem_det_comp compCor
         where compCor.elem_det_id=detCor.elem_det_id
         and   compCor.elem_det_comp_tipo_id=tipo.elem_det_comp_tipo_id
         and   compCor.data_cancellazione is null
         and   compCor.validita_fine is null
         )
	     and   detGestPrec.data_cancellazione is null
    	 and   detGestPrec.validita_fine is null
	     and   compGestPrec.data_cancellazione is null
    	 and   compGestPrec.validita_fine is null
	     and   tipo.data_cancellazione is null;

         strMessaggio:='Aggiornamento componenti importi capitoli di gestione provvisoria esistenti da gestione equivalenti anno precedente annoBilancio+2='
           ||(annoBilancio+2)::varchar
           ||'. Inserimento componenti non esistenti in anno corrente.';
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
            detCor.elem_det_id,
            tipo.elem_det_comp_tipo_id,
            0,
            dataInizioVal,
            loginOperazione,
            tipo.ente_proprietario_id
        from fase_bil_t_gest_apertura_provv fase,
             siac_t_bil_elem_det detCor,
             siac_t_bil_elem_det detGestPrec,
             siac_t_bil_elem_det_comp compGestPrec,
             siac_d_bil_elem_det_comp_tipo tipo
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
         and   fase.elem_id is not null       -- esistente in gestione eq prec
         and   fase.elem_prov_id is not null  -- esistente in gestione eq corr
         and   fase.elem_prov_new_id is null  -- non un nuovo inserimento
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
    	 and   detCor.elem_id=fase.elem_prov_id   -- cap corr
         and   detCor.periodo_id=periodoAnno2Id
         and   detGestPrec.elem_id=fase.elem_id
         and   detGestPrec.elem_det_tipo_id=detCor.elem_det_tipo_id
         and   detGestPrec.periodo_id=periodoId
         and   compGestPrec.elem_det_id=detGestPrec.elem_det_id
         and   tipo.elem_det_comp_tipo_id=compGestPrec.elem_det_comp_tipo_id
         and   not exists
         (
         select 1
         from siac_t_bil_elem_det_comp compCor
         where compCor.elem_det_id=detCor.elem_det_id
         and   compCor.elem_det_comp_tipo_id=tipo.elem_det_comp_tipo_id
         and   compCor.data_cancellazione is null
         and   compCor.validita_fine is null
         )
	     and   detGestPrec.data_cancellazione is null
    	 and   detGestPrec.validita_fine is null
	     and   compGestPrec.data_cancellazione is null
    	 and   compGestPrec.validita_fine is null
	     and   tipo.data_cancellazione is null;


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
     -- SIAC-7495 Sofia 14.09.2020 - fine


	end if;

    if elemGestEq=true then

        strMessaggio:='Verifica esistenza elementi di bilancio provvisorio equivalenti non presenti in gestione anno precedente.';

    	select  1 into gestEqEsisteNoGest
        from fase_bil_t_gest_apertura_provv fase
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.elem_id is null
        and   fase.elem_prov_id is not null
        and   fase.elem_prov_new_id is null
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null
        limit 1;
--raise notice 'gestEqEsisteNoGest=%', gestEqEsisteNoGest;

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

		if gestEqEsisteNoGest is not null then
         -- sostituire insert e successiva update con
         -- backup di importi precedenti per capitoli gestione corrente che non esistono in gestione eq prec
         strMessaggio:='Inserimento backup importi per capitoli di gestione provvisorio esistenti senza gestione equivalente anno precedente.';
         insert into bck_fase_bil_t_gest_apertura_provv_bil_elem_det
         (elem_bck_id,elem_bck_det_id,elem_bck_det_importo,elem_bck_det_flag,elem_bck_det_tipo_id,elem_bck_periodo_id,
          elem_bck_data_creazione,elem_bck_data_modifica,elem_bck_login_operazione,
          elem_bck_validita_inizio,elem_bck_validita_fine,
		  fase_bil_elab_id, login_operazione, validita_inizio, ente_proprietario_id)
         (select  det.elem_id, det.elem_det_id, det.elem_det_importo, det.elem_det_flag, det.elem_det_tipo_id, det.periodo_id,
          	      det.data_creazione, det.data_modifica, det.login_operazione, det.validita_inizio,det.validita_fine,
                  fase.fase_bil_elab_id, loginoperazione, now(),enteProprietarioId
          from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
          where fase.ente_proprietario_id=enteProprietarioId
          and   fase.bil_id=bilancioId
          and   fase.fase_bil_elab_id=faseBilElabId
    	  and   fase.data_cancellazione is null
          and   fase.validita_fine is null
          and   fase.elem_id is null          -- non esiste in gestione precedente
          and   fase.elem_prov_id is not null -- esiste in gestione corrente
          and   fase.elem_prov_new_id is null -- non nuovo
          and   det.elem_id=fase.elem_prov_id -- bck del dato in gestione corrente
          and   det.data_cancellazione is null
          and   det.validita_fine is null);

          -- inserire controllo inserimento backup
		  codResult:=null;
          strMessaggio:=strMessaggio||' Verifica inserimento.';
          select 1 into codResult
          from  fase_bil_t_gest_apertura_provv fase
          where fase.ente_proprietario_id=enteProprietarioId
          and   fase.bil_id=bilancioId
          and   fase.fase_bil_elab_id=faseBilElabId
    	  and   fase.data_cancellazione is null
          and   fase.validita_fine is null
          and   fase.elem_id is null      -- esistente in gestione precedente
          and   fase.elem_prov_new_id is null -- non nuovo
	      and   fase.elem_prov_id is not null -- esistente in gestione correge
          and   not exists ( select 1 from bck_fase_bil_t_gest_apertura_provv_bil_elem_det bck
		 					 where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                             and   bck.elem_bck_id=fase.elem_prov_id
					         and   bck.data_cancellazione is null
					         and   bck.validita_fine is null )
          limit 1;
          if codResult is not null then raise exception ' Elementi senza backup effettuato.'; end if;


         -- update di importi a zero
   	     /*strMessaggio:='Inserimento importi a zero per capitoli di gestione provvisorio esistenti senza gestione equivalente anno precedente.';
  	     insert into siac_t_bil_elem_det
	     (elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
    	  validita_inizio, ente_proprietario_id, login_operazione)
	     (select fase.elem_prov_id, 0,
   		         det.elem_det_tipo_id,
	             det.periodo_id,
    	         dataInizioVal,det.ente_proprietario_id,loginOperazione
	      from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
    	  where fase.ente_proprietario_id=enteProprietarioId
          and   fase.bil_id=bilancioId
          and   fase.fase_bil_elab_id=faseBilElabId
    	  and   fase.data_cancellazione is null
          and   fase.validita_fine is null
	      and   fase.elem_id is null
          and   fase.elem_prov_id is not null
          and   fase.elem_prov_new_id is null
    	  and   det.elem_id=fase.elem_prov_id
	      and   det.data_cancellazione is null
    	  and   det.validita_fine is null
	     ); vedi update sotto */

        strMessaggio:='Aggiornamento importi a zero per capitoli di gestione provvisorio esistenti senza gestione equivalente anno precedente.';
		update siac_t_bil_elem_det detCor
        set elem_det_importo=0,
            data_modifica=dataInizioVal,
            login_operazione=loginOperazione
        from fase_bil_t_gest_apertura_provv fase
    	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.elem_id is null           -- non esiste in gestione eq prec
        and   fase.elem_prov_id is not null  -- esistente in gestione eq corr
        and   fase.elem_prov_new_id is null  -- non un nuovo inserimento
	    and   fase.data_cancellazione is null
    	and   fase.validita_fine is null
    	and   detCor.elem_id=fase.elem_prov_id -- gestione corrente
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

	    /* strMessaggio:='Cancellazione logica importi capitoli di gestione provvisoria esistenti senza gestione equivalente anno precedente.';

    	 update siac_t_bil_elem_det det
	      set data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
    	 from fase_bil_t_gest_apertura_provv fase
	     where  fase.ente_proprietario_id=enteProprietarioId
         and    fase.bil_id=bilancioId
         and    fase.fase_bil_elab_id=faseBilElabId
         and    fase.elem_id is null
         and    fase.elem_prov_id is not null
         and    fase.elem_prov_new_id is null
    	 and    fase.data_cancellazione is null
         and    fase.validita_fine is null
         and    det.elem_id=fase.elem_prov_id
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
	     from siac_t_bil_elem_det det , fase_bil_t_gest_apertura_provv fase
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
         and    fase.elem_id is null
         and    fase.elem_prov_id is not null
         and    fase.elem_prov_new_id is null
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
    	 and   det.elem_id=fase.elem_prov_id
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
         end if;*/


         -- SIAC-7495 Sofia 14.09.2020 - inizio
	     if bilElemGestTipo=CAP_UG_ST then
           strMessaggio:='Inserimento backup componenti importi per capitoli di gestione provvisorio esistenti senza gestione equivalente anno precedente.';
           insert into bck_fase_bil_t_gest_ape_provv_bil_elem_det_comp
           (elem_bck_det_comp_id,
		    elem_bck_det_id,
		    elem_bck_det_comp_tipo_id,
		    elem_bck_det_importo,
            elem_bck_data_creazione,elem_bck_data_modifica,elem_bck_login_operazione,
            elem_bck_validita_inizio,elem_bck_validita_fine,
            fase_bil_elab_id, login_operazione, validita_inizio, ente_proprietario_id)
           (select  comp.elem_det_comp_id,
           		    comp.elem_det_id,
                    comp.elem_det_comp_tipo_id,
                    comp.elem_det_importo,
                    comp.data_creazione, comp.data_modifica, comp.login_operazione, comp.validita_inizio,comp.validita_fine,
                    fase.fase_bil_elab_id, loginoperazione, clock_timestamp(),enteProprietarioId
            from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det,
                 siac_t_bil_elem_det_comp comp--,siac_d_bil_elem_det_comp_tipo tipo
            where fase.ente_proprietario_id=enteProprietarioId
            and   fase.bil_id=bilancioId
            and   fase.fase_bil_elab_id=faseBilElabId
            and   fase.data_cancellazione is null
            and   fase.validita_fine is null
            and   fase.elem_id is null          -- non esiste in gestione precedente
            and   fase.elem_prov_id is not null -- esiste in gestione corrente
            and   fase.elem_prov_new_id is null -- non nuovo
            and   det.elem_id=fase.elem_prov_id -- bck del dato in gestione corrente
            and   comp.elem_det_id=det.elem_det_id
--            and   tipo.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
            and   det.data_cancellazione is null
            and   det.validita_fine is null
            and   comp.data_cancellazione is null
            and   comp.validita_fine is null);
          --  and   tipo.data_cancellazione is null);

          -- inserire controllo inserimento backup
		  codResult:=null;
          strMessaggio:=strMessaggio||' Verifica inserimento.';
          select 1 into codResult
          from  fase_bil_t_gest_apertura_provv fase,siac_t_bil_elem_det det,
                siac_t_bil_elem_det_comp comp--,siac_d_bil_elem_det_comp_tipo tipo
          where fase.ente_proprietario_id=enteProprietarioId
          and   fase.bil_id=bilancioId
          and   fase.fase_bil_elab_id=faseBilElabId
    	  and   fase.data_cancellazione is null
          and   fase.validita_fine is null
          and   fase.elem_id is null      -- esistente in gestione precedente
          and   fase.elem_prov_new_id is null -- non nuovo
	      and   fase.elem_prov_id is not null -- esistente in gestione correge
          and   det.elem_id=fase.elem_prov_id
          and   comp.elem_det_id=det.elem_det_id
          --and   tipo.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
          and   det.data_cancellazione is null
          and   det.validita_fine is null
          and   comp.data_cancellazione is null
          and   comp.validita_fine is null
         -- and   tipo.data_cancellazione is null
          and   not exists ( select 1 from bck_fase_bil_t_gest_ape_provv_bil_elem_det_comp bck
		 					 where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                             and   bck.elem_bck_det_comp_id=comp.elem_det_comp_id
					         and   bck.data_cancellazione is null
					         and   bck.validita_fine is null )
          limit 1;
          if codResult is not null then raise exception ' Elementi senza backup effettuato.'; end if;


          strMessaggio:='Aggiornamento importi a zero per capitoli di gestione provvisorio esistenti senza gestione equivalente anno precedente.';
		  update siac_t_bil_elem_det_comp compCor
	      set elem_det_importo=0,
            data_modifica=dataInizioVal,
            login_operazione=loginOperazione
    	  from fase_bil_t_gest_apertura_provv fase,siac_t_bil_elem_det detCor--,
--               siac_d_bil_elem_det_comp_tipo tipo
	      where fase.ente_proprietario_id=enteProprietarioId
          and   fase.bil_id=bilancioId
          and   fase.fase_bil_elab_id=faseBilElabId
          and   fase.elem_id is null           -- non esiste in gestione eq prec
          and   fase.elem_prov_id is not null  -- esistente in gestione eq corr
          and   fase.elem_prov_new_id is null  -- non un nuovo inserimento
          and   fase.data_cancellazione is null
          and   fase.validita_fine is null
          and   detCor.elem_id=fase.elem_prov_id -- gestione corrente
          and   compCor.elem_det_id=detCor.elem_det_id
       --  and   tipo.elem_det_comp_tipo_id=compCor.elem_det_comp_tipo_id
          and   detCor.data_cancellazione is null
          and   detCor.validita_fine is null
          and   compCor.data_cancellazione is null
          and   compCor.validita_fine is null;
--          and   tipo.data_cancellazione is null;

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
    end if;


   -- SIAC-7495 Sofia 14.09.2020 - inizio
   if bilElemGestTipo=CAP_UG_ST then
   	strMessaggio:='Aggiornamento importi componenti a zero per capitoli di gestione nuovi : '
                  ||' cancellazione logica componenti a zero non utilizzate.';
    update siac_t_bil_elem_det_comp detCompCor
    set --elem_det_importo=0,
        data_cancellazione=clock_timestamp(),
        login_operazione=loginOperazione||'-CANC-COMP-ZERO'
    from  fase_bil_t_gest_apertura_provv fase,
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
          and   tipo.elem_tipo_code=CAP_UG_ST
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
    and   det.elem_id=fase.elem_prov_new_id
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


    strMessaggio:='Aggiornamento importi componenti a zero per capitoli di gestione esistenti : '
                  ||' cancellazione logica componenti a zero non utilizzate.';
    update siac_t_bil_elem_det_comp detCompCor
    set --elem_det_importo=0,
        data_cancellazione=clock_timestamp(),
        login_operazione=loginOperazione||'-CANC-COMP-ZERO'
    from  fase_bil_t_gest_apertura_provv fase,
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
          and   tipo.elem_tipo_code=CAP_UG_ST
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
    and   det.elem_id=fase.elem_prov_id
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
       fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_PROV_DA_GEST||' TERMINATA : AGGIORNAMENTO IMPORTI COMPLETATO.'
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

alter function siac.fnc_fasi_bil_provv_apertura_importi
(
   integer,
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