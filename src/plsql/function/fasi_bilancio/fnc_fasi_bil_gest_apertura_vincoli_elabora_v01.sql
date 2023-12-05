/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_vincoli_elabora(
  enteProprietarioId     integer,
  annoBilancio           integer,
  faseBilElabId          integer,
  loginOperazione        varchar,
  dataElaborazione       timestamp,
  out codiceRisultato    integer,
  out messaggioRisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio       VARCHAR(1500):='';
    strMessaggioTemp   VARCHAR(1000):='';
	strMessaggioFinale VARCHAR(1500):='';
	dataInizioVal      timestamp:=null;
	codResult          integer:=null;

    IMP_MOVGEST_TIPO  CONSTANT varchar:='I';
    ACC_MOVGEST_TIPO  CONSTANT varchar:='A';
    IMP_MOVGEST       CONSTANT varchar:='IMP';
    ACC_MOVGEST       CONSTANT varchar:='ACC';

    APE_GEST_VINCOLI    CONSTANT varchar:='APE_GEST_VINCOLI';

    bilancioPrecId    integer:=null;

BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;

    dataInizioVal:= clock_timestamp();

    strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento vincoli da Gestione precedente. Anno bilancio='
                        ||annoBilancio::varchar||'. ELABORA.';


    codResult:=null;
    strMessaggio:='Verifica stato fase_bil_t_elaborazione.';
    select 1  into codResult
    from fase_bil_t_elaborazione fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_elab_esito like 'IN-%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;
    if codResult is null then
      raise exception ' Nessuna elaborazione in corso [IN-n].';
    end if;


    codResult:=null;
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_vincoli.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_vincoli fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;
    if codResult is null then
      raise exception ' Nessun  vincolo da creare.';
    end if;


	strMessaggio:='Inserimento LOG.';
    codResult:=null;
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;


    strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
    select bil.bil_id into strict bilancioPrecId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio-1
    and   bil.data_cancellazione is null
    and   per.data_cancellazione is null;



    strMessaggio:='Verifica scarti per accertamento non esistente';
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

	update  fase_bil_t_gest_apertura_vincoli fase
    set    fl_elab='X',
           scarto_code='ACC',
           scarto_desc='ACCERTAMENTO NON ESISTENTE O NON VALIDO'
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fl_elab='N'
    and   not exists (select 1 from siac_t_movgest_ts ts, siac_r_movgest_ts_stato r, siac_d_movgest_stato stato
                      where ts.movgest_ts_id=fase.movgest_ts_a_id
                      and   r.movgest_ts_id=ts.movgest_ts_id
                      and   stato.movgest_stato_id=r.movgest_stato_id
                      and   stato.movgest_stato_code!='A'
                      and   r.data_cancellazione is null
                      and   r.validita_fine is null
                      and   ts.data_cancellazione is null
                      and   ts.validita_fine is null
                     )
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;

    strMessaggio:='Verifica scarti per impegno non esistente';
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


	update  fase_bil_t_gest_apertura_vincoli fase
    set    fl_elab='X',
           scarto_code='IMP',
           scarto_desc='IMPEGNO NON ESISTENTE O NON VALIDO'
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fl_elab='N'
    and   not exists (select 1 from siac_t_movgest_ts ts, siac_r_movgest_ts_stato r, siac_d_movgest_stato stato
                      where ts.movgest_ts_id=fase.movgest_ts_b_id
                      and   r.movgest_ts_id=ts.movgest_ts_id
                      and   stato.movgest_stato_id=r.movgest_stato_id
                      and   stato.movgest_stato_code!='A'
                      and   r.data_cancellazione is null
                      and   r.validita_fine is null
                      and   ts.data_cancellazione is null
                      and   ts.validita_fine is null
                     )
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;

    strMessaggio:='Inserimento siac_r_movgest_ts. INIZIO.';
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

	insert into siac_r_movgest_ts
    (
     movgest_ts_a_id,
     movgest_ts_b_id,
     movgest_ts_importo,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    (select fase.movgest_ts_a_id,
            fase.movgest_ts_b_id,
            fase.importo_vinc,
            dataInizioVal,
            loginOperazione,
            enteProprietarioId
     from fase_bil_t_gest_apertura_vincoli fase
     where fase.fase_bil_elab_id=faseBilElabId
     and   fase.fl_elab='N'
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null
    );

    strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_vincoli.';
    update  fase_bil_t_gest_apertura_vincoli fase
    set    movgest_ts_r_id=r.movgest_ts_r_id,
           fl_elab='S'
    from  siac_r_movgest_ts r
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fl_elab='N'
    and   r.movgest_ts_a_id=fase.movgest_ts_a_id
    and   r.movgest_ts_b_id=fase.movgest_ts_b_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;


    strMessaggio:='Inserimento siac_r_movgest_ts. INIZIO.';
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

    strMessaggio:='Aggiornamento stato fase bilancio IN-2.';
    update fase_bil_t_elaborazione
    set fase_bil_elab_esito='IN-2',
        fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_VINCOLI||' IN CORSO IN-2.'
    where fase_bil_elab_id=faseBilElabId;

    codResult:=null;
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;


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
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;