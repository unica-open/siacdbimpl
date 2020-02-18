/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

CREATE OR REPLACE FUNCTION fnc_siac_dwh_capitolo_fpv
(
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE



v_user_table varchar;
params varchar;

BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_anno_bilancio IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Anno di bilancio nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

select fnc_siac_random_user()
into	v_user_table;

params := p_anno_bilancio||' - '||p_ente_proprietario_id::varchar||' - '||p_data::varchar;


insert into
siac_dwh_log_elaborazioni (
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values (
p_ente_proprietario_id,
'fnc_siac_dwh_capitolo_fpv',
params,
clock_timestamp(),
v_user_table
);

esito:= 'Inizio funzione carico legame capitolo di spesa - FPV (FNC_SIAC_DWH_CAPITOLO_FPV) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_capitolo_fpv
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;

insert into siac_dwh_capitolo_fpv
(
  ente_proprietario_id,
  ente_denominazione,
  bil_anno,
  cod_capitolo,
  cod_articolo,
  cod_ueb,
  desc_capitolo,
  desc_articolo,
  cod_tipo_capitolo,
  desc_tipo_capitolo,
  cod_capitolo_fpv,
  cod_articolo_fpv,
  cod_ueb_fpv,
  desc_capitolo_fpv,
  desc_articolo_fpv,
  cod_tipo_capitolo_fpv,
  desc_tipo_capitolo_fpv,
  cod_tipo_fpv,
  desc_tipo_fpv,
  importo_fpv
)
select
  query.ente_proprietario_id,
  query.ente_denominazione,
  query.bil_anno,
  query.cod_capitolo,
  query.cod_articolo,
  query.cod_ueb,
  query.desc_capitolo,
  query.desc_articolo,
  query.cod_tipo_capitolo,
  query.desc_tipo_capitolo,
  query.cod_capitolo_fpv,
  query.cod_articolo_fpv,
  query.cod_ueb_fpv,
  query.desc_capitolo_fpv,
  query.desc_articolo_fpv,
  query.cod_tipo_capitolo_fpv,
  query.desc_tipo_capitolo_fpv,
  query.cod_tipo_fpv,
  query.desc_tipo_fpv,
  query.importo_fpv
from
(
with
capitolo as
(
select tipo.elem_tipo_code,
       tipo.elem_tipo_desc,
       e.elem_id,
       e.elem_code,
       e.elem_code2,
       e.elem_code3,
       e.elem_desc,
       e.elem_desc2
from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
     siac_r_bil_elem_stato rs, siac_d_bil_elem_stato stato,
     siac_t_bil bil, siac_t_periodo per
where tipo.ente_proprietario_id=p_ente_proprietario_id
and   tipo.elem_tipo_code in ('CAP-UP','CAP-UG')
and   e.elem_tipo_id=tipo.elem_tipo_id
and   bil.bil_id=e.bil_id
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=p_anno_bilancio::integer
and   rs.elem_id=e.elem_id
and   stato.elem_stato_id=rs.elem_stato_id
and   stato.elem_stato_code!='AN'
and   rs.data_cancellazione is null
and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio)
and   date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
and   e.data_cancellazione is null
and   date_trunc('DAY',now())>=date_trunc('DAY',e.validita_inizio)
and   date_trunc('DAY',now())<=date_trunc('DAY',coalesce(e.validita_fine,date_trunc('DAY',now())))
),
capitolo_fpv as
(
select tipo.elem_tipo_code,
       tipo.elem_tipo_desc,
       e.elem_id,
       e.elem_code,
       e.elem_code2,
       e.elem_code3,
       e.elem_desc,
       e.elem_desc2,
       cat.elem_cat_code,
       cat.elem_cat_desc
from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
     siac_r_bil_elem_stato rs, siac_d_bil_elem_stato stato,
     siac_t_bil bil, siac_t_periodo per,
     siac_r_bil_elem_categoria rcat, siac_d_bil_elem_categoria cat
where tipo.ente_proprietario_id=p_ente_proprietario_id
and   e.elem_tipo_id=tipo.elem_tipo_id
and   bil.bil_id=e.bil_id
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=p_anno_bilancio::integer
and   rs.elem_id=e.elem_id
and   stato.elem_stato_id=rs.elem_stato_id
and   stato.elem_stato_code!='AN'
and   rcat.elem_id=e.elem_id
and   cat.elem_cat_id=rcat.elem_cat_id
and   cat.elem_cat_code like 'FPV%'
and   rs.data_cancellazione is null
and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio)
and   date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
and   e.data_cancellazione is null
and   date_trunc('DAY',now())>=date_trunc('DAY',e.validita_inizio)
and   date_trunc('DAY',now())<=date_trunc('DAY',coalesce(e.validita_fine,date_trunc('DAY',now())))
and   rcat.data_cancellazione is null
and   date_trunc('DAY',now())>=date_trunc('DAY',rcat.validita_inizio)
and   date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rcat.validita_fine,date_trunc('DAY',now())))
)
select
  ente.ente_proprietario_id,
  ente.ente_denominazione,
  p_anno_bilancio     bil_anno ,
  capitolo.elem_code  cod_capitolo,
  capitolo.elem_code2 cod_articolo,
  capitolo.elem_code3 cod_ueb,
  capitolo.elem_desc  desc_capitolo,
  capitolo.elem_desc2 desc_articolo,
  capitolo.elem_tipo_code cod_tipo_capitolo,
  capitolo.elem_tipo_desc desc_tipo_capitolo,
  capitolo_fpv.elem_code cod_capitolo_fpv,
  capitolo_fpv.elem_code2 cod_articolo_fpv,
  capitolo_fpv.elem_code3 cod_ueb_fpv,
  capitolo_fpv.elem_desc  desc_capitolo_fpv,
  capitolo_fpv.elem_desc2 desc_articolo_fpv,
  capitolo_fpv.elem_tipo_code cod_tipo_capitolo_fpv,
  capitolo_fpv.elem_tipo_desc desc_tipo_capitolo_fpv,
  capitolo_fpv.elem_cat_code  cod_tipo_fpv,
  capitolo_fpv.elem_cat_desc  desc_tipo_fpv,
  r.elem_fpv_importo               importo_fpv
from capitolo, capitolo_fpv, siac_r_bil_elem_fpv r,siac_t_ente_proprietario ente
where r.ente_proprietario_id=p_ente_proprietario_id
and   capitolo.elem_id=r.elem_id
and   capitolo_fpv.elem_id=r.elem_fpv_id
and   ente.ente_proprietario_id=p_ente_proprietario_id
and   r.data_cancellazione is null
and   r.validita_fine is null
) query;



esito:= 'Fine funzione carico legame capitolo di spesa - FPV (FNC_SIAC_DWH_CAPITOLO_FPV) - '||clock_timestamp();

RETURN NEXT;

update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico legame capitolo di spesa - FPV (FNC_SIAC_DWH_CAPITOLO_FPV) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;