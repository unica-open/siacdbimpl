/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿begin;


delete from  siac_r_movgest_ts_sogclasse  where login_operazione=:login and ente_proprietario_id=:ente;
delete from  siac_r_movgest_ts_sog        where login_operazione=:login and ente_proprietario_id=:ente;
delete from  siac_r_movgest_ts_programma  where login_operazione=:login and ente_proprietario_id=:ente;
delete from  siac_r_movgest_ts_attr       where login_operazione=:login and ente_proprietario_id=:ente;
delete from  siac_r_movgest_bil_elem      where login_operazione=:login and ente_proprietario_id=:ente;
delete from  siac_r_movgest_ts_stato      where login_operazione=:login and ente_proprietario_id=:ente;
delete from  siac_t_movgest_ts_det        where login_operazione=:login and ente_proprietario_id=:ente;
delete from  siac_r_movgest_ts_atto_amm   where login_operazione=:login and ente_proprietario_id=:ente;

delete from  siac_r_movgest_class         where login_operazione=:login and ente_proprietario_id=:ente;

 delete from  siac_t_class
 where login_operazione=:login and ente_proprietario_id=:ente;

delete from  siac_t_movgest_ts           where login_operazione=:login and ente_proprietario_id=:ente;
delete from  siac_t_movgest             where login_operazione=:login and ente_proprietario_id=:ente;

delete from siac_r_atto_amm_class where login_operazione=:login and ente_proprietario_id=:ente;
delete from siac_r_atto_amm_stato where login_operazione=:login and ente_proprietario_id=:ente;
delete from siac_t_atto_amm where login_operazione=:login and ente_proprietario_id=:ente;

delete from siac_r_migr_impegno_movgest_ts where  ente_proprietario_id=:ente;

delete from siac_r_migr_accertamento_movgest_ts where ente_proprietario_id=:ente;

-- DAVIDE 09.03.016 - aggiunta tavole per modifiche impegni / accertamenti
delete from siac_t_movgest_ts_det_mod where ente_proprietario_id=:ente;
delete from siac_r_modifica_stato where ente_proprietario_id=:ente;
delete from siac_t_modifica where ente_proprietario_id=:ente;

commit;
begin;
--delete from migr_impegno_accertamento;
--delete from migr_impegno;
--delete from migr_accertamento;
delete from migr_classif_impacc;


vacuum ANALYZE siac_r_movgest_ts_sogclasse;
vacuum ANALYZE siac_r_movgest_ts_sog;
vacuum ANALYZE siac_r_movgest_ts_programma;
vacuum ANALYZE siac_r_movgest_ts_attr;
vacuum ANALYZE siac_r_movgest_ts_stato;
vacuum ANALYZE siac_t_movgest_ts_det;
vacuum ANALYZE siac_r_movgest_ts_atto_amm;
vacuum ANALYZE siac_r_atto_amm_class;
vacuum ANALYZE siac_r_atto_amm_stato;
vacuum ANALYZE siac_t_atto_amm;
vacuum ANALYZE siac_r_movgest_class;
vacuum ANALYZE siac_t_class;
vacuum ANALYZE siac_t_movgest_ts;
vacuum ANALYZE siac_r_movgest_bil_elem;
vacuum ANALYZE siac_t_movgest;
vacuum ANALYZE siac_r_migr_impegno_movgest_ts;
vacuum ANALYZE siac_r_migr_accertamento_movgest_ts;

-- DAVIDE 09.03.016 - aggiunta tavole per modifiche impegni / accertamenti
vacuum ANALYZE siac_t_movgest_ts_det_mod;
vacuum ANALYZE siac_r_modifica_stato;
vacuum ANALYZE siac_t_modifica;

vacuum ANALYZE migr_impegno_accertamento;
vacuum ANALYZE migr_classif_impacc;
vacuum ANALYZE migr_movgest_del;
vacuum ANALYZE migr_movgest_ts_del;
vacuum ANALYZE migr_movgestts_attoamm_del;
vacuum ANALYZE migr_movgest_class_del;

rollback;

commit;

