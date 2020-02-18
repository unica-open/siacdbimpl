/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop FUNCTION fnc_fasi_bil_gest_apertura_liq_popola(
  enteProprietarioId     integer,
  annoBilancio           integer,
  faseBilElabId          integer,
  loginOperazione        varchar,
  dataElaborazione       timestamp,
  out faseBilElabRetId   integer,
  out codiceRisultato    integer,
  out messaggioRisultato varchar
);

CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_liq_popola(
  enteProprietarioId     integer,
  annoBilancio           integer,
  faseBilElabInId          integer,
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
    liqStatoAId       INTEGER:=null;
    ordStatoAId       INTEGER:=null;
    ordTsDetATipoId   integer:=null;
    bilElemStatoANId  integer:=null;
    movGestTsTTipoId  integer:=null;
    movGestTsSTipoId  integer:=null;

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


    APE_GEST_LIQ_RES    CONSTANT varchar:='APE_GEST_LIQ_RES';

	MOVGEST_TS_T_TIPO  CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO  CONSTANT varchar:='S';

    A_LIQ_STATO  CONSTANT varchar:='A';
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

	strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento liquidazioni residue da Gestione precedente. Anno bilancio='||annoBilancio::varchar||'. POPOLA.';

    if faseBilElabInId is null then
     strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_LIQ_RES||' IN CORSO.';
     select 1 into codResult
     from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.fase_bil_elab_tipo_code=APE_GEST_LIQ_RES
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
     (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_LIQ_RES||' IN CORSO.',
             tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
      from fase_bil_d_elaborazione_tipo tipo
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.fase_bil_elab_tipo_code=APE_GEST_LIQ_RES
      and   tipo.data_cancellazione is null
      and   tipo.validita_fine is null)
      returning fase_bil_elab_id into faseBilElabId;

      if faseBilElabId is null then
     	raise exception ' Inserimento non effettuato.';
      end if;

      codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggioFinale||strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;



   else


	 faseBilElabId:=faseBilElabInId;

     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggioFinale||strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

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
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_liq_imp.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_liq_imp fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   fase.fl_elab in ('N','I');
    if codResult is null then
      raise exception ' Nessun movimento per liquidazione da creare.';
    end if;

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

	 strMessaggio:='Lettura id identificativo per liqStatoA='||A_LIQ_STATO||'.';
     select stato.liq_stato_id into strict liqStatoAId
     from siac_d_liquidazione_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.liq_stato_code=A_LIQ_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;

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
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq liquidazioni con dettaglio di pagamento su impegni - INIZIO.';
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


   	 insert into fase_bil_t_gest_apertura_liq
     (fase_bil_elab_id,
      bil_id,
      liq_importo,
	  liq_orig_id,
	  liq_orig_importo,
	  liq_orig_pagato,
	  bil_orig_id,
      ente_proprietario_id,
      login_operazione,
      validita_inizio
      )
      (select faseBilElabId,
              bilancioId,
              liq.liq_importo-sum(det.ord_ts_det_importo),
              liq.liq_id,
              liq.liq_importo,
              sum(det.ord_ts_det_importo),
              liq.bil_id,
			  liq.ente_proprietario_id,
              loginOperazione,
              clock_timestamp()
       from siac_t_bil bil,siac_t_liquidazione liq,
            siac_r_liquidazione_ord rliqord,siac_t_ordinativo_ts ts, siac_t_ordinativo ord,
            siac_r_ordinativo_stato rord,siac_t_ordinativo_ts_det det
       where bil.bil_id=bilancioPrecId
       and   liq.bil_id=bil.bil_id
       and   exists (select 1
                     from siac_t_movgest_ts ts, siac_r_liquidazione_movgest r
                     where r.liq_id=liq.liq_id
                     and   ts.movgest_ts_id=r.movgest_ts_id
                     and   ts.movgest_ts_tipo_id=movGestTsTTipoId
                     and   ts.data_cancellazione is null
                     and   ts.validita_fine is null
                     and   r.data_cancellazione is null
                     and   r.validita_fine is null )
       and exists ( select 1 from siac_r_liquidazione_stato rs
			        where rs.liq_id=liq.liq_id
				    and   rs.liq_stato_id!=liqStatoAId
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
			       )
       and   rliqord.liq_id=liq.liq_id
       and   ts.ord_ts_id=rliqord.sord_id
       and   ord.ord_id=ts.ord_id
       and   rord.ord_id=ord.ord_id
       and   rord.ord_stato_id!=ordStatoAId
       and   det.ord_ts_id=ts.ord_ts_id
       and   det.ord_ts_det_tipo_id=ordTsDetATipoId
       and   liq.data_cancellazione is null
       and   liq.validita_fine is null
       and   rliqord.data_cancellazione is null
       and   rliqord.validita_fine is null
       and   ts.data_cancellazione is null
       and   ts.validita_fine is null
       and   ord.data_cancellazione is null
       and   ord.validita_fine is null
       and   rord.data_cancellazione is null
       and   rord.validita_fine is null
       and   det.data_cancellazione is null
       and   det.validita_fine is null
       group by liq.liq_anno,
                liq.liq_numero,
                liq.liq_id,
                liq.bil_id,
                liq.liq_importo,
                faseBilElabId,
                bilancioId
       having liq.liq_importo- sum(det.ord_ts_det_importo)>0
       order by liq.liq_anno::integer,liq.liq_numero::integer
      );




     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq con dettaglio di pagamento su impegni - FINE.';
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
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq liquidazioni senza dettaglio di pagamento su impegni - INIZIO.';
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


   	 insert into fase_bil_t_gest_apertura_liq
     (fase_bil_elab_id,
      bil_id,
      liq_importo,
	  liq_orig_id,
	  liq_orig_importo,
	  liq_orig_pagato,
	  bil_orig_id,
      ente_proprietario_id,
      login_operazione,
      validita_inizio
      )
      (select faseBilElabId,
              bilancioId,
              liq.liq_importo,
              liq.liq_id,
              liq.liq_importo,
              0,
              liq.bil_id,
			  liq.ente_proprietario_id,
              loginOperazione,
              clock_timestamp()
       from siac_t_bil bil,siac_t_liquidazione liq
       where bil.bil_id=bilancioPrecId
       and   liq.bil_id=bil.bil_id
       and   exists ( select 1 from siac_r_liquidazione_stato rs
                      where rs.liq_id=liq.liq_id
				      and   rs.liq_stato_id!=liqStatoAId
				      and   rs.data_cancellazione is null
					  and   rs.validita_fine is null
                     )
       and   not exists ( select 1
                          from siac_r_liquidazione_ord rliqord,siac_t_ordinativo_ts ts, siac_t_ordinativo ord,
					           siac_r_ordinativo_stato rord
					      where rliqord.liq_id=liq.liq_id
						  and   ts.ord_ts_id=rliqord.sord_id
					      and   ord.ord_id=ts.ord_id
					      and   rord.ord_id=ord.ord_id
				          and   rord.ord_stato_id!=ordStatoAId
                          and   rliqord.data_cancellazione is null
					      and   rliqord.validita_fine is null
					      and   ts.data_cancellazione is null
					      and   ts.validita_fine is null
				          and   ord.data_cancellazione is null
					      and   ord.validita_fine is null
					      and   rord.data_cancellazione is null
					      and   rord.validita_fine is null
                        )
       and   exists (select 1
                     from siac_t_movgest_ts ts, siac_r_liquidazione_movgest r
                     where r.liq_id=liq.liq_id
                     and   ts.movgest_ts_id=r.movgest_ts_id
                     and   ts.movgest_ts_tipo_id=movGestTsTTipoId
                     and   ts.data_cancellazione is null
                     and   ts.validita_fine is null
                     and   r.data_cancellazione is null
                     and   r.validita_fine is null )
       and   liq.data_cancellazione is null
       and   liq.validita_fine is null
       order by liq.liq_anno::integer,liq.liq_numero::integer
      );

     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq senza dettaglio di pagamento su impegni - FINE.';
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
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq liquidazioni con dettaglio di pagamento su subimpegni - INIZIO.';
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


   	 insert into fase_bil_t_gest_apertura_liq
     (fase_bil_elab_id,
      bil_id,
      liq_importo,
	  liq_orig_id,
	  liq_orig_importo,
	  liq_orig_pagato,
	  bil_orig_id,
      ente_proprietario_id,
      login_operazione,
      validita_inizio
      )
      (select faseBilElabId,
              bilancioId,
              liq.liq_importo-sum(det.ord_ts_det_importo),
              liq.liq_id,
              liq.liq_importo,
              sum(det.ord_ts_det_importo),
              liq.bil_id,
			  liq.ente_proprietario_id,
              loginOperazione,
              clock_timestamp()
       from siac_t_bil bil,siac_t_liquidazione liq,
            siac_r_liquidazione_ord rliqord,siac_t_ordinativo_ts ts, siac_t_ordinativo ord,
            siac_r_ordinativo_stato rord, siac_t_ordinativo_ts_det det
       where bil.bil_id=bilancioPrecId
       and   liq.bil_id=bil.bil_id
       and   exists (select 1
                     from siac_t_movgest_ts ts, siac_r_liquidazione_movgest r
                     where r.liq_id=liq.liq_id
                     and   ts.movgest_ts_id=r.movgest_ts_id
                     and   ts.movgest_ts_tipo_id=movGestTsSTipoId
                     and   ts.data_cancellazione is null
                     and   ts.validita_fine is null
                     and   r.data_cancellazione is null
                     and   r.validita_fine is null )
       and   exists (select 1 from siac_r_liquidazione_stato rs
				     where rs.liq_id=liq.liq_id
			         and   rs.liq_stato_id!=liqStatoAId
                     and   rs.data_cancellazione is null
             		 and   rs.validita_fine is null
					)
       and   rliqord.liq_id=liq.liq_id
       and   ts.ord_ts_id=rliqord.sord_id
       and   ord.ord_id=ts.ord_id
       and   rord.ord_id=ord.ord_id
       and   rord.ord_stato_id!=ordStatoAId
       and   det.ord_ts_id=ts.ord_ts_id
       and   det.ord_ts_det_tipo_id=ordTsDetATipoId
       and   liq.data_cancellazione is null
       and   liq.validita_fine is null
       and   rliqord.data_cancellazione is null
       and   rliqord.validita_fine is null
       and   ts.data_cancellazione is null
       and   ts.validita_fine is null
       and   ord.data_cancellazione is null
       and   ord.validita_fine is null
       and   rord.data_cancellazione is null
       and   rord.validita_fine is null
       and   det.data_cancellazione is null
       and   det.validita_fine is null
       group by liq.liq_anno,
                liq.liq_numero,
                liq.liq_id,
                liq.bil_id,
                liq.liq_importo,
                faseBilElabId,
                bilancioId
       having liq.liq_importo- sum(det.ord_ts_det_importo)>0
       order by liq.liq_anno::integer,liq.liq_numero::integer
      );




     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq con dettaglio di pagamento su subimpegni - FINE.';
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
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq liquidazioni senza dettaglio di pagamento su subimpegni - INIZIO.';
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


   	 insert into fase_bil_t_gest_apertura_liq
     (fase_bil_elab_id,
      bil_id,
      liq_importo,
	  liq_orig_id,
	  liq_orig_importo,
	  liq_orig_pagato,
	  bil_orig_id,
      ente_proprietario_id,
      login_operazione,
      validita_inizio
      )
      (select faseBilElabId,
              bilancioId,
              liq.liq_importo,
              liq.liq_id,
              liq.liq_importo,
              0,
              liq.bil_id,
			  liq.ente_proprietario_id,
              loginOperazione,
              clock_timestamp()
       from siac_t_bil bil,siac_t_liquidazione liq
       where bil.bil_id=bilancioPrecId
       and   liq.bil_id=bil.bil_id
       and   exists (select 1 from siac_r_liquidazione_stato rs
			         where   rs.liq_id=liq.liq_id
			         and   rs.liq_stato_id!=liqStatoAId
                     and   rs.data_cancellazione is null
 				     and   rs.validita_fine is null
                     )
       and   not exists ( select 1
                          from siac_r_liquidazione_ord rliqord,siac_t_ordinativo_ts ts, siac_t_ordinativo ord,
					           siac_r_ordinativo_stato rord
					      where rliqord.liq_id=liq.liq_id
						  and   ts.ord_ts_id=rliqord.sord_id
					      and   ord.ord_id=ts.ord_id
					      and   rord.ord_id=ord.ord_id
				          and   rord.ord_stato_id!=ordStatoAId
                          and   rliqord.data_cancellazione is null
					      and   rliqord.validita_fine is null
					      and   ts.data_cancellazione is null
					      and   ts.validita_fine is null
				          and   ord.data_cancellazione is null
					      and   ord.validita_fine is null
					      and   rord.data_cancellazione is null
					      and   rord.validita_fine is null
                        )
       and   exists (select 1
                     from siac_t_movgest_ts ts, siac_r_liquidazione_movgest r
                     where r.liq_id=liq.liq_id
                     and   ts.movgest_ts_id=r.movgest_ts_id
                     and   ts.movgest_ts_tipo_id=movGestTsSTipoId
                     and   ts.data_cancellazione is null
                     and   ts.validita_fine is null
                     and   r.data_cancellazione is null
                     and   r.validita_fine is null )
       and   liq.data_cancellazione is null
       and   liq.validita_fine is null
       order by liq.liq_anno::integer,liq.liq_numero::integer
      );

     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq senza dettaglio di pagamento su subimpegni - FINE.';
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
     strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_liq liquidazioni per estremi movimento gestione - INIZIO.';
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


	 update fase_bil_t_gest_apertura_liq liq
     set movgest_orig_id=mov.movgest_id,
		 movgest_orig_ts_id=ts.movgest_ts_id,
		 elem_orig_id =r.elem_id,
         movgest_ts_tipo=tipo.movgest_ts_tipo_code
     from siac_r_liquidazione_movgest rmov, siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_bil_elem r,
          siac_d_movgest_ts_tipo tipo
     where liq.fase_bil_elab_id=faseBilElabId
     and   rmov.liq_id=liq.liq_orig_id
     and   ts.movgest_ts_id=rmov.movgest_ts_id
     and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
     and   mov.movgest_id=ts.movgest_id
     and   r.movgest_id=mov.movgest_id
     and   rmov.data_cancellazione is null
     and   rmov.validita_fine is null
     and   mov.data_cancellazione is null
     and   mov.validita_fine is null
     and   ts.data_cancellazione is null
     and   ts.validita_fine is null
     and   r.data_cancellazione is null
     and   r.validita_fine is null
     and   liq.data_cancellazione is null
     and   liq.validita_fine is null;

	 select  1 into codResult
     from fase_bil_t_gest_apertura_liq liq
     where liq.fase_bil_elab_id=faseBilElabId
     and   ( liq.movgest_orig_id is null or liq.movgest_orig_ts_id is null or liq.elem_orig_id is null )
     and   liq.data_cancellazione is null
     and   liq.validita_fine is null;

     if codResult is not null then
     	raise exception ' Non riuscito per liquidazioni presenti in fase_bil_t_gest_apertura_liq.';
     end if;

	 codResult:=null;
     strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_liq liquidazioni per estremi movimento gestione - FINE.';
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
     strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_liq per scarto liquidazioni capitolo non presente in nuovo bilancio - INIZIO.';
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


     update fase_bil_t_gest_apertura_liq liq
     set  scarto_code='CAP',
          scarto_desc='Capitolo non presente in bilancio di gestione corrente',
          fl_elab='X'
     from siac_t_bil_elem eprec
     where liq.fase_bil_elab_id=faseBilElabId
     and   eprec.elem_id=liq.elem_orig_id
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
     and   liq.data_cancellazione is null
     and   liq.validita_fine is null
     and   eprec.data_cancellazione is null
	 and   eprec.validita_fine is null;



     codResult:=null;
     strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_liq per scarto liquidazioni capitolo non presente in nuovo bilancio - FINE.';
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
     strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_liq identificativo elemento di bilancio corrente - INIZIO.';
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


     update fase_bil_t_gest_apertura_liq liq
     set  elem_id=e.elem_id
     from siac_t_bil_elem eprec, siac_t_bil_elem e, siac_r_bil_elem_stato r
     where liq.fase_bil_elab_id=faseBilElabId
     and   liq.fl_elab='N'
     and   eprec.elem_id=liq.elem_orig_id
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
     and   liq.data_cancellazione is null
     and   liq.validita_fine is null
     and   eprec.data_cancellazione is null
	 and   eprec.validita_fine is null;

	 select  1 into codResult
     from fase_bil_t_gest_apertura_liq liq
     where liq.fase_bil_elab_id=faseBilElabId
     and   liq.fl_elab='N'
     and   liq.elem_id is null
     and   liq.data_cancellazione is null
     and   liq.validita_fine is null;

     if codResult is not null then
     	raise exception ' Non riuscito per liquidazioni presenti in fase_bil_t_gest_apertura_liq.';
     end if;


     codResult:=null;
     strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_liq identificativo elemento di bilancio corrente - FINE.';
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
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_LIQ_RES||' IN CORSO IN-1.POPOLA LIQ.'
     where fase.fase_bil_elab_id=faseBilElabId;


     faseBilElabRetId:=faseBilElabId;
     codiceRisultato:=0;
     messaggioRisultato:=strMessaggioFinale||' FINE';
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