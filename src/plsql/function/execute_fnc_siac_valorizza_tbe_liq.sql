/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- Esegue fnc
-- Parametrizzare ente (1° parametro) ,  data esecuzione (3° parametro), setNull_tbe
-- Se data esecuzione passata a NULL la funzione imposta la data di sistema.
select * from fnc_siac_valorizza_tbe_liq (18,'batch_tbe','N');

-- Elenco segnalazioni/anomalie
select * from log_fnc_siac_valorizza_tbe_liq where ente_proprietario_id = 18
order by liq_id;

-- elenco liquidazioni da aggiornare
select l.liq_id, l.liq_anno, l.liq_numero, m.movgest_ts_id
          from
          siac_t_liquidazione l, siac_r_liquidazione_movgest m, siac_r_liquidazione_stato st, siac_d_liquidazione_stato ds
          where l.ente_proprietario_id=18
          and l.liq_id=m.liq_id
          and m.data_cancellazione is null and
          date_trunc('day',now())>=date_trunc('day',m.validita_inizio) and
          (date_trunc('day',now())<=date_trunc('day',m.validita_fine)
                    or m.validita_fine is null)
          and st.liq_id=l.liq_id and
          st.data_cancellazione is null and
          date_trunc('day',now())>=date_trunc('day',st.validita_inizio) and
          (date_trunc('day',now())<=date_trunc('day',st.validita_fine)
                    or st.validita_fine is null)
          and ds.liq_stato_id=st.liq_stato_id
          and ds.liq_stato_code != 'ANNULLATO'
          and ds.ente_proprietario_id = 18
--1074
-- elenco liquidazioni migrate (esiste una liquidazione fittizia che non verrà aggiornata)
select count(*) from siac_t_liquidazione where ente_proprietario_id=18
--1075


-- elenco classificatori validi
select l.liq_id, tipoClass.classif_tipo_code,
        c.classif_id idXliq, c.classif_code codeXliq, c.classif_desc descXliq,r.validita_inizio, r.login_operazione,r.liq_classif_id
        from
        siac_t_liquidazione l, siac_r_liquidazione_class r, siac_t_class c
        , siac_d_class_tipo tipoClass
        where l.ente_proprietario_id=18
        and  r.liq_id = l.liq_id
        and r.classif_id = c.classif_id
        and c.classif_tipo_id=tipoClass.classif_tipo_id
        and r.data_cancellazione is null and
          date_trunc('day',now())>=date_trunc('day',r.validita_inizio) and
          (date_trunc('day',now())<=date_trunc('day',r.validita_fine)
                    or r.validita_fine is null)
        and c.data_cancellazione is null and
          date_trunc('day',now())>=date_trunc('day',c.validita_inizio) and
          (date_trunc('day',now())<=date_trunc('day',c.validita_fine)
                    or c.validita_fine is null)
        and
        (tipoClass.classif_tipo_code = 'PDC_V'
        or tipoClass.classif_tipo_code = 'GRUPPO_COFOG'
        or tipoClass.classif_tipo_code = 'TRANSAZIONE_UE_SPESA'
        or tipoClass.classif_tipo_code = 'SIOPE_SPESA_I'
        or tipoClass.classif_tipo_code = 'RICORRENTE_SPESA'
        or tipoClass.classif_tipo_code = 'PERIMETRO_SANITARIO_SPESA'
        or tipoClass.classif_tipo_code = 'POLITICHE_REGIONALI_UNITARIE'
        )
		and tipoClass.ente_proprietario_id=18
		and tipoClass.data_cancellazione is null and
              date_trunc('day',now())>=date_trunc('day',tipoClass.validita_inizio) and
              (date_trunc('day',now())<=date_trunc('day',tipoClass.validita_fine)
                        or tipoClass.validita_fine is null)
        order by l.liq_id, tipoClass.classif_tipo_code
-- 585
--3807 dopo fnc

-- count(*)
select l.liq_id, count(*)
        from
        siac_t_liquidazione l, siac_r_liquidazione_class r, siac_t_class c
        , siac_d_class_tipo tipoClass
        where l.ente_proprietario_id=18
        and  r.liq_id = l.liq_id
        and r.classif_id = c.classif_id
        and c.classif_tipo_id=tipoClass.classif_tipo_id
        and r.data_cancellazione is null and
          date_trunc('day',now())>=date_trunc('day',r.validita_inizio) and
          (date_trunc('day',now())<=date_trunc('day',r.validita_fine)
                    or r.validita_fine is null)
        and c.data_cancellazione is null and
          date_trunc('day',now())>=date_trunc('day',c.validita_inizio) and
          (date_trunc('day',now())<=date_trunc('day',c.validita_fine)
                    or c.validita_fine is null)
        and
        (tipoClass.classif_tipo_code = 'PDC_V'
        or tipoClass.classif_tipo_code = 'GRUPPO_COFOG'
        or tipoClass.classif_tipo_code = 'TRANSAZIONE_UE_SPESA'
        or tipoClass.classif_tipo_code = 'SIOPE_SPESA_I'
        or tipoClass.classif_tipo_code = 'RICORRENTE_SPESA'
        or tipoClass.classif_tipo_code = 'PERIMETRO_SANITARIO_SPESA'
        or tipoClass.classif_tipo_code = 'POLITICHE_REGIONALI_UNITARIE'
        )
		and tipoClass.ente_proprietario_id=18
		and tipoClass.data_cancellazione is null and
              date_trunc('day',now())>=date_trunc('day',tipoClass.validita_inizio) and
              (date_trunc('day',now())<=date_trunc('day',tipoClass.validita_fine)
                        or tipoClass.validita_fine is null)
        group by l.liq_id
        having count(*)>3;

