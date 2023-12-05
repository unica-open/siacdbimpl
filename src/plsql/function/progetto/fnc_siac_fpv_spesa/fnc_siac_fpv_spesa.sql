/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_fpv_spesa (
  programma_id_in integer,
  anno_in varchar
)
RETURNS TABLE (
  missione varchar,
  programma varchar,
  titolo varchar,
  anno_out varchar,
  spesa_prevista numeric,
  fpv_spesa numeric
) AS
$body$
DECLARE
max_anno_ciclo integer;
min_anno_ciclo integer;
anno_ciclo integer;
elem_id_out integer;
elem_code_out varchar;
elem_code2_out varchar;
elem_desc_out varchar;


rec_impegni record;
rec_fpv record;
rec_output record;

v_user varchar;



--rec_anni record;
--gest_rec record;
DEF_NULL    constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;


-- variabili impegno
movgest_id_out integer;
movgest_anno_out varchar;
movgest_desc_out varchar;
movgest_ts_id_out integer;
movgest_ts_code_out varchar;
importo_impegno_out numeric;
classif_id_missione_out integer;
classif_code_missione_out varchar;
classif_desc_missione_out varchar;
classif_tipo_code_missione_out varchar;
classif_id_programma_out integer;
classif_code_programma_out varchar;
classif_desc_programma_out varchar;
classif_tipo_code_programma_out varchar;
classif_id_titolo_out integer;
classif_code_titolo_out varchar;
classif_desc_titolo_out varchar;
classif_tipo_code_titolo_out varchar;
classif_id_macroaggregato_out integer;
classif_code_macroaggregato_out varchar;
classif_desc_macroaggregato_out varchar;
classif_tipo_code_macroaggregato_out varchar;

--variabili fpv
importo_fpv_out numeric;
elem_id_fpv_out integer;
movgest_id_imp_fpv_out integer;
movgest_code_imp_fpv_out varchar;
movgest_desc_imp_fpv_out varchar;
movgest_anno_imp_fpv_out varchar;
movgest_ts_id_imp_fpv_out integer;
movgest_ts_code_imp_fpv_out varchar;
movgest_id_acc_fpv_out integer;
movgest_code_acc_fpv_out varchar;
movgest_desc_acc_fpv_out varchar;
movgest_anno_acc_fpv_out varchar;
movgest_ts_id_acc_fpv_out integer;
movgest_ts_code_acc_fpv_out  varchar;
classif_id_missione_fpv_out integer;
classif_code_missione_fpv_out varchar;
classif_desc_missione_fpv_out varchar;
classif_tipo_code_missione_fpv_out varchar;
classif_id_programma_fpv_out integer;
classif_code_programma_fpv_out varchar;
classif_desc_programma_fpv_out varchar;
classif_tipo_code_programma_fpv_out varchar;
classif_id_titolo_fpv_out integer;
classif_code_titolo_fpv_out varchar;
classif_desc_titolo_fpv_out varchar;
classif_tipo_code_titolo_fpv_out varchar;
classif_id_macroaggregato_fpv_out integer;
classif_code_macroaggregato_fpv_out varchar;
classif_desc_macroaggregato_fpv_out varchar;
classif_tipo_code_macroaggregato_fpv_out varchar;


BEGIN

missione:=null;
programma:=null;
titolo:=null;
anno_out:=null;
spesa_prevista:=null;
fpv_spesa:=null;

v_user:=fnc_siac_random_user();

min_anno_ciclo:=anno_in::integer;
anno_ciclo:=anno_in::integer;

/*delete from siac_elab_fpv_spesa_imp;

delete from siac_elab_fpv_spesa_fpv;*/

--trovo gli anni su cui ciclare

--trovo max
select max(mg.movgest_anno::integer) into max_anno_ciclo from
siac_t_programma p, siac_r_movgest_ts_programma mp, siac_t_movgest_ts mv, siac_t_movgest mg, siac_d_movgest_tipo ti
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

for anno_ciclo in min_anno_ciclo .. max_anno_ciclo loop

raise notice 'anno bilancio: % anno ciclo: %', anno_in, anno_ciclo;

