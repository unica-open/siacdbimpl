/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


﻿drop FUNCTION if exists siac.fnc_siac_vincoli_pending_modifica
(
  p_mod_id integer,
  p_anno_bilancio integer,
  p_log_elab      varchar,
  p_login_operazione varchar,
  p_data_elaborazione timestamp
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_vincoli_pending_modifica
(
  p_mod_id integer,
  p_anno_bilancio integer,
  p_log_elab      varchar,
  p_login_operazione varchar,
  p_data_elaborazione timestamp
)
RETURNS varchar AS
$body$
DECLARE
 importo_mod_da_scalare numeric:=null;
 importo_delta_vincolo numeric:=null;
 ente_proprietario_id_in integer;
 rec record;

 esito varchar(10);

 strMessaggio varchar(1000) := null;
 h_result integer:=null;
 mod_id_in integer:=null;
cur CURSOR(par_in integer) FOR
select query.tipomod,
	   query.mod_id,
       query.movgest_ts_r_id,
       query.movgest_ts_importo,
       query.tipoordinamento
from
(
--avav
SELECT 'avav' tipomod,
a.mod_id,
i.movgest_ts_r_id,
i.movgest_ts_importo - coalesce(pending.importo_pending,0) movgest_ts_importo,
case when n.avav_tipo_code='FPVSC' then 1
	 when n.avav_tipo_code='FPVCC' then 1 when n.avav_tipo_code='AAM' then 2 else 3 end
		as tipoordinamento
FROM siac_t_modifica a,
siac_r_modifica_stato b,
siac_t_movgest_ts_det_mod c,
siac_d_modifica_stato d,
siac_d_movgest_ts_det_tipo e, siac_t_movgest_ts f, siac_t_movgest g,siac_d_movgest_tipo h,
siac_t_avanzovincolo l, siac_d_movgest_ts_tipo m,siac_d_avanzovincolo_tipo n,
siac_r_movgest_ts i left join siac_t_vincolo_pending  pending on ( pending.movgest_ts_r_id=i.movgest_ts_r_id and pending.data_cancellazione is null )
WHERE
a.mod_id=par_in--mod_id_in
 and
a.mod_id = b.mod_id AND
c.mod_stato_r_id = b.mod_stato_r_id AND
d.mod_stato_id = b.mod_stato_id and
e.movgest_ts_det_tipo_id=c.movgest_ts_det_tipo_id and
f.movgest_ts_id=c.movgest_ts_id and
g.movgest_id=f.movgest_id and
d.mod_stato_code='V' and
h.movgest_tipo_id=g.movgest_tipo_id and
h.movgest_tipo_code='I' and
c.mtdm_reimputazione_flag=true and
c.movgest_ts_det_importo<0 and
i.movgest_ts_b_id=f.movgest_ts_id and
i.movgest_ts_importo-coalesce(pending.importo_pending,0)>0 and -- con importo ancora da aggiornare
n.avav_tipo_id=l.avav_tipo_id and
now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now()) and
now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now()) and
m.movgest_ts_tipo_id=f.movgest_ts_tipo_id and
l.avav_id=i.avav_id and
i.movgest_ts_importo-coalesce(pending.importo_pending,0)> -- vincoli impegno FPV/AAM che non sono gia' stati aggiornati da on-line su mod.spesa
(
select coalesce(sum(rvinc.importo_delta ),0) importo_delta
from siac_r_modifica_vincolo rvinc
where rvinc.movgest_ts_r_id=i.movgest_ts_r_id
and   rvinc.mod_id=a.mod_id
and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
and   rvinc.data_cancellazione is null
and   rvinc.validita_fine is null
) and
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL and
e.data_cancellazione is null and
f.data_cancellazione is null and
g.data_cancellazione is null and
h.data_cancellazione is null and
i.data_cancellazione is null and
l.data_cancellazione is null and
m.data_cancellazione is null and
n.data_cancellazione is null
union
-- imp acc
SELECT
'impacc' tipomod,
a.mod_id,
i.movgest_ts_r_id,
i.movgest_ts_importo-coalesce(pending.importo_pending,0) movgest_ts_importo,
4 tipoordinamento
FROM siac_t_modifica a,
siac_r_modifica_stato b,
siac_t_movgest_ts_det_mod c,
siac_d_modifica_stato d,
siac_d_movgest_ts_det_tipo e, siac_t_movgest_ts f, siac_t_movgest g,siac_d_movgest_tipo h,
siac_t_movgest_ts l, siac_d_movgest_ts_tipo m,
siac_r_movgest_ts i left join siac_t_vincolo_pending  pending on ( pending.movgest_ts_r_id=i.movgest_ts_r_id and pending.data_cancellazione is null )
WHERE
a.mod_id=par_in--mod_id_in
and
a.mod_id = b.mod_id AND
c.mod_stato_r_id = b.mod_stato_r_id AND
d.mod_stato_id = b.mod_stato_id and
e.movgest_ts_det_tipo_id=c.movgest_ts_det_tipo_id and
f.movgest_ts_id=c.movgest_ts_id and
g.movgest_id=f.movgest_id and
d.mod_stato_code='V' and
h.movgest_tipo_id=g.movgest_tipo_id and
h.movgest_tipo_code='I' and
c.mtdm_reimputazione_flag=true and
c.movgest_ts_det_importo<0 and
i.movgest_ts_b_id=f.movgest_ts_id and
i.movgest_ts_importo-coalesce(pending.importo_pending,0)>0 and -- con importo ancora da aggiornare
now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now()) and
now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now()) and
m.movgest_ts_tipo_id=f.movgest_ts_tipo_id and
l.movgest_ts_id=i.movgest_ts_a_id and
i.movgest_ts_importo-coalesce(pending.importo_pending,0)>
(
select coalesce(sum(vinc.importo_delta),0)
FROM
(
--  vincoli impegno accertamento che non sono gia' stati aggiornati da on-line su mod.spesa (A)
-- (A)
(
select coalesce(sum(rvinc.importo_delta),0) importo_delta
from siac_r_modifica_vincolo rvinc
where rvinc.movgest_ts_r_id=i.movgest_ts_r_id
and   rvinc.mod_id=a.mod_id
and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
and   rvinc.data_cancellazione is null
and   rvinc.validita_fine is null
)
union
(
select coalesce(sum(rvinc_mod.importo_delta),0) importo_delta
from   siac_r_modifica_vincolo rvinc_mod,
       siac_r_modifica_stato rs_mod_acc,
       siac_t_movgest_ts_det_mod det_mod_acc,
	   siac_r_movgest_ts_det_mod rmod_acc

where rvinc_mod.movgest_ts_r_id=i.movgest_ts_r_id
and   rvinc_mod.modvinc_tipo_operazione='INSERIMENTO'
and   rs_mod_acc.mod_id=rvinc_mod.mod_id
and   det_mod_acc.mod_stato_r_id=rs_mod_acc.mod_stato_r_id
and   det_mod_acc.movgest_ts_id=i.movgest_ts_a_id
and   det_mod_acc.mtdm_reimputazione_flag=true
and   det_mod_acc.movgest_ts_det_importo<0
and   rmod_acc.movgest_ts_det_mod_entrata_id=det_mod_acc.movgest_ts_det_mod_id
and   rmod_acc.movgest_ts_det_mod_spesa_id=c.movgest_ts_det_mod_id
and   rs_mod_acc.mod_stato_id=d.mod_stato_id
and   rvinc_mod.data_cancellazione is null
and   rvinc_mod.validita_fine is null
and   rs_mod_acc.data_cancellazione is null
and   rs_mod_acc.validita_fine is null
and   det_mod_acc.data_cancellazione is null
and   det_mod_acc.validita_fine is null
)
) vinc
) and
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL and
e.data_cancellazione is null and
f.data_cancellazione is null and
g.data_cancellazione is null and
h.data_cancellazione is null and
i.data_cancellazione is null and
l.data_cancellazione is null and
m.data_cancellazione is null
) query
order
by 5 desc,2 asc,4 desc,
-- 21.07.2020 Sofia aggiunto ultimo ord. per coerenza rispetto codice java per calcolo
-- campo pending in elenco vincoli
3 desc;



