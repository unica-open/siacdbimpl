/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 17.02.2014 Sofia -- da completare per i punti 1,2,5,6,7,9 e da verificare in generale per tutto
-- Apertura Bilancio in esercizio provvisorio
-- 1 Gestione dello stato di elaborazione e dei passi
-- 2 Esecuzione di ciascun passo da 'DA ESEGUIRE'
-- 3 Predisposizione Esercizio ( non servirà poichè la codifiche non sono annualizzate )
-- 4 Apertura Esercizio Provvisorio in base al tipo di parametro passato ( L,P)
-- 5 Passaggio Pluriennali
-- 6 Passaggio Residui
-- 7 Altro - Liquidazioni Residue e documenti-predocumenti
-- 8 Aggiornamento Fase e Stato Provvisorio
-- 9 Chiusura Elaborazione
CREATE OR REPLACE FUNCTION fnc_apeBilancioEsercizioProvvisorio (
  annoBilancio varchar,
  annoAttoAmm varchar,
  numeroAttoAmm varchar,
  tipoAttoAmm varchar,
  strutturaAttoAmm varchar,
  enteProprietarioId integer,
  tipoApertura varchar,
  loginOperazione varchar,
  dataElaborazione varchar,
  codiceRisultato out integer,
  messaggioRisultato out varchar
)
returns record AS
$body$
DECLARE

 	statoBilancioRec record;

	strMessaggioFinale VARCHAR(2500):='';
    codiceErrore integer :=0;
	strMessaggio varchar(1500):='';


    dataElabTimeStamp TIMESTAMP:= dataElaborazione::TIMESTAMP;

    -- costanti
    -- FASI BILANCIO ( andrebbero lette a sistema, legate al tipo di elaborazione )
	FASE_PLURIENNALE CONSTANT varchar :='L';
	FASE_PREVISIONE CONSTANT varchar :='P';

    -- TIPI ELEMENTI DI BIALNCIO ( andrebbero letti a sistema )
    BIL_ELEM_USC_PREV CONSTANT varchar :='CAP-UP';
    BIL_ELEM_USC_GEST CONSTANT varchar :='CAP-UG';
    BIL_ELEM_ENT_PREV CONSTANT varchar :='CAP-EP';
    BIL_ELEM_ENT_GEST CONSTANT varchar :='CAP-EG';



