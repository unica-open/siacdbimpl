/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--- calcolo stanziamento effettivo su capitolo di previsione
-- da utilizzarsi dalla fase di bilancio di esercizio di previsione in poi
-- calcolo stanziamento effettivo
 -- esercizio previsione
 -- stanziamento di previsione - 'delta-previsione'
 -- esercizio provvisorio
  -- minimo tra [stanziamento previsione - 'delta-previsione' + variazioni def di gestione]
  --            [stanziamento gestione ]
  -- meno 'delta-gestione'

 -- esercizio 'Gestione, Consuntivo, Chiuso'
  -- stanziamento di previsione

 -- sono calcolati gli stanziamenti effettivi per anno_comp_in
 -- competenza sempre
 -- cassa solo se anno_comp_in=annoBilancio

 -- ai fini del calcolo della disponibilita ad impegnare, in esercizio provvisorio
 -- viene restituito per il primo anno di pluriennale
 -- il massimo impegnabile, presente eventualmente nel tipo importo MI
drop function if exists  siac.fnc_siac_stanz_effettivo_up_anno (
  id_in integer,
  anno_comp_in varchar,
  ente_prop_in integer,
  bil_id_in integer,
  anno_in varchar,
  ele_code_in varchar,
  ele_code2_in varchar,
  ele_code3_in varchar
);
CREATE OR REPLACE FUNCTION siac.fnc_siac_stanz_effettivo_up_anno (
  id_in integer = NULL::integer,
  anno_comp_in varchar = (NOT NULL::boolean),
  ente_prop_in integer = NULL::integer,
  bil_id_in integer = NULL::integer,
  anno_in varchar = NULL::character varying,
  ele_code_in varchar = NULL::character varying,
  ele_code2_in varchar = NULL::character varying,
  ele_code3_in varchar = NULL::character varying
)
RETURNS TABLE (
  elemid integer,
  annocompetenza varchar,
  stanzeffettivo numeric,
  stanzeffettivocassa numeric,
  massimoimpegnabile numeric
) AS
$body$
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
-- 10.10.2022 Sofia Jira-SIAC-8828
STATO_VAR_BD    constant varchar:='BD'; -- BOZZA DEC

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

 if id_in is null or id_in=0 then
 	if  ( (bil_id_in is null or bil_id_in=0) and
          (ente_prop_in is null or ente_prop_in=0))  then
    	RAISE EXCEPTION '% Id ente proprietario mancante.',strMessaggio;
    end if;

    if ele_code_in is null or ele_code_in=NVL_STR or
       ele_code2_in is null or ele_code2_in=NVL_STR or
       ele_code3_in is null or ele_code3_in=NVL_STR then
    	RAISE EXCEPTION '% Chiave logica elem.Bil. mancante.',strMessaggio;
    end if;

    if ( (bil_id_in is null or bil_id_in=0 ) and
         (anno_in is null or anno_in=NVL_STR)) then
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

  select per.anno,  bil.ente_proprietario_id, per.periodo_id
        into strict annoBilancio, enteProprietarioId, periodoId
  from siac_t_bil bil, siac_t_periodo per
  where bil.bil_id=bilancioId and
        per.periodo_id=bil.periodo_id;
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
     select bilElem.elem_id, bilelem.bil_id, per.periodo_id
            into strict bilElemId, bilancioId, periodoId
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

 end  if;




 strMessaggio:='Lettura fase di bilancio corrente per  anno bilancio='||annoBilancio||' bilancioId='||bilancioId||'.';
 select faseop.fase_operativa_code into strict bilFaseOperativa
 from siac_d_fase_operativa faseOp, siac_r_bil_fase_operativa bilFaseOp
 where bilfaseop.bil_id=bilancioId and
       bilfaseop.data_cancellazione is null and
       bilfaseop.validita_fine is null  and
       faseOp.fase_operativa_id = bilfaseop.fase_operativa_id and
       faseOp.data_cancellazione is  null and
       faseOp.validita_fine is null;


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
    where bilElemPrev.elem_id=bilElemId and
          bilElemGest.elem_code=bilElemPrev.elem_code and
          bilElemGest.elem_code2=bilElemPrev.elem_code2 and
          bilElemGest.elem_code3=bilElemPrev.elem_code3 and
          bilElemGest.ente_proprietario_id=bilElemPrev.ente_proprietario_id and
          bilElemGest.bil_id=bilElemPrev.bil_id and
          bilElemGest.data_cancellazione is null and bilElemGest.validita_fine is null and
          tipoGest.elem_tipo_id=bilElemGest.elem_tipo_id and
          tipoGest.elem_tipo_code=TIPO_CAP_UG;

    if NOT FOUND then
	    bilElemGestId:=0;
    end if;

  end if;

  strMessaggio:='Lettura stanziamenti di previsione per elem_id='||bilElemId||' anno_comp_in='||anno_comp_in||'.';
  select importiPrev.elem_det_importo into strict stanziamentoPrev
  from siac_t_bil_elem_det importiPrev, siac_d_bil_elem_det_tipo tipoImpPrev
  where importiPrev.elem_id=bilElemId AND
	    importiPrev.data_cancellazione is null and importiPrev.validita_fine is null and
        tipoImpPrev.elem_det_tipo_id=importiPrev.elem_det_tipo_id and
        tipoImpPrev.elem_det_tipo_code=STA_IMP and
        importiPrev.periodo_id=periodoCompId;

 if anno_comp_in=annoBilancio then
      strMessaggio:='Lettura stanziamenti di previsione cassa per elem_id='||bilElemId||' anno_comp_in='||anno_comp_in||'.';
      select importiprev.elem_det_importo into strict stanziamentoPrevCassa
      from siac_t_bil_elem_det importiPrev, siac_d_bil_elem_det_tipo tipoImpPrev
      where importiPrev.elem_id=bilElemId AND
 	        importiPrev.data_cancellazione is null and importiPrev.validita_fine is null and
   	   	    tipoImpPrev.elem_det_tipo_id=importiPrev.elem_det_tipo_id and
	        tipoImpPrev.elem_det_tipo_code=STA_IMP_SCA and
	        importiPrev.periodo_id=periodoCompId;
 end if;

 --raise 'stanziamentoPrev %',stanziamentoPrev;
  if bilFaseOperativa in (FASE_BIL_PROV,FASE_BIL_PREV) then --1
     --- calcolo dei 'delta-previsione', variazioni agli importi del CAP-UP in stato
	 --- diverso da BOZZA,DEFINTIVO,ANNULLATO
   	 strMessaggio:='Lettura variazioni delta-meno-prev per elem_id='||bilElemId||' anno_comp_in='||
                       anno_comp_in||'.';
     --- 31.03.2016 Sofia SIAC-3304 aggiunto stato P
     select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into strict deltaMenoPrev
     from siac_t_variazione var,
          siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
          siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo
     where bilElemDetVar.elem_id=bilElemId and
    	   bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
           bilElemDetVar.periodo_id=periodoCompId and
           bilElemDetVar.elem_det_importo<0 AND
  	       bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
           bilElemDetVarTipo.elem_det_tipo_code=STA_IMP and
           bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
           statoVar.data_cancellazione is null and statoVar.validita_fine is null and
           tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
