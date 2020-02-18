/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_fpv_entrata_capitolo (
  programma_id_in integer,
  anno_in varchar
)
RETURNS TABLE (
  anno_out varchar,
  elem_id_out integer,
  elem_code_out varchar,
  elem_desc_out varchar,
  entrata_prevista numeric,
  fpv_entrata_spesa_corrente numeric,
  fpv_entrata_spesa_conto_capitale numeric,
  totale numeric,
  fpv_entrata_complessivo numeric
) AS
$body$
DECLARE
max_anno_ciclo integer;
min_anno_ciclo integer;
anno_ciclo integer;
v_user varchar;
rec_capitolo record;
DEF_NULL    constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

BEGIN
anno_out:=null;
elem_id_out:=null;
elem_code_out:=null;
elem_desc_out:=null;
entrata_prevista:=null;
fpv_entrata_spesa_corrente:=null;
fpv_entrata_spesa_conto_capitale:=null;
totale:=null;
fpv_entrata_complessivo:=null;
v_user:=fnc_siac_random_user();

min_anno_ciclo:=anno_in::integer;
anno_ciclo:=anno_in::integer;

--trovo gli anni su cui ciclare = anni su cui ci sono impegni collegati al programma
--limite inferiore ciclo = anno bil
--limite superiore ciclo = max anno degli impegni collegati al progetto


--trovo max
select max(mg.movgest_anno::integer) into max_anno_ciclo 
from
siac_t_programma p, 
siac_r_movgest_ts_programma mp, 
siac_t_movgest_ts mv, 
siac_t_movgest mg, 
siac_d_movgest_tipo ti
where
p.programma_id=programma_id_in
and p.programma_id=mp.programma_id
and mp.movgest_ts_id=mv.movgest_ts_id
and mv.movgest_id=mg.movgest_id
and mg.movgest_tipo_id=ti.movgest_tipo_id
and ti.movgest_tipo_code='I'
and p.data_cancellazione is null and
mp.data_cancellazione is null and
mv.data_cancellazione is null and
mg.data_cancellazione is null and
ti.data_cancellazione is null
;

if max_anno_ciclo is not null then


--per ogni anno x devo determintare:
--l'entrata prevista = sommatoria quote relative ad accertamenti dell'anno x collegati ad impegni legati al progetto
--fpv_entrata_spesa_conto_capitale anno x = quote di accertamento con anno < anno x e impegni >= anno x suddiviso in base al titolo dell'impegno in (2,3) 
--fpv_entrata_spesa_corrente anno x = quote di accertamento con anno < anno x e impegni >= anno x suddiviso in base al titolo dell'impegno not in (2,3)  
for anno_ciclo in min_anno_ciclo .. max_anno_ciclo loop


for rec_capitolo in
select rmob.elem_id elem_id_capitolo
from
siac_t_programma p, 
siac_r_movgest_ts_programma mp, 
siac_t_movgest_ts mv, 
siac_t_movgest mg, 
siac_d_movgest_tipo ti,
siac_r_movgest_bil_elem rmob
where
p.programma_id=programma_id_in
and p.programma_id=mp.programma_id
and mp.movgest_ts_id=mv.movgest_ts_id
and mv.movgest_id=mg.movgest_id
and mg.movgest_tipo_id=ti.movgest_tipo_id
and ti.movgest_tipo_code='I'
and p.data_cancellazione is null and
mp.data_cancellazione is null and
mv.data_cancellazione is null and
mg.data_cancellazione is null and
ti.data_cancellazione is null
and mg.movgest_anno=anno_ciclo
and rmob.movgest_id=mg.movgest_id
and rmob.data_cancellazione is null
loop

elem_id_out:=rec_capitolo.elem_id_capitolo;

select elem_code, elem_desc into elem_code_out, elem_desc_out 
from siac_t_bil_elem where elem_id=rec_capitolo.elem_id_capitolo;

--raise notice 'anno bilancio: % anno ciclo: %', anno_in, anno_ciclo;


