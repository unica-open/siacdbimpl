/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


/*drop function if exists fnc_fasi_bil_variazione_gest
(
annobilancio       varchar,
elencoVariazioni   text,
nomeTabella        varchar,
flagCambiaStato    varchar, -- [1,0],[true,false]
flagApplicaVar     varchar, -- [1,0],[true,false]
statoVar           varchar,
enteProprietarioId varchar,
loginoperazione    VARCHAR,
dataelaborazione   TIMESTAMP,
OUT faseBilElabIdRet   varchar,
OUT codiceRisultato    varchar,
OUT messaggioRisultato VARCHAR
);*/
/*
annoBilancio=anno di bilancio delle variazioni da trattare
elencoVariazioni=elenco di numeri di variazione nel forma n1,n2,n3,n4,nn
nomeTabella=nome di una tabella da popolare con l'elenco dei numeri di variazione
--          - deve essere presente il campo variazione_num
--          - se viene valorizzato il par elencoVariazioni, la tabella non viene utilizzata
flagCambiaStato= true se deve essere effettuato il cambiamento di stato, false diversamente
--             - da valorizzarsi come stringha ai valori 1,0 o true,false
flagApplicaVar=true se la variazione deve essere applicata ai capitoli, false diversamente
--             - applicazione effettuata solo in passaggio o conferma dello stato D
--             - da valorizzarsi come stringha ai valori 1,0 o true,false
statoVar=codice dello stato a cui portare o mantenere la variazione
Sono contemplati i seguenti passatti di stato
da B a P
da P a D
da B a D  ( in questo caso si effettua anche il passaggio intermedio a P )
la funzione richiama la function fnc_siac_bko_gestisci_variazione che effettua
il trattamento dati effettivo sulle singole variazioni
*/
drop function if exists siac.fnc_fasi_bil_variazione_gest
(
annobilancio       varchar,
elencoVariazioni   text,
nomeTabella        varchar,
flagCambiaStato    varchar,
flagApplicaVar     varchar,
statoVar           varchar,
enteProprietarioId varchar,
loginoperazione    VARCHAR,
dataelaborazione   TIMESTAMP,
OUT faseBilElabIdRet   varchar,
OUT codiceRisultato    varchar,
OUT messaggioRisultato VARCHAR
);

