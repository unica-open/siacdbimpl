/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-5137 - INIZIO - Alessandro M

CREATE OR REPLACE FUNCTION siac.fnc_siac_fpv_spesa_previsione (
  cronop_id_in integer,
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
  -- SIAC-5212: per l'impegno prendo solo l'anno in corso
  pe.anno::INTEGER = anno_ciclo and
  -- SIAC-5212 - FINE
  --pe.anno::INTEGER>= anno_ciclo and
  --ced.anno_entrata::INTEGER <= anno_ciclo and
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

--raise notice 'elem_id_out: %  movgest_id_out: % movgest_anno_out: % importo_impegno_out: %' ,elem_id_out,movgest_id_out,movgest_anno_out,importo_impegno_out;

--cerco classificatori collegati

--PROGRAMMA
select distinct
cl2.classif_id,cl2.classif_code,cl2.classif_desc,clt2.classif_tipo_code, ft2.classif_id_padre  
into 
   classif_id_programma_out ,  classif_code_programma_out ,  classif_desc_programma_out ,   classif_tipo_code_programma_out,
   classif_id_missione_out
from 
siac_t_class cl2, siac_r_cronop_elem_class rcl2, 
siac_r_class_fam_tree ft2, siac_t_class_fam_tree cf2, siac_d_class_fam df2,
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

--raise notice 'classif_desc_programma_out:%', classif_desc_programma_out;


--trova missione papa' del programma

select clpa.classif_code,clpa.classif_desc, clt2.classif_tipo_code 
into classif_code_missione_out ,  classif_desc_missione_out ,   classif_tipo_code_missione_out
from siac_t_class clpa,siac_d_class_tipo clt2
where 
clpa.classif_tipo_id=clt2.classif_tipo_id and
clpa.classif_id=classif_id_missione_out;


--raise notice 'classif_desc_missione_out:%', classif_desc_missione_out;


-- TITOLO

select distinct
cl2.classif_id,cl2.classif_code,cl2.classif_desc,clt2.classif_tipo_code
--cl2.classif_code,cl2.classif_desc,clt2.classif_tipo_code
   into classif_id_titolo_out, classif_code_titolo_out ,  classif_desc_titolo_out ,   classif_tipo_code_titolo_out
from 
siac_t_class cl2, siac_r_cronop_elem_class rcl2, 
siac_d_class_tipo clt2
where 
rcl2.cronop_elem_id=movgest_id_out AND
rcl2.classif_id=cl2.classif_id  
and cl2.classif_tipo_id=clt2.classif_tipo_id
and clt2.classif_tipo_code='TITOLO_SPESA';

--raise notice 'classif_desc_titolo_out:%', classif_desc_titolo_out;


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

raise notice 'anno_ciclo_G_FPV : %', anno_ciclo;

--raise notice 'cronop_id_in:%', cronop_id_in;



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



/*raise notice 'importo_fpv_out:%',importo_fpv_out;
raise notice 'elem_id_fpv_out:%',elem_id_fpv_out;
raise notice 'movgest_id_imp_fpv_out:%',movgest_id_imp_fpv_out;
*/


--cerco classificatori collegati

--PROGRAMMA
select distinct
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

--trova missione papa' del programma

select clpa.classif_code,clpa.classif_desc, clt2.classif_tipo_code 
into classif_code_missione_fpv_out ,  classif_desc_missione_fpv_out ,   classif_tipo_code_missione_fpv_out
from siac_t_class clpa,siac_d_class_tipo clt2
where 
clpa.classif_tipo_id=clt2.classif_tipo_id and
clpa.classif_id=classif_id_missione_fpv_out;


-- TITOLO

select distinct
cl2.classif_id,cl2.classif_code,cl2.classif_desc,clt2.classif_tipo_code 
--cl2.classif_code,cl2.classif_desc,clt2.classif_tipo_code 
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

raise notice 'insert siac_elab_fpv_spesa_fpv % %',rec_fpv.cronop_elem_id, anno_ciclo;

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
         SELECT 
                imp.anno,
                -- di ANNA imp.movgest_anno AS anno,
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
         GROUP BY  imp.anno,
                  -- di ANNA imp.movgest_anno,
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
         SELECT  imp.anno AS anno,
                -- di ANNAimp.movgest_anno AS anno,
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
                                 -- di ANNA  fpv.anno::text = imp.movgest_anno::text
               )
         GROUP BY  imp.anno,
                  -- di ANNA imp.movgest_anno,
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
                                             -- di ANNA fpv.anno::text = imp.movgest_anno::text
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

/*delete from siac_elab_fpv_spesa_imp where user_code=v_user;

delete from siac_elab_fpv_spesa_fpv where user_code=v_user;
*/
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

-- SIAC-5137 - FINE - Alessandro M


-- SIAC-5198 - INIZIO - Sofia
CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno (
  id_in integer,
  anno_in varchar,
  verifica_mod_prov boolean = true
)
RETURNS TABLE (
  annocompetenza varchar,
  dicuiimpegnato numeric
) AS
$body$
DECLARE

-- constant
TIPO_CAP_UG constant varchar:='CAP-UG';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';

TIPO_IMP    constant varchar:='I';
TIPO_IMP_T  constant varchar:='T';

STATO_DEF   constant varchar:='D';
STATO_N     constant varchar:='N';
STATO_P     constant varchar:='P';
STATO_A     constant varchar:='A';
IMPORTO_ATT constant varchar:='A';

STATO_MOD_V  constant varchar:='V';
STATO_ATTO_P constant varchar:='PROVVISORIO';

strMessaggio varchar(1500):=NVL_STR;


bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;

movGestTipoId integer:=0;
movGestTsTipoId integer:=0;
movGestStatoId integer:=0;
movGestTsDetTipoId integer:=0;

movGestTsId integer:=0;

importoAttuale numeric:=0;
importoCurAttuale numeric:=0;
importoModifNeg  numeric:=0;

modStatoVId integer:=0;
attoAmmStatoPId integer:=0;


movGestIdRec record;

esisteRmovgestidelemid INTEGER:=0;

BEGIN

select el.elem_id into esisteRmovgestidelemid from siac_r_movgest_bil_elem el, siac_t_movgest mv
where
mv.movgest_id=el.movgest_id
and el.elem_id=id_in
and mv.movgest_anno=anno_in::integer
;

 -- 02.02.2016 Sofia JIRA 2947
if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;

if esisteRmovgestidelemid <>0 then


 annoCompetenza:=null;
 diCuiImpegnato:=0;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.Controllo parametri.';

 if anno_in is null or anno_in=NVL_STR then
	 RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
	 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
 end if;


 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
			   ||'.Calcolo bilancioId enteProprietarioId  annoBilancio.';

 select bil.bil_id,  bil.ente_proprietario_id,  per.anno
        into strict bilancioId, enteProprietarioId, annoBilancio
 from siac_t_bil bil,siac_t_bil_elem bilElem, siac_t_periodo per
 where bilElem.elem_id=id_in
 and   bilElem.data_cancellazione is null
 and   bil.bil_id=bilElem.bil_id
 and   per.periodo_id=bil.periodo_id;





 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTipoId.';
 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
 from  siac_d_movgest_tipo tipoMovGest
 where tipoMovGest.ente_proprietario_id=enteProprietarioId
 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsTipoId.';
