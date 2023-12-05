/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- calcolo disposponibilita accertare su capitolo di gestione
-- da utilizzarsi dalla fase di bilancio di esercizio provvissorio in poi
-- non in previsione poiche i capitoli di gestione non ci sono ancora sul nuovo bilancio di previsione
-- pertanto il calcolo su quelli di previsione varia
-- calcolo stanziamento effettivo attraverso la chiamata alla function
   -- fnc_siac_stanz_effettivo_eg_3anni
-- calcolo accertato competenza attraverso la chiamanta alla function
   -- fnc_siac_dicuiaccertatoeg_comp
-- calcolo dispo= stanziamento_effettivo- totale accertamenti di competenza

CREATE OR REPLACE FUNCTION fnc_siac_disponibilitaaccertareeg_3anni (
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
	annoCompetenza varchar,
    dispAccertare numeric
) AS
$body$
DECLARE


NVL_STR     constant varchar:='';

strMessaggio varchar(1500):=NVL_STR;

accertatoComp  record;
stanzEffettivo  record;

BEGIN

 annoCompetenza:=null;
 dispAccertare:=0;

 -- controllo parametri
 -- se id_in non serve altro
 -- diversamente deve essere passato ente_prop_id e  la chiave logica del capitolo
 -- ele_code_in,ele_code2_in,ele_code3_in
 -- con bil_id_in o anno_in

 strMessaggio:='Calcolo disponibilita accertare.Controllo parametri.';
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

 strMessaggio:='Calcolo disponibilita accertare.';

 for stanzEffettivo in
  (  select * from fnc_siac_stanz_effettivo_eg_3anni (id_in,anno_comp_in,ente_prop_in,
				  			 				       bil_id_in,anno_in,
										           ele_code_in,ele_code2_in,ele_code3_in)
  )
 loop
	annoCompetenza :=null;
    dispAccertare  :=0;

    if coalesce(anno_comp_in ,NVL_STR)=NVL_STR or anno_comp_in=stanzEffettivo.annoCompetenza then
    	 strMessaggio:='Accertato competenza elem_id='||
         				stanzEffettivo.elemId||' anno='||stanzEffettivo.annoCompetenza||'.';

		 select *  into accertatoComp
		 from  fnc_siac_dicuiaccertatoeg_comp (stanzEffettivo.elemId,stanzEffettivo.annoCompetenza);

         strMessaggio:='Disp. Accertare elem_id='||stanzEffettivo.elemId||'anno='||stanzEffettivo.annoCompetenza||'.';
         annoCompetenza:=stanzEffettivo.annoCompetenza;
		 dispAccertare :=stanzEffettivo.stanzEffettivo-accertatoComp.diCuiAccertato;

         return next;
	end if;


 end loop;


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