CREATE OR replace FUNCTION siac.fnc_fasi_bil_variazione_gest
(
annobilancio       varchar,
elencoVariazioni   text,
nomeTabella        varchar,
flagCambiaStato    varchar, -- [1,0],[true,false]
flagApplicaVar     varchar, -- [1,0],[true,false]
statoVar           varchar,
enteProprietarioId varchar,
loginoperazione    VARCHAR,
dataelaborazione   TIMESTAMP,
OUT faseBilElabIdRet   varchar,
OUT codiceRisultato    varchar,
OUT messaggioRisultato VARCHAR
)
returns RECORD
AS
$body$
  DECLARE
   strmessaggio       VARCHAR(1500):='';
   strmessaggiofinale VARCHAR(1500):='';
   codresult          INTEGER:=NULL;
   faseBilElabId         integer:=null;
   faseBilVarGestId      integer:=null;
   varCursor refcursor;
   recVarCursor record;
   strVarCursor varchar:=null;
   recResult record;

   scartoCode varchar(10):=null;
   scartoDesc varchar:=null;
   flagElab   varchar(10):=null;
   variazioneStatoNewId integer:=null;
   variazioneStatoTipoNewId integer:=null;

   elencoVariazioneCur text:='';

   APE_VAR_GEST CONSTANT VARCHAR :='APE_VAR_GEST';
  begin
    messaggiorisultato:='';
    codicerisultato:='0';
    fasebilelabidret:=null;


    strMessaggioFinale:='Variazione bilancio - gestione.';
    raise notice 'strMessaggioFinale=%',strMessaggioFinale;

    raise notice 'nomeTabella=%',      quote_nullable(nomeTabella);
    raise notice 'elencoVariazioni=%', quote_nullable(elencoVariazioni);

    if coalesce(nomeTabella,'')=''  and coalesce(elencoVariazioni,'')='' then
    	strmessaggio:=' Nome tabella e elenco variazione non valorizzati. Impossibile determinare variazioni da trattare.';
        raise exception ' ';
    end if;

    strMessaggio='Inserimento tabella fase_bil_t_elaborazione.';
    raise notice 'strMessaggio=%',strMessaggio;
    insert into  fase_bil_t_elaborazione
    (
    	fase_bil_elab_esito,
        fase_bil_elab_esito_msg,
        fase_bil_elab_tipo_id,
        ente_proprietario_id,
        validita_inizio,
        login_operazione
    )
    select  'IN',
            'ELABORAZIONE FASE BILANCIO '||APE_VAR_GEST||' IN CORSO.',
            tipo.fase_bil_elab_tipo_id,
            tipo.ente_proprietario_id,
            clock_timestamp(),
            loginoperazione
    from fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId::integer
    and   tipo.fase_bil_elab_tipo_code=APE_VAR_GEST
    returning fase_bil_elab_id into codResult;
    if codResult is null then
     strMessaggio:=strMessaggio||' Errore in inserimento - ';
     raise notice 'strMessaggio=%',strMessaggio;
     raise exception ' record non inserito.';
    end if;
    faseBilElabId:=codResult;
    raise notice 'faseBilElabId=%',faseBilElabId;

    if coalesce(elencoVariazioni,'')!='' then
     -- impostazione stringa per ricerca
     raise notice 'elencoVariazioni=%',elencoVariazioni;
     elencoVariazioneCur:=elencoVariazioni;
    else
     -- lettura da tabella
     if coalesce(nomeTabella,'')!='' then
	     raise notice 'Lettura tabella %',nomeTabella;
         strvarcursor:='select * from '||nomeTabella;
         open varCursor for execute strVarCursor;
		    loop
		    fetch varCursor into recVarCursor;
            exit when NOT FOUND;
            if coalesce(elencoVariazioneCur,'')!='' then
             elencoVariazioneCur:=elencoVariazioneCur||',';
            end if;
            elencoVariazioneCur:=elencoVariazioneCur||recVarCursor.variazione_num::varchar;

         end loop;
         close  varCursor;
      end if;
    end if;

    raise notice 'elencoVariazioneCur=%',quote_nullable(elencoVariazioneCur);
	if coalesce(elencoVariazioneCur,'')='' then
      strMessaggio:='Aggiornamento tabella fase_bil_t_elaborazione per errore.Impossibile determinare elenco variazioni da trattare.';
      codResult:=null;
      update fase_bil_t_elaborazione fase
      set    fase_bil_elab_esito='KO',
             fase_bil_elab_esito_msg=
              'ELABORAZIONE FASE BILANCIO '||APE_VAR_GEST||' TERMINATA CON ERRORE.IMPOSSIBILE DETERMINARE VARIAZIONI DA TRATTARE.',
             validita_fine=clock_timestamp(),
             data_modifica=clock_timestamp()
      where fase.fase_bil_elab_id=faseBilElabId
      returning fase.fase_bil_elab_id into codResult;
      if codResult is null then
          raise exception ' Tabella non aggiornata.';
      end if;
    end if;

    strMessaggio:='Preparazione cursore lettura variazioni.';
    raise notice 'strMessaggio=%',strMessaggio;

    strVarCursor:=null;
    varCursor:=null;
    recVarCursor:=null;

    strVarCursor:='select var.variazione_num::integer variazione_num, var.variazione_id, rs.variazione_stato_id, '
                  ||' bil.bil_id,per.anno::integer anno,'
                  ||' stato.variazione_stato_tipo_code, stato.variazione_stato_tipo_id '
                  ||' from siac_t_variazione var,siac_r_variazione_stato rs,siac_d_variazione_stato stato , '
                  ||' siac_t_bil bil,siac_t_periodo per '
                  ||' where stato.ente_proprietario_id='||enteProprietarioId
                  ||' and   stato.variazione_stato_tipo_code!=''A'' '
                  ||' and   rs.variazione_stato_tipo_id=stato.variazione_stato_tipo_id'
                  ||' and   var.variazione_id=rs.variazione_id '
                  ||' and   bil.bil_id=var.bil_id and per.periodo_id=bil.periodo_Id'
                  ||' and   per.anno::integer='||annoBilancio
                  ||' and   var.variazione_num in ('||elencoVariazioneCur||')'
                  ||' and   rs.data_cancellazione is null and rs.validita_fine is null '
                  ||' order by rs.validita_inizio, var.variazione_num::integer';


    raise notice 'strVarCursor=%',strVarCursor;
    strMessaggio:='Apertura cursore lettura variazioni.';
    raise notice 'strMessaggio=%',strMessaggio;
    open varCursor for execute strVarCursor;
    loop
      fetch varCursor into recVarCursor;
      exit when NOT FOUND;

      raise notice 'Variazione num=%',recVarCursor.variazione_num::varchar;

      strMessaggio:='Inserimento tabella fase_bil_t_variazione_gest variazione_numo='||recVarCursor.variazione_num::varchar||'.';
      raise notice 'strMessaggio=%',strMessaggio;

      scartoCode:=null;
      scartoDesc:=null;
      flagElab:='S';
	  variazioneStatoNewId:=null;
      variazioneStatoTipoNewId:=null;
      faseBilVarGestId:=null;
      -- insert into fase_bil_t_variazione_gest
	  insert into fase_bil_t_variazione_gest
      (
      	fase_bil_elab_id,
		variazione_id,
	    bil_id,
	    variazione_stato_id,
	    variazione_stato_tipo_id,
	    fl_cambia_stato,
	    fl_applica_var,
        login_operazione,
        ente_proprietario_id
      )
      values
      (
       faseBilElabId,
       recVarCursor.variazione_id,
       recVarCursor.bil_id,
       recVarCursor.variazione_stato_id,
       recVarCursor.variazione_stato_tipo_id,
       flagCambiaStato::boolean,
       flagApplicaVar::boolean,
       loginOperazione,
       enteProprietarioId::integer
      )
      returning fase_bil_var_gest_id into faseBilVarGestId;
      if faseBilVarGestId is null then
      	strMessaggio:=strMessaggio||' Errore in inserimento - ';
        raise notice 'strMessaggio=%',strMessaggio;
        raise exception ' record non inserito.';
      end if;
      raise notice 'faseBilVarGestId=%', faseBilVarGestId;

	  strMessaggio:='Esecuzione fnc_siac_bko_gestisci_variazione variazione_num='||recVarCursor.variazione_num::varchar||'.';
      raise notice 'strMessaggio=%',strMessaggio;

      select * into recResult
      from fnc_siac_bko_gestisci_variazione
           (
            enteProprietarioId::integer,
            recVarCursor.anno,
            recVarCursor.variazione_num,
            flagCambiaStato::boolean,
            statoVar,
            flagApplicaVar::boolean,
            loginOperazione,
            dataElaborazione
           );

      if recResult.codiceRisultato::integer=0 then
        strMessaggio:='Lettura nuovi identificativi per variazione_num='||recVarCursor.variazione_num::varchar||'.';
        raise notice 'strMessaggio=%',strMessaggio;
      	select rs.variazione_stato_id, stato.variazione_stato_tipo_id
        into   variazioneStatoNewId, variazioneStatoTipoNewId
        from siac_r_variazione_Stato rs,siac_d_variazione_stato stato
        where rs.variazione_id=recVarCursor.variazione_id
        and   stato.variazione_stato_tipo_id=rs.variazione_Stato_tipo_id
        and   rs.data_cancellazione is null
        and   rs.validita_fine is null;
        if variazioneStatoNewId is null or  variazioneStatoTipoNewId is null then
        	variazioneStatoNewId:=null;
            variazioneStatoTipoNewId:=null;
            scartoCode:='02';
       	    scartoDesc:=strMessaggio||strMessaggio||' Errore in lettura.';
            flagElab:='X';
        end if;
      else
        scartoCode:='01';
        scartoDesc:=recResult.messaggioRisultato;
        flagElab:='X';
      end if;

      strMessaggio:='Aggiornamento fase_bil_t_variazione_gest variazione_num='
                   ||recVarCursor.variazione_num::varchar||'flagElab='||flagElab||'.';
      raise notice 'strMessaggio=%',strMessaggio;
      codResult:=null;
   	  update fase_bil_t_variazione_gest fase
      set    scarto_code=scartoCode,
		     scarto_desc=scartoDesc,
             fl_elab=flagElab,
             variazione_stato_new_id=variazioneStatoNewId,
             variazione_stato_tipo_new_id=variazioneStatoTipoNewId
      where  fase.fase_bil_var_gest_id=faseBilVarGestId
      returning fase.fase_bil_var_gest_id into codResult;
      if codResult is null then
      	strMessaggio:=strMessaggio||' Errore in aggiornamento - ';
        raise exception ' record non aggiornato.';
      end if;

    end loop;
    close  varCursor;

    strMessaggio:='Chiusura ciclo-cursore.';
    raise notice 'strMessaggio=%',strMessaggio;

    strMessaggio:='Aggiornamento fase_bil_t_elaborazione termine con successo.';
    raise notice 'strMessaggio=%',strMessaggio;

    codResult:=null;
    update fase_bil_t_elaborazione fase
    set    fase_bil_elab_esito='OK',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_VAR_GEST||' TERMINATA CON SUCCESSO.',
           --validita_fine=clock_timestamp(),
           data_modifica=clock_timestamp()
    where fase.fase_bil_elab_id=faseBilElabId
    returning fase.fase_bil_elab_id into codResult;
    if codResult is null then
    	raise exception ' Tabella non aggiornata.';
    end if;


    if faseBilElabId is not null then
	    faseBilElabIdRet:=faseBilElabId::varchar;
    end if;

    messaggiorisultato:=strMessaggioFinale||strMessaggio;
    codiceRisultato:='0';
    raise notice 'messaggiorisultato=%',messaggiorisultato;
    raise notice 'codiceRisultato=%',codiceRisultato;
    raise notice 'faseBilElabIdRet=%',coalesce(faseBilElabIdRet,' ');


    RETURN;
  EXCEPTION
  WHEN raise_exception THEN

    messaggiorisultato:=strmessaggiofinale
    ||strmessaggio
    ||'ERRORE :'
    ||' '
    ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;


    codicerisultato:='-1';
    raise notice 'codiceRisultato=%',codiceRisultato;
    raise notice 'messaggiorisultato=%',messaggiorisultato;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice ' % % Nessun elemento trovato.' ,strmessaggiofinale,strmessaggio;
    messaggiorisultato:=strmessaggiofinale
    ||strmessaggio
    ||'Nessun elemento trovato.' ;
    codicerisultato:='-1';
    raise notice 'codiceRisultato=%',codiceRisultato;
    raise notice 'messaggiorisultato=%',messaggiorisultato;

    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale
    ||strmessaggio
    ||'Errore DB '
    ||SQLSTATE
    ||' '
    ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:='-1';
    raise notice 'codiceRisultato=%',codiceRisultato;
    raise notice 'messaggiorisultato=%',messaggiorisultato;

    RETURN;
  END;
  $body$ LANGUAGE 'plpgsql' volatile called ON NULL input security invoker cost 100;

alter function siac.fnc_fasi_bil_variazione_gest
(
  varchar,
  text,
  varchar,
  varchar,
  varchar,
  varchar,
  VARCHAR,
  varchar,
  TIMESTAMP,
  OUT varchar,
  OUT varchar,
  OUT  VARCHAR
) owner to siac;