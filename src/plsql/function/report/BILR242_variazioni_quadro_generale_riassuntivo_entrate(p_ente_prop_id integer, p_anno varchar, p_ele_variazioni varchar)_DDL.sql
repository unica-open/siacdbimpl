/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR242_variazioni_quadro_generale_riassuntivo_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titent_tipo_code varchar,
  titent_tipo_desc varchar,
  titent_code varchar,
  titent_desc varchar,
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
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  display_error varchar
) AS
$body$
DECLARE

classifBilRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
TipoImpresidui varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
titoloe_tipo_code varchar;
titoloe_TIPO_DESC varchar;
titoloe_CODE varchar;
titoloe_DESC varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
strApp VARCHAR;
intApp INTEGER;
x_array VARCHAR [];
sql_query VARCHAR;
v_fam_titolotipologiacategoria varchar:='00003';

contaParVarPeg integer;
contaParVarBil integer;
id_bil integer;

BEGIN

/*
	16/12/2020. 
    Funzione nata per la SIAC-7875 per il nuovo report BILR242
    "Variazioni - Quadro Generale Riassuntivo".
    La funzione estrae gli stessi dati della "BILR112_Allegato_9_bill_gest_quadr_riass_gen_entrate"
    ma e' stata rivista per ragioni prestazionali.
    La differenza fra le 2 funzioni e' che questa estrae solo gli importi delle variazioni
    indicate in input, NON sono considerati gli importi dei capitoli.    
*/

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpresidui='STR'; -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
TipoImpCassa ='SCA'; ----- previsioni di cassa
elemTipoCode:='CAP-EG'; -- tipo capitolo previsione
contaParVarPeg:=0;
contaParVarBil:=0;

bil_anno='';
titent_tipo_code='';
titent_tipo_desc='';
titent_code='';
titent_desc='';
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
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
stanziamento_prev_cassa_anno:=0;


display_error='';

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    intApp = strApp::INTEGER;
  END LOOP;

END IF;

select t_bil.bil_id
	into id_bil
from siac_t_bil t_bil,
	siac_t_periodo t_periodo
where t_bil.periodo_id=t_periodo.periodo_id
	and t_bil.ente_proprietario_id = p_ente_prop_id
    and t_periodo.anno= p_anno    
    and t_bil.data_cancellazione IS NULL
    and t_periodo.data_cancellazione IS NULL;
IF NOT FOUND THEN
	raise notice 'Codice del bilancio non trovato';
    return;
END IF;

    
select fnc_siac_random_user()
into	user_table;
 	
-- carico su tabella di appoggio i dati delle variazioni
sql_query='
    insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
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
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio          
     where r_variazione_stato.variazione_id	=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id 	   
    and	testata_variazione.ente_proprietario_id	= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    --10/10/2022 SIAC-8827  Aggiunto lo stato BD.
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'', ''BD'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') 
    and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';

    sql_query=sql_query||' and	r_variazione_stato.data_cancellazione	is null
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
         
raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;

