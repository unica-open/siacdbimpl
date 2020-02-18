/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 14.10.2016 Davide - calcola cassa prendendo il residuo dal capitolo (A) o ricalcolato (B)
                  --> (A) inserimenti su fase_bil_t_cap_calcolo_res leggendo stanziamento_res e stanziamento da capitolo,
                  			-- quindi calcolo dello stanziamento cassa
                  --> (B) inserimenti su fase_bil_t_cap_calcolo_res calcolando tot_impacc e leggendo stanziamento da capitolo
                 			-- quindi calcolo dello stanziamento cassa
-- 14.10.2016 Davide - chiamata da fnc_aggiorna_residui.
CREATE OR REPLACE FUNCTION fnc_fasi_bil_cap_calcolo_cassa (
  annobilancio integer,
  tipoCapitolo varchar,
  tipoCapitolo_old varchar,
  res_calcolato boolean,
  enteproprietarioid integer,
  loginoperazione varchar,
  faseBilElabId    integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

    strMessaggio         VARCHAR(1500):='';
    strMessaggioFinale   VARCHAR(1500):='';
    dataElaborazione  	 timestamp := now();

    APE_CAP_CALC_RES     CONSTANT varchar:='APE_CAP_CALC_RES'; -- APERTURA CAPITOLI CALCOLO RESIDUO
    SY_PER_TIPO          CONSTANT varchar:='SY';

    BILANCIO_CODE        CONSTANT varchar:='BIL_'||annobilancio::varchar;

    CAPITOLO_UP          CONSTANT varchar:='CAP-UP';
    CAPITOLO_UG          CONSTANT varchar:='CAP-UG';

    CAPITOLO_EP          CONSTANT varchar:='CAP-EP';
    CAPITOLO_EG          CONSTANT varchar:='CAP-EG';

    STATO_CAPI           CONSTANT varchar:='VA';       -- vanno estratti i capitoli solo in stato valido

    STA_DET_TIPO         CONSTANT varchar:='STA';
    STR_DET_TIPO         CONSTANT varchar:='STR';

    codResult            integer:=null;
    dataInizioVal        timestamp:=null;
    IdCalcRes            numeric:= null;

    --fasetipoid           integer:=null;
    faseApeCalcId        integer:=null;
    --faseBilElabId        integer:=null;
    bilancioId           integer:=null;
    periodoId            integer:=null;

    detTipoStaId         integer:=null;
    detTipoResId         integer:=null;
    trovatafase          integer:=null;

    -- Id tipi capitolo
    tipoCapId            integer :=0;
    IdCapitoloEP         integer :=0;
    IdCapitoloUP         integer :=0;
    IdCapitoloEG         integer :=0;
    IdCapitoloUG         integer :=0;

	-- Importi
	StanziamentoRes      numeric := 0;
    StanziamentoComp     numeric := 0;
    StanziamentoCassa    numeric := 0;

    Capitoli             record;
    RitornoAggiornamento record;

BEGIN

    messaggioRisultato:='';
    codiceRisultato:=0;

    dataInizioVal:=date_trunc('DAY', now());
    strMessaggioFinale:='Calcolo residui Cassa.Anno bilancio='||annoBilancio::varchar||' faseBilElabId-->'||faseBilElabId::varchar||'.';

	codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
     (faseBilElabId,strMessaggioFinale,clock_timestamp(),loginOperazione,enteProprietarioId)
      returning fase_bil_elab_log_id into codResult;

    if codResult is null then
       RAISE EXCEPTION ' Errore in inserimento LOG.';
    end if;


	strMessaggio:='Lettura id fase bilancio per tipo='||APE_CAP_CALC_RES||'.';





    select tipo.fase_bil_elab_tipo_id into strict faseApeCalcId
     from fase_bil_d_elaborazione_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.fase_bil_elab_tipo_code=APE_CAP_CALC_RES
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

    strMessaggio:='Lettura identificativo Capitolo '||CAPITOLO_EP||'.';
    select tipo.elem_tipo_id into strict IdCapitoloEP
    from siac_d_bil_elem_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_tipo_code=CAPITOLO_EP
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura identificativo Capitolo '||CAPITOLO_UP||'.';
    select tipo.elem_tipo_id into strict IdCapitoloUP
    from siac_d_bil_elem_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_tipo_code=CAPITOLO_UP
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura identificativo Capitolo '||CAPITOLO_EG||'.';
    select tipo.elem_tipo_id into strict IdCapitoloEG
    from siac_d_bil_elem_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_tipo_code=CAPITOLO_EG
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura identificativo Capitolo '||CAPITOLO_UG||'.';
    select tipo.elem_tipo_id into strict IdCapitoloUG
    from siac_d_bil_elem_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_tipo_code=CAPITOLO_UG
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura identificativo tipo importo '||STA_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoStaId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=STA_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura identificativo tipo importo '||STR_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoResId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=STR_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;





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

  	strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
    select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio
    and   bil.data_cancellazione is null
    and   per.data_cancellazione is null;


	if    tipoCapitolo = CAPITOLO_EP then
	    tipoCapId := IdCapitoloEP;
	elsif tipoCapitolo = CAPITOLO_UP then
	    tipoCapId := IdCapitoloUP;
	elsif tipoCapitolo = CAPITOLO_EG then
	    tipoCapId := IdCapitoloEG;
	elsif tipoCapitolo = CAPITOLO_UG then
	    tipoCapId := IdCapitoloUG;
	end if;




    if res_calcolato = false then
        --(A) inserimenti su fase_bil_t_cap_calcolo_res leggendo stanziamento_res e stanziamento da capitolo,
        --    quindi calcolo dello stanziamento cassa
		-- Ciclo sui capitoli di tipo passato, nel annoBilancio  e ente passati
		-- per ogni capitolo trovato leggi stanziamento_res (tot_impacc) e stanziamento (stanziamento)
		-- quindi calcolo dello stanziamento cassa e inserimento del capitolo sulla tavola

        for Capitoli IN
            (select capi.*
    	       from
    	       	siac_t_bil_elem capi,
    	       	siac_r_bil_elem_stato rstato,
    	       	siac_d_bil_elem_stato stato,
    	       	siac_r_bil_elem_categoria relcat,
                siac_d_bil_elem_categoria delcat


	          where
	                capi.ente_proprietario_id=enteProprietarioId
	            and capi.elem_tipo_id = tipoCapId
	            and capi.bil_id=bilancioId
                and rstato.elem_id=capi.elem_id
                and stato.elem_stato_id=rstato.elem_stato_id
                and stato.elem_stato_code=STATO_CAPI
		        and capi.data_cancellazione is null
	            and date_trunc('day',dataElaborazione)>=date_trunc('day',capi.validita_inizio)
    	        and ( date_trunc('day',dataElaborazione)<=date_trunc('day',capi.validita_fine) or capi.validita_fine is null)
	            and capi.elem_id =  relcat.elem_id
                and relcat.elem_cat_id = delcat.elem_cat_id
                and relcat.data_cancellazione is null
                and relcat.validita_fine is null
                and delcat.elem_cat_code = 'STD'

    	       order by capi.elem_code::integer,capi.elem_code2::integer,capi.elem_code3) loop

			-- Legge il dettaglio dal capitolo per STA e RES
            strMessaggio:='Lettura Importo Residuo del Capitolo.';
            select j.elem_det_importo into strict StanziamentoRes
	          from siac_t_bil_elem_det j, siac_d_bil_elem_det_tipo k
             where j.elem_id=Capitoli.elem_id and
	               k.elem_det_tipo_id=detTipoResId and
		           k.elem_det_tipo_id=j.elem_det_tipo_id and
		           j.periodo_id = periodoId;

            strMessaggio:='Lettura Importo Competenza del Capitolo.';
            select j.elem_det_importo into strict StanziamentoComp
	          from siac_t_bil_elem_det j, siac_d_bil_elem_det_tipo k
             where j.elem_id=Capitoli.elem_id and
	               k.elem_det_tipo_id=detTipoStaId and
		           k.elem_det_tipo_id=j.elem_det_tipo_id and
		           j.periodo_id = periodoId;

            strMessaggio:='Inserimento fase_bil_t_cap_calcolo_res.'; -- per ogni capitolo uscita gestione annoprec
            BEGIN

                StanziamentoCassa := StanziamentoRes + StanziamentoComp;

                insert into fase_bil_t_cap_calcolo_res
			        (fase_bil_elab_id, elem_code, elem_code2, elem_code3, bil_id, elem_id,
                     elem_tipo_id, tot_impacc, stanziamento, stanziamento_cassa, validita_inizio,
				     data_creazione, ente_proprietario_id, login_operazione)
                values
                    (faseBilElabId, Capitoli.elem_code, Capitoli.elem_code2, Capitoli.elem_code3,
					 bilancioId, Capitoli.elem_id, tipoCapId, StanziamentoRes, StanziamentoComp,
					 StanziamentoCassa, dataInizioVal, clock_timestamp(), enteProprietarioId,
					 loginOperazione)
                returning fase_bil_cap_calc_res_id into IdCalcRes;

            EXCEPTION
                WHEN OTHERS THEN null;
            END;

            -- Controlla inserimento ok
            if IdCalcRes = 0 then
                RAISE EXCEPTION 'Errore nell''inserimento fase_bil_t_cap_calcolo_res.';
            end if;
        end loop;

    else
        --(B) inserimenti su fase_bil_t_cap_calcolo_res calcolando tot_impacc e leggendo stanziamento da capitolo
		-- Ciclo sui capitoli di tipo passato, nel annoBilancio  e ente passati :
		-- per ogni capitolo estratto leggo lo stanziamento e ricerco il tot_impacc calcolato precedentemente
		-- sulla fase_bil_t_cap_calcolo_res tramite fase_bil_elab_id restituita dalla fnc_calcolo_res
		-- e elem_id estratto,
        -- quindi calcolo dello stanziamento cassa (tot_impacc+stanziamento)
		-- e aggiornamento della fase_bil_t_cap_calcolo_res sempre tramite fase_bil_elab_id restituita dalla
		-- fnc_calcolo_res e elem_id estratto.

	    -- Lancio calcolo tot_impacc
        select * into RitornoAggiornamento from fnc_fasi_bil_cap_calcolo_res (tipoCapitolo,tipoCapitolo_old,annobilancio, enteproprietarioid,loginoperazione,faseBilElabId);

       strMessaggio :='tipoCapitolo '||tipoCapitolo||' tipoCapitolo_old '||tipoCapitolo_old||' annobilancio '||annobilancio::varchar||' faseBilElabId '||faseBilElabId::varchar||'.';



		if RitornoAggiornamento.codiceRisultato=-1 then
            strMessaggio :='Errore nel Calcolo stanziamento residuo Anno Bilancio : % Errore : % ',annobilancio::varchar, RitornoAggiornamento.messaggioRisultato;
            RAISE EXCEPTION 'Errore nel Calcolo stanziamento residuo Anno Bilancio : % Errore : % ',annobilancio::varchar, RitornoAggiornamento.messaggioRisultato;
        end if;

        for Capitoli IN
            (select capi.*
    	       from
               siac_t_bil_elem capi,
                siac_r_bil_elem_stato rstato,
                 siac_d_bil_elem_stato stato,
                 siac_r_bil_elem_categoria relcat,
                siac_d_bil_elem_categoria delcat


	          where capi.ente_proprietario_id=enteProprietarioId
	            and capi.elem_tipo_id = tipoCapId
	            and capi.bil_id=bilancioId
                and rstato.elem_id=capi.elem_id
                and stato.elem_stato_id=rstato.elem_stato_id
                and stato.elem_stato_code=STATO_CAPI
		        and capi.data_cancellazione is null
	            and date_trunc('day',dataElaborazione)>=date_trunc('day',capi.validita_inizio)
    	        and ( date_trunc('day',dataElaborazione)<=date_trunc('day',capi.validita_fine) or capi.validita_fine is null)
                and capi.elem_id =  relcat.elem_id
                and relcat.elem_cat_id = delcat.elem_cat_id
                and relcat.data_cancellazione is null
                and relcat.validita_fine is null
                and delcat.elem_cat_code = 'STD'

    	       order by capi.elem_code::integer,capi.elem_code2::integer,capi.elem_code3) loop

            strMessaggio:=strMessaggio ||'Lettura Importo Residuo del Capitolo faseBilElabId '||faseBilElabId::varchar ||'.';
            select j.tot_impacc into strict StanziamentoRes
	          from fase_bil_t_cap_calcolo_res j
             where j.elem_id=Capitoli.elem_id and
                   j.fase_bil_elab_id=faseBilElabId;

            strMessaggio:='Lettura Importo Competenza del Capitolo.';
            select j.elem_det_importo into strict StanziamentoComp
	          from siac_t_bil_elem_det j, siac_d_bil_elem_det_tipo k
             where j.elem_id=Capitoli.elem_id and
	               k.elem_det_tipo_id=detTipoStaId and
		           k.elem_det_tipo_id=j.elem_det_tipo_id and
		           j.periodo_id = periodoId;

            -- Aggiorna il capitolo sulla tavola
            strMessaggio:='Aggiornamento fase_bil_t_cap_calcolo_res.'; -- per ogni capitolo uscita gestione annoprec
            BEGIN

                StanziamentoCassa := StanziamentoRes + StanziamentoComp;

                update fase_bil_t_cap_calcolo_res h
				   set stanziamento=StanziamentoComp,
				       stanziamento_cassa=StanziamentoCassa
				 where h.fase_bil_elab_id=faseBilElabId
				   and h.elem_id=Capitoli.elem_id;

            EXCEPTION
                WHEN OTHERS THEN null;
            END;
        end loop;

    end if;




    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
        RAISE EXCEPTION ' Errore in inserimento LOG.';
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