--           tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) and --1109015 Sofia aggiunto STATO_VAR_B
           tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) and -- 26072016 Sofia JIRA-SIAC-3887
           var.variazione_id=statoVar.variazione_id and
           var.data_cancellazione is null and var.validita_fine is null and
           var.bil_id=bilancioId;

    if  bilFaseOperativa =FASE_BIL_PROV and bilElemGestId!=0 then --2
     --- calcolo variazioni applicate alla gestione, variazioni agli importi CAP-UG
     strMessaggio:='Lettura variazioni di gestione per elem_id='||bilElemGestId||' anno_comp_in='||
                       anno_comp_in||'.';

     select coalesce(sum(bilElemDetVar.elem_det_importo),0) into strict varImpGestione
     from siac_t_variazione var,
          siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
          siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo
     where bilElemDetVar.elem_id=bilElemGestId and
       	   bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
           bilElemDetVar.periodo_id=periodoCompId and
  	       bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
           bilElemDetVarTipo.elem_det_tipo_code=STA_IMP and
           bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
           statoVar.data_cancellazione is null and statoVar.validita_fine is null and
           tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
           tipoStatoVar.variazione_stato_tipo_code=STATO_VAR_D and
           var.variazione_id=statoVar.variazione_id and
           var.data_cancellazione is null and var.validita_fine is null and
           var.bil_id=bilancioId;


       -- importo massimo impegnabile
       stanzMassimoImpegnabile:=null;
   	   strMessaggio:='Lettura massimo impegnabile per elem_id='||bilElemId||' anno_comp_in='||anno_comp_in||'.';
	   select importiGest.elem_det_importo into  stanzMassimoImpegnabile
	   from siac_t_bil_elem_det importiGest, siac_d_bil_elem_det_tipo tipoImp
       where importiGest.elem_id=bilElemGestId AND
             importiGest.data_cancellazione is null and importiGest.validita_fine is null and
  			 tipoImp.elem_det_tipo_id=importiGest.elem_det_tipo_id and
             tipoImp.elem_det_tipo_code=STA_IMP_MI and
	    	 importiGest.periodo_id=periodoCompId;

    end if; --2

    if anno_comp_in=annoBilancio then --2



      --- calcolo dei 'delta-previsione', variazioni agli importi di cassa del CAP-UP in stato
      --- diverso da BOZZA,DEFINTIVO,ANNULLATO
      strMessaggio:='Lettura variazioni delta-meno-prev cassa per elem_id='||bilElemId||' anno_comp_in='||
                       anno_comp_in||'.';
	  --- 31.03.2016 Sofia SIAC-3304 aggiunto stato P
      select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into strict deltaMenoPrevCassa
      from siac_t_variazione var,
           siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
           siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo
      where bilElemDetVar.elem_id=bilElemId and
      	    bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
            bilElemDetVar.periodo_id=periodoCompId and
	        bilElemDetVar.elem_det_importo<0 AND
  	        bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
            bilElemDetVarTipo.elem_det_tipo_code=STA_IMP_SCA and
            bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
            statoVar.data_cancellazione is null and statoVar.validita_fine is null and
            tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
