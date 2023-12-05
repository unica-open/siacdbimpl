/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno_comp (
  id_in integer,
  id_comp integer,
  anno_in varchar,
  verifica_mod_prov boolean
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno_comp (
  id_in integer,
  id_comp integer,
  anno_in varchar,
  verifica_mod_prov boolean = true
)
RETURNS TABLE (
  annocompetenza varchar,
  dicuiimpegnato numeric
) AS
$body$
DECLARE
/*
Calcolo dell'impegnato di un capitolo di previsione id_in su una componente id_comp per l'anno anno_it,
utile al calcolo della disponibilita' a variare
quindi non tiene conto di grandezze da considerare solo per disponibilita' ad impegnare: limite massimo impegnabile e modifiche di impegno negative su provvedimento provvisorio
*/

-- constant
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';

FASE_OP_BIL_PREV constant VARCHAR:='P';

STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';

STATO_MOD_V  constant varchar:='V';

TIPO_IMP    constant varchar:='I';
TIPO_IMP_T  constant varchar:='T';

STATO_DEF   constant varchar:='D';
STATO_N     constant varchar:='N';
STATO_P     constant varchar:='P';
STATO_A     constant varchar:='A';
IMPORTO_ATT constant varchar:='A';

strMessaggio varchar(1500):=NVL_STR;

attoAmmStatoDId integer:=0;
attoAmmStatoPId integer:=0;
bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;

modStatoVId integer:=0;
movGestTipoId integer:=0;
movGestTsTipoId integer:=0;
movGestStatoId integer:=0;
movGestTsDetTipoId integer:=0;
movGestStatoIdProvvisorio integer:=0;
movGestTsId integer:=0;


importoAttuale numeric:=0;
importoCurAttuale numeric:=0;
importoModifDelta  numeric:=0;
importoModifINS numeric:=0; --aggiunta per ECONB

movGestIdRec record;

elemTipoCode VARCHAR(20):=NVL_STR;
faseOpCode varchar(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;

elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;

-- 10.08.2020 Sofia jira siac-6865
movGestStatoPId integer:=null;
importoCurAttAggiudicazione numeric:=0;
BEGIN

 annoCompetenza:=null;
 diCuiImpegnato:=0;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.Controllo parametri.';

 if anno_in is null or anno_in=NVL_STR then
	 RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
	 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
 end if;

 strMessaggio:='Calcolo impegnato competenza UP elem_id='||id_in||'.';

 strMessaggio:='Calcolo impegnato competenza UP.Calcolo bilancioId e elem_tipo_code per elem_id='||id_in||'.';
 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
       into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem,
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

 strMessaggio:='Calcolo impegnato competenza UP.Calcolo fase operativa per bilancioId='||bilancioId
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

 strMessaggio:='Calcolo impegnato competenza UP.Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
              ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
 -- lettura elemento bil di gestione equivalente
 if faseOpCode is not null and faseOpCode!=NVL_STR then
  	if  faseOpCode = FASE_OP_BIL_PREV then
      	-- lettura bilancioId annoBilancio precedente per lettura elemento di bilancio equivalente
            	select bil.bil_id into strict bilIdElemGestEq
                from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
                where per.anno=((annoBilancio::integer)-1)::varchar
                  and per.ente_proprietario_id=enteProprietarioId
                  and bil.periodo_id=per.periodo_id
                  and perTipo.periodo_tipo_id=per.periodo_tipo_id
                  and perTipo.periodo_tipo_code='SY';
    else
        	bilIdElemGestEq:=bilancioId;
    end if;
 else
	 RAISE EXCEPTION '% Fase non valida.',strMessaggio;
 end if;

 -- lettura elemIdGestEq
 strMessaggio:='Calcolo impegnato competenza UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
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
else
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTipoId.';
 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
 from  siac_d_movgest_tipo tipoMovGest
 where tipoMovGest.ente_proprietario_id=enteProprietarioId
 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTsTipoId.';
 select movGestTsTipo.movgest_ts_tipo_id into strict movGestTsTipoId
 from siac_d_movgest_ts_tipo movGestTsTipo
 where movGestTsTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsTipo.movgest_ts_tipo_code=TIPO_IMP_T;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
               ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTsStatoId.';

 select movGestStato.movgest_stato_id into strict movGestStatoId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_A;

 -- 10.08.2020 Sofia jira SIAC-6865
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
               ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestStatoPId.';

 select movGestStato.movgest_stato_id into strict movGestStatoPId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_P;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||id_comp
				  ||'. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	  select d.attoamm_stato_id into strict attoAmmStatoPId
	  from siac_d_atto_amm_stato d
	  where d.ente_proprietario_id=enteProprietarioId
	  and d.attoamm_stato_code=STATO_ATTO_P;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||id_comp
				  ||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINTIVO';

	  select d.attoamm_stato_id into strict attoAmmStatoDId
	  from siac_d_atto_amm_stato d
	  where d.ente_proprietario_id=enteProprietarioId
	  and  d.attoamm_stato_code=STATO_ATTO_D;

	select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	  from siac_d_movgest_stato movGestStato
	  where movGestStato.ente_proprietario_id=enteProprietarioId
	  and   movGestStato.movgest_stato_code=STATO_P;

	select d.mod_stato_id into strict modStatoVId
	  from siac_d_modifica_stato d
	  where d.ente_proprietario_id=enteProprietarioId
	  and   d.mod_stato_code=STATO_MOD_V;



 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
               ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTsDetTipoId.';

 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
              ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'. Inizio ciclo per anno_in='||anno_in||'.';
 for movGestIdRec in
 (
     select movGestRel.movgest_id
     from siac_r_movgest_bil_elem movGestRel
     where movGestRel.elem_id=elemIdGestEq
     and   movGestRel.data_cancellazione is null
	 and movGestRel.elem_det_comp_tipo_id=id_comp
     and   exists (select 1 from siac_t_movgest movGest
   				   where movGest.movgest_id=movGestRel.movgest_id
			       and	 movGest.bil_id = bilIdElemGestEq
			       and   movGest.movgest_tipo_id=movGestTipoId
				   and   movGest.movgest_anno = anno_in::integer
                   and   movGest.data_cancellazione is null
                   and   movGest.validita_fine is null)
 )
 loop
   	importoCurAttuale:=0;

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
				      ||'.Per elemento gest equivalente elem_id='||elemIdGestEq
                      ||'.Calcolo impegnato anno_in='||anno_in
                      ||'.Lettura siac_t_movgest_ts movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';

    select movgestts.movgest_ts_id into  movGestTsId
    from siac_t_movgest_ts movGestTs
    where movGestTs.movgest_id = movGestIdRec.movgest_id
    and   movGestTs.data_cancellazione is null
    and   movGestTs.movgest_ts_tipo_id=movGestTsTipoId
    and   exists (select 1 from siac_r_movgest_ts_stato movGestTsRel
                  where movGestTsRel.movgest_ts_id=movGestTs.movgest_ts_id
                  and   movGestTsRel.movgest_stato_id!=movGestStatoId
                  and   movGestTsRel.validita_fine is null
                  and   movGestTsRel.data_cancellazione is null);



    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
				      ||'.Per elemento gest equivalente elem_id='||elemIdGestEq
                      ||'.Calcolo accertato anno_in='||anno_in||'.Somma siac_t_movgest_ts_det movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';
    if NOT FOUND then
    else
       select coalesce(sum(movGestTsDet.movgest_ts_det_importo),0) into importoCurAttuale
           from siac_t_movgest_ts_det movGestTsDet
           where movGestTsDet.movgest_ts_id=movGestTsId
           and   movGestTsDet.movgest_ts_det_tipo_id=movGestTsDetTipoId;

	   if importoCurAttuale>=0 then

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
						and rbil.elem_det_comp_tipo_id=id_comp::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
						and	 mov.movgest_id=rbil.movgest_id
						and  mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
						and  mov.movgest_anno=anno_in::integer -- anno dell impegno = annoMovimento
						and  mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
						and  ts.movgest_id=mov.movgest_id
						and  rstato.movgest_ts_id=ts.movgest_ts_id
						and  rstato.movgest_stato_id!=movGestStatoId -- Impegno non ANNULLATO
						and  rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
					  and  tsdet.movgest_ts_id=ts.movgest_ts_id
						and  moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and  moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
						and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
						and   tipom.mod_tipo_id=mod.mod_tipo_id
--						and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione -- SIAC-8899 09.05.2023 Sofia
						and   ( tipom.mod_tipo_code <> 'ECONB' and  tipom.mod_tipo_code <> 'REANNO' ) -- SIAC-8899 09.05.2023 Sofia
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
				-- 14.05.2020 Manuel - aggiunto parametro verifica_mod_prov
				if importoModifDelta is null or verifica_mod_prov is false then importoModifDelta:=0; end if;

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
				and rbil.elem_det_comp_tipo_id=id_comp::integer --SIAC-7349
				and	  mov.movgest_id=rbil.movgest_id
				and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
 			   	and   mov.movgest_anno=anno_in::integer
 			   	and   mov.bil_id=bilancioId
				and   ts.movgest_id=mov.movgest_id
				and   rstato.movgest_ts_id=ts.movgest_ts_id
				and   rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
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

    importoAttuale:=importoAttuale+importoCurAttuale-(importoModifDelta);
  --aggiunta per ECONB
	importoAttuale:=importoAttuale+abs(importoModifINS);
 end loop;

 -- 10.08.2020 Sofia Jira SIAC-6865 - inizio
 -- impegni provvisori nati da aggiudiazione non decurtano la disp. a impegnare
 if  verifica_mod_prov=true then
   strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
               ||'. Calcolo impegnato provvisorio per aggiudicazione per anno_in='||anno_in||'.';

   select tb.importo into importoCurAttAggiudicazione
   from
   (
  	select coalesce(sum(det.movgest_ts_det_importo),0)  importo, ts.movgest_ts_tipo_id
    from  siac_r_movgest_bil_elem rmov,
          siac_t_movgest mov,
      	  siac_t_movgest_ts ts,
      	  siac_r_movgest_ts_stato rs_stato,
          siac_t_movgest_ts_det det,
     	  siac_d_movgest_ts_det_tipo tipo_det
      where rmov.elem_id=elemIdGestEq
      and   rmov.elem_det_comp_tipo_id=id_comp::integer
      and 	mov.movgest_id=rmov.movgest_id
      and   mov.bil_id = bilIdElemGestEq
      and   mov.movgest_tipo_id=movGestTipoId
      and   mov.movgest_anno = anno_in::integer
      and   ts.movgest_id=mov.movgest_id
      and   rs_stato.movgest_ts_id=ts.movgest_ts_id
	  and   rs_stato.movgest_stato_id=movGestStatoPId
      and   det.movgest_ts_id=ts.movgest_ts_id
      and   tipo_det.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
      and   tipo_det.movgest_ts_det_tipo_id=movGestTsDetTipoId
      and   exists
      (
        select 1
        from siac_r_movgest_aggiudicazione ragg
        where   ragg.movgest_id_a=mov.movgest_id
        and     ragg.data_cancellazione is null
        and     ragg.validita_fine is null
      )
      and   rs_stato.validita_fine is null
	  and   rmov.data_cancellazione is null
      and   mov.data_cancellazione is null
      and   ts.data_cancellazione is null
      and   det.data_cancellazione is null
     group by ts.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;
    if importoCurAttAggiudicazione is null then importoCurAttAggiudicazione:=0; end if;

    importoAttuale:=importoAttuale-importoCurAttAggiudicazione;
  end if;
  -- 10.08.2020 Sofia Jira SIAC-6865 - fine

end if;

annoCompetenza:=anno_in;
diCuiImpegnato:=importoAttuale;

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
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno_comp(integer, integer, character varying, boolean)
    OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno_comp(integer, integer, character varying, boolean) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno_comp(integer, integer, character varying, boolean) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno_comp(integer, integer, character varying, boolean) TO siac;
