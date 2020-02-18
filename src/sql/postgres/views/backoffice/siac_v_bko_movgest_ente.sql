/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create or replace view siac_v_bko_movgest_ente as
      select 
i.ente_proprietario_id, i.ente_denominazione,
i.codice_fiscale, g.bil_id, g.bil_desc, h.data_inizio,
h.data_fine
,a.movgest_id
,a.movgest_anno
,a.movgest_numero
,a.movgest_desc
,a.movgest_tipo_id
,a.validita_inizio validita_inizio_movgest
,a.validita_fine validita_fine_movgest
,a.data_creazione data_creazione_movgest
,a.data_modifica data_modifica_movgest
,a.data_cancellazione data_cancellazione_movgest
,a.login_operazione login_operazione_movgest
,a.parere_finanziario
,c.movgest_tipo_code,c.movgest_tipo_desc
,e.movgest_ts_tipo_code,e.movgest_ts_tipo_desc
,d.movgest_stato_code,d.movgest_stato_desc
,b.movgest_ts_id
,b.movgest_ts_code
,b.movgest_ts_desc
,b.movgest_ts_tipo_id
,b.movgest_ts_id_padre
,b.ordine
,b.livello
,b.validita_inizio
,b.validita_fine
,b.data_creazione
,b.data_modifica
,b.data_cancellazione
,b.login_operazione
,b.login_creazione
,b.login_modifica
,b.login_cancellazione
,b.movgest_ts_scadenza_data
    from siac_t_movgest a, siac_t_movgest_ts b, 
 siac_d_movgest_tipo c, siac_d_movgest_stato d ,siac_d_movgest_ts_tipo e
 , siac_r_movgest_ts_stato f, siac_t_bil g, siac_t_periodo h,siac_t_ente_proprietario i
 where a.movgest_id=b.movgest_id
 and a.movgest_tipo_id=c.movgest_tipo_id
 and f.movgest_ts_id=b.movgest_ts_id
 and d.movgest_stato_id=f.movgest_stato_id
 and e.movgest_ts_tipo_id=b.movgest_ts_tipo_id
 and g.bil_id=a.bil_id
 and h.periodo_id=g.periodo_id 
 and i.ente_proprietario_id=a.ente_proprietario_id
   and now() BETWEEN f.validita_inizio and coalesce (f.validita_fine, now())