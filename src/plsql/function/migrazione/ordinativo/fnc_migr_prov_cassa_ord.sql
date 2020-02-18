/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create or replace function fnc_migr_prov_cassa_ord(
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
    v_provc_id              integer := 0;
    v_ord_id                integer := 0;
    v_ord_provc_id            integer := 0;
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
         select distinct 1 into strict countRecordDaMigrare from migr_provv_cassa_ordinativo m
          where m.ente_proprietario_id=enteproprietarioid
            and m.fl_elab='N'
            and m.migr_provvisorio_ord_id >= idmin
            and m.migr_provvisorio_ord_id <= idmax;

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
    
  
    --------------------------
    --INIZIO DEL LOOP---------
    --------------------------
    strMessaggio:='Lettura record migr_provv_cassa_ordinativo.';

    for migrRecord IN
        (
         select
             migr_provvisorio_ord_id,
             provvisorio_id,
             tipo_eu,
             ordinativo_id,
             ord_numero,
             anno_esercizio,
             anno_provvisorio,
             numero_provvisorio,
             importo,
             ente_proprietario_id,
             fl_elab,
             data_creazione
         from
             migr_provv_cassa_ordinativo m
         where m.ente_proprietario_id=enteproprietarioid
               and m.fl_elab='N'
               and m.migr_provvisorio_ord_id >= idmin
               and m.migr_provvisorio_ord_id <= idmax
         order by m.migr_provvisorio_ord_id
        )
    LOOP
    
        strMessaggioScarto := null;
		v_ord_id           := 0;
        v_ord_provc_id     := 0;
		v_provc_id         := 0;

        strMessaggio     := 'estraggo l''id del''ordinativo  di tipo '||migrrecord.tipo_eu ||' e ordinativo id '|| migrRecord.ordinativo_id;
        
        if migrrecord.tipo_eu = 'E' then
            select siac_t_ordinativo.ord_id 
              into strict v_ord_id
              from 
                   migr_ordinativo_entrata,
                   siac_r_migr_ordinativo_entrata_ordinativo,
                   siac_t_ordinativo
             where 
                   migr_ordinativo_entrata.migr_ordinativo_id = siac_r_migr_ordinativo_entrata_ordinativo.migr_ordinativo_id 
               AND siac_r_migr_ordinativo_entrata_ordinativo.ord_id = siac_t_ordinativo.ord_id
               AND migr_ordinativo_entrata.ordinativo_id = migrRecord.ordinativo_id
               AND siac_t_ordinativo.ente_proprietario_id = enteProprietarioId  
               AND siac_t_ordinativo.data_cancellazione is null 
               AND date_trunc('day',dataElaborazione)>=date_trunc('day',siac_t_ordinativo.validita_inizio)
               and (date_trunc('day',dataElaborazione)<=date_trunc('day',siac_t_ordinativo.validita_fine) or siac_t_ordinativo.validita_fine is null);
        else
            select siac_t_ordinativo.ord_id 
              into strict v_ord_id
              from 
                   migr_ordinativo_spesa,
                   siac_r_migr_ordinativo_spesa_ordinativo,
                   siac_t_ordinativo
             where 
                   migr_ordinativo_spesa.migr_ordinativo_id = siac_r_migr_ordinativo_spesa_ordinativo.migr_ordinativo_id 
               AND siac_r_migr_ordinativo_spesa_ordinativo.ord_id = siac_t_ordinativo.ord_id
               AND migr_ordinativo_spesa.ordinativo_id = migrRecord.ordinativo_id
               AND siac_t_ordinativo.ente_proprietario_id = enteProprietarioId  
               AND siac_t_ordinativo.data_cancellazione is null 
               AND date_trunc('day',dataElaborazione)>=date_trunc('day',siac_t_ordinativo.validita_inizio)
               and (date_trunc('day',dataElaborazione)<=date_trunc('day',siac_t_ordinativo.validita_fine) or siac_t_ordinativo.validita_fine is null);
        end if;

        if  v_ord_id = 0 then
            strMessaggioScarto := 'ordinativo non migrato  ordinativo id '|| migrRecord.ordinativo_id || ' del tipo '|| migrrecord.tipo_eu;

        else
        
            strMessaggio     := 'estraggo l''id del provvisorio  di tipo '||migrrecord.tipo_eu ||' e ordinativo id '|| migrRecord.ordinativo_id;
			begin
			    select siac_r_migr_prov_cassa_prov_cassa.provc_id 
                  into strict v_provc_id
                  from migr_provv_cassa,
                       siac_r_migr_prov_cassa_prov_cassa, 
                       siac_t_prov_cassa				   
                 where migr_provv_cassa.migr_provvisorio_id= siac_r_migr_prov_cassa_prov_cassa.migr_provvisorio_id
                   AND siac_r_migr_prov_cassa_prov_cassa.provc_id = siac_t_prov_cassa.provc_id 
				   AND migr_provv_cassa.anno_provvisorio=migrRecord.anno_provvisorio
                   and migr_provv_cassa.numero_provvisorio=migrRecord.numero_provvisorio                   
                   AND siac_t_prov_cassa.ente_proprietario_id = enteProprietarioId  			   
               AND siac_t_prov_cassa.data_cancellazione is null 
               AND date_trunc('day',dataElaborazione)>=date_trunc('day',siac_t_prov_cassa.validita_inizio)
               and (date_trunc('day',dataElaborazione)<=date_trunc('day',siac_t_prov_cassa.validita_fine) or siac_t_prov_cassa.validita_fine is null);

			exception
                 when others  THEN null;
            end;
			
            if v_provc_id = 0 then
                strMessaggioScarto := 'provvisorio cassa non migrato. provvisorio id '||migrRecord.provvisorio_id||'/'||migrRecord.anno_provvisorio||'/'||migrRecord.numero_provvisorio||'.';
            else
                strMessaggio:='Inserimento del provvisorio di cassa ordinativo : '||annoBilancio||'/'||migrRecord.anno_provvisorio||'/'||migrRecord.numero_provvisorio||'/'||migrRecord.tipo_eu||'.';

                insert into siac_r_ordinativo_prov_cassa(
                    ord_id 
                    ,provc_id 
                    ,ord_provc_importo 
                    ,validita_inizio 
                    ,validita_fine
                    ,ente_proprietario_id 
                    ,data_cancellazione 
                    ,login_operazione 
                )VALUES(
                    v_ord_id 
                    ,v_provc_id 
                    ,migrRecord.importo 
                    ,dataInizioVal 
                    ,null
                    ,enteproprietarioid 
                    ,null 
                    ,loginoperazione 
                ) returning ord_provc_id into v_ord_provc_id;
        
                if v_ord_provc_id is null then
                    strMessaggioScarto := 'provvisorio cassa ordinativo non inserito. provvisorio id '||migrRecord.provvisorio_id||'/'||migrRecord.anno_provvisorio||'/'||migrRecord.numero_provvisorio||'.';
                else
        
                    strmessaggio:= 'Insert into siac_r_migr_prov_cassa_ordinativo_siac_r_ordinativo_prov_cassa.';
                    insert into siac_r_migr_prov_cassa_ordinativo_siac_r_ordinativo_prov_cassa(
                        migr_provvisorio_ord_id, 
                        ord_provc_id, 
                        data_creazione,
                        ente_proprietario_id
                    )VALUES(
                        migrRecord.migr_provvisorio_ord_id,
                        v_ord_provc_id,
                        dataInizioVal, 
                        enteProprietarioId);

                    countRecordInseriti:=countRecordInseriti+1;

                    -- valorizzare fl_elab = 'S'
                    update migr_provv_cassa_ordinativo 
                       set fl_elab='S'
                     where ente_proprietario_id=enteProprietarioId
                       and migr_provvisorio_ord_id = migrRecord.migr_provvisorio_ord_id;
                end if;
        
            end if;      
        
        end if;      
        
        if strMessaggioScarto is not null then

            insert into migr_provv_cassa_ordinativo_scarto(
                migr_provvisorio_ord_id,
                provvisorio_id,
                motivo_scarto, 
                ente_proprietario_id
            )values(
                migrRecord.migr_provvisorio_ord_id,
                migrRecord.provvisorio_id,
                strMessaggioScarto,
                enteProprietarioId);    
            
        end if;

  end loop;


   messaggioRisultato:=strMessaggioFinale||'Inseriti '||countRecordInseriti||' provvisori cassa ordinativi.';
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