for rec_impegni in 
select 
rmob.elem_id,
mg.movgest_id, 
mg.movgest_anno, 
mg.movgest_desc,
mv.movgest_ts_id, 
mv.movgest_ts_code,
mvgd.movgest_ts_det_importo importo_impegno
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
siac_d_movgest_stato dst
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
and mg.movgest_anno::integer=anno_ciclo
and mvtipo.movgest_ts_det_tipo_id=mvgd.movgest_ts_det_tipo_id
and mvtipo.movgest_ts_det_tipo_code='A'
and rst.movgest_ts_id=mv.movgest_ts_id
and rst.movgest_stato_id=dst.movgest_stato_id
and dst.movgest_stato_code<>'A'
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


loop


elem_id_out:=rec_impegni.elem_id;
movgest_id_out:=rec_impegni.movgest_id;
movgest_anno_out:=rec_impegni.movgest_anno;
movgest_desc_out:=rec_impegni.movgest_desc;
movgest_ts_id_out:=rec_impegni.movgest_ts_id;
movgest_ts_code_out:=rec_impegni.movgest_ts_code;
importo_impegno_out:=rec_impegni.importo_impegno;

raise notice 'elem_id_out: %  movgest_id_out: % movgest_anno_out: %  movgest_desc_out: % movgest_ts_id_out:% movgest_ts_code_out: % importo_impegno_out: %' ,elem_id_out,movgest_id_out,movgest_anno_out,movgest_desc_out,movgest_ts_id_out,movgest_ts_code_out,importo_impegno_out;
/*raise notice 'movgest_id_out %' ,movgest_id_out;
raise notice 'movgest_anno_out %',movgest_anno_out;
raise notice 'movgest_desc_out %',movgest_desc_out;
raise notice 'movgest_ts_id_out %',movgest_ts_id_out;
raise notice 'movgest_ts_code_out %',movgest_ts_code_out;
raise notice 'importo_impegno_out %',importo_impegno_out;*/

--cerco classificatori collegati

--PROGRAMMA
select 
cl2.classif_id,cl2.classif_code,cl2.classif_desc,clt2.classif_tipo_code, ft2.classif_id_padre  
into 
   classif_id_programma_out ,  classif_code_programma_out ,  classif_desc_programma_out ,   classif_tipo_code_programma_out,
   classif_id_missione_out
from 
siac_t_class cl2, siac_r_bil_elem_class rcl2, siac_r_class_fam_tree ft2, siac_t_class_fam_tree cf2, siac_d_class_fam df2,
siac_d_class_tipo clt2
where 
rcl2.elem_id=elem_id_out AND
rcl2.classif_id=cl2.classif_id  
and ft2.classif_id=cl2.classif_id
and ft2.classif_fam_tree_id=cf2.classif_fam_tree_id
and df2.classif_fam_id=cf2.classif_fam_id
and df2.classif_fam_desc='Spesa - MissioniProgrammi'
and cl2.classif_tipo_id=clt2.classif_tipo_id
and clt2.classif_tipo_code='PROGRAMMA';

--trova missione papà del programma

select clpa.classif_code,clpa.classif_desc, clt2.classif_tipo_code 
into classif_code_missione_out ,  classif_desc_missione_out ,   classif_tipo_code_missione_out
from siac_t_class clpa,siac_d_class_tipo clt2
where 
clpa.classif_tipo_id=clt2.classif_tipo_id and
clpa.classif_id=classif_id_missione_out;

--MACROAGGREGATO
select 
cl2.classif_id,cl2.classif_code,cl2.classif_desc,clt2.classif_tipo_code, ft2.classif_id_padre into 
   classif_id_macroaggregato_out , classif_code_macroaggregato_out ,  classif_desc_macroaggregato_out ,   
   classif_tipo_code_macroaggregato_out, classif_id_titolo_out
from 
siac_t_class cl2, siac_r_bil_elem_class rcl2, siac_r_class_fam_tree ft2, siac_t_class_fam_tree cf2, siac_d_class_fam df2,
siac_d_class_tipo clt2
where 
rcl2.elem_id=elem_id_out and
rcl2.classif_id=cl2.classif_id  
and ft2.classif_id=cl2.classif_id
and ft2.classif_fam_tree_id=cf2.classif_fam_tree_id
and df2.classif_fam_id=cf2.classif_fam_id
and df2.classif_fam_desc='Spesa - TitoliMacroaggregati'
and cl2.classif_tipo_id=clt2.classif_tipo_id
and clt2.classif_tipo_code='MACROAGGREGATO';


