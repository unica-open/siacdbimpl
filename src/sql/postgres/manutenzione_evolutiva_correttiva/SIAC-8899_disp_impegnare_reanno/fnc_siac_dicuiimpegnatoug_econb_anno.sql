/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop FUNCTION if exists siac.fnc_siac_dicuiimpegnatoug_econb_anno
(
  id_in integer,
  anno_in varchar
);

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
