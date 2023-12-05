/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop view if exists siac.siac_v_dwh_mutuo_movgest_ts;
create or replace view siac.siac_v_dwh_mutuo_movgest_ts
(
    ente_proprietario_id,
    anno_bilancio,
    mutuo_numero,
    mutuo_movgest_tipo,
    mutuo_movgest_anno,
    mutuo_movgest_numero,
    mutuo_movgest_subnumero ,
    mutuo_movgest_importo_iniziale,
    mutuo_movgest_importo_finale
 )
AS
(
SELECT 
    per.ente_proprietario_id,
    per.anno::integer anno_bilancio,
    mutuo.mutuo_numero,
    tipo.movgest_tipo_code mutuo_movgest_tipo,
    mov.movgest_anno mutuo_movgest_anno,
    mov.movgest_numero::integer movgest_numero,
    (case when tipo_ts.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)::integer mutuo_movgest_subnumero,
    rmov.mutuo_movgest_ts_importo_iniziale mutuo_movgest_importo_iniziale,
    rmov.mutuo_movgest_ts_importo_finale mutuo_movgest_importo_finale
FROM siac_t_bil bil,siac_t_periodo per,
             siac_t_movgest mov,siac_d_movgest_tipo tipo,
             siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipo_ts,
             siac_t_mutuo mutuo ,siac_r_mutuo_movgest_ts  rmov
where bil.periodo_id=per.periodo_id 
and     mov.bil_id=bil.bil_id 
and     tipo.movgest_tipo_id=mov.movgest_tipo_id 
and     ts.movgest_id=mov.movgest_id 
and     tipo_ts.movgest_ts_tipo_id=ts.movgest_ts_tipo_id 
and     rmov.movgest_ts_id =ts.movgest_ts_id 
and     mutuo.mutuo_id=rmov.mutuo_id 
and     rmov.data_cancellazione  is null 
and     mutuo.data_cancellazione  is null
and     mov.data_cancellazione  is null
and     ts.data_cancellazione  is null
--and     now() >= mutuo.validita_inizio 
--and     now() <= COALESCE(mutuo.validita_fine, now())
);

alter view siac.siac_v_dwh_mutuo_movgest_ts owner to siac;


