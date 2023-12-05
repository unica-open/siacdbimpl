/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_fpv_spesa_capitolo_previsione (
  cronop_id_in integer,
  anno_in varchar
)
RETURNS TABLE (
  elem_id_out integer,
  elem_code_out varchar,
  elem_desc_out varchar,
  missione_out varchar,
  programma_out varchar,
  titolo_out varchar,
  anno_out varchar,
  spesa_prevista_out numeric,
  fpv_spesa_out numeric,
  elem_code2_out varchar,
  elem_desc2_out varchar,
  elem_code3_out varchar
) AS
$body$
DECLARE
max_anno_ciclo integer;
min_anno_ciclo integer;
anno_ciclo integer;
--elem_id_out integer;
--elem_code_out varchar;
--elem_code2_out varchar;
--elem_desc_out varchar;


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

v_user:=fnc_siac_random_user();

min_anno_ciclo:=anno_in::integer;
anno_ciclo:=anno_in::integer;

/*delete from siac_elab_fpv_spesa_imp;

delete from siac_elab_fpv_spesa_fpv;*/

--trovo gli anni su cui ciclare

--trovo max
select max(a.anno::integer) into max_anno_ciclo 
from
siac_t_cronop p, siac_t_cronop_elem mp, siac_t_cronop_elem_det mv, siac_t_periodo a
 where
p.cronop_id=cronop_id_in
and p.cronop_id=mp.cronop_id
and mp.cronop_elem_id=mv.cronop_elem_id
and mv.periodo_id = a.periodo_id
and p.data_cancellazione is null and
mp.data_cancellazione is null and
mv.data_cancellazione is null and
a.data_cancellazione is null
 ;



raise notice 'anno bilancio: % anno ciclo: %', anno_in, anno_ciclo;
raise notice 'max anno ciclo: %', max_anno_ciclo;

for anno_ciclo in min_anno_ciclo .. max_anno_ciclo loop

raise notice 'anno_ciclo_G : %', anno_ciclo;

for rec_impegni in 

select
    c.cronop_id,
    ce.cronop_elem_id,
    pe.anno, 
    ced.cronop_elem_det_importo
  from 
  siac_t_cronop c,
  siac_t_cronop_elem ce,
  siac_t_cronop_elem_det ced,
  siac_d_bil_elem_tipo te,
  siac_t_periodo pe
  where 
  c.cronop_id =cronop_id_in and
  c.cronop_id = ce.cronop_id and
  ce.cronop_elem_id = ced.cronop_elem_id and
  ced.periodo_id = pe.periodo_id and
  ce.elem_tipo_id = te.elem_tipo_id and
  te.elem_tipo_code = 'CAP-UP' and
  pe.anno::INTEGER>= anno_ciclo and
  ced.anno_entrata::INTEGER <= anno_ciclo and
  --ced.anno_entrata::INTEGER < anno_ciclo and
  c.data_cancellazione is null and
  ce.data_cancellazione is null and
  ced.data_cancellazione is null and
  te.data_cancellazione is null and
  pe.data_cancellazione is null 


loop


elem_id_out:=rec_impegni.cronop_id;
movgest_id_out:=rec_impegni.cronop_elem_id;
movgest_anno_out:=rec_impegni.anno;
importo_impegno_out:=rec_impegni.cronop_elem_det_importo;

raise notice 'elem_id_out: %  movgest_id_out: % movgest_anno_out: % importo_impegno_out: %' ,elem_id_out,movgest_id_out,movgest_anno_out,importo_impegno_out;

--cerco classificatori collegati

--PROGRAMMA
select 
cl2.classif_id,cl2.classif_code,cl2.classif_desc,clt2.classif_tipo_code, ft2.classif_id_padre  
into 
   classif_id_programma_out ,  classif_code_programma_out ,  classif_desc_programma_out ,   classif_tipo_code_programma_out,
   classif_id_missione_out
