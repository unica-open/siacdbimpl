/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-8466 - Sofia - 10.11.2022
drop FUNCTION if exists siac.fnc_siac_programma_spesa_entrata(programma_id_in integer, anno_in varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_programma_spesa_entrata(programma_id_in integer, anno_in varchar)
 RETURNS TABLE(anno_out varchar, totale_entrata numeric, totale_spesa numeric)
as
$body$
DECLARE

rec_mov_anni record;

begin 
	
raise notice 'programma_id_in=%',programma_id_in::varchar;
raise notice 'anno_in=%',anno_in;

anno_out:=null;
totale_spesa:=0;
totale_entrata:=0;

for rec_mov_anni in 
select distinct mov.movgest_anno
from siac_r_movgest_ts_programma rp,
           siac_t_movgest_ts ts,
	       siac_d_movgest_ts_tipo ts_tipo,
	       siac_t_movgest mov,
		   siac_t_bil bil,siac_t_periodo per,
	       siac_r_movgest_ts_stato rs,
		   siac_d_movgest_stato stato
 where rp.programma_id=programma_id_in
 and     ts.movgest_ts_id =rp.movgest_ts_id 	
 and     ts_tipo.movgest_ts_tipo_id =ts.movgest_ts_tipo_id 
 and     ts_tipo.movgest_ts_tipo_code ='T'
 and     mov.movgest_id=ts.movgest_id
 and     bil.bil_id=mov.bil_id 
 and     per.periodo_id=bil.periodo_id 
 and     per.anno=anno_in
 and     rs.movgest_ts_id=ts.movgest_ts_id 
 and     stato.movgest_Stato_id =rs.movgest_Stato_id 
 and     stato.movgest_stato_code!='A'
 and     rp.data_cancellazione  is null 
 and     rp.validita_fine  is null 
 and     rs.data_cancellazione  is null 
 and     rs.validita_fine  is null 
 and     mov.data_cancellazione  is null 
 and     mov.validita_fine  is null 
 and     ts.data_cancellazione  is null 
 and     ts.validita_fine  is null 
 order by 1 
 
loop

anno_out:=null;
totale_spesa:=0;
totale_entrata:=0;
anno_out:=rec_mov_anni.movgest_anno;
raise notice 'anno_out=%',anno_out;

select coalesce(sum(det.movgest_ts_det_importo),0) into totale_spesa
from siac_r_movgest_ts_programma rp,
           siac_t_movgest_ts ts,
	       siac_d_movgest_ts_tipo ts_tipo,
	       siac_t_movgest mov,siac_d_movgest_tipo mov_tipo,
		   siac_t_bil bil,siac_t_periodo per,
	       siac_r_movgest_ts_stato rs,
		   siac_d_movgest_stato stato,
		   siac_t_movgest_ts_det det , 
		   siac_d_movgest_ts_det_tipo det_tipo 
 where rp.programma_id=programma_id_in
 and     ts.movgest_ts_id =rp.movgest_ts_id 	
 and     ts_tipo.movgest_ts_tipo_id =ts.movgest_ts_tipo_id 
 and     ts_tipo.movgest_ts_tipo_code ='T'
 and     mov.movgest_id=ts.movgest_id
 and     mov_tipo.movgest_tipo_id =mov.movgest_tipo_id 
 and     mov_tipo.movgest_tipo_code ='I'
 and     bil.bil_id=mov.bil_id 
 and     per.periodo_id=bil.periodo_id 
 and     per.anno=anno_in
 and     mov.movgest_anno::varchar=anno_out
 and     rs.movgest_ts_id=ts.movgest_ts_id 
 and     stato.movgest_Stato_id =rs.movgest_Stato_id 
 and     stato.movgest_stato_code!='A'
 and     det.movgest_ts_id=ts.movgest_ts_id 
 and     det_tipo.movgest_ts_det_tipo_id =det.movgest_ts_det_tipo_id 
 and     det_tipo.movgest_ts_det_tipo_code ='A'
 and     rp.data_cancellazione  is null 
 and     rp.validita_fine  is null 
 and     rs.data_cancellazione  is null 
 and     rs.validita_fine  is null 
 and     mov.data_cancellazione  is null 
 and     mov.validita_fine  is null 
 and     ts.data_cancellazione  is null 
 and     ts.validita_fine  is null 
 and     det.data_cancellazione  is null 
 and     det.validita_fine  is null;
raise notice 'totale_spesa=%',totale_spesa::varchar;

select coalesce(sum(det.movgest_ts_det_importo),0) into totale_entrata
from siac_r_movgest_ts_programma rp,
           siac_t_movgest_ts ts,
	       siac_d_movgest_ts_tipo ts_tipo,
	       siac_t_movgest mov,siac_d_movgest_tipo mov_tipo,
		   siac_t_bil bil,siac_t_periodo per,
	       siac_r_movgest_ts_stato rs,
		   siac_d_movgest_stato stato,
		   siac_t_movgest_ts_det det , 
		   siac_d_movgest_ts_det_tipo det_tipo 
 where rp.programma_id=programma_id_in
 and     ts.movgest_ts_id =rp.movgest_ts_id 	
 and     ts_tipo.movgest_ts_tipo_id =ts.movgest_ts_tipo_id 
 and     ts_tipo.movgest_ts_tipo_code ='T'
 and     mov.movgest_id=ts.movgest_id
 and     mov_tipo.movgest_tipo_id =mov.movgest_tipo_id 
 and     mov_tipo.movgest_tipo_code ='A'
 and     bil.bil_id=mov.bil_id 
 and     per.periodo_id=bil.periodo_id 
 and     per.anno=anno_in
 and     mov.movgest_anno::varchar=anno_out
 and     rs.movgest_ts_id=ts.movgest_ts_id 
 and     stato.movgest_Stato_id =rs.movgest_Stato_id 
 and     stato.movgest_stato_code!='A'
 and     det.movgest_ts_id=ts.movgest_ts_id 
 and     det_tipo.movgest_ts_det_tipo_id =det.movgest_ts_det_tipo_id 
 and     det_tipo.movgest_ts_det_tipo_code ='A'
 and     rp.data_cancellazione  is null 
 and     rp.validita_fine  is null 
 and     rs.data_cancellazione  is null 
 and     rs.validita_fine  is null 
 and     mov.data_cancellazione  is null 
 and     mov.validita_fine  is null 
 and     ts.data_cancellazione  is null 
 and     ts.validita_fine  is null 
 and     det.data_cancellazione  is null 
 and     det.validita_fine  is null;

raise notice 'totale_entrata=%',totale_entrata::varchar;


return next;

end loop;



exception
    when no_data_found THEN
        raise notice 'nessun valore trovato' ;
        return;
    when others  THEN
         RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,SQLERRM;
	return;
end;	
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


alter function siac.fnc_siac_programma_spesa_entrata(integer, varchar) owner to siac;