return query
	with strut_bilancio as(
     		select  *
            from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno,'')),
    capitoli as(
    	select 	cl.classif_id categoria_id,
                p_anno anno_bilancio,
                e.*
		from 	siac_r_bil_elem_class rc, 
            siac_t_bil_elem e, 
            siac_d_class_tipo ct,
            siac_t_class cl,
            siac_d_bil_elem_tipo tipo_elemento,          
            siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
            siac_d_bil_elem_categoria cat_del_capitolo,
            siac_r_bil_elem_categoria r_cat_capitolo
        where ct.classif_tipo_id=cl.classif_tipo_id
        and cl.classif_id=rc.classif_id 
        and e.elem_tipo_id=tipo_elemento.elem_tipo_id 
        and e.elem_id=rc.elem_id        
        and	e.elem_id						=	r_capitolo_stato.elem_id
        and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
        and	e.elem_id						=	r_cat_capitolo.elem_id
        and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
        and e.ente_proprietario_id=p_ente_prop_id
        and e.bil_id= id_bil
        and ct.classif_tipo_code='CATEGORIA'
        and tipo_elemento.elem_tipo_code = elemTipoCode
        and	stato_capitolo.elem_stato_code	=	'VA'
        and	cat_del_capitolo.elem_cat_code	=	'STD'
        and e.data_cancellazione 				is null
        and	r_capitolo_stato.data_cancellazione	is null
        and	r_cat_capitolo.data_cancellazione	is null
        and	rc.data_cancellazione				is null
        and	ct.data_cancellazione 				is null
        and	cl.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione	is null
        and	stato_capitolo.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione	is null
        and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
        and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
        and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
        and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
        and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())),   
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
                    siac_d_bil_elem_stato stato_capitolo, 
                    siac_r_bil_elem_stato r_capitolo_stato,
                    siac_d_bil_elem_categoria cat_del_capitolo, 
                    siac_r_bil_elem_categoria r_cat_capitolo
            where 	capitolo.elem_id					=	capitolo_importi.elem_id 
                and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
                and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
                and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
                and	capitolo.elem_id					=	r_capitolo_stato.elem_id
                and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
                and	capitolo.elem_id					=	r_cat_capitolo.elem_id
                and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
                and capitolo.bil_id 					= id_bil
                and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
                and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
                and	stato_capitolo.elem_stato_code		=	'VA'
                and	capitolo_imp_periodo.anno = annoCapImp
                and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
                and	cat_del_capitolo.elem_cat_code	in ('STD')
                and	capitolo_importi.data_cancellazione 	is null
                and	capitolo_imp_tipo.data_cancellazione 	is null
                and	capitolo_imp_periodo.data_cancellazione is null
                and	capitolo.data_cancellazione 			is null
                and	tipo_elemento.data_cancellazione 		is null
                and	stato_capitolo.data_cancellazione 		is null
                and	r_capitolo_stato.data_cancellazione 	is null
                and	cat_del_capitolo.data_cancellazione 	is null
                and	r_cat_capitolo.data_cancellazione 		is null
                and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
                and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
                and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
                and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
                and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
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
                    siac_d_bil_elem_stato stato_capitolo, 
                    siac_r_bil_elem_stato r_capitolo_stato,
                    siac_d_bil_elem_categoria cat_del_capitolo, 
                    siac_r_bil_elem_categoria r_cat_capitolo
            where 	capitolo.elem_id					=	capitolo_importi.elem_id 
                and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
                and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
                and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
                and	capitolo.elem_id					=	r_capitolo_stato.elem_id
                and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
                and	capitolo.elem_id					=	r_cat_capitolo.elem_id
                and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
                and capitolo.bil_id 					= id_bil
                and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
                and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
                and	stato_capitolo.elem_stato_code		=	'VA'
                and	capitolo_imp_periodo.anno = annoCapImp1
                and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
                and	cat_del_capitolo.elem_cat_code	in ('STD')
                and	capitolo_importi.data_cancellazione 	is null
                and	capitolo_imp_tipo.data_cancellazione 	is null
                and	capitolo_imp_periodo.data_cancellazione is null
                and	capitolo.data_cancellazione 			is null
                and	tipo_elemento.data_cancellazione 		is null
                and	stato_capitolo.data_cancellazione 		is null
                and	r_capitolo_stato.data_cancellazione 	is null
                and	cat_del_capitolo.data_cancellazione 	is null
                and	r_cat_capitolo.data_cancellazione 		is null
                and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
                and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
                and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
                and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
                and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
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
                    siac_d_bil_elem_stato stato_capitolo, 
                    siac_r_bil_elem_stato r_capitolo_stato,
                    siac_d_bil_elem_categoria cat_del_capitolo, 
                    siac_r_bil_elem_categoria r_cat_capitolo
            where 	capitolo.elem_id					=	capitolo_importi.elem_id 
                and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
                and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
                and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
                and	capitolo.elem_id					=	r_capitolo_stato.elem_id
                and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
                and	capitolo.elem_id					=	r_cat_capitolo.elem_id
                and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
                and capitolo.bil_id 					= id_bil
                and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
                and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
                and	stato_capitolo.elem_stato_code		=	'VA'
                and	capitolo_imp_periodo.anno = annoCapImp2
                and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
                and	cat_del_capitolo.elem_cat_code	in ('STD')
                and	capitolo_importi.data_cancellazione 	is null
                and	capitolo_imp_tipo.data_cancellazione 	is null
                and	capitolo_imp_periodo.data_cancellazione is null
                and	capitolo.data_cancellazione 			is null
                and	tipo_elemento.data_cancellazione 		is null
                and	stato_capitolo.data_cancellazione 		is null
                and	r_capitolo_stato.data_cancellazione 	is null
                and	cat_del_capitolo.data_cancellazione 	is null
                and	r_cat_capitolo.data_cancellazione 		is null
                and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
                and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
                and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
                and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
                and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
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
                    siac_d_bil_elem_stato stato_capitolo, 
                    siac_r_bil_elem_stato r_capitolo_stato,
                    siac_d_bil_elem_categoria cat_del_capitolo, 
                    siac_r_bil_elem_categoria r_cat_capitolo
            where 	capitolo.elem_id					=	capitolo_importi.elem_id 
                and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
                and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
                and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
                and	capitolo.elem_id					=	r_capitolo_stato.elem_id
                and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
                and	capitolo.elem_id					=	r_cat_capitolo.elem_id
                and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
                and capitolo.bil_id 					= id_bil
                and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
                and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
                and	stato_capitolo.elem_stato_code		=	'VA'
                and	capitolo_imp_periodo.anno = annoCapImp
                and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpCassa --'SCA
                and	cat_del_capitolo.elem_cat_code	in ('STD')
                and	capitolo_importi.data_cancellazione 	is null
                and	capitolo_imp_tipo.data_cancellazione 	is null
                and	capitolo_imp_periodo.data_cancellazione is null
                and	capitolo.data_cancellazione 			is null
                and	tipo_elemento.data_cancellazione 		is null
                and	stato_capitolo.data_cancellazione 		is null
                and	r_capitolo_stato.data_cancellazione 	is null
                and	cat_del_capitolo.data_cancellazione 	is null
                and	r_cat_capitolo.data_cancellazione 		is null
                and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
                and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
                and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
                and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
                and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
                and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
                and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
                and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
                and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
                group by capitolo_importi.elem_id,
                capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
    variaz_stanz_anno_pos as (
        select a.elem_id, sum(a.importo) importo_stanz
        from siac_rep_var_entrate a
        where a.ente_proprietario= p_ente_prop_id
            and a.utente=user_table
            and a.tipologia = TipoImpComp --STA Competenza
            and a.periodo_anno = annoCapImp
            and a.importo >= 0
        group by a.elem_id),
	variaz_stanz_anno_neg as (
        select a.elem_id, sum(a.importo) importo_stanz
        from siac_rep_var_entrate a
        where a.ente_proprietario= p_ente_prop_id
            and a.utente=user_table
            and a.tipologia = TipoImpComp --STA Competenza
            and a.periodo_anno = annoCapImp
            and a.importo < 0
        group by a.elem_id),        
    variaz_stanz_anno1_pos as (
        select a.elem_id, sum(a.importo) importo_stanz1
        from siac_rep_var_entrate a
        where a.ente_proprietario= p_ente_prop_id
            and a.utente=user_table
            and a.tipologia = TipoImpComp --STA Competenza
            and a.periodo_anno = annoCapImp1
            and a.importo >= 0
        group by a.elem_id),
    variaz_stanz_anno1_neg as (
        select a.elem_id, sum(a.importo) importo_stanz1
        from siac_rep_var_entrate a
        where a.ente_proprietario= p_ente_prop_id
            and a.utente=user_table
            and a.tipologia = TipoImpComp --STA Competenza
            and a.periodo_anno = annoCapImp1
            and a.importo < 0
        group by a.elem_id),
    variaz_stanz_anno2_pos as (
        select a.elem_id, sum(a.importo) importo_stanz2
        from siac_rep_var_entrate a
        where a.ente_proprietario= p_ente_prop_id
            and a.utente=user_table
            and a.tipologia = TipoImpComp --STA Competenza
            and a.periodo_anno = annoCapImp2
            and a.importo >= 0
        group by a.elem_id),  
    variaz_stanz_anno2_neg as (
        select a.elem_id, sum(a.importo) importo_stanz2
        from siac_rep_var_entrate a
        where a.ente_proprietario= p_ente_prop_id
            and a.utente=user_table
            and a.tipologia = TipoImpComp --STA Competenza
            and a.periodo_anno = annoCapImp2
            and a.importo < 0
        group by a.elem_id),
	variaz_cassa_anno_pos as (
        select a.elem_id, sum(a.importo) importo_cassa
        from siac_rep_var_entrate a
        where a.ente_proprietario= p_ente_prop_id
            and a.utente=user_table
            and a.tipologia = TipoImpCassa --SCA Cassa
            and a.periodo_anno = annoCapImp
            and a.importo >= 0
        group by a.elem_id),
	variaz_cassa_anno_neg as (
        select a.elem_id, sum(a.importo) importo_cassa
        from siac_rep_var_entrate a
        where a.ente_proprietario= p_ente_prop_id
            and a.utente=user_table
            and a.tipologia = TipoImpCassa --SCA Cassa
            and a.periodo_anno = annoCapImp
            and a.importo < 0
        group by a.elem_id)                          
