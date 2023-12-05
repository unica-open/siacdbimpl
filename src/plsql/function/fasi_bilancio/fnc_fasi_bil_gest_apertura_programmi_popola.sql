/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION IF EXISTS siac.fnc_fasi_bil_gest_apertura_programmi_popola 
(
  fasebilelabid integer,
  enteproprietarioid integer,
  annobilancio integer,
  tipoapertura varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_programmi_popola (
  fasebilelabid integer,
  enteproprietarioid integer,
  annobilancio integer,
  tipoapertura varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;


    bilancioElabId                   integer:=null;

    APE_GEST_PROGRAMMI    	    	 CONSTANT varchar:='APE_GEST_PROGRAMMI';

    P_FASE							 CONSTANT varchar:='P';
    G_FASE					    	 CONSTANT varchar:='G';
    --- Sofia SIAC-8633 24.05.2023       
    GP_FASE                        CONSTANT varchar:='GP';  

	STATO_AN 			    	     CONSTANT varchar:='AN';
    numeroProgr                      integer:=null;
    numeroCronop					 integer:=0;
    programmaTipoCode                varchar(10):=null;
BEGIN

   codiceRisultato:=null;
   messaggioRisultato:=null;

   dataInizioVal:= clock_timestamp();


   strmessaggiofinale:='Apertura Programmi-Cronoprogrammi di tipo '||tipoApertura||' per annoBilancio='||annoBilancio::varchar||'. Popolamento.';

   strMessaggio:='Inserimento LOG.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
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


   strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
   select bil.bil_id , per.periodo_id into strict bilancioPrecId, periodoPrecId
   from siac_t_bil bil, siac_t_periodo per
   where bil.ente_proprietario_id=enteProprietarioId
   and   per.periodo_id=bil.periodo_id
   and   per.anno::INTEGER=annoBilancio-1
   and   bil.data_cancellazione is null
   and   per.data_cancellazione is null;

   --siac_t_programma
   --siac_r_programma_stato
   --siac_r_programma_class
   --siac_r_programma_attr
   --siac_r_programma_atto_amm
   --siac_r_movgest_ts_programma
   --siac_t_cronop
   --siac_r_cronop_stato
   --siac_r_cronop_attr
   --siac_t_cronop_elem
   --siac_r_cronop_elem_class
   --siac_r_cronop_elem_bil_elem
   --siac_t_cronop_elem_det

 /*  if tipoApertura=P_FASE then
 
   	bilancioElabId:=bilancioPrecId;
    programmaTipoCode=G_FASE;
   else
   	bilancioElabId:=bilancioId;
    programmaTipoCode=P_FASE;
   end if; Sofia SIAC-8633 24.05.2023         */

  -- Sofia SIAC-8633 24.05.2023         
  case  
   when tipoApertura=P_FASE then
	   	bilancioElabId:=bilancioPrecId;
    	programmaTipoCode=G_FASE;
   when tipoApertura=G_FASE then
	   bilancioElabId:=bilancioId;
       programmaTipoCode=P_FASE;
   when tipoApertura=GP_FASE then   
       bilancioElabId:=bilancioId;
       programmaTipoCode=G_FASE;
       tipoApertura=P_FASE;
  end case ;
 
   strMessaggio:='Inserimento dati programmi in fase_bil_t_programmi.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;


   insert into fase_bil_t_programmi
   (
   	fase_bil_elab_id,
	fase_bil_programma_ape_tipo,
	programma_id,
	programma_tipo_id,
	bil_id,
    login_operazione,
    ente_proprietario_id
   )
   select faseBilElabId,
          tipoApertura,
          prog.programma_id,
          tipo.programma_tipo_id,
          prog.bil_id,
          loginOperazione,
          prog.ente_proprietario_id
   from siac_t_programma prog,siac_d_programma_tipo tipo,
	    siac_r_programma_stato rs,siac_d_programma_stato stato
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.programma_tipo_code=programmaTipoCode
   and   prog.programma_tipo_id=tipo.programma_tipo_id
   and   prog.bil_id=bilancioElabId
   and   rs.programma_id=prog.programma_id
   and   stato.programma_stato_id=rs.programma_stato_id
   and   stato.programma_stato_code!=STATO_AN
   and   prog.data_cancellazione is null
   and   prog.validita_fine is null
   and   rs.data_cancellazione is null
   and   rs.validita_fine is null;
   GET DIAGNOSTICS numeroProgr = ROW_COUNT;

   strMessaggio:='Inserimento dati programmi in fase_bil_t_programmi numero='||numeroProgr::varchar||'.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;

   if coalesce(numeroProgr)!=0 then
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.';
    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||' '||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    codResult:=null;
    -- modificare qui in base a indicazioni di Floriana con n-insert diverse
    -- previsione quelli con usato_per_fpv=true
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop. Previsione scelti come FPV.';
    insert into fase_bil_t_cronop
    (
	    fase_bil_elab_id,
	    fase_bil_cronop_ape_tipo,
		cronop_id,
		programma_id,
	    bil_id,
        login_operazione,
   	    ente_proprietario_id
    )
    select fase.fase_bil_elab_id,
           tipoApertura,
           cronop.cronop_id,
           cronop.programma_id,
           cronop.bil_id,
           loginOperazione,
           cronop.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato
    where fase.fase_bil_elab_id=faseBilElabId
    and   cronop.programma_id=fase.programma_id
    and   cronop.bil_id=bilancioElabId
    and   cronop.usato_per_fpv=true
    and   rs.cronop_id=cronop.cronop_id
    and   stato.cronop_stato_id=rs.cronop_stato_id
    and   stato.cronop_stato_code!=STATO_AN
    and   tipoApertura=p_fase
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is not null then
	    numeroCronop:=numeroCronop+codResult;
    end if;

    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.Previsione scelti come FPV. numero='||codResult::varchar||'.';
    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    -- gestione   quelli con prov definitivo
    codResult:=null;
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop. Gestione con provvedimento definitivo.';
    insert into fase_bil_t_cronop
    (
	    fase_bil_elab_id,
	    fase_bil_cronop_ape_tipo,
		cronop_id,
		programma_id,
	    bil_id,
        login_operazione,
   	    ente_proprietario_id
    )
    select fase.fase_bil_elab_id,
           tipoApertura,
           cronop.cronop_id,
           cronop.programma_id,
           cronop.bil_id,
           loginOperazione,
           cronop.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
         siac_r_cronop_atto_amm ratto,siac_r_atto_amm_stato rsatto,siac_d_atto_amm_stato statoatto
    where fase.fase_bil_elab_id=faseBilElabId
    and   cronop.programma_id=fase.programma_id
    and   cronop.bil_id=bilancioElabId
    and   rs.cronop_id=cronop.cronop_id
    and   stato.cronop_stato_id=rs.cronop_stato_id
    and   stato.cronop_stato_code!=STATO_AN
    and   ratto.cronop_id=cronop.cronop_id
    and   rsatto.attoamm_id=ratto.attoamm_id
    and   statoatto.attoamm_stato_id=rsatto.attoamm_stato_id
    and   statoatto.attoamm_stato_code='DEFINITIVO'
    and   tipoApertura=g_fase
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null
    and   ratto.data_cancellazione is null
    and   ratto.validita_fine is null
    and   rsatto.data_cancellazione is null
    and   rsatto.validita_fine is null
    and   not exists -- 17.05.2023 Sofia SIAC-8633
    (
    select 1
    from fase_bil_t_cronop fase1
    where fase1.fase_bil_elab_id=faseBilElabId
    and   fase1.cronop_id=cronop.cronop_id
    and   fase1.data_cancellazione is null
    );
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is not null then
	    numeroCronop:=numeroCronop+codResult;
    end if;

    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.Gestione con provvedimento definitivo. numero='||codResult::varchar||'.';
    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;


    -- gestione   quelli con impegno collegato ( se non ne ho gia ribaltati con prov def )
    codResult:=null;
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop. Gestione con impegno collegato.';
    insert into fase_bil_t_cronop
    (
	    fase_bil_elab_id,
	    fase_bil_cronop_ape_tipo,
		cronop_id,
		programma_id,
	    bil_id,
        login_operazione,
   	    ente_proprietario_id
    )
    select fase.fase_bil_elab_id,
           tipoApertura,
           cronop.cronop_id,
           cronop.programma_id,
           cronop.bil_id,
           loginOperazione,
           cronop.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato
    where fase.fase_bil_elab_id=faseBilElabId
    and   cronop.programma_id=fase.programma_id
    and   cronop.bil_id=bilancioElabId
    and   rs.cronop_id=cronop.cronop_id
    and   stato.cronop_stato_id=rs.cronop_stato_id
    and   stato.cronop_stato_code!=STATO_AN
    and   tipoApertura=g_fase
    and   exists
    (
    select 1
    from siac_t_cronop_elem celem,siac_r_movgest_ts_cronop_elem rmov
    where celem.ente_proprietario_id=enteProprietarioId
    and   celem.cronop_id=cronop.cronop_id
    and   rmov.cronop_elem_id=celem.cronop_elem_id
    and   celem.data_cancellazione is null
    and   celem.validita_fine is null
    and   rmov.data_cancellazione is null
    and   rmov.validita_fine is null
    )
    and   not exists
    (
    select 1
    from fase_bil_t_cronop fase1
    where fase1.fase_bil_elab_id=faseBilElabId
    and   fase1.cronop_id=cronop.cronop_id
    and   fase1.data_cancellazione is null
    )
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is not null then
	    numeroCronop:=numeroCronop+codResult;
    end if;

    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.Gestione con impegno collegato. numero='||codResult::varchar||'.';
    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    -- previsione/gestione quelli non annullati ( ultimo cronop aggiornato ) se non ne ho gia ribaltato prima
	codResult:=null;
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop. Ultimo cronop aggiornato.';
    insert into fase_bil_t_cronop
    (
	    fase_bil_elab_id,
	    fase_bil_cronop_ape_tipo,
		cronop_id,
		programma_id,
	    bil_id,
        login_operazione,
   	    ente_proprietario_id
    )
    select fase.fase_bil_elab_id,
           tipoApertura,
           cronop.cronop_id,
           cronop.programma_id,
           cronop.bil_id,
           loginOperazione,
           cronop.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato
    where fase.fase_bil_elab_id=faseBilElabId
    and   cronop.programma_id=fase.programma_id
    and   cronop.bil_id=bilancioElabId
    and   rs.cronop_id=cronop.cronop_id
    and   stato.cronop_stato_id=rs.cronop_stato_id
    and   stato.cronop_stato_code!=STATO_AN
    and   not exists
    (
    select 1
    from fase_bil_t_cronop fase1
    where fase1.fase_bil_elab_id=faseBilElabId
    and   fase1.cronop_id=cronop.cronop_id
    and   fase1.data_cancellazione is null
    )
    and   exists
	(
      select 1
      from siac_t_cronop c1
      where c1.ente_proprietario_id=enteProprietarioId
      and   c1.cronop_id=cronop.cronop_id
      and   c1.data_modifica=
      (
        select max(cmax.data_modifica)
        from siac_t_cronop cmax,siac_r_cronop_stato rsmax,siac_d_cronop_stato stmax
        where cmax.ente_proprietario_id=enteProprietarioId
        and   cmax.programma_id=c1.programma_id
        and   cmax.bil_id=c1.bil_id
        and   rsmax.cronop_id=cmax.cronop_id
        and   stmax.cronop_stato_id=rsmax.cronop_stato_id
        and   stmax.cronop_stato_code!=STATO_AN
        and   cmax.data_cancellazione is null
        and   cmax.validita_fine is null
        and   rsmax.data_cancellazione is null
        and   rsmax.validita_fine is null
      )
      and   c1.data_cancellazione is null
	  and   c1.validita_fine is null
    )
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is not null then
	    numeroCronop:=numeroCronop+codResult;
    end if;


    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.Ultimo cronop aggiornato. numero='||codResult::varchar||'.';
    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;



    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop numero='||numeroCronop::varchar||'.';
    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;
   end if;
   raise notice 'Programmmi inseriti in fase_bil_t_programmi=%',numeroProgr;
   raise notice 'CronoProgrammmi inseriti in fase_bil_t_cronop=%',numeroCronop;


   strMessaggio:='Aggiornamento stato fase bilancio IN-1.';
   update fase_bil_t_elaborazione fase
   set fase_bil_elab_esito='IN-1',
       fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' IN CORSO IN-1.POPOLA PROGRAMMI-CRONOP.'
   where fase.fase_bil_elab_id=faseBilElabId;


   strMessaggio:='Inserimento LOG.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;


   if coalesce(codiceRisultato,0)=0 then
    	messaggioRisultato:=strMessaggioFinale||'- FINE.';
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

alter FUNCTION  siac.fnc_fasi_bil_gest_apertura_programmi_popola (  integer, integer, integer,  varchar,  varchar,  timestamp, out integer, out  varchar) owner to siac;