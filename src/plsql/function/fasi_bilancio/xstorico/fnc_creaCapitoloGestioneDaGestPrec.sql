/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 17.02.2014 Sofia
-- Creazione dei capitoli di Gestione di un bilancio
-- Partendo dai capitoli di gestione del pluriennale del bilancio precedente
CREATE or replace FUNCTION fnc_creaCapitoloGestioneDaGestPrec(bilancioId in integer,
															  periodoId in INTEGER,
                                                              bilancioPrecId in integer,
															  enteProprietarioId in integer,
                                                      		  tipoCapEU in varchar,
                                                      		  bilElemGestTipo in varchar,
	                                                   	      annoBilancio in VARCHAR, loginOperazione  in VARCHAR,
                        	                            	  dataElaborazione in timestamp,
                            	                        	  numeroCapInseriti out integer, messaggioRisultato out varchar)
AS $$
DECLARE
    bilElemId integer := 0;
    bilElemTipoId integer :=0;

    numeroElementiInseriti integer:=0;
    capitoloGest record;
    bilancioPrecRec record;
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	annoBilancioPrec varchar(4):= ((annoBilancio::INTEGER)-1)::VARCHAR;
   	annoBilancioSucc varchar(4):= ((annoBilancio::INTEGER)+1)::VARCHAR;
   	annoBilancioSuccSucc varchar(4) := ((annoBilancio::INTEGER)+2)::VARCHAR;



    -- totali importi impegni/accertamenti pluriennali da calcolare
	impAccAnnoSuccSuccRec record;

    tipoMovGest varchar(1):='I';
	statiOperativiMovGestPlur varchar(10):='P,D';

    -- costanti
    -- Stato operativo valido
    STATO_VALIDO CONSTANT  varchar :='VA';
    -- Tipi di importo
    STANZ_INIZIALE  CONSTANT  varchar :='STI';
    STANZ_ATTUALE   CONSTANT  varchar :='STA';
    STANZ_RES_INIZIALE CONSTANT  varchar :='SRI';
    STANZ_RESIDUO CONSTANT  varchar :='STR';
    STANZ_CASSA_INIZIALE CONSTANT  varchar :='SCI';
    STANZ_CASSA CONSTANT  varchar :='SCA';
    STANZ_ASSEST_CASSA CONSTANT varchar:='STCASS';
    STANZ_ASSEST CONSTANT varchar:='STASS';
    STANZ_ASSEST_RES CONSTANT varchar:='STRASS';



