/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

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

    ordStatoAId       INTEGER:=null;
    ordTsDetATipoId   integer:=null;

	movgestStatoAId   integer:=null;
	movGestTsDetTipoAId   integer:=null;


	annoImpegnoCur        integer:=null;
    annoImpegnoPrec       integer:=0;
    numeroImpegnoCur      integer:=null;
    numeroImpegnoPrec    integer:=0;
    numeroSubImpegnoCur   integer:=null;
    numeroSubImpegnoPrec  integer:=0;

    impoAttImpegno        numeric:=null;
    totPagatoImpegno      numeric:=null;
    pagatoVincImpegno     numeric:=null;
    pagatoVincImpegnoCur  numeric:=null;
    importoVincoloCur     numeric:=null;


	movGestTipoIId        integer:=null;
    movGestTipoAId        integer:=null;
	movGestTsAId          integer:=null;

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


    APE_GEST_VINCOLI    CONSTANT varchar:='APE_GEST_VINCOLI';


    A_ORD_STATO       CONSTANT varchar:='A';
    A_ORD_TS_DET_TIPO CONSTANT varchar:='A';
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


     strMessaggio:='Lettura id identificativo per ordStatoA='||A_ORD_STATO||'.';
     select stato.ord_stato_id into strict ordStatoAId
     from siac_d_ordinativo_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.ord_stato_code=A_ORD_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;


     strMessaggio:='Lettura id identificativo per movgestStatoAId='||A_IMP_STATO||'.';
     select stato.movgest_stato_id into strict movgestStatoAId
     from siac_d_movgest_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.movgest_stato_code=A_IMP_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;


     strMessaggio:='Lettura id identificativo per ordTsDetATipo='||A_ORD_TS_DET_TIPO||'.';
     select tipo.ord_ts_det_tipo_id into strict ordTsDetATipoId
     from siac_d_ordinativo_ts_det_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.ord_ts_det_tipo_code=A_ORD_STATO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

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

    codResult:=null;
	select 1 into codResult
    from siac_r_movgest_ts r,
         siac_t_movgest ma,siac_t_movgest_ts tsa,
         siac_t_movgest mb,siac_t_movgest_ts tsb
    where ma.ente_proprietario_id=enteProprietarioId
    and   ma.bil_id=bilancioPrecId
    and   tsa.movgest_id=ma.movgest_id
    and   mb.ente_proprietario_id=enteProprietarioId
    and   mb.bil_id=bilancioPrecId
    and   tsb.movgest_id=mb.movgest_id
    and   r.movgest_ts_a_id=tsa.movgest_ts_id
    and   r.movgest_ts_b_id=tsb.movgest_ts_id
    and   ma.data_cancellazione is null
    and   ma.validita_fine is null
    and   mb.data_cancellazione is null
    and   mb.validita_fine is null
    and   tsa.data_cancellazione is null
    and   tsa.validita_fine is null
    and   tsb.data_cancellazione is null
    and   tsb.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   exists (select 1 from siac_t_movgest mnew, siac_t_movgest_ts tsnew, siac_r_movgest_ts_stato rs
   				  where mnew.bil_id=bilancioId
                  and   mnew.movgest_tipo_id=ma.movgest_tipo_id
                  and   mnew.movgest_anno=ma.movgest_anno
                  and   mnew.movgest_numero=ma.movgest_numero
                  and   tsnew.movgest_id=mnew.movgest_id
                  and   tsnew.movgest_ts_tipo_id=tsa.movgest_ts_tipo_id
                  and   tsnew.movgest_ts_code=tsa.movgest_ts_code
                  and   rs.movgest_ts_id=tsnew.movgest_ts_id
                  and   rs.movgest_stato_id!=movgestStatoAId
                  and   rs.data_cancellazione is null
                  and   rs.validita_fine is null
                  and   mnew.data_cancellazione is null
                  and   mnew.validita_fine is null
                  and   tsnew.data_cancellazione is null
                  and   tsnew.validita_fine is null)
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


     strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli - INIZIO ciclo';
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
     (select  mb.movgest_id  movgest_b_id,      tsb.movgest_ts_id movgest_ts_b_id,
     		  mnew.movgest_id movgest_b_new_id, tsnew.movgest_ts_id movgest_ts_b_new_id,
              mb.movgest_anno::integer anno_impegno, mb.movgest_numero::integer numero_impegno,
              tsb.movgest_ts_code::integer numero_subimpegno ,
              ma.movgest_id  movgest_a_id,      tsa.movgest_ts_id movgest_ts_a_id,
              ma.movgest_anno::integer anno_accertamento, ma.movgest_numero::integer numero_accertamento,
              tsa.movgest_ts_code::integer numero_subaccertamento,
              r.movgest_ts_r_id , r.movgest_ts_importo importo_vincolato
      from  siac_r_movgest_ts r, siac_t_movgest mb, siac_t_movgest_ts tsb,
            siac_r_movgest_ts_stato rsb,
            siac_t_movgest mnew, siac_t_movgest_ts tsnew,
            siac_r_movgest_ts_stato rsbnew,
            siac_t_movgest ma, siac_t_movgest_ts tsa, siac_r_movgest_ts_stato rsa
      where mb.ente_proprietario_id=enteProprietarioId
      and   mb.bil_id=bilancioPrecId
      and   mb.movgest_tipo_id=movGestTipoIId
      and   tsb.movgest_id=mb.movgest_id   -- impegno bilancio prec.
      and   r.movgest_ts_b_id=tsb.movgest_ts_id -- vincolato
      and   rsb.movgest_ts_id=tsb.movgest_ts_id
      and   rsb.movgest_stato_id!=movgestStatoAId -- non annullato
      and   mnew.bil_id=bilancioId -- esistente nel nuovo bilancio
      and   mnew.movgest_tipo_id=mb.movgest_tipo_id
      and   mnew.movgest_anno=mb.movgest_anno
      and   mnew.movgest_numero=mb.movgest_numero
      and   tsnew.movgest_id=mnew.movgest_id
      and   tsnew.movgest_ts_code=tsb.movgest_ts_code
      and   tsnew.movgest_ts_tipo_id=tsb.movgest_ts_tipo_id
      and   rsbnew.movgest_ts_id=tsnew.movgest_ts_id
      and   rsbnew.movgest_stato_id!=movgestStatoAId --  non annullato
      and   tsa.movgest_ts_id=r.movgest_ts_a_id -- collegato a accertamento non annullato
      and   ma.movgest_id=tsa.movgest_id
      and   ma.bil_id=bilancioPrecId
      and   ma.movgest_tipo_id=movGestTipoAId
      and   rsa.movgest_ts_id=tsa.movgest_ts_id
      and   rsa.movgest_stato_id!=movgestStatoAId
      and   exists (select 1  -- esiste accertamento in nuovo anno di bilancio non annullato
                    from  siac_t_movgest manew, siac_t_movgest_ts tsanew, siac_r_movgest_ts_stato rsanew
                    where manew.bil_id=bilancioId
                    and   manew.movgest_anno=ma.movgest_anno
                    and   manew.movgest_numero=ma.movgest_numero
                    and   manew.movgest_tipo_id=ma.movgest_tipo_id
                    and   tsanew.movgest_id=manew.movgest_id
                    and   tsanew.movgest_ts_code=tsa.movgest_ts_code
                    and   tsanew.movgest_ts_tipo_id=tsa.movgest_ts_tipo_id
                    and   rsanew.movgest_ts_id=tsanew.movgest_ts_id
                    and   rsanew.movgest_stato_id!=movgestStatoAId
                    and   rsanew.data_cancellazione is null
                    and   rsanew.validita_fine is null
                    and   manew.data_cancellazione is null
                    and   manew.validita_fine is null
                    and   tsanew.data_cancellazione is null
                    and   tsanew.validita_fine is null
                   )
      and   r.data_cancellazione is null
      and   r.validita_fine is null
      and   mb.data_cancellazione is null
      and   mb.validita_fine is null
      and   tsb.data_cancellazione is null
      and   tsb.validita_fine is null
      and   rsb.data_cancellazione is null
      and   rsb.validita_fine is null
      and   ma.data_cancellazione is null
      and   ma.validita_fine is null
      and   tsa.data_cancellazione is null
      and   tsa.validita_fine is null
      and   rsa.data_cancellazione is null
      and   rsa.validita_fine is null
      and   mnew.data_cancellazione is null
      and   mnew.validita_fine is null
      and   tsnew.data_cancellazione is null
      and   tsnew.validita_fine is null
      and   rsbnew.data_cancellazione is null
      and   rsbnew.validita_fine is null
      order by mb.movgest_anno::integer, mb.movgest_numero::integer, tsb.movgest_ts_code::integer,
               ma.movgest_anno::integer, ma.movgest_numero::integer, tsa.movgest_ts_code::integer
     )
     loop

      annoImpegnoCur:=movGestRec.anno_impegno;
      numeroImpegnoCur:=movGestRec.numero_impegno;
      numeroSubImpegnoCur:=movGestRec.numero_subimpegno;

      strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli impegno '||
                    annoImpegnoCur||'/'||numeroImpegnoCur||' sub='||numeroSubImpegnoCur
                    ||'.Importo vincolato='||movGestRec.importo_vincolato||'.';
		 raise notice 'strMessaggio= % ',strMessaggio;

      if annoImpegnoCur!=annoImpegnoPrec or
         numeroImpegnoCur!=numeroImpegnoPrec or
         numeroSubImpegnoCur!=numeroSubImpegnoPrec then

		strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli impegno '||
                    annoImpegnoCur||'/'||numeroImpegnoCur||' sub='||numeroSubImpegnoCur||'. Nuovo impegno.';
		 raise notice 'strMessaggio= % ',strMessaggio;