begin

mod_id_in:=p_mod_id;

strMessaggio:='Aggiornamento pending vincoli da reimputazione - fnc_siac_vincoli_pending_modifica - mod_id='
             ||mod_id_in::varchar||'. Inizio.';
--raise notice '%',strMessaggio;

esito:='oknodata'::varchar;

strMessaggio:='Aggiornamento pending vincoli da reimputazione - fnc_siac_vincoli_pending_modifica - mod_id='
             ||mod_id_in::varchar||'. Lettura importo_mod_da_calare.';
--raise notice '%',strMessaggio;

-- calcolo importo della modifica  a parametro
SELECT abs(det_mod.movgest_ts_det_importo), det_mod.ente_proprietario_id
       into importo_mod_da_scalare, ente_proprietario_id_in
FROM siac_t_modifica mod,
     siac_r_modifica_stato rs_mod,
     siac_d_modifica_stato stato_mod,
     siac_t_movgest_ts ts,
     siac_t_movgest mov,
     siac_d_movgest_tipo tipo_mov,
     siac_t_movgest_ts_det_mod det_mod
WHERE mod.mod_id = mod_id_in
and   rs_mod.mod_id = mod.mod_id
and   det_mod.mod_stato_r_id = rs_mod.mod_stato_r_id
and   stato_mod.mod_stato_id = rs_mod.mod_stato_id
and   stato_mod.mod_stato_code = 'V'
and   ts.movgest_ts_id = det_mod.movgest_ts_id
and   mov.movgest_id = ts.movgest_id
and   tipo_mov.movgest_tipo_id = mov.movgest_tipo_id
and   tipo_mov.movgest_tipo_code = 'I'
and   det_mod.mtdm_reimputazione_flag=true
and   det_mod.movgest_ts_det_importo<0
and   now() BETWEEN rs_mod.validita_inizio
and   COALESCE(rs_mod.validita_fine, now())
and   mod.data_cancellazione IS NULL
and   rs_mod.data_cancellazione IS NULL
and   det_mod.data_cancellazione IS NULL
and   ts.data_cancellazione IS NULL
and   mov.data_cancellazione is null;

