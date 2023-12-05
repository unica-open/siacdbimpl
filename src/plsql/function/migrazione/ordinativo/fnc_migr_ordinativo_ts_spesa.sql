/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create or replace function fnc_migr_ordinativo_ts_spesa(
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
    NVL_STR                   CONSTANT VARCHAR:='';
    bilancioId                INTEGER := 0; -- pk tabella siac_t_bil
    dataInizioVal             timestamp    :=null;
    strToElab                 varchar(250) :='';
    strMessaggio              VARCHAR(1500):='';
    strMessaggioFinale        VARCHAR(1500):='';
    strMessaggioScarto        VARCHAR(1500):='';
    v_scarto                  integer := 0; -- 1 se esiste uno scarto per il numero_ordinativo da migrare, 0 se non esiste quindi viene inserito durante questa elaborazione.
    v_ord_id                  INTEGER := 0; -- pk di siac_t_ordinativo
    v_ord_ts_id               INTEGER := 0; -- pk di siac_t_ordinativo_ts
    countRecordDaMigrare      integer := 0;
    countRecordInseriti       integer := 0;
    migrRecord                RECORD;
    recId                     varchar(100) :='';
    v_doc_onere_id            INTEGER := 0; 
    v_ord_ts_det_tipo_id_i    INTEGER := 0; -- pk siac_d_ordinativo_ts_det_tipo
    v_ord_ts_det_tipo_id_a    INTEGER := 0; -- pk siac_d_ordinativo_ts_det_tipo
    v_movgest_ts_id           integer := 0;
    v_movgest_ts_code_tipo    varchar(1) := '';
    v_liq_id                  INTEGER := 0; 

BEGIN
    numerorecordinseriti:=0;
    messaggioRisultato:='';
    
    dataInizioVal:=date_trunc('DAY', now());
    strMessaggioFinale:='Migrazione ordinativi.';

    -- lettura id bilancio
    strMessaggio:='Lettura id bilancio per anno '||annoBilancio||'.';
    select bilancio.idbilancio, bilancio.messaggiorisultato 
      into bilancioid,messaggioRisultato
      from fnc_get_bilancio(enteProprietarioId,annoBilancio) bilancio;

    if (bilancioid=-1) then
        messaggioRisultato:=strMessaggioFinale||messaggioRisultato;
        numerorecordinseriti:=-13;
        return;
    end if;

    begin
        strMessaggio:='conteggio dei record da migrare.';
        select distinct 1 into strict countRecordDaMigrare from migr_ordinativo_spesa_ts m
         where m.ente_proprietario_id=enteproprietarioid
           and m.fl_elab='N'
           and m.migr_ordinativo_spesa_ts_id >= idmin
           and m.migr_ordinativo_spesa_ts_id <= idmax;
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
        strMessaggio :=' estraggo ord_tipo_id dal campo della tabella di siac_d_ordinativo_ts_det_tipo per codice I. ';

        select ord_ts_det_tipo_id  
          into strict v_ord_ts_det_tipo_id_i 
          from siac_d_ordinativo_ts_det_tipo
         where ord_ts_det_tipo_code='I'
           and ente_proprietario_id =  enteproprietarioid 
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
    strMessaggio :=' estraggo ord_tipo_id dal campo della tabella di siac_d_ordinativo_ts_det_tipo per codice A. ';

    select ord_ts_det_tipo_id  
      into strict v_ord_ts_det_tipo_id_a 
      from siac_d_ordinativo_ts_det_tipo
     where ord_ts_det_tipo_code='A' 
       and ente_proprietario_id =  enteproprietarioid 
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


    --------------------------
    --INIZIO DEL LOOP---------
    --------------------------
    strMessaggio:='Lettura record migr_ordinativo_spesa_ts.';
    
    for migrRecord IN
        (
         select
           migr_ordinativo_spesa_ts_id 
          ,ordinativo_ts_id    
          ,ordinativo_id        
          ,anno_esercizio        
          ,numero_ordinativo   
          ,quota_ordinativo        
          ,anno_impegno          
          ,numero_impegno        
          ,numero_subimpegno    
          ,data_scadenza            
          ,descrizione            
          ,numero_liquidazione    
          ,importo_iniziale    
          ,importo_attuale        
          ,anno_documento        
          ,numero_documento    
          ,tipo_documento        
          ,cod_soggetto_documento  
          ,frazione_documento    
          ,anno_nota_cred          
          ,numero_nota_cred       
          ,cod_sogg_nota_cred     
          ,frazione_nota_cred    
          ,importo_nota_cred      
          ,ente_proprietario_id 
          ,fl_elab 
          ,data_creazione 
         from
             migr_ordinativo_spesa_ts m
         where m.ente_proprietario_id=enteproprietarioid
               and m.fl_elab='N'
               and m.migr_ordinativo_spesa_ts_id >= idmin
               and m.migr_ordinativo_spesa_ts_id <= idmax
         order by m.migr_ordinativo_spesa_ts_id
        )
    LOOP
    
        strMessaggioScarto     := null;
        v_scarto               := null;
        v_ord_id               := 0;
        v_ord_ts_id            := 0;
        v_movgest_ts_id        := 0;
        v_movgest_ts_code_tipo := '';
        v_liq_id               := 0;

        if migrRecord.importo_attuale = 0 then
          strMessaggioScarto := 'ordinativo quota (mandato) non migrata  x importo = 0 '||migrRecord.anno_esercizio||'/'||migrRecord.numero_ordinativo||'/'||migrRecord.quota_ordinativo||'.';
        else
                 
            strMessaggio:='Ricerca Id dell''impegno relativo all''ordinativo quota (mandato): '||migrRecord.anno_esercizio||'/'||migrRecord.numero_ordinativo||'/'||migrRecord.quota_ordinativo||'.';
 
            if migrRecord.numero_subimpegno = 0 then
                v_movgest_ts_code_tipo := 'T';
            else
                v_movgest_ts_code_tipo := 'S';
            end if;
    
            select movt.movgest_ts_id
              into v_movgest_ts_id
              from siac_t_movgest mov, siac_t_movgest_ts movt
             where mov.movgest_anno = migrRecord.anno_impegno
               and mov.movgest_numero = migrRecord.numero_impegno
               and mov.movgest_tipo_id = (SELECT mm.movgest_tipo_id
                                            FROM siac_d_movgest_tipo mm
                                           where mm.ente_proprietario_id=enteproprietarioid
                                             and mm.movgest_tipo_code = 'I')
               and mov.bil_id = bilancioId
               and mov.ente_proprietario_id = enteproprietarioid  
               and movt.movgest_id = mov.movgest_id
               and movt.movgest_ts_tipo_id = (select mts.movgest_ts_tipo_id
                                                from siac_d_movgest_ts_tipo mts
                                               where mts.ente_proprietario_id=enteproprietarioid
                                                 and mts.movgest_ts_tipo_code = v_movgest_ts_code_tipo)
               and movt.ente_proprietario_id = mov.ente_proprietario_id;               

            if v_movgest_ts_id is null then
                select 1 
                  into v_scarto 
                  from migr_ordinativo_spesa_ts_scarto 
                 where migr_ordinativo_spesa_ts_id=migrRecord.migr_ordinativo_id;

                if v_scarto is null then
                    strMessaggioScarto := 'quota ordinativo non inserita per impegno non migrato. Ordinativo : '||migrRecord.numero_ordinativo||'/'||migrRecord.anno_impegno||'/'||migrRecord.numero_impegno||'/'||migrRecord.numero_subimpegno;
                end if;
            end if;
                        
            -- Lettura Ord_id dell'ordinativo a cui appartiene la quota
            select ordin.ord_id
              into v_ord_id
              from siac_t_ordinativo ordin
             where ordin.ord_anno = migrRecord.anno_esercizio
               and ordin.ord_numero = migrRecord.numero_ordinativo
               and ordin.ord_tipo_id = v_ord_ts_det_tipo_id_i
               and ordin.bil_id = bilancioId
               and ordin.ente_proprietario_id = enteproprietarioid;

            if v_ord_id is null then
                strMessaggioScarto := 'quota ordinativo non inserita per ordinativo non migrato. Ordinativo : '||migrRecord.numero_ordinativo||'/'||migrRecord.anno_accertamento||'/'||migrRecord.numero_accertamento||'/'||migrRecord.numero_subaccertamento;
            end if;

        end if;

        if strMessaggioScarto is null then
            -- inserimento della quota dell'ordinativo
            strMessaggio:='Inserimento dell''ordinativo quota (Mandato) : '||migrRecord.anno_esercizio||'/'||migrRecord.numero_ordinativo||'/'||migrRecord.quota_ordinativo||'.';

            insert into siac_t_ordinativo_ts (
                ord_ts_code ,
                ord_ts_desc ,
                ord_id ,
                ord_ts_data_scadenza ,
                --doc_onere_id INTEGER,
                validita_inizio ,
                validita_fine ,
                ente_proprietario_id ,
                data_creazione  ,
                login_operazione
            )VALUES(
                1 ,
                migrRecord.descrizione,
                v_ord_id,
                to_timestamp(migrRecord.data_scadenza ,'dd/mm/yyyy'),
                --v_doc_onere_id,
                dataInizioVal ,
                null  , 
                enteproprietarioid ,
                dataInizioVal  ,
                loginoperazione
            ) returning ord_ts_id into v_ord_ts_id;

            if v_ord_ts_id is null then
                strMessaggioScarto := 'quota ordinativo non inserita per errore. Ordinativo : '||migrRecord.numero_ordinativo||'/'||migrRecord.anno_impegno||'/'||migrRecord.numero_impegno||'/'||migrRecord.numero_subimpegno;
            else
                insert into siac_t_ordinativo_ts_det (
                    ord_ts_id ,
                    ord_ts_det_tipo_id ,
                    ord_ts_det_importo ,
                    validita_inizio ,
                    validita_fine ,
                    ente_proprietario_id ,
                    data_creazione ,
                    login_operazione
                )VALUES(
                    v_ord_ts_id ,
                    v_ord_ts_det_tipo_id_i ,
                    migrRecord.importo_iniziale ,
                    dataInizioVal ,
                    null ,
                    enteproprietarioid ,
                    clock_timestamp() ,
                    loginoperazione
                );

                insert into siac_t_ordinativo_ts_det (
                    ord_ts_id ,
                    ord_ts_det_tipo_id ,
                    ord_ts_det_importo ,
                    validita_inizio ,
                    validita_fine ,
                    ente_proprietario_id ,
                    data_creazione ,
                    login_operazione
                )VALUES(
                    v_ord_ts_id ,
                    v_ord_ts_det_tipo_id_a ,
                    migrRecord.importo_attuale ,
                    dataInizioVal ,
                    null ,
                    enteproprietarioid ,
                    clock_timestamp() ,
                    loginoperazione
                );
                --FINE INSERIMENTO QUOTE ORDINATIVO

                --INIZIO INSERIMENTO IN TABELLE DI RELAZIONE
                select siac_r_migr_liquidazione_t_liquidazione.liquidazione_id 
                  into v_liq_id
                  from
                       migr_liquidazione,
                       siac_r_migr_liquidazione_t_liquidazione
                 where
                       migr_liquidazione.liquidazione_id = siac_r_migr_liquidazione_t_liquidazione.liquidazione_id 
                   and migr_liquidazione.numero_liquidazione =  migrRecord.numero_liquidazione
                   and migr_liquidazione.anno_esercizio = migrRecord.anno_esercizio
                   and migr_liquidazione.ente_proprietario_id = enteproprietarioid;

                if v_liq_id is null then
                    select 1 into v_scarto from migr_ordinativo_spesa_scarto where migr_ordinativo_scarto_id=migrRecord.migr_ordinativo_id;
                    
                   if v_scarto is null then
                       strMessaggioScarto := 'quota ordinativo non inserita per liquidazione non migrata. Ordinativo : '||migrRecord.numero_ordinativo||'/'||migrRecord.anno_impegno||'/'||migrRecord.numero_impegno||'/'||migrRecord.numero_subimpegno||'. Liquidazione : '||migrRecord.numero_liquidazione||'.';
                    end if;
                else
                     insert into siac_r_liquidazione_ord (
                        liq_id ,
                        sord_id ,
                        validita_inizio ,
                        validita_fine ,
                        ente_proprietario_id ,
                        data_creazione ,
                        login_operazione
                    )values(
                        v_liq_id ,
                        v_ord_ts_id ,
                        dataInizioVal , 
                        null , 
                        enteproprietarioid ,
                        clock_timestamp() ,
                        loginoperazione);
        
                    -----------FINALE
                    strmessaggio:= 'Insert into siac_r_migr_ordinativo_ts_entrata_ordinativo.';
                    insert into siac_r_migr_ordinativo_ts_spesa_ordinativo (
                        migr_ordinativo_ts_id
                        ,ord_ts_id
                        ,data_creazione
                        ,ente_proprietario_id
                    )VALUES(
                        migrRecord.ordinativo_ts_id, 
                        v_ord_ts_id,clock_timestamp() ,
                        enteProprietarioId);

                    countRecordInseriti:=countRecordInseriti+1;

                    -- valorizzare fl_elab = 'S'
                    update migr_ordinativo_spesa_ts 
                       set fl_elab='S'
                     where ente_proprietario_id=enteProprietarioId
                       and migr_ordinativo_id = migrRecord.migr_ordinativo_id;        
        
                end if;
        
            end if;
        
        end if;
        
        if strMessaggioScarto is not null then
            insert into migr_ordinativo_spesa_scarto (
                migr_ordinativo_id,
                numero_ordinativo,
                anno_esercizio,
                motivo_scarto, 
                ente_proprietario_id
            )values(
                migrRecord.migr_ordinativo_id,
                migrRecord.numero_ordinativo,
                strMessaggioScarto,
                enteProprietarioId);
        end if; 

  end loop;


   messaggioRisultato:=strMessaggioFinale||'Inserite '||countRecordInseriti||' quote ordinativi spesa.';
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