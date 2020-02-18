/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create or replace function fnc_migr_ordinativo_entrata(
    enteproprietarioid integer,
    annobilancio varchar,
    loginoperazione varchar,
    dataelaborazione timestamp,
    idmin integer,
    idmax integer,
    out numerorecordinseriti integer,
    out messaggioRisultato varchar)
RETURNS record AS
$body$
DECLARE

   -- fnc_migr_ordinativo --> function che effettua il caricamento delgli ordinativi da migrare.
   -- leggendo da migr_ordinativo
   -- effettua inserimento di
   -- siac_t_ordinativo : tabella principale

    NVL_STR               CONSTANT VARCHAR:='';
    TIPO_ORD              CONSTANT VARCHAR:='I';
    SEPARATORE            CONSTANT varchar :='||';
    CL_CLASSIFICATORE_1   CONSTANT varchar :='CLASSIFICATORE_28';
    CL_CLASSIFICATORE_2   CONSTANT varchar :='CLASSIFICATORE_29';
    CL_CLASSIFICATORE_3   CONSTANT varchar :='CLASSIFICATORE_30';
    --CL_CLASSIFICATORE_4   CONSTANT varchar :='CLASSIFICATORE_28';
    
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
    v_notetes_id                    INTEGER := 0; -- pk tab. siac_d_note_tesoriere
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
    v_anno_accertamento             INTEGER := 0; -- per l'inserimento delle relazioni
    v_num_accertamento              INTEGER := 0; -- per l'inserimento delle relazioni
    v_attr_id_flagAllegatoCartaceo  INTEGER := 0; -- pk di siac_t_attr
    v_attr_id_note_ordinativo       INTEGER := 0; -- pk di siac_t_attr
    v_classif_tipo_id_pdc           INTEGER := 0; 
    v_classif_tipo_id_tra           INTEGER := 0; 
    v_classif_tipo_id_en_ri         INTEGER := 0; 
    v_classif_tipo_id_pesa          INTEGER := 0; 
    v_classif_tipo_id_siope         INTEGER := 0; 
    
