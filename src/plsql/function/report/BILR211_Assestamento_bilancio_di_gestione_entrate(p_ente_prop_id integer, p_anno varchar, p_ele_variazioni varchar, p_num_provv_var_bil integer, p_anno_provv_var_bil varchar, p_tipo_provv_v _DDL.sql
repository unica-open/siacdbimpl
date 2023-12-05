/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR211_Assestamento_bilancio_di_gestione_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_num_provv_var_bil integer,
  p_anno_provv_var_bil varchar,
  p_tipo_provv_var_bil varchar,
  p_tipo_var varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  tipo_capitolo varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  residui_presunti numeric,
  variaz_stanz_anno numeric,
  variaz_stanz_anno1 numeric,
  variaz_stanz_anno2 numeric,
  variaz_residui_anno numeric,
  variaz_cassa_anno numeric,
  code_direz_strut_amm_resp varchar,
  desc_direz_strut_amm_resp varchar,
  code_sett_strut_amm_resp varchar,
  desc_sett_strut_amm_resp varchar,
  code_tipo_finanz varchar,
  desc_tipo_finanz varchar,
  display_error varchar
) AS
$body$
DECLARE
classifBilRec record;
elencoVarRec  record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
TipoImpresidui varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
annoPrec VARCHAR;
importo_cassa_app numeric;
importo_competenza_app numeric;
intApp INTEGER;
strApp VARCHAR;
sql_query VARCHAR;
v_fam_titolotipologiacategoria varchar:='00003';
x_array VARCHAR [];
contaParVarPeg integer;
contaParVarBil integer;
sql_query_var1 varchar;
sql_query_var2 varchar;
cercaVariaz boolean;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;  

TipoImpComp='STA';  -- competenza
TipoImpresidui='STR'; -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
TipoImpCassa ='SCA'; ----- previsioni di cassa
elemTipoCode:='CAP-EG'; -- tipo capitolo previsione

bil_anno='';

titoloe_CODE='';
titoloe_DESC='';

tipologia_code='';
tipologia_desc='';

categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
residui_presunti:=0;
--previsioni_anno_prec:=0;
stanziamento_prev_cassa_anno:=0;
display_error='';
contaParVarPeg:=0;
contaParVarBil:=0;
sql_query_var1:='';
sql_query_var2:='';
cercaVariaz:=false;

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    intApp = strApp::INTEGER;
  END LOOP;
END IF;

if p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if contaParVarBil not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione''';
    return next;
    return;        
end if;
sql_query:='';

IF (p_ele_variazioni IS  NULL OR p_ele_variazioni = '') AND
	contaParVarBil = 0 AND
    (p_tipo_var IS NULL OR p_tipo_var = '') THEN
    display_error='OCCORRE SPECIFICARE ALMENO 1 PARAMETRO RELATIVO ALLE VARIAZIONI';
    return next;
    return;  
    
end if;
select fnc_siac_random_user()
into	user_table;


--preparo la parte della query relativa alle variazioni.
	
	sql_query_var1='    
    select	dettaglio_variazione.elem_id,
    		anno_importo.anno,
            sum(dettaglio_variazione.elem_det_importo) importo_var            	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio ';                
    if contaParVarBil = 3 then 
    	sql_query_var1=sql_query_var1||'        	
        	,siac_t_atto_amm 			atto ,
            siac_d_atto_amm_tipo		tipo_atto,
			siac_r_atto_amm_stato 		r_atto_stato,
	        siac_d_atto_amm_stato 		stato_atto ';
    end if;
    sql_query_var1=sql_query_var1||' where 	r_variazione_stato.variazione_id =	testata_variazione.variazione_id
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
    
    if contaParVarBil = 3 then 
    	sql_query_var1=sql_query_var1||' 
        and		r_variazione_stato.attoamm_id_varbil				=	atto.attoamm_id
    	and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    	and 	atto.attoamm_id									= 	r_atto_stato.attoamm_id
    	and 	r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id ';
    end if;

--sono escluse le variazioni ANNULLATE e DEFINITIVE.            
    sql_query_var1=sql_query_var1||' and		testata_variazione.ente_proprietario_id				= ' || p_ente_prop_id;
    sql_query_var1=sql_query_var1 || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code not in (''D'',''A'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''';    
    IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query_var2= ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    end if;
    
    if contaParVarBil = 3 then 
    	sql_query_var2=sql_query_var2||' AND stato_atto.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto.attoamm_numero ='||p_num_provv_var_bil||' 
    	and 	atto.attoamm_anno ='''||p_anno_provv_var_bil||'''
    	and		tipo_atto.attoamm_tipo_code='''||p_tipo_provv_var_bil||''' ';
    end if;
    if (p_tipo_var IS NOT NULL AND p_tipo_var <> '') THEN
    	sql_query_var2=sql_query_var2||' 
        and tipologia_variazione.variazione_tipo_code = '''||p_tipo_var||'''';
    end if;
    sql_query_var2=sql_query_var2 || ' and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
     
    if contaParVarBil = 3 then 
    	sql_query_var2=sql_query_var2 || ' and 	atto.data_cancellazione		is null
    	and 	tipo_atto.data_cancellazione				is null
    	and 	r_atto_stato.data_cancellazione			is null ';
    end if;
    sql_query_var2=sql_query_var2 || ' group by 	dettaglio_variazione.elem_id,               
                anno_importo.anno';	     
         
