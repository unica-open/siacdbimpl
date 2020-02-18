/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_liq_elabora_imp(
  enteProprietarioId     integer,
  annoBilancio           integer,
  tipoElab               varchar,
  faseBilElabId          integer,
  minId                  integer,
  maxId                  integer,
  loginOperazione        varchar,
  dataElaborazione       timestamp,
  out codiceRisultato    integer,
  out messaggioRisultato varchar
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
    aggProgressivi    record;

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


	IMP_MOVGEST_TIPO CONSTANT varchar:='I';

	CAP_UG_TIPO      CONSTANT varchar:='CAP-UG';

    MOVGEST_TS_T_TIPO CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO CONSTANT varchar:='S';

    A_MOV_GEST_STATO  CONSTANT varchar:='A';
    APE_GEST_LIQ_RES  CONSTANT varchar:='APE_GEST_LIQ_RES';

    APE_GEST_IMP_RES  CONSTANT varchar:='APE_GEST_IMP_RES';

    A_MOV_GEST_DET_TIPO  CONSTANT varchar:='A';
    I_MOV_GEST_DET_TIPO  CONSTANT varchar:='I';

	-- 15.02.2017 Sofia SIAC-4425
	FRAZIONABILE_ATTR CONSTANT varchar:='flagFrazionabile';
    flagFrazAttrId integer:=null;

    -- 15.02.2017 Sofia HD-INC000001535447
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

    if tipoElab=APE_GEST_LIQ_RES then
 	 strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento movimenti  residui per ribaltamento liquidazioni res da Gestione precedente. Anno bilancio='||annoBilancio::varchar
                         ||'.Elabora  minId='||coalesce(minId::varchar,' ')||' maxId='||coalesce(maxId::varchar,' ')
                         ||'. Fase Elaborazione Id='||faseBilElabId||'.';
    else
     strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento movimenti  residui da Gestione precedente. Anno bilancio='||annoBilancio::varchar
                         ||'.Elabora  minId='||coalesce(minId::varchar,' ')||' maxId='||coalesce(maxId::varchar,' ')
                         ||'. Fase Elaborazione Id='||faseBilElabId||'.';
    end if;

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
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_liq_imp.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_liq_imp fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   fase.fl_elab='N';
    if codResult is null then
      raise exception ' Nessun impegno da creare.';
    end if;

    if coalesce(minId,0)=0 or coalesce(maxId,0)=0 then
        strMessaggio:='Calcolo min, max Id da elaborare in [fase_bil_t_gest_apertura_liq_imp].';
    	minId:=1;

        select max(fase.fase_bil_gest_ape_liq_imp_id) into maxId
        from fase_bil_t_gest_apertura_liq_imp fase
	    where fase.fase_bil_elab_id=faseBilElabId
    	and   fase.data_cancellazione is null
	    and   fase.validita_fine is null
        and   fase.fl_elab='N';
        if coalesce(maxId ,0)=0 then
        	raise exception ' Impossibile determinare il maxId';
        end if;

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

     -- per I
     strMessaggio:='Lettura id identificativo per tipoMovGestImp='||IMP_MOVGEST_TIPO||'.';
     select tipo.movgest_tipo_id into strict tipoMovGestId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=IMP_MOVGEST_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;


     -- 15.02.2017 Sofia HD-INC000001535447
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
     -- 15.02.2017 Sofia HD-INC000001535447

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

	 -- 15.02.2017 Sofia SIAC-4425
     strMessaggio:='Lettura identificativo per flagFrazAttrCode='||FRAZIONABILE_ATTR||'.';
   	 select attr.attr_id into strict flagFrazAttrId
     from siac_t_attr attr
     where attr.ente_proprietario_id=enteProprietarioId
     and   attr.attr_code=FRAZIONABILE_ATTR
     and   attr.data_cancellazione is null
     and   attr.validita_fine is null;


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


     strMessaggio:='Inizio ciclo per generazione impegni.';
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
     (select  fase.fase_bil_gest_ape_liq_imp_id,
	   		  fase.movgest_ts_tipo,
		      fase.movgest_orig_id,
	          fase.movgest_orig_ts_id,
		      fase.elem_orig_id,
              fase.elem_id,
	          fase.imp_importo
      from  fase_bil_t_gest_apertura_liq_imp fase
      where fase.fase_bil_elab_id=faseBilElabId
      and   fase.fase_bil_gest_ape_liq_imp_id between minId and maxId
      and   fase.fl_elab='N'
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
/*      and   exists -- x test siac-6255
      (
      select 1
      from siac_r_movgest_ts_programma r
      where r.movgest_ts_id=fase.movgest_orig_ts_id
      and   r.data_cancellazione is null
      and   r.validita_fine is null
      ) */
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
      	  strMessaggio:=strMessaggio||'Inserimento Impegno [siac_t_movgest].';

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
	       parere_finanziario_login_operazione
		   )
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
                       ' elem_id='||movGestRec.elem_id||'.Lettura identificativo impegno.';

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

        raise notice 'dopo lettura siac_t_movgest T per inserimento subimpegno movGestIdRet=%',movGestIdRet;

        if codResult is null then

         	 strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.Lettura identificativo siac_t_movgest_ts movgGestTsIdPadre.';
			strMessaggioTemp:=strMessaggio;
        	select ts.movgest_ts_id into movgGestTsIdPadre
	        from siac_t_movgest_ts ts
    	    where ts.movgest_id=movGestIdRet
	        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
    	    and   ts.data_cancellazione is null
        	and   ts.validita_fine is null;

			raise notice 'dopo lettura siac_t_movgest_ts T per inserimento subimpegno movgGestTsIdPadre=%',movgGestTsIdPadre;

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
		  siope_tipo_debito_id ,
  		  siope_assenza_motivazione_id
        )
        ( select
          ts.movgest_ts_code,
          ts.movgest_ts_desc,
          movGestIdRet,    -- inserito se I, per SUB ricavato
          ts.movgest_ts_tipo_id,
          movgGestTsIdPadre, -- da ricavare dal TS T di impegno padre
          ts.movgest_ts_scadenza_data,
          ts.ordine,
          ts.livello,
--          dataEmissione,
          ts.validita_inizio, -- i residui devono mantenere la loro data di emissione originale
          enteProprietarioId,
          loginOperazione,
          loginOperazione,
		  ts.siope_tipo_debito_id ,
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
          and    tipo.movgest_ts_det_tipo_code in (A_MOV_GEST_DET_TIPO,I_MOV_GEST_DET_TIPO)
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
         -- and   atto.data_cancellazione is null 15.02.2017 Sofia HD-INC000001535447
         -- and   atto.validita_fine is null
         );

       /* select 1 into codResult
        from siac_r_movgest_ts_atto_amm det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

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

       -- raise notice 'dopo inserimento siac_r_movgest_ts_atto_amm movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        -- 15.02.2017 Sofia HD-INC000001535447 inserimento relazione con atto amministrativo fittizio
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
--            and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
            and   stato.programma_stato_code!='AN'			-- 06.08.2019 Sofia SIAC-6934
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
           );

		   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                         ' solo cronop [siac_r_movgest_ts_cronop_elem].';

          insert into siac_r_movgest_ts_cronop_elem
          ( movgest_ts_id,
            cronop_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             cnew.cronop_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_cronop_elem r,
                 siac_t_cronop cronop,
                 siac_t_programma prog,
                 siac_t_programma pnew,siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato,
                 siac_t_cronop cnew, siac_r_cronop_stato rsc, siac_d_cronop_stato cstato
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   r.cronop_elem_id is null
            and   cronop.cronop_id=r.cronop_id
            and   prog.programma_id=cronop.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.programma_code=prog.programma_code
            and   cnew.programma_id=pnew.programma_id
            and   cnew.bil_id=bilancioId
			and   cnew.cronop_code=cronop.cronop_code
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
            --and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
            and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   rsc.cronop_id=cnew.cronop_id
            and   cstato.cronop_stato_id=rsc.cronop_stato_id
            --and   cstato.cronop_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
	        and   cstato.cronop_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   cronop.data_cancellazione is null
            and   cronop.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   cnew.data_cancellazione is null
            and   cnew.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   rsc.data_cancellazione is null
            and   rsc.validita_fine is null
           );

           strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                         ' dettaglio cronop [siac_r_movgest_ts_cronop_elem].';

          insert into siac_r_movgest_ts_cronop_elem
          ( movgest_ts_id,
            cronop_id,
            cronop_elem_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             celem_new.cronop_id,
             celem_new.cronop_elem_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_cronop_elem r,siac_t_cronop_elem celem,
		         siac_t_cronop_elem_det det,
                 siac_t_cronop cronop,
                 siac_t_programma prog,
                 siac_t_programma pnew,siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato,
                 siac_t_cronop cnew, siac_r_cronop_stato rsc, siac_d_cronop_stato cstato,
                 siac_t_cronop_elem celem_new,siac_t_cronop_elem_det det_new
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   r.cronop_elem_id is not null
            and   celem.cronop_elem_id=r.cronop_elem_id
            and   det.cronop_elem_id=celem.cronop_elem_id
            and   cronop.cronop_id=celem.cronop_id
            and   prog.programma_id=cronop.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.programma_code=prog.programma_code
            and   cnew.programma_id=pnew.programma_id
            and   celem_new.cronop_id=cnew.cronop_id
            and   det_new.cronop_elem_id=celem_new.cronop_elem_id
            and   cnew.bil_id=bilancioId
			and   cnew.cronop_code=cronop.cronop_code
            and   coalesce(celem_new.cronop_elem_code,'')=coalesce(celem.cronop_elem_code,'')
            and   coalesce(celem_new.cronop_elem_code2,'')=coalesce(celem.cronop_elem_code2,'')
            and   coalesce(celem_new.cronop_elem_code3,'')=coalesce(celem.cronop_elem_code3,'')
            and   coalesce(celem_new.elem_tipo_id,0)=coalesce(celem.elem_tipo_id,0)
            and   coalesce(celem_new.cronop_elem_desc,'')=coalesce(celem.cronop_elem_desc,'')
            and   coalesce(celem_new.cronop_elem_desc2,'')=coalesce(celem.cronop_elem_desc2,'')
            and   coalesce(det_new.periodo_id,0)=coalesce(det.periodo_id,0)
		    and   coalesce(det_new.cronop_elem_det_importo,0)=coalesce(det.cronop_elem_det_importo,0)
            and   coalesce(det_new.cronop_elem_det_desc,'')=coalesce(det.cronop_elem_det_desc,'')
	        and   coalesce(det_new.anno_entrata,'')=coalesce(det.anno_entrata,'')
	        and   coalesce(det_new.elem_det_tipo_id,0)=coalesce(det.elem_det_tipo_id,0)
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
            --and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
		    and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   rsc.cronop_id=cnew.cronop_id
            and   cstato.cronop_stato_id=rsc.cronop_stato_id
            --and   cstato.cronop_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
		    and   cstato.cronop_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   exists
            (
              select 1
              from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
              where rc.cronop_elem_id=celem.cronop_elem_id
              and   c.classif_id=rc.classif_id
              and   tipo.classif_tipo_id=c.classif_tipo_id
              and   exists
              (
                select 1
                from siac_r_cronop_elem_class rc1, siac_t_class c1
                where rc1.cronop_elem_id=celem_new.cronop_elem_id
                and   c1.classif_id=rc1.classif_id
                and   c1.classif_tipo_id=tipo.classif_tipo_id
                and   c1.classif_code=c.classif_code
                and   rc1.data_cancellazione is null
                and   rc1.validita_fine is null
              )
              and   rc.data_cancellazione is null
              and   rc.validita_fine is null
            )
            and  not exists
            (
              select 1
              from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
              where rc.cronop_elem_id=celem.cronop_elem_id
              and   c.classif_id=rc.classif_id
              and   tipo.classif_tipo_id=c.classif_tipo_id
              and   not exists
              (
                select 1
                from siac_r_cronop_elem_class rc1, siac_t_class c1
                where rc1.cronop_elem_id=celem_new.cronop_elem_id
                and   c1.classif_id=rc1.classif_id
                and   c1.classif_tipo_id=tipo.classif_tipo_id
                and   c1.classif_code=c.classif_code
                and   rc1.data_cancellazione is null
                and   rc1.validita_fine is null
              )
              and   rc.data_cancellazione is null
              and   rc.validita_fine is null
            )
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   cronop.data_cancellazione is null
            and   cronop.validita_fine is null
            and   celem.data_cancellazione is null
            and   celem.validita_fine is null
            and   det.data_cancellazione is null
            and   det.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   cnew.data_cancellazione is null
            and   cnew.validita_fine is null
            and   celem_new.data_cancellazione is null
            and   celem_new.validita_fine is null
            and   det_new.data_cancellazione is null
            and   det_new.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   rsc.data_cancellazione is null
            and   rsc.validita_fine is null
           );
        end if;
       end if;


       /*if codResult is null then
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
           r.programma_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_programma r,siac_t_programma prog
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   prog.programma_id=r.programma_id
          and   prog.data_cancellazione is null
          and   prog.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );


		select 1  into codResult
        from siac_r_movgest_ts_programma det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_programma det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_movgest_ts_programma movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/

       -- siac_r_mutuo_voce_movgest
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_mutuo_voce_movgest].';

        insert into siac_r_mutuo_voce_movgest
        ( movgest_ts_id,
          mut_voce_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.mut_voce_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_mutuo_voce_movgest r,siac_t_mutuo_voce voce
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   voce.mut_voce_id=r.mut_voce_id
          and   voce.data_cancellazione is null
          and   voce.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );


		select 1  into codResult
        from siac_r_mutuo_voce_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_mutuo_voce_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_mutuo_voce_movgest movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- inserire il resto dei record legati al TS
       -- verificare quali sono da ribaltare e verificare se usare

       -- siac_r_giustificativo_movgest
       /* cassa-economale da non ribaltare come da indicazioni di Irene
        if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_giustificativo_movgest].';

        insert into siac_r_giustificativo_movgest
        ( movgest_ts_id,
          gst_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.gst_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_giustificativo_movgest r,siac_t_giustificativo gst
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   gst.gst_id=r.gst_id
          and   gst.data_cancellazione is null
          and   gst.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );


		select 1  into codResult
        from siac_r_giustificativo_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_giustificativo_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_giustificativo_movgest movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/


       -- siac_r_cartacont_det_movgest_ts
       /* Non si ribalta in seguito ad indicazioni di Annalina
        if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_cartacont_det_movgest_ts].';

        insert into siac_r_cartacont_det_movgest_ts
        ( movgest_ts_id,
          cartac_det_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.cartac_det_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_cartacont_det_movgest_ts r,siac_t_cartacont_det carta
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   carta.cartac_det_id=r.cartac_det_id
          and   carta.data_cancellazione is null
          and   carta.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );


		select 1  into codResult
        from siac_r_cartacont_det_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_cartacont_det_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_cartacont_det_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; **/

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

       -- siac_r_fondo_econ_movgest
       /* cassa-economale da non ribaltare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_causale_movgest_ts].';

        insert into siac_r_fondo_econ_movgest
        ( movgest_ts_id,
          fondoecon_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.fondoecon_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_fondo_econ_movgest r,siac_t_fondo_econ econ
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   econ.fondoecon_id=r.fondoecon_id
          and   econ.data_cancellazione is null
          and   econ.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_fondo_econ_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_fondo_econ_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_fondo_econ_movgest movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/

       -- siac_r_richiesta_econ_movgest
       /* cassa-economale da non ribaltare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_richiesta_econ_movgest].';

        insert into siac_r_richiesta_econ_movgest
        ( movgest_ts_id,
          ricecon_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.ricecon_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_richiesta_econ_movgest r,siac_t_richiesta_econ econ
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   econ.ricecon_id=r.ricecon_id
          and   econ.data_cancellazione is null
          and   econ.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_richiesta_econ_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_richiesta_econ_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_richiesta_econ_movgest movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/

       -- siac_r_subdoc_movgest_ts
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_subdoc_movgest_ts].';
        -- 12.01.2017 Sofia correzione per esclusione quote pagate
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
                            and   st.doc_stato_code = 'A');

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
        and   not exists (select 1 from siac_r_predoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione)
		and   det1.data_cancellazione is null
        and   det1.validita_fine is null;

        raise notice 'dopo inserimento siac_r_predoc_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       --- cancellazione relazioni del movimento precedente
	   -- siac_r_subdoc_movgest_ts
      /*   spostato sotto dopo pulizia in caso di codResult null
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
       end if; */

       -- siac_r_cartacont_det_movgest_ts
       /* non si gestisce in seguito ad indicazioni di Annalina
       if codResult is null then
    	 	strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
	                      ' movgest_orig_id='||movGestRec.movgest_orig_id||
                          ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                          ' elem_orig_id='||movGestRec.elem_orig_id||
                          ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_cartacont_det_movgest_ts].';
	        update siac_r_cartacont_det_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_cartacont_det_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	       end if;
       end if; */


	   -- 17.06.2019 Sofia SIAC-6702 - inizio
	   if codResult is null then
       	strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                        ' [siac_r_movgest_ts_storico_imp_acc].';

        insert into siac_r_movgest_ts_storico_imp_acc
        ( movgest_ts_id,
          movgest_anno_acc,
          movgest_numero_acc,
          movgest_subnumero_acc,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_anno_acc,
           r.movgest_numero_acc,
           r.movgest_subnumero_acc,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_storico_imp_acc r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
        );


        select 1  into codResult
        from siac_r_movgest_ts_storico_imp_acc det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_storico_imp_acc det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_movgest_ts_storico_imp_acc movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;
       -- 17.06.2019 Sofia SIAC-6702 - fine

       -- pulizia dati inseriti
       -- aggiornamento fase_bil_t_gest_apertura_liq_imp per scarto
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
         -- siac_r_movgest_ts_programma
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_programma.';
         delete from siac_r_movgest_ts_programma where movgest_ts_id=movGestTsIdRet;
         -- siac_r_mutuo_voce_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_mutuo_voce_movgest.';
         delete from siac_r_mutuo_voce_movgest where movgest_ts_id=movGestTsIdRet;
         -- siac_r_giustificativo_movgest
