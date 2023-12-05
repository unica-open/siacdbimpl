/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-5964 Sofia 28.02.2018  -INIZIO

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
        AND    fase_bil_t_reimputazione.tipo = 'T'
        and    fase_bil_t_reimputazione.mtdm_reimputazione_anno=movgestrec.mtdm_reimputazione_anno; -- 28.02.2018 Sofia jira siac-5964
        raise notice 'strMessaggio anno=% numero=% v_numero_el=%', movgestrec.movgest_anno, movgestrec.movgest_numero,v_numero_el;

        SELECT fase_bil_t_reimputazione.movgestnew_id ,
               fase_bil_t_reimputazione.movgestnew_ts_id
        INTO strict  movgestidret ,
               v_movgest_ts_id
        FROM   fase_bil_t_reimputazione
        WHERE  fase_bil_t_reimputazione.movgest_anno = movgestrec.movgest_anno
        AND    fase_bil_t_reimputazione.movgest_numero = movgestrec.movgest_numero
        AND    fase_bil_t_reimputazione.fasebilelabid = p_fasebilelabid
        AND    fase_bil_t_reimputazione.mod_tipo_code =  movgestrec.mod_tipo_code
        AND    fase_bil_t_reimputazione.tipo = 'T'
        and    fase_bil_t_reimputazione.mtdm_reimputazione_anno=movgestrec.mtdm_reimputazione_anno; -- 28.02.2018 Sofia jira siac-5964



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
  $body$ LANGUAGE 'plpgsql' volatile called ON NULL input security invoker cost 100;

-- SIAC-5964 Sofia 28.02.2018  - FINE

-- SIAC-5849 - Sofia 01.03.2018 - INIZIO

--- Flusso mandati-reversali tag natura_spesa_siope

create table if not exists siac_d_oil_natura_spesa
(
	oil_natura_spesa_id   serial,
    oil_natura_spesa_code varchar,
    oil_natura_spesa_desc varchar,
    validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	validita_fine TIMESTAMP WITHOUT TIME ZONE,
	ente_proprietario_id INTEGER NOT NULL,
	data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
	login_operazione VARCHAR(200) NOT NULL
);

create table if not exists siac_r_oil_natura_spesa_titolo
(
	oil_natura_spesa_rel_id    serial,
    oil_natura_spesa_id        integer,
    oil_natura_spesa_titolo_id integer,
    validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	validita_fine TIMESTAMP WITHOUT TIME ZONE,
	ente_proprietario_id INTEGER NOT NULL,
	data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
	login_operazione VARCHAR(200) NOT NULL
);

insert into siac_d_oil_natura_spesa
(oil_natura_spesa_code,oil_natura_spesa_desc,validita_inizio,login_operazione,ente_proprietario_id)
select '1','CORRENTE',now(),'admin-siope+',e.ente_proprietario_id
from siac_t_ente_proprietario e
where not exists
(select 1 from siac_d_oil_natura_spesa d
 where d.ente_proprietario_id=e.ente_proprietario_id
 and   d.oil_natura_spesa_code='1');

insert into siac_d_oil_natura_spesa
(oil_natura_spesa_code,oil_natura_spesa_desc,validita_inizio,login_operazione,ente_proprietario_id)
select '2','CAPITALE',now(),'admin-siope+',e.ente_proprietario_id
from siac_t_ente_proprietario e
where not exists
(select 1 from siac_d_oil_natura_spesa d
 where d.ente_proprietario_id=e.ente_proprietario_id
 and   d.oil_natura_spesa_code='2');

 insert into siac_r_oil_natura_spesa_titolo
(
	oil_natura_spesa_id,
    oil_natura_spesa_titolo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select oil.oil_natura_spesa_id,
       c.classif_id,
       now(),
       'admin-siope+',
       tipo.ente_proprietario_id
from siac_d_oil_natura_spesa oil , siac_t_class c ,siac_d_class_tipo tipo
where tipo.classif_tipo_code='TITOLO_SPESA'
and   c.classif_tipo_id=tipo.classif_tipo_id
and   c.classif_code in ('1','4')
and   oil.ente_proprietario_id=tipo.ente_proprietario_id
and   oil.oil_natura_spesa_code='1'
and   not exists
(select 1 from  siac_r_oil_natura_spesa_titolo r
 where  r.ente_proprietario_id=tipo.ente_proprietario_id
 and    r.oil_natura_spesa_titolo_id=c.classif_id
 and    r.oil_natura_spesa_id=oil.oil_natura_spesa_id
 and    r.data_cancellazione is null
 and    r.validita_fine is null);

 
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_default='CAPITALE',
       flusso_elab_mif_param=null
where mif.flusso_elab_mif_code='natura_spesa_siope'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
);

update mif_d_flusso_elaborato mif
set    flusso_elab_mif_default='CAPITALE',
       flusso_elab_mif_param='MACROAGGREGATO|Spesa - TitoliMacroaggregati'
where mif.flusso_elab_mif_code='natura_spesa_siope'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
);

 --- Flusso mandati-reversali tag destinazione
--- attivazione e valorizzazione solo per CMTO

alter table if exists mif_r_conto_tesoreria_vincolato
alter column vincolato TYPE varchar(50);

--select * from fnc_dba_add_column_params ('mif_r_conto_tesoreria_vincolato', 'vincolato' , 'varchar(50)');

update mif_d_flusso_elaborato mif
set    flusso_elab_mif_attivo=true,
       flusso_elab_mif_xml_out=true
where mif.flusso_elab_mif_code='destinazione'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code in ('REVMIF_SPLUS','MANDMIF_SPLUS')
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
)
and   exists
(
select 1 from  siac_r_sistema_esterno_ente r
where r.ente_proprietario_id=mif.ente_proprietario_id
and   r.extsys_ente_code='CMTO'
);

update mif_r_conto_tesoreria_vincolato  rs
set    vincolato='LIBERA'
from siac_t_ente_proprietario e
where rs.ente_proprietario_id=e.ente_proprietario_id
and   rs.vincolato='L'
and   exists
(
select 1 from  siac_r_sistema_esterno_ente r
where r.ente_proprietario_id=e.ente_proprietario_id
and   r.extsys_ente_code='CMTO'
);

update mif_r_conto_tesoreria_vincolato  rs
set    vincolato='VINCOLATA'
from siac_t_ente_proprietario e
where rs.ente_proprietario_id=e.ente_proprietario_id
and   rs.vincolato='V'
and   exists
(
select 1 from  siac_r_sistema_esterno_ente r
where r.ente_proprietario_id=e.ente_proprietario_id
and   r.extsys_ente_code='CMTO'
);

CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_documenti_splus( ordinativoId integer,
 													           numeroDocumenti integer,
                                                               tipiDocumento   varchar,
                                                               docAnalogico    varchar,
                                                               attrCodeDataScad varchar,
                                                               titoloCap        varchar,
                                                               codicePccUfficio varchar,
                                                   	           enteProprietarioId integer,
                                                               dataElaborazione timestamp,
                                                               dataFineVal timestamp)
RETURNS TABLE
(
    codice_ipa_ente_siope           varchar,
    tipo_documento_siope            varchar,
    tipo_documento_siope_a           varchar,
    identificativo_lotto_sdi_siope  varchar,
    tipo_documento_analogico_siope  varchar,
    codice_fiscale_emittente_siope  varchar,
    anno_emissione_fattura_siope    varchar,
    numero_fattura_siope  	        varchar,
    importo_siope                   varchar,
    importo_siope_split             varchar, -- 22.12.2017 Sofia siac-5665
    data_scadenza_pagam_siope       varchar,
    motivo_scadenza_siope           varchar,
    natura_spesa_siope              varchar

 ) AS
$body$
DECLARE

strMessaggio varchar(1500):=null;
documentiRec record;


motivoScadenza    varchar(500):=null;
dataScadDopoSosp  varchar(500):=null;
tipoDocAnalogico  varchar(500):=null;
codFiscElettronico varchar(100):=null;

DOC_TIPO_ALG      CONSTANT varchar:='ALG';

numeroDocs integer:=1;

tipoDocFPR   varchar(10):=null;
tipoGruppoDocFAT   varchar(10):=null;
tipoGruppoDocNCD   varchar(10):=null;

docPrincId integer:=null;
countNcdCalc integer:=0;
importoNcd numeric:=0;
importoDoc numeric:=0;
importoNcdRipart numeric:=0;

-- 15.01.2018 Sofia JIRA siac-5765
codiceFiscaleDef varchar(50):=null;

-- 26.02.2018 Sofia JIRA siac-5849
escludiNCD VARCHAR(10):=null;

BEGIN

 strMessaggio:='Lettura documenti collegati.';

 codice_ipa_ente_siope:=null;
 tipo_documento_siope:=null;
 tipo_documento_siope_a:=null;

 identificativo_lotto_sdi_siope:=null;
 tipo_documento_analogico_siope:=null;
 codice_fiscale_emittente_siope:=null;
 anno_emissione_fattura_siope:=null;
 numero_fattura_siope:=null;
 importo_siope:=null;
 importo_siope_split:=null; -- 22.12.2017 Sofia siac-5665
 data_scadenza_pagam_siope:=null;
 motivo_scadenza_siope:=null;
 natura_spesa_siope:=null;


 strMessaggio:='Lettura documenti collegati.Inizio ciclo lettura.';
 --raise notice 'strMessaggio =%',strMessaggio;

 tipoDocFPR:=trim (both ' ' from split_part(tipiDocumento,'|',1));

 tipoGruppoDocFAT:=trim (both ' ' from split_part(tipiDocumento,'|',2));
 tipoGruppoDocFAT:=trim (both ' ' from split_part(tipoGruppoDocFAT,',',1));


 tipoGruppoDocNCD:=trim (both ' ' from split_part(tipiDocumento,'|',2));
 tipoGruppoDocNCD:=trim (both ' ' from split_part(tipoGruppoDocNCD,',',2));



 escludiNCD:=trim (both ' ' from split_part(titoloCap,'|',2));
 if escludiNCD is not null and escludiNCD!='' and escludiNCD='S' then
 	   -- esclusione note di credito da estrazione documenti
       -- per ordinativi di entrata SPLIT
 else
       escludiNCD:='N';
 end if;
 titoloCap:=trim(both ' ' from split_part(titoloCap,'|',1));



 --raise notice 'tipoDocFPR =%',tipoDocFPR;
 --raise notice 'tipoGruppoDocFAT =%',tipoGruppoDocFAT;
 --raise notice 'tipoGruppoDocNCD =%',tipoGruppoDocNCD;

 /* 15.01.2018 Sofia JIRA SIAC-5765 */

 raise notice 'docAnalogico=%',docAnalogico;
 codiceFiscaleDef:=trim (both ' ' from split_part(docAnalogico,'|',2));
 docAnalogico:=trim (both ' ' from split_part(docAnalogico,'|',1));

 raise notice 'docAnalogico=%',docAnalogico;
 raise notice 'codiceFiscaleDef=%',codiceFiscaleDef;


/* for documentiRec in
 ( select doc.doc_anno annoDoc, doc.doc_numero numeroDoc, tipo.doc_tipo_code tipoDoc,
          lpad(extract('day' from doc.doc_data_emissione)::varchar,2,'0')||'/'||
          lpad(extract('month' from doc.doc_data_emissione)::varchar,2,'0')||'/'||
          extract('year' from doc.doc_data_emissione) dataDoc,
          sog.codice_fiscale codfiscDoc, sog.partita_iva partivaDoc,
          doc.doc_id docId,
          doc.pccuff_id pccuffId,
          subdoc.subdoc_data_scadenza datascadDoc,
          doc.siope_documento_tipo_id siopeDocTipoId,
          doc.doc_sdi_lotto_siope  siopeSdiLotto,
          doc.siope_documento_tipo_analogico_id siopeDocAnTipoId,
          sum(subdoc.subdoc_importo) importoDoc
   from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
        siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
        siac_r_doc_sog rsog, siac_t_soggetto sog
   where ordts.ord_id=ordinativoId
   and   subdocts.ord_ts_id=ordts.ord_ts_id
   and   subdoc.subdoc_id=subdocts.subdoc_id
   and   doc.doc_id=subdoc.doc_id
   and   tipo.doc_tipo_id=doc.doc_tipo_id
--   and   fnc.isCommerciale=true
   and   fnc_mif_isDocumentoCommerciale_splus(doc.doc_id,tipoDocFPR,tipoGruppoDocFAT,tipoGruppoDocNCD)=true -- 'FPR','FAT','NCD')=true
   and   tipo.doc_tipo_code!=DOC_TIPO_ALG
   and   rsog.doc_id=doc.doc_id
   and   sog.soggetto_id=rsog.soggetto_id
   and   ordts.data_cancellazione is null and ordts.validita_fine is null
   and   subdocts.data_cancellazione is null AND subdocts.validita_fine is null
   and   subdoc.data_cancellazione is null and subdoc.validita_fine is null
   and   doc.data_cancellazione is null and doc.validita_fine is null
   and   tipo.data_cancellazione is null
   and   rsog.data_cancellazione is null and rsog.validita_fine is null
   and   sog.data_cancellazione is null
   and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
   and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione))
   group by doc.doc_anno , doc.doc_numero , tipo.doc_tipo_code,
          lpad(extract('day' from doc.doc_data_emissione)::varchar,2,'0')||'/'||
          lpad(extract('month' from doc.doc_data_emissione)::varchar,2,'0')||'/'||
          extract('year' from doc.doc_data_emissione),
          sog.codice_fiscale, sog.partita_iva, doc.doc_id,doc.pccuff_id,subdoc.subdoc_data_scadenza,
          doc.siope_documento_tipo_id, doc.doc_sdi_lotto_siope,doc.siope_documento_tipo_analogico_id
   union
   select docNcd.doc_anno annoDoc, docNcd.doc_numero numeroDoc, tipoNcd.doc_tipo_code tipoDoc,
          lpad(extract('day' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
          lpad(extract('month' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
          extract('year' from docNcd.doc_data_emissione) dataDoc,
          sog.codice_fiscale codfiscDoc, sog.partita_iva partivaDoc,
          docNcd.doc_id docId,
          docNcd.pccuff_id pccuffId,
          subNcd.subdoc_data_scadenza datascadDoc,
          docNcd.siope_documento_tipo_id siopeDocTipoId,
          docNcd.doc_sdi_lotto_siope  siopeSdiLotto,
          docNcd.siope_documento_tipo_analogico_id siopeDocAnTipoId,
          sum(subdoc.subdoc_importo_da_dedurre) importoDoc -- somm subdoc_importo_da_dedurre / numero di note collegate
   from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
        siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
        siac_r_doc rdoc, siac_d_relaz_tipo tipoRel,
        siac_t_doc docNcd, siac_t_subdoc subNcd, siac_d_doc_tipo tipoNcd,
        siac_r_doc_sog rsog, siac_t_soggetto sog
   where ordts.ord_id=ordinativoId
   and   subdocts.ord_ts_id=ordts.ord_ts_id
   and   subdoc.subdoc_id=subdocts.subdoc_id
   and   doc.doc_id=subdoc.doc_id
   and   tipo.doc_tipo_id=doc.doc_tipo_id
   and   fnc_mif_isDocumentoCommerciale_splus(doc.doc_id,tipoDocFPR,tipoGruppoDocFAT,tipoGruppoDocNCD)=true
   and   tipo.doc_tipo_code!=DOC_TIPO_ALG
   and   rdoc.doc_id_da=doc.doc_id
   and   docncd.doc_id=rdoc.doc_id_a
   and   tipoRel.relaz_tipo_id=rdoc.relaz_tipo_id
   and   tipoRel.relaz_tipo_code=tipoGruppoDocNCD
   and   fnc_mif_isDocumentoCommerciale_splus(docNcd.doc_id,tipoDocFPR,tipoGruppoDocFAT,tipoGruppoDocNCD)=true
   and   subNcd.doc_id=docNcd.doc_id
   and   tipoNcd.doc_tipo_id=docNcd.doc_tipo_id
   and   rsog.doc_id=docNcd.doc_id
   and   sog.soggetto_id=rsog.soggetto_id
   and   ordts.data_cancellazione is null and ordts.validita_fine is null
   and   subdocts.data_cancellazione is null AND subdocts.validita_fine is null
   and   subdoc.data_cancellazione is null and subdoc.validita_fine is null
   and   doc.data_cancellazione is null and doc.validita_fine is null
   and   subNcd.data_cancellazione is null and subNcd.validita_fine is null
   and   docNcd.data_cancellazione is null and docNcd.validita_fine is null
   and   rsog.data_cancellazione is null and rsog.validita_fine is null
   and   rdoc.data_cancellazione is null and rdoc.validita_fine is null
   and   sog.data_cancellazione is null
   group by docNcd.doc_anno , docNcd.doc_numero , tipoNcd.doc_tipo_code,
          lpad(extract('day' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
          lpad(extract('month' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
          extract('year' from docNcd.doc_data_emissione),
          sog.codice_fiscale, sog.partita_iva, docNcd.doc_id,docNcd.pccuff_id,subNcd.subdoc_data_scadenza,
          docNcd.siope_documento_tipo_id, docNcd.doc_sdi_lotto_siope,docNcd.siope_documento_tipo_analogico_id
   order by 3, 1,2
 )*/
 for documentiRec in
 (
  select doc.doc_anno annoDoc, doc.doc_numero numeroDoc, tipo.doc_tipo_code tipoDoc,
        'P'::varchar tipoColl,doc.doc_id docPrincId,
        null annoDocNcd, null numeroDocNcd, null tipoDocNcd,
        lpad(extract('day' from doc.doc_data_emissione)::varchar,2,'0')||'/'||
        lpad(extract('month' from doc.doc_data_emissione)::varchar,2,'0')||'/'||
        extract('year' from doc.doc_data_emissione) dataDoc,
        sog.codice_fiscale codfiscDoc, sog.partita_iva partivaDoc,
        doc.doc_id docId,
        doc.pccuff_id pccuffId,
        subdoc.subdoc_data_scadenza datascadDoc,
        doc.siope_documento_tipo_id siopeDocTipoId,
        doc.doc_sdi_lotto_siope  siopeSdiLotto,
        doc.siope_documento_tipo_analogico_id siopeDocAnTipoId,
        sum(subdoc.subdoc_importo) importoDoc,
        coalesce(sum(subdoc.subdoc_splitreverse_importo),0) importoSplitDoc,
        null importoNcd,null numeroNcd,
        null importoRipartNcd
  from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
       siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
       siac_r_doc_sog rsog, siac_t_soggetto sog
  where ordts.ord_id=ordinativoId
  and   subdocts.ord_ts_id=ordts.ord_ts_id
  and   subdoc.subdoc_id=subdocts.subdoc_id
  and   doc.doc_id=subdoc.doc_id
  and   tipo.doc_tipo_id=doc.doc_tipo_id
  and   fnc_mif_isDocumentoCommerciale_splus(doc.doc_id,tipoDocFPR,tipoGruppoDocFAT,tipoGruppoDocNCD)=true
  and   tipo.doc_tipo_code!=DOC_TIPO_ALG
  and   rsog.doc_id=doc.doc_id
  and   sog.soggetto_id=rsog.soggetto_id
  and   ordts.data_cancellazione is null and ordts.validita_fine is null
  and   subdocts.data_cancellazione is null AND subdocts.validita_fine is null
  and   subdoc.data_cancellazione is null and subdoc.validita_fine is null
  and   doc.data_cancellazione is null and doc.validita_fine is null
  and   tipo.data_cancellazione is null
  and   rsog.data_cancellazione is null and rsog.validita_fine is null
  and   sog.data_cancellazione is null
  and   date_trunc('day',now()::timestamp)>=date_trunc('day',tipo.validita_inizio)
  and   date_trunc('day',now()::timestamp)<=date_trunc('day',coalesce(tipo.validita_fine,now()::timestamp))
  group by doc.doc_anno , doc.doc_numero , tipo.doc_tipo_code,
           lpad(extract('day' from doc.doc_data_emissione)::varchar,2,'0')||'/'||
           lpad(extract('month' from doc.doc_data_emissione)::varchar,2,'0')||'/'||
           extract('year' from doc.doc_data_emissione),
           sog.codice_fiscale, sog.partita_iva, doc.doc_id,doc.pccuff_id,subdoc.subdoc_data_scadenza,
           doc.siope_documento_tipo_id, doc.doc_sdi_lotto_siope,doc.siope_documento_tipo_analogico_id
  union
  (
   with
   docS as
   (
    select doc.doc_anno annoDoc, doc.doc_numero numeroDoc, tipo.doc_tipo_code tipoDoc,
           'S'::varchar tipoColl,doc.doc_id docPrincId,
           docNcd.doc_anno annoDocNcd, docNcd.doc_numero numeroDocNcd, tipoNcd.doc_tipo_code tipoDocNcd,
           lpad(extract('day' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
           lpad(extract('month' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
           extract('year' from docNcd.doc_data_emissione) dataDoc,
           sog.codice_fiscale codfiscDoc, sog.partita_iva partivaDoc,
           docNcd.doc_id docId,
           docNcd.pccuff_id pccuffId,
           subNcd.subdoc_data_scadenza datascadDoc,
           docNcd.siope_documento_tipo_id siopeDocTipoId,
           docNcd.doc_sdi_lotto_siope  siopeSdiLotto,
           docNcd.siope_documento_tipo_analogico_id siopeDocAnTipoId,
           sum(subdoc.subdoc_importo) importoDoc,
           0 importoSplitDoc,
           sum(subdoc.subdoc_importo_da_dedurre) importoNcd
    from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
         siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
         siac_r_doc rdoc, siac_d_relaz_tipo tipoRel,
         siac_t_doc docNcd, siac_t_subdoc subNcd, siac_d_doc_tipo tipoNcd,
         siac_r_doc_sog rsog, siac_t_soggetto sog
    where ordts.ord_id=ordinativoId
    and   subdocts.ord_ts_id=ordts.ord_ts_id
    and   subdoc.subdoc_id=subdocts.subdoc_id
    and   doc.doc_id=subdoc.doc_id
    and   tipo.doc_tipo_id=doc.doc_tipo_id
    and   fnc_mif_isDocumentoCommerciale_splus(doc.doc_id,tipoDocFPR,tipoGruppoDocFAT,tipoGruppoDocNCD)=true
    and   tipo.doc_tipo_code!=DOC_TIPO_ALG
    and   rdoc.doc_id_da=doc.doc_id
    and   docncd.doc_id=rdoc.doc_id_a
    and   tipoRel.relaz_tipo_id=rdoc.relaz_tipo_id
    and   tipoRel.relaz_tipo_code=tipoGruppoDocNCD
    and   fnc_mif_isDocumentoCommerciale_splus(docNcd.doc_id,tipoDocFPR,tipoGruppoDocFAT,tipoGruppoDocNCD)=true
    and   subNcd.doc_id=docNcd.doc_id
    and   tipoNcd.doc_tipo_id=docNcd.doc_tipo_id
    and   rsog.doc_id=docNcd.doc_id
    and   sog.soggetto_id=rsog.soggetto_id
    and   ordts.data_cancellazione is null and ordts.validita_fine is null
    and   subdocts.data_cancellazione is null AND subdocts.validita_fine is null
    and   subdoc.data_cancellazione is null and subdoc.validita_fine is null
    and   doc.data_cancellazione is null and doc.validita_fine is null
    and   subNcd.data_cancellazione is null and subNcd.validita_fine is null
    and   docNcd.data_cancellazione is null and docNcd.validita_fine is null
    and   rsog.data_cancellazione is null and rsog.validita_fine is null
    and   rdoc.data_cancellazione is null and rdoc.validita_fine is null
    and   sog.data_cancellazione is null
    group by  doc.doc_anno , doc.doc_numero , tipo.doc_tipo_code,doc.doc_id,
              docNcd.doc_anno , docNcd.doc_numero , tipoNcd.doc_tipo_code,
              lpad(extract('day' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
              lpad(extract('month' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
              extract('year' from docNcd.doc_data_emissione),
              sog.codice_fiscale, sog.partita_iva, docNcd.doc_id,docNcd.pccuff_id,subNcd.subdoc_data_scadenza,
              docNcd.siope_documento_tipo_id, docNcd.doc_sdi_lotto_siope,docNcd.siope_documento_tipo_analogico_id
   ),
   docCountNcd as
   (
    select doc.doc_anno annoDoc, doc.doc_numero numeroDoc, tipo.doc_tipo_code tipoDoc,
           'S'::varchar tipoColl,doc.doc_id docPrincId,
           count(*) numeroNcd
    from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
         siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
         siac_r_doc rdoc, siac_d_relaz_tipo tipoRel,
         siac_t_doc docNcd, siac_t_subdoc subNcd, siac_d_doc_tipo tipoNcd
    where ordts.ord_id=ordinativoId
    and   subdocts.ord_ts_id=ordts.ord_ts_id
    and   subdoc.subdoc_id=subdocts.subdoc_id
    and   doc.doc_id=subdoc.doc_id
    and   tipo.doc_tipo_id=doc.doc_tipo_id
    and   fnc_mif_isDocumentoCommerciale_splus(doc.doc_id,tipoDocFPR,tipoGruppoDocFAT,tipoGruppoDocNCD)=true
    and   tipo.doc_tipo_code!=DOC_TIPO_ALG
    and   rdoc.doc_id_da=doc.doc_id
    and   docncd.doc_id=rdoc.doc_id_a
    and   tipoRel.relaz_tipo_id=rdoc.relaz_tipo_id
    and   tipoRel.relaz_tipo_code=tipoGruppoDocNCD
    and   fnc_mif_isDocumentoCommerciale_splus(docNcd.doc_id,tipoDocFPR,tipoGruppoDocFAT,tipoGruppoDocNCD)=true
    and   subNcd.doc_id=docNcd.doc_id
    and   tipoNcd.doc_tipo_id=docNcd.doc_tipo_id
    and   ordts.data_cancellazione is null and ordts.validita_fine is null
    and   subdocts.data_cancellazione is null AND subdocts.validita_fine is null
    and   subdoc.data_cancellazione is null and subdoc.validita_fine is null
    and   doc.data_cancellazione is null and doc.validita_fine is null
    and   subNcd.data_cancellazione is null and subNcd.validita_fine is null
    and   docNcd.data_cancellazione is null and docNcd.validita_fine is null
    and   rdoc.data_cancellazione is null and rdoc.validita_fine is null
    group by doc.doc_anno , doc.doc_numero, tipo.doc_tipo_code ,doc.doc_id
   )
   select docS.*,
          docCountNcd.numeroNcd, round(docS.importoNcd/docCountNcd.numeroNcd,2) importoRipartNcd
   from docS, docCountNcd
   where docS.docPrincId=docCountNcd.docPrincId
   and   escludiNCD='N'
  )
  order by 1,2,3,4,6,7,8
 )
 loop

    strMessaggio:='Lettura dati documento doc_id='||documentiRec.docId||'.';
    raise notice 'strMessaggio =%',strMessaggio;

    codice_ipa_ente_siope:=null;          -- ok siac_t_doc.pccuff_id
    tipo_documento_siope:=null;           -- ok siac_t_doc.siope_documento_tipo_id
    tipo_documento_siope_a:=null;         -- ok siac_t_doc.siope_documento_tipo_id
    identificativo_lotto_sdi_siope:=null; -- ok siac_t_doc.doc_sdi_lotto_siope
    tipo_documento_analogico_siope:=null; -- ok solo per doc ANALOGICO doc.siope_documento_tipo_analogico_id
    codice_fiscale_emittente_siope:=null; -- ok
    anno_emissione_fattura_siope:=null;   -- ok
    numero_fattura_siope:=null;           -- ok
    importo_siope:=null;                  -- ok
    importo_siope_split:=null;            -- ok -- 22.12.2017 Sofia siac-5665
    data_scadenza_pagam_siope:=null;      -- dataScadenzaDopoSospensione ok
    motivo_scadenza_siope:=null;          -- ok siac_t_subdoc.siope_scadenza_motivo_id
    natura_spesa_siope:=null;             -- CORRENTE/CAPITALE da capitolo

	motivoScadenza:=null;
    dataScadDopoSosp:=null;
    tipoDocAnalogico:=null;
    codFiscElettronico:=null;

--    raise notice 'strMessaggio =%',strMessaggio;


    if documentiRec.pccuffId is not null then
        strMessaggio:='Lettura dati documento doc_id='||documentiRec.docId||'.'||' Lettura codice ufficio [siac_d_pcc_ufficio].';

	--	 raise notice 'strMessaggio 2 =%',strMessaggio;

    	select pcc.pccuff_code into codice_ipa_ente_siope
        from siac_d_pcc_ufficio pcc
        where pcc.pccuff_id=documentiRec.pccuffId;
    else
        if codicePccUfficio is not null then
        	codice_ipa_ente_siope:=codicePccUfficio;
        end if;
    end if;

    if documentiRec.siopeDocTipoId is not null then
    	strMessaggio:='Lettura dati documento doc_id='||documentiRec.docId||'.'||' Lettura tipo documento siope [siac_d_siope_documento_tipo].';
		 --raise notice 'strMessaggio 3 =%',strMessaggio;

        select upper(tipo.siope_documento_tipo_desc_bnkit) into tipoDocAnalogico
        from siac_d_siope_documento_tipo tipo
        where tipo.siope_documento_tipo_id=documentiRec.siopeDocTipoId;

        if tipoDocAnalogico is not null   then
         if tipoDocAnalogico=docAnalogico then
        	  tipo_documento_siope_a:=tipoDocAnalogico; -- ANALOGICO
         else
              tipo_documento_siope:=tipoDocAnalogico;   -- ELETTRONCIO

              if documentiRec.siopeSdiLotto is not null then
	              identificativo_lotto_sdi_siope:=documentiRec.siopeSdiLotto;
              end if;

         end if;
        end if;
    end if;

    -- se documento analogico
    if tipo_documento_siope_a is not null and
       documentiRec.siopeDocAnTipoId is not null then

       strMessaggio:='Lettura dati documento doc_id='||documentiRec.docId||'.'||' Lettura tipo documento analogico siope [siac_d_siope_documento_tipo_analogico].';
  	   --raise notice 'strMessaggio 4 =%',strMessaggio;

       select upper(tipo.siope_documento_tipo_analogico_desc_bnkit) into tipo_documento_analogico_siope
       from siac_d_siope_documento_tipo_analogico tipo
       where tipo.siope_documento_tipo_analogico_id=documentiRec.siopeDocAnTipoId;

      -- 23.01.2018 Sofia JIRA siac-5765
	  if documentiRec.codfiscDoc is not null and documentiRec.codfiscDoc!='' then
		  codice_fiscale_emittente_siope:=documentiRec.codfiscDoc;
      else
      	  codice_fiscale_emittente_siope:=codiceFiscaleDef;
      end if;
      if documentiRec.tipoColl='P' then
	     anno_emissione_fattura_siope:=documentiRec.annoDoc::varchar;
      else
         anno_emissione_fattura_siope:=documentiRec.annoDocNcd::varchar;
      end if;
    end if;


   	if documentiRec.docPrincId!=coalesce(docPrincId,-1) then
		docPrincId:=documentiRec.docPrincId;
        importoDoc:=documentiRec.importoDoc;
        countNcdCalc:=1;
    end if;
    /*raise notice 'docPrincId=%',docPrincId;
    raise notice 'importoNcd=%',importoNcd;
    raise notice 'countNcdCalc=%',countNcdCalc;
    raise notice 'tipoColl=%',documentiRec.tipoColl;
    raise notice 'importoNcdRipart=%',importoNcdRipart;
    raise notice 'documentiRec.importoRipartNcd=%',documentiRec.importoRipartNcd;
    raise notice 'documentiRec.importoSplitDoc=%',documentiRec.importoSplitDoc;*/

    if documentiRec.tipoColl='S' then
        importoNcd:=documentiRec.importoNcd;
        importoNcdRipart:=importoNcdRipart+documentiRec.importoRipartNcd;
		countNcdCalc:=countNcdCalc+1;
        if countNcdCalc>documentiRec.numeroNcd then
        	if importoNcdRipart!=importoNcd then
				documentiRec.importoRipartNcd:=documentiRec.importoRipartNcd+(importoNcd-importoNcdRipart);
            end if;
        end if;
    end if;



    if documentiRec.tipoColl='P' then
        numero_fattura_siope:=documentiRec.numeroDoc;
	    importo_siope:=documentiRec.importoDoc::varchar;
        importo_siope_split:=documentiRec.importoSplitDoc::varchar; -- 22.12.2017 Sofia siac-5665
    else
        numero_fattura_siope:=documentiRec.numeroDocNcd;
    	importo_siope:=(-documentiRec.importoRipartNcd)::varchar; -- 01.02.2018 Sofia siac-5849
    end if;

    -- se importo=0  non resistuisco dati
    if importo_siope::numeric =0 then
    	continue;
    end if;
--    		 raise notice 'strMessaggio 3 =%',strMessaggio;


    -- se documento elettronico vado a cercare il codice fiscale del documento FEL
/*    if tipo_documento_siope is not null then

        strMessaggio:='Lettura dati documento doc_id='||documentiRec.docId||'.'||' Lettura tipo documento analogico siope [siac_d_siope_documento_tipo_analogico].';

        select presta.codice_prestatore into codFiscElettronico
	    from siac_r_doc_sirfel rs,
	         sirfel_t_fattura fel,sirfel_t_prestatore presta
		where rs.doc_id=documentiRec.docId
		and   fel.id_fattura=rs.id_fattura
	    and   presta.id_prestatore=fel.id_prestatore
		and   rs.data_cancellazione is null
		and   rs.validita_fine is null;

        if codFiscElettronico is not null and
           codFiscElettronico!=codice_fiscale_emittente_siope then
           codice_fiscale_emittente_siope:=codFiscElettronico;
        end if;
    end if;
*/

--		 raise notice 'strMessaggio 4 =%',strMessaggio;

    strMessaggio:='Lettura dati documento doc_id='||documentiRec.docId||'.'||' Lettura motivo scadenza.';
-- raise notice 'strMessaggio =%',strMessaggio;

	select  distinct upper(mot.siope_scadenza_motivo_desc_bnkit)  into motivoScadenza
    from siac_t_subdoc sub, siac_d_siope_scadenza_motivo mot
	where sub.doc_id=documentiRec.docId
    and   sub.siope_scadenza_motivo_id is not null
    and   mot.siope_scadenza_motivo_id=sub.siope_scadenza_motivo_id
	and   sub.data_cancellazione is null
	and   sub.validita_fine is null
    limit 1;

    if coalesce(motivoScadenza,'')!='' then
    	motivo_scadenza_siope:=motivoScadenza;
    end if;

    strMessaggio:='Lettura dati documento doc_id='||documentiRec.docId||'.'||' Lettura data scadenza dopo sospensione.';
	select rattr.testo data_scadenza_dopo_sosp into dataScadDopoSosp
	from siac_t_subdoc sub ,siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts ord,
	     siac_r_subdoc_attr rattr, siac_t_attr attr
	where sub.doc_id=documentiRec.docId
	and   rord.subdoc_id=sub.subdoc_id
	and   ord.ord_ts_id=rord.ord_ts_id
	and   ord.ord_id=ordinativoId
	and   rattr.subdoc_id=sub.subdoc_id
	and   attr.attr_id=rattr.attr_id
	and   attr.attr_code=attrCodeDataScad
	and   rattr.testo is not null
	and   sub.data_cancellazione is null
	and   sub.validita_fine is null
	and   rord.data_cancellazione is null
	and   rord.validita_fine  is null
	and   ord.data_cancellazione is null
	and   ord.validita_fine is null
	and   rattr.data_cancellazione  is null
	and   rattr.validita_fine is null
    limit 1;

    if coalesce(dataScadDopoSosp,'')!='' then
    	data_scadenza_pagam_siope:=substring(dataScadDopoSosp,7,4)||'-'||
        						   substring(dataScadDopoSosp,4,2)||'-'||
                                   substring(dataScadDopoSosp,1,2);
    else
    	if documentiRec.datascadDoc is not null  then
        	data_scadenza_pagam_siope:=extract('year' from documentiRec.datascadDoc)::varchar||'-'||
            					       lpad(extract('month' from documentiRec.datascadDoc)::varchar,2,'0')||'-'||
					                   lpad(extract('day' from documentiRec.datascadDoc)::varchar,2,'0');
        end if;
    end if;
    natura_spesa_siope:=titoloCap;


    exit when numeroDocs>numeroDocumenti;

	return next;

    numeroDocs:=numeroDocs+1;
 end loop;

 --raise notice 'numeroDocs %',numeroDocs;

 return;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 1000),'');
        return;
    when TOO_MANY_ROWS THEN
        RAISE EXCEPTION '% Diverse righe lette.',coalesce(strMessaggio,'');
        return;
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',coalesce(strMessaggio,'');
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',coalesce(strMessaggio,''),SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_spesa_splus (
  enteproprietarioid integer,
  nomeente varchar,
  annobilancio varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  mifordritrasmelabid integer,
  out flussoelabmifdistoilid integer,
  out flussoelabmifid integer,
  out numeroordinativitrasm integer,
  out nomefilemif varchar,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE


 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';
 strMessaggioScarto VARCHAR(1500):='';
 strExecSql VARCHAR(1500):='';

 mifOrdinativoIdRec record;

 mifFlussoOrdinativoRec  mif_t_ordinativo_spesa%rowtype;


 mifFlussoElabMifArr flussoElabMifRecType[];


 mifCountRec integer:=1;
 mifCountTmpRec integer:=1;
 mifAFlussoElabTypeRec  flussoElabMifRecType;
 flussoElabMifElabRec  flussoElabMifRecType;
 mifElabRec record;

 attoAmmRec record;
 enteOilRec record;
 enteProprietarioRec record;
 soggettoRec record;
 soggettoSedeRec record;
 soggettoQuietRec record;
 soggettoQuietRifRec record;
 MDPRec record;
 codAccreRec record;
 bilElemRec record;
 indirizzoRec record;
 ordSostRec record;


 tipoPagamRec record;
 ritenutaRec record;
 ricevutaRec record;
 quoteOrdinativoRec record;
 ordRec record;


 isIndirizzoBenef boolean:=false;
 isIndirizzoBenQuiet boolean:=false;

 flussoElabMifValore varchar (1000):=null;
 flussoElabMifValoreDesc varchar (1000):=null;

 ordNumero numeric:=null;
 ordAnno  integer:=null;
 attoAmmTipoSpr varchar(50):=null;
 attoAmmTipoAll varchar(50):=null;
 attoAmmTipoAllAll varchar(50):=null;

 attoAmmStrTipoRag  varchar(50):=null;
 attoAmmTipoAllRag varchar(50):=null;


 tipoMDPCbi varchar(50):=null;
 tipoMDPCsi varchar(50):=null;
 tipoMDPCo  varchar(50):=null;
 tipoMDPCCP varchar(50):=null;
 tipoMDPCB  varchar(50):=null;
 tipoPaeseCB varchar(50):=null;
 avvisoTipoMDPCo varchar(50):=null;
 codiceCge  varchar(50):=null;
 siopeDef   varchar(50):=null;
 codResult   integer:=null;

 indirizzoEnte varchar(500):=null;
 localitaEnte varchar(500):=null;
 soggettoEnteId INTEGER:=null;
 soggettoRifId integer:=null;
 soggettoSedeSecId integer:=null;
 soggettoQuietId integer:=null;
 soggettoQuietRifId integer:=null;
 accreditoGruppoCode varchar(15):=null;




 flussoElabMifLogId  integer :=null;
 flussoElabMifTipoId integer :=null;
 flussoElabMifTipoNomeFile varchar(500):=null;
 flussoElabMifTipoDec BOOLEAN:=false;
 flussoElabMifOilId integer :=null;
 flussoElabMifDistOilRetId integer:=null;
 mifOrdSpesaId integer:=null;

 dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataFineVal timestamp :=annoBilancio||'-12-31';


 ordImporto numeric :=0;


 ordTipoCodeId integer :=null;
 ordStatoCodeIId  integer :=null;
 ordStatoCodeAId  integer :=null;

 classCdrTipoId INTEGER:=null;
 classCdcTipoId INTEGER:=null;
 ordDetTsTipoId integer :=null;

 ordSedeSecRelazTipoId integer:=null;
 ordRelazCodeTipoId integer :=null;
 ordCsiRelazTipoId  integer:=null;

 noteOrdAttrId integer:=null;

 movgestTsTipoSubId integer:=null;


 famTitSpeMacroAggrCodeId integer:=null;
 titoloUscitaCodeTipoId integer :=null;
 programmaCodeTipoId integer :=null;
 programmaCodeTipo varchar(50):=null;
 famMissProgrCode VARCHAR(50):=null;
 famMissProgrCodeId integer:=null;
 programmaId integer :=null;
 titoloUscitaId integer:=null;



 isPaeseSepa integer:=null;
 ordCodiceBollo  varchar(10):=null;
 ordCodiceBolloDesc varchar(500):=null;
 ordDataScadenza timestamp:=null;

 ordCsiRelazTipo varchar(20):=null;
 ordCsiCOTipo varchar(50):=null;


 ambitoFinId integer:=null;
 anagraficaBenefCBI varchar(500):=null;

 isDefAnnoRedisuo  varchar(5):=null;


 -- ritenute
 tipoRelazRitOrd varchar(10):=null;
 tipoRelazSprOrd varchar(10):=null;
 tipoRelazSubOrd varchar(10):=null;
 tipoRitenuta varchar(10):='R';
 progrRitenuta  varchar(10):=null;
 isRitenutaAttivo boolean:=false;
 tipoOnereIrpefId integer:=null;
 tipoOnereInpsId integer:=null;
 tipoOnereIrpef varchar(10):=null;
 tipoOnereInps varchar(10):=null;

 tipoOnereIrpegId integer:=null;
 tipoOnereIrpeg varchar(10):=null;

 codiceUECodeTipo VARCHAR(50):=null;
 codiceUECodeTipoId integer:=null;
 codiceCofogCodeTipo  VARCHAR(50):=null;
 codiceCofogCodeTipoId integer:=null;
 siopeCodeTipo varchar(50):=null;
 siopeCodeTipoId integer :=null;
 eventoTipoCodeId integer:=null;
 collEventoCodeId integer:=null;

 classifTipoCodeFraz    varchar(50):=null;
 classifTipoCodeFrazVal varchar(50):=null;
 classifTipoCodeFrazId   integer:=null;

 tipoClassFruttifero varchar(100):=null;
 valFruttifero varchar(100):=null;
 valFruttiferoStr varchar(100):=null;
 valFruttiferoStrAltro varchar(100):=null;
 tipoClassFruttiferoId integer:=null;
 valFruttiferoId  integer:=null;

 classVincolatoCode   varchar(100):=null;
 classVincolatoCodeId INTEGER:=null;
 valFruttiferoClassCode   varchar(100):=null;
 valFruttiferoClassCodeId INTEGER:=null;
 valFruttiferoClassCodeSI varchar(100):=null;
 valFruttiferoCodeSI varchar(100):=null;
 valFruttiferoClassCodeNO varchar(100):=null;
 valFruttiferoCodeNO varchar(100):=null;

 cigCausAttrId INTEGER:=null;
 cupCausAttrId INTEGER:=null;
 cigCausAttr   varchar(10):=null;
 cupCausAttr   varchar(10):=null;


 codicePaeseIT varchar(50):=null;
 codiceAccreCB varchar(50):=null;
 codiceAccreCO varchar(50):=null;
 codiceAccreREG varchar(50):=null;
 codiceSepa     varchar(50):=null;
 codiceExtraSepa varchar(50):=null;
 codiceGFB  varchar(50):=null;

 sepaCreditTransfer boolean:=false;
 accreditoGruppoSepaTr varchar(10):=null;
 SepaTr varchar(10):=null;
 paeseSepaTr varchar(10):=null;


 numeroDocs varchar(10):=null;
 tipoDocs varchar(50):=null;
 tipoDocsComm varchar(50):=null;
 tipoGruppoDocs varchar(50):=null;

 tipoEsercizio varchar(50):=null;
 statoBeneficiario boolean :=false;
 bavvioFrazAttr boolean :=false;
 dataAvvioFrazAttr timestamp:=null;
 attrfrazionabile VARCHAR(50):=null;

 dataAvvioSiopeNew VARCHAR(50):=null;
 bAvvioSiopeNew   boolean:=false;


 tipoPagamPostA VARCHAR(100):=null;
 tipoPagamPostB VARCHAR(100):=null;

 cupAttrCodeId INTEGER:=null;
 cupAttrCode   varchar(10):=null;
 cigAttrCodeId INTEGER:=null;
 cigAttrCode   varchar(10):=null;
 ricorrenteCodeTipo varchar(50):=null;
 ricorrenteCodeTipoId integer:=null;

 codiceBolloPlusEsente boolean:=false;
 codiceBolloPlusDesc   varchar(100):=null;

 statoDelegatoCredEff boolean :=false;

 comPccAttrId integer:=null;
 pccOperazTipoId integer:=null;


 -- Transazione elementare
 programmaTbr varchar(50):=null;
 codiceFinVTbr varchar(50):=null;
 codiceEconPatTbr varchar(50):=null;
 cofogTbr varchar(50):=null;
 transazioneUeTbr varchar(50):=null;
 siopeTbr varchar(50):=null;
 cupTbr varchar(50):=null;
 ricorrenteTbr varchar(50):=null;
 aslTbr varchar(50):=null;
 progrRegUnitTbr varchar(50):=null;

 codiceFinVTipoTbrId integer:=null;
 cupAttrId integer:=null;
 ricorrenteTipoTbrId integer:=null;
 aslTipoTbrId integer:=null;
 progrRegUnitTipoTbrId integer:=null;

 codiceFinVCodeTbr varchar(50):=null;
 contoEconCodeTbr varchar(50):=null;
 cofogCodeTbr varchar(50):=null;
 codiceUeCodeTbr varchar(50):=null;
 siopeCodeTbr varchar(50):=null;
 cupAttrTbr varchar(50):=null;
 ricorrenteCodeTbr varchar(50):=null;
 aslCodeTbr  varchar(50):=null;
 progrRegUnitCodeTbr varchar(50):=null;



 isGestioneQuoteOK boolean:=false;
 isGestioneFatture boolean:=false;
 isRicevutaAttivo boolean:=false;
 isTransElemAttiva boolean:=false;
 isMDPCo boolean:=false;
 isOrdPiazzatura boolean:=false;

 docAnalogico    varchar(100):=null;
 titoloCorrente   varchar(100):=null;
 descriTitoloCorrente varchar(100):=null;
 titoloCapitale   varchar(100):=null;
 descriTitoloCapitale varchar(100):=null;

 -- 20.02.2018 Sofia jira siac-5849
 defNaturaPag  varchar(100):=null;

 attrCodeDataScad varchar(100):=null;
 titoloCap  varchar(100):=null;

 isOrdCommerciale boolean:=false;

 NVL_STR               CONSTANT VARCHAR:='';


 ORD_TIPO_CODE_P  CONSTANT  varchar :='P';
 ORD_STATO_CODE_I CONSTANT  varchar :='I';
 ORD_STATO_CODE_A CONSTANT  varchar :='A';
 ORD_RELAZ_CODE_SOS  CONSTANT  varchar :='SOS_ORD';
 ORD_TIPO_A CONSTANT  varchar :='A';

 ORD_RELAZ_SEDE_SEC CONSTANT  varchar :='SEDE_SECONDARIA';
 AMBITO_FIN CONSTANT  varchar :='AMBITO_FIN';

 NOTE_ORD_ATTR CONSTANT  varchar :='NOTE_ORDINATIVO';

 CDC CONSTANT varchar:='CDC';
 CDR CONSTANT varchar:='CDR';


 PROGRAMMA               CONSTANT varchar:='PROGRAMMA';
 TITOLO_SPESA            CONSTANT varchar:='TITOLO_SPESA';
 FAM_TIT_SPE_MACROAGGREG CONSTANT varchar:='Spesa - TitoliMacroaggregati';

 FUNZIONE_CODE_I CONSTANT  varchar :='INSERIMENTO'; -- inserimenti
 FUNZIONE_CODE_S CONSTANT  varchar :='SOSTITUZIONE'; -- sostituzioni senza trasmissione
 FUNZIONE_CODE_N CONSTANT  varchar :='ANNULLO'; -- annullamenti prima di trasmissione

 FUNZIONE_CODE_A CONSTANT  varchar :='ANNULLO'; -- annullamenti dopo trasmissione
 FUNZIONE_CODE_VB CONSTANT  varchar :='VARIAZIONE'; -- spostamenti dopo trasmissione


 ORD_TS_DET_TIPO_A CONSTANT varchar:='A';
 MOVGEST_TS_TIPO_S  CONSTANT varchar:='S';

 SPACE_ASCII CONSTANT integer:=32;
 VT_ASCII CONSTANT integer:=13;
 BS_ASCII CONSTANT integer:=10;

 NUM_SETTE CONSTANT integer:=7;
 NUM_DODICI CONSTANT integer:=12;
 ZERO_PAD CONSTANT  varchar :='0';

 ELAB_MIF_ESITO_IN CONSTANT  varchar :='IN';
 MANDMIF_TIPO  CONSTANT  varchar :='MANDMIF_SPLUS';


 COM_PCC_ATTR  CONSTANT  varchar :='flagComunicaPCC';
 PCC_OPERAZ_CPAG  CONSTANT varchar:='CP';

 SEPARATORE     CONSTANT  varchar :='|';



 FLUSSO_MIF_ELAB_TEST_COD_ABI_BT      CONSTANT integer:=1;  -- codice_ABI_BT
 FLUSSO_MIF_ELAB_TEST_COD_ENTE_IPA    CONSTANT integer:=4;  -- codice_ente
 FLUSSO_MIF_ELAB_TEST_DESC_ENTE       CONSTANT integer:=5;  -- descrizione_ente
 FLUSSO_MIF_ELAB_TEST_COD_ISTAT_ENTE  CONSTANT integer:=6;  -- codice_istat_ente
 FLUSSO_MIF_ELAB_TEST_CODFISC_ENTE    CONSTANT integer:=7;  -- codice_fiscale_ente
 FLUSSO_MIF_ELAB_TEST_CODTRAMITE_ENTE CONSTANT integer:=8;  -- codice_tramite_ente
 FLUSSO_MIF_ELAB_TEST_CODTRAMITE_BT   CONSTANT integer:=9;  -- codice_tramite_bt
 FLUSSO_MIF_ELAB_TEST_COD_ENTE_BT     CONSTANT integer:=10; -- codice_ente_bt
 FLUSSO_MIF_ELAB_TEST_RIFERIMENTO_ENTE CONSTANT integer:=11; -- riferimento_ente
 FLUSSO_MIF_ELAB_TEST_ESERCIZIO       CONSTANT integer:=12; -- riferimento_ente

 FLUSSO_MIF_ELAB_INIZIO_ORD     CONSTANT integer:=13;  -- tipo_operazione

 FLUSSO_MIF_ELAB_FATTURE        CONSTANT integer:=53;  -- fattura_siope_codice_ipa_ente_siope
 FLUSSO_MIF_ELAB_FATT_CODFISC   CONSTANT integer:=58;  -- fattura_siope_codice_fiscale_emittente_siope
 FLUSSO_MIF_ELAB_FATT_DATASCAD_PAG CONSTANT integer:=62; -- data_scadenza_pagam_siope
 FLUSSO_MIF_ELAB_FATT_NATURA_PAG CONSTANT integer:=64; -- natura_spesa_siope
 FLUSSO_MIF_ELAB_NUM_SOSPESO    CONSTANT integer:=122; -- numero_provvisorio
 FLUSSO_MIF_ELAB_RITENUTA       CONSTANT integer:=124; -- importo_ritenuta
 FLUSSO_MIF_ELAB_RITENUTA_PRG   CONSTANT integer:=126; -- progressivo_versante


 REGMOVFIN_STATO_A              CONSTANT varchar:='A';
 SEGNO_ECONOMICO				CONSTANT varchar:='Dare';



BEGIN

	numeroOrdinativiTrasm:=0;
    codiceRisultato:=0;
    messaggioRisultato:='';
	flussoElabMifId:=null;
    nomeFileMif:=null;

    flussoElabMifDistOilId:=null;

	strMessaggioFinale:='Invio ordinativi di spesa SIOPE PLUS.';


    -- enteOilRec
    strMessaggio:='Lettura dati ente OIL  per flusso MIF tipo '||MANDMIF_TIPO||'.';
    select * into strict enteOilRec
    from siac_t_ente_oil ente
    where ente.ente_proprietario_id=enteProprietarioId
    and   ente.data_cancellazione is null
    and   ente.validita_fine is null;

    if enteOilRec is null then
    	raise exception ' Errore in reperimento dati';
    end if;

    if enteOilRec.ente_oil_siope_plus=false then
    	raise exception ' SIOPE PLUS non attivo per l''ente.';
    end if;

    -- inserimento record in tabella mif_t_flusso_elaborato
    strMessaggio:='Inserimento mif_t_flusso_elaborato tipo flusso='||MANDMIF_TIPO||'.';

    insert into mif_t_flusso_elaborato
    (flusso_elab_mif_data ,
     flusso_elab_mif_esito,
     flusso_elab_mif_esito_msg,
     flusso_elab_mif_file_nome,
     flusso_elab_mif_tipo_id,
     flusso_elab_mif_id_flusso_oil, -- da calcolare su tab progressivi
     flusso_elab_mif_codice_flusso_oil, -- da calcolare su tab progressivi
     validita_inizio,
     ente_proprietario_id,
     login_operazione)
     (select dataElaborazione,
             ELAB_MIF_ESITO_IN,
             'Elaborazione in corso per tipo flusso '||MANDMIF_TIPO,
      		 tipo.flusso_elab_mif_nome_file,
     		 tipo.flusso_elab_mif_tipo_id,
     		 null,--flussoElabMifOilId, -- da calcolare su tab progressivi
             null, -- flussoElabMifDistOilId -- da calcolare su tab progressivi
    		 dataElaborazione,
     		 enteProprietarioId,
      		 loginOperazione
      from mif_d_flusso_elaborato_tipo tipo
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.flusso_elab_mif_tipo_code=MANDMIF_TIPO
      and   tipo.data_cancellazione is null
      and   tipo.validita_fine is null
     )
     returning flusso_elab_mif_id into flussoElabMifLogId;-- valore da restituire

      raise notice 'flussoElabMifLogId %',flussoElabMifLogId;

     if flussoElabMifLogId is null then
       RAISE EXCEPTION ' Errore generico in inserimento %.',MANDMIF_TIPO;
     end if;

    strMessaggio:='Verifica esistenza elaborazioni in corso per tipo flusso '||MANDMIF_TIPO||'.';
	codResult:=null;
    select distinct 1 into codResult
    from mif_t_flusso_elaborato elab,  mif_d_flusso_elaborato_tipo tipo
    where  elab.flusso_elab_mif_id!=flussoElabMifLogId
    and    elab.flusso_elab_mif_esito=ELAB_MIF_ESITO_IN
    and    elab.data_cancellazione is null
    and    elab.validita_fine is null
    and    tipo.flusso_elab_mif_tipo_id=elab.flusso_elab_mif_tipo_id
    and    tipo.flusso_elab_mif_tipo_code=MANDMIF_TIPO
    and    tipo.ente_proprietario_id=enteProprietarioId
    and    tipo.data_cancellazione is null
    and    tipo.validita_fine is null;

    if codResult is not null then
    	RAISE EXCEPTION ' Verificare situazioni esistenti.';
    end if;

    -- verifico se la tabella degli id contiene dati in tal caso elaborazioni precedenti sono andate male
    strMessaggio:='Verifica esistenza dati in tabella temporanea id [mif_t_ordinativo_spesa_id].';
    codResult:=null;
    select distinct 1 into codResult
    from mif_t_ordinativo_spesa_id mif
    where mif.ente_proprietario_id=enteProprietarioId;

    if codResult is not null then
      RAISE EXCEPTION ' Dati presenti verificarne il contenuto ed effettuare pulizia prima di rieseguire.';
    end if;



    codResult:=null;
    -- recupero indentificativi tipi codice vari
	begin

        -- ordTipoCodeId
        strMessaggio:='Lettura ordinativo tipo Code Id '||ORD_TIPO_CODE_P||'.';
        select ord_tipo.ord_tipo_id into strict ordTipoCodeId
        from siac_d_ordinativo_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_tipo_code=ORD_TIPO_CODE_P
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
   		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));

		-- ordStatoCodeIId
        strMessaggio:='Lettura ordinativo stato Code Id '||ORD_STATO_CODE_I||'.';
        select ord_tipo.ord_stato_id into strict ordStatoCodeIId
        from siac_d_ordinativo_stato ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_stato_code=ORD_STATO_CODE_I
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


        -- ordStatoCodeAId
        strMessaggio:='Lettura ordinativo stato Code Id '||ORD_STATO_CODE_A||'.';
        select ord_tipo.ord_stato_id into strict ordStatoCodeAId
        from siac_d_ordinativo_stato ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_stato_code=ORD_STATO_CODE_A
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


		-- classCdrTipoId
        strMessaggio:='Lettura classif Id per tipo sac='||CDR||'.';
        select tipo.classif_tipo_id into strict classCdrTipoId
        from siac_d_class_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.classif_tipo_code=CDR
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

        -- classCdcTipoId
        strMessaggio:='Lettura classif Id per tipo sac='||CDC||'.';
        select tipo.classif_tipo_id into strict classCdrTipoId
        from siac_d_class_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.classif_tipo_code=CDC
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));


		-- ordDetTsTipoId
        strMessaggio:='Lettura tipo importo ordinativo  Code Id '||ORD_TS_DET_TIPO_A||'.';
        select ord_tipo.ord_ts_det_tipo_id into strict ordDetTsTipoId
        from siac_d_ordinativo_ts_det_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_ts_det_tipo_code=ORD_TS_DET_TIPO_A
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


        -- ordSedeSecRelazTipoId
        strMessaggio:='Lettura relazione sede secondaria  Code Id '||ORD_RELAZ_SEDE_SEC||'.';
        select ord_tipo.relaz_tipo_id into strict ordSedeSecRelazTipoId
        from siac_d_relaz_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.relaz_tipo_code=ORD_RELAZ_SEDE_SEC
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


		-- ordRelazCodeTipoId
        strMessaggio:='Lettura relazione   Code Id '||ORD_RELAZ_CODE_SOS||'.';
		select ord_tipo.relaz_tipo_id into strict ordRelazCodeTipoId
    	from siac_d_relaz_tipo ord_tipo
		where ord_tipo.ente_proprietario_id=enteProprietarioId
		and   ord_tipo.relaz_tipo_code=ORD_RELAZ_CODE_SOS
		and   ord_tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


        -- movgestTsTipoSubId
        strMessaggio:='Lettura movgest_ts_tipo  '||MOVGEST_TS_TIPO_S||'.';
		select ord_tipo.movgest_ts_tipo_id into strict movgestTsTipoSubId
    	from siac_d_movgest_ts_tipo ord_tipo
		where ord_tipo.ente_proprietario_id=enteProprietarioId
		and   ord_tipo.movgest_ts_tipo_code=MOVGEST_TS_TIPO_S
		and   ord_tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


    	-- programmaCodeTipoId
        strMessaggio:='Lettura programma_code_tipo_id  '||PROGRAMMA||'.';
		select tipo.classif_tipo_id into strict programmaCodeTipoId
    	from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code=PROGRAMMA
		and   tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));

		-- famTitSpeMacroAggrCodeId
		-- FAM_TIT_SPE_MACROAGGREG='Spesa - TitoliMacroaggregati'
        strMessaggio:='Lettura fam_tit_spe_macroggregati_code_tipo_id  '||FAM_TIT_SPE_MACROAGGREG||'.';
		select fam.classif_fam_tree_id into strict famTitSpeMacroAggrCodeId
        from siac_t_class_fam_tree fam
        where fam.ente_proprietario_id=enteProprietarioId
        and   fam.class_fam_code=FAM_TIT_SPE_MACROAGGREG
        and   fam.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',fam.validita_inizio)
		and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(fam.validita_fine,dataElaborazione));


    	-- titoloUscitaCodeTipoId
        strMessaggio:='Lettura titolo_spesa_code_tipo_id  '||TITOLO_SPESA||'.';
		select tipo.classif_tipo_id into strict titoloUscitaCodeTipoId
    	from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code=TITOLO_SPESA
		and   tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));

		-- noteOrdAttrId
        strMessaggio:='Lettura noteOrdAttrId per attributo='||NOTE_ORD_ATTR||'.';
		select attr.attr_id into strict  noteOrdAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=NOTE_ORD_ATTR
        and   attr.data_cancellazione is null
        and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
 	 	and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attr.validita_fine,dataElaborazione));


        -- ambitoFinId
        strMessaggio:='Lettura ambito  Code Id '||AMBITO_FIN||'.';
        select a.ambito_id into strict ambitoFinId
        from siac_d_ambito a
        where a.ente_proprietario_id=enteProprietarioId
   		and   a.ambito_code=AMBITO_FIN
        and   a.data_cancellazione is null
        and   a.validita_fine is null;

        -- flussoElabMifTipoId
        strMessaggio:='Lettura tipo flusso MIF  Code Id '||MANDMIF_TIPO||'.';
        select tipo.flusso_elab_mif_tipo_id, tipo.flusso_elab_mif_nome_file, tipo.flusso_elab_mif_tipo_dec
               into strict flussoElabMifTipoId,flussoElabMifTipoNomeFile, flussoElabMifTipoDec
        from mif_d_flusso_elaborato_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
   		and   tipo.flusso_elab_mif_tipo_code=MANDMIF_TIPO
        and   tipo.data_cancellazione is null
        and   tipo.validita_fine is null;

        -- raise notice 'flussoElabMifTipoId %',flussoElabMifTipoId;
        -- mifFlussoElabTypeRec


        strMessaggio:='Lettura flusso struttura MIF  per tipo '||MANDMIF_TIPO||'.';
        for mifElabRec IN
        (select m.*
         from mif_d_flusso_elaborato m
         where m.flusso_elab_mif_tipo_id=flussoElabMifTipoId
         and   m.flusso_elab_mif_elab=true
         order by m.flusso_elab_mif_ordine_elab
        )
        loop
        	mifAFlussoElabTypeRec.flussoElabMifId :=mifElabRec.flusso_elab_mif_id;
            mifAFlussoElabTypeRec.flussoElabMifAttivo :=mifElabRec.flusso_elab_mif_attivo;
            mifAFlussoElabTypeRec.flussoElabMifDef :=mifElabRec.flusso_elab_mif_default;
            mifAFlussoElabTypeRec.flussoElabMifElab :=mifElabRec.flusso_elab_mif_elab;
            mifAFlussoElabTypeRec.flussoElabMifParam :=mifElabRec.flusso_elab_mif_param;

            mifAFlussoElabTypeRec.flusso_elab_mif_ordine_elab :=mifElabRec.flusso_elab_mif_ordine_elab;
            mifAFlussoElabTypeRec.flusso_elab_mif_ordine :=mifElabRec.flusso_elab_mif_ordine;
            mifAFlussoElabTypeRec.flusso_elab_mif_code :=mifElabRec.flusso_elab_mif_code;
            mifAFlussoElabTypeRec.flusso_elab_mif_campo :=mifElabRec.flusso_elab_mif_campo;

            mifFlussoElabMifArr[mifElabRec.flusso_elab_mif_ordine_elab]:=mifAFlussoElabTypeRec;

        end loop;



		-- Gestione registroPcc per enti che non gestiscono quitanze
        -- Nota : capire se necessario gestire PCC
		/*if enteOilRec.ente_oil_quiet_ord=false then

  			-- comPccAttrId
	        strMessaggio:='Lettura comPccAttrId per attributo='||COM_PCC_ATTR||'.';
			select attr.attr_id into strict  comPccAttrId
	        from siac_t_attr attr
	        where attr.ente_proprietario_id=enteProprietarioId
	        and   attr.attr_code=COM_PCC_ATTR
	        and   attr.data_cancellazione is null
	        and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
   	 	    and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attr.validita_fine,dataElaborazione));

            strMessaggio:='Lettura Id tipo operazine PCC='||PCC_OPERAZ_CPAG||'.';
			select pcc.pccop_tipo_id into strict pccOperazTipoId
		    from siac_d_pcc_operazione_tipo pcc
		    where pcc.ente_proprietario_id=enteProprietarioId
		    and   pcc.pccop_tipo_code=PCC_OPERAZ_CPAG;


        end if;*/

        -- enteProprietarioRec
        strMessaggio:='Lettura dati ente proprietario per flusso MIF tipo '||MANDMIF_TIPO||'.';
        select * into strict enteProprietarioRec
        from siac_t_ente_proprietario ente
        where ente.ente_proprietario_id=enteProprietarioId
	    and   ente.data_cancellazione is null
        and   ente.validita_fine is null;

        -- soggettoEnteId
        strMessaggio:='Lettura indirizzo ente proprietario [siac_r_soggetto_ente_proprietario] per flusso MIF tipo '||MANDMIF_TIPO||'.';
        select ente.soggetto_id into soggettoEnteId
        from siac_r_soggetto_ente_proprietario ente
        where ente.ente_proprietario_id=enteProprietarioId
        and   ente.data_cancellazione is null
        and   ente.validita_fine is null;

        if soggettoEnteId is not null then
            strMessaggio:='Lettura indirizzo ente proprietario [siac_t_indirizzo_soggetto] per flusso MIF tipo '||MANDMIF_TIPO||'.';

        	select viaTipo.via_tipo_code||' '||indir.toponimo||' '||indir.numero_civico,
        		   com.comune_desc
                   into indirizzoEnte,localitaEnte
            from siac_t_indirizzo_soggetto indir,
                 siac_t_comune com,
                 siac_d_via_tipo viaTipo
            where indir.soggetto_id=soggettoEnteId
            and   indir.principale='S'
            and   indir.data_cancellazione is null
            and   indir.validita_fine is null
            and   com.comune_id=indir.comune_id
            and   com.data_cancellazione is null
            and   com.validita_fine is null
            and   viaTipo.via_tipo_id=indir.via_tipo_id
            and   viaTipo.data_cancellazione is null
	   		and   date_trunc('day',dataElaborazione)>=date_trunc('day',viaTipo.validita_inizio)
 			and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(viaTipo.validita_fine,dataElaborazione))
            order by indir.indirizzo_id;
        end if;

        -- Calcolo progressivo "distinta" per flusso MANDMIF
	    -- calcolo su progressivi di flussoElabMifDistOilId flussoOIL univoco per tipo flusso
        strMessaggio:='Lettura progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_'||MANDMIF_TIPO||'_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        codResult:=null;
        select prog.prog_value into flussoElabMifDistOilRetId -- 25.05.2016 Sofia - JIRA-3619
        from siac_t_progressivo prog
        where prog.ente_proprietario_id=enteProprietarioId
        and   prog.prog_key='oil_'||MANDMIF_TIPO||'_'||annoBilancio
        and   prog.ambito_id=ambitoFinId
        and   prog.data_cancellazione is null
        and   prog.validita_fine is null;

        if flussoElabMifDistOilRetId is null then -- 25.05.2016 Sofia - JIRA-3619
			strMessaggio:='Inserimento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        	insert into siac_t_progressivo
            (prog_key,
             prog_value,
			 ambito_id,
		     validita_inizio,
			 ente_proprietario_id,
			 login_operazione
            )
            values
            ('oil_'||MANDMIF_TIPO||'_'||annoBilancio,1,ambitoFinId,now(),enteProprietarioId,loginOperazione)
            returning prog_id into codResult;

            if codResult is null then
            	RAISE EXCEPTION ' Progressivo non inserito.';
            else
            	flussoElabMifDistOilRetId:=0;
            end if;
        end if;

        if flussoElabMifDistOilRetId is not null then
	        flussoElabMifDistOilRetId:=flussoElabMifDistOilRetId+1;
        end if;

	    -- calcolo su progressivo di flussoElabMifOilId flussoOIL univoco
        strMessaggio:='Lettura progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        codResult:=null;
        select prog.prog_value into flussoElabMifOilId
        from siac_t_progressivo prog
        where prog.ente_proprietario_id=enteProprietarioId
        and   prog.prog_key='oil_out_'||annoBilancio
        and   prog.ambito_id=ambitoFinId
        and   prog.data_cancellazione is null
        and   prog.validita_fine is null;

        if flussoElabMifOilId is null then
			strMessaggio:='Inserimento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        	insert into siac_t_progressivo
            (prog_key,
             prog_value,
			 ambito_id,
		     validita_inizio,
			 ente_proprietario_id,
			 login_operazione
            )
            values
            ('oil_out_'||annoBilancio,1,ambitoFinId,now(),enteProprietarioId,loginOperazione)
            returning prog_id into codResult;

            if codResult is null then
            	RAISE EXCEPTION ' Progressivo non inserito.';
            else
            	flussoElabMifOilId:=0;
            end if;
        end if;

        if flussoElabMifOilId is not null then
	        flussoElabMifOilId:=flussoElabMifOilId+1;
        end if;

        exception
		when no_data_found then
			RAISE EXCEPTION ' Non presente in archivio';
        when TOO_MANY_ROWS THEN
            RAISE EXCEPTION ' Diverse righe presenti in archivio.';
		when others  THEN
			RAISE EXCEPTION ' %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 500);
    end;




    --- popolamento mif_t_ordinativo_spesa_id


    -- ordinativi emessi o emessi/spostati non ancora mai trasmessi codice_funzione='I' -- INSERIMENTO
    strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_I||'.';

    insert into mif_t_ordinativo_spesa_id
    (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
     mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
     mif_ord_soggetto_id, mif_ord_modpag_id,
     mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
     mif_ord_liq_id, mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_dist_id,
     mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
     mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
     mif_ord_siope_tipo_debito_id,mif_ord_siope_assenza_motivazione_id,
     mif_ord_login_creazione,mif_ord_login_modifica,
     ente_proprietario_id, login_operazione)
    (
     with
     ritrasm as
     (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	  from mif_t_ordinativo_ritrasmesso r
	  where mifOrdRitrasmElabId is not null
	  and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	  and   r.ente_proprietario_id=enteProprietarioId
	  and   r.data_cancellazione is null),
     ordinativi as
     (
      select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_I mif_ord_codice_funzione,
             bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
             ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
             extract('year' from ord.ord_emissione_data)||'-'||
             lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
             lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione , 0 mif_ord_ord_anno_movg,
             0 mif_ord_soggetto_id,0 mif_ord_modpag_id,0 mif_ord_subord_id, elem.elem_id mif_ord_elem_id,
             0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_liq_id,0 mif_ord_atto_amm_id,
             ord.contotes_id mif_ord_contotes_id,ord.dist_id mif_ord_dist_id,ord.codbollo_id mif_ord_codbollo_id,
             ord.comm_tipo_id mif_ord_comm_tipo_id,ord.notetes_id mif_ord_notetes_id, ord.ord_desc mif_ord_desc,
             ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
             ord.siope_tipo_debito_id,ord.siope_assenza_motivazione_id,
             ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
             enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
      from siac_t_ordinativo ord,siac_r_ordinativo_stato ord_stato,siac_t_bil bil, siac_t_periodo per,siac_r_ordinativo_bil_elem elem
      where  bil.ente_proprietario_id=enteProprietarioId
        and  per.periodo_id=bil.periodo_id
        and  per.anno::integer <=annoBilancio::integer
        and  ord.bil_id=bil.bil_id
        and  ord.ord_tipo_id=ordTipoCodeId
        and  ord_stato.ord_id=ord.ord_id
        and  ord_stato.data_cancellazione is null
	    and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
  	    and  ord_stato.validita_fine is null
        and  ord_stato.ord_stato_id=ordStatoCodeIId
        and  ord.ord_trasm_oil_data is null
        and  ord.ord_emissione_data<=dataElaborazione
        and  elem.ord_id=ord.ord_id
        and  elem.data_cancellazione is null
        and  not exists (select 1 from siac_r_ordinativo rord
                          where rord.ord_id_a=ord.ord_id
                          and   rord.data_cancellazione is null
                          and   rord.validita_fine is null
			              and   rord.relaz_tipo_id=ordRelazCodeTipoId)
       )
       select  o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
		       o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
     		   o.mif_ord_soggetto_id, o.mif_ord_modpag_id,
               o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_liq_id, o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_dist_id,
               o.mif_ord_codbollo_id,o.mif_ord_comm_tipo_id,o.mif_ord_notetes_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.siope_tipo_debito_id,o.siope_assenza_motivazione_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id , o.login_operazione
       from ordinativi o
	   where mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
       );


      -- ordinativi emessi o emessi/spostati non ancora mai trasmessi, sostituzione di altro ordinativo codice_funzione='S' -- 'SOSPENSIONE'
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_S||'.';

      insert into mif_t_ordinativo_spesa_id
	  (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
 	   mif_ord_soggetto_id, mif_ord_modpag_id,
 	   mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
 	   mif_ord_liq_id, mif_ord_atto_amm_id, mif_ord_contotes_id, mif_ord_dist_id,
       mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_siope_tipo_debito_id,mif_ord_siope_assenza_motivazione_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
	  (
       with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_S mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
               ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,
               0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id ,0 mif_ord_modpag_id,0 mif_ord_subord_id,
               elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_liq_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.dist_id mif_ord_dist_id,ord.codbollo_id mif_ord_codbollo_id,
               ord.comm_tipo_id mif_ord_comm_tipo_id,ord.notetes_id mif_ord_notetes_id,
               ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.siope_tipo_debito_id,ord.siope_assenza_motivazione_id,
               ord.login_creazione mif_ord_login_creazione, ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
  	    from siac_t_ordinativo ord,siac_r_ordinativo_stato ord_stato,
             siac_t_bil bil, siac_t_periodo per,
             siac_r_ordinativo_bil_elem elem,siac_r_ordinativo rord
  	    where  bil.ente_proprietario_id=enteProprietarioId
   		  and  per.periodo_id=bil.periodo_id
    	  and  per.anno::integer <=annoBilancio::integer
      	  and  ord.bil_id=bil.bil_id
     	  and  ord.ord_tipo_id=ordTipoCodeId
    	  and  ord_stato.ord_id=ord.ord_id
    	  and  ord_stato.data_cancellazione is null
	   	  and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
  	      and  ord_stato.validita_fine is null
    	  and  ord_stato.ord_stato_id=ordStatoCodeIId
	      and  ord.ord_trasm_oil_data is null
    	  and  ord.ord_emissione_data<=dataElaborazione
    	  and  elem.ord_id=ord.ord_id
    	  and  elem.data_cancellazione is null
          and  elem.validita_fine is null
          and  rord.ord_id_a=ord.ord_id
          and  rord.relaz_tipo_id=ordRelazCodeTipoId
          and  rord.data_cancellazione is null
          and  rord.validita_fine is null
        )
        select  o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
		       o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
     		   o.mif_ord_soggetto_id, o.mif_ord_modpag_id,
               o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_liq_id, o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_dist_id,
               o.mif_ord_codbollo_id,o.mif_ord_comm_tipo_id,o.mif_ord_notetes_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.siope_tipo_debito_id,o.siope_assenza_motivazione_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
        from ordinativi o
	    where mifOrdRitrasmElabId is null
		   or (mifOrdRitrasmElabId is not null and exists
              (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
      );

      -- ordinativi emessi e annullati mai trasmessi codice_funzione='N' -- ANNULLO
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_N||'.';

	  insert into mif_t_ordinativo_spesa_id
	  (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
	   mif_ord_soggetto_id, mif_ord_modpag_id,
	   mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
 	   mif_ord_liq_id, mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_dist_id,
       mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_siope_tipo_debito_id,mif_ord_siope_assenza_motivazione_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
	  (
       with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_N mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
      	 	   ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,
               0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_modpag_id,0 mif_ord_subord_id,
               elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_liq_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.dist_id mif_ord_dist_id,
               ord.codbollo_id mif_ord_codbollo_id,ord.comm_tipo_id mif_ord_comm_tipo_id,
               ord.notetes_id mif_ord_notetes_id,ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.siope_tipo_debito_id,ord.siope_assenza_motivazione_id,
               ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
  	    from siac_t_ordinativo ord, siac_r_ordinativo_stato ord_stato,
             siac_t_bil bil, siac_t_periodo per,
             siac_r_ordinativo_bil_elem elem
        where  bil.ente_proprietario_id=enteProprietarioId
         and  per.periodo_id=bil.periodo_id
         and  per.anno::integer <=annoBilancio::integer
         and  ord.bil_id=bil.bil_id
         and  ord.ord_tipo_id=ordTipoCodeId
         and  ord_stato.ord_id=ord.ord_id
         and  ord_stato.validita_inizio<=dataElaborazione -- questa e'' la data di annullamento
         and  ord.ord_emissione_data<=dataElaborazione
         and  ord_stato.data_cancellazione is null
         and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
  	     and  ord_stato.validita_fine is null
         and  ord_stato.ord_stato_id=ordStatoCodeAId
         and  ord.ord_trasm_oil_data is null
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  elem.validita_fine is null
       )
       select  o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
		       o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
     		   o.mif_ord_soggetto_id, o.mif_ord_modpag_id,
               o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_liq_id, o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_dist_id,
               o.mif_ord_codbollo_id,o.mif_ord_comm_tipo_id,o.mif_ord_notetes_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.siope_tipo_debito_id,o.siope_assenza_motivazione_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id , o.login_operazione
       from ordinativi o
	   where mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
	   );

      -- ordinativi emessi tramessi e poi annullati, anche dopo spostamento  codice_funzione='A' -- ANNULLO
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_A||'.';

      insert into mif_t_ordinativo_spesa_id
      (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_modpag_id,
       mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_liq_id, mif_ord_atto_amm_id,mif_ord_contotes_id,mif_ord_dist_id,
       mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_siope_tipo_debito_id,mif_ord_siope_assenza_motivazione_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
      (
       with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_A mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
               ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,
               0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_modpag_id,0 mif_ord_subord_id,
               elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_liq_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.dist_id mif_ord_dist_id,ord.codbollo_id mif_ord_codbollo_id,
               ord.comm_tipo_id mif_ord_comm_tipo_id,
               ord.notetes_id mif_ord_notetes_id,ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.siope_tipo_debito_id,ord.siope_assenza_motivazione_id,
               ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
        from siac_t_ordinativo ord,siac_r_ordinativo_stato ord_stato,
             siac_t_bil bil, siac_t_periodo per,
             siac_r_ordinativo_bil_elem elem
        where  bil.ente_proprietario_id=enteProprietarioId
          and  per.periodo_id=bil.periodo_id
          and  per.anno::integer <=annoBilancio::integer
          and  ord.bil_id=bil.bil_id
          and  ord.ord_tipo_id=ordTipoCodeId
   		  and  ord_stato.ord_id=ord.ord_id
  		  and  ord.ord_emissione_data<=dataElaborazione
          and  ord_stato.validita_inizio<=dataElaborazione  -- questa e'' la data di annullamento
  		  and  ord.ord_trasm_oil_data is not null
 		  and  ord.ord_trasm_oil_data<ord_stato.validita_inizio
          and  ord_stato.data_cancellazione is null
          and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
  	      and  ord_stato.validita_fine is null
          and  ord_stato.ord_stato_id=ordStatoCodeAId
          and  ( ord.ord_spostamento_data is null or ord.ord_spostamento_data<ord_stato.validita_inizio)
          and  elem.ord_id=ord.ord_id
          and  elem.data_cancellazione is null
          and  elem.validita_fine is null
        )
        select o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
		       o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
     		   o.mif_ord_soggetto_id, o.mif_ord_modpag_id,
               o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_liq_id, o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_dist_id,
               o.mif_ord_codbollo_id,o.mif_ord_comm_tipo_id,o.mif_ord_notetes_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.siope_tipo_debito_id,o.siope_assenza_motivazione_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id , o.login_operazione
        from ordinativi o
	    where mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))

       );
      -- ordinativi emessi , trasmessi  e poi spostati codice_funzione='VB' ( mai annullati ) _--- VARIAZIONE
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_VB||'.';

      insert into mif_t_ordinativo_spesa_id
      (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_modpag_id,
       mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_liq_id, mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_dist_id,
       mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_siope_tipo_debito_id,mif_ord_siope_assenza_motivazione_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
      (
       with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_VB mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
               ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,
               0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_modpag_id,0 mif_ord_subord_id,
               elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_liq_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.dist_id mif_ord_dist_id,ord.codbollo_id mif_ord_codbollo_id,
               ord.comm_tipo_id mif_ord_comm_tipo_id,
               ord.notetes_id mif_ord_notetes_id,ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.siope_tipo_debito_id,ord.siope_assenza_motivazione_id,
               ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
        from siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per, siac_r_ordinativo_bil_elem elem
        where  bil.ente_proprietario_id=enteProprietarioId
         and  per.periodo_id=bil.periodo_id
         and  per.anno::integer <=annoBilancio::integer
         and  ord.bil_id=bil.bil_id
         and  ord.ord_tipo_id=ordTipoCodeId
         and  ord.ord_emissione_data<=dataElaborazione
         and  ord.ord_trasm_oil_data is not null
         and  ord.ord_spostamento_data is not null
         and  ord.ord_trasm_oil_data<ord.ord_spostamento_data
         and  ord.ord_spostamento_data<=dataElaborazione
         and  not exists (select 1 from siac_r_ordinativo_stato ord_stato
  				          where  ord_stato.ord_id=ord.ord_id
					        and  ord_stato.ord_stato_id=ordStatoCodeAId
                            and  ord_stato.data_cancellazione is null)
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  elem.validita_fine is null
        )
       select o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
		       o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
     		   o.mif_ord_soggetto_id, o.mif_ord_modpag_id,
               o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_liq_id, o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_dist_id,
               o.mif_ord_codbollo_id,o.mif_ord_comm_tipo_id,o.mif_ord_notetes_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.siope_tipo_debito_id,o.siope_assenza_motivazione_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id , o.login_operazione
       from ordinativi o
	   where mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
      );
      -- aggiornamento mif_t_ordinativo_spesa_id per id


      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per fase_operativa_code.';
      update mif_t_ordinativo_spesa_id m
      set mif_ord_bil_fase_ope=(select fase.fase_operativa_code from siac_r_bil_fase_operativa rFase, siac_d_fase_operativa fase
      							where rFase.bil_id=m.mif_ord_bil_id
                                and   rFase.data_cancellazione is null
                                and   rFase.validita_fine is null
                                and   fase.fase_operativa_id=rFase.fase_operativa_id
                                and   fase.data_cancellazione is null
                                and   fase.validita_fine is null);


      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per soggetto_id.';
      -- soggetto_id

      update mif_t_ordinativo_spesa_id m
      set mif_ord_soggetto_id=coalesce(s.soggetto_id,0)
      from siac_r_ordinativo_soggetto s
      where s.ord_id=m.mif_ord_ord_id
      and s.data_cancellazione is null
      and s.validita_fine is null;

      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per modpag_id.';

      -- modpag_id
      update mif_t_ordinativo_spesa_id m set  mif_ord_modpag_id=coalesce(s.modpag_id,0)
      from siac_r_ordinativo_modpag s
      where s.ord_id=m.mif_ord_ord_id
   	  and s.modpag_id is not null
      and s.data_cancellazione is null
      and s.validita_fine is null;

      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per modpag_id [CSI].';
      update mif_t_ordinativo_spesa_id m set mif_ord_modpag_id=coalesce(rel.modpag_id,0)
      from siac_r_ordinativo_modpag s, siac_r_soggrel_modpag rel
      where s.ord_id=m.mif_ord_ord_id
      and s.soggetto_relaz_id is not null
      and rel.soggetto_relaz_id=s.soggetto_relaz_id
      and s.data_cancellazione is null
      and s.validita_fine is null
      and rel.data_cancellazione is null
      and rel.validita_fine is null
      and exists  (select  1 from siac_r_soggrel_modpag rel1
                   where    rel.soggetto_relaz_id=s.soggetto_relaz_id
		           and      rel1.soggrelmpag_id=rel.soggrelmpag_id
         		   order by rel1.modpag_id
			       limit 1);

      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per subord_id.';

      -- subord_id
      update mif_t_ordinativo_spesa_id m
      set mif_ord_subord_id =
                             (select s.ord_ts_id from siac_t_ordinativo_ts s
                               where s.ord_id=m.mif_ord_ord_id
                                 and s.data_cancellazione is null
                                 and s.validita_fine is null
                               order by s.ord_ts_id
                               limit 1);

     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per liq_id.';

	 -- liq_id
	 update mif_t_ordinativo_spesa_id m
	 set mif_ord_liq_id = (select s.liq_id from siac_r_liquidazione_ord s
                            where s.sord_id = m.mif_ord_subord_id
                              and s.data_cancellazione is null
                              and s.validita_fine is null);
     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per movgest_ts_id.';

     -- movgest_ts_id
     update mif_t_ordinativo_spesa_id m
     set mif_ord_movgest_ts_id = (select s.movgest_ts_id from siac_r_liquidazione_movgest s
                                   where s.liq_id = m.mif_ord_liq_id
                                     and s.data_cancellazione is null
                                     and s.validita_fine is null);
     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per movgest_id.';

     -- movgest_id
     update mif_t_ordinativo_spesa_id m
     set mif_ord_movgest_id = (select s.movgest_id from siac_t_movgest_ts s
                               where  s.movgest_ts_id = m.mif_ord_movgest_ts_id
                               and s.data_cancellazione is null
                               and s.validita_fine is null);

     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per movgest_id.';

     -- movgest_anno
     update mif_t_ordinativo_spesa_id m
     set mif_ord_ord_anno_movg = (select s.movgest_anno from siac_t_movgest s
                              	  where  s.movgest_id = m.mif_ord_movgest_id
                             	  and s.data_cancellazione is null
                                  and s.validita_fine is null);


     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per attoamm_id.';

    -- attoamm_id
    update mif_t_ordinativo_spesa_id m
    set mif_ord_atto_amm_id = (select s.attoamm_id from siac_r_liquidazione_atto_amm s
                                where s.liq_id = m.mif_ord_liq_id
                                  and s.data_cancellazione is null
                                  and s.validita_fine is null);

    strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per attoamm_id movgest_ts.';
	-- attoamm_movgest_ts_id
    update mif_t_ordinativo_spesa_id m
    set mif_ord_atto_amm_movg_id = (select s.attoamm_id from siac_r_movgest_ts_atto_amm s
                                    where s.movgest_ts_id = m.mif_ord_movgest_ts_id
                                    and s.data_cancellazione is null
                                    and s.validita_fine is null);

	-- mif_ord_programma_id
    -- mif_ord_programma_code
    -- mif_ord_programma_desc
    strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per mif_ord_programma_id mif_ord_programma_code mif_ord_programma_desc.';
    update mif_t_ordinativo_spesa_id m
    set (mif_ord_programma_id,mif_ord_programma_code,mif_ord_programma_desc) = (class.classif_id,class.classif_code,class.classif_desc) -- 11.01.2016 Sofia
    from siac_r_bil_elem_class classElem, siac_t_class class
    where classElem.elem_id=m.mif_ord_elem_id
    and   class.classif_id=classElem.classif_id
    and   class.classif_tipo_id=programmaCodeTipoId
    and   classElem.data_cancellazione is null
    and   classElem.validita_fine is null
    and   class.data_cancellazione is null;

	-- mif_ord_titolo_id
    -- mif_ord_titolo_code
    strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per mif_ord_titolo_id mif_ord_titolo_code.';
    update mif_t_ordinativo_spesa_id m
    set (mif_ord_titolo_id, mif_ord_titolo_code) = (cp.classif_id,cp.classif_code)
	from siac_r_bil_elem_class classElem, siac_t_class cf, siac_r_class_fam_tree r, siac_t_class cp
	where classElem.elem_id=m.mif_ord_elem_id
    and   cf.classif_id=classElem.classif_id
    and   cf.data_cancellazione is null
    and   classElem.data_cancellazione is null
    and   classElem.validita_fine is null
	and   r.classif_id=cf.classif_id
	and   r.classif_id_padre is not null
	and   r.classif_fam_tree_id=famTitSpeMacroAggrCodeId
    and   r.data_cancellazione is null
    and   r.validita_fine is null
	and   cp.classif_id=r.classif_id_padre
    and   cp.data_cancellazione is null;






	-- mif_ord_note_attr_id
	strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per mif_ord_note_attr_id.';
	update mif_t_ordinativo_spesa_id m
    set mif_ord_note_attr_id= attr.ord_attr_id
    from siac_r_ordinativo_attr attr
    where attr.ord_id=m.mif_ord_ord_id
    and   attr.attr_id=noteOrdAttrId
    and   attr.data_cancellazione is null
    and   attr.validita_fine is null;


    strMessaggio:='Verifica esistenza ordinativi di spesa da trasmettere.';
    codResult:=null;
    select 1 into codResult
    from mif_t_ordinativo_spesa_id where ente_proprietario_id=enteProprietarioId;

    if codResult is null then
      codResult:=-12;
      RAISE EXCEPTION ' Nessun ordinativo di spesa da trasmettere.';
    end if;


    -- <ritenute>
    flussoElabMifElabRec:=null;
    flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_RITENUTA];

    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                   ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
    	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifParam is not null then
  					tipoRelazRitOrd:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
	                tipoRelazSprOrd:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
	                tipoRelazSubOrd:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    tipoOnereIrpef:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
                    tipoOnereInps:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5));
                    tipoOnereIrpeg:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,6));


                    if tipoRelazRitOrd is null or tipoRelazSprOrd is null or tipoRelazSubOrd is null
                       or tipoOnereInps is null or tipoOnereIrpef is null
                       or tipoOnereIrpeg is null then
                       RAISE EXCEPTION ' Dati configurazione ritenute non completi.';
                    end if;
                    isRitenutaAttivo:=true;
            end if;
	    else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	   	end if;
   end if;

   if isRitenutaAttivo=true then
     	flussoElabMifElabRec:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_RITENUTA_PRG];
         strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	   	 if flussoElabMifElabRec.flussoElabMifId is null then
  			  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	   	 end if;
    	 if flussoElabMifElabRec.flussoElabMifAttivo=true then
    		if flussoElabMifElabRec.flussoElabMifElab=true then
            	if flussoElabMifElabRec.flussoElabMifDef is not null then
                	progrRitenuta:=flussoElabMifElabRec.flussoElabMifDef;
                end if;
	    	else
				RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	   		end if;
	     else
    	   isRitenutaAttivo:=false;
		 end if;
   end if;

   if isRitenutaAttivo=true then
           strMessaggio:='Lettura dati identificativo tipo Onere '||tipoOnereIrpef
                       ||' sezione ritenute - tipo flusso '||MANDMIF_TIPO||'.';

           select tipo.onere_tipo_id into tipoOnereIrpefId
           from siac_d_onere_tipo tipo
           where tipo.ente_proprietario_id=enteProprietarioId
           and   tipo.onere_tipo_code=tipoOnereIrpef
           and   tipo.data_cancellazione is null
 	  	   and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
   		   and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

           if tipoOnereIrpefId is null then
            	RAISE EXCEPTION ' Dato non reperito.';
           end if;

           strMessaggio:='Lettura dati identificativo tipo Onere '||tipoOnereInps
                       ||' sezione ritenute - tipo flusso '||MANDMIF_TIPO||'.';

           select tipo.onere_tipo_id into tipoOnereInpsId
           from siac_d_onere_tipo tipo
           where tipo.ente_proprietario_id=enteProprietarioId
           and   tipo.onere_tipo_code=tipoOnereInps
           and   tipo.data_cancellazione is null
 	  	   and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		   and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));


           if tipoOnereInpsId is null then
            	RAISE EXCEPTION ' Dato non reperito.';
           end if;

		   strMessaggio:='Lettura dati identificativo tipo Onere '||tipoOnereIrpeg
                        ||' sezione ritenute - tipo flusso '||MANDMIF_TIPO||'.';

           select tipo.onere_tipo_id into tipoOnereIrpegId
           from siac_d_onere_tipo tipo
           where tipo.ente_proprietario_id=enteProprietarioId
           and   tipo.onere_tipo_code=tipoOnereIrpeg
           and   tipo.data_cancellazione is null
 	  	   and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		   and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));


           if tipoOnereIrpegId is null then
            	RAISE EXCEPTION ' Dato non reperito.';
           end if;
   end if;


   -- <sospesi>
   -- <sospeso>
   -- <numero_provvisorio>
   -- <importo_provvisorio>
   flussoElabMifElabRec:=null;
   flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_NUM_SOSPESO];
   mifCountRec:=FLUSSO_MIF_ELAB_NUM_SOSPESO;
   strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   if flussoElabMifElabRec.flussoElabMifId is null then
  	  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
   end if;
   if flussoElabMifElabRec.flussoElabMifAttivo=true then
    	if flussoElabMifElabRec.flussoElabMifElab=true then
			null;
        else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
   		end if;
        isRicevutaAttivo:=true;
   end if;




   flussoElabMifElabRec:=null;
   mifCountRec:=FLUSSO_MIF_ELAB_FATTURE;
   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
   strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
   if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
   end if;
   if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	if flussoElabMifElabRec.flussoElabMifElab=true then
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
 		    numeroDocs:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            tipoDocs  :=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
            tipoGruppoDocs  :=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
            if numeroDocs is not null and numeroDocs!='' and
               tipoDocs is not null and tipoDocs!='' and
               tipoGruppoDocs is not null and tipoGruppoDocs!='' then
                tipoDocs:=tipoDocs||'|'||tipoGruppoDocs;
            	isGestioneFatture:=true;
            end if;
		end if;
    else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
    end if;
   end if;

   if isGestioneFatture=true then

    flussoElabMifElabRec:=null;
    mifCountRec:=FLUSSO_MIF_ELAB_FATT_CODFISC;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	 if flussoElabMifElabRec.flussoElabMifElab=true then
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
 		    docAnalogico:=flussoElabMifElabRec.flussoElabMifParam;
		end if;
     else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
    end if;

   end if;

   if isGestioneFatture=true then
    flussoElabMifElabRec:=null;
    mifCountRec:=FLUSSO_MIF_ELAB_FATT_DATASCAD_PAG;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	 if flussoElabMifElabRec.flussoElabMifElab=true then
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
            attrCodeDataScad:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
		end if;
     else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
    end if;

   end if;

   if isGestioneFatture=true then

    flussoElabMifElabRec:=null;
    mifCountRec:=FLUSSO_MIF_ELAB_FATT_NATURA_PAG;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	 if flussoElabMifElabRec.flussoElabMifElab=true then
        -- 20.02.2018 Sofia JIRA siac-5849
        /*
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
            titoloCorrente:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            descriTitoloCorrente:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
            titoloCapitale:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
            descriTitoloCapitale:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));

		end if;*/

        -- 20.02.2018 Sofia JIRA siac-5849
        if flussoElabMifElabRec.flussoElabMifDef is not null then
        	defNaturaPag:=flussoElabMifElabRec.flussoElabMifDef;
        end if;
     else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
    end if;

   end if;

   --- lettura mif_t_ordinativo_spesa_id per popolamento mif_t_ordinativo_spesa
   codResult:=null;
   strMessaggio:='Lettura ordinativi di spesa da migrare [mif_t_ordinativo_spesa_id].Inizio ciclo.';
   for mifOrdinativoIdRec IN
   (select ms.*
     from mif_t_ordinativo_spesa_id ms
     where ms.ente_proprietario_id=enteProprietarioId
     order by ms.mif_ord_anno_bil,
              ms.mif_ord_ord_numero
   )
   loop


		mifFlussoOrdinativoRec:=null;
		MDPRec:=null;
        codAccreRec:=null;
		bilElemRec:=null;
        soggettoRec:=null;
        soggettoSedeRec:=null;
        soggettoRifId:=null;
        soggettoSedeSecId:=null;
		indirizzoRec:=null;
        mifOrdSpesaId:=null;




        isIndirizzoBenef:=true;
        isIndirizzoBenQuiet:=true;


        bavvioFrazAttr:=false;
        bAvvioSiopeNew:=false;


	    statoBeneficiario:=false;
		statoDelegatoCredEff:=false;

        -- lettura importo ordinativo
 		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura importo ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

        mifFlussoOrdinativoRec.mif_ord_importo:=fnc_mif_importo_ordinativo(mifOrdinativoIdRec.mif_ord_ord_id,ordDetTsTipoId,
        													  		       flussoElabMifTipoDec);
        if flussoElabMifTipoDec=true and
           coalesce(position('.' in mifFlussoOrdinativoRec.mif_ord_importo),0)=0 then
           mifFlussoOrdinativoRec.mif_ord_importo:=mifFlussoOrdinativoRec.mif_ord_importo||'.00';
        end if;

        -- lettura MDP ti ordinativo
 		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura MDP ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

		select * into MDPRec
        from siac_t_modpag mdp
        where mdp.modpag_id=mifOrdinativoIdRec.mif_ord_modpag_id;
        if MDPRec is null then
        	RAISE EXCEPTION ' Errore in lettura siac_t_modpag.';
        end if;

        -- lettura accreditoTipo ti ordinativo
 		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura accredito tipo ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

        select tipo.accredito_tipo_id, tipo.accredito_tipo_code,tipo.accredito_tipo_desc,
               gruppo.accredito_gruppo_id, gruppo.accredito_gruppo_code
               into codAccreRec
        from siac_d_accredito_tipo tipo, siac_d_accredito_gruppo gruppo
        where tipo.accredito_tipo_id=MDPRec.accredito_tipo_id
          and tipo.data_cancellazione is null
          and date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		  and date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione))
          and gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id;
        if codAccreRec is null then
        	RAISE EXCEPTION ' Errore in lettura siac_d_accredito_tipo siac_d_accredito_gruppo.';
        end if;


        -- lettura dati soggetto ordinativo
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati soggetto [siac_r_soggetto_relaz] ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';
        select rel.soggetto_id_da into soggettoRifId
        from  siac_r_soggetto_relaz rel
        where rel.soggetto_id_a=mifOrdinativoIdRec.mif_ord_soggetto_id
        and   rel.relaz_tipo_id=ordSedeSecRelazTipoId
        and   rel.ente_proprietario_id=enteProprietarioId
        and   rel.data_cancellazione is null
		and   rel.validita_fine is null;

        if soggettoRifId is null then
	        soggettoRifId:=mifOrdinativoIdRec.mif_ord_soggetto_id;
        else
        	soggettoSedeSecId:=mifOrdinativoIdRec.mif_ord_soggetto_id;
        end if;

        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati soggetto di riferimento ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

        select * into soggettoRec
   	    from siac_t_soggetto sogg
       	where sogg.soggetto_id=soggettoRifId;

        if soggettoRec is null then
        	RAISE EXCEPTION ' Errore in lettura siac_t_soggetto [soggetto_id= %].',soggettoRifId;
        end if;

        if soggettoSedeSecId is not null then
	        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati sede sec. soggetto di riferimento ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

            select * into soggettoSedeRec
   		    from siac_t_soggetto sogg
	       	where sogg.soggetto_id=soggettoSedeSecId;

	        if soggettoSedeRec is null then
    	    	RAISE EXCEPTION ' Errore in lettura siac_t_soggetto [soggetto_id=%]',soggettoSedeSecId;
        	end if;

        end if;



        -- lettura elemento bilancio  ordinativo
 		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura elemento bilancio ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

		select * into bilElemRec
        from siac_t_bil_elem elem
        where elem.elem_id=mifOrdinativoIdRec.mif_ord_elem_id;
        if bilElemRec is null then
        	RAISE EXCEPTION ' Errore in lettura siac_t_bil_elem.';
        end if;

		-- dati testata flusso presenti come tag solo in testata
        -- valorizzati su ogni ordinativo trasmesso
        -- <testata_flusso>
		-- <codice_ABI_BT>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ABI_BT;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_abi is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_abi_bt:=enteOilRec.ente_oil_abi;
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_abi_bt:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <codice_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ENTE_IPA;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_ipa is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_ipa:=trim(both ' ' from enteOilRec.ente_oil_codice_ipa);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_ipa:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <descrizione_ente>
	    flussoElabMifElabRec:=null;
		mifCountRec:=FLUSSO_MIF_ELAB_TEST_DESC_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteProprietarioRec.ente_denominazione is not null then
            	mifFlussoOrdinativoRec.mif_ord_desc_ente:=enteProprietarioRec.ente_denominazione;
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
               	mifFlussoOrdinativoRec.mif_ord_desc_ente:=substring(flussoElabMifElabRec.flussoElabMifDef from 1 for 30);
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

	    -- <codice_istat_ente>
	    flussoElabMifElabRec:=null;
		mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ISTAT_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_istat is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_istat:=enteOilRec.ente_oil_codice_istat;
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
               	mifFlussoOrdinativoRec.mif_ord_codice_ente_istat:=substring(flussoElabMifElabRec.flussoElabMifDef from 1 for 30);
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <codice_fiscale_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_CODFISC_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteProprietarioRec.codice_fiscale is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente:=trim(both ' ' from enteProprietarioRec.codice_fiscale);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <codice_tramite_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_CODTRAMITE_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_tramite is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite:=trim(both ' ' from enteOilRec.ente_oil_codice_tramite);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <codice_tramite_BT>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_CODTRAMITE_BT;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_tramite_bt is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite_bt:=trim(both ' ' from enteOilRec.ente_oil_codice_tramite_bt);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite_bt:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <codice_ente_BT>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ENTE_BT;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_bt:=trim(both ' ' from enteOilRec.ente_oil_codice);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_bt:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <riferimento_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_RIFERIMENTO_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_riferimento is not null then
            	mifFlussoOrdinativoRec.mif_ord_riferimento_ente:=trim(both ' ' from enteOilRec.ente_oil_riferimento);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_riferimento_ente:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;
        -- </testata_flusso>

        -- <testata_esercizio>
        -- <esercizio>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_ESERCIZIO;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            mifFlussoOrdinativoRec.mif_ord_anno_esercizio:=mifOrdinativoIdRec.mif_ord_anno_bil;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;
        -- </testata_esercizio>

        mifCountRec:=FLUSSO_MIF_ELAB_INIZIO_ORD;
        mifCountTmpRec:=FLUSSO_MIF_ELAB_INIZIO_ORD;

        -- <mandato>
		-- <tipo_operazione>
        flussoElabMifElabRec:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if  flussoElabMifElabRec.flussoElabMifAttivo=true then
         if   flussoElabMifElabRec.flussoElabMifElab=true then
            if flussoElabMifElabRec.flussoElabMifParam is not null then
	            flussoElabMifValore:=fnc_mif_ordinativo_carico_bollo( mifOrdinativoIdRec.mif_ord_codice_funzione,flussoElabMifElabRec.flussoElabMifParam);
            else
            	flussoElabMifValore:=mifOrdinativoIdRec.mif_ord_codice_funzione;
            end if;
            if flussoElabMifValore is not null then
				mifFlussoOrdinativoRec.mif_ord_codice_funzione:=flussoElabMifValore;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <numero_mandato>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
/*         	if flussoElabMifTipoDec=false then
				mifFlussoOrdinativoRec.mif_ord_numero:=lpad(mifOrdinativoIdRec.mif_ord_ord_numero,NUM_SETTE,ZERO_PAD);
            else
	            mifFlussoOrdinativoRec.mif_ord_numero:=mifOrdinativoIdRec.mif_ord_ord_numero;
            end if;*/
            mifFlussoOrdinativoRec.mif_ord_numero:=mifOrdinativoIdRec.mif_ord_ord_numero;
         else
            RAISE EXCEPTION ' Configurazione tag/campo non elaborabile.';
         end if;
        end if;


        -- <data_mandato>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true  then
         if  flussoElabMifElabRec.flussoElabMifElab=true then
			mifFlussoOrdinativoRec.mif_ord_data:=mifOrdinativoIdRec.mif_ord_data_emissione;
         else
            RAISE EXCEPTION ' Configurazione tag/campo non  elaborabile.';
         end if;
        end if;



		-- <importo_mandato>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
			-- calcolato inizio ciclo
            null;
         else
         	mifFlussoOrdinativoRec.mif_ord_importo:='0';
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <conto_evidenza>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
			if mifOrdinativoIdRec.mif_ord_contotes_id is not null then
                 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
					   ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura conto tesoreria.';


            	select d.contotes_code into flussoElabMifValore
                from siac_d_contotesoreria d
                where d.contotes_id=mifOrdinativoIdRec.mif_ord_contotes_id;
                if flussoElabMifValore is null then
                	RAISE EXCEPTION ' Dato non presente in archivio.';
                end if;
            end if;

            if flussoElabMifValore is not null then
	            mifFlussoOrdinativoRec.mif_ord_bci_conto_tes:=substring(flussoElabMifValore from 1 for 7 );
            end if;

         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <estremi_provvedimento_autorizzativo>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
					   ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        flussoElabMifValore:=null;
        attoAmmRec:=null;
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
           if mifOrdinativoIdRec.mif_ord_atto_amm_id is not null then
			if flussoElabMifElabRec.flussoElabMifParam is not null then
                if attoAmmTipoSpr is null then
            		attoAmmTipoSpr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if attoAmmTipoAll is null then
                	attoAmmTipoAll:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
            	end if;
            end if;

            select * into attoAmmRec
            from fnc_mif_estremi_atto_amm(mifOrdinativoIdRec.mif_ord_atto_amm_id,
                                          mifOrdinativoIdRec.mif_ord_atto_amm_movg_id,
                                          attoAmmTipoSpr,attoAmmTipoAll,
                                          dataElaborazione,dataFineVal);
           end if;

           if attoAmmRec.attoAmmEstremi is not null   then
                mifFlussoOrdinativoRec.mif_ord_estremi_attoamm:=attoAmmRec.attoAmmEstremi;
           elseif flussoElabMifElabRec.flussoElabMifDef is not null then
           		mifFlussoOrdinativoRec.mif_ord_estremi_attoamm:=flussoElabMifElabRec.flussoElabMifDef;
           end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
       end if;


       -- <responsabile_provvedimento>
	   flussoElabMifElabRec:=null;
	   flussoElabMifValore:=null;
	   flussoElabMifValoreDesc:=null;
	   mifCountRec:=mifCountRec+1;
	   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
	  if flussoElabMifElabRec.flussoElabMifAttivo=true then
   		if flussoElabMifElabRec.flussoElabMifElab=true then


         if mifOrdinativoIdRec.mif_ord_login_creazione is not null then
			flussoElabMifValore:=mifOrdinativoIdRec.mif_ord_login_creazione;
         end if;

         if flussoElabMifValore is not null then
        	select substring(s.soggetto_desc  from 1 for 12)  into flussoElabMifValoreDesc
			from siac_t_account a, siac_r_soggetto_ruolo r, siac_t_soggetto s
			where a.ente_proprietario_id=enteProprietarioId
            and   a.account_code=flussoElabMifValore
			and   r.soggeto_ruolo_id=a.soggeto_ruolo_id
			and   s.soggetto_id=r.soggetto_id
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   a.data_cancellazione is null
            and   a.validita_fine is null;

            if 	flussoElabMifValoreDesc is not null then
            	flussoElabMifValore:=flussoElabMifValoreDesc;
            end if;
         end if;

         if flussoElabMifValore is not null then
            mifFlussoOrdinativoRec.mif_ord_resp_attoamm:=substring(flussoElabMifValore from 1 for 12);
         end if;
       else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	   end if;
     end if;

     -- <ufficio_responsabile>
     mifCountRec:=mifCountRec+1;

     -- <bilancio>
     -- <codifica_bilancio>
     flussoElabMifElabRec:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then

                mifFlussoOrdinativoRec.mif_ord_codifica_bilancio:=mifOrdinativoIdRec.mif_ord_programma_code
                												||mifOrdinativoIdRec.mif_ord_titolo_code;

                mifFlussoOrdinativoRec.mif_ord_capitolo:=bilElemRec.elem_code;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;

	  -- <descrizione_codifica>
      flussoElabMifElabRec:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            	mifFlussoOrdinativoRec.mif_ord_desc_codifica:=substring( bilElemRec.elem_desc from 1 for 30);
                mifFlussoOrdinativoRec.mif_ord_desc_codifica_bil:=substring( mifOrdinativoIdRec.mif_ord_programma_desc from 1 for 30);
     	 else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     	 end if;
      end if;

      -- <gestione>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if flussoElabMifElabRec.flussoElabMifDef is not null then
            	if mifOrdinativoIdRec.mif_ord_anno_bil=mifOrdinativoIdRec.mif_ord_ord_anno_movg then
	            	flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
                else
	                flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
                end if;
            	mifFlussoOrdinativoRec.mif_ord_gestione:=flussoElabMifValore;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;

      -- <anno_residuo>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then

            if  mifOrdinativoIdRec.mif_ord_anno_bil!=mifOrdinativoIdRec.mif_ord_ord_anno_movg  then
               	   mifFlussoOrdinativoRec.mif_ord_anno_res:=mifOrdinativoIdRec.mif_ord_ord_anno_movg;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;


      -- <numero_articolo>
      flussoElabMifElabRec:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            	mifFlussoOrdinativoRec.mif_ord_articolo:=bilElemRec.elem_code2;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;

      -- <voce_economica>
      mifCountRec:=mifCountRec+1;


      -- <importo_bilancio>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
           	mifFlussoOrdinativoRec.mif_ord_importo_bil:=mifFlussoOrdinativoRec.mif_ord_importo;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
      end if;

      -- </bilancio>

      -- <funzionario_delegato>
      -- <codice_funzionario_delegato>
      -- <importo_funzionario_delegato>
      -- <tipologia_funzionario_delegato>
      -- <numero_pagamento_funzionario_delegato>
      mifCountRec:=mifCountRec+5;

      -- <informazioni_beneficiario>

      -- <progressivo_beneficiario>
      flussoElabMifElabRec:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
--	  raise notice 'progressivo_beneficiario mifCountRec=%',mifCountRec;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
                if flussoElabMifElabRec.flussoElabMifDef is not null then
                	mifFlussoOrdinativoRec.mif_ord_progr_benef:=flussoElabMifElabRec.flussoElabMifDef;
                end if;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
      end if;

      -- <importo_beneficiario>
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
     		mifFlussoOrdinativoRec.mif_ord_importo_benef:=mifFlussoOrdinativoRec.mif_ord_importo;
	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
      end if;


	  -- <tipo_pagamento>
      flussoElabMifElabRec:=null;
      tipoPagamRec:=null;
	  mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
     	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
	 	if flussoElabMifElabRec.flussoElabMifElab=true then
    	   	if flussoElabMifElabRec.flussoElabMifParam is not null and
               flussoElabMifElabRec.flussoElabMifDef is not null then
            	if codicePaeseIT is null then
                	codicePaeseIT:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if codiceAccreCB is null then
	                codiceAccreCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                end if;
                if codiceAccreREG is null then
	                codiceAccreREG:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                end if;
				if codiceSepa is null then
	                codiceSepa:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
                end if;
				if codiceExtraSepa is null then
	                codiceExtraSepa:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5));
                end if;

                if codiceGFB is null then
	                codiceGFB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,6));
                end if;

                select * into tipoPagamRec
                from fnc_mif_tipo_pagamento_splus( mifOrdinativoIdRec.mif_ord_ord_id,
											       (case when MDPRec.iban is not null and length(MDPRec.iban)>=2
                                                   then substring(MDPRec.iban from 1 for 2)
                                                   else null end), -- codicePaese
	                                               codicePaeseIT,codiceSepa,codiceExtraSepa,
                                                   codiceAccreCB,codiceAccreREG,
                                                   flussoElabMifElabRec.flussoElabMifDef, -- compensazione
												   MDPRec.accredito_tipo_id,
                                                   codAccreRec.accredito_gruppo_code,
                                                   mifFlussoOrdinativoRec.mif_ord_importo::NUMERIC, -- importo_ordinativo
                                                   (case when codAccreRec.accredito_tipo_code=codiceGFB then true else false end),
	                                               dataElaborazione,dataFineVal,
                                                   enteProprietarioId);
                if tipoPagamRec is not null then
                	if tipoPagamRec.descTipoPagamento is not null then
                    	mifFlussoOrdinativoRec.mif_ord_pagam_tipo:=tipoPagamRec.descTipoPagamento;
                        mifFlussoOrdinativoRec.mif_ord_pagam_code:=tipoPagamRec.codeTipoPagamento;
                    end if;
                end if;

	        end if;
     	else
       		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;
      end if;

      -- <impignorabili>
      mifCountRec:=mifCountRec+1;


      -- <frazionabile>
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then --1
         if flussoElabMifElabRec.flussoElabMifElab=true then --2
          if flussoElabMifElabRec.flussoElabMifParam is not null and --3
             flussoElabMifElabRec.flussoElabMifDef is not null  then

             if dataAvvioFrazAttr is null then
             	dataAvvioFrazAttr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
             end if;

             if dataAvvioFrazAttr is not null and
                dataAvvioFrazAttr::timestamp<=date_trunc('DAY',mifOrdinativoIdRec.mif_ord_data_emissione::timestamp) -- data emissione ordinativo
                then
                bavvioFrazAttr:=true;
             end if;

             if bavvioFrazAttr=false then
              if classifTipoCodeFraz is null then
               classifTipoCodeFraz:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
              end if;

              if classifTipoCodeFrazVal is null then
               classifTipoCodeFrazVal:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
              end if;
             else
              if attrFrazionabile is null then
	             attrFrazionabile:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
              end if;
             end if;

             if  bavvioFrazAttr = false then
              if classifTipoCodeFraz is not null and
				 classifTipoCodeFrazVal is not null and
                 classifTipoCodeFrazId is null then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura classificatoreTipoId '||classifTipoCodeFraz||'.';
             	select tipo.classif_tipo_id into classifTipoCodeFrazId
                from siac_d_class_tipo tipo
                where tipo.ente_proprietario_id=enteProprietarioId
                and   tipo.classif_tipo_code=classifTipoCodeFraz
                and   tipo.data_cancellazione is null
                and   tipo.validita_fine is null
                order by tipo.classif_tipo_id
                limit 1;
              end if;

              if classifTipoCodeFrazVal is not null and
                 classifTipoCodeFrazId is not null then
               strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore classificatore '||classifTipoCodeFraz||' [siac_r_ordinativo_class].';
             	select c.classif_code into flussoElabMifValore
                from siac_r_ordinativo_class r, siac_t_class c
                where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                and   c.classif_id=r.classif_id
                and   c.classif_tipo_id=classifTipoCodeFrazId
                and   r.data_cancellazione is null
                and   r.validita_fine is null
                and   c.data_cancellazione is null
                order by r.ord_classif_id
                limit 1;

              end if;

              if classifTipoCodeFrazVal is not null and
                flussoElabMifValore is not null and
                flussoElabMifValore=classifTipoCodeFrazVal then
             	mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz:=flussoElabMifElabRec.flussoElabMifDef;
             end if;
			else
              if attrFrazionabile is not null then
               --- calcolo su attributo
               codResult:=null;
               select 1 into codResult
               from  siac_t_ordinativo_ts ts,siac_r_liquidazione_ord liqord,
                     siac_r_liquidazione_movgest rmov,
                     siac_r_movgest_ts_attr r, siac_t_attr attr
               where ts.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
               and   liqord.sord_id=ts.ord_ts_id
               and   rmov.liq_id=liqord.liq_id
               and   r.movgest_ts_id=rmov.movgest_ts_id
               and   attr.attr_id=r.attr_id
               and   attr.attr_code=attrFrazionabile
               and   r.boolean='N'
               and   r.data_cancellazione is null
               and   r.validita_fine is null
               and   rmov.data_cancellazione is null
               and   rmov.validita_fine is null
               and   liqord.data_cancellazione is null
               and   liqord.validita_fine is null
			   and   ts.data_cancellazione is null
               and   ts.validita_fine is null;

               if codResult is not null then
               	mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz:=flussoElabMifElabRec.flussoElabMifDef;
               end if;

             end if;

            end if;

          end if; -- 3
      	 else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;  --- 2

        end if; -- 1

  	   -- <gestione_provvisoria>
       flussoElabMifElabRec:=null;
       mifCountRec:=mifCountRec+1;
        -- gestione_provvisoria da impostare solo se frazionabile=NO
       if mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz is not null then
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
          if flussoElabMifElabRec.flussoElabMifParam is not null and
             flussoElabMifElabRec.flussoElabMifDef is not null and
             mifOrdinativoIdRec.mif_ord_bil_fase_ope is not null  then

             if tipoEsercizio is null then
	             tipoEsercizio:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
             end if;
          	if tipoEsercizio=mifOrdinativoIdRec.mif_ord_bil_fase_ope  then
				mifFlussoOrdinativoRec.mif_ord_class_codice_gest_prov=flussoElabMifElabRec.flussoElabMifDef;
            end if;
		   end if;


         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;

        end if;
        --- frazionabile da impostare NO solo se gestione_provvisoria=SI
        if mifFlussoOrdinativoRec.mif_ord_class_codice_gest_prov is null then
        	mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz:=null;
        end if;

      else
       	null;
      end if;

      -- <data_esecuzione_pagamento>
      flussoElabMifElabRec:=null;
      ordDataScadenza:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifParam is not null and
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo is not null and
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo=flussoElabMifElabRec.flussoElabMifParam then
            	flussoElabMifElabRec.flussoElabMifElab:=false; -- se REGOLARIZZAZIONE data_esecuzione_pagamento non deve essere valorizzato
            end if;

            if flussoElabMifElabRec.flussoElabMifElab=true then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura data scadenza.';
        	 select sub.ord_ts_data_scadenza into ordDataScadenza
             from siac_t_ordinativo_ts sub
             where sub.ord_ts_id=mifOrdinativoIdRec.mif_ord_subord_id;

             if ordDataScadenza is not null and
--               date_trunc('DAY',ordDataScadenza)>= date_trunc('DAY',dataElaborazione) and
               date_trunc('DAY',ordDataScadenza)> date_trunc('DAY',dataElaborazione) and -- 13.12.2017 Sofia siac-5653
               extract('year' from ordDataScadenza)::integer<=annoBilancio::integer then
		  		mifFlussoOrdinativoRec.mif_ord_pagam_data_esec:=
    		        extract('year' from ordDataScadenza)||'-'||
    	         	lpad(extract('month' from ordDataScadenza)::varchar,2,'0')||'-'||
            	 	lpad(extract('day' from ordDataScadenza)::varchar,2,'0');
             end if;
            end if;

	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
      end if;

      -- <data_scadenza_pagamento>
  	  mifCountRec:=mifCountRec+1;

	  -- <destinazione>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      codResult:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
  	   RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	   if flussoElabMifElabRec.flussoElabMifElab=true then

        if flussoElabMifElabRec.flussoElabMifParam is not null or
           flussoElabMifElabRec.flussoElabMifDef is not null then --1

           if flussoElabMifElabRec.flussoElabMifParam is not null then --2
		    if classVincolatoCode is null then
	        	classVincolatoCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            end if;

            if classVincolatoCode is not null and classVincolatoCodeId is null then
            	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura identificativo classVincolatoCode='||classVincolatoCode||'.';

                select tipo.classif_tipo_id into classVincolatoCodeId
                from siac_d_class_tipo tipo
                where tipo.ente_proprietario_id=enteProprietarioId
                and   tipo.classif_tipo_code=classVincolatoCode;

            end if;

            if classVincolatoCodeId is not null then
            	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore per classVincolatoCode='||classVincolatoCode||'.';

                         select c.classif_desc into flussoElabMifValore
                         from siac_r_ordinativo_class r, siac_t_class c
                         where r.ord_id=  mifOrdinativoIdRec.mif_ord_ord_id
                         and   c.classif_id=r.classif_id
                         and   c.classif_tipo_id=classVincolatoCodeId
                         and   r.data_cancellazione is null
                         and   r.validita_fine is null
                         and   c.data_cancellazione is null;

            end if;
  	     end if; --2


         if flussoElabMifValore is null and --3
            mifOrdinativoIdRec.mif_ord_contotes_id is not null and
        	mifOrdinativoIdRec.mif_ord_contotes_id!=0 then

		    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
    		                   ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
        		               ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
            		           ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                		       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                    		   ||' mifCountRec='||mifCountRec
	                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per conto corrente tesoreria [mif_r_conto_tesoreria_vincolato].';

			select mif.vincolato into flussoElabMifValore
    	    from mif_r_conto_tesoreria_vincolato mif
	    	where mif.ente_proprietario_id=enteProprietarioId
    	    and   mif.contotes_id=mifOrdinativoIdRec.mif_ord_contotes_id
	        and   mif.validita_fine is null
		    and   mif.data_cancellazione is null;


        end if; --3
 	    if flussoElabMifValore is null and
           flussoElabMifElabRec.flussoElabMifDef is not null then
           flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
        end if;

	    if flussoElabMifValore is not null then
        	mifFlussoOrdinativoRec.mif_ord_progr_dest:=flussoElabMifValore;
        end if;

       end if; --1
      else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
      end if;
     end if;


     -- <numero_conto_banca_italia_ente_ricevente>
     flussoElabMifElabRec:=null;
     flussoElabMifValore:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     codResult:=null;
     if flussoElabMifElabRec.flussoElabMifId is null then
     	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;

     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifParam is not null then
            	-- non esposto se regolarizzazione (provvisori)
                if mifFlussoOrdinativoRec.mif_ord_pagam_tipo is not null and
-- 28.12.2017 Sofia SIAC-5665	   mifFlussoOrdinativoRec.mif_ord_pagam_tipo= trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2)) then
          		   ( mifFlussoOrdinativoRec.mif_ord_pagam_tipo=
                     trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))
                    or
                     mifFlussoOrdinativoRec.mif_ord_pagam_tipo=
                     trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3))
                    )  then -- 28.12.2017 Sofia SIAC-5665

                   flussoElabMifElabRec.flussoElabMifElab:=false;
                end if;

                if flussoElabMifElabRec.flussoElabMifElab=true then
	             if tipoMDPCbi is null then
                   	tipoMDPCbi:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
               	  end if;


                  if tipoMDPCbi is not null then
                  	if codAccreRec.accredito_gruppo_code=tipoMDPCbi then
                        	 mifFlussoOrdinativoRec.mif_ord_bci_conto:=MDPRec.contocorrente;
                    end if;
                  end if;
                 end if;


            end if;
       else
           RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
     end if;


     -- <tipo_contabilita_ente_ricevente>
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=null;
     flussoElabMifValore:=null;
     codResult:=null;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
             if flussoElabMifElabRec.flussoElabMifDef is not null then

                if flussoElabMifElabRec.flussoElabMifParam is not null then
                   if tipoClassFruttifero is null then
                    	tipoClassFruttifero:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                   end if;

                   if tipoClassFruttifero is not null and valFruttifero is null then
	                   valFruttifero:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                       valFruttiferoStr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                       valFruttiferoStrAltro:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
                   end if;

                   if tipoClassFruttifero is not null and
                      valFruttifero is not null and
                      valFruttiferoStr is not null and
                      valFruttiferoStrAltro is not null and
                      tipoClassFruttiferoId is null then

                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura classifTipoCodeId '||tipoClassFruttifero||'.';
                   	select tipo.classif_tipo_id into tipoClassFruttiferoId
                    from siac_d_class_tipo tipo
                    where tipo.ente_proprietario_id=enteProprietarioId
                    and   tipo.classif_tipo_code=tipoClassFruttifero
                    and   tipo.data_cancellazione is null
                    and   tipo.validita_fine is null;

                   end if;


                   if tipoClassFruttiferoId is not null and
                      valFruttifero is not null and
                      valFruttiferoStr is not null and
                      valFruttiferoStrAltro is not null and
                      valFruttiferoId is null then

                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura classidId '||tipoClassFruttifero||' [siac_r_ordinativo_class].';


                   	select c.classif_code into flussoElabMifValore
                    from siac_r_ordinativo_class r, siac_t_class c
                    where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
	                and   c.classif_id=r.classif_id
                    and   c.classif_tipo_id=tipoClassFruttiferoId
                    and   r.data_cancellazione is null
                    and   r.validita_fine is null
                    and   c.data_cancellazione is null
                    order by r.ord_classif_id limit 1;

                    if flussoElabMifValore is not null then
                    	if flussoElabMifValore=valFruttifero THEN
                        	flussoElabMifValore=valFruttiferoStr;
                        else
                          flussoElabMifValore=valFruttiferoStrAltro;
                        end if;
                    end if;

                  end if;

				end if; -- param

				if flussoElabMifValore is not null then
	                mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil:=flussoElabMifValore;
                end if;

               if mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil is null and
	              mifOrdinativoIdRec.mif_ord_contotes_id is not null and
    	          mifOrdinativoIdRec.mif_ord_contotes_id!=0 then

               	  flussoElabMifValore:=null;
	              strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per conto corrente tesoreria [mif_r_conto_tesoreria_fruttifero].';
	           	  select mif.fruttifero into flussoElabMifValore
	              from mif_r_conto_tesoreria_fruttifero mif
    	          where mif.ente_proprietario_id=enteProprietarioId
        	      and   mif.contotes_id=mifOrdinativoIdRec.mif_ord_contotes_id
            	  and   mif.validita_fine is null
	              and   mif.data_cancellazione is null;

    	          if flussoElabMifValore is not null then
        	       	mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil:=flussoElabMifValore;
            	  end if;

              end if;

              if mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil is null then
                   	mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
              end if;
           end if; -- default
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      -- <tipo_postalizzazione>
      flussoElabMifElabRec:=null;
      codResult:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifValore:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      raise notice 'tipo_postalizzazione mifCountRec=%',mifCountRec;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
    	if flussoElabMifElabRec.flussoElabMifElab=true then
         if flussoElabMifElabRec.flussoElabMifParam is not null and
            flussoElabMifElabRec.flussoElabMifDef is not null then
           if tipoPagamPostA is null then
           	tipoPagamPostA:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
           end if;

           if tipoPagamPostB is null then
           	tipoPagamPostB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
           end if;


           if tipoPagamPostA is not null or tipoPagamPostB is not null then
			  if tipoPagamRec is not null and tipoPagamRec.descTipoPagamento is not null then
              	if tipoPagamRec.descTipoPagamento in (tipoPagamPostA,tipoPagamPostB) then
	                mifFlussoOrdinativoRec.mif_ord_pagam_postalizza:=flussoElabMifElabRec.flussoElabMifDef;
                end if;
              end if;
           end if;

         end if;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
      end if;


      -- <classificazione>
	  -- <codice_cgu>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      flussoElabMifValoreDesc:=null;
      codiceCge:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      raise notice 'classificazione mifCountRec=%',mifCountRec;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then -- attivo
       if flussoElabMifElabRec.flussoElabMifElab=true then -- elab

        if flussoElabMifElabRec.flussoElabMifParam is not null then -- param

       	 if siopeCodeTipo is null and flussoElabMifElabRec.flussoElabMifParam is not null then
         	siopeCodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
         end if;

         if siopeDef is null and flussoElabMifElabRec.flussoElabMifParam is not null then
         	siopeDef:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
         end if;

         if coalesce(dataAvvioSiopeNew,NVL_STR)=NVL_STR and
            flussoElabMifElabRec.flussoElabMifParam is not null then
           	dataAvvioSiopeNew:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
         end if;

         if coalesce(dataAvvioSiopeNew,NVL_STR)!=NVL_STR and codiceFinVTbr is null then
       	 	codiceFinVTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
         end if;

         if coalesce(dataAvvioSiopeNew,NVL_STR)!=NVL_STR then
       	  if dataAvvioSiopeNew::timestamp<=date_trunc('DAY',mifOrdinativoIdRec.mif_ord_data_emissione::timestamp) -- data emissione ordinativo
             then
              bAvvioSiopeNew:=true;
           end if;
         end if;

         if bAvvioSiopeNew=true then -- avvioSiopeNew
           if codiceFinVTbr is not null and codiceFinVTipoTbrId is null then
		  	-- codiceFinVTipoTbrId
            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura ID codice tipo='||codiceFinVTbr||'.';
			select tipo.classif_tipo_id into strict codiceFinVTipoTbrId
			from siac_d_class_tipo tipo
			where tipo.ente_proprietario_id=enteProprietarioId
			and   tipo.classif_tipo_code=codiceFinVTbr
			and   tipo.data_cancellazione is null
			and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
		    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));
          end if;

          if codiceFinVTipoTbrId is not null then
          	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per codice tipo='||codiceFinVTbr||'.';

            select replace(substring(class.classif_code,2),'.','') , class.classif_desc
                   into flussoElabMifValore,flussoElabMifValoreDesc
		   	from siac_r_ordinativo_class r, siac_t_class class
			where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
		    and   class.classif_id=r.classif_id
		    and   class.classif_tipo_id=codiceFinVTipoTbrId
		    and   r.data_cancellazione is null
		    and   r.validita_fine is NULL
		    and   class.data_cancellazione is null;

          	if   flussoElabMifValore is null then
             strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per codice tipo='||codiceFinVTbr||'.';

             select replace(substring(class.classif_code,2),'.','') , class.classif_desc
                   into flussoElabMifValore,flussoElabMifValoreDesc
 		   	 from siac_r_liquidazione_class r, siac_t_class class
			 where r.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
		     and   class.classif_id=r.classif_id
		     and   class.classif_tipo_id=codiceFinVTipoTbrId
		     and   r.data_cancellazione is null
		     and   r.validita_fine is NULL
		     and   class.data_cancellazione is null;
            end if;

          end if;
         else -- avvioSiopeNew
           strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura ID codice tipo='||siopeCodeTipo||'.';

           if siopeCodeTipoId is null and siopeCodeTipo is not null then
           	select tipo.classif_tipo_id into siopeCodeTipoId
            from siac_d_class_tipo tipo
            where tipo.classif_tipo_code=siopeCodeTipo
            and   tipo.ente_proprietario_id=enteProprietarioId
            and   tipo.data_cancellazione is null
	 		and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
           end if;

           strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per codice tipo='||siopeCodeTipo||'.';

           if siopeCodeTipoId is not null then
           	select class.classif_code, class.classif_desc
                   into flussoElabMifValore,flussoElabMifValoreDesc
            from siac_r_ordinativo_class cord, siac_t_class class
            where cord.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
            and cord.data_cancellazione is null
            and cord.validita_fine is null
            and class.classif_id=cord.classif_id
            and class.classif_code!=siopeDef
            and class.data_cancellazione is null
            and class.classif_tipo_id=siopeCodeTipoId;

            if flussoElabMifValore is null then
             select class.classif_code, class.classif_desc
                    into flussoElabMifValore,flussoElabMifValoreDesc
             from siac_r_liquidazione_class cord, siac_t_class class
             where cord.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
             and cord.data_cancellazione is null
             and cord.validita_fine is null
             and class.classif_id=cord.classif_id
             and class.classif_code!=siopeDef
             and class.data_cancellazione is null
             and class.classif_tipo_id=siopeCodeTipoId;
            end if;


           end if;
         end if; -- avvioSiopeNew


         if flussoElabMifValore is not null then
         	mifFlussoOrdinativoRec.mif_ord_class_codice_cge:=flussoElabMifValore;
            codiceCge:=flussoElabMifValore;
         end if;
        end if; -- param
       else -- elab
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if; -- elab
      end if; -- attivo

	  -- <codice_cup>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      flussoElabMifValoreDesc:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
			if flussoElabMifElabRec.flussoElabMifParam is not null then
            	if coalesce(cupAttrCode,NVL_STR)=NVL_STR then
                	cupAttrCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;

                if coalesce(cupAttrCode,NVL_STR)!=NVL_STR and cupAttrId is null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura attr_id '||cupAttrCode||'.';
                	select attr.attr_id into cupAttrId
                    from siac_t_attr attr
                    where attr.ente_proprietario_id=enteProprietarioId
                    and   attr.attr_code=cupAttrCode
                    and   attr.data_cancellazione is null
                    and   attr.validita_fine is null;
                end if;

                if cupAttrId is not null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cupAttrCode||' [siac_r_ordinativo_attr].';

                	select a.testo into flussoElabMifValore
                    from siac_r_ordinativo_attr a
                    where a.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   a.attr_id=cupAttrId
                    and   a.data_cancellazione is null
                    and   a.validita_fine is null;

                    if coalesce(flussoElabMifValore,NVL_STR)!=NVL_STR then
                    	mifFlussoOrdinativoRec.mif_ord_class_codice_cup:=flussoElabMifValore;
                    end if;


                    if mifFlussoOrdinativoRec.mif_ord_class_codice_cup is null then
                    	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cupAttrCode||' [siac_r_liquidazione_attr].';

                    	select a.testo into flussoElabMifValore
                        from siac_r_liquidazione_attr  a
                        where a.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
                        and   a.attr_id=cupAttrId
                        and   a.data_cancellazione is null
	                    and   a.validita_fine is null;


                        if coalesce(flussoElabMifValore,NVL_STR)!=NVL_STR then
    	                	mifFlussoOrdinativoRec.mif_ord_class_codice_cup:=flussoElabMifValore;
	                    end if;
                    end if;
                end if;
            end if;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      -- <codice_cpv>
      mifCountRec:=mifCountRec+1;

      -- <importo>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      flussoElabMifValoreDesc:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

	  if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
 	      	mifFlussoOrdinativoRec.mif_ord_class_importo:=mifFlussoOrdinativoRec.mif_ord_importo;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      -- </classificazione>

      -- <classificazione_dati_siope_uscite>
	  -- <tipo_debito_siope_c>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      isOrdCommerciale:=false;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
        -- 21.12.2017 Sofia JIRA SIAC-5665
        if flussoElabMifElabRec.flussoElabMifParam is not null then
            flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            tipoDocsComm:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))||'|'||
                      trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3))||'|'||
                      trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));

            isOrdCommerciale:=fnc_mif_ordinativo_esiste_documenti_splus( mifOrdinativoIdRec.mif_ord_ord_id,
                                                                         tipoDocsComm,
                                                   	                     enteProprietarioId
                                                                        );


/*        	if mifOrdinativoIdRec.mif_ord_siope_tipo_debito_id is not null then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura tipo debito [siac_d_siope_tipo_debito].';
            	select tipo.siope_tipo_debito_desc_bnkit into flussoElabMifValore
                from siac_d_siope_tipo_debito tipo
                where tipo.siope_tipo_debito_id=mifOrdinativoIdRec.mif_ord_siope_tipo_debito_id;
            end if;

            if flussoElabMifValore is not null and
               upper(flussoElabMifValore)=flussoElabMifElabRec.flussoElabMifParam then
               mifFlussoOrdinativoRec.mif_ord_class_tipo_debito:=flussoElabMifElabRec.flussoElabMifParam;
               isOrdCommerciale:=true;
            end if;*/
            -- 21.12.2017 Sofia JIRA SIAC-5665
            if isOrdCommerciale=true then
            	mifFlussoOrdinativoRec.mif_ord_class_tipo_debito:=flussoElabMifValore;
            end if;

        end if;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

	  -- <tipo_debito_siope_nc>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      if isOrdCommerciale=false then
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
       end if;
       if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
         if flussoElabMifElabRec.flussoElabMifParam is not null then
        	/*if mifOrdinativoIdRec.mif_ord_siope_tipo_debito_id is not null then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura tipo debito [siac_d_siope_tipo_debito].';
            	select upper(tipo.siope_tipo_debito_desc_bnkit) into flussoElabMifValore
                from siac_d_siope_tipo_debito tipo
                where tipo.siope_tipo_debito_id=mifOrdinativoIdRec.mif_ord_siope_tipo_debito_id;
            end if;

            if flussoElabMifValore is not null and
               upper(flussoElabMifValore)=flussoElabMifElabRec.flussoElabMifParam then
               mifFlussoOrdinativoRec.mif_ord_class_tipo_debito_nc:=flussoElabMifElabRec.flussoElabMifParam;
            end if;*/
            -- 21.12.2017 Sofia JIRA SIAC-5665
            mifFlussoOrdinativoRec.mif_ord_class_tipo_debito_nc:=flussoElabMifElabRec.flussoElabMifParam;
         end if;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
       end if;
      end if;

      -- <codice_cig_siope>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      flussoElabMifValoreDesc:=null;
      mifCountRec:=mifCountRec+1;
      raise notice 'codice_cig_siope mifCountRec=%',mifCountRec;
      -- solo per COMMERCIALI
	  if isOrdCommerciale=true then
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
       end if;

       if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
			if flussoElabMifElabRec.flussoElabMifParam is not null then
            	if coalesce(cigAttrCode,NVL_STR)=NVL_STR then
                	cigAttrCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;

                if coalesce(cigAttrCode,NVL_STR)!=NVL_STR and cigAttrCodeId is null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura attr_id '||cigAttrCode||'.';
                	select attr.attr_id into cigAttrCodeId
                    from siac_t_attr attr
                    where attr.ente_proprietario_id=enteProprietarioId
                    and   attr.attr_code=cigAttrCode
                    and   attr.data_cancellazione is null
                    and   attr.validita_fine is null;
                end if;

                if cigAttrCodeId is not null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cupAttrCode||' [siac_r_ordinativo_attr].';

                	select a.testo into flussoElabMifValore
                    from siac_r_ordinativo_attr a
                    where a.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   a.attr_id=cigAttrCodeId
                    and   a.data_cancellazione is null
                    and   a.validita_fine is null;

                    if coalesce(flussoElabMifValore,NVL_STR)!=NVL_STR then
                    	mifFlussoOrdinativoRec.mif_ord_class_cig:=flussoElabMifValore;
                    end if;


                    if mifFlussoOrdinativoRec.mif_ord_class_cig is null then
                    	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cigAttrCode||' [siac_r_liquidazione_attr].';

                    	select a.testo into flussoElabMifValore
                        from siac_r_liquidazione_attr  a
                        where a.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
                        and   a.attr_id=cigAttrCodeId
                        and   a.data_cancellazione is null
	                    and   a.validita_fine is null;


                        if coalesce(flussoElabMifValore,NVL_STR)!=NVL_STR then
    	                	mifFlussoOrdinativoRec.mif_ord_class_cig:=flussoElabMifValore;
	                    end if;
                    end if;
                end if;
            end if;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
       end if;
      end if;

      -- <motivo_esclusione_cig_siope>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      -- solo per COMMERCIALI
      if isOrdCommerciale=true and
         mifFlussoOrdinativoRec.mif_ord_class_cig is null then
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
       end if;

	   if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
       	  if mifOrdinativoIdRec.mif_ord_siope_assenza_motivazione_id is not null then
          	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura motivazione [siac_d_siope_assenza_motivazione].';
            raise notice 'siope_assenza_motivazione_desc_bnkit';
		  	select upper(ass.siope_assenza_motivazione_desc_bnkit) into flussoElabMifValore
			from siac_d_siope_assenza_motivazione ass
			where ass.siope_assenza_motivazione_id=mifOrdinativoIdRec.mif_ord_siope_assenza_motivazione_id;
          end if;
		  if flussoElabMifValore is not null then
	    	  mifFlussoOrdinativoRec.mif_ord_class_motivo_nocig:=flussoElabMifValore;
              raise notice 'siope_assenza_motivazione_desc_bnkit=%',mifFlussoOrdinativoRec.mif_ord_class_motivo_nocig;

          end if;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
       end if;
      end if;

      raise notice 'motivo_esclusione_cig_siope mifCountRec=%',mifCountRec;

      -- <fatture_siope>
      -- </fatture_siope>
      mifCountRec:=mifCountRec+12;

      -- <dati_ARCONET_siope>


      -- <codice_missione_siope>
	  flussoElabMifElabRec:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
    	  mifFlussoOrdinativoRec.mif_ord_class_missione:=SUBSTRING(mifOrdinativoIdRec.mif_ord_programma_code from 1 for 2);
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      raise notice 'codice_missione_siope mifCountRec=%',mifCountRec;

      -- <codice_programma_siope>
	  flussoElabMifElabRec:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
    	  mifFlussoOrdinativoRec.mif_ord_class_programma:=mifOrdinativoIdRec.mif_ord_programma_code;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      -- <codice_economico_siope>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
                              raise notice 'codice_economico_siope mifCountRec=%',mifCountRec;

      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
        if flussoElabMifElabRec.flussoElabMifParam is not null then

          if codiceFinVTbr is null then
				codiceFinVTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
          end if;

		  if codiceFinVTbr is not null and codiceFinVTipoTbrId is null then
		  	-- codiceFinVTipoTbrId
            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura ID codice tipo='||codiceFinVTbr||'.';
			select tipo.classif_tipo_id into strict codiceFinVTipoTbrId
			from siac_d_class_tipo tipo
			where tipo.ente_proprietario_id=enteProprietarioId
			and   tipo.classif_tipo_code=codiceFinVTbr
			and   tipo.data_cancellazione is null
			and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
		    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));
          end if;

          if codiceFinVTipoTbrId is not null then
          	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per codice tipo='||codiceFinVTbr||'.';

            select class.classif_code  into flussoElabMifValore
		   	from siac_r_ordinativo_class r, siac_t_class class
			where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
		    and   class.classif_id=r.classif_id
		    and   class.classif_tipo_id=codiceFinVTipoTbrId
		    and   r.data_cancellazione is null
		    and   r.validita_fine is NULL
		    and   class.data_cancellazione is null;

          	if   flussoElabMifValore is null then
             strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per codice tipo='||codiceFinVTbr||'.';

             select class.classif_code  into flussoElabMifValore
 		   	 from siac_r_liquidazione_class r, siac_t_class class
			 where r.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
		     and   class.classif_id=r.classif_id
		     and   class.classif_tipo_id=codiceFinVTipoTbrId
		     and   r.data_cancellazione is null
		     and   r.validita_fine is NULL
		     and   class.data_cancellazione is null;
            end if;
          end if;
/*
       	  if collEventoCodeId is null then
        	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'Lettura tipo coll. evento '||flussoElabMifElabRec.flussoElabMifParam||'.';


            select coll.collegamento_tipo_id into collEventoCodeId
            from siac_d_collegamento_tipo coll
            where coll.ente_proprietario_id=enteProprietarioId
            and   coll.collegamento_tipo_code=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1))
            and   coll.data_cancellazione is null
		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',coll.validita_inizio)
		    and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(coll.validita_fine,dataElaborazione));

         end if;

	     if collEventoCodeId is not null then
		  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'Lettura conto economico patrimoniale.';
                             raise notice 'QUI QUI strMessaggio=%',strMessaggio;

          select conto.pdce_conto_code into flussoElabMifValore
          from siac_t_pdce_conto conto, siac_t_reg_movfin regMovFin, siac_r_evento_reg_movfin rEvento,
               siac_d_evento evento,
               siac_t_mov_ep reg, siac_r_reg_movfin_stato regstato, siac_d_reg_movfin_stato stato,
               siac_t_prima_nota pn, siac_r_prima_nota_stato rpnota, siac_d_prima_nota_stato pnstato,
               siac_t_mov_ep_det det
          where evento.ente_proprietario_id=enteProprietarioId
          and   evento.collegamento_tipo_id=collEventoCodeId -- OP
          and   rEvento.evento_id=evento.evento_id
          and   rEvento.campo_pk_id=mifOrdinativoIdRec.mif_ord_ord_id
          and   regMovFin.regmovfin_id=rEvento.regmovfin_id
--          and   regMovFin.ambito_id=ambitoFinId  -- AMBITO_FIN togliamo ambito
          and   regstato.regmovfin_id=regMovFin.regmovfin_id
          and   stato.regmovfin_stato_id=regstato.regmovfin_stato_id
          and   stato.regmovfin_stato_code!=REGMOVFIN_STATO_A
          and   reg.regmovfin_id=regMovFin.regmovfin_id
          and   pn.pnota_id=reg.regep_id
          and   rpnota.pnota_id=pn.pnota_id
          and   pnstato.pnota_stato_id=rpnota.pnota_stato_id
          and   pnstato.pnota_stato_code!=REGMOVFIN_STATO_A  -- forse sarebbe meglio prendere solo i D
          and   det.movep_id=reg.movep_id
          and   det.movep_det_segno=SEGNO_ECONOMICO -- Dare
		  and   conto.pdce_conto_id=det.pdce_conto_id
          and   regMovFin.data_cancellazione is null
          and   regMovFin.validita_fine is null
          and   rEvento.data_cancellazione is null
          and   rEvento.validita_fine is null
          and   evento.data_cancellazione is null
          and   evento.validita_fine is null
          and   reg.data_cancellazione is null
          and   reg.validita_fine is null
          and   regstato.data_cancellazione is null
          and   regstato.validita_fine is null
          and   pn.data_cancellazione is null
          and   pn.validita_fine is null
          and   rpnota.data_cancellazione is null
          and   rpnota.validita_fine is null
          and   conto.data_cancellazione is null
          and   conto.validita_fine is null
          order by pn.pnota_id desc
          limit 1;
         end if;
*/
       end if;


        if flussoElabMifValore is not null then
	        mifFlussoOrdinativoRec.mif_ord_class_economico:=flussoElabMifValore;
        end if;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

	  -- <importo_codice_economico_siope>
	  mifCountRec:=mifCountRec+1;
      if mifFlussoOrdinativoRec.mif_ord_class_economico is not null then
      	flussoElabMifElabRec:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
                                                    raise notice 'QUI QUI strMessaggio=%',strMessaggio;

	    if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         		mifFlussoOrdinativoRec.mif_ord_class_importo_economico:=mifFlussoOrdinativoRec.mif_ord_importo;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;
      end if;

      -- <codice_UE_siope>
      flussoElabMifElabRec:=null;
	  flussoElabMifValore:=null;
	  codResult:=null;
	  mifCountRec:=mifCountRec+1;
            raise notice 'codice_UE_siope mifCountRec=%',mifCountRec;

	  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	if flussoElabMifElabRec.flussoElabMifElab=true then
    	 if flussoElabMifElabRec.flussoElabMifParam is not null then
     		if codiceUECodeTipo is null then
				codiceUECodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
	        end if;

            if codiceUECodeTipo is not null and codiceUECodeTipoId is null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_d_class_tipo.';

        	 select tipo.classif_tipo_id into codiceUECodeTipoId
             from  siac_d_class_tipo tipo
             where tipo.ente_proprietario_id=enteProprietarioId
             and   tipo.classif_tipo_code=codiceUECodeTipo
             and   tipo.data_cancellazione is null
		     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
		 	 and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
            end if;

	        if codiceUECodeTipoId is not null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_ordinativo_class.';
                             raise notice 'QUI QUI codiceUECodeTipo=% strMessaggio=%',codiceUECodeTipo,strMessaggio;

        	 select class.classif_code into flussoElabMifValore
             from siac_r_ordinativo_class rclass, siac_t_class class
             where rclass.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
             and   rclass.data_cancellazione is null
             and   rclass.validita_fine is null
             and   class.classif_id=rclass.classif_id
             and   class.classif_tipo_id=codiceUECodeTipoId
             and   class.data_cancellazione is null
             order by rclass.ord_classif_id
             limit 1;

                             raise notice '222QUI QUI codiceUECodeTipo=% strMessaggio=%',codiceUECodeTipo,strMessaggio;

             if flussoElabMifValore is null then
        	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_liquidazione_class.';
        	  select class.classif_code into flussoElabMifValore
              from siac_r_liquidazione_class rclass, siac_t_class class
              where rclass.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
              and   rclass.data_cancellazione is null
              and   rclass.validita_fine is null
              and   class.classif_id=rclass.classif_id
              and   class.classif_tipo_id=codiceUECodeTipoId
              and   class.data_cancellazione is null
              order by rclass.liq_classif_id
              limit 1;
             end if;
	        end if;

      	    if flussoElabMifValore is not null then
                raise notice 'QUI QUI flussoElabMifValore=%',flussoElabMifValore;
            	mifFlussoOrdinativoRec.mif_ord_class_transaz_ue:=flussoElabMifValore;
            end if;

      	 end if;
        else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		end if;
	  end if;

      -- <codice_uscita_siope>
      flussoElabMifElabRec:=null;
	  flussoElabMifValore:=null;
	  codResult:=null;
	  mifCountRec:=mifCountRec+1;
                  raise notice 'codice_uscita_siope mifCountRec=%',mifCountRec;

	  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	if flussoElabMifElabRec.flussoElabMifElab=true then
    	 if flussoElabMifElabRec.flussoElabMifParam is not null then
     		if ricorrenteCodeTipo is null then
				ricorrenteCodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
	        end if;

            if ricorrenteCodeTipo is not null and ricorrenteCodeTipoId is null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_d_class_tipo.';

        	 select tipo.classif_tipo_id into ricorrenteCodeTipoId
             from  siac_d_class_tipo tipo
             where tipo.ente_proprietario_id=enteProprietarioId
             and   tipo.classif_tipo_code=ricorrenteCodeTipo
             and   tipo.data_cancellazione is null
		     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
		 	 and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
            end if;

	        if ricorrenteCodeTipoId is not null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_ordinativo_class.';
                                                    raise notice 'QUI QUI strMessaggio=%',strMessaggio;

        	 select upper(class.classif_desc) into flussoElabMifValore
             from siac_r_ordinativo_class rclass, siac_t_class class
             where rclass.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
             and   rclass.data_cancellazione is null
             and   rclass.validita_fine is null
             and   class.classif_id=rclass.classif_id
             and   class.classif_tipo_id=ricorrenteCodeTipoId
             and   class.data_cancellazione is null
             order by rclass.ord_classif_id
             limit 1;


             if flussoElabMifValore is null then
        	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_liquidazione_class.';
        	  select upper(class.classif_desc) into flussoElabMifValore
              from siac_r_liquidazione_class rclass, siac_t_class class
              where rclass.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
              and   rclass.data_cancellazione is null
              and   rclass.validita_fine is null
              and   class.classif_id=rclass.classif_id
              and   class.classif_tipo_id=ricorrenteCodeTipoId
              and   class.data_cancellazione is null
              order by rclass.liq_classif_id
              limit 1;
             end if;
	        end if;

      	    if flussoElabMifValore is not null then
            	mifFlussoOrdinativoRec.mif_ord_class_ricorrente_spesa:=flussoElabMifValore;
            end if;

      	 end if;
        else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		end if;
	  end if;


      -- <codice_cofog_siope>
      flussoElabMifElabRec:=null;
	  flussoElabMifValore:=null;
	  codResult:=null;
	  mifCountRec:=mifCountRec+1;
                        raise notice 'codice_cofog_siope mifCountRec=%',mifCountRec;

	  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	if flussoElabMifElabRec.flussoElabMifElab=true then
    	 if flussoElabMifElabRec.flussoElabMifParam is not null then
     		if codiceCofogCodeTipo is null then
				codiceCofogCodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
	        end if;

            if codiceCofogCodeTipo is not null and codiceCofogCodeTipoId is null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_d_class_tipo.';

        	 select tipo.classif_tipo_id into codiceCofogCodeTipoId
             from  siac_d_class_tipo tipo
             where tipo.ente_proprietario_id=enteProprietarioId
             and   tipo.classif_tipo_code=codiceCofogCodeTipo
             and   tipo.data_cancellazione is null
		     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
		 	 and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
            end if;

	        if codiceCofogCodeTipoId is not null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_ordinativo_class.';
                                                    raise notice 'QUI QUI strMessaggio=%',strMessaggio;

        	 select class.classif_code into flussoElabMifValore
             from siac_r_ordinativo_class rclass, siac_t_class class
             where rclass.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
             and   rclass.data_cancellazione is null
             and   rclass.validita_fine is null
             and   class.classif_id=rclass.classif_id
             and   class.classif_tipo_id=codiceCofogCodeTipoId
             and   class.data_cancellazione is null
             order by rclass.ord_classif_id
             limit 1;


             if flussoElabMifValore is null then
        	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_liquidazione_class.';
        	  select class.classif_code into flussoElabMifValore
              from siac_r_liquidazione_class rclass, siac_t_class class
              where rclass.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
              and   rclass.data_cancellazione is null
              and   rclass.validita_fine is null
              and   class.classif_id=rclass.classif_id
              and   class.classif_tipo_id=codiceCofogCodeTipoId
              and   class.data_cancellazione is null
              order by rclass.liq_classif_id
              limit 1;
             end if;
	        end if;

      	    if flussoElabMifValore is not null then
            	mifFlussoOrdinativoRec.mif_ord_class_cofog_codice:=flussoElabMifValore;
            end if;

      	 end if;
        else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		end if;
	  end if;

      -- <importo_cofog_siope>
  	  mifCountRec:=mifCountRec+1;
      if mifFlussoOrdinativoRec.mif_ord_class_cofog_codice is not null then
       flussoElabMifElabRec:=null;
	   flussoElabMifValore:=null;
	   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	   if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	   end if;
       if flussoElabMifElabRec.flussoElabMifAttivo=true then
	     if flussoElabMifElabRec.flussoElabMifElab=true then
        		mifFlussoOrdinativoRec.mif_ord_class_cofog_importo:=mifFlussoOrdinativoRec.mif_ord_importo;

         else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		 end if;
	    end if;
       end if;

      -- </dati_ARCONET_siope>

      -- </classificazione_dati_siope_uscite>

      -- <bollo>
      -- <assoggettamento_bollo>
   	  mifCountRec:=mifCountRec+1;
      ordCodiceBolloDesc:=null;
      codiceBolloPlusDesc:=null;
      codiceBolloPlusEsente:=false;
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      if mifOrdinativoIdRec.mif_ord_codbollo_id is not null then


	   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  	    end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	  if flussoElabMifElabRec.flussoElabMifElab=true then

          	if flussoElabMifElabRec.flussoElabMifParam is not null and
               flussoElabMifElabRec.flussoElabMifDef is not null and
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo is not null and
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo in
                 (trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1)), -- REGOLARIZZAZIONE
                  trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))  -- F24EP
                 ) then

               codiceBolloPlusEsente:=true;
               -- REGOLARIZZAZIONE
               if mifFlussoOrdinativoRec.mif_ord_pagam_tipo=
                  trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1)) then
                  mifFlussoOrdinativoRec.mif_ord_bollo_carico:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
               	  mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
               end if;
               -- F24EP
               if mifFlussoOrdinativoRec.mif_ord_pagam_tipo=
                  trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2)) then
                  mifFlussoOrdinativoRec.mif_ord_bollo_carico:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
               	  mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
               end if;
            end if;

            if mifFlussoOrdinativoRec.mif_ord_bollo_carico is null then
          	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura codice bollo.';

             select bollo.codbollo_desc , plus.codbollo_plus_desc, plus.codbollo_plus_esente
                   into ordCodiceBolloDesc, codiceBolloPlusDesc, codiceBolloPlusEsente
             from siac_d_codicebollo bollo, siac_d_codicebollo_plus plus, siac_r_codicebollo_plus rp
             where bollo.codbollo_id=mifOrdinativoIdRec.mif_ord_codbollo_id
             and   rp.codbollo_id=bollo.codbollo_id
             and   plus.codbollo_plus_id=rp.codbollo_plus_id
             and   rp.data_cancellazione is null
             and   rp.validita_fine is null;

             if coalesce(codiceBolloPlusDesc,NVL_STR)!=NVL_STR  then
            	mifFlussoOrdinativoRec.mif_ord_bollo_carico:=codiceBolloPlusDesc;
             end if;
            end if;
          else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		  end if;
        end if;
       end if;

      -- <causale_esenzione_bollo>
   	  mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      if codiceBolloPlusEsente=true and coalesce(ordCodiceBolloDesc,NVL_STR)!=NVL_STR then
      	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  	    end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	  if flussoElabMifElabRec.flussoElabMifElab=true then
            if mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione is null then
	          	mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione:=substring(ordCodiceBolloDesc from 1 for 30);
            end if;
          else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		  end if;
        end if;
      end if;
      -- </bollo>

	  -- <spese>
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      ordCodiceBolloDesc:=null;
      codiceBolloPlusDesc:=null;
      codiceBolloPlusEsente:=false;
      -- <soggetto_destinatario_delle_spese>
      if mifOrdinativoIdRec.mif_ord_comm_tipo_id is not null then
	   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  	    end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	  if flussoElabMifElabRec.flussoElabMifElab=true then
          	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura codice commissione.';

            select tipo.comm_tipo_desc , plus.comm_tipo_plus_desc, plus.comm_tipo_plus_esente
                   into ordCodiceBolloDesc, codiceBolloPlusDesc, codiceBolloPlusEsente
            from siac_d_commissione_tipo tipo, siac_d_commissione_tipo_plus plus, siac_r_commissione_tipo_plus rp
            where tipo.comm_tipo_id=mifOrdinativoIdRec.mif_ord_comm_tipo_id
            and   rp.comm_tipo_id=tipo.comm_tipo_id
            and   plus.comm_tipo_plus_id=rp.comm_tipo_plus_id
            and   rp.data_cancellazione is null
            and   rp.validita_fine is null;

            if coalesce(codiceBolloPlusDesc,NVL_STR)!=NVL_STR  then
            	mifFlussoOrdinativoRec.mif_ord_commissioni_carico:=codiceBolloPlusDesc;
            end if;
          else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		  end if;
        end if;
      end if;
      -- <natura_pagamento>
      mifCountRec:=mifCountRec+1;

      -- <causale_esenzione_spese>
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      if codiceBolloPlusEsente=true and mifFlussoOrdinativoRec.mif_ord_commissioni_carico is not null then
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  	   end if;
       if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	  if flussoElabMifElabRec.flussoElabMifElab=true then
          	mifFlussoOrdinativoRec.mif_ord_commissioni_esenzione:=ordCodiceBolloDesc;
          else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		  end if;
       end if;
      end if;
      -- </spese>

	  -- <beneficiario>
      mifCountRec:=mifCountRec+1;
      -- <anagrafica_beneficiario>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      anagraficaBenefCBI:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
--       raise notice 'beneficiario mifCountRec=%',mifCountRec;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if soggettoSedeSecId is not null then
            	flussoElabMifValore:=soggettoRec.soggetto_desc||' '||soggettoSedeRec.soggetto_desc;
            else
            	flussoElabMifValore:=soggettoRec.soggetto_desc;
            end if;

            /*if flussoElabMifElabRec.flussoElabMifParam is not null and tipoMDPCbi is null then
	           	tipoMDPCbi:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            end if; */

            -- se non e girofondo o se lo e ma il contocorrente_intestazione e vuoto
            -- valorizzo i tag di anagrafica_beneficiario
            -- altrimenti solo anagrafica_beneficiario=contocorrente_intestazione
            -- e anagrafica_beneficiario in dati_a_disposizione_ente
            /*if codAccreRec.accredito_gruppo_code!=tipoMDPCbi or
			   (codAccreRec.accredito_gruppo_code=tipoMDPCbi and
                 (MDPRec.contocorrente_intestazione is null or MDPRec.contocorrente_intestazione='')) then
	           	mifFlussoOrdinativoRec.mif_ord_anag_benef:=substring(flussoElabMifValore from 1 for 140);
            else
	            	anagraficaBenefCBI:=flussoElabMifValore;
	                mifFlussoOrdinativoRec.mif_ord_anag_benef:=substring(MDPRec.contocorrente_intestazione from 1 for 140);
            end if;*/

            mifFlussoOrdinativoRec.mif_ord_anag_benef:=substring(flussoElabMifValore from 1 for 140);

       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
     end if;



	 -- <indirizzo_beneficiario>
     flussoElabMifElabRec:=null;
     flussoElabMifValore:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' indirizzo_benef mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

     if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;

     if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
        	if soggettoSedeSecId is not null then
                select * into indirizzoRec
                from siac_t_indirizzo_soggetto indir
                where indir.soggetto_id=soggettoSedeSecId
                and   indir.data_cancellazione is null
                and   indir.validita_fine is null;

            else
            	select * into indirizzoRec
                from siac_t_indirizzo_soggetto indir
                where indir.soggetto_id=soggettoRifId
                and   indir.principale='S'
                and   indir.data_cancellazione is null
         	    and   indir.validita_fine is null;

            end if;

            if indirizzoRec is null then
            	-- RAISE EXCEPTION ' Errore in lettura indirizzo soggetto [siac_t_indirizzo_soggetto].';
                isIndirizzoBenef:=false;
            end if;

            if isIndirizzoBenef=true then

             if indirizzoRec.via_tipo_id is not null then
            	select tipo.via_tipo_code into flussoElabMifValore
                from siac_d_via_tipo tipo
                where tipo.via_tipo_id=indirizzoRec.via_tipo_id
                and   tipo.data_cancellazione is null
         	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		 		and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
                if flussoElabMifValore is not null then
                	flussoElabMifValore:=flussoElabMifValore||' ';
                end if;
             end if;

             flussoElabMifValore:=trim(both from coalesce(flussoElabMifValore,'')||coalesce(indirizzoRec.toponimo,'')
                                 ||' '||coalesce(indirizzoRec.numero_civico,''));

             if flussoElabMifValore is not null and anagraficaBenefCBI is null then
	            mifFlussoOrdinativoRec.mif_ord_indir_benef:=substring(flussoElabMifValore from 1 for 30);
             end if;
           end if;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

   	  -- <cap_beneficiario>
      mifCountRec:=mifCountRec+1;
      if isIndirizzoBenef=true then
        if indirizzoRec.zip_code is not null and anagraficaBenefCBI is null then
         flussoElabMifElabRec:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
	            mifFlussoOrdinativoRec.mif_ord_cap_benef:=lpad(indirizzoRec.zip_code,5,'0');
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
        end if;
	  end if;

      -- <localita_beneficiario>
      mifCountRec:=mifCountRec+1;
      if isIndirizzoBenef=true then

        if indirizzoRec.comune_id is not null and anagraficaBenefCBI is null then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;

	     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
          	select com.comune_desc into flussoElabMifValore
            from siac_t_comune com
            where com.comune_id=indirizzoRec.comune_id
            and   com.data_cancellazione is null
            and   com.validita_fine is null;

            if flussoElabMifValore is not null then
	            mifFlussoOrdinativoRec.mif_ord_localita_benef:=substring(flussoElabMifValore from 1 for 30);
            end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
        end if;
      end if;


	  -- <provincia_beneficiario>
      mifCountRec:=mifCountRec+1;
      if isIndirizzoBenef=true then

        if indirizzoRec.comune_id is not null and anagraficaBenefCBI is null then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
          	select prov.sigla_automobilistica into flussoElabMifValore
            from siac_r_comune_provincia provRel, siac_t_provincia prov
            where provRel.comune_id=indirizzoRec.comune_id
            and   provRel.data_cancellazione is null
            and   provRel.validita_fine is null
            and   prov.provincia_id=provRel.provincia_id
            and   prov.data_cancellazione is null
            and   prov.validita_fine is null
            order by provRel.data_creazione;

            if flussoElabMifValore is not null then
	            mifFlussoOrdinativoRec.mif_ord_prov_benef:=flussoElabMifValore;
            end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
        end if;
      end if;

      -- <stato_beneficiario>
      mifCountRec:=mifCountRec+1; -- popolare in seguito ricavato il codice_paese di piazzatura
      flussoElabMifElabRec:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
          if anagraficaBenefCBI is null and
             statoBeneficiario=false then
	            statoBeneficiario:=true;
           end if;
         else
           RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;

	  -- <partita_iva_beneficiario>
      mifCountRec:=mifCountRec+1;
      if ( anagraficaBenefCBI is null and
            (soggettoRec.partita_iva is not null or
            (soggettoRec.partita_iva is null and soggettoRec.codice_fiscale is not null and length(soggettoRec.codice_fiscale)=11))
          )   then
      	 flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
          	    if soggettoRec.partita_iva is not null then
		            mifFlussoOrdinativoRec.mif_ord_partiva_benef:=soggettoRec.partita_iva;
                else
                    if length(trim ( both ' ' from soggettoRec.codice_fiscale))=11 then
                        mifFlussoOrdinativoRec.mif_ord_partiva_benef:=trim ( both ' ' from soggettoRec.codice_fiscale);
                    end if;
                end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
      end if;

       -- <codice_fiscale_beneficiario>
      mifCountRec:=mifCountRec+1;
--      if mifFlussoOrdinativoRec.mif_ord_partiva_benef is null and anagraficaBenefCBI is null then
      	 flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
            -- se CASSA codice_fiscale obbligatorio
          	if flussoElabMifElabRec.flussoElabMifParam is not null then
		            if tipoMDPCo is null then
                    	tipoMDPCo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                	end if;

                    if tipoMDPCo is not null and
                       tipoMDPCo=codAccreRec.accredito_gruppo_code then
                       if soggettoRec.codice_fiscale is not null then
                    	flussoElabMifValore:=trim ( both ' ' from soggettoRec.codice_fiscale);
                       else
	                    if mifFlussoOrdinativoRec.mif_ord_partiva_benef is not null then
     	                   flussoElabMifValore:=mifFlussoOrdinativoRec.mif_ord_partiva_benef;
                        end if;
                       end if;
                    end if;
            end if;

            -- se non CASSA valorizzato se partita iva non presente e  codice_fiscale=16
            if flussoElabMifValore is null and
               mifFlussoOrdinativoRec.mif_ord_partiva_benef is null and
               soggettoRec.codice_fiscale is not null and
               length(soggettoRec.codice_fiscale)=16 then
               flussoElabMifValore:=trim ( both ' ' from soggettoRec.codice_fiscale);
            end if;

            if flussoElabMifValore is not null then
		             mifFlussoOrdinativoRec.mif_ord_codfisc_benef:=flussoElabMifValore;
            end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
--        end if;
      -- </beneficiario>


      -- <delegato>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      isMDPCo:=false;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
         	if flussoElabMifElabRec.flussoElabMifParam is not null then
                    if tipoMDPCo is null then
                    	tipoMDPCo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                	end if;

                    if tipoMDPCo is not null and
                       tipoMDPCo=codAccreRec.accredito_gruppo_code then
                    	isMDPCo:=true;
                    end if;

					if isMDPCo=true and -- non esporre se REGOLARIZZAZIONE ( provvisori di cassa )
                       mifFlussoOrdinativoRec.mif_ord_pagam_tipo is not null and
            		   ( mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))
                         or
                         mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3))
                       )  then -- 20.12.2017 Sofia Jira SIAC-5665
			             isMDPCo=false;
			        end if;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;

      -- <anagrafica_delegato>
      mifCountRec:=mifCountRec+1;
      if isMDPCo=true and MDPRec.quietanziante is not null then
        	flussoElabMifElabRec:=null;
      		flussoElabMifValore:=null;

     	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
		    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        	if flussoElabMifElabRec.flussoElabMifId is null then
	            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    	    end if;
            if flussoElabMifElabRec.flussoElabMifAttivo=true then
         		if flussoElabMifElabRec.flussoElabMifElab=true then
                   	mifFlussoOrdinativoRec.mif_ord_anag_quiet:=MDPRec.quietanziante;
           		else
           			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
		         end if;
	        end if;
      end if;

      mifCountRec:=mifCountRec+7;
--      raise notice 'codfisc_quiet mifCountRec=%',mifCountRec;
      -- <codice_fiscale_delegato>
      if isMDPCo=true and mifFlussoOrdinativoRec.mif_ord_anag_quiet is not null and
         MDPRec.quietanziante_codice_fiscale is not null  and
         length(MDPRec.quietanziante_codice_fiscale)=16   then
             flussoElabMifElabRec:=null;
      		 flussoElabMifValore:=null;
             flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 72
		     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        	 if flussoElabMifElabRec.flussoElabMifId is null then
	            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    	     end if;
             if flussoElabMifElabRec.flussoElabMifAttivo=true then
         		if flussoElabMifElabRec.flussoElabMifElab=true then
                   	flussoElabMifValore:=trim ( both ' ' from MDPRec.quietanziante_codice_fiscale);

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_codfisc_quiet:=flussoElabMifValore;
                    end if;

           		else
           			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
		        end if;
	         end if;
      end if;
      -- </delegato>

	  -- <creditore_effettivo>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      soggettoQuietRec:=null;
      soggettoQuietRifRec:=null;
      soggettoQuietId:=null;
      soggettoQuietRifId:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then

          if flussoElabMifElabRec.flussoElabMifParam is not null and
             mifFlussoOrdinativoRec.mif_ord_pagam_tipo is not null and
             ( mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3))
               or
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4))
             )   then -- 20.12.2017 Sofia JIRA siac-5665
             flussoElabMifElabRec.flussoElabMifElab=false;
          end if;

          if flussoElabMifElabRec.flussoElabMifElab=true then -- non esporre su regolarizzazione (provvisori)
           if  ordCsiRelazTipoId is null then
            if ordCsiRelazTipo is null then
            	if flussoElabMifElabRec.flussoElabMifParam is not null then
	                ordCsiRelazTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    ordCsiCOTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                end if;
            end if;

            if ordCsiRelazTipo is  not null then
                select tipo.oil_relaz_tipo_id into ordCsiRelazTipoId
               	from siac_d_oil_relaz_tipo tipo
	            where tipo.ente_proprietario_id=enteProprietarioId
    	          and tipo.oil_relaz_tipo_code=ordCsiRelazTipo
        	      and tipo.data_cancellazione is null
                  and tipo.validita_fine is null;
            end if;
           end if;

           if ordCsiRelazTipoId is not null and
              ( ordCsiCOTipo is null or ordCsiCOTipo!=codAccreRec.accredito_gruppo_code ) then

                soggettoQuietId:=MDPRec.soggetto_id;

                select sogg.*
                       into  soggettoQuietRec
                from siac_t_soggetto sogg, siac_r_soggrel_modpag relmdp,siac_r_soggetto_relaz relsogg,
                     siac_r_oil_relaz_tipo roil
                where sogg.soggetto_id=MDPRec.soggetto_id
                and   sogg.data_cancellazione is null
                and   sogg.validita_fine is null
                and   relmdp.modpag_id=MDPRec.modpag_id
                and   relmdp.data_cancellazione is null
                and   relmdp.validita_fine is null
    			and   relmdp.soggetto_relaz_id=relsogg.soggetto_relaz_id
                and   relsogg.soggetto_id_a=MDPRec.soggetto_id
                and   relsogg.soggetto_id_da=soggettoRifId
                and   roil.relaz_tipo_id=relsogg.relaz_tipo_id
                and   roil.oil_relaz_tipo_id=ordCsiRelazTipoId
                and   relsogg.data_cancellazione is null
                and   relsogg.validita_fine is null
                and   roil.data_cancellazione is null
                and   roil.validita_fine is null;

				if soggettoQuietRec is null then
                	soggettoQuietId:=null;
                end if;

               if soggettoQuietId is not null then
                 select sogg.*
                        into soggettoQuietRifRec
		         from  siac_t_soggetto sogg, siac_r_soggetto_relaz rel
		         where rel.soggetto_id_a=soggettoQuietRec.soggetto_id
		         and   rel.relaz_tipo_id=ordSedeSecRelazTipoId
		         and   rel.ente_proprietario_id=enteProprietarioId
		         and   rel.data_cancellazione is null
                 and   rel.validita_fine is null
                 and   sogg.soggetto_id=rel.soggetto_id_da
		         and   sogg.data_cancellazione is null
                 and   sogg.validita_fine is null;


                 if soggettoQuietRifRec is null then

                 else
                 	soggettoQuietRifId:=soggettoQuietRifRec.soggetto_id;
                 end if;
               end if;
            end if;
          end if;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      mifCountRec:=mifCountRec+1;
  	  -- <anagrafica_creditore_effettivo>
      if soggettoQuietId is not null then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;

	     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --63
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then
	            if soggettoQuietRifId is not null then
    	        	flussoElabMifValore:=soggettoQuietRifRec.soggetto_desc||' '||soggettoQuietRec.soggetto_desc;
        	    else
            		flussoElabMifValore:=soggettoQuietRec.soggetto_desc;
	            end if;

                if flussoElabMifValore is not null then
--                	mifFlussoOrdinativoRec.mif_ord_anag_del:=substring(flussoElabMifValore from 1 for 140);

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in creditore_effettivo -- anagrafica_beneficiario
                    mifFlussoOrdinativoRec.mif_ord_anag_del:=mifFlussoOrdinativoRec.mif_ord_anag_benef;
                    mifFlussoOrdinativoRec.mif_ord_indir_del:=mifFlussoOrdinativoRec.mif_ord_indir_benef;
                    mifFlussoOrdinativoRec.mif_ord_cap_del:=mifFlussoOrdinativoRec.mif_ord_cap_benef;
                    mifFlussoOrdinativoRec.mif_ord_localita_del:=mifFlussoOrdinativoRec.mif_ord_localita_benef;
                    mifFlussoOrdinativoRec.mif_ord_prov_del:=mifFlussoOrdinativoRec.mif_ord_prov_benef;
                    mifFlussoOrdinativoRec.mif_ord_partiva_del:=mifFlussoOrdinativoRec.mif_ord_partiva_benef;
                    mifFlussoOrdinativoRec.mif_ord_codfisc_del:=mifFlussoOrdinativoRec.mif_ord_codfisc_benef;

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
                    mifFlussoOrdinativoRec.mif_ord_anag_benef:=substring(flussoElabMifValore from 1 for 140);

                end if;
         	else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
	  end if;

      mifCountRec:=mifCountRec+1;
      -- <indirizzo_creditore_effettivo>
      if soggettoQuietId is not null then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         indirizzoRec:=null;
		 flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then

                select * into indirizzoRec
                from siac_t_indirizzo_soggetto indir
                where indir.soggetto_id=soggettoQuietId
                and   (case when soggettoQuietRifId is null
                            then indir.principale='S' else coalesce(indir.principale,'N')='N' end)
                and   indir.data_cancellazione is null
                and   indir.validita_fine is null;

                if indirizzoRec is null then
                    isIndirizzoBenQuiet:=false;
            	end if;

			    if isIndirizzoBenQuiet=true then

            	 if indirizzoRec.via_tipo_id is not null then
            		select tipo.via_tipo_code into flussoElabMifValore
                	from siac_d_via_tipo tipo
               		where tipo.via_tipo_id=indirizzoRec.via_tipo_id
	                and   tipo.data_cancellazione is null
    	     	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 			 		and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

                	if flussoElabMifValore is not null then
                		flussoElabMifValore:=flussoElabMifValore||' ';
               	    end if;

           		  end if;

	             flussoElabMifValore:=trim(both from coalesce(flussoElabMifValore,'')||coalesce(indirizzoRec.toponimo,'')
    	                             ||' '||coalesce(indirizzoRec.numero_civico,''));

        	     if flussoElabMifValore is not null then
--	        	    mifFlussoOrdinativoRec.mif_ord_indir_del:=substring(flussoElabMifValore from 1 for 30);

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
                    mifFlussoOrdinativoRec.mif_ord_indir_benef:=substring(flussoElabMifValore from 1 for 30);
	             end if;
                end if;
         	else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
     end if;

	 -- <cap_creditore_effettivo>
     mifCountRec:=mifCountRec+1;
     if isIndirizzoBenQuiet=true then
        if soggettoQuietId is not null and indirizzoRec is not null then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then
--         		mifFlussoOrdinativoRec.mif_ord_cap_del:=lpad(indirizzoRec.zip_code,5,'0');

				-- 24.01.2018 Sofia jira siac-5765 - scambio tag
                -- in anagrafica_beneficiario -- creditore_effettivo
                mifFlussoOrdinativoRec.mif_ord_cap_benef:=lpad(indirizzoRec.zip_code,5,'0');
            else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;

         end if;
        end if;
     end if;


     -- <localita_creditore_effettivo>
     mifCountRec:=mifCountRec+1;
     if isIndirizzoBenQuiet=true then
        if soggettoQuietId is not null and indirizzoRec.comune_id is not null then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
		 flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then

            	select com.comune_desc into flussoElabMifValore
           		from siac_t_comune com
	            where com.comune_id=indirizzoRec.comune_id
    	        and   com.data_cancellazione is null
                and   com.validita_fine is null;

	            if flussoElabMifValore is not null then
--		            mifFlussoOrdinativoRec.mif_ord_localita_del:=substring(flussoElabMifValore from 1 for 30);

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
                    mifFlussoOrdinativoRec.mif_ord_localita_benef:=substring(flussoElabMifValore from 1 for 30);
        	    end if;
            else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
        end if;
     end if;

     mifCountRec:=mifCountRec+1;
	 -- <provincia_creditore_effettivo>
	 if isIndirizzoBenQuiet=true then
        if soggettoQuietId is not null and indirizzoRec.comune_id is not null then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then

            	select prov.sigla_automobilistica into flussoElabMifValore
            	from siac_r_comune_provincia provRel, siac_t_provincia prov
           		where provRel.comune_id=indirizzoRec.comune_id
           	  	and   provRel.data_cancellazione is null
                and   provRel.validita_fine is null
        	    and   prov.provincia_id=provRel.provincia_id
            	and   prov.data_cancellazione is null
                and   prov.validita_fine is null
        	    order by provRel.data_creazione;

	            if flussoElabMifValore is not null then
--		            mifFlussoOrdinativoRec.mif_ord_prov_del:=flussoElabMifValore;
                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
                    mifFlussoOrdinativoRec.mif_ord_prov_benef:=flussoElabMifValore;
        	    end if;
            else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
        end if;
     end if;

     mifCountRec:=mifCountRec+1;
	 -- <stato_creditore_effettivo>
     if soggettoQuietId is not null  then
        flussoElabMifElabRec:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
       end if;
       if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
         	if statoDelegatoCredEff=false then
	            statoDelegatoCredEff:=true;
                -- valorizzato poi in piazzatura
            end if;
          else
           RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
       end if;
     end if;

     mifCountRec:=mifCountRec+1;
	 -- <partita_iva_creditore_effettivo>
     if soggettoQuietId is not null THEN
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then
                if  soggettoQuietRifId is not null then
	            	if soggettoQuietRifRec.partita_iva is not null  or
                       (soggettoQuietRifRec.partita_iva is null and
                        soggettoQuietRifRec.codice_fiscale is not null and length(soggettoQuietRifRec.codice_fiscale)=11)
                       then
                       	if soggettoQuietRifRec.partita_iva is not null then
	    	             flussoElabMifValore:=soggettoQuietRifRec.partita_iva;
                        else
                         flussoElabMifValore:=trim ( both ' ' from soggettoQuietRifRec.codice_fiscale);
                        end if;
                     end if;
				else
                	if soggettoQuietRec.partita_iva is not null  or
                       (soggettoQuietRec.partita_iva is null and
                        soggettoQuietRec.codice_fiscale is not null and length(soggettoQuietRec.codice_fiscale)=11)
                       then
                       	if soggettoQuietRec.partita_iva is not null then
	    	             flussoElabMifValore:=soggettoQuietRec.partita_iva;
                        else
                         flussoElabMifValore:=trim ( both ' ' from soggettoQuietRec.codice_fiscale);
                        end if;
                    end if;
                end if;

			    if flussoElabMifValore is not null then
--	                mifFlussoOrdinativoRec.mif_ord_partiva_del:=flussoElabMifValore;

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
                    mifFlussoOrdinativoRec.mif_ord_partiva_benef:=flussoElabMifValore;

                end if;
         	else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
     end if;

     mifCountRec:=mifCountRec+1;
     -- <codice_fiscale_creditore_effettivo>
     if soggettoQuietId is not null  then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then
            	if soggettoQuietRifId is not null then
                 if mifFlussoOrdinativoRec.mif_ord_partiva_del is null then
                  if soggettoQuietRifRec.codice_fiscale is not null and
                     length(soggettoQuietRifRec.codice_fiscale)= 16 then
	                 flussoElabMifValore:=trim ( both ' ' from soggettoQuietRifRec.codice_fiscale);
                  end if;
                 end if;
                else
                 if soggettoQuietRec.codice_fiscale is not null and
                    length(soggettoQuietRec.codice_fiscale)=16 then
	                 flussoElabMifValore:=trim ( both ' ' from soggettoQuietRec.codice_fiscale);
                 end if;
                end if;

				if flussoElabMifValore is not null then
--	                mifFlussoOrdinativoRec.mif_ord_codfisc_del:=flussoElabMifValore;

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
  		            mifFlussoOrdinativoRec.mif_ord_codfisc_benef:=flussoElabMifValore;

                end if;
         	else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
        end if;
     end if;

     -- </creditore_effettivo>
/**/
	 -- <piazzatura>
     flussoElabMifElabRec:=null;
     isOrdPiazzatura:=false;
     accreditoGruppoCode:=null;
     isPaeseSepa:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
--     raise notice 'piazzatura mifCountRec=%',mifCountRec;
     if flussoElabMifElabRec.flussoElabMifId is null then
      	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
       	 if flussoElabMifElabRec.flussoElabMifParam is not null then
            isOrdPiazzatura:=fnc_mif_ordinativo_piazzatura_splus(MDPRec.accredito_tipo_id,
                                                           		 mifOrdinativoIdRec.mif_ord_codice_funzione,
		  												         flussoElabMifElabRec.flussoElabMifParam,
                                                                 mifFlussoOrdinativoRec.mif_ord_pagam_tipo,
			                                                     dataElaborazione,dataFineVal,enteProprietarioId);
         end if;
      	else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
     end if;

     if isOrdPiazzatura=true then

      	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura tipo accredito MDP per popolamento  campi relativi a'||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

--        raise notice 'Ordinativo con piazzatura % codice funzione=%',mifOrdinativoIdRec.mif_ord_ord_id,mifOrdinativoIdRec.mif_ord_codice_funzione;

		accreditoGruppoCode:=codAccreRec.accredito_gruppo_code;

        if MDPRec.iban is not null and length(MDPRec.iban)>2  then
        	select distinct 1 into isPaeseSepa
            from siac_t_sepa sepa
            where sepa.sepa_iso_code=substring(upper(MDPRec.iban) from 1 for 2)
            and   sepa.ente_proprietario_id=enteProprietarioId
            and   sepa.data_cancellazione is null
      	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',sepa.validita_inizio)
 			and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(sepa.validita_fine,dataElaborazione));
        end if;
     end if;


     -- <abi_beneficiario>
 	 mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;

	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
					if tipoMDPCCP is null then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;


                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 6 for 5);
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
                    if flussoElabMifValore is null and
                       flussoElabMifElabRec.flussoElabMifDef is not null and
                       tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode then
                       flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;


                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_abi_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;
	 end if;

     -- <cab_beneficiario>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
         flussoElabMifElabRec:=null;
     	 flussoElabMifValore:=null;
 	     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;
         if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
					if tipoMDPCCP is null then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;

                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 11 for 5);
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
                    if flussoElabMifValore is null and
                       flussoElabMifElabRec.flussoElabMifDef is not null and
                       tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode then
                       flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_cab_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;
     end if;

     -- <numero_conto_corrente_beneficiario>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;
                    if tipoMDPCCP is null then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;

                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 16 for 12);
                    end if;

                    if tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode and
                       coalesce(MDPRec.contocorrente,NVL_STR)!=NVL_STR then
                       flussoElabMifValore:=lpad(MDPRec.contocorrente,NUM_DODICI,ZERO_PAD);
                    end if;

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_cc_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;
     end if;

     -- <caratteri_controllo>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
	    flussoElabMifElabRec:=null;
    	flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;

					-- 15.01.2018 Sofia JIRA SIAC-5765
					if tipoMDPCCP is null then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;

                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 3 for 2);
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
                    if flussoElabMifValore is null and
                       flussoElabMifElabRec.flussoElabMifDef is not null and
                       tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode then
                       flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_ctrl_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	end if;
     end if;


     -- <codice_cin>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;


					-- 15.01.2018 Sofia JIRA SIAC-5765
					if tipoMDPCCP is null then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;


                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 5 for 1);
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
                    if flussoElabMifValore is null and
                       flussoElabMifElabRec.flussoElabMifDef is not null and
                       tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode then
                       flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_cin_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;
     end if;

     -- <codice_paese>
	 mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;

					-- 15.01.2018 Sofia JIRA SIAC-5765
					if tipoMDPCCP is null then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;


                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 1 for 2);
                    end if;


					-- 15.01.2018 Sofia JIRA SIAC-5765
                    if flussoElabMifValore is null and
                       flussoElabMifElabRec.flussoElabMifDef is not null and
                       tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode then
                       flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_cod_paese_benef:=flussoElabMifValore;
--                        raise notice 'statoBenficiario=%',statoBeneficiario;
                        if statoBeneficiario=true and statoDelegatoCredEff=false then -- se CSI IBAN non riporta dati del beneficiario quindi omettiamo codice_paese
                        	mifFlussoOrdinativoRec.mif_ord_stato_benef:=flussoElabMifValore;
                        end if;
                        if statoDelegatoCredEff=true then
--	                        mifFlussoOrdinativoRec.mif_ord_stato_del:=flussoElabMifValore;
                            -- 24.01.2018 Sofia jira siac-5765
                            mifFlussoOrdinativoRec.mif_ord_stato_del:=mifFlussoOrdinativoRec.mif_ord_stato_benef;
                            mifFlussoOrdinativoRec.mif_ord_stato_benef:=flussoElabMifValore;
                        end if;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
       end if;
     end if;


     -- extra sepa
     -- <denominazione_banca_destinataria>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true and isPaeseSepa is null then
		 flussoElabMifElabRec:=null;
     	 flussoElabMifValore:=null;
		 flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	 end if;
         if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;


                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.banca_denominazione is not null  then
                       	flussoElabMifValore:=MDPRec.banca_denominazione;
                    end if;
                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_denom_banca_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;
     end if;
     -- </piazzatura>

     -- sezione esteri sepa
     -- <sepa_credit_transfer>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true
        and isPaeseSepa is not null then
     	flussoElabMifElabRec:=null;
   	    flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	 end if;
         if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
		     if flussoElabMifElabRec.flussoElabMifParam is not null then
                if paeseSepaTr is null then
	        	   	paeseSepaTr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if accreditoGruppoSepaTr is null then
	            	accreditoGruppoSepaTr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                end if;
                if SepaTr is null then
		            SepaTr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                end if;

    	        if accreditoGruppoSepaTr is not null and SepaTr is not null and paeseSepaTr is not null then
	    	        sepaCreditTransfer:=true;
            	end if;
             end if;
            else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
     end if;

     -- <iban>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true
        and sepaCreditTransfer=true
        and isPaeseSepa is not null
        and accreditoGruppoSepaTr=accreditoGruppoCode then
     	flussoElabMifElabRec:=null;
   	    flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	 end if;
         if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
		     	if MDPRec.iban is not null and length(MDPRec.iban)>=2 and
        		   substring(upper(MDPRec.iban) from 1 for 2)!=paeseSepaTr then
		           	mifFlussoOrdinativoRec.mif_ord_sepa_iban_tr:=MDPRec.iban;
        		end if;
            else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
     end if;

     -- <bic>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true
        and sepaCreditTransfer=true
        and isPaeseSepa is not null
        and accreditoGruppoSepaTr=accreditoGruppoCode then
     	flussoElabMifElabRec:=null;
   	    flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	 end if;
         if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
		     	if MDPRec.bic is not null and
                   MDPRec.iban is not null and length(MDPRec.iban)>=2 and
        		   substring(upper(MDPRec.iban) from 1 for 2)!=paeseSepaTr then
		           mifFlussoOrdinativoRec.mif_ord_sepa_bic_tr:=MDPRec.bic;
        		end if;
            else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
     end if;
     mifCountRec:=mifCountRec+5;
     -- </sepa_credit_transfer>


     -- <causale> ancora informazioni_beneficiario
     flussoElabMifElabRec:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifValore:=null;
     flussoElabMifValoreDesc:=null;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
--     raise notice 'causale mifCountRec=%',mifCountRec;
     if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifParam is not null then
            	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura CUP-CIG.';
            	if cupCausAttr is null then
	            	cupCausAttr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if cigCausAttr is null then
	                cigCausAttr:=trim (both ' '	 from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                end if;

                if coalesce(cupCausAttr,NVL_STR)!=NVL_STR  and cupCausAttrId is null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura attr_id '||cupCausAttr||'.';
                	select attr.attr_id into cupCausAttrId
                    from siac_t_attr attr
                    where attr.ente_proprietario_id=enteProprietarioId
                    and   attr.attr_code=cupCausAttr
                    and   attr.data_cancellazione is null
                    and   attr.validita_fine is null;

                end if;

                if coalesce(cigCausAttr,NVL_STR)!=NVL_STR and cigCausAttrId is null then

                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura attr_id '||cigCausAttr||'.';
                	select attr.attr_id into cigCausAttrId
                    from siac_t_attr attr
                    where attr.ente_proprietario_id=enteProprietarioId
                    and   attr.attr_code=cigCausAttr
                    and   attr.data_cancellazione is null
                    and   attr.validita_fine is null;

                end if;


                if cupCausAttrId is not null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cupCausAttr||' [siac_r_ordinativo_attr].';

                	select a.testo into flussoElabMifValore
                    from siac_r_ordinativo_attr a
                    where a.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   a.attr_id=cupCausAttrId
                    and   a.data_cancellazione is null
                    and   a.validita_fine is null;

                    if coalesce(flussoElabMifValore,NVL_STR)=NVL_STR then
                       	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cupCausAttr||' [siac_r_liquidazione_attr].';

                    	select a.testo into flussoElabMifValore
                        from siac_r_liquidazione_attr  a
                        where a.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
                        and   a.attr_id=cupCausAttrId
                        and   a.data_cancellazione is null
	                    and   a.validita_fine is null;
                    end if;
                end if;

                if cigCausAttrId is not null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cigCausAttr||' [siac_r_ordinativo_attr].';

                	select a.testo into flussoElabMifValoreDesc
                    from siac_r_ordinativo_attr a
                    where a.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   a.attr_id=cigCausAttrId
                    and   a.data_cancellazione is null
                    and   a.validita_fine is null;

                    if coalesce(flussoElabMifValoreDesc,NVL_STR)=NVL_STR then
                       	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cigCausAttr||' [siac_r_liquidazione_attr].';

                    	select a.testo into flussoElabMifValoreDesc
                        from siac_r_liquidazione_attr  a
                        where a.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
                        and   a.attr_id=cigCausAttrId
                        and   a.data_cancellazione is null
	                    and   a.validita_fine is null;
                    end if;
                end if;

            end if;
            -- cup
			if coalesce(flussoElabMifValore,NVL_STR)!=NVL_STR then
			       	mifFlussoOrdinativoRec.mif_ord_pagam_causale:=cupCausAttr||' '||flussoElabMifValore;

            end if;
            -- cig
			if coalesce(flussoElabMifValoreDesc,NVL_STR)!=NVL_STR  then
                	mifFlussoOrdinativoRec.mif_ord_pagam_causale:=
                      trim (both ' ' from coalesce(mifFlussoOrdinativoRec.mif_ord_pagam_causale,' ')||
                           ' '||cigCausAttr||' '||flussoElabMifValoreDesc);
            end if;


			mifFlussoOrdinativoRec.mif_ord_pagam_causale:=
      			replace(replace(substring(trim (both ' ' from coalesce(mifFlussoOrdinativoRec.mif_ord_pagam_causale,' ')||' '||mifOrdinativoIdRec.mif_ord_desc )
	                            from 1 for 370) , chr(VT_ASCII),chr(SPACE_ASCII)),chr(BS_ASCII),NVL_STR);

--			raise notice 'mifFlussoOrdinativoRec.mif_ord_pagam_causale %',mifFlussoOrdinativoRec.mif_ord_pagam_causale;


	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
     end if;

     -- <sospeso>
     -- <numero_provvisorio>
     -- <importo_provvisorio>
     mifCountRec:=mifCountRec+2;

	 -- <ritenuta>
     -- <importo_ritenute>
     -- <numero_reversale>
     -- <progressivo_versante>
     mifCountRec:=mifCountRec+3;

	 -- <informazioni_aggiuntive>

     -- <lingua>
    flussoElabMifElabRec:=null;
    mifCountRec:=mifCountRec+1;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifDef is not null then
        		mifFlussoOrdinativoRec.mif_ord_lingua:=flussoElabMifElabRec.flussoElabMifDef;

--                raise notice 'LINGUA def % %',flussoElabMifElabRec.flusso_elab_mif_campo,flussoElabMifElabRec.flussoElabMifDef;
            end if;
	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
     end if;


    -- <riferimento_documento_esterno>
    mifCountRec:=mifCountRec+1;
    if tipoPagamRec is not null then
    	flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
  		 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;
    	if flussoElabMifElabRec.flussoElabMifAttivo=true then
    		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifDef is not null and
                   flussoElabMifElabRec.flussoElabMifParam is not null then

                    -- modalita accredito=STI - STIPENDI
                    if codAccreRec.accredito_tipo_code =
                           trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3)) then
                           flussoElabMifValore:=
                             trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
                    end if;

                    if  coalesce(flussoElabMifValore,'')='' and
                        tipoPagamRec.descTipoPagamento in
                        (trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1)),
                         trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))
                        ) then
		                flussoElabMifValore:=tipoPagamRec.descTipoPagamento;
                    end if;

                    -- 23.01.2018 Sofia jira siac-5765
			        if codAccreRec.accredito_gruppo_code =
                           trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4)) and
                           MDPRec.contocorrente is not null and MDPRec.contocorrente!=''
                            then
                           flussoElabMifValore:=MDPRec.contocorrente;
                    end if;
                    -- 23.01.2018 Sofia jira siac-5765

                    if coalesce(flussoElabMifValore,'')='' and tipoPagamRec.defRifDocEsterno=true then
                        flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
                    end if;

                    if coalesce(flussoElabMifValore,'')!='' then
	                    mifFlussoOrdinativoRec.mif_ord_rif_doc_esterno:=flussoElabMifValore;
                    end if;
		        end if;
			else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
		    end if;
    	end if;
    end if;
    -- </informazioni_aggiuntive>

    -- <sostituzione_mandato>

    flussoElabMifElabRec:=null;
    ordSostRec:=null;
    mifCountRec:=mifCountRec+1;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
                	select * into ordSostRec
                    from fnc_mif_ordinativo_sostituito( mifOrdinativoIdRec.mif_ord_ord_id,
 														ordRelazCodeTipoId,
                                                        dataElaborazione,dataFineVal);
    	else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;

    end if;

   mifCountRec:=mifCountRec+3;
   if ordSostRec is not null then
   		 flussoElabMifElabRec:=null;
   		 flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec-2];
	     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec-2
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         -- <numero_mandato_da_sostituire>
      	 if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	 end if;

      	 if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	   if flussoElabMifElabRec.flussoElabMifElab=true then
--        		mifFlussoOrdinativoRec.mif_ord_num_ord_colleg:=lpad(ordSostRec.ordNumeroSostituto::varchar,NUM_SETTE,ZERO_PAD);
                mifFlussoOrdinativoRec.mif_ord_num_ord_colleg:=ordSostRec.ordNumeroSostituto::varchar;
	    	else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     	end if;
         end if;

     	-- <progressivo_beneficiario_da_sostuire>
     	flussoElabMifElabRec:=null;
  	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec-1];
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec-1
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    	if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
     		if flussoElabMifElabRec.flussoElabMifElab=true then
            	if flussoElabMifElabRec.flussoElabMifDef is not null then
                	mifFlussoOrdinativoRec.mif_ord_progr_ord_colleg:=flussoElabMifElabRec.flussoElabMifDef;
                end if;
     	    else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
	    end if;

        -- <esercizio_mandato_da_sostituire>
        flussoElabMifElabRec:=null;
		flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    	if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
     		if flussoElabMifElabRec.flussoElabMifElab=true then
               	mifFlussoOrdinativoRec.mif_ord_anno_ord_colleg:=ordSostRec.ordAnnoSostituto;
     	    else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
	    end if;

     end if;


     -- <dati_a_disposizione_ente_beneficiario> facoltativo non valorizzato
     -- </informazioni_beneficiario>

     -- <dati_a_disposizione_ente_mandato>
	 -- <codice_distinta>
     flussoElabMifElabRec:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifValore:=null;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	 end if;

     if flussoElabMifElabRec.flussoElabMifAttivo=true then
      if flussoElabMifElabRec.flussoElabMifElab=true then
      		if mifOrdinativoIdRec.mif_ord_dist_id is not null then
				strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura distinta [siac_d_distinta].';
            	select  d.dist_code into flussoElabMifValore
                from siac_d_distinta d
                where d.dist_id=mifOrdinativoIdRec.mif_ord_dist_id;
            end if;

            if flussoElabMifValore is not null then
              	mifFlussoOrdinativoRec.mif_ord_codice_distinta:=flussoElabMifValore;
            end if;
      else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	  end if;
	 end if;

     -- <atto_contabile>
     flussoElabMifElabRec:=null;
     flussoElabMifValore:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
	     if flussoElabMifElabRec.flussoElabMifElab=true then
         	if flussoElabMifElabRec.flussoElabMifParam is not null then
                if attoAmmTipoAllRag is null then
            		attoAmmTipoAllRag:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if attoAmmStrTipoRag is null then
                	attoAmmStrTipoRag:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
         		end if;

                if attoAmmTipoAllRag is not null and  attoAmmStrTipoRag is not null then

                 flussoElabMifValore:=fnc_mif_estremi_attoamm_all(mifOrdinativoIdRec.mif_ord_atto_amm_id,
                 										          attoAmmTipoAllRag,attoAmmStrTipoRag,
                                                                  dataElaborazione, dataFineVal);

                end if;
          	end if;

            if flussoElabMifValore is not null then
                 	mifFlussoOrdinativoRec.mif_ord_codice_atto_contabile:=flussoElabMifValore;
            end if;

         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

      -- 15.01.2018 Sofia SIAC-5765
      -- <codice_operatore>
	  flussoElabMifElabRec:=null;
	  flussoElabMifValore:=null;
	  flussoElabMifValoreDesc:=null;
	  mifCountRec:=mifCountRec+1;
	  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
	  if flussoElabMifElabRec.flussoElabMifAttivo=true then
   		if flussoElabMifElabRec.flussoElabMifElab=true then


         if mifOrdinativoIdRec.mif_ord_login_creazione is not null then
			flussoElabMifValore:=mifOrdinativoIdRec.mif_ord_login_creazione;
         end if;

         if flussoElabMifValore is not null then
        	select substring(s.soggetto_desc  from 1 for 12)  into flussoElabMifValoreDesc
			from siac_t_account a, siac_r_soggetto_ruolo r, siac_t_soggetto s
			where a.ente_proprietario_id=enteProprietarioId
            and   a.account_code=flussoElabMifValore
			and   r.soggeto_ruolo_id=a.soggeto_ruolo_id
			and   s.soggetto_id=r.soggetto_id
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   a.data_cancellazione is null
            and   a.validita_fine is null;

            if 	flussoElabMifValoreDesc is not null then
            	flussoElabMifValore:=flussoElabMifValoreDesc;
            end if;
         end if;

         if flussoElabMifValore is not null then
            mifFlussoOrdinativoRec.mif_ord_code_operatore:=substring(flussoElabMifValore from 1 for 12);
         end if;
       else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	   end if;
     end if;

     -- </dati_a_disposizione_ente_mandato>

     -- </mandato>
/**/
        /*raise notice 'codice_funzione= %',mifFlussoOrdinativoRec.mif_ord_codice_funzione;
		raise notice 'numero_mandato= %',mifFlussoOrdinativoRec.mif_ord_numero;
        raise notice 'data_mandato= %',mifFlussoOrdinativoRec.mif_ord_data;
        raise notice 'importo_mandato= %',mifFlussoOrdinativoRec.mif_ord_importo;*/

		 strMessaggio:='Inserimento mif_t_ordinativo_spesa per ord. numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        INSERT INTO mif_t_ordinativo_spesa
        (
  		-- mif_ord_data_elab, def now
  		 mif_ord_flusso_elab_mif_id,
 		 mif_ord_bil_id,
 		 mif_ord_ord_id,
  		 mif_ord_anno,
  		 mif_ord_numero,
  		 mif_ord_codice_funzione,
  		 mif_ord_data,
  		 mif_ord_importo,
  		 mif_ord_flag_fin_loc,
  		 mif_ord_documento,
  		 mif_ord_bci_tipo_ente_pag,
  		 mif_ord_bci_dest_ente_pag,
  		 mif_ord_bci_conto_tes,
 		 mif_ord_estremi_attoamm,
         mif_ord_resp_attoamm,
         mif_ord_uff_resp_attomm,
  		 mif_ord_codice_abi_bt,
  		 mif_ord_codice_ente,
  		 mif_ord_desc_ente,
  		 mif_ord_codice_ente_bt,
  		 mif_ord_anno_esercizio,
         mif_ord_codice_flusso_oil,
  		 mif_ord_id_flusso_oil,
  		 mif_ord_data_creazione_flusso,
  		 mif_ord_anno_flusso,
 		 mif_ord_codice_struttura,
  		 mif_ord_ente_localita,
  		 mif_ord_ente_indirizzo,
 		 mif_ord_codice_raggrup,
  		 mif_ord_progr_benef,
         mif_ord_progr_dest,
  		 mif_ord_bci_conto,
  		 mif_ord_bci_tipo_contabil,
  		 mif_ord_class_codice_cge,
  		 mif_ord_class_importo,
  		 mif_ord_class_codice_cup,
  		 mif_ord_class_codice_gest_prov,
  		 mif_ord_class_codice_gest_fraz,
  		 mif_ord_codifica_bilancio,
         mif_ord_capitolo,
  		 mif_ord_articolo,
  		 mif_ord_desc_codifica,
         mif_ord_desc_codifica_bil,
  		 mif_ord_gestione,
  		 mif_ord_anno_res,
  		 mif_ord_importo_bil,
  		 mif_ord_stanz,
    	 mif_ord_mandati_stanz,
  		 mif_ord_disponibilita,
  		 mif_ord_prev,
  		 mif_ord_mandati_prev,
  		 mif_ord_disp_cassa,
  		 mif_ord_anag_benef,
  		 mif_ord_indir_benef,
  		 mif_ord_cap_benef,
  		 mif_ord_localita_benef,
  		 mif_ord_prov_benef,
         mif_ord_stato_benef,
  		 mif_ord_partiva_benef,
  		 mif_ord_codfisc_benef,
  		 mif_ord_anag_quiet,
  		 mif_ord_indir_quiet,
  		 mif_ord_cap_quiet,
  		 mif_ord_localita_quiet,
  		 mif_ord_prov_quiet,
  		 mif_ord_partiva_quiet,
  		 mif_ord_codfisc_quiet,
	     mif_ord_stato_quiet,
  		 mif_ord_anag_del,
         mif_ord_indir_del,
         mif_ord_cap_del,
         mif_ord_localita_del,
         mif_ord_prov_del,
  		 mif_ord_codfisc_del,
         mif_ord_partiva_del,
         mif_ord_stato_del,
  		 mif_ord_invio_avviso,
  		 mif_ord_abi_benef,
  		 mif_ord_cab_benef,
  		 mif_ord_cc_benef_estero,
 		 mif_ord_cc_benef,
         mif_ord_ctrl_benef,
  		 mif_ord_cin_benef,
  		 mif_ord_cod_paese_benef,
  		 mif_ord_denom_banca_benef,
  		 mif_ord_cc_postale_benef,
  		 mif_ord_swift_benef,
  		 mif_ord_iban_benef,
         mif_ord_sepa_iban_tr,
         mif_ord_sepa_bic_tr,
         mif_ord_sepa_id_end_tr,
  		 mif_ord_bollo_esenzione,
  		 mif_ord_bollo_carico,
  		 mif_ordin_bollo_caus_esenzione,
  		 mif_ord_commissioni_carico,
         mif_ord_commissioni_esenzione,
  		 mif_ord_commissioni_importo,
         mif_ord_commissioni_natura,
  		 mif_ord_pagam_tipo,
  		 mif_ord_pagam_code,
  		 mif_ord_pagam_importo,
  		 mif_ord_pagam_causale,
  		 mif_ord_pagam_data_esec,
  		 mif_ord_lingua,
  		 mif_ord_rif_doc_esterno,
  		 mif_ord_info_tesoriere,
  		 mif_ord_flag_copertura,
  		 mif_ord_num_ord_colleg,
  		 mif_ord_progr_ord_colleg,
  		 mif_ord_anno_ord_colleg,
  		 mif_ord_code_operatore, -- 15.01.2018 Sofia SIAC-5765
  		 mif_ord_descri_estesa_cap,
  		 mif_ord_siope_codice_cge,
  		 mif_ord_siope_descri_cge,
         mif_ord_codice_ente_ipa,
         mif_ord_codice_ente_istat,
         mif_ord_codice_ente_tramite,
         mif_ord_codice_ente_tramite_bt,
	     mif_ord_riferimento_ente,
         mif_ord_importo_benef,
         mif_ord_pagam_postalizza,
         mif_ord_class_tipo_debito,
         mif_ord_class_tipo_debito_nc,
         mif_ord_class_cig,
         mif_ord_class_motivo_nocig,
         mif_ord_class_missione,
         mif_ord_class_programma,
         mif_ord_class_economico,
         mif_ord_class_importo_economico,
         mif_ord_class_transaz_ue,
         mif_ord_class_ricorrente_spesa,
         mif_ord_class_cofog_codice,
         mif_ord_class_cofog_importo,
         mif_ord_codice_distinta,
         mif_ord_codice_atto_contabile,
  		 validita_inizio,
         ente_proprietario_id,
  		 login_operazione
		)
		VALUES
        (
	  	 --:mif_ord_data_elab,
  		 flussoElabMifLogId, --idElaborazione univoco
  		 mifOrdinativoIdRec.mif_ord_bil_id,
  		 mifOrdinativoIdRec.mif_ord_ord_id,
  		 mifOrdinativoIdRec.mif_ord_ord_anno,
  		 mifFlussoOrdinativoRec.mif_ord_numero,
  		 mifFlussoOrdinativoRec.mif_ord_codice_funzione,
  		 mifFlussoOrdinativoRec.mif_ord_data,
--  	     (case when mifFlussoOrdinativoRec.mif_ord_codice_funzione in (FUNZIONE_CODE_N,FUNZIONE_CODE_A) then
--                    '0.00' else mifFlussoOrdinativoRec.mif_ord_importo end),
         mifFlussoOrdinativoRec.mif_ord_importo,
 		 mifFlussoOrdinativoRec.mif_ord_flag_fin_loc,
  	     mifFlussoOrdinativoRec.mif_ord_documento,
 		 mifFlussoOrdinativoRec.mif_ord_bci_tipo_ente_pag,
 	 	 mifFlussoOrdinativoRec.mif_ord_bci_dest_ente_pag,
 		 mifFlussoOrdinativoRec.mif_ord_bci_conto_tes,
 		 mifFlussoOrdinativoRec.mif_ord_estremi_attoamm,
         mifFlussoOrdinativoRec.mif_ord_resp_attoamm,
  		 mifFlussoOrdinativoRec.mif_ord_uff_resp_attomm,
 		 mifFlussoOrdinativoRec.mif_ord_codice_abi_bt,
 		 mifFlussoOrdinativoRec.mif_ord_codice_ente,
		 mifFlussoOrdinativoRec.mif_ord_desc_ente,
  		 mifFlussoOrdinativoRec.mif_ord_codice_ente_bt,
 		 mifFlussoOrdinativoRec.mif_ord_anno_esercizio,
  		annoBilancio||flussoElabMifDistOilRetId::varchar,
  		flussoElabMifOilId, --idflussoOil
        extract(year from now())||'-'||
        lpad(extract('month' from now())::varchar,2,'0')||'-'||
        lpad(extract('day' from now())::varchar,2,'0')||'T'||
        lpad(extract('hour' from now())::varchar,2,'0')||':'||
        lpad(extract('minute' from now())::varchar,2,'0')||':'||'00',  -- mif_ord_data_creazione_flusso
        extract(year from now())::integer,
 		mifFlussoOrdinativoRec.mif_ord_codice_struttura,
 		mifFlussoOrdinativoRec.mif_ord_ente_localita,
		mifFlussoOrdinativoRec.mif_ord_ente_indirizzo,
 		mifFlussoOrdinativoRec.mif_ord_codice_raggrup,
 		mifFlussoOrdinativoRec.mif_ord_progr_benef,
 		mifFlussoOrdinativoRec.mif_ord_progr_dest,
 		mifFlussoOrdinativoRec.mif_ord_bci_conto,
  		mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil,
 		mifFlussoOrdinativoRec.mif_ord_class_codice_cge,
        mifFlussoOrdinativoRec.mif_ord_class_importo,
 		mifFlussoOrdinativoRec.mif_ord_class_codice_cup,
 		mifFlussoOrdinativoRec.mif_ord_class_codice_gest_prov,
 		mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz,
 		mifFlussoOrdinativoRec.mif_ord_codifica_bilancio,
        mifFlussoOrdinativoRec.mif_ord_capitolo,
  		mifFlussoOrdinativoRec.mif_ord_articolo,
 		mifFlussoOrdinativoRec.mif_ord_desc_codifica,
        mifFlussoOrdinativoRec.mif_ord_desc_codifica_bil,
		mifFlussoOrdinativoRec.mif_ord_gestione,
 		mifFlussoOrdinativoRec.mif_ord_anno_res,
 		mifFlussoOrdinativoRec.mif_ord_importo_bil,
        mifFlussoOrdinativoRec.mif_ord_stanz,
    	mifFlussoOrdinativoRec.mif_ord_mandati_stanz,
  		mifFlussoOrdinativoRec.mif_ord_disponibilita,
		mifFlussoOrdinativoRec.mif_ord_prev,
  		mifFlussoOrdinativoRec.mif_ord_mandati_prev,
  		mifFlussoOrdinativoRec.mif_ord_disp_cassa,
        mifFlussoOrdinativoRec.mif_ord_anag_benef,
  		mifFlussoOrdinativoRec.mif_ord_indir_benef,
		mifFlussoOrdinativoRec.mif_ord_cap_benef,
 		mifFlussoOrdinativoRec.mif_ord_localita_benef,
  		mifFlussoOrdinativoRec.mif_ord_prov_benef,
        mifFlussoOrdinativoRec.mif_ord_stato_benef,
 		mifFlussoOrdinativoRec.mif_ord_partiva_benef,
  		mifFlussoOrdinativoRec.mif_ord_codfisc_benef,
  		mifFlussoOrdinativoRec.mif_ord_anag_quiet,
        mifFlussoOrdinativoRec.mif_ord_indir_quiet,
  		mifFlussoOrdinativoRec.mif_ord_cap_quiet,
 		mifFlussoOrdinativoRec.mif_ord_localita_quiet,
  		mifFlussoOrdinativoRec.mif_ord_prov_quiet,
 		mifFlussoOrdinativoRec.mif_ord_partiva_quiet,
 		mifFlussoOrdinativoRec.mif_ord_codfisc_quiet,
        mifFlussoOrdinativoRec.mif_ord_stato_quiet,
 		mifFlussoOrdinativoRec.mif_ord_anag_del,
        mifFlussoOrdinativoRec.mif_ord_indir_del,
        mifFlussoOrdinativoRec.mif_ord_cap_del,
 		mifFlussoOrdinativoRec.mif_ord_localita_del,
 		mifFlussoOrdinativoRec.mif_ord_prov_del,
 		mifFlussoOrdinativoRec.mif_ord_codfisc_del,
 		mifFlussoOrdinativoRec.mif_ord_partiva_del,
        mifFlussoOrdinativoRec.mif_ord_stato_del,
 		mifFlussoOrdinativoRec.mif_ord_invio_avviso,
 		mifFlussoOrdinativoRec.mif_ord_abi_benef,
 		mifFlussoOrdinativoRec.mif_ord_cab_benef,
 		mifFlussoOrdinativoRec.mif_ord_cc_benef_estero,
 		mifFlussoOrdinativoRec.mif_ord_cc_benef,
 		mifFlussoOrdinativoRec.mif_ord_ctrl_benef,
 		mifFlussoOrdinativoRec.mif_ord_cin_benef,
 		mifFlussoOrdinativoRec.mif_ord_cod_paese_benef,
  		mifFlussoOrdinativoRec.mif_ord_denom_banca_benef,
 		mifFlussoOrdinativoRec.mif_ord_cc_postale_benef,
  		mifFlussoOrdinativoRec.mif_ord_swift_benef,
  		mifFlussoOrdinativoRec.mif_ord_iban_benef,
        mifFlussoOrdinativoRec.mif_ord_sepa_iban_tr,
        mifFlussoOrdinativoRec.mif_ord_sepa_bic_tr,
        mifFlussoOrdinativoRec.mif_ord_sepa_id_end_tr,
 		mifFlussoOrdinativoRec.mif_ord_bollo_esenzione,
  		mifFlussoOrdinativoRec.mif_ord_bollo_carico,
  		mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione,
 		mifFlussoOrdinativoRec.mif_ord_commissioni_carico,
        mifFlussoOrdinativoRec.mif_ord_commissioni_esenzione,
		mifFlussoOrdinativoRec.mif_ord_commissioni_importo,
        mifFlussoOrdinativoRec.mif_ord_commissioni_natura,
  		mifFlussoOrdinativoRec.mif_ord_pagam_tipo,
 		mifFlussoOrdinativoRec.mif_ord_pagam_code,
	    mifFlussoOrdinativoRec.mif_ord_pagam_importo,
 		mifFlussoOrdinativoRec.mif_ord_pagam_causale,
 		mifFlussoOrdinativoRec.mif_ord_pagam_data_esec,
 		mifFlussoOrdinativoRec.mif_ord_lingua,
		mifFlussoOrdinativoRec.mif_ord_rif_doc_esterno,
 		mifFlussoOrdinativoRec.mif_ord_info_tesoriere,
 		mifFlussoOrdinativoRec.mif_ord_flag_copertura,
		mifFlussoOrdinativoRec.mif_ord_num_ord_colleg,
		mifFlussoOrdinativoRec.mif_ord_progr_ord_colleg,
		mifFlussoOrdinativoRec.mif_ord_anno_ord_colleg,
        mifFlussoOrdinativoRec.mif_ord_code_operatore, -- 15.01.2018 Sofia SIAC-5765
        mifFlussoOrdinativoRec.mif_ord_descri_estesa_cap,
        mifFlussoOrdinativoRec.mif_ord_siope_codice_cge,
        mifFlussoOrdinativoRec.mif_ord_siope_descri_cge,
        mifFlussoOrdinativoRec.mif_ord_codice_ente_ipa,
        mifFlussoOrdinativoRec.mif_ord_codice_ente_istat,
        mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite,
        mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite_bt,
	    mifFlussoOrdinativoRec.mif_ord_riferimento_ente,
        mifFlussoOrdinativoRec.mif_ord_importo_benef,
        mifFlussoOrdinativoRec.mif_ord_pagam_postalizza,
        mifFlussoOrdinativoRec.mif_ord_class_tipo_debito,
        mifFlussoOrdinativoRec.mif_ord_class_tipo_debito_nc,
        mifFlussoOrdinativoRec.mif_ord_class_cig,
        mifFlussoOrdinativoRec.mif_ord_class_motivo_nocig,
        mifFlussoOrdinativoRec.mif_ord_class_missione,
        mifFlussoOrdinativoRec.mif_ord_class_programma,
        mifFlussoOrdinativoRec.mif_ord_class_economico,
        mifFlussoOrdinativoRec.mif_ord_class_importo_economico,
        mifFlussoOrdinativoRec.mif_ord_class_transaz_ue,
        mifFlussoOrdinativoRec.mif_ord_class_ricorrente_spesa,
        mifFlussoOrdinativoRec.mif_ord_class_cofog_codice,
        mifFlussoOrdinativoRec.mif_ord_class_cofog_importo,
	    mifFlussoOrdinativoRec.mif_ord_codice_distinta,
        mifFlussoOrdinativoRec.mif_ord_codice_atto_contabile,
        now(),
        enteProprietarioId,
        loginOperazione
   )
   returning mif_ord_id into mifOrdSpesaId;




 -- dati fatture da valorizzare se ordinativo commerciale
 -- @@@@ sicuramente da completare
 -- <fattura_siope>
 if isGestioneFatture = true and isOrdCommerciale=true then
  flussoElabMifElabRec:=null;
  mifCountRec:=FLUSSO_MIF_ELAB_FATTURE;
  titoloCap:=null;
  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Gestione fatture.Lettura natura spesa.';

  /*if mifOrdinativoIdRec.mif_ord_titolo_code=titoloCorrente then
	  	titoloCap:=descriTitoloCorrente;
  else
   if mifOrdinativoIdRec.mif_ord_titolo_code=titoloCapitale then
     	titoloCap:=descriTitoloCapitale;
   end if;
  end if;*/
  -- 20.02.2018 Sofia JIRA siac-5849
  select oil.oil_natura_spesa_desc into titoloCap
  from siac_d_oil_natura_spesa oil, siac_r_oil_natura_spesa_titolo r
  where r.oil_natura_spesa_titolo_id=mifOrdinativoIdRec.mif_ord_titolo_id
  and   oil.oil_natura_spesa_id=r.oil_natura_spesa_id
  and   r.data_cancellazione is null
  and   r.validita_fine is null;
  if titoloCap is null then titoloCap:=defNaturaPag; end if;
   -- 26.02.2018 Sofia JIRA siac-5849 - inclusione delle note credito  per ordinativi di pagamento
  titoloCap:=titoloCap||'|S';
  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Gestione fatture.Inizio ciclo.';
  ordRec:=null;
  for ordRec in
  (select * from fnc_mif_ordinativo_documenti_splus( mifOrdinativoIdRec.mif_ord_ord_id,
											         numeroDocs::integer,
                                                     tipoDocs,
                                                     docAnalogico,
                                                     attrCodeDataScad,
                                                     titoloCap,
                                                     enteOilRec.ente_oil_codice_pcc_uff,
		   		                        	         enteProprietarioId,
	            		                             dataElaborazione,dataFineVal)
  )
  loop
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Inserimento fatture '
                       ||' in mif_t_ordinativo_spesa_documenti '
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         insert into  mif_t_ordinativo_spesa_documenti
         ( mif_ord_id,
		   mif_ord_documento,
           mif_ord_doc_codice_ipa_ente,
	       mif_ord_doc_tipo,
           mif_ord_doc_tipo_a,
		   mif_ord_doc_id_lotto_sdi,
		   mif_ord_doc_tipo_analog,
		   mif_ord_doc_codfisc_emis,
		   mif_ord_doc_anno,
	       mif_ord_doc_numero,
	       mif_ord_doc_importo,
	       mif_ord_doc_data_scadenza,
	       mif_ord_doc_motivo_scadenza,
	       mif_ord_doc_natura_spesa,
		   validita_inizio,
		   ente_proprietario_id,
		   login_operazione
         )
         values
         (mifOrdSpesaId,
          ordRec.numero_fattura_siope,
		  ordRec.codice_ipa_ente_siope,
		  ordRec.tipo_documento_siope,
          ordRec.tipo_documento_siope_a,
          ordRec.identificativo_lotto_sdi_siope,
          ordRec.tipo_documento_analogico_siope,
          trim ( both ' ' from ordRec.codice_fiscale_emittente_siope),
		  ordRec.anno_emissione_fattura_siope,
		  ordRec.numero_fattura_siope,
          ordRec.importo_siope,
		  ordRec.data_scadenza_pagam_siope,
		  ordRec.motivo_scadenza_siope,
    	  ordRec.natura_spesa_siope,
          now(),
          enteProprietarioId,
          loginOperazione
         );
  end loop;
 end if;




   -- <ritenuta>
   -- <importo_ritenuta>
   -- <numero_reversale>
   -- <progressivo_reversale>

   if  isRitenutaAttivo=true then
    ritenutaRec:=null;
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Gestione  ritenute'
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    for ritenutaRec in
    (select *
     from fnc_mif_ordinativo_ritenute(mifOrdinativoIdRec.mif_ord_ord_id,
         	 					      tipoRelazRitOrd,tipoRelazSubOrd,tipoRelazSprOrd,
                                      tipoOnereIrpefId,tipoOnereInpsId,
                                      tipoOnereIrpegId,
									  ordStatoCodeAId,ordDetTsTipoId,
                                      flussoElabMifTipoDec,
    	                              enteProprietarioId,dataElaborazione,dataFineVal)
    )
    loop
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Inserimento ritenuta'
                       ||' in mif_t_ordinativo_spesa_ritenute '
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   		insert into mif_t_ordinativo_spesa_ritenute
        (mif_ord_id,
  		 mif_ord_rit_tipo,
 		 mif_ord_rit_importo,
 		 mif_ord_rit_numero,
  		 mif_ord_rit_ord_id,
 		 mif_ord_rit_progr_rev,
  		 validita_inizio,
		 ente_proprietario_id,
		 login_operazione)
        values
        (mifOrdSpesaId,
         tipoRitenuta,
         ritenutaRec.importoRitenuta,
         ritenutaRec.numeroRitenuta,
         ritenutaRec.ordRitenutaId,
         progrRitenuta,
         now(),
         enteProprietarioId,
         loginOperazione
        );

    end loop;
   end if;

   -- <sospeso>
   -- <numero_provvisorio>
   -- <importo_provvisorio>
  if  isRicevutaAttivo=true then
    ricevutaRec:=null;
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Gestione  provvisori'
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    for ricevutaRec in
    (select *
     from fnc_mif_ordinativo_ricevute(mifOrdinativoIdRec.mif_ord_ord_id,
                                      flussoElabMifTipoDec,
    	                              enteProprietarioId,dataElaborazione,dataFineVal)
    )
    loop
    	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Inserimento   ricevuta'
                       ||' in mif_t_ordinativo_spesa_ricevute '
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   		insert into mif_t_ordinativo_spesa_ricevute
        (mif_ord_id,
	     mif_ord_ric_anno,
	     mif_ord_ric_numero,
	     mif_ord_provc_id,
		 mif_ord_ric_importo,
	     validita_inizio,
		 ente_proprietario_id,
	     login_operazione
        )
        values
        (mifOrdSpesaId,
         ricevutaRec.annoRicevuta,
         ricevutaRec.numeroRicevuta,
         ricevutaRec.provRicevutaId,
         ricevutaRec.importoRicevuta,
         now(),
         enteProprietarioId,
         loginOperazione
        );
    end loop;
  end if;

  numeroOrdinativiTrasm:=numeroOrdinativiTrasm+1;
 end loop;

/* if comPccAttrId is not null and numeroOrdinativiTrasm>0 then
   	   strMessaggio:='Inserimento Registro PCC.';
	   insert into siac_t_registro_pcc
	   (doc_id,
    	subdoc_id,
	    pccop_tipo_id,
    	ordinativo_data_emissione,
	    ordinativo_numero,
    	rpcc_quietanza_data,
        rpcc_quietanza_importo,
	    soggetto_id,
    	validita_inizio,
	    ente_proprietario_id,
    	login_operazione
	    )
    	(
         with
         mif as
         (select m.mif_ord_ord_id ord_id, m.mif_ord_soggetto_id soggetto_id,
                 ord.ord_emissione_data , ord.ord_numero
          from mif_t_ordinativo_spesa_id m, siac_t_ordinativo ord
          where m.ente_proprietario_id=enteProprietarioId
          and   substring(m.mif_ord_codice_funzione from 1 for 1)=FUNZIONE_CODE_I
          and   ord.ord_id=m.mif_ord_ord_id
         ),
         tipodoc as
         (select tipo.doc_tipo_id
          from siac_d_doc_tipo tipo ,siac_r_doc_tipo_attr attr
          where attr.attr_id=comPccAttrId
          and   attr.boolean='S'
          and   tipo.doc_tipo_id=attr.doc_tipo_id
          and   attr.data_cancellazione is null
          and   attr.validita_fine is null
          and   tipo.data_cancellazione is null
          and   tipo.validita_fine is null
         ),
         doc as
         (select distinct m.mif_ord_ord_id ord_id, subdoc.doc_id , subdoc.subdoc_id, subdoc.subdoc_importo, doc.doc_tipo_id
	      from  mif_t_ordinativo_spesa_id m, siac_t_ordinativo_ts ts, siac_r_subdoc_ordinativo_ts rsubdoc,
                siac_t_subdoc subdoc, siac_t_doc doc
          where m.ente_proprietario_id=enteProprietarioId
          and   substring(m.mif_ord_codice_funzione from 1 for 1)=FUNZIONE_CODE_I
          and   ts.ord_id=m.mif_ord_ord_id
          and   rsubdoc.ord_ts_id=ts.ord_ts_id
          and   subdoc.subdoc_id=rsubdoc.subdoc_id
          and   doc.doc_id=subdoc.doc_id
          and   ts.data_cancellazione is null
          and   ts.validita_fine is null
          and   rsubdoc.data_cancellazione is null
          and   rsubdoc.validita_fine is null
          and   subdoc.data_cancellazione is null
          and   subdoc.validita_fine is null
          and   doc.data_cancellazione is null
          and   doc.validita_fine is null
         )
         select
          doc.doc_id,
          doc.subdoc_id,
          pccOperazTipoId,
--          mif.ord_emissione_data,
--		  mif.ord_emissione_data+(1*interval '1 day'),
		  mif.ord_emissione_data,
          mif.ord_numero,
          dataElaborazione,
          doc.subdoc_importo,
          mif.soggetto_id,
          now(),
          enteProprietarioId,
          loginOperazione
         from mif, doc,tipodoc
         where mif.ord_id=doc.ord_id
         and   tipodoc.doc_tipo_id=doc.doc_tipo_id
        );
   end if;*/


   strMessaggio:='Aggiornamento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
   update siac_t_progressivo p set prog_value=flussoElabMifOilId
   where p.ente_proprietario_id=enteProprietarioId
   and   p.prog_key='oil_out_'||annoBilancio
   and   p.ambito_id=ambitoFinId
   and   p.data_cancellazione is null
   and   p.validita_fine is null;

   strMessaggio:='Aggiornamento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_'||MANDMIF_TIPO||'_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
   update siac_t_progressivo p set prog_value=flussoElabMifDistOilRetId
   where p.ente_proprietario_id=enteProprietarioId
   and   p.prog_key='oil_'||MANDMIF_TIPO||'_'||annoBilancio
   and   p.ambito_id=ambitoFinId
   and   p.data_cancellazione is null
   and   p.validita_fine is null;


   strMessaggio:='Aggiornamento mif_t_flusso_elaborato.';

   update  mif_t_flusso_elaborato
   set (flusso_elab_mif_id_flusso_oil,flusso_elab_mif_codice_flusso_oil,flusso_elab_mif_num_ord_elab,flusso_elab_mif_file_nome,flusso_elab_mif_esito_msg)=
   	   (flussoElabMifOilId,annoBilancio||flussoElabMifDistOilRetId::varchar,numeroOrdinativiTrasm,flussoElabMifTipoNomeFile||'_'||enteOilRec.ente_oil_codice,
        'Elaborazione in corso tipo flusso '||MANDMIF_TIPO||' - Dati inseriti in mif_t_ordinativo_spesa')
   where flusso_elab_mif_id=flussoElabMifLogId;

    -- gestire aggiornamento mif_t_flusso_elaborato

	RAISE NOTICE 'numeroOrdinativiTrasm %', numeroOrdinativiTrasm;
    messaggioRisultato:=strMessaggioFinale||' Trasmessi '||numeroOrdinativiTrasm||' ordinativi di spesa.';
    messaggioRisultato:=upper(messaggioRisultato);
    flussoElabMifId:=flussoElabMifLogId;
    nomeFileMif:=flussoElabMifTipoNomeFile||'_'||enteOilRec.ente_oil_codice;


    flussoElabMifDistOilId:=(annoBilancio||flussoElabMifDistOilRetId::varchar)::integer;
    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE :  % %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 100),mifCountRec;
        if codResult=-12 then
          messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'')||' '||mifCountRec||'.' ;
          codiceRisultato:=0;
        else
          messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'')||' '||mifCountRec||'.' ;
       	  codiceRisultato:=-1;
    	end if;

        numeroOrdinativiTrasm:=0;
		messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then
            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;
        else
        	flussoElabMifId:=null;
        end if;

        return;
     when NO_DATA_FOUND THEN
        raise notice '% % ERRORE : % %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500),mifCountRec;
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio '||' '||mifCountRec||'.';
        numeroOrdinativiTrasm:=0;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then
            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;
        else
        	flussoElabMifId:=null;
        end if;

        return;
     when TOO_MANY_ROWS THEN
        raise notice '% % ERRORE : % %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500),mifCountRec;
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio '||' '||mifCountRec||'.';
        numeroOrdinativiTrasm:=0;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then


            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;
        else
        	flussoElabMifId:=null;
        end if;
        return;
	when others  THEN
		raise notice '% % Errore DB % % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 100),mifCountRec;
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500)||' '||mifCountRec||'.' ;
        numeroOrdinativiTrasm:=0;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then
            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;

        else
        	flussoElabMifId:=null;
        end if;

        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_entrata_splus
( enteProprietarioId integer,
  nomeEnte VARCHAR,
  annobilancio varchar,
  loginOperazione varchar,
  dataElaborazione timestamp,
  mifOrdRitrasmElabId integer,
  out flussoElabMifDistOilId integer,
  out flussoElabMifId integer,
  out numeroOrdinativiTrasm integer,
  out nomeFileMif varchar,
  out codiceRisultato integer,
  out messaggioRisultato varchar )
RETURNS record AS
$body$
DECLARE


 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';
 strMessaggioScarto VARCHAR(1500):='';
 strExecSql VARCHAR(1500):='';

 mifOrdinativoIdRec record;

 mifFlussoOrdinativoRec  mif_t_ordinativo_entrata%rowtype;
-- ordinativoRec record;


 enteOilRec record;
 enteProprietarioRec record;
 soggettoRec record;
 isIndirizzoBenef boolean:=false;
 ordRec record;

 bilElemRec record;
 indirizzoRec record;
 ordSostRec record;
 ricevutaRec record;
 quoteOrdinativoRec record;

 flussoElabMifValore varchar (1000):=null;
 flussoElabMifValoreDesc varchar (1000):=null;




 classCdrTipoId INTEGER:=null;
 classCdcTipoId INTEGER:=null;

 codiceCge  varchar(50):=null;
 siopeDef   varchar(50):=null;
 descCge    varchar(500):=null;
 codResult   integer:=null;

 indirizzoEnte varchar(500):=null;
 localitaEnte varchar(500):=null;
 soggettoEnteId INTEGER:=null;
 soggettoRifId integer:=null;
 siopeClassTipoId integer:=null;

 ordTipoCodeId integer :=null;
 ordStatoCodeIId  integer :=null;
 ordStatoCodeAId  integer :=null;
 ordRelazCodeTipoId integer :=null;
 ordDetTsTipoId integer :=null;



 ambitoFinId integer:=null;

 isDefAnnoRedisuo  varchar(5):=null;
 isRicevutaAttivo boolean:=false;
 isGestioneFatture boolean:=false;

 codiceUECodeTipo VARCHAR(50):=null;
 codiceUECodeTipoId integer:=null;


 ordAllegatoCartAttrId integer:=null;
 ordinativoTsDetTipoId integer:=null;
 movgestTsTipoSubId integer:=null;
 ordinativoSpesaTipoId integer:=null;


 flussoElabMifLogId  integer :=null;
 flussoElabMifTipoId integer :=null;
 flussoElabMifTipoNomeFile varchar(500):=null;
 flussoElabMifTipoDec BOOLEAN:=false;

 flussoElabMifOilId integer :=null;
 flussoElabMifDistOilRetId integer:=null;
 mifOrdSpesaId integer:=null;

 NVL_STR               CONSTANT VARCHAR:='';
 dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataFineVal timestamp :=annoBilancio||'-12-31';


 ordImporto numeric :=0;

 dataAvvioSiopeNew VARCHAR(50):=null;
 bAvvioSiopeNew   boolean:=false;


 -- siope plus
 tipoIncassoCode    varchar(100):=null;
 tipoIncassoCodeId  integer:=null;
 tipoRitOrdInc      varchar(100):=null;
 tipoSplitOrdInc    varchar(100):=null;
 tipoSubOrdInc      varchar(100):=null;
 tipoRitenuteInc    varchar(100):=null;
 tipoIncassoCompensazione varchar(100):=null;
 tipoIncassoRegolarizza varchar(100):=null;
 tipoIncassoCassa varchar(100):=null;
 tipoContoCCPCode varchar(100):=null;
 tipoContoCCPCodeId integer:=null;
 siopeCodeTipo varchar(50):=null;
 siopeCodeTipoId integer :=null;
 codiceFinVTbr varchar(50):=null;
 codiceFinVTipoTbrId integer:=null;

 tipoClassFruttifero varchar(100):=null;
 valFruttifero varchar(100):=null;
 valFruttiferoStr varchar(100):=null;
 valFruttiferoStrAltro varchar(100):=null;
 tipoClassFruttiferoId integer:=null;
 valFruttiferoId  integer:=null;
 eventoTipoCodeId integer:=null;
 collEventoCodeId integer:=null;
 ricorrenteCodeTipoId integer:=null;
 ricorrenteCodeTipo varchar(100):=null;

 classVincolatoCode   varchar(100):=null;
 classVincolatoCodeId INTEGER:=null;

 ordCodiceBollo  varchar(10):=null;
 ordCodiceBolloDesc varchar(500):=null;
 codiceBolloPlusDesc   varchar(100):=null;

 codiceBolloPlusEsente boolean:=false;
 isOrdCommerciale boolean:=false;

 attoAmmTipoAllRag varchar(50):=null;
 attoAmmStrTipoRag varchar(50):=null;
 -- siope plus


 ORD_TIPO_CODE_P  CONSTANT  varchar :='P';
 ORD_TIPO_CODE_I  CONSTANT  varchar :='I';
 ORD_STATO_CODE_I CONSTANT  varchar :='I';
 ORD_STATO_CODE_A CONSTANT  varchar :='A';
 ORD_TIPO_IMPORTO_A CONSTANT  varchar :='A';


 AMBITO_FIN CONSTANT  varchar :='AMBITO_FIN';
 ALLEG_CART_ATTR CONSTANT VARCHAR:='flagAllegatoCartaceo';

 CDC CONSTANT varchar:='CDC';
 CDR CONSTANT varchar:='CDR';

 FUNZIONE_CODE_I CONSTANT  varchar :='INSERIMENTO';
 FUNZIONE_CODE_S CONSTANT  varchar :='SOSTITUZIONE';
 FUNZIONE_CODE_N CONSTANT  varchar :='ANNULLO';

 -- annullamenti e variazioni dopo trasmissione
 FUNZIONE_CODE_A CONSTANT  varchar :='ANNULLO';
 FUNZIONE_CODE_VB CONSTANT  varchar :='VARIAZIONE';

 ORD_RELAZ_CODE_SOS  CONSTANT  varchar :='SOS_ORD';
 ORD_TS_DET_TIPO_A CONSTANT varchar:='A';
 MOVGEST_TS_TIPO_S  CONSTANT varchar:='S';


 REGMOVFIN_STATO_A              CONSTANT varchar:='A';
 SEGNO_ECONOMICO				CONSTANT varchar:='Avere';

 SPACE_ASCII CONSTANT integer:=32;
 VT_ASCII CONSTANT integer:=13;
 BS_ASCII CONSTANT integer:=10;

 NUM_SETTE CONSTANT integer:=7;
 ZERO_PAD CONSTANT  varchar :='0';

 ELAB_MIF_ESITO_IN CONSTANT  varchar :='IN';
 MANDMIF_TIPO  CONSTANT  varchar :='REVMIF_SPLUS';


 SEPARATORE     CONSTANT  varchar :='|';

 mifFlussoElabMifArr flussoElabMifRecType[];

 mifCountTmpRec integer :=null;
 mifCountRec integer:=1;
 mifAFlussoElabTypeRec  flussoElabMifRecType;
 flussoElabMifElabRec  flussoElabMifRecType;
 mifElabRec record;

 tipologiaTipoId integer:=null;
 categoriaTipoId integer:=null;
 famTitEntTipoCategId integer:=null;
 ordinativoSplitId integer:=null;


 numeroDocs  varchar(10):=null;
 tipoDocs    varchar(50):=null;
 tipoGruppoDocs   varchar(50):=null;
 docAnalogico varchar(50):=null;
 attrCodeDataScad varchar(50):=null;

 titoloCorrente varchar(10):=null;
 descriTitoloCorrente varchar(50):=null;
 titoloCapitale varchar(10):=null;
 descriTitoloCapitale varchar(50):=null;
 titoloCap varchar(10):=null;
 macroAggrTipoCode varchar(20):=null;
 macroAggrTipoCodeId integer:=null;


 -- 23.02.2018 Sofia jira siac-5849
 defNaturaPag  varchar(100):=null;
 famMacroTitCode varchar(100):=null;
 famMacroTitCodeId integer:=null;

 FAM_TIT_ENT_TIPCATEG CONSTANT varchar:='Entrata - TitoliTipologieCategorie';
 CATEGORIA CONSTANT varchar:='CATEGORIA';
 TIPOLOGIA CONSTANT varchar:='TIPOLOGIA';



 FLUSSO_MIF_ELAB_TEST_COD_ABI_BT      CONSTANT integer:=1;  -- codice_ABI_BT
 FLUSSO_MIF_ELAB_TEST_COD_ENTE_IPA    CONSTANT integer:=4;  -- codice_ente
 FLUSSO_MIF_ELAB_TEST_DESC_ENTE       CONSTANT integer:=5;  -- descrizione_ente
 FLUSSO_MIF_ELAB_TEST_COD_ISTAT_ENTE  CONSTANT integer:=6;  -- codice_istat_ente
 FLUSSO_MIF_ELAB_TEST_CODFISC_ENTE    CONSTANT integer:=7;  -- codice_fiscale_ente
 FLUSSO_MIF_ELAB_TEST_CODTRAMITE_ENTE CONSTANT integer:=8;  -- codice_tramite_ente
 FLUSSO_MIF_ELAB_TEST_CODTRAMITE_BT   CONSTANT integer:=9;  -- codice_tramite_bt
 FLUSSO_MIF_ELAB_TEST_COD_ENTE_BT     CONSTANT integer:=10; -- codice_ente_bt
 FLUSSO_MIF_ELAB_TEST_RIFERIMENTO_ENTE CONSTANT integer:=11; -- riferimento_ente
 FLUSSO_MIF_ELAB_TEST_ESERCIZIO       CONSTANT integer:=12;  -- esercizio

 FLUSSO_MIF_ELAB_INIZIO_ORD     CONSTANT integer:=13;  -- tipo_operazione
 FLUSSO_MIF_ELAB_FATTURE        CONSTANT integer:=35;  -- codice_ipa_ente_siope
 FLUSSO_MIF_ELAB_FATT_CODFISC   CONSTANT integer:=40;  -- codice_fiscale_emittente_siope
 FLUSSO_MIF_ELAB_FATT_DATASCAD_PAG  CONSTANT integer:=44;  -- data_scadenza_pagam_siope
 FLUSSO_MIF_ELAB_FATT_NATURA_PAG CONSTANT integer:=46;  -- natura_spesa_siope
 FLUSSO_MIF_ELAB_NUM_SOSPESO    CONSTANT integer:=62;  -- numero_provvisorio



BEGIN

	numeroOrdinativiTrasm:=0;
    codiceRisultato:=0;
    messaggioRisultato:='';
	flussoElabMifId:=null;
    nomeFileMif:=null;

    flussoElabMifDistOilId:=null;

	strMessaggioFinale:='Invio ordinativi di entrata a SIOPE PLUS.';


    -- enteOilRec
    strMessaggio:='Lettura dati ente OIL  per flusso MIF tipo '||MANDMIF_TIPO||'.';
    select * into strict enteOilRec
    from siac_t_ente_oil ente
    where ente.ente_proprietario_id=enteProprietarioId
    and   ente.data_cancellazione is null
    and   ente.validita_fine is null;

    if enteOilRec is null then
    	raise exception ' Errore in reperimento dati';
    end if;

    if enteOilRec.ente_oil_siope_plus=false then
    	raise exception ' SIOPE PLUS non attivo per l''ente.';
    end if;

    -- inserimento record in tabella mif_t_flusso_elaborato
    strMessaggio:='Inserimento mif_t_flusso_elaborato tipo_flusso='||MANDMIF_TIPO||'.';

    insert into mif_t_flusso_elaborato
    (flusso_elab_mif_data ,
     flusso_elab_mif_esito,
     flusso_elab_mif_esito_msg,
     flusso_elab_mif_file_nome,
     flusso_elab_mif_tipo_id,
     flusso_elab_mif_id_flusso_oil, -- da calcolare su tab progressivi
     validita_inizio,
     ente_proprietario_id,
     login_operazione)
     (select dataElaborazione,
             ELAB_MIF_ESITO_IN,
             'Elaborazione in corso per tipo flusso '||MANDMIF_TIPO,
      		 tipo.flusso_elab_mif_nome_file,
     		 tipo.flusso_elab_mif_tipo_id,
     		 null,--flussoElabMifOilId, -- da calcolare su tab progressivi
    		 dataElaborazione,
     		 enteProprietarioId,
      		 loginOperazione
      from mif_d_flusso_elaborato_tipo tipo
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.flusso_elab_mif_tipo_code=MANDMIF_TIPO
      and   tipo.data_cancellazione is null
      and   tipo.validita_fine is null
     )
     returning flusso_elab_mif_id into flussoElabMifLogId;-- valore da restituire

      raise notice 'flussoElabMifLogId %',flussoElabMifLogId;

     if flussoElabMifLogId is null then
       RAISE EXCEPTION ' Errore generico in inserimento %.',MANDMIF_TIPO;
     end if;

    strMessaggio:='Verifica esistenza elaborazioni in corso per tipo flusso '||MANDMIF_TIPO||'.';
	codResult:=null;
    select distinct 1 into codResult
    from mif_t_flusso_elaborato elab,  mif_d_flusso_elaborato_tipo tipo
    where  elab.flusso_elab_mif_id!=flussoElabMifLogId
    and    elab.flusso_elab_mif_esito=ELAB_MIF_ESITO_IN
    and    elab.data_cancellazione is null
    and    elab.validita_fine is null
    and    tipo.flusso_elab_mif_tipo_id=elab.flusso_elab_mif_tipo_id
    and    tipo.flusso_elab_mif_tipo_code=MANDMIF_TIPO
    and    tipo.ente_proprietario_id=enteProprietarioId
    and    tipo.data_cancellazione is null
    and    tipo.validita_fine is null;

    if codResult is not null then
    	RAISE EXCEPTION ' Verificare situazioni esistenti.';
    end if;

    -- verifico se la tabella degli id contiene dati in tal caso elaborazioni precedenti sono andate male
    strMessaggio:='Verifica esistenza dati in tabella temporanea id [mif_t_ordinativo_entrata_id].';
    codResult:=null;

    select distinct 1 into codResult
    from mif_t_ordinativo_entrata_id mif
    where mif.ente_proprietario_id=enteProprietarioId;


    if codResult is not null then
      RAISE EXCEPTION ' Dati presenti verificarne il contenuto ed effettuare pulizia prima di rieseguire.';
    end if;



    codResult:=null;
    -- recupero indentificativi tipi codice vari
	begin

        -- ordTipoCodeId
        strMessaggio:='Lettura ordinativo tipo Code Id '||ORD_TIPO_CODE_I||'.';
        select ord_tipo.ord_tipo_id into strict ordTipoCodeId
        from siac_d_ordinativo_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_tipo_code=ORD_TIPO_CODE_I
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));

		-- ordinativoSpesaTipoId
        strMessaggio:='Lettura ordinativo tipo Code Id '||ORD_TIPO_CODE_P||'.';
        select ord_tipo.ord_tipo_id into strict ordinativoSpesaTipoId
        from siac_d_ordinativo_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_tipo_code=ORD_TIPO_CODE_P
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));

		-- ordStatoCodeIId
        strMessaggio:='Lettura ordinativo stato Code Id '||ORD_STATO_CODE_I||'.';
        select ord_tipo.ord_stato_id into strict ordStatoCodeIId
        from siac_d_ordinativo_stato ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_stato_code=ORD_STATO_CODE_I
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));

        -- ordStatoCodeAId
        strMessaggio:='Lettura ordinativo stato Code Id '||ORD_STATO_CODE_A||'.';
        select ord_tipo.ord_stato_id into strict ordStatoCodeAId
        from siac_d_ordinativo_stato ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_stato_code=ORD_STATO_CODE_A
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


        -- classCdrTipoId
        strMessaggio:='Lettura classif Id per tipo sac='||CDR||'.';
        select tipo.classif_tipo_id into strict classCdrTipoId
        from siac_d_class_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.classif_tipo_code=CDR
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

        -- classCdcTipoId
        strMessaggio:='Lettura classif Id per tipo sac='||CDC||'.';
        select tipo.classif_tipo_id into strict classCdrTipoId
        from siac_d_class_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.classif_tipo_code=CDC
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));


		-- ordAllegatoCartAttrId
        strMessaggio:='Lettura attributo ordinativo  Code Id '||ALLEG_CART_ATTR||'.';
        select attr.attr_id into strict ordAllegatoCartAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=ALLEG_CART_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attr.validita_fine,dataElaborazione));

		-- ordDetTsTipoId
        strMessaggio:='Lettura tipo importo ordinativo  Code Id '||ORD_TIPO_IMPORTO_A||'.';
        select ord_tipo.ord_ts_det_tipo_id into strict ordDetTsTipoId
        from siac_d_ordinativo_ts_det_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_ts_det_tipo_code=ORD_TIPO_IMPORTO_A
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));



		-- ordinativoTsDetTipoId
        strMessaggio:='Lettura ordinativo_ts_det_tipo '||ORD_TS_DET_TIPO_A||'.';
		select ord_tipo.ord_ts_det_tipo_id into strict ordinativoTsDetTipoId
    	from siac_d_ordinativo_ts_det_tipo ord_tipo
		where ord_tipo.ente_proprietario_id=enteProprietarioId
		and   ord_tipo.ord_ts_det_tipo_code=ORD_TS_DET_TIPO_A
		and   ord_tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));

        -- movgestTsTipoSubId
        strMessaggio:='Lettura movgest_ts_tipo  '||MOVGEST_TS_TIPO_S||'.';
		select ord_tipo.movgest_ts_tipo_id into strict movgestTsTipoSubId
    	from siac_d_movgest_ts_tipo ord_tipo
		where ord_tipo.ente_proprietario_id=enteProprietarioId
		and   ord_tipo.movgest_ts_tipo_code=MOVGEST_TS_TIPO_S
		and   ord_tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));

        -- ordRelazCodeTipoId
        strMessaggio:='Lettura relazione   Code Id '||ORD_RELAZ_CODE_SOS||'.';
		select ord_tipo.relaz_tipo_id into strict ordRelazCodeTipoId
    	from siac_d_relaz_tipo ord_tipo
		where ord_tipo.ente_proprietario_id=enteProprietarioId
		and   ord_tipo.relaz_tipo_code=ORD_RELAZ_CODE_SOS
		and   ord_tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


        -- ambitoFinId
        strMessaggio:='Lettura ambito  Code Id '||AMBITO_FIN||'.';
        select a.ambito_id into strict ambitoFinId
        from siac_d_ambito a
        where a.ente_proprietario_id=enteProprietarioId
   		and   a.ambito_code=AMBITO_FIN
        and   a.data_cancellazione is null
        and   a.validita_fine is null;

		-- tipologiaTipoId
        strMessaggio:='Lettura tipologia_code_tipo_id  '||TIPOLOGIA||'.';
		select tipo.classif_tipo_id into strict tipologiaTipoId
    	from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code=TIPOLOGIA
		and   tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));

   	    -- categoriaTipoId
        strMessaggio:='Lettura categoria_code_tipo_id  '||CATEGORIA||'.';
		select tipo.classif_tipo_id into strict categoriaTipoId
    	from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code=CATEGORIA
		and   tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));


		-- famTitEntTipoCategId
		-- FAM_TIT_ENT_TIPCATEG='Entrata - TitoliTipologieCategorie'
        strMessaggio:='Lettura fam_tit_ent_tipcategorie_code_tipo_id  '||FAM_TIT_ENT_TIPCATEG||'.';
		select fam.classif_fam_tree_id into strict famTitEntTipoCategId
        from siac_t_class_fam_tree fam
        where fam.ente_proprietario_id=enteProprietarioId
        and   fam.class_fam_code=FAM_TIT_ENT_TIPCATEG
        and   fam.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',fam.validita_inizio)
  		and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(fam.validita_fine,dataElaborazione));

        -- flussoElabMifTipoId
        strMessaggio:='Lettura tipo flusso MIF  Code Id '||MANDMIF_TIPO||'.';
        select tipo.flusso_elab_mif_tipo_id, tipo.flusso_elab_mif_nome_file, tipo.flusso_elab_mif_tipo_dec
               into strict flussoElabMifTipoId,flussoElabMifTipoNomeFile,flussoElabMifTipoDec
        from mif_d_flusso_elaborato_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
   		and   tipo.flusso_elab_mif_tipo_code=MANDMIF_TIPO
        and   tipo.data_cancellazione is null
        and   tipo.validita_fine is null;

        -- raise notice 'flussoElabMifTipoId %',flussoElabMifTipoId;


        strMessaggio:='Lettura flusso struttura SIOPE PLUS  per tipo '||MANDMIF_TIPO||'.';
        for mifElabRec IN
        (select m.*
         from mif_d_flusso_elaborato m
         where m.flusso_elab_mif_tipo_id=flussoElabMifTipoId
         and   m.flusso_elab_mif_elab=true
         order by m.flusso_elab_mif_ordine_elab
        )
        loop
        	mifAFlussoElabTypeRec.flussoElabMifId :=mifElabRec.flusso_elab_mif_id;
            mifAFlussoElabTypeRec.flussoElabMifAttivo :=mifElabRec.flusso_elab_mif_attivo;
            mifAFlussoElabTypeRec.flussoElabMifDef :=mifElabRec.flusso_elab_mif_default;
            mifAFlussoElabTypeRec.flussoElabMifElab :=mifElabRec.flusso_elab_mif_elab;
            mifAFlussoElabTypeRec.flussoElabMifParam :=mifElabRec.flusso_elab_mif_param;

            mifAFlussoElabTypeRec.flusso_elab_mif_ordine_elab :=mifElabRec.flusso_elab_mif_ordine_elab;

            mifAFlussoElabTypeRec.flusso_elab_mif_ordine :=mifElabRec.flusso_elab_mif_ordine;

            mifAFlussoElabTypeRec.flusso_elab_mif_code :=mifElabRec.flusso_elab_mif_code;
            mifAFlussoElabTypeRec.flusso_elab_mif_campo :=mifElabRec.flusso_elab_mif_campo;

            mifFlussoElabMifArr[mifElabRec.flusso_elab_mif_ordine_elab]:=mifAFlussoElabTypeRec;

        end loop;


        -- enteProprietarioRec
        strMessaggio:='Lettura dati ente proprietario per flusso SIOPE PLUS tipo '||MANDMIF_TIPO||'.';
        select * into strict enteProprietarioRec
        from siac_t_ente_proprietario ente
        where ente.ente_proprietario_id=enteProprietarioId
        and   ente.data_cancellazione is null
        and   ente.validita_fine is null;

        -- soggettoEnteId
        strMessaggio:='Lettura indirizzo ente proprietario [siac_r_soggetto_ente_proprietario] per flusso SIOPE PLUS tipo '||MANDMIF_TIPO||'.';
        select ente.soggetto_id into soggettoEnteId
        from siac_r_soggetto_ente_proprietario ente
        where ente.ente_proprietario_id=enteProprietarioId
        and   ente.data_cancellazione is null
        and   ente.validita_fine is null;

        if soggettoEnteId is not null then
            strMessaggio:='Lettura indirizzo ente proprietario [siac_t_indirizzo_soggetto] per flusso SIOPE PLUS tipo '||MANDMIF_TIPO||'.';

        	select viaTipo.via_tipo_code||' '||indir.toponimo||' '||indir.numero_civico,
        		   com.comune_desc
                   into indirizzoEnte,localitaEnte
            from siac_t_indirizzo_soggetto indir,
                 siac_t_comune com,
                 siac_d_via_tipo viaTipo
            where indir.soggetto_id=soggettoEnteId
            and   indir.principale='S'
            and   indir.data_cancellazione is null
            and   indir.validita_fine is null
            and   com.comune_id=indir.comune_id
            and   com.data_cancellazione is null
            and   com.validita_fine is null
            and   viaTipo.via_tipo_id=indir.via_tipo_id
            and   viaTipo.data_cancellazione is null
	   		and   date_trunc('day',dataElaborazione)>=date_trunc('day',viaTipo.validita_inizio)
 			and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(viaTipo.validita_fine,dataElaborazione))
            order by indir.indirizzo_id;
        end if;


        -- calcolo progressivo "distinta" per flusso REVMIF
	    -- calcolo su progressi di flussoElabMifDistOilId flussoOIL univoco per tipo flusso
        strMessaggio:='Lettura progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_'||MANDMIF_TIPO||'_'||annoBilancio||'  per flusso SIOPE PLUS tipo '||MANDMIF_TIPO||'.';
        codResult:=null;

        select prog.prog_value into flussoElabMifDistOilRetId
          from siac_t_progressivo prog
        where prog.ente_proprietario_id=enteProprietarioId
        and   prog.prog_key='oil_'||MANDMIF_TIPO||'_'||annoBilancio
        and   prog.ambito_id=ambitoFinId
        and   prog.data_cancellazione is null
        and   prog.validita_fine is null;

        if flussoElabMifDistOilRetId is null then
			strMessaggio:='Inserimento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        	insert into siac_t_progressivo
            (prog_key,
             prog_value,
			 ambito_id,
		     validita_inizio,
			 ente_proprietario_id,
			 login_operazione
            )
            values
            ('oil_'||MANDMIF_TIPO||'_'||annoBilancio,1,ambitoFinId,now(),enteProprietarioId,loginOperazione)
            returning prog_id into codResult;

            if codResult is null then
            	RAISE EXCEPTION ' Progressivo non inserito.';
            else
            	flussoElabMifDistOilRetId:=0;
            end if;
        end if;

        if flussoElabMifDistOilRetId is not null then
	        flussoElabMifDistOilRetId:=flussoElabMifDistOilRetId+1;
        end if;


	    -- calcolo su progressi di flussoElabMifOilId flussoOIL univoco
        strMessaggio:='Lettura progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        codResult:=null;
        select prog.prog_value into flussoElabMifOilId
        from siac_t_progressivo prog
        where prog.ente_proprietario_id=enteProprietarioId
        and   prog.prog_key='oil_out_'||annoBilancio
        and   prog.ambito_id=ambitoFinId
        and   prog.data_cancellazione is null
        and   prog.validita_fine is null;

        if flussoElabMifOilId is null then
			strMessaggio:='Inserimento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        	insert into siac_t_progressivo
            (prog_key,
             prog_value,
			 ambito_id,
		     validita_inizio,
			 ente_proprietario_id,
			 login_operazione
            )
            values
            ('oil_out_'||annoBilancio,1,ambitoFinId,now(),enteProprietarioId,loginOperazione)
            returning prog_id into codResult;

            if codResult is null then
            	RAISE EXCEPTION ' Progressivo non inserito.';
            else
            	flussoElabMifOilId:=0;
            end if;
        end if;

        if flussoElabMifOilId is not null then
	        flussoElabMifOilId:=flussoElabMifOilId+1;
        end if;

        exception
		when no_data_found then
			RAISE EXCEPTION ' Non presente in archivio';
        when TOO_MANY_ROWS THEN
            RAISE EXCEPTION ' Diverse righe presenti in archivio.';
		when others  THEN
			RAISE EXCEPTION ' %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 500);
    end;




    --- popolamento mif_t_ordinativo_entrata_id


    -- ordinativi emessi o emessi/spostati non ancora mai trasmessi codice_funzione='I'
    strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_entrata_id].Codice funzione='||FUNZIONE_CODE_I||'.';

    insert into mif_t_ordinativo_entrata_id
    (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
     mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
     mif_ord_soggetto_id, mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
     mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_notetes_id,mif_ord_dist_id,mif_ord_desc,
     mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
     mif_ord_codbollo_id,
     mif_ord_login_creazione,mif_ord_login_modifica,
     ente_proprietario_id, login_operazione)
    (
     with
     ritrasm as
     (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	  from mif_t_ordinativo_ritrasmesso r
	  where mifOrdRitrasmElabId is not null
	  and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	  and   r.ente_proprietario_id=enteProprietarioId
	  and   r.data_cancellazione is null),
     ordinativi as
     (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_I mif_ord_codice_funzione,
             bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
             ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
             extract('year' from ord.ord_emissione_data)||'-'||
             lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
             lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,0 mif_ord_ord_anno_movg,
             0 mif_ord_soggetto_id,0 mif_ord_subord_id,elem.elem_id mif_ord_elem_id,
             0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_atto_amm_id,ord.contotes_id mif_ord_contotes_id,
             ord.notetes_id mif_ord_notetes_id,ord.dist_id mif_ord_dist_id, ord.ord_desc mif_ord_desc ,
             ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
             ord.codbollo_id mif_ord_codbollo_id,
             ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
             enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
      from siac_t_ordinativo ord,siac_r_ordinativo_stato ord_stato,siac_t_bil bil, siac_t_periodo per,siac_r_ordinativo_bil_elem elem
      where  bil.ente_proprietario_id=enteProprietarioId
        and  per.periodo_id=bil.periodo_id
        and  per.anno::integer <=annoBilancio::integer
         and  ord.bil_id=bil.bil_id
         and  ord.ord_tipo_id=ordTipoCodeId
         and  ord_stato.ord_id=ord.ord_id
         and  ord_stato.data_cancellazione is null
	   	 and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
		 and  ord_stato.validita_fine is null
         and  ord_stato.ord_stato_id=ordStatoCodeIId
         and  ord.ord_trasm_oil_data is null
         and  ord.ord_emissione_data<=dataElaborazione
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  not exists (select 1 from siac_r_ordinativo rord
                          where rord.ord_id_a=ord.ord_id
                          and   rord.data_cancellazione is null
                          and   rord.validita_fine is null
			              and   rord.relaz_tipo_id=ordRelazCodeTipoId)
      )
      select   o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
               o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
               o.mif_ord_soggetto_id, o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_notetes_id,o.mif_ord_dist_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.mif_ord_codbollo_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
      from ordinativi o
	  where mifOrdRitrasmElabId is null
	     or (mifOrdRitrasmElabId is not null and exists
            (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
      );


      -- ordinativi emessi o emessi/spostati non ancora mai trasmessi, sostituzione di altro ordinativo codice_funzione='S'
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_entrata_id].Codice funzione='||FUNZIONE_CODE_S||'.';

      insert into mif_t_ordinativo_entrata_id
	  (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_notetes_id,mif_ord_dist_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_codbollo_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
	  (
	   with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_S mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
               ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,
               0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_subord_id,
               elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.notetes_id mif_ord_notetes_id,ord.dist_id mif_ord_dist_id,
               ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.codbollo_id mif_ord_codbollo_id,
               ord.login_creazione mif_ord_login_creazione, ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
  	    from siac_t_ordinativo ord,siac_r_ordinativo_stato ord_stato,
             siac_t_bil bil, siac_t_periodo per,
             siac_r_ordinativo_bil_elem elem,siac_r_ordinativo rord
  	    where  bil.ente_proprietario_id=enteProprietarioId
   		  and  per.periodo_id=bil.periodo_id
    	  and  per.anno::integer <=annoBilancio::integer
    	  and  ord.bil_id=bil.bil_id
    	  and  ord.ord_tipo_id=ordTipoCodeId
    	  and  ord_stato.ord_id=ord.ord_id
    	  and  ord_stato.data_cancellazione is null
	   	  and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
          and  ord_stato.validita_fine is null
    	  and  ord_stato.ord_stato_id=ordStatoCodeIId
	      and  ord.ord_trasm_oil_data is null
    	  and  ord.ord_emissione_data<=dataElaborazione
    	  and  elem.ord_id=ord.ord_id
    	  and  elem.data_cancellazione is null
          and  elem.validita_fine is null
          and  rord.ord_id_a=ord.ord_id
          and  rord.relaz_tipo_id=ordRelazCodeTipoId
          and  rord.data_cancellazione is null
          and  rord.validita_fine is null
        )
        select o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
               o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
               o.mif_ord_soggetto_id, o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_notetes_id,o.mif_ord_dist_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.mif_ord_codbollo_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
        from ordinativi o
	    where mifOrdRitrasmElabId is null
	     or (mifOrdRitrasmElabId is not null and exists
            (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
      );

      -- ordinativi emessi e annullati mai trasmessi codice_funzione='N'
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_entrata_id].Codice funzione='||FUNZIONE_CODE_N||'.';

	  insert into mif_t_ordinativo_entrata_id
	  (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_notetes_id,mif_ord_dist_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_codbollo_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
	  (
	   with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_N mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
      	 	   ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,
               0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_subord_id,elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.notetes_id mif_ord_notetes_id,ord.dist_id mif_ord_dist_id,
               ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.codbollo_id mif_ord_codbollo_id,
               ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
  	    from siac_t_ordinativo ord, siac_r_ordinativo_stato ord_stato,
             siac_t_bil bil, siac_t_periodo per,
             siac_r_ordinativo_bil_elem elem
        where  bil.ente_proprietario_id=enteProprietarioId
         and  per.periodo_id=bil.periodo_id
         and  per.anno::integer <=annoBilancio::integer
         and  ord.bil_id=bil.bil_id
         and  ord.ord_tipo_id=ordTipoCodeId
         and  ord_stato.ord_id=ord.ord_id
         and  ord_stato.validita_inizio<=dataElaborazione -- questa e'' la data di annullamento
         and  ord.ord_emissione_data<=dataElaborazione
         and  ord_stato.data_cancellazione is null
         and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
   		 and  ord_stato.validita_fine is null
         and  ord_stato.ord_stato_id=ordStatoCodeAId
         and  ord.ord_trasm_oil_data is null
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  elem.validita_fine is null
        )
        select o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
               o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
               o.mif_ord_soggetto_id, o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_notetes_id,o.mif_ord_dist_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.mif_ord_codbollo_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
        from ordinativi o
	    where mifOrdRitrasmElabId is null
	     or (mifOrdRitrasmElabId is not null and exists
            (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
	   );

      -- ordinativi emessi tramessi e poi annullati, anche dopo spostamento  codice_funzione='A'
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_entrata_id].Codice funzione='||FUNZIONE_CODE_A||'.';

      insert into mif_t_ordinativo_entrata_id
      (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_notetes_id,mif_ord_dist_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_codbollo_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
      (
	   with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_A mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
               ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_subord_id,elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id, ord.notetes_id mif_ord_notetes_id,ord.dist_id mif_ord_dist_id,
               ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.codbollo_id mif_ord_codbollo_id,
               ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
        from siac_t_ordinativo ord,siac_r_ordinativo_stato ord_stato,
             siac_t_bil bil, siac_t_periodo per,
             siac_r_ordinativo_bil_elem elem
        where  bil.ente_proprietario_id=enteProprietarioId
         and  per.periodo_id=bil.periodo_id
         and  per.anno::integer <=annoBilancio::integer
         and  ord.bil_id=bil.bil_id
         and  ord.ord_tipo_id=ordTipoCodeId
   		 and  ord_stato.ord_id=ord.ord_id
  		 and  ord.ord_emissione_data<=dataElaborazione
         and  ord_stato.validita_inizio<=dataElaborazione  -- questa e'' la data di annullamento
  		 and  ord.ord_trasm_oil_data is not null
 		 and  ord.ord_trasm_oil_data<ord_stato.validita_inizio
         and  ord_stato.data_cancellazione is null
         and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
         and  ord_stato.validita_fine is null -- SofiaData
         and  ord_stato.ord_stato_id=ordStatoCodeAId
         and  ( ord.ord_spostamento_data is null or ord.ord_spostamento_data<ord_stato.validita_inizio)
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  elem.validita_fine is null
        )
        select o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
               o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
               o.mif_ord_soggetto_id, o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_notetes_id,o.mif_ord_dist_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.mif_ord_codbollo_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
        from ordinativi o
	    where mifOrdRitrasmElabId is null
	     or (mifOrdRitrasmElabId is not null and exists
            (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
       );

      -- ordinativi emessi , trasmessi  e poi spostati codice_funzione='VB' ( mai annullati )
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_entrata_id].Codice funzione='||FUNZIONE_CODE_VB||'.';

      insert into mif_t_ordinativo_entrata_id
      (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil ,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_notetes_id,mif_ord_dist_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_codbollo_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
      (
	   with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_VB mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
               ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_subord_id,elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.notetes_id mif_ord_notetes_id,ord.dist_id mif_ord_dist_id,
               ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.codbollo_id mif_ord_codbollo_id,
               ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
        from siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per, siac_r_ordinativo_bil_elem elem
        where  bil.ente_proprietario_id=enteProprietarioId
         and  per.periodo_id=bil.periodo_id
         and  per.anno::integer <=annoBilancio::integer
         and  ord.bil_id=bil.bil_id
         and  ord.ord_tipo_id=ordTipoCodeId
         and  ord.ord_emissione_data<=dataElaborazione
         and  ord.ord_trasm_oil_data is not null
         and  ord.ord_spostamento_data is not null
         and  ord.ord_trasm_oil_data<ord.ord_spostamento_data
         and  ord.ord_spostamento_data<=dataElaborazione
         and  not exists (select 1 from siac_r_ordinativo_stato ord_stato
  				          where  ord_stato.ord_id=ord.ord_id
					        and  ord_stato.ord_stato_id=ordStatoCodeAId
                            and  ord_stato.data_cancellazione is null)
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  elem.validita_fine is null
        )
		select o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
               o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
               o.mif_ord_soggetto_id, o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_notetes_id,o.mif_ord_dist_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.mif_ord_codbollo_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
        from ordinativi o
	    where mifOrdRitrasmElabId is null
	     or (mifOrdRitrasmElabId is not null and exists
            (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
       );

      -- aggiornamento mif_t_ordinativo_entrata_id per id


      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per soggetto_id.';
      -- soggetto_id
      update mif_t_ordinativo_entrata_id m
      set mif_ord_soggetto_id = (select s.soggetto_id from siac_r_ordinativo_soggetto s
                                 where s.ord_id=m.mif_ord_ord_id
                                   and s.data_cancellazione is null
                                   and s.validita_fine is null);

      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per subord_id.';

      -- subord_id
      update mif_t_ordinativo_entrata_id m
      set mif_ord_subord_id =
                             (select s.ord_ts_id from siac_t_ordinativo_ts s
                               where s.ord_id=m.mif_ord_ord_id
                                 and s.data_cancellazione is null
                                 and s.validita_fine is null
                               order by s.ord_ts_id
                               limit 1);



     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per movgest_ts_id.';

     -- movgest_ts_id
     update mif_t_ordinativo_entrata_id m
     set mif_ord_movgest_ts_id = (select ts.movgest_ts_id from siac_t_ordinativo_ts s, siac_r_ordinativo_ts_movgest_ts ts
	                              where s.ord_id=m.mif_ord_ord_id
                                  and   ts.ord_ts_id=s.ord_ts_id
                                  and   s.data_cancellazione is null
                                  and   s.validita_fine is null
                                  and   ts.data_cancellazione is null
                                  and   ts.validita_fine is null
                                  order by s.ord_ts_id
                                  limit 1);


     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per movgest_id.';

     -- movgest_id
     update mif_t_ordinativo_entrata_id m
     set mif_ord_movgest_id = (select s.movgest_id from siac_t_movgest_ts s
                               where  s.movgest_ts_id = m.mif_ord_movgest_ts_id
                               and s.data_cancellazione is null
                               and s.validita_fine is null);


     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per movgest_id.';

     -- movgest_anno
     update mif_t_ordinativo_entrata_id m
     set mif_ord_ord_anno_movg = (select s.movgest_anno from siac_t_movgest s
                              	  where  s.movgest_id = m.mif_ord_movgest_id
                             	  and s.data_cancellazione is null
                                  and s.validita_fine is null);


     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per attoamm_id.';

    -- attoamm_id
    update mif_t_ordinativo_entrata_id m
    set mif_ord_atto_amm_id = (select s.attoamm_id from siac_r_ordinativo_atto_amm s
                                where s.ord_id = m.mif_ord_ord_id
                                  and s.data_cancellazione is null
                                  and s.validita_fine is null);


    strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per attoamm_id movgest_ts.';
	-- attoamm_movgest_ts_id
    update mif_t_ordinativo_entrata_id m
    set mif_ord_atto_amm_movg_id = (select s.attoamm_id from siac_r_movgest_ts_atto_amm s
                                    where s.movgest_ts_id = m.mif_ord_movgest_ts_id
                                    and s.data_cancellazione is null
                                    and s.validita_fine is null);


	-- mif_ord_tipologia_id
    -- mif_ord_tipologia_code
    -- mif_ord_tipologia_desc
	strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per mif_ord_tipologia_id mif_ord_tipologia_code mif_ord_tipologia_desc.';
	update mif_t_ordinativo_entrata_id m
    set (mif_ord_tipologia_id, mif_ord_tipologia_code,mif_ord_tipologia_desc) = (cp.classif_id,cp.classif_code,cp.classif_desc)
    from  siac_r_bil_elem_class classElem, siac_t_class cf, siac_r_class_fam_tree r, siac_t_class cp
	where classElem.elem_id= m.mif_ord_elem_id
	and   cf.classif_id=classElem.classif_id
	and   cf.data_cancellazione is null
	and   cf.classif_tipo_id= categoriaTipoid -- categoria
	and   r.classif_id=cf.classif_id
	and   r.classif_id_padre is not null
	and   r.classif_fam_tree_id=famTitEntTipoCategId -- famiglia
	and   r.data_cancellazione is null
	and   r.validita_fine is null
	and   classElem.data_cancellazione is null
	and   classElem.validita_fine is null
	and   cp.classif_id=r.classif_id_padre
	and   cp.data_cancellazione is null
	and   cp.classif_tipo_id=tipologiaTipoid; --tipologia

    strMessaggio:='Verifica esistenza ordinativi di entrata da trasmettere.';
    codResult:=null;

    select 1 into codResult
    from mif_t_ordinativo_entrata_id where ente_proprietario_id=enteProprietarioId;

    if codResult is null then
      codResult:=-12;
      RAISE EXCEPTION ' Nessun ordinativo di entrata da trasmettere.';
    end if;




   -- <sospesi>
   -- <sospeso>
   -- <numero_provvisorio>
   -- <importo_provvisorio>
   flussoElabMifElabRec:=null;
   flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_NUM_SOSPESO];

   strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   if flussoElabMifElabRec.flussoElabMifId is null then
  	  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
   end if;
   raise notice 'numero_provvisorio FLUSSO_MIF_ELAB_NUM_SOSPESO=% strMessaggio=%',FLUSSO_MIF_ELAB_NUM_SOSPESO,strMessaggio;

   if flussoElabMifElabRec.flussoElabMifAttivo=true then
    	if flussoElabMifElabRec.flussoElabMifElab=true then
			isRicevutaAttivo:=true;
        else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
   		end if;
   end if;


   flussoElabMifElabRec:=null;
   mifCountRec:=FLUSSO_MIF_ELAB_FATTURE;
   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
   strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
   if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
   end if;
   if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	if flussoElabMifElabRec.flussoElabMifElab=true then
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
 		    numeroDocs:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            tipoDocs  :=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
            tipoGruppoDocs  :=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
            if numeroDocs is not null and numeroDocs!='' and
               tipoDocs is not null and tipoDocs!='' and
               tipoGruppoDocs is not null and tipoGruppoDocs!='' then
                tipoDocs:=tipoDocs||'|'||tipoGruppoDocs;
            	isGestioneFatture:=true;
            end if;
		end if;
    else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
    end if;
   end if;

   if isGestioneFatture=true then

    flussoElabMifElabRec:=null;
    mifCountRec:=FLUSSO_MIF_ELAB_FATT_CODFISC;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	 if flussoElabMifElabRec.flussoElabMifElab=true then
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
 		    docAnalogico:=flussoElabMifElabRec.flussoElabMifParam;
		end if;
     else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
    end if;

   end if;

   if isGestioneFatture=true then
    flussoElabMifElabRec:=null;
    mifCountRec:=FLUSSO_MIF_ELAB_FATT_DATASCAD_PAG;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	 if flussoElabMifElabRec.flussoElabMifElab=true then
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
            attrCodeDataScad:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
		end if;
     else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
    end if;

   end if;

   if isGestioneFatture=true then

    flussoElabMifElabRec:=null;
    mifCountRec:=FLUSSO_MIF_ELAB_FATT_NATURA_PAG;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	 if flussoElabMifElabRec.flussoElabMifElab=true then
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
            /* 23.02.2018 Sofia JIRA siac-5849
            titoloCorrente:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            descriTitoloCorrente:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
            titoloCapitale:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
            descriTitoloCapitale:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
            macroAggrTipoCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5));
            if macroAggrTipoCode is not null then
            	strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'. Lettura identificato classificatore tipo='||macroAggrTipoCode||'.';
            	select tipo.classif_tipo_id into macroAggrTipoCodeId
                from siac_d_class_tipo tipo
                where tipo.ente_proprietario_id=enteProprietarioId
                and   tipo.classif_tipo_code=macroAggrTipoCode
                and   tipo.data_cancellazione is null
                and   tipo.validita_fine is null;

            end if;*/

            -- 23.02.2018 Sofia JIRA siac-5849
            macroAggrTipoCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            if macroAggrTipoCode is not null then
            	strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'. Lettura identificato classificatore tipo='||macroAggrTipoCode||'.';
            	select tipo.classif_tipo_id into macroAggrTipoCodeId
                from siac_d_class_tipo tipo
                where tipo.ente_proprietario_id=enteProprietarioId
                and   tipo.classif_tipo_code=macroAggrTipoCode
                and   tipo.data_cancellazione is null
                and   tipo.validita_fine is null;

            end if;
            -- 23.02.2018 Sofia JIRA siac-5849
            famMacroTitCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
            if famMacroTitCode is not null then
	            strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'. Lettura identificato famiglia tipo='||famMacroTitCode||'.';
	            select tree.classif_fam_tree_id into famMacroTitCodeId
				from siac_t_class_fam_tree tree, siac_d_class_fam d
				where d.ente_proprietario_id=enteProprietarioId
				and   d.classif_fam_desc=famMacroTitCode --'Spesa - TitoliMacroaggregati'
				and   tree.classif_fam_id=d.classif_fam_id
                and   tree.data_cancellazione is null
                and   tree.validita_fine is null
                and   d.data_cancellazione is null
                and   d.validita_fine is null;

            end if;

			-- 23.02.2018 Sofia JIRA siac-5849
	        if flussoElabMifElabRec.flussoElabMifDef is not null then
        		defNaturaPag:=flussoElabMifElabRec.flussoElabMifDef;
    	    end if;

		end if;
     else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
    end if;

   end if;

    --- lettura mif_t_ordinativo_entrata_id per popolamento mif_t_ordinativo_entrata
    codResult:=null;
    strMessaggio:='Lettura ordinativi di entrata da migrare [mif_t_ordinativo_entrata_id].Inizio ciclo.';
    for mifOrdinativoIdRec IN
    (select ms.*
     from mif_t_ordinativo_entrata_id ms
     where ms.ente_proprietario_id=enteProprietarioId
     order by ms.mif_ord_anno_bil,
              ms.mif_ord_ord_numero
    )
    loop

--		raise notice 'Inizio ciclo numero_ord=%',mifOrdinativoIdRec.mif_ord_ord_numero;
		mifFlussoOrdinativoRec:=null;
		bilElemRec:=null;
        soggettoRec:=null;

        soggettoRifId:=null;

		indirizzoRec:=null;
        mifOrdSpesaId:=null;
	    mifCountRec:=1;
		isIndirizzoBenef:=true;
        bAvvioSiopeNew:=false;

        -- lettura importo ordinativo
		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura importo ordinativo di entrata per tipo flusso '||MANDMIF_TIPO||'.';

        mifFlussoOrdinativoRec.mif_ord_importo:=fnc_mif_importo_ordinativo(mifOrdinativoIdRec.mif_ord_ord_id,ordDetTsTipoId,
        										flussoElabMifTipoDec);
        if flussoElabMifTipoDec=true and
           coalesce(position('.' in mifFlussoOrdinativoRec.mif_ord_importo),0)=0 then
           mifFlussoOrdinativoRec.mif_ord_importo:=mifFlussoOrdinativoRec.mif_ord_importo||'.00';
        end if;

        -- lettura dati soggetto ordinativo
        soggettoRifId:=mifOrdinativoIdRec.mif_ord_soggetto_id;
        select * into soggettoRec
   	    from siac_t_soggetto sogg
       	where sogg.soggetto_id=soggettoRifId;

        if soggettoRec is null then
        	RAISE EXCEPTION ' Errore in lettura siac_t_soggetto [soggetto_id= %].',soggettoRifId;
        end if;


        -- lettura elemento bilancio  ordinativo
 		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura elemento bilancio ordinativo di entrata per tipo flusso '||MANDMIF_TIPO||'.';

		select * into bilElemRec
        from siac_t_bil_elem elem
        where elem.elem_id=mifOrdinativoIdRec.mif_ord_elem_id;
        if bilElemRec is null then
        	RAISE EXCEPTION ' Errore in lettura siac_t_bil_elem.';
        end if;

        -- dati testata flusso presenti come tag solo in testata
        -- valorizzati su ogni ordinativo trasmesso
        -- <testata_flusso>
		-- <codice_ABI_BT>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ABI_BT;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_abi is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_abi_bt:=enteOilRec.ente_oil_abi;
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_abi_bt:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <codice_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ENTE_IPA;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_ipa is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_ipa:=trim(both ' ' from enteOilRec.ente_oil_codice_ipa);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_ipa:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <descrizione_ente>
	    flussoElabMifElabRec:=null;
		mifCountRec:=FLUSSO_MIF_ELAB_TEST_DESC_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteProprietarioRec.ente_denominazione is not null then
            	mifFlussoOrdinativoRec.mif_ord_desc_ente:=enteProprietarioRec.ente_denominazione;
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
               	mifFlussoOrdinativoRec.mif_ord_desc_ente:=substring(flussoElabMifElabRec.flussoElabMifDef from 1 for 30);
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

	    -- <codice_istat_ente>
	    flussoElabMifElabRec:=null;
		mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ISTAT_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_istat is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_istat:=enteOilRec.ente_oil_codice_istat;
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
               	mifFlussoOrdinativoRec.mif_ord_codice_ente_istat:=substring(flussoElabMifElabRec.flussoElabMifDef from 1 for 30);
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <codice_fiscale_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_CODFISC_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteProprietarioRec.codice_fiscale is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente:=trim(both ' ' from enteProprietarioRec.codice_fiscale);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <codice_tramite_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_CODTRAMITE_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_tramite is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite:=trim(both ' ' from enteOilRec.ente_oil_codice_tramite);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <codice_tramite_BT>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_CODTRAMITE_BT;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_tramite_bt is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite_bt:=trim(both ' ' from enteOilRec.ente_oil_codice_tramite_bt);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite_bt:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <codice_ente_BT>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ENTE_BT;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_bt:=trim(both ' ' from enteOilRec.ente_oil_codice);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_bt:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <riferimento_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_RIFERIMENTO_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_riferimento is not null then
            	mifFlussoOrdinativoRec.mif_ord_riferimento_ente:=trim(both ' ' from enteOilRec.ente_oil_riferimento);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_riferimento_ente:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;
        -- </testata_flusso>

        -- <testata_esercizio>
        -- <esercizio>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_ESERCIZIO;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            mifFlussoOrdinativoRec.mif_ord_anno_esercizio:=mifOrdinativoIdRec.mif_ord_anno_bil;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;
        -- </testata_esercizio>

		-- <reversale>
        mifCountRec :=FLUSSO_MIF_ELAB_INIZIO_ORD;

	    -- <tipo_operazione>
        flussoElabMifElabRec:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        raise notice 'tipo_operazione strMessaggio=%',strMessaggio;
        if  flussoElabMifElabRec.flussoElabMifAttivo=true then
         if   flussoElabMifElabRec.flussoElabMifElab=true then
            if flussoElabMifElabRec.flussoElabMifParam is not null then
	            flussoElabMifValore:=fnc_mif_ordinativo_carico_bollo( mifOrdinativoIdRec.mif_ord_codice_funzione,flussoElabMifElabRec.flussoElabMifParam);
            else
            	flussoElabMifValore:=mifOrdinativoIdRec.mif_ord_codice_funzione;
            end if;

            if flussoElabMifValore is not null then
				mifFlussoOrdinativoRec.mif_ord_codice_funzione:=flussoElabMifValore;
            end if;

         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <numero_reversale>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if flussoElabMifTipoDec=false then
				mifFlussoOrdinativoRec.mif_ord_numero:=lpad(mifOrdinativoIdRec.mif_ord_ord_numero,NUM_SETTE,ZERO_PAD);
            else
	            mifFlussoOrdinativoRec.mif_ord_numero:=mifOrdinativoIdRec.mif_ord_ord_numero;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo non elaborabile.';
         end if;
        end if;


        -- <data_reversale>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true  then
         if  flussoElabMifElabRec.flussoElabMifElab=true then
			mifFlussoOrdinativoRec.mif_ord_data:=mifOrdinativoIdRec.mif_ord_data_emissione;
         else
            RAISE EXCEPTION ' Configurazione tag/campo non  elaborabile.';
         end if;
        end if;

		-- <importo_reversale>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
			-- calcolato inizio ciclo
            null;
         else
         	mifFlussoOrdinativoRec.mif_ord_importo:='0';
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <conto_evidenza>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            if mifOrdinativoIdRec.mif_ord_contotes_id is not null then
                 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
					   ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura conto tesoreria.';

            	select d.contotes_code into flussoElabMifValore
                from siac_d_contotesoreria d
                where d.contotes_id=mifOrdinativoIdRec.mif_ord_contotes_id;
                if flussoElabMifValore is null then
                	RAISE EXCEPTION ' Dato non presente in archivio.';
                end if;
            end if;

			if flussoElabMifValore is not null then
             mifFlussoOrdinativoRec.mif_ord_destinazione:=flussoElabMifValore;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <bilancio>
        -- <codifica_bilancio>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;
        raise notice 'codifica_bilancio strMessaggio=%',strMessaggio;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then

         		mifFlussoOrdinativoRec.mif_ord_codifica_bilancio:=
                    substring(mifOrdinativoIdRec.mif_ord_tipologia_code from 1 for 5) ;
            	mifFlussoOrdinativoRec.mif_ord_capitolo:=bilElemRec.elem_code;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


	    -- <descrizione_codifica>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            	mifFlussoOrdinativoRec.mif_ord_desc_codifica:=substring( bilElemRec.elem_desc from 1 for 30);
                mifFlussoOrdinativoRec.mif_ord_desc_codifica_bil:=substring( mifOrdinativoIdRec.mif_ord_tipologia_desc from 1 for 30);
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <gestione>
        flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if flussoElabMifElabRec.flussoElabMifDef is not null then
            	if mifOrdinativoIdRec.mif_ord_anno_bil=mifOrdinativoIdRec.mif_ord_ord_anno_movg then
	            	flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
                else
	                flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
                end if;
            	mifFlussoOrdinativoRec.mif_ord_gestione:=flussoElabMifValore;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <anno_residuo>
        flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
		  if mifOrdinativoIdRec.mif_ord_anno_bil!=mifOrdinativoIdRec.mif_ord_ord_anno_movg  then
       	 	mifFlussoOrdinativoRec.mif_ord_anno_res:=mifOrdinativoIdRec.mif_ord_ord_anno_movg;
          end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

		-- <numero_articolo>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            	mifFlussoOrdinativoRec.mif_ord_articolo:=bilElemRec.elem_code2;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <voce_economica>
        mifCountRec:=mifCountRec+1;

        -- <importo_bilancio>
        flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
           	mifFlussoOrdinativoRec.mif_ord_importo_bil:=mifFlussoOrdinativoRec.mif_ord_importo;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;
        -- </bilancio>

	    -- <informazioni_versante>

        -- <progressivo_versante>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        raise notice 'progressivo_versante strMessaggio=%',strMessaggio;

        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
           	if flussoElabMifElabRec.flussoElabMifDef is not null then
                	mifFlussoOrdinativoRec.mif_ord_progr_vers:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <importo_versante>
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
  	 	 RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	 if flussoElabMifElabRec.flussoElabMifElab=true then
     		mifFlussoOrdinativoRec.mif_ord_vers_importo:=mifFlussoOrdinativoRec.mif_ord_importo;
	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
        end if;

	    -- <tipo_riscossione>
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=null;
	    flussoElabMifValore:=null;
        flussoElabMifValoreDesc:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
           RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
            if coalesce(flussoElabMifElabRec.flussoElabMifParam,NVL_STR)!=NVL_STR and
               coalesce(flussoElabMifElabRec.flussoElabMifDef,NVL_STR)!=NVL_STR then
              if  tipoIncassoCode is null then
            	tipoIncassoCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
              end if;
              if tipoRitOrdInc is null then
	              tipoRitOrdInc:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
              end if;
              if tipoSplitOrdInc is null then
	              tipoSplitOrdInc:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
              end if;
              if tipoSubOrdInc is null then
	              tipoSubOrdInc:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
              end if;

              if tipoRitenuteInc is null then
              	tipoRitenuteInc:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5))||','||
                                 trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,6))||','||
                                 trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,7));
              end if;

			  if tipoIncassoCompensazione is null then
              	tipoIncassoCompensazione:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
              end if;
   			  if tipoIncassoRegolarizza is null then
              	tipoIncassoRegolarizza:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
              end if;

   			  if tipoIncassoCassa is null then
              	tipoIncassoCassa:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,3));
              end if;

              if tipoIncassoCode is not null and tipoIncassoCodeId is null then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura classif_tipo_id per classicatore '||tipoIncassoCode||'.';
              	select tipo.classif_tipo_id into tipoIncassoCodeId
                from siac_d_class_tipo tipo
                where tipo.ente_proprietario_id=enteProprietarioId
                and   tipo.classif_tipo_code=tipoIncassoCode
                and   tipo.data_cancellazione is null
                and   tipo.validita_fine is null;

              end if;

              if tipoIncassoCodeId is not null then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura tipoIncasso '||tipoIncassoCode||' per ordinativo.';

                flussoElabMifValore:=fnc_mif_tipo_incasso_splus
                                     ( mifOrdinativoIdRec.mif_ord_ord_id,
  									   mifFlussoOrdinativoRec.mif_ord_importo::NUMERIC,
                                       tipoRitOrdInc,
                                       tipoSplitOrdInc,
                                       tipoSubOrdInc,
                                       tipoRitenuteInc,
 									   tipoIncassoCodeId,
                                       tipoIncassoCompensazione,
                                       tipoIncassoRegolarizza,
                                       tipoIncassoCassa,
                                       dataElaborazione,
                                       dataFineVal,
                                       enteProprietarioId
                                     );
              end if;

		     if flussoElabMifValore is not null then
	           mifFlussoOrdinativoRec.mif_ord_vers_tipo_riscos:=flussoElabMifValore;
             end if;
           end if;
          else
          	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
        end if;

	    -- <numero_ccp>
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=null;
	    flussoElabMifValore:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
           RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
          	if flussoElabMifElabRec.flussoElabMifParam is not null and
               mifFlussoOrdinativoRec.mif_ord_vers_tipo_riscos is not null then
               if mifFlussoOrdinativoRec.mif_ord_vers_tipo_riscos=
                  trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1)) then
                  if tipoContoCCPCode is null then
                  	tipoContoCCPCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                  end if;
                  if tipoContoCCPCodeId is null then
                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura identificativo classificatore tipo='||tipoContoCCPCode||'.';
                  	select tipo.classif_tipo_id into tipoContoCCPCodeId
                    from siac_d_class_tipo tipo
                    where tipo.ente_proprietario_id=enteProprietarioId
                    and   tipo.classif_tipo_code=tipoContoCCPCode
                    and   tipo.data_cancellazione is null;
                  end if;

                  if tipoContoCCPCodeId is not null then
                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore classificatore tipo='||tipoContoCCPCode||'.';
                  	select c.classif_code into flussoElabMifValore
                    from siac_r_ordinativo_class r, siac_t_class c
                    where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   c.classif_id=r.classif_id
                    and   c.classif_tipo_id=tipoContoCCPCodeId
                    and   r.data_cancellazione is null
                    and   r.validita_fine is null
                    and   c.data_cancellazione is null;
                  end if;
               end if;
               if flussoElabMifValore is not null then
               	mifFlussoOrdinativoRec.mif_ord_vers_cc_postale:=flussoElabMifValore;
               end if;
            end if;
           else
          	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
        end if;

		-- <tipo_entrata>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifValore:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
			if coalesce(flussoElabMifElabRec.flussoElabMifDef,NVL_STR)!=NVL_STR then
              if coalesce(flussoElabMifElabRec.flussoElabMifParam,NVL_STR)!=NVL_STR then
                   if tipoClassFruttifero is null then
                    	tipoClassFruttifero:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                   end if;

                   if tipoClassFruttifero is not null and valFruttifero is null then
	                   valFruttifero:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                       valFruttiferoStr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                       valFruttiferoStrAltro:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
                   end if;


                   if tipoClassFruttifero is not null and
                      valFruttifero is not null and
                      valFruttiferoStr is not null and
                      valFruttiferoStrAltro is not null and
                      tipoClassFruttiferoId is null then

                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura classifTipoCodeId '||tipoClassFruttifero||'.';
                   	select tipo.classif_tipo_id into tipoClassFruttiferoId
                    from siac_d_class_tipo tipo
                    where tipo.ente_proprietario_id=enteProprietarioId
                    and   tipo.classif_tipo_code=tipoClassFruttifero
                    and   tipo.data_cancellazione is null
                    and   tipo.validita_fine is null;

                   end if;
                   if tipoClassFruttiferoId is not null and
                      valFruttifero is not null and
                      valFruttiferoStr is not null and
                      valFruttiferoStrAltro is not null and
                      valFruttiferoId is null then
                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura classidId '||tipoClassFruttifero||' [siac_r_ordinativo_class].';


                   	select c.classif_code into flussoElabMifValore
                    from siac_r_ordinativo_class r, siac_t_class c
                    where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
	                and   c.classif_id=r.classif_id
                    and   c.classif_tipo_id=tipoClassFruttiferoId
                    and   r.data_cancellazione is null
                    and   r.validita_fine is null
                    and   c.data_cancellazione is null
                    order by r.ord_classif_id limit 1;

                    if flussoElabMifValore is not null then
                    	if flussoElabMifValore=valFruttifero THEN
                        	flussoElabMifValore=valFruttiferoStr;
                        else
                          flussoElabMifValore=valFruttiferoStrAltro;
                        end if;
                    end if;
                   end if;
				 end if; -- param


	             if flussoElabMifValore is null and
     	            mifOrdinativoIdRec.mif_ord_contotes_id is not null and
        	        mifOrdinativoIdRec.mif_ord_contotes_id!=0 then

    	            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
        	               ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
            	           ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                	       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
	                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
    	                   ||' mifCountRec='||mifCountRec
        	               ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per conto corrente tesoreria [mif_r_conto_tesoreria_fruttifero].';
	                -- 16.02.2018 Sofia siac-5874
                    select mif.fruttifero_oi into flussoElabMifValore
    	            from mif_r_conto_tesoreria_fruttifero mif
	                where mif.ente_proprietario_id=enteProprietarioId
    	            and   mif.contotes_id=mifOrdinativoIdRec.mif_ord_contotes_id
	                and   mif.validita_fine is null
    	            and   mif.data_cancellazione is null;


	             end if;


                 if flussoElabMifValore is null then
                   	flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
                 end if;

                 mifFlussoOrdinativoRec.mif_ord_bci_tipo_entrata:=flussoElabMifValore;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


		-- <destinazione>
        flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
		   if flussoElabMifElabRec.flussoElabMifParam is not null then

           	if classVincolatoCode is null then
            	classVincolatoCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            end if;

            if classVincolatoCodeId is null and classVincolatoCode is not null then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura identificativo classVincolatoCode='||classVincolatoCode||'.';

                select tipo.classif_tipo_id into strict classVincolatoCodeId
    		    from siac_d_class_tipo tipo
		        where tipo.ente_proprietario_id=enteProprietarioId
        		and   tipo.classif_tipo_code=classVincolatoCode
		        and   tipo.data_cancellazione is null
                and   tipo.validita_fine is null;
            end if;

            if classVincolatoCodeId is not null then
	            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore classVincolatoCode='||classVincolatoCode||'.';


                 select c.classif_desc into flussoElabMifValore
                 from siac_r_ordinativo_class r, siac_t_class c
                 where r.ord_id=  mifOrdinativoIdRec.mif_ord_ord_id
                 and   c.classif_id=r.classif_id
                 and   c.classif_tipo_id=classVincolatoCodeId
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
                 and   c.data_cancellazione is null;
            end if;
           end if;

		   if flussoElabMifValore is null and
    	 	  mifOrdinativoIdRec.mif_ord_contotes_id is not null and
        	  mifOrdinativoIdRec.mif_ord_contotes_id!=0 then

		      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
    		                   ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
        		               ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
            		           ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                		       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                    		   ||' mifCountRec='||mifCountRec
	                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per conto corrente tesoreria [mif_r_conto_tesoreria_vincolato].';

			  select mif.vincolato into flussoElabMifValore
    	      from mif_r_conto_tesoreria_vincolato mif
	    	  where mif.ente_proprietario_id=enteProprietarioId
    	      and   mif.contotes_id=mifOrdinativoIdRec.mif_ord_contotes_id
	          and   mif.validita_fine is null
		      and   mif.data_cancellazione is null;
	       end if;

		   if flussoElabMifValore is null and
           	flussoElabMifElabRec.flussoElabMifDef is not null then
            flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
           end if;

           if flussoElabMifValore is not null then
           	mifFlussoOrdinativoRec.mif_ord_vers_cod_riscos:=flussoElabMifValore;
           end if;

         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <classificazione>
        -- <codice_cge>
        flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        flussoElabMifValoreDesc:=null;
        codiceCge:=null;
        descCge:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;
        raise notice 'codice_cge strMessaggio=%',strMessaggio;

        if flussoElabMifElabRec.flussoElabMifAttivo=true  then
         if flussoElabMifElabRec.flussoElabMifElab=true  then
         		if flussoElabMifElabRec.flussoElabMifParam is not null  then
                	if siopeCodeTipo is null and flussoElabMifElabRec.flussoElabMifParam is not null then
                        siopeCodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
					if siopeDef is null and flussoElabMifElabRec.flussoElabMifParam is not null then
                        siopeDef:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;

                    if coalesce(dataAvvioSiopeNew,NVL_STR)=NVL_STR and
	                  flussoElabMifElabRec.flussoElabMifParam is not null then
    	                	dataAvvioSiopeNew:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
        	        end if;

            	    if coalesce(dataAvvioSiopeNew,NVL_STR)!=NVL_STR and codiceFinVTbr is null then
                	  	codiceFinVTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
	                end if;

            	    if coalesce(dataAvvioSiopeNew,NVL_STR)!=NVL_STR then
                	  	if dataAvvioSiopeNew::timestamp<=date_trunc('DAY',mifOrdinativoIdRec.mif_ord_data_emissione::timestamp) -- data emissione ordinativo
                    	then
    	                	bAvvioSiopeNew:=true;
	                    end if;
    	            end if;

                    if  bAvvioSiopeNew=true then
                     -- lettura da PDC_V
                  	 if codiceFinVTbr is not null and codiceFinVTipoTbrId is null then --1
						-- codiceFinVTipoTbrId
                        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                     		  ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                     		  ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                    		  ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
		                      ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
		                      ||' mifCountRec='||mifCountRec
	                          ||' tipo flusso '||MANDMIF_TIPO||'.Lettura id class tipo='||codiceFinVTbr||'.';
			   		    select tipo.classif_tipo_id into strict codiceFinVTipoTbrId
				    	from siac_d_class_tipo tipo
						where tipo.ente_proprietario_id=enteProprietarioId
						and   tipo.classif_tipo_code=codiceFinVTbr
						and   tipo.data_cancellazione is null
						and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
						and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));
                     end if; --1

                     if codiceFinVTipoTbrId is not null then --2
      		 		  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura piano_conti_fin_V_code '||codiceFinVTbr||' [siac_r_ordinativo_class] .';
		    		  select replace(substring(class.classif_code,2),'.','') , class.classif_desc
                       into flussoElabMifValore,flussoElabMifValoreDesc
			  		  from siac_r_ordinativo_class r, siac_t_class class
	       		      where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
	      		      and   class.classif_id=r.classif_id
 		              and   class.classif_tipo_id=codiceFinVTipoTbrId
		 	          and   r.data_cancellazione is null
				      and   r.validita_fine is NULL
	  		          and   class.data_cancellazione is null;

			 		  if flussoElabMifValore is null then --3
		               strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura piano_conti_fin_V_code '||codiceFinVTbr||' [siac_r_movgest_class].';

             		   select replace(substring(class.classif_code,2),'.','') , class.classif_desc
                    	into flussoElabMifValore,flussoElabMifValoreDesc
		    	       from siac_r_movgest_class rclass, siac_t_class class
		               where rclass.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
    		           and   rclass.data_cancellazione is null
        		       and   rclass.validita_fine is null
            		   and   class.classif_id=rclass.classif_id
		               and   class.classif_tipo_id=codiceFinVTipoTbrId
    		           and   class.data_cancellazione is null
		               order by rclass.movgest_classif_id
    		           limit 1;
        	           end if; --3
                      end if;--2
                    else
                	 if siopeCodeTipoId is null then --1
                    	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                     		  ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                     		  ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                    		  ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
		                      ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
		                      ||' mifCountRec='||mifCountRec
	                          ||' tipo flusso '||MANDMIF_TIPO||'.Lettura id class tipo='||siopeCodeTipo||'.';

                    	select class.classif_tipo_id into siopeCodeTipoId
                        from siac_d_class_tipo class
                        where class.classif_tipo_code=siopeCodeTipo
                        and   class.ente_proprietario_id=enteProprietarioId
                        and   class.data_cancellazione is null
 				    	and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
	 		 		    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(class.validita_fine,dataElaborazione));
                     end if;
                   if siopeCodeTipoId is not null then --2
                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                     		  ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                     		  ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                    		  ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
		                      ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
		                      ||' mifCountRec='||mifCountRec
	                          ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore class tipo='||flussoElabMifElabRec.flussoElabMifParam||'.';


                	select class.classif_code, class.classif_desc
                           into flussoElabMifValore,flussoElabMifValoreDesc
                    from siac_r_ordinativo_class cord, siac_t_class class
                    where cord.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and cord.data_cancellazione is null
                    and cord.validita_fine is null
                    and class.classif_id=cord.classif_id
                    and class.classif_tipo_id=siopeCodeTipoId
                    and class.classif_code!=siopeDef
                    and class.data_cancellazione is null;

                    if flussoElabMifValore is null then --3
	                    select class.classif_code, class.classif_desc
    		                   into flussoElabMifValore,flussoElabMifValoreDesc
	                    from siac_r_movgest_class  r,  siac_t_class class
    	                where r.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
        	            and   r.data_cancellazione is null
            	        and   r.validita_fine is null
                	    and class.classif_id=r.classif_id
                    	and class.classif_tipo_id=siopeCodeTipoId
	                    and class.classif_code!=siopeDef
    	                and class.data_cancellazione is null;
                   end if; --3
                  end if; --2
                end if; --if  bAvvioSiopeNew=true then

                if flussoElabMifValore is not null then
                	mifFlussoOrdinativoRec.mif_ord_class_codice_cge:=flussoElabMifValore;
                    codiceCge:=flussoElabMifValore;
	                descCge:=flussoElabMifValoreDesc;


               end if;
            end if; --param
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if; -- elab
        end if; -- attivo

	    -- <importo>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
	    if codiceCge is not null then
    	flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
        			   ||' tipo flusso '||MANDMIF_TIPO||'.';
    	if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;

	    if flussoElabMifElabRec.flussoElabMifAttivo=true then
    	  if flussoElabMifElabRec.flussoElabMifElab=true then
                	mifFlussoOrdinativoRec.mif_ord_class_importo:=mifFlussoOrdinativoRec.mif_ord_importo;
	      else
    	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
    	end if;
	   end if;

       -- <classificazione_dati_siope_entrate>

       -- <tipo_debito_siope_c> COMMERCIALE
       flussoElabMifElabRec:=null;
       flussoElabMifValore:=null;
       isOrdCommerciale:=false;
       ordinativoSplitId:=null;
       mifCountRec:=mifCountRec+1;
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
        			   ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	   end if;

	   if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
	          if flussoElabMifElabRec.flussoElabMifDef is not null and
                 flussoElabMifElabRec.flussoElabMifParam is not null then

				 -- caso reintroito -- ancora da implementare

				 -- caso di ordinativo di incasso collegato a ordinativo di pagamento per Split
                 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
        			   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura ordinativo di pagamento SPLIT.';

  		         select ord.ord_id into ordinativoSplitId
			     from siac_r_ordinativo rOrd, siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
			         siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato, siac_d_relaz_tipo tiporel
				 where rord.ord_id_a=mifOrdinativoIdRec.mif_ord_ord_id
				 and   ord.ord_id=rord.ord_id_da
				 and   tipo.ord_tipo_id=ord.ord_tipo_id
				 and   tipo.ord_tipo_code='P'
			     and   rstato.ord_id=ord.ord_id
	             and   stato.ord_stato_id=rstato.ord_stato_id
	             and   stato.ord_stato_code!='A'
				 and   tiporel.relaz_tipo_id=rOrd.relaz_tipo_id
                 and   tiporel.relaz_tipo_code=flussoElabMifElabRec.flussoElabMifParam
				 and   rord.data_cancellazione is null
				 and   rord.validita_fine is null
				 and   ord.data_cancellazione is null
			     and   ord.validita_fine is null
			     and   rstato.data_cancellazione is null
	             and   rstato.validita_fine is null
                 limit 1;

            	 if ordinativoSplitId is not null then
                   mifFlussoOrdinativoRec.mif_ord_class_tipo_debito=flussoElabMifElabRec.flussoElabMifDef;
                   isOrdCommerciale:=true;
        	     end if;
               end if;
	      else
    	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	      end if;
       end if;

	   -- <tipo_debito_siope_nc> NON_COMMERCIALE se non COMMERCIALE -- NON COMMERCIALE
       flussoElabMifElabRec:=null;
       flussoElabMifValore:=null;
       mifCountRec:=mifCountRec+1;
       if isOrdCommerciale=false then
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
        			   ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;

	    if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
	          if flussoElabMifElabRec.flussoElabMifDef is not null then
                   mifFlussoOrdinativoRec.mif_ord_class_tipo_debito_nc=flussoElabMifElabRec.flussoElabMifDef;
              end if;
	      else
    	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	      end if;
        end if;
       end if;


       mifCountRec:=mifCountRec+12;
       -- <fatture_siope>
	   -- </fatture_siope>

       -- <dati_ARCONET_siope>
       -- <codice_economico_siope>
       flussoElabMifElabRec:=null;
       flussoElabMifValore:=null;
       mifCountRec:=mifCountRec+1;
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
       end if;
       if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
         if flussoElabMifElabRec.flussoElabMifParam is not null then

         	if codiceFinVTbr is null then
            	codiceFinVTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            end if;
 			if codiceFinVTbr is not null and codiceFinVTipoTbrId is null then --1
				-- codiceFinVTipoTbrId
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                     		  ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                     		  ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                    		  ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
		                      ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
		                      ||' mifCountRec='||mifCountRec
	                          ||' tipo flusso '||MANDMIF_TIPO||'.Lettura id class tipo='||codiceFinVTbr||'.';
			   select tipo.classif_tipo_id into strict codiceFinVTipoTbrId
			   from siac_d_class_tipo tipo
			   where tipo.ente_proprietario_id=enteProprietarioId
			   and   tipo.classif_tipo_code=codiceFinVTbr
			   and   tipo.data_cancellazione is null
			   and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
			   and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));
            end if; --1

            if codiceFinVTipoTbrId is not null then --2
      			strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura piano_conti_fin_V_code '||codiceFinVTbr||' [siac_r_ordinativo_class] .';
		    	select class.classif_code into flussoElabMifValore
  	  		    from siac_r_ordinativo_class r, siac_t_class class
	       	    where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
	      	      and   class.classif_id=r.classif_id
 		          and   class.classif_tipo_id=codiceFinVTipoTbrId
		 	      and   r.data_cancellazione is null
			      and   r.validita_fine is NULL
	  		      and   class.data_cancellazione is null;

			   if flussoElabMifValore is null then --3
		     	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura piano_conti_fin_V_code '||codiceFinVTbr||' [siac_r_movgest_class].';

             	   select class.classif_desc into flussoElabMifValore
	    	       from siac_r_movgest_class rclass, siac_t_class class
	               where rclass.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
   		           and   rclass.data_cancellazione is null
       		       and   rclass.validita_fine is null
           		   and   class.classif_id=rclass.classif_id
	               and   class.classif_tipo_id=codiceFinVTipoTbrId
   		           and   class.data_cancellazione is null
	               order by rclass.movgest_classif_id
   		           limit 1;
   	           end if; --3
           end if;--2
 /*      	  if collEventoCodeId is null then
        	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'Lettura tipo evento '||flussoElabMifElabRec.flussoElabMifParam||'.';

            select coll.collegamento_tipo_id into collEventoCodeId
            from siac_d_collegamento_tipo coll
            where coll.ente_proprietario_id=enteProprietarioId
            and   coll.collegamento_tipo_code=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1))
            and   coll.data_cancellazione is null
		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',coll.validita_inizio)
		    and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(coll.validita_fine,dataElaborazione));
         end if;

	     if collEventoCodeId is not null then
		  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'Lettura conto economico patrimoniale.';
          select conto.pdce_conto_code into flussoElabMifValore
          from siac_t_pdce_conto conto, siac_t_reg_movfin regMovFin, siac_r_evento_reg_movfin rEvento,
               siac_d_collegamento_tipo coll, siac_d_evento evento,
               siac_t_mov_ep reg, siac_r_reg_movfin_stato regstato, siac_d_reg_movfin_stato stato,
               siac_t_prima_nota pn, siac_r_prima_nota_stato rpnota, siac_d_prima_nota_stato pnstato,
               siac_t_mov_ep_det det
          where coll.ente_proprietario_id=enteProprietarioId
          and   coll.collegamento_tipo_id=collEventoCodeId
          and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
          and   rEvento.evento_id=evento.evento_id
          and   rEvento.campo_pk_id=mifOrdinativoIdRec.mif_ord_ord_id
          and   regMovFin.regmovfin_id=rEvento.regmovfin_id
--          and   regMovFin.ambito_id=ambitoFinId  -- AMBITO_FIN
          and   regstato.regmovfin_id=regMovFin.regmovfin_id
          and   stato.regmovfin_stato_id=regstato.regmovfin_stato_id
          and   stato.regmovfin_stato_code!=REGMOVFIN_STATO_A
          and   reg.regmovfin_id=regMovFin.regmovfin_id
          and   pn.pnota_id=reg.regep_id
          and   rpnota.pnota_id=pn.pnota_id
          and   pnstato.pnota_stato_id=rpnota.pnota_stato_id
          and   pnstato.pnota_stato_code!=REGMOVFIN_STATO_A
          and   det.movep_id=reg.movep_id
          and   det.movep_det_segno=SEGNO_ECONOMICO -- Avere
		  and   conto.pdce_conto_id=det.pdce_conto_id
          and   regMovFin.data_cancellazione is null
          and   regMovFin.validita_fine is null
          and   rEvento.data_cancellazione is null
          and   rEvento.validita_fine is null
          and   evento.data_cancellazione is null
          and   evento.validita_fine is null
          and   reg.data_cancellazione is null
          and   reg.validita_fine is null
          and   regstato.data_cancellazione is null
          and   regstato.validita_fine is null
          and   pn.data_cancellazione is null
          and   pn.validita_fine is null
          and   rpnota.data_cancellazione is null
          and   rpnota.validita_fine is null
          and   conto.data_cancellazione is null
          and   conto.validita_fine is null
          order by pn.pnota_id desc
          limit 1;
         end if;*/

	    end if; -- param
        if flussoElabMifValore is not null then
	        mifFlussoOrdinativoRec.mif_ord_class_economico:=flussoElabMifValore;
        end if;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

	  -- <importo_codice_economico_siope>
	  mifCountRec:=mifCountRec+1;
      if mifFlussoOrdinativoRec.mif_ord_class_economico is not null then
      	flussoElabMifElabRec:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         		mifFlussoOrdinativoRec.mif_ord_class_importo_economico:=mifFlussoOrdinativoRec.mif_ord_importo;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;
      end if;

	  -- <codice_ue_siope>
	  flussoElabMifElabRec:=null;
	  flussoElabMifValore:=null;
	  mifCountRec:=mifCountRec+1;
	  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
	  if flussoElabMifElabRec.flussoElabMifAttivo=true then
   		if flussoElabMifElabRec.flussoElabMifElab=true then
	     if flussoElabMifElabRec.flussoElabMifParam is not null then
    	 	if codiceUECodeTipo is null then
				codiceUECodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
	        end if;

         	if codiceUECodeTipo is not null and codiceUECodeTipoId is null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_d_class_tipo.';

        	 select tipo.classif_tipo_id into codiceUECodeTipoId
             from  siac_d_class_tipo tipo
             where tipo.ente_proprietario_id=enteProprietarioId
             and   tipo.classif_tipo_code=codiceUECodeTipo
             and   tipo.data_cancellazione is null
		     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
		 	 and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
       		end if;

	        if codiceUECodeTipoId is not null then

        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_t_class [siac_r_ordinativo_class].';
        	 select class.classif_code into flussoElabMifValore
             from siac_r_ordinativo_class rclass, siac_t_class class
             where rclass.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
             and   rclass.data_cancellazione is null
             and   rclass.validita_fine is null
             and   class.classif_id=rclass.classif_id
             and   class.classif_tipo_id=codiceUECodeTipoId
             and   class.data_cancellazione is null
             order by rclass.ord_classif_id
             limit 1;

		     if flussoElabMifValore is null then
            	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_t_class [siac_r_movgest_class].';
				select class.classif_code into flussoElabMifValore
	    	    from siac_r_movgest_class rclass, siac_t_class class
	            where rclass.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
	            and   rclass.data_cancellazione is null
	            and   rclass.validita_fine is null
	            and   class.classif_id=rclass.classif_id
	            and   class.classif_tipo_id=codiceUECodeTipoId
	            and   class.data_cancellazione is null
	            order by rclass.movgest_classif_id
	            limit 1;
             end if;
        	end if;

	        if flussoElabMifValore is not null then
				mifFlussoOrdinativoRec.mif_ord_class_transaz_ue:=flussoElabMifValore;
    	    end if;
          end if;
	   else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	   end if;
      end if;

	  -- <codice_entrata_siope>
	  flussoElabMifElabRec:=null;
	  flussoElabMifValore:=null;
	  mifCountRec:=mifCountRec+1;
	  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
	  if flussoElabMifElabRec.flussoElabMifAttivo=true then
   		if flussoElabMifElabRec.flussoElabMifElab=true then
	     if flussoElabMifElabRec.flussoElabMifParam is not null then
    	 	if ricorrenteCodeTipo is null then
				ricorrenteCodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
	        end if;

         	if ricorrenteCodeTipo is not null and ricorrenteCodeTipoId is null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_d_class_tipo.';

        	 select tipo.classif_tipo_id into ricorrenteCodeTipoId
             from  siac_d_class_tipo tipo
             where tipo.ente_proprietario_id=enteProprietarioId
             and   tipo.classif_tipo_code=ricorrenteCodeTipo
             and   tipo.data_cancellazione is null
		     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
		 	 and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
       		end if;

	        if ricorrenteCodeTipoId is not null then

        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_t_class [siac_r_ordinativo_class].';
        	 select upper(class.classif_desc) into flussoElabMifValore
             from siac_r_ordinativo_class rclass, siac_t_class class
             where rclass.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
             and   rclass.data_cancellazione is null
             and   rclass.validita_fine is null
             and   class.classif_id=rclass.classif_id
             and   class.classif_tipo_id=ricorrenteCodeTipoId
             and   class.data_cancellazione is null
             order by rclass.ord_classif_id
             limit 1;

		     if flussoElabMifValore is null then
            	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_t_class [siac_r_movgest_class].';
				select upper(class.classif_desc) into flussoElabMifValore
	    	    from siac_r_movgest_class rclass, siac_t_class class
	            where rclass.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
	            and   rclass.data_cancellazione is null
	            and   rclass.validita_fine is null
	            and   class.classif_id=rclass.classif_id
	            and   class.classif_tipo_id=ricorrenteCodeTipoId
	            and   class.data_cancellazione is null
	            order by rclass.movgest_classif_id
	            limit 1;
             end if;
        	end if;

	        if flussoElabMifValore is not null then
				mifFlussoOrdinativoRec.mif_ord_class_ricorrente_entrata:=flussoElabMifValore;
    	    end if;
          end if;
	   else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	   end if;
      end if;



       -- </dati_ARCONET_siope>
       -- </classificazione_dati_siope_entrate>
       -- </classificazione>

       -- <bollo>
       -- <assoggettamento_bollo>
   	  mifCountRec:=mifCountRec+1;
      ordCodiceBolloDesc:=null;
      codiceBolloPlusDesc:=null;
      codiceBolloPlusEsente:=false;
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      if mifOrdinativoIdRec.mif_ord_codbollo_id is not null then


	   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  	    end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	  if flussoElabMifElabRec.flussoElabMifElab=true then
            -- se REGOLARIZZAZIONE IMPOSTAZIONE DI ESENTE BOLLO
            if flussoElabMifElabRec.flussoElabMifParam is not null and
               flussoElabMifElabRec.flussoElabMifDef is not null and
               mifFlussoOrdinativoRec.mif_ord_vers_tipo_riscos is not null and
/*               mifFlussoOrdinativoRec.mif_ord_vers_tipo_riscos=
                 trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1)) -- REGOLARIZZAZIONE*/
               mifFlussoOrdinativoRec.mif_ord_vers_tipo_riscos in  -- siac-5652 14.12.2017 Sofia
               ( trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1)), -- REGOLARIZZAZIONE
                 trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))  -- REGOLARIZZAZIONE ACCREDITO BANCA d'ITALIA
               )
                  then
                   mifFlussoOrdinativoRec.mif_ord_bollo_carico:=
                       trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
                   mifFlussoOrdinativoRec.mif_ord_bollo_esenzione:=
                    trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));

                   codiceBolloPlusEsente:=true;
            end if;

            if mifFlussoOrdinativoRec.mif_ord_bollo_carico  is null then
          	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura codice bollo.';

             select bollo.codbollo_desc , replace(plus.codbollo_plus_desc,'BENEFICIARIO','VERSANTE'), plus.codbollo_plus_esente
                   into ordCodiceBolloDesc, codiceBolloPlusDesc, codiceBolloPlusEsente
             from siac_d_codicebollo bollo, siac_d_codicebollo_plus plus, siac_r_codicebollo_plus rp
             where bollo.codbollo_id=mifOrdinativoIdRec.mif_ord_codbollo_id
             and   rp.codbollo_id=bollo.codbollo_id
             and   plus.codbollo_plus_id=rp.codbollo_plus_id
             and   rp.data_cancellazione is null
             and   rp.validita_fine is null;

             if coalesce(codiceBolloPlusDesc,NVL_STR)!=NVL_STR  then
            	mifFlussoOrdinativoRec.mif_ord_bollo_carico:=codiceBolloPlusDesc;
             end if;
            end if;
          else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		  end if;
        end if;
       end if;

      -- <causale_esenzione_bollo>
   	  mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      if codiceBolloPlusEsente=true and coalesce(ordCodiceBolloDesc,NVL_STR)!=NVL_STR then
      	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  	    end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	  if flussoElabMifElabRec.flussoElabMifElab=true then
          	mifFlussoOrdinativoRec.mif_ord_bollo_esenzione:=substring(ordCodiceBolloDesc from 1 for 30);
          else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		  end if;
        end if;
      end if;
	  -- </bollo>

      -- <versante>
      -- <anagrafica_versante>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            	flussoElabMifValore:=soggettoRec.soggetto_desc;

                if flussoElabMifValore is not null then
	                mifFlussoOrdinativoRec.mif_ord_anag_versante:=substring(flussoElabMifValore from 1 for 140);
                end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;

	   -- <indirizzo_versante>
       flussoElabMifElabRec:=null;
       flussoElabMifValore:=null;
       mifCountRec:=mifCountRec+1;
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' indirizzo_benef mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            	select * into indirizzoRec
                from siac_t_indirizzo_soggetto indir
                where indir.soggetto_id=soggettoRifId
                and   indir.principale='S'
                and   indir.data_cancellazione is null
         	    and   indir.validita_fine is null;
	            if indirizzoRec is null then
                    isIndirizzoBenef:=false;
	            end if;

				if isIndirizzoBenef=true then
                 if indirizzoRec.via_tipo_id is not null then
            		select tipo.via_tipo_code into flussoElabMifValore
	                from siac_d_via_tipo tipo
    	            where tipo.via_tipo_id=indirizzoRec.via_tipo_id
        	        and   tipo.data_cancellazione is null
         		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		 			and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

         	        if flussoElabMifValore is not null then
        	        	flussoElabMifValore:=flussoElabMifValore||' ';
    	            end if;
             	 end if;

            	 flussoElabMifValore:=trim(both from coalesce(flussoElabMifValore,'')||coalesce(indirizzoRec.toponimo,'')
                                 ||' '||coalesce(indirizzoRec.numero_civico,''));

	             if flussoElabMifValore is not null then
		            mifFlussoOrdinativoRec.mif_ord_indir_versante:=substring(flussoElabMifValore from 1 for 30);
        	     end if;
               end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

   	   -- <cap_versante>
       mifCountRec:=mifCountRec+1;
	   if isIndirizzoBenef=true then
        if indirizzoRec.zip_code is not null  then
         flussoElabMifElabRec:=null;

         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
	            mifFlussoOrdinativoRec.mif_ord_cap_versante:=lpad(indirizzoRec.zip_code,5,'0');
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
        end if;
       end if;


       -- <localita_beneficiario>
       mifCountRec:=mifCountRec+1;
	   if isIndirizzoBenef=true then
        if indirizzoRec.comune_id is not null  then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;

	     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
          	select com.comune_desc into flussoElabMifValore
            from siac_t_comune com
            where com.comune_id=indirizzoRec.comune_id
            and   com.data_cancellazione is null
            and   com.validita_fine is null;

            if flussoElabMifValore is not null then
	            mifFlussoOrdinativoRec.mif_ord_localita_versante:=substring(flussoElabMifValore from 1 for 30);
            end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
        end if;
	  end if;

	  -- <provincia_beneficiario>
      mifCountRec:=mifCountRec+1;
	  if isIndirizzoBenef=true then
        if indirizzoRec.comune_id is not null  then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
          	select prov.sigla_automobilistica into flussoElabMifValore
            from siac_r_comune_provincia provRel, siac_t_provincia prov
            where provRel.comune_id=indirizzoRec.comune_id
            and   provRel.data_cancellazione is null
            and   provRel.validita_fine is null
            and   prov.provincia_id=provRel.provincia_id
            and   prov.data_cancellazione is null
            and   prov.validita_fine is null
            order by provRel.data_creazione;

            if flussoElabMifValore is not null then
	            mifFlussoOrdinativoRec.mif_ord_prov_versante:=flussoElabMifValore;
            end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
        end if;
	 end if;


	 -- <stato_versante>
  	 mifCountRec:=mifCountRec+1;

     -- <partita_iva_versante>
     mifCountRec:=mifCountRec+1;
     if soggettoRec.partita_iva is not null or
        (soggettoRec.partita_iva is null and soggettoRec.codice_fiscale is not null and length(soggettoRec.codice_fiscale)=11) then
      	 flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
          		if soggettoRec.partita_iva is not null then
                	 mifFlussoOrdinativoRec.mif_ord_partiva_versante:=soggettoRec.partita_iva;
                else
                	mifFlussoOrdinativoRec.mif_ord_partiva_versante:=trim ( both ' ' from soggettoRec.codice_fiscale);
                end if;

          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
        end if;
      end if;

      -- <codice_fiscale_versante>
      mifCountRec:=mifCountRec+1;
      if soggettoRec.partita_iva is null  then
      	 flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
          	if soggettoRec.codice_fiscale is not null and
  			   length(soggettoRec.codice_fiscale)=16 then
				flussoElabMifValore:=trim ( both ' ' from soggettoRec.codice_fiscale);
            end if;

            if flussoElabMifValore is not null then
		            mifFlussoOrdinativoRec.mif_ord_codfisc_versante:=flussoElabMifValore;
            end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
      end if;
     -- </versante>

     -- <causale>
	 flussoElabMifElabRec:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
            mifFlussoOrdinativoRec.mif_ord_vers_causale:=
	            replace(replace(substring(mifOrdinativoIdRec.mif_ord_desc from 1 for 370) , chr(VT_ASCII),chr(SPACE_ASCII)),chr(BS_ASCII),NVL_STR);
	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
      end if;

      -- <sospeso>
      -- <sospesi>
      -- <numero_provvisorio>
      -- <importo_provvisorio>
      mifCountRec:=mifCountRec+2;


      -- <mandato_associato>
      -- <numero_mandato>
      -- <progressivo_associato>
      mifCountRec:=mifCountRec+2;

      -- <informazioni_aggiuntive>
      -- <lingua>
     flussoElabMifElabRec:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifDef is not null then
        		mifFlussoOrdinativoRec.mif_ord_lingua:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
     end if;

     -- <riferimento_documento_esterno>
     mifCountRec:=mifCountRec+1;
   	 flussoElabMifElabRec:=null;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     if flussoElabMifElabRec.flussoElabMifId is null then
  		 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
   	 if flussoElabMifElabRec.flussoElabMifAttivo=true then
		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifDef is not null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura presenza allegati cartacei.';

                	select 1 into codResult
				    from siac_r_ordinativo_attr rattr
					where rattr.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   rattr.attr_id=ordAllegatoCartAttrId
				    and   rattr.boolean='S'
					and   rattr.data_cancellazione is null
				    and   rattr.validita_fine is null;

				if codResult is not null then
	                mifFlussoOrdinativoRec.mif_ord_rif_doc_esterno:=flussoElabMifElabRec.flussoElabMifDef;
		        end if;
             end if;
		else
    		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;
      end if;
      -- </informazioni_aggiuntive>

      -- <sostituzione_reversale>
      -- <numero_reversale_da_sostituire>
      flussoElabMifElabRec:=null;
      ordSostRec:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

      if flussoElabMifElabRec.flussoElabMifId is null then
  		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
        			strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura ordinativi di sostituzione.';
                	select * into ordSostRec
                    from fnc_mif_ordinativo_sostituito( mifOrdinativoIdRec.mif_ord_ord_id,
 														ordRelazCodeTipoId,
                                                        dataElaborazione,dataFineVal);

                    if ordSostRec is not null then
                    	mifFlussoOrdinativoRec.mif_ord_num_ord_colleg:=lpad(ordSostRec.ordNumeroSostituto::varchar,NUM_SETTE,ZERO_PAD);
                    end if;
    	else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;

      end if;

      mifCountRec:=mifCountRec+1;
      -- <progressivo_reversale_da_sostituire>
      if mifFlussoOrdinativoRec.mif_ord_num_ord_colleg is not null then
       	flussoElabMifElabRec:=null;
  	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    	if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
     		if flussoElabMifElabRec.flussoElabMifElab=true then
            	if flussoElabMifElabRec.flussoElabMifDef is not null then
                	mifFlussoOrdinativoRec.mif_ord_progr_ord_colleg:=flussoElabMifElabRec.flussoElabMifDef;
                end if;
     	    else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
	    end if;
 	 end if;

     -- <esercizio_reversale_da_sostituire>
     mifCountRec:=mifCountRec+1;
     if mifFlussoOrdinativoRec.mif_ord_num_ord_colleg is not null then
        flussoElabMifElabRec:=null;
		flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    	if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
     		if flussoElabMifElabRec.flussoElabMifElab=true then
               	mifFlussoOrdinativoRec.mif_ord_anno_ord_colleg:=ordSostRec.ordAnnoSostituto;
     	    else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
	    end if;
    end if;
	-- </sostituzione_reversale>

    -- <dati_a_disposizione_ente_versante> facoltativo non valorizzato
    -- </informazioni_versante>

    -- <dati_a_disposizione_ente_reversale>
    -- <codice_distinta>
    flussoElabMifElabRec:=null;
    mifCountRec:=mifCountRec+1;
    flussoElabMifValore:=null;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	 end if;

     if flussoElabMifElabRec.flussoElabMifAttivo=true then
      if flussoElabMifElabRec.flussoElabMifElab=true then
      		if mifOrdinativoIdRec.mif_ord_dist_id is not null then
				strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura distinta [siac_d_distinta].';
            	select  d.dist_code into flussoElabMifValore
                from siac_d_distinta d
                where d.dist_id=mifOrdinativoIdRec.mif_ord_dist_id;
            end if;

            if flussoElabMifValore is not null then
              	mifFlussoOrdinativoRec.mif_ord_codice_distinta:=flussoElabMifValore;
            end if;
      else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	  end if;
	 end if;

     -- <atto_contabile>
     flussoElabMifElabRec:=null;
     flussoElabMifValore:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
	     if flussoElabMifElabRec.flussoElabMifElab=true then
         	if flussoElabMifElabRec.flussoElabMifParam is not null then
                if attoAmmTipoAllRag is null then
            		attoAmmTipoAllRag:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if attoAmmStrTipoRag is null then
                	attoAmmStrTipoRag:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
         		end if;

                if attoAmmTipoAllRag is not null and  attoAmmStrTipoRag is not null then

                 flussoElabMifValore:=fnc_mif_estremi_attoamm_all(mifOrdinativoIdRec.mif_ord_atto_amm_id,
                 										          attoAmmTipoAllRag,attoAmmStrTipoRag,
                                                                  dataElaborazione, dataFineVal);

                end if;
          	end if;

            if flussoElabMifValore is not null then
                 	mifFlussoOrdinativoRec.mif_ord_codice_atto_contabile:=flussoElabMifValore;
            end if;

         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


      -- 15.01.2018 Sofia SIAC-5765
      -- <codice_operatore>
	  flussoElabMifElabRec:=null;
	  flussoElabMifValore:=null;
	  flussoElabMifValoreDesc:=null;
	  mifCountRec:=mifCountRec+1;
	  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
	  if flussoElabMifElabRec.flussoElabMifAttivo=true then
   		if flussoElabMifElabRec.flussoElabMifElab=true then


         if mifOrdinativoIdRec.mif_ord_login_creazione is not null then
			flussoElabMifValore:=mifOrdinativoIdRec.mif_ord_login_creazione;
         end if;

         if flussoElabMifValore is not null then
        	select substring(s.soggetto_desc  from 1 for 12)  into flussoElabMifValoreDesc
			from siac_t_account a, siac_r_soggetto_ruolo r, siac_t_soggetto s
			where a.ente_proprietario_id=enteProprietarioId
            and   a.account_code=flussoElabMifValore
			and   r.soggeto_ruolo_id=a.soggeto_ruolo_id
			and   s.soggetto_id=r.soggetto_id
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   a.data_cancellazione is null
            and   a.validita_fine is null;

            if 	flussoElabMifValoreDesc is not null then
            	flussoElabMifValore:=flussoElabMifValoreDesc;
            end if;
         end if;

         if flussoElabMifValore is not null then
            mifFlussoOrdinativoRec.mif_ord_code_operatore:=substring(flussoElabMifValore from 1 for 12);
         end if;
       else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	   end if;
     end if;
    -- </dati_a_disposizione_ente_reversale>
    -- </reversale>



  /*raise notice 'codice_funzione= %',mifFlussoOrdinativoRec.mif_ord_codice_funzione;
  raise notice 'numero_reversale= %',mifFlussoOrdinativoRec.mif_ord_numero;
  raise notice 'data_reversale= %',mifFlussoOrdinativoRec.mif_ord_data;
  raise notice 'importo_reversale= %',mifFlussoOrdinativoRec.mif_ord_importo;*/

  strMessaggio:='Inserimento mif_t_ordinativo_entrata per ord. numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        INSERT INTO mif_t_ordinativo_entrata
        (
		 mif_ord_flusso_elab_mif_id,
		 mif_ord_ord_id,
		 mif_ord_bil_id,
		 mif_ord_anno,
		 mif_ord_numero,
         mif_ord_codice_funzione,
		 mif_ord_data,
		 mif_ord_importo,
		 mif_ord_bci_tipo_contabil,
		 mif_ord_bci_tipo_entrata,
		 --mif_ord_bci_numero_doc,
		 mif_ord_destinazione,
		 mif_ord_codice_abi_bt,
		 mif_ord_codice_ente,
		 mif_ord_desc_ente,
		 mif_ord_codice_ente_bt,
		 mif_ord_anno_esercizio,
         mif_ord_codice_flusso_oil,
		 mif_ord_data_creazione_flusso,
		 mif_ord_anno_flusso,
         mif_ord_id_flusso_oil,
		 mif_ord_codice_struttura,
		 mif_ord_ente_localita,
		 mif_ord_ente_indirizzo,
		 mif_ord_cod_raggrup,
		 mif_ord_progr_vers,
		 mif_ord_class_codice_cge,
		 mif_ord_class_importo,
		 mif_ord_codifica_bilancio,
         mif_ord_capitolo,
		 mif_ord_articolo,
		 mif_ord_desc_codifica,
         mif_ord_desc_codifica_bil,
		 mif_ord_gestione,
		 mif_ord_anno_res,
		 mif_ord_importo_bil,
		 mif_ord_anag_versante,
		 mif_ord_indir_versante,
		 mif_ord_cap_versante,
		 mif_ord_localita_versante,
		 mif_ord_prov_versante,
		 mif_ord_partiva_versante,
		 mif_ord_codfisc_versante,
		 mif_ord_bollo_esenzione,
		 mif_ord_vers_tipo_riscos,
		 mif_ord_vers_cod_riscos,
		 mif_ord_vers_importo,
		 mif_ord_vers_causale,
		 mif_ord_lingua,
		 mif_ord_rif_doc_esterno,
		 mif_ord_info_tesoriere,
		 mif_ord_flag_copertura,
		 mif_ord_sost_rev,
		 mif_ord_num_ord_colleg,
		 mif_ord_progr_ord_colleg,
		 mif_ord_anno_ord_colleg,
		 mif_ord_numero_acc,
		 mif_ord_code_operatore, -- 15.01.2018 Sofia SIAC-5765
		 mif_ord_siope_codice_cge,
		 mif_ord_siope_descri_cge,
		 mif_ord_descri_estesa_cap,
         mif_ord_codice_ente_ipa, -- newSiope+
	     mif_ord_codice_ente_istat,
		 mif_ord_codice_ente_tramite,
		 mif_ord_codice_ente_tramite_bt,
		 mif_ord_riferimento_ente,
         mif_ord_vers_cc_postale,
		 mif_ord_class_tipo_debito,
         mif_ord_class_tipo_debito_nc,
		 mif_ord_class_economico,
		 mif_ord_class_importo_economico,
		 mif_ord_class_transaz_ue,
		 mif_ord_class_ricorrente_entrata,
		 mif_ord_bollo_carico,
		 mif_ord_stato_versante,
		 mif_ord_codice_distinta,
		 mif_ord_codice_atto_contabile, -- newSiope+
  		 validita_inizio,
         ente_proprietario_id,
  		 login_operazione
		)
		VALUES
        (
  		 flussoElabMifLogId, --idElaborazione univoco -- mif_ord_flusso_elab_mif_id
  		 mifOrdinativoIdRec.mif_ord_ord_id,     -- mif_ord_ord_id
		 mifOrdinativoIdRec.mif_ord_bil_id,     -- mif_ord_bil_id
  		 mifOrdinativoIdRec.mif_ord_ord_anno,   -- mif_ord_anno
  		 mifFlussoOrdinativoRec.mif_ord_numero, -- mif_ord_numero
  		 mifFlussoOrdinativoRec.mif_ord_codice_funzione, -- mif_ord_codice_funzione
  		 mifFlussoOrdinativoRec.mif_ord_data, -- mif_ord_data
--  	     (case when mifFlussoOrdinativoRec.mif_ord_codice_funzione in (FUNZIONE_CODE_N,FUNZIONE_CODE_A) then
--                    '0.00' else mifFlussoOrdinativoRec.mif_ord_importo end), -- mif_ord_importo
         mifFlussoOrdinativoRec.mif_ord_importo,  -- mif_ord_importo
 		 mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil,  -- mif_ord_bci_tipo_contabil
  	     mifFlussoOrdinativoRec.mif_ord_bci_tipo_entrata,   -- mif_ord_bci_tipo_entrata
 		 --mifFlussoOrdinativoRec.mif_ord_bci_numero_doc,   -- mif_ord_bci_numero_doc
 	 	 mifFlussoOrdinativoRec.mif_ord_destinazione,       -- mif_ord_destinazione
 		 mifFlussoOrdinativoRec.mif_ord_codice_abi_bt,      -- mif_ord_codice_abi_bt
 		mifFlussoOrdinativoRec.mif_ord_codice_ente,         -- mif_ord_codice_ente
		mifFlussoOrdinativoRec.mif_ord_desc_ente,           -- mif_ord_desc_ente
  		mifFlussoOrdinativoRec.mif_ord_codice_ente_bt,      -- mif_ord_codice_ente_bt
 		mifFlussoOrdinativoRec.mif_ord_anno_esercizio,      -- mif_ord_anno_esercizio
--  		annoBilancio||flussoElabMifDistOilId::varchar,  -- flussoElabMifDistOilId
  		annoBilancio||flussoElabMifDistOilRetId::varchar,
        extract(year from now())||'-'||
        lpad(extract('month' from now())::varchar,2,'0')||'-'||
        lpad(extract('day' from now())::varchar,2,'0')||'T'||
        lpad(extract('hour' from now())::varchar,2,'0')||':'||
        lpad(extract('minute' from now())::varchar,2,'0')||':'||'00',  -- mif_ord_data_creazione_flusso
        extract(year from now())::integer,                  -- mif_ord_anno_flusso
		flussoElabMifOilId, --idflussoOil                   -- mif_ord_id_flusso_oil
 		mifFlussoOrdinativoRec.mif_ord_codice_struttura,  -- mif_ord_codice_struttura
 		mifFlussoOrdinativoRec.mif_ord_ente_localita,     -- mif_ord_ente_localita
		mifFlussoOrdinativoRec.mif_ord_ente_indirizzo,    -- mif_ord_ente_indirizzo
        mifFlussoOrdinativoRec.mif_ord_cod_raggrup,       -- mif_ord_cod_raggrup
 		mifFlussoOrdinativoRec.mif_ord_progr_vers,        -- mif_ord_progr_vers
 		mifFlussoOrdinativoRec.mif_ord_class_codice_cge,  -- mif_ord_class_codice_cge
        mifFlussoOrdinativoRec.mif_ord_class_importo,     -- mif_ord_class_importo
 		mifFlussoOrdinativoRec.mif_ord_codifica_bilancio, -- mif_ord_codifica_bilancio
        mifFlussoOrdinativoRec.mif_ord_capitolo,          -- mif_ord_capitolo
  		mifFlussoOrdinativoRec.mif_ord_articolo,          -- mif_ord_articolo
 		mifFlussoOrdinativoRec.mif_ord_desc_codifica,     -- mif_ord_desc_codifica
        mifFlussoOrdinativoRec.mif_ord_desc_codifica_bil, -- mif_ord_desc_codifica_bil
		mifFlussoOrdinativoRec.mif_ord_gestione,          -- mif_ord_gestione
 		mifFlussoOrdinativoRec.mif_ord_anno_res,          -- mif_ord_anno_res
        mifFlussoOrdinativoRec.mif_ord_importo_bil,       -- mif_ord_importo_bil
        mifFlussoOrdinativoRec.mif_ord_anag_versante,     -- mif_ord_anag_versante
  		mifFlussoOrdinativoRec.mif_ord_indir_versante,    -- mif_ord_indir_versante
		mifFlussoOrdinativoRec.mif_ord_cap_versante,      -- mif_ord_cap_versante
 		mifFlussoOrdinativoRec.mif_ord_localita_versante, -- mif_ord_localita_versante
  		mifFlussoOrdinativoRec.mif_ord_prov_versante,     -- mif_ord_prov_versante
 		mifFlussoOrdinativoRec.mif_ord_partiva_versante,
  		mifFlussoOrdinativoRec.mif_ord_codfisc_versante,
 		mifFlussoOrdinativoRec.mif_ord_bollo_esenzione,
        mifFlussoOrdinativoRec.mif_ord_vers_tipo_riscos,
        mifFlussoOrdinativoRec.mif_ord_vers_cod_riscos,
        mifFlussoOrdinativoRec.mif_ord_vers_importo,
        mifFlussoOrdinativoRec.mif_ord_vers_causale,
 		mifFlussoOrdinativoRec.mif_ord_lingua,
		mifFlussoOrdinativoRec.mif_ord_rif_doc_esterno,
 		mifFlussoOrdinativoRec.mif_ord_info_tesoriere,
 		mifFlussoOrdinativoRec.mif_ord_flag_copertura,
        mifFlussoOrdinativoRec.mif_ord_sost_rev,
		mifFlussoOrdinativoRec.mif_ord_num_ord_colleg,
		mifFlussoOrdinativoRec.mif_ord_progr_ord_colleg,
		mifFlussoOrdinativoRec.mif_ord_anno_ord_colleg,
		mifFlussoOrdinativoRec.mif_ord_numero_acc,
        mifFlussoOrdinativoRec.mif_ord_code_operatore, -- 15.01.2018 Sofia SIAC-5765
        mifFlussoOrdinativoRec.mif_ord_siope_codice_cge,
        mifFlussoOrdinativoRec.mif_ord_siope_descri_cge,
        mifFlussoOrdinativoRec.mif_ord_descri_estesa_cap,
        mifFlussoOrdinativoRec.mif_ord_codice_ente_ipa, -- newSiope+
	    mifFlussoOrdinativoRec.mif_ord_codice_ente_istat,
		mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite,
		mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite_bt,
		mifFlussoOrdinativoRec.mif_ord_riferimento_ente,
        mifFlussoOrdinativoRec.mif_ord_vers_cc_postale,
	    mifFlussoOrdinativoRec.mif_ord_class_tipo_debito,    -- commerciale
        mifFlussoOrdinativoRec.mif_ord_class_tipo_debito_nc, -- non_commerciale
	    mifFlussoOrdinativoRec.mif_ord_class_economico,
	    mifFlussoOrdinativoRec.mif_ord_class_importo_economico,
	    mifFlussoOrdinativoRec.mif_ord_class_transaz_ue,
	    mifFlussoOrdinativoRec.mif_ord_class_ricorrente_entrata,
	    mifFlussoOrdinativoRec.mif_ord_bollo_carico,
	    mifFlussoOrdinativoRec.mif_ord_stato_versante,
	    mifFlussoOrdinativoRec.mif_ord_codice_distinta,
	    mifFlussoOrdinativoRec.mif_ord_codice_atto_contabile, -- newSiope+
        now(),
        enteProprietarioId,
        loginOperazione
     )
     returning mif_ord_id into mifOrdSpesaId;



   /* da vedere
     if isGestioneQuoteOK=true then
	  quoteOrdinativoRec:=null;
	  mifCountRec:=FLUSSO_MIF_ELAB_NUM_QUOTA_MAND;
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura quote ordinativo.';

	for quoteOrdinativoRec in
    (select *
	 from fnc_mif_ordinativo_quote_entrata(mifOrdinativoIdRec.mif_ord_ord_id,
		 								   ordinativoTsDetTipoId,movgestTsTipoSubId,
                                           classCdrTipoId,classCdcTipoId,
        		                           enteProprietarioId,dataElaborazione,dataFineVal)
    )
    loop
  		-- <Numero_quota_reversale>
		mifCountRec:=FLUSSO_MIF_ELAB_NUM_QUOTA_MAND;
	    flussoElabMifElabRec:=null;
        codResult:=null;
		flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];


    end loop;

 end if; */





 -- <sospesi>
 -- <sospeso>
 -- <numero_provvisorio>
 -- <importo_provvisorio>
 if  isRicevutaAttivo=true then
    ricevutaRec:=null;
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Gestione  provvisori'
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    for ricevutaRec in
    (select *
     from fnc_mif_ordinativo_ricevute(mifOrdinativoIdRec.mif_ord_ord_id,
								      flussoElabMifTipoDec,
    	                              enteProprietarioId,dataElaborazione,dataFineVal)
    )
    loop
    	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Inserimento   ricevuta'
                       ||' in mif_t_ordinativo_entrata_ricevute '
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   		insert into mif_t_ordinativo_entrata_ricevute
        (mif_ord_id,
	     mif_ord_ric_anno,
	     mif_ord_ric_numero,
	     mif_ord_provc_id,
		 mif_ord_ric_importo,
	     validita_inizio,
		 ente_proprietario_id,
	     login_operazione
        )
        values
        (mifOrdSpesaId,
         ricevutaRec.annoRicevuta,
         ricevutaRec.numeroRicevuta,
         ricevutaRec.provRicevutaId,
         ricevutaRec.importoRicevuta,
         now(),
         enteProprietarioId,
         loginOperazione
        );
    end loop;

  end if;

  -- dati fatture da valorizzare se ordinativo commerciale
  -- @@@@ sicuramente da completare
  -- <fattura_siope>
  if isGestioneFatture = true and isOrdCommerciale=true then
   flussoElabMifElabRec:=null;
   mifCountRec:=FLUSSO_MIF_ELAB_FATTURE;
   titoloCap:=null;
   codResult:=null;
   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];

   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Gestione fatture.Lettura macroaggregato ordinativo di spesa collegato.';
--   select c.classif_code into titoloCap
   -- 23.02.2018 Sofia JIRA siac-5849
   select c.classif_id into codResult
   from siac_r_ordinativo_bil_elem re, siac_r_bil_elem_class rc,
        siac_t_class c
   where re.ord_id=ordinativoSplitId
   and   rc.elem_id=re.elem_id
   and   c.classif_id=rc.classif_id
   and   c.classif_tipo_id=macroAggrTipoCodeId
   and   re.data_cancellazione is null
   and   re.validita_fine is null
   and   rc.data_cancellazione is null
   and   rc.validita_fine is null
   and   c.data_cancellazione is null;

   -- 23.02.2018 Sofia JIRA siac-5849
   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Gestione fatture.Lettura natura spesa ordinativo di spesa collegato.';
   select oil.oil_natura_spesa_desc into titoloCap
   from siac_d_oil_natura_spesa oil, siac_r_oil_natura_spesa_titolo r,
        siac_r_class_fam_tree rtree
   where rtree.classif_fam_tree_id=famMacroTitCodeId
   and   rtree.classif_id=codResult -- macroaggregatoId
   and   r.oil_natura_spesa_titolo_id=rtree.classif_id_padre
   and   oil.oil_natura_spesa_id=r.oil_natura_spesa_id
   and   rtree.data_cancellazione is null
   and   rtree.validita_fine is null
   and   r.data_cancellazione is null
   and   r.validita_fine is null;

  if titoloCap is null then titoloCap:=defNaturaPag; end if;
  -- 26.02.2018 Sofia JIRA siac-5849 - esclusione note credito  per ordinativi di incasso
  titoloCap:=titoloCap||'|S';

  /**  -- 23.02.2018 Sofia JIRA siac-5849
  if titoloCap is not null then
    if substring(titoloCap from 1 for 1)=titoloCorrente then
	  	titoloCap:=descriTitoloCorrente;
    else
     if substring(titoloCap from 1 for 1)=titoloCapitale then
     	titoloCap:=descriTitoloCapitale;
     end if;
    end if;
   end if; **/

   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Gestione fatture.';
   ordRec:=null;
   for ordRec in
   (select * from fnc_mif_ordinativo_documenti_splus( ordinativoSplitId, -- cerco i documenti relativi a ordinativo di pagamento collegato per split
											          numeroDocs::integer,
                                                      tipoDocs,
                                                      docAnalogico,
                                                      attrCodeDataScad,
                                                      titoloCap,
                                                      enteOilRec.ente_oil_codice_pcc_uff,
		   		                        	          enteProprietarioId,
	            		                              dataElaborazione,dataFineVal)
   )
    loop
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Inserimento fatture '
                       ||' in mif_t_ordinativo_spesa_documenti '
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         insert into  mif_t_ordinativo_spesa_documenti
         ( mif_ord_id,
		   mif_ord_documento,
           mif_ord_doc_codice_ipa_ente,
	       mif_ord_doc_tipo,
           mif_ord_doc_tipo_a,
		   mif_ord_doc_id_lotto_sdi,
		   mif_ord_doc_tipo_analog,
		   mif_ord_doc_codfisc_emis,
		   mif_ord_doc_anno,
	       mif_ord_doc_numero,
	       mif_ord_doc_importo,
	       mif_ord_doc_data_scadenza,
	       mif_ord_doc_motivo_scadenza,
	       mif_ord_doc_natura_spesa,
		   validita_inizio,
		   ente_proprietario_id,
		   login_operazione
         )
         values
         (mifOrdSpesaId,
          ordRec.numero_fattura_siope,
		  ordRec.codice_ipa_ente_siope,
		  ordRec.tipo_documento_siope,
          ordRec.tipo_documento_siope_a,
          ordRec.identificativo_lotto_sdi_siope,
          ordRec.tipo_documento_analogico_siope,
          trim ( both ' ' from ordRec.codice_fiscale_emittente_siope),
		  ordRec.anno_emissione_fattura_siope,
		  ordRec.numero_fattura_siope,
          --ordRec.importo_siope,     -- 22.12.2017 Sofia siac-5665
          ordRec.importo_siope_split, -- 22.12.2017 Sofia siac-5665
		  ordRec.data_scadenza_pagam_siope,
		  ordRec.motivo_scadenza_siope,
    	  ordRec.natura_spesa_siope,
          now(),
          enteProprietarioId,
          loginOperazione
         );
    end loop;
   end if;

   numeroOrdinativiTrasm:=numeroOrdinativiTrasm+1;

   end loop;

   strMessaggio:='Aggiornamento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
   update siac_t_progressivo p set prog_value=flussoElabMifOilId
   where p.ente_proprietario_id=enteProprietarioId
   and   p.prog_key='oil_out_'||annoBilancio
   and   p.ambito_id=ambitoFinId
   and   p.data_cancellazione is null
   and   p.validita_fine is null;

   strMessaggio:='Aggiornamento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_'||MANDMIF_TIPO||'_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
   update siac_t_progressivo p set prog_value=flussoElabMifDistOilRetId
   where p.ente_proprietario_id=enteProprietarioId
   and   p.prog_key='oil_'||MANDMIF_TIPO||'_'||annoBilancio
   and   p.ambito_id=ambitoFinId
   and   p.data_cancellazione is null
   and   p.validita_fine is null;

   strMessaggio:='Aggiornamento mif_t_flusso_elaborato.';
   update  mif_t_flusso_elaborato
   set (flusso_elab_mif_id_flusso_oil,flusso_elab_mif_codice_flusso_oil,flusso_elab_mif_num_ord_elab,flusso_elab_mif_file_nome,flusso_elab_mif_esito_msg)=
   	   (flussoElabMifOilId,annoBilancio||flussoElabMifDistOilRetId::varchar,numeroOrdinativiTrasm,flussoElabMifTipoNomeFile||'_'||enteOilRec.ente_oil_codice,
        'Elaborazione in corso tipo flusso '||MANDMIF_TIPO||' - Dati inseriti in mif_t_ordinativo_entrata')
   where flusso_elab_mif_id=flussoElabMifLogId;

    -- gestire aggiornamento mif_t_flusso_elaborato

	RAISE NOTICE 'numeroOrdinativiTrasm %', numeroOrdinativiTrasm;
    messaggioRisultato:=strMessaggioFinale||' Trasmessi '||numeroOrdinativiTrasm||' ordinativi di entrata.';
    messaggioRisultato:=upper(messaggioRisultato);
    flussoElabMifId:=flussoElabMifLogId;
    nomeFileMif:=flussoElabMifTipoNomeFile||'_'||enteOilRec.ente_oil_codice;
    flussoElabMifDistOilId:=(annoBilancio||flussoElabMifDistOilRetId::varchar)::integer;

    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE :  % %',coalesce(strMessaggioFinale,''),coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 1000),mifCountRec;
        if codResult=-12 then
          messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 1500),'') ||' '||mifCountRec||'.';
          codiceRisultato:=0;
        else
          messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 1500),'')||' '||mifCountRec||'.' ;
       	  codiceRisultato:=-1;
    	end if;

        numeroOrdinativiTrasm:=0;
		messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then
            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;
        else
        	flussoElabMifId:=null;
        end if;

        return;
     when NO_DATA_FOUND THEN
        raise notice '% % ERRORE : % %',coalesce(strMessaggioFinale,''),coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 1500),mifCountRec;
        messaggioRisultato:=coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||' Nessun dato presente in archivio '||' '||mifCountRec||'.';
        numeroOrdinativiTrasm:=0;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then
            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;
        else
        	flussoElabMifId:=null;
        end if;

        return;
     when TOO_MANY_ROWS THEN
        raise notice '% % ERRORE : % %',coalesce(strMessaggioFinale,''),coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 1500),mifCountRec;
        messaggioRisultato:=coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio '||' '||mifCountRec||'.';
        numeroOrdinativiTrasm:=0;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then
            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;
        else
        	flussoElabMifId:=null;
        end if;
        return;
	when others  THEN
		raise notice '% % Errore DB % % %',coalesce(strMessaggioFinale,''),coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 1000),mifCountRec;
        messaggioRisultato:=coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500)||' '||mifCountRec||'.' ;
        numeroOrdinativiTrasm:=0;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then
            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;
        else
        	flussoElabMifId:=null;
        end if;

        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

 
-- SIAC-5849 - Sofia 01.03.2018 - FINE

-- SIAC-5951, SIAC-5955 INIZIO
CREATE OR REPLACE FUNCTION siac.fnc_770_tracciato_quadro_c_f (
  p_anno_elab varchar,
  p_ente_proprietario_id integer,
  p_ex_ente varchar,
  p_quadro_c_f varchar
)
RETURNS varchar AS
$body$
DECLARE

rec_tracciato_770 record;
rec_indirizzo record;
rec_inps record;
rec_tracciato_fin_c record;
rec_tracciato_fin_f record;

v_soggetto_id INTEGER; -- SIAC-5485
v_comune_id_nascita INTEGER; 
v_comune_id INTEGER;
v_comune_id_gen INTEGER;
v_via_tipo_id INTEGER;
v_ord_id_a INTEGER;
v_indirizzo_tipo_code VARCHAR;
v_principale VARCHAR;
v_onere_tipo_code VARCHAR;

v_zip_code VARCHAR;
v_comune_desc VARCHAR;
v_provincia_desc VARCHAR;
v_nazione_desc VARCHAR;
v_indirizzo VARCHAR;
v_via_tipo_desc VARCHAR;
v_toponimo VARCHAR;
v_numero_civico VARCHAR;
v_frazione VARCHAR;
v_interno VARCHAR;
-- INPS
v_importoParzInpsImpon NUMERIC;
v_importoParzInpsNetto NUMERIC;
v_importoParzInpsRiten NUMERIC;
v_importoParzInpsEnte NUMERIC;
v_importo_ritenuta_inps NUMERIC;
v_importo_imponibile_inps NUMERIC;
v_importo_ente_inps NUMERIC;
v_importo_netto_inps NUMERIC;
v_idFatturaOld INTEGER;
v_contaQuotaInps INTEGER;
v_percQuota NUMERIC;
v_numeroQuoteFattura INTEGER;
-- INPS 
v_tipo_record VARCHAR;
v_codice_fiscale_ente VARCHAR;
v_codice_fiscale_percipiente VARCHAR;
v_tipo_percipiente VARCHAR;
v_cognome VARCHAR;
v_nome VARCHAR;
v_sesso VARCHAR;
v_data_nascita TIMESTAMP;    
v_comune_nascita VARCHAR;
v_nazione_nascita VARCHAR; 
v_provincia_nascita VARCHAR;
v_comune_indirizzo_principale VARCHAR;
v_provincia_indirizzo_principale VARCHAR;
v_indirizzo_principale VARCHAR;
v_cap_indirizzo_principale VARCHAR;  
 
v_indirizzo_fiscale VARCHAR;
v_cap_indirizzo_fiscale VARCHAR;
v_comune_indirizzo_fiscale VARCHAR;
v_provincia_indirizzo_fiscale VARCHAR;    
        
v_codice_fiscale_estero VARCHAR;
v_causale VARCHAR;
v_importo_lordo NUMERIC;
v_somma_non_soggetta NUMERIC;  
v_importo_imponibile NUMERIC;
v_ord_ts_det_importo NUMERIC;
v_importo_carico_ente NUMERIC;
v_importo_carico_soggetto NUMERIC; 
v_codice VARCHAR;  
v_codice_tributo VARCHAR;
v_matricola_c INTEGER;
v_matricola_f INTEGER;
v_codice_controllo2 VARCHAR;
v_aliquota NUMERIC;
    
v_elab_id INTEGER;
v_elab_id_det INTEGER;
v_elab_id_temp INTEGER;
v_elab_id_det_temp INTEGER;
v_codresult INTEGER := null;
elab_mif_esito_in CONSTANT  VARCHAR := 'IN';
elab_mif_esito_ok CONSTANT  VARCHAR := 'OK';
elab_mif_esito_ko CONSTANT  VARCHAR := 'KO';
v_tipo_flusso  CONSTANT  VARCHAR := 'MOD770';
v_login CONSTANT  VARCHAR := 'SIAC';
messaggioRisultato VARCHAR;

BEGIN

-- Inserimento record in tabella mif_t_flusso_elaborato
INSERT INTO mif_t_flusso_elaborato
(flusso_elab_mif_data,
 flusso_elab_mif_esito,
 flusso_elab_mif_esito_msg,
 flusso_elab_mif_file_nome,
 flusso_elab_mif_tipo_id,
 flusso_elab_mif_id_flusso_oil,
 validita_inizio,
 ente_proprietario_id,
 login_operazione)
 (SELECT now(),
         elab_mif_esito_in,
         'Elaborazione in corso per tipo flusso '||v_tipo_flusso,
         tipo.flusso_elab_mif_nome_file,
         tipo.flusso_elab_mif_tipo_id,
         null, -- flussoElabMifOilId, -- non usato per questo tipo di flusso
         now(),
         p_ente_proprietario_id,
         v_login
  FROM mif_d_flusso_elaborato_tipo tipo
  WHERE tipo.ente_proprietario_id = p_ente_proprietario_id
  AND   tipo.flusso_elab_mif_tipo_code = v_tipo_flusso
  AND   tipo.data_cancellazione IS NULL
  AND   tipo.validita_fine IS NULL
 )
 RETURNING flusso_elab_mif_id into v_elab_id;

IF p_anno_elab IS NULL THEN
   messaggioRisultato := 'Parametro Anno di Elaborazione nullo.';
   -- RETURN NEXT;
   -- Aggiornamento mif_t_flusso_elaborato per flusso_elab_mif_id = v_elab_id
   UPDATE  mif_t_flusso_elaborato
   SET (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
       (elab_mif_esito_ko,'Elaborazione conclusa con errori per tipo flusso '||v_tipo_flusso||'.'||messaggioRisultato, now())
   WHERE flusso_elab_mif_id = v_elab_id;
   RETURN messaggioRisultato;
END IF;

IF p_ente_proprietario_id IS NULL THEN
   messaggioRisultato := 'Parametro Ente Propietario nullo.';
   -- RETURN NEXT;
   RETURN messaggioRisultato;
END IF;

IF p_ex_ente IS NULL THEN
   messaggioRisultato := 'Parametro Ex Ente nullo.';
   -- RETURN NEXT;
   RETURN messaggioRisultato;
END IF;

IF p_quadro_c_f IS NULL THEN
   messaggioRisultato := 'Parametro Quadro C-F nullo.';
   -- RETURN NEXT;
   RETURN messaggioRisultato;
END IF;

IF v_elab_id IS NULL THEN
  messaggioRisultato := 'Errore generico in inserimento';
  -- RETURN NEXT;  
  RETURN messaggioRisultato;
END IF;

v_codresult:=null;
-- Verifica esistenza elaborazioni in corso per tipo flusso
SELECT DISTINCT 1 
INTO v_codresult
FROM mif_t_flusso_elaborato elab,  mif_d_flusso_elaborato_tipo tipo
WHERE  elab.flusso_elab_mif_id != v_elab_id
AND    elab.flusso_elab_mif_esito = elab_mif_esito_in
AND    elab.data_cancellazione IS NULL
AND    elab.validita_fine IS NULL
AND    tipo.flusso_elab_mif_tipo_id = elab.flusso_elab_mif_tipo_id
AND    tipo.flusso_elab_mif_tipo_code = v_tipo_flusso
AND    tipo.ente_proprietario_id = p_ente_proprietario_id
AND    tipo.data_cancellazione IS NULL
AND    tipo.validita_fine IS NULL;

IF v_codresult IS NOT NULL THEN
   messaggioRisultato := 'Verificare situazioni esistenti.';
   -- RETURN NEXT;
   -- Aggiornamento mif_t_flusso_elaborato per flusso_elab_mif_id = v_elab_id
   UPDATE  mif_t_flusso_elaborato
   SET (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
       (elab_mif_esito_ko,'Elaborazione conclusa con errori per tipo flusso '||v_tipo_flusso||'.'||messaggioRisultato, now())
   WHERE flusso_elab_mif_id = v_elab_id;
   RETURN messaggioRisultato;  
END IF;

v_elab_id_det := 1;
v_elab_id_det_temp := 1;
v_matricola_c := 8000000;
v_matricola_f := 9000000;

IF p_quadro_c_f in ('C','T') THEN
  DELETE FROM siac.tracciato_770_quadro_c_temp
  WHERE ente_proprietario_id = p_ente_proprietario_id;
  --AND   anno_competenza = p_anno_elab

  DELETE FROM siac.tracciato_770_quadro_c
  WHERE ente_proprietario_id = p_ente_proprietario_id;
  --AND   anno_competenza = p_anno_elab
END IF;

IF p_quadro_c_f in ('F','T') THEN
  DELETE FROM siac.tracciato_770_quadro_f_temp
  WHERE ente_proprietario_id = p_ente_proprietario_id;
  --AND   anno_competenza = p_anno_elab

  DELETE FROM siac.tracciato_770_quadro_f
  WHERE ente_proprietario_id = p_ente_proprietario_id;
  --AND   anno_competenza = p_anno_elab
END IF;

IF p_quadro_c_f = 'C' THEN
   v_onere_tipo_code := 'IRPEF';
ELSIF p_quadro_c_f = 'F' THEN
   v_onere_tipo_code := 'IRPEG';
ELSE
   v_onere_tipo_code := null;
END IF;   

v_codice_fiscale_ente := null;
v_tipo_record := null;

SELECT codice_fiscale
INTO   v_codice_fiscale_ente
FROM   siac_t_ente_proprietario
WHERE  ente_proprietario_id = p_ente_proprietario_id;

--v_importo_lordo := 0;
--v_codice_tributo := null;
--v_causale := null; 

v_idFatturaOld := 0;
v_contaQuotaInps := 0;

FOR rec_tracciato_770 IN
SELECT --sto.ord_id, 
       --SUM(totd.ord_ts_det_importo) IMPORTO_LORDO,
       --totd.ord_ts_det_importo IMPORTO_LORDO,       
       rdo.caus_id,
       sdo.onere_code,
       td.doc_id,
       rdo.doc_onere_id,
       rdo.somma_non_soggetta_tipo_id,
       rdo.onere_id,
       sros.soggetto_id,
       roa.testo
FROM  siac_t_ordinativo sto
INNER JOIN siac_t_ente_proprietario tep ON sto.ente_proprietario_id = tep.ente_proprietario_id
INNER JOIN siac_t_bil tb ON tb.bil_id = sto.bil_id
INNER JOIN siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
INNER JOIN siac_r_ordinativo_stato ros ON sto.ord_id = ros.ord_id
INNER JOIN siac_d_ordinativo_stato dos ON ros.ord_stato_id = dos.ord_stato_id
INNER JOIN siac_d_ordinativo_tipo dot ON dot.ord_tipo_id = sto.ord_tipo_id
INNER JOIN siac_t_ordinativo_ts tot ON tot.ord_id = sto.ord_id
--INNER JOIN siac_t_ordinativo_ts_det totd ON totd.ord_ts_id = tot.ord_ts_id
--INNER JOIN siac_d_ordinativo_ts_det_tipo dotdt ON dotdt.ord_ts_det_tipo_id = totd.ord_ts_det_tipo_id
INNER JOIN siac_r_subdoc_ordinativo_ts rsot ON rsot.ord_ts_id = tot.ord_ts_id
INNER JOIN siac_t_subdoc ts ON ts.subdoc_id = rsot.subdoc_id
INNER JOIN siac_t_doc td ON td.doc_id = ts.doc_id
INNER JOIN siac_r_doc_onere rdo ON rdo.doc_id = td.doc_id
INNER JOIN siac_r_onere_attr roa ON roa.onere_id = rdo.onere_id
INNER JOIN siac_t_attr ta ON ta.attr_id = roa.attr_id
INNER JOIN siac_d_onere sdo ON sdo.onere_id = rdo.onere_id
INNER JOIN siac_d_onere_tipo sdot ON sdot.onere_tipo_id = sdo.onere_tipo_id
INNER JOIN siac_r_ordinativo_soggetto sros ON sros.ord_id = sto.ord_id
WHERE sto.ente_proprietario_id = p_ente_proprietario_id
AND   tp.anno = p_anno_elab
AND   dos.ord_stato_code <> 'A'
AND   dot.ord_tipo_code = 'P'
--AND   dotdt.ord_ts_det_tipo_code = 'A'
AND   ((roa.testo = p_quadro_c_f) OR ('T' = p_quadro_c_f AND roa.testo IN ('C','F')))
AND   ta.attr_code = 'QUADRO_770'
AND   ((sdot.onere_tipo_code = v_onere_tipo_code) OR ('T' = p_quadro_c_f AND sdot.onere_tipo_code IN ('IRPEF','IRPEG')))
AND   sto.data_cancellazione IS NULL
AND   tep.data_cancellazione IS NULL
AND   tb.data_cancellazione IS NULL
AND   tp.data_cancellazione IS NULL
AND   ros.data_cancellazione IS NULL
AND   dos.data_cancellazione IS NULL
AND   dot.data_cancellazione IS NULL
AND   tot.data_cancellazione IS NULL
--AND   totd.data_cancellazione IS NULL
--AND   dotdt.data_cancellazione IS NULL
AND   rsot.data_cancellazione IS NULL
AND   ts.data_cancellazione IS NULL
AND   td.data_cancellazione IS NULL
AND   rdo.data_cancellazione IS NULL
AND   roa.data_cancellazione IS NULL
AND   ta.data_cancellazione IS NULL
AND   sdo.data_cancellazione IS NULL
AND   sdot.data_cancellazione IS NULL
AND   sros.data_cancellazione IS NULL
AND   now() BETWEEN sto.validita_inizio AND COALESCE(sto.validita_fine, now())
AND   now() BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, now())
AND   now() BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, now())
AND   now() BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, now())
AND   now() BETWEEN ros.validita_inizio AND COALESCE(ros.validita_fine, now())
AND   now() BETWEEN dos.validita_inizio AND COALESCE(dos.validita_fine, now())
AND   now() BETWEEN dot.validita_inizio AND COALESCE(dot.validita_fine, now())
AND   now() BETWEEN tot.validita_inizio AND COALESCE(tot.validita_fine, now())
--AND   now() BETWEEN totd.validita_inizio AND COALESCE(totd.validita_fine, now())
--AND   now() BETWEEN dotdt.validita_inizio AND COALESCE(dotdt.validita_fine, now())
AND   now() BETWEEN rsot.validita_inizio AND COALESCE(rsot.validita_fine, now())
AND   now() BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, now())
AND   now() BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, now())
AND   now() BETWEEN rdo.validita_inizio AND COALESCE(rdo.validita_fine, now())
AND   now() BETWEEN roa.validita_inizio AND COALESCE(roa.validita_fine, now())
AND   now() BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, now())
AND   now() BETWEEN sdo.validita_inizio AND COALESCE(sdo.validita_fine, now())
AND   now() BETWEEN sdot.validita_inizio AND COALESCE(sdot.validita_fine, now())
AND   now() BETWEEN sros.validita_inizio AND COALESCE(sros.validita_fine, now())
GROUP BY   rdo.caus_id,
           sdo.onere_code,
           td.doc_id,
           rdo.doc_onere_id,
           rdo.somma_non_soggetta_tipo_id,
           rdo.onere_id,
           sros.soggetto_id,
           roa.testo

LOOP  

  --v_importo_lordo := 0;
  v_importoParzInpsImpon := 0;
  v_importoParzInpsNetto := 0;
  v_importoParzInpsRiten := 0;
  v_importoParzInpsEnte := 0;
  v_importo_ritenuta_inps := 0;
  v_importo_imponibile_inps := 0;
  v_importo_ente_inps := 0;
  v_importo_netto_inps := 0;
  v_codice_tributo := null;

  --v_importo_lordo := rec_tracciato_770.IMPORTO_LORDO;
  v_codice_tributo := rec_tracciato_770.onere_code;
  
  v_causale := null;
  
  BEGIN

    SELECT dc.caus_code
    INTO   STRICT v_causale
    FROM   siac_d_causale dc
    WHERE  dc.caus_id = rec_tracciato_770.caus_id
    AND    dc.data_cancellazione IS NULL
    AND    now() BETWEEN dc.validita_inizio AND COALESCE(dc.validita_fine, now());

  EXCEPTION
      
    WHEN NO_DATA_FOUND THEN
        v_causale := null;
      
  END;

  IF rec_tracciato_770.testo = 'C' THEN
   
    v_tipo_record := 'SC';   
    
    -- v_codice := null; -- SIAC-5955
    v_codice := '0'; -- SIAC-5955
    
    IF rec_tracciato_770.somma_non_soggetta_tipo_id IS NULL THEN
          -- SIAC-5955 INIZIO
/*          SELECT dsnst.somma_non_soggetta_tipo_code::varchar
          --INTO  STRICT v_codice
          INTO  v_codice
          FROM  siac_r_onere_somma_non_soggetta_tipo rosnst,
                siac_d_somma_non_soggetta_tipo dsnst
          WHERE rosnst.somma_non_soggetta_tipo_id = dsnst.somma_non_soggetta_tipo_id   
          AND   rosnst.onere_id = rec_tracciato_770.onere_id
          AND   rosnst.data_cancellazione IS NULL
          AND   dsnst.data_cancellazione IS NULL
          AND   now() BETWEEN rosnst.validita_inizio AND COALESCE(rosnst.validita_fine, now())
          AND   now() BETWEEN dsnst.validita_inizio AND COALESCE(dsnst.validita_fine, now());*/
          
          v_codice := '0';
          
          -- SIAC-5955 FINE                    
    ELSE

        BEGIN

          SELECT dsnst.somma_non_soggetta_tipo_code::varchar
          INTO   STRICT v_codice 
          FROM   siac_d_somma_non_soggetta_tipo dsnst
          WHERE  dsnst.somma_non_soggetta_tipo_id = rec_tracciato_770.somma_non_soggetta_tipo_id
          AND    dsnst.data_cancellazione IS NULL
          AND    now() BETWEEN dsnst.validita_inizio AND COALESCE(dsnst.validita_fine, now());  
      
        EXCEPTION
              
          WHEN NO_DATA_FOUND THEN
               -- v_codice := null; -- SIAC-5955
               v_codice := '0'; -- SIAC-5955
              
        END;    
    
    END IF;
    
  ELSE
    
    v_tipo_record := 'SF'; 
    
  END IF;

    -- PARTE RELATIVA AL SOGGETTO INIZIO
    
    v_codice_fiscale_percipiente := null;
    v_codice_fiscale_estero := null;
    v_tipo_percipiente := null;
    v_cognome := null;
    v_nome := null;
    v_sesso := null;
    v_data_nascita := null;
    v_comune_id_nascita := null;
    v_soggetto_id := null; -- SIAC-5485 
    
    BEGIN -- SIAC-5485 INIZIO
    
    SELECT a.soggetto_id_da
    INTO   STRICT v_soggetto_id
    FROM   siac_r_soggetto_relaz a, siac_d_relaz_tipo b
    WHERE  a.ente_proprietario_id = p_ente_proprietario_id
    AND    a.relaz_tipo_id = b.relaz_tipo_id
    AND    b.relaz_tipo_code = 'SEDE_SECONDARIA'
    AND    a.soggetto_id_a = rec_tracciato_770.soggetto_id;
    
    EXCEPTION
              
      WHEN NO_DATA_FOUND THEN      
           v_soggetto_id := rec_tracciato_770.soggetto_id; 
              
    END; -- SIAC-5485 FINE
        
    BEGIN
    
      SELECT ts.codice_fiscale,
             ts.codice_fiscale_estero,
             CASE 
                WHEN dst.soggetto_tipo_code IN ('PF','PFI') THEN
                     1
                ELSE
                     2
             END tipo_percipiente,
             coalesce(tpf.cognome, tpg.ragione_sociale) cognome,
             tpf.nome,
             tpf.sesso,
             tpf.nascita_data,
             tpf.comune_id_nascita
      INTO  STRICT v_codice_fiscale_percipiente,
            v_codice_fiscale_estero,
            v_tipo_percipiente,
            v_cognome,
            v_nome,
            v_sesso,
            v_data_nascita,
            v_comune_id_nascita                
      FROM siac_t_soggetto ts
      INNER JOIN siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
      INNER JOIN siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id = rst.soggetto_tipo_id
      LEFT JOIN  siac_t_persona_giuridica tpg ON tpg.soggetto_id = ts.soggetto_id
                                              AND now() BETWEEN tpg.validita_inizio AND COALESCE(tpg.validita_fine, now())
                                              AND tpg.data_cancellazione IS NULL
      LEFT JOIN  siac_t_persona_fisica tpf ON tpf.soggetto_id = ts.soggetto_id
                                              AND now() BETWEEN tpf.validita_inizio AND COALESCE(tpf.validita_fine, now())
                                              AND tpf.data_cancellazione IS NULL
      WHERE ts.soggetto_id = v_soggetto_id -- rec_tracciato_770.soggetto_id -- SIAC-5485
      AND   ts.data_cancellazione IS NULL
      AND   rst.data_cancellazione IS NULL
      AND   dst.data_cancellazione IS NULL
      AND   now() BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, now())
      AND   now() BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, now())
      AND   now() BETWEEN dst.validita_inizio AND COALESCE(dst.validita_fine, now());

      v_cognome := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_cognome),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
      v_nome := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_nome),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));

    EXCEPTION
              
      WHEN NO_DATA_FOUND THEN
           null;
              
    END;
    
    v_indirizzo_principale := null;
    v_cap_indirizzo_principale := null;
    v_comune_indirizzo_principale := null;
    v_provincia_indirizzo_principale := null;

    v_indirizzo_fiscale := null; -- SIAC-5485
    v_cap_indirizzo_fiscale := null; -- SIAC-5485
    v_comune_indirizzo_fiscale := null; -- SIAC-5485
    v_provincia_indirizzo_fiscale := null; -- SIAC-5485

    v_comune_nascita := null;
    v_provincia_nascita := null;
    v_nazione_nascita := null;    
    
    FOR rec_indirizzo IN
    SELECT tis.comune_id, dit.indirizzo_tipo_code, tis.principale, tis.zip_code,
           tis.toponimo, tis.numero_civico, tis.frazione, tis.interno, tis.via_tipo_id
    FROM   siac.siac_t_indirizzo_soggetto tis
    INNER JOIN siac.siac_r_indirizzo_soggetto_tipo rist ON rist.indirizzo_id = tis.indirizzo_id
                                                        AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN rist.validita_inizio AND COALESCE(rist.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
                                                        --AND now() BETWEEN rist.validita_inizio AND COALESCE(rist.validita_fine, now())
                                                        --AND rist.data_cancellazione IS NULL
    INNER JOIN siac.siac_d_indirizzo_tipo dit ON dit.indirizzo_tipo_id = rist.indirizzo_tipo_id
                                              AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN dit.validita_inizio AND COALESCE(dit.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
                                              --AND now() BETWEEN dit.validita_inizio AND COALESCE(dit.validita_fine, now())
                                              --AND dit.data_cancellazione IS NULL
    WHERE tis.soggetto_id = v_soggetto_id -- rec_tracciato_770.soggetto_id -- SIAC-5485
    AND   tis.principale = 'S'
    AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN tis.validita_inizio AND COALESCE(tis.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
    --AND   now() BETWEEN tis.validita_inizio AND COALESCE(tis.validita_fine, now())
    --AND   tis.data_cancellazione IS NULL
    UNION -- SIAC-5485 INIZIO
    SELECT tis.comune_id, dit.indirizzo_tipo_code, tis.principale, tis.zip_code,
           tis.toponimo, tis.numero_civico, tis.frazione, tis.interno, tis.via_tipo_id
    FROM   siac.siac_t_indirizzo_soggetto tis
    INNER JOIN siac.siac_r_indirizzo_soggetto_tipo rist ON rist.indirizzo_id = tis.indirizzo_id
                                                        AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN rist.validita_inizio AND COALESCE(rist.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
                                                        --AND now() BETWEEN rist.validita_inizio AND COALESCE(rist.validita_fine, now())
                                                        --AND rist.data_cancellazione IS NULL
    INNER JOIN siac.siac_d_indirizzo_tipo dit ON dit.indirizzo_tipo_id = rist.indirizzo_tipo_id
                                              AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN dit.validita_inizio AND COALESCE(dit.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
                                              --AND now() BETWEEN dit.validita_inizio AND COALESCE(dit.validita_fine, now())
                                              --AND dit.data_cancellazione IS NULL
    WHERE tis.soggetto_id = rec_tracciato_770.soggetto_id
    AND   dit.indirizzo_tipo_code = 'DOMICILIO'
    --AND   tis.principale = 'S'
    AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN tis.validita_inizio AND COALESCE(tis.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
    --AND   now() BETWEEN tis.validita_inizio AND COALESCE(tis.validita_fine, now())
    --AND   tis.data_cancellazione IS NULL -- SIAC-5485 FINE    
    UNION
    SELECT NULL, 'NASCITA', NULL, NULL, NULL, NULL, NULL, NULL, NULL

    LOOP

      v_comune_id := null;
      v_comune_id_gen := null;
      v_via_tipo_id := null;
      v_indirizzo_tipo_code := null;
      v_principale := null;
      
      v_zip_code := null;
      v_comune_desc := null;
      v_provincia_desc := null;
      v_nazione_desc := null;
      v_indirizzo := null;
      v_via_tipo_desc := null;
      v_toponimo := null;
      v_numero_civico := null;
      v_frazione := null;
      v_interno := null;
      
      v_comune_id := rec_indirizzo.comune_id;
      v_via_tipo_id := rec_indirizzo.via_tipo_id;      
      v_indirizzo_tipo_code := rec_indirizzo.indirizzo_tipo_code;      
      v_principale := rec_indirizzo.principale;
      
      v_zip_code := rec_indirizzo.zip_code;
      v_toponimo := rec_indirizzo.toponimo;
      v_numero_civico := rec_indirizzo.numero_civico;
      v_frazione := rec_indirizzo.frazione;
      v_interno := rec_indirizzo.interno;

      BEGIN
      
        SELECT dvt.via_tipo_desc
        INTO STRICT v_via_tipo_desc
        FROM siac.siac_d_via_tipo dvt
        WHERE dvt.via_tipo_id = v_via_tipo_id
        AND now() BETWEEN dvt.validita_inizio AND COALESCE(dvt.validita_fine, now())
        AND dvt.data_cancellazione IS NULL;
      
      EXCEPTION
      
        WHEN NO_DATA_FOUND THEN
        	v_via_tipo_desc := null;
      
      END;
      
      IF v_via_tipo_desc IS NOT NULL THEN
         v_indirizzo := v_via_tipo_desc;
      END IF;

      IF v_toponimo IS NOT NULL THEN
         v_indirizzo := v_indirizzo||' '||v_toponimo;
      END IF;

      IF v_numero_civico IS NOT NULL THEN
         v_indirizzo := v_indirizzo||' '||v_numero_civico;
      END IF;

      IF v_frazione IS NOT NULL THEN
         v_indirizzo := v_indirizzo||', frazione '||v_frazione;
      END IF;

      IF v_interno IS NOT NULL THEN
         v_indirizzo := v_indirizzo||', interno '||v_interno;
      END IF;

      v_indirizzo := REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_indirizzo),'à','a'''),'é','e'''),'è','e'''),'ì','i'''),'ò','o'''),'ù','u''');
      v_indirizzo := UPPER(v_indirizzo);

      IF v_indirizzo_tipo_code = 'NASCITA' THEN
         v_comune_id_gen := v_comune_id_nascita;
      ELSE
         v_comune_id_gen := v_comune_id;
      END IF;

      BEGIN

        SELECT tc.comune_desc, tp.sigla_automobilistica, tn.nazione_desc
        INTO  STRICT v_comune_desc, v_provincia_desc, v_nazione_desc
        FROM siac.siac_t_comune tc
        LEFT JOIN siac.siac_r_comune_provincia rcp ON rcp.comune_id = tc.comune_id
                                                   AND now() BETWEEN rcp.validita_inizio AND COALESCE(rcp.validita_fine, now())
                                                   AND rcp.data_cancellazione IS NULL
        LEFT JOIN siac.siac_t_provincia tp ON tp.provincia_id = rcp.provincia_id
                                           AND now() BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, now())
                                           AND tp.data_cancellazione IS NULL
        LEFT JOIN siac.siac_t_nazione tn ON tn.nazione_id = tc.nazione_id
                                         AND now() BETWEEN tn.validita_inizio AND COALESCE(tn.validita_fine, now())
                                         AND tn.data_cancellazione IS NULL
        WHERE tc.comune_id = v_comune_id_gen
        AND now() BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, now())
        AND tc.data_cancellazione IS NULL;

      EXCEPTION
                
        WHEN NO_DATA_FOUND THEN
             null;
                
      END;

    
      IF v_principale = 'S' THEN
         v_indirizzo_principale := v_indirizzo;
         v_cap_indirizzo_principale := v_zip_code;
         v_comune_indirizzo_principale := v_comune_desc;
         v_provincia_indirizzo_principale := v_provincia_desc;
      END IF;
       -- SIAC-5485 INIZIO
      IF  v_indirizzo_tipo_code = 'DOMICILIO' THEN
         v_indirizzo_fiscale := v_indirizzo;
         v_cap_indirizzo_fiscale := v_zip_code;
         v_comune_indirizzo_fiscale := v_comune_desc;
         v_provincia_indirizzo_fiscale := v_provincia_desc;      
      END IF;
      -- SIAC-5485 FINE
      IF  v_indirizzo_tipo_code = 'NASCITA' THEN
          v_comune_nascita := v_comune_desc;
          v_provincia_nascita := v_provincia_desc;
          v_nazione_nascita := v_nazione_desc;
      END IF;    

    END LOOP;

   v_cap_indirizzo_principale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_cap_indirizzo_principale),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
    v_comune_indirizzo_principale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_comune_indirizzo_principale),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
    v_provincia_indirizzo_principale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_provincia_indirizzo_principale),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
    v_cap_indirizzo_fiscale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_cap_indirizzo_fiscale),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u''')); -- SIAC-5485
    v_comune_indirizzo_fiscale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_comune_indirizzo_fiscale),'à','a'''),'é','e'''),'è','e'''),'ì','i'''),'ò','o'''),'ù','u''')); -- SIAC-5485
    v_provincia_indirizzo_fiscale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_provincia_indirizzo_fiscale),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u''')); -- SIAC-5485
    v_comune_nascita := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_comune_nascita),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
    v_provincia_nascita := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_provincia_nascita),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
    v_nazione_nascita := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_nazione_nascita),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));

    -- PARTE RELATIVA AL SOGGETTO FINE

    v_somma_non_soggetta := 0;  
    v_importo_imponibile := 0;
    v_importo_lordo := 0;
/*     v_ord_ts_det_importo := 0;

   SELECT rdo.somma_non_soggetta,  --> id 32 
           rdo.importo_imponibile,  --> id 33 
           totd.ord_ts_det_importo  --> id 34 e id 35 a 0
    INTO   v_somma_non_soggetta,   
           v_importo_imponibile,
           v_ord_ts_det_importo -- Ritenute a titolo d' acconto           
    FROM   siac_r_doc_onere_ordinativo_ts rdoot   
    INNER  JOIN siac_t_ordinativo_ts tot ON tot.ord_ts_id = rdoot.ord_ts_id
    INNER  JOIN siac_t_ordinativo_ts_det totd ON totd.ord_ts_id = tot.ord_ts_id
    INNER  JOIN siac_d_ordinativo_ts_det_tipo dotdt ON totd.ord_ts_det_tipo_id = dotdt.ord_ts_det_tipo_id
    INNER  JOIN siac_r_doc_onere rdo ON rdoot.doc_onere_id = rdo.doc_onere_id
    WHERE  rdoot.doc_onere_id = rec_tracciato_770.doc_onere_id
    AND    dotdt.ord_ts_det_tipo_code = 'A'  
    AND    rdoot.data_cancellazione IS NULL
    AND    tot.data_cancellazione IS NULL
    AND    totd.data_cancellazione IS NULL
    AND    dotdt.data_cancellazione IS NULL
    AND    rdo.data_cancellazione IS NULL
    AND    now() BETWEEN rdoot.validita_inizio AND COALESCE(rdoot.validita_fine, now())
    AND    now() BETWEEN tot.validita_inizio AND COALESCE(tot.validita_fine, now())
    AND    now() BETWEEN totd.validita_inizio AND COALESCE(totd.validita_fine, now())
    AND    now() BETWEEN dotdt.validita_inizio AND COALESCE(dotdt.validita_fine, now())
    AND    now() BETWEEN rdo.validita_inizio AND COALESCE(rdo.validita_fine, now());*/

    BEGIN

      SELECT COALESCE(rdo.somma_non_soggetta,0),  --> id 31 
             COALESCE(rdo.importo_imponibile,0)   --> id 32 
      INTO   STRICT v_somma_non_soggetta,   
             v_importo_imponibile    
      FROM   siac_r_doc_onere rdo
      WHERE  rdo.doc_onere_id = rec_tracciato_770.doc_onere_id
      AND    rdo.data_cancellazione IS NULL
      AND    now() BETWEEN rdo.validita_inizio AND COALESCE(rdo.validita_fine, now());
      
    EXCEPTION
              
      WHEN NO_DATA_FOUND THEN
           null;
              
    END;
    
    v_importo_lordo := v_importo_imponibile + v_somma_non_soggetta;
      
      v_ord_ts_det_importo := 0;

      BEGIN

        SELECT SUM(totd.ord_ts_det_importo) --> id 34 e id 35 a 0
        INTO   STRICT v_ord_ts_det_importo -- Ritenute a titolo d' acconto           
        FROM   siac_r_doc_onere_ordinativo_ts rdoot 
        INNER  JOIN siac_t_ordinativo_ts tot ON tot.ord_ts_id = rdoot.ord_ts_id
        INNER  JOIN siac_t_ordinativo sto ON sto.ord_id = tot.ord_id
        INNER  JOIN siac_r_ordinativo_stato ros ON sto.ord_id = ros.ord_id
        INNER  JOIN siac_d_ordinativo_stato dos ON ros.ord_stato_id = dos.ord_stato_id      
        INNER  JOIN siac_t_ordinativo_ts_det totd ON totd.ord_ts_id = tot.ord_ts_id
        INNER  JOIN siac_d_ordinativo_ts_det_tipo dotdt ON totd.ord_ts_det_tipo_id = dotdt.ord_ts_det_tipo_id
        WHERE  rdoot.doc_onere_id = rec_tracciato_770.doc_onere_id
        AND    dotdt.ord_ts_det_tipo_code = 'A'  
        AND    dos.ord_stato_code <> 'A'
        AND    rdoot.data_cancellazione IS NULL
        AND    tot.data_cancellazione IS NULL
        AND    sto.data_cancellazione IS NULL
        AND    ros.data_cancellazione IS NULL
        AND    dos.data_cancellazione IS NULL    
        AND    totd.data_cancellazione IS NULL
        AND    dotdt.data_cancellazione IS NULL
        AND    now() BETWEEN rdoot.validita_inizio AND COALESCE(rdoot.validita_fine, now())
        AND    now() BETWEEN tot.validita_inizio AND COALESCE(tot.validita_fine, now())
        AND    now() BETWEEN sto.validita_inizio AND COALESCE(sto.validita_fine, now())
        AND    now() BETWEEN ros.validita_inizio AND COALESCE(ros.validita_fine, now())
        AND    now() BETWEEN dos.validita_inizio AND COALESCE(dos.validita_fine, now())
        AND    now() BETWEEN totd.validita_inizio AND COALESCE(totd.validita_fine, now())
        AND    now() BETWEEN dotdt.validita_inizio AND COALESCE(dotdt.validita_fine, now());

      EXCEPTION
                
        WHEN NO_DATA_FOUND THEN
             null;
                
      END;

IF rec_tracciato_770.testo = 'F' THEN

  BEGIN

    v_aliquota := 0;

    SELECT roa.percentuale
    INTO   STRICT v_aliquota
    FROM   siac_d_onere sdo, siac_r_onere_attr roa, siac_t_attr ta
    WHERE  sdo.onere_id = rec_tracciato_770.onere_id
    AND    sdo.onere_id = roa.onere_id    
    AND    roa.attr_id = ta.attr_id
    AND    ta.attr_code = 'ALIQUOTA_SOGG'
    AND    sdo.data_cancellazione IS NULL
    AND    roa.data_cancellazione IS NULL
    AND    ta.data_cancellazione IS NULL
    AND    now() BETWEEN sdo.validita_inizio AND COALESCE(sdo.validita_fine, now())
    AND    now() BETWEEN roa.validita_inizio AND COALESCE(roa.validita_fine, now())
    AND    now() BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, now());

  EXCEPTION
                
    WHEN NO_DATA_FOUND THEN
         null;
                
  END;

END IF;

IF rec_tracciato_770.testo = 'C' THEN

      v_importo_carico_ente := 0;
      v_importo_carico_soggetto := 0; 

      /* verifico quante quote ci sono relative alla fattura */
  /*    v_numeroQuoteFattura := 0;
  		            
      SELECT count(*)
      INTO   v_numeroQuoteFattura
      FROM   siac_t_subdoc
      WHERE  doc_id= rec_tracciato_770.doc_id;
                
      IF NOT FOUND THEN
          v_numeroQuoteFattura := 0;
      END IF;*/

      FOR rec_inps IN  
      SELECT td.doc_importo IMPORTO_FATTURA,
             ts.subdoc_importo IMPORTO_QUOTA,
             rdo.importo_carico_ente,
             --totd.ord_ts_det_importo
             --rdo.importo_carico_soggetto
             rdo.doc_onere_id
      FROM  siac_t_ordinativo sto
      INNER JOIN siac_r_ordinativo_stato ros ON sto.ord_id = ros.ord_id
      INNER JOIN siac_d_ordinativo_stato dos ON ros.ord_stato_id = dos.ord_stato_id
      INNER JOIN siac_t_ordinativo_ts tot ON tot.ord_id = sto.ord_id
      INNER JOIN siac_t_ordinativo_ts_det totd ON totd.ord_ts_id = tot.ord_ts_id
      INNER JOIN siac_d_ordinativo_ts_det_tipo dotdt ON dotdt.ord_ts_det_tipo_id = totd.ord_ts_det_tipo_id
      INNER JOIN siac_r_subdoc_ordinativo_ts rsot ON rsot.ord_ts_id = tot.ord_ts_id
      INNER JOIN siac_t_subdoc ts ON ts.subdoc_id = rsot.subdoc_id
      INNER JOIN siac_t_doc td ON td.doc_id = ts.doc_id
      INNER JOIN siac_r_doc_onere rdo ON rdo.doc_id = td.doc_id
      INNER JOIN siac_d_onere sdo ON sdo.onere_id = rdo.onere_id
      INNER JOIN siac_d_onere_tipo sdot ON sdot.onere_tipo_id = sdo.onere_tipo_id
      WHERE td.doc_id = rec_tracciato_770.doc_id
      AND   dos.ord_stato_code <> 'A'
      AND   dotdt.ord_ts_det_tipo_code = 'A'
      AND   sdot.onere_tipo_code = 'INPS'
      AND   sto.data_cancellazione IS NULL
      AND   ros.data_cancellazione IS NULL
      AND   dos.data_cancellazione IS NULL
      AND   tot.data_cancellazione IS NULL
      AND   totd.data_cancellazione IS NULL
      AND   dotdt.data_cancellazione IS NULL
      AND   rsot.data_cancellazione IS NULL
      AND   ts.data_cancellazione IS NULL
      AND   td.data_cancellazione IS NULL
      AND   rdo.data_cancellazione IS NULL
      AND   sdo.data_cancellazione IS NULL
      AND   sdot.data_cancellazione IS NULL
      AND   now() BETWEEN sto.validita_inizio AND COALESCE(sto.validita_fine, now())
      AND   now() BETWEEN ros.validita_inizio AND COALESCE(ros.validita_fine, now())
      AND   now() BETWEEN dos.validita_inizio AND COALESCE(dos.validita_fine, now())
      AND   now() BETWEEN tot.validita_inizio AND COALESCE(tot.validita_fine, now())
      AND   now() BETWEEN totd.validita_inizio AND COALESCE(totd.validita_fine, now())
      AND   now() BETWEEN dotdt.validita_inizio AND COALESCE(dotdt.validita_fine, now())
      AND   now() BETWEEN rsot.validita_inizio AND COALESCE(rsot.validita_fine, now())
      AND   now() BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, now())
      AND   now() BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, now())
      AND   now() BETWEEN rdo.validita_inizio AND COALESCE(rdo.validita_fine, now())
      AND   now() BETWEEN sdo.validita_inizio AND COALESCE(sdo.validita_fine, now())
      AND   now() BETWEEN sdot.validita_inizio AND COALESCE(sdot.validita_fine, now())
       
      LOOP
      
        BEGIN

          SELECT SUM(totd.ord_ts_det_importo)
          INTO   STRICT v_importo_carico_soggetto           
          FROM   siac_r_doc_onere_ordinativo_ts rdoot 
          INNER  JOIN siac_t_ordinativo_ts tot ON tot.ord_ts_id = rdoot.ord_ts_id
          INNER  JOIN siac_t_ordinativo sto ON sto.ord_id = tot.ord_id
          INNER  JOIN siac_r_ordinativo_stato ros ON sto.ord_id = ros.ord_id
          INNER  JOIN siac_d_ordinativo_stato dos ON ros.ord_stato_id = dos.ord_stato_id      
          INNER  JOIN siac_t_ordinativo_ts_det totd ON totd.ord_ts_id = tot.ord_ts_id
          INNER  JOIN siac_d_ordinativo_ts_det_tipo dotdt ON totd.ord_ts_det_tipo_id = dotdt.ord_ts_det_tipo_id
          WHERE  rdoot.doc_onere_id = rec_inps.doc_onere_id
          AND    dotdt.ord_ts_det_tipo_code = 'A'  
          AND    dos.ord_stato_code <> 'A'
          AND    rdoot.data_cancellazione IS NULL
          AND    tot.data_cancellazione IS NULL
          AND    sto.data_cancellazione IS NULL
          AND    ros.data_cancellazione IS NULL
          AND    dos.data_cancellazione IS NULL    
          AND    totd.data_cancellazione IS NULL
          AND    dotdt.data_cancellazione IS NULL
          AND    now() BETWEEN rdoot.validita_inizio AND COALESCE(rdoot.validita_fine, now())
          AND    now() BETWEEN tot.validita_inizio AND COALESCE(tot.validita_fine, now())
          AND    now() BETWEEN sto.validita_inizio AND COALESCE(sto.validita_fine, now())
          AND    now() BETWEEN ros.validita_inizio AND COALESCE(ros.validita_fine, now())
          AND    now() BETWEEN dos.validita_inizio AND COALESCE(dos.validita_fine, now())
          AND    now() BETWEEN totd.validita_inizio AND COALESCE(totd.validita_fine, now())
          AND    now() BETWEEN dotdt.validita_inizio AND COALESCE(dotdt.validita_fine, now());

        EXCEPTION
                  
          WHEN NO_DATA_FOUND THEN
               null;
                  
        END;    
      
          --v_importo_carico_soggetto := rec_inps.importo_carico_soggetto;
          --v_importo_carico_ente := rec_inps.importo_carico_ente;
          v_percQuota := 0;    	          
                                                  
          -- calcolo la percentuale della quota corrente rispetto
          -- al totale fattura.
          v_percQuota := COALESCE(rec_inps.IMPORTO_QUOTA,0)*100/COALESCE(rec_inps.IMPORTO_FATTURA,0);                
                                                       
          --raise notice 'IRAP ORD_ID=%,  ORD_NUM =%', elencoMandati.ord_id,numero_mandato; 
          --raise notice 'ESTRATTO: IMPON =%, RITEN = %, ENTE =%', elencoMandati.IMPORTO_IMPONIBILE,elencoMandati.IMPOSTA,elencoMandati.IMPORTO_CARICO_ENTE;          
          --raise notice 'FATTURA_ID = %, NUMERO_QUOTE = %, IMPORTO FATT = %, IMPORTO QUOTA = %, PERC_QUOTA = %',elencoMandati.doc_id,numeroQuoteFattura, elencoMandati.IMPORTO_FATTURA, elencoMandati.IMPORTO_QUOTA,  percQuota;
                                
          -- la fattura e' la stessa della quota precedente.       		      
          ----IF v_idFatturaOld = rec_tracciato_770.doc_id THEN
              ----v_contaQuotaInps := v_contaQuotaInps + 1;
              --raise notice 'Fattura uguale alla prec: %, num_quota = %',idFatturaOld, contaQuotaIrap;
              -- e' l'ultima quota della fattura:
              -- gli importi sono quelli totali meno quelli delle quote
              -- precedenti, per evitare problemi di arrotondamento.            
  /*          IF v_contaQuotaInps = v_numeroQuoteFattura THEN
              --raise notice 'ULTIMA QUOTA'; 
              v_importo_imponibile_inps := v_importo_imponibile - v_importoParzInpsImpon;
              v_importo_ritenuta_inps := v_importo_carico_soggetto - v_importoParzInpsRiten;
              v_importo_ente_inps := rec_inps.importo_carico_ente - v_importoParzInpsEnte;                                  
              -- azzero gli importi parziali per fattura
              v_importoParzInpsImpon := 0;
              v_importoParzInpsRiten := 0;
              v_importoParzInpsEnte := 0;
              v_importoParzInpsNetto := 0;
              v_contaQuotaInps := 0;      
            ELSE*/
              --raise notice 'ALTRA QUOTA';
              --v_importo_imponibile_inps := v_importo_imponibile*v_percQuota/100;
              --v_importo_ritenuta_inps := v_importo_carico_soggetto*v_percQuota/100; 
              ----v_importo_ente_inps := rec_inps.importo_carico_ente*v_percQuota/100;
              --v_importo_netto_inps := v_importo_lordo-v_importo_ritenuta_inps;                      
              -- sommo l'importo della quota corrente
              -- al parziale per fattura.
              --v_importoParzInpsImpon := v_importoParzInpsImpon + v_importo_imponibile_inps;
              --v_importoParzInpsRiten := v_importoParzInpsRiten + v_importo_ritenuta_inps;
              ----v_importoParzInpsEnte :=  v_importoParzInpsEnte + v_importo_ente_inps;
              --v_importoParzInpsNetto := v_importoParzInpsNetto + v_importo_netto_inps;                      
            --END IF;      
          ----ELSE -- fattura diversa dalla precedente
            --raise notice 'Fattura diversa dalla prec: %, %',idFatturaOld,elencoMandati.doc_id;
            --v_importo_imponibile_inps := v_importo_imponibile*v_percQuota/100;
            --v_importo_ritenuta_inps := v_importo_carico_soggetto*v_percQuota/100; 
            v_importo_ente_inps := COALESCE(rec_inps.importo_carico_ente,0)*v_percQuota/100;
            --v_importo_netto_inps := v_importo_lordo - v_importo_ritenuta_inps;
            -- imposto l'importo della quota corrente
            -- al parziale per fattura.            
            --v_importoParzInpsImpon := v_importo_imponibile_inps;
            --v_importoParzInpsRiten := v_importo_ritenuta_inps;
            ----v_importoParzInpsEnte := v_importo_ente_inps;
            --v_importoParzInpsNetto := v_importo_netto_inps;
            ----v_contaQuotaInps := 1;            
          ----END IF;                                    
          --raise notice 'ParzImpon = %, ParzRiten = %, ParzEnte = %, ParzNetto = %', importoParzIrapImpon,importoParzIrapRiten,importoParzIrapEnte,importoParzIrapNetto;                
          --raise notice 'IMPON =%, RITEN = %, ENTE =%, NETTO= %', importo_imponibile_irap, importo_ritenuta_irap,importo_ente_irap,importo_ente_irap; 
          ----v_idFatturaOld := rec_tracciato_770.doc_id;    
          v_importo_carico_ente :=  v_importo_carico_ente + v_importo_ente_inps;  
      END LOOP;
  
    END IF;  
           
    IF rec_tracciato_770.testo = 'F' THEN
       null;
       -- Aliquota
       -- Ritenute Operate
    END IF;
        
    IF rec_tracciato_770.testo = 'C' THEN
    
      INSERT INTO siac.tracciato_770_quadro_c_temp
       (
        elab_id_temp,
        elab_id_det_temp,
        ente_proprietario_id,
        tipo_record,
        codice_fiscale_ente,
        codice_fiscale_percipiente,
        tipo_percipiente,
        cognome_denominazione,
        nome,
        sesso,
        data_nascita,
        comune_nascita,
        provincia_nascita,
        comune_domicilio_spedizione,
        provincia_domicilio_spedizione,
        indirizzo_domicilio_spedizione,
        cap_domicilio_spedizione,
        percipienti_esteri_cod_fiscale,
        causale,
        ammontare_lordo_corrisposto,
        altre_somme_no_ritenute,
        imponibile_b,
        ritenute_titolo_acconto_b,
        ritenute_titolo_imposta_b,
        contr_prev_carico_sog_erogante,
        contr_prev_carico_sog_percipie,
        codice,
        anno_competenza,
        codice_tributo
        )
         VALUES
        ( v_elab_id,
          v_elab_id_det_temp,
          p_ente_proprietario_id,
          v_tipo_record,
          v_codice_fiscale_ente,
          v_codice_fiscale_percipiente,
          v_tipo_percipiente,
          v_cognome,
          v_nome,
          v_sesso,
          v_data_nascita,    
          COALESCE(v_comune_nascita, v_nazione_nascita), 
          v_provincia_nascita,
          v_comune_indirizzo_principale, 
          v_provincia_indirizzo_principale, 
          v_indirizzo_principale, 
          v_cap_indirizzo_principale,           
          v_codice_fiscale_estero,
          v_causale,
          v_importo_lordo,
          v_somma_non_soggetta,   
          v_importo_imponibile,
          v_ord_ts_det_importo,
          0,
          v_importo_carico_ente,
          v_importo_carico_soggetto,      
          v_codice,
          p_anno_elab,
          v_codice_tributo
        );         
    
    END IF;    
    
    IF rec_tracciato_770.testo = 'F' THEN    
    
      INSERT INTO siac.tracciato_770_quadro_f_temp
       (
        elab_id_temp,
        elab_id_det_temp,
        ente_proprietario_id,
        tipo_record,
        codice_fiscale_ente,
        codice_fiscale_percipiente,
        tipo_percipiente,
        cognome_denominazione,
        nome,
        sesso,
        data_nascita,
        comune_nascita,
        provincia_nascita,
        comune_domicilio_fiscale,
        provincia_domicilio_fiscale,
        indirizzo_domicilio_fiscale,
        cap_domicilio_spedizione,
        codice_identif_fiscale_estero,
        causale,
        ammontare_lordo_corrisposto,
        altre_somme_no_ritenute,
        aliquota,
        ritenute_operate,
        ritenute_sospese,
        rimborsi,
        anno_competenza,
        codice_tributo
        )
         VALUES
        ( v_elab_id,
          v_elab_id_det_temp,
          p_ente_proprietario_id,
          v_tipo_record,
          v_codice_fiscale_ente,
          v_codice_fiscale_percipiente,
          v_tipo_percipiente,
          v_cognome,
          v_nome,
          v_sesso,
          v_data_nascita,    
          COALESCE(v_comune_nascita, v_nazione_nascita), 
          v_provincia_nascita,
          COALESCE(v_comune_indirizzo_fiscale, v_comune_indirizzo_principale), 
          COALESCE(v_provincia_indirizzo_fiscale, v_provincia_indirizzo_principale), 
          COALESCE(v_indirizzo_fiscale, v_indirizzo_principale), 
          COALESCE(v_cap_indirizzo_fiscale, v_cap_indirizzo_principale),           
          v_codice_fiscale_estero,
          v_causale,
          v_importo_lordo,
          v_somma_non_soggetta,   
          v_aliquota,
          v_ord_ts_det_importo,
          0,
          0,    
          p_anno_elab,
          v_codice_tributo
        );         
     
    END IF;
    
  v_elab_id_det_temp := v_elab_id_det_temp + 1;
     
END LOOP;

IF p_quadro_c_f IN ('C','T') THEN
  v_elab_id_det := 1;
  -- Parte relativa al caricamento della tabella finale
  FOR rec_tracciato_fin_c IN
  SELECT   
    tipo_record,
    rpad(substring(coalesce(codice_fiscale_ente,'') from 1 for 16), 16, ' ') codice_fiscale_ente,
    rpad(substring(coalesce(codice_fiscale_percipiente,'') from 1 for 16), 16, ' ') codice_fiscale_percipiente,
    tipo_percipiente,
    rpad(substring(coalesce(cognome_denominazione,'') from 1 for 24), 24, ' ') cognome_denominazione,
    rpad(substring(coalesce(nome,'') from 1 for 20), 20, ' ') nome,
    rpad(coalesce(sesso,''), 1, ' ') sesso,
    lpad(coalesce(to_char(data_nascita,'yyyymmdd'),''),8,'0') data_nascita,
    rpad(substring(coalesce(comune_nascita,'') from 1 for 21), 21, ' ') comune_nascita,
    rpad(substring(coalesce(provincia_nascita,'') from 1 for 2), 2, ' ') provincia_nascita,
    rpad(substring(coalesce(comune_domicilio_spedizione,'') from 1 for 21), 21, ' ') comune_domicilio_spedizione,
    rpad(substring(coalesce(provincia_domicilio_spedizione,'') from 1 for 2), 2, ' ') provincia_domicilio_spedizione,
    rpad(substring(coalesce(indirizzo_domicilio_spedizione,'') from 1 for 35), 35, ' ') indirizzo_domicilio_spedizione,
    rpad(substring(coalesce(cap_domicilio_spedizione,'') from 1 for 5), 5, ' ') cap_domicilio_spedizione,
    rpad(substring(coalesce(percipienti_esteri_cod_fiscale,'') from 1 for 20), 20, ' ') percipienti_esteri_cod_fiscale,
    rpad(substring(coalesce(causale,'') from 1 for 2), 2, ' ') causale,
    rpad(substring(coalesce(codice,'') from 1 for 1), 1, ' ') codice,
    anno_competenza,
    lpad((SUM(coalesce(ammontare_lordo_corrisposto,0))*100)::bigint::varchar, 11, '0')::varchar ammontare_lordo_corrisposto,
    lpad((SUM(coalesce(altre_somme_no_ritenute,0))*100)::bigint::varchar, 11, '0') altre_somme_no_ritenute,
    lpad((SUM(coalesce(imponibile_b,0))*100)::bigint::varchar, 11, '0') imponibile_b,
    lpad((SUM(coalesce(ritenute_titolo_acconto_b,0))*100)::bigint::varchar, 11, '0') ritenute_titolo_acconto_b,
    lpad((SUM(coalesce(ritenute_titolo_imposta_b,0))*100)::bigint::varchar, 11, '0') ritenute_titolo_imposta_b,
    lpad((SUM(coalesce(contr_prev_carico_sog_erogante,0))*100)::bigint::varchar, 11, '0') contr_prev_carico_sog_erogante,
    lpad((SUM(coalesce(contr_prev_carico_sog_percipie,0))*100)::bigint::varchar, 11, '0') contr_prev_carico_sog_percipie,
    lpad(codice_tributo,4,'0') codice_tributo
  FROM tracciato_770_quadro_c_temp
  WHERE elab_id_temp = v_elab_id
  AND   ente_proprietario_id = p_ente_proprietario_id
  AND   anno_competenza = p_anno_elab
  GROUP BY
    tipo_record,
    codice_fiscale_ente,
    codice_fiscale_percipiente,
    tipo_percipiente,
    cognome_denominazione,
    nome,
    sesso,
    data_nascita,
    comune_nascita,
    provincia_nascita,
    comune_domicilio_spedizione,
    provincia_domicilio_spedizione,
    indirizzo_domicilio_spedizione,
    cap_domicilio_spedizione,
    percipienti_esteri_cod_fiscale,
    causale,
    codice,
    anno_competenza,
    codice_tributo
    
  LOOP
            
      INSERT INTO siac.tracciato_770_quadro_c
        ( 
          elab_id,
          elab_id_det,
          elab_data,
          ente_proprietario_id,
          tipo_record,
          codice_fiscale_ente,
          codice_fiscale_percipiente,
          tipo_percipiente,
          cognome_denominazione,
          nome,
          sesso,
          data_nascita,
          comune_nascita,
          provincia_nascita,
          colonna_1,
          colonna_2 ,
          comune_domicilio_fiscale_prec,
          comune_domicilio_spedizione,
          provincia_domicilio_spedizione,
          colonna_3,
          esclusione_precompilata,
          categorie_particolari,
          indirizzo_domicilio_spedizione,
          cap_domicilio_spedizione,
          colonna_4,
          codice_sede,
          comune_domicilio_fiscale,
          rappresentante_codice_fiscale,
          percipienti_esteri_no_res,
          percipienti_esteri_localita,
          percipienti_esteri_stato,
          percipienti_esteri_cod_fiscale,
          ex_causale,
          ammontare_lordo_corrisposto,
          somme_no_ritenute_regime_conv,
          altre_somme_no_ritenute,
          imponibile_b,
          ritenute_titolo_acconto_b,
          ritenute_titolo_imposta_b,
          ritenute_sospese_b,
          anticipazione,
          anno,
          add_reg_titolo_acconto_b,
          add_reg_titolo_imposta_b,
          add_reg_sospesa_b,
          imponibile_anni_prec,
          ritenute_operate_anni_prec,
          contr_prev_carico_sog_erogante,
          contr_prev_carico_sog_percipie,
          spese_rimborsate,
          ritenute_rimborsate,
          colonna_5,
          percipienti_esteri_via_numciv,
          colonna_6,
          eventi_eccezionali,
          somme_prima_data_fallimento,
          somme_curatore_commissario,
          colonna_7,
          colonna_8,
          codice,
          colonna_9,
          codice_fiscale_e,
          imponibile_e,
          ritenute_titolo_acconto_e,
          ritenute_titolo_imposta_e,
          ritenute_sospese_e,
          add_reg_titolo_acconto_e,
          add_reg_titolo_imposta_e,
          add_reg_sospesa_e,
          add_com_titolo_acconto_e,
          add_com_titolo_imposta_e,
          add_com_sospesa_e,
          add_com_titolo_acconto_b,
          add_com_titolo_imposta_b,
          add_com_sospesa_b,
          colonna_10,
          codice_fiscale_redd_diversi_f,
          codice_fiscale_pignoramento_f,
          codice_fiscale_esproprio_f,
          colonna_11,
          colonna_12,
          colonna_13,
          colonna_14,
          colonna_15,
          colonna_16,
          colonna_17,
          colonna_18,
          colonna_19,
          colonna_20,
          colonna_21,
          colonna_22,
          colonna_23,
          codice_fiscale_ente_prev,
          denominazione_ente_prev,
          codice_ente_prev,
          codice_azienda,
          categoria,
          altri_contributi,
          importo_altri_contributi,
          contributi_dovuti,
          contributi_versati,
          causale,
          colonna_24,
          colonna_25,
          colonna_26,
          colonna_27,
          anno_competenza,
          ex_ente,
          progressivo,
          matricola,
          codice_tributo,
          versione_tracciato_procsi,
          colonna_28,
          caratteri_controllo_1,
          caratteri_controllo_2
        )
      VALUES
        ( v_elab_id,
          v_elab_id_det,
          now(),
          p_ente_proprietario_id,
          rec_tracciato_fin_c.tipo_record,
          rec_tracciato_fin_c.codice_fiscale_ente,
          rec_tracciato_fin_c.codice_fiscale_percipiente,
          rec_tracciato_fin_c.tipo_percipiente,
          rec_tracciato_fin_c.cognome_denominazione,
          rec_tracciato_fin_c.nome,
          rec_tracciato_fin_c.sesso,
          rec_tracciato_fin_c.data_nascita,
          rec_tracciato_fin_c.comune_nascita,
          rec_tracciato_fin_c.provincia_nascita,
          rpad(' ',21,' '),
          rpad(' ',2,' '),
          rpad(' ',4,' '),
          rec_tracciato_fin_c.comune_domicilio_spedizione,
          rec_tracciato_fin_c.provincia_domicilio_spedizione,
          rpad(' ',3,' '),
          rpad(' ',1,' '),
          rpad(' ',2,' '),
          rec_tracciato_fin_c.indirizzo_domicilio_spedizione,
          rec_tracciato_fin_c.cap_domicilio_spedizione,
          rpad(' ',57,' '),
          rpad(' ',3,' '),
          rpad(' ',4,' '),
          rpad(' ',16,' '),
          rpad(' ',1,' '),
          rpad(' ',35,' '),
          lpad('0',3,'0'),
          rec_tracciato_fin_c.percipienti_esteri_cod_fiscale,
          rpad(' ',1,' '),
          rec_tracciato_fin_c.ammontare_lordo_corrisposto,
          lpad('0',11,'0'),
          rec_tracciato_fin_c.altre_somme_no_ritenute,
          rec_tracciato_fin_c.imponibile_b,
          rec_tracciato_fin_c.ritenute_titolo_acconto_b,
          rec_tracciato_fin_c.ritenute_titolo_imposta_b,
          lpad('0',11,'0'),
          lpad('0',1,'0'),
          lpad('0',4,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          rec_tracciato_fin_c.contr_prev_carico_sog_erogante,
          rec_tracciato_fin_c.contr_prev_carico_sog_percipie,
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          rpad(' ',2,' '),
          rpad(' ',35,' '),
          rpad(' ',1,' '),
          lpad('0',1,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          rpad(' ',11,' '),
          rpad(' ',1,' '),        
          rec_tracciato_fin_c.codice,
          rpad(' ',9,' '),
          rpad(' ',16,' '),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          rpad(' ',103,' '),
          rpad(' ',16,' '),
          rpad(' ',16,' '),
          rpad(' ',16,' '),
          rpad(' ',16,' '),
          rpad(' ',1,' '),
          rpad(' ',2,' '),
          rpad(' ',4,' '),
          rpad(' ',4,' '),
          rpad(' ',4,' '),
          rpad(' ',7,' '),
          rpad(' ',6,' '),
          rpad(' ',4,' '),
          rpad(' ',7,' '),
          rpad(' ',4,' '),
          rpad(' ',9,' '),
          rpad(' ',1,' '),
          rpad(' ',16,' '),
          rpad(' ',30,' '),
          rpad(' ',1,' '),
          rpad(' ',15,' '),
          rpad(' ',1,' '),
          lpad('0',1,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          rec_tracciato_fin_c.causale,
          rpad(' ',1044,' '),
          rpad(' ',4,' '),
          rpad(' ',4,' '),          
          rpad(' ',1818,' '),
          rec_tracciato_fin_c.anno_competenza,
          rpad(p_ex_ente,4,' '),
          lpad((v_elab_id_det)::varchar,7,'0'),
          lpad((v_matricola_c)::varchar,7,'0'),
          rec_tracciato_fin_c.codice_tributo,
          'V12',
          rpad(' ',9,' '),
          'A',
          NULL
        );      
    
       v_matricola_c := 8000000 + v_elab_id_det;
       v_elab_id_det := v_elab_id_det + 1;
       
  END LOOP;
  
END IF;

IF p_quadro_c_f IN ('F','T') THEN
  v_elab_id_det := 1;
  -- Parte relativa al caricamento della tabella finale
  FOR rec_tracciato_fin_f IN
  SELECT   
    tipo_record,
    rpad(substring(coalesce(codice_fiscale_ente,'') from 1 for 16), 16, ' ') codice_fiscale_ente,
    rpad(substring(coalesce(codice_fiscale_percipiente,'') from 1 for 16), 16, ' ') codice_fiscale_percipiente,
    tipo_percipiente,
    rpad(substring(coalesce(cognome_denominazione,'') from 1 for 24), 24, ' ') cognome_denominazione,
    rpad(substring(coalesce(nome,'') from 1 for 20), 20, ' ') nome,
    rpad(coalesce(sesso,''), 1, ' ') sesso,
    lpad(coalesce(to_char(data_nascita,'yyyymmdd'),''),8,'0') data_nascita,
    rpad(substring(coalesce(comune_nascita,'') from 1 for 21), 21, ' ') comune_nascita,
    rpad(substring(coalesce(provincia_nascita,'') from 1 for 2), 2, ' ') provincia_nascita,
    rpad(substring(coalesce(comune_domicilio_fiscale,'') from 1 for 21), 21, ' ') comune_domicilio_fiscale,
    rpad(substring(coalesce(provincia_domicilio_fiscale,'') from 1 for 2), 2, ' ') provincia_domicilio_fiscale,
    rpad(substring(coalesce(indirizzo_domicilio_fiscale,'') from 1 for 35), 35, ' ') indirizzo_domicilio_fiscale,
    rpad(substring(coalesce(cap_domicilio_spedizione,'') from 1 for 5), 5, ' ') cap_domicilio_spedizione,
    rpad(substring(coalesce(codice_identif_fiscale_estero,'') from 1 for 20), 20, ' ') codice_identif_fiscale_estero,
    rpad(substring(coalesce(causale,'') from 1 for 1), 1, ' ') causale,
    anno_competenza,
    lpad((SUM(coalesce(ammontare_lordo_corrisposto,0))*100)::bigint::varchar, 13, '0')::varchar ammontare_lordo_corrisposto,
    lpad((SUM(coalesce(altre_somme_no_ritenute,0))*100)::bigint::varchar, 13, '0') altre_somme_no_ritenute,
    lpad((SUM(coalesce(ritenute_operate,0))*100)::bigint::varchar, 13, '0') ritenute_operate,
    lpad((SUM(coalesce(ritenute_sospese,0))*100)::bigint::varchar, 13, '0') ritenute_sospese,
    lpad((SUM(coalesce(rimborsi,0))*100)::bigint::varchar, 13, '0') rimborsi,
    lpad(codice_tributo,4,'0') codice_tributo,
    -- lpad((coalesce(aliquota,0)*100)::bigint::varchar,5,'0') aliquota -- SIAC-5951
    lpad(coalesce(aliquota,0)::bigint::varchar,5,'0') aliquota -- SIAC-5951
  FROM tracciato_770_quadro_f_temp
  WHERE elab_id_temp = v_elab_id
  AND   ente_proprietario_id = p_ente_proprietario_id
  AND   anno_competenza = p_anno_elab
  GROUP BY
    tipo_record,
    codice_fiscale_ente,
    codice_fiscale_percipiente,
    tipo_percipiente,
    cognome_denominazione,
    nome,
    sesso,
    data_nascita,
    comune_nascita,
    provincia_nascita,
    comune_domicilio_fiscale,
    provincia_domicilio_fiscale,
    indirizzo_domicilio_fiscale,
    cap_domicilio_spedizione,
    codice_identif_fiscale_estero,
    causale,
    anno_competenza,
    codice_tributo,
    aliquota
    
  LOOP
            
      INSERT INTO siac.tracciato_770_quadro_f
        ( 
          elab_id,
          elab_id_det,
          elab_data,
          ente_proprietario_id,
          tipo_record,
          codice_fiscale_ente,
          codice_fiscale_percipiente,
          tipo_percipiente,
          cognome_denominazione,
          nome,
          sesso,
          data_nascita,
          comune_nascita,
          provincia_nascita,
          comune_domicilio_fiscale,
          provincia_domicilio_fiscale,
          indirizzo_domicilio_fiscale,
          colonna_1,
          colonna_2,
          colonna_3,
          colonna_4,
          cap_domicilio_spedizione,
          colonna_5,
          codice_stato_estero,
          codice_identif_fiscale_estero,
          causale,
          ammontare_lordo_corrisposto,
          somme_no_soggette_ritenuta,
          aliquota,
          ritenute_operate,
          ritenute_sospese,
          codice_fiscale_rappr_soc,
          cognome_denom_rappr_soc,
          nome_rappr_soc,
          sesso_rappr_soc,
          data_nascita_rappr_soc,
          comune_nascita_rappr_soc,
          provincia_nascita_rappr_soc,
          comune_dom_fiscale_rappr_soc,
          provincia_rappr_soc,
          indirizzo_rappr_soc,
          codice_stato_estero_rappr_soc,
          rimborsi,
          colonna_6,
          colonna_7,
          colonna_8,
          colonna_9,
          colonna_10,
          colonna_11,
          colonna_12,
          colonna_13,
          colonna_14,
          colonna_15,
          colonna_16,
          colonna_17,
          colonna_18,
          colonna_19,
          colonna_20,
          colonna_21,
          colonna_22,
          colonna_23,
          anno_competenza,
          ex_ente,
          progressivo,
          matricola,
          codice_tributo,
          versione_tracciato_procsi,
          colonna_28,
          caratteri_controllo_1, 
          caratteri_controllo_2
        )
      VALUES
        ( v_elab_id,
          v_elab_id_det,
          now(),
          p_ente_proprietario_id,
          rec_tracciato_fin_f.tipo_record,
          rec_tracciato_fin_f.codice_fiscale_ente,
          rec_tracciato_fin_f.codice_fiscale_percipiente,
          rec_tracciato_fin_f.tipo_percipiente,
          rec_tracciato_fin_f.cognome_denominazione,
          rec_tracciato_fin_f.nome,
          rec_tracciato_fin_f.sesso,
          rec_tracciato_fin_f.data_nascita,
          rec_tracciato_fin_f.comune_nascita,
          rec_tracciato_fin_f.provincia_nascita,
          rec_tracciato_fin_f.comune_domicilio_fiscale,
          rec_tracciato_fin_f.provincia_domicilio_fiscale,
          rec_tracciato_fin_f.indirizzo_domicilio_fiscale,
          rpad(' ',60,' '),
          rpad(' ',21,' '),
          rpad(' ',2,' '),
          rpad(' ',35,' '),
          rec_tracciato_fin_f.cap_domicilio_spedizione,
          rpad(' ',31,' '),
          lpad('0',3,'0'),
          rec_tracciato_fin_f.codice_identif_fiscale_estero,
          rec_tracciato_fin_f.causale,
          rec_tracciato_fin_f.ammontare_lordo_corrisposto,
          rec_tracciato_fin_f.altre_somme_no_ritenute,
          rec_tracciato_fin_f.aliquota,
          rec_tracciato_fin_f.ritenute_operate,
          rec_tracciato_fin_f.ritenute_sospese,
          rpad(' ',16,' '),
          rpad(' ',60,' '),
          rpad(' ',20,' '),
          rpad(' ',1,' '),
          lpad('0',8,'0'),
          rpad(' ',21,' '),
          rpad(' ',2,' '),
          rpad(' ',21,' '),
          rpad(' ',2,' '),
          rpad(' ',35,' '),
          lpad('0',3,'0'),
          rec_tracciato_fin_f.rimborsi,
          rpad(' ',315,' '),
          rpad(' ',16,' '),       
          rpad(' ',1,' '),      
          rpad(' ',2,' '),
          rpad(' ',4,' '),
          rpad(' ',4,' '),
          rpad(' ',4,' '),
          rpad(' ',7,' '),
          rpad(' ',6,' '),
          rpad(' ',4,' '),
          rpad(' ',7,' '),
          rpad(' ',4,' '),
          rpad(' ',9,' '),
          rpad(' ',1,' '),
          rpad(' ',1143,' '),
          rpad(' ',4,' '),    
          rpad(' ',4,' '),
          rpad(' ',1818,' '),                                                                                                                                              
          rec_tracciato_fin_f.anno_competenza,
          rpad(p_ex_ente,4,' '),
          lpad((v_elab_id_det)::varchar,7,'0'),
          lpad((v_matricola_f)::varchar,7,'0'),
          rec_tracciato_fin_f.codice_tributo,
          'V12',
          rpad(' ',9,' '),
          'A',
          NULL
        );      
    
       v_matricola_f := 9000000 + v_elab_id_det;
       v_elab_id_det := v_elab_id_det + 1;
       
  END LOOP;
             
END IF;  

messaggioRisultato := 'OK';

-- Aggiornamento mif_t_flusso_elaborato per flusso_elab_mif_id = v_elab_id
UPDATE  mif_t_flusso_elaborato
SET (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
    (elab_mif_esito_ok,'Elaborazione conclusa [stato OK] per tipo flusso '||v_tipo_flusso, now())
WHERE flusso_elab_mif_id = v_elab_id;

RETURN messaggioRisultato;

EXCEPTION

	WHEN OTHERS  THEN
         messaggioRisultato := SUBSTRING(UPPER(SQLERRM) from 1 for 100);
         -- RETURN NEXT;
		 messaggioRisultato := UPPER(messaggioRisultato);
        
        INSERT INTO mif_t_flusso_elaborato
        (flusso_elab_mif_data,
         flusso_elab_mif_esito,
         flusso_elab_mif_esito_msg,
         flusso_elab_mif_file_nome,
         flusso_elab_mif_tipo_id,
         flusso_elab_mif_id_flusso_oil,
         validita_inizio,
         validita_fine,
         ente_proprietario_id,
         login_operazione)
         (SELECT now(),
                 elab_mif_esito_ko,
                 'Elaborazione conclusa con errori per tipo flusso '||v_tipo_flusso||'.'||messaggioRisultato,
                 tipo.flusso_elab_mif_nome_file,
                 tipo.flusso_elab_mif_tipo_id,
                 null, -- flussoElabMifOilId, -- non usato per questo tipo di flusso
                 now(),
                 now(),
                 p_ente_proprietario_id,
                 v_login
          FROM mif_d_flusso_elaborato_tipo tipo
          WHERE tipo.ente_proprietario_id = p_ente_proprietario_id
          AND   tipo.flusso_elab_mif_tipo_code = v_tipo_flusso
          AND   tipo.data_cancellazione IS NULL
          AND   tipo.validita_fine IS NULL
         );
         
         RETURN messaggioRisultato;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;
-- SIAC-5951, SIAC-5955 FINE
--PATCH SIAC-5972
INSERT INTO
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  verificauo,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'OP-GEN-regMassRegistroGSA',
'creazione massiva prime note GSA',
a.azione_tipo_id,b.gruppo_azioni_id,
'/../siacbilapp/azioneRichiesta.do',
FALSE,
now(),
a.ente_proprietario_id,
'admin'
 from siac_d_azione_tipo a, siac_d_gruppo_azioni b
where
b.ente_proprietario_id=A.ente_proprietario_id
and
a.azione_tipo_code='ATTIVITA_SINGOLA'
and b.gruppo_azioni_code='GEN_GSA' and
not exists (select 1 from siac_t_azione z where z.azione_code='OP-GEN-regMassRegistroGSA'
and z.ente_proprietario_id=a.ente_proprietario_id);
--PATCH SIAC-5972