strMessaggio:='Aggiornamento pending vincoli da reimputazione - fnc_siac_vincoli_pending_modifica - mod_id='
             ||mod_id_in::varchar||'. Lettura importo_mod_da_calare='||coalesce(importo_mod_da_scalare,0)::varchar||'.';
--raise notice '%',strMessaggio;

-- calcolo dei delta sui vincoli impegno adeguati con la modifica  a parametro
if importo_mod_da_scalare is not null and
   importo_mod_da_scalare>0 then
   strMessaggio:='Aggiornamento pending vincoli da reimputazione - fnc_siac_vincoli_pending_modifica - mod_id='
             ||mod_id_in::varchar||'. Lettura importo_delta_vincolo su impegno.';
--   raise notice '%',strMessaggio;

   select sum(abs(rvinc.importo_delta)) into importo_delta_vincolo
   from siac_r_modifica_vincolo rvinc
   where rvinc.mod_id=mod_id_in
   and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
   and   rvinc.data_cancellazione is null
   and   rvinc.validita_fine is null;
   strMessaggio:='Aggiornamento pending vincoli da reimputazione - fnc_siac_vincoli_pending_modifica - mod_id='
             ||mod_id_in::varchar||'. Lettura importo_delta_vincolo su imp ='||coalesce(importo_delta_vincolo,0)::varchar||'.';
--   raise notice '%',strMessaggio;
   if importo_delta_vincolo is not null then
   		importo_mod_da_scalare:=importo_mod_da_scalare-importo_delta_vincolo;
   end if;

end if;

-- calcolo dei delta sui vincoli di accertamento legati sia (vincolo o mod_entrata)
-- a impegno della modifica a parametro
if importo_mod_da_scalare is not null and
   importo_mod_da_scalare>0 then

  strMessaggio:='Aggiornamento pending vincoli da reimputazione - fnc_siac_vincoli_pending_modifica - mod_id='
             ||mod_id_in::varchar||'. Lettura importo_delta_vincolo su accert.';
