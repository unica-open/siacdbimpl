/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_cronoprogramma_spesa_entrata (
  cronoprogramma_id_in integer,
  anno_in varchar
)
RETURNS TABLE (
  anno_out varchar,
  totale_entrata numeric,
  totale_spesa numeric
) AS
$body$
DECLARE


RTN_MESSAGGIO varchar;

programma_id_in integer;
rec_impegni_anni record;
anno_v integer;

begin 
RTN_MESSAGGIO:='';
programma_id_in:=cronoprogramma_id_in;


for rec_impegni_anni in 
select distinct
mg.movgest_anno
from 
siac_t_programma p,
siac_r_movgest_ts_programma mp,
siac_t_movgest_ts mv,
--SIAC-6917
siac_d_movgest_ts_tipo tmv,
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
--SIAC-6917
and mv.movgest_ts_tipo_id = tmv.movgest_ts_tipo_id
and tmv.movgest_ts_tipo_code = 'T'
and mv.movgest_id=mg.movgest_id
and mg.movgest_tipo_id=ti.movgest_tipo_id
and ti.movgest_tipo_code='I'
and mvgd.movgest_ts_id=mv.movgest_ts_id
and bil.bil_id=mg.bil_id 
and pe.anno=anno_in
and rmob.movgest_id=mg.movgest_id
and pe.periodo_id=bil.periodo_id
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
order by 1

loop

anno_v:=rec_impegni_anni.movgest_anno;
anno_out:=anno_v::varchar;

--totale spesa
select sum(mvgd.movgest_ts_det_importo) into totale_spesa
from 
siac_t_programma p,
siac_r_movgest_ts_programma mp,
siac_t_movgest_ts mv,
--SIAC-6917
siac_d_movgest_ts_tipo tmv,
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
--SIAC-6917
and mv.movgest_ts_tipo_id = tmv.movgest_ts_tipo_id
and tmv.movgest_ts_tipo_code = 'T'
and mv.movgest_id=mg.movgest_id
and mg.movgest_tipo_id=ti.movgest_tipo_id
and ti.movgest_tipo_code='I'
and mvgd.movgest_ts_id=mv.movgest_ts_id
and bil.bil_id=mg.bil_id 
and rmob.movgest_id=mg.movgest_id
and pe.periodo_id=bil.periodo_id
and pe.anno=anno_in
and mvtipo.movgest_ts_det_tipo_id=mvgd.movgest_ts_det_tipo_id
and mvtipo.movgest_ts_det_tipo_code='A'
and rst.movgest_ts_id=mv.movgest_ts_id
and rst.movgest_stato_id=dst.movgest_stato_id
and dst.movgest_stato_code<>'A'
and mg.movgest_anno=anno_v
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
group by mg.movgest_anno;



select 
sum(rmo.movgest_ts_importo) into totale_entrata
from 
siac_t_programma p,
siac_r_movgest_ts_programma mp,
siac_t_movgest_ts mv,
--SIAC-6917
siac_d_movgest_ts_tipo tmv,
siac_t_movgest mg,
siac_d_movgest_tipo ti,
siac_t_movgest_ts_det mvgd,
siac_t_bil bil,
siac_d_movgest_ts_det_tipo mvtipo,
siac_r_movgest_bil_elem rmob,
siac_t_periodo pe,
siac_r_movgest_ts_stato rst,
siac_d_movgest_stato dst
,siac_r_movgest_ts rmo
 where
p.programma_id=programma_id_in
and p.programma_id=mp.programma_id
and mp.movgest_ts_id=mv.movgest_ts_id
--SIAC-6917
and mv.movgest_ts_tipo_id = tmv.movgest_ts_tipo_id
and tmv.movgest_ts_tipo_code = 'T'
and mv.movgest_id=mg.movgest_id
and mg.movgest_tipo_id=ti.movgest_tipo_id
and ti.movgest_tipo_code='I'
and mvgd.movgest_ts_id=mv.movgest_ts_id
and bil.bil_id=mg.bil_id 
and rmob.movgest_id=mg.movgest_id
and pe.periodo_id=bil.periodo_id
and pe.anno=anno_in
and mg.movgest_anno=anno_v
and mvtipo.movgest_ts_det_tipo_id=mvgd.movgest_ts_det_tipo_id
and mvtipo.movgest_ts_det_tipo_code='A'
and rst.movgest_ts_id=mv.movgest_ts_id
and rst.movgest_stato_id=dst.movgest_stato_id
and dst.movgest_stato_code<>'A'
and rmo.movgest_ts_b_id=mv.movgest_ts_id
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
and now() between rmo.validita_inizio and COALESCE(rmo.validita_fine,now())
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
and rmo.data_cancellazione is null
group by mg.movgest_anno;

return next;

end loop;



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