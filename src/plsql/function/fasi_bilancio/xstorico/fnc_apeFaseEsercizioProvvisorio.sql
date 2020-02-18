/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 17.02.2014 Sofia - aggiornamento della fase e stato di bilancio per apertura 
-- Esercizio Provvisorio ( fase bilancio )
-- Stato di Esercizio Provvisorio ( stato bilancio ) ricavato in base alla fase/stato di partenza 
-- Attribuzione di un atto amministrativo di approvazione dello stato di bilancio nuovo
-- Nota. da provare e verificare
CREATE OR REPLACE FUNCTION fnc_apeFaseEsercizioProvvisorio (
  bilancioid integer,
  periodoid integer,
  enteproprietarioid integer,
  annoAttoAmm varchar,
  numeroAttoAmm varchar,
  tipoAttoAmm varchar,
  codiceStrutturaAttoAmm varchar,
  annobilancio varchar,
  loginoperazione varchar,
  dataElaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

 statoBilancioRec record;

 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';
 codiceErrore integer :=0;
 codiceStatoNew siac_d_bil_stato_op.bil_stato_op_code%TYPE:='';

 attoAmmId integer:=0;
 strAmmId integer:=0;
 bilBilStatoOpId integer:=0;

 -- FASI BILANCIO ( andrebbero letti a sistema )
 FASE_PLURIENNALE CONSTANT varchar :='L';
 FASE_PREVISIONE CONSTANT varchar :='P';
 FASE_PROVVISORIO CONSTANT varchar :='E';
 -- STATI BILANCIO ( andrebbero letti a sistema e relazionati )
 --- FASE PREVISIONE
 FASE_PREVISIONE_BIL_CAR CONSTANT varchar :='CB';
 FASE_PREVISIONE_BIL_SP CONSTANT varchar :='SP';
 FASE_PREVISIONE_BIL_SC CONSTANT varchar :='SC';
 FASE_PREVISIONE_BIL_PN CONSTANT varchar :='PN';
 --- FASE ESERC PROVVISORIO
 FASE_PROVVISORIO_EC CONSTANT varchar :='EC';
 FASE_PROVVISORIO_SE CONSTANT varchar :='SE';
 FASE_PROVVISORIO_EN CONSTANT varchar :='EN';

begin

 RAISE NOTICE 'Aggiornamento fase esercizio provvisorio bilancio id=% anno=%  ', bilancioId,annoBilancio;

 codiceRisultato:=0;
 messaggioRisultato:='';


 strMessaggioFinale:='Aggiornamento fase Eserc. Provvisorio per bilancio anno '||annoBilancio||' Id '||bilancioId||'.';

 if annoAttoAmm is not null and numeroAttoAmm is not null and tipoAttoAmm is not null then
     strMessaggio:='Lettura '||tipoAttoAmm||' Anno '||annoAttoAmm||' Numero '||numeroAttoAmm||'.';
 	 select atto.attoamm_id attoAmmId
	 from siac_t_atto_amm atto, siac_d_atto_amm_tipo attoTipo
	 where attoTipo.attoamm_tipo_id=atto.attoamm_tipo_id and  atto.ente_proprietario_id=enteProprietarioId and
	       atto.attoamm_anno=annoAttoAmm and atto.attoamm_numero=numeroAttoAmm and
           attoTipo.attoamm_tipo_code=tipoAttoAmm and
           atto.data_cancellazione is not null and
           date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',atto.validita_inizio) and
       	   (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',atto.validita_fine)
	          or atto.validita_fine is null);

     if codiceStrutturaAttoAmm is not null then
         strMessaggio:=strMessaggio||'Struttura Amm '||codiceStrutturaAttoAmm||'.';
		 select  attoStrAmm.classif_id strAmmId
		 from siac_r_atto_amm_class attoStrAmmRel,
		 	  fnc_getclassificatoregerarchico(enteProprietarioId,null,'Struttura Amministrativa Contabile',codiceStrutturaAttoAmm) attoStrAmm
		 where  attoStrAmmRel.attoamm_id=attoAmmId and
		        attoStrAmmRel.data_cancellazione is not null and
        	    date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',attoStrAmmRel.validita_inizio) and
	       	    (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',attoStrAmmRel.validita_fine)
		          or attoStrAmmRel.validita_fine is null);
     end if;

 end if;


 strMessaggio:='Lettura fase e stato attuali.';

 select faseBilancio.fase_operativa_code codiceFase,statoBilancio.bil_stato_op_code codiceStato,
  	    faseBilancioRel.bil_fase_operativa_id faseBilancioId, statoBilancioRel.bil_bil_stato_op_id statoBilancioId
	    into statoBilancioRec
 from siac_t_bil bilancio, siac_d_bil_stato_op statoBilancio,siac_r_bil_stato_op statoBilancioRel,
      siac_d_fase_operativa faseBilancio, siac_r_bil_fase_operativa faseBilancioRel
 where bilancio.bil_id=bilancioId and
       bilancio.data_cancellazione is null and
       date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',bilancio.validita_inizio) and
         (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',bilancio.validita_fine)
            or bilancio.validita_fine is null) and
       faseBilancioRel.bil_id=bilancio.bil_id and
       faseBilancio.fase_operativa_id=faseBilancioRel.fase_operativa_id and
       faseBilancioRel.data_cancellazione is null and
       date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',faseBilancioRel.validita_inizio) and
       (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',faseBilancioRel.validita_fine)
          or faseBilancioRel.validita_fine is null) and
       statoBilancioRel.bil_id=bilancio.bil_id and
       statoBilancio.bil_stato_op_id=statoBilancioRel.bil_stato_op_id and
       statoBilancioRel.data_cancellazione is null and
       date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',statoBilancioRel.validita_inizio) and
       (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',statoBilancioRel.validita_fine)
          or statoBilancioRel.validita_fine is null);

 case statoBilancioRec.codiceFase
	when FASE_PLURIENNALE then
    	codiceStatoNew:=FASE_PROVVISORIO_EC;
    when FASE_PREVISIONE then
    	case statoBilancioRec.codiceStato
        	when FASE_PREVISIONE_BIL_CAR then
            	codiceStatoNew:=FASE_PROVVISORIO_EC;
            when FASE_PREVISIONE_BIL_SP, FASE_PREVISIONE_BIL_SC then
            	codiceStatoNew:=FASE_PROVVISORIO_SE;
            when FASE_PREVISIONE_BIL_PN then
                codiceStatoNew:=FASE_PROVVISORIO_EN;
            else
            	-- stato bilancio non ammesso
                codiceErrore:=-1;
                strMessaggio:='Stato bilancio '||statoBilancioRec.codiceStato||' non ammesso per l''apertura del provvisorio';
        end case;
    else
    	-- fase non ammessa
        codiceErrore:=-1;
        strMessaggio:='Fase bilancio '||statoBilancioRec.codiceFase||' non ammessa per l''apertura del provvisorio';
 end case;

 if codiceErrore=0 then
	-- Apertura della nuova fase di esercizio provvisorio
    -- Verificare come portarsi dietro eventualmente l'atto amministrativo
    strMessaggio:='Inserimento fase bilancio '||FASE_PROVVISORIO||'.';
	INSERT INTO siac_r_bil_fase_operativa
	(bil_id,fase_operativa_id,validita_inizio,ente_proprietario_id,
	 data_creazione, login_operazione
    )
    (select bilancioId,faseBilancioProvv.fase_operativa_id,CURRENT_TIMESTAMP,
     faseBilancioProvv.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
     from siac_d_fase_operativa faseBilancioProvv
     where faseBilancioProvv.fase_operativa_code=FASE_PROVVISORIO and
           faseBilancioProvv.ente_proprietario_id= enteProprietarioId and
           faseBilancioProvv.data_cancellazione is null and
           date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',faseBilancioProvv.validita_inizio) and
	       (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',faseBilancioProvv.validita_fine)
    	      or faseBilancioProvv.validita_fine is null));

    -- Apertura della nuova fase di esercizio provvisorio , nuovo stato
	strMessaggio:='Inserimento stato bilancio '||codiceStatoNew||'.';
	INSERT INTO siac_r_bil_stato_op
    (bil_id,bil_stato_op_id,validita_inizio,ente_proprietario_id, data_creazione,login_operazione)
	(
    	select bilancioId,statoBilancioProvv.bil_stato_op_id, CURRENT_TIMESTAMP,
               statoBilancioProvv.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
        from siac_d_bil_stato_op statoBilancioProvv
        where statoBilancioProvv.bil_stato_op_code=codiceStatoNew and
              statoBilancioProvv.ente_proprietario_id=enteProprietarioId and
              statoBilancioProvv.data_cancellazione is null and
			  date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',statoBilancioProvv.validita_inizio) and
		      (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',statoBilancioProvv.validita_fine)
    	      	or statoBilancioProvv.validita_fine is null)
     )
     returning bil_bil_stato_op_id into bilBilStatoOpId ;

	if attoAmmId !=0 then
	    strMessaggio:='Inserimento stato bilancio '||codiceStatoNew||' atto amministrativo id='||attoAmmId;
    	insert into siac_r_bil_stato_op_atto_amm
        (bil_bil_stato_op_id,attoamm_id,ente_proprietario_id,data_creazione,validita_inizio,login_operazione)
        values
        (bilBilStatoOpId,attoAmmId,enteProprietarioId,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,loginOperazione);
    end if;

    -- Aggiornamento fase, stato esercizio per chiusura precedenti
	strMessaggio:='Chiusura stato bilancio per apertura nuovo stato '||codiceStatoNew||'.';
    update siac_r_bil_stato_op  set
           validita_fine = CURRENT_TIMESTAMP,login_operazione=loginOperazione,data_modifica=CURRENT_TIMESTAMP
    where bil_bil_stato_op_id= statoBilancioRec.statoBilancioId;

	strMessaggio:='Chiusura fase bilancio per apertura nuova fase '||FASE_PROVVISORIO||'.';
    update siac_r_bil_fase_operativa  set
           validita_fine = CURRENT_TIMESTAMP,login_operazione=loginOperazione,data_modifica=CURRENT_TIMESTAMP
    where bil_fase_operativa_id=statoBilancioRec.faseBilancioId;
 end if;

 codiceRisultato:= codiceErrore;
 if codiceErrore=0 then
 	messaggioRisultato:=strMessaggioFinale||'Aperto in stato bilancio '||codiceStatoNew||'.';
 else
 	messaggioRisultato:=strMessaggioFinale||strMessaggio;
 end if;

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
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;