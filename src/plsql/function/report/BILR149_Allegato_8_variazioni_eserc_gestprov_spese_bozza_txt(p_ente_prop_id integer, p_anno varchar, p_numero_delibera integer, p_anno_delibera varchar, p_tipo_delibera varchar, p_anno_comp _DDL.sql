/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR149_Allegato_8_variazioni_eserc_gestprov_spese_bozza_txt" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  attoamm_id integer,
  attoamm_anno varchar,
  attoamm_numero integer,
  tipo_atto varchar,
  attoamm_oggetto varchar,
  data_provv_var timestamp,
  data_approvazione_provv timestamp,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  variazione_aumento_stanziato numeric,
  variazione_diminuzione_stanziato numeric,
  variazione_aumento_fpv numeric,
  variazione_diminuzione_fpv numeric,
  tipo_capitolo varchar
) AS
$body$
DECLARE

annoCapImp varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;
bilancio_id integer;

BEGIN

--annoCapImp:= p_anno; 
annoCapImp:=p_anno_competenza;


raise notice '%', annoCapImp;

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

elemTipoCode:='CAP-UG'; -- tipo capitolo gestione

missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_fpv:=0;
variazione_diminuzione_fpv:=0;

/* Funzione nata per la SIAC-7195 per la gestione dei file in formato testo 
	per Unicredit.
    La funzione estrae i dati delle variazioni di spesa del report BILR149 
    e del relativo atto.
    Resituisce solo i dati di stanziamento suddivisi x STD e FPV
    e le variazioni sono quelle in bozza.
    
  SIAC-8217 31/05/2021.
   Tolto il filtro sulla tipologia del capitolo perche' i dati dei 
   capitoli devono essere sempre estratti in modo da fare match con i 
   capitoli coinvolti nella variazione.
   Inoltre la tipologia di capitolo e' stata aggiunta ai dati di output.     
*/


select a.bil_id 
	into bilancio_id 
from siac_t_bil a,siac_t_periodo b
where b.periodo_id=a.periodo_id
	and a.ente_proprietario_id=p_ente_prop_id 
	and b.anno=p_anno;
    
    --preparo la query
