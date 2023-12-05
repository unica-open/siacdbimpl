/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_liq_elabora_liq(enteproprietarioid integer, annobilancio integer, fasebilelabid integer, minid integer, maxid integer, loginoperazione character varying, dataelaborazione timestamp without time zone, OUT codicerisultato integer, OUT messaggiorisultato character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
	strMessaggio VARCHAR(1500):='';
    strMessaggioTemp VARCHAR(1000):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;


    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;
    dataEmissione     timestamp:=null;

    movGestRec        record;


    liqIdRet          integer:=null;

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


    APE_GEST_LIQ_RES  CONSTANT varchar:='APE_GEST_LIQ_RES';


BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;



    dataInizioVal:= clock_timestamp();

	strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento liquidazioni  residue da Gestione precedente. Anno bilancio='||annoBilancio::varchar
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
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_liq.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_liq fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   fase.fl_elab='N';
    if codResult is null then
      raise exception ' Nessuna liquidazione da creare.';
    end if;


/*    codResult:=null;
    strMessaggio:='Verifica esistenza movimenti creati in fase_bil_t_gest_apertura_liq_imp.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_liq fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   fase.fl_elab='N'
    and   not exists (select 1 from fase_bil_t_gest_apertura_liq_imp fase1
                  	  where fase1.fase_bil_elab_id=faseBilElabId
				      and   fase1.data_cancellazione is null
				      and   fase1.validita_fine is null
    	              and   fase1.movgest_orig_id=fase.movgest_orig_id
        	          and   fase1.movgest_orig_ts_id=fase.movgest_orig_ts_id
            	      and   fase1.fl_elab='I'
                     );
    if codResult is not null then
      raise exception ' Esistono liquidazioni da creare per cui non e'' stato creato il relativo movimento residuo.';
    end if;*/



    if coalesce(minId,0)=0 or coalesce(maxId,0)=0 then
        strMessaggio:='Calcolo min, max Id da elaborare in [fase_bil_t_gest_apertura_liq].';
    	minId:=1;

        select max(fase.fase_bil_gest_ape_liq_id) into maxId
        from fase_bil_t_gest_apertura_liq fase
	    where fase.fase_bil_elab_id=faseBilElabId
    	and   fase.data_cancellazione is null
	    and   fase.validita_fine is null
        and   fase.fl_elab='N';
        if coalesce(maxId ,0)=0 then
        	raise exception ' Impossibile determinare il maxId';
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

     strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioPrecId, periodoPrecId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio-1
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;


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

	 strMessaggio:='Verifica scarti in fase_bil_t_gest_apertura_liq per inesistenza movimento gestione nel nuovo bilancio.';
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

	 update fase_bil_t_gest_apertura_liq fase
     set   fl_elab='X',
           scarto_code='LIQ1',
           scarto_desc='Movimento di gestione non esistente in nuovo bilancio'
     where fase.fase_bil_elab_id=faseBilElabId
     and   fase.fase_bil_gest_ape_liq_id between minId and maxId
     and   fase.fl_elab='N'
     and   not exists (select 1
                       from siac_t_movgest mov, siac_t_movgest_ts ts,
                            siac_t_movgest movprec, siac_t_movgest_ts tsprec
    			       where movprec.movgest_id=fase.movgest_orig_id
                       and   tsprec.movgest_ts_id=fase.movgest_orig_ts_id
                       and   tsprec.movgest_id=movprec.movgest_id
                       and   mov.bil_id=bilancioId
                       and   mov.movgest_tipo_id=movprec.movgest_tipo_id
                       and   mov.movgest_anno=movprec.movgest_anno
                       and   mov.movgest_numero=movprec.movgest_numero
                       and   ts.movgest_id=mov.movgest_id
                       and   ts.movgest_ts_code=tsprec.movgest_ts_code
                       and   mov.data_cancellazione is null
                       and   mov.validita_fine is null
                       and   ts.data_cancellazione is null
                       and   ts.validita_fine is null
                       )
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null;


     strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_liq per estremi movimento gestione nel nuovo bilancio.';
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

	 update fase_bil_t_gest_apertura_liq fase
     set   movgest_id=mov.movgest_id,
           movgest_ts_id=ts.movgest_ts_id
     from siac_t_movgest mov, siac_t_movgest_ts ts,
          siac_t_movgest movprec, siac_t_movgest_ts tsprec
     where fase.fase_bil_elab_id=faseBilElabId
     and   fase.fase_bil_gest_ape_liq_id between minId and maxId
     and   fase.fl_elab='N'
     and   fase.movgest_id is null
     and   fase.movgest_ts_id is null
     and   movprec.movgest_id=fase.movgest_orig_id
     and   tsprec.movgest_ts_id=fase.movgest_orig_ts_id
     and   tsprec.movgest_id=movprec.movgest_id
     and   mov.bil_id=bilancioId
     and   mov.movgest_tipo_id=movprec.movgest_tipo_id
     and   mov.movgest_anno=movprec.movgest_anno
     and   mov.movgest_numero=movprec.movgest_numero
     and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_code=tsprec.movgest_ts_code
     and   mov.data_cancellazione is null
     and   mov.validita_fine is null
     and   ts.data_cancellazione is null
     and   ts.validita_fine is null
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null;

     codResult:=null;
	 select 1 into codResult
     from fase_bil_t_gest_apertura_liq fase
     where fase.fase_bil_elab_id=faseBilElabId
     and   fase.fase_bil_gest_ape_liq_id between minId and maxId
     and   fase.fl_elab='N'
     and   fase.movgest_id is null
     and   fase.movgest_ts_id is null
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null;
	 if codResult is not null then
     	raise exception ' Non tutti i record sono stati correttamente aggiornati.';
     end if;

	 strMessaggio:='Verifica scarti in fase_bil_t_gest_apertura_liq per liquidazione provvisoria senza documento.';
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

	 update fase_bil_t_gest_apertura_liq fase
     set   fl_elab='X',
           scarto_code='LIQ3',
           scarto_desc='Liquidazione provvisoria senza documenti.'
     where fase.fase_bil_elab_id=faseBilElabId
     and   fase.fase_bil_gest_ape_liq_id between minId and maxId
     and   fase.fl_elab='N'
     and   exists (select 1 from siac_r_liquidazione_stato rstato
                                ,siac_d_liquidazione_stato dstato
    			       where rstato.liq_id=fase.liq_orig_id
                       and   rstato.liq_stato_id = dstato.liq_stato_id
                       and   dstato.liq_stato_code = 'P'
                       and   rstato.data_cancellazione is null
                       and   rstato.validita_fine is null)
     and   not exists (select 1
                       from siac_r_subdoc_liquidazione rsub
    			       where rsub.liq_id=fase.liq_orig_id
                       and   rsub.data_cancellazione is null
                       and   rsub.validita_fine is null
                       )
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null;


     -- SIAC-8551 28.04.2022  Sofia - inizio  
     strMessaggio:='Verifica scarti in fase_bil_t_gest_apertura_liq per liquidazione riferita a documento collegato a prov.cassa di anno in chiusura.';
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

	 update fase_bil_t_gest_apertura_liq fase
     set   fl_elab='X',
           scarto_code='LIQ4',
           scarto_desc='Liquidazione su documento collegato a prov. cassa su anno in chiusura.'
     where fase.fase_bil_elab_id=faseBilElabId
     and   fase.fase_bil_gest_ape_liq_id between minId and maxId
     and   fase.fl_elab='N'
     and   exists (select 1
                   from siac_r_subdoc_liquidazione rsub,siac_r_subdoc_prov_cassa rprov,siac_t_prov_cassa p
    		       where rsub.liq_id=fase.liq_orig_id
    		       AND   rprov.subdoc_id=rsub.subdoc_id 
    		       AND   p.provc_id=rprov.provc_id
    		       AND   p.provc_anno::integer=(annoBilancio-1)
                   and   rsub.data_cancellazione is null
                   and   rsub.validita_fine is NULL
                   and   rprov.data_cancellazione is null
                   and   rprov.validita_fine is null
                   and   p.data_cancellazione is null
                   and   p.validita_fine is null
                   )
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null;
     -- SIAC-8551 28.04.2022  Sofia - fine 
    
     strMessaggio:='Inizio ciclo per generazione liquidazioni.';
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
     (select  fase.fase_bil_gest_ape_liq_id,
	   		  fase.movgest_ts_tipo,
		      fase.movgest_orig_id,
	          fase.movgest_orig_ts_id,
              fase.liq_orig_id,
		      fase.elem_orig_id,
              fase.elem_id,
              fase.movgest_id,
              fase.movgest_ts_id,
	          fase.liq_importo
      from  fase_bil_t_gest_apertura_liq fase
      where fase.fase_bil_elab_id=faseBilElabId
      and   fase.fase_bil_gest_ape_liq_id between minId and maxId
      and   fase.fl_elab='N'
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      order by fase.fase_bil_gest_ape_liq_id
     )
     loop

     	liqIdRet:=null;
        codResult:=null;

        -- siac_t_liquidazione
        -- siac_r_liquidazione_stato
        -- siac_r_liquidazione_soggetto
        -- siac_r_liquidazione_movgest
        -- siac_r_liquidazione_atto_amm
        -- siac_r_liquidazione_class
        -- siac_r_liquidazione_attr
        -- siac_r_subdoc_liquidazione
		--raise notice 'Inizio ciclo';
        strMessaggio:='Movimento liq_orig_id='||movGestRec.liq_orig_id||
                      ' movGestTsTipo='||movGestRec.movgest_ts_tipo||
                      ' elem_orig_id='||movGestRec.elem_orig_id||
                      ' elem_id='||movGestRec.elem_id||
                      ' movgest_id='||movGestRec.movgest_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_id||'.';
		--raise notice 'Inizio ciclo strMessaggio=%',strMessaggio;

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

         -- siac_t_liquidazione
		 strMessaggio:=strMessaggio||'Inseimento liquidazione [siac_t_liquidazione].';
         insert into siac_t_liquidazione
         (liq_anno,
		  liq_numero,
		  liq_desc,
		  liq_emissione_data,
		  liq_importo,
		  liq_automatica,
		  liq_convalida_manuale,
		  contotes_id,
		  dist_id,
		  bil_id,
		  modpag_id,
          soggetto_relaz_id,
		  validita_inizio,
		  ente_proprietario_id,
	      login_operazione,
	      siope_tipo_debito_id ,
		  siope_assenza_motivazione_id

         )
         (select
           liq.liq_anno,
		   liq.liq_numero,
		   liq.liq_desc,
		   liq.liq_emissione_data,
		   movGestRec.liq_importo,
		   liq.liq_automatica,
		   liq.liq_convalida_manuale,
		   liq.contotes_id,
		   liq.dist_id,
		   bilancioId,
		   liq.modpag_id,
           liq.soggetto_relaz_id,
		   dataInizioVal,
		   enteProprietarioId,
	       loginOperazione,
           liq.siope_tipo_debito_id,
		   liq.siope_assenza_motivazione_id

           from siac_t_liquidazione liq
           where liq.liq_id=movGestRec.liq_orig_id
         )
         returning liq_id into liqIdRet;

         if liqIdRet is null then
            strMessaggioTemp:=strMessaggio;
            codResult:=-1;
         end if;

         raise notice 'dopo inserimento siac_t_liquidazione liqIdRet=%',liqIdRet;

         -- siac_r_liquidazione_stato
         if codResult is null then
         	strMessaggio:='Movimento liq_orig_id='||movGestRec.liq_orig_id||
                      ' movGestTsTipo='||movGestRec.movgest_ts_tipo||
                      ' elem_orig_id='||movGestRec.elem_orig_id||
                      ' elem_id='||movGestRec.elem_id||
                      ' movgest_id='||movGestRec.movgest_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_id||'. Inserimento siac_r_liquidazione_stato.';

            insert into siac_r_liquidazione_stato
            (liq_id,
             liq_stato_id,
             validita_inizio,
             ente_proprietario_id,
             login_operazione
            )
            (select liqIdRet,
                    r.liq_stato_id,
                    dataInizioVal,
		  	 	    enteProprietarioId,
	                loginOperazione
             from siac_r_liquidazione_stato r
             where r.liq_id= movGestRec.liq_orig_id
             and   r.data_cancellazione is null
             and   r.validita_fine is null
            )
            returning liq_stato_r_id into codResult;

            raise notice 'dopo inserimento siac_r_liquidazione_stato codResult=%',codResult;

            if codResult is null then
      	      strMessaggioTemp:=strMessaggio;
        	  codResult:=-1;
            else codResult:=null;
	        end if;
         end if;

         -- siac_r_liquidazione_soggetto
		 if codResult is null then
         	strMessaggio:='Movimento liq_orig_id='||movGestRec.liq_orig_id||
                      ' movGestTsTipo='||movGestRec.movgest_ts_tipo||
                      ' elem_orig_id='||movGestRec.elem_orig_id||
                      ' elem_id='||movGestRec.elem_id||
                      ' movgest_id='||movGestRec.movgest_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_id||'. Inserimento siac_r_liquidazione_soggetto.';
            insert into siac_r_liquidazione_soggetto
            (liq_id,
             soggetto_id,
             validita_inizio,
             ente_proprietario_id,
             login_operazione
            )
            (select liqIdRet,
                    r.soggetto_id,
                    dataInizioVal,
		  	 	    enteProprietarioId,
	                loginOperazione
             from siac_r_liquidazione_soggetto r
             where r.liq_id=movGestRec.liq_orig_id
             and   r.data_cancellazione is null
             and   r.validita_fine is null
            )
            returning liq_soggetto_id into codResult;

            raise notice 'dopo inserimento siac_r_liquidazione_soggetto codResult=%',codResult;

            if codResult is null then
      	      strMessaggioTemp:=strMessaggio;
        	  codResult:=-1;
            else codResult:=null;
	        end if;

         end if;

         -- siac_r_liquidazione_movgest
         if codResult is null then
             strMessaggio:='Movimento liq_orig_id='||movGestRec.liq_orig_id||
                      ' movGestTsTipo='||movGestRec.movgest_ts_tipo||
                      ' elem_orig_id='||movGestRec.elem_orig_id||
                      ' elem_id='||movGestRec.elem_id||
                      ' movgest_id='||movGestRec.movgest_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_id||'. Inserimento siac_r_liquidazione_movgest.';
             insert into siac_r_liquidazione_movgest
             (liq_id,
              movgest_ts_id,
              validita_inizio,
              ente_proprietario_id,
              login_operazione
             )
             values
             (liqIdRet,
              movGestRec.movgest_ts_id,
              dataInizioVal,
 	 	      enteProprietarioId,
	          loginOperazione
             );

             select 1 into codResult
             from siac_r_liquidazione_movgest r
             where r.liq_id=liqIdRet
             and   r.data_cancellazione is null
             and   r.validita_fine is null;

             raise notice 'dopo inserimento siac_r_liquidazione_movgest codResult=%',codResult;

             if codResult is null then
    	      strMessaggioTemp:=strMessaggio;
        	  codResult:=-1;
	         else codResult:=null;
             end if;

         end if;

		 -- siac_r_liquidazione_atto_amm
         if codResult is null then
         	strMessaggio:='Movimento liq_orig_id='||movGestRec.liq_orig_id||
                           ' movGestTsTipo='||movGestRec.movgest_ts_tipo||
                           ' movgest_orig_id='||movGestRec.movgest_orig_id||
                           ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                           ' elem_orig_id='||movGestRec.elem_orig_id||
                           ' elem_id='||movGestRec.elem_id||'. Inserimento siac_r_liquidazione_atto_amm.';
            insert into siac_r_liquidazione_atto_amm
            (liq_id,
             attoamm_id,
             validita_inizio,
             ente_proprietario_id,
             login_operazione
            )
            (select  liqIdRet,
                     r.attoamm_id,
                     dataInizioVal,
	 	 	         enteProprietarioId,
	                 loginOperazione
             from siac_r_liquidazione_atto_amm r
             where r.liq_id=movGestRec.liq_orig_id
             and   r.data_cancellazione is null
             and   r.validita_fine is null
            )
            returning liq_atto_amm_id into codResult;
            raise notice 'dopo inserimento siac_r_liquidazione_atto_amm codResult=%',codResult;

            if codResult is null then
    	      strMessaggioTemp:=strMessaggio;
        	  codResult:=-1;
	        else codResult:=null;
            end if;

         end if;



		 -- siac_r_liquidazione_class
         if codResult is null then
         	strMessaggio:='Movimento liq_orig_id='||movGestRec.liq_orig_id||
                      ' movGestTsTipo='||movGestRec.movgest_ts_tipo||
                      ' elem_orig_id='||movGestRec.elem_orig_id||
                      ' elem_id='||movGestRec.elem_id||
                      ' movgest_id='||movGestRec.movgest_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_id||'. Inserimento siac_r_liquidazione_class.';
            insert into  siac_r_liquidazione_class
            (liq_id,
             classif_id,
             validita_inizio,
             ente_proprietario_id,
             login_operazione
            )
            (select  liqIdRet,
                     r.classif_id,
                     dataInizioVal,
	 	 	         enteProprietarioId,
	                 loginOperazione
             from siac_r_liquidazione_class r, siac_t_class c
             where r.liq_id=movGestRec.liq_orig_id
             and   c.classif_id=r.classif_id
             and   r.data_cancellazione is null
             and   r.validita_fine is null
             and   c.data_cancellazione is null
             and   c.validita_fine is null
            );

            select 1 into codResult
            from siac_r_liquidazione_class r,siac_t_class c
            where r.liq_id=movGestRec.liq_orig_id
             and   c.classif_id=r.classif_id
             and   r.data_cancellazione is null
             and   r.validita_fine is null
             and   c.data_cancellazione is null
             and   c.validita_fine is null
             and   not exists ( select 1
				                from siac_r_liquidazione_class r
				                where r.liq_id=liqIdRet
					            and   r.data_cancellazione is null
					            and   r.validita_fine is null
                               );
			raise notice 'dopo inserimento siac_r_liquidazione_class codResult=%',codResult;

            if codResult is not null then
    	      strMessaggioTemp:=strMessaggio;
        	  codResult:=-1;
	        else codResult:=null;
            end if;

         end if;

         -- siac_r_liquidazione_attr
         if codResult is null then
         	strMessaggio:='Movimento liq_orig_id='||movGestRec.liq_orig_id||
                      ' movGestTsTipo='||movGestRec.movgest_ts_tipo||
                      ' elem_orig_id='||movGestRec.elem_orig_id||
                      ' elem_id='||movGestRec.elem_id||
                      ' movgest_id='||movGestRec.movgest_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_id||'. Inserimento siac_r_liquidazione_attr.';
             insert into siac_r_liquidazione_attr
             (liq_id,
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
             (select liqIdRet,
                     r.attr_id,
                     r.tabella_id,
			         r.boolean,
		             r.percentuale,
		             r.testo,
			         r.numerico,
                     dataInizioVal,
	 	 	         enteProprietarioId,
	                 loginOperazione
              from siac_r_liquidazione_attr r, siac_t_attr attr
              where r.liq_id=movGestRec.liq_orig_id
              and   attr.attr_id=r.attr_id
              and   r.data_cancellazione is null
              and   r.validita_fine is null
              and   attr.data_cancellazione is null
              and   attr.validita_fine is null
             );

             select 1 into codResult
             from siac_r_liquidazione_attr r, siac_t_attr attr
              where r.liq_id=movGestRec.liq_orig_id
              and   attr.attr_id=r.attr_id
              and   r.data_cancellazione is null
              and   r.validita_fine is null
              and   attr.data_cancellazione is null
              and   attr.validita_fine is null
              and   not exists (select 1
				                from siac_r_liquidazione_attr r
					            where r.liq_id=liqIdRet
					            and   r.data_cancellazione is null
					            and   r.validita_fine is null
                                );
			raise notice 'dopo inserimento siac_r_liquidazione_attr codResult=%',codResult;

             if codResult is not null then
    	      strMessaggioTemp:=strMessaggio;
        	  codResult:=-1;
	         else codResult:=null;
             end if;
         end if;


         -- siac_r_subdoc_liquidazione
         if codResult is null then
         	strMessaggio:='Movimento liq_orig_id='||movGestRec.liq_orig_id||
                      ' movGestTsTipo='||movGestRec.movgest_ts_tipo||
                      ' elem_orig_id='||movGestRec.elem_orig_id||
                      ' elem_id='||movGestRec.elem_id||
                      ' movgest_id='||movGestRec.movgest_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_id||'. Inserimento siac_r_subdoc_liquidazione.';
            insert into siac_r_subdoc_liquidazione
            (liq_id,
             subdoc_id,
             validita_inizio,
             ente_proprietario_id,
             login_operazione
            )
            (select liqIdRet,
                    r.subdoc_id,
                    dataInizioVal,
	 	 	        enteProprietarioId,
	                loginOperazione
             from siac_r_subdoc_liquidazione r, siac_t_subdoc sub
             where r.liq_id=movGestRec.liq_orig_id
             and   sub.subdoc_id=r.subdoc_id
             and   not exists (select 1
                               from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                    siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
			                   where rord.subdoc_id=r.subdoc_id
		        		        and  tsord.ord_ts_id=rord.ord_ts_id
				                and  ord.ord_id=tsord.ord_id
				                and  ord.bil_id=bilancioPrecId
		    	        	    and  rstato.ord_id=ord.ord_id
		        	        	and  stato.ord_stato_id=rstato.ord_stato_id
			        	        and  stato.ord_stato_code!='A'
			            	    and  rord.data_cancellazione is null
			                	and  rord.validita_fine is null
			    	            and  rstato.data_cancellazione is null
			        	        and  rstato.validita_fine is null
        			    	  )
             and   r.data_cancellazione is null
             and   r.validita_fine is null
             and   sub.data_cancellazione is null
             and   sub.validita_fine is null
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

             select 1 into codResult
             from siac_r_subdoc_liquidazione r, siac_t_subdoc sub
             where r.liq_id=movGestRec.liq_orig_id
             and   sub.subdoc_id=r.subdoc_id
             and   not exists (select 1
                               from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                    siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
			                   where rord.subdoc_id=r.subdoc_id
		        		        and  tsord.ord_ts_id=rord.ord_ts_id
				                and  ord.ord_id=tsord.ord_id
				                and  ord.bil_id=bilancioPrecId
		    	        	    and  rstato.ord_id=ord.ord_id
		        	        	and  stato.ord_stato_id=rstato.ord_stato_id
			        	        and  stato.ord_stato_code!='A'
			            	    and  rord.data_cancellazione is null
			                	and  rord.validita_fine is null
			    	            and  rstato.data_cancellazione is null
			        	        and  rstato.validita_fine is null
        			    	  )
             and   not exists (select 1
				               from siac_r_subdoc_liquidazione r
					           where r.liq_id=liqIdRet
				               and   r.data_cancellazione is null
					           and   r.validita_fine is null)
             and   r.data_cancellazione is null
             and   r.validita_fine is null
             and   sub.data_cancellazione is null
             and   sub.validita_fine is null
        	 and   not exists (select 1
          				    from siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                            where doc.doc_id = sub.doc_id
                            and   doc.doc_id = rst.doc_id
                            and   rst.data_cancellazione is null
                            and   rst.validita_fine is null
                            and   st.doc_stato_id = rst.doc_stato_id
                            and   st.doc_stato_code = 'A')
             ;
			raise notice 'dopo inserimento siac_r_subdoc_liquidazione codResult=%',codResult;

             if codResult is not null then
    	      strMessaggioTemp:=strMessaggio;
        	  codResult:=-1;
	         else codResult:=null;
             end if;

       end if;

	   -- cancellazione logica relazioni anno precedente
       -- siac_r_subdoc_liquidazione
       /* spostato sotto
       if codResult is null then
	        strMessaggio:='Movimento liq_orig_id='||movGestRec.liq_orig_id||
                      ' movGestTsTipo='||movGestRec.movgest_ts_tipo||
                      ' elem_orig_id='||movGestRec.elem_orig_id||
                      ' elem_id='||movGestRec.elem_id||
                      ' movgest_id='||movGestRec.movgest_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_id||'. Cancellazione relazioni liquidazione su gestione prec. [siac_r_subdoc_liquidazione].';
	        update siac_r_subdoc_liquidazione r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.liq_id=movGestRec.liq_orig_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_subdoc_liquidazione r
        	where r.liq_id=movGestRec.liq_orig_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	       end if;

        end if; */

       -- pulizia dati inseriti
       -- aggiornamento fase_bil_t_gest_apertura_liq per scarto
	   if codResult=-1 then

         -- siac_r_subdoc_liquidazione
	     strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_subdoc_liquidazione.';
         delete from siac_r_subdoc_liquidazione    where liq_id=liqIdRet;


         -- siac_r_liquidazione_class
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_liquidazione_class.';
         delete from siac_r_liquidazione_class    where liq_id=liqIdRet;


         -- siac_r_liquidazione_attr
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_liquidazione_attr.';
         delete from siac_r_liquidazione_attr    where liq_id=liqIdRet;



		 -- siac_r_liquidazione_atto_amm
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_liquidazione_atto_amm.';
         delete from siac_r_liquidazione_atto_amm    where liq_id=liqIdRet;

		 -- siac_r_liquidazione_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_liquidazione_movgest.';
         delete from siac_r_liquidazione_movgest    where liq_id=liqIdRet;

         -- siac_r_liquidazione_soggetto
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_liquidazione_soggetto.';
         delete from siac_r_liquidazione_soggetto    where liq_id=liqIdRet;

         -- siac_r_liquidazione_stato
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_liquidazione_stato.';
         delete from siac_r_liquidazione_stato    where liq_id=liqIdRet;

         -- siac_t_liquidazione
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_t_liquidazione.';
         delete from siac_t_liquidazione    where liq_id=liqIdRet;



        /*strMessaggio:=strMessaggioTemp||
                     ' Non Effettuato. Aggiornamento fase_bil_t_gest_apertura_liq per scarto.';*/
	    strMessaggioTemp:=strMessaggio;
        strMessaggio:=strMessaggio||
                      'Aggiornamento fase_bil_t_gest_apertura_liq per scarto.';
      	update fase_bil_t_gest_apertura_liq fase
        set fl_elab='X',
            scarto_code='LIQ2',
            scarto_desc='Liquidazione residua non inserita.'||strMessaggioTemp
        where fase.fase_bil_gest_ape_liq_id=movGestRec.fase_bil_gest_ape_liq_id
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.liq_orig_id=movGestRec.liq_orig_id
        and   fase.fl_elab='N'
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null;

		continue;
       end if;

       if codResult is null then
	        strMessaggio:='Movimento liq_orig_id='||movGestRec.liq_orig_id||
                      ' movGestTsTipo='||movGestRec.movgest_ts_tipo||
                      ' elem_orig_id='||movGestRec.elem_orig_id||
                      ' elem_id='||movGestRec.elem_id||
                      ' movgest_id='||movGestRec.movgest_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_id||'. Cancellazione relazioni liquidazione su gestione prec. [siac_r_subdoc_liquidazione].';
            -- 12.01.2017 Sofia sistemazione subdoc per quote pagate
	        update siac_r_subdoc_liquidazione r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.liq_id=movGestRec.liq_orig_id
            and   not exists (select 1
                               from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                    siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
			                   where rord.subdoc_id=r.subdoc_id
		        		        and  tsord.ord_ts_id=rord.ord_ts_id
				                and  ord.ord_id=tsord.ord_id
				                and  ord.bil_id=bilancioPrecId
		    	        	    and  rstato.ord_id=ord.ord_id
		        	        	and  stato.ord_stato_id=rstato.ord_stato_id
			        	        and  stato.ord_stato_code!='A'
			            	    and  rord.data_cancellazione is null
			                	and  rord.validita_fine is null
			    	            and  rstato.data_cancellazione is null
			        	        and  rstato.validita_fine is null
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

	        select 1 into codResult
    	    from siac_r_subdoc_liquidazione r
        	where r.liq_id=movGestRec.liq_orig_id
            and   not exists (select 1
                               from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                    siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
			                   where rord.subdoc_id=r.subdoc_id
		        		        and  tsord.ord_ts_id=rord.ord_ts_id
				                and  ord.ord_id=tsord.ord_id
				                and  ord.bil_id=bilancioPrecId
		    	        	    and  rstato.ord_id=ord.ord_id
		        	        	and  stato.ord_stato_id=rstato.ord_stato_id
			        	        and  stato.ord_stato_code!='A'
			            	    and  rord.data_cancellazione is null
			                	and  rord.validita_fine is null
			    	            and  rstato.data_cancellazione is null
			        	        and  rstato.validita_fine is null
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

	  strMessaggio:='Movimento liq_orig_id='||movGestRec.liq_orig_id||
                      ' movGestTsTipo='||movGestRec.movgest_ts_tipo||
                      ' elem_orig_id='||movGestRec.elem_orig_id||
                      ' elem_id='||movGestRec.elem_id||
                      ' movgest_id='||movGestRec.movgest_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_id||'. Aggiornamento fase_bil_t_gest_apertura_liq per fine elaborazione.';
      	update fase_bil_t_gest_apertura_liq fase
        set fl_elab='S',
            liq_id=liqIdRet
        where fase.fase_bil_gest_ape_liq_id=movGestRec.fase_bil_gest_ape_liq_id
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.liq_orig_id=movGestRec.liq_orig_id
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

	 strMessaggio:='Cancellazione logica liq provv anno precedente';
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

     update siac_t_liquidazione liq
     set data_cancellazione=now(),
         login_operazione=liq.login_operazione||'-'||loginOperazione
     from fase_bil_t_gest_apertura_liq fase,
          siac_r_liquidazione_stato rs, siac_d_liquidazione_stato stato
     where fase.fase_bil_elab_id=faseBilElabId
     and liq.liq_id=fase.liq_orig_id
     and rs.liq_id=liq.liq_id
     and stato.liq_stato_id=rs.liq_stato_id
     and stato.liq_stato_code='P'
     and rs.data_cancellazione is null
     and rs.validita_fine is null
     and fase.fl_elab = 'S'
     and fase.liq_id is not null;

     strMessaggio:='Aggiornamento stato fase bilancio IN-3.';
     update fase_bil_t_elaborazione
     set fase_bil_elab_esito='IN-3',
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_LIQ_RES||' IN CORSO IN-3.Elabora Liq.'
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
$function$

