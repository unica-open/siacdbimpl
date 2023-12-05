/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- FUNCTION: siac.fnc_fasi_bil_gest_reimputa_popola(integer, integer, integer, character varying, timestamp without time zone, character varying, character varying)

-- DROP FUNCTION siac.fnc_fasi_bil_gest_reimputa_popola(integer, integer, integer, character varying, timestamp without time zone, character varying, character varying);

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_reimputa_popola(
	p_fasebilelabid integer,
	p_enteproprietarioid integer,
	p_annobilancio integer,
	p_loginoperazione character varying,
	p_dataelaborazione timestamp without time zone,
	p_movgest_tipo_code character varying,
	motivo character varying,
	OUT outfasebilelabretid integer,
	OUT codicerisultato integer,
	OUT messaggiorisultato character varying)
    RETURNS record
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
	codResult          integer;
    v_faseBilElabId    integer;
    v_bil_attr_id      integer;
    v_attr_code        varchar;
-- SIAC-6997 ---------------- INIZIO --------------------
    v_annobilancio     integer;
-- SIAC-6997 ---------------- FINE --------------------
    MOVGEST_TS_T_TIPO  CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO  CONSTANT varchar:='S';
    CAP_UG_TIPO        CONSTANT varchar:='CAP-UG';
    CAP_EG_TIPO        CONSTANT varchar:='CAP-EG';
    APE_GEST_REIMP     CONSTANT varchar:='APE_GEST_REIMP';

    MOVGEST_IMP_TIPO    CONSTANT  varchar:='I';
    MACROAGGREGATO_TIPO CONSTANT varchar:='MACROAGGREGATO';
    TITOLO_SPESA_TIPO   CONSTANT varchar:='TITOLO_SPESA';

    faseRec record;
    faseElabRec record;
    recmovgest  record;

    attoAmmId integer:=null;
BEGIN

    codiceRisultato:=null;
    messaggioRisultato:=null;
    strMessaggioFinale:='Inizio.';

    strMessaggio := 'prima del loop';

-- SIAC-6997 ---------------- INIZIO --------------------
    v_annobilancio := p_annoBilancio;
    if motivo = 'REIMP' then
       v_annobilancio := p_annoBilancio - 1;
    end if;
