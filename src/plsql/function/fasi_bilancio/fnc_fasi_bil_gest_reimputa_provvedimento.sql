/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_reimputa_provvedimento
(
  enteProprietarioId     	integer,
  annoBilancio           	integer,
  loginOperazione        	varchar,
  p_dataElaborazione       	timestamp,
  p_movgest_tipo_code      	varchar,
  out outfaseBilElabRetId   integer,
  out codiceRisultato    	integer,
  out messaggioRisultato 	varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
	codResult          integer;

    APE_GEST_REIMP     CONSTANT varchar:='APE_GEST_REIMP';

	tipoMovGestId integer;
    bilancioPrecId integer;
    faseBilElabId integer;
    v_faseBilElabId integer;

BEGIN
	outfaseBilElabRetId:=null;
    codiceRisultato:=null;
    messaggioRisultato:=null;


    strMessaggioFinale:='Reimputazione impegni-accertamenti a partire anno ='||annoBilancio::varchar||'. Aggiornamento provvedimento e stato.';


    strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_REIMP||' IN CORSO.';
    select 1 into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito like 'IN%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
    if codResult is not null then
    	raise exception ' Esistenza elaborazione reimputazione in corso.';
    end if;


    strMessaggio:='Lettura tipo movimento='||p_movgest_tipo_code||'.';
    select tipo.movgest_tipo_id into tipoMovGestId
    from siac_d_movgest_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code=p_movgest_tipo_code;
    if tipoMovGestId  is null then
    	raise exception ' Identificativo non reperito.';
    end if;

    strMessaggio:='Lettura annoBilancio-1='||(annoBilancio-1)::varchar||'.';
    select bil.bil_id into bilancioPrecId
    from siac_t_bil bil , siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::integer=annoBilancio-1;
    if bilancioPrecId is null then
	  	raise exception ' Identificativo non reperito.';
    end if;

  	codResult:=null;
    strMessaggio:='Lettura identificativo elaborazione '||APE_GEST_REIMP||' per movimento di tipo='||p_movgest_tipo_code||'.';
    select fase.fase_bil_elab_id into faseBilElabId
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
    if faseBilElabId is null then
	 	raise exception ' Identificativo non reperito.';
    end if;

	codResult:=null;
    strMessaggio:=' Inizio.';
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

	codResult:=null;
    strMessaggio:='Aggiornamento stati operativi.';
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

    strMessaggio:='Aggiornamento stati operativi.Chiusura stato corrente.';
    v_faseBilElabId:=faseBilElabId;
	-- aggiornamento stati operativi
    -- chiusura stato precedente
    update siac_r_movgest_ts_stato rs
    set    validita_fine=clock_timestamp(),
           data_cancellazione=clock_timestamp(),
           login_operazione=rs.login_operazione||'-'||loginOperazione
    from fase_bil_t_reimputazione fase
    where fase.fasebilelabid=v_faseBilElabId
    and   fase.fl_elab is not null and fase.fl_elab='S'
    and   fase.bil_id=bilancioPrecId -- bilancio precedente per elaborazione reimputazione su annoBilancio
    and   rs.movgest_ts_id=fase.movgestnew_ts_id
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null;

    -- inserimento stato di origine
    strMessaggio:='Aggiornamento stati operativi.Inserimento stato da riaccertamento.';
    insert into siac_r_movgest_ts_stato
    (
    	movgest_ts_id,
        movgest_stato_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    select  fase.movgestnew_ts_id,
            fase.movgest_stato_id,
            clock_timestamp(),
            loginOperazione,
            enteProprietarioId
    from fase_bil_t_reimputazione fase
    where fase.fasebilelabid=v_faseBilElabId
    and   fase.fl_elab is not null and fase.fl_elab='S'
    and   fase.bil_id=bilancioPrecId; -- bilancio precedente per elaborazione reimputazione su annoBilancio


	codResult:=null;
    strMessaggio:='Aggiornamento provvedimenti.Inserimento stato da riaccertamento.';
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    --- inserimento provvedimento

    insert into siac_r_movgest_ts_atto_amm
    (
    	movgest_ts_id,
        attoamm_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    select fase.movgestnew_ts_id,
           fase.attoamm_id,
           clock_timestamp(),
           loginOperazione,
           enteProprietarioId
    from fase_bil_t_reimputazione fase
    where fase.fasebilelabid=v_faseBilElabId
    and   fase.fl_elab is not null and fase.fl_elab='S'
    and   fase.bil_id=bilancioPrecId -- bilancio precedente per elaborazione reimputazione su annoBilancio
    and   not exists
    (select 1
     from siac_r_movgest_ts_atto_amm r1
     where r1.movgest_ts_id=fase.movgestnew_ts_id
     and   r1.data_cancellazione is null
     and   r1.validita_fine is null
    );

	codResult:=null;
    strMessaggio:=' Fine.';
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;


    outfaseBilElabRetId:=faseBilElabId;
    codiceRisultato:=0;
    messaggioRisultato:=strMessaggioFinale||' FINE';

    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=faseBilElabId;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=faseBilElabId;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=faseBilElabId;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;