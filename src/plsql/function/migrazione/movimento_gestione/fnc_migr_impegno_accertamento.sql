/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_impegno_accertamento (
  enteproprietarioid integer,
  annobilancio varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  idmin integer,
  idmax integer,
  out numerorecordinseriti integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$

DECLARE
    NVL_STR                   CONSTANT VARCHAR:='';

    MOVGEST_TESTATA           CONSTANT varchar :='T';
    MOVGEST_IMPEGNI           CONSTANT varchar :='I';
    MOVGEST_ACCERT            CONSTANT varchar :='A';

    dataInizioVal             timestamp    :=null;
    strToElab                 varchar(250) :='';
    strMessaggio              VARCHAR(1500):='';
    strMessaggioFinale        VARCHAR(1500):='';
    strMessaggioScarto        VARCHAR(1500):='';
	strMessaggioScarto_prec   VARCHAR(1500):='';
    v_scarto                  integer := 0; -- 1 se esiste uno scarto per il numero_ordinativo da migrare, 0 se non esiste quindi viene inserito durante questa elaborazione.
    bilancioId                INTEGER := 0; -- pk tabella siac_t_bil
    countRecordDaMigrare      integer := 0;
    countRecordInseriti       integer := 0;
    migrRecord                RECORD;
    recId                     varchar(100) :='';
    v_accertamento_id         integer := 0;
    v_anno_impegno            integer := 0;
    v_numero_impegno          integer := 0;
    v_anno_accertamento       integer := 0;
    v_numero_accertamento     integer := 0;
    v_anno_accertamento_rec   integer := 0;
    v_numero_accertamento_rec integer := 0;
    v_impegno_id              integer := 0;
    v_vincolo_id              integer := 0;
    movgestTipoImpId          integer := 0;
    movgestTipoAccId          integer := 0;
    movgestTipoTestId         integer := 0;
    code                      varchar(500) := '';
	v_flag_acce_N             boolean := false;

BEGIN
    numerorecordinseriti:=0;
    messaggioRisultato:='';

    dataInizioVal:=date_trunc('DAY', now());
    strMessaggioFinale:='Migrazione Vincoli Imp/Acc.';

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
         select distinct 1 into strict countRecordDaMigrare from migr_impegno_accertamento m
          where m.ente_proprietario_id=enteproprietarioid
            and m.fl_elab='N'
            and m.migr_vincolo_impacc_id >= idmin
            and m.migr_vincolo_impacc_id <= idmax;

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

    -- Lettura codifiche fisse all'interno del ciclo
    begin
        code:='MOVGEST_IMPEGNI';
        select tipoMovGest.movgest_tipo_id into strict movgestTipoImpId
        from siac_d_movgest_tipo tipoMovGest
               where tipoMovGest.movgest_tipo_code=MOVGEST_IMPEGNI and
                 tipoMovGest.data_cancellazione is null and
                 date_trunc('day',dataElaborazione)>=date_trunc('day',tipoMovGest.validita_inizio) and
                 (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoMovGest.validita_fine)
                    or tipoMovGest.validita_fine is null) and
                 tipoMovGest.ente_proprietario_id=enteProprietarioId;

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
               and m.fl_elab='N'
               and m.migr_vincolo_impacc_id >= idmin
               and m.migr_vincolo_impacc_id <= idmax
         order by m.anno_accertamento, m.numero_accertamento, m.migr_vincolo_impacc_id)
    LOOP

        strMessaggioScarto := null;
        v_impegno_id              := 0;
        v_vincolo_id              := 0;
        v_anno_impegno            := migrRecord.anno_impegno::integer;
        v_numero_impegno          := migrRecord.numero_impegno;
        v_anno_accertamento_rec   := migrRecord.anno_accertamento::integer;
        v_numero_accertamento_rec := migrRecord.numero_accertamento;

        if (v_anno_accertamento != v_anno_accertamento_rec) or (v_numero_accertamento != v_numero_accertamento_rec) then

            v_anno_accertamento     := v_anno_accertamento_rec;
            v_numero_accertamento   := v_numero_accertamento_rec;
			v_accertamento_id       := 0;
	        strMessaggioScarto_prec :='';

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

            if  v_accertamento_id = 0 then
                strMessaggioScarto := 'scarto vincolo per accertamento vincolato non migrato '|| migrRecord.anno_accertamento||'/'||migrRecord.numero_accertamento||'.';
                strMessaggioScarto_prec := strMessaggioScarto;
                v_flag_acce_N := true;
		    else
                v_flag_acce_N := false;
			end if;

        end if;

        -- if strMessaggioScarto is null then
        if v_flag_acce_N != true then
            strMessaggio     := 'estraggo l''id dell''impegno collegato '||migrRecord.anno_impegno||'/'||migrRecord.numero_impegno||'.';

            begin
                select o.movgest_ts_id from siac_t_movgest_ts o
                  into strict v_impegno_id
                 where o.ente_proprietario_id=enteproprietarioid
                   and o.movgest_ts_tipo_id=movgestTipoTestId
                   and o.movgest_id in (select j.movgest_id
                                          from siac_t_movgest j
                                         where j.ente_proprietario_id=enteproprietarioid
                                           and j.movgest_anno=v_anno_impegno
                                           and j.movgest_numero=v_numero_impegno
                                           and j.bil_id = bilancioId
                                           and j.movgest_tipo_id = movgestTipoImpId);
            exception
                when others  THEN null;
            end;

            if v_impegno_id = 0 then
                strMessaggioScarto := 'scarto vincolo per impegno collegato non migrato '||migrRecord.anno_impegno||'/'||migrRecord.numero_impegno||'.';
            else
                strMessaggio:='Inserimento del vincolo : '||annoBilancio||'/'||migrRecord.migr_vincolo_impacc_id||' sull''accertamento '|| migrRecord.anno_accertamento||'/'||migrRecord.numero_accertamento||'.';

                insert into siac_r_movgest_ts(
                    movgest_ts_a_id,
                    movgest_ts_b_id,
                    movgest_ts_importo,
                    validita_inizio,
                    validita_fine,
                    ente_proprietario_id,
                    data_creazione,
                    login_operazione
                )VALUES(
                    v_accertamento_id
                    ,v_impegno_id
                    ,migrRecord.importo
                    ,clock_timestamp()
                    ,null
                    ,enteproprietarioid
                    ,clock_timestamp()
                    ,loginoperazione
                ) returning movgest_ts_r_id into v_vincolo_id;

                if v_vincolo_id = 0 then
                    strMessaggioScarto := 'Vincolo sull''accertamento '||annoBilancio||'/'|| migrRecord.anno_accertamento||'/'||migrRecord.numero_accertamento||' non inserito. vincolo id '||migrRecord.migr_vincolo_impacc_id||'.';
                else
                    countRecordInseriti := countRecordInseriti + 1;

                    -- valorizzare fl_elab = 'S'
                    update migr_impegno_accertamento
                       set fl_elab='S'
                     where ente_proprietario_id=enteProprietarioId
                       and migr_vincolo_impacc_id = migrRecord.migr_vincolo_impacc_id;

                end if;

            end if;

        else
            strMessaggioScarto := strMessaggioScarto_prec;
        end if;

        if strMessaggioScarto is not null then

            insert into migr_impacc_scarto(
                vincolo_impacc_id,
                anno_esercizio,
                motivo_scarto,
                ente_proprietario_id
            )values(
                migrRecord.vincolo_impacc_id,
                annobilancio,
                strMessaggioScarto,
                enteProprietarioId);

        end if;

    end loop;

    messaggioRisultato:=strMessaggioFinale||'Inseriti '||countRecordInseriti||' vincoli Impegni/Accertamenti.';
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