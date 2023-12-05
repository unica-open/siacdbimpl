/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_stanz_effettivo_up_anno_comp (
  id_in integer,
  id_comp integer,
  anno_comp_in varchar
  
)
RETURNS TABLE (
  elemid integer,
  annocompetenza varchar,
  stanzeffettivo numeric,
  stanzeffettivocassa numeric,
  massimoimpegnabile numeric
)
LANGUAGE 'plpgsql'
COST 100
VOLATILE
ROWS 1000
AS $BODY$
DECLARE


-- constant
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';
STA_IMP_SCA     constant varchar:='SCA';
STA_IMP_MI     constant varchar:='MI'; -- tipo importo massimo impegnabile

-- fasi di bilancio
FASE_BIL_PREV  constant varchar:='P'; -- previsione
FASE_BIL_PROV  constant varchar:='E'; -- esercizio provvisorio
FASE_BIL_GEST  constant varchar:='G'; -- esercizio gestione
FASE_BIL_CONS  constant varchar:='O'; -- esercizio consuntivo
FASE_BIL_CHIU  constant varchar:='C'; -- esercizio chiuso

-- stati variazioni di importo
STATO_VAR_G    constant varchar:='G'; -- GIUNTA
STATO_VAR_C    constant varchar:='C'; -- CONSIGLIO
STATO_VAR_D    constant varchar:='D'; -- DEFINITIVA
STATO_VAR_B    constant varchar:='B'; -- BOZZA
--- 31.03.2016 Sofia SIAC-3304 aggiunto stato P
STATO_VAR_P    constant varchar:='P'; -- PRE-DEFINITIVO

bilancioId integer:=0;
bilElemId  integer:=0;
bilElemGestId  integer:=0;

strMessaggio varchar(1500):=NVL_STR;

bilFaseOperativa varchar(10):=NVL_STR;
annoBilancio varchar(10):=NVL_STR;

stanziamentoPrev numeric:=0;
stanziamentoPrevCassa numeric:=0;
stanziamento numeric:=0;
stanziamentoEff numeric:=0;
deltaMenoPrev numeric:=0;
varImpGestione numeric:=0;
deltaMenoGest numeric:=0;
deltaMenoPrevCassa numeric:=0;
varImpGestioneCassa numeric:=0;
deltaMenoGestCassa numeric:=0;
stanziamentoEffCassa numeric:=0;
stanziamentoCassa numeric:=0;
stanzMassimoImpegnabile numeric:=null;
enteProprietarioId INTEGER:=0;
periodoId integer:=0;
periodoCompId integer:=0;

