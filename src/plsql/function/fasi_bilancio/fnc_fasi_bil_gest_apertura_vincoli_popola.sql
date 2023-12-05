/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿
CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_vincoli_popola(
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

    movGestRec record;
    faseBilElabId     integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;

	faseOp            varchar(10):=null;

	movgestStatoAId   integer:=null;
	movGestTsDetTipoAId   integer:=null;

	movGestTipoIId        integer:=null;
    movGestTipoAId        integer:=null;
	movGestTsAId          integer:=null;

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


    APE_GEST_VINCOLI    CONSTANT varchar:='APE_GEST_VINCOLI';

	A_IMP_STATO       CONSTANT varchar:='A';
	IMPOATT_TIPO    CONSTANT varchar:='A';

    I_MOVGEST_TIPO  CONSTANT varchar:='I';
    A_MOVGEST_TIPO  CONSTANT varchar:='A';
    E_FASE CONSTANT varchar:='E';
    G_FASE CONSTANT varchar:='G';
BEGIN
	faseBilElabRetId:=null;
    codiceRisultato:=null;
    messaggioRisultato:=null;

    dataInizioVal:= clock_timestamp();

	strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento vincoli da Gestione precedente. Anno bilancio='||annoBilancio::varchar||'. POPOLA.';

    strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_VINCOLI||' IN CORSO.';
    select 1 into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_VINCOLI
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
    (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_VINCOLI||' IN CORSO.',
            tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
     from fase_bil_d_elaborazione_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.fase_bil_elab_tipo_code=APE_GEST_VINCOLI
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




     strMessaggio:='Lettura id identificativo per movgestStatoAId='||A_IMP_STATO||'.';
     select stato.movgest_stato_id into strict movgestStatoAId
     from siac_d_movgest_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.movgest_stato_code=A_IMP_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;


     strMessaggio:='Lettura id identificativo per movGestTipoIId='||I_MOVGEST_TIPO||'.';
     select tipo.movgest_tipo_id into strict movGestTipoIId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=I_MOVGEST_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura id identificativo per movGestTipoAId='||A_MOVGEST_TIPO||'.';
     select tipo.movgest_tipo_id into strict movGestTipoAId
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

     -- 07.02.2018 Daniela SIAC-5852

     strMessaggio:='Apertura avanzo vincolo per anno annoBilancio='||annoBilancio::varchar||'.INIZIO.';
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

     insert into siac_t_avanzovincolo
     (avav_tipo_id, avav_importo_massimale,validita_inizio,ente_proprietario_id,login_operazione)
     select a.avav_tipo_id, 0, to_date('01/01/'||annoBilancio::varchar,'dd/MM/yyyy'),enteProprietarioId, loginOperazione
     from siac_t_avanzovincolo a
     where a.ente_proprietario_id = enteProprietarioId
     and   a.validita_inizio = to_date ('01/01/'||(annoBilancio-1)::varchar,'dd/MM/yyyy')
     and   a.validita_fine is NULL
     and   a.data_cancellazione is NULL
     and   not exists (select 1 from siac_t_avanzovincolo b
		  			   where b.ente_proprietario_id=a.ente_proprietario_id
					   and b.validita_inizio = to_date('01/01/'||annoBilancio::varchar,'dd/MM/yyyy')
  					   and b.avav_tipo_id = a.avav_tipo_id
                       and b.validita_fine is null
                       and b.data_cancellazione is null);

     strMessaggio:='Apertura avanzo vincolo per anno bilancio annoBilancio='||annoBilancio::varchar||'.FINE.';
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

     strMessaggio:='Chiusura avanzo vincolo per anno annoBilancio-1='||(annoBilancio-1)::varchar||'.INIZIO.';
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

     Update siac_t_avanzovincolo
      set validita_fine = to_date('31/12/'||(annoBilancio-1)::varchar,'dd/MM/yyyy')
      , login_operazione = login_operazione||'-'||loginOperazione
      , data_modifica = now()
     where ente_proprietario_id = enteProprietarioId
     and   validita_fine is null
     and   data_cancellazione is null
     and   validita_inizio = to_date('01/01/'||(annoBilancio-1)::varchar,'dd/MM/yyyy');

     strMessaggio:='Chiusura avanzo vincolo per anno annoBilancio-1='||(annoBilancio-1)::varchar||'.FINE.';
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

    strMessaggio:='Verifica esistenza vincoli su movimenti da ribaltare INIZIO.';
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

    -- 06.12.2017 Sofia siac-5276 - revisione ribaltamento vincoli tra impegni-accertamenti
    codResult:=null;
	select 1 into codResult
    from siac_r_movgest_ts r,
         siac_t_movgest mb,siac_t_movgest_ts tsb
    where mb.ente_proprietario_id=enteProprietarioId
    and   mb.movgest_tipo_id=movGestTipoIId
    and   mb.bil_id=bilancioPrecId
    and   mb.movgest_anno::INTEGER>=annoBilancio
    and   tsb.movgest_id=mb.movgest_id
    and   r.movgest_ts_b_id=tsb.movgest_ts_id
    and   mb.data_cancellazione is null
    and   mb.validita_fine is null
    and   tsb.data_cancellazione is null
    and   tsb.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   exists (select 1 from siac_t_movgest mnew, siac_t_movgest_ts tsnew, siac_r_movgest_ts_stato rs
   				  where mnew.bil_id=bilancioId
                  and   mnew.movgest_tipo_id=mb.movgest_tipo_id
                  and   mnew.movgest_anno=mb.movgest_anno
                  and   mnew.movgest_numero=mb.movgest_numero
                  and   tsnew.movgest_id=mnew.movgest_id
                  and   tsnew.movgest_ts_tipo_id=tsb.movgest_ts_tipo_id
                  and   tsnew.movgest_ts_code=tsb.movgest_ts_code
                  and   rs.movgest_ts_id=tsnew.movgest_ts_id
                  and   rs.movgest_stato_id!=movgestStatoAId
                  and   rs.data_cancellazione is null
                  and   rs.validita_fine is null
                  and   mnew.data_cancellazione is null
                  and   mnew.validita_fine is null
                  and   tsnew.data_cancellazione is null
                  and   tsnew.validita_fine is null);

	 if codResult is null then
     	raise exception ' Nessun vincolo da ribaltare.';
     end if;

     strMessaggio:='Verifica esistenza vincoli su movimenti da ribaltare FINE.';
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


     strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli - INIZIO inserimenti';
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

     strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli - INIZIO inserimenti - caso 1';
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

     -- caso 1
	 -- il movimento nel bilancio precedente presentava un legame ad avanzo_tipo FPVCC conto capitale o FPVSC spesa corrente:
	 --  in questo caso ricreare un vincolo analogo nel
	 --  nuovo bilancio per la stessa quota senza legame ad accertamento ( solo movgest_ts_id_b )
     insert into fase_bil_t_gest_apertura_vincoli
     (fase_bil_elab_id,
      movgest_orig_ts_b_id,
      movgest_orig_ts_r_id,
      bil_orig_id,
      importo_orig_vinc,
      movgest_ts_b_id,
      importo_vinc,
	  avav_id,
      bil_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
      )
      (
      with
      vincPrec as
      (
      select mb.movgest_anno::integer, mb.movgest_numero::integer,
             tsb.movgest_ts_code::integer,
             tsb.movgest_ts_tipo_id,
             mb.movgest_id, tsb.movgest_ts_id,
             r.movgest_ts_r_id,
             r.avav_id, r.movgest_ts_importo
             ,tipo.avav_tipo_id
      from siac_r_movgest_ts r,
           siac_t_movgest mb,siac_t_movgest_ts tsb ,siac_t_avanzovincolo av,siac_d_avanzovincolo_tipo tipo
      where mb.bil_id=bilancioPrecId
      and   mb.movgest_tipo_id=movGestTipoIId
      and   mb.movgest_anno::INTEGER>=annoBilancio
	  and   tsb.movgest_id=mb.movgest_id
	  and   r.movgest_ts_b_id=tsb.movgest_ts_id
      and   r.movgest_ts_a_id is null
      and   av.avav_id=r.avav_id
      and   tipo.avav_tipo_id=av.avav_tipo_id
      and   tipo.avav_tipo_code in ('FPVCC','FPVSC')
	  and   mb.data_cancellazione is null
	  and   mb.validita_fine is null
	  and   tsb.data_cancellazione is null
	  and   tsb.validita_fine is null
	  and   r.data_cancellazione is null
      and   r.validita_fine is null
      ),
      impNew as
      (select mnew.movgest_anno::integer, mnew.movgest_numero::integer,
              tsnew.movgest_ts_code::integer,
              tsnew.movgest_ts_tipo_id,
              mnew.movgest_id, tsnew.movgest_ts_id
       from siac_t_movgest mnew, siac_t_movgest_ts tsnew, siac_r_movgest_ts_stato rs
       where mnew.bil_id=bilancioId
       and   mnew.movgest_tipo_id=movGestTipoIId
       and   mnew.movgest_anno::integer>=annoBilancio
       and   tsnew.movgest_id=mnew.movgest_id
       and   rs.movgest_ts_id=tsnew.movgest_ts_id
       and   rs.movgest_stato_id!=movgestStatoAId
       and   rs.data_cancellazione is null
       and   rs.validita_fine is null
       and   mnew.data_cancellazione is null
       and   mnew.validita_fine is null
       and   tsnew.data_cancellazione is null
       and   tsnew.validita_fine is null
      )
      -- 07.02.2018 - Daniela SIAC-5852
      , avavNew as
      ( select av.avav_id, av.avav_tipo_id
        from siac_t_avanzoVincolo av
        where av.ente_proprietario_id = enteProprietarioId
        and   av.validita_inizio = to_date('01/01/'||annoBilancio::varchar,'dd/MM/yyyy')
        and   av.validita_fine is null
        and   av.data_cancellazione is NULL
        )
      select faseBilElabId, 				-- fase_bil_elab_id
             vincPrec.movgest_ts_id, 		-- movgest_orig_ts_b_id
             vincPrec.movgest_ts_r_id,  	-- movgest_orig_ts_r_id
             bilancioPrecId, 				-- bil_orig_id
             vincPrec.movgest_ts_importo, 	-- importo_orig_vinc
             impNew.movgest_ts_id, 			-- movgest_ts_b_id
             vincPrec.movgest_ts_importo, 	-- importo_vinc
--             vincPrec.avav_id,  			-- avav_id
             avavNew.avav_id,				-- avav_id
             bilancioId, 					-- bil_id
       		 dataInizioVal,
	         loginOperazione,
	         enteProprietarioId
      from vincPrec, impNew, avavNew
      where vincPrec.movgest_anno=impNew.movgest_anno
      and   vincPrec.movgest_numero=impNew.movgest_numero
      and   vincPrec.movgest_ts_code=impNew.movgest_ts_code
      and   vincPrec.movgest_ts_tipo_id=impNew.movgest_ts_tipo_id
      and   avavNew.avav_tipo_id = vincPrec.avav_tipo_id
      );


     strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli - FINE inserimenti - caso 1';
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

     strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli - INIZIO inserimenti - caso 2.a';
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
     -- caso 2.a
     -- il movimento nel bilancio precedente presentava un legame ad
     -- avanzo_tipo Avanzo di amministrazione
     -- creare un legame nuovo bilancio del tipo FPV  per la stessa quota
     -- (la tipologia conto capitale o spesa corrente da determinare sulla base del titolo di spesa)
     -- titolo 1 e 4 - FPVSC corrente
     -- titolo 2 e 3 - FPVCC in conto capitale
     insert into fase_bil_t_gest_apertura_vincoli
     (fase_bil_elab_id,
      movgest_orig_ts_b_id,
      movgest_orig_ts_r_id,
      bil_orig_id,
      importo_orig_vinc,
      movgest_ts_b_id,
      importo_vinc,
	  avav_id,
      bil_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
      )
      (
      with
      vincPrec as
      (
      select mb.movgest_anno::integer, mb.movgest_numero::integer,
             tsb.movgest_ts_code::integer,
             tsb.movgest_ts_tipo_id,
             mb.movgest_id, tsb.movgest_ts_id,
             r.movgest_ts_r_id,
             r.avav_id, r.movgest_ts_importo
      from siac_r_movgest_ts r,
           siac_t_movgest mb,siac_t_movgest_ts tsb ,siac_t_avanzovincolo av,siac_d_avanzovincolo_tipo tipo
      where mb.bil_id=bilancioPrecId
	  and   mb.movgest_tipo_id=movGestTipoIId
      and   mb.movgest_anno::INTEGER>=annoBilancio
	  and   tsb.movgest_id=mb.movgest_id
	  and   r.movgest_ts_b_id=tsb.movgest_ts_id
      and   r.movgest_ts_a_id is null
      and   av.avav_id=r.avav_id
      and   tipo.avav_tipo_id=av.avav_tipo_id
      and   tipo.avav_tipo_code='AAM'
	  and   mb.data_cancellazione is null
	  and   mb.validita_fine is null
	  and   tsb.data_cancellazione is null
	  and   tsb.validita_fine is null
	  and   r.data_cancellazione is null
      and   r.validita_fine is null
      ),
      impNew as
      (select mnew.movgest_anno::integer, mnew.movgest_numero::integer,
              tsnew.movgest_ts_code::integer,
              tsnew.movgest_ts_tipo_id,
              mnew.movgest_id, tsnew.movgest_ts_id
       from siac_t_movgest mnew, siac_t_movgest_ts tsnew, siac_r_movgest_ts_stato rs
       where mnew.bil_id=bilancioId
       and   mnew.movgest_tipo_id=movGestTipoIId
       and   mnew.movgest_anno::integer>=annoBilancio
       and   tsnew.movgest_id=mnew.movgest_id
       and   rs.movgest_ts_id=tsnew.movgest_ts_id
       and   rs.movgest_stato_id!=movgestStatoAId
       and   rs.data_cancellazione is null
       and   rs.validita_fine is null
       and   mnew.data_cancellazione is null
       and   mnew.validita_fine is null
       and   tsnew.data_cancellazione is null
       and   tsnew.validita_fine is null
      ),
      titoloNew as
      (
      	select rmov.movgest_id, cTitolo.classif_code::integer titolo_uscita,
               ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                      then 'FPVSC'
                      when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                      then 'FPVCC'
                      else null end ) tipo_avanzo
        from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
             siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
             siac_r_class_fam_tree rfam,
             siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
             siac_r_movgest_bil_elem rmov
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.elem_tipo_code='CAP-UG'
        and   e.elem_tipo_id=tipo.elem_tipo_id
        and   e.bil_id=bilancioId
        and   rc.elem_id=e.elem_id
        and   cMacro.classif_id=rc.classif_id
        and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
        and   tipomacro.classif_tipo_code='MACROAGGREGATO'
        and   rfam.classif_id=cMacro.classif_id
        and   cTitolo.classif_id=rfam.classif_id_padre
        and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
        and   tipoTitolo.classif_tipo_code='TITOLO_SPESA'
        and   rmov.elem_id=e.elem_id
        and   e.data_cancellazione is null
        and   e.validita_fine is null
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
        and   rfam.data_cancellazione is null
        and   rfam.validita_fine is null
        and   rmov.data_cancellazione is null
        and   rmov.validita_fine is null
      ),
      tipoAv as
      (
       select av.avav_id, tipoav.avav_tipo_code
       from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo tipoav
       where tipoav.ente_proprietario_id=enteProprietarioId
       and   av.avav_tipo_id=tipoav.avav_tipo_id
       and   tipoav.avav_tipo_code in ('FPVSC','FPVCC')
       -- 07.02.2018 - Daniela SIAC-5852
       and   av.validita_inizio = to_date('01/01/'||annoBilancio::varchar,'dd/MM/yyyy')
       and   av.validita_fine is null
       and   av.data_cancellazione is NULL
      )
      select faseBilElabId, 				-- fase_bil_elab_id
             vincPrec.movgest_ts_id, 		-- movgest_orig_ts_b_id
             vincPrec.movgest_ts_r_id,  	-- movgest_orig_ts_r_id
             bilancioPrecId, 				-- bil_orig_id
             vincPrec.movgest_ts_importo, 	-- importo_orig_vinc
             impNew.movgest_ts_id, 			-- movgest_ts_b_id
             vincPrec.movgest_ts_importo, 	-- importo_vinc
             tipoAv.avav_id,  				-- avav_id
             bilancioId, 					-- bil_id
       		 dataInizioVal,
	         loginOperazione,
	         enteProprietarioId
      from vincPrec, impNew, titoloNew, tipoAv
      where vincPrec.movgest_anno=impNew.movgest_anno
      and   vincPrec.movgest_numero=impNew.movgest_numero
      and   vincPrec.movgest_ts_code=impNew.movgest_ts_code
      and   vincPrec.movgest_ts_tipo_id=impNew.movgest_ts_tipo_id
      and   titoloNew.movgest_id=impNew.movgest_id
      and   tipoAv.avav_tipo_code=titoloNew.tipo_avanzo
      );

     strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli - FINE inserimenti - caso 2.a';
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

	 strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli - INIZIO inserimenti - caso 2.b';
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
     -- caso 2.b
     -- il movimento nel bilancio precedente presentava un legame ad
     -- un accertamento con anno < del nuovo bilancio:
     -- creare un legame nuovo bilancio del tipo FPV  per la stessa quota
     -- (la tipologia conto capitale o spesa corrente da determinare sulla base del titolo di spesa)
     -- titolo 1 e 4 - FPVSC corrente
     -- titolo 2 e 3 - FPVCC in conto capitale
     insert into fase_bil_t_gest_apertura_vincoli
     (fase_bil_elab_id,
      movgest_orig_ts_b_id,
      movgest_orig_ts_a_id,
      movgest_orig_ts_r_id,
      bil_orig_id,
      importo_orig_vinc,
      movgest_ts_b_id,
      importo_vinc,
	  avav_id,
      bil_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
      )
      (
      with
      vincPrec as
      (
      select mb.movgest_anno::integer, mb.movgest_numero::integer,
             tsb.movgest_ts_code::integer,
             tsb.movgest_ts_tipo_id,
             mb.movgest_id, tsb.movgest_ts_id,
             ma.movgest_id movgest_a_id, tsa.movgest_ts_id movgest_ts_a_id,
             r.movgest_ts_r_id,
             r.movgest_ts_importo
      from siac_r_movgest_ts r,
           siac_t_movgest mb,siac_t_movgest_ts tsb ,
           siac_t_movgest ma,siac_t_movgest_ts tsa
      where mb.bil_id=bilancioPrecId
	  and   mb.movgest_tipo_id=movGestTipoIId
      and   mb.movgest_anno::INTEGER>=annoBilancio
	  and   tsb.movgest_id=mb.movgest_id
	  and   r.movgest_ts_b_id=tsb.movgest_ts_id
      and   tsa.movgest_ts_id=r.movgest_ts_a_id
      and   ma.movgest_id=tsa.movgest_id
      and   ma.movgest_tipo_id=movGestTipoAId
      and   ma.bil_id=bilancioPrecId
      and   ma.movgest_anno::INTEGER<annoBilancio
	  and   mb.data_cancellazione is null
	  and   mb.validita_fine is null
	  and   tsb.data_cancellazione is null
	  and   tsb.validita_fine is null
	  and   ma.data_cancellazione is null
	  and   ma.validita_fine is null
	  and   tsa.data_cancellazione is null
	  and   tsa.validita_fine is null
	  and   r.data_cancellazione is null
      and   r.validita_fine is null
      ),
      impNew as
      (select mnew.movgest_anno::integer, mnew.movgest_numero::integer,
              tsnew.movgest_ts_code::integer,
              tsnew.movgest_ts_tipo_id,
              mnew.movgest_id, tsnew.movgest_ts_id
       from siac_t_movgest mnew, siac_t_movgest_ts tsnew, siac_r_movgest_ts_stato rs
       where mnew.bil_id=bilancioId
       and   mnew.movgest_tipo_id=movGestTipoIId
       and   mnew.movgest_anno::integer>=annoBilancio
       and   tsnew.movgest_id=mnew.movgest_id
       and   rs.movgest_ts_id=tsnew.movgest_ts_id
       and   rs.movgest_stato_id!=movgestStatoAId
       and   rs.data_cancellazione is null
       and   rs.validita_fine is null
       and   mnew.data_cancellazione is null
       and   mnew.validita_fine is null
       and   tsnew.data_cancellazione is null
       and   tsnew.validita_fine is null
      ),
      titoloNew as
      (
      	select rmov.movgest_id, cTitolo.classif_code::integer titolo_uscita,
               ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                      then 'FPVSC'
                      when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                      then 'FPVCC'
                      else null end ) tipo_avanzo
        from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
             siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
             siac_r_class_fam_tree rfam,
             siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
             siac_r_movgest_bil_elem rmov
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.elem_tipo_code='CAP-UG'
        and   e.elem_tipo_id=tipo.elem_tipo_id
        and   e.bil_id=bilancioId
        and   rc.elem_id=e.elem_id
        and   cMacro.classif_id=rc.classif_id
        and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
        and   tipomacro.classif_tipo_code='MACROAGGREGATO'
        and   rfam.classif_id=cMacro.classif_id
        and   cTitolo.classif_id=rfam.classif_id_padre
        and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
        and   tipoTitolo.classif_tipo_code='TITOLO_SPESA'
        and   rmov.elem_id=e.elem_id
        and   e.data_cancellazione is null
        and   e.validita_fine is null
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
        and   rfam.data_cancellazione is null
        and   rfam.validita_fine is null
        and   rmov.data_cancellazione is null
        and   rmov.validita_fine is null
      ),
      tipoAv as
      (
       select av.avav_id, tipoav.avav_tipo_code
       from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo tipoav
       where tipoav.ente_proprietario_id=enteProprietarioId
       and   av.avav_tipo_id=tipoav.avav_tipo_id
       and   tipoav.avav_tipo_code in ('FPVSC','FPVCC')
       -- 07.02.2018 - Daniela SIAC-5852
       and   av.validita_inizio = to_date('01/01/'||annoBilancio::varchar,'dd/MM/yyyy')
       and   av.validita_fine is null
       and   av.data_cancellazione is NULL
      )
      select faseBilElabId, 				-- fase_bil_elab_id
             vincPrec.movgest_ts_id, 		-- movgest_orig_ts_b_id
             vincPrec.movgest_ts_a_id, 		-- movgest_orig_ts_a_id
             vincPrec.movgest_ts_r_id,  	-- movgest_orig_ts_r_id
             bilancioPrecId, 				-- bil_orig_id
             vincPrec.movgest_ts_importo, 	-- importo_orig_vinc
             impNew.movgest_ts_id, 			-- movgest_ts_b_id
             vincPrec.movgest_ts_importo, 	-- importo_vinc
             tipoAv.avav_id,  				-- avav_id
             bilancioId, 					-- bil_id
             dataInizioVal,
	         loginOperazione,
	         enteProprietarioId
      from vincPrec, impNew, titoloNew, tipoAv
      where vincPrec.movgest_anno=impNew.movgest_anno
      and   vincPrec.movgest_numero=impNew.movgest_numero
      and   vincPrec.movgest_ts_code=impNew.movgest_ts_code
      and   vincPrec.movgest_ts_tipo_id=impNew.movgest_ts_tipo_id
      and   titoloNew.movgest_id=impNew.movgest_id
      and   tipoAv.avav_tipo_code=titoloNew.tipo_avanzo
      );

     strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli - FINE inserimenti - caso 2.b';
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


     strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli - INIZIO inserimenti - caso 3';
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

     -- caso 3
	 -- il movimento nel bilancio precedente presentava un legame ad un accertamento di competenza/pluriennale rispetto al nuovo bilancio: ricreare lo stesso vincolo per la
	 --  quota così come presente nel vecchio bilancio ( l'accertamento deve esistere nel nuovo bilancio ) movgest_ts_id_b e movgest_ts_id_a
	 insert into fase_bil_t_gest_apertura_vincoli
     (fase_bil_elab_id,
      movgest_orig_ts_b_id,
      movgest_orig_ts_a_id,
      movgest_orig_ts_r_id,
      bil_orig_id,
      importo_orig_vinc,
      movgest_ts_b_id,
      movgest_ts_a_id,
      importo_vinc,
	  avav_id,
      bil_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
      )
      (
      with
      vincPrec as
      (
      select mb.movgest_anno::integer, mb.movgest_numero::integer,
             tsb.movgest_ts_code::integer,
             tsb.movgest_ts_tipo_id,
             mb.movgest_id, tsb.movgest_ts_id,
             ma.movgest_anno::integer movgest_anno_a, ma.movgest_numero::integer movgest_numero_a,
             tsa.movgest_ts_code::integer movgest_ts_code_a,
             tsa.movgest_ts_tipo_id movgest_ts_tipo_a_id,
             ma.movgest_id movgest_a_id, tsa.movgest_ts_id movgest_ts_a_id,
             r.movgest_ts_r_id,
             r.movgest_ts_importo,
             r.avav_id,
             av.avav_tipo_id
      from siac_r_movgest_ts r left outer join siac_t_avanzovincolo av on (r.avav_id = av.avav_id)
      	   ,siac_t_movgest mb,siac_t_movgest_ts tsb ,
           siac_t_movgest ma,siac_t_movgest_ts tsa
      where mb.bil_id=bilancioPrecId
	  and   mb.movgest_tipo_id=movGestTipoIId
      and   mb.movgest_anno::INTEGER>=annoBilancio
	  and   tsb.movgest_id=mb.movgest_id
	  and   r.movgest_ts_b_id=tsb.movgest_ts_id
      and   tsa.movgest_ts_id=r.movgest_ts_a_id
      and   ma.movgest_id=tsa.movgest_id
      and   ma.movgest_tipo_id=movGestTipoAId
      and   ma.bil_id=bilancioPrecId
      and   ma.movgest_anno::INTEGER>=annoBilancio
	  and   mb.data_cancellazione is null
	  and   mb.validita_fine is null
	  and   tsb.data_cancellazione is null
	  and   tsb.validita_fine is null
	  and   ma.data_cancellazione is null
	  and   ma.validita_fine is null
	  and   tsa.data_cancellazione is null
	  and   tsa.validita_fine is null
	  and   r.data_cancellazione is null
      and   r.validita_fine is null
      ),
      impNew as
      (select mnew.movgest_anno::integer, mnew.movgest_numero::integer,
              tsnew.movgest_ts_code::integer,
              tsnew.movgest_ts_tipo_id,
              mnew.movgest_id, tsnew.movgest_ts_id
       from siac_t_movgest mnew, siac_t_movgest_ts tsnew, siac_r_movgest_ts_stato rs
       where mnew.bil_id=bilancioId
       and   mnew.movgest_tipo_id=movGestTipoIId
       and   mnew.movgest_anno::integer>=annoBilancio
       and   tsnew.movgest_id=mnew.movgest_id
       and   rs.movgest_ts_id=tsnew.movgest_ts_id
       and   rs.movgest_stato_id!=movgestStatoAId
       and   rs.data_cancellazione is null
       and   rs.validita_fine is null
       and   mnew.data_cancellazione is null
       and   mnew.validita_fine is null
       and   tsnew.data_cancellazione is null
       and   tsnew.validita_fine is null
      ),
      accNew as
      (select mnew.movgest_anno::integer, mnew.movgest_numero::integer,
              tsnew.movgest_ts_code::integer,
              tsnew.movgest_ts_tipo_id,
              mnew.movgest_id, tsnew.movgest_ts_id
       from siac_t_movgest mnew, siac_t_movgest_ts tsnew, siac_r_movgest_ts_stato rs
       where mnew.bil_id=bilancioId
       and   mnew.movgest_tipo_id=movGestTipoAId
       and   mnew.movgest_anno::integer>=annoBilancio
       and   tsnew.movgest_id=mnew.movgest_id
       and   rs.movgest_ts_id=tsnew.movgest_ts_id
       and   rs.movgest_stato_id!=movgestStatoAId
       and   rs.data_cancellazione is null
       and   rs.validita_fine is null
       and   mnew.data_cancellazione is null
       and   mnew.validita_fine is null
       and   tsnew.data_cancellazione is null
       and   tsnew.validita_fine is null
      )
      -- 07.02.2018 - Daniela SIAC-5852
      , avavNew as
      ( select av.avav_id, av.avav_tipo_id
        from siac_t_avanzoVincolo av
        where av.ente_proprietario_id = enteProprietarioId
        and   av.validita_inizio = to_date('01/01/'||annoBilancio::varchar,'dd/MM/yyyy')
        and   av.validita_fine is null
        and   av.data_cancellazione is NULL
        )
      select faseBilElabId, 				-- fase_bil_elab_id
             vincPrec.movgest_ts_id, 		-- movgest_orig_ts_b_id
             vincPrec.movgest_ts_a_id, 		-- movgest_orig_ts_a_id
             vincPrec.movgest_ts_r_id,  	-- movgest_orig_ts_r_id
             bilancioPrecId, 				-- bil_orig_id
             vincPrec.movgest_ts_importo, 	-- importo_orig_vinc
             impNew.movgest_ts_id, 			-- movgest_ts_b_id
             accNew.movgest_ts_id,          -- movgest_ts_a_id
             vincPrec.movgest_ts_importo, 	-- importo_vinc
--             vincPrec.avav_id,  			-- avav_id
             avavNew.avav_id,  				-- avav_id
             bilancioId, 					-- bil_id
       		 dataInizioVal,
	         loginOperazione,
	         enteProprietarioId
      from vincPrec left outer join avavNew on (avavNew.avav_tipo_id = vincPrec.avav_tipo_id)
      , impNew, accNew
      where vincPrec.movgest_anno=impNew.movgest_anno
      and   vincPrec.movgest_numero=impNew.movgest_numero
      and   vincPrec.movgest_ts_code=impNew.movgest_ts_code
      and   vincPrec.movgest_ts_tipo_id=impNew.movgest_ts_tipo_id
      and   vincPrec.movgest_anno_a=accNew.movgest_anno
      and   vincPrec.movgest_numero_a=accNew.movgest_numero
      and   vincPrec.movgest_ts_code_a=accNew.movgest_ts_code
      and   vincPrec.movgest_ts_tipo_a_id=accNew.movgest_ts_tipo_id
      );

     strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli - FINE inserimenti - caso 3';
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




     strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli - FINE inserimenti';
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
	 strMessaggio:='Verifica inserimento dati in fase_bil_t_gest_apertura_vincoli.';
	 select  1 into codResult
     from fase_bil_t_gest_apertura_vincoli vinc
     where vinc.fase_bil_elab_id=faseBilElabId
     and   vinc.data_cancellazione is null
     and   vinc.validita_fine is null;

     if codResult is null then
     	raise exception ' Nessun inserimento effettuato.';
     end if;


     strMessaggio:='Aggiornamento stato fase bilancio IN-1.';
     update fase_bil_t_elaborazione fase
     set fase_bil_elab_esito='IN-1',
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_VINCOLI||' IN CORSO IN-1.POPOLA VINCOLI.'
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