/*         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_giustificativo_movgest.';
         delete from siac_r_giustificativo_movgest where movgest_ts_id=movGestTsIdRet;
         -- siac_r_cartacont_det_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_cartacont_det_movgest_ts.';
         delete from siac_r_cartacont_det_movgest_ts where movgest_ts_id=movGestTsIdRet;
         -- siac_r_causale_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_causale_movgest_ts.';
         delete from siac_r_causale_movgest_ts where movgest_ts_id=movGestTsIdRet;

		 -- siac_r_fondo_econ_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_fondo_econ_movgest.';
         delete from siac_r_fondo_econ_movgest where movgest_ts_id=movGestTsIdRet;
	     -- siac_r_richiesta_econ_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_richiesta_econ_movgest.';
         delete from siac_r_richiesta_econ_movgest where movgest_ts_id=movGestTsIdRet; */
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
         -- siac_r_movgest_ts_cronop_elem
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_cronop_elem.';
         delete from siac_r_movgest_ts_cronop_elem where movgest_ts_id=movGestTsIdRet;

	     -- 17.06.2019 Sofia siac-6702
         -- siac_r_movgest_ts_storico_imp_acc
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_storico_imp_acc.';
         delete from siac_r_movgest_ts_storico_imp_acc  where movgest_ts_id=movGestTsIdRet;


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




