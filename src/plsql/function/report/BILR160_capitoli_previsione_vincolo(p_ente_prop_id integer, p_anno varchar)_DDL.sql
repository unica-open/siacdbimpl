/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR160_capitoli_previsione_vincolo" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  vincolo_code varchar,
  tipo_capitolo varchar,
  titolo_code varchar,
  missione_code varchar,
  programma_code varchar,
  numero_capitolo integer,
  numero_articolo integer,
  desc_capitolo varchar,
  classif_cdr_code varchar,
  classif_cdc_code varchar,
  classif_pdc_fin_code varchar,
  classif_ric_code varchar,
  classif_tr_ue_code varchar,
  classif_cat_code varchar,
  classif_tipo_fin_code varchar,
  stanziamento_anno1 numeric,
  stanziamento_anno2 numeric,
  stanziamento_anno3 numeric,
  stanziamento_cassa numeric
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
-- estrazione capitoli di previsione per codice vincolo
select zz.* from (
with
QUERY_EU as
(
--- SPESA
select QUERY_CAP.*
--select QUERY_CAP.numero_capitolo, QUERY_CAP.numero_articolo, count(*)
from
(
with
capitoli as
(
with
cap as
(
select tipo.elem_tipo_code tipo_capitolo,
       e.elem_code::integer numero_capitolo,
       e.elem_code2::integer numero_articolo,
       replace(e.elem_desc,chr(13)||chr(10),'') desc_capitolo,
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
sta_cassa as
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
programma_cap as
(
	select tipoc.classif_tipo_code,
           missione.classif_code missione_code,
           c.classif_code programma_code,
           rc.elem_id
    from  siac_r_bil_elem_class rc, siac_t_class c, siac_d_class_tipo tipoc,
      	  siac_r_class_fam_tree strTree,siac_t_class missione
    where tipoc.ente_proprietario_id=p_ente_prop_id
    and   tipoc.classif_tipo_code='PROGRAMMA'
    and   c.classif_tipo_id=tipoc.classif_tipo_id
    and   rc.classif_id=c.classif_id
    and   strTree.classif_id=rc.classif_id
    and   missione.classif_id=strTree.classif_id_padre
    and   rc.data_cancellazione is null
    and   rc.validita_fine is null
    and   strTree.data_cancellazione is null
    and   strTree.validita_fine is null
    and   c.data_cancellazione is null
    and   missione.data_cancellazione is null
),
titolo_cap as
(
	select titolo.classif_code titolo_code,
	       titolo.classif_desc titolo_desc,
           c.classif_code macroagg_code,
           c.classif_desc macroagg_desc,
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
select cap.tipo_capitolo,
       cap.numero_capitolo,
       cap.numero_articolo,
       cap.desc_capitolo,
       cap.elem_id,
       titolo_cap.titolo_code,
       titolo_cap.titolo_desc,
       programma_cap.missione_code,
       programma_cap.programma_code,
       sta_anno1.elem_det_importo stanziamento_anno1,
       sta_anno2.elem_det_importo stanziamento_anno2,
       sta_anno3.elem_det_importo stanziamento_anno3,
       sta_cassa.elem_det_importo stanziamento_cassa 
from  cap,sta_anno1, sta_anno2,sta_anno3, programma_cap , titolo_cap, sta_cassa
where sta_anno1.elem_id=cap.elem_id
and   sta_anno2.elem_id=cap.elem_id
and   sta_anno3.elem_id=cap.elem_id
and   sta_cassa.elem_id=cap.elem_id
and   programma_cap.elem_id=cap.elem_id
and   titolo_cap.elem_id=cap.elem_id
-- -- 4777
),
cdc as
(
select rc.elem_id,
       c.classif_id classif_cdc_id,
       c.classif_code classif_cdc_code,
       c.classif_desc classif_cdc_desc,
       cdr.classif_id classif_cdr_id,
       cdr.classif_code classif_cdr_code,
       cdr.classif_desc classif_cdr_desc
from siac_t_class c, siac_d_class_tipo tipoc, siac_r_class_fam_tree strTree,siac_t_class cdr,
     siac_r_bil_elem_class rc
where tipoc.ente_proprietario_id=p_ente_prop_id
and   tipoc.classif_tipo_code='CDC'
and   c.classif_tipo_id=tipoc.classif_tipo_id
and   strTree.classif_id=c.classif_id
and   cdr.classif_id=strTree.classif_id_padre
and   rc.classif_id=c.classif_id
and   c.data_cancellazione is null
and   rc.data_cancellazione is null
and   rc.validita_fine is null
and   strTree.data_cancellazione is null
and   strTree.validita_fine is null
and   cdr.data_cancellazione is null
),
tipo_finanziamento_class as
(
select rc.elem_id,
       c.classif_id classif_tipo_fin_id,
       c.classif_code classif_tipo_fin_code,
       c.classif_desc  classif_tipo_fin_desc
from siac_d_class_tipo tipoc, siac_t_class c, siac_r_bil_elem_class rc
where tipoc.ente_proprietario_id=p_ente_prop_id
and   tipoc.classif_tipo_code='TIPO_FINANZIAMENTO'
and   c.classif_tipo_id=tipoc.classif_tipo_id
and   rc.classif_id=c.classif_id
and   rc.data_cancellazione is null
and   rc.validita_fine is null
and   c.data_cancellazione is null
),
spesa_ricorrente_class as
(
select rc.elem_id,
       c.classif_id classif_ric_id,
       c.classif_code classif_ric_code,
       c.classif_desc  classif_ric_desc
from siac_d_class_tipo tipoc, siac_t_class c, siac_r_bil_elem_class rc
where tipoc.ente_proprietario_id=p_ente_prop_id
and   tipoc.classif_tipo_code='RICORRENTE_SPESA'
and   c.classif_tipo_id=tipoc.classif_tipo_id
and   rc.classif_id=c.classif_id
and   rc.data_cancellazione is null
and   rc.validita_fine is null
and   c.data_cancellazione is null
),
transazione_ue_class as
(
select rc.elem_id,
       c.classif_id classif_tr_ue_id,
       c.classif_code classif_tr_ue_code,
       c.classif_desc  classif_tr_ue_desc
from siac_d_class_tipo tipoc, siac_t_class c, siac_r_bil_elem_class rc
where tipoc.ente_proprietario_id=p_ente_prop_id
and   tipoc.classif_tipo_code='TRANSAZIONE_UE_SPESA'
and   c.classif_tipo_id=tipoc.classif_tipo_id
and   rc.classif_id=c.classif_id
and   rc.data_cancellazione is null
and   rc.validita_fine is null
and   c.data_cancellazione is null
),
pdc_fin_class as
(
select rc.elem_id,
       tipoc.classif_tipo_code classif_tipo_pdc_fin_code,
       c.classif_id classif_pdc_fin_id,
       c.classif_code classif_pdc_fin_code,
       c.classif_desc  classif_pdc_fin_desc
from siac_d_class_tipo tipoc, siac_t_class c, siac_r_bil_elem_class rc
where tipoc.ente_proprietario_id=p_ente_prop_id
and   tipoc.classif_tipo_code like 'PDC_%'
and   c.classif_tipo_id=tipoc.classif_tipo_id
and   rc.classif_id=c.classif_id
and   rc.data_cancellazione is null
and   rc.validita_fine is null
and   c.data_cancellazione is null
and   c.validita_fine is null
),
classif_cat_cap as
(
select rcat.elem_id,
       cat.elem_cat_code classif_cat_code,
       cat.elem_cat_desc classif_cat_desc
from siac_r_bil_elem_categoria rcat, siac_d_bil_elem_categoria cat
where  cat.ente_proprietario_id=p_ente_prop_id
and    rcat.elem_cat_id=cat.elem_cat_id
and    rcat.data_cancellazione is null
and    rcat.validita_fine is null
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
select capitoli.tipo_capitolo,
       capitoli.numero_capitolo,
       capitoli.numero_articolo,
       capitoli.desc_capitolo,
       capitoli.elem_id,
       capitoli.titolo_code,
       capitoli.titolo_desc,
       capitoli.missione_code,
       capitoli.programma_code,
       capitoli.stanziamento_anno1,
       capitoli.stanziamento_anno2,
       capitoli.stanziamento_anno3,
       capitoli.stanziamento_cassa,
       cdc.classif_cdr_code,cdc.classif_cdr_desc,
       cdc.classif_cdc_code,cdc.classif_cdc_desc,
       classif_cat_cap.classif_cat_code,
       classif_cat_cap.classif_cat_desc,
       tipo_finanziamento_class.classif_tipo_fin_code,
       tipo_finanziamento_class.classif_tipo_fin_desc,
       spesa_ricorrente_class.classif_ric_code,
       spesa_ricorrente_class.classif_ric_desc,
       transazione_ue_class.classif_tr_ue_code,
       transazione_ue_class.classif_tr_ue_desc,
       pdc_fin_class.classif_tipo_pdc_fin_code,
       pdc_fin_class.classif_pdc_fin_code,
       pdc_fin_class.classif_pdc_fin_desc,
       vincolo_cap.vincolo_code
from capitoli
      left join cdc                      on ( capitoli.elem_id=cdc.elem_id )
      left join tipo_finanziamento_class on ( capitoli.elem_id=tipo_finanziamento_class.elem_id )
      left join spesa_ricorrente_class   on ( capitoli.elem_id=spesa_ricorrente_class.elem_id )
      left join transazione_ue_class     on ( capitoli.elem_id=transazione_ue_class.elem_id )
      left join pdc_fin_class            on ( capitoli.elem_id=pdc_fin_class.elem_id )
      left join classif_cat_cap          on ( capitoli.elem_id=classif_cat_cap.elem_id )
      left join vincolo_cap              on ( capitoli.elem_id=vincolo_cap.elem_id )
)
QUERY_CAP
/*where QUERY_CAP.vincolo_code is not null
group by QUERY_CAP.numero_capitolo, QUERY_CAP.numero_articolo
having count(*) >1
order by QUERY_CAP.numero_capitolo,QUERY_CAP.numero_articolo*/
UNION
--- ENTRATA
select QUERY_CAP.*
--select QUERY_CAP.numero_capitolo, QUERY_CAP.numero_articolo, count(*)
from
(
with
capitoli as
(
with
cap as
(
select tipo.elem_tipo_code tipo_capitolo,
       e.elem_code::integer numero_capitolo,
       e.elem_code2::integer numero_articolo,
       replace(e.elem_desc,chr(13)||chr(10),'') desc_capitolo,
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
sta_cassa as
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
titolo_cap as
(
	select titolo.classif_code titolo_code,
	       titolo.classif_desc titolo_desc,
           tipologia.classif_code tipologia_code,
           tipologia.classif_desc tipologia_desc,
           c.classif_code categoria_code,
           c.classif_desc categoria_desc,
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
select cap.tipo_capitolo,
       cap.numero_capitolo,
       cap.numero_articolo,
       cap.desc_capitolo,
       cap.elem_id,
       titolo_cap.titolo_code,
       titolo_cap.titolo_desc,
       '0'::varchar missione_code,
       '0'::varchar programma_code,
       sta_anno1.elem_det_importo stanziamento_anno1,
       sta_anno2.elem_det_importo stanziamento_anno2,
       sta_anno3.elem_det_importo stanziamento_anno3,
       sta_cassa.elem_det_importo stanziamento_cassa
from  sta_anno1, sta_anno2,sta_anno3,sta_cassa, cap
      left join titolo_cap on (cap.elem_id=titolo_cap.elem_id)
where sta_anno1.elem_id=cap.elem_id
and   sta_anno2.elem_id=cap.elem_id
and   sta_anno3.elem_id=cap.elem_id
and   sta_cassa.elem_id=cap.elem_id
-- -- 1088
),
cdc as
(
select rc.elem_id,
       c.classif_id classif_cdc_id,
       c.classif_code classif_cdc_code,
       c.classif_desc classif_cdc_desc,
       cdr.classif_id classif_cdr_id,
       cdr.classif_code classif_cdr_code,
       cdr.classif_desc classif_cdr_desc
from siac_t_class c, siac_d_class_tipo tipoc, siac_r_class_fam_tree strTree,siac_t_class cdr,
     siac_r_bil_elem_class rc
where tipoc.ente_proprietario_id=p_ente_prop_id
and   tipoc.classif_tipo_code='CDC'
and   c.classif_tipo_id=tipoc.classif_tipo_id
and   strTree.classif_id=c.classif_id
and   cdr.classif_id=strTree.classif_id_padre
and   rc.classif_id=c.classif_id
and   c.data_cancellazione is null
and   rc.data_cancellazione is null
and   rc.validita_fine is null
and   strTree.data_cancellazione is null
and   strTree.validita_fine is null
and   cdr.data_cancellazione is null
),
tipo_finanziamento_class as
(
select rc.elem_id,
       c.classif_id classif_tipo_fin_id,
       c.classif_code classif_tipo_fin_code,
       c.classif_desc  classif_tipo_fin_desc
from siac_d_class_tipo tipoc, siac_t_class c, siac_r_bil_elem_class rc
where tipoc.ente_proprietario_id=p_ente_prop_id
and   tipoc.classif_tipo_code='TIPO_FINANZIAMENTO'
and   c.classif_tipo_id=tipoc.classif_tipo_id
and   rc.classif_id=c.classif_id
and   rc.data_cancellazione is null
and   rc.validita_fine is null
and   c.data_cancellazione is null
),
entrata_ricorrente_class as
(
select rc.elem_id,
       c.classif_id classif_ric_id,
       c.classif_code classif_ric_code,
       c.classif_desc  classif_ric_desc
from siac_d_class_tipo tipoc, siac_t_class c, siac_r_bil_elem_class rc
where tipoc.ente_proprietario_id=p_ente_prop_id
and   tipoc.classif_tipo_code='RICORRENTE_ENTRATA'
and   c.classif_tipo_id=tipoc.classif_tipo_id
and   rc.classif_id=c.classif_id
and   rc.data_cancellazione is null
and   rc.validita_fine is null
and   c.data_cancellazione is null
),
transazione_ue_class as
(
select rc.elem_id,
       c.classif_id classif_tr_ue_id,
       c.classif_code classif_tr_ue_code,
       c.classif_desc  classif_tr_ue_desc
from siac_d_class_tipo tipoc, siac_t_class c, siac_r_bil_elem_class rc
where tipoc.ente_proprietario_id=p_ente_prop_id
and   tipoc.classif_tipo_code='TRANSAZIONE_UE_ENTRATA'
and   c.classif_tipo_id=tipoc.classif_tipo_id
and   rc.classif_id=c.classif_id
and   rc.data_cancellazione is null
and   rc.validita_fine is null
and   c.data_cancellazione is null
),
pdc_fin_class as
(
select rc.elem_id,
       tipoc.classif_tipo_code classif_tipo_pdc_fin_code,
       c.classif_id classif_pdc_fin_id,
       c.classif_code classif_pdc_fin_code,
       c.classif_desc  classif_pdc_fin_desc
from siac_d_class_tipo tipoc, siac_t_class c, siac_r_bil_elem_class rc
where tipoc.ente_proprietario_id=p_ente_prop_id
and   tipoc.classif_tipo_code like 'PDC_%'
and   c.classif_tipo_id=tipoc.classif_tipo_id
and   rc.classif_id=c.classif_id
and   rc.data_cancellazione is null
and   rc.validita_fine is null
and   c.data_cancellazione is null
and   c.validita_fine is null
),
classif_cat_cap as
(
select rcat.elem_id,
       cat.elem_cat_code classif_cat_code,
       cat.elem_cat_desc classif_cat_desc
from siac_r_bil_elem_categoria rcat, siac_d_bil_elem_categoria cat
where  cat.ente_proprietario_id=p_ente_prop_id
and    rcat.elem_cat_id=cat.elem_cat_id
and    rcat.data_cancellazione is null
and    rcat.validita_fine is null
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
select capitoli.tipo_capitolo,
       capitoli.numero_capitolo,
       capitoli.numero_articolo,
       capitoli.desc_capitolo,
       capitoli.elem_id,
       capitoli.titolo_code,
       capitoli.titolo_desc,
       capitoli.missione_code,
       capitoli.programma_code,
       capitoli.stanziamento_anno1,
       capitoli.stanziamento_anno2,
       capitoli.stanziamento_anno3,
       capitoli.stanziamento_cassa,
       cdc.classif_cdr_code,cdc.classif_cdr_desc,
       cdc.classif_cdc_code,cdc.classif_cdc_desc,
       classif_cat_cap.classif_cat_code,
       classif_cat_cap.classif_cat_desc,
       tipo_finanziamento_class.classif_tipo_fin_code,
       tipo_finanziamento_class.classif_tipo_fin_desc,
       entrata_ricorrente_class.classif_ric_code,
       entrata_ricorrente_class.classif_ric_desc,
       transazione_ue_class.classif_tr_ue_code,
       transazione_ue_class.classif_tr_ue_desc,
       pdc_fin_class.classif_tipo_pdc_fin_code,
       pdc_fin_class.classif_pdc_fin_code,
       pdc_fin_class.classif_pdc_fin_desc,
       vincolo_cap.vincolo_code
from capitoli
      left join cdc                      on ( capitoli.elem_id=cdc.elem_id )
      left join tipo_finanziamento_class on ( capitoli.elem_id=tipo_finanziamento_class.elem_id )
      left join entrata_ricorrente_class   on ( capitoli.elem_id=entrata_ricorrente_class.elem_id )
      left join transazione_ue_class     on ( capitoli.elem_id=transazione_ue_class.elem_id )
      left join pdc_fin_class            on ( capitoli.elem_id=pdc_fin_class.elem_id )
      left join classif_cat_cap          on ( capitoli.elem_id=classif_cat_cap.elem_id )
      left join vincolo_cap              on ( capitoli.elem_id=vincolo_cap.elem_id )
)
QUERY_CAP
/*where QUERY_CAP.vincolo_code is not null
group by QUERY_CAP.numero_capitolo, QUERY_CAP.numero_articolo
having count(*) >1
order by QUERY_CAP.numero_capitolo,QUERY_CAP.numero_articolo*/
)
SELECT QUERY_EU.vincolo_code::varchar,
       QUERY_EU.tipo_capitolo::varchar,
       QUERY_EU.titolo_code::varchar,
       QUERY_EU.missione_code::varchar,
       QUERY_EU.programma_code::varchar,
       QUERY_EU.numero_capitolo::integer,
       QUERY_EU.numero_articolo::integer,
       QUERY_EU.desc_capitolo::varchar,
       QUERY_EU.classif_cdr_code::varchar,
       QUERY_EU.classif_cdc_code::varchar,
       QUERY_EU.classif_pdc_fin_code::varchar,
       QUERY_EU.classif_ric_code::varchar,
	   QUERY_EU.classif_tr_ue_code::varchar,
       QUERY_EU.classif_cat_code::varchar,
       QUERY_EU.classif_tipo_fin_code::varchar,
	   QUERY_EU.stanziamento_anno1::numeric,
       QUERY_EU.stanziamento_anno2::numeric,
       QUERY_EU.stanziamento_anno3::numeric,
       QUERY_EU.stanziamento_cassa::numeric
from QUERY_EU
order by QUERY_EU.vincolo_code,
         QUERY_EU.titolo_code) as zz;

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