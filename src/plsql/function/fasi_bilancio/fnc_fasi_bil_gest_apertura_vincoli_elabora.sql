/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_vincoli_elabora (
  enteproprietarioid integer,
  annobilancio integer,
  fasebilelabid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
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
    --- 26.06.2019 Sofia siac-6702
    bilancioId        integer:=null;
    numeroVincoliIns  integer:=null;

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

    --- 26.06.2019 Sofia siac-6702
    strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
    select bil.bil_id into strict bilancioId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio
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
    and   fase.movgest_ts_a_id is not null -- 06.12.2017 Sofia jira siac-5276
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
     avav_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    (select fase.movgest_ts_a_id,
            fase.movgest_ts_b_id,
            fase.importo_vinc,
            fase.avav_id, -- 06.12.2017 Sofia jira siac-5276
            --dataInizioVal,
            clock_timestamp(), -- 12.01.2018 Sofia
            loginOperazione||'_APE_VINC@'||fase.fase_bil_gest_ape_vinc_id::varchar, -- 06.12.2017 Sofia jira siac-5276
            enteProprietarioId
     from fase_bil_t_gest_apertura_vincoli fase
     where fase.fase_bil_elab_id=faseBilElabId
     and   fase.fl_elab='N'
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null
    );
    -- 29.07.2019 Sofia SIAC-6702
    GET DIAGNOSTICS numeroVincoliIns = ROW_COUNT;



    strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_vincoli.';
    update  fase_bil_t_gest_apertura_vincoli fase
    set    movgest_ts_r_id=r.movgest_ts_r_id,
           fl_elab='S'
    from  siac_r_movgest_ts r
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fl_elab='N'
    and   r.ente_proprietario_id=fase.ente_proprietario_id
    -- 06.12.2017 Sofia jira siac-5276
    and   r.login_operazione like '%_APE_VINC@%'
    and   substring(r.login_operazione , position('@' in r.login_operazione)+1)::integer=fase.fase_bil_gest_ape_vinc_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;


    strMessaggio:='Inserimento siac_r_movgest_ts. FINE.';
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

    -- 26.06.2019 Sofia SIAC-6702 - inizio
 --   if numeroVincoliIns is not null then

    -- inserire i rec. di storico per le relazioni tra impegni(anno_bilancio) e accertamenti,
    -- che esistono in anno_bilancio -1  e non esistono in anno_bilancio
    -- verificare se farlo se il ribaltamento dei vincoli e andato bene
    strMessaggio:='Inserimento SIAC_R_MOVGEST_TS_STORICO_IMP_ACC. INIZIO.';
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
    select query.movgest_ts_id,
           query.movgest_anno_acc,
           query.movgest_numero_acc,
           query.movgest_subnumero_acc,
           clock_timestamp(),
           loginOperazione,
           enteProprietarioId
    FROM
    (
    with
    impegni_cur as
    (
    select mov.movgest_anno::integer, mov.movgest_numero::integer,
           ( case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
           ts.movgest_ts_id
    from siac_t_movgest mov,siac_d_movgest_tipo tipo,siac_t_movgest_Ts ts,siac_d_movgest_ts_tipo tipots,
         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code='I'
    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
    and   mov.bil_id=bilancioId
    and   ts.movgest_id=mov.movgest_id
    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    ),
    impegni_prec as
    (
    select mov.movgest_anno::integer, mov.movgest_numero::integer,
           ( case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
           mov_a.movgest_anno::integer movgest_anno_acc, mov_a.movgest_numero::integer movgest_numero_acc,
           ( case when tipots_a.movgest_ts_tipo_code='T' then 0 else ts_a.movgest_ts_code::integer end ) movgest_subnumero_acc,
           ts.movgest_ts_id movgest_ts_b_id,
           ts_a.movgest_ts_id movgest_ts_a_id
    from siac_t_movgest mov,siac_d_movgest_tipo tipo,siac_t_movgest_Ts ts,siac_d_movgest_ts_tipo tipots,
         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_r_movgest_ts r,
         siac_t_movgest mov_a,siac_d_movgest_tipo tipo_a,siac_t_movgest_Ts ts_a,siac_d_movgest_ts_tipo tipots_a,
         siac_r_movgest_ts_stato rs_a,siac_d_movgest_stato stato_a
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code='I'
    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
    and   mov.bil_id=bilancioPrecId
    and   ts.movgest_id=mov.movgest_id
    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   r.movgest_ts_b_id=ts.movgest_ts_id
    and   ts_a.movgest_ts_id=r.movgest_ts_a_id
    and   mov_a.movgest_id=ts_a.movgest_id
    and   tipots_a.movgest_ts_tipo_id=ts_a.movgest_ts_tipo_id
    and   tipo_a.movgest_tipo_id=mov_a.movgest_tipo_id
    and   tipo_a.movgest_tipo_code='A'
    and   mov_a.bil_id=bilancioPrecId
    and   rs_a.movgest_ts_id=ts_a.movgest_ts_id
    and   stato_a.movgest_stato_id=rs_a.movgest_stato_id
    and   stato_a.movgest_stato_code!='A'
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   rs_a.data_cancellazione is null
    and   rs_a.validita_fine is null
    and   mov_a.data_cancellazione is null
    and   mov_a.validita_fine is null
    and   ts_a.data_cancellazione is null
    and   ts_a.validita_fine is null
    ),
    acc_cur as
    (
    select mov.movgest_anno::integer, mov.movgest_numero::integer,
           ( case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
           r.movgest_ts_a_id,
           r.movgest_ts_b_id
    from siac_t_movgest mov,siac_d_movgest_tipo tipo,siac_t_movgest_Ts ts,siac_d_movgest_ts_tipo tipots,
         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_r_movgest_ts r
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code='A'
    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
    and   mov.bil_id=bilancioId
    and   ts.movgest_id=mov.movgest_id
    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   r.movgest_ts_a_id=ts.movgest_ts_id
    and   r.movgest_ts_b_id is not null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    )
    select distinct
           impegni_cur.movgest_ts_id,
           impegni_prec.movgest_anno_acc,
           impegni_prec.movgest_numero_acc,
           impegni_prec.movgest_subnumero_acc
    from impegni_cur, impegni_prec
    where impegni_cur.movgest_anno=impegni_prec.movgest_anno
    and   impegni_cur.movgest_numero=impegni_prec.movgest_numero
    and   impegni_cur.movgest_subnumero=impegni_prec.movgest_subnumero
    and   not exists
    (select 1
     from acc_cur
     where acc_cur.movgest_ts_b_id=impegni_cur.movgest_ts_id
     and   acc_cur.movgest_anno=impegni_prec.movgest_anno_acc
     and   acc_cur.movgest_numero=impegni_prec.movgest_numero_acc
     and   acc_cur.movgest_subnumero=impegni_prec.movgest_subnumero_acc )
     ) query
     where
     not exists
     (select 1
      from SIAC_R_MOVGEST_TS_STORICO_IMP_ACC rStorico
      where rStorico.ente_proprietario_id=enteProprietarioId
      and   rStorico.movgest_ts_id=query.movgest_ts_id
      and   rStorico.movgest_anno_acc=query.movgest_anno_acc
      and   rStorico.movgest_numero_acc=query.movgest_numero_acc
      and   rStorico.movgest_subnumero_acc=query.movgest_subnumero_acc
      and   rStorico.data_cancellazione is null
      and   rStorico.validita_fine is null);


      strMessaggio:='Inserimento SIAC_R_MOVGEST_TS_STORICO_IMP_ACC. FINE.';
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
 --  end if:
   -- 26.06.2019 Sofia SIAC-6702 - fine


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