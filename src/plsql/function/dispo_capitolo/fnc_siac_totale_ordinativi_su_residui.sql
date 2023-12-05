/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_totale_ordinativi_su_residui (
  id_in integer,
  tipo_ord_in varchar
)
RETURNS numeric AS
$body$
DECLARE

-- constant
/*TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_EG constant varchar:='CAP-EG';*/
NVL_STR     constant varchar:='';

TIPO_ORD_P constant varchar:='P';
TIPO_ORD_I constant varchar:='I';

STATO_A     constant varchar:='A';
IMPORTO_ATT constant varchar:='A';

tipoCapitolo varchar(10):=null;
strMessaggio varchar(1500):=NVL_STR;
totOrdinativi numeric:=0;

ordTipoId integer:=0;
enteProprietarioId integer :=0;
ordTsDetTipoId integer:=0;
ordStatoId integer:=0;
bilancioId integer:=0;
ordTsId integer:=0;

ordRecId record;
curImportoOrd numeric:=0;

BEGIN

 strMessaggio:='Calcolo totale ordinativi su residui per elem_id='||id_in||'.';

 curImportoOrd :=0;
   
   select coalesce(sum(d.ord_ts_det_importo),0)  into curImportoOrd
   from 
	siac_r_ordinativo_bil_elem a, siac_t_ordinativo b, siac_t_ordinativo_ts c,
	siac_t_ordinativo_ts_det d,siac_r_ordinativo_stato e,siac_d_ordinativo_stato f
	, siac_d_ordinativo_tipo g,
	siac_d_ordinativo_ts_det_tipo h
	where a.ord_id=b.ord_id
	and c.ord_id=b.ord_id
	and d.ord_ts_id=c.ord_ts_id
	and e.ord_id=b.ord_id
	and e.ord_stato_id=f.ord_stato_id
	and f.ord_stato_code<>STATO_A
	and g.ord_tipo_id=b.ord_tipo_id
	and g.ord_tipo_code=tipo_ord_in
	and a.elem_id=id_in
	and h.ord_ts_det_tipo_id=d.ord_ts_det_tipo_id
	and h.ord_ts_det_tipo_code=IMPORTO_ATT
	and   now() between a.validita_inizio and COALESCE(a.validita_fine,now())
	and   now() between e.validita_inizio and COALESCE(e.validita_fine,now())
	and a.data_cancellazione is null
	and b.data_cancellazione is null
	and c.data_cancellazione is null
	and d.data_cancellazione is null
	and e.data_cancellazione is null
	and f.data_cancellazione is null
	and g.data_cancellazione is null
	and h.data_cancellazione is null
	and (exists (
		select 1 from siac_r_liquidazione_ord srlo,
		siac_r_liquidazione_movgest srlm,
		siac_t_movgest_ts stmt, siac_t_movgest stm, siac_t_bil stb, siac_t_periodo stp 
		where srlm.liq_id  = srlo.liq_id 
		and stmt.movgest_ts_id  = srlm.movgest_ts_id 
		and stm.movgest_id  = stmt.movgest_id 
		and srlo.sord_id  = c.ord_ts_id
		and stb.bil_id = stm.bil_id
		and stb.periodo_id  = stp.periodo_id 
		and   now() between stm.validita_inizio and COALESCE(stm.validita_fine,now())
		and   now() between stmt.validita_inizio and COALESCE(stmt.validita_fine,now())
		and   now() between srlo.validita_inizio and COALESCE(srlo.validita_fine,now())
		and   now() between srlm.validita_inizio and COALESCE(srlm.validita_fine,now())
		and srlm.data_cancellazione  is null 
		and srlo.data_cancellazione  is null
		and stm.data_cancellazione  is null 
		and stmt.data_cancellazione  is null
		and stm.movgest_anno::integer < stp.anno::integer
	) or exists (
		select 1 from siac_r_ordinativo_ts_movgest_ts srotmt,
		siac_t_movgest_ts stmt, siac_t_movgest stm, siac_t_bil stb, siac_t_periodo stp 
		where stmt.movgest_ts_id  = srotmt.movgest_ts_id 
		and stm.movgest_id  = stmt.movgest_id 
		and srotmt.ord_ts_id  = c.ord_ts_id
		and stb.bil_id = stm.bil_id
		and stb.periodo_id  = stp.periodo_id 
		and   now() between stm.validita_inizio and COALESCE(stm.validita_fine,now())
		and   now() between stmt.validita_inizio and COALESCE(stmt.validita_fine,now())
		and   now() between srotmt.validita_inizio and COALESCE(srotmt.validita_fine,now())
		and srotmt.data_cancellazione  is null 
		and stm.data_cancellazione  is null 
		and stmt.data_cancellazione  is null
		and stm.movgest_anno::integer < stp.anno::integer
		)
	
	);



   totOrdinativi:=totOrdinativi+curImportoOrd;


 return totOrdinativi;


exception
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        totOrdinativi:=0;
        return totOrdinativi;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        totOrdinativi:=0;
        return totOrdinativi;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

