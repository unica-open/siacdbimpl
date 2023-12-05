/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatoeffettivoup_comp_anno (
  id_in integer,
  anno_in varchar
)
RETURNS TABLE (
  annocompetenza varchar,
  impegnatoEffettivo numeric
) AS
$body$

DECLARE
annoBilancio varchar:=null;
annoEsercizio varchar:=null;
annoMovimento varchar:=null;
importoAttuale numeric:=0;
elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;
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
STATO_P     constant varchar:='P';
TIPO_IMP    constant varchar:='I';
movGestStatoIdAnnullato integer:=0;
movGestStatoIdProvvisorio integer:=0;
movGestTipoId integer:=0;
IMPORTO_ATT constant varchar:='A';
movGestTsDetTipoId integer:=0;
IMPORTO_INIZIALE constant varchar:='I';
movGestTsDetTipoIdIniziale integer:=0;
STATO_MOD_V  constant varchar:='V';

STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';
importoCurAttuale numeric:=0;
esisteRmovgestidelemid INTEGER:=0;
impegniDaRibaltamento integer:=0;
pluriennaliDaRibaltamento integer:=0;
flagNMaggioreNPiu2 integer:=0;
importoImpegnato integer:=0;

strMessaggio varchar(1500):=null;
BEGIN


    strMessaggio:='Calcolo totale impegnato effettivo per elem_id='||id_in||'.';

	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;

	strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||'. Lettura anno di bilancio del capitolo UP.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;


	strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||'. Determina capitolo di gestione equivalente in anno esercizio di calcolato. Calcolo bilancioId e elem_tipo_code.';
	 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
	 into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
	 from 	siac_t_bil_elem bilElem,
	 		siac_d_bil_elem_tipo tipoBilElem,
		  	siac_t_bil bil, siac_t_periodo per
	 where bilElem.elem_id=id_in
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
	   and bil.bil_id=bilElem.bil_id
	   and per.periodo_id=bil.periodo_id;

	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UP then
			RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
	 end if;

	 strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||'. Determina capitolo di gestione equivalente in anno esercizio calcolato. Calcolo fase operativa per bilancioId='||bilancioId||' , per ente='||enteProprietarioId||' e per elem_id='||id_in||'.';

	 select  faseOp.fase_operativa_code into  faseOpCode
	 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
	 where bilFase.bil_id =bilancioId
	   and bilfase.data_cancellazione is null
	   and bilFase.validita_fine is null
	   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
	   and faseOp.data_cancellazione is null
	 order by bilFase.bil_fase_operativa_id desc;

	 if NOT FOUND THEN
	   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
	 end if;

	 strMessaggio:='Calcolo impegnato effettivo elem_id='||id_in||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

	 strMessaggio:='Calcolo impegnato effettivo  competenza elem_id='||id_in||
				  '. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO'
				  '. Calcolo movGestTsStatoIdProvvisorio per movgest_stato_code=PROVVISORIO';

	 select movGestStato.movgest_stato_id into strict movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;

	 select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_P;

	 strMessaggio:='Calcolo impegnato effettivo competenza elem_id='||id_in||
				  '. Calcolo movGestTsDetTipoId per movgest_ts_det_tipo_code=IMPORTO ATTUALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT; --'A'

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||
				  '. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE; --'I'


	importoCurAttuale:=0;
	annoMovimento=anno_in;
	annoEsercizio=annoBilancio;

	strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||'. Determina capitolo di gestione equivalente in anno esercizio calcolato.';

	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';
	
    -- SIAC-7913 FL Inizio  
	  -- lettura elemIdGestEq
--	 strMessaggio:='Calcolo impegnato effettivo competenza UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
--				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
--
--	 select bilelem.elem_id into elemIdGestEq
--	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
--	 where bilElem.elem_code=elemCode
--	   and bilElem.elem_code2=elemCode2
--	   and bilElem.elem_code3=elemCode3
--	   and bilElem.ente_proprietario_id=enteProprietarioId
--	   and bilElem.data_cancellazione is null
--	   and bilElem.validita_fine is null
--	   and bilElem.bil_id=bilIdElemGestEq
--	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
--	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;
	   


