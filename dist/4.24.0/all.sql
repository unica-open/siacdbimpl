/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--SIAC-7294 - Maurizio - INIZIO
DROP FUNCTION if exists siac."BILR068_stampa_variazione_entrate"(p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar, p_anno_variazione varchar);
DROP FUNCTION if exists siac."BILR068_stampa_variazione_spese"(p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar, p_anno_variazione varchar);


CREATE OR REPLACE FUNCTION siac."BILR068_stampa_variazione_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_anno_variazione varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
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
  ente_denominazione varchar,
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
ente_prop varchar;

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
elemTipoCode:='CAP-EG'; -- tipo capitolo gestione

--  verifico che il parametro con l'elenco delle variazioni abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 --intApp= strApp ::numeric/ 1;
 intApp = strApp::numeric;
END IF;


bil_anno='';
titoloe_tipo_code='';
titoloe_tipo_desc='';
titoloe_code='';
titoloe_desc ='';
tipologia_tipo_code ='';
tipologia_tipo_desc ='';
tipologia_code='';
tipologia_desc ='';
categoria_tipo_code ='';
categoria_tipo_desc ='';
categoria_code ='';
categoria_desc ='';
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
  
select t_ente.ente_denominazione
	into ente_prop
from siac_t_ente_proprietario t_ente
where t_ente.ente_proprietario_id = p_ente_prop_id	
    and t_ente.data_cancellazione IS NULL;  

   
    --inserisco le variazioni.
sql_query='insert into siac_rep_var_entrate
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
sql_query=sql_query ||' and		tipologia_stato_var.variazione_stato_tipo_code		 in	(''B'',''G'', ''C'', ''P'') and 
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
				from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id,p_anno,'')),
    capitoli as (select categ.categ_elem_id ,
    			categ.categoria_id,
              	p_anno anno_bilancio,
              	capitolo.*
      from siac_t_bil_elem capitolo
           	left join (select r_capitolo_categoria.elem_id categ_elem_id,
            			categoria.classif_id categoria_id                                                
                    from siac_d_class_tipo categoria_tipo,
                        siac_t_class categoria,
                         siac_r_bil_elem_class r_capitolo_categoria
                    where categoria.classif_tipo_id=categoria_tipo.classif_tipo_id and
                      categoria.classif_id=r_capitolo_categoria.classif_id		and
                      categoria.ente_proprietario_id=p_ente_prop_id and
                      categoria_tipo.classif_tipo_code='CATEGORIA' and
                      categoria_tipo.data_cancellazione 	is null and
                      categoria.data_cancellazione 			is null and 
                      r_capitolo_categoria.data_cancellazione 	is null) categ
              	ON  capitolo.elem_id = categ.categ_elem_id,                 		
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
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_stanz_neg as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id),   
         variaz_cassa_pos as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario = p_ente_prop_id
                        and a.tipologia=TipoImpCassa -- ''SCA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id), 
         variaz_cassa_neg as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.tipologia=TipoImpCassa -- ''SCA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id), 
         variaz_residui_pos as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id   
                        and a.tipologia=TipoImpRes -- ''STR''
                        and a.importo > 0
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_residui_neg as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.tipologia=TipoImpRes -- ''STR''
                        and a.importo < 0
                        and a.utente=user_table
                        group by  a.elem_id)                          
    select p_anno::varchar bil_anno,
    	''::varchar titoloe_tipo_code ,
        dati_struttura.classif_tipo_desc1::varchar titoloe_tipo_desc,
        dati_struttura.titolo_code::varchar titoloe_code,
        dati_struttura.titolo_desc::varchar titoloe_desc,
        ''::varchar tipologia_tipo_code,
        dati_struttura.classif_tipo_desc2::varchar tipologia_tipo_desc,
        dati_struttura.tipologia_code::varchar tipologia_code,
        dati_struttura.tipologia_desc::varchar tipologia_desc,
        ''::varchar categoria_tipo_code,
        dati_struttura.classif_tipo_desc3::varchar categoria_tipo_desc,
        dati_struttura.categoria_code::varchar categoria_code,
        dati_struttura.categoria_desc::varchar categoria_desc,
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
        ente_prop::varchar ente_denominazione,
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
        	on dati_struttura.categoria_id = capitoli.categoria_id    
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
    	/*and exists (select 1 from siac_r_class_fam_tree aa,
        				capitoli bb--,
                       -- siac_rep_cap_ug_imp cc
        			where --bb.elem_id =cc.elem_id
                    	 bb.macroaggregato_id = aa.classif_id
                 		and aa.classif_id_padre = dati_struttura.titusc_id 
                        and bb.programma_id=dati_struttura.programma_id
                        and aa.ente_proprietario_id=p_ente_prop_id)*/
 union
    select	p_anno::varchar bil_anno,
    	''::varchar titoloe_tipo_code ,
        'Titolo'::varchar titoloe_tipo_desc,
        '0'::varchar titoloe_code,
        ' '::varchar titoloe_desc,
        ''::varchar tipologia_tipo_code,
        'Tipologia'::varchar tipologia_tipo_desc,
        '0000000'::varchar tipologia_code,
        ' '::varchar tipologia_desc,
        ''::varchar categoria_tipo_code,
        'Categoria'::varchar categoria_tipo_desc,
        '0000000'::varchar categoria_code,
        ' '::varchar categoria_desc,
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
        p_anno_variazione::varchar anno_riferimento,
        ente_prop::varchar ente_denominazione,
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
      	 and capitoli.categ_elem_id is null ;

delete from	siac_rep_var_entrate	where utente=user_table;


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
COST 100 ROWS 1000;



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
sql_query=sql_query ||' and		tipologia_stato_var.variazione_stato_tipo_code		 in	(''B'',''G'', ''C'', ''P'') and 
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
COST 100 ROWS 1000;


--SIAC-7294 - Maurizio - FINE

--SIAC-7650 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac.fnc_bilr_stampa_mastrino (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_reg_da date,
  p_data_reg_a date,
  p_pdce_v_livello varchar,
  p_ambito varchar
)
RETURNS TABLE (
  nome_ente varchar,
  id_pdce0 integer,
  codice_pdce0 varchar,
  descr_pdce0 varchar,
  id_pdce1 integer,
  codice_pdce1 varchar,
  descr_pdce1 varchar,
  id_pdce2 integer,
  codice_pdce2 varchar,
  descr_pdce2 varchar,
  id_pdce3 integer,
  codice_pdce3 varchar,
  descr_pdce3 varchar,
  id_pdce4 integer,
  codice_pdce4 varchar,
  descr_pdce4 varchar,
  id_pdce5 integer,
  codice_pdce5 varchar,
  descr_pdce5 varchar,
  id_pdce6 integer,
  codice_pdce6 varchar,
  descr_pdce6 varchar,
  id_pdce7 integer,
  codice_pdce7 varchar,
  descr_pdce7 varchar,
  id_pdce8 integer,
  codice_pdce8 varchar,
  descr_pdce8 varchar,
  data_registrazione date,
  num_prima_nota integer,
  tipo_pnota varchar,
  prov_pnota varchar,
  cod_soggetto varchar,
  descr_soggetto varchar,
  tipo_documento varchar,
  data_registrazione_mov date,
  numero_documento varchar,
  num_det_rif varchar,
  data_det_rif date,
  importo_dare numeric,
  importo_avere numeric,
  livello integer,
  tipo_movimento varchar,
  saldo_prec_dare numeric,
  saldo_prec_avere numeric,
  saldo_ini_dare numeric,
  saldo_ini_avere numeric,
  code_pdce_livello varchar,
  display_error varchar
) AS
$body$
DECLARE
elenco_prime_note record;
elencoPdce record;
dati_movimento record;
dati_eventi record;
--dati_pdce record;
pdce_conto_id_in integer;


-- 07.06.2018 Sofia SIAC-6200
pdce_conto_ambito_id integer;
pdce_conto_ambito_code varchar;
pdce_conto_esiste_pnota integer:=null;

DEF_NULL	constant varchar:='';
RTN_MESSAGGIO 		varchar(1000):=DEF_NULL;
user_table			varchar;
nome_ente_in varchar;
bil_id_in integer;




BEGIN