select capitoli.anno_bilancio::varchar bil_anno,
		''::varchar titent_tipo_code,
		strut_bilancio.classif_tipo_desc1::varchar titent_tipo_desc,
        strut_bilancio.titolo_code::varchar titent_code,
        strut_bilancio.titolo_desc::varchar titent_desc,
        ''::varchar tipologia_tipo_code,
        strut_bilancio.classif_tipo_desc2::varchar tipologia_tipo_desc,
        strut_bilancio.tipologia_code::varchar tipologia_code,
        strut_bilancio.tipologia_desc::varchar tipologia_desc,
        ''::varchar categoria_tipo_code,
        strut_bilancio.classif_tipo_desc3::varchar categoria_tipo_desc,
        strut_bilancio.categoria_code::varchar categoria_code,
        strut_bilancio.categoria_desc::varchar categoria_desc,
        capitoli.elem_code::varchar bil_ele_code,
        capitoli.elem_desc::varchar bil_ele_desc,
        capitoli.elem_code2::varchar bil_ele_code2,
        capitoli.elem_desc2::varchar bil_ele_desc2,
        capitoli.elem_id::integer bil_ele_id,
        capitoli.elem_id_padre::integer bil_ele_id_padre,
        -- gli importi sono relativi solo alle variazioni
        (COALESCE(variaz_cassa_anno_pos.importo_cassa,0) +
         COALESCE(variaz_cassa_anno_neg.importo_cassa,0))::numeric stanziamento_prev_cassa_anno,
        (COALESCE(variaz_stanz_anno_pos.importo_stanz,0) +
         COALESCE(variaz_stanz_anno_neg.importo_stanz,0))::numeric stanziamento_prev_anno,
        (COALESCE(variaz_stanz_anno1_pos.importo_stanz1,0) +
         COALESCE(variaz_stanz_anno1_neg.importo_stanz1,0))::numeric stanziamento_prev_anno1,
        (COALESCE(variaz_stanz_anno2_pos.importo_stanz2,0) +
    	 COALESCE(variaz_stanz_anno2_neg.importo_stanz2,0))::numeric stanziamento_prev_anno2,
        ''::varchar display_error