--            tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) and -- 1109015 Sofia aggiunto STATO_VAR_B
            tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) and -- 26072016 Sofia JIRA-SIAC-3887
            var.variazione_id=statoVar.variazione_id and
            var.data_cancellazione is null and var.validita_fine is null and
            var.bil_id=bilancioId;


     if  bilFaseOperativa =FASE_BIL_PROV and bilElemGestId!=0 then --3
      --- calcolo variazioni applicate alla gestione, variazioni agli importi di casas CAP-UG
      strMessaggio:='Lettura variazioni di gestione cassa per elem_id='||bilElemGestId||' anno_comp_in='||
                       anno_comp_in||'.';

      select coalesce(sum(bilElemDetVar.elem_det_importo),0) into strict varImpGestioneCassa
      from siac_t_variazione var,
       	   siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
           siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo
      where bilElemDetVar.elem_id=bilElemGestId and
        	bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
            bilElemDetVar.periodo_id=periodoCompId and
            bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
            bilElemDetVarTipo.elem_det_tipo_code=STA_IMP_SCA and
            bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
            statoVar.data_cancellazione is null and statoVar.validita_fine is null and
            tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
            tipoStatoVar.variazione_stato_tipo_code=STATO_VAR_D and
            var.variazione_id=statoVar.variazione_id and
            var.data_cancellazione is null and var.validita_fine is null and
            var.bil_id=bilancioId;
    end if; --3
   end if; --2
 end if; --1

 if bilFaseOperativa in ( FASE_BIL_PROV) and bilElemGestId!=0 then

     strMessaggio:='Lettura stanziamenti di gestione per elem_id='||bilElemGestId||' anno_comp_in='||anno_comp_in||'.';
   	 select importiGest.elem_det_importo into strict stanziamento
     from siac_t_bil_elem_det importiGest, siac_d_bil_elem_det_tipo tipoImp
     where importiGest.elem_id=bilElemGestId AND
       	   importiGest.data_cancellazione is null and importiGest.validita_fine is null and
   	 	   tipoImp.elem_det_tipo_id=importiGest.elem_det_tipo_id and
           tipoImp.elem_det_tipo_code=STA_IMP and
    	   importiGest.periodo_id=periodoCompId;

     --- calcolo dei 'delta-gestione', variazioni agli importi del CAP-UG in stato
     --- diverso da BOZZA,DEFINTIVO,ANNULLATO
     strMessaggio:='Lettura variazioni delta-meno-gest per elem_id='||bilElemGestId||' anno_comp_in='||
                           anno_comp_in||'.';
	 --- 31.03.2016 Sofia SIAC-3304 aggiunto stato P
     select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into strict deltaMenoGest
     from siac_t_variazione var,
      	  siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
	      siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo
     where bilElemDetVar.elem_id=bilElemGestId and
           bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
           bilElemDetVar.periodo_id=periodoCompId and
	       bilElemDetVar.elem_det_importo<0 AND
  	       bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
	       bilElemDetVarTipo.elem_det_tipo_code=STA_IMP and
           bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
	       statoVar.data_cancellazione is null and statoVar.validita_fine is null and
    	   tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