strQuery:='          
with atti as(select	atto.attoamm_anno, atto.attoamm_numero,
			tipo_atto.attoamm_tipo_code, atto.attoamm_oggetto,
			dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo) importo_var,        
            tipo_elemento.elem_det_tipo_code tipo_importo,            
            '''||p_anno_competenza||''',
            atto.attoamm_id, atto.data_creazione data_provv_var,
            r_atto_stato.data_creazione data_approvazione_provv,
            cat_del_capitolo.elem_cat_code	      	
    from 	siac_t_atto_amm 			atto,
            siac_d_atto_amm_tipo		tipo_atto,
            siac_r_atto_amm_stato 		r_atto_stato,
            siac_d_atto_amm_stato 		stato_atto,
            siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_importi,
            siac_d_bil_elem_categoria 	cat_del_capitolo,
            siac_r_bil_elem_categoria 	r_cat_capitolo
    where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    and		r_atto_stato.attoamm_id								=	atto.attoamm_id
    and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
    and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
                r_variazione_stato.attoamm_id_varbil   				=	atto.attoamm_id )
    and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
    and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id	
    and		r_cat_capitolo.elem_id 								= 	capitolo.elem_id
    and 	r_cat_capitolo.elem_cat_id							= 	cat_del_capitolo.elem_cat_id
    and 	atto.ente_proprietario_id 							= 	'||p_ente_prop_id ||'
    and 	testata_variazione.bil_id							=   '||bilancio_id;
    if p_numero_delibera IS NOT NULL THEN
    	strQuery:=strQuery|| ' and	atto.attoamm_numero 	= 	'||p_numero_delibera||'
    		and		atto.attoamm_anno						=	'''||p_anno_delibera||'''
    		and		tipo_atto.attoamm_tipo_code				=	'''||p_tipo_delibera||'''';         
   else
    	strQuery:=strQuery|| ' and		testata_variazione.variazione_num		in('||p_ele_variazioni||') ';
    end if;
   
    
    strQuery:=strQuery|| ' and		anno_importi.anno		= 	'''||p_anno_competenza||'''		
    --10/10/2022 SIAC-8827  Aggiunto lo stato BD.			
 	and		tipologia_stato_var.variazione_stato_tipo_code	in	(''B'',''G'', ''C'', ''P'', ''BD'')
    and		tipo_capitolo.elem_tipo_code					=	'''||elemTipoCode||'''
    and		tipo_elemento.elem_det_tipo_code				in (''STA'')
    and		atto.data_cancellazione						is null
    and		tipo_atto.data_cancellazione				is null
    and		r_atto_stato.data_cancellazione				is null
    and		stato_atto.data_cancellazione				is null
    and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null
    and		cat_del_capitolo.data_cancellazione			is null
    and		r_cat_capitolo.data_cancellazione			is null
    group by 	atto.attoamm_anno, atto.attoamm_numero,tipo_atto.attoamm_tipo_code,
    			atto.attoamm_oggetto, dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
            	atto.attoamm_id, atto.data_creazione, 
                r_atto_stato.data_creazione,
                cat_del_capitolo.elem_cat_code),
	capitoli as (select programma.classif_id programma_id,
						macroaggr.classif_id macroaggregato_id,        				
       					capitolo.elem_code, capitolo.elem_code2,
                        capitolo.elem_desc, capitolo.elem_desc2,
                        capitolo.elem_id, capitolo.elem_id_padre,
                        cat_del_capitolo.elem_cat_code
                from siac_d_class_tipo programma_tipo,
                     siac_t_class programma,
                     siac_d_class_tipo macroaggr_tipo,
                     siac_t_class macroaggr,
                     siac_t_bil_elem capitolo,
                     siac_d_bil_elem_tipo tipo_elemento,
                     siac_r_bil_elem_class r_capitolo_programma,
                     siac_r_bil_elem_class r_capitolo_macroaggr, 
                     siac_d_bil_elem_stato stato_capitolo, 
                     siac_r_bil_elem_stato r_capitolo_stato,
                     siac_d_bil_elem_categoria cat_del_capitolo,
                     siac_r_bil_elem_categoria r_cat_capitolo
                where programma.classif_tipo_id=programma_tipo.classif_tipo_id 				
                    and programma.classif_id=r_capitolo_programma.classif_id	
                    and macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 
                    and macroaggr.classif_id=r_capitolo_macroaggr.classif_id								
                    and capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
                    and capitolo.elem_id=r_capitolo_programma.elem_id		
                    and capitolo.elem_id=r_capitolo_macroaggr.elem_id	
                    and capitolo.elem_id		=	r_capitolo_stato.elem_id	
                    and r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
                    and capitolo.elem_id				=	r_cat_capitolo.elem_id	
                    and r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
                    and capitolo.ente_proprietario_id='||p_ente_prop_id ||'  		
                    and capitolo.bil_id					= '||bilancio_id||'		
                    and programma_tipo.classif_tipo_code=''PROGRAMMA''	
                    and macroaggr_tipo.classif_tipo_code=''MACROAGGREGATO''	                     							                    	
                    and tipo_elemento.elem_tipo_code = '''||elemTipoCode||'''			                     			                    
                    and stato_capitolo.elem_stato_code	in(''VA'',''PR'')
                     --SIAC-8217: tolto il filtro. 				
                    --and cat_del_capitolo.elem_cat_code	in (''STD'',''FPV'',''FSC'',''FPVC'')                    
                    and	programma_tipo.data_cancellazione 			is null
                    and	programma.data_cancellazione 				is null
                    and	macroaggr_tipo.data_cancellazione 			is null
                    and	macroaggr.data_cancellazione 				is null
                    and	capitolo.data_cancellazione 				is null
                    and	tipo_elemento.data_cancellazione 			is null
                    and	r_capitolo_programma.data_cancellazione 	is null
                    and	r_capitolo_macroaggr.data_cancellazione 	is null 
                    and	stato_capitolo.data_cancellazione 			is null 
                    and	r_capitolo_stato.data_cancellazione 		is null
                    and	cat_del_capitolo.data_cancellazione 		is null
                    and	r_cat_capitolo.data_cancellazione 			is null),                
	strutt_bilancio as (select *
        		from "fnc_bilr_struttura_cap_bilancio_spese"('||p_ente_prop_id||',
                				'''||p_anno||''',''''))
    select atti.attoamm_id::integer attoamm_id,
    	  atti.attoamm_anno::varchar attoamm_anno,
    	  atti.attoamm_numero::integer attoamm_numero,
          atti.attoamm_tipo_code::varchar tipo_atto,
          atti.attoamm_oggetto::varchar attoamm_oggetto,
          atti.data_provv_var::timestamp data_provv_var,
          atti.data_approvazione_provv::timestamp data_approvazione_provv,
  		  strutt_bilancio.missione_tipo_desc::varchar missione_tipo_desc ,
          strutt_bilancio.missione_code::varchar missione_code,
          strutt_bilancio.missione_desc::varchar missione_desc,
          strutt_bilancio.programma_tipo_desc::varchar programma_tipo_desc,
          strutt_bilancio.programma_code::varchar programma_code,
          strutt_bilancio.programma_desc::varchar programma_desc,
          strutt_bilancio.titusc_tipo_desc::varchar titusc_tipo_desc,
          strutt_bilancio.titusc_code::varchar titusc_code,
          strutt_bilancio.titusc_desc::varchar titusc_desc,
          strutt_bilancio.macroag_tipo_desc::varchar macroag_tipo_desc,
          strutt_bilancio.macroag_code::varchar macroag_code,
          strutt_bilancio.macroag_desc::varchar macroag_desc,
          capitoli.elem_code::varchar bil_ele_code ,
          capitoli.elem_desc::varchar bil_ele_desc,
          capitoli.elem_code2::varchar bil_ele_code2,
          capitoli.elem_desc2::varchar bil_ele_desc2,
          capitoli.elem_id::integer bil_ele_id,
          case when atti.tipo_importo = '''||TipoImpComp||''' --STA
          		and atti.elem_cat_code in(''STD'',''FSC'')
                and atti.importo_var >= 0 then
                	COALESCE(atti.importo_var, 0)::numeric
                else 0::numeric end variazione_aumento_stanziato,
          case when atti.tipo_importo = '''||TipoImpComp||''' --STA
          		and atti.elem_cat_code in(''STD'',''FSC'')
          		and atti.importo_var <0 then
                	COALESCE(atti.importo_var *-1, 0)::numeric
                else 0::numeric end  variazione_diminuzione_stanziato,
          case when atti.tipo_importo = '''||TipoImpComp||''' --STA
          		and atti.elem_cat_code in(''FPV'',''FPVC'')
                and atti.importo_var >= 0 then
                	COALESCE(atti.importo_var, 0)::numeric
                else 0::numeric end variazione_aumento_fpv,
          case when atti.tipo_importo = '''||TipoImpComp||''' --STA
          		and atti.elem_cat_code in(''FPV'',''FPVC'')
          		and atti.importo_var <0 then
                	COALESCE(atti.importo_var *-1, 0)::numeric
                else 0::numeric end  variazione_diminuzione_fpv ,
          COALESCE(capitoli.elem_cat_code,'''')             
    from atti
    	LEFT JOIN capitoli
        	ON atti.elem_id = capitoli.elem_id
        LEFT JOIN strutt_bilancio
        	ON (strutt_bilancio.programma_id = capitoli.programma_id
                	and strutt_bilancio.macroag_id = capitoli.macroaggregato_id) ';
            
raise notice 'strQuery = %', strQuery;   
             
return query execute  strQuery;

raise notice 'fine OK';

exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;              
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR149_Allegato_8_variazioni_eserc_gestprov_spese_bozza_txt" (p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar, p_ele_variazioni varchar)
  OWNER TO siac;