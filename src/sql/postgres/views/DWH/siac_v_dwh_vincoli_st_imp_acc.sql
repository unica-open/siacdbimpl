/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop view if exists siac.siac_v_dwh_vincoli_st_imp_acc;
CREATE OR REPLACE VIEW siac.siac_v_dwh_vincoli_st_imp_acc
(
    ente_proprietario_id,
    bil_code,
    anno_bilancio,
    anno_impegno,
    numero_impegno,
    anno_accertamento,
    numero_accertamento ,
    numero_subaccertamento
    )
AS
(
SELECT 
       bil.ente_proprietario_id,
       bil.bil_code,
       per.anno AS anno_bilancio,
       mov.movgest_anno as anno_impegno,
       mov.movgest_numero::integer AS numero_impegno,
       r.movgest_anno_acc  as anno_accertamento,
       r.movgest_numero_acc as numero_accertamento,
       r.movgest_subnumero_acc as  numero_subaccertamento
FROM  siac_t_movgest mov,siac_d_movgest_tipo tipo ,
              siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipo_ts,
              siac_t_bil bil,siac_t_periodo per,
              siac_r_movgest_ts_storico_imp_acc r 
where tipo.movgest_tipo_code='I'
and     mov.movgest_tipo_id=tipo.movgest_tipo_id 
and     ts.movgest_id=mov.movgest_id 
and     tipo_ts.movgest_ts_tipo_id=ts.movgest_ts_tipo_id 
and     tipo_ts.movgest_ts_tipo_code='T'
and     bil.bil_id=mov.bil_id 
and     per.periodo_id=bil.periodo_id 
and     r.movgest_ts_id =ts.movgest_ts_id 
and     mov.data_cancellazione IS NULL
AND   mov.validita_fine IS NULL
AND   ts.data_cancellazione IS NULL
AND   ts.validita_fine IS NULL
AND   r.data_cancellazione IS NULL
AND   r.validita_fine IS NULL
AND   bil.data_cancellazione IS NULL
AND   per.data_cancellazione IS null);

alter view siac.siac_v_dwh_vincoli_st_imp_acc owner to siac;