--SIAC-6429 11/09/2018.
-- veniva aggiunto un giorno per far estrarre anche le date che avevano ora e minuti settati,
-- pero' questo causava l'estrazione anche delle prime note del giorno successivo.
-- Pertanto il parametro e' lasciato cosi' come arriva, mentre la data  pnota_dataregistrazionegiornale
-- viene troncata al giorno (senza ora e minuti) nelle varie query dove e'
-- confrontata.
   -- p_data_reg_a:=date_trunc('day', to_timestamp(to_char(p_data_reg_a,'dd/mm/yyyy'),'dd/mm/yyyy')) + interval '1 day';

	raise notice 'p_data_reg_da=%',p_data_reg_da;
	raise notice 'p_data_reg_a=%',p_data_reg_a;

	select ente_denominazione,b.bil_id into nome_ente_in,bil_id_in
	from siac_t_ente_proprietario a,siac_t_bil b,siac_t_periodo c
    where a.ente_proprietario_id=p_ente_prop_id
    and  a.ente_proprietario_id=b.ente_proprietario_id and b.periodo_id=c.periodo_id
	and c.anno=p_anno;

    select fnc_siac_random_user()
	into	user_table;

    raise notice '1 - % ',clock_timestamp()::varchar;

	-- 07.06.2018 Sofia siac-6200
	select a.pdce_conto_id , ambito.ambito_id, ambito.ambito_code
    into   pdce_conto_id_in, pdce_conto_ambito_id, pdce_conto_ambito_code
    from siac_t_pdce_conto a,siac_d_ambito ambito
    where a.ente_proprietario_id=p_ente_prop_id
  	and   a.pdce_conto_code=p_pdce_v_livello
    and   ambito.ambito_id=a.ambito_id
    and   p_anno::integer BETWEEN date_part('year',a.validita_inizio)::integer
    and   coalesce (date_part('year',a.validita_fine)::integer ,p_anno::integer  );

    IF NOT FOUND THEN
    	display_error='Il codice PDCE indicato ('||p_pdce_v_livello||') e'' inesistente';
        return next;
    	return;
    END IF;

    if coalesce(p_ambito,'')!='' and -- 08.06.2018 Sofia siac-6200
       pdce_conto_ambito_code!=p_ambito then
  		display_error='Il codice PDCE indicato ('||p_pdce_v_livello||') non appartiene all''ambito '||p_ambito||' richiesto.';
        return next;
    	return;
    end if;

    -- 08.06.2018 Sofia siac-6200
    select 1 into pdce_conto_esiste_pnota
    from siac_t_prima_nota pn,siac_r_prima_nota_stato rs,siac_d_prima_nota_stato stato,
         siac_t_mov_ep ep, siac_t_mov_ep_det det
    where det.pdce_conto_id=pdce_conto_id_in
    and   ep.movep_id=det.movep_id
    and   pn.pnota_id=ep.regep_id
    and   pn.bil_id=bil_id_in
    and   rs.pnota_id=pn.pnota_id
    and   stato.pnota_stato_id=rs.pnota_stato_id
    and   stato.pnota_stato_code='D'
    --SIAC-6429 aggiunto il date_trunc('day'
    and   date_trunc('day',pn.pnota_dataregistrazionegiornale) between p_data_reg_da
    and   p_data_reg_a
    and   ( case when coalesce(p_ambito,'')!='' then pn.ambito_id=pdce_conto_ambito_id
                 else pn.ambito_id=pn.ambito_id  end )
    and   pn.data_cancellazione is null
    and   pn.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   ep.data_cancellazione is null
    and   ep.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null
    limit 1;

    -- 08.06.2018 Sofia siac-6200
    if pdce_conto_esiste_pnota is null then
    	display_error='Per il codice PDCE indicato ('||p_pdce_v_livello||') non esistono prime note nel periodo richiesto.';
        return next;
    	return;
    end if;

--raise notice 'PDCE livello = %, conto = %, ID = %',  dati_pdce.livello, dati_pdce.pdce_conto_code, dati_pdce.pdce_conto_id;
raise notice 'pdce_conto_id_in=%',pdce_conto_id_in;
--     carico l'intera struttura PDCE
RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL PDCE ''.';
raise notice 'inserimento tabella di comodo STRUTTURA DEL PDCE';

raise notice '2 - % ',clock_timestamp()::varchar;
INSERT INTO
  siac.siac_rep_struttura_pdce
(
  pdce_liv0_id,
  pdce_liv0_id_padre,
  pdce_liv0_code,
  pdce_liv0_desc,
  pdce_liv1_id,
  pdce_liv1_id_padre,
  pdce_liv1_code,
  pdce_liv1_desc,
  pdce_liv2_id,
  pdce_liv2_id_padre,
  pdce_liv2_code,
  pdce_liv2_desc,
  pdce_liv3_id,
  pdce_liv3_id_padre,
  pdce_liv3_code,
  pdce_liv3_desc,
  pdce_liv4_id,
  pdce_liv4_id_padre,
  pdce_liv4_code,
  pdce_liv4_desc,
  pdce_liv5_id,
  pdce_liv5_id_padre,
  pdce_liv5_code,
  pdce_liv5_desc,
  pdce_liv6_id,
  pdce_liv6_id_padre,
  pdce_liv6_code,
  pdce_liv6_desc,
  pdce_liv7_id,
  pdce_liv7_id_padre,
  pdce_liv7_code,
  pdce_liv7_desc,
  utente
)
select zzz.*, user_table from(
with t_pdce_conto0 as (
WITH RECURSIVE my_tree AS
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree where pdce_conto_id=pdce_conto_id_in
),
t_pdce_conto1 as (
WITH RECURSIVE my_tree AS
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree
),
t_pdce_conto2 as (
WITH RECURSIVE my_tree AS
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree
)
,
t_pdce_conto3 as (
WITH RECURSIVE my_tree AS
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree
)
,
t_pdce_conto4 as (
WITH RECURSIVE my_tree AS
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree
)
,
t_pdce_conto5 as (
WITH RECURSIVE my_tree AS
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree
)
,
t_pdce_conto6 as (
WITH RECURSIVE my_tree AS
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree
)
,
t_pdce_conto7 as (
WITH RECURSIVE my_tree AS
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree
)
select
t_pdce_conto7.pdce_conto_id pdce_liv0_id,
t_pdce_conto7.pdce_conto_id_padre pdce_liv0_id_padre,
t_pdce_conto7.pdce_conto_code pdce_liv0_code,
t_pdce_conto7.pdce_conto_desc pdce_liv0_desc,
t_pdce_conto6.pdce_conto_id pdce_liv1_id,
t_pdce_conto6.pdce_conto_id_padre pdce_liv1_id_padre,
t_pdce_conto6.pdce_conto_code pdce_liv1_code,
t_pdce_conto6.pdce_conto_desc pdce_liv1_desc,
t_pdce_conto5.pdce_conto_id pdce_liv2_id,
t_pdce_conto5.pdce_conto_id_padre pdce_liv2_id_padre,
t_pdce_conto5.pdce_conto_code pdce_liv2_code,
t_pdce_conto5.pdce_conto_desc pdce_liv2_desc,
t_pdce_conto4.pdce_conto_id pdce_liv3_id,
t_pdce_conto4.pdce_conto_id_padre pdce_liv3_id_padre,
t_pdce_conto4.pdce_conto_code pdce_liv3_code,
t_pdce_conto4.pdce_conto_desc pdce_liv3_desc,
t_pdce_conto3.pdce_conto_id pdce_liv4_id,
t_pdce_conto3.pdce_conto_id_padre pdce_liv4_id_padre,
t_pdce_conto3.pdce_conto_code pdce_liv4_code,
t_pdce_conto3.pdce_conto_desc pdce_liv4_desc,
t_pdce_conto2.pdce_conto_id pdce_liv5_id,
t_pdce_conto2.pdce_conto_id_padre pdce_liv5_id_padre,
t_pdce_conto2.pdce_conto_code pdce_liv5_code,
t_pdce_conto2.pdce_conto_desc pdce_liv5_desc,
t_pdce_conto1.pdce_conto_id pdce_liv6_id,
t_pdce_conto1.pdce_conto_id_padre pdce_liv6_id_padre,
t_pdce_conto1.pdce_conto_code pdce_liv6_code,
t_pdce_conto1.pdce_conto_desc pdce_liv6_desc,
t_pdce_conto0.pdce_conto_id pdce_liv7_id,
t_pdce_conto0.pdce_conto_id_padre pdce_liv7_id_padre,
t_pdce_conto0.pdce_conto_code pdce_liv7_code,
t_pdce_conto0.pdce_conto_desc pdce_liv7_desc
 from t_pdce_conto0 left join t_pdce_conto1
on t_pdce_conto0.livello-1=t_pdce_conto1.livello
left join t_pdce_conto2
on t_pdce_conto1.livello-1=t_pdce_conto2.livello
left join t_pdce_conto3
on t_pdce_conto2.livello-1=t_pdce_conto3.livello
left join t_pdce_conto4
on t_pdce_conto3.livello-1=t_pdce_conto4.livello
left join t_pdce_conto5
on t_pdce_conto4.livello-1=t_pdce_conto5.livello
left join t_pdce_conto6
on t_pdce_conto5.livello-1=t_pdce_conto6.livello
left join t_pdce_conto7
on t_pdce_conto6.livello-1=t_pdce_conto7.livello
) as zzz;

raise notice '3 - % ',clock_timestamp()::varchar;
RTN_MESSAGGIO:='Estrazione dei dati delle prime note''.';
raise notice 'Estrazione dei dati delle prime note';

return query
select outp.* from (
with ord as (--ORD
SELECT
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
'ORD'::varchar tipo_pnota,
c.evento_code::varchar prov_pnota,
s.soggetto_code::varchar cod_soggetto,
s.soggetto_desc::varchar       descr_soggetto,
'ORD'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
q.ord_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,
g.evento_tipo_code::varchar  tipo_movimento,
q.ord_emissione_data::date data_det_rif,
--SIAC-6279: 26/06/2018.
-- La data di registrazione e' la pnota_dataregistrazionegiornale
-- che e' sempre valorizzata perche' sono estratte solo le prime note
-- in stato definitivio.
--m.data_creazione::date  data_registrazione,
m.pnota_dataregistrazionegiornale::date  data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
m.ambito_id ambito_prima_nota_id,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_ordinativo q,
       siac_r_ordinativo_soggetto  r,
       siac_t_soggetto  s
WHERE d.collegamento_tipo_code in ('OI','OP') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and
        m.bil_id=bil_id_in
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and
        o.pnota_stato_code='D' and
        --SIAC-6429 aggiunto il date_trunc('day'
        date_trunc('day',m.pnota_dataregistrazionegiornale) between
        p_data_reg_da and
p_data_reg_a  and
        q.ord_id=b.campo_pk_id and
        r.ord_id=q.ord_id and
        s.soggetto_id=r.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL
     --   limit 1
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union
union all
select impacc.* from (
--A,I
with movgest as (
SELECT
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
case when d.collegamento_tipo_code = 'I' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 c.evento_code::varchar prov_pnota,
case when d.collegamento_tipo_code = 'I' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
q.movgest_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,
g.evento_tipo_code::varchar  tipo_movimento,
--SIAC-6279: 26/06/2018.
-- nel caso di impegni e accertamenti la data di riferimento e' quella di 
-- creazione del movimento
--null::date data_det_rif,
q.data_creazione::date data_det_rif,
--SIAC-6279: 26/06/2018.
-- La data di registrazione e' la pnota_dataregistrazionegiornale
-- che e' sempre valorizzata perche' sono estratte solo le prime note
-- in stato definitivio.
--m.data_creazione::date  data_registrazione,
m.pnota_dataregistrazionegiornale::date  data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
m.ambito_id ambito_prima_nota_id,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere
, q.movgest_id
 FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_movgest q
WHERE d.collegamento_tipo_code in ('I','A') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and
        m.bil_id=bil_id_in
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and
        o.pnota_stato_code='D' and
        --SIAC-6429 aggiunto il date_trunc('day'
        date_trunc('day',m.pnota_dataregistrazionegiornale) between
        p_data_reg_da and
p_data_reg_a
and q.movgest_id=b.campo_pk_id and
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL AND
g.data_cancellazione IS NULL AND
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
q.data_cancellazione IS NULL
),
--SIAC-7650  28/05/2020.
-- per i soggetti e la classe di soggetti aggiunto il test su 
-- siac_d_movgest_ts_tipo.movgest_ts_tipo_code='T'
-- per evitare che siano presi sutti i sub-impegni.
sogcla as (
select distinct c.movgest_id,b.soggetto_classe_code,b.soggetto_classe_desc
From  siac_r_movgest_ts_sogclasse a,siac_d_soggetto_classe b,
siac_t_movgest c,siac_t_movgest_ts d,
siac_d_movgest_ts_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and b.soggetto_classe_id=a.soggetto_classe_id
and c.movgest_id=d.movgest_id
and d.movgest_ts_id=a.movgest_ts_id
and d.movgest_ts_tipo_id= e.movgest_ts_tipo_id
and e.movgest_ts_tipo_code='T'
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
),
sog as (
select c.movgest_id, b.soggetto_id,
b.soggetto_code,b.soggetto_desc from siac_r_movgest_ts_sog a,
siac_t_soggetto b,siac_t_movgest c,siac_t_movgest_ts d,
siac_d_movgest_ts_tipo e
where a.ente_proprietario_id=p_ente_prop_id 
and b.soggetto_id=a.soggetto_id
and c.movgest_id=d.movgest_id
and d.movgest_ts_id=a.movgest_ts_id
and d.movgest_ts_tipo_id= e.movgest_ts_tipo_id
and e.movgest_ts_tipo_code='T'
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
)
select
movgest.pnota_dataregistrazionegiornale,
movgest.num_prima_nota,
movgest.tipo_pnota,
movgest.prov_pnota,
	--SIAC-7650  28/05/2020.
    -- aggiunto COALESCE
case when sog.soggetto_id is null then 
		COALESCE(sogcla.soggetto_classe_code,'') 
    else COALESCE(sog.soggetto_code,'') end  cod_soggetto,
case when sog.soggetto_id is null then 
		COALESCE(sogcla.soggetto_classe_desc,'') 
    else COALESCE(sog.soggetto_desc,'') end descr_soggetto,
movgest.tipo_documento,
movgest.data_registrazione_movimento,
movgest.numero_documento,
movgest.num_det_rif,
movgest.ente_proprietario_id,
movgest.pdce_conto_id,
movgest.tipo_movimento,
movgest.data_det_rif,
movgest.data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
movgest.ambito_prima_nota_id,
movgest.importo_dare,
movgest.importo_avere
 from movgest left join sogcla on
movgest.movgest_id=sogcla.movgest_id
left join sog on
movgest.movgest_id=sog.movgest_id
) as impacc
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union
union all
select impsubacc.* from (
--SA,SI
with movgest as (
SELECT
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
case when d.collegamento_tipo_code = 'SI' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 c.evento_code::varchar prov_pnota,
case when d.collegamento_tipo_code = 'SI' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.movgest_numero||'-'||q.movgest_ts_code::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,
g.evento_tipo_code::varchar  tipo_movimento,
--SIAC-6279: 26/06/2018.
-- nel caso di sub-impegni e sub-accertamenti la data di riferimento e' 
-- quella di creazione del movimento
--null::date data_det_rif,
q.data_creazione::date data_det_rif,
--SIAC-6279: 26/06/2018.
-- La data di registrazione e' la pnota_dataregistrazionegiornale
-- che e' sempre valorizzata perche' sono estratte solo le prime note
-- in stato definitivio.
--m.data_creazione::date  data_registrazione,
m.pnota_dataregistrazionegiornale::date  data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
m.ambito_id ambito_prima_nota_id,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere
, q.movgest_ts_id
 FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_movgest_ts q,siac_t_movgest r
WHERE d.collegamento_tipo_code in ('SI','SA') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and
        m.bil_id=bil_id_in
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and
        o.pnota_stato_code='D' and
        --SIAC-6429 aggiunto il date_trunc('day'
        date_trunc('day',m.pnota_dataregistrazionegiornale) between
        p_data_reg_da and
p_data_reg_a
and q.movgest_ts_id =b.campo_pk_id and
r.movgest_id=q.movgest_id and
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL AND
g.data_cancellazione IS NULL AND
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
q.data_cancellazione IS NULL and
r.data_cancellazione IS NULL
),
sogcla as (
select distinct d.movgest_ts_id ,b.soggetto_classe_code,b.soggetto_classe_desc
From  siac_r_movgest_ts_sogclasse a,siac_d_soggetto_classe b,siac_t_movgest_ts d where a.ente_proprietario_id=p_ente_prop_id
and b.soggetto_classe_id=a.soggetto_classe_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
),
sog as (
select d.movgest_ts_id, b.soggetto_id,
b.soggetto_code,b.soggetto_desc from siac_r_movgest_ts_sog a,
siac_t_soggetto b,siac_t_movgest_ts d
where a.ente_proprietario_id=p_ente_prop_id and b.soggetto_id=a.soggetto_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
)
select
movgest.pnota_dataregistrazionegiornale,
movgest.num_prima_nota,
movgest.tipo_pnota,
movgest.prov_pnota,
case when sog.soggetto_id is null then sogcla.soggetto_classe_code else sog.soggetto_code end  cod_soggetto,
case when sog.soggetto_id is null then sogcla.soggetto_classe_desc else sog.soggetto_desc end descr_soggetto,
movgest.tipo_documento,
movgest.data_registrazione_movimento,
movgest.numero_documento,
movgest.num_det_rif,
movgest.ente_proprietario_id,
movgest.pdce_conto_id,
movgest.tipo_movimento,
movgest.data_det_rif,
movgest.data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
movgest.ambito_prima_nota_id,
movgest.importo_dare,
movgest.importo_avere
 from movgest left join sogcla on
movgest.movgest_ts_id=sogcla.movgest_ts_id
left join sog on
movgest.movgest_ts_id=sog.movgest_ts_id
) as impsubacc
--'MMGE','MMGS'
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union
union all
select impsubaccmod.* from (
with movgest as (
with modge as (select tbz.* from (
with modprnoteint as (
select
g.campo_pk_id,
a.pnota_dataregistrazionegiornale,
a.pnota_progressivogiornale::integer num_prima_nota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 h.evento_code::varchar prov_pnota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_documento ,
e.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
a.ente_proprietario_id,
e.pdce_conto_id,
l.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
--SIAC-6279: 26/06/2018.
-- La data di registrazione e' la pnota_dataregistrazionegiornale
-- che e' sempre valorizzata perche' sono estratte solo le prime note
-- in stato definitivio.
--a.data_creazione::date  data_registrazione,
a.pnota_dataregistrazionegiornale::date  data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
a.ambito_id ambito_prima_nota_id,
case when  e.movep_det_segno='Dare' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,
case when  e.movep_det_segno='Avere' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere
from
siac_t_prima_nota a
,siac_r_prima_nota_stato b,
siac_d_prima_nota_stato c,
siac_t_mov_ep d,
siac_t_mov_ep_det e,
siac_t_reg_movfin f,
siac_r_evento_reg_movfin g,
siac_d_evento h,
siac_d_collegamento_tipo i,
siac_d_evento_tipo l
where a.ente_proprietario_id=p_ente_prop_id
and a.bil_id=bil_id_in
and b.pnota_id=a.pnota_id
and i.collegamento_tipo_code in ('MMGS','MMGE')
and c.pnota_stato_id=b.pnota_stato_id
--SIAC-6429 aggiunto il date_trunc('day'
and   date_trunc('day',a.pnota_dataregistrazionegiornale) between  p_data_reg_da and
p_data_reg_a
and b.validita_fine is null
and d.regep_id=a.pnota_id
and e.movep_id=d.movep_id
and f.regmovfin_id=d.regmovfin_id
and g.regmovfin_id=f.regmovfin_id
and g.validita_fine is null
and h.evento_id=g.evento_id
and i.collegamento_tipo_id=h.collegamento_tipo_id
and l.evento_tipo_id=h.evento_tipo_id
and c.pnota_stato_code='D'
and  a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
and l.data_cancellazione is null
)
,
moddd as (
select m.mod_id,n.mod_stato_r_id
 from siac_t_modifica m,
siac_r_modifica_stato n,
siac_d_modifica_stato o
where m.ente_proprietario_id=p_ente_prop_id
and n.mod_id=m.mod_id
and n.validita_fine is null
and o.mod_stato_id=n.mod_stato_id
and m.data_cancellazione is null
and n.data_cancellazione is null
and o.data_cancellazione is null
)
select
moddd.mod_stato_r_id,
modprnoteint.pnota_dataregistrazionegiornale,
modprnoteint.num_prima_nota,
modprnoteint.tipo_pnota,
modprnoteint.prov_pnota,
modprnoteint.tipo_documento,
modprnoteint.data_registrazione_movimento,
modprnoteint.numero_documento,
modprnoteint.ente_proprietario_id,
modprnoteint.pdce_conto_id,
modprnoteint.tipo_movimento,
modprnoteint.data_det_rif,
modprnoteint.data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
modprnoteint.ambito_prima_nota_id,
modprnoteint.importo_dare,
modprnoteint.importo_avere
 from modprnoteint join moddd
on  moddd.mod_id=modprnoteint.campo_pk_id)
as tbz
) ,
modsog as (
select p.mod_stato_r_id,q.movgest_ts_id,r.movgest_numero||'-'||q.movgest_ts_code num_det_rif
 from
siac_r_movgest_ts_sog_mod p,siac_t_movgest_ts q,siac_t_movgest r
where
p.ente_proprietario_id=p_ente_prop_id and
 q.movgest_ts_id=p.movgest_ts_id
and r.movgest_id=q.movgest_id
and p.data_cancellazione is null
and q.data_cancellazione is null
and r.data_cancellazione is null)
,
modimp as (
select p.mod_stato_r_id,q.movgest_ts_id
,r.movgest_numero||'-'||q.movgest_ts_code num_det_rif
from
siac_t_movgest_ts_det_mod p,siac_t_movgest_ts q,siac_t_movgest r
where
p.ente_proprietario_id=p_ente_prop_id and
 q.movgest_ts_id=p.movgest_ts_id
and r.movgest_id=q.movgest_id
and p.data_cancellazione is null
and q.data_cancellazione is null
and r.data_cancellazione is null)
select
modge.pnota_dataregistrazionegiornale,
modge.num_prima_nota,
modge.tipo_pnota,
modge.prov_pnota,
modge.tipo_documento ,--uguale a tipo_pnota,
modge.data_registrazione_movimento,
modge.numero_documento,
case when modsog.movgest_ts_id is null then modimp.num_det_rif else modsog.num_det_rif end num_det_rif,
modge.ente_proprietario_id,
modge.pdce_conto_id,
modge.tipo_movimento,
modge.data_det_rif,
modge.data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
modge.ambito_prima_nota_id,
modge.importo_dare,
modge.importo_avere
, case when modsog.movgest_ts_id is null then modimp.movgest_ts_id else modsog.movgest_ts_id end movgest_ts_id
from modge left join
modsog on modge.mod_stato_r_id=modsog.mod_stato_r_id
left join
modimp on modge.mod_stato_r_id=modimp.mod_stato_r_id
),
sogcla as (
select distinct d.movgest_ts_id ,b.soggetto_classe_code,b.soggetto_classe_desc
From  siac_r_movgest_ts_sogclasse a,siac_d_soggetto_classe b,siac_t_movgest_ts d where a.ente_proprietario_id=p_ente_prop_id
and b.soggetto_classe_id=a.soggetto_classe_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
),
sog as (
select d.movgest_ts_id, b.soggetto_id,
b.soggetto_code,b.soggetto_desc from siac_r_movgest_ts_sog a,
siac_t_soggetto b,siac_t_movgest_ts d
where a.ente_proprietario_id=p_ente_prop_id and b.soggetto_id=a.soggetto_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
)
select
movgest.pnota_dataregistrazionegiornale,
movgest.num_prima_nota,
movgest.tipo_pnota,
movgest.prov_pnota,
case when sog.soggetto_id is null then sogcla.soggetto_classe_code else sog.soggetto_code end  cod_soggetto,
case when sog.soggetto_id is null then sogcla.soggetto_classe_desc else sog.soggetto_desc end descr_soggetto,
movgest.tipo_documento,
movgest.data_registrazione_movimento,
movgest.numero_documento,
movgest.num_det_rif,
movgest.ente_proprietario_id,
movgest.pdce_conto_id,
movgest.tipo_movimento,
movgest.data_det_rif,
movgest.data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
movgest.ambito_prima_nota_id,
movgest.importo_dare,
movgest.importo_avere
 from movgest left join sogcla on
movgest.movgest_ts_id=sogcla.movgest_ts_id
left join sog on
movgest.movgest_ts_id=sog.movgest_ts_id
) as impsubaccmod
--LIQ
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union
union all
SELECT
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
'LIQ'::varchar tipo_pnota,
 c.evento_code::varchar prov_pnota,
s.soggetto_code::varchar cod_soggetto,
 s.soggetto_desc::varchar       descr_soggetto,
'LIQ'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
q.liq_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,
g.evento_tipo_code::varchar  tipo_movimento,
q.liq_emissione_data::date data_det_rif,
--SIAC-6279: 26/06/2018.
-- La data di registrazione e' la pnota_dataregistrazionegiornale
-- che e' sempre valorizzata perche' sono estratte solo le prime note
-- in stato definitivio.
--m.data_creazione::date  data_registrazione,
m.pnota_dataregistrazionegiornale::date  data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
m.ambito_id ambito_prima_nota_id,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_liquidazione q,
       siac_r_liquidazione_soggetto  r,
       siac_t_soggetto  s
WHERE d.collegamento_tipo_code in ('L') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and
        m.bil_id=bil_id_in
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and
        o.pnota_stato_code='D' and
        --SIAC-6429 aggiunto il date_trunc('day'
        date_trunc('day',m.pnota_dataregistrazionegiornale) between
        p_data_reg_da and p_data_reg_a  and
        q.liq_id=b.campo_pk_id and
        r.liq_id=q.liq_id and
        s.soggetto_id=r.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union
union all
--DOC
SELECT
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
'FAT'::varchar tipo_pnota,
 c.evento_code::varchar prov_pnota,
t.soggetto_code::varchar cod_soggetto,
 t.soggetto_desc::varchar       descr_soggetto,
'FAT'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.doc_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,
g.evento_tipo_code::varchar  tipo_movimento,
r.doc_data_emissione::date data_det_rif,
--SIAC-6279: 26/06/2018.
-- La data di registrazione e' la pnota_dataregistrazionegiornale
-- che e' sempre valorizzata perche' sono estratte solo le prime note
-- in stato definitivio.
--m.data_creazione::date  data_registrazione,
m.pnota_dataregistrazionegiornale::date  data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
m.ambito_id ambito_prima_nota_id,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_subdoc q,
       siac_t_doc  r,
       siac_r_doc_sog s,
       siac_t_soggetto t
WHERE d.collegamento_tipo_code in ('SS','SE') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and
        m.bil_id=bil_id_in
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and
        o.pnota_stato_code='D' and
        --SIAC-6429 aggiunto il date_trunc('day'
        date_trunc('day',m.pnota_dataregistrazionegiornale) between
        p_data_reg_da and p_data_reg_a  and
        q.subdoc_id=b.campo_pk_id and
        r.doc_id=q.doc_id and
        s.doc_id=r.doc_id and
        s.soggetto_id=t.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union
union all
--lib
SELECT
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
case when dd.evento_code='AAP' then 'AAP'::varchar when dd.evento_code='APP' then 'APP'::varchar
else 'LIB'::varchar end tipo_pnota,
 dd.evento_code::varchar prov_pnota,
m.pnota_desc::varchar cod_soggetto,
 ''::varchar       descr_soggetto,
'LIB'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
''::varchar num_det_rif,
m.ente_proprietario_id,
p.pdce_conto_id,
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
--SIAC-6279: 26/06/2018.
-- La data di registrazione e' la pnota_dataregistrazionegiornale
-- che e' sempre valorizzata perche' sono estratte solo le prime note
-- in stato definitivio.
--m.data_creazione::date  data_registrazione,
m.pnota_dataregistrazionegiornale::date  data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
m.ambito_id ambito_prima_nota_id,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere
  FROM siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
siac_t_causale_ep	aa,
siac_d_causale_ep_tipo bb,
siac_r_evento_causale cc,
siac_d_evento dd,
siac_d_evento_tipo g
where
l.ente_proprietario_id=p_ente_prop_id
and l.regep_id=m.pnota_id
and n.pnota_id=m.pnota_id
and o.pnota_stato_id=n.pnota_stato_id
and p.movep_id=l.movep_id
and aa.causale_ep_id=l.causale_ep_id
and bb.causale_ep_tipo_id=aa.causale_ep_tipo_id
and bb.causale_ep_tipo_code='LIB'
and cc.causale_ep_id=aa.causale_ep_id
and dd.evento_id=cc.evento_id
and g.evento_tipo_id=dd.evento_tipo_id and
--SIAC-6429 aggiunto il date_trunc('day'
 date_trunc('day',m.pnota_dataregistrazionegiornale) between
        p_data_reg_da and p_data_reg_a  and
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
aa.data_cancellazione IS NULL AND
bb.data_cancellazione IS NULL AND
cc.data_cancellazione IS NULL AND
dd.data_cancellazione IS NULL AND
g.data_cancellazione IS NULL
AND  n.validita_fine IS NULL
AND  cc.validita_fine IS NULL
AND  m.bil_id = bil_id_in
AND  o.pnota_stato_code = 'D' -- SIAC-5893
        )
        ,cc as
        ( WITH RECURSIVE my_tree AS
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_code, my_tree.livello
from my_tree
),
bb as (select * from siac_rep_struttura_pdce bb where bb.utente=user_table)
         select
nome_ente_in,
bb.pdce_liv0_id::integer  id_pdce0 ,
bb.pdce_liv0_code::varchar codice_pdce0 ,
bb.pdce_liv0_desc  descr_pdce0 ,
bb.pdce_liv1_id id_pdce1,
bb.pdce_liv1_code::varchar  codice_pdce1 ,
bb.pdce_liv1_desc::varchar  descr_pdce1 ,
bb.pdce_liv2_id  id_pdce2 ,
bb.pdce_liv2_code::varchar codice_pdce2 ,
bb.pdce_liv2_desc::varchar  descr_pdce2 ,
bb.pdce_liv3_id  id_pdce3 ,
bb.pdce_liv3_code::varchar  codice_pdce3 ,
bb.pdce_liv3_desc::varchar  descr_pdce3 ,
bb.pdce_liv4_id   id_pdce4 ,
bb.pdce_liv4_code::varchar  codice_pdce4 ,
bb.pdce_liv4_desc::varchar  descr_pdce4 ,
bb.pdce_liv5_id   id_pdce5 ,
bb.pdce_liv5_code::varchar  codice_pdce5 ,
bb.pdce_liv5_desc::varchar  descr_pdce5 ,
bb.pdce_liv6_id   id_pdce6 ,
bb.pdce_liv6_code::varchar  codice_pdce6 ,
bb.pdce_liv6_desc::varchar  descr_pdce6 ,
bb.pdce_liv7_id   id_pdce7 ,
bb.pdce_liv7_code::varchar  codice_pdce7 ,
bb.pdce_liv7_desc::varchar  descr_pdce7 ,
coalesce(bb.pdce_liv8_id,0)::integer   id_pdce8 ,
coalesce(bb.pdce_liv8_code,'')::varchar  codice_pdce8 ,
coalesce(bb.pdce_liv8_desc,'')::varchar  descr_pdce8,
ord.data_registrazione,
ord.num_prima_nota,
ord.tipo_pnota tipo_pnota,
ord.prov_pnota,
ord.cod_soggetto,
ord.descr_soggetto,
ord.tipo_documento tipo_documento,--uguale a tipo_pnota,
ord.data_registrazione_movimento,
''::varchar numero_documento,
ord.num_det_rif,
ord.data_det_rif,
ord.importo_dare,
ord.importo_avere,
--bb.livello::integer,
cc.livello::integer,
ord.tipo_movimento,
0::numeric  saldo_prec_dare,
0::numeric  saldo_prec_avere ,
0::numeric saldo_ini_dare ,
0::numeric saldo_ini_avere ,
--bb.codice_conto::varchar   code_pdce_livello ,
cc.pdce_conto_code::varchar   code_pdce_livello ,
''::varchar  display_error
from ord
     join cc on ord.pdce_conto_id=cc.pdce_conto_id
     cross join bb
where -- 08.06/2018 Sofia SIAC-6200
     ( case when coalesce(p_ambito,'')!='' then ord.ambito_prima_nota_id=pdce_conto_ambito_id
            else ord.ambito_prima_nota_id=ord.ambito_prima_nota_id end )
) as outp;

delete from siac_rep_struttura_pdce 	where utente=user_table;

exception
	when no_data_found THEN
		raise notice 'Prime note non trovate' ;
		--return next;
	when others  THEN
		--raise notice 'errore nella lettura delle prime note ';
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'MASTRINO',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

--SIAC-7650 - Maurizio - FINE


--SIAC-7195 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR024_Allegato_7_Allegato_delibera_variaz_totali_entrate_txt" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  stanziato_totale numeric,
  cassa_totale numeric,
  residuo_totale numeric
) AS
$body$
DECLARE

DataSetAtti record;
contaRec integer;

annoCapImp varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_titolotipologiacategoria varchar:='00003';
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;
bilancio_id integer;
stanz_tot numeric;
cassa_tot numeric;
residui_tot numeric;
importi_var_capitoli numeric;

BEGIN

--annoCapImp:= p_anno; 
annoCapImp:=p_anno_competenza;

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-EG'; -- tipo capitolo gestione


stanziato_totale=0;
cassa_totale=0;
residuo_totale=0;

    
/* Funzione nata per la SIAC-7195 per la gestione dei file in formato testo 
	per Unicredit.
    La funzione estrae i totali complessivi che comprendono i dati delle variazioni
    considerate da i parametri in input. 
*/

select fnc_siac_random_user()
into	user_table;

select a.bil_id 
	into bilancio_id 
from siac_t_bil a,
		siac_t_periodo b
where b.periodo_id=a.periodo_id
	and a.ente_proprietario_id=p_ente_prop_id 
	and b.anno=p_anno
    and a.data_cancellazione IS NULL
    and b.data_cancellazione IS NULL;
    
raise notice '1 - %' , clock_timestamp()::text;

	--dati variabili dei capitoli.
select sum(stanziato)-sum(variazione_aumento)+sum(variazione_diminuzione)
	into importi_var_capitoli
from "BILR024_Allegato_7_Allegato_delibera_variazione_variabili" 
	(p_ente_prop_id,p_anno,p_numero_delibera,p_anno_delibera,p_tipo_delibera,
    p_anno_competenza,p_ele_variazioni,' ') 
where tipologia_capitolo in('AAM','FPVSC','FPVCC');

/* carico sulla tabella di appoggio siac_rep_cap_ug_imp gli importi dei capitoli
    	decrementando gli importi delle varizioni successive a quelle 
        specificate in input. */
strQuery:= 'with cap as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,           
            capitolo_imp_tipo.elem_det_tipo_id,
            sum(capitolo_importi.elem_det_importo) importo_cap
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,            
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_t_bil_elem 			capitolo	             			            
     where 	capitolo_importi.ente_proprietario_id 	='||p_ente_prop_id||' 
        and	anno_eserc.anno						= 	'''||p_anno||'''												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno  =  '''||p_anno_competenza||'''
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code		=	''VA''								
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and cat_del_capitolo.elem_cat_code		in (''STD'')
        and capitolo_imp_tipo.elem_det_tipo_code in (''STA'',''SCA'',''STR'')						
 		and	capitolo_importi.data_cancellazione 		is null
        and	capitolo_imp_tipo.data_cancellazione 		is null
       	and	capitolo_imp_periodo.data_cancellazione 	is null
        and	capitolo.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione 			is null
        and	bilancio.data_cancellazione 				is null
	 	and	anno_eserc.data_cancellazione 				is null 
	 	and	stato_capitolo.data_cancellazione 			is null 
    	and	r_capitolo_stato.data_cancellazione 		is null
	 	and cat_del_capitolo.data_cancellazione 		is null
    	and	r_cat_capitolo.data_cancellazione 			is null
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id,  cat_del_capitolo.elem_cat_code,
    	capitolo_imp_tipo.elem_det_tipo_id),
        -- SIAC-7200 nella query che estrae le variazioni successive, aggiunto
        --  il test sull''anno (periodo_id) che lega la variazione corrente
        --  (siac_t_variazione avar) a quelle successive (siac_t_variazione avarsucc).
 importi_variaz as(    with varcurr as (              
      select dvar.elem_id elem_id_var, bvar.validita_inizio, dvar.periodo_id,
          dvar.elem_det_tipo_id
      from 
      siac_t_variazione avar, siac_r_variazione_stato bvar,
      siac_d_variazione_stato cvar, siac_t_bil_elem_det_var dvar, siac_t_periodo periodo_importo_variazione
      where avar.variazione_id=bvar.variazione_id
      and bvar.variazione_stato_tipo_id=cvar.variazione_stato_tipo_id
      and dvar.variazione_stato_id=bvar.variazione_stato_id         
      and cvar.variazione_stato_tipo_code=''D''                            
      and bvar.data_cancellazione is null
      and bvar.variazione_stato_id in (';
if p_numero_delibera IS NOT NULL THEN  --specifico un atto.
strQuery:=strQuery||'                      
            select max(var_stato.variazione_stato_id)
            from siac_t_atto_amm             atto,
              siac_d_atto_amm_tipo        tipo_atto,
              siac_r_atto_amm_stato         r_atto_stato,
              siac_d_atto_amm_stato         stato_atto,
              siac_r_variazione_stato     var_stato
            where
              (var_stato.attoamm_id = atto.attoamm_id 
                 or var_stato.attoamm_id_varbil = atto.attoamm_id )                  
              and     r_atto_stato.attoamm_id   =   atto.attoamm_id 
              and     r_atto_stato.attoamm_stato_id     =   stato_atto.attoamm_stato_id
              and     atto.ente_proprietario_id   =   '||p_ente_prop_id||'
              and     atto.attoamm_numero=  '||p_numero_delibera||'
              and     atto.attoamm_anno  =  '''||p_anno_delibera||'''                 
              and     tipo_atto.attoamm_tipo_code  = '''||p_tipo_delibera||'''
              and     stato_atto.attoamm_stato_code   =   ''DEFINITIVO'') ';
else        -- specificato l'elenco delle variazione.          
      	strQuery:=strQuery||'     
                select max(var_stato.variazione_stato_id)
                from siac_t_variazione t_var,
                  siac_r_variazione_stato     var_stato
                where
                  t_var.variazione_id = var_stato.variazione_id
                  and t_var.ente_proprietario_id = '||p_ente_prop_id||'
                  and t_var.variazione_num in('||p_ele_variazioni||')
                  and t_var.data_cancellazione IS NULL
                  and var_stato.data_cancellazione IS NULL )
                  and periodo_importo_variazione.periodo_id = dvar.periodo_id           --  SIAC-7311
                  and periodo_importo_variazione.anno =  '''||p_anno_competenza||'''';  -- 	SIAC-7311                                   
end if;                
		
strQuery:=strQuery||'),
      varsuccess as (select dvarsucc.elem_id elem_id_var, tipoimp.elem_det_tipo_id,
          dvarsucc.periodo_id, bvarsucc.validita_inizio,
          COALESCE(dvarsucc.elem_det_importo,0) importo_var
          from siac_t_variazione avarsucc, siac_r_variazione_stato bvarsucc,              
          siac_d_variazione_stato cvarsucc,
          siac_t_bil_elem_det_var dvarsucc,
          siac_d_bil_elem_det_tipo tipoimp,
          siac_t_periodo periodo_importo_variazione
          where avarsucc.variazione_id= bvarsucc.variazione_id
          and bvarsucc.variazione_stato_tipo_id=cvarsucc.variazione_stato_tipo_id
          and dvarsucc.variazione_stato_id = bvarsucc.variazione_stato_id
          and tipoimp.elem_det_tipo_id = dvarsucc.elem_det_tipo_id
          and dvarsucc.ente_proprietario_id= '||p_ente_prop_id||'                            
          and cvarsucc.variazione_stato_tipo_code=''D''   
          and periodo_importo_variazione.periodo_id = dvarsucc.periodo_id      --  SIAC-7311
          and periodo_importo_variazione.anno =   '''||p_anno_competenza||'''  --  SIAC-7311                                      
          and bvarsucc.data_cancellazione is null
          and dvarsucc.data_cancellazione IS NULL)
      select  varsuccess.elem_id_var, varsuccess.elem_det_tipo_id,
              sum(varsuccess.importo_var) totale_var_succ
      from varcurr
            JOIN varsuccess
              on (varcurr.elem_det_tipo_id = varsuccess.elem_det_tipo_id
                    and varcurr.periodo_id = varsuccess.periodo_id
                    and varsuccess.validita_inizio > varcurr.validita_inizio
                    and varcurr.elem_id_var = varsuccess.elem_id_var) 		   --  SIAC-7311
      group by varsuccess.elem_id_var, varsuccess.elem_det_tipo_id  )    
                    INSERT INTO siac_rep_cap_eg_imp
                    select 	cap.elem_id, 
                              cap.BIL_ELE_IMP_ANNO, 
                              cap.TIPO_IMP,
                              cap.ente_proprietario_id, 
                              '''||user_table||''' utente,               
                              (cap.importo_cap  - COALESCE(importi_variaz.totale_var_succ,0)) diff
                    from cap LEFT  JOIN importi_variaz 
                    ON (cap.elem_id = importi_variaz.elem_id_var
                      and cap.elem_det_tipo_id= importi_variaz.elem_det_tipo_id);';
raise notice 'Query1 = %', strQuery;                

raise notice 'Inizio query importi capitoli - %' , clock_timestamp()::text;

execute  strQuery;

	--stanziato totale
select sum(importo)
into stanziato_totale
from siac_rep_cap_eg_imp
where ente_proprietario=p_ente_prop_id
and tipo_imp= 'STA'
and utente = user_table;

	--allo stanziato aggiungo i dati dei capitoli.
stanziato_totale:=stanziato_totale+importi_var_capitoli;

	--cassa
select sum(importo)
into cassa_totale
from siac_rep_cap_eg_imp
where ente_proprietario=p_ente_prop_id
and tipo_imp= 'SCA'
and utente = user_table;

	--residuo
select sum(importo)
into residuo_totale
from siac_rep_cap_eg_imp
where ente_proprietario=p_ente_prop_id
and tipo_imp= 'STR'
and utente = user_table;

return next;

delete from siac_rep_cap_eg_imp where utente = user_table;

raise notice 'fine OK';

exception
	when no_data_found THEN
		raise notice 'nessun atto trovato' ;
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
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac.fnc_tracciato_t2sb22s (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar,
  p_organo_provv varchar,
  p_code_report varchar,
  p_codice_ente varchar
)
RETURNS TABLE (
  record_t2sb22s varchar
) AS
$body$
DECLARE

prefisso varchar;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

begin
	
/*
	27/05/2020. 
    Funzione nata per la SIAC-7195.
    La funziona prepara i dati del tracciato t2sb22s.
    Riceve in input i parametri di estrazione dei dati ed il codice report.
    In base al report richiama le procedure corrette.
    Funziona solo per il report BILR139.

*/
	
if p_code_report = 'BILR139' then
    return query 
      select (--CIST
          '00001'  || 
              --CENT codice ente 
          p_codice_ente  || 
              --CESE codice esercizio
          p_anno_competenza  || 
              -- NDEL Numero Delibera
          LPAD(spese.attoamm_numero::varchar,7,'0') ||          
              --SORG Organo deliberante
          case when p_organo_provv is null or p_organo_provv = '' then 
              ' ' else p_organo_provv  end || 
              -- CTIPREC tipo record
          '2'   ||
           	  -- SEOU INDICATORE ENTRATA/USCITA (fisso 2 = Uscita)
          '2'  ||
			  -- NCAP Codifica di Bilancio
          LPAD(spese.codifica_bil, 7, '0') ||
          	  -- NART Numero Articolo
          '000' ||
          		--NRES Anno Residuo ??
          p_anno_competenza ||
          		--IPIUFNV Importo Variazione PIU' fondo vincolato
          trim(replace(to_char(spese.variazione_aumento_stanziato ,
          		'000000000000000.00'),'.','')) ||         
          		--IMENFNV Importo Variazione MENO Competenza
          trim(replace(to_char(spese.variazione_diminuzione_stanziato ,
          		'000000000000000.00'),'.','')) ||
                --ZDES Descrizione delibera
          RPAD(left(spese.attoamm_oggetto,50),50,' ') ||
                --FILLER 
          RPAD(' ', 276, ' '))::varchar
      from (
      	select  attoamm_anno,
            attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
            data_provv_var, data_approvazione_provv,
            programma_code||titusc_code codifica_bil, 
            titusc_desc descr_codifica_bil,
            sum(variazione_aumento_residuo) variazione_aumento_residuo,
            sum(variazione_aumento_stanziato) variazione_aumento_stanziato,
            sum(variazione_aumento_cassa) variazione_aumento_cassa,
            sum(variazione_diminuzione_residuo) variazione_diminuzione_residuo,
            sum(variazione_diminuzione_stanziato) variazione_diminuzione_stanziato,
            sum(variazione_diminuzione_cassa) variazione_diminuzione_cassa                          
        from "BILR139_Allegato_8_Allegato_delibera_variazion_su_spese_fpv_txt" (
          p_ente_prop_id, p_anno ,
          p_numero_delibera, p_anno_delibera, p_tipo_delibera,
          p_anno_competenza, p_ele_variazioni)            
    	group by  attoamm_anno,
            attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
            data_provv_var, data_approvazione_provv,
            codifica_bil, descr_codifica_bil
      order by attoamm_id, codifica_bil) spese;
else
	record_t2sb22s:= 'Il REPORT '||p_code_report|| ' NON E'' GESTITO IN QUESTO FORMATO';
    return next;
    return;	       
end if;
	

exception
    when syntax_error THEN
    	record_t2sb22s='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	record_t2sb22s='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
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
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac.fnc_tracciato_t2sb21s (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar,
  p_organo_provv varchar,
  p_code_report varchar,
  p_codice_ente varchar
)
RETURNS TABLE (
  record_t2sb21s varchar
) AS
$body$
DECLARE

prefisso varchar;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

begin
	
/*
	27/05/2020. 
    Funzione nata per la SIAC-7195.
    La funziona prepara i dati del tracciato t2sb21s.
    Riceve in input i parametri di estrazione dei dati ed il codice report.
    In base al report richiama le procedure corrette.
    Funziona solo per i report BILR024 e BILR146.

*/
	
if p_code_report = 'BILR024' then
    return query 
      with query_tot as (
      	select 'E' tipo_record, attoamm_anno,
            attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
            data_provv_var, data_approvazione_provv,
            COALESCE(tipologia_code,'') codifica_bil, 
            COALESCE(tipologia_desc,'') descr_codifica_bil,
            sum(variazione_aumento_residuo) variazione_aumento_residuo,
            sum(variazione_aumento_stanziato) variazione_aumento_stanziato,
            sum(variazione_aumento_cassa) variazione_aumento_cassa,
            sum(variazione_diminuzione_residuo) variazione_diminuzione_residuo,
            sum(variazione_diminuzione_stanziato) variazione_diminuzione_stanziato,
            sum(variazione_diminuzione_cassa) variazione_diminuzione_cassa                          
        from "BILR024_Allegato_7_Allegato_delibera_variazione_su_entrate_txt" (
          p_ente_prop_id, p_anno ,
          p_numero_delibera, p_anno_delibera, p_tipo_delibera,
          p_anno_competenza, p_ele_variazioni)            
    	group by tipo_record, attoamm_anno,
            attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
            data_provv_var, data_approvazione_provv,
            codifica_bil, descr_codifica_bil
     UNION select 'S' tipo_record, attoamm_anno,
                attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
                data_provv_var, data_approvazione_provv,
                COALESCE(programma_code,'')||COALESCE(titusc_code,'') codifica_bil,
                COALESCE(titusc_desc,'') descr_codifica_bil,
                sum(variazione_aumento_residuo) variazione_aumento_residuo,
                sum(variazione_aumento_stanziato) variazione_aumento_stanziato,
                sum(variazione_aumento_cassa) variazione_aumento_cassa,
                sum(variazione_diminuzione_residuo) variazione_diminuzione_residuo,
                sum(variazione_diminuzione_stanziato) variazione_diminuzione_stanziato,
                sum(variazione_diminuzione_cassa) variazione_diminuzione_cassa                          
            from "BILR024_Allegato_7_Allegato_delibera_variazione_su_spese_txt" (
              p_ente_prop_id, p_anno ,
              p_numero_delibera, p_anno_delibera, p_tipo_delibera,
              p_anno_competenza, p_ele_variazioni)            
        	group by tipo_record, attoamm_anno,
                attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
                data_provv_var, data_approvazione_provv,
                codifica_bil, descr_codifica_bil
      order by tipo_record, attoamm_id, codifica_bil)
       select (         	
              --CIST
          '00001'  || 
              --CENT codice ente 
          p_codice_ente  || 
              --CESE codice esercizio
          p_anno_competenza  || 
              -- NDEL Numero Delibera
          LPAD(query_tot.attoamm_numero::varchar,7,'0') ||          
              --SORG Organo deliberante
          case when p_organo_provv is null or p_organo_provv = '' then 
              ' ' else p_organo_provv  end || 
              -- CTIPREC tipo record
          '1'   ||
           	  -- SEOU INDICATORE ENTRATA/USCITA (1= Entrata - 2 = Uscita)
          case when query_tot.tipo_record = 'E' then '1'
          		else '2' end ||
			  -- NCAP Codifica di Bilancio
          LPAD(query_tot.codifica_bil, 7, '0') ||
          	  -- NART Numero Articolo
          '000' ||
          		--NRES Anno Residuo ??
          p_anno_competenza ||
          		--IPIUCPT Importo Variazione PIU' Competenza
          trim(replace(to_char(query_tot.variazione_aumento_stanziato ,
          		'000000000000000.00'),'.','')) ||         
          		--IMENCPT Importo Variazione MENO Competenza
          trim(replace(to_char(query_tot.variazione_diminuzione_stanziato ,
          		'000000000000000.00'),'.','')) ||
           		--IPIUCAS Importo Variazione PIU' Cassa
          trim(replace(to_char(query_tot.variazione_aumento_cassa ,
          		'000000000000000.00'),'.','')) ||
          		--IMENCAS Importo Variazione MENO Cassa
          trim(replace(to_char(query_tot.variazione_diminuzione_cassa ,
          		'000000000000000.00'),'.','')) ||
         		--ZDES Descrizione Codifica di Bilancio
          RPAD(left(query_tot.descr_codifica_bil,90),90,' ') ||
                --ZDESBL Descrizione Codifica di Bilancio (Bilingue)
          RPAD(' ',90,' ') || 
          		--CMEC Codice Meccanografico
          RPAD('0', 7, '0') ||
                -- SRILIVA Segnale Rilevanza IVA (0 = NO - 1 = SI) NON OBBL.
          ' ' ||
          		--ISTACPT  Importo Stanziamento di Competenza
          LPAD('0', 17,'0') ||
          		--ISTACAS  Importo Stanziamento di Cassa
          LPAD('0', 17,'0') ||
          		--NCNTRIF   Numero Conto di Riferimento
          LPAD('0', 7,'0') ||
          		-- STIPCNT  Tipo Conto di Riferimento (0 = ordinario - 1 = vincolato)
          ' ' ||
          		--ISCOCAP   Importo limite Sconfino
          LPAD('0', 17,'0') ||
          		--IIMP   Importo Impegnato
          LPAD('0', 17,'0') ||
          		--IFNDVIN   Importo Fondo Vincolato
          LPAD('0', 17,'0') ||
           		--FILLER 
          RPAD(' ', 11, ' ')
          )::varchar           
       from query_tot;
else --BILR149                
return query 
      with query_tot as (
      	select 'E' tipo_record, attoamm_anno,
            attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
            data_provv_var, data_approvazione_provv,
            COALESCE(tipologia_code,'') codifica_bil, 
            COALESCE(tipologia_desc,'') descr_codifica_bil,
            sum(variazione_aumento_stanziato) variazione_aumento_stanziato,
            0 variazione_aumento_fpv,
            sum(variazione_diminuzione_stanziato) variazione_diminuzione_stanziato,
            0 variazione_diminuzione_fpv                             
        from "BILR149_Allegato_8_variazioni_eserc_gestprov_entrate_bozza_txt" (
          p_ente_prop_id, p_anno ,
          p_numero_delibera, p_anno_delibera, p_tipo_delibera,
          p_anno_competenza, p_ele_variazioni)            
    	group by tipo_record, attoamm_anno,
            attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
            data_provv_var, data_approvazione_provv,
            codifica_bil, descr_codifica_bil
     UNION select 'S' tipo_record, attoamm_anno,
                attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
                data_provv_var, data_approvazione_provv,
                COALESCE(programma_code,'')||COALESCE(titusc_code,'') codifica_bil,
                COALESCE(titusc_desc,'') descr_codifica_bil,
                	--l'importo presentato delle variazioni deve comprendere
                    --lo stanziato NON FPV piu' quello FPV.
                sum(variazione_aumento_stanziato+variazione_aumento_fpv) variazione_aumento_stanziato,
                sum(variazione_aumento_fpv) variazione_aumento_fpv,
                sum(variazione_diminuzione_stanziato+variazione_diminuzione_fpv) variazione_diminuzione_stanziato,
                sum(variazione_diminuzione_fpv) variazione_diminuzione_fpv                          
            from "BILR149_Allegato_8_variazioni_eserc_gestprov_spese_bozza_txt" (
              p_ente_prop_id, p_anno ,
              p_numero_delibera, p_anno_delibera, p_tipo_delibera,
              p_anno_competenza, p_ele_variazioni)            
        	group by tipo_record, attoamm_anno,
                attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
                data_provv_var, data_approvazione_provv,
                codifica_bil, descr_codifica_bil
      order by tipo_record, attoamm_id, codifica_bil)
       select (         	
              --CIST
          '00001'  || 
              --CENT codice ente 
          p_codice_ente  || 
              --CESE codice esercizio
          p_anno_competenza  || 
              -- NDEL Numero Delibera
          LPAD(query_tot.attoamm_numero::varchar,7,'0') ||          
              --SORG Organo deliberante
          case when p_organo_provv is null or p_organo_provv = '' then 
              ' ' else p_organo_provv  end || 
              -- CTIPREC tipo record
          '1'   ||
           	  -- SEOU INDICATORE ENTRATA/USCITA (1= Entrata - 2 = Uscita)
          case when query_tot.tipo_record = 'E' then '1'
          		else '2' end ||
			  -- NCAP Codifica di Bilancio
          LPAD(query_tot.codifica_bil, 7, '0') ||
          	  -- NART Numero Articolo
          '000' ||
          		--NRES Anno Residuo ??
          p_anno_competenza ||
          		--IPIUCPT Importo Variazione PIU' Competenza
          trim(replace(to_char(query_tot.variazione_aumento_stanziato ,
          		'000000000000000.00'),'.','')) ||         
          		--IMENCPT Importo Variazione MENO Competenza
          trim(replace(to_char(query_tot.variazione_diminuzione_stanziato ,
          		'000000000000000.00'),'.','')) ||
           		--IPIUCAS Importo Variazione PIU' Cassa
          LPAD('0',17,'0') ||
          		--IMENCAS Importo Variazione MENO Cassa
          LPAD('0',17,'0') ||
         		--ZDES Descrizione Codifica di Bilancio
          RPAD(left(query_tot.descr_codifica_bil,90),90,' ') ||
                --ZDESBL Descrizione Codifica di Bilancio (Bilingue)
          RPAD(' ',90,' ') || 
          		--CMEC Codice Meccanografico
          RPAD('0', 7, '0') ||
                -- SRILIVA Segnale Rilevanza IVA (0 = NO - 1 = SI) NON OBBL.
          ' ' ||
          		--ISTACPT  Importo Stanziamento di Competenza
          LPAD('0', 17,'0') ||
          		--ISTACAS  Importo Stanziamento di Cassa
          LPAD('0', 17,'0') ||
          		--NCNTRIF   Numero Conto di Riferimento
          LPAD('0', 7,'0') ||
          		-- STIPCNT  Tipo Conto di Riferimento (0 = ordinario - 1 = vincolato)
          ' ' ||
          		--ISCOCAP   Importo limite Sconfino
          LPAD('0', 17,'0') ||
          		--IIMP   Importo Impegnato
          LPAD('0', 17,'0') ||
          		--IFNDVIN   Importo Fondo Vincolato
          LPAD('0', 17,'0') ||
           		--FILLER 
          RPAD(' ', 11, ' ')
          )::varchar           
       from query_tot;                   
                
end if;
	

exception
    when syntax_error THEN
    	record_t2Sb21s='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	record_t2Sb21s='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
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
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac.fnc_tracciato_t2sb20s (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar,
  p_organo_provv varchar,
  p_code_report varchar,
  p_codice_ente varchar
)
RETURNS TABLE (
  record_t2sb20s varchar
) AS
$body$
DECLARE

prefisso varchar;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
elencoRec record;
importo_tot_stanz_entrate numeric;
importo_tot_cassa_entrate numeric;
importo_tot_residui_entrate numeric;
importo_tot_stanz_spese numeric;
importo_tot_cassa_spese numeric;
importo_tot_residui_spese numeric;

begin
	
/*
	27/05/2020. 
    Funzione nata per la SIAC-7195.
    La funziona prepara i dati del tracciato t2sb20s.
    Riceve in input i parametri di estrazione dei dati ed il codice report.
    In base al report richiama le procedure corrette.
    Funziona solo per i report BILR024 e BILR146.

*/

if p_code_report = 'BILR024' then
   -- return query 
   	for elencoRec in
    	select entrate.attoamm_anno attoamm_anno_ent,
            entrate.attoamm_numero attoamm_numero_ent, 
            entrate.tipo_atto tipo_atto_ent, 
            entrate.attoamm_oggetto attoamm_oggetto_ent, 
            entrate.attoamm_id attoamm_id_ent, 
            entrate.data_provv_var data_provv_var_ent, 
            entrate.data_approvazione_provv data_approvazione_provv_ent,
            entrate.variazione_aumento_residuo variazione_aumento_residuo_ent,
            entrate.variazione_aumento_stanziato variazione_aumento_stanziato_ent,
            entrate.variazione_aumento_cassa variazione_aumento_cassa_ent,
            entrate.variazione_diminuzione_residuo variazione_diminuzione_residuo_ent,
            entrate.variazione_diminuzione_stanziato variazione_diminuzione_stanziato_ent,
            entrate.variazione_diminuzione_cassa variazione_diminuzione_cassa_ent,
            spese.attoamm_anno attoamm_anno_spese,
            spese.attoamm_numero attoamm_numero_spese, 
            spese.tipo_atto tipo_atto_spese, 
            spese.attoamm_oggetto attoamm_oggetto_spese, 
            spese.attoamm_id attoamm_id_spese, 
            spese.data_provv_var data_provv_var_spese, 
            spese.data_approvazione_provv data_approvazione_provv_spese,
            spese.variazione_aumento_residuo variazione_aumento_residuo_spese,
            spese.variazione_aumento_stanziato variazione_aumento_stanziato_spese,
            spese.variazione_aumento_cassa variazione_aumento_cassa_spese,
            spese.variazione_diminuzione_residuo variazione_diminuzione_residuo_spese,
            spese.variazione_diminuzione_stanziato variazione_diminuzione_stanziato_spese,
            spese.variazione_diminuzione_cassa variazione_diminuzione_cassa_spese        	                                      
        from (select attoamm_anno,
            attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
            data_provv_var, data_approvazione_provv,
            sum(variazione_aumento_residuo) variazione_aumento_residuo,
            sum(variazione_aumento_stanziato) variazione_aumento_stanziato,
            sum(variazione_aumento_cassa) variazione_aumento_cassa,
            sum(variazione_diminuzione_residuo) variazione_diminuzione_residuo,
            sum(variazione_diminuzione_stanziato) variazione_diminuzione_stanziato,
            sum(variazione_diminuzione_cassa) variazione_diminuzione_cassa                          
        from "BILR024_Allegato_7_Allegato_delibera_variazione_su_entrate_txt" (
          p_ente_prop_id, p_anno ,
          p_numero_delibera, p_anno_delibera, p_tipo_delibera,
          p_anno_competenza, p_ele_variazioni)            
    	group by attoamm_anno,
            attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
            data_provv_var, data_approvazione_provv) entrate
    FULL JOIN 
               (select attoamm_anno,
                attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
                data_provv_var, data_approvazione_provv,
                sum(variazione_aumento_residuo) variazione_aumento_residuo,
                sum(variazione_aumento_stanziato) variazione_aumento_stanziato,
                sum(variazione_aumento_cassa) variazione_aumento_cassa,
                sum(variazione_diminuzione_residuo) variazione_diminuzione_residuo,
                sum(variazione_diminuzione_stanziato) variazione_diminuzione_stanziato,
                sum(variazione_diminuzione_cassa) variazione_diminuzione_cassa                          
            from "BILR024_Allegato_7_Allegato_delibera_variazione_su_spese_txt" (
              p_ente_prop_id, p_anno ,
              p_numero_delibera, p_anno_delibera, p_tipo_delibera,
              p_anno_competenza, p_ele_variazioni)            
        	group by attoamm_anno,
                attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
                data_provv_var, data_approvazione_provv) spese
    ON entrate.attoamm_id=spese.attoamm_id
   	loop
    		--per ogni atto cerco gli importi complessivi
    	if elencoRec.attoamm_id_ent is not null then
        	select COALESCE(stanziato_totale,0), COALESCE(cassa_totale,0), 
            		COALESCE(residuo_totale,0)
            	into importo_tot_stanz_entrate, importo_tot_cassa_entrate,
                	importo_tot_residui_entrate
            from "BILR024_Allegato_7_Allegato_delibera_variaz_totali_entrate_txt"(
            	p_ente_prop_id, p_anno, elencoRec.attoamm_numero_ent, 
                elencoRec.attoamm_anno_ent, elencoRec.tipo_atto_ent,
                p_anno_competenza, NULL);
        else 
        	importo_tot_stanz_entrate:=0;
            importo_tot_cassa_entrate:=0;
            importo_tot_cassa_entrate:=0;
        end if;
raise notice 'Atto numero %/%/%, stanz_entrate = %, cassa_entrate = %, residui_entrate= %',
	       elencoRec.attoamm_numero_ent,elencoRec.attoamm_anno_ent, elencoRec.tipo_atto_ent,
           importo_tot_stanz_entrate, importo_tot_cassa_entrate, importo_tot_cassa_entrate;
    	
        if elencoRec.attoamm_id_spese is not null then
        	select COALESCE(stanziato_totale,0), COALESCE(cassa_totale,0), 
            		COALESCE(residuo_totale,0)
            	into importo_tot_stanz_spese, importo_tot_cassa_spese,
                	importo_tot_residui_spese
            from "BILR024_Allegato_7_Allegato_delibera_variaz_totali_spese_txt"(
            	p_ente_prop_id, p_anno, elencoRec.attoamm_numero_spese, 
                elencoRec.attoamm_anno_spese, elencoRec.tipo_atto_spese, 
                p_anno_competenza, NULL);
        else 
        	importo_tot_stanz_spese:=0;
            importo_tot_cassa_spese:=0;
            importo_tot_residui_spese:=0;
        end if;        
        
raise notice 'Atto numero %/%/%, stanz_spese = %, cassa_spese = %, residui_spese= %',
	       elencoRec.attoamm_numero_spese,elencoRec.attoamm_anno_spese,elencoRec.tipo_atto_spese,
           importo_tot_stanz_spese, importo_tot_cassa_spese, importo_tot_residui_spese;
        
			--preparo il record da restituire.
    	record_t2sb20s:=(
                        --CIST
                '00001'  || 
                    --CENT codice ente 
                p_codice_ente  || 
                    --CESE codice esercizio
                p_anno_competenza  || 
                    -- NDEL Numero Delibera
                case when elencoRec.attoamm_id_ent is NULL then
                    LPAD(elencoRec.attoamm_numero_spese::varchar,7,'0')
                else LPAD(elencoRec.attoamm_numero_ent::varchar,7,'0') end || 
                    --SORG Organo deliberante
                case when p_organo_provv is null or p_organo_provv = '' then 
                    ' ' else p_organo_provv  end || 
                    -- CTIPREC tipo record
                '0'  || 
                    -- DDEL Data delibera
               case when elencoRec.attoamm_id_ent is NULL then
                    to_char(elencoRec.data_provv_var_spese,'ddMMyyyy') 
                else to_char(elencoRec.data_provv_var_ent,'ddMMyyyy') end ||
                    -- ZDES descr delibera
               case when elencoRec.attoamm_id_ent is NULL then
                    RPAD(left(elencoRec.attoamm_oggetto_spese,50),50,' ')
                else RPAD(left(elencoRec.attoamm_oggetto_ent,50),50,' ') end || 
                    -- SORGAPP  Organo approvazione
                case when p_organo_provv is null or p_organo_provv = '' then 
                    ' ' else p_organo_provv  end || 
                    -- DDEL Data Approvazione Delibera.
               case when elencoRec.attoamm_id_ent is NULL then
                    to_char(elencoRec.data_approvazione_provv_spese,'ddMMyyyy')
                else to_char(elencoRec.data_approvazione_provv_ent,'ddMMyyyy') end || 
                    --DDATAPP  Numero Approvazione Delibera
                LPAD('0', 7, '0') || 
                    --IENTRES Importo entrate residuo
               case when elencoRec.attoamm_id_ent is NULL then
                    LPAD('0',17,'0') 
                  else trim(replace(to_char(ABS(importo_tot_residui_entrate) ,
          				'000000000000000.00'),'.','')) end ||                  	
                    --SENTRES Segno entrate residuo  
               case when elencoRec.attoamm_id_ent is NULL then ' '                     
                else case when importo_tot_residui_entrate >=0 then '+'
                    else '-' end end || 
                    --IUSCRES Importo spese residuo
                case when elencoRec.attoamm_id_spese IS NULL then
                    LPAD('0',17,'0') 
                else trim(replace(to_char(ABS(importo_tot_residui_spese),
          				'000000000000000.00'),'.','')) end ||
                    --SUSCRES Segno spese residuo 
                case when elencoRec.attoamm_id_spese IS NULL then ' '                         
                else case when importo_tot_residui_spese >=0 then '+'
                    else '-' end end ||                                
                    --IENTCPT Importo entrate competenza
               case when elencoRec.attoamm_id_ent is NULL then
                    LPAD('0',17,'0')
			   else trim(replace(to_char(ABS(importo_tot_stanz_entrate),
          				'000000000000000.00'),'.','')) end ||                        
                    --SENTCPT Segno entrate competenza
               case when elencoRec.attoamm_id_ent is NULL then ' '
                else case when importo_tot_stanz_entrate >=0 then '+'
                    else '-' end end ||
                    --IUSCCPT Importo spese competenza
                case when elencoRec.attoamm_id_spese IS NULL then
                    LPAD('0',17,'0')
                else trim(replace(to_char(ABS(importo_tot_stanz_spese),
          				'000000000000000.00'),'.','')) end ||
                    --SUSCCPT Segno spese competenza 
                case when elencoRec.attoamm_id_spese IS NULL then ' ' 
                else case when importo_tot_stanz_spese >=0 then '+'
                    else '-' end end ||   
                    --IENTCAS Importo entrate cassa 
               case when elencoRec.attoamm_id_ent is NULL then
                    LPAD('0',17,'0')                               
                else trim(replace(to_char(ABS(importo_tot_cassa_entrate),
          				'000000000000000.00'),'.','')) end ||
                    --SENTCAS Segno entrate cassa
               case when elencoRec.attoamm_id_ent is NULL then ' ' 
                else case when importo_tot_cassa_entrate >=0 then '+'
                    else '-' end end ||
                    --IUSCCAS Importo spese cassa   
                case when elencoRec.attoamm_id_spese IS NULL then
                    LPAD('0',17,'0')
                else trim(replace(to_char(ABS(importo_tot_cassa_spese),
          				'000000000000000.00'),'.','')) end ||
                    --SUSCCAS Segno spese cassa 
                case when elencoRec.attoamm_id_spese IS NULL then ' '
                 else case when importo_tot_cassa_spese >=0 then '+'
                    else '-' end end ||
                    --KEYWEB Identificativo flusso web. NON OBBLIGATORIO.    
                RPAD(' ', 30, ' ')  ||
                    --CTIPFLU Identificativo tipo flusso.
                'D' ||
                    --SSBIL Segnale stato bilancio. NON OBBLIGATORIO. 
                ' ' || 
                    --STIPINV Indicatore tipo invio. NON OBBLIGATORIO.
                ' ' || 
                    --FILLER 
                RPAD(' ', 160, ' '))::varchar ; 
    
    return next;
    
  end loop;
elsif  p_code_report = 'BILR149' then --Report BILR149
	for elencoRec in
    	select entrate.attoamm_anno attoamm_anno_ent,
            entrate.attoamm_numero attoamm_numero_ent, 
            entrate.tipo_atto tipo_atto_ent, 
            entrate.attoamm_oggetto attoamm_oggetto_ent, 
            entrate.attoamm_id attoamm_id_ent, 
            entrate.data_provv_var data_provv_var_ent, 
            entrate.data_approvazione_provv data_approvazione_provv_ent,            
            entrate.variazione_aumento_stanziato variazione_aumento_stanziato_ent,
            entrate.variazione_diminuzione_stanziato variazione_diminuzione_stanziato_ent,
            spese.attoamm_anno attoamm_anno_spese,
            spese.attoamm_numero attoamm_numero_spese, 
            spese.tipo_atto tipo_atto_spese, 
            spese.attoamm_oggetto attoamm_oggetto_spese, 
            spese.attoamm_id attoamm_id_spese, 
            spese.data_provv_var data_provv_var_spese, 
            spese.data_approvazione_provv data_approvazione_provv_spese,
            spese.variazione_aumento_stanziato variazione_aumento_stanziato_spese,
            spese.variazione_aumento_fpv variazione_aumento_fpv_spese,
            spese.variazione_diminuzione_stanziato variazione_diminuzione_stanziato_spese,
            spese.variazione_diminuzione_fpv variazione_diminuzione_fpv_spese        	                                      
        from (select attoamm_anno,
            attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
            data_provv_var, data_approvazione_provv,
            sum(variazione_aumento_stanziato) variazione_aumento_stanziato,            
            sum(variazione_diminuzione_stanziato) variazione_diminuzione_stanziato             
        from "BILR149_Allegato_8_variazioni_eserc_gestprov_entrate_bozza_txt" (
          p_ente_prop_id, p_anno ,
          p_numero_delibera, p_anno_delibera, p_tipo_delibera,
          p_anno_competenza, p_ele_variazioni)            
    	group by attoamm_anno,
            attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
            data_provv_var, data_approvazione_provv) entrate
    FULL JOIN 
               (select attoamm_anno,
                attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
                data_provv_var, data_approvazione_provv,                
                sum(variazione_aumento_stanziato) variazione_aumento_stanziato,
                sum(variazione_aumento_fpv) variazione_aumento_fpv,
                sum(variazione_diminuzione_stanziato) variazione_diminuzione_stanziato,
                sum(variazione_diminuzione_fpv) variazione_diminuzione_fpv                          
            from "BILR149_Allegato_8_variazioni_eserc_gestprov_spese_bozza_txt" (
              p_ente_prop_id, p_anno ,
              p_numero_delibera, p_anno_delibera, p_tipo_delibera,
              p_anno_competenza, p_ele_variazioni)            
        	group by attoamm_anno,
                attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
                data_provv_var, data_approvazione_provv) spese
    ON entrate.attoamm_id=spese.attoamm_id
   	loop
    		--per ogni atto cerco gli importi complessivi
    	if elencoRec.attoamm_id_ent is not null then
        	select COALESCE(stanziato_totale,0)
            	into importo_tot_stanz_entrate, importo_tot_cassa_entrate,
                	importo_tot_residui_entrate
            from "BILR149_Allegato_8_variazioni_eserc_gestprov_entrate_totali_txt"(
            	p_ente_prop_id, p_anno, elencoRec.attoamm_numero_ent, 
                elencoRec.attoamm_anno_ent, elencoRec.tipo_atto_ent,
                p_anno_competenza, NULL);
        else 
        	importo_tot_stanz_entrate:=0;
            importo_tot_cassa_entrate:=0;
            importo_tot_cassa_entrate:=0;
        end if;
raise notice 'Atto numero %/%/%, stanz_entrate = %, cassa_entrate = %, residui_entrate= %',
	       elencoRec.attoamm_numero_ent,elencoRec.attoamm_anno_ent, elencoRec.tipo_atto_ent,
           importo_tot_stanz_entrate, importo_tot_cassa_entrate, importo_tot_cassa_entrate;
    	
        if elencoRec.attoamm_id_spese is not null then
        	select COALESCE(stanziato_totale,0)
            	into importo_tot_stanz_spese, importo_tot_cassa_spese,
                	importo_tot_residui_spese
            from "BILR149_Allegato_8_variazioni_eserc_gestprov_spese_totali_txt"(
            	p_ente_prop_id, p_anno, elencoRec.attoamm_numero_spese, 
                elencoRec.attoamm_anno_spese, elencoRec.tipo_atto_spese, 
                p_anno_competenza, NULL);
        else 
        	importo_tot_stanz_spese:=0;
            importo_tot_cassa_spese:=0;
            importo_tot_residui_spese:=0;
        end if;        
        
raise notice 'Atto numero %/%/%, stanz_spese = %, cassa_spese = %, residui_spese= %',
	       elencoRec.attoamm_numero_spese,elencoRec.attoamm_anno_spese,elencoRec.tipo_atto_spese,
           importo_tot_stanz_spese, importo_tot_cassa_spese, importo_tot_residui_spese;
        
			--preparo il record da restituire.
    	record_t2sb20s:=(
                         --CIST
                '00001'  || 
                    --CENT codice ente 
                p_codice_ente  || 
                    --CESE codice esercizio
                p_anno_competenza  || 
                    -- NDEL Numero Delibera
                case when elencoRec.attoamm_id_ent IS NULL then
                    LPAD(elencoRec.attoamm_numero_spese::varchar,7,'0')
                else LPAD(elencoRec.attoamm_numero_ent::varchar,7,'0') end || 
                    --SORG Organo deliberante
                case when p_organo_provv is null or p_organo_provv = '' then 
                    ' ' else p_organo_provv  end || 
                    -- CTIPREC tipo record
                '0'  || 
                    -- DDEL Data delibera
               case when elencoRec.attoamm_id_ent IS NULL then
                    to_char(elencoRec.data_provv_var_spese,'ddMMyyyy') 
                else to_char(elencoRec.data_provv_var_ent,'ddMMyyyy') end ||
                    -- ZDES descr delibera
               case when elencoRec.attoamm_id_ent IS NULL then
                    RPAD(left(elencoRec.attoamm_oggetto_spese,50),50,' ')
                else RPAD(left(elencoRec.attoamm_oggetto_ent,50),50,' ') end || 
                    -- SORGAPP  Organo approvazione
                case when p_organo_provv is null or p_organo_provv = '' then 
                    ' ' else p_organo_provv  end || 
                    -- DDEL Data Approvazione Delibera.
               case when elencoRec.attoamm_id_ent IS NULL then
                    to_char(elencoRec.data_approvazione_provv_spese,'ddMMyyyy')
                else to_char(elencoRec.data_approvazione_provv_ent,'ddMMyyyy') end || 
                    --DDATAPP  Numero Approvazione Delibera
                LPAD('0', 7, '0') || 
                    --IENTRES Importo entrate residuo               
                LPAD('0',17,'0') ||
                    --SENTRES Segno entrate residuo  
                ' ' || 
                    --IUSCRES Importo spese residuo
                LPAD('0',17,'0') ||
                    --SUSCRES Segno spese residuo 
                ' ' ||                            
                    --IENTCPT Importo entrate competenza
                    
 			   case when elencoRec.attoamm_id_ent is NULL then
                    LPAD('0',17,'0')
			   else trim(replace(to_char(ABS(importo_tot_stanz_entrate),
          				'000000000000000.00'),'.','')) end ||                                                   	
                    --SENTCPT Segno entrate competenza
               case when elencoRec.attoamm_id_ent IS NULL then
                    ' '
                else case when importo_tot_stanz_entrate >=0 then '+'
                    else '-' end end ||
                    --IUSCCPT Importo spese competenza
                case when elencoRec.attoamm_id_spese IS NULL then
                    LPAD('0',17,'0')
                else trim(replace(to_char(ABS(importo_tot_stanz_spese),
          				'000000000000000.00'),'.','')) end ||
                    --SUSCCPT Segno spese competenza 
                case when elencoRec.attoamm_id_spese IS NULL then
                    ' '
                else case when importo_tot_stanz_spese >=0 then '+'
                    else '-' end end ||   
                    --IENTCAS Importo entrate cassa 
                LPAD('0',17,'0') ||
                    --SENTCAS Segno entrate cassa
                ' ' ||  
                    --IUSCCAS Importo spese cassa   
                LPAD('0',17,'0') ||
                    --SUSCCAS Segno spese cassa 
                ' ' ||   
                    --KEYWEB Identificativo flusso web. NON OBBLIGATORIO.    
                RPAD(' ', 30, ' ')  ||
                    --CTIPFLU Identificativo tipo flusso.
                'D' ||
                    --SSBIL Segnale stato bilancio. NON OBBLIGATORIO. 
                ' ' || 
                    --STIPINV Indicatore tipo invio. NON OBBLIGATORIO.
                ' ' || 
                    --FILLER 
                RPAD(' ', 160, ' '))::varchar       ; 
    
    return next;
    
  end loop;
else
	record_t2sb20s:= 'Il REPORT '||p_code_report|| ' NON E'' GESTITO IN QUESTO FORMATO';
    return next;
    return;
        	
end if;


	

exception
    when syntax_error THEN
    	record_t2sb20s='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	record_t2sb20s='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
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
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac.fnc_bilr_tracciato_400_cad (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar,
  p_organo_provv varchar,
  p_code_report varchar
)
RETURNS TABLE (
  riga_tracciato text
) AS
$body$
DECLARE

codice_ente varchar;
code_organo_provv varchar;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;

begin
	
/*
	27/05/2020. 
    Funzione nata per la SIAC-7195.
    La funziona e' quella principale chiamata dall'applicazione.
    Riceve in input i parametri di estrazione dei dati ed il codice report.
    Effettua il controlla della correttezza dei parametri e, in base al 
    codice report, richiama le procedure corrette per generare i tracciati
    corretti.
    Funziona solo per i report BILR024, BILR139 e BILR146.

*/

	/*
	-- DEBUG NON TOGLIERE QUESTE RIGHE.
    -- Servono per evenutali verifiche dei parametri ricevuti.
		return QUERY 
  SELECT 	'1 ente: ' || coalesce (p_ente_prop_id::text, 'null val')
 UNION SELECT    '2 anno: ' || coalesce (p_anno::text, 'null val')
  UNION SELECT   '3 num delib: ' ||  coalesce (p_numero_delibera::text, 'null val')
  UNION SELECT  '4 anno delib: ' ||  coalesce (p_anno_delibera::text, 'null val')
  UNION SELECT '5 tipo delib: ' ||  coalesce (p_tipo_delibera::text, 'null val')
  UNION SELECT 	'6 anno comp: ' || coalesce (p_anno_competenza::text, 'null val')
  UNION SELECT 	'7 ele variaz: ' || coalesce (p_ele_variazioni::text, 'null val')
  UNION SELECT '8 organo provv: ' || coalesce (p_organo_provv::text, 'null val')
  UNION SELECT '9 code report: ' || coalesce (p_code_report::text, 'null val') 
 order by 1;
*/
	
  --Controllo dei parametri
contaParametriParz:=0;
contaParametri:=0;
    
-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

if p_numero_delibera IS NOT NULL THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_anno_delibera IS NOT NULL AND p_anno_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_tipo_delibera IS NOT NULL AND p_tipo_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;    

if  contaParametriParz = 1 
    OR contaParametriParz = 2 
    OR (contaParametriParz = 3 and (p_organo_provv IS NULL OR
				p_organo_provv = ''))     then
	riga_tracciato:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
    return next;
    return; 
elsif contaParametriParz = 3 THEN -- parametro corretto
	contaParametri := contaParametri + 1;
end if;

contaParametriParz:=0;

if (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	contaParametri := contaParametri + 1;
end if;


if contaParametri = 0 THEN
	riga_tracciato:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN    
	riga_tracciato:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;
    
if p_organo_provv = '' Or p_organo_provv IS NULL then
	riga_tracciato:= 'ERRORE NEI PARAMETRI: Specificare l''organo che ha emesso il Provvedimento';
    return next;
    return;	
end if;

-- imposto il codice ente. 
codice_ente:='';
select ente_oil_codice
	into codice_ente
from siac_t_ente_oil a
where a.ente_proprietario_id= p_ente_prop_id
	and a.data_cancellazione IS NULL;

if codice_ente is null or codice_ente = '' then
	riga_tracciato:= 'ERRORE: non e'' stato configurato il codice dell''ente';
    return next;
    return;		
else 
	codice_ente:=LPAD(codice_ente, 7, '0');    
end if;    

	--imposto il codice relativo all'organo che ha emesso il provvedimento.
if upper(p_organo_provv) like '%GIUNTA%' then
	code_organo_provv:='G';
elsif  upper(p_organo_provv) like '%CONSIGLIO%' then
	code_organo_provv:='C';
else 
	code_organo_provv:='A'; --Assemblea.
end if;

raise notice 'code_organo_provv = %', code_organo_provv;

if p_code_report = 'BILR024' OR p_code_report = 'BILR149' then
    RETURN QUERY
        select record_t2sb20s::text rec
        from "fnc_tracciato_t2sb20s"(p_ente_prop_id, p_anno ,
                    p_numero_delibera ,  p_anno_delibera ,
                    p_tipo_delibera ,  p_anno_competenza ,
                    p_ele_variazioni, code_organo_provv,p_code_report,
                    codice_ente)
    UNION
        select record_t2sb21s::text rec
        from "fnc_tracciato_t2sb21s"(p_ente_prop_id, p_anno ,
                    p_numero_delibera ,  p_anno_delibera ,
                    p_tipo_delibera ,  p_anno_competenza ,
                    p_ele_variazioni, code_organo_provv,p_code_report,
                    codice_ente)
         order by rec;
else if p_code_report = 'BILR139' then
     RETURN QUERY
        select record_t2sb22s::text rec
        from "fnc_tracciato_t2sb22s"(p_ente_prop_id, p_anno ,
                    p_numero_delibera ,  p_anno_delibera ,
                    p_tipo_delibera ,  p_anno_competenza ,
                    p_ele_variazioni, code_organo_provv,p_code_report,
                    codice_ente);
     end if;                
end if;
                            

exception
	when syntax_error THEN
    	riga_tracciato='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	riga_tracciato='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;     
     when others  THEN
         RAISE EXCEPTION 'Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR149_Allegato_8_variazioni_eserc_gestprov_spese_totali_txt" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  stanziato_totale numeric
) AS
$body$
DECLARE

DataSetAtti record;
contaRec integer;

annoCapImp varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_titolotipologiacategoria varchar:='00003';
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;
bilancio_id integer;
stanz_tot numeric;
cassa_tot numeric;
residui_tot numeric;
importi_var_capitoli numeric;

BEGIN

--annoCapImp:= p_anno; 
annoCapImp:=p_anno_competenza;

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione


stanziato_totale=0;

    
/* Funzione nata per la SIAC-7195 per la gestione dei file in formato testo 
	per Unicredit.
    La funzione estrae i totali complessivi che comprendono i dati delle variazioni
    considerate da i parametri in input. 
*/

select fnc_siac_random_user()
into	user_table;

select a.bil_id 
	into bilancio_id 
from siac_t_bil a,
		siac_t_periodo b
where b.periodo_id=a.periodo_id
	and a.ente_proprietario_id=p_ente_prop_id 
	and b.anno=p_anno
    and a.data_cancellazione IS NULL
    and b.data_cancellazione IS NULL;
    
raise notice '1 - %' , clock_timestamp()::text;

	--dati variabili dei capitoli.
    --il report BILR149 per questo calcolo richima la procedure del BILR119.
select sum(stanziato)+sum(variazione_aumento)-sum(variazione_diminuzione)
	into importi_var_capitoli
from "BILR119_Allegato_7_Allegato_delibera_variazione_variabili_bozza" 
	(p_ente_prop_id,p_anno,p_numero_delibera,p_anno_delibera,p_tipo_delibera,
    p_anno_competenza,p_ele_variazioni) 
where tipologia_capitolo in('DAM')
	and anno_riferimento=p_anno_competenza;

raise notice 'importi_var_capitoli = %', importi_var_capitoli;

INSERT INTO siac_rep_cap_ug_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_imp_tipo.elem_det_tipo_code    TIPO_IMP,
            capitolo_importi.ente_proprietario_id,  
            user_table utente,            
            sum(capitolo_importi.elem_det_importo) importo_cap
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,            
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_t_bil_elem 			capitolo				            
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
        and	stato_capitolo.elem_stato_code		in ('VA', 'PR')								
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')	
        -- 13/02/2017: aggiunto filtro su anno competenza e sugli importi					
        --and capitolo_imp_periodo.anno = p_anno_competenza
        and capitolo_imp_periodo.anno =	p_anno							
        and	capitolo_imp_tipo.elem_det_tipo_code = 'STA'
        and	capitolo_importi.data_cancellazione 		is null
        and	capitolo_imp_tipo.data_cancellazione 		is null
       	and	capitolo_imp_periodo.data_cancellazione 	is null
        and	capitolo.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione 			is null
        and	bilancio.data_cancellazione 				is null
	 	and	anno_eserc.data_cancellazione 				is null 
	 	and	stato_capitolo.data_cancellazione 			is null 
    	and	r_capitolo_stato.data_cancellazione 		is null
	 	and cat_del_capitolo.data_cancellazione 		is null
    	and	r_cat_capitolo.data_cancellazione 			is null
    group by	capitolo_importi.elem_id,
    capitolo_imp_tipo.elem_det_tipo_code,
    capitolo_imp_periodo.anno,
    capitolo_importi.ente_proprietario_id, utente;
     

	--stanziato totale
select sum(COALESCE(importo,0))
into stanziato_totale
from siac_rep_cap_ug_imp
where ente_proprietario=p_ente_prop_id
and tipo_imp='STA'
and periodo_anno= p_anno_competenza
and utente = user_table;

	--allo stanziato aggiungo i dati dei capitoli.
stanziato_totale:=stanziato_totale+importi_var_capitoli;


return next;

delete from siac_rep_cap_ug_imp where utente = user_table;

raise notice 'fine OK';

exception
	when no_data_found THEN
		raise notice 'nessun atto trovato' ;
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
COST 100 ROWS 1000;

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
  variazione_diminuzione_fpv numeric
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
 	and		tipologia_stato_var.variazione_stato_tipo_code	in	(''B'',''G'', ''C'', ''P'')
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
                        capitolo.elem_id, capitolo.elem_id_padre
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
                    and cat_del_capitolo.elem_cat_code	in (''STD'',''FPV'',''FSC'',''FPVC'')                    
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
                else 0::numeric end  variazione_diminuzione_fpv              
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
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR149_Allegato_8_variazioni_eserc_gestprov_entrate_totali_txt" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  stanziato_totale numeric
) AS
$body$
DECLARE

DataSetAtti record;
contaRec integer;

annoCapImp varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_titolotipologiacategoria varchar:='00003';
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;
bilancio_id integer;
stanz_tot numeric;
cassa_tot numeric;
residui_tot numeric;
importi_var_capitoli numeric;

BEGIN

--annoCapImp:= p_anno; 
annoCapImp:=p_anno_competenza;

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-EG'; -- tipo capitolo gestione


stanziato_totale=0;


    
/* Funzione nata per la SIAC-7195 per la gestione dei file in formato testo 
	per Unicredit.
    La funzione estrae i totali complessivi che comprendono i dati delle variazioni
    considerate da i parametri in input. 
*/

select fnc_siac_random_user()
into	user_table;

select a.bil_id 
	into bilancio_id 
from siac_t_bil a,
		siac_t_periodo b
where b.periodo_id=a.periodo_id
	and a.ente_proprietario_id=p_ente_prop_id 
	and b.anno=p_anno
    and a.data_cancellazione IS NULL
    and b.data_cancellazione IS NULL;
    
raise notice '1 - %' , clock_timestamp()::text;

	--dati variabili dei capitoli.
    --il report BILR149 per questo calcolo richima la procedure del BILR119.
select sum(stanziato)+sum(variazione_aumento)-sum(variazione_diminuzione)
	into importi_var_capitoli
from "BILR119_Allegato_7_Allegato_delibera_variazione_variabili_bozza" 
	(p_ente_prop_id,p_anno,p_numero_delibera,p_anno_delibera,p_tipo_delibera,
    p_anno_competenza,p_ele_variazioni) 
where tipologia_capitolo in('AAM','FPVSC','FPVCC')
	and anno_riferimento=p_anno_competenza;

raise notice 'importi_var_capitoli = %', importi_var_capitoli;

INSERT INTO siac_rep_cap_eg_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,   
            sum(capitolo_importi.elem_det_importo)    importo_cap 
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code	in	('VA', 'PR')
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD'
        and capitolo_imp_periodo.anno =	p_anno					 
        and	capitolo_imp_tipo.elem_det_tipo_code = 'STA' 		
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
    group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
    capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente;

	--stanziato totale
select sum(importo)
into stanziato_totale
from siac_rep_cap_eg_imp
where ente_proprietario=p_ente_prop_id
and periodo_anno= p_anno_competenza
and tipo_imp= 'STA'
and utente = user_table;

	--allo stanziato aggiungo i dati dei capitoli.
stanziato_totale:=stanziato_totale+importi_var_capitoli;


return next;

delete from siac_rep_cap_eg_imp where utente = user_table;

raise notice 'fine OK';

exception
	when no_data_found THEN
		raise notice 'nessun atto trovato' ;
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
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR149_Allegato_8_variazioni_eserc_gestprov_entrate_bozza_txt" (
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
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  variazione_aumento_stanziato numeric,
  variazione_diminuzione_stanziato numeric
) AS
$body$
DECLARE

DataSetAtti record;
contaRec integer;

annoCapImp varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_titolotipologiacategoria varchar:='00003';
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;
bilancio_id integer;

BEGIN

--annoCapImp:= p_anno; 
annoCapImp:=p_anno_competenza;

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-EG'; -- tipo capitolo gestione


titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;

    
/* Funzione nata per la SIAC-7195 per la gestione dei file in formato testo 
	per Unicredit.
    La funzione estrae i dati delle variazioni di entata del report BILR149 
    e del relativo atto.
    Resituisce solo i dati di stanziamento e le variazioni sono 
    quelle in bozza.
*/


select a.bil_id 
	into bilancio_id 
from siac_t_bil a,
		siac_t_periodo b
where b.periodo_id=a.periodo_id
	and a.ente_proprietario_id=p_ente_prop_id 
	and b.anno=p_anno
    and a.data_cancellazione IS NULL
    and b.data_cancellazione IS NULL;
    
raise notice '1 - %' , clock_timestamp()::text;

	--preparo la query
strQuery:='          
with atti as(select	atto.attoamm_anno, atto.attoamm_numero,
			tipo_atto.attoamm_tipo_code, atto.attoamm_oggetto,
			dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo) importo_var,        
            tipo_elemento.elem_det_tipo_code tipo_importo,            
            '''||p_anno_competenza||''',
            atto.attoamm_id, atto.data_creazione data_provv_var,
            r_atto_stato.data_creazione data_approvazione_provv	      	
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
            siac_t_periodo 				anno_importi
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
 	and		tipologia_stato_var.variazione_stato_tipo_code	in	(''B'',''G'', ''C'', ''P'')
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
    group by 	atto.attoamm_anno, atto.attoamm_numero,tipo_atto.attoamm_tipo_code,
    			atto.attoamm_oggetto, dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
            	atto.attoamm_id, atto.data_creazione, r_atto_stato.data_creazione),
 capitoli as (select cl.classif_id categoria_id,
              '''||p_anno||''' anno_bilancio,
              capitolo.elem_code, capitolo.elem_code2,
              capitolo.elem_desc, capitolo.elem_desc2,
              capitolo.elem_id, capitolo.elem_id_padre
             from 	siac_r_bil_elem_class rc,
                    siac_t_bil_elem capitolo,
                    siac_d_class_tipo ct,
                    siac_t_class cl,
                    siac_d_bil_elem_tipo tipo_elemento, 
                    siac_d_bil_elem_stato stato_capitolo,
                    siac_r_bil_elem_stato r_capitolo_stato,
                    siac_d_bil_elem_categoria cat_del_capitolo,
                    siac_r_bil_elem_categoria r_cat_capitolo
            where ct.classif_tipo_id				=	cl.classif_tipo_id
            and cl.classif_id					=	rc.classif_id 
            and capitolo.elem_tipo_id			=	tipo_elemento.elem_tipo_id 
            and capitolo.elem_id				=	rc.elem_id 
            and	capitolo.elem_id				=	r_capitolo_stato.elem_id
            and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id				=	r_cat_capitolo.elem_id
            and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
            and capitolo.ente_proprietario_id	=	'||p_ente_prop_id||'
            and capitolo.bil_id					=   '||bilancio_id||'
            and ct.classif_tipo_code				=	''CATEGORIA''           
            and tipo_elemento.elem_tipo_code 	=	'''||elemTipoCode||'''    
            and	stato_capitolo.elem_stato_code	=	''VA''         
            and	cat_del_capitolo.elem_cat_code	=	''STD''
            and capitolo.data_cancellazione 		is null
            and	r_capitolo_stato.data_cancellazione	is null
            and	r_cat_capitolo.data_cancellazione	is null
            and	rc.data_cancellazione				is null
            and	ct.data_cancellazione 				is null
            and	cl.data_cancellazione 				is null
            and	tipo_elemento.data_cancellazione	is null
            and	stato_capitolo.data_cancellazione 	is null
            and	cat_del_capitolo.data_cancellazione	is null),               
	strutt_bilancio as (select *
        		from "fnc_bilr_struttura_cap_bilancio_entrate"('||p_ente_prop_id||',
                				'''||p_anno||''',''''))
    select atti.attoamm_id::integer attoamm_id, 
    	  atti.attoamm_anno::varchar attoamm_anno,
    	  atti.attoamm_numero::integer attoamm_numero,
          atti.attoamm_tipo_code::varchar tipo_atto,
          atti.attoamm_oggetto::varchar attoamm_oggetto,
          atti.data_provv_var::timestamp data_provv_var,
          atti.data_approvazione_provv::timestamp data_approvazione_provv,
          ''''::varchar titoloe_tipo_code ,
          strutt_bilancio.classif_tipo_desc1::varchar titoloe_tipo_desc,
          strutt_bilancio.titolo_code::varchar titoloe_code,
          strutt_bilancio.titolo_desc::varchar titoloe_desc,
          ''''::varchar tipologia_tipo_code,
          strutt_bilancio.classif_tipo_desc2::varchar tipologia_tipo_desc,
          strutt_bilancio.tipologia_code::varchar tipologia_code,
          strutt_bilancio.tipologia_desc::varchar tipologia_desc,
          ''''::varchar categoria_tipo_code,
          strutt_bilancio.classif_tipo_desc3::varchar categoria_tipo_desc,
          strutt_bilancio.categoria_code::varchar categoria_code,
          strutt_bilancio.categoria_desc::varchar categoria_desc,
          capitoli.elem_code::varchar bil_ele_code,
          capitoli.elem_desc::varchar bil_ele_desc,
          capitoli.elem_code2::varchar bil_ele_code2,
          capitoli.elem_desc2::varchar bil_ele_desc2,
          capitoli.elem_id::integer bil_ele_id,
          case when atti.tipo_importo = '''||TipoImpComp||''' --STA
          		and atti.importo_var >= 0 then
                	COALESCE(atti.importo_var, 0)::numeric
                else 0::numeric end variazione_aumento_stanziato,
          case when atti.tipo_importo = '''||TipoImpComp||''' --STA
          		and atti.importo_var <0 then
                	COALESCE(atti.importo_var *-1, 0)::numeric
                else 0::numeric end  variazione_diminuzione_stanziato          
    from atti
    	LEFT JOIN capitoli
        	ON atti.elem_id = capitoli.elem_id
        LEFT JOIN strutt_bilancio
        	ON strutt_bilancio.categoria_id = capitoli.categoria_id ';

raise notice 'strQuery = % ', strQuery;     

return query execute strQuery ;

raise notice 'fine OK';

exception
	when no_data_found THEN
		raise notice 'nessun atto trovato' ;
        attoamm_id := NULL;
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
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR139_Allegato_8_Allegato_delibera_variazion_su_spese_fpv_txt" (
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
  variazione_aumento_cassa numeric,
  variazione_diminuzione_cassa numeric,
  variazione_aumento_residuo numeric,
  variazione_diminuzione_residuo numeric
) AS
$body$
DECLARE

annoCapImp varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_missioneprogramma  varchar;
v_fam_titolomacroaggregato varchar;
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
v_fam_missioneprogramma :='00001';
v_fam_titolomacroaggregato := '00002';

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
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;


/* Funzione nata per la SIAC-7195 per la gestione dei file in formato testo 
	per Unicredit.
    La funzione estrae i dati delle variazioni di spesa del report BILR139
    e del relativo atto.
    Questo report e' relativo solo a capitoli e variazioni FPV e solo per
    le spese.
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
            r_atto_stato.data_creazione data_approvazione_provv	      	
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
    		and		tipo_atto.attoamm_tipo_code				=	'''||p_tipo_delibera||'''
            and		stato_atto.attoamm_stato_code	=	''DEFINITIVO''';
   else
    	strQuery:=strQuery|| ' and		testata_variazione.variazione_num		in('||p_ele_variazioni||') ';
    end if;
   
    
    strQuery:=strQuery|| ' and		anno_importi.anno		= 	'''||p_anno_competenza||'''					
 	and		tipologia_stato_var.variazione_stato_tipo_code	=	''D''
    and		tipo_capitolo.elem_tipo_code					=	'''||elemTipoCode||'''
    and		tipo_elemento.elem_det_tipo_code				in (''STA'',''SCA'',''STR'')
    and 	cat_del_capitolo.elem_cat_code				in (''FPV'',''FPVC'')
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
            	atto.attoamm_id, atto.data_creazione, r_atto_stato.data_creazione),
	capitoli as (select programma.classif_id programma_id,
						macroaggr.classif_id macroaggregato_id,        				
       					capitolo.elem_code, capitolo.elem_code2,
                        capitolo.elem_desc, capitolo.elem_desc2,
                        capitolo.elem_id, capitolo.elem_id_padre
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
                    and stato_capitolo.elem_stato_code	=	''VA''				
                    and cat_del_capitolo.elem_cat_code	in (''FPV'',''FPVC'')                    
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
          		and atti.importo_var >= 0 then
                	COALESCE(atti.importo_var, 0)::numeric
                else 0::numeric end variazione_aumento_stanziato,
          case when atti.tipo_importo = '''||TipoImpComp||''' --STA
          		and atti.importo_var <0 then
                	COALESCE(atti.importo_var *-1, 0)::numeric
                else 0::numeric end  variazione_diminuzione_stanziato,
          case when atti.tipo_importo = '''||TipoImpCassa||''' --SCA
          		and atti.importo_var >= 0 then
                	COALESCE(atti.importo_var, 0)::numeric
                else 0::numeric end  variazione_aumento_cassa,
          case when atti.tipo_importo = '''||TipoImpCassa||''' --SCA
          		and atti.importo_var < 0 then
                	COALESCE(atti.importo_var *-1, 0)::numeric
                else 0::numeric end  variazione_diminuzione_cassa,
          case when atti.tipo_importo = '''||TipoImpRes||''' --STR
          		and atti.importo_var >= 0 then
                	COALESCE(atti.importo_var, 0)::numeric
                else 0::numeric end  variazione_aumento_residuo,
          case when atti.tipo_importo = '''||TipoImpRes||''' --STR
          		and atti.importo_var < 0 then
                	COALESCE(atti.importo_var *-1, 0)::numeric
                else 0::numeric end  variazione_diminuzione_residuo
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
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR024_Allegato_7_Allegato_delibera_variazione_su_spese_txt" (
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
  variazione_aumento_cassa numeric,
  variazione_diminuzione_cassa numeric,
  variazione_aumento_residuo numeric,
  variazione_diminuzione_residuo numeric
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
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;


/* Funzione nata per la SIAC-7195 per la gestione dei file in formato testo 
	per Unicredit.
    La funzione estrae i dati delle variazioni di spesa del report BILR024 e del
    relativo atto.
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
            r_atto_stato.data_creazione data_approvazione_provv	      	
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
            siac_t_periodo 				anno_importi
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
    and 	atto.ente_proprietario_id 							= 	'||p_ente_prop_id ||'
    and 	testata_variazione.bil_id							=   '||bilancio_id;
    if p_numero_delibera IS NOT NULL THEN
    	strQuery:=strQuery|| ' and	atto.attoamm_numero 	= 	'||p_numero_delibera||'
    		and		atto.attoamm_anno						=	'''||p_anno_delibera||'''
    		and		tipo_atto.attoamm_tipo_code				=	'''||p_tipo_delibera||'''
            and		stato_atto.attoamm_stato_code	=	''DEFINITIVO''';
   else
    	strQuery:=strQuery|| ' and		testata_variazione.variazione_num		in('||p_ele_variazioni||') ';
    end if;
   
    
    strQuery:=strQuery|| ' and		anno_importi.anno		= 	'''||p_anno_competenza||'''					
 	and		tipologia_stato_var.variazione_stato_tipo_code	=	''D''
    and		tipo_capitolo.elem_tipo_code					=	'''||elemTipoCode||'''
    and		tipo_elemento.elem_det_tipo_code				in (''STA'',''SCA'',''STR'')
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
    group by 	atto.attoamm_anno, atto.attoamm_numero,tipo_atto.attoamm_tipo_code,
    			atto.attoamm_oggetto, dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
            	atto.attoamm_id, atto.data_creazione, r_atto_stato.data_creazione),
	capitoli as (select programma.classif_id programma_id,
						macroaggr.classif_id macroaggregato_id,        				
       					capitolo.elem_code, capitolo.elem_code2,
                        capitolo.elem_desc, capitolo.elem_desc2,
                        capitolo.elem_id, capitolo.elem_id_padre
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
                    and stato_capitolo.elem_stato_code	=	''VA''				
                    and cat_del_capitolo.elem_cat_code	in (''STD'',''FPV'',''FSC'',''FPVC'')                    
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
          		and atti.importo_var >= 0 then
                	COALESCE(atti.importo_var, 0)::numeric
                else 0::numeric end variazione_aumento_stanziato,
          case when atti.tipo_importo = '''||TipoImpComp||''' --STA
          		and atti.importo_var <0 then
                	COALESCE(atti.importo_var *-1, 0)::numeric
                else 0::numeric end  variazione_diminuzione_stanziato,
          case when atti.tipo_importo = '''||TipoImpCassa||''' --SCA
          		and atti.importo_var >= 0 then
                	COALESCE(atti.importo_var, 0)::numeric
                else 0::numeric end  variazione_aumento_cassa,
          case when atti.tipo_importo = '''||TipoImpCassa||''' --SCA
          		and atti.importo_var < 0 then
                	COALESCE(atti.importo_var *-1, 0)::numeric
                else 0::numeric end  variazione_diminuzione_cassa,
          case when atti.tipo_importo = '''||TipoImpRes||''' --STR
          		and atti.importo_var >= 0 then
                	COALESCE(atti.importo_var, 0)::numeric
                else 0::numeric end  variazione_aumento_residuo,
          case when atti.tipo_importo = '''||TipoImpRes||''' --STR
          		and atti.importo_var < 0 then
                	COALESCE(atti.importo_var *-1, 0)::numeric
                else 0::numeric end  variazione_diminuzione_residuo
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
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR024_Allegato_7_Allegato_delibera_variazione_su_entrate_txt" (
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
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  variazione_aumento_stanziato numeric,
  variazione_diminuzione_stanziato numeric,
  variazione_aumento_cassa numeric,
  variazione_diminuzione_cassa numeric,
  variazione_aumento_residuo numeric,
  variazione_diminuzione_residuo numeric
) AS
$body$
DECLARE

DataSetAtti record;
contaRec integer;

annoCapImp varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_titolotipologiacategoria varchar:='00003';
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;
bilancio_id integer;


BEGIN

--annoCapImp:= p_anno; 
annoCapImp:=p_anno_competenza;

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-EG'; -- tipo capitolo gestione


titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;

    
/* Funzione nata per la SIAC-7195 per la gestione dei file in formato testo 
	per Unicredit.
    La funzione estrae i dati delle variazioni di entata del report BILR024 e del
    relativo atto.
*/

select fnc_siac_random_user()
into	user_table;

select a.bil_id 
	into bilancio_id 
from siac_t_bil a,
		siac_t_periodo b
where b.periodo_id=a.periodo_id
	and a.ente_proprietario_id=p_ente_prop_id 
	and b.anno=p_anno
    and a.data_cancellazione IS NULL
    and b.data_cancellazione IS NULL;
    
raise notice '1 - %' , clock_timestamp()::text;


	--preparo la query generale
strQuery:='          
with atti as(select	atto.attoamm_anno, atto.attoamm_numero,
			tipo_atto.attoamm_tipo_code, atto.attoamm_oggetto,
			dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo) importo_var,        
            tipo_elemento.elem_det_tipo_code tipo_importo,            
            '''||p_anno_competenza||''',
            atto.attoamm_id, atto.data_creazione data_provv_var,
            r_atto_stato.data_creazione data_approvazione_provv	      	
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
            siac_t_periodo 				anno_importi
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
    and 	atto.ente_proprietario_id 							= 	'||p_ente_prop_id ||'
    and 	testata_variazione.bil_id							=   '||bilancio_id;
    if p_numero_delibera IS NOT NULL THEN
    	strQuery:=strQuery|| ' and	atto.attoamm_numero 	= 	'||p_numero_delibera||'
    		and		atto.attoamm_anno						=	'''||p_anno_delibera||'''
    		and		tipo_atto.attoamm_tipo_code				=	'''||p_tipo_delibera||'''
            and		stato_atto.attoamm_stato_code	=	''DEFINITIVO''';
   else
    	strQuery:=strQuery|| ' and		testata_variazione.variazione_num		in('||p_ele_variazioni||') ';
    end if;
       
    strQuery:=strQuery|| ' and		anno_importi.anno		= 	'''||p_anno_competenza||'''					
 	and		tipologia_stato_var.variazione_stato_tipo_code	=	''D''
    and		tipo_capitolo.elem_tipo_code					=	'''||elemTipoCode||'''
    and		tipo_elemento.elem_det_tipo_code				in (''STA'',''SCA'',''STR'')
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
    group by 	atto.attoamm_anno, atto.attoamm_numero,tipo_atto.attoamm_tipo_code,
    			atto.attoamm_oggetto, dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
            	atto.attoamm_id, atto.data_creazione, r_atto_stato.data_creazione),
 capitoli as (select cl.classif_id categoria_id,
              '''||p_anno||''' anno_bilancio,
              capitolo.elem_code, capitolo.elem_code2,
              capitolo.elem_desc, capitolo.elem_desc2,
              capitolo.elem_id, capitolo.elem_id_padre
             from 	siac_r_bil_elem_class rc,
                    siac_t_bil_elem capitolo,
                    siac_d_class_tipo ct,
                    siac_t_class cl,
                    siac_d_bil_elem_tipo tipo_elemento, 
                    siac_d_bil_elem_stato stato_capitolo,
                    siac_r_bil_elem_stato r_capitolo_stato,
                    siac_d_bil_elem_categoria cat_del_capitolo,
                    siac_r_bil_elem_categoria r_cat_capitolo
            where ct.classif_tipo_id				=	cl.classif_tipo_id
            and cl.classif_id					=	rc.classif_id 
            and capitolo.elem_tipo_id			=	tipo_elemento.elem_tipo_id 
            and capitolo.elem_id				=	rc.elem_id 
            and	capitolo.elem_id				=	r_capitolo_stato.elem_id
            and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id				=	r_cat_capitolo.elem_id
            and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
            and capitolo.ente_proprietario_id	=	'||p_ente_prop_id||'
            and capitolo.bil_id					=   '||bilancio_id||'
            and ct.classif_tipo_code				=	''CATEGORIA''           
            and tipo_elemento.elem_tipo_code 	=	'''||elemTipoCode||'''   
            and	stato_capitolo.elem_stato_code	=	''VA''         
            and	cat_del_capitolo.elem_cat_code	=	''STD''
            and capitolo.data_cancellazione 		is null
            and	r_capitolo_stato.data_cancellazione	is null
            and	r_cat_capitolo.data_cancellazione	is null
            and	rc.data_cancellazione				is null
            and	ct.data_cancellazione 				is null
            and	cl.data_cancellazione 				is null
            and	tipo_elemento.data_cancellazione	is null
            and	stato_capitolo.data_cancellazione 	is null
            and	cat_del_capitolo.data_cancellazione	is null),               
	strutt_bilancio as (select *
        		from "fnc_bilr_struttura_cap_bilancio_entrate"('||p_ente_prop_id||',
                				'''||p_anno||''',''''))
    select atti.attoamm_id::integer attoamm_id, 
    	  atti.attoamm_anno::varchar attoamm_anno,
    	  atti.attoamm_numero::integer attoamm_numero,
          atti.attoamm_tipo_code::varchar tipo_atto,
          atti.attoamm_oggetto::varchar attoamm_oggetto,
          atti.data_provv_var::timestamp data_provv_var,
          atti.data_approvazione_provv::timestamp data_approvazione_provv,
          ''''::varchar titoloe_tipo_code ,
          strutt_bilancio.classif_tipo_desc1::varchar titoloe_tipo_desc,
          strutt_bilancio.titolo_code::varchar titoloe_code,
          strutt_bilancio.titolo_desc::varchar titoloe_desc,
          ''''::varchar tipologia_tipo_code,
          strutt_bilancio.classif_tipo_desc2::varchar tipologia_tipo_desc,
          strutt_bilancio.tipologia_code::varchar tipologia_code,
          strutt_bilancio.tipologia_desc::varchar tipologia_desc,
          ''''::varchar categoria_tipo_code,
          strutt_bilancio.classif_tipo_desc3::varchar categoria_tipo_desc,
          strutt_bilancio.categoria_code::varchar categoria_code,
          strutt_bilancio.categoria_desc::varchar categoria_desc,
          capitoli.elem_code::varchar bil_ele_code,
          capitoli.elem_desc::varchar bil_ele_desc,
          capitoli.elem_code2::varchar bil_ele_code2,
          capitoli.elem_desc2::varchar bil_ele_desc2,
          capitoli.elem_id::integer bil_ele_id,
          case when atti.tipo_importo = '''||TipoImpComp||''' --STA
          		and atti.importo_var >= 0 then
                	COALESCE(atti.importo_var, 0)::numeric
                else 0::numeric end variazione_aumento_stanziato,
          case when atti.tipo_importo = '''||TipoImpComp||''' --STA
          		and atti.importo_var <0 then
                	COALESCE(atti.importo_var *-1, 0)::numeric
                else 0::numeric end  variazione_diminuzione_stanziato,
          case when atti.tipo_importo = '''||TipoImpCassa||''' --SCA
          		and atti.importo_var >= 0 then
                	COALESCE(atti.importo_var, 0)::numeric
                else 0::numeric end  variazione_aumento_cassa,
          case when atti.tipo_importo = '''||TipoImpCassa||''' --SCA
          		and atti.importo_var < 0 then
                	COALESCE(atti.importo_var *-1, 0)::numeric
                else 0::numeric end  variazione_diminuzione_cassa,
          case when atti.tipo_importo = '''||TipoImpRes||''' --STR
          		and atti.importo_var >= 0 then
                	COALESCE(atti.importo_var, 0)::numeric
                else 0::numeric end  variazione_aumento_residuo,
          case when atti.tipo_importo = '''||TipoImpRes||''' --STR
          		and atti.importo_var < 0 then
                	COALESCE(atti.importo_var *-1, 0)::numeric
                else 0::numeric end  variazione_diminuzione_residuo
    from atti
    	LEFT JOIN capitoli
        	ON atti.elem_id = capitoli.elem_id
        LEFT JOIN strutt_bilancio
        	ON strutt_bilancio.categoria_id = capitoli.categoria_id'; 
    --    LEFT JOIN siac_rep_cap_eg_imp imp imp_cap 
        --	ON imp_cap.elem_id = capitoli.elem_id';

raise notice 'strQuery = % ', strQuery;     

return query execute strQuery ;

raise notice 'fine OK';

exception
	when no_data_found THEN
		raise notice 'nessun atto trovato' ;
        attoamm_id := NULL;
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
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR024_Allegato_7_Allegato_delibera_variaz_totali_spese_txt" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  stanziato_totale numeric,
  cassa_totale numeric,
  residuo_totale numeric
) AS
$body$
DECLARE

DataSetAtti record;
contaRec integer;

annoCapImp varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_titolotipologiacategoria varchar:='00003';
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;
bilancio_id integer;
stanz_tot numeric;
cassa_tot numeric;
residui_tot numeric;
importi_var_capitoli numeric;

BEGIN

--annoCapImp:= p_anno; 
annoCapImp:=p_anno_competenza;

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione


stanziato_totale=0;
cassa_totale=0;
residuo_totale=0;

    
/* Funzione nata per la SIAC-7195 per la gestione dei file in formato testo 
	per Unicredit.
    La funzione estrae i totali complessivi che comprendono i dati delle variazioni
    considerate da i parametri in input. 
*/

select fnc_siac_random_user()
into	user_table;

select a.bil_id 
	into bilancio_id 
from siac_t_bil a,
		siac_t_periodo b
where b.periodo_id=a.periodo_id
	and a.ente_proprietario_id=p_ente_prop_id 
	and b.anno=p_anno
    and a.data_cancellazione IS NULL
    and b.data_cancellazione IS NULL;
    
raise notice '1 - %' , clock_timestamp()::text;

	--dati variabili dei capitoli.
select sum(stanziato)-sum(variazione_aumento)+sum(variazione_diminuzione)
	into importi_var_capitoli
from "BILR024_Allegato_7_Allegato_delibera_variazione_variabili" 
	(p_ente_prop_id,p_anno,p_numero_delibera,p_anno_delibera,p_tipo_delibera,
    p_anno_competenza,p_ele_variazioni,' ') 
where tipologia_capitolo in('DAM');

 /* carico sulla tabella di appoggio siac_rep_cap_ug_imp gli importi dei capitoli
    	decrementando gli importi delle varizioni successive a quelle 
        specificate in input. */
strQuery:= 'with cap as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,           
            capitolo_imp_tipo.elem_det_tipo_id,
            sum(capitolo_importi.elem_det_importo) importo_cap
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,            
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_t_bil_elem 			capitolo	             			            
     where 	capitolo_importi.ente_proprietario_id 	='||p_ente_prop_id||' 
        and	anno_eserc.anno						= 	'''||p_anno||'''												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno  =  '''||p_anno_competenza||'''
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code		=	''VA''								
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and cat_del_capitolo.elem_cat_code	in (''STD'',''FPV'',''FSC'',''FPVC'')
        and capitolo_imp_tipo.elem_det_tipo_code in (''STA'',''SCA'',''STR'')						
 		and	capitolo_importi.data_cancellazione 		is null
        and	capitolo_imp_tipo.data_cancellazione 		is null
       	and	capitolo_imp_periodo.data_cancellazione 	is null
        and	capitolo.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione 			is null
        and	bilancio.data_cancellazione 				is null
	 	and	anno_eserc.data_cancellazione 				is null 
	 	and	stato_capitolo.data_cancellazione 			is null 
    	and	r_capitolo_stato.data_cancellazione 		is null
	 	and cat_del_capitolo.data_cancellazione 		is null
    	and	r_cat_capitolo.data_cancellazione 			is null
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id,  cat_del_capitolo.elem_cat_code,
    	capitolo_imp_tipo.elem_det_tipo_id),
        -- SIAC-7200 nella query che estrae le variazioni successive, aggiunto
        --  il test sull''anno (periodo_id) che lega la variazione corrente
        --  (siac_t_variazione avar) a quelle successive (siac_t_variazione avarsucc).
 importi_variaz as(    with varcurr as (              
      select dvar.elem_id elem_id_var, bvar.validita_inizio, dvar.periodo_id,
          dvar.elem_det_tipo_id
      from 
      siac_t_variazione avar, siac_r_variazione_stato bvar,
      siac_d_variazione_stato cvar, siac_t_bil_elem_det_var dvar, siac_t_periodo periodo_importo_variazione
      where avar.variazione_id=bvar.variazione_id
      and bvar.variazione_stato_tipo_id=cvar.variazione_stato_tipo_id
      and dvar.variazione_stato_id=bvar.variazione_stato_id         
      and cvar.variazione_stato_tipo_code=''D''                            
      and bvar.data_cancellazione is null
      and bvar.variazione_stato_id in (';
if p_numero_delibera IS NOT NULL THEN  --specifico un atto.
strQuery:=strQuery||'                      
            select max(var_stato.variazione_stato_id)
            from siac_t_atto_amm             atto,
              siac_d_atto_amm_tipo        tipo_atto,
              siac_r_atto_amm_stato         r_atto_stato,
              siac_d_atto_amm_stato         stato_atto,
              siac_r_variazione_stato     var_stato
            where
              (var_stato.attoamm_id = atto.attoamm_id 
                 or var_stato.attoamm_id_varbil = atto.attoamm_id )                  
              and     r_atto_stato.attoamm_id   =   atto.attoamm_id 
              and     r_atto_stato.attoamm_stato_id     =   stato_atto.attoamm_stato_id
              and     atto.ente_proprietario_id   =   '||p_ente_prop_id||'
              and     atto.attoamm_numero=  '||p_numero_delibera||'
              and     atto.attoamm_anno  =  '''||p_anno_delibera||'''                 
              and     tipo_atto.attoamm_tipo_code  = '''||p_tipo_delibera||'''
              and     stato_atto.attoamm_stato_code   =   ''DEFINITIVO'') ';
else        -- specificato l'elenco delle variazione.          
      	strQuery:=strQuery||'     
                select max(var_stato.variazione_stato_id)
                from siac_t_variazione t_var,
                  siac_r_variazione_stato     var_stato
                where
                  t_var.variazione_id = var_stato.variazione_id
                  and t_var.ente_proprietario_id = '||p_ente_prop_id||'
                  and t_var.variazione_num in('||p_ele_variazioni||')
                  and t_var.data_cancellazione IS NULL
                  and var_stato.data_cancellazione IS NULL )
                  and periodo_importo_variazione.periodo_id = dvar.periodo_id                     	--  SIAC-7311
                  and periodo_importo_variazione.anno =  '''||p_anno_competenza||'''';              -- 	SIAC-7311  
end if;                
		
strQuery:=strQuery||'),
      varsuccess as (select dvarsucc.elem_id elem_id_var, tipoimp.elem_det_tipo_id,
          dvarsucc.periodo_id, bvarsucc.validita_inizio,
          COALESCE(dvarsucc.elem_det_importo,0) importo_var
          from siac_t_variazione avarsucc, siac_r_variazione_stato bvarsucc,              
          siac_d_variazione_stato cvarsucc,
          siac_t_bil_elem_det_var dvarsucc,
          siac_d_bil_elem_det_tipo tipoimp,
          siac_t_periodo periodo_importo_variazione
          where avarsucc.variazione_id= bvarsucc.variazione_id
          and bvarsucc.variazione_stato_tipo_id=cvarsucc.variazione_stato_tipo_id
          and dvarsucc.variazione_stato_id = bvarsucc.variazione_stato_id
          and tipoimp.elem_det_tipo_id = dvarsucc.elem_det_tipo_id
          and dvarsucc.ente_proprietario_id= '||p_ente_prop_id||'                            
          and cvarsucc.variazione_stato_tipo_code=''D''                                          
          and periodo_importo_variazione.periodo_id = dvarsucc.periodo_id                             --  SIAC-7311
          and periodo_importo_variazione.anno =   '''||p_anno_competenza||'''                         --  SIAC-7311
                    and bvarsucc.data_cancellazione is null
          and dvarsucc.data_cancellazione IS NULL)
      select  varsuccess.elem_id_var, varsuccess.elem_det_tipo_id,
              sum(varsuccess.importo_var) totale_var_succ
      from varcurr
            JOIN varsuccess
              on (varcurr.elem_det_tipo_id = varsuccess.elem_det_tipo_id
                    and varcurr.periodo_id = varsuccess.periodo_id
                    and varsuccess.validita_inizio > varcurr.validita_inizio
                    and varcurr.elem_id_var = varsuccess.elem_id_var)                                --  SIAC-7311
      group by varsuccess.elem_id_var, varsuccess.elem_det_tipo_id  )    
                    INSERT INTO siac_rep_cap_ug_imp
                    select 	cap.elem_id, 
                              cap.BIL_ELE_IMP_ANNO, 
                              cap.TIPO_IMP,
                              cap.ente_proprietario_id, 
                              '''||user_table||''' utente,               
                              (cap.importo_cap  - COALESCE(importi_variaz.totale_var_succ,0)) diff
                    from cap LEFT  JOIN importi_variaz 
                    ON (cap.elem_id = importi_variaz.elem_id_var
                      and cap.elem_det_tipo_id= importi_variaz.elem_det_tipo_id);';
raise notice 'Query1 = %', strQuery;                

raise notice 'Inizio query importi capitoli - %' , clock_timestamp()::text;
execute  strQuery;


	--stanziato totale
select sum(importo)
into stanziato_totale
from siac_rep_cap_ug_imp
where ente_proprietario=p_ente_prop_id
and tipo_imp= 'STA'
and periodo_anno=p_anno_competenza
and utente = user_table;

	--allo stanziato aggiungo i dati dei capitoli.
stanziato_totale:=stanziato_totale+importi_var_capitoli;

	--cassa
select sum(importo)
into cassa_totale
from siac_rep_cap_ug_imp
where ente_proprietario=p_ente_prop_id
and tipo_imp= 'SCA'
and periodo_anno=p_anno_competenza
and utente = user_table;

	--residuo
select sum(importo)
into residuo_totale
from siac_rep_cap_ug_imp
where ente_proprietario=p_ente_prop_id
and tipo_imp= 'STR'
and periodo_anno=p_anno_competenza
and utente = user_table;

return next;

delete from siac_rep_cap_ug_imp where utente = user_table;

raise notice 'fine OK';

exception
	when no_data_found THEN
		raise notice 'nessun atto trovato' ;
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
COST 100 ROWS 1000;

--SIAC-7195 - Maurizio - FINE
--SIAC-7516 INIZIO
insert into siac_d_doc_tipo
(
  doc_tipo_code,
  doc_tipo_desc,
  doc_fam_tipo_id,
  doc_gruppo_tipo_id,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select 'FSN',
       'FATTURA NEGATIVA DA INCASSARE',
       tipo.doc_fam_tipo_id,
       null,
       now(),
       'admin_SIAC-7516',
       tipo.ente_proprietario_id
from siac_d_doc_fam_tipo tipo,siac_t_ente_proprietario ente--, siac_d_doc_fam_tipo fam_tipo
where tipo.ente_proprietario_id  = ente.ente_proprietario_id 
and tipo.doc_fam_tipo_code='E'
and   not exists
(select 1 
from siac_d_doc_tipo tipo1 where 
tipo1.ente_proprietario_id= ente.ente_proprietario_id 
and tipo1.doc_tipo_code='FSN' and tipo1.data_cancellazione is null);
--SIAC-7516 FINE
