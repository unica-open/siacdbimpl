/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


﻿drop function if exists siac.fnc_siac_vincoli_pending
(
  p_ente_proprietario_id integer,
  p_anno_bilancio integer,
  p_log_elab      varchar,
  p_movgest_anno  integer,
  p_movgest_numero integer,
  p_login_operazione varchar,
  p_data_elaborazione timestamp
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_vincoli_pending
(
  p_ente_proprietario_id integer,
  p_anno_bilancio integer,
  p_log_elab      varchar,
  p_movgest_anno  integer,
  p_movgest_numero integer,
  p_login_operazione varchar,
  p_data_elaborazione timestamp
)
RETURNS integer  AS
$body$
DECLARE
 params varchar(250):=null;

 p_esito integer:=-1;
 esito varchar(10):='OK';

 rec record;
 cur_modif CURSOR (c_movgest_anno integer,c_movgest_numero integer ) FOR
 select modif.mod_id, per.anno::integer anno_bilancio
 from siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_t_bil bil,siac_t_periodo per,
     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo ts_tipo,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
     siac_t_movgest_ts_det_mod dmod,
     siac_r_modifica_stato rs_mod,siac_d_modifica_stato stato_mod,
     siac_t_modifica modif
where tipo.ente_proprietario_id=p_ente_proprietario_id
and   tipo.movgest_tipo_code='I'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   bil.bil_id=mov.bil_id
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=p_anno_bilancio
and   ts.movgest_id=mov.movgest_id
and   ts_tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and   ts_tipo.movgest_ts_tipo_code='T'
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   stato.movgest_stato_code!='A'
and   dmod.movgest_ts_id=ts.movgest_ts_id
and   rs_mod.mod_stato_r_id=dmod.mod_stato_r_id
and   stato_mod.mod_stato_id=rs_mod.mod_stato_id
and   stato_mod.mod_stato_code!='A'
and   modif.mod_id=rs_mod.mod_id
and   dmod.movgest_ts_det_importo<0
and   dmod.mtdm_reimputazione_flag=true
and   dmod.mtdm_reimputazione_anno is not null
and   modif.elab_ror_reanno=false
and   mov.movgest_anno::integer=coalesce(c_movgest_anno,mov.movgest_anno::integer)
and   mov.movgest_numero::integer=coalesce(c_movgest_numero,mov.movgest_numero::integer)
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   ts.validita_fine is null
and   rs_mod.data_cancellazione is null
and   rs_mod.validita_fine is null
and   dmod.data_cancellazione is null
and   dmod.validita_fine is null
order by mov.movgest_anno::integer,mov.movgest_numero::integer,modif.mod_num::integer;


begin

p_esito:=-1;

params := p_anno_bilancio::varchar||' - '||p_ente_proprietario_id::varchar||' - '||p_data_elaborazione::varchar;
raise notice '%', 'fnc_siac_vincoli_pending - inizio - '||clock_timestamp()::varchar||'.';

if p_log_elab is not null then
 insert into  siac_dwh_log_elaborazioni
  (
    ente_proprietario_id,
    fnc_name ,
    fnc_parameters ,
    fnc_elaborazione_inizio ,
    fnc_user
  )
  values
  (
    p_ente_proprietario_id,
    'fnc_siac_vincoli_pending',
    params||' - fnc_siac_vincoli_pending - inizio - '||clock_timestamp()::varchar||'.',
    clock_timestamp(),
    p_log_elab
  );
end if;

raise notice '%', 'fnc_siac_vincoli_pending - inizio cancellazione  siac_dwh_vincoli_pending - '||clock_timestamp()::varchar||'.';
delete from siac_t_vincolo_pending pending
where pending.ente_proprietario_id=p_ente_proprietario_id
and   pending.bil_anno::integer=p_anno_bilancio;

if p_log_elab is not null then
 insert into  siac_dwh_log_elaborazioni
  (
    ente_proprietario_id,
    fnc_name ,
    fnc_parameters ,
    fnc_elaborazione_inizio ,
    fnc_user
  )
  values
  (
    p_ente_proprietario_id,
    'fnc_siac_vincoli_pending',
    params||' - fnc_siac_vincoli_pending - inizio chiamata fnc_siac_vincoli_pending_modifica - '||clock_timestamp()::varchar||'.',
    clock_timestamp(),
    p_log_elab
  );
end if;

raise notice '%', 'fnc_siac_vincoli_pending - inizio chiamata fnc_siac_vincoli_pending_modifica - '||clock_timestamp()::varchar||'.';
for rec in cur_modif (p_movgest_anno,p_movgest_numero) loop
select fnc_siac_vincoli_pending_modifica(rec.mod_id,rec.anno_bilancio,p_log_elab,p_login_operazione,p_data_elaborazione) into esito;
--raise notice '%', 'fnc_siac_vincoli_pending - chiamata fnc_siac_vincoli_pending_modifica - mod_id='||rec.mod_id::varchar||' esito='||esito::varchar||'.';
end loop;
raise notice '%', 'fnc_siac_vincoli_pending - fine chiamata fnc_siac_vincoli_pending_modifica - '||clock_timestamp()::varchar||'.';

if p_log_elab is not null then
 insert into  siac_dwh_log_elaborazioni
  (
    ente_proprietario_id,
    fnc_name ,
    fnc_parameters ,
    fnc_elaborazione_inizio ,
    fnc_user
  )
  values
  (
    p_ente_proprietario_id,
    'fnc_siac_vincoli_pending',
    params||' - fnc_siac_vincoli_pending - fine chiamata fnc_siac_vincoli_pending_modifica - '||clock_timestamp()::varchar||'.',
    clock_timestamp(),
    p_log_elab
  );
end if;

raise notice '%', 'fnc_siac_vincoli_pending - fine chiamata fnc_siac_vincoli_pending_modifica - '||clock_timestamp()::varchar||'.';

p_esito:=0;
return p_esito;

EXCEPTION
WHEN others THEN
  p_esito:=-1;
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
  RETURN p_esito;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
alter function siac.fnc_siac_vincoli_pending(integer,integer,varchar,integer,integer,varchar,timestamp) owner to siac;