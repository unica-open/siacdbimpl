/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 17.02.2014 Sofia
-- Creazione dei Vincoli Capitolo di Gestione
-- Partendo da quelli del pluriennale di gestione del precedente bilancio
CREATE or replace FUNCTION fnc_creaVincoliCapitoloGestioneDaGestPrec(bilancioId in integer,
																 	 periodoId IN integer ,
	                                                                 bilancioPrecId in integer,
                                                                     periodoPrecId IN integer ,
     	                                                             enteProprietarioId in integer,
         	                                             			 bilElemUscGestTipo in varchar,
            	                                          			 bilElemEntGestTipo in varchar,
	            	                                                 annoBilancio in VARCHAR, loginOperazione  in VARCHAR,
		            	                                             dataElaborazione timestamp,
                        	                                         numeroVincoliInseriti out integer, messaggioRisultato out varchar)
AS $$
DECLARE

    vincoloId integer := 0;
	vincoloTipoId integer := 0;

    numeroElementiInseriti integer:=0;
    vincoloGest record;

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

    -- costanti
    -- Stato operativo valido
    STATO_VALIDO CONSTANT  varchar :='V';
    TIPO_VINCOLO_G CONSTANT varchar :='G';

	STATO_ELEM_VALIDO CONSTANT  varchar :='VA';