BEGIN

    RAISE NOTICE 'Inizio creazione capitoli da tipo=% ', bilElemGestTipo;

    numeroCapInseriti:=0;
    messaggioRisultato:='';

	if tipoCapEU='E' then
	    tipoMovGest:='A';
    end if;

	strMessaggioFinale:='Inserimento elementi tipo '||bilElemGestTipo||' da pluriennale precedente.';

	strMessaggio:='Lettura elemento bilancio tipo '||bilElemGestTipo||' anno bilancio='||annoBilancioPrec||'.';
    for capitoloGest in
    select capitolo.*
     from siac_t_bil_elem  capitolo, siac_d_bil_elem_stato capitoloStato, siac_r_bil_elem_stato capitoloStatoRel,
          siac_d_bil_elem_tipo capitoloTipo,
          siac_t_bil bilancio
     where  bilancio.bil_id = bilancioPrecId and
     		bilancio.ente_proprietario_id= enteProprietarioId and
     		capitolo.bil_id=bilancio.bil_id and
            capitolo.data_cancellazione is null and
			date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitolo.validita_inizio) and
            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitolo.validita_fine)
              or capitolo.validita_fine is null) and
            capitoloStatoRel.elem_id=capitolo.elem_id and
            capitoloStato.elem_stato_id = capitoloStatoRel.elem_stato_id and
            capitoloStato.elem_stato_code=STATO_VALIDO and
            capitoloTipo.elem_tipo_id=capitolo.elem_tipo_id and
            capitoloTipo.elem_tipo_code=bilElemGestTipo and
            capitoloStatoRel.data_cancellazione is null and
			date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloStatoRel.validita_inizio) and
            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloStatoRel.validita_fine)
              or capitoloStatoRel.validita_fine is null)
    order by capitolo.elem_code,capitolo.elem_code2,capitolo.elem_code3


    loop


	strMessaggio:='Inserimento elemento bilancio tipo '||bilElemGestTipo||' '||
    capitoloGest.elem_code||'/'||capitoloGest.elem_code2||'/'||capitoloGest.elem_code3||
    ' da Id '||capitoloGest.elem_id||' anno prec='||annoBilancioPrec||'.';

    -- inserimento del capitolo Gestione
	insert into siac_t_bil_elem
	(elem_code,elem_code2,elem_code3, elem_desc,elem_desc2,
	 elem_id_padre,elem_tipo_id, bil_id,ordine,livello,
	 validita_inizio , ente_proprietario_id,data_creazione,login_operazione)
	(select capitoloGest.elem_code,capitoloGest.elem_code2,capitoloGest.elem_code3,capitoloGest.elem_desc,capitoloGest.elem_desc2,
           capitoloGest.elem_id_padre,bilElemTipoId,bilancioId,capitoloGest.ordine,capitoloGest.livello,
           CURRENT_TIMESTAMP,capitoloGest.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
	 from siac_t_bil_elem capitolo
 	 where capitolo.elem_id=capitoloGest.elem_id)
     returning elem_id into bilElemId ;


	strMessaggio:='Inserimento stato op. elemento bilancio tipo '||bilElemGestTipo||' '||
    capitoloGest.elem_code||'/'||capitoloGest.elem_code2||'/'||capitoloGest.elem_code3||
    ' da Id '||capitoloGest.elem_id||' anno prec='||annoBilancioPrec||'.';

	 -- Inserimento dello stato capitolo Gestione  VA-Valido
	 -- dovra esserci un unico elemento valido per lo stato VA
	 insert into siac_r_bil_elem_stato
     (elem_id,elem_stato_id,validita_inizio,ente_proprietario_id,
     data_creazione,login_operazione)
     (select bilElemId,capitoloStato.elem_stato_id,CURRENT_TIMESTAMP,capitoloStato.ente_proprietario_id,
      CURRENT_TIMESTAMP,loginOperazione
      from  siac_d_bil_elem_stato capitoloStato
      where capitoloStato.elem_stato_code= STATO_VALIDO and
            capitoloStato.ente_proprietario_id=enteProprietarioId and
            capitoloStato.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloStato.validita_inizio) and
            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloStato.validita_fine)
              or capitoloStato.validita_fine is null));


	strMessaggio:='Inserimento dettagli elemento bilancio tipo '||bilElemGestTipo||' '||
    capitoloGest.elem_code||'/'||capitoloGest.elem_code2||'/'||capitoloGest.elem_code3||
    ' da Id '||capitoloGest.elem_id||' anno prec='||annoBilancioPrec||'.'||
    'Stanziamento Iniziale '||annoBilancio||' ' ||annoBilancioSucc||'.';

     -- Stanziamenti gestione su bilancio annoprec, importi anno, anno+1
	 -- STI - Stanziamento Iniziale
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     (select bilElemId, capitoloDett.elem_det_importo,capitoloDett.elem_det_flag,
             (select elem_det_tipo_id from siac_d_bil_elem_det_tipo capitoloTipoDettIniz
              where capitoloTipoDettIniz.ente_proprietario_id=enteProprietarioId and
              		capitoloTipoDettIniz.data_cancellazione is null and
                    date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloTipoDettIniz.validita_inizio) and
		            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloTipoDettIniz.validita_fine)
        		      or capitoloTipoDettIniz.validita_fine is null) and
                    capitoloTipoDettIniz.elem_det_tipo_code=STANZ_INIZIALE),
             periodoPlurPrec.periodo_id,CURRENT_TIMESTAMP,
	  	     capitoloDett.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
      from siac_t_bil_elem_det capitoloDett, siac_d_bil_elem_det_tipo capitoloTipoDett,
      	   siac_t_periodo periodoPlurPrec
      where periodoPlurPrec.anno in (annoBilancio,annoBilancioSucc) and
      		periodoPlurPrec.ente_proprietario_id=enteProprietarioId and
      		capitoloDett.periodo_id=periodoPlurPrec.periodo_id and
      		capitoloDett.elem_id=capitoloGest.elem_id and
            capitoloDett.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloDett.validita_inizio) and
		            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloDett.validita_fine)
        		      or capitoloDett.validita_fine is null) and
            periodoPlurPrec.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',periodoPlurPrec.validita_inizio) and
		            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',periodoPlurPrec.validita_fine)
        		      or periodoPlurPrec.validita_fine is null) and
            capitoloTipoDett.elem_det_tipo_id = capitoloDett.elem_det_tipo_id and
            capitoloTipoDett.elem_det_tipo_code=STANZ_ATTUALE);

	strMessaggio:='Inserimento dettagli elemento bilancio tipo '||bilElemGestTipo||' '||
    capitoloGest.elem_code||'/'||capitoloGest.elem_code2||'/'||capitoloGest.elem_code3||
    ' da Id '||capitoloGest.elem_id||' anno prec='||annoBilancioPrec||'.'||
    'Stanziamento Residuo Iniziale '||annoBilancio||' ' ||annoBilancioSucc||'.';


     -- SRI - Stanziamento Residuo Iniziale
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     (select bilElemId, capitoloDett.elem_det_importo,capitoloDett.elem_det_flag,
             (select elem_det_tipo_id from siac_d_bil_elem_det_tipo capitoloTipoDettIniz
              where capitoloTipoDettIniz.ente_proprietario_id=enteProprietarioId and
                    capitoloTipoDettIniz.data_cancellazione is null and
                    date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloTipoDettIniz.validita_inizio) and
		            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloTipoDettIniz.validita_fine)
        		      or capitoloTipoDettIniz.validita_fine is null) and
                    capitoloTipoDettIniz.elem_det_tipo_code=STANZ_RES_INIZIALE),
             periodoPlurPrec.periodo_id,CURRENT_TIMESTAMP,
	  	     capitoloDett.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
      from siac_t_bil_elem_det capitoloDett, siac_d_bil_elem_det_tipo capitoloTipoDett,
	       siac_t_periodo periodoPlurPrec
      where periodoPlurPrec.anno in (annoBilancio,annoBilancioSucc) and
      		periodoPlurPrec.ente_proprietario_id=enteProprietarioId and
      		capitoloDett.periodo_id=periodoPlurPrec.periodo_id and
      		capitoloDett.elem_id=capitoloGest.elem_id and
            periodoPlurPrec.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',periodoPlurPrec.validita_inizio) and
		            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',periodoPlurPrec.validita_fine)
        		      or periodoPlurPrec.validita_fine is null) and
            capitoloDett.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloDett.validita_inizio) and
		            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloDett.validita_fine)
        		      or capitoloDett.validita_fine is null) and
            capitoloTipoDett.elem_det_tipo_id = capitoloDett.elem_det_tipo_id and
            capitoloTipoDett.elem_det_tipo_code=STANZ_RESIDUO);

	strMessaggio:='Inserimento dettagli elemento bilancio tipo '||bilElemGestTipo||' '||
    capitoloGest.elem_code||'/'||capitoloGest.elem_code2||'/'||capitoloGest.elem_code3||
    ' da Id '||capitoloGest.elem_id||' anno prec='||annoBilancioPrec||'.'||
    'Stanziamento Cassa Iniziale '||annoBilancio||' ' ||annoBilancioSucc||'.';


	 -- SCI - Stanziamento Cassa Iniziale
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     (select bilElemId, capitoloDett.elem_det_importo,capitoloDett.elem_det_flag,
             (select elem_det_tipo_id from siac_d_bil_elem_det_tipo capitoloTipoDettIniz
              where capitoloTipoDettIniz.ente_proprietario_id=enteProprietarioId and
                    capitoloTipoDettIniz.data_cancellazione is null and
                    date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloTipoDettIniz.validita_inizio) and
		            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloTipoDettIniz.validita_fine)
        		      or capitoloTipoDettIniz.validita_fine is null) and
                    capitoloTipoDettIniz.elem_det_tipo_code=STANZ_CASSA_INIZIALE),
             periodoPlurPrec.periodo_id,CURRENT_TIMESTAMP,
	  	     capitoloDett.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
      from siac_t_bil_elem_det capitoloDett, siac_d_bil_elem_det_tipo capitoloTipoDett,
      	    siac_t_periodo periodoPlurPrec
      where periodoPlurPrec.anno in (annoBilancio,annoBilancioSucc) and
      		periodoPlurPrec.ente_proprietario_id=enteProprietarioId and
      		capitoloDett.periodo_id=periodoPlurPrec.periodo_id and
      		capitoloDett.elem_id=capitoloGest.elem_id and
            capitoloDett.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloDett.validita_inizio) and
            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloDett.validita_fine)
       		      or capitoloDett.validita_fine is null) and
            periodoPlurPrec.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',periodoPlurPrec.validita_inizio) and
		            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',periodoPlurPrec.validita_fine)
        		      or periodoPlurPrec.validita_fine is null) and
            capitoloTipoDett.elem_det_tipo_id = capitoloDett.elem_det_tipo_id and
            capitoloTipoDett.elem_det_tipo_code=STANZ_CASSA);

	strMessaggio:='Inserimento dettagli elemento bilancio tipo '||bilElemGestTipo||' '||
    capitoloGest.elem_code||'/'||capitoloGest.elem_code2||'/'||capitoloGest.elem_code3||
    ' da Id '||capitoloGest.elem_id||' anno prec='||annoBilancioPrec||'.'||
    'Altri stanziamenti '||annoBilancio||' ' ||annoBilancioSucc||'.';


	 -- STP - Stanziamento Proposto
     -- STA - Stanziamento Attuale
     -- STR - Stanziamento Residuo
     -- SCA - Stanziamento Cassa
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     (select bilElemId, capitoloDett.elem_det_importo,capitoloDett.elem_det_flag,
			 capitoloDett.elem_det_tipo_id,
             periodoPlurPrec.periodo_id,CURRENT_TIMESTAMP,
	  	     capitoloDett.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
      from siac_t_bil_elem_det capitoloDett, siac_d_bil_elem_det_tipo capitoloTipoDett,
		   siac_t_periodo periodoPlurPrec
      where periodoPlurPrec.anno in (annoBilancio,annoBilancioSucc) and
      		periodoPlurPrec.ente_proprietario_id=enteProprietarioId and
      		capitoloDett.periodo_id=periodoPlurPrec.periodo_id and
      		capitoloDett.elem_id=capitoloGest.elem_id and
            capitoloDett.data_cancellazione is null and
		    date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloDett.validita_inizio) and
            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloDett.validita_fine)
       		      or capitoloDett.validita_fine is null) and
            periodoPlurPrec.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',periodoPlurPrec.validita_inizio) and
		            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',periodoPlurPrec.validita_fine)
        		      or periodoPlurPrec.validita_fine is null) and
            capitoloTipoDett.elem_det_tipo_id = capitoloDett.elem_det_tipo_id and
            capitoloTipoDett.elem_det_tipo_code not in (STANZ_INIZIALE,STANZ_RES_INIZIALE,STANZ_CASSA_INIZIALE));

	strMessaggio:='Inserimento dettagli elemento bilancio tipo '||bilElemGestTipo||' '||
    capitoloGest.elem_code||'/'||capitoloGest.elem_code2||'/'||capitoloGest.elem_code3||
    ' da Id '||capitoloGest.elem_id||' anno prec='||annoBilancioPrec||'.'||
    'Stanziamenti Assestamento '||annoBilancio||' ' ||annoBilancioSucc||'.';

	 -- STASS - Stanziamento Assestamento
     -- STCASS - Stanziamento Assestamento Cassa
     -- STRASS - Stanziamento Assestamento Residuo
	 insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     (select bilElemId, 0,capitoloDett.elem_det_flag,
			 capitoloDett.elem_det_tipo_id,
             periodoPlurPrec.periodo_id,CURRENT_TIMESTAMP,
	  	     capitoloDett.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
      from siac_t_bil_elem_det capitoloDett, siac_d_bil_elem_det_tipo capitoloTipoDett,
		   siac_t_periodo periodoPlurPrec
      where periodoPlurPrec.anno in (annoBilancio,annoBilancioSucc) and
      		periodoPlurPrec.ente_proprietario_id=enteProprietarioId and
      		capitoloDett.periodo_id=periodoPlurPrec.periodo_id and
      		capitoloDett.elem_id=capitoloGest.elem_id and
            capitoloDett.data_cancellazione is null and
		    date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloDett.validita_inizio) and
            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloDett.validita_fine)
       		      or capitoloDett.validita_fine is null) and
            periodoPlurPrec.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',periodoPlurPrec.validita_inizio) and
		            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',periodoPlurPrec.validita_fine)
        		      or periodoPlurPrec.validita_fine is null) and
            capitoloTipoDett.elem_det_tipo_id = capitoloDett.elem_det_tipo_id and
            capitoloTipoDett.elem_det_tipo_code  in (STANZ_ASSEST,STANZ_ASSEST_CASSA,STANZ_ASSEST_RES));

		strMessaggio:='Inserimento dettagli elemento bilancio tipo '||bilElemGestTipo||' '||
    	capitoloGest.elem_code||'/'||capitoloGest.elem_code2||'/'||capitoloGest.elem_code3||
	    ' da Id '||capitoloGest.elem_id||' anno prec='||annoBilancioPrec||'.'||
    	'Stanziamenti  '||annoBilancioSuccSucc||'.';

		-- Stanziamenti gestione su bilancio  importi anno+2
		insert into siac_t_bil_elem_det
	    (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
		 ente_proprietario_id,data_creazione,login_operazione)
	    (select bilElemId, 0,capitoloDett.elem_det_flag,
		  	    capitoloDett.elem_det_tipo_id,
                (select periodoSuccSucc.periodo_id
                 from siac_t_periodo periodoSuccSucc
                 where periodoSuccSucc.anno = annoBilancioSuccSucc and
	                   periodoSuccSucc.ente_proprietario_id=enteProprietarioId and
                       periodoSuccSucc.data_cancellazione is null and
			           date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',periodoSuccSucc.validita_inizio) and
		     		  (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',periodoSuccSucc.validita_fine)
        		       or periodoSuccSucc.validita_fine is null)
                 ),
                CURRENT_TIMESTAMP,
  	  	        capitoloDett.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
	    from siac_t_bil_elem_det capitoloDett, siac_d_bil_elem_det_tipo capitoloTipoDett,
		     siac_t_periodo periodoPlurPrec
        where periodoPlurPrec.anno=annoBilancioSucc and
      		  periodoPlurPrec.ente_proprietario_id=enteProprietarioId and
      		  capitoloDett.periodo_id=periodoPlurPrec.periodo_id and
      		  capitoloDett.elem_id=capitoloGest.elem_id and
              capitoloDett.data_cancellazione is null and
		      date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloDett.validita_inizio) and
              (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloDett.validita_fine)
       		      or capitoloDett.validita_fine is null) and
              periodoPlurPrec.data_cancellazione is null and
              date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',periodoPlurPrec.validita_inizio) and
		            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',periodoPlurPrec.validita_fine)
        		      or periodoPlurPrec.validita_fine is null) and
              capitoloTipoDett.elem_det_tipo_id = capitoloDett.elem_det_tipo_id and
              capitoloTipoDett.elem_det_tipo_code not in (STANZ_INIZIALE,STANZ_ATTUALE,STANZ_FPV));


        strMessaggio:='Inserimento dettagli elemento bilancio tipo '||bilElemGestTipo||' '||
    	capitoloGest.elem_code||'/'||capitoloGest.elem_code2||'/'||capitoloGest.elem_code3||
	    ' da Id '||capitoloGest.elem_id||' anno prec='||annoBilancioPrec||'.'||
    	'Lettura impegnato/accertato pluriennale '||annoBilancioSuccSucc||'per valorizzazione stanziamenti iniziale e attuale.';

		select * into impAccAnnoSuccSuccRec
        from fnc_totaleImpAccAnnoCompetenza(bilancioPrecId,capitoloGest.elem_id,
        									null,null,null,null,tipoMovGest,enteProprietarioId,annoBilancioSuccSucc,
                                            statiOperativiMovGestPlur,dataElaborazione);

		raise notice '% %',strMessaggio,COALESCE( impAccAnnoSuccSuccRec.totImpegnatoAttuale,0);

		strMessaggio:='Inserimento dettagli elemento bilancio tipo '||bilElemGestTipo||' '||
    	capitoloGest.elem_code||'/'||capitoloGest.elem_code2||'/'||capitoloGest.elem_code3||
	    ' da Id '||capitoloGest.elem_id||' anno prec='||annoBilancioPrec||'.'||
    	'Stanziamenti iniziale e attuale '||annoBilancioSuccSucc||'.';

		-- Stanziamenti iniziale, attuale gestione su bilancio  importi anno+2
        -- Necessario calcolo degli impegni pluriennali del bilancio di gestione precedente
        -- Solo implegni pluriennali con annoCompetenza=anno+2
		insert into siac_t_bil_elem_det
	    (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
		 ente_proprietario_id,data_creazione,login_operazione)
	    (select bilElemId, COALESCE(impAccAnnoSuccSuccRec.totImpegnatoAttuale,0),capitoloDett.elem_det_flag,
		  	    capitoloDett.elem_det_tipo_id,
                (select periodoSuccSucc.periodo_id
                 from siac_t_periodo periodoSuccSucc
                 where periodoSuccSucc.anno = annoBilancioSuccSucc and
	                   periodoSuccSucc.ente_proprietario_id=enteProprietarioId and
                       periodoSuccSucc.data_cancellazione is null and
			           date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',periodoSuccSucc.validita_inizio) and
		     		  (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',periodoSuccSucc.validita_fine)
        		       or periodoSuccSucc.validita_fine is null)
                 ),
                CURRENT_TIMESTAMP,
  	  	        capitoloDett.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
	    from siac_t_bil_elem_det capitoloDett, siac_d_bil_elem_det_tipo capitoloTipoDett,
		     siac_t_periodo periodoPlurPrec
        where periodoPlurPrec.anno=annoBilancioSucc and
      		  periodoPlurPrec.ente_proprietario_id=enteProprietarioId and
      		  capitoloDett.periodo_id=periodoPlurPrec.periodo_id and
      		  capitoloDett.elem_id=capitoloGest.elem_id and
              capitoloDett.data_cancellazione is null and
		      date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloDett.validita_inizio) and
              (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloDett.validita_fine)
       		      or capitoloDett.validita_fine is null) and
              periodoPlurPrec.data_cancellazione is null and
              date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',periodoPlurPrec.validita_inizio) and
		            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',periodoPlurPrec.validita_fine)
        		      or periodoPlurPrec.validita_fine is null) and
              capitoloTipoDett.elem_det_tipo_id = capitoloDett.elem_det_tipo_id and
              capitoloTipoDett.elem_det_tipo_code  in (STANZ_INIZIALE,STANZ_ATTUALE));


	strMessaggio:='Inserimento attributi elemento bilancio tipo '||bilElemGestTipo||' '||
    capitoloGest.elem_code||'/'||capitoloGest.elem_code2||'/'||capitoloGest.elem_code3||
    ' da Id '||capitoloGest.elem_id||' anno prec='||annoBilancioPrec||'.';

 	 insert into siac_r_bil_elem_attr
     (elem_id,attr_id,tabella_id,boolean,percentuale,testo,numerico,validita_inizio,
     ente_proprietario_id,data_creazione,login_operazione)
    (select bilElemId,capitoloAttr.attr_id,capitoloAttr.tabella_id,
            capitoloAttr.boolean,capitoloAttr.percentuale,capitoloAttr.testo,capitoloAttr.numerico,
            CURRENT_TIMESTAMP,
	        capitoloAttr.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
     from siac_r_bil_elem_attr capitoloAttr, siac_t_attr attrTipi
     where capitoloAttr.elem_id= capitoloGest.elem_id and
           capitoloAttr.data_cancellazione is null and
           date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloAttr.validita_inizio) and
           (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloAttr.validita_fine)
      		      or capitoloAttr.validita_fine is null) and
           attrTipi.attr_id=capitoloAttr.attr_id);



	strMessaggio:='Inserimento classificatori elemento bilancio tipo '||bilElemGestTipo||' '||
    capitoloPrev.elem_code||'/'||capitoloPrev.elem_code2||'/'||capitoloPrev.elem_code3||
    ' da Id '||capitoloPrev.elem_id||' '||bilElemPrevTipo||'.';

     insert into siac_r_bil_elem_class
     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
	  data_creazione,login_operazione)
     (select bilElemId,capitoloAttrClass.classif_id,CURRENT_TIMESTAMP , capitoloAttrClass.ente_proprietario_id,
	  CURRENT_TIMESTAMP,loginOperazione
      from siac_r_bil_elem_class capitoloAttrClass
      where capitoloAttrClass.elem_id= capitoloPrev.elem_id and
            capitoloAttrClass.data_cancellazione is null and
			date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloAttrClass.validita_inizio) and
	        (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloAttrClass.validita_fine)
      		      or capitoloAttrClass.validita_fine is null));


	strMessaggio:='Inserimento atti di legge relazionati a elemento bilancio tipo '||bilElemGestTipo||' '||
    capitoloGest.elem_code||'/'||capitoloGest.elem_code2||'/'||capitoloGest.elem_code3||
    ' da Id '||capitoloGest.elem_id||' anno prec='||annoBilancioPrec||'.';

	INSERT INTO siac_r_bil_elem_atto_legge
    (elem_id,attolegge_id,descrizione,gerarchia,finanziamento_inizio,finanziamento_fine,
	 validita_inizio,ente_proprietario_id, data_creazione,login_operazione
	)
    (select bilElemId, capitoloAttoLegge.attolegge_id,capitoloAttoLegge.descrizione,
            capitoloAttoLegge.gerarchia,capitoloAttoLegge.finanziamento_inizio,capitoloAttoLegge.finanziamento_fine,
	  	    CURRENT_TIMESTAMP,capitoloAttoLegge.ente_proprietario_id, CURRENT_TIMESTAMP,loginOperazione
     from siac_r_bil_elem_atto_legge capitoloAttoLegge
     where capitoloAttoLegge.elem_id= capitoloGest.elem_id and
           capitoloAttoLegge.data_cancellazione is null and
           date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloAttoLegge.validita_inizio) and
	        (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloAttoLegge.validita_fine)
      		      or capitoloAttoLegge.validita_fine is null)
    );

     numeroElementiInseriti:=numeroElementiInseriti+1;
   end loop;

   RAISE NOTICE 'NumeroElementiInseriti %', numeroElementiInseriti;

   messaggioRisultato:=strMessaggioFinale||'Inseriti '||numeroElementiInseriti||' elementi di bilancio.';
   numeroCapInseriti:= numeroElementiInseriti;
   return;

exception
	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        numeroCapInseriti:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        numeroCapInseriti:=-1;
        return;
END;
$$ LANGUAGE plpgsql;