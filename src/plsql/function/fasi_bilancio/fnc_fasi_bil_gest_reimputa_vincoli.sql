/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_reimputa_vincoli (
  enteproprietarioid integer,
  annobilancio integer,
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

	tipoMovGestId      integer:=null;
    tipoMovGestAccId   integer:=null;

    movGestTsTipoId    integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;

    periodoId         integer:=null;
    periodoPrecId     integer:=null;

    movGestStatoAId   integer:=null;

    movGestRec        record;
    resultRec        record;

    faseBilElabId     integer;
	movGestTsRIdRet   integer;
    numeroVincAgg     integer:=0;


	faseBilElabReimpId integer;
    faseBilElabReAccId integer;

    movgestAccCurRiaccId integer;
    movgesttsAccCurRiaccId  integer;

	bCreaVincolo boolean;
    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


	IMP_MOVGEST_TIPO CONSTANT varchar:='I';
    ACC_MOVGEST_TIPO CONSTANT varchar:='A';


    APE_GEST_REIMP     CONSTANT varchar:='APE_GEST_REIMP';
    APE_GEST_REIMP_VINC     CONSTANT varchar:='APE_GEST_REIMP_VINC';


    A_MOV_GEST_STATO  CONSTANT varchar:='A';


BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;


	strMessaggioFinale:='Apertura bilancio gestione.Reimputazione vincoli. Anno bilancio='||annoBilancio::varchar||'.';

    strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_REIMP_VINC||' IN CORSO.';
    select 1 into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP_VINC
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito like 'IN%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
    if codResult is not null then
        strMessaggio :=' Esistenza elaborazione reimputazione vincoli in corso.';
    	raise exception ' Esistenza elaborazione reimputazione vincoli in corso.';
    	return;
    end if;


    strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
    fase_bil_elab_tipo_id,
    ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE REIMPUTAZIONE VINCOLI IN CORSO.',tipo.fase_bil_elab_tipo_id,ente_proprietario_id, dataElaborazione, loginOperazione
    from fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteproprietarioid
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP_VINC
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null)
    returning fase_bil_elab_id into faseBilElabId;

     if faseBilElabId is null then
        strMessaggio  :=' Inserimento elaborazione per tipo APE_GEST_REIMP_VINC non effettuato.';
     	raise exception ' Inserimento elaborazione per tipo APE_GEST_REIMP_VINC non effettuato.';
     	return;
    end if;

    codResult:=null;
    strMessaggio:='Inserimento LOG.';
    raise notice 'strMesasggio=%',strMessaggio;
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||' - INIZO.',clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    -- per I
    strMessaggio:='Lettura id identificativo per tipoMovGest='||IMP_MOVGEST_TIPO||'.';
    select tipo.movgest_tipo_id into tipoMovGestId
    from siac_d_movgest_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code=IMP_MOVGEST_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
    if tipoMovGestId is null then
	    strMessaggio :=strMessaggio||'- Errore in lettura identificativo';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - '||upper(strMessaggio),
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    end if;

	strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
    select bil.bil_id , per.periodo_id into bilancioPrecId, periodoPrecId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio-1
    and   bil.data_cancellazione is null
    and   per.data_cancellazione is null;
    if bilancioPrecId is null then
	    strMessaggio :=strMessaggio||'- Errore in lettura identificativo';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - '||upper(strMessaggio),
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    end if;

	codResult:=null;
    strMessaggio:='Verifica elaborazione fase='||APE_GEST_REIMP||' per impegni.';
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

  	codResult:=null;
    select fase.fase_bil_elab_id into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
         fase_bil_t_reimputazione fasereimp
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito='OK'
    and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
    and   fasereimp.movgest_tipo_id=tipoMovGestId
    and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
    and   fasereimp.bil_id=bilancioPrecId -- bilancio precedente per elaborazione reimputazione su annoBilancio
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null
    order by fase.fase_bil_elab_id desc
    limit 1;

    if codResult is null then
        strMessaggio :='Elaborazione non effettuabile - Reimputazione impegni non eseguita.';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - ELABORAZIONE REIMPUTAZIONE IMPEGNI NON ESEGUITA.',
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    else faseBilElabReimpId:=codResult;
    end if;


    -- per A
    strMessaggio:='Lettura id identificativo per tipoMovGest='||ACC_MOVGEST_TIPO||'.';
    select tipo.movgest_tipo_id into tipoMovGestAccId
    from siac_d_movgest_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code=ACC_MOVGEST_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
	if tipoMovGestAccId is null then
	    strMessaggio :=strMessaggio||'- Errore in lettura identificativo';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - '||upper(strMessaggio),
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    end if;

	codResult:=null;
    strMessaggio:='Verifica elaborazione fase='||APE_GEST_REIMP||' per accertamenti.';
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

    codResult:=null;
    select fase.fase_bil_elab_id into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
         fase_bil_t_reimputazione fasereimp
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito='OK'
    and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
    and   fasereimp.movgest_tipo_id=tipoMovGestAccId
    and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
    and   fasereimp.bil_id=bilancioPrecId -- bilancio precedente per elaborazione reimputazione su annoBilancio
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null
    order by fase.fase_bil_elab_id desc
    limit 1;

	if codResult is not null then
		 faseBilElabReaccId:=codResult;
    end if;



	strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
    select bil.bil_id , per.periodo_id into bilancioId, periodoId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio
    and   bil.data_cancellazione is null
    and   per.data_cancellazione is null;
	if bilancioId is null then
	    strMessaggio :=strMessaggio||'- Errore in lettura identificativo';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - '||upper(strMessaggio),
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    end if;

    strMessaggio:='Lettura id identificativo per movGestStatoA='||A_MOV_GEST_STATO||'.';
    select stato.movgest_stato_id into  movGestStatoAId
    from siac_d_movgest_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and   stato.movgest_stato_code=A_MOV_GEST_STATO
    and   stato.data_cancellazione is null
    and   stato.validita_fine is null;

	if movGestStatoAId is null then
	    strMessaggio :=strMessaggio||'- Errore in lettura identificativo';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - '||upper(strMessaggio),
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    end if;


    strMessaggio:='Inizio ciclo per elaborazione.';
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

     for movGestRec in
     (select  mov.movgest_anno::integer anno_impegno,
              mov.movgest_numero::integer numero_impegno,
              (case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) numero_subimpegno,
              fasevinc.movgest_ts_b_id,
              fasevinc.movgest_ts_a_id,
              fasevinc.movgest_ts_r_id,
              fasevinc.mod_id,
              fasevinc.importo_vincolo,
              fasevinc.avav_id,
              fasevinc.avav_new_id,
              fasevinc.importo_vincolo_new,
              mov.movgest_id,ts.movgest_ts_id,
              fasevinc.reimputazione_vinc_id
	  from siac_t_movgest mov ,
	       siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
	       siac_r_movgest_ts_stato rs,
	       fase_bil_t_reimputazione fase, fase_bil_t_reimputazione_vincoli fasevinc
	  where mov.bil_id=bilancioId
	  and   mov.movgest_tipo_id=tipoMovGestId
	  and   ts.movgest_id=mov.movgest_id
	  and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
	  and   rs.movgest_ts_id=ts.movgest_ts_id
      and   rs.movgest_stato_id!=movGestStatoAId
	  and   fase.fasebilelabid=faseBilElabReImpId
	  and   fase.movgestnew_ts_id=ts.movgest_ts_id
	  and   fase.movgest_tipo_id=mov.movgest_tipo_id
	  and   fase.fl_elab is not null and fase.fl_elab!=''
	  and   fase.fl_elab='S'
      and   fasevinc.fasebilelabid=fase.fasebilelabid
      and   fasevinc.reimputazione_id=fase.reimputazione_id
      and   fasevinc.fl_elab is null -- non elaborato e non scartato
      and   fasevinc.mod_tipo_code=fase.mod_tipo_code -- 09.0.2018 Sofia JIRA SIAC-6054
      and   fasevinc.reimputazione_anno=fase.mtdm_reimputazione_anno::integer -- 09.0.2018 Sofia JIRA SIAC-6054
      and   fasevinc.reimputazione_anno=mov.movgest_anno::integer -- 09.0.2018 Sofia JIRA SIAC-6054
	  and   rs.data_cancellazione is null
	  and   rs.validita_fine is null
	  and   mov.data_cancellazione is null
	  and   mov.validita_fine is null
	  and   ts.data_cancellazione is null
	  and   ts.validita_fine is null
      order by mov.movgest_anno::integer ,
               mov.movgest_numero::integer,
               (case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end),
               fasevinc.movgest_ts_b_id,
               coalesce(fasevinc.movgest_ts_a_id,0)
     )
     loop

        codResult:=null;
	    movgestAccCurRiaccId:=null;
	    movgesttsAccCurRiaccId :=null;
	    movGestTsRIdRet:=null;
		bCreaVincolo:=false;

        strMessaggio:='Impegno anno='||movGestRec.anno_impegno||
                      ' numero='||movGestRec.numero_impegno||
                      ' subnumero='||movGestRec.numero_subimpegno||
                      ' movgest_ts_new_id='||movGestRec.movgest_ts_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_b_id||
                      ' movgest_ts_r_id='||movGestRec.movgest_ts_r_id||
                      ' movgest_ts_a_id='||coalesce(movGestRec.movgest_ts_a_id,0)||'.';

        raise notice 'strMessaggio=%  movGestRec.movgest_new_id=%', strMessaggio, movGestRec.movgest_ts_id;
		insert into fase_bil_t_elaborazione_log
	    (fase_bil_elab_id,fase_bil_elab_log_operazione,
    	 validita_inizio, login_operazione, ente_proprietario_id
	    )
	    values
    	(faseBilElabId,strMessaggio||' - INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
	    returning fase_bil_elab_log_id into codResult;

	    if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	    end if;

        -- caso 1,2
		if movGestRec.movgest_ts_a_id is null then
            bCreaVincolo:=true;
        end if;

        /* caso 3
  		   se il vincolo abbattuto era legato ad un accertamento
		   che non presenta quote riaccertate esso stesso:
		   creare un vincolo nel nuovo bilancio di tipo FPV per la quote di vincolo abbattuta
		   con tipo spesa corrente o conto capitale in base al titolo di spesa dell'impegno (vedi algoritmo a seguire)
        */
        /* caso 4
		 se il vincolo abbattuto era legato ad un accertamento che presenta quote riaccertate:
		 creare un vincolo nel nuovo bilancio per la parte di vincolo abbattuta a capienza dell'utilizzabile
		 (utilizzabile - somma altri vincoli) del ogni nuovo acc. riaccertato con anno_accertamento<=anno_impegno
		 Per la restante parte creare un vincolo di tipo FPV con tipo spesa corrente o conto capitale in base al titolo di
		 spesa dell'impegno (vedi algoritmo a seguire) */
        if movGestRec.movgest_ts_a_id is not null then
            codResult:=null;
            strMessaggio:=strMessaggio||' - caso con accertamento verifica esistenza quota riacc.';
            raise notice 'strMessaggio=%',strMessaggio;
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

        	with
             accPrec as
             (
        	  select mov.movgest_anno::integer anno_accertamento,
              mov.movgest_numero::integer numero_accertamento,
              (case when tstipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) numero_subaccertamento,
              mov.movgest_id, ts.movgest_ts_id
              from siac_t_movgest mov, siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tstipo,
             	   siac_r_movgest_ts_stato rs
              where mov.bil_id=bilancioPrecId
              and   mov.movgest_tipo_id=tipoMovGestAccId
              and   ts.movgest_id=mov.movgest_id
              and   ts.movgest_ts_id=movGestRec.movgest_ts_a_id
              and   rs.movgest_ts_id=ts.movgest_ts_id
              and   rs.movgest_stato_id!=movGestStatoAId
              and   rs.data_cancellazione is null
              and   rs.validita_fine is null
              and   mov.data_cancellazione is null
              and   mov.validita_fine is null
              and   ts.data_cancellazione is null
              and   ts.validita_fine is null
             ),
             accCurRiacc as
             (
              select mov.movgest_anno::integer anno_accertamento,
	                 mov.movgest_numero::integer numero_accertamento,
       			    (case when tstipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) numero_subaccertamento,
	                mov.movgest_id movgest_new_id, ts.movgest_ts_id movgest_ts_new_id,fase.movgest_ts_id
              from siac_t_movgest mov, siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tstipo,
             	   siac_r_movgest_ts_stato rs, fase_bil_t_reimputazione fase
              where mov.bil_id=bilancioId
              and   mov.movgest_tipo_id=tipoMovGestAccId
              and   ts.movgest_id=mov.movgest_id
              and   rs.movgest_ts_id=ts.movgest_ts_id
              and   rs.movgest_stato_id!=movGestStatoAId
              and   fase.fasebilelabid=faseBilElabReAccId
              and   fase.fl_elab is not null and fase.fl_elab!=''
	    	  and   fase.fl_elab='S'
              and   ts.movgest_ts_id=fase.movgestnew_ts_id  -- nuovo accertamento riaccertato con anno_accertamento<=anno_impegno nuovo
              and   mov.movgest_anno::integer<=movGestRec.anno_impegno
              and   rs.data_cancellazione is null
              and   rs.validita_fine is null
              and   mov.data_cancellazione is null
              and   mov.validita_fine is null
              and   ts.data_cancellazione is null
              and   ts.validita_fine is null
             )
             select  accCurRiacc.movgest_new_id, accCurRiacc.movgest_ts_new_id
                     into movgestAccCurRiaccId, movgesttsAccCurRiaccId
             from accPrec, accCurRiacc
             where accPrec.movgest_ts_id=accCurRiacc.movgest_ts_id
             limit 1;


			 if movgestAccCurRiaccId is null or movgesttsAccCurRiaccId is null then
             	-- caso 3
                bCreaVincolo:=true;

             else
   	            codResult:=null;
	            strMessaggio:=strMessaggio||' - caso con accertamento e quota riacc.';
                            raise notice 'strMessaggio=%',strMessaggio;

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


                -- caso 4
                -- inserire nuovi vincoli con algoritmo descritto in JIRA per il caso 4
                --- vedere algoritmo
                /* caso 4
		 se il vincolo abbattuto era legato ad un accertamento che presenta quote riaccertate:
		 creare un vincolo nel nuovo bilancio per la parte di vincolo abbattuta a capienza dell'utilizzabile
		 (utilizzabile - somma altri vincoli) del ogni nuovo acc. riaccertato con anno_accertamento<=anno_impegno
		 Per la restante parte creare un vincolo di tipo FPV con tipo spesa corrente o conto capitale in base al titolo di
		 spesa dell'impegno (vedi algoritmo a seguire) */
               select * into resultRec
               from  fnc_fasi_bil_gest_reimputa_vincoli_acc
               (
				  enteProprietarioId,
				  annoBilancio,
				  faseBilElabId,
				  movGestRec.anno_impegno,        -- annoImpegnoRiacc integer,   -- annoImpegno riaccertato
				  movGestRec.movgest_ts_id,       -- movgestTsImpNewId integer,  -- movgest_id_id impegno riaccertato
				  movGestRec.avav_new_id,         -- avavRiaccImpId   integer,        -- avav_id nuovo
				  movGestRec.importo_vincolo_new, -- importoVincoloRiaccertato numeric, -- importo totale vincolo impegno riaccertato
				  faseBilElabReAccId,             -- faseId di elaborazione riaccertmaento Acc
				  tipoMovGestAccId,               -- tipoMovGestId Accertamenti
				  movGestRec.movgest_ts_a_id,     -- movgestTsAccPrecId integer, -- movgest_ts_id accertamento anno precedente vincolato a impegno riaccertato
				  loginOperazione,
				  dataElaborazione
                );
                if resultRec.codiceRisultato=0 then
                	numeroVincAgg:=numeroVincAgg+resultRec.numeroVincoliCreati;

                    strMessaggio:='Aggiornamento fase_bil_t_reimputazione_vincoli in fase di reimputazione nuovo vincolo.';
                	update fase_bil_t_reimputazione_vincoli fase
	                set    fl_elab='S',
    	                   movgest_ts_b_new_id=movGestRec.movgest_ts_id,
    --    	               movgest_ts_r_new_id=movGestTsRIdRet, non impostato poiche multiplo verso diversi accertamenti pluri
            	       	   bil_new_id=bilancioId
	            	where fase.reimputazione_vinc_id=movGestRec.reimputazione_vinc_id;
                else
                	strMessaggio:='Aggiornamento fase_bil_t_reimputazione_vincoli per scarto in fase di reimputazione nuovo vincolo.';
            		update fase_bil_t_reimputazione_vincoli fase
	                set    fl_elab='X',
			               movgest_ts_b_new_id=movGestRec.movgest_ts_id,
        	        	   bil_new_id=bilancioId,
	        	           scarto_code='99',
                	       scarto_desc='VINCOLO NUOVO NON CREATO IN FASE DI REIMPUTAZIONE'
	            	where fase.reimputazione_vinc_id=movGestRec.reimputazione_vinc_id;
                end if;
	         end if;

        end if;


	   if bCreaVincolo=true then
            codResult:=null;
            strMessaggio:=strMessaggio||' - inserimento vincolo senza accertamento vincolato.';
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


       		-- inserimento siac_t_movgest_ts_r nuovo con i dati presenti in fase_bil_t_reimputazione_vincoli
            -- aggiornamento di fase_bil_t_reimputazione_vincoli
            insert into siac_r_movgest_ts
            (
		        movgest_ts_b_id,
			    movgest_ts_importo,
                avav_id,
                validita_inizio,
                login_operazione,
                ente_proprietario_id
            )
            values
            (
            	movGestRec.movgest_ts_id,
                movGestRec.importo_vincolo_new,
                movGestRec.avav_new_id,
                clock_timestamp(),
                loginOperazione,
                enteProprietarioId
            )
            returning movgest_ts_r_id into movGestTsRIdRet;

            if movGestTsRIdRet is null then
            	strMessaggio:='Aggiornamento fase_bil_t_reimputazione_vincoli per scarto in fase di reimputazione nuovo vincolo.';
            	update fase_bil_t_reimputazione_vincoli fase
                set    fl_elab='X',
		               movgest_ts_b_new_id=movGestRec.movgest_ts_id,
                	   bil_new_id=bilancioId,
	                   scarto_code='99',
                       scarto_desc='VINCOLO NUOVO NON CREATO IN FASE DI REIMPUTAZIONE'
            	where fase.reimputazione_vinc_id=movGestRec.reimputazione_vinc_id;

            else
            	numeroVincAgg:=numeroVincAgg+1;
                strMessaggio:='Aggiornamento fase_bil_t_reimputazione_vincoli in fase di reimputazione nuovo vincolo.';
                update fase_bil_t_reimputazione_vincoli fase
                set    fl_elab='S',
                       movgest_ts_b_new_id=movGestRec.movgest_ts_id,
                       movgest_ts_r_new_id=movGestTsRIdRet,
                   	   bil_new_id=bilancioId
            	where fase.reimputazione_vinc_id=movGestRec.reimputazione_vinc_id;
            end if;

            --- 29.07.2019 Sofia SIAC-6702
            if movGestRec.movgest_ts_a_id is not null then
                codResult:=null;
                strMessaggio:='Impegno anno='||movGestRec.anno_impegno||
                      ' numero='||movGestRec.numero_impegno||
                      ' subnumero='||movGestRec.numero_subimpegno||
                      ' movgest_ts_new_id='||movGestRec.movgest_ts_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_b_id||
                      ' movgest_ts_r_id='||movGestRec.movgest_ts_r_id||
                      ' movgest_ts_a_id='||coalesce(movGestRec.movgest_ts_a_id,0)||
                      ' - inserimento vincolo senza accertamento vincolato - inserimento storico.';

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

            	insert into SIAC_R_MOVGEST_TS_STORICO_IMP_ACC
                (
                    movgest_ts_id,
                    movgest_anno_acc,
                    movgest_numero_acc,
                    movgest_subnumero_acc,
                    validita_inizio,
                    login_operazione,
                    ente_proprietario_id
                )
                select movGestRec.movgest_ts_id,
                       mov.movgest_anno::integer,
                       mov.movgest_numero::integer,
                       (case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end),
                       clock_timestamp(),
               		   loginOperazione,
	                   enteProprietarioId
                from siac_t_movgest mov , siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots
                where ts.movgest_ts_id=movGestRec.movgest_ts_a_id
                and   mov.movgest_id=ts.movgest_id
                and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                and   ts.data_cancellazione is null
                and   ts.validita_fine is null
                and   mov.data_cancellazione is null
                and   mov.validita_fine is null
                and   not exists
                (
                select 1 from SIAC_R_MOVGEST_TS_STORICO_IMP_ACC r
                where r.movgest_ts_id=ts.movgest_ts_id
                and   r.movgest_anno_acc=mov.movgest_anno::Integer
                and   r.movgest_numero_acc=mov.movgest_numero::integer
                and   r.movgest_subnumero_acc=(case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)
                and   r.data_cancellazione is null
                and   r.validita_fine is null
                );
            end if;
       end if;



       strMessaggio:='Impegno anno='||movGestRec.anno_impegno||
                      ' numero='||movGestRec.numero_impegno||
                      ' subnumero='||movGestRec.numero_subimpegno||
                      ' movgest_ts_new_id='||movGestRec.movgest_ts_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_b_id||
                      ' movgest_ts_r_id='||movGestRec.movgest_ts_r_id||
                      ' movgest_ts_a_id='||coalesce(movGestRec.movgest_ts_a_id,0)||'.';

        raise notice 'strMessaggio=%  movGestRec.movgest_new_id=%', strMessaggio, movGestRec.movgest_ts_id;
		insert into fase_bil_t_elaborazione_log
	    (fase_bil_elab_id,fase_bil_elab_log_operazione,
    	 validita_inizio, login_operazione, ente_proprietario_id
	    )
	    values
    	(faseBilElabId,strMessaggio||' - FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	    returning fase_bil_elab_log_id into codResult;

	    if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	    end if;

     end loop;



     strMessaggio:='Aggiornamento stato fase bilancio OK.';
     update fase_bil_t_elaborazione
     set fase_bil_elab_esito='OK',
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_REIMP_VINC||
                                 ' OK. INSERITI NUOVI VINCOLI NUM='||
                                 coalesce(numeroVincAgg,0)||'.'
     where fase_bil_elab_id=faseBilElabId;

     strMessaggio:='Aggiornamento fase_bil_elab_coll_id su elaborazione riacc. impegni.';
	 update fase_bil_t_elaborazione fase
     set    fase_bil_elab_coll_id=faseBilElabId,
            data_modifica=now()
     where fase.fase_bil_elab_id=faseBilElabReimpId;

     strMessaggio:='Aggiornamento fase_bil_elab_coll_id su elaborazione riacc. accertamenti.';
	 update fase_bil_t_elaborazione fase
     set    fase_bil_elab_coll_id=faseBilElabId,
            data_modifica=now()
     where fase.fase_bil_elab_id=faseBilElabReAccId;


     codiceRisultato:=0;
     messaggioRisultato:=strMessaggioFinale||' FINE';
     return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,coalesce(strMessaggio,'');
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;