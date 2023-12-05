/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

DROP FUNCTION IF EXISTS siac.fnc_fasi_bil_gest_apertura_acc_elabora 
(
  enteproprietarioid integer,
  annobilancio integer,
  fasebilelabid integer,
  minid integer,
  maxid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_acc_elabora (
  enteproprietarioid integer,
  annobilancio integer,
  fasebilelabid integer,
  minid integer,
  maxid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
    strMessaggioTemp VARCHAR(1000):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

	tipoMovGestId      integer:=null;
    movGestTsTipoId    integer:=null;
    tipoMovGestTsSId   integer:=null;
    tipoMovGestTsTId   integer:=null;
    tipoCapitoloGestId integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;
    dataEmissione     timestamp:=null;
	movGestIdRet      integer:=null;
    movGestTsIdRet    integer:=null;
    elemNewId         integer:=null;
	movGestTsTipoTId  integer:=null;
	movGestTsTipoSId  integer:=null;
	movGestTsTipoCode VARCHAR(10):=null;
    movGestStatoAId   integer:=null;
	movgGestTsIdPadre integer:=null;

    movGestRec        record;

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


	ACC_MOVGEST_TIPO CONSTANT varchar:='A';
  	IMP_MOVGEST_TIPO CONSTANT varchar:='I';

	CAP_UG_TIPO      CONSTANT varchar:='CAP-EG';

    MOVGEST_TS_T_TIPO CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO CONSTANT varchar:='S';

    A_MOV_GEST_STATO  CONSTANT varchar:='A';
    APE_GEST_ACC_RES    CONSTANT varchar:='APE_GEST_ACC_RES';

    A_MOV_GEST_DET_TIPO  CONSTANT varchar:='A';
    I_MOV_GEST_DET_TIPO  CONSTANT varchar:='I';
    U_MOV_GEST_DET_TIPO  CONSTANT varchar:='U';

    -- 17.02.2017 Sofia HD-INC000001535447
    ATTO_AMM_FIT_TIPO  CONSTANT varchar:='SPR';
    ATTO_AMM_FIT_OGG CONSTANT varchar:='Passaggio residuo.';
    ATTO_AMM_FIT_STATO CONSTANT VARCHAR:='DEFINITIVO';
    attoAmmFittizioId integer:=null;
	attoAmmNumeroFittizio  VARCHAR(10):='9'||annoBilancio::varchar||'99';

	-- 03.05.2019 Sofia siac-6255
    faseOp                    VARCHAR(10):=null;
    G_FASE                    CONSTANT varchar:='G'; -- gestione approvata

BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;



    dataInizioVal:= clock_timestamp();

	strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento accertamenti  residui  da Gestione precedente. Anno bilancio='||annoBilancio::varchar
                         ||'.Elabora  minId='||coalesce(minId::varchar,' ')||' maxId='||coalesce(maxId::varchar,' ')
                         ||'. Fase Elaborazione Id='||faseBilElabId||'.';

     raise notice 'strMessaggioFinale %',strMessaggioFinale;

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
    strMessaggio:='Verifica esistenza in fase_bil_t_gest_apertura_acc di movimenti da generare.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_acc fase
 	where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
	and   fase.validita_fine is null
    and   fase.fl_elab='N'
    and   fase.movgest_orig_id is not null
    and   fase.movgest_orig_ts_id is not null;
    if codResult is null then
    	 raise exception ' Nessun movimento presente.';
    end if;

    if coalesce(minId,0)=0 or coalesce(maxId,0)=0 then
        strMessaggio:='Calcolo min, max Id da elaborare in [fase_bil_t_gest_apertura_acc].';
    	minId:=1;

        select max(fase.fase_bil_gest_ape_acc_id) into maxId
        from fase_bil_t_gest_apertura_acc fase
	    where fase.fase_bil_elab_id=faseBilElabId
    	and   fase.data_cancellazione is null
	    and   fase.validita_fine is null
        and   fase.fl_elab='N';
        if coalesce(maxId ,0)=0 then
        	raise exception ' Impossibile determinare il maxId';
        end if;

    end if;

	-- 12.11.2019 Sofia SIAC-7145 - inizio
    strMessaggio:='Aggiornamento movimenti da creare in fase_bil_t_gest_apertura_acc per esclusione importi a zero.';
    update fase_bil_t_gest_apertura_acc fase
    set  scarto_code='IMP',
         scarto_desc='Importo a residuo pari a zero',
         fl_elab='X'
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_gest_ape_acc_id between minId and maxId
    and   fase.fl_elab='N'
    and   fase.imp_importo=0
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;

	codResult:=null;
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_acc dopo esclusione importi a zero.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_acc fase
 	where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
	and   fase.validita_fine is null
    and   fase.fl_elab='N'
    and   fase.movgest_orig_id is not null
    and   fase.movgest_orig_ts_id is not null;
    if codResult is null then
    	 raise exception ' Nessun movimento presente.';
    end if;

     strMessaggio:='Lettura id identificativo per tipo capitolo='||CAP_UG_TIPO||'.';
	 select tipo.elem_tipo_id into strict tipoCapitoloGestId
     from siac_d_bil_elem_tipo tipo
     where tipo.elem_tipo_code=CAP_UG_TIPO
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

     -- per A
     strMessaggio:='Lettura id identificativo per tipoMovGestImp='||ACC_MOVGEST_TIPO||'.';
     select tipo.movgest_tipo_id into strict tipoMovGestId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=ACC_MOVGEST_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;





     strMessaggio:='Lettura identificativo per tipoMovGestTsT='||MOVGEST_TS_T_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict tipoMovGestTsTId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_T_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura identificativo per tipoMovGestTsS='||MOVGEST_TS_S_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict tipoMovGestTsSId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_S_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     -- 17.02.2017 Sofia HD-INC000001535447
     strMessaggio:='Lettura id identificativo atto amministrativo fittizio per passaggio residui.';
	 select a.attoamm_id into attoAmmFittizioId
     from siac_d_atto_amm_tipo tipo, siac_t_atto_amm a
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.attoamm_tipo_code=ATTO_AMM_FIT_TIPO
     and   a.attoamm_tipo_id=tipo.attoamm_tipo_id
     and   a.attoamm_anno::integer=annoBilancio
     and   a.attoamm_numero=attoAmmNumeroFittizio::integer
     and   a.data_cancellazione is null
     and   a.validita_fine is null;

     if attoAmmFittizioId is null then
        strMessaggio:='Inserimento atto amministrativo fittizio per passaggio residui.';
     	insert into siac_t_atto_amm
        ( attoamm_anno,
          attoamm_numero,
          attoamm_oggetto,
          attoamm_tipo_id,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
        )
        (select
          annoBilancio::varchar,
          attoAmmNumeroFittizio::integer,
          ATTO_AMM_FIT_OGG,
		  tipo.attoamm_tipo_id,
          dataInizioVal,
          loginOperazione,
          enteProprietarioId
         from siac_d_atto_amm_tipo tipo
         where tipo.ente_proprietario_id=enteProprietarioId
	     and   tipo.attoamm_tipo_code=ATTO_AMM_FIT_TIPO
        )
        returning attoamm_id into attoAmmFittizioId;

        if attoAmmFittizioId is null then
        	raise exception 'Inserimento non effettuato.';
        end if;

        codResult:=null;
        strMessaggio:='Inserimento stato atto amministrativo fittizio per passaggio residui.';
        insert into siac_r_atto_amm_stato
        (attoamm_id,
         attoamm_stato_id,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
        )
        (select  attoAmmFittizioId,
                 stato.attoamm_stato_id,
        		 dataInizioVal,
         		 loginOperazione,
		         enteProprietarioId
         from siac_d_atto_amm_stato stato
         where stato.ente_proprietario_id=enteProprietarioId
         and   stato.attoamm_stato_code=ATTO_AMM_FIT_STATO
         )
         returning att_attoamm_stato_id into codResult;
         if codResult is null then
         	raise exception 'Inserimento non effettuato.';
         end if;
     end if;
     -- 17.02.2017 Sofia HD-INC000001535447

	 -- 03.05.2019 Sofia siac-6255
     strMessaggio:='Lettura fase di bilancio di corrente.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
     if faseOp is null then
		 raise exception ' Impossibile determinare Fase.';
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


     strMessaggio:='Inizio ciclo per generazione accertamenti.';
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

     raise notice 'Prima di inizio ciclo';
     for movGestRec in
     (select  fase.fase_bil_gest_ape_acc_id,
	   		  fase.movgest_ts_tipo,
		      fase.movgest_orig_id,
	          fase.movgest_orig_ts_id,
		      fase.elem_orig_id,
              fase.elem_id,
	          fase.imp_importo
      from  fase_bil_t_gest_apertura_acc fase
      where fase.fase_bil_elab_id=faseBilElabId
      and   fase.fase_bil_gest_ape_acc_id between minId and maxId
      and   fase.fl_elab='N'
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      order by fase.movgest_ts_tipo desc,fase.movgest_orig_id,
	           fase.movgest_orig_ts_id
     )
     loop

     	movGestTsIdRet:=null;
        movGestIdRet:=null;
        movgGestTsIdPadre:=null;
        codResult:=null;




         strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.';
 		 insert into fase_bil_t_elaborazione_log
	     (fase_bil_elab_id,fase_bil_elab_log_operazione,
    	 validita_inizio, login_operazione, ente_proprietario_id
	     )
	     values
    	 (faseBilElabId,strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
	     returning fase_bil_elab_log_id into codResult;

	     if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	     end if;

    	 codResult:=null;
		 if movGestRec.movgest_ts_tipo=MOVGEST_TS_T_TIPO then
      	  strMessaggio:=strMessaggio||'Inserimento Accertamento [siac_t_movgest].';

          raise notice 'strMessaggio %',strMessaggio;
     	  insert into siac_t_movgest
          (movgest_anno,
		   movgest_numero,
		   movgest_desc,
		   movgest_tipo_id,
		   bil_id,
		   validita_inizio,
	       ente_proprietario_id,
	       login_operazione,
	       parere_finanziario,
	       parere_finanziario_data_modifica,
	       parere_finanziario_login_operazione)
          (select
           m.movgest_anno,
		   m.movgest_numero,
		   m.movgest_desc,
		   m.movgest_tipo_id,
		   bilancioId,
		   dataInizioVal,
	       enteProprietarioId,
	       loginOperazione,
	       m.parere_finanziario,
	       m.parere_finanziario_data_modifica,
	       m.parere_finanziario_login_operazione
           from siac_t_movgest m
           where m.movgest_id=movGestRec.movgest_orig_id
          )
          returning movgest_id into movGestIdRet;
          if movGestIdRet is null then
            strMessaggioTemp:=strMessaggio;
            codResult:=-1;
          end if;

		  raise notice 'dopo inserimento siac_t_movgest T movGestIdRet=%',movGestIdRet;
		  raise notice 'dopo inserimento siac_t_movgest T strMessaggioTemp=%',strMessaggioTemp;

	      if codResult is null then
          	  strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Inserimento relazione elemento di bilancio [siac_r_movgest_bil_elem].';
	          insert into siac_r_movgest_bil_elem
    	      (movgest_id,
	    	   elem_id,
	           validita_inizio,
    	       ente_proprietario_id,
        	   login_operazione)
	          values
    	      (movGestIdRet,
        	   movGestRec.elem_id,
	           dataInizioVal,
    	       enteProprietarioId,
        	   loginOperazione
		       )
    	       returning movgest_atto_amm_id into codResult;
        	   if codResult is null then
            	codResult:=-1;
	            strMessaggioTemp:=strMessaggio;
               else codResult:=null;
    	       end if;
          end if;
      else

        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.Lettura identificativo accertamento.';

          raise notice 'strMessaggio %',strMessaggio;
		select mov.movgest_id into movGestIdRet
        from siac_t_movgest mov, siac_t_movgest movprec
        where movprec.movgest_id=movGestRec.movgest_orig_id
        and   mov.bil_id=bilancioId
        and   mov.movgest_tipo_id=tipoMovGestId
        and   mov.movgest_anno=movprec.movgest_anno
        and   mov.movgest_numero=movprec.movgest_numero
        and   mov.data_cancellazione is null
        and   mov.validita_fine is null
        and   movprec.data_cancellazione is null
        and   movprec.validita_fine is null;

        if movGestIdRet is null then
	        codResult:=-1;
            strMessaggioTemp:=strMessaggio;
        end if;

        raise notice 'dopo lettura siac_t_movgest T per inserimento subaccertamento movGestIdRet=%',movGestIdRet;

        if codResult is null then

         	 strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.Lettura identificativo siac_t_movgest_ts movgGestTsIdPadre.';

        	select ts.movgest_ts_id into movgGestTsIdPadre
	        from siac_t_movgest_ts ts
    	    where ts.movgest_id=movGestIdRet
	        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
    	    and   ts.data_cancellazione is null
        	and   ts.validita_fine is null;

			raise notice 'dopo lettura siac_t_movgest_ts T per inserimento subaccertamento movgGestTsIdPadre=%',movgGestTsIdPadre;

        end if;

        raise notice 'dopo lettura siac_t_movgest movGestIdRet=%',movGestIdRet;
        raise notice 'dopo lettura siac_t_movgest strMessaggioTemp=%',strMessaggioTemp;
      end if;

      -- inserimento TS sia T che S
      if codResult is null then
   	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'Inserimento [siac_t_movgest_ts].';

		raise notice 'strMessaggio=% ',strMessaggio;

        insert into siac_t_movgest_ts
        ( movgest_ts_code,
          movgest_ts_desc,
          movgest_id,
	      movgest_ts_tipo_id,
          movgest_ts_id_padre,
          movgest_ts_scadenza_data,
	      ordine,
		  livello,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione,
	      login_creazione,
	      siope_tipo_debito_id,
		  siope_assenza_motivazione_id

        )
        ( select
          ts.movgest_ts_code,
          ts.movgest_ts_desc,
          movGestIdRet,    -- inserito se I, per SUB ricavato
          ts.movgest_ts_tipo_id,
          movgGestTsIdPadre, -- da ricavare dal TS T di accertamento padre
          ts.movgest_ts_scadenza_data,
          ts.ordine,
          ts.livello,
--          dataEmissione,
          ts.validita_inizio, -- i residui devono mantenere la loro data di emissione originale
          enteProprietarioId,
          loginOperazione,
          loginOperazione,
          ts.siope_tipo_debito_id,
		  ts.siope_assenza_motivazione_id


          from siac_t_movgest_ts ts
          where ts.movgest_ts_id=movGestRec.movgest_orig_ts_id
         )
        returning movgest_ts_id into  movGestTsIdRet;
        if movGestTsIdRet is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        end if;
       end if;

       raise notice 'dopo inserimento siac_t_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

       -- siac_r_movgest_ts_stato
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                       ' [siac_r_movgest_ts_stato].';

        insert into siac_r_movgest_ts_stato
        ( movgest_ts_id,
          movgest_stato_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_stato_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_stato r, siac_d_movgest_stato stato
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   stato.movgest_stato_id=r.movgest_stato_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   stato.data_cancellazione is null
          and   stato.validita_fine is null
         )
        returning movgest_stato_r_id into  codResult;
        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;
        raise notice 'dopo inserimento siac_r_movgest_ts_stato movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

       -- siac_t_movgest_ts_det
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                     ' [siac_t_movgest_ts_det].';
        raise notice ' inserimento siac_t_movgest_ts_det movGestTsIdRet=% movGestRec.movgest_orig_ts_id=%', movGestTsIdRet,movGestRec.movgest_orig_ts_id;

        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        (  select
           movGestTsIdRet,
           tipo.movgest_ts_det_tipo_id,
           movGestRec.imp_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_d_movgest_ts_det_tipo tipo
          where  tipo.ente_proprietario_id=enteProprietarioId
          and    tipo.movgest_ts_det_tipo_code in (A_MOV_GEST_DET_TIPO,I_MOV_GEST_DET_TIPO,U_MOV_GEST_DET_TIPO)
         );

		select 1 into codResult
        from siac_t_movgest_ts_det det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_t_movgest_ts_det movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_class
       if codResult is null then
   	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                     ' [siac_r_movgest_class].';

        insert into siac_r_movgest_class
        ( movgest_ts_id,
          classif_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.classif_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_class r, siac_t_class class
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   class.classif_id=r.classif_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   class.data_cancellazione is null
          and   class.validita_fine is null
         );

        select 1 into codResult
        from siac_r_movgest_class det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_r_movgest_class movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
         else codResult:=null;
         end if;
       end if;

       -- siac_r_movgest_ts_attr
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_attr].';

        insert into siac_r_movgest_ts_attr
        ( movgest_ts_id,
          attr_id,
          tabella_id,
		  boolean,
	      percentuale,
		  testo,
	      numerico,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
          movGestTsIdRet,
          r.attr_id,
          r.tabella_id,
		  r.boolean,
	      r.percentuale,
		  r.testo,
	      r.numerico,
          dataInizioVal,
          enteProprietarioId,
          loginOperazione
          from siac_r_movgest_ts_attr r, siac_t_attr attr
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   attr.attr_id=r.attr_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   attr.data_cancellazione is null
          and   attr.validita_fine is null
         );

		select 1 into codResult
        from siac_r_movgest_ts_attr det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_r_movgest_ts_attr movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_atto_amm
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_atto_amm].';

        insert into siac_r_movgest_ts_atto_amm
        ( movgest_ts_id,
          attoamm_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.attoamm_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_atto_amm r, siac_t_atto_amm atto
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   atto.attoamm_id=r.attoamm_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
--          and   atto.data_cancellazione is null 17.02.2017 Sofia HD-INC000001535447
--          and   atto.validita_fine is null
         );



		select 1  into codResult
        from siac_r_movgest_ts_atto_amm det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_atto_amm det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        raise notice 'dopo inserimento siac_r_movgest_ts_atto_amm movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

		-- 17.02.2017 Sofia HD-INC000001535447 inserimento relazione con atto amministrativo fittizio
        if codResult is not null then
        	codResult:=null;
            strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_atto_amm]. Inserimento atto amm. fittizio.';
        	insert into siac_r_movgest_ts_atto_amm
            (
             movgest_ts_id,
		     attoamm_id,
			 validita_inizio,
			 login_operazione,
			 ente_proprietario_id
            )
            values
            (
             movGestTsIdRet,
             attoAmmFittizioId,
             dataInizioVal,
	         loginOperazione,
             enteProprietarioId
            )
            returning movgest_atto_amm_id into codResult;

            if codResult is null then
       	 		codResult:=-1;
	         	strMessaggioTemp:=strMessaggio;
    	    else codResult:=null;
        	end if;
        end if;
        -- 17.02.2017 Sofia HD-INC000001535447 inserimento relazione con atto amministrativo fittizio
        /*if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;*/

       end if;

       -- siac_r_movgest_ts_sog
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_sog].';

        insert into siac_r_movgest_ts_sog
        ( movgest_ts_id,
          soggetto_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.soggetto_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_sog r,siac_t_soggetto sogg
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sogg.soggetto_id=r.soggetto_id
          and   sogg.data_cancellazione is null
          and   sogg.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );



 		select 1  into codResult
        from siac_r_movgest_ts_sog det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_sog det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        raise notice 'dopo inserimento siac_r_movgest_ts_sog movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;


        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_sogclasse
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_sogclasse].';

        insert into siac_r_movgest_ts_sogclasse
        ( movgest_ts_id,
          soggetto_classe_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.soggetto_classe_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_sogclasse r,siac_d_soggetto_classe classe
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   classe.soggetto_classe_id=r.soggetto_classe_id
--          and   classe.data_cancellazione is null
--          and   classe.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

        select 1  into codResult
        from siac_r_movgest_ts_sogclasse det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_sogclasse det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_movgest_ts_sogclasse movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;


       -- siac_r_causale_movgest_ts
       /* non si gestisce in seguito ad indicazioni di Annalina
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_causale_movgest_ts].';

        insert into siac_r_causale_movgest_ts
        ( movgest_ts_id,
          caus_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.caus_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_causale_movgest_ts r,siac_d_causale caus
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   caus.caus_id=r.caus_id
          and   caus.data_cancellazione is null
          and   caus.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_causale_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_causale_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_causale_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */


       -- siac_r_subdoc_movgest_ts
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_subdoc_movgest_ts].';
        -- 12.01.2017 Sofia sistemazione gestione quote per escludere quelle incassate
        insert into siac_r_subdoc_movgest_ts
        ( movgest_ts_id,
          subdoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select distinct
           movGestTsIdRet,
           r.subdoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=r.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
          -- SIAC-8551 Sofia - inizio 
          and not exists 
          (
          select 1
          from  siac_r_subdoc_prov_cassa  r ,siac_t_prov_cassa p 
          where r.subdoc_id=sub.subdoc_id 
          and   p.provc_id=r.provc_id 
          and   p.provc_anno::integer=(annoBilancio-1)
          and   p.data_cancellazione is null 
          and   p.validita_fine  is null 
          and   r.data_cancellazione is null 
          and   r.validita_fine is null 
          )
     	  -- SIAC-8551 Sofia - fine
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          -- 10.04.2018 Daniela esclusione documenti annullati (SIAC-6015)
          and   not exists (select 1
          				    from siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                            where doc.doc_id = sub.doc_id
                            and   doc.doc_id = rst.doc_id
                            and   rst.data_cancellazione is null
                            and   rst.validita_fine is null
                            and   st.doc_stato_id = rst.doc_stato_id
                            and   st.doc_stato_code = 'A')
         );

		select 1  into codResult
        from siac_r_subdoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=det1.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
        -- SIAC-8551 Sofia - inizio 
        and not exists 
        (
          select 1
          from  siac_r_subdoc_prov_cassa  r ,siac_t_prov_cassa p 
          where r.subdoc_id=det1.subdoc_id 
          and   p.provc_id=r.provc_id 
          and   p.provc_anno::integer=(annoBilancio-1)
          and   p.data_cancellazione is null 
          and   p.validita_fine  is null 
          and   r.data_cancellazione is null 
          and   r.validita_fine is null 
        )
     	-- SIAC-8551 Sofia - fine        		    	   
        and   not exists (select 1 from siac_r_subdoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione)
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1
          				    from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                            where det1.subdoc_id = sub.subdoc_id
                            and   doc.doc_id = sub.doc_id
                            and   doc.doc_id = rst.doc_id
                            and   rst.data_cancellazione is null
                            and   rst.validita_fine is null
                            and   st.doc_stato_id = rst.doc_stato_id
                            and   st.doc_stato_code = 'A')
        ;
        raise notice 'dopo inserimento siac_r_subdoc_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_predoc_movgest_ts
	   if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_predoc_movgest_ts].';

        insert into siac_r_predoc_movgest_ts
        ( movgest_ts_id,
          predoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.predoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_predoc_movgest_ts r,siac_t_predoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.predoc_id=r.predoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_predoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_predoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        raise notice 'dopo inserimento siac_r_predoc_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       --- cancellazione relazioni del movimento precedente
	   -- siac_r_subdoc_movgest_ts
       /** spostato sotto
       if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_subdoc_movgest_ts].';
	        update siac_r_subdoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_subdoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	       end if;

       end if;

       -- siac_r_predoc_movgest_ts
       if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_predoc_movgest_ts].';
	        update siac_r_predoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_predoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	        end if;
       end if; **/

	   -- 03.05.2019 Sofia siac-6255
       -- siac_r_movgest_ts_programma
       if codResult is null then
	   	if faseOp=G_FASE then
          strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                        ' [siac_r_movgest_ts_programma].';

          insert into siac_r_movgest_ts_programma
          ( movgest_ts_id,
            programma_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             pnew.programma_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_programma r,siac_t_programma prog,
                 siac_t_programma pnew,siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   prog.programma_id=r.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.bil_id=bilancioId
            and   pnew.programma_code=prog.programma_code
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
            and   stato.programma_stato_code='VA'
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
           );
        end if;
       end if;

       -- pulizia dati inseriti
       -- aggiornamento fase_bil_t_gest_apertura_acc per scarto
	   if codResult=-1 then


        if movGestTsIdRet is not null then


         -- siac_r_movgest_class
	     strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_class.';
         delete from siac_r_movgest_class    where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_attr
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_attr.';
         delete from siac_r_movgest_ts_attr     where movgest_ts_id=movGestTsIdRet;
		 -- siac_r_movgest_ts_atto_amm
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_attr.';
         delete from siac_r_movgest_ts_atto_amm     where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_stato
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_stato.';
         delete from siac_r_movgest_ts_stato     where movgest_ts_id=movGestTsIdRet;
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_sog.';
         delete from siac_r_movgest_ts_sog      where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_sogclasse
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_sogclasse.';
         delete from siac_r_movgest_ts_sogclasse      where movgest_ts_id=movGestTsIdRet;
         -- siac_t_movgest_ts_det
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_t_movgest_ts_det.';
         delete from siac_t_movgest_ts_det      where movgest_ts_id=movGestTsIdRet;
/*
         -- siac_r_causale_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_causale_movgest_ts.';
         delete from siac_r_causale_movgest_ts where movgest_ts_id=movGestTsIdRet;*/

         -- siac_r_subdoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_subdoc_movgest_ts.';
         delete from siac_r_subdoc_movgest_ts where movgest_ts_id=movGestTsIdRet;
         -- siac_r_predoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_predoc_movgest_ts.';
         delete from siac_r_predoc_movgest_ts where movgest_ts_id=movGestTsIdRet;

 		 -- 03.05.2019 Sofia siac-6255
		 -- siac_r_movgest_ts_programma
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_programma.';
         delete from siac_r_movgest_ts_programma   where movgest_ts_id=movGestTsIdRet;

         -- siac_t_movgest_ts
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_t_movgest_ts.';
         delete from siac_t_movgest_ts         where movgest_ts_id=movGestTsIdRet;
        end if;

		if  movGestRec.movgest_ts_tipo=MOVGEST_TS_T_TIPO then
            -- siac_r_movgest_bil_elem
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';

            delete from siac_r_movgest_bil_elem where movgest_id=movGestIdRet;
        	-- siac_t_movgest
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';
            delete from siac_t_movgest          where movgest_id=movGestIdRet;

        end if;

        /*strMessaggio:=strMessaggioTemp||
                     ' Non Effettuato. Aggiornamento fase_bil_t_gest_apertura_acc per scarto.';*/
        strMessaggioTemp:=strMessaggio;
        strMessaggio:=strMessaggio||
                      'Aggiornamento fase_bil_t_gest_apertura_acc per scarto.';
      	update fase_bil_t_gest_apertura_acc fase
        set fl_elab='X',
            scarto_code='RES1',
            scarto_desc='Movimento accertamento/subaccertamento residuo non inserito.'||strMessaggioTemp
        where fase.fase_bil_gest_ape_acc_id=movGestRec.fase_bil_gest_ape_acc_id
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.fl_elab='N'
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null;

		continue;
       end if;


       --- cancellazione relazioni del movimento precedente
	   -- siac_r_subdoc_movgest_ts
       if codResult is null then
       	    -- 12.01.2017 Sofia sistemazione gestione quote per escludere quote incassate
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_subdoc_movgest_ts].';
	        update siac_r_subdoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=r.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
        	-- SIAC-8551 Sofia - inizio 
	        and not exists 
    	    (
        	  select 1
	          from  siac_r_subdoc_prov_cassa  r ,siac_t_prov_cassa p 
    	      where r.subdoc_id=r.subdoc_id 
        	  and   p.provc_id=r.provc_id 
	          and   p.provc_anno::integer=(annoBilancio-1)
    	      and   p.data_cancellazione is null 
        	  and   p.validita_fine  is null 
	          and   r.data_cancellazione is null 
    	      and   r.validita_fine is null 
        	)
     		-- SIAC-8551 Sofia - fine      	    	   
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null
			and   not exists (select 1
                              from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                              where r.subdoc_id = sub.subdoc_id
                              and   doc.doc_id = sub.doc_id
                              and   doc.doc_id = rst.doc_id
                              and   rst.data_cancellazione is null
                              and   rst.validita_fine is null
                              and   st.doc_stato_id = rst.doc_stato_id
                              and   st.doc_stato_code = 'A')
            ;

	        select 1 into codResult
    	    from siac_r_subdoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=r.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
        	-- SIAC-8551 Sofia - inizio 
    	    and not exists 
	        (
        	  select 1
	          from  siac_r_subdoc_prov_cassa  r ,siac_t_prov_cassa p 
    	      where r.subdoc_id=r.subdoc_id 
		      and   p.provc_id=r.provc_id 
        	  and   p.provc_anno::integer=(annoBilancio-1)
	          and   p.data_cancellazione is null 
    	      and   p.validita_fine  is null 
	          and   r.data_cancellazione is null 
    	      and   r.validita_fine is null 
	        )
        	-- SIAC-8551 Sofia - fine      	    	   
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null
            and   not exists (select 1
                              from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                              where r.subdoc_id = sub.subdoc_id
                              and   doc.doc_id = sub.doc_id
                              and   doc.doc_id = rst.doc_id
                              and   rst.data_cancellazione is null
                              and   rst.validita_fine is null
                              and   st.doc_stato_id = rst.doc_stato_id
                              and   st.doc_stato_code = 'A')
            ;

        	if codResult is not null then
