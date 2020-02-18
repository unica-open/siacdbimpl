/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_fase_gen_elaborazione_fineanno (
  enteproprietarioid integer,
  annobilancio integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabretid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;
    faseBilElabId     integer:=null;

    bilancioId        integer:=null;
  	bilancioNextId    integer:=null;

    periodoId         integer:=null;
    periodoNextId     integer:=null;

	dataInizioVal     timestamp:=null;

    eseguiStep        boolean:=false;
	eseguiStepScritture boolean:=true;

	faseOp            varchar(10):=null;

    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';

    LOG_OP_FINE       CONSTANT varchar:='_gen_chiape';

	COSTI_CLASSE      CONSTANT varchar:='CE'; -- costi
    RICAVI_CLASSE     CONSTANT varchar:='RE'; -- ricavi
    ATT_PATR_CLASSE   CONSTANT varchar:='AP'; -- patrimonio attivo
    PAS_PATR_CLASSE   CONSTANT varchar:='PP'; -- patrimonio passivo

    RIS_CONTO_TIPO    CONSTANT varchar:='RIS'; -- risconti

	saldiRec record;
    primaNotaRec record;

    E_FASE            CONSTANT varchar:='E'; -- esercizio provvisorio
    G_FASE            CONSTANT varchar:='G'; -- gestione approvata
    
    contaPasso integer;
    provaRec record;
    
BEGIN
	faseBilElabRetId:=null;
    codiceRisultato:=null;
    messaggioRisultato:=null;

    dataInizioVal:= clock_timestamp();
	contaPasso:=0;
    
	strMessaggioFinale:='Gestione fine anno GEN. Scritture di chiusura/apertura  Anno bilancio='||annoBilancio::varchar||'.';

    strMessaggio:='Lettura identificativo bilancio in chiusura annoBilancio='||annoBilancio::varchar||'.';
    raise notice '%', strMessaggio;
    select bil.bil_id, per.periodo_id into bilancioId, periodoId
    from siac_t_bil bil, siac_t_periodo per, siac_d_bil_tipo tipo
    where bil.ente_proprietario_id=enteProprietarioId
    and   tipo.bil_tipo_id=bil.bil_tipo_id
    and   tipo.bil_tipo_code=BIL_ORD_TIPO
    and   per.periodo_id=bil.periodo_id
    and   per.anno::integer=annoBilancio;
	raise notice 'FINE %', strMessaggio;
    strMessaggio:='Verifica esecuzione elaborazione fine anno per annoBilancio='||annoBilancio::VARCHAR||'.';
    raise notice '%', strMessaggio;
    select 1 into codResult
    from fase_gen_t_elaborazione_fineanno fase
    where fase.ente_proprietario_id=enteProprietarioId
    and   fase.bil_id=bilancioId
    and   fase.fase_gen_elab_esito='OK'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;
raise notice 'FINE %', strMessaggio;
    if codResult is not null then
    	raise exception ' Registrazione scritture fine anno gia'' eseguita.';
    end if;



    strMessaggio:='Lettura identificativo bilancio in apertura annoBilancio='||(annoBilancio+1)::varchar;
    raise notice '%', strMessaggio;
    select bil.bil_id into bilancioNextId, periodoNextId
    from siac_t_bil bil, siac_t_periodo per, siac_d_bil_tipo tipo
    where bil.ente_proprietario_id=enteProprietarioId
    and   tipo.bil_tipo_id=bil.bil_tipo_id
    and   tipo.bil_tipo_code=BIL_ORD_TIPO
    and   per.periodo_id=bil.periodo_id
    and   per.anno::integer=annoBilancio+1;
raise notice 'FINE %', strMessaggio;

    strMessaggio:='Verifica esecuzione elaborazione fine anno in corso per annoBilancio='||annoBilancio::varchar||'.';
    raise notice ' %', strMessaggio;
    select fase.fase_gen_elab_id into faseBilElabId
    from fase_gen_t_elaborazione_fineanno fase
    where fase.ente_proprietario_id=enteProprietarioId
    and   fase.bil_id=bilancioId
    and   fase.fase_gen_elab_esito like 'IN%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;
raise notice 'FINE %', strMessaggio;
    if faseBilElabId is null then
    raise notice 'faseBilElabId=NULL';
        strMessaggio:='Inserimento esecuzione elaborazione fine anno [fase_gen_t_elaborazione_fineanno].';
		insert into fase_gen_t_elaborazione_fineanno
        (fase_gen_elab_esito,
	     fase_gen_elab_esito_msg,
		 bil_id,
	     validita_inizio,
	     login_operazione,
	     ente_proprietario_id
        )
        values
        ('IN',
         'ELABORAZIONE SCRITTURE GEN DI CHIUSURA/APERTURA FINE ANNO - INIZIO',
         bilancioId,
         dataElaborazione,
         loginOperazione||LOG_OP_FINE,
         enteProprietarioId
        )
        returning fase_gen_elab_id into faseBilElabId;
        if faseBilElabId is null then
        	raise exception ' Inserimento non effettuato.';
        end if;
    end if;

    codResult:=null;
    raise notice 'INSERT SU LOG';
    insert into fase_gen_t_elaborazione_fineanno_log
    (fase_gen_elab_id,fase_gen_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_gen_elab_log_id into codResult;
	raise notice 'FINE INSERT SU LOG faseBilElabId = %', faseBilElabId;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;


    -- PRIMO STEP : INSERIMENTO CALCOLO SALDI CONTI
	strMessaggio:='Verifica esecuzione primo step.';
	codResult:=null;
    insert into fase_gen_t_elaborazione_fineanno_log
    (fase_gen_elab_id,fase_gen_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
	(faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_gen_elab_log_id into codResult;

	if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
	end if;

	contaPasso:=1;
	strMessaggio:='Verifica esecuzione primo step di elaborazione in corso.';
    codResult:=null;
	select 1 into codResult
    from fase_gen_t_elaborazione_fineanno_det fasedet, fase_gen_d_elaborazione_fineanno_tipo tipo
    where fasedet.fase_gen_elab_id=faseBilElabId
    and   fasedet.fase_gen_det_elab_esito like 'IN%'
    and   tipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
    and   tipo.ordine=1
    and   fasedet.data_cancellazione is null
    and   fasedet.validita_fine is null;
    if codResult is not null then
    	raise exception ' Esistenza primo step in corso.';
    end if;

	strMessaggio:='Verifica esecuzione primo step di elaborazione OK.';
    codResult:=null;
	select 1 into codResult
    from fase_gen_t_elaborazione_fineanno_det fasedet, fase_gen_d_elaborazione_fineanno_tipo tipo
    where fasedet.fase_gen_elab_id=faseBilElabId
    and   fasedet.fase_gen_det_elab_esito='OK'
    and   tipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
    and   tipo.ordine=1
    and   fasedet.data_cancellazione is null
    and   fasedet.validita_fine is null;
    if codResult is not null then
	   	raise notice ' Esistenza primo step elaborato OK.Passaggio allo step 2.';
    end if;

    if codResult is not null then

        strMessaggio:='Primo step gia'' eseguito. Passaggio allo step 2.';
        codResult:=null;
        insert into fase_gen_t_elaborazione_fineanno_log
        (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
    	values
	    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	returning fase_gen_elab_log_id into codResult;

	    if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	    end if;
    else     eseguiStep:=true;
    end if;

    -- esecuzione primo step
    if eseguiStep=true then
    	strMessaggio:='Esecuzione primo step.';
        codResult:=null;
        insert into fase_gen_t_elaborazione_fineanno_log
        (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
    	values
	    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	returning fase_gen_elab_log_id into codResult;

	    if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	    end if;

    	strMessaggio:='Verifica esecuzione primo step di elaborazione OK.';
    	codResult:=null;
		select fasedet.fase_gen_elab_det_id into codResult
    	from fase_gen_t_elaborazione_fineanno_det fasedet, fase_gen_d_elaborazione_fineanno_tipo tipo
	    where fasedet.fase_gen_elab_id=faseBilElabId
    	and   fasedet.fase_gen_det_elab_esito='KO'
	    and   tipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
    	and   tipo.ordine=1
	    and   fasedet.data_cancellazione is null;
        if codResult is not null then
        	strMessaggio:='Rielaborazione primo step.Cancellazione saldi conti [fase_gen_t_elaborazione_fineanno_saldi].';
        	delete from fase_gen_t_elaborazione_fineanno_saldi saldi
            where saldi.fase_gen_elab_det_id=codResult;
            strMessaggio:='Rielaborazione primo step.Chiusura elaborazione saldi conti [fase_gen_t_elaborazione_fineanno_det].';
        	update fase_gen_t_elaborazione_fineanno_det saldi
            set    data_cancellazione=now(),
                   validita_fine=now(),
                   login_operazione=saldi.login_operazione||'-'||loginOperazione||'_TERMINE'
            where saldi.fase_gen_elab_det_id=codResult;
        end if;

        -- chiamata a funcion per caricamento saldi
        strMessaggio:='Inserimento saldi conti [fase_gen_t_elaborazione_fineanno_saldi].';
		select * into saldiRec
        from fnc_fase_gen_elaborazione_fineanno_calcolo_saldi
	         (enteProprietarioId,
  			  annoBilancio,
			  loginOperazione,
			  dataElaborazione,
              faseBilElabId,
              bilancioId
             );
        if saldiRec.codiceRisultato!=0 and  saldiRec.codiceRisultato!=1 then
         strMessaggio:=strmessaggio||saldiRec.messaggioRisultato;
         raise exception ' Errore.';
        elsif saldiRec.codiceRisultato=1 then
         eseguiStepScritture:=false;
        end if;

        strMessaggio:='Termine esecuzione primo step.';
        codResult:=null;
        insert into fase_gen_t_elaborazione_fineanno_log
        (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
    	values
	    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	returning fase_gen_elab_log_id into codResult;

	    if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	    end if;


    end if;

 -- se va male lo step 1 non eseguo dal secondo in poi
 if eseguiStepScritture=true then

    -- SECONDO STEP : INSERIMENTO CHIUSURA PASSIVITA DI BILANCIO
    contaPasso:=2;
    eseguiStep:=false;
	strMessaggio:='Verifica esecuzione secondo step.';
	codResult:=null;
    insert into fase_gen_t_elaborazione_fineanno_log
    (fase_gen_elab_id,fase_gen_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
	(faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_gen_elab_log_id into codResult;

	if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
	end if;

	strMessaggio:='Verifica esecuzione secondo step di elaborazione in corso.';
    codResult:=null;
	select 1 into codResult
    from fase_gen_t_elaborazione_fineanno_det fasedet, fase_gen_d_elaborazione_fineanno_tipo tipo
    where fasedet.fase_gen_elab_id=faseBilElabId
    and   fasedet.fase_gen_det_elab_esito like 'IN%'
    and   tipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
    and   tipo.ordine=2
    and   fasedet.data_cancellazione is null
    and   fasedet.validita_fine is null;
    if codResult is not null then
    	raise exception ' Esistenza secondo step in corso.';
    end if;


	strMessaggio:='Verifica esecuzione secondo step di elaborazione OK.';
    codResult:=null;
	select 1 into codResult
    from fase_gen_t_elaborazione_fineanno_det fasedet, fase_gen_d_elaborazione_fineanno_tipo tipo
    where fasedet.fase_gen_elab_id=faseBilElabId
    and   fasedet.fase_gen_det_elab_esito='OK'
    and   tipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
    and   tipo.ordine=2
    and   fasedet.data_cancellazione is null
    and   fasedet.validita_fine is null;
    if codResult is not null then
    	raise notice ' Esistenza secondo step elaborato OK.Passaggio allo step 3.';
    end if;

    if codResult is not null then

        strMessaggio:='Secondo step gia'' eseguito. Passaggio allo step 3.';
        codResult:=null;
        insert into fase_gen_t_elaborazione_fineanno_log
        (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
    	values
	    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	returning fase_gen_elab_log_id into codResult;

	    if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	    end if;
    else     eseguiStep:=true;
    end if;

    -- esecuzione secondo step
    if eseguiStep=true then
    	strMessaggio:='Esecuzione secondo step.';
        codResult:=null;
        insert into fase_gen_t_elaborazione_fineanno_log
        (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
    	values
	    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	returning fase_gen_elab_log_id into codResult;

	    if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	    end if;

        -- inserimento registrazioni conti passivita e ordine passivi
        strMessaggio:='Inserimento prima nota step 2. Chiusura classe conti '||PAS_PATR_CLASSE||' .';
raise notice '%',strMessaggio;
		select * into primaNotaRec
        from fnc_fase_gen_elaborazione_fineanno_insert_pnota
		(
		  enteproprietarioid,
		  annobilancio,
		  loginOperazione,
		  dataElaborazione,
		  faseBilElabId,
		  bilancioId,
		  PAS_PATR_CLASSE,
		  2,
		  'CHI'
         );
raise notice 'FINE %',strMessaggio;
         if primaNotaRec.codiceRisultato!=0 then
	         strMessaggio:=strmessaggio||saldiRec.messaggioRisultato;
    	     raise exception ' Errore.';
         end if;

         strMessaggio:='Termine esecuzione secondo step.';
         codResult:=null;
         insert into fase_gen_t_elaborazione_fineanno_log
         (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
         )
    	 values
	     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	 returning fase_gen_elab_log_id into codResult;

	     if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	     end if;

    end if;

    -- TERZO STEP : INSERIMENTO CHIUSURA ATTIVITA DI BILANCIO
    contaPasso:=3;
    eseguiStep:=false;
	strMessaggio:='Verifica esecuzione terzo step.';
	codResult:=null;
    insert into fase_gen_t_elaborazione_fineanno_log
    (fase_gen_elab_id,fase_gen_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
	(faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_gen_elab_log_id into codResult;

	if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
	end if;

	strMessaggio:='Verifica esecuzione terzo step di elaborazione in corso.';
    codResult:=null;
	select 1 into codResult
    from fase_gen_t_elaborazione_fineanno_det fasedet, fase_gen_d_elaborazione_fineanno_tipo tipo
    where fasedet.fase_gen_elab_id=faseBilElabId
    and   fasedet.fase_gen_det_elab_esito like 'IN%'
    and   tipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
    and   tipo.ordine=3
    and   fasedet.data_cancellazione is null
    and   fasedet.validita_fine is null;
    if codResult is not null then
    	raise exception ' Esistenza terzo step in corso.';
    end if;


	strMessaggio:='Verifica esecuzione terzo step di elaborazione OK.';
    codResult:=null;
	select 1 into codResult
    from fase_gen_t_elaborazione_fineanno_det fasedet, fase_gen_d_elaborazione_fineanno_tipo tipo
    where fasedet.fase_gen_elab_id=faseBilElabId
    and   fasedet.fase_gen_det_elab_esito='OK'
    and   tipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
    and   tipo.ordine=3
    and   fasedet.data_cancellazione is null
    and   fasedet.validita_fine is null;
    if codResult is not null then
    	raise notice ' Esistenza terzo step elaborato OK.Passaggio allo step 4.';
    end if;

    if codResult is not null then

        strMessaggio:='Terzo step gia'' eseguito. Passaggio allo step 4.';
        codResult:=null;
        insert into fase_gen_t_elaborazione_fineanno_log
        (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
    	values
	    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	returning fase_gen_elab_log_id into codResult;

	    if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	    end if;
    else     eseguiStep:=true;
    end if;

    -- esecuzione terzo step
    if eseguiStep=true then
    	strMessaggio:='Esecuzione terzo step.';
        codResult:=null;
        insert into fase_gen_t_elaborazione_fineanno_log
        (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
    	values
	    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	returning fase_gen_elab_log_id into codResult;

	    if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	    end if;

        -- inserimento registrazioni conti attivita e ordine attivi
        strMessaggio:='Inserimento prima nota step 3. Chiusura classe conti '||ATT_PATR_CLASSE||' .';

		select * into primaNotaRec
        from fnc_fase_gen_elaborazione_fineanno_insert_pnota
		(
		  enteproprietarioid,
		  annobilancio,
		  loginOperazione,
		  dataElaborazione,
		  faseBilElabId,
		  bilancioId,
		  ATT_PATR_CLASSE,
		  3,
		  'CHI'
         );

         if primaNotaRec.codiceRisultato!=0 then
	         strMessaggio:=strmessaggio||saldiRec.messaggioRisultato;
    	     raise exception ' Errore.';
         end if;

         strMessaggio:='Termine esecuzione terzo step.';
         codResult:=null;
         insert into fase_gen_t_elaborazione_fineanno_log
         (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
         )
    	 values
	     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	 returning fase_gen_elab_log_id into codResult;

	     if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	     end if;

    end if;

    -- QUARTO STEP : INSERIMENTO EPILOGO COSTI

	contaPasso:=4;
	eseguiStep:=false;
	strMessaggio:='Verifica esecuzione quarto step.';
	codResult:=null;
    insert into fase_gen_t_elaborazione_fineanno_log
    (fase_gen_elab_id,fase_gen_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
	(faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_gen_elab_log_id into codResult;

	if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
	end if;

	strMessaggio:='Verifica esecuzione quarto step di elaborazione in corso.';
    codResult:=null;
	select 1 into codResult
    from fase_gen_t_elaborazione_fineanno_det fasedet, fase_gen_d_elaborazione_fineanno_tipo tipo
    where fasedet.fase_gen_elab_id=faseBilElabId
    and   fasedet.fase_gen_det_elab_esito like 'IN%'
    and   tipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
    and   tipo.ordine=4
    and   fasedet.data_cancellazione is null
    and   fasedet.validita_fine is null;
    if codResult is not null then
    	raise exception ' Esistenza  quarto in corso.';
    end if;


	strMessaggio:='Verifica esecuzione quarto step di elaborazione OK.';
    codResult:=null;
	select 1 into codResult
    from fase_gen_t_elaborazione_fineanno_det fasedet, fase_gen_d_elaborazione_fineanno_tipo tipo
    where fasedet.fase_gen_elab_id=faseBilElabId
    and   fasedet.fase_gen_det_elab_esito='OK'
    and   tipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
    and   tipo.ordine=4
    and   fasedet.data_cancellazione is null
    and   fasedet.validita_fine is null;
    if codResult is not null then
    	raise notice ' Esistenza quarto step elaborato OK.Passaggio allo step 5.';
    end if;

    if codResult is not null then

        strMessaggio:='Quarto step gia'' eseguito.Passaggio allo step 5.';
        codResult:=null;
        insert into fase_gen_t_elaborazione_fineanno_log
        (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
    	values
	    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	returning fase_gen_elab_log_id into codResult;

	    if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	    end if;
    else     eseguiStep:=true;
    end if;

	-- esecuzione quarto step
    if eseguiStep=true then
    	strMessaggio:='Esecuzione quarto step.';
        codResult:=null;
        insert into fase_gen_t_elaborazione_fineanno_log
        (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
    	values
	    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	returning fase_gen_elab_log_id into codResult;

	    if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	    end if;

        -- inserimento registrazioni epilogo costi
        strMessaggio:='Inserimento prima nota step 4. Epilogo '||COSTI_CLASSE||' .';

		select * into primaNotaRec
        from fnc_fase_gen_elaborazione_fineanno_insert_pnota
		(
		  enteproprietarioid,
		  annobilancio,
		  loginOperazione,
		  dataElaborazione,
		  faseBilElabId,
		  bilancioId,
		  COSTI_CLASSE,
		  4,
		  'EPC'
         );

         if primaNotaRec.codiceRisultato!=0 then
	         strMessaggio:=strmessaggio||saldiRec.messaggioRisultato;
    	     raise exception ' Errore.';
         end if;

         strMessaggio:='Termine esecuzione quarto step.';
         codResult:=null;
         insert into fase_gen_t_elaborazione_fineanno_log
         (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
         )
    	 values
	     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	 returning fase_gen_elab_log_id into codResult;

	     if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	     end if;

    end if;

    --- QUINTO STEP EPILOGO RICAVI
	contaPasso:=5;
    eseguiStep:=false;
	strMessaggio:='Verifica esecuzione quinto step.';
	codResult:=null;
    insert into fase_gen_t_elaborazione_fineanno_log
    (fase_gen_elab_id,fase_gen_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
	(faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_gen_elab_log_id into codResult;

	if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
	end if;

	strMessaggio:='Verifica esecuzione quinto step di elaborazione in corso.';
    codResult:=null;
	select 1 into codResult
    from fase_gen_t_elaborazione_fineanno_det fasedet, fase_gen_d_elaborazione_fineanno_tipo tipo
    where fasedet.fase_gen_elab_id=faseBilElabId
    and   fasedet.fase_gen_det_elab_esito like 'IN%'
    and   tipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
    and   tipo.ordine=5
    and   fasedet.data_cancellazione is null
    and   fasedet.validita_fine is null;
    if codResult is not null then
    	raise exception ' Esistenza  quinto in corso.';
    end if;


	strMessaggio:='Verifica esecuzione quinto step di elaborazione OK.';
    codResult:=null;
	select 1 into codResult
    from fase_gen_t_elaborazione_fineanno_det fasedet, fase_gen_d_elaborazione_fineanno_tipo tipo
    where fasedet.fase_gen_elab_id=faseBilElabId
    and   fasedet.fase_gen_det_elab_esito='OK'
    and   tipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
    and   tipo.ordine=5
    and   fasedet.data_cancellazione is null
    and   fasedet.validita_fine is null;
    if codResult is not null then
    	raise notice ' Esistenza quinto step elaborato OK.Passaggio allo step 6.';
    end if;

    if codResult is not null then

        strMessaggio:='Quinto step gia'' eseguito. Passaggio alle step 6.';
        codResult:=null;
        insert into fase_gen_t_elaborazione_fineanno_log
        (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
    	values
	    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	returning fase_gen_elab_log_id into codResult;

	    if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	    end if;
    else     eseguiStep:=true;
    end if;


    -- esecuzione quinto step
    if eseguiStep=true then
    	strMessaggio:='Esecuzione quinto step.';
        codResult:=null;
        insert into fase_gen_t_elaborazione_fineanno_log
        (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
    	values
	    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	returning fase_gen_elab_log_id into codResult;

	    if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	    end if;

        -- inserimento registrazioni epilogo ricavi
        strMessaggio:='Inserimento prima nota step 5. Epilogo '||RICAVI_CLASSE||' .';

		select * into primaNotaRec
        from fnc_fase_gen_elaborazione_fineanno_insert_pnota
		(
		  enteproprietarioid,
		  annobilancio,
		  loginOperazione,
		  dataElaborazione,
		  faseBilElabId,
		  bilancioId,
		  RICAVI_CLASSE,
		  5,
		  'EPR'
         );

         if primaNotaRec.codiceRisultato!=0 then
	         strMessaggio:=strmessaggio||saldiRec.messaggioRisultato;
    	     raise exception ' Errore.';
         end if;

         strMessaggio:='Termine esecuzione quinto step.';
         codResult:=null;
         insert into fase_gen_t_elaborazione_fineanno_log
         (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
         )
    	 values
	     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	 returning fase_gen_elab_log_id into codResult;

	     if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	     end if;

    end if;


	--- SESTO STEP EPILOGO DETERMINAZIONE RISULTATO ECONOMICO ESERCIZIO REE
	contaPasso:=6;
    eseguiStep:=false;
	strMessaggio:='Verifica esecuzione sesto step.';
	codResult:=null;
    insert into fase_gen_t_elaborazione_fineanno_log
    (fase_gen_elab_id,fase_gen_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
	(faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_gen_elab_log_id into codResult;

	if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
	end if;

	strMessaggio:='Verifica esecuzione sesto step di elaborazione in corso.';
    codResult:=null;
	select 1 into codResult
    from fase_gen_t_elaborazione_fineanno_det fasedet, fase_gen_d_elaborazione_fineanno_tipo tipo
    where fasedet.fase_gen_elab_id=faseBilElabId
    and   fasedet.fase_gen_det_elab_esito like 'IN%'
    and   tipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
    and   tipo.ordine=6
    and   fasedet.data_cancellazione is null
    and   fasedet.validita_fine is null;
    if codResult is not null then
    	raise exception ' Esistenza  sesto in corso.';
    end if;


	strMessaggio:='Verifica esecuzione sesto step di elaborazione OK.';
    codResult:=null;
	select 1 into codResult
    from fase_gen_t_elaborazione_fineanno_det fasedet, fase_gen_d_elaborazione_fineanno_tipo tipo
    where fasedet.fase_gen_elab_id=faseBilElabId
    and   fasedet.fase_gen_det_elab_esito='OK'
    and   tipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
    and   tipo.ordine=6
    and   fasedet.data_cancellazione is null
    and   fasedet.validita_fine is null;
    if codResult is not null then
    	raise notice ' Esistenza sesto step elaborato OK.Passaggio allo step 7.';
    end if;

    if codResult is not null then

        strMessaggio:='Sesto step gia'' eseguito.Passaggio allo step 7.';
        codResult:=null;
        insert into fase_gen_t_elaborazione_fineanno_log
        (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
    	values
	    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	returning fase_gen_elab_log_id into codResult;

	    if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	    end if;
    else     eseguiStep:=true;
    end if;


    -- esecuzione sesto step
    if eseguiStep=true then
    	strMessaggio:='Esecuzione sesto step.';
        codResult:=null;
        insert into fase_gen_t_elaborazione_fineanno_log
        (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
    	values
	    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	returning fase_gen_elab_log_id into codResult;

	    if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	    end if;

        -- inserimento registrazioni REE
        strMessaggio:='Inserimento prima nota step 6. Determinazione risultato economico esercizio.';

		select * into primaNotaRec
        from fnc_fase_gen_elaborazione_fineanno_insert_pnota_ree
		(
		  enteproprietarioid,
		  annobilancio,
		  loginOperazione,
		  dataElaborazione,
		  faseBilElabId,
		  bilancioId,
		  6
         );


         if primaNotaRec.codiceRisultato!=0 then
	         strMessaggio:=strmessaggio||primaNotaRec.messaggioRisultato;
    	     raise exception ' Errore.';
         end if;

         strMessaggio:='Termine esecuzione sesto step.';
         codResult:=null;
         insert into fase_gen_t_elaborazione_fineanno_log
         (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
         )
    	 values
	     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	 returning fase_gen_elab_log_id into codResult;

	     if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	     end if;

    end if;


    --- SETTIMO STEP APERTURA PASSIVITA BILANCIO
	contaPasso:=7;
    eseguiStep:=false;
	strMessaggio:='Verifica esecuzione settimo step.';
	codResult:=null;
    insert into fase_gen_t_elaborazione_fineanno_log
    (fase_gen_elab_id,fase_gen_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
	(faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_gen_elab_log_id into codResult;

	if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
	end if;

	strMessaggio:='Verifica esecuzione settimo step di elaborazione in corso.';
    codResult:=null;
	select 1 into codResult
    from fase_gen_t_elaborazione_fineanno_det fasedet, fase_gen_d_elaborazione_fineanno_tipo tipo
    where fasedet.fase_gen_elab_id=faseBilElabId
    and   fasedet.fase_gen_det_elab_esito like 'IN%'
    and   tipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
    and   tipo.ordine=7
    and   fasedet.data_cancellazione is null
    and   fasedet.validita_fine is null;
    if codResult is not null then
    	raise exception ' Esistenza  settimo in corso.';
    end if;


	strMessaggio:='Verifica esecuzione settimo step di elaborazione OK.';
    codResult:=null;
	select 1 into codResult
    from fase_gen_t_elaborazione_fineanno_det fasedet, fase_gen_d_elaborazione_fineanno_tipo tipo
    where fasedet.fase_gen_elab_id=faseBilElabId
    and   fasedet.fase_gen_det_elab_esito='OK'
    and   tipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
    and   tipo.ordine=7
    and   fasedet.data_cancellazione is null
    and   fasedet.validita_fine is null;
    if codResult is not null then
    	raise notice ' Esistenza settimo step elaborato OK.Passaggio allo step 8.';
    end if;

    if codResult is not null then

        strMessaggio:='Settimo step gia'' eseguito.Passaggio allo step 8.';
        codResult:=null;
        insert into fase_gen_t_elaborazione_fineanno_log
        (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
    	values
	    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	returning fase_gen_elab_log_id into codResult;

	    if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	    end if;
    else     eseguiStep:=true;
    end if;

    -- esecuzione settimo step
    if eseguiStep=true then
    	strMessaggio:='Esecuzione settimo step.';
        codResult:=null;
        insert into fase_gen_t_elaborazione_fineanno_log
        (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
    	values
	    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	returning fase_gen_elab_log_id into codResult;

	    if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	    end if;

        -- inserimento apertura passivita di bilancio
        strMessaggio:='Inserimento prima nota step 7. Apertura passivita'' di bilancio.';

		select * into primaNotaRec
		from fnc_fase_gen_elaborazione_fineanno_insert_pnota_ape
		(
		  enteproprietarioid,
		  annobilancio+1,
		  loginOperazione,
		  dataElaborazione,
		  faseBilElabId,
		  bilancioNextId,
		  PAS_PATR_CLASSE,
		  2,
		  7,
	      'APE'
         );

         if primaNotaRec.codiceRisultato!=0 then
	         strMessaggio:=strmessaggio||primaNotaRec.messaggioRisultato;
    	     raise exception ' Errore.';
         end if;

         strMessaggio:='Termine esecuzione settimo step.';
         codResult:=null;
         insert into fase_gen_t_elaborazione_fineanno_log
         (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
         )
    	 values
	     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	 returning fase_gen_elab_log_id into codResult;

	     if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	     end if;

    end if;



	--- OTTAVO STEP APERTURA ATTIVITA BILANCIO
	contaPasso:=8;
    eseguiStep:=false;
	strMessaggio:='Verifica esecuzione ottavo step.';
	codResult:=null;
    insert into fase_gen_t_elaborazione_fineanno_log
    (fase_gen_elab_id,fase_gen_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
	(faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_gen_elab_log_id into codResult;

	if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
	end if;

	strMessaggio:='Verifica esecuzione ottavo step di elaborazione in corso.';
    codResult:=null;
	select 1 into codResult
    from fase_gen_t_elaborazione_fineanno_det fasedet, fase_gen_d_elaborazione_fineanno_tipo tipo
    where fasedet.fase_gen_elab_id=faseBilElabId
    and   fasedet.fase_gen_det_elab_esito like 'IN%'
    and   tipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
    and   tipo.ordine=8
    and   fasedet.data_cancellazione is null
    and   fasedet.validita_fine is null;
    if codResult is not null then
    	raise exception ' Esistenza  ottavo in corso.';
    end if;


	strMessaggio:='Verifica esecuzione ottavo step di elaborazione OK.';
    codResult:=null;
	select 1 into codResult
    from fase_gen_t_elaborazione_fineanno_det fasedet, fase_gen_d_elaborazione_fineanno_tipo tipo
    where fasedet.fase_gen_elab_id=faseBilElabId
    and   fasedet.fase_gen_det_elab_esito='OK'
    and   tipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
    and   tipo.ordine=8
    and   fasedet.data_cancellazione is null
    and   fasedet.validita_fine is null;
    if codResult is not null then
    	raise notice ' Esistenza ottavo step elaborato OK.Passaggio allo step 9.';
    end if;

    if codResult is not null then

        strMessaggio:='Ottavo step gia'' eseguito.Passaggio allo step 9.';
        codResult:=null;
        insert into fase_gen_t_elaborazione_fineanno_log
        (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
    	values
	    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	returning fase_gen_elab_log_id into codResult;

	    if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	    end if;
    else     eseguiStep:=true;
    end if;

    -- esecuzione ottavo step
    if eseguiStep=true then
    	strMessaggio:='Esecuzione ottavo step.';
        codResult:=null;
        insert into fase_gen_t_elaborazione_fineanno_log
        (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
    	values
	    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	returning fase_gen_elab_log_id into codResult;

	    if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	    end if;

        -- inserimento apertura attovita di bilancio
        strMessaggio:='Inserimento prima nota step 8. Apertura attivita'' di bilancio.';

		select * into primaNotaRec
		from fnc_fase_gen_elaborazione_fineanno_insert_pnota_ape
		(
		  enteproprietarioid,
		  annobilancio+1,
		  loginOperazione,
		  dataElaborazione,
		  faseBilElabId,
		  bilancioNextId,
		  ATT_PATR_CLASSE,
		  3,
		  8,
	      'APE'
         );

         if primaNotaRec.codiceRisultato!=0 then
	         strMessaggio:=strmessaggio||primaNotaRec.messaggioRisultato;
    	     raise exception ' Errore.';
         end if;

         strMessaggio:='Termine esecuzione ottavo step.';
         codResult:=null;
         insert into fase_gen_t_elaborazione_fineanno_log
         (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
         )
    	 values
	     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	 returning fase_gen_elab_log_id into codResult;

	     if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	     end if;

    end if;


    --- NONO STEP STORNO RISCONTI
	contaPasso:=9;
    eseguiStep:=false;
	strMessaggio:='Verifica esecuzione nono step.';
	codResult:=null;
    insert into fase_gen_t_elaborazione_fineanno_log
    (fase_gen_elab_id,fase_gen_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
	(faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_gen_elab_log_id into codResult;

	if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
	end if;

	strMessaggio:='Verifica esecuzione nono step di elaborazione in corso.';
    codResult:=null;
	select 1 into codResult
    from fase_gen_t_elaborazione_fineanno_det fasedet, fase_gen_d_elaborazione_fineanno_tipo tipo
    where fasedet.fase_gen_elab_id=faseBilElabId
    and   fasedet.fase_gen_det_elab_esito like 'IN%'
    and   tipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
    and   tipo.ordine=9
    and   fasedet.data_cancellazione is null
    and   fasedet.validita_fine is null;
    if codResult is not null then
    	raise exception ' Esistenza  nono in corso.';
    end if;


	strMessaggio:='Verifica esecuzione nono step di elaborazione OK.';
    codResult:=null;
	select 1 into codResult
    from fase_gen_t_elaborazione_fineanno_det fasedet, fase_gen_d_elaborazione_fineanno_tipo tipo
    where fasedet.fase_gen_elab_id=faseBilElabId
    and   fasedet.fase_gen_det_elab_esito='OK'
    and   tipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
    and   tipo.ordine=9
    and   fasedet.data_cancellazione is null
    and   fasedet.validita_fine is null;
    if codResult is not null then
    	raise notice ' Esistenza nono step elaborato OK.Passaggio a conclusione elaborazione.';
    end if;

    if codResult is not null then

        strMessaggio:='Nono step gia'' eseguito.Passaggio a conclusione elaborazione.';
        codResult:=null;
        insert into fase_gen_t_elaborazione_fineanno_log
        (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
    	values
	    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	returning fase_gen_elab_log_id into codResult;

	    if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	    end if;
    else     eseguiStep:=true;
    end if;


    -- esecuzione nono step
    if eseguiStep=true then
    	strMessaggio:='Esecuzione nono step.';
        codResult:=null;
        insert into fase_gen_t_elaborazione_fineanno_log
        (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
    	values
	    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	returning fase_gen_elab_log_id into codResult;

	    if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	    end if;

        -- inserimento storno risconti
        strMessaggio:='Inserimento prima nota step 9. Storno risconti.';

		select * into primaNotaRec
        from fnc_fase_gen_elaborazione_fineanno_insert_pnota_sri
 		(
		  enteproprietarioid,
		  annobilancio+1,
		  loginOperazione,
		  dataElaborazione,
		  faseBilElabId,
		  bilancioNextId,
		  RIS_CONTO_TIPO,
		  9,
	      'SRI'
         );

         if primaNotaRec.codiceRisultato!=0 then
	         strMessaggio:=strmessaggio||primaNotaRec.messaggioRisultato;
    	     raise exception ' Errore.';
         end if;

         strMessaggio:='Termine esecuzione nono step.';
         codResult:=null;
         insert into fase_gen_t_elaborazione_fineanno_log
         (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
         )
    	 values
	     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	 returning fase_gen_elab_log_id into codResult;

	     if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	     end if;

    end if;


/********************************/

---- Maurizio
 --- DECIMO STEP CONTABILIZZAZIONE
	contaPasso:=10;
    eseguiStep:=false;
	strMessaggio:='Verifica esecuzione decimo step.';
	codResult:=null;
    insert into fase_gen_t_elaborazione_fineanno_log
    (fase_gen_elab_id,fase_gen_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
	(faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_gen_elab_log_id into codResult;

	if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
	end if;

	strMessaggio:='Verifica esecuzione decimo step di elaborazione in corso.';
    codResult:=null;
	select 1 into codResult
    from fase_gen_t_elaborazione_fineanno_det fasedet, fase_gen_d_elaborazione_fineanno_tipo tipo
    where fasedet.fase_gen_elab_id=faseBilElabId
    and   fasedet.fase_gen_det_elab_esito like 'IN%'
    and   tipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
    and   tipo.ordine=10
    and   fasedet.data_cancellazione is null
    and   fasedet.validita_fine is null;
    if codResult is not null then
    	raise exception ' Esistenza  decimo in corso.';
    end if;


	strMessaggio:='Verifica esecuzione decimo step di elaborazione OK.';
    codResult:=null;
	select 1 into codResult
    from fase_gen_t_elaborazione_fineanno_det fasedet, fase_gen_d_elaborazione_fineanno_tipo tipo
    where fasedet.fase_gen_elab_id=faseBilElabId
    and   fasedet.fase_gen_det_elab_esito='OK'
    and   tipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
    and   tipo.ordine=10
    and   fasedet.data_cancellazione is null
    and   fasedet.validita_fine is null;
    if codResult is not null then
    	raise notice ' Esistenza decimo step elaborato OK.Passaggio a conclusione elaborazione.';
    end if;

    if codResult is not null then

        strMessaggio:='Decimo step gia'' eseguito.Passaggio a conclusione elaborazione.';
        codResult:=null;
        insert into fase_gen_t_elaborazione_fineanno_log
        (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
    	values
	    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	returning fase_gen_elab_log_id into codResult;

	    if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	    end if;
    else     eseguiStep:=true;
    end if;


    -- esecuzione decimo step
    if eseguiStep=true then
    	strMessaggio:='Esecuzione decimo step.';
        codResult:=null;
        insert into fase_gen_t_elaborazione_fineanno_log
        (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
    	values
	    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	returning fase_gen_elab_log_id into codResult;

	    if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	    end if;

        -- contabilizzazione
        strMessaggio:='Contabilizzazione prime note APE/CHI step 10. Contabilizzazione.';

		select * into primaNotaRec
        from fnc_fase_gen_elaborazione_fineanno_contabilizza
 		(
		  enteproprietarioid,
		  annobilancio+1,
		  loginOperazione,
		  dataElaborazione,
		  faseBilElabId,
		  bilancioNextId,
		  10
         );
raise notice 'Conclusione STEP 10';
raise notice 'STEP 10 - codiceRisultato= %, messaggiorisultato = %',
	primaNotaRec.codiceRisultato,primaNotaRec.messaggiorisultato;
         if primaNotaRec.codiceRisultato!=0 then	                      
	         strMessaggio:=strmessaggio||primaNotaRec.messaggioRisultato;
    	     raise exception ' Errore.';
         end if;

         strMessaggio:='Termine esecuzione decimo step.';
         codResult:=null;
         insert into fase_gen_t_elaborazione_fineanno_log
         (fase_gen_elab_id,fase_gen_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
         )
    	 values
	     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    	 returning fase_gen_elab_log_id into codResult;

	     if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	     end if;

    end if;





/*****************************************/

end if; -- step 1 andato male

 codResult:=null;
 strMessaggio:='Verifica esecuzione step elaborazione.';
 insert into fase_gen_t_elaborazione_fineanno_log
 (fase_gen_elab_id,fase_gen_elab_log_operazione,
  validita_inizio, login_operazione, ente_proprietario_id
 )
 values
 (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
 returning fase_gen_elab_log_id into codResult;

 if codResult is null then
   	raise exception ' Errore in inserimento LOG.';
 end if;


 codResult:=null;
 select 1 into codResult
 from fase_gen_t_elaborazione_fineanno fase, fase_gen_d_elaborazione_fineanno_tipo tipo
 where fase.fase_gen_elab_id=faseBilElabId
 and   tipo.ente_proprietario_id=fase.ente_proprietario_id
 and   tipo.ordine<=10
 and   not exists ( select 1 from fase_gen_t_elaborazione_fineanno_det fasedet
                    where fasedet.fase_gen_elab_id=fase.fase_gen_elab_id
                    and   fasedet.fase_gen_elab_tipo_id=tipo.fase_gen_elab_tipo_id
                    and   fasedet.fase_gen_det_elab_esito='OK'
                    and   fasedet.data_cancellazione is null
                    and   fasedet.validita_fine is null
                   )
 and   fase.data_cancellazione is null
 and   fase.validita_fine is null;

 if codResult is  null then


        -- chiusura elaborazione
	    strMessaggio:='Aggiornamento fase elaborazione OK.';
    	update fase_gen_t_elaborazione_fineanno fase
	    set fase_gen_elab_esito='OK',
    	    fase_gen_elab_esito_msg=fase.fase_gen_elab_esito_msg||' - FINE OK.',
            data_modifica=now(),
            login_operazione=fase.login_operazione||loginOperazione||'_TERMINE'
	    where fase.fase_gen_elab_id=faseBilElabId;

        codResult:=null;
		insert into fase_gen_t_elaborazione_fineanno_log
	    (fase_gen_elab_id,fase_gen_elab_log_operazione,
	     validita_inizio, login_operazione, ente_proprietario_id
	    )
	    values
	    (faseBilElabId,strMessaggioFinale||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	    returning fase_gen_elab_log_id into codResult;
        if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	    end if;


        codiceRisultato:=0;
	    messaggioRisultato:=strMessaggioFinale||' FINE';

 else
        codResult:=null;
		insert into fase_gen_t_elaborazione_fineanno_log
	    (fase_gen_elab_id,fase_gen_elab_log_operazione,
	     validita_inizio, login_operazione, ente_proprietario_id
	    )
	    values
	    (faseBilElabId,strMessaggioFinale||' ELABORAZIONE NON CONCLUSA. VERIFICA STEP.',clock_timestamp(),loginOperazione,enteProprietarioId)
	    returning fase_gen_elab_log_id into codResult;
        if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
	    end if;

        codiceRisultato:=1;
	    messaggioRisultato:=strMessaggioFinale||' ELABORAZIONE NON CONCLUSA. VERIFICA STEP '||contaPasso||'.';

  end if;


  faseBilElabRetId:=faseBilElabId;

  return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        --codiceRisultato:=-1;
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