/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_allinea_res_liq
(
  annobilancio           integer,
  enteproprietarioid     integer,
  loginoperazione        varchar,
  dataelaborazione       timestamp,
  out faseBilElabIdRet   integer,
  out codicerisultato    integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

    strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;
    faseBilElabId     integer:=null;

    strRec record;

    APE_GEST_LIQ_RES  CONSTANT varchar:='APE_GEST_LIQ_RES';

	totaleResAggiornato numeric:=0;
    totaleResCalcolato numeric:=0;
BEGIN


	messaggioRisultato:='';
    codiceRisultato:=0;
    faseBilElabIdRet:=0;


	strMessaggioFinale:='Apertura bilancio gestione per Anno bilancio='||annoBilancio::varchar||
                        '. Allineamento liquidazioni residui.';



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
	/*strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
     fase_bil_elab_tipo_id,
     ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_IMP_RES||' IN CORSO.',
            tipo.fase_bil_elab_tipo_id,enteProprietarioId, clock_timestamp(), loginOperazione
     from fase_bil_d_elaborazione_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.fase_bil_elab_tipo_code=APE_GEST_IMP_RES
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null)
     returning fase_bil_elab_id into faseBilElabId;

     if faseBilElabId is null then
     	raise exception ' Inserimento non effettuato.';
     end if;*/


    /*strMessaggio:='Inserimento LOG.';
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
    end if;*/



    strmessaggio:='Calcola liquidazioni residui.';
    select * into strRec
	from fnc_fasi_bil_gest_apertura_liq_popola
	(
	  enteproprietarioid,
      annobilancio,
	  null,
	  loginoperazione,
 	  dataelaborazione
	);
    if strRec.codiceRisultato=0 then
    	faseBilElabId:=strRec.faseBilElabRetId;
    else
        strMessaggio:=strRec.messaggioRisultato;
        codiceRisultato:=strRec.codiceRisultato;
    end if;

	if codiceRisultato=0 then
	    strMessaggio:='Allineamento liquidazioni residui : aggiornamento fase_bil_t_gest_apertura_liq per scarti LIQ1-LIQ3.';
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
	    and   fase.fl_elab='N'
    	and   not exists (select 1
                       from siac_t_movgest mov, siac_t_movgest_ts ts,
                            siac_t_movgest movprec, siac_t_movgest_ts tsprec,
                            siac_v_bko_anno_bilancio anno
    			       where movprec.movgest_id=fase.movgest_orig_id
                       and   tsprec.movgest_ts_id=fase.movgest_orig_ts_id
                       and   tsprec.movgest_id=movprec.movgest_id
                       and   mov.bil_id=anno.bil_id
                       and   anno.anno_bilancio=annoBilancio
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

  	    strMessaggio:='Allineamento liquidazioni residui : aggiornamento fase_bil_t_gest_apertura_liq per scarti LIQ3.';

    	update fase_bil_t_gest_apertura_liq fase
     	set   fl_elab='X',
           scarto_code='LIQ3',
           scarto_desc='Liquidazione provvisoria senza documenti.'
	    where fase.fase_bil_elab_id=faseBilElabId
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

    end if;


    if codiceRisultato=0 then

     strMessaggio:='Allineamento liquidazioni residui : importo_res diverso da attuale.Allinea attuale.';
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
	 set    liq_importo=QUERY.importo_res,
     	    data_modifica=clock_timestamp(),
       	    login_operazione=liq.login_operazione||'-'||loginOperazione||'-ALLINEA-ATT-'||faseBilElabId::varchar
	 from
	 (
	  with
	  liq2017 as
	  (
	   select liq.liq_anno::integer   anno_liq,
       		  liq.liq_numero::integer numero_liq,
--	          liq.liq_importo         importo_res,
--              SIAC-7364 28.01.2020 Sofia
	          fase.liq_importo         importo_res,
	          fase.fl_elab
	   from fase_bil_t_gest_apertura_liq fase, siac_t_liquidazione liq
	   where fase.fase_bil_elab_id=faseBilElabId
	   and   liq.liq_id=fase.liq_orig_id
	   and   liq.data_cancellazione is null
	   and   fase.fl_elab!='X'
	  ),
	  liq2018 as
	  (
	   select liq.liq_anno::integer anno_liq, liq.liq_numero::integer numero_liq,
	          liq.liq_importo,liq.liq_id
	   from siac_t_liquidazione liq, siac_r_liquidazione_stato rs, siac_d_liquidazione_stato stato,
	        siac_v_bko_anno_bilancio anno
	   where anno.ente_proprietario_id=enteProprietarioId
	   and   anno.anno_bilancio=annoBilancio
	   and   liq.bil_id=anno.bil_id
	   and   liq.liq_anno::integer<anno.anno_bilancio
	   and   rs.liq_id=liq.liq_id
	   and   stato.liq_stato_id=rs.liq_stato_id
	   and   stato.liq_stato_code!='A'
	   and   rs.data_cancellazione is null
	   and   rs.validita_fine is null
	   and   liq.data_cancellazione is  null
	  )
	  SELECT liq2017.anno_liq, liq2017.numero_liq,
	         liq2017.importo_res,
	         liq2018.anno_liq, liq2018.numero_liq,
	         liq2018.liq_importo,
	         liq2017.fl_elab,
	         liq2018.liq_id liq_id_2018
	  from liq2017, liq2018
	  where liq2017.anno_liq=liq2018.anno_liq
	  and   liq2017.numero_liq=liq2018.numero_liq
	  and   liq2017.importo_res!=liq2018.liq_importo
	  order by 1,2,3,4
	 )
	 QUERY
	 where liq.ente_proprietario_id=enteProprietarioId
	 and   liq.liq_id=QUERY.liq_id_2018;


     strMessaggio:='Allineamento liquidazioni residui : inserimento nuovi residui.Aggiorna fase_bil_t_gest_apertura_liq.';
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
	 set    fl_elab='W'
	 where  fase.fase_bil_elab_id=faseBilElabId
	 and    fase.fl_elab!='X'
	 and not exists
	 (
	  with
	  liq2017 as
	  (
	   select liq.liq_anno::integer   anno_liq,
       		  liq.liq_numero::integer numero_liq,
	          liq.liq_importo         importo_res,
	          fase.fl_elab,
	          fase.fase_bil_gest_ape_liq_id
	  from fase_bil_t_gest_apertura_liq fase, siac_t_liquidazione liq
	  where fase.fase_bil_elab_id=faseBilElabId
      and   liq.liq_id=fase.liq_orig_id
	  and   liq.data_cancellazione is null
	  and   fase.fl_elab!='X'
	 ),
	 liq2018 as
	 (
	 select liq.liq_anno::integer anno_liq, liq.liq_numero::integer numero_liq,
	        liq.liq_importo
	 from siac_t_liquidazione liq, siac_r_liquidazione_stato rs, siac_d_liquidazione_stato stato,
	      siac_v_bko_anno_bilancio anno
	 where anno.ente_proprietario_id=enteProprietarioId
	 and   anno.anno_bilancio=annoBilancio
	 and   liq.bil_id=anno.bil_id
	 and   liq.liq_anno::integer<anno.anno_bilancio
	 and   rs.liq_id=liq.liq_id
	 and   stato.liq_stato_id=rs.liq_stato_id
	 and   stato.liq_stato_code!='A'
	 and   rs.data_cancellazione is null
	 and   rs.validita_fine is null
	 and   liq.data_cancellazione is  null
	)
	SELECT liq2017.anno_liq, liq2017.numero_liq,
    	   liq2017.importo_res,
	       liq2018.anno_liq, liq2018.numero_liq,
	       liq2018.liq_importo,
	       liq2017.fl_elab,
	       liq2017.fase_bil_gest_ape_liq_id
	from liq2017
	     left join liq2018 on
	     (liq2017.anno_liq=liq2018.anno_liq
	and   liq2017.numero_liq=liq2018.numero_liq)
	where liq2018.anno_liq is null
	and   liq2017.fase_bil_gest_ape_liq_id=fase.fase_bil_gest_ape_liq_id
	order by 1,2,3,4
	);

	 codResult:=null;
	 select count(*) into codResult
     from  fase_bil_t_gest_apertura_liq fase
	 where fase.fase_bil_elab_id=faseBilElabId
     and   fase.fl_elab='N';
     if coalesce(codResult)!=0 then

	  strMessaggio:='Allineamento liquidazioni residui : inserimento nuovi residui.Esecuzione fnc_fasi_bil_gest_apertura_liq_elabora_imp.';
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

      strMessaggio:='Crea impegni nuovi residui.';
   	  select * into strRec
      from fnc_fasi_bil_gest_apertura_liq_elabora_liq
	  (
	   enteProprietarioId,
       annoBilancio,
	   faseBilElabId,
	   0,--minId,
	   0,--maxId
	   loginOperazione,
	   dataElaborazione
	  );
      if strRec.codiceRisultato!=0 then
	  	strMessaggio:=strRec.messaggioRisultato;
    	codiceRisultato:=strRec.codiceRisultato;
      end if;
     end if;

    end if;


    strMessaggio:='Aggiornamento stato fase bilancio OK.';
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

    if codiceRisultato=0 then

        update fase_bil_t_elaborazione
        set fase_bil_elab_esito='OK',
            fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_LIQ_RES||'TERMINATA CON SUCCESSO.',
            validita_fine=clock_timestamp()
        where fase_bil_elab_id=faseBilElabId;

    else
       update fase_bil_t_elaborazione
       set fase_bil_elab_esito='KO',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_LIQ_RES||'TERMINATA CON ERRORE.',
           validita_fine=clock_timestamp()
       where fase_bil_elab_id=faseBilElabId;
	end if;

	strMessaggio:='Inserimento LOG.';
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

    if codiceRisultato=0 then
    	messaggioRisultato:=strMessaggioFinale||' Elaborazione terminata con successo.';
        faseBilElabIdRet:=faseBilElabId;
    else messaggioRisultato:=strMessaggioFinale||strMessaggio;
    end if;

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