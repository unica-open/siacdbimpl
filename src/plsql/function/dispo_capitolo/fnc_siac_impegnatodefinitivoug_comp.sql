/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatodefinitivoug_comp (
  id_in integer,
  idcomp_in integer
)
RETURNS TABLE (
  indiceannualita integer,
  elemdetcompid integer,
  impegnatodefinitivo numeric
) AS
$body$
DECLARE


annoBilancio varchar:=null;
annoEsercizio varchar:=null;
annoMovimento varchar:=null;

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
modStatoVId integer:=0;
attoAmmStatoPId integer:=0;
STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoCurAttuale numeric:=0;
esisteRmovgestidelemid INTEGER:=0;
importoModifDelta  numeric:=0;
importoModifINS numeric:=0; --aggiunta per ECONB

flagNMaggioreNPiu2 integer:=0;
flagDeltaPagamenti integer:=0;
importoImpegnato numeric:=0;
importoPagatoDelta numeric:=0;
ordStatoAId          integer:=null;
ordTsDetTipoAId      integer:=null;
-- stati ordinativi
STATO_ORD_A    constant varchar:='A'; -- ANNULLATO
-- importoAttuale ordinativi
ORD_TS_DET_TIPO_A  constant varchar:='A';

strMessaggio varchar(1500):=null;
BEGIN
-- CALCOLO IMPEGNATO DEFINITIVO 
-- IN TUTTI I CASI:
-- I valori di impegnato dovranno essere calcolati tenendo conto del solo impegnato definitivo.
-- Escluse dal calcolo quindi:
--		- le modifiche di impegno provvisorie (modifiche con provvedimento in stato provvisorio - di qualsiasi segno
-- 		- gli  impegni in stato provvisorio

    strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in|| 'idcomp_in='||idcomp_in|| '.';

	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;
	if idcomp_in is null or idcomp_in=0 then
		 RAISE EXCEPTION '% Identificativo componente mancante.',strMessaggio;
	end if;
 
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
    			  '.Lettura anno di bilancio del capitolo UG.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;
		  

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
    			  '. Determina capitolo dati del capitolo di gestione in anno esercizio calcolato' || 
				   '. Calcolo bilancioId e elem_tipo_code.';
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

	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UG then
			RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
	 end if;

	 strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				   'Calcolo fase operativa per bilancioId='||bilancioId
				   ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

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

	 strMessaggio:='Calcolo impegnato definitivo elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO'
				  ||'. Calcolo movGestTsStatoIdProvvisorio per movgest_stato_code=PROVVISORIO';

	 select movGestStato.movgest_stato_id into strict movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;

	 select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_P; 
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo movGestTsDetTipoId per movgest_ts_det_tipo_code=IMPORTO ATTUALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE;
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
              ||'. Calcolo modStatoVId per mod_stato_code=VALIDO.';
	 select d.mod_stato_id into strict modStatoVId
	 from siac_d_modifica_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.mod_stato_code=STATO_MOD_V;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	 select d.attoamm_stato_id into strict attoAmmStatoPId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_P;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINITIVO';
	 select d.attoamm_stato_id into strict attoAmmStatoDId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_D;

 
--- CICLO SU TUTTE LE POSSIBILI ANNUALITA': N-1, N, N+1, N+2 e >N+2
FOR loop_counter IN  0..6  LOOP
CASE loop_counter

 WHEN 0 THEN
	-- Calcolo Impegnato definitivo - Anno N-1: 
	-- Sommatoria di tutti gli Impegni assunti sul capitolo di previsione id_in su Componente idcomp_in
	-- con anno movimento N-1 e anno esercizio N-1.
	-- I valori di impegnato dovranno essere calcolati tenendo conto del solo impegnato definitivo.
	-- Escluse dal calcolo quindi:
	--		- le modifiche di impegno provvisorie (modifiche con provvedimento in stato provvisorio - di qualsiasi segno)
	-- 		- gli  impegni in stato provvisorio

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
    			  '.Determina anno esercizio ed anno movimento per i quali calcolare.';
    annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
    annoMovimento:=((annoBilancio::INTEGER)-1)::varchar;
	flagNMaggioreNPiu2:=0;
	
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				   '. Calcolo bilancioId per annoEsercizio='||annoEsercizio
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
         -- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- verifica esistenza capitolo ed assegna a  elemIdGestEq
	 strMessaggio:='Calcolo impegnato competenza UG.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
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


	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else

		strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento|| 
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid 
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno=annoMovimento::integer
			and el.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
			;
		
		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;
		
		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
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
				  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
				  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  -- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  -- and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
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

			 -- 16.03.2017 Sofia JIRA-SIAC-4614
			-- if importoCurAttuale>0 then
			 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

				strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Calcolo totale modifiche su atti provvisori per annoMovimento='||annoMovimento||'.';

				select tb.importo into importoModifDelta
				 from
				 (
					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, 
					 	 siac_t_movgest mov,
					 	 siac_t_movgest_ts ts,
						 siac_r_movgest_ts_stato rstato,
					  	 siac_t_movgest_ts_det tsdet,
						 siac_t_movgest_ts_det_mod moddet,
						 siac_t_modifica mod, 
					 	 siac_r_modifica_stato rmodstato,
						 siac_r_atto_amm_stato attostato, 
					 	 siac_t_atto_amm atto,
						 siac_d_modifica_tipo tipom
					where 
						rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
						and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
						and	  mov.movgest_id=rbil.movgest_id
						and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
						and   mov.movgest_anno=annoMovimento::integer -- anno dell impegno = annoMovimento
						and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
						and   ts.movgest_id=mov.movgest_id
						and   rstato.movgest_ts_id=ts.movgest_ts_id
						and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
						-- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
						-- and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
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
						and   tipom.mod_tipo_id=mod.mod_tipo_id
						and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
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
					  
 				if importoModifDelta is null then importoModifDelta:=0; end if;
				 /*Aggiunta delle modifiche ECONB*/
				 -- anna_economie inizio
   				select tb.importo into importoModifINS
 				from
 				(
 					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
 			   	 	siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
				    siac_t_movgest_ts_det_mod moddet,
 			   	 	siac_t_modifica mod, siac_r_modifica_stato rmodstato,
				    siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
 			        siac_d_modifica_tipo tipom
				where rbil.elem_id=elemIdGestEq
				and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
				and	  mov.movgest_id=rbil.movgest_id
				and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
 			   	and   mov.movgest_anno=annoMovimento::integer
 			   	and   mov.bil_id=bilancioId
				and   ts.movgest_id=mov.movgest_id
				and   rstato.movgest_ts_id=ts.movgest_ts_id
				and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- impegno non annullato
				and   tsdet.movgest_ts_id=ts.movgest_ts_id
				and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
				and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
				and   moddet.movgest_ts_det_importo<0 -- importo negativo
				and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
				and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
				and   mod.mod_id=rmodstato.mod_id
				and   atto.attoamm_id=mod.attoamm_id
				and   attostato.attoamm_id=atto.attoamm_id
				and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
 			   and   tipom.mod_tipo_id=mod.mod_tipo_id
 			   and   tipom.mod_tipo_code = 'ECONB'
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
			 
			 if importoModifINS is null then 
			 	importoModifINS = 0;
			 end if;

		
			end if;		
		end if;
	end if;

	
	-- restituisco il record risultato
	
	--FIX Adeguamento 7349 MR
	-- Non dobbiamo piu' restituire al impegnato le modifiche provvisorie e le ECONB
	importoModifDelta:=0;
	importoModifINS:=0;
	--
	
	indiceAnnualita:=loop_counter;
	elemDetCompId:=idcomp_in;
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente per l'anno N-1
	impegnatoDefinitivo:=impegnatoDefinitivo+importoCurAttuale-(importoModifDelta);

	--aggiunta per ECONB
	impegnatoDefinitivo:=impegnatoDefinitivo+abs(importoModifINS);

	return next;

	
	
 WHEN 1,2,3 THEN
 	-- Calcolo Impegnato definitivo - Anno N: 
	-- - Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in e anno movimento N e anno esercizio N

	-- Calcolo Impegnato definitivo - Anno N+1: 
	-- - Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in e anno movimento N+1 e anno esercizio N

	-- Calcolo Impegnato definitivo - Anno N+2: 
	-- - Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in e anno movimento N+2 e anno esercizio N
	
	-- I valori di impegnato dovranno essere calcolati tenendo conto del solo impegnato definitivo.
	-- Escluse dal calcolo quindi:
	--		- le modifiche di impegno provvisorie (modifiche con provvedimento in stato provvisorio - di qualsiasi segno)
	-- 		- gli  impegni in stato provvisorio

	importoCurAttuale:=0;	
	importoModifDelta:=0;
	importoModifINS:=0;

				
	--	ImpegnatoDefinitivo = 	Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in 
	--			e anno movimento [N | N+1 | N+2] e anno esercizio N

	annoEsercizio:=annoBilancio;
	annoMovimento:=((annoBilancio::INTEGER)+loop_counter-1)::varchar;
	flagNMaggioreNPiu2:=0;
	
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per e per annoEsercizio='||annoEsercizio
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    	-- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo impegnato competenza UG.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
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

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else

		strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento|| 
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid 
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno=annoMovimento::integer
			and el.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
			;
		
		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;
		
		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

					
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
				  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
				  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  -- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  -- and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
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

			 -- 16.03.2017 Sofia JIRA-SIAC-4614
			-- if importoCurAttuale>0 then
			 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

				strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Calcolo totale modifiche su atti provvisori per annoMovimento='||annoMovimento||'.';

				select tb.importo into importoModifDelta
				 from
				 (
					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, 
					 	 siac_t_movgest mov,
					 	 siac_t_movgest_ts ts,
						 siac_r_movgest_ts_stato rstato,
					  	 siac_t_movgest_ts_det tsdet,
						 siac_t_movgest_ts_det_mod moddet,
						 siac_t_modifica mod, 
					 	 siac_r_modifica_stato rmodstato,
						 siac_r_atto_amm_stato attostato, 
					 	 siac_t_atto_amm atto,
						 siac_d_modifica_tipo tipom
					where 
						rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
						and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
						and	  mov.movgest_id=rbil.movgest_id
						and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
						and   mov.movgest_anno=annoMovimento::integer -- anno dell impegno = annoMovimento
						and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
						and   ts.movgest_id=mov.movgest_id
						and   rstato.movgest_ts_id=ts.movgest_ts_id
						and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
						-- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  		-- and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
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
						and   tipom.mod_tipo_id=mod.mod_tipo_id
						and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
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
					  
 				if importoModifDelta is null then importoModifDelta:=0; end if;
				  /*Aggiunta delle modifiche ECONB*/
				 -- anna_economie inizio
   				select tb.importo into importoModifINS
 				from
 				(
 					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
 			   	 	siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
				    siac_t_movgest_ts_det_mod moddet,
 			   	 	siac_t_modifica mod, siac_r_modifica_stato rmodstato,
				    siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
 			        siac_d_modifica_tipo tipom
				where rbil.elem_id=elemIdGestEq
				and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
				and	  mov.movgest_id=rbil.movgest_id
				and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
 			   	and   mov.movgest_anno=annoMovimento::integer
 			   	and   mov.bil_id=bilancioId
				and   ts.movgest_id=mov.movgest_id
				and   rstato.movgest_ts_id=ts.movgest_ts_id
				and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- impegno non annullato
				and   tsdet.movgest_ts_id=ts.movgest_ts_id
				and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
				and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
				and   moddet.movgest_ts_det_importo<0 -- importo negativo
				and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
				and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
				and   mod.mod_id=rmodstato.mod_id
				and   atto.attoamm_id=mod.attoamm_id
				and   attostato.attoamm_id=atto.attoamm_id
				and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
 			   and   tipom.mod_tipo_id=mod.mod_tipo_id
 			   and   tipom.mod_tipo_code = 'ECONB'
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
			 
			 if importoModifINS is null then 
			 	importoModifINS = 0;
			 end if;

		
			end if;		
		end if;
	end if;
	
	--FIX Adeguamento 7349 MR
	-- Non dobbiamo piu' restituire al impegnato le modifiche provvisorie e le ECONB
	importoModifDelta:=0;
	importoModifINS:=0;
	--
	
	indiceAnnualita:=loop_counter;
	elemDetCompId:=idcomp_in;
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente per l'anno N-1
	impegnatoDefinitivo:=impegnatoDefinitivo+importoCurAttuale-(importoModifDelta);
	--aggiunta per ECONB
	impegnatoDefinitivo:=impegnatoDefinitivo+abs(importoModifINS);
	
	return next;

 	
 WHEN 4 THEN
 	-- Calcolo Impegnato definitivo - Anno > N+2:
 	-- - Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in e anno movimento > N+2 e anno esercizio N
	-- I valori di impegnato dovranno essere calcolati tenendo conto del solo impegnato definitivo.
	-- Escluse dal calcolo quindi:
	--		- le modifiche di impegno provvisorie (modifiche con provvedimento in stato provvisorio - di qualsiasi segno)
	-- 		- gli  impegni in stato provvisorio

	importoCurAttuale:=0;	
	importoModifDelta:=0;
	importoModifINS := 0;
	
				
 	--	ImpegnatoDefinitivo = Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in 
	--	e anno movimento > N+2 e anno esercizio N

	annoEsercizio:=annoBilancio;
	annoMovimento:=((annoBilancio::INTEGER)+2)::varchar;
	flagNMaggioreNPiu2:=1;

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per annoEsercizio='||annoEsercizio
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    -- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo impegnato competenza UG.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
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

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else

		strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento|| 
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid 
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno>annoMovimento::integer 
			and el.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
			;
		
		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;
		
		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
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
				  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
				  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  -- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  -- and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno > annoMovimento::integer -- anno dell impegno > annoMovimento 
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

			 -- 16.03.2017 Sofia JIRA-SIAC-4614
			-- if importoCurAttuale>0 then
			 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

				strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Calcolo totale modifiche su atti provvisori per annoMovimento='||annoMovimento||'.';

				select tb.importo into importoModifDelta
				 from
				 (
					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, 
					 	 siac_t_movgest mov,
					 	 siac_t_movgest_ts ts,
						 siac_r_movgest_ts_stato rstato,
					  	 siac_t_movgest_ts_det tsdet,
						 siac_t_movgest_ts_det_mod moddet,
						 siac_t_modifica mod, 
					 	 siac_r_modifica_stato rmodstato,
						 siac_r_atto_amm_stato attostato, 
					 	 siac_t_atto_amm atto,
						 siac_d_modifica_tipo tipom
					where 
						rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
						and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
						and	  mov.movgest_id=rbil.movgest_id
						and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
						and   mov.movgest_anno>annoMovimento::integer -- anno dell impegno = annoMovimento 
						and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
						and   ts.movgest_id=mov.movgest_id
						and   rstato.movgest_ts_id=ts.movgest_ts_id
						and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
						-- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				        -- and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
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
						and   tipom.mod_tipo_id=mod.mod_tipo_id
						and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
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
					  
 				if importoModifDelta is null then importoModifDelta:=0; end if;
				  /*Aggiunta delle modifiche ECONB*/
				 -- anna_economie inizio
   				select tb.importo into importoModifINS
 				from
 				(
 					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
 			   	 	siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
				    siac_t_movgest_ts_det_mod moddet,
 			   	 	siac_t_modifica mod, siac_r_modifica_stato rmodstato,
				    siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
 			        siac_d_modifica_tipo tipom
				where rbil.elem_id=elemIdGestEq
				and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
				and	  mov.movgest_id=rbil.movgest_id
				and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
 			   	and   mov.movgest_anno=annoMovimento::integer
 			   	and   mov.bil_id=bilancioId
				and   ts.movgest_id=mov.movgest_id
				and   rstato.movgest_ts_id=ts.movgest_ts_id
				and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- impegno non annullato
				and   tsdet.movgest_ts_id=ts.movgest_ts_id
				and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
				and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
				and   moddet.movgest_ts_det_importo<0 -- importo negativo
				and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
				and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
				and   mod.mod_id=rmodstato.mod_id
				and   atto.attoamm_id=mod.attoamm_id
				and   attostato.attoamm_id=atto.attoamm_id
				and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
 			   and   tipom.mod_tipo_id=mod.mod_tipo_id
 			   and   tipom.mod_tipo_code = 'ECONB'
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
			 
			 if importoModifINS is null then 
			 	importoModifINS = 0;
			 end if;

		
			end if;		
		end if;
	end if;
	
	--FIX Adeguamento 7349 MR
	-- Non dobbiamo piu' restituire al impegnato le modifiche provvisorie e le ECONB
	importoModifDelta:=0;
	importoModifINS:=0;
	--
	
	
	indiceAnnualita:=loop_counter;
	elemDetCompId:=idcomp_in;
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente per l'anno N-1
	impegnatoDefinitivo:=impegnatoDefinitivo+importoCurAttuale-(importoModifDelta);
	--aggiunta per ECONB
	impegnatoDefinitivo:=impegnatoDefinitivo+abs(importoModifINS);
	return next;

 WHEN 5 THEN
	-- Calcolo Residuo Iniziale: 
	--	 Sommatoria dell'importo iniziale di tutti gli Impegni assunti sul capitolo in questione su idcomp_in
	--	con anno movimento < N e anno esercizio N.

	importoImpegnato:=0;	
	importoPagatoDelta:=0;
	
 
	--		Residuo Iniziale = 
	--	 		Sommatoria dell'importo iniziale di tutti gli Impegni assunti sul capitolo in questione su idcomp_in
	--			con anno movimento < N e anno esercizio N.

	annoEsercizio:=annoBilancio;
	annoMovimento:=annoBilancio;
	flagDeltaPagamenti:=0; -- non e' necessario scomputare il pagato
		
 	

	strMessaggio:='Calcolo residuo iniziale elem_id='||id_in||'idcomp_in='||idcomp_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per annoEsercizio='||annoEsercizio
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    -- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo residuo iniziale.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
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

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else

		strMessaggio:='Calcolo residuo iniziale elem_id='||id_in||'idcomp_in='||idcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento||'.'; 

		impegnatoDefinitivo:=0;
		strMessaggio:='Calcolo residuo iniziale elem_id='||id_in||'idcomp_in='||idcomp_in||
			'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
			'. Inizio calcolo totale importo  impegni per annoMovimento='||annoMovimento||'.';


		importoImpegnato:=0;			
		select tb.importo into importoImpegnato
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
				  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
				  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  -- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  -- and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno < annoMovimento::integer -- anno dell impegno < annoMovimento 
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoIdIniziale -- considerare l'importo iniziale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;		
			-- 02.02.2016 Sofia JIRA 2947
			if importoImpegnato is null then importoImpegnato:=0; end if;

	end if;

	indiceAnnualita:=loop_counter;
	elemDetCompId:=idcomp_in;
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente per l'anno N-1
	if flagDeltaPagamenti != 0 then
		impegnatoDefinitivo:=impegnatoDefinitivo+importoImpegnato-(importoPagatoDelta);
	else 
		impegnatoDefinitivo:=impegnatoDefinitivo+importoImpegnato;
	end if;
	return next;

	

 WHEN 6 THEN
	-- Calcolo Residuo Finale (In presenza della colonna finale e in assenza di qualsiasi colonna):
	--		Sommatoria dell'importo attuale di tutti gli Impegni assunti sul capitolo in questione su idcomp_in 
	--		con anno movimento < N e anno esercizio N.
 
	importoImpegnato:=0;	
	importoPagatoDelta:=0;
	

	--		Residuo Finale = 
	--	 		Sommatoria dell'importo attuale di tutti gli Impegni assunti sul capitolo in questione su idcomp_in
	--			con anno movimento < N e anno esercizio N.

	annoEsercizio:=annoBilancio;
	annoMovimento:=annoBilancio;
	flagDeltaPagamenti:=0; -- non e' necessario scomputare il pagato
		

	strMessaggio:='Calcolo residuo finale elem_id='||id_in||'idcomp_in='||idcomp_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per annoEsercizio='||annoEsercizio
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    -- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo residuo finale.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
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

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else

		strMessaggio:='Calcolo residuo finale elem_id='||id_in||'idcomp_in='||idcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento||'.'; 

		impegnatoDefinitivo:=0;
		strMessaggio:='Calcolo residuo finale elem_id='||id_in||'idcomp_in='||idcomp_in||
			'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
			'. Inizio calcolo totale importo  impegni per annoMovimento='||annoMovimento||'.';

		importoImpegnato:=0;			
		select tb.importo into importoImpegnato
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
				  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
				  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  -- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  -- and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno < annoMovimento::integer -- anno dell impegno < annoMovimento 
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
			if importoImpegnato is null then importoImpegnato:=0; end if;


	end if;

	indiceAnnualita:=loop_counter;
	elemDetCompId:=idcomp_in;
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente per l'anno N-1
	if flagDeltaPagamenti != 0 then
		impegnatoDefinitivo:=impegnatoDefinitivo+importoImpegnato-(importoPagatoDelta);
	else 
		impegnatoDefinitivo:=impegnatoDefinitivo+importoImpegnato;
	end if;
	return next;

END CASE;
END LOOP;

return;

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


ALTER FUNCTION siac.fnc_siac_impegnatodefinitivoug_comp (id_in integer, idcomp_in integer)
  OWNER TO siac;
 
--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatodefinitivoug_comp (id_in integer, idcomp_in integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatodefinitivoug_comp (id_in integer, idcomp_in integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatodefinitivoug_comp (id_in integer, idcomp_in integer) TO siac;