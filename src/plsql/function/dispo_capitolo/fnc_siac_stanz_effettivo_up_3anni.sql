/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- calcolo stanziamento effettivo su capitolo di previsione
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

 -- sono calcolati gli stanziamenti effettivi
 -- competenza per i tre anni o solo quello passato
 -- cassa solo per il primo anno di competenza

 -- ai fini del calcolo della disponibilita ad impegnare, in esercizio provvisorio
 -- viene restituito per il primo anno di pluriennale
 -- il massimo impegnabile, presente eventualmente nel tipo importo MI

CREATE OR REPLACE FUNCTION fnc_siac_stanz_effettivo_up_3anni (
  id_in         integer default null,
  anno_comp_in  varchar default null,
  ente_prop_in  integer default null,
  bil_id_in     integer default null,
  anno_in       varchar default null,
  ele_code_in   varchar default null,
  ele_code2_in  varchar default null,
  ele_code3_in  varchar default null
)
RETURNS table
(
	elemId integer,
    annoCompetenza varchar,
    stanzEffettivo numeric,
    stanzEffettivoCassa numeric,
    massimoImpegnabile numeric
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

bilancioId integer:=0;
bilElemId  integer:=0;
bilElemGestId  integer:=0;

strMessaggio varchar(1500):=NVL_STR;

bilFaseOperativa varchar(10):=NVL_STR;
annoBilancio varchar(10):=NVL_STR;

stanziamentoPrev numeric:=0;
stanziamentoPrevCassa numeric:=0;
stanziamentoPrevAnno2 numeric:=0;
stanziamentoPrevAnno3 numeric:=0;

stanziamento numeric:=0;
stanziamentoAnno2 numeric:=0;
stanziamentoAnno3 numeric:=0;


stanziamentoEff numeric:=0;
stanziamentoEffAnno2 numeric:=0;
stanziamentoEffAnno3 numeric:=0;

deltaMenoPrev numeric:=0;
varImpGestione numeric:=0;

deltaMenoGest numeric:=0;
deltaMenoGestAnno2 numeric:=0;
deltaMenoGestAnno3 numeric:=0;


deltaMenoPrevCassa numeric:=0;
varImpGestioneCassa numeric:=0;
deltaMenoGestCassa numeric:=0;

stanziamentoEffCassa numeric:=0;
stanziamentoCassa numeric:=0;
stanzMassimoImpegnabile numeric:=null;

BEGIN

 annoCompetenza:=null;
 stanzEffettivo:=0;
 stanzEffettivoCassa:=null;
 elemId:=null;
 massimoImpegnabile:=null;

 -- controllo parametri
 -- se id_in non serve altro
 -- diversamente deve essere passsato ente_prop_id e  la chiave logica del capitolo
 -- ele_code_in,ele_code2_in,ele_code3_in
 -- con bil_id_in o anno_in

 strMessaggio:='Calcolo stanziamento effettivo.Controllo parametri.';

 if coalesce(id_in,0)=0  then
 	if coalesce(ente_prop_in,0)=0  then
    	RAISE EXCEPTION '% Id ente proprietario mancante.',strMessaggio;
    end if;

    if coalesce(bil_id_in,0)=0 and coalesce(anno_in ,NVL_STR)=NVL_STR then
    	RAISE EXCEPTION '% Id e anno di bilancio mancanti.',strMessaggio;
    end if;

    if coalesce(ele_code_in ,NVL_STR)=NVL_STR or
       coalesce(ele_code2_in ,NVL_STR)=NVL_STR or
       coalesce(ele_code3_in ,NVL_STR)=NVL_STR then
    	RAISE EXCEPTION '% Chiave logica elem.Bil. mancante.',strMessaggio;
    end if;

 end if;

 -- determinare la fase di bilancio
 -- siac_d_fase_operativa, siac_r_bil_fase_operativa
 if coalesce(id_in,0) !=0 then
 	begin
        strMessaggio:='Lettura identificativo bil da elemento di bilancio elem_id='||id_in||'.';
    	select bilElem.bil_id  into strict bilancioId
        from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem
        where bilElem.elem_id=id_in and
              bilElem.data_cancellazione is null AND
              bilElem.validita_fine is null AND
              tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id and
              tipoBilElem.elem_tipo_code = TIPO_CAP_UP and
              tipoBilElem.ente_proprietario_id=bilElem.ente_proprietario_id;

         bilElemId:=id_in;

		 exception
	         	when no_data_found then
				  RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
            	when others  THEN
	              RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);
    end;
 end if;

 if coalesce(bil_id_in,0) != 0 then
 	bilancioId:=bil_id_in;
 elseif coalesce(anno_in,NVL_STR)!=NVL_STR then
 	begin
    	strMessaggio:='Lettura identificativo bil per anno='||anno_in||'.';
    	select bil.bil_id into strict bilancioId
        from siac_t_bil bil, siac_t_periodo per
        where per.anno=anno_in and
              per.ente_proprietario_id=ente_prop_in and
              bil.periodo_id=per.periodo_id and
              bil.ente_proprietario_id=ente_prop_in;

         annoBilancio:=anno_in;

		 exception
	         	when no_data_found then
				  RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
            	when others  THEN
	              RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);

    end;
 end if;

 if annoBilancio=NVL_STR then
 	begin
    	strMessaggio:='Lettura anno di bilancio per bilancioId='||bilancioId||'.';
	 	select per.anno into strict annoBilancio
        from siac_t_bil bil, siac_t_periodo per
        where bil.bil_id=bilancioId and
        	  per.periodo_id=bil.periodo_id;

       exception
         	when no_data_found then
				  RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
           	when others  THEN
	              RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);

    end;
 end if;

 begin
 	strMessaggio:='Lettura fase di bilancio corrente per  anno bilancio='||annoBilancio||' bilancioId='||bilancioId||'.';
    select faseop.fase_operativa_code into strict bilFaseOperativa
    from siac_d_fase_operativa faseOp, siac_r_bil_fase_operativa bilFaseOp
    where bilfaseop.bil_id=bilancioId and
          bilfaseop.data_cancellazione is null and
          bilfaseop.validita_fine is null  and
          faseOp.ente_proprietario_id=bilFaseOp.ente_proprietario_id and
          faseOp.fase_operativa_id = bilfaseop.fase_operativa_id and
          faseOp.data_cancellazione is  null and
          faseOp.validita_fine is null;


    if bilFaseOperativa not in ( FASE_BIL_PREV, FASE_BIL_PROV, FASE_BIL_GEST,FASE_BIL_CONS,FASE_BIL_CHIU) then
    	RAISE EXCEPTION '% Fase non ammessa per il calcolo richiesto.',strMessaggio;
    end if;

   exception
	   	when no_data_found then
		  RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
      	when others  THEN
	      RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);
 end;

 if bilElemId=0 then
 	begin
 	 strMessaggio:='Lettura identificativo elemento di bilancio '||ele_code_in||'/'||ele_code2_in||'/'||ele_code3_in||' .';
     select bilElem.elem_id into strict bilElemId
     from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem
     where bilElem.bil_id=bilancioId and
           bilElem.elem_code=ele_code_in and
           bilElem.elem_code2=ele_code2_in and
           bilElem.elem_code3=ele_code3_in and
           bilElem.data_cancellazione is null AND
           bilElem.validita_fine is null AND
           tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id and
           tipoBilElem.ente_proprietario_id=bilElem.ente_proprietario_id and
           tipoBilElem.elem_tipo_code = TIPO_CAP_UP;

     exception
     	when no_data_found then
		  RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
       when others  THEN
	      RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);
    end;
 end  if;

 if bilFaseOperativa = FASE_BIL_PROV then
 	begin
    	strMessaggio:='Lettura elemento di bilancio equivalente di gestione per elem_id='||bilElemId||'.';
	    select bilElemGest.elem_id into strict bilElemGestId
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
              tipoGest.ente_proprietario_id=bilElemGest.ente_proprietario_id and
              tipoGest.elem_tipo_code=TIPO_CAP_UG;

	     exception
		 	when no_data_found then
			  --RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
              bilElemGestId:=0;
        	when others  THEN
	          RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);
    end;
 end if;

 if coalesce(anno_comp_in ,NVL_STR)=NVL_STR or anno_comp_in=annoBilancio then

 	   begin
        strMessaggio:='Lettura stanziamenti di previsione per elem_id='||bilElemId||' annoBilancio='||annoBilancio||'.';
        select importiPrev.elem_det_importo into strict stanziamentoPrev
	    from siac_t_bil_elem_det importiPrev, siac_d_bil_elem_det_tipo tipoImpPrev,
             siac_t_periodo per
	    where importiPrev.elem_id=bilElemId AND
	    	  importiPrev.data_cancellazione is null and importiPrev.validita_fine is null and
     	   	  tipoImpPrev.elem_det_tipo_id=importiPrev.elem_det_tipo_id and
	          tipoImpPrev.ente_proprietario_id=importiPrev.ente_proprietario_id and
	          tipoImpPrev.elem_det_tipo_code=STA_IMP and
	          per.periodo_id=importiPrev.periodo_id and
	          per.anno=annoBilancio;

        exception
          when no_data_found then
			   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        	when others  THEN
	          RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);

        end;

      if bilFaseOperativa in (FASE_BIL_PROV,FASE_BIL_PREV) then
         --- calcolo dei 'delta-previsione', variazioni agli importi del CAP-UP in stato
	     --- diverso da BOZZA,DEFINTIVO,ANNULLATO
         deltaMenoPrev:=0;
         begin
        	strMessaggio:='Lettura variazioni delta-meno-prev per elem_id='||bilElemId||' annoBilancio='||
                       annoBilancio||'.';

       	  select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into strict deltaMenoPrev
          from siac_t_variazione var,
          	   siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
               siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo,
               siac_t_periodo per
          where bilElemDetVar.elem_id=bilElemId and
        	    bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
                per.periodo_id=bilElemDetVar.periodo_id and
                per.anno=annoBilancio and
		        bilElemDetVar.elem_det_importo<0 AND
  	            bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
                bilElemDetVarTipo.ente_proprietario_id=bilElemDetVar.ente_proprietario_id and
                bilElemDetVarTipo.elem_det_tipo_code=STA_IMP and
                bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
                statoVar.data_cancellazione is null and statoVar.validita_fine is null and
                tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
                tipoStatoVar.ente_proprietario_id=statoVar.ente_proprietario_id and
                tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C) and
                var.variazione_id=statoVar.variazione_id and
                var.data_cancellazione is null and var.validita_fine is null and
                var.bil_id=bilancioId;

          exception
           when no_data_found then
		 	  deltaMenoPrev:=0;
           when others  THEN
	           RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);
       end;

	  if bilElemGestId!=0 then
       --- calcolo variazioni applicate alla gestione, variazioni agli importi CAP-UG
       varImpGestione:=0;
	   begin
       	strMessaggio:='Lettura variazioni di gestione per elem_id='||bilElemGestId||' annoBilancio='||
                       annoBilancio||'.';

       	select coalesce(sum(bilElemDetVar.elem_det_importo),0) into strict varImpGestione
        from siac_t_variazione var,
        	 siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
             siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo,
             siac_t_periodo per
        where bilElemDetVar.elem_id=bilElemGestId and
        	  bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
              per.periodo_id=bilElemDetVar.periodo_id and
              per.anno=annoBilancio and
  	          bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
              bilElemDetVarTipo.ente_proprietario_id=bilElemDetVar.ente_proprietario_id and
              bilElemDetVarTipo.elem_det_tipo_code=STA_IMP and
              bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
              statoVar.data_cancellazione is null and statoVar.validita_fine is null and
              tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
              tipoStatoVar.ente_proprietario_id=statoVar.ente_proprietario_id and
              tipoStatoVar.variazione_stato_tipo_code=STATO_VAR_D and
              var.variazione_id=statoVar.variazione_id and
              var.data_cancellazione is null and var.validita_fine is null and
              var.bil_id=bilancioId;

         exception
          when no_data_found then
			  varImpGestione:=0;
          when others  THEN
	          RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);

       end;

       -- importo massimo impegnabile
       stanzMassimoImpegnabile:=null;
       begin
           	strMessaggio:='Lettura massimo impegnabile per elem_id='||bilElemId||' annoBilancio='||annoBilancio||'.';
		    select importiGest.elem_det_importo into strict stanzMassimoImpegnabile
			from siac_t_bil_elem_det importiGest, siac_d_bil_elem_det_tipo tipoImp,
    	      	 siac_t_periodo per
	     	where importiGest.elem_id=bilElemGestId AND
         	  	  importiGest.data_cancellazione is null and importiGest.validita_fine is null and
	   			  tipoImp.elem_det_tipo_id=importiGest.elem_det_tipo_id and
	        	  tipoImp.ente_proprietario_id=importiGest.ente_proprietario_id and
		          tipoImp.elem_det_tipo_code=STA_IMP_MI and
	    	      per.periodo_id=importiGest.periodo_id and
	        	  per.anno=annoBilancio;

             exception
        	  when no_data_found then
				  stanzMassimoImpegnabile:=null;
	        	when others  THEN
		          RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);
       end;
      end if;
	 end if;


     begin
	    strMessaggio:='Lettura stanziamenti di previsione cassa per elem_id='||bilElemId||' annoBilancio='||annoBilancio||'.';
        select importiprev.elem_det_importo into strict stanziamentoPrevCassa
	    from siac_t_bil_elem_det importiPrev, siac_d_bil_elem_det_tipo tipoImpPrev,
             siac_t_periodo per
	    where importiPrev.elem_id=bilElemId AND
		 	  importiPrev.data_cancellazione is null and importiPrev.validita_fine is null and
     	   	  tipoImpPrev.elem_det_tipo_id=importiPrev.elem_det_tipo_id and
	          tipoImpPrev.ente_proprietario_id=importiPrev.ente_proprietario_id and
	          tipoImpPrev.elem_det_tipo_code=STA_IMP_SCA and
	          per.periodo_id=importiPrev.periodo_id and
	          per.anno=annoBilancio;

        exception
          when no_data_found then
			   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
          when others  THEN
	           RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);
       end;

	 if bilFaseOperativa in (FASE_BIL_PROV,FASE_BIL_PREV) then
        --- calcolo dei 'delta-previsione', variazioni agli importi di cassa del CAP-UP in stato
	    --- diverso da BOZZA,DEFINTIVO,ANNULLATO
        deltaMenoPrevCassa:=0;
        begin
       	 strMessaggio:='Lettura variazioni delta-meno-prev cassa per elem_id='||bilElemId||' annoBilancio='||
                       annoBilancio||'.';

       	 select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into strict deltaMenoPrevCassa
         from siac_t_variazione var,
              siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
              siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo,
              siac_t_periodo per
         where bilElemDetVar.elem_id=bilElemId and
         	   bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
               per.periodo_id=bilElemDetVar.periodo_id and
               per.anno=annoBilancio and
		       bilElemDetVar.elem_det_importo<0 AND
  	           bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
               bilElemDetVarTipo.ente_proprietario_id=bilElemDetVar.ente_proprietario_id and
               bilElemDetVarTipo.elem_det_tipo_code=STA_IMP_SCA and
               bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
               statoVar.data_cancellazione is null and statoVar.validita_fine is null and
               tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
               tipoStatoVar.ente_proprietario_id=statoVar.ente_proprietario_id and
               tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C) and
               var.variazione_id=statoVar.variazione_id and
               var.data_cancellazione is null and var.validita_fine is null and
               var.bil_id=bilancioId;

          exception
           when no_data_found then
		 	  deltaMenoPrevCassa:=0;
           when others  THEN
	          RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);

        end;

     if bilElemGestId!=0 then
      --- calcolo variazioni applicate alla gestione, variazioni agli importi di casas CAP-UG
       varImpGestioneCassa:=0;
	   begin
       	strMessaggio:='Lettura variazioni di gestione cassa per elem_id='||bilElemGestId||' annoBilancio='||
                       annoBilancio||'.';

       	select coalesce(sum(bilElemDetVar.elem_det_importo),0) into strict varImpGestioneCassa
        from siac_t_variazione var,
        	 siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
             siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo,
             siac_t_periodo per
        where bilElemDetVar.elem_id=bilElemGestId and
        	  bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
              per.periodo_id=bilElemDetVar.periodo_id and
              per.anno=annoBilancio and
  	          bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
              bilElemDetVarTipo.ente_proprietario_id=bilElemDetVar.ente_proprietario_id and
              bilElemDetVarTipo.elem_det_tipo_code=STA_IMP_SCA and
              bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
              statoVar.data_cancellazione is null and statoVar.validita_fine is null and
              tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
              tipoStatoVar.ente_proprietario_id=statoVar.ente_proprietario_id and
              tipoStatoVar.variazione_stato_tipo_code=STATO_VAR_D and
              var.variazione_id=statoVar.variazione_id and
              var.data_cancellazione is null and var.validita_fine is null and
              var.bil_id=bilancioId;

         exception
          when no_data_found then
			  varImpGestioneCassa:=0;
          when others  THEN
	          RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);

       end;
      end if;
     end if;

	 -- stanziamenti di previsione competenza e cassa adeguati a
     -- relativi 'delta-meno' e variazioni def. applicate alle gestione

     stanziamentoPrev:= stanziamentoPrev-deltaMenoPrev+varImpGestione;
     stanziamentoPrevCassa:= stanziamentoPrevCassa-deltaMenoPrevCassa+varImpGestioneCassa;

   end if;

   if coalesce(anno_comp_in ,NVL_STR)=NVL_STR or
       anno_comp_in=ltrim(rtrim(to_char((annoBilancio::numeric)+1,'9999'))) then

	   begin
	    strMessaggio:='Lettura stanziamenti di previsione per elem_id='||bilElemId||' annoBilancio='||
                   to_char((annoBilancio::numeric)+1,'9999')||'.';
    	select importiprev.elem_det_importo into strict stanziamentoPrevAnno2
	    from siac_t_bil_elem_det importiPrev, siac_d_bil_elem_det_tipo tipoImpPrev,
        	 siac_t_periodo per
    	where importiPrev.elem_id=bilElemId AND
              importiPrev.data_cancellazione is null and importiPrev.validita_fine is null and
	    	  tipoImpPrev.elem_det_tipo_id=importiPrev.elem_det_tipo_id and
    	      tipoImpPrev.ente_proprietario_id=importiPrev.ente_proprietario_id and
        	  tipoImpPrev.elem_det_tipo_code=STA_IMP and
	          per.periodo_id=importiPrev.periodo_id and
    	      per.anno=ltrim(rtrim(to_char((annoBilancio::numeric)+1,'9999')));

        exception
          when no_data_found then
			   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        	when others  THEN
	          RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);

	   end;

    if bilFaseOperativa in (FASE_BIL_PROV,FASE_BIL_PREV) then

	   --- calcolo dei 'delta-previsione', variazioni agli importi del CAP-UP in stato
	   --- diverso da BOZZA,DEFINTIVO,ANNULLATO
       deltaMenoPrev:=0;
       begin
       	strMessaggio:='Lettura variazioni delta-meno-prev per elem_id='||bilElemId||' annoBilancio='||
                      to_char((annoBilancio::numeric)+1,'9999')||'.';

       	select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into strict deltaMenoPrev
        from siac_t_variazione var,
        	 siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
             siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo,
             siac_t_periodo per
        where bilElemDetVar.elem_id=bilElemId and
              bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
              per.periodo_id=bilElemDetVar.periodo_id and
              per.anno=ltrim(rtrim(to_char((annoBilancio::numeric)+1,'9999'))) and
		      bilElemDetVar.elem_det_importo<0 AND
  	          bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
              bilElemDetVarTipo.ente_proprietario_id=bilElemDetVar.ente_proprietario_id and
              bilElemDetVarTipo.elem_det_tipo_code=STA_IMP and
              bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
              statoVar.data_cancellazione is null and statoVar.validita_fine is null and
              tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
              tipoStatoVar.ente_proprietario_id=statoVar.ente_proprietario_id and
              tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C) and
              var.variazione_id=statoVar.variazione_id and
              var.data_cancellazione is null and var.validita_fine is null and
              var.bil_id=bilancioId;

         exception
          when no_data_found then
			  deltaMenoPrev:=0;
        	when others  THEN
	          RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);

       end;

     if bilElemGestId!=0 then
      --- calcolo variazioni applicate alla gestione, variazioni agli importi CAP-UG
       varImpGestione:=0;
	   begin
       	strMessaggio:='Lettura variazioni di gestione per elem_id='||bilElemGestId||' annoBilancio='||
                   to_char((annoBilancio::numeric)+1,'9999')||'.';

       	select coalesce(sum(bilElemDetVar.elem_det_importo),0) into strict varImpGestione
        from siac_t_variazione var,
        	 siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
             siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo,
             siac_t_periodo per
        where bilElemDetVar.elem_id=bilElemGestId and
              bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
              per.periodo_id=bilElemDetVar.periodo_id and
              per.anno=ltrim(rtrim(to_char((annoBilancio::numeric)+1,'9999'))) and
  	          bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
              bilElemDetVarTipo.ente_proprietario_id=bilElemDetVar.ente_proprietario_id and
              bilElemDetVarTipo.elem_det_tipo_code=STA_IMP and
              bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
              statoVar.data_cancellazione is null and statoVar.validita_fine is null and
              tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
              tipoStatoVar.ente_proprietario_id=statoVar.ente_proprietario_id and
              tipoStatoVar.variazione_stato_tipo_code=STATO_VAR_D and
              var.variazione_id=statoVar.variazione_id and
              var.data_cancellazione is null and var.validita_fine is null and
              var.bil_id=bilancioId;

         exception
          when no_data_found then
			  varImpGestione:=0;
          when others  THEN
	          RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);

       end;
      end if;
     end if;
      -- stanziemendo di previsione competenza anno+1 adeguato  a
      -- relativi 'delta-meno' e variazioni def. applicate alla gestione
      stanziamentoPrevAnno2:= stanziamentoPrevAnno2-deltaMenoPrev+varImpGestione;

    end if;

    if coalesce(anno_comp_in ,NVL_STR)=NVL_STR or
       anno_comp_in=ltrim(rtrim(to_char((annoBilancio::numeric)+2,'9999'))) then

       begin

        strMessaggio:='Lettura stanziamenti di previsione per elem_id='||bilElemId||' annoBilancio='||
                   to_char((annoBilancio::numeric)+2,'9999')||'.';
	    select importiprev.elem_det_importo into strict stanziamentoPrevAnno3
    	from siac_t_bil_elem_det importiPrev, siac_d_bil_elem_det_tipo tipoImpPrev,
        	 siac_t_periodo per
	    where importiPrev.elem_id=bilElemId AND
        	  importiPrev.data_cancellazione is null and importiPrev.validita_fine is null and
    		  tipoImpPrev.elem_det_tipo_id=importiPrev.elem_det_tipo_id and
	          tipoImpPrev.ente_proprietario_id=importiPrev.ente_proprietario_id and
    	      tipoImpPrev.elem_det_tipo_code=STA_IMP and
        	  per.periodo_id=importiPrev.periodo_id and
	          per.anno=ltrim(rtrim(to_char((annoBilancio::numeric)+2,'9999')));

         exception
          when no_data_found then
			   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        	when others  THEN
	          RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);
	   end;

     if bilFaseOperativa in (FASE_BIL_PROV,FASE_BIL_PREV) then
	   --- calcolo dei 'delta-previsione', variazioni negative  in valore assoluto
       --- agli importi del CAP-UP in stato
	   --- diverso da BOZZA,DEFINTIVO,ANNULLATO
       deltaMenoPrev:=0;
       begin
       	strMessaggio:='Lettura variazioni delta-meno-prev per elem_id='||bilElemId||' annoBilancio='||
                   to_char((annoBilancio::numeric)+2,'9999')||'.';

       	select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into strict deltaMenoPrev
        from siac_t_variazione var,
        	 siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
             siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo,
             siac_t_periodo per
        where bilElemDetVar.elem_id=bilElemId and
              bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
              per.periodo_id=bilElemDetVar.periodo_id and
              per.anno=ltrim(rtrim(to_char((annoBilancio::numeric)+2,'9999'))) and
		      bilElemDetVar.elem_det_importo<0 AND
  	          bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
              bilElemDetVarTipo.ente_proprietario_id=bilElemDetVar.ente_proprietario_id and
              bilElemDetVarTipo.elem_det_tipo_code=STA_IMP and
              bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
              statoVar.data_cancellazione is null and statoVar.validita_fine is null and
              tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
              tipoStatoVar.ente_proprietario_id=statoVar.ente_proprietario_id and
              tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C) and
              var.variazione_id=statoVar.variazione_id and
              var.data_cancellazione is null and var.validita_fine is null and
              var.bil_id=bilancioId;

         exception
          when no_data_found then
			  deltaMenoPrev:=0;
        	when others  THEN
	          RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);

       end;

     if bilElemGestId!=0 THEN

      --- calcolo variazioni applicate alla gestione, variazioni agli importi CAP-UG
      varImpGestione:=0;
	  begin
       	strMessaggio:='Lettura variazioni di gestione per elem_id='||bilElemGestId||' annoBilancio='||
                   to_char((annoBilancio::numeric)+2,'9999')||'.';

       	select coalesce(sum(bilElemDetVar.elem_det_importo),0) into strict varImpGestione
        from siac_t_variazione var,
        	 siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
             siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo,
             siac_t_periodo per
        where bilElemDetVar.elem_id=bilElemGestId and
        	  bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
              per.periodo_id=bilElemDetVar.periodo_id and
              per.anno=ltrim(rtrim(to_char((annoBilancio::numeric)+2,'9999'))) and
  	          bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
              bilElemDetVarTipo.ente_proprietario_id=bilElemDetVar.ente_proprietario_id and
              bilElemDetVarTipo.elem_det_tipo_code=STA_IMP and
              bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
              statoVar.data_cancellazione is null and statoVar.validita_fine is null and
              tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
              tipoStatoVar.ente_proprietario_id=statoVar.ente_proprietario_id and
              tipoStatoVar.variazione_stato_tipo_code=STATO_VAR_D and
              var.variazione_id=statoVar.variazione_id and
              var.data_cancellazione is null and var.validita_fine is null and
              var.bil_id=bilancioId;

         exception
          when no_data_found then
			  varImpGestione:=0;
        	when others  THEN
	          RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);

      end;
     end if;
   end if;

   -- stanziamento di previsione competenza anno+2 adeguato a
   -- relativi 'delta-meno' e variazioni def. applicate alla gestione
   stanziamentoPrevAnno3:= stanziamentoPrevAnno3-deltaMenoPrev+varImpGestione;
 end if;

 if bilFaseOperativa in ( FASE_BIL_PROV) and bilElemGestId!=0 then

    if coalesce(anno_comp_in ,NVL_STR)=NVL_STR or anno_comp_in=annoBilancio then
		begin
	     strMessaggio:='Lettura stanziamenti di gestione per elem_id='||bilElemGestId||' annoBilancio='||annoBilancio||'.';
    	 select importiGest.elem_det_importo into strict stanziamento
	     from siac_t_bil_elem_det importiGest, siac_d_bil_elem_det_tipo tipoImp,
    	      siac_t_periodo per
	     where importiGest.elem_id=bilElemGestId AND
         	   importiGest.data_cancellazione is null and importiGest.validita_fine is null and
    	 	   tipoImp.elem_det_tipo_id=importiGest.elem_det_tipo_id and
        	   tipoImp.ente_proprietario_id=importiGest.ente_proprietario_id and
	           tipoImp.elem_det_tipo_code=STA_IMP and
    	       per.periodo_id=importiGest.periodo_id and
        	   per.anno=annoBilancio;

          exception
          when no_data_found then
			   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        	when others  THEN
	          RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);
        end;

         --- calcolo dei 'delta-gestione', variazioni agli importi del CAP-UG in stato
 	     --- diverso da BOZZA,DEFINTIVO,ANNULLATO
         deltaMenoGest:=0;
         begin
	       	strMessaggio:='Lettura variazioni delta-meno-gest per elem_id='||bilElemGestId||' annoBilancio='||
                           annoBilancio||'.';

    	   	select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into strict deltaMenoGest
        	from siac_t_variazione var,
        		 siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
	             siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo,
    	         siac_t_periodo per
        	where bilElemDetVar.elem_id=bilElemGestId and
                  bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
            	  per.periodo_id=bilElemDetVar.periodo_id and
	              per.anno=annoBilancio and
			      bilElemDetVar.elem_det_importo<0 AND
  	    	      bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
            	  bilElemDetVarTipo.ente_proprietario_id=bilElemDetVar.ente_proprietario_id and
	              bilElemDetVarTipo.elem_det_tipo_code=STA_IMP and
    	          bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
	              statoVar.data_cancellazione is null and statoVar.validita_fine is null and
    	          tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
	              tipoStatoVar.ente_proprietario_id=statoVar.ente_proprietario_id and
    	          tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C) and
        	      var.variazione_id=statoVar.variazione_id and
            	  var.data_cancellazione is null and var.validita_fine is null and
	              var.bil_id=bilancioId;

    	     exception
        	  when no_data_found then
				  deltaMenoGest:=0;
	        	when others  THEN
		          RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);
    	   end;

		 begin
         	strMessaggio:='Lettura stanziamenti di gestione cassa per elem_id='||bilElemGestId||' annoBilancio='||annoBilancio||'.';

            select importiGest.elem_det_importo into strict stanziamentoCassa
			from siac_t_bil_elem_det importiGest, siac_d_bil_elem_det_tipo tipoImp,
    	    	 siac_t_periodo per
		    where importiGest.elem_id=bilElemGestId AND
         		  importiGest.data_cancellazione is null and importiGest.validita_fine is null and
		   		  tipoImp.elem_det_tipo_id=importiGest.elem_det_tipo_id and
	        	  tipoImp.ente_proprietario_id=importiGest.ente_proprietario_id and
		          tipoImp.elem_det_tipo_code=STA_IMP_SCA and
	    	      per.periodo_id=importiGest.periodo_id and
	        	  per.anno=annoBilancio;

         	exception
	          when no_data_found then
			   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
    	      when others  THEN
	    	   RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);
         end;

         --- calcolo dei 'delta-gestione', variazioni agli importi di cassa del CAP-UG in stato
 	     --- diverso da BOZZA,DEFINTIVO,ANNULLATO
         deltaMenoGestCassa:=0;
         begin
	       	strMessaggio:='Lettura variazioni delta-meno-gest cassa per elem_id='||bilElemGestId||' annoBilancio='||
                           annoBilancio||'.';

    	   	select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into strict deltaMenoGestCassa
        	from siac_t_variazione var,
        		 siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
	             siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo,
    	         siac_t_periodo per
        	where bilElemDetVar.elem_id=bilElemGestId and
                  bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
            	  per.periodo_id=bilElemDetVar.periodo_id and
	              per.anno=annoBilancio and
			      bilElemDetVar.elem_det_importo<0 AND
  	    	      bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
            	  bilElemDetVarTipo.ente_proprietario_id=bilElemDetVar.ente_proprietario_id and
	              bilElemDetVarTipo.elem_det_tipo_code=STA_IMP_SCA and
    	          bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
	              statoVar.data_cancellazione is null and statoVar.validita_fine is null and
    	          tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
	              tipoStatoVar.ente_proprietario_id=statoVar.ente_proprietario_id and
    	          tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C) and
        	      var.variazione_id=statoVar.variazione_id and
            	  var.data_cancellazione is null and var.validita_fine is null and
	              var.bil_id=bilancioId;

    	     exception
        	  when no_data_found then
				  deltaMenoGestCassa:=0;
	        	when others  THEN
		          RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);
    	   end;

    end if;

    if coalesce(anno_comp_in ,NVL_STR)=NVL_STR or
       anno_comp_in=ltrim(rtrim(to_char((annoBilancio::numeric)+1,'9999'))) then
	   begin

	    strMessaggio:='Lettura stanziamenti di gestione per elem_id='||bilElemGestId||' annoBilancio='||
    	               to_char((annoBilancio::numeric)+1,'9999')||'.';
	    select importiGest.elem_det_importo into strict stanziamentoAnno2
    	from siac_t_bil_elem_det importiGest, siac_d_bil_elem_det_tipo tipoImp,
	         siac_t_periodo per
    	where importiGest.elem_id=bilElemGestId AND
        	  importiGest.data_cancellazione is null and importiGest.validita_fine is null and
	    	  tipoImp.elem_det_tipo_id=importiGest.elem_det_tipo_id and
    	      tipoImp.ente_proprietario_id=importiGest.ente_proprietario_id and
        	  tipoImp.elem_det_tipo_code=STA_IMP and
	          per.periodo_id=importiGest.periodo_id and
    	      per.anno=ltrim(rtrim(to_char((annoBilancio::numeric)+1,'9999')));

         exception
          when no_data_found then
			   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        	when others  THEN
	          RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);

	    end;

         --- calcolo dei 'delta-gestione', variazioni agli importi del CAP-UG in stato
 	     --- diverso da BOZZA,DEFINTIVO,ANNULLATO
         deltaMenoGestAnno2:=0;
         begin
	       	strMessaggio:='Lettura variazioni delta-meno-gest per elem_id='||bilElemGestId||' annoBilancio='||
                   to_char((annoBilancio::numeric)+1,'9999')||'.';

    	   	select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into strict deltaMenoGestAnno2
        	from siac_t_variazione var,
        		 siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
	             siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo,
    	         siac_t_periodo per
        	where bilElemDetVar.elem_id=bilElemGestId and
                  bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
            	  per.periodo_id=bilElemDetVar.periodo_id and
	              per.anno=ltrim(rtrim(to_char((annoBilancio::numeric)+1,'9999'))) and
			      bilElemDetVar.elem_det_importo<0 AND
  	    	      bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
            	  bilElemDetVarTipo.ente_proprietario_id=bilElemDetVar.ente_proprietario_id and
	              bilElemDetVarTipo.elem_det_tipo_code=STA_IMP and
    	          bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
	              statoVar.data_cancellazione is null and statoVar.validita_fine is null and
    	          tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
	              tipoStatoVar.ente_proprietario_id=statoVar.ente_proprietario_id and
    	          tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C) and
        	      var.variazione_id=statoVar.variazione_id and
            	  var.data_cancellazione is null and var.validita_fine is null and
	              var.bil_id=bilancioId;

    	     exception
        	  when no_data_found then
				  deltaMenoGestAnno2:=0;
	        	when others  THEN
		          RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);
    	   end;

     end if;

    if coalesce(anno_comp_in ,NVL_STR)=NVL_STR or
       anno_comp_in=ltrim(rtrim(to_char((annoBilancio::numeric)+2,'9999'))) then

        begin
	     strMessaggio:='Lettura stanziamenti di gestione per elem_id='||bilElemGestId||' annoBilancio='||
    	               to_char((annoBilancio::numeric)+2,'9999')||'.';
	     select importiGest.elem_det_importo into strict stanziamentoAnno3
    	 from siac_t_bil_elem_det importiGest, siac_d_bil_elem_det_tipo tipoImp,
	          siac_t_periodo per
    	 where importiGest.elem_id=bilElemGestId AND
          	   importiGest.data_cancellazione is null and importiGest.validita_fine is null and
	    	   tipoImp.elem_det_tipo_id=importiGest.elem_det_tipo_id and
    	       tipoImp.ente_proprietario_id=importiGest.ente_proprietario_id and
        	   tipoImp.elem_det_tipo_code=STA_IMP and
	           per.periodo_id=importiGest.periodo_id and
    	       per.anno=ltrim(rtrim(to_char((annoBilancio::numeric)+2,'9999')));


          exception
          when no_data_found then
			   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        	when others  THEN
	          RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);
		 end;

         --- calcolo dei 'delta-gestione', variazioni agli importi del CAP-UG in stato
 	     --- diverso da BOZZA,DEFINTIVO,ANNULLATO
         deltaMenoGestAnno3:=0;
		 begin
	       	strMessaggio:='Lettura variazioni delta-meno-gest per elem_id='||bilElemGestId||' annoBilancio='||
                   to_char((annoBilancio::numeric)+2,'9999')||'.';

    	   	select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into strict deltaMenoGestAnno3
        	from siac_t_variazione var,
        		 siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
	             siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo,
    	         siac_t_periodo per
        	where bilElemDetVar.elem_id=bilElemGestId and
		          bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
            	  per.periodo_id=bilElemDetVar.periodo_id and
	              per.anno=ltrim(rtrim(to_char((annoBilancio::numeric)+2,'9999'))) and
			      bilElemDetVar.elem_det_importo<0 AND
  	    	      bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
            	  bilElemDetVarTipo.ente_proprietario_id=bilElemDetVar.ente_proprietario_id and
	              bilElemDetVarTipo.elem_det_tipo_code=STA_IMP and
    	          bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
	              statoVar.data_cancellazione is null and statoVar.validita_fine is null and
    	          tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
	              tipoStatoVar.ente_proprietario_id=statoVar.ente_proprietario_id and
    	          tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C) and
        	      var.variazione_id=statoVar.variazione_id and
            	  var.data_cancellazione is null and var.validita_fine is null and
	              var.bil_id=bilancioId;

    	     exception
        	  when no_data_found then
				  deltaMenoGestAnno3:=0;
	        	when others  THEN
		          RAISE EXCEPTION '% Errore : %-%.',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 500);
    	   end;
	end if;
 end if;


 strMessaggio:='Stanziamento effettivo elem_id='||bilElemId||'.';
 case
   when bilFaseOperativa=FASE_BIL_PROV then
   		if stanziamentoPrev>stanziamento then
        	 stanziamentoEff:=stanziamento;
        else stanziamentoEff:=stanziamentoPrev;
        end if;

        if stanziamentoPrevCassa>stanziamentoCassa then
        	 stanziamentoEffCassa:=stanziamentoCassa;
        else stanziamentoEffCassa:=stanziamentoPrevCassa;
        end if;

   		if stanziamentoPrevAnno2>stanziamentoAnno2 then
        	 stanziamentoEffAnno2:=stanziamentoAnno2;
        else stanziamentoEffAnno2:=stanziamentoPrevAnno2;
        end if;
   		if stanziamentoPrevAnno3>stanziamentoAnno3 then
        	 stanziamentoEffAnno3:=stanziamentoAnno3;
        else stanziamentoEffAnno3:=stanziamentoPrevAnno3;
        end if;
   ELSE
   		stanziamentoEff:=stanziamentoPrev;
        stanziamentoEffCassa:=stanziamentoPrevCassa;
        stanziamentoEffAnno2:=stanziamentoPrevAnno2;
        stanziamentoEffAnno3:=stanziamentoPrevAnno3;
 end case;

 -- stanziamentoEff abbattutto dai 'delta-gestione'
 stanziamentoEff:=stanziamentoEff-deltaMenoGest;
 stanziamentoEffCassa:=stanziamentoEffCassa-deltaMenoGestCassa;

 stanziamentoEffAnno2:=stanziamentoEffAnno2-deltaMenoGestAnno2;
 stanziamentoEffAnno3:=stanziamentoEffAnno3-deltaMenoGestAnno3;

 if coalesce(anno_comp_in ,NVL_STR)=NVL_STR or anno_comp_in=annoBilancio then
	 strMessaggio:='Stanziamento effettivo elem_id='||bilElemId||'anno='||annoBilancio||'.';

     elemId:=bilElemId;
	 annoCompetenza:=annoBilancio;
	 stanzEffettivo:=stanziamentoEff;
     stanzEffettivoCassa:=stanziamentoEffCassa;
     if stanzMassimoImpegnabile is not null then
     	massimoImpegnabile:=stanzMassimoImpegnabile;
     end if;

	 return next;
 end if;

 if coalesce(anno_comp_in ,NVL_STR)=NVL_STR or
    anno_comp_in=ltrim(rtrim(to_char((annoBilancio::numeric)+1,'9999'))) then

     strMessaggio:='Stanziamento effettivo elem_id='||bilElemId||'anno='||to_char((annoBilancio::numeric)+1,'9999')||'.';

     elemId:=bilElemId;
	 annoCompetenza:=ltrim(rtrim(to_char((annoBilancio::numeric)+1,'9999')));
	 stanzEffettivo:=stanziamentoEffAnno2;
     stanzEffettivoCassa:=null;
     massimoImpegnabile:=null;

 	 return next;
 end if;

 if coalesce(anno_comp_in ,NVL_STR)=NVL_STR or
    anno_comp_in=ltrim(rtrim(to_char((annoBilancio::numeric)+2,'9999'))) then

	 strMessaggio:='Stanziamento effettivo elem_id='||bilElemId||'anno='||to_char((annoBilancio::numeric)+2,'9999')||'.';

     elemId:=bilElemId;
	 annoCompetenza:=ltrim(rtrim(to_char((annoBilancio::numeric)+2,'9999')));
	 stanzEffettivo:=stanziamentoEffAnno3;
     stanzEffettivoCassa:=null;
	 massimoImpegnabile:=null;
     return next;
 end if;

 if coalesce(annoCompetenza,NVL_STR)=NVL_STR then
	 return next;
 else
     return;
 end if;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
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
COST 100;