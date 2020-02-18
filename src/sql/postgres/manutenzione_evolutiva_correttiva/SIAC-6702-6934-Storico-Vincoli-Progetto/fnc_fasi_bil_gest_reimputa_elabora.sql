/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿
/*DROP FUNCTION fnc_fasi_bil_gest_reimputa_elabora(    INTEGER ,
                                                               INTEGER,
                                                                     INTEGER,
                                                                  VARCHAR,
                                                               TIMESTAMP,VARCHAR);*/



-- 15.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile per impegni
-- 20.02.2017 Sofia HD-INC000001535447
-- 07.03.2017 Sofia SIAC-4568
-- 05.05.2017 Sofia HD-INC000001737424

drop function fnc_fasi_bil_gest_reimputa_elabora( p_fasebilelabid   INTEGER ,
                                                              enteproprietarioid INTEGER,
                                                              annobilancio       INTEGER,
                                                              loginoperazione    VARCHAR,
                                                              dataelaborazione TIMESTAMP,
                                                              p_movgest_tipo_code     VARCHAR,
                                                              OUT outfasebilelabretid INTEGER,
                                                              OUT codicerisultato     INTEGER,
                                                              OUT messaggiorisultato  VARCHAR );


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

    -- 30.07.2019 Sofia siac-6934
	faseOp                    VARCHAR(10):=null;
    G_FASE                    CONSTANT varchar:='G'; -- gestione approvata

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

	 -- 30.07.2019 Sofia siac-6934
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


      /*      -- 30.07.2019 Sofia siac-6934
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
			 AND    r.validita_fine IS NULL );*/

      -- 30.07.2019 Sofia siac-6934
      if faseOp=G_FASE then
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
					prog_new.programma_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_programma r,
					siac_t_programma prog,
                    siac_t_programma prog_new, siac_d_programma_tipo tipo,
                    siac_r_programma_stato rs,siac_d_programma_stato stato
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
             and    prog.programma_id=r.programma_id
             and    tipo.ente_proprietario_id=prog.ente_proprietario_id
             and    tipo.programma_tipo_code='G'
             and    prog_new.programma_tipo_id=tipo.programma_tipo_id
             and    prog_new.bil_id=bilancioId
             and    prog_new.programma_code=prog.programma_code
	 		 and    rs.programma_id=prog_new.programma_id
             and    stato.programma_stato_id=rs.programma_stato_id
--             and    stato.programma_stato_code='VA'
             and    stato.programma_stato_code!='AN' -- 06.08.2019 Sofia siac-6934

			 AND    prog.data_cancellazione IS NULL
			 AND    prog.validita_fine IS NULL
			 AND    prog_new.data_cancellazione IS NULL
			 AND    prog_new.validita_fine IS NULL
			 AND    rs.data_cancellazione IS NULL
			 AND    rs.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL
        );

  	    if p_movgest_tipo_code = 'I' then
          -- siac_r_movgest_ts_cronop_elem
          strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' solo cronop [siac_r_movgest_ts_cronop_elem].';
          insert into siac_r_movgest_ts_cronop_elem
          (
              movgest_ts_id,
              cronop_id,
              validita_inizio,
              ente_proprietario_id,
              login_operazione
          )
          select movgesttsidret,
                 cnew.cronop_id,
                 datainizioval,
                 enteproprietarioid,
                 loginoperazione
          from siac_r_movgest_ts_cronop_elem r ,
               siac_t_cronop cronop,
               siac_t_programma prog,
               siac_t_programma pnew, siac_d_programma_tipo tipo,
               siac_r_programma_stato rs,siac_d_programma_stato stato,
               siac_t_cronop cnew, siac_r_cronop_stato rsc, siac_d_cronop_stato cstato
          where r.movgest_ts_id=movgestrec.movgest_ts_id
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
--          and   stato.programma_stato_code='VA'
          and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
          and   rsc.cronop_id=cnew.cronop_id
          and   cstato.cronop_stato_id=rsc.cronop_stato_id
--          and   cstato.cronop_stato_code='VA'
          and   cstato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934

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
          and   rsc.validita_fine is null;


          strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' dettaglio cronop [siac_r_movgest_ts_cronop_elem].';
          insert into siac_r_movgest_ts_cronop_elem
          (
              movgest_ts_id,
              cronop_id,
              cronop_elem_id,
              validita_inizio,
              ente_proprietario_id,
              login_operazione
          )
          select movgesttsidret,
                 cnew.cronop_id,
                 celem_new.cronop_elem_id,
                 datainizioval,
                 enteproprietarioid,
                 loginoperazione
          from siac_r_movgest_ts_cronop_elem r ,
               siac_t_cronop_elem celem,
               siac_t_cronop_elem_det det,
               siac_t_cronop cronop,
               siac_t_programma prog,
               siac_t_programma pnew, siac_d_programma_tipo tipo,
               siac_r_programma_stato rs,siac_d_programma_stato stato,
               siac_t_cronop cnew, siac_r_cronop_stato rsc, siac_d_cronop_stato cstato,
               siac_t_cronop_elem celem_new,siac_t_cronop_elem_det det_new
          where r.movgest_ts_id=movgestrec.movgest_ts_id
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
          and   cnew.bil_id=bilancioId
          and   cnew.cronop_code=cronop.cronop_code
          and   celem_new.cronop_id=cnew.cronop_id
          and   det_new.cronop_elem_id=celem_new.cronop_elem_id
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
--          and   stato.programma_stato_code='VA'
          and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia siac-6934

          and   rsc.cronop_id=cnew.cronop_id
          and   cstato.cronop_stato_id=rsc.cronop_stato_id