BEGIN

     annoCompetenza:=null;
     stanzEffettivo:=null;
     stanzEffettivoCassa:=null;
     elemId:=null;
     massimoImpegnabile:=null;

      -- controllo parametri
      -- anno_comp_in obbligatorio
      -- se id_in non serve altro
      -- diversamente deve essere passato
      -- ente_prop_id, anno_in o bil_id_in
      --  e  la chiave logica del capitolo
      -- ele_code_in,ele_code2_in,ele_code3_in

     strMessaggio:='Calcolo stanziamento effettivo.Controllo parametri.';

     if anno_comp_in is null or anno_comp_in=NVL_STR then
         	RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
     end if;
 
     if id_comp is null or id_comp=0 then
         	RAISE EXCEPTION '% Id componente mancante.',strMessaggio;
     end if;

     if id_in is null or id_in=0 then

          if  ( (bil_id_in is null or bil_id_in=0) and (ente_prop_in is null or ente_prop_in=0)) then
         	     RAISE EXCEPTION '% Id ente proprietario mancante.',strMessaggio;
          end if;

          if ele_code_in is null or ele_code_in=NVL_STR or ele_code2_in is null or ele_code2_in=NVL_STR or ele_code3_in is null or ele_code3_in=NVL_STR then
         	     RAISE EXCEPTION '% Chiave logica elem.Bil. mancante.',strMessaggio;
          end if;

          if ( (bil_id_in is null or bil_id_in=0 ) and (anno_in is null or anno_in=NVL_STR)) then
         	     RAISE EXCEPTION '% Anno bilancio mancante.',strMessaggio;
          end if;
     end if;


     if id_in is not null and id_in!=0 then

          strMessaggio:='Lettura identificativo bilancioId, annoBilancio e enteProprietarioId da elemento di bilancio elem_id='||id_in||'.';
         	select bil.bil_id, per.anno, bilElem.ente_proprietario_id
                    into strict bilancioId, annoBilancio, enteProprietarioId
             from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem,
                  siac_t_bil bil, siac_t_periodo per
             where bilElem.elem_id=id_in
             and   bilElem.data_cancellazione is null
             and   bilElem.validita_fine is null
             and   tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
             and   tipoBilElem.elem_tipo_code = TIPO_CAP_UP
             and   bil.bil_id=bilElem.bil_id
             and   per.periodo_id=bil.periodo_id;
             bilElemId:=id_in;
     else
          if bil_id_in is not null and bil_id_in!=0  then
      	     bilancioId:=bil_id_in;
          end if;
     end if;

     if bilancioId is not null and bilancioId!=0 then
          strMessaggio:='Lettura identificativo annoBilancio enteProprietarioId periodoId elemento di bilancio elem_id='||id_in
                   ||' per bilancioId='||bilancioId||'.';

          select per.anno,  bil.ente_proprietario_id, per.periodo_id into strict annoBilancio, enteProprietarioId, periodoId
          from siac_t_bil bil, siac_t_periodo per
          where bil.bil_id=bilancioId 
                and per.periodo_id=bil.periodo_id;
     end if;

     if bilElemId is null or bilElemId=0 then
          strMessaggio:='Lettura identificativo elemento di bilancio '||ele_code_in||'/'||ele_code2_in||'/'||ele_code3_in||'.';
          if bilancioId is not null and bilancioId!=0 then
      	     strMessaggio:='Lettura identificativo elemento di bilancio '||ele_code_in||'/'||ele_code2_in||'/'||ele_code3_in
                         ||'  per bilancioId='||bilancioId||' .';
               select bilElem.elem_id into strict bilElemId
               from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem
               where bilElem.bil_id=bilancioId
               and   bilElem.elem_code=ele_code_in
               and   bilElem.elem_code2=ele_code2_in
               and   bilElem.elem_code3=ele_code3_in
               and   bilElem.data_cancellazione is null
               and   bilElem.validita_fine is null
               and   tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
               and   tipoBilElem.elem_tipo_code = TIPO_CAP_UP;
          else
     	     strMessaggio:='Lettura identificativo elemento di bilancio '||ele_code_in||'/'||ele_code2_in||'/'||ele_code3_in
                         ||'  bilancioId periodoId per annoBilancioIn='||anno_in||' enteProprietarioIn'||ente_prop_in||' .';
               select bilElem.elem_id, bilelem.bil_id, per.periodo_id into strict bilElemId, bilancioId, periodoId
               from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem,
               siac_t_bil bil, siac_t_periodo per, siac_d_periodo_tipo tipoPer
               where per.anno=anno_in
               and   per.ente_proprietario_id=ente_prop_in
               and   tipoPer.periodo_tipo_id=per.periodo_tipo_id
               and   tipoPer.periodo_tipo_code='SY'
               and   bil.periodo_id=per.periodo_id
               and   bilElem.bil_id=bil.bil_id
               and   bilElem.elem_code=ele_code_in
               and   bilElem.elem_code2=ele_code2_in
               and   bilElem.elem_code3=ele_code3_in
               and   bilElem.data_cancellazione is null
               and   bilElem.validita_fine is null
               and   tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
               and   tipoBilElem.elem_tipo_code = TIPO_CAP_UP;

               annoBilancio:=anno_in;
               enteProprietarioId:=ente_prop_in;

          end if;    
     end if;

     strMessaggio:='Lettura fase di bilancio corrente per  anno bilancio='||annoBilancio||' bilancioId='||bilancioId||'.';
     select faseop.fase_operativa_code into strict bilFaseOperativa
     from siac_d_fase_operativa faseOp, siac_r_bil_fase_operativa bilFaseOp
     where bilfaseop.bil_id=bilancioId 
          and bilfaseop.data_cancellazione is null
          and bilfaseop.validita_fine is null
          and faseOp.fase_operativa_id = bilfaseop.fase_operativa_id
          and faseOp.data_cancellazione is null
          and faseOp.validita_fine is null;


     if bilFaseOperativa not in ( FASE_BIL_PREV, FASE_BIL_PROV, FASE_BIL_GEST,FASE_BIL_CONS,FASE_BIL_CHIU) then
        	RAISE EXCEPTION '% Fase non ammessa per il calcolo richiesto.',strMessaggio;
     end if;

     if anno_comp_in!=annoBilancio then
      	strMessaggio:='Lettura periodoCompId per anno_comp_in='||anno_comp_in||' elem_id='||bilElemId||'.';
          select  per.periodo_id into strict periodoCompId
          from siac_t_periodo per, siac_d_periodo_tipo perTipo
          where per.anno=anno_comp_in
          and   per.ente_proprietario_id=enteProprietarioId
          and   perTipo.periodo_tipo_id=per.periodo_tipo_id
          and   perTipo.periodo_tipo_code='SY';
     else
          periodoCompId:=periodoId;
     end if;

     if bilFaseOperativa = FASE_BIL_PROV then
          strMessaggio:='Lettura elemento di bilancio equivalente di gestione per elem_id='||bilElemId||'.';
          select bilElemGest.elem_id into  bilElemGestId
          from siac_t_bil_elem bilElemPrev, siac_d_bil_elem_tipo tipoGest,
               siac_t_bil_elem bilElemGest
          where bilElemPrev.elem_id=bilElemId
          and bilElemGest.elem_code=bilElemPrev.elem_code
          and bilElemGest.elem_code2=bilElemPrev.elem_code2 
          and bilElemGest.elem_code3=bilElemPrev.elem_code3
          and bilElemGest.ente_proprietario_id=bilElemPrev.ente_proprietario_id
          and bilElemGest.bil_id=bilElemPrev.bil_id
          and bilElemGest.data_cancellazione is null 
          and bilElemGest.validita_fine is null
          and tipoGest.elem_tipo_id=bilElemGest.elem_tipo_id
          and tipoGest.elem_tipo_code=TIPO_CAP_UG;

          if NOT FOUND then
          	bilElemGestId:=0;
          end if;
     end if;

     strMessaggio:='Lettura stanziamenti di previsione per elem_id='||bilElemId||' anno_comp_in='||anno_comp_in||'.';

     /*SIAC - 7349*/
     select comp.elem_det_importo  into strict stanziamentoPrev
     from siac_t_bil_elem_det importiPrev,
     	siac_d_bil_elem_det_tipo tipoImpPrev,
     	siac_t_bil_elem_det_comp comp,
     	siac_d_bil_elem_det_comp_tipo comptipo
     where importiPrev.elem_id=bilElemId
     	and comp.elem_det_id = importiPrev.elem_det_id
          and importiPrev.data_cancellazione is null 
          and importiPrev.validita_fine is null
     	and tipoImpPrev.elem_det_tipo_id=importiPrev.elem_det_tipo_id 
          and tipoImpPrev.elem_det_tipo_code=STA_IMP
     	and comp.data_cancellazione is null and comp.validita_fine is null
          and importiPrev.periodo_id=periodoCompId
     	and comptipo.data_cancellazione is null 
        -- SIAC-7796
		-- and comptipo.validita_fine is null  
     	and comp.elem_det_comp_tipo_id = comptipo.elem_det_comp_tipo_id
     	and comptipo.elem_det_comp_tipo_id = id_comp
	-- SIAC-7349 Aggiunto non exists per escludere le componenti che sono collegate come "nuovi dettagli" tramite variazione in stato diverso da definitivo
		and not (exists (
			select siactbilel4_.elem_det_var_comp_id
			from 	siac_t_bil_elem_det_var_comp siactbilel4_
					cross join siac_t_bil_elem_det_var siactbilel5_
					cross join siac_r_variazione_stato siacrvaria6_
					cross join siac_d_variazione_stato siacdvaria7_
			where 	siactbilel4_.elem_det_var_id=siactbilel5_.elem_det_var_id
				and siactbilel5_.variazione_stato_id=siacrvaria6_.variazione_stato_id
				and siacrvaria6_.variazione_stato_tipo_id=siacdvaria7_.variazione_stato_tipo_id
				and siactbilel4_.elem_det_comp_id=comp.elem_det_comp_id
				and siactbilel4_.elem_det_flag='N'
				and siacdvaria7_.variazione_stato_tipo_code<>'D'
				and siactbilel4_.data_cancellazione is null
				and siactbilel5_.data_cancellazione is null
				and siacrvaria6_.data_cancellazione is null
			));

     if anno_comp_in=annoBilancio then
           strMessaggio:='Lettura stanziamenti di previsione cassa per elem_id='||bilElemId||' anno_comp_in='||anno_comp_in||'.';
           select importiprev.elem_det_importo into strict stanziamentoPrevCassa
           from siac_t_bil_elem_det importiPrev, siac_d_bil_elem_det_tipo tipoImpPrev
           where importiPrev.elem_id=bilElemId
      	     and importiPrev.data_cancellazione is null 
               and importiPrev.validita_fine is null
        	   	and tipoImpPrev.elem_det_tipo_id=importiPrev.elem_det_tipo_id
     	     and tipoImpPrev.elem_det_tipo_code=STA_IMP_SCA
     	     and importiPrev.periodo_id=periodoCompId;
     end if;


  
     if bilFaseOperativa in (FASE_BIL_PROV,FASE_BIL_PREV) then --1
          --- calcolo dei 'delta-previsione', variazioni agli importi del CAP-UP in stato
     	--- diverso da BOZZA,DEFINTIVO,ANNULLATO
        	strMessaggio:='Lettura variazioni delta-meno-prev per elem_id='||bilElemId||' anno_comp_in='||
                            anno_comp_in||'.';
     
     	/*SIAC - 7349*/
         /*ERRORE RISCONTRATO NEL TEST FASE DI PREV - mr*/
	     /*select   coalesce(sum(abs(bilElemDetVarComp.elem_det_importo)),0) into strict deltaMenoPrev
          from siac_t_variazione var,
              	siac_r_variazione_stato statoVar,
	     	siac_d_variazione_stato tipoStatoVar,
               siac_t_bil_elem_det_var bilElemDetVar,
	     	siac_d_bil_elem_det_tipo bilElemDetVarTipo,
               siac_t_bil_elem_det_var_comp bilElemDetVarComp,
               siac_d_bil_elem_det_comp_tipo bilElemDetCompTipo, 
               siac_t_bil_elem_det_comp bilElemDetComp
              where bilElemDetVar.elem_id=bilElemId
             	     and bilElemDetVar.data_cancellazione is null 
                    and bilElemDetVar.validita_fine is null
                    and bilElemDetVar.periodo_id=periodoCompId
	     	     and bilElemDetVar.elem_det_importo<0
  	               and bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id
                    and bilElemDetVarTipo.elem_det_tipo_code=STA_IMP
                    and bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id
                    and statoVar.data_cancellazione is null 
                    and statoVar.validita_fine is null
                    and tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id
                    and tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) -- 1109015 Sofia aggiunto STATO_VAR_B
	     		and tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) -- Sofia 26072016 JIRA-SIAC-3887
                    and var.variazione_id=statoVar.variazione_id
                    and var.data_cancellazione is null and var.validita_fine is null
                    and var.bil_id= bilancioId
	     		and bilElemDetVarComp.data_cancellazione is null and bilElemDetVarComp.validita_fine is null
	     		and bilElemDetComp.data_cancellazione is null and bilElemDetComp.validita_fine is null
                    and bilElemDetVarComp.elem_det_var_id = bilElemDetVar.elem_det_var_id
                    and bilElemDetComp.elem_det_comp_tipo_id =  bilElemDetCompTipo.elem_det_comp_tipo_id
	     		and bilElemDetCompTipo.elem_det_comp_tipo_id = id_comp; --adeguamento*/
          
          select  coalesce(sum(abs(bilElemDetVarComp.elem_det_importo)),0) into strict deltaMenoPrev
			from siac_t_variazione var,
			siac_r_variazione_stato statoVar,
			siac_d_variazione_stato tipoStatoVar,
			siac_t_bil_elem_det_var bilElemDetVar,
			siac_d_bil_elem_det_tipo bilElemDetVarTipo,
			siac_t_bil_elem_det_var_comp bilElemDetVarComp,
			siac_d_bil_elem_det_comp_tipo bilElemDetCompTipo --adeguamento 
			where bilElemDetVar.elem_id=bilElemId and
			bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
			bilElemDetVar.periodo_id=periodoCompId and
			bilElemDetVar.elem_det_importo<0 AND
			bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
			bilElemDetVarTipo.elem_det_tipo_code=STA_IMP and
			bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
			statoVar.data_cancellazione is null and statoVar.validita_fine is null and
			tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
			-- tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) and -- 1109015 Sofia aggiunto STATO_VAR_B
			tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) and -- Sofia 26072016 JIRA-SIAC-3887
			var.variazione_id=statoVar.variazione_id and
			var.data_cancellazione is null and var.validita_fine is null and
			var.bil_id= bilancioId and
			bilElemDetVarComp.data_cancellazione is null and bilElemDetVarComp.validita_fine is null and
			bilElemDetVarComp.elem_det_var_id = bilElemDetVar.elem_det_var_id				
			and bilElemDetCompTipo.elem_det_comp_tipo_id = id_comp;                  

          if  bilFaseOperativa =FASE_BIL_PROV and bilElemGestId!=0 then --2
          --- calcolo variazioni applicate alla gestione, variazioni agli importi CAP-UG
               strMessaggio:='Lettura variazioni di gestione per elem_id='||bilElemGestId||' anno_comp_in='||
                       anno_comp_in||'.';
	
	          select coalesce(sum(bilElemDetVarComp.elem_det_importo),0) into strict varImpGestione
                  from siac_t_variazione var,
                       siac_r_variazione_stato statoVar,
                       siac_d_variazione_stato tipoStatoVar,
                       siac_t_bil_elem_det_var bilElemDetVar,
                       siac_d_bil_elem_det_tipo bilElemDetVarTipo,
                       siac_t_bil_elem_det_var_comp bilElemDetVarComp,
                       siac_d_bil_elem_det_comp_tipo bilElemDetCompTipo, --adeguamento
                       siac_t_bil_elem_det_comp bilElemDetComp
                     -- where bilElemDetVar.elem_id=bilElemId --SIAC-7349 Fix TC su calcolo disponibilita' variare - GS - 10/07/2020
                    where bilElemDetVar.elem_id=bilElemGestId --SIAC-7349 Fix TC su calcolo disponibilita' variare - GS - 10/07/2020
                    and bilElemDetVar.data_cancellazione is null 
                    and bilElemDetVar.validita_fine is null
                    and bilElemDetVar.periodo_id=periodoCompId
  	               and bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id
                    and bilElemDetVarTipo.elem_det_tipo_code=STA_IMP
                    and bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id
                    and statoVar.data_cancellazione is null and statoVar.validita_fine is null
                    and tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id
                    and tipoStatoVar.variazione_stato_tipo_code=STATO_VAR_D
                    and var.variazione_id=statoVar.variazione_id
                    and var.data_cancellazione is null 
                    and var.validita_fine is null
                    and var.bil_id=bilancioId
                    and bilElemDetVarComp.elem_det_var_id = bilElemDetVar.elem_det_var_id
                    and bilElemDetVarComp.elem_det_comp_id = bilElemDetComp.elem_det_comp_id
	          	and bilElemDetComp.elem_det_comp_tipo_id =  bilElemDetCompTipo.elem_det_comp_tipo_id
	          	and bilElemDetCompTipo.elem_det_comp_tipo_id = id_comp --adeguamento
	          	and bilElemDetVarComp.data_cancellazione is null 
                    and bilElemDetVarComp.validita_fine is null 
                    and bilElemDetComp.data_cancellazione is null 
                    and bilElemDetComp.validita_fine is null;


          end if; --2
     end if; --1

     if bilFaseOperativa in ( FASE_BIL_PROV) and bilElemGestId!=0 then


			  strMessaggio:='Lettura stanziamenti di gestione per elem_id='||bilElemGestId||' anno_comp_in='||anno_comp_in||'.';
			--SIAC-7349
				-- SIAC-7796: 	defaultato a zero gli importi nel caso di componente mancante in gestione equivalente 
				-- select comp.elem_det_importo	into strict stanziamento
			  select coalesce(comp.elem_det_importo, 0) into stanziamento
			from siac_t_bil_elem_det importiGest,
			siac_d_bil_elem_det_tipo tipoImp,
			  siac_t_bil_elem_det_comp comp,
			siac_d_bil_elem_det_comp_tipo comptipo
			-- where importiGest.elem_id=bilElemId --SIAC-7349 Fix TC su calcolo disponibilita' variare - GS - 10/07/2020
			where importiGest.elem_id=bilElemGestId --SIAC-7349 Fix TC su calcolo disponibilita' variare - GS - 10/07/2020    	
			and importiGest.data_cancellazione is null 
			  and importiGest.validita_fine is null
				 and tipoImp.elem_det_tipo_id=importiGest.elem_det_tipo_id
			  and tipoImp.elem_det_tipo_code=STA_IMP
				 and importiGest.periodo_id=periodoCompId
			  and comp.elem_det_id = importiGest.elem_det_id
			 and comp.elem_det_comp_tipo_id = comptipo.elem_det_comp_tipo_id
			 and comp.data_cancellazione is null 
			  and comp.validita_fine is null
			  and comptipo.data_cancellazione is null 
			  -- SIAC-7796
			  -- and comptipo.validita_fine is null
			 and comptipo.elem_det_comp_tipo_id = id_comp
			-- SIAC-7349 Aggiunto non exists per escludere le componenti che sono collegate come "nuovi dettagli" tramite variazione in stato diverso da definitivo
			and not (exists (
				select siactbilel4_.elem_det_var_comp_id
				from 	siac_t_bil_elem_det_var_comp siactbilel4_
						cross join siac_t_bil_elem_det_var siactbilel5_
						cross join siac_r_variazione_stato siacrvaria6_
						cross join siac_d_variazione_stato siacdvaria7_
				where 	siactbilel4_.elem_det_var_id=siactbilel5_.elem_det_var_id
					and siactbilel5_.variazione_stato_id=siacrvaria6_.variazione_stato_id
					and siacrvaria6_.variazione_stato_tipo_id=siacdvaria7_.variazione_stato_tipo_id
					and siactbilel4_.elem_det_comp_id=comp.elem_det_comp_id
					and siactbilel4_.elem_det_flag='N'
					and siacdvaria7_.variazione_stato_tipo_code<>'D'
					and siactbilel4_.data_cancellazione is null
					and siactbilel5_.data_cancellazione is null
					and siacrvaria6_.data_cancellazione is null
				));	     

	     
	     
          --- calcolo dei 'delta-gestione', variazioni agli importi del CAP-UG in stato
          --- diverso da BOZZA,DEFINTIVO,ANNULLATO
          strMessaggio:='Lettura variazioni delta-meno-gest per elem_id='||bilElemGestId||' anno_comp_in='||
                           anno_comp_in||'.';
		
     	--SIAC-7349
     	select coalesce(sum(abs(bilElemDetVarComp.elem_det_importo)),0) into strict deltaMenoGest
          from siac_t_variazione var,
          siac_r_variazione_stato statoVar,
          siac_d_variazione_stato tipoStatoVar,
	     siac_t_bil_elem_det_var bilElemDetVar,
          siac_d_bil_elem_det_tipo bilElemDetVarTipo,
          siac_t_bil_elem_det_var_comp bilElemDetVarComp,
          siac_d_bil_elem_det_comp_tipo bilElemDetCompTipo, --adeguamento
          siac_t_bil_elem_det_comp bilElemDetComp
     	  -- where bilElemDetVar.elem_id=bilElemId --SIAC-7349 Fix TC su calcolo disponibilita' variare - GS - 10/07/2020
          where bilElemDetVar.elem_id=bilElemGestId --SIAC-7349 Fix TC su calcolo disponibilita' variare - GS - 10/07/2020    	
          and bilElemDetVar.data_cancellazione is null 
          and bilElemDetVar.validita_fine is null
          and bilElemDetVar.periodo_id=periodoCompId
		and bilElemDetVar.elem_det_importo<0
  	    	and bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id
	     and bilElemDetVarTipo.elem_det_tipo_code=STA_IMP
    	     and bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id
	     and statoVar.data_cancellazione is null 
          and statoVar.validita_fine is null
    	     and tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id
       	--and tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) and --1109015 Sofia aggiunto STATO_VAR_B
      	--and tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) and -- 26072016 Sofia JIRA-SIAC-3887
       	and tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P,STATO_VAR_B) -- 14.102016 Sofia JIRA-SIAC-4099 riaggiunto B
          and var.variazione_id=statoVar.variazione_id
          and var.data_cancellazione is null and var.validita_fine is null
     	and var.bil_id=bilancioId
          and bilElemDetVarComp.elem_det_var_id = bilElemDetVar.elem_det_var_id
          and bilElemDetVarComp.elem_det_comp_id = bilElemDetComp.elem_det_comp_id
     	and bilElemDetVarComp.data_cancellazione is null 
          and bilElemDetVarComp.validita_fine is null  
          and bilElemDetComp.data_cancellazione is null 
          and bilElemDetComp.validita_fine is null  
     	and bilElemDetComp.elem_det_comp_tipo_id =  bilElemDetCompTipo.elem_det_comp_tipo_id
     	and bilElemDetCompTipo.elem_det_comp_tipo_id = id_comp; --adeguamento

     end if;


     stanziamentoPrev:= stanziamentoPrev-deltaMenoPrev;




     strMessaggio:='Stanziamento effettivo elem_id='||bilElemId||'.';
     case
          when bilFaseOperativa=FASE_BIL_PROV then
 --  		
   		     if stanziamentoPrev>stanziamento-deltaMenoGest then
                    stanziamentoEff:=stanziamento-deltaMenoGest;
               else 
                    stanziamentoEff:=stanziamentoPrev;
               end if;

               if anno_comp_in=annoBilancio then
