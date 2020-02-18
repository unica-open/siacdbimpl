/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 17.02.2014 Sofia
-- Creazione dei Vincoli Capitolo di Gestione
-- Partendo da quelli di Previsione dello stesso bilancio
CREATE or replace FUNCTION fnc_creaVincoliCapitoloGestioneDaPrev(bilancioId in integer, periodoId IN integer ,enteProprietarioId in integer,
                                                      bilElemUscPrevTipo in varchar, bilElemUscGestTipo in varchar,
                                                      bilElemEntPrevTipo in varchar, bilElemEntGestTipo in varchar,
                                                      annoBilancio in VARCHAR, loginOperazione  in VARCHAR,
                                                      dataElaborazione timestamp,
                                                      numeroVincoliInseriti out integer, messaggioRisultato out varchar)
AS $$
DECLARE

    vincoloId integer := 0;
	vincoloTipoId integer := 0;

    numeroElementiInseriti integer:=0;
    vincoloPrev record;

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

    -- costanti
    -- Stato operativo valido
    STATO_VALIDO CONSTANT  varchar :='V';
    TIPO_VINCOLO_P CONSTANT varchar :='P';
    TIPO_VINCOLO_G CONSTANT varchar :='G';

	STATO_ELEM_VALIDO CONSTANT  varchar :='VA';

