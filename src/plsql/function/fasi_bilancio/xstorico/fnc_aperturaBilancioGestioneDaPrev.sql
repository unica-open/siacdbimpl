/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 17.02.2014 Sofia
-- Creazione di capitoli e vincoli di gestione da previsione dello stesso bilancio
-- Nota. tutto da verificare e provare
CREATE OR REPLACE FUNCTION fnc_apeBilancioGestioneDaPrev (
  bilancioId integer,
  periodoId integer,
  enteProprietarioId integer,
  bilElemUscPrevTipo varchar,
  bilElemEntPrevTipo varchar,
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
    numeroCapUscInseriti integer:=0;
    numeroCapEntInseriti integer:=0;
    numeroVincoliInseriti integer :=0;

	strMessaggio varchar(1500):='';

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

    -- ATTRIBUTI
    FLAG_PER_MEMORIA CONSTANT varchar :='FlagPerMemoria';
    FLAG_ASSEGNABILE CONSTANT varchar :='FlagAssegnabile';

BEGIN
   codiceRisultato:=0;
   messaggioRisultato:='';

   RAISE NOTICE 'CAPITOLI USCITA';

   select * into numeroElementiInseriti,strMessaggio
   from fnc_creaCapitoloGestioneDaPrev(bilancioId,enteProprietarioId,
	                                   'U',bilElemUscPrevTipo,bilElemUscGestTipo,
    	                               annoBilancio,loginOperazione,dataElaborazione);

   RAISE NOTICE 'numeroCapUscInseriti % - %', numeroElementiInseriti,strMessaggio;

   if numeroElementiInseriti=-1 then
    codiceRisultato:=-1;
   end if;

   if codiceRisultato=0 then
    RAISE NOTICE 'CAPITOLI ENTRATA';
    select * into numeroElementiInseriti,strMessaggio
     from fnc_creaCapitoloGestioneDaPrev(bilancioId,enteProprietarioId,
	                                     'E',bilElemEntPrevTipo,bilElemEntGestTipo,
    	                                 annoBilancio,loginOperazione,dataElaborazione);

    RAISE NOTICE 'numeroCapEntInseriti % - %', numeroElementiInseriti,strMessaggio;

    if numeroElementiInseriti=-1 then
     codiceRisultato:=-1;
    end if;

   end if;

   if codiceRisultato=0 then
	   RAISE NOTICE 'VINCOLI CAPITOLO ';
	   select *  into numeroElementiInseriti, strMessaggio
       from fnc_creaVincoliCapitoloGestioneDaPrev(bilancioId,periodoId,enteProprietarioId,
        	                                      bilElemUscPrevTipo,bilElemUscGestTipo,
            	                                  bilElemEntPrevTipo,bilElemEntGestTipo,
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
		raise notice 'Creazione Capitoli e Vincoli Gestione KO.Errore DB % %',SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:='Creazione Capitoli e Vincoli Gestione KO.Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50);
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