/*        strMessaggio:=strMessaggioTemp||
                     ' Non Effettuato. Aggiornamento fase_bil_t_gest_apertura_liq_imp per scarto.';*/
        strMessaggioTemp:=strMessaggio;
        strMessaggio:=strMessaggio||
                      'Aggiornamento fase_bil_t_gest_apertura_liq_imp per scarto.';

      	update fase_bil_t_gest_apertura_liq_imp fase
        set fl_elab='X',
            scarto_code='RES1',
            scarto_desc='Movimento impegno/subimpegno residuo non inserito.'||strMessaggioTemp
        where fase.fase_bil_gest_ape_liq_imp_id=movGestRec.fase_bil_gest_ape_liq_imp_id
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.fl_elab='N'
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null;

		continue;
       end if;

       --- cancellazione relazioni del movimento precedente
	   -- siac_r_subdoc_movgest_ts
       if codResult is null then
            --- 12.01.2017 Sofia - sistemazione update per escludere le quote pagate
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
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null
            and   not exists (select 1
                              from siac_t_subdoc sub,siac_t_doc  doc, siac_r_doc_stato rst, siac_d_doc_stato st
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
	    	    --strMessaggioTemp:=strMessaggio;
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
                       ' elem_id='||movGestRec.elem_id||'. Aggiornamento fase_bil_t_gest_apertura_liq_imp per fine elaborazione.';
      	update fase_bil_t_gest_apertura_liq_imp fase
        set fl_elab='I',
            movgest_id=movGestIdRet,
            movgest_ts_id=movGestTsIdRet
        where fase.fase_bil_gest_ape_liq_imp_id=movGestRec.fase_bil_gest_ape_liq_imp_id
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


	 -- 15.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile
     -- insert N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
     -- essendo residui consideriamo solo mov.movgest_anno::integer<annoBilancio
     -- che non hanno ancora attributo
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore N per impegni residui.';
     INSERT INTO siac_r_movgest_ts_attr
	 (
	  movgest_ts_id,
	  attr_id,
	  boolean,
	  validita_inizio,
	  ente_proprietario_id,
	  login_operazione
	 )
	 select ts.movgest_ts_id,
	        flagFrazAttrId,
            'N',
		    dataInizioVal,
		    ts.ente_proprietario_id,
		    loginOperazione
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio)
     and   mov.movgest_anno::integer<annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   not exists (select 1 from siac_r_movgest_ts_attr r1
       		           where r1.movgest_ts_id=ts.movgest_ts_id
                       and   r1.attr_id=flagFrazAttrId
                       and   r1.data_cancellazione is null
                       and   r1.validita_fine is null);

     -- insert S per impegni mov.movgest_anno::integer=annoBilancio
     -- che non hanno ancora attributo
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore S per impegni di competenza senza atto amministrativo antecedente.';
	 INSERT INTO siac_r_movgest_ts_attr
	 (
	  movgest_ts_id,
	  attr_id,
	  boolean,
	  validita_inizio,
	  ente_proprietario_id,
	  login_operazione
	 )
	 select ts.movgest_ts_id,
	        flagFrazAttrId,
            'S',
	        dataInizioVal,
	        ts.ente_proprietario_id,
	        loginOperazione
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where mov.bil_id=bilancioId
	 and   mov.movgest_anno::integer=annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   not exists (select 1 from siac_r_movgest_ts_attr r1
       		           where r1.movgest_ts_id=ts.movgest_ts_id
                       and   r1.attr_id=flagFrazAttrId
                       and   r1.data_cancellazione is null
                       and   r1.validita_fine is null)
     and  not exists (select 1 from siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
					  where ra.movgest_ts_id=ts.movgest_ts_id
					  and   atto.attoamm_id=ra.attoamm_id
				 	  and   atto.attoamm_anno::integer < annoBilancio
		     		  and   ra.data_cancellazione is null
				      and   ra.validita_fine is null);

     -- aggiornamento N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
     -- essendo residui consideriamo solo mov.movgest_anno::integer<annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni residui.';
	 update  siac_r_movgest_ts_attr r set boolean='N'
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where  mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<2017 or mov.movgest_anno::integer>2017)
	 and   mov.movgest_anno::integer<annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   r.movgest_ts_id=ts.movgest_ts_id
     and   r.attr_id=flagFrazAttrId
	 and   r.boolean='S'
     and   r.data_cancellazione is null
     and   r.validita_fine is null;

     -- aggiornamento N per impegni mov.movgest_anno::integer=annoBilancio e atto.attoamm_anno::integer < annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni di competenza e atti amministrativi antecedenti.';
     update siac_r_movgest_ts_attr r set boolean='N'
  	 from siac_t_movgest mov, siac_t_movgest_ts ts,
	      siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
  	 where mov.bil_id=bilancioId
	 and   mov.movgest_anno::INTEGER=2017
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   r.movgest_ts_id=ts.movgest_ts_id
     and   r.attr_id=flagFrazAttrId
	 and   ra.movgest_ts_id=ts.movgest_ts_id
	 and   atto.attoamm_id=ra.attoamm_id
	 and   atto.attoamm_anno::integer < annoBilancio
	 and   r.boolean='S'
     and   r.data_cancellazione is null
     and   r.validita_fine is null
     and   ra.data_cancellazione is null
     and   ra.validita_fine is null;
    -- 15.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile

    strMessaggio:='Aggiornamento stato fase bilancio IN-2.';
    update fase_bil_t_elaborazione
    set fase_bil_elab_esito='IN-2',
        fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||tipoElab||' IN CORSO IN-2.Elabora Imp.'
    where fase_bil_elab_id=faseBilElabId;


    codiceRisultato:=0;
    messaggioRisultato:=strMessaggioFinale||' FINE';
    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500);
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
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100; _ f i n e   i s   n u l l 
 
                       ) ; 
 
                 e n d   i f ; 
 
               e n d   i f ; 
 
 
 
 
 
               / * i f   c o d R e s u l t   i s   n u l l   t h e n 
 
       	         s t r M e s s a g g i o : = ' M o v i m e n t o   m o v G e s t T s T i p o = ' | | m o v G e s t R e c . m o v g e s t _ t s _ t i p o | | 
 
                                               '   m o v g e s t _ o r i g _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ i d | | 
 
                                               '   m o v g e s t _ o r i g _ t s _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d | | 
 
                                               '   e l e m _ o r i g _ i d = ' | | m o v G e s t R e c . e l e m _ o r i g _ i d | | 
 
                                               '   e l e m _ i d = ' | | m o v G e s t R e c . e l e m _ i d | | 
 
                                             '   [ s i a c _ r _ m o v g e s t _ t s _ p r o g r a m m a ] . ' ; 
 
 
 
                 i n s e r t   i n t o   s i a c _ r _ m o v g e s t _ t s _ p r o g r a m m a 
 
                 (   m o v g e s t _ t s _ i d , 
 
                     p r o g r a m m a _ i d , 
 
 	             v a l i d i t a _ i n i z i o , 
 
 	             e n t e _ p r o p r i e t a r i o _ i d , 
 
                     l o g i n _ o p e r a z i o n e 
 
                 ) 
 
                 (   s e l e c t 
 
                       m o v G e s t T s I d R e t , 
 
                       r . p r o g r a m m a _ i d , 
 
                       d a t a I n i z i o V a l , 
 
                       e n t e P r o p r i e t a r i o I d , 
 
                       l o g i n O p e r a z i o n e 
 
                     f r o m   s i a c _ r _ m o v g e s t _ t s _ p r o g r a m m a   r , s i a c _ t _ p r o g r a m m a   p r o g 
 
                     w h e r e   r . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
                     a n d       p r o g . p r o g r a m m a _ i d = r . p r o g r a m m a _ i d 
 
                     a n d       p r o g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       p r o g . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
                   ) ; 
 
 
 
 
 
 	 	 s e l e c t   1     i n t o   c o d R e s u l t 
 
                 f r o m   s i a c _ r _ m o v g e s t _ t s _ p r o g r a m m a   d e t 1 
 
                 w h e r e   d e t 1 . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
                 a n d       d e t 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       d e t 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
                 a n d       n o t   e x i s t s   ( s e l e c t   1   f r o m   s i a c _ r _ m o v g e s t _ t s _ p r o g r a m m a   d e t 
 
 	 	 	 	                     w h e r e   d e t . m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t 
 
 	 	 	 	 	                 a n d       d e t . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 	 	 	                 a n d       d e t . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	 	 	 	                 a n d       d e t . l o g i n _ o p e r a z i o n e = l o g i n O p e r a z i o n e ) ; 
 
                 r a i s e   n o t i c e   ' d o p o   i n s e r i m e n t o   s i a c _ r _ m o v g e s t _ t s _ p r o g r a m m a   m o v G e s t T s I d R e t = %   c o d R e s u l t = % ' ,   m o v G e s t T s I d R e t , c o d R e s u l t ; 
 
 
 
                 i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
               	   c o d R e s u l t : = - 1 ; 
 
                   s t r M e s s a g g i o T e m p : = s t r M e s s a g g i o ; 
 
                 e l s e   c o d R e s u l t : = n u l l ; 
 
                 e n d   i f ; 
 
               e n d   i f ; * / 
 
 
 
               - -   s i a c _ r _ m u t u o _ v o c e _ m o v g e s t 
 
               i f   c o d R e s u l t   i s   n u l l   t h e n 
 
       	         s t r M e s s a g g i o : = ' M o v i m e n t o   m o v G e s t T s T i p o = ' | | m o v G e s t R e c . m o v g e s t _ t s _ t i p o | | 
 
                                               '   m o v g e s t _ o r i g _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ i d | | 
 
                                               '   m o v g e s t _ o r i g _ t s _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d | | 
 
                                               '   e l e m _ o r i g _ i d = ' | | m o v G e s t R e c . e l e m _ o r i g _ i d | | 
 
                                               '   e l e m _ i d = ' | | m o v G e s t R e c . e l e m _ i d | | 
 
                                             '   [ s i a c _ r _ m u t u o _ v o c e _ m o v g e s t ] . ' ; 
 
 
 
                 i n s e r t   i n t o   s i a c _ r _ m u t u o _ v o c e _ m o v g e s t 
 
                 (   m o v g e s t _ t s _ i d , 
 
                     m u t _ v o c e _ i d , 
 
 	             v a l i d i t a _ i n i z i o , 
 
 	             e n t e _ p r o p r i e t a r i o _ i d , 
 
                     l o g i n _ o p e r a z i o n e 
 
                 ) 
 
                 (   s e l e c t 
 
                       m o v G e s t T s I d R e t , 
 
                       r . m u t _ v o c e _ i d , 
 
                       d a t a I n i z i o V a l , 
 
                       e n t e P r o p r i e t a r i o I d , 
 
                       l o g i n O p e r a z i o n e 
 
                     f r o m   s i a c _ r _ m u t u o _ v o c e _ m o v g e s t   r , s i a c _ t _ m u t u o _ v o c e   v o c e 
 
                     w h e r e   r . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
                     a n d       v o c e . m u t _ v o c e _ i d = r . m u t _ v o c e _ i d 
 
                     a n d       v o c e . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       v o c e . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
                   ) ; 
 
 
 
 
 
 	 	 s e l e c t   1     i n t o   c o d R e s u l t 
 
                 f r o m   s i a c _ r _ m u t u o _ v o c e _ m o v g e s t   d e t 1 
 
                 w h e r e   d e t 1 . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
                 a n d       d e t 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       d e t 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
                 a n d       n o t   e x i s t s   ( s e l e c t   1   f r o m   s i a c _ r _ m u t u o _ v o c e _ m o v g e s t   d e t 
 
 	 	 	 	                     w h e r e   d e t . m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t 
 
 	 	 	 	 	                 a n d       d e t . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 	 	 	                 a n d       d e t . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	 	 	 	                 a n d       d e t . l o g i n _ o p e r a z i o n e = l o g i n O p e r a z i o n e ) ; 
 
                 r a i s e   n o t i c e   ' d o p o   i n s e r i m e n t o   s i a c _ r _ m u t u o _ v o c e _ m o v g e s t   m o v G e s t T s I d R e t = %   c o d R e s u l t = % ' ,   m o v G e s t T s I d R e t , c o d R e s u l t ; 
 
 
 
                 i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
               	   c o d R e s u l t : = - 1 ; 
 
                   s t r M e s s a g g i o T e m p : = s t r M e s s a g g i o ; 
 
                 e l s e   c o d R e s u l t : = n u l l ; 
 
                 e n d   i f ; 
 
               e n d   i f ; 
 
 
 
               - -   i n s e r i r e   i l   r e s t o   d e i   r e c o r d   l e g a t i   a l   T S 
 
               - -   v e r i f i c a r e   q u a l i   s o n o   d a   r i b a l t a r e   e   v e r i f i c a r e   s e   u s a r e 
 
 
 
               - -   s i a c _ r _ g i u s t i f i c a t i v o _ m o v g e s t 
 
               / *   c a s s a - e c o n o m a l e   d a   n o n   r i b a l t a r e   c o m e   d a   i n d i c a z i o n i   d i   I r e n e 
 
                 i f   c o d R e s u l t   i s   n u l l   t h e n 
 
       	         s t r M e s s a g g i o : = ' M o v i m e n t o   m o v G e s t T s T i p o = ' | | m o v G e s t R e c . m o v g e s t _ t s _ t i p o | | 
 
                                               '   m o v g e s t _ o r i g _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ i d | | 
 
                                               '   m o v g e s t _ o r i g _ t s _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d | | 
 
                                               '   e l e m _ o r i g _ i d = ' | | m o v G e s t R e c . e l e m _ o r i g _ i d | | 
 
                                               '   e l e m _ i d = ' | | m o v G e s t R e c . e l e m _ i d | | 
 
                                             '   [ s i a c _ r _ g i u s t i f i c a t i v o _ m o v g e s t ] . ' ; 
 
 
 
                 i n s e r t   i n t o   s i a c _ r _ g i u s t i f i c a t i v o _ m o v g e s t 
 
                 (   m o v g e s t _ t s _ i d , 
 
                     g s t _ i d , 
 
 	             v a l i d i t a _ i n i z i o , 
 
 	             e n t e _ p r o p r i e t a r i o _ i d , 
 
                     l o g i n _ o p e r a z i o n e 
 
                 ) 
 
                 (   s e l e c t 
 
                       m o v G e s t T s I d R e t , 
 
                       r . g s t _ i d , 
 
                       d a t a I n i z i o V a l , 
 
                       e n t e P r o p r i e t a r i o I d , 
 
                       l o g i n O p e r a z i o n e 
 
                     f r o m   s i a c _ r _ g i u s t i f i c a t i v o _ m o v g e s t   r , s i a c _ t _ g i u s t i f i c a t i v o   g s t 
 
                     w h e r e   r . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
                     a n d       g s t . g s t _ i d = r . g s t _ i d 
 
                     a n d       g s t . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       g s t . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
                   ) ; 
 
 
 
 
 
 	 	 s e l e c t   1     i n t o   c o d R e s u l t 
 
                 f r o m   s i a c _ r _ g i u s t i f i c a t i v o _ m o v g e s t   d e t 1 
 
                 w h e r e   d e t 1 . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
                 a n d       d e t 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       d e t 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
                 a n d       n o t   e x i s t s   ( s e l e c t   1   f r o m   s i a c _ r _ g i u s t i f i c a t i v o _ m o v g e s t   d e t 
 
 	 	 	 	                     w h e r e   d e t . m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t 
 
 	 	 	 	 	                 a n d       d e t . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 	 	 	                 a n d       d e t . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	 	 	 	                 a n d       d e t . l o g i n _ o p e r a z i o n e = l o g i n O p e r a z i o n e ) ; 
 
                 r a i s e   n o t i c e   ' d o p o   i n s e r i m e n t o   s i a c _ r _ g i u s t i f i c a t i v o _ m o v g e s t   m o v G e s t T s I d R e t = %   c o d R e s u l t = % ' ,   m o v G e s t T s I d R e t , c o d R e s u l t ; 
 
 
 
                 i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
               	   c o d R e s u l t : = - 1 ; 
 
                   s t r M e s s a g g i o T e m p : = s t r M e s s a g g i o ; 
 
                 e l s e   c o d R e s u l t : = n u l l ; 
 
                 e n d   i f ; 
 
               e n d   i f ; * / 
 
 
 
 
 
               - -   s i a c _ r _ c a r t a c o n t _ d e t _ m o v g e s t _ t s 
 
               / *   N o n   s i   r i b a l t a   i n   s e g u i t o   a d   i n d i c a z i o n i   d i   A n n a l i n a 
 
                 i f   c o d R e s u l t   i s   n u l l   t h e n 
 
       	         s t r M e s s a g g i o : = ' M o v i m e n t o   m o v G e s t T s T i p o = ' | | m o v G e s t R e c . m o v g e s t _ t s _ t i p o | | 
 
                                               '   m o v g e s t _ o r i g _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ i d | | 
 
                                               '   m o v g e s t _ o r i g _ t s _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d | | 
 
                                               '   e l e m _ o r i g _ i d = ' | | m o v G e s t R e c . e l e m _ o r i g _ i d | | 
 
                                               '   e l e m _ i d = ' | | m o v G e s t R e c . e l e m _ i d | | 
 
                                             '   [ s i a c _ r _ c a r t a c o n t _ d e t _ m o v g e s t _ t s ] . ' ; 
 
 
 
                 i n s e r t   i n t o   s i a c _ r _ c a r t a c o n t _ d e t _ m o v g e s t _ t s 
 
                 (   m o v g e s t _ t s _ i d , 
 
                     c a r t a c _ d e t _ i d , 
 
 	             v a l i d i t a _ i n i z i o , 
 
 	             e n t e _ p r o p r i e t a r i o _ i d , 
 
                     l o g i n _ o p e r a z i o n e 
 
                 ) 
 
                 (   s e l e c t 
 
                       m o v G e s t T s I d R e t , 
 
                       r . c a r t a c _ d e t _ i d , 
 
                       d a t a I n i z i o V a l , 
 
                       e n t e P r o p r i e t a r i o I d , 
 
                       l o g i n O p e r a z i o n e 
 
                     f r o m   s i a c _ r _ c a r t a c o n t _ d e t _ m o v g e s t _ t s   r , s i a c _ t _ c a r t a c o n t _ d e t   c a r t a 
 
                     w h e r e   r . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
                     a n d       c a r t a . c a r t a c _ d e t _ i d = r . c a r t a c _ d e t _ i d 
 
                     a n d       c a r t a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       c a r t a . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
                   ) ; 
 
 
 
 
 
 	 	 s e l e c t   1     i n t o   c o d R e s u l t 
 
                 f r o m   s i a c _ r _ c a r t a c o n t _ d e t _ m o v g e s t _ t s   d e t 1 
 
                 w h e r e   d e t 1 . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
                 a n d       d e t 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       d e t 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
                 a n d       n o t   e x i s t s   ( s e l e c t   1   f r o m   s i a c _ r _ c a r t a c o n t _ d e t _ m o v g e s t _ t s   d e t 
 
 	 	 	 	                     w h e r e   d e t . m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t 
 
 	 	 	 	 	                 a n d       d e t . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 	 	 	                 a n d       d e t . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	 	 	 	                 a n d       d e t . l o g i n _ o p e r a z i o n e = l o g i n O p e r a z i o n e ) ; 
 
                 r a i s e   n o t i c e   ' d o p o   i n s e r i m e n t o   s i a c _ r _ c a r t a c o n t _ d e t _ m o v g e s t _ t s   m o v G e s t T s I d R e t = %   c o d R e s u l t = % ' ,   m o v G e s t T s I d R e t , c o d R e s u l t ; 
 
 
 
                 i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
               	   c o d R e s u l t : = - 1 ; 
 
                   s t r M e s s a g g i o T e m p : = s t r M e s s a g g i o ; 
 
                 e l s e   c o d R e s u l t : = n u l l ; 
 
                 e n d   i f ; 
 
               e n d   i f ;   * * / 
 
 
 
               - -   s i a c _ r _ c a u s a l e _ m o v g e s t _ t s 
 
               / *   n o n   s i   g e s t i s c e   i n   s e g u i t o   a d   i n d i c a z i o n i   d i   A n n a l i n a 
 
               i f   c o d R e s u l t   i s   n u l l   t h e n 
 
       	         s t r M e s s a g g i o : = ' M o v i m e n t o   m o v G e s t T s T i p o = ' | | m o v G e s t R e c . m o v g e s t _ t s _ t i p o | | 
 
                                               '   m o v g e s t _ o r i g _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ i d | | 
 
                                               '   m o v g e s t _ o r i g _ t s _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d | | 
 
                                               '   e l e m _ o r i g _ i d = ' | | m o v G e s t R e c . e l e m _ o r i g _ i d | | 
 
                                               '   e l e m _ i d = ' | | m o v G e s t R e c . e l e m _ i d | | 
 
                                             '   [ s i a c _ r _ c a u s a l e _ m o v g e s t _ t s ] . ' ; 
 
 
 
                 i n s e r t   i n t o   s i a c _ r _ c a u s a l e _ m o v g e s t _ t s 
 
                 (   m o v g e s t _ t s _ i d , 
 
                     c a u s _ i d , 
 
 	             v a l i d i t a _ i n i z i o , 
 
 	             e n t e _ p r o p r i e t a r i o _ i d , 
 
                     l o g i n _ o p e r a z i o n e 
 
                 ) 
 
                 (   s e l e c t 
 
                       m o v G e s t T s I d R e t , 
 
                       r . c a u s _ i d , 
 
                       d a t a I n i z i o V a l , 
 
                       e n t e P r o p r i e t a r i o I d , 
 
                       l o g i n O p e r a z i o n e 
 
                     f r o m   s i a c _ r _ c a u s a l e _ m o v g e s t _ t s   r , s i a c _ d _ c a u s a l e   c a u s 
 
                     w h e r e   r . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
                     a n d       c a u s . c a u s _ i d = r . c a u s _ i d 
 
                     a n d       c a u s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       c a u s . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
                   ) ; 
 
 
 
 	 	 s e l e c t   1     i n t o   c o d R e s u l t 
 
                 f r o m   s i a c _ r _ c a u s a l e _ m o v g e s t _ t s   d e t 1 
 
                 w h e r e   d e t 1 . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
                 a n d       d e t 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       d e t 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
                 a n d       n o t   e x i s t s   ( s e l e c t   1   f r o m   s i a c _ r _ c a u s a l e _ m o v g e s t _ t s   d e t 
 
 	 	 	 	                     w h e r e   d e t . m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t 
 
 	 	 	 	 	                 a n d       d e t . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 	 	 	                 a n d       d e t . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	 	 	 	                 a n d       d e t . l o g i n _ o p e r a z i o n e = l o g i n O p e r a z i o n e ) ; 
 
                 r a i s e   n o t i c e   ' d o p o   i n s e r i m e n t o   s i a c _ r _ c a u s a l e _ m o v g e s t _ t s   m o v G e s t T s I d R e t = %   c o d R e s u l t = % ' ,   m o v G e s t T s I d R e t , c o d R e s u l t ; 
 
 
 
                 i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
               	   c o d R e s u l t : = - 1 ; 
 
                   s t r M e s s a g g i o T e m p : = s t r M e s s a g g i o ; 
 
                 e l s e   c o d R e s u l t : = n u l l ; 
 
                 e n d   i f ; 
 
               e n d   i f ;   * / 
 
 
 
               - -   s i a c _ r _ f o n d o _ e c o n _ m o v g e s t 
 
               / *   c a s s a - e c o n o m a l e   d a   n o n   r i b a l t a r e   c o m e   d a   i n d i c a z i o n i   d i   I r e n e 
 
               i f   c o d R e s u l t   i s   n u l l   t h e n 
 
       	         s t r M e s s a g g i o : = ' M o v i m e n t o   m o v G e s t T s T i p o = ' | | m o v G e s t R e c . m o v g e s t _ t s _ t i p o | | 
 
                                               '   m o v g e s t _ o r i g _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ i d | | 
 
                                               '   m o v g e s t _ o r i g _ t s _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d | | 
 
                                               '   e l e m _ o r i g _ i d = ' | | m o v G e s t R e c . e l e m _ o r i g _ i d | | 
 
                                               '   e l e m _ i d = ' | | m o v G e s t R e c . e l e m _ i d | | 
 
                                             '   [ s i a c _ r _ c a u s a l e _ m o v g e s t _ t s ] . ' ; 
 
 
 
                 i n s e r t   i n t o   s i a c _ r _ f o n d o _ e c o n _ m o v g e s t 
 
                 (   m o v g e s t _ t s _ i d , 
 
                     f o n d o e c o n _ i d , 
 
 	             v a l i d i t a _ i n i z i o , 
 
 	             e n t e _ p r o p r i e t a r i o _ i d , 
 
                     l o g i n _ o p e r a z i o n e 
 
                 ) 
 
                 (   s e l e c t 
 
                       m o v G e s t T s I d R e t , 
 
                       r . f o n d o e c o n _ i d , 
 
                       d a t a I n i z i o V a l , 
 
                       e n t e P r o p r i e t a r i o I d , 
 
                       l o g i n O p e r a z i o n e 
 
                     f r o m   s i a c _ r _ f o n d o _ e c o n _ m o v g e s t   r , s i a c _ t _ f o n d o _ e c o n   e c o n 
 
                     w h e r e   r . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
                     a n d       e c o n . f o n d o e c o n _ i d = r . f o n d o e c o n _ i d 
 
                     a n d       e c o n . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       e c o n . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
                   ) ; 
 
 
 
 	 	 s e l e c t   1     i n t o   c o d R e s u l t 
 
                 f r o m   s i a c _ r _ f o n d o _ e c o n _ m o v g e s t   d e t 1 
 
                 w h e r e   d e t 1 . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
                 a n d       d e t 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       d e t 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
                 a n d       n o t   e x i s t s   ( s e l e c t   1   f r o m   s i a c _ r _ f o n d o _ e c o n _ m o v g e s t   d e t 
 
 	 	 	 	                     w h e r e   d e t . m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t 
 
 	 	 	 	 	                 a n d       d e t . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 	 	 	                 a n d       d e t . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	 	 	 	                 a n d       d e t . l o g i n _ o p e r a z i o n e = l o g i n O p e r a z i o n e ) ; 
 
                 r a i s e   n o t i c e   ' d o p o   i n s e r i m e n t o   s i a c _ r _ f o n d o _ e c o n _ m o v g e s t   m o v G e s t T s I d R e t = %   c o d R e s u l t = % ' ,   m o v G e s t T s I d R e t , c o d R e s u l t ; 
 
 
 
                 i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
               	   c o d R e s u l t : = - 1 ; 
 
                   s t r M e s s a g g i o T e m p : = s t r M e s s a g g i o ; 
 
                 e l s e   c o d R e s u l t : = n u l l ; 
 
                 e n d   i f ; 
 
               e n d   i f ; * / 
 
 
 
               - -   s i a c _ r _ r i c h i e s t a _ e c o n _ m o v g e s t 
 
               / *   c a s s a - e c o n o m a l e   d a   n o n   r i b a l t a r e   c o m e   d a   i n d i c a z i o n i   d i   I r e n e 
 
               i f   c o d R e s u l t   i s   n u l l   t h e n 
 
       	         s t r M e s s a g g i o : = ' M o v i m e n t o   m o v G e s t T s T i p o = ' | | m o v G e s t R e c . m o v g e s t _ t s _ t i p o | | 
 
                                               '   m o v g e s t _ o r i g _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ i d | | 
 
                                               '   m o v g e s t _ o r i g _ t s _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d | | 
 
                                               '   e l e m _ o r i g _ i d = ' | | m o v G e s t R e c . e l e m _ o r i g _ i d | | 
 
                                               '   e l e m _ i d = ' | | m o v G e s t R e c . e l e m _ i d | | 
 
                                             '   [ s i a c _ r _ r i c h i e s t a _ e c o n _ m o v g e s t ] . ' ; 
 
 
 
                 i n s e r t   i n t o   s i a c _ r _ r i c h i e s t a _ e c o n _ m o v g e s t 
 
                 (   m o v g e s t _ t s _ i d , 
 
                     r i c e c o n _ i d , 
 
 	             v a l i d i t a _ i n i z i o , 
 
 	             e n t e _ p r o p r i e t a r i o _ i d , 
 
                     l o g i n _ o p e r a z i o n e 
 
                 ) 
 
                 (   s e l e c t 
 
                       m o v G e s t T s I d R e t , 
 
                       r . r i c e c o n _ i d , 
 
                       d a t a I n i z i o V a l , 
 
                       e n t e P r o p r i e t a r i o I d , 
 
                       l o g i n O p e r a z i o n e 
 
                     f r o m   s i a c _ r _ r i c h i e s t a _ e c o n _ m o v g e s t   r , s i a c _ t _ r i c h i e s t a _ e c o n   e c o n 
 
                     w h e r e   r . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
                     a n d       e c o n . r i c e c o n _ i d = r . r i c e c o n _ i d 
 
                     a n d       e c o n . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       e c o n . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
                   ) ; 
 
 
 
 	 	 s e l e c t   1     i n t o   c o d R e s u l t 
 
                 f r o m   s i a c _ r _ r i c h i e s t a _ e c o n _ m o v g e s t   d e t 1 
 
                 w h e r e   d e t 1 . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
                 a n d       d e t 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       d e t 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
                 a n d       n o t   e x i s t s   ( s e l e c t   1   f r o m   s i a c _ r _ r i c h i e s t a _ e c o n _ m o v g e s t   d e t 
 
 	 	 	 	                     w h e r e   d e t . m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t 
 
 	 	 	 	 	                 a n d       d e t . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 	 	 	                 a n d       d e t . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	 	 	 	                 a n d       d e t . l o g i n _ o p e r a z i o n e = l o g i n O p e r a z i o n e ) ; 
 
                 r a i s e   n o t i c e   ' d o p o   i n s e r i m e n t o   s i a c _ r _ r i c h i e s t a _ e c o n _ m o v g e s t   m o v G e s t T s I d R e t = %   c o d R e s u l t = % ' ,   m o v G e s t T s I d R e t , c o d R e s u l t ; 
 
 
 
                 i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
               	   c o d R e s u l t : = - 1 ; 
 
                   s t r M e s s a g g i o T e m p : = s t r M e s s a g g i o ; 
 
                 e l s e   c o d R e s u l t : = n u l l ; 
 
                 e n d   i f ; 
 
               e n d   i f ; * / 
 
 
 
               - -   s i a c _ r _ s u b d o c _ m o v g e s t _ t s 
 
               i f   c o d R e s u l t   i s   n u l l   t h e n 
 
       	         s t r M e s s a g g i o : = ' M o v i m e n t o   m o v G e s t T s T i p o = ' | | m o v G e s t R e c . m o v g e s t _ t s _ t i p o | | 
 
                                               '   m o v g e s t _ o r i g _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ i d | | 
 
                                               '   m o v g e s t _ o r i g _ t s _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d | | 
 
                                               '   e l e m _ o r i g _ i d = ' | | m o v G e s t R e c . e l e m _ o r i g _ i d | | 
 
                                               '   e l e m _ i d = ' | | m o v G e s t R e c . e l e m _ i d | | 
 
                                             '   [ s i a c _ r _ s u b d o c _ m o v g e s t _ t s ] . ' ; 
 
                 - -   1 2 . 0 1 . 2 0 1 7   S o f i a   c o r r e z i o n e   p e r   e s c l u s i o n e   q u o t e   p a g a t e 
 
                 i n s e r t   i n t o   s i a c _ r _ s u b d o c _ m o v g e s t _ t s 
 
                 (   m o v g e s t _ t s _ i d , 
 
                     s u b d o c _ i d , 
 
 	             v a l i d i t a _ i n i z i o , 
 
 	             e n t e _ p r o p r i e t a r i o _ i d , 
 
                     l o g i n _ o p e r a z i o n e 
 
                 ) 
 
                 (   s e l e c t   d i s t i n c t 
 
                       m o v G e s t T s I d R e t , 
 
                       r . s u b d o c _ i d , 
 
                       d a t a I n i z i o V a l , 
 
                       e n t e P r o p r i e t a r i o I d , 
 
                       l o g i n O p e r a z i o n e 
 
                     f r o m   s i a c _ r _ s u b d o c _ m o v g e s t _ t s   r , s i a c _ t _ s u b d o c   s u b 
 
                     w h e r e   r . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
                     a n d       s u b . s u b d o c _ i d = r . s u b d o c _ i d 
 
                     a n d       n o t   e x i s t s   ( s e l e c t   1 
 
                                                         f r o m   s i a c _ r _ s u b d o c _ o r d i n a t i v o _ t s   r o r d , s i a c _ t _ o r d i n a t i v o _ t s   t s o r d ,   s i a c _ t _ o r d i n a t i v o   o r d , 
 
                                                                   s i a c _ r _ o r d i n a t i v o _ s t a t o   r s t a t o ,   s i a c _ d _ o r d i n a t i v o _ s t a t o   s t a t o 
 
   	 	                                 	 w h e r e   r o r d . s u b d o c _ i d = r . s u b d o c _ i d 
 
 	                 	 	                 a n d       t s o r d . o r d _ t s _ i d = r o r d . o r d _ t s _ i d 
 
 	 	 	                                 a n d       o r d . o r d _ i d = t s o r d . o r d _ i d 
 
 	 	 	                                 a n d       o r d . b i l _ i d = b i l a n c i o P r e c I d 
 
 	 	                         	         a n d       r s t a t o . o r d _ i d = o r d . o r d _ i d 
 
 	 	                                 	 a n d       s t a t o . o r d _ s t a t o _ i d = r s t a t o . o r d _ s t a t o _ i d 
 
 	 	 	                                 a n d       s t a t o . o r d _ s t a t o _ c o d e ! = ' A ' 
 
 	 	 	                                 a n d       r o r d . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 	                                 a n d       r o r d . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	         	                         a n d       r s t a t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	                 	                 a n d       r s t a t o . v a l i d i t a _ f i n e   i s   n u l l 
 
                 	 	         	       ) 
 
                     a n d       s u b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       s u b . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
                     - -   1 0 . 0 4 . 2 0 1 8   D a n i e l a   e s c l u s i o n e   d o c u m e n t i   a n n u l l a t i   ( S I A C - 6 0 1 5 ) 
 
                     a n d       n o t   e x i s t s   ( s e l e c t   1 
 
                     	 	 	 	         f r o m   s i a c _ t _ d o c   d o c ,   s i a c _ r _ d o c _ s t a t o   r s t ,   s i a c _ d _ d o c _ s t a t o   s t 
 
                                                         w h e r e   d o c . d o c _ i d   =   s u b . d o c _ i d 
 
                                                         a n d       d o c . d o c _ i d   =   r s t . d o c _ i d 
 
                                                         a n d       r s t . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                                         a n d       r s t . v a l i d i t a _ f i n e   i s   n u l l 
 
                                                         a n d       s t . d o c _ s t a t o _ i d   =   r s t . d o c _ s t a t o _ i d 
 
                                                         a n d       s t . d o c _ s t a t o _ c o d e   =   ' A ' ) 
 
                   ) ; 
 
 
 
 	 	 s e l e c t   1     i n t o   c o d R e s u l t 
 
                 f r o m   s i a c _ r _ s u b d o c _ m o v g e s t _ t s   d e t 1 
 
                 w h e r e   d e t 1 . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
                 a n d       n o t   e x i s t s   ( s e l e c t   1 
 
                                                         f r o m   s i a c _ r _ s u b d o c _ o r d i n a t i v o _ t s   r o r d , s i a c _ t _ o r d i n a t i v o _ t s   t s o r d ,   s i a c _ t _ o r d i n a t i v o   o r d , 
 
                                                                   s i a c _ r _ o r d i n a t i v o _ s t a t o   r s t a t o ,   s i a c _ d _ o r d i n a t i v o _ s t a t o   s t a t o 
 
   	 	                                 	 w h e r e   r o r d . s u b d o c _ i d = d e t 1 . s u b d o c _ i d 
 
 	                 	 	                 a n d       t s o r d . o r d _ t s _ i d = r o r d . o r d _ t s _ i d 
 
 	 	 	                                 a n d       o r d . o r d _ i d = t s o r d . o r d _ i d 
 
 	 	 	                                 a n d       o r d . b i l _ i d = b i l a n c i o P r e c I d 
 
 	 	                         	         a n d       r s t a t o . o r d _ i d = o r d . o r d _ i d 
 
 	 	                                 	 a n d       s t a t o . o r d _ s t a t o _ i d = r s t a t o . o r d _ s t a t o _ i d 
 
 	 	 	                                 a n d       s t a t o . o r d _ s t a t o _ c o d e ! = ' A ' 
 
 	 	 	                                 a n d       r o r d . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 	                                 a n d       r o r d . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	         	                         a n d       r s t a t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	                 	                 a n d       r s t a t o . v a l i d i t a _ f i n e   i s   n u l l 
 
                 	 	         	       ) 
 
                 a n d       n o t   e x i s t s   ( s e l e c t   1   f r o m   s i a c _ r _ s u b d o c _ m o v g e s t _ t s   d e t 
 
 	 	 	 	                     w h e r e   d e t . m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t 
 
 	 	 	 	 	                 a n d       d e t . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 	 	 	                 a n d       d e t . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	 	 	 	                 a n d       d e t . l o g i n _ o p e r a z i o n e = l o g i n O p e r a z i o n e ) 
 
                 a n d       d e t 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       d e t 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
                 a n d       n o t   e x i s t s   ( s e l e c t   1 
 
                     	 	 	 	         f r o m   s i a c _ t _ s u b d o c   s u b ,   s i a c _ t _ d o c   d o c ,   s i a c _ r _ d o c _ s t a t o   r s t ,   s i a c _ d _ d o c _ s t a t o   s t 
 
                                                         w h e r e   d e t 1 . s u b d o c _ i d   =   s u b . s u b d o c _ i d 
 
                                                         a n d       d o c . d o c _ i d   =   s u b . d o c _ i d 
 
                                                         a n d       d o c . d o c _ i d   =   r s t . d o c _ i d 
 
                                                         a n d       r s t . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                                         a n d       r s t . v a l i d i t a _ f i n e   i s   n u l l 
 
                                                         a n d       s t . d o c _ s t a t o _ i d   =   r s t . d o c _ s t a t o _ i d 
 
                                                         a n d       s t . d o c _ s t a t o _ c o d e   =   ' A ' ) ; 
 
 
 
                 r a i s e   n o t i c e   ' d o p o   i n s e r i m e n t o   s i a c _ r _ s u b d o c _ m o v g e s t _ t s   m o v G e s t T s I d R e t = %   c o d R e s u l t = % ' ,   m o v G e s t T s I d R e t , c o d R e s u l t ; 
 
 
 
                 i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
               	   c o d R e s u l t : = - 1 ; 
 
                   s t r M e s s a g g i o T e m p : = s t r M e s s a g g i o ; 
 
                 e l s e   c o d R e s u l t : = n u l l ; 
 
                 e n d   i f ; 
 
               e n d   i f ; 
 
 
 
               - -   s i a c _ r _ p r e d o c _ m o v g e s t _ t s 
 
 	       i f   c o d R e s u l t   i s   n u l l   t h e n 
 
       	         s t r M e s s a g g i o : = ' M o v i m e n t o   m o v G e s t T s T i p o = ' | | m o v G e s t R e c . m o v g e s t _ t s _ t i p o | | 
 
                                               '   m o v g e s t _ o r i g _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ i d | | 
 
                                               '   m o v g e s t _ o r i g _ t s _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d | | 
 
                                               '   e l e m _ o r i g _ i d = ' | | m o v G e s t R e c . e l e m _ o r i g _ i d | | 
 
                                               '   e l e m _ i d = ' | | m o v G e s t R e c . e l e m _ i d | | 
 
                                             '   [ s i a c _ r _ p r e d o c _ m o v g e s t _ t s ] . ' ; 
 
 
 
                 i n s e r t   i n t o   s i a c _ r _ p r e d o c _ m o v g e s t _ t s 
 
                 (   m o v g e s t _ t s _ i d , 
 
                     p r e d o c _ i d , 
 
 	             v a l i d i t a _ i n i z i o , 
 
 	             e n t e _ p r o p r i e t a r i o _ i d , 
 
                     l o g i n _ o p e r a z i o n e 
 
                 ) 
 
                 (   s e l e c t 
 
                       m o v G e s t T s I d R e t , 
 
                       r . p r e d o c _ i d , 
 
                       d a t a I n i z i o V a l , 
 
                       e n t e P r o p r i e t a r i o I d , 
 
                       l o g i n O p e r a z i o n e 
 
                     f r o m   s i a c _ r _ p r e d o c _ m o v g e s t _ t s   r , s i a c _ t _ p r e d o c   s u b 
 
                     w h e r e   r . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
                     a n d       s u b . p r e d o c _ i d = r . p r e d o c _ i d 
 
                     a n d       s u b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       s u b . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
                   ) ; 
 
 
 
 	 	 s e l e c t   1     i n t o   c o d R e s u l t 
 
                 f r o m   s i a c _ r _ p r e d o c _ m o v g e s t _ t s   d e t 1 
 
                 w h e r e   d e t 1 . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
                 a n d       n o t   e x i s t s   ( s e l e c t   1   f r o m   s i a c _ r _ p r e d o c _ m o v g e s t _ t s   d e t 
 
 	 	 	 	                     w h e r e   d e t . m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t 
 
 	 	 	 	 	                 a n d       d e t . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 	 	 	                 a n d       d e t . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	 	 	 	                 a n d       d e t . l o g i n _ o p e r a z i o n e = l o g i n O p e r a z i o n e ) 
 
 	 	 a n d       d e t 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       d e t 1 . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                 r a i s e   n o t i c e   ' d o p o   i n s e r i m e n t o   s i a c _ r _ p r e d o c _ m o v g e s t _ t s   m o v G e s t T s I d R e t = %   c o d R e s u l t = % ' ,   m o v G e s t T s I d R e t , c o d R e s u l t ; 
 
 
 
                 i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
               	   c o d R e s u l t : = - 1 ; 
 
                   s t r M e s s a g g i o T e m p : = s t r M e s s a g g i o ; 
 
                 e l s e   c o d R e s u l t : = n u l l ; 
 
                 e n d   i f ; 
 
               e n d   i f ; 
 
 
 
               - - -   c a n c e l l a z i o n e   r e l a z i o n i   d e l   m o v i m e n t o   p r e c e d e n t e 
 
 	       - -   s i a c _ r _ s u b d o c _ m o v g e s t _ t s 
 
             / *       s p o s t a t o   s o t t o   d o p o   p u l i z i a   i n   c a s o   d i   c o d R e s u l t   n u l l 
 
                       i f   c o d R e s u l t   i s   n u l l   t h e n 
 
 	                 s t r M e s s a g g i o : = ' M o v i m e n t o   m o v G e s t T s T i p o = ' | | m o v G e s t R e c . m o v g e s t _ t s _ t i p o | | 
 
                                               '   m o v g e s t _ o r i g _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ i d | | 
 
                                               '   m o v g e s t _ o r i g _ t s _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d | | 
 
                                               '   e l e m _ o r i g _ i d = ' | | m o v G e s t R e c . e l e m _ o r i g _ i d | | 
 
                                               '   e l e m _ i d = ' | | m o v G e s t R e c . e l e m _ i d | | ' .   C a n c e l l a z i o n e   r e l a z i o n i   s u   g e s t i o n e   p r e c .   [ s i a c _ r _ s u b d o c _ m o v g e s t _ t s ] . ' ; 
 
 	                 u p d a t e   s i a c _ r _ s u b d o c _ m o v g e s t _ t s   r 
 
         	         s e t         d a t a _ c a n c e l l a z i o n e = d a t a E l a b o r a z i o n e , 
 
                 	               v a l i d i t a _ f i n e = d a t a E l a b o r a z i o n e , 
 
                         	       l o g i n _ o p e r a z i o n e = r . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
 	                 w h e r e   r . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
         	         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 	 a n d       r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 	                 s e l e c t   1   i n t o   c o d R e s u l t 
 
         	         f r o m   s i a c _ r _ s u b d o c _ m o v g e s t _ t s   r 
 
                 	 w h e r e   r . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
 	                 a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         	         a n d       r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                 	 i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
 	         	         s t r M e s s a g g i o T e m p : = s t r M e s s a g g i o ; 
 
         	                 c o d R e s u l t : = - 1 ; 
 
 	         	 e l s e   c o d R e s u l t : = n u l l ; 
 
 	               e n d   i f ; 
 
 
 
               e n d   i f ; 
 
 
 
               - -   s i a c _ r _ p r e d o c _ m o v g e s t _ t s 
 
               i f   c o d R e s u l t   i s   n u l l   t h e n 
 
 	                 s t r M e s s a g g i o : = ' M o v i m e n t o   m o v G e s t T s T i p o = ' | | m o v G e s t R e c . m o v g e s t _ t s _ t i p o | | 
 
                                               '   m o v g e s t _ o r i g _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ i d | | 
 
                                               '   m o v g e s t _ o r i g _ t s _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d | | 
 
                                               '   e l e m _ o r i g _ i d = ' | | m o v G e s t R e c . e l e m _ o r i g _ i d | | 
 
                                               '   e l e m _ i d = ' | | m o v G e s t R e c . e l e m _ i d | | ' .   C a n c e l l a z i o n e   r e l a z i o n i   s u   g e s t i o n e   p r e c .   [ s i a c _ r _ p r e d o c _ m o v g e s t _ t s ] . ' ; 
 
 	                 u p d a t e   s i a c _ r _ p r e d o c _ m o v g e s t _ t s   r 
 
         	         s e t         d a t a _ c a n c e l l a z i o n e = d a t a E l a b o r a z i o n e , 
 
                 	               v a l i d i t a _ f i n e = d a t a E l a b o r a z i o n e , 
 
                         	       l o g i n _ o p e r a z i o n e = r . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
 	                 w h e r e   r . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
         	         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 	 a n d       r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 	                 s e l e c t   1   i n t o   c o d R e s u l t 
 
         	         f r o m   s i a c _ r _ p r e d o c _ m o v g e s t _ t s   r 
 
                 	 w h e r e   r . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
 	                 a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         	         a n d       r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                 	 i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
 	         	         s t r M e s s a g g i o T e m p : = s t r M e s s a g g i o ; 
 
         	                 c o d R e s u l t : = - 1 ; 
 
 	         	 e l s e   c o d R e s u l t : = n u l l ; 
 
 	                 e n d   i f ; 
 
               e n d   i f ;   * / 
 
 
 
               - -   s i a c _ r _ c a r t a c o n t _ d e t _ m o v g e s t _ t s 
 
               / *   n o n   s i   g e s t i s c e   i n   s e g u i t o   a d   i n d i c a z i o n i   d i   A n n a l i n a 
 
               i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	   	 s t r M e s s a g g i o : = ' M o v i m e n t o   m o v G e s t T s T i p o = ' | | m o v G e s t R e c . m o v g e s t _ t s _ t i p o | | 
 
 	                                             '   m o v g e s t _ o r i g _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ i d | | 
 
                                                     '   m o v g e s t _ o r i g _ t s _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d | | 
 
                                                     '   e l e m _ o r i g _ i d = ' | | m o v G e s t R e c . e l e m _ o r i g _ i d | | 
 
                                                     '   e l e m _ i d = ' | | m o v G e s t R e c . e l e m _ i d | | ' .   C a n c e l l a z i o n e   r e l a z i o n i   s u   g e s t i o n e   p r e c .   [ s i a c _ r _ c a r t a c o n t _ d e t _ m o v g e s t _ t s ] . ' ; 
 
 	                 u p d a t e   s i a c _ r _ c a r t a c o n t _ d e t _ m o v g e s t _ t s   r 
 
         	         s e t         d a t a _ c a n c e l l a z i o n e = d a t a E l a b o r a z i o n e , 
 
                 	               v a l i d i t a _ f i n e = d a t a E l a b o r a z i o n e , 
 
                         	       l o g i n _ o p e r a z i o n e = r . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
 	                 w h e r e   r . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
         	         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 	 a n d       r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 	                 s e l e c t   1   i n t o   c o d R e s u l t 
 
         	         f r o m   s i a c _ r _ c a r t a c o n t _ d e t _ m o v g e s t _ t s   r 
 
                 	 w h e r e   r . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
 	                 a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         	         a n d       r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                 	 i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
 	         	         s t r M e s s a g g i o T e m p : = s t r M e s s a g g i o ; 
 
         	                 c o d R e s u l t : = - 1 ; 
 
 	         	 e l s e   c o d R e s u l t : = n u l l ; 
 
 	               e n d   i f ; 
 
               e n d   i f ;   * / 
 
 
 
 
 
 	       - -   1 7 . 0 6 . 2 0 1 9   S o f i a   S I A C - 6 7 0 2   -   i n i z i o 
 
 	       i f   c o d R e s u l t   i s   n u l l   t h e n 
 
               	 s t r M e s s a g g i o : = ' M o v i m e n t o   m o v G e s t T s T i p o = ' | | m o v G e s t R e c . m o v g e s t _ t s _ t i p o | | 
 
                                                   '   m o v g e s t _ o r i g _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ i d | | 
 
                                                   '   m o v g e s t _ o r i g _ t s _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d | | 
 
                                                   '   e l e m _ o r i g _ i d = ' | | m o v G e s t R e c . e l e m _ o r i g _ i d | | 
 
                                                   '   e l e m _ i d = ' | | m o v G e s t R e c . e l e m _ i d | | 
 
                                                 '   [ s i a c _ r _ m o v g e s t _ t s _ s t o r i c o _ i m p _ a c c ] . ' ; 
 
 
 
                 i n s e r t   i n t o   s i a c _ r _ m o v g e s t _ t s _ s t o r i c o _ i m p _ a c c 
 
                 (   m o v g e s t _ t s _ i d , 
 
                     m o v g e s t _ a n n o _ a c c , 
 
                     m o v g e s t _ n u m e r o _ a c c , 
 
                     m o v g e s t _ s u b n u m e r o _ a c c , 
 
                     v a l i d i t a _ i n i z i o , 
 
                     e n t e _ p r o p r i e t a r i o _ i d , 
 
                     l o g i n _ o p e r a z i o n e 
 
                 ) 
 
                 (   s e l e c t 
 
                       m o v G e s t T s I d R e t , 
 
                       r . m o v g e s t _ a n n o _ a c c , 
 
                       r . m o v g e s t _ n u m e r o _ a c c , 
 
                       r . m o v g e s t _ s u b n u m e r o _ a c c , 
 
                       d a t a I n i z i o V a l , 
 
                       e n t e P r o p r i e t a r i o I d , 
 
                       l o g i n O p e r a z i o n e 
 
                     f r o m   s i a c _ r _ m o v g e s t _ t s _ s t o r i c o _ i m p _ a c c   r 
 
                     w h e r e   r . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
                     a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
                 ) ; 
 
 
 
 
 
                 s e l e c t   1     i n t o   c o d R e s u l t 
 
                 f r o m   s i a c _ r _ m o v g e s t _ t s _ s t o r i c o _ i m p _ a c c   d e t 1 
 
                 w h e r e   d e t 1 . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
                 a n d       d e t 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       d e t 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
                 a n d       n o t   e x i s t s   ( s e l e c t   1   f r o m   s i a c _ r _ m o v g e s t _ t s _ s t o r i c o _ i m p _ a c c   d e t 
 
 	 	 	 	                     w h e r e   d e t . m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t 
 
 	 	 	 	 	                 a n d       d e t . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 	 	 	                 a n d       d e t . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	 	 	 	                 a n d       d e t . l o g i n _ o p e r a z i o n e = l o g i n O p e r a z i o n e ) ; 
 
                 r a i s e   n o t i c e   ' d o p o   i n s e r i m e n t o   s i a c _ r _ m o v g e s t _ t s _ s t o r i c o _ i m p _ a c c   m o v G e s t T s I d R e t = %   c o d R e s u l t = % ' ,   m o v G e s t T s I d R e t , c o d R e s u l t ; 
 
 
 
                 i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
               	   c o d R e s u l t : = - 1 ; 
 
                   s t r M e s s a g g i o T e m p : = s t r M e s s a g g i o ; 
 
                 e l s e   c o d R e s u l t : = n u l l ; 
 
                 e n d   i f ; 
 
               e n d   i f ; 
 
               - -   1 7 . 0 6 . 2 0 1 9   S o f i a   S I A C - 6 7 0 2   -   f i n e 
 
 
 
               - -   p u l i z i a   d a t i   i n s e r i t i 
 
               - -   a g g i o r n a m e n t o   f a s e _ b i l _ t _ g e s t _ a p e r t u r a _ l i q _ i m p   p e r   s c a r t o 
 
 	       i f   c o d R e s u l t = - 1   t h e n 
 
 
 
 
 
                 i f   m o v G e s t T s I d R e t   i s   n o t   n u l l   t h e n 
 
 
 
 
 
                   - -   s i a c _ r _ m o v g e s t _ c l a s s 
 
 	           s t r M e s s a g g i o : = s t r M e s s a g g i o T e m p | | 
 
                                               '   N o n   E f f e t t u a t o .   C a n c e l l a z i o n e   s i a c _ r _ m o v g e s t _ c l a s s . ' ; 
 
                   d e l e t e   f r o m   s i a c _ r _ m o v g e s t _ c l a s s         w h e r e   m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t ; 
 
                   - -   s i a c _ r _ m o v g e s t _ a t t r 
 
                   s t r M e s s a g g i o : = s t r M e s s a g g i o T e m p | | 
 
                                               '   N o n   E f f e t t u a t o .   C a n c e l l a z i o n e   s i a c _ r _ m o v g e s t _ t s _ a t t r . ' ; 
 
                   d e l e t e   f r o m   s i a c _ r _ m o v g e s t _ t s _ a t t r           w h e r e   m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t ; 
 
 	 	   - -   s i a c _ r _ m o v g e s t _ t s _ a t t o _ a m m 
 
                   s t r M e s s a g g i o : = s t r M e s s a g g i o T e m p | | 
 
                                               '   N o n   E f f e t t u a t o .   C a n c e l l a z i o n e   s i a c _ r _ m o v g e s t _ t s _ a t t r . ' ; 
 
                   d e l e t e   f r o m   s i a c _ r _ m o v g e s t _ t s _ a t t o _ a m m           w h e r e   m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t ; 
 
                   - -   s i a c _ r _ m o v g e s t _ t s _ s t a t o 
 
 	 	   s t r M e s s a g g i o : = s t r M e s s a g g i o T e m p | | 
 
                                               '   N o n   E f f e t t u a t o .   C a n c e l l a z i o n e   s i a c _ r _ m o v g e s t _ t s _ s t a t o . ' ; 
 
                   d e l e t e   f r o m   s i a c _ r _ m o v g e s t _ t s _ s t a t o           w h e r e   m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t ; 
 
 	 	   s t r M e s s a g g i o : = s t r M e s s a g g i o T e m p | | 
 
                                               '   N o n   E f f e t t u a t o .   C a n c e l l a z i o n e   s i a c _ r _ m o v g e s t _ t s _ s o g . ' ; 
 
                   d e l e t e   f r o m   s i a c _ r _ m o v g e s t _ t s _ s o g             w h e r e   m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t ; 
 
                   - -   s i a c _ r _ m o v g e s t _ t s _ s o g c l a s s e 
 
 	 	   s t r M e s s a g g i o : = s t r M e s s a g g i o T e m p | | 
 
                                               '   N o n   E f f e t t u a t o .   C a n c e l l a z i o n e   s i a c _ r _ m o v g e s t _ t s _ s o g c l a s s e . ' ; 
 
                   d e l e t e   f r o m   s i a c _ r _ m o v g e s t _ t s _ s o g c l a s s e             w h e r e   m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t ; 
 
                   - -   s i a c _ t _ m o v g e s t _ t s _ d e t 
 
 	 	   s t r M e s s a g g i o : = s t r M e s s a g g i o T e m p | | 
 
                                               '   N o n   E f f e t t u a t o .   C a n c e l l a z i o n e   s i a c _ t _ m o v g e s t _ t s _ d e t . ' ; 
 
                   d e l e t e   f r o m   s i a c _ t _ m o v g e s t _ t s _ d e t             w h e r e   m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t ; 
 
                   - -   s i a c _ r _ m o v g e s t _ t s _ p r o g r a m m a 
 
                   s t r M e s s a g g i o : = s t r M e s s a g g i o T e m p | | 
 
                                               '   N o n   E f f e t t u a t o .   C a n c e l l a z i o n e   s i a c _ r _ m o v g e s t _ t s _ p r o g r a m m a . ' ; 
 
                   d e l e t e   f r o m   s i a c _ r _ m o v g e s t _ t s _ p r o g r a m m a   w h e r e   m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t ; 
 
                   - -   s i a c _ r _ m u t u o _ v o c e _ m o v g e s t 
 
                   s t r M e s s a g g i o : = s t r M e s s a g g i o T e m p | | 
 
                                               '   N o n   E f f e t t u a t o .   C a n c e l l a z i o n e   s i a c _ r _ m u t u o _ v o c e _ m o v g e s t . ' ; 
 
                   d e l e t e   f r o m   s i a c _ r _ m u t u o _ v o c e _ m o v g e s t   w h e r e   m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t ; 
 
                   - -   s i a c _ r _ g i u s t i f i c a t i v o _ m o v g e s t 
 
 / *                   s t r M e s s a g g i o : = s t r M e s s a g g i o T e m p | | 
 
                                               '   N o n   E f f e t t u a t o .   C a n c e l l a z i o n e   s i a c _ r _ g i u s t i f i c a t i v o _ m o v g e s t . ' ; 
 
                   d e l e t e   f r o m   s i a c _ r _ g i u s t i f i c a t i v o _ m o v g e s t   w h e r e   m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t ; 
 
                   - -   s i a c _ r _ c a r t a c o n t _ d e t _ m o v g e s t _ t s 
 
                   s t r M e s s a g g i o : = s t r M e s s a g g i o T e m p | | 
 
                                               '   N o n   E f f e t t u a t o .   C a n c e l l a z i o n e   s i a c _ r _ c a r t a c o n t _ d e t _ m o v g e s t _ t s . ' ; 
 
                   d e l e t e   f r o m   s i a c _ r _ c a r t a c o n t _ d e t _ m o v g e s t _ t s   w h e r e   m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t ; 
 
                   - -   s i a c _ r _ c a u s a l e _ m o v g e s t _ t s 
 
                   s t r M e s s a g g i o : = s t r M e s s a g g i o T e m p | | 
 
                                               '   N o n   E f f e t t u a t o .   C a n c e l l a z i o n e   s i a c _ r _ c a u s a l e _ m o v g e s t _ t s . ' ; 
 
                   d e l e t e   f r o m   s i a c _ r _ c a u s a l e _ m o v g e s t _ t s   w h e r e   m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t ; 
 
 
 
 	 	   - -   s i a c _ r _ f o n d o _ e c o n _ m o v g e s t 
 
                   s t r M e s s a g g i o : = s t r M e s s a g g i o T e m p | | 
 
                                               '   N o n   E f f e t t u a t o .   C a n c e l l a z i o n e   s i a c _ r _ f o n d o _ e c o n _ m o v g e s t . ' ; 
 
                   d e l e t e   f r o m   s i a c _ r _ f o n d o _ e c o n _ m o v g e s t   w h e r e   m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t ; 
 
 	           - -   s i a c _ r _ r i c h i e s t a _ e c o n _ m o v g e s t 
 
                   s t r M e s s a g g i o : = s t r M e s s a g g i o T e m p | | 
 
                                               '   N o n   E f f e t t u a t o .   C a n c e l l a z i o n e   s i a c _ r _ r i c h i e s t a _ e c o n _ m o v g e s t . ' ; 
 
                   d e l e t e   f r o m   s i a c _ r _ r i c h i e s t a _ e c o n _ m o v g e s t   w h e r e   m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t ;   * / 
 
                   - -   s i a c _ r _ s u b d o c _ m o v g e s t _ t s 
 
                   s t r M e s s a g g i o : = s t r M e s s a g g i o T e m p | | 
 
                                               '   N o n   E f f e t t u a t o .   C a n c e l l a z i o n e   s i a c _ r _ s u b d o c _ m o v g e s t _ t s . ' ; 
 
                   d e l e t e   f r o m   s i a c _ r _ s u b d o c _ m o v g e s t _ t s   w h e r e   m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t ; 
 
                   - -   s i a c _ r _ p r e d o c _ m o v g e s t _ t s 
 
                   s t r M e s s a g g i o : = s t r M e s s a g g i o T e m p | | 
 
                                               '   N o n   E f f e t t u a t o .   C a n c e l l a z i o n e   s i a c _ r _ p r e d o c _ m o v g e s t _ t s . ' ; 
 
                   d e l e t e   f r o m   s i a c _ r _ p r e d o c _ m o v g e s t _ t s   w h e r e   m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t ; 
 
 
 
 	 	   - -   0 3 . 0 5 . 2 0 1 9   S o f i a   s i a c - 6 2 5 5 
 
 	 	   - -   s i a c _ r _ m o v g e s t _ t s _ p r o g r a m m a 
 
                   s t r M e s s a g g i o : = s t r M e s s a g g i o T e m p | | 
 
                                             '   N o n   E f f e t t u a t o .   C a n c e l l a z i o n e   s i a c _ r _ m o v g e s t _ t s _ p r o g r a m m a . ' ; 
 
                   d e l e t e   f r o m   s i a c _ r _ m o v g e s t _ t s _ p r o g r a m m a       w h e r e   m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t ; 
 
                   - -   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m 
 
                   s t r M e s s a g g i o : = s t r M e s s a g g i o T e m p | | 
 
                                             '   N o n   E f f e t t u a t o .   C a n c e l l a z i o n e   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m . ' ; 
 
                   d e l e t e   f r o m   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m   w h e r e   m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t ; 
 
 
 
 	           - -   1 7 . 0 6 . 2 0 1 9   S o f i a   s i a c - 6 7 0 2 
 
                   - -   s i a c _ r _ m o v g e s t _ t s _ s t o r i c o _ i m p _ a c c 
 
   	           s t r M e s s a g g i o : = s t r M e s s a g g i o T e m p | | 
 
                                             '   N o n   E f f e t t u a t o .   C a n c e l l a z i o n e   s i a c _ r _ m o v g e s t _ t s _ s t o r i c o _ i m p _ a c c . ' ; 
 
                   d e l e t e   f r o m   s i a c _ r _ m o v g e s t _ t s _ s t o r i c o _ i m p _ a c c     w h e r e   m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t ; 
 
 
 
 
 
                   - -   s i a c _ t _ m o v g e s t _ t s 
 
   	           s t r M e s s a g g i o : = s t r M e s s a g g i o T e m p | | 
 
                                             '   N o n   E f f e t t u a t o .   C a n c e l l a z i o n e   s i a c _ t _ m o v g e s t _ t s . ' ; 
 
                   d e l e t e   f r o m   s i a c _ t _ m o v g e s t _ t s                   w h e r e   m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t ; 
 
                 e n d   i f ; 
 
 
 
 	 	 i f     m o v G e s t R e c . m o v g e s t _ t s _ t i p o = M O V G E S T _ T S _ T _ T I P O   t h e n 
 
                         - -   s i a c _ r _ m o v g e s t _ b i l _ e l e m 
 
                         s t r M e s s a g g i o : = s t r M e s s a g g i o T e m p | | 
 
                                                     '   N o n   E f f e t t u a t o .   C a n c e l l a z i o n e   s i a c _ t _ m o v g e s t . ' ; 
 
 
 
                         d e l e t e   f r o m   s i a c _ r _ m o v g e s t _ b i l _ e l e m   w h e r e   m o v g e s t _ i d = m o v G e s t I d R e t ; 
 
                 	 - -   s i a c _ t _ m o v g e s t 
 
                         s t r M e s s a g g i o : = s t r M e s s a g g i o T e m p | | 
 
                                                     '   N o n   E f f e t t u a t o .   C a n c e l l a z i o n e   s i a c _ t _ m o v g e s t . ' ; 
 
                         d e l e t e   f r o m   s i a c _ t _ m o v g e s t                     w h e r e   m o v g e s t _ i d = m o v G e s t I d R e t ; 
 
 
 
                 e n d   i f ; 
 
 
 
 
 
 
 
 
 
 / *                 s t r M e s s a g g i o : = s t r M e s s a g g i o T e m p | | 
 
                                           '   N o n   E f f e t t u a t o .   A g g i o r n a m e n t o   f a s e _ b i l _ t _ g e s t _ a p e r t u r a _ l i q _ i m p   p e r   s c a r t o . ' ; * / 
 
                 s t r M e s s a g g i o T e m p : = s t r M e s s a g g i o ; 
 
                 s t r M e s s a g g i o : = s t r M e s s a g g i o | | 
 
                                             ' A g g i o r n a m e n t o   f a s e _ b i l _ t _ g e s t _ a p e r t u r a _ l i q _ i m p   p e r   s c a r t o . ' ; 
 
 
 
             	 u p d a t e   f a s e _ b i l _ t _ g e s t _ a p e r t u r a _ l i q _ i m p   f a s e 
 
                 s e t   f l _ e l a b = ' X ' , 
 
                         s c a r t o _ c o d e = ' R E S 1 ' , 
 
                         s c a r t o _ d e s c = ' M o v i m e n t o   i m p e g n o / s u b i m p e g n o   r e s i d u o   n o n   i n s e r i t o . ' | | s t r M e s s a g g i o T e m p 
 
                 w h e r e   f a s e . f a s e _ b i l _ g e s t _ a p e _ l i q _ i m p _ i d = m o v G e s t R e c . f a s e _ b i l _ g e s t _ a p e _ l i q _ i m p _ i d 
 
                 a n d       f a s e . f a s e _ b i l _ e l a b _ i d = f a s e B i l E l a b I d 
 
                 a n d       f a s e . f l _ e l a b = ' N ' 
 
                 a n d       f a s e . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       f a s e . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 	 	 c o n t i n u e ; 
 
               e n d   i f ; 
 
 
 
               - - -   c a n c e l l a z i o n e   r e l a z i o n i   d e l   m o v i m e n t o   p r e c e d e n t e 
 
 	       - -   s i a c _ r _ s u b d o c _ m o v g e s t _ t s 
 
               i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                         - - -   1 2 . 0 1 . 2 0 1 7   S o f i a   -   s i s t e m a z i o n e   u p d a t e   p e r   e s c l u d e r e   l e   q u o t e   p a g a t e 
 
 	                 s t r M e s s a g g i o : = ' M o v i m e n t o   m o v G e s t T s T i p o = ' | | m o v G e s t R e c . m o v g e s t _ t s _ t i p o | | 
 
                                               '   m o v g e s t _ o r i g _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ i d | | 
 
                                               '   m o v g e s t _ o r i g _ t s _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d | | 
 
                                               '   e l e m _ o r i g _ i d = ' | | m o v G e s t R e c . e l e m _ o r i g _ i d | | 
 
                                               '   e l e m _ i d = ' | | m o v G e s t R e c . e l e m _ i d | | ' .   C a n c e l l a z i o n e   r e l a z i o n i   s u   g e s t i o n e   p r e c .   [ s i a c _ r _ s u b d o c _ m o v g e s t _ t s ] . ' ; 
 
 	                 u p d a t e   s i a c _ r _ s u b d o c _ m o v g e s t _ t s   r 
 
         	         s e t         d a t a _ c a n c e l l a z i o n e = d a t a E l a b o r a z i o n e , 
 
                 	               v a l i d i t a _ f i n e = d a t a E l a b o r a z i o n e , 
 
                         	       l o g i n _ o p e r a z i o n e = r . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
 	                 w h e r e   r . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
                         a n d       n o t   e x i s t s   ( s e l e c t   1 
 
                                                             f r o m   s i a c _ r _ s u b d o c _ o r d i n a t i v o _ t s   r o r d , s i a c _ t _ o r d i n a t i v o _ t s   t s o r d ,   s i a c _ t _ o r d i n a t i v o   o r d , 
 
                                                                       s i a c _ r _ o r d i n a t i v o _ s t a t o   r s t a t o ,   s i a c _ d _ o r d i n a t i v o _ s t a t o   s t a t o 
 
   	 	                                 	     w h e r e   r o r d . s u b d o c _ i d = r . s u b d o c _ i d 
 
 	                 	 	                     a n d       t s o r d . o r d _ t s _ i d = r o r d . o r d _ t s _ i d 
 
 	 	 	                                     a n d       o r d . o r d _ i d = t s o r d . o r d _ i d 
 
 	 	 	                                     a n d       o r d . b i l _ i d = b i l a n c i o P r e c I d 
 
 	 	                         	             a n d       r s t a t o . o r d _ i d = o r d . o r d _ i d 
 
 	 	                                 	     a n d       s t a t o . o r d _ s t a t o _ i d = r s t a t o . o r d _ s t a t o _ i d 
 
 	 	 	                                     a n d       s t a t o . o r d _ s t a t o _ c o d e ! = ' A ' 
 
 	 	 	                                     a n d       r o r d . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 	                                     a n d       r o r d . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	         	                             a n d       r s t a t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	                 	                     a n d       r s t a t o . v a l i d i t a _ f i n e   i s   n u l l 
 
                 	 	         	           ) 
 
         	         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 	 a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
                         a n d       n o t   e x i s t s   ( s e l e c t   1 
 
                                                             f r o m   s i a c _ t _ s u b d o c   s u b , s i a c _ t _ d o c     d o c ,   s i a c _ r _ d o c _ s t a t o   r s t ,   s i a c _ d _ d o c _ s t a t o   s t 
 
                                                             w h e r e   r . s u b d o c _ i d   =   s u b . s u b d o c _ i d 
 
                                                             a n d       d o c . d o c _ i d   =   s u b . d o c _ i d 
 
                                                             a n d       d o c . d o c _ i d   =   r s t . d o c _ i d 
 
                                                             a n d       r s t . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                                             a n d       r s t . v a l i d i t a _ f i n e   i s   n u l l 
 
                                                             a n d       s t . d o c _ s t a t o _ i d   =   r s t . d o c _ s t a t o _ i d 
 
                                                             a n d       s t . d o c _ s t a t o _ c o d e   =   ' A ' ) 
 
                         ; 
 
 
 
 	                 s e l e c t   1   i n t o   c o d R e s u l t 
 
         	         f r o m   s i a c _ r _ s u b d o c _ m o v g e s t _ t s   r 
 
                 	 w h e r e   r . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
                         a n d       n o t   e x i s t s   ( s e l e c t   1 
 
                                                             f r o m   s i a c _ r _ s u b d o c _ o r d i n a t i v o _ t s   r o r d , s i a c _ t _ o r d i n a t i v o _ t s   t s o r d ,   s i a c _ t _ o r d i n a t i v o   o r d , 
 
                                                                       s i a c _ r _ o r d i n a t i v o _ s t a t o   r s t a t o ,   s i a c _ d _ o r d i n a t i v o _ s t a t o   s t a t o 
 
   	 	                                 	     w h e r e   r o r d . s u b d o c _ i d = r . s u b d o c _ i d 
 
 	                 	 	                     a n d       t s o r d . o r d _ t s _ i d = r o r d . o r d _ t s _ i d 
 
 	 	 	                                     a n d       o r d . o r d _ i d = t s o r d . o r d _ i d 
 
 	 	 	                                     a n d       o r d . b i l _ i d = b i l a n c i o P r e c I d 
 
 	 	                         	             a n d       r s t a t o . o r d _ i d = o r d . o r d _ i d 
 
 	 	                                 	     a n d       s t a t o . o r d _ s t a t o _ i d = r s t a t o . o r d _ s t a t o _ i d 
 
 	 	 	                                     a n d       s t a t o . o r d _ s t a t o _ c o d e ! = ' A ' 
 
 	 	 	                                     a n d       r o r d . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 	                                     a n d       r o r d . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	         	                             a n d       r s t a t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	                 	                     a n d       r s t a t o . v a l i d i t a _ f i n e   i s   n u l l 
 
                 	 	         	           ) 
 
 	                 a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         	         a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
                         a n d       n o t   e x i s t s   ( s e l e c t   1 
 
                                                             f r o m   s i a c _ t _ s u b d o c   s u b ,   s i a c _ t _ d o c   d o c ,   s i a c _ r _ d o c _ s t a t o   r s t ,   s i a c _ d _ d o c _ s t a t o   s t 
 
                                                             w h e r e   r . s u b d o c _ i d   =   s u b . s u b d o c _ i d 
 
                                                             a n d       d o c . d o c _ i d   =   s u b . d o c _ i d 
 
                                                             a n d       d o c . d o c _ i d   =   r s t . d o c _ i d 
 
                                                             a n d       r s t . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                                             a n d       r s t . v a l i d i t a _ f i n e   i s   n u l l 
 
                                                             a n d       s t . d o c _ s t a t o _ i d   =   r s t . d o c _ s t a t o _ i d 
 
                                                             a n d       s t . d o c _ s t a t o _ c o d e   =   ' A ' ) 
 
                         ; 
 
 
 
                 	 i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
 	         	         - - s t r M e s s a g g i o T e m p : = s t r M e s s a g g i o ; 
 
         	                 c o d R e s u l t : = - 1 ; 
 
                                 r a i s e   e x c e p t i o n   '   E r r o r e   i n   a g g i o r n a m e n t o . ' ; 
 
 	         	 e l s e   c o d R e s u l t : = n u l l ; 
 
 	                 e n d   i f ; 
 
                 e n d   i f ; 
 
 
 
               - -   s i a c _ r _ p r e d o c _ m o v g e s t _ t s 
 
               i f   c o d R e s u l t   i s   n u l l   t h e n 
 
 	                 s t r M e s s a g g i o : = ' M o v i m e n t o   m o v G e s t T s T i p o = ' | | m o v G e s t R e c . m o v g e s t _ t s _ t i p o | | 
 
                                               '   m o v g e s t _ o r i g _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ i d | | 
 
                                               '   m o v g e s t _ o r i g _ t s _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d | | 
 
                                               '   e l e m _ o r i g _ i d = ' | | m o v G e s t R e c . e l e m _ o r i g _ i d | | 
 
                                               '   e l e m _ i d = ' | | m o v G e s t R e c . e l e m _ i d | | ' .   C a n c e l l a z i o n e   r e l a z i o n i   s u   g e s t i o n e   p r e c .   [ s i a c _ r _ p r e d o c _ m o v g e s t _ t s ] . ' ; 
 
 	                 u p d a t e   s i a c _ r _ p r e d o c _ m o v g e s t _ t s   r 
 
         	         s e t         d a t a _ c a n c e l l a z i o n e = d a t a E l a b o r a z i o n e , 
 
                 	               v a l i d i t a _ f i n e = d a t a E l a b o r a z i o n e , 
 
                         	       l o g i n _ o p e r a z i o n e = r . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
 	                 w h e r e   r . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
         	         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 	 a n d       r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 	                 s e l e c t   1   i n t o   c o d R e s u l t 
 
         	         f r o m   s i a c _ r _ p r e d o c _ m o v g e s t _ t s   r 
 
                 	 w h e r e   r . m o v g e s t _ t s _ i d = m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d 
 
 	                 a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         	         a n d       r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                 	 i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
 - - 	         	         s t r M e s s a g g i o T e m p : = s t r M e s s a g g i o ; 
 
         	                 c o d R e s u l t : = - 1 ; 
 
                                 r a i s e   e x c e p t i o n   '   E r r o r e   i n   a g g i o r n a m e n t o . ' ; 
 
 	         	 e l s e   c o d R e s u l t : = n u l l ; 
 
 	                 e n d   i f ; 
 
               e n d   i f ; 
 
 
 
 	       s t r M e s s a g g i o : = ' M o v i m e n t o   m o v G e s t T s T i p o = ' | | m o v G e s t R e c . m o v g e s t _ t s _ t i p o | | 
 
                                               '   m o v g e s t _ o r i g _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ i d | | 
 
                                               '   m o v g e s t _ o r i g _ t s _ i d = ' | | m o v G e s t R e c . m o v g e s t _ o r i g _ t s _ i d | | 
 
                                               '   e l e m _ o r i g _ i d = ' | | m o v G e s t R e c . e l e m _ o r i g _ i d | | 
 
                                               '   e l e m _ i d = ' | | m o v G e s t R e c . e l e m _ i d | | ' .   A g g i o r n a m e n t o   f a s e _ b i l _ t _ g e s t _ a p e r t u r a _ l i q _ i m p   p e r   f i n e   e l a b o r a z i o n e . ' ; 
 
             	 u p d a t e   f a s e _ b i l _ t _ g e s t _ a p e r t u r a _ l i q _ i m p   f a s e 
 
                 s e t   f l _ e l a b = ' I ' , 
 
                         m o v g e s t _ i d = m o v G e s t I d R e t , 
 
                         m o v g e s t _ t s _ i d = m o v G e s t T s I d R e t 
 
                 w h e r e   f a s e . f a s e _ b i l _ g e s t _ a p e _ l i q _ i m p _ i d = m o v G e s t R e c . f a s e _ b i l _ g e s t _ a p e _ l i q _ i m p _ i d 
 
                 a n d       f a s e . f a s e _ b i l _ e l a b _ i d = f a s e B i l E l a b I d 
 
                 a n d       f a s e . f l _ e l a b = ' N ' 
 
                 a n d       f a s e . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       f a s e . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 
 
               c o d R e s u l t : = n u l l ; 
 
 	       i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
 	       ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
                 v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
 	       ) 
 
 	       v a l u e s 
 
               ( f a s e B i l E l a b I d , s t r M e s s a g g i o | | '   F I N E . ' , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
 	       r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
 
 
 	       i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	   	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
 	       e n d   i f ; 
 
 
 
           e n d   l o o p ; 
 
 
 
 
 
 	   - -   1 5 . 0 2 . 2 0 1 7   S o f i a   S I A C - 4 4 2 5   -   g e s t i o n e   a t t r i b u t o   f l a g F r a z i o n a b i l e 
 
           - -   i n s e r t   N   p e r   i m p e g n i   m o v . m o v g e s t _ a n n o : : i n t e g e r < a n n o B i l a n c i o   o r   m o v . m o v g e s t _ a n n o : : i n t e g e r > a n n o B i l a n c i o 
 
           - -   e s s e n d o   r e s i d u i   c o n s i d e r i a m o   s o l o   m o v . m o v g e s t _ a n n o : : i n t e g e r < a n n o B i l a n c i o 
 
           - -   c h e   n o n   h a n n o   a n c o r a   a t t r i b u t o 
 
           s t r M e s s a g g i o : = ' G e s t i o n e   a t t r i b u t o   ' | | F R A Z I O N A B I L E _ A T T R | | ' .   I n s e r i m e n t o   v a l o r e   N   p e r   i m p e g n i   r e s i d u i . ' ; 
 
           I N S E R T   I N T O   s i a c _ r _ m o v g e s t _ t s _ a t t r 
 
 	   ( 
 
 	     m o v g e s t _ t s _ i d , 
 
 	     a t t r _ i d , 
 
 	     b o o l e a n , 
 
 	     v a l i d i t a _ i n i z i o , 
 
 	     e n t e _ p r o p r i e t a r i o _ i d , 
 
 	     l o g i n _ o p e r a z i o n e 
 
 	   ) 
 
 	   s e l e c t   t s . m o v g e s t _ t s _ i d , 
 
 	                 f l a g F r a z A t t r I d , 
 
                         ' N ' , 
 
 	 	         d a t a I n i z i o V a l , 
 
 	 	         t s . e n t e _ p r o p r i e t a r i o _ i d , 
 
 	 	         l o g i n O p e r a z i o n e 
 
 	   f r o m   s i a c _ t _ m o v g e s t   m o v ,   s i a c _ t _ m o v g e s t _ t s   t s 
 
 	   w h e r e   m o v . b i l _ i d = b i l a n c i o I d 
 
 - - 	 	 a n d       (   m o v . m o v g e s t _ a n n o : : i n t e g e r < a n n o B i l a n c i o   o r   m o v . m o v g e s t _ a n n o : : i n t e g e r > a n n o B i l a n c i o ) 
 
           a n d       m o v . m o v g e s t _ a n n o : : i n t e g e r < a n n o B i l a n c i o 
 
 	   a n d       m o v . m o v g e s t _ t i p o _ i d = t i p o M o v G e s t I d 
 
 	   a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
           a n d       t s . m o v g e s t _ t s _ t i p o _ i d = t i p o M o v G e s t T s T I d 
 
 	   a n d       n o t   e x i s t s   ( s e l e c t   1   f r o m   s i a c _ r _ m o v g e s t _ t s _ a t t r   r 1 
 
               	 	                       w h e r e   r 1 . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
                                               a n d       r 1 . a t t r _ i d = f l a g F r a z A t t r I d 
 
                                               a n d       r 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                               a n d       r 1 . v a l i d i t a _ f i n e   i s   n u l l ) ; 
 
 
 
           - -   i n s e r t   S   p e r   i m p e g n i   m o v . m o v g e s t _ a n n o : : i n t e g e r = a n n o B i l a n c i o 
 
           - -   c h e   n o n   h a n n o   a n c o r a   a t t r i b u t o 
 
           s t r M e s s a g g i o : = ' G e s t i o n e   a t t r i b u t o   ' | | F R A Z I O N A B I L E _ A T T R | | ' .   I n s e r i m e n t o   v a l o r e   S   p e r   i m p e g n i   d i   c o m p e t e n z a   s e n z a   a t t o   a m m i n i s t r a t i v o   a n t e c e d e n t e . ' ; 
 
 	   I N S E R T   I N T O   s i a c _ r _ m o v g e s t _ t s _ a t t r 
 
 	   ( 
 
 	     m o v g e s t _ t s _ i d , 
 
 	     a t t r _ i d , 
 
 	     b o o l e a n , 
 
 	     v a l i d i t a _ i n i z i o , 
 
 	     e n t e _ p r o p r i e t a r i o _ i d , 
 
 	     l o g i n _ o p e r a z i o n e 
 
 	   ) 
 
 	   s e l e c t   t s . m o v g e s t _ t s _ i d , 
 
 	                 f l a g F r a z A t t r I d , 
 
                         ' S ' , 
 
 	                 d a t a I n i z i o V a l , 
 
 	                 t s . e n t e _ p r o p r i e t a r i o _ i d , 
 
 	                 l o g i n O p e r a z i o n e 
 
 	   f r o m   s i a c _ t _ m o v g e s t   m o v ,   s i a c _ t _ m o v g e s t _ t s   t s 
 
 	   w h e r e   m o v . b i l _ i d = b i l a n c i o I d 
 
 	   a n d       m o v . m o v g e s t _ a n n o : : i n t e g e r = a n n o B i l a n c i o 
 
 	   a n d       m o v . m o v g e s t _ t i p o _ i d = t i p o M o v G e s t I d 
 
 	   a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
           a n d       t s . m o v g e s t _ t s _ t i p o _ i d = t i p o M o v G e s t T s T I d 
 
 	   a n d       n o t   e x i s t s   ( s e l e c t   1   f r o m   s i a c _ r _ m o v g e s t _ t s _ a t t r   r 1 
 
               	 	                       w h e r e   r 1 . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
                                               a n d       r 1 . a t t r _ i d = f l a g F r a z A t t r I d 
 
                                               a n d       r 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                               a n d       r 1 . v a l i d i t a _ f i n e   i s   n u l l ) 
 
           a n d     n o t   e x i s t s   ( s e l e c t   1   f r o m   s i a c _ r _ m o v g e s t _ t s _ a t t o _ a m m   r a , s i a c _ t _ a t t o _ a m m   a t t o 
 
 	 	 	 	 	     w h e r e   r a . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
 	 	 	 	 	     a n d       a t t o . a t t o a m m _ i d = r a . a t t o a m m _ i d 
 
 	 	 	 	   	     a n d       a t t o . a t t o a m m _ a n n o : : i n t e g e r   <   a n n o B i l a n c i o 
 
 	 	           	 	     a n d       r a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 	 	             a n d       r a . v a l i d i t a _ f i n e   i s   n u l l ) ; 
 
 
 
           - -   a g g i o r n a m e n t o   N   p e r   i m p e g n i   m o v . m o v g e s t _ a n n o : : i n t e g e r < a n n o B i l a n c i o   o r   m o v . m o v g e s t _ a n n o : : i n t e g e r > a n n o B i l a n c i o 
 
           - -   e s s e n d o   r e s i d u i   c o n s i d e r i a m o   s o l o   m o v . m o v g e s t _ a n n o : : i n t e g e r < a n n o B i l a n c i o 
 
           - -   c h e     h a n n o     a t t r i b u t o   = ' S ' 
 
           s t r M e s s a g g i o : = ' G e s t i o n e   a t t r i b u t o   ' | | F R A Z I O N A B I L E _ A T T R | | ' .   A g g i o r n a m e n t o   v a l o r e   N   p e r   i m p e g n i   r e s i d u i . ' ; 
 
 	   u p d a t e     s i a c _ r _ m o v g e s t _ t s _ a t t r   r   s e t   b o o l e a n = ' N ' 
 
 	   f r o m   s i a c _ t _ m o v g e s t   m o v ,   s i a c _ t _ m o v g e s t _ t s   t s 
 
 	   w h e r e     m o v . b i l _ i d = b i l a n c i o I d 
 
 - - 	 	 a n d       (   m o v . m o v g e s t _ a n n o : : i n t e g e r < 2 0 1 7   o r   m o v . m o v g e s t _ a n n o : : i n t e g e r > 2 0 1 7 ) 
 
 	   a n d       m o v . m o v g e s t _ a n n o : : i n t e g e r < a n n o B i l a n c i o 
 
 	   a n d       m o v . m o v g e s t _ t i p o _ i d = t i p o M o v G e s t I d 
 
 	   a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
           a n d       t s . m o v g e s t _ t s _ t i p o _ i d = t i p o M o v G e s t T s T I d 
 
 	   a n d       r . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
           a n d       r . a t t r _ i d = f l a g F r a z A t t r I d 
 
 	   a n d       r . b o o l e a n = ' S ' 
 
           a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d       r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
           - -   a g g i o r n a m e n t o   N   p e r   i m p e g n i   m o v . m o v g e s t _ a n n o : : i n t e g e r = a n n o B i l a n c i o   e   a t t o . a t t o a m m _ a n n o : : i n t e g e r   <   a n n o B i l a n c i o 
 
           - -   c h e     h a n n o     a t t r i b u t o   = ' S ' 
 
           s t r M e s s a g g i o : = ' G e s t i o n e   a t t r i b u t o   ' | | F R A Z I O N A B I L E _ A T T R | | ' .   A g g i o r n a m e n t o   v a l o r e   N   p e r   i m p e g n i   d i   c o m p e t e n z a   e   a t t i   a m m i n i s t r a t i v i   a n t e c e d e n t i . ' ; 
 
           u p d a t e   s i a c _ r _ m o v g e s t _ t s _ a t t r   r   s e t   b o o l e a n = ' N ' 
 
     	   f r o m   s i a c _ t _ m o v g e s t   m o v ,   s i a c _ t _ m o v g e s t _ t s   t s , 
 
 	             s i a c _ r _ m o v g e s t _ t s _ a t t o _ a m m   r a , s i a c _ t _ a t t o _ a m m   a t t o 
 
     	   w h e r e   m o v . b i l _ i d = b i l a n c i o I d 
 
 	   a n d       m o v . m o v g e s t _ a n n o : : I N T E G E R = 2 0 1 7 
 
 	   a n d       m o v . m o v g e s t _ t i p o _ i d = t i p o M o v G e s t I d 
 
 	   a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
           a n d       t s . m o v g e s t _ t s _ t i p o _ i d = t i p o M o v G e s t T s T I d 
 
 	   a n d       r . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
           a n d       r . a t t r _ i d = f l a g F r a z A t t r I d 
 
 	   a n d       r a . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
 	   a n d       a t t o . a t t o a m m _ i d = r a . a t t o a m m _ i d 
 
 	   a n d       a t t o . a t t o a m m _ a n n o : : i n t e g e r   <   a n n o B i l a n c i o 
 
 	   a n d       r . b o o l e a n = ' S ' 
 
           a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
           a n d       r a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d       r a . v a l i d i t a _ f i n e   i s   n u l l ; 
 
         - -   1 5 . 0 2 . 2 0 1 7   S o f i a   S I A C - 4 4 2 5   -   g e s t i o n e   a t t r i b u t o   f l a g F r a z i o n a b i l e 
 
 
 
         s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   s t a t o   f a s e   b i l a n c i o   I N - 2 . ' ; 
 
         u p d a t e   f a s e _ b i l _ t _ e l a b o r a z i o n e 
 
         s e t   f a s e _ b i l _ e l a b _ e s i t o = ' I N - 2 ' , 
 
                 f a s e _ b i l _ e l a b _ e s i t o _ m s g = ' E L A B O R A Z I O N E   F A S E   B I L A N C I O   ' | | t i p o E l a b | | '   I N   C O R S O   I N - 2 . E l a b o r a   I m p . ' 
 
         w h e r e   f a s e _ b i l _ e l a b _ i d = f a s e B i l E l a b I d ; 
 
 
 
 
 
         c o d i c e R i s u l t a t o : = 0 ; 
 
         m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | '   F I N E ' ; 
 
         r e t u r n ; 
 
 
 
 e x c e p t i o n 
 
         w h e n   R A I S E _ E X C E P T I O N   T H E N 
 
         	 r a i s e   n o t i c e   ' %   %   E R R O R E   :   % ' , s t r M e s s a g g i o F i n a l e , c o a l e s c e ( s t r M e s s a g g i o , ' ' ) , 
 
 	                 	 s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   5 0 0 ) ; 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | ' E R R O R E   : ' | | '   ' | | s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   1 5 0 0 )   ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 r e t u r n ; 
 
 
 
 	 w h e n   n o _ d a t a _ f o u n d   T H E N 
 
 	 	 r a i s e   n o t i c e   '   %   %   N e s s u n   e l e m e n t o   t r o v a t o . '   , s t r M e s s a g g i o F i n a l e , c o a l e s c e ( s t r M e s s a g g i o , ' ' ) ; 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | ' N e s s u n   e l e m e n t o   t r o v a t o . '   ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
 	 	 r e t u r n ; 
 
 	 w h e n   o t h e r s     T H E N 
 
 	 	 r a i s e   n o t i c e   ' %   %   E r r o r e   D B   %   % ' , s t r M e s s a g g i o F i n a l e , c o a l e s c e ( s t r M e s s a g g i o , ' ' ) , S Q L S T A T E , 
 
 	                 	 s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   5 0 ) ; 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | ' E r r o r e   D B   ' | | S Q L S T A T E | | '   ' | | s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   1 5 0 0 )   ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 r e t u r n ; 
 
 
 
 E N D ; 
 
 $ b o d y $ 
 
 L A N G U A G E   ' p l p g s q l ' 
 
 V O L A T I L E 
 
 C A L L E D   O N   N U L L   I N P U T 
 
 S E C U R I T Y   I N V O K E R 
 
 C O S T   1 0 0 ; 