/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 17.11.2016 Sofia - apertura delle liquidazioni, portando contestualmente i residui relativi
-- per ora non utilizzata
-- differisce per la chiamata a
-- fnc_fasi_bil_gest_apertura_liq_popola_imp ( differente da fnc_fasi_bil_gest_apertura_imp_popola )
-- fnc_fasi_bil_gest_apertura_liq_popola ( chiamata con un idElab già calcolato )
-- fnc_fasi_bil_gest_apertura_liq_elabora_imp ( chiamata con tipoElab=APE_GEST_LIQ_RES)
-- in caso comunque sarebbero da vedere
-- nella fnc_fasi_bil_gest_apertura_liq non vengono lanciate le fnc relative agli impegni

CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_impliq
(
  annobilancio           integer,
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

	codResult         integer:=null;
    faseBilElabId     integer:=null;

    strRec record;

    APE_GEST_LIQ_RES  CONSTANT varchar:='APE_GEST_LIQ_RES';


BEGIN
	messaggioRisultato:='';
    codiceRisultato:=0;
    faseBilElabIdRet:=0;


	strMessaggioFinale:='Apertura bilancio gestione per Anno bilancio='||annoBilancio::varchar||
                        '. Ribaltamento liquidazioni residue.';

	strmessaggio:='Calcola impegni residui da creare.';
    select * into strRec
    from fnc_fasi_bil_gest_apertura_liq_popola_imp
    (enteproprietarioid,
     annobilancio,
     loginoperazione,
	 dataelaborazione
    );
    if strRec.codiceRisultato=0 then
    	faseBilElabId:=strRec.faseBilElabRetId;
    else
        strMessaggio:=strRec.messaggioRisultato;
        codiceRisultato:=strRec.codiceRisultato;
    end if;

    if codiceRisultato=0 and faseBilElabId is not null then
    	strMessaggio:='Calcola liquidazioni residue da creare.';
        select * into strRec
    	from fnc_fasi_bil_gest_apertura_liq_popola
        (enteProprietarioId,
	     annoBilancio,
	     faseBilElabId,
	     loginOperazione,
	     dataElaborazione
        );
        if strRec.codiceRisultato!=0 then
	        strMessaggio:=strRec.messaggioRisultato;
    	    codiceRisultato:=strRec.codiceRisultato;
	    end if;
    end if;

    if codiceRisultato=0 and faseBilElabId is not null then
        strMessaggio:='Crea impegni residui.';
    	select * into strRec
	    from fnc_fasi_bil_gest_apertura_liq_elabora_imp
        (enteProprietarioId,
	     annoBilancio,
         APE_GEST_LIQ_RES,
	     faseBilElabId,
		 0,--minId,
		 0,--maxId
	     loginOperazione,
	     dataElaborazione
        );
        if strRec.codiceRisultato!=0 then
	        strMessaggio:=strRec.messaggioRisultato;
    	    codiceRisultato:=strRec.codiceRisultato;
	    end if;
    end if;

    if codiceRisultato=0 and faseBilElabId is not null then
        strMessaggio:='Crea liquidazioni residue.';
    	select * into strRec
	    from fnc_fasi_bil_gest_apertura_liq_elabora_liq
        (enteProprietarioId,
	     annoBilancio,
	     faseBilElabId,
		 0,--minId,
		 0,--maxId
	     loginOperazione,
	     dataElaborazione
        );
        if strRec.codiceRisultato!=0 then
	        strMessaggio:=strRec.messaggioRisultato;
    	    codiceRisultato:=strRec.codiceRisultato;
	    end if;
    end if;

    if codiceRisultato=0 and faseBilElabId is not null then
	   strMessaggio:='Aggiornamento stato fase bilancio OK.';
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
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_LIQ_RES||'TERMINATA CON SUCCESSO.'
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

    end if;

    if codiceRisultato=0 then
    	messaggioRisultato:=strMessaggioFinale||' Elaborazione terminata con successo.';
        faseBilElabIdRet:=faseBilElabId;
    else messaggioRisultato:=strMessaggioFinale||strMessaggio;
    end if;

    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1000) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1000) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;