select 
sum(r2.movgest_ts_importo) into entrata_prevista
/*,rmob.elem_id,
m_b.movgest_id movgest_id_b, m_b.movgest_numero movgest_numero_b, m_b.movgest_desc movgest_desc_b, m_b.movgest_anno movgest_anno_b,
mts_b2.movgest_ts_id movgest_ts_id_b,mts_b2.movgest_ts_code movgest_ts_code_b,
m_a.movgest_id movgest_id_a, m_a.movgest_numero movgest_numero_a, m_a.movgest_desc movgest_desc_a, m_a.movgest_anno movgest_anno_a,
mts_a2.movgest_ts_id movgest_ts_id_a,mts_a2.movgest_ts_code movgest_ts_code_a*/
from 
siac_r_movgest_ts r2, 
siac_t_movgest_ts mts_a2 ,--accertameto 
siac_t_movgest_ts mts_b2, --impegno
siac_t_movgest m_a,--accertameto 
siac_t_movgest m_b,--impegno,
siac_r_movgest_bil_elem rmob,
siac_t_programma p,
siac_r_movgest_ts_programma mp,
siac_t_bil bil,
siac_t_periodo pe
where 
p.programma_id=programma_id_in
and p.programma_id=mp.programma_id
and mp.movgest_ts_id=mts_b2.movgest_ts_id
and mts_b2.movgest_id=m_b.movgest_id
and r2.movgest_ts_b_id=mts_b2.movgest_ts_id
and pe.anno=anno_in
and mts_a2.movgest_ts_id=r2.movgest_ts_a_id
and m_a.movgest_id=mts_a2.movgest_id
and m_b.movgest_id=mts_b2.movgest_id
and m_a.movgest_anno::INTEGER=anno_ciclo
and rmob.movgest_id=m_b.movgest_id
and bil.bil_id=m_b.bil_id
and bil.periodo_id=pe.periodo_id
and r2.data_cancellazione is null
and mts_a2.data_cancellazione is null
and mts_b2.data_cancellazione is null
and m_a.data_cancellazione is null
and m_b.data_cancellazione is null
and rmob.elem_id=rec_capitolo.elem_id_capitolo;

if entrata_prevista is null then

entrata_prevista:=0;

end if;


select 
sum(tb.quota) into fpv_entrata_spesa_conto_capitale from (
select 
rmob.elem_id,
mg.movgest_id, 
mg.movgest_anno, 
mg.movgest_desc,
mv.movgest_ts_id, 
mv.movgest_ts_code,
mvgd.movgest_ts_det_importo importo_impegno,
r.movgest_ts_importo quota,
rmob.elem_id,
bcl.classif_id
,cl.classif_id macroaggregato_id,clt.classif_tipo_code macroaggregato, cl.classif_code macroaggregato_code,cl.classif_desc macroaggregato_desc, clt.classif_tipo_desc,
cl2.classif_id titolo_id, clt2.classif_tipo_code titolo, cl2.classif_code titolo_code, cl2.classif_desc titolo_desc
from 
siac_t_programma p,
siac_r_movgest_ts_programma mp,
siac_t_movgest_ts mv,
siac_t_movgest mg,
siac_d_movgest_tipo ti,
siac_t_movgest_ts_det mvgd,
siac_t_bil bil,
siac_d_movgest_ts_det_tipo mvtipo,
siac_r_movgest_bil_elem rmob,
siac_t_periodo pe,
siac_r_movgest_ts_stato rst,
siac_d_movgest_stato dst,
siac_r_movgest_ts r,
siac_t_movgest_ts mv2, -- accertamento
siac_t_movgest mg2 --accertamnto
,siac_r_bil_elem_class bcl,
siac_t_class cl,
siac_d_class_tipo clt,
siac_r_class_fam_tree ft,
siac_t_class cl2,
siac_d_class_tipo clt2
where
p.programma_id=programma_id_in
and p.programma_id=mp.programma_id
and mp.movgest_ts_id=mv.movgest_ts_id
and mv.movgest_id=mg.movgest_id
and mg.movgest_tipo_id=ti.movgest_tipo_id
and ti.movgest_tipo_code='I'
and mvgd.movgest_ts_id=mv.movgest_ts_id
and bil.bil_id=mg.bil_id 
and rmob.movgest_id=mg.movgest_id
and pe.periodo_id=bil.periodo_id
and pe.anno=anno_in
and mg.movgest_anno::integer>=anno_ciclo -- impegno
and mvtipo.movgest_ts_det_tipo_id=mvgd.movgest_ts_det_tipo_id
and mvtipo.movgest_ts_det_tipo_code='A'
and rst.movgest_ts_id=mv.movgest_ts_id
and rst.movgest_stato_id=dst.movgest_stato_id
and dst.movgest_stato_code<>'A'
and r.movgest_ts_b_id=mv.movgest_ts_id
and r.movgest_ts_a_id=mv2.movgest_ts_id
and mg2.movgest_id=mv2.movgest_id
and mg2.movgest_anno::integer<anno_ciclo --accertmanto
and bcl.elem_id=rmob.elem_id
and bcl.classif_id=cl.classif_id
and cl.classif_tipo_id=clt.classif_tipo_id
and clt.classif_tipo_code = 'MACROAGGREGATO'
and ft.classif_id=cl.classif_id
and ft.classif_id_padre=cl2.classif_id
and clt2.classif_tipo_id=cl2.classif_tipo_id
and now() between rst.validita_inizio and COALESCE(rst.validita_fine,now())
and now() between p.validita_inizio and COALESCE(p.validita_fine,now())
and now() between mp.validita_inizio and COALESCE(mp.validita_fine,now())
and now() between mv.validita_inizio and COALESCE(mv.validita_fine,now())
and now() between mg.validita_inizio and COALESCE(mg.validita_fine,now())
and now() between ti.validita_inizio and COALESCE(ti.validita_fine,now())
and now() between mvgd.validita_inizio and COALESCE(mvgd.validita_fine,now())
and now() between bil.validita_inizio and COALESCE(bil.validita_fine,now())
and now() between rmob.validita_inizio and COALESCE(rmob.validita_fine,now())
and now() between mvtipo.validita_inizio and COALESCE(mvtipo.validita_fine,now())
and now() between pe.validita_inizio and COALESCE(pe.validita_fine,now())
and now() between dst.validita_inizio and COALESCE(dst.validita_fine,now())
and now() between r.validita_inizio and COALESCE(r.validita_fine,now())
and now() between mv2.validita_inizio and COALESCE(mv2.validita_fine,now())
and now() between mg2.validita_inizio and COALESCE(mg2.validita_fine,now())
and now() between bcl.validita_inizio and COALESCE(bcl.validita_fine,now())
and now() between cl.validita_inizio and COALESCE(cl.validita_fine,now())
and now() between clt.validita_inizio and COALESCE(clt.validita_fine,now())
and now() between ft.validita_inizio and COALESCE(ft.validita_fine,now())
and now() between cl2.validita_inizio and COALESCE(cl2.validita_fine,now())
and now() between clt2.validita_inizio and COALESCE(clt2.validita_fine,now())
and p.data_cancellazione is null and
mp.data_cancellazione is null and
mv.data_cancellazione is null and
mg.data_cancellazione is null and
ti.data_cancellazione is null and
mvgd.data_cancellazione is null and
bil.data_cancellazione is null and
rmob.data_cancellazione is null and
mvtipo.data_cancellazione is null 
and pe.data_cancellazione is null
and rst.data_cancellazione is null
and dst.data_cancellazione is null
and r.data_cancellazione is null
and mv2.data_cancellazione  is null
and mg2.data_cancellazione  is null
and bcl.data_cancellazione is null
and cl.data_cancellazione is null
and clt.data_cancellazione is null
and ft.data_cancellazione is null
and cl2.data_cancellazione is null
and clt2.data_cancellazione is null
) tb where tb.titolo_code in ('2','3')
and rmob.elem_id=rec_capitolo.elem_id_capitolo;

