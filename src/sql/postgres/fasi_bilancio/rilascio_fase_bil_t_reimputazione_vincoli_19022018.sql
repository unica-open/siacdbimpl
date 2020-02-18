/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-5368 Sofia 19.02.2018 - INIZIO

CREATE TABLE if not exists fase_bil_t_reimputazione_vincoli
(
  reimputazione_vinc_id serial,
  reimputazione_id integer,
  fasebilelabid INTEGER NOT NULL,
  bil_id integer,
  mod_id integer,
  movgest_ts_r_id integer,
  movgest_ts_a_id integer,
  movgest_ts_b_id integer,
  avav_id integer,
  importo_vincolo numeric,
  bil_new_id   integer,
  movgest_ts_r_new_id integer,
  movgest_ts_a_new_id integer,
  movgest_ts_b_new_id integer,
  avav_new_id integer,
  importo_vincolo_new NUMERIC,
  fl_elab VARCHAR,
  scarto_code VARCHAR,
  scarto_desc VARCHAR,
  login_operazione VARCHAR,
  data_creazione TIMESTAMP WITHOUT TIME ZONE,
  data_modifica TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER
)
WITH (oids = false);


CREATE OR REPLACE FUNCTION fnc_siac_add_column()
returns void
AS
$body$
declare
 stm varchar;
begin

 select  'ALTER TABLE fase_bil_t_reimputazione ADD COLUMN attoamm_id integer;' into stm
 where
 not exists
 (
 SELECT 1
 FROM information_schema.columns
 WHERE table_name = 'fase_bil_t_reimputazione'
 AND column_name = 'attoamm_id'
 );
 if stm is not null then
 	execute stm;
 end if;

 stm:=null;
 select  'ALTER TABLE fase_bil_t_reimputazione ADD COLUMN movgest_stato_id integer;' into stm
 where
 not exists
 (
 SELECT 1
 FROM information_schema.columns
 WHERE table_name = 'fase_bil_t_reimputazione'
 AND column_name = 'movgest_stato_id'
 );
 if stm is not null then
 	execute stm;
 end if;

 stm:=null;
 select  'ALTER TABLE fase_bil_t_elaborazione ADD COLUMN fase_bil_elab_coll_id integer;' into stm
 where
 not exists
 (
 SELECT 1
 FROM information_schema.columns
 WHERE table_name = 'fase_bil_t_elaborazione'
 AND column_name = 'fase_bil_elab_coll_id'
 );
 if stm is not null then
 	execute stm;
 end if;


end;
$body$ LANGUAGE 'plpgsql' volatile called ON NULL input security invoker cost 100;

select * from fnc_siac_add_column();

