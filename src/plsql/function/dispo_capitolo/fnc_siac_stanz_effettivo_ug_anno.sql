/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop FUNCTION if exists siac.fnc_siac_stanz_effettivo_ug_anno 
(
  id_in integer = NULL::integer,
  anno_comp_in varchar = (NOT NULL::boolean),
  ente_prop_in integer = NULL::integer,
  bil_id_in integer = NULL::integer,
  anno_in varchar = NULL::character varying,
  ele_code_in varchar = NULL::character varying,
  ele_code2_in varchar = NULL::character varying,
  ele_code3_in varchar = NULL::character varying
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_stanz_effettivo_ug_anno (
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
STATO_VAR_B    constant varchar:='B'; -- BOZZA
STATO_VAR_D    constant varchar:='D'; -- DEFINITIVA
STATO_VAR_P    constant varchar:='P'; -- PRE-DEFINITIVA -- 31.03.2016 Sofia JIRA-SIAC-3304
--- SIAC-8828
STATO_VAR_BD    constant varchar:='BD'; -- BOZZA DEC

bilancioId integer:=0;
bilElemId  integer:=0;
bilElemPrevId  integer:=0;
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

periodoId integer:=0;
periodoCompId integer:=0;
enteProprietarioId integer:=0;

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
        and   tipoBilElem.elem_tipo_code = TIPO_CAP_UG
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
     and   tipoBilElem.elem_tipo_code = TIPO_CAP_UG;
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
     and   tipoBilElem.elem_tipo_code = TIPO_CAP_UG;

     annoBilancio:=anno_in;
     enteProprietarioId:=ente_prop_in;

   end if;

 end  if;


 strMessaggio:='Lettura fase di bilancio corrente per  anno bilancio='||annoBilancio||' bilancioId='||bilancioId
                ||' per elem_id='||bilElemId||' .';

 select faseop.fase_operativa_code into strict bilFaseOperativa
 from siac_d_fase_operativa faseOp, siac_r_bil_fase_operativa bilFaseOp
 where bilfaseop.bil_id=bilancioId and
       bilfaseop.data_cancellazione is null and
       bilfaseop.validita_fine is null  and
       faseOp.ente_proprietario_id=bilFaseOp.ente_proprietario_id and
       faseOp.fase_operativa_id = bilfaseop.fase_operativa_id and
       faseOp.data_cancellazione is null and
       faseOp.validita_fine is null;


 if bilFaseOperativa in ( FASE_BIL_PREV ) then
    	return next;
        return;
 elsif bilFaseOperativa not in ( FASE_BIL_PROV, FASE_BIL_GEST,FASE_BIL_CONS,FASE_BIL_CHIU) then
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
    -- [stanziamento previsione - 'delta-previsione' + variazioni def di gestione]

    	strMessaggio:='Lettura elemento di bilancio equivalente di previsione per elem_id='||bilElemId||'.';
	    select bilElemPrev.elem_id into  bilElemPrevId
    	from siac_t_bil_elem bilElemPrev, siac_d_bil_elem_tipo tipoPrev,
        	 siac_t_bil_elem bilElemGest
    	where bilElemGest.elem_id=bilElemId and
              bilElemPrev.elem_code=bilElemGest.elem_code and
              bilElemPrev.elem_code2=bilElemGest.elem_code2 and
              bilElemPrev.elem_code3=bilElemGest.elem_code3 and
              bilElemPrev.ente_proprietario_id=bilElemGest.ente_proprietario_id and
              bilElemPrev.bil_id=bilElemGest.bil_id and
              bilElemPrev.data_cancellazione is null and bilElemPrev.validita_fine is null and
              tipoPrev.elem_tipo_id=bilElemPrev.elem_tipo_id and
              tipoPrev.elem_tipo_code=TIPO_CAP_UP;

        if NOT FOUND then
         bilElemPrevId:=0;
        else
         strMessaggio:='Lettura stanziamenti di previsione per elem_id='||bilElemPrevId||' anno_comp_in='||anno_comp_in||'.';
         select importiprev.elem_det_importo into strict stanziamentoPrev
	     from siac_t_bil_elem_det importiPrev, siac_d_bil_elem_det_tipo tipoImpPrev
	     where importiPrev.elem_id=bilElemPrevId AND
	     	   importiPrev.data_cancellazione is null and importiPrev.validita_fine is null and
     	   	   tipoImpPrev.elem_det_tipo_id=importiPrev.elem_det_tipo_id and
	           tipoImpPrev.elem_det_tipo_code=STA_IMP and
	           importiPrev.periodo_id=periodoCompId;


         --- calcolo dei 'delta-previsione', variazioni agli importi del CAP-UP in stato
	     --- diverso da BOZZA,DEFINTIVO,ANNULLATO
         --- 31.03.2016 Sofia SIAC-3304 aggiunto stato P
       	 strMessaggio:='Lettura variazioni delta-meno-prev per elem_id='||bilElemPrevId||' anno_comp_in='||
                        anno_comp_in||'.';

       	 select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into strict deltaMenoPrev
         from siac_t_variazione var,
         	  siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
              siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo
         where bilElemDetVar.elem_id=bilElemPrevId and
        	   bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
               bilElemDetVar.periodo_id=periodoCompId and
		       bilElemDetVar.elem_det_importo<0 AND
  	           bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
               bilElemDetVarTipo.elem_det_tipo_code=STA_IMP and
               bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
               statoVar.data_cancellazione is null and statoVar.validita_fine is null and
               tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
               --tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) and -- 1109015 Sofia aggiunto STATO_VAR_B
			   tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) and -- Sofia 26072016 JIRA-SIAC-3887
               var.variazione_id=statoVar.variazione_id and
               var.data_cancellazione is null and var.validita_fine is null and
               var.bil_id=bilancioId;
        end if;

        --- calcolo variazioni applicate alla gestione, variazioni agli importi CAP-UG
      	strMessaggio:='Lettura variazioni di gestione per elem_id='||bilElemId||' anno_comp_in='||
                       anno_comp_in||'.';

        select coalesce(sum(bilElemDetVar.elem_det_importo),0) into strict varImpGestione
        from siac_t_variazione var,
             siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
             siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo
        where bilElemDetVar.elem_id=bilElemId and
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

	    if anno_comp_in=annoBilancio then
         if bilElemPrevId!=0 then
	      strMessaggio:='Lettura stanziamenti di previsione cassa per elem_id='||bilElemPrevId||' anno_comp_in='||anno_comp_in||'.';
          select importiprev.elem_det_importo into strict stanziamentoPrevCassa
	      from siac_t_bil_elem_det importiPrev, siac_d_bil_elem_det_tipo tipoImpPrev
	      where importiPrev.elem_id=bilElemPrevId AND
		   	    importiPrev.data_cancellazione is null and importiPrev.validita_fine is null and
     	   	    tipoImpPrev.elem_det_tipo_id=importiPrev.elem_det_tipo_id and
	            tipoImpPrev.elem_det_tipo_code=STA_IMP_SCA and
	            importiPrev.periodo_id=periodoCompId;


          --- calcolo dei 'delta-previsione', variazioni agli importi di cassa del CAP-UP in stato
	      --- diverso da BOZZA,DEFINTIVO,ANNULLATO
          --- 31.03.2016 Sofia SIAC-3304 aggiunto stato P
       	  strMessaggio:='Lettura variazioni delta-meno-prev cassa per elem_id='||bilElemPrevId||' anno_comp_in='||
                         anno_comp_in||'.';

       	  select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into strict deltaMenoPrevCassa
          from siac_t_variazione var,
               siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
               siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo
          where bilElemDetVar.elem_id=bilElemPrevId and
          	    bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
                bilElemDetVar.periodo_id=periodoCompId and
		        bilElemDetVar.elem_det_importo<0 AND
  	            bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
                bilElemDetVarTipo.elem_det_tipo_code=STA_IMP_SCA and
                bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
                statoVar.data_cancellazione is null and statoVar.validita_fine is null and
                tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