-- liquidazioni senza classificatori
select count(*) from siac_t_liquidazione l where l.ente_proprietario_id=18
and not exists (select 1 from siac_r_liquidazione_class r where r.liq_id=l.liq_id)
-- 490




-- liquidazione e movgest associato
-- sostituire id liquidazione
	select l.liq_id, r.movgest_ts_id,ts.movgest_id, m.movgest_anno, m.movgest_numero  from
    siac_t_liquidazione l
    , siac_r_liquidazione_movgest r
    , siac_t_movgest_ts ts
    , siac_t_movgest m
    where l.liq_id=53
    and r.liq_id=l.liq_id
    and r.movgest_ts_id=ts.movgest_ts_id
    and ts.movgest_id=m.movgest_id


-- parametrizzare ID ENTE, ID LIQ e CODE TIPO CLASS
-- CODE TIPO CLASS: impostare quello del messaggio della segnalazione
-- Se il record non viene trovato significa che il classificatore è null per il movgest e valorizzato per la liquidazione (eseguire le query sotto per verifcare)
        select tipoClass.classif_tipo_code,
        c.classif_id idXliq, c.classif_code codeXliq, c.classif_desc descXliq,r.validita_inizio, r.login_operazione,r.liq_classif_id,
        c1.classif_id idXmov, c1.classif_code codeXmov, c1.classif_desc descXliq,r1.validita_inizio,  r1.login_operazione, r1.movgest_classif_id
        from
        siac_t_liquidazione l, siac_r_liquidazione_movgest lrm,
        siac_r_liquidazione_class r, siac_t_class c
		, siac_r_movgest_class r1, siac_t_class c1
        , siac_d_class_tipo tipoClass
        where l.liq_id=39471
        and r.liq_id = l.liq_id
        and r.classif_id = c.classif_id
        and c.classif_tipo_id=tipoClass.classif_tipo_id
        and r.data_cancellazione is null and
          date_trunc('day',now())>=date_trunc('day',r.validita_inizio) and
          (date_trunc('day',now())<=date_trunc('day',r.validita_fine)
                    or r.validita_fine is null)
        and c.data_cancellazione is null and
          date_trunc('day',now())>=date_trunc('day',c.validita_inizio) and
          (date_trunc('day',now())<=date_trunc('day',c.validita_fine)
                    or c.validita_fine is null)
        and lrm.liq_id=l.liq_id
        and r1.movgest_ts_id = lrm.movgest_ts_id
        and r1.classif_id = c1.classif_id
        and c1.classif_tipo_id=tipoClass.classif_tipo_id
        and r1.data_cancellazione is null and
          date_trunc('day',now())>=date_trunc('day',r1.validita_inizio) and
          (date_trunc('day',now())<=date_trunc('day',r1.validita_fine)
                    or r1.validita_fine is null)
        and c1.data_cancellazione is null and
          date_trunc('day',now())>=date_trunc('day',c1.validita_inizio) and
          (date_trunc('day',now())<=date_trunc('day',c1.validita_fine)
                    or c1.validita_fine is null)
        and
        (tipoClass.classif_tipo_code = 'PDC_V'
        or tipoClass.classif_tipo_code = 'GRUPPO_COFOG'
        or tipoClass.classif_tipo_code = 'TRANSAZIONE_UE_SPESA'
        or tipoClass.classif_tipo_code = 'SIOPE_SPESA_I'
        or tipoClass.classif_tipo_code = 'RICORRENTE_SPESA'
        or tipoClass.classif_tipo_code = 'PERIMETRO_SANITARIO_SPESA'
        or tipoClass.classif_tipo_code = 'POLITICHE_REGIONALI_UNITARIE'
        )
		and tipoClass.ente_proprietario_id=18
		and tipoClass.data_cancellazione is null and
              date_trunc('day',now())>=date_trunc('day',tipoClass.validita_inizio) and
              (date_trunc('day',now())<=date_trunc('day',tipoClass.validita_fine)
                        or tipoClass.validita_fine is null);

select * from siac_r_liquidazione_class r where r.liq_classif_id in (53850, 53847, 53851)