if fpv_entrata_spesa_conto_capitale is null then

fpv_entrata_spesa_conto_capitale:=0;

end if;



select 
sum(tb.quota) into fpv_entrata_spesa_corrente from (
select 
rmob.elem_id,
mg.movgest_id, 
mg.movgest_anno, 
mg.movgest_desc,
mv.movgest_ts_id, 
mv.movgest_ts_code,
mvgd.movgest_ts_det_importo importo_impegno,
r.movgest_ts_importo quota,
rmob.elem_id,
bcl.classif_id
,cl.classif_id macroaggregato_id,clt.classif_tipo_code macroaggregato, cl.classif_code macroaggregato_code,cl.classif_desc macroaggregato_desc, clt.classif_tipo_desc,
cl2.classif_id titolo_id, clt2.classif_tipo_code titolo, cl2.classif_code titolo_code, cl2.classif_desc titolo_desc
from 
siac_t_programma p,
siac_r_movgest_ts_programma mp,
siac_t_movgest_ts mv,
siac_t_movgest mg,
siac_d_movgest_tipo ti,
siac_t_movgest_ts_det mvgd,
siac_t_bil bil,
siac_d_movgest_ts_det_tipo mvtipo,
siac_r_movgest_bil_elem rmob,
siac_t_periodo pe,
siac_r_movgest_ts_stato rst,
siac_d_movgest_stato dst,
siac_r_movgest_ts r,
siac_t_movgest_ts mv2, -- accertamento
siac_t_movgest mg2 --accertamnto
,siac_r_bil_elem_class bcl,
siac_t_class cl,
siac_d_class_tipo clt,
siac_r_class_fam_tree ft,
siac_t_class cl2,
siac_d_class_tipo clt2
where
p.programma_id=programma_id_in
and p.programma_id=mp.programma_id
and mp.movgest_ts_id=mv.movgest_ts_id
and mv.movgest_id=mg.movgest_id
and mg.movgest_tipo_id=ti.movgest_tipo_id
and ti.movgest_tipo_code='I'
and mvgd.movgest_ts_id=mv.movgest_ts_id
and bil.bil_id=mg.bil_id 
and rmob.movgest_id=mg.movgest_id
and pe.periodo_id=bil.periodo_id
and pe.anno=anno_in
and mg.movgest_anno::integer>=anno_ciclo -- impegno
and mvtipo.movgest_ts_det_tipo_id=mvgd.movgest_ts_det_tipo_id
and mvtipo.movgest_ts_det_tipo_code='A'
and rst.movgest_ts_id=mv.movgest_ts_id
and rst.movgest_stato_id=dst.movgest_stato_id
and dst.movgest_stato_code<>'A'
and r.movgest_ts_b_id=mv.movgest_ts_id
and r.movgest_ts_a_id=mv2.movgest_ts_id
and mg2.movgest_id=mv2.movgest_id
and mg2.movgest_anno::integer<anno_ciclo --accertmanto
and bcl.elem_id=rmob.elem_id
and bcl.classif_id=cl.classif_id
and cl.classif_tipo_id=clt.classif_tipo_id
and clt.classif_tipo_code = 'MACROAGGREGATO'
and ft.classif_id=cl.classif_id
and ft.classif_id_padre=cl2.classif_id
and clt2.classif_tipo_id=cl2.classif_tipo_id
and now() between rst.validita_inizio and COALESCE(rst.validita_fine,now())
and now() between p.validita_inizio and COALESCE(p.validita_fine,now())
and now() between mp.validita_inizio and COALESCE(mp.validita_fine,now())
and now() between mv.validita_inizio and COALESCE(mv.validita_fine,now())
and now() between mg.validita_inizio and COALESCE(mg.validita_fine,now())
and now() between ti.validita_inizio and COALESCE(ti.validita_fine,now())
and now() between mvgd.validita_inizio and COALESCE(mvgd.validita_fine,now())
and now() between bil.validita_inizio and COALESCE(bil.validita_fine,now())
and now() between rmob.validita_inizio and COALESCE(rmob.validita_fine,now())
and now() between mvtipo.validita_inizio and COALESCE(mvtipo.validita_fine,now())
and now() between pe.validita_inizio and COALESCE(pe.validita_fine,now())
and now() between dst.validita_inizio and COALESCE(dst.validita_fine,now())
and now() between r.validita_inizio and COALESCE(r.validita_fine,now())
and now() between mv2.validita_inizio and COALESCE(mv2.validita_fine,now())
and now() between mg2.validita_inizio and COALESCE(mg2.validita_fine,now())
and now() between bcl.validita_inizio and COALESCE(bcl.validita_fine,now())
and now() between cl.validita_inizio and COALESCE(cl.validita_fine,now())
and now() between clt.validita_inizio and COALESCE(clt.validita_fine,now())
and now() between ft.validita_inizio and COALESCE(ft.validita_fine,now())
and now() between cl2.validita_inizio and COALESCE(cl2.validita_fine,now())
and now() between clt2.validita_inizio and COALESCE(clt2.validita_fine,now())
and p.data_cancellazione is null and
mp.data_cancellazione is null and
mv.data_cancellazione is null and
mg.data_cancellazione is null and
ti.data_cancellazione is null and
mvgd.data_cancellazione is null and
bil.data_cancellazione is null and
rmob.data_cancellazione is null and
mvtipo.data_cancellazione is null 
and pe.data_cancellazione is null
and rst.data_cancellazione is null
and dst.data_cancellazione is null
and r.data_cancellazione is null
and mv2.data_cancellazione  is null
and mg2.data_cancellazione  is null
and bcl.data_cancellazione is null
and cl.data_cancellazione is null
and clt.data_cancellazione is null
and ft.data_cancellazione is null
and cl2.data_cancellazione is null
and clt2.data_cancellazione is null
) tb where tb.titolo_code not in ('2','3')
and rmob.elem_id=rec_capitolo.elem_id_capitolo;


if fpv_entrata_spesa_corrente is null then

fpv_entrata_spesa_corrente:=0;

end if;

anno_out :=anno_ciclo;



fpv_entrata_complessivo:= fpv_entrata_spesa_corrente +  fpv_entrata_spesa_conto_capitale;
totale:= entrata_prevista +  fpv_entrata_spesa_corrente +  fpv_entrata_spesa_conto_capitale;

return next;

end loop;

anno_ciclo:=anno_ciclo+1;

end loop;

end if; 

exception
    when no_data_found THEN
        raise notice 'nessun valore trovato' ;
        return;
        when others  THEN
        --RTN_MESSAGGIO:='capitolo altro errore';
         RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,SQLERRM;
return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;