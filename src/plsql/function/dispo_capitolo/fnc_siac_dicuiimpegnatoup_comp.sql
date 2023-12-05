/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_siac_dicuiimpegnatoup_comp (
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
TIPO_CAP_UP constant varchar:='CAP-UP';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';

FASE_OP_BIL_PREV constant VARCHAR:='P';
PER_TIPO_CODE_SY constant VARCHAR:='SY';

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

bilancioId integer:=0;
bilIdElemGestEq integer:=0;
enteProprietarioId integer:=0;
elemIdGestEq integer:=0;

elemTipoCode VARCHAR(20):=NVL_STR;
annoBilancio varchar(4):=NVL_STR;
faseOpCode varchar(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;

BEGIN


 annoCompetenza:=null;
 diCuiImpegnato:=0;

 strMessaggio:='Calcolo impegnato competenza UP elem_id='||id_in||'.';

 begin
    strMessaggio:='Calcolo impegnato competenza UP.Calcolo bilancioId e elem_tipo_code per elem_id='||id_in||'.';
	select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
           into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio, enteProprietarioId
    from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem,
         siac_t_bil bil, siac_t_periodo per
    where bilElem.elem_id=id_in
      and bilElem.data_cancellazione is null
      and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
      and tipoBilElem.ente_proprietario_id=bilElem.ente_proprietario_id
      and bil.bil_id=bilElem.bil_id
      and per.periodo_id=bil.periodo_id
      and per.ente_proprietario_id=bil.ente_proprietario_id;

    if coalesce(elemTipoCode,NVL_STR)!=TIPO_CAP_UP then
        RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
    end if;

    exception
		when no_data_found then
	    	RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        when too_many_rows then
            RAISE EXCEPTION '% Piu'' record presenti in archivio.',strMessaggio;
        when others  THEN
	        RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);
 end;

 strMessaggio:='Calcolo impegnato competenza UP.Calcolo fase operativa per bilancioId='||bilancioId
               ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

 select  faseOp.fase_operativa_code into  faseOpCode
 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
 where bilFase.bil_id =bilancioId
   and bilfase.data_cancellazione is null
   and bilFase.validita_fine is null
   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
   and faseOp.ente_proprietario_id=bilFase.ente_proprietario_id
   and faseOp.data_cancellazione is null
 order by bilFase.bil_fase_operativa_id desc;

 if NOT FOUND THEN
   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
 end if;


 strMessaggio:='Calcolo impegnato competenza UP.Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
              ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
 -- lettura elemento bil di gestione equivalente
 if coalesce(faseOpCode,NVL_STR)!=NVL_STR then
  	if  faseOpCode = FASE_OP_BIL_PREV then
      	-- lettura bilancioId annoBilancio precedente per lettura elemento di bilancio equivalente
            begin
            	select bil.bil_id into strict bilIdElemGestEq
                from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
                where per.anno=ltrim(rtrim(to_char((annoBilancio::numeric)-1,'9999')))
                  and per.ente_proprietario_id=enteProprietarioId
                  and bil.periodo_id=per.periodo_id
                  and perTipo.periodo_tipo_id=per.periodo_tipo_id
                  and perTipo.periodo_tipo_code=PER_TIPO_CODE_SY
	              and perTipo.ente_proprietario_id=per.ente_proprietario_id;

                exception
					when no_data_found then
				    	RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
			        when too_many_rows then
			            RAISE EXCEPTION '% Piu'' record presenti in archivio.',strMessaggio;
			        when others  THEN
	        			RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);
            end;
      else
        	bilIdElemGestEq:=bilancioId;
      end if;
 else
	 RAISE EXCEPTION '% Fase non valida.',strMessaggio;
 end if;

 -- lettura elemIdGestEq
 begin
    strMessaggio:='Calcolo impegnato competenza UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
              ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

 	select bilelem.elem_id into strict elemIdGestEq
    from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
    where bilElem.elem_code=elemCode
      and bilElem.elem_code2=elemCode2
      and bilElem.elem_code3=elemCode3
      and bilElem.ente_proprietario_id=enteProprietarioId
      and bilElem.data_cancellazione is null
      and bilElem.bil_id=bilIdElemGestEq
      and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
      and bilElemTipo.ente_proprietario_id=bilElem.ente_proprietario_id
      and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

     exception
	 	when no_data_found then
			RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
		when too_many_rows then
		    RAISE EXCEPTION '% Piu'' record presenti in archivio.',strMessaggio;
	    when others  THEN
	 		RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);
 end;

if coalesce(anno_in,NVL_STR)!=NVL_STR then
	annoMovimento1:=anno_in;
    annoMovimento3:=anno_in;
    strMessaggio:='Calcolo impegnato competenza UP elem_id='||elemIdGestEq||'.Anno='||anno_in||'.';
ELSE
     strMessaggio:='Calcolo impegnato competenza UP elem_id='||elemIdGestEq||'.Calcolo su triennale.';
	 annoMovimento1:=annoBilancio;
     annoMovimento3:=to_char((annoMovimento1::numeric)+2,'9999');

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
 where  bilElem.elem_id = elemIdGestEq and
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