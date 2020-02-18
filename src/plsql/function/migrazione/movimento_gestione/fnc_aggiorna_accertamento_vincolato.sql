/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_aggiorna_accertamento_vincolato (
  enteproprietarioid integer,
  annobilancio varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out numerorecordinseriti integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
    NVL_STR                   CONSTANT VARCHAR:='';
    
    MOVGEST_TESTATA           CONSTANT varchar :='T';
    MOVGEST_ACCERT            CONSTANT varchar :='A';
    IMPORTO_UTILIZZABILE      CONSTANT varchar :='U'; 

    strMessaggio              VARCHAR(1500):='';
    strMessaggioFinale        VARCHAR(1500):='';
    bilancioId                INTEGER := 0; -- pk tabella siac_t_bil
    countRecordDaMigrare      integer := 0;
    countRecordAggiornati     integer := 0;
    migrRecord                RECORD;
    recId                     varchar(100) :='';
    v_accertamento_id         integer := 0;
    v_somma_importi           numeric := 0;
    v_anno_accertamento       integer := 0;
    v_numero_accertamento     integer := 0;
    v_anno_accertamento_rec   integer := 0;
    v_numero_accertamento_rec integer := 0;
    movgestTipoAccId          integer := 0;
    movgestTipoTestId         integer := 0;
    idImportoUtilizzabile     integer := 0; 
    code                      varchar(500) := '';
    
BEGIN
    numerorecordinseriti:=0;
    messaggioRisultato:='';

    strMessaggioFinale:='Aggiornamento Importo Utilizzabile su Accertamenti Vincolati.';

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
         strMessaggio:='conteggio dei record da aggiornare.';
         select distinct 1 into strict countRecordDaMigrare from migr_impegno_accertamento m
          where m.ente_proprietario_id=enteproprietarioid
            and m.fl_elab='S';

    exception
        when NO_DATA_FOUND then
  --          messaggioRisultato:=strMessaggioFinale||' Archivio migrazione vuoto per ente '||enteProprietarioId||', idmin '||idmin||', idmax '||idmax||'.';
            messaggioRisultato:=strMessaggioFinale||' Archivio migrazione vuoto per ente '||enteProprietarioId||'.';
            numerorecordinseriti:=-12;
            return;

        when others  THEN
            raise notice '%  % ERRORE DB: % %',strMessaggioFinale,strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 1500);
            messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
            numerorecordinseriti:=-1;
            return;
    end;
 
    -- Lettura codifiche fisse all'interno del ciclo
    begin
        code:='MOVGEST_ACCERT';
        select tipoMovGest.movgest_tipo_id into strict movgestTipoAccId
        from siac_d_movgest_tipo tipoMovGest
        where tipoMovGest.ente_proprietario_id=enteProprietarioid and
          tipoMovGest.movgest_tipo_code=MOVGEST_ACCERT and
          tipoMovGest.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',tipoMovGest.validita_inizio) and
           (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoMovGest.validita_fine)
                  or tipoMovGest.validita_fine is null);
                 
        code:='MOVGEST_TESTATA';
        select tipoMovGestTs.movgest_ts_tipo_id into strict movgestTipoTestId
        from siac_d_movgest_ts_tipo tipoMovGestTs
        where tipoMovGestTs.ente_proprietario_id=enteProprietarioid and
          tipoMovGestTs.movgest_ts_tipo_code=MOVGEST_TESTATA and
          tipoMovGestTs.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',tipoMovGestTs.validita_inizio) and
           (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoMovGestTs.validita_fine)
                  or tipoMovGestTs.validita_fine is null);

        code:='IMPORTO_UTILIZZABILE';
        select tipoImporto.movgest_ts_det_tipo_id into strict idImportoUtilizzabile
          from siac_d_movgest_ts_det_tipo tipoImporto
          where tipoImporto.ente_proprietario_id=enteProprietarioId and
          tipoImporto.movgest_ts_det_tipo_code=IMPORTO_UTILIZZABILE and
          tipoImporto.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',tipoImporto.validita_inizio) and
          (date_trunc('day',dataElaborazione)<date_trunc('day',tipoImporto.validita_fine)
            or tipoImporto.validita_fine is null);

    exception
        when no_data_found then
            RAISE EXCEPTION 'Code cercato % non presente in archivio',code;
        when others  THEN
            RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
    end;    
  
    --------------------------
    --INIZIO DEL LOOP---------
    --------------------------
    strMessaggio:='Lettura record migr_impegno_accertamento.';

    for migrRecord IN
        (select
          migr_vincolo_impacc_id,
          vincolo_impacc_id,
          anno_impegno,
          numero_impegno,
          anno_accertamento,
          numero_accertamento,
          importo,
          ente_proprietario_id,
          fl_elab,
          data_creazione
         from
             migr_impegno_accertamento m
         where m.ente_proprietario_id=enteproprietarioid
               and m.fl_elab='S'
         order by m.anno_accertamento, m.numero_accertamento, m.migr_vincolo_impacc_id)
    LOOP
    
        v_anno_accertamento_rec   := migrRecord.anno_accertamento::integer;
        v_numero_accertamento_rec := migrRecord.numero_accertamento;
    
        if (v_anno_accertamento != v_anno_accertamento_rec) or (v_numero_accertamento != v_numero_accertamento_rec) then
        
            v_somma_importi         := 0;
            v_anno_accertamento     := v_anno_accertamento_rec;
            v_numero_accertamento   := v_numero_accertamento_rec;
			v_accertamento_id       := 0;

            strMessaggio     := 'estraggo l''id dell''accertamento '|| migrRecord.anno_accertamento||'/'||migrRecord.numero_accertamento||'.';
        
            begin
                select o.movgest_ts_id from siac_t_movgest_ts o
                  into strict v_accertamento_id
                 where o.ente_proprietario_id=enteproprietarioid 
                   and o.movgest_ts_tipo_id=movgestTipoTestId
                   and o.movgest_id in (select j.movgest_id 
                                          from siac_t_movgest j
                                         where j.ente_proprietario_id=enteproprietarioid
                                           and j.movgest_anno=v_anno_accertamento_rec
                                           and j.movgest_numero=v_numero_accertamento_rec
                                           and j.bil_id = bilancioId
                                           and j.movgest_tipo_id = movgestTipoAccId);
            exception
                when others  THEN null;
            end;
		   
            countRecordAggiornati := countRecordAggiornati + 1; 

        end if;

        v_somma_importi     := v_somma_importi + migrRecord.importo;
						   
        -- Aggiorna l'importo utilizzabile dell'Accertamento vincolato
        update siac_t_movgest_ts_det 
           set movgest_ts_det_importo=v_somma_importi,
		       data_modifica=clock_timestamp(),
			   login_operazione=loginoperazione
         where ente_proprietario_id=enteProprietarioId
           and movgest_ts_det_tipo_id = idImportoUtilizzabile
           and movgest_ts_id = v_accertamento_id;
					
    end loop;

    messaggioRisultato:=strMessaggioFinale||'Aggiornati '||countRecordAggiornati||' Accertamenti vincolati.';
    numerorecordinseriti:= countRecordAggiornati;
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