--	if NOT FOUND THEN
--		impegnatoEffettivo:=0;
--	else
	-- SIAC-7913 FL Fine
		-- SIAC-7349 GS 16/07/2020 - INIZIO - Aggiunta la logica dei "ribaltamenti non presenti" usata nella function usata per il calcolo dell'impegnato della componente 
		-- - Se presenti i movimenti gestione provenienti dal ribaltamento:
		--		Sommatoria di tutti gli Impegni assunti sul capitolo in questione e anno movimento N e anno esercizio N
		-- - Se non presenti i movimenti gestione provenienti dal ribaltamento
		--		Sommatoria di tutti gli Impegni assunti sul capitolo in questione e anno movimento N e anno esercizio N-1 >>

		-- Verifica se presenti i movimenti di gestione provenienti dal ribaltamento
		-- Per "ribaltamento" si intende  il batch di ribaltamento residui che gira prima del ROR 
		--		e che "copia" gli impegni dell anno N-1 nel bilancio dell'anno N (di solito il 2 gennaio)
		-- Per verificare che il batch di ribaltamento sia stato eseguito controllo le seguenti tabelle
		-- 		fase_bil_t_gest_apertura_liq_imp per gli impegni residui
		--  	fase_bil_t_gest_apertura_pluri per i pluriennli (sia impegni che accertamenti)
		-- In entrambe si trova sia il bil_id che il bil_id_orig ovvero l'anno nuovo su cui si stanno ribaltando i movimenti e l'anno prec
		-- si trova anche un campo fl_elab che ti dice se i dati sono stati elaborati con scarto o con successo 
		strMessaggio:='Calcolo totale impegnato  bilIdElemGestEq='||bilIdElemGestEq||
					 '.Verifica se presenti i movimenti di gestione provenienti dal ribaltamento per anno di esercizio N.';

		impegniDaRibaltamento:=0;
		pluriennaliDaRibaltamento:=0;

		select  count(*) into impegniDaRibaltamento 
		from fase_bil_t_gest_apertura_liq_imp fb 
		where 
		fb.movgest_Ts_id is not null
		and fb.bil_id = bilIdElemGestEq
		and fb.data_cancellazione is null
		and fb.validita_fine is null;

		select  count(*) into  pluriennaliDaRibaltamento
		from fase_bil_t_gest_apertura_pluri fb 
		where 
		fb.movgest_Ts_id is not null
		and fb.bil_id = bilIdElemGestEq
		and fb.data_cancellazione is null
		and fb.validita_fine is null;

		strMessaggio:='Calcolo totale impegnato  bilIdElemGestEq='||bilIdElemGestEq||
						' impegniDaRibaltamento='||impegniDaRibaltamento||
						' pluriennaliDaRibaltamento='||pluriennaliDaRibaltamento||
						'.';

		if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then

			-- - Se presenti i movimenti gestione provenienti dal ribaltamento:
			--	ImpegnatoDefinitivo = 	Sommatoria di tutti gli Impegni assunti sul capitolo in questione  
			--			e anno movimento [N | N+1 | N+2] e anno esercizio N

			annoEsercizio:=annoBilancio;
			annoMovimento:=annoMovimento;
		else

			-- - Se non presenti i movimenti gestione provenienti dal ribaltamento
			--	ImpegnatoDefinitivo = Sommatoria di tutti gli Impegni assunti sul capitolo in questione  
			-- 			e anno movimento [N | N+1 | N+2] e anno esercizio N-1 >>

			annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
			annoMovimento:=annoMovimento;
		end if;--SIAC-7913	
			-- Determina nuovamente i valori di bilIdElemGestEq e elemIdGestEq

			strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||'. Determina capitolo di gestione equivalente in anno esercizio calcolato.';
			select bil.bil_id into strict bilIdElemGestEq
			from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
			where per.anno=annoEsercizio
			  and per.ente_proprietario_id=enteProprietarioId
			  and bil.periodo_id=per.periodo_id
			  and perTipo.periodo_tipo_id=per.periodo_tipo_id
			  and perTipo.periodo_tipo_code='SY';

			 strMessaggio:='Calcolo impegnato effettivo competenza UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
						  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

			 select bilelem.elem_id into elemIdGestEq
			 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
			 where bilElem.elem_code=elemCode
			   and bilElem.elem_code2=elemCode2
			   and bilElem.elem_code3=elemCode3
			   and bilElem.ente_proprietario_id=enteProprietarioId
			   and bilElem.data_cancellazione is null
			   and bilElem.validita_fine is null
			   and bilElem.bil_id=bilIdElemGestEq
			   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
			   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

	  --SIAC-7913 FL Inizio modifica 
		--end if;
	  if NOT FOUND THEN
		impegnatoEffettivo:=0;
	  else		
	  --SIAC-7913 FL Fine
		strMessaggio:='Calcolo totale impegnato  bilIdElemGestEq='||bilIdElemGestEq||
						' annoEsercizio='||annoEsercizio||
						' annoMovimento='||annoMovimento||
						'.';

		-- SIAC-7349 GS 16/07/2020 - FINE - Aggiunta la logica dei "ribaltamenti non presenti" usata nella function usata per il calcolo dell'impegnato della componente 
	
	
	
	
		strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq||
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento||
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno=annoMovimento::integer;

		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;

		if esisteRmovgestidelemid <>0 then
 			impegnatoEffettivo:=0;
			strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq||
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

			importoCurAttuale:=0;
			select tb.importo into importoCurAttuale
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq  -- UID del capitolo di gestione equivalente
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno = annoMovimento::integer -- anno dell impegno = annoMovimento
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;

			-- 02.02.2016 Sofia JIRA 2947
			 if importoCurAttuale is null then importoCurAttuale:=0; end if;

		end if;
	end if;-- siac-7913 era già presente ma chiede un altro if

 importoAttuale:=importoAttuale+importoCurAttuale; -- 16.03.2017 Sofia JIRA-SIAC-4614

 annoCompetenza:=anno_in;
 impegnatoEffettivo:=importoAttuale;

 return next;


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
PARALLEL UNSAFE
COST 100 ROWS 1000;


ALTER FUNCTION siac.fnc_siac_impegnatoeffettivoup_comp_anno (id_in integer, anno_in varchar)
  OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoup_comp_anno (id_in integer, anno_in varchar) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoup_comp_anno (id_in integer, anno_in varchar) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoup_comp_anno (id_in integer, anno_in varchar) TO siac;