BEGIN

    RAISE NOTICE 'Inizio creazione Vincoli Capitolo tipo=G da gestione pluriennale precedente ';

    numeroVincoliInseriti:=0;
    messaggioRisultato:='';

	strMessaggioFinale:='Inserimento Vincoli Capitolo  tipo G da gestione pluriennale precedente.';

    strMessaggio:='Lettura Identificativo Vincolo  tipo G.';
    -- Dovra esserci un unico elemento valido
    select vincolo_tipo_id into vincoloTipoId
	from siac_d_vincolo_tipo
	where vincolo_tipo_code=TIPO_VINCOLO_G and
          data_cancellazione is null and
          date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',validita_inizio) and
          (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',validita_fine)
             or validita_fine is null) and
          ente_proprietario_id=enteProprietarioId;


	strMessaggio:='Lettura Vincoli Capitolo.';
	--- Accesso ai vincoli per periodo che deve essere quello relativo all'anno di bilancio
    for vincoloGest in
     select vincolo.*
	 from siac_t_vincolo vincolo, siac_d_vincolo_stato statoVincolo,siac_r_vincolo_stato  statoVincoloRel,
          siac_d_vincolo_tipo tipoVincolo
	 where vincolo.periodo_id = periodoPrecId and vincolo.ente_proprietario_id=enteProprietarioId and
     	   vincolo.vincolo_tipo_id = tipoVincolo.vincolo_tipo_id and
           vincolo.data_cancellazione is null and
		   date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',vincolo.validita_inizio) and
            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',vincolo.validita_fine)
              or vincolo.validita_fine is null) and
           tipovincolo.vincolo_tipo_id=vincoloTipoId and
           statoVincoloRel.vincolo_id=vincolo.vincolo_id and
           statoVincoloRel.vincolo_stato_id=statoVincolo.vincolo_stato_id and
           statoVincolo.vincolo_stato_code=STATO_VALIDO and
           statoVincoloRel.data_cancellazione is null and
		   date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',statoVincoloRel.validita_inizio) and
           (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',statoVincoloRel.validita_fine)
              or statoVincoloRel.validita_fine is null) and
           vincolo.vincolo_id  in
           ( (select distinct vincoloBilElem.vincolo_id
      	         from siac_r_vincolo_bil_elem vincoloBilElem,
               	      siac_t_bil_elem capitoloUscGestPrec,siac_t_bil bilancioPrec,
	                  siac_t_bil_elem capitoloUscGest, siac_d_bil_elem_tipo tipoCapUscGest, siac_t_bil bilancio
	              where bilancioPrec.bil_id=bilancioPrecId and
                        bilancioPrec.ente_proprietario_id=enteProprietarioId and
    		            capitoloUscGestPrec.bil_id = bilancioPrec.bil_id and
		                tipoCapUscGest.elem_tipo_id=capitoloUscGestPrec.elem_tipo_id and
         	            tipoCapUscGest.elem_tipo_code=bilElemUscGestTipo AND
             	        vincoloBilElem.elem_id=capitoloUscGestPrec.elem_id and
                        vincoloBilElem.data_cancellazione is null and
                        date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',vincoloBilElem.validita_inizio) and
          				(date_trunc('seconds',dataElaborazione)<date_trunc('seconds',vincoloBilElem.validita_fine)
			              or vincoloBilElem.validita_fine is null) and
                        bilancio.bil_id=bilancioId and
                        bilancio.ente_proprietario_id=enteProprietarioId and
		                capitoloUscGest.bil_id = bilancio.bil_id and
	                    tipoCapUscGest.elem_tipo_id=capitoloUscGest.elem_tipo_id and
       		            tipoCapUscGest.elem_tipo_code=bilElemUscGestTipo AND
             		    capitoloUscGest.elem_code=capitoloUscGestPrec.elem_code and
	                    capitoloUscGest.elem_code2=capitoloUscGestPrec.elem_code2 and
      	                capitoloUscGest.elem_code3=capitoloUscGestPrec.elem_code3
                ),
                (select distinct vincoloBilElem.vincolo_id
	             from siac_r_vincolo_bil_elem vincoloBilElem,
           	          siac_t_bil_elem capitoloEntGestPrec, siac_t_bil bilancioPrec,
               	      siac_t_bil_elem capitoloEntGest, siac_d_bil_elem_tipo tipoCapEntGest, siac_t_bil bilancio
	                  where bilancioPrec.bil_id=bilancioPrecId and
		                    bilancioPrec.ente_proprietario_id=enteProprietarioId and
       	  	                capitoloEntGestPrec.bil_id = bilancioPrec.bil_id and
		                    tipoCapEntGest.elem_tipo_id=capitoloEntGestPrec.elem_tipo_id and
		                    tipoCapEntGest.elem_tipo_code=bilElemEntGestTipo AND
           			        vincoloBilElem.elem_id=capitoloEntGestPrec.elem_id and
                            vincoloBilElem.data_cancellazione is null and
	                        date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',vincoloBilElem.validita_inizio) and
    	      				(date_trunc('seconds',dataElaborazione)<date_trunc('seconds',vincoloBilElem.validita_fine)
				              or vincoloBilElem.validita_fine is null) and
                            bilancio.bil_id=bilancioId and
		                    bilancio.ente_proprietario_id=enteProprietarioId and
          		            capitoloEntGest.bil_id = bilancio.bil_id and
          		            tipoCapEntGest.elem_tipo_id=capitoloEntGest.elem_tipo_id and
		                    tipoCapEntGest.elem_tipo_code=bilElemEntGestTipo AND
		                    capitoloEntGest.elem_code=capitoloEntGestPrec.elem_code and
			                capitoloEntGest.elem_code2=capitoloEntGestPrec.elem_code2 and
            	            capitoloEntGest.elem_code3=capitoloEntGestPrec.elem_code3
                 )
            )
    order by vincolo.vincolo_id
    loop


	strMessaggio:='Inserimento Vincolo tipo G '||' '||vincoloGest.vincolo_code||'  da Vincolo gestione Prec id='||vincoloGest.vincolo_id||'.';


	INSERT INTO siac_t_vincolo
	(vincolo_code,vincolo_desc,vincolo_tipo_id,periodo_id,validita_inizio,
	 ente_proprietario_id,data_creazione,login_operazione)
     values
     (vincoloGest.vincolo_code,vincoloGest.vincolo_desc,vincoloTipoId,periodoId,CURRENT_TIMESTAMP,
	  vincoloGest.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
 	 )
     returning vincolo_id into vincoloId;


	strMessaggio:='Inserimento stato op Vincolo tipo G '||' '||vincoloGest.vincolo_code||'  da Vincolo gestione Prec id='||vincoloGest.vincolo_id||'.';

	 -- Inserimento dello stato vincolo Gestione  V-Valido
	 -- dovra esserci un unico elemento valido per lo stato V
	 insert into siac_r_vincolo_stato
     (vincolo_id,vincolo_stato_id,validita_inizio, ente_proprietario_id,
	  data_creazione,login_operazione
	 )
     (select vincoloId,vincoloStato.vincolo_stato_id,CURRENT_TIMESTAMP,vincoloStato.ente_proprietario_id,
      CURRENT_TIMESTAMP,loginOperazione
      from  siac_d_vincolo_stato vincoloStato
      where vincoloStato.elem_stato_code= STATO_VALIDO and
            vincoloStato.ente_proprietario_id=enteProprietarioId and
            vincoloStato.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',vincoloStato.validita_inizio) and
			(date_trunc('seconds',dataElaborazione)<date_trunc('seconds',vincoloStato.validita_fine)
			              or vincoloStato.validita_fine is null)
	 );

	 strMessaggio:='Inserimento attributi Vincolo tipo G '||' '||vincoloGest.vincolo_code||'  da Vincolo gestione Prec id='||vincoloGest.vincolo_id||'.';
	 -- Inserimento degli attributi del vincolo Gestione

 	 insert into siac_r_vincolo_attr
     (  vincolo_id,attr_id,tabella_id,boolean,percentuale,testo,numerico,validita_inizio,
	    ente_proprietario_id,data_creazione,login_operazione
     )
     (select vincoloId,vincoloAttr.attr_id,vincoloAttr.tabella_id,vincoloAttr.boolean,vincoloAttr.percentuale,
     	     vincoloAttr.testo,vincoloAttr.numerico,CURRENT_TIMESTAMP,
	         vincoloAttr.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
     from siac_r_vincolo_attr vincoloAttr, siac_t_attr attrTipi
     where vincoloAttr.vincolo_id= vincoloGest.vincolo_id and
           vincoloAttr.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',vincoloAttr.validita_inizio) and
			(date_trunc('seconds',dataElaborazione)<date_trunc('seconds',vincoloAttr.validita_fine)
			              or vincoloStato.validita_fine is null) and
           attrTipi.attr_id=vincoloAttr.attr_id);

	 strMessaggio:='Inserimento relazioni con Elementi di bilancio di uscita di gestione  Vincolo tipo G '||' '||vincoloPrev.vincolo_code||'  da Vincolo P id='||vincoloPrev.vincolo_id||'.';
	 -- Inserimento delle relazioni con i capitoli di uscita di gestione per il  vincolo Gestione

	 INSERT INTO siac_r_vincolo_bil_elem
	 (vincolo_id, elem_id, validita_inizio,ente_proprietario_id,data_creazione,login_operazione)
	 (select vincoloId, capitoloUscGest.elem_id,CURRENT_TIMESTAMP,vincoloBilElem.ente_proprietario_id,
      CURRENT_TIMESTAMP,loginOperazione
      from   siac_r_vincolo_bil_elem vincoloBilElem,
             siac_t_bil_elem capitoloUscGestPrec, siac_t_bil bilancioPrec,
	         siac_t_bil_elem capitoloUscGest, siac_d_bil_elem_tipo tipoCapUscGest, siac_t_bil bilancio,
             siac_d_bil_elem_stato capitoloStato, siac_r_bil_elem_stato capitoloStatoRel
	  where bilancioPrec.bil_id=bilancioPrecId and
		    bilancioPrec.ente_proprietario_id=enteProprietarioId and
            capitoloUscGestPrec.bil_id = bilancioPrec.bil_id and
            capitoloUscGestPrec.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloUscGestPrec.validita_inizio) and
			(date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloUscGestPrec.validita_fine)
			              or capitoloUscGestPrec.validita_fine is null) and
            capitoloStatoRel.elem_id=capitoloUscGestPrec.elem_id and
            capitoloStato.elem_stato_id=capitoloStatoRel.elem_stato_id and
            capitoloStato.elem_stato_code=STATO_ELEM_VALIDO and
            capitoloStatoRel.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloStatoRel.validita_inizio) and
			(date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloStatoRel.validita_fine)
			              or capitoloStatoRel.validita_fine is null) and
		    tipoCapUscGest.elem_tipo_id=capitoloUscGestPrec.elem_tipo_id and
         	tipoCapUscGest.elem_tipo_code=bilElemUscGestTipo AND
            vincoloBilElem.vincolo_id=vincoloGest.vincolo_id and
            vincoloBilElem.elem_id=capitoloUscGestPrec.elem_id and
			vincoloBilElem.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',vincoloBilElem.validita_inizio) and
			(date_trunc('seconds',dataElaborazione)<date_trunc('seconds',vincoloBilElem.validita_fine)
			              or vincoloBilElem.validita_fine is null) and
            bilancio.bil_id=bilancioId and
		    bilancioPrec.ente_proprietario_id=enteProprietarioId and
		    capitoloUscGest.bil_id = bilancio.bil_id and
	        tipoCapUscGest.elem_tipo_id=capitoloUscGest.elem_tipo_id and
       		tipoCapUscGest.elem_tipo_code=bilElemUscGestTipo AND
            capitoloUscGest.elem_code=capitoloUscGestPrec.elem_code and
	        capitoloUscGest.elem_code2=capitoloUscGestPrec.elem_code2 and
      	    capitoloUscGest.elem_code3=capitoloUscGestPrec.elem_code3);

	 strMessaggio:='Inserimento relazioni con Elementi di bilancio di entrata di gestione  Vincolo tipo G '||' '||vincoloPrev.vincolo_code||'  da Vincolo P id='||vincoloPrev.vincolo_id||'.';
	 -- Inserimento delle relazioni con i capitoli di entrata di gestione per il  vincolo Gestione

	 INSERT INTO siac_r_vincolo_bil_elem
	 (vincolo_id, elem_id, validita_inizio,ente_proprietario_id,data_creazione,login_operazione)
	 (select vincoloId, capitoloEntGest.elem_id,CURRENT_TIMESTAMP,vincoloBilElem.ente_proprietario_id,
      CURRENT_TIMESTAMP,loginOperazione
      from siac_r_vincolo_bil_elem vincoloBilElem,
           siac_t_bil_elem capitoloEntGestPrec,  siac_t_bil bilancioPrec,
   	       siac_t_bil_elem capitoloEntGest, siac_d_bil_elem_tipo tipoCapEntGest, siac_t_bil bilancio,
           siac_d_bil_elem_stato capitoloStato, siac_r_bil_elem_stato capitoloStatoRel
	  where bilancioPrec.bil_id=bilancioPrecId and
	        bilancioPrec.ente_proprietario_id=enteProprietarioId and
            capitoloEntGestPrec.bil_id = bilancioPrec.bil_id and
		    tipoCapEntGest.elem_tipo_id=capitoloEntGestPrec.elem_tipo_id and
		    tipoCapEntGest.elem_tipo_code=bilElemEntGestTipo AND
            capitoloStatoRel.elem_id=capitoloEntGestPrec.elem_id and
            capitoloStato.elem_stato_id=capitoloStatoRel.elem_stato_id and
            capitoloStato.elem_stato_code=STATO_ELEM_VALIDO and
            capitoloStatoRel.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloStatoRel.validita_inizio) and
			(date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloStatoRel.validita_fine)
			              or capitoloStatoRel.validita_fine is null) and
            vincoloBilElem.vincolo_id and
            vincoloBilElem.elem_id=capitoloEntGestPrec.elem_id and
			vincoloBilElem.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',vincoloBilElem.validita_inizio) and
			(date_trunc('seconds',dataElaborazione)<date_trunc('seconds',vincoloBilElem.validita_fine)
			              or vincoloBilElem.validita_fine is null) and
            bilancio.bil_id=bilancioId and
	        bilancio.ente_proprietario_id=enteProprietarioId and
            capitoloEntGest.bil_id = bilancio.bil_id and
            tipoCapEntGest.elem_tipo_id=capitoloEntGest.elem_tipo_id and
		    tipoCapEntGest.elem_tipo_code=bilElemEntGestTipo AND
		    capitoloEntGest.elem_code=capitoloEntGestPrec.elem_code and
		    capitoloEntGest.elem_code2=capitoloEntGestPrec.elem_code2 and
            capitoloEntGest.elem_code3=capitoloEntGestPrec.elem_code3);

     numeroElementiInseriti:=numeroElementiInseriti+1;
   end loop;

   RAISE NOTICE 'NumeroElementiInseriti %', numeroElementiInseriti;

   messaggioRisultato:=strMessaggioFinale||'Inseriti '||numeroElementiInseriti||' vincoli di gestione fra elementi di bilancio.';
   numeroVincoliInseriti:= numeroElementiInseriti;
   return;

exception
	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||'Nessun elemento trovato.' ;
        numeroVincoliInseriti:=0;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        numeroVincoliInseriti:=-1;
        return;
END;
$$ LANGUAGE plpgsql;