from 
siac_t_class cl2, siac_r_cronop_elem_class rcl2, siac_r_class_fam_tree ft2, siac_t_class_fam_tree cf2, siac_d_class_fam df2,
siac_d_class_tipo clt2
where 
rcl2.cronop_elem_id=movgest_id_out AND
rcl2.classif_id=cl2.classif_id  
and ft2.classif_id=cl2.classif_id
and ft2.classif_fam_tree_id=cf2.classif_fam_tree_id
and df2.classif_fam_id=cf2.classif_fam_id
and df2.classif_fam_desc='Spesa - MissioniProgrammi'
and cl2.classif_tipo_id=clt2.classif_tipo_id
and clt2.classif_tipo_code='PROGRAMMA';

raise notice 'classif_desc_programma_out:%', classif_desc_programma_out;


--trova missione papà del programma

select clpa.classif_code,clpa.classif_desc, clt2.classif_tipo_code 
into classif_code_missione_out ,  classif_desc_missione_out ,   classif_tipo_code_missione_out
from siac_t_class clpa,siac_d_class_tipo clt2
where 
clpa.classif_tipo_id=clt2.classif_tipo_id and
clpa.classif_id=classif_id_missione_out;


raise notice 'classif_desc_missione_out:%', classif_desc_missione_out;


-- TITOLO

select 
cl2.classif_id,cl2.classif_code,cl2.classif_desc,clt2.classif_tipo_code
   --into classif_code_titolo_out ,  classif_desc_titolo_out ,   classif_tipo_code_titolo_out
into classif_id_titolo_out, classif_code_titolo_out ,  classif_desc_titolo_out ,   classif_tipo_code_titolo_out
from 
siac_t_class cl2, siac_r_cronop_elem_class rcl2, 
siac_d_class_tipo clt2
where 
rcl2.cronop_elem_id=movgest_id_out AND
rcl2.classif_id=cl2.classif_id  
and cl2.classif_tipo_id=clt2.classif_tipo_id
and clt2.classif_tipo_code='TITOLO_SPESA';

raise notice 'classif_desc_titolo_out:%', classif_desc_titolo_out;


--anno_out:=anno_ciclo;
--importo_out:=importo_impegno_out;

insert into siac_elab_fpv_spesa_imp
(programma_id,anno_bilancio,anno,elem_id, movgest_id,movgest_anno,importo_impegno,
classif_id_missione,classif_code_missione,classif_desc_missione,classif_tipo_code_missione,classif_id_programma,
classif_code_programma,classif_desc_programma,classif_tipo_code_programma,classif_id_titolo,classif_code_titolo,
classif_desc_titolo,classif_tipo_code_titolo, user_code
)
values (
cronop_id_in , anno_in , anno_ciclo ,elem_id_out, movgest_id_out,movgest_anno_out,
importo_impegno_out,
classif_id_missione_out,classif_code_missione_out,classif_desc_missione_out,classif_tipo_code_missione_out,
classif_id_programma_out,classif_code_programma_out,classif_desc_programma_out,classif_tipo_code_programma_out,
classif_id_titolo_out,classif_code_titolo_out,classif_desc_titolo_out,classif_tipo_code_titolo_out,
v_user
);

raise notice 'insert siac_elab_fpv_spesa_imp % %',rec_impegni.cronop_elem_id, anno_ciclo;

end loop;

anno_ciclo:=anno_ciclo+1;

end loop;

---------altro loop

anno_ciclo:=anno_in::integer;

raise notice 'anno ciclo: %', anno_ciclo;
raise notice 'max anno ciclo: %', max_anno_ciclo;

for anno_ciclo in min_anno_ciclo .. max_anno_ciclo loop
--calcolo FPV


--per ogni capitolo trovo la somma degli importi degli accertamenti (su tab R) 
-- dove anno impegno > anno_ciclo e anno accertamento <= anno_ciclo

