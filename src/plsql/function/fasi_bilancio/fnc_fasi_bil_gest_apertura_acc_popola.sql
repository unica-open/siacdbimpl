/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_acc_popola(
  enteProprietarioId     integer,
  annoBilancio           integer,
  loginOperazione        varchar,
  dataElaborazione       timestamp,
  out faseBilElabRetId   integer,
  out codiceRisultato    integer,
  out messaggioRisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;


    faseBilElabId     integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;

	faseOp            varchar(10):=null;

    ordStatoAId       INTEGER:=null;
    ordTsDetATipoId   integer:=null;
    bilElemStatoANId  integer:=null;
    movGestTsTTipoId  integer:=null;
    movGestTsSTipoId  integer:=null;
    movGestTipoId     integer:=null;

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


    APE_GEST_ACC_RES    CONSTANT varchar:='APE_GEST_ACC_RES';

    I_MOVGEST_TIPO     CONSTANT varchar:='I';
    A_MOVGEST_TIPO     CONSTANT varchar:='A';
	MOVGEST_TS_T_TIPO  CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO  CONSTANT varchar:='S';

    A_ORD_STATO  CONSTANT varchar:='A';
    A_ORD_TS_DET_TIPO CONSTANT varchar:='A';
    A_BIL_ELEM_STATO CONSTANT varchar:='AN';

    E_FASE            CONSTANT varchar:='E'; -- esercizio provvisorio
    G_FASE            CONSTANT varchar:='G'; -- gestione approvata

BEGIN
	faseBilElabRetId:=null;
    codiceRisultato:=null;
    messaggioRisultato:=null;

    dataInizioVal:= clock_timestamp();

	strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento accertamenti residui da Gestione precedente. Anno bilancio='||annoBilancio::varchar||'. POPOLA.';

    strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_ACC_RES||' IN CORSO.';
    select 1 into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_ACC_RES
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito like 'IN%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
    if codResult is not null then
    	raise exception ' Esistenza fase in corso.';
    end if;

    -- inserimento fase_bil_t_elaborazione
	strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
     fase_bil_elab_tipo_id,
     ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_ACC_RES||' IN CORSO.',
            tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
     from fase_bil_d_elaborazione_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.fase_bil_elab_tipo_code=APE_GEST_ACC_RES
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null)
     returning fase_bil_elab_id into faseBilElabId;

     if faseBilElabId is null then
     	raise exception ' Inserimento non effettuato.';
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


	 strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;


	 strMessaggio:='Verifica fase di bilancio di corrente.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
     if faseOp is null or faseOp not in (E_FASE,G_FASE) then
     	raise exception ' Il bilancio deve essere in fase % o %.',E_FASE,G_FASE;
     end if;

     strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioPrecId, periodoPrecId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio-1
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;


     strMessaggio:='Lettura id identificativo per ordStatoA='||A_ORD_STATO||'.';
     select stato.ord_stato_id into strict ordStatoAId
     from siac_d_ordinativo_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.ord_stato_code=A_ORD_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;


	 strMessaggio:='Lettura id identificativo per bilElemStatoANId='||A_BIL_ELEM_STATO||'.';
     select stato.elem_stato_id into strict bilElemStatoANId
     from siac_d_bil_elem_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.elem_stato_code=A_BIL_ELEM_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;

     strMessaggio:='Lettura id identificativo per ordTsDetATipo='||A_ORD_TS_DET_TIPO||'.';
     select tipo.ord_ts_det_tipo_id into strict ordTsDetATipoId
     from siac_d_ordinativo_ts_det_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.ord_ts_det_tipo_code=A_ORD_STATO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura id identificativo per movGestTsTTipo='||MOVGEST_TS_T_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict movGestTsTTipoId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_T_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura id identificativo per movGestTsSTipo='||MOVGEST_TS_S_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict movGestTsSTipoId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_S_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

  	 strMessaggio:='Lettura id identificativo per movGestTipo='||A_MOVGEST_TIPO||'.';
     select tipo.movgest_tipo_id into strict movGestTipoId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=A_MOVGEST_TIPO
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

     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_acc con dettaglio di incasso - INIZIO.';
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

     -- accertamenti con incassi
     -- accertato del padre - incassato di se stesso + tutti subaccertamenti

   	 insert into fase_bil_t_gest_apertura_acc
     (fase_bil_elab_id,
      movgest_ts_tipo,
      movgest_orig_id,
      movgest_orig_ts_id,
      imp_importo,
      imp_orig_importo,
      bil_orig_id,
      elem_orig_id,
      bil_id,
      ente_proprietario_id,
      login_operazione,
      validita_inizio
      )
      (select faseBilElabId,
              MOVGEST_TS_T_TIPO,
              mov.movgest_id,
              movts.movgest_ts_id,
              detm.movgest_ts_det_importo-fnc_siac_totale_ordinativi_inc_movgest(mov.movgest_id,null), -- imp_importo
              detm.movgest_ts_det_importo, -- imp_orig_importo
              mov.bil_id,
              re.elem_id,
              bilancioId,
			  mov.ente_proprietario_id,
              loginOperazione,
              clock_timestamp()
       from siac_t_bil bil,siac_t_movgest mov,siac_t_movgest_ts movts,
            siac_t_movgest_ts_det detm, siac_d_movgest_ts_det_tipo tipodetm,siac_r_movgest_bil_elem re
       where bil.bil_id=bilancioPrecId
       and   mov.bil_id=bil.bil_id
       and   mov.movgest_tipo_id=movGestTipoId
       and   mov.movgest_anno::INTEGER<annoBilancio -- devo escludere i pluriennali
       and   movts.movgest_id=mov.movgest_id
       and   movts.movgest_ts_tipo_id=movGestTsTTipoId
       and   re.movgest_id=mov.movgest_id
       and   detm.movgest_ts_id=movts.movgest_ts_id
       and   tipodetm.movgest_ts_det_tipo_id=detm.movgest_ts_det_tipo_id
       and   tipodetm.movgest_ts_det_tipo_code='A'
       and   exists ( select 1
                      from siac_t_movgest_ts ts1,  siac_r_ordinativo_ts_movgest_ts rm,
                           siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                           siac_r_ordinativo_stato rsord
                      where ts1.movgest_id=mov.movgest_id
                      and   rm.movgest_ts_id=ts1.movgest_ts_id
                      and   tsord.ord_ts_id=rm.ord_ts_id
                      and   ord.ord_id=tsord.ord_id
                      and   rsord.ord_id=ord.ord_id
                      and   rsord.ord_stato_id!=ordStatoAId
                      and   rm.data_cancellazione is null
                      and   rm.validita_fine is null
                      and   tsord.data_cancellazione is null
                      and   tsord.validita_fine is null
                      and   ord.data_cancellazione is null
                      and   ord.validita_fine is null
                      and   rsord.data_cancellazione is null
                      and   rsord.validita_fine is null
                      and   ts1.data_cancellazione is null
                      and   ts1.validita_fine is null)
       and   mov.data_cancellazione is null
       and   mov.validita_fine is null
       and   movts.data_cancellazione is null
       and   movts.validita_fine is null
       and   detm.data_cancellazione is null
       and   detm.validita_fine is null
       and   re.data_cancellazione is null
       and   re.validita_fine is null
       and detm.movgest_ts_det_importo-fnc_siac_totale_ordinativi_inc_movgest(mov.movgest_id,null)>0
       order by mov.movgest_anno::integer,mov.movgest_numero::integer
      );




     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_acc su accertamenti con dettaglio di incasso senza res vincolati - FINE.';
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


     -- accertamenti con dettagli di incasso completo ma vincolati
     -- accertato del padre - incassato di se stesso + tutti subaccertamenti

   	 insert into fase_bil_t_gest_apertura_acc
     (fase_bil_elab_id,
      movgest_ts_tipo,
      movgest_orig_id,
      movgest_orig_ts_id,
      imp_importo,
      imp_orig_importo,
      bil_orig_id,
      elem_orig_id,
      bil_id,
      ente_proprietario_id,
      login_operazione,
      validita_inizio
      )
      (select faseBilElabId,
              MOVGEST_TS_T_TIPO,
              mov.movgest_id,
              movts.movgest_ts_id,
              0, -- imp_importo
              detm.movgest_ts_det_importo, -- imp_orig_importo
              mov.bil_id,
              re.elem_id,
              bilancioId,
			  mov.ente_proprietario_id,
              loginOperazione,
              clock_timestamp()
       from siac_t_bil bil,siac_t_movgest mov,siac_t_movgest_ts movts,
            siac_t_movgest_ts_det detm, siac_d_movgest_ts_det_tipo tipodetm,siac_r_movgest_bil_elem re
       where bil.bil_id=bilancioPrecId
       and   mov.bil_id=bil.bil_id
       and   mov.movgest_tipo_id=movGestTipoId
       and   mov.movgest_anno::INTEGER<annoBilancio -- devo escludere i pluriennali
       and   movts.movgest_id=mov.movgest_id
       and   movts.movgest_ts_tipo_id=movGestTsTTipoId
       and   re.movgest_id=mov.movgest_id
       and   detm.movgest_ts_id=movts.movgest_ts_id
       and   tipodetm.movgest_ts_det_tipo_id=detm.movgest_ts_det_tipo_id
       and   tipodetm.movgest_ts_det_tipo_code='A'
       and   exists ( select 1
                      from siac_t_movgest_ts ts1,  siac_r_ordinativo_ts_movgest_ts rm,
                           siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                           siac_r_ordinativo_stato rsord
                      where ts1.movgest_id=mov.movgest_id
                      and   rm.movgest_ts_id=ts1.movgest_ts_id
                      and   tsord.ord_ts_id=rm.ord_ts_id
                      and   ord.ord_id=tsord.ord_id
                      and   rsord.ord_id=ord.ord_id
                      and   rsord.ord_stato_id!=ordStatoAId
                      and   rm.data_cancellazione is null
                      and   rm.validita_fine is null
                      and   tsord.data_cancellazione is null
                      and   tsord.validita_fine is null
                      and   ord.data_cancellazione is null
                      and   ord.validita_fine is null
                      and   rsord.data_cancellazione is null
                      and   rsord.validita_fine is null
                      and   ts1.data_cancellazione is null
                      and   ts1.validita_fine is null)
       and exists ( select 1
				    from siac_r_movgest_ts r,
                         siac_t_movgest impprec, siac_t_movgest_ts tsimpprec,
                         siac_t_movgest imp, siac_t_movgest_ts tsimp,siac_d_movgest_tipo tipoimp,
                         siac_r_movgest_ts_stato rsimp, siac_d_movgest_stato statoimp
                    where r.movgest_ts_a_id=movts.movgest_ts_id
                    and   tsimpprec.movgest_ts_id=r.movgest_ts_b_id
                    and   impprec.movgest_id=tsimpprec.movgest_id
                    and   impprec.bil_id=mov.bil_id
                    and   tipoimp.movgest_tipo_id=impprec.movgest_tipo_id
                    and   tipoimp.movgest_tipo_code=I_MOVGEST_TIPO
                    and   imp.bil_id=bilancioId
                    and   imp.movgest_anno=impprec.movgest_anno
                    and   imp.movgest_numero=impprec.movgest_numero
                    and   imp.movgest_tipo_id=impprec.movgest_tipo_id
                    and   imp.movgest_id=tsimp.movgest_id
                    and   rsimp.movgest_ts_id=tsimp.movgest_ts_id
                    and   statoimp.movgest_stato_id=rsimp.movgest_stato_id
                    and   statoimp.movgest_stato_code!='A'
                    and   r.data_cancellazione is null
                    and   r.validita_fine is null
                    and   imp.data_cancellazione is null
                    and   imp.validita_fine is null
                    and   tsimp.data_cancellazione is null
                    and   tsimp.validita_fine is null
                    and   rsimp.data_cancellazione is null
                    and   rsimp.validita_fine is null
                    and   impprec.data_cancellazione is null
                    and   impprec.validita_fine is null
                    and   tsimpprec.data_cancellazione is null
                    and   tsimpprec.validita_fine is null
                   )
       and   mov.data_cancellazione is null
       and   mov.validita_fine is null
       and   movts.data_cancellazione is null
       and   movts.validita_fine is null
       and   detm.data_cancellazione is null
       and   detm.validita_fine is null
       and   re.data_cancellazione is null
       and   re.validita_fine is null
       and detm.movgest_ts_det_importo-fnc_siac_totale_ordinativi_inc_movgest(mov.movgest_id,null)=0
       order by mov.movgest_anno::integer,mov.movgest_numero::integer
      );




     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_acc su accertamenti con dettaglio di incasso senza res vincolati - FINE.';
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



     -- accertamenti senza incassi
     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_acc accertamenti senza dettaglio di incasso - INIZIO.';
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

   	 insert into fase_bil_t_gest_apertura_acc
     (fase_bil_elab_id,
      movgest_ts_tipo,
      movgest_orig_id,
      movgest_orig_ts_id,
      imp_importo,
      imp_orig_importo,
      bil_orig_id,
      elem_orig_id,
      bil_id,
      ente_proprietario_id,
      login_operazione,
      validita_inizio
      )
      (select faseBilElabId,
              MOVGEST_TS_T_TIPO,
              mov.movgest_id,
              movts.movgest_ts_id,
              detm.movgest_ts_det_importo, -- imp_importo
              detm.movgest_ts_det_importo, -- imp_orig_importo
              mov.bil_id,
              re.elem_id,
              bilancioId,
			  mov.ente_proprietario_id,
              loginOperazione,
              clock_timestamp()
       from siac_t_bil bil,siac_t_movgest mov,siac_t_movgest_ts movts,
            siac_t_movgest_ts_det detm, siac_d_movgest_ts_det_tipo tipodetm,
            siac_r_movgest_bil_elem re
       where bil.bil_id=bilancioPrecId
       and   mov.bil_id=bil.bil_id
       and   mov.movgest_tipo_id=movGestTipoId
       and   mov.movgest_anno::INTEGER<annoBilancio -- devo escludere i pluriennali
       and   re.movgest_id=mov.movgest_id
       and   movts.movgest_id=mov.movgest_id
       and   movts.movgest_ts_tipo_id=movGestTsTTipoId
       and   detm.movgest_ts_id=movts.movgest_ts_id
       and   tipodetm.movgest_ts_det_tipo_id=detm.movgest_ts_det_tipo_id
       and   tipodetm.movgest_ts_det_tipo_code='A'
       and   not exists (select 1 -- non esistono ordinativi su accertamento / sub
                         from siac_r_ordinativo_ts_movgest_ts rm, siac_t_movgest_ts ts1,
                              siac_t_ordinativo_ts ts, siac_t_ordinativo ord,
				              siac_r_ordinativo_stato rord
                         where ts1.movgest_id=mov.movgest_id
	                       and rm.movgest_ts_id=ts1.movgest_ts_id
					       and ts.ord_ts_id=rm.ord_ts_id
					       and ord.ord_id=ts.ord_id
					       and rord.ord_id=ord.ord_id
					       and rord.ord_stato_id!=ordStatoAId
                           and rm.data_cancellazione is null
				           and rm.validita_fine is null
					       and ts.data_cancellazione is null
					       and ts.validita_fine is null
					       and ord.data_cancellazione is null
					       and ord.validita_fine is null
					       and rord.data_cancellazione is null
						   and rord.validita_fine is null
                           and  ts1.data_cancellazione is null
						   and  ts1.validita_fine is null
                        )
        and   exists ( select 1 from siac_r_movgest_ts_stato rstato, siac_d_movgest_stato stato
                      where rstato.movgest_ts_id=movts.movgest_ts_id
                      and   stato.movgest_stato_id=rstato.movgest_stato_id
                      and   stato.movgest_stato_code not in ('A','P')
                      and   rstato.data_cancellazione is null
                      and   rstato.validita_fine is null
                    )
       and   mov.data_cancellazione is null
       and   mov.validita_fine is null
       and   movts.data_cancellazione is null
       and   movts.validita_fine is null
       and   detm.data_cancellazione is null
       and   detm.validita_fine is null
       and   re.data_cancellazione is null
       and   re.validita_fine is null
       order by mov.movgest_anno::integer,mov.movgest_numero::integer
      );




     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_acc su accertamenti senza dettaglio di incasso - FINE.';
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


     ---  subccertamenti
     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_acc subccertamenti con dettaglio di incasso - INIZIO.';
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


   	 insert into fase_bil_t_gest_apertura_acc
     (fase_bil_elab_id,
      movgest_ts_tipo,
      movgest_orig_id,
      movgest_orig_ts_id,
      imp_importo,
      imp_orig_importo,
      bil_orig_id,
      elem_orig_id,
      bil_id,
      ente_proprietario_id,
      login_operazione,
      validita_inizio
      )
      (select faseBilElabId,
              MOVGEST_TS_S_TIPO,
              mov.movgest_id,
              movts.movgest_ts_id,
              detm.movgest_ts_det_importo-sum(det.ord_ts_det_importo), -- imp_importo
              detm.movgest_ts_det_importo, -- imp_orig_importo
              mov.bil_id,
              re.elem_id,
              bilancioId,
			  mov.ente_proprietario_id,
              loginOperazione,
              clock_timestamp()
       from siac_t_bil bil,siac_t_movgest mov,siac_t_movgest_ts movts,
            siac_t_movgest_ts_det detm, siac_d_movgest_ts_det_tipo tipodetm,
            siac_r_ordinativo_ts_movgest_ts rm,siac_t_ordinativo_ts ts, siac_t_ordinativo ord,
            siac_r_ordinativo_stato rord, siac_t_ordinativo_ts_det det, siac_r_movgest_bil_elem re
       where bil.bil_id=bilancioPrecId
       and   mov.bil_id=bil.bil_id
       and   mov.movgest_tipo_id=movGestTipoId
       and   mov.movgest_anno::INTEGER<annoBilancio -- devo escludere i pluriennali
       and   movts.movgest_id=mov.movgest_id
       and   movts.movgest_ts_tipo_id=movGestTsSTipoId
       and   re.movgest_id=mov.movgest_id
       and   detm.movgest_ts_id=movts.movgest_ts_id
       and   tipodetm.movgest_ts_det_tipo_id=detm.movgest_ts_det_tipo_id
       and   tipodetm.movgest_ts_det_tipo_code='A'
       and   rm.movgest_ts_id=movts.movgest_ts_id
       and   ts.ord_ts_id=rm.ord_ts_id
       and   ord.ord_id=ts.ord_id
       and   rord.ord_id=ord.ord_id
       and   rord.ord_stato_id!=ordStatoAId
       and   det.ord_ts_id=ts.ord_ts_id
       and   det.ord_ts_det_tipo_id=ordTsDetATipoId
       and   exists (select 1 from fase_bil_t_gest_apertura_acc fase1
                     where fase1.fase_bil_elab_id=faseBilElabId
                     and   fase1.movgest_ts_tipo=MOVGEST_TS_T_TIPO
                     and   fase1.movgest_orig_id=mov.movgest_id
                     and   fase1.fl_elab='N'
                     and   fase1.data_cancellazione is null
                     and   fase1.validita_fine is null
                    )
       and   mov.data_cancellazione is null
       and   mov.validita_fine is null
       and   movts.data_cancellazione is null
       and   movts.validita_fine is null
       and   rm.data_cancellazione is null
       and   rm.validita_fine is null
       and   ts.data_cancellazione is null
       and   ts.validita_fine is null
       and   ord.data_cancellazione is null
       and   ord.validita_fine is null
       and   rord.data_cancellazione is null
       and   rord.validita_fine is null
       and   det.data_cancellazione is null
       and   det.validita_fine is null
       and   detm.data_cancellazione is null
       and   detm.validita_fine is null
       and   re.data_cancellazione is null
       and   re.validita_fine is null
       group by faseBilElabId,
                MOVGEST_TS_S_TIPO,
                mov.movgest_id,
                movts.movgest_ts_id,
                detm.movgest_ts_det_importo,
                mov.bil_id,
                re.elem_id,
                bilancioId,
   			    mov.ente_proprietario_id
       having detm.movgest_ts_det_importo-sum(det.ord_ts_det_importo)>0
       order by mov.movgest_anno::integer,mov.movgest_numero::integer,movts.movgest_ts_code::integer
      );




     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_acc su subccertamenti con dettaglio di incasso  - FINE.';
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

     -- subaccertamenti con dettaglio di incasso res vincolati
     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_acc subccertamenti con dettaglio di incasso senza res vincolato - INIZIO.';
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


   	 insert into fase_bil_t_gest_apertura_acc
     (fase_bil_elab_id,
      movgest_ts_tipo,
      movgest_orig_id,
      movgest_orig_ts_id,
      imp_importo,
      imp_orig_importo,
      bil_orig_id,
      elem_orig_id,
      bil_id,
      ente_proprietario_id,
      login_operazione,
      validita_inizio
      )
      (select faseBilElabId,
              MOVGEST_TS_S_TIPO,
              mov.movgest_id,
              movts.movgest_ts_id,
              0, -- imp_importo
              detm.movgest_ts_det_importo, -- imp_orig_importo
              mov.bil_id,
              re.elem_id,
              bilancioId,
			  mov.ente_proprietario_id,
              loginOperazione,
              clock_timestamp()
       from siac_t_bil bil,siac_t_movgest mov,siac_t_movgest_ts movts,
            siac_t_movgest_ts_det detm, siac_d_movgest_ts_det_tipo tipodetm,
            siac_r_ordinativo_ts_movgest_ts rm,siac_t_ordinativo_ts ts, siac_t_ordinativo ord,
            siac_r_ordinativo_stato rord, siac_t_ordinativo_ts_det det, siac_r_movgest_bil_elem re
       where bil.bil_id=bilancioPrecId
       and   mov.bil_id=bil.bil_id
       and   mov.movgest_tipo_id=movGestTipoId
       and   mov.movgest_anno::INTEGER<annoBilancio -- devo escludere i pluriennali
       and   movts.movgest_id=mov.movgest_id
       and   movts.movgest_ts_tipo_id=movGestTsSTipoId
       and   re.movgest_id=mov.movgest_id
       and   detm.movgest_ts_id=movts.movgest_ts_id
       and   tipodetm.movgest_ts_det_tipo_id=detm.movgest_ts_det_tipo_id
       and   tipodetm.movgest_ts_det_tipo_code='A'
       and   rm.movgest_ts_id=movts.movgest_ts_id
       and   ts.ord_ts_id=rm.ord_ts_id
       and   ord.ord_id=ts.ord_id
       and   rord.ord_id=ord.ord_id
       and   rord.ord_stato_id!=ordStatoAId
       and   det.ord_ts_id=ts.ord_ts_id
       and   det.ord_ts_det_tipo_id=ordTsDetATipoId
       and   exists (select 1 from fase_bil_t_gest_apertura_acc fase1
                     where fase1.fase_bil_elab_id=faseBilElabId
                     and   fase1.movgest_ts_tipo=MOVGEST_TS_T_TIPO
                     and   fase1.movgest_orig_id=mov.movgest_id
                     and   fase1.fl_elab='N'
                     and   fase1.data_cancellazione is null
                     and   fase1.validita_fine is null
                    )
       and exists ( select 1
				    from siac_r_movgest_ts r,
	                     siac_t_movgest impprec, siac_t_movgest_ts tsimpprec,
                         siac_t_movgest imp, siac_t_movgest_ts tsimp,siac_d_movgest_tipo tipoimp,
                         siac_r_movgest_ts_stato rsimp, siac_d_movgest_stato statoimp
                    where r.movgest_ts_a_id=movts.movgest_ts_id
                    and   tsimpprec.movgest_ts_id=r.movgest_ts_b_id
                    and   impprec.movgest_id=tsimpprec.movgest_id
                    and   impprec.bil_id=mov.bil_id
                    and   tipoimp.movgest_tipo_id=impprec.movgest_tipo_id
                    and   tipoimp.movgest_tipo_code=I_MOVGEST_TIPO
                    and   imp.bil_id=bilancioId
                    and   imp.movgest_anno=impprec.movgest_anno
                    and   imp.movgest_numero=impprec.movgest_numero
                    and   imp.movgest_tipo_id=impprec.movgest_tipo_id
                    and   imp.movgest_id=tsimp.movgest_id
                    and   rsimp.movgest_ts_id=tsimp.movgest_ts_id
                    and   statoimp.movgest_stato_id=rsimp.movgest_stato_id
                    and   statoimp.movgest_stato_code!='A'
                    and   r.data_cancellazione is null
                    and   r.validita_fine is null
                    and   imp.data_cancellazione is null
                    and   imp.validita_fine is null
                    and   tsimp.data_cancellazione is null
                    and   tsimp.validita_fine is null
                    and   rsimp.data_cancellazione is null
                    and   rsimp.validita_fine is null
                    and   impprec.data_cancellazione is null
                    and   impprec.validita_fine is null
                    and   tsimpprec.data_cancellazione is null
                    and   tsimpprec.validita_fine is null
                   )
       and   mov.data_cancellazione is null
       and   mov.validita_fine is null
       and   movts.data_cancellazione is null
       and   movts.validita_fine is null
       and   rm.data_cancellazione is null
       and   rm.validita_fine is null
       and   ts.data_cancellazione is null
       and   ts.validita_fine is null
       and   ord.data_cancellazione is null
       and   ord.validita_fine is null
       and   rord.data_cancellazione is null
       and   rord.validita_fine is null
       and   det.data_cancellazione is null
       and   det.validita_fine is null
       and   detm.data_cancellazione is null
       and   detm.validita_fine is null
       and   re.data_cancellazione is null
       and   re.validita_fine is null
       group by faseBilElabId,
                MOVGEST_TS_S_TIPO,
                mov.movgest_id,
                movts.movgest_ts_id,
                detm.movgest_ts_det_importo,
                mov.bil_id,
                re.elem_id,
                bilancioId,
   			    mov.ente_proprietario_id
       having detm.movgest_ts_det_importo-sum(det.ord_ts_det_importo)=0
       order by mov.movgest_anno::integer,mov.movgest_numero::integer,movts.movgest_ts_code::integer
      );




     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_acc su subccertamenti con dettaglio di incasso senza res vincolati - FINE.';
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
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_acc subccertamenti senza dettaglio di incasso - INIZIO.';
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



   	 insert into fase_bil_t_gest_apertura_acc
     (fase_bil_elab_id,
      movgest_ts_tipo,
      movgest_orig_id,
      movgest_orig_ts_id,
      imp_importo,
      imp_orig_importo,
      bil_orig_id,
      elem_orig_id,
      bil_id,
      ente_proprietario_id,
      login_operazione,
      validita_inizio
      )
      (select faseBilElabId,
              MOVGEST_TS_S_TIPO,
              mov.movgest_id,
              movts.movgest_ts_id,
              detm.movgest_ts_det_importo, -- imp_importo
              detm.movgest_ts_det_importo, -- imp_orig_importo
              mov.bil_id,
              re.elem_id,
              bilancioId,
			  mov.ente_proprietario_id,
              loginOperazione,
              clock_timestamp()
       from siac_t_bil bil,siac_t_movgest mov,siac_t_movgest_ts movts,
            siac_t_movgest_ts_det detm, siac_d_movgest_ts_det_tipo tipodetm,
            siac_r_movgest_bil_elem re
       where bil.bil_id=bilancioPrecId
       and   mov.bil_id=bil.bil_id
       and   mov.movgest_tipo_id=movGestTipoId
       and   mov.movgest_anno::INTEGER<annoBilancio -- devo escludere i pluriennali
       and   re.movgest_id=mov.movgest_id
       and   movts.movgest_id=mov.movgest_id
       and   movts.movgest_ts_tipo_id=movGestTsSTipoId
       and   detm.movgest_ts_id=movts.movgest_ts_id
       and   tipodetm.movgest_ts_det_tipo_id=detm.movgest_ts_det_tipo_id
       and   tipodetm.movgest_ts_det_tipo_code='A'
       and   not exists (select 1
                         from siac_r_ordinativo_ts_movgest_ts rm,siac_t_ordinativo_ts ts, siac_t_ordinativo ord,
				              siac_r_ordinativo_stato rord
                         where rm.movgest_ts_id=movts.movgest_ts_id
					       and ts.ord_ts_id=rm.ord_ts_id
					       and ord.ord_id=ts.ord_id
					       and rord.ord_id=ord.ord_id
					       and rord.ord_stato_id!=ordStatoAId
					       and ts.data_cancellazione is null
					       and ts.validita_fine is null
					       and ord.data_cancellazione is null
					       and ord.validita_fine is null
					       and rord.data_cancellazione is null
						   and rord.validita_fine is null
                           and rm.data_cancellazione is null
						   and rm.validita_fine is null
                        )
	  and   exists ( select 1 from siac_r_movgest_ts_stato rstato, siac_d_movgest_stato stato
                      where rstato.movgest_ts_id=movts.movgest_ts_id
                      and   stato.movgest_stato_id=rstato.movgest_stato_id
                      and   stato.movgest_stato_code not in ('A','P')
                      and   rstato.data_cancellazione is null
                      and   rstato.validita_fine is null
                    )
       and   exists (select 1 from fase_bil_t_gest_apertura_acc fase1
                     where fase1.fase_bil_elab_id=faseBilElabId
                     and   fase1.movgest_ts_tipo=MOVGEST_TS_T_TIPO
                     and   fase1.movgest_orig_id=mov.movgest_id
                     and   fase1.fl_elab='N'
                     and   fase1.data_cancellazione is null
                     and   fase1.validita_fine is null
                    )
       and   mov.data_cancellazione is null
       and   mov.validita_fine is null
       and   movts.data_cancellazione is null
       and   movts.validita_fine is null
       and   detm.data_cancellazione is null
       and   detm.validita_fine is null
       and   re.data_cancellazione is null
       and   re.validita_fine is null
       order by mov.movgest_anno::integer,mov.movgest_numero::integer,movts.movgest_ts_code::integer
      );




     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_acc su subccertamenti senza dettaglio di incasso  - FINE.';
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

     --- fine subccertamenti
     codResult:=null;
	 strMessaggio:='Verifica inserimento dati in fase_bil_t_gest_apertura_liq_imp.';
	 select  1 into codResult
     from fase_bil_t_gest_apertura_acc liq
     where liq.fase_bil_elab_id=faseBilElabId
     and   liq.movgest_orig_id is not null
     and   liq.movgest_orig_ts_id is not null
     and   liq.elem_orig_id is not null
     and   liq.data_cancellazione is null
     and   liq.validita_fine is null;

     if codResult is null then
     	raise exception ' Nessun inserimento effettuato.';
     end if;

	 codResult:=null;
     strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_acc accertamenti/subccertamenti per estremi movimento gestione prec - FINE.';
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

     --- gestione scarti per capitolo non esistente in nuovo bilancio
     codResult:=null;
     strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_acc per scarto accertamenti relativi a capitolo non presente in nuovo bilancio - INIZIO.';
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


     update fase_bil_t_gest_apertura_acc acc
     set  scarto_code='CAP',
          scarto_desc='Capitolo non presente in bilancio di gestione corrente',
          fl_elab='X'
     from siac_t_bil_elem eprec
     where acc.fase_bil_elab_id=faseBilElabId
     and   eprec.elem_id=acc.elem_orig_id
     and   not exists (select 1
                       from siac_t_bil_elem e, siac_r_bil_elem_stato r
				       where   e.bil_id=bilancioId
					     and   e.elem_code=eprec.elem_code
					     and   e.elem_code2=eprec.elem_code2
					     and   e.elem_code3=eprec.elem_code3
					     and   e.elem_tipo_id=eprec.elem_tipo_id
					     and   r.elem_id=e.elem_id
					     and   r.elem_stato_id!=bilElemStatoANId
					     and   r.data_cancellazione is null
					     and   r.validita_fine is null
					     and   e.data_cancellazione is null
					     and   e.validita_fine is null
                      )
     and   acc.data_cancellazione is null
     and   acc.validita_fine is null
     and   eprec.data_cancellazione is null
	 and   eprec.validita_fine is null;



     codResult:=null;
     strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_acc per scarto accertamenti capitolo non presente in nuovo bilancio - FINE.';
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
     strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_acc identificativo elemento di bilancio corrente - INIZIO.';
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


     update fase_bil_t_gest_apertura_acc acc
     set  elem_id=e.elem_id
     from siac_t_bil_elem eprec, siac_t_bil_elem e, siac_r_bil_elem_stato r
     where acc.fase_bil_elab_id=faseBilElabId
     and   acc.fl_elab='N'
     and   eprec.elem_id=acc.elem_orig_id
     and   e.bil_id=bilancioId
     and   e.elem_code=eprec.elem_code
     and   e.elem_code2=eprec.elem_code2
     and   e.elem_code3=eprec.elem_code3
     and   e.elem_tipo_id=eprec.elem_tipo_id
     and   r.elem_id=e.elem_id
     and   r.elem_stato_id!=bilElemStatoANId
     and   r.data_cancellazione is null
     and   r.validita_fine is null
     and   e.data_cancellazione is null
     and   e.validita_fine is null
     and   acc.data_cancellazione is null
     and   acc.validita_fine is null
     and   eprec.data_cancellazione is null
	 and   eprec.validita_fine is null;

	 select  1 into codResult
     from fase_bil_t_gest_apertura_acc acc
     where acc.fase_bil_elab_id=faseBilElabId
     and   acc.fl_elab='N'
     and   acc.elem_id is null
     and   acc.data_cancellazione is null
     and   acc.validita_fine is null;

     if codResult is not null then
     	raise exception ' Non riuscito per accertamenti presenti in fase_bil_t_gest_apertura_acc.';
     end if;


     codResult:=null;
     strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_acc identificativo elemento di bilancio corrente - FINE.';
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


     strMessaggio:='Aggiornamento stato fase bilancio IN-1.';
     update fase_bil_t_elaborazione fase
     set fase_bil_elab_esito='IN-1',
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_ACC_RES||' IN CORSO IN-2.POPOLA ACCERTAMENTI.'
     where fase.fase_bil_elab_id=faseBilElabId;


     faseBilElabRetId:=faseBilElabId;
     codiceRisultato:=0;
     messaggioRisultato:=strMessaggioFinale||' FINE';
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