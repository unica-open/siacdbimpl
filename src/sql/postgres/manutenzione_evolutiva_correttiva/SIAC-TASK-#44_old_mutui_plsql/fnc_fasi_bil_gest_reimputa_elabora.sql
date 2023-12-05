/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿
 drop  FUNCTION if exists siac.fnc_fasi_bil_gest_reimputa_elabora (
  p_fasebilelabid integer,
  enteproprietarioid integer,
  annobilancio integer,
  impostaprovvedimento boolean,
  loginoperazione varchar,
  dataelaborazione timestamp,
  p_movgest_tipo_code varchar,
  motivo varchar,
  out outfasebilelabretid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar);
  
CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_reimputa_elabora (
  p_fasebilelabid integer,
  enteproprietarioid integer,
  annobilancio integer,
  impostaprovvedimento boolean,
  loginoperazione varchar,
  dataelaborazione timestamp,
  p_movgest_tipo_code varchar,
  motivo varchar,
  out outfasebilelabretid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
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
-- SIAC-6997 ---------------- INIZIO --------------------
	DAREANNO_ATTR CONSTANT varchar:='flagDaReanno';
    v_flagdareanno_attr_id  integer:=null;
-- SIAC-6997 ---------------- FINE --------------------
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

-- SIAC-6997 ---------------- INIZIO --------------------

    SELECT attr.attr_id
    INTO   v_flagdareanno_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code = DAREANNO_ATTR
    AND    attr.ente_proprietario_id = enteproprietarioid;

-- SIAC-6997 ---------------- FINE --------------------

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
                  importo_reimputato, -- 05.06.2020 Sofia SIAC-7593
                  importo_modifica_entrata, -- 05.06.2020 Sofia SIAC-7593
                  coll_mod_entrata,  -- 05.06.2020 Sofia SIAC-7593
                  elem_det_comp_tipo_id, -- 05.06.2020 Sofia SIAC-7593
                  login_operazione ,
                  ente_proprietario_id,
                  siope_tipo_debito_id,
		          siope_assenza_motivazione_id
           FROM   fase_bil_t_reimputazione
           WHERE  ente_proprietario_id = enteproprietarioid
           AND    fasebilelabid = p_fasebilelabid
           AND    fl_elab = 'N'
           order by  1) -- 19.04.2019 Sofia JIRA SIAC-6788
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
          AND    siac_t_progressivo.prog_key = 'imp_'||movgestrec.mtdm_reimputazione_anno::VARCHAR
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
                        'imp_'||movgestrec.mtdm_reimputazione_anno::VARCHAR,
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
            AND    siac_t_progressivo.ente_proprietario_id = enteproprietarioid
            AND    siac_t_progressivo.prog_key = 'imp_'||movgestrec.mtdm_reimputazione_anno::VARCHAR
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
          AND    siac_t_progressivo.ente_proprietario_id = enteproprietarioid
          AND    siac_t_progressivo.prog_key = 'acc_'||movgestrec.mtdm_reimputazione_anno::VARCHAR
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
            AND    siac_t_progressivo.ente_proprietario_id = enteproprietarioid
            AND    siac_t_progressivo.prog_key = 'acc_'||movgestrec.mtdm_reimputazione_anno::VARCHAR
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
          elem_det_comp_tipo_id, -- 05.06.2020 Sofia SIAC-7593
          validita_inizio,
          ente_proprietario_id,
          login_operazione
        )
        VALUES
        (
          movgestidret,
          v_elemid,--movGestRec.elemId_old,
          -- 05.06.2020 Sofia SIAC-7593
          (case when p_movgest_tipo_code='I' then movgestrec.elem_det_comp_tipo_id else null end ),
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
--        and   fase_bil_t_reimputazione.fasebilelabid=370 -- Sofia 27.04.2021 Jira SIAC-8175 per elaborare solo sub impostare elabId dei movimenti padre
--        and   fase_bil_t_reimputazione.fasebilelabid=369 -- Sofia 27.04.2021 Jira SIAC-8175 per elaborare solo sub impostare elabId dei movimenti padre
        AND    fase_bil_t_reimputazione.mod_tipo_code =  movgestrec.mod_tipo_code
        AND    fase_bil_t_reimputazione.tipo = 'T'
        and    fase_bil_t_reimputazione.mtdm_reimputazione_anno=movgestrec.mtdm_reimputazione_anno -- 28.02.2018 Sofia jira siac-5964
       and    (case when p_movgest_tipo_code='I'  -- 08.06.2020 Sofia Jira siac-7593
---                  then fase_bil_t_reimputazione.elem_det_comp_tipo_id= movgestrec.elem_det_comp_tipo_id - Sofia 27.04.2021 Jira SIAC-8175
	 				 --- Sofia 27.04.2021  modifica per sbloccare sub	SIAC-8175
	                 then fase_bil_t_reimputazione.elem_det_comp_tipo_id = fase_bil_t_reimputazione.elem_det_comp_tipo_id  
                     else p_movgest_tipo_code='A' end);

 --       raise notice 'strMessaggio anno=% numero=% v_numero_el=%', movgestrec.movgest_anno, movgestrec.movgest_numero,v_numero_el;

        SELECT fase_bil_t_reimputazione.movgestnew_id ,
               fase_bil_t_reimputazione.movgestnew_ts_id
        INTO strict  movgestidret ,
               v_movgest_ts_id
        FROM   fase_bil_t_reimputazione
        WHERE  fase_bil_t_reimputazione.movgest_anno = movgestrec.movgest_anno
        AND    fase_bil_t_reimputazione.movgest_numero = movgestrec.movgest_numero
        AND    fase_bil_t_reimputazione.fasebilelabid = p_fasebilelabid
--        and    fase_bil_t_reimputazione.fasebilelabid=370 -- Sofia 27.04.2021 Jira SIAC-8175 per elaborare solo sub impostare elabId dei movimenti padre
--        and    fase_bil_t_reimputazione.fasebilelabid=369 -- Sofia 27.04.2021 Jira SIAC-8175 per elaborare solo sub impostare elabId dei movimenti padre

        AND    fase_bil_t_reimputazione.mod_tipo_code =  movgestrec.mod_tipo_code
        AND    fase_bil_t_reimputazione.tipo = 'T'
        and    fase_bil_t_reimputazione.mtdm_reimputazione_anno=movgestrec.mtdm_reimputazione_anno -- 28.02.2018 Sofia jira siac-5964
	    and    (case when p_movgest_tipo_code='I'  -- 08.06.2020 Sofia Jira siac-7593
--                      then fase_bil_t_reimputazione.elem_det_comp_tipo_id= movgestrec.elem_det_comp_tipo_id - Sofia 27.04.2021 Jira SIAC-8175
				     --- Sofia 27.04.2021 modifica per sbloccare sub Jira SIAC-8175
                     then fase_bil_t_reimputazione.elem_det_comp_tipo_id = fase_bil_t_reimputazione.elem_det_comp_tipo_id  
                     else p_movgest_tipo_code='A' end)
        order by fase_bil_t_reimputazione.fasebilelabid  -- Sofia 27.04.2021 modifica per sbloccare sub
        limit 1;   -- Sofia 27.04.2021 modifica per sbloccare sub Jira SIAC-8175

   --  raise notice 'strMessaggio anno=% numero=% movgestidret=%', movgestrec.movgest_anno, movgestrec.movgest_numero,movgestidret;
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
      -- 05.06.2020 Sofia Jira SIAC-7593
      --v_importomodifica := movgestrec.importomodifica * -1;
      -- 05.06.2020 Sofia Jira SIAC-7593
      v_importomodifica:= movgestrec.importo_reimputato;
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
                                       'numeroRiaccertato',
									   'flagDaReanno') ); -- 02.10.2020 SIAC-7593

