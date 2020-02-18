/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_programmi_popola (
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

   if tipoApertura=P_FASE THEN
   	bilancioElabId:=bilancioPrecId;
    programmaTipoCode=G_FASE;
   else
   	bilancioElabId:=bilancioId;
    programmaTipoCode=P_FASE;
   end if;

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
    and   rsatto.validita_fine is null;
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


    -- gestione   quelli con impegno collegato ( se non ne ho già ribaltati con prov def )
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

    -- previsione/gestione quelli non annullati ( ultimo cronop aggiornato ) se non ne ho già ribaltato prima
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


   if codiceRisultato=0 then
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
COST 100; u l l 
 
         a n d       c r o n o p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       c r o n o p . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       r a t t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r a t t o . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       r s a t t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r s a t t o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
         G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
 	         n u m e r o C r o n o p : = n u m e r o C r o n o p + c o d R e s u l t ; 
 
         e n d   i f ; 
 
 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   c r o n o - p r o g r a m m i   i n   f a s e _ b i l _ t _ c r o n o p . G e s t i o n e   c o n   p r o v v e d i m e n t o   d e f i n i t i v o .   n u m e r o = ' | | c o d R e s u l t : : v a r c h a r | | ' . ' ; 
 
         c o d R e s u l t : = n u l l ; 
 
         i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
         ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
           v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         v a l u e s 
 
         ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | ' - ' | | s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
         r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
         e n d   i f ; 
 
 
 
 
 
         - -   g e s t i o n e       q u e l l i   c o n   i m p e g n o   c o l l e g a t o   (   s e   n o n   n e   h o   g i �   r i b a l t a t i   c o n   p r o v   d e f   ) 
 
         c o d R e s u l t : = n u l l ; 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   c r o n o - p r o g r a m m i   i n   f a s e _ b i l _ t _ c r o n o p .   G e s t i o n e   c o n   i m p e g n o   c o l l e g a t o . ' ; 
 
         i n s e r t   i n t o   f a s e _ b i l _ t _ c r o n o p 
 
         ( 
 
 	         f a s e _ b i l _ e l a b _ i d , 
 
 	         f a s e _ b i l _ c r o n o p _ a p e _ t i p o , 
 
 	 	 c r o n o p _ i d , 
 
 	 	 p r o g r a m m a _ i d , 
 
 	         b i l _ i d , 
 
                 l o g i n _ o p e r a z i o n e , 
 
       	         e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   f a s e . f a s e _ b i l _ e l a b _ i d , 
 
                       t i p o A p e r t u r a , 
 
                       c r o n o p . c r o n o p _ i d , 
 
                       c r o n o p . p r o g r a m m a _ i d , 
 
                       c r o n o p . b i l _ i d , 
 
                       l o g i n O p e r a z i o n e , 
 
                       c r o n o p . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   f a s e _ b i l _ t _ p r o g r a m m i   f a s e , s i a c _ t _ c r o n o p   c r o n o p , s i a c _ r _ c r o n o p _ s t a t o   r s , s i a c _ d _ c r o n o p _ s t a t o   s t a t o 
 
         w h e r e   f a s e . f a s e _ b i l _ e l a b _ i d = f a s e B i l E l a b I d 
 
         a n d       c r o n o p . p r o g r a m m a _ i d = f a s e . p r o g r a m m a _ i d 
 
         a n d       c r o n o p . b i l _ i d = b i l a n c i o E l a b I d 
 
         a n d       r s . c r o n o p _ i d = c r o n o p . c r o n o p _ i d 
 
         a n d       s t a t o . c r o n o p _ s t a t o _ i d = r s . c r o n o p _ s t a t o _ i d 
 
         a n d       s t a t o . c r o n o p _ s t a t o _ c o d e ! = S T A T O _ A N 
 
         a n d       t i p o A p e r t u r a = g _ f a s e 
 
         a n d       e x i s t s 
 
         ( 
 
         s e l e c t   1 
 
         f r o m   s i a c _ t _ c r o n o p _ e l e m   c e l e m , s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m   r m o v 
 
         w h e r e   c e l e m . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       c e l e m . c r o n o p _ i d = c r o n o p . c r o n o p _ i d 
 
         a n d       r m o v . c r o n o p _ e l e m _ i d = c e l e m . c r o n o p _ e l e m _ i d 
 
         a n d       c e l e m . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       c e l e m . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       r m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r m o v . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) 
 
         a n d       n o t   e x i s t s 
 
         ( 
 
         s e l e c t   1 
 
         f r o m   f a s e _ b i l _ t _ c r o n o p   f a s e 1 
 
         w h e r e   f a s e 1 . f a s e _ b i l _ e l a b _ i d = f a s e B i l E l a b I d 
 
         a n d       f a s e 1 . c r o n o p _ i d = c r o n o p . c r o n o p _ i d 
 
         a n d       f a s e 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         ) 
 
         a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       c r o n o p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       c r o n o p . v a l i d i t a _ f i n e   i s   n u l l ; 
 
         G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
 	         n u m e r o C r o n o p : = n u m e r o C r o n o p + c o d R e s u l t ; 
 
         e n d   i f ; 
 
 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   c r o n o - p r o g r a m m i   i n   f a s e _ b i l _ t _ c r o n o p . G e s t i o n e   c o n   i m p e g n o   c o l l e g a t o .   n u m e r o = ' | | c o d R e s u l t : : v a r c h a r | | ' . ' ; 
 
         c o d R e s u l t : = n u l l ; 
 
         i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
         ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
           v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         v a l u e s 
 
         ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | ' - ' | | s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
         r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
         e n d   i f ; 
 
 
 
         - -   p r e v i s i o n e / g e s t i o n e   q u e l l i   n o n   a n n u l l a t i   (   u l t i m o   c r o n o p   a g g i o r n a t o   )   s e   n o n   n e   h o   g i �   r i b a l t a t o   p r i m a 
 
 	 c o d R e s u l t : = n u l l ; 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   c r o n o - p r o g r a m m i   i n   f a s e _ b i l _ t _ c r o n o p .   U l t i m o   c r o n o p   a g g i o r n a t o . ' ; 
 
         i n s e r t   i n t o   f a s e _ b i l _ t _ c r o n o p 
 
         ( 
 
 	         f a s e _ b i l _ e l a b _ i d , 
 
 	         f a s e _ b i l _ c r o n o p _ a p e _ t i p o , 
 
 	 	 c r o n o p _ i d , 
 
 	 	 p r o g r a m m a _ i d , 
 
 	         b i l _ i d , 
 
                 l o g i n _ o p e r a z i o n e , 
 
       	         e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   f a s e . f a s e _ b i l _ e l a b _ i d , 
 
                       t i p o A p e r t u r a , 
 
                       c r o n o p . c r o n o p _ i d , 
 
                       c r o n o p . p r o g r a m m a _ i d , 
 
                       c r o n o p . b i l _ i d , 
 
                       l o g i n O p e r a z i o n e , 
 
                       c r o n o p . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   f a s e _ b i l _ t _ p r o g r a m m i   f a s e , s i a c _ t _ c r o n o p   c r o n o p , s i a c _ r _ c r o n o p _ s t a t o   r s , s i a c _ d _ c r o n o p _ s t a t o   s t a t o 
 
         w h e r e   f a s e . f a s e _ b i l _ e l a b _ i d = f a s e B i l E l a b I d 
 
         a n d       c r o n o p . p r o g r a m m a _ i d = f a s e . p r o g r a m m a _ i d 
 
         a n d       c r o n o p . b i l _ i d = b i l a n c i o E l a b I d 
 
         a n d       r s . c r o n o p _ i d = c r o n o p . c r o n o p _ i d 
 
         a n d       s t a t o . c r o n o p _ s t a t o _ i d = r s . c r o n o p _ s t a t o _ i d 
 
         a n d       s t a t o . c r o n o p _ s t a t o _ c o d e ! = S T A T O _ A N 
 
         a n d       n o t   e x i s t s 
 
         ( 
 
         s e l e c t   1 
 
         f r o m   f a s e _ b i l _ t _ c r o n o p   f a s e 1 
 
         w h e r e   f a s e 1 . f a s e _ b i l _ e l a b _ i d = f a s e B i l E l a b I d 
 
         a n d       f a s e 1 . c r o n o p _ i d = c r o n o p . c r o n o p _ i d 
 
         a n d       f a s e 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         ) 
 
         a n d       e x i s t s 
 
 	 ( 
 
             s e l e c t   1 
 
             f r o m   s i a c _ t _ c r o n o p   c 1 
 
             w h e r e   c 1 . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
             a n d       c 1 . c r o n o p _ i d = c r o n o p . c r o n o p _ i d 
 
             a n d       c 1 . d a t a _ m o d i f i c a = 
 
             ( 
 
                 s e l e c t   m a x ( c m a x . d a t a _ m o d i f i c a ) 
 
                 f r o m   s i a c _ t _ c r o n o p   c m a x , s i a c _ r _ c r o n o p _ s t a t o   r s m a x , s i a c _ d _ c r o n o p _ s t a t o   s t m a x 
 
                 w h e r e   c m a x . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                 a n d       c m a x . p r o g r a m m a _ i d = c 1 . p r o g r a m m a _ i d 
 
                 a n d       c m a x . b i l _ i d = c 1 . b i l _ i d 
 
                 a n d       r s m a x . c r o n o p _ i d = c m a x . c r o n o p _ i d 
 
                 a n d       s t m a x . c r o n o p _ s t a t o _ i d = r s m a x . c r o n o p _ s t a t o _ i d 
 
                 a n d       s t m a x . c r o n o p _ s t a t o _ c o d e ! = S T A T O _ A N 
 
                 a n d       c m a x . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       c m a x . v a l i d i t a _ f i n e   i s   n u l l 
 
                 a n d       r s m a x . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       r s m a x . v a l i d i t a _ f i n e   i s   n u l l 
 
             ) 
 
             a n d       c 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	     a n d       c 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) 
 
         a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       c r o n o p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       c r o n o p . v a l i d i t a _ f i n e   i s   n u l l ; 
 
         G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
 	         n u m e r o C r o n o p : = n u m e r o C r o n o p + c o d R e s u l t ; 
 
         e n d   i f ; 
 
 
 
 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   c r o n o - p r o g r a m m i   i n   f a s e _ b i l _ t _ c r o n o p . U l t i m o   c r o n o p   a g g i o r n a t o .   n u m e r o = ' | | c o d R e s u l t : : v a r c h a r | | ' . ' ; 
 
         c o d R e s u l t : = n u l l ; 
 
         i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
         ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
           v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         v a l u e s 
 
         ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | ' - ' | | s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
         r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
         e n d   i f ; 
 
 
 
 
 
 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   c r o n o - p r o g r a m m i   i n   f a s e _ b i l _ t _ c r o n o p   n u m e r o = ' | | n u m e r o C r o n o p : : v a r c h a r | | ' . ' ; 
 
         c o d R e s u l t : = n u l l ; 
 
         i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
         ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
           v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         v a l u e s 
 
         ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | ' - ' | | s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
         r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
         e n d   i f ; 
 
       e n d   i f ; 
 
       r a i s e   n o t i c e   ' P r o g r a m m m i   i n s e r i t i   i n   f a s e _ b i l _ t _ p r o g r a m m i = % ' , n u m e r o P r o g r ; 
 
       r a i s e   n o t i c e   ' C r o n o P r o g r a m m m i   i n s e r i t i   i n   f a s e _ b i l _ t _ c r o n o p = % ' , n u m e r o C r o n o p ; 
 
 
 
 
 
       s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   s t a t o   f a s e   b i l a n c i o   I N - 1 . ' ; 
 
       u p d a t e   f a s e _ b i l _ t _ e l a b o r a z i o n e   f a s e 
 
       s e t   f a s e _ b i l _ e l a b _ e s i t o = ' I N - 1 ' , 
 
               f a s e _ b i l _ e l a b _ e s i t o _ m s g = ' E L A B O R A Z I O N E   F A S E   B I L A N C I O   ' | | A P E _ G E S T _ P R O G R A M M I | | '   I N   C O R S O   I N - 1 . P O P O L A   P R O G R A M M I - C R O N O P . ' 
 
       w h e r e   f a s e . f a s e _ b i l _ e l a b _ i d = f a s e B i l E l a b I d ; 
 
 
 
 
 
       s t r M e s s a g g i o : = ' I n s e r i m e n t o   L O G . ' ; 
 
       c o d R e s u l t : = n u l l ; 
 
       i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
       ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
             v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
       ) 
 
       v a l u e s 
 
       ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | ' - F I N E . ' , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
       r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
       i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
       e n d   i f ; 
 
 
 
 
 
       i f   c o d i c e R i s u l t a t o = 0   t h e n 
 
         	 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | ' -   F I N E . ' ; 
 
       e l s e   m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o ; 
 
       e n d   i f ; 
 
 
 
       r e t u r n ; 
 
 
 
 e x c e p t i o n 
 
         w h e n   R A I S E _ E X C E P T I O N   T H E N 
 
         	 r a i s e   n o t i c e   ' %   %   E R R O R E   :   % ' , s t r M e s s a g g i o F i n a l e , s t r M e s s a g g i o , 
 
 	                 	 s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   1 5 0 0 ) ; 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o | | ' E R R O R E   : ' | | '   ' | | s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   1 0 0 0 )   ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 r e t u r n ; 
 
 
 
 	 w h e n   n o _ d a t a _ f o u n d   T H E N 
 
 	 	 r a i s e   n o t i c e   '   %   %   N e s s u n   e l e m e n t o   t r o v a t o . '   , s t r M e s s a g g i o F i n a l e , s t r M e s s a g g i o ; 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o | | ' N e s s u n   e l e m e n t o   t r o v a t o . '   ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
 	 	 r e t u r n ; 
 
 	 w h e n   o t h e r s     T H E N 
 
 	 	 r a i s e   n o t i c e   ' %   %   E r r o r e   D B   %   % ' , s t r M e s s a g g i o F i n a l e , s t r M e s s a g g i o , S Q L S T A T E , 
 
 	                 	 s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   1 5 0 0 ) ; 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o | | ' E r r o r e   D B   ' | | S Q L S T A T E | | '   ' | | s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   1 0 0 0 )   ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 r e t u r n ; 
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