--	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
                raise exception ' Errore in aggiornamento.';
	    	else codResult:=null;
	       end if;

       end if;

       -- siac_r_predoc_movgest_ts
       if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_predoc_movgest_ts].';
	        update siac_r_predoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_predoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
--	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
                raise exception ' Errore in aggiornamento.';
	    	else codResult:=null;
	        end if;
       end if;

	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Aggiornamento fase_bil_t_gest_apertura_acc per fine elaborazione.';
      	update fase_bil_t_gest_apertura_acc fase
        set fl_elab='I',
            movgest_id=movGestIdRet,
            movgest_ts_id=movGestTsIdRet
        where fase.fase_bil_gest_ape_acc_id=movGestRec.fase_bil_gest_ape_acc_id
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.fl_elab='N'
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null;


       codResult:=null;
	   insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

     end loop;



     strMessaggio:='Aggiornamento stato fase bilancio IN-2.';
     update fase_bil_t_elaborazione
     set fase_bil_elab_esito='IN-2',
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_ACC_RES||' IN CORSO IN-2.Elabora Acc.'
     where fase_bil_elab_id=faseBilElabId;


     codiceRisultato:=0;
     messaggioRisultato:=strMessaggioFinale||' FINE';
     return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,coalesce(strMessaggio,'');
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION siac.fnc_fasi_bil_gest_apertura_acc_elabora 
(
  integer,
  integer,
  integer,
  integer,
  integer,
  varchar,
  timestamp,
  out integer,
  out varchar)
OWNER TO siac;
