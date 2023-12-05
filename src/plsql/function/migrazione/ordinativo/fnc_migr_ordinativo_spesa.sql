/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create or replace function fnc_migr_ordinativo_spesa(
    enteproprietarioid integer,
    annobilancio varchar,
    loginoperazione varchar,
    dataelaborazione timestamp,
    idmin integer,
    idmax integer,
    out numerorecordinseriti integer,
    out messaggiorisultato varchar)
RETURNS record AS
$body$
DECLARE

   -- fnc_migr_ordinativo --> function che effettua il caricamento delgli ordinativi da migrare.
   -- leggendo da migr_ordinativo
   -- effettua inserimento di
   -- siac_t_ordinativo : tabella principale

    NVL_STR               CONSTANT VARCHAR:='';
    TIPO_ORD              CONSTANT VARCHAR:='P';
    SEPARATORE            CONSTANT varchar :='||';
    CL_CLASSIFICATORE_1   CONSTANT varchar :='CLASSIFICATORE_23';
    CL_CLASSIFICATORE_2   CONSTANT varchar :='CLASSIFICATORE_24';
    CL_CLASSIFICATORE_3   CONSTANT varchar :='CLASSIFICATORE_25';
    --CL_CLASSIFICATORE_4   CONSTANT varchar :='CLASSIFICATORE_25';

    strToElab             varchar(250):='';
    strMessaggio          VARCHAR(1500):='';
    strMessaggioFinale    VARCHAR(1500):='';
    strMessaggioScarto    VARCHAR(1500):='';
    strDettaglioScarto    VARCHAR(1500):='';
    countRecordDaMigrare  integer := 0;
    countRecordInseriti   integer := 0;
    v_scarto              integer := 0; -- 1 se esiste uno scarto per il numero_ordinativo da migrare, 0 se non esiste quindi viene inserito durante questa elaborazione.

    migrClassif record;
    migrRecord RECORD;
    aggProgressivi record;
    recClassif record;

    dataInizioVal timestamp :=null;
    classifCode varchar(250):='';
    classifDesc varchar(250):='';
    segnalare                       boolean := false;
    recId                           varchar(100) :='';
    bilancioId                      INTEGER := 0; -- pk tabella siac_t_bil
    --soggettoId                    INTEGER := 0; -- pk tabella siac_t_soggetto
    v_ordId                         INTEGER := 0; -- pk tab. siac_t_ordinativo
    v_ord_tipo_id                   INTEGER := 0; -- pk tab. siac_d_ordinativo_tipo
    v_codbollo_id                   INTEGER := 0; -- pk tab. siac_d_codicebollo
    v_comm_tipo_id                  INTEGER := 0; -- pk tab. siac_d_commissione_tipo
    v_contotes_id                   INTEGER := 0; -- pk tab. siac_d_contotesoreria
    v_notete_id                     INTEGER := 0; -- pk tab. siac_d_noteoriere
    v_dist_id                       INTEGER := 0; -- pk tab. siac_d_distinta
    --v_ord_ts_det_tipo_id_i        INTEGER := 0; -- pk siac_d_ordinativo_ts_det_tipo
    --v_ord_ts_det_tipo_id_a        INTEGER := 0; -- pk siac_d_ordinativo_ts_det_tipo
    v_ord_stato_id                  INTEGER := 0; -- pk siac_d_ordinativo_stato
    v_ord_stato_id_a                INTEGER := 0; -- pk siac_d_ordinativo_stato
    v_ord_stato_id_i                INTEGER := 0; -- pk siac_d_ordinativo_stato
    v_ord_stato_id_t                INTEGER := 0; -- pk siac_d_ordinativo_stato
    v_ord_stato_id_f                INTEGER := 0; -- pk siac_d_ordinativo_stato
    v_ord_stato_id_q                INTEGER := 0; -- pk siac_d_ordinativo_stato
    v_elem_id                       INTEGER := 0; -- pk di siac_t_bil_elem  (capitolo)
    v_soggetto_id                   INTEGER := 0; -- pk di siac_t_soggetto
    v_attoamm_id                    INTEGER := 0; -- pk di siac_t_atto_amm
    v_liq_id                        INTEGER := 0; 
    v_anno_liquidazione             INTEGER := 0; -- per l'inserimento delle relazioni
    v_num_liquidazione              INTEGER := 0; -- per l'inserimento delle relazioni
    v_attr_id_flagAllegatoCartaceo  INTEGER := 0; -- pk di siac_t_attr
    v_attr_id_note_ordinativo       INTEGER := 0; -- pk di siac_t_attr
    v_attr_id_cig                   INTEGER := 0; -- pk di siac_t_attr
    v_attr_id_cup                   INTEGER := 0; -- pk di siac_t_attr
    v_classif_tipo_id_pdc           INTEGER := 0; 
    v_classif_tipo_id_tra           INTEGER := 0; 
    v_classif_tipo_id_sp_ri         INTEGER := 0; 
    v_classif_tipo_id_pesa          INTEGER := 0; 
    v_classif_tipo_id_pore          INTEGER := 0; 
    v_classif_tipo_id_siope         INTEGER := 0; 
    v_modpag_id                     INTEGER := 0; 
  
    v_soggettoRelazId               integer := 0; 
    migr_modpag_id_principale       integer := 0; 
    modpag_id_principale            integer := 0; 
    mmdp_sede_secondaria            VARCHAR(1) := null;
    mmdp_cessione                   VARCHAR(20):= null; 
    soggetto_id_principale          integer := 0; 
    migr_soggetto_id_principale     integer := 0;
    migr_modpag_id_altra            integer := 0;
    modpag_id_altra                 integer := 0;
    soggetto_id_altro               integer := 0;    
    