--trova titolo papà del macroaggragato

select clpa.classif_code,clpa.classif_desc, clt2.classif_tipo_code 
into classif_code_titolo_out ,  classif_desc_titolo_out ,   classif_tipo_code_titolo_out
from siac_t_class clpa,siac_d_class_tipo clt2
where 
clpa.classif_tipo_id=clt2.classif_tipo_id and
clpa.classif_id=classif_id_titolo_out;

--anno_out:=anno_ciclo;
--importo_out:=importo_impegno_out;

insert into siac_elab_fpv_spesa_imp
(programma_id,anno_bilancio,anno,elem_id, movgest_id,movgest_anno,movgest_desc,movgest_ts_id,movgest_ts_code,importo_impegno,
classif_id_missione,classif_code_missione,classif_desc_missione,classif_tipo_code_missione,classif_id_programma,
classif_code_programma,classif_desc_programma,classif_tipo_code_programma,classif_id_titolo,classif_code_titolo,
classif_desc_titolo,classif_tipo_code_titolo, user_code
)
values (
programma_id_in , anno_in , anno_ciclo ,elem_id_out, movgest_id_out,movgest_anno_out,movgest_desc_out,movgest_ts_id_out,
movgest_ts_code_out,importo_impegno_out,
classif_id_missione_out,classif_code_missione_out,classif_desc_missione_out,classif_tipo_code_missione_out,
classif_id_programma_out,classif_code_programma_out,classif_desc_programma_out,classif_tipo_code_programma_out,
classif_id_titolo_out,classif_code_titolo_out,classif_desc_titolo_out,classif_tipo_code_titolo_out,
v_user
);


end loop;

--calcolo FPV


--per ogni capitolo trovo la somma degli importi degli accertamenti (su tab R) 
-- dove anno impegno > anno_ciclo e anno accertamento <= anno_ciclo

raise notice 'programma_id_in:%', programma_id_in;
raise notice 'anno_ciclo:%',anno_ciclo;

for rec_fpv in 
select 
r2.movgest_ts_importo,
rmob.elem_id,
m_b.movgest_id movgest_id_b, m_b.movgest_numero movgest_numero_b, m_b.movgest_desc movgest_desc_b, m_b.movgest_anno movgest_anno_b,
mts_b2.movgest_ts_id movgest_ts_id_b,mts_b2.movgest_ts_code movgest_ts_code_b,
m_a.movgest_id movgest_id_a, m_a.movgest_numero movgest_numero_a, m_a.movgest_desc movgest_desc_a, m_a.movgest_anno movgest_anno_a,
mts_a2.movgest_ts_id movgest_ts_id_a,mts_a2.movgest_ts_code movgest_ts_code_a
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
and m_b.movgest_anno::integer>anno_ciclo
and m_a.movgest_anno::INTEGER<=anno_ciclo
and rmob.movgest_id=m_b.movgest_id
and bil.bil_id=m_b.bil_id
and bil.periodo_id=pe.periodo_id
and r2.data_cancellazione is null
and mts_a2.data_cancellazione is null
and mts_b2.data_cancellazione is null
and m_a.data_cancellazione is null
and m_b.data_cancellazione is null
loop


importo_fpv_out:=rec_fpv.movgest_ts_importo;
elem_id_fpv_out:=rec_fpv.elem_id;
movgest_id_imp_fpv_out:=rec_fpv.movgest_id_b;
movgest_code_imp_fpv_out:=rec_fpv.movgest_numero_b;
movgest_desc_imp_fpv_out:=rec_fpv.movgest_desc_b;
movgest_anno_imp_fpv_out:=rec_fpv.movgest_anno_b;
movgest_ts_id_imp_fpv_out:=rec_fpv.movgest_ts_id_b;
movgest_ts_code_imp_fpv_out:=rec_fpv.movgest_ts_code_b;
movgest_id_acc_fpv_out:=rec_fpv.movgest_id_a;
movgest_code_acc_fpv_out:=rec_fpv.movgest_numero_a;
movgest_desc_acc_fpv_out:=rec_fpv.movgest_desc_a;
movgest_anno_acc_fpv_out:=rec_fpv.movgest_anno_a;
movgest_ts_id_acc_fpv_out:=rec_fpv.movgest_ts_id_a;
movgest_ts_code_acc_fpv_out:=rec_fpv.movgest_ts_code_a;