--                tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) and --1109015 Sofia aggiunto STATO_VAR_B
                tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) and -- 26072016 Sofia JIRA-SIAC-3887
                var.variazione_id=statoVar.variazione_id and
                var.data_cancellazione is null and var.validita_fine is null and
                var.bil_id=bilancioId;
         end if;

         --- calcolo variazioni applicate alla gestione, variazioni agli importi di casas CAP-UG
       	 strMessaggio:='Lettura variazioni di gestione cassa per elem_id='||bilElemId||' anno_comp_in='||
                        anno_comp_in||'.';

       	 select coalesce(sum(bilElemDetVar.elem_det_importo),0) into strict varImpGestioneCassa
         from siac_t_variazione var,
          	  siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
              siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo
         where bilElemDetVar.elem_id=bilElemId and
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

       end if;

	   /*  04.07.2016 Sofia ID-INC000001114035 non considerare le variazioni di gestione
	   -- stanziamenti di previsione competenza e cassa adeguati a
       -- relativi 'delta-meno' e variazioni def. applicate alle gestione

       stanziamentoPrev:= stanziamentoPrev-deltaMenoPrev+varImpGestione;
       stanziamentoPrevCassa:= stanziamentoPrevCassa-deltaMenoPrevCassa+varImpGestioneCassa; */

	   /*  04.07.2016 Sofia ID-INC000001114035 */
       stanziamentoPrev:= stanziamentoPrev-deltaMenoPrev;
       stanziamentoPrevCassa:= stanziamentoPrevCassa-deltaMenoPrevCassa;

 end if;

 if bilFaseOperativa in ( FASE_BIL_PROV, FASE_BIL_GEST,FASE_BIL_CONS,FASE_BIL_CHIU) then
       strMessaggio:='Lettura stanziamenti di gestione per elem_id='||bilElemId||' anno_comp_in='||anno_comp_in||'.';

       select importiGest.elem_det_importo into strict stanziamento
	   from siac_t_bil_elem_det importiGest, siac_d_bil_elem_det_tipo tipoImp
	   where importiGest.elem_id=bilElemId AND
       	     importiGest.data_cancellazione is null and importiGest.validita_fine is null and
    	 	 tipoImp.elem_det_tipo_id=importiGest.elem_det_tipo_id and
             tipoImp.elem_det_tipo_code=STA_IMP and
    	     importiGest.periodo_id=periodoCompId;


       --- calcolo dei 'delta-gestione', variazioni agli importi del CAP-UG in stato
 	   --- diverso da BOZZA,DEFINTIVO,ANNULLATO
       strMessaggio:='Lettura variazioni delta-meno-gest per elem_id='||bilElemId||' anno_comp_in='||
                           anno_comp_in||'.';
       --- 31.03.2016 Sofia SIAC-3304 aggiunto stato P
       select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into strict deltaMenoGest
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
--  	         tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) and --1109015 Sofia aggiunto STATO_VAR_B
--  	         tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) and -- 26072016 Sofia JIRA-SIAC-3887
--  	         tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P,STATO_VAR_B) and -- 14.102016 Sofia JIRA-SIAC-4099 riaggiunto B
  	         tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P,STATO_VAR_B,STATO_VAR_BD) and -- 10.102022 Sofia JIRA-SIAC-8828 aggiunto BD
  	         
        	 var.variazione_id=statoVar.variazione_id and
             var.data_cancellazione is null and var.validita_fine is null and
	         var.bil_id=bilancioId;

      if anno_comp_in=annoBilancio then
        strMessaggio:='Lettura stanziamenti di gestione cassa per elem_id='||bilElemId||' anno_comp_in='||anno_comp_in||'.';

        select importiGest.elem_det_importo into strict stanziamentoCassa
		from siac_t_bil_elem_det importiGest, siac_d_bil_elem_det_tipo tipoImp
	    where importiGest.elem_id=bilElemId AND
       		  importiGest.data_cancellazione is null and importiGest.validita_fine is null and
	   		  tipoImp.elem_det_tipo_id=importiGest.elem_det_tipo_id and
	          tipoImp.elem_det_tipo_code=STA_IMP_SCA and
	    	  importiGest.periodo_id=periodoCompId;

         --- calcolo dei 'delta-gestione', variazioni agli importi di cassa del CAP-UG in stato
 	     --- diverso da BOZZA,DEFINTIVO,ANNULLATO
       	strMessaggio:='Lettura variazioni delta-meno-gest cassa per elem_id='||bilElemId||' anno_comp_in='||
                           anno_comp_in||'.';
	             --- 31.03.2016 Sofia SIAC-3304 aggiunto stato P
    	select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into strict deltaMenoGestCassa
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
--   	          tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) and -- 1109015 Sofia aggiunto STATO_VAR_B
--   	          tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) and -- 26072016 Sofia JIRA-SIAC-3887
--   	          tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P,STATO_VAR_B) and -- 14102016 Sofia JIRA-SIAC-4099
   	          tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P,STATO_VAR_B,STATO_VAR_BD) and -- 10102022 Sofia JIRA-SIAC-8828   	          
       	      var.variazione_id=statoVar.variazione_id and
              var.data_cancellazione is null and var.validita_fine is null and
	          var.bil_id=bilancioId;

        end if;
        -- importo massimo impegnabile
        stanzMassimoImpegnabile:=null;
        strMessaggio:='Lettura massimo impegnabile per elem_id='||bilElemId||' anno_comp_in='||anno_comp_in||'.';
		select importiGest.elem_det_importo into stanzMassimoImpegnabile
		from siac_t_bil_elem_det importiGest, siac_d_bil_elem_det_tipo tipoImp
     	where importiGest.elem_id=bilElemId AND
              importiGest.data_cancellazione is null and importiGest.validita_fine is null and
	   	 	  tipoImp.elem_det_tipo_id=importiGest.elem_det_tipo_id and
		      tipoImp.elem_det_tipo_code=STA_IMP_MI and
	    	  importiGest.periodo_id=periodoCompId;

 end if;


 strMessaggio:='Stanziamento effettivo elem_id='||bilElemId||'.';
 case
  ---    ANNASILVIA CMTO FORZATURA 13-01-2017 aggiunta condizione  and ente_prop_in <> 3
  ---    10/02/2017 - richiesta REGP (DI MICHELE) - eliminare controllo tra previsione e gestione
  ---    in esercizio provvisorio