BEGIN

    RAISE NOTICE 'Inizio creazione Vincoli Capitolo tipo=G da tipo=P ';

    numeroVincoliInseriti:=0;
    messaggioRisultato:='';

	strMessaggioFinale:='Inserimento Vincoli Capitolo  tipo P a G.';

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
    for vincoloPrev in
     select vincolo.*
	 from siac_t_vincolo vincolo, siac_d_vincolo_stato statoVincolo,siac_r_vincolo_stato  statoVincoloRel,
          siac_d_vincolo_tipo tipoVincolo
	 where vincolo.periodo_id = periodoId and vincolo.ente_proprietario_id=enteProprietarioId and
     	   vincolo.vincolo_tipo_id = tipoVincolo.vincolo_tipo_id and
           vincolo.data_cancellazione is null and
		   date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',vincolo.validita_inizio) and
            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',vincolo.validita_fine)
              or vincolo.validita_fine is null) and
           tipovincolo.vincolo_tipo_code=TIPO_VINCOLO_P and
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
               	      siac_t_bil_elem capitoloUscPrev, siac_d_bil_elem_tipo tipoCapUscPrev,
	                  siac_t_bil_elem capitoloUscGest, siac_d_bil_elem_tipo tipoCapUscGest, siac_t_bil bilancio
	              where bilancio.bil_id=bilancioId and
	                    bilancio.ente_proprietario_id=enteProprietarioId and
    		            capitoloUscPrev.bil_id = bilancio.bil_id and
		                tipoCapUscPrev.elem_tipo_id=capitoloUscPrev.elem_tipo_id and
         	            tipoCapUscPrev.elem_tipo_code=bilElemUscPrevTipo AND
             	        vincoloBilElem.elem_id=capitoloUscPrev.elem_id and
                        vincoloBilElem.data_cancellazione is null and
                        date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',vincoloBilElem.validita_inizio) and
          				(date_trunc('seconds',dataElaborazione)<date_trunc('seconds',vincoloBilElem.validita_fine)
			              or vincoloBilElem.validita_fine is null) and
		                capitoloUscGest.bil_id = bilancio.bil_id and
	                    tipoCapUscGest.elem_tipo_id=capitoloUscGest.elem_tipo_id and
       		            tipoCapUscGest.elem_tipo_code=bilElemUscGestTipo AND
             		    capitoloUscGest.elem_code=capitoloUscPrev.elem_code and
	                    capitoloUscGest.elem_code2=capitoloUscPrev.elem_code2 and
      	                capitoloUscGest.elem_code3=capitoloUscPrev.elem_code3
                ),
                (select distinct vincoloBilElem.vincolo_id
	             from siac_r_vincolo_bil_elem vincoloBilElem,
           	          siac_t_bil_elem capitoloEntPrev, siac_d_bil_elem_tipo tipoCapEntPrev,
               	      siac_t_bil_elem capitoloEntGest, siac_d_bil_elem_tipo tipoCapEntGest, siac_t_bil bilancio
	                  where bilancio.bil_id=bilancioId and
	                      	bilancio.ente_proprietario_id=enteProprietarioId and
       	  	                capitoloEntPrev.bil_id = bilancio.bil_id and
		                    tipoCapEntPrev.elem_tipo_id=capitoloEntPrev.elem_tipo_id and
		                    tipoCapEntPrev.elem_tipo_code=bilElemEntPrevTipo AND
           			        vincoloBilElem.elem_id=capitoloEntPrev.elem_id and
                            vincoloBilElem.data_cancellazione is null and
	                        date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',vincoloBilElem.validita_inizio) and
    	      				(date_trunc('seconds',dataElaborazione)<date_trunc('seconds',vincoloBilElem.validita_fine)
				              or vincoloBilElem.validita_fine is null) and
          		            capitoloEntGest.bil_id = bilancio.bil_id and
          		            tipoCapEntGest.elem_tipo_id=capitoloEntGest.elem_tipo_id and
		                    tipoCapEntGest.elem_tipo_code=bilElemEntGestTipo AND
		                    capitoloEntGest.elem_code=capitoloEntPrev.elem_code and
			                capitoloEntGest.elem_code2=capitoloEntPrev.elem_code2 and
            	            capitoloEntGest.elem_code3=capitoloEntPrev.elem_code3
                 )
            )
    order by vincolo.vincolo_id
    loop


	strMessaggio:='Inserimento Vincolo tipo G '||' '||vincoloPrev.vincolo_code||'  da Vincolo P id='||vincoloPrev.vincolo_id||'.';


	INSERT INTO siac_t_vincolo
	(vincolo_code,vincolo_desc,vincolo_tipo_id,periodo_id,validita_inizio,
	 ente_proprietario_id,data_creazione,login_operazione)
     values
     (vincoloPrev.vincolo_code,vincoloPrev.vincolo_desc,vincoloTipoId,vincoloPrev.periodo_id,CURRENT_TIMESTAMP,
	  vincoloPrev.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
 	 )
     returning vincolo_id into vincoloId;


	strMessaggio:='Inserimento stato op Vincolo tipo G '||' '||vincoloPrev.vincolo_code||'  da Vincolo P id='||vincoloPrev.vincolo_id||'.';

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

	 strMessaggio:='Inserimento attributi Vincolo tipo G '||' '||vincoloPrev.vincolo_code||'  da Vincolo P id='||vincoloPrev.vincolo_id||'.';
	 -- Inserimento degli attributi del vincolo Gestione

 	 insert into siac_r_vincolo_attr
     (  vincolo_id,attr_id,tabella_id,boolean,percentuale,testo,numerico,validita_inizio,
	    ente_proprietario_id,data_creazione,login_operazione
     )
     (select vincoloId,vincoloAttr.attr_id,vincoloAttr.tabella_id,vincoloAttr.boolean,vincoloAttr.percentuale,
     	     vincoloAttr.testo,vincoloAttr.numerico,CURRENT_TIMESTAMP,
	         vincoloAttr.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
     from siac_r_vincolo_attr vincoloAttr, siac_t_attr attrTipi
     where vincoloAttr.vincolo_id= vincoloPrev.vincolo_id and
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
             siac_t_bil_elem capitoloUscPrev, siac_d_bil_elem_tipo tipoCapUscPrev,
	         siac_t_bil_elem capitoloUscGest, siac_d_bil_elem_tipo tipoCapUscGest, siac_t_bil bilancio,
             siac_d_bil_elem_stato capitoloStato, siac_r_bil_elem_stato capitoloStatoRel
	  where bilancio.bil_id=bilancioId and
	      	bilancio.ente_proprietario_id=enteProprietarioId and
            capitoloUscPrev.bil_id = bilancio.bil_id and
            capitoloUscPrev.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloUscPrev.validita_inizio) and
			(date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloUscPrev.validita_fine)
			              or capitoloUscPrev.validita_fine is null) and
            capitoloStatoRel.elem_id=capitoloUscPrev.elem_id and
            capitoloStato.elem_stato_id=capitoloStatoRel.elem_stato_id and
            capitoloStato.elem_stato_code=STATO_ELEM_VALIDO and
            capitoloStatoRel.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloStatoRel.validita_inizio) and
			(date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloStatoRel.validita_fine)
			              or capitoloStatoRel.validita_fine is null) and
		    tipoCapUscPrev.elem_tipo_id=capitoloUscPrev.elem_tipo_id and
         	tipoCapUscPrev.elem_tipo_code=bilElemUscPrevTipo AND
            vincoloBilElem.vincolo_id=vincoloPrev.vincolo_id and
            vincoloBilElem.elem_id=capitoloUscPrev.elem_id and
			vincoloBilElem.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',vincoloBilElem.validita_inizio) and
			(date_trunc('seconds',dataElaborazione)<date_trunc('seconds',vincoloBilElem.validita_fine)
			              or vincoloBilElem.validita_fine is null) and
		    capitoloUscGest.bil_id = bilancio.bil_id and
	        tipoCapUscGest.elem_tipo_id=capitoloUscGest.elem_tipo_id and
       		tipoCapUscGest.elem_tipo_code=bilElemUscGestTipo AND
            capitoloUscGest.elem_code=capitoloUscPrev.elem_code and
	        capitoloUscGest.elem_code2=capitoloUscPrev.elem_code2 and
      	    capitoloUscGest.elem_code3=capitoloUscPrev.elem_code3);

	 strMessaggio:='Inserimento relazioni con Elementi di bilancio di entrata di gestione  Vincolo tipo G '||' '||vincoloPrev.vincolo_code||'  da Vincolo P id='||vincoloPrev.vincolo_id||'.';
	 -- Inserimento delle relazioni con i capitoli di entrata di gestione per il  vincolo Gestione

	 INSERT INTO siac_r_vincolo_bil_elem
	 (vincolo_id, elem_id, validita_inizio,ente_proprietario_id,data_creazione,login_operazione)
	 (select vincoloId, capitoloEntGest.elem_id,CURRENT_TIMESTAMP,vincoloBilElem.ente_proprietario_id,
      CURRENT_TIMESTAMP,loginOperazione
      from siac_r_vincolo_bil_elem vincoloBilElem,
           siac_t_bil_elem capitoloEntPrev, siac_d_bil_elem_tipo tipoCapEntPrev,
   	       siac_t_bil_elem capitoloEntGest, siac_d_bil_elem_tipo tipoCapEntGest, siac_t_bil bilancio,
           siac_d_bil_elem_stato capitoloStato, siac_r_bil_elem_stato capitoloStatoRel
	  where bilancio.bil_id=bilancioId and
      		bilancio.ente_proprietario_id=enteProprietarioId and
            capitoloEntPrev.bil_id = bilancio.bil_id and
		    tipoCapEntPrev.elem_tipo_id=capitoloEntPrev.elem_tipo_id and
		    tipoCapEntPrev.elem_tipo_code=bilElemEntPrevTipo AND
            capitoloStatoRel.elem_id=capitoloEntPrev.elem_id and
            capitoloStato.elem_stato_id=capitoloStatoRel.elem_stato_id and
            capitoloStato.elem_stato_code=STATO_ELEM_VALIDO and
            capitoloStatoRel.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloStatoRel.validita_inizio) and
			(date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloStatoRel.validita_fine)
			              or capitoloStatoRel.validita_fine is null) and
            vincoloBilElem.vincolo_id=vincoloPrev.vincolo_id and
            vincoloBilElem.elem_id=capitoloEntPrev.elem_id and
			vincoloBilElem.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',vincoloBilElem.validita_inizio) and
			(date_trunc('seconds',dataElaborazione)<date_trunc('seconds',vincoloBilElem.validita_fine)
			              or vincoloBilElem.validita_fine is null) and
            capitoloEntGest.bil_id = bilancio.bil_id and
            tipoCapEntGest.elem_tipo_id=capitoloEntGest.elem_tipo_id and
		    tipoCapEntGest.elem_tipo_code=bilElemEntGestTipo AND
		    capitoloEntGest.elem_code=capitoloEntPrev.elem_code and
		    capitoloEntGest.elem_code2=capitoloEntPrev.elem_code2 and
            capitoloEntGest.elem_code3=capitoloEntPrev.elem_code3);

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