raise notice 'importo_fpv_out:%',importo_fpv_out;
raise notice 'elem_id_fpv_out:%',elem_id_fpv_out;
raise notice 'movgest_id_imp_fpv_out:%',movgest_id_imp_fpv_out;
raise notice 'movgest_code_imp_fpv_out:%',movgest_code_imp_fpv_out;
raise notice 'movgest_desc_imp_fpv_out:%',movgest_desc_imp_fpv_out;
raise notice 'movgest_anno_imp_fpv_out:%',movgest_anno_imp_fpv_out;
raise notice 'movgest_ts_id_imp_fpv_out:%',movgest_ts_id_imp_fpv_out;
raise notice 'movgest_ts_code_imp_fpv_out:%',movgest_ts_code_imp_fpv_out;
raise notice 'movgest_id_acc_fpv_out:%',movgest_id_acc_fpv_out;
raise notice 'movgest_code_acc_fpv_out:%',movgest_code_acc_fpv_out;
raise notice 'movgest_desc_acc_fpv_out:%',movgest_desc_acc_fpv_out;
raise notice 'movgest_anno_acc_fpv_out:%',movgest_anno_acc_fpv_out;
raise notice 'movgest_ts_id_acc_fpv_out:%',movgest_ts_id_acc_fpv_out;
raise notice 'movgest_ts_code_acc_fpv_out:%',movgest_ts_code_acc_fpv_out;


--cerco classificatori collegati

--PROGRAMMA
select 
cl2.classif_id,cl2.classif_code,cl2.classif_desc,clt2.classif_tipo_code, ft2.classif_id_padre  
into 
classif_id_programma_fpv_out,classif_code_programma_fpv_out,classif_desc_programma_fpv_out,
classif_tipo_code_programma_fpv_out,classif_id_missione_fpv_out
from 
siac_t_class cl2, siac_r_bil_elem_class rcl2, siac_r_class_fam_tree ft2, siac_t_class_fam_tree cf2, siac_d_class_fam df2,
siac_d_class_tipo clt2
where 
rcl2.elem_id=elem_id_fpv_out AND
rcl2.classif_id=cl2.classif_id  
and ft2.classif_id=cl2.classif_id
and ft2.classif_fam_tree_id=cf2.classif_fam_tree_id
and df2.classif_fam_id=cf2.classif_fam_id
and df2.classif_fam_desc='Spesa - MissioniProgrammi'
and cl2.classif_tipo_id=clt2.classif_tipo_id
and clt2.classif_tipo_code='PROGRAMMA';

--trova missione papà del programma

select clpa.classif_code,clpa.classif_desc, clt2.classif_tipo_code 
into classif_code_missione_fpv_out ,  classif_desc_missione_fpv_out ,   classif_tipo_code_missione_fpv_out
from siac_t_class clpa,siac_d_class_tipo clt2
where 
clpa.classif_tipo_id=clt2.classif_tipo_id and
clpa.classif_id=classif_id_missione_fpv_out;

--MACROAGGREGATO
select 
cl2.classif_id,cl2.classif_code,cl2.classif_desc,clt2.classif_tipo_code, ft2.classif_id_padre 
into 
classif_id_macroaggregato_fpv_out , classif_code_macroaggregato_fpv_out ,  classif_desc_macroaggregato_fpv_out ,   
classif_tipo_code_macroaggregato_fpv_out, classif_id_titolo_fpv_out
from 
siac_t_class cl2, siac_r_bil_elem_class rcl2, siac_r_class_fam_tree ft2, siac_t_class_fam_tree cf2, siac_d_class_fam df2,
siac_d_class_tipo clt2
where 
rcl2.elem_id=elem_id_fpv_out and
rcl2.classif_id=cl2.classif_id  
and ft2.classif_id=cl2.classif_id
and ft2.classif_fam_tree_id=cf2.classif_fam_tree_id
and df2.classif_fam_id=cf2.classif_fam_id
and df2.classif_fam_desc='Spesa - TitoliMacroaggregati'
and cl2.classif_tipo_id=clt2.classif_tipo_id
and clt2.classif_tipo_code='MACROAGGREGATO';


--trova titolo papà del macroaggragato

