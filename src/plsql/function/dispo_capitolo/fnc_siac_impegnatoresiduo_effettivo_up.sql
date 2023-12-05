/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop function if exists siac.fnc_siac_impegnatoresiduo_effettivo_up( id_in integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatoresiduo_effettivo_up
(
  id_in integer
)
RETURNS NUMERIC
AS
$body$
DECLARE

annoBilancio varchar:=null;
annoEsercizio varchar:=null;
annoMovimento varchar:=null;

elemIdGestEq integer:=null;
bilIdElemGestEq integer:=0;
elemIdRelTempo integer:=null;
NVL_STR     constant varchar:='';
faseOpCode varchar(20):=NVL_STR;
bilancioId integer:=0;
elemTipoCode VARCHAR(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;
enteProprietarioId INTEGER:=0;

TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';

FASE_OP_BIL_PREV constant VARCHAR:='P';

STATO_A     constant varchar:='A';

TIPO_IMP    constant varchar:='I';

movGestStatoIdAnnullato integer:=0;
movGestTipoId integer:=0;

IMPORTO_ATT constant varchar:='A';
movGestTsDetTipoId integer:=0;
IMPORTO_INIZIALE constant varchar:='I';
movGestTsDetTipoIdIniziale integer:=0;



--pluriennalidaribaltamento integer:=0;
impegniDaRibaltamento integer:=0;

flagDeltaPagamenti boolean:=false;
importoImpegnato numeric:=0;
impegnatoDefinitivo numeric:=0;
importoPagatoDelta numeric:=0;

ordStatoAId          integer:=null;
ordTsDetTipoAId      integer:=null;

-- stati ordinativi
STATO_ORD_A    constant varchar:='A'; -- ANNULLATO
-- importoAttuale ordinativi
ORD_TS_DET_TIPO_A  constant varchar:='A';

strMessaggio varchar(1500):=null;
BEGIN

    strMessaggio:='Calcolo totale impegnato residuo effettivo elem_id='||id_in|| '.';

	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;
 
	strMessaggio:='Calcolo totale impegnato residuo effettivo elem_id='||id_in||
    			  '.Lettura anno di bilancio del capitolo UP.';

	select per.anno into  annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil,siac_t_periodo per 
	where bilElem.elem_id=id_in 
	AND   bil.bil_id=bilElem.bil_id
	and   per.periodo_id=bil.periodo_id
	AND   bilElem.data_cancellazione is null 
	and   bilElem.validita_fine is null;
	if annoBilancio is null then 
		RAISE EXCEPTION '%. Dato non trovato.',strMessaggio;
	end if;

		  

	strMessaggio:='Calcolo totale impegnato residuo effettivo elem_id='||id_in||
    			  '. Determina estremi capitolo - bilancioId e elem_tipo_code.';
    select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
	into  elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
	from  siac_t_bil_elem bilElem, 
	      siac_d_bil_elem_tipo tipoBilElem,
		  siac_t_bil bil, siac_t_periodo per
	 where bilElem.elem_id=id_in
 	   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
 	   and bil.bil_id=bilElem.bil_id
	   and per.periodo_id=bil.periodo_id
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null;
     
	 if annoBilancio is null or enteProprietarioId is null or bilancioId  is null 
	    or elemCode is null or elemCode2 is null or elemTipoCode is null then 
		RAISE EXCEPTION '%. Dati non reperiti.',strMessaggio;
	 end if; 
	  	
	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UP then
			RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
	 end if;


	 strMessaggio:='Calcolo totale impegnato residuo effettivo elem_id='||id_in||
		 	       '.Lettura fase operativa per bilancioId='||bilancioId
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

	 strMessaggio:='Calcolo impegnato residuo effettivo elem_id='||id_in
				  ||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;
	 
	 if movGestTipoId is null then 
	 	RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	 end if;
	
	 strMessaggio:='Calcolo impegnato residuo effettivo elem_id='||id_in
				  ||'. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO.';

	 select movGestStato.movgest_stato_id into  movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;

	 
 	 if movGestStatoIdAnnullato is null then 
		RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	 end if;
	
	 strMessaggio:='Calcolo impegnato residuo effettivo elem_id='||id_in
				  ||'. Calcolo movGestTsDetTipoId per movgest_ts_det_tipo_code=IMPORTO ATTUALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into  movGestTsDetTipoId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

	 if movGestTsDetTipoId is null then 
		RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	 end if;
	
	 strMessaggio:='Calcolo impegnato residuo effettivo elem_id='||id_in
				  ||'. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE;

	 if movGestTsDetTipoIdIniziale is null then 
		RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	 end if;

	


	impegniDaRibaltamento:=0;
--	pluriennaliDaRibaltamento:=0;
	importoImpegnato:=0;	
	
	select  count(*) into impegniDaRibaltamento 
	from fase_bil_t_gest_apertura_liq_imp fb 
	where fb.bil_id = bilancioId
	and   fb.movgest_Ts_id is not null
	and   fb.data_cancellazione is null
	and   fb.validita_fine is null;
    if impegniDaRibaltamento is null then impegniDaRibaltamento:=0; end if;
   
   raise notice 'impegniDaRibaltamento=%',impegniDaRibaltamento;
  
/*	select  count(*) into  pluriennaliDaRibaltamento
	from fase_bil_t_gest_apertura_pluri fb 
	where fb.bil_id = bilancioId
	and   fb.movgest_Ts_id is not null
	and fb.data_cancellazione is null
	and fb.validita_fine is null;
	if pluriennaliDaRibaltamento is null then pluriennaliDaRibaltamento:=0; end if;
    
    raise notice 'pluriennaliDaRibaltamento=%',pluriennaliDaRibaltamento;*/
--	if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then
--     impegniDaRibaltamento:=0;
	if impegniDaRibaltamento>0  then	

		-- - Se presenti i movimenti gestione provenienti dal ribaltamento 
		--		Residuo Finale = 
		--	 		Sommatoria dell importo attuale di tutti gli Impegni assunti sul capitolo in questione
		--			con anno movimento < N e anno esercizio N.
	    -- Sofia : ma sui residui passati al nuovo anno non si dovrebbe considerare iniziale - dubbio

		annoEsercizio:=annoBilancio;
		annoMovimento:=annoBilancio;
 		flagDeltaPagamenti:=false; -- non e' necessario scomputare il pagato
		
 	else

		-- - Se non presenti i movimenti gestione provenienti dal ribaltamento 
		-- 		Residuo Finale =	
		--			Sommatoria di tutti gli Impegni (valore effettivo aka finale) assunti sul capitolo in questione
		--			con anno movimento < N e anno esercizio N-1  
		--			diminuiti dalla sommatoria del pagato sui medesimi impegni nell esercizio N-1.
		annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
        annoMovimento:=annoBilancio;
		flagDeltaPagamenti:=true; -- bisogna sottrarre la sommatoria del pagato sui medesimi impegni nell'esercizio N-1
        
		strMessaggio:='Calcolo impegnato residuo effettivo elem_id='||id_in
				  ||'. Lettura capitolo equivalente in annoEsercizio='||annoEsercizio::varchar
				  ||'  attraverso siac_r_bil_elem_rel_tempo.';
		select rel.elem_id_old into elemIdGestEq
		from siac_r_bil_elem_rel_tempo rel 
		where rel.elem_id=id_in
		and   rel.data_cancellazione is null 
		and   rel.validita_fine is null;
		raise notice '>> siac_r_bil_elem_rel_tempo elemIdGestEq=%',elemIdGestEq::varchar;
	end if;

	strMessaggio:='Calcolo impegnato residuo effettivo elem_id='||id_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
   	-- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.ente_proprietario_id=enteProprietarioId
    and   per.anno=annoEsercizio
    and   perTipo.periodo_tipo_id=per.periodo_tipo_id
	and   perTipo.periodo_tipo_code='SY'    
    and   bil.periodo_id=per.periodo_id;

    if bilIdElemGestEq is null then
    	RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
    end if;
   
    if elemIdGestEq is null then
	    -- lettura elemIdGestEq
   		strMessaggio:='Calcolo impegnato residuo effettivo elem_id='||id_in||
		              'Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				      ||' per ente='||enteProprietarioId||'.';

		select bilelem.elem_id into elemIdGestEq
		from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
		where bilElemTipo.ente_proprietario_id=enteProprietarioId
		and   bilElemTipo.elem_tipo_code=TIPO_CAP_UG
    	and   bilElem.elem_tipo_id=bilElemTipo.elem_tipo_id	
	    and   bilElem.bil_id=bilIdElemGestEq
		and   bilElem.elem_code=elemCode
	    and   bilElem.elem_code2=elemCode2
		and   bilElem.elem_code3=elemCode3
	    and   bilElem.data_cancellazione is null
		and   bilElem.validita_fine is null;
	else
	    strMessaggio:='Calcolo impegnato residuo effettivo elem_id='||id_in||
		              'Verifica validita'' elem_id equivalente per bilancioId='||bilIdElemGestEq
				      ||' per ente='||enteProprietarioId||' da siac_r_bil_elem_rel_tempo.';

	    select bilelem.elem_id into elemIdRelTempo
		from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
		where bilElemTipo.ente_proprietario_id=enteProprietarioId
		and   bilElemTipo.elem_tipo_code=TIPO_CAP_UG
    	and   bilElem.elem_tipo_id=bilElemTipo.elem_tipo_id	
	    and   bilElem.bil_id=bilIdElemGestEq
	    and   bilElem.elem_id=elemIdGestEq
	    and   bilElem.data_cancellazione is null
		and   bilElem.validita_fine is null;
	    if elemIdRelTempo is null then
	    	raise notice 'elemIdRelTempo=%',elemIdRelTempo::varchar;
	        elemIdGestEq:=null;
	    end if;
	   
	end if;


	if NOT FOUND or elemIdGestEq is null  THEN
		impegnatoDefinitivo:=0;  
	else

   	    strMessaggio:='Calcolo impegnato residuo effettivo elem_id='||id_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento||'.'; 

		impegnatoDefinitivo:=0;

--		if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then
        raise notice 'flagDeltaPagamenti=%',flagDeltaPagamenti;
		if flagDeltaPagamenti=false then
			--  Sommatoria dell'importo attuale di tutti gli Impegni assunti sul capitolo in questione 
			--	con anno movimento < N e anno esercizio N

			importoImpegnato:=0;			
			select tb.importo into importoImpegnato
			from 
			(
			  select coalesce(sum(det.movgest_ts_det_importo),0) importo, ts.movgest_ts_tipo_id
			  from    siac_t_movgest mov,		  
					  siac_t_movgest_ts ts,
				      siac_r_movgest_ts_stato rs,
			  		  siac_r_movgest_bil_elem re,
			  		  siac_d_movgest_ts_det_tipo tipo_det,
					  siac_t_movgest_ts_det det
			  where mov.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
			  and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
			  and   mov.movgest_anno < annoMovimento::integer -- anno dell impegno < annoMovimento
			  and   ts.movgest_id=mov.movgest_id
			  and   rs.movgest_ts_id=ts.movgest_ts_id
			  and   rs.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO			  
			  and   re.movgest_id=mov.movgest_id
			  and   re.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
			  and   det.movgest_ts_id=ts.movgest_ts_id
			  and   tipo_det.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
			  and   tipo_det.movgest_ts_det_tipo_id=movGestTsDetTipoIdIniziale -- considerare l'importo iniziale
			  and   rs.data_cancellazione is null
			  and   rs.validita_fine is null
			  and   re.validita_fine is null 
			  and   re.data_cancellazione is null
			  and   mov.data_cancellazione is null
			  and   ts.data_cancellazione is null
			  group by ts.movgest_ts_tipo_id
			) tb, siac_d_movgest_ts_tipo tipo
			where tb.movgest_ts_tipo_id=tipo.movgest_ts_tipo_id
			order by tipo.movgest_ts_tipo_code desc
			limit 1;		
			if importoImpegnato is null then importoImpegnato:=0; end if;
			raise notice 'importoImpegnato=%',importoImpegnato;
		else
			-- Sommatoria di tutti gli Impegni assunti (valore effettivo aka finale) sul capitolo in questione su Componente X 
			-- con anno movimento < N e anno esercizio N-1
			-- diminuiti dalla sommatoria del pagato sui medesimi impegni nell'esercizio N-1.
			importoImpegnato:=0;			
			select tb.importo into importoImpegnato
			from 
			(
			  select coalesce(sum(det.movgest_ts_det_importo),0) importo, ts.movgest_ts_tipo_id
			  from    siac_t_movgest mov,		  
					  siac_t_movgest_ts ts,
				      siac_r_movgest_ts_stato rs,
			  		  siac_r_movgest_bil_elem re,
			  		  siac_d_movgest_ts_det_tipo tipo_det,
					  siac_t_movgest_ts_det det
			  where mov.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
			  and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
			  and   mov.movgest_anno < annoMovimento::integer -- anno dell impegno < annoMovimento
			  and   ts.movgest_id=mov.movgest_id
			  and   rs.movgest_ts_id=ts.movgest_ts_id
			  and   rs.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO			  
			  and   re.movgest_id=mov.movgest_id
			  and   re.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
			  and   det.movgest_ts_id=ts.movgest_ts_id
			  and   tipo_det.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
			  and   tipo_det.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
			  and   rs.data_cancellazione is null
			  and   rs.validita_fine is null
			  and   re.validita_fine is null 
			  and   re.data_cancellazione is null
			  and   mov.data_cancellazione is null
			  and   ts.data_cancellazione is null
			  group by ts.movgest_ts_tipo_id
			) tb, siac_d_movgest_ts_tipo tipo
			where tb.movgest_ts_tipo_id=tipo.movgest_ts_tipo_id
			order by tipo.movgest_ts_tipo_code desc
			limit 1;		
			if importoImpegnato is null then importoImpegnato:=0; end if;
			raise notice 'importoImpegnato=%',importoImpegnato;

			if importoImpegnato>=0 then

   	    		strMessaggio:='Calcolo impegnato residuo effettivo elem_id='||id_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Calcolo sommatoria del pagato sui medesimi impegni nell''esercizio N-1.';

			   select ordstato.ord_stato_id into ordStatoAId
			   from siac_d_ordinativo_stato ordstato
			   where ordstato.ente_proprietario_id=enteProprietarioId
			   and   ordstato.ord_stato_code=STATO_ORD_A;
				
			   if ordStatoAId is null then
			   	RAISE EXCEPTION '% Identificativo ord_stato_code=% non reperito.',strMessaggio,STATO_ORD_A;
			   end if;
			  
			   select tipo.ord_ts_det_tipo_id into ordTsDetTipoAId
			   from siac_d_ordinativo_ts_det_tipo tipo
			   where tipo.ente_proprietario_id=enteProprietarioId
			   and   tipo.ord_ts_det_tipo_code=ORD_TS_DET_TIPO_A;

			   if ordTsDetTipoAId is null then
			   	RAISE EXCEPTION '% Identificativo ord_ts_det_tipo_code=% non reperito.',strMessaggio,ORD_TS_DET_TIPO_A;
			   end if;
			  
 
			   select coalesce(sum(det.ord_ts_det_importo),0) into importoPagatoDelta
				from  
					 siac_r_movgest_bil_elem re,
					 siac_t_movgest  mov, -- mov, 
					 siac_t_movgest_ts ts, --ts,
					 siac_r_liquidazione_movgest rliq,
					 siac_r_liquidazione_ord rord, 
					 siac_t_ordinativo_ts ordts, 
					 siac_t_ordinativo ord,
					 siac_r_ordinativo_stato rordstato,
					 siac_t_ordinativo_ts_det det, --tsdet,
					 siac_r_movgest_ts_stato rmov_stato
				where  re.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
				and    mov.movgest_id=re.movgest_id 
				and    mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO				
				and    mov.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
			    and    mov.movgest_anno < annoMovimento::integer -- anno dell impegno < annoMovimento
				and    ts.movgest_id=mov.movgest_id
			    and    rmov_stato.movgest_ts_id=ts.movgest_ts_id			    
				and    rmov_stato.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO			    
		     	and    rliq.movgest_ts_id=ts.movgest_ts_id				
				and    rord.liq_id=rliq.liq_id
				and    ordts.ord_ts_id=rord.sord_id		     	
				and    ord.ord_id=ordts.ord_id
			    and    ord.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				and    rordstato.ord_id=ord.ord_id
				and    rordstato.ord_stato_id!=ordStatoAId -- non deve essere Annullato
				and    det.ord_ts_id=ordts.ord_ts_id
				and    det.ord_ts_det_tipo_id=ordTsDetTipoAId -- importo attuale
				and    det.data_cancellazione is null
				and    det.validita_fine is null
				and    mov.data_cancellazione is null
				and    mov.validita_fine is null
				and    ts.data_cancellazione is null
				and    ts.validita_fine is null
				and    re.data_cancellazione is null
				and    re.validita_fine is null
				and    rord.data_cancellazione is null
				and    rord.validita_fine is null
				and    rliq.data_cancellazione is null
				and    rliq.validita_fine is null
				and    ordts.data_cancellazione is null
				and    ordts.validita_fine is null
				and    ord.data_cancellazione is null
				and    ord.validita_fine is null
				and    rordstato.data_cancellazione is null
				and    rordstato.validita_fine is null
				and    rmov_stato.data_cancellazione is null
				and    rmov_stato.validita_fine is null;

				if importoPagatoDelta is null then importoPagatoDelta:=0; end if;
   			    raise notice 'importoPagatoDelta=%',importoPagatoDelta;

			end if;		
		end if;
	end if;


	impegnatoDefinitivo:=0; 
	impegnatoDefinitivo:=impegnatoDefinitivo+importoImpegnato-(importoPagatoDelta);
    raise notice 'impegnatoDefinitivo=%',impegnatoDefinitivo;
	return impegnatoDefinitivo;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
		return impegnatoDefinitivo;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
		return impegnatoDefinitivo;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
		return impegnatoDefinitivo;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


ALTER FUNCTION siac.fnc_siac_impegnatoresiduo_effettivo_up (id_in integer)
  OWNER TO siac;