/* select movGestTsTipo.movgest_ts_tipo_id into strict movGestTsTipoId
 from siac_d_movgest_ts_tipo movGestTsTipo
 where movGestTsTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsTipo.movgest_ts_tipo_code=TIPO_IMP_T;
*/
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsStatoId.';

 select movGestStato.movgest_stato_id into strict movGestStatoId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_A;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsDetTipoId.';

 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

 -- 16.03.2017 Sofia JIRA-SIAC-4614
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo modStatoVId.';
 select d.mod_stato_id into strict modStatoVId
 from siac_d_modifica_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.mod_stato_code=STATO_MOD_V;


 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo attoAmmStatoPId.';
 select d.attoamm_stato_id into strict attoAmmStatoPId
 from siac_d_atto_amm_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.attoamm_stato_code=STATO_ATTO_P;
 -- 16.03.2017 Sofia JIRA-SIAC-4614


 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Inizio calcolo totale importo attuale impegni per anno_in='||anno_in||'.';


 --nuovo G
   	importoCurAttuale:=0;

    select tb.importo into importoCurAttuale
 from (
  select
      coalesce(sum(e.movgest_ts_det_importo),0)  importo
      , c.movgest_ts_tipo_id
    from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id=a.movgest_id and
      a.elem_id=id_in
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
      and c.movgest_id=b.movgest_id
      and d.movgest_ts_id=c.movgest_ts_id
      and d.validita_fine is null
      and e.movgest_ts_id=c.movgest_ts_id
	and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
     and e.data_cancellazione is null
     and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
    and e.movgest_ts_det_tipo_id=movGestTsDetTipoId
    group by
   c.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;


/*select tb.importo into importoCurAttuale from (
  select
      coalesce(sum(e.movgest_ts_det_importo),0)  importo
      , c.movgest_ts_tipo_id
      from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id= ANY (VALUES (a.movgest_id)) and
      a.elem_id=id_in
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
      and c.movgest_id=b.movgest_id
      and d.movgest_ts_id=c.movgest_ts_id
      and d.validita_fine is null
      and e.movgest_ts_id=c.movgest_ts_id
	and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
     and e.data_cancellazione is null
     and f.movgest_ts_det_tipo_id=ANY (VALUES (e.movgest_ts_det_tipo_id))
    and e.movgest_ts_det_tipo_id=ANY (VALUES (movGestTsDetTipoId))
    group by c.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    and t.movgest_ts_tipo_code=TIPO_IMP_T;--'T'; */


 /* select
      coalesce(sum(e.movgest_ts_det_importo),0) into importoCurAttuale
      from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id= ANY (VALUES (a.movgest_id)) and
      a.elem_id=id_in
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
      and c.movgest_id=b.movgest_id
      and d.movgest_ts_id=c.movgest_ts_id
      and e.movgest_ts_id=c.movgest_ts_id
	and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
     and e.data_cancellazione is null
     and f.movgest_ts_det_tipo_id=ANY (VALUES (e.movgest_ts_det_tipo_id))
    and e.movgest_ts_det_tipo_id=ANY (VALUES (movGestTsDetTipoId));*/

  --raise notice 'importoCurAttuale:%', importoCurAttuale;
 --fine nuovo G
 /*for movGestIdRec in
 (
     select movGestRel.movgest_id
     from siac_r_movgest_bil_elem movGestRel
     where movGestRel.elem_id=id_in
     and   movGestRel.data_cancellazione is null
     and   exists (select 1 from siac_t_movgest movGest
   				   where movGest.movgest_id=movGestRel.movgest_id
			       and	 movGest.bil_id = bilancioId
			       and   movGest.movgest_tipo_id=movGestTipoId
				   and   movGest.movgest_anno = anno_in::integer)
 )
 loop
   	importoCurAttuale:=0;

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
                      ||'.Calcolo impegnato anno_in='||anno_in
                      ||'.Lettura siac_t_movgest_ts movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';

    select movgestts.movgest_ts_id into  movGestTsId
    from siac_t_movgest_ts movGestTs
    where movGestTs.movgest_id = movGestIdRec.movgest_id
    and   movGestTs.data_cancellazione is null
    and   movGestTs.movgest_ts_tipo_id=movGestTsTipoId
    and   exists (select 1 from siac_r_movgest_ts_stato movGestTsRel
                  where movGestTsRel.movgest_ts_id=movGestTs.movgest_ts_id
                  and   movGestTsRel.movgest_stato_id!=movGestStatoId);

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
                      ||'.Calcolo accertato anno_in='||anno_in||'Somma siac_t_movgest_ts_det movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';
    if NOT FOUND then
    else
       select coalesce(sum(movGestTsDet.movgest_ts_det_importo),0) into importoCurAttuale
           from siac_t_movgest_ts_det movGestTsDet
           where movGestTsDet.movgest_ts_id=movGestTsId
           and   movGestTsDet.movgest_ts_det_tipo_id=movGestTsDetTipoId;
    end if;

    importoAttuale:=importoAttuale+importoCurAttuale;
 end loop;*/
 -- 02.02.2016 Sofia JIRA 2947
 if importoCurAttuale is null then importoCurAttuale:=0; end if;

 -- 16.03.2017 Sofia JIRA-SIAC-4614
-- if importoCurAttuale>0 then
 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

  strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Calcolo totale modifiche negative su atti provvisori per anno_in='||anno_in||'.';

 select tb.importo into importoModifNeg
 from
 (
 	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
    	 siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
	     siac_t_movgest_ts_det_mod moddet,
    	 siac_t_modifica mod, siac_r_modifica_stato rmodstato,
	     siac_r_atto_amm_stato attostato, siac_t_atto_amm atto
	where rbil.elem_id=id_in
	and	  mov.movgest_id=rbil.movgest_id
	and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
    and   mov.movgest_anno=anno_in::integer
    and   mov.bil_id=bilancioId
	and   ts.movgest_id=mov.movgest_id
	and   rstato.movgest_ts_id=ts.movgest_ts_id
	and   rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
	and   tsdet.movgest_ts_id=ts.movgest_ts_id
	and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	and   moddet.movgest_ts_det_importo<0 -- importo negativo
	and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
	and   mod.mod_id=rmodstato.mod_id
	and   atto.attoamm_id=mod.attoamm_id
	and   attostato.attoamm_id=atto.attoamm_id
	and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
	-- date
	and rbil.data_cancellazione is null
	and rbil.validita_fine is null
	and mov.data_cancellazione is null
	and mov.validita_fine is null
	and ts.data_cancellazione is null
	and ts.validita_fine is null
	and rstato.data_cancellazione is null
	and rstato.validita_fine is null
	and tsdet.data_cancellazione is null
	and tsdet.validita_fine is null
	and moddet.data_cancellazione is null
	and moddet.validita_fine is null
	and mod.data_cancellazione is null
	and mod.validita_fine is null
	and rmodstato.data_cancellazione is null
	and rmodstato.validita_fine is null
	and attostato.data_cancellazione is null
	and attostato.validita_fine is null
	and atto.data_cancellazione is null
	and atto.validita_fine is null
    group by ts.movgest_ts_tipo_id
  ) tb, siac_d_movgest_ts_tipo tipo
  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
  order by tipo.movgest_ts_tipo_code desc
  limit 1;
  -- 21.06.2017 Sofia - aggiunto parametro verifica_mod_prov, ripreso da prod CmTo dove era stato implementato
  if importoModifNeg is null or verifica_mod_prov is false then importoModifNeg:=0; end if;

 end if;

 --nuovo G
 importoAttuale:=importoAttuale+importoCurAttuale+abs(importoModifNeg); -- 16.03.2017 Sofia JIRA-SIAC-4614
 --fine nuovoG

 annoCompetenza:=anno_in;
 diCuiImpegnato:=importoAttuale;

 return next;

else

annoCompetenza:=anno_in;
diCuiImpegnato:=0;

return next;

end if;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
	when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
-- SIAC-5198 - FINE - Sofia

-- SIAC-5190 - INIZIO - Maurizio

CREATE OR REPLACE FUNCTION siac.fnc_bilr104_tab_reversali (
  p_ente_prop_id integer,
  p_tipo_ritenuta varchar
)
RETURNS TABLE (
  ord_id integer,
  conta_reversali integer,
  codice_risc varchar,
  onere_code varchar,
  onere_tipo_code varchar,
  importo_imponibile numeric,
  importo_ente numeric,
  importo_imposta numeric,
  importo_ritenuta numeric,
  importo_reversale numeric,
  importo_ord numeric,
  attivita_inizio date,
  attivita_fine date,
  attivita_code varchar,
  attivita_desc varchar,
  code_caus_770 varchar,
  desc_caus_770 varchar,
  code_caus_esenz varchar,
  desc_caus_esenz varchar
) AS
$body$
DECLARE
RTN_MESSAGGIO varchar;
elencoReversali record;
ciclo integer;

/*
Funzione utilizzata dal report BILR104 per estrarre le ritenute ed i relativi importi
per ogni ordinativo.
*/

BEGIN

ord_id:=null;
conta_reversali:=0;
importo_reversale:=0;
codice_risc:='';
onere_code:='';
onere_tipo_code:='';
importo_imponibile:=0;
importo_imposta:=0;
importo_ritenuta:=0;
importo_ente:=0;
importo_ord:=0;
attivita_inizio:=NULL;
attivita_fine:=NULL;
attivita_code:='';
attivita_desc:='';
code_caus_770:='';
desc_caus_770:='';
code_caus_esenz:='';
desc_caus_esenz:='';

 for elencoReversali in     
        select t_ordinativo.ord_numero, t_ordinativo.ord_emissione_data,
                t_ordinativo.ord_id,d_relaz_tipo.relaz_tipo_code,
                t_ord_ts_det.ord_ts_det_importo importo_ord, r_ordinativo.ord_id_da,
                r_doc_onere.importo_carico_ente, r_doc_onere.importo_imponibile,
                d_onere_tipo.onere_tipo_code, d_onere.onere_code,
                COALESCE(d_dom_non_sogg_tipo.somma_non_soggetta_tipo_code,'') somma_non_soggetta_tipo_code,
                COALESCE(d_dom_non_sogg_tipo.somma_non_soggetta_tipo_desc,'') somma_non_soggetta_tipo_desc,
                caus_770.caus_code_770,
                caus_770.caus_desc_770,r_doc_onere.doc_onere_id,
                r_doc_onere.attivita_inizio,
                r_doc_onere.attivita_fine,
                d_onere_attivita.onere_att_code,
                d_onere_attivita.onere_att_desc
          from  siac_r_ordinativo r_ordinativo, siac_t_ordinativo t_ordinativo,
                siac_d_ordinativo_tipo d_ordinativo_tipo,
                siac_d_relaz_tipo d_relaz_tipo, siac_t_ordinativo_ts t_ord_ts,
                siac_t_ordinativo_ts_det t_ord_ts_det, siac_d_ordinativo_ts_det_tipo ts_det_tipo,
                siac_r_doc_onere_ordinativo_ts r_doc_onere_ord_ts,
                siac_r_doc_onere r_doc_onere
                LEFT JOIN siac_d_somma_non_soggetta_tipo d_dom_non_sogg_tipo
                    	ON (d_dom_non_sogg_tipo.somma_non_soggetta_tipo_id=
                        	  r_doc_onere.somma_non_soggetta_tipo_id
                            AND d_dom_non_sogg_tipo.data_cancellazione IS NULL)
                LEFT JOIN siac_d_onere_attivita d_onere_attivita	
                		ON (d_onere_attivita.onere_att_id=
                        	  r_doc_onere.onere_att_id
                            AND d_onere_attivita.data_cancellazione IS NULL)
                /* 01/06/2017: aggiunta gestione delle causali 770 */                    
               LEFT JOIN (SELECT distinct r_onere_caus.onere_id,
               				r_doc_onere.doc_id,t_subdoc.subdoc_id,
               				COALESCE(d_causale.caus_code,'') caus_code_770,
                            COALESCE(d_causale.caus_desc,'') caus_desc_770
               			FROM siac_r_doc_onere r_doc_onere,
                        	siac_t_subdoc t_subdoc,
                        	siac_r_onere_causale r_onere_caus,
							siac_d_causale d_causale ,
							siac_d_modello d_modello                                                       
                    WHERE   t_subdoc.doc_id=r_doc_onere.doc_id                    	
                    	AND r_doc_onere.onere_id=r_onere_caus.onere_id
                        AND d_causale.caus_id=r_doc_onere.caus_id
                    	AND d_causale.caus_id=r_onere_caus.caus_id   
                    	AND d_modello.model_id=d_causale.model_id                                                      
                        AND d_modello.model_code='01' --Causale 770
                        AND r_doc_onere.ente_proprietario_id =p_ente_prop_id                      AND r_doc_onere.onere_id=5
                        AND r_onere_caus.validita_fine IS NULL                        
                        AND r_doc_onere.data_cancellazione IS NULL 
                        AND d_modello.data_cancellazione IS NULL 
                        AND d_causale.data_cancellazione IS NULL
                        AND t_subdoc.data_cancellazione IS NULL) caus_770
                    ON (caus_770.onere_id=r_doc_onere.onere_id
                    	AND caus_770.doc_id=r_doc_onere.doc_id),
                        --AND caus_770.subdoc_id=irpef.subdoc_id),
                siac_d_onere d_onere,
                siac_d_onere_tipo  d_onere_tipo
                where t_ordinativo.ord_id=r_ordinativo.ord_id_a
                    AND d_ordinativo_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id
                    AND d_relaz_tipo.relaz_tipo_id=r_ordinativo.relaz_tipo_id
                    AND t_ord_ts.ord_id=t_ordinativo.ord_id
                    AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
                    AND ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
                    AND r_doc_onere_ord_ts.ord_ts_id=t_ord_ts_det.ord_ts_id
                    AND r_doc_onere.doc_onere_id=r_doc_onere_ord_ts.doc_onere_id
                    AND d_onere.onere_id=r_doc_onere.onere_id
                      AND d_onere_tipo.onere_tipo_id=d_onere.onere_tipo_id
                     AND d_ordinativo_tipo.ord_tipo_code ='I'
                     AND ts_det_tipo.ord_ts_det_tipo_code='A'
                        /* cerco tutte le tipologie di relazione,
                            non solo RIT_ORD */
               -- AND d_relaz_tipo.relaz_tipo_code='RIT_ORD'
                  /* ord_id_da contiene l'ID del mandato
                     ord_id_a contiene l'ID della reversale */
                --AND r_ordinativo.ord_id_da = elencoMandati.ord_id
                AND d_onere_tipo.onere_tipo_code=p_tipo_ritenuta 
                AND d_relaz_tipo.data_cancellazione IS NULL
                AND t_ordinativo.data_cancellazione IS NULL
                AND r_ordinativo.data_cancellazione IS NULL
                AND r_ordinativo.data_cancellazione IS NULL
                AND t_ord_ts.data_cancellazione IS NULL
                AND t_ord_ts_det.data_cancellazione IS NULL
                AND ts_det_tipo.data_cancellazione IS NULL
                AND r_doc_onere_ord_ts.data_cancellazione IS NULL
                AND r_doc_onere.data_cancellazione IS NULL
                AND d_onere.data_cancellazione IS NULL
                AND d_onere_tipo.data_cancellazione IS NULL
          ORDER BY r_ordinativo.ord_id_da
                        
      loop
--raise notice 'Tipo rev=%, Importo rev=%, Imponibile=%' , elencoReversali.onere_tipo_code, elencoReversali.importo_ord, elencoReversali.importo_imponibile;          
             if ord_id is not null and 
            	ord_id <> elencoReversali.ord_id_da  THEN
                  return next;
                  conta_reversali:=0;
                  importo_reversale:=0;
                  codice_risc:='';
                  onere_code:='';
                  onere_tipo_code:='';
                  importo_imponibile:=0;
                  importo_imposta:=0;
                  importo_ritenuta:=0;
                  importo_ente:=0;
                  importo_ord:=0;
                  attivita_inizio:=NULL;
                  attivita_fine:=NULL;
                  attivita_code:='';
                  attivita_desc:='';
                  code_caus_770:='';
            	  desc_caus_770:='';
        		  code_caus_esenz:='';
        		  desc_caus_esenz:='';
                end if;
                
            ord_id:=elencoReversali.ord_id_da;
          
           --raise notice 'ord_id_da = % - r_doc_onere_id = % - carico_ente = % - importo_imponibile = % - importo_ord = %',
          -- elencoReversali.ord_id_da, elencoReversali.doc_onere_id,
          -- elencoReversali.importo_carico_ente, elencoReversali.importo_imponibile, elencoReversali.importo_ord;
            conta_reversali=conta_reversali+1;
            importo_reversale=importo_reversale+elencoReversali.importo_ord;
                          
            onere_code=COALESCE(elencoReversali.onere_code,'');
            onere_tipo_code=upper(elencoReversali.onere_tipo_code);           
            importo_imponibile = importo_imponibile+elencoReversali.importo_imponibile;
            importo_ente=importo_ente+elencoReversali.importo_carico_ente;                    
            importo_ritenuta = importo_ritenuta+elencoReversali.importo_ord;  
            importo_ord:=importo_ord+elencoReversali.importo_ord;
            attivita_inizio:=elencoReversali.attivita_inizio;
            attivita_fine:=elencoReversali.attivita_fine;
            attivita_code:=elencoReversali.onere_att_code;
            attivita_desc:=elencoReversali.onere_att_desc;
            
            code_caus_770:=COALESCE(elencoReversali.caus_code_770,'');
            desc_caus_770:=COALESCE(elencoReversali.caus_desc_770,'');
        	code_caus_esenz:=COALESCE(elencoReversali.somma_non_soggetta_tipo_code,'');
        	desc_caus_esenz:=COALESCE(elencoReversali.somma_non_soggetta_tipo_desc,'');
            
             /* anche split/reverse è una reversale, quindi qualunque tipo
                tipo di relazione concateno i risultati ottenuti 
                (possono essere più di 1) */              
              if codice_risc = '' THEN
                  codice_risc = elencoReversali.ord_numero ::VARCHAR;
              else
                  codice_risc = codice_risc||', '||elencoReversali.ord_numero ::VARCHAR;
              end if;

          end loop; 
        
        return next;



