/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 08.06.2017 Sofia - predocumenti
-- completa predocumenti
-- impegno  ( parametri di input ), derivare provvedimento per ricercare i dati da completare
-- anno  e numero elenco
-- estrarre tutti i predoc in stato incompleto associati al provvedimento o elenco
-- associarli all'impegno e passarli in stato completo
-- (A) annoImpegno,numeroImpegno,numeroSubimpegno : estremi dell'impegno con cui ricercare i dati e completare
-- (B) annoElenco,numeroElenco : estremi dell'elenco  con cui ricercare i dati ( facoltativo )

-- (A) (B) sono alternativi
-- (A) obbligatorio , deve essere esistente e deve avere un provvedimento con cui ricercare i dati da completare
--     usato per completare i dati
-- (B) facoltativo, se indicato deve esistere ed essere usato per ricercare i dati
-- domande.
-- fare controllo disp ???
-- fare controllo  se tutti hanno l'associazione con soggetto , MDP ??


CREATE OR REPLACE FUNCTION fnc_siac_predoc_spesa_completa
 (
  annoImpegno            integer,
  numeroImpegno          integer,
  numeroSubimpegno       integer,
  annoElenco             integer,
  numeroElenco           integer,
  enteproprietarioid     integer,
  annobilancio           integer,
  loginoperazione        varchar,
  dataelaborazione       timestamp,
  out codicerisultato    integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;
  	dataInizioVal     timestamp:=null;

	bilancioId		  integer:=null;
    movgestId         integer:=null;
    movgestTsId       integer:=null;
    attoAmmId         integer:=null;
    eldocId           integer:=null;

    movgestTsTipoCode varchar(10):=null;
    movgestTsTipoId   integer:=null;
    numeroTsCode      integer:=null;



    TIPO_MOVGEST      CONSTANT varchar:='I';
    TIPO_MOVGEST_TS_T CONSTANT varchar:='T';
    TIPO_MOVGEST_TS_S CONSTANT varchar:='S';
    MOVGEST_STATO_A   CONSTANT varchar:='A';


    ELDOC_STATO_R     CONSTANT varchar:='R';
    PREDOC_STATO_I    CONSTANT varchar:='I';
    PREDOC_STATO_C    CONSTANT varchar:='C';
    ATTOAMM_STATO_ANNULLATO CONSTANT varchar:='ANNULLATO';

BEGIN

  codiceRisultato:=null;
  messaggioRisultato:=null;
  dataInizioVal:= clock_timestamp();

  strMessaggioFinale:='Completa predocumenti di spesa '||annoBilancio::varchar||'.';


  -- controllo parametri input
  strMessaggio:='Verifica passaggio enteProprietarioId';
  if enteProprietarioId is null then
  	raise exception ' Dato obbligatorio mancante.';
  end if;

  strMessaggio:='Verifica passaggio annoBilancio.';
  if annoBilancio is null then
  	raise exception ' Dato obbligatorio mancante.';
  end if;

  strMessaggio:='Verifica passaggio estremi impegno.';
  if annoImpegno is null or numeroImpegno is  null then
	raise exception ' Dati obbligatori mancanti.';
  end if;

  strMessaggio:='Verifica passaggio estremi elenco.';
  if  ( annoElenco is not null or numeroElenco is not null ) and
      not ( annoElenco is not null and numeroElenco is not null ) then
  	raise exception ' Dati elenco non completi.';
  end if;


  -- lettura bilancioId
  strMessaggio:='Lettura bilancioId per annoBilancio='||annoBilancio||'.';
  select bil.bil_id into bilancioId
  from siac_t_bil bil , siac_t_periodo per
  where bil.ente_proprietario_id=enteProprietarioId
  and   per.periodo_id=bil.periodo_id
  and   per.anno::integer=annoBilancio;
  if bilancioId is null then
  	raise exception ' Errore in lettura identificativo.';
  end if;

  -- lettura tipo TS
  if coalesce(numeroSubimpegno,0)!=0 then
  		movgestTsTipoCode:=TIPO_MOVGEST_TS_S;
        numeroTsCode:=numeroSubimpegno;
  else
  		movgestTsTipoCode:=TIPO_MOVGEST_TS_T;
        numeroTsCode:=numeroImpegno;
  end if;

  strMessaggio:='Lettura movgestTsTipoId per tipo='||movgestTsTipoCode||'.';
  select tipo.movgest_ts_tipo_id into movgestTsTipoId
  from siac_d_movgest_ts_tipo tipo
  where tipo.ente_proprietario_id=enteProprietarioId
  and   tipo.movgest_ts_tipo_code=movgestTsTipoCode;

  -- lettura impegno
  strMessaggio:='Lettura impegno.';
  select mov.movgest_id, ts.movgest_ts_id into movgestId, movgestTsId
  from siac_t_movgest mov, siac_d_movgest_tipo tipo,
       siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
       siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato
  where mov.bil_id=bilancioId
    and tipo.movgest_tipo_id=mov.movgest_tipo_id
    and tipo.movgest_tipo_code=TIPO_MOVGEST
    and ts.movgest_id=mov.movgest_id
    and tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and tipots.movgest_ts_tipo_code=movgestTsTipoCode
    and mov.movgest_anno::integer=annoImpegno
    and mov.movgest_numero::integer=numeroImpegno
    and ts.movgest_ts_code::integer=numeroTsCode
    and rs.movgest_ts_id=ts.movgest_ts_id
    and stato.movgest_stato_id=rs.movgest_stato_id
    and stato.movgest_stato_code!=MOVGEST_STATO_A
    and mov.data_cancellazione is null
    and mov.validita_fine is null
    and ts.data_cancellazione is null
    and ts.validita_fine is null
    and rs.data_cancellazione is null
    and rs.validita_fine is null;
  if movgestId is null  then
   	raise exception ' Non esistente o non valido.';
  end if;

  strMessaggio:='Lettura identificativo atto amministrativo collegato a impegno.';
  select rs.attoamm_id into attoAmmId
  from siac_r_movgest_ts_atto_amm rs, siac_r_atto_amm_stato rstato, siac_d_atto_amm_stato stato
  where rs.ente_proprietario_id=enteProprietarioId
    and rs.movgest_ts_id=movgestTsId
    and rstato.attoamm_id=rs.attoamm_id
    and stato.attoamm_stato_id=rstato.attoamm_stato_id
    and stato.attoamm_stato_code!=ATTOAMM_STATO_ANNULLATO
    and rs.data_cancellazione is null
    and rs.validita_fine is null
    and rstato.data_cancellazione is null
    and rstato.validita_fine is null;

  if attoAmmId is null then
    	raise exception ' Identificativo non reperito.';
  end if;


  if annoElenco is not null then
  	strMessaggio:='Lettura identificativo elenco predoc.';
  	select e.eldoc_id into eldocId
    from siac_t_elenco_doc e, siac_r_elenco_doc_stato r, siac_d_elenco_doc_stato stato
    where e.ente_proprietario_id=enteProprietarioId
    and   e.eldoc_anno::integer=annoElenco
    and   e.eldoc_numero::integer=numeroElenco
    and   r.eldoc_id=e.eldoc_id
    and   stato.eldoc_stato_id=r.eldoc_stato_id
    and   stato.eldoc_stato_code!=ELDOC_STATO_R
    and   e.data_cancellazione is null
    and   e.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

    if eldocId is null then
    	raise exception ' Identificativo non reperito.';
    end if;
  end if;


  -- verifica esistenza predocumenti da completare

  if eldocId is not null then
  	strMessaggio:='Verifica esistenza predocumenti in stato='||PREDOC_STATO_I
                  ||' collegati all'' elenco '||annoElenco::varchar||'/'||numeroElenco::varchar||'.';
    codResult:=null;
  	select 1 into codResult
    from siac_r_elenco_doc_predoc r,siac_t_predoc predoc,siac_r_predoc_stato rstato, siac_d_predoc_stato stato
    where r.eldoc_id=eldocId
    and   predoc.predoc_id=r.predoc_id
    and   rstato.predoc_id=predoc.predoc_id
    and   stato.predoc_stato_id=rstato.predoc_stato_id
    and   stato.predoc_stato_code=PREDOC_STATO_I
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   predoc.data_cancellazione is null
    and   predoc.validita_fine is null
    and   rstato.data_cancellazione is null
    and   rstato.validita_fine is null;
    if coalesce(codResult,0)=0 then
    	raise exception ' Predocumenti non presenti.';
    end if;

  	strMessaggio:='Inserimento relazione [siac_r_predoc_movgest_ts] tra predocumenti associati all''elenco '
                  ||annoElenco::varchar||'/'||numeroElenco::varchar
                  ||' e l''impegno passato.';
    insert into siac_r_predoc_movgest_ts
    (
     predoc_id,
	 movgest_ts_id,
	 validita_inizio,
     ente_proprietario_id,
	 login_operazione
    )
    select predoc.predoc_id,
           movgestTsId,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
    from siac_r_elenco_doc_predoc r,siac_t_predoc predoc,siac_r_predoc_stato rstato, siac_d_predoc_stato stato
    where r.eldoc_id=eldocId
    and   predoc.predoc_id=r.predoc_id
    and   rstato.predoc_id=predoc.predoc_id
    and   stato.predoc_stato_id=rstato.predoc_stato_id
    and   stato.predoc_stato_code=PREDOC_STATO_I
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   predoc.data_cancellazione is null
    and   predoc.validita_fine is null
    and   rstato.data_cancellazione is null
    and   rstato.validita_fine is null;

	strMessaggio:='Inserimento stato '||PREDOC_STATO_C||' per i predocumenti collegati all''elenco '
    			   ||annoElenco::varchar||'/'||numeroElenco::varchar||'.';
	insert into siac_r_predoc_stato
    (
    	predoc_id,
        predoc_stato_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    select predoc.predoc_id,
           statoC.predoc_stato_id,
           dataInizioVal,
           loginOperazione,
           statoC.ente_proprietario_id
    from siac_r_elenco_doc_predoc r,
         siac_t_predoc predoc, siac_r_predoc_stato rstato,siac_d_predoc_stato stato,
         siac_d_predoc_stato statoC
    where r.eldoc_id=eldocId
    and   predoc.predoc_id=r.predoc_id
    and   rstato.predoc_id=predoc.predoc_id
    and   stato.predoc_stato_id=rstato.predoc_stato_id
    and   stato.predoc_stato_code=PREDOC_STATO_I
    and   statoC.ente_proprietario_id=stato.ente_proprietario_id
    and   statoC.predoc_stato_code=PREDOC_STATO_C
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   predoc.data_cancellazione is null
    and   predoc.validita_fine is null
    and   rstato.data_cancellazione is null
    and   rstato.validita_fine is null;

    strMessaggio:='Chiusura stato '||PREDOC_STATO_I||' per i predocumenti collegati all''elenco '
    			   ||annoElenco::varchar||'/'||numeroElenco::varchar||'.';
    update siac_r_predoc_stato rstato
    set    data_cancellazione=dataElaborazione,
           validita_fine=dataElaborazione,
           login_operazione=rstato.login_operazione||'-'||loginOperazione
    from siac_r_elenco_doc_predoc r,siac_t_predoc predoc, siac_d_predoc_stato stato
    where r.eldoc_id=eldocId
    and   predoc.predoc_id=r.predoc_id
    and   rstato.predoc_id=predoc.predoc_id
    and   stato.predoc_stato_id=rstato.predoc_stato_id
    and   stato.predoc_stato_code=PREDOC_STATO_I
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   predoc.data_cancellazione is null
    and   predoc.validita_fine is null
    and   rstato.data_cancellazione is null
    and   rstato.validita_fine is null;
 end if;

 if codResult is null and attoAmmId is not null then
  	strMessaggio:='Verifica esistenza predocumenti in stato='||PREDOC_STATO_I
                  ||' collegati al provvedimento passato.';
    codResult:=null;
  	select 1 into codResult
    from siac_r_predoc_atto_amm r,siac_t_predoc predoc,siac_r_predoc_stato rstato, siac_d_predoc_stato stato
    where r.attoamm_id=attoAmmId
    and   predoc.predoc_id=r.predoc_id
    and   rstato.predoc_id=predoc.predoc_id
    and   stato.predoc_stato_id=rstato.predoc_stato_id
    and   stato.predoc_stato_code=PREDOC_STATO_I
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   predoc.data_cancellazione is null
    and   predoc.validita_fine is null
    and   rstato.data_cancellazione is null
    and   rstato.validita_fine is null;
    if coalesce(codResult,0)=0 then
    	raise exception ' Predocumenti non presenti.';
    end if;


    strMessaggio:='Inserimento relazione [siac_r_predoc_movgest_ts] tra predocumenti associati al provvedimento di impegno passato.';
    insert into siac_r_predoc_movgest_ts
    (
     predoc_id,
	 movgest_ts_id,
	 validita_inizio,
     ente_proprietario_id,
	 login_operazione
    )
    select predoc.predoc_id,
           movgestTsId,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
    from siac_r_predoc_atto_amm r,siac_t_predoc predoc,siac_r_predoc_stato rstato, siac_d_predoc_stato stato
    where r.attoamm_id=attoAmmId
    and   predoc.predoc_id=r.predoc_id
    and   rstato.predoc_id=predoc.predoc_id
    and   stato.predoc_stato_id=rstato.predoc_stato_id
    and   stato.predoc_stato_code=PREDOC_STATO_I
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   predoc.data_cancellazione is null
    and   predoc.validita_fine is null
    and   rstato.data_cancellazione is null
    and   rstato.validita_fine is null;

	strMessaggio:='Inserimento stato '||PREDOC_STATO_C||' per i predocumenti collegati all'' impegno passato.';
	insert into siac_r_predoc_stato
    (
    	predoc_id,
        predoc_stato_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    select predoc.predoc_id,
           statoC.predoc_stato_id,
           dataInizioVal,
           loginOperazione,
           statoC.ente_proprietario_id
    from siac_r_predoc_atto_amm r,
         siac_t_predoc predoc, siac_r_predoc_stato rstato,siac_d_predoc_stato stato,
         siac_d_predoc_stato statoC
    where r.attoamm_id=attoAmmId
    and   predoc.predoc_id=r.predoc_id
    and   rstato.predoc_id=predoc.predoc_id
    and   stato.predoc_stato_id=rstato.predoc_stato_id
    and   stato.predoc_stato_code=PREDOC_STATO_I
    and   statoC.ente_proprietario_id=stato.ente_proprietario_id
    and   statoC.predoc_stato_code=PREDOC_STATO_C
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   predoc.data_cancellazione is null
    and   predoc.validita_fine is null
    and   rstato.data_cancellazione is null
    and   rstato.validita_fine is null;

    strMessaggio:='Chiusura stato '||PREDOC_STATO_I||' per i predocumenti associati all''impegno passato.';
    update siac_r_predoc_stato rstato
    set    data_cancellazione=dataElaborazione,
           validita_fine=dataElaborazione,
           login_operazione=rstato.login_operazione||'-'||loginOperazione
    from siac_r_predoc_atto_amm r,siac_t_predoc predoc, siac_d_predoc_stato stato
    where r.attoamm_id=attoAmmId
    and   predoc.predoc_id=r.predoc_id
    and   rstato.predoc_id=predoc.predoc_id
    and   stato.predoc_stato_id=rstato.predoc_stato_id
    and   stato.predoc_stato_code=PREDOC_STATO_I
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   predoc.data_cancellazione is null
    and   predoc.validita_fine is null
    and   rstato.data_cancellazione is null
    and   rstato.validita_fine is null;
  end if;


  codiceRisultato:=0;
  messaggioRisultato:=strMessaggioFinale||' Elaborazione terminata.';




  return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
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
        messaggioRisultato:=strMessaggioFinale||strMessaggio||' Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;