/*       mi sembra che non serva
         strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli impegno '||
                        annoImpegnoCur||'/'||numeroImpegnoCur||' sub='||numeroSubImpegnoCur||'. Calcolo importo attuale.';

         impoAttImpegno:=0;
         -- calcolo impoatt
         select det.movgest_ts_det_importo into impoAttImpegno
         from siac_t_movgest_ts_det det
         where det.movgest_ts_id=movGestRec.movgest_ts_b_id
         and   det.movgest_ts_det_tipo_id=movGestTsDetTipoAId
         and   det.data_cancellazione is null
         and   det.validita_fine is null;

         if impoAttImpegno is null then
         	raise exception ' Errore in fase di calcolo.';
         end if;*/


         -- non fare per pluriennale
         -- calcolo pagato
         totPagatoImpegno:=0;
         if annoImpegnoCur<annoBilancio::integer then
         	strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli impegno '||
                        annoImpegnoCur||'/'||numeroImpegnoCur||' sub='||numeroSubImpegnoCur||'. Calcolo pagato.';

            raise notice 'strMessaggio % calcolo pagato',strMessaggio;

			select coalesce(sum(det.ord_ts_det_importo),0) into totPagatoImpegno
            from siac_r_liquidazione_movgest rliq,
                 siac_r_liquidazione_ord     rliqord,
                 siac_t_ordinativo_ts ts, siac_t_ordinativo ord,siac_r_ordinativo_stato rs,
                 siac_t_ordinativo_ts_det det
            where rliq.movgest_ts_id=movGestRec.movgest_ts_b_id
            and   rliqord.liq_id=rliq.liq_id
            and   ts.ord_ts_id=rliqord.sord_id
            and   ord.ord_id=ts.ord_id
            and   rs.ord_id=ord.ord_id
            and   rs.ord_stato_id!=ordStatoAId
            and   det.ord_ts_id=ts.ord_ts_id
            and   det.ord_ts_det_tipo_id=ordTsDetATipoId
            and   rliq.data_cancellazione is null
            and   rliq.validita_fine is null
            and   rliqord.data_cancellazione is null
            and   rliqord.validita_fine is null
            and   ord.data_cancellazione is null
            and   ord.validita_fine is null
            and   ts.data_cancellazione is null
            and   ts.validita_fine is null
            and   det.data_cancellazione is null
            and   det.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null;

			raise notice 'totPagatoImpegno=%',totPagatoImpegno;
            if totPagatoImpegno is null then
              totPagatoImpegno:=0;
            end if;


         end if;

		 annoImpegnoPrec:=annoImpegnoCur;
         numeroImpegnoPrec:=numeroImpegnoCur;
         numeroSubImpegnoPrec:=numeroSubImpegnoCur;

         pagatoVincImpegno:=totPagatoImpegno;
      end if;

      -- non fare per pluriennale
      if annoImpegnoCur<annoBilancio::integer then
      strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli impegno '||
                        annoImpegnoCur||'/'||numeroImpegnoCur||' sub='||numeroSubImpegnoCur||'. Calcolo pagato vincolo.';

            raise notice 'strMessaggio % calcolo pagato',strMessaggio;
       -- calcolo pagato su Vincolo corrente
 	   if pagatoVincImpegno> movGestRec.importo_vincolato then
      	pagatoVincImpegnoCur:=movGestRec.importo_vincolato;
       else
        pagatoVincImpegnoCur:=pagatoVincImpegno;
       end if;
       pagatoVincImpegno:=pagatoVincImpegno-pagatoVincImpegnoCur; --3

      end if;
      raise notice 'pagatoVincImpegnoCur=%',pagatoVincImpegnoCur;
      raise notice 'movGestRec.importo_vincolato=%',movGestRec.importo_vincolato;

      importoVincoloCur:=movGestRec.importo_vincolato-coalesce(pagatoVincImpegnoCur,0); -- 3
      raise notice 'importoVincoloCur=%',importoVincoloCur;

      -- leggi accertamento new
      strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli impegno '||
                     annoImpegnoCur||'/'||numeroImpegnoCur||' sub='||numeroSubImpegnoCur
                     ||'. Lettura vincolo per su movGestRec.movgest_ts_a_id='||movGestRec.movgest_ts_a_id||'.';
      movGestTsAId:=0;
      select tsnew.movgest_ts_id into movGestTsAId
      from siac_t_movgest_ts ts,
           siac_t_movgest movnew, siac_t_movgest_ts tsnew,
           siac_r_movgest_ts_stato rs
      where ts.movgest_ts_id=movGestRec.movgest_ts_a_id
      and   movnew.bil_id=bilancioId
      and   movnew.movgest_tipo_id=movGestTipoAId
      and   movnew.movgest_anno::integer=movGestRec.anno_accertamento
      and   movnew.movgest_numero::integer=movGestRec.numero_accertamento
      and   tsnew.movgest_id=movnew.movgest_id
      and   tsnew.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   tsnew.movgest_ts_code=ts.movgest_ts_code
      and   tsnew.movgest_ts_code::integer=movGestRec.numero_subaccertamento
	  and   rs.movgest_ts_id=tsnew.movgest_ts_id
      and   rs.movgest_stato_id!=movgestStatoAId
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   tsnew.data_cancellazione is null
      and   tsnew.validita_fine is null
      and   movnew.data_cancellazione is null
      and   movnew.validita_fine is null;

      if movGestTsAId is null then
      	raise exception ' Errore in lettura.';
      end if;


      codResult:=null;
      strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli impegno '||
                     annoImpegnoCur||'/'||numeroImpegnoCur||' sub='||numeroSubImpegnoCur
                     ||'.';
      insert into fase_bil_t_gest_apertura_vincoli
      (fase_bil_elab_id,
       movgest_orig_ts_a_id,
       movgest_orig_ts_b_id,
       movgest_orig_ts_r_id,
       bil_orig_id,
       importo_orig_vinc,
       importo_orig_pag_vinc,
       movgest_ts_a_id,
       movgest_ts_b_id,
       importo_vinc,
       bil_id,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
       )
      values
      (faseBilElabId,
       movGestRec.movgest_ts_a_id,
       movGestRec.movgest_ts_b_id,
       movGestRec.movgest_ts_r_id,
       bilancioPrecId,
       movGestRec.importo_vincolato,
       coalesce(pagatoVincImpegnoCur,0),
       movGestTsAId,
       movGestRec.movgest_ts_b_new_id,
       importoVincoloCur,
       bilancioId,
       dataInizioVal,
       loginOperazione,
       enteProprietarioId
       )
       returning fase_bil_gest_ape_vinc_id into codResult;

       if codResult is null then
     	raise exception ' Errore in inserimento.';
       end if;


     end loop;

     strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli - FINE ciclo';
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