exception
    when no_data_found THEN
        raise notice 'nessun mandato trovato' ;
        return;
    when others  THEN
         RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;


CREATE OR REPLACE FUNCTION siac."BILR104_stampa_ritenute" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_mandato_da date,
  p_data_mandato_a date,
  p_data_trasm_da date,
  p_data_trasm_a date,
  p_tipo_ritenuta varchar,
  p_data_quietanza_da date,
  p_data_quietanza_a date
)
RETURNS TABLE (
  nome_ente varchar,
  partita_iva_ente varchar,
  anno_ese_finanz integer,
  anno_mandato integer,
  numero_mandato integer,
  data_mandato date,
  desc_mandato varchar,
  benef_codice varchar,
  benef_cod_fiscale varchar,
  benef_partita_iva varchar,
  benef_nome varchar,
  stato_mandato varchar,
  importo_lordo_mandato numeric,
  tipo_ritenuta_irpef varchar,
  codice_tributo_irpef varchar,
  importo_ritenuta_irpef numeric,
  importo_netto_irpef numeric,
  importo_imponibile_irpef numeric,
  codice_risc varchar,
  tipo_ritenuta_inps varchar,
  codice_tributo_inps varchar,
  importo_ritenuta_inps numeric,
  importo_netto_inps numeric,
  importo_imponibile_inps numeric,
  importo_ente_inps numeric,
  tipo_ritenuta_irap varchar,
  importo_ritenuta_irap numeric,
  importo_netto_irap numeric,
  importo_imponibile_irap numeric,
  codice_ritenuta_irap varchar,
  desc_ritenuta_irap varchar,
  importo_ente_irap numeric,
  display_error varchar,
  tipo_ritenuta_irpeg varchar,
  codice_tributo_irpeg varchar,
  importo_ritenuta_irpeg numeric,
  importo_netto_irpeg numeric,
  importo_imponibile_irpeg numeric,
  codice_ritenuta_irpeg varchar,
  desc_ritenuta_irpeg varchar,
  importo_ente_irpeg numeric,
  code_caus_770 varchar,
  desc_caus_770 varchar,
  code_caus_esenz varchar,
  desc_caus_esenz varchar,
  attivita_inizio date,
  attivita_fine date,
  attivita_code varchar,
  attivita_desc varchar
) AS
$body$
DECLARE
elencoMandati record;
elencoOneri	record;
elencoReversali record;


DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
importoSubDoc NUMERIC;
imponibileInpsApp NUMERIC;
impostaInpsApp	NUMERIC;
enteInpsApp NUMERIC;
imponibileIrpefApp NUMERIC;
impostaIrpefApp	NUMERIC;
imponibileIrapApp NUMERIC;
impostaIrapApp	NUMERIC;
contaQuotaIrap integer;
importoParzIrapImpon NUMERIC;
importoParzIrapNetto NUMERIC;
importoParzIrapRiten NUMERIC;
importoParzIrapEnte NUMERIC;

contaQuotaIrpef integer;
importoParzIrpefImpon NUMERIC;
importoParzIrpefNetto NUMERIC;
importoParzIrpefRiten NUMERIC;
importoParzIrpefEnte NUMERIC;
importoTotDaDedurreFattura NUMERIC;

percQuota NUMERIC;
idFatturaOld INTEGER;
numeroQuoteFattura INTEGER;
numeroParametriData Integer;
docIdApp integer;

ente_denominazione VARCHAR;
cod_fisc_ente VARCHAR;
bilancio_id  INTEGER;
miaQuery VARCHAR;

BEGIN

nome_ente='';
partita_iva_ente='';
anno_ese_finanz=0;
anno_mandato=0;
numero_mandato=0;
data_mandato=NULL;
desc_mandato='';
benef_cod_fiscale='';
benef_partita_iva='';
benef_nome='';
stato_mandato='';

codice_risc='';
importo_lordo_mandato=0;
importo_netto_irpef=0;
importo_imponibile_irpef=0;
importo_ritenuta_irpef=0;
importo_netto_inps=0;
importo_imponibile_inps=0;
importo_ritenuta_inps=0;
importo_netto_irap=0;
importo_imponibile_irap=0;
importo_ritenuta_irap=0;

tipo_ritenuta_inps='';
tipo_ritenuta_irpef='';
tipo_ritenuta_irap='';

codice_tributo_irpef='';
codice_tributo_inps='';

codice_ritenuta_irap='';
desc_ritenuta_irap='';
benef_codice='';
importo_ente_irap=0;
importo_ente_inps=0;
code_caus_770:='';
desc_caus_770:='';
code_caus_esenz:='';
desc_caus_esenz:='';
attivita_inizio:=NULL;
attivita_fine:=NULL;
attivita_code:='';
attivita_desc:='';

tipo_ritenuta_irpeg='';
codice_tributo_irpeg='';
importo_ritenuta_irpeg=0;
importo_netto_irpeg=0;
importo_imponibile_irpeg=0;
codice_ritenuta_irpeg='';
desc_ritenuta_irpeg='';
importo_ente_irpeg=0;
numeroParametriData=0;


display_error='';
/*
if p_data_trasm_da IS NULL AND p_data_trasm_a IS NULL AND p_data_mandato_da IS NULL AND
	p_data_mandato_a IS NULL AND p_data_quietanza_da IS NULL AND p_data_quietanza_a IS NULL THEN
	display_error='OCCORRE SPECIFICARE UNO TRA GLI INTERVALLI "DATA MANDATO DA/A",  "DATA TRASMISSIONE DA/A" E "DATA QUIETANZA DA/A".';
    return next;
    return;
end if;


if p_data_trasm_da IS NOT NULL AND p_data_trasm_a IS NOT NULL 
	AND p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL THEN
	display_error='OCCORRE SPECIFICARE UNO SOLO DEI TRE INTERVALLI DI DATA "DATA MANDATO DA/A", "DATA TRASMISSIONE DA/A" E "DATA QUIETANZA DA/A".';
    return next;
    return;
end if;*/

if (p_data_trasm_da IS NOT NULL OR p_data_trasm_a IS NOT NULL) THEN
	numeroParametriData=numeroParametriData+1;
end if;
if (p_data_mandato_da IS NOT NULL OR p_data_mandato_a IS NOT NULL) THEN
	numeroParametriData=numeroParametriData+1;
end if;
if (p_data_quietanza_da IS NOT NULL OR p_data_quietanza_a IS NOT NULL) THEN
	numeroParametriData=numeroParametriData+1;
end if;

if numeroParametriData = 0 THEN
	display_error='OCCORRE SPECIFICARE UNO TRA GLI INTERVALLI "DATA MANDATO DA/A",  "DATA TRASMISSIONE DA/A" E "DATA QUIETANZA DA/A".';
    return next;
    return;
end if;

if numeroParametriData>=2 THEN
	display_error='OCCORRE SPECIFICARE UNO SOLO DEI TRE INTERVALLI DI DATA "DATA MANDATO DA/A", "DATA TRASMISSIONE DA/A" E "DATA QUIETANZA DA/A".';
    return next;
    return;
end if;

if (p_data_trasm_da IS NULL AND p_data_trasm_a IS NOT NULL) OR 
	(p_data_trasm_da IS NOT NULL AND p_data_trasm_a IS  NULL) THEN
	display_error='OCCORRE SPECIFICARE ENTRAMBE LE DATE "DATA TRASMISSIONE DA/A".';
    return next;
    return;
end if;

if (p_data_mandato_da IS NULL AND p_data_mandato_a IS NOT NULL) OR 
	(p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS  NULL) THEN
	display_error='OCCORRE SPECIFICARE ENTRAMBE LE DATE "DATA MANDATO DA/A".';
    return next;
    return;
end if;

if (p_data_quietanza_da IS NULL AND p_data_quietanza_a IS NOT NULL) OR 
	(p_data_quietanza_da IS NOT NULL AND p_data_quietanza_a IS  NULL) THEN
	display_error='OCCORRE SPECIFICARE ENTRAMBE LE DATE "DATA QUIETANZA DA/A".';
    return next;
    return;
end if;

RTN_MESSAGGIO:='Estrazione dei dati dei mandati ''.';
raise notice 'Estrazione dei dati dei mandati ';
raise notice 'ora: % ',clock_timestamp()::varchar;

    	/* 11/10/2016: cerco i mandati di tutte le ritenute tranne l'IRAP che 
        	deve essere estratta in modo diverso */
/* 30/05/2017: L'IRPEF deve essere gestita in modo simile all'IRAP in quanto 
	è necessario calcolare il dato della ritenuta proporzionandola con la
    percentuale calcolata delle relativie quote della fattura */
--if p_tipo_ritenuta <> 'IRAP' THEN
if p_tipo_ritenuta in ('INPS','IRPEG') THEN

select a.ente_denominazione, a.codice_fiscale
into  ente_denominazione, cod_fisc_ente
from  siac_t_ente_proprietario a
where a.ente_proprietario_id = p_ente_prop_id;
    
select a.bil_id 
into bilancio_id 
from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id 
and b.periodo_id = a.periodo_id
and b.anno = p_anno;

/* 07/09/2017: rivista la modalità di estrazione dei dati INPS e IRPEG per velocizzare 
    la procedura.
    In particolare è stata creata la function fnc_bilr104_tab_reversali per estrarre
    tutte le reversali per mandato in modo da estrarre tutte le informazioni in un
    colpo solo senza dover cercare le reversali nel ciclo per ogni mandato. 
    Corretto anche un problema relativo ai casi in cui un mandato ha più reversali 
    collegate, fatto in modo di sommare gli importi IMPONIBILE, ENTE e RITENUTA ma
    solo se la reversale collegata ha un onere del tipo richiesto (INPS o IRPEG). */

