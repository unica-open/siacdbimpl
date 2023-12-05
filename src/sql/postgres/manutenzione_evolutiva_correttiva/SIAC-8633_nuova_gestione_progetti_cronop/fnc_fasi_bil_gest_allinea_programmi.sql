/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

/*DROP FUNCTION IF EXISTS siac.fnc_fasi_bil_gest_allinea_programmi 
(
  annobilancio integer,
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabidret integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);*/

DROP FUNCTION IF EXISTS siac.fnc_fasi_bil_gest_allinea_programmi 
(
  annobilancio integer,
  enteproprietarioid integer,
  tipoAllineamento varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabidret integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_allinea_programmi 
(
  annobilancio integer,
  enteproprietarioid integer,
  tipoAllineamento varchar, 
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabidret integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
  DECLARE
   strMessaggio       			VARCHAR(1500)	:='';
   strMessaggioErr       			VARCHAR(1500)	:='';
   strMessaggiofinale 			VARCHAR(1500)	:='';
   codResult              		INTEGER  		:=NULL;
   dataInizioVal 				timestamp		:=NULL;
   faseBilElabId 		        integer:=null;
   faseBilElabPGId          integer:=null;
   faseBilElabGPId          integer:=null;
   bilancioId                   integer:=null;
   periodoId                    integer:=null;
   tipoOperazioni varchar(50):=null;
  
   faseOp                       varchar(50):=null;
   strRec record;

   APE_GEST_PROGRAMMI    	    CONSTANT varchar:='APE_GEST_ALL_PROGRAMMI';
   P_FASE						CONSTANT varchar:='P';
   E_FASE					    CONSTANT varchar:='E';
   
  BEGIN

   messaggioRisultato:='';
   codicerisultato:=0;
   faseBilElabIdRet:=0;
   dataInizioVal:= clock_timestamp();

   strmessaggiofinale:='Allineamento '||coalesce(tipoAllineamento,' ')||' Programmi-Cronoprogrammi per annoBilancio='||annoBilancio::varchar||'.';
   raise notice '%',strmessaggiofinale;
   strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_PROGRAMMI||' IN CORSO.';
   select 1 into codResult
   from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.fase_bil_elab_tipo_code=APE_GEST_PROGRAMMI
   and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
   and   fase.fase_bil_elab_esito like 'IN%'
   and   fase.data_cancellazione is null
   and   fase.validita_fine is null
   and   tipo.data_cancellazione is null
   and   tipo.validita_fine is null;
   if codResult is not null then
   	raise exception ' Esistenza fase in corso.';
   end if;

   -- da g anno-1  a  p anno gp   - PREVISIONE E ES. PROVVISORIO no ribaltamento collegamenti movimenti
   -- da g anno     a  p anno GP   - ES.PROVVISORIO no ribaltamento collegamenti con movimenti 
   -- da p anno     a g anno  PG   - ES. PROVVISORIO  sempre e solo dei mancati con ribaltamento dei collegamenti con movimenti
   --     'gp|GP|PG'
   strMessaggio:='Verifica tipo allineamenti da eseguire per  '||APE_GEST_PROGRAMMI||'.';
   select tipo.fase_bil_elab_tipo_param  into tipoOperazioni
   from fase_bil_d_elaborazione_tipo  tipo 
   where tipo.ente_proprietario_id =enteProprietarioId 
   and      tipo.fase_bil_elab_tipo_code =APE_GEST_PROGRAMMI
   and      tipo.data_cancellazione  is null 
   and      tipo.validita_fine is null;
   if tipoOperazioni is null then 
       messaggioRisultato := strMessaggioFinale||strMessaggio||' Nessun tipo di allineamento predisposto in esecuzione.';
	   return;
   end if;


    
    -- inserimento fase_bil_t_elaborazione
	strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
     fase_bil_elab_tipo_id,
     ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' gp - DA G ANNO-1 P ANNO IN CORSO.',
            tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
     from fase_bil_d_elaborazione_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.fase_bil_elab_tipo_code=APE_GEST_PROGRAMMI
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
     if faseOp is null or faseOp not in (P_FASE,E_FASE) then
      	raise notice ' Il bilancio deve essere in fase % o %.',P_FASE,E_FASE;
	--	strMessaggio:='Allineamento Programmi-Cronoprogrammi gp -  da gestione '||(annoBilancio-1)::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
	    strMessaggio:=strMessaggio||' Il bilancio deve essere in fase '||P_FASE||' o '||E_FASE||'. Chiusura fase_bil_t_elaborazione KO.';
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

       update fase_bil_t_elaborazione
       set fase_bil_elab_esito='KO',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' gp - DA G ANNO-1 A P ANNO TERMINATA CON ERRORE.'||upper (strMessaggio)
       where fase_bil_elab_id=faseBilElabId;
      
       messaggioRisultato := strMessaggioFinale||strMessaggio||' Fase di bilancio non ammessa.';
	   return;
     end if;
    
    -- da g anno-1  a  p anno gp   - PREVISIONE E ES. PROVVISORIO no ribaltamento collegamenti movimenti
    if coalesce(tipoAllineamento,'')='' or tipoAllineamento like '%gp%' then 
	 -- da g anno-1  a  p anno gp   - PREVISIONE E ES. PROVVISORIO no ribaltamento collegamenti movimenti
     strMessaggio:='Allineamento Programmi-Cronoprogrammi gp - da gestione '||(annoBilancio-1)::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
     if tipoOperazioni like '%gp%'  then
      raise notice '%',strmessaggio;
      strMessaggio:=strMessaggio||' Inizio Popola programmi-cronop da elaborare.';
 	
	  select * into strRec
      from fnc_fasi_bil_gest_apertura_programmi_popola
      (
       faseBilElabId,
       enteproprietarioid,
       annobilancio,
       'P',
       loginoperazione,
	   dataelaborazione
      );
      if strRec.codiceRisultato!=0 then
        strMessaggio:=strRec.messaggioRisultato;
        codiceRisultato:=strRec.codiceRisultato;
      end if;
     
      if codiceRisultato = 0 then
          strMessaggio:='Allineamento Programmi-Cronoprogrammi gp - da gestione '||(annoBilancio-1)::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
          strMessaggio:=strMessaggio||' Inizio Elabora programmi-cronop.';
    	 select * into strRec
	     from fnc_fasi_bil_gest_apertura_programmi_elabora
    	 (
	      faseBilElabId,
    	  enteproprietarioid,
	      annobilancio,
          'P',
          loginoperazione,
          dataelaborazione,
          false -- no colleg. movimenti
         );
         if strRec.codiceRisultato!=0 then
            strMessaggioErr:=strRec.messaggioRisultato;
            strMessaggio:=strMessaggioErr;
            codiceRisultato:=strRec.codiceRisultato;
         end if;
      end if;
     end if;
    
      if codiceRisultato=0 and faseBilElabId is not null then
       strMessaggio:='Allineamento Programmi-Cronoprogrammi gp - da gestione '||(annoBilancio-1)::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
	   strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione OK.';
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

       update fase_bil_t_elaborazione
       set fase_bil_elab_esito='OK',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' gp - DA G ANNO-1 a P ANNO TERMINATA CON SUCCESSO.'
       where fase_bil_elab_id=faseBilElabId;

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

	 else
      if codiceRisultato!=0 and faseBilElabId is not null then
       strMessaggio:='Allineamento Programmi-Cronoprogrammi gp - da gestione '||(annoBilancio-1)::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
	   strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione KO.';
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

       update fase_bil_t_elaborazione
       set fase_bil_elab_esito='KO',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' gp - DA G ANNO-1 A P ANNO TERMINATA CON ERRORE.'||upper (strMessaggio)
       where fase_bil_elab_id=faseBilElabId;
      end if;

     end if;
    end if;
   
     -- da g anno   a  p anno GP   - ES.PROVVISORIO no ribaltamento collegamenti con movimenti
     -- da modificare fnc interne tutto nello stesso annoBilancio
    if coalesce(tipoAllineamento,'')='' or tipoAllineamento like '%GP%'  and
        tipoOperazioni like '%GP%' and codiceRisultato=0 and faseOp=E_FASE  then 
        strMessaggio:='Allineamento Programmi-Cronoprogrammi GP - da gestione '||annoBilancio::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
        raise notice '%',strmessaggio;
        strMessaggio:=strMessaggio||' Inserimento fase elaborazione [fase_bil_t_elaborazione].';

       insert into fase_bil_t_elaborazione
        (fase_bil_elab_esito, fase_bil_elab_esito_msg,
         fase_bil_elab_tipo_id,
         ente_proprietario_id,validita_inizio, login_operazione)
        (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' GP - DA G ANNO A P ANNO IN CORSO.',
                     tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
         from fase_bil_d_elaborazione_tipo tipo
         where tipo.ente_proprietario_id=enteProprietarioId
         and   tipo.fase_bil_elab_tipo_code=APE_GEST_PROGRAMMI
         and   tipo.data_cancellazione is null
         and   tipo.validita_fine is null)
         returning fase_bil_elab_id into faseBilElabGPId;

    
        if faseBilElabGPId is null then 
         strMessaggio:=strMessaggio||' Impossibile determinare id.Elab.';
         codiceRisultato:=-1;
        else 
         codResult:=null;
	     insert into fase_bil_t_elaborazione_log
         (fase_bil_elab_id,fase_bil_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
         )
         values
         (faseBilElabGPId,strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
         returning fase_bil_elab_log_id into codResult;
         if codResult is null then
    	   raise exception ' Errore in inserimento LOG.';
         end if;
        
         strMessaggio:='Allineamento Programmi-Cronoprogrammi GP - da gestione '||annoBilancio::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
         strMessaggio:=strMessaggio||' Inizio Popola programmi-cronop da elaborare.'; 
         select * into strRec
         from fnc_fasi_bil_gest_apertura_programmi_popola
         (
           faseBilElabGPId,
           enteproprietarioid,
           annobilancio,
           'GP',
           loginoperazione,
	       dataelaborazione
          );
          if strRec.codiceRisultato!=0 then
            strMessaggio:=strRec.messaggioRisultato;
            codiceRisultato:=strRec.codiceRisultato;
         end if;  
       
         if codiceRisultato = 0 then
           strMessaggio:='Allineamento Programmi-Cronoprogrammi GP - da gestione '||annoBilancio::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
           strMessaggio:=strMessaggio||' Inizio Elabora programmi-cronop.';
    	   select * into strRec
 	       from fnc_fasi_bil_gest_apertura_programmi_elabora
    	   (
	        faseBilElabGPId,
    	    enteproprietarioid,
	        annobilancio,
            'GP',
            loginoperazione,
            dataelaborazione,
            false -- no colleg movimenti
           );
           if strRec.codiceRisultato!=0 then
            strMessaggioErr:=strRec.messaggioRisultato;
            strMessaggio:=strMessaggioErr;
            codiceRisultato:=strRec.codiceRisultato;
           end if;
         end if; 
      end if;
     end if;
    
     if faseBilElabGPId is not null then
      strMessaggio:='Allineamento Programmi-Cronoprogrammi GP - da gestione '||annoBilancio::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
      if codiceRisultato=0 then 
     	   strMessaggio:=strMessaggio||'  Chiusura fase_bil_t_elaborazione OK.';
           insert into fase_bil_t_elaborazione_log
	       (fase_bil_elab_id,fase_bil_elab_log_operazione,
             validita_inizio, login_operazione, ente_proprietario_id
	       )
	       values
           (faseBilElabGPId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	       returning fase_bil_elab_log_id into codResult;

	       if codResult is null then
    	 	   raise exception ' Errore in inserimento LOG.';
    	   end if;

           update fase_bil_t_elaborazione
           set fase_bil_elab_esito='OK',
             fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' GP - DA G ANNO a P ANNO TERMINATA CON SUCCESSO.'
           where fase_bil_elab_id=faseBilElabGPId;

           insert into fase_bil_t_elaborazione_log
     	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
            validita_inizio, login_operazione, ente_proprietario_id
	       )
	       values
          (faseBilElabGPId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	       returning fase_bil_elab_log_id into codResult;

	       if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	       end if;
     else 
	   		strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione KO.';
		    insert into fase_bil_t_elaborazione_log
		    (fase_bil_elab_id,fase_bil_elab_log_operazione,
		        validita_inizio, login_operazione, ente_proprietario_id
	  	   )
		   values
    	   (faseBilElabGPId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
		   returning fase_bil_elab_log_id into codResult;

		   if codResult is null then
    		 	raise exception ' Errore in inserimento LOG.';
		   end if;
	
    	   update fase_bil_t_elaborazione
	       set fase_bil_elab_esito='KO',
    	       fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' GP - DA G ANNO A P ANNO TERMINATA CON ERRORE.'||upper (strMessaggioErr)
       		where fase_bil_elab_id=faseBilElabGPId;
      end if;
     end if;
    
    -- da p anno     a g anno  PG   - ES. PROVVISORIO  sempre e solo dei mancati con ribaltamento dei collegamenti con movimenti
    if coalesce(tipoAllineamento,'')='' or tipoAllineamento like '%PG%' and
        tipoOperazioni like '%PG%'  and codiceRisultato=0 and faseOp=E_FASE then 
        strMessaggio:='Allineamento Programmi-Cronoprogrammi PG - da previsione '||annoBilancio::varchar||' a gestione annoBilancio='||annoBilancio::varchar||'.';
        raise notice '%',strmessaggio;
        strMessaggio:=strMessaggio||' Inserimento fase elaborazione [fase_bil_t_elaborazione].';
       
        insert into fase_bil_t_elaborazione
        (fase_bil_elab_esito, fase_bil_elab_esito_msg,
         fase_bil_elab_tipo_id,
         ente_proprietario_id,validita_inizio, login_operazione)
        (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' PG - DA P ANNO A G ANNO IN CORSO.',
                     tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
         from fase_bil_d_elaborazione_tipo tipo
         where tipo.ente_proprietario_id=enteProprietarioId
         and   tipo.fase_bil_elab_tipo_code=APE_GEST_PROGRAMMI
         and   tipo.data_cancellazione is null
         and   tipo.validita_fine is null)
         returning fase_bil_elab_id into faseBilElabPGId;
        
        if faseBilElabPGId is null then 
         strMessaggio:=strMessaggio||' Impossibile determinare id.Elab.';
         codiceRisultato:=-1;
        else 
         codResult:=null;
	     insert into fase_bil_t_elaborazione_log
         (fase_bil_elab_id,fase_bil_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
         )
         values
         (faseBilElabPGId,strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
         returning fase_bil_elab_log_id into codResult;
         if codResult is null then
    	   raise exception ' Errore in inserimento LOG.';
         end if;
        
         strMessaggio:='Allineamento Programmi-Cronoprogrammi PG - da previsione '||annoBilancio::varchar||' a gestione annoBilancio='||annoBilancio::varchar||'.';
         strMessaggio:=strMessaggio||' Inizio Popola programmi-cronop da elaborare.';
         select * into strRec
         from fnc_fasi_bil_gest_apertura_programmi_popola
         (
           faseBilElabPGId,
           enteproprietarioid,
           annobilancio,
           'G',
           loginoperazione,
	       dataelaborazione
          );
          if strRec.codiceRisultato!=0 then
            strMessaggio:=strRec.messaggioRisultato;
            codiceRisultato:=strRec.codiceRisultato;
         end if;  
         if codiceRisultato = 0 then
           strMessaggio:='Allineamento Programmi-Cronoprogrammi PG - da previsione '||annoBilancio::varchar||' a gestione annoBilancio='||annoBilancio::varchar||'.';
           strMessaggio:=strMessaggio||' Inizio Elabora programmi-cronop.';
    	   select * into strRec
 	       from fnc_fasi_bil_gest_apertura_programmi_elabora
    	   (
	        faseBilElabPGId,
    	    enteproprietarioid,
	        annobilancio,
            'G',
            loginoperazione,
            dataelaborazione,
            true -- si colleg movimenti
           );
           if strRec.codiceRisultato!=0 then
            strMessaggioErr:=strRec.messaggioRisultato;
            strMessaggio:=strMessaggioErr;
            codiceRisultato:=strRec.codiceRisultato;
           end if;
         end if;
       end if; 
     end if;
    
 	 
     if faseBilElabPGId is not null then
     strMessaggio:='Allineamento Programmi-Cronoprogrammi PG - da previsione '||annoBilancio::varchar||' a gestione annoBilancio='||annoBilancio::varchar||'.';
     if codiceRisultato=0 then 
           
     	   strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione OK.';
           insert into fase_bil_t_elaborazione_log
	       (fase_bil_elab_id,fase_bil_elab_log_operazione,
             validita_inizio, login_operazione, ente_proprietario_id
	       )
	       values
           (faseBilElabPGId,strMessaggioFinale||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	       returning fase_bil_elab_log_id into codResult;

	       if codResult is null then
    	 	   raise exception ' Errore in inserimento LOG.';
    	   end if;

           update fase_bil_t_elaborazione
           set fase_bil_elab_esito='OK',
             fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' PG - DA P ANNO a G ANNO TERMINATA CON SUCCESSO.'
           where fase_bil_elab_id=faseBilElabPGId;

           insert into fase_bil_t_elaborazione_log
     	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
            validita_inizio, login_operazione, ente_proprietario_id
	       )
	       values
          (faseBilElabPGId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	       returning fase_bil_elab_log_id into codResult;

	       if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	       end if;
     else 
	   		strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione KO.';
		    insert into fase_bil_t_elaborazione_log
		    (fase_bil_elab_id,fase_bil_elab_log_operazione,
		        validita_inizio, login_operazione, ente_proprietario_id
	  	   )
		   values
    	   (faseBilElabPGId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
		   returning fase_bil_elab_log_id into codResult;

		   if codResult is null then
    		 	raise exception ' Errore in inserimento LOG.';
		   end if;

    	   update fase_bil_t_elaborazione
	       set fase_bil_elab_esito='KO',
    	       fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' PG - DA P ANNO A G ANNO TERMINATA CON ERRORE.'||upper (strMessaggioErr)
       		where fase_bil_elab_id=faseBilElabPGId;
      end if;
    end if;

 
	 if  codiceRisultato=0 then
	  	 messaggioRisultato := strMessaggioFinale||' Operazione terminata correttamente';
	  	 if faseBilElabId is not null then 
 	  	 	faseBilElabIdRet:=faseBilElabId;
 	  	 else 
 	  	    if faseBilElabPGId is not null then 
   	   	     faseBilElabIdRet:=faseBilElabPGId;
   	   	    else 
   	   	     if faseBilElabGPId is not null then 
   	   	      faseBilElabIdRet:=faseBilElabGPId;
   	   	     end if;
   	   	    end if; 
   	   	 end if; 
	 else
  	  	 messaggioRisultato := strMessaggioFinale||strMessaggio||strMessaggioErr;
     end if;

	 RETURN;
EXCEPTION
  WHEN raise_exception THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'ERRORE: . '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'Nessun elemento trovato. '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'Errore OTHERS DB '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


alter FUNCTION siac.fnc_fasi_bil_gest_allinea_programmi
(
integer, 
integer, 
varchar,
varchar, 
timestamp without time zone, 
OUT integer,
OUT integer, 
OUT  varchar
) owner to siac;