raise notice 'cronop_id_in:%', cronop_id_in;
raise notice 'anno_ciclo:%',anno_ciclo;


for rec_fpv in
 select 
    ced.cronop_elem_det_importo,
    c.cronop_id,
    ce.cronop_elem_id
  from 
  siac_t_cronop c,
  siac_t_cronop_elem ce,
  siac_t_cronop_elem_det ced,
  siac_d_bil_elem_tipo te,
  siac_t_periodo pe
  where 
  c.cronop_id =cronop_id_in and
  c.cronop_id = ce.cronop_id and
  ce.cronop_elem_id = ced.cronop_elem_id and
  ced.periodo_id = pe.periodo_id and
  ce.elem_tipo_id = te.elem_tipo_id and
  te.elem_tipo_code = 'CAP-UP' and
  pe.anno::INTEGER> anno_ciclo and
  ced.anno_entrata::INTEGER <= anno_ciclo and
  c.data_cancellazione is null and
  ce.data_cancellazione is null and
  ced.data_cancellazione is null and 
  te.data_cancellazione is null and
  pe.data_cancellazione is null

loop


importo_fpv_out:=rec_fpv.cronop_elem_det_importo;
elem_id_fpv_out:=rec_fpv.cronop_id;
movgest_id_imp_fpv_out:=rec_fpv.cronop_elem_id;



raise notice 'importo_fpv_out:%',importo_fpv_out;
raise notice 'elem_id_fpv_out:%',elem_id_fpv_out;
raise notice 'movgest_id_imp_fpv_out:%',movgest_id_imp_fpv_out;



--cerco classificatori collegati

--PROGRAMMA
select 
cl2.classif_id,cl2.classif_code,cl2.classif_desc,clt2.classif_tipo_code, ft2.classif_id_padre  
into 
classif_id_programma_fpv_out,classif_code_programma_fpv_out,classif_desc_programma_fpv_out,
classif_tipo_code_programma_fpv_out,classif_id_missione_fpv_out
from 
siac_t_class cl2, siac_r_cronop_elem_class rcl2, siac_r_class_fam_tree ft2, siac_t_class_fam_tree cf2, siac_d_class_fam df2,
siac_d_class_tipo clt2
where 
rcl2.cronop_elem_id=movgest_id_imp_fpv_out AND
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


-- TITOLO

select 
cl2.classif_id,cl2.classif_code,cl2.classif_desc,clt2.classif_tipo_code 
   --into classif_code_titolo_fpv_out ,  classif_desc_titolo_fpv_out ,   classif_tipo_code_titolo_fpv_out
