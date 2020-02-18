/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 02.05.2016 Davide - predisposizione bilancio provvisorio da gestione precedente
-- bilancio gestione annoBilancio-1
--06.04.2016 Anto - predisposizione bilancio di previsione da gestione precedente
-- bilancio gestione annoBilancio-1
-- 07.07.2016 Anto - adeguamenti per backup
-- 04.11.2016 Anto JIRA-SIAC-4161- aggiunto esclusione dei capitoli annullati
-- 11.11.2016 Anto JIRA-SIAC-4167- gestione segnalazioni e ribaltamento anche se classificatori non validi
CREATE OR replace FUNCTION fnc_fasi_bil_provv_apertura_struttura ( annobilancio      INTEGER,
                                                                  euelemtipo         VARCHAR,
                                                                  bilelemgesttipo    VARCHAR,
                                                                  checkgest          BOOLEAN, -- TRUE: il dato provvisorio esistente viene aggiornato al dato di gestione prec, FALSE il dato provvisorio esistente non viene aggiornato.
                                                                  enteproprietarioid INTEGER,
                                                                  loginoperazione    VARCHAR,
                                                                  dataelaborazione TIMESTAMP,
                                                                  OUT fasebilelabidret   INTEGER,
                                                                  OUT codicerisultato    INTEGER,
                                                                  OUT messaggiorisultato VARCHAR )
