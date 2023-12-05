/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 05.12.2016 Sofia ribaltamento vincoli
-- residui e pluriennali
/*drop FUNCTION fnc_fasi_bil_gest_apertura_vincoli
(
  annobilancio           integer,
  enteproprietarioid     integer,
  loginoperazione        varchar,
  dataelaborazione       timestamp,
  out faseBilElabIdRet   integer,
  out codicerisultato    integer,
  out messaggiorisultato varchar
);*/


CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_vincoli
(
  annobilancio           integer,
  enteproprietarioid     integer,
  aggiorna_utilizzabile boolean,
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

	APE_GEST_VINCOLI    CONSTANT varchar:='APE_GEST_VINCOLI';

BEGIN
	messaggioRisultato:='';
    codiceRisultato:=0;
    faseBilElabIdRet:=0;


	strMessaggioFinale:='Apertura bilancio gestione per Anno bilancio='||annoBilancio::varchar||
                        '. Ribaltamento vincoli - residui e pluriennali.';

	strmessaggio:='Popola.';
    select * into strRec
    from fnc_fasi_bil_gest_apertura_vincoli_popola
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
        strMessaggio:='Elabora.';
    	select * into strRec
	    from fnc_fasi_bil_gest_apertura_vincoli_elabora
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

    -- 06.12.2017 Sofia jira siac-5276
    /*if codiceRisultato=0
       and faseBilElabId is not null
       and aggiorna_utilizzabile=true then
        strMessaggio:='Aggiorna Utilizzabile.';
        raise notice '%',strMessaggio;
    	select * into strRec
        from fnc_siac_aggiorna_utilizzabile_acc
        (enteProprietarioId,
	     annoBilancio,
	     loginOperazione,
	     dataElaborazione
        );
        if strRec.codiceRisultato!=0 then
	        strMessaggio:=strRec.messaggioRisultato;
    	    codiceRisultato:=strRec.codiceRisultato;
	    end if;
    else
            raise notice 'Non aggiorna utilizzabile.';
    end if;*/

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
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_VINCOLI||'TERMINATA CON SUCCESSO.'
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