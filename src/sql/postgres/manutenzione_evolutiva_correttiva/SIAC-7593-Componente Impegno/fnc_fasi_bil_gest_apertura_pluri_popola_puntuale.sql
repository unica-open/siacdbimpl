/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_pluri_popola_puntuale (
  enteproprietarioid integer,
  annobilancio integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabretid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;
    faseBilElabId     integer:=null;
	tipoMovGestId     integer:=null;
	capUgTipoId       integer:=null;
	capEgTipoId       integer:=null;
    impTipoMovGestId  integer:=null;
    accTipoMovGestId  integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;
	movGestIdRet      integer:=null;

	movGestTsTipoTId  integer:=null;
	movGestTsTipoSId  integer:=null;
    movGestStatoAId   integer:=null;
	faseOp            varchar(10):=null;

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';

    CAP_UG_TIPO       CONSTANT varchar:='CAP-UG';
    CAP_EG_TIPO       CONSTANT varchar:='CAP-EG';

    IMP_MOV_GEST_TIPO CONSTANT varchar:='I';
    ACC_MOV_GEST_TIPO CONSTANT varchar:='A';

    MOVGEST_TS_T_TIPO CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO CONSTANT varchar:='S';

    APE_GEST_PLURI    CONSTANT varchar:='APE_GEST_PLURI';
    A_MOV_GEST_STATO  CONSTANT varchar:='A';

    E_FASE            CONSTANT varchar:='E'; -- esercizio provvisorio
    G_FASE            CONSTANT varchar:='G'; -- gestione approvata
BEGIN
	faseBilElabRetId:=null;
    codiceRisultato:=null;
    messaggioRisultato:=null;

    dataInizioVal:= clock_timestamp();

	strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento movimenti  pluriennali da Gestione precedente. Anno bilancio='||annoBilancio::varchar||'. POPOLA.';

    strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_PLURI||' IN CORSO.';
    select 1 into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_PLURI
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
    (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_PLURI||' IN CORSO.',
            tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
     from fase_bil_d_elaborazione_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.fase_bil_elab_tipo_code=APE_GEST_PLURI
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

     strMessaggio:='Lettura id identificativo per tipo capitolo='||CAP_UG_TIPO||'.';
	 select tipo.elem_tipo_id into strict capUgTipoId
     from siac_d_bil_elem_tipo tipo
     where tipo.elem_tipo_code=CAP_UG_TIPO
     and   tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.data_cancellazione is null
     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
     and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

     strMessaggio:='Lettura id identificativo per tipo capitolo='||CAP_EG_TIPO||'.';
	 select tipo.elem_tipo_id into strict capEgTipoId
     from siac_d_bil_elem_tipo tipo
     where tipo.elem_tipo_code=CAP_EG_TIPO
     and   tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.data_cancellazione is null
     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
     and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);


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
     if faseOp is null or faseOp not in (E_FASE, G_FASE) then
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

     strMessaggio:='Lettura id identificativo per movGestStatoA='||A_MOV_GEST_STATO||'.';
     select stato.movgest_stato_id into strict movGestStatoAId
     from siac_d_movgest_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.movgest_stato_code=A_MOV_GEST_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;


     strMessaggio:='Lettura id identificativo per tipoMovGest='||IMP_MOV_GEST_TIPO||'.';
     select tipo.movgest_tipo_id into strict impTipoMovGestId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=IMP_MOV_GEST_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura id identificativo per tipoMovGest='||ACC_MOV_GEST_TIPO||'.';
     select tipo.movgest_tipo_id into strict accTipoMovGestId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=ACC_MOV_GEST_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;


     strMessaggio:='Lettura identificativo per tipoMovGestTsTipoT='||MOVGEST_TS_T_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict movGestTsTipoTId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_T_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura identificativo per tipoMovGestTsTipoS='||MOVGEST_TS_S_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict movGestTsTipoSId
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

     --- impegni
     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per impegni - INIZIO.';
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

   	 insert into fase_bil_t_gest_apertura_pluri
     (fase_bil_elab_id,
      movgest_orig_id,
	  movgest_orig_ts_id,
      elem_orig_det_comp_tipo_id,  -- 14.05.2020 Sofia Jira SIAC-7593
	  elem_orig_id,
	  bil_orig_id,
      movgest_tipo,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
      )
      (select faseBilElabId,
              m.movgest_id,
              ts.movgest_ts_id,
              elem.elem_det_comp_tipo_id,-- 14.05.2020 Sofia Jira SIAC-7593
              elem.elem_id,
              m.bil_id,
              'IMP', -- impegno
              clock_timestamp(),
              loginOperazione,
              m.ente_proprietario_id
       from siac_t_bil bil, siac_t_movgest m, siac_t_movgest_ts ts,
      		siac_r_movgest_bil_elem elem,siac_r_movgest_ts_stato stato,
            fase_bil_t_gest_apertura_pluri_puntuale fase_punt
       where bil.bil_id=bilancioPrecId
       and   m.bil_id=bil.bil_id
       and   m.movgest_tipo_id=impTipoMovGestId
       and   m.movgest_anno::integer>=annoBilancio
       and   ts.movgest_id=m.movgest_id
       and   ts.movgest_ts_tipo_id=movGestTsTipoTId
	   and   elem.movgest_id=m.movgest_id
       and   stato.movgest_ts_id=ts.movgest_ts_id
       and   stato.movgest_stato_id!=movGestStatoAId
       -- fase_puntuale --
       and   fase_punt.ente_proprietario_id=enteProprietarioId
       and   fase_punt.bil_id=bilancioPrecId
       and   fase_punt.movgest_ts_id=ts.movgest_ts_id
       and   fase_punt.validita_fine is null
       and   fase_punt.data_cancellazione is null
       -- fase_puntuale --
       and   m.data_cancellazione is null
       and   m.validita_fine is null
       and   ts.data_cancellazione is null
       and   ts.validita_fine is null
       and   elem.data_cancellazione is null
       and   elem.validita_fine is null
       and   stato.data_cancellazione is null
       and   stato.validita_fine is null
       order by m.movgest_anno::integer,m.movgest_numero::integer
       );

     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per impegni - FINE.';
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

     -- subimpegni
     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per subimpegni - INIZIO.';
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

   	 insert into fase_bil_t_gest_apertura_pluri
     (fase_bil_elab_id,
      movgest_orig_id,
	  movgest_orig_ts_id,
      elem_orig_det_comp_tipo_id,  -- 14.05.2020 Sofia Jira SIAC-7593
	  elem_orig_id,
	  bil_orig_id,
      movgest_tipo,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
      )
      (select faseBilElabId,
              m.movgest_id,
              ts.movgest_ts_id,
              elem.elem_det_comp_tipo_id,-- 14.05.2020 Sofia Jira SIAC-7593
              elem.elem_id,
              m.bil_id,
              'SIM', -- subimpegno
              clock_timestamp(),
              loginOperazione,
              m.ente_proprietario_id
       from siac_t_bil bil, siac_t_movgest m, siac_t_movgest_ts ts,
      		siac_r_movgest_bil_elem elem,siac_r_movgest_ts_stato stato,
            fase_bil_t_gest_apertura_pluri_puntuale fase_punt
       where bil.bil_id=bilancioPrecId
       and   m.bil_id=bil.bil_id
       and   m.movgest_tipo_id=impTipoMovGestId
       and   m.movgest_anno::integer>=annoBilancio
       and   ts.movgest_id=m.movgest_id
       and   ts.movgest_ts_tipo_id=movGestTsTipoSId
	   and   elem.movgest_id=m.movgest_id
       and   stato.movgest_ts_id=ts.movgest_ts_id
       and   stato.movgest_stato_id!=movGestStatoAId
       -- fase_puntuale --
       and   fase_punt.ente_proprietario_id=enteProprietarioId
       and   fase_punt.bil_id=bilancioPrecId
       and   fase_punt.movgest_ts_id=ts.movgest_ts_id
       and   fase_punt.validita_fine is null
       and   fase_punt.data_cancellazione is null
       -- fase_puntuale --
       and   m.data_cancellazione is null
       and   m.validita_fine is null
       and   ts.data_cancellazione is null
       and   ts.validita_fine is null
       and   elem.data_cancellazione is null
       and   elem.validita_fine is null
       and   stato.data_cancellazione is null
       and   stato.validita_fine is null
       order by m.movgest_anno::integer,m.movgest_numero::integer,ts.movgest_ts_code::integer
       );

     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per subimpegni - FINE.';
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


	 --- accertamenti
     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per accertamenti - INIZIO.';
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

   	 insert into fase_bil_t_gest_apertura_pluri
     (fase_bil_elab_id,
      movgest_orig_id,
	  movgest_orig_ts_id,
	  elem_orig_id,
	  bil_orig_id,
      movgest_tipo,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
      )
      (select faseBilElabId,
              m.movgest_id,
              ts.movgest_ts_id,
              elem.elem_id,
              m.bil_id,
              'ACC', -- accertamento
              clock_timestamp(),
              loginOperazione,
              m.ente_proprietario_id
       from siac_t_bil bil, siac_t_movgest m, siac_t_movgest_ts ts,
      		siac_r_movgest_bil_elem elem,siac_r_movgest_ts_stato stato,
            fase_bil_t_gest_apertura_pluri_puntuale fase_punt
       where bil.bil_id=bilancioPrecId
       and   m.bil_id=bil.bil_id
       and   m.movgest_tipo_id=accTipoMovGestId
       and   m.movgest_anno::integer>=annoBilancio
       and   ts.movgest_id=m.movgest_id
       and   ts.movgest_ts_tipo_id=movGestTsTipoTId
	   and   elem.movgest_id=m.movgest_id
       and   stato.movgest_ts_id=ts.movgest_ts_id
       and   stato.movgest_stato_id!=movGestStatoAId
       -- fase_puntuale --
       and   fase_punt.ente_proprietario_id=enteProprietarioId
       and   fase_punt.bil_id=bilancioPrecId
       and   fase_punt.movgest_ts_id=ts.movgest_ts_id
       and   fase_punt.validita_fine is null
       and   fase_punt.data_cancellazione is null
       -- fase_puntuale --
       and   m.data_cancellazione is null
       and   m.validita_fine is null
       and   ts.data_cancellazione is null
       and   ts.validita_fine is null
       and   elem.data_cancellazione is null
       and   elem.validita_fine is null
       and   stato.data_cancellazione is null
       and   stato.validita_fine is null
       order by m.movgest_anno::integer,m.movgest_numero::integer
       );

     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per accertamenti - FINE.';
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

	-- subaccertamenti
     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per subaccertamenti - INIZIO.';
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

   	 insert into fase_bil_t_gest_apertura_pluri
     (fase_bil_elab_id,
      movgest_orig_id,
	  movgest_orig_ts_id,
	  elem_orig_id,
	  bil_orig_id,
      movgest_tipo,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
      )
      (select faseBilElabId,
              m.movgest_id,
              ts.movgest_ts_id,
              elem.elem_id,
              m.bil_id,
              'SAC', -- subaccertamento
              clock_timestamp(),
              loginOperazione,
              m.ente_proprietario_id
       from siac_t_bil bil, siac_t_movgest m, siac_t_movgest_ts ts,
      		siac_r_movgest_bil_elem elem,siac_r_movgest_ts_stato stato,
            fase_bil_t_gest_apertura_pluri_puntuale fase_punt
       where bil.bil_id=bilancioPrecId
       and   m.bil_id=bil.bil_id
       and   m.movgest_tipo_id=accTipoMovGestId
       and   m.movgest_anno::integer>=annoBilancio
       and   ts.movgest_id=m.movgest_id
       and   ts.movgest_ts_tipo_id=movGestTsTipoSId
	   and   elem.movgest_id=m.movgest_id
       and   stato.movgest_ts_id=ts.movgest_ts_id
       and   stato.movgest_stato_id!=movGestStatoAId
        -- fase_puntuale --
       and   fase_punt.ente_proprietario_id=enteProprietarioId
       and   fase_punt.bil_id=bilancioPrecId
       and   fase_punt.movgest_ts_id=ts.movgest_ts_id
       and   fase_punt.validita_fine is null
       and   fase_punt.data_cancellazione is null
       -- fase_puntuale --
       and   m.data_cancellazione is null
       and   m.validita_fine is null
       and   ts.data_cancellazione is null
       and   ts.validita_fine is null
       and   elem.data_cancellazione is null
       and   elem.validita_fine is null
       and   stato.data_cancellazione is null
       and   stato.validita_fine is null
       order by m.movgest_anno::integer,m.movgest_numero::integer,ts.movgest_ts_code::integer
       );

     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per subaccertamenti - FINE.';
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

	 -- controlli e scarti per sub per cui non inserito padre
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

     strMessaggio:='Aggiornamento stato fase bilancio IN-1.';
     update fase_bil_t_elaborazione fase
     set fase_bil_elab_esito='IN-1',
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PLURI||' IN CORSO IN-1.'
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