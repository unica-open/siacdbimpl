/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-8899 Sofia 08.05.2023 inizio 

drop FUNCTION if exists siac.fnc_siac_dicuiimpegnatoug_comp_anno
(
  id_in integer,
  anno_in varchar,
  verifica_mod_prov boolean
);

drop FUNCTION if exists siac.fnc_siac_dicuiimpegnatoug_comp_anno_comp 
(
  id_in integer,
  anno_in varchar,
  idcomp_in integer,
  verifica_mod_prov boolean
);

DROP FUNCTION if exists siac.fnc_siac_dicuiimpegnatoup_comp_anno ( integer,character varying);

drop FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno_comp (
  id_in integer,
  id_comp integer,
  anno_in varchar,
  verifica_mod_prov boolean
);

drop FUNCTION if exists siac.fnc_siac_dicuiimpegnatoug_econb_anno
(
  id_in integer,
  anno_in varchar
);

create OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno 
(
  id_in integer,
  anno_in varchar,
  verifica_mod_prov boolean = true
)
RETURNS TABLE (
  annocompetenza varchar,
  dicuiimpegnato numeric
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

STATO_MOD_V  constant varchar:='V';
STATO_ATTO_P constant varchar:='PROVVISORIO';

-- anna_economie inizio
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoModifINS  numeric:=0;
-- anna_economie fine

strMessaggio varchar(1500):=NVL_STR;

bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;

movGestTipoId integer:=0;
movGestTsTipoId integer:=0;
movGestStatoId integer:=0;
movGestTsDetTipoId integer:=0;

movGestTsId integer:=0;

importoAttuale numeric:=0;
importoCurAttuale numeric:=0;
importoModifNeg  numeric:=0;

modStatoVId integer:=0;
attoAmmStatoPId integer:=0;

movGestIdRec record;

esisteRmovgestidelemid INTEGER:=0;

-- 10.08.2020 Sofia jira siac-6865
importoCurAttAggiudicazione numeric:=0;
movGestStatoPId integer:=null;
BEGIN

select el.elem_id into esisteRmovgestidelemid from siac_r_movgest_bil_elem el, siac_t_movgest mv
where
mv.movgest_id=el.movgest_id
and el.elem_id=id_in
and mv.movgest_anno=anno_in::integer
;

 -- 02.02.2016 Sofia JIRA 2947
if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;

if esisteRmovgestidelemid <>0 then

 annoCompetenza:=null;
 diCuiImpegnato:=0;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.Controllo parametri.';

 if anno_in is null or anno_in=NVL_STR then
	 RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
	 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
 end if;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
			   ||'.Calcolo bilancioId enteProprietarioId  annoBilancio.';

 select bil.bil_id,  bil.ente_proprietario_id,  per.anno
        into strict bilancioId, enteProprietarioId, annoBilancio
 from siac_t_bil bil,siac_t_bil_elem bilElem, siac_t_periodo per
 where bilElem.elem_id=id_in
 and   bilElem.data_cancellazione is null
 and   bil.bil_id=bilElem.bil_id
 and   per.periodo_id=bil.periodo_id;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTipoId.';
 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
 from  siac_d_movgest_tipo tipoMovGest
 where tipoMovGest.ente_proprietario_id=enteProprietarioId
 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsTipoId.';
/* select movGestTsTipo.movgest_ts_tipo_id into strict movGestTsTipoId
 from siac_d_movgest_ts_tipo movGestTsTipo
 where movGestTsTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsTipo.movgest_ts_tipo_code=TIPO_IMP_T;
*/
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestStatoId.';

 select movGestStato.movgest_stato_id into strict movGestStatoId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_A;



 -- 10.08.2020 Sofia Jira SIAC-6865
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestStatoPId.';

 select movGestStato.movgest_stato_id into strict movGestStatoPId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_P;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsDetTipoId.';

 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

 -- 16.03.2017 Sofia JIRA-SIAC-4614
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo modStatoVId.';
 select d.mod_stato_id into strict modStatoVId
 from siac_d_modifica_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.mod_stato_code=STATO_MOD_V;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo attoAmmStatoPId.';
 select d.attoamm_stato_id into strict attoAmmStatoPId
 from siac_d_atto_amm_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.attoamm_stato_code=STATO_ATTO_P;
 -- 16.03.2017 Sofia JIRA-SIAC-4614

 -- anna_economie inizio
 select d.attoamm_stato_id into strict attoAmmStatoDId
 from siac_d_atto_amm_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.attoamm_stato_code=STATO_ATTO_D;
 -- anna_economie fine

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Inizio calcolo totale importo attuale impegni per anno_in='||anno_in||'.';

 --nuovo G
   	importoCurAttuale:=0;

    select tb.importo into importoCurAttuale
 from (
  select
      coalesce(sum(e.movgest_ts_det_importo),0)  importo
      , c.movgest_ts_tipo_id
    from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id=a.movgest_id and
      a.elem_id=id_in
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
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
    group by
   c.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;
raise notice 'importoCurAttuale=%',importoCurAttuale;
/*select tb.importo into importoCurAttuale from (
  select
      coalesce(sum(e.movgest_ts_det_importo),0)  importo
      , c.movgest_ts_tipo_id
      from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id= ANY (VALUES (a.movgest_id)) and
      a.elem_id=id_in
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
      and c.movgest_id=b.movgest_id
      and d.movgest_ts_id=c.movgest_ts_id
      and d.validita_fine is null
      and e.movgest_ts_id=c.movgest_ts_id
	and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
     and e.data_cancellazione is null
     and f.movgest_ts_det_tipo_id=ANY (VALUES (e.movgest_ts_det_tipo_id))
    and e.movgest_ts_det_tipo_id=ANY (VALUES (movGestTsDetTipoId))
    group by c.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    and t.movgest_ts_tipo_code=TIPO_IMP_T;--'T'; */

 /* select
      coalesce(sum(e.movgest_ts_det_importo),0) into importoCurAttuale
      from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id= ANY (VALUES (a.movgest_id)) and
      a.elem_id=id_in
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
      and c.movgest_id=b.movgest_id
      and d.movgest_ts_id=c.movgest_ts_id
      and e.movgest_ts_id=c.movgest_ts_id
	and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
     and e.data_cancellazione is null
     and f.movgest_ts_det_tipo_id=ANY (VALUES (e.movgest_ts_det_tipo_id))
    and e.movgest_ts_det_tipo_id=ANY (VALUES (movGestTsDetTipoId));*/

  --raise notice 'importoCurAttuale:%', importoCurAttuale;
 --fine nuovo G
 /*for movGestIdRec in
 (
     select movGestRel.movgest_id
     from siac_r_movgest_bil_elem movGestRel
     where movGestRel.elem_id=id_in
     and   movGestRel.data_cancellazione is null
     and   exists (select 1 from siac_t_movgest movGest
   				   where movGest.movgest_id=movGestRel.movgest_id
			       and	 movGest.bil_id = bilancioId
			       and   movGest.movgest_tipo_id=movGestTipoId
				   and   movGest.movgest_anno = anno_in::integer)
 )
 loop
   	importoCurAttuale:=0;

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
                      ||'.Calcolo impegnato anno_in='||anno_in
                      ||'.Lettura siac_t_movgest_ts movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';

    select movgestts.movgest_ts_id into  movGestTsId
    from siac_t_movgest_ts movGestTs
    where movGestTs.movgest_id = movGestIdRec.movgest_id
    and   movGestTs.data_cancellazione is null
    and   movGestTs.movgest_ts_tipo_id=movGestTsTipoId
    and   exists (select 1 from siac_r_movgest_ts_stato movGestTsRel
                  where movGestTsRel.movgest_ts_id=movGestTs.movgest_ts_id
                  and   movGestTsRel.movgest_stato_id!=movGestStatoId);

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
                      ||'.Calcolo accertato anno_in='||anno_in||'Somma siac_t_movgest_ts_det movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';
    if NOT FOUND then
    else
       select coalesce(sum(movGestTsDet.movgest_ts_det_importo),0) into importoCurAttuale
           from siac_t_movgest_ts_det movGestTsDet
           where movGestTsDet.movgest_ts_id=movGestTsId
           and   movGestTsDet.movgest_ts_det_tipo_id=movGestTsDetTipoId;
    end if;

    importoAttuale:=importoAttuale+importoCurAttuale;
 end loop;*/
 -- 02.02.2016 Sofia JIRA 2947
 if importoCurAttuale is null then importoCurAttuale:=0; end if;

 -- 16.03.2017 Sofia JIRA-SIAC-4614
-- if importoCurAttuale>0 then
 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

  strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Calcolo totale modifiche negative su atti provvisori per anno_in='||anno_in||'.';

 select tb.importo into importoModifNeg
 from
 (
 	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
    	 siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
	     siac_t_movgest_ts_det_mod moddet,
    	 siac_t_modifica mod, siac_r_modifica_stato rmodstato,
	     siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
         siac_d_modifica_tipo tipom
	where rbil.elem_id=id_in
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
	and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
    and   tipom.mod_tipo_id=mod.mod_tipo_id
    --and   tipom.mod_tipo_code <> 'ECONB'  -- 08.05.2023 Sofia SIAC-8899
     -- 08.05.2023 Sofia SIAC-8899
    and   ( tipom.mod_tipo_code <> 'ECONB' AND  tipom.mod_tipo_code <> 'REANNO' )
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
  AND   tipo.movgest_ts_tipo_code='T' -- SIAC-8349 Sofia 15.09.2021
  order by tipo.movgest_ts_tipo_code desc
  limit 1;
  -- 21.06.2017 Sofia - aggiunto parametro verifica_mod_prov, ripreso da prod CmTo dove era stato implementato
  if importoModifNeg is null or verifica_mod_prov is false then importoModifNeg:=0; end if;
raise notice 'importoModifNeg=%',importoModifNeg;
  -- 10.08.2020 Sofia jira SIAC-6865 - inizio
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
      where rmov.elem_id=id_in
      and 	mov.movgest_id=rmov.movgest_id
      and   mov.bil_id = bilancioId
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
  end if;
  -- 10.08.2020 Sofia jira SIAC-6865 - fine
raise notice 'importoCurAttAggiudicazione=%',importoCurAttAggiudicazione;

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
      where rbil.elem_id=id_in
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
      -- SIAC-7349
      -- abbiamo tolto il commento nella riga qui sotto perche' d'accordo con Pietro Gambino
      -- e visto che possono anche esserci modifiche ECONB positive
      -- e' bene escluderle dal calcolo importoModifINS
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
    AND   tipo.movgest_ts_tipo_code='T' -- SIAC-8349 Sofia 15.09.2021
    order by tipo.movgest_ts_tipo_code desc
    limit 1;

    if importoModifINS is null then importoModifINS:=0; end if;

  -- anna_economie fine

 end if;
raise notice 'importoModifINS=%',importoModifINS;

raise notice 'importoAttuale0=%',importoAttuale;

 --nuovo G
 importoAttuale:=importoAttuale+importoCurAttuale+abs(importoModifNeg); -- 16.03.2017 Sofia JIRA-SIAC-4614
 --fine nuovoG
raise notice 'importoAttuale1=%',importoAttuale;

 -- anna_economie inizio
 importoAttuale:=importoAttuale+abs(importoModifINS);
 -- anna_economie fine
raise notice 'importoAttuale2=%',importoAttuale;

 -- 10.08.2020 Sofia jira siac-6865
 importoAttuale:=importoAttuale-importoCurAttAggiudicazione;
raise notice 'importoAttuale3=%',importoAttuale;

 annoCompetenza:=anno_in;
 diCuiImpegnato:=importoAttuale;

 return next;

else

annoCompetenza:=anno_in;
diCuiImpegnato:=0;

return next;

end if;

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

ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno(integer, character varying, boolean)
    OWNER TO siac;
	
CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno_comp (
  id_in integer,
  anno_in varchar,
  idcomp_in integer,
  verifica_mod_prov boolean = true
)
RETURNS TABLE (
  annocompetenza varchar,
  dicuiimpegnato numeric
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

STATO_MOD_V  constant varchar:='V';
STATO_ATTO_P constant varchar:='PROVVISORIO';

-- anna_economie inizio
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoModifINS  numeric:=0;
-- anna_economie fine

strMessaggio varchar(1500):=NVL_STR;

bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;

movGestTipoId integer:=0;
movGestTsTipoId integer:=0;
movGestStatoId integer:=0;
movGestTsDetTipoId integer:=0;

movGestTsId integer:=0;

importoAttuale numeric:=0;
importoCurAttuale numeric:=0;
importoModifNeg  numeric:=0;

modStatoVId integer:=0;
attoAmmStatoPId integer:=0;

movGestIdRec record;

esisteRmovgestidelemid INTEGER:=0;

-- 10.08.2020 Sofia jira siac-6865
importoCurAttAggiudicazione numeric:=0;
movGestStatoPId integer:=null;

BEGIN

select el.elem_id into esisteRmovgestidelemid from siac_r_movgest_bil_elem el, siac_t_movgest mv
where
mv.movgest_id=el.movgest_id
and el.elem_id=id_in
and mv.movgest_anno=anno_in::integer
and el.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
;

 -- 02.02.2016 Sofia JIRA 2947
if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;

if esisteRmovgestidelemid <>0 then

 annoCompetenza:=null;
 diCuiImpegnato:=0;

 strMessaggio:='Calcolo impegnato di competenza elem_id='||id_in||'.Controllo parametri.';

 if anno_in is null or anno_in=NVL_STR then
	 RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
	 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
 end if;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
			   ||'.Calcolo bilancioId enteProprietarioId  annoBilancio.';

 select bil.bil_id,  bil.ente_proprietario_id,  per.anno
        into strict bilancioId, enteProprietarioId, annoBilancio
 from siac_t_bil bil,siac_t_bil_elem bilElem, siac_t_periodo per
 where bilElem.elem_id=id_in
 and   bilElem.data_cancellazione is null
 and   bil.bil_id=bilElem.bil_id
 and   per.periodo_id=bil.periodo_id;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTipoId.';
 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
 from  siac_d_movgest_tipo tipoMovGest
 where tipoMovGest.ente_proprietario_id=enteProprietarioId
 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsTipoId.';

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestStatoId.';

 select movGestStato.movgest_stato_id into strict movGestStatoId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_A;

 -- 10.08.2020 Sofia Jira SIAC-6865
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestStatoPId.';

 select movGestStato.movgest_stato_id into strict movGestStatoPId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_P;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsDetTipoId.';

 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

 -- 16.03.2017 Sofia JIRA-SIAC-4614
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo modStatoVId.';
 select d.mod_stato_id into strict modStatoVId
 from siac_d_modifica_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.mod_stato_code=STATO_MOD_V;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo attoAmmStatoPId.';
 select d.attoamm_stato_id into strict attoAmmStatoPId
 from siac_d_atto_amm_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.attoamm_stato_code=STATO_ATTO_P;
 -- 16.03.2017 Sofia JIRA-SIAC-4614

 -- anna_economie inizio
 select d.attoamm_stato_id into strict attoAmmStatoDId
 from siac_d_atto_amm_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.attoamm_stato_code=STATO_ATTO_D;
 -- anna_economie fine

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Inizio calcolo totale importo attuale impegni per anno_in='||anno_in||'.';

 --nuovo G
   	importoCurAttuale:=0;

    select tb.importo into importoCurAttuale
 from (
  select
      coalesce(sum(e.movgest_ts_det_importo),0)  importo
      , c.movgest_ts_tipo_id
    from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id=a.movgest_id and
      a.elem_id=id_in and
	  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
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
    group by
   c.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;


 -- 02.02.2016 Sofia JIRA 2947
 if importoCurAttuale is null then importoCurAttuale:=0; end if;

 -- 16.03.2017 Sofia JIRA-SIAC-4614
-- if importoCurAttuale>0 then
 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

  strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Calcolo totale modifiche negative su atti provvisori per anno_in='||anno_in||'.';

 select tb.importo into importoModifNeg
 from
 (
 	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
    	 siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
	     siac_t_movgest_ts_det_mod moddet,
    	 siac_t_modifica mod, siac_r_modifica_stato rmodstato,
	     siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
         siac_d_modifica_tipo tipom
	where rbil.elem_id=id_in
	 and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
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
	and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
    and   tipom.mod_tipo_id=mod.mod_tipo_id
    --and   tipom.mod_tipo_code <> 'ECONB' -- 08.05.2023 Sofia SIAC-8899
    -- 08.05.2023 Sofia SIAC-8899
    and  (tipom.mod_tipo_code <> 'ECONB' and tipom.mod_tipo_code <> 'REANNO') 
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
  AND   tipo.movgest_ts_tipo_code='T' -- SIAC-8349 Sofia 15.09.2021
  order by tipo.movgest_ts_tipo_code desc
  limit 1;
  -- 21.06.2017 Sofia - aggiunto parametro verifica_mod_prov, ripreso da prod CmTo dove era stato implementato
  if importoModifNeg is null or verifica_mod_prov is false then importoModifNeg:=0; end if;

-- 10.08.2020 Sofia jira SIAC-6865 - inizio
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
      where rmov.elem_id=id_in
      and   rmov.elem_det_comp_tipo_id=idcomp_in::integer
      and 	mov.movgest_id=rmov.movgest_id
      and   mov.bil_id = bilancioId
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
  end if;
  -- 10.08.2020 Sofia jira SIAC-6865 - fine

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
	where rbil.elem_id=id_in
	and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
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
  AND   tipo.movgest_ts_tipo_code='T' -- SIAC-8349 Sofia 15.09.2021
  order by tipo.movgest_ts_tipo_code desc
  limit 1;

  if importoModifINS is null then importoModifINS:=0; end if;

  -- anna_economie fine

 end if;

 --nuovo G
 importoAttuale:=importoAttuale+importoCurAttuale+abs(importoModifNeg); -- 16.03.2017 Sofia JIRA-SIAC-4614
 --fine nuovoG

 -- anna_economie inizio
 importoAttuale:=importoAttuale+abs(importoModifINS);
 -- anna_economie fine

 -- 10.08.2020 Sofia jira siac-6865
 importoAttuale:=importoAttuale-importoCurAttAggiudicazione;

 annoCompetenza:=anno_in;
 diCuiImpegnato:=importoAttuale;

 return next;

else

annoCompetenza:=anno_in;
diCuiImpegnato:=0;

return next;

end if;

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

ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno_comp(integer, varchar, integer, boolean)
    OWNER TO siac;
	
CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno(id_in integer, anno_in character varying, verifica_mod_prov boolean DEFAULT true)
 RETURNS TABLE(annocompetenza character varying, dicuiimpegnato numeric)
AS 
$body$
DECLARE

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

attoAmmStatoDId integer:=0; -- SIAC-7349
attoAmmStatoPId integer:=0;-- SIAC-7349
bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;
modStatoVId integer:=0; -- SIAC-7349
movGestTipoId integer:=0;
movGestTsTipoId integer:=0;
movGestStatoId integer:=0;movGestTsDetTipoId integer:=0;
movGestStatoIdProvvisorio integer:=0; -- SIAC-7349
movGestTsId integer:=0;

importoAttuale numeric:=0;
importoCurAttuale numeric:=0;
importoModifDelta  numeric:=0;
importoModifINS numeric:=0; -- SIAC-7349 --aggiunta per ECONB

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


-- SIAC-7349 INIZIO
strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	  select d.attoamm_stato_id into strict attoAmmStatoPId
	  from siac_d_atto_amm_stato d
	  where d.ente_proprietario_id=enteProprietarioId
	  and d.attoamm_stato_code=STATO_ATTO_P;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINTIVO';

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
-- SIAC-7349 FINE

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
	   -- SIAC-7349 INIZIO
          
/*  SIAC-8493 03.12.2021 Sofia spostato fuori ciclo      
    if importoCurAttuale>=0 then
              ----------------
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
	          		and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
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
		                and	 mov.movgest_id=rbil.movgest_id
		                and  mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
	                  and  mov.movgest_anno=anno_in::integer
	                  and  mov.bil_id=bilancioId
		                and  ts.movgest_id=mov.movgest_id
		                and  rstato.movgest_ts_id=ts.movgest_ts_id
		                and  rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
		                and  tsdet.movgest_ts_id=ts.movgest_ts_id
		                and  moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
		                and  moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
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
            end if; SIAC-8493 03.12.2021 Sofia spostato fuori ciclo   - fine   */
    end if;
   importoAttuale:=importoAttuale+importoCurAttuale;
 
  -- SIAC-8493 03.12.2021 Sofia spostato fuori ciclo    
  --importoAttuale:=importoAttuale+importoCurAttuale-(importoModifDelta);

  -- SIAC-8493 03.12.2021 Sofia spostato fuori ciclo    
  --aggiunta per ECONB
  --importoAttuale:=importoAttuale+abs(importoModifINS);

 end loop;
 
 -- SIAC-8493 03.12.2021 Sofia spostato fuori ciclo    
 raise notice 'importoAttuale=%',importoAttuale::varchar;
 if  verifica_mod_prov=true then
  strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
               ||'. Calcolo modifiche negative per anno_in='||anno_in||'.';
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
--  		and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione -- SIAC-8899 09.05.2023 Sofia 
  		and  (tipom.mod_tipo_code <> 'ECONB' and tipom.mod_tipo_code <> 'REANNO') -- SIAC-8899 09.05.2023 Sofia 
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
   
      if importoModifDelta is null or verifica_mod_prov is false then importoModifDelta:=0; end if;
      raise notice 'importoModifDelta=%',importoModifDelta::varchar;

      -- aggiunta negative	
      importoAttuale:=importoAttuale-(importoModifDelta);

      raise notice 'importoAttuale=%',importoAttuale::varchar;

      strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
               ||'. Calcolo modifiche negative ECONB per anno_in='||anno_in||'.';  
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
		and	 mov.movgest_id=rbil.movgest_id
		and  mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
		and  mov.movgest_anno=anno_in::integer
		and  mov.bil_id=bilancioId
		and  ts.movgest_id=mov.movgest_id
		and  rstato.movgest_ts_id=ts.movgest_ts_id
		and  rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
		and  tsdet.movgest_ts_id=ts.movgest_ts_id
		and  moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
		and  moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
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
      raise notice 'importoModifINS=%',importoModifINS::varchar;

      --aggiunta per ECONB
      importoAttuale:=importoAttuale+abs(importoModifINS);
	  raise notice 'importoAttuale=%',importoAttuale::varchar;
 end if;
 -- SIAC-8493 03.12.2021 Sofia spostato fuori ciclo - fine

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
    raise notice 'importoCurAttAggiudicazione=%',importoCurAttAggiudicazione::varchar;
    importoAttuale:=importoAttuale-importoCurAttAggiudicazione;
    raise notice 'importoAttuale=%',importoAttuale::varchar;
  end if;
  -- 10.08.2020 Sofia Jira SIAC-6865 - fine

end if;


-- SIAC-8493 03.12.2021 Sofia spostato fuori ciclo
raise notice '@@@@@ in uscita importoAttuale=%',importoAttuale::varchar;
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

ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno (integer, varchar, boolean)
  OWNER TO siac;
  
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


create OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoug_econb_anno 
(
  id_in integer,
  anno_in varchar
)
RETURNS TABLE 
(
  annocompetenza varchar,
  dicuiimpegnato_econb numeric
) AS
$body$
DECLARE



strMessaggio varchar(1500):='';

bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;

importoModifNeg  numeric:=0;
importoModifEconb  numeric:=0;

esisteMovPerElemId INTEGER:=0;

BEGIN

strMessaggio:='Calcolo totale movimenti modifiche negative prov e econb elem_id='||id_in||'.Inizio.';
annoCompetenza:=anno_in;
diCuiImpegnato_EconB:=0;

strMessaggio:='Calcolo totale movimenti modifiche negative prov e econb elem_id='||id_in||'.Verifica esistenza movimenti..';
select 1 into esisteMovPerElemId 
from siac_r_movgest_bil_elem re, siac_t_movgest mov
where re.elem_id=id_in
and     mov.movgest_id=re.movgest_id
and     mov.movgest_anno=anno_in::integer
and     re.data_cancellazione  is null 
and     re.validita_fine  is null;
if esisteMovPerElemId is null then esisteMovPerElemId:=0; end if;
raise notice 'esisteMovPerElemId=%',esisteMovPerElemId;

if esisteMovPerElemId <>0 then



 strMessaggio:='Calcolo totale movimenti modifiche negative prov e econb elem_id='||id_in||'.Controllo parametri.';

 if anno_in is null or anno_in='' then
	 RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
	 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
 end if;

 strMessaggio:='Calcolo totale movimenti modifiche negative prov e econb elem_id='||id_in
			   ||'.Calcolo bilancioId enteProprietarioId  annoBilancio.';

 select bil.bil_id,  bil.ente_proprietario_id,  per.anno
 into strict bilancioId, enteProprietarioId, annoBilancio
 from siac_t_bil bil,siac_t_bil_elem bilElem, siac_t_periodo per
 where bilElem.elem_id=id_in
 and      bilElem.data_cancellazione is null
 and      bil.bil_id=bilElem.bil_id
 and      per.periodo_id=bil.periodo_id;


 strMessaggio:='Calcolo totale movimenti modifiche negative prov e econb elem_id='||id_in||'. Inizio calcolo totale modifiche negative prov. per anno_in='||anno_in||'.';
 raise notice 'strMessaggio %',strMessaggio;
 select tb.importo  into importoModifNeg
 from
 (
 	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id 
	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
	       	  siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
	          siac_t_movgest_ts_det_mod moddet,
    	 	  siac_t_modifica mod, siac_r_modifica_stato rmodstato,
	  	      siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
              siac_d_modifica_tipo tipom,
              siac_d_movgest_tipo tipo ,
              siac_d_movgest_stato stato ,
              siac_d_modifica_stato stato_modif,
              siac_d_atto_amm_stato stato_atto
	where  rbil.elem_id= id_in -- <elem_id_in >
	and	      mov.movgest_id=rbil.movgest_id
	and  	  mov.movgest_tipo_id=tipo.movgest_tipo_id 
	and   	  tipo.movgest_tipo_code ='I'
    and       mov.movgest_anno=anno_in::integer -- <annoCompetenza>
    and       mov.bil_id=bilancioId
	and   	  ts.movgest_id=mov.movgest_id
	and       rstato.movgest_ts_id=ts.movgest_ts_id
	and       rstato.movgest_stato_id=stato.movgest_stato_id 
	and   	  stato.movgest_stato_code !='A'
	and   	  tsdet.movgest_ts_id=ts.movgest_ts_id
	and  	  moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	and  	  moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	and  	  moddet.movgest_ts_det_importo<0 -- importo negativo
	and   	  rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	and   	  rmodstato.mod_stato_id=stato_modif.mod_stato_id 
	and   	  stato_modif.mod_stato_code ='V'
	and       mod.mod_id=rmodstato.mod_id
	and  	  atto.attoamm_id=mod.attoamm_id
	and   	  attostato.attoamm_id=atto.attoamm_id
	and   	  attostato.attoamm_stato_id=stato_atto.attoamm_stato_id 
    and   	  stato_atto.attoamm_stato_code ='PROVVISORIO'
    and   	  tipom.mod_tipo_id=mod.mod_tipo_id
    --and   	  tipom.mod_tipo_code <> 'ECONB' -- 10.05.2023 Sofia Jira SIAC-8899
    and   	  ( tipom.mod_tipo_code <> 'ECONB'   AND tipom.mod_tipo_code <> 'REANNO' ) -- 10.05.2023 Sofia Jira SIAC-8899
    and    	  not exists 
    (
    select 1 
    from siac_r_movgest_aggiudicazione  ragg 
    where ragg.movgest_id_da =mov.movgest_id 
    and     ragg.data_cancellazione  is null 
    and     ragg.validita_fine is null 
    )
	and 	  rbil.data_cancellazione is null
	and 	  rbil.validita_fine is null
	and		  mov.data_cancellazione is null
	and		  mov.validita_fine is null
	and 	  ts.data_cancellazione is null
	and 	  ts.validita_fine is null
	and 	  rstato.data_cancellazione is null
	and 	  rstato.validita_fine is null
	and 	  tsdet.data_cancellazione is null
	and 	  tsdet.validita_fine is null
	and 	  moddet.data_cancellazione is null
	and 	  moddet.validita_fine is null
	and 	  mod.data_cancellazione is null
	and 	  mod.validita_fine is null
	and       rmodstato.data_cancellazione is null
	and		  rmodstato.validita_fine is null
	and 	  attostato.data_cancellazione is null
	and 	  attostato.validita_fine is null
	and 	  atto.data_cancellazione is null
	and 	  atto.validita_fine is null
    group by ts.movgest_ts_tipo_id
  ) tb, siac_d_movgest_ts_tipo tipo
  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
  AND   tipo.movgest_ts_tipo_code='T';
  if importoModifNeg is null then importoModifNeg:=0; end if;
  
  raise notice 'importoModifNeg=%',importoModifNeg::varchar;
 
  strMessaggio:='Calcolo totale movimenti modifiche negative prov e econb elem_id='||id_in||'. Inizio calcolo totale modifiche econb  per anno_in='||anno_in||'.';
  raise notice 'strMessaggio %',strMessaggio;
 select tb.importo into importoModifEconb
  from
 (
 	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
       	       siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
	           siac_t_movgest_ts_det_mod moddet,
	       	   siac_t_modifica mod, siac_r_modifica_stato rmodstato,
  	           siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
               siac_d_modifica_tipo tipom,
	           siac_d_movgest_tipo tipo ,
               siac_d_movgest_stato stato ,
	           siac_d_modifica_stato stato_modif,
               siac_d_atto_amm_stato stato_atto
	where  rbil.elem_id= id_in -- <elem_id_id>
 	and	      mov.movgest_id=rbil.movgest_id
	and       mov.movgest_tipo_id=tipo.movgest_tipo_id 
	and       tipo.movgest_tipo_code ='I'
    and       mov.movgest_anno=anno_in::integer -- <annoCompetenza>
    and       mov.bil_id=bilancioId
	and       ts.movgest_id=mov.movgest_id
	and       rstato.movgest_ts_id=ts.movgest_ts_id
	and       rstato.movgest_stato_id=stato.movgest_stato_id 
	and       stato.movgest_stato_code !='A'
	and       tsdet.movgest_ts_id=ts.movgest_ts_id
	and       moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	and       moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	and       moddet.movgest_ts_det_importo<0 -- importo negativo
	and       rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	and       rmodstato.mod_stato_id=stato_modif.mod_stato_id 
	and       stato_modif.mod_stato_code ='V'
	and       mod.mod_id=rmodstato.mod_id
	and       atto.attoamm_id=mod.attoamm_id
	and       attostato.attoamm_id=atto.attoamm_id
	and       attostato.attoamm_stato_id=stato_atto.attoamm_stato_id 
    and       stato_atto.attoamm_stato_code in ('PROVVISORIO','DEFINITIVO')
    and       tipom.mod_tipo_id=mod.mod_tipo_id
    and       tipom.mod_tipo_code = 'ECONB'
	and       rbil.data_cancellazione is null
	and       rbil.validita_fine is null
	and       mov.data_cancellazione is null
	and       mov.validita_fine is null
	and       ts.data_cancellazione is null
	and       ts.validita_fine is null
	and       rstato.data_cancellazione is null
	and       rstato.validita_fine is null
	and       tsdet.data_cancellazione is null
	and       tsdet.validita_fine is null
	and       moddet.data_cancellazione is null
	and       moddet.validita_fine is null
	and       mod.data_cancellazione is null
	and       mod.validita_fine is null
	and       rmodstato.data_cancellazione is null
	and       rmodstato.validita_fine is null
	and       attostato.data_cancellazione is null
	and       attostato.validita_fine is null
	and       atto.data_cancellazione is null
	and       atto.validita_fine is null
    group by ts.movgest_ts_tipo_id
  ) tb, siac_d_movgest_ts_tipo tipo
  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
  AND   tipo.movgest_ts_tipo_code='T';
  if importoModifEconb is null then importoModifEconb:=0; end if;
  raise notice 'importoModifEconb=%',importoModifEconb::varchar;


  annoCompetenza:=anno_in;
  diCuiImpegnato_EconB:=importoModifNeg+importoModifEconb;

else

   annoCompetenza:=anno_in;
   diCuiImpegnato_EconB:=0;
   raise notice 'Movimento non esistenti.';
end if;

raise notice 'anno_in=%',anno_in;
raise notice 'diCuiImpegnato_EconB=%',diCuiImpegnato_EconB::varchar;

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

ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoug_econb_anno(integer, varchar)   OWNER TO siac;


-- SIAC-8899 Sofia 08.05.2023 fine 