BEGIN
    numerorecordinseriti:=0;
    messaggioRisultato:='';
    strMessaggioFinale:='Migrazione ordinativi di entrata.';

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
         select distinct 1 into strict countRecordDaMigrare from migr_ordinativo_entrata m
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
          
        strMessaggio:='Lettura classificatore tipo_code TRANSAZIONE_UE_ENTRATA .';
        select tipoPdcFin.classif_tipo_id into strict v_classif_tipo_id_tra
          from siac_d_class_tipo tipoPdcFin
         where tipoPdcFin.ente_proprietario_id=enteProprietarioId
           and tipoPdcFin.classif_tipo_code='TRANSAZIONE_UE_ENTRATA'
           and tipoPdcFin.data_cancellazione is null
           and date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFin.validita_inizio)
           and (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPdcFin.validita_fine) or tipoPdcFin.validita_fine is null);

        strMessaggio:='Lettura classificatore tipo_code RICORRENTE_ENTRATA .';
        select tipoPdcFin.classif_tipo_id into strict v_classif_tipo_id_en_ri
          from siac_d_class_tipo tipoPdcFin
         where tipoPdcFin.ente_proprietario_id=enteProprietarioId
           and tipoPdcFin.classif_tipo_code='RICORRENTE_ENTRATA'
           and tipoPdcFin.data_cancellazione is null
           and date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFin.validita_inizio)
           and (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPdcFin.validita_fine) or tipoPdcFin.validita_fine is null);

        strMessaggio:='Lettura classificatore tipo_code PERIMETRO_SANITARIO_ENTRATA .';
        select tipoPdcFin.classif_tipo_id into strict v_classif_tipo_id_pesa
          from siac_d_class_tipo tipoPdcFin
         where tipoPdcFin.ente_proprietario_id=enteProprietarioId
           and tipoPdcFin.classif_tipo_code='PERIMETRO_SANITARIO_ENTRATA'
           and tipoPdcFin.data_cancellazione is null
           and date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFin.validita_inizio)
           and (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPdcFin.validita_fine) or tipoPdcFin.validita_fine is null);

        strMessaggio:='Lettura classificatore tipo_code SIOPE_ENTRATA_I .';
        select tipoPdcFin.classif_tipo_id into strict v_classif_tipo_id_siope
          from siac_d_class_tipo tipoPdcFin
         where tipoPdcFin.ente_proprietario_id=enteProprietarioId
           and tipoPdcFin.classif_tipo_code='SIOPE_ENTRATA_I'
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
    strMessaggio:='Lettura record migr_ordinativo_entrata.';

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
          ,codice_conto_corrente
          ,codice_soggetto
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
          ,firma_ord_data
          ,firma_ord
          ,quietanza_numero
          ,quietanza_data
          ,quietanza_importo
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
          ,transazione_ue_entrata 
          ,entrata_ricorrente 
          ,perimetro_sanitario_entrata 
          ,pdc_economico_patr 
          ,siope_entrata 
          ,ente_proprietario_id 
          ,fl_elab
          ,data_creazione
         from
             migr_ordinativo_entrata m
         where m.ente_proprietario_id=enteproprietarioid
               and m.fl_elab='N'
               and m.migr_ordinativo_id >= idmin
               and m.migr_ordinativo_id <= idmax
         order by m.migr_ordinativo_id
        )
    LOOP
        strDettaglioScarto := null;
        strMessaggioScarto := null;
        --codRet := 0;
        v_ordId := 0;
        v_codbollo_id := 0;
        v_contotes_id := 0;
        v_notetes_id := 0;
        v_dist_id := 0;
        v_elem_id := 0;
        v_attoamm_id := 0;
        v_anno_accertamento := 0;
        v_num_accertamento := 0;
        v_ord_stato_id := 0;
         
        strMessaggio:='Ricerca Codice bollo per codice: '|| migrRecord.codice_bollo||'.';
        
        select codbollo_id 
          into v_codbollo_id
          from siac_d_codicebollo cob
         where ente_proprietario_id = enteproprietarioid 
           and data_cancellazione is null 
           and codbollo_code= migrRecord.codice_bollo
           and date_trunc('day',dataelaborazione)>=date_trunc('day',cob.validita_inizio) 
           and (date_trunc('day',dataelaborazione)<=date_trunc('day',cob.validita_fine) or cob.validita_fine is null);
              
        if v_codbollo_id is null then
            strMessaggioScarto := 'Codice bollo non presente in archivio cod bollo--> '|| migrRecord.codice_bollo||
                                  ' Ordinativo --> '||migrRecord.numero_ordinativo||'/'||annobilancio||'/'||migrRecord.numero_capitolo||'/'||migrRecord.numero_articolo||'/'||migrRecord.numero_ueb||'.';
        end if;

        strMessaggio:='Ricerca Codice tesoreria per codice: '||migrRecord.codice_conto_corrente||'.';

        select contotes_id 
          into v_contotes_id 
          from siac_d_contotesoreria
         where ente_proprietario_id =  enteproprietarioid 
           and data_cancellazione is null 
           and contotes_code=migrRecord.codice_conto_corrente
           and date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio) 
           and (date_trunc('day',dataElaborazione)<=date_trunc('day',validita_fine) or validita_fine is null);

        if v_contotes_id is null then
            strMessaggioScarto := 'Codice conto tesoreria non presente in archivio migrRecord.conto tesoreria--> '|| migrRecord.codice_conto_corrente||
                                  ' Ordinativo --> '||migrRecord.numero_ordinativo||'/'||annobilancio||'/'||migrRecord.numero_capitolo||'/'||migrRecord.numero_articolo||'/'||migrRecord.numero_ueb||'.';
        end if;

        strMessaggio:='Ricerca note tesoriere per codice: '||migrRecord.note_tesoriere||'.';
        
        select notetes_id 
          into v_notetes_id 
          from siac_d_note_tesoriere
         where ente_proprietario_id =  enteproprietarioid 
           and data_cancellazione is null 
           and notetes_code=migrRecord.note_tesoriere
           and date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio) 
           and (date_trunc('day',dataElaborazione)<=date_trunc('day',validita_fine) or validita_fine is null);
        
        if v_notetes_id is null then
            strMessaggioScarto := 'Note tesoriere non presente in archivio migrRecord.note_tesoriere--> '|| migrRecord.note_tesoriere||
                                  ' Ordinativo --> '||migrRecord.numero_ordinativo||'/'||annobilancio||'/'||migrRecord.numero_capitolo||'/'||migrRecord.numero_articolo||'/'||migrRecord.numero_ueb||'.';
        end if;

        strMessaggio:='Ricerca distinta per codice: '||migrRecord.codice_distinta||'.';
        
        select dist_id 
          into v_dist_id 
          from siac_d_distinta
         where ente_proprietario_id =  enteproprietarioid 
           and data_cancellazione is null 
           and dist_code=migrRecord.codice_distinta
           and date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio) 
           and (date_trunc('day',dataElaborazione)<=date_trunc('day',validita_fine) or validita_fine is null);

        if v_dist_id is null then
            strMessaggioScarto := 'Distinta non presente in archivio migrRecord.distinta--> '|| migrRecord.codice_distinta||
                                  ' Ordinativo --> '||migrRecord.numero_ordinativo||'/'||annobilancio||'/'||migrRecord.numero_capitolo||'/'||migrRecord.numero_articolo||'/'||migrRecord.numero_ueb||'.';
        end if;

        if strMessaggioScarto is not null then
            insert into migr_ordinativo_entrata_scarto
                (migr_ordinativo_id, numero_ordinativo, anno_esercizio, motivo_scarto, ente_proprietario_id)
            values
                (migrRecord.migr_ordinativo_id, migrRecord.numero_ordinativo, migrRecord.anno_esercizio,
                 strMessaggioScarto, enteProprietarioId);
        else 
            -- inserimento dell'ordinativo
            strMessaggio:='Inserimento dell''Ordinativo (Reversale) : '||migrRecord.anno_esercizio||'/'||migrRecord.numero_ordinativo||'.';
        
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
                null, --ord_variazione_data  ,
                false,-- da rivedere con sofia
                v_codbollo_id ,
                bilancioid ,
                null  ,
                v_contotes_id  ,
                v_notetes_id  ,
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
               and siac_d_bil_elem_tipo.elem_tipo_code='CAP-EG'
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
                  from migr_ordinativo_entrata_scarto 
                 where migr_ordinatovo_entrata_scarto_id=migrRecord.migr_ordinativo_id;
            
                if v_scarto is null then
                    strMessaggioScarto := 'capitolo non migrato.';
                    strDettaglioScarto := '[capitolo]['||annobilancio||'/'||migrRecord.numero_capitolo||'/'||migrRecord.numero_articolo||'/'||migrRecord.numero_ueb||'].'||
                                          'Ordinativo -- >'||migrRecord.numero_ordinativo||||'.';
                end if;
            else
                insert into siac_r_ordinativo_bil_elem 
                    (ord_id, elem_id, validita_inizio, validita_fine, ente_proprietario_id, data_creazione, login_operazione)
                values
                    (v_ordId, v_elem_id, dataInizioVal, null, enteproprietarioid, clock_timestamp(), loginoperazione);
            end if;

            ----------------------------definizione atto amministrativo da collegare all'ordinativo REVERSALI ----------------------------------------------------------------------

            strMessaggio:='Ricerca atto amministrativo: '||migrRecord.anno_esercizio||'/'||migrRecord.numero_ordinativo||'/'||TIPO_ORD||'.';
            
            select a.attoamm_id, d.anno_accertamento, d.numero_accertamento 
              into v_attoamm_id, v_anno_accertamento, v_num_accertamento
              from siac_r_movgest_ts_atto_amm a, 
                   siac_t_movgest b,
                   siac_t_movgest_ts c,
                   migr_ordinativo_entrata_ts d
             where d.ente_proprietario_id=enteproprietarioid
               and c.ente_proprietario_id=d.ente_proprietario_id
               and b.ente_proprietario_id=c.ente_proprietario_id
               and a.ente_proprietario_id=b.ente_proprietario_id
               and d.ordinativo_id=migrRecord.ordinativo_id
               and b.bil_id=bilancioid
               and b.movgest_tipo_id in 
                   (select r.movgest_tipo_id 
                      from siac_d_movgest_tipo r 
                     where r.ente_proprietario_id=enteproprietarioid 
                       and r.movgest_tipo_code='A')
               and b.movgest_anno=d.anno_accertamento
               and b.movgest_numero=d.numero_accertamento
               and b.movgest_id=c.movgest_id
               and c.movgest_ts_id = a.movgest_ts_id;
                 
            if v_attoamm_id is null then
                select 1 
                  into v_scarto 
                  from migr_ordinativo_entrata_scarto 
                 where migr_ordinativo_scarto_id=migrRecord.migr_ordinativo_id;

                if v_scarto is null then
                    strMessaggioScarto := 'Atto Amministrativo non migrato. ';
                    strDettaglioScarto := '[ordinativo]['||migrRecord.anno_esercizio||'/'||migrRecord.numero_ordinativo||'/'||TIPO_ORD'].';
                end if;  
            else              
                strMessaggio:='Inserimento relazione tra ordinativo e Atto Amministrativo collegato.'; 

                insert into siac_r_ordinativo_atto_amm 
                    (ord_id, attoamm_id, validita_inizio, validita_fine, ente_proprietario_id, data_creazione, login_operazione)
                values 
                    (v_ordid, v_attoamm_id, dataInizioVal, null, enteproprietarioid, clock_timestamp(), loginoperazione);

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
                         null ,validita_inizio ,null , enteproprietarioid ,data_creazione ,loginoperazione);
                end if;
            end if;

            ----------------------------FINE definizione atto amministrativo da collegare all'ordinativo----------------------------------------------------------------------
            
            if strMessaggioScarto is not null then
                insert into migr_ordinativo_entrata_scarto
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
                        (ord_id, attr_id, tabella_id, "boolean", percentuale, testo, numerico, validita_inizio, validita_fine, ente_proprietario_id,
                         data_creazione, login_operazione)
                    VALUES
                       (v_ordid, v_attr_id_flagAllegatoCartaceo, null, migrRecord.flag_allegato_cart, null, null, null, dataInizioVal,
                        null, enteproprietarioid, clock_timestamp(), loginoperazione);
                end if;

                if migrRecord.comunicazioni_tes is not null then
                    strMessaggio:=strMessaggio||'Inserimento attributo COMUNICAZIONI_TES.'; 
                    insert into siac_r_ordinativo_attr 
                        (ord_id, attr_id, tabella_id, "boolean", percentuale, testo, numerico, validita_inizio, validita_fine, ente_proprietario_id,
                         data_creazione, login_operazione)
                    VALUES
                        (v_ordid, v_attr_id_note_ordinativo, null, null, null, migrRecord.comunicazioni_tes, null, dataInizioVal, null, enteproprietarioid,
                         clock_timestamp(), loginoperazione);
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
                    messaggioRisultato:=strMessaggio||' STATO ORDINATIVO NON PRESENTE per ord_stato_code = '||migrRecord.stato_operativo||'.';
                    numerorecordinseriti:=-12;
                    return;
                else
                    if migrRecord.stato_operativo = 'I' THEN
                        if migrRecord.data_emissione is not null then
                            insert into siac_r_ordinativo_stato 
                               (ord_id, ord_stato_id, validita_inizio, validita_fine, ente_proprietario_id, data_creazione, login_operazione)
                            values
                               (v_ordid, v_ord_stato_id_i, to_timestamp(migrRecord.data_emissione,'dd/mm/yyyy'), null, enteproprietarioid, clock_timestamp(), 
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
                                (ord_id,ord_stato_id, validita_inizio, validita_fine, ente_proprietario_id, data_creazione, login_operazione)
                            values
                                (v_ordid, v_ord_stato_id_i, to_timestamp(migrRecord.data_emissione,'dd/mm/yyyy'),
                                 to_timestamp(migrRecord.data_trasmissione,'dd/mm/yyyy'), enteproprietarioid, clock_timestamp(), loginoperazione);
                        end if;

                        if migrRecord.data_trasmissione is not null then
                            insert into siac_r_ordinativo_stato
                               (ord_id, ord_stato_id, validita_inizio, validita_fine, ente_proprietario_id, data_creazione, login_operazione)
                            values
                               (v_ordid, v_ord_stato_id_t, to_timestamp(migrRecord.data_trasmissione,'dd/mm/yyyy'),
                                to_timestamp(migrRecord.firma_ord_data,'dd/mm/yyyy'), enteproprietarioid, clock_timestamp(), loginoperazione);
                        end if;

                        if migrRecord.firma_ord_data is not null then
                            insert into siac_r_ordinativo_stato
                                (ord_id, ord_stato_id, validita_inizio ,validita_fine ,ente_proprietario_id ,data_creazione ,login_operazione)
                            values
                                (v_ordid, v_ord_stato_id_f, to_timestamp(migrRecord.firma_ord_data,'dd/mm/yyyy'), null,
                                 enteproprietarioid, clock_timestamp(), loginoperazione);

                            -- inserimento nella relazione ordinativo firma
                            insert into siac_r_ordinativo_firma 
                                (ord_id ,ord_firma_data ,ord_firma ,oil_ricevuta_id , validita_inizio ,
                                 validita_fine ,ente_proprietario_id ,data_creazione ,login_operazione)
                            values
                                (v_ordid , to_timestamp(migrRecord.firma_ord_data,'dd/mm/yyyy'),migrRecord.firma_ord ,NULL,dataInizioVal ,
                                 null , enteproprietarioid ,clock_timestamp() ,loginoperazione) ;
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
                                (ord_id ,ord_firma_data ,ord_firma ,oil_ricevuta_id , validita_inizio ,
                                 validita_fine ,ente_proprietario_id ,data_creazione ,login_operazione)
                            values
                                (v_ordid , to_timestamp(migrRecord.firma_ord_data,'dd/mm/yyyy') ,migrRecord.firma_ord ,null,
                                 to_timestamp(migrRecord.quietanza_data,'dd/mm/yyyy') ,null , enteproprietarioid ,clock_timestamp() ,
                                 loginoperazione) ;
                        end if;  
              
                        if migrRecord.quietanza_data is not null then            
                            insert into siac_r_ordinativo_stato
                               (ord_id ,ord_stato_id , validita_inizio ,validita_fine ,ente_proprietario_id ,data_creazione ,login_operazione)
                            values
                               (v_ordid , v_ord_stato_id_q ,to_timestamp(migrRecord.quietanza_data,'dd/mm/yyyy') ,null ,
                                enteproprietarioid ,clock_timestamp() ,loginoperazione );
                        end if;
                    end if;
                       
                    if migrRecord.stato_operativo = 'A' THEN
                        --se la data annullamento è valorizzata inserisco lo stato relativo
                        if migrRecord.data_emissione is not null then
                            insert into siac_r_ordinativo_stato
                                (ord_id ,ord_stato_id , validita_inizio ,validita_fine ,ente_proprietario_id ,data_creazione ,login_operazione)
                            values
                                (v_ordid , v_ord_stato_id_i ,to_timestamp(migrRecord.data_emissione,'dd/mm/yyyy') ,
                                 to_timestamp(migrRecord.data_annullamento,'dd/mm/yyyy') ,enteproprietarioid ,clock_timestamp() ,loginoperazione);
                        end if;

                        if migrRecord.data_trasmissione is not null then
                            insert into siac_r_ordinativo_stato
                                (ord_id ,ord_stato_id , validita_inizio ,validita_fine ,ente_proprietario_id ,data_creazione ,login_operazione)
                            values
                                (v_ordid , v_ord_stato_id_t ,to_timestamp(migrRecord.data_trasmissione,'dd/mm/yyyy') ,
                                 to_timestamp(migrRecord.data_annullamento,'dd/mm/yyyy'),enteproprietarioid ,clock_timestamp() ,loginoperazione);
                        end if;

                        if (migrRecord.firma_ord_data is not null) and 
                           (migrRecord.quietanza_data is not null)     then            
                            insert into siac_r_ordinativo_stato
                                (ord_id, ord_stato_id, validita_inizio, validita_fine, ente_proprietario_id, data_creazione, login_operazione)
                            values
                                (v_ordid, v_ord_stato_id_f,to_timestamp(migrRecord.firma_ord_data,'dd/mm/yyyy'),
                                 to_timestamp(migrRecord.quietanza_data,'dd/mm/yyyy'), enteproprietarioid, clock_timestamp(), loginoperazione);

                            insert into siac_r_ordinativo_firma 
                                (ord_id, ord_firma_data, ord_firma, oil_ricevuta_id, validita_inizio, validita_fine, ente_proprietario_id,
                                 data_creazione, login_operazione)
                            values
                                (v_ordid, to_timestamp(migrRecord.firma_ord_data,'dd/mm/yyyy'), migrRecord.firma_ord, null,
                                 to_timestamp(migrRecord.quietanza_data,'dd/mm/yyyy'), null, enteproprietarioid, clock_timestamp(), 
                                 loginoperazione);
                        end if;  
             
                        if migrRecord.data_annullamento is not null then            
                            insert into siac_r_ordinativo_stato
                               (ord_id, ord_stato_id, validita_inizio, validita_fine, ente_proprietario_id, data_creazione, login_operazione)
                            values
                               (v_ordid, v_ord_stato_id_a, to_timestamp(migrRecord.data_annullamento,'dd/mm/yyyy'), null,
                                enteproprietarioid, clock_timestamp(), loginoperazione );
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
                        (classif_id ,ord_id ,validita_inizio ,validita_fine ,ente_proprietario_id ,data_cancellazione ,login_operazione )
                    values
                        (migrClassif.classifId, v_ordid, dataInizioVal ,null ,enteproprietarioid ,null ,loginOperazione );
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
                        (classif_id ,ord_id ,validita_inizio ,validita_fine ,ente_proprietario_id ,data_cancellazione ,login_operazione )
                    values
                        (migrClassif.classifId ,v_ordid ,dataInizioVal ,null ,enteproprietarioid ,null ,loginOperazione );
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
                        (classif_id ,ord_id ,validita_inizio ,validita_fine ,ente_proprietario_id ,data_cancellazione ,login_operazione)
                    values
                        (migrClassif.classifId ,v_ordid ,dataInizioVal ,null ,enteproprietarioid ,null ,loginOperazione);
                    end if;
                */
  
                strMessaggio:='gestione piano dei conti V   '||migrRecord.pdc_finanziario||'.';
                select * 
                  into recClassif 
                  from fnc_getClassifid_entrata(v_ordid, v_classif_tipo_id_pdc, 'PDC_V'::varchar, migrRecord.pdc_finanziario, v_num_accertamento::varchar, 
                                        migrRecord.anno_esercizio::varchar, enteproprietarioid, loginOperazione );
                
                if recClassif.codResult <> 0 then
                    strMessaggio := strMessaggio||recClassif.strMessaggio;
                    strMessaggioScarto := recClassif.strMessaggioScarto;
                else
                    strMessaggio:='gestione TRANSAZIONE_UE_ENTRATA   '||migrRecord.transazione_ue_entrata||'.';        
                    select * 
                      into recClassif 
                      from fnc_getClassifid_entrata(v_ordid, v_classif_tipo_id_tra, 'TRANSAZIONE_UE_ENTRATA'::varchar ,migrRecord.transazione_ue_entrata, 
                                            v_num_accertamento::varchar, migrRecord.anno_esercizio::varchar, enteproprietarioid,loginOperazione );

                    if recClassif.codResult <> 0 then
                        strMessaggio := strMessaggio||recClassif.strMessaggio;
                        strMessaggioScarto := recClassif.strMessaggioScarto;
                    else
                        strMessaggio:='gestione RICORRENTE_ENTRATA   '||migrRecord.entrata_ricorrente||'.';
                        select * 
                          into recClassif 
                          from fnc_getClassifid_entrata(v_ordid, v_classif_tipo_id_en_ri, 'RICORRENTE_ENTRATA'::varchar, migrRecord.entrata_ricorrente, 
                                                v_num_accertamento::varchar, migrRecord.anno_esercizio::varchar, enteproprietarioid, loginOperazione);
                     
                        if recClassif.codResult <> 0 then
                            strMessaggio := strMessaggio||recClassif.strMessaggio;
                            strMessaggioScarto := recClassif.strMessaggioScarto;
                        else
                            strMessaggio:='gestione PERIMETRO_SANITARIO_ENTRATA   '||migrRecord.perimetro_sanitario_entrata||'.';
                            select * 
                              into recClassif 
                              from fnc_getClassifid_entrata(v_ordid, v_classif_tipo_id_pesa, 'PERIMETRO_SANITARIO_ENTRATA'::varchar, 
                                                    migrRecord.perimetro_sanitario_entrata, v_num_accertamento::varchar, 
                                                    migrRecord.anno_esercizio::varchar, enteproprietarioid, loginOperazione);

                            if recClassif.codResult <> 0 then
                                strMessaggio := strMessaggio||recClassif.strMessaggio;
                                strMessaggioScarto := recClassif.strMessaggioScarto;
                            else
                                strMessaggio:='gestione SIOPE_ENTRATA_I   '||migrRecord.siope_entrata||'.';
                                select * 
                                  into recClassif 
                                  from fnc_getClassifid_entrata(v_ordid, v_classif_tipo_id_siope, 'SIOPE_ENTRATA_I'::varchar, migrRecord.siope_entrata,
                                                          v_num_accertamento::varchar, migrRecord.anno_esercizio::varchar, enteproprietarioid, loginOperazione);
                                                        
                                if recClassif.codResult <> 0 then
                                    strMessaggio := strMessaggio||recClassif.strMessaggio;
                                    strMessaggioScarto := recClassif.strMessaggioScarto;
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
                    
                    select sogg.soggetto_id 
                      into v_soggetto_id
                      from siac_t_soggetto sogg
                         where sogg.soggetto_code = migrRecord.codice_soggetto::varchar
                           and sogg.ente_proprietario_id = enteProprietarioId;
   
                    if v_soggetto_id is null then
                        select 1 
                          into v_scarto 
                          from migr_ordinativo_entrata_scarto 
                         where migr_ordinativo_scarto_id=migrRecord.migr_ordinativo_id;

                        if v_scarto is null then
                            strMessaggioScarto := 'Soggetto non migrato. ';
                            strDettaglioScarto := '[codice_soggetto]['||migrRecord.codice_soggetto||'].';
                        end if;
                    else
                        insert into siac_r_ordinativo_soggetto 
                            (ord_id ,soggetto_id , validita_inizio ,validita_fine , ente_proprietario_id ,data_creazione ,login_operazione)
                        values
                            (v_ordid, v_soggetto_id,dataInizioVal, null,enteproprietarioid ,clock_timestamp(),loginoperazione);
                    end if;
                    
                    if strMessaggioScarto is not null then
                        insert into migr_ordinativo_entrata_scarto
                            (migr_ordinativo_id, numero_ordinativo, anno_esercizio, motivo_scarto, ente_proprietario_id)
                        values
                            (migrRecord.migr_ordinativo_id, migrRecord.numero_ordinativo, migrRecord.anno_esercizio, 
                             strMessaggioScarto||strDettaglioScarto, enteProprietarioId);
                    end if;

                    -- FINE SOGGETTO------------------------------------------------------------
   
                    if v_soggetto_id is not null then
                        -----------FINALE
                        strmessaggio:= 'Insert into siac_r_migr_ordinativo_entrata_ordinativo.';
                        insert into siac_r_migr_ordinativo_entrata_ordinativo
                            (migr_ordinativo_id, ord_id, ente_proprietario_id)
                        VALUES
                            (migrRecord.migr_ordinativo_id, v_ordid, enteProprietarioId);

                        countRecordInseriti:=countRecordInseriti+1;

                        -- valorizzare fl_elab = 'S'
                        update migr_ordinativo_entrata 
                           set fl_elab='S'
                         where ente_proprietario_id=enteProprietarioId
                           and migr_ordinativo_id = migrRecord.migr_ordinativo_id;

                    end if;
                end if;
            end if;
        end if;

    end loop;

    messaggioRisultato:=strMessaggio||strMessaggioFinale||'Inseriti '||countRecordInseriti||' ordinativi entrata.';
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