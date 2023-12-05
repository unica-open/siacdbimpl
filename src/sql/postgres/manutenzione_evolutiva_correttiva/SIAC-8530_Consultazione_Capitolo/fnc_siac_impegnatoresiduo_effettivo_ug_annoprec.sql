/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/*Residui effettivi iniziali-attuali annoBilancio-1, considerare elemId del capitolo collegato attraverso siac_r_bil_elem_rel_tempo se non esiste collegamento su siac_r_bil_elem_rel_tempo
per elemId del capitolo di gestione di annoBilancio-1 equivalente ( elem_code,elem_code2,elem_code3 uguali a quello del capitolo in gestione in input)
Calcolo del Totale impegnato residuo=siac_r_movgest_bil_elem.elem_id=elemId
¿ siac_t_movgest_ts_det.movgest_ts_importo
per impegni non annullati con
movgest_tipo_code='I'
movgest_ts_tipo_code='T'
movgest_anno<annoBilancio-1
movgest_ts_det_tipo_code='I'
annoBilancio=annoBilancio-1 in consultazione*/

drop function if exists siac.fnc_siac_impegnatoresiduo_effettivo_ug_annoprec ( id_in integer, tipo_importo_in varchar );
CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatoresiduo_effettivo_ug_annoprec ( id_in integer, tipo_importo_in varchar )
RETURNS numeric  AS
$body$
DECLARE


annoBilancio varchar:=null;
annoBilancioPrec varchar:=null;



NVL_STR     constant varchar:='';
bilancioId integer:=0;
bilancioPrecId integer:=0;

elemTipoCode VARCHAR(20):=NVL_STR;

enteProprietarioId INTEGER:=0;

TIPO_CAP_UG constant varchar:='CAP-UG';

elemPrecId integer:=null;

