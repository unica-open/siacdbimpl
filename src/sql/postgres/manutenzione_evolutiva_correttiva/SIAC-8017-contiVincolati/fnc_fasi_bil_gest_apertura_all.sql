/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 30.09.2016 Sofia  apertura bilancio di gestione
-- faseBilancio --> E  esercizio provvisorio , da gestione prec a gestine corrente        --> in esercizio provvisorio
--              --> EP esercizio provvisorio , da previsione corrente a gestione corrente --> in esercizio provvisorio
--              --> G  esercizio gestione definitiva, da previsione corrente a gestione corrente --> in gestione definitiva
-- stepPartenza --  step di partenza
--              --  1,99  STEP 1
--              --  >=2   STEP 2
-- STEP 1       -- capitoli di uscita
-- STEP 2       -- capitoli di entrata

drop FUNCTION IF EXISTS siac.fnc_fasi_bil_gest_apertura_all
(
  annobilancio           integer,
  faseBilancio           varchar,
  stepPartenza           integer,
  checkGest              boolean,
  impostaImporti         boolean,
  enteproprietarioid     integer,
  loginoperazione        varchar,
  dataelaborazione       timestamp,
  out faseBilElabIdRet   integer,
  out codicerisultato    integer,
  out messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_all
(
  annobilancio           integer,
  faseBilancio           varchar,
  stepPartenza           integer,
  checkGest              boolean,
  impostaImporti         boolean,
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

    faseBilElabId     integer:=null;

    strRec record;

    CAP_EP_STR          CONSTANT varchar:='CAP-EP';
    CAP_UP_STR          CONSTANT varchar:='CAP-UP';
    CAP_EG_STR          CONSTANT varchar:='CAP-EG';
    CAP_UG_STR          CONSTANT varchar:='CAP-UG';

    U_STR               CONSTANT varchar:='U';
    E_STR               CONSTANT varchar:='E';


BEGIN
	messaggioRisultato:='';
    codiceRisultato:=0;
    faseBilElabIdRet:=0;


	strMessaggioFinale:='Apertura bilancio gestione per Anno bilancio='||annoBilancio::varchar||
                        '. Fase Bilancio di apertura='||faseBilancio||'.';

    if not (stepPartenza=99 or stepPartenza>=1) then
        strMessaggio:='Step ri-partenza non corretto valori ammessi >=1 99.';
        codiceRisultato:=-1;
    end if;

    -- STEP 1 - capitoli di uscita eseguiro per stepPartenza 1, 99
    if stepPartenza=1 or stepPartenza=99 then
 	 strMessaggio:='Capitolo di uscita.';
     select * into strRec
     from fnc_fasi_bil_gest_apertura
     (annobilancio,
      U_STR,
      CAP_UP_STR,
      CAP_UG_STR,
      faseBilancio,
      checkGest,
      impostaImporti,
      enteProprietarioId,
      loginOperazione,
      dataElaborazione
     );
     if strRec.codiceRisultato=0 then
      	faseBilElabId:=strRec.faseBilElabIdRet;
     else
        strMessaggio:=strRec.messaggioRisultato;
        codiceRisultato:=strRec.codiceRisultato;
     end if;
   end if;

   -- STEP 2 - capitoli di entrata eseguiro per stepPartenza >=2
   if codiceRisultato=0 and stepPartenza>=2 then
    	strMessaggio:='Capitolo di entrata.';
    	select * into strRec
	    from fnc_fasi_bil_gest_apertura
    	(annobilancio,
	     E_STR,
    	 CAP_EP_STR,
	     CAP_EG_STR,
	     faseBilancio,
	     checkGest,
     	 impostaImporti,
	     enteProprietarioId,
    	 loginOperazione,
	     dataElaborazione
    	);
        if strRec.codiceRisultato=0 then
      		faseBilElabId:=strRec.faseBilElabIdRet;
	    else
    	    strMessaggio:=strRec.messaggioRisultato;
        	codiceRisultato:=strRec.codiceRisultato;
	    end if;
    end if;

    if codiceRisultato=0 then
    	messaggioRisultato:=strMessaggioFinale||' Elaborazione terminata con successo.';
        faseBilElabIdRet:=faseBilElabId;
    else
    	messaggioRisultato:=strMessaggioFinale||strMessaggio;
    end if;


    -- STEP 3 -- popolamento dei vincoli di gestione
    if codiceRisultato=0 and stepPartenza>=2 then
		strMessaggio:='Ribaltamento vincoli.';
    	if faseBilancio = 'E' then
	    	select * into strRec from fnc_fasi_bil_gest_ribaltamento_vincoli ('GEST-GEST',annobilancio,enteproprietarioid,loginoperazione, dataelaborazione );
		else
			select * into strRec from fnc_fasi_bil_gest_ribaltamento_vincoli ('PREV-GEST',annobilancio,enteproprietarioid,loginoperazione, dataelaborazione );
		end if;

	    if strRec.codiceRisultato=0 then
            faseBilElabId:=strRec.faseBilElabIdRet;
	    else
    	    strMessaggio:=strRec.messaggioRisultato;
        	codiceRisultato:=strRec.codiceRisultato;
	    end if;


    end if;

    -- STEP 4 -- popolamento dei programmi-cronop di gestione
    if codiceRisultato=0 and stepPartenza>=2 then
    	if faseBilancio = 'G' then
            strMessaggio:='Ribaltamento Programmi-Cronoprogrammi di gestione da previsione corrente.';
        	select * into strRec
        	from fnc_fasi_bil_gest_apertura_programmi
	             (
				  annoBilancio,
				  enteProprietarioId,
				  'G',
				  loginOperazione,
				  dataElaborazione
                 );
            if  strRec.codiceRisultato!=0 then
            	strMessaggio:=strRec.messaggioRisultato;
        		codiceRisultato:=strRec.codiceRisultato;
            end if;
        end if;
    end if;

   -- 08.04.2022 Sofia SIAC-8017-CMTO
    -- STEP 6 -- popolamento dei programmi-cronoprogrammi di previsione
	if codiceRisultato=0 and stepPartenza>=2 then    -- deve essere stato eseguito sia spesa che entrata
    	strMessaggio:='Ribaltamento Programmi-Cronoprogrammi di previsione da gestione precedente.';
       	select * into strRec
       	from fnc_fasi_bil_gest_apertura_saldo_sottoconto_vincolo
		(
	     enteProprietarioId,
	     annoBilancio,   -- iniziale
	     annoBilancio-1, -- finale
	     loginOperazione,
	     dataelaborazione);
--       if strRec.codiceRisultato!=0 then
--       	strMessaggio:=strRec.messaggioRisultato;
  --      codiceRisultato:=strRec.codiceRisultato;
    --   end if;
    end if;
    -- 08.04.2022 Sofia SIAC-8017-CMTO
   
    if codiceRisultato=0 then
	   	messaggioRisultato:=strMessaggioFinale||' Elaborazione terminata con successo.';
	    faseBilElabIdRet:=faseBilElabId;
	else
	  	messaggioRisultato:=strMessaggioFinale||strMessaggio;
    end if;

    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION siac.fnc_fasi_bil_gest_apertura_all
(
  integer,
  varchar,
  integer,
  boolean,
  boolean,
  integer,
  varchar,
  timestamp,
  out integer,
  out integer,
  out varchar
) OWNER TO siac;