miaQuery ='
with ordinativo as (
    select t_ordinativo.ord_anno,
           t_ordinativo.ord_desc, 
           t_ordinativo.ord_numero,
           t_ordinativo.ord_emissione_data,        
           t_ord_ts_det.ord_ts_det_importo,
           d_ord_stato.ord_stato_code,
           t_ordinativo.ord_id,
           t_ord_ts_det.ord_ts_id
    from  siac_t_ordinativo t_ordinativo,
          siac_t_ordinativo_ts t_ord_ts,
          siac_t_ordinativo_ts_det t_ord_ts_det,
          siac_d_ordinativo_ts_det_tipo d_ts_det_tipo,
          siac_r_ordinativo_stato r_ord_stato,
          siac_d_ordinativo_stato d_ord_stato,
          siac_d_ordinativo_tipo  d_ord_tipo
    where t_ordinativo.ente_proprietario_id = ' ||p_ente_prop_id||'
    and   t_ordinativo.bil_id =  '||bilancio_id ||'    
    and   d_ts_det_tipo.ord_ts_det_tipo_code = ''A''            
    and   d_ord_stato.ord_stato_code <> ''A''
    and   d_ord_tipo.ord_tipo_code = ''P''
    and   r_ord_stato.validita_fine is null 
    and   t_ordinativo.ord_id = t_ord_ts.ord_id
    and   t_ord_ts.ord_ts_id = t_ord_ts_det.ord_ts_id
    and   t_ord_ts_det.ord_ts_det_tipo_id = d_ts_det_tipo.ord_ts_det_tipo_id
    and   t_ordinativo.ord_id = r_ord_stato.ord_id
    and   r_ord_stato.ord_stato_id = d_ord_stato.ord_stato_id
    and   t_ordinativo.ord_tipo_id = d_ord_tipo.ord_tipo_id ';
	if p_data_mandato_da is not null and p_data_mandato_a is not null THEN
		miaQuery=miaQuery||' and to_timestamp(to_char(t_ordinativo.ord_emissione_data,''dd/MM/yyyy''),''dd/MM/yyyy'') between '''||p_data_mandato_da ||''' and '''||p_data_mandato_a||'''';
	elsif p_data_trasm_da is not null and p_data_trasm_a is not null THEN 
		miaQuery=miaQuery||' and to_timestamp(to_char(t_ordinativo.ord_trasm_oil_data,''dd/MM/yyyy''),''dd/MM/yyyy'') between '''||p_data_trasm_da || ''' and '''||p_data_trasm_a||'''';
	end if;
    
    miaQuery=miaQuery||' 
    and   t_ordinativo.data_cancellazione is null
    and   t_ord_ts.data_cancellazione is null
    and   t_ord_ts_det.data_cancellazione is null
    and   d_ts_det_tipo.data_cancellazione is null
    and   r_ord_stato.data_cancellazione is null
    and   d_ord_stato.data_cancellazione is null
    and   d_ord_tipo.data_cancellazione is null
    )
    , capitolo as (
    select t_bil_elem.elem_code, 
           t_bil_elem.elem_code2,
           r_ordinativo_bil_elem.ord_id,
           t_bil_elem.elem_id       
    from   siac_r_ordinativo_bil_elem r_ordinativo_bil_elem, 
           siac_t_bil_elem t_bil_elem
    where  r_ordinativo_bil_elem.elem_id = t_bil_elem.elem_id
    and    r_ordinativo_bil_elem.ente_proprietario_id = '||p_ente_prop_id||'
    and    r_ordinativo_bil_elem.data_cancellazione is null
    and    t_bil_elem.data_cancellazione is null     
    )
    , movimento as (
    select distinct t_movgest.movgest_anno,
           r_liq_ord.sord_id
    from  siac_r_liquidazione_ord r_liq_ord,
          siac_r_liquidazione_movgest r_liq_movgest,
          siac_t_movgest t_movgest,
          siac_t_movgest_ts t_movgest_ts
    where r_liq_ord.liq_id = r_liq_movgest.liq_id
    and   r_liq_movgest.movgest_ts_id = t_movgest_ts.movgest_ts_id
    and   t_movgest_ts.movgest_id = t_movgest.movgest_id
    and   t_movgest.ente_proprietario_id = '||p_ente_prop_id||'
    and   r_liq_ord.data_cancellazione is null
    and   r_liq_movgest.data_cancellazione is null
    and   t_movgest.data_cancellazione is null
    and   t_movgest_ts.data_cancellazione is null
    )
    , soggetto as (
    select t_soggetto.soggetto_code, 
           t_soggetto.soggetto_desc,  
           t_soggetto.partita_iva,
           t_soggetto.codice_fiscale,
           r_ord_soggetto.ord_id
    from   siac_r_ordinativo_soggetto r_ord_soggetto,
           siac_t_soggetto t_soggetto
    where  r_ord_soggetto.soggetto_id = t_soggetto.soggetto_id
    and    t_soggetto.ente_proprietario_id = '||p_ente_prop_id||'
    and    r_ord_soggetto.data_cancellazione is null  
    and    t_soggetto.data_cancellazione is null
    )
    , reversali as (select * from "fnc_bilr104_tab_reversali"('||p_ente_prop_id||','''||p_tipo_ritenuta||'''))
    select '''||ente_denominazione||''' ente_denominazione, '''||
           cod_fisc_ente||''' cod_fisc_ente, '''||
           p_anno||''' anno_eser,
           ordinativo.ord_anno,
           ordinativo.ord_desc, 
           ordinativo.ord_numero,
           ordinativo.ord_emissione_data,        
           -- ordinativo.ord_ts_det_importo,
           SUM(ordinativo.ord_ts_det_importo) IMPORTO_TOTALE,
           ordinativo.ord_stato_code,
           ordinativo.ord_id,
           capitolo.elem_code cod_cap, 
           capitolo.elem_code2 cod_art,
           capitolo.elem_id,
           movimento.movgest_anno anno_impegno,
           soggetto.soggetto_code, 
           soggetto.soggetto_desc,  
           soggetto.partita_iva,
           soggetto.codice_fiscale,
           reversali.*
    from  ordinativo         
    inner join capitolo  on ordinativo.ord_id = capitolo.ord_id
    inner join movimento on ordinativo.ord_ts_id = movimento.sord_id
    inner join soggetto  on ordinativo.ord_id = soggetto.ord_id
    inner join reversali  on ordinativo.ord_id = reversali.ord_id
    left  join siac_r_ordinativo_quietanza r_ord_quietanza on ordinativo.ord_id = r_ord_quietanza.ord_id 
                                                                and r_ord_quietanza.data_cancellazione is null 
	where reversali.onere_tipo_code='''||p_tipo_ritenuta||'''';
    if p_data_quietanza_da is not null and p_data_quietanza_a is not null THEN
		miaQuery=miaQuery||' 
		and to_timestamp(to_char(r_ord_quietanza.ord_quietanza_data,''dd/MM/yyyy''),''dd/MM/yyyy'') between ''' ||p_data_quietanza_da ||''' and ''' ||p_data_quietanza_a||'''';
    end if;
	miaQuery=miaQuery||' 
    group by ente_denominazione, cod_fisc_ente, anno_eser,
             ordinativo.ord_anno,
             ordinativo.ord_desc, 
             ordinativo.ord_numero,
             ordinativo.ord_emissione_data,
             ordinativo.ord_stato_code,
             ordinativo.ord_id,
             capitolo.elem_code, 
             capitolo.elem_code2,
             capitolo.elem_id,  
             movimento.movgest_anno,
             soggetto.soggetto_code, 
             soggetto.soggetto_desc,  
             soggetto.partita_iva,
             soggetto.codice_fiscale,
             reversali.ord_id,      
             reversali.conta_reversali,  
             reversali.codice_risc,  
             reversali.onere_code,  
             reversali.onere_tipo_code,  
             reversali.importo_imponibile,  
             reversali.importo_ente,  
             reversali.importo_imposta,  
             reversali.importo_ritenuta,  
             --reversali.importo_netto,  
             reversali.importo_reversale,  
             reversali.importo_ord,  
             reversali.attivita_inizio,  
             reversali.attivita_fine,  
             reversali.attivita_code,  
             reversali.attivita_desc,
             reversali.code_caus_770,
			 reversali.desc_caus_770,
			 reversali.code_caus_esenz,
			 reversali.desc_caus_esenz    
    order by ordinativo.ord_numero, ordinativo.ord_emissione_data ';
raise notice 'miaQuery = %', miaQuery;


  for elencoMandati in execute miaQuery    
          
  loop

  importo_lordo_mandato= COALESCE(elencoMandati.IMPORTO_TOTALE,0);


	/* cerco gli oneri: INPS, IRPEF ed IRAP */
    /* 11/03/2016: gli importi degli oneri sono salvati, ma l'importo vero e proprio
    	è assegnato più avanti dopo aver estratto la reversale */
    /* 14/03/2016: gli importi degli oneri sono presi dalle reversali */
/*for elencoOneri IN
        SELECT d_onere_tipo.onere_tipo_code, d_onere.onere_code,
          d_onere.onere_desc,        
          sum(r_doc_onere.importo_imponibile) IMPORTO_IMPONIBILE,
          sum(r_doc_onere.importo_carico_soggetto) IMPOSTA,
          sum(r_doc_onere.importo_carico_ente) IMPORTO_CARICO_ENTE
        from siac_t_ordinativo_ts t_ordinativo_ts,
            siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts,          
            siac_t_doc t_doc, 
            siac_t_subdoc t_subdoc,
            siac_r_doc_onere r_doc_onere,
            siac_d_onere d_onere,
            siac_d_onere_tipo d_onere_tipo
        WHERE r_subdoc_ordinativo_ts.ord_ts_id=t_ordinativo_ts.ord_ts_id
            AND t_doc.doc_id=t_subdoc.doc_id
            and t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id
            AND r_doc_onere.doc_id=t_doc.doc_id
            AND d_onere.onere_id=r_doc_onere.onere_id
            AND d_onere_tipo.onere_tipo_id=d_onere.onere_tipo_id         
            AND t_ordinativo_ts.ord_id=elencoMandati.ord_id
            AND t_doc.data_cancellazione IS NULL
            AND t_subdoc.data_cancellazione IS NULL
            AND r_doc_onere.data_cancellazione IS NULL
            AND d_onere.data_cancellazione IS NULL
            AND d_onere_tipo.data_cancellazione IS NULL
            AND t_ordinativo_ts.data_cancellazione IS NULL
            AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL
            GROUP BY d_onere_tipo.onere_tipo_code,d_onere.onere_code, d_onere.onere_desc
    loop       
          IF upper(elencoOneri.onere_tipo_code) = 'IRPEF' THEN
              tipo_ritenuta_irpef=upper(elencoOneri.onere_tipo_code);                                            
              codice_tributo=elencoOneri.onere_code;
              --importo_imponibile_irpef = elencoOneri.IMPORTO_IMPONIBILE;              
              --importo_ritenuta_irpef = elencoOneri.IMPOSTA;                             
              --importo_netto_irpef=importo_lordo_mandato-importo_ritenuta_irpef;   
              imponibileIrpefApp=elencoOneri.IMPORTO_IMPONIBILE;   
			  impostaIrpefApp= elencoOneri.IMPOSTA;                                     
          ELSIF  upper(elencoOneri.onere_tipo_code) = 'INPS' THEN
              tipo_ritenuta_inps=upper(elencoOneri.onere_tipo_code);
              --importo_imponibile_inps = elencoOneri.IMPORTO_IMPONIBILE;
              --importo_ritenuta_inps = elencoOneri.IMPOSTA;                
              --importo_ente_inps=elencoOneri.IMPORTO_CARICO_ENTE;
              --importo_netto_inps=importo_lordo_mandato-importo_ritenuta_inps; 
              imponibileInpsApp=elencoOneri.IMPORTO_IMPONIBILE;   
			  impostaInpsApp= elencoOneri.IMPOSTA;         
              enteInpsApp=elencoOneri.IMPORTO_CARICO_ENTE;
          ELSIF  upper(elencoOneri.onere_tipo_code) = '3' THEN
              tipo_ritenuta_irap=upper(elencoOneri.onere_tipo_code);
              desc_ritenuta_irap=elencoOneri.onere_desc;
              codice_ritenuta_irap=elencoOneri.onere_code;
              --importo_imponibile_irap = elencoOneri.IMPORTO_IMPONIBILE;
              --importo_ritenuta_irap = elencoOneri.IMPOSTA;                
			  --importo_ente_irap=elencoOneri.IMPORTO_CARICO_ENTE;
              --importo_netto_irap=importo_lordo_mandato-importo_ritenuta_irap; 
              imponibileIrapApp=elencoOneri.IMPORTO_IMPONIBILE;   
			  impostaIrapApp= elencoOneri.IMPOSTA;                                  
          END IF;
    end loop;      */


	/* sono inviati al report solo i mandati che hanno una ritenuta IRPEF o INPS */
--if tipo_ritenuta_irpef <> '' OR  tipo_ritenuta_inps <> '' OR
--	tipo_ritenuta_irap <> '' THEN
    
/* 11/03/2016: cerco il subdoc per ricavarne l'importo */
      --   importoSubDoc=0;
      
 /*     SELECT t_subdoc.doc_id, COALESCE(t_subdoc.subdoc_importo,0)
          INTO docIdApp, importoSubDoc
      FROM siac_t_ordinativo_ts t_ordinativo_ts
          LEFT JOIN  siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts   
              ON  (r_subdoc_ordinativo_ts.ord_ts_id =t_ordinativo_ts.ord_ts_id 
                      AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL) 
          LEFT JOIN  siac_t_subdoc t_subdoc
              ON  (t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id
                  AND t_subdoc.data_cancellazione IS NULL)       
      WHERE  t_ordinativo_ts.ord_id=elencoMandati.ord_id;
      --GROUP BY t_subdoc.doc_id;
          IF NOT FOUND THEN
              importoSubDoc=0;
          END IF;  */
       
  --raise notice 'Num mandato =%, importo subdoc=%',elencoMandati.ord_numero,importoSubDoc;
  --raise notice 'ordinativo id =%', elencoMandati.ord_id;    	
          /* cerco le reversali siac_r_doc_onere_ordinativo_ts */
      /* 14/03/2016: attraverso la tabella siac_r_doc_onere_ordinativo_ts si può 
          recuperare il dato dell'importo della reversale a livello di quota documento.
          Quindi non è più necessario cercare gli oneri */
      /* 07/04/2016: aggiunto d_onere.onere_code che è il codice_tributo */
      
--raise notice 'PRIMA DI ESEGUIRE QUERY REVERSALI, mandato id %',elencoMandati.ord_id;
--raise notice 'ora: % ',clock_timestamp()::varchar;

      codice_risc:=elencoMandati.codice_risc;
      if upper(elencoMandati.onere_tipo_code) = 'INPS' THEN
        codice_tributo_inps=COALESCE(elencoMandati.onere_code,'');
        tipo_ritenuta_inps=upper(elencoMandati.onere_tipo_code);        
        importo_imponibile_inps = elencoMandati.importo_imponibile;
        --raise notice 'ord_id = % - IMPON = %', elencoMandati.ord_id, elencoMandati.importo_imponibile;
        importo_ente_inps=elencoMandati.importo_ente;                   
        importo_ritenuta_inps = elencoMandati.importo_ord;    
        importo_netto_inps=importo_lordo_mandato-elencoMandati.importo_ritenuta;-- elencoMandati.importo_netto;-- importo_lordo_mandato-importo_ritenuta_inps;
        attivita_inizio:=elencoMandati.attivita_inizio;
        attivita_fine:=elencoMandati.attivita_fine;
        attivita_code:=elencoMandati.attivita_code;
        attivita_desc:=elencoMandati.attivita_desc;
      elsif upper(elencoMandati.onere_tipo_code) = 'IRPEG' THEN

        codice_tributo_irpeg=COALESCE(elencoMandati.onere_code,'');
        tipo_ritenuta_irpeg=upper(elencoMandati.onere_tipo_code);    		
        importo_imponibile_irpeg = elencoMandati.importo_imponibile;
        importo_ritenuta_irpeg = elencoMandati.importo_ord;    
                                        
        importo_netto_irpeg=importo_lordo_mandato-elencoMandati.importo_ritenuta;  
        code_caus_770:=COALESCE(elencoMandati.code_caus_770,'');
        desc_caus_770:=COALESCE(elencoMandati.desc_caus_770,'');
        code_caus_esenz:=COALESCE(elencoMandati.code_caus_esenz,'');
        desc_caus_esenz:=COALESCE(elencoMandati.desc_caus_esenz,'');
      end if; 
      
        /* 07/092017: restituisco solo i dati relativi alla ritenuta richiesta */
       if (p_tipo_ritenuta='INPS' AND tipo_ritenuta_inps <> '') OR
               (p_tipo_ritenuta='IRPEG' AND tipo_ritenuta_irpeg <> '') THEN
            stato_mandato= elencoMandati.ord_stato_code;

            nome_ente=elencoMandati.ente_denominazione;
            partita_iva_ente=elencoMandati.cod_fisc_ente;
            anno_ese_finanz=elencoMandati.anno_eser;
            desc_mandato=COALESCE(elencoMandati.ord_desc,'');

            anno_mandato=elencoMandati.ord_anno;
            numero_mandato=elencoMandati.ord_numero;
            data_mandato=elencoMandati.ord_emissione_data;
            benef_cod_fiscale=COALESCE(elencoMandati.codice_fiscale,'');
            benef_partita_iva=COALESCE(elencoMandati.partita_iva,'');
            benef_nome=COALESCE(elencoMandati.soggetto_desc,'');
            benef_codice=COALESCE(elencoMandati.soggetto_code,'');
            
            return next;
         end if;
     
  nome_ente='';
  partita_iva_ente='';
  anno_ese_finanz=0;
  anno_mandato=0;
  numero_mandato=0;
  data_mandato=NULL;
  desc_mandato='';
  benef_cod_fiscale='';
  benef_partita_iva='';
  benef_nome='';
  stato_mandato='';
  codice_tributo_irpef='';
  codice_tributo_inps='';
  codice_risc='';
  importo_lordo_mandato=0;
  importo_netto_irpef=0;
  importo_imponibile_irpef=0;
  importo_ritenuta_irpef=0;
  importo_netto_inps=0;
  importo_imponibile_inps=0;
  importo_ritenuta_inps=0;
  importo_netto_irap=0;
  importo_imponibile_irap=0;
  importo_ritenuta_irap=0;
  tipo_ritenuta_inps='';
  tipo_ritenuta_irpef='';
  tipo_ritenuta_irap='';
  codice_ritenuta_irap='';
  desc_ritenuta_irap='';
  benef_codice='';
  importo_ente_irap=0;
  importo_ente_inps=0;

  tipo_ritenuta_irpeg='';
  codice_tributo_irpeg='';
  importo_ritenuta_irpeg=0;
  importo_netto_irpeg=0;
  importo_imponibile_irpeg=0;
  codice_ritenuta_irpeg='';
  desc_ritenuta_irpeg='';
  importo_ente_irpeg=0;
  code_caus_770:='';
  desc_caus_770:='';
  code_caus_esenz:='';
  desc_caus_esenz:='';
  attivita_inizio:=NULL;
  attivita_fine:=NULL;
  attivita_code:='';
  attivita_desc:='';
  
end loop;

	/* 11/10/2016: è stata richiesta IRAP, estraggo solo i dati relativi */
elsif p_tipo_ritenuta = 'IRAP' THEN
	idFatturaOld=0;
	contaQuotaIrap=0;
    importoParzIrapImpon =0;
    importoParzIrapNetto =0;
    importoParzIrapRiten =0;
    importoParzIrapEnte =0;
    
    	/* 11/10/2016: la query deve estrarre insieme mandati e dati IRAP e
        	ordinare i dati per id fattura (doc_id) perchè ci sono
            fatture che sono legate a differenti mandati.
            In questo caso è necessario riproporzionare l'importo
            dell'aliquota a seconda della percentuale della quota fattura
            relativa al mandato rispetto al totale fattura */        
	FOR elencoMandati IN
    select * from 
		(SELECT d_onere_tipo.onere_tipo_code, d_onere_tipo.onere_tipo_desc,
            d_onere.onere_code, d_onere.onere_desc, t_ordinativo_ts.ord_id,
            t_subdoc.subdoc_id,t_doc.doc_id,
              t_doc.doc_importo IMPORTO_FATTURA,
              t_subdoc.subdoc_importo IMPORTO_QUOTA,
              t_subdoc.subdoc_importo_da_dedurre IMP_DEDURRE,
              sum(r_doc_onere.importo_imponibile) IMPORTO_IMPONIBILE,
              sum(r_doc_onere.importo_carico_soggetto) IMPOSTA,
              sum(r_doc_onere.importo_carico_ente) IMPORTO_CARICO_ENTE
            from siac_t_ordinativo_ts t_ordinativo_ts,
                siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts,          
                siac_t_doc t_doc, 
                siac_t_subdoc t_subdoc,
                siac_r_doc_onere r_doc_onere,
                siac_d_onere d_onere,
                siac_d_onere_tipo d_onere_tipo
            WHERE r_subdoc_ordinativo_ts.ord_ts_id=t_ordinativo_ts.ord_ts_id
                AND t_doc.doc_id=t_subdoc.doc_id
                and t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id
                AND r_doc_onere.doc_id=t_doc.doc_id
                AND d_onere.onere_id=r_doc_onere.onere_id
                AND d_onere_tipo.onere_tipo_id=d_onere.onere_tipo_id         
               -- AND t_ordinativo_ts.ord_id=mandati.ord_id
                AND upper(d_onere_tipo.onere_tipo_code) in('IRAP')
                AND t_doc.data_cancellazione IS NULL
                AND t_subdoc.data_cancellazione IS NULL
                AND r_doc_onere.data_cancellazione IS NULL
                AND d_onere.data_cancellazione IS NULL
                AND d_onere_tipo.data_cancellazione IS NULL
                AND t_ordinativo_ts.data_cancellazione IS NULL
                AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL
                GROUP BY d_onere_tipo.onere_tipo_code, d_onere_tipo.onere_tipo_desc,
                	t_ordinativo_ts.ord_id, t_subdoc.subdoc_id,
                    t_doc.doc_id,
                    d_onere.onere_code, d_onere.onere_desc,
                     t_doc.doc_importo, t_subdoc.subdoc_importo , 
                     t_subdoc.subdoc_importo_da_dedurre) irap,
        (select 	ep.ente_denominazione, ep.codice_fiscale cod_fisc_ente, 
            t_periodo.anno anno_eser, t_ordinativo.ord_anno,
             t_ordinativo.ord_desc, t_ordinativo.ord_id,
            t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,     
            t_soggetto.soggetto_code, t_soggetto.soggetto_desc,  
            t_soggetto.partita_iva,t_soggetto.codice_fiscale,
            t_bil_elem.elem_code cod_cap, t_bil_elem.elem_code2 cod_art,
            t_bil_elem.elem_id, d_ord_stato.ord_stato_code, 
            SUM(t_ord_ts_det.ord_ts_det_importo) IMPORTO_TOTALE,
            t_movgest.movgest_anno anno_impegno
            FROM  	siac_t_ente_proprietario ep,
                    siac_t_bil t_bil,
                    siac_t_periodo t_periodo,
                    siac_r_ordinativo_bil_elem r_ordinativo_bil_elem,
                    siac_t_bil_elem t_bil_elem,                  
                    siac_t_ordinativo t_ordinativo
                  --09/02/2017: aggiunta la tabella della quietanza per testare
                  -- la data quietanza se specificata in input.
                  	LEFT JOIN siac_r_ordinativo_quietanza r_ord_quietanza
                   	on (r_ord_quietanza.ord_id=t_ordinativo.ord_id
                       	and r_ord_quietanza.data_cancellazione IS NULL),  
                    siac_t_ordinativo_ts t_ord_ts,
                    siac_r_liquidazione_ord r_liq_ord,
                    siac_r_liquidazione_movgest r_liq_movgest,
                    siac_t_movgest t_movgest,
                    siac_t_movgest_ts t_movgest_ts,
                    siac_t_ordinativo_ts_det t_ord_ts_det,
                    siac_d_ordinativo_ts_det_tipo d_ts_det_tipo,
                    siac_r_ordinativo_stato r_ord_stato,  
                    siac_d_ordinativo_stato d_ord_stato ,
                     siac_d_ordinativo_tipo d_ord_tipo,
                     siac_r_ordinativo_soggetto r_ord_soggetto ,
                     siac_t_soggetto t_soggetto  		    	
            WHERE  t_ordinativo.ente_proprietario_id=ep.ente_proprietario_id        	
                AND r_ordinativo_bil_elem.elem_id=t_bil_elem.elem_id            
                AND  r_ordinativo_bil_elem.ord_id=t_ordinativo.ord_id                    
               AND t_ordinativo.ord_id=r_ord_stato.ord_id
               AND t_bil.bil_id=t_ordinativo.bil_id
               AND t_periodo.periodo_id=t_bil.periodo_id
               AND t_ord_ts.ord_id=t_ordinativo.ord_id           
               AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
               AND d_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
               AND d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
               AND d_ord_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id 
               AND t_soggetto.soggetto_id=r_ord_soggetto.soggetto_id
               AND r_ord_soggetto.ord_id=t_ordinativo.ord_id
               AND r_liq_ord.sord_id= t_ord_ts.ord_ts_id
               AND r_liq_movgest.liq_id=r_liq_ord.liq_id
               AND t_movgest_ts.movgest_ts_id=r_liq_movgest.movgest_ts_id
               AND t_movgest_ts.movgest_id=t_movgest.movgest_id  
               -- inizio INC000001342288      
                             AND ((p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL
                  AND (to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                      between p_data_mandato_da AND p_data_mandato_a))
                  OR (p_data_mandato_da IS  NULL AND p_data_mandato_a IS  NULL))
              AND ((p_data_trasm_da IS NOT NULL AND p_data_trasm_a IS NOT NULL
                  AND (to_timestamp(to_char(t_ordinativo.ord_trasm_oil_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                      between p_data_trasm_da AND p_data_trasm_a))
                  OR (p_data_trasm_da IS  NULL AND p_data_trasm_a IS  NULL))           
    		--- fine INC000001342288	       
            --09/02/2017: aggiunto test sulla data quietanza
                  -- se specificata in input.
              AND ((p_data_quietanza_da IS NOT NULL AND p_data_quietanza_a IS NOT NULL
                  AND (to_timestamp(to_char(r_ord_quietanza.ord_quietanza_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                      between p_data_quietanza_da AND p_data_quietanza_a)) 
                  OR (p_data_quietanza_da IS  NULL AND p_data_quietanza_a IS  NULL))      
            --AND p_data_mandato_da =to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                AND t_ordinativo.ente_proprietario_id = p_ente_prop_id
                AND t_periodo.anno=p_anno
                    /* Gli stati possibili sono:
                        I = INSERITO
                        T = TRASMESSO 
                        Q = QUIETANZIATO
                        F = FIRMATO
                        A = ANNULLATO 
                        Prendo tutti tranne gli annullati.
                       */
                AND d_ord_stato.ord_stato_code <> 'A'
                AND d_ord_tipo.ord_tipo_code='P' /* Ordinativi di pagamento */
                AND d_ts_det_tipo.ord_ts_det_tipo_code='A' /* importo attuale */
                    /* devo testare la data di fine validità perchè
                        quando un ordinativo è annullato, lo trovo 2 volte,
                        uno con stato inserito e l'altro annullato */
                AND r_ord_stato.validita_fine IS NULL 
                AND ep.data_cancellazione IS NULL
                AND r_ord_stato.data_cancellazione IS NULL
                AND r_ordinativo_bil_elem.data_cancellazione IS NULL
                AND t_bil_elem.data_cancellazione IS NULL
                AND  t_bil.data_cancellazione IS NULL
                AND  t_periodo.data_cancellazione IS NULL
                AND  t_ordinativo.data_cancellazione IS NULL
                AND  t_ord_ts.data_cancellazione IS NULL
                AND  t_ord_ts_det.data_cancellazione IS NULL
                AND  d_ts_det_tipo.data_cancellazione IS NULL
                AND  r_ord_stato.data_cancellazione IS NULL
                AND  d_ord_stato.data_cancellazione IS NULL
                AND  d_ord_tipo.data_cancellazione IS NULL  
                AND r_ord_soggetto.data_cancellazione IS NULL
                AND t_soggetto.data_cancellazione IS NULL
                AND r_liq_ord.data_cancellazione IS NULL 
                AND r_liq_movgest.data_cancellazione IS NULL 
                AND t_movgest.data_cancellazione IS NULL
                AND t_movgest_ts.data_cancellazione IS NULL
                AND t_ord_ts.data_cancellazione IS NULL
                GROUP BY ep.ente_denominazione, ep.codice_fiscale, 
                  t_periodo.anno , t_ordinativo.ord_anno,
                   t_ordinativo.ord_desc, t_ordinativo.ord_id,
                  t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,   
                  t_soggetto.soggetto_code, t_soggetto.soggetto_desc,  
                  t_soggetto.partita_iva,t_soggetto.codice_fiscale,                  
                  t_bil_elem.elem_code , t_bil_elem.elem_code2 ,
                  t_bil_elem.elem_id, d_ord_stato.ord_stato_code, t_movgest.movgest_anno
                   ) mandati   
                where mandati.ord_id =     irap.ord_id    
                ORDER BY irap.doc_id, irap.subdoc_id                  
   loop           
        percQuota=0;    	          
       
   			/* verifico quante quote ci sono relative alla fattura */
		numeroQuoteFattura=0;
        SELECT count(*)
        INTO numeroQuoteFattura
        from siac_t_subdoc s
        where s.doc_id= elencoMandati.doc_id
        		--19/07/2017: prendo solo le quote NON STORNATE completamente.
            and s.subdoc_importo-s.subdoc_importo_da_dedurre>0;
        IF NOT FOUND THEN
        	numeroQuoteFattura=0;
        END IF;
        --19/07/2017: devo calcolare il totale da dedurre su tutta la fattura
        --	per calcolare correttamente la percentuale della quota.
        importoTotDaDedurreFattura:=0;
        SELECT sum(s.subdoc_importo_da_dedurre)
          INTO importoTotDaDedurreFattura
          from siac_t_subdoc s
          where s.doc_id= elencoMandati.doc_id;
          IF NOT FOUND THEN
              importoTotDaDedurreFattura:=0;
        END IF;
        
        raise notice 'contaQuotaIrapXXX= %', contaQuotaIrap;
        
        stato_mandato= elencoMandati.ord_stato_code;

        nome_ente=elencoMandati.ente_denominazione;
        partita_iva_ente=elencoMandati.cod_fisc_ente;
        anno_ese_finanz=elencoMandati.anno_eser;
        desc_mandato=COALESCE(elencoMandati.ord_desc,'');

        anno_mandato=elencoMandati.ord_anno;
        numero_mandato=elencoMandati.ord_numero;
        data_mandato=elencoMandati.ord_emissione_data;
        benef_cod_fiscale=COALESCE(elencoMandati.codice_fiscale,'');
        benef_partita_iva=COALESCE(elencoMandati.partita_iva,'');
        benef_nome=COALESCE(elencoMandati.soggetto_desc,'');
        benef_codice=COALESCE(elencoMandati.soggetto_code,'');
                
        tipo_ritenuta_irap=upper(elencoMandati.onere_tipo_code);
                				
        codice_ritenuta_irap=elencoMandati.onere_code;
        desc_ritenuta_irap=elencoMandati.onere_desc;
        
        	-- calcolo la percentuale della quota corrente rispetto
            -- al totale fattura.
        --19/07/2017: La percentuale della quota deve essere calcolata tenendo conto
        --	della quota da dedurre.
        --percQuota = elencoMandati.IMPORTO_QUOTA*100/ elencoMandati.IMPORTO_FATTURA;  
        percQuota = (elencoMandati.IMPORTO_QUOTA-elencoMandati.IMP_DEDURRE)*100/ 
        	(elencoMandati.IMPORTO_FATTURA-importoTotDaDedurreFattura);               
        
        importo_lordo_mandato= COALESCE(elencoMandati.IMPORTO_TOTALE,0);         
        raise notice 'IRAP ORD_ID=%,  ORD_NUM =%', elencoMandati.ord_id,numero_mandato; 
        raise notice 'ESTRATTO: IMPON =%, RITEN = %, ENTE =%', elencoMandati.IMPORTO_IMPONIBILE,elencoMandati.IMPOSTA,elencoMandati.IMPORTO_CARICO_ENTE;          
        raise notice 'FATTURA_ID = %, NUMERO_QUOTE = %, IMPORTO FATT = %, IMPORTO QUOTA = %, PERC_QUOTA = %',elencoMandati.doc_id,numeroQuoteFattura, elencoMandati.IMPORTO_FATTURA, elencoMandati.IMPORTO_QUOTA,  percQuota;
        raise notice 'Importo da Dedurre= %', elencoMandati.IMP_DEDURRE;
        raise notice 'Perc quota = %', percQuota;
        
        	-- la fattura è la stessa della quota precedente. 
		IF  idFatturaOld = elencoMandati.doc_id THEN
        	contaQuotaIrap=contaQuotaIrap+1;
        	raise notice 'Fattura uguale alla prec: %, num_quota = %',idFatturaOld, contaQuotaIrap;
            	-- è l'ultima quota della fattura:
                -- gli importi sono quelli totali meno quelli delle quote
                -- precedenti, per evitare problemi di arrotondamento.            
            if contaQuotaIrap= numeroQuoteFattura THEN
            	raise notice 'ULTIMA QUOTA';
            	importo_imponibile_irap=elencoMandati.IMPORTO_IMPONIBILE-importoParzIrapImpon;
                importo_ritenuta_irap=elencoMandati.IMPOSTA-importoParzIrapRiten;
                importo_ente_irap=elencoMandati.IMPORTO_CARICO_ENTE-importoParzIrapEnte;
                
                	-- azzero gli importi parziali per fattura
                importoParzIrapImpon=0;
        		importoParzIrapRiten=0;
        		importoParzIrapEnte=0;
        		importoParzIrapNetto=0;
                contaQuotaIrap=0;
            ELSE
            	raise notice 'ALTRA QUOTA';
            	importo_imponibile_irap = elencoMandati.IMPORTO_IMPONIBILE*percQuota/100;
        		importo_ritenuta_irap = elencoMandati.IMPOSTA*percQuota/100; 
        		importo_ente_irap=elencoMandati.IMPORTO_CARICO_ENTE*percQuota/100;
                importo_netto_irap=importo_lordo_mandato-importo_ritenuta_irap;
                
                	-- sommo l'importo della quota corrente
                    -- al parziale per fattura.
                importoParzIrapImpon=importoParzIrapImpon+importo_imponibile_irap;
                importoParzIrapRiten=importoParzIrapRiten+ importo_ritenuta_irap;
                importoParzIrapEnte=importoParzIrapEnte+importo_ente_irap;
                importoParzIrapNetto=importoParzIrapNetto+importo_netto_irap;
                --contaQuotaIrap=contaQuotaIrap+1;
                
            END IF;
        ELSE -- fattura diversa dalla precedente
        	raise notice 'Fattura diversa dalla prec: %, %',idFatturaOld,elencoMandati.doc_id;
            importo_imponibile_irap = elencoMandati.IMPORTO_IMPONIBILE*percQuota/100;
        	importo_ritenuta_irap = elencoMandati.IMPOSTA*percQuota/100; 
        	importo_ente_irap=elencoMandati.IMPORTO_CARICO_ENTE*percQuota/100;
            importo_netto_irap=importo_lordo_mandato-importo_ritenuta_irap;

                -- imposto l'importo della quota corrente
                -- al parziale per fattura.            
            importoParzIrapImpon=importo_imponibile_irap;
        	importoParzIrapRiten= importo_ritenuta_irap;
        	importoParzIrapEnte=importo_ente_irap;
       		importoParzIrapNetto=importo_netto_irap;
            contaQuotaIrap=1;            
        END IF;
        
                
      raise notice 'ParzImpon = %, ParzRiten = %, ParzEnte = %, ParzNetto = %', importoParzIrapImpon,importoParzIrapRiten,importoParzIrapEnte,importoParzIrapNetto;                
      raise notice 'IMPON =%, RITEN = %, ENTE =%, NETTO= %', importo_imponibile_irap, importo_ritenuta_irap,importo_ente_irap,importo_ente_irap; 
      idFatturaOld=elencoMandati.doc_id;
            
      return next;
      raise notice '';
      
      nome_ente='';
      partita_iva_ente='';
      anno_ese_finanz=0;
      anno_mandato=0;
      numero_mandato=0;
      data_mandato=NULL;
      desc_mandato='';
      benef_cod_fiscale='';
      benef_partita_iva='';
      benef_nome='';
      stato_mandato='';
      codice_tributo_irpef='';
      codice_tributo_inps='';
      codice_risc='';
      importo_lordo_mandato=0;
      importo_netto_irpef=0;
      importo_imponibile_irpef=0;
      importo_ritenuta_irpef=0;
      importo_netto_inps=0;
      importo_imponibile_inps=0;
      importo_ritenuta_inps=0;
      importo_netto_irap=0;
      importo_imponibile_irap=0;
      importo_ritenuta_irap=0;
      tipo_ritenuta_inps='';
      tipo_ritenuta_irpef='';
      tipo_ritenuta_irap='';
      codice_ritenuta_irap='';
      desc_ritenuta_irap='';
      benef_codice='';
      importo_ente_irap=0;
      importo_ente_inps=0;

      tipo_ritenuta_irpeg='';
      codice_tributo_irpeg='';
      importo_ritenuta_irpeg=0;
      importo_netto_irpeg=0;
      importo_imponibile_irpeg=0;
      codice_ritenuta_irpeg='';
      desc_ritenuta_irpeg='';
      importo_ente_irpeg=0;
      code_caus_770:='';
      desc_caus_770:='';
      code_caus_esenz:='';
      desc_caus_esenz:='';
      attivita_inizio:=NULL;
      attivita_fine:=NULL;
      attivita_code:='';
      attivita_desc:='';
      
    end loop;        
      --end if;
elsif p_tipo_ritenuta = 'IRPEF' THEN
	idFatturaOld=0;
	contaQuotaIrpef=0;
    importoParzIrpefImpon =0;
    importoParzIrpefNetto =0;
    importoParzIrpefRiten =0;
    --importoParzIrpefEnte =0;
    
    	/* 11/10/2016: la query deve estrarre insieme mandati e dati IRPEF e
        	ordinare i dati per id fattura (doc_id) perchè ci sono
            fatture che sono legate a differenti mandati.
            In questo caso è necessario riproporzionare l'importo
            dell'aliquota a seconda della percentuale della quota fattura
            relativa al mandato rispetto al totale fattura */        
	FOR elencoMandati IN
    select * from 
		(SELECT d_onere_tipo.onere_tipo_code, d_onere_tipo.onere_tipo_desc,
            d_onere.onere_code, d_onere.onere_desc, t_ordinativo_ts.ord_id,
            t_subdoc.subdoc_id,t_doc.doc_id,d_onere.onere_id ,
            d_dom_non_sogg_tipo.somma_non_soggetta_tipo_code,
            d_dom_non_sogg_tipo.somma_non_soggetta_tipo_desc,
              t_doc.doc_importo IMPORTO_FATTURA,
              t_subdoc.subdoc_importo IMPORTO_QUOTA,
              t_subdoc.subdoc_importo_da_dedurre IMP_DEDURRE,
              sum(r_doc_onere.importo_imponibile) IMPORTO_IMPONIBILE,
              sum(r_doc_onere.importo_carico_soggetto) IMPOSTA,
              sum(r_doc_onere.importo_carico_ente) IMPORTO_CARICO_ENTE
            from siac_t_ordinativo_ts t_ordinativo_ts,
                siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts,          
                siac_t_doc t_doc, 
                siac_t_subdoc t_subdoc,
                siac_r_doc_onere r_doc_onere
                	LEFT JOIN siac_d_somma_non_soggetta_tipo d_dom_non_sogg_tipo
                    	ON (d_dom_non_sogg_tipo.somma_non_soggetta_tipo_id=
                        	  r_doc_onere.somma_non_soggetta_tipo_id
                            AND d_dom_non_sogg_tipo.data_cancellazione IS NULL),
                siac_d_onere d_onere,                	
                siac_d_onere_tipo d_onere_tipo               
            WHERE r_subdoc_ordinativo_ts.ord_ts_id=t_ordinativo_ts.ord_ts_id
                AND t_doc.doc_id=t_subdoc.doc_id
                and t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id
                AND r_doc_onere.doc_id=t_doc.doc_id
                AND d_onere.onere_id=r_doc_onere.onere_id
                AND d_onere_tipo.onere_tipo_id=d_onere.onere_tipo_id                                      
               -- AND t_ordinativo_ts.ord_id=mandati.ord_id
                AND upper(d_onere_tipo.onere_tipo_code) in('IRPEF')
                AND t_doc.data_cancellazione IS NULL
                AND t_subdoc.data_cancellazione IS NULL
                AND r_doc_onere.data_cancellazione IS NULL
                AND d_onere.data_cancellazione IS NULL
                AND d_onere_tipo.data_cancellazione IS NULL
                AND t_ordinativo_ts.data_cancellazione IS NULL
                AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL                                
                GROUP BY d_onere_tipo.onere_tipo_code, d_onere_tipo.onere_tipo_desc,
                	t_ordinativo_ts.ord_id, t_subdoc.subdoc_id,
                    d_dom_non_sogg_tipo.somma_non_soggetta_tipo_code,
            		d_dom_non_sogg_tipo.somma_non_soggetta_tipo_desc,
                    t_doc.doc_id,d_onere.onere_id ,
                    d_onere.onere_code, d_onere.onere_desc,
                     t_doc.doc_importo, t_subdoc.subdoc_importo,
                     t_subdoc.subdoc_importo_da_dedurre  ) irpef
				/* 01/06/2017: aggiunta gestione delle causali 770 */                    
               LEFT JOIN (SELECT distinct r_onere_caus.onere_id,
               				r_doc_onere.doc_id,t_subdoc.subdoc_id,
               				COALESCE(d_causale.caus_code,'') caus_code_770,
                            COALESCE(d_causale.caus_desc,'') caus_desc_770
               			FROM siac_r_doc_onere r_doc_onere,
                        	siac_t_subdoc t_subdoc,
                        	siac_r_onere_causale r_onere_caus,
							siac_d_causale d_causale ,
							siac_d_modello d_modello                                                       
                    WHERE   t_subdoc.doc_id=r_doc_onere.doc_id                    	
                    	AND r_doc_onere.onere_id=r_onere_caus.onere_id
                        AND d_causale.caus_id=r_doc_onere.caus_id
                    	AND d_causale.caus_id=r_onere_caus.caus_id   
                    	AND d_modello.model_id=d_causale.model_id                                                      
                        AND d_modello.model_code='01' --Causale 770
                        AND r_doc_onere.ente_proprietario_id =p_ente_prop_id                      AND r_doc_onere.onere_id=5
                        AND r_onere_caus.validita_fine IS NULL                        
                        AND r_doc_onere.data_cancellazione IS NULL 
                        AND d_modello.data_cancellazione IS NULL 
                        AND d_causale.data_cancellazione IS NULL
                        AND t_subdoc.data_cancellazione IS NULL) caus_770
                    ON caus_770.onere_id=irpef.onere_id
                    	AND caus_770.doc_id=irpef.doc_id
                        AND caus_770.subdoc_id=irpef.subdoc_id,
        (select 	ep.ente_denominazione, ep.codice_fiscale cod_fisc_ente, 
            t_periodo.anno anno_eser, t_ordinativo.ord_anno,
             t_ordinativo.ord_desc, t_ordinativo.ord_id,
            t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,     
            t_soggetto.soggetto_code, t_soggetto.soggetto_desc,  
            t_soggetto.partita_iva,t_soggetto.codice_fiscale,
            t_bil_elem.elem_code cod_cap, t_bil_elem.elem_code2 cod_art,
            t_bil_elem.elem_id, d_ord_stato.ord_stato_code, 
            SUM(t_ord_ts_det.ord_ts_det_importo) IMPORTO_TOTALE,
            t_movgest.movgest_anno anno_impegno
            FROM  	siac_t_ente_proprietario ep,
                    siac_t_bil t_bil,
                    siac_t_periodo t_periodo,
                    siac_r_ordinativo_bil_elem r_ordinativo_bil_elem,
                    siac_t_bil_elem t_bil_elem,                  
                    siac_t_ordinativo t_ordinativo
                  --09/02/2017: aggiunta la tabella della quietanza per testare
                  -- la data quietanza se specificata in input.
                  	LEFT JOIN siac_r_ordinativo_quietanza r_ord_quietanza
                   	on (r_ord_quietanza.ord_id=t_ordinativo.ord_id
                       	and r_ord_quietanza.data_cancellazione IS NULL),  
                    siac_t_ordinativo_ts t_ord_ts,
                    siac_r_liquidazione_ord r_liq_ord,
                    siac_r_liquidazione_movgest r_liq_movgest,
                    siac_t_movgest t_movgest,
                    siac_t_movgest_ts t_movgest_ts,
                    siac_t_ordinativo_ts_det t_ord_ts_det,
                    siac_d_ordinativo_ts_det_tipo d_ts_det_tipo,
                    siac_r_ordinativo_stato r_ord_stato,  
                    siac_d_ordinativo_stato d_ord_stato ,
                     siac_d_ordinativo_tipo d_ord_tipo,
                     siac_r_ordinativo_soggetto r_ord_soggetto ,
                     siac_t_soggetto t_soggetto  		    	
            WHERE  t_ordinativo.ente_proprietario_id=ep.ente_proprietario_id        	
                AND r_ordinativo_bil_elem.elem_id=t_bil_elem.elem_id            
                AND  r_ordinativo_bil_elem.ord_id=t_ordinativo.ord_id                    
               AND t_ordinativo.ord_id=r_ord_stato.ord_id
               AND t_bil.bil_id=t_ordinativo.bil_id
               AND t_periodo.periodo_id=t_bil.periodo_id
               AND t_ord_ts.ord_id=t_ordinativo.ord_id           
               AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
               AND d_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
               AND d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
               AND d_ord_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id 
               AND t_soggetto.soggetto_id=r_ord_soggetto.soggetto_id
               AND r_ord_soggetto.ord_id=t_ordinativo.ord_id
               AND r_liq_ord.sord_id= t_ord_ts.ord_ts_id
               AND r_liq_movgest.liq_id=r_liq_ord.liq_id
               AND t_movgest_ts.movgest_ts_id=r_liq_movgest.movgest_ts_id
               AND t_movgest_ts.movgest_id=t_movgest.movgest_id    
                             AND ((p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL
                  AND (to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                      between p_data_mandato_da AND p_data_mandato_a))
                  OR (p_data_mandato_da IS  NULL AND p_data_mandato_a IS  NULL))
              AND ((p_data_trasm_da IS NOT NULL AND p_data_trasm_a IS NOT NULL
                  AND (to_timestamp(to_char(t_ordinativo.ord_trasm_oil_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                      between p_data_trasm_da AND p_data_trasm_a))
                  OR (p_data_trasm_da IS  NULL AND p_data_trasm_a IS  NULL))           
              AND ((p_data_quietanza_da IS NOT NULL AND p_data_quietanza_a IS NOT NULL
                  AND (to_timestamp(to_char(r_ord_quietanza.ord_quietanza_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                      between p_data_quietanza_da AND p_data_quietanza_a)) 
                  OR (p_data_quietanza_da IS  NULL AND p_data_quietanza_a IS  NULL))                 
                AND t_ordinativo.ente_proprietario_id = p_ente_prop_id
                --and t_ordinativo.ord_numero in (6744,6745,6746)
                --and t_ordinativo.ord_numero in (7578,7579,7580)                
                AND t_periodo.anno=p_anno
                    /* Gli stati possibili sono:
                        I = INSERITO
                        T = TRASMESSO 
                        Q = QUIETANZIATO
                        F = FIRMATO
                        A = ANNULLATO 
                        Prendo tutti tranne gli annullati.
                       */
                AND d_ord_stato.ord_stato_code <> 'A'
                AND d_ord_tipo.ord_tipo_code='P' /* Ordinativi di pagamento */
                AND d_ts_det_tipo.ord_ts_det_tipo_code='A' /* importo attuale */
                    /* devo testare la data di fine validità perchè
                        quando un ordinativo è annullato, lo trovo 2 volte,
                        uno con stato inserito e l'altro annullato */
                AND r_ord_stato.validita_fine IS NULL 
                AND ep.data_cancellazione IS NULL
                AND r_ord_stato.data_cancellazione IS NULL
                AND r_ordinativo_bil_elem.data_cancellazione IS NULL
                AND t_bil_elem.data_cancellazione IS NULL
                AND  t_bil.data_cancellazione IS NULL
                AND  t_periodo.data_cancellazione IS NULL
                AND  t_ordinativo.data_cancellazione IS NULL
                AND  t_ord_ts.data_cancellazione IS NULL
                AND  t_ord_ts_det.data_cancellazione IS NULL
                AND  d_ts_det_tipo.data_cancellazione IS NULL
                AND  r_ord_stato.data_cancellazione IS NULL
                AND  d_ord_stato.data_cancellazione IS NULL
                AND  d_ord_tipo.data_cancellazione IS NULL  
                AND r_ord_soggetto.data_cancellazione IS NULL
                AND t_soggetto.data_cancellazione IS NULL
                AND r_liq_ord.data_cancellazione IS NULL 
                AND r_liq_movgest.data_cancellazione IS NULL 
                AND t_movgest.data_cancellazione IS NULL
                AND t_movgest_ts.data_cancellazione IS NULL
                AND t_ord_ts.data_cancellazione IS NULL
                GROUP BY ep.ente_denominazione, ep.codice_fiscale, 
                  t_periodo.anno , t_ordinativo.ord_anno,
                   t_ordinativo.ord_desc, t_ordinativo.ord_id,
                  t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,   
                  t_soggetto.soggetto_code, t_soggetto.soggetto_desc,  
                  t_soggetto.partita_iva,t_soggetto.codice_fiscale,                  
                  t_bil_elem.elem_code , t_bil_elem.elem_code2 ,
                  t_bil_elem.elem_id, d_ord_stato.ord_stato_code, t_movgest.movgest_anno
                   ) mandati 
                where mandati.ord_id =     irpef.ord_id    
                ORDER BY irpef.doc_id, irpef.subdoc_id                  
   loop           
        percQuota=0;    	          
       
   			/* se la fattura è nuovaverifico quante quote ci sono 
            	relative alla fattura */
        IF  idFatturaOld <> elencoMandati.doc_id THEN
          numeroQuoteFattura=0;
          SELECT count(*)
          INTO numeroQuoteFattura
          from siac_t_subdoc s
          where s.doc_id= elencoMandati.doc_id
          	--19/07/2017: prendo solo le quote NON STORNATE completamente.
          	and s.subdoc_importo-s.subdoc_importo_da_dedurre>0;
          IF NOT FOUND THEN
              numeroQuoteFattura=0;
          END IF;
       
        --19/07/2017: devo calcolare il totale da dedurre su tutta la fattura
        --	per calcolare correttamente la percentuale della quota.
        importoTotDaDedurreFattura:=0;
        SELECT sum(s.subdoc_importo_da_dedurre)
          INTO importoTotDaDedurreFattura
          from siac_t_subdoc s
          where s.doc_id= elencoMandati.doc_id;
          IF NOT FOUND THEN
              importoTotDaDedurreFattura:=0;
          END IF;
        END IF;
        
        raise notice 'contaQuotaIrpefXXX= %', contaQuotaIrpef;
        stato_mandato= elencoMandati.ord_stato_code;

        nome_ente=elencoMandati.ente_denominazione;
        partita_iva_ente=elencoMandati.cod_fisc_ente;
        anno_ese_finanz=elencoMandati.anno_eser;
        desc_mandato=COALESCE(elencoMandati.ord_desc,'');

        anno_mandato=elencoMandati.ord_anno;
        numero_mandato=elencoMandati.ord_numero;
        data_mandato=elencoMandati.ord_emissione_data;
        benef_cod_fiscale=COALESCE(elencoMandati.codice_fiscale,'');
        benef_partita_iva=COALESCE(elencoMandati.partita_iva,'');
        benef_nome=COALESCE(elencoMandati.soggetto_desc,'');
        benef_codice=COALESCE(elencoMandati.soggetto_code,'');
                
        tipo_ritenuta_irpef=upper(elencoMandati.onere_tipo_code);
                				
        codice_tributo_irpef=elencoMandati.onere_code;
        --desc_ritenuta_irpef=elencoMandati.onere_desc;
        code_caus_770:=COALESCE(elencoMandati.caus_code_770,'');
		desc_caus_770:=COALESCE(elencoMandati.caus_desc_770,'');
        code_caus_esenz:=COALESCE(elencoMandati.somma_non_soggetta_tipo_code,'');
		desc_caus_esenz:=COALESCE(elencoMandati.somma_non_soggetta_tipo_desc,'');
        
        	-- calcolo la percentuale della quota corrente rispetto
            -- al totale fattura.
        --19/07/2017: La percentuale della quota deve essere calcolata tenendo conto
        --	della quota da dedurre.
        --percQuota = elencoMandati.IMPORTO_QUOTA*100/ elencoMandati.IMPORTO_FATTURA;  
        percQuota = (elencoMandati.IMPORTO_QUOTA-elencoMandati.IMP_DEDURRE)*100/ 
        	(elencoMandati.IMPORTO_FATTURA-importoTotDaDedurreFattura);               
        
        importo_lordo_mandato= COALESCE(elencoMandati.IMPORTO_TOTALE,0); 
          
        raise notice 'irpef ORD_ID=%,  ORD_NUM =%', elencoMandati.ord_id,numero_mandato; 
        raise notice 'ESTRATTO: IMPON =%, RITEN = %, LORDO MANDATO = %', elencoMandati.IMPORTO_IMPONIBILE,elencoMandati.IMPOSTA,importo_lordo_mandato;          
        raise notice 'FATTURA_ID = %, NUMERO_QUOTE = %, IMPORTO FATT = %, IMPORTO QUOTA = %, PERC_QUOTA = %',elencoMandati.doc_id,numeroQuoteFattura, elencoMandati.IMPORTO_FATTURA, elencoMandati.IMPORTO_QUOTA,  percQuota;
        raise notice 'importo da dedurre quota: %; Importo da dedurre TOTALE = % ', 
        	elencoMandati.IMP_DEDURRE, importoTotDaDedurreFattura;
        raise notice 'Perc quota = %', percQuota;
        
        	-- la fattura è la stessa della quota precedente. 
		IF  idFatturaOld = elencoMandati.doc_id THEN
        	contaQuotaIrpef=contaQuotaIrpef+1;
        	raise notice 'Fattura uguale alla prec: %, num_quota = %',idFatturaOld, contaQuotaIrpef;
            	
                -- è l'ultima quota della fattura:
                -- gli importi sono quelli totali meno quelli delle quote
                -- precedenti, per evitare problemi di arrotondamento.            
            if contaQuotaIrpef= numeroQuoteFattura THEN
            	raise notice 'ULTIMA QUOTA';
            	importo_imponibile_irpef=elencoMandati.IMPORTO_IMPONIBILE-importoParzIrpefImpon;
                importo_ritenuta_irpef=round(elencoMandati.IMPOSTA-importoParzIrpefRiten,2);
                --importo_ente_irpef=elencoMandati.IMPORTO_CARICO_ENTE-importoParzIrpefEnte;
        raise notice 'importo_lordo_mandato = %, importo_ritenuta_irpef = %,
                		importoParzIrpefRiten = %',
                	 importo_lordo_mandato, importo_ritenuta_irpef, importoParzIrpefRiten;
				importo_netto_irpef=importo_lordo_mandato-importo_ritenuta_irpef;
                
                raise notice 'Dopo ultima rata - ParzImpon = %, ParzRiten = %, ParzNetto = %', importoParzIrpefImpon,importoParzIrpefRiten,importoParzIrpefNetto;    
                	-- azzero gli importi parziali per fattura
                importoParzIrpefImpon=0;
        		importoParzIrpefRiten=0;
        		importoParzIrpefNetto=0;
                contaQuotaIrpef=0;
            ELSE
            	raise notice 'ALTRA QUOTA';
            	importo_imponibile_irpef = round(elencoMandati.IMPORTO_IMPONIBILE*percQuota/100,2);
        		importo_ritenuta_irpef = round(elencoMandati.IMPOSTA*percQuota/100,2);         		
                importo_netto_irpef=importo_lordo_mandato-importo_ritenuta_irpef;
                
                	-- sommo l'importo della quota corrente
                    -- al parziale per fattura.
                importoParzIrpefImpon=round(importoParzIrpefImpon+importo_imponibile_irpef,2);
                importoParzIrpefRiten=round(importoParzIrpefRiten+ importo_ritenuta_irpef,2);                
                importoParzIrpefNetto=round(importoParzIrpefNetto+importo_netto_irpef,2);
                raise notice 'Dopo altra quota - ParzImpon = %, ParzRiten = %, ParzNetto = %', importoParzIrpefImpon,importoParzIrpefRiten,importoParzIrpefNetto;    
            END IF;
        ELSE -- fattura diversa dalla precedente
        	raise notice 'Fattura diversa dalla prec: %, %',idFatturaOld,elencoMandati.doc_id;
            importo_imponibile_irpef = round(elencoMandati.IMPORTO_IMPONIBILE*percQuota/100,2);
        	importo_ritenuta_irpef = round(elencoMandati.IMPOSTA*percQuota/100,2);    
            importo_netto_irpef=importo_lordo_mandato-importo_ritenuta_irpef;

                -- imposto l'importo della quota corrente
                -- al parziale per fattura.            
            importoParzIrpefImpon=round(importo_imponibile_irpef,2);
        	importoParzIrpefRiten= round(importo_ritenuta_irpef,2);
       		importoParzIrpefNetto=round(importo_netto_irpef,2);
            
            raise notice 'Dopo prima quota - ParzImpon = %, ParzRiten = %, ParzNetto = %', importoParzIrpefImpon,importoParzIrpefRiten,importoParzIrpefNetto;    
            contaQuotaIrpef=1;            
        END IF;
                        
      raise notice 'IMPON =%, RITEN = %,  NETTO= %', importo_imponibile_irpef, importo_ritenuta_irpef,importo_netto_irpef; 
      idFatturaOld=elencoMandati.doc_id;
      
      -- Cerco le reversali del mandato per valorizzare il campo cod_risc
      -- non i numeri di reversali collegate.
      for elencoReversali in    
          select t_ordinativo.ord_numero
          from  siac_r_ordinativo r_ordinativo, siac_t_ordinativo t_ordinativo,
                siac_d_ordinativo_tipo d_ordinativo_tipo,
                siac_d_relaz_tipo d_relaz_tipo, siac_t_ordinativo_ts t_ord_ts,
                siac_t_ordinativo_ts_det t_ord_ts_det, siac_d_ordinativo_ts_det_tipo ts_det_tipo,
                siac_r_doc_onere_ordinativo_ts r_doc_onere_ord_ts,
                siac_r_doc_onere r_doc_onere, siac_d_onere d_onere,
                siac_d_onere_tipo  d_onere_tipo
                where t_ordinativo.ord_id=r_ordinativo.ord_id_a
                    AND d_ordinativo_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id
                    AND d_relaz_tipo.relaz_tipo_id=r_ordinativo.relaz_tipo_id
                    AND t_ord_ts.ord_id=t_ordinativo.ord_id
                    AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
                    AND ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
                    AND r_doc_onere_ord_ts.ord_ts_id=t_ord_ts_det.ord_ts_id
                    AND r_doc_onere.doc_onere_id=r_doc_onere_ord_ts.doc_onere_id
                    AND d_onere.onere_id=r_doc_onere.onere_id
                      AND d_onere_tipo.onere_tipo_id=d_onere.onere_tipo_id
                     AND d_ordinativo_tipo.ord_tipo_code ='I'
                     AND ts_det_tipo.ord_ts_det_tipo_code='A'
                        /* cerco tutte le tipologie di relazione,
                            non solo RIT_ORD */
                  /* ord_id_da contiene l'ID del mandato
                     ord_id_a contiene l'ID della reversale */
                AND r_ordinativo.ord_id_da = elencoMandati.ord_id
                AND d_relaz_tipo.data_cancellazione IS NULL
                AND t_ordinativo.data_cancellazione IS NULL
                AND r_ordinativo.data_cancellazione IS NULL
                AND r_ordinativo.data_cancellazione IS NULL
                AND t_ord_ts.data_cancellazione IS NULL
                AND t_ord_ts_det.data_cancellazione IS NULL
                AND ts_det_tipo.data_cancellazione IS NULL
                AND r_doc_onere_ord_ts.data_cancellazione IS NULL
                AND r_doc_onere.data_cancellazione IS NULL
                AND d_onere.data_cancellazione IS NULL
                AND d_onere_tipo.data_cancellazione IS NULL
          loop
          	if codice_risc = '' THEN
                codice_risc = elencoReversali.ord_numero ::VARCHAR;
            else
                codice_risc = codice_risc||', '||elencoReversali.ord_numero ::VARCHAR;
              end if;
          end loop;
      return next;
      
      raise notice '';
      
      nome_ente='';
      partita_iva_ente='';
      anno_ese_finanz=0;
      anno_mandato=0;
      numero_mandato=0;
      data_mandato=NULL;
      desc_mandato='';
      benef_cod_fiscale='';
      benef_partita_iva='';
      benef_nome='';
      stato_mandato='';
      codice_tributo_irpef='';
      codice_tributo_inps='';
      codice_risc='';
      importo_lordo_mandato=0;
      importo_netto_irpef=0;
      importo_imponibile_irpef=0;
      importo_ritenuta_irpef=0;
      importo_netto_inps=0;
      importo_imponibile_inps=0;
      importo_ritenuta_inps=0;
      importo_netto_irap=0;
      importo_imponibile_irap=0;
      importo_ritenuta_irap=0;
      tipo_ritenuta_inps='';
      tipo_ritenuta_irpef='';
      tipo_ritenuta_irap='';
      codice_ritenuta_irap='';
      desc_ritenuta_irap='';
      benef_codice='';
      importo_ente_irap=0;
      importo_ente_inps=0;

      tipo_ritenuta_irpeg='';
      codice_tributo_irpeg='';
      importo_ritenuta_irpeg=0;
      importo_netto_irpeg=0;
      importo_imponibile_irpeg=0;
      codice_ritenuta_irpeg='';
      desc_ritenuta_irpeg='';
      importo_ente_irpeg=0;
      code_caus_770:='';
      desc_caus_770:='';
      code_caus_esenz:='';
	  desc_caus_esenz:='';
      attivita_inizio:=NULL;
      attivita_fine:=NULL;
      attivita_code:='';
      attivita_desc:='';
      
   end loop;   
   
end if; -- FINE IF p_tipo_ritenuta

raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'fine estrazione dei dati e preparazione dati in output ';  

exception
	when no_data_found THEN
		raise notice 'nessun mandato trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;


-- SIAC-5190 - FINE - Maurizio