--  raise notice '%',strMessaggio;
  importo_delta_vincolo:=null;
  select sum(abs(rvinc_mod.importo_delta)) into importo_delta_vincolo
  from siac_r_modifica_stato rs_spesa,siac_d_modifica_stato stato_mod_spesa,
       siac_t_movgest_ts_det_mod det_mod_spesa,
       siac_r_movgest_ts_det_mod rmod_acc, siac_t_movgest_ts_det_mod det_mod_acc,
       siac_r_modifica_vincolo rvinc_mod,siac_r_movgest_ts rvinc,
       siac_r_modifica_stato rs_mod_acc
  where rs_spesa.mod_id=mod_id_in
  and   stato_mod_spesa.mod_stato_id=rs_spesa.mod_stato_id
  and   stato_mod_spesa.mod_Stato_code='V'
  and   det_mod_spesa.mod_stato_r_id=rs_spesa.mod_stato_r_id
  and   rmod_acc.movgest_ts_det_mod_spesa_id=det_mod_spesa.movgest_ts_det_mod_id
  and   det_mod_acc.movgest_ts_det_mod_id=rmod_acc.movgest_ts_det_mod_entrata_id
  and   det_mod_acc.mtdm_reimputazione_flag=true
  and   det_mod_acc.movgest_ts_det_importo<0
  and   rs_mod_acc.mod_stato_r_id=det_mod_acc.mod_stato_r_id
  and   rs_mod_acc.mod_Stato_id=stato_mod_spesa.mod_stato_id
  and   rvinc.movgest_ts_b_id=det_mod_spesa.movgest_ts_id
  and   rvinc.movgest_ts_a_id=det_mod_acc.movgest_ts_id
  and   rvinc_mod.movgest_ts_r_id=rvinc.movgest_ts_r_id
  and   rvinc_mod.mod_id=rs_mod_acc.mod_id
  and   rvinc_mod.modvinc_tipo_operazione='INSERIMENTO'
  and   rs_spesa.data_cancellazione is null
  and   rs_spesa.validita_fine is null
  and   det_mod_spesa.data_cancellazione is null
  and   det_mod_spesa.validita_fine is null
  and   rmod_acc.data_cancellazione is null
  and   rmod_acc.validita_fine is null
  and   det_mod_acc.data_cancellazione is null
  and   det_mod_acc.validita_fine is null
  and   rvinc_mod.data_cancellazione is null
  and   rvinc_mod.validita_fine is null
  and   rvinc.data_cancellazione is null
  and   rvinc.validita_fine is null
  and   rs_mod_acc.data_cancellazione is null
  and   rs_mod_acc.validita_fine is null;
  strMessaggio:='Aggiornamento pending vincoli da reimputazione - fnc_siac_vincoli_pending_modifica - mod_id='
             ||mod_id_in::varchar||'. Lettura importo_delta_vincolo su accert='||coalesce(importo_delta_vincolo,0)::varchar||'.';
--  raise notice '%',strMessaggio;
  if importo_delta_vincolo is not null then
   		importo_mod_da_scalare:=importo_mod_da_scalare-importo_delta_vincolo;
   end if;
end if;


strMessaggio:='Aggiornamento pending vincoli da reimputazione - fnc_siac_vincoli_pending_modifica - mod_id='
             ||mod_id_in::varchar||'. importo_mod_da_scalare='||coalesce(importo_mod_da_scalare,0)::varchar||'.';
--raise notice '%',strMessaggio;

if importo_mod_da_scalare>0 then
strMessaggio:='Aggiornamento pending vincoli da reimputazione - fnc_siac_vincoli_pending_modifica - mod_id='
             ||mod_id_in::varchar||'. Inizio loop di aggiornamento.';