into classif_id_titolo_fpv_out, classif_code_titolo_fpv_out ,  classif_desc_titolo_fpv_out ,   classif_tipo_code_titolo_fpv_out
from 
siac_t_class cl2, siac_r_cronop_elem_class rcl2, 
siac_d_class_tipo clt2
where 
rcl2.cronop_elem_id=movgest_id_imp_fpv_out AND
rcl2.classif_id=cl2.classif_id  
and cl2.classif_tipo_id=clt2.classif_tipo_id
and clt2.classif_tipo_code='TITOLO_SPESA';


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
cronop_id_in,anno_in,anno_ciclo,importo_fpv_out,elem_id_fpv_out,
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
         tb.elem_id,
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
                fpv.movgest_id_imp as elem_id,
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
                  fpv.classif_desc_titolo,
                  fpv.movgest_id_imp
       ) tb,
       (
         SELECT  --ANNA imp.anno,
                imp.movgest_anno AS anno,
                imp.classif_id_missione,
                imp.classif_code_missione,
                imp.classif_desc_missione,
                imp.classif_id_programma,
                imp.classif_code_programma,
                imp.classif_desc_programma,
                imp.classif_id_titolo,
                imp.classif_code_titolo,
                imp.classif_desc_titolo,
                imp.movgest_id as elem_id,
                sum(imp.importo_impegno) AS importo_impegno,
                sum(0) AS importo_fpv
         FROM siac_elab_fpv_spesa_imp imp
         where imp.user_code=v_user
         GROUP BY --ANNA imp.anno,
                  imp.movgest_anno,
                  imp.classif_id_missione,
                  imp.classif_code_missione,
                  imp.classif_desc_missione,
                  imp.classif_id_programma,
                  imp.classif_code_programma,
                  imp.classif_desc_programma,
                  imp.classif_id_titolo,
                  imp.classif_code_titolo,
                  imp.classif_desc_titolo,
                  imp.movgest_id
       ) tb2
  WHERE tb.classif_id_missione = tb2.classif_id_missione AND
        tb.classif_id_programma = tb2.classif_id_programma AND
        tb.classif_id_titolo = tb2.classif_id_titolo AND
        tb.anno::text = tb2.anno::text
        and tb.elem_id=tb2.elem_id
  UNION
  SELECT tb.anno,
         tb.classif_code_missione,
         tb.classif_code_programma,
         tb.classif_code_titolo,
         tb.elem_id ,
         tb.importo_impegno,
         0 AS importo_fpv
  FROM (
         SELECT --ANNA imp.anno AS anno,
                imp.movgest_anno AS anno,
                imp.classif_id_missione,
                imp.classif_code_missione,
                imp.classif_desc_missione,
                imp.classif_id_programma,
                imp.classif_code_programma,
                imp.classif_desc_programma,
                imp.classif_id_titolo,
                imp.classif_code_titolo,
                imp.classif_desc_titolo,
                imp.movgest_id as elem_id,
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
                                   fpv.classif_id_titolo = imp.classif_id_titolo AND
                                   -- ANNA fpv.anno::text = imp.anno::text and
                                   fpv.anno::text = imp.movgest_anno::text and
                                   fpv.movgest_id_imp = imp.movgest_id
               )
         GROUP BY --ANNA imp.anno,
         			imp.movgest_anno,
                  imp.classif_id_missione,
                  imp.classif_code_missione,
                  imp.classif_desc_missione,
                  imp.classif_id_programma,
                  imp.classif_code_programma,
                  imp.classif_desc_programma,
                  imp.classif_id_titolo,
                  imp.classif_code_titolo,
                  imp.classif_desc_titolo,
                  imp.movgest_id
       ) tb         
        UNION
            SELECT tb2.anno,
                   tb2.classif_code_missione,
                   tb2.classif_code_programma,
                   tb2.classif_code_titolo,
                   tb2.elem_id,
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
                          fpv.movgest_id_imp as elem_id,
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
                                             --fpv.anno::text = imp.anno::text AND
                                             fpv.anno::text = imp.movgest_anno::text AND
                                             fpv.movgest_id_imp = imp.movgest_id
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
                            fpv.classif_desc_titolo,
                            fpv.movgest_id_imp
                 ) tb2
            ORDER BY 1,
                     2
loop

missione_out:=rec_output.classif_code_missione;
programma_out:=rec_output.classif_code_programma;
titolo_out:=rec_output.classif_code_titolo;
anno_out:=rec_output.anno;
spesa_prevista_out:=rec_output.importo_impegno;
fpv_spesa_out:=rec_output.importo_fpv;
elem_id_out:=rec_output.elem_id;
    
select cronop_elem_code, cronop_elem_desc, cronop_elem_code2,
	 cronop_elem_desc2, cronop_elem_code3
into elem_code_out, elem_desc_out, elem_code2_out, elem_desc2_out,
	elem_code3_out
from siac_t_cronop_elem where cronop_elem_id=elem_id_out;



return next;
end loop;

delete from siac_elab_fpv_spesa_imp where user_code=v_user;

delete from siac_elab_fpv_spesa_fpv where user_code=v_user;

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