select * from siac_r_liquidazione_class r where r.classif_id = 9102 and r.liq_id=78

Aggiornamento transazione elementare per liquidazioni.Liq. 2015\82727, id 53.Set Null della tbe presente, classificatori.ERRORE DB 42703 COLUMN "LIQ_CLASSIFIF_ID" DOES NOT EXIST


-- classificatore per liquidazione (validi ad oggi)
        select tipoClass.classif_tipo_code, c.classif_id idXliq, c.classif_code codeXliq, c.classif_desc descXliq  ---r.classif_id into idClass_transazioneUE_liq
        from
        siac_t_liquidazione l, siac_r_liquidazione_class r, siac_t_class c , siac_d_class_tipo tipoClass
        where l.liq_id=78
        and r.liq_id = l.liq_id
        and r.classif_id = c.classif_id
        and c.classif_tipo_id=tipoClass.classif_tipo_id
        and r.data_cancellazione is null and
          date_trunc('day',now())>=date_trunc('day',r.validita_inizio) and
          (date_trunc('day',now())<=date_trunc('day',r.validita_fine)
                    or r.validita_fine is null)
        and c.data_cancellazione is null and
          date_trunc('day',now())>=date_trunc('day',c.validita_inizio) and
          (date_trunc('day',now())<=date_trunc('day',c.validita_fine)
                    or c.validita_fine is null)
        and tipoClass.classif_tipo_code in
        ( 'POLITICHE_REGIONALI_UNITARIE','TRANSAZIONE_UE_SPESA','PERIMETRO_SANITARIO_SPESA')
		and tipoClass.ente_proprietario_id=2
		and tipoClass.data_cancellazione is null and
              date_trunc('day',now())>=date_trunc('day',tipoClass.validita_inizio) and
              (date_trunc('day',now())<=date_trunc('day',tipoClass.validita_fine)
                        or tipoClass.validita_fine is null);

-- Classificatore per movgest
        select c1.classif_id idXmov, c1.classif_code codeXmov, c1.classif_desc descXliq
        from
        siac_t_liquidazione l, siac_r_liquidazione_movgest lrm
		, siac_r_movgest_class r1, siac_t_class c1
        , siac_d_class_tipo tipoClass
        where l.liq_id=53
        and lrm.liq_id=l.liq_id
        and r1.movgest_ts_id = lrm.movgest_ts_id
        and r1.classif_id = c1.classif_id
        and c1.classif_tipo_id=tipoClass.classif_tipo_id
        and r1.data_cancellazione is null and
          date_trunc('day',now())>=date_trunc('day',r1.validita_inizio) and
          (date_trunc('day',now())<=date_trunc('day',r1.validita_fine)
                    or r1.validita_fine is null)
        and c1.data_cancellazione is null and
          date_trunc('day',now())>=date_trunc('day',c1.validita_inizio) and
          (date_trunc('day',now())<=date_trunc('day',c1.validita_fine)
                    or c1.validita_fine is null)
        and tipoClass.classif_tipo_code = 'PDC_V' --'TRANSAZIONE_UE_SPESA' --
		and tipoClass.ente_proprietario_id=2
		and tipoClass.data_cancellazione is null and
              date_trunc('day',now())>=date_trunc('day',tipoClass.validita_inizio) and
              (date_trunc('day',now())<=date_trunc('day',tipoClass.validita_fine)
                        or tipoClass.validita_fine is null);




-- classificatore per liquidazione (tutti)
        select tipoClass.classif_tipo_code, c.classif_id idXliq, c.classif_code codeXliq, c.classif_desc descXliq
        , r.validita_inizio, r.validita_fine, r.data_cancellazione, r.login_operazione
        from
        siac_r_liquidazione_class r, siac_t_class c , siac_d_class_tipo tipoClass
        where r.liq_id=53
        and r.classif_id = c.classif_id
        and c.classif_tipo_id=tipoClass.classif_tipo_id
        and tipoClass.classif_tipo_code in
        ( 'PDC_V','GRUPPO_COFOG','SIOPE_SPESA_I','RICORRENTE_SPESA','POLITICHE_REGIONALI_UNITARIE','TRANSAZIONE_UE_SPESA','PERIMETRO_SANITARIO_SPESA')
		and tipoClass.ente_proprietario_id=2
        order by tipoClass.classif_tipo_code, r.validita_inizio, r.validita_fine;

tipoClass.classif_tipo_code = 'PDC_V'
        or tipoClass.classif_tipo_code = 'GRUPPO_COFOG'
        or tipoClass.classif_tipo_code = 'TRANSAZIONE_UE_SPESA'
        or tipoClass.classif_tipo_code = 'SIOPE_SPESA_I'
        or tipoClass.classif_tipo_code = 'RICORRENTE_SPESA'
        or tipoClass.classif_tipo_code = 'PERIMETRO_SANITARIO_SPESA'
        or tipoClass.classif_tipo_code = 'POLITICHE_REGIONALI_UNITARIE'