--             if stanziamentoPrevCassa>stanziamentoCassa then 26072016 Sofia JIRA-SIAC-3887
                    if stanziamentoPrevCassa>stanziamentoCassa-deltaMenoGestCassa then
                    /* 04.07.2016 Sofia ID-INC000001114035
        	          stanziamentoEffCassa:=stanziamentoCassa; **/
                         stanziamentoEffCassa:=stanziamentoCassa-deltaMenoGestCassa;
                    else 
                         stanziamentoEffCassa:=stanziamentoPrevCassa;
                    end if;
               end if;
     else

   	     stanziamentoEff:=stanziamentoPrev;
          if anno_comp_in=annoBilancio then
               stanziamentoEffCassa:=stanziamentoPrevCassa;
          end if;

     end case;

  /* 04.07.2016 Sofia ID-INC000001114035
 -- stanziamentoEff abbattutto dai 'delta-gestione'
 stanziamentoEff:=stanziamentoEff-deltaMenoGest;
 if anno_comp_in = annoBilancio then
  stanziamentoEffCassa:=stanziamentoEffCassa-deltaMenoGestCassa;
 end if; */



     elemId:=bilElemId;
     annoCompetenza:=anno_comp_in;
     stanzEffettivo:=stanziamentoEff;
     if anno_comp_in = annoBilancio then
     stanzEffettivoCassa:=stanziamentoEffCassa;
     end if;
     if stanzMassimoImpegnabile is not null then
        	massimoImpegnabile:=stanzMassimoImpegnabile;
     end if;

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
$BODY$;

ALTER FUNCTION siac.fnc_siac_stanz_effettivo_up_anno_comp (id_in integer, id_comp integer, anno_comp_in varchar)
  OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_stanz_effettivo_up_anno_comp (id_in integer, id_comp integer, anno_comp_in varchar) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_stanz_effettivo_up_anno_comp (id_in integer, id_comp integer, anno_comp_in varchar) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_stanz_effettivo_up_anno_comp (id_in integer, id_comp integer, anno_comp_in varchar) TO siac;
