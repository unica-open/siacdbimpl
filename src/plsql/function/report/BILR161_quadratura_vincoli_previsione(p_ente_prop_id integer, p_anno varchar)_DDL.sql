/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR161_quadratura_vincoli_previsione" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  vincolo_cod varchar,
  capup_stanziamento_anno1 numeric,
  capup_stanziamento_anno2 numeric,
  capup_stanziamento_anno3 numeric,
  capup_stanziamento_cassa_anno1 numeric,
  capep_stanziamento_anno1 numeric,
  capep_stanziamento_anno2 numeric,
  capep_stanziamento_anno3 numeric,
  capep_stanziamento_cassa_anno1 numeric
) AS
$body$
DECLARE

RTN_MESSAGGIO text;
int_anno1 integer;
int_anno2 integer;
int_anno3 integer;

BEGIN
RTN_MESSAGGIO:='select 1';

int_anno1:=p_anno::integer;
int_anno2:=p_anno::integer+1;
int_anno3:=p_anno::integer+2;


return query
select *
from
(
with
vincoli_up as
(

select vincolo_code,
       stanziamento_anno1,
       stanziamento_anno2,
       stanziamento_anno3,
       stanziamento_cassa_anno1
from
(
with
cap as
(
select tipo.elem_tipo_code tipo_capitolo,
       e.elem_code::integer numero_capitolo,
       e.elem_code2::integer numero_articolo,
       e.elem_id
from siac_t_bil bil , siac_t_periodo per,
     siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
     siac_r_bil_elem_stato rs, siac_d_bil_elem_stato stato
where bil.ente_proprietario_id=p_ente_prop_id
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=int_anno1
and   e.bil_id=bil.bil_id
and   tipo.elem_tipo_id=e.elem_tipo_id
and   tipo.elem_tipo_code='CAP-UP'
and   rs.elem_id=e.elem_id
and   stato.elem_stato_id=rs.elem_stato_id
and   stato.elem_stato_code='VA'
and   e.data_cancellazione is null
and   e.validita_fine is  null
and   rs.data_cancellazione is null
and   rs.validita_fine is  null
order by 2,3
),
sta_anno1 as
(select det.elem_id, det.elem_det_id,
        det.elem_det_importo
 from siac_t_bil_elem_det det, siac_d_bil_elem_det_tipo tipod,
      siac_t_periodo per
 where  tipod.ente_proprietario_id=p_ente_prop_id
 and    tipod.elem_det_tipo_code='STA'
 and    det.elem_det_tipo_id=tipod.elem_det_tipo_id
 and    per.periodo_id=det.periodo_id
 and    per.anno::integer=int_anno1
 and    det.data_cancellazione is null
 and    det.validita_fine is null
),
sta_anno2 as
(select det.elem_id, det.elem_det_id,
        det.elem_det_importo
 from siac_t_bil_elem_det det, siac_d_bil_elem_det_tipo tipod,
      siac_t_periodo per
 where  tipod.ente_proprietario_id=p_ente_prop_id
 and    tipod.elem_det_tipo_code='STA'
 and    det.elem_det_tipo_id=tipod.elem_det_tipo_id
 and    per.periodo_id=det.periodo_id
 and    per.anno::integer=int_anno2
 and    det.data_cancellazione is null
 and    det.validita_fine is null
),
sta_anno3 as
(select det.elem_id, det.elem_det_id,
        det.elem_det_importo
 from siac_t_bil_elem_det det, siac_d_bil_elem_det_tipo tipod,
      siac_t_periodo per
 where  tipod.ente_proprietario_id=p_ente_prop_id
 and    tipod.elem_det_tipo_code='STA'
 and    det.elem_det_tipo_id=tipod.elem_det_tipo_id
 and    per.periodo_id=det.periodo_id
 and    per.anno::integer=int_anno3
 and    det.data_cancellazione is null
 and    det.validita_fine is null
),
sta_cassa_anno1 as
(select det.elem_id, det.elem_det_id,
        det.elem_det_importo
 from siac_t_bil_elem_det det, siac_d_bil_elem_det_tipo tipod,
      siac_t_periodo per
 where  tipod.ente_proprietario_id=p_ente_prop_id
 and    tipod.elem_det_tipo_code='SCA'
 and    det.elem_det_tipo_id=tipod.elem_det_tipo_id
 and    per.periodo_id=det.periodo_id
 and    per.anno::integer=int_anno1
 and    det.data_cancellazione is null
 and    det.validita_fine is null
),
vincolo_cap as
(
select vinc.vincolo_id,
       vinc.vincolo_code,
       rvinc.elem_id
from siac_t_vincolo vinc, siac_r_vincolo_stato rs,siac_d_vincolo_stato stato,
     siac_r_vincolo_bil_elem rvinc, siac_t_periodo per,
     siac_t_bil_elem e, siac_d_bil_elem_tipo tipoe
where rvinc.ente_proprietario_id=p_ente_prop_id
and   vinc.vincolo_id=rvinc.vincolo_id
and   rs.vincolo_id=vinc.vincolo_id
and   stato.vincolo_stato_id=rs.vincolo_stato_id
and   stato.vincolo_stato_code!='A'
and   per.periodo_id=vinc.periodo_id
and   per.anno::integer=int_anno1
and   e.elem_id=rvinc.elem_id
and   tipoe.elem_tipo_id=e.elem_tipo_id
and   tipoe.elem_tipo_code='CAP-UP'
and   vinc.data_cancellazione is null
and   vinc.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   rvinc.data_cancellazione is null
and   rvinc.validita_fine is null
)
select coalesce(vincolo_cap.vincolo_code,'NON-VINCOLATO') vincolo_code,
       sum(sta_anno1.elem_det_importo)       stanziamento_anno1,
       sum(sta_anno2.elem_det_importo)       stanziamento_anno2,
       sum(sta_anno3.elem_det_importo)       stanziamento_anno3,
       sum(sta_cassa_anno1.elem_det_importo) stanziamento_cassa_anno1
from sta_anno1,sta_anno2,sta_anno3, sta_cassa_anno1,
     cap
      left join vincolo_cap on ( cap.elem_id=vincolo_cap.elem_id )
where cap.elem_id=sta_anno1.elem_id
and   cap.elem_id=sta_anno2.elem_id
and   cap.elem_id=sta_anno3.elem_id
and   cap.elem_id=sta_cassa_anno1.elem_id
group by coalesce(vincolo_cap.vincolo_code,'NON-VINCOLATO')
) CAP_UP_QUERY
-- cap-up 589
),
vincoli_ep as
(
select vincolo_code,
       stanziamento_anno1,
       stanziamento_anno2,
       stanziamento_anno3,
       stanziamento_cassa_anno1
from
(
with
cap as
(
select tipo.elem_tipo_code tipo_capitolo,
       e.elem_code::integer numero_capitolo,
       e.elem_code2::integer numero_articolo,
       e.elem_id
from siac_t_bil bil , siac_t_periodo per,
     siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
     siac_r_bil_elem_stato rs, siac_d_bil_elem_stato stato
where bil.ente_proprietario_id=p_ente_prop_id
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=int_anno1
and   e.bil_id=bil.bil_id
and   tipo.elem_tipo_id=e.elem_tipo_id
and   tipo.elem_tipo_code='CAP-EP'
and   rs.elem_id=e.elem_id
and   stato.elem_stato_id=rs.elem_stato_id
and   stato.elem_stato_code='VA'
and   e.data_cancellazione is null
and   e.validita_fine is  null
and   rs.data_cancellazione is null
and   rs.validita_fine is  null
order by 2,3
),
sta_anno1 as
(select det.elem_id, det.elem_det_id,
        det.elem_det_importo
 from siac_t_bil_elem_det det, siac_d_bil_elem_det_tipo tipod,
      siac_t_periodo per
 where  tipod.ente_proprietario_id=p_ente_prop_id
 and    tipod.elem_det_tipo_code='STA'
 and    det.elem_det_tipo_id=tipod.elem_det_tipo_id
 and    per.periodo_id=det.periodo_id
 and    per.anno::integer=int_anno1
 and    det.data_cancellazione is null
 and    det.validita_fine is null
),
sta_anno2 as
(select det.elem_id, det.elem_det_id,
        det.elem_det_importo
 from siac_t_bil_elem_det det, siac_d_bil_elem_det_tipo tipod,
      siac_t_periodo per
 where  tipod.ente_proprietario_id=p_ente_prop_id
 and    tipod.elem_det_tipo_code='STA'
 and    det.elem_det_tipo_id=tipod.elem_det_tipo_id
 and    per.periodo_id=det.periodo_id
 and    per.anno::integer=int_anno2
 and    det.data_cancellazione is null
 and    det.validita_fine is null
),
sta_anno3 as
(select det.elem_id, det.elem_det_id,
        det.elem_det_importo
 from siac_t_bil_elem_det det, siac_d_bil_elem_det_tipo tipod,
      siac_t_periodo per
 where  tipod.ente_proprietario_id=p_ente_prop_id
 and    tipod.elem_det_tipo_code='STA'
 and    det.elem_det_tipo_id=tipod.elem_det_tipo_id
 and    per.periodo_id=det.periodo_id
 and    per.anno::integer=int_anno3
 and    det.data_cancellazione is null
 and    det.validita_fine is null
),
sta_cassa_anno1 as
(select det.elem_id, det.elem_det_id,
        det.elem_det_importo
 from siac_t_bil_elem_det det, siac_d_bil_elem_det_tipo tipod,
      siac_t_periodo per
 where  tipod.ente_proprietario_id=p_ente_prop_id
 and    tipod.elem_det_tipo_code='SCA'
 and    det.elem_det_tipo_id=tipod.elem_det_tipo_id
 and    per.periodo_id=det.periodo_id
 and    per.anno::integer=int_anno1
 and    det.data_cancellazione is null
 and    det.validita_fine is null
),
vincolo_cap as
(
select vinc.vincolo_id,
       vinc.vincolo_code,
       rvinc.elem_id
from siac_t_vincolo vinc, siac_r_vincolo_stato rs,siac_d_vincolo_stato stato,
     siac_r_vincolo_bil_elem rvinc, siac_t_periodo per,
     siac_t_bil_elem e, siac_d_bil_elem_tipo tipoe
where rvinc.ente_proprietario_id=p_ente_prop_id
and   vinc.vincolo_id=rvinc.vincolo_id
and   rs.vincolo_id=vinc.vincolo_id
and   stato.vincolo_stato_id=rs.vincolo_stato_id
and   stato.vincolo_stato_code!='A'
and   per.periodo_id=vinc.periodo_id
and   per.anno::integer=int_anno1
and   e.elem_id=rvinc.elem_id
and   tipoe.elem_tipo_id=e.elem_tipo_id
and   tipoe.elem_tipo_code='CAP-EP'
and   vinc.data_cancellazione is null
and   vinc.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   rvinc.data_cancellazione is null
and   rvinc.validita_fine is null
)
select coalesce(vincolo_cap.vincolo_code,'NON-VINCOLATO') vincolo_code,
       sum(sta_anno1.elem_det_importo)       stanziamento_anno1,
       sum(sta_anno2.elem_det_importo)       stanziamento_anno2,
       sum(sta_anno3.elem_det_importo)       stanziamento_anno3,
       sum(sta_cassa_anno1.elem_det_importo) stanziamento_cassa_anno1
from sta_anno1,sta_anno2,sta_anno3, sta_cassa_anno1,
     cap
      left join vincolo_cap on ( cap.elem_id=vincolo_cap.elem_id )
where cap.elem_id=sta_anno1.elem_id
and   cap.elem_id=sta_anno2.elem_id
and   cap.elem_id=sta_anno3.elem_id
and   cap.elem_id=sta_cassa_anno1.elem_id
group by coalesce(vincolo_cap.vincolo_code,'NON-VINCOLATO')
) CAP_EP_QUERY
-- 523
),
QUERY_VINCOLI as
(
select vincolo_code
from
(
with
cap as
(
select tipo.elem_tipo_code tipo_capitolo,
       e.elem_code::integer numero_capitolo,
       e.elem_code2::integer numero_articolo,
       e.elem_id
from siac_t_bil bil , siac_t_periodo per,
     siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
     siac_r_bil_elem_stato rs, siac_d_bil_elem_stato stato
where bil.ente_proprietario_id=p_ente_prop_id
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=int_anno1
and   e.bil_id=bil.bil_id
and   tipo.elem_tipo_id=e.elem_tipo_id
and   tipo.elem_tipo_code='CAP-UP'
and   rs.elem_id=e.elem_id
and   stato.elem_stato_id=rs.elem_stato_id
and   stato.elem_stato_code='VA'
and   e.data_cancellazione is null
and   e.validita_fine is  null
and   rs.data_cancellazione is null
and   rs.validita_fine is  null
order by 2,3
),
vincolo_cap as
(
select vinc.vincolo_id,
       vinc.vincolo_code,
       rvinc.elem_id
from siac_t_vincolo vinc, siac_r_vincolo_stato rs,siac_d_vincolo_stato stato,
     siac_r_vincolo_bil_elem rvinc, siac_t_periodo per,
     siac_t_bil_elem e, siac_d_bil_elem_tipo tipoe
where rvinc.ente_proprietario_id=p_ente_prop_id
and   vinc.vincolo_id=rvinc.vincolo_id
and   rs.vincolo_id=vinc.vincolo_id
and   stato.vincolo_stato_id=rs.vincolo_stato_id
and   stato.vincolo_stato_code!='A'
and   per.periodo_id=vinc.periodo_id
and   per.anno::integer=int_anno1
and   e.elem_id=rvinc.elem_id
and   tipoe.elem_tipo_id=e.elem_tipo_id
and   tipoe.elem_tipo_code='CAP-UP'
and   vinc.data_cancellazione is null
and   vinc.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   rvinc.data_cancellazione is null
and   rvinc.validita_fine is null
)
select coalesce(vincolo_cap.vincolo_code,'NON-VINCOLATO') vincolo_code
from cap
      left join vincolo_cap on ( cap.elem_id=vincolo_cap.elem_id )
group by coalesce(vincolo_cap.vincolo_code,'NON-VINCOLATO')
) CAP_UP_QUERY
-- cap-up 589
UNION
select vincolo_code
from
(
with
cap as
(
select tipo.elem_tipo_code tipo_capitolo,
       e.elem_code::integer numero_capitolo,
       e.elem_code2::integer numero_articolo,
       e.elem_id
from siac_t_bil bil , siac_t_periodo per,
     siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
     siac_r_bil_elem_stato rs, siac_d_bil_elem_stato stato
where bil.ente_proprietario_id=p_ente_prop_id
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=int_anno1
and   e.bil_id=bil.bil_id
and   tipo.elem_tipo_id=e.elem_tipo_id
and   tipo.elem_tipo_code='CAP-EP'
and   rs.elem_id=e.elem_id
and   stato.elem_stato_id=rs.elem_stato_id
and   stato.elem_stato_code='VA'
and   e.data_cancellazione is null
and   e.validita_fine is  null
and   rs.data_cancellazione is null
and   rs.validita_fine is  null
order by 2,3
),
vincolo_cap as
(
select vinc.vincolo_id,
       vinc.vincolo_code,
       rvinc.elem_id
from siac_t_vincolo vinc, siac_r_vincolo_stato rs,siac_d_vincolo_stato stato,
     siac_r_vincolo_bil_elem rvinc, siac_t_periodo per,
     siac_t_bil_elem e, siac_d_bil_elem_tipo tipoe
where rvinc.ente_proprietario_id=p_ente_prop_id
and   vinc.vincolo_id=rvinc.vincolo_id
and   rs.vincolo_id=vinc.vincolo_id
and   stato.vincolo_stato_id=rs.vincolo_stato_id
and   stato.vincolo_stato_code!='A'
and   per.periodo_id=vinc.periodo_id
and   per.anno::integer=int_anno1
and   e.elem_id=rvinc.elem_id
and   tipoe.elem_tipo_id=e.elem_tipo_id
and   tipoe.elem_tipo_code='CAP-EP'
and   vinc.data_cancellazione is null
and   vinc.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   rvinc.data_cancellazione is null
and   rvinc.validita_fine is null
)
select coalesce(vincolo_cap.vincolo_code,'NON-VINCOLATO') vincolo_code
from cap
      left join vincolo_cap on ( cap.elem_id=vincolo_cap.elem_id )
group by coalesce(vincolo_cap.vincolo_code,'NON-VINCOLATO')
) CAP_EP_QUERY
-- 538
)
select QUERY_VINCOLI.vincolo_code::varchar vincolo_cod,
       coalesce(vincoli_up.stanziamento_anno1,0)::numeric capup_stanziamento_anno1,
       coalesce(vincoli_up.stanziamento_anno2,0)::numeric capup_stanziamento_anno2,
       coalesce(vincoli_up.stanziamento_anno3,0)::numeric capup_stanziamento_anno3,
       coalesce(vincoli_up.stanziamento_cassa_anno1,0)::numeric capup_stanziamento_cassa_anno1,
       coalesce(vincoli_ep.stanziamento_anno1,0)::numeric capep_stanziamento_anno1,
       coalesce(vincoli_ep.stanziamento_anno2,0)::numeric capep_stanziamento_anno2,
       coalesce(vincoli_ep.stanziamento_anno3,0)::numeric capep_stanziamento_anno3,
       coalesce(vincoli_ep.stanziamento_cassa_anno1,0)::numeric capep_stanziamento_cassa_anno1
from  QUERY_VINCOLI
      left join vincoli_up  on (QUERY_VINCOLI.vincolo_code=vincoli_up.vincolo_code)
      left join vincoli_ep  on (QUERY_VINCOLI.vincolo_code=vincoli_ep.vincolo_code)
/*from vincoli_up, vincoli_ep
where vincoli_up.vincolo_code=vincoli_ep.vincolo_code*/
) QUERY_FINALE
order by 1;

    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
    return;
    when others  THEN
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;