returns RECORD
AS
  $body$
  DECLARE
    strmessaggio       VARCHAR(1500):='';
    strmessaggiofinale VARCHAR(1500):='';
    -- tipo periodo annuale
    sy_per_tipo CONSTANT VARCHAR:='SY';
    -- tipo anno ordinario annuale
    bil_ord_tipo     CONSTANT VARCHAR:='BIL_ORD';
    provvisorio_fase CONSTANT VARCHAR:='E';
    elembil RECORD;
    -- CLASSIFICATORI
    cl_macroaggregato         CONSTANT VARCHAR :='MACROAGGREGATO';
    cl_programma              CONSTANT VARCHAR :='PROGRAMMA';
    cl_categoria              CONSTANT VARCHAR :='CATEGORIA';
    cl_cdc                    CONSTANT VARCHAR :='CDC';
    cl_cdr                    CONSTANT VARCHAR :='CDR';
    cl_ricorrente_spesa       CONSTANT VARCHAR:='RICORRENTE_SPESA';
    cl_ricorrente_entrata     CONSTANT VARCHAR:='RICORRENTE_ENTRATA';
    cl_transazione_ue_spesa   CONSTANT VARCHAR:='TRANSAZIONE_UE_SPESA';
    cl_transazione_ue_entrata CONSTANT VARCHAR:='TRANSAZIONE_UE_ENTRATA';
    cl_pdc_fin_quarto         CONSTANT VARCHAR :='PDC_IV';
    cl_pdc_fin_quinto         CONSTANT VARCHAR :='PDC_V';
    cl_cofog                  CONSTANT VARCHAR :='GRUPPO_COFOG';
    cl_siope_spesa_terzo      CONSTANT VARCHAR:='SIOPE_SPESA_I';
    cl_siope_entrata_terzo    CONSTANT VARCHAR:='SIOPE_ENTRATA_I';
    tipo_elab_p               CONSTANT VARCHAR :='P'; -- previsione
    tipo_elab_g               CONSTANT VARCHAR :='G'; -- gestione
    tipo_elem_eu              CONSTANT VARCHAR:='U';
    ape_prov_da_gest          CONSTANT VARCHAR:='APE_PROV';
    macroaggrtipoid           INTEGER:=NULL;
    programmatipoid           INTEGER:=NULL;
    categoriatipoid           INTEGER:=NULL;
    cdctipoid                 INTEGER:=NULL;
    cdrtipoid                 INTEGER:=NULL;
    ricorrentespesaid         INTEGER:=NULL;
    transazioneuespesaid      INTEGER:=NULL;
    ricorrenteentrataid       INTEGER:=NULL;
    transazioneueentrataid    INTEGER:=NULL;
    pdcfinivid                INTEGER:=NULL;
    pdcfinvid                 INTEGER:=NULL;
    cofogtipoid               INTEGER:=NULL;
    siopespesatipoid          INTEGER:=NULL;
    siopeentratatipoid        INTEGER:=NULL;
    bilelemgesttipoid         INTEGER:=NULL;
    bilelemidret              INTEGER:=NULL;
    bilancioid                INTEGER:=NULL;
    periodoid                 INTEGER:=NULL;
    bilancioprecid            INTEGER:=NULL;
    periodoprecid             INTEGER:=NULL;
    codresult                 INTEGER:=NULL;
    datainizioval timestamp:=NULL;
    fasebilelabid    INTEGER:=NULL;
    categoria_std    CONSTANT VARCHAR := 'STD';
    categoriacapcode VARCHAR :=NULL;
    -- 04.11.2016 Anto JIRA-SIAC-4161
    bilelemstatoan CONSTANT VARCHAR:='AN';
    -- 04.11.2016 Anto JIRA-SIAC-4161
    bilelemstatoanid INTEGER:=NULL;
    -- Anto JIRA-SIAC-4167 15.11.2016
    datainiziovalclass timestamp:=NULL;
    datafinevalclass timestamp:=NULL;
    _row_count INTEGER:=0;

    v_dataprimogiornoanno timestamp:=NULL;

  BEGIN
    -- Sofia JIRA-SIAC-4167 15.11.2016
    datainiziovalclass:= clock_timestamp();
    datafinevalclass:= (annobilancio
    ||'-01-01')::timestamp;

     v_dataprimogiornoanno:= (annobilancio
    ||'-01-01')::timestamp;

    messaggiorisultato:='';
    codicerisultato:=0;
    fasebilelabidret:=0;
    datainizioval:= clock_timestamp();
    strmessaggiofinale:='Apertura bilancio provvisorio.Creazione struttura Provvisorio '
    ||bilelemgesttipo
    ||' da Gestione precedente '
    ||bilelemgesttipo
    || '.Anno bilancio='
    ||annobilancio::VARCHAR
    ||'.';
    -- inserimento fase_bil_t_elaborazione
    strmessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    INSERT INTO fase_bil_t_elaborazione
                (
                            fase_bil_elab_esito,
                            fase_bil_elab_esito_msg,
                            fase_bil_elab_tipo_id,
                            ente_proprietario_id,
                            validita_inizio,
                            login_operazione
                )
                (
                       SELECT 'IN',
                              'ELABORAZIONE FASE BILANCIO '
                                     ||ape_prov_da_gest
                                     ||' IN CORSO : CREAZIONE STRUTTURE.',
                              tipo.fase_bil_elab_tipo_id,
                              enteproprietarioid,
                              datainizioval,
                              loginoperazione
                       FROM   fase_bil_d_elaborazione_tipo tipo
                       WHERE  tipo.ente_proprietario_id=enteproprietarioid
                       AND    tipo.fase_bil_elab_tipo_code=ape_prov_da_gest
                       AND    tipo.data_cancellazione IS NULL
                       AND    tipo.validita_fine IS NULL)
    returning   fase_bil_elab_id
    INTO        fasebilelabid;

    IF fasebilelabid IS NULL THEN
      RAISE
    EXCEPTION
      ' Inserimento non effettuato.';
    END IF;
    codresult:=NULL;
    INSERT INTO fase_bil_t_elaborazione_log
                (
                            fase_bil_elab_id,
                            fase_bil_elab_log_operazione,
                            validita_inizio,
                            login_operazione,
                            ente_proprietario_id
                )
                VALUES
                (
                            fasebilelabid,
                            strmessaggio,
                            clock_timestamp(),
                            loginoperazione,
                            enteproprietarioid
                )
    returning   fase_bil_elab_log_id
    INTO        codresult;

    IF codresult IS NULL THEN
      RAISE
    EXCEPTION
      ' Errore in inserimento LOG.';
    END IF;
    -- 04.11.2016 Anto JIRA-SIAC-4161
    strmessaggio:='Lettura bilElemStatoAN  per tipo='
    ||bilelemstatoan
    ||'.';
    SELECT tipo.elem_stato_id
    INTO   strict bilelemstatoanid
    FROM   siac_d_bil_elem_stato tipo
    WHERE  tipo.elem_stato_code=bilelemstatoan
    AND    tipo.ente_proprietario_id=enteproprietarioid
    AND    tipo.data_cancellazione IS NULL
    AND    date_trunc('day',dataelaborazione)>=date_trunc('day',tipo.validita_inizio)
    AND    (
                  date_trunc('day',dataelaborazione)<=date_trunc('day',tipo.validita_fine)
           OR     tipo.validita_fine IS NULL);

    strmessaggio:='Lettura bilElemGestTipo  per tipo='
    ||bilelemgesttipo
    ||'.';
    SELECT tipo.elem_tipo_id
    INTO   strict bilelemgesttipoid
    FROM   siac_d_bil_elem_tipo tipo
    WHERE  tipo.elem_tipo_code=bilelemgesttipo
    AND    tipo.ente_proprietario_id=enteproprietarioid
    AND    tipo.data_cancellazione IS NULL
    AND    date_trunc('day',dataelaborazione)>=date_trunc('day',tipo.validita_inizio)
    AND    (
                  date_trunc('day',dataelaborazione)<=date_trunc('day',tipo.validita_fine)
           OR     tipo.validita_fine IS NULL);

    strmessaggio:='Lettura cdcTipoId  per classif='
    ||cl_cdc
    ||'.';
    SELECT tipo.classif_tipo_id
    INTO   strict cdctipoid
    FROM   siac_d_class_tipo tipo
    WHERE  tipo.ente_proprietario_id=enteproprietarioid
    AND    tipo.classif_tipo_code=cl_cdc
    AND    tipo.data_cancellazione IS NULL
    AND    date_trunc('day',dataelaborazione)>=date_trunc('day',tipo.validita_inizio)
    AND    (
                  date_trunc('day',dataelaborazione)<=date_trunc('day',tipo.validita_fine)
           OR     tipo.validita_fine IS NULL);

    strmessaggio:='Lettura cdcTipoId  per classif='
    ||cl_cdr
    ||'.';
    SELECT tipo.classif_tipo_id
    INTO   strict cdrtipoid
    FROM   siac_d_class_tipo tipo
    WHERE  tipo.ente_proprietario_id=enteproprietarioid
    AND    tipo.classif_tipo_code=cl_cdr
    AND    tipo.data_cancellazione IS NULL
    AND    date_trunc('day',dataelaborazione)>=date_trunc('day',tipo.validita_inizio)
    AND    (
                  date_trunc('day',dataelaborazione)<=date_trunc('day',tipo.validita_fine)
           OR     tipo.validita_fine IS NULL);

    strmessaggio:='Lettura pdcFinIVId  per classif='
    ||cl_pdc_fin_quarto
    ||'.';
    SELECT tipo.classif_tipo_id
    INTO   strict pdcfinivid
    FROM   siac_d_class_tipo tipo
    WHERE  tipo.ente_proprietario_id=enteproprietarioid
    AND    tipo.classif_tipo_code=cl_pdc_fin_quarto
    AND    tipo.data_cancellazione IS NULL
    AND    date_trunc('day',dataelaborazione)>=date_trunc('day',tipo.validita_inizio)
    AND    (
                  date_trunc('day',dataelaborazione)<=date_trunc('day',tipo.validita_fine)
           OR     tipo.validita_fine IS NULL);

    strmessaggio:='Lettura pdcFinVId  per classif='
    ||cl_pdc_fin_quinto
    ||'.';
    SELECT tipo.classif_tipo_id
    INTO   strict pdcfinvid
    FROM   siac_d_class_tipo tipo
    WHERE  tipo.ente_proprietario_id=enteproprietarioid
    AND    tipo.classif_tipo_code=cl_pdc_fin_quinto
    AND    tipo.data_cancellazione IS NULL
    AND    date_trunc('day',dataelaborazione)>=date_trunc('day',tipo.validita_inizio)
    AND    (
                  date_trunc('day',dataelaborazione)<=date_trunc('day',tipo.validita_fine)
           OR     tipo.validita_fine IS NULL);

    IF euelemtipo=tipo_elem_eu THEN
      strmessaggio:='Lettura macroAggrTipoId  per classif='
      ||cl_macroaggregato
      ||'.';
      SELECT tipo.classif_tipo_id
      INTO   strict macroaggrtipoid
      FROM   siac_d_class_tipo tipo
      WHERE  tipo.ente_proprietario_id=enteproprietarioid
      AND    tipo.classif_tipo_code=cl_macroaggregato
      AND    tipo.data_cancellazione IS NULL
      AND    date_trunc('day',dataelaborazione)>=date_trunc('day',tipo.validita_inizio)
      AND    (
                    date_trunc('day',dataelaborazione)<=date_trunc('day',tipo.validita_fine)
             OR     tipo.validita_fine IS NULL);

      strmessaggio:='Lettura programmaTipoId  per classif='
      ||cl_programma
      ||'.';
      SELECT tipo.classif_tipo_id
      INTO   strict programmatipoid
      FROM   siac_d_class_tipo tipo
      WHERE  tipo.ente_proprietario_id=enteproprietarioid
      AND    tipo.classif_tipo_code=cl_programma
      AND    tipo.data_cancellazione IS NULL
      AND    date_trunc('day',dataelaborazione)>=date_trunc('day',tipo.validita_inizio)
      AND    (
                    date_trunc('day',dataelaborazione)<=date_trunc('day',tipo.validita_fine)
             OR     tipo.validita_fine IS NULL);

      strmessaggio:='Lettura ricorrenteSpesaId  per classif='
      ||cl_ricorrente_spesa
      ||'.';
      SELECT tipo.classif_tipo_id
      INTO   strict ricorrentespesaid
      FROM   siac_d_class_tipo tipo
      WHERE  tipo.ente_proprietario_id=enteproprietarioid
      AND    tipo.classif_tipo_code=cl_ricorrente_spesa
      AND    tipo.data_cancellazione IS NULL
      AND    date_trunc('day',dataelaborazione)>=date_trunc('day',tipo.validita_inizio)
      AND    (
                    date_trunc('day',dataelaborazione)<=date_trunc('day',tipo.validita_fine)
             OR     tipo.validita_fine IS NULL);

      strmessaggio:='Lettura transazioneUeSpesaId  per classif='
      ||cl_transazione_ue_spesa
      ||'.';
      SELECT tipo.classif_tipo_id
      INTO   strict transazioneuespesaid
      FROM   siac_d_class_tipo tipo
      WHERE  tipo.ente_proprietario_id=enteproprietarioid
      AND    tipo.classif_tipo_code=cl_transazione_ue_spesa
      AND    tipo.data_cancellazione IS NULL
      AND    date_trunc('day',dataelaborazione)>=date_trunc('day',tipo.validita_inizio)
      AND    (
                    date_trunc('day',dataelaborazione)<=date_trunc('day',tipo.validita_fine)
             OR     tipo.validita_fine IS NULL);

      strmessaggio:='Lettura cofogTipoId  per classif='
      ||cl_cofog
      ||'.';
      SELECT tipo.classif_tipo_id
      INTO   strict cofogtipoid
      FROM   siac_d_class_tipo tipo
      WHERE  tipo.ente_proprietario_id=enteproprietarioid
      AND    tipo.classif_tipo_code=cl_cofog
      AND    tipo.data_cancellazione IS NULL
      AND    date_trunc('day',dataelaborazione)>=date_trunc('day',tipo.validita_inizio)
      AND    (
                    date_trunc('day',dataelaborazione)<=date_trunc('day',tipo.validita_fine)
             OR     tipo.validita_fine IS NULL);

      strmessaggio:='Lettura siopeSpesaTipoId  per classif='
      ||cl_siope_spesa_terzo
      ||'.';
      SELECT tipo.classif_tipo_id
      INTO   strict siopespesatipoid
      FROM   siac_d_class_tipo tipo
      WHERE  tipo.ente_proprietario_id=enteproprietarioid
      AND    tipo.classif_tipo_code=cl_siope_spesa_terzo
      AND    tipo.data_cancellazione IS NULL
      AND    date_trunc('day',dataelaborazione)>=date_trunc('day',tipo.validita_inizio)
      AND    (
                    date_trunc('day',dataelaborazione)<=date_trunc('day',tipo.validita_fine)
             OR     tipo.validita_fine IS NULL);

    ELSE
      strmessaggio:='Lettura categoriaTipoId  per classif='
      ||cl_categoria
      ||'.';
      SELECT tipo.classif_tipo_id
      INTO   strict categoriatipoid
      FROM   siac_d_class_tipo tipo
      WHERE  tipo.ente_proprietario_id=enteproprietarioid
      AND    tipo.classif_tipo_code=cl_categoria
      AND    tipo.data_cancellazione IS NULL
      AND    date_trunc('day',dataelaborazione)>=date_trunc('day',tipo.validita_inizio)
      AND    (
                    date_trunc('day',dataelaborazione)<=date_trunc('day',tipo.validita_fine)
             OR     tipo.validita_fine IS NULL);

      strmessaggio:='Lettura ricorrenteEntrataId  per classif='
      ||cl_ricorrente_entrata
      ||'.';
      SELECT tipo.classif_tipo_id
      INTO   strict ricorrenteentrataid
      FROM   siac_d_class_tipo tipo
      WHERE  tipo.ente_proprietario_id=enteproprietarioid
      AND    tipo.classif_tipo_code=cl_ricorrente_entrata
      AND    tipo.data_cancellazione IS NULL
      AND    date_trunc('day',dataelaborazione)>=date_trunc('day',tipo.validita_inizio)
      AND    (
                    date_trunc('day',dataelaborazione)<=date_trunc('day',tipo.validita_fine)
             OR     tipo.validita_fine IS NULL);

      strmessaggio:='Lettura transazioneUeEntrataId  per classif='
      ||cl_transazione_ue_entrata
      ||'.';
      SELECT tipo.classif_tipo_id
      INTO   strict transazioneueentrataid
      FROM   siac_d_class_tipo tipo
      WHERE  tipo.ente_proprietario_id=enteproprietarioid
      AND    tipo.classif_tipo_code=cl_transazione_ue_entrata
      AND    tipo.data_cancellazione IS NULL
      AND    date_trunc('day',dataelaborazione)>=date_trunc('day',tipo.validita_inizio)
      AND    (
                    date_trunc('day',dataelaborazione)<=date_trunc('day',tipo.validita_fine)
             OR     tipo.validita_fine IS NULL);

      strmessaggio:='Lettura siopeEntrataTipoId  per classif='
      ||cl_siope_entrata_terzo
      ||'.';
      SELECT tipo.classif_tipo_id
      INTO   strict siopeentratatipoid
      FROM   siac_d_class_tipo tipo
      WHERE  tipo.ente_proprietario_id=enteproprietarioid
      AND    tipo.classif_tipo_code=cl_siope_entrata_terzo
      AND    tipo.data_cancellazione IS NULL
      AND    date_trunc('day',dataelaborazione)>=date_trunc('day',tipo.validita_inizio)
      AND    (
                    date_trunc('day',dataelaborazione)<=date_trunc('day',tipo.validita_fine)
             OR     tipo.validita_fine IS NULL);

    END IF;
    -- fine lettura classificatori Tipo Id
    strmessaggio:='Inserimento LOG per lettura classificatori tipo.';
    codresult:=NULL;
    INSERT INTO fase_bil_t_elaborazione_log
                (
                            fase_bil_elab_id,
                            fase_bil_elab_log_operazione,
                            validita_inizio,
                            login_operazione,
                            ente_proprietario_id
                )
                VALUES
                (
                            fasebilelabid,
                            strmessaggio,
                            clock_timestamp(),
                            loginoperazione,
                            enteproprietarioid
                )
    returning   fase_bil_elab_log_id
    INTO        codresult;

    IF codresult IS NULL THEN
      RAISE
    EXCEPTION
      ' Errore in inserimento LOG.';
    END IF;
    strmessaggio:='Inserimento bilancio  per annoBilancio='
    ||annobilancio::VARCHAR
    ||'.';
    INSERT INTO siac_t_bil
                (
                            bil_code,
                            bil_desc,
                            bil_tipo_id,
                            periodo_id,
                            validita_inizio,
                            ente_proprietario_id,
                            login_operazione
                )
                (
                       SELECT 'BIL_'
                                     ||annobilancio::VARCHAR,
                              'Bilancio '
                                     ||annobilancio::VARCHAR,
                              btipo.bil_tipo_id,
                              per.periodo_id,
                              datainizioval,
                              per.ente_proprietario_id,
                              loginoperazione
                       FROM   siac_t_periodo per ,
                              siac_d_periodo_tipo tipo,
                              siac_d_bil_tipo btipo
                       WHERE  per.ente_proprietario_id=enteproprietarioid
                       AND    per.anno::INTEGER=annobilancio
                       AND    tipo.periodo_tipo_id=per.periodo_tipo_id
                       AND    tipo.periodo_tipo_code=sy_per_tipo
                       AND    btipo.ente_proprietario_id=per.ente_proprietario_id
                       AND    btipo.bil_tipo_code=bil_ord_tipo
                       AND    per.data_cancellazione IS NULL
                       AND    NOT EXISTS
                              (
                                     SELECT 1
                                     FROM   siac_t_bil bil
                                     WHERE  bil.ente_proprietario_id=per.ente_proprietario_id
                                     AND    bil.bil_tipo_id=btipo.bil_tipo_id
                                     AND    bil.periodo_id=per.periodo_id
                                     AND    bil.data_cancellazione IS NULL));

    strmessaggio:='Inserimento periodo  per annoBilancio+2='
    ||(annobilancio+2)::VARCHAR
    ||'.';
    INSERT INTO siac_t_periodo
                (
                            periodo_code,
                            periodo_desc,
                            data_inizio,
                            data_fine,
                            validita_inizio,
                            periodo_tipo_id,
                            anno,
                            ente_proprietario_id,
                            login_operazione
                )
                (
                       SELECT 'anno'
                                     ||(annobilancio+2)::VARCHAR,
                              'anno'
                                     ||(annobilancio+2)::VARCHAR,
                              ((annobilancio+2)::VARCHAR
                                     ||'-01-01')::timestamp,
                              ((annobilancio+2)::VARCHAR
                                     ||'-12-31')::timestamp,
                              datainizioval,
                              tipo.periodo_tipo_id,
                              (annobilancio+2)::VARCHAR,
                              tipo.ente_proprietario_id,
                              loginoperazione
                       FROM   siac_d_periodo_tipo tipo
                       WHERE  tipo.ente_proprietario_id=enteproprietarioid
                       AND    tipo.periodo_tipo_code=sy_per_tipo
                       AND    NOT EXISTS
                              (
                                     SELECT 1
                                     FROM   siac_t_periodo per1
                                     WHERE  per1.periodo_tipo_id=tipo.periodo_tipo_id
                                     AND    per1.anno::INTEGER=annobilancio+2
                                     AND    per1.data_cancellazione IS NULL));

    codresult:=NULL;
    strmessaggio:='Inserimento annoBilancio='
    ||annobilancio::VARCHAR
    ||' periodo per annoCompetenza='
    ||(annobilancio+2)::VARCHAR
    ||'.';
    INSERT INTO fase_bil_t_elaborazione_log
                (
                            fase_bil_elab_id,
                            fase_bil_elab_log_operazione,
                            validita_inizio,
                            login_operazione,
                            ente_proprietario_id
                )
                VALUES
                (
                            fasebilelabid,
                            strmessaggio,
                            clock_timestamp(),
                            loginoperazione,
                            enteproprietarioid
                )
    returning   fase_bil_elab_log_id
    INTO        codresult;

    IF codresult IS NULL THEN
      RAISE
    EXCEPTION
      ' Errore in inserimento LOG.';
    END IF;
    strmessaggio:='Lettura bilancioId e periodoId  per annoBilancio='
    ||annobilancio::VARCHAR
    ||'.';
    SELECT bil.bil_id ,
           per.periodo_id
    INTO   strict bilancioid,
           periodoid
    FROM   siac_t_bil bil,
           siac_t_periodo per
    WHERE  bil.ente_proprietario_id=enteproprietarioid
    AND    per.periodo_id=bil.periodo_id
    AND    per.anno::INTEGER=annobilancio
    AND    bil.data_cancellazione IS NULL
    AND    per.data_cancellazione IS NULL;

    codresult:=NULL;
    INSERT INTO fase_bil_t_elaborazione_log
                (
                            fase_bil_elab_id,
                            fase_bil_elab_log_operazione,
                            validita_inizio,
                            login_operazione,
                            ente_proprietario_id
                )
                VALUES
                (
                            fasebilelabid,
                            strmessaggio,
                            clock_timestamp(),
                            loginoperazione,
                            enteproprietarioid
                )
    returning   fase_bil_elab_log_id
    INTO        codresult;

    IF codresult IS NULL THEN
      RAISE
    EXCEPTION
      ' Errore in inserimento LOG.';
    END IF;
    strmessaggio:='Cancellazione fase tipo diversa da '
    ||provvisorio_fase
    ||' per bilancio annoBilancio='
    ||annobilancio::VARCHAR
    ||'.';
    DELETE
    FROM   siac_r_bil_fase_operativa r
    WHERE  r.ente_proprietario_id=enteproprietarioid
    AND    r.data_cancellazione IS NULL
    AND    r.validita_fine IS NULL
    AND    r.bil_id=bilancioid
    AND    EXISTS
           (
                  SELECT 1
                  FROM   siac_d_fase_operativa d
                  WHERE  d.fase_operativa_id=r.fase_operativa_id
                  AND    d.fase_operativa_code!=provvisorio_fase);

    strmessaggio:='Inserimento fase tipo='
    ||provvisorio_fase
    ||' per bilancio annoBilancio='
    ||annobilancio::VARCHAR
    ||'.';
    INSERT INTO siac_r_bil_fase_operativa
                (
                            bil_id,
                            fase_operativa_id,
                            validita_inizio,
                            ente_proprietario_id,
                            login_operazione
                )
                (
                       SELECT bilancioid,
                              f.fase_operativa_id,
                              datainizioval,
                              f.ente_proprietario_id,
                              loginoperazione
                       FROM   siac_d_fase_operativa f
                       WHERE  f.ente_proprietario_id=enteproprietarioid
                       AND    f.fase_operativa_code=provvisorio_fase
                       AND    NOT EXISTS
                              (
                                     SELECT 1
                                     FROM   siac_r_bil_fase_operativa r
                                     WHERE  r.bil_id=bilancioid
                                            --and    r.fase_operativa_id=f.fase_operativa_id
                                     AND    r.data_cancellazione IS NULL));

    codresult:=NULL;
    INSERT INTO fase_bil_t_elaborazione_log
                (
                            fase_bil_elab_id,
                            fase_bil_elab_log_operazione,
                            validita_inizio,
                            login_operazione,
                            ente_proprietario_id
                )
                VALUES
                (
                            fasebilelabid,
                            strmessaggio,
                            clock_timestamp(),
                            loginoperazione,
                            enteproprietarioid
                )
    returning   fase_bil_elab_log_id
    INTO        codresult;

    IF codresult IS NULL THEN
      RAISE
    EXCEPTION
      ' Errore in inserimento LOG.';
    END IF;
    strmessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='
    ||(annobilancio-1)::VARCHAR
    ||'.';
    SELECT bil.bil_id ,
           per.periodo_id
    INTO   strict bilancioprecid,
           periodoprecid
    FROM   siac_t_bil bil,
           siac_t_periodo per
    WHERE  bil.ente_proprietario_id=enteproprietarioid
    AND    per.periodo_id=bil.periodo_id
    AND    per.anno::INTEGER=annobilancio-1
    AND    per.data_cancellazione IS NULL;

    codresult:=NULL;
    INSERT INTO fase_bil_t_elaborazione_log
                (
                            fase_bil_elab_id,
                            fase_bil_elab_log_operazione,
                            validita_inizio,
                            login_operazione,
                            ente_proprietario_id
                )
                VALUES
                (
                            fasebilelabid,
                            strmessaggio,
                            clock_timestamp(),
                            loginoperazione,
                            enteproprietarioid
                )
    returning   fase_bil_elab_log_id
    INTO        codresult;

    IF codresult IS NULL THEN
      RAISE
    EXCEPTION
      ' Errore in inserimento LOG.';
    END IF;
    -- capitoli gestione provvisoria nuovi non esistenti in gestione corrente
    strmessaggio:='Popolamento fase_bil_t_gest_apertura_provv.Provvisorio nuovo con gestione eq anno precedente. Non esistenti in gestione corrente.';
    INSERT INTO fase_bil_t_gest_apertura_provv
                (
                            elem_id,
                            elem_code,
                            elem_code2,
                            elem_code3,
                            bil_id,
                            fase_bil_elab_id,
                            ente_proprietario_id,
                            validita_inizio,
                            login_operazione
                )
                (
                         SELECT   gest.elem_id,
                                  gest.elem_code,
                                  gest.elem_code2,
                                  gest.elem_code3,
                                  bilancioid,
                                  fasebilelabid,
                                  gest.ente_proprietario_id,
                                  datainizioval,
                                  loginoperazione
                         FROM     siac_t_bil_elem gest
                         WHERE    gest.ente_proprietario_id=enteproprietarioid
                         AND      gest.elem_tipo_id=bilelemgesttipoid
                         AND      gest.bil_id=bilancioprecid
                         AND      gest.data_cancellazione IS NULL
                         AND      date_trunc('day',dataelaborazione)>=date_trunc('day',gest.validita_inizio)
                         AND      (
                                           date_trunc('day',dataelaborazione)<=date_trunc('day',gest.validita_fine)
                                  OR       gest.validita_fine IS NULL)
                         AND      EXISTS
                                  (
                                         SELECT 1
                                         FROM   siac_r_bil_elem_stato rstato -- 04.11.2016 Anto JIRA-SIAC-4161
                                         WHERE  rstato.elem_id=gest.elem_id
                                         AND    rstato.elem_stato_id!=bilelemstatoanid
                                         AND    rstato.data_cancellazione IS NULL
                                         AND    rstato.validita_fine isnull )
                         AND      NOT EXISTS
                                  (
                                           SELECT   1
                                           FROM     siac_t_bil_elem gestcorr
                                           WHERE    gestcorr.ente_proprietario_id=gest.ente_proprietario_id
                                           AND      gestcorr.bil_id=bilancioid
                                           AND      gestcorr.elem_tipo_id=gest.elem_tipo_id
                                           AND      gestcorr.elem_code=gest.elem_code
                                           AND      gestcorr.elem_code2=gest.elem_code2
                                           AND      gestcorr.elem_code3=gest.elem_code3
                                           AND      EXISTS
                                                    (
                                                           SELECT 1
                                                           FROM   siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
                                                           WHERE  rstato.elem_id=gestcorr.elem_id
                                                           AND    rstato.elem_stato_id!=bilelemstatoanid
                                                           AND    rstato.data_cancellazione IS NULL
                                                           AND    rstato.validita_fine isnull )
                                           AND      gestcorr.data_cancellazione IS NULL
                                           AND      date_trunc('day',dataelaborazione)>=date_trunc('day',gestcorr.validita_inizio)
                                           AND      (
                                                             date_trunc('day',dataelaborazione)<=date_trunc('day',gestcorr.validita_fine)
                                                    OR       gestcorr.validita_fine IS NULL)
                                           ORDER BY gestcorr.elem_id limit 1 )
                         ORDER BY gest.elem_code:: INTEGER,
                                  gest.elem_code2::INTEGER,
                                  gest.elem_code3 );

    codresult:=NULL;
    INSERT INTO fase_bil_t_elaborazione_log
                (
                            fase_bil_elab_id,
                            fase_bil_elab_log_operazione,
                            validita_inizio,
                            login_operazione,
                            ente_proprietario_id
                )
                VALUES
                (
                            fasebilelabid,
                            strmessaggio,
                            clock_timestamp(),
                            loginoperazione,
                            enteproprietarioid
                )
    returning   fase_bil_elab_log_id
    INTO        codresult;

    IF codresult IS NULL THEN
      RAISE
    EXCEPTION
      ' Errore in inserimento LOG.';
    END IF;
    -- verifica apertura con gestione corrente pre-esistente ( rielaborazione )
    IF checkgest=TRUE THEN
      -- capitoli gestione corrente esistenti con gestione eq anno precendente esistente - da aggiornare
      strmessaggio:='Popolamento fase_bil_t_gest_apertura_provv.Provvisorio esistente con gestione eq anno precedente.';
      INSERT INTO fase_bil_t_gest_apertura_provv
                  (
                              elem_id,
                              elem_code,
                              elem_code2,
                              elem_code3,
                              elem_prov_id,
                              bil_id,
                              fase_bil_elab_id,
                              ente_proprietario_id,
                              validita_inizio,
                              login_operazione
                  )
                  (
                           SELECT   gest.elem_id,
                                    gest.elem_code,
                                    gest.elem_code2,
                                    gest.elem_code3,
                                    gestcorr.elem_id,
                                    bilancioid,
                                    fasebilelabid,
                                    enteproprietarioid,
                                    datainizioval,
                                    loginoperazione
                           FROM     siac_t_bil_elem gest,
                                    siac_t_bil_elem gestcorr
                           WHERE    gest.ente_proprietario_id=enteproprietarioid
                           AND      gest.elem_tipo_id=bilelemgesttipoid
                           AND      gest.bil_id=bilancioprecid
                           AND      gestcorr.ente_proprietario_id=gest.ente_proprietario_id
                           AND      gestcorr.bil_id=bilancioid
                           AND      gestcorr.elem_tipo_id=gest.elem_tipo_id
                           AND      gestcorr.elem_code=gest.elem_code
                           AND      gestcorr.elem_code2=gest.elem_code2
                           AND      gestcorr.elem_code3=gest.elem_code3
                           AND      gest.data_cancellazione IS NULL
                           AND      date_trunc('day',dataelaborazione)>=date_trunc('day',gest.validita_inizio)
                           AND      (
                                             date_trunc('day',dataelaborazione)<=date_trunc('day',gest.validita_fine)
                                    OR       gest.validita_fine IS NULL)
                           AND      gestcorr.data_cancellazione IS NULL
                           AND      date_trunc('day',dataelaborazione)>=date_trunc('day',gestcorr.validita_inizio)
                           AND      (
                                             date_trunc('day',dataelaborazione)<=date_trunc('day',gestcorr.validita_fine)
                                    OR       gestcorr.validita_fine IS NULL)
                           AND      EXISTS
                                    (
                                           SELECT 1
                                           FROM   siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
                                           WHERE  rstato.elem_id=gestcorr.elem_id
                                           AND    rstato.elem_stato_id!=bilelemstatoanid
                                           AND    rstato.data_cancellazione IS NULL
                                           AND    rstato.validita_fine isnull )
                           AND      EXISTS
                                    (
                                           SELECT 1
                                           FROM   siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
                                           WHERE  rstato.elem_id=gest.elem_id
                                           AND    rstato.elem_stato_id!=bilelemstatoanid
                                           AND    rstato.data_cancellazione IS NULL
                                           AND    rstato.validita_fine IS NULL )
                           ORDER BY gest.elem_code:: INTEGER,
                                    gest.elem_code2::INTEGER,
                                    gest.elem_code3 );

      codresult:=NULL;
      INSERT INTO fase_bil_t_elaborazione_log
                  (
                              fase_bil_elab_id,
                              fase_bil_elab_log_operazione,
                              validita_inizio,
                              login_operazione,
                              ente_proprietario_id
                  )
                  VALUES
                  (
                              fasebilelabid,
                              strmessaggio,
                              clock_timestamp(),
                              loginoperazione,
                              enteproprietarioid
                  )
      returning   fase_bil_elab_log_id
      INTO        codresult;

      IF codresult IS NULL THEN
        RAISE
      EXCEPTION
        ' Errore in inserimento LOG.';
      END IF;
      -- capitoli gestione corrente esistenti con gestione eq anno precendente non esistente - da aggiornare
      strmessaggio:='Popolamento fase_bil_t_gest_apertura_provv.Provvisorio esistente con gestione eq anno precedente non esistente.';
      INSERT INTO fase_bil_t_gest_apertura_provv
                  (
                              elem_prov_id,
                              elem_code,
                              elem_code2,
                              elem_code3,
                              bil_id,
                              fase_bil_elab_id,
                              ente_proprietario_id,
                              validita_inizio,
                              login_operazione
                  )
                  (
                           SELECT   gestcorr.elem_id,
                                    gestcorr.elem_code,
                                    gestcorr.elem_code2,
                                    gestcorr.elem_code3,
                                    bilancioid,
                                    fasebilelabid,
                                    enteproprietarioid,
                                    datainizioval,
                                    loginoperazione
                           FROM     siac_t_bil_elem gestcorr
                           WHERE    gestcorr.ente_proprietario_id=enteproprietarioid
                           AND      gestcorr.bil_id=bilancioid
                           AND      gestcorr.elem_tipo_id=bilelemgesttipoid
                           AND      gestcorr.data_cancellazione IS NULL
                           AND      date_trunc('day',dataelaborazione)>=date_trunc('day',gestcorr.validita_inizio)
                           AND      (
                                             date_trunc('day',dataelaborazione)<=date_trunc('day',gestcorr.validita_fine)
                                    OR       gestcorr.validita_fine IS NULL)
                           AND      EXISTS
                                    (
                                           SELECT 1
                                           FROM   siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
                                           WHERE  rstato.elem_id=gestcorr.elem_id
                                           AND    rstato.elem_stato_id!=bilelemstatoanid
                                           AND    rstato.data_cancellazione IS NULL
                                           AND    rstato.validita_fine IS NULL )
                           AND      NOT EXISTS
                                    (
                                           SELECT 1
                                           FROM   siac_t_bil_elem gest
                                           WHERE  gest.ente_proprietario_id=gestcorr.ente_proprietario_id
                                           AND    gest.bil_id=bilancioprecid
                                           AND    gest.elem_tipo_id=gestcorr.elem_tipo_id
                                           AND    gest.elem_code=gestcorr.elem_code
                                           AND    gest.elem_code2=gestcorr.elem_code2
                                           AND    gest.elem_code3=gestcorr.elem_code3
                                           AND    gest.data_cancellazione IS NULL
                                           AND    date_trunc('day',dataelaborazione)>=date_trunc('day',gest.validita_inizio)
                                           AND    (
                                                         date_trunc('day',dataelaborazione)<=date_trunc('day',gest.validita_fine)
                                                  OR     gest.validita_fine IS NULL)
                                           AND    EXISTS
                                                  (
                                                         SELECT 1
                                                         FROM   siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
                                                         WHERE  rstato.elem_id=gest.elem_id
                                                         AND    rstato.elem_stato_id!=bilelemstatoanid
                                                         AND    rstato.data_cancellazione IS NULL
                                                         AND    rstato.validita_fine IS NULL ))
                           ORDER BY gestcorr.elem_code:: INTEGER,
                                    gestcorr.elem_code2::INTEGER,
                                    gestcorr.elem_code3 );

      codresult:=NULL;
      INSERT INTO fase_bil_t_elaborazione_log
                  (
                              fase_bil_elab_id,
                              fase_bil_elab_log_operazione,
                              validita_inizio,
                              login_operazione,
                              ente_proprietario_id
                  )
                  VALUES
                  (
                              fasebilelabid,
                              strmessaggio,
                              clock_timestamp(),
                              loginoperazione,
                              enteproprietarioid
                  )
      returning   fase_bil_elab_log_id
      INTO        codresult;

      IF codresult IS NULL THEN
        RAISE
      EXCEPTION
        ' Errore in inserimento LOG.';
      END IF;
    END IF;
    codresult:=NULL;
    strmessaggio:='Popolamento fase_bil_t_gest_apertura_provv.Verifica esistenza capitoli di gestione da creare/aggiornare da gestione eq precedente.';
    SELECT   1
    INTO     codresult
    FROM     fase_bil_t_gest_apertura_provv fase
    WHERE    fase.ente_proprietario_id=enteproprietarioid
    AND      fase.bil_id=bilancioid
    AND      fase.fase_bil_elab_id=fasebilelabid
    AND      fase.data_cancellazione IS NULL
    AND      fase.validita_fine IS NULL
    ORDER BY fase.fase_bil_gest_ape_prov_id limit 1;

    IF codresult IS NOT NULL THEN
      -- inserimento nuove strutture
      -- capitoli gestione non esistenti da gestione eq anno precedente
      strmessaggio:='Inserimento nuove strutture per tipo='
      ||bilelemgesttipo
      ||'.';
      codresult:=NULL;
      INSERT INTO fase_bil_t_elaborazione_log
                  (
                              fase_bil_elab_id,
                              fase_bil_elab_log_operazione,
                              validita_inizio,
                              login_operazione,
                              ente_proprietario_id
                  )
                  VALUES
                  (
                              fasebilelabid,
                              strmessaggio,
                              clock_timestamp(),
                              loginoperazione,
                              enteproprietarioid
                  )
      returning   fase_bil_elab_log_id
      INTO        codresult;

      IF codresult IS NULL THEN
        RAISE
      EXCEPTION
        ' Errore in inserimento LOG.';
      END IF;
      FOR elembil IN
      (
               SELECT   elem_id,
                        elem_code,
                        elem_code2,
                        elem_code3
               FROM     fase_bil_t_gest_apertura_provv
               WHERE    ente_proprietario_id=enteproprietarioid
               AND      bil_id=bilancioid
               AND      elem_id IS NOT NULL
               AND      elem_prov_id IS NULL     -- non esistente in gestione corrente
               AND      elem_prov_new_id IS NULL -- non ancora elaborato con nuovo inserimento in gestione corrente
               AND      fase_bil_elab_id=fasebilelabid
               AND      data_cancellazione IS NULL
               AND      validita_fine IS NULL
               ORDER BY elem_code:: INTEGER,
                        elem_code2::INTEGER,
                        elem_code3
      )
      LOOP
        bilelemidret:=NULL;
        strmessaggio:='Inserimento nuove strutture per tipo='
        ||bilelemgesttipo
        || '.Elemento di bilancio '
        ||elembil.elem_code
        ||' '
        ||elembil.elem_code2
        ||' '
        ||elembil.elem_code3
        ||' : siac_t_bil_elem.' ;
        -- siac_t_bil_elem
        INSERT INTO siac_t_bil_elem
                    (
                                elem_code,
                                elem_code2,
                                elem_code3,
                                elem_desc,
                                elem_desc2,
                                elem_tipo_id,
                                bil_id,
                                ordine,
                                livello,
                                validita_inizio ,
                                ente_proprietario_id,
                                login_operazione
                    )
                    (
                           SELECT gest.elem_code,
                                  gest.elem_code2,
                                  gest.elem_code3,
                                  gest.elem_desc,
                                  gest.elem_desc2,
                                  gest.elem_tipo_id,
                                  bilancioid,
                                  gest.ordine,
                                  gest.livello,
                                  datainizioval,
                                  gest.ente_proprietario_id,
                                  loginoperazione
                           FROM   siac_t_bil_elem gest
                           WHERE  gest.elem_id=elembil.elem_id)
        returning   elem_id
        INTO        bilelemidret;

        IF bilelemidret IS NULL THEN
          RAISE
        EXCEPTION
          ' Inserimento non effettuato.';
        END IF;
        codresult:=NULL;
        strmessaggio:='Inserimento nuove strutture per tipo='
        ||bilelemgesttipo
        || '.Elemento di bilancio '
        ||elembil.elem_code
        ||' '
        ||elembil.elem_code2
        ||' '
        ||elembil.elem_code3
        ||' : siac_r_bil_elem_stato.' ;
        -- siac_r_bil_elem_stato
        strmessaggio:='Inserimento siac_r_bil_elem_stato.';
        INSERT INTO siac_r_bil_elem_stato
                    (
                                elem_id,
                                elem_stato_id,
                                validita_inizio,
                                ente_proprietario_id,
                                login_operazione
                    )
                    (
                           SELECT bilelemidret,
                                  stato.elem_stato_id,
                                  datainizioval,
                                  stato.ente_proprietario_id,
                                  loginoperazione
                           FROM   siac_r_bil_elem_stato stato
                           WHERE  stato.elem_id=elembil.elem_id
                           AND    stato.data_cancellazione IS NULL
                           AND    date_trunc('day',dataelaborazione)>=date_trunc('day',stato.validita_inizio)
                           AND    (
                                         date_trunc('day',dataelaborazione)<=date_trunc('day',stato.validita_fine)
                                  OR     stato.validita_fine IS NULL) )
        returning   bil_elem_stato_id
        INTO        codresult;

        IF codresult IS NULL THEN
          RAISE
        EXCEPTION
          ' Inserimento non effettuato.';
        END IF;
        codresult:=NULL;
        -- siac_r_bil_elem_categoria
        strmessaggio:='Inserimento nuove strutture per tipo='
        ||bilelemgesttipo
        || '.Elemento di bilancio '
        ||elembil.elem_code
        ||' '
        ||elembil.elem_code2
        ||' '
        ||elembil.elem_code3
        ||' : siac_r_bil_elem_categoria.' ;
        INSERT INTO siac_r_bil_elem_categoria
                    (
                                elem_id,
                                elem_cat_id,
                                validita_inizio,
                                ente_proprietario_id,
                                login_operazione
                    )
                    (
                           SELECT bilelemidret,
                                  cat.elem_cat_id,
                                  datainizioval,
                                  cat.ente_proprietario_id,
                                  loginoperazione
                           FROM   siac_r_bil_elem_categoria cat
                           WHERE  cat.elem_id=elembil.elem_id
                           AND    cat.data_cancellazione IS NULL
                           AND    date_trunc('day',dataelaborazione)>=date_trunc('day',cat.validita_inizio)
                           AND    (
                                         date_trunc('day',dataelaborazione)<=date_trunc('day',cat.validita_fine)
                                  OR     cat.validita_fine IS NULL) )
        returning   bil_elem_r_cat_id
        INTO        codresult;

        IF codresult IS NULL THEN
          RAISE
        EXCEPTION
          ' Inserimento non effettuato.';
        END IF;
        -- salvataggio della categoria per successivi controlli su classificatori obbligatori
        SELECT d.elem_cat_code
        INTO   categoriacapcode
        FROM   siac_r_bil_elem_categoria r,
               siac_d_bil_elem_categoria d
        WHERE  d.elem_cat_id=r.elem_cat_id
        AND    r.bil_elem_r_cat_id=codresult;

        codresult:=NULL;
        -- siac_r_bil_elem_attr
        strmessaggio:='Inserimento nuove strutture per tipo='
        ||bilelemgesttipo
        || '.Elemento di bilancio '
        ||elembil.elem_code
        ||' '
        ||elembil.elem_code2
        ||' '
        ||elembil.elem_code3
        ||' : siac_r_bil_elem_attr.' ;
        INSERT INTO siac_r_bil_elem_attr
                    (
                                elem_id,
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
                           SELECT bilelemidret,
                                  attr.attr_id,
                                  attr.tabella_id,
                                  attr.BOOLEAN,
                                  attr.percentuale,
                                  attr.testo,
                                  attr.numerico,
                                  datainizioval,
                                  attr.ente_proprietario_id,
                                  loginoperazione
                           FROM   siac_r_bil_elem_attr attr
                           WHERE  attr.elem_id=elembil.elem_id
                           AND    attr.data_cancellazione IS NULL
                           AND    date_trunc('day',dataelaborazione)>=date_trunc('day',attr.validita_inizio)
                           AND    (
                                         date_trunc('day',dataelaborazione)<=date_trunc('day',attr.validita_fine)
                                  OR     attr.validita_fine IS NULL) );

        codresult:=NULL;
        SELECT   1
        INTO     codresult
        FROM     siac_r_bil_elem_attr
        WHERE    elem_id=bilelemidret
        AND      data_cancellazione IS NULL
        AND      validita_fine IS NULL
        ORDER BY elem_id limit 1;

        IF codresult IS NULL THEN
          RAISE
        EXCEPTION
          ' Nessun attributo inserito.';
        END IF;
        /* SIAC-5590
codResult:=null;
-- siac_r_vincolo_bil_elem
strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
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
strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
'.Elemento di bilancio '||elemBil.elem_code||' '
||elemBil.elem_code2||' '
||elemBil.elem_code3||' : siac_r_vincolo_bil_elem.Verifica inserimento.' ;
select  1  into codResult
from  siac_r_vincolo_bil_elem v
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
*/
        codresult:=NULL;
        -- siac_r_bil_elem_atto_legge
        strmessaggio:='Inserimento nuove strutture per tipo='
        ||bilelemgesttipo
        || '.Elemento di bilancio '
        ||elembil.elem_code
        ||' '
        ||elembil.elem_code2
        ||' '
        ||elembil.elem_code3
        ||' : siac_r_bil_elem_atto_legge.' ;
        INSERT INTO siac_r_bil_elem_atto_legge
                    (
                                elem_id,
                                attolegge_id,
                                descrizione,
                                gerarchia,
                                finanziamento_inizio,
                                finanziamento_fine,
                                validita_inizio,
                                ente_proprietario_id,
                                login_operazione
                    )
                    (
                           SELECT bilelemidret,
                                  v.attolegge_id,
                                  v.descrizione,
                                  v.gerarchia,
                                  v.finanziamento_inizio,
                                  v.finanziamento_fine,
                                  datainizioval,
                                  v.ente_proprietario_id,
                                  loginoperazione
                           FROM   siac_r_bil_elem_atto_legge v
                           WHERE  v.elem_id=elembil.elem_id
                           AND    v.data_cancellazione IS NULL
                           AND    date_trunc('day',dataelaborazione)>=date_trunc('day',v.validita_inizio)
                           AND    (
                                         date_trunc('day',dataelaborazione)<=date_trunc('day',v.validita_fine)
                                  OR     v.validita_fine IS NULL) );

        codresult:=NULL;
        strmessaggio:='Inserimento nuove strutture per tipo='
        ||bilelemgesttipo
        || '.Elemento di bilancio '
        ||elembil.elem_code
        ||' '
        ||elembil.elem_code2
        ||' '
        ||elembil.elem_code3
        ||' : siac_r_bil_elem_atto_legge.Verifica inserimento.' ;
        SELECT   1
        INTO     codresult
        FROM     siac_r_bil_elem_atto_legge v
        WHERE    v.elem_id=elembil.elem_id
        AND      v.data_cancellazione IS NULL
        AND      date_trunc('day',dataelaborazione)>=date_trunc('day',v.validita_inizio)
        AND      (
                          date_trunc('day',dataelaborazione)<=date_trunc('day',v.validita_fine)
                 OR       v.validita_fine IS NULL)
        AND      NOT EXISTS
                 (
                          SELECT   1
                          FROM     siac_r_bil_elem_atto_legge v1
                          WHERE    v1.elem_id= bilelemidret
                          AND      v1.data_cancellazione IS NULL
                          AND      date_trunc('day',dataelaborazione)>=date_trunc('day',v1.validita_inizio)
                          AND      (
                                            date_trunc('day',dataelaborazione)<=date_trunc('day',v1.validita_fine)
                                   OR       v1.validita_fine IS NULL)
                          ORDER BY v1.elem_id limit 1 )
        ORDER BY v.elem_id limit 1;

        IF codresult IS NOT NULL THEN
          RAISE
        EXCEPTION
          ' Non effettuato.';
        END IF;
        strmessaggio:='Inserimento nuove strutture per tipo='
        ||bilelemgesttipo
        || '.Elemento di bilancio '
        ||elembil.elem_code
        ||' '
        ||elembil.elem_code2
        ||' '
        ||elembil.elem_code3
        ||' : siac_r_bil_elem_rel_tempo.' ;
        INSERT INTO siac_r_bil_elem_rel_tempo
                    (
                                elem_id,
                                elem_id_old,
                                validita_inizio,
                                ente_proprietario_id,
                                login_operazione
                    )
                    (
                           SELECT bilelemidret,
                                  v.elem_id_old,
                                  datainizioval,
                                  v.ente_proprietario_id,
                                  loginoperazione
                           FROM   siac_r_bil_elem_rel_tempo v
                           WHERE  v.elem_id=elembil.elem_id
                           AND    v.data_cancellazione IS NULL
                           AND    date_trunc('day',dataelaborazione)>=date_trunc('day',v.validita_inizio)
                           AND    (
                                         date_trunc('day',dataelaborazione)<=date_trunc('day',v.validita_fine)
                                  OR     v.validita_fine IS NULL));

        codresult:=NULL;
        strmessaggio:='Inserimento nuove strutture per tipo='
        ||bilelemgesttipo
        || '.Elemento di bilancio '
        ||elembil.elem_code
        ||' '
        ||elembil.elem_code2
        ||' '
        ||elembil.elem_code3
        ||' : siac_r_bil_elem_rel_tempo.Verifica inserimento.' ;
        SELECT   1
        INTO     codresult
        FROM     siac_r_bil_elem_rel_tempo v
        WHERE    v.elem_id=elembil.elem_id
        AND      v.data_cancellazione IS NULL
        AND      date_trunc('day',dataelaborazione)>=date_trunc('day',v.validita_inizio)
        AND      (
                          date_trunc('day',dataelaborazione)<=date_trunc('day',v.validita_fine)
                 OR       v.validita_fine IS NULL)
        AND      NOT EXISTS
                 (
                          SELECT   1
                          FROM     siac_r_bil_elem_rel_tempo v1
                          WHERE    v1.elem_id= bilelemidret
                          AND      v1.data_cancellazione IS NULL
                          AND      date_trunc('day',dataelaborazione)>=date_trunc('day',v1.validita_inizio)
                          AND      (
                                            date_trunc('day',dataelaborazione)<=date_trunc('day',v1.validita_fine)
                                   OR       v1.validita_fine IS NULL)
                          ORDER BY v1.elem_id limit 1 )
        ORDER BY v.elem_id limit 1;

        IF codresult IS NOT NULL THEN
          RAISE
        EXCEPTION
          ' Non effettuato.';
        END IF;
        codresult:=NULL;
        -- siac_r_bil_elem_class
        strmessaggio:='Inserimento nuove strutture per tipo='
        ||bilelemgesttipo
        || '.Elemento di bilancio '
        ||elembil.elem_code
        ||' '
        ||elembil.elem_code2
        ||' '
        ||elembil.elem_code3
        ||' : siac_r_bil_elem_class.' ;
        /*
insert into siac_r_bil_elem_class
(elem_id,classif_id, validita_inizio, ente_proprietario_id,login_operazione)
(select bilElemIdRet, class.classif_id,dataInizioVal,class.ente_proprietario_id,loginOperazione
from siac_r_bil_elem_class class
where class.elem_id=elemBil.elem_id
and   class.data_cancellazione is null
and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',class.validita_fine) or class.validita_fine is null));
*/
        /*
select 1 into codResult
from siac_r_bil_elem_class
where elem_id=bilElemIdRet
and   data_cancellazione is null
and   validita_fine is null
order by elem_id
limit 1;
if codResult is null then raise exception ' Nessun classificatore inserito.'; end if;
*/
        /** JIRA-SIAC-4167 - aggiunto controllo su validita classificatore **/
        INSERT INTO siac_r_bil_elem_class
                    (
                                elem_id,
                                classif_id,
                                validita_inizio,
                                ente_proprietario_id,
                                login_operazione
                    )
                    (
                           SELECT bilelemidret,
                                  class.classif_id,
                                  datainizioval,
                                  class.ente_proprietario_id,
                                  loginoperazione
                           FROM   siac_r_bil_elem_class class,
                                  siac_t_class c
                           WHERE  class.elem_id=elembil.elem_id
                           AND    c.classif_id=class.classif_id
                           AND    class.data_cancellazione IS NULL
                           AND    date_trunc('day',dataelaborazione)>=date_trunc('day',class.validita_inizio)
                           AND    (
                                         date_trunc('day',dataelaborazione)<=date_trunc('day',class.validita_fine)
                                  OR     class.validita_fine IS NULL)
                           AND    c.data_cancellazione IS NULL
                           AND    date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                           AND    (
                                         date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                  OR     c.validita_fine IS NULL));
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
        codresult:=NULL;
        strmessaggio:='Inserimento nuove strutture per tipo='
        ||bilelemgesttipo
        || '.Elemento di bilancio '
        ||elembil.elem_code
        ||' '
        ||elembil.elem_code2
        ||' '
        ||elembil.elem_code3
        ||' : verifica classificatore '
        ||cl_cdc
        ||' '
        ||cl_cdr
        ||'.' ;
        /** JIRA-SIAC-4167  **/
        SELECT   1
        INTO     codresult
        FROM     siac_r_bil_elem_class r,
                 siac_t_class c
        WHERE    r.elem_id=bilelemidret
        AND      c.classif_id=r.classif_id
        AND      c.classif_tipo_id IN (cdctipoid,
                                       cdrtipoid)
        AND      c.data_cancellazione IS NULL
        AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
        AND      (
                          date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                 OR       c.validita_fine IS NULL)
        ORDER BY r.elem_id limit 1;

        IF codresult IS NULL THEN
          --provo a collegare il capitolo con il classificatore equivalente nuovo
          --siac-5297
          -- Sofia 21.11.2017
          INSERT INTO siac_r_bil_elem_class
                      (
                                  elem_id,
                                  classif_id,
                                  validita_inizio,
                                  ente_proprietario_id,
                                  login_operazione
                      )
                      (
                             SELECT bilelemidret,
                                    c.classif_id,
                                    datainizioval,
                                    c.ente_proprietario_id,
                                    loginoperazione
                             FROM   siac_t_class c ,
                                    siac_r_bil_elem_class rprec,
                                    siac_t_class cprec
                             WHERE  rprec.elem_id=elembil.elem_id
                             AND    cprec.classif_id=rprec.classif_id
                             AND    cprec.classif_tipo_id IN (cdctipoid,
                                                              cdrtipoid)
                             AND    rprec.data_cancellazione IS NULL
                             AND    date_trunc('day',dataelaborazione)>=date_trunc('day',rprec.validita_inizio)
                             AND    (
                                           date_trunc('day',dataelaborazione)<=date_trunc('day',rprec.validita_fine)
                                    OR     rprec.validita_fine IS NULL) -- relazione ad oggi valida
                             AND    cprec.data_cancellazione IS NULL
                             AND    date_trunc('day',v_dataprimogiornoanno)>date_trunc('day',cprec.validita_fine) -- su classif chiuso in data in anno prec
                             AND    c.ente_proprietario_id=cprec.ente_proprietario_id
                             AND    c.classif_tipo_id=cprec.classif_tipo_id
                             AND    c.classif_code=cprec.classif_code
                             AND    c.data_cancellazione IS NULL -- cercando un classificatore equivalente aperto su anno succ
                             AND    date_trunc('day',v_dataprimogiornoanno)<=date_trunc('day',c.validita_inizio)
                             AND    (
                                           date_trunc('day',v_dataprimogiornoanno) < date_trunc('day',c.validita_fine)
                                    OR     c.validita_fine IS NULL) );

          GET diagnostics _row_count = row_count;
          IF _row_count <1 THEN
            strmessaggio:=strmessaggio
            ||' Inserimento segnalazione mancanza classif.';
            INSERT INTO fase_bil_t_prev_apertura_segnala
                        (
                                    elem_id,
                                    elem_code,
                                    elem_code2,
                                    elem_code3,
                                    bil_id,
                                    fase_bil_elab_id,
                                    segnala_codice,
                                    segnala_desc,
                                    validita_inizio,
                                    ente_proprietario_id,
                                    login_operazione
                        )
                        (
                               SELECT capitolo.elem_id,
                                      capitolo.elem_code,
                                      capitolo.elem_code2,
                                      capitolo.elem_code3,
                                      capitolo.bil_id,
                                      fasebilelabid,
                                      'SAC',
                                      'Sac mancante',
                                      datainizioval,
                                      capitolo.ente_proprietario_id,
                                      loginoperazione
                               FROM   siac_t_bil_elem capitolo
                               WHERE  capitolo.elem_id=bilelemidret )
            returning   fase_bil_prev_ape_seg_id
            INTO        codresult;

            IF codresult IS NULL THEN
              RAISE
            EXCEPTION
              'Nessuno inserimento effettuato.';
            END IF;
          END IF;
          /*
strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
insert into fase_bil_t_prev_apertura_segnala
(elem_id,
elem_code,
elem_code2,
elem_code3,
bil_id,
fase_bil_elab_id,
segnala_codice,
segnala_desc,
validita_inizio,
ente_proprietario_id,
login_operazione)
(select capitolo.elem_id,
capitolo.elem_code,
capitolo.elem_code2,
capitolo.elem_code3,
capitolo.bil_id,
faseBilElabId,
'SAC',
'Sac mancante',
dataInizioVal,
capitolo.ente_proprietario_id,
loginOperazione
from siac_t_bil_elem capitolo
where  capitolo.elem_id=bilElemIdRet
)
returning fase_bil_prev_ape_seg_id into codresult;
if codResult is null then raise exception 'Nessuno inserimento effettuato.'; end if;
*/
        END IF;
        /** FINE **/
        -- CL_PDC_FIN_QUINTO, CL_PDC_FIN_QUARTO
        codresult:=NULL;
        strmessaggio:='Inserimento nuove strutture per tipo='
        ||bilelemgesttipo
        || '.Elemento di bilancio '
        ||elembil.elem_code
        ||' '
        ||elembil.elem_code2
        ||' '
        ||elembil.elem_code3
        ||' : verifica classificatore '
        ||cl_pdc_fin_quarto
        ||' '
        ||cl_pdc_fin_quinto
        ||'.' ;
        /** JIRA-SIAC-4167 **/
        SELECT   1
        INTO     codresult
        FROM     siac_r_bil_elem_class r,
                 siac_t_class c
        WHERE    r.elem_id=bilelemidret
        AND      c.classif_id=r.classif_id
        AND      c.classif_tipo_id IN (pdcfinivid,
                                       pdcfinvid)
        AND      c.data_cancellazione IS NULL
        AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
        AND      (
                          date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                 OR       c.validita_fine IS NULL)
        ORDER BY r.elem_id limit 1;

        -- Obbligatorieta  del classificatore vale solo per capitolo STANDARD
        IF categoriacapcode = categoria_std THEN
          --  JIRA-SIAC-4167  if codResult is null then raise exception ' Nessuno inserimento effettuato.'; end if;
          IF codresult IS NULL THEN
            /*
strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
insert into fase_bil_t_prev_apertura_segnala
(elem_id,
elem_code,
elem_code2,
elem_code3,
bil_id,
fase_bil_elab_id,
segnala_codice,
segnala_desc,
validita_inizio,
ente_proprietario_id,
login_operazione)
(select capitolo.elem_id,
capitolo.elem_code,
capitolo.elem_code2,
capitolo.elem_code3,
capitolo.bil_id,
faseBilElabId,
'PDCFIN',
'PdcFin mancante',
dataInizioVal,
capitolo.ente_proprietario_id,
loginOperazione
from siac_t_bil_elem capitolo
where  capitolo.elem_id=bilElemIdRet
)
returning fase_bil_prev_ape_seg_id into codresult;
if codResult is null then raise exception 'Nessuno inserimento effettuato.'; end if;
*/
            --provo a collegare il capitolo con il classificatore equivalente nuovo
            --siac-5297
            -- Sofia 21.11.2017
            INSERT INTO siac_r_bil_elem_class
                        (
                                    elem_id,
                                    classif_id,
                                    validita_inizio,
                                    ente_proprietario_id,
                                    login_operazione
                        )
                        (
                               SELECT bilelemidret,
                                      c.classif_id,
                                      datainizioval,
                                      c.ente_proprietario_id,
                                      loginoperazione
                               FROM   siac_t_class c ,
                                      siac_r_bil_elem_class rprec,
                                      siac_t_class cprec
                               WHERE  rprec.elem_id=elembil.elem_id
                               AND    cprec.classif_id=rprec.classif_id
                               AND    cprec.classif_tipo_id IN (pdcfinivid,
                                                                pdcfinvid)
                               AND    rprec.data_cancellazione IS NULL
                               AND    date_trunc('day',dataelaborazione)>=date_trunc('day',rprec.validita_inizio)
                               AND    (
                                             date_trunc('day',dataelaborazione)<=date_trunc('day',rprec.validita_fine)
                                      OR     rprec.validita_fine IS NULL) -- relazione ad oggi valida
                               AND    cprec.data_cancellazione IS NULL
                               AND    date_trunc('day',v_dataprimogiornoanno)>date_trunc('day',cprec.validita_fine) -- su classif chiuso in data in anno prec
                               AND    c.ente_proprietario_id=cprec.ente_proprietario_id
                               AND    c.classif_tipo_id=cprec.classif_tipo_id
                               AND    c.classif_code=cprec.classif_code
                               AND    c.data_cancellazione IS NULL -- cercando un classificatore equivalente aperto su anno succ
                               AND    date_trunc('day',v_dataprimogiornoanno)<=date_trunc('day',c.validita_inizio)
                               AND    (
                                             date_trunc('day',v_dataprimogiornoanno) < date_trunc('day',c.validita_fine)
                                      OR     c.validita_fine IS NULL) );

            GET diagnostics _row_count = row_count;
            IF _row_count <1 THEN
              strmessaggio:=strmessaggio
              ||' Inserimento segnalazione mancanza classif.';
              INSERT INTO fase_bil_t_prev_apertura_segnala
                          (
                                      elem_id,
                                      elem_code,
                                      elem_code2,
                                      elem_code3,
                                      bil_id,
                                      fase_bil_elab_id,
                                      segnala_codice,
                                      segnala_desc,
                                      validita_inizio,
                                      ente_proprietario_id,
                                      login_operazione
                          )
                          (
                                 SELECT capitolo.elem_id,
                                        capitolo.elem_code,
                                        capitolo.elem_code2,
                                        capitolo.elem_code3,
                                        capitolo.bil_id,
                                        fasebilelabid,
                                        'PDCFIN',
                                        'PdcFin mancante',
                                        datainizioval,
                                        capitolo.ente_proprietario_id,
                                        loginoperazione
                                 FROM   siac_t_bil_elem capitolo
                                 WHERE  capitolo.elem_id=bilelemidret )
              returning   fase_bil_prev_ape_seg_id
              INTO        codresult;

              IF codresult IS NULL THEN
                RAISE
              EXCEPTION
                'Nessuno inserimento effettuato.';
              END IF;
            END IF;
          END IF;
        END IF;
        IF euelemtipo=tipo_elem_eu THEN
          -- CL_PROGRAMMA
          codresult:=NULL;
          strmessaggio:='Inserimento nuove strutture per tipo='
          ||bilelemgesttipo
          || '.Elemento di bilancio '
          ||elembil.elem_code
          ||' '
          ||elembil.elem_code2
          ||' '
          ||elembil.elem_code3
          ||' : verifica classificatore '
          ||cl_programma
          ||'.' ;
          /** JIRA-SIAC-4167 **/
          SELECT   1
          INTO     codresult
          FROM     siac_r_bil_elem_class r,
                   siac_t_class c
          WHERE    r.elem_id=bilelemidret
          AND      c.classif_id=r.classif_id
          AND      c.classif_tipo_id=programmatipoid
          AND      c.data_cancellazione IS NULL
          AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
          AND      (
                            date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                   OR       c.validita_fine IS NULL)
          ORDER BY r.elem_id limit 1;

          -- Obbligatorieta  del classificatore vale solo per capitolo STANDARD
          IF categoriacapcode = categoria_std THEN
            -- JIRA-SIAC-4167 if codResult is null then raise exception ' Nessuno inserimento effettuato.'; end if;
            IF codresult IS NULL THEN
              /*
strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
insert into fase_bil_t_prev_apertura_segnala
(elem_id,
elem_code,
elem_code2,
elem_code3,
bil_id,
fase_bil_elab_id,
segnala_codice,
segnala_desc,
validita_inizio,
ente_proprietario_id,
login_operazione)
(select capitolo.elem_id,
capitolo.elem_code,
capitolo.elem_code2,
capitolo.elem_code3,
capitolo.bil_id,
faseBilElabId,
CL_PROGRAMMA,
CL_PROGRAMMA||' mancante',
dataInizioVal,
capitolo.ente_proprietario_id,
loginOperazione
from siac_t_bil_elem capitolo
where  capitolo.elem_id=bilElemIdRet
)
returning fase_bil_prev_ape_seg_id into codresult;
if codResult is null then raise exception 'Nessuno inserimento effettuato.'; end if;
*/
              --provo a collegare il capitolo con il classificatore equivalente nuovo
              --siac-5297
              -- Sofia 21.11.2017
              INSERT INTO siac_r_bil_elem_class
                          (
                                      elem_id,
                                      classif_id,
                                      validita_inizio,
                                      ente_proprietario_id,
                                      login_operazione
                          )
                          (
                                 SELECT bilelemidret,
                                        c.classif_id,
                                        datainizioval,
                                        c.ente_proprietario_id,
                                        loginoperazione
                                 FROM   siac_t_class c ,
                                        siac_r_bil_elem_class rprec,
                                        siac_t_class cprec
                                 WHERE  rprec.elem_id=elembil.elem_id
                                 AND    cprec.classif_id=rprec.classif_id
                                 AND    cprec.classif_tipo_id =programmatipoid
                                 AND    rprec.data_cancellazione IS NULL
                                 AND    date_trunc('day',dataelaborazione)>=date_trunc('day',rprec.validita_inizio)
                                 AND    (
                                               date_trunc('day',dataelaborazione)<=date_trunc('day',rprec.validita_fine)
                                        OR     rprec.validita_fine IS NULL) -- relazione ad oggi valida
                                 AND    cprec.data_cancellazione IS NULL
                                 AND    date_trunc('day',v_dataprimogiornoanno)>date_trunc('day',cprec.validita_fine) -- su classif chiuso in data in anno prec
                                 AND    c.ente_proprietario_id=cprec.ente_proprietario_id
                                 AND    c.classif_tipo_id=cprec.classif_tipo_id
                                 AND    c.classif_code=cprec.classif_code
                                 AND    c.data_cancellazione IS NULL -- cercando un classificatore equivalente aperto su anno succ
                                 AND    date_trunc('day',v_dataprimogiornoanno)<=date_trunc('day',c.validita_inizio)
                                 AND    (
                                               date_trunc('day',v_dataprimogiornoanno) < date_trunc('day',c.validita_fine)
                                        OR     c.validita_fine IS NULL) );

              GET diagnostics _row_count = row_count;
              IF _row_count <1 THEN
                strmessaggio:=strmessaggio
                ||' Inserimento segnalazione mancanza classif.';
                INSERT INTO fase_bil_t_prev_apertura_segnala
                            (
                                        elem_id,
                                        elem_code,
                                        elem_code2,
                                        elem_code3,
                                        bil_id,
                                        fase_bil_elab_id,
                                        segnala_codice,
                                        segnala_desc,
                                        validita_inizio,
                                        ente_proprietario_id,
                                        login_operazione
                            )
                            (
                                   SELECT capitolo.elem_id,
                                          capitolo.elem_code,
                                          capitolo.elem_code2,
                                          capitolo.elem_code3,
                                          capitolo.bil_id,
                                          fasebilelabid,
                                          cl_programma,
                                          cl_programma
                                                 ||' mancante',
                                          datainizioval,
                                          capitolo.ente_proprietario_id,
                                          loginoperazione
                                   FROM   siac_t_bil_elem capitolo
                                   WHERE  capitolo.elem_id=bilelemidret )
                returning   fase_bil_prev_ape_seg_id
                INTO        codresult;

                IF codresult IS NULL THEN
                  RAISE
                EXCEPTION
                  'Nessuno inserimento effettuato.';
                END IF;
              END IF;
            END IF;
          END IF;
          -- CL_MACROAGGREGATO
          codresult:=NULL;
          strmessaggio:='Inserimento nuove strutture per tipo='
          ||bilelemgesttipo
          || '.Elemento di bilancio '
          ||elembil.elem_code
          ||' '
          ||elembil.elem_code2
          ||' '
          ||elembil.elem_code3
          ||' : verifica classificatore '
          ||cl_macroaggregato
          ||'.' ;
          /** JIRA-SIAC-4167 **/
          SELECT   1
          INTO     codresult
          FROM     siac_r_bil_elem_class r,
                   siac_t_class c
          WHERE    r.elem_id=bilelemidret
          AND      c.classif_id=r.classif_id
          AND      c.classif_tipo_id=macroaggrtipoid
          AND      c.data_cancellazione IS NULL
          AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
          AND      (
                            date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                   OR       c.validita_fine IS NULL)
          ORDER BY r.elem_id limit 1;

          -- Obbligatorieta del classificatore vale solo per capitolo STANDARD
          IF categoriacapcode = categoria_std THEN
            -- JIRA-SIAC-4167 if codResult is null then raise exception ' Nessuno inserimento effettuato.'; end if;
            IF codresult IS NULL THEN
              /*
strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
insert into fase_bil_t_prev_apertura_segnala
(elem_id,
elem_code,
elem_code2,
elem_code3,
bil_id,
fase_bil_elab_id,
segnala_codice,
segnala_desc,
validita_inizio,
ente_proprietario_id,
login_operazione)
(select capitolo.elem_id,
capitolo.elem_code,
capitolo.elem_code2,
capitolo.elem_code3,
capitolo.bil_id,
faseBilElabId,
CL_MACROAGGREGATO,
CL_MACROAGGREGATO||' mancante',
dataInizioVal,
capitolo.ente_proprietario_id,
loginOperazione
from siac_t_bil_elem capitolo
where  capitolo.elem_id=bilElemIdRet
)
returning fase_bil_prev_ape_seg_id into codresult;
if codResult is null then raise exception 'Nessuno inserimento effettuato.';  end if;
*/
              --provo a collegare il capitolo con il classificatore equivalente nuovo
              --siac-5297
              -- Sofia 21.11.2017
              INSERT INTO siac_r_bil_elem_class
                          (
                                      elem_id,
                                      classif_id,
                                      validita_inizio,
                                      ente_proprietario_id,
                                      login_operazione
                          )
                          (
                                 SELECT bilelemidret,
                                        c.classif_id,
                                        datainizioval,
                                        c.ente_proprietario_id,
                                        loginoperazione
                                 FROM   siac_t_class c ,
                                        siac_r_bil_elem_class rprec,
                                        siac_t_class cprec
                                 WHERE  rprec.elem_id=elembil.elem_id
                                 AND    cprec.classif_id=rprec.classif_id
                                 AND    cprec.classif_tipo_id =macroaggrtipoid
                                 AND    rprec.data_cancellazione IS NULL
                                 AND    date_trunc('day',dataelaborazione)>=date_trunc('day',rprec.validita_inizio)
                                 AND    (
                                               date_trunc('day',dataelaborazione)<=date_trunc('day',rprec.validita_fine)
                                        OR     rprec.validita_fine IS NULL) -- relazione ad oggi valida
                                 AND    cprec.data_cancellazione IS NULL
                                 AND    date_trunc('day',v_dataprimogiornoanno)>date_trunc('day',cprec.validita_fine) -- su classif chiuso in data in anno prec
                                 AND    c.ente_proprietario_id=cprec.ente_proprietario_id
                                 AND    c.classif_tipo_id=cprec.classif_tipo_id
                                 AND    c.classif_code=cprec.classif_code
                                 AND    c.data_cancellazione IS NULL -- cercando un classificatore equivalente aperto su anno succ
                                 AND    date_trunc('day',v_dataprimogiornoanno)<=date_trunc('day',c.validita_inizio)
                                 AND    (
                                               date_trunc('day',v_dataprimogiornoanno) < date_trunc('day',c.validita_fine)
                                        OR     c.validita_fine IS NULL) );

              GET diagnostics _row_count = row_count;
              IF _row_count <1 THEN
                strmessaggio:=strmessaggio
                ||' Inserimento segnalazione mancanza classif.';
                INSERT INTO fase_bil_t_prev_apertura_segnala
                            (
                                        elem_id,
                                        elem_code,
                                        elem_code2,
                                        elem_code3,
                                        bil_id,
                                        fase_bil_elab_id,
                                        segnala_codice,
                                        segnala_desc,
                                        validita_inizio,
                                        ente_proprietario_id,
                                        login_operazione
                            )
                            (
                                   SELECT capitolo.elem_id,
                                          capitolo.elem_code,
                                          capitolo.elem_code2,
                                          capitolo.elem_code3,
                                          capitolo.bil_id,
                                          fasebilelabid,
                                          cl_macroaggregato,
                                          cl_macroaggregato
                                                 ||' mancante',
                                          datainizioval,
                                          capitolo.ente_proprietario_id,
                                          loginoperazione
                                   FROM   siac_t_bil_elem capitolo
                                   WHERE  capitolo.elem_id=bilelemidret )
                returning   fase_bil_prev_ape_seg_id
                INTO        codresult;

                IF codresult IS NULL THEN
                  RAISE
                EXCEPTION
                  'Nessuno inserimento effettuato.';
                END IF;
              END IF;
            END IF;
          END IF;
          -- CL_COFOG
          codresult:=NULL;
          strmessaggio:='Inserimento nuove strutture per tipo='
          ||bilelemgesttipo
          || '.Elemento di bilancio '
          ||elembil.elem_code
          ||' '
          ||elembil.elem_code2
          ||' '
          ||elembil.elem_code3
          ||' : verifica classificatore '
          ||cl_cofog
          ||'.' ;
          SELECT   1
          INTO     codresult
          FROM     siac_r_bil_elem_class r,
                   siac_t_class c
          WHERE    r.elem_id=elembil.elem_id
          AND      c.classif_id=r.classif_id
          AND      c.classif_tipo_id=cofogtipoid
          AND      r.data_cancellazione IS NULL
          AND      date_trunc('day',dataelaborazione)>=date_trunc('day',r.validita_inizio)
          AND      (
                            date_trunc('day',dataelaborazione)<=date_trunc('day',r.validita_fine)
                   OR       r.validita_fine IS NULL)
          AND      c.data_cancellazione IS NULL
          /*AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
          AND      (
                            date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                   OR       c.validita_fine IS NULL)*/
          AND      NOT EXISTS
                   (
                                   SELECT DISTINCT 1
                                   FROM            siac_r_bil_elem_class r,
                                                   siac_t_class c
                                   WHERE           r.elem_id=bilelemidret
                                   AND             c.classif_id=r.classif_id
                                   AND             c.classif_tipo_id=cofogtipoid
                                   AND             c.data_cancellazione IS NULL
                                   /*AND             date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                   AND             (
                                                                   date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                   OR              c.validita_fine IS NULL) */)
          ORDER BY r.elem_id limit 1;

          -- --JIRA-SIAC-4167 14.11.2016 Sofia
          IF codresult IS NOT NULL THEN
            /*
codResult:=null;
strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
insert into fase_bil_t_prev_apertura_segnala
(elem_id,
elem_code,
elem_code2,
elem_code3,
bil_id,
fase_bil_elab_id,
segnala_codice,
segnala_desc,
validita_inizio,
ente_proprietario_id,
login_operazione)
(select capitolo.elem_id,
capitolo.elem_code,
capitolo.elem_code2,
capitolo.elem_code3,
capitolo.bil_id,
faseBilElabId,
CL_COFOG,
CL_COFOG||' mancante',
dataInizioVal,
capitolo.ente_proprietario_id,
loginOperazione
from siac_t_bil_elem capitolo
where  capitolo.elem_id=bilElemIdRet
)
returning fase_bil_prev_ape_seg_id into codresult;
if codResult is  null then raise exception ' Nessuno inserimento effettuato.'; end if;
*/
            --provo a collegare il capitolo con il classificatore equivalente nuovo
            --siac-5297
            -- Sofia 21.11.2017
            INSERT INTO siac_r_bil_elem_class
                        (
                                    elem_id,
                                    classif_id,
                                    validita_inizio,
                                    ente_proprietario_id,
                                    login_operazione
                        )
                        (
                               SELECT bilelemidret,
                                      c.classif_id,
                                      datainizioval,
                                      c.ente_proprietario_id,
                                      loginoperazione
                               FROM   siac_t_class c ,
                                      siac_r_bil_elem_class rprec,
                                      siac_t_class cprec
                               WHERE  rprec.elem_id=elembil.elem_id
                               AND    cprec.classif_id=rprec.classif_id
                               AND    cprec.classif_tipo_id =cofogtipoid
                               AND    rprec.data_cancellazione IS NULL
                               AND    date_trunc('day',dataelaborazione)>=date_trunc('day',rprec.validita_inizio)
                               AND    (
                                             date_trunc('day',dataelaborazione)<=date_trunc('day',rprec.validita_fine)
                                      OR     rprec.validita_fine IS NULL) -- relazione ad oggi valida
                               AND    cprec.data_cancellazione IS NULL
                               AND    date_trunc('day',v_dataprimogiornoanno)>date_trunc('day',cprec.validita_fine) -- su classif chiuso in data in anno prec
                               AND    c.ente_proprietario_id=cprec.ente_proprietario_id
                               AND    c.classif_tipo_id=cprec.classif_tipo_id
                               AND    c.classif_code=cprec.classif_code
                               AND    c.data_cancellazione IS NULL -- cercando un classificatore equivalente aperto su anno succ
                               AND    date_trunc('day',v_dataprimogiornoanno)<=date_trunc('day',c.validita_inizio)
                               AND    (
                                             date_trunc('day',v_dataprimogiornoanno) < date_trunc('day',c.validita_fine)
                                      OR     c.validita_fine IS NULL) );

            GET diagnostics _row_count = row_count;
            IF _row_count <1 THEN
              codresult:=NULL;
              strmessaggio:=strmessaggio
              ||' Inserimento segnalazione mancanza classif.';
              INSERT INTO fase_bil_t_prev_apertura_segnala
                          (
                                      elem_id,
                                      elem_code,
                                      elem_code2,
                                      elem_code3,
                                      bil_id,
                                      fase_bil_elab_id,
                                      segnala_codice,
                                      segnala_desc,
                                      validita_inizio,
                                      ente_proprietario_id,
                                      login_operazione
                          )
                          (
                                 SELECT capitolo.elem_id,
                                        capitolo.elem_code,
                                        capitolo.elem_code2,
                                        capitolo.elem_code3,
                                        capitolo.bil_id,
                                        fasebilelabid,
                                        cl_cofog,
                                        cl_cofog
                                               ||' mancante',
                                        datainizioval,
                                        capitolo.ente_proprietario_id,
                                        loginoperazione
                                 FROM   siac_t_bil_elem capitolo
                                 WHERE  capitolo.elem_id=bilelemidret )
              returning   fase_bil_prev_ape_seg_id
              INTO        codresult;

              IF codresult IS NULL THEN
                RAISE
              EXCEPTION
                ' Nessuno inserimento effettuato.';
              END IF;
            END IF;
          END IF;
          -- CL_RICORRENTE_SPESA
          codresult:=NULL;
          strmessaggio:='Inserimento nuove strutture per tipo='
          ||bilelemgesttipo
          || '.Elemento di bilancio '
          ||elembil.elem_code
          ||' '
          ||elembil.elem_code2
          ||' '
          ||elembil.elem_code3
          ||' : verifica classificatore '
          ||cl_ricorrente_spesa
          ||'.' ;
          SELECT   1
          INTO     codresult
          FROM     siac_r_bil_elem_class r,
                   siac_t_class c
          WHERE    r.elem_id=elembil.elem_id
          AND      c.classif_id=r.classif_id
          AND      c.classif_tipo_id=ricorrentespesaid
          AND      r.data_cancellazione IS NULL
          AND      date_trunc('day',dataelaborazione)>=date_trunc('day',r.validita_inizio)
          AND      (
                            date_trunc('day',dataelaborazione)<=date_trunc('day',r.validita_fine)
                   OR       r.validita_fine IS NULL)
          AND      c.data_cancellazione IS NULL
          /*AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
          AND      (
                            date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                   OR       c.validita_fine IS NULL)*/
          AND      NOT EXISTS
                   (
                                   SELECT DISTINCT 1
                                   FROM            siac_r_bil_elem_class r,
                                                   siac_t_class c
                                   WHERE           r.elem_id=bilelemidret
                                   AND             c.classif_id=r.classif_id
                                   AND             c.classif_tipo_id=ricorrentespesaid
                                   AND             c.data_cancellazione IS NULL
                                   /*AND             date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                   AND             (
                                                                   date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                   OR              c.validita_fine IS NULL)*/ )
          ORDER BY r.elem_id limit 1;

          -- JIRA-SIAC-4167 14.11.2016 Sofia
          IF codresult IS NOT NULL THEN
            /*
codResult:=null;
strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
insert into fase_bil_t_prev_apertura_segnala
(elem_id,
elem_code,
elem_code2,
elem_code3,
bil_id,
fase_bil_elab_id,
segnala_codice,
segnala_desc,
validita_inizio,
ente_proprietario_id,
login_operazione)
(select capitolo.elem_id,
capitolo.elem_code,
capitolo.elem_code2,
capitolo.elem_code3,
capitolo.bil_id,
faseBilElabId,
CL_RICORRENTE_SPESA,
CL_RICORRENTE_SPESA||' mancante',
dataInizioVal,
capitolo.ente_proprietario_id,
loginOperazione
from siac_t_bil_elem capitolo
where  capitolo.elem_id=bilElemIdRet
)
returning fase_bil_prev_ape_seg_id into codresult;
if codResult is  null then raise exception ' Nessuno inserimento effettuato.'; end if;
*/
            --provo a collegare il capitolo con il classificatore equivalente nuovo
            --siac-5297
            -- Sofia 21.11.2017
            INSERT INTO siac_r_bil_elem_class
                        (
                                    elem_id,
                                    classif_id,
                                    validita_inizio,
                                    ente_proprietario_id,
                                    login_operazione
                        )
                        (
                               SELECT bilelemidret,
                                      c.classif_id,
                                      datainizioval,
                                      c.ente_proprietario_id,
                                      loginoperazione
                               FROM   siac_t_class c ,
                                      siac_r_bil_elem_class rprec,
                                      siac_t_class cprec
                               WHERE  rprec.elem_id=elembil.elem_id
                               AND    cprec.classif_id=rprec.classif_id
                               AND    cprec.classif_tipo_id =ricorrentespesaid
                               AND    rprec.data_cancellazione IS NULL
                               AND    date_trunc('day',dataelaborazione)>=date_trunc('day',rprec.validita_inizio)
                               AND    (
                                             date_trunc('day',dataelaborazione)<=date_trunc('day',rprec.validita_fine)
                                      OR     rprec.validita_fine IS NULL) -- relazione ad oggi valida
                               AND    cprec.data_cancellazione IS NULL
                               AND    date_trunc('day',v_dataprimogiornoanno)>date_trunc('day',cprec.validita_fine) -- su classif chiuso in data in anno prec
                               AND    c.ente_proprietario_id=cprec.ente_proprietario_id
                               AND    c.classif_tipo_id=cprec.classif_tipo_id
                               AND    c.classif_code=cprec.classif_code
                               AND    c.data_cancellazione IS NULL -- cercando un classificatore equivalente aperto su anno succ
                               AND    date_trunc('day',v_dataprimogiornoanno)<=date_trunc('day',c.validita_inizio)
                               AND    (
                                             date_trunc('day',v_dataprimogiornoanno) < date_trunc('day',c.validita_fine)
                                      OR     c.validita_fine IS NULL) );

            GET diagnostics _row_count = row_count;
            IF _row_count <1 THEN
              codresult:=NULL;
              strmessaggio:=strmessaggio
              ||' Inserimento segnalazione mancanza classif.';
              INSERT INTO fase_bil_t_prev_apertura_segnala
                          (
                                      elem_id,
                                      elem_code,
                                      elem_code2,
                                      elem_code3,
                                      bil_id,
                                      fase_bil_elab_id,
                                      segnala_codice,
                                      segnala_desc,
                                      validita_inizio,
                                      ente_proprietario_id,
                                      login_operazione
                          )
                          (
                                 SELECT capitolo.elem_id,
                                        capitolo.elem_code,
                                        capitolo.elem_code2,
                                        capitolo.elem_code3,
                                        capitolo.bil_id,
                                        fasebilelabid,
                                        cl_ricorrente_spesa,
                                        cl_ricorrente_spesa
                                               ||' mancante',
                                        datainizioval,
                                        capitolo.ente_proprietario_id,
                                        loginoperazione
                                 FROM   siac_t_bil_elem capitolo
                                 WHERE  capitolo.elem_id=bilelemidret )
              returning   fase_bil_prev_ape_seg_id
              INTO        codresult;

              IF codresult IS NULL THEN
                RAISE
              EXCEPTION
                ' Nessuno inserimento effettuato.';
              END IF;
            END IF;
          END IF;
          -- CL_SIOPE_SPESA_TERZO
          codresult:=NULL;
          strmessaggio:='Inserimento nuove strutture per tipo='
          ||bilelemgesttipo
          || '.Elemento di bilancio '
          ||elembil.elem_code
          ||' '
          ||elembil.elem_code2
          ||' '
          ||elembil.elem_code3
          ||' : verifica classificatore '
          ||cl_siope_spesa_terzo
          ||'.' ;
          SELECT   1
          INTO     codresult
          FROM     siac_r_bil_elem_class r,
                   siac_t_class c
          WHERE    r.elem_id=elembil.elem_id
          AND      c.classif_id=r.classif_id
          AND      c.classif_tipo_id=siopespesatipoid
          AND      r.data_cancellazione IS NULL
          AND      date_trunc('day',dataelaborazione)>=date_trunc('day',r.validita_inizio)
          AND      (
                            date_trunc('day',dataelaborazione)<=date_trunc('day',r.validita_fine)
                   OR       r.validita_fine IS NULL)
          AND      c.data_cancellazione IS NULL
          /*AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
          AND      (
                            date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                   OR       c.validita_fine IS NULL)*/
          AND      NOT EXISTS
                   (
                                   SELECT DISTINCT 1
                                   FROM            siac_r_bil_elem_class r,
                                                   siac_t_class c
                                   WHERE           r.elem_id=bilelemidret
                                   AND             c.classif_id=r.classif_id
                                   AND             c.classif_tipo_id=siopespesatipoid
                                   AND             c.data_cancellazione IS NULL
                                   /*AND             date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                   AND             (
                                                                   date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                   OR              c.validita_fine IS NULL) */)
          ORDER BY r.elem_id limit 1;

          -- JIRA-SIAC-4167 14.11.2016 Sofia
          IF codresult IS NOT NULL THEN
            /*
codResult:=null;
strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
insert into fase_bil_t_prev_apertura_segnala
(elem_id,
elem_code,
elem_code2,
elem_code3,
bil_id,
fase_bil_elab_id,
segnala_codice,
segnala_desc,
validita_inizio,
ente_proprietario_id,
login_operazione)
(select capitolo.elem_id,
capitolo.elem_code,
capitolo.elem_code2,
capitolo.elem_code3,
capitolo.bil_id,
faseBilElabId,
CL_SIOPE_SPESA_TERZO,
CL_SIOPE_SPESA_TERZO||' mancante',
dataInizioVal,
capitolo.ente_proprietario_id,
loginOperazione
from siac_t_bil_elem capitolo
where  capitolo.elem_id=bilElemIdRet
)
returning fase_bil_prev_ape_seg_id into codresult;
if codResult is  null then raise exception ' Nessuno inserimento effettuato.'; end if;
*/
            --provo a collegare il capitolo con il classificatore equivalente nuovo
            --siac-5297
            -- Sofia 21.11.2017
            INSERT INTO siac_r_bil_elem_class
                        (
                                    elem_id,
                                    classif_id,
                                    validita_inizio,
                                    ente_proprietario_id,
                                    login_operazione
                        )
                        (
                               SELECT bilelemidret,
                                      c.classif_id,
                                      datainizioval,
                                      c.ente_proprietario_id,
                                      loginoperazione
                               FROM   siac_t_class c ,
                                      siac_r_bil_elem_class rprec,
                                      siac_t_class cprec
                               WHERE  rprec.elem_id=elembil.elem_id
                               AND    cprec.classif_id=rprec.classif_id
                               AND    cprec.classif_tipo_id =siopespesatipoid
                               AND    rprec.data_cancellazione IS NULL
                               AND    date_trunc('day',dataelaborazione)>=date_trunc('day',rprec.validita_inizio)
                               AND    (
                                             date_trunc('day',dataelaborazione)<=date_trunc('day',rprec.validita_fine)
                                      OR     rprec.validita_fine IS NULL) -- relazione ad oggi valida
                               AND    cprec.data_cancellazione IS NULL
                               AND    date_trunc('day',v_dataprimogiornoanno)>date_trunc('day',cprec.validita_fine) -- su classif chiuso in data in anno prec
                               AND    c.ente_proprietario_id=cprec.ente_proprietario_id
                               AND    c.classif_tipo_id=cprec.classif_tipo_id
                               AND    c.classif_code=cprec.classif_code
                               AND    c.data_cancellazione IS NULL -- cercando un classificatore equivalente aperto su anno succ
                               AND    date_trunc('day',v_dataprimogiornoanno)<=date_trunc('day',c.validita_inizio)
                               AND    (
                                             date_trunc('day',v_dataprimogiornoanno) < date_trunc('day',c.validita_fine)
                                      OR     c.validita_fine IS NULL) );

            GET diagnostics _row_count = row_count;
            IF _row_count <1 THEN
              codresult:=NULL;
              strmessaggio:=strmessaggio
              ||' Inserimento segnalazione mancanza classif.';
              INSERT INTO fase_bil_t_prev_apertura_segnala
                          (
                                      elem_id,
                                      elem_code,
                                      elem_code2,
                                      elem_code3,
                                      bil_id,
                                      fase_bil_elab_id,
                                      segnala_codice,
                                      segnala_desc,
                                      validita_inizio,
                                      ente_proprietario_id,
                                      login_operazione
                          )
                          (
                                 SELECT capitolo.elem_id,
                                        capitolo.elem_code,
                                        capitolo.elem_code2,
                                        capitolo.elem_code3,
                                        capitolo.bil_id,
                                        fasebilelabid,
                                        cl_siope_spesa_terzo,
                                        cl_siope_spesa_terzo
                                               ||' mancante',
                                        datainizioval,
                                        capitolo.ente_proprietario_id,
                                        loginoperazione
                                 FROM   siac_t_bil_elem capitolo
                                 WHERE  capitolo.elem_id=bilelemidret )
              returning   fase_bil_prev_ape_seg_id
              INTO        codresult;

              IF codresult IS NULL THEN
                RAISE
              EXCEPTION
                ' Nessuno inserimento effettuato.';
              END IF;
            END IF;
          END IF;
          -- CL_TRANSAZIONE_UE_SPESA
          codresult:=NULL;
          strmessaggio:='Inserimento nuove strutture per tipo='
          ||bilelemgesttipo
          || '.Elemento di bilancio '
          ||elembil.elem_code
          ||' '
          ||elembil.elem_code2
          ||' '
          ||elembil.elem_code3
          ||' : verifica classificatore '
          ||cl_transazione_ue_spesa
          ||'.' ;
          SELECT   1
          INTO     codresult
          FROM     siac_r_bil_elem_class r,
                   siac_t_class c
          WHERE    r.elem_id=elembil.elem_id
          AND      c.classif_id=r.classif_id
          AND      c.classif_tipo_id=transazioneuespesaid
          AND      r.data_cancellazione IS NULL
          AND      date_trunc('day',dataelaborazione)>=date_trunc('day',r.validita_inizio)
          AND      (
                            date_trunc('day',dataelaborazione)<=date_trunc('day',r.validita_fine)
                   OR       r.validita_fine IS NULL)
          AND      c.data_cancellazione IS NULL
          /*AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
          AND      (
                            date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                   OR       c.validita_fine IS NULL)*/
          AND      NOT EXISTS
                   (
                                   SELECT DISTINCT 1
                                   FROM            siac_r_bil_elem_class r,
                                                   siac_t_class c
                                   WHERE           r.elem_id=bilelemidret
                                   AND             c.classif_id=r.classif_id
                                   AND             c.classif_tipo_id=transazioneuespesaid
                                   AND             c.data_cancellazione IS NULL
                                   /*AND             date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                   AND             (
                                                                   date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                   OR              c.validita_fine IS NULL)*/ )
          ORDER BY r.elem_id limit 1;

          -- JIRA-SIAC-4167 14.11.2016 Sofia
          IF codresult IS NOT NULL THEN
            /*
codResult:=null;
strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
insert into fase_bil_t_prev_apertura_segnala
(elem_id,
elem_code,
elem_code2,
elem_code3,
bil_id,
fase_bil_elab_id,
segnala_codice,
segnala_desc,
validita_inizio,
ente_proprietario_id,
login_operazione)
(select capitolo.elem_id,
capitolo.elem_code,
capitolo.elem_code2,
capitolo.elem_code3,
capitolo.bil_id,
faseBilElabId,
CL_TRANSAZIONE_UE_SPESA,
CL_TRANSAZIONE_UE_SPESA||' mancante',
dataInizioVal,
capitolo.ente_proprietario_id,
loginOperazione
from siac_t_bil_elem capitolo
where  capitolo.elem_id=bilElemIdRet
)
returning fase_bil_prev_ape_seg_id into codresult;
if codResult is  null then raise exception ' Nessuno inserimento effettuato.'; end if;
*/
            --provo a collegare il capitolo con il classificatore equivalente nuovo
            --siac-5297
            -- Sofia 21.11.2017
            INSERT INTO siac_r_bil_elem_class
                        (
                                    elem_id,
                                    classif_id,
                                    validita_inizio,
                                    ente_proprietario_id,
                                    login_operazione
                        )
                        (
                               SELECT bilelemidret,
                                      c.classif_id,
                                      datainizioval,
                                      c.ente_proprietario_id,
                                      loginoperazione
                               FROM   siac_t_class c ,
                                      siac_r_bil_elem_class rprec,
                                      siac_t_class cprec
                               WHERE  rprec.elem_id=elembil.elem_id
                               AND    cprec.classif_id=rprec.classif_id
                               AND    cprec.classif_tipo_id =transazioneuespesaid
                               AND    rprec.data_cancellazione IS NULL
                               AND    date_trunc('day',dataelaborazione)>=date_trunc('day',rprec.validita_inizio)
                               AND    (
                                             date_trunc('day',dataelaborazione)<=date_trunc('day',rprec.validita_fine)
                                      OR     rprec.validita_fine IS NULL) -- relazione ad oggi valida
                               AND    cprec.data_cancellazione IS NULL
                               AND    date_trunc('day',v_dataprimogiornoanno)>date_trunc('day',cprec.validita_fine) -- su classif chiuso in data in anno prec
                               AND    c.ente_proprietario_id=cprec.ente_proprietario_id
                               AND    c.classif_tipo_id=cprec.classif_tipo_id
                               AND    c.classif_code=cprec.classif_code
                               AND    c.data_cancellazione IS NULL -- cercando un classificatore equivalente aperto su anno succ
                               AND    date_trunc('day',v_dataprimogiornoanno)<=date_trunc('day',c.validita_inizio)
                               AND    (
                                             date_trunc('day',v_dataprimogiornoanno) < date_trunc('day',c.validita_fine)
                                      OR     c.validita_fine IS NULL) );

            GET diagnostics _row_count = row_count;
            if elembil.elem_id=55447 then
            	raise notice 'SOFIA SOFIA SOFIA _row_count=%',_row_count;
            end if;
            IF _row_count <1 THEN
              codresult:=NULL;
              strmessaggio:=strmessaggio
              ||' Inserimento segnalazione mancanza classif.';
              INSERT INTO fase_bil_t_prev_apertura_segnala
                          (
                                      elem_id,
                                      elem_code,
                                      elem_code2,
                                      elem_code3,
                                      bil_id,
                                      fase_bil_elab_id,
                                      segnala_codice,
                                      segnala_desc,
                                      validita_inizio,
                                      ente_proprietario_id,
                                      login_operazione
                          )
                          (
                                 SELECT capitolo.elem_id,
                                        capitolo.elem_code,
                                        capitolo.elem_code2,
                                        capitolo.elem_code3,
                                        capitolo.bil_id,
                                        fasebilelabid,
                                        cl_transazione_ue_spesa,
                                        cl_transazione_ue_spesa
                                               ||' mancante',
                                        datainizioval,
                                        capitolo.ente_proprietario_id,
                                        loginoperazione
                                 FROM   siac_t_bil_elem capitolo
                                 WHERE  capitolo.elem_id=bilelemidret )
              returning   fase_bil_prev_ape_seg_id
              INTO        codresult;
			 raise notice 'fase_bil_prev_ape_seg_id=%',codresult;
              IF codresult IS NULL THEN
                RAISE
              EXCEPTION
                ' Nessuno inserimento effettuato.';
              END IF;
            END IF;
          END IF;
        ELSE
          -- CL_CATEGORIA
          codresult:=NULL;
          strmessaggio:='Inserimento nuove strutture per tipo='
          ||bilelemgesttipo
          || '.Elemento di bilancio '
          ||elembil.elem_code
          ||' '
          ||elembil.elem_code2
          ||' '
          ||elembil.elem_code3
          ||' : verifica classificatore '
          ||cl_categoria
          ||'.' ;
          SELECT   1
          INTO     codresult
          FROM     siac_r_bil_elem_class r,
                   siac_t_class c
          WHERE    r.elem_id=bilelemidret
          AND      c.classif_id=r.classif_id
          AND      c.classif_tipo_id=categoriatipoid
          AND      r.data_cancellazione IS NULL
          AND      date_trunc('day',dataelaborazione)>=date_trunc('day',r.validita_inizio)
          AND      (
                            date_trunc('day',dataelaborazione)<=date_trunc('day',r.validita_fine)
                   OR       r.validita_fine IS NULL)
          AND      c.data_cancellazione IS NULL
          /*AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
          AND      (
                            date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                   OR       c.validita_fine IS NULL)*/
          ORDER BY r.elem_id limit 1;

          -- Obbligatorieta  del classificatore vale solo per capitolo STANDARD
          IF categoriacapcode = categoria_std THEN
            -- JIRA-SIAC-4167 14.11.2016 Sofia
            -- if codResult is null then raise exception ' Nessuno inserimento effettuato.'; end if;
            IF codresult IS NULL THEN
              /*
codResult:=null;
strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
insert into fase_bil_t_prev_apertura_segnala
(elem_id,
elem_code,
elem_code2,
elem_code3,
bil_id,
fase_bil_elab_id,
segnala_codice,
segnala_desc,
validita_inizio,
ente_proprietario_id,
login_operazione)
(select capitolo.elem_id,
capitolo.elem_code,
capitolo.elem_code2,
capitolo.elem_code3,
capitolo.bil_id,
faseBilElabId,
CL_CATEGORIA,
CL_CATEGORIA||' mancante',
dataInizioVal,
capitolo.ente_proprietario_id,
loginOperazione
from siac_t_bil_elem capitolo
where  capitolo.elem_id=bilElemIdRet
)
returning fase_bil_prev_ape_seg_id into codresult;
if codResult is null then raise exception ' Nessuno inserimento effettuato.'; end if;
*/
              --provo a collegare il capitolo con il classificatore equivalente nuovo
              --siac-5297
              -- Sofia 21.11.2017
              INSERT INTO siac_r_bil_elem_class
                          (
                                      elem_id,
                                      classif_id,
                                      validita_inizio,
                                      ente_proprietario_id,
                                      login_operazione
                          )
                          (
                                 SELECT bilelemidret,
                                        c.classif_id,
                                        datainizioval,
                                        c.ente_proprietario_id,
                                        loginoperazione
                                 FROM   siac_t_class c ,
                                        siac_r_bil_elem_class rprec,
                                        siac_t_class cprec
                                 WHERE  rprec.elem_id=elembil.elem_id
                                 AND    cprec.classif_id=rprec.classif_id
                                 AND    cprec.classif_tipo_id =categoriatipoid
                                 AND    rprec.data_cancellazione IS NULL
                                 AND    date_trunc('day',dataelaborazione)>=date_trunc('day',rprec.validita_inizio)
                                 AND    (
                                               date_trunc('day',dataelaborazione)<=date_trunc('day',rprec.validita_fine)
                                        OR     rprec.validita_fine IS NULL) -- relazione ad oggi valida
                                 AND    cprec.data_cancellazione IS NULL
                                 AND    date_trunc('day',v_dataprimogiornoanno)>date_trunc('day',cprec.validita_fine) -- su classif chiuso in data in anno prec
                                 AND    c.ente_proprietario_id=cprec.ente_proprietario_id
                                 AND    c.classif_tipo_id=cprec.classif_tipo_id
                                 AND    c.classif_code=cprec.classif_code
                                 AND    c.data_cancellazione IS NULL -- cercando un classificatore equivalente aperto su anno succ
                                 AND    date_trunc('day',v_dataprimogiornoanno)<=date_trunc('day',c.validita_inizio)
                                 AND    (
                                               date_trunc('day',v_dataprimogiornoanno) < date_trunc('day',c.validita_fine)
                                        OR     c.validita_fine IS NULL) );

              GET diagnostics _row_count = row_count;
              IF _row_count <1 THEN
                codresult:=NULL;
                strmessaggio:=strmessaggio
                ||' Inserimento segnalazione mancanza classif.';
                INSERT INTO fase_bil_t_prev_apertura_segnala
                            (
                                        elem_id,
                                        elem_code,
                                        elem_code2,
                                        elem_code3,
                                        bil_id,
                                        fase_bil_elab_id,
                                        segnala_codice,
                                        segnala_desc,
                                        validita_inizio,
                                        ente_proprietario_id,
                                        login_operazione
                            )
                            (
                                   SELECT capitolo.elem_id,
                                          capitolo.elem_code,
                                          capitolo.elem_code2,
                                          capitolo.elem_code3,
                                          capitolo.bil_id,
                                          fasebilelabid,
                                          cl_categoria,
                                          cl_categoria
                                                 ||' mancante',
                                          datainizioval,
                                          capitolo.ente_proprietario_id,
                                          loginoperazione
                                   FROM   siac_t_bil_elem capitolo
                                   WHERE  capitolo.elem_id=bilelemidret )
                returning   fase_bil_prev_ape_seg_id
                INTO        codresult;

                IF codresult IS NULL THEN
                  RAISE
                EXCEPTION
                  ' Nessuno inserimento effettuato.';
                END IF;
              END IF;
            END IF;
          END IF;
          -- CL_RICORRENTE_ENTRATA
          codresult:=NULL;
          strmessaggio:='Inserimento nuove strutture per tipo='
          ||bilelemgesttipo
          || '.Elemento di bilancio '
          ||elembil.elem_code
          ||' '
          ||elembil.elem_code2
          ||' '
          ||elembil.elem_code3
          ||' : verifica classificatore '
          ||cl_ricorrente_entrata
          ||'.' ;
          SELECT   1
          INTO     codresult
          FROM     siac_r_bil_elem_class r,
                   siac_t_class c
          WHERE    r.elem_id=elembil.elem_id
          AND      c.classif_id=r.classif_id
          AND      c.classif_tipo_id=ricorrenteentrataid
          AND      r.data_cancellazione IS NULL
          AND      date_trunc('day',dataelaborazione)>=date_trunc('day',r.validita_inizio)
          AND      (
                            date_trunc('day',dataelaborazione)<=date_trunc('day',r.validita_fine)
                   OR       r.validita_fine IS NULL)
          AND      c.data_cancellazione IS NULL
          /*AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
          AND      (
                            date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                   OR       c.validita_fine IS NULL)*/
          AND      NOT EXISTS
                   (
                                   SELECT DISTINCT 1
                                   FROM            siac_r_bil_elem_class r,
                                                   siac_t_class c
                                   WHERE           r.elem_id=bilelemidret
                                   AND             c.classif_id=r.classif_id
                                   AND             c.classif_tipo_id=ricorrenteentrataid
                                   AND             c.data_cancellazione IS NULL
                                   /*AND             date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                   AND             (
                                                                   date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                   OR              c.validita_fine IS NULL) */)
          ORDER BY r.elem_id limit 1;

          -- JIRA-SIAC-4167 14.11.2016 Sofia
          IF codresult IS NOT NULL THEN
            /*
codResult:=null;
strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
insert into fase_bil_t_prev_apertura_segnala
(elem_id,
elem_code,
elem_code2,
elem_code3,
bil_id,
fase_bil_elab_id,
segnala_codice,
segnala_desc,
validita_inizio,
ente_proprietario_id,
login_operazione)
(select capitolo.elem_id,
capitolo.elem_code,
capitolo.elem_code2,
capitolo.elem_code3,
capitolo.bil_id,
faseBilElabId,
CL_RICORRENTE_ENTRATA,
CL_RICORRENTE_ENTRATA||' mancante',
dataInizioVal,
capitolo.ente_proprietario_id,
loginOperazione
from siac_t_bil_elem capitolo
where  capitolo.elem_id=bilElemIdRet
)
returning fase_bil_prev_ape_seg_id into codresult;
if codResult is  null then raise exception ' Nessuno inserimento effettuato.'; end if;
*/
            --provo a collegare il capitolo con il classificatore equivalente nuovo
            --siac-5297
            -- Sofia 21.11.2017
            INSERT INTO siac_r_bil_elem_class
                        (
                                    elem_id,
                                    classif_id,
                                    validita_inizio,
                                    ente_proprietario_id,
                                    login_operazione
                        )
                        (
                               SELECT bilelemidret,
                                      c.classif_id,
                                      datainizioval,
                                      c.ente_proprietario_id,
                                      loginoperazione
                               FROM   siac_t_class c ,
                                      siac_r_bil_elem_class rprec,
                                      siac_t_class cprec
                               WHERE  rprec.elem_id=elembil.elem_id
                               AND    cprec.classif_id=rprec.classif_id
                               AND    cprec.classif_tipo_id =ricorrenteentrataid
                               AND    rprec.data_cancellazione IS NULL
                               AND    date_trunc('day',dataelaborazione)>=date_trunc('day',rprec.validita_inizio)
                               AND    (
                                             date_trunc('day',dataelaborazione)<=date_trunc('day',rprec.validita_fine)
                                      OR     rprec.validita_fine IS NULL) -- relazione ad oggi valida
                               AND    cprec.data_cancellazione IS NULL
                               AND    date_trunc('day',v_dataprimogiornoanno)>date_trunc('day',cprec.validita_fine) -- su classif chiuso in data in anno prec
                               AND    c.ente_proprietario_id=cprec.ente_proprietario_id
                               AND    c.classif_tipo_id=cprec.classif_tipo_id
                               AND    c.classif_code=cprec.classif_code
                               AND    c.data_cancellazione IS NULL -- cercando un classificatore equivalente aperto su anno succ
                               AND    date_trunc('day',v_dataprimogiornoanno)<=date_trunc('day',c.validita_inizio)
                               AND    (
                                             date_trunc('day',v_dataprimogiornoanno) < date_trunc('day',c.validita_fine)
                                      OR     c.validita_fine IS NULL) );

            GET diagnostics _row_count = row_count;
            IF _row_count <1 THEN
              codresult:=NULL;
              strmessaggio:=strmessaggio
              ||' Inserimento segnalazione mancanza classif.';
              INSERT INTO fase_bil_t_prev_apertura_segnala
                          (
                                      elem_id,
                                      elem_code,
                                      elem_code2,
                                      elem_code3,
                                      bil_id,
                                      fase_bil_elab_id,
                                      segnala_codice,
                                      segnala_desc,
                                      validita_inizio,
                                      ente_proprietario_id,
                                      login_operazione
                          )
                          (
                                 SELECT capitolo.elem_id,
                                        capitolo.elem_code,
                                        capitolo.elem_code2,
                                        capitolo.elem_code3,
                                        capitolo.bil_id,
                                        fasebilelabid,
                                        cl_ricorrente_entrata,
                                        cl_ricorrente_entrata
                                               ||' mancante',
                                        datainizioval,
                                        capitolo.ente_proprietario_id,
                                        loginoperazione
                                 FROM   siac_t_bil_elem capitolo
                                 WHERE  capitolo.elem_id=bilelemidret )
              returning   fase_bil_prev_ape_seg_id
              INTO        codresult;

              IF codresult IS NULL THEN
                RAISE
              EXCEPTION
                ' Nessuno inserimento effettuato.';
              END IF;
            END IF;
          END IF;
          -- CL_SIOPE_ENTRATA_TERZO
          codresult:=NULL;
          strmessaggio:='Inserimento nuove strutture per tipo='
          ||bilelemgesttipo
          || '.Elemento di bilancio '
          ||elembil.elem_code
          ||' '
          ||elembil.elem_code2
          ||' '
          ||elembil.elem_code3
          ||' : verifica classificatore '
          ||cl_siope_entrata_terzo
          ||'.' ;
          SELECT   1
          INTO     codresult
          FROM     siac_r_bil_elem_class r,
                   siac_t_class c
          WHERE    r.elem_id=elembil.elem_id
          AND      c.classif_id=r.classif_id
          AND      c.classif_tipo_id=siopeentratatipoid
          AND      r.data_cancellazione IS NULL
          AND      date_trunc('day',dataelaborazione)>=date_trunc('day',r.validita_inizio)
          AND      (
                            date_trunc('day',dataelaborazione)<=date_trunc('day',r.validita_fine)
                   OR       r.validita_fine IS NULL)
          AND      c.data_cancellazione IS NULL
          /*AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
          AND      (
                            date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                   OR       c.validita_fine IS NULL)*/
          AND      NOT EXISTS
                   (
                            SELECT   1
                            FROM     siac_r_bil_elem_class r,
                                     siac_t_class c
                            WHERE    r.elem_id=bilelemidret
                            AND      c.classif_id=r.classif_id
                            AND      c.classif_tipo_id=siopeentratatipoid
                            AND      c.data_cancellazione IS NULL
                            /*AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                            AND      (
                                              date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                     OR       c.validita_fine IS NULL)*/
                            ORDER BY r.elem_id limit 1)
          ORDER BY r.elem_id limit 1;

          -- JIRA-SIAC-4167 14.11.2016 Sofia
          IF codresult IS NOT NULL THEN
            /*
codResult:=null;
strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
insert into fase_bil_t_prev_apertura_segnala
(elem_id,
elem_code,
elem_code2,
elem_code3,
bil_id,
fase_bil_elab_id,
segnala_codice,
segnala_desc,
validita_inizio,
ente_proprietario_id,
login_operazione)
(select capitolo.elem_id,
capitolo.elem_code,
capitolo.elem_code2,
capitolo.elem_code3,
capitolo.bil_id,
faseBilElabId,
CL_SIOPE_ENTRATA_TERZO,
CL_SIOPE_ENTRATA_TERZO||' mancante',
dataInizioVal,
capitolo.ente_proprietario_id,
loginOperazione
from siac_t_bil_elem capitolo
where  capitolo.elem_id=bilElemIdRet
)
returning fase_bil_prev_ape_seg_id into codresult;
if codResult is  null then raise exception ' Nessuno inserimento effettuato.'; end if;
*/
            --provo a collegare il capitolo con il classificatore equivalente nuovo
            --siac-5297
            -- Sofia 21.11.2017
            INSERT INTO siac_r_bil_elem_class
                        (
                                    elem_id,
                                    classif_id,
                                    validita_inizio,
                                    ente_proprietario_id,
                                    login_operazione
                        )
                        (
                               SELECT bilelemidret,
                                      c.classif_id,
                                      datainizioval,
                                      c.ente_proprietario_id,
                                      loginoperazione
                               FROM   siac_t_class c ,
                                      siac_r_bil_elem_class rprec,
                                      siac_t_class cprec
                               WHERE  rprec.elem_id=elembil.elem_id
                               AND    cprec.classif_id=rprec.classif_id
                               AND    cprec.classif_tipo_id =siopeentratatipoid
                               AND    rprec.data_cancellazione IS NULL
                               AND    date_trunc('day',dataelaborazione)>=date_trunc('day',rprec.validita_inizio)
                               AND    (
                                             date_trunc('day',dataelaborazione)<=date_trunc('day',rprec.validita_fine)
                                      OR     rprec.validita_fine IS NULL) -- relazione ad oggi valida
                               AND    cprec.data_cancellazione IS NULL
                               AND    date_trunc('day',v_dataprimogiornoanno)>date_trunc('day',cprec.validita_fine) -- su classif chiuso in data in anno prec
                               AND    c.ente_proprietario_id=cprec.ente_proprietario_id
                               AND    c.classif_tipo_id=cprec.classif_tipo_id
                               AND    c.classif_code=cprec.classif_code
                               AND    c.data_cancellazione IS NULL -- cercando un classificatore equivalente aperto su anno succ
                               AND    date_trunc('day',v_dataprimogiornoanno)<=date_trunc('day',c.validita_inizio)
                               AND    (
                                             date_trunc('day',v_dataprimogiornoanno) < date_trunc('day',c.validita_fine)
                                      OR     c.validita_fine IS NULL) );

            GET diagnostics _row_count = row_count;
            IF _row_count <1 THEN
              codresult:=NULL;
              strmessaggio:=strmessaggio
              ||' Inserimento segnalazione mancanza classif.';
              INSERT INTO fase_bil_t_prev_apertura_segnala
                          (
                                      elem_id,
                                      elem_code,
                                      elem_code2,
                                      elem_code3,
                                      bil_id,
                                      fase_bil_elab_id,
                                      segnala_codice,
                                      segnala_desc,
                                      validita_inizio,
                                      ente_proprietario_id,
                                      login_operazione
                          )
                          (
                                 SELECT capitolo.elem_id,
                                        capitolo.elem_code,
                                        capitolo.elem_code2,
                                        capitolo.elem_code3,
                                        capitolo.bil_id,
                                        fasebilelabid,
                                        cl_siope_entrata_terzo,
                                        cl_siope_entrata_terzo
                                               ||' mancante',
                                        datainizioval,
                                        capitolo.ente_proprietario_id,
                                        loginoperazione
                                 FROM   siac_t_bil_elem capitolo
                                 WHERE  capitolo.elem_id=bilelemidret )
              returning   fase_bil_prev_ape_seg_id
              INTO        codresult;

              IF codresult IS NULL THEN
                RAISE
              EXCEPTION
                ' Nessuno inserimento effettuato.';
              END IF;
            END IF;
          END IF;
          -- CL_TRANSAZIONE_UE_ENTRATA
          codresult:=NULL;
          strmessaggio:='Inserimento nuove strutture per tipo='
          ||bilelemgesttipo
          || '.Elemento di bilancio '
          ||elembil.elem_code
          ||' '
          ||elembil.elem_code2
          ||' '
          ||elembil.elem_code3
          ||' : verifica classificatore '
          ||cl_transazione_ue_entrata
          ||'.' ;
          SELECT   1
          INTO     codresult
          FROM     siac_r_bil_elem_class r,
                   siac_t_class c
          WHERE    r.elem_id=elembil.elem_id
          AND      c.classif_id=r.classif_id
          AND      c.classif_tipo_id=transazioneueentrataid
          AND      r.data_cancellazione IS NULL
          AND      date_trunc('day',dataelaborazione)>=date_trunc('day',r.validita_inizio)
          AND      (
                            date_trunc('day',dataelaborazione)<=date_trunc('day',r.validita_fine)
                   OR       r.validita_fine IS NULL)
          AND      c.data_cancellazione IS NULL
          /*AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
          AND      (
                            date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                   OR       c.validita_fine IS NULL)*/
          AND      NOT EXISTS
                   (
                                   SELECT DISTINCT 1
                                   FROM            siac_r_bil_elem_class r,
                                                   siac_t_class c
                                   WHERE           r.elem_id=bilelemidret
                                   AND             c.classif_id=r.classif_id
                                   AND             c.classif_tipo_id=transazioneueentrataid
                                   AND             c.data_cancellazione IS NULL
                                   /*AND             date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                   AND             (
                                                                   date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                   OR              c.validita_fine IS NULL) */)
          ORDER BY r.elem_id limit 1;

          -- JIRA-SIAC-4167 14.11.2016 Sofia
          IF codresult IS NOT NULL THEN
            /*
codResult:=null;
strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
insert into fase_bil_t_prev_apertura_segnala
(elem_id,
elem_code,
elem_code2,
elem_code3,
bil_id,
fase_bil_elab_id,
segnala_codice,
segnala_desc,
validita_inizio,
ente_proprietario_id,
login_operazione)
(select capitolo.elem_id,
capitolo.elem_code,
capitolo.elem_code2,
capitolo.elem_code3,
capitolo.bil_id,
faseBilElabId,
CL_TRANSAZIONE_UE_ENTRATA,
CL_TRANSAZIONE_UE_ENTRATA||' mancante',
dataInizioVal,
capitolo.ente_proprietario_id,
loginOperazione
from siac_t_bil_elem capitolo
where  capitolo.elem_id=bilElemIdRet
)
returning fase_bil_prev_ape_seg_id into codresult;
if codResult is  null then raise exception ' Nessuno inserimento effettuato.'; end if;
*/
            --provo a collegare il capitolo con il classificatore equivalente nuovo
            --siac-5297
            -- Sofia 21.11.2017
            INSERT INTO siac_r_bil_elem_class
                        (
                                    elem_id,
                                    classif_id,
                                    validita_inizio,
                                    ente_proprietario_id,
                                    login_operazione
                        )
                        (
                               SELECT bilelemidret,
                                      c.classif_id,
                                      datainizioval,
                                      c.ente_proprietario_id,
                                      loginoperazione
                               FROM   siac_t_class c ,
                                      siac_r_bil_elem_class rprec,
                                      siac_t_class cprec
                               WHERE  rprec.elem_id=elembil.elem_id
                               AND    cprec.classif_id=rprec.classif_id
                               AND    cprec.classif_tipo_id =transazioneueentrataid
                               AND    rprec.data_cancellazione IS NULL
                               AND    date_trunc('day',dataelaborazione)>=date_trunc('day',rprec.validita_inizio)
                               AND    (
                                             date_trunc('day',dataelaborazione)<=date_trunc('day',rprec.validita_fine)
                                      OR     rprec.validita_fine IS NULL) -- relazione ad oggi valida
                               AND    cprec.data_cancellazione IS NULL
                               AND    date_trunc('day',v_dataprimogiornoanno)>date_trunc('day',cprec.validita_fine) -- su classif chiuso in data in anno prec
                               AND    c.ente_proprietario_id=cprec.ente_proprietario_id
                               AND    c.classif_tipo_id=cprec.classif_tipo_id
                               AND    c.classif_code=cprec.classif_code
                               AND    c.data_cancellazione IS NULL -- cercando un classificatore equivalente aperto su anno succ
                               AND    date_trunc('day',v_dataprimogiornoanno)<=date_trunc('day',c.validita_inizio)
                               AND    (
                                             date_trunc('day',v_dataprimogiornoanno) < date_trunc('day',c.validita_fine)
                                      OR     c.validita_fine IS NULL) );

            GET diagnostics _row_count = row_count;
            IF _row_count <1 THEN
              codresult:=NULL;
              strmessaggio:=strmessaggio
              ||' Inserimento segnalazione mancanza classif.';
              INSERT INTO fase_bil_t_prev_apertura_segnala
                          (
                                      elem_id,
                                      elem_code,
                                      elem_code2,
                                      elem_code3,
                                      bil_id,
                                      fase_bil_elab_id,
                                      segnala_codice,
                                      segnala_desc,
                                      validita_inizio,
                                      ente_proprietario_id,
                                      login_operazione
                          )
                          (
                                 SELECT capitolo.elem_id,
                                        capitolo.elem_code,
                                        capitolo.elem_code2,
                                        capitolo.elem_code3,
                                        capitolo.bil_id,
                                        fasebilelabid,
                                        cl_transazione_ue_entrata,
                                        cl_transazione_ue_entrata
                                               ||' mancante',
                                        datainizioval,
                                        capitolo.ente_proprietario_id,
                                        loginoperazione
                                 FROM   siac_t_bil_elem capitolo
                                 WHERE  capitolo.elem_id=bilelemidret )
              returning   fase_bil_prev_ape_seg_id
              INTO        codresult;

              IF codresult IS NULL THEN
                RAISE
              EXCEPTION
                ' Nessuno inserimento effettuato.';
              END IF;
            END IF;
          END IF;
        END IF;
        strmessaggio:='Inserimento nuove strutture per tipo='
        ||bilelemgesttipo
        || '.Elemento di bilancio '
        ||elembil.elem_code
        ||' '
        ||elembil.elem_code2
        ||' '
        ||elembil.elem_code3
        ||' : aggiornamento relazione tra elem_id_gest prec e elem_prov_id nuovo.' ;
        UPDATE fase_bil_t_gest_apertura_provv
        SET    elem_prov_new_id=bilelemidret
        WHERE  elem_id=elembil.elem_id
        AND    fase_bil_elab_id=fasebilelabid;

      END LOOP;
      strmessaggio:='Conclusione inserimento nuove strutture per tipo='
      ||bilelemgesttipo
      ||'.';
      codresult:=NULL;
      INSERT INTO fase_bil_t_elaborazione_log
                  (
                              fase_bil_elab_id,
                              fase_bil_elab_log_operazione,
                              validita_inizio,
                              login_operazione,
                              ente_proprietario_id
                  )
                  VALUES
                  (
                              fasebilelabid,
                              strmessaggio,
                              clock_timestamp(),
                              loginoperazione,
                              enteproprietarioid
                  )
      returning   fase_bil_elab_log_id
      INTO        codresult;

      IF codresult IS NULL THEN
        RAISE
      EXCEPTION
        ' Errore in inserimento LOG.';
      END IF;
    END IF;
    -- verifica apertura gestione provvisorio con gestione pre-esistente ( rielaborazione )
    IF checkgest=TRUE THEN
      codresult:=NULL;
      strmessaggio:='Verifica esistenza elementi di bilancio provvisorio equivalenti da aggiornare da gestione anno prec.';
      SELECT   1
      INTO     codresult
      FROM     fase_bil_t_gest_apertura_provv fase
      WHERE    fase.ente_proprietario_id=enteproprietarioid
      AND      fase.bil_id=bilancioid
      AND      fase.fase_bil_elab_id=fasebilelabid
      AND      fase.data_cancellazione IS NULL
      AND      fase.validita_fine IS NULL
      AND      fase.elem_id IS NOT NULL      -- esistenti in gestione precedente
      AND      fase.elem_prov_new_id IS NULL -- non elaborati per nuovo inserimento in gestione corrente
      AND      fase.elem_prov_id IS NOT NULL -- esistente in gestione corrente
      ORDER BY fase.fase_bil_gest_ape_prov_id limit 1;

      IF codresult IS NOT NULL THEN
        -- popolamento tabelle bck per salvataggio precedenti strutture
        -- siac_t_bil_elem
        codresult:=NULL;
        INSERT INTO fase_bil_t_elaborazione_log
                    (
                                fase_bil_elab_id,
                                fase_bil_elab_log_operazione,
                                validita_inizio,
                                login_operazione,
                                ente_proprietario_id
                    )
                    VALUES
                    (
                                fasebilelabid,
                                strmessaggio,
                                clock_timestamp(),
                                loginoperazione,
                                enteproprietarioid
                    )
        returning   fase_bil_elab_log_id
        INTO        codresult;

        IF codresult IS NULL THEN
          RAISE
        EXCEPTION
          ' Errore in inserimento LOG.';
        END IF;
        strmessaggio:='Backup vecchia struttura [siac_t_bil_elem] per capitoli provvisorio equivalente per nuovo aggiornamento.';
        INSERT INTO bck_fase_bil_t_gest_apertura_provv_bil_elem
                    (
                                elem_id,
                                elem_bck_id,
                                elem_bck_code,
                                elem_bck_code2,
                                elem_bck_code3,
                                elem_bck_desc,
                                elem_bck_desc2,
                                elem_bck_bil_id,
                                elem_bck_id_padre,
                                elem_bck_tipo_id,
                                elem_bck_livello,
                                elem_bck_ordine,
                                elem_bck_data_creazione,
                                elem_bck_data_modifica,
                                elem_bck_login_operazione,
                                elem_bck_validita_inizio,
                                elem_bck_validita_fine,
                                fase_bil_elab_id,
                                ente_proprietario_id,
                                login_operazione,
                                validita_inizio
                    )
                    (
                           SELECT fase.elem_prov_id,
                                  elem.elem_id,
                                  elem.elem_code,
                                  elem.elem_code2,
                                  elem.elem_code3,
                                  elem.elem_desc,
                                  elem.elem_desc2,
                                  elem.bil_id,
                                  elem.elem_id_padre,
                                  elem.elem_tipo_id,
                                  elem.livello,
                                  elem.ordine,
                                  elem.data_creazione,
                                  elem.data_modifica,
                                  elem.login_operazione,
                                  elem.validita_inizio,
                                  elem.validita_fine,
                                  fasebilelabid,
                                  elem.ente_proprietario_id,
                                  loginoperazione,
                                  datainizioval
                           FROM   fase_bil_t_gest_apertura_provv fase,
                                  siac_t_bil_elem elem
                           WHERE  fase.ente_proprietario_id=enteproprietarioid
                           AND    fase.bil_id=bilancioid
                           AND    fase.fase_bil_elab_id=fasebilelabid
                           AND    elem.elem_id=fase.elem_prov_id
                           AND    fase.data_cancellazione IS NULL
                           AND    fase.validita_fine IS NULL
                           AND    fase.elem_prov_id IS NOT NULL -- esistente in gestione corrente
                           AND    fase.elem_id IS NOT NULL      -- esistente in gestione precedente
                           AND    fase.elem_prov_new_id IS NULL -- non inserito come nuovo gestione
                    );

        -- bck per attributi e classificatori, stato e categoria
        strmessaggio:='Backup vecchia struttura [siac_r_bil_elem_stato] per capitoli provvisorio equivalente per nuovo aggiornamento.';
        INSERT INTO bck_fase_bil_t_gest_apertura_provv_bil_elem_stato
                    (
                                elem_id,
                                elem_bck_id,
                                elem_bck_stato_id,
                                elem_bck_data_creazione,
                                elem_bck_data_modifica,
                                elem_bck_login_operazione,
                                elem_bck_validita_inizio,
                                elem_bck_validita_fine,
                                fase_bil_elab_id,
                                ente_proprietario_id,
                                login_operazione,
                                validita_inizio
                    )
                    (
                           SELECT fase.elem_prov_id,
                                  elem.elem_id,
                                  elem.elem_stato_id,
                                  elem.data_creazione,
                                  elem.data_modifica,
                                  elem.login_operazione,
                                  elem.validita_inizio,
                                  elem.validita_fine,
                                  fasebilelabid,
                                  elem.ente_proprietario_id,
                                  loginoperazione,
                                  datainizioval
                           FROM   fase_bil_t_gest_apertura_provv fase,
                                  siac_r_bil_elem_stato elem
                           WHERE  fase.ente_proprietario_id=enteproprietarioid
                           AND    fase.bil_id=bilancioid
                           AND    fase.fase_bil_elab_id=fasebilelabid
                           AND    elem.elem_id=fase.elem_prov_id
                           AND    fase.data_cancellazione IS NULL
                           AND    fase.validita_fine IS NULL
                           AND    fase.elem_prov_id IS NOT NULL -- esistente in gestione corrente
                           AND    fase.elem_id IS NOT NULL      -- esistente in gestione precedente
                           AND    fase.elem_prov_new_id IS NULL -- non inserito come nuovo gestione
                           AND    elem.data_cancellazione IS NULL
                           AND    elem.validita_fine IS NULL );

        strmessaggio:='Backup vecchia struttura [siac_r_bil_elem_attr] per capitoli provvisorio equivalente per nuovo aggiornamento.';
        INSERT INTO bck_fase_bil_t_gest_apertura_provv_bil_elem_attr
                    (
                                elem_id,
                                elem_bck_id,
                                elem_bck_attr_id,
                                elem_bck_tabella_id,
                                elem_bck_boolean,
                                elem_bck_percentuale,
                                elem_bck_testo,
                                elem_bck_numerico,
                                elem_bck_data_creazione,
                                elem_bck_data_modifica,
                                elem_bck_login_operazione,
                                elem_bck_validita_inizio,
                                elem_bck_validita_fine,
                                fase_bil_elab_id,
                                ente_proprietario_id,
                                login_operazione,
                                validita_inizio
                    )
                    (
                           SELECT fase.elem_prov_id,
                                  elem.elem_id,
                                  elem.attr_id,
                                  elem.tabella_id,
                                  elem."boolean",
                                  elem.percentuale,
                                  elem.testo,
                                  elem.numerico,
                                  elem.data_creazione,
                                  elem.data_modifica,
                                  elem.login_operazione,
                                  elem.validita_inizio,
                                  elem.validita_fine,
                                  fasebilelabid,
                                  elem.ente_proprietario_id,
                                  loginoperazione,
                                  datainizioval
                           FROM   fase_bil_t_gest_apertura_provv fase,
                                  siac_r_bil_elem_attr elem
                           WHERE  fase.ente_proprietario_id=enteproprietarioid
                           AND    fase.bil_id=bilancioid
                           AND    fase.fase_bil_elab_id=fasebilelabid
                           AND    elem.elem_id=fase.elem_prov_id
                           AND    fase.data_cancellazione IS NULL
                           AND    fase.validita_fine IS NULL
                           AND    fase.elem_prov_id IS NOT NULL -- esistente in gestione corrente
                           AND    fase.elem_id IS NOT NULL      -- esistente in gestione precedente
                           AND    fase.elem_prov_new_id IS NULL -- non inserito come nuovo gestione
                           AND    elem.data_cancellazione IS NULL
                           AND    elem.validita_fine IS NULL );

        strmessaggio:='Backup vecchia struttura [siac_r_bil_elem_class] per capitoli provvisorio equivalente per nuovo aggiornamento.';
        INSERT INTO bck_fase_bil_t_gest_apertura_provv_bil_elem_class
                    (
                                elem_id,
                                elem_bck_id,
                                elem_bck_classif_id,
                                elem_bck_data_creazione,
                                elem_bck_data_modifica,
                                elem_bck_login_operazione,
                                elem_bck_validita_inizio,
                                elem_bck_validita_fine,
                                fase_bil_elab_id,
                                ente_proprietario_id,
                                login_operazione,
                                validita_inizio
                    )
                    (
                           SELECT fase.elem_prov_id,
                                  elem.elem_id,
                                  elem.classif_id,
                                  elem.data_creazione,
                                  elem.data_modifica,
                                  elem.login_operazione,
                                  elem.validita_inizio,
                                  elem.validita_fine,
                                  fasebilelabid,
                                  elem.ente_proprietario_id,
                                  loginoperazione,
                                  datainizioval
                           FROM   fase_bil_t_gest_apertura_provv fase,
                                  siac_r_bil_elem_class elem
                           WHERE  fase.ente_proprietario_id=enteproprietarioid
                           AND    fase.bil_id=bilancioid
                           AND    fase.fase_bil_elab_id=fasebilelabid
                           AND    elem.elem_id=fase.elem_prov_id
                           AND    fase.data_cancellazione IS NULL
                           AND    fase.validita_fine IS NULL
                           AND    fase.elem_prov_id IS NOT NULL -- esistente in gestione corrente
                           AND    fase.elem_id IS NOT NULL      -- esistente in gestione precedente
                           AND    fase.elem_prov_new_id IS NULL -- non inserito come nuovo gestione
                           AND    elem.data_cancellazione IS NULL
                           AND    elem.validita_fine IS NULL );

        strmessaggio:='Backup vecchia struttura [siac_r_bil_elem_categoria] per capitoli provvisorio equivalente per nuovo aggiornamento.';
        INSERT INTO bck_fase_bil_t_gest_apertura_provv_bil_elem_categ
                    (
                                elem_id,
                                elem_bck_id,
                                elem_bck_cat_id,
                                elem_bck_data_creazione,
                                elem_bck_data_modifica,
                                elem_bck_login_operazione,
                                elem_bck_validita_inizio,
                                elem_bck_validita_fine,
                                fase_bil_elab_id,
                                ente_proprietario_id,
                                login_operazione,
                                validita_inizio
                    )
                    (
                           SELECT fase.elem_prov_id,
                                  elem.elem_id,
                                  elem.elem_cat_id,
                                  elem.data_creazione,
                                  elem.data_modifica,
                                  elem.login_operazione,
                                  elem.validita_inizio,
                                  elem.validita_fine,
                                  fasebilelabid,
                                  elem.ente_proprietario_id,
                                  loginoperazione,
                                  datainizioval
                           FROM   fase_bil_t_gest_apertura_provv fase,
                                  siac_r_bil_elem_categoria elem
                           WHERE  fase.ente_proprietario_id=enteproprietarioid
                           AND    fase.bil_id=bilancioid
                           AND    fase.fase_bil_elab_id=fasebilelabid
                           AND    elem.elem_id=fase.elem_prov_id
                           AND    fase.data_cancellazione IS NULL
                           AND    fase.validita_fine IS NULL
                           AND    fase.elem_prov_id IS NOT NULL -- esistente in gestione corrente
                           AND    fase.elem_id IS NOT NULL      -- esistente in gestione precedente
                           AND    fase.elem_prov_new_id IS NULL -- non inserito come nuovo gestione
                           AND    elem.data_cancellazione IS NULL
                           AND    elem.validita_fine IS NULL );

        codresult:=NULL;
        INSERT INTO fase_bil_t_elaborazione_log
                    (
                                fase_bil_elab_id,
                                fase_bil_elab_log_operazione,
                                validita_inizio,
                                login_operazione,
                                ente_proprietario_id
                    )
                    VALUES
                    (
                                fasebilelabid,
                                strmessaggio,
                                clock_timestamp(),
                                loginoperazione,
                                enteproprietarioid
                    )
        returning   fase_bil_elab_log_id
        INTO        codresult;

        IF codresult IS NULL THEN
          RAISE
        EXCEPTION
          ' Errore in inserimento LOG.';
        END IF;
        codresult:=NULL;
        strmessaggio:='Inizio cancellazione logica vecchie strutture provvisorio esistenti.';
        INSERT INTO fase_bil_t_elaborazione_log
                    (
                                fase_bil_elab_id,
                                fase_bil_elab_log_operazione,
                                validita_inizio,
                                login_operazione,
                                ente_proprietario_id
                    )
                    VALUES
                    (
                                fasebilelabid,
                                strmessaggio,
                                clock_timestamp(),
                                loginoperazione,
                                enteproprietarioid
                    )
        returning   fase_bil_elab_log_id
        INTO        codresult;

        IF codresult IS NULL THEN
          RAISE
        EXCEPTION
          ' Errore in inserimento LOG.';
        END IF;
        -- cancellazione logica precendenti relazioni
        -- siac_r_bil_elem_stato
        /* per queste relazioni si va in aggiornamento fatti bck prima
strMessaggio:='Cancellazione logica vecchie strutture provvisorio esistenti [siac_r_bil_elem_stato].';
update siac_r_bil_elem_stato canc  set
data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
where canc.ente_proprietario_id=enteProprietarioId
and   canc.data_cancellazione is null and canc.validita_fine is null
and   exists (select 1 from fase_bil_t_gest_apertura_provv fase
where fase.ente_proprietario_id=enteProprietarioId
and   fase.bil_id=bilancioId
and   fase.fase_bil_elab_id=faseBilElabId
and   fase.elem_prov_id=canc.elem_id
and   fase.elem_prov_id is not null
and   fase.elem_id is not null
and   fase.elem_prov_new_id is null
and   fase.data_cancellazione is null
order by fase.fase_bil_gest_ape_prov_id
limit 1);
-- siac_r_bil_elem_categoria
strMessaggio:='Cancellazione logica vecchie strutture provvisorio esistenti [siac_r_bil_elem_categoria].';
update  siac_r_bil_elem_categoria canc set
data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
where canc.ente_proprietario_id=enteProprietarioId
and   canc.data_cancellazione is null and canc.validita_fine is null
and   exists (select 1 from fase_bil_t_gest_apertura_provv fase
where fase.ente_proprietario_id=enteProprietarioId
and   fase.bil_id=bilancioId
and   fase.fase_bil_elab_id=faseBilElabId
and   fase.elem_prov_id=canc.elem_id
and   fase.elem_prov_id is not null
and   fase.elem_id is not null
and   fase.elem_prov_new_id is null
and   fase.data_cancellazione is null
order by fase.fase_bil_gest_ape_prov_id
limit 1);
-- siac_r_bil_elem_attr
strMessaggio:='Cancellazione logica vecchie strutture provvisorio esistenti [siac_r_bil_elem_attr].';
update siac_r_bil_elem_attr canc set
data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
where canc.ente_proprietario_id=enteProprietarioId
and   canc.data_cancellazione is null and canc.validita_fine is null
and   exists (select 1 from fase_bil_t_gest_apertura_provv fase
where fase.ente_proprietario_id=enteProprietarioId
and   fase.bil_id=bilancioId
and   fase.fase_bil_elab_id=faseBilElabId
and   fase.elem_prov_id=canc.elem_id
and   fase.elem_prov_id is not null
and   fase.elem_id is not null
and   fase.elem_prov_new_id is null
and   fase.data_cancellazione is null
order by fase.fase_bil_gest_ape_prov_id
limit 1);
-- siac_r_bil_elem_class
strMessaggio:='Cancellazione logica vecchie strutture provvisorio esistenti [siac_r_bil_elem_class].';
update siac_r_bil_elem_class canc set
data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
where canc.ente_proprietario_id=enteProprietarioId
and   canc.data_cancellazione is null and canc.validita_fine is null
and   exists (select 1 from fase_bil_t_gest_apertura_provv fase
where fase.ente_proprietario_id=enteProprietarioId
and   fase.bil_id=bilancioId
and   fase.fase_bil_elab_id=faseBilElabId
and   fase.elem_prov_id=canc.elem_id
and   fase.elem_prov_id is not null
and   fase.elem_id is not null
and   fase.elem_prov_new_id is null
and   fase.data_cancellazione is null
order by fase.fase_bil_gest_ape_prov_id
limit 1);
*/
        /*--SIAC-5590
-- siac_r_vincolo_bil_elem
strMessaggio:='Cancellazione logica vecchie strutture provvisorio esistenti [siac_r_vincolo_bil_elem].';
update siac_r_vincolo_bil_elem canc set
data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
where canc.ente_proprietario_id=enteProprietarioId
and   canc.data_cancellazione is null and canc.validita_fine is null
and   exists (select 1 from fase_bil_t_gest_apertura_provv fase
where fase.ente_proprietario_id=enteProprietarioId
and   fase.bil_id=bilancioId
and   fase.fase_bil_elab_id=faseBilElabId
and   fase.elem_prov_id=canc.elem_id
and   fase.elem_prov_id is not null
and   fase.elem_id is not null
and   fase.elem_prov_new_id is null
and   fase.data_cancellazione is null
order by fase.fase_bil_gest_ape_prov_id
limit 1);
*/
        -- siac_r_bil_elem_atto_legge
        strmessaggio:='Cancellazione logica vecchie strutture provvisorio esistenti [siac_r_bil_elem_atto_legge].';
        UPDATE siac_r_bil_elem_atto_legge canc
        SET    data_cancellazione=now(),
               validita_fine=now(),
               login_operazione=loginoperazione
        WHERE  canc.ente_proprietario_id=enteproprietarioid
        AND    canc.data_cancellazione IS NULL
        AND    canc.validita_fine IS NULL
        AND    EXISTS
               (
                        SELECT   1
                        FROM     fase_bil_t_gest_apertura_provv fase
                        WHERE    fase.ente_proprietario_id=enteproprietarioid
                        AND      fase.bil_id=bilancioid
                        AND      fase.fase_bil_elab_id=fasebilelabid
                        AND      fase.elem_prov_id=canc.elem_id
                        AND      fase.elem_prov_id IS NOT NULL
                        AND      fase.elem_id IS NOT NULL
                        AND      fase.elem_prov_new_id IS NULL
                        AND      fase.data_cancellazione IS NULL
                        ORDER BY fase.fase_bil_gest_ape_prov_id limit 1);

        -- siac_r_bil_elem_rel_tempo
        strmessaggio:='Cancellazione logica vecchie strutture provvisorio esistenti [siac_r_bil_elem_rel_tempo].';
        UPDATE siac_r_bil_elem_rel_tempo canc
        SET    data_cancellazione=now(),
               validita_fine=now(),
               login_operazione=loginoperazione
        WHERE  canc.ente_proprietario_id=enteproprietarioid
        AND    canc.data_cancellazione IS NULL
        AND    canc.validita_fine IS NULL
        AND    EXISTS
               (
                        SELECT   1
                        FROM     fase_bil_t_gest_apertura_provv fase
                        WHERE    fase.ente_proprietario_id=enteproprietarioid
                        AND      fase.bil_id=bilancioid
                        AND      fase.fase_bil_elab_id=fasebilelabid
                        AND      fase.elem_prov_id=canc.elem_id
                        AND      fase.elem_prov_id IS NOT NULL
                        AND      fase.elem_id IS NOT NULL
                        AND      fase.elem_prov_new_id IS NULL
                        AND      fase.data_cancellazione IS NULL
                        ORDER BY fase.fase_bil_gest_ape_prov_id limit 1);

        codresult:=NULL;
        strmessaggio:='Fine cancellazione logica vecchie strutture provvisorio esistenti.';
        INSERT INTO fase_bil_t_elaborazione_log
                    (
                                fase_bil_elab_id,
                                fase_bil_elab_log_operazione,
                                validita_inizio,
                                login_operazione,
                                ente_proprietario_id
                    )
                    VALUES
                    (
                                fasebilelabid,
                                strmessaggio,
                                clock_timestamp(),
                                loginoperazione,
                                enteproprietarioid
                    )
        returning   fase_bil_elab_log_id
        INTO        codresult;

        IF codresult IS NULL THEN
          RAISE
        EXCEPTION
          ' Errore in inserimento LOG.';
        END IF;
        -- cancellazione logica precendenti relazioni
        -- aggiornamento siac_t_bil_elem
        strmessaggio:='Aggiornamento nuova struttura provvisorio esistente da gestione equivalente anno precedente [siac_t_bil_elem].';
        UPDATE siac_t_bil_elem gestcorr
        SET
               (
                      elem_desc,
                      elem_desc2,
                      ordine,
                      livello,
                      data_modifica,
                      login_operazione
               )
               = (gest.elem_desc,gest.elem_desc2,gest.ordine,gest.livello,now(),loginoperazione)
        FROM   fase_bil_t_gest_apertura_provv fase,
               siac_t_bil_elem gest
        WHERE  gestcorr.ente_proprietario_id=enteproprietarioid
        AND    gestcorr.elem_id=fase.elem_prov_id
        AND    gest.elem_id=fase.elem_id
        AND    fase.ente_proprietario_id=enteproprietarioid
        AND    fase.bil_id=bilancioid
        AND    fase.fase_bil_elab_id=fasebilelabid
        AND    fase.data_cancellazione IS NULL
        AND    fase.elem_id IS NOT NULL       -- gestione equivalente anno prec esistente
        AND    fase.elem_prov_id IS NOT NULL  -- gestione equivalente corrente esistente
        AND    fase.elem_prov_new_id IS NULL; -- non inserito come nuova gestione corrente
        codresult:=NULL;
        INSERT INTO fase_bil_t_elaborazione_log
                    (
                                fase_bil_elab_id,
                                fase_bil_elab_log_operazione,
                                validita_inizio,
                                login_operazione,
                                ente_proprietario_id
                    )
                    VALUES
                    (
                                fasebilelabid,
                                strmessaggio,
                                clock_timestamp(),
                                loginoperazione,
                                enteproprietarioid
                    )
        returning   fase_bil_elab_log_id
        INTO        codresult;

        IF codresult IS NULL THEN
          RAISE
        EXCEPTION
          ' Errore in inserimento LOG.';
        END IF;
        codresult:=NULL;
        strmessaggio:='Inizio inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente.';
        INSERT INTO fase_bil_t_elaborazione_log
                    (
                                fase_bil_elab_id,
                                fase_bil_elab_log_operazione,
                                validita_inizio,
                                login_operazione,
                                ente_proprietario_id
                    )
                    VALUES
                    (
                                fasebilelabid,
                                strmessaggio,
                                clock_timestamp(),
                                loginoperazione,
                                enteproprietarioid
                    )
        returning   fase_bil_elab_log_id
        INTO        codresult;

        IF codresult IS NULL THEN
          RAISE
        EXCEPTION
          ' Errore in inserimento LOG.';
        END IF;
        -- update relazioni esistenti
        -- siac_r_bil_elem_stato
        /* strMessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_stato].';
insert into siac_r_bil_elem_stato
(elem_id,elem_stato_id,validita_inizio,ente_proprietario_id,login_operazione)
(select fase.elem_prov_id, stato.elem_stato_id , dataInizioVal, stato.ente_proprietario_id, loginOperazione
from siac_r_bil_elem_stato stato, fase_bil_t_gest_apertura_provv fase
where stato.elem_id=fase.elem_id
and   fase.ente_proprietario_id=enteProprietarioid
and   fase.bil_id=bilancioId
and   fase.fase_bil_elab_id=faseBilElabId
and   fase.data_cancellazione is null
and   fase.elem_id is not null
and   fase.elem_prov_id is not null
and   fase.elem_prov_new_id is null
and   stato.data_cancellazione is null
and   stato.validita_fine is null);*/
        -- siac_r_bil_elem_stato
        strmessaggio:='Aggiornamento strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_stato].';
        UPDATE siac_r_bil_elem_stato stato
        SET    elem_stato_id=stato.elem_stato_id,
               data_modifica=now(),
               login_operazione=loginoperazione
        FROM   fase_bil_t_gest_apertura_provv fase,
               siac_r_bil_elem_stato statonew
        WHERE  stato.elem_id=fase.elem_prov_id
        AND    statonew.elem_id=fase.elem_id
        AND    fase.ente_proprietario_id=enteproprietarioid
        AND    fase.bil_id=bilancioid
        AND    fase.fase_bil_elab_id=fasebilelabid
        AND    fase.data_cancellazione IS NULL
        AND    fase.elem_id IS NOT NULL
        AND    fase.elem_prov_id IS NOT NULL
        AND    fase.elem_prov_new_id IS NULL
        AND    stato.data_cancellazione IS NULL
        AND    stato.validita_fine IS NULL
        AND    statonew.data_cancellazione IS NULL
        AND    statonew.validita_fine IS NULL;

        -- siac_r_bil_elem_attr
        strmessaggio:='Cancellazione per nuovo inserimento strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_attr].';
        DELETE
        FROM   siac_r_bil_elem_attr attr
        USING  fase_bil_t_gest_apertura_provv fase
        WHERE  attr.elem_id=fase.elem_prov_id
        AND    fase.ente_proprietario_id=enteproprietarioid
        AND    fase.bil_id=bilancioid
        AND    fase.fase_bil_elab_id=fasebilelabid
        AND    fase.data_cancellazione IS NULL
        AND    fase.elem_id IS NOT NULL
        AND    fase.elem_prov_id IS NOT NULL
        AND    fase.elem_prov_new_id IS NULL
        AND    attr.data_cancellazione IS NULL
        AND    attr.validita_fine IS NULL;

        strmessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_attr].';
        INSERT INTO siac_r_bil_elem_attr
                    (
                                elem_id,
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
                           SELECT fase.elem_prov_id,
                                  attr.attr_id ,
                                  attr.tabella_id,
                                  attr.BOOLEAN,
                                  attr.percentuale,
                                  attr.testo,
                                  attr.numerico,
                                  datainizioval,
                                  attr.ente_proprietario_id,
                                  loginoperazione
                           FROM   siac_r_bil_elem_attr attr,
                                  fase_bil_t_gest_apertura_provv fase
                           WHERE  attr.elem_id=fase.elem_id
                           AND    fase.ente_proprietario_id=enteproprietarioid
                           AND    fase.bil_id=bilancioid
                           AND    fase.fase_bil_elab_id=fasebilelabid
                           AND    fase.data_cancellazione IS NULL
                           AND    fase.elem_id IS NOT NULL
                           AND    fase.elem_prov_id IS NOT NULL
                           AND    fase.elem_prov_new_id IS NULL
                           AND    attr.data_cancellazione IS NULL
                           AND    attr.validita_fine IS NULL);

        -- siac_r_bil_elem_categoria
        strmessaggio:='Cancellazione per nuovo inserimento strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_categoria].';
        DELETE
        FROM   siac_r_bil_elem_categoria cat
        USING  fase_bil_t_gest_apertura_provv fase
        WHERE  cat.elem_id=fase.elem_prov_id
        AND    fase.ente_proprietario_id=enteproprietarioid
        AND    fase.bil_id=bilancioid
        AND    fase.fase_bil_elab_id=fasebilelabid
        AND    fase.data_cancellazione IS NULL
        AND    fase.elem_id IS NOT NULL
        AND    fase.elem_prov_id IS NOT NULL
        AND    fase.elem_prov_new_id IS NULL
        AND    cat.data_cancellazione IS NULL
        AND    cat.validita_fine IS NULL;

        strmessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_categoria].';
        INSERT INTO siac_r_bil_elem_categoria
                    (
                                elem_id,
                                elem_cat_id,
                                validita_inizio,
                                ente_proprietario_id,
                                login_operazione
                    )
                    (
                           SELECT fase.elem_prov_id,
                                  cat.elem_cat_id ,
                                  datainizioval,
                                  cat.ente_proprietario_id,
                                  loginoperazione
                           FROM   siac_r_bil_elem_categoria cat,
                                  fase_bil_t_gest_apertura_provv fase
                           WHERE  cat.elem_id=fase.elem_id
                           AND    fase.ente_proprietario_id=enteproprietarioid
                           AND    fase.bil_id=bilancioid
                           AND    fase.fase_bil_elab_id=fasebilelabid
                           AND    fase.data_cancellazione IS NULL
                           AND    fase.elem_id IS NOT NULL
                           AND    fase.elem_prov_id IS NOT NULL
                           AND    fase.elem_prov_new_id IS NULL
                           AND    cat.data_cancellazione IS NULL
                           AND    cat.validita_fine IS NULL);

        -- siac_r_bil_elem_class
        strmessaggio:='Cancellazione per nuovo inserimento strutture provvisorio esistenti da gestione equivalente anno precedente [fase_bil_t_gest_apertura_provv].';
        DELETE
        FROM   siac_r_bil_elem_class class
        USING  fase_bil_t_gest_apertura_provv fase
        WHERE  class.elem_id=fase.elem_prov_id
        AND    fase.ente_proprietario_id=enteproprietarioid
        AND    fase.bil_id=bilancioid
        AND    fase.fase_bil_elab_id=fasebilelabid
        AND    fase.data_cancellazione IS NULL
        AND    fase.elem_id IS NOT NULL
        AND    fase.elem_prov_id IS NOT NULL
        AND    fase.elem_prov_new_id IS NULL
        AND    class.data_cancellazione IS NULL
        AND    class.validita_fine IS NULL;

        strmessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].';
        /*
insert into siac_r_bil_elem_class
(elem_id,classif_id,validita_inizio,ente_proprietario_id,login_operazione)
(select fase.elem_prov_id, class.classif_id , dataInizioVal, class.ente_proprietario_id, loginOperazione
from siac_r_bil_elem_class class, fase_bil_t_gest_apertura_provv fase,siac_t_class c
where class.elem_id=fase.elem_id
and   fase.ente_proprietario_id=enteProprietarioid
and   fase.bil_id=bilancioId
and   fase.fase_bil_elab_id=faseBilElabId
and   fase.data_cancellazione is null
and   fase.elem_id is not null
and   fase.elem_prov_id is not null
and   fase.elem_prov_new_id is null
and   class.data_cancellazione is null
and   class.validita_fine is null;
*/
        -- JIRA-SIAC-4167 14.11.2016
        INSERT INTO siac_r_bil_elem_class
                    (
                                elem_id,
                                classif_id,
                                validita_inizio,
                                ente_proprietario_id,
                                login_operazione
                    )
                    (
                           SELECT fase.elem_prov_id,
                                  class.classif_id ,
                                  datainizioval,
                                  class.ente_proprietario_id,
                                  loginoperazione
                           FROM   siac_r_bil_elem_class class,
                                  fase_bil_t_gest_apertura_provv fase,
                                  siac_t_class c
                           WHERE  class.elem_id=fase.elem_id
                           AND    fase.ente_proprietario_id=enteproprietarioid
                           AND    fase.bil_id=bilancioid
                           AND    fase.fase_bil_elab_id=fasebilelabid
                           AND    fase.data_cancellazione IS NULL
                           AND    fase.elem_id IS NOT NULL
                           AND    fase.elem_prov_id IS NOT NULL
                           AND    fase.elem_prov_new_id IS NULL
                           AND    class.data_cancellazione IS NULL
                           AND    class.validita_fine IS NULL
                           AND    c.classif_id=class.classif_id
                           AND    c.data_cancellazione IS NULL
                           AND    date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                           AND    ( date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine) OR     c.validita_fine IS NULL));


    	-- 22.11.2017 Sofia - siac-5297
        strmessaggio:='Inserimento nuove strutture previsione esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Classificazioni equivalenti anno nuovo.';
		INSERT INTO siac_r_bil_elem_class
                    (
                                elem_id,
                                classif_id,
                                validita_inizio,
                                ente_proprietario_id,
                                login_operazione
                    )
                    (
                           SELECT --fase.elem_prev_id,
                                  fase.elem_prov_id,
                                  cnew.classif_id ,
                                  datainizioval,
                                  class.ente_proprietario_id,
                                  loginoperazione
                           FROM   siac_r_bil_elem_class class,
                                  fase_bil_t_gest_apertura_provv fase,
                                  siac_t_class c, siac_t_class cnew
                           WHERE  class.elem_id=fase.elem_id
                           AND    fase.ente_proprietario_id=enteproprietarioid
                           AND    fase.bil_id=bilancioid
                           AND    fase.fase_bil_elab_id=fasebilelabid
                           AND    c.classif_id=class.classif_id
                           and    cnew.ente_proprietario_id=c.ente_proprietario_id
                           and    cnew.classif_tipo_id=c.classif_tipo_id
                           and    cnew.classif_code=c.classif_code
                           AND    fase.data_cancellazione IS NULL
                           AND    fase.elem_prov_id IS NOT NULL
                           AND    fase.elem_prov_new_id IS NULL
                         -- AND    fase.elem_gest_id IS NOT NULL
                         --  AND    fase.elem_prev_id IS NOT NULL
                           AND    class.data_cancellazione IS NULL
                           AND    class.validita_fine IS NULL
                           AND    c.data_cancellazione IS NULL
                           and    date_trunc('day',v_dataprimogiornoanno)>date_trunc('day',c.validita_fine)
						   and    cnew.data_cancellazione is null
          				   and    date_trunc('day',v_dataprimogiornoanno)<=date_trunc('day',cnew.validita_inizio)
				           AND    (date_trunc('day',v_dataprimogiornoanno) < date_trunc('day',cnew.validita_fine)or cnew.validita_fine IS NULL)
                           and    not exists
                           (
                           select 1
                           from siac_r_bil_elem_class r1,siac_t_class c1
                           where r1.elem_id=fase.elem_prov_id
                           and   c1.classif_id=r1.classif_id
                           and   c1.classif_tipo_id=c.classif_tipo_id
                           and   r1.data_cancellazione  is null
                           and   r1.validita_fine is null
                           )
           			 );


        /* SIAC-5590
-- inserimento nuove relazioni
-- siac_r_vincolo_bil_elem
strMessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_vincolo_bil_elem].';
insert into siac_r_vincolo_bil_elem
( elem_id,vincolo_id, validita_inizio,ente_proprietario_id,login_operazione)
(select fase.elem_prov_id, v.vincolo_id, dataInizioVal,v.ente_proprietario_id, loginOperazione
from siac_r_vincolo_bil_elem v,fase_bil_t_gest_apertura_provv fase
where v.elem_id=fase.elem_id
and   fase.ente_proprietario_id=enteProprietarioid
and   fase.bil_id=bilancioId
and   fase.fase_bil_elab_id=faseBilElabId
and   fase.data_cancellazione is null
and   fase.elem_id is not null
and   fase.elem_prov_id is not null
and   fase.elem_prov_new_id is null
and   v.data_cancellazione is null
and   v.validita_fine is null
);
*/
        -- siac_r_bil_elem_atto_legge
        strmessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_atto_legge].';
        INSERT INTO siac_r_bil_elem_atto_legge
                    (
                                elem_id,
                                attolegge_id,
                                descrizione,
                                gerarchia,
                                finanziamento_inizio,
                                finanziamento_fine,
                                validita_inizio,
                                ente_proprietario_id,
                                login_operazione
                    )
                    (
                           SELECT fase.elem_prov_id,
                                  v.attolegge_id,
                                  v.descrizione,
                                  v.gerarchia,
                                  v.finanziamento_inizio,
                                  v.finanziamento_fine,
                                  datainizioval,
                                  v.ente_proprietario_id,
                                  loginoperazione
                           FROM   siac_r_bil_elem_atto_legge v,
                                  fase_bil_t_gest_apertura_provv fase
                           WHERE  v.elem_id=fase.elem_id
                           AND    fase.ente_proprietario_id=enteproprietarioid
                           AND    fase.bil_id=bilancioid
                           AND    fase.elem_id IS NOT NULL
                           AND    fase.elem_prov_id IS NOT NULL
                           AND    fase.elem_prov_new_id IS NULL
                           AND    v.data_cancellazione IS NULL
                           AND    v.validita_fine IS NULL );

        -- siac_r_bil_elem_rel_tempo
        strmessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_rel_tempo].';
        INSERT INTO siac_r_bil_elem_rel_tempo
                    (
                                elem_id,
                                elem_id_old,
                                validita_inizio,
                                ente_proprietario_id,
                                login_operazione
                    )
                    (
                           SELECT fase.elem_prov_id,
                                  v.elem_id_old,
                                  datainizioval,
                                  v.ente_proprietario_id,
                                  loginoperazione
                           FROM   siac_r_bil_elem_rel_tempo v,
                                  fase_bil_t_gest_apertura_provv fase
                           WHERE  v.elem_id=fase.elem_id
                           AND    fase.ente_proprietario_id=enteproprietarioid
                           AND    fase.bil_id=bilancioid
                           AND    fase.fase_bil_elab_id=fasebilelabid
                           AND    fase.data_cancellazione IS NULL
                           AND    fase.elem_id IS NOT NULL
                           AND    fase.elem_prov_id IS NOT NULL
                           AND    fase.elem_prov_new_id IS NULL
                           AND    v.data_cancellazione IS NULL
                           AND    v.validita_fine IS NULL );

        codresult:=NULL;
        strmessaggio:='Fine inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente.';
        INSERT INTO fase_bil_t_elaborazione_log
                    (
                                fase_bil_elab_id,
                                fase_bil_elab_log_operazione,
                                validita_inizio,
                                login_operazione,
                                ente_proprietario_id
                    )
                    VALUES
                    (
                                fasebilelabid,
                                strmessaggio,
                                clock_timestamp(),
                                loginoperazione,
                                enteproprietarioid
                    )
        returning   fase_bil_elab_log_id
        INTO        codresult;

        IF codresult IS NULL THEN
          RAISE
        EXCEPTION
          ' Errore in inserimento LOG.';
        END IF;
        -- verifica dati inseriti
        codresult:=NULL;
        strmessaggio:='Inizio verifica inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente.';
        INSERT INTO fase_bil_t_elaborazione_log
                    (
                                fase_bil_elab_id,
                                fase_bil_elab_log_operazione,
                                validita_inizio,
                                login_operazione,
                                ente_proprietario_id
                    )
                    VALUES
                    (
                                fasebilelabid,
                                strmessaggio,
                                clock_timestamp(),
                                loginoperazione,
                                enteproprietarioid
                    )
        returning   fase_bil_elab_log_id
        INTO        codresult;

        IF codresult IS NULL THEN
          RAISE
        EXCEPTION
          ' Errore in inserimento LOG.';
        END IF;
        codresult:=NULL;
        strmessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_stato].Verifica esistenza relazione stati.';
        SELECT   1
        INTO     codresult
        FROM     fase_bil_t_gest_apertura_provv fase
        WHERE    fase.ente_proprietario_id=enteproprietarioid
        AND      fase.bil_id=bilancioid
        AND      fase.fase_bil_elab_id=fasebilelabid
        AND      fase.elem_id IS NOT NULL
        AND      fase.elem_prov_id IS NOT NULL
        AND      fase.elem_prov_new_id IS NULL
        AND      fase.data_cancellazione IS NULL
        AND      NOT EXISTS
                 (
                          SELECT   1
                          FROM     siac_r_bil_elem_stato stato
                          WHERE    stato.elem_id=fase.elem_prov_id
                          AND      stato.data_cancellazione IS NULL
                          AND      stato.validita_fine IS NULL
                          ORDER BY stato.elem_id limit 1)
        ORDER BY fase.fase_bil_gest_ape_prov_id limit 1;

        IF codresult IS NOT NULL THEN
          RAISE
        EXCEPTION
          ' Elementi di bilancio assenti di relazione.';
        END IF;
        codresult:=NULL;
        strmessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_attr].Verifica esistenza attributi.';
        SELECT   1
        INTO     codresult
        FROM     fase_bil_t_gest_apertura_provv fase
        WHERE    fase.ente_proprietario_id=enteproprietarioid
        AND      fase.bil_id=bilancioid
        AND      fase.fase_bil_elab_id=fasebilelabid
        AND      fase.elem_id IS NOT NULL
        AND      fase.elem_prov_id IS NOT NULL
        AND      fase.elem_prov_new_id IS NULL
        AND      fase.data_cancellazione IS NULL
        AND      NOT EXISTS
                 (
                          SELECT   1
                          FROM     siac_r_bil_elem_attr attr
                          WHERE    attr.elem_id=fase.elem_prov_id
                          AND      attr.data_cancellazione IS NULL
                          AND      attr.validita_fine IS NULL
                          ORDER BY attr.elem_id limit 1)
        ORDER BY fase.fase_bil_gest_ape_prov_id limit 1;

        IF codresult IS NOT NULL THEN
          RAISE
        EXCEPTION
          ' Elementi di bilancio assenti di relazione.';
        END IF;
        --ANTO JIRA-SIAC-4167
        codresult:=NULL;
        strmessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni classificatori.';
        SELECT   1
        INTO     codresult
        FROM     fase_bil_t_gest_apertura_provv fase
        WHERE    fase.ente_proprietario_id=enteproprietarioid
        AND      fase.bil_id=bilancioid
        AND      fase.fase_bil_elab_id=fasebilelabid
        AND      fase.elem_id IS NOT NULL
        AND      fase.elem_prov_id IS NOT NULL
        AND      fase.elem_prov_new_id IS NULL
        AND      fase.data_cancellazione IS NULL
        AND      NOT EXISTS
                 (
                          SELECT   1
                          FROM     siac_r_bil_elem_class class,
                                   siac_t_class c
                          WHERE    class.elem_id=fase.elem_prov_id
                          AND      class.data_cancellazione IS NULL
                          AND      class.validita_fine IS NULL
                          AND      c.classif_id=class.classif_id
                          AND      c.data_cancellazione IS NULL
                          AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                          AND      (
                                            date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                   OR       c.validita_fine IS NULL)
                          ORDER BY class.elem_id limit 1)
        ORDER BY fase.fase_bil_gest_ape_prov_id limit 1;

        IF codresult IS NOT NULL THEN
          RAISE
        EXCEPTION
          ' Elementi di bilancio assenti di relazione.';
        END IF;
        codresult:=NULL;
        strmessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_categoria].Verifica esistenza relazioni categoria.';
        SELECT DISTINCT 1
        INTO            codresult
        FROM            fase_bil_t_gest_apertura_provv fase
        WHERE           fase.ente_proprietario_id=enteproprietarioid
        AND             fase.bil_id=bilancioid
        AND             fase.fase_bil_elab_id=fasebilelabid
        AND             fase.elem_id IS NOT NULL
        AND             fase.elem_prov_id IS NOT NULL
        AND             fase.elem_prov_new_id IS NULL
        AND             fase.data_cancellazione IS NULL
        AND             NOT EXISTS
                        (
                               SELECT 1
                               FROM   siac_r_bil_elem_categoria class
                               WHERE  class.elem_id=fase.elem_prov_id
                               AND    class.data_cancellazione IS NULL
                               AND    class.validita_fine IS NULL) limit 1;

        IF codresult IS NOT NULL THEN
          RAISE
        EXCEPTION
          ' Elementi di bilancio assenti di relazione.';
        END IF;
        -- verifica se esistono elementi senza classificatori obbligatori (**)
        -- controlli sui classificatori obbligatori
        -- CL_CDC, CL_CDR
        codresult:=NULL;
        strmessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni struttura amministrativa.';
        SELECT   1
        INTO     codresult
        FROM     fase_bil_t_gest_apertura_provv fase
        WHERE    fase.ente_proprietario_id=enteproprietarioid
        AND      fase.elem_id IS NOT NULL
        AND      fase.elem_prov_id IS NOT NULL
        AND      fase.elem_prov_new_id IS NULL
        AND      fase.bil_id=bilancioid
        AND      fase.fase_bil_elab_id=fasebilelabid
        AND      fase.data_cancellazione IS NULL
        AND      NOT EXISTS
                 (
                          SELECT   1
                          FROM     siac_r_bil_elem_class class ,
                                   siac_t_class c
                          WHERE    class.elem_id=fase.elem_prov_id
                          AND      c.classif_id=class.classif_id
                          AND      c.classif_tipo_id IN (cdctipoid,
                                                         cdrtipoid)
                          AND      class.data_cancellazione IS NULL
                          AND      class.validita_fine IS NULL
                          AND      c.data_cancellazione IS NULL
                          AND      c.validita_fine IS NULL
                                   --ANTO JIRA-SIAC-4167
                          AND      c.data_cancellazione IS NULL
                          /*siac-5297
                          AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                          AND      (
                                            date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                   OR       c.validita_fine IS NULL)
                          */
                          ORDER BY class.elem_id limit 1)
        ORDER BY fase.fase_bil_gest_ape_prov_id limit 1;


        --12.12.2016 JIRA-SIAC-4167
        IF codresult IS NOT NULL THEN
          codresult:=NULL;
          strmessaggio:=strmessaggio
          ||' Inserimento segnalazione mancanza classif.';
          INSERT INTO fase_bil_t_prev_apertura_segnala
                      (
                                  elem_id,
                                  elem_code,
                                  elem_code2,
                                  elem_code3,
                                  bil_id,
                                  fase_bil_elab_id,
                                  segnala_codice,
                                  segnala_desc,
                                  validita_inizio,
                                  ente_proprietario_id,
                                  login_operazione
                      )
                      (
                             SELECT fase.elem_prov_id,
                                    fase.elem_code,
                                    fase.elem_code2,
                                    fase.elem_code3,
                                    fase.bil_id,
                                    fasebilelabid,
                                    'SAC',
                                    'SAC'
                                           ||' mancante',
                                    datainizioval,
                                    fase.ente_proprietario_id,
                                    loginoperazione
                             FROM   fase_bil_t_gest_apertura_provv fase
                             WHERE  fase.ente_proprietario_id=enteproprietarioid
                             AND    fase.elem_id IS NOT NULL
                             AND    fase.elem_prov_id IS NOT NULL
                             AND    fase.elem_prov_new_id IS NULL
                             AND    fase.bil_id=bilancioid
                             AND    fase.fase_bil_elab_id=fasebilelabid
                             AND    fase.data_cancellazione IS NULL
                             AND    NOT EXISTS
                                    (
                                             SELECT   1
                                             FROM     siac_r_bil_elem_class class ,
                                                      siac_t_class c
                                             WHERE    class.elem_id=fase.elem_prov_id
                                             AND      c.classif_id=class.classif_id
                                             AND      c.classif_tipo_id IN (cdctipoid,
                                                                            cdrtipoid)
                                             AND      class.data_cancellazione IS NULL
                                             AND      class.validita_fine IS NULL
                                             AND      c.data_cancellazione IS NULL
                                             /*siac-5297
                                             AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                             AND      (date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)OR       c.validita_fine IS NULL)
                                             */
                                             ORDER BY class.elem_id limit 1) );

        END IF;
        -- CL_PDC_FIN_QUINTO, CL_PDC_FIN_QUARTO
        codresult:=NULL;
        strmessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni '
        ||cl_pdc_fin_quarto
        ||' '
        ||cl_pdc_fin_quinto
        ||'.';
        -- Il classificatore deve essere obbligatoriamente presente solo se capitolo gestione STD
        SELECT   1
        INTO     codresult
        FROM     fase_bil_t_gest_apertura_provv fase ,
                 siac_r_bil_elem_categoria rcat ,
                 siac_d_bil_elem_categoria cat
        WHERE    fase.ente_proprietario_id=enteproprietarioid
        AND      fase.bil_id=bilancioid
        AND      fase.fase_bil_elab_id=fasebilelabid
        AND      fase.elem_id IS NOT NULL
        AND      fase.elem_prov_id IS NOT NULL
        AND      fase.elem_prov_new_id IS NULL
        AND      fase.data_cancellazione IS NULL
        AND      rcat.elem_id=fase.elem_prov_id
        AND      rcat.data_cancellazione IS NULL
        AND      rcat.validita_fine IS NULL
        AND      rcat.elem_cat_id=cat.elem_cat_id
        AND      cat.elem_cat_code = categoria_std
        AND      NOT EXISTS
                 (
                          SELECT   1
                          FROM     siac_r_bil_elem_class class ,
                                   siac_t_class c
                          WHERE    class.elem_id=fase.elem_prov_id
                          AND      c.classif_id=class.classif_id
                          AND      c.classif_tipo_id IN (pdcfinivid,
                                                         pdcfinvid)
                          AND      class.data_cancellazione IS NULL
                          AND      class.validita_fine IS NULL
                          AND      c.data_cancellazione IS NULL
                                   --ANTO JIRA-SIAC-4167
                          AND      c.validita_fine IS NULL
                          /*siac-5297
                          AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                          AND      (
                                            date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                   OR       c.validita_fine IS NULL)
                                   */
                          ORDER BY class.elem_id limit 1)
        ORDER BY fase.fase_bil_gest_ape_prov_id limit 1;


        IF codresult IS NOT NULL THEN
          codresult:=NULL;
          strmessaggio:=strmessaggio
          ||' Inserimento segnalazione mancanza classif.';
          INSERT INTO fase_bil_t_prev_apertura_segnala
                      (
                                  elem_id,
                                  elem_code,
                                  elem_code2,
                                  elem_code3,
                                  bil_id,
                                  fase_bil_elab_id,
                                  segnala_codice,
                                  segnala_desc,
                                  validita_inizio,
                                  ente_proprietario_id,
                                  login_operazione
                      )
                      (
                             SELECT fase.elem_prov_id,
                                    fase.elem_code,
                                    fase.elem_code2,
                                    fase.elem_code3,
                                    fase.bil_id,
                                    fasebilelabid,
                                    'PDCFIN',
                                    'PDCFIN'
                                           ||' mancante',
                                    datainizioval,
                                    fase.ente_proprietario_id,
                                    loginoperazione
                             FROM   fase_bil_t_gest_apertura_provv fase ,
                                    siac_r_bil_elem_categoria rcat,
                                    siac_d_bil_elem_categoria cat
                             WHERE  fase.ente_proprietario_id=enteproprietarioid
                             AND    fase.bil_id=bilancioid
                             AND    fase.fase_bil_elab_id=fasebilelabid
                             AND    fase.elem_id IS NOT NULL
                             AND    fase.elem_prov_id IS NOT NULL
                             AND    fase.elem_prov_new_id IS NULL
                             AND    fase.data_cancellazione IS NULL
                             AND    rcat.elem_id=fase.elem_prov_id
                             AND    rcat.data_cancellazione IS NULL
                             AND    rcat.validita_fine IS NULL
                             AND    rcat.elem_cat_id=cat.elem_cat_id
                             AND    cat.elem_cat_code = categoria_std
                             AND    NOT EXISTS
                                    (
                                             SELECT   1
                                             FROM     siac_r_bil_elem_class class ,
                                                      siac_t_class c
                                             WHERE    class.elem_id=fase.elem_prov_id
                                             AND      c.classif_id=class.classif_id
                                             AND      c.classif_tipo_id IN (pdcfinivid,
                                                                            pdcfinvid)
                                             AND      class.data_cancellazione IS NULL
                                             AND      class.validita_fine IS NULL
                                             AND      c.data_cancellazione IS NULL
                                             /*siac-5297
                                             AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                             AND      (
                                                               date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                      OR       c.validita_fine IS NULL)
                                             */
                                             ORDER BY class.elem_id limit 1) );

        END IF;

        codresult:=NULL;
        strmessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_atto_legge].Verifica esistenza relazioni atti di legge.';
        SELECT   1
        INTO     codresult
        FROM     fase_bil_t_gest_apertura_provv fase,
                 siac_r_bil_elem_atto_legge v
        WHERE    fase.ente_proprietario_id=enteproprietarioid
        AND      v.elem_id=fase.elem_id
        AND      fase.bil_id=bilancioid
        AND      fase.fase_bil_elab_id=fasebilelabid
        AND      fase.elem_id IS NOT NULL
        AND      fase.elem_prov_id IS NOT NULL
        AND      fase.elem_prov_new_id IS NULL
        AND      fase.data_cancellazione IS NULL
        AND      v.data_cancellazione IS NULL
        AND      v.validita_fine IS NULL
        AND      NOT EXISTS
                 (
                          SELECT   1
                          FROM     siac_r_bil_elem_atto_legge class
                          WHERE    class.elem_id=fase.elem_prov_id
                          AND      class.data_cancellazione IS NULL
                          AND      class.validita_fine IS NULL
                          ORDER BY class.elem_id limit 1)
        ORDER BY fase.fase_bil_gest_ape_prov_id limit 1;

        IF codresult IS NOT NULL THEN
          RAISE
        EXCEPTION
          ' Elementi di bilancio assenti di relazione.';
        END IF;
        codresult:=NULL;
        strmessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_rel_tempo].Verifica esistenza relazioni.';
        SELECT   1
        INTO     codresult
        FROM     fase_bil_t_gest_apertura_provv fase,
                 siac_r_bil_elem_rel_tempo v
        WHERE    fase.ente_proprietario_id=enteproprietarioid
        AND      v.elem_id=fase.elem_id
        AND      fase.bil_id=bilancioid
        AND      fase.fase_bil_elab_id=fasebilelabid
        AND      fase.elem_id IS NOT NULL
        AND      fase.elem_prov_id IS NOT NULL
        AND      fase.elem_prov_new_id IS NULL
        AND      fase.data_cancellazione IS NULL
        AND      v.data_cancellazione IS NULL
        AND      v.validita_fine IS NULL
        AND      NOT EXISTS
                 (
                          SELECT   1
                          FROM     siac_r_bil_elem_rel_tempo class
                          WHERE    class.elem_id=fase.elem_prov_id
                          AND      class.data_cancellazione IS NULL
                          AND      class.validita_fine IS NULL
                          ORDER BY class.elem_id limit 1)
        ORDER BY fase.fase_bil_gest_ape_prov_id limit 1;

        IF codresult IS NOT NULL THEN
          RAISE
        EXCEPTION
          ' Elementi di bilancio assenti di relazione.';
        END IF;
        IF euelemtipo=tipo_elem_eu THEN
          -- Classificatore necessario solo per capitolo di categoria STD
          -- CL_PROGRAMMA
          codresult:=NULL;
          strmessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni '
          ||cl_programma
          ||'.';
          SELECT 1
          INTO   codresult
          FROM   fase_bil_t_gest_apertura_provv fase,
                 siac_r_bil_elem_categoria rcat,
                 siac_d_bil_elem_categoria cat
          WHERE  fase.ente_proprietario_id=enteproprietarioid
          AND    fase.bil_id=bilancioid
          AND    fase.fase_bil_elab_id=fasebilelabid
          AND    fase.elem_id IS NOT NULL
          AND    fase.elem_prov_id IS NOT NULL
          AND    fase.elem_prov_new_id IS NULL
          AND    fase.data_cancellazione IS NULL
          AND    rcat.elem_id=fase.elem_prov_id
          AND    rcat.data_cancellazione IS NULL
          AND    rcat.validita_fine IS NULL
          AND    rcat.elem_cat_id=cat.elem_cat_id
          AND    cat.elem_cat_code = categoria_std
          AND    NOT EXISTS
                 (
                        SELECT 1
                        FROM   siac_r_bil_elem_class class ,
                               siac_t_class c
                        WHERE  class.elem_id=fase.elem_prov_id
                        AND    c.classif_id=class.classif_id
                        AND    c.classif_tipo_id=programmatipoid
                        AND    class.data_cancellazione IS NULL
                        AND    class.validita_fine IS NULL
                        AND    c.data_cancellazione IS NULL
                        AND    c.validita_fine IS NULL
                               /*siac-5297
                        AND    date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                        AND    (
                                      date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                               OR     c.validita_fine IS NULL) limit 1*/
                        ) limit 1;


          IF codresult IS NOT NULL THEN
            strmessaggio:=strmessaggio
            ||' Inserimento segnalazione mancanza classif.';
            INSERT INTO fase_bil_t_prev_apertura_segnala
                        (
                                    elem_id,
                                    elem_code,
                                    elem_code2,
                                    elem_code3,
                                    bil_id,
                                    fase_bil_elab_id,
                                    segnala_codice,
                                    segnala_desc,
                                    validita_inizio,
                                    ente_proprietario_id,
                                    login_operazione
                        )
                        (
                               SELECT fase.elem_prov_id,
                                      fase.elem_code,
                                      fase.elem_code2,
                                      fase.elem_code3,
                                      fase.bil_id,
                                      fasebilelabid,
                                      cl_programma,
                                      cl_programma
                                             ||' mancante',
                                      datainizioval,
                                      fase.ente_proprietario_id,
                                      loginoperazione
                               FROM   fase_bil_t_gest_apertura_provv fase,
                                      siac_r_bil_elem_categoria rcat,
                                      siac_d_bil_elem_categoria cat
                               WHERE  fase.ente_proprietario_id=enteproprietarioid
                               AND    fase.bil_id=bilancioid
                               AND    fase.fase_bil_elab_id=fasebilelabid
                               AND    fase.elem_id IS NOT NULL
                               AND    fase.elem_prov_id IS NOT NULL
                               AND    fase.elem_prov_new_id IS NULL
                               AND    fase.data_cancellazione IS NULL
                               AND    rcat.elem_id=fase.elem_prov_id
                               AND    rcat.data_cancellazione IS NULL
                               AND    rcat.validita_fine IS NULL
                               AND    rcat.elem_cat_id=cat.elem_cat_id
                               AND    cat.elem_cat_code = categoria_std
                               AND    NOT EXISTS
                                      (
                                               SELECT   1
                                               FROM     siac_r_bil_elem_class class ,
                                                        siac_t_class c
                                               WHERE    class.elem_id=fase.elem_prov_id
                                               AND      c.classif_id=class.classif_id
                                               AND      c.classif_tipo_id =programmatipoid
                                               AND      class.data_cancellazione IS NULL
                                               AND      class.validita_fine IS NULL
                                               AND      c.data_cancellazione IS NULL
                                               /*siac-5297
                                               AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                               AND      (
                                                                 date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                        OR       c.validita_fine IS NULL)*/
                                               ORDER BY class.elem_id limit 1) );

          END IF;
          -- Classificatore necessario solo per capitolo di categoria STD
          -- CL_MACROAGGREGATO
          codresult:=NULL;
          strmessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni '
          ||cl_macroaggregato
          ||'.';
          SELECT   1
          INTO     codresult
          FROM     fase_bil_t_gest_apertura_provv fase ,
                   siac_r_bil_elem_categoria rcat ,
                   siac_d_bil_elem_categoria cat
          WHERE    fase.ente_proprietario_id=enteproprietarioid
          AND      fase.bil_id=bilancioid
          AND      fase.fase_bil_elab_id=fasebilelabid
          AND      fase.elem_id IS NOT NULL
          AND      fase.elem_prov_id IS NOT NULL
          AND      fase.elem_prov_new_id IS NULL
          AND      fase.data_cancellazione IS NULL
          AND      rcat.elem_id=fase.elem_prov_id
          AND      rcat.data_cancellazione IS NULL
          AND      rcat.validita_fine IS NULL
          AND      rcat.elem_cat_id=cat.elem_cat_id
          AND      cat.elem_cat_code = categoria_std
          AND      NOT EXISTS
                   (
                            SELECT   1
                            FROM     siac_r_bil_elem_class class ,
                                     siac_t_class c
                            WHERE    class.elem_id=fase.elem_prov_id
                            AND      c.classif_tipo_id=macroaggrtipoid
                            AND      class.data_cancellazione IS NULL
                            AND      class.validita_fine IS NULL
                            AND      c.data_cancellazione IS NULL
                            AND      c.validita_fine IS NULL
                            ORDER BY class.elem_id limit 1)
          ORDER BY fase.fase_bil_gest_ape_prov_id limit 1;


          IF codresult IS NOT NULL THEN
            strmessaggio:=strmessaggio
            ||' Inserimento segnalazione mancanza classif.';
            INSERT INTO fase_bil_t_prev_apertura_segnala
                        (
                                    elem_id,
                                    elem_code,
                                    elem_code2,
                                    elem_code3,
                                    bil_id,
                                    fase_bil_elab_id,
                                    segnala_codice,
                                    segnala_desc,
                                    validita_inizio,
                                    ente_proprietario_id,
                                    login_operazione
                        )
                        (
                               SELECT fase.elem_prov_id,
                                      fase.elem_code,
                                      fase.elem_code2,
                                      fase.elem_code3,
                                      fase.bil_id,
                                      fasebilelabid,
                                      cl_macroaggregato,
                                      cl_macroaggregato
                                             ||' mancante',
                                      datainizioval,
                                      fase.ente_proprietario_id,
                                      loginoperazione
                               FROM   fase_bil_t_gest_apertura_provv fase,
                                      siac_r_bil_elem_categoria rcat,
                                      siac_d_bil_elem_categoria cat
                               WHERE  fase.ente_proprietario_id=enteproprietarioid
                               AND    fase.bil_id=bilancioid
                               AND    fase.fase_bil_elab_id=fasebilelabid
                               AND    fase.elem_id IS NOT NULL
                               AND    fase.elem_prov_id IS NOT NULL
                               AND    fase.elem_prov_new_id IS NULL
                               AND    fase.data_cancellazione IS NULL
                               AND    rcat.elem_id=fase.elem_prov_id
                               AND    rcat.data_cancellazione IS NULL
                               AND    rcat.validita_fine IS NULL
                               AND    rcat.elem_cat_id=cat.elem_cat_id
                               AND    cat.elem_cat_code = categoria_std
                               AND    NOT EXISTS
                                      (
                                               SELECT   1
                                               FROM     siac_r_bil_elem_class class ,
                                                        siac_t_class c
                                               WHERE    class.elem_id=fase.elem_prov_id
                                               AND      c.classif_id=class.classif_id
                                               AND      c.classif_tipo_id =macroaggrtipoid
                                               AND      class.data_cancellazione IS NULL
                                               AND      class.validita_fine IS NULL
                                               AND      c.data_cancellazione IS NULL
                                               /*siac-5297
                                               AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                               AND      (
                                                                 date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                        OR       c.validita_fine IS NULL)
                                                        */
                                               ORDER BY class.elem_id limit 1) );

          END IF;
          -- CL_COFOG
          codresult:=NULL;
          strmessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni '
          ||cl_cofog
          ||'.';
          SELECT   1
          INTO     codresult
          FROM     fase_bil_t_gest_apertura_provv fase
          WHERE    fase.ente_proprietario_id=enteproprietarioid
          AND      fase.bil_id=bilancioid
          AND      fase.fase_bil_elab_id=fasebilelabid
          AND      fase.elem_id IS NOT NULL
          AND      fase.elem_prov_id IS NOT NULL
          AND      fase.elem_prov_new_id IS NULL
          AND      fase.data_cancellazione IS NULL
                   -- Classificatore definito in gestione deve essere stato ribaltato su provvisorio
          AND      EXISTS
                   (
                            SELECT   1
                            FROM     siac_r_bil_elem_class class ,
                                     siac_t_class c
                            WHERE    class.elem_id=fase.elem_id
                            AND      c.classif_id=class.classif_id
                            AND      c.classif_tipo_id=cofogtipoid
                            AND      class.data_cancellazione IS NULL
                            AND      class.validita_fine IS NULL
                            AND      c.data_cancellazione IS NULL
                            AND      c.validita_fine IS NULL
/*siac-5297
                            AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                            AND      (
                                              date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                     OR       c.validita_fine IS NULL)
                                     */
                            ORDER BY class.elem_id limit 1)
          AND      NOT EXISTS
                   (
                            SELECT   1
                            FROM     siac_r_bil_elem_class class ,
                                     siac_t_class c
                            WHERE    class.elem_id=fase.elem_prov_id
                            AND      c.classif_id=class.classif_id
                            AND      c.classif_tipo_id=cofogtipoid
                            AND      class.data_cancellazione IS NULL
                            AND      class.validita_fine IS NULL
                            AND      c.data_cancellazione IS NULL
                            AND      c.validita_fine IS NULL

                                     /*siac-5297
                            AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                            AND      (
                                              date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                     OR       c.validita_fine IS NULL)
                                     */
                            ORDER BY class.elem_id limit 1)
          ORDER BY fase.fase_bil_gest_ape_prov_id limit 1;


          IF codresult IS NOT NULL THEN
            strmessaggio:=strmessaggio
            ||' Inserimento segnalazione mancanza classif.';
            INSERT INTO fase_bil_t_prev_apertura_segnala
                        (
                                    elem_id,
                                    elem_code,
                                    elem_code2,
                                    elem_code3,
                                    bil_id,
                                    fase_bil_elab_id,
                                    segnala_codice,
                                    segnala_desc,
                                    validita_inizio,
                                    ente_proprietario_id,
                                    login_operazione
                        )
                        (
                               SELECT fase.elem_prov_id,
                                      fase.elem_code,
                                      fase.elem_code2,
                                      fase.elem_code3,
                                      fase.bil_id,
                                      fasebilelabid,
                                      cl_cofog,
                                      cl_cofog
                                             ||' mancante',
                                      datainizioval,
                                      fase.ente_proprietario_id,
                                      loginoperazione
                               FROM   fase_bil_t_gest_apertura_provv fase
                               WHERE  fase.ente_proprietario_id=enteproprietarioid
                               AND    fase.bil_id=bilancioid
                               AND    fase.fase_bil_elab_id=fasebilelabid
                               AND    fase.elem_id IS NOT NULL
                               AND    fase.elem_prov_id IS NOT NULL
                               AND    fase.elem_prov_new_id IS NULL
                               AND    fase.data_cancellazione IS NULL
                               AND    EXISTS
                                      (
                                               SELECT   1
                                               FROM     siac_r_bil_elem_class class ,
                                                        siac_t_class c
                                               WHERE    class.elem_id=fase.elem_id
                                               AND      c.classif_id=class.classif_id
                                               AND      c.classif_tipo_id=cofogtipoid
                                               AND      class.data_cancellazione IS NULL
                                               AND      class.validita_fine IS NULL
                                               AND      c.data_cancellazione IS NULL
                                               /*siac-5297
                                               AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                               AND      (
                                                                 date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                        OR       c.validita_fine IS NULL)
                                                        */
                                               ORDER BY class.elem_id limit 1)
                               AND    NOT EXISTS
                                      (
                                               SELECT   1
                                               FROM     siac_r_bil_elem_class class ,
                                                        siac_t_class c
                                               WHERE    class.elem_id=fase.elem_prov_id
                                               AND      c.classif_id=class.classif_id
                                               AND      c.classif_tipo_id=cofogtipoid
                                               AND      class.data_cancellazione IS NULL
                                               AND      class.validita_fine IS NULL
                                               AND      c.data_cancellazione IS NULL
                                               /*siac-5297
                                               AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                               AND      (
                                                                 date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                        OR       c.validita_fine IS NULL)
                                                        */
                                               ORDER BY class.elem_id limit 1) );

          END IF;
          -- CL_RICORRENTE_SPESA
          codresult:=NULL;
          strmessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni '
          ||cl_ricorrente_spesa
          ||'.';
          SELECT   1
          INTO     codresult
          FROM     fase_bil_t_gest_apertura_provv fase
          WHERE    fase.ente_proprietario_id=enteproprietarioid
          AND      fase.bil_id=bilancioid
          AND      fase.fase_bil_elab_id=fasebilelabid
          AND      fase.elem_id IS NOT NULL
          AND      fase.elem_prov_id IS NOT NULL
          AND      fase.elem_prov_new_id IS NULL
          AND      fase.data_cancellazione IS NULL
                   -- Classificatore definito in gestione deve essere stato ribaltato su provvisorio
          AND      EXISTS
                   (
                            SELECT   1
                            FROM     siac_r_bil_elem_class class ,
                                     siac_t_class c
                            WHERE    class.elem_id=fase.elem_id
                            AND      c.classif_id=class.classif_id
                            AND      c.classif_tipo_id=ricorrentespesaid
                            AND      class.data_cancellazione IS NULL
                            AND      class.validita_fine IS NULL
                            AND      c.data_cancellazione IS NULL
                            AND      c.validita_fine IS NULL
                                     /*siac-5297
                            AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                            AND      (
                                              date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                     OR       c.validita_fine IS NULL)
                                     */
                            ORDER BY class.elem_id limit 1)
          AND      NOT EXISTS
                   (
                            SELECT   1
                            FROM     siac_r_bil_elem_class class ,
                                     siac_t_class c
                            WHERE    class.elem_id=fase.elem_prov_id
                            AND      c.classif_id=class.classif_id
                            AND      c.classif_tipo_id=ricorrentespesaid
                            AND      class.data_cancellazione IS NULL
                            AND      class.validita_fine IS NULL
                            AND      c.data_cancellazione IS NULL
                            AND      c.validita_fine IS NULL
                                    /*siac-5297
                            AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                            AND      (
                                              date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                     OR       c.validita_fine IS NULL)
                                     */
                            ORDER BY class.elem_id limit 1)
          ORDER BY fase.fase_bil_gest_ape_prov_id limit 1;


          IF codresult IS NOT NULL THEN
            strmessaggio:=strmessaggio
            ||' Inserimento segnalazione mancanza classif.';
            INSERT INTO fase_bil_t_prev_apertura_segnala
                        (
                                    elem_id,
                                    elem_code,
                                    elem_code2,
                                    elem_code3,
                                    bil_id,
                                    fase_bil_elab_id,
                                    segnala_codice,
                                    segnala_desc,
                                    validita_inizio,
                                    ente_proprietario_id,
                                    login_operazione
                        )
                        (
                               SELECT fase.elem_prov_id,
                                      fase.elem_code,
                                      fase.elem_code2,
                                      fase.elem_code3,
                                      fase.bil_id,
                                      fasebilelabid,
                                      cl_ricorrente_spesa,
                                      cl_ricorrente_spesa
                                             ||' mancante',
                                      datainizioval,
                                      fase.ente_proprietario_id,
                                      loginoperazione
                               FROM   fase_bil_t_gest_apertura_provv fase
                               WHERE  fase.ente_proprietario_id=enteproprietarioid
                               AND    fase.bil_id=bilancioid
                               AND    fase.fase_bil_elab_id=fasebilelabid
                               AND    fase.elem_id IS NOT NULL
                               AND    fase.elem_prov_id IS NOT NULL
                               AND    fase.elem_prov_new_id IS NULL
                               AND    fase.data_cancellazione IS NULL
                               AND    EXISTS
                                      (
                                               SELECT   1
                                               FROM     siac_r_bil_elem_class class ,
                                                        siac_t_class c
                                               WHERE    class.elem_id=fase.elem_id
                                               AND      c.classif_id=class.classif_id
                                               AND      c.classif_tipo_id=ricorrentespesaid
                                               AND      class.data_cancellazione IS NULL
                                               AND      class.validita_fine IS NULL
                                               AND      c.data_cancellazione IS NULL
                                               /*siac-5297
                                               AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                               AND      (
                                                                 date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                        OR       c.validita_fine IS NULL)
                                                */
                                               ORDER BY class.elem_id limit 1)
                               AND    NOT EXISTS
                                      (
                                               SELECT   1
                                               FROM     siac_r_bil_elem_class class ,
                                                        siac_t_class c
                                               WHERE    class.elem_id=fase.elem_prov_id
                                               AND      c.classif_id=class.classif_id
                                               AND      c.classif_tipo_id=ricorrentespesaid
                                               AND      class.data_cancellazione IS NULL
                                               AND      class.validita_fine IS NULL
                                               AND      c.data_cancellazione IS NULL
                                               /*siac-5297
                                               AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                               AND      (
                                                                 date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                        OR       c.validita_fine IS NULL)
                                               */
                                               ORDER BY class.elem_id limit 1) );

          END IF;
          -- CL_SIOPE_SPESA_TERZO
          codresult:=NULL;
          strmessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni '
          ||cl_siope_spesa_terzo
          ||'.';
          SELECT   1
          INTO     codresult
          FROM     fase_bil_t_gest_apertura_provv fase
          WHERE    fase.ente_proprietario_id=enteproprietarioid
          AND      fase.bil_id=bilancioid
          AND      fase.fase_bil_elab_id=fasebilelabid
          AND      fase.elem_id IS NOT NULL
          AND      fase.elem_prov_id IS NOT NULL
          AND      fase.elem_prov_new_id IS NULL
          AND      fase.data_cancellazione IS NULL
          AND      EXISTS
                   (
                            SELECT   1
                            FROM     siac_r_bil_elem_class class ,
                                     siac_t_class c
                            WHERE    class.elem_id=fase.elem_id
                            AND      c.classif_id=class.classif_id
                            AND      c.classif_tipo_id=siopespesatipoid
                            AND      class.data_cancellazione IS NULL
                            AND      class.validita_fine IS NULL
                            AND      c.data_cancellazione IS NULL
                            AND      c.validita_fine IS NULL
                            /*siac-5297
                            AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                            AND      (
                                              date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                     OR       c.validita_fine IS NULL)
                            */
                            ORDER BY class.elem_id limit 1)
          AND      NOT EXISTS
                   (
                            SELECT   1
                            FROM     siac_r_bil_elem_class class ,
                                     siac_t_class c
                            WHERE    class.elem_id=fase.elem_prov_id
                            AND      c.classif_id=class.classif_id
                            AND      c.classif_tipo_id=siopespesatipoid
                            AND      class.data_cancellazione IS NULL
                            AND      class.validita_fine IS NULL
                            AND      c.data_cancellazione IS NULL
                            AND      c.validita_fine IS NULL
                            /*siac-5297
                            AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                            AND      (
                                              date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                     OR       c.validita_fine IS NULL)
                            */
                            ORDER BY class.elem_id limit 1)
          ORDER BY fase.fase_bil_gest_ape_prov_id limit 1;


          IF codresult IS NOT NULL THEN
            strmessaggio:=strmessaggio
            ||' Inserimento segnalazione mancanza classif.';
            INSERT INTO fase_bil_t_prev_apertura_segnala
                        (
                                    elem_id,
                                    elem_code,
                                    elem_code2,
                                    elem_code3,
                                    bil_id,
                                    fase_bil_elab_id,
                                    segnala_codice,
                                    segnala_desc,
                                    validita_inizio,
                                    ente_proprietario_id,
                                    login_operazione
                        )
                        (
                               SELECT fase.elem_prov_id,
                                      fase.elem_code,
                                      fase.elem_code2,
                                      fase.elem_code3,
                                      fase.bil_id,
                                      fasebilelabid,
                                      cl_siope_spesa_terzo,
                                      cl_siope_spesa_terzo
                                             ||' mancante',
                                      datainizioval,
                                      fase.ente_proprietario_id,
                                      loginoperazione
                               FROM   fase_bil_t_gest_apertura_provv fase
                               WHERE  fase.ente_proprietario_id=enteproprietarioid
                               AND    fase.bil_id=bilancioid
                               AND    fase.fase_bil_elab_id=fasebilelabid
                               AND    fase.elem_id IS NOT NULL
                               AND    fase.elem_prov_id IS NOT NULL
                               AND    fase.elem_prov_new_id IS NULL
                               AND    fase.data_cancellazione IS NULL
                               AND    EXISTS
                                      (
                                               SELECT   1
                                               FROM     siac_r_bil_elem_class class ,
                                                        siac_t_class c
                                               WHERE    class.elem_id=fase.elem_id
                                               AND      c.classif_id=class.classif_id
                                               AND      c.classif_tipo_id=siopespesatipoid
                                               AND      class.data_cancellazione IS NULL
                                               AND      class.validita_fine IS NULL
                                               AND      c.data_cancellazione IS NULL
                                               /*siac-5297
                                               AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                               AND      (
                                                                 date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                        OR       c.validita_fine IS NULL)
                                                        */
                                               ORDER BY class.elem_id limit 1)
                               AND    NOT EXISTS
                                      (
                                               SELECT   1
                                               FROM     siac_r_bil_elem_class class ,
                                                        siac_t_class c
                                               WHERE    class.elem_id=fase.elem_prov_id
                                               AND      c.classif_id=class.classif_id
                                               AND      c.classif_tipo_id=siopespesatipoid
                                               AND      class.data_cancellazione IS NULL
                                               AND      class.validita_fine IS NULL
                                               AND      c.data_cancellazione IS NULL
                                               /*siac-5297
                                               AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                               AND      (
                                                                 date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                        OR       c.validita_fine IS NULL)
                                                        */
                                               ORDER BY class.elem_id limit 1) );

          END IF;
          -- CL_TRANSAZIONE_UE_SPESA
          codresult:=NULL;
          strmessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni '
          ||cl_transazione_ue_spesa
          ||'.';
          SELECT   1
          INTO     codresult
          FROM     fase_bil_t_gest_apertura_provv fase
          WHERE    fase.ente_proprietario_id=enteproprietarioid
          AND      fase.bil_id=bilancioid
          AND      fase.fase_bil_elab_id=fasebilelabid
          AND      fase.elem_id IS NOT NULL
          AND      fase.elem_prov_id IS NOT NULL
          AND      fase.elem_prov_new_id IS NULL
          AND      fase.data_cancellazione IS NULL
                   -- Classificatore definito in gestione deve essere stato ribaltato su provvisorio
          AND      EXISTS
                   (
                            SELECT   1
                            FROM     siac_r_bil_elem_class class ,
                                     siac_t_class c
                            WHERE    class.elem_id=fase.elem_id
                            AND      c.classif_id=class.classif_id
                            AND      c.classif_tipo_id=transazioneuespesaid
                            AND      class.data_cancellazione IS NULL
                            AND      class.validita_fine IS NULL
                            AND      c.data_cancellazione IS NULL
                            AND      c.validita_fine IS NULL
                            /*siac-5297
                            AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                            AND      (
                                              date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                     OR       c.validita_fine IS NULL)
                                     */
                            ORDER BY class.elem_id limit 1)
          AND      NOT EXISTS
                   (
                            SELECT   1
                            FROM     siac_r_bil_elem_class class ,
                                     siac_t_class c
                            WHERE    class.elem_id=fase.elem_prov_id
                            AND      c.classif_id=class.classif_id
                            AND      c.classif_tipo_id=transazioneuespesaid
                            AND      class.data_cancellazione IS NULL
                            AND      class.validita_fine IS NULL
                            AND      c.data_cancellazione IS NULL
                            AND      c.validita_fine IS NULL
                             /*siac-5297
                            AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                            AND      (
                                              date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                     OR       c.validita_fine IS NULL)
                                     */
                            ORDER BY class.elem_id limit 1)
          ORDER BY fase.fase_bil_gest_ape_prov_id limit 1;


          IF codresult IS NOT NULL THEN
            strmessaggio:=strmessaggio
            ||' Inserimento segnalazione mancanza classif.';
            INSERT INTO fase_bil_t_prev_apertura_segnala
                        (
                                    elem_id,
                                    elem_code,
                                    elem_code2,
                                    elem_code3,
                                    bil_id,
                                    fase_bil_elab_id,
                                    segnala_codice,
                                    segnala_desc,
                                    validita_inizio,
                                    ente_proprietario_id,
                                    login_operazione
                        )
                        (
                               SELECT fase.elem_prov_id,
                                      fase.elem_code,
                                      fase.elem_code2,
                                      fase.elem_code3,
                                      fase.bil_id,
                                      fasebilelabid,
                                      cl_transazione_ue_spesa,
                                      cl_transazione_ue_spesa
                                             ||' mancante',
                                      datainizioval,
                                      fase.ente_proprietario_id,
                                      loginoperazione
                               WHERE  fase.ente_proprietario_id=enteproprietarioid
                               AND    fase.bil_id=bilancioid
                               AND    fase.fase_bil_elab_id=fasebilelabid
                               AND    fase.elem_id IS NOT NULL
                               AND    fase.elem_prov_id IS NOT NULL
                               AND    fase.elem_prov_new_id IS NULL
                               AND    fase.data_cancellazione IS NULL
                               AND    EXISTS
                                      (
                                               SELECT   1
                                               FROM     siac_r_bil_elem_class class ,
                                                        siac_t_class c
                                               WHERE    class.elem_id=fase.elem_id
                                               AND      c.classif_id=class.classif_id
                                               AND      c.classif_tipo_id=transazioneuespesaid
                                               AND      class.data_cancellazione IS NULL
                                               AND      class.validita_fine IS NULL
                                               AND      c.data_cancellazione IS NULL
                                               /*siac-5297
                                               AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                               AND      (
                                                                 date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                        OR       c.validita_fine IS NULL)
                                                        */
                                               ORDER BY class.elem_id limit 1)
                               AND    NOT EXISTS
                                      (
                                               SELECT   1
                                               FROM     siac_r_bil_elem_class class ,
                                                        siac_t_class c
                                               WHERE    class.elem_id=fase.elem_prov_id
                                               AND      c.classif_id=class.classif_id
                                               AND      c.classif_tipo_id=transazioneuespesaid
                                               AND      class.data_cancellazione IS NULL
                                               AND      class.validita_fine IS NULL
                                               AND      c.data_cancellazione IS NULL
                                               /*siac-5297
                                               AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                               AND      (
                                                                 date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                        OR       c.validita_fine IS NULL)
                                                        */
                                               ORDER BY class.elem_id limit 1) );

          END IF;
        ELSE
          -- CL_CATEGORIA
          codresult:=NULL;
          strmessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni '
          ||cl_categoria
          ||'.';
          -- Classificatore deve essere obbligatoriamente presente solo se capitolo STD
          SELECT DISTINCT 1
          INTO            codresult
          FROM            fase_bil_t_gest_apertura_provv fase,
                          siac_r_bil_elem_categoria rcat,
                          siac_d_bil_elem_categoria cat
          WHERE           fase.ente_proprietario_id=enteproprietarioid
          AND             fase.bil_id=bilancioid
          AND             fase.fase_bil_elab_id=fasebilelabid
          AND             fase.elem_id IS NOT NULL
          AND             fase.elem_prov_id IS NOT NULL
          AND             fase.elem_prov_new_id IS NULL
          AND             fase.data_cancellazione IS NULL
          AND             rcat.elem_id=fase.elem_prov_id
          AND             rcat.data_cancellazione IS NULL
          AND             rcat.validita_fine IS NULL
          AND             rcat.elem_cat_id=cat.elem_cat_id
          AND             cat.elem_cat_code = categoria_std
          AND             NOT EXISTS
                          (
                                 SELECT 1
                                 FROM   siac_r_bil_elem_class class ,
                                        siac_t_class c
                                 WHERE  class.elem_id=fase.elem_prov_id
                                 AND    c.classif_id=class.classif_id
                                 AND    c.classif_tipo_id=categoriatipoid
                                 AND    class.data_cancellazione IS NULL
                                 AND    class.validita_fine IS NULL
                                 AND    c.data_cancellazione IS NULL
                                 AND    c.validita_fine IS NULL
                                 /*siac-5297
                                 AND    date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                 AND    (
                                               date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                        OR     c.validita_fine IS NULL)
                                        */
                                         limit 1);


          IF codresult IS NOT NULL THEN
            strmessaggio:=strmessaggio
            ||' Inserimento segnalazione mancanza classif.';
            INSERT INTO fase_bil_t_prev_apertura_segnala
                        (
                                    elem_id,
                                    elem_code,
                                    elem_code2,
                                    elem_code3,
                                    bil_id,
                                    fase_bil_elab_id,
                                    segnala_codice,
                                    segnala_desc,
                                    validita_inizio,
                                    ente_proprietario_id,
                                    login_operazione
                        )
                        (
                               SELECT fase.elem_prov_id,
                                      fase.elem_code,
                                      fase.elem_code2,
                                      fase.elem_code3,
                                      fase.bil_id,
                                      fasebilelabid,
                                      cl_categoria,
                                      cl_categoria
                                             ||' mancante',
                                      datainizioval,
                                      fase.ente_proprietario_id,
                                      loginoperazione
                               FROM   fase_bil_t_gest_apertura_provv fase,
                                      siac_r_bil_elem_categoria rcat,
                                      siac_d_bil_elem_categoria cat
                               WHERE  fase.ente_proprietario_id=enteproprietarioid
                               AND    fase.bil_id=bilancioid
                               AND    fase.fase_bil_elab_id=fasebilelabid
                               AND    fase.elem_id IS NOT NULL
                               AND    fase.elem_prov_id IS NOT NULL
                               AND    fase.elem_prov_new_id IS NULL
                               AND    fase.data_cancellazione IS NULL
                               AND    rcat.elem_id=fase.elem_prov_id
                               AND    rcat.data_cancellazione IS NULL
                               AND    rcat.validita_fine IS NULL
                               AND    rcat.elem_cat_id=cat.elem_cat_id
                               AND    cat.elem_cat_code = categoria_std
                               AND    NOT EXISTS
                                      (
                                             SELECT 1
                                             FROM   siac_r_bil_elem_class class ,
                                                    siac_t_class c
                                             WHERE  class.elem_id=fase.elem_prov_id
                                             AND    c.classif_id=class.classif_id
                                             AND    c.classif_tipo_id=categoriatipoid
                                             AND    class.data_cancellazione IS NULL
                                             AND    class.validita_fine IS NULL
                                             AND    c.data_cancellazione IS NULL
                                             /*siac-5297
                                             AND    date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                             AND    (
                                                           date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                    OR     c.validita_fine IS NULL)
                                                    */
                                                    limit 1) );

          END IF;
          -- CL_RICORRENTE_ENTRATA
          codresult:=NULL;
          strmessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni '
          ||cl_ricorrente_entrata
          ||'.';
          SELECT   1
          INTO     codresult
          FROM     fase_bil_t_gest_apertura_provv fase
          WHERE    fase.ente_proprietario_id=enteproprietarioid
          AND      fase.bil_id=bilancioid
          AND      fase.fase_bil_elab_id=fasebilelabid
          AND      fase.elem_id IS NOT NULL
          AND      fase.elem_prov_id IS NOT NULL
          AND      fase.elem_prov_new_id IS NULL
          AND      fase.data_cancellazione IS NULL
                   -- Classificatore definito in provvisorio deve essere stato ribaltato su gestione
          AND      EXISTS
                   (
                            SELECT   1
                            FROM     siac_r_bil_elem_class class ,
                                     siac_t_class c
                            WHERE    class.elem_id=fase.elem_id
                            AND      c.classif_id=class.classif_id
                            AND      c.classif_tipo_id=ricorrenteentrataid
                            AND      class.data_cancellazione IS NULL
                            AND      class.validita_fine IS NULL
                            AND      c.data_cancellazione IS NULL
                            AND      c.validita_fine IS NULL
                            /*siac-5297
                            AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                            AND      (
                                              date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                     OR       c.validita_fine IS NULL)*/
                            ORDER BY class.elem_id limit 1)
          AND      NOT EXISTS
                   (
                            SELECT   1
                            FROM     siac_r_bil_elem_class class ,
                                     siac_t_class c
                            WHERE    class.elem_id=fase.elem_prov_id
                            AND      c.classif_id=class.classif_id
                            AND      c.classif_tipo_id=ricorrenteentrataid
                            AND      class.data_cancellazione IS NULL
                            AND      class.validita_fine IS NULL
                            AND      c.data_cancellazione IS NULL
                            AND      c.validita_fine IS NULL
                            /*siac-5297
                            AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                            AND      (
                                              date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                     OR       c.validita_fine IS NULL)
                                     */
                            ORDER BY class.elem_id limit 1)
          ORDER BY fase.fase_bil_gest_ape_prov_id limit 1;

          IF codresult IS NOT NULL THEN
            strmessaggio:=strmessaggio
            ||' Inserimento segnalazione mancanza classif.';
            INSERT INTO fase_bil_t_prev_apertura_segnala
                        (
                                    elem_id,
                                    elem_code,
                                    elem_code2,
                                    elem_code3,
                                    bil_id,
                                    fase_bil_elab_id,
                                    segnala_codice,
                                    segnala_desc,
                                    validita_inizio,
                                    ente_proprietario_id,
                                    login_operazione
                        )
                        (
                               SELECT fase.elem_prov_id,
                                      fase.elem_code,
                                      fase.elem_code2,
                                      fase.elem_code3,
                                      fase.bil_id,
                                      fasebilelabid,
                                      cl_ricorrente_entrata,
                                      cl_ricorrente_entrata
                                             ||' mancante',
                                      datainizioval,
                                      fase.ente_proprietario_id,
                                      loginoperazione
                               FROM   fase_bil_t_gest_apertura_provv fase
                               WHERE  fase.ente_proprietario_id=enteproprietarioid
                               AND    fase.bil_id=bilancioid
                               AND    fase.fase_bil_elab_id=fasebilelabid
                               AND    fase.elem_id IS NOT NULL
                               AND    fase.elem_prov_id IS NOT NULL
                               AND    fase.elem_prov_new_id IS NULL
                               AND    fase.data_cancellazione IS NULL
                               AND    EXISTS
                                      (
                                               SELECT   1
                                               FROM     siac_r_bil_elem_class class ,
                                                        siac_t_class c
                                               WHERE    class.elem_id=fase.elem_id
                                               AND      c.classif_id=class.classif_id
                                               AND      c.classif_tipo_id=ricorrenteentrataid
                                               AND      class.data_cancellazione IS NULL
                                               AND      class.validita_fine IS NULL
                                               AND      c.data_cancellazione IS NULL
                                               /*siac-5297
                                               AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                               AND      (
                                                                 date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                        OR       c.validita_fine IS NULL)
                                                        */
                                               ORDER BY class.elem_id limit 1)
                               AND    NOT EXISTS
                                      (
                                               SELECT   1
                                               FROM     siac_r_bil_elem_class class ,
                                                        siac_t_class c
                                               WHERE    class.elem_id=fase.elem_prov_id
                                               AND      c.classif_id=class.classif_id
                                               AND      c.classif_tipo_id=ricorrenteentrataid
                                               AND      class.data_cancellazione IS NULL
                                               AND      class.validita_fine IS NULL
                                               AND      c.data_cancellazione IS NULL
                                               /*siac-5297
                                               AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                               AND      (
                                                                 date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                        OR       c.validita_fine IS NULL)
                                                        */
                                               ORDER BY class.elem_id limit 1) );

          END IF;
          -- CL_SIOPE_ENTRATA_TERZO
          codresult:=NULL;
          strmessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni '
          ||cl_siope_entrata_terzo
          ||'.';
          SELECT   1
          INTO     codresult
          FROM     fase_bil_t_gest_apertura_provv fase
          WHERE    fase.ente_proprietario_id=enteproprietarioid
          AND      fase.bil_id=bilancioid
          AND      fase.fase_bil_elab_id=fasebilelabid
          AND      fase.elem_id IS NOT NULL
          AND      fase.elem_prov_id IS NOT NULL
          AND      fase.elem_prov_new_id IS NULL
          AND      fase.data_cancellazione IS NULL
          AND      EXISTS
                   (
                            SELECT   1
                            FROM     siac_r_bil_elem_class class ,
                                     siac_t_class c
                            WHERE    class.elem_id=fase.elem_id
                            AND      c.classif_id=class.classif_id
                            AND      c.classif_tipo_id=siopeentratatipoid
                            AND      class.data_cancellazione IS NULL
                            AND      class.validita_fine IS NULL
                            AND      c.data_cancellazione IS NULL
                            AND      c.validita_fine IS NULL
                             /*siac-5297
                            AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                            AND      (
                                              date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                     OR       c.validita_fine IS NULL)
                                     */
                            ORDER BY class.elem_id limit 1)
          AND      NOT EXISTS
                   (
                            SELECT   1
                            FROM     siac_r_bil_elem_class class ,
                                     siac_t_class c
                            WHERE    class.elem_id=fase.elem_prov_id
                            AND      c.classif_id=class.classif_id
                            AND      c.classif_tipo_id=siopeentratatipoid
                            AND      class.data_cancellazione IS NULL
                            AND      class.validita_fine IS NULL
                            AND      c.data_cancellazione IS NULL
                            AND      c.validita_fine IS NULL
                            /*siac-5297
                            AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                            AND      (
                                              date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                     OR       c.validita_fine IS NULL)
                                     */
                            ORDER BY class.elem_id limit 1)
          ORDER BY fase.fase_bil_gest_ape_prov_id limit 1;

          IF codresult IS NOT NULL THEN
            strmessaggio:=strmessaggio
            ||' Inserimento segnalazione mancanza classif.';
            INSERT INTO fase_bil_t_prev_apertura_segnala
                        (
                                    elem_id,
                                    elem_code,
                                    elem_code2,
                                    elem_code3,
                                    bil_id,
                                    fase_bil_elab_id,
                                    segnala_codice,
                                    segnala_desc,
                                    validita_inizio,
                                    ente_proprietario_id,
                                    login_operazione
                        )
                        (
                               SELECT fase.elem_prov_id,
                                      fase.elem_code,
                                      fase.elem_code2,
                                      fase.elem_code3,
                                      fase.bil_id,
                                      fasebilelabid,
                                      cl_siope_entrata_terzo,
                                      cl_siope_entrata_terzo
                                             ||' mancante',
                                      datainizioval,
                                      fase.ente_proprietario_id,
                                      loginoperazione
                               FROM   fase_bil_t_gest_apertura_provv fase
                               WHERE  fase.ente_proprietario_id=enteproprietarioid
                               AND    fase.bil_id=bilancioid
                               AND    fase.fase_bil_elab_id=fasebilelabid
                               AND    fase.elem_id IS NOT NULL
                               AND    fase.elem_prov_id IS NOT NULL
                               AND    fase.elem_prov_new_id IS NULL
                               AND    fase.data_cancellazione IS NULL
                               AND    EXISTS
                                      (
                                               SELECT   1
                                               FROM     siac_r_bil_elem_class class ,
                                                        siac_t_class c
                                               WHERE    class.elem_id=fase.elem_id
                                               AND      c.classif_id=class.classif_id
                                               AND      c.classif_tipo_id=siopeentratatipoid
                                               AND      class.data_cancellazione IS NULL
                                               AND      class.validita_fine IS NULL
                                               AND      c.data_cancellazione IS NULL
                                               /*siac-5297
                                               AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                               AND      (
                                                                 date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                        OR       c.validita_fine IS NULL)
                                                        */
                                               ORDER BY class.elem_id limit 1)
                               AND    NOT EXISTS
                                      (
                                               SELECT   1
                                               FROM     siac_r_bil_elem_class class ,
                                                        siac_t_class c
                                               WHERE    class.elem_id=fase.elem_prov_id
                                               AND      c.classif_id=class.classif_id
                                               AND      c.classif_tipo_id=siopeentratatipoid
                                               AND      class.data_cancellazione IS NULL
                                               AND      class.validita_fine IS NULL
                                               AND      c.data_cancellazione IS NULL
                                               /*siac-5297
                                               AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                               AND      (
                                                                 date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                        OR       c.validita_fine IS NULL)
                                                        */
                                               ORDER BY class.elem_id limit 1) );

          END IF;
          -- CL_TRANSAZIONE_UE_ENTRATA
          codresult:=NULL;
          strmessaggio:='Inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente [siac_r_bil_elem_class].Verifica esistenza relazioni '
          ||cl_transazione_ue_entrata
          ||'.';
          SELECT   1
          INTO     codresult
          FROM     fase_bil_t_gest_apertura_provv fase
          WHERE    fase.ente_proprietario_id=enteproprietarioid
          AND      fase.bil_id=bilancioid
          AND      fase.fase_bil_elab_id=fasebilelabid
          AND      fase.elem_id IS NOT NULL
          AND      fase.elem_prov_id IS NOT NULL
          AND      fase.elem_prov_new_id IS NULL
          AND      fase.data_cancellazione IS NULL
                   -- Classificatore definito in gestione deve essere stato ribaltato su provvisorio
          AND      EXISTS
                   (
                            SELECT   1
                            FROM     siac_r_bil_elem_class class ,
                                     siac_t_class c
                            WHERE    class.elem_id=fase.elem_id
                            AND      c.classif_id=class.classif_id
                            AND      c.classif_tipo_id=transazioneueentrataid
                            AND      class.data_cancellazione IS NULL
                            AND      class.validita_fine IS NULL
                            AND      c.data_cancellazione IS NULL
                            AND      c.validita_fine IS NULL
                            /*siac-5297
                            AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                            AND      (
                                              date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                     OR       c.validita_fine IS NULL)
                                     */
                            ORDER BY class.elem_id limit 1)
          AND      NOT EXISTS
                   (
                            SELECT   1
                            FROM     siac_r_bil_elem_class class ,
                                     siac_t_class c
                            WHERE    class.elem_id=fase.elem_prov_id
                            AND      c.classif_id=class.classif_id
                            AND      c.classif_tipo_id=transazioneueentrataid
                            AND      class.data_cancellazione IS NULL
                            AND      class.validita_fine IS NULL
                            AND      c.data_cancellazione IS NULL
                            AND      c.validita_fine IS NULL
                            /*siac-5297
                            AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                            AND      (
                                              date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                     OR       c.validita_fine IS NULL)
                                     */
                            ORDER BY class.elem_id limit 1)
          ORDER BY fase.fase_bil_gest_ape_prov_id limit 1;

          IF codresult IS NOT NULL THEN
            strmessaggio:=strmessaggio
            ||' Inserimento segnalazione mancanza classif.';
            INSERT INTO fase_bil_t_prev_apertura_segnala
                        (
                                    elem_id,
                                    elem_code,
                                    elem_code2,
                                    elem_code3,
                                    bil_id,
                                    fase_bil_elab_id,
                                    segnala_codice,
                                    segnala_desc,
                                    validita_inizio,
                                    ente_proprietario_id,
                                    login_operazione
                        )
                        (
                               SELECT fase.elem_prov_id,
                                      fase.elem_code,
                                      fase.elem_code2,
                                      fase.elem_code3,
                                      fase.bil_id,
                                      fasebilelabid,
                                      cl_transazione_ue_entrata,
                                      cl_transazione_ue_entrata
                                             ||' mancante',
                                      datainizioval,
                                      fase.ente_proprietario_id,
                                      loginoperazione
                               FROM   fase_bil_t_gest_apertura_provv fase
                               WHERE  fase.ente_proprietario_id=enteproprietarioid
                               AND    fase.bil_id=bilancioid
                               AND    fase.fase_bil_elab_id=fasebilelabid
                               AND    fase.elem_id IS NOT NULL
                               AND    fase.elem_prov_id IS NOT NULL
                               AND    fase.elem_prov_new_id IS NULL
                               AND    fase.data_cancellazione IS NULL
                               AND    EXISTS
                                      (
                                               SELECT   1
                                               FROM     siac_r_bil_elem_class class ,
                                                        siac_t_class c
                                               WHERE    class.elem_id=fase.elem_id
                                               AND      c.classif_id=class.classif_id
                                               AND      c.classif_tipo_id=transazioneueentrataid
                                               AND      class.data_cancellazione IS NULL
                                               AND      class.validita_fine IS NULL
                                               AND      c.data_cancellazione IS NULL
                                               /*siac-5297
                                               AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                               AND      (
                                                                 date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                        OR       c.validita_fine IS NULL)
                                                        */
                                               ORDER BY class.elem_id limit 1)
                               AND    NOT EXISTS
                                      (
                                               SELECT   1
                                               FROM     siac_r_bil_elem_class class ,
                                                        siac_t_class c
                                               WHERE    class.elem_id=fase.elem_prov_id
                                               AND      c.classif_id=class.classif_id
                                               AND      c.classif_tipo_id=transazioneueentrataid
                                               AND      class.data_cancellazione IS NULL
                                               AND      class.validita_fine IS NULL
                                               AND      c.data_cancellazione IS NULL
                                               /*siac-5297
                                               AND      date_trunc('day',datainiziovalclass)>=date_trunc('day',c.validita_inizio)
                                               AND      (
                                                                 date_trunc('day',datafinevalclass)<=date_trunc('day',c.validita_fine)
                                                        OR       c.validita_fine IS NULL)
                                                        */
                                               ORDER BY class.elem_id limit 1) );

          END IF;
        END IF;
        codresult:=NULL;
        strmessaggio:='Fine verifica inserimento nuove strutture provvisorio esistenti da gestione equivalente anno precedente.';
        INSERT INTO fase_bil_t_elaborazione_log
                    (
                                fase_bil_elab_id,
                                fase_bil_elab_log_operazione,
                                validita_inizio,
                                login_operazione,
                                ente_proprietario_id
                    )
                    VALUES
                    (
                                fasebilelabid,
                                strmessaggio,
                                clock_timestamp(),
                                loginoperazione,
                                enteproprietarioid
                    )
        returning   fase_bil_elab_log_id
        INTO        codresult;

        IF codresult IS NULL THEN
          RAISE
        EXCEPTION
          ' Errore in inserimento LOG.';
        END IF;
      END IF;
    END IF;
    strmessaggio:='Aggiornamento fase elaborazione [fase_bil_t_elaborazione].';
    UPDATE fase_bil_t_elaborazione
    SET    fase_bil_elab_esito='IN2',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '
                  ||ape_prov_da_gest
                  ||' IN CORSO : AGGIORNAMENTO STRUTTURE COMPLETATO.'
    WHERE  fase_bil_elab_id=fasebilelabid;

    codresult:=NULL;
    INSERT INTO fase_bil_t_elaborazione_log
                (
                            fase_bil_elab_id,
                            fase_bil_elab_log_operazione,
                            validita_inizio,
                            login_operazione,
                            ente_proprietario_id
                )
                VALUES
                (
                            fasebilelabid,
                            strmessaggio,
                            clock_timestamp(),
                            loginoperazione,
                            enteproprietarioid
                )
    returning   fase_bil_elab_log_id
    INTO        codresult;

    IF codresult IS NULL THEN
      RAISE
    EXCEPTION
      ' Errore in inserimento LOG.';
    END IF;
    fasebilelabidret:= fasebilelabid;
    messaggiorisultato:=strmessaggiofinale
    ||'OK .';
    RETURN;
  EXCEPTION
  WHEN raise_exception THEN
    RAISE notice '% % ERRORE : %',strmessaggiofinale,strmessaggio, substring(upper(SQLERRM) FROM 1 FOR 500);
    messaggiorisultato:=strmessaggiofinale
    ||strmessaggio
    ||'ERRORE :'
    ||' '
    ||substring(upper(SQLERRM) FROM 1 FOR 500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice ' % % Nessun elemento trovato.' ,strmessaggiofinale,strmessaggio;
    messaggiorisultato:=strmessaggiofinale
    ||strmessaggio
    ||'Nessun elemento trovato.' ;
    codicerisultato:=-1;
    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 50);
    messaggiorisultato:=strmessaggiofinale
    ||strmessaggio
    ||'Errore DB '
    ||SQLSTATE
    ||' '
    ||substring(upper(SQLERRM) FROM 1 FOR 50) ;
    codicerisultato:=-1;
    RETURN;
  END;
  $body$ LANGUAGE 'plpgsql' volatile called ON NULL input security invoker cost 100;