--raise notice '%',strMessaggio;
for rec in cur(mod_id_in) loop
    if rec.movgest_ts_importo is not null and importo_mod_da_scalare>0 then
        if rec.movgest_ts_importo - importo_mod_da_scalare <=0 then

          esito:='ok';
          /*update siac_r_movgest_ts
          set movgest_ts_importo = 0,
              login_operazione = login_operazione_in,
              data_modifica = clock_timestamp()
          where movgest_ts_r_id = rec.movgest_ts_r_id;*/

          /*insert into siac_r_modifica_vincolo
          (mod_id, movgest_ts_r_id,
           modvinc_tipo_operazione, importo_delta, validita_inizio, ente_proprietario_id,
           login_operazione)
          values
          (mod_id_in, rec.movgest_ts_r_id, 'INSERIMENTO', -rec.movgest_ts_importo,
           clock_timestamp(), ente_proprietario_id_in, login_operazione_in || ' - ' ||
            'fnc_siac_riccertamento_reimp');*/
          h_result:=null;
	      update siac_t_vincolo_pending pending
          set    importo_pending =pending.importo_pending+rec.movgest_ts_importo
          where pending.movgest_ts_r_id=rec.movgest_ts_r_id
          and   pending.data_cancellazione is null
          returning pending.movgest_ts_r_id into h_result;

--		  raise notice 'h_result=%', h_result;

          if h_result is null then
            insert into siac_t_vincolo_pending
            (
              ente_proprietario_id,
              bil_anno,
              movgest_ts_r_id,
              importo_pending,
              login_operazione
            )
            values
            (
              ente_proprietario_id_in,
              p_anno_bilancio::varchar,
              rec.movgest_ts_r_id,
              rec.movgest_ts_importo,
              p_login_operazione
            );
		  end if;

          importo_mod_da_scalare:= importo_mod_da_scalare - rec.movgest_ts_importo;

        elsif rec.movgest_ts_importo - importo_mod_da_scalare > 0 then
          esito:='ok';
/*          update siac_r_movgest_ts
          set    movgest_ts_importo = movgest_ts_importo - importo_mod_da_scalare,
                 login_operazione=login_operazione_in,
                 data_modifica=clock_timestamp()
          where movgest_ts_r_id=rec.movgest_ts_r_id;*/

/*          insert into siac_r_modifica_vincolo
          (mod_id,movgest_ts_r_id,modvinc_tipo_operazione,
           importo_delta,validita_inizio,ente_proprietario_id,login_operazione )
          values
          (mod_id_in, rec.movgest_ts_r_id, 'INSERIMENTO',-importo_mod_da_scalare,clock_timestamp(),
           ente_proprietario_id_in,login_operazione_in||' - '||'fnc_siac_riccertamento_reimp' );*/

          h_result:=null;
          update siac_t_vincolo_pending pending
          set    importo_pending =pending.importo_pending+importo_mod_da_scalare
          where pending.movgest_ts_r_id=rec.movgest_ts_r_id
          and   pending.data_cancellazione is null
          returning pending.movgest_ts_r_id into h_result;

--          raise notice 'h_result=%', h_result;

		  if h_result is null then
            insert into siac_t_vincolo_pending
            (
              ente_proprietario_id,
              bil_anno,
              movgest_ts_r_id,
              importo_pending,
              login_operazione
            )
            values
            (
              ente_proprietario_id_in,
              p_anno_bilancio::varchar,
              rec.movgest_ts_r_id,
              importo_mod_da_scalare,
              p_login_operazione
            );
          end if;

          importo_mod_da_scalare:= importo_mod_da_scalare - importo_mod_da_scalare;

        end if;
    end if;
end loop;

end if;

strMessaggio:='Aggiornamento pending vincoli da reimputazione - fnc_siac_vincoli_pending_modifica - mod_id='
             ||mod_id_in::varchar||'. Fine esito='||esito||'.';
esito:='OK';
return esito;

EXCEPTION
WHEN others THEN
  esito:='ko';
  strMessaggio:='Aggiornamento pending vincoli da reimputazione - fnc_siac_vincoli_pending_modifica - mod_id='
             ||mod_id_in::varchar||'. Fine esito='||esito||'-  '||SQLSTATE||'-'||SQLERRM||'.';
--  RAISE NOTICE '%',strMessaggio;
RETURN esito;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;
alter function siac.fnc_siac_vincoli_pending_modifica(integer,integer,varchar,varchar,timestamp) owner to siac;