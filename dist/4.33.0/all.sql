/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

-- 04.05.2021 Sofia Jira SIAC-7794 - inizio 
drop function if exists 
siac.fnc_siac_controllo_importo_impegni_vincolati 
(
  listaidalatto text
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_controllo_importo_impegni_vincolati (
  listaidalatto text
)
RETURNS TABLE (
  v_doc_anno integer,
  v_doc_numero varchar,
  v_subdoc_numero integer,
  v_eldoc_anno integer,
  v_eldoc_numero integer,
  v_subdoc_importo numeric,
  v_acc_anno integer,
  v_acc_numero numeric,v_importoord numeric
) AS
$body$
DECLARE
 arrayIdAlAtto 		integer[];
 indice     		integer:=1;
 idAttoAll  		integer;

 /* v_doc_anno		integer;
  v_doc_numero      VARCHAR(200);
  v_subdoc_numero   integer;
  v_eldoc_numero    integer;
  v_eldoc_anno      integer;
  v_subdoc_importo 	NUMERIC;
  v_acc_anno		integer;
  v_acc_numero      NUMERIC;
  v_importoOrd 		NUMERIC;*/
  strMessaggio		varchar(200);
  recVincolati      record;
begin

	arrayIdAlAtto = string_to_array(listaIdAlAtto,',');

    execute 'DROP TABLE IF EXISTS tmp_spesa_vincolata_non_finanziata;';
    -- 04.05.2021 Sofia Jira SIAC-7794
    execute 'CREATE TEMPORARY TABLE tmp_spesa_vincolata_non_finanziata (
                                                                doc_anno			integer,
                                                                doc_numero      	VARCHAR(200),
                                                                subdoc_numero   	integer,
                                                                eldoc_anno      	integer,
                                                                eldoc_numero    	integer,
                                                                subdoc_importo 		NUMERIC,
                                                                acc_anno            integer,
																acc_numero          NUMERIC,
                                                                importoOrd 			NUMERIC
    ) ON COMMIT DROP;'; -- 04.05.2021 Sofia Jira SIAC-7794
-- raise notice '@@@@ prima di while @@@@@';
while coalesce(arrayIdAlAtto[indice],0)!=0
  loop
    idAttoAll:=arrayIdAlAtto[indice];
   -- raise notice 'idAttoAll=% ',idAttoAll;
    indice:=indice+1;
	for recVincolati in (
	 select
       sum(subdoc.subdoc_importo) as totale_importo_subdoc
      ,r_movgest.movgest_ts_a_id as acc_ts_id
       ,r_movgest.movgest_ts_b_id as imp_ts_id
	from
		 siac_t_atto_allegato allegato
		,siac_r_atto_allegato_elenco_doc r_allegato_elenco
		,siac_t_elenco_doc elenco
		,siac_r_elenco_doc_subdoc r_elenco_subdoc
		,siac_r_subdoc_movgest_ts r_subdoc_movgest_ts
		,siac_t_movgest_ts imp_ts
		,siac_r_movgest_ts r_movgest
		,siac_t_subdoc subdoc
	where
		-- condizioni di join
			allegato.attoal_id =  r_allegato_elenco.attoal_id
		and r_allegato_elenco.eldoc_id =  elenco.eldoc_id
		and elenco.eldoc_id =  r_elenco_subdoc.eldoc_id
		and r_elenco_subdoc.subdoc_id =  r_subdoc_movgest_ts.subdoc_id
		and r_subdoc_movgest_ts.movgest_ts_id =  imp_ts.movgest_ts_id
		and imp_ts.movgest_ts_id = r_movgest.movgest_ts_b_id --impegno
		and r_elenco_subdoc.subdoc_id = subdoc.subdoc_id
		-- filtro su data cancellazione
		and allegato.data_cancellazione is null
		and r_allegato_elenco.data_cancellazione is null
        and now() >= r_allegato_elenco.validita_inizio
		and now() <= coalesce(r_allegato_elenco.validita_fine::timestamp with time zone, now())
		and elenco.data_cancellazione is null
		and r_elenco_subdoc.data_cancellazione is null
        and now() >= r_elenco_subdoc.validita_inizio
		and now() <= coalesce(r_elenco_subdoc.validita_fine::timestamp with time zone, now())
		and r_subdoc_movgest_ts.data_cancellazione is null
		and now() >= r_subdoc_movgest_ts.validita_inizio
		and now() <= coalesce(r_subdoc_movgest_ts.validita_fine::timestamp with time zone, now())
		and imp_ts.data_cancellazione is null
		and subdoc.data_cancellazione is null
		and r_movgest.data_cancellazione is null
		and now() >= r_movgest.validita_inizio
		and now() <= coalesce(r_movgest.validita_fine::timestamp with time zone, now())
		-- filtro su id atto allegato
		and allegato.attoal_id = idAttoAll
		-- gli accertamenti devono essere validi
		and exists (
			select 1
			from siac_r_movgest_ts_stato r_stato_acc
			,siac_d_movgest_stato acc_stato
			where r_stato_acc.data_cancellazione is null
			and acc_stato.movgest_stato_id = r_stato_acc.movgest_stato_id
			and r_stato_acc.movgest_ts_id = r_movgest.movgest_ts_a_id
			and now() >= r_stato_acc.validita_inizio
		    and now() <= coalesce(r_stato_acc.validita_fine::timestamp with time zone, now())
			and acc_stato.movgest_stato_code <> 'A'
		)
		--gli accertamenti devono essere di tipo accertamento
		and exists(
			select 1
			from siac_t_movgest_ts tmt
			,siac_t_movgest tm
			,siac_d_movgest_tipo dmt
			where tm.movgest_id = tmt.movgest_id
			and tmt.movgest_ts_id = r_movgest.movgest_ts_a_id
			and dmt.movgest_tipo_id = tm.movgest_tipo_id
			and dmt.movgest_tipo_code='A'
			and now() >= tm.validita_inizio
		    and now() <= coalesce(tm.validita_fine::timestamp with time zone, now())
			and now() >= tmt.validita_inizio
		    and now() <= coalesce(tmt.validita_fine::timestamp with time zone, now())
		)
		group by r_movgest.movgest_ts_a_id,r_movgest.movgest_ts_b_id
	)loop

	 v_doc_anno:=null;
	 v_doc_numero:=null;
	 v_subdoc_numero:=null;
	 v_eldoc_numero:=null;
	 v_eldoc_anno:=null;
	 v_subdoc_importo :=null;
	 v_acc_anno:=null;
	 v_acc_numero:=null;
	 v_importoOrd:=null;

 --   raise notice '@@@@@ vincolato @@@@@';
	--calcolo l'importo riscosso
	SELECT	coalesce(sum(detA.ord_ts_det_importo),0) into v_importoOrd
		FROM  siac_t_ordinativo ordinativo,
			  --siac_d_ordinativo_tipo tipo,
			  siac_r_ordinativo_stato rs,
			  siac_d_ordinativo_stato stato,
			  siac_t_ordinativo_ts ts,
			  siac_t_ordinativo_ts_det detA ,
			  siac_d_ordinativo_ts_det_tipo tipoA,
			  siac_r_ordinativo_ts_movgest_ts r_ordinativo_movgest
		WHERE  r_ordinativo_movgest.movgest_ts_id = recVincolati.acc_ts_id
		and    ts.ord_ts_id=r_ordinativo_movgest.ord_ts_id
		and    ordinativo.ord_id=ts.ord_id
		and    rs.ord_id=ordinativo.ord_id
	    and    stato.ord_stato_id=rs.ord_stato_id
		and    stato.ord_stato_code!='A'
--		and    tipo.ord_tipo_id=ordinativo.ord_tipo_id
--      and    tipo.ord_tipo_code='I'
		and    detA.ord_ts_id=ts.ord_ts_id
		and    tipoA.ord_ts_det_tipo_id=detA.ord_ts_det_tipo_id
		and    tipoA.ord_ts_det_tipo_code='A'
		and    ordinativo.data_cancellazione is null
		and    now() >= ordinativo.validita_inizio
		and    now() <= coalesce(ordinativo.validita_fine::timestamp with time zone, now())
		and    ts.data_cancellazione is null
		and    now() >= ts.validita_inizio
		and    now() <= coalesce(ts.validita_fine::timestamp with time zone, now())
		and    detA.data_cancellazione is null
		and    now() >= detA.validita_inizio
		and    now() <= coalesce(detA.validita_fine::timestamp with time zone, now())
		and    rs.data_cancellazione is null
		and    now() >= rs.validita_inizio
		and    now() <= coalesce(rs.validita_fine::timestamp with time zone, now())
		and    now() >= r_ordinativo_movgest.validita_inizio
		and    now() <= coalesce(r_ordinativo_movgest.validita_fine::timestamp with time zone, now());

--raise notice '@@@@ v_importoOrd=%@@@',v_importoOrd::varchar;
		if v_importoOrd < recVincolati.totale_importo_subdoc then
			--SIAC-6688
			select distinct tm.movgest_anno, tm.movgest_numero into v_acc_anno, v_acc_numero
			from siac_t_movgest tm
			,siac_t_movgest_ts tmt
			where tm.movgest_id = tmt.movgest_id
			and tmt.movgest_ts_id = recVincolati.acc_ts_id;

            --versione con tabella
			--/*
            insert into tmp_spesa_vincolata_non_finanziata
				select doc.doc_anno
				,doc.doc_numero
				,subdoc.subdoc_numero
                ,elenco.eldoc_anno
				,elenco.eldoc_numero
				,subdoc.subdoc_importo
				,v_acc_anno
				,v_acc_numero
				,v_importoOrd
		  -- */
           --versione con next
			/*select doc.doc_anno::integer
				  ,doc.doc_numero
				  ,subdoc.subdoc_numero::integer
				  ,elenco.eldoc_numero::integer
				  ,elenco.eldoc_anno::integer
				  ,subdoc.subdoc_importo
            into
				  v_doc_anno,
			      v_doc_numero,
				  v_subdoc_numero,
				  v_eldoc_numero,
				  v_eldoc_anno,
				  v_subdoc_importo
            */
			from siac_t_subdoc subdoc
				,siac_t_doc doc
				,siac_r_elenco_doc_subdoc r_elenco_sub
				,siac_t_elenco_doc elenco
                ,siac_r_subdoc_movgest_ts r_subdoc_movgest
                ,siac_r_atto_allegato_elenco_doc r_allegato_elenco
				where doc.doc_id = subdoc.doc_id
				and  r_elenco_sub.subdoc_id = subdoc.subdoc_id
			    and  elenco.eldoc_id = r_elenco_sub.eldoc_id
                and r_allegato_elenco.eldoc_id = elenco.eldoc_id
                and r_allegato_elenco.attoal_id = idAttoAll
                and r_subdoc_movgest.subdoc_id = r_elenco_sub.subdoc_id
				and r_subdoc_movgest.movgest_ts_id = recVincolati.imp_ts_id
                and r_subdoc_movgest.data_cancellazione is null
				and doc.data_cancellazione is null
				and subdoc.data_cancellazione is null
				and r_elenco_sub.data_cancellazione is null
				and elenco.data_cancellazione is null
                and r_allegato_elenco.data_cancellazione is null
                and exists(
                	select 1
                	from siac_r_elenco_doc_stato r_elenco_stato
                	,siac_d_elenco_doc_stato elenco_stato
                	where r_elenco_stato.eldoc_id = elenco.eldoc_id
                	and r_elenco_stato.eldoc_stato_id = elenco_stato.eldoc_stato_id
                	and elenco_stato.eldoc_stato_code = 'B'
                	and r_elenco_stato.data_cancellazione is null
                );
		-- return next;

		end if;
    end loop;
  end loop;

	RETURN QUERY

    SELECT
      *
    from
    	tmp_spesa_vincolata_non_finanziata
        order by acc_anno, acc_numero, eldoc_anno, eldoc_numero;

  -- return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;


alter function siac.fnc_siac_controllo_importo_impegni_vincolati(text) owner to siac;

-- 04.05.2021 Sofia Jira SIAC-7794 -- fine


-- 04.05.2021 Sofia JIRA - SIAC-8095 - inizio
drop function if exists 
siac.fnc_fasi_bil_gest_apertura_liq_elabora_imp (
  enteproprietarioid integer,
  annobilancio integer,
  tipoelab varchar,
  fasebilelabid integer,
  minid integer,
  maxid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_liq_elabora_imp (
  enteproprietarioid integer,
  annobilancio integer,
  tipoelab varchar,
  fasebilelabid integer,
  minid integer,
  maxid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
    strMessaggioTemp VARCHAR(1000):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

	tipoMovGestId      integer:=null;
    movGestTsTipoId    integer:=null;
    tipoMovGestTsSId   integer:=null;
    tipoMovGestTsTId   integer:=null;
    tipoCapitoloGestId integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;
    dataEmissione     timestamp:=null;
	movGestIdRet      integer:=null;
    movGestTsIdRet    integer:=null;
    elemNewId         integer:=null;
	movGestTsTipoTId  integer:=null;
	movGestTsTipoSId  integer:=null;
	movGestTsTipoCode VARCHAR(10):=null;
    movGestStatoAId   integer:=null;
	movgGestTsIdPadre integer:=null;

    movGestRec        record;
    aggProgressivi    record;

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


	IMP_MOVGEST_TIPO CONSTANT varchar:='I';

	CAP_UG_TIPO      CONSTANT varchar:='CAP-UG';

    MOVGEST_TS_T_TIPO CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO CONSTANT varchar:='S';

    A_MOV_GEST_STATO  CONSTANT varchar:='A';
    APE_GEST_LIQ_RES  CONSTANT varchar:='APE_GEST_LIQ_RES';

    APE_GEST_IMP_RES  CONSTANT varchar:='APE_GEST_IMP_RES';

    A_MOV_GEST_DET_TIPO  CONSTANT varchar:='A';
    I_MOV_GEST_DET_TIPO  CONSTANT varchar:='I';

	-- 15.02.2017 Sofia SIAC-4425
	FRAZIONABILE_ATTR CONSTANT varchar:='flagFrazionabile';
    flagFrazAttrId integer:=null;

    -- 15.02.2017 Sofia HD-INC000001535447
    ATTO_AMM_FIT_TIPO  CONSTANT varchar:='SPR';
    ATTO_AMM_FIT_OGG CONSTANT varchar:='Passaggio residuo.';
    ATTO_AMM_FIT_STATO CONSTANT VARCHAR:='DEFINITIVO';
    attoAmmFittizioId integer:=null;
	attoAmmNumeroFittizio  VARCHAR(10):='9'||annoBilancio::varchar||'99';


	-- 03.05.2019 Sofia siac-6255
    faseOp                    VARCHAR(10):=null;
    G_FASE                    CONSTANT varchar:='G'; -- gestione approvata

BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;



    dataInizioVal:= clock_timestamp();

    if tipoElab=APE_GEST_LIQ_RES then
 	 strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento movimenti  residui per ribaltamento liquidazioni res da Gestione precedente. Anno bilancio='||annoBilancio::varchar
                         ||'.Elabora  minId='||coalesce(minId::varchar,' ')||' maxId='||coalesce(maxId::varchar,' ')
                         ||'. Fase Elaborazione Id='||faseBilElabId||'.';
    else
     strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento movimenti  residui da Gestione precedente. Anno bilancio='||annoBilancio::varchar
                         ||'.Elabora  minId='||coalesce(minId::varchar,' ')||' maxId='||coalesce(maxId::varchar,' ')
                         ||'. Fase Elaborazione Id='||faseBilElabId||'.';
    end if;

     raise notice 'strMessaggioFinale %',strMessaggioFinale;

     strMessaggio:='Inserimento LOG.';
	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggioFinale||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

	codResult:=null;
    strMessaggio:='Verifica stato fase_bil_t_elaborazione.';
    select 1  into codResult
    from fase_bil_t_elaborazione fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_elab_esito like 'IN-%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;
    if codResult is null then
      raise exception ' Nessuna elaborazione in corso [IN-n].';
    end if;


    codResult:=null;
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_liq_imp.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_liq_imp fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   fase.fl_elab='N';
    if codResult is null then
      raise exception ' Nessun impegno da creare.';
    end if;

    if coalesce(minId,0)=0 or coalesce(maxId,0)=0 then
        strMessaggio:='Calcolo min, max Id da elaborare in [fase_bil_t_gest_apertura_liq_imp].';
    	minId:=1;

        select max(fase.fase_bil_gest_ape_liq_imp_id) into maxId
        from fase_bil_t_gest_apertura_liq_imp fase
	    where fase.fase_bil_elab_id=faseBilElabId
    	and   fase.data_cancellazione is null
	    and   fase.validita_fine is null
        and   fase.fl_elab='N';
        if coalesce(maxId ,0)=0 then
        	raise exception ' Impossibile determinare il maxId';
        end if;

    end if;

    -- 08.11.2019 Sofia SIAC-7145 - inizio
    strMessaggio:='Aggiornamento movimenti da creare in fase_bil_t_gest_apertura_liq_imp per esclusione importi a zero.';
    update fase_bil_t_gest_apertura_liq_imp fase
    set  scarto_code='IMP',
         scarto_desc='Importo a residuo pari a zero',
         fl_elab='X'
    where Fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_gest_ape_liq_imp_id between minId and maxId
    and   fase.fl_elab='N'
    and   fase.imp_importo=0
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;

    codResult:=null;
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_liq_imp dopo esclusione importi a zero.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_liq_imp fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   fase.fl_elab='N';
    if codResult is null then
      raise exception ' Nessun impegno da creare.';
    end if;
    -- 08.11.2019 Sofia SIAC-7145 - fine


     strMessaggio:='Lettura id identificativo per tipo capitolo='||CAP_UG_TIPO||'.';
	 select tipo.elem_tipo_id into strict tipoCapitoloGestId
     from siac_d_bil_elem_tipo tipo
     where tipo.elem_tipo_code=CAP_UG_TIPO
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

     strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioPrecId, periodoPrecId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio-1
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;

     strMessaggio:='Lettura id identificativo per movGestStatoA='||A_MOV_GEST_STATO||'.';
     select stato.movgest_stato_id into strict movGestStatoAId
     from siac_d_movgest_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.movgest_stato_code=A_MOV_GEST_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;

     -- per I
     strMessaggio:='Lettura id identificativo per tipoMovGestImp='||IMP_MOVGEST_TIPO||'.';
     select tipo.movgest_tipo_id into strict tipoMovGestId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=IMP_MOVGEST_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;


     -- 15.02.2017 Sofia HD-INC000001535447
     strMessaggio:='Lettura id identificativo atto amministrativo fittizio per passaggio residui.';
	 select a.attoamm_id into attoAmmFittizioId
     from siac_d_atto_amm_tipo tipo, siac_t_atto_amm a
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.attoamm_tipo_code=ATTO_AMM_FIT_TIPO
     and   a.attoamm_tipo_id=tipo.attoamm_tipo_id
     and   a.attoamm_anno::integer=annoBilancio
     and   a.attoamm_numero=attoAmmNumeroFittizio::integer
     and   a.data_cancellazione is null
     and   a.validita_fine is null;

     if attoAmmFittizioId is null then
        strMessaggio:='Inserimento atto amministrativo fittizio per passaggio residui.';
     	insert into siac_t_atto_amm
        ( attoamm_anno,
          attoamm_numero,
          attoamm_oggetto,
          attoamm_tipo_id,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
        )
        (select
          annoBilancio::varchar,
          attoAmmNumeroFittizio::integer,
          ATTO_AMM_FIT_OGG,
		  tipo.attoamm_tipo_id,
          dataInizioVal,
          loginOperazione,
          enteProprietarioId
         from siac_d_atto_amm_tipo tipo
         where tipo.ente_proprietario_id=enteProprietarioId
	     and   tipo.attoamm_tipo_code=ATTO_AMM_FIT_TIPO
        )
        returning attoamm_id into attoAmmFittizioId;

        if attoAmmFittizioId is null then
        	raise exception 'Inserimento non effettuato.';
        end if;

        codResult:=null;
        strMessaggio:='Inserimento stato atto amministrativo fittizio per passaggio residui.';
        insert into siac_r_atto_amm_stato
        (attoamm_id,
         attoamm_stato_id,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
        )
        (select  attoAmmFittizioId,
                 stato.attoamm_stato_id,
        		 dataInizioVal,
         		 loginOperazione,
		         enteProprietarioId
         from siac_d_atto_amm_stato stato
         where stato.ente_proprietario_id=enteProprietarioId
         and   stato.attoamm_stato_code=ATTO_AMM_FIT_STATO
         )
         returning att_attoamm_stato_id into codResult;
         if codResult is null then
         	raise exception 'Inserimento non effettuato.';
         end if;
     end if;
     -- 15.02.2017 Sofia HD-INC000001535447

     strMessaggio:='Lettura identificativo per tipoMovGestTsT='||MOVGEST_TS_T_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict tipoMovGestTsTId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_T_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura identificativo per tipoMovGestTsS='||MOVGEST_TS_S_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict tipoMovGestTsSId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_S_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

	 -- 15.02.2017 Sofia SIAC-4425
     strMessaggio:='Lettura identificativo per flagFrazAttrCode='||FRAZIONABILE_ATTR||'.';
   	 select attr.attr_id into strict flagFrazAttrId
     from siac_t_attr attr
     where attr.ente_proprietario_id=enteProprietarioId
     and   attr.attr_code=FRAZIONABILE_ATTR
     and   attr.data_cancellazione is null
     and   attr.validita_fine is null;


     -- 03.05.2019 Sofia siac-6255
     strMessaggio:='Lettura fase di bilancio di corrente.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
     if faseOp is null then
		 raise exception ' Impossibile determinare Fase.';
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
     	raise exception ' Errore in inserimento LOG.';
     end if;


     strMessaggio:='Inizio ciclo per generazione impegni.';
     codResult:=null;
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

     raise notice 'Prima di inizio ciclo';
     for movGestRec in
     (select  fase.fase_bil_gest_ape_liq_imp_id,
	   		  fase.movgest_ts_tipo,
		      fase.movgest_orig_id,
	          fase.movgest_orig_ts_id,
		      fase.elem_orig_id,
              fase.elem_id,
              fase.elem_orig_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
              fase.elem_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
	          fase.imp_importo
      from  fase_bil_t_gest_apertura_liq_imp fase
      where fase.fase_bil_elab_id=faseBilElabId
      and   fase.fase_bil_gest_ape_liq_imp_id between minId and maxId
      and   fase.fl_elab='N'
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
/*      and   exists -- x test siac-6255
      (
      select 1
      from siac_r_movgest_ts_programma r
      where r.movgest_ts_id=fase.movgest_orig_ts_id
      and   r.data_cancellazione is null
      and   r.validita_fine is null
      ) */
      order by fase.movgest_ts_tipo desc,fase.movgest_orig_id,
	           fase.movgest_orig_ts_id
     )
     loop

     	movGestTsIdRet:=null;
        movGestIdRet:=null;
        movgGestTsIdPadre:=null;
        codResult:=null;




         strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.';
 		 insert into fase_bil_t_elaborazione_log
	     (fase_bil_elab_id,fase_bil_elab_log_operazione,
    	 validita_inizio, login_operazione, ente_proprietario_id
	     )
	     values
    	 (faseBilElabId,strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
	     returning fase_bil_elab_log_id into codResult;

	     if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	     end if;

    	 codResult:=null;
		 if movGestRec.movgest_ts_tipo=MOVGEST_TS_T_TIPO then
      	  strMessaggio:=strMessaggio||'Inserimento Impegno [siac_t_movgest].';

          raise notice 'strMessaggio %',strMessaggio;
     	  insert into siac_t_movgest
          (movgest_anno,
		   movgest_numero,
		   movgest_desc,
		   movgest_tipo_id,
		   bil_id,
		   validita_inizio,
	       ente_proprietario_id,
	       login_operazione,
	       parere_finanziario,
	       parere_finanziario_data_modifica,
	       parere_finanziario_login_operazione
		   )
          (select
           m.movgest_anno,
		   m.movgest_numero,
		   m.movgest_desc,
		   m.movgest_tipo_id,
		   bilancioId,
		   dataInizioVal,
	       enteProprietarioId,
	       loginOperazione,
	       m.parere_finanziario,
	       m.parere_finanziario_data_modifica,
	       m.parere_finanziario_login_operazione
           from siac_t_movgest m
           where m.movgest_id=movGestRec.movgest_orig_id
          )
          returning movgest_id into movGestIdRet;
          if movGestIdRet is null then
            strMessaggioTemp:=strMessaggio;
            codResult:=-1;
          end if;

		  raise notice 'dopo inserimento siac_t_movgest T movGestIdRet=%',movGestIdRet;
		  raise notice 'dopo inserimento siac_t_movgest T strMessaggioTemp=%',strMessaggioTemp;

	      if codResult is null then
          	  strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Inserimento relazione elemento di bilancio [siac_r_movgest_bil_elem].';
	          insert into siac_r_movgest_bil_elem
    	      (movgest_id,
	    	   elem_id,
               elem_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
	           validita_inizio,
    	       ente_proprietario_id,
        	   login_operazione)
	          values
    	      (movGestIdRet,
        	   movGestRec.elem_id,
               movGestRec.elem_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
	           dataInizioVal,
    	       enteProprietarioId,
        	   loginOperazione
		       )
    	       returning movgest_atto_amm_id into codResult;
        	   if codResult is null then
            	codResult:=-1;
	            strMessaggioTemp:=strMessaggio;
               else codResult:=null;
    	       end if;
          end if;
      else

        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.Lettura identificativo impegno.';

          raise notice 'strMessaggio %',strMessaggio;
		select mov.movgest_id into movGestIdRet
        from siac_t_movgest mov, siac_t_movgest movprec
        where movprec.movgest_id=movGestRec.movgest_orig_id
        and   mov.bil_id=bilancioId
        and   mov.movgest_tipo_id=tipoMovGestId
        and   mov.movgest_anno=movprec.movgest_anno
        and   mov.movgest_numero=movprec.movgest_numero
        and   mov.data_cancellazione is null
        and   mov.validita_fine is null
        and   movprec.data_cancellazione is null
        and   movprec.validita_fine is null;

        if movGestIdRet is null then
	        codResult:=-1;
            strMessaggioTemp:=strMessaggio;
        end if;

        raise notice 'dopo lettura siac_t_movgest T per inserimento subimpegno movGestIdRet=%',movGestIdRet;

        if codResult is null then

         	 strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.Lettura identificativo siac_t_movgest_ts movgGestTsIdPadre.';
			strMessaggioTemp:=strMessaggio;
        	select ts.movgest_ts_id into movgGestTsIdPadre
	        from siac_t_movgest_ts ts
    	    where ts.movgest_id=movGestIdRet
	        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
    	    and   ts.data_cancellazione is null
        	and   ts.validita_fine is null;

			raise notice 'dopo lettura siac_t_movgest_ts T per inserimento subimpegno movgGestTsIdPadre=%',movgGestTsIdPadre;

        end if;

        raise notice 'dopo lettura siac_t_movgest movGestIdRet=%',movGestIdRet;
        raise notice 'dopo lettura siac_t_movgest strMessaggioTemp=%',strMessaggioTemp;
      end if;

      -- inserimento TS sia T che S
      if codResult is null then
   	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'Inserimento [siac_t_movgest_ts].';

		raise notice 'strMessaggio=% ',strMessaggio;

        insert into siac_t_movgest_ts
        ( movgest_ts_code,
          movgest_ts_desc,
          movgest_id,
	      movgest_ts_tipo_id,
          movgest_ts_id_padre,
          movgest_ts_scadenza_data,
	      ordine,
		  livello,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione,
	      login_creazione,
		  siope_tipo_debito_id ,
  		  siope_assenza_motivazione_id
        )
        ( select
          ts.movgest_ts_code,
          ts.movgest_ts_desc,
          movGestIdRet,    -- inserito se I, per SUB ricavato
          ts.movgest_ts_tipo_id,
          movgGestTsIdPadre, -- da ricavare dal TS T di impegno padre
          ts.movgest_ts_scadenza_data,
          ts.ordine,
          ts.livello,
--          dataEmissione,
          ts.validita_inizio, -- i residui devono mantenere la loro data di emissione originale
          enteProprietarioId,
          loginOperazione,
          loginOperazione,
		  ts.siope_tipo_debito_id ,
  		  ts.siope_assenza_motivazione_id
          from siac_t_movgest_ts ts
          where ts.movgest_ts_id=movGestRec.movgest_orig_ts_id
         )
        returning movgest_ts_id into  movGestTsIdRet;
        if movGestTsIdRet is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        end if;
       end if;

       raise notice 'dopo inserimento siac_t_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

       -- siac_r_movgest_ts_stato
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                       ' [siac_r_movgest_ts_stato].';

        insert into siac_r_movgest_ts_stato
        ( movgest_ts_id,
          movgest_stato_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_stato_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_stato r, siac_d_movgest_stato stato
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   stato.movgest_stato_id=r.movgest_stato_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   stato.data_cancellazione is null
          and   stato.validita_fine is null
         )
        returning movgest_stato_r_id into  codResult;
        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;
        raise notice 'dopo inserimento siac_r_movgest_ts_stato movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

       -- siac_t_movgest_ts_det
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                     ' [siac_t_movgest_ts_det].';
        raise notice ' inserimento siac_t_movgest_ts_det movGestTsIdRet=% movGestRec.movgest_orig_ts_id=%', movGestTsIdRet,movGestRec.movgest_orig_ts_id;

        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        (  select
           movGestTsIdRet,
           tipo.movgest_ts_det_tipo_id,
           movGestRec.imp_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_d_movgest_ts_det_tipo tipo
          where  tipo.ente_proprietario_id=enteProprietarioId
          and    tipo.movgest_ts_det_tipo_code in (A_MOV_GEST_DET_TIPO,I_MOV_GEST_DET_TIPO)
         );

		select 1 into codResult
        from siac_t_movgest_ts_det det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_t_movgest_ts_det movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_class
       if codResult is null then
   	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                     ' [siac_r_movgest_class].';

        insert into siac_r_movgest_class
        ( movgest_ts_id,
          classif_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.classif_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_class r, siac_t_class class
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   class.classif_id=r.classif_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   class.data_cancellazione is null
          and   class.validita_fine is null
         );

        select 1 into codResult
        from siac_r_movgest_class det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_r_movgest_class movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
         else codResult:=null;
         end if;
       end if;

       -- siac_r_movgest_ts_attr
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_attr].';

        insert into siac_r_movgest_ts_attr
        ( movgest_ts_id,
          attr_id,
          tabella_id,
		  boolean,
	      percentuale,
		  testo,
	      numerico,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
          movGestTsIdRet,
          r.attr_id,
          r.tabella_id,
		  r.boolean,
	      r.percentuale,
		  r.testo,
	      r.numerico,
          dataInizioVal,
          enteProprietarioId,
          loginOperazione
          from siac_r_movgest_ts_attr r, siac_t_attr attr
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   attr.attr_id=r.attr_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   attr.data_cancellazione is null
          and   attr.validita_fine is null
         );

		select 1 into codResult
        from siac_r_movgest_ts_attr det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_r_movgest_ts_attr movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_atto_amm
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_atto_amm].';

        insert into siac_r_movgest_ts_atto_amm
        ( movgest_ts_id,
          attoamm_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.attoamm_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_atto_amm r, siac_t_atto_amm atto
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   atto.attoamm_id=r.attoamm_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         -- and   atto.data_cancellazione is null 15.02.2017 Sofia HD-INC000001535447
         -- and   atto.validita_fine is null
         );

       /* select 1 into codResult
        from siac_r_movgest_ts_atto_amm det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_movgest_ts_atto_amm det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_atto_amm det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

       -- raise notice 'dopo inserimento siac_r_movgest_ts_atto_amm movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        -- 15.02.2017 Sofia HD-INC000001535447 inserimento relazione con atto amministrativo fittizio
        if codResult is not null then
        	codResult:=null;
            strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_atto_amm]. Inserimento atto amm. fittizio.';
        	insert into siac_r_movgest_ts_atto_amm
            (
             movgest_ts_id,
		     attoamm_id,
			 validita_inizio,
			 login_operazione,
			 ente_proprietario_id
            )
            values
            (
             movGestTsIdRet,
             attoAmmFittizioId,
             dataInizioVal,
	         loginOperazione,
             enteProprietarioId
            )
            returning movgest_atto_amm_id into codResult;

            if codResult is null then
       	 		codResult:=-1;
	         strMessaggioTemp:=strMessaggio;
    	    else codResult:=null;
        	end if;
        end if;

       end if;

       -- siac_r_movgest_ts_sog
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_sog].';

        insert into siac_r_movgest_ts_sog
        ( movgest_ts_id,
          soggetto_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.soggetto_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_sog r,siac_t_soggetto sogg
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sogg.soggetto_id=r.soggetto_id
          and   sogg.data_cancellazione is null
          and   sogg.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );



 		select 1  into codResult
        from siac_r_movgest_ts_sog det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_sog det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        raise notice 'dopo inserimento siac_r_movgest_ts_sog movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;


        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_sogclasse
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_sogclasse].';

        insert into siac_r_movgest_ts_sogclasse
        ( movgest_ts_id,
          soggetto_classe_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.soggetto_classe_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_sogclasse r,siac_d_soggetto_classe classe
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   classe.soggetto_classe_id=r.soggetto_classe_id
--          and   classe.data_cancellazione is null
--          and   classe.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

        select 1  into codResult
        from siac_r_movgest_ts_sogclasse det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_sogclasse det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_movgest_ts_sogclasse movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_programma
       if codResult is null then
	   	if faseOp=G_FASE then
          strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                        ' [siac_r_movgest_ts_programma].';

          insert into siac_r_movgest_ts_programma
          ( movgest_ts_id,
            programma_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             pnew.programma_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_programma r,siac_t_programma prog,
                 siac_t_programma pnew,siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   prog.programma_id=r.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.bil_id=bilancioId
            and   pnew.programma_code=prog.programma_code
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
--            and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
            and   stato.programma_stato_code!='AN'			-- 06.08.2019 Sofia SIAC-6934
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
           );

		   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                         ' solo cronop [siac_r_movgest_ts_cronop_elem].';

          insert into siac_r_movgest_ts_cronop_elem
          ( movgest_ts_id,
            cronop_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             cnew.cronop_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_cronop_elem r,
                 siac_t_cronop cronop,
                 siac_t_programma prog,
                 siac_t_programma pnew,siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato,
                 siac_t_cronop cnew, siac_r_cronop_stato rsc, siac_d_cronop_stato cstato
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   r.cronop_elem_id is null
            and   cronop.cronop_id=r.cronop_id
            and   prog.programma_id=cronop.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.programma_code=prog.programma_code
            and   cnew.programma_id=pnew.programma_id
            and   cnew.bil_id=bilancioId
			and   cnew.cronop_code=cronop.cronop_code
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
            --and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
            and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   rsc.cronop_id=cnew.cronop_id
            and   cstato.cronop_stato_id=rsc.cronop_stato_id
            --and   cstato.cronop_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
	        and   cstato.cronop_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   cronop.data_cancellazione is null
            and   cronop.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   cnew.data_cancellazione is null
            and   cnew.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   rsc.data_cancellazione is null
            and   rsc.validita_fine is null
           );

           strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                         ' dettaglio cronop [siac_r_movgest_ts_cronop_elem].';

          insert into siac_r_movgest_ts_cronop_elem
          ( movgest_ts_id,
            cronop_id,
            cronop_elem_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             celem_new.cronop_id,
             celem_new.cronop_elem_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_cronop_elem r,siac_t_cronop_elem celem,
		         siac_t_cronop_elem_det det,
                 siac_t_cronop cronop,
                 siac_t_programma prog,
                 siac_t_programma pnew,siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato,
                 siac_t_cronop cnew, siac_r_cronop_stato rsc, siac_d_cronop_stato cstato,
                 siac_t_cronop_elem celem_new,siac_t_cronop_elem_det det_new
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   r.cronop_elem_id is not null
            and   celem.cronop_elem_id=r.cronop_elem_id
            and   det.cronop_elem_id=celem.cronop_elem_id
            and   cronop.cronop_id=celem.cronop_id
            and   prog.programma_id=cronop.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.programma_code=prog.programma_code
            and   cnew.programma_id=pnew.programma_id
            and   celem_new.cronop_id=cnew.cronop_id
            and   det_new.cronop_elem_id=celem_new.cronop_elem_id
            and   cnew.bil_id=bilancioId
			and   cnew.cronop_code=cronop.cronop_code
            and   coalesce(celem_new.cronop_elem_code,'')=coalesce(celem.cronop_elem_code,'')
            and   coalesce(celem_new.cronop_elem_code2,'')=coalesce(celem.cronop_elem_code2,'')
            and   coalesce(celem_new.cronop_elem_code3,'')=coalesce(celem.cronop_elem_code3,'')
            and   coalesce(celem_new.elem_tipo_id,0)=coalesce(celem.elem_tipo_id,0)
            and   coalesce(celem_new.cronop_elem_desc,'')=coalesce(celem.cronop_elem_desc,'')
            and   coalesce(celem_new.cronop_elem_desc2,'')=coalesce(celem.cronop_elem_desc2,'')
            and   coalesce(det_new.periodo_id,0)=coalesce(det.periodo_id,0)
		    and   coalesce(det_new.cronop_elem_det_importo,0)=coalesce(det.cronop_elem_det_importo,0)
            and   coalesce(det_new.cronop_elem_det_desc,'')=coalesce(det.cronop_elem_det_desc,'')
	        and   coalesce(det_new.anno_entrata,'')=coalesce(det.anno_entrata,'')
	        and   coalesce(det_new.elem_det_tipo_id,0)=coalesce(det.elem_det_tipo_id,0)
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
            --and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
		    and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   rsc.cronop_id=cnew.cronop_id
            and   cstato.cronop_stato_id=rsc.cronop_stato_id
            --and   cstato.cronop_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
		    and   cstato.cronop_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   exists
            (
              select 1
              from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
              where rc.cronop_elem_id=celem.cronop_elem_id
              and   c.classif_id=rc.classif_id
              and   tipo.classif_tipo_id=c.classif_tipo_id
              and   exists
              (
                select 1
                from siac_r_cronop_elem_class rc1, siac_t_class c1
                where rc1.cronop_elem_id=celem_new.cronop_elem_id
                and   c1.classif_id=rc1.classif_id
                and   c1.classif_tipo_id=tipo.classif_tipo_id
                and   c1.classif_code=c.classif_code
                and   rc1.data_cancellazione is null
                and   rc1.validita_fine is null
              )
              and   rc.data_cancellazione is null
              and   rc.validita_fine is null
            )
            and  not exists
            (
              select 1
              from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
              where rc.cronop_elem_id=celem.cronop_elem_id
              and   c.classif_id=rc.classif_id
              and   tipo.classif_tipo_id=c.classif_tipo_id
              and   not exists
              (
                select 1
                from siac_r_cronop_elem_class rc1, siac_t_class c1
                where rc1.cronop_elem_id=celem_new.cronop_elem_id
                and   c1.classif_id=rc1.classif_id
                and   c1.classif_tipo_id=tipo.classif_tipo_id
                and   c1.classif_code=c.classif_code
                and   rc1.data_cancellazione is null
                and   rc1.validita_fine is null
              )
              and   rc.data_cancellazione is null
              and   rc.validita_fine is null
            )
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   cronop.data_cancellazione is null
            and   cronop.validita_fine is null
            and   celem.data_cancellazione is null
            and   celem.validita_fine is null
            and   det.data_cancellazione is null
            and   det.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   cnew.data_cancellazione is null
            and   cnew.validita_fine is null
            and   celem_new.data_cancellazione is null
            and   celem_new.validita_fine is null
            and   det_new.data_cancellazione is null
            and   det_new.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   rsc.data_cancellazione is null
            and   rsc.validita_fine is null
           );
        end if;
       end if;


       /*if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_programma].';

        insert into siac_r_movgest_ts_programma
        ( movgest_ts_id,
          programma_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.programma_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_programma r,siac_t_programma prog
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   prog.programma_id=r.programma_id
          and   prog.data_cancellazione is null
          and   prog.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );


		select 1  into codResult
        from siac_r_movgest_ts_programma det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_programma det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_movgest_ts_programma movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/

       -- siac_r_mutuo_voce_movgest
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_mutuo_voce_movgest].';

        insert into siac_r_mutuo_voce_movgest
        ( movgest_ts_id,
          mut_voce_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.mut_voce_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_mutuo_voce_movgest r,siac_t_mutuo_voce voce
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   voce.mut_voce_id=r.mut_voce_id
          and   voce.data_cancellazione is null
          and   voce.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );


		select 1  into codResult
        from siac_r_mutuo_voce_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_mutuo_voce_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_mutuo_voce_movgest movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- inserire il resto dei record legati al TS
       -- verificare quali sono da ribaltare e verificare se usare

       -- siac_r_giustificativo_movgest
       /* cassa-economale da non ribaltare come da indicazioni di Irene
        if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_giustificativo_movgest].';

        insert into siac_r_giustificativo_movgest
        ( movgest_ts_id,
          gst_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.gst_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_giustificativo_movgest r,siac_t_giustificativo gst
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   gst.gst_id=r.gst_id
          and   gst.data_cancellazione is null
          and   gst.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );


		select 1  into codResult
        from siac_r_giustificativo_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_giustificativo_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_giustificativo_movgest movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/


       -- siac_r_cartacont_det_movgest_ts
       /* Non si ribalta in seguito ad indicazioni di Annalina
        if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_cartacont_det_movgest_ts].';

        insert into siac_r_cartacont_det_movgest_ts
        ( movgest_ts_id,
          cartac_det_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.cartac_det_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_cartacont_det_movgest_ts r,siac_t_cartacont_det carta
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   carta.cartac_det_id=r.cartac_det_id
          and   carta.data_cancellazione is null
          and   carta.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );


		select 1  into codResult
        from siac_r_cartacont_det_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_cartacont_det_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_cartacont_det_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; **/

       -- siac_r_causale_movgest_ts
       /* non si gestisce in seguito ad indicazioni di Annalina
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_causale_movgest_ts].';

        insert into siac_r_causale_movgest_ts
        ( movgest_ts_id,
          caus_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.caus_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_causale_movgest_ts r,siac_d_causale caus
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   caus.caus_id=r.caus_id
          and   caus.data_cancellazione is null
          and   caus.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_causale_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_causale_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_causale_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */

       -- siac_r_fondo_econ_movgest
       /* cassa-economale da non ribaltare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_causale_movgest_ts].';

        insert into siac_r_fondo_econ_movgest
        ( movgest_ts_id,
          fondoecon_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.fondoecon_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_fondo_econ_movgest r,siac_t_fondo_econ econ
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   econ.fondoecon_id=r.fondoecon_id
          and   econ.data_cancellazione is null
          and   econ.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_fondo_econ_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_fondo_econ_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_fondo_econ_movgest movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/

       -- siac_r_richiesta_econ_movgest
       /* cassa-economale da non ribaltare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_richiesta_econ_movgest].';

        insert into siac_r_richiesta_econ_movgest
        ( movgest_ts_id,
          ricecon_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.ricecon_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_richiesta_econ_movgest r,siac_t_richiesta_econ econ
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   econ.ricecon_id=r.ricecon_id
          and   econ.data_cancellazione is null
          and   econ.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_richiesta_econ_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_richiesta_econ_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_richiesta_econ_movgest movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/

       -- siac_r_subdoc_movgest_ts
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_subdoc_movgest_ts].';
        -- 12.01.2017 Sofia correzione per esclusione quote pagate
        insert into siac_r_subdoc_movgest_ts
        ( movgest_ts_id,
          subdoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select distinct
           movGestTsIdRet,
           r.subdoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=r.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
          -- 04.05.2021 Sofia SIAC-8095
          and  not exists (
				           select 1
                           from siac_r_subdoc_ordinativo_ts rord, siac_t_ordinativo_ts ts, siac_t_ordinativo ord
                           where rord.subdoc_id=r.subdoc_id
                           and   ts.ord_ts_id=rord.ord_ts_id
                           and   ord.ord_id=ts.ord_id
                           and   ord.ord_anno>annoBilancio
                           and   rord.data_cancellazione is null
                           and   rord.validita_fine is null
                          )
          -- 04.05.2021 Sofia SIAC-8095
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          -- 10.04.2018 Daniela esclusione documenti annullati (SIAC-6015)
          and   not exists (select 1
          				    from siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                            where doc.doc_id = sub.doc_id
                            and   doc.doc_id = rst.doc_id
                            and   rst.data_cancellazione is null
                            and   rst.validita_fine is null
                            and   st.doc_stato_id = rst.doc_stato_id
                            and   st.doc_stato_code = 'A')
         );

		select 1  into codResult
        from siac_r_subdoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=det1.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
        -- 04.05.2021 Sofia SIAC-8095
          and  not exists (
				           select 1
                           from siac_r_subdoc_ordinativo_ts rord, siac_t_ordinativo_ts ts, siac_t_ordinativo ord
                           where rord.subdoc_id=det1.subdoc_id
                           and   ts.ord_ts_id=rord.ord_ts_id
                           and   ord.ord_id=ts.ord_id
                           and   ord.ord_anno>annoBilancio
                           and   rord.data_cancellazione is null
                           and   rord.validita_fine is null
                          )
          -- 04.05.2021 Sofia SIAC-8095
        and   not exists (select 1 from siac_r_subdoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione)
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1
          				    from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                            where det1.subdoc_id = sub.subdoc_id
                            and   doc.doc_id = sub.doc_id
                            and   doc.doc_id = rst.doc_id
                            and   rst.data_cancellazione is null
                            and   rst.validita_fine is null
                            and   st.doc_stato_id = rst.doc_stato_id
                            and   st.doc_stato_code = 'A');

        raise notice 'dopo inserimento siac_r_subdoc_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_predoc_movgest_ts
	   if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_predoc_movgest_ts].';

        insert into siac_r_predoc_movgest_ts
        ( movgest_ts_id,
          predoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.predoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_predoc_movgest_ts r,siac_t_predoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.predoc_id=r.predoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_predoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   not exists (select 1 from siac_r_predoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione)
		and   det1.data_cancellazione is null
        and   det1.validita_fine is null;

        raise notice 'dopo inserimento siac_r_predoc_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       --- cancellazione relazioni del movimento precedente
	   -- siac_r_subdoc_movgest_ts
      /*   spostato sotto dopo pulizia in caso di codResult null
           if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_subdoc_movgest_ts].';
	        update siac_r_subdoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_subdoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	       end if;

       end if;

       -- siac_r_predoc_movgest_ts
       if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_predoc_movgest_ts].';
	        update siac_r_predoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_predoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	        end if;
       end if; */

       -- siac_r_cartacont_det_movgest_ts
       /* non si gestisce in seguito ad indicazioni di Annalina
       if codResult is null then
    	 	strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
	                      ' movgest_orig_id='||movGestRec.movgest_orig_id||
                          ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                          ' elem_orig_id='||movGestRec.elem_orig_id||
                          ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_cartacont_det_movgest_ts].';
	        update siac_r_cartacont_det_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_cartacont_det_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	       end if;
       end if; */


	   -- 17.06.2019 Sofia SIAC-6702 - inizio
	   if codResult is null then
       	strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                        ' [siac_r_movgest_ts_storico_imp_acc].';

        insert into siac_r_movgest_ts_storico_imp_acc
        ( movgest_ts_id,
          movgest_anno_acc,
          movgest_numero_acc,
          movgest_subnumero_acc,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_anno_acc,
           r.movgest_numero_acc,
           r.movgest_subnumero_acc,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_storico_imp_acc r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
        );


        select 1  into codResult
        from siac_r_movgest_ts_storico_imp_acc det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_storico_imp_acc det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_movgest_ts_storico_imp_acc movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;
       -- 17.06.2019 Sofia SIAC-6702 - fine

       -- pulizia dati inseriti
       -- aggiornamento fase_bil_t_gest_apertura_liq_imp per scarto
	   if codResult=-1 then


        if movGestTsIdRet is not null then


         -- siac_r_movgest_class
	     strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_class.';
         delete from siac_r_movgest_class    where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_attr
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_attr.';
         delete from siac_r_movgest_ts_attr     where movgest_ts_id=movGestTsIdRet;
		 -- siac_r_movgest_ts_atto_amm
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_attr.';
         delete from siac_r_movgest_ts_atto_amm     where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_stato
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_stato.';
         delete from siac_r_movgest_ts_stato     where movgest_ts_id=movGestTsIdRet;
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_sog.';
         delete from siac_r_movgest_ts_sog      where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_sogclasse
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_sogclasse.';
         delete from siac_r_movgest_ts_sogclasse      where movgest_ts_id=movGestTsIdRet;
         -- siac_t_movgest_ts_det
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_t_movgest_ts_det.';
         delete from siac_t_movgest_ts_det      where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_programma
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_programma.';
         delete from siac_r_movgest_ts_programma where movgest_ts_id=movGestTsIdRet;
         -- siac_r_mutuo_voce_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_mutuo_voce_movgest.';
         delete from siac_r_mutuo_voce_movgest where movgest_ts_id=movGestTsIdRet;
         -- siac_r_giustificativo_movgest
/*         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_giustificativo_movgest.';
         delete from siac_r_giustificativo_movgest where movgest_ts_id=movGestTsIdRet;
         -- siac_r_cartacont_det_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_cartacont_det_movgest_ts.';
         delete from siac_r_cartacont_det_movgest_ts where movgest_ts_id=movGestTsIdRet;
         -- siac_r_causale_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_causale_movgest_ts.';
         delete from siac_r_causale_movgest_ts where movgest_ts_id=movGestTsIdRet;

		 -- siac_r_fondo_econ_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_fondo_econ_movgest.';
         delete from siac_r_fondo_econ_movgest where movgest_ts_id=movGestTsIdRet;
	     -- siac_r_richiesta_econ_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_richiesta_econ_movgest.';
         delete from siac_r_richiesta_econ_movgest where movgest_ts_id=movGestTsIdRet; */
         -- siac_r_subdoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_subdoc_movgest_ts.';
         delete from siac_r_subdoc_movgest_ts where movgest_ts_id=movGestTsIdRet;
         -- siac_r_predoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_predoc_movgest_ts.';
         delete from siac_r_predoc_movgest_ts where movgest_ts_id=movGestTsIdRet;

		 -- 03.05.2019 Sofia siac-6255
		 -- siac_r_movgest_ts_programma
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_programma.';
         delete from siac_r_movgest_ts_programma   where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_cronop_elem
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_cronop_elem.';
         delete from siac_r_movgest_ts_cronop_elem where movgest_ts_id=movGestTsIdRet;

	     -- 17.06.2019 Sofia siac-6702
         -- siac_r_movgest_ts_storico_imp_acc
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_storico_imp_acc.';
         delete from siac_r_movgest_ts_storico_imp_acc  where movgest_ts_id=movGestTsIdRet;


         -- siac_t_movgest_ts
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_t_movgest_ts.';
         delete from siac_t_movgest_ts         where movgest_ts_id=movGestTsIdRet;
        end if;

		if  movGestRec.movgest_ts_tipo=MOVGEST_TS_T_TIPO then
            -- siac_r_movgest_bil_elem
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';

            delete from siac_r_movgest_bil_elem where movgest_id=movGestIdRet;
        	-- siac_t_movgest
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';
            delete from siac_t_movgest          where movgest_id=movGestIdRet;

        end if;




/*        strMessaggio:=strMessaggioTemp||
                     ' Non Effettuato. Aggiornamento fase_bil_t_gest_apertura_liq_imp per scarto.';*/
        strMessaggioTemp:=strMessaggio;
        strMessaggio:=strMessaggio||
                      'Aggiornamento fase_bil_t_gest_apertura_liq_imp per scarto.';

      	update fase_bil_t_gest_apertura_liq_imp fase
        set fl_elab='X',
            scarto_code='RES1',
            scarto_desc='Movimento impegno/subimpegno residuo non inserito.'||strMessaggioTemp
        where fase.fase_bil_gest_ape_liq_imp_id=movGestRec.fase_bil_gest_ape_liq_imp_id
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.fl_elab='N'
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null;

		continue;
       end if;

       --- cancellazione relazioni del movimento precedente
	   -- siac_r_subdoc_movgest_ts
       if codResult is null then
            --- 12.01.2017 Sofia - sistemazione update per escludere le quote pagate
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_subdoc_movgest_ts].';
	        update siac_r_subdoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   not exists (select 1
                              from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                   siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	  where rord.subdoc_id=r.subdoc_id
	        		          and   tsord.ord_ts_id=rord.ord_ts_id
			                  and   ord.ord_id=tsord.ord_id
			                  and   ord.bil_id=bilancioPrecId
		            	      and   rstato.ord_id=ord.ord_id
		                	  and   stato.ord_stato_id=rstato.ord_stato_id
			                  and   stato.ord_stato_code!='A'
			                  and   rord.data_cancellazione is null
			                  and   rord.validita_fine is null
		    	              and   rstato.data_cancellazione is null
		        	          and   rstato.validita_fine is null
        		    	     )
		   -- 04.05.2021 Sofia SIAC-8095
           and  not exists (
				           select 1
                           from siac_r_subdoc_ordinativo_ts rord, siac_t_ordinativo_ts ts, siac_t_ordinativo ord
                           where rord.subdoc_id=r.subdoc_id
                           and   ts.ord_ts_id=rord.ord_ts_id
                           and   ord.ord_id=ts.ord_id
                           and   ord.ord_anno>annoBilancio
                           and   rord.data_cancellazione is null
                           and   rord.validita_fine is null
                          )
            -- 04.05.2021 Sofia SIAC-8095
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null
            and   not exists (select 1
                              from siac_t_subdoc sub,siac_t_doc  doc, siac_r_doc_stato rst, siac_d_doc_stato st
                              where r.subdoc_id = sub.subdoc_id
                              and   doc.doc_id = sub.doc_id
                              and   doc.doc_id = rst.doc_id
                              and   rst.data_cancellazione is null
                              and   rst.validita_fine is null
                              and   st.doc_stato_id = rst.doc_stato_id
                              and   st.doc_stato_code = 'A')
            ;

	        select 1 into codResult
    	    from siac_r_subdoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   not exists (select 1
                              from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                   siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	  where rord.subdoc_id=r.subdoc_id
	        		          and   tsord.ord_ts_id=rord.ord_ts_id
			                  and   ord.ord_id=tsord.ord_id
			                  and   ord.bil_id=bilancioPrecId
		            	      and   rstato.ord_id=ord.ord_id
		                	  and   stato.ord_stato_id=rstato.ord_stato_id
			                  and   stato.ord_stato_code!='A'
			                  and   rord.data_cancellazione is null
			                  and   rord.validita_fine is null
		    	              and   rstato.data_cancellazione is null
		        	          and   rstato.validita_fine is null
        		    	     )
            -- 04.05.2021 Sofia SIAC-8095
            and  not exists (
                             select 1
                             from siac_r_subdoc_ordinativo_ts rord, siac_t_ordinativo_ts ts, siac_t_ordinativo ord
                             where rord.subdoc_id=r.subdoc_id
                             and   ts.ord_ts_id=rord.ord_ts_id
                             and   ord.ord_id=ts.ord_id
                             and   ord.ord_anno>annoBilancio
                             and   rord.data_cancellazione is null
                             and   rord.validita_fine is null
                           )
            -- 04.05.2021 Sofia SIAC-8095
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null
            and   not exists (select 1
                              from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                              where r.subdoc_id = sub.subdoc_id
                              and   doc.doc_id = sub.doc_id
                              and   doc.doc_id = rst.doc_id
                              and   rst.data_cancellazione is null
                              and   rst.validita_fine is null
                              and   st.doc_stato_id = rst.doc_stato_id
                              and   st.doc_stato_code = 'A')
            ;

        	if codResult is not null then
	    	    --strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
                raise exception ' Errore in aggiornamento.';
	    	else codResult:=null;
	        end if;
        end if;

       -- siac_r_predoc_movgest_ts
       if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_predoc_movgest_ts].';
	        update siac_r_predoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_predoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
--	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
                raise exception ' Errore in aggiornamento.';
	    	else codResult:=null;
	        end if;
       end if;

	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Aggiornamento fase_bil_t_gest_apertura_liq_imp per fine elaborazione.';
      	update fase_bil_t_gest_apertura_liq_imp fase
        set fl_elab='I',
            movgest_id=movGestIdRet,
            movgest_ts_id=movGestTsIdRet
        where fase.fase_bil_gest_ape_liq_imp_id=movGestRec.fase_bil_gest_ape_liq_imp_id
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.fl_elab='N'
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null;


       codResult:=null;
	   insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

     end loop;


	 -- 15.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile
     -- insert N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
     -- essendo residui consideriamo solo mov.movgest_anno::integer<annoBilancio
     -- che non hanno ancora attributo
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore N per impegni residui.';
     INSERT INTO siac_r_movgest_ts_attr
	 (
	  movgest_ts_id,
	  attr_id,
	  boolean,
	  validita_inizio,
	  ente_proprietario_id,
	  login_operazione
	 )
	 select ts.movgest_ts_id,
	        flagFrazAttrId,
            'N',
		    dataInizioVal,
		    ts.ente_proprietario_id,
		    loginOperazione
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio)
     and   mov.movgest_anno::integer<annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   not exists (select 1 from siac_r_movgest_ts_attr r1
       		           where r1.movgest_ts_id=ts.movgest_ts_id
                       and   r1.attr_id=flagFrazAttrId
                       and   r1.data_cancellazione is null
                       and   r1.validita_fine is null);

     -- insert S per impegni mov.movgest_anno::integer=annoBilancio
     -- che non hanno ancora attributo
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore S per impegni di competenza senza atto amministrativo antecedente.';
	 INSERT INTO siac_r_movgest_ts_attr
	 (
	  movgest_ts_id,
	  attr_id,
	  boolean,
	  validita_inizio,
	  ente_proprietario_id,
	  login_operazione
	 )
	 select ts.movgest_ts_id,
	        flagFrazAttrId,
            'S',
	        dataInizioVal,
	        ts.ente_proprietario_id,
	        loginOperazione
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where mov.bil_id=bilancioId
	 and   mov.movgest_anno::integer=annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   not exists (select 1 from siac_r_movgest_ts_attr r1
       		           where r1.movgest_ts_id=ts.movgest_ts_id
                       and   r1.attr_id=flagFrazAttrId
                       and   r1.data_cancellazione is null
                       and   r1.validita_fine is null)
     and  not exists (select 1 from siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
					  where ra.movgest_ts_id=ts.movgest_ts_id
					  and   atto.attoamm_id=ra.attoamm_id
				 	  and   atto.attoamm_anno::integer < annoBilancio
		     		  and   ra.data_cancellazione is null
				      and   ra.validita_fine is null);

     -- aggiornamento N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
     -- essendo residui consideriamo solo mov.movgest_anno::integer<annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni residui.';
	 update  siac_r_movgest_ts_attr r set boolean='N'
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where  mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<2017 or mov.movgest_anno::integer>2017)
	 and   mov.movgest_anno::integer<annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   r.movgest_ts_id=ts.movgest_ts_id
     and   r.attr_id=flagFrazAttrId
	 and   r.boolean='S'
     and   r.data_cancellazione is null
     and   r.validita_fine is null;

     -- aggiornamento N per impegni mov.movgest_anno::integer=annoBilancio e atto.attoamm_anno::integer < annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni di competenza e atti amministrativi antecedenti.';
     update siac_r_movgest_ts_attr r set boolean='N'
  	 from siac_t_movgest mov, siac_t_movgest_ts ts,
	      siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
  	 where mov.bil_id=bilancioId
	 and   mov.movgest_anno::INTEGER=2017
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   r.movgest_ts_id=ts.movgest_ts_id
     and   r.attr_id=flagFrazAttrId
	 and   ra.movgest_ts_id=ts.movgest_ts_id
	 and   atto.attoamm_id=ra.attoamm_id
	 and   atto.attoamm_anno::integer < annoBilancio
	 and   r.boolean='S'
     and   r.data_cancellazione is null
     and   r.validita_fine is null
     and   ra.data_cancellazione is null
     and   ra.validita_fine is null;
    -- 15.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile

    strMessaggio:='Aggiornamento stato fase bilancio IN-2.';
    update fase_bil_t_elaborazione
    set fase_bil_elab_esito='IN-2',
        fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||tipoElab||' IN CORSO IN-2.Elabora Imp.'
    where fase_bil_elab_id=faseBilElabId;


    codiceRisultato:=0;
    messaggioRisultato:=strMessaggioFinale||' FINE';
    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,coalesce(strMessaggio,'');
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


alter function siac.fnc_fasi_bil_gest_apertura_liq_elabora_imp 
( integer, integer, varchar,integer, integer, integer, varchar, timestamp,
  out  integer,
  out varchar
) owner to siac;

-- 04.05.2021 Sofia JIRA - SIAC-8095 - fine 


-- 05.05.2021 Sofia Jira - SIAC-8146 - inizio

select fnc_dba_add_column_params 
('siac_bko_regmovfin_prima_nota_documento',
 'login_operazione',
 'varchar(250)'
);

drop FUNCTION if exists 
siac.fnc_siac_annulla_attivazioni_contabili(id_ente integer, anno_bil integer, numero_ndc text, tipo_doc text, codice_soggetto text, codice_inc text);

CREATE OR REPLACE FUNCTION siac.fnc_siac_annulla_attivazioni_contabili
(
  id_ente integer,
  anno_bil integer,
  numero_ndc text,
  tipo_doc text,
  codice_soggetto text,
  codice_inc text
)
RETURNS text AS
$body$
DECLARE

tmp text;

-- 04.05.2021 Sofia Jira SIAC-8146
result integer:=null;
annoBilancioGen integer:=null;

BEGIN

	delete from siac_bko_regmovfin_prima_nota_documento bko
	where bko.ente_proprietario_id=id_ente;

   /* 04.05.2021 Sofia JIRA SIAC-8146
   insert into siac_bko_regmovfin_prima_nota_documento
    (
      anno_bilancio,
      doc_anno,
      doc_numero,
      doc_tipo_code,
      doc_soggetto_code,
      doc_subnumero,
      evento_code,
      collegamento_tipo_code,
      ente_proprietario_id,
      doc_genera,
      doc_genera_gsa
    )
    select  anno_bil,
            doc.doc_anno::integer,
            doc.doc_numero,
            tipo.doc_tipo_code,
            sog.soggetto_code,
            sub.subdoc_numero::integer,
            evento.evento_code,
            coll.collegamento_tipo_code,
            doc.ente_proprietario_id,
            false,
            false
    from siac_t_doc doc, siac_d_doc_tipo tipo,siac_t_subdoc sub,
         siac_r_evento_reg_movfin revento,siac_d_evento evento, siac_d_collegamento_tipo coll,
         siac_r_reg_movfin_stato rs, siac_d_reg_movfin_stato stato,siac_r_doc_sog rsog,siac_t_soggetto sog
    where tipo.ente_proprietario_id=id_ente
    and   doc.doc_tipo_id=tipo.doc_tipo_id
    and   doc.doc_anno::INTEGER=anno_bil
    and   doc.doc_numero=numero_ndc
    and   tipo.doc_tipo_code = tipo_doc
    and  sub.doc_id=doc.doc_id
    and  revento.campo_pk_id=sub.subdoc_id
    and  evento.evento_id=revento.evento_id
    and  coll.collegamento_tipo_id=evento.collegamento_tipo_id
    and  coll.collegamento_tipo_code='SS'
    and  rs.regmovfin_id=revento.regmovfin_id
    and  stato.regmovfin_stato_id=rs.regmovfin_stato_id
    and  stato.regmovfin_stato_code!='A'
    and  rsog.doc_id=doc.doc_id
    and  sog.soggetto_id=rsog.soggetto_id
    and   sog.soggetto_code = codice_soggetto
    and  sub.data_cancellazione is null
    and  sub.validita_fine is null
    and  revento.data_cancellazione is null
    and  revento.validita_fine is null
    and  rs.data_cancellazione is null
    and  rs.validita_fine is null
    and  rsog.data_cancellazione is null
    and  rsog.validita_fine is null;*/

   raise notice '@@@ prima di insert @@@@';
   -- 04.05.2021 Sofia JIRA SIAC-8146
   insert into siac_bko_regmovfin_prima_nota_documento
   (
      anno_bilancio,
      doc_anno,
      doc_numero,
      doc_tipo_code,
      doc_soggetto_code,
      doc_subnumero,
      evento_code,
      collegamento_tipo_code,
      ente_proprietario_id,
      doc_genera,
      doc_genera_gsa,
      login_operazione
   )
   select   --distinct
            per.anno::integer,
            doc.doc_anno::integer,
            doc.doc_numero,
            tipo.doc_tipo_code,
            sog.soggetto_code,
            sub.subdoc_numero::integer,
            evento.evento_code,
            coll.collegamento_tipo_code,
            doc.ente_proprietario_id,
            false,
            false,
            codice_inc
    from siac_t_doc doc, siac_d_doc_tipo tipo,siac_t_subdoc sub,
         siac_r_evento_reg_movfin revento,siac_d_evento evento, siac_d_collegamento_tipo coll,
         siac_t_reg_movfin reg, siac_r_reg_movfin_stato rs, siac_d_reg_movfin_stato stato,siac_r_doc_sog rsog,siac_t_soggetto sog,
         siac_t_bil bil,siac_t_periodo per
    where tipo.ente_proprietario_id=id_ente
    and   tipo.doc_tipo_code = tipo_doc
    and   doc.doc_tipo_id=tipo.doc_tipo_id
    and   doc.doc_anno::INTEGER=anno_bil
    and   doc.doc_numero=numero_ndc
    and   rsog.doc_id=doc.doc_id
    and   sog.soggetto_id=rsog.soggetto_id
    and   sog.soggetto_code = codice_soggetto
    and   sub.doc_id=doc.doc_id
    and   revento.campo_pk_id=sub.subdoc_id
    and   evento.evento_id=revento.evento_id
    and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
    and   coll.collegamento_tipo_code='SS'
    and   rs.regmovfin_id=revento.regmovfin_id
    and   stato.regmovfin_stato_id=rs.regmovfin_stato_id
    and   stato.regmovfin_stato_code!='A'
    and   reg.regmovfin_id=revento.regmovfin_id
    and   bil.bil_id=reg.bil_id
    and   per.periodo_id=bil.periodo_Id
    and   sub.data_cancellazione is null
    and   sub.validita_fine is null
    and   revento.data_cancellazione is null
    and   revento.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   rsog.data_cancellazione is null
    and   rsog.validita_fine is null
    and   reg.data_cancellazione is null
    and   reg.validita_fine is null;


    -- 04.05.2021 Sofia JIRA SIAC-8146
    select bko.anno_bilancio into annoBilancioGen
    from siac_bko_regmovfin_prima_nota_documento bko
    where bko.ente_proprietario_id=id_ente
    and   bko.login_operazione=codice_inc
    limit 1;
    raise notice '@@@@annoBilancioGen=%@@@@@', annoBilancioGen::varchar;

/*	04.05.2021 Sofia JIRA SIAC-8146 - tutto fatto nella function richiamata successivamente


 -- inserire stato prima nota annullato, se esiste non annullata
 insert into siac_r_prima_nota_stato
  (
 	pnota_id,
    pnota_stato_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  select distinct pnota.pnota_id,
                  statoA.pnota_stato_id,
                  now(),
                  codice_inc,
                  tipo.ente_proprietario_id
  from siac_d_doc_tipo tipo, siac_t_doc doc , siac_r_doc_sog rdoc, siac_t_soggetto sog,
       siac_bko_regmovfin_prima_nota_documento bko,
       siac_t_subdoc sub,
       siac_v_bko_anno_bilancio anno,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
       siac_t_mov_ep ep, siac_t_prima_nota pnota,
       siac_d_prima_nota_stato pnstato,siac_r_prima_nota_stato r,
       siac_d_prima_nota_stato statoA
  where  tipo.ente_proprietario_id=id_ente
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   tipo.doc_tipo_code=bko.doc_tipo_code
   and   doc.ente_proprietario_id=tipo.ente_proprietario_id
   and   doc.doc_anno::integer=bko.doc_anno
   and   doc.doc_numero=bko.doc_numero
   and   rdoc.doc_id=doc.doc_id
   and   sog.soggetto_id=rdoc.soggetto_id
   and   sog.soggetto_code=bko.doc_soggetto_code
   and   sub.doc_id=doc.doc_id
   and   sub.subdoc_numero=bko.doc_subnumero
   and   anno.ente_proprietario_id=tipo.ente_proprietario_id
   and   anno.anno_bilancio=anno_bil
   and   revento.campo_pk_id=sub.subdoc_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code=bko.collegamento_tipo_code
   and   evento.evento_code=bko.evento_code
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   ep.regmovfin_id=reg.regmovfin_id
   and   pnota.pnota_id=ep.regep_id
   and   r.pnota_id=pnota.pnota_id
   and   pnota.bil_id=anno.bil_id
   and   pnstato.pnota_stato_id=r.pnota_stato_id
   and   pnstato.pnota_stato_code!='A'
   and   statoA.ente_proprietario_id=tipo.ente_proprietario_id
   and   statoA.pnota_stato_code='A'
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null
   and   ep.data_cancellazione is null
   and   ep.validita_fine is null
   and   pnota.data_cancellazione is null
   and   pnota.validita_fine is null
   and   r.data_cancellazione is null
   and   r.validita_fine is null
   and   rdoc.data_cancellazione is null
   and   rdoc.validita_fine is null
   and   sub.data_cancellazione is null
   and   sub.validita_fine is null
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null;





-- annullare prima nota, se presente non annullata
	 update siac_r_prima_nota_stato r
  set    data_cancellazione=clock_timestamp(),
         validita_fine=clock_timestamp(),
         login_operazione=r.login_operazione||'-'||codice_inc
 from siac_d_doc_tipo tipo, siac_t_doc doc , siac_r_doc_sog rdoc, siac_t_soggetto sog,
       siac_bko_regmovfin_prima_nota_documento bko,
       siac_t_subdoc sub,
       siac_v_bko_anno_bilancio anno,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
       siac_t_mov_ep ep, siac_t_prima_nota pnota,
       siac_d_prima_nota_stato pnstato
  where  tipo.ente_proprietario_id=id_ente
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   tipo.doc_tipo_code=bko.doc_tipo_code
   and   doc.ente_proprietario_id=tipo.ente_proprietario_id
   and   doc.doc_anno::integer=bko.doc_anno
   and   doc.doc_numero=bko.doc_numero
   and   rdoc.doc_id=doc.doc_id
   and   sog.soggetto_id=rdoc.soggetto_id
   and   sog.soggetto_code=bko.doc_soggetto_code
   and   sub.doc_id=doc.doc_id
   and   sub.subdoc_numero=bko.doc_subnumero
   and   anno.ente_proprietario_id=tipo.ente_proprietario_id
   and   anno.anno_bilancio=anno_bil
   and   revento.campo_pk_id=sub.subdoc_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code=bko.collegamento_tipo_code
   and   evento.evento_code=bko.evento_code
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   ep.regmovfin_id=reg.regmovfin_id
   and   pnota.pnota_id=ep.regep_id
   and   r.pnota_id=pnota.pnota_id
   and   pnota.bil_id=anno.bil_id
   and   pnstato.pnota_stato_id=r.pnota_stato_id
   and   pnstato.pnota_stato_code!='A'
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null
   and   ep.data_cancellazione is null
   and   ep.validita_fine is null
   and   pnota.data_cancellazione is null
   and   pnota.validita_fine is null
   and   r.data_cancellazione is null
   and   r.validita_fine is null
   and   rdoc.data_cancellazione is null
   and   rdoc.validita_fine is null
   and   sub.data_cancellazione is null
   and   sub.validita_fine is null
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null;


-- inserire stato registro annullato, se esiste non annullato

 insert into siac_r_reg_movfin_stato
   (
  	 regmovfin_id,
     regmovfin_stato_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
   )
   select REG.regmovfin_id,
          statoA.regmovfin_stato_id,
          now(),
          codice_inc,
	      statoA.ente_proprietario_id
   from siac_d_reg_movfin_stato statoA,
   (
   select distinct reg.regmovfin_id
   from siac_d_doc_tipo tipo, siac_t_doc doc , siac_r_doc_sog rdoc, siac_t_soggetto sog,
       siac_bko_regmovfin_prima_nota_documento bko,
       siac_t_subdoc sub,
       siac_v_bko_anno_bilancio anno,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato
   where  tipo.ente_proprietario_id=id_ente
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   tipo.doc_tipo_code=bko.doc_tipo_code
   and   doc.ente_proprietario_id=tipo.ente_proprietario_id
   and   doc.doc_anno::integer=bko.doc_anno
   and   doc.doc_numero=bko.doc_numero
   and   rdoc.doc_id=doc.doc_id
   and   sog.soggetto_id=rdoc.soggetto_id
   and   sog.soggetto_code=bko.doc_soggetto_code
   and   sub.doc_id=doc.doc_id
   and   sub.subdoc_numero=bko.doc_subnumero
   and   anno.ente_proprietario_id=tipo.ente_proprietario_id
   and   anno.anno_bilancio=anno_bil
   and   revento.campo_pk_id=sub.subdoc_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code=bko.collegamento_tipo_code
   and   evento.evento_code=bko.evento_code
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null
   and   rdoc.data_cancellazione is null
   and   rdoc.validita_fine is null
   and   sub.data_cancellazione is null
   and   sub.validita_fine is null
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null
   and   reg.bil_id = anno.bil_id
   ) REG
   where statoA.ente_proprietario_id=id_ente
   and   statoA.regmovfin_stato_code='A';




update siac_r_reg_movfin_stato rrstato
   set    data_cancellazione=clock_timestamp(),
          validita_fine=clock_timestamp(),
          login_operazione=rrstato.login_operazione||'-'||codice_inc
   from siac_d_doc_tipo tipo, siac_t_doc doc , siac_r_doc_sog rdoc, siac_t_soggetto sog,
       siac_bko_regmovfin_prima_nota_documento bko,
       siac_t_subdoc sub,
       siac_v_bko_anno_bilancio anno,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg, siac_d_reg_movfin_stato rstato
  where  tipo.ente_proprietario_id=id_ente
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   tipo.doc_tipo_code=bko.doc_tipo_code
   and   doc.ente_proprietario_id=tipo.ente_proprietario_id
   and   doc.doc_anno::integer=bko.doc_anno
   and   doc.doc_numero=bko.doc_numero
   and   rdoc.doc_id=doc.doc_id
   and   sog.soggetto_id=rdoc.soggetto_id
   and   sog.soggetto_code=bko.doc_soggetto_code
   and   sub.doc_id=doc.doc_id
   and   sub.subdoc_numero=bko.doc_subnumero
   and   anno.ente_proprietario_id=tipo.ente_proprietario_id
   and   anno.anno_bilancio=anno_bil
   and   revento.campo_pk_id=sub.subdoc_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code=bko.collegamento_tipo_code
   and   evento.evento_code=bko.evento_code
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null
   and   rdoc.data_cancellazione is null
   and   rdoc.validita_fine is null
   and   sub.data_cancellazione is null
   and   sub.validita_fine is null
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null
   and   reg.bil_id = anno.bil_id;	*/


  --   04.05.2021 Sofia JIRA SIAC-8146
  if annoBilancioGen is not null then

    select
    fnc_siac_bko_regmovfin_prima_nota_documento
    (
--     anno_bil,  04.05.2021 Sofia JIRA SIAC-8146
     annoBilancioGen,
     id_ente,
     codice_inc,
     true,
     false
    ) into tmp;
  end if;


  select
    fnc_siac_bko_aggiorna_doc_contabilizza_genpcc
    (
      doc.ente_proprietario_id,
      anno_bil,
      tipo.doc_tipo_code,
      doc.doc_anno::integer,
      doc.doc_numero,
      sog.soggetto_code,
      false,
      codice_inc
    ) into tmp
    from siac_t_doc doc, siac_d_doc_tipo tipo,siac_r_doc_sog rsog,siac_t_soggetto sog
    where tipo.ente_proprietario_id=id_ente
    and   doc.doc_tipo_id=tipo.doc_tipo_id
    and   doc.doc_anno::INTEGER=anno_bil
    and   doc.doc_numero=numero_ndc
    and   tipo.doc_tipo_code = tipo_doc
    and  rsog.doc_id=doc.doc_id
    and  sog.soggetto_id=rsog.soggetto_id
    and   sog.soggetto_code = codice_soggetto
    and  rsog.data_cancellazione is null
    and  rsog.validita_fine is null;


	delete from siac_bko_regmovfin_prima_nota_documento bko
    where bko.ente_proprietario_id=id_ente
    and   bko.login_operazione=codice_inc; -- 05.05.2021 Sofia Jira SIAC-8146


    return null;

exception
	when others  THEN
	    return SQLERRM;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter function siac.fnc_siac_annulla_attivazioni_contabili(integer, integer, text, text,  text,  text) owner to siac;
-- 05.05.2021 Sofia Jira - SIAC-8146 - fine

-- 06.05.2021 Sofia Jira - SIAC-7931 - inizio
drop function if exists
fnc_fasi_bil_cap_aggiorna_res_cassa 
(
   p_elem_tipo_code       varchar
  ,p_elem_tipo_code_prev  varchar
  ,p_annoBilancio         integer
  ,p_ente_proprietario_id integer
  ,p_login_operazione     varchar
  ,p_calcolo_res 		  boolean
  ,p_calcolo_cassa        boolean
  ,p_res_calcolato        boolean
  ,p_aggiorna_stanz       boolean
  ,out faseBilElabId      integer
  ,out codicerisultato    integer
  ,out messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION fnc_fasi_bil_cap_aggiorna_res_cassa 
(
   p_elem_tipo_code       varchar  --  tipo capitolo da aggiornare [CAP-EP,CAP-EG,CAP-UG,CAP-UP]|[C,R,E] - il tipo aggiornamento obb. solo se p_aggiorna_stanz=true
   -- C : aggiorna cassa       ,  imposta p_calcolo_cassa=true p_calcolo_res=false
   -- R : aggiorna res         ,  imposta p_calcolo_res=true   p_calcolo_cassa=p_res_calcolo=false
   -- E : aggiorna, res e cassa,  imposta p_calcolo_cassa=p_res_calcolo=true p_calcolo_res=false   
  ,p_elem_tipo_code_prev  varchar  --  tipo capitolo su cui leggere residui (CAP-UG, CAP-EG)
  ,p_annoBilancio         integer 
  ,p_ente_proprietario_id integer
  ,p_login_operazione     varchar
  ,p_calcolo_res 		  boolean  --> se true lancia fnc_calcolo_res ( esclusivo con fnc_calcolo_cassa )
  ,p_calcolo_cassa        boolean  --> se true lancia fnc_calcolo_cassa ( esclusivo con fnc_calcolo_res )
  ,p_res_calcolato        boolean  --> utilizzato in caso di p_calcolo_cassa=true per calcolo cassa, se true residui ricalcolati, se false letti da STR 
  ,p_aggiorna_stanz       boolean  --> se true aggiorna gli stianziamenti sui capitoli in base al tipo di aggiornamento 
  ,out faseBilElabId      integer
  ,out codicerisultato    integer
  ,out messaggiorisultato varchar
)
RETURNS record  AS
$body$
declare
    v_dataElaborazione  	timestamp := now();
    ris_res					record;
    ris_res_cassa			record;
    strMessaggio            varchar;
    v_faseBilElabId         integer;
    recInsResCassa          record;
    v_annoBilancio          varchar;

    -- 06.05.2021 Sofia Jira SIAC-7193
    tipoAggiornamento      varchar(15):=null;

begin
    v_annoBilancio = p_annoBilancio::varchar;
    codicerisultato:=0;
    faseBilElabId:=null;

    strMessaggio:='Inserimento fase elaborazione [fnc_fasi_bil_aggiorna_res_cassa].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
    fase_bil_elab_tipo_id,
    ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE CALCOLO RESIDUO E CASSA IN CORSO.',
            tipo.fase_bil_elab_tipo_id,p_ente_proprietario_id, now(), p_login_operazione
    from fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=p_ente_proprietario_id
    and   tipo.fase_bil_elab_tipo_code='APE_CAP_CALC_RES'
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null)
    returning fase_bil_elab_id into v_faseBilElabId;

	----------------------------------------------------
   /*  06.05.2021 Sofia Jira SIAC-7931
   if p_calcolo_res = true AND (p_res_calcolato is true or p_calcolo_cassa is true) then
      messaggiorisultato := 'OK. se p_calcolo_res is true p_res_calcolato e p_calcolo_cassa non possono essere  true';
      codicerisultato:=-1;
    raise notice 'KO p_calcolo_res e p_res_calcolato non possono essere entrambi true';
	return;
    end if;*/

	
    -- 06.05.2021 Sofia Jira SIAC-7931
    if p_calcolo_res=true and p_calcolo_cassa=true then
      messaggiorisultato := 'KO. Residuo e Cassa devono essere alternativi (p_calcolo_res=true e p_calcolo_cassa=true non consentito ).';
      codicerisultato:=-1;
	  raise notice '%',messaggiorisultato;
	  return;
    end if;

	-- 06.05.2021 Sofia Jira SIAC-7931
	if p_aggiorna_stanz=false and p_calcolo_cassa=false and p_calcolo_res=false then
	  messaggiorisultato := 'KO. Calcolo stanziamenti senza aggiornamento indicare almeno uno dei due calcoli da effettuare (p_calcolo_cassa=true o p_calcolo_res=true ).';
      codicerisultato:=-1;
	  raise notice '%',messaggiorisultato;
	  return;
	end if;
	
	
    /*  06.05.2021 Sofia Jira SIAC-7931
    if (p_aggiorna_stanz is true AND p_calcolo_cassa is false ) then

	    messaggiorisultato := 'OK. aggiornamento dei dati non possibile se non a seguito di calcolo cassa concomitante per cui valorizzare sia p_aggiorna_stanz che p_calcolo_cassa a true.';
	      codicerisultato:=-1;
	    raise notice 'OK. aggiornamento dei dati non possibile se non a seguito di calcolo cassa concomitante per cui valorizzare sia p_aggiorna_stanz che p_calcolo_cassa a true.';
		return;

    end if;*/

    -- 06.05.2021 Sofia Jira SIAC-7931
    if position('|' in p_elem_tipo_code)>0 then
		tipoAggiornamento:=substring(p_elem_tipo_code,position('|' in p_elem_tipo_code)+1);
	    p_elem_tipo_code:=substring(p_elem_tipo_code,1, position('|' in p_elem_tipo_code)-1);
    end if;
    raise notice 'p_elem_tipo_code=%',p_elem_tipo_code;
    raise notice 'tipoAggiornamento=%',tipoAggiornamento;
    raise notice 'p_aggiorna_stanz=%',p_aggiorna_stanz::varchar;

    if p_aggiorna_stanz is true then
    	if coalesce(tipoAggiornamento,'')='' then
	        messaggiorisultato := 'KO. Per aggiornamento stanziamenti specificare quali aggiornare [C|R|E] in coda al primo parametro.';
    		codicerisultato:=-1;
		    raise notice '%',messaggiorisultato;
	        return;
        end if;

        if tipoAggiornamento='E' then
          p_calcolo_res:=false;
          p_calcolo_cassa:=true;
          p_res_calcolato:=true;
        end if;

        if tipoAggiornamento='C'then
          p_calcolo_res:=false;
          p_calcolo_cassa:=true;
        end if;

        if tipoAggiornamento='R' then
          p_calcolo_res:=true;
          p_calcolo_cassa:=false;
          p_res_calcolato:=false;
        end if;
    end if;

    raise notice 'p_calcolo_res=%',p_calcolo_res::varchar;
    raise notice 'p_calcolo_cassa=%',p_calcolo_cassa::varchar;
    raise notice 'p_res_calcolato=%',p_res_calcolato::varchar;

    if p_calcolo_res = true then
    	select * into ris_res from fnc_fasi_bil_cap_calcolo_res ( p_elem_tipo_code ,p_elem_tipo_code_prev,p_annoBilancio,p_ente_proprietario_id,p_login_operazione,v_faseBilElabId);
    	if ris_res.codiceRisultato = -1 then
    	    strMessaggio := ris_res.strMessaggio;
    		raise notice '%   ERRORE : %',ris_res.strMessaggio,substring(upper(SQLERRM) from 1 for 2500);
    	end if;
   	end if;

    if p_calcolo_cassa = true then
    	select * into ris_res_cassa from fnc_fasi_bil_cap_calcolo_cassa (p_annoBilancio ,p_elem_tipo_code ,p_elem_tipo_code_prev , p_res_calcolato ,p_ente_proprietario_id ,p_login_operazione , v_faseBilElabId);
    	if ris_res_cassa.codiceRisultato = -1 then
    	    strMessaggio := ris_res_cassa.messaggiorisultato;
    		raise notice '%   ERRORE : %',ris_res_cassa.messaggiorisultato,substring(upper(SQLERRM) from 1 for 2500);
    	end if;
    end if;

   	if p_aggiorna_stanz = true then

    		strMessaggio :=strMessaggio||'Inizio aggiorno le tabelle sul siac.';
    		--if p_calcolo_cassa = false AND p_calcolo_res = false then
            	--select max(faseBilElabId) into v_faseBilElabId from fase_bil_t_cap_calcolo_res where  ente_proprietario_id = p_ente_proprietario_id;
            --end if;



            for recInsResCassa IN( select * from fase_bil_t_cap_calcolo_res where ente_proprietario_id = p_ente_proprietario_id and fase_bil_elab_id = v_faseBilElabId) LOOP



			strMessaggio    := 'CAPITOLO elem_code-->'||recInsResCassa.elem_code||' elem_code2-->'||recInsResCassa.elem_code2||' elem_code3-->'||recInsResCassa.elem_code3||'v_faseBilElabId-->'||v_faseBilElabId::varchar||'.';

				/*
            	update siac_t_bil_elem_det set elem_det_importo = recInsResCassa.stanziamento
                where elem_det_id in (
                  select
                    siac_t_bil_elem_det.elem_det_id
                  from
                    siac_t_bil_elem ,
                    siac_d_bil_elem_tipo,
                    siac_t_bil,
                    siac_r_bil_elem_stato,
                    siac_d_bil_elem_stato,
                    siac_t_bil_elem_det,
                    siac_d_bil_elem_det_tipo,
                    siac_t_periodo
                  where
                        siac_t_bil.bil_id = siac_t_bil_elem.bil_id
                    and	siac_t_bil_elem.elem_tipo_id =  siac_d_bil_elem_tipo.elem_tipo_id
                    and siac_t_bil_elem.elem_id = siac_r_bil_elem_stato.elem_id
                    and siac_r_bil_elem_stato.elem_stato_id = siac_d_bil_elem_stato.elem_stato_id
                    and siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id
                    and siac_t_bil_elem_det.elem_det_tipo_id=siac_d_bil_elem_det_tipo.elem_det_tipo_id
					and siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
                    and siac_d_bil_elem_tipo.elem_tipo_code = p_elem_tipo_code--'CAP-UP'
                    and siac_t_bil.bil_id = recInsResCassa.bil_id
                    and siac_t_bil_elem.ente_proprietario_id = p_ente_proprietario_id
                    and siac_t_bil_elem.data_cancellazione is null
                    and siac_r_bil_elem_stato.data_cancellazione is null
                    and siac_d_bil_elem_stato.elem_stato_code in ('PR','VA')
                    and siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id
                    and siac_t_periodo.anno = v_annoBilancio
                    and siac_t_bil_elem.elem_code  = recInsResCassa.elem_code
                    and siac_t_bil_elem.elem_code2 = recInsResCassa.elem_code2
                    and siac_t_bil_elem.elem_code3 = recInsResCassa.elem_code3

                );
                */


	            -- 06.05.2021 Sofia Jira SIAC-7931
				if tipoAggiornamento in ('C','E') then
            /* -- 06.05.2021 Sofia Jira SIAC-7931
 				 update siac_t_bil_elem_det set elem_det_importo = recInsResCassa.stanziamento_cassa
                  where elem_det_id in (
                    select
                      siac_t_bil_elem_det.elem_det_id
                    from
                      siac_t_bil_elem ,
                      siac_d_bil_elem_tipo,
                      siac_t_bil,
                      siac_r_bil_elem_stato,
                      siac_d_bil_elem_stato,
                      siac_t_bil_elem_det,
                      siac_d_bil_elem_det_tipo,
                      siac_t_periodo
                    where
                          siac_t_bil.bil_id = siac_t_bil_elem.bil_id
                      and	siac_t_bil_elem.elem_tipo_id =  siac_d_bil_elem_tipo.elem_tipo_id
                      and siac_t_bil_elem.elem_id = siac_r_bil_elem_stato.elem_id
                      and siac_r_bil_elem_stato.elem_stato_id = siac_d_bil_elem_stato.elem_stato_id
                      and siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id
                      and siac_t_bil_elem_det.elem_det_tipo_id=siac_d_bil_elem_det_tipo.elem_det_tipo_id
                      and siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA'
                      and siac_d_bil_elem_tipo.elem_tipo_code = p_elem_tipo_code--'CAP-UP'
                      and siac_t_bil.bil_id = recInsResCassa.bil_id
                      and siac_t_bil_elem.ente_proprietario_id = p_ente_proprietario_id
                      and siac_t_bil_elem.data_cancellazione is null
                      and siac_t_bil_elem.validita_fine is null
                      and siac_r_bil_elem_stato.data_cancellazione is null
                      and siac_r_bil_elem_stato.validita_fine is null
  --                    and siac_d_bil_elem_stato.elem_stato_code in ('PR','VA')
                      and siac_d_bil_elem_stato.elem_stato_code='VA'
                      and siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id
                      and siac_t_periodo.anno = v_annoBilancio
                      and siac_t_bil_elem.elem_code  = recInsResCassa.elem_code
                      and siac_t_bil_elem.elem_code2 = recInsResCassa.elem_code2
                      and siac_t_bil_elem.elem_code3 = recInsResCassa.elem_code3
                  );
            */
                  update siac_t_bil_elem_det detUPD
                  set elem_det_importo = recInsResCassa.stanziamento_cassa,
                      data_modifica=clock_timestamp(),
                      login_operazione=detUPD.login_operazione||'-'||p_login_operazione
		          from
				  (
                    select det.elem_det_id
                    from
                      siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
                      siac_r_bil_elem_stato rs,siac_d_bil_elem_stato stato,
                      siac_t_bil_elem_det det,siac_d_bil_elem_det_tipo tipo_det,
                      siac_t_periodo  per
                    where tipo.ente_proprietario_id=p_ente_proprietario_id
	                and   tipo.elem_tipo_code = p_elem_tipo_code
                    and	  e.elem_tipo_id =  tipo.elem_tipo_id
                    and   e.bil_id =        recInsResCassa.bil_id
                    and   e.elem_code  = recInsResCassa.elem_code
                    and   e.elem_code2 = recInsResCassa.elem_code2
                    and   e.elem_code3 = recInsResCassa.elem_code3
                    and   rs.elem_id = e.elem_id
                    and   stato.elem_stato_id = rs.elem_stato_id
                    and   stato.elem_stato_code='VA'
                    and   det.elem_id = e.elem_id
                    and   tipo_det.elem_det_tipo_id=det.elem_det_tipo_id
                    and   tipo_Det.elem_det_tipo_code = 'SCA'
                    and   det.periodo_id = per.periodo_id
                    and   per.anno = v_annoBilancio
                    and   e.data_cancellazione is null
                    and   e.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                  ) query_UPD
                  where detUPD.ente_proprietario_id=p_ente_proprietario_id
                  and   detUPD.elem_Det_id=query_UPD.elem_det_id
                  and   detUPD.data_cancellazione is null
                  and   detUPD.validita_fine is null;


                  strMessaggio    := strMessaggio||'update SCA.';
              end if;  -- 06.05.2021 Sofia Jira SIAC-7931

			  -- 06.05.2021 Sofia Jira SIAC-7931
			  if tipoAggiornamento in ('R','E') then
               /* 06.05.2021 Sofia Jira SIAC-7931
                  update siac_t_bil_elem_det set elem_det_importo = recInsResCassa.tot_impacc
                      where elem_det_id in (
                        select
                          siac_t_bil_elem_det.elem_det_id
                        from
                          siac_t_bil_elem ,
                          siac_d_bil_elem_tipo,
                          siac_t_bil,
                          siac_r_bil_elem_stato,
                          siac_d_bil_elem_stato,
                          siac_t_bil_elem_det,
                          siac_d_bil_elem_det_tipo,
                          siac_t_periodo
                        where
                              siac_t_bil.bil_id = siac_t_bil_elem.bil_id
                          and	siac_t_bil_elem.elem_tipo_id =  siac_d_bil_elem_tipo.elem_tipo_id
                          and siac_t_bil_elem.elem_id = siac_r_bil_elem_stato.elem_id
                          and siac_r_bil_elem_stato.elem_stato_id = siac_d_bil_elem_stato.elem_stato_id
                          and siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id
                          and siac_t_bil_elem_det.elem_det_tipo_id=siac_d_bil_elem_det_tipo.elem_det_tipo_id
                          and siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
                          and siac_d_bil_elem_tipo.elem_tipo_code = p_elem_tipo_code--'CAP-UP'
                          and siac_t_bil.bil_id = recInsResCassa.bil_id
                          and siac_t_bil_elem.ente_proprietario_id = p_ente_proprietario_id
                          and siac_t_bil_elem.data_cancellazione is null
                          and siac_t_bil_elem.validita_fine is null
                          and siac_r_bil_elem_stato.data_cancellazione is null
                          and siac_r_bil_elem_stato.validita_fine is null
    --                      and siac_d_bil_elem_stato.elem_stato_code in ('PR','VA')
                          and siac_d_bil_elem_stato.elem_stato_code='VA'
                          and siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id
                          and siac_t_periodo.anno = v_annoBilancio
                          and siac_t_bil_elem.elem_code  = recInsResCassa.elem_code
                          and siac_t_bil_elem.elem_code2 = recInsResCassa.elem_code2
                          and siac_t_bil_elem.elem_code3 = recInsResCassa.elem_code3
                      );
*/
		          -- 06.05.2021 Sofia Jira SIAC-7931
	              update siac_t_bil_elem_det detUPD
                  set elem_det_importo = recInsResCassa.tot_impacc,
                      data_modifica=clock_timestamp(),
                      login_operazione=detUPD.login_operazione||'-'||p_login_operazione
		          from
				  (
                    select det.elem_det_id
                    from
                      siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
                      siac_r_bil_elem_stato rs,siac_d_bil_elem_stato stato,
                      siac_t_bil_elem_det det,siac_d_bil_elem_det_tipo tipo_det,
                      siac_t_periodo  per
                    where tipo.ente_proprietario_id=p_ente_proprietario_id
	                and   tipo.elem_tipo_code = p_elem_tipo_code
                    and	  e.elem_tipo_id =  tipo.elem_tipo_id
                    and   e.bil_id =        recInsResCassa.bil_id
                    and   e.elem_code  = recInsResCassa.elem_code
                    and   e.elem_code2 = recInsResCassa.elem_code2
                    and   e.elem_code3 = recInsResCassa.elem_code3
                    and   rs.elem_id = e.elem_id
                    and   stato.elem_stato_id = rs.elem_stato_id
                    and   stato.elem_stato_code='VA'
                    and   det.elem_id = e.elem_id
                    and   tipo_det.elem_det_tipo_id=det.elem_det_tipo_id
                    and   tipo_Det.elem_det_tipo_code = 'STR'
                    and   det.periodo_id = per.periodo_id
                    and   per.anno = v_annoBilancio
                    and   e.data_cancellazione is null
                    and   e.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                  ) query_UPD
                  where detUPD.ente_proprietario_id=p_ente_proprietario_id
                  and   detUPD.elem_Det_id=query_UPD.elem_det_id
                  and   detUPD.data_cancellazione is null
                  and   detUPD.validita_fine is null;
                  -- 06.05.2021 Sofia Jira SIAC-7931
                  strMessaggio    := strMessaggio||'update STR.';
				end if; -- 06.05.2021 Sofia Jira SIAC-7931

            end loop;

    end if;

     -----------------------------------------------------
     strMessaggio:='Aggiornamento fase elaborazione [fnc_fasi_bil_aggiorna_res_cassa].';
     update fase_bil_t_elaborazione set
          fase_bil_elab_esito='OK',
          fase_bil_elab_esito_msg='ELABORAZIONE CALCOLO RESIDUO E CASSA COMPLETATA.',
          validita_fine=now()
     where fase_bil_elab_id=v_faseBilElabId;

     faseBilElabId:=v_faseBilElabId;
     messaggiorisultato := 'OK. '|| strMessaggio||'fine elaborazione.';
exception
    when RAISE_EXCEPTION THEN
    	codicerisultato:=-1;
    	raise notice '%   ERRORE : %',strMessaggio,substring(upper(SQLERRM) from 1 for 2500);
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        return;
	when others  THEN
	    codicerisultato:=-1;
		raise notice ' % ERRORE DB: % %',strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 2500);
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter function siac.fnc_fasi_bil_cap_aggiorna_res_cassa
( varchar, varchar,integer, integer ,varchar, boolean, boolean, boolean ,boolean, out integer,out integer,out varchar) owner to siac;

-- 06.05.2021 Sofia Jira - SIAC-7931 - fine

-- 10.05.2021 Sofia Jira - SIAC-8167 - inizio
drop function if exists 
siac.fnc_pagopa_t_elaborazione_riconc_esegui 
(
  filepagopaelabid integer,
  annobilancioelab integer,
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_pagopa_t_elaborazione_riconc_esegui (
  filepagopaelabid integer,
  annobilancioelab integer,
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(2500):=''; -- 09.10.2019 Sofia
	strMessaggioBck VARCHAR(2500):=''; -- 09.10.2019 Sofia
    strMessaggioLog VARCHAR(2500):='';

	strMessaggioFinale VARCHAR(1500):='';
    strErrore  VARCHAR(1500):='';
    pagoPaCodeErr varchar(50):='';
	codResult integer:=null;
    codResult1 integer:=null;
    docid integer:=null;
    subDocId integer:=null;
    nProgressivo integer=null;




    -- stati ammessi per procedere con elaborazione
    -- file XML caricato correttamente pronto x elaborazione
	ACQUISITO_ST              CONSTANT  varchar :='ACQUISITO';
    -- file XML caricato correttamente, elaborazione in corso, flussi in fase di elaborazione
    ELABORATO_IN_CORSO_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO'; -- senza errori  e scarti
    ELABORATO_IN_CORSO_ER_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_ER';  -- con errori
    ELABORATO_IN_CORSO_SC_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_SC'; -- con scarti
    -- stati ammessi per procedere con elaborazione


    -- stati per chiusura con errore
    ELABORATO_SCARTATO_ST     CONSTANT  varchar :='ELABORATO_SCARTATO';
    ELABORATO_ERRATO_ST       CONSTANT  varchar :='ELABORATO_ERRATO';
    ANNULLATO_ST              CONSTANT  varchar :='ANNULLATO';
	RIFIUTATO_ST              CONSTANT  varchar :='RIFIUTATO';
    -- stati per chiusura con errore

    -- stati per chiusura con successo con o senza scarti
    -- file XML caricato, ELABORAZIONE TERMINATA E CONCLUSA
    ELABORATO_OK_ST           CONSTANT  varchar :='ELABORATO_OK'; -- documenti  emessi
    ELABORATO_KO_ST           CONSTANT  varchar :='ELABORATO_KO'; -- documenti emessi - presenza di errori-scarti
    -- stati per chiusura con successo con o senza scarti

	ESERCIZIO_PROVVISORIO_ST CONSTANT  varchar :='E'; -- esercizio provvisorio
    ESERCIZIO_GESTIONE_ST    CONSTANT  varchar :='G'; -- esercizio gestione
    -- 18.01.2021 Sofia Jira SIAC-7962
    ESERCIZIO_CONSUNTIVO_ST    CONSTANT  varchar :='O'; -- esercizio consuntivo

	-- errori di elaborazione su dettagli
	PAGOPA_ERR_1	CONSTANT  varchar :='1'; --ANNULLATO
	PAGOPA_ERR_2	CONSTANT  varchar :='2'; --SCARTATO
	PAGOPA_ERR_3	CONSTANT  varchar :='3'; --ERRORE GENERICO
	PAGOPA_ERR_4	CONSTANT  varchar :='4'; --FILE NON ESISTENTE O STATO NON RICHIESTO
	PAGOPA_ERR_5	CONSTANT  varchar :='5'; --FILE CARICATO DIVERSE VOLTE PER filepagopaFileXMLId
	PAGOPA_ERR_6	CONSTANT  varchar :='6'; --DATI DI RICONCILIAZIONE NON PRESENTI
	PAGOPA_ERR_7	CONSTANT  varchar :='7'; --DATI DI RICONCILIAZIONE DA ELABORARE NON PRESENTI
	PAGOPA_ERR_8	CONSTANT  varchar :='8'; --DATI DI RICONCILIAZIONE NON PRESENTI PER filepagopaFileXMLId
	PAGOPA_ERR_9	CONSTANT  varchar :='9'; --DATI DI RICONCILIAZIONE PRESENTI PER DIVERSO FILE E STESSO filepagopaFileXMLId
	PAGOPA_ERR_10	CONSTANT  varchar :='10';--DATI DI RICONCILIAZIONE ASSOCIATI A DIVERSI VALORI DI ANNO ESERCIZIO
	PAGOPA_ERR_11	CONSTANT  varchar :='11';--DATI DI RICONCILIAZIONE ASSOCIATI A ANNO ESERCIZIO SUCCESSIVO A ANNO BILANCIO
	PAGOPA_ERR_12	CONSTANT  varchar :='12';--DATI DI RICONCILIAZIONE SENZA ANNO ESERCIZIO INDICATO
	PAGOPA_ERR_13	CONSTANT  varchar :='13';--DATI DI RICONCILIAZIONE SENZA ESTREMI PROVVISORIO DI CASSA
	PAGOPA_ERR_14	CONSTANT  varchar :='14';--DATI DI RICONCILIAZIONE SENZA ESTREMI ACCERTAMENTO
	PAGOPA_ERR_15	CONSTANT  varchar :='15';--DATI DI RICONCILIAZIONE SENZA ESTREMI VOCE/SOTTOVOCE
	PAGOPA_ERR_16	CONSTANT  varchar :='16';--DATI DI RICONCILIAZIONE SENZA IMPORTO
	PAGOPA_ERR_17	CONSTANT  varchar :='17';--ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FILE
	PAGOPA_ERR_18	CONSTANT  varchar :='18';--ANNO BILANCIO DI ELABORAZIONE NON ESISTENTE O FASE NON AMMESSA
	PAGOPA_ERR_19	CONSTANT  varchar :='19';--ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FLUSSO DI RICONCILIAZIONE
	PAGOPA_ERR_20	CONSTANT  varchar :='20';--DATI DI ELABORAZIONE NON ESISTENTI O IN STATO NON AMMESSO
	PAGOPA_ERR_21	CONSTANT  varchar :='21';--ERRORE IN INSERIMENTO DATI DI DETTAGLIO ELABORAZIONE FLUSSO DI RICONCILIAZIONE
	PAGOPA_ERR_22	CONSTANT  varchar :='22';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA NON ESISTENTE
	PAGOPA_ERR_23	CONSTANT  varchar :='23';--DATI DI RICONCILIAZIONE ASSOCIATI A ACCERTAMENTO NON ESISTENTE
  	PAGOPA_ERR_24	CONSTANT  varchar :='24';--TIPO DOCUMENTO IPA NON ESISTENTE
    PAGOPA_ERR_25   CONSTANT  varchar :='25';--BOLLO ESENTE NON ESISTENTE
    PAGOPA_ERR_26   CONSTANT  varchar :='26';--STATO VALIDO DOCUMENTO NON ESISTENTE
    PAGOPA_ERR_27   CONSTANT  varchar :='27';--IDENTIFICATIVO CDC/CDR NON ESISTENTE
    PAGOPA_ERR_28   CONSTANT  varchar :='28';--IDENTIFICATIVO TIPO QUOTA DOCUMENTO NON ESISTENTE
    PAGOPA_ERR_29   CONSTANT  varchar :='29';--IDENTIFICATIVI VARI INESISTENTI
    PAGOPA_ERR_30   CONSTANT  varchar :='30';--ERRORE IN FASE DI INSERIMENTO DOCUMENTO
    PAGOPA_ERR_31   CONSTANT  varchar :='31';--ERRORE IN FASE DI ADEGUAMENTO IMPORTO ACCERTAMENTO
    PAGOPA_ERR_32   CONSTANT  varchar :='32';--ERRORE IN FASE DI VERIFICA DISPONIBILITA PROVVOSORIO DI CASSA
    PAGOPA_ERR_33   CONSTANT  varchar :='33';--DISPONIBILITA INSUFFICIENTE PER PROVVOSORIO DI CASSA
    PAGOPA_ERR_34   CONSTANT  varchar :='34';--DATI DI RICONCILIAZIONE ASSOCIATI A SOGGETTO NON ESISTENTE
    PAGOPA_ERR_35   CONSTANT  varchar :='35';--DATI DI RICONCILIAZIONE ASSOCIATI A STRUTTURA AMMINISTRATIVA NON ESISTENTE

    PAGOPA_ERR_36   CONSTANT  varchar :='36';--DATI DI RICONCILIAZIONE SCARTATI PER ANOMALIA SU GENERAZIONE DOC. PER PROV. CASSA

    PAGOPA_ERR_37   CONSTANT  varchar :='37';--ERRORE IN LETTURA PROGRESSIVI DOCUMENTI
    PAGOPA_ERR_38   CONSTANT  varchar :='38';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA REGOLARIZZATO
    PAGOPA_ERR_39   CONSTANT  varchar :='39';--PROVVISORIO DI CASSA REGOLARIZZATO


	-- 31.05.2019 siac-6720
	PAGOPA_ERR_41   CONSTANT  varchar :='41';--ESTREMI SOGGETTO NON PRESENTI PER DETTAGLIO
	PAGOPA_ERR_42   CONSTANT  varchar :='42';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO NON PRESENTE
	PAGOPA_ERR_43   CONSTANT  varchar :='43';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO NON VALIDO
 	PAGOPA_ERR_44   CONSTANT  varchar :='44';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO VALIDO NON UNIVOCO COD.FISC.
 	PAGOPA_ERR_45   CONSTANT  varchar :='45';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO VALIDO NON UNIVOCO PIVA
 	PAGOPA_ERR_46   CONSTANT  varchar :='46';--DATI RICONCILIAZIONE DETTAGLIO FAT. SENZA IDENTIFICATIVO SOGGETTO ASSOCIATO
 	PAGOPA_ERR_47   CONSTANT  varchar :='47';--ERRORE IN LETTURA IDENTIFICATIVO ATTRIBUTI ACCERTAMENTO
    PAGOPA_ERR_48   CONSTANT  varchar :='48';--TIPO DOCUMENTO NON PRESENTE SU DATI DI RICONCILIAZIONE
    PAGOPA_ERR_49   CONSTANT  varchar :='49';--DETTAGLI NON PRESENTI SU DATI DI RICONCILIAZIONE CON DETT
    PAGOPA_ERR_50   CONSTANT  varchar :='50';--DATI RICONCILIAZIONE DETTAGLIO FAT. PRIVI DI IMPORTO

    -- 22.07.2019 Sofia siac-6963 - inizio
	PAGOPA_ERR_51   CONSTANT  varchar :='51';--DATI RICONCILIAZIONE CON ACCERTAMENTO PRIVO DI SOGGETTO O INESISTENTE

    DOC_STATO_VALIDO    CONSTANT  varchar :='V';
	DOC_TIPO_IPA    CONSTANT  varchar :='IPA';
    --- 12.06.2019 SIAC-6720
    DOC_TIPO_COR    CONSTANT  varchar :='COR';
    DOC_TIPO_FAT    CONSTANT  varchar :='FTV';

    -- attributi siac_t_doc
	ANNO_REPERTORIO_ATTR CONSTANT varchar:='anno_repertorio';
	NUM_REPERTORIO_ATTR CONSTANT varchar:='num_repertorio';
	DATA_REPERTORIO_ATTR CONSTANT varchar:='data_repertorio';
	REG_REPERTORIO_ATTR CONSTANT varchar:='registro_repertorio';
	ARROTONDAMENTO_ATTR CONSTANT varchar:='arrotondamento';

	CAUS_SOSPENSIONE_ATTR CONSTANT varchar:='causale_sospensione';
	DATA_SOSPENSIONE_ATTR CONSTANT varchar:='data_sospensione';
    DATA_RIATTIVAZIONE_ATTR CONSTANT varchar:='data_riattivazione';
    DATA_SCAD_SOSP_ATTR CONSTANT varchar:='dataScadenzaDopoSospensione';
    TERMINE_PAG_ATTR CONSTANT varchar:='terminepagamento';
    NOTE_PAG_INC_ATTR CONSTANT varchar:='notePagamentoIncasso';
    DATA_PAG_INC_ATTR CONSTANT varchar:='dataOperazionePagamentoIncasso';

	FL_AGG_QUOTE_ELE_ATTR CONSTANT varchar:='flagAggiornaQuoteDaElenco';
    FL_SENZA_NUM_ATTR CONSTANT varchar:='flagSenzaNumero';
    FL_REG_RES_ATTR CONSTANT varchar:='flagDisabilitaRegistrazioneResidui';
    FL_PAGATA_INC_ATTR CONSTANT varchar:='flagPagataIncassata';
    COD_FISC_PIGN_ATTR CONSTANT varchar:='codiceFiscalePignorato';
    DATA_RIC_PORTALE_ATTR CONSTANT varchar:='dataRicezionePortale';

	FL_AVVISO_ATTR	 CONSTANT varchar:='flagAvviso';
    FL_ESPROPRIO_ATTR	 CONSTANT varchar:='flagEsproprio';
    FL_ORD_MANUALE_ATTR	 CONSTANT varchar:='flagOrdinativoManuale';
    FL_ORD_SINGOLO_ATTR	 CONSTANT varchar:='flagOrdinativoSingolo';
    FL_RIL_IVA_ATTR	 CONSTANT varchar:='flagRilevanteIVA';

    CAUS_ORDIN_ATTR	 CONSTANT varchar:='causaleOrdinativo';
    DATA_ESEC_PAG_ATTR	 CONSTANT varchar:='dataEsecuzionePagamento';


    TERMINE_PAG_DEF  CONSTANT integer=30;

    provvisorioId integer:=null;
    bilancioId integer:=null;
    periodoId integer:=null;

    filePagoPaId                    integer:=null;
    filePagoPaFileXMLId             varchar:=null;

    bElabora boolean:=true;
    bErrore boolean:=false;

    docTipoId integer:=null;

    --- 12.06.2019 Siac-6720
    docTipoFatId integer:=null;
    docTipoCorId integer:=null;
    docTipoCorNumAutom integer:=null;
    docTipoFatNumAutom integer:=null;
    nProgressivoFat integer:=null;
    nProgressivoCor integer:=null;
    nProgressivoTemp integer:=null;
	isDocIPA boolean:=false;

    codBolloId integer:=null;
    dDocImporto numeric:=null;
    dispAccertamento numeric:=null;
	dispProvvisorioCassa numeric:=null;

    strElencoFlussi varchar:=null;
    docStatoValId   integer:=null;
    cdrTipoId integer:=null;
    cdcTipoId integer:=null;
    subDocTipoId integer:=null;
	movgestTipoId  integer:=null;
    movgestTsTipoId integer:=null;
    movgestStatoId integer:=null;
    provvisorioTipoId integer:=null;
	movgestTsDetTipoId integer:=null;
	dnumQuote integer:=0;
    movgestTsId integer:=null;
    subdocMovgestTsId integer:=null;

    annoBilancio integer:=null;

    -- 11.06.2019 SIAC-6720
	numModifica  integer:=null;
    attoAmmId    integer:=null;
    modificaTipoId integer:=null;
    modifId       integer:=null;
    modifStatoId  integer:=null;
    modStatoRId   integer:=Null;

	-- 13.09.2019 Sofia SIAC-7034
    numeroFattura varchar(250):=null;

    fncRec record;
    pagoPaFlussoRec record;
    pagoPaFlussoQuoteRec record;
    elabRec record;

	-- 12.08.2019 Sofia SIAC-6978 - fine
    docIUV varchar(150):=null;
    -- 06.02.2020 Sofia jira siac-7375
    docDataOperazione timestamp:=null;
BEGIN

	strMessaggioFinale:='Elaborazione rinconciliazione PAGOPA per '||
                        'Id. elaborazione filePagoPaElabId='||filePagoPaElabId::varchar||
                        ' AnnoBilancioElab='||annoBilancioElab::varchar||'.';

    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale;
--    raise notice '%',strMessaggioLog;

	insert into pagopa_t_elaborazione_log
    (
     pagopa_elab_id,
     pagopa_elab_file_id,
     pagopa_elab_log_operazione,
     ente_proprietario_id,
     login_operazione,
     data_creazione
    )
    values
    (
     filePagoPaElabId,
     null,
     strMessaggioLog,
	 enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );
    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice '2222%',strMessaggioLog;
    raise notice '2222-codResult- %',codResult;
    codResult:=null;
    codiceRisultato:=0;
    messaggioRisultato:='';


    strMessaggio:='Verifica esistenza elaborazione.';
    --select elab.file_pagopa_id, elab.pagopa_elab_file_id into filePagoPaId, filePagoPaFileXMLId
    select 1 into codResult
    from pagopa_t_elaborazione elab, pagopa_d_elaborazione_stato stato
    where elab.pagopa_elab_id=filePagoPaElabId
    and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
    and   stato.pagopa_elab_stato_code in (ELABORATO_IN_CORSO_ST, ELABORATO_IN_CORSO_ER_ST,ELABORATO_IN_CORSO_SC_ST)
    and   stato.ente_proprietario_id=enteProprietarioId
    and   elab.data_cancellazione is null
    and   elab.validita_fine  is null;
    raise notice '2222strMessaggio  %',strMessaggio;
    raise notice '2222strMessaggio CodResult %',codResult;

--	if filePagoPaId is null or filePagoPaFileXMLId is null then
    if codResult is null then
        pagoPaCodeErr:=PAGOPA_ERR_20;
        strErrore:=' Non esistente.';
        codResult:=-1;
        bElabora:=false;
    else codResult:=null;
    end if;

/*  elaborazioni multi file
    if codResult is null then
     strMessaggio:='Verifica esistenza file di elaborazione per filePagoPaId='||filePagoPaId::varchar||
                   ' filePagoPaFileXMLId='||filePagoPaFileXMLId||'.';
     select 1 into codResult
     from siac_t_file_pagopa file, siac_d_file_pagopa_stato stato
     where file.file_pagopa_id=filePagoPaId
     and   file.file_pagopa_code=filePagoPaFileXMLId
     and   stato.file_pagopa_stato_id=file.file_pagopa_stato_id
     and   stato.file_pagopa_stato_code in (ELABORATO_IN_CORSO_ST, ELABORATO_IN_CORSO_ER_ST,ELABORATO_IN_CORSO_SC_ST)
     and   stato.ente_proprietario_id=enteProprietarioId
     and   file.data_cancellazione is null
     and   file.validita_fine  is null;

     if codResult is null then
    	pagoPaCodeErr:=PAGOPA_ERR_4;
        strErrore:=' Non esistente.';
        codResult:=-1;
        bElabora:=false;
     else codResult:=null;
     end if;
    end if;
*/


   if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_IPA||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoId
      from siac_d_doc_tipo tipo
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_IPA;
      if docTipoId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      end if;
   end if;

  if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_FAT||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoFatId
      from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_FAT
      and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
      and   fam.doc_fam_tipo_code='E';
      if docTipoFatId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      else
	      select 1 into docTipoFatNumAutom
          from siac_r_doc_tipo_attr rattr,siac_t_attr attr
          where rattr.doc_tipo_id=docTipoFatId
          and   attr.attr_id=rattr.attr_id
          and   attr.attr_code='flagSenzaNumero'
          and   coalesce(rattr.boolean,'N')='S'
          and   rattr.data_cancellazione is null
          and   rattr.validita_fine is null;
      end if;

  end if;

  if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_COR||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoCorId
      from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_COR
      and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
      and   fam.doc_fam_tipo_code='E';

      if docTipoCorId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      else
   	      select 1 into docTipoCorNumAutom
          from siac_r_doc_tipo_attr rattr,siac_t_attr attr
          where rattr.doc_tipo_id=docTipoCorId
          and   attr.attr_id=rattr.attr_id
          and   attr.attr_code='flagSenzaNumero'
          and   coalesce(rattr.boolean,'N')='S'
          and   rattr.data_cancellazione is null
          and   rattr.validita_fine is null;

      end if;
   end if;


   if codResult is null then
    	strMessaggio:='Lettura identificativo bollo esente.';
    	-- lettura tipodocumento
		select cod.codbollo_id into codBolloId
		from siac_d_codicebollo cod
		where cod.ente_proprietario_id=enteProprietarioId
		and   cod.codbollo_desc='ESENTE BOLLO';
        if codBolloId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_25;
    	    strErrore:=' Non riuscita.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;


   if codResult is null then
    	strMessaggio:='Lettura identificativo documento stato='||DOC_STATO_VALIDO||'.';
		select stato.doc_stato_id into docStatoValId
		from siac_d_doc_stato Stato
		where stato.ente_proprietario_id=enteProprietarioId
		and   stato.doc_stato_code=DOC_STATO_VALIDO;
        if docStatoValId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_26;
    	    strErrore:=' Non riuscita.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

    if codResult is null then
    	strMessaggio:='Lettura identificativo tipo CDC.';
		select tipo.classif_tipo_id into cdcTipoId
		from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code='CDC';
        if cdcTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_27;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo CDR.';
		select tipo.classif_tipo_id into cdrTipoId
		from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code='CDR';
        if cdrTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_27;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;


	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo subdocumento SE.';
		select tipo.subdoc_tipo_id into subDocTipoId
		from siac_d_subdoc_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.subdoc_tipo_code='SE';
        if subDocTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_28;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo accertamento.';
		select tipo.movgest_tipo_id into movgestTipoId
		from siac_d_movgest_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_tipo_code='A';
        if movgestTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo testata accertamento.';
		select tipo.movgest_ts_tipo_id into movgestTsTipoId
		from siac_d_movgest_ts_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_ts_tipo_code='T';
        if movgestTsTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo stato DEFINITIVO accertamento.';
		select tipo.movgest_stato_id into movgestStatoId
		from siac_d_movgest_stato tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_stato_code='D';
        if movgestStatoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo importo ATTUALE accertamento.';
		select tipo.movgest_ts_det_tipo_id into movgestTsDetTipoId
		from siac_d_movgest_ts_det_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_ts_det_tipo_code='A';
        if movgestTsDetTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;



	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo provvissorio cassa entrata.';
		select tipo.provc_tipo_id into provvisorioTipoId
		from siac_d_prov_cassa_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.provc_tipo_code='E';
        if provvisorioTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;

	if codResult is null then
     strMessaggio:='Gestione scarti di elaborazione. Verifica annoBilancio indicato su dettagli di riconciliazione.';
    raise notice '22229998@@%',strMessaggio;

     select  distinct doc.pagopa_ric_doc_anno_esercizio into annoBilancio
     from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
     where flusso.pagopa_elab_id=filePagoPaElabId
     and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc.pagopa_ric_doc_stato_elab='N'
     and   doc.pagopa_ric_doc_subdoc_id is null
     and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and   not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and   doc.data_cancellazione is null
     and   doc.validita_fine is null
     and   flusso.data_cancellazione is null
     and   flusso.validita_fine is null
     limit 1;
     if annoBilancio is null then
       	pagoPaCodeErr:=PAGOPA_ERR_12;
        strErrore:=' Dati non presenti.';
        codResult:=-1;
        bElabora:=false;
     else
     	if annoBilancio>annoBilancioElab then
           	pagoPaCodeErr:=PAGOPA_ERR_11;
	        strErrore:=' Anno bilancio successivo ad anno di elaborazione.';
    	    codResult:=-1;
        	bElabora:=false;
        end if;
     end if;
         raise notice '2222@@strErrore%',strErrore;

	end if;


    if codResult is null then
	 strMessaggio:='Gestione scarti di elaborazione. Verifica fase bilancio per elaborazione.';
         raise notice '22229997@@%',strMessaggio;

	 select bil.bil_id, per.periodo_id into bilancioId , periodoId
     from siac_t_bil bil,siac_t_periodo per,
          siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where per.ente_proprietario_id=enteProprietarioid
     and   per.anno::integer=annoBilancio
     and   bil.periodo_id=per.periodo_id
     and   r.bil_id=bil.bil_id
     and   fase.fase_operativa_id=r.fase_operativa_id
     -- 18.01.2021 Sofia Jira SIAC-7962
--     and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST);
     and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST,ESERCIZIO_CONSUNTIVO_ST);
     if bilancioId is null then
     	pagoPaCodeErr:=PAGOPA_ERR_18;
        strErrore:=' Fase non ammessa per elaborazione.';
        codResult:=-1;
        bElabora:=false;
	 end if;
   end if;

   if codResult is null then
	  strMessaggio:='Gestione scarti di elaborazione. Lettura progressivo doc. siac_t_doc_num per anno='||annoBilancio::varchar||'.';

      nProgressivo:=0;
      insert into  siac_t_doc_num
      (
        doc_anno,
        doc_numero,
        doc_tipo_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
      )
      select annoBilancio,
             nProgressivo,
             docTipoId,
             clock_timestamp(),
             loginOperazione,
             bil.ente_proprietario_id
      from siac_t_bil bil
      where bil.bil_id=bilancioId
      and not exists
      (
      select 1
      from siac_t_doc_num num
      where num.ente_proprietario_id=bil.ente_proprietario_id
      and   num.doc_anno::integer=annoBilancio
      and   num.doc_tipo_id=docTipoId
      and   num.data_cancellazione is null
      and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
      )
      returning doc_num_id into codResult;

      if codResult is null then
      	select num.doc_numero into codResult
        from siac_t_doc_num num
        where num.ente_proprietario_id=enteProprietarioId
        and   num.doc_anno::integer=annoBilancio
        and   num.doc_tipo_id=docTipoId;

        if codResult is not null then
        	nProgressivo:=codResult;
            codResult:=null;
        else
            pagoPaCodeErr:=PAGOPA_ERR_37;
        	strErrore:=' Progressivo non reperito.';
	        codResult:=-1;
    	    bElabora:=false;
        end if;
      else codResult:=null;
      end if;

   end if;

   --- 12.06.2019 Sofia SIAC-6720
   if codResult is null and
      (docTipoCorNumAutom is not null or docTipoFatNumAutom is not null ) then
	  strMessaggio:='Gestione scarti di elaborazione. Lettura progressivo doc. siac_t_doc_num ['
                   ||DOC_TIPO_FAT||'-'
                   ||DOC_TIPO_COR
                   ||'] per anno='||annoBilancio::varchar||'.';

      nProgressivoFat:=0;
      nProgressivoCor:=0;
      insert into  siac_t_doc_num
      (
        doc_anno,
        doc_numero,
        doc_tipo_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
      )
      select annoBilancio,
             nProgressivoFat,
             tipo.doc_tipo_id,
             clock_timestamp(),
             loginOperazione,
             bil.ente_proprietario_id
      from siac_t_bil bil,siac_d_doc_tipo tipo
      where bil.bil_id=bilancioId
      --and   tipo.doc_tipo_id in (docTipoFatId,docTipoCorId)
      and   tipo.doc_tipo_id in
      (select docTipoCorId doc_tipo_id where  docTipoCorNumAutom is not null
       union
       select docTipoFatId doc_tipo_id where  docTipoFatNumAutom is not null
      )
      and not exists
      (
      select 1
      from siac_t_doc_num num
      where num.ente_proprietario_id=bil.ente_proprietario_id
      and   num.doc_anno::integer=annoBilancio
      and   num.doc_tipo_id=tipo.doc_tipo_id
      and   num.data_cancellazione is null
      and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
      );
      GET DIAGNOSTICS codResult = ROW_COUNT;

	  codResult:=null;
      --if codResult is null then
      if docTipoCorNumAutom is not null then
          select num.doc_numero into codResult
          from siac_t_doc_num num
          where num.ente_proprietario_id=enteProprietarioId
          and   num.doc_anno::integer=annoBilancio
          and   num.doc_tipo_id =docTipoCorId;

          if codResult is not null then
              nProgressivoCor:=codResult;
              codResult:=null;
          else
              pagoPaCodeErr:=PAGOPA_ERR_37;
              strErrore:=' Progressivo non reperito.';
              codResult:=-1;
              bElabora:=false;
          end if;
      end if;

      if docTipoFatNumAutom is not null and codResult is null then
          select num.doc_numero into codResult
          from siac_t_doc_num num
          where num.ente_proprietario_id=enteProprietarioId
          and   num.doc_anno::integer=annoBilancio
          and   num.doc_tipo_id =docTipoFatId;

          if codResult is not null then
              nProgressivoFat:=codResult;
              codResult:=null;
          else
              pagoPaCodeErr:=PAGOPA_ERR_37;
              strErrore:=' Progressivo non reperito.';
              codResult:=-1;
              bElabora:=false;
          end if;
      end if;
--    else codResult:=null;
--    end if;

   end if;

   if codResult is null then
    strMessaggio:='Gestione scarti di elaborazione. Inserimento siac_t_registrounico_doc_num per anno='||annoBilancio::varchar||'.';
    raise notice '22229996@@%',strMessaggio;

	insert into  siac_t_registrounico_doc_num
    (
	  rudoc_registrazione_anno,
	  rudoc_registrazione_numero,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select annoBilancio,
           0,
           clock_timestamp(),
           loginOperazione,
           bil.ente_proprietario_id
    from siac_t_bil bil
    where bil.bil_id=bilancioId
    and not exists
    (
    select 1
    from siac_t_registrounico_doc_num num
    where num.ente_proprietario_id=bil.ente_proprietario_id
    and   num.rudoc_registrazione_anno::integer=annoBilancio
    and   num.data_cancellazione is null
    and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
    );
   end if;



    -- gestione scarti
    -- provvisorio non esistente
    if codResult is null then

 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_22||'.';
     raise notice '2222999999@@strMessaggio PAGOPA_ERR_22 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
              login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    not exists
     (
     select 1
     from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.provc_tipo_code='E'
     and   prov.provc_tipo_id=tipo.provc_tipo_id
     and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
     and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
     and   prov.provc_data_annullamento is null
     and   prov.provc_data_regolarizzazione is null
     and   prov.data_cancellazione is null
     and   prov.validita_fine is null
     )
     --     26.07.2019 Sofia questo controllo causa
     --     nelle update successive il non aggiornamento del motivo di scarto
     --     sulle righe dello stesso flusso ma con motivi diversi
     --     gli step successivi ( update successivi ) lasciano elab='N'
     --     in questo modo il flusso non viene elaborato
     --     in quanto la stessa condizione compare nel query del loop di elaborazione
     --     ma non tutti i dettagli in scarto vengono trattati ed eventualmente associati
     --     a un motivo di scarto
     --     bisogna tenerne conto quando un  flusso non viene elaborato
     --     e non tutti i dettagli hanno un motivo di scarto segnalato
     and    not exists -- esclusione flussi ( per provvisorio ) con scarti
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_22
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_22;
        strErrore:=' Provvisori di cassa non esistenti.';
     end if;
	 codResult:=null;
    end if;
--    raise notice 'strErrore=%',strErrore;

    --- provvisorio esistente , ma regolarizzato
    if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_38||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_38 %',strMessaggio;
     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     select 1
     from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo, siac_r_ordinativo_prov_cassa rp
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.provc_tipo_code='E'
     and   prov.provc_tipo_id=tipo.provc_tipo_id
     and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
     and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
     and   rp.provc_id=prov.provc_id
     and   prov.provc_data_annullamento is null
     and   prov.provc_data_regolarizzazione is null
     and   prov.data_cancellazione is null
     and   prov.validita_fine is null
     and   rp.data_cancellazione is null
     and   rp.validita_fine is null
     )
     and    not exists -- esclusione flussi ( per provvisorio ) con scarti
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_38
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)=0 then
       update pagopa_t_riconciliazione_doc doc
       set    pagopa_ric_doc_stato_elab='X',
        	  pagopa_ric_errore_id=err.pagopa_ric_errore_id,
              data_modifica=clock_timestamp(),
--               login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
               login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

   	   from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
	   where  flusso.pagopa_elab_id=filePagoPaElabId
       and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
       and    doc.pagopa_ric_doc_stato_elab='N'
       and    doc.pagopa_ric_doc_subdoc_id is null
       and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
       and    exists
       (
       select 1
       from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo, siac_r_subdoc_prov_cassa rp
       where tipo.ente_proprietario_id=doc.ente_proprietario_id
       and   tipo.provc_tipo_code='E'
       and   prov.provc_tipo_id=tipo.provc_tipo_id
       and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
       and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
       and   rp.provc_id=prov.provc_id
       and   prov.provc_data_annullamento is null
       and   prov.provc_data_regolarizzazione is null
       and   prov.data_cancellazione is null
       and   prov.validita_fine is null
       and   rp.data_cancellazione is null
       and   rp.validita_fine is null
       )
       and    not exists -- esclusione flussi ( per provvisorio ) con scarti
       (
       select 1
       from pagopa_t_riconciliazione_doc doc1
       where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
       and   doc1.pagopa_ric_doc_stato_elab!='N'
       and   doc1.data_cancellazione is null
       and   doc1.validita_fine is null
       )
       and    err.ente_proprietario_id=flusso.ente_proprietario_id
       and    err.pagopa_ric_errore_code=PAGOPA_ERR_38
       and    flusso.data_cancellazione is null
       and    flusso.validita_fine is null
       and    doc.data_cancellazione is null
       and    doc.validita_fine is null;
       GET DIAGNOSTICS codResult = ROW_COUNT;
     end if;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_38;
        strErrore:=' Provvisori di cassa regolarizzati.';
     end if;
	 codResult:=null;
    end if;

    if codResult is null then
     -- accertamento non esistente
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_23||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_23 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    not exists
     (
     select 1
     from siac_t_movgest mov, siac_d_movgest_tipo tipo,
          siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
          siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.movgest_tipo_code='A'
     and   mov.movgest_tipo_id=tipo.movgest_tipo_id
     and   mov.bil_id=bilancioId
     and   ts.movgest_id=mov.movgest_id
     and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
     and   tipots.movgest_ts_tipo_code='T'
     and   rs.movgest_ts_id=ts.movgest_ts_id
     and   stato.movgest_stato_id=rs.movgest_stato_id
     and   stato.movgest_stato_code='D'
     and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
     and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
     and   mov.data_cancellazione is null
     and   mov.validita_fine is null
     and   ts.data_cancellazione is null
     and   ts.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_23
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0  then
     	pagoPaCodeErr:=PAGOPA_ERR_23;
        strErrore:=' Accertamenti non esistenti.';
     end if;
     codResult:=null;
   end if;

--   raise notice 'strErrore=%',strErrore;

   -- siac-6720 31.05.2019 controlli - inizio


   -- dettagli con codice fiscale non indicato
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_41||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_41
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_41;
        strErrore:=' Estremi soggetto non indicati per dati di dettaglio-fatt.';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_42||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select  1
     from  siac_t_soggetto sog,siac_d_ambito ambito
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select  1
     from  siac_t_soggetto sog,siac_d_ambito ambito
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_42
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_42;
        strErrore:=' Soggetto inesistente per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto esistente ma non valido
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_43||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select  1
     from  siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
           siac_d_ambito ambito
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   rs.soggetto_id=sog.soggetto_id
     and   stato.soggetto_stato_id=rs.soggetto_stato_id
     and   stato.soggetto_stato_code='VALIDO'
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select  1
     from  siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
           siac_d_ambito ambito
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   rs.soggetto_id=sog.soggetto_id
     and   stato.soggetto_stato_id=rs.soggetto_stato_id
     and   stato.soggetto_stato_code='VALIDO'
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_43
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_43;
        strErrore:=' Soggetto esistente non VALIDO per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto esistente valido ma non univoco (diversi soggetti per stesso codice fiscale)
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_44||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select (case when 1<count(*) then 1 else 0 end)
	 from siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
          siac_d_ambito ambito
	 where sog.ente_proprietario_id=enteProprietarioId
	 and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs.soggetto_id=sog.soggetto_id
	 and   stato.soggetto_stato_id=rs.soggetto_stato_id
	 and   stato.soggetto_stato_code='VALIDO'
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
	 and   sog.data_cancellazione is null
	 and   sog.validita_fine is null
	 and   rs.data_cancellazione is null
	 and   rs.validita_fine is null
	 group by sog.codice_fiscale
	 having count(*)>1
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_44
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_44;
        strErrore:=' Soggetto esistente VALIDO non univoco (cod.fisc) per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   --  soggetto esistente valido ma non univoco (diversi soggetti per stessa partita iva)
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_45||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select (case when 1<count(*) then 1 else 0 end)
	 from siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
          siac_d_ambito ambito
	 where sog.ente_proprietario_id=enteProprietarioId
	 and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs.soggetto_id=sog.soggetto_id
	 and   stato.soggetto_stato_id=rs.soggetto_stato_id
	 and   stato.soggetto_stato_code='VALIDO'
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
	 and   sog.data_cancellazione is null
	 and   sog.validita_fine is null
	 and   rs.data_cancellazione is null
	 and   rs.validita_fine is null
	 group by sog.partita_iva
	 having count(*)>1
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_45
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_45;
        strErrore:=' Soggetto esistente VALIDO non univoco (p.iva) per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;


   -- aggiornare tutti i dettagli con il soggetto_id
   -- (anche il codice del soggetto !! adesso funziona gia' tutto con il codice del soggetto impostato )
   if codResult is null then
 	 strMessaggio:='Aggiornamento dati soggetto su dati di riconciliazione di dettaglio per codice fiscale [pagopa_t_riconciliazione_doc].';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_soggetto_id=sog.soggetto_id,
            pagopa_ric_doc_codice_benef=sog.soggetto_code,
            data_modifica=clock_timestamp()
     from pagopa_t_elaborazione_flusso flusso,siac_t_soggetto sog, siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
          siac_d_ambito ambito
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
     and    sog.ente_proprietario_id=enteProprietarioId
	 and    sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and    rs.soggetto_id=sog.soggetto_id
	 and    stato.soggetto_stato_id=rs.soggetto_stato_id
	 and    stato.soggetto_stato_code='VALIDO'
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
     and    exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select 1
	 from siac_t_soggetto sog1,siac_r_soggetto_stato rs1,siac_d_ambito ambito1
	 where sog1.ente_proprietario_id=enteProprietarioId
	 and   sog1.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs1.soggetto_id=sog1.soggetto_id
	 and   rs1.soggetto_stato_id=stato.soggetto_stato_id
     and   ambito1.ambito_id=sog1.ambito_id
     and   ambito1.ambito_code='AMBITO_FIN'
	 and   sog1.data_cancellazione is null
	 and   sog1.validita_fine is null
	 and   rs1.data_cancellazione is null
	 and   rs1.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null
  	 and    sog.data_cancellazione is null
	 and    sog.validita_fine is null
	 and    rs.data_cancellazione is null
	 and    rs.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     codResult:=null;
     strMessaggio:='Aggiornamento dati soggetto su dati di riconciliazione di dettaglio per partita iva [pagopa_t_riconciliazione_doc].';
     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_soggetto_id=sog.soggetto_id,
            pagopa_ric_doc_codice_benef=sog.soggetto_code,
            data_modifica=clock_timestamp()
     from pagopa_t_elaborazione_flusso flusso,siac_t_soggetto sog, siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
          siac_d_ambito ambito
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
     and    sog.ente_proprietario_id=enteProprietarioId
	 and    sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and    rs.soggetto_id=sog.soggetto_id
	 and    stato.soggetto_stato_id=rs.soggetto_stato_id
	 and    stato.soggetto_stato_code='VALIDO'
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     and    ambito.ambito_id=sog.ambito_id
     and    ambito.ambito_code='AMBITO_FIN'
     and    exists
     (
     select 1
	 from siac_t_soggetto sog1,siac_r_soggetto_stato rs1,siac_d_ambito ambito
	 where sog1.ente_proprietario_id=enteProprietarioId
	 and   sog1.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs1.soggetto_id=sog1.soggetto_id
	 and   rs1.soggetto_stato_id=stato.soggetto_stato_id
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     and   ambito.ambito_id=sog1.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
	 and   sog1.data_cancellazione is null
	 and   sog1.validita_fine is null
	 and   rs1.data_cancellazione is null
	 and   rs1.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null
  	 and    sog.data_cancellazione is null
	 and    sog.validita_fine is null
	 and    rs.data_cancellazione is null
	 and    rs.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     codResult:=null;
   end if;

   --  soggetto_id non aggiornato su dettagli di riconciliazione
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_46||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_46
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_46;
        strErrore:=' Esistanza  dati di dettaglio-fatt. senza estremi soggetto aggiornato. ';
     end if;
     codResult:=null;
   end if;

   --  importo non valorizzato  su dettagli di riconciliazione
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_50||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_sottovoce_importo,0)=0
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_50
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_50;
        strErrore:=' Esistanza  dati di dettaglio-fatt. senza importo valorizzato. ';
     end if;
     codResult:=null;
   end if;

   -- siac-6720 31.05.2019 controlli - fine

   -- siac-6720 31.05.2019 controlli commentare il seguente
   -- soggetto indicato non esistente non esistente
   /*if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_34||'.';
     raise notice '2222@@strMessaggio PAGOPA_ERR_34 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_codice_benef is not null
     and    not exists
     (
     select 1
     from siac_t_soggetto sog
     where sog.ente_proprietario_id=doc.ente_proprietario_id
     and   sog.soggetto_code=doc.pagopa_ric_doc_codice_benef
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_34
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_34;
        strErrore:=' Soggetto indicato non esistente.';
     end if;
     codResult:=null;
   end if;*/

   -- struttura amministrativa indicata non esistente indicato non esistente non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_35||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_35 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_str_amm,'')!=''
     and    not exists
     (
     select 1
     from siac_t_class c
     where c.ente_proprietario_id=doc.ente_proprietario_id
     and   c.classif_code=doc.pagopa_ric_doc_str_amm
     and   c.classif_tipo_id in (cdcTipoId,cdrTipoId)
     and   c.data_cancellazione is null
     and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine, date_trunc('DAY',now())))
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_35
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_35;
        strErrore:=' Struttura amministrativa indicata non esistente o non valida.';
     end if;
     codResult:=null;
   end if;

   -- 22.07.2019 Sofia siac-6963 - inizio
   -- accertamento indicato per IPA,COR senza soggetto o soggetto  non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_51||'.';
     raise notice '2222@@strMessaggio PAGOPA_ERR_51 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false
     and    doc.pagopa_ric_doc_flag_dett=false
     and    not exists
     (
      select 1
      from siac_t_movgest mov, siac_d_movgest_tipo tipo,
           siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
           siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato,
           siac_r_movgest_ts_sog rsog,siac_t_soggetto sog
      where tipo.ente_proprietario_id=doc.ente_proprietario_id
      and   tipo.movgest_tipo_code='A'
      and   mov.movgest_tipo_id=tipo.movgest_tipo_id
      and   mov.bil_id=bilancioId
      and   ts.movgest_id=mov.movgest_id
      and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   tipots.movgest_ts_tipo_code='T'
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code='D'
      and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
      and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
      and   rsog.movgest_ts_id=ts.movgest_ts_id
      and   sog.soggetto_id=rsog.soggetto_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   rsog.data_cancellazione is null
      and   rsog.validita_fine is null
      and   sog.data_cancellazione is null
      and   sog.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_51
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_51;
        strErrore:=' Soggetto non indicato su accertamento o non esistente.';
     end if;
     codResult:=null;
   end if;
   -- 22.07.2019 Sofia siac-6963 - fine

--raise notice '@@@@@@@@@@@@@pagoPaCodeErr   %',pagoPaCodeErr;
--raise notice 'codResult   %',codResult;
  ---  aggiornamento di pagopa_t_riconciliazione a partire da pagopa_t_riconciliazione_doc
  ---  per gli scarti prodotti in questa elaborazione
  if codResult is null then
   strMessaggio:='Gestione scarti di elaborazione. Aggiornamento pagopa_t_riconciliazione da pagopa_t_riconciliazione_doc.';
--   raise notice '2222@@strMessaggio   %',strMessaggio;
--   raise notice '@@@@@@@@@@@@@pagoPaCodeErr   %',pagoPaCodeErr;
   update pagopa_t_riconciliazione ric
   set    pagopa_ric_flusso_stato_elab='X',
  	      pagopa_ric_errore_id=doc.pagopa_ric_errore_id,
          data_modifica=clock_timestamp(),
--          login_operazione=ric.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
          login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

   from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
   where flusso.pagopa_elab_id=filePagoPaElabId
   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
   and   doc.pagopa_ric_doc_stato_elab='X'
   and   doc.login_operazione like '%@ELAB-'|| filePagoPaElabId::varchar||'%'
   and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId --- per elab_id
   and   ric.pagopa_ric_id=doc.pagopa_ric_id;
  end if;
  ---

   if codResult is null then
     strMessaggio:='Verifica esistenza dettagli di riconciliazione da elaborare.';

--     raise notice 'strMessaggio=%',strMessaggio;
     select 1 into codresult
     from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
     where flusso.pagopa_elab_id=filePagoPaElabId
     and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc.pagopa_ric_doc_stato_elab='N'
     and   doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and   not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and   doc.data_cancellazione is null
     and   doc.validita_fine is null
     and   flusso.data_cancellazione is null
     and   flusso.validita_fine is null;
--    raise notice 'codREsult=%',codResult;
     if codResult is null then
       	pagoPaCodeErr:=PAGOPA_ERR_7;
        strErrore:=' Dati non presenti.';
        codResult:=-1;
        bElabora:=false;
     else codResult:=null;
     end if;
   end if;



   if pagoPaCodeErr is not null then
     -- aggiornare anche pagopa_t_riconciliazione e pagopa_t_riconciliazione_doc
     strmessaggioBck:=strMessaggio;
     strMessaggio:=strMessaggio||' '||strErrore||' Aggiornamento pagopa_t_elaborazione.';
     raise notice 'strMessaggioStrErrore=%',strMessaggio;
	 update pagopa_t_elaborazione elab
     set    data_modifica=clock_timestamp(),
            validita_fine=(case when bElabora=false then clock_timestamp() else null end ),
            pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
            pagopa_elab_errore_id=err.pagopa_ric_errore_id,
		    pagopa_elab_note=substr(upper(strMessaggioFinale||' '||strMessaggio),1,1500) -- 09.10.2019 Sofia
     from  pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
     where elab.pagopa_elab_id=filePagoPaElabId
     and   statonew.ente_proprietario_id=elab.ente_proprietario_id
     and   statonew.pagopa_elab_stato_code=(case when bElabora=false then ELABORATO_ERRATO_ST else ELABORATO_IN_CORSO_SC_ST end)
     and   err.ente_proprietario_id=statonew.ente_proprietario_id
     and   err.pagopa_ric_errore_code=pagoPaCodeErr
     and   elab.data_cancellazione is null
     and   elab.validita_fine is null;


     strMessaggio:=strmessaggioBck||' '||strErrore||' Aggiornamento siac_t_file_pagopa.';
     update siac_t_file_pagopa file
     set    data_modifica=clock_timestamp(),
            file_pagopa_stato_id=stato.file_pagopa_stato_id,
            file_pagopa_errore_id=err.pagopa_ric_errore_id,
            file_pagopa_note=substr(upper(strMessaggioFinale||' '||strMessaggio),1,1500), -- 09.10.2019 Sofia
            login_operazione=substr(loginOperazione||'-'||file.login_operazione,1,200) -- 09.10.2019 Sofia
     from  pagopa_r_elaborazione_file r,
           siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
        where r.pagopa_elab_id=filePagoPaElabId
        and   file.file_pagopa_id=r.file_pagopa_id
        and   stato.ente_proprietario_id=file.ente_proprietario_id
        and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ER_ST
        and   err.ente_proprietario_id=stato.ente_proprietario_id
        and   err.pagopa_ric_errore_code=pagoPaCodeErr
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

     if bElabora= false then
      -- 10.05.2021 Sofia Jira SIAC-8167
      if pagoPaCodeErr=PAGOPA_ERR_7 then
      	codiceRisultato:=0;
      else
        codiceRisultato:=-1;
      end if;

      messaggioRisultato:= upper(strMessaggioFinale||' '||strmessaggioBck||' '||strErrore||'.');
      strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_esegui - '||messaggioRisultato;
      insert into pagopa_t_elaborazione_log
      (
       pagopa_elab_id,
       pagopa_elab_file_id,
       pagopa_elab_log_operazione,
       ente_proprietario_id,
       login_operazione,
       data_creazione
      )
      values
      (
       filePagoPaElabId,
       null,
       strMessaggioLog,
       enteProprietarioId,
       loginOperazione,
       clock_timestamp()
      );

      return;
     end if;
   end if;


  pagoPaCodeErr:=null;
  strMessaggio:='Inizio inserimento documenti.';
  strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
  insert into pagopa_t_elaborazione_log
  (
   pagopa_elab_id,
   pagopa_elab_file_id,
   pagopa_elab_log_operazione,
   ente_proprietario_id,
   login_operazione,
   data_creazione
  )
  values
  (
   filePagoPaElabId,
   null,
   strMessaggioLog,
   enteProprietarioId,
   loginOperazione,
   clock_timestamp()
  );

--  raise notice 'strMessaggio=%',strMessaggio;
  for pagoPaFlussoRec in
  (
   with
   pagopa_sogg as
   (
   with
   pagopa as
   (
   select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
   		  coalesce(doc.pagopa_ric_doc_soggetto_id,-1) pagopa_soggetto_id, -- 04.06.2019 siac-6720
		  doc.pagopa_ric_doc_str_amm pagopa_str_amm ,
          doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
		  doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
          doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
          doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento,
          doc.pagopa_ric_doc_tipo_code pagopa_doc_tipo_code, -- siac-6720
          doc.pagopa_ric_doc_tipo_id pagopa_doc_tipo_id,           -- siac-6720
          doc.pagopa_ric_doc_iuv     pagopa_doc_iuv ,   -- 06.02.2020 Sofia siac-7375
          doc.pagopa_ric_doc_data_operazione pagopa_doc_data_operazione -- 06.02.2020 Sofia siac-7375
   from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
   where flusso.pagopa_elab_id=filePagoPaElabId
   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
   and   doc.pagopa_ric_doc_stato_elab='N'
   and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
   and   doc.pagopa_ric_doc_subdoc_id is null
   --     26.07.2019 Sofia questo controllo causa
   --     la non elaborazione di flussi che hanno dettagli in scarto
   --     righe dello stesso flusso ma con motivi diversi
   --     possono esserci righe con scarto='X' e scarto='N'
   --     per le update a step successivi che hanno la stessa condizione
   --     in questo modo il flusso non viene elaborato
   --     non tutti i dettagli in scarto vengono trattati ed eventualmente associati
   --     a un motivo di scarto
   --     bisogna tenerne conto quando un  flusso non viene elaborato
   --     e non tutti i dettagli hanno un motivo di scarto segnalato
   and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
   )
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null
   and   flusso.data_cancellazione is null
   and   flusso.validita_fine is null
   group by doc.pagopa_ric_doc_codice_benef,
            coalesce(doc.pagopa_ric_doc_soggetto_id,-1), -- 04.06.2019 siac-6720
			doc.pagopa_ric_doc_str_amm,
            doc.pagopa_ric_doc_voce_tematica,
            doc.pagopa_ric_doc_voce_code,
            doc.pagopa_ric_doc_voce_desc,
            doc.pagopa_ric_doc_anno_accertamento,
            doc.pagopa_ric_doc_num_accertamento,
            doc.pagopa_ric_doc_tipo_code, -- siac-6720
            doc.pagopa_ric_doc_tipo_id, -- siac-6720
            doc.pagopa_ric_doc_iuv ,   -- 06.02.2020 Sofia siac-7375
            doc.pagopa_ric_doc_data_operazione -- 06.02.2020 Sofia siac-7375
   ),
   sogg as
   (
   select sog.soggetto_id, sog.soggetto_code,sog.soggetto_desc
   from siac_t_soggetto sog
   where sog.ente_proprietario_id=enteProprietarioId
   and   sog.data_cancellazione is null
   and   sog.validita_fine is null
   )
   select pagopa.*,
          sogg.soggetto_id,
          sogg.soggetto_desc
   from pagopa
---        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code) -- 04.06.2019 siac-6720
        left join sogg on (pagopa.pagopa_soggetto_id=sogg.soggetto_id)
   ),
   accertamenti_sogg as
   (
   with
   accertamenti as
   (
   	select mov.movgest_anno::integer, mov.movgest_numero::integer,
           mov.movgest_id, ts.movgest_ts_id
    from siac_t_movgest mov , siac_d_movgest_tipo tipo,
         siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code='A'
    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
    and   mov.bil_id=bilancioId
    and   ts.movgest_id=mov.movgest_id
    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   tipots.movgest_ts_tipo_code='T'
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code='D'
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
   ),
   soggetto_acc as
   (
   select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc,rsog.movgest_ts_id
   from siac_r_movgest_ts_sog rsog, siac_t_soggetto sog
   where sog.ente_proprietario_id=enteProprietarioId
   and   rsog.soggetto_id=sog.soggetto_id
   and   rsog.data_cancellazione is null
   and   rsog.validita_fine is null
   )
   select accertamenti.*,soggetto_acc.soggetto_id, soggetto_acc.soggetto_code,soggetto_acc.soggetto_desc
   from   accertamenti --, soggetto_acc -- 22.07.2019 siac-6963
          left join soggetto_acc on (accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id) -- 22.07.2019 siac-6963
--   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id -- 22.07.2019 siac-6963
   )
   select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
   		   ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc,
		   ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
           pagopa_sogg.pagopa_str_amm,
           pagopa_sogg.pagopa_voce_tematica,
           pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
           pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id, -- siac-6720
           pagopa_sogg.pagopa_doc_iuv, pagopa_sogg.pagopa_doc_data_operazione -- 06.02.2020 Sofia siac-7375
   from  pagopa_sogg, accertamenti_sogg
   where pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
   and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
   group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
            ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
            ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )  ,
            pagopa_sogg.pagopa_str_amm,
            pagopa_sogg.pagopa_voce_tematica,
            pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
            pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id,  -- siac-6720
            pagopa_sogg.pagopa_doc_iuv, pagopa_sogg.pagopa_doc_data_operazione -- 06.02.2020 Sofia siac-7375
   order by  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
   			 pagopa_sogg.pagopa_str_amm,
             pagopa_sogg.pagopa_voce_tematica,
			 pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
             pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id  -- siac-6720

  )
  loop
   		-- filePagoPaElabId - elaborazione id
        -- filePagoPaId     - file pagopa id
        -- filePagoPaFileXMLId  - file pagopa id XML
        -- pagopa_soggetto_id
        -- pagopa_soggetto_code
        -- pagopa_voce_code
        -- pagopa_voce_desc
        -- pagopa_str_amm

        -- elementi per inserimento documento

        -- inserimento documento
        -- siac_t_doc ok
        -- siac_r_doc_sog ok
        -- siac_r_doc_stato ok
        -- siac_r_doc_class ok struttura amministrativa
        -- siac_r_doc_attr ok
        -- siac_t_registrounico_doc ok
        -- siac_t_subdoc_num ok

        -- siac_t_subdoc ok
        -- siac_r_subdoc_attr ok
        -- siac_r_subdoc_class -- non ce ne sono

        -- siac_r_subdoc_atto_amm ok
        -- siac_r_subdoc_movgest_ts ok
        -- siac_r_subdoc_prov_cassa ok

        dDocImporto:=0;
        strElencoFlussi:=' ';
        dnumQuote:=0;
        bErrore:=false;
		docIUV:=null;
        -- 06.02.2020 Sofia jira siac-7375
        docDataOperazione:=null;

		-- 12.08.2019 Sofia SIAC-6978 - inizio
		if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_FAT then
          strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                        ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                        ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_t_doc].'
                        ||' Lettura codice IUV.';
          strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;

          insert into pagopa_t_elaborazione_log
          (
           pagopa_elab_id,
           pagopa_elab_file_id,
           pagopa_elab_log_operazione,
           ente_proprietario_id,
           login_operazione,
           data_creazione
          )
          values
          (
           filePagoPaElabId,
           null,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
          );

         /* select distinct query.pagopa_ric_doc_iuv into docIUV
          from
          (
             with
             pagopa_sogg as
             (
             with
             pagopa as
             (
             select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
                    coalesce(doc.pagopa_ric_doc_soggetto_id,-1) pagopa_soggetto_id, -- 04.06.2019 siac-6720
                    doc.pagopa_ric_doc_str_amm pagopa_str_amm ,
                    doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
                    doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
                    doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento,
                    doc.pagopa_ric_doc_tipo_code pagopa_doc_tipo_code, -- siac-6720
                    doc.pagopa_ric_doc_tipo_id pagopa_doc_tipo_id, -- siac-6720
                    doc.pagopa_ric_doc_iuv pagopa_ric_doc_iuv
             from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
             where flusso.pagopa_elab_id=filePagoPaElabId
             and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
             and   doc.pagopa_ric_doc_stato_elab='N'
             and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
             and   doc.pagopa_ric_doc_subdoc_id is null
             --     26.07.2019 Sofia questo controllo causa
             --     la non elaborazione di flussi che hanno dettagli in scarto
             --     righe dello stesso flusso ma con motivi diversi
             --     possono esserci righe con scarto='X' e scarto='N'
             --     per le update a step successivi che hanno la stessa condizione
             --     in questo modo il flusso non viene elaborato
             --     non tutti i dettagli in scarto vengono trattati ed eventualmente associati
             --     a un motivo di scarto
             --     bisogna tenerne conto quando un  flusso non viene elaborato
             --     e non tutti i dettagli hanno un motivo di scarto segnalato
             -- 06.12.2019 Sofia jira SIAC-7251  -- errore in esecuzione e poi scarto
            /* and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
             (
               select 1
               from pagopa_t_riconciliazione_doc doc1
               where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
               and   doc1.pagopa_ric_doc_stato_elab!='N'
               and   doc1.data_cancellazione is null
               and   doc1.validita_fine is null
             )*/
             and   doc.data_cancellazione is null
             and   doc.validita_fine is null
             and   flusso.data_cancellazione is null
             and   flusso.validita_fine is null
             group by doc.pagopa_ric_doc_codice_benef,
                      coalesce(doc.pagopa_ric_doc_soggetto_id,-1), -- 04.06.2019 siac-6720
                      doc.pagopa_ric_doc_str_amm,
                      doc.pagopa_ric_doc_voce_tematica,
                      doc.pagopa_ric_doc_voce_code,
                      doc.pagopa_ric_doc_voce_desc,
                      doc.pagopa_ric_doc_anno_accertamento,
                      doc.pagopa_ric_doc_num_accertamento,
                      doc.pagopa_ric_doc_tipo_code, -- siac-6720
                      doc.pagopa_ric_doc_tipo_id, -- siac-6720
                      doc.pagopa_ric_doc_iuv
             ),
             sogg as
             (
             select sog.soggetto_id, sog.soggetto_code,sog.soggetto_desc
             from siac_t_soggetto sog
             where sog.ente_proprietario_id=enteProprietarioId
             and   sog.data_cancellazione is null
             and   sog.validita_fine is null
             )
             select pagopa.*,
                    sogg.soggetto_id,
                    sogg.soggetto_desc
             from pagopa
          ---        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code) -- 04.06.2019 siac-6720
                  left join sogg on (pagopa.pagopa_soggetto_id=sogg.soggetto_id)
             ),
             accertamenti_sogg as
             (
             with
             accertamenti as
             (
              select mov.movgest_anno::integer, mov.movgest_numero::integer,
                     mov.movgest_id, ts.movgest_ts_id
              from siac_t_movgest mov , siac_d_movgest_tipo tipo,
                   siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
                   siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
              where tipo.ente_proprietario_id=enteProprietarioId
              and   tipo.movgest_tipo_code='A'
              and   mov.movgest_tipo_id=tipo.movgest_tipo_id
              and   mov.bil_id=bilancioId
              and   ts.movgest_id=mov.movgest_id
              and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
              and   tipots.movgest_ts_tipo_code='T'
              and   rs.movgest_ts_id=ts.movgest_ts_id
              and   stato.movgest_stato_id=rs.movgest_stato_id
              and   stato.movgest_stato_code='D'
              and   mov.data_cancellazione is null
              and   mov.validita_fine is null
              and   ts.data_cancellazione is null
              and   ts.validita_fine is null
              and   rs.data_cancellazione is null
              and   rs.validita_fine is null
             ),
             soggetto_acc as
             (
             select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc,rsog.movgest_ts_id
             from siac_r_movgest_ts_sog rsog, siac_t_soggetto sog
             where sog.ente_proprietario_id=enteProprietarioId
             and   rsog.soggetto_id=sog.soggetto_id
             and   rsog.data_cancellazione is null
             and   rsog.validita_fine is null
             )
             select accertamenti.*,soggetto_acc.soggetto_id, soggetto_acc.soggetto_code,soggetto_acc.soggetto_desc
             from   accertamenti --, soggetto_acc -- 22.07.2019 siac-6963
                    left join soggetto_acc on (accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id) -- 22.07.2019 siac-6963
          --   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id -- 22.07.2019 siac-6963
             )
             select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
                     ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc,
                     ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
                     pagopa_sogg.pagopa_str_amm,
                     pagopa_sogg.pagopa_voce_tematica,
                     pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                     pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id, -- siac-6720,
                     pagopa_sogg.pagopa_ric_doc_iuv
             from  pagopa_sogg, accertamenti_sogg
             where pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
             and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
             group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
                      ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
                      ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )  ,
                      pagopa_sogg.pagopa_str_amm,
                      pagopa_sogg.pagopa_voce_tematica,
                      pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                      pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id,  -- siac-6720
                      pagopa_sogg.pagopa_ric_doc_iuv
             order by  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
                       pagopa_sogg.pagopa_str_amm,
                       pagopa_sogg.pagopa_voce_tematica,
                       pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                       pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id
          )
          query
          where query.pagopa_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id
          and   coalesce(query.pagopa_voce_tematica,'')=coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(query.pagopa_voce_tematica,''))
          and   query.pagopa_voce_code=pagoPaFlussoRec.pagopa_voce_code
          and   coalesce(query.pagopa_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(query.pagopa_voce_desc,''))
          and   coalesce(query.pagopa_str_amm,'')=coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(query.pagopa_str_amm,''))
          and   query.pagopa_soggetto_id=pagoPaFlussoRec.pagopa_soggetto_id;*/

        -- 06.02.2020 Sofia jira siac-7375
        docIUV:=pagoPaFlussoRec.pagopa_doc_iuv;
        raise notice 'IUUUUUUUUUV docIUV=%',docIUV;
       	if coalesce(docIUV,'')='' or docIUV is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Lettura non riuscita.';
        end if;
        -- 06.02.2020 Sofia jira siac-7375
        docDataOperazione:=pagoPaFlussoRec.pagopa_doc_data_operazione;
        raise notice 'IUUUUUUUUUV docDataOperazione=%',docDataOperazione;

       end if;
 	   -- 12.08.2019 Sofia SIAC-6978 - fine


       if bErrore=false then
		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_t_doc].';
		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;

        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );

		docId:=null;

        -- 12.06.2019 SIAC-6720
--        nProgressivo:=nProgressivo+1;
        nProgressivoTemp:=null;
        isDocIPA:=false;
        -- 13.09.2019 Sofia SIAC-7034
        numeroFattura:=null;

        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_FAT and docTipoFatNumAutom is not null then
        	nProgressivoFat:=nProgressivoFat+1;
            nProgressivoTemp:=nProgressivoFat;
            -- 13.09.2019 Sofia SIAC-7034
            numeroFattura:= pagoPaFlussoRec.pagopa_voce_code||'-'||nProgressivoTemp::varchar;
        end if;
        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_COR and docTipoCorNumAutom is not null then
        	nProgressivoCor:=nProgressivoCor+1;
            nProgressivoTemp:=nProgressivoCor;
        end if;
        if nProgressivoTemp is null then
	          nProgressivo:=nProgressivo+1;
              nProgressivoTemp:=nProgressivo;
              isDocIPA:=true;
        end if;

        -- 13.09.2019 Sofia SIAC-7034
        if numeroFattura is null then
           numeroFattura:= pagoPaFlussoRec.pagopa_voce_code||' '
                          ||extract ( day from dataElaborazione)||'-'
                          ||lpad(extract ( month from dataElaborazione)::varchar,2,'0')
                          ||'-'||extract ( year from dataElaborazione)
                          -- ||' ' 20.04.2020 Sofia jira	SIAC-7586
                          ||' '||nProgressivoTemp::varchar;
        end if;



--        raise notice 'pagoPaFlussoRec.pagopa_doc_tipo_code=%',pagoPaFlussoRec.pagopa_doc_tipo_code;
--        raise notice 'isDocIPA=%',isDocIPA;
--		raise notice 'nProgressivo=%',nProgressivo;
--        raise notice 'nProgressivoCor=%',nProgressivoCor;
--        raise notice 'nProgressivoFat=%',nProgressivoFat;
		-- siac_t_doc
        insert into siac_t_doc
        (
        	doc_anno,
		    doc_numero,
			doc_desc,
		    doc_importo,
		    doc_data_emissione, -- dataElaborazione
			doc_data_scadenza,  -- dataSistema
		    doc_tipo_id,
		    codbollo_id,
		    validita_inizio,
		    ente_proprietario_id,
		    login_operazione,
		    login_creazione,
            login_modifica,
			pcccod_id, -- null ??
	        pccuff_id,
            IUV, -- null ??  -- 12.08.2019 Sofia SIAC-6978 - fine
            doc_data_operazione -- 06.02.2020 Sofia jira siac-7375
        )
        select annoBilancio,
--               pagoPaFlussoRec.pagopa_voce_code||' '||dataElaborazione||' '||nProgressivoTemp::varchar,
               numeroFattura,-- 13.09.2019 Sofia SIAC-7034
               upper('Incassi '
               		 ||substring(coalesce(pagoPaFlussoRec.pagopa_voce_tematica,' '),1,30)||' '
                     ||pagoPaFlussoRec.pagopa_voce_code||' '
                     ||substring(coalesce(pagoPaFlussoRec.pagopa_voce_desc,' '),1,30) ||' '||strElencoFlussi),
			   dDocImporto,
               dataElaborazione,
               dataElaborazione,
--			   docTipoId, siac-6720 28.05.2019 Sofia
               pagoPaFlussoRec.pagopa_doc_tipo_id, -- siac-6720 28.05.2019 Sofia
               codBolloId,
               clock_timestamp(),
               enteProprietarioId,
               loginOperazione,
               loginOperazione,
               loginOperazione,
               null,
               null,
               docIUV,   -- 12.08.2019 Sofia SIAC-6978 - fine
               docDataOperazione -- 06.02.2020 Sofia jira siac-7375
        returning doc_id into docId;
--	    raise notice 'docid=%',docId;
		if docId is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
        end if;
       end if;


	   if bErrore=false then
		 codResult:=null;
	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_r_doc_sog].';
		 -- siac_r_doc_sog
         insert into siac_r_doc_sog
         (
        	doc_id,
            soggetto_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
         )
         select  docId,
                 pagoPaFlussoRec.pagopa_soggetto_id,
                 clock_timestamp(),
                 loginOperazione,
                 enteProprietarioId
         returning  doc_sog_id into codResult;

         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';

         end if;
        end if;

	    if bErrore=false then
         codResult:=null;
	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_r_doc_stato].';
         insert into siac_r_doc_stato
         (
        	doc_id,
            doc_stato_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
         )
         select docId,
                docStatoValId,
                clock_timestamp(),
                loginOperazione,
                enteProprietarioId
         returning doc_stato_r_id into codResult;
		 if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
		end if;

        if bErrore=false then
         -- siac_r_doc_attr
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||ANNO_REPERTORIO_ATTR||' [siac_r_doc_attr].';

         -- anno_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
         	    --annoBilancio::varchar,
                NULL,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=ANNO_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then

	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||NUM_REPERTORIO_ATTR||' [siac_r_doc_attr].';

         -- num_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
         	    null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=NUM_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||DATA_REPERTORIO_ATTR||' [siac_r_doc_attr].';
		 -- data_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
--        	    extract( 'day' from now())::varchar||'/'||
--               lpad(extract( 'month' from now())::varchar,2,'0')||'/'||
--               extract( 'year' from now())::varchar,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=DATA_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

        if bErrore=false then
		 -- registro_repertorio
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||REG_REPERTORIO_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=REG_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
		 -- arrotondamento
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||ARROTONDAMENTO_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            numerico,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                0,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=ARROTONDAMENTO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		/*if bErrore=false then
         -- causale_sospensione
 		 -- data_sospensione
 		 -- data_riattivazione
   		 -- dataScadenzaDopoSospensione
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi sospensione [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code in (CAUS_SOSPENSIONE_ATTR,DATA_SOSPENSIONE_ATTR,DATA_RIATTIVAZIONE_ATTR/*,DATA_SCAD_SOSP_ATTR*/);
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;*/

        if bErrore=false then
		 -- terminepagamento
		 strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||TERMINE_PAG_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            numerico,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                TERMINE_PAG_DEF,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=TERMINE_PAG_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		/*if bErrore=false then
	     -- notePagamentoIncasso
    	 -- dataOperazionePagamentoIncasso
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi pagamento incasso [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code in (NOTE_PAG_INC_ATTR,DATA_PAG_INC_ATTR);
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;*/

		if bErrore=false then
         -- flagAggiornaQuoteDaElenco
		 -- flagSenzaNumero
		 -- flagDisabilitaRegistrazioneResidui
		 -- flagPagataIncassata
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi flag [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            boolean,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                'N',
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
--         and   a.attr_code in (/*FL_AGG_QUOTE_ELE_ATTR,*/FL_SENZA_NUM_ATTR,FL_REG_RES_ATTR);--,FL_PAGATA_INC_ATTR);
         and   a.attr_code=FL_REG_RES_ATTR;

         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
		 -- codiceFiscalePignorato
		 -- dataRicezionePortale

		 strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi vari [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
--         and   a.attr_code in (COD_FISC_PIGN_ATTR,DATA_RIC_PORTALE_ATTR);
         and   a.attr_code=DATA_RIC_PORTALE_ATTR;
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;
        if bErrore=false then
		 -- siac_r_doc_class
         if coalesce(pagoPaFlussoRec.pagopa_str_amm ,'')!='' then
            strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa [siac_r_doc_class]'
                         ||'. Verifica esistenza come CDC.';

        	codResult:=null;
            select c.classif_id into codResult
            from siac_t_class c
            where c.classif_tipo_id=cdcTipoId
            and   c.classif_code=pagoPaFlussoRec.pagopa_str_amm
            and   c.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine,date_trunc('DAY',now())));
            if codResult is null then
                strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa  [siac_r_doc_class]'
                         ||'. Verifica esistenza come CDR.';
	            select c.classif_id into codResult
    	        from siac_t_class c
        	    where c.classif_tipo_id=cdrTipoId
	           	and   c.classif_code=pagoPaFlussoRec.pagopa_str_amm
    	        and   c.data_cancellazione is null
        	    and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine,date_trunc('DAY',now())));
            end if;
            if codResult is not null then
               codResult1:=codResult;
               codResult:=null;
	           strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa  [siac_r_doc_class].';

            	insert into siac_r_doc_class
                (
                	doc_id,
                    classif_id,
                    validita_inizio,
                    login_operazione,
                    ente_proprietario_id
                )
                values
                (
                	docId,
                    codResult1,
                    clock_timestamp(),
                    loginOperazione,
                    enteProprietarioId
                )
                returning doc_classif_id into codResult;

                if codResult is null then
                	bErrore:=true;
		            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
                end if;
            end if;
         end if;
        end if;

		if bErrore =false then
		 --  siac_t_registrounico_doc
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento registro unico documento [siac_t_registrounico_doc].';

      	 codResult:=null;
         insert into siac_t_registrounico_doc
         (
        	rudoc_registrazione_anno,
 			rudoc_registrazione_numero,
			rudoc_registrazione_data,
			doc_id,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select num.rudoc_registrazione_anno,
                num.rudoc_registrazione_numero+1,
                clock_timestamp(),
                docId,
                loginOperazione,
                clock_timestamp(),
                num.ente_proprietario_id
         from siac_t_registrounico_doc_num num
         where num.ente_proprietario_id=enteProprietarioId
         and   num.rudoc_registrazione_anno=annoBilancio
         and   num.data_cancellazione is null
         and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
         returning rudoc_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
         if bErrore=false then
            codResult:=null;
         	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento registro unico documento [siac_t_registrounico_doc_num].';
         	update siac_t_registrounico_doc_num num
            set    rudoc_registrazione_numero=num.rudoc_registrazione_numero+1,
                   data_modifica=clock_timestamp()
        	where num.ente_proprietario_id=enteProprietarioId
	        and   num.rudoc_registrazione_anno=annoBilancio
         	and   num.data_cancellazione is null
	        and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
            returning num.rudoc_num_id into codResult;
            if codResult is null  then
               bErrore:=true;
               strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
            end if;
         end if;
        end if;

		if bErrore =false then
         codResult:=null;
		 --  siac_t_doc_num
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento progressivi documenti [siac_t_doc_num].';
         --- 12.06.2019 Siac-6720
--         raise notice 'pagoPaFlussoRec.pagopa_doc_tipo_code2=%',pagoPaFlussoRec.pagopa_doc_tipo_code;
         if isDocIPA=true then
           update siac_t_doc_num num
           set    doc_numero=num.doc_numero+1,
                  data_modifica=clock_timestamp()
           where  num.ente_proprietario_id=enteProprietarioid
           and    num.doc_anno=annoBilancio
           and    num.doc_tipo_id=docTipoId
           returning num.doc_num_id into codResult;
         else
           update siac_t_doc_num num
           set    doc_numero=num.doc_numero+1,
                  data_modifica=clock_timestamp()
           where  num.ente_proprietario_id=enteProprietarioid
           and    num.doc_anno=annoBilancio
           and    num.doc_tipo_id =pagoPaFlussoRec.pagopa_doc_tipo_id
           returning num.doc_num_id into codResult;
         end if;
         if codResult is null then
         	 bErrore:=true;
             strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
         end if;
        end if;

        if bErrore=true then
            strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
        end if;


		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento.';
--        raise notice 'strMessaggio=%',strMessaggio;
		if bErrore=false then
			strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
	    end if;

        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );
raise notice 'prima di quote berrore=%',berrore;
        for pagoPaFlussoQuoteRec in
  		(
  	     with
           pagopa_sogg as
		   (
           with
		   pagopa as
		   (
		   select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
			      doc.pagopa_ric_doc_str_amm pagopa_str_amm,
                  doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
           		  doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
                  doc.pagopa_ric_doc_sottovoce_code pagopa_sottovoce_code, doc.pagopa_ric_doc_sottovoce_desc pagopa_sottovoce_desc,
                  flusso.pagopa_elab_flusso_anno_provvisorio pagopa_anno_provvisorio,
                  flusso.pagopa_elab_flusso_num_provvisorio pagopa_num_provvisorio,
                  flusso.pagopa_elab_ric_flusso_id pagopa_flusso_id,
                  flusso.pagopa_elab_flusso_nome_mittente pagopa_flusso_nome_mittente,
        		  doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
		          doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento,
                  doc.pagopa_ric_doc_sottovoce_importo pagopa_sottovoce_importo
		   from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
		   where flusso.pagopa_elab_id=filePagoPaElabId
		   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
           and   doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
           and   coalesce(doc.pagopa_ric_doc_iuv,'')=coalesce(pagoPaFlussoRec.pagopa_doc_iuv,'') -- 06.02.2020 Sofia siac-7375
           and   coalesce(doc.pagopa_ric_doc_data_operazione,'2020-01-01'::timestamp)=
                 coalesce(pagoPaFlussoRec.pagopa_doc_data_operazione,'2020-01-01'::timestamp) -- 06.02.2020 Sofia siac-7375
           and   coalesce(doc.pagopa_ric_doc_voce_tematica,'')=coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
           and   doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
           and   coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
           and   coalesce(doc.pagopa_ric_doc_str_amm,'')=coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
		   and   doc.pagopa_ric_doc_stato_elab='N'
           and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
		   and   doc.pagopa_ric_doc_subdoc_id is null
		   and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
		   (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		   )
		   and   doc.data_cancellazione is null
		   and   doc.validita_fine is null
		   and   flusso.data_cancellazione is null
		   and   flusso.validita_fine is null
		   ),
		   sogg as
		   (
			   select sog.soggetto_id, sog.soggetto_code,sog.soggetto_desc
			   from siac_t_soggetto sog
			   where sog.ente_proprietario_id=enteProprietarioId
			   and   sog.data_cancellazione is null
			   and   sog.validita_fine is null
		   )
		   select pagopa.*,
		          sogg.soggetto_id,
        		  sogg.soggetto_desc
		   from pagopa
		        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code)
		   ),
		   accertamenti_sogg as
		   (
             with
			 accertamenti as
			 (
			   	select mov.movgest_anno::integer, mov.movgest_numero::integer,
		    	       mov.movgest_id, ts.movgest_ts_id
			    from siac_t_movgest mov , siac_d_movgest_tipo tipo,
			         siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
			         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
			    where tipo.ente_proprietario_id=enteProprietarioId
			    and   tipo.movgest_tipo_code='A'
			    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
			    and   mov.bil_id=bilancioId
			    and   ts.movgest_id=mov.movgest_id
			    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
			    and   tipots.movgest_ts_tipo_code='T'
			    and   rs.movgest_ts_id=ts.movgest_ts_id
			    and   stato.movgest_stato_id=rs.movgest_stato_id
			    and   stato.movgest_stato_code='D'
			    and   mov.data_cancellazione is null
			    and   mov.validita_fine is null
			    and   ts.data_cancellazione is null
			    and   ts.validita_fine is null
			    and   rs.data_cancellazione is null
			    and   rs.validita_fine is null
		   ),
		   soggetto_acc as
		   (
			   select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc,rsog.movgest_ts_id
			   from siac_r_movgest_ts_sog rsog, siac_t_soggetto sog
			   where sog.ente_proprietario_id=enteProprietarioId
			   and   rsog.soggetto_id=sog.soggetto_id
			   and   rsog.data_cancellazione is null
			   and   rsog.validita_fine is null
		   )
		   select accertamenti.*,soggetto_acc.soggetto_id, soggetto_acc.soggetto_code,soggetto_acc.soggetto_desc
		   from   accertamenti -- , soggetto_acc -- 22.07.2019 siac-6963
                  left join soggetto_acc on (accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id) -- 22.07.2019 siac-6963
--		   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id -- 22.07.2019 siac-6963
	  	 )
		 select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
   				 ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc	,
                 ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
                 pagopa_sogg.pagopa_str_amm,
                 pagopa_sogg.pagopa_voce_tematica,
                 pagopa_sogg.pagopa_voce_code,  pagopa_sogg.pagopa_voce_desc,
                 pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                 pagopa_sogg.pagopa_flusso_id,
                 pagopa_sogg.pagopa_flusso_nome_mittente,
                 pagopa_sogg.pagopa_anno_provvisorio,
                 pagopa_sogg.pagopa_num_provvisorio,
                 pagopa_sogg.pagopa_anno_accertamento,
		         pagopa_sogg.pagopa_num_accertamento,
                 sum(pagopa_sogg.pagopa_sottovoce_importo) pagopa_sottovoce_importo
  	     from  pagopa_sogg, accertamenti_sogg
 	     where bErrore=false
         and   pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
	   	 and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
         and   (case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )=
	           pagoPaFlussoRec.pagopa_soggetto_id
	     group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
        	      ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
                  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ),
                  pagopa_sogg.pagopa_str_amm,
                  pagopa_sogg.pagopa_voce_tematica,
                  pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                  pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                  pagopa_sogg.pagopa_flusso_id,pagopa_sogg.pagopa_flusso_nome_mittente,
                  pagopa_sogg.pagopa_anno_provvisorio,
                  pagopa_sogg.pagopa_num_provvisorio,
                  pagopa_sogg.pagopa_anno_accertamento,
		          pagopa_sogg.pagopa_num_accertamento
	     order by  pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                   pagopa_sogg.pagopa_anno_provvisorio,
                   pagopa_sogg.pagopa_num_provvisorio,
				   pagopa_sogg.pagopa_anno_accertamento,
		           pagopa_sogg.pagopa_num_accertamento
  	   )
       loop

        codResult:=null;
        codResult1:=null;
        subdocId:=null;
        subdocMovgestTsId:=null;
		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_t_subdoc].';
--        raise notice 'strMessagio=%',strMessaggio;
		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );

		-- siac_t_subdoc
        insert into siac_t_subdoc
        (
        	subdoc_numero,
			subdoc_desc,
			subdoc_importo,
--		    subdoc_nreg_iva,
	        subdoc_data_scadenza,
	        subdoc_convalida_manuale,
	        subdoc_importo_da_dedurre, -- 05.06.2019 SIAC-6893
--	        subdoc_splitreverse_importo,
--	        subdoc_pagato_cec,
--	        subdoc_data_pagamento_cec,
--	        contotes_id INTEGER,
--	        dist_id INTEGER,
--	        comm_tipo_id INTEGER,
	        doc_id,
	        subdoc_tipo_id,
--	        notetes_id INTEGER,
	        validita_inizio,
			ente_proprietario_id,
		    login_operazione,
	        login_creazione,
            login_modifica
        )
        values
        (
        	dnumQuote+1,
            upper('Voce '||pagoPaFlussoQuoteRec.pagopa_voce_code||'/'||pagoPaFlussoQuoteRec.pagopa_sottovoce_code||' '||
            substring(coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,' ' ),1,30)||
            pagoPaFlussoQuoteRec.pagopa_flusso_id||' PSP '||pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente||
            ' Prov. '||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio::varchar||'/'||
            pagoPaFlussoQuoteRec.pagopa_num_provvisorio),
            pagoPaFlussoQuoteRec.pagopa_sottovoce_importo,
            dataElaborazione,
            'M', --- 13.12.2018 Sofia siac-6602
            0,   --- 05.06.2019 SIAC-6893
  			docId,
            subDocTipoId,
            clock_timestamp(),
            enteProprietarioId,
            loginOperazione,
            loginOperazione,
            loginOperazione
        )
        returning subdoc_id into subDocId;
--        raise notice 'subdocId=%',subdocId;
        if subDocId is null then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;

		-- siac_r_subdoc_attr
		-- flagAvviso
		-- flagEsproprio
		-- flagOrdinativoManuale
		-- flagOrdinativoSingolo
		-- flagRilevanteIVA
        codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr vari].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            boolean,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               'N',
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code in
        (
         FL_AVVISO_ATTR,
	     FL_ESPROPRIO_ATTR,
	     FL_ORD_MANUALE_ATTR,
		 FL_ORD_SINGOLO_ATTR,
	     FL_RIL_IVA_ATTR
        );
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if coalesce(codResult,0)=0 then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;

        end if;

		-- causaleOrdinativo
        /*codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr='||CAUS_ORDIN_ATTR||'].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            testo,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               upper('Regolarizzazione incasso voce '||pagoPaFlussoQuoteRec.pagopa_voce_code||'/'||pagoPaFlussoQuoteRec.pagopa_sottovoce_code||' '||
	            substring(coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,' '),1,30)||
    	        ' Prov. '||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio::varchar||'/'||
        	    pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' '),
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code=CAUS_ORDIN_ATTR
        returning subdoc_attr_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;*/

		-- dataEsecuzionePagamento
    	/*codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr='||DATA_ESEC_PAG_ATTR||'].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            testo,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               null,
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code=DATA_ESEC_PAG_ATTR
        returning subdoc_attr_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;*/

  	    -- controllo sfondamento e adeguamento accertamento
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||'. Verifica esistenza accertamento.';

		codResult:=null;
        dispAccertamento:=null;
        movgestTsId:=null;
        select ts.movgest_ts_id into movgestTsId
        from siac_t_movgest mov, siac_t_movgest_ts ts,
             siac_r_movgest_ts_stato rs
        where mov.bil_id=bilancioId
        and   mov.movgest_tipo_id=movgestTipoId
        and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
        and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
        and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=movgestTsTipoId
        and   rs.movgest_ts_id=ts.movgest_ts_id
        and   rs.movgest_stato_id=movgestStatoId
        and   rs.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
        and   ts.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
        and   mov.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())));

        if movgestTsId is not null then
       		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||'. Verifica dispon. accertamento.';

	        select * into dispAccertamento
            from fnc_siac_disponibilitaincassaremovgest (movgestTsId) disponibilita;
--		    raise notice 'dispAccertamento=%',dispAccertamento;
            if dispAccertamento is not null then
            	if dispAccertamento-pagoPaFlussoQuoteRec.pagopa_sottovoce_importo<0 then
                     -- 11.06.2019 SIAC-6720 - inserimento movimento di modifica acc automatico
		      		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                         ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
      					 ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento mov. modifica. Calcolo numero.';


                    numModifica:=null;
                    codResult:=null;
                    select coalesce(max(query.mod_num),0) into numModifica
                    from
                    (
					select  modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_t_movgest_ts_det_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    union
					select modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_r_movgest_ts_sog_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    union
					select modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_r_movgest_ts_sogclasse_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    ) query;

                    if numModifica is null then
                     numModifica:=0;
                    end if;

                    strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                         ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
      					 ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento mov. modifica.';
                    attoAmmId:=null;
                    select ratto.attoamm_id into attoAmmId
                    from siac_r_movgest_ts_atto_amm ratto
                    where ratto.movgest_ts_id=movgestTsId
                    and   ratto.data_cancellazione is null
                    and   ratto.validita_fine is null;
					if attoAmmId is null then
                    	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in lettura atto amministrativo.';
                    end if;

                    if codResult is null and modificaTipoId is null then
                    	select tipo.mod_tipo_id into modificaTipoId
                        from siac_d_modifica_tipo tipo
                        where tipo.ente_proprietario_id=enteProprietarioId
                        and   tipo.mod_tipo_code='ALT';
                        if modificaTipoId is null then
                        	codResult:=-1;
	                        strMessaggio:=strMessaggio||' Errore in lettura modifica tipo.';
                        end if;
                    end if;

                    if codResult is null then
                      modifId:=null;
                      insert into siac_t_modifica
                      (
                          mod_num,
                          mod_desc,
                          mod_data,
                          mod_tipo_id,
                          attoamm_id,
                          login_operazione,
                          validita_inizio,
                          ente_proprietario_id
                      )
                      values
                      (
                          numModifica+1,
                          'Modifica automatica per predisposizione di incasso',
                          dataElaborazione,
                          modificaTipoId,
                          attoAmmId,
                          loginOperazione||'@ELAB_PAGOPA-'||filePagoPaElabId::varchar, -- 27.02.2020 Sofia jira SIAC-7449
                          clock_timestamp(),
                          enteProprietarioId
                      )
                      returning mod_id into modifId;
                      if modifId is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_t_modifica.';
                      end if;
					end if;

                    if codResult is null and modifStatoId is null then
	                    select stato.mod_stato_id into modifStatoId
                        from siac_d_modifica_stato stato
                        where stato.ente_proprietario_id=enteProprietarioId
                        and   stato.mod_stato_code='V';
                        if modifStatoId is null then
                        	codResult:=-1;
	                        strMessaggio:=strMessaggio||' Errore in lettura stato modifica.';
                        end if;
                    end if;
                    if codResult is null then
                      modStatoRId:=null;
                      insert into siac_r_modifica_stato
                      (
                          mod_id,
                          mod_stato_id,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      values
                      (
                          modifId,
                          modifStatoId,
                          clock_timestamp(),
                          loginOperazione||'@ELAB_PAGOPA'||filePagoPaElabId::varchar, -- 27.02.2020 Sofia jira SIAC-7449
                          enteProprietarioId
                      )
                      returning mod_stato_r_id into modStatoRId;
                      if modStatoRId is  null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_r_modifica_stato.';
                      end if;
                    end if;
                    if codResult is null then
                      insert into siac_t_movgest_ts_det_mod
                      (
                          mod_stato_r_id,
                          movgest_ts_det_id,
                          movgest_ts_id,
                          movgest_ts_det_tipo_id,
                          movgest_ts_det_importo,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      select modStatoRId,
                             det.movgest_ts_det_id,
                             det.movgest_ts_id,
                             det.movgest_ts_det_tipo_id,
                             pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento,
                             clock_timestamp(),
                             loginOperazione||'@ELAB_PAGOPA'||filePagoPaElabId::varchar, -- 27.02.2020 Sofia jira SIAC-7449
                             det.ente_proprietario_id
                      from siac_t_movgest_ts_det det
                      where det.movgest_ts_id=movgestTsId
                      and   det.movgest_ts_det_tipo_id=movgestTsDetTipoId
                      returning movgest_ts_det_mod_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_t_movgest_ts_det_mod.';
                      else
                        codResult:=null;
                      end if;
                	end if;

                    if codResult is null then
                      strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                           ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                           ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                           ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                           ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
                           ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'.';
                      update siac_t_movgest_ts_det det
                      set    movgest_ts_det_importo=det.movgest_ts_det_importo+
                                                    (pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento),
                             data_modifica=clock_timestamp(),
                             --login_operazione=det.login_operazione||'-'||loginOperazione -- 27.02.2020 Sofia jira SIAC-7449
                             login_operazione=loginOperazione||'@ELAB_PAGOPA-'||filePagoPaElabId::varchar -- 27.02.2020 Sofia jira SIAC-7449
                      where det.movgest_ts_id=movgestTsId
                      and   det.movgest_ts_det_tipo_id=movgestTsDetTipoId
                      and   det.data_cancellazione is null
                      and   date_trunc('DAY',now())>=date_trunc('DAY',det.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(det.validita_fine,date_trunc('DAY',now())))
                      returning det.movgest_ts_det_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in aggiornamento siac_t_movgest_ts_det.';
                      else codResult:=null;
                      end if;
                    end if;

                    if codResult is null then
                      strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                           ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                           ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                           ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                           ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
                           ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento pagopa_t_modifica_elab.';
                      insert into pagopa_t_modifica_elab
                      (
                          pagopa_modifica_elab_importo,
                          pagopa_elab_id,
                          subdoc_id,
                          mod_id,
                          movgest_ts_id,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      values
                      (
                          pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento,
                          filePagoPaElabId,
                          subDocId,
                          modifId,
                          movgestTsId,
                          clock_timestamp(),
                          loginOperazione||'@ELAB_PAGOPA-'||filePagoPaElabId::varchar, -- 27.02.2020 Sofia jira SIAC-7449
                          enteProprietarioId
                      )
                      returning pagopa_modifica_elab_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento pagopa_t_modifica_elab.';
                      else codResult:=null;
                      end if;
                    end if;

                    if codResult is not null then
                        --bErrore:=true;
                        pagoPaCodeErr:=PAGOPA_ERR_31;
                    	strMessaggioBck:=strMessaggio||' PAGOPA_ERR_31='||PAGOPA_ERR_31||' .';
--                        raise notice '%', strMessaggioBck;
                        strMessaggio:=' ';
                        raise exception '%', strMessaggioBck;
                    end if;
                     -- 11.06.2019 SIAC-6720 - inserimento movimento di modifica acc automatico
                end if;
            else
            	bErrore:=true;
           		pagoPaCodeErr:=PAGOPA_ERR_31;
                strMessaggio:=strMessaggio||' Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
            						  ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||' errore.';
	            continue;
            end if;
        else
            bErrore:=true;
            pagoPaCodeErr:=PAGOPA_ERR_31;
            strMessaggio:=strMessaggio||' Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
            						  ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||' non esistente.';
            continue;
        end if;


		codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' movgest_ts_id='||movgestTsId::varchar||' [siac_r_subdoc_movgest_ts].';
		-- siac_r_subdoc_movgest_ts
        insert into siac_r_subdoc_movgest_ts
        (
        	subdoc_id,
            movgest_ts_id,
            validita_inizio,
            login_Operazione,
            ente_proprietario_id
        )
        values
        (
               subdocId,
               movgestTsId,
               clock_timestamp(),
               loginOperazione,
               enteProprietarioId
        )
		returning subdoc_movgest_ts_id into codResult;
		if codResult is null then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;
		subdocMovgestTsId:=  codResult;
--        raise notice 'subdocMovgestTsId=%',subdocMovgestTsId;

        -- siac-6720 30.05.2019 - per i corrispettivi non collegare atto_amm
--        if pagoPaFlussoRec.pagopa_doc_tipo_code!=DOC_TIPO_COR  then -- Jira SIAC-7089 14.10.2019 Sofia
        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_IPA  then    -- Jira SIAC-7089 14.10.2019 Sofia


          -- siac_r_subdoc_atto_amm
          codResult:=null;
          strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                           ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                           ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                           ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_atto_amm].';
          insert into siac_r_subdoc_atto_amm
          (
              subdoc_id,
              attoamm_id,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
          )
          select subdocId,
                 atto.attoamm_id,
                 clock_timestamp(),
                 loginOperazione,
                 atto.ente_proprietario_id
          from siac_r_subdoc_movgest_ts rts, siac_r_movgest_ts_atto_amm atto
          where rts.subdoc_movgest_ts_id=subdocMovgestTsId
          and   atto.movgest_ts_id=rts.movgest_ts_id
          and   atto.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',atto.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(atto.validita_fine,date_trunc('DAY',now())))
          returning subdoc_atto_amm_id into codResult;
          if codResult is null then
              bErrore:=true;
              strMessaggio:=strMessaggio||' Errore in inserimento.';
              continue;
          end if;
        end if;

		-- controllo esistenza e sfondamento disp. provvisorio
        codResult:=null;
        provvisorioId:=null;
        dispProvvisorioCassa:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa].';
        select prov.provc_id into provvisorioId
        from siac_t_prov_cassa prov
        where prov.provc_tipo_id=provvisorioTipoId
        and   prov.provc_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
        and   prov.provc_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
        and   prov.provc_data_annullamento is null
        and   prov.provc_data_regolarizzazione is null
        and   prov.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',prov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(prov.validita_fine,date_trunc('DAY',now())));
--        raise notice 'provvisorioId=%',provvisorioId;

        if provvisorioId is not null then
        	select 1 into codResult
            from siac_r_ordinativo_prov_cassa r
            where r.provc_id=provvisorioId
            and   r.data_cancellazione is null
            and   r.validita_fine is null;
            if codResult is null then
            	select 1 into codResult
	            from siac_r_subdoc_prov_cassa r
    	        where r.provc_id=provvisorioId
                and   r.login_operazione not like '%@PAGOPA-'||filePagoPaElabId::varchar||'%'
        	    and   r.data_cancellazione is null
            	and   r.validita_fine is null;
            end if;
            if codResult is not null then
            	pagoPaCodeErr:=PAGOPA_ERR_39;
	            bErrore:=true;
                strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' regolarizzato.';
       		    continue;
            end if;
        end if;
        if provvisorioId is not null then
           strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa] provc_id='
                         ||provvisorioId::VARCHAR||'. Verifica disponibilita''.';
			select * into dispProvvisorioCassa
            from fnc_siac_daregolarizzareprovvisorio(provvisorioId) disponibilita;
--            raise notice 'dispProvvisorioCassa=%',dispProvvisorioCassa;
--            raise notice 'pagoPaFlussoQuoteRec.pagopa_sottovoce_importo=%',pagoPaFlussoQuoteRec.pagopa_sottovoce_importo;

            if dispProvvisorioCassa is not null then
            	if dispProvvisorioCassa-pagoPaFlussoQuoteRec.pagopa_sottovoce_importo<0 then
                	pagoPaCodeErr:=PAGOPA_ERR_33;
		            bErrore:=true;
                    strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' disp. insufficiente.';
        		    continue;
                end if;
            else
            	pagoPaCodeErr:=PAGOPA_ERR_32;
	            bErrore:=true;
               strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' Errore.';

    	        continue;
            end if;
        else
        	pagoPaCodeErr:=PAGOPA_ERR_32;
            bErrore:=true;
            strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' non esistente.';
            continue;
        end if;


		codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa] provc_id='
                         ||provvisorioId::varchar||'.';
		-- siac_r_subdoc_prov_cassa
        insert into siac_r_subdoc_prov_cassa
        (
        	subdoc_id,
            provc_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        VALUES
        (
               subdocId,
               provvisorioId,
               clock_timestamp(),
               loginOperazione||'@PAGOPA-'||filePagoPaElabId::varchar,
               enteProprietarioId
        )
        returning subdoc_provc_id into codResult;
---        raise notice 'subdoc_provc_id=%',codResult;

        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end  if;

		codResult:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento pagopa_t_riconciliazione_doc per subdoc_id.';
        -- aggiornare pagopa_t_riconciliazione_doc
        update pagopa_t_riconciliazione_doc docUPD
        set    pagopa_ric_doc_subdoc_id=subdocId,
		       pagopa_ric_doc_stato_elab='S',
               pagopa_ric_errore_id=null,
               pagopa_ric_doc_movgest_ts_id=movgestTsId,
               pagopa_ric_doc_provc_id=provvisorioId,
               data_modifica=clock_timestamp(),
--               login_operazione=docUPD.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
               login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

        from
        (
         with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
			and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and    coalesce(doc.pagopa_ric_doc_iuv,'')=coalesce(pagoPaFlussoRec.pagopa_doc_iuv,'') -- 06.02.2020 Sofia siac-7375
            and    coalesce(doc.pagopa_ric_doc_data_operazione,'2020-01-01'::timestamp)=
                   coalesce(pagoPaFlussoRec.pagopa_doc_data_operazione,'2020-01-01'::timestamp) -- 06.02.2020 Sofia siac-7375
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
            and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
            and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
                   coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
            and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
            and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
            and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
            and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
            and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
    		and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab='N'
            and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     	    and    doc.pagopa_ric_doc_subdoc_id is null
     		and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          -- 23.07.2019 siac-6963
          accertamenti_sog as
          (
           with
           accertamenti as
           (
              select ts.movgest_ts_id
              from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
              where mov.bil_id=bilancioId
              and   mov.movgest_tipo_id=movgestTipoId
              and   ts.movgest_id=mov.movgest_id
              and   ts.movgest_ts_tipo_id=movgestTsTipoId
              and   rs.movgest_ts_id=ts.movgest_ts_id
              and   rs.movgest_stato_id=movgestStatoId
              and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
              and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
              and   mov.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
              and   ts.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
              and   rs.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
              select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
              from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
              where sog.ente_proprietario_id=enteProprietarioId
              and   rsog.soggetto_id=sog.soggetto_id
              and   sog.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
              and   rsog.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))

           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id
          from --pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
--               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog ,-- 22.07.2019 siac-6963
               pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code)
        ) QUERY
        where docUPD.ente_proprietario_id=enteProprietarioId
        and   docUPD.pagopa_ric_doc_stato_elab='N'
        and   docUPD.pagopa_ric_doc_subdoc_id is null
        and   docUPD.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
        and   docUPD.pagopa_ric_doc_id=QUERY.pagopa_ric_doc_id
        and   QUERY.pagopa_soggetto_id=pagoPaFlussoQuoteRec.pagopa_soggetto_id
        and   docUPD.data_cancellazione is null
        and   docUPD.validita_fine is null;
        GET DIAGNOSTICS codResult = ROW_COUNT;
--		raise notice 'Aggiornati pagopa_t_riconciliazione_doc=%',codResult;
		if coalesce(codResult,0)=0 then
            raise exception ' Errore in aggiornamento.';
        end if;

		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );


        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento pagopa_t_riconciliazione per subdoc_id.';
		codResult:=null;
        -- aggiornare pagopa_t_riconciliazione
        update pagopa_t_riconciliazione ric
        set    pagopa_ric_flusso_stato_elab='S',
			   pagopa_ric_errore_id=null,
               data_modifica=clock_timestamp(),
--               login_operazione=ric.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
               login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

		from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
        where flusso.pagopa_elab_id=filePagoPaElabId
        and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
        and   doc.pagopa_ric_doc_subdoc_id=subdocId
        and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
        and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
        and   ric.pagopa_ric_id=doc.pagopa_ric_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
--   		raise notice 'Aggiornati pagopa_t_riconciliazione=%',codResult;

--        returning ric.pagopa_ric_id into codResult;
		if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in aggiornamento.';
            strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
            insert into pagopa_t_elaborazione_log
            (
            pagopa_elab_id,
            pagopa_elab_file_id,
            pagopa_elab_log_operazione,
            ente_proprietario_id,
            login_operazione,
            data_creazione
            )
            values
            (
            filePagoPaElabId,
            null,
            strMessaggioLog,
            enteProprietarioId,
            loginOperazione,
            clock_timestamp()
            );


            continue;
        end if;

		dnumQuote:=dnumQuote+1;
        dDocImporto:=dDocImporto+pagoPaFlussoQuoteRec.pagopa_sottovoce_importo;

       end loop;
		raise notice 'dnumQuote %',dnumQuote;
	   if dnumQuote>0 and bErrore=false then
        -- siac_t_subdoc_num
        codResult:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento numero quote [siac_t_subdoc_num].';
 	    insert into siac_t_subdoc_num
        (
         doc_id,
         subdoc_numero,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
        )
        values
        (
         docId,
         dnumQuote,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
        )
        returning subdoc_num_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
        end if;

		if bErrore =false then
        	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento importo documento.';
        	update siac_t_doc doc
            set    doc_importo=dDocImporto
            where doc.doc_id=docId
            returning doc.doc_id into codResult;
            if codResult is null then
            	bErrore:=true;
            	strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
            end if;
        end if;
       else
        -- non ha inserito quote
        if bErrore=false  then
        	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote non effettuato.';
            bErrore:=true;
        end if;
       end if;



	   if bErrore=true then

    	 strMessaggioBck:=strMessaggio;
         strMessaggio:='Cancellazione dati documento inseriti.'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
--                  raise notice 'pagoPaCodeErr=%',pagoPaCodeErr;

		 if pagoPaCodeErr is null then
         	pagoPaCodeErr:=PAGOPA_ERR_30;
         end if;

         -- pulizia delle tabella pagopa_t_riconciliazione

         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione S].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
  		 update pagopa_t_riconciliazione ric
         set    pagopa_ric_flusso_stato_elab='X',
  			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                data_modifica=clock_timestamp(),
--                login_operazione=split_part(ric.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
                login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

   	     from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc,
              pagopa_d_riconciliazione_errore errore, siac_t_subdoc sub
         where flusso.pagopa_elab_id=filePagoPaElabId
         and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   sub.doc_id=docId
         and   doc.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
         and   ric.pagopa_ric_id=doc.pagopa_ric_id
         and   exists
         (
         select 1
         from pagopa_t_riconciliazione_doc doc1
         where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc1.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   doc1.pagopa_ric_id=ric.pagopa_ric_id
         and   doc1.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   doc1.validita_fine is null
         and   doc1.data_cancellazione is null
         )
         and   errore.ente_proprietario_id=flusso.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   flusso.data_cancellazione is null
         and   flusso.validita_fine is null
         and   ric.data_cancellazione is null
         and   ric.validita_fine is null
         and   sub.data_cancellazione is null
         and   sub.validita_fine is null;

		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
           pagopa_elab_id,
           pagopa_elab_file_id,
           pagopa_elab_log_operazione,
           ente_proprietario_id,
           login_operazione,
           data_creazione
         )
         values
         (
           filePagoPaElabId,
           null,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
         );

         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione N].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_riconciliazione  docUPD
         set    pagopa_ric_flusso_stato_elab='X',
  			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                data_modifica=clock_timestamp(),
                --login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
                login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar      -- 04.02.2020 Sofia SIAC-7375
         from
         (
		  with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef,
                    doc.pagopa_ric_id
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
            and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and   coalesce(doc.pagopa_ric_doc_iuv,'')=coalesce(pagoPaFlussoRec.pagopa_doc_iuv,'') -- 06.02.2020 Sofia siac-7375
            and   coalesce(doc.pagopa_ric_doc_data_operazione,'2020-01-01'::timestamp)=
                  coalesce(pagoPaFlussoRec.pagopa_doc_data_operazione,'2020-01-01'::timestamp) -- 06.02.2020 Sofia siac-7375
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
        --    and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
        --    and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
        --           coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
        --    and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
        --    and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
        --    and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
        --    and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
        --   and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
        --	 and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab = 'N'
            and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
			and    doc.pagopa_ric_doc_subdoc_id is null
     	/*	and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )*/
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          -- 23.07.2019 siac-6963
          accertamenti_sog AS
          (
           with
           accertamenti as
           (
                select ts.movgest_ts_id
                from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
                where mov.bil_id=bilancioId
                and   mov.movgest_tipo_id=movgestTipoId
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_tipo_id=movgestTsTipoId
                and   rs.movgest_ts_id=ts.movgest_ts_id
                and   rs.movgest_stato_id=movgestStatoId
            --    and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
             --   and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
                and   mov.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
                and   ts.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
                and   rs.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
	           select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
    		   from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
	           where sog.ente_proprietario_id=enteProprietarioId
               and   rsog.soggetto_id=sog.soggetto_id
	           and   sog.data_cancellazione is null
	           and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
               and   rsog.data_cancellazione is null
               and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
--                accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog -- 22.07.2019 siac-6963
         ) query,pagopa_d_riconciliazione_errore errore
         where docUPD.ente_proprietario_id=enteProprietarioId
--         and   docUPD.pagopa_ric_flusso_stato_elab='N'
         and   docUPD.pagopa_ric_id=QUERY.pagopa_ric_id
         and   QUERY.pagopa_soggetto_id=pagoPaFlussoRec.pagopa_soggetto_id
         and   errore.ente_proprietario_id=docUPD.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   docUPD.data_cancellazione is null
         and   docUPD.validita_fine is null;

         strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );




         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione_doc S].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;

         update pagopa_t_riconciliazione_doc doc
         set    pagopa_ric_doc_stato_elab='X',
			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                pagopa_ric_doc_subdoc_id=null,
                pagopa_ric_doc_movgest_ts_id=null,
                pagopa_ric_doc_provc_id=null,
                data_modifica=clock_timestamp(),
--                login_operazione=split_part(doc.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
                login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar             -- 04.02.2020 Sofia SIAC-7375
         from pagopa_t_elaborazione_flusso flusso,
              pagopa_d_riconciliazione_errore errore, siac_t_subdoc sub
         where flusso.pagopa_elab_id=filePagoPaElabId
         and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
         and   doc.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   sub.doc_id=docId
         and   doc.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
         and   errore.ente_proprietario_id=flusso.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   flusso.data_cancellazione is null
         and   flusso.validita_fine is null
         and   sub.data_cancellazione is null
         and   sub.validita_fine is null;

		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );

	     strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione_doc N].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_riconciliazione_doc  docUPD
         set    pagopa_ric_doc_stato_elab='X',
			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                pagopa_ric_doc_subdoc_id=null,
                pagopa_ric_doc_movgest_ts_id=null,
                pagopa_ric_doc_provc_id=null,
                data_modifica=clock_timestamp(),
--                login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
                login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar          -- 04.02.2020 Sofia SIAC-7375
         from
         (
		  with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef,
                    doc.pagopa_ric_id
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
            and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and    coalesce(doc.pagopa_ric_doc_iuv,'')=coalesce(pagoPaFlussoRec.pagopa_doc_iuv,'') -- 06.02.2020 Sofia siac-7375
            and    coalesce(doc.pagopa_ric_doc_data_operazione,'2020-01-01'::timestamp)=
                   coalesce(pagoPaFlussoRec.pagopa_doc_data_operazione,'2020-01-01'::timestamp) -- 06.02.2020 Sofia siac-7375
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
--            and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
--            and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
--                   coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
--            and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
--            and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
--            and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
--            and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
--            and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
--    		and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab = 'N'
			and    doc.pagopa_ric_doc_subdoc_id is null
            and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
  /*   		and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )*/
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          -- 23.07.2019 siac-6963
          accertamenti_sog as
          (
           with
           accertamenti as
           (
            select ts.movgest_ts_id
            from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
            where mov.bil_id=bilancioID
            and   mov.movgest_tipo_id=movgestTipoId
            and   ts.movgest_id=mov.movgest_id
            and   ts.movgest_ts_tipo_id=movgestTsTipoId
            and   rs.movgest_ts_id=ts.movgest_ts_id
            and   rs.movgest_stato_id=movgestStatoId
--            and   rsog.movgest_ts_id=ts.movgest_ts_id -- 06.12.2019 Sofia jira SIAC-7251  -- errore in esecuzione
  --          and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
  --          and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and   mov.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
            and   ts.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
            and   rs.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
            select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
            from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
            where sog.ente_proprietario_id=enteProprietarioId
            and   rsog.soggetto_id=sog.soggetto_id
            and   sog.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
            and   rsog.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
---               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog -- 22.07.2019 siac-6963

         ) query,pagopa_d_riconciliazione_errore errore
         where docUPD.ente_proprietario_id=enteProprietarioId
--         and   docUPD.pagopa_ric_doc_stato_elab='N'
         and   docUPD.pagopa_ric_doc_id=QUERY.pagopa_ric_doc_id
         and   QUERY.pagopa_soggetto_id=pagoPaFlussoRec.pagopa_soggetto_id
         and   errore.ente_proprietario_id=docUPD.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   docUPD.data_cancellazione is null
         and   docUPD.validita_fine is null;

  		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );

         -- 11.06.2019 SIAC-6720
         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_modifica_elab].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_modifica_elab r
         set    pagopa_modifica_elab_note='DOCUMENTO CANCELLATO IN ESEGUI PER pagoPaCodeErr='||pagoPaCodeErr||' ',
                subdoc_id=null
         from 	siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;

         strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_movgest_ts].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;

         delete from siac_r_subdoc_movgest_ts r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;

		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_attr].'||strMessaggioBck;
         delete from siac_r_subdoc_attr r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_atto_amm].'||strMessaggioBck;
         delete from siac_r_subdoc_atto_amm r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_prov_cassa].'||strMessaggioBck;
         delete from siac_r_subdoc_prov_cassa r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_subdoc].'||strMessaggioBck;
         delete from siac_t_subdoc doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_sog].'||strMessaggioBck;
         delete from siac_r_doc_sog doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_stato].'||strMessaggioBck;
         delete from siac_r_doc_stato doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_attr].'||strMessaggioBck;
         delete from siac_r_doc_attr doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_class].'||strMessaggioBck;
         delete from siac_r_doc_class doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_registrounico_doc].'||strMessaggioBck;
         delete from siac_t_registrounico_doc doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_subdoc_num].'||strMessaggioBck;
         delete from siac_t_subdoc_num doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_doc].'||strMessaggioBck;
         delete from siac_t_doc doc where doc.doc_id=docId;

		 strMessaggioLog:=strMessaggioFinale||strMessaggio||' - Continue fnc_pagopa_t_elaborazione_riconc_esegui.';
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );

       end if;


  end loop;


  strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - Fine ciclo caricamento documenti - '||strMessaggioFinale;
--  raise notice 'strMessaggioLog=%',strMessaggioLog;
  insert into pagopa_t_elaborazione_log
  (
   pagopa_elab_id,
   pagopa_elab_file_id,
   pagopa_elab_log_operazione,
   ente_proprietario_id,
   login_operazione,
   data_creazione
  )
  values
  (
   filePagoPaElabId,
   null,
   strMessaggioLog,
   enteProprietarioId,
   loginOperazione,
   clock_timestamp()
  );

  -- richiamare function per gestire anomalie e errori su provvisori e flussi in generale
  -- su elaborazione
  -- controllare ogni flusso/provvisorio
  strMessaggio:='Chiamata fnc.';
  select * into  fncRec
  from fnc_pagopa_t_elaborazione_riconc_esegui_clean
  (
    filePagoPaElabId,
    annoBilancioElab,
    enteProprietarioId,
    loginOperazione,
    dataElaborazione
  );
  if fncRec.codiceRisultato=0 then
    if fncRec.pagopaBckSubdoc=true then
    	pagoPaCodeErr:=PAGOPA_ERR_36;
    end if;
  else
  	raise exception '%',fncRec.messaggiorisultato;
  end if;

  -- aggiornare siac_t_registrounico_doc_num
  codResult:=null;
  strMessaggio:='Aggiornamento numerazione su siac_t_registrounico_doc_num.';
  update siac_t_registrounico_doc_num num
  set    rudoc_registrazione_numero= coalesce(QUERY.rudoc_registrazione_numero,0),
         data_modifica=clock_timestamp()--, 26.08.2020 Sofia Jira SIAC-7747
         -- login_operazione=num.login_operazione||'-'||loginOperazione 26.08.2020 Sofia Jira SIAC-7747
  from
  (
   select max(doc.rudoc_registrazione_numero::integer) rudoc_registrazione_numero
   from  siac_t_registrounico_doc doc
   where doc.ente_proprietario_id=enteProprietarioId
   and   doc.rudoc_registrazione_anno::integer=annoBilancio
   and   doc.data_cancellazione is null
   and   date_trunc('DAY',now())>=date_trunc('DAY',doc.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(doc.validita_fine,date_trunc('DAY',now())))
  ) QUERY
  where num.ente_proprietario_id=enteProprietarioId
  and   num.rudoc_registrazione_anno=annoBilancio
  and   num.data_cancellazione is null
  and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())));
 -- returning num.rudoc_num_id into codResult;
  --if codResult is null then
  --	raise exception 'Errore in fase di aggiornamento.';
  --end if;



  -- chiusura della elaborazione, siac_t_file per errore in generazione per aggiornare pagopa_ric_errore_id
  if coalesce(pagoPaCodeErr,' ') in (PAGOPA_ERR_30,PAGOPA_ERR_31,PAGOPA_ERR_32,PAGOPA_ERR_33,PAGOPA_ERR_36,PAGOPA_ERR_39) then
     strMessaggio:=' Aggiornamento pagopa_t_elaborazione.';
	 update pagopa_t_elaborazione elab
     set    data_modifica=clock_timestamp(),
            pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
            pagopa_elab_errore_id=err.pagopa_ric_errore_id,
            pagopa_elab_note=
            substr(
             (
              'AGGIORNAMENTO PER ERR.='||(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )::varchar||'.'
              ||elab.pagopa_elab_note
             ),1,1500) -- 09.10.2019 Sofia
     from  pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
     where elab.pagopa_elab_id=filePagoPaElabId
     and   statonew.ente_proprietario_id=elab.ente_proprietario_id
     and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_ER_ST
     and   err.ente_proprietario_id=statonew.ente_proprietario_id
     and   err.pagopa_ric_errore_code=(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )
     and   elab.data_cancellazione is null
     and   elab.validita_fine is null;



    strMessaggio:=' Aggiornamento siac_t_file_pagopa.';
    update siac_t_file_pagopa file
    set    data_modifica=clock_timestamp(),
           file_pagopa_stato_id=stato.file_pagopa_stato_id,
           file_pagopa_errore_id=err.pagopa_ric_errore_id,
           file_pagopa_note=
                  substr(
                    ('AGGIORNAMENTO PER ERR.='||(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )::varchar||'.'
                     ||file.file_pagopa_note
                    ),1,1500), -- 09.10.2019 Sofia
           login_operazione=substr(loginOperazione||'-'||file.login_operazione,1,200) -- 09.10.2019 Sofia
    from  pagopa_r_elaborazione_file r,
          siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
    where r.pagopa_elab_id=filePagoPaElabId
    and   file.file_pagopa_id=r.file_pagopa_id
    and   stato.ente_proprietario_id=file.ente_proprietario_id
    and   err.ente_proprietario_id=stato.ente_proprietario_id
    and   err.pagopa_ric_errore_code=(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

  end if;

  strMessaggio:='Verifica dettaglio elaborati per chiusura pagopa_t_elaborazione.';
--  raise notice 'strMessaggio=%',strMessaggio;

  codResult:=null;
  select 1 into codResult
  from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
  where flusso.pagopa_elab_id=filePagoPaElabId
  and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
  and   doc.pagopa_ric_doc_subdoc_id is not null
  and   doc.pagopa_ric_doc_stato_elab='S'
  and   flusso.data_cancellazione is null
  and   flusso.validita_fine is null
  and   doc.data_cancellazione is null
  and   doc.validita_fine is null;
  -- ELABORATO_KO_ST ELABORATO_OK_SE
  if codResult is not null then
  	  codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is null
      and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
      and   doc.pagopa_ric_doc_stato_elab in ('X','E','N')
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null;
      -- se ci sono S e X,E,N KO
      if codResult is not null then
            pagoPaCodeErr:=ELABORATO_KO_ST;
      -- se si sono solo S OK
      else  pagoPaCodeErr:=ELABORATO_OK_ST;
      end if;
  else -- se non esiste neanche un S allora elaborazione errata o scartata
	  codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is null
      and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
      and   doc.pagopa_ric_doc_stato_elab='X'
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null;
      if codResult is not null then
            pagoPaCodeErr:=ELABORATO_SCARTATO_ST;
      else  pagoPaCodeErr:=ELABORATO_ERRATO_ST;
      end if;
  end if;

  strMessaggio:='Aggiornamento pagopa_t_elaborazione in stato='||pagoPaCodeErr||'.';

  --  strMessaggioFinale:='CHIUSURA - '||upper(strMessaggioFinale||' '||strMessaggio); -- 09.10.2019 Sofia
  strMessaggioFinale:='CHIUSURA - '||substr(upper(strMessaggio||' '||strMessaggioFinale),1,1450); -- 09.10.2019 Sofia

  update pagopa_t_elaborazione elab
  set    data_modifica=clock_timestamp(),
  		 validita_fine=clock_timestamp(),
         pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
         pagopa_elab_note=strMessaggioFinale
  from  pagopa_d_elaborazione_stato statonew
  where elab.pagopa_elab_id=filePagoPaElabId
  and   statonew.ente_proprietario_id=elab.ente_proprietario_id
  and   statonew.pagopa_elab_stato_code=pagoPaCodeErr
  and   elab.data_cancellazione is null
  and   elab.validita_fine is null;

  strMessaggio:='Verifica dettaglio elaborati per chiusura siac_t_file_pagopa.';
  for elabRec in
  (
  select r.file_pagopa_id
  from pagopa_r_elaborazione_file r
  where r.pagopa_elab_id=filePagoPaElabId
  and   r.data_cancellazione is null
  and   r.validita_fine is null
  order by r.file_pagopa_id
  )
  loop

    -- chiusura per siac_t_file_pagopa
    -- capire se ho chiuso per bene pagopa_t_riconciliazione
    -- se esistono S Ok o in corso
    --    se esistono N non elaborati  IN_CORSO no chiusura
    --    se esistono X scartati IN_CORSO_SC no chiusura
    --    se esistono E errati   IN_CORSO_ER no chiusura
    --    se non esistono!=S FINE ELABORATO_Ok con chiusura
    -- se non esistono S, in corso
    --    se esistono N IN_CORSO no chiusura
    --    se esistono X scartati IN_CORSO_SC non chiusura
    --    se esistono E errati IN_CORSO_ER non chiusura
    strMessaggio:='Verifica dettaglio elaborati per chiusura siac_t_file_pagopa file_pagopa_id='||elabRec.file_pagopa_id::varchar||'.';
    codResult:=null;
    pagoPaCodeErr:=null;
    select 1 into codResult
    from  pagopa_t_riconciliazione ric
    where  ric.file_pagopa_id=elabRec.file_pagopa_id
    and   ric.pagopa_ric_flusso_stato_elab='S'
    and   ric.data_cancellazione is null
    and   ric.validita_fine is null;

    if codResult is not null then
      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='N'
  --    and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='X'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_SC_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='E'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ER_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab!='S'
    --  and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is null then
          pagoPaCodeErr:=ELABORATO_OK_ST;
      end if;

    else
      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='N'
   --   and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='X'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_SC_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='E'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ER_ST;
      end if;

    end if;

    if pagoPaCodeErr is not null then
       strMessaggio:='Aggiornamento siac_t_file_pagopa in stato='||pagoPaCodeErr||'.';

--       strMessaggioFinale:='CHIUSURA - '||upper(strMessaggioFinale||' '||strMessaggio); -- 09.10.2019 Sofia
       strMessaggioFinale:='CHIUSURA - '||substr(upper(strMessaggio||' '||strMessaggioFinale),1,1450); -- 09.10.2019 Sofia

       update siac_t_file_pagopa file
       set    data_modifica=clock_timestamp(),
              validita_fine=(case when pagoPaCodeErr=ELABORATO_OK_ST then clock_timestamp() else null end),
              file_pagopa_stato_id=stato.file_pagopa_stato_id,
              file_pagopa_note=file.file_pagopa_note||upper(strMessaggioFinale),
--              login_operazione=file.login_operazione||'-'||loginOperazione
              login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

       from  siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
       where file.file_pagopa_id=elabRec.file_pagopa_id
       and   stato.ente_proprietario_id=file.ente_proprietario_id
       and   stato.file_pagopa_stato_code=pagoPaCodeErr;

    end if;

  end loop;

  messaggioRisultato:='OK VERIFICARE STATO ELAB. - '||upper(strMessaggioFinale);
-- raise notice 'messaggioRisultato=%',messaggioRisultato;
  return;


exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter function siac.fnc_pagopa_t_elaborazione_riconc_esegui
( integer, integer, integer , varchar , timestamp ,  
  out integer,
  out varchar) owner to siac;
  
-- 10.05.2021 Sofia Jira - SiAC-8167 - fine


-- SIAC-8179 - Maurizio - INIZIO

update siac_r_report_importi
set posizione_stampa = 2,
	data_modifica=now(),
    login_operazione=login_operazione||' - SIAC-8174'
where repimp_id in (select b.repimp_id
from siac_t_report a,
	siac_t_report_importi b,
    siac_r_report_importi c,
    siac_t_bil d,
    siac_t_periodo e
where a.rep_id=c.rep_id
and b.repimp_id=c.repimp_id
and b.bil_id=d.bil_id
and d.periodo_id=e.periodo_id   
and a.rep_codice='BILR014'
and b.repimp_codice='amm_rate_prest_prec'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL);

update siac_r_report_importi
set posizione_stampa = 3,
	data_modifica=now(),
    login_operazione=login_operazione||' - SIAC-8174'
where repimp_id in (select b.repimp_id
from siac_t_report a,
	siac_t_report_importi b,
    siac_r_report_importi c,
    siac_t_bil d,
    siac_t_periodo e
where a.rep_id=c.rep_id
and b.repimp_id=c.repimp_id
and b.bil_id=d.bil_id
and d.periodo_id=e.periodo_id  
and a.rep_codice='BILR014'
and b.repimp_codice='amm_rate_prest_att'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL);

update siac_r_report_importi
set posizione_stampa = 4,
	data_modifica=now(),
    login_operazione=login_operazione||' - SIAC-8174'
where repimp_id in (select b.repimp_id
from siac_t_report a,
	siac_t_report_importi b,
    siac_r_report_importi c,
    siac_t_bil d,
    siac_t_periodo e
where a.rep_id=c.rep_id
and b.repimp_id=c.repimp_id
and b.bil_id=d.bil_id
and d.periodo_id=e.periodo_id   
and a.rep_codice='BILR014'
and b.repimp_codice='amm_rate_pot_deb'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL);


update siac_r_report_importi
set posizione_stampa = 5,
	data_modifica=now(),
    login_operazione=login_operazione||' - SIAC-8174'
where repimp_id in (select b.repimp_id
from siac_t_report a,
	siac_t_report_importi b,
    siac_r_report_importi c,
    siac_t_bil d,
    siac_t_periodo e
where a.rep_id=c.rep_id
and b.repimp_id=c.repimp_id
and b.bil_id=d.bil_id
and d.periodo_id=e.periodo_id
and a.rep_codice='BILR014'
and b.repimp_codice='amm_rate_aut_legge'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL);


update siac_r_report_importi
set posizione_stampa = 6,
	data_modifica=now(),
    login_operazione=login_operazione||' - SIAC-8174'
where repimp_id in (select b.repimp_id
from siac_t_report a,
	siac_t_report_importi b,
    siac_r_report_importi c,
    siac_t_bil d,
    siac_t_periodo e
where a.rep_id=c.rep_id
and b.repimp_id=c.repimp_id
and b.bil_id=d.bil_id
and d.periodo_id=e.periodo_id  
and a.rep_codice='BILR014'
and b.repimp_codice='contr_erariali'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL);


update siac_r_report_importi
set posizione_stampa = 7,
	data_modifica=now(),
    login_operazione=login_operazione||' - SIAC-8174'
where repimp_id in (select b.repimp_id
from siac_t_report a,
	siac_t_report_importi b,
    siac_r_report_importi c,
    siac_t_bil d,
    siac_t_periodo e
where a.rep_id=c.rep_id
and b.repimp_id=c.repimp_id
and b.bil_id=d.bil_id
and d.periodo_id=e.periodo_id  
and a.rep_codice='BILR014'
and b.repimp_codice='amm_rate_debitii'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL);

update siac_r_report_importi
set posizione_stampa = 8,
	data_modifica=now(),
    login_operazione=login_operazione||' - SIAC-8174'
where repimp_id in (select b.repimp_id
from siac_t_report a,
	siac_t_report_importi b,
    siac_r_report_importi c,
    siac_t_bil d,
    siac_t_periodo e
where a.rep_id=c.rep_id
and b.repimp_id=c.repimp_id
and b.bil_id=d.bil_id
and d.periodo_id=e.periodo_id   
and a.rep_codice='BILR014'
and b.repimp_codice='deb_contratto_prec'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL);



update siac_r_report_importi
set posizione_stampa = 9,
	data_modifica=now(),
    login_operazione=login_operazione||' - SIAC-8174'
where repimp_id in (select b.repimp_id
from siac_t_report a,
	siac_t_report_importi b,
    siac_r_report_importi c,
    siac_t_bil d,
    siac_t_periodo e
where a.rep_id=c.rep_id
and b.repimp_id=c.repimp_id
and b.bil_id=d.bil_id
and d.periodo_id=e.periodo_id   
and a.rep_codice='BILR014'
and b.repimp_codice='deb_autoriz_att'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL);


update siac_r_report_importi
set posizione_stampa = 10,
	data_modifica=now(),
    login_operazione=login_operazione||' - SIAC-8174'
where repimp_id in (select b.repimp_id
from siac_t_report a,
	siac_t_report_importi b,
    siac_r_report_importi c,
    siac_t_bil d,
    siac_t_periodo e
where a.rep_id=c.rep_id
and b.repimp_id=c.repimp_id
and b.bil_id=d.bil_id
and d.periodo_id=e.periodo_id   
and a.rep_codice='BILR014'
and b.repimp_codice='deb_autoriz_legge'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL);


update siac_r_report_importi
set posizione_stampa = 11,
	data_modifica=now(),
    login_operazione=login_operazione||' - SIAC-8174'
where repimp_id in (select b.repimp_id
from siac_t_report a,
	siac_t_report_importi b,
    siac_r_report_importi c,
    siac_t_bil d,
    siac_t_periodo e
where a.rep_id=c.rep_id
and b.repimp_id=c.repimp_id
and b.bil_id=d.bil_id
and d.periodo_id=e.periodo_id   
and a.rep_codice='BILR014'
and b.repimp_codice='gar_princ'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL);


update siac_r_report_importi
set posizione_stampa = 12,
	data_modifica=now(),
    login_operazione=login_operazione||' - SIAC-8174'
where repimp_id in (select b.repimp_id
from siac_t_report a,
	siac_t_report_importi b,
    siac_r_report_importi c,
    siac_t_bil d,
    siac_t_periodo e
where a.rep_id=c.rep_id
and b.repimp_id=c.repimp_id
and b.bil_id=d.bil_id
and d.periodo_id=e.periodo_id  
and a.rep_codice='BILR014'
and b.repimp_codice='di_cui_gar_princ'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL);


update siac_r_report_importi
set posizione_stampa = 13,
	data_modifica=now(),
    login_operazione=login_operazione||' - SIAC-8174'
where repimp_id in (select b.repimp_id
from siac_t_report a,
	siac_t_report_importi b,
    siac_r_report_importi c,
    siac_t_bil d,
    siac_t_periodo e
where a.rep_id=c.rep_id
and b.repimp_id=c.repimp_id
and b.bil_id=d.bil_id
and d.periodo_id=e.periodo_id   
and a.rep_codice='BILR014'
and b.repimp_codice='garanzie'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL);



INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'A_ent_corr_trib_contr_pereq',
        'A) Entrate correnti di natura tributaria, contributiva e perequativa (Titolo I) - (opzionale)',
        0,
        'N',
        (select max(b.repimp_progr_riga)+1
        from siac_t_report a,
            siac_t_report_importi b,
            siac_r_report_importi c,
            siac_t_bil d,
            siac_t_periodo e
        where a.rep_id=c.rep_id
            and b.repimp_id =c.repimp_id
            and b.bil_id=d.bil_id
            and d.periodo_id=e.periodo_id
            and e.anno='2021'
            and a.rep_codice in('BILR014')
            and c.ente_proprietario_id=ente.ente_proprietario_id
            and a.data_cancellazione IS NULL 
            and b.data_cancellazione IS NULL 
            and c.data_cancellazione IS NULL),  
        t_bil.bil_id,
        t_periodo_imp.periodo_id,
        now(),
        null,
        t_bil.ente_proprietario_id,
        now(),
        now(),
        null,
        'SIAC-8174'
from  siac_t_bil t_bil, siac_t_ente_proprietario ente,
siac_t_periodo t_periodo_bil, siac_d_periodo_tipo d_per_tipo_bil,
siac_t_periodo t_periodo_imp, siac_d_periodo_tipo d_per_tipo_imp,
siac_t_report rep
where t_bil.periodo_id = t_periodo_bil.periodo_id
and d_per_tipo_bil.periodo_tipo_id=t_periodo_bil.periodo_tipo_id
and t_periodo_imp.ente_proprietario_id=t_periodo_bil.ente_proprietario_id
and d_per_tipo_imp.periodo_tipo_id=t_periodo_imp.periodo_tipo_id
and t_bil.ente_proprietario_id=ente.ente_proprietario_id
and rep.ente_proprietario_id=ente.ente_proprietario_id
and t_periodo_bil.anno in ('2018','2019','2020','2021') --anno bilancio
and d_per_tipo_bil.periodo_tipo_code='SY'
and t_periodo_imp.anno::integer between t_periodo_bil.anno::integer and
	t_periodo_bil.anno::integer +2 --anno importo
and d_per_tipo_imp.periodo_tipo_code='SY'
and rep.rep_codice='BILR014'
and t_bil.data_cancellazione is null
and ente.data_cancellazione is null
and t_periodo_bil.data_cancellazione is null
and d_per_tipo_bil.data_cancellazione is null
and t_periodo_imp.data_cancellazione is null
and d_per_tipo_imp.data_cancellazione is null
and rep.data_cancellazione is null
and not exists (select 1
	from siac_t_report_importi a
    where a.repimp_codice =  'A_ent_corr_trib_contr_pereq'
    	and a.bil_id = t_bil.bil_id
        and a.periodo_id = t_periodo_imp.periodo_id
        and a.ente_proprietario_id = ente.ente_proprietario_id
        and a.data_cancellazione IS NULL);    
        
INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select t_report.rep_id
from   siac_t_report t_report
where t_report.rep_codice = 'BILR014'
  and t_report.ente_proprietario_id = t_report_imp.ente_proprietario_id
  and t_report.data_cancellazione IS NULL) rep_id,
t_report_imp.repimp_id,
1 posizione_stampa,
now() validita_inizio,
null validita_fine,
t_report_imp.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'SIAC-8174' login_operazione
from   siac_t_report_importi t_report_imp
where  t_report_imp.repimp_codice = 'A_ent_corr_trib_contr_pereq'
	and t_report_imp.data_cancellazione IS NULL
    and not exists (select 1
    		from siac_r_report_importi a,
            	siac_t_report b,
                siac_t_ente_proprietario c
            where a.rep_id=b.rep_id
            	and a.repimp_id = t_report_imp.repimp_id
            	and a.ente_proprietario_id =t_report_imp.ente_proprietario_id
                and b.ente_proprietario_id=c.ente_proprietario_id
                and b.rep_codice ='BILR014'
                and a.data_cancellazione IS NULL
                and b.data_cancellazione IS NULL);	         
      
	  
-- SIAC-8179 - Maurizio - FINE

-- INC000005001587 Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR153_struttura_dca_spese" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_code varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_code varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_code varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_code varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  bil_ele_code3 varchar,
  code_cofog varchar,
  code_transaz_ue varchar,
  pdc_iv varchar,
  perim_sanitario_spesa varchar,
  ricorrente_spesa varchar,
  cup varchar,
  ord_id integer,
  ord_importo numeric,
  movgest_id integer,
  anno_movgest integer,
  movgest_importo numeric,
  fondo_plur_vinc numeric,
  movgest_importo_app numeric,
  tupla_group varchar
) AS
$body$
DECLARE

bilancio_id integer;
RTN_MESSAGGIO text;
anno_succ varchar;

BEGIN

/*
  SIAC-7702 16/09/2020.
  La funzione e' stata trasformata in funzione chiamante delle funzioni che
  estraggono i dati:
  - BILR153_struttura_dca_spese_dati_anno; estrae i dati come faceva prima 
    la funzione "BILR153_struttura_dca_spese";
  - BILR153_struttura_dca_spese_fpv_anno_succ; estrae i dati dell'FPV per 
    l'anno di bilancio successivo (come richiesto dalla jira SIAC-7702).
*/

anno_succ:=(p_anno::integer + 1);

return query
      select dati.bil_anno ,  dati.missione_tipo_code ,
        dati.missione_tipo_desc , dati.missione_code ,
        dati.missione_desc ,  dati.programma_tipo_code ,
        dati.programma_tipo_desc , 
        --29/04/2021 INC000005001587
        --Presi solo gli ultimi 2 caratteri del programma per risolvere un errore
        --nella generazione del file XBRL.
        --dati.programma_code,
        right(dati.programma_code,2)::varchar ,
        dati.programma_desc ,  dati.titusc_tipo_code ,
        dati.titusc_tipo_desc ,  dati.titusc_code ,
        dati.titusc_desc ,  dati.macroag_tipo_code ,
        dati.macroag_tipo_desc ,  dati.macroag_code ,
        dati.macroag_desc ,  dati.bil_ele_code ,
        dati.bil_ele_desc ,  dati.bil_ele_code2 ,
        dati.bil_ele_desc2 ,  dati.bil_ele_id ,
        dati.bil_ele_id_padre , dati.bil_ele_code3 ,
        dati.code_cofog ,  dati.code_transaz_ue ,
        dati.pdc_iv ,  dati.perim_sanitario_spesa ,
        dati.ricorrente_spesa ,  
        --29/04/2021 INC000005001587
        --il cup deve essere NULL se non definito per evitare problemi all'XBRL.
        case when dati.cup = '' then null else dati.cup end cup ,
        dati.ord_id ,  dati.ord_importo ,
        dati.movgest_id ,  dati.anno_movgest ,
        dati.movgest_importo ,  
        case when LAG(dati.tupla_group,1) 
              OVER (order by dati.tupla_group) = dati.tupla_group then 0
              	else coalesce(dati_fpv_anno_succ.fondo_plur_vinc,0) 
              end fondo_plur_vinc,
        dati.movgest_importo_app, dati.tupla_group
    from "BILR153_struttura_dca_spese_dati_anno"(p_ente_prop_id, p_anno) dati
     left join (select *
    	from "BILR153_struttura_dca_spese_fpv_anno_succ" (p_ente_prop_id, 
        				anno_succ)) dati_fpv_anno_succ
    on dati.tupla_group=dati_fpv_anno_succ.tupla_group  ;

exception
	when no_data_found THEN
      raise notice 'Nessun dato trovato per per il DCD spese.';
      return;
	when others  THEN
      RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
      return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- INC000005001587 Maurizio - FINE

-- 14.05.2021 Sofia Jira SIAC-8119 - inizio
update siac_d_accredito_tipo tipo
set    data_cancellazione=now(),
       validita_fine=now(),
       login_operazione=tipo.login_operazione||'-SIAC-8119'
from siac_d_accredito_tipo_oil oil,siac_r_accredito_tipo_oil r
where oil.ente_proprietario_id  in (2,3,4,5,10,14,15)
and   oil.accredito_tipo_oil_desc in ('VAGLIA POSTALE','VAGLIA TESORO')
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   tipo.accredito_tipo_id=r.accredito_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null;


update siac_r_accredito_tipo_oil r
set    data_cancellazione=now(),
       validita_fine=now(),
       login_operazione=r.login_operazione||'-SIAC-8119'
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id  in (2,3,4,5,10,14,15)
and   oil.accredito_tipo_oil_desc in ('VAGLIA POSTALE','VAGLIA TESORO')
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null
and   oil.data_cancellazione is null
and   oil.validita_fine is null;

update siac_d_accredito_tipo_oil oil
set    data_cancellazione=now(),
       validita_fine=now(),
       login_operazione=oil.login_operazione||'-SIAC-8119'
where oil.ente_proprietario_id  in (2,3,4,5,10,14,15)
and   oil.accredito_tipo_oil_desc in ('VAGLIA POSTALE','VAGLIA TESORO')
and   oil.data_cancellazione is null
and   oil.validita_fine is null;
-- 14.05.2021 Sofia Jira SIAC-8119 - fine


-- SIAC-8207 - Maurizio - INIZIO

update siac_t_voce_conf_indicatori_sint
set voce_conf_ind_desc='A) Risultato di amministrazione - Allegato a) (rendiconto)',
	data_modifica=now(),
    login_operazione=login_operazione|| ' - SIAC-8207'
where voce_conf_ind_codice='a_ris_amm_presunto_rnd'
	and login_operazione not like '%SIAC-8207';
	
-- SIAC-8207 - Maurizio - FINE
	
-- SIAC-8000 - Maurizio - INIZIO	

CREATE OR REPLACE FUNCTION siac."BILR252_variazioni_bozza_previsione_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  residui_presunti numeric,
  previsioni_anno_prec numeric,
  display_error varchar
) AS
$body$
DECLARE
classifBilRec record;
elencoVarRec  record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
TipoImpresidui varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
annoPrec VARCHAR;
importo_cassa_app numeric;
importo_competenza_app numeric;
intApp INTEGER;
strApp VARCHAR;
sql_query VARCHAR;
v_fam_titolotipologiacategoria varchar:='00003';
x_array VARCHAR [];




BEGIN

/*
	20/05/2021. SIAC-8000.
    La funzione nasce come copia della BILR236_entrate_riepilogo_titoli_tipologie ma
    gestisce i dati della PREVISIONE.
    E' stata rivista per renderla piu' veloce.
*/    

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;  

TipoImpComp='STA';  -- competenza
TipoImpresidui='STR'; -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
TipoImpCassa ='SCA'; ----- previsioni di cassa
elemTipoCode:='CAP-EP'; -- tipo capitolo previsione

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
residui_presunti:=0;
previsioni_anno_prec:=0;
stanziamento_prev_cassa_anno:=0;
display_error='';

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
 x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    intApp = strApp::INTEGER;
  END LOOP;
END IF;

select fnc_siac_random_user()
into	user_table;

--uso una tabella di appoggio per le varizioni perche' la query e' di tipo dinamico
--in quanto il parametro con l'elenco delle variazioni e' variabile.
sql_query='
insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio  ';          
       
    sql_query=sql_query||' where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id ';    
  
    sql_query=sql_query || ' and testata_variazione.ente_proprietario_id	=  ' || p_ente_prop_id ||'     
    and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code != ''A''              --SIAC-7244   in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';

    sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
       
    sql_query=sql_query||'
    and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
    
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	    

raise notice 'Query variazioni: % ',  sql_query;      
EXECUTE sql_query;                
         
sql_query:='
insert into siac_rep_cap_ep
select cl.classif_id,
    anno_eserc.anno anno_bilancio,
    e.*, '''||user_table||''' utente
   from 	siac_r_bil_elem_class rc,
          siac_t_bil_elem e,
          siac_d_class_tipo ct,
          siac_t_class cl,
          siac_t_bil bilancio,
          siac_t_periodo anno_eserc,
          siac_d_bil_elem_tipo tipo_elemento, 
          siac_d_bil_elem_stato stato_capitolo,
          siac_r_bil_elem_stato r_capitolo_stato,
          siac_d_bil_elem_categoria cat_del_capitolo,
          siac_r_bil_elem_categoria r_cat_capitolo
  where ct.classif_tipo_id				=	cl.classif_tipo_id
  and cl.classif_id					=	rc.classif_id 
  and bilancio.periodo_id				=	anno_eserc.periodo_id 
  and e.bil_id						=	bilancio.bil_id 
  and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
  and e.elem_id						=	rc.elem_id 
  and	e.elem_id						=	r_capitolo_stato.elem_id
  and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
  and	e.elem_id						=	r_cat_capitolo.elem_id
  and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
  and e.ente_proprietario_id='||p_ente_prop_id||
  'and anno_eserc.anno					= 	'''||p_anno||'''
  and ct.classif_tipo_code			=	''CATEGORIA''
  and tipo_elemento.elem_tipo_code 	= 	'''||elemTipoCode||'''
  and	stato_capitolo.elem_stato_code	=	''VA''
  and e.data_cancellazione 				is null
  and	r_capitolo_stato.data_cancellazione	is null
  and	r_cat_capitolo.data_cancellazione	is null
  and	rc.data_cancellazione				is null
  and	ct.data_cancellazione 				is null
  and	cl.data_cancellazione 				is null
  and	bilancio.data_cancellazione 		is null
  and	anno_eserc.data_cancellazione 		is null
  and	tipo_elemento.data_cancellazione	is null
  and	stato_capitolo.data_cancellazione 	is null
  and	cat_del_capitolo.data_cancellazione	is null
  and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
  and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
  and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
  and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
  and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
  and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
  and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
  and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
  and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
  and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
  and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())';
  
raise notice 'Query1 capitoli: % ',  sql_query;      
EXECUTE sql_query; 

--carico anche i capitoli su una tabella di appoggio 
sql_query:='
insert into siac_rep_cap_ep             
with prec as (       
select * From siac_t_cap_e_importi_anno_prec a
where a.anno='''||annoPrec||'''       
and a.ente_proprietario_id='||p_ente_prop_id||'), 
categ as (
select * from siac_t_class a, siac_d_class_tipo b
where a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code = ''CATEGORIA''
and a.data_cancellazione is null
and b.data_cancellazione is null
and a.ente_proprietario_id='||p_ente_prop_id||'
and to_timestamp(''01/01/'||annoPrec||''',''dd/mm/yyyy'') between
a.validita_inizio and COALESCE(a.validita_fine, to_timestamp(''31/12/'||annoPrec||''',''dd/mm/yyyy''))
)  
select categ.classif_id classif_id_categ,  '||p_anno||',
NULL, prec.elem_code, prec.elem_code2,
       prec.elem_code3, NULL, NULL,  NULL, NULL, NULL, NULL, NULL,NULL,NULL,
        prec.ente_proprietario_id, prec.data_creazione, prec.data_modifica,
        prec.data_cancellazione,prec.login_operazione, '''||user_table||''' utente
 from prec
join categ on prec.categoria_code=categ.classif_code
and not exists (select 1 from siac_rep_cap_ep ep
                      where ep.elem_code=prec.elem_code
                        AND ep.elem_code2=prec.elem_code2
                        and ep.elem_code3=prec.elem_code3
                        and ep.classif_id = categ.classif_id
                        and ep.utente='''||user_table||'''
                        and ep.ente_proprietario_id='||p_ente_prop_id||')'; 
raise notice 'Query2 capitoli: % ',  sql_query;                          
EXECUTE sql_query; 
                        
return query
with struttura as (
	select * from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno,user_table)),
capitoli as (select *
			from siac_rep_cap_ep a
            where a.ente_proprietario_id=p_ente_prop_id
            	and utente = user_table),
	variaz_stanz_anno as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_entrate variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('STD')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_stanz_anno1 as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_entrate variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp1
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('STD')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_stanz_anno2 as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_entrate variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp2
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('STD')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_cassa_anno as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_entrate variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp
                and variaz.tipologia = TipoImpCassa  --'SCA' -- cassa
                and d_bil_elem_categ.elem_cat_code in ('STD')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id )  ,
    variaz_residui_anno as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_entrate variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp
                and variaz.tipologia = TipoImpresidui --'STR'  residui
                and d_bil_elem_categ.elem_cat_code in ('STD')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id )  
select
  capitoli.anno_bilancio::varchar bil_anno,
  ''::varchar titoloe_tipo_code,
  struttura.classif_tipo_desc1::varchar titoloe_tipo_desc,
  struttura.titolo_code:: varchar titoloe_code,
  struttura.titolo_desc:: varchar titoloe_desc,
  ''::varchar tipologia_tipo_code,
  struttura.classif_tipo_desc2::varchar tipologia_tipo_desc,
  struttura.tipologia_code::varchar tipologia_code,
  struttura.tipologia_desc::varchar tipologia_desc,
  ''::varchar categoria_tipo_code,
  struttura.classif_tipo_desc3::varchar categoria_tipo_desc,
  struttura.categoria_code::varchar categoria_code,
  struttura.categoria_desc::varchar categoria_desc,
  capitoli.elem_code::varchar bil_ele_code,
  capitoli.elem_desc::varchar bil_ele_desc,
  capitoli.elem_code2::varchar bil_ele_code2,
  capitoli.elem_desc2::varchar bil_ele_desc2,
  capitoli.elem_id::integer bil_ele_id,
  capitoli.elem_id_padre::integer bil_ele_id_padre,
  COALESCE(variaz_cassa_anno.importo_variaz,0)::numeric stanziamento_prev_cassa_anno,
  COALESCE(variaz_stanz_anno.importo_variaz,0)::numeric stanziamento_prev_anno,
  COALESCE(variaz_stanz_anno1.importo_variaz,0)::numeric stanziamento_prev_anno1,
  COALESCE(variaz_stanz_anno2.importo_variaz,0)::numeric stanziamento_prev_anno2,
  COALESCE(variaz_residui_anno.importo_variaz,0)::numeric residui_presunti,  
  0::numeric previsioni_anno_prec,
  ''::varchar display_error  
from struttura 
	left join capitoli
    	on struttura.categoria_id = capitoli.classif_id
    left join variaz_stanz_anno
      on variaz_stanz_anno.elem_id = capitoli.elem_id
    left join variaz_stanz_anno1
      on variaz_stanz_anno1.elem_id = capitoli.elem_id
    left join variaz_stanz_anno2
      on variaz_stanz_anno2.elem_id = capitoli.elem_id 
    left join variaz_cassa_anno
      on variaz_cassa_anno.elem_id = capitoli.elem_id    
    left join variaz_residui_anno
      on variaz_residui_anno.elem_id = capitoli.elem_id;



delete from siac_rep_var_entrate where utente=user_table;
delete from siac_rep_cap_ep where utente=user_table;

raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;        
	when others  THEN
        RTN_MESSAGGIO:='capitolo altro errore';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR252_variazioni_bozza_previsione_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_code3 varchar,
  bil_ele_id integer,
  imp_variaz_stanz_anno numeric,
  imp_variaz_stanz_anno1 numeric,
  imp_variaz_stanz_anno2 numeric,
  imp_variaz_cassa_anno numeric,
  imp_variaz_stanz_fpv_anno numeric,
  imp_variaz_stanz_fpv_anno1 numeric,
  imp_variaz_stanz_fpv_anno2 numeric,
  imp_variaz_residui_anno numeric,
  display_error varchar
) AS
$body$
DECLARE

classifBilRec record;
ImpegniRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
elemTipoCode_UG	varchar;
TipoImpstanzresidui varchar;
tipo_capitolo	varchar;
h_count integer :=0;
importo integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
tipologia_capitolo	varchar;
cat_capitolo	varchar;
esiste_siac_t_dicuiimpegnato_bilprev integer;
annoPrec VARCHAR;
annobilint integer :=0;
previsioni_anno_prec_cassa_app NUMERIC;
previsioni_anno_prec_comp_app NUMERIC;
tipo_categ_capitolo VARCHAR;
stanziamento_fpv_anno_prec_app NUMERIC;
sql_query VARCHAR;
strApp VARCHAR;
intApp INTEGER;
v_importo_imp   NUMERIC :=0;
v_importo_imp1  NUMERIC :=0;
v_importo_imp2  NUMERIC :=0;
v_conta_rec INTEGER :=0;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
x_array VARCHAR [];

contaParVarPeg integer;
contaParVarBil integer;

BEGIN

/*
	20/05/2021. SIAC-8000.
    La funzione nasce come copia della BILR238_spese_riepilogo_missione_programma ma
    gestisce i dati della PREVISIONE.
    La funzione fornisce in output solo i dati delle variazioni raggruppati per:
    - missione
    - programma
    - titolo
	- macroaggregato
    - capitolo.
     Gli importi delle variazioni riguardano:
    - competenza anno bilancio, annobilancio + 1 e anno bilancio + 2;
    - cassa anno bilancio;
    - residui anno bilancio;
    - stanziamento fpv anno bilancio, annobilancio + 1 e anno bilancio + 2.
    
    ATTENZIONE: 
    Gli importi delle variazioni riguardano solo i capitoli di tipo ('STD','FSC','FPV','FPVC'),
    cosi' come fatto dalla procedura "BILR111_Allegato_9_bil_gest_spesa_mpt".
    Per questo modivo se si confrontano i totali delle variazioni da applicativo con i totali 
    estratti da questa procedura potrebbero esserci delle differenze, in quanto le variazioni
    potrebbero coinvolgere anche altri tipi di capitoli.   	   
          
*/

annobilint := p_anno::INTEGER;
annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
elemTipoCode:='CAP-UP'; -- tipo capitolo previsione

annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;
display_error='';
contaParVarPeg:=0;
contaParVarBil:=0;

-- verifico che il parametro con l'elenco delle variazioni abbia solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
   x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    intApp = strApp::INTEGER;
  END LOOP;
END IF;


select fnc_siac_random_user()
into	user_table;

raise notice '1: %', clock_timestamp()::varchar;  
-- raise notice 'user  %',user_table;

bil_anno='';

missione_code='';
missione_desc='';

programma_code='';
programma_desc='';

titusc_code='';
titusc_desc='';

macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
imp_variaz_stanz_anno=0;
imp_variaz_stanz_anno1=0;
imp_variaz_stanz_anno2=0;
imp_variaz_cassa_anno=0;
imp_variaz_stanz_fpv_anno=0;
imp_variaz_stanz_fpv_anno1=0;
imp_variaz_stanz_fpv_anno2=0;
   
display_error:='';

--uso una tabella di appoggio per le varizioni perche' la query e' di tipo dinamico
--in quanto il parametro con l'elenco delle variazioni e' variabile.

sql_query='
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio  ';          
       
    sql_query=sql_query||' where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id ';    
  
    sql_query=sql_query || ' and testata_variazione.ente_proprietario_id	=  ' || p_ente_prop_id ||'     
    and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code != ''A''              --SIAC-7244   in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';

    sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
       
    sql_query=sql_query||'
    and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
    
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	    

raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;                
                
return query 
with struttura as (
	select * from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, p_anno,user_table)),
capitoli as (   
    select 	programma.classif_id classif_id_programma,
            macroaggr.classif_id classif_id_macroaggregato,
            anno_eserc.anno anno_bilancio,
            capitolo.elem_code, 
            capitolo.elem_code2,
            capitolo.elem_code3,
            capitolo.elem_desc,
            capitolo.elem_id,
            capitolo.elem_desc2
    from siac_t_bil bilancio,
         siac_t_periodo anno_eserc,
         siac_d_class_tipo programma_tipo,
         siac_t_class programma,
         siac_d_class_tipo macroaggr_tipo,
         siac_t_class macroaggr,
         siac_t_bil_elem capitolo,
         siac_d_bil_elem_tipo tipo_elemento,
         siac_r_bil_elem_class r_capitolo_programma,
         siac_r_bil_elem_class r_capitolo_macroaggr, 
         siac_d_bil_elem_stato stato_capitolo, 
         siac_r_bil_elem_stato r_capitolo_stato,
         siac_d_bil_elem_categoria cat_del_capitolo,
         siac_r_bil_elem_categoria r_cat_capitolo
    where        		
        programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
        programma.classif_id=r_capitolo_programma.classif_id					and
        macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
        macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
        bilancio.periodo_id=anno_eserc.periodo_id 								and
        capitolo.bil_id=bilancio.bil_id 										and
        capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
        tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
        capitolo.elem_id=r_capitolo_programma.elem_id							and
        capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
        capitolo.elem_id				=	r_capitolo_stato.elem_id			and
        r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
        capitolo.elem_id				=	r_cat_capitolo.elem_id				and
        r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and                
        capitolo.ente_proprietario_id=p_ente_prop_id      						and
        anno_eserc.anno= p_anno 												and
        programma_tipo.classif_tipo_code='PROGRAMMA' 							and
        macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
        stato_capitolo.elem_stato_code	=	'VA'								and
        cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
        and	bilancio.data_cancellazione 				is null
        and	anno_eserc.data_cancellazione 				is null
        and	programma_tipo.data_cancellazione 			is null
        and	programma.data_cancellazione 				is null
        and	macroaggr_tipo.data_cancellazione 			is null
        and	macroaggr.data_cancellazione 				is null
        and	capitolo.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione 			is null
        and	r_capitolo_programma.data_cancellazione 	is null
        and	r_capitolo_macroaggr.data_cancellazione 	is null 
        and	stato_capitolo.data_cancellazione 			is null 
        and	r_capitolo_stato.data_cancellazione 		is null
        and	cat_del_capitolo.data_cancellazione 		is null
        and	r_cat_capitolo.data_cancellazione 	 		is null),
	variaz_stanz_anno as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('STD','FSC','FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_stanz_anno1 as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp1
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('STD','FSC','FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_stanz_anno2 as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp2
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('STD','FSC','FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_cassa_anno as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp
                and variaz.tipologia = TipoImpCassa  --'SCA' -- cassa
                and d_bil_elem_categ.elem_cat_code in ('STD','FSC','FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id )  ,
      variaz_stanz_fpv_anno as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_stanz_fpv_anno1 as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp1
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_stanz_fpv_anno2 as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp2
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id )  ,
    variaz_residui_anno as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp
                and variaz.tipologia = TipoImpRes --'STR'  residui
                and d_bil_elem_categ.elem_cat_code in ('STD','FSC','FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id )              		                                    
select 
  p_anno::varchar bil_anno,
  struttura.missione_tipo_desc::varchar missione_tipo_desc,
  struttura.missione_code::varchar missione_code,
  struttura.missione_desc:: varchar missione_desc,
  struttura.programma_tipo_desc:: varchar programma_tipo_desc,
  struttura.programma_code::varchar programma_code,
  struttura.programma_desc::varchar programma_desc,
  struttura.titusc_tipo_desc::varchar titusc_tipo_desc,
  struttura.titusc_code::varchar titusc_code,
  struttura.titusc_desc::varchar titusc_desc,
  struttura.macroag_tipo_desc::varchar macroag_tipo_desc,
  struttura.macroag_code::varchar macroag_code,
  struttura.macroag_desc::varchar macroag_desc,
  capitoli.elem_code::varchar bil_ele_code,
  capitoli.elem_desc::varchar bil_ele_desc,
  capitoli.elem_code2::varchar bil_ele_code2,
  capitoli.elem_desc2::varchar bil_ele_desc2,
  capitoli.elem_code3::varchar bil_ele_code3,
  capitoli.elem_id::integer bil_ele_id,
  COALESCE(variaz_stanz_anno.importo_variaz,0)::numeric imp_variaz_stanz_anno,
  COALESCE(variaz_stanz_anno1.importo_variaz,0)::numeric imp_variaz_stanz_anno1,
  COALESCE(variaz_stanz_anno2.importo_variaz,0)::numeric imp_variaz_stanz_anno2,
  COALESCE(variaz_cassa_anno.importo_variaz,0)::numeric imp_variaz_cassa_anno,
  COALESCE(variaz_stanz_fpv_anno.importo_variaz,0)::numeric imp_variaz_stanz_fpv_anno,
  COALESCE(variaz_stanz_fpv_anno1.importo_variaz,0)::numeric imp_variaz_stanz_fpv_anno1,
  COALESCE(variaz_stanz_fpv_anno2.importo_variaz,0)::numeric imp_variaz_stanz_fpv_anno2,
  COALESCE(variaz_residui_anno.importo_variaz,0)::numeric imp_variaz_residui_anno,  
  ''::varchar display_error  
from struttura 
	left join capitoli
    	on (struttura.programma_id = capitoli.classif_id_programma    
           	and	struttura.macroag_id = capitoli.classif_id_macroaggregato)
    left join variaz_stanz_anno
      on variaz_stanz_anno.elem_id = capitoli.elem_id
    left join variaz_stanz_anno1
      on variaz_stanz_anno1.elem_id = capitoli.elem_id
    left join variaz_stanz_anno2
      on variaz_stanz_anno2.elem_id = capitoli.elem_id 
    left join variaz_cassa_anno
      on variaz_cassa_anno.elem_id = capitoli.elem_id
    left join variaz_stanz_fpv_anno
      on variaz_stanz_fpv_anno.elem_id = capitoli.elem_id
    left join variaz_stanz_fpv_anno1
      on variaz_stanz_fpv_anno1.elem_id = capitoli.elem_id
    left join variaz_stanz_fpv_anno2
      on variaz_stanz_fpv_anno2.elem_id = capitoli.elem_id
    left join variaz_residui_anno
      on variaz_residui_anno.elem_id = capitoli.elem_id;
                    
       
                          
delete from siac_rep_var_spese  where utente=user_table;

raise notice 'fine OK';
    exception
    when no_data_found THEN
      raise notice 'Nessun dato trovato riguardo la struttura di bilancio.';
      return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;              
    when others  THEN
      RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
      return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR997_tipo_capitolo_dei_report_solo_variaz_prev" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_num_provv_var_peg integer,
  p_anno_provv_var_peg varchar,
  p_tipo_provv_var_peg varchar,
  p_num_provv_var_bil integer,
  p_anno_provv_var_bil varchar,
  p_tipo_provv_var_bil varchar,
  p_code_sac_direz_peg varchar,
  p_code_sac_sett_peg varchar,
  p_code_sac_direz_bil varchar,
  p_code_sac_sett_bil varchar
)
RETURNS TABLE (
  anno_competenza varchar,
  importo numeric,
  descrizione varchar,
  posizione_nel_report integer,
  codice_importo varchar,
  tipo_capitolo_cod varchar
) AS
$body$
DECLARE

 /* 21/05/2021. SIAC-8000.
 	Questa funzione nasce come copia della BILR997_tipo_capitolo_dei_report_solo_variaz
    ma lavora sui capitoli di previsione.    
*/         
         
classifBilRec record;
tipo_capitolo record;
tipoAvanzo varchar;
tipoDisavanzo varchar;
tipoFpvcc varchar;
tipoFpvsc varchar;
tipoFCassaIni varchar;
tipoFpv varchar;
elemTipoCodeE varchar;
elemTipoCodeS varchar;
RTN_MESSAGGIO varchar(1000):='';
sql_query VARCHAR;
user_table	varchar;
elemTipoCode VARCHAR;
elemCatCode  VARCHAR;
variazione_aumento_stanziato NUMERIC;
variazione_diminuzione_stanziato NUMERIC;
variazione_aumento_cassa NUMERIC;
variazione_diminuzione_cassa NUMERIC;
variazione_aumento_residuo NUMERIC;
variazione_diminuzione_residuo NUMERIC;


annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
contaParVarPeg integer;
contaParVarBil integer;

BEGIN

anno_competenza='';
importo=0;
descrizione='';
posizione_nel_report=0;
codice_importo='';
tipoAvanzo='AAM';
tipoDisavanzo='DAM';
tipoFpvcc='FPVCC';
tipoFpvsc='FPVSC';
tipoFCassaIni='FCI';
tipoFpv='FPV'; 
tipo_capitolo_cod='';


elemTipoCodeE:='CAP-EP'; -- tipo capitolo previsione
elemTipoCodeS:='CAP-UP'; -- tipo capitolo previsione

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 


variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;

contaParVarPeg:=0;
contaParVarBil:=0;

if p_num_provv_var_peg IS NOT  NULL THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_anno_provv_var_peg IS NOT  NULL AND p_anno_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_tipo_provv_var_peg IS NOT  NULL AND p_tipo_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if contaParVarPeg not in (0,3) then
	--display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di PEG''';
    return next;
    return;        
end if;

if p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if contaParVarBil not in (0,3) then
	--display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di Bilancio''';
    return next;
    return;        
end if;
select fnc_siac_random_user()
into	user_table;


insert into siac_rep_cap_ep
select --cl.classif_id,
  NULL,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	
 		siac_t_bil_elem e,

        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCodeE
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now());

IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') OR
	 contaParVarPeg= 3 OR contaParVarBil = 3 OR p_code_sac_direz_peg <> '999' OR
     p_code_sac_direz_bil <> '999' THEN
	sql_query='
    insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio  ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto ,
            siac_d_atto_amm_tipo		tipo_atto,
			siac_r_atto_amm_stato 		r_atto_stato,
	        siac_d_atto_amm_stato 		stato_atto ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto2 ,
            siac_d_atto_amm_tipo		tipo_atto2,
			siac_r_atto_amm_stato 		r_atto_stato2,
	        siac_d_atto_amm_stato 		stato_atto2 ';
    end if;
    IF p_code_sac_direz_peg <> '999'  THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti'; 
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti2'; 
    END IF;
    sql_query=sql_query||'  where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id						=	atto.attoamm_id
    	and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    	and 	atto.attoamm_id										= 	r_atto_stato.attoamm_id
    	and 	r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id_varbil				=	atto2.attoamm_id
    	and		atto2.attoamm_tipo_id								=	tipo_atto2.attoamm_tipo_id
    	and 	atto2.attoamm_id									= 	r_atto_stato2.attoamm_id
    	and 	r_atto_stato2.attoamm_stato_id						=	stato_atto2.attoamm_stato_id ';
    end if;
        
    IF p_code_sac_direz_peg <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id =ele_dir_sett_atti.attoamm_id ';
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id_varbil =ele_dir_sett_atti2.attoamm_id ';
    END IF;
    sql_query=sql_query || ' and		testata_variazione.ente_proprietario_id				= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code != ''A''              --SIAC-7244   in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCodeE|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';
    
    IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    end if;
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||' AND stato_atto.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto.attoamm_numero ='||p_num_provv_var_peg||' 
    	and 	atto.attoamm_anno ='''||p_anno_provv_var_peg||'''
    	and		tipo_atto.attoamm_tipo_code='''||p_tipo_provv_var_peg||''' ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' AND stato_atto2.attoamm_stato_code <> ''ANNULLATO''
        and 	atto2.attoamm_numero ='||p_num_provv_var_bil||' 
    	and 	atto2.attoamm_anno ='''||p_anno_provv_var_bil||'''
    	and		tipo_atto2.attoamm_tipo_code='''||p_tipo_provv_var_bil||''' ';
    end if;
    IF p_code_sac_direz_peg <> '999' THEN
    	IF p_code_sac_sett_peg = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' ';
        ELSIF p_code_sac_sett_peg = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificati un settore.
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''||p_code_sac_sett_peg||'''';
        END IF;
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	IF p_code_sac_sett_bil = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' ';
        ELSIF p_code_sac_sett_bil = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificato un settore.
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''||p_code_sac_sett_bil||'''';
        END IF;
    END IF;
    sql_query=sql_query||' and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query || ' and 	atto.data_cancellazione						is null
    	and 	tipo_atto.data_cancellazione				is null
    	and 	r_atto_stato.data_cancellazione				is null ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query || ' and 	atto2.data_cancellazione		is null
    	and 	tipo_atto2.data_cancellazione				is null
    	and 	r_atto_stato2.data_cancellazione			is null ';
    end if;
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query Var Entrate: % ',  sql_query;      
EXECUTE sql_query;

RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

    insert into siac_rep_var_entrate_riga
    select  tb0.elem_id,     
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            p_anno
    from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno=p_anno
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno=p_anno
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno=p_anno
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno=p_anno
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno=p_anno
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno=p_anno
            and tb6.utente = tb0.utente 	)
      union 
         select  tb0.elem_id,   
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            (p_anno::INTEGER + 1)::varchar
    from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb6.utente = tb0.utente 	)
        union 
        select  tb0.elem_id,    
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            (p_anno::INTEGER + 2)::varchar
        from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb6.utente = tb0.utente 	);



insert into siac_rep_cap_ug 
select 	NULL, --programma.classif_id,
		NULL, --macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
       user_table utente
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where capitolo.ente_proprietario_id=p_ente_prop_id      						and
   	anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCodeS						     	and 
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
   	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
    and	stato_capitolo.data_cancellazione 			is null 
    and	r_capitolo_stato.data_cancellazione 		is null
	and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione 			is null;	
    
    
sql_query='
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio  ';
	if contaParVarPeg = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto ,
            siac_d_atto_amm_tipo		tipo_atto,
			siac_r_atto_amm_stato 		r_atto_stato,
	        siac_d_atto_amm_stato 		stato_atto ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto2 ,
            siac_d_atto_amm_tipo		tipo_atto2,
			siac_r_atto_amm_stato 		r_atto_stato2,
	        siac_d_atto_amm_stato 		stato_atto2 ';
    end if;
    IF p_code_sac_direz_peg <> '999'  THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti'; 
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti2'; 
    END IF;                      
    
    sql_query=sql_query||' where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id						=	atto.attoamm_id
    	and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    	and 	atto.attoamm_id										= 	r_atto_stato.attoamm_id
    	and 	r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id_varbil				=	atto2.attoamm_id
    	and		atto2.attoamm_tipo_id								=	tipo_atto2.attoamm_tipo_id
    	and 	atto2.attoamm_id									= 	r_atto_stato2.attoamm_id
    	and 	r_atto_stato2.attoamm_stato_id						=	stato_atto2.attoamm_stato_id ';
    end if;
        
    IF p_code_sac_direz_peg <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id =ele_dir_sett_atti.attoamm_id ';
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id_varbil =ele_dir_sett_atti2.attoamm_id ';
    END IF;
    sql_query=sql_query || ' and		testata_variazione.ente_proprietario_id	= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code != ''A''              --SIAC-7244   in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCodeS|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';
    
IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    end if;
    if contaParVarPeg = 3 then 
    	sql_query=sql_query|| ' AND stato_atto.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto.attoamm_numero ='||p_num_provv_var_peg||' 
    	and 	atto.attoamm_anno ='''||p_anno_provv_var_peg||'''
    	and		tipo_atto.attoamm_tipo_code='''||p_tipo_provv_var_peg||''' ';
    end if;
   
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' AND stato_atto2.attoamm_stato_code <> ''ANNULLATO''  
        and 	atto2.attoamm_numero ='||p_num_provv_var_bil||' 
    	and 	atto2.attoamm_anno ='''||p_anno_provv_var_bil||'''
    	and		tipo_atto2.attoamm_tipo_code='''||p_tipo_provv_var_bil||''' ';
    end if;
    
    IF p_code_sac_direz_peg <> '999' THEN
    	IF p_code_sac_sett_peg = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' ';
        ELSIF p_code_sac_sett_peg = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificati un settore.
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''||p_code_sac_sett_peg||'''';
        END IF;
    END IF;

    IF p_code_sac_direz_bil <> '999' THEN
    	IF p_code_sac_sett_bil = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' ';
        ELSIF p_code_sac_sett_bil = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificato un settore.
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''||p_code_sac_sett_bil||'''';
        END IF;
    END IF;
    
    sql_query=sql_query||' and		r_variazione_stato.data_cancellazione	is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query || ' and 	atto.data_cancellazione						is null
    	and 	tipo_atto.data_cancellazione				is null
    	and 	r_atto_stato.data_cancellazione				is null ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query || ' and 	atto2.data_cancellazione		is null
    	and 	tipo_atto2.data_cancellazione				is null
    	and 	r_atto_stato2.data_cancellazione			is null ';
    end if;
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;


   insert into siac_rep_var_spese_riga
select  tb0.elem_id,
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno
        and     tb1.utente = tb0.utente 
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=p_anno
        and     tb2.utente = tb0.utente 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=p_anno
        and     tb3.utente = tb0.utente  
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=p_anno
        and     tb4.utente = tb0.utente  
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=p_anno
        and     tb5.utente = tb0.utente	
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=p_anno
        and     tb6.utente = tb0.utente 
         )
        where  tb0.utente = user_table  
   union
     select  tb0.elem_id,        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
       annocapimp1
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp1
        and     tb1.utente = tb0.utente 
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp1
        and     tb2.utente = tb0.utente 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp1
        and     tb3.utente = tb0.utente  
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp1
        and     tb4.utente = tb0.utente  
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp1
        and     tb5.utente = tb0.utente	
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp1
        and     tb6.utente = tb0.utente 
         )
        where  tb0.utente = user_table  
        union
     select  tb0.elem_id,        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        annocapimp2
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp2
        and     tb1.utente = tb0.utente 
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp2
        and     tb2.utente = tb0.utente 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp2
        and     tb3.utente = tb0.utente  
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp2
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp2
        and     tb5.utente = tb0.utente	
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp2
        and     tb6.utente = tb0.utente 
         )
        where  tb0.utente = user_table    ; 
        
        
end if;

    
for tipo_capitolo in
        select t0.*               
			from "BILR000_tipo_capitolo_dei_report" (p_ente_prop_id, p_anno, 'P') t0
            	ORDER BY t0.anno_competenza
loop

importo:=0;

elemCatCode= tipo_capitolo.codice_importo;

IF tipo_capitolo.tipo_capitolo_cod =elemTipoCodeE THEN  
	--Cerco i dati delle eventuali variazioni di entrata
--raise notice 'codice importo =%', tipo_capitolo.codice_importo;      
	
--16/03/2017: nel caso di capitoli FPV di entrata devo sommare gli importi
--	dei capitoli FPVSC e FPVCC.
		if tipo_capitolo.codice_importo = 'FPV' then
              --raise notice 'tipo_capitolo.codice_importo=%', variazione_diminuzione_stanziato;
              select      'FPV' elem_cat_code , 
                  coalesce (sum (t1.variazione_aumento_stanziato),0) variazione_aumento_stanziato,
                  coalesce (sum (t1.variazione_diminuzione_stanziato),0) variazione_diminuzione_stanziato,
                  coalesce (sum (t1.variazione_aumento_cassa),0) variazione_aumento_cassa,
                  coalesce (sum (t1.variazione_diminuzione_cassa),0) variazione_diminuzione_cassa,
                  coalesce (sum (t1.variazione_aumento_residuo),0) variazione_aumento_residuo,
                  coalesce (sum (t1.variazione_diminuzione_residuo),0) variazione_diminuzione_residuo                                                                                           
              into elemCatCode,variazione_aumento_stanziato, variazione_diminuzione_stanziato,
                  variazione_aumento_cassa, variazione_diminuzione_cassa,variazione_aumento_residuo,
              variazione_diminuzione_residuo 
              from siac_rep_var_entrate_riga t1,
                  siac_r_bil_elem_categoria r_cat_capitolo,
                  siac_d_bil_elem_categoria cat_del_capitolo            
              WHERE  r_cat_capitolo.elem_id=t1.elem_id
                  AND r_cat_capitolo.elem_cat_id=cat_del_capitolo.elem_cat_id
                  AND t1.utente=user_table
                  AND cat_del_capitolo.elem_cat_code in (tipoFpvcc, tipoFpvsc)
                  AND r_cat_capitolo.data_cancellazione IS NULL
                  AND cat_del_capitolo.data_cancellazione IS NULL
                  AND t1.periodo_anno = tipo_capitolo.anno_competenza
             -- 17/07/2017: commentata la group by per jira SIAC-5105
             	--group by  elem_cat_code  
             ;             
            IF NOT FOUND THEN
                  variazione_aumento_stanziato=0;
                  variazione_diminuzione_stanziato=0;
                  variazione_aumento_cassa=0;
                  variazione_diminuzione_cassa=0;
                  variazione_aumento_residuo=0;
                  variazione_diminuzione_residuo=0;
            end if;
            
            raise notice 'variazione_aumento_stanziato=%', variazione_aumento_stanziato;
            raise notice 'variazione_diminuzione_stanziato=%', variazione_diminuzione_stanziato;
              /* 
                  SIAC-7211 e SIAC-7212.
                  L'importo restituito deve contenere solo l'importo dei capitoli variati.
              */
            --importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato; 
            importo = variazione_aumento_stanziato+variazione_diminuzione_stanziato; 
            else 


               select      cat_del_capitolo.elem_cat_code,
                    coalesce (sum (t1.variazione_aumento_stanziato),0) variazione_aumento_stanziato,
                    coalesce (sum (t1.variazione_diminuzione_stanziato),0) variazione_diminuzione_stanziato,
                    coalesce (sum (t1.variazione_aumento_cassa),0) variazione_aumento_cassa,
                    coalesce (sum (t1.variazione_diminuzione_cassa),0) variazione_diminuzione_cassa,
                    coalesce (sum (t1.variazione_aumento_residuo),0) variazione_aumento_residuo,
                    coalesce (sum (t1.variazione_diminuzione_residuo),0) variazione_diminuzione_residuo                                                                                           
                into elemCatCode,variazione_aumento_stanziato, variazione_diminuzione_stanziato,
                    variazione_aumento_cassa, variazione_diminuzione_cassa,variazione_aumento_residuo,
                variazione_diminuzione_residuo 
                from siac_rep_var_entrate_riga t1,
                    siac_r_bil_elem_categoria r_cat_capitolo,
                    siac_d_bil_elem_categoria cat_del_capitolo            
                WHERE  r_cat_capitolo.elem_id=t1.elem_id
                    AND r_cat_capitolo.elem_cat_id=cat_del_capitolo.elem_cat_id
                    AND t1.utente=user_table
                    AND cat_del_capitolo.elem_cat_code=tipo_capitolo.codice_importo
                    AND r_cat_capitolo.data_cancellazione IS NULL
                    AND cat_del_capitolo.data_cancellazione IS NULL
                    AND t1.periodo_anno = tipo_capitolo.anno_competenza
                group by cat_del_capitolo.elem_cat_code   ; 
                
                IF NOT FOUND THEN
                  variazione_aumento_stanziato=0;
                  variazione_diminuzione_stanziato=0;
                  variazione_aumento_cassa=0;
                  variazione_diminuzione_cassa=0;
                  variazione_aumento_residuo=0;
                  variazione_diminuzione_residuo=0;
                ELSE                
                  
              /* 
                  SIAC-7211 e SIAC-7212.
                  L'importo restituito deve contenere solo l'importo dei capitoli variati.
              */                   
                  IF elemCatCode = tipoFCassaIni THEN                 
                      --importo =tipo_capitolo.importo+variazione_aumento_cassa+variazione_diminuzione_cassa;  
                      importo =variazione_aumento_cassa+variazione_diminuzione_cassa;  
                  ELSE         
                      --importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato;   	
                      importo = variazione_aumento_stanziato+variazione_diminuzione_stanziato;   	
                  END IF;
              
            end if;  
                  
            END IF;     
            
ELSE  --Cerco i dati delle eventuali variazioni di spesa
--raise notice 'codice importo =%', tipo_capitolo.codice_importo;
	select      cat_del_capitolo.elem_cat_code,
			    coalesce (sum (t1.variazione_aumento_stanziato),0) variazione_aumento_stanziato,
                coalesce (sum (t1.variazione_diminuzione_stanziato),0) variazione_diminuzione_stanziato,
                coalesce (sum (t1.variazione_aumento_cassa),0) variazione_aumento_cassa,
                coalesce (sum (t1.variazione_diminuzione_cassa),0) variazione_diminuzione_cassa,
                coalesce (sum (t1.variazione_aumento_residuo),0) variazione_aumento_residuo,
                coalesce (sum (t1.variazione_diminuzione_residuo),0) variazione_diminuzione_residuo                                                                                               
			into elemCatCode,variazione_aumento_stanziato, variazione_diminuzione_stanziato,
            	variazione_aumento_cassa, variazione_diminuzione_cassa,variazione_aumento_residuo,
			variazione_diminuzione_residuo 
            from siac_rep_var_spese_riga t1,
            	siac_r_bil_elem_categoria r_cat_capitolo,
                siac_d_bil_elem_categoria cat_del_capitolo            
            WHERE  r_cat_capitolo.elem_id=t1.elem_id
            	AND r_cat_capitolo.elem_cat_id=cat_del_capitolo.elem_cat_id
            	AND t1.utente=user_table
                AND cat_del_capitolo.elem_cat_code=tipo_capitolo.codice_importo
                AND r_cat_capitolo.data_cancellazione IS NULL
                AND cat_del_capitolo.data_cancellazione IS NULL
                AND t1.periodo_anno = tipo_capitolo.anno_competenza
            group by cat_del_capitolo.elem_cat_code   ; 
            IF NOT FOUND THEN
              variazione_aumento_stanziato=0;
              variazione_diminuzione_stanziato=0;
              variazione_aumento_cassa=0;
              variazione_diminuzione_cassa=0;
              variazione_aumento_residuo=0;
              variazione_diminuzione_residuo=0;
            ELSE
            	importo = variazione_aumento_stanziato+variazione_diminuzione_stanziato;               
            END IF;                    
END IF;
            
--raise notice 'anno_competenza=%', tipo_capitolo.anno_competenza;
--raise notice 'codice_importo=%', tipo_capitolo.codice_importo;
--raise notice 'importo=%', tipo_capitolo.importo;
--raise notice 'variazione_aumento_stanziato=%', variazione_aumento_stanziato;
--raise notice 'variazione_diminuzione_stanziato=%', variazione_diminuzione_stanziato;
--raise notice 'variazione_aumento_cassa=%', variazione_aumento_cassa;
--raise notice 'variazione_diminuzione_cassa=%', variazione_diminuzione_cassa;
--raise notice 'variazione_aumento_residuo=%', variazione_aumento_residuo;
--raise notice 'variazione_diminuzione_residuo=%', variazione_diminuzione_residuo;


anno_competenza = tipo_capitolo.anno_competenza;
descrizione = tipo_capitolo.descrizione;
posizione_nel_report = tipo_capitolo.posizione_nel_report;
codice_importo = tipo_capitolo.codice_importo;
tipo_capitolo_cod = tipo_capitolo.tipo_capitolo_cod;

return next;

variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
anno_competenza = '';
descrizione = '';
posizione_nel_report = 0;
codice_importo = '';
tipo_capitolo_cod = '';
importo=0;

end loop;


delete from siac_rep_cap_ep where utente=user_table;
delete from siac_rep_cap_ug where utente=user_table;

delete from siac_rep_var_entrate where utente=user_table;

delete from siac_rep_var_entrate_riga where utente=user_table;

delete from siac_rep_var_spese where utente=user_table;
delete from siac_rep_var_spese_riga where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-8000 - Maurizio - FINE	


-- SIAC-8205 - Maurizio - INIZIO	


--Configurazione reportistica di gestione 2021
--Enti locali.
insert into siac_t_azione (
  azione_code,  azione_desc,
  azione_tipo_id,  
  gruppo_azioni_id,  
  urlapplicazione,  nomeprocesso,  nometask ,  verificauo,
  validita_inizio,  validita_fine,  ente_proprietario_id,
  data_creazione,  data_modifica,  data_cancellazione,  login_operazione)
select 'OP-GESREP1-BilCons-2021', 'Reportistica Gestione 2021 (Enti Locali)',
	(select a.azione_tipo_id from siac_d_azione_tipo a
    	where a.azione_tipo_code='ATTIVITA_SINGOLA'
        	and a.ente_proprietario_id=ente.ente_proprietario_id
            and a.data_cancellazione IS NULL),
    (select b.gruppo_azioni_id from siac_d_gruppo_azioni b
    	where b.gruppo_azioni_code='BIL_CAP_GES'
        	and b.ente_proprietario_id=ente.ente_proprietario_id
            and b.data_cancellazione IS NULL),
    '/../siacrepapp/azioneRichiesta.do', NULL, NULL , FALSE, 
    now(), NULL, ente.ente_proprietario_id,
    now(), now(), NULL, 'SIAC-8205'
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_azione az
        where az.ente_proprietario_id=ente.ente_proprietario_id
        	and az.azione_code='OP-GESREP1-BilCons-2021');  

-- Regione.
insert into   siac_t_azione (
  azione_code,  azione_desc,
  azione_tipo_id,  
  gruppo_azioni_id,  
  urlapplicazione,  nomeprocesso,  nometask ,  verificauo,
  validita_inizio,  validita_fine,  ente_proprietario_id,
  data_creazione,  data_modifica,  data_cancellazione,  login_operazione)
select 'OP-GESREP2-BilCons-2021', 'Reportistica Gestione 2021 (Regione)',
	(select a.azione_tipo_id from siac_d_azione_tipo a
    	where a.azione_tipo_code='ATTIVITA_SINGOLA'
        	and a.ente_proprietario_id=ente.ente_proprietario_id
            and a.data_cancellazione IS NULL),
    (select b.gruppo_azioni_id from siac_d_gruppo_azioni b
    	where b.gruppo_azioni_code='BIL_CAP_GES'
        	and b.ente_proprietario_id=ente.ente_proprietario_id
            and b.data_cancellazione IS NULL),
    '/../siacrepapp/azioneRichiesta.do', NULL, NULL , FALSE, 
    now(), NULL, ente.ente_proprietario_id,
    now(), now(), NULL, 'SIAC-8205'
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_azione az
        where az.ente_proprietario_id=ente.ente_proprietario_id
        	and az.azione_code='OP-GESREP2-BilCons-2021'); 
            
--INSERIMENTO DELLA CONFIGURAZIONE DEI RUOLI COPIANDOLI DALLE CARTELLE 2020.	
insert into siac_r_ruolo_op_azione (
ruolo_op_id ,  azione_id ,  validita_inizio,  validita_fine ,
  ente_proprietario_id ,  data_creazione,  data_modifica ,
  data_cancellazione,  login_operazione )
select ruolo.ruolo_op_id, (select azione_id from siac_t_azione a  
				where a.azione_code='OP-GESREP1-BilCons-2021'
                	and a.ente_proprietario_id=ruolo.ente_proprietario_id
                    and a.data_cancellazione IS NULL), now(), NULL,
       ruolo.ente_proprietario_id, now(), now(),
       NULL, 'SIAC-8205'
from siac_r_ruolo_op_azione ruolo, 
	siac_t_azione az,
    siac_t_ente_proprietario ente
where ruolo.azione_id=az.azione_id
	and ente.ente_proprietario_id=az.ente_proprietario_id
	and az.azione_code='OP-GESREP1-BilCons-2020'
    and ruolo.data_cancellazione IS NULL
    and ruolo.validita_fine IS NULL
    and az.data_cancellazione IS NULL
    and az.validita_fine IS NULL
    and ente.data_cancellazione IS NULL
    and ente.validita_fine IS NULL 
    and not exists (select 1
    	from siac_r_ruolo_op_azione ruolo1, 
			siac_t_azione az1
		where ruolo1.azione_id=az1.azione_id
        	and az1.azione_code='OP-GESREP1-BilCons-2021');		

insert into siac_r_ruolo_op_azione (
ruolo_op_id ,  azione_id ,  validita_inizio,  validita_fine ,
  ente_proprietario_id ,  data_creazione,  data_modifica ,
  data_cancellazione,  login_operazione )
select ruolo.ruolo_op_id, (select azione_id from siac_t_azione a  
				where a.azione_code='OP-GESREP2-BilCons-2021'
                	and a.ente_proprietario_id=ruolo.ente_proprietario_id
                    and a.data_cancellazione IS NULL), now(), NULL,
       ruolo.ente_proprietario_id, now(), now(),
       NULL, 'SIAC-8205'
from siac_r_ruolo_op_azione ruolo, 
	siac_t_azione az,
    siac_t_ente_proprietario ente
where ruolo.azione_id=az.azione_id
	and ente.ente_proprietario_id=az.ente_proprietario_id
	and az.azione_code='OP-GESREP2-BilCons-2020'
    and ruolo.data_cancellazione IS NULL
    and ruolo.validita_fine IS NULL
    and az.data_cancellazione IS NULL
    and az.validita_fine IS NULL
    and ente.data_cancellazione IS NULL
    and ente.validita_fine IS NULL 
    and not exists (select 1
    	from siac_r_ruolo_op_azione ruolo1, 
			siac_t_azione az1
		where ruolo1.azione_id=az1.azione_id
        	and az1.azione_code='OP-GESREP2-BilCons-2021');		 
			

--correggo le descrizioni dei menu'
--Previsione Enti Locali
update siac_t_azione     
set data_modifica = now(),
	login_operazione= login_operazione|| ' - SIAC-8205',
    azione_desc='Reportistica Bilancio di Previsione 2020 (Enti Locali)'
where azione_code='OP-GESREP1-BilPrev-2020'
	and login_operazione not like '%SIAC-8205';
    
update siac_t_azione     
set data_modifica = now(),
	login_operazione= login_operazione|| ' - SIAC-8205',
    azione_desc='Reportistica Bilancio di Previsione 2021 (Enti Locali)'
where azione_code='OP-GESREP1-BilPrev-2021'
	and login_operazione not like '%SIAC-8205';    
    
--Previsione Regione
update siac_t_azione     
set data_modifica = now(),
	login_operazione= login_operazione|| ' - SIAC-8205',
    azione_desc='Reportistica Bilancio di Previsione 2020 (Regione)'
where azione_code='OP-GESREP2-BilPrev-2020'
	and login_operazione not like '%SIAC-8205';
    
update siac_t_azione     
set data_modifica = now(),
	login_operazione= login_operazione|| ' - SIAC-8205',
    azione_desc='Reportistica Bilancio di Previsione 2021 (Regione)'
where azione_code='OP-GESREP2-BilPrev-2021'
	and login_operazione not like '%SIAC-8205';    
        
--Gestione Enti Locali 2016 e 2017    
update siac_t_azione     
set data_modifica = now(),
	login_operazione= login_operazione|| ' - SIAC-8205',
    azione_desc='Reportistica Bilancio di Previsione 2016 (Enti Locali)'
where azione_code='OP-GESREP1-BilCons-2016'
	and login_operazione not like '%SIAC-8205';        
    
update siac_t_azione     
set data_modifica = now(),
	login_operazione= login_operazione|| ' - SIAC-8205',
    azione_desc='Reportistica Bilancio di Previsione 2017 (Enti Locali)'
where azione_code='OP-GESREP1-BilCons-2017'
	and login_operazione not like '%SIAC-8205'; 
	

-- SIAC-8205 - Maurizio - FINE


-- SIAC-8212 - Maurizio - INIZIO

update siac_t_report_importi
set data_modifica=now(),
	login_operazione= login_operazione|| ' - SIAC-8212',
    repimp_codice= 'Colonna E Allegato c) FCDE Rendiconto (indicare la tipologia di interesse, ad esempio 1010400, ed il relativo importo)'
where repimp_codice = 'Colonna E Allegato c) FCDE Rendiconto'
and repimp_id in(select b.repimp_id
  from siac_t_report a,
  siac_t_report_importi b,
  siac_r_report_importi c
  where a.rep_id=c.rep_id
  and b.repimp_id=c.repimp_id
  and  a.rep_codice='BILR148'
  and b.data_cancellazione IS NULL
  and c.data_cancellazione IS NULL)
and login_operazione not like '%SIAC-8212';

CREATE OR REPLACE FUNCTION siac."BILR148_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_cons" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  residui_attivi numeric,
  residui_attivi_prec numeric,
  totale_residui_attivi numeric,
  importo_minimo_fondo numeric,
  bil_ele_code3 varchar,
  flag_cassa integer,
  accertamenti_succ numeric,
  crediti_stralciati numeric,
  fondo_dubbia_esig numeric
) AS
$body$
DECLARE

classifBilRec record;
bilancio_id integer;
annoCapImp_int integer;
tipomedia varchar;
RTN_MESSAGGIO text;
BEGIN
RTN_MESSAGGIO:='select 1';

annoCapImp_int:= p_anno::integer; 

select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id=p_ente_prop_id and 
b.periodo_id=a.periodo_id
and b.anno=p_anno;

select attr_bilancio.testo
into tipomedia from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
siac_r_bil_attr attr_bilancio, siac_t_attr attr
where 
bilancio.periodo_id = anno_eserc.periodo_id and
anno_eserc.anno = 	p_anno and
bilancio.bil_id =  attr_bilancio.bil_id and
attr_bilancio.attr_id= attr.attr_id and
attr.attr_code = 'mediaApplicata' and
attr_bilancio.data_cancellazione is null and
attr_bilancio.ente_proprietario_id=p_ente_prop_id;

if tipomedia is null then
   tipomedia = 'SEMPLICE';
end if;

return query
select zz.* from (
with clas as (
with titent as 
(select 
e.classif_tipo_desc titent_tipo_desc,
a.classif_id titent_id,
a.classif_code titent_code,
a.classif_desc titent_desc,
a.validita_inizio titent_validita_inizio,
a.validita_fine titent_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = '00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
tipologia as
(
select 
e.classif_tipo_desc tipologia_tipo_desc,
b.classif_id_padre titent_id,
a.classif_id tipologia_id,
a.classif_code tipologia_code,
a.classif_desc tipologia_desc,
a.validita_inizio tipologia_validita_inizio,
a.validita_fine tipologia_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = '00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=2
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
categoria as (
select 
e.classif_tipo_desc categoria_tipo_desc,
b.classif_id_padre tipologia_id,
a.classif_id categoria_id,
a.classif_code categoria_code,
a.classif_desc categoria_desc,
a.validita_inizio categoria_validita_inizio,
a.validita_fine categoria_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = '00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=3
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
select 
titent.titent_tipo_desc,
titent.titent_id,
titent.titent_code,
titent.titent_desc,
titent.titent_validita_inizio,
titent.titent_validita_fine,
tipologia.tipologia_tipo_desc,
tipologia.tipologia_id,
tipologia.tipologia_code,
tipologia.tipologia_desc,
tipologia.tipologia_validita_inizio,
tipologia.tipologia_validita_fine,
categoria.categoria_tipo_desc,
categoria.categoria_id,
categoria.categoria_code,
categoria.categoria_desc,
categoria.categoria_validita_inizio,
categoria.categoria_validita_fine,
categoria.ente_proprietario_id
from titent,tipologia,categoria
where titent.titent_id=tipologia.titent_id
and tipologia.tipologia_id=categoria.tipologia_id
),
capall as (
with
cap as (
select
a.elem_id,
a.elem_code,
a.elem_desc,
a.elem_code2,
a.elem_desc2,
a.elem_id_padre,
a.elem_code3,
d.classif_id
from siac_t_bil_elem a,	
     siac_d_bil_elem_tipo b,
     siac_r_bil_elem_class c,
 	 siac_t_class d,	
     siac_d_class_tipo e,
	 siac_r_bil_elem_categoria f,	
     siac_d_bil_elem_categoria g, 
     siac_r_bil_elem_stato h, 
     siac_d_bil_elem_stato i 
where a.ente_proprietario_id = p_ente_prop_id
and   a.bil_id               = bilancio_id
and   a.elem_tipo_id		 = b.elem_tipo_id 
and   b.elem_tipo_code 	     = 'CAP-EG'
and   c.elem_id              = a.elem_id
and   d.classif_id           = c.classif_id
and   e.classif_tipo_id      = d.classif_tipo_id
and   e.classif_tipo_code	 = 'CATEGORIA'
and   g.elem_cat_id          = f.elem_cat_id
and   f.elem_id              = a.elem_id
and	  g.elem_cat_code	     = 'STD'
and   h.elem_id              = a.elem_id
and   i.elem_stato_id        = h.elem_stato_id
and	  i.elem_stato_code	     = 'VA'
and   a.data_cancellazione   is null
and	  b.data_cancellazione   is null
and	  c.data_cancellazione	 is null
and	  d.data_cancellazione	 is null
and	  e.data_cancellazione 	 is null
and	  f.data_cancellazione 	 is null
and	  g.data_cancellazione	 is null
and	  h.data_cancellazione   is null
and	  i.data_cancellazione   is null
), 
resatt as ( -- Residui Attivi 
select capitolo.elem_id,
       sum (dt_movimento.movgest_ts_det_importo) residui_accertamenti,
       CASE 
         WHEN movimento.movgest_anno < annoCapImp_int AND dt_mov_tipo.movgest_ts_det_tipo_code = 'I' THEN
            'RESATT' 
         WHEN movimento.movgest_anno = annoCapImp_int AND dt_mov_tipo.movgest_ts_det_tipo_code = 'A' THEN  
            'ACCERT' 
         ELSE
            'ALTRO'
       END tipo_importo         
from siac_t_bil_elem                  capitolo
inner join siac_r_movgest_bil_elem    r_mov_capitolo on r_mov_capitolo.elem_id = capitolo.elem_id
inner join siac_d_bil_elem_tipo       t_capitolo on capitolo.elem_tipo_id = t_capitolo.elem_tipo_id
inner join siac_t_movgest             movimento on r_mov_capitolo.movgest_id = movimento.movgest_id 
inner join siac_d_movgest_tipo        tipo_mov on movimento.movgest_tipo_id = tipo_mov.movgest_tipo_id 
inner join siac_t_movgest_ts          ts_movimento on movimento.movgest_id = ts_movimento.movgest_id 
inner join siac_r_movgest_ts_stato    r_movimento_stato on ts_movimento.movgest_ts_id = r_movimento_stato.movgest_ts_id 
inner join siac_d_movgest_stato       tipo_stato on r_movimento_stato.movgest_stato_id = tipo_stato.movgest_stato_id
inner join siac_t_movgest_ts_det      dt_movimento on ts_movimento.movgest_ts_id = dt_movimento.movgest_ts_id 
inner join siac_d_movgest_ts_tipo     ts_mov_tipo on ts_movimento.movgest_ts_tipo_id = ts_mov_tipo.movgest_ts_tipo_id
inner join siac_d_movgest_ts_det_tipo dt_mov_tipo on dt_movimento.movgest_ts_det_tipo_id = dt_mov_tipo.movgest_ts_det_tipo_id 
where capitolo.ente_proprietario_id     =   p_ente_prop_id
and   capitolo.bil_id      				=	bilancio_id
and   t_capitolo.elem_tipo_code    		= 	'CAP-EG'
and   movimento.movgest_anno 	        <= 	annoCapImp_int
and   movimento.bil_id					=	bilancio_id
and   tipo_mov.movgest_tipo_code    	=   'A' 
and   tipo_stato.movgest_stato_code     in  ('D','N')
and   ts_mov_tipo.movgest_ts_tipo_code  =   'T'
and   dt_mov_tipo.movgest_ts_det_tipo_code in ('I','A')
and   capitolo.data_cancellazione     	is null 
and   r_mov_capitolo.data_cancellazione is null 
and   t_capitolo.data_cancellazione    	is null 
and   movimento.data_cancellazione     	is null 
and   tipo_mov.data_cancellazione     	is null 
and   r_movimento_stato.data_cancellazione is null 
and   ts_movimento.data_cancellazione   is null 
and   tipo_stato.data_cancellazione    	is null 
and   dt_movimento.data_cancellazione   is null 
and   ts_mov_tipo.data_cancellazione    is null 
and   dt_mov_tipo.data_cancellazione    is null
and   now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
and   now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
group by tipo_importo, capitolo.elem_id
),
resrisc as ( -- Riscossione residui
select 		r_capitolo_ordinativo.elem_id,
            sum(ordinativo_imp.ord_ts_det_importo) importo_residui,
            CASE 
             WHEN movimento.movgest_anno < annoCapImp_int THEN
                'RISRES'
             ELSE
                'RISCOMP'
             END tipo_importo                    
from  --siac_t_bil 						bilancio,
      --siac_t_periodo 					anno_eserc, 
      siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
      siac_t_ordinativo				    ordinativo,
      siac_d_ordinativo_tipo			tipo_ordinativo,
      siac_r_ordinativo_stato			r_stato_ordinativo,
      siac_d_ordinativo_stato			stato_ordinativo,
      siac_t_ordinativo_ts 			    ordinativo_det,
      siac_t_ordinativo_ts_det 		    ordinativo_imp,
      siac_d_ordinativo_ts_det_tipo 	ordinativo_imp_tipo,
      siac_t_movgest     				movimento,
      siac_t_movgest_ts    			    ts_movimento, 
      siac_r_ordinativo_ts_movgest_ts	r_ordinativo_movgest
where 	--anno_eserc.anno					= 	p_anno											
--and	bilancio.periodo_id					=	anno_eserc.periodo_id
--and	bilancio.ente_proprietario_id	    =	p_ente_prop_id
ordinativo_det.ente_proprietario_id	    =	p_ente_prop_id
and	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
and	tipo_ordinativo.ord_tipo_code		= 	'I'	-- Incasso
and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
------------------------------------------------------------------------------------------		
----------------------    LO STATO DEVE ESSERE MODIFICATO IN Q  --- QUIETANZATO    ------		
and	stato_ordinativo.ord_stato_code			<> 'A' -- Annullato
-----------------------------------------------------------------------------------------------
--and	ordinativo.bil_id					=	bilancio.bil_id
and	ordinativo.bil_id					=	bilancio_id
and	ordinativo.ord_id					=	ordinativo_det.ord_id
and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' 	-- Importo attuale
---------------------------------------------------------------------------------------------------------------------
and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
and	ts_movimento.movgest_id				=	movimento.movgest_id
and	movimento.movgest_anno				<=	annoCapImp_int	
--and movimento.bil_id					=	bilancio.bil_id	
and movimento.bil_id					=	bilancio_id	
--------------------------------------------------------------------------------------------------------------------		
--and	bilancio.data_cancellazione 				is null
--and	anno_eserc.data_cancellazione 				is null
and	r_capitolo_ordinativo.data_cancellazione	is null
and	ordinativo.data_cancellazione				is null
and	tipo_ordinativo.data_cancellazione			is null
and	r_stato_ordinativo.data_cancellazione		is null
and	stato_ordinativo.data_cancellazione			is null
and ordinativo_det.data_cancellazione			is null
and ordinativo_imp.data_cancellazione			is null
and ordinativo_imp_tipo.data_cancellazione		is null
and	movimento.data_cancellazione				is null
and	ts_movimento.data_cancellazione				is null
and	r_ordinativo_movgest.data_cancellazione		is null
and now() between r_capitolo_ordinativo.validita_inizio and COALESCE(r_capitolo_ordinativo.validita_fine,now())
and now() between r_stato_ordinativo.validita_inizio and COALESCE(r_stato_ordinativo.validita_fine,now())
and now() between r_ordinativo_movgest.validita_inizio and COALESCE(r_ordinativo_movgest.validita_fine,now())
group by tipo_importo, r_capitolo_ordinativo.elem_id
),
resriacc as ( -- Riaccertamenti residui
select capitolo.elem_id,
       sum (t_movgest_ts_det_mod.movgest_ts_det_importo) riaccertamenti_residui
from --siac_t_bil      bilancio, 
     --siac_t_periodo     anno_eserc, 
     siac_t_bil_elem     capitolo , 
     siac_r_movgest_bil_elem   r_mov_capitolo, 
     siac_d_bil_elem_tipo    t_capitolo, 
     siac_t_movgest     movimento, 
     siac_d_movgest_tipo    tipo_mov, 
     siac_t_movgest_ts    ts_movimento, 
     siac_r_movgest_ts_stato   r_movimento_stato, 
     siac_d_movgest_stato    tipo_stato, 
     siac_t_movgest_ts_det   dt_movimento, 
     siac_d_movgest_ts_tipo   ts_mov_tipo, 
     siac_d_movgest_ts_det_tipo  dt_mov_tipo ,
     siac_t_modifica t_modifica,
     siac_r_modifica_stato r_mod_stato,
     siac_d_modifica_stato d_mod_stato,
     siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
     where --bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
     --and anno_eserc.anno       			=   p_anno
     --and bilancio.bil_id      				=	capitolo.bil_id
     capitolo.bil_id      				=	bilancio_id
     and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
     and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
     and movimento.movgest_anno 	< 	annoCapImp_int
     --and movimento.bil_id					=	bilancio.bil_id
     and movimento.bil_id					=	bilancio_id
     and r_mov_capitolo.elem_id    		=	capitolo.elem_id
     and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
     and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
     and tipo_mov.movgest_tipo_code    	= 'A' 
     and movimento.movgest_id      		= 	ts_movimento.movgest_id 
     and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
     and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
     and tipo_stato.movgest_stato_code   in ('D','N')
     and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
     and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
     and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
     and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
     and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' -- Importo attuale 
     and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
     and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
     and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
     and d_mod_stato.mod_stato_code='V'
     and r_mod_stato.mod_id=t_modifica.mod_id
     and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
     and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
     and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
     --and anno_eserc.data_cancellazione    	is null 
     --and bilancio.data_cancellazione     	is null 
     and capitolo.data_cancellazione     	is null 
     and r_mov_capitolo.data_cancellazione is null 
     and t_capitolo.data_cancellazione    	is null 
     and movimento.data_cancellazione     	is null 
     and tipo_mov.data_cancellazione     	is null 
     and r_movimento_stato.data_cancellazione   is null 
     and ts_movimento.data_cancellazione   is null 
     and tipo_stato.data_cancellazione    	is null 
     and dt_movimento.data_cancellazione   is null 
     and ts_mov_tipo.data_cancellazione    is null 
     and dt_mov_tipo.data_cancellazione    is null
     and t_movgest_ts_det_mod.data_cancellazione    is null
     and r_mod_stato.data_cancellazione    is null
     and t_modifica.data_cancellazione    is null
     and capitolo.ente_proprietario_id   = p_ente_prop_id
     group by capitolo.elem_id	
),
minfondo as ( -- Importo minimo del fondo
SELECT
 rbilelem.elem_id, 
 CASE 
   WHEN tipomedia = 'SEMPLICE' THEN
        round((COALESCE(datifcd.perc_acc_fondi,0)+
        COALESCE(datifcd.perc_acc_fondi_1,0)+
        COALESCE(datifcd.perc_acc_fondi_2,0)+
        COALESCE(datifcd.perc_acc_fondi_3,0)+
        COALESCE(datifcd.perc_acc_fondi_4,0))/5,2)
   ELSE
        round((COALESCE(datifcd.perc_acc_fondi,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_1,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_2,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_3,0)*0.35+
        COALESCE(datifcd.perc_acc_fondi_4,0)*0.35),2)
 END perc_media
 -- ,1 flag_cassa -- SIAC-5854
 , 1 flag_fondo -- SIAC-5854
 FROM siac_t_acc_fondi_dubbia_esig datifcd, siac_r_bil_elem_acc_fondi_dubbia_esig rbilelem
 WHERE rbilelem.acc_fde_id = datifcd.acc_fde_id 
 AND   datifcd.ente_proprietario_id = p_ente_prop_id 
 AND   rbilelem.data_cancellazione is null
),
accertcassa as ( -- Accertato per cassa -- SIAC-5854
SELECT rbea.elem_id, 0 flag_cassa
FROM   siac_r_bil_elem_attr rbea, siac_t_attr ta
WHERE  rbea.attr_id = ta.attr_id
AND    rbea.data_cancellazione is null
AND    ta.data_cancellazione is null
AND    ta.attr_code = 'FlagAccertatoPerCassa'
AND    ta.ente_proprietario_id = p_ente_prop_id
AND    rbea."boolean" = 'S'
),
acc_succ as ( -- Accertamenti imputati agli esercizi successivi a quello cui il rendiconto si riferisce
select capitolo.elem_id,
       --sum (t_movgest_ts_det_mod.movgest_ts_det_importo) accertamenti_succ
       sum (dt_movimento.movgest_ts_det_importo) accertamenti_succ
from --siac_t_bil      bilancio, 
     --siac_t_periodo     anno_eserc, 
     siac_t_bil_elem     capitolo , 
     siac_r_movgest_bil_elem   r_mov_capitolo, 
     siac_d_bil_elem_tipo    t_capitolo, 
     siac_t_movgest     movimento, 
     siac_d_movgest_tipo    tipo_mov, 
     siac_t_movgest_ts    ts_movimento, 
     siac_r_movgest_ts_stato   r_movimento_stato, 
     siac_d_movgest_stato    tipo_stato, 
     siac_t_movgest_ts_det   dt_movimento, 
     siac_d_movgest_ts_tipo   ts_mov_tipo, 
     siac_d_movgest_ts_det_tipo  dt_mov_tipo 
     --,siac_t_modifica t_modifica,
     --siac_r_modifica_stato r_mod_stato,
     --siac_d_modifica_stato d_mod_stato,
     --siac_t_movgest_ts_det_mod t_movgest_ts_det_mod--,
     --siac_r_movgest_ts_attr r_movgest_ts_attr,
     --siac_t_attr t_attr 
     where --bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
     --and anno_eserc.anno       			=   p_anno
     --and bilancio.bil_id      				=	capitolo.bil_id
     capitolo.bil_id      				=	bilancio_id
     and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
     and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
     and movimento.movgest_anno 	> 	annoCapImp_int
     --and movimento.bil_id					=	bilancio.bil_id
     and movimento.bil_id					=	bilancio_id
     and r_mov_capitolo.elem_id    		=	capitolo.elem_id
     and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
     and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
     and tipo_mov.movgest_tipo_code    	= 'A' 
     and movimento.movgest_id      		= 	ts_movimento.movgest_id 
     and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
     and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
     and tipo_stato.movgest_stato_code   in ('D','N')
     and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
     and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
     and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
     and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
     and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' -- Importo attuale 
     --and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
     --and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
     --and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
     --and d_mod_stato.mod_stato_code='V'
     --and r_mod_stato.mod_id=t_modifica.mod_id
     --and r_movgest_ts_attr.movgest_ts_id = ts_movimento.movgest_ts_id
     --and r_movgest_ts_attr.attr_id = t_attr.attr_id
     --and t_attr.attr_code = 'annoOriginePlur'
     --and r_movgest_ts_attr.testo <= p_anno
     and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
     and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
     --and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
     --and anno_eserc.data_cancellazione    	is null 
     --and bilancio.data_cancellazione     	is null 
     and capitolo.data_cancellazione     	is null 
     and r_mov_capitolo.data_cancellazione is null 
     and t_capitolo.data_cancellazione    	is null 
     and movimento.data_cancellazione     	is null 
     and tipo_mov.data_cancellazione     	is null 
     and r_movimento_stato.data_cancellazione   is null 
     and ts_movimento.data_cancellazione   is null 
     and tipo_stato.data_cancellazione    	is null 
     and dt_movimento.data_cancellazione   is null 
     and ts_mov_tipo.data_cancellazione    is null 
     and dt_mov_tipo.data_cancellazione    is null
     --and t_movgest_ts_det_mod.data_cancellazione    is null
     --and r_mod_stato.data_cancellazione    is null
     --and t_modifica.data_cancellazione    is null
     and capitolo.ente_proprietario_id   = p_ente_prop_id
     group by capitolo.elem_id	
),
cred_stra as ( -- Crediti stralciati
 select    
   capitolo.elem_id,
   abs(sum (t_movgest_ts_det_mod.movgest_ts_det_importo)) crediti_stralciati
    from 
      siac_t_bil      bilancio, 
      siac_t_periodo     anno_eserc, 
      siac_t_bil_elem     capitolo , 
      siac_r_movgest_bil_elem   r_mov_capitolo, 
      siac_d_bil_elem_tipo    t_capitolo, 
      siac_t_movgest     movimento, 
      siac_d_movgest_tipo    tipo_mov, 
      siac_t_movgest_ts    ts_movimento, 
      siac_r_movgest_ts_stato   r_movimento_stato, 
      siac_d_movgest_stato    tipo_stato, 
      siac_t_movgest_ts_det   dt_movimento, 
      siac_d_movgest_ts_tipo   ts_mov_tipo, 
      siac_d_movgest_ts_det_tipo  dt_mov_tipo ,
      siac_t_modifica t_modifica,
      siac_d_modifica_tipo d_modif_tipo,
      siac_r_modifica_stato r_mod_stato,
      siac_d_modifica_stato d_mod_stato,
      siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
      where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
      and anno_eserc.anno       			=   p_anno
      and bilancio.bil_id      				=	capitolo.bil_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      and movimento.movgest_anno 	        <= 	annoCapImp_int
      and movimento.bil_id					=	bilancio.bil_id
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and tipo_mov.movgest_tipo_code    	= 'A' 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
      and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
      and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
      and d_mod_stato.mod_stato_code='V'
      and r_mod_stato.mod_id=t_modifica.mod_id
      and d_modif_tipo.mod_tipo_id = t_modifica.mod_tipo_id
      /*and ((d_modif_tipo.mod_tipo_code in ('CROR','ECON') and p_anno <= '2016')
            or
           (d_modif_tipo.mod_tipo_code like 'FCDE%' and p_anno >= '2017')
          ) */
      and d_modif_tipo.mod_tipo_code in ('CROR','ECON')    
      and t_movgest_ts_det_mod.movgest_ts_det_importo < 0
      and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
 	  and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
	  and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
      and anno_eserc.data_cancellazione    	is null 
      and bilancio.data_cancellazione     	is null 
      and capitolo.data_cancellazione     	is null 
      and r_mov_capitolo.data_cancellazione is null 
      and t_capitolo.data_cancellazione    	is null 
      and movimento.data_cancellazione     	is null 
      and tipo_mov.data_cancellazione     	is null 
      and r_movimento_stato.data_cancellazione   is null 
      and ts_movimento.data_cancellazione   is null 
      and tipo_stato.data_cancellazione    	is null 
      and dt_movimento.data_cancellazione   is null 
      and ts_mov_tipo.data_cancellazione    is null 
      and dt_mov_tipo.data_cancellazione    is null
      and t_movgest_ts_det_mod.data_cancellazione    is null
      and r_mod_stato.data_cancellazione    is null
      and t_modifica.data_cancellazione    is null
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id
group by capitolo.elem_id
)
select 
cap.elem_id bil_ele_id,
cap.elem_code bil_ele_code,
cap.elem_desc bil_ele_desc,
cap.elem_code2 bil_ele_code2,
cap.elem_desc2 bil_ele_desc2,
cap.elem_id_padre bil_ele_id_padre,
cap.elem_code3 bil_ele_code3,
cap.classif_id categoria_id,
coalesce(resatt1.residui_accertamenti,0) residui_attivi,
(coalesce(resatt1.residui_accertamenti,0) -
coalesce(resrisc1.importo_residui,0) +
coalesce(resriacc.riaccertamenti_residui,0)) residui_attivi_prec,
coalesce(minfondo.perc_media,0) perc_media,
-- minfondo.flag_cassa, -- SIAC-5854
coalesce(minfondo.flag_fondo,0) flag_fondo, -- SIAC-5854
coalesce(accertcassa.flag_cassa,1) flag_cassa, -- SIAC-5854
coalesce(acc_succ.accertamenti_succ,0) accertamenti_succ,
coalesce(cred_stra.crediti_stralciati,0) crediti_stralciati,
coalesce(resrisc2.importo_residui,0) residui_competenza,
coalesce(resatt2.residui_accertamenti,0) accertamenti,
(coalesce(resatt2.residui_accertamenti,0) -
 coalesce(resrisc2.importo_residui,0)) importo_finale
from cap
left join resatt resatt1
on cap.elem_id=resatt1.elem_id and resatt1.tipo_importo = 'RESATT'
left join resatt resatt2
on cap.elem_id=resatt2.elem_id and resatt2.tipo_importo = 'ACCERT'
left join resrisc resrisc1
on cap.elem_id=resrisc1.elem_id and resrisc1.tipo_importo = 'RISRES'
left join resrisc resrisc2
on cap.elem_id=resrisc2.elem_id and resrisc2.tipo_importo = 'RISCOMP'
left join resriacc
on cap.elem_id=resriacc.elem_id
left join minfondo
on cap.elem_id=minfondo.elem_id
left join accertcassa
on cap.elem_id=accertcassa.elem_id
left join acc_succ
on cap.elem_id=acc_succ.elem_id
left join cred_stra
on cap.elem_id=cred_stra.elem_id
),
fondo_dubbia_esig as (
select  importi.repimp_desc programma_code,
        coalesce(importi.repimp_importo,0) imp_fondo_dubbia_esig
from 	siac_t_report					report,
		siac_t_report_importi 			importi,
		siac_r_report_importi 			r_report_importi,
		siac_t_bil 						bilancio,
	 	siac_t_periodo 					anno_eserc,
        siac_t_periodo 					anno_comp
where 	report.rep_codice				=	'BILR148'   				
and     report.ente_proprietario_id		=	p_ente_prop_id				
and		anno_eserc.anno					=	p_anno 						
and     bilancio.periodo_id				=	anno_eserc.periodo_id 		
and     importi.bil_id					=	bilancio.bil_id 			
and     r_report_importi.rep_id			=	report.rep_id				
and     r_report_importi.repimp_id		=	importi.repimp_id			
and     importi.periodo_id 				=	anno_comp.periodo_id
and     report.data_cancellazione is null
and     importi.data_cancellazione is null
and     r_report_importi.data_cancellazione is null
and     anno_eserc.data_cancellazione is null
and     anno_comp.data_cancellazione is null
and     importi.repimp_desc <> ''
--24/05/2021 SIAC-8212.
--Cambiato il codice che identifica le variabili per aggiungere una nota utile
--all'utente per la compilazione degli importi.
--and     importi.repimp_codice = 'Colonna E Allegato c) FCDE Rendiconto'
and importi.repimp_codice like 'Colonna E Allegato c) FCDE Rendiconto%'
)
select 
p_anno::varchar bil_anno,
''::varchar titent_tipo_code,
clas.titent_tipo_desc::varchar,
clas.titent_code::varchar,
clas.titent_desc::varchar,
''::varchar tipologia_tipo_code,
clas.tipologia_tipo_desc::varchar,
clas.tipologia_code::varchar,
clas.tipologia_desc::varchar,
''::varchar	categoria_tipo_code,
clas.categoria_tipo_desc::varchar,
clas.categoria_code::varchar,
clas.categoria_desc::varchar,
capall.bil_ele_code::varchar,
capall.bil_ele_desc::varchar,
capall.bil_ele_code2::varchar,
capall.bil_ele_desc2::varchar,
capall.bil_ele_id::integer,
capall.bil_ele_id_padre::integer,
COALESCE(capall.importo_finale::numeric,0) residui_attivi,
COALESCE(capall.residui_attivi_prec::numeric,0) residui_attivi_prec,
COALESCE(capall.importo_finale::numeric + capall.residui_attivi_prec::numeric,0) totale_residui_attivi,
CASE
 --WHEN perc_media::numeric <> 0 THEN
 WHEN capall.flag_cassa::numeric = 1 AND capall.flag_fondo::numeric = 1 THEN
  COALESCE(round((capall.importo_finale::numeric + capall.residui_attivi_prec::numeric) * (1 - perc_media::numeric/100),2),0)
 ELSE
 0
END 
importo_minimo_fondo,
capall.bil_ele_code3::varchar,
--COALESCE(capall.flag_cassa::integer,0) flag_cassa, -- SAIC-5854
COALESCE(capall.flag_cassa::integer,1) flag_cassa, -- SAIC-5854       
COALESCE(capall.accertamenti_succ::numeric,0) accertamenti_succ,
COALESCE(capall.crediti_stralciati::numeric,0) crediti_stralciati,
imp_fondo_dubbia_esig
from clas 
left join capall on clas.categoria_id = capall.categoria_id  
left join fondo_dubbia_esig on fondo_dubbia_esig.programma_code = clas.tipologia_code   
) as zz;

/*raise notice 'query: %',queryfin;
RETURN QUERY queryfin;*/

    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
    return;
    when others  THEN
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-8212 - Maurizio - FINE


-- SIAC-8213 24.05.2021 Sofia - inizio 
drop FUNCTION if exists fnc_pagopa_t_elaborazione_riconc_insert
(
  filepagopaid integer,
  filepagopaFileXMLId     varchar,
  filepagopaFileOra       varchar,
  filepagopaFileEnte      varchar,
  filepagopaFileFruitore  varchar,
  inPagoPaElabId          integer,
  annoBilancioElab        integer,
  enteproprietarioid      integer,
  loginoperazione         varchar,
  dataelaborazione        timestamp,
  out outPagoPaElabId     integer,
  out codicerisultato     integer,
  out messaggiorisultato  varchar
);


CREATE OR REPLACE FUNCTION fnc_pagopa_t_elaborazione_riconc_insert
(
  filepagopaid integer,
  filepagopaFileXMLId     varchar,
  filepagopaFileOra       varchar,
  filepagopaFileEnte      varchar,
  filepagopaFileFruitore  varchar,
  inPagoPaElabId          integer,
  annoBilancioElab        integer,
  enteproprietarioid      integer,
  loginoperazione         varchar,
  dataelaborazione        timestamp,
  out outPagoPaElabId     integer,
  out codicerisultato     integer,
  out messaggiorisultato  varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
    strMessaggioBck  VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
	strErrore VARCHAR(1500):='';
    strMessaggioLog VARCHAR(2500):='';
	codResult integer:=null;
	annoBilancio integer:=null;

    -- stati ammessi per procedere con elaborazione
    -- file XML caricato correttamente pronto x elaborazione
	ACQUISITO_ST              CONSTANT  varchar :='ACQUISITO';
    -- file XML caricato correttamente, elaborazione in corso, flussi in fase di elaborazione
    ELABORATO_IN_CORSO_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO'; -- senza errori  e scarti
    ELABORATO_IN_CORSO_ER_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_ER';  -- con errori
    ELABORATO_IN_CORSO_SC_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_SC'; -- con scarti
    -- stati ammessi per procedere con elaborazione

    -- stati per chiusura con errore
    ELABORATO_SCARTATO_ST     CONSTANT  varchar :='ELABORATO_SCARTATO';
    ELABORATO_ERRATO_ST       CONSTANT  varchar :='ELABORATO_ERRATO';
    ANNULLATO_ST              CONSTANT  varchar :='ANNULLATO';
	RIFIUTATO_ST              CONSTANT  varchar :='RIFIUTATO';
    -- stati per chiusura con errore

    -- stati per chiusura con successo con o senza scarti
    -- file XML caricato, ELABORAZIONE TERMINATA E CONCLUSA
    ELABORATO_OK_ST           CONSTANT  varchar :='ELABORATO_OK'; -- documenti  emessi
    ELABORATO_KO_ST           CONSTANT  varchar :='ELABORATO_KO'; -- documenti emessi - presenza di errori-scarti
    -- stati per chiusura con successo con o senza scarti

	ESERCIZIO_PROVVISORIO_ST CONSTANT  varchar :='E'; -- esercizio provvisorio
    ESERCIZIO_GESTIONE_ST    CONSTANT  varchar :='G'; -- esercizio gestione

	-- errori di elaborazione su dettagli
	PAGOPA_ERR_1	CONSTANT  varchar :='1'; --ANNULLATO
	PAGOPA_ERR_2	CONSTANT  varchar :='2'; --SCARTATO
	PAGOPA_ERR_3	CONSTANT  varchar :='3'; --ERRORE GENERICO
	PAGOPA_ERR_4	CONSTANT  varchar :='4'; --FILE NON ESISTENTE O STATO NON RICHIESTO
	PAGOPA_ERR_5	CONSTANT  varchar :='5'; --FILE CARICATO DIVERSE VOLTE PER filepagopaFileXMLId
	PAGOPA_ERR_6	CONSTANT  varchar :='6'; --DATI DI RICONCILIAZIONE NON PRESENTI
	PAGOPA_ERR_7	CONSTANT  varchar :='7'; --DATI DI RICONCILIAZIONE DA ELABORARE NON PRESENTI
	PAGOPA_ERR_8	CONSTANT  varchar :='8'; --DATI DI RICONCILIAZIONE NON PRESENTI PER filepagopaFileXMLId
	PAGOPA_ERR_9	CONSTANT  varchar :='9'; --DATI DI RICONCILIAZIONE PRESENTI PER DIVERSO FILE E STESSO filepagopaFileXMLId
	PAGOPA_ERR_10	CONSTANT  varchar :='10';--DATI DI RICONCILIAZIONE ASSOCIATI A DIVERSI VALORI DI ANNO ESERCIZIO
	PAGOPA_ERR_11	CONSTANT  varchar :='11';--DATI DI RICONCILIAZIONE ASSOCIATI A ANNO ESERCIZIO SUCCESSIVO A ANNO BILANCIO
	PAGOPA_ERR_12	CONSTANT  varchar :='12';--DATI DI RICONCILIAZIONE SENZA ANNO ESERCIZIO INDICATO
	PAGOPA_ERR_13	CONSTANT  varchar :='13';--DATI DI RICONCILIAZIONE SENZA ESTREMI PROVVISORIO DI CASSA
	PAGOPA_ERR_14	CONSTANT  varchar :='14';--DATI DI RICONCILIAZIONE SENZA ESTREMI ACCERTAMENTO
	PAGOPA_ERR_15	CONSTANT  varchar :='15';--DATI DI RICONCILIAZIONE SENZA ESTREMI VOCE/SOTTOVOCE
	PAGOPA_ERR_16	CONSTANT  varchar :='16';--DATI DI RICONCILIAZIONE SENZA IMPORTO
	PAGOPA_ERR_17	CONSTANT  varchar :='17';--ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FILE
	PAGOPA_ERR_18	CONSTANT  varchar :='18';--ANNO BILANCIO DI ELABORAZIONE NON ESISTENTE O FASE NON AMMESSA
	PAGOPA_ERR_19	CONSTANT  varchar :='19';--ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FLUSSO DI RICONCILIAZIONE
	PAGOPA_ERR_20	CONSTANT  varchar :='20';--DATI DI ELABORAZIONE NON ESISTENTI O IN STATO NON AMMESSO
	PAGOPA_ERR_21	CONSTANT  varchar :='21';--ERRORE IN INSERIMENTO DATI DI DETTAGLIO ELABORAZIONE FLUSSO DI RICONCILIAZIONE
	PAGOPA_ERR_22	CONSTANT  varchar :='22';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA NON ESISTENTE
	PAGOPA_ERR_23	CONSTANT  varchar :='23';--DATI DI RICONCILIAZIONE ASSOCIATI A ACCERTAMENTO NON ESISTENTE
  	PAGOPA_ERR_24	CONSTANT  varchar :='24';--TIPO DOCUMENTO IPA NON ESISTENTE
    PAGOPA_ERR_25   CONSTANT  varchar :='25';--BOLLO ESENTE NON ESISTENTE
    PAGOPA_ERR_26   CONSTANT  varchar :='26';--STATO VALIDO DOCUMENTO NON ESISTENTE
    PAGOPA_ERR_27   CONSTANT  varchar :='27';--IDENTIFICATIVO CDC/CDR NON ESISTENTE
    PAGOPA_ERR_28   CONSTANT  varchar :='28';--IDENTIFICATIVO TIPO QUOTA DOCUMENTO NON ESISTENTE
    PAGOPA_ERR_29   CONSTANT  varchar :='29';--IDENTIFICATIVI VARI INESISTENTI
    PAGOPA_ERR_30   CONSTANT  varchar :='30';--ERRORE IN FASE DI INSERIMENTO DOCUMENTO
	PAGOPA_ERR_31   CONSTANT  varchar :='31';--ERRORE IN FASE DI ADEGUAMENTO IMPORTO ACCERTAMENTO
    PAGOPA_ERR_32   CONSTANT  varchar :='32';--ERRORE IN FASE DI VERIFICA DISPONIBILITA PROVVOSORIO DI CASSA
    PAGOPA_ERR_33   CONSTANT  varchar :='33';--DISPONIBILITA INSUFFICIENTE PER PROVVOSORIO DI CASSA
    PAGOPA_ERR_34   CONSTANT  varchar :='34';--DATI DI RICONCILIAZIONE ASSOCIATI A SOGGETTO NON ESISTENTE
    PAGOPA_ERR_35   CONSTANT  varchar :='35';--DATI DI RICONCILIAZIONE ASSOCIATI A STRUTTURA AMMINISTRATIVA NON ESISTENTE
    PAGOPA_ERR_36   CONSTANT  varchar :='36';--DATI DI RICONCILIAZIONE SCARTATI PER ANOMALIA SU GENERAZIONE DOC. PER PROV. CASSA

    PAGOPA_ERR_37   CONSTANT  varchar :='37';--ERRORE IN LETTURA PROGRESSIVI DOCUMENTI
    PAGOPA_ERR_38   CONSTANT  varchar :='38';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA REGOLARIZZATO
    PAGOPA_ERR_39   CONSTANT  varchar :='39';--PROVVISORIO DI CASSA REGOLARIZZATO

    PAGOPA_ERR_40   CONSTANT  varchar :='40';--PROVVISORIO DI CASSA REGOLARIZZATO
    -- 31.05.2019 siac-6720
	PAGOPA_ERR_41   CONSTANT  varchar :='41';--ESTREMI SOGGETTO NON PRESENTI PER DETTAGLIO
 	PAGOPA_ERR_47   CONSTANT  varchar :='47';--ERRORE IN LETTURA IDENTIFICATIVO ATTRIBUTI ACCERTAMENTO

    PAGOPA_ERR_48   CONSTANT  varchar :='48';--TIPO DOCUMENTO NON PRESENTE SU DATI DI RICONCILIAZIONE
    PAGOPA_ERR_49   CONSTANT  varchar :='49';--DETTAGLI NON PRESENTI SU DATI DI RICONCILIAZIONE CON DETT

    -- 30.05.2019 siac-6720
  	DOC_TIPO_IPA    CONSTANT  varchar :='IPA';
    DOC_TIPO_COR    CONSTANT  varchar :='COR';
    DOC_TIPO_FAT    CONSTANT  varchar :='FTV';


    FL_COLL_FATT_ATTR CONSTANT varchar :='FlagCollegamentoAccertamentoFattura';
    FL_COLL_CORR_ATTR CONSTANT varchar :='FlagCollegamentoAccertamentoCorrispettivo';

	docTipoIpaId integer :=null;
    docTipoFatId integer :=null;
    docTipoCorId integer :=null;

    attrAccFatturaId integer:=null;
    attrAccCorrispettivoId integer:=null;


    filePagoPaElabId integer:=null;

    pagoPaFlussoAnnoEsercizio integer:=null;
    pagoPaFlussoNomeMittente  varchar(500):=null;
    pagoPaFlussoData  varchar(50):=null;
    pagoPaFlussoTotPagam  numeric:=null;

    pagoPaFlussoRec record;

    pagopaElabFlussoId integer:=null;
    strNote varchar(500):=null;

    bilancioId integer:=null;
    periodoid integer:=null;
    pagoPaErrCode varchar(10):=null;

BEGIN

    if coalesce(filepagopaFileXMLId,'')='' THEN
     strMessaggioFinale:='Elaborazione PAGOPA per file_pagopa_id='||filepagopaid::varchar||'.';
    else
	 strMessaggioFinale:='Elaborazione PAGOPA per file_pagopa_id='||filepagopaid::varchar
                       ||' filepagopaFileXMLId='||coalesce(filepagopaFileXMLId,' ')||'.';
    end if;

    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale;
--    raise notice 'strMessaggioLog=% ',strMessaggioLog;
	insert into pagopa_t_elaborazione_log
    (
     pagopa_elab_id,
     pagopa_elab_file_id,
     pagopa_elab_log_operazione,
     ente_proprietario_id,
     login_operazione,
     data_creazione
    )
    values
    (
     inPagoPaElabId,
     filepagopaid,
     strMessaggioLog,
	 enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );

   	outPagoPaElabId:=null;
    codiceRisultato:=0;
    messaggioRisultato:='';

    if coalesce(inPagoPaElabId,0)!=0 then
    	outPagoPaElabId:=inPagoPaElabId;
        filePagoPaElabId:=inPagoPaElabId;
    end if;


    ---------- inizio controlli su siac_t_file_pagopa e piano_t_riconciliazione  --------------------------------
	-- verifica esistenza file_pagopa per filePagoPaId passato
    -- un file XML puo essere in stato
    -- ACQUISITO - dati XML flussi caricati - pronti per inizio elaborazione
    -- ELABORATO_IN_CORSO* - dati XML flussi caricati - elaborazione in corso
    -- ELABORATO_OK - dati XML flussi elaborati e conclusi correttamente
    -- ANNULLATO, RIFIUTATO  - errore - file chiuso

   strMessaggio:='Verifica esistenza filePagoPa da elaborare per filePagoPaid e filepagopaFileXMLId.';
   codResult:=null;
   select 1 into codResult
   from siac_t_file_pagopa pagopa,siac_d_file_pagopa_stato stato
   where pagopa.file_pagopa_id=filePagoPaId
   and   pagopa.file_pagopa_code=(case when coalesce(filepagopaFileXMLId,'')!='' then filepagopaFileXMLId
                                 else pagopa.file_pagopa_code end )
   and   stato.file_pagopa_stato_id=pagopa.file_pagopa_stato_id
   and   stato.file_pagopa_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
   and   pagopa.data_cancellazione is null
   and   pagopa.validita_fine is null;

   if codResult is  null then
      -- errore bloccante
      strErrore:=' File non esistente o in stato differente.Verificare.';
      codiceRisultato:=-1;
      --outPagoPaElabId:=-1;
      messaggioRisultato:=strMessaggioFinale||strMessaggio||strErrore;
      strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_insert - '||messaggioRisultato;
--      raise notice 'strMessaggioLog=% ',strMessaggioLog;

      insert into pagopa_t_elaborazione_log
      (
       pagopa_elab_id,
       pagopa_elab_file_id,
       pagopa_elab_log_operazione,
       ente_proprietario_id,
       login_operazione,
       data_creazione
      )
      values
      (
       inPagoPaElabId,
       filepagopaid,
       strMessaggioLog,
	   enteProprietarioId,
       loginOperazione,
       clock_timestamp()
      );

      return;
   end if;


   if codResult is null then
     strMessaggio:='Verifica esistenza filePagoPa  elaborato per filePagoPaid e filepagopaFileXMLId.';
     select 1 into codResult
     from siac_t_file_pagopa pagopa,siac_d_file_pagopa_stato stato
     where pagopa.file_pagopa_id=filePagoPaId
     and   pagopa.file_pagopa_code=(case when coalesce(filepagopaFileXMLId,'')!='' then filepagopaFileXMLId
                                   else pagopa.file_pagopa_code end )
     and   stato.file_pagopa_stato_id=pagopa.file_pagopa_stato_id
     and   stato.file_pagopa_stato_code=ELABORATO_OK_ST
     and   pagopa.data_cancellazione is null;
     if codResult is not null then
      -- errore bloccante
      strErrore:=' File gia'' elaborato.Verificare.';
      codiceRisultato:=-1;
      -- pagoPaElabId:=-1;
      messaggioRisultato:=strMessaggioFinale||strMessaggio||strErrore;
      messaggioRisultato:=strMessaggioFinale||strMessaggio||strErrore;
      strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_insert - '||messaggioRisultato;
--      raise notice 'strMessaggioLog=% ',strMessaggioLog;

      insert into pagopa_t_elaborazione_log
      (
       pagopa_elab_id,
       pagopa_elab_file_id,
       pagopa_elab_log_operazione,
       ente_proprietario_id,
       login_operazione,
       data_creazione
      )
      values
      (
       inPagoPaElabId,
       filepagopaid,
       strMessaggioLog,
	   enteProprietarioId,
       loginOperazione,
       clock_timestamp()
      );
      return;
     end if;
   end if;



   codResult:=null;
   if coalesce(filepagopaFileXMLId,'')!=''  then
      strMessaggio:='Verifica univocita'' file filepagopaFileXMLId.';
      select count(*) into codResult
      from siac_t_file_pagopa pagopa,siac_d_file_pagopa_stato stato
      where pagopa.file_pagopa_code=filepagopaFileXMLId
      and   stato.file_pagopa_stato_id=pagopa.file_pagopa_stato_id
      and   stato.file_pagopa_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
      and   pagopa.data_cancellazione is null
      and   pagopa.validita_fine is null;

      if codResult is not null and codResult>1 then
          strErrore:=' File caricato piu'' volte. Verificare.';
          codResult:=-1;
          pagoPaErrCode:=PAGOPA_ERR_5;
      else codResult:=null;
      end if;
   end if;

   if codResult is null then
        -- errore bloccante
        strMessaggio:='Verifica esistenza pagopa_t_riconciliazione.';
    	select 1 into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
--        and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;

		if codResult is null then
        	codResult:=-1;
            strErrore:=' Non esistente.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_6;
        else codResult:=null;
        end if;

		-- errore bloccante
		if codResult is null then
         strMessaggio:='Verifica esistenza pagopa_t_riconciliazione da elaborare.';
    	 select 1 into codResult
         from pagopa_t_riconciliazione ric
         where ric.file_pagopa_id=filePagoPaId
         and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--         and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
         /*and   not exists
         (select 1
          from pagopa_t_riconciliazione_doc doc
          where doc.pagopa_ric_id=ric.pagopa_ric_id
          and   doc.pagopa_ric_doc_subdoc_id is not null
          and   doc.data_cancellazione is null
          and   doc.validita_fine is null
         )*/
         /*and   not exists
         (select 1
          from pagopa_t_riconciliazione_doc doc
          where doc.pagopa_ric_id=ric.pagopa_ric_id
          and   doc.pagopa_ric_doc_subdoc_id is null
          and   doc.pagopa_ric_doc_stato_elab in ('E')
          and   doc.data_cancellazione is null
          and   doc.validita_fine is null
         )*/
         and   ric.data_cancellazione is null
         and   ric.validita_fine is null;

         if codResult is null then
         	codResult:=-1;
            strErrore:=' Non esistente.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_7;
         else codResult:=null;
         end if;
        end if;
   end if;


   -- controlli correttezza del filepagopaFileXMLId in pagopa_t_riconciliazione
   if codResult is null and coalesce(filepagopaFileXMLId,'')!='' then
    strMessaggio:='Verifica congruenza filepagopaFileXMLId su pagopa_t_riconciliazione.';
    select count(distinct ric.file_pagopa_id) into codResult
   	from pagopa_t_riconciliazione ric
    where ric.pagopa_ric_file_id=filepagopaFileXMLId
    and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--    and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
    and   ric.data_cancellazione is null
    and   ric.validita_fine is null;

    if codResult is null then
    	codResult:=-1;
        strErrore:=' File non presenti per identificativo.Verificare.';
    else
      if codResult >1 then
           codResult:=-1;
           strErrore:=' Esistenza diversi file presenti con stesso identificativo.Verificare.';
		   pagoPaErrCode:=PAGOPA_ERR_9;
      else codResult:=null;
      end if;
   end if;

  end if;

  if codResult is null then
    	strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_IPA||'.';
        -- lettura tipodocumento
        select tipo.doc_tipo_id into docTipoIpaId
        from siac_d_doc_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.doc_tipo_code=DOC_TIPO_IPA;
        if docTipoIpaId is null then
          strErrore:=' Identificativo insesistente.';
          codResult:=-1;
          pagoPaErrCode:=PAGOPA_ERR_24;
        else codResult:=null;
        end if;
  end if;

  if codResult is null then
    	strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_COR||'.';
        -- lettura tipodocumento
        select tipo.doc_tipo_id into docTipoCorId
        from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.doc_tipo_code=DOC_TIPO_COR
        and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
        and   fam.doc_fam_tipo_code='E';
        if docTipoCorId is null then
          strErrore:=' Identificativo insesistente.';
          codResult:=-1;
          pagoPaErrCode:=PAGOPA_ERR_24;
        else codResult:=null;
        end if;
  end if;

  if codResult is null then
    	strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_FAT||'.';
        -- lettura tipodocumento
        select tipo.doc_tipo_id into docTipoFatId
        from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.doc_tipo_code=DOC_TIPO_FAT
        and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
        and   fam.doc_fam_tipo_code='E';
        if docTipoFatId is null then
          strErrore:=' Identificativo insesistente.';
          codResult:=-1;
          pagoPaErrCode:=PAGOPA_ERR_24;
        else codResult:=null;
        end if;
  end if;


  --FlagCollegamentoAccertamentoFattura
  --FL_COLL_FATT_ATTR
  if codResult is null  then
    strMessaggio:='Verifica esistenza attributo='||FL_COLL_FATT_ATTR||'.';
    select attr.attr_id into attrAccFatturaId
    from siac_t_attr attr
    where attr.ente_proprietario_id=enteProprietarioId
    and   attr.attr_code=FL_COLL_FATT_ATTR;
    if attrAccFatturaId is null then
          strErrore:=' Identificativo insesistente.';
          codResult:=-1;
          pagoPaErrCode:=PAGOPA_ERR_47;
     else codResult:=null;
    end if;
  end if;

  --FlagCollegamentoAccertamentoCorrispettivo
  --FL_COLL_CORR_ATTR
  if codResult is null  then
    strMessaggio:='Verifica esistenza attributo='||FL_COLL_CORR_ATTR||'.';
    select attr.attr_id into attrAccCorrispettivoId
    from siac_t_attr attr
    where attr.ente_proprietario_id=enteProprietarioId
    and   attr.attr_code=FL_COLL_CORR_ATTR;
    if attrAccCorrispettivoId is null then
          strErrore:=' Identificativo insesistente.';
          codResult:=-1;
          pagoPaErrCode:=PAGOPA_ERR_47;
     else codResult:=null;
    end if;
  end if;

   -- errore bloccante - da verificare se possono in un file XML inserire dati di diversi anno_esercizio
   -- commentato in quanto anno_esercizio=annoProvvisorio univoco per flusso
   /*if codResult is null then
    	strMessaggio:='Verifica annoEsercizio su pagopa_t_riconciliazione.';
    	select count(distinct ric.pagopa_ric_flusso_anno_esercizio) into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;
        if coalesce(codResult,0)>1 then
        	codResult:=-1;
            strErrore:=' Esistenza diversi annoEsercizio su dati riconciliazione.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_10;


            strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';
	        update pagopa_t_riconciliazione ric
    	    set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
        	       data_modifica=clock_timestamp(),
                   pagopa_ric_flusso_stato_elab='E',
            	   login_operazione=ric.login_operazione||'-'||loginOperazione
	        from pagopa_d_riconciliazione_errore err
    	    where ric.file_pagopa_id=filePagoPaId
            and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
        	and   err.ente_proprietario_id=ric.ente_proprietario_id
	        and   err.pagopa_ric_errore_code=pagoPaErrCode
    	    and   ric.data_cancellazione is null
	        and   ric.validita_fine is null;

        else codResult:=null;
        end if;


    end if;*/


   ----- 04.06.2019 SIAC-6720
   ----  qui inserimento in pagopa_t_riconciliazione
   ----  dei dati con pagopa_ric_flusso_flag_dett=true
   ----- forse meglio da servizio java altrimenti ad ogni elaborazione creo diversi record

   -- errore bloccante
   if codResult is null then
    	strMessaggio:='Verifica annoEsercizio su pagopa_t_riconciliazione.';
    	select 1 into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
        and   ric.pagopa_ric_flusso_anno_esercizio>annoBilancioElab
--        and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;
        if codResult is not null then
        	codResult:=-1;
            strErrore:=' Esistenza annoEsercizio su dati riconciliazione successivo ad annoBilancio di elab .Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_11;

            strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';
            update pagopa_t_riconciliazione ric
    	    set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
        	       data_modifica=clock_timestamp(),
                   pagopa_ric_flusso_stato_elab='E',
            	   login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
	        from pagopa_d_riconciliazione_errore err
    	    where ric.file_pagopa_id=filePagoPaId
            and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--            and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
            and   ric.pagopa_ric_flusso_anno_esercizio>annoBilancioElab
        	and   err.ente_proprietario_id=ric.ente_proprietario_id
	        and   err.pagopa_ric_errore_code=pagoPaErrCode
    	    and   ric.data_cancellazione is null
	        and   ric.validita_fine is null;

        end if;


    end if;

    if codResult is null then
    	strMessaggio:='Lettura annoEsercizio su pagopa_t_riconciliazione.';
    	select distinct ric.pagopa_ric_flusso_anno_esercizio into annoBilancio
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--        and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null
        limit 1;
        if annoBilancio is  null or AnnoBilancio!=annoBilancioElab then
        	codResult:=-1;
            strErrore:=' Non effettuata .Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_12;

            strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';
            update pagopa_t_riconciliazione ric
    	    set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
        	       data_modifica=clock_timestamp(),
                   pagopa_ric_flusso_stato_elab='E',
            	   login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
	        from pagopa_d_riconciliazione_errore err
    	    where ric.file_pagopa_id=filePagoPaId
            and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--            and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
        	and   err.ente_proprietario_id=ric.ente_proprietario_id
	        and   err.pagopa_ric_errore_code=pagoPaErrCode
    	    and   ric.data_cancellazione is null
	        and   ric.validita_fine is null;

        end if;
    end if;

    strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - controllo dati pagopa_t_riconciliazione - '||strMessaggioFinale;
--    raise notice 'strMessaggioLog=% ',strMessaggioLog;

    insert into pagopa_t_elaborazione_log
    (
       pagopa_elab_id,
       pagopa_elab_file_id,
       pagopa_elab_log_operazione,
       ente_proprietario_id,
       login_operazione,
       data_creazione
    )
    values
    (
       inPagoPaElabId,
       filepagopaid,
       strMessaggioLog,
	   enteProprietarioId,
       loginOperazione,
       clock_timestamp()
    );

    -- controlli campi obbligatori su pagopa_t_riconciliazione
    -- senza anno_esercizio
    if codResult is null then
    	strMessaggio:='Verifica annoEsercizio su pagopa_t_riconciliazione.';
    	select 1 into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--        and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
        and   coalesce(ric.pagopa_ric_flusso_anno_esercizio,0)=0
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;
        if codResult is not null then
        	codResult:=-1;
            strErrore:=' Esistenza dati riconciliazione senza annoEsercizio.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_12;

           strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';

           update pagopa_t_riconciliazione ric
           set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
         	      data_modifica=clock_timestamp(),
                  pagopa_ric_flusso_stato_elab='E',
            	  login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
	       from pagopa_d_riconciliazione_errore err
    	   where ric.file_pagopa_id=filePagoPaId
           and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--           and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
	       and   coalesce(ric.pagopa_ric_flusso_anno_esercizio,0)=0
           and   err.ente_proprietario_id=ric.ente_proprietario_id
	       and   err.pagopa_ric_errore_code=pagoPaErrCode
    	   and   ric.data_cancellazione is null
	       and   ric.validita_fine is null;
        end if;
    end if;

    -- senza dati provvisori
    if codResult is null then
    	strMessaggio:='Verifica Provvisori di cassa su pagopa_t_riconciliazione.';
    	select 1 into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--        and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
        and   ( coalesce(ric.pagopa_ric_flusso_anno_provvisorio,0)=0  or coalesce(ric.pagopa_ric_flusso_num_provvisorio,0)=0)
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;
        if codResult is not null then
        	codResult:=-1;
            strErrore:=' Esistenza dati riconciliazione senza provvisorio di cassa.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_13;

           strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';

           update pagopa_t_riconciliazione ric
           set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
         	      data_modifica=clock_timestamp(),
                  pagopa_ric_flusso_stato_elab='E',
            	  login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
	       from pagopa_d_riconciliazione_errore err
    	   where ric.file_pagopa_id=filePagoPaId
           and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--           and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
           and   ( coalesce(ric.pagopa_ric_flusso_anno_provvisorio,0)=0  or coalesce(ric.pagopa_ric_flusso_num_provvisorio,0)=0)
           and   err.ente_proprietario_id=ric.ente_proprietario_id
	       and   err.pagopa_ric_errore_code=pagoPaErrCode
    	   and   ric.data_cancellazione is null
	       and   ric.validita_fine is null;


        end if;
    end if;


    -- senza accertamento
    if codResult is null then
    	strMessaggio:='Verifica Accertamenti su pagopa_t_riconciliazione.';
    	select 1 into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
        and   ( coalesce(ric.pagopa_ric_flusso_anno_accertamento,0)=0  or coalesce(ric.pagopa_ric_flusso_num_accertamento,0)=0)
--        and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;
        if codResult is not null then
        	codResult:=-1;
            strErrore:=' Esistenza dati riconciliazione senza accertamento.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_14;

            strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';

           update pagopa_t_riconciliazione ric
           set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
         	      data_modifica=clock_timestamp(),
                  pagopa_ric_flusso_stato_elab='E',
            	  login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
	       from pagopa_d_riconciliazione_errore err
    	   where ric.file_pagopa_id=filePagoPaId
           and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--	       and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
           and   ( coalesce(ric.pagopa_ric_flusso_anno_accertamento,0)=0  or coalesce(ric.pagopa_ric_flusso_num_accertamento,0)=0)
           and   err.ente_proprietario_id=ric.ente_proprietario_id
	       and   err.pagopa_ric_errore_code=pagoPaErrCode
    	   and   ric.data_cancellazione is null
	       and   ric.validita_fine is null;
        end if;
    end if;

	-- senza voce/sottovoce
    if codResult is null then
    	strMessaggio:='Verifica Voci su pagopa_t_riconciliazione.';
    	select 1 into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--        and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
        and   ( coalesce(ric.pagopa_ric_flusso_voce_code,'')=''  or coalesce(ric.pagopa_ric_flusso_sottovoce_code,'')='')
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;
        if codResult is not null then
        	codResult:=-1;
            strErrore:=' Esistenza dati riconciliazione senza estremi voce/sottovoce.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_15;


            strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';

           update pagopa_t_riconciliazione ric
           set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
         	      data_modifica=clock_timestamp(),
                  pagopa_ric_flusso_stato_elab='E',
            	  login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
	       from pagopa_d_riconciliazione_errore err
    	   where ric.file_pagopa_id=filePagoPaId
           and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--           and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
           and   ( coalesce(ric.pagopa_ric_flusso_voce_code,'')=''  or coalesce(ric.pagopa_ric_flusso_sottovoce_code,'')='')
           and   err.ente_proprietario_id=ric.ente_proprietario_id
	       and   err.pagopa_ric_errore_code=pagoPaErrCode
    	   and   ric.data_cancellazione is null
	       and   ric.validita_fine is null;

        end if;
    end if;

    -- senza importo
    if codResult is null then
    	strMessaggio:='Verifica importi su pagopa_t_riconciliazione.';
    	select 1 into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--        and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
        and   coalesce(ric.pagopa_ric_flusso_sottovoce_importo,0)=0
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;
        if codResult is not null then
        	codResult:=-1;
            strErrore:=' Esistenza dati riconciliazione senza importo.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_16;

            strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';

           update pagopa_t_riconciliazione ric
           set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
         	      data_modifica=clock_timestamp(),
                  pagopa_ric_flusso_stato_elab='E',
            	  login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
	       from pagopa_d_riconciliazione_errore err
    	   where ric.file_pagopa_id=filePagoPaId
           and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--           and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
           and   coalesce(ric.pagopa_ric_flusso_sottovoce_importo,0)=0
           and   err.ente_proprietario_id=ric.ente_proprietario_id
	       and   err.pagopa_ric_errore_code=pagoPaErrCode
    	   and   ric.data_cancellazione is null
	       and   ric.validita_fine is null;

        end if;
    end if;

    -- siac-6720 31.05.2019 controlli
    -- dettaglio senza codice fiscale soggetto
    -- si può valutare di intercettare questo errore gia'' in caricamento di pagopa_t_riconciliazione
    /*if codResult is null then
    	strMessaggio:='Verifica estremi soggetto su dati di dettaglio fatture su pagopa_t_riconciliazione.';
    	select 1 into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--        and   ric.pagopa_ric_flusso_flag_con_dett=false -- con dettaglio
        and   ric.pagopa_ric_flusso_flag_dett=true -- dettaglio
        and   coalesce(ric.pagopa_ric_flusso_codfisc_benef,'')=''
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;
        if codResult is not null then
        	codResult:=-1;
            strErrore:=' Esistenza dati riconciliazione-fatt senza estremi soggetto.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_41;

            strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';

           update pagopa_t_riconciliazione ric
           set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
         	      data_modifica=clock_timestamp(),
                  pagopa_ric_flusso_stato_elab='E',
            	  login_operazione=ric.login_operazione||'-'||loginOperazione
	       from pagopa_d_riconciliazione_errore err
    	   where ric.file_pagopa_id=filePagoPaId
           and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--           and   ric.pagopa_ric_flusso_flag_con_dett=false -- con dettaglio
	       and   ric.pagopa_ric_flusso_flag_dett=true -- dettaglio
               and   coalesce(ric.pagopa_ric_flusso_codfisc_benef,'')=''
           and   err.ente_proprietario_id=ric.ente_proprietario_id
	       and   err.pagopa_ric_errore_code=pagoPaErrCode
    	   and   ric.data_cancellazione is null
	       and   ric.validita_fine is null;

        end if;
    end if;*/

    -- chiusura siac_t_file_pagopa
    if codResult is not null then
        -- errore bloccante
        strMessaggioBck:=strMessaggio;
        strMessaggio:=' Chiusura siac_t_file_pagopa.';
    	update siac_t_file_pagopa file
        set    data_modifica=clock_timestamp(),
         	   validita_fine=clock_timestamp(),
               file_pagopa_stato_id=stato.file_pagopa_stato_id,
               file_pagopa_errore_id=err.pagopa_ric_errore_id,
               file_pagopa_code=coalesce(filepagopaFileXMLId,file.file_pagopa_code),
               file_pagopa_note=upper(coalesce(strMessaggioFinale,' ' )||coalesce(strMessaggioBck,'  ')||coalesce(strErrore,' ')),
               login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
        from siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
        where file.file_pagopa_id=filePagoPaId
        and   stato.ente_proprietario_id=file.ente_proprietario_id
        and   stato.file_pagopa_stato_code=ELABORATO_ERRATO_ST
        and   err.ente_proprietario_id=stato.ente_proprietario_id
        and   err.pagopa_ric_errore_code=pagoPaErrCode;

		-- errore bloccante per elaborazione del filePagoPaId passato per cui si esce ma senza errore bloccante per elaborazione complessiva
        -- pagoPaElabId:=-1;
        -- codiceRisultato:=-1;
        messaggioRisultato:=strMessaggioFinale||strMessaggioBck||strErrore||strMessaggio;
        strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_insert - '||messaggioRisultato;
--        raise notice 'strMessaggioLog=% ',strMessaggioLog;

        insert into pagopa_t_elaborazione_log
        (
          pagopa_elab_id,
          pagopa_elab_file_id,
          pagopa_elab_log_operazione,
          ente_proprietario_id,
          login_operazione,
          data_creazione
        )
        values
        (
          inPagoPaElabId,
          filepagopaid,
          strMessaggioLog,
          enteProprietarioId,
          loginOperazione,
          clock_timestamp()
        );

        return;
    end if;


    ---------- fine controlli su siac_t_file_pagopa e piano_t_riconciliazione  --------------------------------


    ---------- inizio inserimento pagopa_t_elaborazione -------------------------------
    -- se inPagoPaElabId=0 inizio nuovo idElaborazione
    if coalesce(inPagoPaElabId,0) = 0 then
      codResult:=null;
      strMessaggio:='Inserimento elaborazione PagoPa in stato '||acquisito_st||'.';
      --- inserimento in stato ACQUISITO
      insert into pagopa_t_elaborazione
      (
          pagopa_elab_data,
          pagopa_elab_stato_id,
          pagopa_elab_file_id,
          pagopa_elab_file_ora,
          pagopa_elab_file_ente,
          pagopa_elab_file_fruitore,
          pagopa_elab_note,
         -- file_pagopa_id ,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
      )
      select
             dataelaborazione,
             stato.pagopa_elab_stato_id,
             filepagopaFileXMLId,
             filepagopaFileOra,
             filepagopaFileEnte,
             filepagopaFileFruitore,
             'AVVIO ELABORAZIONE SU FILE file_pagopa_id='||filePagoPaId::varchar||' IN STATO '||ACQUISITO_ST||' ',
           --  filePagoPaId,
             clock_timestamp(),
             loginOperazione,
             stato.ente_proprietario_id
      from pagopa_d_elaborazione_stato stato
      where stato.ente_proprietario_id=enteProprietarioId
      and   stato.pagopa_elab_stato_code=ACQUISITO_ST
      returning pagopa_elab_id into filePagoPaElabId;


      if filePagoPaElabId is null then
          -- bloccante per elaborazione del file ma puo essere rielaborato
          strMessaggioBck:=strMessaggio;
          strMessaggio:=strMessaggio||' Inserimento non effettuato. Aggiornamento siac_t_file_pagopa.';
          update siac_t_file_pagopa file
          set    data_modifica=clock_timestamp(),
                 file_pagopa_stato_id=stato.file_pagopa_stato_id,
                 file_pagopa_errore_id=err.pagopa_ric_errore_id,
                 file_pagopa_code=coalesce(filepagopaFileXMLId,file.file_pagopa_code),
                 file_pagopa_note=upper(coalesce(strMessaggioFinale,' ' )||coalesce(strMessaggioBck,' ')||' Inserimento non effettuato. Aggiornamento siac_t_file_pagopa.'),
                 login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
          from siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
          where file.file_pagopa_id=filePagoPaId
          and   stato.ente_proprietario_id=file.ente_proprietario_id
          and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ER_ST
          and   err.ente_proprietario_id=stato.ente_proprietario_id
          and   err.pagopa_ric_errore_code=PAGOPA_ERR_17;


          strMessaggio:=strMessaggioBck||'  Inserimento non effettuato.Aggiornamento PAGOPA_ERR='||PAGOPA_ERR_17||'.';

          update pagopa_t_riconciliazione ric
          set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                 data_modifica=clock_timestamp(),
                 pagopa_ric_flusso_stato_elab='X',
                 login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
          from pagopa_d_riconciliazione_errore err
          where ric.file_pagopa_id=filePagoPaId
          and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--          and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
          and   err.ente_proprietario_id=ric.ente_proprietario_id
          and   err.pagopa_ric_errore_code=PAGOPA_ERR_17
          and   ric.data_cancellazione is null
          and   ric.validita_fine is null;

          --pagoPaElabId:=-1;
          codiceRisultato:=0; -- può essere rielaborato
          messaggioRisultato:=strMessaggioFinale||strMessaggioBck||' Inserimento non effettuato.Aggiornamento siac_t_file_pagopa e pagopa_t_riconciliazione.';

		  strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_insert - '||messaggioRisultato;
--          raise notice 'strMessaggioLog=% ',strMessaggioLog;

          insert into pagopa_t_elaborazione_log
          (
          	pagopa_elab_id,
	        pagopa_elab_file_id,
          	pagopa_elab_log_operazione,
          	ente_proprietario_id,
          	login_operazione,
            data_creazione
          )
          values
	      (
     	     inPagoPaElabId,
        	 filepagopaid,
	         strMessaggioLog,
    	     enteProprietarioId,
	         loginOperazione,
             clock_timestamp()
    	  );

          return;

      else
          -- elaborazione in corso
          strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale||strMessaggio;
--          raise notice 'strMessaggioLog=% ',strMessaggioLog;

          insert into pagopa_t_elaborazione_log
          (
          	pagopa_elab_id,
	        pagopa_elab_file_id,
          	pagopa_elab_log_operazione,
          	ente_proprietario_id,
          	login_operazione,
            data_creazione
          )
          values
	      (
     	     filePagoPaElabId,
        	 filepagopaid,
	         strMessaggioLog,
    	     enteProprietarioId,
	         loginOperazione,
             clock_timestamp()
    	  );

/**          -- fare qui modifica per aggiornare solo se non in stato IN_CORSO_ST
          strMessaggioBck:=strMessaggio;
          strMessaggio:=strMessaggio||' Aggiornamento siac_t_file_pagopa.';

          update siac_t_file_pagopa file
          set    data_modifica=clock_timestamp(),
                 file_pagopa_stato_id=(case when statocor.file_pagopa_stato_code not in (ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST) then stato.file_pagopa_stato_id
                                       else  file.file_pagopa_stato_id end ),
                 file_pagopa_code=coalesce(filepagopaFileXMLId,file.file_pagopa_code),
                 login_operazione=file.login_operazione||'-'||loginOperazione
          from siac_d_file_pagopa_stato stato, siac_d_file_pagopa_stato statocor
          where file.file_pagopa_id=filePagoPaId
          and   stato.ente_proprietario_id=file.ente_proprietario_id
          and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ST
          and   statocor.file_pagopa_stato_id=file.file_pagopa_stato_id;
	  */
      end if;
    end if;

    -- elaborazione in corso
    -- fare qui modifica per aggiornare solo se non in stato IN_CORSO_ST
    strMessaggio:='Aggiornamento siac_t_file_pagopa per elaborazione in corso.';
    update siac_t_file_pagopa file
    set    data_modifica=clock_timestamp(),
           file_pagopa_stato_id=(case when statocor.file_pagopa_stato_code not in (ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST) then stato.file_pagopa_stato_id
                                 else  file.file_pagopa_stato_id end ),
           file_pagopa_code=coalesce(filepagopaFileXMLId,file.file_pagopa_code),
           file_pagopa_note=upper(coalesce(strMessaggioFinale,' ' )||coalesce(strMessaggio,' ')),
           login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
    from siac_d_file_pagopa_stato stato, siac_d_file_pagopa_stato statocor
    where file.file_pagopa_id=filePagoPaId
    and   stato.ente_proprietario_id=file.ente_proprietario_id
    and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ST
    and   statocor.file_pagopa_stato_id=file.file_pagopa_stato_id;

    -- inserimento pagopa_r_elaborazione_file
    codResult:=null;
    strMessaggio:='Inserimento pagopa_r_elaborazione_file.';
    insert into pagopa_r_elaborazione_file
    (
          pagopa_elab_id,
          file_pagopa_id,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
	)
    values
    (
        filePagoPaElabId,
        filePagoPaId,
        clock_timestamp(),
        loginOperazione,
        enteProprietarioId
    )
    returning pagopa_r_elab_id into codResult;
    if codResult is null then
    	 -- bloccante per elaborazione, ma il file può essere rielaborato
    	 -- chiusura elaborazione
    	 codResult:=null;
         strMessaggioBck:=strMessaggio;
         strmessaggio:=strMessaggioBck||' Non effettuato. Aggiornamento pagopa_t_elaborazione.';
       	 update pagopa_t_elaborazione elab
         set    data_modifica=clock_timestamp(),
                validita_fine=clock_timestamp(),
                pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
                pagopa_elab_errore_id=err.pagopa_ric_errore_id,
                pagopa_elab_note=upper(strMessaggioFinale||' '||strmessaggio)
         from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
         where elab.pagopa_elab_id=filePagoPaElabId
          and  stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
          and  stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
          and  statonew.ente_proprietario_id=stato.ente_proprietario_id
          and  statonew.pagopa_elab_stato_code=ELABORATO_ERRATO_ST
          and  err.ente_proprietario_id=stato.ente_proprietario_id
          and  err.pagopa_ric_errore_code=PAGOPA_ERR_17
          and  elab.data_cancellazione is null
          and  elab.validita_fine is null;

          strmessaggio:=strMessaggioBck||' Non effettuato. Aggiornamento siac_t_file_pagopa.';
          -- chiusura file_pagopa
          update siac_t_file_pagopa file
          set    data_modifica=clock_timestamp(),
                 file_pagopa_stato_id=stato.file_pagopa_stato_id,
                 file_pagopa_errore_id=err.pagopa_ric_errore_id,
                 file_pagopa_code=coalesce(filepagopaFileXMLId,pagopa.file_pagopa_code),
                 file_pagopa_note=upper(coalesce(strMessaggioFinale,' ' )||coalesce(strmessaggio,' ')),
                 login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
          from siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
          where file.file_pagopa_id=filePagoPaId
          and   stato.ente_proprietario_id=file.ente_proprietario_id
          and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ER_ST
          and   err.ente_proprietario_id=stato.ente_proprietario_id
          and   err.pagopa_ric_errore_code=PAGOPA_ERR_17;


		  strMessaggio:=strMessaggioBck||' Inserimento non effettuato.Aggiornamento PAGOPA_ERR='||PAGOPA_ERR_17||'.';

          update pagopa_t_riconciliazione ric
          set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                 data_modifica=clock_timestamp(),
                 pagopa_ric_flusso_stato_elab='X',
                 login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
          from pagopa_d_riconciliazione_errore err
      	  where ric.file_pagopa_id=filePagoPaId
          and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--          and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
          and   err.ente_proprietario_id=ric.ente_proprietario_id
	      and   err.pagopa_ric_errore_code=PAGOPA_ERR_17
          and   ric.data_cancellazione is null
  	      and   ric.validita_fine is null;


          outPagoPaElabId:=filePagoPaElabId;
          codiceRisultato:=0;
          messaggioRisultato:=strMessaggioFinale||strMessaggioBck||' Inserimento non effettuato.';
          strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_insert - '||messaggioRisultato;
          insert into pagopa_t_elaborazione_log
          (
          	pagopa_elab_id,
	        pagopa_elab_file_id,
          	pagopa_elab_log_operazione,
          	ente_proprietario_id,
          	login_operazione,
            data_creazione
          )
          values
	      (
     	     filePagoPaElabId,
        	 filepagopaid,
	         strMessaggioLog,
    	     enteProprietarioId,
	         loginOperazione,
             clock_timestamp()
    	  );
         return;
    end if;


	-- controllo su annoBilancio
    strMessaggio:='Verifica stato annoBilancio di elaborazione='||annoBilancio::varchar||'.';
    select bil.bil_id , per.periodo_id into bilancioId, periodoId
    from siac_t_bil bil, siac_t_periodo per, siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
    where fase.ente_proprietario_id=enteProprietarioid
    and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST)
    and   per.ente_proprietario_id=fase.ente_proprietario_id
    and   per.anno::integer=annoBilancio
    and   bil.periodo_id=per.periodo_id
    and   r.fase_operativa_id=fase.fase_operativa_id
    and   r.bil_id=r.bil_id;

    if bilancioId is null then
         -- bloccante per elaborazione, ma il file può essere rielaborato
    	 -- chiusura elaborazione
    	 codResult:=null;
         strMessaggioBck:=strMessaggio;
         strmessaggio:=strMessaggioBck||' Fase non valida. Aggiornamento pagopa_t_elaborazione.';
       	 update pagopa_t_elaborazione elab
         set    data_modifica=clock_timestamp(),
                validita_fine=clock_timestamp(),
                pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
                pagopa_elab_errore_id=err.pagopa_ric_errore_id,
                pagopa_elab_note=upper(strMessaggioFinale||' '||strMessaggioBck||'Fase bilancio non valida.')
         from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
         where elab.pagopa_elab_id=filePagoPaElabId
          and  stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
          and  stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
          and  statonew.ente_proprietario_id=stato.ente_proprietario_id
          and  statonew.pagopa_elab_stato_code=ELABORATO_ERRATO_ST
          and  err.ente_proprietario_id=stato.ente_proprietario_id
          and  err.pagopa_ric_errore_code=PAGOPA_ERR_18
          and  elab.data_cancellazione is null
          and  elab.validita_fine is null;

          strMessaggio:=strMessaggioBck;
          strmessaggio:=strMessaggioBck||' Fase non valida. Aggiornamento siac_t_file_pagopa.';
          -- chiusura file_pagopa
          update siac_t_file_pagopa file
          set    data_modifica=clock_timestamp(),
                 file_pagopa_stato_id=stato.file_pagopa_stato_id,
                 file_pagopa_errore_id=err.pagopa_ric_errore_id,
                 file_pagopa_code=coalesce(filepagopaFileXMLId,pagopa.file_pagopa_code),
                 file_pagopa_note=upper(coalesce(strMessaggioFinale,' ' )||coalesce(strMessaggioBck,' ')||' Fase bilancio non valida.'),
                 login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
          from siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
          where file.file_pagopa_id=filePagoPaId
          and   stato.ente_proprietario_id=file.ente_proprietario_id
          and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ER_ST
          and   err.ente_proprietario_id=stato.ente_proprietario_id
          and   err.pagopa_ric_errore_code=PAGOPA_ERR_18;


		  strMessaggio:=strMessaggioBck||'  Inserimento non effettuato.Aggiornamento PAGOPA_ERR='||PAGOPA_ERR_18||'.';

          update pagopa_t_riconciliazione ric
          set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                 data_modifica=clock_timestamp(),
                 pagopa_ric_flusso_stato_elab='X',
                 login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
          from pagopa_d_riconciliazione_errore err
      	  where ric.file_pagopa_id=filePagoPaId
          and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--          and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
          and   err.ente_proprietario_id=ric.ente_proprietario_id
	      and   err.pagopa_ric_errore_code=PAGOPA_ERR_18
          and   ric.data_cancellazione is null
  	      and   ric.validita_fine is null;


          outPagoPaElabId:=filePagoPaElabId;
          codiceRisultato:=0; -- il file puo essere rielaborato
          messaggioRisultato:=strMessaggioFinale||strMessaggioBck||' Fase bilancio non valida.';

          strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_insert - '||messaggioRisultato;
          insert into pagopa_t_elaborazione_log
          (
          	pagopa_elab_id,
	        pagopa_elab_file_id,
          	pagopa_elab_log_operazione,
          	ente_proprietario_id,
          	login_operazione,
            data_creazione
          )
          values
	      (
     	     filePagoPaElabId,
        	 filepagopaid,
	         strMessaggioLog,
    	     enteProprietarioId,
	         loginOperazione,
             clock_timestamp()
    	  );
         return;
    end if;


    codResult:=null;
    ---------- fine inserimento pagopa_t_elaborazione --------------------------------

    ---------- inizio gestione flussi su piano_t_riconciliazione per pagopa_elab_id ----------------


    -- per file_pagopa_id, file_pagopa_id ( XML )
    -- distinct su pagopa_t_riconciliazione su file_pagopa_id, file_pagopa_id ( XML ) pagopa_flusso_id ( XML )
    -- per cui non esiste corrispondenza su
    --   pagopa_t_riconciliazione_doc con subdoc_id valorizzato
    --   pagopa_t_riconciliazione_doc con subdoc_id non valorizzato e errore bloccante
    --   pagopa_t_riconciliazione con errore bloccante
    strMessaggio:='Inserimento dati per elaborazione flussi.Inizio ciclo.';
    strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale||strMessaggio;
    insert into pagopa_t_elaborazione_log
    (
      pagopa_elab_id,
      pagopa_elab_file_id,
      pagopa_elab_log_operazione,
      ente_proprietario_id,
      login_operazione,
      data_creazione
    )
    values
    (
       filePagoPaElabId,
       filepagopaid,
       strMessaggioLog,
       enteProprietarioId,
       loginOperazione,
       clock_timestamp()
    );

    for pagoPaFlussoRec in
    (
    select distinct ric.pagopa_ric_file_id pagopa_file_id,
                    ric.pagopa_ric_flusso_id pagopa_flusso_id,
                    ric.pagopa_ric_flusso_anno_provvisorio pagopa_anno_provvisorio,
					ric.pagopa_ric_flusso_num_provvisorio pagopa_num_provvisorio
    from pagopa_t_riconciliazione ric
    where ric.file_pagopa_id=filePagoPaId
    and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--    and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
    /*and   not exists
    ( select 1
      from pagopa_t_riconciliazione_doc doc
      where doc.pagopa_ric_id=ric.pagopa_ric_id
      and   doc.pagopa_ric_doc_subdoc_id is not null
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null
    )*/
   /* and   not exists
    ( select 1
      from pagopa_t_riconciliazione_doc doc
      where doc.pagopa_ric_id=ric.pagopa_ric_id
      and   doc.pagopa_ric_doc_subdoc_id is null
      and   doc.pagopa_ric_doc_stato_elab in ('E')
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null
    )*/
    and   ric.data_cancellazione is null
    and   ric.validita_fine is null
    order by        ric.pagopa_ric_flusso_anno_provvisorio,
					ric.pagopa_ric_flusso_num_provvisorio
    )
    loop

        codResult:=null;
	    strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.';

        strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale||strMessaggio;
        insert into pagopa_t_elaborazione_log
        (
          pagopa_elab_id,
          pagopa_elab_file_id,
          pagopa_elab_log_operazione,
          ente_proprietario_id,
          login_operazione,
          data_creazione
        )
        values
        (
           filePagoPaElabId,
           filepagopaid,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
        );


	    --   inserimento in pagopa_t_elaborazione_flusso

        pagoPaFlussoAnnoEsercizio :=null;
	    pagoPaFlussoNomeMittente  :=null;
	    pagoPaFlussoData  :=null;
    	pagoPaFlussoTotPagam  :=null;
        codResult:=null;
        strNote:=null;
        pagopaElabFlussoId:=null;

        strMessaggio:=strmessaggio||' Ricava dati.';
		select ric.pagopa_ric_flusso_anno_esercizio,
    	       ric.pagopa_ric_flusso_nome_mittente,
 	    	   ric.pagopa_ric_flusso_data::varchar,
			   ric.pagopa_ric_flusso_tot_pagam,
               ric.pagopa_ric_id
    	       into
        	   pagoPaFlussoAnnoEsercizio,
	           pagoPaFlussoNomeMittente,
    	       pagoPaFlussoData,
	       	   pagoPaFlussoTotPagam,
               codResult
	    from pagopa_t_riconciliazione ric
	    where ric.file_pagopa_id=filePagoPaId
    	and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--        and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
	    and   ric.pagopa_ric_flusso_id= pagoPaFlussoRec.pagopa_flusso_id
    	and   ric.pagopa_ric_flusso_anno_provvisorio=pagoPaFlussoRec.pagopa_anno_provvisorio
		and   ric.pagopa_ric_flusso_num_provvisorio=pagoPaFlussoRec.pagopa_num_provvisorio
        /*and   not exists
	    ( select 1
    	  from pagopa_t_riconciliazione_doc doc
	      where doc.pagopa_ric_id=ric.pagopa_ric_id
    	  and   doc.pagopa_ric_doc_subdoc_id is not null
	      and   doc.data_cancellazione is null
    	  and   doc.validita_fine is null
	    )*/
    	/*and   not exists
	    ( select 1
    	  from pagopa_t_riconciliazione_doc doc
	      where doc.pagopa_ric_id=ric.pagopa_ric_id
    	  and   doc.pagopa_ric_doc_subdoc_id is null
	      and   doc.pagopa_ric_doc_stato_elab in ('E')
    	  and  doc.data_cancellazione is null
	      and   doc.validita_fine is null
	    )*/
    	and   ric.data_cancellazione is null
	    and   ric.validita_fine is null
    	limit 1;

		if  codResult is null then
        	strNote:='Dati testata mancanti.';
        end if;

	    strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                       ' Inserimento pagopa_t_elaborazione_flusso.';

	    insert into pagopa_t_elaborazione_flusso
    	(
    	 pagopa_elab_flusso_data,
	     pagopa_elab_flusso_stato_id,
		 pagopa_elab_flusso_note,
		 pagopa_elab_ric_flusso_id,
		 pagopa_elab_flusso_nome_mittente,
		 pagopa_elab_ric_flusso_data,
	     pagopa_elab_flusso_tot_pagam,
	     pagopa_elab_flusso_anno_esercizio,
	     pagopa_elab_flusso_anno_provvisorio,
	     pagopa_elab_flusso_num_provvisorio,
		 pagopa_elab_id,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
	    )
    	select dataElaborazione,
        	   stato.pagopa_elab_stato_id,
	           'AVVIO ELABORAZIONE FILE file_pagopa_id='||filePagoPaId::varchar||
               upper(' FLUSSO_ID='||pagoPaFlussoRec.pagopa_flusso_id||' IN STATO '||ACQUISITO_ST||' '||
               coalesce(strNote,' ')),
               pagoPaFlussoRec.pagopa_flusso_id,
   	           pagoPaFlussoNomeMittente,
			   pagoPaFlussoData,
               pagoPaFlussoTotPagam,
               pagoPaFlussoAnnoEsercizio,
               pagoPaFlussoRec.pagopa_anno_provvisorio,
               pagoPaFlussoRec.pagopa_num_provvisorio,
               filePagoPaElabId,
               clock_timestamp(),
               loginOperazione,
               enteProprietarioId
    	from pagopa_d_elaborazione_stato stato
	    where stato.ente_proprietario_id=enteProprietarioId
    	and   stato.pagopa_elab_stato_code=ACQUISITO_ST
        returning pagopa_elab_flusso_id into pagopaElabFlussoId;

        codResult:=null;
        if pagopaElabFlussoId is null then
            strMessaggioBck:=strMessaggio;
            strmessaggio:=strMessaggioBck||' NON Effettuato. Aggiornamento pagopa_t_elaborazione.';
        	update pagopa_t_elaborazione elab
            set    data_modifica=clock_timestamp(),
                   pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
                   pagopa_elab_errore_id=err.pagopa_ric_errore_id,
                   pagopa_elab_note=upper(strMessaggioFinale||' '||strmessaggio)
            from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
            where elab.pagopa_elab_id=filePagoPaElabId
            and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
            and   stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
            and   statonew.ente_proprietario_id=stato.ente_proprietario_id
            and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_ER_ST
            and   err.ente_proprietario_id=stato.ente_proprietario_id
            and   err.pagopa_ric_errore_code=PAGOPA_ERR_19
            and   elab.data_cancellazione is null
            and   elab.validita_fine is null;

             strMessaggio:=strMessaggioBck||' NON effettuato.Aggiornamento PAGOPA_ERR='||PAGOPA_ERR_19||'.';
             update pagopa_t_riconciliazione ric
             set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                    data_modifica=clock_timestamp(),
                    pagopa_ric_flusso_stato_elab='X',
                    login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
             from pagopa_d_riconciliazione_errore err
             where ric.file_pagopa_id=filePagoPaId
             and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--             and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
             and   err.ente_proprietario_id=ric.ente_proprietario_id
             and   err.pagopa_ric_errore_code=PAGOPA_ERR_19
             and   ric.pagopa_ric_flusso_id= pagoPaFlussoRec.pagopa_flusso_id
             and   ric.pagopa_ric_flusso_anno_provvisorio=pagoPaFlussoRec.pagopa_anno_provvisorio
             and   ric.pagopa_ric_flusso_num_provvisorio=pagoPaFlussoRec.pagopa_num_provvisorio
             /*and   not exists
             ( select 1
               from pagopa_t_riconciliazione_doc doc
               where doc.pagopa_ric_id=ric.pagopa_ric_id
               and   doc.pagopa_ric_doc_subdoc_id is not null
               and   doc.data_cancellazione is null
               and   doc.validita_fine is null
             )*/
             /*and   not exists
             ( select 1
               from pagopa_t_riconciliazione_doc doc
               where doc.pagopa_ric_id=ric.pagopa_ric_id
               and   doc.pagopa_ric_doc_subdoc_id is null
               and   doc.pagopa_ric_doc_stato_elab in ('E')
               and   doc.data_cancellazione is null
               and   doc.validita_fine is null
             )*/
             and   ric.data_cancellazione is null
             and   ric.validita_fine is null;

            codResult:=-1;
            pagoPaErrCode:=PAGOPA_ERR_19;

        end if;

        if  pagopaElabFlussoId is not null then
         strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                        pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                        pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                        pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                        ' Inserimento pagopa_t_riconciliazione_doc.';
		 --   inserimento in pagopa_t_riconciliazione_doc
         insert into pagopa_t_riconciliazione_doc
         (
        	pagopa_ric_doc_data,
            pagopa_ric_doc_voce_tematica,
  	        pagopa_ric_doc_voce_code,
			pagopa_ric_doc_voce_desc,
			pagopa_ric_doc_sottovoce_code,
		    pagopa_ric_doc_sottovoce_desc,
			pagopa_ric_doc_sottovoce_importo,
		    pagopa_ric_doc_anno_esercizio,
		    pagopa_ric_doc_anno_accertamento,
			pagopa_ric_doc_num_accertamento,
		    pagopa_ric_doc_num_capitolo,
		    pagopa_ric_doc_num_articolo,
		    pagopa_ric_doc_pdc_v_fin,
		    pagopa_ric_doc_titolo,
		    pagopa_ric_doc_tipologia,
		    pagopa_ric_doc_categoria,
		    pagopa_ric_doc_str_amm,
            --- 31.05.2019 siac-6720
		    pagopa_ric_doc_codice_benef,
            pagopa_ric_doc_ragsoc_benef,
            pagopa_ric_doc_nome_benef,
            pagopa_ric_doc_cognome_benef,
            pagopa_ric_doc_codfisc_benef,
        --    pagopa_ric_doc_flag_dett,
            --- 31.05.2019 siac-6720
            pagopa_ric_id,
	        pagopa_elab_flusso_id,
            file_pagopa_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
         )
         select dataElaborazione,
                ric.pagopa_ric_flusso_tematica,
                ric.pagopa_ric_flusso_voce_code,
                ric.pagopa_ric_flusso_voce_desc,
                ric.pagopa_ric_flusso_sottovoce_code,
                ric.pagopa_ric_flusso_sottovoce_desc,
                ric.pagopa_ric_flusso_sottovoce_importo,
                ric.pagopa_ric_flusso_anno_esercizio,
                ric.pagopa_ric_flusso_anno_accertamento,
                ric.pagopa_ric_flusso_num_accertamento,
                ric.pagopa_ric_flusso_num_capitolo,
                ric.pagopa_ric_flusso_num_articolo,
                ric.pagopa_ric_flusso_pdc_v_fin,
                ric.pagopa_ric_flusso_titolo,
                ric.pagopa_ric_flusso_tipologia,
                ric.pagopa_ric_flusso_categoria,
                ric.pagopa_ric_flusso_str_amm,
                -- 31.05.2019 siac-6720
				ric.pagopa_ric_flusso_codice_benef,
                ric.pagopa_ric_flusso_ragsoc_benef,
           	    ric.pagopa_ric_flusso_nome_benef,
                ric.pagopa_ric_flusso_cognome_benef,
                ric.pagopa_ric_flusso_codfisc_benef,
              --  ric.pagopa_ric_flusso_flag_dett,
                -- 31.05.2019 siac-6720
                ric.pagopa_ric_id,
                pagopaElabFlussoId,
                filePagoPaId,
                clock_timestamp(),
                loginOperazione,
                enteProprietarioId
         from pagopa_t_riconciliazione ric
         where ric.file_pagopa_id=filePagoPaId
    	 and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--         and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
	     and   ric.pagopa_ric_flusso_id= pagoPaFlussoRec.pagopa_flusso_id
    	 and   ric.pagopa_ric_flusso_anno_provvisorio=pagoPaFlussoRec.pagopa_anno_provvisorio
		 and   ric.pagopa_ric_flusso_num_provvisorio=pagoPaFlussoRec.pagopa_num_provvisorio
         /*and   not exists
    	 ( select 1
	       from pagopa_t_riconciliazione_doc doc
    	   where doc.pagopa_ric_id=ric.pagopa_ric_id
	       and   doc.pagopa_ric_doc_subdoc_id is not null
    	   and   doc.data_cancellazione is null
	       and   doc.validita_fine is null
    	 )*/
	     /*and   not exists
	     ( select 1
    	   from pagopa_t_riconciliazione_doc doc
	       where doc.pagopa_ric_id=ric.pagopa_ric_id
      	   and   doc.pagopa_ric_doc_subdoc_id is null
	       and   doc.pagopa_ric_doc_stato_elab in ('E')
    	   and   doc.data_cancellazione is null
	       and   doc.validita_fine is null
    	 )*/
    	 and   ric.data_cancellazione is null
	     and   ric.validita_fine is null;

         strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                       ' Verifica inserimento pagopa_t_riconciliazione_doc.';
         -- controllo inserimento
		 codResult:=null;
         select 1 into codResult
         from pagopa_t_riconciliazione_doc doc
         where doc.pagopa_elab_flusso_id=pagopaElabFlussoId;
         if codResult is null then
             strMessaggioBck:=strMessaggio;
             strmessaggio:=strMessaggioBck||'. NON Effettuato. Aggiornamento pagopa_t_elaborazione.';
          	 update pagopa_t_elaborazione elab
             set   data_modifica=clock_timestamp(),
                   pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
                   pagopa_elab_errore_id=err.pagopa_ric_errore_id,
                   pagopa_elab_note=upper(strMessaggioFinale||' '||strmessaggio)
             from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
             where elab.pagopa_elab_id=filePagoPaElabId
             and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
             and   stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
             and   statonew.ente_proprietario_id=stato.ente_proprietario_id
             and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_ER_ST
             and   err.ente_proprietario_id=stato.ente_proprietario_id
             and   err.pagopa_ric_errore_code=PAGOPA_ERR_21
             and   elab.data_cancellazione is null
             and   elab.validita_fine is null;


             codResult:=-1;
             pagoPaErrCode:=PAGOPA_ERR_21;

             strMessaggio:=strMessaggioBck||' NON effettuato.Aggiornamento PAGOPA_ERR='||PAGOPA_ERR_19||'.';
			 update pagopa_t_riconciliazione ric
    	     set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
        	        data_modifica=clock_timestamp(),
            	    pagopa_ric_flusso_stato_elab='X',
                	login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
	         from pagopa_d_riconciliazione_errore err
    	     where ric.file_pagopa_id=filePagoPaId
    		 and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--             and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
	         and   err.ente_proprietario_id=ric.ente_proprietario_id
    	     and   err.pagopa_ric_errore_code=PAGOPA_ERR_21
	    	 and   ric.pagopa_ric_flusso_id= pagoPaFlussoRec.pagopa_flusso_id
	    	 and   ric.pagopa_ric_flusso_anno_provvisorio=pagoPaFlussoRec.pagopa_anno_provvisorio
			 and   ric.pagopa_ric_flusso_num_provvisorio=pagoPaFlussoRec.pagopa_num_provvisorio
        	 /*and   not exists
	    	 ( select 1
		       from pagopa_t_riconciliazione_doc doc
    		   where doc.pagopa_ric_id=ric.pagopa_ric_id
		       and   doc.pagopa_ric_doc_subdoc_id is not null
    		   and   doc.data_cancellazione is null
	    	   and   doc.validita_fine is null
	    	 )*/
		     /*and   not exists
	    	 ( select 1
	    	   from pagopa_t_riconciliazione_doc doc
		       where doc.pagopa_ric_id=ric.pagopa_ric_id
      		   and   doc.pagopa_ric_doc_subdoc_id is null
		       and   doc.pagopa_ric_doc_stato_elab in ('E')
    		   and   doc.data_cancellazione is null
	    	   and   doc.validita_fine is null
	    	 )*/
    		 and   ric.data_cancellazione is null
	    	 and   ric.validita_fine is null;


         else
         	codResult:=null;
            strMessaggio:=strMessaggio||' Inserimento effettuato.';
         end if;
		end if;

	    strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale||strMessaggio;
        insert into pagopa_t_elaborazione_log
        (
          pagopa_elab_id,
          pagopa_elab_file_id,
          pagopa_elab_log_operazione,
          ente_proprietario_id,
          login_operazione,
          data_creazione
        )
        values
        (
           filePagoPaElabId,
           filepagopaid,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
        );

        -- controllo dati su
        -- pagopa_t_elaborazione_flusso
        -- pagopa_t_riconciliazione_doc
        if codResult is null then
        	-- esistenza provvisorio di cassa
            strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                       ' Verifica esistenza provvisorio di cassa.';
            select 1 into codResult
            from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo
            where  tipo.ente_proprietario_id=enteProprietarioid
            and    tipo.provc_tipo_code='E'
            and    prov.provc_tipo_id=tipo.provc_tipo_id
            and    prov.provc_anno::integer=pagoPaFlussoRec.pagopa_anno_provvisorio
            and    prov.provc_numero::integer=pagoPaFlussoRec.pagopa_num_provvisorio
            and    prov.provc_data_annullamento is null
            and    prov.provc_data_regolarizzazione is null
            and    prov.data_cancellazione  is null
			and    prov.validita_fine is null;
		    if codResult is null then
            	pagoPaErrCode:=PAGOPA_ERR_22;
                codResult:=-1;
            else codResult:=null;
            end if;
            if codResult is null then
            	strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                       ' Verifica esistenza provvisorio di cassa regolarizzato [Ord.].';
                select 1 into codResult
                from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo,siac_r_ordinativo_prov_cassa rp
                where  tipo.ente_proprietario_id=enteProprietarioid
                and    tipo.provc_tipo_code='E'
                and    prov.provc_tipo_id=tipo.provc_tipo_id
                and    prov.provc_anno::integer=pagoPaFlussoRec.pagopa_anno_provvisorio
                and    prov.provc_numero::integer=pagoPaFlussoRec.pagopa_num_provvisorio
                and    rp.provc_id=prov.provc_id
                and    prov.provc_data_annullamento is null
                and    prov.provc_data_regolarizzazione is null
                and    prov.data_cancellazione  is null
                and    prov.validita_fine is null
                and    rp.data_cancellazione  is null
                and    rp.validita_fine is null;
                if codResult is null then
                    strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                       ' Verifica esistenza provvisorio di cassa regolarizzato [Doc.].';
                	select 1 into codResult
                    from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo,siac_r_subdoc_prov_cassa rp
                    where  tipo.ente_proprietario_id=enteProprietarioid
                    and    tipo.provc_tipo_code='E'
                    and    prov.provc_tipo_id=tipo.provc_tipo_id
                    and    prov.provc_anno::integer=pagoPaFlussoRec.pagopa_anno_provvisorio
                    and    prov.provc_numero::integer=pagoPaFlussoRec.pagopa_num_provvisorio
                    and    rp.provc_id=prov.provc_id
                    and    prov.provc_data_annullamento is null
                    and    prov.provc_data_regolarizzazione is null
                    and    prov.data_cancellazione  is null
                    and    prov.validita_fine is null
                    and    rp.data_cancellazione  is null
                    and    rp.validita_fine is null;
                end if;
                if codResult is not null then
                	pagoPaErrCode:=PAGOPA_ERR_38;
	                codResult:=-1;
                end if;
            end if;

            if pagoPaErrCode is not null then
              strMessaggioBck:=strMessaggio;
              strmessaggio:=strMessaggio||' NON esistente o regolarizzato. Aggiornamento pagopa_t_elaborazione.';
              update pagopa_t_elaborazione elab
              set    data_modifica=clock_timestamp(),
                     pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
                     pagopa_elab_errore_id=err.pagopa_ric_errore_id,
                     pagopa_elab_note=upper(strMessaggioFinale||' '||strMessaggio)
              from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
              where elab.pagopa_elab_id=filePagoPaElabId
              and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
              and   stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
              and   statonew.ente_proprietario_id=stato.ente_proprietario_id
              and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_SC_ST
              and   err.ente_proprietario_id=stato.ente_proprietario_id
              and   err.pagopa_ric_errore_code=pagoPaErrCode
              and   elab.data_cancellazione is null
              and   elab.validita_fine is null;

              codResult:=-1;


              strMessaggio:=strMessaggioBck||' NON esistente o regolarizzato.Aggiornamento pagopa_t_riconciliazione_doc PAGOPA_ERR='||pagoPaErrCode||'.';
              update pagopa_t_riconciliazione_doc doc
              set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                     data_modifica=clock_timestamp(),
                     pagopa_ric_doc_stato_elab='X',
                     login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
              from pagopa_d_riconciliazione_errore err
              where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
              and   err.ente_proprietario_id=doc.ente_proprietario_id
              and   err.pagopa_ric_errore_code=pagoPaErrCode
              and   doc.data_cancellazione is null
              and   doc.validita_fine is null;


              strMessaggio:=strMessaggioBck||' NON esistente o regolarizzato.Aggiornamento pagopa_t_riconciliazione PAGOPA_ERR='||pagoPaErrCode||'.';
              update pagopa_t_riconciliazione ric
              set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                     data_modifica=clock_timestamp(),
                     pagopa_ric_flusso_stato_elab='X',
                     login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
              from pagopa_d_riconciliazione_errore err,pagopa_t_riconciliazione_doc doc
              where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
              and   ric.pagopa_ric_id=doc.pagopa_ric_id
              and   err.ente_proprietario_id=doc.ente_proprietario_id
              and   err.pagopa_ric_errore_code=pagoPaErrCode
              and   doc.data_cancellazione is null
              and   doc.validita_fine is null
              and   ric.data_cancellazione is null
              and   ric.validita_fine is null;
            else codResult:=null;
            end if;

            -- esistenza accertamento
            if codResult is null then
                strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                       ' Verifica esistenza accertamenti.';
            	select 1 into codResult
                from pagopa_t_riconciliazione_doc doc
                where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
                and   not exists
                (
                select 1
				from siac_t_movgest mov, siac_d_movgest_tipo tipo,
                     siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
                     siac_r_movgest_ts_stato rs , siac_d_movgest_stato stato
                where   mov.bil_id=bilancioId
                and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
                and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
                and   tipo.movgest_tipo_id=mov.movgest_tipo_id
                and   tipo.movgest_tipo_code='A'
                and   ts.movgest_id=mov.movgest_id
                and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                and   tipots.movgest_ts_tipo_code='T'
                and   rs.movgest_ts_id=ts.movgest_ts_id
                and   stato.movgest_stato_id=rs.movgest_stato_id
                and   stato.movgest_stato_code='D'
                and   rs.data_cancellazione is null
                and   rs.validita_fine is null
                and   mov.data_cancellazione is null
                and   mov.validita_fine is null
                and   ts.data_cancellazione is null
                and   ts.validita_fine is null
                );

				if codResult is not null then
             		strMessaggioBck:=strMessaggio;
		            strmessaggio:=strMessaggio||' NON esistente. Aggiornamento pagopa_t_elaborazione.';
		          	update pagopa_t_elaborazione elab
		            set    data_modifica=clock_timestamp(),
    	                   pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
                           pagopa_elab_errore_id=err.pagopa_ric_errore_id,
        	               pagopa_elab_note=upper(strMessaggioFinale||' '||strmessaggio)
            		from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
	                where elab.pagopa_elab_id=filePagoPaElabId
    	            and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
        	        and   stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
            	    and   statonew.ente_proprietario_id=stato.ente_proprietario_id
	                and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_SC_ST
                    and   err.ente_proprietario_id=stato.ente_proprietario_id
                    and   err.pagopa_ric_errore_code=PAGOPA_ERR_23
    	            and   elab.data_cancellazione is null
        	        and   elab.validita_fine is null;

					pagoPaErrCode:=PAGOPA_ERR_23;
		            codResult:=-1;

                    strMessaggio:=strMessaggioBck||' NON esistente.Aggiornamento pagopa_t_riconciliazione_doc PAGOPA_ERR='||PAGOPA_ERR_23||'.';
			     	update pagopa_t_riconciliazione_doc doc
	     	        set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
    	    	           data_modifica=clock_timestamp(),
        	      	       pagopa_ric_doc_stato_elab='X',
                 		   login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
	                from pagopa_d_riconciliazione_errore err
    	            where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
                    -- 24.05.2021 Sofia Jira-SIAC-8213 - inizio
                    and   not exists
                    (
                    select 1
                    from siac_t_movgest mov, siac_d_movgest_tipo tipo,
                         siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
                         siac_r_movgest_ts_stato rs , siac_d_movgest_stato stato
                    where   mov.bil_id=bilancioId
                    and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
                    and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
                    and   tipo.movgest_tipo_id=mov.movgest_tipo_id
                    and   tipo.movgest_tipo_code='A'
                    and   ts.movgest_id=mov.movgest_id
                    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                    and   tipots.movgest_ts_tipo_code='T'
                    and   rs.movgest_ts_id=ts.movgest_ts_id
                    and   stato.movgest_stato_id=rs.movgest_stato_id
                    and   stato.movgest_stato_code='D'
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   mov.data_cancellazione is null
                    and   mov.validita_fine is null
                    and   ts.data_cancellazione is null
                    and   ts.validita_fine is null
                    )
                    -- 24.05.2021 Sofia Jira-SIAC-8213 - fine
	                and   err.ente_proprietario_id=doc.ente_proprietario_id
     	            and   err.pagopa_ric_errore_code=PAGOPA_ERR_23
    		        and   doc.data_cancellazione is null
	    	        and   doc.validita_fine is null;


            	    strMessaggio:=strMessaggioBck||' NON esistente.Aggiornamento pagopa_t_riconciliazione PAGOPA_ERR='||PAGOPA_ERR_23||'.';
			        update pagopa_t_riconciliazione ric
     	            set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
        	               data_modifica=clock_timestamp(),
              	           pagopa_ric_flusso_stato_elab='X',
                 	       login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
	                from pagopa_d_riconciliazione_errore err,pagopa_t_riconciliazione_doc doc
    	            where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
                    -- 24.05.2021 Sofia Jira-SIAC-8213 - inizio
                    and   not exists
                    (
                    select 1
                    from siac_t_movgest mov, siac_d_movgest_tipo tipo,
                         siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
                         siac_r_movgest_ts_stato rs , siac_d_movgest_stato stato
                    where   mov.bil_id=bilancioId
                    and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
                    and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
                    and   tipo.movgest_tipo_id=mov.movgest_tipo_id
                    and   tipo.movgest_tipo_code='A'
                    and   ts.movgest_id=mov.movgest_id
                    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                    and   tipots.movgest_ts_tipo_code='T'
                    and   rs.movgest_ts_id=ts.movgest_ts_id
                    and   stato.movgest_stato_id=rs.movgest_stato_id
                    and   stato.movgest_stato_code='D'
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   mov.data_cancellazione is null
                    and   mov.validita_fine is null
                    and   ts.data_cancellazione is null
                    and   ts.validita_fine is null
                    )
                    -- 24.05.2021 Sofia Jira-SIAC-8213 - inizio
                    and   ric.pagopa_ric_id=doc.pagopa_ric_id
	                and   err.ente_proprietario_id=doc.ente_proprietario_id
     	            and   err.pagopa_ric_errore_code=PAGOPA_ERR_23
    		        and   doc.data_cancellazione is null
	    	        and   doc.validita_fine is null
                    and   ric.data_cancellazione is null
	    	        and   ric.validita_fine is null;
        	    end if;
            end if;
        end if;

		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale||strMessaggio;
        insert into pagopa_t_elaborazione_log
        (
          pagopa_elab_id,
          pagopa_elab_file_id,
          pagopa_elab_log_operazione,
          ente_proprietario_id,
          login_operazione,
          data_creazione
        )
        values
        (
           filePagoPaElabId,
           filepagopaid,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
        );

        --- siac-6720 - 23.05.2019
        --  pagopa_t_riconciliazione_doc con il tipo di documento da creare
        --  trattare gli errori come sopra per accertamento non esistente
        --  se arrivo qui vuol dire che non ci sono errori e tutti i record
        --  non scartati hanno accertamento
        if codResult is null then
          strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
	                     pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
    	                 pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
        	             pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                         ' Aggiornamento tipo documento.';
          /*
          update pagopa_t_riconciliazione_doc doc
          set    pagopa_ric_doc_tipo_code=tipod.doc_tipo_code,
                 pagopa_ric_doc_tipo_id=tipod.doc_tipo_id
          from   siac_t_movgest mov, siac_d_movgest_tipo tipo,
                 siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
                 siac_r_movgest_ts_stato rs , siac_d_movgest_stato stato,
                 siac_d_doc_tipo tipod
          where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
          and   mov.bil_id=bilancioId
          and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
          and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
          and   tipo.movgest_tipo_id=mov.movgest_tipo_id
          and   tipo.movgest_tipo_code='A'
          and   ts.movgest_id=mov.movgest_id
          and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
          and   tipots.movgest_ts_tipo_code='T'
          and   rs.movgest_ts_id=ts.movgest_ts_id
          and   stato.movgest_stato_id=rs.movgest_stato_id
          and   stato.movgest_stato_code='D'
          and   tipod.ente_proprietario_id=tipo.ente_proprietario_id
          and   ( case  when ts.movgest_ts_prev_fatt=true then tipod.doc_tipo_id=docTipoFatId
          				when ts.movgest_ts_prev_cor=true  then tipod.doc_tipo_id=docTipoCorId
                        else tipod.doc_tipo_id=docTipoIpaId end)
          and   rs.data_cancellazione is null
          and   rs.validita_fine is null
          and   mov.data_cancellazione is null
          and   mov.validita_fine is null
          and   ts.data_cancellazione is null
          and   ts.validita_fine is null;*/


          update pagopa_t_riconciliazione_doc doc
          set    pagopa_ric_doc_tipo_code=tipod.doc_tipo_code,
                 pagopa_ric_doc_tipo_id=tipod.doc_tipo_id,
                 pagopa_ric_doc_flag_con_dett= (case when tipod.doc_tipo_id =docTipoFatId then true else false end )
          from
          (
          with
          accertamento as
          (
          select mov.movgest_anno::integer anno_accertamento,mov.movgest_numero::integer numero_accertamento  ,
                 ts.movgest_ts_id
          from  siac_t_movgest mov, siac_d_movgest_tipo tipo,
                siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
                siac_r_movgest_ts_stato rs , siac_d_movgest_stato stato
          where mov.bil_id=bilancioId
          and   tipo.movgest_tipo_id=mov.movgest_tipo_id
          and   tipo.movgest_tipo_code='A'
          and   ts.movgest_id=mov.movgest_id
          and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
          and   tipots.movgest_ts_tipo_code='T'
          and   rs.movgest_ts_id=ts.movgest_ts_id
          and   stato.movgest_stato_id=rs.movgest_stato_id
          and   stato.movgest_stato_code='D'
          and   rs.data_cancellazione is null
          and   rs.validita_fine is null
          and   mov.data_cancellazione is null
          and   mov.validita_fine is null
          and   ts.data_cancellazione is null
          and   ts.validita_fine is null
          ),
          -- FlagCollegamentoAccertamentoFattura
          acc_fattura as
          (
          select rattr.movgest_ts_id, coalesce(rattr.boolean,'N') fl_fatt
          from siac_r_movgest_ts_Attr rattr
          where rattr.ente_proprietario_id=enteProprietarioId
          and   rattr.attr_id=attrAccFatturaId
          and   coalesce(rattr.boolean,'N')='S'
          and   rattr.data_cancellazione is null
          and   rattr.validita_fine is null
          ),
          --FlagCollegamentoAccertamentoCorrispettivo
          acc_corrispettivo as
          (
          select rattr.movgest_ts_id,coalesce(rattr.boolean,'N') fl_corr
          from siac_r_movgest_ts_Attr rattr
          where rattr.ente_proprietario_id=enteProprietarioId
          and   rattr.attr_id=attrAccCorrispettivoId
          and   coalesce(rattr.boolean,'N')='S'
          and   rattr.data_cancellazione is null
          and   rattr.validita_fine is null
          )
          select accertamento.movgest_ts_id,accertamento.anno_accertamento, accertamento.numero_accertamento,
                 (case when coalesce(acc_fattura.fl_fatt,'N')='S' then docTipoFatId
                      when coalesce(acc_corrispettivo.fl_corr,'N')='S' then docTipoCorId
                      else docTipoIpaId end) doc_tipo_id
          from accertamento
               left join acc_fattura on ( accertamento.movgest_ts_id=acc_fattura.movgest_ts_id )
               left join acc_corrispettivo on ( accertamento.movgest_ts_id=acc_corrispettivo.movgest_ts_id )
          ) query,siac_d_doc_tipo tipod
          where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
          and   query.anno_accertamento=doc.pagopa_ric_doc_anno_accertamento
          and   query.numero_accertamento=doc.pagopa_ric_doc_num_accertamento
          and   tipod.doc_tipo_id=query.doc_tipo_id;

          strMessaggio:=strMessaggio||' Dati NON aggiornati ';
		  select 1 into codResult
		  from pagopa_t_riconciliazione_doc doc
          where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
          and   ( coalesce(doc.pagopa_ric_doc_tipo_code,'')='' or doc.pagopa_ric_doc_tipo_id is null);

          if codResult is not null then
            strMessaggioBck:=strMessaggio;
            strmessaggio:=strMessaggio||'  esistenti. Aggiornamento pagopa_t_elaborazione.';
            update pagopa_t_elaborazione elab
            set    data_modifica=clock_timestamp(),
                   pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
                   pagopa_elab_errore_id=err.pagopa_ric_errore_id,
                   pagopa_elab_note=upper(strMessaggioFinale||' '||strmessaggio)
            from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
            where elab.pagopa_elab_id=filePagoPaElabId
            and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
            and   stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
            and   statonew.ente_proprietario_id=stato.ente_proprietario_id
            and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_SC_ST
            and   err.ente_proprietario_id=stato.ente_proprietario_id
            and   err.pagopa_ric_errore_code=PAGOPA_ERR_48
            and   elab.data_cancellazione is null
            and   elab.validita_fine is null;

            pagoPaErrCode:=PAGOPA_ERR_48;
            codResult:=-1;

            strMessaggio:=strMessaggioBck||' esistenti.Aggiornamento pagopa_t_riconciliazione_doc PAGOPA_ERR='||PAGOPA_ERR_48||'.';
            update pagopa_t_riconciliazione_doc doc
            set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                   data_modifica=clock_timestamp(),
                   pagopa_ric_doc_stato_elab='X',
                   login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
            from pagopa_d_riconciliazione_errore err
            where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
            and   err.ente_proprietario_id=doc.ente_proprietario_id
            and   err.pagopa_ric_errore_code=PAGOPA_ERR_48
            and   doc.data_cancellazione is null
            and   doc.validita_fine is null;


            strMessaggio:=strMessaggioBck||' esistenti.Aggiornamento pagopa_t_riconciliazione PAGOPA_ERR='||PAGOPA_ERR_48||'.';
            update pagopa_t_riconciliazione ric
            set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                   data_modifica=clock_timestamp(),
                   pagopa_ric_flusso_stato_elab='X',
                   login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
            from pagopa_d_riconciliazione_errore err,pagopa_t_riconciliazione_doc doc
            where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
            and   ric.pagopa_ric_id=doc.pagopa_ric_id
            and   err.ente_proprietario_id=doc.ente_proprietario_id
            and   err.pagopa_ric_errore_code=PAGOPA_ERR_48
            and   doc.data_cancellazione is null
            and   doc.validita_fine is null
            and   ric.data_cancellazione is null
            and   ric.validita_fine is null;
          end if;


          strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale||strMessaggio;
          insert into pagopa_t_elaborazione_log
          (
            pagopa_elab_id,
            pagopa_elab_file_id,
            pagopa_elab_log_operazione,
            ente_proprietario_id,
            login_operazione,
            data_creazione
          )
          values
          (
             filePagoPaElabId,
             filepagopaid,
             strMessaggioLog,
             enteProprietarioId,
             loginOperazione,
             clock_timestamp()
          );
        end if;

		if codResult is null then
          --- inserire qui i dettagli ( pagopa_ric_doc_flag_dett=true) prendendoli da  tabella in più di Ale
          --- considerando quelli che hanno il tipo_code=FAT, pagopa_ric_doc_flag_con_dett=true da update sopra
          --- inserire in pagopa_t_riconciliazione_doc con pagopa_ric_doc_flag_dett=true
          --- in esegui devo poi esclure i pagopa_t_riconciliazione_doc.pagopa_ric_doc_flag_con_dett=true


		  strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
	                     pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
    	                 pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
        	             pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                         ' Inserimento pagopa_t_riconciliazione_doc -  dati di dettaglio.';
          insert into pagopa_t_riconciliazione_doc
          (
            pagopa_ric_doc_data,
            pagopa_ric_doc_voce_tematica,
  	        pagopa_ric_doc_voce_code,
			pagopa_ric_doc_voce_desc,
			pagopa_ric_doc_sottovoce_code,
		    pagopa_ric_doc_sottovoce_desc,
			pagopa_ric_doc_sottovoce_importo,
		    pagopa_ric_doc_anno_esercizio,
		    pagopa_ric_doc_anno_accertamento,
			pagopa_ric_doc_num_accertamento,
		    pagopa_ric_doc_num_capitolo,
		    pagopa_ric_doc_num_articolo,
		    pagopa_ric_doc_pdc_v_fin,
		    pagopa_ric_doc_titolo,
		    pagopa_ric_doc_tipologia,
		    pagopa_ric_doc_categoria,
		    pagopa_ric_doc_str_amm,
            pagopa_ric_doc_flag_dett,
            pagopa_ric_doc_tipo_code,
            pagopa_ric_doc_tipo_id,
		    pagopa_ric_doc_codice_benef,
            pagopa_ric_doc_ragsoc_benef,
            pagopa_ric_doc_nome_benef,
            pagopa_ric_doc_cognome_benef,
            pagopa_ric_doc_codfisc_benef,
            pagopa_ric_id,
            pagopa_ric_det_id,
	        pagopa_elab_flusso_id,
            pagopa_ric_doc_iuv, --- 12.08.2019 Sofia SIAC-6978,
            pagopa_ric_doc_data_operazione, -- 04.02.2020 Sofia SIAC-7375
            file_pagopa_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
          )
          select dataElaborazione,
	             doc.pagopa_ric_doc_voce_tematica,
	    	     doc.pagopa_ric_doc_voce_code,
	 			 doc.pagopa_ric_doc_voce_desc,
	  			 doc.pagopa_ric_doc_sottovoce_code,
	 		     doc.pagopa_ric_doc_sottovoce_desc,
	 			 det.pagopa_det_importo_versamento,
                 doc.pagopa_ric_doc_anno_esercizio,
                 doc.pagopa_ric_doc_anno_accertamento,
                 doc.pagopa_ric_doc_num_accertamento,
                 doc.pagopa_ric_doc_num_capitolo,
                 doc.pagopa_ric_doc_num_articolo,
                 doc.pagopa_ric_doc_pdc_v_fin,
                 doc.pagopa_ric_doc_titolo,
                 doc.pagopa_ric_doc_tipologia,
                 doc.pagopa_ric_doc_categoria,
                 doc.pagopa_ric_doc_str_amm,
                 true,
                 doc.pagopa_ric_doc_tipo_code,
                 doc.pagopa_ric_doc_tipo_id,
                 doc.pagopa_ric_doc_codice_benef,
                 -- det
                 det.pagopa_det_anag_ragione_sociale,
           	     det.pagopa_det_anag_nome,
                 det.pagopa_det_anag_cognome,
                 det.pagopa_det_anag_codice_fiscale,
                 doc.pagopa_ric_id,
                 det.pagopa_ric_det_id,
	             doc.pagopa_elab_flusso_id,
                 det.pagopa_det_versamento_id,  --- 12.08.2019 Sofia SIAC-6978
                 det.pagopa_det_data_pagamento, -- 04.02.2020 Sofia SIAC-7375
                 doc.file_pagopa_id,
                 clock_timestamp(),
                 loginOperazione,
                 enteProprietarioId
          from pagopa_t_riconciliazione_doc doc, pagopa_t_riconciliazione_det det
          where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
          and   doc.pagopa_ric_doc_flag_con_dett=true
          and   doc.pagopa_ric_doc_tipo_id=docTipoFatId
          and   det.pagopa_ric_id=doc.pagopa_ric_id
          and   det.data_cancellazione is null
 	      and   det.validita_fine is null;

          strMessaggio:=strMessaggio||' Verifica.';
		  select 1 into codResult
          from  pagopa_t_riconciliazione_doc doc
          where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
          and   doc.pagopa_ric_doc_flag_con_dett=true
          and   doc.pagopa_ric_doc_tipo_id=docTipoFatId
          and   not exists
          (
          select 1 from pagopa_t_riconciliazione_doc doc1
          where doc1.pagopa_elab_flusso_id=pagopaElabFlussoId
          and   doc1.pagopa_ric_id=doc.pagopa_ric_id
          and   doc1.pagopa_ric_doc_flag_dett=true
          );

		  if codResult is not null then
          	strMessaggioBck:=strMessaggio;
            strmessaggio:=strMessaggio||'  esistenti. Aggiornamento pagopa_t_elaborazione.';
            update pagopa_t_elaborazione elab
            set    data_modifica=clock_timestamp(),
                   pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
                   pagopa_elab_errore_id=err.pagopa_ric_errore_id,
                   pagopa_elab_note=upper(strMessaggioFinale||' '||strmessaggio)
            from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
            where elab.pagopa_elab_id=filePagoPaElabId
            and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
            and   stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
            and   statonew.ente_proprietario_id=stato.ente_proprietario_id
            and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_SC_ST
            and   err.ente_proprietario_id=stato.ente_proprietario_id
            and   err.pagopa_ric_errore_code=PAGOPA_ERR_49
            and   elab.data_cancellazione is null
            and   elab.validita_fine is null;

            pagoPaErrCode:=PAGOPA_ERR_49;
            codResult:=-1;

            strMessaggio:=strMessaggioBck||' esistenti.Aggiornamento pagopa_t_riconciliazione_doc PAGOPA_ERR='||PAGOPA_ERR_49||'.';
            update pagopa_t_riconciliazione_doc doc
            set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                   data_modifica=clock_timestamp(),
                   pagopa_ric_doc_stato_elab='X',
                   login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
            from pagopa_d_riconciliazione_errore err
            where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
            and   err.ente_proprietario_id=doc.ente_proprietario_id
            and   err.pagopa_ric_errore_code=PAGOPA_ERR_49
            and   doc.data_cancellazione is null
            and   doc.validita_fine is null;


            strMessaggio:=strMessaggioBck||' esistenti.Aggiornamento pagopa_t_riconciliazione PAGOPA_ERR='||PAGOPA_ERR_49||'.';
            update pagopa_t_riconciliazione ric
            set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                   data_modifica=clock_timestamp(),
                   pagopa_ric_flusso_stato_elab='X',
                   login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
            from pagopa_d_riconciliazione_errore err,pagopa_t_riconciliazione_doc doc
            where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
            and   ric.pagopa_ric_id=doc.pagopa_ric_id
            and   err.ente_proprietario_id=doc.ente_proprietario_id
            and   err.pagopa_ric_errore_code=PAGOPA_ERR_49
            and   doc.data_cancellazione is null
            and   doc.validita_fine is null
            and   ric.data_cancellazione is null
            and   ric.validita_fine is null;
          end if;

          strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale||strMessaggio;
          insert into pagopa_t_elaborazione_log
          (
            pagopa_elab_id,
            pagopa_elab_file_id,
            pagopa_elab_log_operazione,
            ente_proprietario_id,
            login_operazione,
            data_creazione
          )
          values
          (
             filePagoPaElabId,
             filepagopaid,
             strMessaggioLog,
             enteProprietarioId,
             loginOperazione,
             clock_timestamp()
          );
		end if;

		-- sono stati inseriti
        -- pagopa_t_elaborazione_flusso
        -- pagopa_t_riconciliazione_doc
        -- posso aggiornare su pagopa_t_elaborazione per elab=elaborato_in_corso
		if codResult is null then
		            strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                       ' Aggiornamento pagopa_t_elaborazione '||ELABORATO_IN_CORSO_ST||'.';
		          	update pagopa_t_elaborazione elab
		            set    data_modifica=clock_timestamp(),
    	                   pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
        	               pagopa_elab_note='AGGIORNAMENTO ELABORAZIONE SU FILE file_pagopa_id='||filePagoPaId::varchar||' IN STATO '||ELABORATO_IN_CORSO_ST||' '
            		from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew
	                where elab.pagopa_elab_id=filePagoPaElabId
    	            and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
        	        and   stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST)
            	    and   statonew.ente_proprietario_id=stato.ente_proprietario_id
	                and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_ST
    	            and   elab.data_cancellazione is null
        	        and   elab.validita_fine is null;
        end if;

		-- non sono stati inseriti
        -- pagopa_t_elaborazione_flusso
        -- pagopa_t_riconciliazione_doc
        -- quindi aggiornare siac_t_file_pagopa
        if codResult is not null then
	        strmessaggio:=strMessaggioBck||' Errore. Aggiornamento siac_t_file_pagopa.';
	       	update siac_t_file_pagopa file
          	set    data_modifica=clock_timestamp(),
            	   file_pagopa_stato_id=stato.file_pagopa_stato_id,
                   file_pagopa_errore_id=err.pagopa_ric_errore_id,
                   file_pagopa_code=coalesce(filepagopaFileXMLId,file.file_pagopa_code),
                   file_pagopa_note=coalesce(strMessaggioFinale,' ' )||coalesce(strmessaggio,' '),
                   login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
            from siac_d_file_pagopa_stato stato, pagopa_d_riconciliazione_errore err
            where file.file_pagopa_id=filePagoPaId
            and   stato.ente_proprietario_id=file.ente_proprietario_id
            and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_SC_ST
            and   err.ente_proprietario_id=stato.ente_proprietario_id
            and   err.pagopa_ric_errore_code=pagoPaErrCode;
        end if;

	    strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale||strMessaggio;
        insert into pagopa_t_elaborazione_log
        (
          pagopa_elab_id,
          pagopa_elab_file_id,
          pagopa_elab_log_operazione,
          ente_proprietario_id,
          login_operazione,
          data_creazione
        )
        values
        (
           filePagoPaElabId,
           filepagopaid,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
        );

    end loop;
    ---------- fine gestione flussi su piano_t_riconciliazione per pagopa_elab_id ----------------

    outPagoPaElabId:=filePagoPaElabId;
    messaggioRisultato:=upper(strMessaggioFinale||' OK');
    strMessaggioLog:='Fine fnc_pagopa_t_elaborazione_riconc_insert - '||messaggioRisultato;
    insert into pagopa_t_elaborazione_log
    (
      pagopa_elab_id,
      pagopa_elab_file_id,
      pagopa_elab_log_operazione,
      ente_proprietario_id,
      login_operazione,
      data_creazione
    )
    values
    (
       filePagoPaElabId,
       filepagopaid,
       strMessaggioLog,
       enteProprietarioId,
       loginOperazione,
       clock_timestamp()
    );

    return;
exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);
       	outPagoPaElabId:=-1;

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	outPagoPaElabId:=-1;

        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
      	outPagoPaElabId:=-1;

        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	outPagoPaElabId:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter function fnc_pagopa_t_elaborazione_riconc_insert
(
  integer,
  varchar,
  varchar,
  varchar,
  varchar,
  integer,
  integer,
  integer,
  varchar,
  timestamp,
  out integer,
  out integer,
  out varchar
) OWNER to siac;
-- SIAC-8213 - 24.05.2021 Sofia - fine 



-- 8123

-- FUNCTION: siac.fnc_pagopa_t_riconc_doc_cerca_dettagli_elab_di_aggregato(integer, integer, integer)

-- DROP FUNCTION siac.fnc_pagopa_t_riconc_doc_cerca_dettagli_elab_di_aggregato(integer, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_pagopa_t_riconc_doc_cerca_dettagli_elab_di_aggregato(
	p_pagopa_ric_id integer,
	p_pagopa_elab_flusso_id integer,
	p_codice_ente integer)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE
	strMessaggio    			VARCHAR(1500):='';  
    codicerisultato 			integer:=null;
    messaggiorisultato 			VARCHAR(1500):='';
	v_cnt 						integer:=null;
	v_count_dettagli_tutti		integer:=null;
	v_count_dettagli_elaborati	integer:=null;
	
BEGIN
     codicerisultato :=0;
	 v_cnt :=0;
	 v_count_dettagli_tutti := 0;
	 v_count_dettagli_elaborati := 0;
	 messaggiorisultato :='Inizio.';
    
    -- 2 errore generico
    -- 1 ko, non tutti i dettagli sono stati elaborati con successo
    -- 0 ok, tutti i dettagli sono stati elaborati con successo

	strMessaggio:= 'Verifica parametri di input.';
 	if (p_pagopa_ric_id is  null) 
	then
		codicerisultato :=2;	 
		messaggiorisultato := 'p_pagopa_ric_id NULL';
		return codicerisultato::varchar ||'-'||messaggiorisultato;
	end if;
	if (p_pagopa_elab_flusso_id is  null) 
	then
		codicerisultato :=2;	 
		messaggiorisultato := 'p_pagopa_elab_flusso_id NULL';
		return codicerisultato::varchar ||'-'||messaggiorisultato;
	end if;
	if (p_codice_ente is  null) 
	then
		codicerisultato :=2;	 
		messaggiorisultato := 'p_codice_ente NULL';
		return codicerisultato::varchar ||'-'||messaggiorisultato;
	end if;
	
	
	------------------------------------------------------------------------------------------- 
	--- Query che torna il numero di dettagli di una riconciliazione (aggregato)
	------------------------------------------------------------------------------------------- 
	
	strMessaggio:= 'Lettura v_count_dettagli_tutti';
	select count(*)
	into
	v_count_dettagli_tutti
	from siac.pagopa_t_riconciliazione_doc doc
	where doc.ente_proprietario_id = p_codice_ente
		 and doc.data_cancellazione is null
		 and doc.pagopa_ric_id = p_pagopa_ric_id
		 and doc.pagopa_elab_flusso_id = p_pagopa_elab_flusso_id
		 and doc.pagopa_ric_doc_flag_dett = true
		 and doc.pagopa_ric_doc_flag_con_dett = false;
	raise notice ' Letti: v_count_dettagli_tutti=% ',
		v_count_dettagli_tutti;
	
	
	------------------------------------------------------------------------------------------- 
	--- Query che torna il numero di dettagli di una riconciliazione (aggregato)
	--- che sono stati elaborati correttamente (senza errori)
	------------------------------------------------------------------------------------------- 
	strMessaggio:= 'Lettura v_count_dettagli_elaborati';
	select count(*)
	into
	v_count_dettagli_elaborati
	from siac.pagopa_t_riconciliazione_doc
	where pagopa_t_riconciliazione_doc.ente_proprietario_id = p_codice_ente
		 and pagopa_t_riconciliazione_doc.data_cancellazione is null
		 and pagopa_t_riconciliazione_doc.pagopa_ric_id = p_pagopa_ric_id
		 and pagopa_t_riconciliazione_doc.pagopa_elab_flusso_id = p_pagopa_elab_flusso_id
		 and pagopa_t_riconciliazione_doc.pagopa_ric_doc_flag_dett = true
		 and pagopa_t_riconciliazione_doc.pagopa_ric_doc_flag_con_dett = false
		 and pagopa_t_riconciliazione_doc.pagopa_ric_doc_stato_elab = 'S'
		 and pagopa_t_riconciliazione_doc.pagopa_ric_doc_subdoc_id is not null;
	raise notice ' Letti: v_count_dettagli_elaborati=% ',
		v_count_dettagli_elaborati;
		
		
	------------------------------------------------------------------------------------------- 
	--- Confrontiamo i due valori trovati per sapere se tutti i dettagli di una 
	--- riconciliazione (aggregato) sono stati elaborati correttamente
	
	--- (v_count_dettagli_tutti - v_count_dettagli_elaborati) =
	--- se 0 allora sono stati tutti correttamente (senza errori)
	--- se diverso da 0 allora non tutti i dettagli sono stati elaborati correttamente (senza errori)
	------------------------------------------------------------------------------------------- 
	codicerisultato :=(v_count_dettagli_tutti - v_count_dettagli_elaborati);

    return codicerisultato::varchar ; --||'-'||messaggiorisultato;

exception
    when RAISE_EXCEPTION THEN
    	raise notice 'ERRORE DB: % % %',strMessaggio,SQLSTATE, substring(upper(SQLERRM) from 1 for 2500);
        codicerisultato:=2;
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        return codicerisultato::varchar ||'-'||messaggiorisultato;
	when others  THEN
 		raise notice 'ERRORE DB: % % %',strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 2500);
        codicerisultato:=2;
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        return codicerisultato::varchar ||'-'||messaggiorisultato;
END;
$BODY$;




-- 8046

--inserimento azioni
--insert azione OP-CRUSCOTTO-aggiornaAccPagopa
INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, verificauo, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-CRUSCOTTO-aggiornaAccPagopa', 'Aggiorna accertamento pagoPA', a.azione_tipo_id, b.gruppo_azioni_id, '/../siacbilapp/azioneRichiesta.do', FALSE, now(), a.ente_proprietario_id,  'admin'
FROM siac.siac_d_azione_tipo a JOIN siac.siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'AZIONE_SECONDARIA'
AND b.gruppo_azioni_code = 'FIN_BASE2'
AND NOT EXISTS (
  SELECT 1
  FROM siac.siac_t_azione z
  WHERE z.azione_code = 'OP-CRUSCOTTO-aggiornaAccPagopa'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

/*
 * SIAC-8046 CM 15/04-19/04/2021 PagoPA Task 2.2-2.3
 * 
 * function per aggiornamento di anno e numero accertamento di una riconciliazione.
 * 
 */

-- FUNCTION: siac.fnc_pagopa_t_riconc_aggiorna_accertamento(integer, integer, integer, integer, integer)

-- DROP FUNCTION siac.fnc_pagopa_t_riconc_aggiorna_accertamento(integer, integer, integer, integer, integer);

-- drop della function con il vecchio nome
DROP FUNCTION if exists siac.fnc_siac_aggiornaaccertamentopagopa(integer, integer, integer, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_pagopa_t_riconc_aggiorna_accertamento(
	p_pagopa_ric_id integer,
	p_pagopa_ric_flusso_anno_accertamento integer,
	p_pagopa_ric_flusso_num_accertamento integer,
	p_codice_ente integer,
	p_anno_esercizio integer)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE
	strMessaggio    			VARCHAR(1500):='';  
    codicerisultato 			integer:=null;
    messaggiorisultato 			VARCHAR(1500):='';
	v_cnt 						integer:=null;
	v_pagopa_ric_flusso_anno_accertamento integer:=null;
	v_pagopa_ric_flusso_num_accertamento integer:=null;
	v_pagopa_ric_flusso_stato_elab VARCHAR(1500):='';--character varying;
	v_file_pagopa_id 			integer:=null;
	v_file_pagopa_stato_id 		integer:=null;
	v_count_file_pagopa_id 		integer:=null;
	
BEGIN
     codicerisultato :=0;
	 v_cnt := 0;
	 messaggiorisultato :='Inizio.';
    
    -- 2 errore gestito (nessun record prima query/collegamento DE/DS)
    -- 1 errore generico
    --  0 ok	

	strMessaggio:= 'Verifica parametri di input.';
 	if (p_pagopa_ric_id is  null) 
	then
		codicerisultato :=2;	 
		messaggiorisultato := 'p_pagopa_ric_id NULL';
		return codicerisultato::varchar ||'-'||messaggiorisultato;
	end if;
	if (p_pagopa_ric_flusso_anno_accertamento is  null) 
	then
		codicerisultato :=2;	 
		messaggiorisultato := 'p_pagopa_ric_flusso_anno_accertamento NULL';
		return codicerisultato::varchar ||'-'||messaggiorisultato;
	end if;
	if (p_pagopa_ric_flusso_num_accertamento is  null) 
	then
		codicerisultato :=2;	 
		messaggiorisultato := 'p_pagopa_ric_flusso_num_accertamento NULL';
		return codicerisultato::varchar ||'-'||messaggiorisultato;
	end if;
	if (p_codice_ente is  null) 
	then
		codicerisultato :=2;	 
		messaggiorisultato := 'p_codice_ente NULL';
		return codicerisultato::varchar ||'-'||messaggiorisultato;
	end if;
	if (p_anno_esercizio is  null) 
	then
		codicerisultato :=2;	 
		messaggiorisultato := 'p_anno_esercizio NULL';
		return codicerisultato::varchar ||'-'||messaggiorisultato;
	end if;
	
	strMessaggio:= 'Lettura dati attuali.';
	select 
	pagopa_t_riconciliazione.pagopa_ric_flusso_anno_accertamento, 
	pagopa_t_riconciliazione.pagopa_ric_flusso_num_accertamento,
	pagopa_t_riconciliazione.pagopa_ric_flusso_stato_elab,
	pagopa_t_riconciliazione.file_pagopa_id
	into
	v_pagopa_ric_flusso_anno_accertamento,
	v_pagopa_ric_flusso_num_accertamento,
	v_pagopa_ric_flusso_stato_elab,
	v_file_pagopa_id
	from siac.pagopa_t_riconciliazione
	where pagopa_t_riconciliazione.ente_proprietario_id = p_codice_ente
		 and pagopa_t_riconciliazione.data_cancellazione is null
		 and pagopa_t_riconciliazione.pagopa_ric_flusso_anno_esercizio = p_anno_esercizio
		 and pagopa_t_riconciliazione.pagopa_ric_id = p_pagopa_ric_id;
	raise notice ' Letti: v_pagopa_ric_flusso_anno_accertamento=% v_pagopa_ric_flusso_num_accertamento=% v_pagopa_ric_flusso_stato_elab=% v_file_pagopa_id=%',
		v_pagopa_ric_flusso_anno_accertamento,
		v_pagopa_ric_flusso_num_accertamento,
		v_pagopa_ric_flusso_stato_elab,
		v_file_pagopa_id;

	strMessaggio:= 'Lettura v_file_pagopa_stato_id';
	select 
	siac_d_file_pagopa_stato.file_pagopa_stato_id
	into
	v_file_pagopa_stato_id
	from siac.siac_d_file_pagopa_stato
	where siac_d_file_pagopa_stato.ente_proprietario_id = p_codice_ente 
		and siac_d_file_pagopa_stato.data_cancellazione is null
		and siac_d_file_pagopa_stato.file_pagopa_stato_code = 'ELABORATO_IN_CORSO_SC';
	raise notice ' Letti: v_file_pagopa_stato_id=% ',
		v_file_pagopa_stato_id;
	
	strMessaggio:= 'Lettura v_count_file_pagopa_id';
	SELECT count(*)
	into
	v_count_file_pagopa_id
	FROM siac.pagopa_t_riconciliazione
	WHERE pagopa_t_riconciliazione.ente_proprietario_id = p_codice_ente
		 AND pagopa_t_riconciliazione.data_cancellazione is null
		 AND pagopa_t_riconciliazione.pagopa_ric_flusso_anno_esercizio = p_anno_esercizio
		 AND pagopa_t_riconciliazione.file_pagopa_id = v_file_pagopa_id
		 AND pagopa_t_riconciliazione.pagopa_ric_flusso_stato_elab = 'E'
		 AND pagopa_t_riconciliazione.pagopa_ric_id != p_pagopa_ric_id;
	raise notice ' Letti: v_count_file_pagopa_id=% ',
		v_count_file_pagopa_id;
		
	------------------------------------------------------------------------------------------- 
	--- Caso 1 - in cui esistono i valori per anno e numero accertamento
	------------------------------------------------------------------------------------------- 
	if((v_pagopa_ric_flusso_anno_accertamento is not null) 
	   and (v_pagopa_ric_flusso_num_accertamento is not null)
	  and (v_pagopa_ric_flusso_anno_accertamento != 0)
	  and (v_pagopa_ric_flusso_num_accertamento != 0))
	then
		v_cnt := 0;
		--update normale
		strMessaggio:= 'Update normale';

		UPDATE pagopa_t_riconciliazione
		SET pagopa_ric_flusso_anno_accertamento = p_pagopa_ric_flusso_anno_accertamento, 
			pagopa_ric_flusso_num_accertamento = p_pagopa_ric_flusso_num_accertamento,
			data_modifica = now(),
			login_operazione = '_'||login_operazione
		WHERE ente_proprietario_id = p_codice_ente
			 AND data_cancellazione is null
			 AND pagopa_ric_flusso_anno_esercizio = p_anno_esercizio
			 AND pagopa_ric_id = p_pagopa_ric_id;
		GET DIAGNOSTICS v_cnt = ROW_COUNT;
		raise notice ' MOdificati: v_cnt=% ', v_cnt;

		if v_cnt != 0 
		then
			codicerisultato :=0;	 
			messaggiorisultato := 'Aggiornamento andato a buon fine';
		else
			codicerisultato :=2;	 
			messaggiorisultato := 'Aggiornamento andato a buon fine';
		end if;

	------------------------------------------------------------------------------------------- 
	--- Caso 2 - in cui non esistono i valori per anno e numero accertamento e pagopa_ric_flusso_stato_elab = 'E'
	------------------------------------------------------------------------------------------- 
	elsif (((v_pagopa_ric_flusso_anno_accertamento is null) or (v_pagopa_ric_flusso_anno_accertamento = 0))
		   and ((v_pagopa_ric_flusso_num_accertamento is null) or (v_pagopa_ric_flusso_num_accertamento = 0))
		   and (v_pagopa_ric_flusso_stato_elab = 'E'))
	then
		v_cnt := 0;
		--casi particolari(caso 2)
		strMessaggio:= 'casi particolari(caso 2.1)';

		UPDATE pagopa_t_riconciliazione
		SET pagopa_ric_flusso_anno_accertamento = p_pagopa_ric_flusso_anno_accertamento, 
			pagopa_ric_flusso_num_accertamento = p_pagopa_ric_flusso_num_accertamento,
			pagopa_ric_errore_id = null,
			pagopa_ric_flusso_stato_elab = 'N',
			data_modifica = now(),
			login_operazione = '_'||login_operazione
		WHERE ente_proprietario_id = p_codice_ente
			 AND data_cancellazione is null
			 AND pagopa_ric_flusso_anno_esercizio = p_anno_esercizio
			 AND pagopa_ric_id = p_pagopa_ric_id;

		GET DIAGNOSTICS v_cnt = ROW_COUNT;
		if v_cnt != 0 
		then
			if v_count_file_pagopa_id = 0 	--vuol dire che si deve fare un'altra update 
											-- (non ci sono altri dettagli con pagopa_ric_flusso_stato_elab = 'E')
			then
				v_cnt := 0;
				strMessaggio:= 'Caso 2.2 si deve fare altra update';

				UPDATE siac.siac_t_file_pagopa
				SET validita_fine = null,
					file_pagopa_stato_id = v_file_pagopa_stato_id,
					data_modifica = now(),
					login_operazione = '_'||login_operazione
				WHERE ente_proprietario_id = p_codice_ente
					 AND data_cancellazione is null
					 AND file_pagopa_id = v_file_pagopa_id; 

				GET DIAGNOSTICS v_cnt = ROW_COUNT;
				if v_cnt != 0 
				then
					codicerisultato :=0;	 
					messaggiorisultato := 'Aggiornamento andato a buon fine';
				else
					codicerisultato :=2;	 
					messaggiorisultato := 'Aggiornamento non andato a buon fine';
				end if;
			else
				codicerisultato :=0;	 
				messaggiorisultato := 'Aggiornamento andato a buon fine';
			end if;
		else
			codicerisultato :=2;	 
			messaggiorisultato := 'Aggiornamento non andato a buon fine';
		end if;

 	------------------------------------------------------------------------------------------- 
	--- Caso NON GESTITO
	------------------------------------------------------------------------------------------- 
	else
		-- altro non gestito
		codicerisultato :=2;	 
		messaggiorisultato := 'Condizione non gestita. Aggiornamento non andato a buon fine';
	end if;

    return codicerisultato::varchar ||'-'||messaggiorisultato;

exception
    when RAISE_EXCEPTION THEN
    	raise notice 'ERRORE DB: % % %',strMessaggio,SQLSTATE, substring(upper(SQLERRM) from 1 for 2500);
        codicerisultato:=1;
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        return codicerisultato::varchar ||'-'||messaggiorisultato;
	when others  THEN
 		raise notice 'ERRORE DB: % % %',strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 2500);
        codicerisultato:=1;
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        return codicerisultato::varchar ||'-'||messaggiorisultato;
END;
$BODY$;
-- fine 8046

-- INIZIO SIAC-8188
-- ACCERTAMENTO DA CAPITOLO ENTRATA
DROP FUNCTION  IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata(_uid_capitoloentrata integer, _anno character varying, _filtro_crp character varying, _limit integer, _page integer);


CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata(_uid_capitoloentrata integer, _anno character varying, _filtro_crp character varying, _limit integer, _page integer)
 RETURNS TABLE(uid integer, accertamento_anno integer, accertamento_numero numeric, accertamento_desc character varying, soggetto_code character varying, soggetto_desc character varying, accertamento_stato_desc character varying, importo numeric, capitolo_anno integer, capitolo_numero integer, capitolo_articolo integer, ueb_numero character varying, attoamm_numero integer, attoamm_anno character varying, attoamm_stato_desc character varying, attoamm_sac_code character varying, attoamm_sac_desc character varying, attoamm_tipo_code character varying, attoamm_tipo_desc character varying, pdc_code character varying, pdc_desc character varying, attoamm_oggetto character varying
 	--SIAC-8188
 	, attoal_causale character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
	_offset INTEGER := (_page) * _limit;
	rec record;
	v_movgest_ts_id integer;
	v_attoamm_id integer;
BEGIN

	for rec in
		select
			a.elem_id,
			c2.anno,
			a.elem_code,
			a.elem_code2,
			a.elem_code3,
			e.movgest_ts_id,
			c.movgest_anno,
			c.movgest_numero,
			c.movgest_desc,
			f.movgest_ts_det_importo,
			l.movgest_stato_desc,
			c.movgest_id,
			n.classif_code pdc_code,
			n.classif_desc pdc_desc
		from
			siac_t_bil_elem a,
			siac_t_bil b2,
			siac_t_periodo c2,
			siac_r_movgest_bil_elem b,
			siac_t_movgest c,
			siac_d_movgest_tipo d,
			siac_t_movgest_ts e,
			siac_t_movgest_ts_det f,
			siac_d_movgest_ts_tipo g,
			siac_d_movgest_ts_det_tipo h,
			siac_r_movgest_ts_stato i,
			siac_d_movgest_stato l,
			siac_r_movgest_class m,
			siac_t_class n,
			siac_d_class_tipo o,
			siac_t_bil p,
			siac_t_periodo q
		where a.bil_id=b2.bil_id
		and c2.periodo_id=b2.periodo_id
		and c.movgest_id=b.movgest_id
		and b.elem_id=a.elem_id
		and d.movgest_tipo_id=c.movgest_tipo_id
		and e.movgest_id=c.movgest_id
		and f.movgest_ts_id=e.movgest_ts_id
		and g.movgest_ts_tipo_id=e.movgest_ts_tipo_id
		and h.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
		and l.movgest_stato_id=i.movgest_stato_id
		and i.movgest_ts_id=e.movgest_ts_id
		and m.movgest_ts_id = e.movgest_ts_id
		and n.classif_id = m.classif_id
		and o.classif_tipo_id = n.classif_tipo_id
		and p.bil_id = c.bil_id
		and q.periodo_id = p.periodo_id
		and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
		and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
		and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
		and b.data_cancellazione is null
		and c.data_cancellazione is null
		and d.data_cancellazione is null
		and e.data_cancellazione is null
		and f.data_cancellazione is null
		and g.data_cancellazione is null
		and h.data_cancellazione is null
		and i.data_cancellazione is null
		and l.data_cancellazione is null
		and m.data_cancellazione is null
		and n.data_cancellazione is null
		and o.data_cancellazione is null
		and d.movgest_tipo_code='A'
		and h.movgest_ts_det_tipo_code='A'
		and g.movgest_ts_tipo_code='T'
		and o.classif_tipo_code IN ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
		and a.elem_id=_uid_capitoloentrata
		and q.anno = _anno
        -- 12.07.2018 Sofia jira siac-6193
        and (case when coalesce(_filtro_crp,'X')='R' then c.movgest_anno<_anno::integer
                  when coalesce(_filtro_crp,'X')='C' then c.movgest_anno=_anno::integer
                  when coalesce(_filtro_crp,'X')='P' then c.movgest_anno>_anno::integer
                  else true end )
		order by
			c.movgest_anno,
			c.movgest_numero
		LIMIT _limit
		OFFSET _offset

		loop

			uid:=rec.movgest_id;
			capitolo_anno:=rec.anno::integer;
			capitolo_numero:=rec.elem_code::integer;
			capitolo_articolo:=rec.elem_code2::integer;
			ueb_numero:=rec.elem_code3;
			v_movgest_ts_id:=rec.movgest_ts_id;
			accertamento_anno:=rec.movgest_anno;
			accertamento_numero:=rec.movgest_numero;
			accertamento_desc:=rec.movgest_desc;
			importo:=rec.movgest_ts_det_importo;
			accertamento_stato_desc:=rec.movgest_stato_desc;
			pdc_code:=rec.pdc_code;
			pdc_desc:=rec.pdc_desc;

			select
				y.soggetto_code,
				y.soggetto_desc
			into
				soggetto_code,
				soggetto_desc
			from
				siac_r_movgest_ts_sog z,
				siac_t_soggetto y
			where z.soggetto_id=y.soggetto_id
			and now() BETWEEN z.validita_inizio
			and COALESCE(z.validita_fine,now())
			and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
			and z.data_cancellazione is null
			and y.data_cancellazione is null
			and z.movgest_ts_id=v_movgest_ts_id;

			--classe di soggetti
			if soggetto_code is null then

				select
					l.soggetto_classe_code,
					l.soggetto_classe_desc
				into
					soggetto_code,
					soggetto_desc
				from
					siac_t_soggetto g,
					siac_r_movgest_ts_sogclasse h,
					siac_r_soggetto_classe i,
					siac_d_soggetto_classe l
				where g.soggetto_id=i.soggetto_id
				and h.soggetto_classe_id=l.soggetto_classe_id
				and i.soggetto_classe_id=l.soggetto_classe_id
				and now() between h.validita_inizio and coalesce(h.validita_fine, now())
				and g.data_cancellazione is null
				and h.data_cancellazione is null
				and now() between i.validita_inizio and coalesce(i.validita_fine, now())
				and h.movgest_ts_id=v_movgest_ts_id;
			end if;

			select
				q.attoamm_id,
				q.attoamm_numero,
				q.attoamm_anno,
				t.attoamm_stato_desc,
				r.attoamm_tipo_code,
				r.attoamm_tipo_desc,
                -- 12.07.2018 Sofia jira siac-6193
                q.attoamm_oggetto,
                --SIAC-8188
               	staa.attoal_causale
			into
				v_attoamm_id,
				attoamm_numero,
				attoamm_anno,
				attoamm_stato_desc,
				attoamm_tipo_code,
				attoamm_tipo_desc,
                attoamm_oggetto,
                --SIAC-8188
                attoal_causale
			from
				siac_r_movgest_ts_atto_amm p,
				siac_d_atto_amm_tipo r,
				siac_r_atto_amm_stato s,
				siac_d_atto_amm_stato t,
				siac_t_atto_amm q
			--SIAC-8188 se ci sono corrisponsenze le ritorno
			left join siac_t_atto_allegato staa on q.attoamm_id = staa.attoamm_id 
			where p.attoamm_id=q.attoamm_id
			and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
			and r.attoamm_tipo_id=q.attoamm_tipo_id
			and s.attoamm_id=q.attoamm_id
			and t.attoamm_stato_id=s.attoamm_stato_id
			and now() BETWEEN s.validita_inizio and COALESCE(s.validita_fine,now())
			and p.movgest_ts_id=rec.movgest_ts_id
			and p.data_cancellazione is null
			and q.data_cancellazione is null
			and r.data_cancellazione is null
			and s.data_cancellazione is null
			and t.data_cancellazione is null;

			--sac
			select
				y.classif_code,
				y.classif_desc
			into
				attoamm_sac_code,
				attoamm_sac_desc
			from
				siac_r_atto_amm_class z,
				siac_t_class y,
				siac_d_class_tipo x
			where z.classif_id=y.classif_id
			and x.classif_tipo_id=y.classif_tipo_id
			and x.classif_tipo_code  IN ('CDC', 'CDR')
			and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
			and z.attoamm_id=v_attoamm_id;

			return next;

		end loop;

	return;

END;
$function$
;


-- REVERSALE DA CAPITOLO ENTRATA
DROP FUNCTION  IF EXISTS siac.fnc_siac_cons_entita_reversale_from_capitoloentrata(_uid_capitoloentrata integer, _filtro_crp character varying, _limit integer, _page integer);


CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_reversale_from_capitoloentrata(_uid_capitoloentrata integer, _filtro_crp character varying, _limit integer, _page integer)
 RETURNS TABLE(uid integer, ord_numero numeric, ord_desc character varying, ord_emissione_data timestamp without time zone, soggetto_code character varying, soggetto_desc character varying, accredito_tipo_code character varying, accredito_tipo_desc character varying, ord_stato_desc character varying, importo numeric, ord_ts_code character varying, attoamm_numero integer, attoamm_anno character varying, attoamm_stato_desc character varying, attoamm_sac_code character varying, attoamm_sac_desc character varying, attoamm_tipo_code character varying, attoamm_tipo_desc character varying, uid_capitolo integer, capitolo_numero character varying, capitolo_articolo character varying, ueb_numero character varying, capitolo_desc character varying, capitolo_anno character varying, provc_anno integer, provc_numero numeric, provc_data_convalida timestamp without time zone, ord_quietanza_data timestamp without time zone, conto_tesoreria character varying, distinta_code character varying, distinta_desc character varying, ord_split character varying, ord_ritenute character varying
  	--SIAC-8188
 	, attoal_causale character varying, attoamm_oggetto character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
	_offset INTEGER := (_page) * _limit;
	_test VARCHAR := 'test';
rec record;
v_ord_id integer;
v_ord_ts_id integer;
v_attoamm_id integer;
BEGIN

	for rec in
     -- 12.07.2018 Sofia jira SIAC-6193 C,R
     WITH
      movimenti as
      (
      select rmov.ord_ts_id, mov.movgest_anno
      from   siac_r_movgest_bil_elem re,siac_t_movgest mov,
             siac_t_movgest_ts ts, siac_r_ordinativo_ts_movgest_ts rmov
      where  re.elem_id=_uid_capitoloentrata
      and    mov.movgest_id=re.movgest_id
      and    ts.movgest_id=mov.movgest_id
      and    rmov.movgest_ts_id=ts.movgest_ts_id
      and    re.data_cancellazione is null
      and    now() BETWEEN re.validita_inizio and COALESCE(re.validita_fine,now())
      and    mov.data_cancellazione is null
      and    now() BETWEEN mov.validita_inizio and COALESCE(mov.validita_fine,now())
      and    ts.data_cancellazione is null
      and    now() BETWEEN ts.validita_inizio and COALESCE(ts.validita_fine,now())
      and    rmov.data_cancellazione is null
      and    now() BETWEEN rmov.validita_inizio and COALESCE(rmov.validita_fine,now())
      ),
      ordinativi as
      (
		select
			a.elem_id,
			c2.anno,
			a.elem_code,
			a.elem_code2,
			a.elem_code3,
			d.ord_id,
			d.ord_anno,
			d.ord_numero,
			d.ord_desc,
			d.ord_emissione_data,
			g.ord_stato_desc,
			h.ord_ts_id,
			h.ord_ts_code,
            -- 12.07.2018 Sofia jira siac-6193
            d.contotes_id,
            d.dist_id
		from
			siac_t_bil_elem a,
			siac_t_bil b2,
			siac_t_periodo c2,
			siac_r_ordinativo_bil_elem b,
			siac_t_ordinativo d,
			siac_d_ordinativo_tipo e,
			siac_r_ordinativo_stato f,
			siac_d_ordinativo_stato g,
			siac_t_ordinativo_ts h
		where a.bil_id=b2.bil_id
		and c2.periodo_id=b2.periodo_id
		and a.elem_id=_uid_capitoloentrata
		and b.elem_id=a.elem_id
		and d.ord_id=b.ord_id
		and e.ord_tipo_id=d.ord_tipo_id
		and e.ord_tipo_code='I'
		and f.ord_id=d.ord_id
		and g.ord_stato_id=f.ord_stato_id
		and h.ord_id = d.ord_id
		and now() BETWEEN f.validita_inizio and COALESCE(f.validita_fine,now())
		and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
		and b.data_cancellazione is null
		and d.data_cancellazione is null
		and b2.data_cancellazione is null
		and c2.data_cancellazione is null
		and e.data_cancellazione is null
		and h.data_cancellazione is null
       )
       -- 12.07.2018 Sofia jira SIAC-6193 C,R
       select ordinativi.*
       from ordinativi, movimenti
       where ordinativi.ord_ts_id=movimenti.ord_ts_id
       and   ( case when coalesce(_filtro_crp,'')='C' then ordinativi.ord_anno=movimenti.movgest_anno
      			    when coalesce(_filtro_crp,'')='R' then movimenti.movgest_anno<ordinativi.ord_anno
                    else true end )
	   LIMIT _limit
	   OFFSET _offset

		loop
			uid:=rec.ord_id;
			capitolo_anno:=rec.anno;
			capitolo_numero:=rec.elem_code;
			capitolo_articolo:=rec.elem_code2;
			ueb_numero:=rec.elem_code3;
			ord_numero:=rec.ord_numero;
			ord_desc:=rec.ord_desc;
			ord_emissione_data:=rec.ord_emissione_data;
            
			v_ord_id:=rec.ord_id;
			ord_stato_desc:=rec.ord_stato_desc;
			v_ord_ts_id:=rec.ord_ts_id;
			ord_ts_code:=rec.ord_ts_code;

			select
				f.ord_ts_det_importo
			into
				importo
			from
				siac_t_ordinativo_ts e,
				siac_t_ordinativo_ts_det f,
				siac_d_ordinativo_ts_det_tipo g
			where e.ord_ts_id=v_ord_ts_id
			and f.ord_ts_id=e.ord_ts_id
			and g.ord_ts_det_tipo_id=f.ord_ts_det_tipo_id
			and g.ord_ts_det_tipo_code='A'
			and e.data_cancellazione is null
			and f.data_cancellazione is null
			and g.data_cancellazione is null;

			select
				y.soggetto_code,
				y.soggetto_desc
			into
				soggetto_code,
				soggetto_desc
			from
				siac_r_ordinativo_soggetto z,
				siac_t_soggetto y
			where z.soggetto_id=y.soggetto_id
			and now() BETWEEN z.validita_inizio
			and COALESCE(z.validita_fine,now())
			and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
			and z.data_cancellazione is null
			and y.data_cancellazione is null
			and z.ord_id=v_ord_id;

			select
				q.attoamm_id,
				q.attoamm_numero,
				q.attoamm_anno,
				t.attoamm_stato_desc,
				r.attoamm_tipo_code,
				r.attoamm_tipo_desc,
				--SIAC-8188
				q.attoamm_oggetto,
				staa.attoal_causale
			into
				v_attoamm_id,
				attoamm_numero,
				attoamm_anno,
				attoamm_stato_desc,
				attoamm_tipo_code,
				attoamm_tipo_desc,
				--SIAC-8188
				attoamm_oggetto,
				attoal_causale
			from
				siac_r_ordinativo_atto_amm p,
				siac_d_atto_amm_tipo r,
				siac_r_atto_amm_stato s,
				siac_d_atto_amm_stato t,
				siac_t_atto_amm q
			--SIAC-8188 se ci sono corrisponsenze le ritorno
			left join siac_t_atto_allegato staa on q.attoamm_id = staa.attoamm_id 
			where p.attoamm_id=q.attoamm_id
			and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
			and r.attoamm_tipo_id=q.attoamm_tipo_id
			and s.attoamm_id=q.attoamm_id
			and t.attoamm_stato_id=s.attoamm_stato_id
			and now() BETWEEN s.validita_inizio and COALESCE(s.validita_fine,now())
			and p.ord_id=v_ord_id
			and p.data_cancellazione is null
			and q.data_cancellazione is null
			and r.data_cancellazione is null
			and s.data_cancellazione is null
			and t.data_cancellazione is null;

			--sac
			select
				y.classif_code,
				y.classif_desc
			into
				attoamm_sac_code,
				attoamm_sac_desc
			from
				siac_r_atto_amm_class z,
				siac_t_class y,
				siac_d_class_tipo x
			where z.classif_id=y.classif_id
			and x.classif_tipo_id=y.classif_tipo_id
			and x.classif_tipo_code IN ('CDC', 'CDR')
			and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
			and z.attoamm_id=v_attoamm_id;

            --SIAC-5899
            SELECT
                siac_r_ordinativo_quietanza.ord_quietanza_data
            INTO
                ord_quietanza_data
            FROM
                siac_t_oil_ricevuta
                ,siac_T_Ordinativo
                ,siac_d_oil_ricevuta_tipo
                ,siac_r_ordinativo_quietanza
            WHERE
                    siac_t_oil_ricevuta.oil_ricevuta_tipo_id =  siac_d_oil_ricevuta_tipo.oil_ricevuta_tipo_id
                AND siac_t_oil_ricevuta.oil_ord_id  = siac_T_Ordinativo.ord_id
                AND siac_T_Ordinativo.ord_id = siac_r_ordinativo_quietanza.ord_id
                AND siac_d_oil_ricevuta_tipo.oil_ricevuta_tipo_code = 'Q'
                AND siac_T_Ordinativo.ord_Id = v_ord_id
                AND siac_t_oil_ricevuta.data_cancellazione is null
                AND siac_T_Ordinativo.data_cancellazione is null
                AND siac_d_oil_ricevuta_tipo.data_cancellazione is null
                AND siac_r_ordinativo_quietanza.data_cancellazione is null;

            -- 12.07.2018 Sofia jira siac-6193
            conto_tesoreria:=null;
            select conto.contotes_code into conto_tesoreria
            from siac_d_contotesoreria conto
            where conto.contotes_id=rec.contotes_id;

            distinta_code:=null;
            distinta_desc:=null;
            select d.dist_code, d.dist_desc
                   into distinta_code, distinta_desc
            from siac_d_distinta d
            where d.dist_id=rec.dist_id;

            -- 12.07.2018 Sofia jira siac-6193
            ord_split:=null;
           	select tipo.relaz_tipo_code into ord_split
            from siac_r_ordinativo rOrd, siac_d_relaz_tipo tipo,
                 siac_r_ordinativo_stato rstato,siac_d_ordinativo_stato stato
  		    where rord.ord_id_a=rec.ord_id
            and   tipo.relaz_tipo_id=rord.relaz_tipo_id
            and   tipo.relaz_tipo_code='SPR'
			and   rstato.ord_id=rOrd.ord_id_da
            and   stato.ord_stato_id=rstato.ord_stato_id
			and   stato.ord_stato_code!='A'
            and   rord.data_cancellazione is null
	        and   now() between rord.validita_inizio and coalesce(rord.validita_fine, now())
   		    and   rstato.data_cancellazione is null
			and   now() between rstato.validita_inizio and coalesce(rstato.validita_fine, now())
            limit 1;
			if ord_split is not null then
                 ord_split:='S';
            else ord_split:='N';
            end if;

            -- 12.07.2018 Sofia jira siac-6193
            ord_ritenute:=null;
            select tipo.relaz_tipo_code into ord_ritenute
            from siac_r_ordinativo rOrd, siac_d_relaz_tipo tipo,
                 siac_r_ordinativo_stato rstato,siac_d_ordinativo_stato stato
  		    where rord.ord_id_a=rec.ord_id
            and   tipo.relaz_tipo_id=rord.relaz_tipo_id
            and   tipo.relaz_tipo_code='RIT_ORD'
			and   rstato.ord_id=rOrd.ord_id_da
            and   stato.ord_stato_id=rstato.ord_stato_id
			and   stato.ord_stato_code!='A'
            and   rord.data_cancellazione is null
	        and   now() between rord.validita_inizio and coalesce(rord.validita_fine, now())
   		    and   rstato.data_cancellazione is null
			and   now() between rstato.validita_inizio and coalesce(rstato.validita_fine, now())
            limit 1;
            if ord_ritenute is not null then
                 ord_ritenute:='S';
            else ord_ritenute:='N';
            end if;

			return next;
		end loop;
	return;

END;
$function$
;


-- ALLEGATO ATTO DA PROVVEDIMENTO [FORSE MAI USATA]
DROP FUNCTION  IF EXISTS siac.fnc_siac_cons_entita_allegato_from_provvedimento(_uid_provvedimento integer, _limit integer, _page integer);


CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_allegato_from_provvedimento(_uid_provvedimento integer, _limit integer, _page integer)
 RETURNS TABLE(uid integer, attoal_causale character varying, attoal_data_scadenza timestamp without time zone, attoal_stato_desc character varying, attoal_versione_invio_firma integer, attoamm_numero integer, attoamm_anno character varying, attoamm_tipo_code character varying, attoamm_tipo_desc character varying, attoamm_stato_desc character varying, attoamm_sac_code character varying, attoamm_sac_desc character varying,
 	--SIAC-8188
 	attoamm_oggetto character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
	_offset INTEGER := (_page) * _limit;
	stringaTest character varying := 'stringa di test';
BEGIN

/*	RETURN QUERY
	SELECT 123, stringaTest, TO_TIMESTAMP('2015 12 31', 'YYYY MM DD')::timestamp without time zone,stringaTest,
		1,234, stringaTest, stringaTest, stringaTest, stringaTest, stringaTest, stringaTest
	LIMIT _limit
	OFFSET _offset;*/

    RETURN QUERY
    with attoamm as (
    select 
    e.attoal_id uid,
    e.attoal_causale,
    e.attoal_data_scadenza,
    m.attoal_stato_desc,
    e.attoal_versione_invio_firma,
    a.attoamm_numero,
    a.attoamm_anno,
    b.attoamm_tipo_code,
    b.attoamm_tipo_desc,
    d.attoamm_stato_desc,
    a.attoamm_id,
    --SIAC-8188 ritorno l'oggetto
    a.attoamm_oggetto 
    from siac_t_atto_amm a, siac_d_atto_amm_tipo b,siac_r_atto_amm_stato c,
    siac_d_atto_amm_stato d, siac_t_atto_allegato e,siac_r_atto_allegato_stato l,
    siac_d_atto_allegato_stato m
    where 
    b.attoamm_tipo_id=a.attoamm_tipo_id
    and c.attoamm_id=a.attoamm_id
    and d.attoamm_stato_id=c.attoamm_stato_id
    and now() BETWEEN c.validita_inizio and COALESCE(c.validita_fine,now())
    and a.attoamm_id=_uid_provvedimento
    and e.attoamm_id=a.attoamm_id
    and l.attoal_id=e.attoal_id
    and m.attoal_stato_id=l.attoal_stato_id
    and now() BETWEEN l.validita_inizio and COALESCE(l.validita_fine,now())
    and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
    and d.data_cancellazione is null
    and e.data_cancellazione is null
    and l.data_cancellazione is null
    and m.data_cancellazione is null)
    ,
    sac as 
    (select f.attoamm_id,g.classif_code,g.classif_desc
     from siac_r_atto_amm_class f, siac_t_class g,
    siac_d_class_tipo h 
    where 
    f.classif_id=g.classif_id
    and h.classif_tipo_id=g.classif_tipo_id
    and h.classif_tipo_code in ('CDR','CDC')
    and now() BETWEEN f.validita_inizio and COALESCE(f.validita_fine,now())
    and f.data_cancellazione is null
    and g.data_cancellazione is null
    and h.data_cancellazione is null
    )
    select 
    attoamm.uid,
    attoamm.attoal_causale,
    attoamm.attoal_data_scadenza,
    attoamm.attoal_stato_desc,
    attoamm.attoal_versione_invio_firma,
    attoamm.attoamm_numero,
    attoamm.attoamm_anno,
    attoamm.attoamm_tipo_code,
    attoamm.attoamm_tipo_desc,
    attoamm.attoamm_stato_desc,
    sac.classif_code attoamm_sac_code,
    sac.classif_desc attoamm_sac_desc 
    from attoamm left outer join sac
    on attoamm.attoamm_id=sac.attoamm_id
    order by    attoamm.attoamm_anno,  attoamm.attoamm_numero   
   	LIMIT _limit
	OFFSET _offset
    ;
        
    
END;
$function$
;

-- IMPEGNO DA CAPITOLO SPESA
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_capitolospesa(_uid_capitolospesa integer, _anno character varying, _filtro_crp character varying, _limit integer, _page integer);


CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_impegno_from_capitolospesa(_uid_capitolospesa integer, _anno character varying, _filtro_crp character varying, _limit integer, _page integer)
 RETURNS TABLE(uid integer, impegno_anno integer, impegno_numero numeric, impegno_desc character varying, impegno_stato character varying, impegno_importo numeric, soggetto_code character varying, soggetto_desc character varying, attoamm_numero integer, attoamm_anno character varying, 
 	--SIAC-8188
 	attoamm_oggetto character varying, attoal_causale character varying,
 	attoamm_tipo_code character varying, attoamm_tipo_desc character varying, attoamm_stato_desc character varying, attoamm_sac_code character varying, attoamm_sac_desc character varying, pdc_code character varying, pdc_desc character varying, impegno_anno_capitolo integer, impegno_nro_capitolo integer, impegno_nro_articolo integer, impegno_flag_prenotazione character varying, impegno_cup character varying, impegno_cig character varying, impegno_tipo_debito character varying, impegno_motivo_assenza_cig character varying, impegno_componente character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
		with imp_sogg_attoamm as (
			with imp_sogg as (
				select distinct
					soggall.uid,
					soggall.movgest_anno,
					soggall.movgest_numero,
					soggall.movgest_desc,
					soggall.movgest_stato_desc,
					soggall.movgest_ts_id,
					soggall.movgest_ts_det_importo,
					case when soggall.zzz_soggetto_code is null then soggall.zzzz_soggetto_code else soggall.zzz_soggetto_code end soggetto_code,
					case when soggall.zzz_soggetto_desc is null then soggall.zzzz_soggetto_desc else soggall.zzz_soggetto_desc end soggetto_desc,
					soggall.pdc_code,
					soggall.pdc_desc,
                    -- 29.06.2018 Sofia jira siac-6193
					soggall.impegno_nro_capitolo,
					soggall.impegno_nro_articolo,
					soggall.impegno_anno_capitolo,
                    soggall.impegno_flag_prenotazione,
                    soggall.impegno_cig,
  					soggall.impegno_cup,
                    soggall.impegno_motivo_assenza_cig,
            		soggall.impegno_tipo_debito,
                    -- 11.05.2020 SIAC-7349 SR210
                    soggall.impegno_componente

				from (
					with za as (
						select
							zzz.uid,
							zzz.movgest_anno,
							zzz.movgest_numero,
							zzz.movgest_desc,
							zzz.movgest_stato_desc,
							zzz.movgest_ts_id,
							zzz.movgest_ts_det_importo,
							zzz.zzz_soggetto_code,
							zzz.zzz_soggetto_desc,
							zzz.pdc_code,
							zzz.pdc_desc,
                            -- 29.06.2018 Sofia jira siac-6193
                            zzz.impegno_nro_capitolo,
                            zzz.impegno_nro_articolo,
                            zzz.impegno_anno_capitolo,
                            zzz.impegno_flag_prenotazione,
                            zzz.impegno_cig,
  							zzz.impegno_cup,
                            zzz.impegno_motivo_assenza_cig,
            				zzz.impegno_tipo_debito,
                            --11/05/2020 SIAC-7349 SR210
                            zzz.impegno_componente
						from (
							with impegno as (


								select
									a.movgest_id as uid,
									a.movgest_anno,
									a.movgest_numero,
									a.movgest_desc,
									e.movgest_stato_desc,
									c.movgest_ts_id,
									f.movgest_ts_det_importo,
									q.classif_code pdc_code,
									q.classif_desc pdc_desc,
                                    -- 29.06.2018 Sofia jira siac-6193
                                    bilelem.elem_code::integer impegno_nro_capitolo,
                                    bilelem.elem_code2::integer impegno_nro_articolo,
                                    t.anno::integer impegno_anno_capitolo,
                                    c.siope_assenza_motivazione_id,
                                    c.siope_tipo_debito_id,
                                    --11.05.2020 Mr SIAC-7349 SR210 tiro fuori l'id per la join con la tabella del tipo componente
                                    b.elem_det_comp_tipo_id
                                    --
								from
									siac_t_bil_elem bilelem,
									siac_t_movgest a,
									siac_r_movgest_bil_elem b,
									siac_r_movgest_ts_stato d,
									siac_d_movgest_stato e,
									siac_t_movgest_ts_det f,
									siac_d_movgest_ts_tipo j,
									siac_d_movgest_ts_det_tipo k,
									siac_r_movgest_class p,
									siac_t_class q,
									siac_d_class_tipo r,
									siac_t_bil s,
									siac_t_periodo t,
									siac_t_movgest_ts c
								where a.movgest_id=b.movgest_id
								and c.movgest_id=a.movgest_id
								and d.movgest_ts_id=c.movgest_ts_id
								and e.movgest_stato_id=d.movgest_stato_id
								and p.movgest_ts_id = c.movgest_ts_id
								and q.classif_id = p.classif_id
								and r.classif_tipo_id = q.classif_tipo_id
								and j.movgest_ts_tipo_id=c.movgest_ts_tipo_id
								and k.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
								and s.bil_id = a.bil_id
								and t.periodo_id = s.periodo_id
								and now() between d.validita_inizio and coalesce(d.validita_fine, now())
								and now() between b.validita_inizio and coalesce(b.validita_fine, now())
								and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
								and f.movgest_ts_id=c.movgest_ts_id
								and a.data_cancellazione is null
								and b.data_cancellazione is null
								and c.data_cancellazione is null
								and d.data_cancellazione is null
								and e.data_cancellazione is null
								and f.data_cancellazione is null
								and p.data_cancellazione is null
								and q.data_cancellazione is null
								and r.data_cancellazione is null
								and s.data_cancellazione is null
								and t.data_cancellazione is null
								and bilelem.data_cancellazione is null
								and e.movgest_stato_code<>'A'
								and j.movgest_ts_tipo_code='T'
								and k.movgest_ts_det_tipo_code='A'
								and r.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
								and b.elem_id=bilelem.elem_id
								and bilelem.elem_id=_uid_capitolospesa
                                and t.anno = _anno
							),
							siope_assenza_motivazione as
                            (
								select
									d.siope_assenza_motivazione_id,
									d.siope_assenza_motivazione_code,
									d.siope_assenza_motivazione_desc
								from siac_d_siope_assenza_motivazione d
								where d.data_cancellazione is null
							),

							siope_tipo_debito as
                            (
								select
									d.siope_tipo_debito_id,
									d.siope_tipo_debito_code,
									d.siope_tipo_debito_desc
								from siac_d_siope_tipo_debito d
								where d.data_cancellazione is null
							),
							soggetto as
                            (
								select
									g.soggetto_code,
									g.soggetto_desc,
									h.movgest_ts_id
								from
									siac_t_soggetto g,
									siac_r_movgest_ts_sog h
								where h.soggetto_id=g.soggetto_id
								and now() between h.validita_inizio and coalesce(h.validita_fine, now())
								and g.data_cancellazione is null
								and h.data_cancellazione is null
							),
							impegno_flag_prenotazione as
                            (
								select
									r.movgest_ts_id,
									r.boolean
								from
									siac_r_movgest_ts_attr r,
									siac_t_attr t
								where r.attr_id = t.attr_id
								and now() between r.validita_inizio and coalesce(r.validita_fine, now())
								and r.data_cancellazione is null
								and t.data_cancellazione is null
								and t.attr_code = 'flagPrenotazione'
							),
							impegno_cig as
                            (
								select
									r.movgest_ts_id,
									r.testo
								from
									siac_r_movgest_ts_attr r,
									siac_t_attr t
								where r.attr_id = t.attr_id
								and now() between r.validita_inizio and coalesce(r.validita_fine, now())
								and r.data_cancellazione is null
								and t.data_cancellazione is null
								and t.attr_code = 'cig'
							),
							impegno_cup as
                            (
								select
									r.movgest_ts_id,
									r.testo
								from
									siac_r_movgest_ts_attr r,
									siac_t_attr t
								where r.attr_id = t.attr_id
								and now() between r.validita_inizio and coalesce(r.validita_fine, now())
								and r.data_cancellazione is null
								and t.data_cancellazione is null
								and t.attr_code = 'cup'
							),
                            --11.05.2020 SIAC-7349 MR SR210 lista di tutte le componenti
                            componente_desc AS
                            (
                                select * from 
                                siac_d_bil_elem_det_comp_tipo tipo
                                --where tipo.data_cancellazione is NULL --da discuterne. in questo caso prende solo le componenti non cancellate
                            )
							select
								impegno.uid,
								impegno.movgest_anno,
								impegno.movgest_numero,
								impegno.movgest_desc,
								impegno.movgest_stato_desc,
								impegno.movgest_ts_id,
								impegno.movgest_ts_det_importo,
								soggetto.soggetto_code zzz_soggetto_code,
								soggetto.soggetto_desc zzz_soggetto_desc,
								impegno.pdc_code,
								impegno.pdc_desc,
                                -- 29.06.2018 Sofia jira siac-6193
                                impegno.impegno_nro_capitolo,
                                impegno.impegno_nro_articolo,
                                impegno.impegno_anno_capitolo,
                                siope_assenza_motivazione.siope_assenza_motivazione_desc impegno_motivo_assenza_cig,
                                siope_tipo_debito.siope_tipo_debito_desc impegno_tipo_debito,
                                coalesce(impegno_flag_prenotazione.boolean,'N') impegno_flag_prenotazione,
                                impegno_cig.testo  impegno_cig,
                                impegno_cup.testo  impegno_cup,
                                --11.05.2020 MR SIAC-7349 SR210
                                componente_desc.elem_det_comp_tipo_desc impegno_componente
							from impegno
                              left outer join soggetto on impegno.movgest_ts_id=soggetto.movgest_ts_id
                              left outer join impegno_flag_prenotazione on impegno.movgest_ts_id=impegno_flag_prenotazione.movgest_ts_id
                              left outer join impegno_cig on impegno.movgest_ts_id=impegno_cig.movgest_ts_id
                              left outer join impegno_cup on impegno.movgest_ts_id=impegno_cup.movgest_ts_id
                              left outer join siope_assenza_motivazione on impegno.siope_assenza_motivazione_id=siope_assenza_motivazione.siope_assenza_motivazione_id
                              left outer join siope_tipo_debito on impegno.siope_tipo_debito_id=siope_tipo_debito.siope_tipo_debito_id
                              --11.05.2020 MR SIAC-7349 SR210
                              left outer join componente_desc on impegno.elem_det_comp_tipo_id=componente_desc.elem_det_comp_tipo_id
						) as zzz
					),
					zb as (
						select
							zzzz.uid,
							zzzz.movgest_anno,
							zzzz.movgest_numero,
							zzzz.movgest_desc,
							zzzz.movgest_stato_desc,
							zzzz.movgest_ts_id,
							zzzz.movgest_ts_det_importo,
							zzzz.soggetto_code zzzz_soggetto_code,
							zzzz.soggetto_desc zzzz_soggetto_desc
						from (
							with impegno as (
								select
									a.movgest_id as uid,
									a.movgest_anno,
									a.movgest_numero,
									a.movgest_desc,
									e.movgest_stato_desc,
									c.movgest_ts_id,
									f.movgest_ts_det_importo
								from
									siac_t_movgest a,
									siac_r_movgest_bil_elem b,
									siac_t_movgest_ts c,
									siac_r_movgest_ts_stato d,
									siac_d_movgest_stato e,
									siac_t_movgest_ts_det f,
									siac_d_movgest_ts_tipo j,
									siac_d_movgest_ts_det_tipo k,
									siac_t_bil l,
									siac_t_periodo m
								where a.movgest_id=b.movgest_id
								and c.movgest_id=a.movgest_id
								and d.movgest_ts_id=c.movgest_ts_id
								and e.movgest_stato_id=d.movgest_stato_id
								and j.movgest_ts_tipo_id=c.movgest_ts_tipo_id
								and k.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
								and l.bil_id = a.bil_id
								and m.periodo_id = l.periodo_id
								and now() between d.validita_inizio and coalesce(d.validita_fine, now())
								and now() between b.validita_inizio and coalesce(b.validita_fine, now())
								and f.movgest_ts_id=c.movgest_ts_id
								and a.data_cancellazione is null
								and b.data_cancellazione is null
								and c.data_cancellazione is null
								and d.data_cancellazione is null
								and e.data_cancellazione is null
								and f.data_cancellazione is null
								and e.movgest_stato_code<>'A'
								and j.movgest_ts_tipo_code='T'
								and k.movgest_ts_det_tipo_code='A'
								and b.elem_id=_uid_capitolospesa
								and m.anno = _anno
							),
							soggetto as (
                                select
									l.soggetto_classe_code soggetto_code,
									l.soggetto_classe_desc soggetto_desc,
									h.movgest_ts_id
								from
									siac_r_movgest_ts_sogclasse h,
									siac_d_soggetto_classe l
								where
								    h.soggetto_classe_id=l.soggetto_classe_id
                                and now() between h.validita_inizio and coalesce(h.validita_fine, now())
								and h.data_cancellazione is null
							)
							select
								impegno.uid,
								impegno.movgest_anno,
								impegno.movgest_numero,
								impegno.movgest_desc,
								impegno.movgest_stato_desc,
								impegno.movgest_ts_id,
								impegno.movgest_ts_det_importo,
								soggetto.soggetto_code,
								soggetto.soggetto_desc
							from impegno
							left outer join soggetto on impegno.movgest_ts_id=soggetto.movgest_ts_id
						) as zzzz
					)
					select
						za.*,
						zb.zzzz_soggetto_code,
						zb.zzzz_soggetto_desc
					from za
					left join zb on za.movgest_ts_id=zb.movgest_ts_id
				) soggall
			),

			attoamm as (
				select
					movgest_ts_id,
					n.attoamm_id,
					n.attoamm_numero,
					n.attoamm_anno,
                    --29.06.2018 Sofia jira siac-6193
                    n.attoamm_oggetto,
					q.attoamm_stato_desc,
					o.attoamm_tipo_code,
					o.attoamm_tipo_desc,
					--SIAC-8188
					staa.attoal_causale
				from
					siac_r_movgest_ts_atto_amm m,
					siac_d_atto_amm_tipo o,
					siac_r_atto_amm_stato p,
					siac_d_atto_amm_stato q,
					siac_t_atto_amm n
				--SIAC-8188 se ci sono corrisponsenze le ritorno
				left join siac_t_atto_allegato staa on n.attoamm_id = staa.attoamm_id 
				where n.attoamm_id=m.attoamm_id
				and o.attoamm_tipo_id=n.attoamm_tipo_id
				and p.attoamm_id=n.attoamm_id
				and p.attoamm_stato_id=q.attoamm_stato_id
				and now() BETWEEN m.validita_inizio and coalesce (m.validita_fine,now())
				and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
				and q.attoamm_stato_code<>'ANNULLATO'
				and m.data_cancellazione is null
				and n.data_cancellazione is null
				and o.data_cancellazione is null
				and p.data_cancellazione is null
				and q.data_cancellazione is null
			)
			select
				imp_sogg.uid,
				imp_sogg.movgest_anno,
				imp_sogg.movgest_numero,
				imp_sogg.movgest_desc,
				imp_sogg.movgest_stato_desc,
				imp_sogg.movgest_ts_det_importo,
				imp_sogg.soggetto_code,
				imp_sogg.soggetto_desc,
				attoamm.attoamm_id,
				attoamm.attoamm_numero,
				attoamm.attoamm_anno,
                -- 29.06.2018 Sofia jira siac-6193
                attoamm.attoamm_oggetto,
				attoamm.attoamm_tipo_code,
				attoamm.attoamm_tipo_desc,
				attoamm.attoamm_stato_desc,
				--SIAC-8188
				attoamm.attoal_causale,
				imp_sogg.pdc_code,
				imp_sogg.pdc_desc,
                -- 29.06.2018 Sofia jira siac-6193
                imp_sogg.impegno_nro_capitolo,
           		imp_sogg.impegno_nro_articolo,
           		imp_sogg.impegno_anno_capitolo,
                imp_sogg.impegno_flag_prenotazione,
                imp_sogg.impegno_cig,
                imp_sogg.impegno_cup,
                imp_sogg.impegno_motivo_assenza_cig,
                imp_sogg.impegno_tipo_debito,
                --11.05.2020 MR SIAC-7349 SR210
                imp_sogg.impegno_componente

			from imp_sogg

			 left outer join attoamm ON imp_sogg.movgest_ts_id=attoamm.movgest_ts_id
            where (case when coalesce(_filtro_crp,'X')='R' then imp_sogg.movgest_anno<_anno::integer
                     	when coalesce(_filtro_crp,'X')='C' then imp_sogg.movgest_anno=_anno::integer
                        when coalesce(_filtro_crp,'X')='P' then imp_sogg.movgest_anno>_anno::integer
		                else true end ) -- 29.06.2018 Sofia jira siac-6193
		),
		sac_attoamm as (
			select
				y.classif_code,
				y.classif_desc,
				z.attoamm_id
			from
				siac_r_atto_amm_class z,
				siac_t_class y,
				siac_d_class_tipo x
			where z.classif_id=y.classif_id
			and x.classif_tipo_id=y.classif_tipo_id
			and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
			and x.classif_tipo_code  IN ('CDC', 'CDR')
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
		)
		select
			imp_sogg_attoamm.uid,
			imp_sogg_attoamm.movgest_anno as impegno_anno,
			imp_sogg_attoamm.movgest_numero as impegno_numero,
			imp_sogg_attoamm.movgest_desc as impegno_desc,
			imp_sogg_attoamm.movgest_stato_desc as impegno_stato,
			imp_sogg_attoamm.movgest_ts_det_importo as impegno_importo,
			imp_sogg_attoamm.soggetto_code,
			imp_sogg_attoamm.soggetto_desc,
			imp_sogg_attoamm.attoamm_numero,
			imp_sogg_attoamm.attoamm_anno,
            -- 29.06.2018 Sofia jira siac-6193
            imp_sogg_attoamm.attoamm_oggetto attoamm_oggetto, --SIAC-8188 si cambia il nome del campo da attoamm_desc a attoamm_oggetto per mantenere una struttura univoca
            imp_sogg_attoamm.attoal_causale attoal_causale, --SIAC-8188 si cambia il nome del campo da attoamm_desc a attoamm_oggetto per mantenere una struttura univoca
			imp_sogg_attoamm.attoamm_tipo_code,
			imp_sogg_attoamm.attoamm_tipo_desc,
			imp_sogg_attoamm.attoamm_stato_desc,
			sac_attoamm.classif_code as attoamm_sac_code,
			sac_attoamm.classif_desc as attoamm_sac_desc,
			imp_sogg_attoamm.pdc_code,
			imp_sogg_attoamm.pdc_desc,
            -- 29.06.2018 Sofia jira siac-6193
            imp_sogg_attoamm.impegno_anno_capitolo,
            imp_sogg_attoamm.impegno_nro_capitolo,
            imp_sogg_attoamm.impegno_nro_articolo,
            imp_sogg_attoamm.impegno_flag_prenotazione::varchar,
			imp_sogg_attoamm.impegno_cup,
            imp_sogg_attoamm.impegno_cig,
            imp_sogg_attoamm.impegno_tipo_debito,
            imp_sogg_attoamm.impegno_motivo_assenza_cig,
            --11.05.2020 SIAC-7349 MR SR210
            imp_sogg_attoamm.impegno_componente
		from imp_sogg_attoamm
		left outer join sac_attoamm on imp_sogg_attoamm.attoamm_id=sac_attoamm.attoamm_id
		order by
			imp_sogg_attoamm.movgest_anno,
			imp_sogg_attoamm.movgest_numero


		LIMIT _limit
		OFFSET _offset;
END;
$function$
;


--VARIAZIONE DA CAPITOLO ENTRATA
DROP FUNCTION  IF EXISTS siac.fnc_siac_cons_entita_variazione_from_capitoloentrata(_uid_capitoloentrata integer, _limit integer, _page integer);


CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_variazione_from_capitoloentrata(_uid_capitoloentrata integer, _limit integer, _page integer)
 RETURNS TABLE(uid integer, variazione_num integer, variazione_desc character varying, variazione_applicazione character varying, variazione_tipo_code character varying, variazione_tipo_desc character varying, variazione_stato_tipo_code character varying, variazione_stato_tipo_desc character varying, attoamm_numero integer, attoamm_anno character varying, attoamm_tipo_code character varying, attoamm_tipo_desc character varying, attoamm_stato_desc character varying, attoamm_sac_code character varying, attoamm_sac_desc character varying
 	--SIAC-8188	
 	, attoamm_oggetto character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
_offset INTEGER := (_page) * _limit;
rec record;    
v_attoamm_id integer;    
BEGIN

for rec in   
--variazione codifica
select 
e.variazione_id,
e.variazione_num,e.variazione_desc,
	CASE
			WHEN g.elem_tipo_code LIKE '%G' THEN 'GESTIONE'::VARCHAR
			WHEN g.elem_tipo_code LIKE '%P' THEN 'PREVISIONE'::VARCHAR
			ELSE '?'::VARCHAR
		END AS variazione_applicazione,
f.variazione_tipo_code,f.variazione_tipo_desc,
i.variazione_stato_tipo_code,
i.variazione_stato_tipo_desc,  
d.attoamm_id
 from siac_T_bil_elem a,siac_t_bil b2,siac_t_periodo c2,
 siac_t_bil_elem_var a2,siac_r_variazione_stato d,
 siac_t_variazione e,siac_d_variazione_tipo f, siac_d_bil_elem_tipo g,
 siac_r_variazione_stato h,siac_d_variazione_stato i
  where 
 a.bil_id=b2.bil_id
 and c2.periodo_id=b2.periodo_id and
 a.elem_id=_uid_capitoloentrata--25330
and a.elem_id=a2.elem_id
and d.variazione_stato_id=a2.variazione_stato_id
and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
and e.variazione_id=d.variazione_id
and f.variazione_tipo_id=e.variazione_tipo_id
and g.elem_tipo_id=a.elem_tipo_id
and h.variazione_id=e.variazione_id
and i.variazione_stato_tipo_id=h.variazione_stato_tipo_id
and now() BETWEEN h.validita_inizio and COALESCE(h.validita_fine,now())
and a.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
and a2.data_cancellazione is null
and b2.data_cancellazione is null
and c2.data_cancellazione is null
union
select 
e.variazione_id,
e.variazione_num,e.variazione_desc,
	CASE
			WHEN g.elem_tipo_code LIKE '%G' THEN 'GESTIONE'::VARCHAR
			WHEN g.elem_tipo_code LIKE '%P' THEN 'PREVISIONE'::VARCHAR
			ELSE '?'::VARCHAR
		END AS variazione_applicazione,
f.variazione_tipo_code,f.variazione_tipo_desc,
i.variazione_stato_tipo_code,
i.variazione_stato_tipo_desc,  
d.attoamm_id
 from siac_T_bil_elem a,siac_t_bil b2,siac_t_periodo c2,
 siac_t_bil_elem_det_var a2,siac_r_variazione_stato d,
 siac_t_variazione e,siac_d_variazione_tipo f, siac_d_bil_elem_tipo g,
 siac_r_variazione_stato h,siac_d_variazione_stato i
  where 
 a.bil_id=b2.bil_id
 and c2.periodo_id=b2.periodo_id and
 a.elem_id=_uid_capitoloentrata--25330
and a.elem_id=a2.elem_id
and d.variazione_stato_id=a2.variazione_stato_id
and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
and e.variazione_id=d.variazione_id
and f.variazione_tipo_id=e.variazione_tipo_id
and g.elem_tipo_id=a.elem_tipo_id
and h.variazione_id=e.variazione_id
and i.variazione_stato_tipo_id=h.variazione_stato_tipo_id
and now() BETWEEN h.validita_inizio and COALESCE(h.validita_fine,now())
and a.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
and a2.data_cancellazione is null
and b2.data_cancellazione is null
and c2.data_cancellazione is null
order by 2
LIMIT _limit
OFFSET _offset
loop
 

uid:=rec.variazione_id;
variazione_num:=rec.variazione_num;
variazione_desc:=rec.variazione_desc;
variazione_applicazione:=rec.variazione_applicazione;
variazione_tipo_code:=rec.variazione_tipo_code;
variazione_tipo_desc:=rec.variazione_tipo_desc;
variazione_stato_tipo_code:=rec.variazione_stato_tipo_code;
variazione_stato_tipo_desc:=rec.variazione_stato_tipo_desc;
v_attoamm_id:=rec.attoamm_id;

select 
q.attoamm_numero,q.attoamm_anno,
--SIAC-8188
q.attoamm_oggetto,
t.attoamm_stato_desc,
r.attoamm_tipo_code,r.attoamm_tipo_desc
into 
attoamm_numero,attoamm_anno,
--SIAC-8188
attoamm_oggetto,
attoamm_stato_desc,
attoamm_tipo_code,attoamm_tipo_desc
 from 
siac_t_atto_amm q,siac_d_atto_amm_tipo r,
siac_r_atto_amm_stato s, siac_d_atto_amm_stato t
where q.attoamm_id=v_attoamm_id
and r.attoamm_tipo_id=q.attoamm_tipo_id
and s.attoamm_id=q.attoamm_id
and t.attoamm_stato_id=s.attoamm_stato_id
and now() BETWEEN s.validita_inizio and COALESCE(s.validita_fine,now())
and q.data_cancellazione is null
and r.data_cancellazione is null
and s.data_cancellazione is null
and t.data_cancellazione is null;

--sac
select 
y.classif_code,y.classif_desc
into 
attoamm_sac_code,
  attoamm_sac_desc
from  siac_r_atto_amm_class z,
siac_t_class y, siac_d_class_tipo x
where z.classif_id=y.classif_id
and x.classif_tipo_id=y.classif_tipo_id
and x.classif_tipo_code  IN ('CDC', 'CDR')
and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
and z.data_cancellazione is NULL
and x.data_cancellazione is NULL
and y.data_cancellazione is NULL
and z.attoamm_id=v_attoamm_id
;


return next;

end loop;

return;    

END;
$function$
;


--VARIAZIONE DA CAPITOLO SPESA
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_variazione_from_capitolospesa(_uid_capitolospesa integer, _limit integer, _page integer);


CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_variazione_from_capitolospesa(_uid_capitolospesa integer, _limit integer, _page integer)
 RETURNS TABLE(uid integer, variazione_num integer, variazione_desc character varying, variazione_applicazione character varying, variazione_tipo_code character varying, variazione_tipo_desc character varying, variazione_stato_tipo_code character varying, variazione_stato_tipo_desc character varying, attoamm_numero integer, attoamm_anno character varying, attoamm_tipo_code character varying, attoamm_tipo_desc character varying, attoamm_stato_desc character varying, attoamm_sac_code character varying, attoamm_sac_desc character varying,
 	--SIAC-8188
 	attoamm_oggetto character varying, attoal_causale character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
_offset INTEGER := (_page) * _limit;
rec record;    
v_attoamm_id integer;    
BEGIN

for rec in   
--variazione codifica
select 
e.variazione_id,
e.variazione_num,e.variazione_desc,
	CASE
			WHEN g.elem_tipo_code LIKE '%G' THEN 'GESTIONE'::VARCHAR
			WHEN g.elem_tipo_code LIKE '%P' THEN 'PREVISIONE'::VARCHAR
			ELSE '?'::VARCHAR
		END AS variazione_applicazione,
f.variazione_tipo_code,f.variazione_tipo_desc,
i.variazione_stato_tipo_code,
i.variazione_stato_tipo_desc,  
d.attoamm_id
 from siac_T_bil_elem a,siac_t_bil b2,siac_t_periodo c2,
 siac_t_bil_elem_var a2,siac_r_variazione_stato d,
 siac_t_variazione e,siac_d_variazione_tipo f, siac_d_bil_elem_tipo g,
 siac_r_variazione_stato h,siac_d_variazione_stato i
  where 
 a.bil_id=b2.bil_id
 and c2.periodo_id=b2.periodo_id and
 a.elem_id=_uid_capitolospesa--25330
and a.elem_id=a2.elem_id
and d.variazione_stato_id=a2.variazione_stato_id
and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
and e.variazione_id=d.variazione_id
and f.variazione_tipo_id=e.variazione_tipo_id
and g.elem_tipo_id=a.elem_tipo_id
and h.variazione_id=e.variazione_id
and i.variazione_stato_tipo_id=h.variazione_stato_tipo_id
and now() BETWEEN h.validita_inizio and COALESCE(h.validita_fine,now())
and a.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
and a2.data_cancellazione is null
and b2.data_cancellazione is null
and c2.data_cancellazione is null
union
select 
e.variazione_id,
e.variazione_num,e.variazione_desc,
	CASE
			WHEN g.elem_tipo_code LIKE '%G' THEN 'GESTIONE'::VARCHAR
			WHEN g.elem_tipo_code LIKE '%P' THEN 'PREVISIONE'::VARCHAR
			ELSE '?'::VARCHAR
		END AS variazione_applicazione,
f.variazione_tipo_code,f.variazione_tipo_desc,
i.variazione_stato_tipo_code,
i.variazione_stato_tipo_desc,  
d.attoamm_id
 from siac_T_bil_elem a,siac_t_bil b2,siac_t_periodo c2,
 siac_t_bil_elem_det_var a2,siac_r_variazione_stato d,
 siac_t_variazione e,siac_d_variazione_tipo f, siac_d_bil_elem_tipo g,
 siac_r_variazione_stato h,siac_d_variazione_stato i
  where 
 a.bil_id=b2.bil_id
 and c2.periodo_id=b2.periodo_id and
 a.elem_id=_uid_capitolospesa
and a.elem_id=a2.elem_id
and d.variazione_stato_id=a2.variazione_stato_id
and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
and e.variazione_id=d.variazione_id
and f.variazione_tipo_id=e.variazione_tipo_id
and g.elem_tipo_id=a.elem_tipo_id
and h.variazione_id=e.variazione_id
and i.variazione_stato_tipo_id=h.variazione_stato_tipo_id
and now() BETWEEN h.validita_inizio and COALESCE(h.validita_fine,now())
and a.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
and a2.data_cancellazione is null
and b2.data_cancellazione is null
and c2.data_cancellazione is null
order by 2
LIMIT _limit
OFFSET _offset
loop
 

uid:=rec.variazione_id;
variazione_num:=rec.variazione_num;
variazione_desc:=rec.variazione_desc;
variazione_applicazione:=rec.variazione_applicazione;
variazione_tipo_code:=rec.variazione_tipo_code;
variazione_tipo_desc:=rec.variazione_tipo_desc;
variazione_stato_tipo_code:=rec.variazione_stato_tipo_code;
variazione_stato_tipo_desc:=rec.variazione_stato_tipo_desc;
v_attoamm_id:=rec.attoamm_id;

select 
q.attoamm_numero,
q.attoamm_anno,
--SIAC-8188
q.attoamm_oggetto, 
t.attoamm_stato_desc,
r.attoamm_tipo_code,
r.attoamm_tipo_desc,
--SIAC-8188
staa.attoal_causale
into 
attoamm_numero,
attoamm_anno,
--SIAC-8188
attoamm_oggetto
attoamm_stato_desc,
attoamm_tipo_code,
attoamm_tipo_desc,
--SIAC-8188
attoal_causale
 from 
siac_d_atto_amm_tipo r, siac_r_atto_amm_stato s, 
siac_d_atto_amm_stato t, siac_t_atto_amm q
--SIAC-8188 se ci sono corrisponsenze le ritorno
left join siac_t_atto_allegato staa on q.attoamm_id = staa.attoamm_id 
where q.attoamm_id=v_attoamm_id
and r.attoamm_tipo_id=q.attoamm_tipo_id
and s.attoamm_id=q.attoamm_id
and t.attoamm_stato_id=s.attoamm_stato_id
and now() BETWEEN s.validita_inizio and COALESCE(s.validita_fine,now())
and q.data_cancellazione is null
and r.data_cancellazione is null
and s.data_cancellazione is null
and t.data_cancellazione is null;

--sac
select 
y.classif_code,y.classif_desc
into 
attoamm_sac_code,
  attoamm_sac_desc
from  siac_r_atto_amm_class z,
siac_t_class y, siac_d_class_tipo x
where z.classif_id=y.classif_id
and x.classif_tipo_id=y.classif_tipo_id
and x.classif_tipo_code  IN ('CDC', 'CDR')
and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
and z.data_cancellazione is NULL
and x.data_cancellazione is NULL
and y.data_cancellazione is NULL
and z.attoamm_id=v_attoamm_id
;


return next;

end loop;

return;    

END;
$function$
;
-- FINE SIAC-8188


-- SIAC-8197 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR159_struttura_dca_conto_economico" (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  cod_missione varchar,
  cod_programma varchar
)
RETURNS TABLE (
  nome_ente varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  segno_importo varchar,
  importo numeric,
  pdce_conto_code varchar,
  pdce_conto_desc varchar,
  livello integer,
  pnota_id integer,
  ambito_id integer
) AS
$body$
DECLARE

nome_ente varchar;
bilancio_id integer;
RTN_MESSAGGIO text;
sql_query VARCHAR;

BEGIN
  RTN_MESSAGGIO:='select 1';
  
  SELECT a.ente_denominazione
  INTO  nome_ente
  FROM  siac_t_ente_proprietario a
  WHERE a.ente_proprietario_id = p_ente_proprietario_id;
  
  --siac 5536: 10/11/2017.
  --	Nella query dinamica si ottiene un errore se il nome ente 
  -- 	contiene un apice. Sostituisco l'apice con uno doppio.  
  nome_ente:=REPLACE(nome_ente,'''','''''');  
  
  select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
  where a.ente_proprietario_id = p_ente_proprietario_id 
  and b.periodo_id = a.periodo_id
  and b.anno = p_anno_bilancio;

/* 18/10/2017: resa dinamica la query perche' sono stati aggiunti i parametri 
	cod_missione e cod_programma */

/*SIAC-5525 Sostituito l'ordine delle tabelle nella query
Prima era:
  from cap
  left join dati_prime_note on cap.elem_id = dati_prime_note.elem_id 
e
  from clas left join capall on 
  clas.programma_id = capall.programma_id and    
  clas.macroag_id=capall.macroag_id 
Aggiunta inoltre la condizione

  where (dati_prime_note.elem_id is null or exists (select 1 
  from siac_t_bil_elem a
  where a.ente_proprietario_id = '||p_ente_proprietario_id||'
  and   a.elem_id = dati_prime_note.elem_id
  and   a.bil_id ='||bilancio_id||'
  and   a.data_cancellazione is null))   
  
per evitare di prendere in considerazione dati con capitoli appartenenti ad un anno di bilancio
diverso da quello inserito
  */ 
    
/* 30/12/2020 SIAC-7894.
	Inserita la gestione dell'ambito in quanto si deve filtrare per ambito FIN.

*************************************************************

   25/05/2021 SIAC-8197.
    Quando vi sono importi negativi nella colonna Dare devono essere spostati 
    come positivi nella colonna Avere e viceversa.
    Questo controllo non vale per i conti:
    - 1.5.1.01.01.001
    - 1.6.1.01.01.001
    - 2.5.1.01.01.001.         

	Questo controllo e' stato implementato trasformando il segno da Dare ad Avere
    e viceversa quando l'importo e' negativo ed il conto non e' compreso tra
    i 3 indicati.
    Il controllo c'è in 2 punti nella query costruita dinamicamente perche'
    c'è una UNION.
    
*/  


sql_query:='select --zz.*  
 zz.nome_ente ,
  zz.missione_code ,
  zz.missione_desc ,
  zz.programma_code ,
  zz.programma_desc ,
 -- zz.movep_det_segno ,
 case when zz.importo < 0 and 
   zz.pdce_conto_code not in (''1.5.1.01.01.001'', ''1.6.1.01.01.001'', ''2.5.1.01.01.001'')
   then	case when zz.movep_det_segno =''Dare'' then ''Avere'' else ''Dare'' end
  else zz.movep_det_segno end ,
  case when zz.importo < 0 and 
   zz.pdce_conto_code not in (''1.5.1.01.01.001'', ''1.6.1.01.01.001'', ''2.5.1.01.01.001'')
   then zz.importo*-1 else  zz.importo end, 
  zz.pdce_conto_code ,
  zz.pdce_conto_desc ,
  zz.livello ,
  zz.pnota_id ,
  zz.ambito_id 
from (
  with clas as (
  with missione as 
  (select 
  e.classif_tipo_desc missione_tipo_desc,
  a.classif_id missione_id,
  a.classif_code missione_code,
  a.classif_desc missione_desc,
  a.validita_inizio missione_validita_inizio,
  a.validita_fine missione_validita_fine,
  a.ente_proprietario_id
  from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
  where 
  a.ente_proprietario_id='||p_ente_proprietario_id||'
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = ''00001''
  and to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))
  and b.classif_id_padre is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.classif_tipo_id=a.classif_tipo_id)
  , programma as (
  select 
  e.classif_tipo_desc programma_tipo_desc,
  b.classif_id_padre missione_id,
  a.classif_id programma_id,
  a.classif_code programma_code,
  a.classif_desc programma_desc,
  a.validita_inizio programma_validita_inizio,
  a.validita_fine programma_validita_fine,
  a.ente_proprietario_id
  from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
  where 
  a.ente_proprietario_id='||p_ente_proprietario_id||'
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = ''00001''
  and to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))
  and b.classif_id_padre is not  null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.classif_tipo_id=a.classif_tipo_id)
  ,
  titusc as (
  select 
  e.classif_tipo_desc titusc_tipo_desc,
  a.classif_id titusc_id,
  a.classif_code titusc_code,
  a.classif_desc titusc_desc,
  a.validita_inizio titusc_validita_inizio,
  a.validita_fine titusc_validita_fine,
  a.ente_proprietario_id
  from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
  where a.ente_proprietario_id='||p_ente_proprietario_id||'
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = ''00002''
  and to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))
  and b.classif_id_padre is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.classif_tipo_id=a.classif_tipo_id)
  , macroag as (
  select 
  e.classif_tipo_desc macroag_tipo_desc,
  b.classif_id_padre titusc_id,
  a.classif_id macroag_id,
  a.classif_code macroag_code,
  a.classif_desc macroag_desc,
  a.validita_inizio macroag_validita_inizio,
  a.validita_fine macroag_validita_fine,
  a.ente_proprietario_id
  from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
  where a.ente_proprietario_id='||p_ente_proprietario_id||'
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = ''00002''
  and to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))
  and b.classif_id_padre is not null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.classif_tipo_id=a.classif_tipo_id
  )
  select  missione.missione_tipo_desc,
  missione.missione_id,
  missione.missione_code,
  missione.missione_desc,
  missione.missione_validita_inizio,
  missione.missione_validita_fine,
  programma.programma_tipo_desc,
  programma.programma_id,
  programma.programma_code,
  programma.programma_desc,
  programma.programma_validita_inizio,
  programma.programma_validita_fine,
  titusc.titusc_tipo_desc,
  titusc.titusc_id,
  titusc.titusc_code,
  titusc.titusc_desc,
  titusc.titusc_validita_inizio,
  titusc.titusc_validita_fine,
  macroag.macroag_tipo_desc,
  macroag.macroag_id,
  macroag.macroag_code,
  macroag.macroag_desc,
  macroag.macroag_validita_inizio,
  macroag.macroag_validita_fine,
  missione.ente_proprietario_id
  from missione , programma,titusc, macroag, siac_r_class progmacro
  where programma.missione_id=missione.missione_id
  and titusc.titusc_id=macroag.titusc_id
  AND programma.programma_id = progmacro.classif_a_id
  AND titusc.titusc_id = progmacro.classif_b_id
  and titusc.ente_proprietario_id=missione.ente_proprietario_id
   ),
  capall as (
  with
  cap as (
  select a.elem_id,
  a.elem_code ,
  a.elem_desc ,
  a.elem_code2 ,
  a.elem_desc2 ,
  a.elem_id_padre ,
  a.elem_code3,
  d.classif_id programma_id,d2.classif_id macroag_id
  from siac_t_bil_elem a,siac_d_bil_elem_tipo b, siac_r_bil_elem_class c,
  siac_r_bil_elem_class c2,
  siac_t_class d,siac_t_class d2,
  siac_d_class_tipo e,siac_d_class_tipo e2, siac_r_bil_elem_categoria f, 
  siac_d_bil_elem_categoria g,siac_r_bil_elem_stato h,siac_d_bil_elem_stato i
  where a.ente_proprietario_id='||p_ente_proprietario_id||'
  and a.bil_id='||bilancio_id||'
  and b.elem_tipo_id=a.elem_tipo_id
  and b.elem_tipo_code = ''CAP-UG''
  and c.elem_id=a.elem_id
  and c2.elem_id=a.elem_id
  and d.classif_id=c.classif_id
  and d2.classif_id=c2.classif_id
  and e.classif_tipo_id=d.classif_tipo_id
  and e2.classif_tipo_id=d2.classif_tipo_id
  and e.classif_tipo_code=''PROGRAMMA''
  and e2.classif_tipo_code=''MACROAGGREGATO''
  and g.elem_cat_id=f.elem_cat_id
  and f.elem_id=a.elem_id
  and g.elem_cat_code in	(''STD'',''FPV'',''FSC'',''FPVC'')
  and h.elem_id=a.elem_id
  and i.elem_stato_id=h.elem_stato_id
  and i.elem_stato_code = ''VA''
  and h.validita_fine is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and c2.data_cancellazione is null
  and d.data_cancellazione is null
  and d2.data_cancellazione is null
  and e.data_cancellazione is null
  and e2.data_cancellazione is null
  and f.data_cancellazione is null
  and g.data_cancellazione is null
  and h.data_cancellazione is null
  and i.data_cancellazione is null
  ), 
  dati_prime_note as(
  WITH prime_note AS (
  SELECT d.pdce_fam_code, d.pdce_fam_desc,
  e.movep_det_segno,
  e.movep_det_importo importo,
  CASE 
   WHEN b.livello = 7 THEN
      (SELECT o.pdce_conto_code
      FROM   siac_t_pdce_conto o
      WHERE  o.pdce_conto_id = b.pdce_conto_id_padre
      AND    o.data_cancellazione IS NULL)
   ELSE
       b.pdce_conto_code
  END pdce_conto_code,   
  CASE 
   WHEN b.livello = 7 THEN
      (SELECT o.pdce_conto_desc
      FROM   siac_t_pdce_conto o
      WHERE  o.pdce_conto_id = b.pdce_conto_id_padre
      AND    o.data_cancellazione IS NULL)
   ELSE
       b.pdce_conto_desc
  END pdce_conto_desc,
  n.campo_pk_id,n.campo_pk_id_2,
  q.collegamento_tipo_code,
  b.livello,
  -- 03/06/2019 SIAC-6875
  -- aggiunto l''id della nota per essere certo di estrarre tutte le prime note anche
  -- a parita'' degli altri valori estratti.
  g.pnota_id, b.ambito_id
  FROM  siac_t_pdce_conto b
  INNER JOIN siac_t_pdce_fam_tree c ON b.pdce_fam_tree_id = c.pdce_fam_tree_id
  INNER JOIN siac_d_pdce_fam d ON c.pdce_fam_id = d.pdce_fam_id    
  INNER JOIN siac_t_mov_ep_det e ON e.pdce_conto_id = b.pdce_conto_id
  INNER JOIN siac_t_mov_ep f ON e.movep_id = f.movep_id
  INNER JOIN siac_t_prima_nota g ON f.regep_id = g.pnota_id
  INNER JOIN siac_t_bil h ON g.bil_id = h.bil_id
  INNER JOIN siac_t_periodo i ON h.periodo_id = i.periodo_id
  INNER JOIN siac_r_prima_nota_stato l ON g.pnota_id = l.pnota_id
  INNER JOIN siac_d_prima_nota_stato m ON l.pnota_stato_id = m.pnota_stato_id 
  INNER JOIN siac_r_evento_reg_movfin n ON n.regmovfin_id = f.regmovfin_id
  INNER JOIN siac_d_evento p ON p.evento_id = n.evento_id
  INNER JOIN siac_d_collegamento_tipo q ON q.collegamento_tipo_id = p.collegamento_tipo_id
  WHERE b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   m.pnota_stato_code = ''D''
  AND   i.anno = '''||p_anno_bilancio||'''
  AND   d.pdce_fam_code in (''CE'',''RE'')
  AND   b.data_cancellazione IS NULL
  AND   c.data_cancellazione IS NULL
  AND   d.data_cancellazione IS NULL
  AND   e.data_cancellazione IS NULL
  AND   f.data_cancellazione IS NULL
  AND   g.data_cancellazione IS NULL
  AND   h.data_cancellazione IS NULL
  AND   i.data_cancellazione IS NULL
  AND   l.data_cancellazione IS NULL
  AND   m.data_cancellazione IS NULL
  AND   n.data_cancellazione IS NULL
  AND   p.data_cancellazione IS NULL
  AND   q.data_cancellazione IS NULL
  ), collegamento_MMGS_MMGE_a AS (
  SELECT DISTINCT rmbe.elem_id, tm.mod_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_t_movgest_ts_det_mod tmtdm, siac_t_movgest_ts tmt,
        siac_r_movgest_bil_elem rmbe
  WHERE rms.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   tmtdm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = tmtdm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND   dms.mod_stato_code = ''V''
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   tmtdm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL
  ),
  collegamento_MMGS_MMGE_b AS (
  SELECT DISTINCT rmbe.elem_id, tm.mod_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_r_movgest_ts_sog_mod rmtsm, siac_t_movgest_ts tmt,
        siac_r_movgest_bil_elem rmbe
  WHERE rms.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   rmtsm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = rmtsm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND   dms.mod_stato_code = ''V''
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   rmtsm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL
  ),
  collegamento_I_A AS (
  SELECT DISTINCT a.elem_id, a.movgest_id
  FROM   siac_r_movgest_bil_elem a
  WHERE  a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND    a.data_cancellazione IS NULL
  ),
  collegamento_SI_SA AS (
  SELECT DISTINCT b.elem_id, a.movgest_ts_id
  FROM  siac_t_movgest_ts a, siac_r_movgest_bil_elem b
  WHERE a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   a.movgest_id = b.movgest_id
  AND   a.data_cancellazione IS NULL
  AND   b.data_cancellazione IS NULL
  ),
  collegamento_SS_SE AS (
  SELECT DISTINCT c.elem_id, a.subdoc_id
  FROM   siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
  WHERE  b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND    a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  /* 19/09/2017: SIAC-5216.
  	Si deve testare la data di fine validita'' perche'' (da mail di Irene):
     "a causa della doppia gestione che purtroppo non e'' stata implementata sui documenti!!!! 
     E'' stato trovato questo escamotage per cui la relazione 2016 viene chiusa con una
data dell''anno nuovo (in questo caso 2017) e viene creata quella nuova del 2017
(quella che tra l''altro vediamo da sistema anche sul 2016).
Per cui l''unica soluzione e'' recuperare nella tabella r_subdoc_movgest_ts  la
relazione 2016 che troverai non piu'' valida."
  */
    --and a.data_cancellazione IS NULL
  AND    (a.data_cancellazione IS NULL OR (a.data_cancellazione IS NOT NULL
  				AND a.validita_fine IS NOT NULL AND
                a.validita_fine > to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'')))
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  ),
  collegamento_OP_OI AS (
  SELECT DISTINCT a.elem_id, a.ord_id
  FROM   siac_r_ordinativo_bil_elem a
  WHERE  a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND    a.data_cancellazione IS NULL
  ),
  collegamento_L AS (
  SELECT DISTINCT c.elem_id, a.liq_id
  FROM   siac_r_liquidazione_movgest a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
  WHERE  b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND    a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  AND    a.data_cancellazione IS NULL
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  ),
  collegamento_RR AS (
  SELECT DISTINCT d.elem_id, a.gst_id
  FROM  siac_t_giustificativo a, siac_r_richiesta_econ_movgest b, siac_t_movgest_ts c, siac_r_movgest_bil_elem d
  WHERE a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   a.ricecon_id = b.ricecon_id
  AND   b.movgest_ts_id = c.movgest_ts_id
  AND   c.movgest_id = d.movgest_id
  AND   a.data_cancellazione  IS NULL
  AND   b.data_cancellazione  IS NULL
  AND   c.data_cancellazione  IS NULL
  AND   d.data_cancellazione  IS NULL
  ),
  collegamento_RE AS (
  SELECT DISTINCT c.elem_id, a.ricecon_id
  FROM  siac_r_richiesta_econ_movgest a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
  WHERE b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   a.movgest_ts_id = b.movgest_ts_id
  AND   b.movgest_id = c.movgest_id
  AND   a.data_cancellazione  IS NULL
  AND   b.data_cancellazione  IS NULL
  AND   c.data_cancellazione  IS NULL
  ),
  /* 20/09/2017: SIAC-5216.
  	Aggiunto collegamento per estrarre il capitolo nel caso il documento
  	sia una nota di Credito.
    In questo caso occorre prendere l''impegno del documento collegato e non quello della nota di 
    credito che non esiste */
  collegamento_SS_SE_NCD AS (
  select c.elem_id, a.subdoc_id
  from  siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
  where a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  AND b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND    (a.data_cancellazione IS NULL OR (a.data_cancellazione IS NOT NULL
  				AND a.validita_fine IS NOT NULL AND
                a.validita_fine > to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'')))
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  )
  SELECT 
  prime_note.movep_det_segno,
  prime_note.importo,
  prime_note.pdce_conto_code,
  prime_note.pdce_conto_desc,
  prime_note.livello,
  -- 03/06/2019 SIAC-6875
  -- aggiunto l''id della nota per essere certo di estrarre tutte le prime note anche
  -- a parita'' degli altri valori estratti.
  prime_note.pnota_id,prime_note.ambito_id,
  -- COALESCE(collegamento_MMGS_MMGE_a.elem_id, collegamento_MMGS_MMGE_b.elem_id),
  -- collegamento_SS_SE.elem_id,
  -- collegamento_I_A.elem_id,
  -- collegamento_SI_SA.elem_id
  -- collegamento_OP_OI.elem_id
  -- collegamento_L.elem_id
  -- collegamento_RR.elem_id
  -- collegamento_RE.elem_id
  --COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.elem_id, collegamento_MMGS_MMGE_b.elem_id),collegamento_SS_SE.elem_id),collegamento_I_A.elem_id),collegamento_SI_SA.elem_id),collegamento_OP_OI.elem_id),collegamento_L.elem_id),collegamento_RR.elem_id),collegamento_RE.elem_id) elem_id
  COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.elem_id, collegamento_MMGS_MMGE_b.elem_id),collegamento_SS_SE.elem_id),collegamento_I_A.elem_id),collegamento_SI_SA.elem_id),collegamento_OP_OI.elem_id),collegamento_L.elem_id),collegamento_RR.elem_id),collegamento_RE.elem_id), collegamento_SS_SE_NCD.elem_id) elem_id
  FROM   prime_note
  LEFT   JOIN collegamento_MMGS_MMGE_a ON collegamento_MMGS_MMGE_a.mod_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN (''MMGS'',''MMGE'') 
  LEFT   JOIN collegamento_MMGS_MMGE_b ON collegamento_MMGS_MMGE_b.mod_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN (''MMGS'',''MMGE'')
  LEFT   JOIN collegamento_I_A ON collegamento_I_A.movgest_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN (''I'',''A'')
  LEFT   JOIN collegamento_SI_SA ON collegamento_SI_SA.movgest_ts_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN (''SI'',''SA'')                                     
  LEFT   JOIN collegamento_SS_SE ON collegamento_SS_SE.subdoc_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN (''SS'',''SE'')
  LEFT   JOIN collegamento_OP_OI ON collegamento_OP_OI.ord_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN (''OP'',''OI'')
  LEFT   JOIN collegamento_L ON collegamento_L.liq_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code = ''L''
  LEFT   JOIN collegamento_RR ON collegamento_RR.gst_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code = ''RR''
  LEFT   JOIN collegamento_RE ON collegamento_RE.ricecon_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code = ''RE''
  --20/09/2017: collegamento per note di credito. Si usa campo_pk_id_2
  LEFT	 JOIN collegamento_SS_SE_NCD ON collegamento_SS_SE_NCD.subdoc_id = prime_note.campo_pk_id_2
  										AND prime_note.collegamento_tipo_code IN (''SS'',''SE'')                      
  )                      
  select -- distinct
  cap.elem_id bil_ele_id,
  cap.elem_code bil_ele_code,
  cap.elem_desc bil_ele_desc,
  cap.elem_code2 bil_ele_code2,
  cap.elem_desc2 bil_ele_desc2,
  cap.elem_id_padre bil_ele_id_padre,
  cap.elem_code3 bil_ele_code3,
  cap.programma_id,cap.macroag_id,
  dati_prime_note.*
  from dati_prime_note
  left join cap on cap.elem_id = dati_prime_note.elem_id
  where (dati_prime_note.elem_id is null or exists (select 1 
  from siac_t_bil_elem a
  where a.ente_proprietario_id = '||p_ente_proprietario_id||'
  and   a.elem_id = dati_prime_note.elem_id
  and   a.bil_id ='||bilancio_id||'
  and   a.data_cancellazione is null)) 
  )
  select 
      '''||nome_ente||'''::varchar nome_ente,
      clas.missione_code::varchar,
      clas.missione_desc::varchar,
      clas.programma_code::varchar,
      clas.programma_desc::varchar,
      capall.movep_det_segno::varchar,
      capall.importo::numeric,
      capall.pdce_conto_code::varchar,
      capall.pdce_conto_desc::varchar,
      capall.livello::integer,
      	-- 03/06/2019 SIAC-6875
  		-- aggiunto l''id della nota per essere certo di estrarre tutte le prime note anche
  		-- a parita'' degli altri valori estratti.
  	  capall.pnota_id, capall.ambito_id
  from capall 
  left join clas on 
  clas.programma_id = capall.programma_id and    
  clas.macroag_id = capall.macroag_id
  where capall.importo is not null ';
/*  16/10/2017: SIAC-5287.
	Aggiunto filtro su missione/programma */      
  if cod_missione <> 'T' THEN
  	sql_query:=sql_query||' AND clas.missione_code ='''||cod_missione||'''';
  end if;
  if cod_programma <> 'T' THEN
  	sql_query:=sql_query||' AND clas.programma_code ='''||cod_programma||'''';
  end if;
  sql_query:=sql_query||' 
  union all
    select 
      '''||nome_ente||'''::varchar nome_ente,
      clas.missione_code::varchar,
      clas.missione_desc::varchar,
      clas.programma_code::varchar,
      clas.programma_desc::varchar,
      ''Avere'',
      0.00::numeric(15,2) ,
      capall.pdce_conto_code::varchar,
      capall.pdce_conto_desc::varchar,
      capall.livello::integer,
      	-- 03/06/2019 SIAC-6875
  		-- aggiunto l''id della nota per essere certo di estrarre tutte le prime note anche
  		-- a parita'' degli altri valori estratti.
  	  capall.pnota_id, capall.ambito_id       
  from clas left join capall on 
  	clas.programma_id = capall.programma_id and    
 	 clas.macroag_id=capall.macroag_id
  where capall.importo is not null ';
/*  16/10/2017: SIAC-5287.
	Aggiunto filtro su missione/programma */      
  if cod_missione <> 'T' THEN
  	sql_query:=sql_query||' AND clas.missione_code ='''||cod_missione||'''';
  end if;
  if cod_programma <> 'T' THEN
  	sql_query:=sql_query||' AND clas.programma_code ='''||cod_programma||'''';
  end if;
  sql_query:=sql_query||' 
  union all
      select 
      '''||nome_ente||'''::varchar nome_ente,
      clas.missione_code::varchar,
      clas.missione_desc::varchar,
      clas.programma_code::varchar,
      clas.programma_desc::varchar,
      ''Dare'',
      0.00::numeric(15,2) ,
      capall.pdce_conto_code::varchar,
      capall.pdce_conto_desc::varchar,
      capall.livello::integer,
      	-- 03/06/2019 SIAC-6875
  		-- aggiunto l''id della nota per essere certo di estrarre tutte le prime note anche
  		-- a parita'' degli altri valori estratti.
  	  capall.pnota_id, capall.ambito_id       
  from clas left join capall on 
  clas.programma_id = capall.programma_id and    
  clas.macroag_id=capall.macroag_id
  where capall.importo is not null ';
/*  16/10/2017: SIAC-5287.
	Aggiunto filtro su missione/programma */      
  if cod_missione <> 'T' THEN
  	sql_query:=sql_query||' AND clas.missione_code ='''||cod_missione||'''';
  end if;
  if cod_programma <> 'T' THEN
  	sql_query:=sql_query||' AND clas.programma_code ='''||cod_programma||'''';
  end if;
  sql_query:=sql_query||' ) as zz ,
    siac_d_ambito ambito
where zz.ambito_id =ambito.ambito_id
    and ambito.ambito_code=''AMBITO_FIN''  ';
/*  16/10/2017: SIAC-5287.
    	Aggiunta gestione delle prime note libere.
*/  
sql_query:=sql_query||' 
UNION
  select-- xx.* 
   xx.nome_ente ,
  xx.missione_code ,
  xx.missione_desc ,
  xx.programma_code ,
  xx.programma_desc ,
  case when xx.importo < 0 and 
   xx.pdce_conto_code not in (''1.5.1.01.01.001'', ''1.6.1.01.01.001'', ''2.5.1.01.01.001'')
   then	case when xx.segno_importo =''Dare'' then ''Avere'' else ''Dare'' end
  else xx.segno_importo end ,
   case when xx.importo < 0 and 
   xx.pdce_conto_code not in (''1.5.1.01.01.001'', ''1.6.1.01.01.001'', ''2.5.1.01.01.001'')   
   then xx.importo*-1 else xx.importo end ,   
  xx.pdce_conto_code ,
  xx.pdce_conto_desc ,
  xx.livello ,
  xx.pnota_id ,
  xx.ambito_id 
  from (
  WITH prime_note_lib AS (
  SELECT b.ente_proprietario_id, d_caus_ep.causale_ep_tipo_code, d.pdce_fam_code, d.pdce_fam_desc,
  e.movep_det_segno,
  e.movep_det_importo importo,
  CASE 
   WHEN b.livello = 7 THEN
      (SELECT o.pdce_conto_code
      FROM   siac_t_pdce_conto o
      WHERE  o.pdce_conto_id = b.pdce_conto_id_padre
      AND    o.data_cancellazione IS NULL)
   ELSE
       b.pdce_conto_code
  END pdce_conto_code,   
  CASE 
   WHEN b.livello = 7 THEN
      (SELECT o.pdce_conto_desc
      FROM   siac_t_pdce_conto o
      WHERE  o.pdce_conto_id = b.pdce_conto_id_padre
      AND    o.data_cancellazione IS NULL)
   ELSE
       b.pdce_conto_desc
  END pdce_conto_desc,
  b.livello,e.movep_det_id,
  -- 03/06/2019 SIAC-6875
  -- aggiunto l''id della nota per essere certo di estrarre tutte le prime note anche
  -- a parita'' degli altri valori estratti.
  g.pnota_id, b.ambito_id
  FROM  siac_t_pdce_conto b
  INNER JOIN siac_t_pdce_fam_tree c ON b.pdce_fam_tree_id = c.pdce_fam_tree_id
  INNER JOIN siac_d_pdce_fam d ON c.pdce_fam_id = d.pdce_fam_id    
  INNER JOIN siac_t_mov_ep_det e ON e.pdce_conto_id = b.pdce_conto_id
  --LEFT JOIN  siac_r_mov_ep_det_class r_mov_ep_det_class 
  --		ON (r_mov_ep_det_class.movep_det_id=e.movep_det_id
   --     	AND r_mov_ep_det_class.data_cancellazione IS NULL)
  INNER JOIN siac_t_mov_ep f ON e.movep_id = f.movep_id
  INNER JOIN siac_t_prima_nota g ON f.regep_id = g.pnota_id
  INNER JOIN siac_t_bil h ON g.bil_id = h.bil_id
  INNER JOIN siac_t_periodo i ON h.periodo_id = i.periodo_id
  INNER JOIN siac_r_prima_nota_stato l ON g.pnota_id = l.pnota_id
  INNER JOIN siac_d_prima_nota_stato m ON l.pnota_stato_id = m.pnota_stato_id 
  INNER JOIN siac_t_causale_ep t_caus_ep ON t_caus_ep.causale_ep_id=f.causale_ep_id
  INNER JOIN siac_d_causale_ep_tipo d_caus_ep ON d_caus_ep.causale_ep_tipo_id=t_caus_ep.causale_ep_tipo_id
  WHERE b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   m.pnota_stato_code = ''D''
  AND   i.anno = '''||p_anno_bilancio||'''
  AND   d.pdce_fam_code in (''CE'',''RE'')
  AND   d_caus_ep.causale_ep_tipo_code =''LIB''
  AND   b.data_cancellazione IS NULL
  AND   c.data_cancellazione IS NULL
  AND   d.data_cancellazione IS NULL
  AND   e.data_cancellazione IS NULL
  AND   f.data_cancellazione IS NULL
  AND   g.data_cancellazione IS NULL
  AND   h.data_cancellazione IS NULL
  AND   i.data_cancellazione IS NULL
  AND   l.data_cancellazione IS NULL
  AND   m.data_cancellazione IS NULL
  ),
ele_prime_note_progr as (
  	select r_mov_ep_det_class.*
    from siac_r_mov_ep_det_class r_mov_ep_det_class,
    	siac_t_class t_class ,  	
        siac_d_class_tipo d_class_tipo	
    where t_class.classif_id=r_mov_ep_det_class.classif_id
    	and d_class_tipo.classif_tipo_id = t_class.classif_tipo_id
        AND r_mov_ep_det_class.ente_proprietario_id='||p_ente_proprietario_id||'
        and d_class_tipo.classif_tipo_code=''PROGRAMMA''
        and r_mov_ep_det_class.data_cancellazione IS NULL
        and t_class.data_cancellazione IS NULL
        and d_class_tipo.data_cancellazione IS NULL),
ele_prime_note_miss as (
  	select r_mov_ep_det_class.*
    from siac_r_mov_ep_det_class r_mov_ep_det_class,
    	siac_t_class t_class ,  	
        siac_d_class_tipo d_class_tipo	
    where t_class.classif_id=r_mov_ep_det_class.classif_id
    	and d_class_tipo.classif_tipo_id = t_class.classif_tipo_id
        AND r_mov_ep_det_class.ente_proprietario_id='||p_ente_proprietario_id||'
        and d_class_tipo.classif_tipo_code=''MISSIONE''
        and r_mov_ep_det_class.data_cancellazione IS NULL
        and t_class.data_cancellazione IS NULL
        and d_class_tipo.data_cancellazione IS NULL),        
  missione as 
  (select 
  e.classif_tipo_desc missione_tipo_desc,
  a.classif_id missione_id,
  a.classif_code missione_code,
  a.classif_desc missione_desc,
  a.validita_inizio missione_validita_inizio,
  a.validita_fine missione_validita_fine,
  a.ente_proprietario_id
  from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
  where 
  a.ente_proprietario_id='||p_ente_proprietario_id||'
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = ''00001''
  and to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))
  and b.classif_id_padre is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.classif_tipo_id=a.classif_tipo_id)
  , programma as (
  select 
  e.classif_tipo_desc programma_tipo_desc,
  b.classif_id_padre missione_id,
  a.classif_id programma_id,
  a.classif_code programma_code,
  a.classif_desc programma_desc,
  a.validita_inizio programma_validita_inizio,
  a.validita_fine programma_validita_fine,
  a.ente_proprietario_id
  from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
  where 
  a.ente_proprietario_id='||p_ente_proprietario_id||'
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = ''00001''
  and to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))
  and b.classif_id_padre is not  null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.classif_tipo_id=a.classif_tipo_id)
select '''||nome_ente||'''::varchar nome_ente, 
	COALESCE(missione.missione_code,'''')::varchar missione_code, 
    COALESCE(missione.missione_desc,'''')::varchar missione_desc,
	COALESCE(programma.programma_code,'''')::varchar programma_code, 
	COALESCE(programma.programma_desc,'''')::varchar programma_desc,
	prime_note_lib.movep_det_segno::varchar segno_importo,
    prime_note_lib.importo::numeric ,
	prime_note_lib.pdce_conto_code::varchar,
    prime_note_lib.pdce_conto_desc::varchar,
    prime_note_lib.livello::integer,
    prime_note_lib.pnota_id,  prime_note_lib.ambito_id  
from prime_note_lib
	LEFT JOIN ele_prime_note_progr ON ele_prime_note_progr.movep_det_id=prime_note_lib.movep_det_id
    LEFT JOIN ele_prime_note_miss ON ele_prime_note_miss.movep_det_id=prime_note_lib.movep_det_id
	LEFT JOIN programma ON programma.programma_id = ele_prime_note_progr.classif_id
    LEFT JOIN missione ON missione.missione_id=ele_prime_note_miss.classif_id ';  
  if cod_missione <> 'T' THEN
  	sql_query:=sql_query||' 
    	WHERE (missione.missione_code ='''||cod_missione||''' OR ele_prime_note_miss.movep_det_id is null) ';
  end if;
  if cod_programma <> 'T' THEN
  	sql_query:=sql_query||' 
    	AND (programma.programma_code ='''||cod_programma||''' OR ele_prime_note_progr.movep_det_id is null) ';
  end if;
  sql_query:=sql_query||'
union select '''||nome_ente||'''::varchar nome_ente, 
	COALESCE(missione.missione_code,'''')::varchar missione_code, 
    COALESCE(missione.missione_desc,'''')::varchar missione_desc,
	COALESCE(programma.programma_code,'''')::varchar programma_code, 
	COALESCE(programma.programma_desc,'''')::varchar programma_desc,
	''Dare''::varchar segno_importo,
    0.00::numeric(15,2),
	prime_note_lib.pdce_conto_code::varchar,
    prime_note_lib.pdce_conto_desc::varchar,
    prime_note_lib.livello::integer,
      	-- 03/06/2019 SIAC-6875
  		-- aggiunto l''id della nota per essere certo di estrarre tutte le prime note anche
  		-- a parita'' degli altri valori estratti.
  	prime_note_lib.pnota_id, prime_note_lib.ambito_id       
from prime_note_lib
	LEFT JOIN ele_prime_note_progr ON ele_prime_note_progr.movep_det_id=prime_note_lib.movep_det_id
    LEFT JOIN ele_prime_note_miss ON ele_prime_note_miss.movep_det_id=prime_note_lib.movep_det_id
	LEFT JOIN programma ON programma.programma_id = ele_prime_note_progr.classif_id
    LEFT JOIN missione ON missione.missione_id=ele_prime_note_miss.classif_id ';  
if cod_missione <> 'T' THEN
  	sql_query:=sql_query||' 
    	WHERE (missione.missione_code ='''||cod_missione||''' OR ele_prime_note_miss.movep_det_id is null) ';
  end if;
  if cod_programma <> 'T' THEN
  	sql_query:=sql_query||' 
    	AND (programma.programma_code ='''||cod_programma||''' OR ele_prime_note_progr.movep_det_id is null) ';
  end if; 
sql_query:=sql_query||' 
union select '''||nome_ente||'''::varchar nome_ente, 
	COALESCE(missione.missione_code,'''')::varchar missione_code, 
    COALESCE(missione.missione_desc,'''')::varchar missione_desc,
	COALESCE(programma.programma_code,'''')::varchar programma_code, 
	COALESCE(programma.programma_desc,'''')::varchar programma_desc,
	''Avere''::varchar segno_importo,
    0.00::numeric(15,2),
	prime_note_lib.pdce_conto_code::varchar,
    prime_note_lib.pdce_conto_desc::varchar,
    prime_note_lib.livello::integer,
      	-- 03/06/2019 SIAC-6875
  		-- aggiunto l''id della nota per essere certo di estrarre tutte le prime note anche
  		-- a parita'' degli altri valori estratti.
  	prime_note_lib.pnota_id, prime_note_lib.ambito_id           
from prime_note_lib
	LEFT JOIN ele_prime_note_progr ON ele_prime_note_progr.movep_det_id=prime_note_lib.movep_det_id
    LEFT JOIN ele_prime_note_miss ON ele_prime_note_miss.movep_det_id=prime_note_lib.movep_det_id
	LEFT JOIN programma ON programma.programma_id = ele_prime_note_progr.classif_id
    LEFT JOIN missione ON missione.missione_id=ele_prime_note_miss.classif_id ';  
if cod_missione <> 'T' THEN
  	sql_query:=sql_query||' 
    	WHERE (missione.missione_code ='''||cod_missione||''' OR ele_prime_note_miss.movep_det_id is null) ';
  end if;
  if cod_programma <> 'T' THEN
  	sql_query:=sql_query||' 
    	AND (programma.programma_code ='''||cod_programma||''' OR ele_prime_note_progr.movep_det_id is null) ';
  end if; 
sql_query:=sql_query||'
    ) as xx,
 siac_d_ambito ambito
where xx.ambito_id =ambito.ambito_id
    and ambito.ambito_code=''AMBITO_FIN'' ';
    
raise notice 'sql_query= %',     sql_query;

  return query execute sql_query;
  

  exception
  when no_data_found THEN
  raise notice 'nessun dato trovato per struttura bilancio';
  return;
  when others  THEN
  RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
  return;
    
    
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-8197 - Maurizio - FINE

-- SIAC-8117 - Alessandro T - INIZIO
DROP FUNCTION IF EXISTS siac.fnc_siac_importo_residuo_spesa_collegata(p_det_mod_id integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_importo_residuo_spesa_collegata(p_det_mod_id integer)
 RETURNS numeric
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_importo_residuo numeric := null;
    v_importo_collegato numeric := null;
    v_importo_modifica numeric := null;
    v_result integer := null;
   	v_messaggiorisultato varchar;
BEGIN

	--ottengo la somma degli importi delle modifiche sulla R associate alla modifica se presenti
	select SUM(srmtdm.movgest_ts_det_mod_importo)
	from siac_r_movgest_ts_det_mod srmtdm 
	join siac_t_movgest_ts_det_mod stmtdm on srmtdm.movgest_ts_det_mod_spesa_id = stmtdm.movgest_ts_det_mod_id 
	join siac_r_modifica_stato srms on stmtdm.mod_stato_r_id = srms.mod_stato_r_id
	join siac_t_modifica stm on stm.mod_id = srms.mod_id
	where stm.mod_id = p_det_mod_id 
	and srmtdm.data_cancellazione is null 
	and srms.data_cancellazione is null into v_importo_collegato;

	--calcolo l'importo del dettaglio modifica
	select ABS(stmtdm.movgest_ts_det_importo) 
	from siac_t_movgest_ts_det_mod stmtdm
	join siac_r_modifica_stato srms on stmtdm.mod_stato_r_id = srms.mod_stato_r_id
	join siac_t_modifica stm on stm.mod_id = srms.mod_id
	where stm.mod_id = p_det_mod_id 
	and stmtdm.data_cancellazione is null 
	and srms.data_cancellazione is null into v_importo_modifica;

	-- se il residuo e' presente ed e' minore o uguale a 0 
	if v_importo_collegato <= 0 then
		v_importo_collegato := 0;
	-- se nullo assumo il valore nel vecchio importo del dettaglio modifica
  	elseif v_importo_collegato is null and v_importo_modifica is not null
  		then
  		v_importo_residuo := v_importo_modifica;
  	-- se ho l'importo della R ed e' maggiore di 0
  	elseif v_importo_collegato is not null and v_importo_collegato > 0 and v_importo_modifica is not null 
  		then
  		v_importo_residuo := v_importo_modifica - v_importo_collegato;
  	end if;
	
  	-- probabili dati sporchi, probabilmente manca l'importo della modifica
  	if v_importo_residuo is null then
  		v_messaggiorisultato = ' Nessun importo residuo trovato per la modifica con uid: ' || p_det_mod_id || ' .';
  		raise notice '[fnc_siac_importo_residuo_spesa_collegata] v_messaggiorisultato=%', v_messaggiorisultato;
  		v_importo_residuo := 0;
  	end if;
  
--  v_messaggiorisultato := ' importo residuo trovato per la modifica con uid: ' || p_det_mod_id || ', importo residuo: ' || v_importo_residuo;
--	raise notice '[fnc_siac_importo_max_coll_spesa_collegata] v_messaggiorisultato=%', v_messaggiorisultato;
  	
  	return v_importo_residuo;

END;
$function$
;


DROP FUNCTION IF EXISTS siac.fnc_siac_importo_max_coll_spesa_collegata(p_det_mod_id integer, p_importo_residuo numeric);

CREATE OR REPLACE FUNCTION siac.fnc_siac_importo_max_coll_spesa_collegata(p_det_mod_id integer, p_importo_residuo numeric)
 RETURNS numeric
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_importo_vincolo numeric:= null;
    v_importo_residuo numeric:= null;
    v_importo_massimo_collegabile numeric:=null;
   	v_messaggiorisultato varchar;
begin
	
	v_importo_residuo := p_importo_residuo;
	
	--calcolo l'importo del vincolo
	select ABS(srmt.movgest_ts_importo) 
	from siac_r_movgest_ts srmt 
	join siac_t_movgest_ts stmt on srmt.movgest_ts_b_id = stmt.movgest_ts_id 
	join siac_t_movgest_ts_det_mod stmtdm on stmt.movgest_ts_id = stmtdm.movgest_ts_id 
	join siac_r_modifica_stato srms on stmtdm.mod_stato_r_id = srms.mod_stato_r_id
	join siac_t_modifica stm on stm.mod_id = srms.mod_id
	where stm.mod_id = p_det_mod_id 
	and srmt.data_cancellazione is null 
	and srms.data_cancellazione is null into v_importo_vincolo;

--	v_messaggiorisultato := ' importo vincolo trovato per la modifica con uid: ' || p_det_mod_id || ' importo vincolo: ' || v_importo_vincolo;
--	raise notice '[fnc_siac_importo_max_coll_spesa_collegata] v_messaggiorisultato=%', v_messaggiorisultato;

	if v_importo_residuo <= v_importo_vincolo then
		v_importo_massimo_collegabile := v_importo_residuo;
  	else
  		v_importo_massimo_collegabile := v_importo_vincolo;
  	end if;
  
-- 	v_messaggiorisultato := ' importo massimo collegabile per la modifica con uid: ' || p_det_mod_id || ' importo massimo collegabile: ' || v_importo_massimo_collegabile;
--	raise notice '[fnc_siac_importo_max_coll_spesa_collegata] v_messaggiorisultato=%', v_messaggiorisultato;
	
  	if v_importo_massimo_collegabile is null then
  		v_messaggiorisultato := ' Nessun importo massimo collegabile trovato per la modifica con uid: ' || p_det_mod_id;
  		raise notice '[fnc_siac_importo_max_coll_spesa_collegata] v_messaggiorisultato=%', v_messaggiorisultato;
  		v_importo_massimo_collegabile := 0;
  	end if;
  	
  	return v_importo_massimo_collegabile;
  
END;
$function$
;


DROP FUNCTION IF EXISTS siac.fnc_siac_importi_modifica_spesa_collegata_set(p_mod_id integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_importi_modifica_spesa_collegata_set(p_mod_id integer)
 RETURNS SETOF numeric
 LANGUAGE plpgsql
AS $function$
DECLARE
   	v_importo_residuo numeric := null;
   	v_importo_max_collegabile numeric := null;
   	v_messaggiorisultato varchar := null;
BEGIN

	SELECT * FROM fnc_siac_importo_residuo_spesa_collegata(p_mod_id) INTO v_importo_residuo;

	SELECT * FROM fnc_siac_importo_max_coll_spesa_collegata(p_mod_id, v_importo_residuo) INTO v_importo_max_collegabile;
	
	v_messaggiorisultato := ' importo residuo : ' || v_importo_residuo || ', importo massimo collegabile: ' || v_importo_max_collegabile || '';
	RAISE NOTICE '[fnc_siac_importo_residuo_spesa_collegata] v_messaggiorisultato=%', v_messaggiorisultato;
	
	-- return numeric[] => [0] => v_importo_residuo, [1] => v_importo_max_collegabile
    RETURN query values (v_importo_residuo), (v_importo_max_collegabile);
    
END;
$function$
;

-- SIAC-8117 - Alessandro T - FINE