-- SIAC-6997 ---------------- INIZIO --------------------
    if motivo = 'REIMP' then
-- SIAC-6997 ---------------- FINE --------------------

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
-- SIAC-6997 ---------------- INIZIO --------------------
    else
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
				  v_flagdareanno_attr_id ,
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
    end if;
-- SIAC-6997 ----------------  FINE --------------------

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
      -- 07.02.2023 Sofia Jira SIAC-8895
      if motivo = 'REANNO' then
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
			 AND    r.validita_fine IS NULL 
	  );
	 else -- 07.02.2023 Sofia Jira SIAC-8895
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
					           pNew.programma_id,
		  					   datainizioval,
					           enteproprietarioid,
					           loginoperazione
			 FROM   siac_r_movgest_ts_programma r,
			  			    siac_t_programma prog,siac_t_programma pNew,siac_r_programma_stato rs,siac_d_programma_stato stato
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND         prog.programma_id=r.programma_id
			 and           pNew.bil_id =bilancioId 
			 and           pNew.programma_tipo_id =prog.programma_tipo_id 
			 and           pNew.programma_code =prog.programma_code 
			 and           rs.programma_id=pNew.programma_id 
			 and           stato.programma_stato_id=rs.programma_stato_id 
			 and           stato.programma_stato_code ='VA'
			 AND         prog.data_cancellazione IS NULL
			 AND         prog.validita_fine IS NULL
			 AND         r.data_cancellazione IS NULL
			 AND         r.validita_fine IS NULL 
			 AND         pNew.data_cancellazione IS NULL
			 AND         pNew.validita_fine IS null
			 AND         rs.data_cancellazione IS NULL
			 AND         rs.validita_fine IS NULL
	  );
	 end if;

     --- 18.06.2019 Sofia SIAC-6702
	 if p_movgest_tipo_code=imp_movgest_tipo then
      -- siac_r_movgest_ts_storico_imp_acc
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_storico_imp_acc].';
      INSERT INTO siac_r_movgest_ts_storico_imp_acc
	  (
			movgest_ts_id,
            movgest_anno_acc,
            movgest_numero_acc,
            movgest_subnumero_acc,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.movgest_anno_acc,
             		r.movgest_numero_acc,
		            r.movgest_subnumero_acc,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_storico_imp_acc r
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );
      end if;

      /* 16.03.2023 Sofia SIAC-TASK-#44
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
	  */
	  
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
	 and   mov.movgest_anno::INTEGER=annoBilancio
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
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


alter function  siac.fnc_fasi_bil_gest_reimputa_elabora 
(   integer, integer, integer, boolean, varchar, timestamp, varchar,varchar,
    out  integer,  out integer, out  varchar) owner to siac;