select clpa.classif_code,clpa.classif_desc, clt2.classif_tipo_code 
into classif_code_titolo_fpv_out ,  classif_desc_titolo_fpv_out ,   classif_tipo_code_titolo_fpv_out
from siac_t_class clpa,siac_d_class_tipo clt2
where 
clpa.classif_tipo_id=clt2.classif_tipo_id and
clpa.classif_id=classif_id_titolo_fpv_out;

insert into siac_elab_fpv_spesa_fpv (
programma_id,anno_bilancio,anno,importo_fpv,elem_id,
movgest_id_imp,movgest_code_imp ,movgest_desc_imp ,movgest_anno_imp ,
movgest_ts_id_imp ,movgest_ts_code_imp ,
movgest_id_acc ,movgest_code_acc ,movgest_desc_acc ,movgest_anno_acc ,
movgest_ts_id_acc ,movgest_ts_code_acc,
classif_id_missione ,classif_code_missione ,classif_desc_missione ,
classif_tipo_code_missione ,classif_id_programma ,classif_code_programma ,classif_desc_programma ,
classif_tipo_code_programma ,classif_id_titolo ,classif_code_titolo ,classif_desc_titolo ,
classif_tipo_code_titolo, user_code
 )
values(
programma_id_in,anno_in,anno_ciclo,importo_fpv_out,elem_id_fpv_out,
movgest_id_imp_fpv_out,movgest_code_imp_fpv_out,movgest_desc_imp_fpv_out,movgest_anno_imp_fpv_out,
movgest_ts_id_imp_fpv_out,movgest_ts_code_imp_fpv_out,
movgest_id_acc_fpv_out,movgest_code_acc_fpv_out,movgest_desc_acc_fpv_out,movgest_anno_acc_fpv_out,
movgest_ts_id_acc_fpv_out,movgest_ts_code_acc_fpv_out,
classif_id_missione_fpv_out,classif_code_missione_fpv_out,classif_desc_missione_fpv_out,
classif_tipo_code_missione_fpv_out,classif_id_programma_fpv_out,classif_code_programma_fpv_out,classif_desc_programma_fpv_out,
classif_tipo_code_programma_fpv_out,classif_id_titolo_fpv_out,classif_code_titolo_fpv_out,classif_desc_titolo_fpv_out,
classif_tipo_code_titolo_fpv_out, v_user
);

end loop;

anno_ciclo:=anno_ciclo+1;


end loop;