--raise notice 'Query VAR: % ',  sql_query_var1||sql_query_var2;      

-- preparo la query totale.
sql_query:='with strutt_amm as (
	select * from "fnc_bilr_struttura_cap_bilancio_entrate"('||p_ente_prop_id||','''||p_anno||''','''')),
ele_cap as (select classific.classif_id,
    anno_eserc.anno anno_bilancio,
    cap.*, cat_del_capitolo.elem_cat_code
   from   siac_t_bil_elem cap
   			LEFT JOIN (select rc.elem_id, rc.classif_id
				from   siac_r_bil_elem_class rc,
  					siac_t_class cl,
        			siac_d_class_tipo ct
				where  cl.classif_id = rc.classif_id
    				AND ct.classif_tipo_id	= cl.classif_tipo_id
    				AND rc.ente_proprietario_id = '||p_ente_prop_id||'
    				AND ct.classif_tipo_code			=	''CATEGORIA''
					AND rc.data_cancellazione IS NULL
    				AND cl.data_cancellazione IS NULL
    				AND  ct.data_cancellazione IS NULL
    				AND now() between rc.validita_inizio and coalesce (rc.validita_fine, now()) 
    				AND now() between cl.validita_inizio and coalesce (cl.validita_fine, now()) 
    				AND	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())) classific
            	ON classific.elem_id= cap.elem_id,                    
          siac_t_bil bilancio,
          siac_t_periodo anno_eserc,
          siac_d_bil_elem_tipo tipo_elemento, 
          siac_d_bil_elem_stato stato_capitolo,
          siac_r_bil_elem_stato r_capitolo_stato,
          siac_d_bil_elem_categoria cat_del_capitolo,
          siac_r_bil_elem_categoria r_cat_capitolo
  where bilancio.periodo_id				=	anno_eserc.periodo_id 
  and cap.bil_id						=	bilancio.bil_id 
  and cap.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
  and	cap.elem_id						=	r_capitolo_stato.elem_id
  and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
  and	cap.elem_id						=	r_cat_capitolo.elem_id
  and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
  and cap.ente_proprietario_id 			=	'||p_ente_prop_id||'
  and anno_eserc.anno					= 	'''||p_anno||'''
  and tipo_elemento.elem_tipo_code 	= 	''CAP-EG''
  and	stato_capitolo.elem_stato_code	=	''VA''
  and cap.data_cancellazione 				is null
  and	r_capitolo_stato.data_cancellazione	is null
  and	bilancio.data_cancellazione 		is null
  and	anno_eserc.data_cancellazione 		is null
  and	tipo_elemento.data_cancellazione	is null
  and	stato_capitolo.data_cancellazione 	is null
  and	cat_del_capitolo.data_cancellazione	is null
  and	now() between cap.validita_inizio and coalesce (cap.validita_fine, now())
  and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
  and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
  and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
  and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
  and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
  and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
  and	now() between r_cat_capitolo.validita_inizio 
  and coalesce (r_cat_capitolo.validita_fine, now())),
strutt_amm_resp as (
	select *
    from "fnc_elenco_direzioni_settori_cap"('||p_ente_prop_id||')),
tipo_finanziamento_class as
(
select rc.elem_id,
       c.classif_id classif_tipo_fin_id,
       c.classif_code classif_tipo_fin_code,
       c.classif_desc  classif_tipo_fin_desc
from siac_d_class_tipo tipoc, siac_t_class c, siac_r_bil_elem_class rc
where tipoc.ente_proprietario_id='||p_ente_prop_id||'
and   tipoc.classif_tipo_code=''TIPO_FINANZIAMENTO''
and   c.classif_tipo_id=tipoc.classif_tipo_id
and   rc.classif_id=c.classif_id
and   rc.data_cancellazione is null
and   rc.validita_fine is null
and   c.data_cancellazione is null),    
imp_comp_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
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
    where 	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_importi.ente_proprietario_id = '||p_ente_prop_id||' 
        and	anno_eserc.anno						= 	'''||p_anno||''' 	
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
		and	stato_capitolo.elem_stato_code		=	''VA''
        and	capitolo_imp_periodo.anno in ('''||annoCapImp||''')
        and	capitolo_imp_tipo.elem_det_tipo_code = '''||TipoImpComp||'''
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
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id), 
imp_comp_anno1 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
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
    where 	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_importi.ente_proprietario_id = '||p_ente_prop_id||'  
        and	anno_eserc.anno						= 	'''||p_anno||'''	
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
		and	stato_capitolo.elem_stato_code		=	''VA''
        and	capitolo_imp_periodo.anno in ('''||annoCapImp1||''')	
        and	capitolo_imp_tipo.elem_det_tipo_code = '''||TipoImpComp||'''
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
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
    group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_anno2 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
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
    where 	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_importi.ente_proprietario_id = '||p_ente_prop_id ||' 
        and	anno_eserc.anno						= 	'''||p_anno||'''	
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
		and	stato_capitolo.elem_stato_code		=	''VA''
        and	capitolo_imp_periodo.anno in ('''||annoCapImp2||''')	
        and	capitolo_imp_tipo.elem_det_tipo_code = '''||TipoImpComp||'''
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
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
    group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_residui_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
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
    where 	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_importi.ente_proprietario_id = '||p_ente_prop_id||' 
        and	anno_eserc.anno						= 	'''||p_anno||'''	
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
		and	stato_capitolo.elem_stato_code		=	''VA''
        and	capitolo_imp_periodo.anno in ('''||annoCapImp||''')
        and	capitolo_imp_tipo.elem_det_tipo_code = '''||TipoImpresidui||'''
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
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_cassa_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
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
    where 	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_importi.ente_proprietario_id = '||p_ente_prop_id||' 
        and	anno_eserc.anno						= 	'''||p_anno||''' 	
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
		and	stato_capitolo.elem_stato_code		=	''VA''
        and	capitolo_imp_periodo.anno in ('''||annoCapImp||''')
        and	capitolo_imp_tipo.elem_det_tipo_code = '''||TipoImpCassa||'''
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
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id), ';
        
/* inserisco la parte di query relativa alle variazioni */
	  sql_query:= sql_query||'
      imp_variaz_comp_anno as('||sql_query_var1||'
      and	tipo_elemento.elem_det_tipo_code in (''STA'')
      and   anno_importo.anno='''||annoCapImp||''''||sql_query_var2||'), 
      imp_variaz_comp_anno1 as('||sql_query_var1||'
      and	tipo_elemento.elem_det_tipo_code in (''STA'')
      and   anno_importo.anno='''||annoCapImp1||''''||sql_query_var2||'),
      imp_variaz_comp_anno2 as('||sql_query_var1||'
      and	tipo_elemento.elem_det_tipo_code in (''STA'')
      and   anno_importo.anno='''||annoCapImp2||''''||sql_query_var2||'),
	  imp_variaz_residui_anno as('||sql_query_var1||'
      and	tipo_elemento.elem_det_tipo_code in (''STR'')
      and   anno_importo.anno='''||annoCapImp||''''||sql_query_var2||'),
      imp_variaz_cassa_anno as('||sql_query_var1||'
      and	tipo_elemento.elem_det_tipo_code in (''SCA'')
      and   anno_importo.anno='''||annoCapImp||''''||sql_query_var2||')
      ';
sql_query:= sql_query||'                        
select '''||p_anno||'''::varchar bil_anno,
	strutt_amm.titolo_code::varchar titoloe_code,
    strutt_amm.titolo_desc::varchar titoloe_desc,
    left(strutt_amm.tipologia_code,5)::varchar tipologia_code,
    strutt_amm.tipologia_desc::varchar tipologia_desc,
    strutt_amm.categoria_code::varchar categoria_code,
    strutt_amm.categoria_desc::varchar categoria_desc,
    ele_cap.elem_cat_code::varchar tipo_capitolo,
    ele_cap.elem_code::varchar bil_ele_code,
    ele_cap.elem_desc::varchar bil_ele_desc,
    ele_cap.elem_code2::varchar bil_ele_code2,
    ele_cap.elem_desc2::varchar bil_ele_desc2,
    ele_cap.elem_id::integer  bil_ele_id,
    ele_cap.elem_id_padre::integer  bil_ele_id_padre,
    COALESCE(imp_cassa_anno.importo,0)::numeric stanziamento_prev_cassa_anno,
    COALESCE(imp_comp_anno.importo,0)::numeric stanziamento_prev_anno,
    COALESCE(imp_comp_anno1.importo,0)::numeric stanziamento_prev_anno1,
    COALESCE(imp_comp_anno2.importo,0)::numeric stanziamento_prev_anno2,
    COALESCE(imp_residui_anno.importo,0)::numeric residui_presunti,
    COALESCE(imp_variaz_comp_anno.importo_var,0)::numeric variaz_stanz_anno,
    COALESCE(imp_variaz_comp_anno1.importo_var,0)::numeric variaz_stanz_anno1,
    COALESCE(imp_variaz_comp_anno2.importo_var,0)::numeric variaz_stanz_anno2,
    COALESCE(imp_variaz_residui_anno.importo_var,0)::numeric variaz_residui_anno,
    COALESCE(imp_variaz_cassa_anno.importo_var,0)::numeric variaz_cassa_anno,
    COALESCE(strutt_amm_resp.cod_direz,'''')::varchar code_direz_strut_amm_resp,
    COALESCE(strutt_amm_resp.desc_direz,'''')::varchar desc_direz_strut_amm_resp,
    COALESCE(strutt_amm_resp.cod_sett,'''')::varchar code_sett_strut_amm_resp,
    COALESCE(strutt_amm_resp.desc_sett,'''')::varchar desc_sett_strut_amm_resp,
    COALESCE(tipo_finanziamento_class.classif_tipo_fin_code,''''):: varchar code_tipo_finanz,
    COALESCE(tipo_finanziamento_class.classif_tipo_fin_desc,''''):: varchar desc_tipo_finanz,    
    ''''::varchar display_error
from strutt_amm
	FULL join ele_cap 
    	on strutt_amm.categoria_id = ele_cap.classif_id
    left join imp_comp_anno
    	on imp_comp_anno.elem_id = ele_cap.elem_id
    left join imp_comp_anno1
    	on imp_comp_anno1.elem_id = ele_cap.elem_id
    left join imp_comp_anno2
    	on imp_comp_anno2.elem_id = ele_cap.elem_id
    left join imp_residui_anno
    	on imp_residui_anno.elem_id = ele_cap.elem_id
    left join imp_cassa_anno
    	on imp_cassa_anno.elem_id = ele_cap.elem_id
    left join imp_variaz_comp_anno
    	on imp_variaz_comp_anno.elem_id = ele_cap.elem_id
    left join imp_variaz_comp_anno1
    	on imp_variaz_comp_anno1.elem_id = ele_cap.elem_id
    left join imp_variaz_comp_anno2
    	on imp_variaz_comp_anno2.elem_id = ele_cap.elem_id
    left join imp_variaz_residui_anno
    	on imp_variaz_residui_anno.elem_id = ele_cap.elem_id
    left join imp_variaz_cassa_anno
    	on imp_variaz_cassa_anno.elem_id = ele_cap.elem_id
    left join strutt_amm_resp
    	on strutt_amm_resp.elem_id =  ele_cap.elem_id    
    left join tipo_finanziamento_class
    	on tipo_finanziamento_class.elem_id =  ele_cap.elem_id             
where ele_cap.elem_code is not null';

raise notice 'Query: % ', sql_query;
return query execute sql_query;     
    

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
        RTN_MESSAGGIO:='capitolo altro errore';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;