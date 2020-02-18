/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_programmi (
  annobilancio integer,
  enteproprietarioid integer,
  tipoapertura varchar,
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
   strMessaggiofinale 			VARCHAR(1500)	:='';
   codResult              		INTEGER  		:=NULL;
   dataInizioVal 				timestamp		:=NULL;
   faseBilElabId 		        integer:=null;
   bilancioId                   integer:=null;
   periodoId                    integer:=null;

   faseOp                       varchar(50):=null;
   strRec record;

   APE_GEST_PROGRAMMI    	    CONSTANT varchar:='APE_GEST_PROGRAMMI';
   P_FASE						CONSTANT varchar:='P';
   G_FASE					    CONSTANT varchar:='G';
  BEGIN

   messaggioRisultato:='';
   codicerisultato:=0;
   faseBilElabIdRet:=0;
   dataInizioVal:= clock_timestamp();

   strmessaggiofinale:='Apertura Programmi-Cronoprogrammi di tipo '||tipoApertura||' per annoBilancio='||annoBilancio::varchar||'.';

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


    -- inserimento fase_bil_t_elaborazione
	strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
     fase_bil_elab_tipo_id,
     ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' IN CORSO.',
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
     if faseOp is null or faseOp not in (P_FASE,G_FASE) then
      	raise exception ' Il bilancio deve essere in fase % o %.',P_FASE,G_FASE;
     end if;

     strMessaggio:='Verifica coerenza tipo di apertura programmi-fase di bilancio di corrente.';
	 if tipoApertura!=faseOp then
     	raise exception ' Tipo di apertura % non consentita in fase di bilancio %.', tipoApertura,faseOp;
     end if;

 	 strMessaggio:='Inizio Popola programmi-cronop da elaborare.';
     select * into strRec
     from fnc_fasi_bil_gest_apertura_programmi_popola
     (
      faseBilElabId,
      enteproprietarioid,
      annobilancio,
      tipoApertura,
      loginoperazione,
	  dataelaborazione
     );
     if strRec.codiceRisultato!=0 then
        strMessaggio:=strRec.messaggioRisultato;
        codiceRisultato:=strRec.codiceRisultato;
     end if;

     if codiceRisultato=0 then
	     strMessaggio:='Inizio Elabora programmi-cronop.';
    	 select * into strRec
	     from fnc_fasi_bil_gest_apertura_programmi_elabora
    	 (
	      faseBilElabId,
    	  enteproprietarioid,
	      annobilancio,
          tipoApertura,
          loginoperazione,
          dataelaborazione
         );
         if strRec.codiceRisultato!=0 then
            strMessaggio:=strRec.messaggioRisultato;
            codiceRisultato:=strRec.codiceRisultato;
         end if;

     end if;


     if codiceRisultato=0 and faseBilElabId is not null then
	   strMessaggio:=' Chiusura fase_bil_t_elaborazione OK.';
       insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggioFinale||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

       update fase_bil_t_elaborazione
       set fase_bil_elab_esito='OK',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||'TERMINATA CON SUCCESSO.'
       where fase_bil_elab_id=faseBilElabId;

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

	 else
      if codiceRisultato!=0 and faseBilElabId is not null then
	   strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione KO.';
       insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggioFinale||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

       update fase_bil_t_elaborazione
       set fase_bil_elab_esito='KO',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||'TERMINATA CON ERRORE.'||upper (strMessaggio)
       where fase_bil_elab_id=faseBilElabId;
      end if;

     end if;
	 if  codiceRisultato=0 then
	  	 messaggioRisultato := strMessaggioFinale||' Operazione terminata correttamente';
	 else
  	  	 messaggioRisultato := strMessaggioFinale||strMessaggio;
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
COST 100; s a g g i o : = ' I n i z i o   P o p o l a   p r o g r a m m i - c r o n o p   d a   e l a b o r a r e . ' ; 
 
           s e l e c t   *   i n t o   s t r R e c 
 
           f r o m   f n c _ f a s i _ b i l _ g e s t _ a p e r t u r a _ p r o g r a m m i _ p o p o l a 
 
           ( 
 
             f a s e B i l E l a b I d , 
 
             e n t e p r o p r i e t a r i o i d , 
 
             a n n o b i l a n c i o , 
 
             t i p o A p e r t u r a , 
 
             l o g i n o p e r a z i o n e , 
 
 	     d a t a e l a b o r a z i o n e 
 
           ) ; 
 
           i f   s t r R e c . c o d i c e R i s u l t a t o ! = 0   t h e n 
 
                 s t r M e s s a g g i o : = s t r R e c . m e s s a g g i o R i s u l t a t o ; 
 
                 c o d i c e R i s u l t a t o : = s t r R e c . c o d i c e R i s u l t a t o ; 
 
           e n d   i f ; 
 
 
 
           i f   c o d i c e R i s u l t a t o = 0   t h e n 
 
 	           s t r M e s s a g g i o : = ' I n i z i o   E l a b o r a   p r o g r a m m i - c r o n o p . ' ; 
 
         	   s e l e c t   *   i n t o   s t r R e c 
 
 	           f r o m   f n c _ f a s i _ b i l _ g e s t _ a p e r t u r a _ p r o g r a m m i _ e l a b o r a 
 
         	   ( 
 
 	             f a s e B i l E l a b I d , 
 
         	     e n t e p r o p r i e t a r i o i d , 
 
 	             a n n o b i l a n c i o , 
 
                     t i p o A p e r t u r a , 
 
                     l o g i n o p e r a z i o n e , 
 
                     d a t a e l a b o r a z i o n e 
 
                   ) ; 
 
                   i f   s t r R e c . c o d i c e R i s u l t a t o ! = 0   t h e n 
 
                         s t r M e s s a g g i o : = s t r R e c . m e s s a g g i o R i s u l t a t o ; 
 
                         c o d i c e R i s u l t a t o : = s t r R e c . c o d i c e R i s u l t a t o ; 
 
                   e n d   i f ; 
 
 
 
           e n d   i f ; 
 
 
 
 
 
           i f   c o d i c e R i s u l t a t o = 0   a n d   f a s e B i l E l a b I d   i s   n o t   n u l l   t h e n 
 
 	       s t r M e s s a g g i o : = '   C h i u s u r a   f a s e _ b i l _ t _ e l a b o r a z i o n e   O K . ' ; 
 
               i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
 	       ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
                 v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
 	       ) 
 
 	       v a l u e s 
 
               ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
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
               u p d a t e   f a s e _ b i l _ t _ e l a b o r a z i o n e 
 
               s e t   f a s e _ b i l _ e l a b _ e s i t o = ' O K ' , 
 
                       f a s e _ b i l _ e l a b _ e s i t o _ m s g = ' E L A B O R A Z I O N E   F A S E   B I L A N C I O   ' | | A P E _ G E S T _ P R O G R A M M I | | ' T E R M I N A T A   C O N   S U C C E S S O . ' 
 
               w h e r e   f a s e _ b i l _ e l a b _ i d = f a s e B i l E l a b I d ; 
 
 
 
               i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
 	       ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
                 v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
 	       ) 
 
 	       v a l u e s 
 
               ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | '   F I N E . ' , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
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
 	   e l s e 
 
             i f   c o d i c e R i s u l t a t o ! = 0   a n d   f a s e B i l E l a b I d   i s   n o t   n u l l   t h e n 
 
 	       s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   C h i u s u r a   f a s e _ b i l _ t _ e l a b o r a z i o n e   K O . ' ; 
 
               i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
 	       ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
                 v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
 	       ) 
 
 	       v a l u e s 
 
               ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
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
               u p d a t e   f a s e _ b i l _ t _ e l a b o r a z i o n e 
 
               s e t   f a s e _ b i l _ e l a b _ e s i t o = ' K O ' , 
 
                       f a s e _ b i l _ e l a b _ e s i t o _ m s g = ' E L A B O R A Z I O N E   F A S E   B I L A N C I O   ' | | A P E _ G E S T _ P R O G R A M M I | | ' T E R M I N A T A   C O N   E R R O R E . ' | | u p p e r   ( s t r M e s s a g g i o ) 
 
               w h e r e   f a s e _ b i l _ e l a b _ i d = f a s e B i l E l a b I d ; 
 
             e n d   i f ; 
 
 
 
           e n d   i f ; 
 
 	   i f     c o d i c e R i s u l t a t o = 0   t h e n 
 
 	     	   m e s s a g g i o R i s u l t a t o   : =   s t r M e s s a g g i o F i n a l e | | '   O p e r a z i o n e   t e r m i n a t a   c o r r e t t a m e n t e ' ; 
 
 	   e l s e 
 
     	     	   m e s s a g g i o R i s u l t a t o   : =   s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o ; 
 
           e n d   i f ; 
 
 
 
 	   R E T U R N ; 
 
 E X C E P T I O N 
 
     W H E N   r a i s e _ e x c e p t i o n   T H E N 
 
         R A I S E   n o t i c e   ' %   %   E r r o r e   D B   %   % ' , s t r m e s s a g g i o f i n a l e , s t r m e s s a g g i o , S Q L S T A T E ,   s u b s t r i n g ( u p p e r ( S Q L E R R M )   F R O M   1   F O R   1 5 0 0 ) ; 
 
         m e s s a g g i o r i s u l t a t o : = s t r m e s s a g g i o f i n a l e | | s t r m e s s a g g i o | | ' E R R O R E :   .   ' | | S Q L S T A T E | | '   ' | | s u b s t r i n g ( u p p e r ( S Q L E R R M )   F R O M   1   F O R   1 5 0 0 )   ; 
 
         c o d i c e r i s u l t a t o : = - 1 ; 
 
         R E T U R N ; 
 
     W H E N   n o _ d a t a _ f o u n d   T H E N 
 
         R A I S E   n o t i c e   ' %   %   E r r o r e   D B   %   % ' , s t r m e s s a g g i o f i n a l e , s t r m e s s a g g i o , S Q L S T A T E ,   s u b s t r i n g ( u p p e r ( S Q L E R R M )   F R O M   1   F O R   1 5 0 0 ) ; 
 
         m e s s a g g i o r i s u l t a t o : = s t r m e s s a g g i o f i n a l e | | s t r m e s s a g g i o | | ' N e s s u n   e l e m e n t o   t r o v a t o .   ' | | S Q L S T A T E | | '   ' | | s u b s t r i n g ( u p p e r ( S Q L E R R M )   F R O M   1   F O R   1 5 0 0 )   ; 
 
         c o d i c e r i s u l t a t o : = - 1 ; 
 
         R E T U R N ; 
 
     W H E N   O T H E R S   T H E N 
 
         R A I S E   n o t i c e   ' %   %   E r r o r e   D B   %   % ' , s t r m e s s a g g i o f i n a l e , s t r m e s s a g g i o , S Q L S T A T E ,   s u b s t r i n g ( u p p e r ( S Q L E R R M )   F R O M   1   F O R   1 5 0 0 ) ; 
 
         m e s s a g g i o r i s u l t a t o : = s t r m e s s a g g i o f i n a l e | | s t r m e s s a g g i o | | ' E r r o r e   O T H E R S   D B   ' | | S Q L S T A T E | | '   ' | | s u b s t r i n g ( u p p e r ( S Q L E R R M )   F R O M   1   F O R   1 5 0 0 )   ; 
 
         c o d i c e r i s u l t a t o : = - 1 ; 
 
         R E T U R N ; 
 
     E N D ; 
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