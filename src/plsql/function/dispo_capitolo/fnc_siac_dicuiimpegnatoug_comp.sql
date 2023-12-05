/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_siac_dicuiimpegnatoug_comp (
  id_in integer,
  anno_in varchar default null
)
RETURNS table
(
	annoCompetenza varchar,
    diCuiImpegnato numeric
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

annoMovimento1 varchar(10):=NVL_STR;
annoMovimento3 varchar(10):=NVL_STR;

strMessaggio varchar(1500):=NVL_STR;

totImpegnato numeric:=0;
movGestRec record;

BEGIN


annoCompetenza:=null;
diCuiImpegnato:=0;

strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.';

if coalesce(anno_in,NVL_STR)!=NVL_STR then
	annoMovimento1:=anno_in;
    annoMovimento3:=anno_in;
    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.Anno='||anno_in||'.';
ELSE
	begin
     strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.Calcolo anni triennale.';

     select per.anno  into strict annoMovimento1
     from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem,
          siac_t_bil bil, siac_t_periodo per
        where bilElem.elem_id=id_in and
              bilElem.data_cancellazione is null AND
              tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id and
              tipoBilElem.elem_tipo_code = TIPO_CAP_UG and
              tipoBilElem.ente_proprietario_id=bilElem.ente_proprietario_id and
              bil.bil_id=bilElem.bil_id and
              per.periodo_id=bil.periodo_id;


     annoMovimento3:=to_char((annoMovimento1::numeric)+2,'9999');

     exception
		 	when no_data_found then
			  RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        	when others  THEN
	          RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);
    end;
end if;


for movGestRec in
 select movGest.movgest_anno annoMovimento,
 		coalesce(sum (movGestTsDet.movgest_ts_det_importo),0) importoAttuale
 from siac_t_bil_elem bilElem ,
      siac_d_bil_elem_tipo bilElemTipo,
      siac_r_movgest_bil_elem movGestRel,
	  siac_t_movgest movGest,
	  siac_d_movgest_tipo tipoMovGest,
	  siac_t_movgest_ts movGestTs,
      siac_d_movgest_ts_tipo movGestTsTipo,
	  siac_r_movgest_ts_stato movGestTsRel,
	  siac_d_movgest_stato movGestStato,
	  siac_t_movgest_ts_det movGestTsDet,
	  siac_d_movgest_ts_det_tipo movGestTsDetTipo
 where  bilElem.elem_id = id_in and
	    bilElem.data_cancellazione is null and
        bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id and
        bilElemTipo.ente_proprietario_id=bilElem.ente_proprietario_id and
        bilElemTipo.elem_tipo_code=TIPO_CAP_UG and
        movGestRel.elem_id = bilElem.elem_id and
	    movGestRel.ente_proprietario_id=bilElem.ente_proprietario_id and
        movGestRel.data_cancellazione is null and
		movGest.movgest_id=movGestRel.movgest_id  and
	    movGest.bil_id = bilElem.bil_id and
        tipoMovGest.movgest_tipo_id=movGest.movgest_tipo_id and
        tipoMovGest.ente_proprietario_id=movGest.ente_proprietario_id and
        tipoMovGest.movgest_tipo_code=TIPO_IMP and
		movGest.movgest_anno >= annoMovimento1::INTEGER and
        movGest.movgest_anno <= annoMovimento3::INTEGER and
		movGestTs.movgest_id = movGest.movgest_id and
        movGestTs.data_cancellazione is null and
        movGestTsTipo.movgest_ts_tipo_id=movGestTs.movgest_ts_tipo_id and
        movGestTsTipo.ente_proprietario_id=movGestTs.ente_proprietario_id and
        movGestTsTipo.movgest_ts_tipo_code=TIPO_IMP_T and
        movGestTsRel.movgest_ts_id=movGestTs.movgest_ts_id and
        movGestTsRel.ente_proprietario_id=movGestTs.ente_proprietario_id and
        movGestTsRel.data_cancellazione is null and
        movGestStato.movgest_stato_id=movGestTsRel.movgest_stato_id and
        movGestStato.ente_proprietario_id=movGestTs.ente_proprietario_id and
        movGestStato.movgest_stato_code!= STATO_A and
        movGestTsDet.movgest_ts_id=movGestTs.movgest_ts_id and
        movGestTsDetTipo.movgest_ts_det_tipo_id=movGestTsDet.movgest_ts_det_tipo_id and
        movGestTsDetTipo.ente_proprietario_id=movGestTs.ente_proprietario_id and
        movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT
 group by movGest.movgest_anno
loop

	annoCompetenza:=movGestRec.annoMovimento::varchar;
	diCuiImpegnato:=movGestRec.importoAttuale;

    totImpegnato:=totImpegnato+movGestRec.importoAttuale;

	return next;
end loop;

if totImpegnato!=0 THEN
	return;
else
    return next;
end if;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
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
COST 100;