BEGIN
    numerorecordinseriti:=0;
    messaggioRisultato:='';
    strMessaggioFinale:='Migrazione ordinativi di spesa.';

    dataInizioVal:=date_trunc('DAY', now());

    -- lettura id bilancio
    strMessaggio:='Lettura id bilancio per anno '||annoBilancio||'.';
    select bilancio.idbilancio, bilancio.messaggiorisultato into bilancioid,messaggioRisultato
    from fnc_get_bilancio(enteProprietarioId,annoBilancio) bilancio;
    if (bilancioid=-1) then
        messaggioRisultato:=strMessaggioFinale||messaggioRisultato;
        numerorecordinseriti:=-13;
        return;
    end if;

    begin
         strMessaggio:='conteggio dei record da migrare.';
         select distinct 1 into strict countRecordDaMigrare from migr_ordinativo_spesa m
         where m.ente_proprietario_id=enteproprietarioid
               and m.fl_elab='N'
               and m.migr_ordinativo_id >= idmin
               and m.migr_ordinativo_id <= idmax;
    exception
        when NO_DATA_FOUND then
         messaggioRisultato:=strMessaggioFinale||' Archivio migrazione vuoto per ente '||enteProprietarioId||', idmin '||idmin||', idmax '||idmax||'.';
         numerorecordinseriti:=-12;
         return;

        when others  THEN
            raise notice '%  % ERRORE DB: % %',strMessaggioFinale,strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 500);
            messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
            numerorecordinseriti:=-1;
            return;
    end;

    begin
        strMessaggio :=' estraggo ord_tipo_id dal campo della tabella di migrazione per codice ord --> '|| TIPO_ORD||'.';
        select ord_tipo_id 
          into strict v_ord_tipo_id 
          from siac_d_ordinativo_tipo
         where ente_proprietario_id =  enteproprietarioid
           and data_cancellazione is null and ord_tipo_code = TIPO_ORD
           and date_trunc('day',dataelaborazione)>=date_trunc('day',validita_inizio)
           and (date_trunc('day',dataelaborazione)<=date_trunc('day',validita_fine) or validita_fine is null);
    exception
         when NO_DATA_FOUND then
         messaggioRisultato:=strMessaggioFinale||strMessaggio||' record non trovato.';
         numerorecordinseriti:=-1;
         return;
         when others  THEN
            raise notice '%  % ERRORE DB: % %',strMessaggioFinale,strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 500);
            messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
            numerorecordinseriti:=-1;
            return;
    end;

    begin
        strMessaggio :=' estraggo lo stato id da  siac_d_ordinativo_stato per codice A. ';
        select ord_stato_id
          into strict v_ord_stato_id_a
          from siac_d_ordinativo_stato
         where
               ente_proprietario_id=enteproprietarioid and
               ord_stato_code='A' and
               date_trunc('day',dataelaborazione)>=date_trunc('day',validita_inizio) and
               (date_trunc('day',dataelaborazione)<=date_trunc('day',validita_fine) or validita_fine is null);


        strMessaggio :=' estraggo lo stato id da  siac_d_ordinativo_stato per codice I. ';
        select ord_stato_id
          into strict v_ord_stato_id_i
          from siac_d_ordinativo_stato
         where
               ente_proprietario_id=enteproprietarioid and
               ord_stato_code='I' and
               date_trunc('day',dataelaborazione)>=date_trunc('day',validita_inizio) and
               (date_trunc('day',dataelaborazione)<=date_trunc('day',validita_fine) or validita_fine is null);

        strMessaggio :=' estraggo lo stato id da  siac_d_ordinativo_stato per codice T. ';
        select ord_stato_id
          into strict v_ord_stato_id_t
          from siac_d_ordinativo_stato
         where
               ente_proprietario_id=enteproprietarioid and
               ord_stato_code='T' and
               date_trunc('day',dataelaborazione)>=date_trunc('day',validita_inizio) and
               (date_trunc('day',dataelaborazione)<=date_trunc('day',validita_fine) or validita_fine is null);

        strMessaggio :=' estraggo lo stato id da  siac_d_ordinativo_stato per codice F. ';
        select ord_stato_id
          into strict v_ord_stato_id_f
          from siac_d_ordinativo_stato
         where
               ente_proprietario_id=enteproprietarioid and
               ord_stato_code='F' and
               date_trunc('day',dataelaborazione)>=date_trunc('day',validita_inizio) and
               (date_trunc('day',dataelaborazione)<=date_trunc('day',validita_fine) or validita_fine is null);

        strMessaggio :=' estraggo lo stato id da  siac_d_ordinativo_stato per codice Q. ';
        select ord_stato_id
          into strict v_ord_stato_id_q
          from siac_d_ordinativo_stato
         where
               ente_proprietario_id=enteproprietarioid and
               ord_stato_code='Q' and
               date_trunc('day',dataelaborazione)>=date_trunc('day',validita_inizio) and
               (date_trunc('day',dataelaborazione)<=date_trunc('day',validita_fine) or validita_fine is null);

    exception
         when NO_DATA_FOUND then
         messaggioRisultato:=strMessaggioFinale||strMessaggio||' record non trovato.';
         numerorecordinseriti:=-1;
         return;

         when others  THEN
            raise notice '%  % ERRORE DB: % %',strMessaggioFinale,strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 500);
            messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
            numerorecordinseriti:=-1;
            return;
    end;

    --lista Attributi
      begin
        strMessaggio :=' estraggo identificativo attributo attr_code= flagAllegatoCartaceo.';
        select siac_t_attr.attr_id
          into strict v_attr_id_flagAllegatoCartaceo
          from siac_t_attr
         where siac_t_attr.ente_proprietario_id=enteproprietarioid
           and siac_t_attr.attr_code='flagAllegatoCartaceo'
           and date_trunc('day',dataelaborazione)>=date_trunc('day',siac_t_attr.validita_inizio)
           and (date_trunc('day',dataelaborazione)<=date_trunc('day',siac_t_attr.validita_fine) or siac_t_attr.validita_fine is null);

          strMessaggio :=' estraggo identificativo attributo attr_code= NOTE_ORDINATIVO.';
        select siac_t_attr.attr_id
          into strict v_attr_id_note_ordinativo
          from siac_t_attr
         where siac_t_attr.ente_proprietario_id=enteproprietarioid 
           and siac_t_attr.attr_code='NOTE_ORDINATIVO' 
           and date_trunc('day',dataelaborazione)>=date_trunc('day',siac_t_attr.validita_inizio)
           and (date_trunc('day',dataelaborazione)<=date_trunc('day',siac_t_attr.validita_fine) or siac_t_attr.validita_fine is null);

          strMessaggio :=' estraggo identificativo attributo attr_code= cup.';
        select siac_t_attr.attr_id
          into strict v_attr_id_cup
          from siac_t_attr
         where siac_t_attr.ente_proprietario_id=enteproprietarioid
           and siac_t_attr.attr_code='cup' 
           and date_trunc('day',dataelaborazione)>=date_trunc('day',siac_t_attr.validita_inizio)
           and (date_trunc('day',dataelaborazione)<=date_trunc('day',siac_t_attr.validita_fine) or siac_t_attr.validita_fine is null);

          strMessaggio :=' estraggo identificativo attributo attr_code= cig.';
        select siac_t_attr.attr_id
          into strict v_attr_id_cig
          from siac_t_attr
         where siac_t_attr.ente_proprietario_id=enteproprietarioid
           and siac_t_attr.attr_code='cig'
           and date_trunc('day',dataelaborazione)>=date_trunc('day',siac_t_attr.validita_inizio)
           and (date_trunc('day',dataelaborazione)<=date_trunc('day',siac_t_attr.validita_fine) or siac_t_attr.validita_fine is null);

      exception
           when NO_DATA_FOUND then
           messaggioRisultato:=strMessaggioFinale||strMessaggio||' record non trovato.';
           numerorecordinseriti:=-1;
           return;

           when others  THEN
              raise notice '%  % ERRORE DB: % %',strMessaggioFinale,strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 500);
              messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
              numerorecordinseriti:=-1;
              return;
      end;

    --fine lista attributi
    begin 
        strMessaggio:='Lettura classificatore tipo_code PDC_V .';
        select tipoPdcFin.classif_tipo_id into strict v_classif_tipo_id_pdc
          from siac_d_class_tipo tipoPdcFin
         where tipoPdcFin.ente_proprietario_id=enteProprietarioId
           and tipoPdcFin.classif_tipo_code='PDC_V'
           and tipoPdcFin.data_cancellazione is null
           and date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFin.validita_inizio)
           and (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPdcFin.validita_fine) or tipoPdcFin.validita_fine is null);
          
        strMessaggio:='Lettura classificatore tipo_code TRANSAZIONE_UE_SPESA .';
        select tipoPdcFin.classif_tipo_id into strict v_classif_tipo_id_tra
          from siac_d_class_tipo tipoPdcFin
         where tipoPdcFin.ente_proprietario_id=enteProprietarioId
           and tipoPdcFin.classif_tipo_code='TRANSAZIONE_UE_SPESA'
           and tipoPdcFin.data_cancellazione is null
           and date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFin.validita_inizio)
           and (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPdcFin.validita_fine) or tipoPdcFin.validita_fine is null);

        strMessaggio:='Lettura classificatore tipo_code RICORRENTE_SPESA .';
        select tipoPdcFin.classif_tipo_id into strict v_classif_tipo_id_sp_ri
          from siac_d_class_tipo tipoPdcFin
         where tipoPdcFin.ente_proprietario_id=enteProprietarioId
           and tipoPdcFin.classif_tipo_code='RICORRENTE_SPESA'
           and tipoPdcFin.data_cancellazione is null
           and date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFin.validita_inizio)
           and (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPdcFin.validita_fine) or tipoPdcFin.validita_fine is null);

        strMessaggio:='Lettura classificatore tipo_code PERIMETRO_SANITARIO_SPESA .';
        select tipoPdcFin.classif_tipo_id into strict v_classif_tipo_id_pesa
          from siac_d_class_tipo tipoPdcFin
         where tipoPdcFin.ente_proprietario_id=enteProprietarioId
           and tipoPdcFin.classif_tipo_code='PERIMETRO_SANITARIO_SPESA'
           and tipoPdcFin.data_cancellazione is null
           and date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFin.validita_inizio)
           and (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPdcFin.validita_fine) or tipoPdcFin.validita_fine is null);

        strMessaggio:='Lettura classificatore tipo_code POLITICHE_REGIONALI_UNITARIE .';
        select tipoPdcFin.classif_tipo_id into strict v_classif_tipo_id_pore
          from siac_d_class_tipo tipoPdcFin
         where tipoPdcFin.ente_proprietario_id=enteProprietarioId
           and tipoPdcFin.classif_tipo_code='POLITICHE_REGIONALI_UNITARIE'
           and tipoPdcFin.data_cancellazione is null
           and date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFin.validita_inizio)
           and (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPdcFin.validita_fine) or tipoPdcFin.validita_fine is null);
          
        strMessaggio:='Lettura classificatore tipo_code SIOPE_SPESA_I .';
        select tipoPdcFin.classif_tipo_id into strict v_classif_tipo_id_siope
          from siac_d_class_tipo tipoPdcFin
         where tipoPdcFin.ente_proprietario_id=enteProprietarioId
           and tipoPdcFin.classif_tipo_code='SIOPE_SPESA_I'
           and tipoPdcFin.data_cancellazione is null
           and date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFin.validita_inizio)
           and (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPdcFin.validita_fine) or tipoPdcFin.validita_fine is null);

      exception
           when NO_DATA_FOUND then
           messaggioRisultato:=strMessaggioFinale||strMessaggio||' record non trovato.';
           numerorecordinseriti:=-1;
           return;

           when others  THEN
              raise notice '%  % ERRORE DB: % %',strMessaggioFinale,strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 500);
              messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
              numerorecordinseriti:=-1;
              return;
      end;

    --------------------------
    --INIZIO DEL LOOP---------
    --------------------------
    strMessaggio:='Lettura record migr_ordinativo_spesa.';

    for migrRecord IN
        (
         select
           migr_ordinativo_id
          ,ordinativo_id
          ,anno_esercizio
          ,numero_ordinativo
          ,numero_capitolo
          ,numero_articolo
          ,numero_ueb
          ,descrizione
          ,data_emissione
          ,data_annullamento
          ,data_riduzione
          ,data_scadenza
          ,data_spostamento
          ,data_trasmissione
          ,stato_operativo
          ,codice_distinta
          ,codice_bollo
          ,codice_commissione
          ,codice_conto_corrente
          ,codice_soggetto
          ,codice_modpag
          ,anno_provvedimento
          ,numero_provvedimento
          ,tipo_provvedimento
          ,sac_provvedimento
          ,oggetto_provvedimento
          ,note_provvedimento
          ,stato_provvedimento
          ,flag_allegato_cart
          ,note_tesoriere
          ,comunicazioni_tes
          ,cup
          ,cig
          ,firma_ord_data
          ,firma_ord
          ,quietanza_numero
          ,quietanza_data
          ,quietanza_importo
          ,quietanza_codice_cro
          ,storno_quiet_numero
          ,storno_quiet_data
          ,storno_quiet_importo
          ,cast_competenza
          ,cast_cassa
          ,cast_emessi
          ,utente_creazione
          ,utente_modifica
          ,classificatore_1
          ,classificatore_2 
          ,classificatore_3 
          ,pdc_finanziario 
          ,transazione_ue_spesa 
          ,spesa_ricorrente 
          ,perimetro_sanitario_spesa 
          ,politiche_regionali_unitarie 
          ,pdc_economico_patr 
          ,cofog 
          ,siope_spesa 
          ,ente_proprietario_id 
          ,fl_elab
          ,data_creazione
         from
             migr_ordinativo_spesa m
         where m.ente_proprietario_id=enteproprietarioid
               and m.fl_elab='N'
               and m.migr_ordinativo_id >= idmin
               and m.migr_ordinativo_id <= idmax
         order by m.migr_ordinativo_id
        )
    LOOP
        strDettaglioScarto := null;
        strMessaggioScarto := null;
        v_ordId := 0;
        v_codbollo_id := 0; 
        v_contotes_id := 0;
        v_notete_id := 0;
        v_dist_id := 0; 
        v_elem_id := 0; 
        v_attoamm_id := 0;
        v_anno_liquidazione := 0;
        v_num_liquidazione := 0;
        v_ord_stato_id := 0;
        v_soggetto_id := 0;
        v_liq_id := 0; 
        migr_modpag_id_principale := 0;
        modpag_id_principale := 0;
        mmdp_sede_secondaria := null;
        mmdp_cessione := null;
        migr_soggetto_id_principale := 0;
        soggetto_id_principale := 0;
        migr_modpag_id_altra := 0;
        modpag_id_altra  := 0;
        soggetto_id_altro := 0;

        strMessaggio:='Ricerca Codice bollo per codice: '|| migrRecord.codice_bollo||'.';

        select codbollo_id 
          into v_codbollo_id 
          from siac_d_codicebollo cob
         where ente_proprietario_id = enteProprietarioId 
           and data_cancellazione is null 
           and codbollo_code= migrRecord.codice_bollo
           and date_trunc('day',dataelaborazione)>=date_trunc('day',cob.validita_inizio) 
           and (date_trunc('day',dataelaborazione)<=date_trunc('day',cob.validita_fine) or cob.validita_fine is null);

        if v_codbollo_id is null then
            strMessaggioScarto := 'Codice bollo non presente in archivio cod bollo--> '|| migrRecord.codice_bollo||
                                  ' Ordinativo --> '||migrRecord.numero_ordinativo||'/'||annobilancio||'/'||migrRecord.numero_capitolo||'/'||migrRecord.numero_articolo||'/'||migrRecord.numero_ueb||'.';
        end if;

        strMessaggio:='Ricerca Codice commissione per codice: '|| migrRecord.codice_commissione||'.';
        
        select comm_tipo_id 
          into v_comm_tipo_id 
          from siac_d_commissione_tipo
         where ente_proprietario_id = enteProprietarioId 
           and data_cancellazione is null 
           and comm_tipo_code= migrRecord.codice_commissione
           and date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio) 
           and (date_trunc('day',dataElaborazione)<=date_trunc('day',validita_fine) or validita_fine is null);

        if v_comm_tipo_id is null then
            strMessaggioScarto := 'Codice commissione non presente in archivio migrRecord.codice commissione--> '|| migrRecord.codice_commissione||
                                  ' Ordinativo --> '||migrRecord.numero_ordinativo||'/'||annobilancio||'/'||migrRecord.numero_capitolo||'/'||migrRecord.numero_articolo||'/'||migrRecord.numero_ueb||'.';
        end if;

        strMessaggio:='Ricerca Codice tesoreria per codice: '|| migrRecord.codice_conto_corrente||'.';
        
        select contotes_id 
          into v_contotes_id 
          from siac_d_contotesoreria
         where ente_proprietario_id =  enteProprietarioId 
           and data_cancellazione is null 
           and contotes_code=migrRecord.codice_conto_corrente
           and date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio) 
           and (date_trunc('day',dataElaborazione)<=date_trunc('day',validita_fine) or validita_fine is null);

        if v_contotes_id is null then
            strMessaggioScarto := 'Codice conto tesoreria non presente in archivio migrRecord.conto tesoreria--> '|| COALESCE(migrRecord.codice_conto_corrente, 'NULL')||
                                  ' Ordinativo --> '||migrRecord.numero_ordinativo||'/'||annobilancio||'/'||migrRecord.numero_capitolo||'/'||migrRecord.numero_articolo||'/'||migrRecord.numero_ueb||'.';
        end if;

        strMessaggio:='Ricerca note tesoriere per codice: '|| migrRecord.note_tesoriere||'.';
        
        select notetes_id 
          into v_notete_id 
          from siac_d_note_tesoriere
         where ente_proprietario_id = enteProprietarioId 
           and data_cancellazione is null 
           and notetes_code=migrRecord.note_tesoriere
           and date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio) 
           and (date_trunc('day',dataElaborazione)<=date_trunc('day',validita_fine) or validita_fine is null);

        if v_notete_id is null then
            strMessaggioScarto := 'Note tesoriere non presente in archivio migrRecord.note_tesoriere--> ' || COALESCE(migrRecord.note_tesoriere, 'NULL')||
                                  ' Ordinativo --> '||migrRecord.numero_ordinativo||'/'||annobilancio||'/'||migrRecord.numero_capitolo||'/'||migrRecord.numero_articolo||'/'||migrRecord.numero_ueb||'.';
        end if;
     
        strMessaggio:='Ricerca distinta per codice: '|| migrRecord.codice_distinta||'.';
        
        select dist_id 
          into v_dist_id 
          from siac_d_distinta
         where ente_proprietario_id = enteProprietarioId 
           and data_cancellazione is null 
           and dist_code=migrRecord.codice_distinta
           and date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio) 
           and (date_trunc('day',dataElaborazione)<=date_trunc('day',validita_fine) or validita_fine is null);

        if v_dist_id is null then
            strMessaggioScarto := 'Distinta non presente in archivio migrRecord.distinta--> '|| migrRecord.codice_distinta||
                                  ' Ordinativo --> '||migrRecord.numero_ordinativo||'/'||annobilancio||'/'||migrRecord.numero_capitolo||'/'||migrRecord.numero_articolo||'/'||migrRecord.numero_ueb||'.';
        end if;

        if strMessaggioScarto is not null then
            insert into migr_ordinativo_spesa_scarto
                (migr_ordinativo_id, numero_ordinativo, anno_esercizio, motivo_scarto, ente_proprietario_id)
            values
                (migrRecord.migr_ordinativo_id, migrRecord.numero_ordinativo, migrRecord.anno_esercizio,
                 strMessaggioScarto, enteProprietarioId);
        else 
            -- inserimento dell'ordinativo
            strMessaggio:='Inserimento dell''Ordinativo (Mandato) : '||migrRecord.anno_esercizio||'/'||migrRecord.numero_ordinativo||'.';
            
            INSERT INTO siac_t_ordinativo (
                ord_anno ,
                ord_numero ,
                ord_desc ,
                ord_tipo_id ,
                ord_cast_cassa ,
                ord_cast_competenza ,
                ord_cast_emessi ,
                ord_emissione_data ,
                ord_riduzione_data ,
                ord_spostamento_data  ,
                ord_variazione_data  ,
                ord_beneficiariomult,
                codbollo_id  ,
                bil_id ,
                comm_tipo_id  ,
                contotes_id  ,
                notetes_id  ,
                dist_id  ,
                validita_inizio ,
                validita_fine  ,
                ente_proprietario_id ,
                data_creazione ,
                --data_modifica ,
                --data_cancellazione ,
                login_operazione ,
                login_creazione ,
                login_modifica ,
                login_cancellazione ,
                ord_trasm_oil_data
            ) VALUES(
                migrRecord.anno_esercizio::integer ,
                migrRecord.numero_ordinativo ,
                migrRecord.descrizione , 
                v_ord_tipo_id ,
                migrRecord.cast_cassa ,
                migrRecord.cast_competenza ,
                migrRecord.cast_emessi ,
                to_timestamp(migrRecord.data_emissione,'dd/mm/yyyy'),
                to_timestamp(migrRecord.data_riduzione,'dd/mm/yyyy'),
                to_timestamp(migrRecord.data_spostamento,'dd/mm/yyyy'),
                null, 
                false,
                v_codbollo_id , 
                bilancioid ,
                v_comm_tipo_id  , 
                v_contotes_id  , 
                v_notete_id  ,
                v_dist_id  ,
                dataInizioVal ,
                null  , 
                enteproprietarioid , 
                clock_timestamp() , 
                --null ,
                --null ,
                loginoperazione,
                migrRecord.utente_creazione, 
                migrRecord.utente_modifica, 
                null, --login_cancellazione
                to_timestamp(migrRecord.data_trasmissione,'dd/mm/yyyy')
            ) returning ord_id into v_ordid;
        
        end if;

        if v_ordid is not null then
        
            --INIZIO INSERIMENTO IN TABELLE DI RELAZIONE
            v_scarto := 0;

            --estraggo il capitolo per associarlo all'ordinativo
            strMessaggio:='Ricerca estraggo il capitolo: ' ||annobilancio||'/'||migrRecord.numero_capitolo||'/'||migrRecord.numero_articolo||'/'||migrRecord.numero_ueb||'.';

            select elem_id 
              into strict v_elem_id
              from siac_t_bil_elem,siac_d_bil_elem_tipo
             where siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id 
               and siac_d_bil_elem_tipo.elem_tipo_code='CAP-UG' 
               and siac_t_bil_elem.elem_code=migrRecord.numero_capitolo::varchar 
               and siac_t_bil_elem.elem_code2=migrRecord.numero_articolo::varchar 
               and siac_t_bil_elem.elem_code3=migrRecord.numero_ueb::varchar 
               and siac_t_bil_elem.bil_id=bilancioid 
               and siac_t_bil_elem.ente_proprietario_id = siac_t_bil_elem.ente_proprietario_id
               and siac_t_bil_elem.ente_proprietario_id = enteproprietarioid 
               and siac_d_bil_elem_tipo.ente_proprietario_id = enteproprietarioid 
               and date_trunc('day',dataElaborazione)>=date_trunc('day',siac_t_bil_elem.validita_inizio) 
               and (date_trunc('day',dataElaborazione)<=date_trunc('day',siac_t_bil_elem.validita_fine) or siac_t_bil_elem.validita_fine is null) 
               and date_trunc('day',dataElaborazione)>=date_trunc('day',siac_d_bil_elem_tipo.validita_inizio) 
               and (date_trunc('day',dataElaborazione)<=date_trunc('day',siac_d_bil_elem_tipo.validita_fine) or siac_d_bil_elem_tipo.validita_fine is null);
          
            if v_elem_id is null then
                select 1 
                  into v_scarto 
                  from migr_ordinativo_spesa_scarto 
                 where migr_ordinativo_spesa_scarto.migr_ordinativo_id =migrRecord.migr_ordinativo_id;
                 
                if v_scarto is null then
                    strMessaggioScarto := 'capitolo non migrato.';
                    strDettaglioScarto := '[capitolo]['||annobilancio||'/'||migrRecord.numero_capitolo||'/'||migrRecord.numero_articolo||'/'||migrRecord.numero_ueb||'].'||
                                          'Ordinativo -- >'||migrRecord.numero_ordinativo||||'.';
                end if;
            else
                insert into siac_r_ordinativo_bil_elem 
                    (ord_id ,elem_id ,validita_inizio,validita_fine , ente_proprietario_id , data_creazione ,login_operazione)
                values
                    (v_ordid , v_elem_id , dataInizioVal,null , enteproprietarioid ,clock_timestamp() ,loginoperazione);
            end if;

            ----------------------------definizione atto amministrativo da collegare all'ordinativo MANDATI ----------------------------------------------------------------------

            strMessaggio:='Ricerca atto amministrativo: '||migrRecord.anno_esercizio||'/'||migrRecord.numero_ordinativo||'/'||TIPO_ORD||'.';

            select siac_r_liquidazione_atto_amm.attoamm_id, migr_liquidazione.anno_esercizio, migr_liquidazione.numero_liquidazione
              into v_attoamm_id, v_anno_liquidazione, v_num_liquidazione 
              from migr_liquidazione,
                   siac_r_migr_liquidazione_t_liquidazione ,
                   siac_r_liquidazione_atto_amm
             where
                   migr_liquidazione.migr_liquidazione_id =siac_r_migr_liquidazione_t_liquidazione.migr_liquidazione_id
               and siac_r_migr_liquidazione_t_liquidazione.liquidazione_id = siac_r_liquidazione_atto_amm.liquidazione_id
               and migr_liquidazione.numero_liquidazione in  
                  (select f.numero_liquidazione 
                     from migr_ordinativo_spesa_ts f
                    where f.ente_proprietario_id=enteproprietarioid 
                      and f.ordinativo_id=migrRecord.ordinativo_id)
               and migr_liquidazione.anno_esercizio = migrRecord.anno_esercizio
               and migr_liquidazione.ente_proprietario_id= enteproprietarioid
               and siac_r_migr_liquidazione_t_liquidazione.ente_proprietario_id= enteproprietarioid
               and siac_r_liquidazione_atto_amm.ente_proprietario_id= enteproprietarioid
               and date_trunc('day',dataElaborazione)>=date_trunc('day',siac_r_liquidazione_atto_amm.validita_inizio)
               and (date_trunc('day',dataElaborazione)<date_trunc('day',siac_r_liquidazione_atto_amm.validita_fine) or siac_r_liquidazione_atto_amm.validita_fine is null);

            if v_attoamm_id is null THEN
                select siac_r_liquidazione_atto_amm.attoamm_id 
                  into v_attoamm_id 
                  from migr_liquidazione, siac_r_migr_liquidazione_t_liquidazione, siac_r_liquidazione_movgest ,
                       siac_r_movgest_ts_atto_amm
                 where
                       migr_liquidazione.migr_liquidazione_id =siac_r_migr_liquidazione_t_liquidazione.migr_liquidazione_id
                   and siac_r_migr_liquidazione_t_liquidazione.liquidazione_id = siac_r_liquidazione_movgest.liq_id
                   and siac_r_liquidazione_movgest.movgest_ts_id=  siac_r_movgest_ts_atto_amm.movgest_ts_id 
                   and migr_liquidazione.numero_liquidazione in  
                       (select f.numero_liquidazione 
                          from migr_ordinativo_spesa_ts f
                         where f.ente_proprietario_id=enteproprietarioid 
                           and f.ordinativo_id=migrRecord.ordinativo_id)
                   and migr_liquidazione.anno_esercizio = migrRecord.anno_esercizio
                   and migr_liquidazione.ente_proprietario_id= enteproprietarioid
                   and siac_r_migr_liquidazione_t_liquidazione.ente_proprietario_id= enteproprietarioid
                   and siac_r_liquidazione_movgest.ente_proprietario_id= enteproprietarioid
                   and siac_r_movgest_ts_atto_amm.ente_proprietario_id= enteproprietarioid
                   and date_trunc('day',dataElaborazione)>=date_trunc('day',siac_r_liquidazione_movgest.validita_inizio)
                   and (date_trunc('day',dataElaborazione)<date_trunc('day',siac_r_liquidazione_movgest.validita_fine) or siac_r_liquidazione_movgest.validita_fine is null)
                   and date_trunc('day',dataElaborazione)>=date_trunc('day',siac_r_movgest_ts_atto_amm.validita_inizio)
                   and (date_trunc('day',dataElaborazione)<date_trunc('day',siac_r_movgest_ts_atto_amm.validita_fine) or siac_r_movgest_ts_atto_amm.validita_fine is null);
            end if;
            
            if v_attoamm_id is null then
                select 1 
                  into v_scarto 
                  from migr_ordinativo_spesa_scarto
                 where migr_ordinativo_scarto_id=migrRecord.migr_ordinativo_id;
                        
                if v_scarto is null then
                    strMessaggioScarto := 'Atto Amministrativo non migrato.';
                    strDettaglioScarto := '[ordinativo]['||migrRecord.anno_esercizio||'/'||migrRecord.numero_ordinativo||'/'||TIPO_ORD'].';
                end if;  
            else              
                strMessaggio:='Inserimento relazione tra ordinativo e Atto Amministrativo collegato.'; 

                insert into siac_r_ordinativo_atto_amm 
                    (ord_id ,attoamm_id ,validita_inizio ,validita_fine,ente_proprietario_id ,data_creazione,login_operazione)
                values
                    (v_ordid ,v_attoamm_id ,dataInizioVal ,null ,enteproprietarioid ,clock_timestamp() ,loginoperazione);

                if migrRecord.storno_quiet_numero is not null  
                    AND  migrRecord.storno_quiet_data is not null  
                    AND migrRecord.storno_quiet_importo is not null THEN
                    
                    strMessaggio:='Inserimento relazione tra ordinativo e storno collegato (se presente).'; 

                    -- inserimento nella siac_r_ordinativo_storno
                    insert into siac_r_ordinativo_storno 
                        (ord_id ,ord_storno_data ,ord_storno_numero ,ord_storno_importo , oil_ricevuta_id , validita_inizio ,
                         validita_fine ,ente_proprietario_id ,data_creazione ,login_operazione)
                    values
                        (v_ordid ,migrRecord.storno_quiet_data, migrRecord.storno_quiet_numero,migrRecord.storno_quiet_importo, 
                         null , validita_inizio ,null , enteproprietarioid ,data_creazione ,loginoperazione);
                end if;
            end if;

            ----------------------------FINE definizione atto amministrativo da collegare all'ordinativo----------------------------------------------------------------------
            
            if strMessaggioScarto is not null then
                insert into migr_ordinativo_spesa_scarto
                    (migr_ordinativo_id, numero_ordinativo, anno_esercizio, motivo_scarto, ente_proprietario_id)
                values
                    (migrRecord.migr_ordinativo_id, migrRecord.numero_ordinativo, migrRecord.anno_esercizio, strMessaggioScarto||strDettaglioScarto,
                     enteProprietarioId);
            end if;

            if v_attoamm_id is not null then
                strMessaggio:='Inserimento relazioni tra ordinativo e suoi attributi.'; 
                --------------------- INIZIO ATTRIBUTI
                if migrRecord.flag_allegato_cart is not null then
                    strMessaggio:=strMessaggio||'Inserimento attributo FLAG_ALLEGATO_CART.'; 
                    insert into siac_r_ordinativo_attr 
                        (ord_id,attr_id, tabella_id, "boolean",percentuale,testo,numerico,validita_inizio,validita_fine,ente_proprietario_id,
                         data_creazione,login_operazione)
                    VALUES
                        (v_ordid,v_attr_id_flagAllegatoCartaceo,null,migrRecord.flag_allegato_cart::boolean,null,null,null,dataInizioVal,
                         null, enteproprietarioid,clock_timestamp(),loginoperazione);
                end if;

                if migrRecord.comunicazioni_tes is not null then
                    strMessaggio:=strMessaggio||'Inserimento attributo COMUNICAZIONI_TES.'; 
                    insert into siac_r_ordinativo_attr 
                        (ord_id,attr_id, tabella_id, "boolean",percentuale,testo,numerico,validita_inizio,validita_fine,ente_proprietario_id,
                         data_creazione,login_operazione)
                    VALUES
                        (v_ordid,v_attr_id_note_ordinativo,null,null,null,migrRecord.comunicazioni_tes,null,dataInizioVal,
                         null, enteproprietarioid,clock_timestamp(),loginoperazione);
                end if;

                if migrRecord.cup is not null then
                    strMessaggio:=strMessaggio||'Inserimento attributo CUP.'; 
                    insert into siac_r_ordinativo_attr 
                        (ord_id,attr_id, tabella_id, "boolean",percentuale,testo,numerico,validita_inizio,validita_fine,ente_proprietario_id,
                         data_creazione,login_operazione)
                    VALUES
                        (v_ordid,v_attr_id_cup,null,null,null,migrRecord.cup,null,dataInizioVal,null, enteproprietarioid,clock_timestamp(),
                         loginoperazione);
                end if;

                if migrRecord.cig is not null then
                    strMessaggio:=strMessaggio||'Inserimento attributo CIG.'; 
                    insert into siac_r_ordinativo_attr 
                        (ord_id,attr_id, tabella_id, "boolean",percentuale,testo,numerico,validita_inizio,validita_fine,ente_proprietario_id,
                         data_creazione,login_operazione)
                    VALUES(v_ordid,v_attr_id_cig,null,null,null,migrRecord.cig,null,dataInizioVal,null, enteproprietarioid,clock_timestamp(),
                           loginoperazione);
                end if;
                --------------- FINE ATTRIBUTI
                
                strMessaggio:='Inserimento relazione tra ordinativo e stato (I,T,F,Q,A).migr_ordinativo_id='||migrRecord.migr_ordinativo_id||'.';    
                
                select ord_stato_id
                  into v_ord_stato_id
                  from siac_d_ordinativo_stato
                 where
                       ente_proprietario_id=enteproprietarioid 
                   and ord_stato_code=migrRecord.stato_operativo 
                   and date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
                   and (date_trunc('day',dataElaborazione)<=date_trunc('day',validita_fine) or validita_fine is null);

                if v_ord_stato_id is null then
                    messaggiorisultato:=strMessaggio||' STATO ORDINATIVO NON PRESENTE per ord_stato_code = '|| COALESCE(migrRecord.stato_operativo, 'NULL')||'.';
                    numerorecordinseriti:=-12;
                    return;
                else
                    if migrRecord.stato_operativo = 'I' THEN
                        if migrRecord.data_emissione is not null then
                            insert into siac_r_ordinativo_stato
                               (ord_id, ord_stato_id, validita_inizio, validita_fine, ente_proprietario_id, data_creazione, login_operazione)
                            values
                               (v_ordid, v_ord_stato_id_i, to_timestamp(migrRecord.data_emissione,'dd/mm/yyyy'), null,enteproprietarioid,clock_timestamp(),
                                loginoperazione);
                        end if;
                    end if;

                    if migrRecord.stato_operativo = 'T' THEN
                        -- se la data trasmissione è valorizzata inserisco lo stato trasmesso
                        if migrRecord.data_emissione is not null then
                            insert into siac_r_ordinativo_stato
                                (ord_id, ord_stato_id, validita_inizio, validita_fine, ente_proprietario_id, data_creazione, login_operazione)
                            values
                                (v_ordid, v_ord_stato_id_i, to_timestamp(migrRecord.data_emissione,'dd/mm/yyyy'),
                                 to_timestamp(migrRecord.data_trasmissione,'dd/mm/yyyy'), enteproprietarioid, clock_timestamp(), loginoperazione);
                        end if;
                             
                        if migrRecord.data_trasmissione is not null then
                            insert into siac_r_ordinativo_stato
                                (ord_id, ord_stato_id, validita_inizio, validita_fine, ente_proprietario_id, data_creazione, login_operazione)
                            values
                                (v_ordid, v_ord_stato_id_t, to_timestamp(migrRecord.data_trasmissione,'dd/mm/yyyy'), null, enteproprietarioid,
                                 clock_timestamp(), loginoperazione);
                        end if;
                    end if;
           
                    if migrRecord.stato_operativo = 'F' THEN
                        -- se la data firma è valorizzata inserisco lo stato relativo
                        if migrRecord.data_emissione is not null then
                            insert into siac_r_ordinativo_stato
                                (ord_id, ord_stato_id, validita_inizio, validita_fine, ente_proprietario_id, data_creazione, login_operazione)
                            values
                                (v_ordid, v_ord_stato_id_i, to_timestamp(migrRecord.data_emissione,'dd/mm/yyyy'),
                                 to_timestamp(migrRecord.data_trasmissione,'dd/mm/yyyy'), enteproprietarioid, clock_timestamp(), loginoperazione);
                        end if;

                        if migrRecord.data_trasmissione is not null then
                            insert into siac_r_ordinativo_stato
                                (ord_id, ord_stato_id, validita_inizio, validita_fine, ente_proprietario_id, data_creazione, login_operazione)
                            values
                                (v_ordid, v_ord_stato_id_t, to_timestamp(migrRecord.data_trasmissione,'dd/mm/yyyy'),
                                 to_timestamp(migrRecord.firma_ord_data,'dd/mm/yyyy'), enteproprietarioid, clock_timestamp(), loginoperazione );
                        end if;

                        if migrRecord.firma_ord_data is not null then
                            insert into siac_r_ordinativo_stato
                                (ord_id ,ord_stato_id , validita_inizio ,validita_fine ,ente_proprietario_id ,data_creazione ,login_operazione)
                            values
                                (v_ordid , v_ord_stato_id_f ,to_timestamp(migrRecord.firma_ord_data,'dd/mm/yyyy') ,null ,enteproprietarioid ,
                                 clock_timestamp() ,loginoperazione );

                            -- inserimento nella relazione ordinativo firma
                            insert into siac_r_ordinativo_firma 
                                (ord_id ,ord_firma_data ,ord_firma ,oil_ricevuta_id , validita_inizio ,validita_fine ,ente_proprietario_id ,
                                 data_creazione ,login_operazione)
                            values
                                (v_ordid , to_timestamp(migrRecord.firma_ord_data,'dd/mm/yyyy'),migrRecord.firma_ord ,NULL,dataInizioVal ,null , 
                                enteproprietarioid ,clock_timestamp() ,loginoperazione) ;
                        end if;
                    end if;
           
                    if migrRecord.stato_operativo = 'Q' THEN
                        --se la data quietanza è valorizzata inserisco lo stato relativo
                        if migrRecord.data_emissione is not null then
                            insert into siac_r_ordinativo_stato
                               (ord_id ,ord_stato_id , validita_inizio ,validita_fine ,ente_proprietario_id ,data_creazione ,login_operazione)
                            values
                               (v_ordid , v_ord_stato_id_i ,to_timestamp(migrRecord.data_emissione,'dd/mm/yyyy') ,
                                to_timestamp(migrRecord.data_trasmissione,'dd/mm/yyyy') ,enteproprietarioid ,clock_timestamp() ,loginoperazione );
                        end if;

                        if migrRecord.data_trasmissione is not null then
                            insert into siac_r_ordinativo_stato
                               (ord_id ,ord_stato_id , validita_inizio ,validita_fine ,ente_proprietario_id ,data_creazione ,login_operazione)
                            values
                               (v_ordid , v_ord_stato_id_t ,to_timestamp(migrRecord.data_trasmissione,'dd/mm/yyyy') ,
                                to_timestamp(migrRecord.firma_ord_data,'dd/mm/yyyy') ,enteproprietarioid ,clock_timestamp() ,loginoperazione );
                        end if;

                        if (migrRecord.firma_ord_data is not null) and 
                           (migrRecord.quietanza_data is not null)     then            
                            insert into siac_r_ordinativo_stato
                                (ord_id ,ord_stato_id , validita_inizio ,validita_fine ,ente_proprietario_id ,data_creazione ,login_operazione)
                            values
                                (v_ordid , v_ord_stato_id_f ,to_timestamp(migrRecord.firma_ord_data,'dd/mm/yyyy') ,
                                 to_timestamp(migrRecord.quietanza_data,'dd/mm/yyyy') ,enteproprietarioid ,clock_timestamp() ,loginoperazione );

                            insert into siac_r_ordinativo_firma 
                                (ord_id ,ord_firma_data ,ord_firma ,oil_ricevuta_id , validita_inizio ,validita_fine ,ente_proprietario_id ,
                                 data_creazione ,login_operazione)
                            values
                                (v_ordid , to_timestamp(migrRecord.firma_ord_data,'dd/mm/yyyy') ,migrRecord.firma_ord ,null,
                                 to_timestamp(migrRecord.quietanza_data,'dd/mm/yyyy'),dataInizioVal ,null , enteproprietarioid ,clock_timestamp() ,
                                 loginoperazione) ;
                        end if;  
              
                        if migrRecord.quietanza_data is not null then            
                            insert into siac_r_ordinativo_stato
                               (ord_id ,ord_stato_id , validita_inizio ,validita_fine ,ente_proprietario_id ,data_creazione ,login_operazione)
                            values
                               (v_ordid , v_ord_stato_id_f ,to_timestamp(migrRecord.quietanza_data,'dd/mm/yyyy') ,null ,enteproprietarioid ,
                                clock_timestamp() ,loginoperazione );
                        end if;
                    end if;
                       
                    if migrRecord.stato_operativo = 'A' THEN
                        --se la data annullamento è valorizzata inserisco lo stato relativo
                        if migrRecord.data_emissione is not null then
                            insert into siac_r_ordinativo_stato
                               (ord_id ,ord_stato_id , validita_inizio ,validita_fine ,ente_proprietario_id ,data_creazione ,login_operazione)
                            values
                               (v_ordid , v_ord_stato_id_i ,to_timestamp(migrRecord.data_emissione,'dd/mm/yyyy') ,
                                to_timestamp(migrRecord.data_annullamento,'dd/mm/yyyy') ,enteproprietarioid ,clock_timestamp() ,loginoperazione );
                        end if;

                        if migrRecord.data_trasmissione is not null then
                            insert into siac_r_ordinativo_stato
                                (ord_id ,ord_stato_id , validita_inizio ,validita_fine ,ente_proprietario_id ,data_creazione ,login_operazione)
                            values
                                (v_ordid , v_ord_stato_id_t ,to_timestamp(migrRecord.data_trasmissione,'dd/mm/yyyy') ,
                                 to_timestamp(migrRecord.data_annullamento,'dd/mm/yyyy'),enteproprietarioid ,clock_timestamp() ,loginoperazione );
                        end if;

                        if (migrRecord.firma_ord_data is not null) and 
                           (migrRecord.quietanza_data is not null)     then            
                            insert into siac_r_ordinativo_stato
                                (ord_id ,ord_stato_id , validita_inizio ,validita_fine ,ente_proprietario_id ,data_creazione ,login_operazione)
                            values
                                (v_ordid , v_ord_stato_id_f ,to_timestamp(migrRecord.firma_ord_data,'dd/mm/yyyy') ,
                                 to_timestamp(migrRecord.quietanza_data,'dd/mm/yyyy') ,enteproprietarioid ,clock_timestamp() ,loginoperazione );

                            insert into siac_r_ordinativo_firma 
                                (ord_id ,ord_firma_data ,ord_firma ,oil_ricevuta_id , validita_inizio ,validita_fine ,ente_proprietario_id ,
                                 data_creazione ,login_operazione)
                            values
                                (v_ordid , to_timestamp(migrRecord.firma_ord_data,'dd/mm/yyyy') ,migrRecord.firma_ord ,null,
                                 to_timestamp(migrRecord.quietanza_data,'dd/mm/yyyy'),dataInizioVal ,null , enteproprietarioid ,clock_timestamp() ,
                                 loginoperazione) ;
                        end if;  
             
                        if migrRecord.data_annullamento is not null then            
                            insert into siac_r_ordinativo_stato
                               (ord_id ,ord_stato_id , validita_inizio ,validita_fine ,ente_proprietario_id ,data_creazione ,login_operazione)
                            values
                               (v_ordid , v_ord_stato_id_a ,to_timestamp(migrRecord.data_annullamento,'dd/mm/yyyy') ,null ,enteproprietarioid ,
                                clock_timestamp() ,loginoperazione );
                        end if;
                    end if;

                end if;        
                -- FINE condizione di inserimento nell'ordinativo stato

                ---CLASSIFICATORI -------------------
                  strMessaggio:='Inserimento classificatori dell''ordinativo.'; 
                if coalesce(migrRecord.classificatore_1)!=NVL_STR then
                    strMessaggio:=strMessaggio||'Classificatore '||migrRecord.classificatore_1||'.';
                    strToElab:=migrRecord.classificatore_1;

                    classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
                    classifDesc:=substring(strToElab from position(SEPARATORE in strToElab)+2 for char_length(strToElab)-position(SEPARATORE in strToElab));

                    select * 
                      into migrClassif 
                      from fnc_migr_classif(CL_CLASSIFICATORE_1,classifCode,classifDesc,enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);

                    if migrClassif.codiceRisultato=-1 then
                        RAISE EXCEPTION ' % ', migrClassif.messaggioRisultato;
                    end if;

                    strMessaggio:=strMessaggio||'Inserimento relazione '||CL_CLASSIFICATORE_1||' codice= '||classifCode||'.';

                    insert into siac_r_ordinativo_class
                        (classif_id ,ord_id ,validita_inizio ,validita_fine ,ente_proprietario_id ,data_cancellazione ,login_operazione )
                    values
                        (migrClassif.classifId ,v_ordid ,dataInizioVal ,null ,enteproprietarioid ,null ,loginOperazione );
                end if;

                if coalesce(migrRecord.classificatore_2)!=NVL_STR then
                    strMessaggio:=strMessaggio||'Classificatore '||migrRecord.classificatore_2||'.';
                    strToElab:=migrRecord.classificatore_2;

                    classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
                    classifDesc:=substring(strToElab from position(SEPARATORE in strToElab)+2 for char_length(strToElab)-position(SEPARATORE in strToElab));

                    select * 
                      into migrClassif 
                      from fnc_migr_classif(CL_CLASSIFICATORE_1,classifCode,classifDesc,enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);

                    if migrClassif.codiceRisultato=-1 then
                        RAISE EXCEPTION ' % ', migrClassif.messaggioRisultato;
                    end if;

                    strMessaggio:=strMessaggio||'Inserimento relazione '||CL_CLASSIFICATORE_2||' codice= '||classifCode||'.';

                    insert into siac_r_ordinativo_class
                        (classif_id ,ord_id ,validita_inizio ,validita_fine ,ente_proprietario_id ,data_cancellazione ,login_operazione)
                    values
                        (migrClassif.classifId ,v_ordid ,dataInizioVal ,null ,enteproprietarioid ,null ,loginOperazione);
                end if;

                if coalesce(migrRecord.classificatore_3)!=NVL_STR then
                    strMessaggio:=strMessaggio||'Classificatore '||migrRecord.classificatore_3||'.';
                    strToElab:=migrRecord.classificatore_3;

                    classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
                    classifDesc:=substring(strToElab from position(SEPARATORE in strToElab)+2 for char_length(strToElab)-position(SEPARATORE in strToElab));

                    select * 
                      into migrClassif 
                      from fnc_migr_classif(CL_CLASSIFICATORE_3,classifCode,classifDesc,enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);

                    if migrClassif.codiceRisultato=-1 then
                        RAISE EXCEPTION ' % ', migrClassif.messaggioRisultato;
                    end if;

                    strMessaggio:=strMessaggio||'Inserimento relazione '||CL_CLASSIFICATORE_3||' codice= '||classifCode||'.';

                    insert into siac_r_ordinativo_class
                        (classif_id ,ord_id ,validita_inizio ,validita_fine ,ente_proprietario_id ,data_cancellazione ,login_operazione)
                    values
                        (migrClassif.classifId ,v_ordid ,dataInizioVal ,null ,enteproprietarioid ,null ,loginOperazione);
                end if;
        
                /*
                if coalesce(migrRecord.classificatore_4)!=NVL_STR then
                    strMessaggio:=strMessaggio||'Classificatore '||migrRecord.classificatore_4||'.';
                    strToElab:=migrRecord.classificatore_4;

                    classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
                    classifDesc:=substring(strToElab from position(SEPARATORE in strToElab)+2 for char_length(strToElab)-position(SEPARATORE in strToElab));

                    select * 
                      into migrClassif 
                      from fnc_migr_classif(CL_CLASSIFICATORE_4,classifCode,classifDesc,enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);

                    if migrClassif.codiceRisultato=-1 then
                        RAISE EXCEPTION ' % ', migrClassif.messaggioRisultato;
                    end if;

                    strMessaggio:=strMessaggio||'Inserimento relazione '||CL_CLASSIFICATORE_4||' codice= '||classifCode||'.';

                    insert into siac_r_ordinativo_class
                        (classif_id ,ord_id ,validita_inizio ,validita_fine ,ente_proprietario_id ,data_cancellazione ,login_operazione )
                    values
                        (migrClassif.classifId ,v_ordid ,dataInizioVal ,null ,enteproprietarioid ,null ,loginOperazione);
                end if;
                */
  
                strMessaggio:='gestione piano dei conti V   '||migrRecord.pdc_finanziario||'.';
                select * 
                  into recClassif 
                  from fnc_getClassifid(v_ordid,v_classif_tipo_id_pdc ,'PDC_V'::varchar,migrRecord.pdc_finanziario, v_num_liquidazione::varchar,
                                        migrRecord.anno_esercizio::varchar,enteproprietarioid,loginOperazione);
                
                if recClassif.codResult <> 0 then
                    strMessaggio := strMessaggio||recClassif.strMessaggio;
                    strMessaggioScarto := recClassif.strMessaggioScarto;
                else
                    strMessaggio:='gestione TRANSAZIONE_UE_SPESA   '||migrRecord.transazione_ue_spesa||'.';    
                    select * 
                      into recClassif 
                      from fnc_getClassifid(v_ordid,v_classif_tipo_id_tra,'TRANSAZIONE_UE_SPESA'::varchar,migrRecord.transazione_ue_spesa  ,
                                               v_num_liquidazione::varchar,migrRecord.anno_esercizio::varchar,enteproprietarioid,loginOperazione);
                
                    if recClassif.codResult <> 0 then
                        strMessaggio := strMessaggio||recClassif.strMessaggio;
                        strMessaggioScarto := recClassif.strMessaggioScarto;
                    else
                        strMessaggio:='gestione RICORRENTE_SPESA   '||migrRecord.spesa_ricorrente||'.';    
                        select * 
                          into recClassif 
                          from fnc_getClassifid(v_ordid,v_classif_tipo_id_sp_ri ,'RICORRENTE_SPESA'::varchar ,migrRecord.spesa_ricorrente, 
                                                v_num_liquidazione::varchar, migrRecord.anno_esercizio::varchar,enteproprietarioid,loginOperazione);
                
                        if recClassif.codResult <> 0 then
                            strMessaggio := strMessaggio||recClassif.strMessaggio;
                            strMessaggioScarto := recClassif.strMessaggioScarto;
                        else
                            strMessaggio:='gestione PERIMETRO_SANITARIO_SPESA   '||migrRecord.perimetro_sanitario_spesa||'.';    
                            select * 
                              into recClassif 
                              from fnc_getClassifid(v_ordid,v_classif_tipo_id_pesa ,'PERIMETRO_SANITARIO_SPESA'::varchar ,
                                                    migrRecord.perimetro_sanitario_spesa, v_num_liquidazione::varchar, 
                                                    migrRecord.anno_esercizio::varchar, enteproprietarioid,loginOperazione);
                
                            if recClassif.codResult <> 0 then
                                strMessaggio := strMessaggio||recClassif.strMessaggio;
                                strMessaggioScarto := recClassif.strMessaggioScarto;
                            else
                                strMessaggio:='gestione POLITICHE_REGIONALI_UNITARIE   '||migrRecord.politiche_regionali_unitarie||'.';    
                                select * 
                                  into recClassif 
                                  from fnc_getClassifid(v_ordid,v_classif_tipo_id_pore ,'POLITICHE_REGIONALI_UNITARIE'::varchar,
                                                        migrRecord.politiche_regionali_unitarie, v_num_liquidazione::varchar,
                                                        migrRecord.anno_esercizio::varchar,enteproprietarioid,loginOperazione);
                
                                if recClassif.codResult <> 0 then
                                    strMessaggio := strMessaggio||recClassif.strMessaggio;
                                    strMessaggioScarto := recClassif.strMessaggioScarto;
                                else
                                    strMessaggio:='gestione SIOPE_SPESA_I   '||migrRecord.siope_spesa||'.';    
                                    select * 
                                      into recClassif 
                                      from fnc_getClassifid(v_ordid,v_classif_tipo_id_siope ,'SIOPE_SPESA_I'::varchar ,migrRecord.siope_spesa,
                                                             v_num_liquidazione::varchar,  migrRecord.anno_esercizio::varchar,enteproprietarioid,
                                                            loginOperazione);

                                    if recClassif.codResult <> 0 then
                                        strMessaggio := strMessaggio||recClassif.strMessaggio;
                                        strMessaggioScarto := recClassif.strMessaggioScarto;
                                    end if;
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
                
                ---------------------- FINE CLASSIFICATORI
                
                if strMessaggioScarto is not null then 
                    insert into migr_ordinativo_entrata_scarto
                        (migr_ordinativo_id, numero_ordinativo, anno_esercizio, motivo_scarto, ente_proprietario_id)
                    values
                        (migrRecord.migr_ordinativo_id, migrRecord.numero_ordinativo, migrRecord.anno_esercizio, 
                          strMessaggioScarto||strDettaglioScarto, enteProprietarioId);
                else

                    --SOGGETTO--------------------------------

                    strMessaggio:='Ricerca soggetto per codice: '||migrRecord.codice_soggetto||'.';
					
                    select mdp.migr_modpag_id, mdp.modpag_id, mdp.sede_secondaria,mdp.cessione,mdp.soggetto_id, ms.migr_soggetto_id
                      into migr_modpag_id_principale, modpag_id_principale, mmdp_sede_secondaria, mmdp_cessione, soggetto_id_principale, 
                             migr_soggetto_id_principale
                      from migr_modpag mdp
                     inner join  migr_soggetto ms on ( mdp.soggetto_id=ms.soggetto_id
                                                      and ms.ente_proprietario_id = enteProprietarioId
                                                      and ms.codice_soggetto=migrRecord.codice_soggetto)
                     where mdp.ente_proprietario_id = enteProprietarioId
                       and mdp.codice_modpag=migrRecord.codice_modpag
                       and coalesce(mdp.codice_modpag_del,'0') = coalesce(migrRecord.codice_modpag_del,'0')
                     order by mdp.cessione;
            
                    strMessaggio:='Ricerca Mdp altra valorizzata.';

                    select mdp_altra.migr_modpag_id ,mdp_altra.modpag_id,  mdp_altra.soggetto_id soggetto_altro
                      into migr_modpag_id_altra, modpag_id_altra, soggetto_id_altro
                      from migr_modpag mdp_altra,migr_soggetto ms_altro
                     where mdp_altra.ente_proprietario_id=enteProprietarioId
                       and mdp_altra.codice_modpag=migrRecord.codice_modpag
                       and coalesce(mdp_altra.codice_modpag_del,'0') = coalesce(migrRecord.codice_modpag_del,'0')
                       and mdp_altra.fl_genera_codice='S'
                       and ms_altro.codice_soggetto=migrRecord.codice_soggetto
                       and ms_altro.ente_proprietario_id = enteProprietarioId
                       and ms_altro.soggetto_id=mdp_altra.soggetto_id
                       and ms_altro.fl_genera_codice='S';   

                    if mmdp_sede_secondaria = 'N' then
                        strMessaggio:='Ricerca Soggetto, SS N';
                        select rss.soggetto_id 
                          into v_soggetto_id
                          from siac_r_migr_soggetto_soggetto rss
                         where rss.migr_soggetto_id = migr_soggetto_id_principale
                           and rss.ente_proprietario_id = enteProprietarioId;
                    else
                        strMessaggio:='Ricerca Soggetto, SS S';
                        select sr.soggetto_id_a 
                          into v_soggetto_id
                          from migr_modpag mdp, migr_sede_secondaria mss, siac_r_migr_sede_secondaria_rel_sede rss, siac_r_soggetto_relaz sr
                         where mdp.ente_proprietario_id = enteProprietarioId
                           and mdp.migr_modpag_id = migr_modpag_id_principale
                           and mss.ente_proprietario_id = enteProprietarioId
                           and mdp.sede_id=mss.sede_id
                           and rss.migr_sede_id=mss.migr_sede_id
                           and rss.soggetto_relaz_id=sr.soggetto_relaz_id;
                    end if;    
   
                    if v_soggetto_id is null then
                        select 1 
                          into v_scarto 
                          from migr_ordinativo_spesa_scarto 
                         where migr_ordinativo_scarto_id=migrRecord.migr_ordinativo_id;

                        if v_scarto is null then
                            strMessaggioScarto := 'Soggetto non migrato [codice_soggetto]['||migrRecord.codice_soggetto||'].';
                        end if;
                    else    
                        insert into siac_r_ordinativo_soggetto 
                           (ord_id ,soggetto_id , validita_inizio ,validita_fine , ente_proprietario_id ,data_creazione ,login_operazione)
                        values
                           (v_ordid, v_soggetto_id,dataInizioVal, null,enteproprietarioid ,clock_timestamp(),loginoperazione);
                    end if;
                    
                    if strMessaggioScarto is not null then
                        insert into migr_ordinativo_spesa_scarto
                           (migr_ordinativo_id, numero_ordinativo, anno_esercizio, motivo_scarto, ente_proprietario_id)
                        values
                           (migrRecord.migr_ordinativo_id, migrRecord.numero_ordinativo, migrRecord.anno_esercizio,
                            strMessaggioScarto, enteProprietarioId);
                    end if;
 
                    -- FINE SOGGETTO------------------------------------------------------------
   
                    if v_soggetto_id is not null then

                        if mmdp_cessione is null then
                            strMessaggio:='Ricerca Mdp, Cessione Null.';

                            if migr_modpag_id_altra is not null and migr_modpag_id_altra <> 0 then
                                select coalesce(rmdp.modpag_id,0) 
                                  into v_modpag_id
                                  from siac_r_migr_modpag_modpag rmdp
                                 where rmdp.migr_modpag_id=migr_modpag_id_altra
                                   and rmdp.ente_proprietario_id=enteProprietarioId;
                            else
                                select coalesce(rmdp.modpag_id,0) 
                                  into v_modpag_id
                                  from siac_r_migr_modpag_modpag rmdp
                                 where rmdp.migr_modpag_id=migr_modpag_id_principale
                                   and rmdp.ente_proprietario_id=enteProprietarioId;
                            end if;
                        else
                            strMessaggio:='Ricerca Mdp, Cessione '||COALESCE(mmdp_cessione, 'NULL')||'.';

                            if mmdp_cessione='CSI' then
                                select relMdp.modpag_id, relMdp.soggetto_relaz_id 
                                  into v_modpag_id, v_soggettoRelazId 
                                  from migr_relaz_soggetto mrs, siac_r_migr_relaz_soggetto_relaz rmr, siac_r_soggrel_modpag relMdp
                                 where mrs.soggetto_id_da = soggetto_id_principale --sogg.prin
                                   and mrs.soggetto_id_a = coalesce(soggetto_id_altro,mrs.soggetto_id_a) --sogg.altro
                                   and mrs.modpag_id_da=modpag_id_principale --mdp_principale
                                   and mrs.modpag_id_a= coalesce(modpag_id_altra,mrs.modpag_id_a)  --mdp_altra
                                   and mrs.ente_proprietario_id=enteProprietarioId
                                   and rmr.migr_relaz_id=mrs.migr_relaz_id
                                   and relMdp.soggetto_relaz_id=rmr.soggetto_relaz_id;
                            else
                                select relMdp.modpag_id 
                                  into v_modpag_id
                                  from migr_relaz_soggetto mrs, siac_r_migr_relaz_soggetto_relaz rmr, siac_r_soggrel_modpag relMdp
                                 where mrs.soggetto_id_a = soggetto_id_principale --sogg.prin
                                   and mrs.modpag_id_a=modpag_id_principale --mdp_principale
                                   and mrs.ente_proprietario_id=enteProprietarioId
                                   and rmr.migr_relaz_id=mrs.migr_relaz_id
                                   and relMdp.soggetto_relaz_id=rmr.soggetto_relaz_id;
                            end if;

                            -- da commentare se la mdp ritornera da impostare
                            if soggettoRelazId is not null then
                                v_modpag_id:=null;
                            end if;
                        end if;
                
                        if v_modpag_id is null then
                            select 1 
                              into v_scarto 
                              from migr_ordinativo_spesa_scarto 
                             where migr_ordinatovo_spesa_scarto_id=migrRecord.migr_ordinativo_id;

                            if v_scarto is null then
                                strMessaggioScarto := 'modalità pagamento  non migrata [codice_soggetto]['||migrRecord.codice_soggetto||'].';
                            end if;
                        else
                            insert into siac_r_ordinativo_modpag 
                               (ord_id ,modpag_id ,validita_inizio,validita_fine,ente_proprietario_id ,data_creazione ,login_operazione ,soggetto_relaz_id) 
                            values
                               (v_ordid ,v_modpag_id  ,dataInizioVal ,null ,enteproprietarioid  ,clock_timestamp() ,loginoperazione  ,v_soggettoRelazId);
                        end if;    

                        if strMessaggioScarto is not null then
                            insert into migr_ordinativo_spesa_scarto
                               (migr_ordinativo_id, numero_ordinativo, anno_esercizio, motivo_scarto, ente_proprietario_id)
                            values 
                               (migrRecord.migr_ordinativo_id, migrRecord.numero_ordinativo, migrRecord.anno_esercizio,
                                strMessaggioScarto, enteProprietarioId);
                        else
                            -----------FINALE
                            strmessaggio:= 'Insert into siac_r_migr_ordinativo_spesa_ordinativo.';
                            insert into siac_r_migr_ordinativo_spesa_ordinativo
                               (migr_ordinativo_id, ord_id, ente_proprietario_id)
                            values
                               (migrRecord.migr_ordinativo_id, v_ordid, enteProprietarioId);

                            -- valorizzare fl_elab = 'S'
                            update migr_ordinativo_spesa 
                               set fl_elab='S'
                             where ente_proprietario_id=enteProprietarioId
                               and migr_ordinativo_id = migrRecord.migr_ordinativo_id;

                            countRecordInseriti:=countRecordInseriti+1; 
                            strMessaggio:='.';
                        end if; 
                    end if;
                end if;
            end if;
        end if;
     
    end loop;

    messaggioRisultato:=strMessaggio||strMessaggioFinale||'Inserite '||countRecordInseriti||' ordinativi spesa.';
    numerorecordinseriti:= countRecordInseriti;
    return;

exception
    when RAISE_EXCEPTION THEN
        raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio, substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        numerorecordinseriti:=-1;
        return;
    when others  THEN
        raise notice '% % % ERRORE DB: % %',strMessaggioFinale,recId,strMessaggio,SQLSTATE, substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||recId||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        numerorecordinseriti:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;