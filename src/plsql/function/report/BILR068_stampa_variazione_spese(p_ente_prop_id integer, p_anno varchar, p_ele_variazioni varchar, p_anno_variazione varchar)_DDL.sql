/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR068_stampa_variazione_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_anno_variazione varchar
)
RETURNS TABLE (
  bil_anno varchar,
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
  bil_ele_id_padre integer,
  stanziamento numeric,
  cassa numeric,
  residuo numeric,
  variazione_aumento_stanziato numeric,
  variazione_diminuzione_stanziato numeric,
  variazione_aumento_cassa numeric,
  variazione_diminuzione_cassa numeric,
  variazione_aumento_residuo numeric,
  variazione_diminuzione_residuo numeric,
  anno_riferimento varchar,
  display_error varchar,
  flag_visualizzazione numeric
) AS
$body$
DECLARE


classifBilRec record;


annoCapImp varchar;
annoCapImp2 varchar;
annoCapImp3 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
sql_query varchar;
strApp varchar;
intApp numeric;
bilancio_id integer;

BEGIN

annoCapImp:= p_anno; 
annocapimp2:=(p_anno::INTEGER + 1)::varchar;
annocapimp3:=(p_anno::INTEGER + 2)::varchar;

raise notice '%', annoCapImp;


TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione

--  verifico che il parametro con l'elenco delle variazioni abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 --intApp= strApp ::numeric/ 1;
 intApp = strApp::numeric;
END IF;


bil_anno='';
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
bil_ele_id_padre=0;
stanziamento=0;
cassa=0;
residuo=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
anno_riferimento='';
display_error='';
flag_visualizzazione = -111;

-- 06/05/2020 SIAC-7294.
--	Procedura completamente rivista per ottimizzazione.

select fnc_siac_random_user()
into	user_table;

select t_bil.bil_id
	into bilancio_id
from siac_t_bil t_bil,
	siac_t_periodo t_per
where t_bil.periodo_id=t_per.periodo_id 
	and t_bil.ente_proprietario_id = p_ente_prop_id
	and t_per.anno = p_anno
    and t_bil.data_cancellazione IS NULL   
    and t_per.data_cancellazione IS NULL;
    

   
    --inserisco le variazioni su una tabella di appoggio.
sql_query='insert into siac_rep_var_spese
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        tipo_elemento.elem_det_tipo_code, '''; 
sql_query=sql_query ||user_table||''' utente, 
        testata_variazione.ente_proprietario_id,
        anno_importo.anno     	      	
from 	siac_r_variazione_stato		r_variazione_stato,
        siac_t_variazione 			testata_variazione,
        siac_d_variazione_tipo		tipologia_variazione,
        siac_d_variazione_stato 	tipologia_stato_var,
        siac_t_bil_elem_det_var 	dettaglio_variazione,
        siac_t_bil_elem				capitolo,
        siac_d_bil_elem_tipo 		tipo_capitolo,
        siac_d_bil_elem_det_tipo	tipo_elemento,
        siac_t_periodo 				anno_eserc ,
        siac_t_periodo              anno_importo ,
        siac_t_bil                  bilancio  