--   when bilFaseOperativa=FASE_BIL_PROV and ente_prop_in = 0 then
-- 01.06.2017 Sofia HD-INC000001805128 CmTo richiede di attivare il controllo
   when bilFaseOperativa=FASE_BIL_PROV and enteProprietarioId = 3 then

--   		if stanziamentoPrev>stanziamento then
--      26072016 Sofia JIRA-SIAC-3887
   		if stanziamentoPrev>stanziamento-deltaMenoGest then

             /*  04.07.2016 Sofia ID-INC000001114035 non considerare le variazioni di gestione
                 nello stanziamento non sono considerate le variazioni di gestione,
                 se poi lo stanziamento effettivo e quello di gestione allora
                 consideriamo i deltamenoGest per abbatterlo ulteriormente */
        	 --stanziamentoEff:=stanziamento;
             -- stanziamentoEff abbattutto dai 'delta-gestione'
	         stanziamentoEff:=stanziamento-deltaMenoGest;
        else stanziamentoEff:=stanziamentoPrev;
        end if;

        if anno_comp_in=annoBilancio then
 --       if stanziamentoPrevCassa>stanziamentoCassa then
        --      26072016 Sofia JIRA-SIAC-3887
         if stanziamentoPrevCassa>stanziamentoCassa-deltaMenoGestCassa then
           /*  04.07.2016 Sofia ID-INC000001114035 non considerare le variazioni di gestione
               nello stanziamento non sono considerate le variazioni di gestione,
               se poi lo stanziamento effettivo e quello di gestione allora
               consideriamo i deltamenoGest per abbatterlo ulteriormente */
        	/*  stanziamentoEffCassa:=stanziamentoCassa; */
              stanziamentoEffCassa:=stanziamentoCassa-deltaMenoGestCassa;
         else stanziamentoEffCassa:=stanziamentoPrevCassa;
         end if;
        end if;
   ELSE
        /*  04.07.2016 Sofia ID-INC000001114035
   		stanziamentoEff:=stanziamento; */
        stanziamentoEff:=stanziamento-deltaMenoGest;
        if anno_comp_in=annoBilancio then
          /*  04.07.2016 Sofia ID-INC000001114035
          stanziamentoEffCassa:=stanziamentoCassa; */
          stanziamentoEffCassa:=stanziamentoCassa-deltaMenoGestCassa;
        end if;
 end case;
  /*  04.07.2016 Sofia ID-INC000001114035 spostato sopra per considerare i deltaMenoGest
     solo se lo stanziamento effettivo da considerare e quello di gestione
 -- stanziamentoEff abbattutto dai 'delta-gestione'
 stanziamentoEff:=stanziamentoEff-deltaMenoGest;
 if anno_comp_in=annoBilancio then
  stanziamentoEffCassa:=stanziamentoEffCassa-deltaMenoGestCassa;
 end if; */


 strMessaggio:='Stanziamento effettivo elem_id='||bilElemId||'anno_comp_in='||anno_comp_in||'.';

 elemId:=bilElemId;
 annoCompetenza:=anno_comp_in;
 stanzEffettivo:=stanziamentoEff;
 if anno_comp_in=annoBilancio then
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

ALTER FUNCTION siac.fnc_siac_stanz_effettivo_ug_anno ( integer, varchar, integer,integer,varchar, varchar,varchar,varchar) OWNER TO siac;  