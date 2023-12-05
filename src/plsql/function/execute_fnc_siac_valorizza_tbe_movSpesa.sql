/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
select * from fnc_siac_valorizza_tbe_movSpesa(18,'batch_tbe','N')

select * from log_fnc_siac_valorizza_tbe_movSpesa where ente_proprietario_id = 18

-- elenco movimenti di USCITA da aggiornare
select * from siac_d_movgest_tipo where movgest_tipo_code = 'I' and ente_proprietario_id=18
-- 5 regione
Select ts.movgest_ts_id,elem.elem_id, m.movgest_id,  tsTipo.movgest_ts_tipo_code
from siac_t_movgest m,siac_t_movgest_ts ts, siac_r_movgest_bil_elem elem
, siac_d_movgest_ts_tipo tsTipo
where m.ente_proprietario_id=18
and m.movgest_tipo_id = 32
and m.movgest_id=elem.movgest_id
and elem.data_cancellazione is null and
date_trunc('day',now())>=date_trunc('day',elem.validita_inizio) and
(date_trunc('day',now())<=date_trunc('day',elem.validita_fine)
          or elem.validita_fine is null)
and ts.movgest_id=m.movgest_id
and tstipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
order by m.movgest_id, tsTipo.movgest_ts_tipo_code desc
--482


-- elenco dei classificatori definiti per accertamenti
select r.movgest_ts_id,d.classif_tipo_code, c.classif_code, c.classif_desc, r.login_operazione
from siac_r_movgest_class r, siac_t_class c,  siac_d_class_tipo d, siac_d_movgest_tipo tipo, siac_t_movgest_ts ts, siac_t_movgest t
where r.ente_proprietario_id=18
and r.classif_id = c.classif_id
and c.classif_tipo_id = d.classif_tipo_id
and d.classif_tipo_code in ('PDC_V','GRUPPO_COFOG','TRANSAZIONE_UE_SPESA','SIOPE_SPESA_I','RICORRENTE_SPESA','PERIMETRO_SANITARIO_SPESA','POLITICHE_REGIONALI_UNITARIE')
and r.data_cancellazione is null
--and r.movgest_ts_id=45327
and ts.movgest_ts_id = r.movgest_ts_id
and t.movgest_id=ts.movgest_id
and t.movgest_tipo_id=tipo.movgest_tipo_id
and tipo.movgest_tipo_code='I'
order by r.movgest_ts_id, d.classif_tipo_code
--371
-- dopo fnc 1817


select r.movgest_ts_id, count(*)
from siac_r_movgest_class r, siac_t_class c,  siac_d_class_tipo d, siac_d_movgest_tipo tipo, siac_t_movgest_ts ts, siac_t_movgest t
where r.ente_proprietario_id=18
and r.classif_id = c.classif_id
and c.classif_tipo_id = d.classif_tipo_id
and d.classif_tipo_code in ('PDC_V','GRUPPO_COFOG','TRANSAZIONE_UE_SPESA','SIOPE_SPESA_I','RICORRENTE_SPESA','PERIMETRO_SANITARIO_SPESA','POLITICHE_REGIONALI_UNITARIE')
and r.data_cancellazione is null
--and r.movgest_ts_id=45327
and ts.movgest_ts_id = r.movgest_ts_id
and t.movgest_id=ts.movgest_id
and t.movgest_tipo_id=tipo.movgest_tipo_id
and tipo.movgest_tipo_code='I'
group by r.movgest_ts_id
having count(*)>3


-- classificatori per movimento e capitolo (in join) (solo i validi)
        select tipoClass.classif_tipo_code,
        c.classif_id idXmov, c.classif_code codeXmov, c.classif_desc descXmov,r.login_operazione,r.movgest_classif_id,
        c1.classif_id idXcap, c1.classif_code codeXcap, c1.classif_desc descXcap, r1.login_operazione, r1.elem_classif_id
        from
        siac_t_movgest_ts ts, siac_r_movgest_bil_elem cap,
        siac_r_movgest_class r, siac_t_class c
		, siac_r_bil_elem_class r1, siac_t_class c1
        , siac_d_class_tipo tipoClass
        where ts.movgest_ts_id=45668
        and r.movgest_ts_id= ts.movgest_ts_id
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
		and ts.movgest_id=cap.movgest_id
        and r1.elem_id = cap.elem_id
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