where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id   
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id 
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id ';
sql_query=sql_query ||'and		tipo_capitolo.elem_tipo_code						= '''||elemTipoCode||'''';
sql_query=sql_query ||' and 	testata_variazione.ente_proprietario_id 	= 	'||p_ente_prop_id;
sql_query=sql_query ||' and		anno_eserc.anno					= 	'''||p_anno||''''; 												
sql_query=sql_query ||' and 	testata_variazione.variazione_num in ('||p_ele_variazioni||') ';  
--04/07/2019: nell'ambito delle verifiche della SIAC-6956, ci si e' accorti
--che era commentato il filtro sullo stato della variazione.
--Poiche' il report BILR068 estrae solo le variazioni in BOZZA, il filtro
--viene ripristinato.
--sql_query=sql_query ||' and		--tipologia_stato_var.variazione_stato_tipo_code		 in	(''B'',''G'', ''C'', ''P'') and 
--10/10/2022 SIAC-8827  Aggiunto lo stato BD.
sql_query=sql_query ||' and		tipologia_stato_var.variazione_stato_tipo_code		 in	(''B'',''G'', ''C'', ''P'',''BD'') and 
		tipo_elemento.elem_det_tipo_code					in (''STA'',''SCA'',''STR'')
and 	anno_importo.anno ='''||p_anno_variazione||'''
and		r_variazione_stato.data_cancellazione		is null
and		testata_variazione.data_cancellazione		is null
and		tipologia_variazione.data_cancellazione		is null
and		tipologia_stato_var.data_cancellazione		is null
and 	dettaglio_variazione.data_cancellazione		is null
and 	capitolo.data_cancellazione					is null
and		tipo_capitolo.data_cancellazione			is null
and		tipo_elemento.data_cancellazione			is null
group by 	dettaglio_variazione.elem_id,
        	tipo_elemento.elem_det_tipo_code, 
        	utente,
        	testata_variazione.ente_proprietario_id,
            anno_importo.anno';
            
raise notice 'sql_query = % ', sql_query;

EXECUTE sql_query;

return QUERY
	with dati_struttura as (select *
				from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id,p_anno,'')),
    capitoli as (select macro.macroaggr_id macroaggregato_id,
              progr.programma_id,
              p_anno anno_bilancio,
              capitolo.*
      from siac_t_bil_elem capitolo
           	left join (select r_capitolo_programma.elem_id progr_elem_id,
            			programma.classif_id programma_id                                                
                    from siac_d_class_tipo programma_tipo,
                        siac_t_class programma,
                         siac_r_bil_elem_class r_capitolo_programma
                    where programma.classif_tipo_id=programma_tipo.classif_tipo_id and
                      programma.classif_id=r_capitolo_programma.classif_id		and
                      programma.ente_proprietario_id=p_ente_prop_id and
                      programma_tipo.classif_tipo_code='PROGRAMMA' and
                      programma_tipo.data_cancellazione 	is null and
                      programma.data_cancellazione 			is null and 
                      r_capitolo_programma.data_cancellazione 	is null) progr
              	ON  capitolo.elem_id = progr.progr_elem_id
             left join (select macroaggr.classif_id macroaggr_id,
                        r_capitolo_macroaggr.elem_id macroaggr_elem_id
                       from siac_t_class macroaggr,                       
                        siac_d_class_tipo macroaggr_tipo,
                        siac_r_bil_elem_class r_capitolo_macroaggr
                    where  
                      macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 	and
                      macroaggr.classif_id=r_capitolo_macroaggr.classif_id		and
                      macroaggr.ente_proprietario_id = p_ente_prop_id and
                      macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'		and                  
                      macroaggr_tipo.data_cancellazione 	is null and
                      macroaggr.data_cancellazione 			is null and           			  
          			  r_capitolo_macroaggr.data_cancellazione 	is null) macro 
              ON capitolo.elem_id = macro.macroaggr_elem_id,              		
           siac_d_bil_elem_tipo tipo_elemento,
           siac_d_bil_elem_stato stato_capitolo, 
           siac_r_bil_elem_stato r_capitolo_stato,
           siac_d_bil_elem_categoria cat_del_capitolo,
           siac_r_bil_elem_categoria r_cat_capitolo
      where         
          capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 				and          
          capitolo.elem_id		=	r_capitolo_stato.elem_id			and
          r_capitolo_stato.elem_stato_id	=stato_capitolo.elem_stato_id	and
          capitolo.elem_id				=	r_cat_capitolo.elem_id		and
          r_cat_capitolo.elem_cat_id	=	cat_del_capitolo.elem_cat_id	and
          capitolo.ente_proprietario_id=p_ente_prop_id     				and
          capitolo.bil_id = bilancio_id									and                   	
          tipo_elemento.elem_tipo_code = elemTipoCode					and 
          -- INC000001570761 stato_capitolo.elem_stato_code	=	'VA'								and
          stato_capitolo.elem_stato_code	in ('VA', 'PR')					    		
          ------cat_del_capitolo.elem_cat_code	=	'STD'	
          -- 06/09/2016: aggiunto FPVC
          --and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')             
          and	capitolo.data_cancellazione 				is null
          and	tipo_elemento.data_cancellazione 			is null
          and	stato_capitolo.data_cancellazione 			is null 
          and	r_capitolo_stato.data_cancellazione 		is null
          and	cat_del_capitolo.data_cancellazione 		is null
          and	r_cat_capitolo.data_cancellazione 			is null),
    importi_stanz as (select capitolo_importi.elem_id,          
            		sum(capitolo_importi.elem_det_importo) importo_cap
              from 		siac_t_bil_elem_det 		capitolo_importi,
                          siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
                          siac_t_periodo 				capitolo_imp_periodo,            
                          siac_d_bil_elem_tipo 		tipo_elemento,            
                          siac_d_bil_elem_stato 		stato_capitolo, 
                          siac_r_bil_elem_stato 		r_capitolo_stato,
                          siac_d_bil_elem_categoria 	cat_del_capitolo,
                          siac_r_bil_elem_categoria 	r_cat_capitolo,
                          siac_t_bil_elem 			capitolo				            
                  where capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id	
                      and	capitolo.elem_id					=	capitolo_importi.elem_id 
                      and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
                      and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
                      and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
                      and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
                      and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
                      and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
                      and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  								
                      and	capitolo.bil_id						=	bilancio_id 			 
                      and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode 		
                      and	capitolo_imp_periodo.anno = p_anno_variazione
                      -- INC000001570761 and stato_capitolo.elem_stato_code	=	'VA'								
                      and stato_capitolo.elem_stato_code	in ('VA', 'PR')			
                       and capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp -- 'STA'			
                      and	capitolo_importi.data_cancellazione 		is null
                      and	capitolo_imp_tipo.data_cancellazione 		is null
                      and	capitolo_imp_periodo.data_cancellazione 	is null
                      and	capitolo.data_cancellazione 				is null
                      and	tipo_elemento.data_cancellazione 			is null
                      and	stato_capitolo.data_cancellazione 			is null 
                      and	r_capitolo_stato.data_cancellazione 		is null
                      and cat_del_capitolo.data_cancellazione 		is null
                      and	r_cat_capitolo.data_cancellazione 			is null
                  group by	capitolo_importi.elem_id),   
			importi_cassa as (select capitolo_importi.elem_id,          
            		sum(capitolo_importi.elem_det_importo) importo_cap
              from 		siac_t_bil_elem_det 		capitolo_importi,
                          siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
                          siac_t_periodo 				capitolo_imp_periodo,            
                          siac_d_bil_elem_tipo 		tipo_elemento,            
                          siac_d_bil_elem_stato 		stato_capitolo, 
                          siac_r_bil_elem_stato 		r_capitolo_stato,
                          siac_d_bil_elem_categoria 	cat_del_capitolo,
                          siac_r_bil_elem_categoria 	r_cat_capitolo,
                          siac_t_bil_elem 			capitolo				            
                  where capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id	
                      and	capitolo.elem_id					=	capitolo_importi.elem_id 
                      and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
                      and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
                      and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
                      and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
                      and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
                      and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
                      and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  								
                      and	capitolo.bil_id						=	bilancio_id 			 
                      and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode 		
                      and	capitolo_imp_periodo.anno = p_anno_variazione
                      -- INC000001570761 and stato_capitolo.elem_stato_code	=	'VA'								
                      and stato_capitolo.elem_stato_code	in ('VA', 'PR')			
                       and capitolo_imp_tipo.elem_det_tipo_code = TipoImpCassa -- 'SCA'			
                      and	capitolo_importi.data_cancellazione 		is null
                      and	capitolo_imp_tipo.data_cancellazione 		is null
                      and	capitolo_imp_periodo.data_cancellazione 	is null
                      and	capitolo.data_cancellazione 				is null
                      and	tipo_elemento.data_cancellazione 			is null
                      and	stato_capitolo.data_cancellazione 			is null 
                      and	r_capitolo_stato.data_cancellazione 		is null
                      and cat_del_capitolo.data_cancellazione 		is null
                      and	r_cat_capitolo.data_cancellazione 			is null
                  group by	capitolo_importi.elem_id),                         
     importi_residui as (select capitolo_importi.elem_id,          
            		sum(capitolo_importi.elem_det_importo) importo_cap
              from 		siac_t_bil_elem_det 		capitolo_importi,
                          siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
                          siac_t_periodo 				capitolo_imp_periodo,            
                          siac_d_bil_elem_tipo 		tipo_elemento,            
                          siac_d_bil_elem_stato 		stato_capitolo, 
                          siac_r_bil_elem_stato 		r_capitolo_stato,
                          siac_d_bil_elem_categoria 	cat_del_capitolo,
                          siac_r_bil_elem_categoria 	r_cat_capitolo,
                          siac_t_bil_elem 			capitolo				            
                  where capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id	
                      and	capitolo.elem_id					=	capitolo_importi.elem_id 
                      and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
                      and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
                      and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
                      and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
                      and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
                      and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
                      and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  								
                      and	capitolo.bil_id						=	bilancio_id 			 
                      and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode 		
                      and	capitolo_imp_periodo.anno = p_anno_variazione
                      -- INC000001570761 and stato_capitolo.elem_stato_code	=	'VA'								
                      and stato_capitolo.elem_stato_code	in ('VA', 'PR')			
                       and capitolo_imp_tipo.elem_det_tipo_code = TipoImpRes -- 'STR'			
                      and	capitolo_importi.data_cancellazione 		is null
                      and	capitolo_imp_tipo.data_cancellazione 		is null
                      and	capitolo_imp_periodo.data_cancellazione 	is null
                      and	capitolo.data_cancellazione 				is null
                      and	tipo_elemento.data_cancellazione 			is null
                      and	stato_capitolo.data_cancellazione 			is null 
                      and	r_capitolo_stato.data_cancellazione 		is null
                      and cat_del_capitolo.data_cancellazione 		is null
                      and	r_cat_capitolo.data_cancellazione 			is null
                  group by	capitolo_importi.elem_id),      
		variaz_stanz_pos as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_stanz_neg as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id),   
         variaz_cassa_pos as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario = p_ente_prop_id
                        and a.tipologia=TipoImpCassa -- ''SCA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id), 
         variaz_cassa_neg as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.tipologia=TipoImpCassa -- ''SCA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id), 
         variaz_residui_pos as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id   
                        and a.tipologia=TipoImpRes -- ''STR''
                        and a.importo > 0
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_residui_neg as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.tipologia=TipoImpRes -- ''STR''
                        and a.importo < 0
                        and a.utente=user_table
                        group by  a.elem_id)                          
    select p_anno::varchar bil_anno,
    	dati_struttura.missione_tipo_desc::varchar missione_tipo_desc ,
        dati_struttura.missione_code::varchar missione_code,
        dati_struttura.missione_desc::varchar missione_desc,
        dati_struttura.programma_tipo_desc::varchar programma_tipo_desc,
        dati_struttura.programma_code::varchar programma_code,
        dati_struttura.programma_desc::varchar programma_desc,
        dati_struttura.titusc_tipo_desc::varchar titusc_tipo_desc,
        dati_struttura.titusc_code::varchar titusc_code,
        dati_struttura.titusc_desc::varchar titusc_desc,
        dati_struttura.macroag_tipo_desc::varchar macroag_tipo_desc,
        dati_struttura.macroag_code::varchar macroag_code,
        dati_struttura.macroag_desc::varchar macroag_desc,
        capitoli.elem_code::varchar bil_ele_code ,
        capitoli.elem_desc::varchar bil_ele_desc,
        capitoli.elem_code2::varchar bil_ele_code2,
        capitoli.elem_desc2::varchar bil_ele_desc2,
        capitoli.elem_id::integer bil_ele_id,
        capitoli.elem_id_padre::integer bil_ele_id_padre,
		COALESCE(importi_stanz.importo_cap,0)::numeric stanziamento ,
        COALESCE(importi_cassa.importo_cap,0)::numeric cassa ,
        COALESCE(importi_residui.importo_cap,0)::numeric residuo ,
        COALESCE(variaz_stanz_pos.importo_var,0)::numeric variazione_aumento_stanziato,
        COALESCE(variaz_stanz_neg.importo_var *-1,0)::numeric variazione_diminuzione_stanziato,
        COALESCE(variaz_cassa_pos.importo_var,0)::numeric variazione_aumento_cassa,
        COALESCE(variaz_cassa_neg.importo_var *-1,0)::numeric variazione_diminuzione_cassa,
        COALESCE(variaz_residui_pos.importo_var,0)::numeric variazione_aumento_residuo,
        COALESCE(variaz_residui_neg.importo_var *-1,0)::numeric variazione_diminuzione_residuo,                                    
        p_anno_variazione::varchar anno_riferimento ,
  		''::varchar display_error,
        case when variaz_stanz_pos.elem_id IS NOT NULL OR
        	variaz_stanz_neg.elem_id IS NOT NULL OR
            variaz_cassa_pos.elem_id IS NOT NULL OR
            variaz_cassa_neg.elem_id IS NOT NULL OR
            variaz_residui_pos.elem_id IS NOT NULL OR
            variaz_residui_neg.elem_id IS NOT NULL then capitoli.elem_id::numeric
            else -111::numeric end flag_visualizzazione 
	from dati_struttura
    	left join capitoli
        	on (dati_struttura.programma_id = capitoli.programma_id    
                and	dati_struttura.macroag_id = capitoli.macroaggregato_id) 
        LEFT JOIN importi_stanz
            ON importi_stanz.elem_id = capitoli.elem_id
        LEFT JOIN importi_cassa
            ON importi_cassa.elem_id = capitoli.elem_id
        LEFT JOIN importi_residui
            ON importi_residui.elem_id = capitoli.elem_id
        LEFT JOIN variaz_stanz_pos
            ON variaz_stanz_pos.elem_id = capitoli.elem_id
        LEFT JOIN variaz_stanz_neg
            ON variaz_stanz_neg.elem_id = capitoli.elem_id
        LEFT JOIN variaz_cassa_pos
            ON variaz_cassa_pos.elem_id = capitoli.elem_id
        LEFT JOIN variaz_cassa_neg
            ON variaz_cassa_neg.elem_id = capitoli.elem_id
        LEFT JOIN variaz_residui_pos
            ON variaz_residui_pos.elem_id = capitoli.elem_id
        LEFT JOIN variaz_residui_neg
            ON variaz_residui_neg.elem_id = capitoli.elem_id
	where capitoli.elem_id is not null
    	and exists (select 1 from siac_r_class_fam_tree aa,
        				capitoli bb--,
                       -- siac_rep_cap_ug_imp cc
        			where --bb.elem_id =cc.elem_id
                    	 bb.macroaggregato_id = aa.classif_id
                 		and aa.classif_id_padre = dati_struttura.titusc_id 
                        and bb.programma_id=dati_struttura.programma_id
                        and aa.ente_proprietario_id=p_ente_prop_id)
 union
    select	p_anno::varchar 				bil_anno,
    	'Missione'							missione_tipo_desc,
        '00'								missione_code,
        ' '									missione_desc,
        'Programma'							programma_tipo_desc,
        '0000'								programma_code,
        ' '									programma_desc,
        'Titolo Spesa'						titusc_tipo_desc,
        '0'									titusc_code,
        ' '									titusc_desc,
        'Macroaggregato'					macroag_tipo_desc,
    	'0000000'							macroag_code,
      	' '									macroag_desc,
        capitoli.elem_code::varchar bil_ele_code ,
        capitoli.elem_desc::varchar bil_ele_desc,
        capitoli.elem_code2::varchar bil_ele_code2,
        capitoli.elem_desc2::varchar bil_ele_desc2,
        capitoli.elem_id::integer bil_ele_id,
        capitoli.elem_id_padre::integer bil_ele_id_padre,
		COALESCE(importi_stanz.importo_cap,0)::numeric stanziamento ,
        COALESCE(importi_cassa.importo_cap,0)::numeric cassa ,
        COALESCE(importi_residui.importo_cap,0)::numeric residuo ,
        COALESCE(variaz_stanz_pos.importo_var,0)::numeric variazione_aumento_stanziato,
        COALESCE(variaz_stanz_neg.importo_var *-1,0)::numeric variazione_diminuzione_stanziato,
        COALESCE(variaz_cassa_pos.importo_var,0)::numeric variazione_aumento_cassa,
        COALESCE(variaz_cassa_neg.importo_var *-1,0)::numeric variazione_diminuzione_cassa,
        COALESCE(variaz_residui_pos.importo_var,0)::numeric variazione_aumento_residuo,
        COALESCE(variaz_residui_neg.importo_var *-1,0)::numeric variazione_diminuzione_residuo,                      
        p_anno_variazione::varchar anno_riferimento ,
  		''::varchar display_error,
        case when variaz_stanz_pos.elem_id IS NOT NULL OR
        	variaz_stanz_neg.elem_id IS NOT NULL OR
            variaz_cassa_pos.elem_id IS NOT NULL OR
            variaz_cassa_neg.elem_id IS NOT NULL OR
            variaz_residui_pos.elem_id IS NOT NULL OR
            variaz_residui_neg.elem_id IS NOT NULL then capitoli.elem_id::numeric
            else -111::numeric end flag_visualizzazione
    from capitoli             
        LEFT JOIN importi_stanz
            ON importi_stanz.elem_id = capitoli.elem_id
        LEFT JOIN importi_cassa
            ON importi_cassa.elem_id = capitoli.elem_id
        LEFT JOIN importi_residui
            ON importi_residui.elem_id = capitoli.elem_id
        LEFT JOIN variaz_stanz_pos
            ON variaz_stanz_pos.elem_id = capitoli.elem_id
        LEFT JOIN variaz_stanz_neg
            ON variaz_stanz_neg.elem_id = capitoli.elem_id
        LEFT JOIN variaz_cassa_pos
            ON variaz_cassa_pos.elem_id = capitoli.elem_id
        LEFT JOIN variaz_cassa_neg
            ON variaz_cassa_neg.elem_id = capitoli.elem_id
        LEFT JOIN variaz_residui_pos
            ON variaz_residui_pos.elem_id = capitoli.elem_id
        LEFT JOIN variaz_residui_neg
            ON variaz_residui_neg.elem_id = capitoli.elem_id
      where capitoli.elem_id is not null
      	 and (capitoli.programma_id is null or capitoli.macroaggregato_id is NULL);
        
delete from	siac_rep_var_spese	where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
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

ALTER FUNCTION siac."BILR068_stampa_variazione_spese" (p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar, p_anno_variazione varchar)
  OWNER TO siac;