BEGIN
   codiceRisultato:=0;
   messaggioRisultato:='';

   RAISE NOTICE 'APERTURA ESERCIZIO PROVVISORIO ANNO=% TIPO APE=% ENTE=% ',annoBilancio,tipoApertura,enteProprietarioId ;
   strMessaggioFinale:='Apertura esercizio provvisorio anno '||annoBilancio||' tipo apertura '||tipoApertura||' ente '||enteProprietarioId||'.';

   raise notice 'data % ',dataElabTimeStamp;
  -- raise notice 'data1 % ',dataElabTimeStamp1;

   -- Lettura dati del bilancio ( fase e stato attuale)
   strMessaggio:='Lettura dati bilancio ( fase e stato attuale).';
   select bilancio.bil_id bilancioId, periodo.periodo_id periodoId,
   	      faseBilancio.fase_operativa_code codiceFase, statoBilancio.bil_stato_op_code codiceStato
          into statoBilancioRec
   from siac_t_bil bilancio, siac_t_periodo periodo,
	    siac_d_fase_operativa faseBilancio, siac_d_bil_stato_op statoBilancio,
        siac_r_bil_fase_operativa faseBilancioRel, siac_r_bil_stato_op statoBilancioRel
   where bilancio.ente_proprietario_id=enteProprietarioId and
   	     bilancio.periodo_id=periodo.periodo_id and
         periodo.anno=annoBilancio and
         periodo.data_cancellazione is null and
		 date_trunc('seconds',dataElabTimeStamp)>=date_trunc('seconds',periodo.validita_inizio) and
         (date_trunc('seconds',dataElabTimeStamp)<date_trunc('seconds',periodo.validita_fine)
            or periodo.validita_fine is null) and
         bilancio.data_cancellazione is null and
         date_trunc('seconds',dataElabTimeStamp)>=date_trunc('seconds',bilancio.validita_inizio) and
         (date_trunc('seconds',dataElabTimeStamp)<date_trunc('seconds',bilancio.validita_fine)
            or bilancio.validita_fine is null) and
         statoBilancioRel.bil_id=bilancio.bil_id and
         statoBilancioRel.bil_stato_op_id=statoBilancio.bil_stato_op_id and
         statoBilancioRel.data_cancellazione is null and
         date_trunc('seconds',dataElabTimeStamp)>=date_trunc('seconds',statoBilancioRel.validita_inizio) and
         (date_trunc('seconds',dataElabTimeStamp)<date_trunc('seconds',statoBilancioRel.validita_fine)
            or statoBilancioRel.validita_fine is null) and
         faseBilancioRel.bil_id=bilancio.bil_id and
         faseBilancioRel.fase_operativa_id=faseBilancio.fase_operativa_id and
         faseBilancioRel.data_cancellazione is null and
         date_trunc('seconds',dataElabTimeStamp)>=date_trunc('seconds',faseBilancioRel.validita_inizio) and
         (date_trunc('seconds',dataElabTimeStamp)<date_trunc('seconds',faseBilancioRel.validita_fine)
            or faseBilancioRel.validita_fine is null);


   if statoBilancioRec.codiceFase not in (FASE_PLURIENNALE,FASE_PREVISIONE) then
   	codiceErrore:=-1;
    strMessaggio:='Fase di bilancio '||statoBilancioRec.codiceFase||'non ammessa per l''apertura dell'' esercizio Provvisorio.';
   end if;

   -- Creazione capitoli , vincoli
   if codiceErrore=0 then
   	case tipoApertura
    	when FASE_PLURIENNALE THEN
	    	-- Apertura da pluriennale precedente
	        raise notice 'Creazione elementi di bilancio, vincoli  da Bilancio Pluriennale anno precedente.';
            strMessaggio:='Creazione elementi di bilancio, vincoli  da Bilancio Pluriennale anno precedente.';
       	    select * into codiceErrore,strMessaggio
			from fnc_apeBilancioGestioneDaGestPrec (statoBilancioRec.bilancioId,statoBilancioRec.periodoId,
													enteProprietarioId,
												    BIL_ELEM_USC_GEST,BIL_ELEM_ENT_GEST,
													annoBilancio,loginOperazione,dataElabTimeStamp);
        when FASE_PREVISIONE then
	        -- Apertura da bilancio di previsione
            raise notice 'Creazione elementi di bilancio, viconli da Bilancio di Previsione';
            strMessaggio:='Creazione elementi di bilancio, viconli da Bilancio di Previsione.';
    	    select * into codiceErrore,strMessaggio
        	from fnc_apeBilancioGestioneDaPrev (statoBilancioRec.bilancioId,statoBilancioRec.periodoId,enteProprietarioId,
						  				    	BIL_ELEM_USC_PREV,BIL_ELEM_ENT_PREV,BIL_ELEM_USC_GEST,BIL_ELEM_ENT_GEST,
										        annoBilancio, loginOperazione,dataElabTimeStamp);
    ELSE
    	codiceErrore:=-1;
        strMessaggio:='Tipo Apertura '||tipoApertura||' non prevista.';
    end case;
   end if;


   -- Ribaltamento Pluriennali
   -- Ribaltamento Residui
   -- Ribaltamento Liquidazioni residue
   -- Altri aggiornamenti su documenti e predocumenti

   -- aggiornamento fase e stato bilancio
   if codiceErrore=0 then
   	raise notice 'Aggiornamento fase e stato bilancio';
    strMessaggio:='Aggiornamento fase e stato bilancio.';
 	select *  into codiceErrore,strMessaggio
    from   fnc_apeFaseEsercizioProvvisorio (statoBilancioRec.bilancioId,statoBilancioRec.periodoId,
    									    enteProprietarioId,
                                            annoAttoAmm,numeroAttoAmm,tipoAttoAmm,strutturaAttoAmm,
                                            annoBilancio,loginOperazione,dataElabTimeStamp);
   end if;

   codiceRisultato:= codiceErrore;
   if codiceErrore=0 then
 	messaggioRisultato:=strMessaggioFinale||'Apertura bilancio OK.';
   else
 	messaggioRisultato:=strMessaggioFinale||strMessaggio;
   end if;
	 raise notice' MESSAGGIO FINALE %',messaggioRisultato;
   return;

exception
	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % % ',strMessaggioFinale,strMessaggio,SQLSTATE,
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