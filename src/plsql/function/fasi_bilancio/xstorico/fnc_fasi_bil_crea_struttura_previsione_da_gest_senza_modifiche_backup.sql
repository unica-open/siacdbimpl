/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 07.07.2016 Sofia - salvato versione senza ultime modifiche backup
-- 06.04.2016 Sofia - predisposizione bilancio di previsione da gestione precedente
-- bilancio gestione annoBilancio-1
CREATE OR REPLACE FUNCTION fnc_fasi_bil_prev_apertura_struttura
(
  annobilancio integer,
  euElemTipo   varchar,
  bilElemPrevTipo varchar,
  bilElemGestTipo varchar,
  checkPrev       boolean, -- TRUE: il dato di previsione esistente viene aggiornato al dato di gestione, FALSE il dato di previsione esistente non viene aggiornato.
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out faseBilElabIdRet integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE


	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

    -- Attributo solo di previsione
    --  inserito con default N se la previsione non esiste
    --  non variato in caso di aggiornamento se la previsione esiste
    FLAG_PER_MEM CONSTANT varchar := 'FlagPerMemoria';

    -- tipo periodo annuale
    SY_PER_TIPO      CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO     CONSTANT varchar:='BIL_ORD';

    PREVISIONE_FASE     CONSTANT varchar:='P';

	elemBil record;

	-- CLASSIFICATORI
	CL_MACROAGGREGATO CONSTANT varchar :='MACROAGGREGATO';
	CL_PROGRAMMA CONSTANT varchar :='PROGRAMMA';
    CL_CATEGORIA CONSTANT varchar :='CATEGORIA';
    CL_CDC CONSTANT varchar :='CDC';
    CL_CDR CONSTANT varchar :='CDR';
	CL_RICORRENTE_SPESA CONSTANT varchar:='RICORRENTE_SPESA';
    CL_RICORRENTE_ENTRATA CONSTANT varchar:='RICORRENTE_ENTRATA';
	CL_TRANSAZIONE_UE_SPESA CONSTANT varchar:='TRANSAZIONE_UE_SPESA';
  	CL_TRANSAZIONE_UE_ENTRATA CONSTANT varchar:='TRANSAZIONE_UE_ENTRATA';


    CL_PDC_FIN_QUARTO     CONSTANT varchar :='PDC_IV';
    CL_PDC_FIN_QUINTO     CONSTANT varchar :='PDC_V';
	CL_COFOG 			  CONSTANT varchar :='GRUPPO_COFOG';
	CL_SIOPE_SPESA_TERZO  CONSTANT varchar:='SIOPE_SPESA_I';
    CL_SIOPE_ENTRATA_TERZO  CONSTANT varchar:='SIOPE_ENTRATA_I';

	TIPO_ELAB_P CONSTANT varchar :='P'; -- previsione
    TIPO_ELAB_G CONSTANT varchar :='G'; -- gestione

    TIPO_ELEM_EU CONSTANT varchar:='U';

	APE_PREV_DA_GEST CONSTANT varchar:='APE_PREV';

	macroAggrTipoId     integer:=null;
    programmaTipoId      integer:=null;
    categoriaTipoId      integer:=null;
    cdcTipoId            integer:=null;
    cdrTipoId            integer:=null;
    ricorrenteSpesaId    integer:=null;
    transazioneUeSpesaId INTEGER:=null;
    ricorrenteEntrataId    integer:=null;
    transazioneUeEntrataId INTEGER:=null;

    pdcFinIVId             integer:=null;
    pdcFinVId             integer:=null;
    cofogTipoId          integer:=null;
    siopeSpesaTipoId          integer:=null;
    siopeEntrataTipoId          integer:=null;

    bilElemGestTipoId integer:=null;
    bilElemPrevTipoId integer:=null;
    bilElemIdRet      integer:=null;
    bilancioId        integer:=null;
    periodoId         integer:=null;
    flagPerMemAttrId  integer:=null;


	bilancioPrecId        integer:=null;
    periodoPrecId         integer:=null;

	codResult         integer:=null;
	dataInizioVal     timestamp:=null;
    faseBilElabId     integer:=null;

    CATEGORIA_STD     constant varchar := 'STD';
    categoriaCapCode  varchar :=null;

BEGIN



    messaggioRisultato:='';
    codiceRisultato:=0;
    faseBilElabIdRet:=0;

    dataInizioVal:= clock_timestamp();

	strMessaggioFinale:='Apertura bilancio di previsione.Creazione struttura Previsione '||bilElemPrevTipo||' da Gestione precedente '||bilElemGestTipo||
    					'.Anno bilancio='||annoBilancio::varchar||'.';

    -- inserimento fase_bil_t_elaborazione
	strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
     fase_bil_elab_tipo_id,
     ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_PREV_DA_GEST||' IN CORSO : CREAZIONE STRUTTURE.',
            tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
     from fase_bil_d_elaborazione_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.fase_bil_elab_tipo_code=APE_PREV_DA_GEST
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null)
     returning fase_bil_elab_id into faseBilElabId;

     if faseBilElabId is null then
     	raise exception ' Inserimento non effettuato.';
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





	strMessaggio:='Lettura bilElemPrevTipo  per tipo='||bilElemPrevTipo||'.';
	select tipo.elem_tipo_id into strict bilElemPrevTipoId
    from siac_d_bil_elem_tipo tipo
    where tipo.elem_tipo_code=bilElemPrevTipo
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

	strMessaggio:='Lettura bilElemGestTipo  per tipo='||bilElemGestTipo||'.';
	select tipo.elem_tipo_id into strict bilElemGestTipoId
    from siac_d_bil_elem_tipo tipo
    where tipo.elem_tipo_code=bilElemGestTipo
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);


    -- lettura classificatori Tipo Id
	strMessaggio:='Lettura flagPerMemAttrId  per attr='||FLAG_PER_MEM||'.';
	select attr.attr_id into strict flagPerMemAttrId
    from siac_t_attr attr
    where attr.ente_proprietario_id=enteProprietarioId
	and   attr.attr_code=FLAG_PER_MEM
    and   attr.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',attr.validita_fine) or attr.validita_fine is null);

	strMessaggio:='Lettura cdcTipoId  per classif='||CL_CDC||'.';
	select tipo.classif_tipo_id into strict cdcTipoId
    from siac_d_class_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.classif_tipo_code=CL_CDC
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

	strMessaggio:='Lettura cdcTipoId  per classif='||CL_CDR||'.';
	select tipo.classif_tipo_id into strict cdrTipoId
    from siac_d_class_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.classif_tipo_code=CL_CDR
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

    strMessaggio:='Lettura pdcFinIVId  per classif='||CL_PDC_FIN_QUARTO||'.';
	select tipo.classif_tipo_id into strict pdcFinIVId
    from siac_d_class_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.classif_tipo_code=CL_PDC_FIN_QUARTO
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

    strMessaggio:='Lettura pdcFinVId  per classif='||CL_PDC_FIN_QUINTO||'.';
	select tipo.classif_tipo_id into strict pdcFinVId
    from siac_d_class_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.classif_tipo_code=CL_PDC_FIN_QUINTO
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

	if euElemTipo=TIPO_ELEM_EU then
		strMessaggio:='Lettura macroAggrTipoId  per classif='||CL_MACROAGGREGATO||'.';
		select tipo.classif_tipo_id into strict macroAggrTipoId
	    from siac_d_class_tipo tipo
    	where tipo.ente_proprietario_id=enteProprietarioId
	    and   tipo.classif_tipo_code=CL_MACROAGGREGATO
    	and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    	and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

		strMessaggio:='Lettura programmaTipoId  per classif='||CL_PROGRAMMA||'.';
		select tipo.classif_tipo_id into strict programmaTipoId
	    from siac_d_class_tipo tipo
    	where tipo.ente_proprietario_id=enteProprietarioId
	    and   tipo.classif_tipo_code=CL_PROGRAMMA
    	and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    	and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

        strMessaggio:='Lettura ricorrenteSpesaId  per classif='||CL_RICORRENTE_SPESA||'.';
		select tipo.classif_tipo_id into strict ricorrenteSpesaId
    	from siac_d_class_tipo tipo
	    where tipo.ente_proprietario_id=enteProprietarioId
    	and   tipo.classif_tipo_code=CL_RICORRENTE_SPESA
	    and   tipo.data_cancellazione is null
    	and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
	    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

	    strMessaggio:='Lettura transazioneUeSpesaId  per classif='||CL_TRANSAZIONE_UE_SPESA||'.';
		select tipo.classif_tipo_id into strict transazioneUeSpesaId
    	from siac_d_class_tipo tipo
	    where tipo.ente_proprietario_id=enteProprietarioId
    	and   tipo.classif_tipo_code=CL_TRANSAZIONE_UE_SPESA
	    and   tipo.data_cancellazione is null
    	and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
	    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

        strMessaggio:='Lettura cofogTipoId  per classif='||CL_COFOG||'.';
		select tipo.classif_tipo_id into strict cofogTipoId
	    from siac_d_class_tipo tipo
    	where tipo.ente_proprietario_id=enteProprietarioId
	    and   tipo.classif_tipo_code=CL_COFOG
    	and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    	and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

	    strMessaggio:='Lettura siopeSpesaTipoId  per classif='||CL_SIOPE_SPESA_TERZO||'.';
		select tipo.classif_tipo_id into strict siopeSpesaTipoId
	    from siac_d_class_tipo tipo
    	where tipo.ente_proprietario_id=enteProprietarioId
	    and   tipo.classif_tipo_code=CL_SIOPE_SPESA_TERZO
    	and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    	and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

    else

		strMessaggio:='Lettura categoriaTipoId  per classif='||CL_CATEGORIA||'.';
		select tipo.classif_tipo_id into strict categoriaTipoId
	    from siac_d_class_tipo tipo
    	where tipo.ente_proprietario_id=enteProprietarioId
	    and   tipo.classif_tipo_code=CL_CATEGORIA
    	and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    	and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

        strMessaggio:='Lettura ricorrenteEntrataId  per classif='||CL_RICORRENTE_ENTRATA||'.';
		select tipo.classif_tipo_id into strict ricorrenteEntrataId
    	from siac_d_class_tipo tipo
	    where tipo.ente_proprietario_id=enteProprietarioId
    	and   tipo.classif_tipo_code=CL_RICORRENTE_ENTRATA
	    and   tipo.data_cancellazione is null
    	and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
	    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

	    strMessaggio:='Lettura transazioneUeEntrataId  per classif='||CL_TRANSAZIONE_UE_ENTRATA||'.';
		select tipo.classif_tipo_id into strict transazioneUeEntrataId
    	from siac_d_class_tipo tipo
	    where tipo.ente_proprietario_id=enteProprietarioId
    	and   tipo.classif_tipo_code=CL_TRANSAZIONE_UE_ENTRATA
	    and   tipo.data_cancellazione is null
    	and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
	    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

	    strMessaggio:='Lettura siopeEntrataTipoId  per classif='||CL_SIOPE_ENTRATA_TERZO||'.';
		select tipo.classif_tipo_id into strict siopeEntrataTipoId
	    from siac_d_class_tipo tipo
    	where tipo.ente_proprietario_id=enteProprietarioId
	    and   tipo.classif_tipo_code=CL_SIOPE_ENTRATA_TERZO
    	and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    	and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);


    end if;

    -- fine lettura classificatori Tipo Id
    strMessaggio:='Inserimento LOG per lettura classificatori tipo.';
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


	strMessaggio:='Inserimento bilancio  per annoBilancio='||annoBilancio::varchar||'.';
    insert into siac_t_bil
    (bil_code,bil_desc,bil_tipo_id,periodo_id, validita_inizio, ente_proprietario_id, login_operazione)
    (select 'BIL_'||annoBilancio::varchar, 'Bilancio '||annoBilancio::varchar, btipo.bil_tipo_id,  per.periodo_id,
             dataInizioVal, per.ente_proprietario_id, loginOperazione
     from siac_t_periodo per ,siac_d_periodo_tipo tipo, siac_d_bil_tipo btipo
	 where per.ente_proprietario_id=enteProprietarioId
     and   per.anno::integer=annoBilancio
     and   tipo.periodo_tipo_id=per.periodo_tipo_id
     and   tipo.periodo_tipo_code=SY_PER_TIPO
     and   btipo.ente_proprietario_id=per.ente_proprietario_id
     and   btipo.bil_tipo_code=BIL_ORD_TIPO
     and   per.data_cancellazione is null
     and   not exists (select 1 from siac_t_bil bil
					    where bil.ente_proprietario_id=per.ente_proprietario_id
                        and   bil.bil_tipo_id=btipo.bil_tipo_id
                        and   bil.periodo_id=per.periodo_id
                        and   bil.data_cancellazione is null));

	strMessaggio:='Inserimento periodo  per annoBilancio+2='||(annoBilancio+2)::varchar||'.';
    insert into siac_t_periodo
    (periodo_code,periodo_desc,data_inizio,data_fine,validita_inizio, periodo_tipo_id,
     anno,ente_proprietario_id, login_operazione)
    (select 'anno'||(annoBilancio+2)::varchar, 'anno'||(annoBilancio+2)::varchar,
            ((annoBilancio+2)::varchar||'-01-01')::timestamp,((annoBilancio+2)::varchar||'-12-31')::timestamp,dataInizioVal,
            tipo.periodo_tipo_id, (annoBilancio+2)::varchar, tipo.ente_proprietario_id, loginOperazione
     from siac_d_periodo_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.periodo_tipo_code=SY_PER_TIPO
     and   not exists (select 1 from siac_t_periodo per1
                       where per1.periodo_tipo_id=tipo.periodo_tipo_id
                       and   per1.anno::integer=annoBilancio+2
                       and   per1.data_cancellazione is null));

    codResult:=null;
    strMessaggio:='Inserimento annoBilancio='||annoBilancio::varchar||' periodo per annoCompetenza='||(annoBilancio+2)::varchar||'.';
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

  	strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
    select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio
    and   bil.data_cancellazione is null
    and   per.data_cancellazione is null;


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

   	strMessaggio:='Inserimento fase tipo='||PREVISIONE_FASE||' per bilancio annoBilancio='||annoBilancio::varchar||'.';
	insert into siac_r_bil_fase_operativa
	(bil_id,fase_operativa_id, validita_inizio, ente_proprietario_id, login_operazione )
	(select bilancioId,f.fase_operativa_id,dataInizioVal,f.ente_proprietario_id,loginOperazione
	 from siac_d_fase_operativa f
     where f.ente_proprietario_id=enteProprietarioId
	 and   f.fase_operativa_code=PREVISIONE_FASE
	 and   not exists (select 1 from siac_r_bil_fase_operativa r
     	 		       where  r.bil_id=bilancioId
                       --and    r.fase_operativa_id=f.fase_operativa_id
                       and    r.data_cancellazione is null));

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


	strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
    select bil.bil_id , per.periodo_id into strict bilancioPrecId, periodoPrecId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio-1
    and   per.data_cancellazione is null;


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


	-- popolamento tabella appoggio

	-- capitoli previsione nuovi non esistenti in gestione

    strMessaggio:='Popolamento fase_bil_t_prev_apertura_str_elem_prev_nuovo.Previsione nuova con gestione eq anno precedente.';
    insert into fase_bil_t_prev_apertura_str_elem_prev_nuovo
    (elem_id,elem_code,elem_code2, elem_code3,
     bil_id,fase_bil_elab_id,
     ente_proprietario_id,validita_inizio,login_operazione)
    (select gest.elem_id, gest.elem_code,gest.elem_code2,gest.elem_code3,
            bilancioId,faseBilElabId,
            gest.ente_proprietario_id, dataInizioVal,loginOperazione
     from siac_t_bil_elem gest
     where gest.ente_proprietario_id=enteProprietarioId
     and   gest.elem_tipo_id=bilElemGestTipoId
     and   gest.bil_id=bilancioPrecId
     and   gest.data_cancellazione is null
     and   date_trunc('day',dataElaborazione)>=date_trunc('day',gest.validita_inizio)
     and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',gest.validita_fine) or gest.validita_fine is null)
     and   not exists (select 1 from siac_t_bil_elem prev
                       where prev.ente_proprietario_id=gest.ente_proprietario_id
                       and   prev.bil_id=bilancioId
                       and   prev.elem_tipo_id=bilElemPrevTipoId
                       and   prev.elem_code=gest.elem_code
                       and   prev.elem_code2=gest.elem_code2
                       and   prev.elem_code3=gest.elem_code3
                       and   prev.data_cancellazione is null
                       and   date_trunc('day',dataElaborazione)>=date_trunc('day',prev.validita_inizio)
   			 		   and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',prev.validita_fine) or prev.validita_fine is null)
                       order by prev.elem_id limit 1
                      )
     order by gest.elem_code::integer,gest.elem_code2::integer,gest.elem_code3
     );


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

    -- verifica apertura con previsione pre-esistente ( rielaborazione )
    if checkPrev=true then
        -- capitoli privisione esistenti con gestione eq anno precendente esistente - da aggiornare
    	strMessaggio:='Popolamento fase_bil_t_prev_apertura_str_elem_prev_esiste.Previsione esistente con gestione eq anno precedente.';
	    insert into fase_bil_t_prev_apertura_str_elem_prev_esiste
    	(elem_prev_id, elem_gest_id,elem_code,elem_code2, elem_code3,
         bil_id,fase_bil_elab_id,
         ente_proprietario_id,validita_inizio,login_operazione)
	    (select prev.elem_id, gest.elem_id,prev.elem_code,prev.elem_code2,prev.elem_code3,
                prev.bil_id,faseBilElabId,
                enteProprietarioId, dataInizioVal,loginOperazione
    	 from siac_t_bil_elem prev, siac_t_bil_elem gest
	     where prev.ente_proprietario_id=enteProprietarioId
	     and   prev.elem_tipo_id=bilElemPrevTipoId
	     and   prev.bil_id=bilancioId
	     and   gest.ente_proprietario_id=prev.ente_proprietario_id
	     and   gest.bil_id=bilancioPrecId
         and   gest.elem_tipo_id=bilElemGestTipoId
    	 and   gest.elem_code=prev.elem_code
	     and   gest.elem_code2=prev.elem_code2
	     and   gest.elem_code3=prev.elem_code3
		 and   prev.data_cancellazione is null
	     and   date_trunc('day',dataElaborazione)>=date_trunc('day',prev.validita_inizio)
    	 and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',prev.validita_fine) or prev.validita_fine is null)
	     and   gest.data_cancellazione is null
    	 and   date_trunc('day',dataElaborazione)>=date_trunc('day',gest.validita_inizio)
	   	 and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',gest.validita_fine) or gest.validita_fine is null)
    	 order by prev.elem_code::integer,prev.elem_code2::integer,prev.elem_code3
	    );


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

        -- capitoli previsione esistenti senza capitolo eq in gestione precedente - da invalidare, azzerare importi
    	strMessaggio:='Popolamento fase_bil_t_prev_apertura_str_elem_prev_esiste.Previsione esistente senza gestione eq anno precedente.';
	    insert into fase_bil_t_prev_apertura_str_elem_prev_esiste
    	(elem_prev_id, elem_gest_id,elem_code,elem_code2, elem_code3,
         bil_id,fase_bil_elab_id,
         ente_proprietario_id,validita_inizio,login_operazione)
	    (select prev.elem_id, null,prev.elem_code,prev.elem_code2,prev.elem_code3,
        	 	prev.bil_id,faseBilElabId,
                enteProprietarioId,dataInizioVal,loginOperazione
    	 from  siac_t_bil_elem prev
	     where prev.ente_proprietario_id=enteProprietarioId
	     and   prev.elem_tipo_id=bilElemPrevTipoid
	     and   prev.bil_id=bilancioId
	     and   prev.data_cancellazione is null
    	 and   date_trunc('day',dataElaborazione)>=date_trunc('day',prev.validita_inizio)
	   	 and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',prev.validita_fine) or prev.validita_fine is null)
         and   not exists (select  1 from siac_t_bil_elem gest
  						   where  gest.ente_proprietario_id=prev.ente_proprietario_id
                           and    gest.bil_id=bilancioPrecId
                           and    gest.elem_tipo_id=bilElemGestTipoId
                           and    gest.elem_code=prev.elem_code
						   and    gest.elem_code2=prev.elem_code2
					       and    gest.elem_code3=prev.elem_code3
					       and    gest.data_cancellazione is null
				    	   and    date_trunc('day',dataElaborazione)>=date_trunc('day',gest.validita_inizio)
				      	   and    ( date_trunc('day',dataElaborazione)<=date_trunc('day',gest.validita_fine) or gest.validita_fine is null)
                           order by gest.elem_id limit 1)
    	 order by prev.elem_code::integer,prev.elem_code2::integer,prev.elem_code3
	    );

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

	end if;

    codResult:=null;
    strMessaggio:='Popolamento fase_bil_t_prev_apertura_str_elem_prev_nuovo.Verifica esistenza capitoli di previsione nuovi da creare da gestione eq precedente.';
    select 1 into codResult
    from fase_bil_t_prev_apertura_str_elem_prev_nuovo fase
    where fase.ente_proprietario_id=enteProprietarioId
    and   fase.bil_id=bilancioId
    and   fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    order by fase.fase_bil_prev_str_nuovo_id limit 1;


    if codResult is not null then
 	-- inserimento nuove strutture
    -- capitoli previsione non esistenti da gestione eq anno precedente
     strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||'.';

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


    for elemBil in
    (select elem_id, elem_code,elem_code2,elem_code3
     from fase_bil_t_prev_apertura_str_elem_prev_nuovo
     where ente_proprietario_id=enteProprietarioId
     and   bil_id=bilancioId
     and   fase_bil_elab_id=faseBilElabId
     and   data_cancellazione is NULL
     and   validita_fine is null
     order by elem_code::integer,elem_code2::integer,elem_code3
    )
    loop
    	bilElemIdRet:=null;
        strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        			  '.Elemento di bilancio '||elemBil.elem_code||' '
                                              ||elemBil.elem_code2||' '
                                              ||elemBil.elem_code3||' : siac_t_bil_elem.' ;
        -- siac_t_bil_elem
    	insert into siac_t_bil_elem
	    (elem_code,elem_code2,elem_code3, elem_desc,elem_desc2,
    	 elem_tipo_id, bil_id,ordine,livello,
	     validita_inizio , ente_proprietario_id,login_operazione)
        (select gest.elem_code,gest.elem_code2,gest.elem_code3,gest.elem_desc, gest.elem_desc2,
	            bilElemPrevTipoId,bilancioId,gest.ordine,gest.livello,
                dataInizioVal,gest.ente_proprietario_id,loginOperazione
         from siac_t_bil_elem gest
         where gest.elem_id=elemBil.elem_id)
         returning elem_id into bilElemIdRet;

        if bilElemIdRet is null then raise exception ' Inserimento non effettuato.';  end if;

        codResult:=null;
        strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        			  '.Elemento di bilancio '||elemBil.elem_code||' '
                                              ||elemBil.elem_code2||' '
                                              ||elemBil.elem_code3||' : siac_r_bil_elem_stato.' ;

        -- siac_r_bil_elem_stato
	    strMessaggio:='Inserimento siac_r_bil_elem_stato.';
	    insert into siac_r_bil_elem_stato
    	(elem_id,elem_stato_id,validita_inizio,ente_proprietario_id,login_operazione)
    	(select bilElemIdRet,stato.elem_stato_id,dataInizioVal,stato.ente_proprietario_id, loginOperazione
         from siac_r_bil_elem_stato stato
         where stato.elem_id=elemBil.elem_id
         and   stato.data_cancellazione is null
         and   date_trunc('day',dataElaborazione)>=date_trunc('day',stato.validita_inizio)
	   	 and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',stato.validita_fine) or stato.validita_fine is null)
         )
         returning bil_elem_stato_id into codResult;
         if codResult is null then raise exception ' Inserimento non effettuato.'; end if;

         codResult:=null;
         -- siac_r_bil_elem_categoria
         strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        			   '.Elemento di bilancio '||elemBil.elem_code||' '
                                              ||elemBil.elem_code2||' '
                                              ||elemBil.elem_code3||' : siac_r_bil_elem_categoria.' ;

         insert into siac_r_bil_elem_categoria
	     (elem_id,  elem_cat_id, validita_inizio,ente_proprietario_id, login_operazione)
         (select bilElemIdRet, cat.elem_cat_id,dataInizioVal,cat.ente_proprietario_id,loginOperazione
          from siac_r_bil_elem_categoria cat
          where cat.elem_id=elemBil.elem_id
          and   cat.data_cancellazione is null
          and   date_trunc('day',dataElaborazione)>=date_trunc('day',cat.validita_inizio)
	   	  and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',cat.validita_fine) or cat.validita_fine is null)
         )
         returning bil_elem_r_cat_id into codResult;
         if codResult is null then raise exception ' Inserimento non effettuato.'; end if;

         -- salvataggio della categoria per successivi controlli su classificatori obbligatori
         select d.elem_cat_code into categoriaCapCode
         from siac_r_bil_elem_categoria r, siac_d_bil_elem_categoria d where
         d.elem_cat_id=r.elem_cat_id
         and r.bil_elem_r_cat_id=codResult;

         codResult:=null;
         -- siac_r_bil_elem_attr
         strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        			   '.Elemento di bilancio '||elemBil.elem_code||' '
                                              ||elemBil.elem_code2||' '
                                              ||elemBil.elem_code3||' : siac_r_bil_elem_attr.' ;
         insert into siac_r_bil_elem_attr
         ( elem_id,attr_id, tabella_id,boolean,percentuale,testo,numerico,
           validita_inizio,ente_proprietario_id,login_operazione
         )
         (select bilElemIdRet, attr.attr_id,attr.tabella_id,attr.boolean,attr.percentuale,attr.testo,attr.numerico,
                 dataInizioVal,attr.ente_proprietario_id, loginOperazione
          from siac_r_bil_elem_attr attr
          where attr.elem_id=elemBil.elem_id
          and   attr.data_cancellazione is null
          and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
	   	  and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',attr.validita_fine) or attr.validita_fine is null)
          );

          codResult:=null;
          -- siac_r_bil_elem_attr FLAG_PER_MEM - default N - attributo non presente in gestione
          strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
         			    '.Elemento di bilancio '||elemBil.elem_code||' '
                                              ||elemBil.elem_code2||' '
                                              ||elemBil.elem_code3||' : siac_r_bil_elem_attr attributo'||FLAG_PER_MEM||'.' ;
         insert into siac_r_bil_elem_attr
         ( elem_id,attr_id, boolean,validita_inizio,ente_proprietario_id,login_operazione)
         values
         (bilElemIdRet, flagPerMemAttrId,'N',dataInizioVal,enteProprietarioId, loginOperazione);

          select 1 into codResult
          from siac_r_bil_elem_attr
          where elem_id=bilElemIdRet
          and   data_cancellazione is null
          and   validita_fine is null
          order by elem_id
          limit 1;
          if codResult is null then raise exception ' Nessun attributo inserito.'; end if;

         codResult:=null;
         -- siac_r_vincolo_bil_elem
         strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        			   '.Elemento di bilancio '||elemBil.elem_code||' '
                                              ||elemBil.elem_code2||' '
                                              ||elemBil.elem_code3||' : siac_r_vincolo_bil_elem.' ;
         insert into siac_r_vincolo_bil_elem
         ( elem_id,vincolo_id, validita_inizio,ente_proprietario_id,login_operazione
         )
         (select bilElemIdRet, v.vincolo_id, dataInizioVal,v.ente_proprietario_id, loginOperazione
          from siac_r_vincolo_bil_elem v
          where v.elem_id=elemBil.elem_id
          and   v.data_cancellazione is null
          and   date_trunc('day',dataElaborazione)>=date_trunc('day',v.validita_inizio)
	   	  and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',v.validita_fine) or v.validita_fine is null)
          );

          codResult:=null;
          strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        			    '.Elemento di bilancio '||elemBil.elem_code||' '
                                               ||elemBil.elem_code2||' '
                                               ||elemBil.elem_code3||' : siac_r_vincolo_bil_elem.Verifica inserimento.' ;
          select  1  into codResult
          from 	siac_r_vincolo_bil_elem v
          where v.elem_id=elemBil.elem_id
          and   v.data_cancellazione is null
          and   date_trunc('day',dataElaborazione)>=date_trunc('day',v.validita_inizio)
	   	  and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',v.validita_fine) or v.validita_fine is null)
          and   not exists (select 1 from siac_r_vincolo_bil_elem v1
	                        where v1.elem_id= bilElemIdRet
    	                    and   v1.data_cancellazione is null
				            and   date_trunc('day',dataElaborazione)>=date_trunc('day',v1.validita_inizio)
				  	   	    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',v1.validita_fine) or v1.validita_fine is null)
                            order by v1.elem_id
                            limit 1
                            )
          order by v.elem_id
          limit 1;
          if codResult is not null then raise exception ' Non effettuato.'; end if;


         codResult:=null;
         -- siac_r_bil_elem_atto_legge
         strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        			   '.Elemento di bilancio '||elemBil.elem_code||' '
                                              ||elemBil.elem_code2||' '
                                              ||elemBil.elem_code3||' : siac_r_bil_elem_atto_legge.' ;
         insert into siac_r_bil_elem_atto_legge
         ( elem_id,attolegge_id, descrizione, gerarchia,finanziamento_inizio,finanziamento_fine,
           validita_inizio,ente_proprietario_id,login_operazione
         )
         (select bilElemIdRet, v.attolegge_id, v.descrizione,v.gerarchia,v.finanziamento_inizio,v.finanziamento_fine,
                 dataInizioVal,v.ente_proprietario_id, loginOperazione
          from siac_r_bil_elem_atto_legge v
          where v.elem_id=elemBil.elem_id
          and   v.data_cancellazione is null
          and   date_trunc('day',dataElaborazione)>=date_trunc('day',v.validita_inizio)
	   	  and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',v.validita_fine) or v.validita_fine is null)
          );


          codResult:=null;
          strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        			    '.Elemento di bilancio '||elemBil.elem_code||' '
                                                ||elemBil.elem_code2||' '
                                                ||elemBil.elem_code3||' : siac_r_bil_elem_atto_legge.Verifica inserimento.' ;
          select 1  into codResult
          from 	siac_r_bil_elem_atto_legge v
          where v.elem_id=elemBil.elem_id
          and   v.data_cancellazione is null
          and   date_trunc('day',dataElaborazione)>=date_trunc('day',v.validita_inizio)
	   	  and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',v.validita_fine) or v.validita_fine is null)
          and   not exists (select 1 from siac_r_bil_elem_atto_legge v1
	                        where v1.elem_id= bilElemIdRet
    	                    and   v1.data_cancellazione is null
				            and   date_trunc('day',dataElaborazione)>=date_trunc('day',v1.validita_inizio)
				  	   	    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',v1.validita_fine) or v1.validita_fine is null)
                            order by v1.elem_id
                            limit 1
                            )
          order by v.elem_id
          limit 1;
          if codResult is not null then raise exception ' Non effettuato.'; end if;

          strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        			    '.Elemento di bilancio '||elemBil.elem_code||' '
                                               ||elemBil.elem_code2||' '
                                               ||elemBil.elem_code3||' : siac_r_bil_elem_rel_tempo.' ;
 		  insert into siac_r_bil_elem_rel_tempo
          (elem_id, elem_id_old, validita_inizio, ente_proprietario_id,login_operazione)
          (select bilElemIdRet,v.elem_id_old, dataInizioVal,v.ente_proprietario_id, loginOperazione
           from siac_r_bil_elem_rel_tempo v
           where v.elem_id=elemBil.elem_id
	       and   v.data_cancellazione is null
           and   date_trunc('day',dataElaborazione)>=date_trunc('day',v.validita_inizio)
	   	   and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',v.validita_fine) or v.validita_fine is null));

          codResult:=null;
          strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        			    '.Elemento di bilancio '||elemBil.elem_code||' '
                                               ||elemBil.elem_code2||' '
                                               ||elemBil.elem_code3||' : siac_r_bil_elem_rel_tempo.Verifica inserimento.' ;
          select 1  into codResult
          from 	siac_r_bil_elem_rel_tempo v
          where v.elem_id=elemBil.elem_id
          and   v.data_cancellazione is null
          and   date_trunc('day',dataElaborazione)>=date_trunc('day',v.validita_inizio)
	   	  and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',v.validita_fine) or v.validita_fine is null)
          and   not exists (select 1 from siac_r_bil_elem_rel_tempo v1
	                        where v1.elem_id= bilElemIdRet
    	                    and   v1.data_cancellazione is null
				            and   date_trunc('day',dataElaborazione)>=date_trunc('day',v1.validita_inizio)
				  	   	    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',v1.validita_fine) or v1.validita_fine is null)
                            order by v1.elem_id
                            limit 1
                            )
          order by v.elem_id
          limit 1;
          if codResult is not null then raise exception ' Non effettuato.'; end if;


	      codResult:=null;
	      -- siac_r_bil_elem_class
          strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        			    '.Elemento di bilancio '||elemBil.elem_code||' '
                                               ||elemBil.elem_code2||' '
                                               ||elemBil.elem_code3||' : siac_r_bil_elem_class.' ;
         insert into siac_r_bil_elem_class
         (elem_id,classif_id, validita_inizio, ente_proprietario_id,login_operazione)
         (select bilElemIdRet, class.classif_id,dataInizioVal,class.ente_proprietario_id,loginOperazione
          from siac_r_bil_elem_class class
          where class.elem_id=elemBil.elem_id
          and   class.data_cancellazione is null
          and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
	   	  and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',class.validita_fine) or class.validita_fine is null));

          select 1 into codResult
          from siac_r_bil_elem_class
          where elem_id=bilElemIdRet
          and   data_cancellazione is null
          and   validita_fine is null
          order by elem_id
          limit 1;
          if codResult is null then raise exception ' Nessun classificatore inserito.'; end if;

          -- controlli sui classificatori obbligatori
          -- CL_CDC, CL_CDR
          codResult:=null;
          strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        			    '.Elemento di bilancio '||elemBil.elem_code||' '
                                               ||elemBil.elem_code2||' '
                                               ||elemBil.elem_code3||' : verifica classificatore '||CL_CDC||' '||CL_CDR||'.' ;
          select 1 into codResult
          from siac_r_bil_elem_class r, siac_t_class c
          where r.elem_id=bilElemIdRet
          and   c.classif_id=r.classif_id
          and   c.classif_tipo_id in (cdcTipoId, cdrTipoId)
          and   c.data_cancellazione is null
          and   c.validita_fine is null
          order by r.elem_id
          limit 1;
          if codResult is null then raise exception ' Nessuno inserimento effettuato.'; end if;

   	      -- CL_PDC_FIN_QUINTO, CL_PDC_FIN_QUARTO
		  codResult:=null;
          strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        			    '.Elemento di bilancio '||elemBil.elem_code||' '
                                               ||elemBil.elem_code2||' '
                                               ||elemBil.elem_code3||' : verifica classificatore '||CL_PDC_FIN_QUARTO||' '||CL_PDC_FIN_QUINTO||'.' ;
          select 1 into codResult
          from siac_r_bil_elem_class r, siac_t_class c
          where r.elem_id=bilElemIdRet
          and   c.classif_id=r.classif_id
          and   c.classif_tipo_id in (pdcFinIVId, pdcFinVId)
          and   c.data_cancellazione is null
          and   c.validita_fine is null
          order by r.elem_id
          limit 1;

          -- Obbligatorietà del classificatore vale solo per capitolo STANDARD
		  if categoriaCapCode = CATEGORIA_STD then
	          if codResult is null then raise exception ' Nessuno inserimento effettuato.'; end if;
          end if;

          if euElemTipo=TIPO_ELEM_EU then
	          -- CL_PROGRAMMA
              codResult:=null;
        	  strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        				    '.Elemento di bilancio '||elemBil.elem_code||' '
                	                               ||elemBil.elem_code2||' '
                    	                           ||elemBil.elem_code3||' : verifica classificatore '||CL_PROGRAMMA||'.' ;
	          select 1 into codResult
    	      from siac_r_bil_elem_class r, siac_t_class c
        	  where r.elem_id=bilElemIdRet
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=programmaTipoId
              and   c.data_cancellazione is null
         	  and   c.validita_fine is null
              order by r.elem_id
        	  limit 1;

              -- Obbligatorietà del classificatore vale solo per capitolo STANDARD
              if categoriaCapCode = CATEGORIA_STD then
                  if codResult is null then raise exception ' Nessuno inserimento effettuato.'; end if;
              end if;

    	      -- CL_MACROAGGREGATO
              codResult:=null;
        	  strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        				    '.Elemento di bilancio '||elemBil.elem_code||' '
                	                               ||elemBil.elem_code2||' '
                    	                           ||elemBil.elem_code3||' : verifica classificatore '||CL_MACROAGGREGATO||'.' ;
	          select 1 into codResult
    	      from siac_r_bil_elem_class r, siac_t_class c
        	  where r.elem_id=bilElemIdRet
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=macroAggrTipoId
              and   c.data_cancellazione is null
          	  and   c.validita_fine is null
              order by r.elem_id
        	  limit 1;
              -- Obbligatorietà del classificatore vale solo per capitolo STANDARD
              if categoriaCapCode = CATEGORIA_STD then
		          if codResult is null then raise exception ' Nessuno inserimento effettuato.'; end if;
              end if;

			  -- CL_COFOG
              codResult:=null;
        	  strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        				    '.Elemento di bilancio '||elemBil.elem_code||' '
                	                               ||elemBil.elem_code2||' '
                    	                           ||elemBil.elem_code3||' : verifica classificatore '||CL_COFOG||'.' ;

			  -- Definizione classificatore necessaria solo se presente in gestione equivalente
              select 1 into codResult
              from  siac_r_bil_elem_class r, siac_t_class c
              where r.elem_id=elemBil.elem_id
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=cofogTipoId
              and   c.data_cancellazione is null
		      and   c.validita_fine is null
              and   not exists ( select distinct 1
					    	     from siac_r_bil_elem_class r, siac_t_class c
					       	     where r.elem_id=bilElemIdRet
						         and   c.classif_id=r.classif_id
					   	         and   c.classif_tipo_id=cofogTipoId
					             and   c.data_cancellazione is null
							     and   c.validita_fine is null
                                 )
			  order by r.elem_id limit 1;
	          if codResult is not null then raise exception ' Nessuno inserimento effettuato.'; end if;

        	  -- CL_RICORRENTE_SPESA
              codResult:=null;
        	  strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        				    '.Elemento di bilancio '||elemBil.elem_code||' '
                	                               ||elemBil.elem_code2||' '
                    	                           ||elemBil.elem_code3||' : verifica classificatore '||CL_RICORRENTE_SPESA||'.' ;
			  -- Definizione classificatore necessaria solo se presente in gestione equivalente
              select 1 into codResult
              from  siac_r_bil_elem_class r, siac_t_class c
              where r.elem_id=elemBil.elem_id
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=ricorrenteSpesaId
              and   c.data_cancellazione is null
		      and   c.validita_fine is null
              and   not exists ( select distinct 1
					    	     from siac_r_bil_elem_class r, siac_t_class c
					       	     where r.elem_id=bilElemIdRet
						         and   c.classif_id=r.classif_id
					   	         and   c.classif_tipo_id=ricorrenteSpesaId
					             and   c.data_cancellazione is null
							     and   c.validita_fine is null
                                 )
			  order by r.elem_id limit 1;
	          if codResult is not null then raise exception ' Nessuno inserimento effettuato.'; end if;

	          -- CL_SIOPE_SPESA_TERZO
              codResult:=null;
        	  strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        				    '.Elemento di bilancio '||elemBil.elem_code||' '
                	                               ||elemBil.elem_code2||' '
                    	                           ||elemBil.elem_code3||' : verifica classificatore '||CL_SIOPE_SPESA_TERZO||'.' ;

              select 1 into codResult
              from  siac_r_bil_elem_class r, siac_t_class c
              where r.elem_id=elemBil.elem_id
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=siopeSpesaTipoId
              and   c.data_cancellazione is null
		      and   c.validita_fine is null
              and   not exists ( select distinct 1
					    	     from siac_r_bil_elem_class r, siac_t_class c
					       	     where r.elem_id=bilElemIdRet
						         and   c.classif_id=r.classif_id
					   	         and   c.classif_tipo_id=siopeSpesaTipoId
					             and   c.data_cancellazione is null
							     and   c.validita_fine is null
                                 )
			  order by r.elem_id
              limit 1;

	          if codResult is not null then raise exception ' Nessuno inserimento effettuato.'; end if;

    	      -- CL_TRANSAZIONE_UE_SPESA
              codResult:=null;
        	  strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        				    '.Elemento di bilancio '||elemBil.elem_code||' '
                	                               ||elemBil.elem_code2||' '
                    	                           ||elemBil.elem_code3||' : verifica classificatore '||CL_TRANSAZIONE_UE_SPESA||'.' ;

			  -- Definizione classificatore necessaria solo se presente in gestione equivalente
              select 1 into codResult
              from  siac_r_bil_elem_class r, siac_t_class c
              where r.elem_id=elemBil.elem_id
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=transazioneUeSpesaId
              and   c.data_cancellazione is null
		      and   c.validita_fine is null
              and   not exists ( select distinct 1
					    	     from siac_r_bil_elem_class r, siac_t_class c
					       	     where r.elem_id=bilElemIdRet
						         and   c.classif_id=r.classif_id
					   	         and   c.classif_tipo_id=transazioneUeSpesaId
					             and   c.data_cancellazione is null
							     and   c.validita_fine is null
                                 )
			  order by r.elem_id limit 1;
	          if codResult is not null then raise exception ' Nessuno inserimento effettuato.'; end if;

          else

    	      -- CL_CATEGORIA
              codResult:=null;
        	  strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        				    '.Elemento di bilancio '||elemBil.elem_code||' '
                	                               ||elemBil.elem_code2||' '
                    	                           ||elemBil.elem_code3||' : verifica classificatore '||CL_CATEGORIA||'.' ;
	          select 1 into codResult
    	      from siac_r_bil_elem_class r, siac_t_class c
        	  where r.elem_id=bilElemIdRet
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=categoriaTipoId
              and   c.data_cancellazione is null
		      and   c.validita_fine is null
              order by r.elem_id
        	  limit 1;
              -- Obbligatorietà del classificatore vale solo per capitolo STANDARD
              if categoriaCapCode = CATEGORIA_STD then
				  if codResult is null then raise exception ' Nessuno inserimento effettuato.'; end if;
              end if;

        	  -- CL_RICORRENTE_ENTRATA
              codResult:=null;
        	  strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        				    '.Elemento di bilancio '||elemBil.elem_code||' '
                	                               ||elemBil.elem_code2||' '
                    	                           ||elemBil.elem_code3||' : verifica classificatore '||CL_RICORRENTE_ENTRATA||'.' ;
			  -- Definizione classificatore necessaria solo se presente in previsione
              select 1 into codResult
              from  siac_r_bil_elem_class r, siac_t_class c
              where r.elem_id=elemBil.elem_id
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=ricorrenteEntrataId
              and   c.data_cancellazione is null
		      and   c.validita_fine is null
              and   not exists ( select distinct 1
					    	     from siac_r_bil_elem_class r, siac_t_class c
					       	     where r.elem_id=bilElemIdRet
						         and   c.classif_id=r.classif_id
					   	         and   c.classif_tipo_id=ricorrenteEntrataId
					             and   c.data_cancellazione is null
							     and   c.validita_fine is null
                                 )
			  order by r.elem_id limit 1;
	          if codResult is not null then raise exception ' Nessuno inserimento effettuato.'; end if;

	          -- CL_SIOPE_ENTRATA_TERZO
              codResult:=null;
        	  strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        				    '.Elemento di bilancio '||elemBil.elem_code||' '
                	                               ||elemBil.elem_code2||' '
                    	                           ||elemBil.elem_code3||' : verifica classificatore '||CL_SIOPE_ENTRATA_TERZO||'.' ;

	          select 1 into codResult
    	      from siac_r_bil_elem_class r, siac_t_class c
        	  where r.elem_id=elemBil.elem_id
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=siopeEntrataTipoId
              and   c.data_cancellazione is null
		      and   c.validita_fine is null
              and   not exists (select 1
				      	        from siac_r_bil_elem_class r, siac_t_class c
				        	    where r.elem_id=bilElemIdRet
					            and   c.classif_id=r.classif_id
					   	        and   c.classif_tipo_id=siopeEntrataTipoId
			                    and   c.data_cancellazione is null
							    and   c.validita_fine is null
                                order by r.elem_id
                                limit 1)
			  order by r.elem_id
              limit 1;
	          if codResult is not null then raise exception ' Nessuno inserimento effettuato.'; end if;

    	      -- CL_TRANSAZIONE_UE_ENTRATA
              codResult:=null;
        	  strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        				    '.Elemento di bilancio '||elemBil.elem_code||' '
                	                               ||elemBil.elem_code2||' '
                    	                           ||elemBil.elem_code3||' : verifica classificatore '||CL_TRANSAZIONE_UE_ENTRATA||'.' ;

			  -- Definizione classificatore necessaria solo se presente in previsione
              select 1 into codResult
              from  siac_r_bil_elem_class r, siac_t_class c
              where r.elem_id=elemBil.elem_id
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=transazioneUeEntrataId
              and   c.data_cancellazione is null
		      and   c.validita_fine is null
              and   not exists ( select distinct 1
					    	     from siac_r_bil_elem_class r, siac_t_class c
					       	     where r.elem_id=bilElemIdRet
						         and   c.classif_id=r.classif_id
					   	         and   c.classif_tipo_id=transazioneUeEntrataId
					             and   c.data_cancellazione is null
							     and   c.validita_fine is null
                                 )
			  order by r.elem_id limit 1;
	          if codResult is not null then raise exception ' Nessuno inserimento effettuato.'; end if;
          end if;

          strMessaggio:='Inserimento nuove strutture per tipo='||bilElemPrevTipo||
        			    '.Elemento di bilancio '||elemBil.elem_code||' '
                                               ||elemBil.elem_code2||' '
                                               ||elemBil.elem_code3||' : aggiornamento relazione tra elem_id_gest prec e elem_id_prev nuovo.' ;
          update fase_bil_t_prev_apertura_str_elem_prev_nuovo set elem_prev_id=bilElemIdRet
          where elem_id=elemBil.elem_id
          and   fase_bil_elab_id=faseBilElabId;

  end loop;

  strMessaggio:='Conclusione inserimento nuove strutture per tipo='||bilElemPrevTipo||'.';
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

 end if;

 -- verifica apertura con previsione pre-esistente ( rielaborazione )
 if checkPrev=true then

 	codResult:=null;
    strMessaggio:='Verifica esistenza elementi di bilancio di previsione equivalenti da aggiornare da gestione anno prec.';
	select 1 into codResult
    from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
    where fase.ente_proprietario_id=enteProprietarioId
    and   fase.bil_id=bilancioId
    and   fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   fase.elem_gest_id is not null
    order by fase.fase_bil_prev_str_esiste_id
    limit 1;

    if codResult is not null then
    -- popolamento tabelle bck per salvataggio precedenti strutture
    -- siac_t_bil_elem
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

    strMessaggio:='Backup vecchia struttura [siac_t_bil_elem] per capitoli di previsione equivalente per nuovo aggiornamento.';
    insert into bck_fase_bil_t_prev_apertura_bil_elem
    (elem_gest_id, elem_bck_id,elem_bck_code,elem_bck_code2, elem_bck_code3,
     elem_bck_desc,elem_bck_desc2, elem_bck_bil_id, elem_bck_id_padre, elem_bck_tipo_id, elem_bck_livello,
     elem_bck_ordine, elem_bck_data_creazione, elem_bck_data_modifica, elem_bck_login_operazione,
     elem_bck_validita_inizio, elem_bck_validita_fine,fase_bil_elab_id,
     ente_proprietario_id, login_operazione,validita_inizio)
    (select fase.elem_gest_id,elem.elem_id, elem.elem_code,elem.elem_code2,elem.elem_code3,
            elem.elem_desc,elem.elem_desc2, elem.bil_id, elem.elem_id_padre, elem.elem_tipo_id, elem.livello,
            elem.ordine, elem.data_creazione, elem.data_modifica, elem.login_operazione,
            elem.validita_inizio, elem.validita_fine,faseBilElabId,
            elem.ente_proprietario_id, loginOperazione,dataInizioVal
	 from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem elem
     where fase.ente_proprietario_id=enteProprietarioId
     and   fase.bil_id=bilancioId
     and   fase.fase_bil_elab_id=faseBilElabId
     and   elem.elem_id=fase.elem_prev_id
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null
     and   fase.elem_gest_id is not null
     );


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


	 codResult:=null;
     strMessaggio:='Inizio cancellazione logica vecchie strutture previsione esistenti.';
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

     -- cancellazione logica precendenti relazioni
     -- siac_r_bil_elem_stato
     strMessaggio:='Cancellazione logica vecchie strutture previsione esistenti [siac_r_bil_elem_stato].';
     update siac_r_bil_elem_stato canc  set
      data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
     where canc.ente_proprietario_id=enteProprietarioId
     and   canc.data_cancellazione is null and canc.validita_fine is null
     and   exists (select 1 from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
                   where fase.ente_proprietario_id=enteProprietarioId
                   and   fase.bil_id=bilancioId
                   and   fase.fase_bil_elab_id=faseBilElabId
                   and   fase.elem_prev_id=canc.elem_id
                   and   fase.elem_gest_id is not null
                   and   fase.data_cancellazione is null
                   order by fase.fase_bil_prev_str_esiste_id
                   limit 1);

     -- siac_r_bil_elem_categoria
     strMessaggio:='Cancellazione logica vecchie strutture previsione esistenti [siac_r_bil_elem_categoria].';
     update  siac_r_bil_elem_categoria canc set
          data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
     where canc.ente_proprietario_id=enteProprietarioId
     and   canc.data_cancellazione is null and canc.validita_fine is null
     and   exists (select 1 from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
                   where fase.ente_proprietario_id=enteProprietarioId
                   and   fase.bil_id=bilancioId
                   and   fase.fase_bil_elab_id=faseBilElabId
                   and   fase.elem_prev_id=canc.elem_id
                   and   fase.elem_gest_id is not null
                   and   fase.data_cancellazione is null
                   order by fase.fase_bil_prev_str_esiste_id
                   limit 1);
     -- siac_r_bil_elem_attr
     strMessaggio:='Cancellazione logica vecchie strutture previsione esistenti [siac_r_bil_elem_attr].';
     update siac_r_bil_elem_attr canc set
          data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
     where canc.ente_proprietario_id=enteProprietarioId
     and   canc.attr_id!=flagPerMemAttrId -- esclusione FLAG_PER_MEM
     and   canc.data_cancellazione is null and canc.validita_fine is null
     and   exists (select 1 from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
                   where fase.ente_proprietario_id=enteProprietarioId
                   and   fase.bil_id=bilancioId
                   and   fase.fase_bil_elab_id=faseBilElabId
                   and   fase.elem_prev_id=canc.elem_id
                   and   fase.elem_gest_id is not null
                   and   fase.data_cancellazione is null
                   order by fase.fase_bil_prev_str_esiste_id
                   limit 1);

     -- siac_r_bil_elem_class
     strMessaggio:='Cancellazione logica vecchie strutture previsione esistenti [siac_r_bil_elem_class].';
     update siac_r_bil_elem_class canc set
              data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
     where canc.ente_proprietario_id=enteProprietarioId
     and   canc.data_cancellazione is null and canc.validita_fine is null
     and   exists (select 1 from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
                   where fase.ente_proprietario_id=enteProprietarioId
                   and   fase.bil_id=bilancioId
                   and   fase.fase_bil_elab_id=faseBilElabId
                   and   fase.elem_prev_id=canc.elem_id
                   and   fase.elem_gest_id is not null
                   and   fase.data_cancellazione is null
                   order by fase.fase_bil_prev_str_esiste_id
                   limit 1);

     -- siac_r_vincolo_bil_elem
     strMessaggio:='Cancellazione logica vecchie strutture previsione esistenti [siac_r_vincolo_bil_elem].';
     update siac_r_vincolo_bil_elem canc set
              data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
     where canc.ente_proprietario_id=enteProprietarioId
     and   canc.data_cancellazione is null and canc.validita_fine is null
     and   exists (select 1 from  fase_bil_t_prev_apertura_str_elem_prev_esiste fase
                   where fase.ente_proprietario_id=enteProprietarioId
                   and   fase.bil_id=bilancioId
                   and   fase.fase_bil_elab_id=faseBilElabId
                   and   fase.elem_prev_id=canc.elem_id
                   and   fase.elem_gest_id is not null
                   and   fase.data_cancellazione is null
                   order by fase.fase_bil_prev_str_esiste_id
                   limit 1);


     -- siac_r_bil_elem_atto_legge
     strMessaggio:='Cancellazione logica vecchie strutture previsione esistenti [siac_r_bil_elem_atto_legge].';
     update siac_r_bil_elem_atto_legge canc set
              data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
     where canc.ente_proprietario_id=enteProprietarioId
     and   canc.data_cancellazione is null and canc.validita_fine is null
     and   exists (select 1 from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
                   where fase.ente_proprietario_id=enteProprietarioId
                   and   fase.bil_id=bilancioId
                   and   fase.fase_bil_elab_id=faseBilElabId
                   and   fase.elem_prev_id=canc.elem_id
                   and   fase.elem_gest_id is not null
                   and   fase.data_cancellazione is null
                   order by fase.fase_bil_prev_str_esiste_id
                   limit 1);

	 -- siac_r_bil_elem_rel_tempo
     strMessaggio:='Cancellazione logica vecchie strutture previsione esistenti [siac_r_bil_elem_rel_tempo].';
	 update 	siac_r_bil_elem_rel_tempo canc set
		    data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
	 where canc.ente_proprietario_id=enteProprietarioId
     and   canc.data_cancellazione is null and canc.validita_fine is null
     and   exists (select 1 from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
                   where fase.ente_proprietario_id=enteProprietarioId
                   and   fase.bil_id=bilancioId
                   and   fase.fase_bil_elab_id=faseBilElabId
                   and   fase.elem_prev_id=canc.elem_id
                   and   fase.elem_gest_id is not null
                   and   fase.data_cancellazione is null
                   order by fase.fase_bil_prev_str_esiste_id
                   limit 1);

	 codResult:=null;
     strMessaggio:='Fine cancellazione logica vecchie strutture previsione esistenti.';
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

     -- cancellazione logica precendenti relazioni

     -- aggiornamento siac_t_bil_elem
     strMessaggio:='Aggiornamento nuova struttura previsione esistente da gestione equivalente anno precedente [siac_t_bil_elem].';
     update siac_t_bil_elem prev set
     (elem_desc, elem_desc2, ordine, livello, login_operazione)=
     (gest.elem_desc,gest.elem_desc2,gest.ordine,gest.livello,loginOperazione)
     from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem gest
     where  prev.ente_proprietario_id=enteProprietarioId
     and    prev.elem_id=fase.elem_prev_id
     and    gest.elem_id=fase.elem_gest_id
     and    fase.ente_proprietario_id=enteProprietarioid
     and    fase.bil_id=bilancioId
     and    fase.fase_bil_elab_id=faseBilElabId
     and    fase.data_cancellazione is null
     and    fase.elem_gest_id is not null;

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

     codResult:=null;
     strMessaggio:='Inizio inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente.';
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

     -- inserimento nuove relazioni
     -- siac_r_bil_elem_stato
     strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_stato].';
     insert into siac_r_bil_elem_stato
     (elem_id,elem_stato_id,validita_inizio,ente_proprietario_id,login_operazione)
     (select fase.elem_prev_id, stato.elem_stato_id , dataInizioVal, stato.ente_proprietario_id, loginOperazione
      from siac_r_bil_elem_stato stato, fase_bil_t_prev_apertura_str_elem_prev_esiste fase
      where stato.elem_id=fase.elem_gest_id
      and   fase.ente_proprietario_id=enteProprietarioid
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.data_cancellazione is null
      and   fase.elem_gest_id is not null
      and   stato.data_cancellazione is null
      and   stato.validita_fine is null);

     -- siac_r_bil_elem_attr
     strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_attr].';
     insert into siac_r_bil_elem_attr
     (elem_id,attr_id,tabella_id,boolean,percentuale,
      testo,numerico,validita_inizio,
      ente_proprietario_id,login_operazione)
     (select fase.elem_prev_id, attr.attr_id , attr.tabella_id,attr.boolean,attr.percentuale,
            attr.testo,attr.numerico,
            dataInizioVal, attr.ente_proprietario_id, loginOperazione
      from siac_r_bil_elem_attr attr, fase_bil_t_prev_apertura_str_elem_prev_esiste fase
      where attr.elem_id=fase.elem_gest_id
      and   fase.ente_proprietario_id=enteProprietarioid
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.data_cancellazione is null
      and   fase.elem_gest_id is not null
      and   attr.data_cancellazione is null
      and   attr.validita_fine is null);

     -- siac_r_bil_elem_categoria
     strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_categoria].';
     insert into siac_r_bil_elem_categoria
     (elem_id,elem_cat_id,validita_inizio,ente_proprietario_id,login_operazione)
     (select fase.elem_prev_id, cat.elem_cat_id , dataInizioVal, cat.ente_proprietario_id, loginOperazione
      from siac_r_bil_elem_categoria cat, fase_bil_t_prev_apertura_str_elem_prev_esiste fase
      where cat.elem_id=fase.elem_gest_id
      and   fase.ente_proprietario_id=enteProprietarioid
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.data_cancellazione is null
      and   fase.elem_gest_id is not null
      and   cat.data_cancellazione is null
      and   cat.validita_fine is null);

     -- siac_r_bil_elem_class
     strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].';
	 insert into siac_r_bil_elem_class
     (elem_id,classif_id,validita_inizio,ente_proprietario_id,login_operazione)
     (select fase.elem_prev_id, class.classif_id , dataInizioVal, class.ente_proprietario_id, loginOperazione
      from siac_r_bil_elem_class class, fase_bil_t_prev_apertura_str_elem_prev_esiste fase
      where class.elem_id=fase.elem_gest_id
      and   fase.ente_proprietario_id=enteProprietarioid
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.data_cancellazione is null
      and   fase.elem_gest_id is not null
      and   class.data_cancellazione is null
      and   class.validita_fine is null);

      -- siac_r_vincolo_bil_elem
      strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_vincolo_bil_elem].';
 	  insert into siac_r_vincolo_bil_elem
      ( elem_id,vincolo_id, validita_inizio,ente_proprietario_id,login_operazione)
      (select fase.elem_prev_id, v.vincolo_id, dataInizioVal,v.ente_proprietario_id, loginOperazione
       from siac_r_vincolo_bil_elem v,fase_bil_t_prev_apertura_str_elem_prev_esiste fase
       where v.elem_id=fase.elem_gest_id
	   and   fase.ente_proprietario_id=enteProprietarioid
       and   fase.bil_id=bilancioId
       and   fase.fase_bil_elab_id=faseBilElabId
	   and   fase.data_cancellazione is null
       and   fase.elem_gest_id is not null
       and   v.data_cancellazione is null
       and   v.validita_fine is null
       );

       -- siac_r_bil_elem_atto_legge
       strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_atto_legge].';
       insert into siac_r_bil_elem_atto_legge
       ( elem_id,attolegge_id, descrizione, gerarchia,finanziamento_inizio,finanziamento_fine,
         validita_inizio,ente_proprietario_id,login_operazione
       )
       ( select fase.elem_prev_id,v.attolegge_id,v.descrizione, v.gerarchia,v.finanziamento_inizio,v.finanziamento_fine,
               dataInizioVal,v.ente_proprietario_id, loginOperazione
         from   siac_r_bil_elem_atto_legge v,fase_bil_t_prev_apertura_str_elem_prev_esiste fase
         where v.elem_id=fase.elem_gest_id
	     and   fase.ente_proprietario_id=enteProprietarioid
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
  	     and   fase.data_cancellazione is null
         and   fase.elem_gest_id is not null
         and   v.data_cancellazione is null
         and   v.validita_fine is null
       );

       -- siac_r_bil_elem_rel_tempo
       strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_rel_tempo].';
       insert into siac_r_bil_elem_rel_tempo
       (elem_id, elem_id_old, validita_inizio, ente_proprietario_id,login_operazione)
       ( select fase.elem_prev_id,v.elem_id_old,
               dataInizioVal,v.ente_proprietario_id, loginOperazione
         from   siac_r_bil_elem_rel_tempo v,fase_bil_t_prev_apertura_str_elem_prev_esiste fase
         where v.elem_id=fase.elem_gest_id
	     and   fase.ente_proprietario_id=enteProprietarioid
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
  	     and   fase.data_cancellazione is null
         and   fase.elem_gest_id is not null
         and   v.data_cancellazione is null
         and   v.validita_fine is null
       );

       codResult:=null;
       strMessaggio:='Fine inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente.';
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

       -- verifica dati inseriti
       codResult:=null;
       strMessaggio:='Inizio verifica inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente.';
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

       codResult:=null;
       strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_stato].Verifica esistenza relazione stati.';
       select 1 into codResult
       from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
       where fase.ente_proprietario_id=enteProprietarioId
       and   fase.bil_id=bilancioId
       and   fase.fase_bil_elab_id=faseBilElabId
       and   fase.elem_gest_id is not null
       and   fase.data_cancellazione is null
       and   not exists (select 1 from siac_r_bil_elem_stato stato
                 		 where stato.elem_id=fase.elem_prev_id
                         and   stato.data_cancellazione is null
                         and   stato.validita_fine is null
                         order by stato.elem_id
                         limit 1)
       order by fase.fase_bil_prev_str_esiste_id
       limit 1;

       if codResult is not null then
    	raise exception ' Elementi di bilancio assenti di relazione.';
       end if;

	  codResult:=null;
      strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_attr].Verifica esistenza attributi.';
      select 1 into codResult
      from  fase_bil_t_prev_apertura_str_elem_prev_esiste fase
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_gest_id is not null
      and   fase.data_cancellazione is null
      and   not exists (select 1 from siac_r_bil_elem_attr attr
     		 		    where attr.elem_id=fase.elem_prev_id
                        and   attr.data_cancellazione is null
                        and   attr.validita_fine is null
                        order by attr.elem_id
                        limit 1)
	  order by fase.fase_bil_prev_str_esiste_id
      limit 1;

      if codResult is not null then
    	raise exception ' Elementi di bilancio assenti di relazione.';
      end if;

	  codResult:=null;
      strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni classificatori.';
      select 1 into codResult
      from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_gest_id is not null
      and   fase.data_cancellazione is null
      and   not exists ( select 1 from siac_r_bil_elem_class class
      				     where class.elem_id=fase.elem_prev_id
                         and   class.data_cancellazione is null
                         and   class.validita_fine is null
                         order by class.elem_id
                         limit 1)
	  order by fase.fase_bil_prev_str_esiste_id
      limit 1;


      if codResult is not null then
    	raise exception ' Elementi di bilancio assenti di relazione.';
      end if;



      codResult:=null;
      strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_categoria].Verifica esistenza relazioni categoria.';
      select distinct 1 into codResult
      from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_gest_id is not null
      and   fase.data_cancellazione is null
      and   not exists ( select 1 from siac_r_bil_elem_categoria class
                         where class.elem_id=fase.elem_prev_id
                         and   class.data_cancellazione is null
                         and   class.validita_fine is null);


      if codResult is not null then
    	raise exception ' Elementi di bilancio assenti di relazione.';
      end if;

	  -- verifica se esistono elementi senza classificatori obbligatori (**)
      -- controlli sui classificatori obbligatori
      -- CL_CDC, CL_CDR
      codResult:=null;
      strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni struttura amministrativa.';
      select 1 into codResult
      from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.elem_gest_id is not null
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.data_cancellazione is null
      and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
                       where class.elem_id=fase.elem_prev_id
                       and   c.classif_id=class.classif_id
                       and   c.classif_tipo_id in (cdcTipoId, cdrTipoId)
                       and   class.data_cancellazione is null
                       and   class.validita_fine is null
                       and   c.data_cancellazione is null
                       and   c.validita_fine is null
                       order by class.elem_id
                       limit 1)
	  order by fase.fase_bil_prev_str_esiste_id
      limit 1;

      if codResult is not null then
    	raise exception ' Elementi di bilancio assenti di relazione.';
      end if;


      -- CL_PDC_FIN_QUINTO, CL_PDC_FIN_QUARTO
      codResult:=null;
	  strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni '||CL_PDC_FIN_QUARTO||' '||CL_PDC_FIN_QUINTO||'.';

      -- Il classificatore deve essere obbligatoriamente presente solo se capitolo gestione STD
	  select 1 into codResult
      from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
      , siac_r_bil_elem_categoria rcat
	  , siac_d_bil_elem_categoria cat
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_gest_id is not null
      and   fase.data_cancellazione is null
      and   rcat.elem_id=fase.elem_prev_id
      and   rcat.data_cancellazione is null
      and   rcat.validita_fine is null
      and   rcat.elem_cat_id=cat.elem_cat_id
      and   cat.elem_cat_code = CATEGORIA_STD
      and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
                       where class.elem_id=fase.elem_prev_id
                       and   c.classif_id=class.classif_id
                       and   c.classif_tipo_id in (pdcFinIVId, pdcFinVId)
                       and   class.data_cancellazione is null
                       and   class.validita_fine is null
                       and   c.data_cancellazione is null
                       and   c.validita_fine is null
                       order by class.elem_id
                       limit 1)
	  order by fase.fase_bil_prev_str_esiste_id
      limit 1;
      if codResult is not null then
    	raise exception ' Elementi di bilancio assenti di relazione.';
      end if;

	  codResult:=null;
      strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_vincolo_bil_elem].Verifica esistenza relazioni vincoli.';
      select 1 into codResult
      from fase_bil_t_prev_apertura_str_elem_prev_esiste fase,
           siac_r_vincolo_bil_elem v
      where fase.ente_proprietario_id=enteProprietarioId
      and   v.elem_id=fase.elem_gest_id
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_gest_id is not null
      and   fase.data_cancellazione is null
      and   v.data_cancellazione is null
      and   v.validita_fine is null
      and   not exists ( select 1 from siac_r_vincolo_bil_elem class
                         where class.elem_id=fase.elem_prev_id
                         and   class.data_cancellazione is null
                         and   class.validita_fine is null
                         order by class.elem_id
                         limit 1
                       )
	  order by fase.fase_bil_prev_str_esiste_id
      limit 1;


      if codResult is not null then
    	raise exception ' Elementi di bilancio assenti di relazione.';
      end if;

	  codResult:=null;
      strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_atto_legge].Verifica esistenza relazioni atti di legge.';
      select 1 into codResult
      from fase_bil_t_prev_apertura_str_elem_prev_esiste fase,
           siac_r_bil_elem_atto_legge v
      where fase.ente_proprietario_id=enteProprietarioId
      and   v.elem_id=fase.elem_gest_id
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_gest_id is not null
      and   fase.data_cancellazione is null
      and   v.data_cancellazione is null
      and   v.validita_fine is null
      and   not exists ( select 1 from siac_r_bil_elem_atto_legge class
                         where class.elem_id=fase.elem_prev_id
                         and   class.data_cancellazione is null
                         and   class.validita_fine is null
                         order by class.elem_id
                         limit 1)
	  order by fase.fase_bil_prev_str_esiste_id
      limit 1;


      if codResult is not null then
    	raise exception ' Elementi di bilancio assenti di relazione.';
      end if;


	  codResult:=null;
      strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_rel_tempo].Verifica esistenza relazioni.';
      select 1 into codResult
      from fase_bil_t_prev_apertura_str_elem_prev_esiste fase,
           siac_r_bil_elem_rel_tempo v
      where fase.ente_proprietario_id=enteProprietarioId
      and   v.elem_id=fase.elem_gest_id
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_gest_id is not null
      and   fase.data_cancellazione is null
      and   v.data_cancellazione is null
      and   v.validita_fine is null
      and   not exists ( select 1 from siac_r_bil_elem_rel_tempo class
                         where class.elem_id=fase.elem_prev_id
                         and   class.data_cancellazione is null
                         and   class.validita_fine is null
                         order by class.elem_id
                         limit 1)
	  order by fase.fase_bil_prev_str_esiste_id
      limit 1;


      if codResult is not null then
    	raise exception ' Elementi di bilancio assenti di relazione.';
      end if;


	  if euElemTipo=TIPO_ELEM_EU then

		-- Classificatore necessario solo per capitolo di categoria STD

		-- CL_PROGRAMMA
        codResult:=null;
        strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni '||CL_PROGRAMMA||'.';
        select 1 into codResult
	    from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_r_bil_elem_categoria rcat, siac_d_bil_elem_categoria cat
    	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
    	and   fase.elem_gest_id is not null
	    and   fase.data_cancellazione is null
        and   rcat.elem_id=fase.elem_prev_id
        and   rcat.data_cancellazione is null
        and   rcat.validita_fine is null
        and   rcat.elem_cat_id=cat.elem_cat_id
        and   cat.elem_cat_code = CATEGORIA_STD
    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	               where class.elem_id=fase.elem_prev_id
            	           and   c.classif_id=class.classif_id
                	       and   c.classif_tipo_id=programmaTipoId
                    	   and   class.data_cancellazione is null
	                       and   class.validita_fine is null
    	                   and   c.data_cancellazione is null
        	               and   c.validita_fine is null
                           limit 1)
	    limit 1;

	    if codResult is not null then
    		raise exception ' Elementi di bilancio assenti di relazione.';
	    end if;

		-- Classificatore necessario solo per capitolo di categoria STD
        -- CL_MACROAGGREGATO
        codResult:=null;
	    strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni '||CL_MACROAGGREGATO||'.';
        select 1 into codResult
	    from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
        , siac_r_bil_elem_categoria rcat
        , siac_d_bil_elem_categoria cat
    	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
    	and   fase.elem_gest_id is not null
	    and   fase.data_cancellazione is null
        and   rcat.elem_id=fase.elem_prev_id
        and   rcat.data_cancellazione is null
        and   rcat.validita_fine is null
        and   rcat.elem_cat_id=cat.elem_cat_id
        and   cat.elem_cat_code = CATEGORIA_STD
    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	               where class.elem_id=fase.elem_prev_id
                	       and   c.classif_tipo_id=macroAggrTipoId
                    	   and   class.data_cancellazione is null
	                       and   class.validita_fine is null
    	                   and   c.data_cancellazione is null
        	               and   c.validita_fine is null
                           order by class.elem_id
                           limit 1)
		order by fase.fase_bil_prev_str_esiste_id
	    limit 1;
	    if codResult is not null then
    		raise exception ' Elementi di bilancio assenti di relazione.';
	    end if;


  	    -- CL_COFOG
        codResult:=null;
        strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni '||CL_COFOG||'.';
        select 1 into codResult
	    from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
    	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
    	and   fase.elem_gest_id is not null
	    and   fase.data_cancellazione is null
        -- Classificatore definito in gestione deve essere stato ribaltato su previsione
        and   exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	           where class.elem_id=fase.elem_gest_id
                       and   c.classif_id=class.classif_id
               	       and   c.classif_tipo_id=cofogTipoId
                  	   and   class.data_cancellazione is null
	                   and   class.validita_fine is null
    	               and   c.data_cancellazione is null
        	           and   c.validita_fine is null
                       order by class.elem_id
                       limit 1)
    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	               where class.elem_id=fase.elem_prev_id
            	           and   c.classif_id=class.classif_id
                	       and   c.classif_tipo_id=cofogTipoId
                    	   and   class.data_cancellazione is null
	                       and   class.validita_fine is null
    	                   and   c.data_cancellazione is null
        	               and   c.validita_fine is null
                           order by class.elem_id
                           limit 1)
		order by fase.fase_bil_prev_str_esiste_id
	    limit 1;
	    if codResult is not null then
    		raise exception ' Elementi di bilancio assenti di relazione.';
	    end if;

 	    -- CL_RICORRENTE_SPESA
        codResult:=null;
        strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni '||CL_RICORRENTE_SPESA||'.';
        select  1 into codResult
	    from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
    	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
    	and   fase.elem_gest_id is not null
	    and   fase.data_cancellazione is null
        -- Classificatore definito in gestione deve essere stato ribaltato su previsione
        and   exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	           where class.elem_id=fase.elem_gest_id
                       and   c.classif_id=class.classif_id
               	       and   c.classif_tipo_id=ricorrenteSpesaId
                  	   and   class.data_cancellazione is null
	                   and   class.validita_fine is null
    	               and   c.data_cancellazione is null
        	           and   c.validita_fine is null
                       order by class.elem_id
                       limit 1)
    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	               where class.elem_id=fase.elem_prev_id
            	           and   c.classif_id=class.classif_id
                	       and   c.classif_tipo_id=ricorrenteSpesaId
                    	   and   class.data_cancellazione is null
	                       and   class.validita_fine is null
    	                   and   c.data_cancellazione is null
        	               and   c.validita_fine is null
                           order by class.elem_id
                           limit 1)
		order by fase.fase_bil_prev_str_esiste_id
	    limit 1;

	    if codResult is not null then
    		raise exception ' Elementi di bilancio assenti di relazione.';
	    end if;

        -- CL_SIOPE_SPESA_TERZO
        codResult:=null;
        strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni '||CL_SIOPE_SPESA_TERZO||'.';
        select  1 into codResult
	    from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
    	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
    	and   fase.elem_gest_id is not null
	    and   fase.data_cancellazione is null
        and exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	         where class.elem_id=fase.elem_gest_id
                     and   c.classif_id=class.classif_id
                     and   c.classif_tipo_id=siopeSpesaTipoId
                     and   class.data_cancellazione is null
	                 and   class.validita_fine is null
    	             and   c.data_cancellazione is null
        	         and   c.validita_fine is null
                     order by class.elem_id
                     limit 1)
    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	               where class.elem_id=fase.elem_prev_id
            	           and   c.classif_id=class.classif_id
                	       and   c.classif_tipo_id=siopeSpesaTipoId
                    	   and   class.data_cancellazione is null
	                       and   class.validita_fine is null
    	                   and   c.data_cancellazione is null
        	               and   c.validita_fine is null
                           order by class.elem_id
                           limit 1)
		order by fase.fase_bil_prev_str_esiste_id
	    limit 1;
	    if codResult is not null then
    		raise exception ' Elementi di bilancio assenti di relazione.';
	    end if;

 	    -- CL_TRANSAZIONE_UE_SPESA
        codResult:=null;
        strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni '||CL_TRANSAZIONE_UE_SPESA||'.';
        select  1 into codResult
	    from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
    	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
    	and   fase.elem_gest_id is not null
	    and   fase.data_cancellazione is null
        -- Classificatore definito in gestione deve essere stato ribaltato su previsione
        and   exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	           where class.elem_id=fase.elem_gest_id
                       and   c.classif_id=class.classif_id
               	       and   c.classif_tipo_id=transazioneUeSpesaId
                  	   and   class.data_cancellazione is null
	                   and   class.validita_fine is null
    	               and   c.data_cancellazione is null
        	           and   c.validita_fine is null
                       order by class.elem_id
                       limit 1)
    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	               where class.elem_id=fase.elem_prev_id
            	           and   c.classif_id=class.classif_id
                	       and   c.classif_tipo_id=transazioneUeSpesaId
                    	   and   class.data_cancellazione is null
	                       and   class.validita_fine is null
    	                   and   c.data_cancellazione is null
        	               and   c.validita_fine is null
                           order by class.elem_id
                           limit 1)
		order by fase.fase_bil_prev_str_esiste_id
	    limit 1;
	    if codResult is not null then
    		raise exception ' Elementi di bilancio assenti di relazione.';
	    end if;
     else
        -- CL_CATEGORIA
        codResult:=null;
        strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni '||CL_CATEGORIA||'.';

        -- Classificatore deve essere obbligatoriamente presente solo se capitolo STD
        select distinct 1 into codResult
	    from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_r_bil_elem_categoria rcat, siac_d_bil_elem_categoria cat
    	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
    	and   fase.elem_gest_id is not null
	    and   fase.data_cancellazione is null
        and   rcat.elem_id=fase.elem_prev_id
        and   rcat.data_cancellazione is null
        and   rcat.validita_fine is null
        and   rcat.elem_cat_id=cat.elem_cat_id
        and   cat.elem_cat_code = CATEGORIA_STD
    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	               where class.elem_id=fase.elem_prev_id
            	           and   c.classif_id=class.classif_id
                	       and   c.classif_tipo_id=categoriaTipoId
                    	   and   class.data_cancellazione is null
	                       and   class.validita_fine is null
    	                   and   c.data_cancellazione is null
        	               and   c.validita_fine is null
                           limit 1);
	    if codResult is not null then
    		raise exception ' Elementi di bilancio assenti di relazione.';
	    end if;

     	-- CL_RICORRENTE_ENTRATA
        codResult:=null;
        strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni '||CL_RICORRENTE_ENTRATA||'.';
        select  1 into codResult
	    from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
    	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
    	and   fase.elem_gest_id is not null
	    and   fase.data_cancellazione is null
        -- Classificatore definito in previsione deve essere stato ribaltato su gestione
        and   exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	           where class.elem_id=fase.elem_gest_id
                       and   c.classif_id=class.classif_id
               	       and   c.classif_tipo_id=ricorrenteEntrataId
                  	   and   class.data_cancellazione is null
	                   and   class.validita_fine is null
    	               and   c.data_cancellazione is null
        	           and   c.validita_fine is null
                       order by class.elem_id
                       limit 1)
    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	               where class.elem_id=fase.elem_prev_id
            	           and   c.classif_id=class.classif_id
                	       and   c.classif_tipo_id=ricorrenteEntrataId
                    	   and   class.data_cancellazione is null
	                       and   class.validita_fine is null
    	                   and   c.data_cancellazione is null
        	               and   c.validita_fine is null
                           order by class.elem_id
                           limit 1)
		order by fase.fase_bil_prev_str_esiste_id
	    limit 1;
	    if codResult is not null then
    		raise exception ' Elementi di bilancio assenti di relazione.';
	    end if;

	    -- CL_SIOPE_ENTRATA_TERZO
        codResult:=null;
        strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni '||CL_SIOPE_ENTRATA_TERZO||'.';
        select  1 into codResult
	    from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
    	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
    	and   fase.elem_gest_id is not null
	    and   fase.data_cancellazione is null
        and   exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	           where class.elem_id=fase.elem_gest_id
                       and   c.classif_id=class.classif_id
               	       and   c.classif_tipo_id=siopeEntrataTipoId
                  	   and   class.data_cancellazione is null
	                   and   class.validita_fine is null
    	               and   c.data_cancellazione is null
        	           and   c.validita_fine is null
                       order by class.elem_id
                       limit 1)
    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	               where class.elem_id=fase.elem_prev_id
            	           and   c.classif_id=class.classif_id
                	       and   c.classif_tipo_id=siopeEntrataTipoId
                    	   and   class.data_cancellazione is null
	                       and   class.validita_fine is null
    	                   and   c.data_cancellazione is null
        	               and   c.validita_fine is null
                           order by class.elem_id
	                       limit 1)
		order by fase.fase_bil_prev_str_esiste_id
	    limit 1;
	    if codResult is not null then
    		raise exception ' Elementi di bilancio assenti di relazione.';
	    end if;

	    -- CL_TRANSAZIONE_UE_ENTRATA
        codResult:=null;
        strMessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni '||CL_TRANSAZIONE_UE_ENTRATA||'.';
        select 1 into codResult
	    from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
    	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.elem_gest_id is not null
	    and   fase.data_cancellazione is null
        -- Classificatore definito in gestione deve essere stato ribaltato su previsione
        and   exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	           where class.elem_id=fase.elem_gest_id
                       and   c.classif_id=class.classif_id
               	       and   c.classif_tipo_id=transazioneUeEntrataId
                  	   and   class.data_cancellazione is null
	                   and   class.validita_fine is null
    	               and   c.data_cancellazione is null
        	           and   c.validita_fine is null
                       order by class.elem_id
                       limit 1)
    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	               where class.elem_id=fase.elem_prev_id
            	           and   c.classif_id=class.classif_id
                	       and   c.classif_tipo_id=transazioneUeEntrataId
                    	   and   class.data_cancellazione is null
	                       and   class.validita_fine is null
    	                   and   c.data_cancellazione is null
        	               and   c.validita_fine is null
                           order by class.elem_id
	                       limit 1)
		order by fase.fase_bil_prev_str_esiste_id
	    limit 1;
	    if codResult is not null then
    		raise exception ' Elementi di bilancio assenti di relazione.';
	    end if;
     end if;

     codResult:=null;
     strMessaggio:='Fine verifica inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente.';
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

   end if;

 end if;

 strMessaggio:='Aggiornamento fase elaborazione [fase_bil_t_elaborazione].';
 update fase_bil_t_elaborazione set
      fase_bil_elab_esito='IN2',
      fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_PREV_DA_GEST||' IN CORSO : AGGIORNAMENTO STRUTTURE COMPLETATO.'
 where fase_bil_elab_id=faseBilElabId;

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


 faseBilElabIdRet:= faseBilElabId;
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