-- classificatori per movgest_ts (solo i validi)
        select tipoClass.classif_tipo_code, r1.classif_id idXmov, c1.classif_code codeXmov, c1.classif_desc descXliq, r1.login_operazione
        from
		siac_r_movgest_class r1, siac_t_class c1
        , siac_d_class_tipo tipoClass
        where r1.movgest_ts_id=9192
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
		and tipoClass.ente_proprietario_id=2
		and tipoClass.data_cancellazione is null and
              date_trunc('day',now())>=date_trunc('day',tipoClass.validita_inizio) and
              (date_trunc('day',now())<=date_trunc('day',tipoClass.validita_fine)
                        or tipoClass.validita_fine is null);


-- classificatori per capitolo legato al movimento ts (solo i validi)
        select tipoClass.classif_tipo_code, r1.classif_id idXcap, c1.classif_code codeXcap, c1.classif_desc descXcap
        from
        siac_T_movgest_ts ts,siac_r_movgest_bil_elem cap, siac_r_bil_elem_class r1
		, siac_t_class c1, siac_d_class_tipo tipoClass
        where ts.movgest_ts_id=9192
        and ts.movgest_id=cap.movgest_id
		and r1.elem_id=cap.elem_id
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
		and tipoClass.ente_proprietario_id=2
		and tipoClass.data_cancellazione is null and
              date_trunc('day',now())>=date_trunc('day',tipoClass.validita_inizio) and
              (date_trunc('day',now())<=date_trunc('day',tipoClass.validita_fine)
                        or tipoClass.validita_fine is null);




-- classificatori per movimento ts (tutti anche quelli non piu validi)
select tipo.classif_tipo_code, c.classif_code, c.classif_desc, r.validita_inizio, r.validita_fine, r.data_cancellazione, r.login_operazione
from siac_r_movgest_class r, siac_t_class c, siac_d_class_tipo  tipo
where r.movgest_ts_id = 9192
and r.classif_id=c.classif_id
and c.classif_tipo_id=tipo.classif_tipo_id
and tipo.classif_tipo_code in
('PDC_V','GRUPPO_COFOG','TRANSAZIONE_UE_SPESA','SIOPE_SPESA_I','RICORRENTE_SPESA','PERIMETRO_SANITARIO_SPESA','POLITICHE_REGIONALI_UNITARIE')
order by tipo.classif_tipo_code, r.validita_inizio,r.validita_fine


-- capitoli senza SIOPE DEFINITO
select * from siac_t_bil_elem elem, siac_d_bil_elem_tipo tipo
where elem.ente_proprietario_id=18
and tipo.elem_tipo_code in ('CAP-UP', 'CAP-UG')
and elem.elem_tipo_id=tipo.elem_tipo_id
and not exists (select 1 from siac_r_bil_elem_class r, siac_t_class c, siac_d_class_tipo  tipo
where r.elem_id=elem.elem_id
and r.classif_id=c.classif_id
and c.classif_tipo_id=tipo.classif_tipo_id
and tipo.classif_tipo_code = 'SIOPE_SPESA_I')
--273

-- count(*) dei capitoli
select * from siac_t_bil_elem elem, siac_d_bil_elem_tipo tipo
where elem.ente_proprietario_id=18
and tipo.elem_tipo_code in ('CAP-UP', 'CAP-UG')
and elem.elem_tipo_id=tipo.elem_tipo_id
--640

select * from siac_r_migr_capitolo_entrata_bil_elem where elem_id = 21991

select * from siac_r_migr_capitolo_uscita_bil_elem where elem_id = 21388
select * from migr_capitolo_uscita_scarto where migr_capusc_id = 13691




-- 11.01.2016
--caso di prova:
--elem_id = 4166
--movgest = 9157
--movgest_ts = 9192
--liq_id 53

select d.elem_tipo_code, b.* from siac_t_bil_elem b, siac_d_bil_elem_tipo d
where b.elem_id = 4166
and d.elem_tipo_id=b.elem_tipo_id