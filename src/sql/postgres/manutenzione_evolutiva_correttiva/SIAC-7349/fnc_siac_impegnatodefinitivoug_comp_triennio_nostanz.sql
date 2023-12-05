/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatodefinitivoug_comp_triennio_nostanz(
	id_in integer,
	idcomp_in integer[])
    RETURNS TABLE(elemdetcompid integer, elemdetcompdesc character varying, annoimpegnato integer, impegnatodefinitivo numeric, elemdetcompmacrotipodesc character varying) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
AS $BODY$
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
impegniDaRibaltamento integer:=0;
pluriennaliDaRibaltamento integer:=0;
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

sidcomp_in  varchar:=null;
strMessaggio varchar(1500):=null;

impComponenteRec record;

BEGIN

/* Calcola impegnato definitivo per quelle componenti per le quali pur non essendoci stanziamento
 * esistono quote di impegnato nel triennio
 * Le componenti per le quali esiste stanziamento (e quindi da non considerare) sono passate in input nell'array idcomp_in
 * NOTA: per problemi Java/Hibernate idcomp_in non puo essere un array vuoto, quindi 
 *		l'array in input conterra' sempre la componente fittizia idcomp = -1
 */
-- CALCOLO IMPEGNATO DEFINITIVO 
-- Stiamo sempre parlando di impegnato sul capitolo di gestione equivalente	

	sidcomp_in:=array_to_string(idcomp_in, ',');
    	strMessaggio:='Calcolo totale impegnato definitovo elem_id='||id_in|| ' escludo idcomp_in='||sidcomp_in|| '.';

	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;
 
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||
    			  '.Lettura anno di bilancio del capitolo UP.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;
	strMessaggio:=strMessaggio || 'annoBilancio='||annoBilancio|| '.';

		  

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||
 
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

	 strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||

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

	 strMessaggio:='Calcolo impegnato definitivo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'escludo idcomp_in='||sidcomp_in
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
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTsDetTipoId per movgest_ts_det_tipo_code=IMPORTO ATTUALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE;
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
              ||'. Calcolo modStatoVId per mod_stato_code=VALIDO.';
	 select d.mod_stato_id into strict modStatoVId
	 from siac_d_modifica_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.mod_stato_code=STATO_MOD_V;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	 select d.attoamm_stato_id into strict attoAmmStatoPId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_P;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINITIVO';
	 select d.attoamm_stato_id into strict attoAmmStatoDId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_D;

 	-- Calcolo Impegnato definitivo 

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in;
	
	importoCurAttuale:=0;	
	importoModifDelta:=0;
	importoModifINS := 0;
	
	-- - Se presenti i movimenti gestione provenienti dal ribaltamento 
		annoEsercizio:=annoBilancio;
		annoMovimento:=annoBilancio;
	
	strMessaggio:=strMessaggio || 'annoEsercizio='||annoEsercizio|| '.';
	strMessaggio:=strMessaggio || 'annoMovimento='||annoMovimento|| '.';


	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
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
	strMessaggio:=strMessaggio || 'bilIdElemGestEq='||bilIdElemGestEq|| '.';


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
	strMessaggio:=strMessaggio || 'elemIdGestEq='||elemIdGestEq|| '.';


	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else
	
		strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento|| 
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid 
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno IN (annoMovimento::integer,  annoMovimento::integer+1, annoMovimento::integer+2) 
			and NOT (el.elem_det_comp_tipo_id = ANY( idcomp_in)) --SIAC-7349
			;
		
		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;

		strMessaggio:=strMessaggio || 'esisteRmovgestidelemid='||esisteRmovgestidelemid|| '.';


		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

			/* Versione con group by per le componenti non da escludere e ciclo per ogni componente */
			for impComponenteRec in
			 (
				select tb.elem_det_comp_tipo_id as compId, 
				 g.elem_det_comp_tipo_desc as compDesc, 
				 tb.importo as importoCurAttuale,
				 h.elem_det_comp_macro_tipo_desc as compMacroTipoDesc,
				 tb.movgest_anno as annualita
				from (
				  select
					  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id, a.elem_det_comp_tipo_id, b.movgest_anno
				  from
					  siac_r_movgest_bil_elem a,
					  siac_t_movgest b,
					  siac_t_movgest_ts c,
					  siac_r_movgest_ts_stato d,
					  siac_t_movgest_ts_det e,
					  siac_d_movgest_ts_det_tipo f
				  where
					  b.movgest_id=a.movgest_id 
					  and a.elem_id=elemIdGestEq 
					  and NOT( a.elem_det_comp_tipo_id = ANY(idcomp_in)) --SIAC-7349 --id componente diversa da quella ricevuta in input
					  and b.bil_id = bilIdElemGestEq
					  and b.movgest_tipo_id=movGestTipoId
					  and d.movgest_stato_id<>movGestStatoIdAnnullato
					  -- SIAC-7737 GS 31/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				      -- and d.movgest_stato_id<>movGestStatoIdProvvisorio
					  and b.movgest_anno IN (annoMovimento::integer,  annoMovimento::integer+1, annoMovimento::integer+2)
					  and c.movgest_id=b.movgest_id
					  and d.movgest_ts_id=c.movgest_ts_id
					  and d.validita_fine is null
					  and e.movgest_ts_id=c.movgest_ts_id
					  and a.data_cancellazione is null
					  and b.data_cancellazione is null
					  and c.data_cancellazione is null
					  and e.data_cancellazione is null
					  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
					  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId
					  group by 	c.movgest_ts_tipo_id, 
								a.elem_det_comp_tipo_id, -- SIAC-7349
								b.movgest_anno
					) tb, 
					siac_d_movgest_ts_tipo t,
					siac_d_bil_elem_det_comp_tipo g,
				 	siac_d_bil_elem_det_comp_macro_tipo h
				where 
					tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
					and g.elem_det_comp_tipo_id = tb.elem_det_comp_tipo_id --SIAC-7349 recupera anche la descrizione della componente
					and g.elem_det_comp_macro_tipo_id = h.elem_det_comp_macro_tipo_id --SIAC-7349 recupera anche la descrizione del macrotipo della componente
					and t.movgest_ts_tipo_code='T'  --SIAC-7876 filtrare sul campo per prendere solo gli impegni
				 order by t.movgest_ts_tipo_code desc
				 limit 1 --SIAC-7876 filtrare sul campo per prendere solo gli impegni
 			) 
			loop
			

					-- 02.02.2016 Sofia JIRA 2947
					 if impComponenteRec.importoCurAttuale is null then impComponenteRec.importoCurAttuale:=0; end if;

					 -- 16.03.2017 Sofia JIRA-SIAC-4614
					-- if importoCurAttuale>0 then
					 if impComponenteRec.importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

						strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'  impComponenteRec.compId='||impComponenteRec.compId||
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
								and rbil.elem_det_comp_tipo_id=impComponenteRec.compId --SIAC-7349 deve essere sulla compoenente del record 
								and	  mov.movgest_id=rbil.movgest_id
								and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
								and   mov.movgest_anno>annoMovimento::integer -- anno dell impegno = annoMovimento 
								and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
								and   ts.movgest_id=mov.movgest_id
								and   rstato.movgest_ts_id=ts.movgest_ts_id
								and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
								-- SIAC-7737 GS 31/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
							    -- and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
								and   tsdet.movgest_ts_id=ts.movgest_ts_id
								and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
								and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
								-- SIAC-7349 Prendo tutti gli importi, sia con segno negativo che con segno positivo
								-- La loro somma produce il valore importoModifDelta che devo sottrarre all'impegnato calcolato
								-- ad esempio: modifiche su atto provv +100, -322 -> somma -222 si tratta di un delta che devo sottrarre
								-- all'impegnato calcolato = impegnato calcolato - (-222) = +222 (aggiungo quello che avevo tolto)
								-- and   moddet.movgest_ts_det_importo<0 -- importo negativo
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
						and rbil.elem_det_comp_tipo_id=impComponenteRec.compId --SIAC-7349
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
	
			--Fix MR adeguamento sprint 5
			-- Mon restituiamo piu' al valore impegnato le modifiche provvisorie e le ECONB
           		importoModifDelta:=0;
            		importoModifINS:=0;
            --
			
			annoimpegnato:=impComponenteRec.annualita;
			elemDetCompId:=impComponenteRec.compId;
			elemdetcompdesc:=impComponenteRec.compDesc;
			elemdetcompmacrotipodesc:=impComponenteRec.compMacroTipoDesc;
			impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente  
			impegnatoDefinitivo:=impegnatoDefinitivo+impComponenteRec.importoCurAttuale-(importoModifDelta);
			--aggiunta per ECONB
			impegnatoDefinitivo:=impegnatoDefinitivo+abs(importoModifINS);
			return next;	

	end loop;
	end if;
	end if;

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
$BODY$;

ALTER FUNCTION siac.fnc_siac_impegnatodefinitivoug_comp_triennio_nostanz(integer, integer[])
    OWNER TO siac;


