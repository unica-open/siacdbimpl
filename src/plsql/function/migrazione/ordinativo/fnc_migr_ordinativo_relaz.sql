/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create or replace function fnc_migr_ordinativo_relaz(
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
    dataInizioVal               timestamp    :=null;
    strToElab                 varchar(250) :='';
    strMessaggio              VARCHAR(1500):='';
    strMessaggioFinale        VARCHAR(1500):='';
    strMessaggioScarto        VARCHAR(1500):='';
    v_scarto                  integer := 0; -- 1 se esiste uno scarto per il numero_ordinativo da migrare, 0 se non esiste quindi viene inserito durante questa elaborazione.
    bilancioId                  INTEGER := 0; -- pk tabella siac_t_bil
    countRecordDaMigrare      integer := 0;
    countRecordInseriti       integer := 0;
    migrRecord                 RECORD;
    recId                   varchar(100) :='';
    v_ord_tipo_id_p            integer := 0;
    v_ord_tipo_id_i            integer := 0;
    v_ord_r_id                integer := 0;
    v_ord_id_da                integer := 0;
    v_ord_id_a                integer := 0;
BEGIN
    numerorecordinseriti:=0;
    messaggioRisultato:='';

    dataInizioVal:=date_trunc('DAY', now());
    strMessaggioFinale:='Migrazione ordinativi.';

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
         select distinct 1 into strict countRecordDaMigrare from migr_ordinativo_relaz m
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
            raise notice '%  % ERRORE DB: % %',strMessaggioFinale,strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 1500);
            messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
            numerorecordinseriti:=-1;
            return;
    end;

    begin
    strMessaggio :=' estraggo ord_tipo_id dal campo della tabella di migrazione per codice ord --> P.';

    select ord_tipo_id 
        into strict v_ord_tipo_id_p 
    from 
        siac_d_ordinativo_tipo
    where
        ente_proprietario_id =  enteproprietarioid and
        data_cancellazione is null and ord_tipo_code = 'P'  and
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

    begin
    strMessaggio :=' estraggo ord_tipo_id dal campo della tabella di migrazione per codice ord --> I.';

    select ord_tipo_id 
        into strict v_ord_tipo_id_i 
    from 
        siac_d_ordinativo_tipo
    where
        ente_proprietario_id =  enteproprietarioid and
        data_cancellazione is null and ord_tipo_code = 'I'  and
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
    

    --------------------------
    --INIZIO DEL LOOP---------
    --------------------------
    strMessaggio:='Lettura record migr_ordinativo_relaz.';

    for migrRecord IN
        (
         select
            migr_ordinativo_relaz_id
            ,ordinativo_id_da
            ,tipo_ord_da
            ,ordinativo_id_a
            ,tipo_ord_a
            ,tipo_relaz
            ,numero_da
            ,anno_esercizio_da
            ,numero_a
            ,anno_esercizio_a
            ,ente_proprietario_id
            ,fl_elab
            ,data_creazione
         from
             migr_ordinativo_relaz m
         where 
                m.ente_proprietario_id=enteproprietarioid
               and m.fl_elab='N'
               and m.migr_ordinativo_id >= idmin
               and m.migr_ordinativo_id <= idmax
         order by m.migr_ordinativo_relaz_id
        )
    LOOP
    
        strMessaggioScarto     := null;

      select 
           siac_t_ordinativo.ord_id into v_ord_id_da 
      from 
           siac_t_ordinativo
          ,siac_r_migr_ordinativo_spesa_ordinativo
      where 
          siac_t_ordinativo.ord_id = siac_r_migr_ordinativo_spesa_ordinativo.ord_id
          and  siac_t_ordinativo.ord_tipo_id  =v_ord_tipo_id_p
          and  siac_t_ordinativo.ord_anno = migrRecord.anno_esercizio_da
          and  siac_t_ordinativo.ord_numero = migrRecord.numero_da
          and  siac_t_ordinativo.ente_proprietario_id=enteproprietarioid 
          and  date_trunc('day',dataelaborazione)>=date_trunc('day',siac_t_ordinativo.validita_inizio) 
          and  (date_trunc('day',dataelaborazione)<=date_trunc('day',siac_t_ordinativo.validita_fine) or siac_t_ordinativo.validita_fine is null);

      select 
           siac_t_ordinativo.ord_id into v_ord_id_a 
      from 
           siac_t_ordinativo
          ,siac_r_migr_ordinativo_spesa_ordinativo
      where 
          siac_t_ordinativo.ord_id = siac_r_migr_ordinativo_spesa_ordinativo.ord_id
          and  siac_t_ordinativo.ord_tipo_id  =v_ord_tipo_id_i
          and  siac_t_ordinativo.ord_anno = migrRecord.anno_esercizio_a
          and  siac_t_ordinativo.ord_numero = migrRecord.numero_a
          and  siac_t_ordinativo.ente_proprietario_id=enteproprietarioid 
          and  date_trunc('day',dataelaborazione)>=date_trunc('day',siac_t_ordinativo.validita_inizio) 
          and  (date_trunc('day',dataelaborazione)<=date_trunc('day',siac_t_ordinativo.validita_fine) or siac_t_ordinativo.validita_fine is null);

        strMessaggio:='Inserimento della relazione ordinativo per l''anno : '||annoBilancio||'.';

        insert into siac_r_ordinativo(
            --ord_r_id SERIAL,
            relaz_tipo_id
            ,ord_id_da
            ,ord_id_a
            ,validita_inizio
            ,validita_fine
            ,ente_proprietario_id
            ,data_creazione
            ,login_operazione
        )VALUES(
            relaz_tipo_id
            ,ord_id_da
            ,ord_id_a
            ,validita_inizio
            ,null
            ,enteproprietarioid
            ,data_creazione
            ,loginoperazione
        ) returning ord_r_id into v_ord_r_id;
        --INIZIO INSERIMENTO IN TABELLE DI RELAZIONE
        
        -----------FINALE

        countRecordInseriti:=countRecordInseriti+1;

        -- valorizzare fl_elab = 'S'
        update migr_ordinativo_relaz set fl_elab='S'
        where ente_proprietario_id=enteProprietarioId
        and migr_ordinativo_relaz_id = migrRecord.migr_ordinativo_relaz_id;

  end loop;


   messaggioRisultato:=strMessaggioFinale||'Inseriti '||countRecordInseriti||' ordinativi relazioni.';
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