---          and   cstato.cronop_stato_code='VA'
          and   cstato.cronop_stato_code!='AN'      -- 06.08.2019 Sofia siac-6934
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
          and   rsc.validita_fine is null;
		end if;
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
  $body$ LANGUAGE 'plpgsql' volatile called ON NULL input security invoker cost 100;c e l l a z i o n e   I S   N U L L 
 
 	 	 	   A N D         c l a s s . v a l i d i t a _ f i n e   I S   N U L L   ) ; 
 
 
 
             s t r m e s s a g g i o : = ' I n s e r i m e n t o   a t t r i b u t i     m o v g e s t _ t s _ i d = '   | | m o v g e s t r e c . m o v g e s t _ t s _ i d : : V A R C H A R   | |   '   [ s i a c _ r _ m o v g e s t _ t s _ a t t r ] . ' ; 
 
             - -   s i a c _ r _ m o v g e s t _ t s _ a t t r 
 
             I N S E R T   I N T O   s i a c _ r _ m o v g e s t _ t s _ a t t r 
 
 	     ( 
 
                 m o v g e s t _ t s _ i d , 
 
                 a t t r _ i d , 
 
                 t a b e l l a _ i d , 
 
                 B O O L E A N , 
 
                 p e r c e n t u a l e , 
 
                 t e s t o , 
 
                 n u m e r i c o , 
 
                 v a l i d i t a _ i n i z i o , 
 
                 e n t e _ p r o p r i e t a r i o _ i d , 
 
                 l o g i n _ o p e r a z i o n e 
 
 	     ) 
 
 	     ( 
 
                   S E L E C T   m o v g e s t t s i d r e t , 
 
                                 r . a t t r _ i d , 
 
                                 r . t a b e l l a _ i d , 
 
                                 r . B O O L E A N , 
 
                                 r . p e r c e n t u a l e , 
 
                                 r . t e s t o , 
 
                                 r . n u m e r i c o , 
 
                                 d a t a i n i z i o v a l , 
 
                                 e n t e p r o p r i e t a r i o i d , 
 
                                 l o g i n o p e r a z i o n e 
 
                   F R O M       s i a c _ r _ m o v g e s t _ t s _ a t t r   r , 
 
                                 s i a c _ t _ a t t r   a t t r 
 
                   W H E R E     r . m o v g e s t _ t s _ i d = m o v g e s t r e c . m o v g e s t _ t s _ i d 
 
                   A N D         a t t r . a t t r _ i d = r . a t t r _ i d 
 
                   A N D         r . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
                   A N D         r . v a l i d i t a _ f i n e   I S   N U L L 
 
                   A N D         a t t r . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
                   A N D         a t t r . v a l i d i t a _ f i n e   I S   N U L L 
 
                   A N D         a t t r . a t t r _ c o d e   N O T   I N   ( ' f l a g D a R i a c c e r t a m e n t o ' , 
 
                                                                               ' a n n o R i a c c e r t a t o ' , 
 
                                                                               ' n u m e r o R i a c c e r t a t o ' )   ) ; 
 
 
 
             I N S E R T   I N T O   s i a c _ r _ m o v g e s t _ t s _ a t t r 
 
 	     ( 
 
 	 	 	 	     m o v g e s t _ t s _ i d   , 
 
 	 	 	 	     a t t r _ i d   , 
 
 	 	 	 	     t a b e l l a _ i d   , 
 
 	 	 	 	     " b o o l e a n "   , 
 
 	 	 	 	     p e r c e n t u a l e , 
 
 	 	 	 	     t e s t o , 
 
 	 	 	 	     n u m e r i c o   , 
 
 	 	 	 	     v a l i d i t a _ i n i z i o   , 
 
 	 	 	 	     v a l i d i t a _ f i n e   , 
 
 	 	 	 	     e n t e _ p r o p r i e t a r i o _ i d   , 
 
 	 	 	 	     d a t a _ c a n c e l l a z i o n e   , 
 
 	 	 	 	     l o g i n _ o p e r a z i o n e 
 
 	     )     V A L U E S   ( 
 
 	 	 	 	     m o v g e s t t s i d r e t   , 
 
 	 	 	 	     v _ f l a g d a r i a c c e r t a m e n t o _ a t t r _ i d   , 
 
 	 	 	 	     N U L L , 
 
 	 	 	 	     ' S ' , 
 
 	 	 	 	     N U L L , 
 
 	 	 	 	     N U L L   , 
 
 	 	 	 	     N U L L , 
 
 	 	 	 	     n o w ( )   , 
 
 	 	 	 	     N U L L   , 
 
 	 	 	 	     e n t e p r o p r i e t a r i o i d   , 
 
 	 	 	 	     N U L L   , 
 
 	 	 	 	     l o g i n o p e r a z i o n e 
 
 	     ) ; 
 
 
 
             I N S E R T   I N T O   s i a c _ r _ m o v g e s t _ t s _ a t t r 
 
 	     ( 
 
                 m o v g e s t _ t s _ i d   , 
 
                 a t t r _ i d   , 
 
                 t a b e l l a _ i d   , 
 
                 " b o o l e a n "   , 
 
                 p e r c e n t u a l e , 
 
                 t e s t o , 
 
                 n u m e r i c o   , 
 
                 v a l i d i t a _ i n i z i o   , 
 
                 v a l i d i t a _ f i n e   , 
 
                 e n t e _ p r o p r i e t a r i o _ i d   , 
 
                 d a t a _ c a n c e l l a z i o n e   , 
 
                 l o g i n _ o p e r a z i o n e 
 
 	     ) 
 
 	     V A L U E S 
 
 	     ( 
 
                 m o v g e s t t s i d r e t   , 
 
                 v _ a n n o r i a c c e r t a t o _ a t t r _ i d , 
 
                 N U L L , 
 
                 N U L L , 
 
                 N U L L , 
 
                 m o v g e s t r e c . m o v g e s t _ a n n o   , 
 
                 N U L L   , 
 
                 n o w ( )   , 
 
                 N U L L , 
 
                 e n t e p r o p r i e t a r i o i d , 
 
                 N U L L , 
 
                 l o g i n o p e r a z i o n e 
 
 	     ) ; 
 
 
 
             I N S E R T   I N T O   s i a c _ r _ m o v g e s t _ t s _ a t t r 
 
 	     ( 
 
                 m o v g e s t _ t s _ i d   , 
 
                 a t t r _ i d   , 
 
                 t a b e l l a _ i d   , 
 
                 " b o o l e a n "   , 
 
                 p e r c e n t u a l e , 
 
                 t e s t o , 
 
                 n u m e r i c o   , 
 
                 v a l i d i t a _ i n i z i o   , 
 
                 v a l i d i t a _ f i n e   , 
 
                 e n t e _ p r o p r i e t a r i o _ i d   , 
 
                 d a t a _ c a n c e l l a z i o n e   , 
 
                 l o g i n _ o p e r a z i o n e 
 
 	     ) 
 
 	     V A L U E S 
 
 	     ( 
 
                 m o v g e s t t s i d r e t   , 
 
                 v _ n u m e r o r i a c c e r t a t o _ a t t r _ i d   , 
 
                 N U L L , 
 
                 N U L L , 
 
                 N U L L , 
 
                 m o v g e s t r e c . m o v g e s t _ n u m e r o   , 
 
                 N U L L , 
 
                 n o w ( )   , 
 
                 N U L L   , 
 
                 e n t e p r o p r i e t a r i o i d   , 
 
                 N U L L , 
 
                 l o g i n o p e r a z i o n e 
 
 	     ) ; 
 
 
 
             - -   s i a c _ r _ m o v g e s t _ t s _ a t t o _ a m m 
 
             / * s t r m e s s a g g i o : = ' I n s e r i m e n t o       m o v g e s t _ t s _ i d = ' 
 
             | | m o v g e s t r e c . m o v g e s t _ t s _ i d : : V A R C H A R 
 
             | |   '   [ s i a c _ r _ m o v g e s t _ t s _ a t t o _ a m m ] . ' ; 
 
             I N S E R T   I N T O   s i a c _ r _ m o v g e s t _ t s _ a t t o _ a m m 
 
 	     ( 
 
 	 	 	 	     m o v g e s t _ t s _ i d , 
 
 	 	 	 	     a t t o a m m _ i d , 
 
 	 	 	 	     v a l i d i t a _ i n i z i o , 
 
 	 	 	 	     e n t e _ p r o p r i e t a r i o _ i d , 
 
 	 	 	 	     l o g i n _ o p e r a z i o n e 
 
 	     ) 
 
 	     ( 
 
 	 	 	   S E L E C T   m o v g e s t t s i d r e t , 
 
 	 	 	 	 	 r . a t t o a m m _ i d , 
 
 	 	 	 	 	 d a t a i n i z i o v a l , 
 
 	 	 	 	 	 e n t e p r o p r i e t a r i o i d , 
 
 	 	 	 	 	 l o g i n o p e r a z i o n e 
 
 	 	 	   F R O M       s i a c _ r _ m o v g e s t _ t s _ a t t o _ a m m   r , 
 
 	 	 	 	 	 s i a c _ t _ a t t o _ a m m   a t t o 
 
 	 	 	   W H E R E     r . m o v g e s t _ t s _ i d = m o v g e s t r e c . m o v g e s t _ t s _ i d 
 
 	 	 	   A N D         a t t o . a t t o a m m _ i d = r . a t t o a m m _ i d 
 
 	 	 	   A N D         r . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
 	 	 	   A N D         r . v a l i d i t a _ f i n e   I S   N U L L 
 
               ) ; * / 
 
 - - 	 	 	   A N D         a t t o . d a t a _ c a n c e l l a z i o n e   I S   N U L L   S o f i a   H D - I N C 0 0 0 0 0 1 5 3 5 4 4 7 
 
 - - 	 	 	   A N D         a t t o . v a l i d i t a _ f i n e   I S   N U L L   ) ; 
 
 
 
 	       - -   0 7 . 0 2 . 2 0 1 8   S o f i a   s i a c - 5 3 6 8 
 
 	       i f   i m p o s t a P r o v v e d i m e n t o = t r u e   t h e n 
 
               	 s t r m e s s a g g i o : = ' I n s e r i m e n t o       m o v g e s t _ t s _ i d = ' 
 
 	             | | m o v g e s t r e c . m o v g e s t _ t s _ i d : : V A R C H A R 
 
         	     | |   '   [ s i a c _ r _ m o v g e s t _ t s _ a t t o _ a m m ] . ' ; 
 
               	 I N S E R T   I N T O   s i a c _ r _ m o v g e s t _ t s _ a t t o _ a m m 
 
 	     	 ( 
 
 	 	   m o v g e s t _ t s _ i d , 
 
 	           a t t o a m m _ i d , 
 
 	           v a l i d i t a _ i n i z i o , 
 
 	           e n t e _ p r o p r i e t a r i o _ i d , 
 
 	           l o g i n _ o p e r a z i o n e 
 
 	     	 ) 
 
                 v a l u e s 
 
                 ( 
 
                   m o v g e s t t s i d r e t , 
 
                   m o v g e s t r e c . a t t o a m m _ i d , 
 
                   d a t a i n i z i o v a l , 
 
 	   	   e n t e p r o p r i e t a r i o i d , 
 
 	   	   l o g i n o p e r a z i o n e 
 
                 ) ; 
 
               e n d   i f ; 
 
 
 
 
 
             - -   s i a c _ r _ m o v g e s t _ t s _ s o g 
 
             s t r m e s s a g g i o : = ' I n s e r i m e n t o       m o v g e s t _ t s _ i d = '   | | m o v g e s t r e c . m o v g e s t _ t s _ i d : : V A R C H A R   | |   '   [ s i a c _ r _ m o v g e s t _ t s _ s o g ] . ' ; 
 
             I N S E R T   I N T O   s i a c _ r _ m o v g e s t _ t s _ s o g 
 
 	     ( 
 
 	 	 	 	     m o v g e s t _ t s _ i d , 
 
 	 	 	 	     s o g g e t t o _ i d , 
 
 	 	 	 	     v a l i d i t a _ i n i z i o , 
 
 	 	 	 	     e n t e _ p r o p r i e t a r i o _ i d , 
 
 	 	 	 	     l o g i n _ o p e r a z i o n e 
 
 	     ) 
 
 	     ( 
 
 	 	 	   S E L E C T   m o v g e s t t s i d r e t , 
 
 	 	 	 	 	 r . s o g g e t t o _ i d , 
 
 	 	 	 	 	 d a t a i n i z i o v a l , 
 
 	 	 	 	 	 e n t e p r o p r i e t a r i o i d , 
 
 	 	 	 	 	 l o g i n o p e r a z i o n e 
 
 	 	 	   F R O M       s i a c _ r _ m o v g e s t _ t s _ s o g   r , 
 
 	 	 	 	 	 s i a c _ t _ s o g g e t t o   s o g g 
 
 	 	 	   W H E R E     r . m o v g e s t _ t s _ i d = m o v g e s t r e c . m o v g e s t _ t s _ i d 
 
 	 	 	   A N D         s o g g . s o g g e t t o _ i d = r . s o g g e t t o _ i d 
 
 	 	 	   A N D         s o g g . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
 	 	 	   A N D         s o g g . v a l i d i t a _ f i n e   I S   N U L L 
 
 	 	 	   A N D         r . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
 	 	 	   A N D         r . v a l i d i t a _ f i n e   I S   N U L L   ) ; 
 
 
 
             - -   s i a c _ r _ m o v g e s t _ t s _ s o g c l a s s e 
 
             s t r m e s s a g g i o : = ' I n s e r i m e n t o       m o v g e s t _ t s _ i d = '   | | m o v g e s t r e c . m o v g e s t _ t s _ i d : : V A R C H A R   | |   '   [ s i a c _ r _ m o v g e s t _ t s _ s o g c l a s s e ] . ' ; 
 
             I N S E R T   I N T O   s i a c _ r _ m o v g e s t _ t s _ s o g c l a s s e 
 
 	     ( 
 
 	 	 	 	     m o v g e s t _ t s _ i d , 
 
 	 	 	 	     s o g g e t t o _ c l a s s e _ i d , 
 
 	 	 	 	     v a l i d i t a _ i n i z i o , 
 
 	 	 	 	     e n t e _ p r o p r i e t a r i o _ i d , 
 
 	 	 	 	     l o g i n _ o p e r a z i o n e 
 
 	     ) 
 
 	     ( 
 
 	 	 	   S E L E C T   m o v g e s t t s i d r e t , 
 
 	 	 	 	 	 r . s o g g e t t o _ c l a s s e _ i d , 
 
 	 	 	 	 	 d a t a i n i z i o v a l , 
 
 	 	 	 	 	 e n t e p r o p r i e t a r i o i d , 
 
 	 	 	 	 	 l o g i n o p e r a z i o n e 
 
 	 	 	   F R O M       s i a c _ r _ m o v g e s t _ t s _ s o g c l a s s e   r , 
 
 	 	 	 	 	 s i a c _ d _ s o g g e t t o _ c l a s s e   c l a s s e 
 
 	 	 	   W H E R E     r . m o v g e s t _ t s _ i d = m o v g e s t r e c . m o v g e s t _ t s _ i d 
 
 	 	 	   A N D         c l a s s e . s o g g e t t o _ c l a s s e _ i d = r . s o g g e t t o _ c l a s s e _ i d 
 
 	 	 	   A N D         c l a s s e . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
 	 	 	   A N D         c l a s s e . v a l i d i t a _ f i n e   I S   N U L L 
 
 	 	 	   A N D         r . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
 	 	 	   A N D         r . v a l i d i t a _ f i n e   I S   N U L L   ) ; 
 
 
 
 
 
             / *             - -   3 0 . 0 7 . 2 0 1 9   S o f i a   s i a c - 6 9 3 4 
 
             - -   s i a c _ r _ m o v g e s t _ t s _ p r o g r a m m a 
 
             s t r m e s s a g g i o : = ' I n s e r i m e n t o       m o v g e s t _ t s _ i d = '   | | m o v g e s t r e c . m o v g e s t _ t s _ i d : : V A R C H A R   | |   '   [ s i a c _ r _ m o v g e s t _ t s _ p r o g r a m m a ] . ' ; 
 
             I N S E R T   I N T O   s i a c _ r _ m o v g e s t _ t s _ p r o g r a m m a 
 
 	     ( 
 
 	 	 	 	     m o v g e s t _ t s _ i d , 
 
 	 	 	 	     p r o g r a m m a _ i d , 
 
 	 	 	 	     v a l i d i t a _ i n i z i o , 
 
 	 	 	 	     e n t e _ p r o p r i e t a r i o _ i d , 
 
 	 	 	 	     l o g i n _ o p e r a z i o n e 
 
 	     ) 
 
 	     ( 
 
 	 	 	   S E L E C T   m o v g e s t t s i d r e t , 
 
 	 	 	 	 	 r . p r o g r a m m a _ i d , 
 
 	 	 	 	 	 d a t a i n i z i o v a l , 
 
 	 	 	 	 	 e n t e p r o p r i e t a r i o i d , 
 
 	 	 	 	 	 l o g i n o p e r a z i o n e 
 
 	 	 	   F R O M       s i a c _ r _ m o v g e s t _ t s _ p r o g r a m m a   r , 
 
 	 	 	 	 	 s i a c _ t _ p r o g r a m m a   p r o g 
 
 	 	 	   W H E R E     r . m o v g e s t _ t s _ i d = m o v g e s t r e c . m o v g e s t _ t s _ i d 
 
 	 	 	   A N D         p r o g . p r o g r a m m a _ i d = r . p r o g r a m m a _ i d 
 
 	 	 	   A N D         p r o g . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
 	 	 	   A N D         p r o g . v a l i d i t a _ f i n e   I S   N U L L 
 
 	 	 	   A N D         r . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
 	 	 	   A N D         r . v a l i d i t a _ f i n e   I S   N U L L   ) ; * / 
 
 
 
             - -   3 0 . 0 7 . 2 0 1 9   S o f i a   s i a c - 6 9 3 4 
 
             i f   f a s e O p = G _ F A S E   t h e n 
 
                   - -   s i a c _ r _ m o v g e s t _ t s _ p r o g r a m m a 
 
                   s t r m e s s a g g i o : = ' I n s e r i m e n t o       m o v g e s t _ t s _ i d = '   | | m o v g e s t r e c . m o v g e s t _ t s _ i d : : V A R C H A R   | |   '   [ s i a c _ r _ m o v g e s t _ t s _ p r o g r a m m a ] . ' ; 
 
                   I N S E R T   I N T O   s i a c _ r _ m o v g e s t _ t s _ p r o g r a m m a 
 
 	     	   ( 
 
 	 	 	 	     m o v g e s t _ t s _ i d , 
 
 	 	 	 	     p r o g r a m m a _ i d , 
 
 	 	 	 	     v a l i d i t a _ i n i z i o , 
 
 	 	 	 	     e n t e _ p r o p r i e t a r i o _ i d , 
 
 	 	 	 	     l o g i n _ o p e r a z i o n e 
 
 	     	 ) 
 
 	     	 ( 
 
 	 	 	   S E L E C T   m o v g e s t t s i d r e t , 
 
 	 	 	 	 	 p r o g _ n e w . p r o g r a m m a _ i d , 
 
 	 	 	 	 	 d a t a i n i z i o v a l , 
 
 	 	 	 	 	 e n t e p r o p r i e t a r i o i d , 
 
 	 	 	 	 	 l o g i n o p e r a z i o n e 
 
 	 	 	   F R O M       s i a c _ r _ m o v g e s t _ t s _ p r o g r a m m a   r , 
 
 	 	 	 	 	 s i a c _ t _ p r o g r a m m a   p r o g , 
 
                                         s i a c _ t _ p r o g r a m m a   p r o g _ n e w ,   s i a c _ d _ p r o g r a m m a _ t i p o   t i p o , 
 
                                         s i a c _ r _ p r o g r a m m a _ s t a t o   r s , s i a c _ d _ p r o g r a m m a _ s t a t o   s t a t o 
 
 	 	 	   W H E R E     r . m o v g e s t _ t s _ i d = m o v g e s t r e c . m o v g e s t _ t s _ i d 
 
                           a n d         p r o g . p r o g r a m m a _ i d = r . p r o g r a m m a _ i d 
 
                           a n d         t i p o . e n t e _ p r o p r i e t a r i o _ i d = p r o g . e n t e _ p r o p r i e t a r i o _ i d 
 
                           a n d         t i p o . p r o g r a m m a _ t i p o _ c o d e = ' G ' 
 
                           a n d         p r o g _ n e w . p r o g r a m m a _ t i p o _ i d = t i p o . p r o g r a m m a _ t i p o _ i d 
 
                           a n d         p r o g _ n e w . b i l _ i d = b i l a n c i o I d 
 
                           a n d         p r o g _ n e w . p r o g r a m m a _ c o d e = p r o g . p r o g r a m m a _ c o d e 
 
 	   	 	   a n d         r s . p r o g r a m m a _ i d = p r o g _ n e w . p r o g r a m m a _ i d 
 
                           a n d         s t a t o . p r o g r a m m a _ s t a t o _ i d = r s . p r o g r a m m a _ s t a t o _ i d 
 
 - -                           a n d         s t a t o . p r o g r a m m a _ s t a t o _ c o d e = ' V A ' 
 
                           a n d         s t a t o . p r o g r a m m a _ s t a t o _ c o d e ! = ' A N '   - -   0 6 . 0 8 . 2 0 1 9   S o f i a   s i a c - 6 9 3 4 
 
 
 
 	 	 	   A N D         p r o g . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
 	 	 	   A N D         p r o g . v a l i d i t a _ f i n e   I S   N U L L 
 
 	 	 	   A N D         p r o g _ n e w . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
 	 	 	   A N D         p r o g _ n e w . v a l i d i t a _ f i n e   I S   N U L L 
 
 	 	 	   A N D         r s . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
 	 	 	   A N D         r s . v a l i d i t a _ f i n e   I S   N U L L 
 
 	 	 	   A N D         r . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
 	 	 	   A N D         r . v a l i d i t a _ f i n e   I S   N U L L 
 
                 ) ; 
 
 
 
     	         i f   p _ m o v g e s t _ t i p o _ c o d e   =   ' I '   t h e n 
 
                     - -   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m 
 
                     s t r m e s s a g g i o : = ' I n s e r i m e n t o       m o v g e s t _ t s _ i d = '   | | m o v g e s t r e c . m o v g e s t _ t s _ i d : : V A R C H A R   | |   '   s o l o   c r o n o p   [ s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m ] . ' ; 
 
                     i n s e r t   i n t o   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m 
 
                     ( 
 
                             m o v g e s t _ t s _ i d , 
 
                             c r o n o p _ i d , 
 
                             v a l i d i t a _ i n i z i o , 
 
                             e n t e _ p r o p r i e t a r i o _ i d , 
 
                             l o g i n _ o p e r a z i o n e 
 
                     ) 
 
                     s e l e c t   m o v g e s t t s i d r e t , 
 
                                   c n e w . c r o n o p _ i d , 
 
                                   d a t a i n i z i o v a l , 
 
                                   e n t e p r o p r i e t a r i o i d , 
 
                                   l o g i n o p e r a z i o n e 
 
                     f r o m   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m   r   , 
 
                               s i a c _ t _ c r o n o p   c r o n o p , 
 
                               s i a c _ t _ p r o g r a m m a   p r o g , 
 
                               s i a c _ t _ p r o g r a m m a   p n e w ,   s i a c _ d _ p r o g r a m m a _ t i p o   t i p o , 
 
                               s i a c _ r _ p r o g r a m m a _ s t a t o   r s , s i a c _ d _ p r o g r a m m a _ s t a t o   s t a t o , 
 
                               s i a c _ t _ c r o n o p   c n e w ,   s i a c _ r _ c r o n o p _ s t a t o   r s c ,   s i a c _ d _ c r o n o p _ s t a t o   c s t a t o 
 
                     w h e r e   r . m o v g e s t _ t s _ i d = m o v g e s t r e c . m o v g e s t _ t s _ i d 
 
                     a n d       r . c r o n o p _ e l e m _ i d   i s   n u l l 
 
                     a n d       c r o n o p . c r o n o p _ i d = r . c r o n o p _ i d 
 
                     a n d       p r o g . p r o g r a m m a _ i d = c r o n o p . p r o g r a m m a _ i d 
 
                     a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = p r o g . e n t e _ p r o p r i e t a r i o _ i d 
 
                     a n d       t i p o . p r o g r a m m a _ t i p o _ c o d e = ' G ' 
 
                     a n d       p n e w . p r o g r a m m a _ t i p o _ i d = t i p o . p r o g r a m m a _ t i p o _ i d 
 
                     a n d       p n e w . p r o g r a m m a _ c o d e = p r o g . p r o g r a m m a _ c o d e 
 
                     a n d       c n e w . p r o g r a m m a _ i d = p n e w . p r o g r a m m a _ i d 
 
                     a n d       c n e w . b i l _ i d = b i l a n c i o I d 
 
                     a n d       c n e w . c r o n o p _ c o d e = c r o n o p . c r o n o p _ c o d e 
 
                     a n d       r s . p r o g r a m m a _ i d = p n e w . p r o g r a m m a _ i d 
 
                     a n d       s t a t o . p r o g r a m m a _ s t a t o _ i d = r s . p r o g r a m m a _ s t a t o _ i d 
 
 - -                     a n d       s t a t o . p r o g r a m m a _ s t a t o _ c o d e = ' V A ' 
 
                     a n d       s t a t o . p r o g r a m m a _ s t a t o _ c o d e ! = ' A N '   - -   0 6 . 0 8 . 2 0 1 9   S o f i a   s i a c - 6 9 3 4 
 
                     a n d       r s c . c r o n o p _ i d = c n e w . c r o n o p _ i d 
 
                     a n d       c s t a t o . c r o n o p _ s t a t o _ i d = r s c . c r o n o p _ s t a t o _ i d 
 
 - -                     a n d       c s t a t o . c r o n o p _ s t a t o _ c o d e = ' V A ' 
 
                     a n d       c s t a t o . c r o n o p _ s t a t o _ c o d e ! = ' A N '   - -   0 6 . 0 8 . 2 0 1 9   S o f i a   s i a c - 6 9 3 4 
 
 
 
                     a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       p r o g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       p r o g . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       c r o n o p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       c r o n o p . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       p n e w . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       p n e w . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       c n e w . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       c n e w . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       r s c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r s c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 
 
                     s t r m e s s a g g i o : = ' I n s e r i m e n t o       m o v g e s t _ t s _ i d = '   | | m o v g e s t r e c . m o v g e s t _ t s _ i d : : V A R C H A R   | |   '   d e t t a g l i o   c r o n o p   [ s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m ] . ' ; 
 
                     i n s e r t   i n t o   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m 
 
                     ( 
 
                             m o v g e s t _ t s _ i d , 
 
                             c r o n o p _ i d , 
 
                             c r o n o p _ e l e m _ i d , 
 
                             v a l i d i t a _ i n i z i o , 
 
                             e n t e _ p r o p r i e t a r i o _ i d , 
 
                             l o g i n _ o p e r a z i o n e 
 
                     ) 
 
                     s e l e c t   m o v g e s t t s i d r e t , 
 
                                   c n e w . c r o n o p _ i d , 
 
                                   c e l e m _ n e w . c r o n o p _ e l e m _ i d , 
 
                                   d a t a i n i z i o v a l , 
 
                                   e n t e p r o p r i e t a r i o i d , 
 
                                   l o g i n o p e r a z i o n e 
 
                     f r o m   s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m   r   , 
 
                               s i a c _ t _ c r o n o p _ e l e m   c e l e m , 
 
                               s i a c _ t _ c r o n o p _ e l e m _ d e t   d e t , 
 
                               s i a c _ t _ c r o n o p   c r o n o p , 
 
                               s i a c _ t _ p r o g r a m m a   p r o g , 
 
                               s i a c _ t _ p r o g r a m m a   p n e w ,   s i a c _ d _ p r o g r a m m a _ t i p o   t i p o , 
 
                               s i a c _ r _ p r o g r a m m a _ s t a t o   r s , s i a c _ d _ p r o g r a m m a _ s t a t o   s t a t o , 
 
                               s i a c _ t _ c r o n o p   c n e w ,   s i a c _ r _ c r o n o p _ s t a t o   r s c ,   s i a c _ d _ c r o n o p _ s t a t o   c s t a t o , 
 
                               s i a c _ t _ c r o n o p _ e l e m   c e l e m _ n e w , s i a c _ t _ c r o n o p _ e l e m _ d e t   d e t _ n e w 
 
                     w h e r e   r . m o v g e s t _ t s _ i d = m o v g e s t r e c . m o v g e s t _ t s _ i d 
 
                     a n d       r . c r o n o p _ e l e m _ i d   i s   n o t   n u l l 
 
                     a n d       c e l e m . c r o n o p _ e l e m _ i d = r . c r o n o p _ e l e m _ i d 
 
                     a n d       d e t . c r o n o p _ e l e m _ i d = c e l e m . c r o n o p _ e l e m _ i d 
 
                     a n d       c r o n o p . c r o n o p _ i d = c e l e m . c r o n o p _ i d 
 
                     a n d       p r o g . p r o g r a m m a _ i d = c r o n o p . p r o g r a m m a _ i d 
 
                     a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = p r o g . e n t e _ p r o p r i e t a r i o _ i d 
 
                     a n d       t i p o . p r o g r a m m a _ t i p o _ c o d e = ' G ' 
 
                     a n d       p n e w . p r o g r a m m a _ t i p o _ i d = t i p o . p r o g r a m m a _ t i p o _ i d 
 
                     a n d       p n e w . p r o g r a m m a _ c o d e = p r o g . p r o g r a m m a _ c o d e 
 
                     a n d       c n e w . p r o g r a m m a _ i d = p n e w . p r o g r a m m a _ i d 
 
                     a n d       c n e w . b i l _ i d = b i l a n c i o I d 
 
                     a n d       c n e w . c r o n o p _ c o d e = c r o n o p . c r o n o p _ c o d e 
 
                     a n d       c e l e m _ n e w . c r o n o p _ i d = c n e w . c r o n o p _ i d 
 
                     a n d       d e t _ n e w . c r o n o p _ e l e m _ i d = c e l e m _ n e w . c r o n o p _ e l e m _ i d 
 
                     a n d       c o a l e s c e ( c e l e m _ n e w . c r o n o p _ e l e m _ c o d e , ' ' ) = c o a l e s c e ( c e l e m . c r o n o p _ e l e m _ c o d e , ' ' ) 
 
                     a n d       c o a l e s c e ( c e l e m _ n e w . c r o n o p _ e l e m _ c o d e 2 , ' ' ) = c o a l e s c e ( c e l e m . c r o n o p _ e l e m _ c o d e 2 , ' ' ) 
 
                     a n d       c o a l e s c e ( c e l e m _ n e w . c r o n o p _ e l e m _ c o d e 3 , ' ' ) = c o a l e s c e ( c e l e m . c r o n o p _ e l e m _ c o d e 3 , ' ' ) 
 
                     a n d       c o a l e s c e ( c e l e m _ n e w . e l e m _ t i p o _ i d , 0 ) = c o a l e s c e ( c e l e m . e l e m _ t i p o _ i d , 0 ) 
 
                     a n d       c o a l e s c e ( c e l e m _ n e w . c r o n o p _ e l e m _ d e s c , ' ' ) = c o a l e s c e ( c e l e m . c r o n o p _ e l e m _ d e s c , ' ' ) 
 
                     a n d       c o a l e s c e ( c e l e m _ n e w . c r o n o p _ e l e m _ d e s c 2 , ' ' ) = c o a l e s c e ( c e l e m . c r o n o p _ e l e m _ d e s c 2 , ' ' ) 
 
                     a n d       c o a l e s c e ( d e t _ n e w . p e r i o d o _ i d , 0 ) = c o a l e s c e ( d e t . p e r i o d o _ i d , 0 ) 
 
                     a n d       c o a l e s c e ( d e t _ n e w . c r o n o p _ e l e m _ d e t _ i m p o r t o , 0 ) = c o a l e s c e ( d e t . c r o n o p _ e l e m _ d e t _ i m p o r t o , 0 ) 
 
                     a n d       c o a l e s c e ( d e t _ n e w . c r o n o p _ e l e m _ d e t _ d e s c , ' ' ) = c o a l e s c e ( d e t . c r o n o p _ e l e m _ d e t _ d e s c , ' ' ) 
 
                     a n d       c o a l e s c e ( d e t _ n e w . a n n o _ e n t r a t a , ' ' ) = c o a l e s c e ( d e t . a n n o _ e n t r a t a , ' ' ) 
 
                     a n d       c o a l e s c e ( d e t _ n e w . e l e m _ d e t _ t i p o _ i d , 0 ) = c o a l e s c e ( d e t . e l e m _ d e t _ t i p o _ i d , 0 ) 
 
                     a n d       r s . p r o g r a m m a _ i d = p n e w . p r o g r a m m a _ i d 
 
                     a n d       s t a t o . p r o g r a m m a _ s t a t o _ i d = r s . p r o g r a m m a _ s t a t o _ i d 
 
 - -                     a n d       s t a t o . p r o g r a m m a _ s t a t o _ c o d e = ' V A ' 
 
                     a n d       s t a t o . p r o g r a m m a _ s t a t o _ c o d e ! = ' A N '   - -   0 6 . 0 8 . 2 0 1 9   S o f i a   s i a c - 6 9 3 4 
 
 
 
                     a n d       r s c . c r o n o p _ i d = c n e w . c r o n o p _ i d 
 
                     a n d       c s t a t o . c r o n o p _ s t a t o _ i d = r s c . c r o n o p _ s t a t o _ i d 
 
 - - -                     a n d       c s t a t o . c r o n o p _ s t a t o _ c o d e = ' V A ' 
 
                     a n d       c s t a t o . c r o n o p _ s t a t o _ c o d e ! = ' A N '             - -   0 6 . 0 8 . 2 0 1 9   S o f i a   s i a c - 6 9 3 4 
 
                     a n d       e x i s t s 
 
                     ( 
 
                         s e l e c t   1 
 
                         f r o m   s i a c _ r _ c r o n o p _ e l e m _ c l a s s   r c , s i a c _ t _ c l a s s   c , s i a c _ d _ c l a s s _ t i p o   t i p o 
 
                         w h e r e   r c . c r o n o p _ e l e m _ i d = c e l e m . c r o n o p _ e l e m _ i d 
 
                         a n d       c . c l a s s i f _ i d = r c . c l a s s i f _ i d 
 
                         a n d       t i p o . c l a s s i f _ t i p o _ i d = c . c l a s s i f _ t i p o _ i d 
 
                         a n d       e x i s t s 
 
                         ( 
 
                             s e l e c t   1 
 
                             f r o m   s i a c _ r _ c r o n o p _ e l e m _ c l a s s   r c 1 ,   s i a c _ t _ c l a s s   c 1 
 
                             w h e r e   r c 1 . c r o n o p _ e l e m _ i d = c e l e m _ n e w . c r o n o p _ e l e m _ i d 
 
                             a n d       c 1 . c l a s s i f _ i d = r c 1 . c l a s s i f _ i d 
 
                             a n d       c 1 . c l a s s i f _ t i p o _ i d = t i p o . c l a s s i f _ t i p o _ i d 
 
                             a n d       c 1 . c l a s s i f _ c o d e = c . c l a s s i f _ c o d e 
 
                             a n d       r c 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                             a n d       r c 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
                         ) 
 
                         a n d       r c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       r c . v a l i d i t a _ f i n e   i s   n u l l 
 
                     ) 
 
                     a n d     n o t   e x i s t s 
 
                     ( 
 
                         s e l e c t   1 
 
                         f r o m   s i a c _ r _ c r o n o p _ e l e m _ c l a s s   r c , s i a c _ t _ c l a s s   c , s i a c _ d _ c l a s s _ t i p o   t i p o 
 
                         w h e r e   r c . c r o n o p _ e l e m _ i d = c e l e m . c r o n o p _ e l e m _ i d 
 
                         a n d       c . c l a s s i f _ i d = r c . c l a s s i f _ i d 
 
                         a n d       t i p o . c l a s s i f _ t i p o _ i d = c . c l a s s i f _ t i p o _ i d 
 
                         a n d       n o t   e x i s t s 
 
                         ( 
 
                             s e l e c t   1 
 
                             f r o m   s i a c _ r _ c r o n o p _ e l e m _ c l a s s   r c 1 ,   s i a c _ t _ c l a s s   c 1 
 
                             w h e r e   r c 1 . c r o n o p _ e l e m _ i d = c e l e m _ n e w . c r o n o p _ e l e m _ i d 
 
                             a n d       c 1 . c l a s s i f _ i d = r c 1 . c l a s s i f _ i d 
 
                             a n d       c 1 . c l a s s i f _ t i p o _ i d = t i p o . c l a s s i f _ t i p o _ i d 
 
                             a n d       c 1 . c l a s s i f _ c o d e = c . c l a s s i f _ c o d e 
 
                             a n d       r c 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                             a n d       r c 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
                         ) 
 
                         a n d       r c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       r c . v a l i d i t a _ f i n e   i s   n u l l 
 
                     ) 
 
                     a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       p r o g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       p r o g . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       c r o n o p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       c r o n o p . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       c e l e m . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       c e l e m . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       d e t . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d e t . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       p n e w . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       p n e w . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       c n e w . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       c n e w . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       c e l e m _ n e w . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       c e l e m _ n e w . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       d e t _ n e w . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d e t _ n e w . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       r s c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r s c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 	 	 e n d   i f ; 
 
             e n d   i f ; 
 
 
 
           - - -   1 8 . 0 6 . 2 0 1 9   S o f i a   S I A C - 6 7 0 2 
 
 	   i f   p _ m o v g e s t _ t i p o _ c o d e = i m p _ m o v g e s t _ t i p o   t h e n 
 
             - -   s i a c _ r _ m o v g e s t _ t s _ s t o r i c o _ i m p _ a c c 
 
             s t r m e s s a g g i o : = ' I n s e r i m e n t o       m o v g e s t _ t s _ i d = '   | | m o v g e s t r e c . m o v g e s t _ t s _ i d : : V A R C H A R   | |   '   [ s i a c _ r _ m o v g e s t _ t s _ s t o r i c o _ i m p _ a c c ] . ' ; 
 
             I N S E R T   I N T O   s i a c _ r _ m o v g e s t _ t s _ s t o r i c o _ i m p _ a c c 
 
 	     ( 
 
 	 	 	 m o v g e s t _ t s _ i d , 
 
                         m o v g e s t _ a n n o _ a c c , 
 
                         m o v g e s t _ n u m e r o _ a c c , 
 
                         m o v g e s t _ s u b n u m e r o _ a c c , 
 
                         v a l i d i t a _ i n i z i o , 
 
                         e n t e _ p r o p r i e t a r i o _ i d , 
 
                         l o g i n _ o p e r a z i o n e 
 
 	     ) 
 
 	     ( 
 
 	 	 	   S E L E C T   m o v g e s t t s i d r e t , 
 
 	 	 	 	 	 r . m o v g e s t _ a n n o _ a c c , 
 
                           	 	 r . m o v g e s t _ n u m e r o _ a c c , 
 
 	 	                         r . m o v g e s t _ s u b n u m e r o _ a c c , 
 
 	 	 	 	 	 d a t a i n i z i o v a l , 
 
 	 	 	 	 	 e n t e p r o p r i e t a r i o i d , 
 
 	 	 	 	 	 l o g i n o p e r a z i o n e 
 
 	 	 	   F R O M       s i a c _ r _ m o v g e s t _ t s _ s t o r i c o _ i m p _ a c c   r 
 
 	 	 	   W H E R E     r . m o v g e s t _ t s _ i d = m o v g e s t r e c . m o v g e s t _ t s _ i d 
 
 	 	 	   A N D         r . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
 	 	 	   A N D         r . v a l i d i t a _ f i n e   I S   N U L L   ) ; 
 
             e n d   i f ; 
 
 
 
             - -   s i a c _ r _ m u t u o _ v o c e _ m o v g e s t 
 
             s t r m e s s a g g i o : = ' I n s e r i m e n t o       m o v g e s t _ t s _ i d = '   | | m o v g e s t r e c . m o v g e s t _ t s _ i d : : V A R C H A R   | |   '   [ s i a c _ r _ m u t u o _ v o c e _ m o v g e s t ] . ' ; 
 
             I N S E R T   I N T O   s i a c _ r _ m u t u o _ v o c e _ m o v g e s t 
 
 	     ( 
 
 	 	 	 	     m o v g e s t _ t s _ i d , 
 
 	 	 	 	     m u t _ v o c e _ i d , 
 
 	 	 	 	     v a l i d i t a _ i n i z i o , 
 
 	 	 	 	     e n t e _ p r o p r i e t a r i o _ i d , 
 
 	 	 	 	     l o g i n _ o p e r a z i o n e 
 
 	     ) 
 
 	     ( 
 
 	 	 	   S E L E C T   m o v g e s t t s i d r e t , 
 
 	 	 	 	 	 r . m u t _ v o c e _ i d , 
 
 	 	 	 	 	 d a t a i n i z i o v a l , 
 
 	 	 	 	 	 e n t e p r o p r i e t a r i o i d , 
 
 	 	 	 	 	 l o g i n o p e r a z i o n e 
 
 	 	 	   F R O M       s i a c _ r _ m u t u o _ v o c e _ m o v g e s t   r , 
 
 	 	 	 	 	 s i a c _ t _ m u t u o _ v o c e   v o c e 
 
 	 	 	   W H E R E     r . m o v g e s t _ t s _ i d = m o v g e s t r e c . m o v g e s t _ t s _ i d 
 
 	 	 	   A N D         v o c e . m u t _ v o c e _ i d = r . m u t _ v o c e _ i d 
 
 	 	 	   A N D         v o c e . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
 	 	 	   A N D         v o c e . v a l i d i t a _ f i n e   I S   N U L L 
 
 	 	 	   A N D         r . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
 	 	 	   A N D         r . v a l i d i t a _ f i n e   I S   N U L L   ) ; 
 
 
 
             - -   s i a c _ r _ c a u s a l e _ m o v g e s t _ t s 
 
             s t r m e s s a g g i o : = ' I n s e r i m e n t o       m o v g e s t _ t s _ i d = '   | | m o v g e s t r e c . m o v g e s t _ t s _ i d : : V A R C H A R   | |   '   [ s i a c _ r _ c a u s a l e _ m o v g e s t _ t s ] . ' ; 
 
             I N S E R T   I N T O   s i a c _ r _ c a u s a l e _ m o v g e s t _ t s 
 
 	     ( 
 
 	 	 	 	     m o v g e s t _ t s _ i d , 
 
 	 	 	 	     c a u s _ i d , 
 
 	 	 	 	     v a l i d i t a _ i n i z i o , 
 
 	 	 	 	     e n t e _ p r o p r i e t a r i o _ i d , 
 
 	 	 	 	     l o g i n _ o p e r a z i o n e 
 
 	     ) 
 
 	     ( 
 
 	 	 	   S E L E C T   m o v g e s t t s i d r e t , 
 
 	 	 	 	 	 r . c a u s _ i d , 
 
 	 	 	 	 	 d a t a i n i z i o v a l , 
 
 	 	 	 	 	 e n t e p r o p r i e t a r i o i d , 
 
 	 	 	 	 	 l o g i n o p e r a z i o n e 
 
 	 	 	   F R O M       s i a c _ r _ c a u s a l e _ m o v g e s t _ t s   r , 
 
 	 	 	 	 	 s i a c _ d _ c a u s a l e   c a u s 
 
 	 	 	   W H E R E     r . m o v g e s t _ t s _ i d = m o v g e s t r e c . m o v g e s t _ t s _ i d 
 
 	 	 	   A N D         c a u s . c a u s _ i d = r . c a u s _ i d 
 
 	 	 	   A N D         c a u s . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
 	 	 	   A N D         c a u s . v a l i d i t a _ f i n e   I S   N U L L 
 
 	 	 	   A N D         r . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
 	 	 	   A N D         r . v a l i d i t a _ f i n e   I S   N U L L   ) ; 
 
 
 
             - -   0 5 . 0 5 . 2 0 1 7   S o f i a   H D - I N C 0 0 0 0 0 1 7 3 7 4 2 4 
 
             - -   s i a c _ r _ s u b d o c _ m o v g e s t _ t s 
 
             / * 
 
             s t r m e s s a g g i o : = ' I n s e r i m e n t o       m o v g e s t _ t s _ i d = '   | | m o v g e s t r e c . m o v g e s t _ t s _ i d : : V A R C H A R   | |   '   [ s i a c _ r _ s u b d o c _ m o v g e s t _ t s ] . ' ; 
 
             I N S E R T   I N T O   s i a c _ r _ s u b d o c _ m o v g e s t _ t s 
 
 	     ( 
 
 	 	 	 	     m o v g e s t _ t s _ i d , 
 
 	 	 	 	     s u b d o c _ i d , 
 
 	 	 	 	     v a l i d i t a _ i n i z i o , 
 
 	 	 	 	     e n t e _ p r o p r i e t a r i o _ i d , 
 
 	 	 	 	     l o g i n _ o p e r a z i o n e 
 
 	     ) 
 
 	     ( 
 
 	 	 	   S E L E C T   m o v g e s t t s i d r e t , 
 
 	 	 	 	 	 r . s u b d o c _ i d , 
 
 	 	 	 	 	 d a t a i n i z i o v a l , 
 
 	 	 	 	 	 e n t e p r o p r i e t a r i o i d , 
 
 	 	 	 	 	 l o g i n o p e r a z i o n e 
 
 	 	 	   F R O M       s i a c _ r _ s u b d o c _ m o v g e s t _ t s   r , 
 
 	 	 	 	 	 s i a c _ t _ s u b d o c   s u b 
 
 	 	 	   W H E R E     r . m o v g e s t _ t s _ i d = m o v g e s t r e c . m o v g e s t _ t s _ i d 
 
 	 	 	   A N D         s u b . s u b d o c _ i d = r . s u b d o c _ i d 
 
 	 	 	   A N D         s u b . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
 	 	 	   A N D         s u b . v a l i d i t a _ f i n e   I S   N U L L 
 
 	 	 	   A N D         r . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
 	 	 	   A N D         r . v a l i d i t a _ f i n e   I S   N U L L   ) ; 
 
 
 
             - -   s i a c _ r _ p r e d o c _ m o v g e s t _ t s 
 
             s t r m e s s a g g i o : = ' I n s e r i m e n t o       m o v g e s t _ t s _ i d = '   | | m o v g e s t r e c . m o v g e s t _ t s _ i d : : V A R C H A R   | |   '   [ s i a c _ r _ p r e d o c _ m o v g e s t _ t s ] . ' ; 
 
             I N S E R T   I N T O   s i a c _ r _ p r e d o c _ m o v g e s t _ t s 
 
                                     ( 
 
                                                             m o v g e s t _ t s _ i d , 
 
                                                             p r e d o c _ i d , 
 
                                                             v a l i d i t a _ i n i z i o , 
 
                                                             e n t e _ p r o p r i e t a r i o _ i d , 
 
                                                             l o g i n _ o p e r a z i o n e 
 
                                     ) 
 
                                     ( 
 
                                                   S E L E C T   m o v g e s t t s i d r e t , 
 
                                                                 r . p r e d o c _ i d , 
 
                                                                 d a t a i n i z i o v a l , 
 
                                                                 e n t e p r o p r i e t a r i o i d , 
 
                                                                 l o g i n o p e r a z i o n e 
 
                                                   F R O M       s i a c _ r _ p r e d o c _ m o v g e s t _ t s   r , 
 
                                                                 s i a c _ t _ p r e d o c   s u b 
 
                                                   W H E R E     r . m o v g e s t _ t s _ i d = m o v g e s t r e c . m o v g e s t _ t s _ i d 
 
                                                   A N D         s u b . p r e d o c _ i d = r . p r e d o c _ i d 
 
                                                   A N D         s u b . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
                                                   A N D         s u b . v a l i d i t a _ f i n e   I S   N U L L 
 
                                                   A N D         r . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
                                                   A N D         r . v a l i d i t a _ f i n e   I S   N U L L   ) ; 
 
 	     * / 
 
             - -   0 5 . 0 5 . 2 0 1 7   S o f i a   H D - I N C 0 0 0 0 0 1 7 3 7 4 2 4 
 
 
 
 
 
             s t r m e s s a g g i o : = ' a g g i o r n a m e n t o   t a b e l l a   d i   a p p o g g i o ' ; 
 
             U P D A T E   f a s e _ b i l _ t _ r e i m p u t a z i o n e 
 
             S E T       m o v g e s t n e w _ t s _ i d   = m o v g e s t t s i d r e t 
 
             	 	 , m o v g e s t n e w _ i d   = m o v g e s t i d r e t 
 
                         , d a t a _ m o d i f i c a   =   c l o c k _ t i m e s t a m p ( ) 
 
               	 	 , f l _ e l a b = ' S ' 
 
             W H E R E     r e i m p u t a z i o n e _ i d   =   m o v g e s t r e c . r e i m p u t a z i o n e _ i d ; 
 
 
 
 
 
 
 
         E N D   L O O P ; 
 
 
 
         - -   b o n i f i c a   e v e n t u a l i   s c a r t i 
 
         s e l e c t   *   i n t o   c l e a n r e c   f r o m   f n c _ f a s i _ b i l _ g e s t _ r e i m p u t a _ c l e a n (     p _ f a s e b i l e l a b i d   , e n t e p r o p r i e t a r i o i d   ) ; 
 
 
 
 	 - -   1 5 . 0 2 . 2 0 1 7   S o f i a   S o f i a   S I A C - 4 4 2 5 
 
 	 i f   p _ m o v g e s t _ t i p o _ c o d e = i m p _ m o v g e s t _ t i p o   a n d   c l e a n r e c . c o d i c e r i s u l t a t o   = 0   t h e n 
 
           - -   i n s e r t   N   p e r   i m p e g n i   m o v . m o v g e s t _ a n n o : : i n t e g e r < a n n o B i l a n c i o   o r   m o v . m o v g e s t _ a n n o : : i n t e g e r > a n n o B i l a n c i o 
 
           - -   e s s e n d o   r e i m p u t a z i o n i   c o n s i d e r i a m o   s o l o   m o v . m o v g e s t _ a n n o : : i n t e g e r > a n n o B i l a n c i o 
 
           - -   c h e   n o n   h a n n o   a n c o r a   a t t r i b u t o 
 
 	   s t r M e s s a g g i o : = ' G e s t i o n e   a t t r i b u t o   ' | | F R A Z I O N A B I L E _ A T T R | | ' .   I n s e r i m e n t o   v a l o r e   N   p e r   i m p e g n i   p l u r i e n n a l i . ' ; 
 
           I N S E R T   I N T O   s i a c _ r _ m o v g e s t _ t s _ a t t r 
 
 	   ( 
 
 	     m o v g e s t _ t s _ i d , 
 
 	     a t t r _ i d , 
 
 	     b o o l e a n , 
 
 	     v a l i d i t a _ i n i z i o , 
 
 	     e n t e _ p r o p r i e t a r i o _ i d , 
 
 	     l o g i n _ o p e r a z i o n e 
 
 	   ) 
 
 	   s e l e c t   t s . m o v g e s t _ t s _ i d , 
 
 	                 f l a g F r a z A t t r I d , 
 
                         ' N ' , 
 
 	 	         d a t a I n i z i o V a l , 
 
 	 	         t s . e n t e _ p r o p r i e t a r i o _ i d , 
 
 	 	         l o g i n O p e r a z i o n e 
 
 	   f r o m   s i a c _ t _ m o v g e s t   m o v ,   s i a c _ t _ m o v g e s t _ t s   t s 
 
 	   w h e r e   m o v . b i l _ i d = b i l a n c i o I d 
 
 - - 	 	 a n d       (   m o v . m o v g e s t _ a n n o : : i n t e g e r < a n n o B i l a n c i o   o r   m o v . m o v g e s t _ a n n o : : i n t e g e r > a n n o B i l a n c i o ) 
 
           a n d       m o v . m o v g e s t _ a n n o : : i n t e g e r > a n n o B i l a n c i o 
 
 	   a n d       m o v . m o v g e s t _ t i p o _ i d = t i p o M o v G e s t I d 
 
 	   a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
           a n d       t s . m o v g e s t _ t s _ t i p o _ i d = t i p o M o v G e s t T s T I d 
 
 	   a n d       n o t   e x i s t s   ( s e l e c t   1   f r o m   s i a c _ r _ m o v g e s t _ t s _ a t t r   r 1 
 
               	 	                       w h e r e   r 1 . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
                                               a n d       r 1 . a t t r _ i d = f l a g F r a z A t t r I d 
 
                                               a n d       r 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                               a n d       r 1 . v a l i d i t a _ f i n e   i s   n u l l ) ; 
 
 
 
           - -   i n s e r t   S   p e r   i m p e g n i   m o v . m o v g e s t _ a n n o : : i n t e g e r = a n n o B i l a n c i o 
 
           - -   c h e   n o n   h a n n o   a n c o r a   a t t r i b u t o 
 
           s t r M e s s a g g i o : = ' G e s t i o n e   a t t r i b u t o   ' | | F R A Z I O N A B I L E _ A T T R | | ' .   I n s e r i m e n t o   v a l o r e   S   p e r   i m p e g n i   d i   c o m p e t e n z a   s e n z a   a t t o   a m m i n i s t r a t i v o   a n t e c e d e n t e . ' ; 
 
 	   I N S E R T   I N T O   s i a c _ r _ m o v g e s t _ t s _ a t t r 
 
 	   ( 
 
 	     m o v g e s t _ t s _ i d , 
 
 	     a t t r _ i d , 
 
 	     b o o l e a n , 
 
 	     v a l i d i t a _ i n i z i o , 
 
 	     e n t e _ p r o p r i e t a r i o _ i d , 
 
 	     l o g i n _ o p e r a z i o n e 
 
 	   ) 
 
 	   s e l e c t   t s . m o v g e s t _ t s _ i d , 
 
 	                 f l a g F r a z A t t r I d , 
 
                         ' S ' , 
 
 	                 d a t a I n i z i o V a l , 
 
 	                 t s . e n t e _ p r o p r i e t a r i o _ i d , 
 
 	                 l o g i n O p e r a z i o n e 
 
 	   f r o m   s i a c _ t _ m o v g e s t   m o v ,   s i a c _ t _ m o v g e s t _ t s   t s 
 
 	   w h e r e   m o v . b i l _ i d = b i l a n c i o I d 
 
 	   a n d       m o v . m o v g e s t _ a n n o : : i n t e g e r = a n n o B i l a n c i o 
 
 	   a n d       m o v . m o v g e s t _ t i p o _ i d = t i p o M o v G e s t I d 
 
 	   a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
           a n d       t s . m o v g e s t _ t s _ t i p o _ i d = t i p o M o v G e s t T s T I d 
 
 	   a n d       n o t   e x i s t s   ( s e l e c t   1   f r o m   s i a c _ r _ m o v g e s t _ t s _ a t t r   r 1 
 
               	 	                       w h e r e   r 1 . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
                                               a n d       r 1 . a t t r _ i d = f l a g F r a z A t t r I d 
 
                                               a n d       r 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                               a n d       r 1 . v a l i d i t a _ f i n e   i s   n u l l ) 
 
           a n d     n o t   e x i s t s   ( s e l e c t   1   f r o m   s i a c _ r _ m o v g e s t _ t s _ a t t o _ a m m   r a , s i a c _ t _ a t t o _ a m m   a t t o 
 
 	 	 	 	 	     w h e r e   r a . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
 	 	 	 	 	     a n d       a t t o . a t t o a m m _ i d = r a . a t t o a m m _ i d 
 
 	 	 	 	   	     a n d       a t t o . a t t o a m m _ a n n o : : i n t e g e r   <   a n n o B i l a n c i o 
 
 	 	           	 	     a n d       r a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 	 	             a n d       r a . v a l i d i t a _ f i n e   i s   n u l l ) ; 
 
 
 
           - -   a g g i o r n a m e n t o   N   p e r   i m p e g n i   m o v . m o v g e s t _ a n n o : : i n t e g e r < a n n o B i l a n c i o   o r   m o v . m o v g e s t _ a n n o : : i n t e g e r > a n n o B i l a n c i o 
 
           - -   e s s e n d o   r e i m p u t a z i o n i   c o n s i d e r i a m o   s o l o   m o v . m o v g e s t _ a n n o : : i n t e g e r > a n n o B i l a n c i o 
 
           - -   c h e     h a n n o     a t t r i b u t o   = ' S ' 
 
           s t r M e s s a g g i o : = ' G e s t i o n e   a t t r i b u t o   ' | | F R A Z I O N A B I L E _ A T T R | | ' .   A g g i o r n a m e n t o   v a l o r e   N   p e r   i m p e g n i   p l u r i e n n a l i . ' ; 
 
 	   u p d a t e     s i a c _ r _ m o v g e s t _ t s _ a t t r   r   s e t   b o o l e a n = ' N ' 
 
 	   f r o m   s i a c _ t _ m o v g e s t   m o v ,   s i a c _ t _ m o v g e s t _ t s   t s 
 
 	   w h e r e     m o v . b i l _ i d = b i l a n c i o I d 
 
 - - 	 	 a n d       (   m o v . m o v g e s t _ a n n o : : i n t e g e r < 2 0 1 7   o r   m o v . m o v g e s t _ a n n o : : i n t e g e r > 2 0 1 7 ) 
 
 	   a n d       m o v . m o v g e s t _ a n n o : : i n t e g e r > a n n o B i l a n c i o 
 
 	   a n d       m o v . m o v g e s t _ t i p o _ i d = t i p o M o v G e s t I d 
 
 	   a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
           a n d       t s . m o v g e s t _ t s _ t i p o _ i d = t i p o M o v G e s t T s T I d 
 
 	   a n d       r . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
           a n d       r . a t t r _ i d = f l a g F r a z A t t r I d 
 
 	   a n d       r . b o o l e a n = ' S ' 
 
           a n d       r . l o g i n _ o p e r a z i o n e = l o g i n O p e r a z i o n e 
 
           a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d       r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
           - -   a g g i o r n a m e n t o   N   p e r   i m p e g n i   m o v . m o v g e s t _ a n n o : : i n t e g e r = a n n o B i l a n c i o   e   a t t o . a t t o a m m _ a n n o : : i n t e g e r   <   a n n o B i l a n c i o 
 
           - -   c h e     h a n n o     a t t r i b u t o   = ' S ' 
 
           s t r M e s s a g g i o : = ' G e s t i o n e   a t t r i b u t o   ' | | F R A Z I O N A B I L E _ A T T R | | ' .   A g g i o r n a m e n t o   v a l o r e   N   p e r   i m p e g n i   d i   c o m p e t e n z a   c o n   a t t o   a m m i n i s t r a t i v o   a n t e c e d e n t e . ' ; 
 
           u p d a t e   s i a c _ r _ m o v g e s t _ t s _ a t t r   r   s e t   b o o l e a n = ' N ' 
 
     	   f r o m   s i a c _ t _ m o v g e s t   m o v ,   s i a c _ t _ m o v g e s t _ t s   t s , 
 
 	             s i a c _ r _ m o v g e s t _ t s _ a t t o _ a m m   r a , s i a c _ t _ a t t o _ a m m   a t t o 
 
     	   w h e r e   m o v . b i l _ i d = b i l a n c i o I d 
 
 	   a n d       m o v . m o v g e s t _ a n n o : : I N T E G E R = a n n o B i l a n c i o 
 
 	   a n d       m o v . m o v g e s t _ t i p o _ i d = t i p o M o v G e s t I d 
 
 	   a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
           a n d       t s . m o v g e s t _ t s _ t i p o _ i d = t i p o M o v G e s t T s T I d 
 
 	   a n d       r . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
           a n d       r . a t t r _ i d = f l a g F r a z A t t r I d 
 
 	   a n d       r a . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
 	   a n d       a t t o . a t t o a m m _ i d = r a . a t t o a m m _ i d 
 
 	   a n d       a t t o . a t t o a m m _ a n n o : : i n t e g e r   <   a n n o B i l a n c i o 
 
 	   a n d       r . b o o l e a n = ' S ' 
 
           a n d       r . l o g i n _ o p e r a z i o n e = l o g i n O p e r a z i o n e 
 
           a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
           a n d       r a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d       r a . v a l i d i t a _ f i n e   i s   n u l l ; 
 
         e n d   i f ; 
 
         - -   1 5 . 0 2 . 2 0 1 7   S o f i a   S I A C - 4 4 2 5   -   g e s t i o n e   a t t r i b u t o   f l a g F r a z i o n a b i l e 
 
 
 
 
 
         o u t f a s e b i l e l a b r e t i d : = p _ f a s e b i l e l a b i d ; 
 
         i f   c l e a n r e c . c o d i c e r i s u l t a t o   =   - 1   t h e n 
 
 	         c o d i c e r i s u l t a t o : = c l e a n r e c . c o d i c e r i s u l t a t o ; 
 
 	         m e s s a g g i o r i s u l t a t o : = c l e a n r e c . m e s s a g g i o r i s u l t a t o ; 
 
         e l s e 
 
 	         c o d i c e r i s u l t a t o : = 0 ; 
 
 	         m e s s a g g i o r i s u l t a t o : = s t r m e s s a g g i o f i n a l e   | | s t r m e s s a g g i o   | | '   F I N E ' ; 
 
         e n d   i f ; 
 
 
 
 
 
 
 
         o u t f a s e b i l e l a b r e t i d : = p _ f a s e b i l e l a b i d ; 
 
         c o d i c e r i s u l t a t o : = 0 ; 
 
         m e s s a g g i o r i s u l t a t o : = s t r m e s s a g g i o f i n a l e   | | s t r m e s s a g g i o   | | '   F I N E ' ; 
 
         R E T U R N ; 
 
     E X C E P T I O N 
 
     W H E N   r a i s e _ e x c e p t i o n   T H E N 
 
         R A I S E   n o t i c e   ' %   %   E R R O R E   :   % ' , s t r m e s s a g g i o f i n a l e , s t r m e s s a g g i o , s u b s t r i n g ( u p p e r ( S Q L E R R M )   F R O M   1   F O R   1 5 0 0 ) ; 
 
         m e s s a g g i o r i s u l t a t o : = s t r m e s s a g g i o f i n a l e   | | s t r m e s s a g g i o   | | ' E R R O R E   : '   | | '   '   | | s u b s t r i n g ( u p p e r ( S Q L E R R M )   F R O M   1   F O R   1 5 0 0 )   ; 
 
         c o d i c e r i s u l t a t o : = - 1 ; 
 
         o u t f a s e b i l e l a b r e t i d : = p _ f a s e b i l e l a b i d ; 
 
         R E T U R N ; 
 
     W H E N   n o _ d a t a _ f o u n d   T H E N 
 
         R A I S E   n o t i c e   '   %   %   N e s s u n   e l e m e n t o   t r o v a t o . '   , s t r m e s s a g g i o f i n a l e , s t r m e s s a g g i o ; 
 
         m e s s a g g i o r i s u l t a t o : = s t r m e s s a g g i o f i n a l e   | | s t r m e s s a g g i o   | | ' N e s s u n   e l e m e n t o   t r o v a t o . '   ; 
 
         c o d i c e r i s u l t a t o : = - 1 ; 
 
         o u t f a s e b i l e l a b r e t i d : = p _ f a s e b i l e l a b i d ; 
 
         R E T U R N ; 
 
     W H E N   O T H E R S   T H E N 
 
         R A I S E   n o t i c e   ' %   %   E r r o r e   D B   %   % ' , s t r m e s s a g g i o f i n a l e , s t r m e s s a g g i o , S Q L S T A T E , s u b s t r i n g ( u p p e r ( S Q L E R R M )   F R O M   1   F O R   1 5 0 0 ) ; 
 
         m e s s a g g i o r i s u l t a t o : = s t r m e s s a g g i o f i n a l e   | | s t r m e s s a g g i o   | | ' E r r o r e   D B   '   | | S Q L S T A T E   | | '   '   | | s u b s t r i n g ( u p p e r ( S Q L E R R M )   F R O M   1   F O R   1 5 0 0 )   ; 
 
         c o d i c e r i s u l t a t o : = - 1 ; 
 
         o u t f a s e b i l e l a b r e t i d : = p _ f a s e b i l e l a b i d ; 
 
         R E T U R N ; 
 
     E N D ; 
 
     $ b o d y $   L A N G U A G E   ' p l p g s q l '   v o l a t i l e   c a l l e d   O N   N U L L   i n p u t   s e c u r i t y   i n v o k e r   c o s t   1 0 0 ; 