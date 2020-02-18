/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR163_quadratura_capitoli_previsione_titolo" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  titolo varchar,
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
titoli as
(
select '1' titolo
union
select '2' titolo
union
select '3' titolo
union
select '4' titolo
union
select '5' titolo
union
select '6' titolo
union
select '7' titolo
union
select '8' titolo
union
select '9' titolo
union
select 'ND' titolo
),
capitoli_up_tit as
(
select CAP_UP_QUERY.*
from
(
with
capitoli_up as
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
)
select cap.tipo_capitolo,
       cap.numero_capitolo,
       cap.numero_articolo,
       cap.elem_id,
       sta_anno1.elem_det_importo stanziamento_anno1,
       sta_anno2.elem_det_importo stanziamento_anno2,
       sta_anno3.elem_det_importo stanziamento_anno3,
       sta_cassa_anno1.elem_det_importo stanziamento_cassa_anno1
from  cap,sta_anno1, sta_anno2,sta_anno3, sta_cassa_anno1
where sta_anno1.elem_id=cap.elem_id
and   sta_anno2.elem_id=cap.elem_id
and   sta_anno3.elem_id=cap.elem_id
and   sta_cassa_anno1.elem_id=cap.elem_id
),
titolo_cap as
(
	select titolo.classif_code titolo_code,
           rc.elem_id
    from  siac_r_bil_elem_class rc, siac_t_class c, siac_d_class_tipo tipoc,
    	  siac_r_class_fam_tree strTree,siac_t_class titolo
    where tipoc.ente_proprietario_id=p_ente_prop_id
    and   tipoc.classif_tipo_code='MACROAGGREGATO'
    and   c.classif_tipo_id=tipoc.classif_tipo_id
    and   rc.classif_id=c.classif_id
    and   strTree.classif_id=rc.classif_id
    and   titolo.classif_id=strTree.classif_id_padre
    and   rc.data_cancellazione is null
    and   rc.validita_fine is null
    and   strTree.data_cancellazione is null
    and   strTree.validita_fine is null
    and   c.data_cancellazione is null
    and   titolo.data_cancellazione is null
)
select coalesce(titolo_cap.titolo_code,'ND') titolo_code,
       coalesce(sum(capitoli_up.stanziamento_anno1),0) capup_stanziamento_anno1,
       coalesce(sum(capitoli_up.stanziamento_anno2),0) capup_stanziamento_anno2,
       coalesce(sum(capitoli_up.stanziamento_anno3),0) capup_stanziamento_anno3,
       coalesce(sum(capitoli_up.stanziamento_cassa_anno1),0) capup_stanziamento_cassa_anno1
from capitoli_up left join titolo_cap on (capitoli_up.elem_id=titolo_cap.elem_id)
group by coalesce(titolo_cap.titolo_code,'ND')
) CAP_UP_QUERY
),
capitoli_ep_tit as
(
select CAP_EP_QUERY.*
from
(
with
capitoli_ep as
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
)
select cap.tipo_capitolo,
       cap.numero_capitolo,
       cap.numero_articolo,
       cap.elem_id,
       sta_anno1.elem_det_importo stanziamento_anno1,
       sta_anno2.elem_det_importo stanziamento_anno2,
       sta_anno3.elem_det_importo stanziamento_anno3,
       sta_cassa_anno1.elem_det_importo stanziamento_cassa_anno1
from  cap,sta_anno1, sta_anno2,sta_anno3, sta_cassa_anno1
where sta_anno1.elem_id=cap.elem_id
and   sta_anno2.elem_id=cap.elem_id
and   sta_anno3.elem_id=cap.elem_id
and   sta_cassa_anno1.elem_id=cap.elem_id
),
titolo_cap as
(
	select titolo.classif_code titolo_code,
           rc.elem_id
    from  siac_r_bil_elem_class rc, siac_t_class c, siac_d_class_tipo tipoc,
    	  siac_r_class_fam_tree strTreeTip,siac_t_class tipologia ,
    	  siac_r_class_fam_tree strTreeTit,siac_t_class titolo
    where tipoc.ente_proprietario_id=p_ente_prop_id
    and   tipoc.classif_tipo_code='CATEGORIA'
    and   c.classif_tipo_id=tipoc.classif_tipo_id
    and   rc.classif_id=c.classif_id
    and   strTreeTip.classif_id=rc.classif_id
    and   tipologia.classif_id=strTreeTip.classif_id_padre
    and   strTreeTit.classif_id=tipologia.classif_id
    and   titolo.classif_id=strTreeTit.classif_id_padre
    and   rc.data_cancellazione is null
    and   rc.validita_fine is null
    and   strTreeTip.data_cancellazione is null
    and   strTreeTip.validita_fine is null
    and   strTreeTit.data_cancellazione is null
    and   strTreeTit.validita_fine is null
    and   c.data_cancellazione is null
    and   tipologia.data_cancellazione is null
    and   titolo.data_cancellazione is null
)
select coalesce(titolo_cap.titolo_code,'ND') titolo_code,
       coalesce(sum(capitoli_ep.stanziamento_anno1),0) capep_stanziamento_anno1,
       coalesce(sum(capitoli_ep.stanziamento_anno2),0) capep_stanziamento_anno2,
       coalesce(sum(capitoli_ep.stanziamento_anno3),0) capep_stanziamento_anno3,
       coalesce(sum(capitoli_ep.stanziamento_cassa_anno1),0) capep_stanziamento_cassa_anno1
from capitoli_ep left join titolo_cap on (capitoli_ep.elem_id=titolo_cap.elem_id)
group by coalesce(titolo_cap.titolo_code,'ND')
) CAP_EP_QUERY
)
select titoli.titolo::varchar,
       coalesce(sum(capitoli_up_tit.capup_stanziamento_anno1),0)::numeric capup_stanziamento_anno1,
       coalesce(sum(capitoli_up_tit.capup_stanziamento_anno2),0)::numeric capup_stanziamento_anno2,
       coalesce(sum(capitoli_up_tit.capup_stanziamento_anno3),0)::numeric capup_stanziamento_anno3,
       coalesce(sum(capitoli_up_tit.capup_stanziamento_cassa_anno1),0)::numeric capup_stanziamento_cassa_anno1,
       coalesce(sum(capitoli_ep_tit.capep_stanziamento_anno1),0)::numeric capep_stanziamento_anno1,
       coalesce(sum(capitoli_ep_tit.capep_stanziamento_anno2),0)::numeric capep_stanziamento_anno2,
       coalesce(sum(capitoli_ep_tit.capep_stanziamento_anno3),0)::numeric capep_stanziamento_anno3,
       coalesce(sum(capitoli_ep_tit.capep_stanziamento_cassa_anno1),0)::numeric capep_stanziamento_cassa_anno1
from titoli
     left join capitoli_up_tit on (titoli.titolo=capitoli_up_tit.titolo_code)
     left join capitoli_ep_tit on (titoli.titolo=capitoli_ep_tit.titolo_code)
group by titoli.titolo
order by 1) as zz;

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