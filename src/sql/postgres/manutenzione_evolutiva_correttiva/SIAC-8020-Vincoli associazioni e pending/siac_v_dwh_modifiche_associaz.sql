/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop VIEW if exists siac.siac_v_dwh_modifiche_associaz;
CREATE OR REPLACE VIEW siac.siac_v_dwh_modifiche_associaz
(
  bil_anno,
  acc_anno,
  acc_numero,
  acc_subnumero,
  acc_mod_numero,
  imp_anno,
  imp_numero,
  imp_subnumero,
  imp_mod_numero,
  importo_associaz,
  importo_residuo,
  ente_proprietario_id
) as
select
     per.anno::integer bil_anno,
     mov_acc.movgest_anno::integer acc_anno,
     mov_acc.movgest_numero::integer acc_nuumero,
     (case when tipo_ts_acc.movgest_ts_tipo_code='T' then 0 else ts_acc.movgest_ts_code::integer end )::integer acc_subnumero,
     modif_acc.mod_num::integer acc_mod_numero,
     mov_imp.movgest_anno::integer imp_anno,
     mov_imp.movgest_numero::integer imp_numero,
     (case when tipo_ts_imp.movgest_ts_tipo_code='T' then 0 else ts_imp.movgest_ts_code::integer end)::integer imp_subnumero,
     modif_imp.mod_num::integer imp_mod_numero,
     r.movgest_ts_det_mod_importo importo_associaz,
     r.movgest_ts_det_mod_impo_residuo importo_residuo,
     per.ente_proprietario_id
from siac_r_movgest_ts_det_mod r,
     siac_t_movgest_ts_det_mod dmod_acc,
     siac_t_movgest_ts ts_acc,siac_t_movgest mov_acc,
     siac_d_movgest_ts_tipo tipo_ts_acc,
     siac_r_modifica_stato rs_acc,siac_t_modifica modif_acc,
     siac_t_bil bil,siac_t_periodo per,
     siac_t_movgest_ts_det_mod dmod_imp,
     siac_t_movgest_ts ts_imp,siac_t_movgest mov_imp,
     siac_d_movgest_ts_tipo tipo_ts_imp,
     siac_r_modifica_stato rs_imp,siac_t_modifica modif_imp
where r.movgest_ts_det_mod_entrata_id=dmod_acc.movgest_ts_det_mod_id
and   ts_acc.movgest_ts_id=dmod_acc.movgest_ts_id
and   mov_acc.movgest_id=ts_acc.movgest_id
and   tipo_ts_acc.movgest_ts_tipo_id=ts_acc.movgest_ts_tipo_id
and   bil.bil_id=mov_acc.bil_id
and   per.periodo_id=bil.periodo_id
and   rs_acc.mod_stato_r_id=dmod_acc.mod_stato_r_id
and   modif_acc.mod_id=rs_acc.mod_id
and   dmod_imp.movgest_ts_det_mod_id=r.movgest_ts_det_mod_spesa_id
and   ts_imp.movgest_ts_id=dmod_imp.movgest_ts_id
and   mov_imp.movgest_id=ts_imp.movgest_id
and   tipo_ts_imp.movgest_ts_tipo_id=ts_imp.movgest_ts_tipo_id
and   rs_imp.mod_stato_r_id=dmod_imp.mod_stato_r_id
and   modif_imp.mod_id=rs_imp.mod_id
and   r.data_cancellazione is null
and   r.validita_fine is null
and   dmod_acc.data_cancellazione is null
and   dmod_acc.validita_fine is null
and   ts_acc.data_cancellazione is null
and   ts_acc.validita_fine is null
and   mov_acc.data_cancellazione is null
and   mov_acc.validita_fine is null
and   rs_acc.data_cancellazione is null
and   rs_acc.validita_fine is null
and   modif_acc.data_cancellazione is null
and   modif_acc.validita_fine is null
and   dmod_imp.data_cancellazione is null
and   dmod_imp.validita_fine is null
and   ts_imp.data_cancellazione is null
and   ts_imp.validita_fine is null
and   mov_imp.data_cancellazione is null
and   mov_imp.validita_fine is null
and   rs_imp.data_cancellazione is null
and   rs_imp.validita_fine is null
and   modif_imp.data_cancellazione is null
and   modif_imp.validita_fine is null;
alter VIEW siac.siac_v_dwh_modifiche_associaz owner to siac;