--	       tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) and -- 1109015 Sofia aggiunto STATO_VAR_B
--	       tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) and -- 26072016 Sofia JIRA-SIAC-3887
--	       tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P,STATO_VAR_B) and -- 14102016 Sofia JIRA-SIAC-4099
	       tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P,STATO_VAR_B,STATO_VAR_BD) and -- 10.10.202 Sofia JIRA-SIAC-8828	       
           var.variazione_id=statoVar.variazione_id and
           var.data_cancellazione is null and var.validita_fine is null and
	       var.bil_id=bilancioId;

	 if anno_comp_in=annoBilancio then
         	strMessaggio:='Lettura stanziamenti di gestione cassa per elem_id='||bilElemGestId||' anno_comp_in='||anno_comp_in||'.';

            select importiGest.elem_det_importo into strict stanziamentoCassa
			from siac_t_bil_elem_det importiGest, siac_d_bil_elem_det_tipo tipoImp
		    where importiGest.elem_id=bilElemGestId AND
         		  importiGest.data_cancellazione is null and importiGest.validita_fine is null and
		   		  tipoImp.elem_det_tipo_id=importiGest.elem_det_tipo_id and
		          tipoImp.elem_det_tipo_code=STA_IMP_SCA and
	    	      importiGest.periodo_id=periodoCompId;


         --- calcolo dei 'delta-gestione', variazioni agli importi di cassa del CAP-UG in stato
 	     --- diverso da BOZZA,DEFINTIVO,ANNULLATO
       	 strMessaggio:='Lettura variazioni delta-meno-gest cassa per elem_id='||bilElemGestId||' anno_comp_in='||
                           anno_comp_in||'.';
		 --- 31.03.2016 Sofia SIAC-3304 aggiunto stato P
    	 select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into strict deltaMenoGestCassa
         from siac_t_variazione var,
              siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
	          siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo
         where bilElemDetVar.elem_id=bilElemGestId and
               bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
               bilElemDetVar.periodo_id=periodoCompId and
			   bilElemDetVar.elem_det_importo<0 AND
  	    	   bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
	           bilElemDetVarTipo.elem_det_tipo_code=STA_IMP_SCA and
    	       bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
	           statoVar.data_cancellazione is null and statoVar.validita_fine is null and
    	       tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
--   	           tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) and -- 1109015 Sofia aggiunto STATO_VAR_B
--   	           tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) and -- 26072016 Sofia JIRA-SIAC-3887
--   	           tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P,STATO_VAR_B) and -- 14102016 Sofia JIRA-SIAC-4099
   	           tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P,STATO_VAR_B,STATO_VAR_BD) and -- 10.10.2022 Sofia JIRA-SIAC-8828   	           
        	   var.variazione_id=statoVar.variazione_id and
               var.data_cancellazione is null and var.validita_fine is null and
	           var.bil_id=bilancioId;
      end if;
 end if;

 -- stanziamenti di previsione competenza e cassa adeguati a
 -- relativi 'delta-meno' e variazioni def. applicate alle gestione
 /* 04.07.2016 Sofia ID-INC000001114035
 stanziamentoPrev:= stanziamentoPrev-deltaMenoPrev+varImpGestione; */

 stanziamentoPrev:= stanziamentoPrev-deltaMenoPrev;
 if anno_comp_in=annoBilancio then
   /* 04.07.2016 Sofia ID-INC000001114035
     stanziamentoPrevCassa:= stanziamentoPrevCassa-deltaMenoPrevCassa+varImpGestioneCassa; **/
     stanziamentoPrevCassa:= stanziamentoPrevCassa-deltaMenoPrevCassa;
 end if;

raise notice 'deltaMenoPrev=%', deltaMenoPrev;
 raise notice 'deltaMenoPrevCassa=%', deltaMenoPrevCassa;
 raise notice 'deltaMenoGest=%', deltaMenoGest;
 raise notice 'deltaMenoGestCassa=%', deltaMenoGestCassa;
 strMessaggio:='Stanziamento effettivo elem_id='||bilElemId||'.';
 case
--   when bilFaseOperativa=FASE_BIL_PROV then -- 15.01.2021 Sofia JiraSIAC-7958
-- 15.01.2021 Sofia JiraSIAC-7958
   when bilFaseOperativa=FASE_BIL_PROV and ente_prop_in!=2 then
 --  		if stanziamentoPrev>stanziamento then 26072016 Sofia JIRA-SIAC-3887
   		if stanziamentoPrev>stanziamento-deltaMenoGest then
        /* 04.07.2016 Sofia ID-INC000001114035
        	 stanziamentoEff:=stanziamento; **/
             stanziamentoEff:=stanziamento-deltaMenoGest;
        else stanziamentoEff:=stanziamentoPrev;
        end if;

        if anno_comp_in=annoBilancio then
--         if stanziamentoPrevCassa>stanziamentoCassa then 26072016 Sofia JIRA-SIAC-3887
         if stanziamentoPrevCassa>stanziamentoCassa-deltaMenoGestCassa then
          /* 04.07.2016 Sofia ID-INC000001114035
        	 stanziamentoEffCassa:=stanziamentoCassa; **/
             stanziamentoEffCassa:=stanziamentoCassa-deltaMenoGestCassa;
         else stanziamentoEffCassa:=stanziamentoPrevCassa;
         end if;
        end if;

   ELSE
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
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_stanz_effettivo_up_anno 
               ( id_in integer,anno_comp_in varchar, ente_prop_in integer,bil_id_in integer,anno_in varchar,ele_code_in varchar, ele_code2_in varchar,ele_code3_in varchar) OWNER TO siac;