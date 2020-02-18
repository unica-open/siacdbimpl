/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create or replace function fnc_migr_prov_cassa(
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
    recId                     varchar(100) :='';
    v_provc_tipo_id            integer := 0;
    v_provc_tipo_id_s        integer := 0;
    v_provc_tipo_id_e        integer := 0;
    v_provc_id              integer := 0;
    
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
        select distinct 1 into strict countRecordDaMigrare from migr_provv_cassa m
         where m.ente_proprietario_id=enteproprietarioid
           and m.fl_elab='N'
           and m.migr_provvisorio_id >= idmin
           and m.migr_provvisorio_id <= idmax;

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
        strMessaggio :=' estraggo provc_tipo_id dal campo della tabella di siac_d_prov_cassa_tipo per codice E. ';

        select provc_tipo_id 
          into v_provc_tipo_id_e
          from siac_d_prov_cassa_tipo
         where siac_d_prov_cassa_tipo.provc_tipo_code='E'
           and siac_d_prov_cassa_tipo.ente_proprietario_id = enteProprietarioId
           and siac_d_prov_cassa_tipo.data_cancellazione is null 
           and date_trunc('day',dataElaborazione)>=date_trunc('day',siac_d_prov_cassa_tipo.validita_inizio)
           and (date_trunc('day',dataElaborazione)<=date_trunc('day',siac_d_prov_cassa_tipo.validita_fine) or siac_d_prov_cassa_tipo.validita_fine is null);

 	    strMessaggio :=' estraggo provc_tipo_id dal campo della tabella di siac_d_prov_cassa_tipo per codice S. ';

        select provc_tipo_id 
          into v_provc_tipo_id_s
          from siac_d_prov_cassa_tipo
         where siac_d_prov_cassa_tipo.provc_tipo_code='S'
           and siac_d_prov_cassa_tipo.ente_proprietario_id = enteProprietarioId 
           and siac_d_prov_cassa_tipo.data_cancellazione is null
           and date_trunc('day',dataElaborazione)>=date_trunc('day',siac_d_prov_cassa_tipo.validita_inizio)
           and (date_trunc('day',dataElaborazione)<=date_trunc('day',siac_d_prov_cassa_tipo.validita_fine) or siac_d_prov_cassa_tipo.validita_fine is null);

    exception
        when NO_DATA_FOUND then
            messaggioRisultato:=strMessaggioFinale||' tipo prov S o E non presenti per ente  '||enteProprietarioId||', idmin '||idmin||', idmax '||idmax||'.';
            numerorecordinseriti:=-12;
            return;

        when others  THEN
            raise notice '%  % ERRORE DB: % %',strMessaggioFinale,strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 1500);
            messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
            numerorecordinseriti:=-1;
            return;
    end;


    --------------------------
    --INIZIO DEL LOOP---------
    --------------------------
    strMessaggio:='Lettura record migr_provv_cassa.';

    for migrRecord IN
        (
         select
            migr_provvisorio_id
            ,provvisorio_id
            ,tipo_eu
            ,anno_provvisorio
            ,numero_provvisorio
            ,causale
            ,sub_causale
            ,data_emissione
            ,importo
            ,denominazione_soggetto
            ,data_annullamento
            ,data_regolarizzazione
            ,ente_proprietario_id
            ,fl_elab
            ,data_creazione
         from migr_provv_cassa m
         where m.ente_proprietario_id=enteproprietarioid
               and m.fl_elab='N'
               and m.migr_provvisorio_id >= idmin
               and m.migr_provvisorio_id <= idmax
         order by m.migr_provvisorio_id
        )
    LOOP
    
        strMessaggioScarto     := null;
        v_provc_id             := 0;

        if migrrecord.tipo_eu = 'E' then
            v_provc_tipo_id    := v_provc_tipo_id_e;
        else
            v_provc_tipo_id    := v_provc_tipo_id_s;        
        end if;

        strMessaggio:='Inserimento del provvisorio di cassa : '||annoBilancio||'/'||migrRecord.anno_provvisorio||'/'||migrRecord.numero_provvisorio||'/'||migrRecord.tipo_eu||'.';
 
        insert into siac_t_prov_cassa(
              provc_anno 
              ,provc_numero 
              ,provc_causale 
              ,provc_subcausale 
              ,provc_denom_soggetto 
              --provc_data_convalida -- da chiedere a sofia
             ,provc_data_emissione 
              ,provc_data_annullamento 
              ,provc_data_regolarizzazione 
              ,provc_importo 
              ,provc_tipo_id 
              ,validita_inizio 
              ,validita_fine 
              ,ente_proprietario_id 
              ,data_creazione 
              ,login_operazione 
        )VALUES(
             
               migrRecord.anno_provvisorio
              ,migrRecord.numero_provvisorio
              ,migrRecord.causale 
              ,migrRecord.sub_causale 
              ,migrRecord.denominazione_soggetto
              --,to_timestamp(provc_data_convalida,'dd/mm/yyyy')     -- da chiedere a sofia
             ,to_timestamp(migrRecord.data_emissione,'dd/mm/yyyy') 
              ,to_timestamp(migrRecord.data_annullamento,'dd/mm/yyyy') 
              ,to_timestamp(migrRecord.data_regolarizzazione,'dd/mm/yyyy')
              ,migrRecord.importo 
              ,v_provc_tipo_id 
              ,dataInizioVal 
              ,null 
              ,enteproprietarioid 
              ,clock_timestamp() 
              --data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
              --data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
              ,loginoperazione
        ) returning provc_id into v_provc_id;

        if v_provc_id is not null then
            --INIZIO INSERIMENTO IN TABELLE DI RELAZIONE
        
            -----------FINALE
            strmessaggio:= 'Insert into siac_r_migr_prov_cassa_prov_cassa.';
            insert into siac_r_migr_prov_cassa_prov_cassa (
                migr_provvisorio_id, 
                provc_id,
                data_creazione,
                ente_proprietario_id
            )VALUES(
                migrRecord.migr_provvisorio_id, 
                v_provc_id,
                dataInizioVal, 
                enteProprietarioId);

               countRecordInseriti:=countRecordInseriti+1;

            -- valorizzare fl_elab = 'S'
            update migr_provv_cassa 
               set fl_elab='S'
             where ente_proprietario_id=enteProprietarioId
               and migr_provvisorio_id = migrRecord.migr_provvisorio_id;
        
        else 
            strMessaggioScarto     := 'Provvisorio di cassa non inserito. Provvisorio : '||anno_provvisorio||'/'||numero_provvisorio||'.';

            insert into migr_prov_cassa_scarto(
                migr_provvisorio_id,
                numero_provvisorio,
                anno_esercizio,
                motivo_scarto, 
                ente_proprietario_id
            )values(
                migrRecord.migr_provvisorio_id,
                migrRecord.numero_provvisorio,
                strMessaggioScarto,
                enteProprietarioId);

        end if;

  end loop;


   messaggioRisultato:=strMessaggioFinale||'Inseriti '||countRecordInseriti||' Provvisori di Cassa.';
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