elemCode varchar(100):=null;
elemCode2 varchar(100):=null;
elemCode3 varchar(100):=null;

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

    strMessaggio:='Calcolo totale impegnato residuo effettivo anno prec. elem_id='||id_in|| '.';

	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;
 
    if coalesce(tipo_importo_in,NVL_STR)=NVL_STR or
       coalesce(tipo_importo_in,NVL_STR) not in (IMPORTO_ATT,IMPORTO_INIZIALE) then 
       RAISE EXCEPTION '% Parametro tipo importo non presente o non valido.',strMessaggio;
    end if;

	strMessaggio:='Calcolo totale impegnato residuo effettivo anno prec. elem_id='||id_in||
    			  '. Lettura informazioni elemento di bilancio.' || 
				   '. Calcolo annoBilancio, bilancioId e elem_tipo_code.';
	select  bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id,
	        bilElem.elem_code, bilelem.elem_code2,bilElem.elem_code3
	into   bilancioId, elemTipoCode , annoBilancio,enteProprietarioId, elemCode, elemCode2,elemCode3
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
		 --RAISE EXCEPTION '% Anno bilancio non reperito.',strMessaggio;
		 RAISE notice '% Anno bilancio non reperito.',strMessaggio;
		 importoImpegnato:=0;
	     return importoImpegnato;
	   
	 end if;

	 if enteProprietarioId is null then
		 --RAISE EXCEPTION '% enteProprietarioId non reperito.',strMessaggio;
		 RAISE notice '% enteProprietarioId non reperito.',strMessaggio;
		 importoImpegnato:=0;
	     return importoImpegnato;
	 end if;
	
	 if elemTipoCode is null then
		 --RAISE EXCEPTION '% elemTipoCode non reperito.',strMessaggio;
		 RAISE notice '% elemTipoCode non reperito.',strMessaggio;
		 importoImpegnato:=0;
	     return importoImpegnato;		 
	 end if;
	
	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UG then
			--RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
			RAISE notice '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
		    importoImpegnato:=0;
	        return importoImpegnato;		 			
	 end if;

	 if elemCode is null or elemCode2 is null or elemCode3 is null then 
		 --RAISE EXCEPTION '% chiave logica elemento bilancio non reperita.',strMessaggio;
		 RAISE notice '% chiave logica elemento bilancio non reperita.',strMessaggio;
		 importoImpegnato:=0;
	     return importoImpegnato;		 					 
	 end if;

 	 strMessaggio:='Calcolo totale impegnato residuo effettivo anno prec. elem_id='||id_in||
    			  '. Lettura informazioni elemento di bilancio anno prec.';	
	 select rel.elem_id_old into elemPrecId
	 from siac_r_bil_elem_rel_tempo rel 
	 where rel.ente_proprietario_id=enteProprietarioId
	 and   rel.elem_id=id_in
	 and   rel.data_cancellazione is null 
	 and   rel.validita_fine is null;
	 raise notice 'elemPrecId=%',elemPrecId;
	
     if elemPrecId is null then
  	    strMessaggio:='Calcolo totale impegnato residuo effettivo anno prec. elem_id='||id_in||
    			      '. Lettura informazioni elemento di bilancio anno prec in anno prec - equivalente .';	
 		select  bil.bil_id , per.anno ,bilElem.elem_id
		into    bilancioPrecId, annoBilancioPrec,elemPrecId
		from 	siac_t_bil_elem bilElem, 
	 		siac_d_bil_elem_tipo tipoBilElem,
		  	siac_t_bil bil, siac_t_periodo per
		where bilElem.ente_proprietario_id=enteProprietarioId
		and   tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id 
		and   tipoBilElem.elem_tipo_code=TIPO_CAP_UG
		and   bilElem.elem_code=elemCode
		and   bilElem.elem_code2=elemCode2
		and   bilElem.elem_code3=elemCode3
		and   bil.bil_id=bilElem.bil_id 
		and   per.periodo_id=bil.periodo_id
		and   per.anno::integer=(annoBilancio::integer)-1
	    and   bilElem.data_cancellazione is null
		and   bilElem.validita_fine is null;
	 else
	    strMessaggio:='Calcolo totale impegnato residuo effettivo anno prec. elem_id='||id_in||
    			      '. Lettura informazioni elemento di bilancio anno prec in anno prec - rel_tempo .';	
	    select  bil.bil_id , per.anno
		into    bilancioPrecId, annoBilancioPrec
		from 	siac_t_bil_elem bilElem, 
  		 		siac_d_bil_elem_tipo tipoBilElem,
			  	siac_t_bil bil, siac_t_periodo per
		where bilElem.ente_proprietario_id=enteProprietarioId
		and   bilElem.elem_id=elemPrecId
		and   tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id 
		and   tipoBilElem.elem_tipo_code=TIPO_CAP_UG
		and   bil.bil_id=bilElem.bil_id 
		and   per.periodo_id=bil.periodo_id
		and   per.anno::integer=(annoBilancio::integer)-1
	    and   bilElem.data_cancellazione is null
		and   bilElem.validita_fine is null;
     end if;
	 
    
     if elemPrecId is null then 
     	RAISE NOTICE '%  Identificativo elemento bilancio anno prec non reperita.',strMessaggio; 
	    importoImpegnato:=0;
	    return importoImpegnato;
	   
     end if;

     if bilancioPrecId is null or annoBilancioPrec is null then 
     	--RAISE EXCEPTION '%  Informazioni elemento bilancio anno prec non reperite.',strMessaggio; 
        RAISE notice '%  Informazioni elemento bilancio anno prec non reperite.',strMessaggio; 
		importoImpegnato:=0;
	    return importoImpegnato;		 					 		
     end if;
    
  	 strMessaggio:='Calcolo totale impegnato residuo effettivo anno prec. elem_id='||id_in
				  ||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;
 
	 if movGestTipoId is null then
	   --RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	   RAISE notice '% Dato non reperito.',strMessaggio;
	   importoImpegnato:=0;
	   return importoImpegnato;		 					 			   
	  end if;
		
     strMessaggio:='Calcolo totale impegnato residuo effettivo anno prec. elem_id='||id_in
				  ||'. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO.';

	 select movGestStato.movgest_stato_id into movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;
	
	 if movGestStatoIdAnnullato is null then
	   --RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	   RAISE notice '% Dato non reperito.',strMessaggio;
	   importoImpegnato:=0;
	   return importoImpegnato;		 					 			   			   
	 end if;

	
     strMessaggio:='Calcolo totale impegnato residuo effettivo anno prec. elem_id='||id_in
				  ||'. Calcolo movGestTsDetTipoAttualeId per movgest_ts_det_tipo_code=IMPORTO ATTUALE.';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into movGestTsDetTipoAttualeId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

	 if movGestTsDetTipoAttualeId is null then
	 		   --RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
			   RAISE notice '% Dato non reperito.',strMessaggio;
	           importoImpegnato:=0;
	           return importoImpegnato;		 					 			   			   
	 end if;

	
     strMessaggio:='Calcolo totale impegnato residuo effettivo anno prec. elem_id='||id_in
				  ||'. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE.';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into  movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE;

	 if movGestTsDetTipoIdIniziale is null then
	 		   --RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	   RAISE notice '% Dato non reperito.',strMessaggio;
	   importoImpegnato:=0;
	   return importoImpegnato;		 					 			   			   			   
	 end if;

	
 	
	 if tipo_importo_in = IMPORTO_INIZIALE then 
  	    strMessaggio:='Calcolo totale impegnato residuo effettivo anno prec. elem_id='||id_in
 						||'.Inizio calcolo totale importo iniziale  impegni residui per anno esercizio ='||annoBilancioPrec||'.';
	    movGestTsDetTipoId:=movGestTsDetTipoIdIniziale;
					
    else 
  	    strMessaggio:='Calcolo totale impegnato residuo effettivo anno prec. elem_id='||id_in
						||'.Inizio calcolo totale importo attuale   impegni residui per anno esercizio ='||annoBilancioPrec||'.';

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
	  where re.elem_id=elemPrecId
	  and   mov.movgest_id=re.movgest_id 
	  and   mov.bil_id=bilancioPrecId
	  and   mov.movgest_tipo_Id=movGestTipoId
	  and   mov.movgest_anno<annoBilancioPrec::integer
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



ALTER FUNCTION siac.fnc_siac_impegnatoresiduo_effettivo_ug_annoprec ( id_in integer, tipo_importo_in varchar ) OWNER TO siac;
 
