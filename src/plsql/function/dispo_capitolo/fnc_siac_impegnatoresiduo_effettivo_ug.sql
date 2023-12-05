/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop function if exists siac.fnc_siac_impegnatoresiduo_effettivo_ug ( id_in integer, tipo_importo_in varchar );
CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatoresiduo_effettivo_ug ( id_in integer, tipo_importo_in varchar )
RETURNS numeric  AS
$body$
DECLARE


annoBilancio varchar:=null;
annoEsercizio varchar:=null;
annoMovimento varchar:=null;

NVL_STR     constant varchar:='';
faseOpCode varchar(20):=NVL_STR;
bilancioId integer:=0;

elemTipoCode VARCHAR(20):=NVL_STR;

enteProprietarioId INTEGER:=0;

TIPO_CAP_UG constant varchar:='CAP-UG';


FASE_OP_BIL_PREV constant VARCHAR:='P';

STATO_A     constant varchar:='A';
TIPO_IMP    constant varchar:='I';

movGestStatoIdAnnullato integer:=0;
movGestTipoId integer:=0;

movGestTsDetTipoAttualeId integer:=0;
movGestTsDetTipoId integer:=0;

movGestTsDetTipoIdIniziale integer:=0;

IMPORTO_ATT constant varchar:='A';
IMPORTO_INIZIALE constant varchar:='I';

importoImpegnato numeric:=0;


strMessaggio varchar(1500):=null;
BEGIN

    strMessaggio:='Calcolo totale impegnato residuo definitvo elem_id='||id_in|| '.';

	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;
 
    if coalesce(tipo_importo_in,NVL_STR)=NVL_STR or
       coalesce(tipo_importo_in,NVL_STR) not in (IMPORTO_ATT,IMPORTO_INIZIALE) then 
       RAISE EXCEPTION '% Parametro tipo importo non presente o non valido.',strMessaggio;
    end if;

	strMessaggio:='Calcolo totale impegnato residuo definitvo elem_id='||id_in||
    			  '. Lettura informazioni elemento di bilancio passato.' || 
				   '. Calcolo annoBilancio, bilancioId e elem_tipo_code.';
	 select  bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
	 into   bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
	 from 	siac_t_bil_elem bilElem, 
	 		siac_d_bil_elem_tipo tipoBilElem,
		  	siac_t_bil bil, siac_t_periodo per
	 where bilElem.elem_id=id_in
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
	   and bil.bil_id=bilElem.bil_id
	   and per.periodo_id=bil.periodo_id;
     
	 if annoBilancio is null then
		 RAISE EXCEPTION '% Anno bilancio non reperito.',strMessaggio;
	 end if;

	 if enteProprietarioId is null then
		 RAISE EXCEPTION '% enteProprietarioId non reperito.',strMessaggio;
	 end if;
	
	 if elemTipoCode is null then
		 RAISE EXCEPTION '% elemTipoCode non reperito.',strMessaggio;
	 end if;
	
	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UG then
			RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
	 end if;

	 strMessaggio:='Calcolo totale impegnato residuo definitvo elem_id='||id_in||
				   'Calcolo fase operativa per bilancioId='||bilancioId
				   ||' per ente='||enteProprietarioId||'.';

	 select  faseOp.fase_operativa_code into  faseOpCode
	 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
	 where bilFase.bil_id =bilancioId
	   and bilfase.data_cancellazione is null
	   and bilFase.validita_fine is null
	   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
	   and faseOp.data_cancellazione is null
	 order by bilFase.bil_fase_operativa_id desc;

	 if NOT FOUND or faseOpCode is null THEN
	   RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	 end if;

	 strMessaggio:='Calcolo impegnato residuo definitivo elem_id='||id_in
				  ||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;
 
	 if movGestTipoId is null then
	   RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	  end if;
		
	 strMessaggio:='Calcolo impegnato residuo definitivo elem_id='||id_in
				  ||'. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO.';

	 select movGestStato.movgest_stato_id into movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;
	
	 if movGestStatoIdAnnullato is null then
	 		   RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	 end if;

	
	 strMessaggio:='Calcolo impegnato residuo definitivo elem_id='||id_in
				  ||'. Calcolo movGestTsDetTipoAttualeId per movgest_ts_det_tipo_code=IMPORTO ATTUALE.';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into movGestTsDetTipoAttualeId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

	 if movGestTsDetTipoAttualeId is null then
	 		   RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	 end if;

	
	 strMessaggio:='Calcolo impegnato residuo definitivo elem_id='||id_in
				  ||'. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE.';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into  movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE;

	 if movGestTsDetTipoIdIniziale is null then
	 		   RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	 end if;

	
	 annoEsercizio:=annoBilancio;
	 annoMovimento:=annoBilancio;
		
 	
	 if tipo_importo_in = IMPORTO_INIZIALE then 
	    strMessaggio:='Calcolo impegnato residuo definitivo elem_id='||id_in
 						||'.Inizio calcolo totale importo iniziale   impegni residui per anno esercizio ='||annoEsercizio||
						' anno movimento ='||annoMovimento||'.';
	    movGestTsDetTipoId:=movGestTsDetTipoIdIniziale;
					
    else 
		 strMessaggio:='Calcolo impegnato residuo definitivo elem_id='||id_in
						||'.Inizio calcolo totale importo attuale   impegni residui per anno esercizio ='||annoEsercizio||
						' anno movimento ='||annoMovimento||'.';

   	    movGestTsDetTipoId:=movGestTsDetTipoAttualeId;
    end if;
   
	importoImpegnato:=0;			
	select tb.importo into importoImpegnato
	from 
	(
	  select coalesce(sum(det.movgest_ts_det_importo),0) importo, ts.movgest_ts_tipo_id
	  from  siac_r_movgest_bil_elem re,
		    siac_t_movgest mov,
		    siac_t_movgest_ts ts,
		    siac_r_movgest_ts_stato rs,
		    siac_t_movgest_ts_det det
	  where re.elem_id=id_in
	  and   mov.movgest_id=re.movgest_id 
	  and   mov.bil_id=bilancioId
	  and   mov.movgest_tipo_Id=movGestTipoId
	  and   mov.movgest_anno<annoMovimento::integer
	  and   ts.movgest_id=mov.movgest_id 
	  and   rs.movgest_ts_id=ts.movgest_ts_id 
	  and   rs.movgest_stato_id!=movGestStatoIdAnnullato
	  and   det.movgest_ts_id=ts.movgest_ts_id 
	  and   det.movgest_ts_det_tipo_id=movGestTsDetTipoId
      and   re.data_cancellazione is null 
      and   re.validita_fine is null 
      and   mov.data_cancellazione is null 
      and   ts.data_cancellazione is null 
      and   rs.data_cancellazione is null 
      and   rs.validita_fine is null
      group by ts.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo tipo
	where tb.movgest_ts_tipo_id=tipo.movgest_ts_tipo_id
	order by tipo.movgest_ts_tipo_code desc
	limit 1;		
	if importoImpegnato is null then importoImpegnato:=0; end if;

	raise notice 'importoImpegnato=%',importoImpegnato;
	return importoImpegnato;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
		return importoImpegnato;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
		return importoImpegnato;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
		return importoImpegnato;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;



ALTER FUNCTION siac.fnc_siac_impegnatoresiduo_effettivo_ug (id_in integer, tipo_importo_in varchar ) OWNER TO siac;
 