from strut_bilancio
	LEFT JOIN capitoli on capitoli.categoria_id = strut_bilancio.categoria_id  
    LEFT JOIN imp_comp_anno on capitoli.elem_id = imp_comp_anno.elem_id
    LEFT JOIN imp_comp_anno1 on capitoli.elem_id = imp_comp_anno1.elem_id
    LEFT JOIN imp_comp_anno2 on capitoli.elem_id = imp_comp_anno2.elem_id
    LEFT JOIN imp_cassa_anno on capitoli.elem_id = imp_cassa_anno.elem_id    
    LEFT JOIN variaz_stanz_anno_pos on capitoli.elem_id = variaz_stanz_anno_pos.elem_id
    LEFT JOIN variaz_stanz_anno_neg on capitoli.elem_id = variaz_stanz_anno_neg.elem_id
    LEFT JOIN variaz_stanz_anno1_pos on capitoli.elem_id = variaz_stanz_anno1_pos.elem_id
    LEFT JOIN variaz_stanz_anno1_neg on capitoli.elem_id = variaz_stanz_anno1_neg.elem_id
    LEFT JOIN variaz_stanz_anno2_pos on capitoli.elem_id = variaz_stanz_anno2_pos.elem_id
    LEFT JOIN variaz_stanz_anno2_neg on capitoli.elem_id = variaz_stanz_anno2_neg.elem_id
    LEFT JOIN variaz_cassa_anno_pos on capitoli.elem_id = variaz_cassa_anno_pos.elem_id
    LEFT JOIN variaz_cassa_anno_neg on capitoli.elem_id = variaz_cassa_anno_neg.elem_id;                               
            
delete from siac_rep_var_entrate where utente=user_table;


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
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR242_variazioni_quadro_generale_riassuntivo_entrate" (p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar)
  OWNER TO siac;