insert into fase_bil_d_elaborazione_tipo
(
  fase_bil_elab_tipo_code,
  fase_bil_elab_tipo_desc,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select 'APE_GEST_REIMP_VINC',
       'APERTURA BILANCIO : GESTIONE REIMPUTAZIONE VINCOLI IMPEGNI-ACCERTAMENTI',
       now(),
       'admin',
       e.ente_proprietario_id
from siac_t_ente_proprietario e
where not exists
(
select 1
from fase_bil_d_elaborazione_tipo tipo
where tipo.ente_proprietario_id=e.ente_proprietario_id
and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP_VINC'
);

drop function if exists fnc_fasi_bil_gest_reimputa_elabora( p_fasebilelabid   INTEGER ,
                                                              enteproprietarioid INTEGER,
                                                              annobilancio       INTEGER,
                                                              loginoperazione    VARCHAR,
                                                              dataelaborazione TIMESTAMP,
                                                              p_movgest_tipo_code     VARCHAR,
                                                              OUT outfasebilelabretid INTEGER,
                                                              OUT codicerisultato     INTEGER,
                                                              OUT messaggiorisultato  VARCHAR );
															  
drop function if exists fnc_fasi_bil_gest_reimputa(
  enteProprietarioId     	integer,
  annoBilancio           	integer,
  loginOperazione        	varchar,
  p_dataElaborazione       	timestamp,
  p_movgest_tipo_code      	varchar,
  out outfaseBilElabRetId   integer,
  out codiceRisultato    	integer,
  out messaggioRisultato 	varchar
);

CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_reimputa_popola(
  p_faseBilElabId             integer,
  p_enteProprietarioId     	integer,
  p_annoBilancio           	integer,
  p_loginOperazione        	varchar,
  p_dataElaborazione       	timestamp,
  p_movgest_tipo_code      	VARCHAR,
  out outfaseBilElabRetId   integer,
  out codiceRisultato    	integer,
  out messaggioRisultato 	varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
	codResult          integer;
    v_faseBilElabId    integer;
    v_bil_attr_id      integer;
    v_attr_code        varchar;
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
				and   per.anno::integer=p_annoBilancio-1
				and   modifica.ente_proprietario_id=bil.ente_proprietario_id
				and   rmodstato.mod_id=modifica.mod_id
				and   dettsmod.mod_stato_r_id=rmodstato.mod_stato_r_id
				and   modstato.mod_stato_id=rmodstato.mod_stato_id
				and   modstato.mod_stato_code='V'
                and   modifica.mod_tipo_id =  modificaTipo.mod_tipo_id
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

	    insert into   fase_bil_t_reimputazione_vincoli
		(
			reimputazione_id,
		    fasebilelabid,
		    bil_id,
		    mod_id,
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
		and   per.anno::integer=p_annoBilancio-1
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

	  insert into   fase_bil_t_reimputazione_vincoli
	  (
		reimputazione_id,
    	fasebilelabid,
	    bil_id,
    	mod_id,
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
		and   per.anno::integer=p_annoBilancio-1
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
		and   rvinc.mod_id=mod.mod_id
		and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
		and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
        and   rts.movgest_ts_b_id=ts.movgest_ts_id             -- vincolo legato a impegno riaccertato
		and   av.avav_id=rts.avav_id
		and   tipoav.avav_tipo_id=av.avav_tipo_id
		and   tipoav.avav_tipo_code  ='AAM'
		and   dettsmod.mtdm_reimputazione_anno is not null
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
	  insert into   fase_bil_t_reimputazione_vincoli
  	  (
		reimputazione_id,
	    fasebilelabid,
    	bil_id,
	    mod_id,
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
			and   per.anno::integer=p_annoBilancio-1
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
			and   rvinc.mod_id=mod.mod_id
			and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
			and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
            and   rts.movgest_ts_b_id=ts.movgest_ts_id             -- vincolo legato a impegno riaccertato
			and   rts.movgest_ts_a_id is not null -- legato ad accertamento
			and   dettsmod.mtdm_reimputazione_anno is not null
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
			and   per.anno::integer=p_annoBilancio-1
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
			and   rvinc.mod_id=mod.mod_id
			and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
			and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
            and   rts.movgest_ts_b_id=ts.movgest_ts_id             -- vincolo legato a impegno riaccertato
			and   dettsmod.mtdm_reimputazione_anno is not null
			and   dettsmod.mtdm_reimputazione_flag is true
            and   not exists
            (
            select 1
            from fase_bil_t_reimputazione_vincoli fase
            where fase.fasebilelabid=p_faseBilElabId
            and   fase.movgest_ts_r_id=rts.movgest_ts_r_id
            and   fase.movgest_ts_b_id=ts.movgest_ts_id
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
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


															  

CREATE OR replace FUNCTION fnc_fasi_bil_gest_reimputa_elabora( p_fasebilelabid   INTEGER ,
                                                              enteproprietarioid INTEGER,
                                                              annobilancio       INTEGER,
                                                              impostaProvvedimento boolean, -- 07.02.2018 Sofia siac-5368
                                                              loginoperazione    VARCHAR,
                                                              dataelaborazione TIMESTAMP,
                                                              p_movgest_tipo_code     VARCHAR,
                                                              OUT outfasebilelabretid INTEGER,
                                                              OUT codicerisultato     INTEGER,
                                                              OUT messaggiorisultato  VARCHAR )
returns RECORD
AS
$body$
  DECLARE
    strmessaggiotemp   				VARCHAR(1000):='';
    tipomovgestid      				INTEGER:=NULL;
    movgesttstipoid    				INTEGER:=NULL;
    tipomovgesttssid   				INTEGER:=NULL;
    tipomovgesttstid   				INTEGER:=NULL;
    tipocapitologestid 				INTEGER:=NULL;
    bilancioid         				INTEGER:=NULL;
    bilancioprecid     				INTEGER:=NULL;
    periodoid          				INTEGER:=NULL;
    periodoprecid      				INTEGER:=NULL;
    datainizioval      				timestamp:=NULL;
    movgestidret      				INTEGER:=NULL;
    movgesttsidret    				INTEGER:=NULL;
    v_elemid          				INTEGER:=NULL;
    movgesttstipotid  				INTEGER:=NULL;
    movgesttstiposid  				INTEGER:=NULL;
    movgesttstipocode 				VARCHAR(10):=NULL;
    movgeststatoaid   				INTEGER:=NULL;
    v_importomodifica 				NUMERIC;
    movgestrec 						RECORD;
    aggprogressivi 					RECORD;
    cleanrec						RECORD;
    v_movgest_numero                INTEGER;
    v_prog_id                       INTEGER;
    v_flagdariaccertamento_attr_id  INTEGER;
    v_annoriaccertato_attr_id       INTEGER;
    v_numeroriaccertato_attr_id     INTEGER;
    v_numero_el                     integer;
    -- tipo periodo annuale
    sy_per_tipo CONSTANT VARCHAR:='SY';
    -- tipo anno ordinario annuale
    bil_ord_tipo        CONSTANT VARCHAR:='BIL_ORD';
    imp_movgest_tipo    CONSTANT VARCHAR:='I';
    acc_movgest_tipo    CONSTANT VARCHAR:='A';
    sim_movgest_ts_tipo CONSTANT VARCHAR:='SIM';
    sac_movgest_ts_tipo CONSTANT VARCHAR:='SAC';
    a_mov_gest_stato    CONSTANT VARCHAR:='A';
    strmessaggio        VARCHAR(1500):='';
    strmessaggiofinale  VARCHAR(1500):='';
    codresult           INTEGER;
    v_bil_attr_id       INTEGER;
    v_attr_code         VARCHAR;
    movgest_ts_t_tipo   CONSTANT VARCHAR:='T';
    movgest_ts_s_tipo   CONSTANT VARCHAR:='S';
    cap_ug_tipo         CONSTANT VARCHAR:='CAP-UG';
    cap_eg_tipo         CONSTANT VARCHAR:='CAP-EG';
    ape_gest_reimp      CONSTANT VARCHAR:='APE_GEST_REIMP';
    faserec RECORD;
    faseelabrec RECORD;
    recmovgest RECORD;
    v_maxcodgest      INTEGER;
    v_movgest_ts_id   INTEGER;
    v_ambito_id       INTEGER;
    v_inizio          VARCHAR;
    v_fine            VARCHAR;
    v_bil_tipo_id     INTEGER;
    v_periodo_id      INTEGER;
    v_periodo_tipo_id INTEGER;
    v_tmp             VARCHAR;


    -- 15.02.2017 Sofia SIAC-4425
	FRAZIONABILE_ATTR CONSTANT varchar:='flagFrazionabile';
    flagFrazAttrId integer:=null;
	-- 07.03.2017 Sofia SIAC-4568
    dataEmissione     timestamp:=null;

	-- 07.02.2018 Sofia siac-5368
    movGestStatoId INTEGER:=null;
    movGestStatoPId INTEGER:=null;
	MOVGEST_STATO_CODE_P CONSTANT VARCHAR:='P';

  BEGIN
    codicerisultato:=NULL;
    messaggiorisultato:=NULL;
    strmessaggiofinale:='Inizio.';
    datainizioval:= clock_timestamp();
    -- 07.03.2017 Sofia SIAC-4568
    dataEmissione:=(annoBilancio::varchar||'-01-01')::timestamp;

    SELECT attr.attr_id
    INTO   v_flagdariaccertamento_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code ='flagDaRiaccertamento'
    AND    attr.ente_proprietario_id = enteproprietarioid;

    SELECT attr.attr_id
    INTO   v_annoriaccertato_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code ='annoRiaccertato'
    AND    attr.ente_proprietario_id = enteproprietarioid;

    SELECT attr.attr_id
    INTO   v_numeroriaccertato_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code ='numeroRiaccertato'
    AND    attr.ente_proprietario_id = enteproprietarioid;

    -- estraggo il bilancio nuovo
    SELECT bil_id
    INTO   strict bilancioid
    FROM   siac_t_bil
    WHERE  bil_code = 'BIL_'
                  ||annobilancio::VARCHAR
    AND    ente_proprietario_id = enteproprietarioid;

	-- 07.02.2018 Sofia siac-5368
    strMessaggio:='Lettura identificativo per stato='||MOVGEST_STATO_CODE_P||'.';
	select stato.movgest_stato_id
    into   strict movGestStatoPId
    from siac_d_movgest_stato stato
    where stato.ente_proprietario_id=enteproprietarioid
    and   stato.movgest_stato_code=MOVGEST_STATO_CODE_P;

    -- 15.02.2017 Sofia Sofia SIAC-4425
	if p_movgest_tipo_code=imp_movgest_tipo then
    	strMessaggio:='Lettura identificativo per flagFrazAttrCode='||FRAZIONABILE_ATTR||'.';
     	select attr.attr_id into strict flagFrazAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FRAZIONABILE_ATTR
        and   attr.data_cancellazione is null
        and   attr.validita_fine is null;

        strMessaggio:='Lettura identificativo per movGestTipoCode='||imp_movgest_tipo||'.';
        select tipo.movgest_tipo_id into strict tipoMovGestId
        from siac_d_movgest_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.movgest_tipo_code=imp_movgest_tipo
        and   tipo.data_cancellazione is null
        and   tipo.validita_fine is null;

        strMessaggio:='Lettura identificativo per movGestTsTTipoCode='||movgest_ts_t_tipo||'.';
        select tipo.movgest_ts_tipo_id into strict tipoMovGestTsTId
        from siac_d_movgest_ts_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.movgest_ts_tipo_code=movgest_ts_t_tipo
        and   tipo.data_cancellazione is null
        and   tipo.validita_fine is null;

    end if;


    FOR movgestrec IN
    (
           SELECT reimputazione_id ,
                  bil_id ,
                  elemid_old ,
                  elem_code ,
                  elem_code2 ,
                  elem_code3 ,
                  elem_tipo_code ,
                  movgest_id ,
                  movgest_anno ,
                  movgest_numero ,
                  movgest_desc ,
                  movgest_tipo_id ,
                  parere_finanziario ,
                  parere_finanziario_data_modifica ,
                  parere_finanziario_login_operazione ,
                  movgest_ts_id ,
                  movgest_ts_code ,
                  movgest_ts_desc ,
                  movgest_ts_tipo_id ,
                  movgest_ts_id_padre ,
                  ordine ,
                  livello ,
                  movgest_ts_scadenza_data ,
                  movgest_ts_det_tipo_id ,
                  impoinizimpegno ,
                  impoattimpegno ,
                  importomodifica ,
                  tipo ,
                  movgest_ts_det_tipo_code ,
                  movgest_ts_det_importo ,
                  mtdm_reimputazione_anno ,
                  mtdm_reimputazione_flag ,
                  mod_tipo_code ,
                  attoamm_id,       -- 07.02.2018 Sofia siac-5368
                  movgest_stato_id, -- 07.02.2018 Sofia siac-5368
                  login_operazione ,
                  ente_proprietario_id,
                  siope_tipo_debito_id,
		          siope_assenza_motivazione_id
           FROM   fase_bil_t_reimputazione
           WHERE  ente_proprietario_id = enteproprietarioid
           AND    fasebilelabid = p_fasebilelabid
           AND    fl_elab = 'N' )
    LOOP
      movgesttsidret:=NULL;
      movgestidret:=NULL;
      codresult:=NULL;
      v_elemid:=NULL;
      v_inizio := movgestrec.mtdm_reimputazione_anno::VARCHAR ||'-01-01';
      v_fine := movgestrec.mtdm_reimputazione_anno::VARCHAR ||'-12-31';

	  --caso in cui si tratta di impegno/ accertamento creo la struttua a partire da movgest
      --tipots.movgest_ts_tipo_code tipo

      IF movgestrec.tipo !='S' THEN

        v_movgest_ts_id = NULL;
        --v_maxcodgest= movgestrec.movgest_ts_code::INTEGER;

        IF p_movgest_tipo_code = 'I' THEN
          strmessaggio:='progressivo per Impegno ' ||'imp_'||movgestrec.mtdm_reimputazione_anno::VARCHAR ||'.';
          SELECT prog_value + 1 ,
                 prog_id
          INTO   strict v_movgest_numero ,
                 v_prog_id
          FROM   siac_t_progressivo ,
                 siac_d_ambito
          WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
          AND    siac_t_progressivo.ente_proprietario_id = enteproprietarioid
          AND    siac_t_progressivo.prog_key = 'imp_'  ||movgestrec.mtdm_reimputazione_anno::VARCHAR
          AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          IF v_movgest_numero IS NULL THEN
            strmessaggio:='aggiungo progressivo per anno ' ||'imp_' ||movgestrec.mtdm_reimputazione_anno::VARCHAR ||'.';
            SELECT ambito_id
            INTO   strict v_ambito_id
            FROM   siac_d_ambito
            WHERE  ambito_code = 'AMBITO_FIN'
            AND    ente_proprietario_id = enteproprietarioid
            AND    data_cancellazione IS NULL;

            INSERT INTO siac_t_progressivo
            (
                        prog_value,
                        prog_key ,
                        ambito_id ,
                        validita_inizio ,
                        validita_fine ,
                        ente_proprietario_id ,
                        data_cancellazione ,
                        login_operazione
            )
            VALUES
            (
                        0,
                        'imp_' ||movgestrec.mtdm_reimputazione_anno::VARCHAR,
                        v_ambito_id ,
                        v_inizio::timestamp,
                        v_fine::timestamp,
                        enteproprietarioid ,
                        NULL,
                        loginoperazione
            )
            returning   prog_id  INTO        v_prog_id ;

            SELECT prog_value + 1 ,
                   prog_id
            INTO   v_movgest_numero ,
                   v_prog_id
            FROM   siac_t_progressivo ,
                   siac_d_ambito
            WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
            AND    siac_t_progressivo .ente_proprietario_id = enteproprietarioid
            AND    siac_t_progressivo.prog_key = 'imp_'
                          ||movgestrec.mtdm_reimputazione_anno::VARCHAR
            AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          END IF;

        ELSE --IF p_movgest_tipo_code = 'I'

          --Accertamento
          SELECT prog_value + 1,
                 prog_id
          INTO   v_movgest_numero,
                 v_prog_id
          FROM   siac_t_progressivo ,
                 siac_d_ambito
          WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
          AND    siac_t_progressivo .ente_proprietario_id = enteproprietarioid
          AND    siac_t_progressivo.prog_key = 'acc_'
                        ||movgestrec.mtdm_reimputazione_anno::VARCHAR
          AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          IF v_movgest_numero IS NULL THEN

            strmessaggio:='aggiungo progressivo per anno ' ||'acc_' ||movgestrec.mtdm_reimputazione_anno::VARCHAR ||'.';
            SELECT ambito_id
            INTO   v_ambito_id
            FROM   siac_d_ambito
            WHERE  ambito_code = 'AMBITO_FIN'
            AND    ente_proprietario_id = enteproprietarioid
            AND    data_cancellazione IS NULL;

            v_inizio := movgestrec.mtdm_reimputazione_anno::VARCHAR||'-01-01'; v_fine := movgestrec.mtdm_reimputazione_anno::VARCHAR||'-12-31';
            INSERT INTO siac_t_progressivo
			(
				prog_value ,
				prog_key ,
				ambito_id ,
				validita_inizio ,
				validita_fine ,
				ente_proprietario_id ,
				data_cancellazione ,
				login_operazione
			)
			VALUES
			(
				0,
				'acc_'||movgestrec.mtdm_reimputazione_anno::VARCHAR,
				v_ambito_id ,
				v_inizio::timestamp,
				v_fine::timestamp,
				enteproprietarioid ,
				NULL,
				loginoperazione
			)
            returning   prog_id INTO        v_prog_id ;

            SELECT prog_value + 1 ,
                   prog_id
            INTO   strict v_movgest_numero ,
                   v_prog_id
            FROM   siac_t_progressivo ,
                   siac_d_ambito
            WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
            AND    siac_t_progressivo .ente_proprietario_id = enteproprietarioid
            AND    siac_t_progressivo.prog_key = 'acc_'
                          ||movgestrec.mtdm_reimputazione_anno::VARCHAR
            AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          END IF; --fine if v_movgest_numero

        END IF;

        strmessaggio:='inserisco il siac_t_movgest.';
        INSERT INTO siac_t_movgest
        (
			movgest_anno,
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
        VALUES
        (
			movgestrec.mtdm_reimputazione_anno,
            v_movgest_numero,
			movgestrec.movgest_desc,
			movgestrec.movgest_tipo_id,
			bilancioid,
			datainizioval,
			enteproprietarioid,
			loginoperazione,
			movgestrec.parere_finanziario,
			movgestrec.parere_finanziario_data_modifica,
			movgestrec.parere_finanziario_login_operazione
        )
        returning   movgest_id INTO        movgestidret;

        IF movgestidret IS NULL THEN
          strmessaggiotemp:=strmessaggio;
          codresult:=-1;
        END IF;

        RAISE notice 'dopo inserimento siac_t_movgest movGestIdRet=%',movgestidret;

        strmessaggio:='aggiornamento progressivo v_prog_id ' ||v_prog_id::VARCHAR;
        UPDATE siac_t_progressivo
        SET    prog_value = prog_value + 1
        WHERE  prog_id = v_prog_id;

        strmessaggio:='estraggo il capitolo =elem_code ' || movgestrec.elem_code ||' elem_code2 ' || movgestrec.elem_code2 ||' elem_code3' || movgestrec.elem_code3 ||' elem_tipo_code =' || movgestrec.elem_tipo_code ||' bilancioId='||bilancioid::VARCHAR ||'.';
        --raise notice 'strMessaggio=%',strMessaggio;
        SELECT be.elem_id
        INTO   v_elemid
        FROM   siac_t_bil_elem be,
               siac_r_bil_elem_stato rbes,
               siac_d_bil_elem_stato bbes,
               siac_d_bil_elem_tipo bet
        WHERE  be.elem_tipo_id = bet.elem_tipo_id
        AND    be.elem_code=movgestrec.elem_code
        AND    be.elem_code2=movgestrec.elem_code2
        AND    be.elem_code3=movgestrec.elem_code3
        AND    bet.elem_tipo_code = movgestrec.elem_tipo_code
        AND    be.elem_id = rbes.elem_id
        AND    rbes.elem_stato_id = bbes.elem_stato_id
        AND    bbes.elem_stato_code !='AN'
        AND    rbes.data_cancellazione IS NULL
        AND    be.bil_id = bilancioid
        AND    be.ente_proprietario_id = enteproprietarioid
        AND    be.data_cancellazione IS NULL
        AND    be.validita_fine IS NULL;

        IF v_elemid IS NULL THEN
          codresult:=-1;
          strmessaggio:= ' impegno/accertamento privo di capitolo nel nuovo bilancio elem_code ' || movgestrec.elem_code ||' elem_code2 ' || movgestrec.elem_code2 ||' elem_code3' || movgestrec.elem_code3 ||' elem_tipo_code =' || movgestrec.elem_tipo_code ||' bilancioId='||bilancioid::VARCHAR ||'.';

          update fase_bil_t_reimputazione
          set fl_elab='X'
            ,movgestnew_ts_id = movgesttsidret
            ,movgestnew_id    = movgestidret
            ,data_modifica = clock_timestamp()
            ,scarto_code='IMAC1'
            ,scarto_desc=' impegno/accertamento privo di capitolo nel nuovo bilancio elem_code ' || movgestrec.elem_code ||' elem_code2 ' || movgestrec.elem_code2 ||' elem_code3' || movgestrec.elem_code3 ||' elem_tipo_code =' || movgestrec.elem_tipo_code ||' bilancioId='||bilancioid::VARCHAR ||'.'
      	  where
      	  	fase_bil_t_reimputazione.reimputazione_id = movgestrec.reimputazione_id;
          continue;
        END IF;


        -- relazione tra capitolo e movimento
        strmessaggio:='Inserimento relazione movimento capitolo anno='||movgestrec.movgest_anno ||' numero=' ||movgestrec.movgest_numero || ' v_elemId='||v_elemid::varchar ||' [siac_r_movgest_bil_elem]';

        INSERT INTO siac_r_movgest_bil_elem
        (
          movgest_id,
          elem_id,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
        )
        VALUES
        (
          movgestidret,
          v_elemid,--movGestRec.elemId_old,
          datainizioval,
          enteproprietarioid,
          loginoperazione
        )
        returning   movgest_atto_amm_id  INTO        codresult;

        IF codresult IS NULL THEN
          codresult:=-1;
          strmessaggiotemp:=strmessaggio;
        ELSE
          codresult:=NULL;
        END IF;
        strmessaggio:='Inserimento movimento movGestTipo=' ||movgestrec.tipo || ' anno=' ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero|| ' sub=' ||movgestrec.movgest_ts_code || ' [siac_t_movgest_ts].';
        RAISE notice 'strMessaggio=% ',strmessaggio;

        v_maxcodgest := v_movgest_numero;



      ELSE --caso in cui si tratta di subimpegno/ subaccertamento estraggo il movgest_id padre e movgest_ts_id_padre IF movgestrec.tipo =='S'

        -- todo calcolare il papa' sel subimpegno movgest_id  del padre  ed anche movgest_ts_id_padre
        strmessaggio:='caso SUB movGestTipo=' ||movgestrec.tipo ||'.';

        SELECT count(*)
        INTO v_numero_el
        FROM   fase_bil_t_reimputazione
        WHERE  fase_bil_t_reimputazione.movgest_anno = movgestrec.movgest_anno
        AND    fase_bil_t_reimputazione.movgest_numero = movgestrec.movgest_numero
        AND    fase_bil_t_reimputazione.fasebilelabid = p_fasebilelabid
        AND    fase_bil_t_reimputazione.mod_tipo_code =  movgestrec.mod_tipo_code
        AND    fase_bil_t_reimputazione.tipo = 'T';


        SELECT fase_bil_t_reimputazione.movgestnew_id ,
               fase_bil_t_reimputazione.movgestnew_ts_id
        INTO strict  movgestidret ,
               v_movgest_ts_id
        FROM   fase_bil_t_reimputazione
        WHERE  fase_bil_t_reimputazione.movgest_anno = movgestrec.movgest_anno
        AND    fase_bil_t_reimputazione.movgest_numero = movgestrec.movgest_numero
        AND    fase_bil_t_reimputazione.fasebilelabid = p_fasebilelabid
        AND    fase_bil_t_reimputazione.mod_tipo_code =  movgestrec.mod_tipo_code
        AND    fase_bil_t_reimputazione.tipo = 'T';



        if movgestidret is null then
          update fase_bil_t_reimputazione
          set fl_elab        ='X'
            ,scarto_code      ='IMACNP'
            ,scarto_desc      =' subimpegno/subaccertamento privo di testata modificata movGestTipo=' ||movgestrec.tipo || ' anno=' ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero|| ' v_numero_el = ' ||v_numero_el::varchar||'.'
      	    ,movgestnew_ts_id = movgesttsidret
            ,movgestnew_id    = movgestidret
            ,data_modifica = clock_timestamp()
          from
          	siac_t_bil_elem elem
      	  where
      	  	fase_bil_t_reimputazione.reimputazione_id = movgestrec.reimputazione_id;
        	continue;
        end if;


        strmessaggio:=' estraggo movGest padre movGestRec.movgest_id='||movgestrec.movgest_id::VARCHAR ||' p_fasebilelabid'||p_fasebilelabid::VARCHAR ||'' ||'.';
        --strMessaggio:='calcolo il max siac_t_movgest_ts.movgest_ts_code  movGestIdRet='||movGestIdRet::varchar ||'.';

        SELECT max(siac_t_movgest_ts.movgest_ts_code::INTEGER)
        INTO   v_maxcodgest
        FROM   siac_t_movgest ,
               siac_t_movgest_ts ,
               siac_d_movgest_tipo,
               siac_d_movgest_ts_tipo
        WHERE  siac_t_movgest.movgest_id = siac_t_movgest_ts.movgest_id
        AND    siac_t_movgest.movgest_tipo_id = siac_d_movgest_tipo.movgest_tipo_id
        AND    siac_d_movgest_tipo.movgest_tipo_code = p_movgest_tipo_code
        AND    siac_t_movgest_ts.movgest_ts_tipo_id = siac_d_movgest_ts_tipo.movgest_ts_tipo_id
        AND    siac_d_movgest_ts_tipo.movgest_ts_tipo_code = 'S'
        AND    siac_t_movgest.bil_id = bilancioid
        AND    siac_t_movgest.ente_proprietario_id = enteproprietarioid
        AND    siac_t_movgest.movgest_id = movgestidret;

        IF v_maxcodgest IS NULL THEN
          v_maxcodgest:=0;
        END IF;
        v_maxcodgest := v_maxcodgest+1;

     END IF; -- fine cond se sub o non sub





      -- caso di sub



      INSERT INTO siac_t_movgest_ts
      (
        movgest_ts_code,
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
		siope_tipo_debito_id,
		siope_assenza_motivazione_id
      )
      VALUES
      (
        v_maxcodgest::VARCHAR, --movGestRec.movgest_ts_code,
        movgestrec.movgest_ts_desc,
        movgestidret, -- inserito se I/A, per SUB ricavato
        movgestrec.movgest_ts_tipo_id,
        v_movgest_ts_id, -- ????? valorizzato se SUB come quello da cui deriva diversamente null
        movgestrec.movgest_ts_scadenza_data,
        movgestrec.ordine,
        movgestrec.livello,
--        dataelaborazione, -- 07.03.2017 Sofia SIAC-4568
		dataEmissione,      -- 07.03.2017 Sofia SIAC-4568
        enteproprietarioid,
        loginoperazione,
        loginoperazione,
        movgestrec.siope_tipo_debito_id,
		movgestrec.siope_assenza_motivazione_id
      )
      returning   movgest_ts_id
      INTO        movgesttsidret;

      IF movgesttsidret IS NULL THEN
        codresult:=-1;
        strmessaggiotemp:=strmessaggio;
      END IF;
      RAISE notice 'dopo inserimento siac_t_movgest_ts movGestTsIdRet=% codResult=%', movgesttsidret,codresult;

      -- siac_r_movgest_ts_stato
      strmessaggio:='Inserimento movimento ' || ' anno='  ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero || ' sub=' ||movgestrec.movgest_ts_code || ' [siac_r_movgest_ts_stato].';
      -- 07.02.2018 Sofia siac-5368
      /*INSERT INTO siac_r_movgest_ts_stato
	  (
          movgest_ts_id,
          movgest_stato_id,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
	  )
	  (
         SELECT movgesttsidret,
                r.movgest_stato_id,
                datainizioval,
                enteproprietarioid,
                loginoperazione
         FROM   siac_r_movgest_ts_stato r,
                siac_d_movgest_stato stato
         WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
         AND    stato.movgest_stato_id=r.movgest_stato_id
         AND    r.data_cancellazione IS NULL
         AND    r.validita_fine IS NULL
         AND    stato.data_cancellazione IS NULL
         AND    stato.validita_fine IS NULL )
      returning   movgest_stato_r_id INTO        codresult;*/

      -- 07.02.2018 Sofia siac-5368
	  if impostaProvvedimento=true then
      	     movGestStatoId:=movGestRec.movgest_stato_id;
      else   movGestStatoId:=movGestStatoPId;
      end if;

      INSERT INTO siac_r_movgest_ts_stato
	  (
          movgest_ts_id,
          movgest_stato_id,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
	  )
      values
      (
      	movgesttsidret,
        movGestStatoId,
        datainizioval,
        enteProprietarioId,
        loginoperazione
      )
      returning   movgest_stato_r_id INTO        codresult;


      IF codresult IS NULL THEN
        codresult:=-1;
        strmessaggiotemp:=strmessaggio;
      ELSE
        codresult:=NULL;
      END IF;
      RAISE notice 'dopo inserimento siac_r_movgest_ts_stato movGestTsIdRet=% codResult=%', movgesttsidret,codresult;
      -- siac_t_movgest_ts_det
      strmessaggio:='Inserimento movimento ' || ' anno=' ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero || ' sub=' ||movgestrec.movgest_ts_code|| ' [siac_t_movgest_ts_det].';
      RAISE notice ' inserimento siac_t_movgest_ts_det movGestTsIdRet=% movGestRec.movgest_ts_id=%', movgesttsidret,movgestrec.movgest_ts_id;
      v_importomodifica := movgestrec.importomodifica * -1;
      INSERT INTO siac_t_movgest_ts_det
	  (
        movgest_ts_id,
        movgest_ts_det_tipo_id,
        movgest_ts_det_importo,
        validita_inizio,
        ente_proprietario_id,
        login_operazione
	  )
	  (
       SELECT movgesttsidret,
              r.movgest_ts_det_tipo_id,
              v_importomodifica,
              datainizioval,
              enteproprietarioid,
              loginoperazione
       FROM   siac_t_movgest_ts_det r
       WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
       AND    r.data_cancellazione IS NULL
       AND    r.validita_fine IS NULL );

      IF codresult IS NULL THEN
        codresult:=-1;
        strmessaggiotemp:=strmessaggio;
      ELSE
        codresult:=NULL;
      END IF;
      strmessaggio:='Inserimento classificatori  movgest_ts_id='||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_class].';
      -- siac_r_movgest_class
      INSERT INTO siac_r_movgest_class
	  (
				  movgest_ts_id,
				  classif_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.classif_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_class r,
					siac_t_class class
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    class.classif_id=r.classif_id
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL
			 AND    class.data_cancellazione IS NULL
			 AND    class.validita_fine IS NULL );

      strmessaggio:='Inserimento attributi  movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_attr].';
      -- siac_r_movgest_ts_attr
      INSERT INTO siac_r_movgest_ts_attr
	  (
        movgest_ts_id,
        attr_id,
        tabella_id,
        BOOLEAN,
        percentuale,
        testo,
        numerico,
        validita_inizio,
        ente_proprietario_id,
        login_operazione
	  )
	  (
         SELECT movgesttsidret,
                r.attr_id,
                r.tabella_id,
                r.BOOLEAN,
                r.percentuale,
                r.testo,
                r.numerico,
                datainizioval,
                enteproprietarioid,
                loginoperazione
         FROM   siac_r_movgest_ts_attr r,
                siac_t_attr attr
         WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
         AND    attr.attr_id=r.attr_id
         AND    r.data_cancellazione IS NULL
         AND    r.validita_fine IS NULL
         AND    attr.data_cancellazione IS NULL
         AND    attr.validita_fine IS NULL
         AND    attr.attr_code NOT IN ('flagDaRiaccertamento',
                                       'annoRiaccertato',
                                       'numeroRiaccertato') );

      INSERT INTO siac_r_movgest_ts_attr
	  (
				  movgest_ts_id ,
				  attr_id ,
				  tabella_id ,
				  "boolean" ,
				  percentuale,
				  testo,
				  numerico ,
				  validita_inizio ,
				  validita_fine ,
				  ente_proprietario_id ,
				  data_cancellazione ,
				  login_operazione
	  )  VALUES (
				  movgesttsidret ,
				  v_flagdariaccertamento_attr_id ,
				  NULL,
				  'S',
				  NULL,
				  NULL ,
				  NULL,
				  now() ,
				  NULL ,
				  enteproprietarioid ,
				  NULL ,
				  loginoperazione
	  );

      INSERT INTO siac_r_movgest_ts_attr
	  (
        movgest_ts_id ,
        attr_id ,
        tabella_id ,
        "boolean" ,
        percentuale,
        testo,
        numerico ,
        validita_inizio ,
        validita_fine ,
        ente_proprietario_id ,
        data_cancellazione ,
        login_operazione
	  )
	  VALUES
	  (
        movgesttsidret ,
        v_annoriaccertato_attr_id,
        NULL,
        NULL,
        NULL,
        movgestrec.movgest_anno ,
        NULL ,
        now() ,
        NULL,
        enteproprietarioid,
        NULL,
        loginoperazione
	  );

      INSERT INTO siac_r_movgest_ts_attr
	  (
        movgest_ts_id ,
        attr_id ,
        tabella_id ,
        "boolean" ,
        percentuale,
        testo,
        numerico ,
        validita_inizio ,
        validita_fine ,
        ente_proprietario_id ,
        data_cancellazione ,
        login_operazione
	  )
	  VALUES
	  (
        movgesttsidret ,
        v_numeroriaccertato_attr_id ,
        NULL,
        NULL,
        NULL,
        movgestrec.movgest_numero ,
        NULL,
        now() ,
        NULL ,
        enteproprietarioid ,
        NULL,
        loginoperazione
	  );

      -- siac_r_movgest_ts_atto_amm
      /*strmessaggio:='Inserimento   movgest_ts_id='
      ||movgestrec.movgest_ts_id::VARCHAR
      || ' [siac_r_movgest_ts_atto_amm].';
      INSERT INTO siac_r_movgest_ts_atto_amm
	  (
				  movgest_ts_id,
				  attoamm_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.attoamm_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_atto_amm r,
					siac_t_atto_amm atto
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    atto.attoamm_id=r.attoamm_id
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL
       );*/
--			 AND    atto.data_cancellazione IS NULL Sofia HD-INC000001535447
--			 AND    atto.validita_fine IS NULL );

	   -- 07.02.2018 Sofia siac-5368
	   if impostaProvvedimento=true then
       	strmessaggio:='Inserimento   movgest_ts_id='
	      ||movgestrec.movgest_ts_id::VARCHAR
    	  || ' [siac_r_movgest_ts_atto_amm].';
       	INSERT INTO siac_r_movgest_ts_atto_amm
	  	(
		 movgest_ts_id,
	     attoamm_id,
	     validita_inizio,
	     ente_proprietario_id,
	     login_operazione
	  	)
        values
        (
         movgesttsidret,
         movgestrec.attoamm_id,
         datainizioval,
	 	 enteproprietarioid,
	 	 loginoperazione
        );
       end if;


      -- siac_r_movgest_ts_sog
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_sog].';
      INSERT INTO siac_r_movgest_ts_sog
	  (
				  movgest_ts_id,
				  soggetto_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.soggetto_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_sog r,
					siac_t_soggetto sogg
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    sogg.soggetto_id=r.soggetto_id
			 AND    sogg.data_cancellazione IS NULL
			 AND    sogg.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_movgest_ts_sogclasse
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_sogclasse].';
      INSERT INTO siac_r_movgest_ts_sogclasse
	  (
				  movgest_ts_id,
				  soggetto_classe_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.soggetto_classe_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_sogclasse r,
					siac_d_soggetto_classe classe
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    classe.soggetto_classe_id=r.soggetto_classe_id
			 AND    classe.data_cancellazione IS NULL
			 AND    classe.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_movgest_ts_programma
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_programma].';
      INSERT INTO siac_r_movgest_ts_programma
	  (
				  movgest_ts_id,
				  programma_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.programma_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_programma r,
					siac_t_programma prog
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    prog.programma_id=r.programma_id
			 AND    prog.data_cancellazione IS NULL
			 AND    prog.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_mutuo_voce_movgest
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_mutuo_voce_movgest].';
      INSERT INTO siac_r_mutuo_voce_movgest
	  (
				  movgest_ts_id,
				  mut_voce_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.mut_voce_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_mutuo_voce_movgest r,
					siac_t_mutuo_voce voce
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    voce.mut_voce_id=r.mut_voce_id
			 AND    voce.data_cancellazione IS NULL
			 AND    voce.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_causale_movgest_ts
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_causale_movgest_ts].';
      INSERT INTO siac_r_causale_movgest_ts
	  (
				  movgest_ts_id,
				  caus_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.caus_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_causale_movgest_ts r,
					siac_d_causale caus
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    caus.caus_id=r.caus_id
			 AND    caus.data_cancellazione IS NULL
			 AND    caus.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- 05.05.2017 Sofia HD-INC000001737424
      -- siac_r_subdoc_movgest_ts
      /*
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_subdoc_movgest_ts].';
      INSERT INTO siac_r_subdoc_movgest_ts
	  (
				  movgest_ts_id,
				  subdoc_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.subdoc_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_subdoc_movgest_ts r,
					siac_t_subdoc sub
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    sub.subdoc_id=r.subdoc_id
			 AND    sub.data_cancellazione IS NULL
			 AND    sub.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_predoc_movgest_ts
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_predoc_movgest_ts].';
      INSERT INTO siac_r_predoc_movgest_ts
                  (
                              movgest_ts_id,
                              predoc_id,
                              validita_inizio,
                              ente_proprietario_id,
                              login_operazione
                  )
                  (
                         SELECT movgesttsidret,
                                r.predoc_id,
                                datainizioval,
                                enteproprietarioid,
                                loginoperazione
                         FROM   siac_r_predoc_movgest_ts r,
                                siac_t_predoc sub
                         WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
                         AND    sub.predoc_id=r.predoc_id
                         AND    sub.data_cancellazione IS NULL
                         AND    sub.validita_fine IS NULL
                         AND    r.data_cancellazione IS NULL
                         AND    r.validita_fine IS NULL );
	  */
      -- 05.05.2017 Sofia HD-INC000001737424


      strmessaggio:='aggiornamento tabella di appoggio';
      UPDATE fase_bil_t_reimputazione
      SET   movgestnew_ts_id =movgesttsidret
      		,movgestnew_id =movgestidret
            ,data_modifica = clock_timestamp()
       		,fl_elab='S'
      WHERE  reimputazione_id = movgestrec.reimputazione_id;



    END LOOP;

    -- bonifica eventuali scarti
    select * into cleanrec from fnc_fasi_bil_gest_reimputa_clean(  p_fasebilelabid ,enteproprietarioid );

	-- 15.02.2017 Sofia Sofia SIAC-4425
	if p_movgest_tipo_code=imp_movgest_tipo and cleanrec.codicerisultato =0 then
     -- insert N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
     -- essendo reimputazioni consideriamo solo mov.movgest_anno::integer>annoBilancio
     -- che non hanno ancora attributo
	 strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore N per impegni pluriennali.';
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
     and   mov.movgest_anno::integer>annoBilancio
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
     -- essendo reimputazioni consideriamo solo mov.movgest_anno::integer>annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni pluriennali.';
	 update  siac_r_movgest_ts_attr r set boolean='N'
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where  mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<2017 or mov.movgest_anno::integer>2017)
	 and   mov.movgest_anno::integer>annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   r.movgest_ts_id=ts.movgest_ts_id
     and   r.attr_id=flagFrazAttrId
	 and   r.boolean='S'
     and   r.login_operazione=loginOperazione
     and   r.data_cancellazione is null
     and   r.validita_fine is null;

     -- aggiornamento N per impegni mov.movgest_anno::integer=annoBilancio e atto.attoamm_anno::integer < annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni di competenza con atto amministrativo antecedente.';
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
     and   r.login_operazione=loginOperazione
     and   r.data_cancellazione is null
     and   r.validita_fine is null
     and   ra.data_cancellazione is null
     and   ra.validita_fine is null;
    end if;
    -- 15.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile


    outfasebilelabretid:=p_fasebilelabid;
    if cleanrec.codicerisultato = -1 then
	    codicerisultato:=cleanrec.codicerisultato;
	    messaggiorisultato:=cleanrec.messaggiorisultato;
    else
	    codicerisultato:=0;
	    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||' FINE';
    end if;



    outfasebilelabretid:=p_fasebilelabid;
    codicerisultato:=0;
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||' FINE';
    RETURN;
  EXCEPTION
  WHEN raise_exception THEN
    RAISE notice '% % ERRORE : %',strmessaggiofinale,strmessaggio,substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'ERRORE :' ||' ' ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice ' % % Nessun elemento trovato.' ,strmessaggiofinale,strmessaggio;
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'Nessun elemento trovato.' ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE,substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'Errore DB ' ||SQLSTATE ||' ' ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  END;
  $body$ LANGUAGE 'plpgsql' volatile called ON NULL input security invoker cost 100;
  
 
 CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_reimputa
(
  enteProprietarioId     	integer,
  annoBilancio           	integer,
  impostaProvvedimento	    varchar, -- 07.02.2018 Sofia siac-5368
  loginOperazione        	varchar,
  p_dataElaborazione       	timestamp,
  p_movgest_tipo_code      	varchar,
  out outfaseBilElabRetId   integer,
  out codiceRisultato    	integer,
  out messaggioRisultato 	varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
	codResult          integer;
    v_faseBilElabId    integer;
    v_bil_attr_id      integer;
    v_attr_code        varchar;
    MOVGEST_TS_T_TIPO  CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO  CONSTANT varchar:='S';
    CAP_UG_TIPO        CONSTANT varchar:='CAP-UG';
    CAP_EG_TIPO        CONSTANT varchar:='CAP-EG';
    APE_GEST_REIMP     CONSTANT varchar:='APE_GEST_REIMP';
    v_boolean          char(1);
    v_attr_id          integer;
    v_bil_id           integer;
    faseRec record;
    faseElabRec record;

BEGIN
	v_faseBilElabId:=null;
    codiceRisultato:=null;
    messaggioRisultato:=null;


    strMessaggioFinale:='Reimputazione Importi/ accertamenti a partire anno ='||annoBilancio::varchar||'.';

    select bil_id into v_bil_id from siac_t_bil where ente_proprietario_id = enteProprietarioId and bil_code = 'BIL_'||annoBilancio::varchar and data_cancellazione is null;
    if v_bil_id is  null then
        strMessaggio :='Bilancio non trovato anno ='||annoBilancio::varchar||'.';
    	raise exception 'Bilancio non trovato anno =%',annoBilancio::varchar;
    	return;
    end if;

    strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_REIMP||' IN CORSO.';
    select 1 into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito like 'IN%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
    if codResult is not null then
        strMessaggio :=' Esistenza elaborazione reimputazione in corso.';
    	raise exception ' Esistenza elaborazione reimputazione in corso.';
    	return;
    end if;


    strMessaggio:='Inserimento fase elaborazione [fnc_fasi_bil_gest_reimputa].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
    fase_bil_elab_tipo_id,
    ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE REIMPUTAZIONE IN CORSO.',tipo.fase_bil_elab_tipo_id,ente_proprietario_id, p_dataElaborazione, loginOperazione
    from fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteproprietarioid
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null)
    returning fase_bil_elab_id into v_faseBilElabId;

     if v_faseBilElabId is null then
        strMessaggio  :=' Inserimento elaborazione per tipo APE_GEST_REIMP non effettuato.';
     	raise exception ' Inserimento elaborazione per tipo APE_GEST_REIMP non effettuato.';
     	return;
     end if;

/*
A)
Il sistema verifica che l’elaborazione non sia gia stata effettuata:
SE per l’anno di bilancio in elaborazione il flagReimputaSpese e a TRUE l’elaborazione viene interrotta con l’errore
- quindi se su siac_t_bil per annoBilancio=2017
               siac_r_bil_attr per attr_code in flagReimputaSpese,flagReimputaEntrate il valore e impostato a S, se si blocchi elaborazione, se no procedi

Verificare che non ci siano elaborazioni in corso per APE_GEST_REIMP in fase_bil_t_elaborazione ( come fanno le altre function )
Inserire nella fase_bil_t_elaborazione il fase_elab_id per  APE_GEST_REIMP
*/

    if p_movgest_tipo_code = 'I' then
        v_attr_code := 'flagReimputaSpese';
        select attr_id into v_attr_id  from siac_t_attr where ente_proprietario_id = enteProprietarioId and   data_cancellazione is null and      attr_code = 'flagReimputaSpese';
    else
        v_attr_code := 'flagReimputaEntrate';
        select attr_id into v_attr_id  from siac_t_attr where ente_proprietario_id = enteProprietarioId and   data_cancellazione is null and      attr_code = 'flagReimputaEntrate';
    end if;


    select
    	siac_r_bil_attr.bil_attr_id,
    	siac_r_bil_attr.boolean
    into v_bil_attr_id,v_boolean
    from
    	siac_t_bil,siac_r_bil_attr,siac_t_attr
    where
    siac_t_bil.bil_id = siac_r_bil_attr.bil_id
    and siac_r_bil_attr.attr_id =  siac_t_attr.attr_id
    and siac_r_bil_attr.data_cancellazione is null
    and siac_t_attr.attr_code = v_attr_code
    and siac_t_bil.bil_code = 'BIL_'||annoBilancio::varchar
    --and siac_r_bil_attr.boolean != 'S'
    and siac_t_bil.ente_proprietario_id = enteProprietarioId;

    raise notice ' v_bil_attr_id %',v_bil_attr_id;

    if v_bil_attr_id is  null then
        insert into  siac_r_bil_attr (bil_id ,attr_id ,tabella_id ,boolean,percentuale,testo ,numerico ,validita_inizio ,validita_fine ,ente_proprietario_id ,data_cancellazione ,login_operazione
        )
        VALUES( v_bil_id,v_attr_id,null,'N',null,null,null,now(),null,enteProprietarioId,null,loginOperazione)
        returning bil_attr_id into v_bil_attr_id; -- 26.01.2016 Sofia
	else
		if  v_boolean = 'S' then
            strMessaggio:=' Elaborazione terminata reimputazione gia eseguita in precedenza v_bil_attr_id-->'||v_bil_attr_id::varchar||'.';
            --raise notice ' Elaborazione terminata reimputazione gia eseguita in precedenza.';
			raise exception ' Elaborazione terminata reimputazione gia eseguita in precedenza.';
			return;
        end if;
    end if;

	select * into faseRec
    from fnc_fasi_bil_gest_reimputa_popola
    	 (
    	  v_faseBilElabId            ,
    	  enteProprietarioId     	,
          annoBilancio           	,
          loginOperazione        	,
          p_dataElaborazione       	,
          p_movgest_tipo_code
          );
    if faseRec.codiceRisultato=-1  then
     strMessaggio:='Errore Lancio popolamento.'||faseRec.messaggioRisultato;
     raise exception 'Errore Lancio popolamento % .',faseRec.messaggioRisultato;
     return;
    end if;



	select * into faseRec
    from fnc_fasi_bil_gest_reimputa_elabora
    	 (
    	  v_faseBilElabId,
    	  enteProprietarioId,
		  annoBilancio,
          impostaProvvedimento::boolean, -- 07.02.2018 Sofia siac-5638
		  loginOperazione,
		  p_dataElaborazione,
		  p_movgest_tipo_code
          );
    if faseRec.codiceRisultato=-1  then
     strMessaggio:='Lancio elaborazione.'||faseRec.messaggioRisultato;
     raise exception ' Errore Lancio elaborazione % .',faseRec.messaggioRisultato;
     return;
    end if;

    strMessaggio:='Aggiornamento attributo reimputazione avvenuta con succeeo poi chiusura.';
    update  siac_r_bil_attr set BOOLEAN='S',login_operazione = loginoperazione , data_modifica = now()
    where   bil_attr_id = v_bil_attr_id;

    strMessaggio:='Aggiornamento stato fase bilancio OK per chiusura v_bil_attr_id-->'||v_bil_attr_id::varchar||'.';

    update fase_bil_t_elaborazione fase
    set fase_bil_elab_esito='OK',
        fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_REIMP||' CHIUSURA.'
    where fase.fase_bil_elab_id=v_faseBilElabId;

    outfaseBilElabRetId:=v_faseBilElabId;
    codiceRisultato:=0;
    messaggioRisultato:=strMessaggioFinale||' FINE';

    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=v_faseBilElabId;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=v_faseBilElabId;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=v_faseBilElabId;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;



CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_reimputa_provvedimento
(
  enteProprietarioId     	integer,
  annoBilancio           	integer,
  loginOperazione        	varchar,
  p_dataElaborazione       	timestamp,
  p_movgest_tipo_code      	varchar,
  out outfaseBilElabRetId   integer,
  out codiceRisultato    	integer,
  out messaggioRisultato 	varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
	codResult          integer;

    APE_GEST_REIMP     CONSTANT varchar:='APE_GEST_REIMP';

	tipoMovGestId integer;
    bilancioPrecId integer;
    faseBilElabId integer;
    v_faseBilElabId integer;

BEGIN
	outfaseBilElabRetId:=null;
    codiceRisultato:=null;
    messaggioRisultato:=null;


    strMessaggioFinale:='Reimputazione impegni-accertamenti a partire anno ='||annoBilancio::varchar||'. Aggiornamento provvedimento e stato.';


    strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_REIMP||' IN CORSO.';
    select 1 into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito like 'IN%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
    if codResult is not null then
    	raise exception ' Esistenza elaborazione reimputazione in corso.';
    end if;


    strMessaggio:='Lettura tipo movimento='||p_movgest_tipo_code||'.';
    select tipo.movgest_tipo_id into tipoMovGestId
    from siac_d_movgest_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code=p_movgest_tipo_code;
    if tipoMovGestId  is null then
    	raise exception ' Identificativo non reperito.';
    end if;

    strMessaggio:='Lettura annoBilancio-1='||(annoBilancio-1)::varchar||'.';
    select bil.bil_id into bilancioPrecId
    from siac_t_bil bil , siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::integer=annoBilancio-1;
    if bilancioPrecId is null then
	  	raise exception ' Identificativo non reperito.';
    end if;

  	codResult:=null;
    strMessaggio:='Lettura identificativo elaborazione '||APE_GEST_REIMP||' per movimento di tipo='||p_movgest_tipo_code||'.';
    select fase.fase_bil_elab_id into faseBilElabId
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
         fase_bil_t_reimputazione fasereimp
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito='OK'
    and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
    and   fasereimp.movgest_tipo_id=tipoMovGestId
    and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
    and   fasereimp.bil_id=bilancioPrecId -- bilancio precedente per elaborazione reimputazione su annoBilancio
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null
    order by fase.fase_bil_elab_id desc
    limit 1;
    if faseBilElabId is null then
	 	raise exception ' Identificativo non reperito.';
    end if;

	codResult:=null;
    strMessaggio:=' Inizio.';
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

	codResult:=null;
    strMessaggio:='Aggiornamento stati operativi.';
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

    strMessaggio:='Aggiornamento stati operativi.Chiusura stato corrente.';
    v_faseBilElabId:=faseBilElabId;
	-- aggiornamento stati operativi
    -- chiusura stato precedente
    update siac_r_movgest_ts_stato rs
    set    validita_fine=clock_timestamp(),
           data_cancellazione=clock_timestamp(),
           login_operazione=rs.login_operazione||'-'||loginOperazione
    from fase_bil_t_reimputazione fase
    where fase.fasebilelabid=v_faseBilElabId
    and   fase.fl_elab is not null and fase.fl_elab='S'
    and   fase.bil_id=bilancioPrecId -- bilancio precedente per elaborazione reimputazione su annoBilancio
    and   rs.movgest_ts_id=fase.movgestnew_ts_id
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null;

    -- inserimento stato di origine
    strMessaggio:='Aggiornamento stati operativi.Inserimento stato da riaccertamento.';
    insert into siac_r_movgest_ts_stato
    (
    	movgest_ts_id,
        movgest_stato_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    select  fase.movgestnew_ts_id,
            fase.movgest_stato_id,
            clock_timestamp(),
            loginOperazione,
            enteProprietarioId
    from fase_bil_t_reimputazione fase
    where fase.fasebilelabid=v_faseBilElabId
    and   fase.fl_elab is not null and fase.fl_elab='S'
    and   fase.bil_id=bilancioPrecId; -- bilancio precedente per elaborazione reimputazione su annoBilancio


	codResult:=null;
    strMessaggio:='Aggiornamento provvedimenti.Inserimento stato da riaccertamento.';
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    --- inserimento provvedimento

    insert into siac_r_movgest_ts_atto_amm
    (
    	movgest_ts_id,
        attoamm_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    select fase.movgestnew_ts_id,
           fase.attoamm_id,
           clock_timestamp(),
           loginOperazione,
           enteProprietarioId
    from fase_bil_t_reimputazione fase
    where fase.fasebilelabid=v_faseBilElabId
    and   fase.fl_elab is not null and fase.fl_elab='S'
    and   fase.bil_id=bilancioPrecId -- bilancio precedente per elaborazione reimputazione su annoBilancio
    and   not exists
    (select 1
     from siac_r_movgest_ts_atto_amm r1
     where r1.movgest_ts_id=fase.movgestnew_ts_id
     and   r1.data_cancellazione is null
     and   r1.validita_fine is null
    );

	codResult:=null;
    strMessaggio:=' Fine.';
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;


    outfaseBilElabRetId:=faseBilElabId;
    codiceRisultato:=0;
    messaggioRisultato:=strMessaggioFinale||' FINE';

    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=faseBilElabId;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=faseBilElabId;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=faseBilElabId;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_reimputa_vincoli_acc (
  enteproprietarioid integer,
  annobilancio integer,
  faseBilElabId integer,
  annoImpegnoRiacc integer,   -- annoImpegno riaccertato
  movgestTsImpNewId integer,  -- movgest_id_id impegno riaccertato
  avavRiaccImpId   integer,        -- avav_id nuovo
  importoVincoloRiaccertato numeric, -- importo totale vincolo impegno riaccertato
  faseBilElabReAccId integer, -- faseId di elaborazione riaccertmaento Acc
  tipoMovGestAccId integer,   -- tipoMovGestId Accertamenti
  movgestTsAccPrecId integer, -- movgest_ts_id accertamento anno precedente vincolato a impegno riaccertato
  loginoperazione varchar,
  dataelaborazione timestamp,
  out numeroVincoliCreati integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

    daVincolare numeric:=0;
    importoVinc numeric:=0;
    totVincolato numeric:=0;

    daCancellare BOOLEAN:=false;
    movGestRec record;

    numeroVinc   integer:=0;
BEGIN

    codiceRisultato:=null;
    messaggioRisultato:=null;
    numeroVincoliCreati:=0;

	strMessaggioFinale:='Reimputazione vincoli su accertamento riacc. Anno bilancio='
                     ||annoBilancio::varchar
                     ||' per impegno riacc movgest_ts_id='||movgestTsImpNewId::varchar
                     ||' per avav_id='||avavRiaccImpId::varchar
                     ||' per importo vincolo='||importoVincoloRiaccertato::varchar||'.';

    raise notice 'strMessaggioFinale=%',strMessaggioFinale;
    strMessaggio:='Inizio elaborazione.';
    insert into fase_bil_t_elaborazione_log
	(fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
	)
	values
    (faseBilElabId,strMessaggioFinale||' - INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
	returning fase_bil_elab_log_id into codResult;

	if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	end if;

    daVincolare:=importoVincoloRiaccertato;
	for movGestRec in
	(
	 with
	 accPrec as
	 (-- accertamento vincolato in annoBilancio-1
	  select mov.movgest_anno::integer anno_accertamento,
  			 mov.movgest_numero::integer numero_accertamento,
	         (case when tstipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) numero_subaccertamento,
    	     mov.movgest_id, ts.movgest_ts_id
	  from siac_t_movgest mov, siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tstipo,
    	   siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
	  where ts.movgest_ts_id=movgestTsAccPrecId
      and   tstipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
	  and   mov.movgest_id=ts.movgest_id
	  and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
	  and   rs.data_cancellazione is null
	  and   rs.validita_fine is null
	  and   mov.data_cancellazione is null
	  and   mov.validita_fine is null
	  and   ts.data_cancellazione is null
	  and   ts.validita_fine is null
	 ),
 	 accCurRiacc as
	 (-- accertamenti riaccertati per accPrec in annoBilancio
	  select mov.movgest_anno::integer anno_accertamento,
    	     mov.movgest_numero::integer numero_accertamento,
	 	     (case when tstipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) numero_subaccertamento,
		     mov.movgest_id movgest_new_id, ts.movgest_ts_id movgest_ts_new_id,fase.movgest_ts_id
	  from siac_t_movgest mov, siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tstipo,
   		   siac_r_movgest_ts_stato rs, fase_bil_t_reimputazione fase,siac_d_movgest_stato stato,
           siac_t_bil bil,siac_t_periodo per
	  where bil.ente_proprietario_id=enteProprietarioId
      and   per.periodo_id=bil.periodo_id
      and   per.anno::integer=annoBilancio
      and   mov.bil_id=bil.bil_id
	  and   mov.movgest_tipo_id=tipoMovGestAccId
	  and   ts.movgest_id=mov.movgest_id
      and   tstipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
	  and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
	  and   fase.fasebilelabid=faseBilElabReAccId
	  and   fase.fl_elab is not null and fase.fl_elab!=''
	  and   fase.fl_elab='S'
	  and   ts.movgest_ts_id=fase.movgestnew_ts_id  -- nuovo accertamento riaccertato con anno_accertamento<=anno_impegno nuovo
	  and   mov.movgest_anno::integer<=annoImpegnoRiacc
	  and   rs.data_cancellazione is null
	  and   rs.validita_fine is null
	  and   mov.data_cancellazione is null
	  and   mov.validita_fine is null
	  and   ts.data_cancellazione is null
	  and   ts.validita_fine is null
	),
	accUtilizzabile as
	(-- utlizzabile per accertamento
	 select det.movgest_ts_id, det.movgest_ts_det_importo importo_utilizzabile
	 from siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipo
	 where tipo.ente_proprietario_id=enteProprietarioId
	 and   tipo.movgest_ts_det_tipo_code='U'
	 and   det.movgest_ts_det_tipo_id= tipo.movgest_ts_det_tipo_id
	 and   det.data_cancellazione is null
	 and   det.validita_fine is null
	),
	vincolato as
	(-- vincolato per accertamento
	 select r.movgest_ts_a_id, sum(r.movgest_ts_importo) totale_vincolato
     from siac_r_movgest_ts r
	 where r.ente_proprietario_id=enteProprietarioId
	 and   r.data_cancellazione is null
	 and   r.validita_fine is null
     and   r.movgest_ts_a_id is not null
	 group by r.movgest_ts_a_id
	)
	select   accCurRiacc.anno_accertamento,
    	     accCurRiacc.numero_accertamento,
        	 accCurRiacc.numero_subaccertamento,
	         accUtilizzabile.importo_utilizzabile,
    	     coalesce(vincolato.totale_vincolato,0) totale_vincolato,
	         accUtilizzabile.importo_utilizzabile -  coalesce(vincolato.totale_vincolato,0) dispVincolabile,
    	     accCurRiacc.movgest_ts_new_id movgest_ts_riacc_id
	from accPrec, accUtilizzabile,
    	 accCurRiacc
	       left join vincolato on (accCurRiacc.movgest_ts_new_id=vincolato.movgest_ts_a_id)
	where accPrec.movgest_ts_id=accCurRiacc.movgest_ts_id
    and   accUtilizzabile.movgest_ts_id=accCurRiacc.movgest_ts_new_id
	order by  accCurRiacc.anno_accertamento,
	          accCurRiacc.numero_accertamento,
	          accCurRiacc.numero_subaccertamento
	)
	loop
	   --daVincolare:=importoVincoloRiaccertato-(totVincolato);
       raise notice 'daVincolare=%',daVincolare;
	   raise notice 'dispVincolabile=%',movGestRec.dispVincolabile;
	   if daVincolare >= movGestRec.dispVincolabile then
   	        importoVinc:=movGestRec.dispVincolabile;
   	   else importoVinc:=daVincolare;
	   end if;

       raise notice 'importoVinc=%',importoVinc;

	   codResult:=null;
       strMessaggio:='Accertamento da riacc movgest_ts_id='||movgestTsAccPrecId::varchar
                    ||' - accertamento riacc movgest_ts_id='||movGestRec.movgest_ts_riacc_id::varchar
                    ||' - quota vincolo='||importoVinc::varchar||'.';
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

	   if importoVinc>0 then
        codResult:=null;
   		-- insert into siac_r_movgest_ts
	    insert into siac_r_movgest_ts
	    (
    		movgest_ts_a_id,
        	movgest_ts_b_id,
	        movgest_ts_importo,
    	    avav_id,
    	    validita_inizio,
	        login_operazione,
	        ente_proprietario_id
	    )
    	values
	    (
    		movGestRec.movgest_ts_riacc_id,
	        movgestTsImpNewId,
	        importoVinc,
	        avavRiaccImpId,
    	    clock_timestamp(),
	        loginOperazione,
	        enteProprietarioId
        )
        returning movgest_ts_r_id into codResult;
        if codResult is null then
        	daCancellare:=true;
        else numeroVinc:=numeroVinc+1;
        end if;
	--   else 	daCancellare:=true;
   	   end if;

       totVincolato:=totVincolato+importoVinc;
  	   daVincolare:=importoVincoloRiaccertato-(totVincolato);
       raise notice 'daVincolare=%',daVincolare;

	   exit when daVincolare<=0 or daCancellare=true;
	end loop;
       raise notice 'daVincolare=%',daVincolare;
       raise notice 'daCancellare=%',daCancellare;

	if daCancellare=false and daVincolare>0 then
    	codResult:=null;
        strMessaggio:='Accertamento da riacc movgest_ts_id='||movgestTsAccPrecId::varchar
                    ||' - accertamento riacc movgest_ts_id='||movGestRec.movgest_ts_riacc_id::varchar
                    ||' - quota vincolo residuo='||daVincolare::varchar||'.';
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
		-- insert into
        codResult:=null;
	    insert into siac_r_movgest_ts
    	(
	        movgest_ts_b_id,
    	    avav_id,
	        movgest_ts_importo,
	        validita_inizio,
	        login_operazione,
	        ente_proprietario_id
	    )
	    values
	    (
	        movgestTsImpNewId,
	        avavRiaccImpId,
    	    daVincolare,
	        clock_timestamp(),
	        loginOperazione,
	        enteProprietarioId
	    )
        returning movgest_ts_r_id into codResult;
               raise notice 'codResult=%',codResult;

        if codResult is null then
	       	daCancellare:=true;
        else numeroVinc:=numeroVinc+1;
        end if;

	end if;

    if daCancellare = true then
    	codResult:=null;
        strMessaggio:='Accertamento da riacc movgest_ts_id='||movgestTsAccPrecId::varchar
                    ||' - accertamento riacc movgest_ts_id='||movGestRec.movgest_ts_riacc_id::varchar
                    ||' - annullamento quote inserite.';
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

    	delete  from siac_r_movgest_ts r
        where r.ente_proprietario_id=enteProprietarioId
        and   r.movgest_ts_b_id=movgestTsImpNewId
        and   r.login_operazione=loginOperazione
        and   r.data_cancellazione is null
        and   r.validita_fine is null;
        numeroVinc:=0;
    end if;

	strMessaggio:=' - Vincoli inseriti num='||numeroVinc::varchar;
	insert into fase_bil_t_elaborazione_log
	(fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
	)
	values
    (faseBilElabId,strMessaggioFinale||strMessaggio||' - FINE .',clock_timestamp(),loginOperazione,enteProprietarioId)
	returning fase_bil_elab_log_id into codResult;

	if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	end if;


    codiceRisultato:=0;
    numeroVincoliCreati:=numeroVinc;
    messaggioRisultato:=strMessaggioFinale||' FINE';
    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,coalesce(strMessaggio,'');
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_reimputa_vincoli (
  enteproprietarioid integer,
  annobilancio integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

	tipoMovGestId      integer:=null;
    tipoMovGestAccId   integer:=null;

    movGestTsTipoId    integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;

    periodoId         integer:=null;
    periodoPrecId     integer:=null;

    movGestStatoAId   integer:=null;

    movGestRec        record;
    resultRec        record;

    faseBilElabId     integer;
	movGestTsRIdRet   integer;
    numeroVincAgg     integer:=0;


	faseBilElabReimpId integer;
    faseBilElabReAccId integer;

    movgestAccCurRiaccId integer;
    movgesttsAccCurRiaccId  integer;

	bCreaVincolo boolean;
    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


	IMP_MOVGEST_TIPO CONSTANT varchar:='I';
    ACC_MOVGEST_TIPO CONSTANT varchar:='A';


    APE_GEST_REIMP     CONSTANT varchar:='APE_GEST_REIMP';
    APE_GEST_REIMP_VINC     CONSTANT varchar:='APE_GEST_REIMP_VINC';


    A_MOV_GEST_STATO  CONSTANT varchar:='A';


BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;


	strMessaggioFinale:='Apertura bilancio gestione.Reimputazione vincoli. Anno bilancio='||annoBilancio::varchar||'.';

    strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_REIMP_VINC||' IN CORSO.';
    select 1 into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP_VINC
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito like 'IN%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
    if codResult is not null then
        strMessaggio :=' Esistenza elaborazione reimputazione vincoli in corso.';
    	raise exception ' Esistenza elaborazione reimputazione vincoli in corso.';
    	return;
    end if;


    strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
    fase_bil_elab_tipo_id,
    ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE REIMPUTAZIONE VINCOLI IN CORSO.',tipo.fase_bil_elab_tipo_id,ente_proprietario_id, dataElaborazione, loginOperazione
    from fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteproprietarioid
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP_VINC
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null)
    returning fase_bil_elab_id into faseBilElabId;

     if faseBilElabId is null then
        strMessaggio  :=' Inserimento elaborazione per tipo APE_GEST_REIMP_VINC non effettuato.';
     	raise exception ' Inserimento elaborazione per tipo APE_GEST_REIMP_VINC non effettuato.';
     	return;
    end if;

    codResult:=null;
    strMessaggio:='Inserimento LOG.';
    raise notice 'strMesasggio=%',strMessaggio;
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||' - INIZO.',clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    -- per I
    strMessaggio:='Lettura id identificativo per tipoMovGest='||IMP_MOVGEST_TIPO||'.';
    select tipo.movgest_tipo_id into tipoMovGestId
    from siac_d_movgest_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code=IMP_MOVGEST_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
    if tipoMovGestId is null then
	    strMessaggio :=strMessaggio||'- Errore in lettura identificativo';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - '||upper(strMessaggio),
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    end if;

	strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
    select bil.bil_id , per.periodo_id into bilancioPrecId, periodoPrecId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio-1
    and   bil.data_cancellazione is null
    and   per.data_cancellazione is null;
    if bilancioPrecId is null then
	    strMessaggio :=strMessaggio||'- Errore in lettura identificativo';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - '||upper(strMessaggio),
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    end if;

	codResult:=null;
    strMessaggio:='Verifica elaborazione fase='||APE_GEST_REIMP||' per impegni.';
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
    select fase.fase_bil_elab_id into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
         fase_bil_t_reimputazione fasereimp
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito='OK'
    and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
    and   fasereimp.movgest_tipo_id=tipoMovGestId
    and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
    and   fasereimp.bil_id=bilancioPrecId -- bilancio precedente per elaborazione reimputazione su annoBilancio
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null
    order by fase.fase_bil_elab_id desc
    limit 1;

    if codResult is null then
        strMessaggio :='Elaborazione non effettuabile - Reimputazione impegni non eseguita.';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - ELABORAZIONE REIMPUTAZIONE IMPEGNI NON ESEGUITA.',
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    else faseBilElabReimpId:=codResult;
    end if;


    -- per A
    strMessaggio:='Lettura id identificativo per tipoMovGest='||ACC_MOVGEST_TIPO||'.';
    select tipo.movgest_tipo_id into tipoMovGestAccId
    from siac_d_movgest_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code=ACC_MOVGEST_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
	if tipoMovGestAccId is null then
	    strMessaggio :=strMessaggio||'- Errore in lettura identificativo';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - '||upper(strMessaggio),
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    end if;

	codResult:=null;
    strMessaggio:='Verifica elaborazione fase='||APE_GEST_REIMP||' per accertamenti.';
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
    select fase.fase_bil_elab_id into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
         fase_bil_t_reimputazione fasereimp
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito='OK'
    and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
    and   fasereimp.movgest_tipo_id=tipoMovGestAccId
    and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
    and   fasereimp.bil_id=bilancioPrecId -- bilancio precedente per elaborazione reimputazione su annoBilancio
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null
    order by fase.fase_bil_elab_id desc
    limit 1;

	if codResult is not null then
		 faseBilElabReaccId:=codResult;
    end if;



	strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
    select bil.bil_id , per.periodo_id into bilancioId, periodoId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio
    and   bil.data_cancellazione is null
    and   per.data_cancellazione is null;
	if bilancioId is null then
	    strMessaggio :=strMessaggio||'- Errore in lettura identificativo';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - '||upper(strMessaggio),
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    end if;

    strMessaggio:='Lettura id identificativo per movGestStatoA='||A_MOV_GEST_STATO||'.';
    select stato.movgest_stato_id into  movGestStatoAId
    from siac_d_movgest_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and   stato.movgest_stato_code=A_MOV_GEST_STATO
    and   stato.data_cancellazione is null
    and   stato.validita_fine is null;

	if movGestStatoAId is null then
	    strMessaggio :=strMessaggio||'- Errore in lettura identificativo';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - '||upper(strMessaggio),
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    end if;


    strMessaggio:='Inizio ciclo per elaborazione.';
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

     for movGestRec in
     (select  mov.movgest_anno::integer anno_impegno,
              mov.movgest_numero::integer numero_impegno,
              (case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) numero_subimpegno,
              fasevinc.movgest_ts_b_id,
              fasevinc.movgest_ts_a_id,
              fasevinc.movgest_ts_r_id,
              fasevinc.mod_id,
              fasevinc.importo_vincolo,
              fasevinc.avav_id,
              fasevinc.avav_new_id,
              fasevinc.importo_vincolo_new,
              mov.movgest_id,ts.movgest_ts_id,
              fasevinc.reimputazione_vinc_id
	  from siac_t_movgest mov ,
	       siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
	       siac_r_movgest_ts_stato rs,
	       fase_bil_t_reimputazione fase, fase_bil_t_reimputazione_vincoli fasevinc
	  where mov.bil_id=bilancioId
	  and   mov.movgest_tipo_id=tipoMovGestId
	  and   ts.movgest_id=mov.movgest_id
	  and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
	  and   rs.movgest_ts_id=ts.movgest_ts_id
      and   rs.movgest_stato_id!=movGestStatoAId
	  and   fase.fasebilelabid=faseBilElabReImpId
	  and   fase.movgestnew_ts_id=ts.movgest_ts_id
	  and   fase.movgest_tipo_id=mov.movgest_tipo_id
	  and   fase.fl_elab is not null and fase.fl_elab!=''
	  and   fase.fl_elab='S'
      and   fasevinc.fasebilelabid=fase.fasebilelabid
      and   fasevinc.reimputazione_id=fase.reimputazione_id
      and   fasevinc.fl_elab is null -- non elaborato e non scartato
	  and   rs.data_cancellazione is null
	  and   rs.validita_fine is null
	  and   mov.data_cancellazione is null
	  and   mov.validita_fine is null
	  and   ts.data_cancellazione is null
	  and   ts.validita_fine is null
      order by mov.movgest_anno::integer ,
               mov.movgest_numero::integer,
               (case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end),
               fasevinc.movgest_ts_b_id,
               coalesce(fasevinc.movgest_ts_a_id,0)
     )
     loop

        codResult:=null;
	    movgestAccCurRiaccId:=null;
	    movgesttsAccCurRiaccId :=null;
	    movGestTsRIdRet:=null;
		bCreaVincolo:=false;

        strMessaggio:='Impegno anno='||movGestRec.anno_impegno||
                      ' numero='||movGestRec.numero_impegno||
                      ' subnumero='||movGestRec.numero_subimpegno||
                      ' movgest_ts_new_id='||movGestRec.movgest_ts_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_b_id||
                      ' movgest_ts_r_id='||movGestRec.movgest_ts_r_id||
                      ' movgest_ts_a_id='||coalesce(movGestRec.movgest_ts_a_id,0)||'.';

        raise notice 'strMessaggio=%  movGestRec.movgest_new_id=%', strMessaggio, movGestRec.movgest_ts_id;
		insert into fase_bil_t_elaborazione_log
	    (fase_bil_elab_id,fase_bil_elab_log_operazione,
    	 validita_inizio, login_operazione, ente_proprietario_id
	    )
	    values
    	(faseBilElabId,strMessaggio||' - INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
	    returning fase_bil_elab_log_id into codResult;

	    if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	    end if;

        -- caso 1,2
		if movGestRec.movgest_ts_a_id is null then
            bCreaVincolo:=true;
        end if;

        /* caso 3
  		   se il vincolo abbattuto era legato ad un accertamento
		   che non presenta quote riaccertate esso stesso:
		   creare un vincolo nel nuovo bilancio di tipo FPV per la quote di vincolo abbattuta
		   con tipo spesa corrente o conto capitale in base al titolo di spesa dell'impegno (vedi algoritmo a seguire)
        */
        /* caso 4
		 se il vincolo abbattuto era legato ad un accertamento che presenta quote riaccertate:
		 creare un vincolo nel nuovo bilancio per la parte di vincolo abbattuta a capienza dell'utilizzabile
		 (utilizzabile - somma altri vincoli) del ogni nuovo acc. riaccertato con anno_accertamento<=anno_impegno
		 Per la restante parte creare un vincolo di tipo FPV con tipo spesa corrente o conto capitale in base al titolo di
		 spesa dell'impegno (vedi algoritmo a seguire) */
        if movGestRec.movgest_ts_a_id is not null then
            codResult:=null;
            strMessaggio:=strMessaggio||' - caso con accertamento verifica esistenza quota riacc.';
            raise notice 'strMessaggio=%',strMessaggio;
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

        	with
             accPrec as
             (
        	  select mov.movgest_anno::integer anno_accertamento,
              mov.movgest_numero::integer numero_accertamento,
              (case when tstipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) numero_subaccertamento,
              mov.movgest_id, ts.movgest_ts_id
              from siac_t_movgest mov, siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tstipo,
             	   siac_r_movgest_ts_stato rs
              where mov.bil_id=bilancioPrecId
              and   mov.movgest_tipo_id=tipoMovGestAccId
              and   ts.movgest_id=mov.movgest_id
              and   ts.movgest_ts_id=movGestRec.movgest_ts_a_id
              and   rs.movgest_ts_id=ts.movgest_ts_id
              and   rs.movgest_stato_id!=movGestStatoAId
              and   rs.data_cancellazione is null
              and   rs.validita_fine is null
              and   mov.data_cancellazione is null
              and   mov.validita_fine is null
              and   ts.data_cancellazione is null
              and   ts.validita_fine is null
             ),
             accCurRiacc as
             (
              select mov.movgest_anno::integer anno_accertamento,
	                 mov.movgest_numero::integer numero_accertamento,
       			    (case when tstipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) numero_subaccertamento,
	                mov.movgest_id movgest_new_id, ts.movgest_ts_id movgest_ts_new_id,fase.movgest_ts_id
              from siac_t_movgest mov, siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tstipo,
             	   siac_r_movgest_ts_stato rs, fase_bil_t_reimputazione fase
              where mov.bil_id=bilancioId
              and   mov.movgest_tipo_id=tipoMovGestAccId
              and   ts.movgest_id=mov.movgest_id
              and   rs.movgest_ts_id=ts.movgest_ts_id
              and   rs.movgest_stato_id!=movGestStatoAId
              and   fase.fasebilelabid=faseBilElabReAccId
              and   fase.fl_elab is not null and fase.fl_elab!=''
	    	  and   fase.fl_elab='S'
              and   ts.movgest_ts_id=fase.movgestnew_ts_id  -- nuovo accertamento riaccertato con anno_accertamento<=anno_impegno nuovo
              and   mov.movgest_anno::integer<=movGestRec.anno_impegno
              and   rs.data_cancellazione is null
              and   rs.validita_fine is null
              and   mov.data_cancellazione is null
              and   mov.validita_fine is null
              and   ts.data_cancellazione is null
              and   ts.validita_fine is null
             )
             select  accCurRiacc.movgest_new_id, accCurRiacc.movgest_ts_new_id
                     into movgestAccCurRiaccId, movgesttsAccCurRiaccId
             from accPrec, accCurRiacc
             where accPrec.movgest_ts_id=accCurRiacc.movgest_ts_id
             limit 1;


			 if movgestAccCurRiaccId is null or movgesttsAccCurRiaccId is null then
             	-- caso 3
                bCreaVincolo:=true;

             else
   	            codResult:=null;
	            strMessaggio:=strMessaggio||' - caso con accertamento e quota riacc.';
                            raise notice 'strMessaggio=%',strMessaggio;

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


                -- caso 4
                -- inserire nuovi vincoli con algoritmo descritto in JIRA per il caso 4
                --- vedere algoritmo
                /* caso 4
		 se il vincolo abbattuto era legato ad un accertamento che presenta quote riaccertate:
		 creare un vincolo nel nuovo bilancio per la parte di vincolo abbattuta a capienza dell'utilizzabile
		 (utilizzabile - somma altri vincoli) del ogni nuovo acc. riaccertato con anno_accertamento<=anno_impegno
		 Per la restante parte creare un vincolo di tipo FPV con tipo spesa corrente o conto capitale in base al titolo di
		 spesa dell'impegno (vedi algoritmo a seguire) */
               select * into resultRec
               from  fnc_fasi_bil_gest_reimputa_vincoli_acc
               (
				  enteProprietarioId,
				  annoBilancio,
				  faseBilElabId,
				  movGestRec.anno_impegno,        -- annoImpegnoRiacc integer,   -- annoImpegno riaccertato
				  movGestRec.movgest_ts_id,       -- movgestTsImpNewId integer,  -- movgest_id_id impegno riaccertato
				  movGestRec.avav_new_id,         -- avavRiaccImpId   integer,        -- avav_id nuovo
				  movGestRec.importo_vincolo_new, -- importoVincoloRiaccertato numeric, -- importo totale vincolo impegno riaccertato
				  faseBilElabReAccId,             -- faseId di elaborazione riaccertmaento Acc
				  tipoMovGestAccId,               -- tipoMovGestId Accertamenti
				  movGestRec.movgest_ts_a_id,     -- movgestTsAccPrecId integer, -- movgest_ts_id accertamento anno precedente vincolato a impegno riaccertato
				  loginOperazione,
				  dataElaborazione
                );
                if resultRec.codiceRisultato=0 then
                	numeroVincAgg:=numeroVincAgg+resultRec.numeroVincoliCreati;

                    strMessaggio:='Aggiornamento fase_bil_t_reimputazione_vincoli in fase di reimputazione nuovo vincolo.';
                	update fase_bil_t_reimputazione_vincoli fase
	                set    fl_elab='S',
    	                   movgest_ts_b_new_id=movGestRec.movgest_ts_id,
    --    	               movgest_ts_r_new_id=movGestTsRIdRet, non impostato poiche multiplo verso diversi accertamenti pluri
            	       	   bil_new_id=bilancioId
	            	where fase.reimputazione_vinc_id=movGestRec.reimputazione_vinc_id;
                else
                	strMessaggio:='Aggiornamento fase_bil_t_reimputazione_vincoli per scarto in fase di reimputazione nuovo vincolo.';
            		update fase_bil_t_reimputazione_vincoli fase
	                set    fl_elab='X',
			               movgest_ts_b_new_id=movGestRec.movgest_ts_id,
        	        	   bil_new_id=bilancioId,
	        	           scarto_code='99',
                	       scarto_desc='VINCOLO NUOVO NON CREATO IN FASE DI REIMPUTAZIONE'
	            	where fase.reimputazione_vinc_id=movGestRec.reimputazione_vinc_id;
                end if;
	         end if;

        end if;


	   if bCreaVincolo=true then
            codResult:=null;
            strMessaggio:=strMessaggio||' - inserimento vincolo senza accertamento vincolato.';
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


       		-- inserimento siac_t_movgest_ts_r nuovo con i dati presenti in fase_bil_t_reimputazione_vincoli
            -- aggiornamento di fase_bil_t_reimputazione_vincoli
            insert into siac_r_movgest_ts
            (
		        movgest_ts_b_id,
			    movgest_ts_importo,
                avav_id,
                validita_inizio,
                login_operazione,
                ente_proprietario_id
            )
            values
            (
            	movGestRec.movgest_ts_id,
                movGestRec.importo_vincolo_new,
                movGestRec.avav_new_id,
                clock_timestamp(),
                loginOperazione,
                enteProprietarioId
            )
            returning movgest_ts_r_id into movGestTsRIdRet;

            if movGestTsRIdRet is null then
            	strMessaggio:='Aggiornamento fase_bil_t_reimputazione_vincoli per scarto in fase di reimputazione nuovo vincolo.';
            	update fase_bil_t_reimputazione_vincoli fase
                set    fl_elab='X',
		               movgest_ts_b_new_id=movGestRec.movgest_ts_id,
                	   bil_new_id=bilancioId,
	                   scarto_code='99',
                       scarto_desc='VINCOLO NUOVO NON CREATO IN FASE DI REIMPUTAZIONE'
            	where fase.reimputazione_vinc_id=movGestRec.reimputazione_vinc_id;

            else
            	numeroVincAgg:=numeroVincAgg+1;
                strMessaggio:='Aggiornamento fase_bil_t_reimputazione_vincoli in fase di reimputazione nuovo vincolo.';
                update fase_bil_t_reimputazione_vincoli fase
                set    fl_elab='S',
                       movgest_ts_b_new_id=movGestRec.movgest_ts_id,
                       movgest_ts_r_new_id=movGestTsRIdRet,
                   	   bil_new_id=bilancioId
            	where fase.reimputazione_vinc_id=movGestRec.reimputazione_vinc_id;
            end if;
       end if;



       strMessaggio:='Impegno anno='||movGestRec.anno_impegno||
                      ' numero='||movGestRec.numero_impegno||
                      ' subnumero='||movGestRec.numero_subimpegno||
                      ' movgest_ts_new_id='||movGestRec.movgest_ts_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_b_id||
                      ' movgest_ts_r_id='||movGestRec.movgest_ts_r_id||
                      ' movgest_ts_a_id='||coalesce(movGestRec.movgest_ts_a_id,0)||'.';

        raise notice 'strMessaggio=%  movGestRec.movgest_new_id=%', strMessaggio, movGestRec.movgest_ts_id;
		insert into fase_bil_t_elaborazione_log
	    (fase_bil_elab_id,fase_bil_elab_log_operazione,
    	 validita_inizio, login_operazione, ente_proprietario_id
	    )
	    values
    	(faseBilElabId,strMessaggio||' - FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	    returning fase_bil_elab_log_id into codResult;

	    if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	    end if;

     end loop;



     strMessaggio:='Aggiornamento stato fase bilancio OK.';
     update fase_bil_t_elaborazione
     set fase_bil_elab_esito='OK',
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_REIMP_VINC||
                                 ' OK. INSERITI NUOVI VINCOLI NUM='||
                                 coalesce(numeroVincAgg,0)||'.'
     where fase_bil_elab_id=faseBilElabId;

     strMessaggio:='Aggiornamento fase_bil_elab_coll_id su elaborazione riacc. impegni.';
	 update fase_bil_t_elaborazione fase
     set    fase_bil_elab_coll_id=faseBilElabId,
            data_modifica=now()
     where fase.fase_bil_elab_id=faseBilElabReimpId;

     strMessaggio:='Aggiornamento fase_bil_elab_coll_id su elaborazione riacc. accertamenti.';
	 update fase_bil_t_elaborazione fase
     set    fase_bil_elab_coll_id=faseBilElabId,
            data_modifica=now()
     where fase.fase_bil_elab_id=faseBilElabReAccId;


     codiceRisultato:=0;
     messaggioRisultato:=strMessaggioFinale||' FINE';
     return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,coalesce(strMessaggio,'');
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


-- SIAC-5368 Sofia 19.02.2018 - FINE