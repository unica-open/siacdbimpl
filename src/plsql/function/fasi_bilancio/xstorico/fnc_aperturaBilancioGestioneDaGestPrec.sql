/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 17.02.2014 Sofia 
-- Creazione di capitoli e vincoli di gestione di un bilancio dalla gestione del pluriennale del bilancio precedente
-- Nota. tutto da verificare provare
CREATE OR REPLACE FUNCTION fnc_apeBilancioGestioneDaGestPrec (
  bilancioId integer,
  periodoId integer,
  enteProprietarioId integer,
  bilElemUscGestTipo varchar,
  bilElemEntGestTipo varchar,
  annoBilancio varchar,
  loginOperazione varchar,
  dataElaborazione timestamp,
  codiceRisultato out integer,
  messaggioRisultato out varchar
)
returns record AS
$body$
DECLARE

    numeroElementiInseriti integer:=0;
	strMessaggio varchar(1500):='';

	annoBilancioPrec varchar(4):= ((annoBilancio::INTEGER)-1)::VARCHAR;
	bilancioPrecRec record;

BEGIN
   codiceRisultato:=0;
   messaggioRisultato:='';

   RAISE NOTICE 'LETTURA DATI BILANCIO PRECEDENTE';

   strMessaggio:='Lettura dati bilancio pluriennale anno prec=  '||annoBilancioPrec||'.';

   select  bilancioPrec.bil_id bilancioId, periodoPrec.periodo_id periodoId, periodoPrec.anno anno
   into bilancioPrecRec
   from siac_t_bil bilancioPrec, siac_t_periodo periodoPrec
   where periodoPrec.anno=annoBilancioPrec and
         bilancioPrec.bil_id = periodoPrec.periodo_id and
         bilancioPrec.ente_proprietario_id=enteProprietarioId and
         bilancioPrec.data_cancellazione is null and
         date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',periodoPrec.validita_inizio) and
         (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',periodoPrec.validita_fine)
           or periodoPrec.validita_fine is null) and
         date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',bilancioPrec.validita_inizio) and
         (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',bilancioPrec.validita_fine)
           or bilancioPrec.validita_fine is null);

   RAISE NOTICE 'CAPITOLI USCITA';
   select * into numeroElementiInseriti,strMessaggio
   from   fnc_creaCapitoloGestioneDaGestPrec(bilancioId,periodoId,
  											 bilancioPrecRec.bilancioId,
   											 enteProprietarioId,
                                      		 'U',bilElemUscGestTipo,
                                       	      annoBilancio, loginOperazione,dataElaborazione);

   RAISE NOTICE 'numeroCapUscInseriti % - %', numeroElementiInseriti,strMessaggio;

   if numeroElementiInseriti=-1 then
    codiceRisultato:=-1;
   end if;

   if codiceRisultato=0 then
    RAISE NOTICE 'CAPITOLI ENTRATA';
    select * into numeroElementiInseriti,strMessaggio
    from   fnc_creaCapitoloGestioneDaGestPrec(bilancioId,periodoId,
   											  bilancioPrecRec.bilancioId,
    										  enteProprietarioId,
                                      		  'E',bilElemEntGestTipo,
                                       	      annoBilancio, loginOperazione,dataElaborazione);

    RAISE NOTICE 'numeroCapEntInseriti % - %', numeroElementiInseriti,strMessaggio;

    if numeroElementiInseriti=-1 then
     codiceRisultato:=-1;
    end if;

    end if;

   if codiceRisultato=0 then
	   RAISE NOTICE 'VINCOLI CAPITOLO ';
	   select *  into numeroElementiInseriti, strMessaggio
       from fnc_creaVincoliCapitoloGestioneDaGestPrec(bilancioId,periodoId,
											      bilancioPrecRec.bilancioId,
                                                  bilancioPrecRec.periodoId,
									  			  enteProprietarioId,
            	                                  bilElemUscGestTipo,bilElemEntGestTipo,
                	                              annoBilancio,loginOperazione,dataElaborazione);

      RAISE NOTICE 'numeroVincoliInseriti % - %', numeroElementiInseriti,strMessaggio;

      if numeroElementiInseriti=-1 then
	     codiceRisultato:=-1;
	  end if;
   end if;


   if codiceRisultato=0 then
	   messaggioRisultato:='Creazione Capitoli e Vincoli Gestione OK';
   else
	   messaggioRisultato:=strMessaggio;
   end if;

   return;

exception
	when others  THEN
    	if strMessaggio='' then
	        raise notice 'Creazione Capitoli e Vincoli Gestione KO.Errore DB % %',SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
	        messaggioRisultato:='Creazione Capitoli e Vincoli Gestione KO.Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50);
        else
			raise notice 'Creazione Capitoli e Vincoli Gestione KO.% % %',strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
	        messaggioRisultato:='Creazione Capitoli e Vincoli Gestione KO.'||strMessaggio||' '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50);
        end if;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;