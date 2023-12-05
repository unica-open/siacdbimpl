/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- Davide - 08.09.2016 - Funzione per l'aggiornamento degli Importi Competenza e Cassa del Bilancio
--                       di Previsione attuale a partire dai capitoli di Gestione equivalenti
--                       dell'anno di bilancio precedente e/o il dicuiimpegnato per la fase di
--                       PREDISPOSIZIONE BILANCIO DI PREVISIONE o la fase di ESERCIZIO PROVVISORIO (Main).

CREATE OR REPLACE FUNCTION fnc_fasi_bil_aggiorna_importi_bilprev (
  annobilancio integer,
  flagaggimpo boolean,
  flagdicuiimpe boolean,
  fasebilelabid integer,
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

    strMessaggio         VARCHAR(1500):='';
    strMessaggioFinale   VARCHAR(1500):='';

    BILANCIO_CODE        CONSTANT varchar:='BIL_'||annobilancio::varchar;
    BILANCIO_CODEP       CONSTANT varchar:='BIL_'||(annobilancio-1)::varchar;

    CAPITOLO_EP          CONSTANT varchar:='CAP-EP';
    CAPITOLO_UP          CONSTANT varchar:='CAP-UP';
    CAPITOLO_EG          CONSTANT varchar:='CAP-EG';
    CAPITOLO_UG          CONSTANT varchar:='CAP-UG';
	STATO_CAPI           CONSTANT varchar:='VA';       -- vanno estratti i capitoli solo in stato valido

    APE_PREV_DA_GEST     CONSTANT varchar:='APE_PREV'; -- PREDISPOSIZIONE BILANCIO DI PREVISIONE
    APE_PROV_DA_GEST     CONSTANT varchar:='APE_PROV'; -- ESERCIZIO PROVVISORIO
    SY_PER_TIPO          CONSTANT varchar:='SY';


    codResult            integer:=null;
    --dataInizioVal      timestamp:=null;

    fasetipoid           integer:=null;
    fasePredispBilId     integer:=null;
    faseEserPrvBilId     integer:=null;
    faseEP               boolean:=false;
    bilId                integer:=null;
    bilancioId           integer:=null;
    periodoId            integer:=null;
	bilancioPrecId       integer:=null;
    periodoPrecId        integer:=null;

    -- Id tipi capitolo
    IdCapitoloEP         integer :=null;
    IdCapitoloUP         integer :=null;
    IdCapitoloEG         integer :=null;
    IdCapitoloUG         integer :=null;

	CapiEquiv            record;
	CapiEquiv1           record;
    CapUscita            record;
    RitornoAggiornamento record;

    faseBilElabInizId    integer:=null; -- 05.10.2016
BEGIN

    messaggioRisultato:='';
    codiceRisultato:=0;

    faseBilElabInizId:=fasebilelabid;

    --dataInizioVal:=clock_timestamp();-- usato al posto di now() per essere certi di riconoscere i record inseriti dopo la chiamata della funzione;

	strMessaggioFinale:='Aggiornamento bilancio di previsione.Aggiornamento importi Cassa, Competenza e/o dicuiimpegnato da capitoli equivalenti Gestione anno precedente.Anno bilancio='||annoBilancio::varchar||'.';

	strMessaggio:='Lettura id fase bilancio per tipo='||APE_PREV_DA_GEST||'.';
    select tipo.fase_bil_elab_tipo_id into strict fasePredispBilId
     from fase_bil_d_elaborazione_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.fase_bil_elab_tipo_code=APE_PREV_DA_GEST
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

	strMessaggio:='Lettura id fase bilancio per tipo='||APE_PROV_DA_GEST||'.';
    select tipo.fase_bil_elab_tipo_id into strict faseEserPrvBilId
     from fase_bil_d_elaborazione_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.fase_bil_elab_tipo_code=APE_PROV_DA_GEST
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

	if faseBilElabId is not null then
        strMessaggio:='Lettura validita'' identificativo elaborazione faseBilElabId='||faseBilElabId||' relativamente alle fasi PREDISPOSIZIONE BILANCIO DI PREVISIONE / ESERCIZIO PROVVISORIO.';
        codResult:=null;
        select  1 into codResult
          from fase_bil_t_elaborazione fase
         where fase.fase_bil_elab_id=faseBilElabId
         and   fase.ente_proprietario_id=enteProprietarioId
         and   fase.data_cancellazione is null
         and   fase.validita_fine is null;

        if codResult is null then
            RAISE EXCEPTION ' Identificatvo fasebilelab non trovato.';
        end if;

        codResult:=null;
        select  1 into codResult
          from fase_bil_t_elaborazione fase
         where fase.fase_bil_elab_id=faseBilElabId
         and   fase.ente_proprietario_id=enteProprietarioId
         and   fase.data_cancellazione is null
         and   fase.validita_fine is null
         and   fase.fase_bil_elab_tipo_id not in (fasePredispBilId,faseEserPrvBilId);

        if codResult is not null then
            RAISE EXCEPTION ' Identificatvo fasebilelab di tipo diverso da PREDISPOSIZIONE BILANCIO DI PREVISIONE / ESERCIZIO PROVVISORIO.';
        end if;

    else
        -- trova un'id tipo fase che sia PREDISPOSIZIONE BILANCIO DI PREVISIONE / ESERCIZIO PROVVISORIO
/*        -- 05.10.2016 Sofia
        select distinct fase.fase_bil_elab_tipo_id into strict fasetipoid
          from fase_bil_t_elaborazione fase
         where fase.ente_proprietario_id=enteProprietarioId
         and   fase.data_cancellazione is null
         and   fase.validita_fine is null
         and   fase.fase_bil_elab_tipo_id in (fasePredispBilId,faseEserPrvBilId);*/
         strMessaggio:='Lettura validita'' identificativo tipo elaborazione '||APE_PREV_DA_GEST||' o '||APE_PROV_DA_GEST||' eleborata.';
         select fase.fase_bil_elab_tipo_id into fasetipoid
         from fase_bil_t_elaborazione fase
         where fase.ente_proprietario_id=enteProprietarioId
         and   fase.data_cancellazione is null
         and   fase.validita_fine is null
         and   fase.fase_bil_elab_tipo_id in (fasePredispBilId,faseEserPrvBilId)
         order by fase.fase_bil_elab_id desc
         limit  1 ; -- 05.10.2016 Sofia

        if fasetipoid is null then
            RAISE EXCEPTION ' Identificatvo fasetipo non trovato per le fasi di PREDISPOSIZIONE BILANCIO DI PREVISIONE / ESERCIZIO PROVVISORIO.';
        end if;

    	strMessaggio:='Lettura validita'' identificativo elaborazione elaborata.';
        select fase.fase_bil_elab_id into strict faseBilElabId
          from fase_bil_t_elaborazione fase
         where fase.ente_proprietario_id=enteProprietarioId
         and   fase.data_cancellazione is null
         and   fase.validita_fine is null
         and   fase.fase_bil_elab_tipo_id = fasetipoid
         order by fase.fase_bil_elab_id desc
         limit 1; -- 05.10.2016 Sofia

        if faseBilElabId is null then
            RAISE EXCEPTION ' Identificatvo fasebilelab. non trovato.';
        end if;
    end if;

    strMessaggio:='Lettura validita'' identificativo elaborazione faseBilElabId='||faseBilElabId||'.';
    codResult:=null;
    select  1, fase.fase_bil_elab_tipo_id into codResult, fasetipoid
      from fase_bil_t_elaborazione fase
     where fase.fase_bil_elab_id=faseBilElabId
     and   fase.ente_proprietario_id=enteProprietarioId
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null
     and   fase.fase_bil_elab_esito!='IN2';

    if codResult is null then
        RAISE EXCEPTION ' Identificatvo fasebilelab non valido.';
    end if;

	strMessaggio:='Lettura IdCapitoloEP  per tipo='||CAPITOLO_EP||'.';
	select tipo.elem_tipo_id into strict IdCapitoloEP
    from siac_d_bil_elem_tipo tipo
    where tipo.elem_tipo_code=CAPITOLO_EP
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

	strMessaggio:='Lettura IdCapitoloUP  per tipo='||CAPITOLO_UP||'.';
	select tipo.elem_tipo_id into strict IdCapitoloUP
    from siac_d_bil_elem_tipo tipo
    where tipo.elem_tipo_code=CAPITOLO_UP
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

	strMessaggio:='Lettura IdCapitoloEG  per tipo='||CAPITOLO_EG||'.';
	select tipo.elem_tipo_id into strict IdCapitoloEG
    from siac_d_bil_elem_tipo tipo
    where tipo.elem_tipo_code=CAPITOLO_EG
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

	strMessaggio:='Lettura IdCapitoloUG  per tipo='||CAPITOLO_UG||'.';
	select tipo.elem_tipo_id into strict IdCapitoloUG
    from siac_d_bil_elem_tipo tipo
    where tipo.elem_tipo_code=CAPITOLO_UG
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

	strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
    select bil.bil_id , per.periodo_id into strict bilancioPrecId, periodoPrecId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio-1
    and   per.data_cancellazione is null;

  	strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
    select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio
    and   bil.data_cancellazione is null
    and   per.data_cancellazione is null;

    -- 05.10.2016 Sofia
    if faseBilElabInizId is not null then
     codResult:=null;
     insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabInizId,strMessaggioFinale,clock_timestamp(),loginOperazione,enteProprietarioId)
      returning fase_bil_elab_log_id into codResult;

     if codResult is null then
        RAISE EXCEPTION ' Errore in inserimento LOG.';
     end if;
    end if;


    if flagAggImpo=true then
        -- 1) Lettura capitoli Gestione anno precedente equivalenti ai capitoli Bilancio Previsione anno attuale
        -- 2) Inserimento importi cassa e competenza per ognuno dei capitoli letti da 1).
        -- 3) Lettura capitoli Gestione anno precedente equivalenti ai capitoli Bilancio Previsione anno precedente
		--    non presenti su Bilancio Previsione anno attuale
		-- 4) Inserimento importi cassa e competenza per ognuno dei capitoli letti da 3)

        -- Cancellazione massiva della tavola siac_t_dicuiimpegnato_bilprev
        -- per ente_proprietario e anno bilancio interessati
        strMessaggio:='Cancellazione massiva delle tabelle siac_t_cap_e_importi_anno_prec e '||
        'siac_t_cap_u_importi_anno_prec per ente proprietario='||enteProprietarioId||
        'e Anno Bilancio='||(annobilancio)::varchar||'.';

        BEGIN
            delete
              from siac_t_cap_e_importi_anno_prec k
             where k.ente_proprietario_id=enteProprietarioId
               and k.anno=(annobilancio-1)::varchar
               and k.data_cancellazione is null; --05.10.2016 Sofia

            delete
              from siac_t_cap_u_importi_anno_prec k
             where k.ente_proprietario_id=enteProprietarioId
               and k.anno=(annobilancio-1)::varchar
               and k.data_cancellazione is null; --05.10.2016 Sofia

        EXCEPTION
            when others THEN
                RAISE EXCEPTION ' ERRORE : Cancellazione tabelle siac_t_cap_e_importi_anno_prec e siac_t_cap_u_importi_anno_prec non effettuate.';
        END;

        -- 1) Lettura capitoli Gestione anno precedente equivalenti ai capitoli Bilancio Previsione anno attuale
        -- 2) Inserimento importi cassa e competenza per ognuno dei capitoli letti da 1).
        for CapiEquiv IN
            (select prev.elem_id, prev.elem_tipo_id, prev.elem_code, prev.elem_code2,  prev.elem_code3,
                    gest.elem_id as gestelemid, gest.bil_id as gestbilid
    	       from siac_t_bil_elem prev, siac_t_bil_elem gest, siac_r_bil_elem_stato rstato, siac_d_bil_elem_stato stato
	          where prev.ente_proprietario_id=enteProprietarioId
	            and ((prev.elem_tipo_id = IdCapitoloEP and gest.elem_tipo_id = IdCapitoloEG)   or
				     (prev.elem_tipo_id = IdCapitoloUP and gest.elem_tipo_id = IdCapitoloUG))
	            and prev.bil_id=bilancioId
	            and gest.ente_proprietario_id=prev.ente_proprietario_id
	            and gest.bil_id=bilancioPrecId
                and rstato.elem_id=gest.elem_id
                and stato.elem_stato_id=rstato.elem_stato_id
                and stato.elem_stato_code=STATO_CAPI
    	        and gest.elem_code=prev.elem_code
	            and gest.elem_code2=prev.elem_code2
	            and gest.elem_code3=prev.elem_code3
		        and prev.data_cancellazione is null
	            and date_trunc('day',dataElaborazione)>=date_trunc('day',prev.validita_inizio)
    	        and ( date_trunc('day',dataElaborazione)<=date_trunc('day',prev.validita_fine) or prev.validita_fine is null)
	            and gest.data_cancellazione is null
    	        and date_trunc('day',dataElaborazione)>=date_trunc('day',gest.validita_inizio)
	   	        and ( date_trunc('day',dataElaborazione)<=date_trunc('day',gest.validita_fine) or gest.validita_fine is null)
    	       order by prev.elem_code::integer,prev.elem_code2::integer,prev.elem_code3) loop

            -- Aggiornamento Importi Capitoli Previsione
            select * into RitornoAggiornamento
              from fnc_fasi_bil_aggiorna_importi (annobilancio,
                                                  CapiEquiv.elem_id,
                                                  CapiEquiv.elem_tipo_id,
                                                  CapiEquiv.elem_code,
                                                  CapiEquiv.elem_code2,
                                                  CapiEquiv.elem_code3,
                                                  CapiEquiv.gestelemid,
                                                  CapiEquiv.gestbilid,
                                                  enteproprietarioid,
                                                  loginoperazione,
                                                  dataelaborazione);
            if RitornoAggiornamento.codiceRisultato=-1 then
                RAISE EXCEPTION 'Errore nell''aggiornamento Importi Capitoli Previsione % ', RitornoAggiornamento.messaggioRisultato;
            end if;
        end loop;

        -- 3) Lettura capitoli Gestione anno precedente equivalenti ai capitoli Bilancio Previsione anno precedente
		--    non presenti su Bilancio Previsione anno attuale
		-- 4) Inserimento importi cassa e competenza per ognuno dei capitoli letti da 3)
        for CapiEquiv1 IN
            (select gest.elem_id, gest.elem_tipo_id, gest.elem_code, gest.elem_code2, gest.elem_code3,
                    gest.elem_id as gestelemid, gest.bil_id as gestbilid
			   from siac_t_bil_elem gest, siac_r_bil_elem_stato rstato, siac_d_bil_elem_stato stato
              where gest.ente_proprietario_id=enteProprietarioId
                and gest.elem_tipo_id in (IdCapitoloEG,IdCapitoloUG)
                and gest.bil_id=bilancioPrecId
                and rstato.elem_id=gest.elem_id
                and stato.elem_stato_id=rstato.elem_stato_id
                and stato.elem_stato_code=STATO_CAPI
                and gest.data_cancellazione is null
                and date_trunc('day',dataElaborazione)>=date_trunc('day',gest.validita_inizio)
                and (date_trunc('day',dataElaborazione)<=date_trunc('day',gest.validita_fine) or gest.validita_fine is null)
				and not exists(select 1
                                 from siac_t_bil_elem prev1
                                where prev1.ente_proprietario_id=enteProprietarioId
                                  and prev1.bil_id=bilancioId
                                  and
                                   ( ( prev1.elem_tipo_id=IdCapitoloEP and  gest.elem_tipo_id=IdCapitoloEG ) or
                                     ( prev1.elem_tipo_id=IdCapitoloUP and  gest.elem_tipo_id=IdCapitoloUG )
                                   )
                                  and prev1.elem_code=gest.elem_code
                                  and prev1.elem_code2=gest.elem_code2
                                  and prev1.elem_code3=gest.elem_code3
                                  and prev1.data_cancellazione is null

                                  and date_trunc('day',dataElaborazione)>=date_trunc('day',prev1.validita_inizio)
                                  and (date_trunc('day',dataElaborazione)<=date_trunc('day',prev1.validita_fine) or prev1.validita_fine is null)
                               )
               order by gest.elem_code::integer,gest.elem_code2::integer,gest.elem_code3) loop

            -- Aggiornamento Importi Capitoli Previsione non presenti nel Bilancio anno attuale
            select * into RitornoAggiornamento
              from fnc_fasi_bil_aggiorna_importi (annobilancio,
                                                  null,
                                                  CapiEquiv1.elem_tipo_id,
                                                  CapiEquiv1.elem_code,
                                                  CapiEquiv1.elem_code2,
                                                  CapiEquiv1.elem_code3,
                                                  CapiEquiv1.gestelemid,
                                                  CapiEquiv1.gestbilid,
                                                  enteproprietarioid,
                                                  loginoperazione,
                                                  dataelaborazione);
            if RitornoAggiornamento.codiceRisultato=-1 then
                RAISE EXCEPTION 'Errore nell''aggiornamento Importi Capitoli Previsione non presenti nel Bilancio anno attuale % ', RitornoAggiornamento.messaggioRisultato;
            end if;
        end loop;
    end if;

    if flagdicuiimpe=true then
        -- 1) Lettura capitoli Gestione anno precedente (se la fase bilancio è PREDISPOSIZIONE BILANCIO DI PREVISIONE)
		--    oppure dei capitoli Gestione dello stesso anno (se la fase bilancio è ESERCIZIO PROVVISORIO)
		--    equivalenti ai capitoli Bilancio Previsione anno attuale
        -- 2) inserimento o aggiornamento dicuiimpegnato (sempre Gestione)  per ognuno dei capitoli letti conteggiando gli impegni (anche pluriennali).

		-- Determina in che fase siamo e passa alla query l'anno bilancio corretto
		if fasetipoid = fasePredispBilId then
			faseEP := false;
			bilId  := bilancioPrecId;
		else
			faseEP := true;
			bilId  := bilancioId;
		end if;

        -- Cancellazione massiva della tavola siac_t_dicuiimpegnato_bilprev
        -- per ente_proprietario e anno bilancio corrente
        strMessaggio:='Cancellazione massiva della tabella siac_t_dicuiimpegnato_bilprev per ente proprietario='||enteProprietarioId||
        'e Anno Bilancio='||annoBilancio::varchar||'.';

        BEGIN
            delete
              from siac_t_dicuiimpegnato_bilprev k
             where k.ente_proprietario_id=enteProprietarioId
               and k.bil_id=bilancioId
               and k.data_cancellazione is null; --05.10.2016 Sofia

        EXCEPTION
            when others THEN
                RAISE EXCEPTION ' ERRORE : Cancellazione tabella siac_t_dicuiimpegnato_bilprev non effettuata.';
        END;

        for CapUscita IN
		    (select prev.elem_id, gest.elem_id as gestelemid, gest.elem_tipo_id as gestelemtipoid
    	       from siac_t_bil_elem prev, siac_t_bil_elem gest
	          where prev.ente_proprietario_id=enteProprietarioId
	            and prev.elem_tipo_id = IdCapitoloUP
	            and prev.bil_id=bilancioId
	            and gest.ente_proprietario_id=prev.ente_proprietario_id
	            and gest.bil_id=bilId
                and gest.elem_tipo_id = IdCapitoloUG
    	        and gest.elem_code=prev.elem_code
	            and gest.elem_code2=prev.elem_code2
	            and gest.elem_code3=prev.elem_code3
		        and prev.data_cancellazione is null
	            and date_trunc('day',dataElaborazione)>=date_trunc('day',prev.validita_inizio)
    	        and ( date_trunc('day',dataElaborazione)<=date_trunc('day',prev.validita_fine) or prev.validita_fine is null)
	            and gest.data_cancellazione is null
    	        and date_trunc('day',dataElaborazione)>=date_trunc('day',gest.validita_inizio)
	   	        and ( date_trunc('day',dataElaborazione)<=date_trunc('day',gest.validita_fine) or gest.validita_fine is null)
    	       order by prev.elem_code::integer,prev.elem_code2::integer,prev.elem_code3) loop
		    RAISE NOTICE 'PRIMA DI fnc_fasi_bil_aggiorna_dicuiimpegnato ANNO_BILANCIO=% BILANCIOid=% FASEEP=% ',
                            annoBilancio,bilancioId ,faseEp;
            -- Aggiornamento Importi dicuiimpegnato
            select * into RitornoAggiornamento
              from fnc_fasi_bil_aggiorna_dicuiimpegnato (annoBilancio,
			                                             bilancioId,
                                                         CapUscita.elem_id,
                                                         CapUscita.gestelemid,
                                                         enteproprietarioid,
														 faseEP,
                                                         loginoperazione,
                                                         dataelaborazione);
            if RitornoAggiornamento.codiceRisultato=-1 then
                RAISE EXCEPTION 'Errore nell''aggiornamento Importi dicuiimpegnato  % ', RitornoAggiornamento.messaggioRisultato;
            end if;
        end loop;
    end if;

    -- 05.10.2016 Sofia
    if faseBilElabInizId is not null then
     strMessaggio:='Aggiornamento elaborazione faseBilElabId='||faseBilElabId||' per conclusione OK.';
     update fase_bil_t_elaborazione set
        fase_bil_elab_esito='OK',
        fase_bil_elab_esito_msg=fase_bil_elab_esito_msg||' AGGIORNAMENTO IMPORTI E DATI ANNO PREC TERMINATO.'
     where fase_bil_elab_id=faseBilElabInizId;

     codResult:=null;
     insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabInizId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
        RAISE EXCEPTION ' Errore in inserimento LOG.';
     end if;
    end if;

    messaggioRisultato:=strMessaggioFinale||'OK .';
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