-- SIAC-6997 ----------------  FINE --------------------

    for recmovgest in (select
					   --siac_t_bil_elem
					   bilel.bil_id
					  ,bilel.elem_id
					  ,bilel.elem_code
					  ,bilel.elem_code2
					  ,bilel.elem_code3
					  -- siac_t_movgest
					  ,movgest.movgest_id
					  ,movgest.movgest_anno
					  ,movgest.movgest_numero
					  ,movgest.movgest_desc
					  ,movgest.movgest_tipo_id
					  ,movgest.parere_finanziario
					  ,movgest.parere_finanziario_data_modifica
					  ,movgest.parere_finanziario_login_operazione
					  -- siac_t_movgest_ts
					  ,tsmov.movgest_ts_id --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_code --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_desc
					  ,tsmov.movgest_ts_tipo_id
					  ,tsmov.movgest_ts_id_padre
					  ,tsmov.ordine
					  ,tsmov.livello
					  ,tsmov.login_operazione
					  ,tsmov.movgest_ts_scadenza_data
					  ,tsmov.siope_tipo_debito_id
					  ,tsmov.siope_assenza_motivazione_id
					  --siac_t_movgest_ts_dett
					  ,tipots.movgest_ts_tipo_code tipo
					  ,tipodet.movgest_ts_det_tipo_code
                      ,modificaTipo.mod_tipo_code
					  ,dettsIniz.movgest_ts_det_tipo_id
					  ,dettsIniz.movgest_ts_det_importo impoInizImpegno
					  ,detts.movgest_ts_det_importo     impoAttImpegno
					  ,dettsmod.mtdm_reimputazione_anno::integer
					  ,dettsmod.mtdm_reimputazione_flag
					  ,dbileltip.elem_tipo_code
                      ,rstato.movgest_stato_id -- 07.02.2018 Sofia siac-5368
					  ,sum(dettsmod.movgest_ts_det_importo)  importoModifica
				from siac_t_modifica modifica,
                     siac_d_modifica_tipo modificaTipo,
					 siac_t_bil bil ,
					 siac_t_bil_elem bilel,
					 siac_r_movgest_bil_elem rbilel,
					 siac_t_movgest movgest,
					 siac_t_movgest_ts_det detts,
					 siac_t_movgest_ts_det_mod  dettsmod,
					 siac_r_modifica_stato  rmodstato,
					 siac_d_modifica_stato modstato,
					 siac_d_movgest_ts_det_tipo tipodet,
					 siac_t_movgest_ts tsmov,
					 siac_d_movgest_tipo tipomov,
					 siac_d_movgest_ts_tipo tipots,
					 siac_t_movgest_ts_det dettsIniz,
					 siac_d_movgest_ts_det_tipo tipodetIniz,
					 siac_t_periodo per,
					 siac_d_bil_elem_tipo dbileltip,
                     siac_r_movgest_ts_stato rstato -- 07.02.2018 Sofia siac-5368
				where bil.ente_proprietario_id=p_enteProprietarioId
				and   bilel.elem_tipo_id = dbileltip.elem_tipo_id
				-- da siac_t_bil_elem a siac_t_movgest
				and   bilel.elem_id   = rbilel.elem_id
				and   rbilel.movgest_id = movgest.movgest_id
				and   per.periodo_id=bil.periodo_id
-- SIAC-6997 ---------------- INIZIO --------------------
--				and   per.anno::integer=p_annoBilancio-1
                and   per.anno::integer=v_annoBilancio
-- SIAC-6997 ---------------- INIZIO --------------------
				and   modifica.ente_proprietario_id=bil.ente_proprietario_id
				and   rmodstato.mod_id=modifica.mod_id
				and   dettsmod.mod_stato_r_id=rmodstato.mod_stato_r_id
				and   modstato.mod_stato_id=rmodstato.mod_stato_id
				and   modstato.mod_stato_code='V'
                and   modifica.mod_tipo_id = modificaTipo.mod_tipo_id
-- SIAC-6997 ----------------  INIZIO --------------------
                and   modifica.elab_ror_reanno = FALSE
                and   modificaTipo.mod_tipo_code = motivo
-- SIAC-6997 ----------------  FINE --------------------
                and   dettsmod.movgest_ts_det_importo<0
				and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
				and   detts.movgest_ts_det_id=dettsmod.movgest_ts_det_id
				and   tsmov.movgest_ts_id=detts.movgest_ts_id
				and   dettsIniz.movgest_ts_id=tsmov.movgest_ts_id
				and   tipodetIniz.movgest_ts_det_tipo_id=dettsIniz.movgest_ts_det_tipo_id
				and   tipodetIniz.movgest_ts_det_tipo_code=p_movgest_tipo_code--'I'
				and   tipots.movgest_ts_tipo_id=tsmov.movgest_ts_tipo_id
				and   movgest.movgest_id=tsmov.movgest_id
				and   movgest.bil_id=bil.bil_id
				and   tipomov.movgest_tipo_id=movgest.movgest_tipo_id
				and   tipomov.movgest_tipo_code=p_movgest_tipo_code--'I' -- 'A'
				and   dettsmod.mtdm_reimputazione_anno is not null
				and   dettsmod.mtdm_reimputazione_flag is true
                and   rstato.movgest_ts_id=tsmov.movgest_ts_id  -- 07.02.2018 Sofia siac-5368
				and   bilel.validita_fine is null
				and   rbilel.validita_fine is null
				and   rmodstato.validita_fine is null
				and   tsmov.validita_fine is null
				and   dettsIniz.validita_fine is null
				and   bil.validita_fine is null
				and   per.validita_fine is null
				and   modifica.validita_fine is null
				and   bilel.data_cancellazione is null
				and   rbilel.data_cancellazione is null
				and   rmodstato.data_cancellazione is null
				and   tsmov.data_cancellazione is null
				and   dettsIniz.data_cancellazione is null
				and   bil.data_cancellazione is null
				and   per.data_cancellazione is null
				and   modifica.data_cancellazione is null
                and   rstato.data_cancellazione is null -- 07.02.2018 Sofia siac-5368
                and   rstato.validita_fine is null -- 07.02.2018 Sofia siac-5368
               	group by

				       bilel.bil_id
					  ,bilel.elem_id
					  ,bilel.elem_code
					  ,bilel.elem_code2
					  ,bilel.elem_code3
					  -- siac_t_movgest
					  ,movgest.movgest_id
					  ,movgest.movgest_anno
					  ,movgest.movgest_numero
					  ,movgest.movgest_desc
					  ,movgest.movgest_tipo_id
					  ,movgest.parere_finanziario
					  ,movgest.parere_finanziario_data_modifica
					  ,movgest.parere_finanziario_login_operazione
					  -- siac_t_movgest_ts
					  ,tsmov.movgest_ts_id --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_code --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_desc
					  ,tsmov.movgest_ts_tipo_id
					  ,tsmov.movgest_ts_id_padre
					  ,tsmov.ordine
					  ,tsmov.livello
					  ,tsmov.login_operazione
					  ,tsmov.movgest_ts_scadenza_data
					  ,tsmov.siope_tipo_debito_id
					  ,tsmov.siope_assenza_motivazione_id
					  --siac_t_movgest_ts_dett
					  ,tipots.movgest_ts_tipo_code
					  ,tipodet.movgest_ts_det_tipo_code
                      ,modificaTipo.mod_tipo_code
					  ,dettsIniz.movgest_ts_det_tipo_id
					  ,dettsIniz.movgest_ts_det_importo
					  ,detts.movgest_ts_det_importo
					  --,dettsmod.movgest_ts_det_importo  importoModifica
					  ,dettsmod.mtdm_reimputazione_anno::integer
					  ,dettsmod.mtdm_reimputazione_flag
					  ,dbileltip.elem_tipo_code
                      ,rstato.movgest_stato_id -- 07.02.2018 Sofia siac-5368
				order by
				 		 dettsmod.mtdm_reimputazione_anno::integer
				 		,modificaTipo.mod_tipo_code
				 		--,tsmov.movgest_ts_code::integer    ?? serve????
						,movgest.movgest_anno::integer
                        ,movgest.movgest_numero::integer
                        ,tipo desc --tipots.movgest_ts_tipo_code desc,



    --Raggruppate per anno reimputazione, motivo anno/numero impegno/sub,


    ) loop

		-- 07.02.2018 Sofia siac-5368
       	strMessaggio := 'Lettura attoamm_id prima di inserimento in fase_bil_t_reimputazione per movimento movgest_ts_id='||recmovgest.movgest_ts_id::varchar||'.';
        		raise notice 'strMessaggio=%',strMessaggio;

        attoAmmId:=null;
        select r.attoamm_id into attoAmmId
        from siac_r_movgest_ts_atto_amm r
        where r.movgest_ts_id=recmovgest.movgest_ts_id
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

    	strMessaggio := 'Inserimento in fase_bil_t_reimputazione per movimento movgest_ts_id='||recmovgest.movgest_ts_id::varchar||'.';
		raise notice 'strMessaggio=%',strMessaggio;
        codResult:=null; -- 31.01.2018 Sofia siac-5368
        insert into  fase_bil_t_reimputazione (
           --siac_t_bil_elem
           faseBilElabId
          ,bil_id
          ,elemId_old
          ,elem_code
          ,elem_code2
          ,elem_code3
          ,elem_tipo_code
          -- siac_t_movgest
          ,movgest_id
          ,movgest_anno
          ,movgest_numero
          ,movgest_desc
          ,movgest_tipo_id
          ,parere_finanziario
          ,parere_finanziario_data_modifica
          ,parere_finanziario_login_operazione
          -- siac_t_movgest_ts
          ,movgest_ts_id --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
          ,movgest_ts_code --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
          ,movgest_ts_desc
          ,movgest_ts_tipo_id
          ,movgest_ts_id_padre
          ,ordine
          ,livello
          ,movgest_ts_scadenza_data
          ,siope_tipo_debito_id
		  ,siope_assenza_motivazione_id
          --siac_t_movgest_ts_dett
          ,tipo
          ,movgest_ts_det_tipo_code
          ,mod_tipo_code
          ,movgest_ts_det_tipo_id
          ,impoInizImpegno
          ,impoAttImpegno
          ,importoModifica
          ,mtdm_reimputazione_anno
          ,mtdm_reimputazione_flag
          , attoamm_id        -- 07.02.2018 Sofia siac-5368
          , movgest_stato_id  -- 07.02.2018 Sofia siac-5368
          ,login_operazione
          ,ente_proprietario_id
          ,data_creazione
          ,fl_elab
		  ,scarto_code
		  ,scarto_desc
      ) values (
      --siac_t_bil_elem
          --siac_t_bil_elem
           p_faseBilElabId
          ,recmovgest.bil_id
          ,recmovgest.elem_id
          ,recmovgest.elem_code
          ,recmovgest.elem_code2
          ,recmovgest.elem_code3
		  ,recmovgest.elem_tipo_code
          -- siac_t_movgest
          ,recmovgest.movgest_id
          ,recmovgest.movgest_anno
          ,recmovgest.movgest_numero
          ,recmovgest.movgest_desc
          ,recmovgest.movgest_tipo_id
          ,recmovgest.parere_finanziario
          ,recmovgest.parere_finanziario_data_modifica
          ,recmovgest.parere_finanziario_login_operazione
          -- siac_t_movgest_ts
          ,recmovgest.movgest_ts_id
          ,recmovgest.movgest_ts_code --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
          ,recmovgest.movgest_ts_desc
          ,recmovgest.movgest_ts_tipo_id
          ,recmovgest.movgest_ts_id_padre
          ,recmovgest.ordine
          ,recmovgest.livello
          ,recmovgest.movgest_ts_scadenza_data
          ,recmovgest.siope_tipo_debito_id
		  ,recmovgest.siope_assenza_motivazione_id
          --siac_t_movgest_ts_dett
          ,recmovgest.tipo
          ,recmovgest.movgest_ts_det_tipo_code
          ,recmovgest.mod_tipo_code
          ,recmovgest.movgest_ts_det_tipo_id
          ,recmovgest.impoInizImpegno
          ,recmovgest.impoAttImpegno
          ,recmovgest.importoModifica
          ,recmovgest.mtdm_reimputazione_anno
          ,recmovgest.mtdm_reimputazione_flag
          , attoAmmId                    -- 07.02.2018 Sofia siac-5368
          , recmovgest.movgest_stato_id  -- 07.02.2018 Sofia siac-5368
          ,p_loginoperazione
          ,p_enteProprietarioId
          ,p_dataElaborazione
          ,'N'
		  ,null
		  ,null
  	)
    returning reimputazione_id into codResult; -- 31.01.2018 Sofia siac-5788

	raise notice 'dopo inserimento codResult=%',codResult;
    /* 31.01.2018 Sofia siac-5788 -
       inserimento in fase_bil_t_reimputazione_vincoli per traccia delle modifiche legata a vincoli
       con predisposizione dei dati utili per il successivo job di elaborazione dei vincoli riaccertati
    */
    if codResult is not null  and
       p_movgest_tipo_code=MOVGEST_IMP_TIPO then

        /* caso 1
   	       se il vincolo abbattuto era del tipo FPV -> creare analogo vincolo nel nuovo bilancio per la quote di vincolo
           abbattuta */
    	strMessaggio := 'Inserimento caso 1 in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='||recmovgest.movgest_ts_id::varchar||'.';
	    raise notice 'strMessaggio=%',strMessaggio;
        -- 23.03.2018 Sofia dopo elaborazione riacc_vincoli su CMTO
		-- per bugprod : aggiungere condizione su
        -- anno_reimputazione e tipo_modifica presi da recmovgest
        -- recmovgest.mtdm_reimputazione_anno
        -- recmovgest.mod_tipo_code
        -- si dovrebbe raggruppare e totalizzare ma su questa tabella nn si puo per il mod_id
        -- quindi bisogna poi modificare la logica nella creazione dei vincoli totalizzando
        -- per recmovgest.mtdm_reimputazione_anno
        -- recmovgest.mod_tipo_code ovvero per movimento reimputato
        -- controllare poi anche le altre casistiche
		-- 06.04.2018 Sofia JIRA SIAC-6054 - aggiunto filtri per tipo_modifica e anno_reimputazione
	    insert into   fase_bil_t_reimputazione_vincoli
		(
			reimputazione_id,
		    fasebilelabid,
		    bil_id,
		    mod_id,
            mod_tipo_code,      -- 06.04.2018 Sofia JIRA SIAC-6054
            reimputazione_anno, -- 06.04.2018 Sofia JIRA SIAC-6054
		    movgest_ts_r_id,
		    movgest_ts_b_id,
		    avav_id,
		    importo_vincolo,
		    avav_new_id,
		    importo_vincolo_new,
		    data_creazione,
		    login_operazione,
		    ente_proprietario_id
		)
		(select
		 codResult,
		 p_faseBilElabId,
		 bil.bil_id,
		 mod.mod_id,
         tipomod.mod_tipo_code,  -- 06.04.2018 Sofia JIRA SIAC-6054
         dettsmod.mtdm_reimputazione_anno::integer, -- 06.04.2018 Sofia JIRA SIAC-6054
		 rvinc.movgest_ts_r_id,
		 ts.movgest_ts_id, -- movgest_ts_b_id
		 av.avav_id,
		 rts.movgest_ts_importo,
		 avnew.avav_id,       -- avav_new_id
		 abs(rvinc.importo_delta), -- importo_vincolo_new
		 clock_timestamp(),
		 p_loginoperazione,
		 p_enteProprietarioId
		from siac_t_bil bil ,
		     siac_t_periodo per,
		     siac_t_movgest mov,siac_d_movgest_tipo tipo,
		     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
			 siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
			 siac_t_movgest_ts_det_mod  dettsmod,
			 siac_t_modifica mod,siac_d_modifica_tipo tipomod,
			 siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
			 siac_r_modifica_vincolo rvinc,
		     siac_r_movgest_ts rts,
		     siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo tipoav,
		     siac_t_avanzovincolo avnew
		where bil.ente_proprietario_id=p_enteProprietarioId
		and   per.periodo_id=bil.periodo_id
-- SIAC-6997 ---------------- INIZIO --------------------
--		and   per.anno::integer=p_annoBilancio-1
        and   per.anno::integer=v_annoBilancio
-- SIAC-6997 ---------------- INIZIO --------------------
		and   tipo.ente_proprietario_id=bil.ente_proprietario_id
		and   tipo.movgest_tipo_code=p_movgest_tipo_code
		and   mov.movgest_tipo_id=tipo.movgest_tipo_id
		and   mov.bil_id=bil.bil_id
		and   ts.movgest_id=mov.movgest_id
		and   ts.movgest_ts_id=recmovgest.movgest_ts_id        -- movgest_ts_id --> di impegno-sub appena gestito
		and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
		and   detts.movgest_ts_id=ts.movgest_ts_id
		and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
		and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
		and   dettsmod.movgest_ts_det_importo<0
		and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
		and   modstato.mod_stato_id=rmodstato.mod_stato_id
		and   modstato.mod_stato_code='V'
		and   mod.mod_id=rmodstato.mod_id
		and   tipomod.mod_tipo_id =  mod.mod_tipo_id
-- SIAC-6997 ----------------  INIZIO --------------------
        and   mod.elab_ror_reanno = FALSE
        and   tipomod.mod_tipo_code = motivo
-- SIAC-6997 ----------------  FINE --------------------        
        and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code  -- 06.04.2018 Sofia JIRA SIAC-6054 - filtro modifiche per mod_tipo
		and   rvinc.mod_id=mod.mod_id
		and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
		and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
        and   rts.movgest_ts_b_id=ts.movgest_ts_id             -- vincolo legato a impegno riaccertato
		and   av.avav_id=rts.avav_id
		and   tipoav.avav_tipo_id=av.avav_tipo_id
		and   tipoav.avav_tipo_code in ('FPVCC','FPVSC')
		and   avnew.avav_tipo_id=tipoav.avav_tipo_id
		and   extract('year' from avnew.validita_inizio::timestamp)::integer=p_annoBilancio
		and   dettsmod.mtdm_reimputazione_anno is not null
        and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno -- 06.04.2018 Sofia JIRA SIAC-6054 filtro modifiche per anno_reimputazione
		and   dettsmod.mtdm_reimputazione_flag is true
		and   rmodstato.validita_fine is null
		and   mov.data_cancellazione is null
		and   mov.validita_fine is null
		and   ts.data_cancellazione is null
		and   ts.validita_fine is null
		and   detts.data_cancellazione is null
		and   detts.validita_fine is null
		and   dettsmod.data_cancellazione is null
		and   dettsmod.validita_fine is null
		and   rmodstato.data_cancellazione is null
		and   rmodstato.validita_fine is null
		and   mod.data_cancellazione is null
		and   mod.validita_fine is null
		and   rvinc.data_cancellazione is null
		and   rvinc.validita_fine is null
		and   rts.data_cancellazione is null
		and   rts.validita_fine is null
	   );

    	strMessaggio := 'Inserimento caso 2 in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='||recmovgest.movgest_ts_id::varchar||'.';
	    raise notice 'strMessaggio=%',strMessaggio;

	  /* caso 2
		 se il vincolo abbattuto era del tipo Avanzo -> creare un vincolo nel nuovo bilancio di tipo FPV
		 per la quote di vincolo abbattuta con tipo spesa corrente o conto capitale in base al titolo di spesa dell'impegno
		 (vedi algoritmo a seguire) */
	  -- 06.04.2018 Sofia JIRA SIAC-6054 - aggiunto filtri per tipo_modifica e anno_reimputazione
	  insert into   fase_bil_t_reimputazione_vincoli
	  (
		reimputazione_id,
    	fasebilelabid,
	    bil_id,
    	mod_id,
        mod_tipo_code,      -- 06.04.2018 Sofia JIRA SIAC-6054
        reimputazione_anno, -- 06.04.2018 Sofia JIRA SIAC-6054
	    movgest_ts_r_id,
	    movgest_ts_b_id,
	    avav_id,
	    importo_vincolo,
	    avav_new_id,
	    importo_vincolo_new,
	    data_creazione,
	    login_operazione,
    	ente_proprietario_id
	   )
	   (
		with
		titoloNew as
	    (
    	  	select cTitolo.classif_code::integer titolo_uscita,
        	       ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                      then 'FPVSC'
                      when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                      then 'FPVCC'
                      else null end ) tipo_avanzo
	        from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
    	         siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
        	     siac_r_class_fam_tree rfam,
            	 siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
	             siac_t_bil bil, siac_t_periodo per
    	    where tipo.ente_proprietario_id=p_enteProprietarioId
	        and   tipo.elem_tipo_code=CAP_UG_TIPO
	        and   e.elem_tipo_id=tipo.elem_tipo_id
    	    and   bil.bil_id=e.bil_id
	        and   per.periodo_id=bil.periodo_id
	        and   per.anno::integer=p_annoBilancio
	        and   e.elem_code::integer=recmovgest.elem_code::integer
	        and   e.elem_code2::integer=recmovgest.elem_code2::integer
	        and   e.elem_code3=recmovgest.elem_code3
	        and   rc.elem_id=e.elem_id
	        and   cMacro.classif_id=rc.classif_id
	        and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
	        and   tipomacro.classif_tipo_code=MACROAGGREGATO_TIPO
	        and   rfam.classif_id=cMacro.classif_id
	        and   cTitolo.classif_id=rfam.classif_id_padre
	        and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
    	    and   tipoTitolo.classif_tipo_code=TITOLO_SPESA_TIPO
	        and   e.data_cancellazione is null
	        and   e.validita_fine is null
	        and   rc.data_cancellazione is null
	        and   rc.validita_fine is null
	        and   rfam.data_cancellazione is null
	        and   rfam.validita_fine is null
	   ),
	   avanzoTipo as
   	   (
		 select av.avav_id, avtipo.avav_tipo_code
		 from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo avtipo
		 where avtipo.ente_proprietario_id=p_enteProprietarioId
		 and   avtipo.avav_tipo_code in ('FPVSC','FPVCC')
		 and   av.avav_tipo_id=avtipo.avav_tipo_id
	     and   extract('year' from av.validita_inizio::timestamp)::integer=p_annoBilancio
	   ),
	   vincPrec as
	   (
		select
		 bil.bil_id,
		 mod.mod_id,
         tipomod.mod_tipo_code,  -- 06.04.2018 Sofia JIRA SIAC-6054
         dettsmod.mtdm_reimputazione_anno::integer, -- 06.04.2018 Sofia JIRA SIAC-6054
		 rvinc.movgest_ts_r_id,
		 ts.movgest_ts_id movgest_ts_b_id, -- movgest_ts_b_id
		 av.avav_id,
		 rts.movgest_ts_importo importo_vincolo,
		 abs(rvinc.importo_delta) importo_vincolo_new -- importo_vincolo_new
		from siac_t_bil bil ,
		     siac_t_periodo per,
		     siac_t_movgest mov,siac_d_movgest_tipo tipo,
		     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
			 siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
			 siac_t_movgest_ts_det_mod  dettsmod,
			 siac_t_modifica mod,siac_d_modifica_tipo tipomod,
			 siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
			 siac_r_modifica_vincolo rvinc,
		     siac_r_movgest_ts rts,
		     siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo tipoav
		where bil.ente_proprietario_id=p_enteProprietarioId
		and   per.periodo_id=bil.periodo_id
-- SIAC-6997 ---------------- INIZIO --------------------
--		and   per.anno::integer=p_annoBilancio-1
        and   per.anno::integer=v_annoBilancio
-- SIAC-6997 ---------------- INIZIO --------------------        
        and   tipo.ente_proprietario_id=bil.ente_proprietario_id
		and   tipo.movgest_tipo_code=p_movgest_tipo_code
		and   mov.movgest_tipo_id=tipo.movgest_tipo_id
		and   mov.bil_id=bil.bil_id
		and   ts.movgest_id=mov.movgest_id
		and   ts.movgest_ts_id=recmovgest.movgest_ts_id        -- movgest_ts_id --> di impegno-sub appena gestito
		and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
		and   detts.movgest_ts_id=ts.movgest_ts_id
		and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
		and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
		and   dettsmod.movgest_ts_det_importo<0
		and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
		and   modstato.mod_stato_id=rmodstato.mod_stato_id
		and   modstato.mod_stato_code='V'
		and   mod.mod_id=rmodstato.mod_id
		and   tipomod.mod_tipo_id =  mod.mod_tipo_id
-- SIAC-6997 ----------------  INIZIO --------------------
        and   mod.elab_ror_reanno = FALSE
        and   tipomod.mod_tipo_code = motivo
-- SIAC-6997 ----------------  FINE --------------------
        and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code  -- 06.04.2018 Sofia JIRA SIAC-6054 - filtro modifiche per mod_tipo
		and   rvinc.mod_id=mod.mod_id
		and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
		and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
        and   rts.movgest_ts_b_id=ts.movgest_ts_id             -- vincolo legato a impegno riaccertato
		and   av.avav_id=rts.avav_id
		and   tipoav.avav_tipo_id=av.avav_tipo_id
		and   tipoav.avav_tipo_code  ='AAM'
		and   dettsmod.mtdm_reimputazione_anno is not null
        and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno -- 06.04.2018 Sofia JIRA SIAC-6054 filtro modifiche per anno_reimputazione
		and   dettsmod.mtdm_reimputazione_flag is true
		and   rmodstato.validita_fine is null
		and   mov.data_cancellazione is null
		and   mov.validita_fine is null
		and   ts.data_cancellazione is null
		and   ts.validita_fine is null
		and   detts.data_cancellazione is null
		and   detts.validita_fine is null
		and   dettsmod.data_cancellazione is null
		and   dettsmod.validita_fine is null
		and   rmodstato.data_cancellazione is null
		and   rmodstato.validita_fine is null
		and   mod.data_cancellazione is null
		and   mod.validita_fine is null
		and   rvinc.data_cancellazione is null
		and   rvinc.validita_fine is null
		and   rts.data_cancellazione is null
		and   rts.validita_fine is null
	 )
	  select codResult,
	 	     p_faseBilElabId,
	         vincPrec.bil_id,
    	     vincPrec.mod_id,
             vincPrec.mod_tipo_code,  -- 06.04.2018 Sofia JIRA SIAC-6054
             vincPrec.mtdm_reimputazione_anno,  -- 06.04.2018 Sofia JIRA SIAC-6054
	         vincPrec.movgest_ts_r_id,
	         vincPrec.movgest_ts_b_id,
    	     vincPrec.avav_id,
	         vincPrec.importo_vincolo,
	         avanzoTipo.avav_id,
	         vincPrec.importo_vincolo_new,
	         clock_timestamp(),
	         p_loginoperazione,
	         p_enteProprietarioId
	  from vincPrec,titoloNew,avanzoTipo
	  where titoloNew.tipo_avanzo=avanzoTipo.avav_tipo_code
      );

    	strMessaggio := 'Inserimento caso 3,4 in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='||recmovgest.movgest_ts_id::varchar||'.';
	    raise notice 'strMessaggio=%',strMessaggio;

      /* caso 3
  		 se il vincolo abbattuto era legato ad un accertamento
		 che non presenta quote riaccertate esso stesso:
		 creare un vincolo nel nuovo bilancio di tipo FPV per la quote di vincolo abbattuta
		 con tipo spesa corrente o conto capitale in base al titolo di spesa dell'impegno (vedi algoritmo a seguire)*/

	  /* caso 4
		 se il vincolo abbattuto era legato ad un accertamento che presenta quote riaccertate:
		 creare un vincolo nel nuovo bilancio per la parte di vincolo abbattuta a capienza dell'utilizzabile
		 (utilizzabile - somma altri vincoli) del ogni nuovo acc. riaccertato con anno_accertamento<=anno_impegno
		 Per la restante parte creare un vincolo di tipo FPV con tipo spesa corrente o conto capitale in base al titolo di
		 spesa dell'impegno (vedi algoritmo a seguire) */
      -- 06.04.2018 Sofia JIRA SIAC-6054 - aggiunto filtri per tipo_modifica e anno_reimputazione
	  insert into   fase_bil_t_reimputazione_vincoli
  	  (
		reimputazione_id,
	    fasebilelabid,
    	bil_id,
	    mod_id,
        mod_tipo_code,      -- 06.04.2018 Sofia JIRA SIAC-6054
        reimputazione_anno, -- 06.04.2018 Sofia JIRA SIAC-6054
    	movgest_ts_r_id,
	    movgest_ts_b_id,
    	movgest_ts_a_id,
	    importo_vincolo,
    	avav_new_id,
	    importo_vincolo_new,
    	data_creazione,
	    login_operazione,
    	ente_proprietario_id
	 )
     (
		with
		titoloNew as
        (
  	    	select cTitolo.classif_code::integer titolo_uscita,
    	           ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                      then 'FPVSC'
                      when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                      then 'FPVCC'
                      else null end ) tipo_avanzo
        	from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
            	 siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
	             siac_r_class_fam_tree rfam,
    	         siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
        	     siac_t_bil bil, siac_t_periodo per
	        where tipo.ente_proprietario_id=p_enteProprietarioId
    	    and   tipo.elem_tipo_code=CAP_UG_TIPO
	        and   e.elem_tipo_id=tipo.elem_tipo_id
    	    and   bil.bil_id=e.bil_id
	        and   per.periodo_id=bil.periodo_id
	        and   per.anno::integer=p_annoBilancio
    	    and   e.elem_code::integer=recmovgest.elem_code::integer
	        and   e.elem_code2::integer=recmovgest.elem_code2::integer
    	    and   e.elem_code3::integer=recmovgest.elem_code3::integer
	        and   rc.elem_id=e.elem_id
    	    and   cMacro.classif_id=rc.classif_id
	        and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
    	    and   tipomacro.classif_tipo_code=MACROAGGREGATO_TIPO
        	and   rfam.classif_id=cMacro.classif_id
	        and   cTitolo.classif_id=rfam.classif_id_padre
    	    and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
        	and   tipoTitolo.classif_tipo_code=TITOLO_SPESA_TIPO
	        and   e.data_cancellazione is null
    	    and   e.validita_fine is null
        	and   rc.data_cancellazione is null
	        and   rc.validita_fine is null
    	    and   rfam.data_cancellazione is null
	        and   rfam.validita_fine is null
		),
		avanzoTipo as
		(
			select av.avav_id, avtipo.avav_tipo_code
			from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo avtipo
			where avtipo.ente_proprietario_id=p_enteProprietarioId
			and   avtipo.avav_tipo_code in ('FPVSC','FPVCC')
			and   av.avav_tipo_id=avtipo.avav_tipo_id
			and   extract('year' from av.validita_inizio::timestamp)::integer=p_annoBilancio
		),
		vincPrec as
		(
			select
			 bil.bil_id,
			 mod.mod_id,
             tipomod.mod_tipo_code,  -- 06.04.2018 Sofia JIRA SIAC-6054
             dettsmod.mtdm_reimputazione_anno::integer, -- 06.04.2018 Sofia JIRA SIAC-6054
			 rvinc.movgest_ts_r_id,
			 ts.movgest_ts_id movgest_ts_b_id, -- movgest_ts_b_id
			 rts.movgest_ts_a_id,              -- movgest_ts_a_id
			 rts.movgest_ts_importo importo_vincolo,
			 abs(rvinc.importo_delta) importo_vincolo_new -- importo_vincolo_new
			from siac_t_bil bil ,
			     siac_t_periodo per,
			     siac_t_movgest mov,siac_d_movgest_tipo tipo,
			     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
				 siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
				 siac_t_movgest_ts_det_mod  dettsmod,
				 siac_t_modifica mod,siac_d_modifica_tipo tipomod,
				 siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
				 siac_r_modifica_vincolo rvinc,
			     siac_r_movgest_ts rts
			where bil.ente_proprietario_id=p_enteProprietarioId
			and   per.periodo_id=bil.periodo_id
-- SIAC-6997 ---------------- INIZIO --------------------
--			and   per.anno::integer=p_annoBilancio-1
            and   per.anno::integer=v_annoBilancio
-- SIAC-6997 ---------------- INIZIO --------------------        
			and   tipo.ente_proprietario_id=bil.ente_proprietario_id
			and   tipo.movgest_tipo_code=p_movgest_tipo_code
			and   mov.movgest_tipo_id=tipo.movgest_tipo_id
			and   mov.bil_id=bil.bil_id
			and   ts.movgest_id=mov.movgest_id
			and   ts.movgest_ts_id=recmovgest.movgest_ts_id        -- movgest_ts_id --> di impegno-sub appena gestito
			and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
			and   detts.movgest_ts_id=ts.movgest_ts_id
			and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
			and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
			and   dettsmod.movgest_ts_det_importo<0
			and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
			and   modstato.mod_stato_id=rmodstato.mod_stato_id
			and   modstato.mod_stato_code='V'
			and   mod.mod_id=rmodstato.mod_id
			and   tipomod.mod_tipo_id =  mod.mod_tipo_id
-- SIAC-6997 ----------------  INIZIO --------------------
            and   mod.elab_ror_reanno = FALSE
            and   tipomod.mod_tipo_code = motivo
-- SIAC-6997 ----------------  FINE --------------------
            and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code  -- 06.04.2018 Sofia JIRA SIAC-6054 - filtro modifiche per mod_tipo
			and   rvinc.mod_id=mod.mod_id
			and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
			and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
            and   rts.movgest_ts_b_id=ts.movgest_ts_id             -- vincolo legato a impegno riaccertato
			and   rts.movgest_ts_a_id is not null -- legato ad accertamento
			and   dettsmod.mtdm_reimputazione_anno is not null
            and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno -- 06.04.2018 Sofia JIRA SIAC-6054 filtro modifiche per anno_reimputazione
			and   dettsmod.mtdm_reimputazione_flag is true
			and   rmodstato.validita_fine is null
			and   mov.data_cancellazione is null
			and   mov.validita_fine is null
			and   ts.data_cancellazione is null
			and   ts.validita_fine is null
			and   detts.data_cancellazione is null
			and   detts.validita_fine is null
			and   dettsmod.data_cancellazione is null
			and   dettsmod.validita_fine is null
			and   rmodstato.data_cancellazione is null
			and   rmodstato.validita_fine is null
			and   mod.data_cancellazione is null
			and   mod.validita_fine is null
			and   rvinc.data_cancellazione is null
			and   rvinc.validita_fine is null
			and   rts.data_cancellazione is null
			and   rts.validita_fine is null
		)
		select codResult,
	    	   p_faseBilElabId,
	           vincPrec.bil_id,
	  	       vincPrec.mod_id,
               vincPrec.mod_tipo_code,  -- 06.04.2018 Sofia JIRA SIAC-6054
               vincPrec.mtdm_reimputazione_anno,  -- 06.04.2018 Sofia JIRA SIAC-6054
	  	   	   vincPrec.movgest_ts_r_id,
	           vincPrec.movgest_ts_b_id,
	  	       vincPrec.movgest_ts_a_id,
	      	   vincPrec.importo_vincolo,
	           avanzoTipo.avav_id,
	           vincPrec.importo_vincolo_new,
	           clock_timestamp(),
	           p_loginoperazione,
       	       p_enteProprietarioId
        from vincPrec,titoloNew,avanzoTipo
		where titoloNew.tipo_avanzo=avanzoTipo.avav_tipo_code
	   );


       /* gestione scarti
       */
    	strMessaggio := 'Inserimento scarti in in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='||recmovgest.movgest_ts_id::varchar||'.';
	    raise notice 'strMessaggio=%',strMessaggio;

       insert into   fase_bil_t_reimputazione_vincoli
  	  (
		reimputazione_id,
	    fasebilelabid,
    	bil_id,
	    mod_id,
        mod_tipo_code,      -- 06.04.2018 Sofia JIRA SIAC-6054
        reimputazione_anno, -- 06.04.2018 Sofia JIRA SIAC-6054
    	movgest_ts_r_id,
	    movgest_ts_b_id,
    	movgest_ts_a_id,
	    importo_vincolo,
	    importo_vincolo_new,
        scarto_code,
        scarto_desc,
    	data_creazione,
	    login_operazione,
    	ente_proprietario_id
	 )
     (
			select
             codResult,
             p_faseBilElabId,
			 bil.bil_id,
			 mod.mod_id,
             tipomod.mod_tipo_code,  -- 06.04.2018 Sofia JIRA SIAC-6054
             dettsmod.mtdm_reimputazione_anno::integer, -- 06.04.2018 Sofia JIRA SIAC-6054
			 rvinc.movgest_ts_r_id,
			 ts.movgest_ts_id movgest_ts_b_id, -- movgest_ts_b_id
			 rts.movgest_ts_a_id,              -- movgest_ts_a_id
			 rts.movgest_ts_importo,  -- importo_vincolo
			 abs(rvinc.importo_delta), -- importo_vincolo_new
             '99',
             'VINCOLO NON CLASSIFICATO',
             clock_timestamp(),
             p_loginoperazione,
     	     p_enteProprietarioId
			from siac_t_bil bil ,
			     siac_t_periodo per,
			     siac_t_movgest mov,siac_d_movgest_tipo tipo,
			     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
				 siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
				 siac_t_movgest_ts_det_mod  dettsmod,
				 siac_t_modifica mod,siac_d_modifica_tipo tipomod,
				 siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
				 siac_r_modifica_vincolo rvinc,
			     siac_r_movgest_ts rts
			where bil.ente_proprietario_id=p_enteProprietarioId
			and   per.periodo_id=bil.periodo_id
-- SIAC-6997 ---------------- INIZIO --------------------
--			and   per.anno::integer=p_annoBilancio-1
            and   per.anno::integer=v_annoBilancio
-- SIAC-6997 ---------------- INIZIO --------------------        			
			and   tipo.ente_proprietario_id=bil.ente_proprietario_id
			and   tipo.movgest_tipo_code=p_movgest_tipo_code
			and   mov.movgest_tipo_id=tipo.movgest_tipo_id
			and   mov.bil_id=bil.bil_id
			and   ts.movgest_id=mov.movgest_id
			and   ts.movgest_ts_id=recmovgest.movgest_ts_id        -- movgest_ts_id --> di impegno-sub appena gestito
			and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
			and   detts.movgest_ts_id=ts.movgest_ts_id
			and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
			and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
			and   dettsmod.movgest_ts_det_importo<0
			and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
			and   modstato.mod_stato_id=rmodstato.mod_stato_id
			and   modstato.mod_stato_code='V'
			and   mod.mod_id=rmodstato.mod_id
			and   tipomod.mod_tipo_id =  mod.mod_tipo_id
-- SIAC-6997 ----------------  INIZIO --------------------
            and   mod.elab_ror_reanno = FALSE
            and   tipomod.mod_tipo_code = motivo
-- SIAC-6997 ----------------  FINE --------------------
            and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code  -- 06.04.2018 Sofia JIRA SIAC-6054 - filtro modifiche per mod_tipo
			and   rvinc.mod_id=mod.mod_id
			and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
			and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
            and   rts.movgest_ts_b_id=ts.movgest_ts_id             -- vincolo legato a impegno riaccertato
			and   dettsmod.mtdm_reimputazione_anno is not null
            and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno -- 06.04.2018 Sofia JIRA SIAC-6054 filtro modifiche per anno_reimputazione
			and   dettsmod.mtdm_reimputazione_flag is true
            and   not exists
            (
            select 1
            from fase_bil_t_reimputazione_vincoli fase
            where fase.fasebilelabid=p_faseBilElabId
            and   fase.movgest_ts_r_id=rts.movgest_ts_r_id
            and   fase.movgest_ts_b_id=ts.movgest_ts_id
            and   fase.mod_tipo_code=recmovgest.mod_tipo_code -- 06.04.2018 Sofia JIRA SIAC-6054
            and   fase.reimputazione_anno=recmovgest.mtdm_reimputazione_anno::integer -- 06.04.2018 Sofia JIRA SIAC-6054
            )
			and   rmodstato.validita_fine is null
			and   mov.data_cancellazione is null
			and   mov.validita_fine is null
			and   ts.data_cancellazione is null
			and   ts.validita_fine is null
			and   detts.data_cancellazione is null
			and   detts.validita_fine is null
			and   dettsmod.data_cancellazione is null
			and   dettsmod.validita_fine is null
			and   rmodstato.data_cancellazione is null
			and   rmodstato.validita_fine is null
			and   mod.data_cancellazione is null
			and   mod.validita_fine is null
			and   rvinc.data_cancellazione is null
			and   rvinc.validita_fine is null
			and   rts.data_cancellazione is null
			and   rts.validita_fine is null
	   );


    end if;



    end loop;

    strMessaggio := 'fine del loop';

    outfaseBilElabRetId:=p_faseBilElabId;
    codiceRisultato:=0;
    messaggioRisultato:=strMessaggioFinale||' FINE';

    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=p_faseBilElabId;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=p_faseBilElabId;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=p_faseBilElabId;
        return;

END;
$BODY$;

LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