for rec_output in
 SELECT tb.anno,
         tb.classif_code_missione,
         tb.classif_code_programma,
         tb.classif_code_titolo,
         tb2.importo_impegno,
         tb.importo_fpv
  FROM (
         SELECT fpv.anno,
                fpv.classif_id_missione,
                fpv.classif_code_missione,
                fpv.classif_desc_missione,
                fpv.classif_id_programma,
                fpv.classif_code_programma,
                fpv.classif_desc_programma,
                fpv.classif_id_titolo,
                fpv.classif_code_titolo,
                fpv.classif_desc_titolo,
                sum(0) AS importo_impegno,
                sum(fpv.importo_fpv) AS importo_fpv
         FROM siac_elab_fpv_spesa_fpv fpv
         where fpv.user_code=v_user
         GROUP BY fpv.anno,
                  fpv.classif_id_missione,
                  fpv.classif_code_missione,
                  fpv.classif_desc_missione,
                  fpv.classif_id_programma,
                  fpv.classif_code_programma,
                  fpv.classif_desc_programma,
                  fpv.classif_id_titolo,
                  fpv.classif_code_titolo,
                  fpv.classif_desc_titolo
       ) tb,
       (
         SELECT imp.anno,
                imp.classif_id_missione,
                imp.classif_code_missione,
                imp.classif_desc_missione,
                imp.classif_id_programma,
                imp.classif_code_programma,
                imp.classif_desc_programma,
                imp.classif_id_titolo,
                imp.classif_code_titolo,
                imp.classif_desc_titolo,
                sum(imp.importo_impegno) AS importo_impegno,
                sum(0) AS importo_fpv
         FROM siac_elab_fpv_spesa_imp imp
         where imp.user_code=v_user
         GROUP BY imp.anno,
                  imp.classif_id_missione,
                  imp.classif_code_missione,
                  imp.classif_desc_missione,
                  imp.classif_id_programma,
                  imp.classif_code_programma,
                  imp.classif_desc_programma,
                  imp.classif_id_titolo,
                  imp.classif_code_titolo,
                  imp.classif_desc_titolo
       ) tb2
  WHERE tb.classif_id_missione = tb2.classif_id_missione AND
        tb.classif_id_programma = tb2.classif_id_programma AND
        tb.classif_id_titolo = tb2.classif_id_titolo AND
        tb.anno::text = tb2.anno::text
  UNION
  SELECT tb.anno,
         tb.classif_code_missione,
         tb.classif_code_programma,
         tb.classif_code_titolo,
         tb.importo_impegno,
         0 AS importo_fpv
  FROM (
         SELECT imp.anno,
                imp.classif_id_missione,
                imp.classif_code_missione,
                imp.classif_desc_missione,
                imp.classif_id_programma,
                imp.classif_code_programma,
                imp.classif_desc_programma,
                imp.classif_id_titolo,
                imp.classif_code_titolo,
                imp.classif_desc_titolo,
                sum(imp.importo_impegno) AS importo_impegno
         FROM siac_elab_fpv_spesa_imp imp
         WHERE imp.user_code=v_user and NOT EXISTS (
                             SELECT 1
                             FROM siac_elab_fpv_spesa_fpv fpv
                             WHERE 
                             fpv.user_code=v_user and
                             fpv.classif_id_missione =
                               imp.classif_id_missione AND
                                   fpv.classif_id_programma =
                                     imp.classif_id_programma AND
                                   fpv.classif_id_titolo = imp.classif_id_titolo
  AND
                                   fpv.anno::text = imp.anno::text
               )
         GROUP BY imp.anno,
                  imp.classif_id_missione,
                  imp.classif_code_missione,
                  imp.classif_desc_missione,
                  imp.classif_id_programma,
                  imp.classif_code_programma,
                  imp.classif_desc_programma,
                  imp.classif_id_titolo,
                  imp.classif_code_titolo,
                  imp.classif_desc_titolo
       ) tb         
        UNION
            SELECT tb2.anno,
                   tb2.classif_code_missione,
                   tb2.classif_code_programma,
                   tb2.classif_code_titolo,
                   0 AS importo_impegno,
                   tb2.importo_fpv
            FROM (
                   SELECT fpv.anno,
                          fpv.classif_id_missione,
                          fpv.classif_code_missione,
                          fpv.classif_desc_missione,
                          fpv.classif_id_programma,
                          fpv.classif_code_programma,
                          fpv.classif_desc_programma,
                          fpv.classif_id_titolo,
                          fpv.classif_code_titolo,
                          fpv.classif_desc_titolo,
                          sum(fpv.importo_fpv) AS importo_fpv
                   FROM siac_elab_fpv_spesa_fpv fpv
                   WHERE fpv.user_code=v_user and NOT EXISTS (
                                       SELECT 1
                                       FROM siac_elab_fpv_spesa_imp imp
                                       WHERE 
                                       imp.user_code=v_user and
                                       fpv.classif_id_missione =
                                         imp.classif_id_missione AND
                                             fpv.classif_id_programma =
                                               imp.classif_id_programma AND
                                             fpv.classif_id_titolo =
                                               imp.classif_id_titolo AND
                                             fpv.anno::text = imp.anno::text
                         )
                   GROUP BY fpv.anno,
                            fpv.classif_id_missione,
                            fpv.classif_code_missione,
                            fpv.classif_desc_missione,
                            fpv.classif_id_programma,
                            fpv.classif_code_programma,
                            fpv.classif_desc_programma,
                            fpv.classif_id_titolo,
                            fpv.classif_code_titolo,
                            fpv.classif_desc_titolo
                 ) tb2
            ORDER BY 1,
                     2
loop

missione:=rec_output.classif_code_missione;
programma:=rec_output.classif_code_programma;
titolo:=rec_output.classif_code_titolo;
anno_out:=rec_output.anno;
spesa_prevista:=rec_output.importo_impegno;
fpv_spesa:=rec_output.importo_fpv;
    
return next;
end loop;

delete from siac_elab_fpv_spesa_imp where user_code=v_user;

delete from siac_elab_fpv_spesa_fpv where user_code=v_user;

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