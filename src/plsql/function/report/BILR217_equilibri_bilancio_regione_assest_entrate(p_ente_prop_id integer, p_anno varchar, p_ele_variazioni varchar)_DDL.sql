/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR217_equilibri_bilancio_regione_assest_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar
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
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  codice_pdc varchar,
  display_error varchar
) AS
$body$
DECLARE
classifBilRec record;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
elemTipoCode varchar;
user_table	varchar;
h_count integer :=0;
v_fam_titolotipologiacategoria varchar:='00003';
strApp varchar;
intApp numeric;
x_array VARCHAR [];
id_bil integer;
strQuery varchar;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
elemTipoCode:='CAP-EG'; -- tipo capitolo previsione

bil_anno='';
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
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
codice_pdc='';

--14/12/2020 Funzione rivista per ottimizzare le prestazioni insieme alle modifiche 
--  per la SIAC-7877.
 
--14/12/2020 SIAC-7877 introdotta la gestione delle variazioni.
-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    intApp = strApp::INTEGER;
  END LOOP;
END IF;

select fnc_siac_random_user()
into	user_table;

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

display_error:='';

--14/12/2020 SIAC-7877 introdotta la gestione delle variazioni.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
strQuery:= '
    insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),        
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
        testata_variazione.ente_proprietario_id,
        anno_importi.anno	      	
        from 	siac_r_variazione_stato		r_variazione_stato,
                siac_t_variazione 			testata_variazione,
                siac_d_variazione_tipo		tipologia_variazione,
                siac_d_variazione_stato 	tipologia_stato_var,
                siac_t_bil_elem_det_var 	dettaglio_variazione,
                siac_t_bil_elem				capitolo,
                siac_d_bil_elem_tipo 		tipo_capitolo,
                siac_d_bil_elem_det_tipo	tipo_elemento,
                siac_t_periodo 				anno_eserc ,
                siac_t_bil					t_bil,
                siac_t_periodo 				anno_importi
        where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
        and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
        and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
        and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
        and		dettaglio_variazione.elem_id						=	capitolo.elem_id
        and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
        and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
        and 	t_bil.periodo_id 									=	anno_eserc.periodo_id		
        and 	t_bil.bil_id 										= testata_variazione.bil_id
        and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id	
        and 	testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id ||'
        and		anno_eserc.anno										= 	'''||p_anno||''' 
        and 	testata_variazione.variazione_num 					in ('||p_ele_variazioni||')  
        and		anno_importi.anno				in 	('''||annoCapImp||''','''||annoCapImp1||''','''||annoCapImp2||''')									
        --10/10/2022 SIAC-8827  Aggiunto lo stato BD.
        and		tipologia_stato_var.variazione_stato_tipo_code	in	(''B'',''G'', ''C'', ''P'', ''BD'')
        and		tipo_capitolo.elem_tipo_code						=	'''||elemTipoCode||'''
        and		tipo_elemento.elem_det_tipo_code					in (''STA'',''SCA'',''STR'')
        and		r_variazione_stato.data_cancellazione		is null
        and		testata_variazione.data_cancellazione		is null
        and		tipologia_variazione.data_cancellazione		is null
        and		tipologia_stato_var.data_cancellazione		is null
        and 	dettaglio_variazione.data_cancellazione		is null
        and 	capitolo.data_cancellazione					is null
        and		tipo_capitolo.data_cancellazione			is null
        and		tipo_elemento.data_cancellazione			is null
        and		t_bil.data_cancellazione					is null
        group by 	dettaglio_variazione.elem_id,
                    tipo_elemento.elem_det_tipo_code, 
                    utente,
                    testata_variazione.ente_proprietario_id,
                    anno_importi.anno';                    

	raise notice 'Query variazioni entrate = %', strQuery;
    execute  strQuery;
end if;

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
   pdc_capitolo as (
      select r_capitolo_pdc.elem_id,
           pdc.classif_code pdc_code
      from siac_r_bil_elem_class r_capitolo_pdc,
           siac_t_class pdc,
           siac_d_class_tipo pdc_tipo
      where r_capitolo_pdc.classif_id = pdc.classif_id and
           pdc.classif_tipo_id 		= pdc_tipo.classif_tipo_id and
           r_capitolo_pdc.ente_proprietario_id	=	p_ente_prop_id and 
           pdc_tipo.classif_tipo_code like 'PDC_%'		and
           r_capitolo_pdc.data_cancellazione 			is null and 	
           pdc.data_cancellazione is null 	and
           pdc_tipo.data_cancellazione 	is null), 
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
    variaz_stanz_anno as (
        select a.elem_id, sum(a.importo) importo_stanz
        from siac_rep_var_entrate a
        where a.ente_proprietario= p_ente_prop_id
            and a.utente=user_table
            and a.tipologia = TipoImpComp --STA Competenza
            and a.periodo_anno = annoCapImp
        group by a.elem_id),
    variaz_stanz_anno1 as (
        select a.elem_id, sum(a.importo) importo_stanz1
        from siac_rep_var_entrate a
        where a.ente_proprietario= p_ente_prop_id
            and a.utente=user_table
            and a.tipologia = TipoImpComp --STA Competenza
            and a.periodo_anno = annoCapImp1
        group by a.elem_id),
    variaz_stanz_anno2 as (
        select a.elem_id, sum(a.importo) importo_stanz2
        from siac_rep_var_entrate a
        where a.ente_proprietario= p_ente_prop_id
            and a.utente=user_table
            and a.tipologia = TipoImpComp --STA Competenza
            and a.periodo_anno = annoCapImp2
        group by a.elem_id)                
select capitoli.anno_bilancio::varchar bil_anno,
		''::varchar titoloe_tipo_code,
		strut_bilancio.classif_tipo_desc1::varchar titoloe_tipo_desc,
        strut_bilancio.titolo_code::varchar titoloe_code,
        strut_bilancio.titolo_desc::varchar titoloe_desc,
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
  --14/12/2020 SIAC-7877 introdotta la gestione delle variazioni.
        (COALESCE(imp_comp_anno.importo,0) +
         COALESCE(variaz_stanz_anno.importo_stanz,0))::numeric stanziamento_prev_anno,
        (COALESCE(imp_comp_anno1.importo,0) +
         COALESCE(variaz_stanz_anno1.importo_stanz1,0))::numeric stanziamento_prev_anno1,
        (COALESCE(imp_comp_anno2.importo,0) +
    	 COALESCE(variaz_stanz_anno2.importo_stanz2,0))::numeric stanziamento_prev_anno2,
        pdc_capitolo.pdc_code::varchar codice_pdc,
        ''::varchar display_error
from strut_bilancio
	LEFT JOIN capitoli on capitoli.categoria_id = strut_bilancio.categoria_id  
    LEFT JOIN pdc_capitolo on capitoli.elem_id = pdc_capitolo.elem_id  
    LEFT JOIN imp_comp_anno on capitoli.elem_id = imp_comp_anno.elem_id
    LEFT JOIN imp_comp_anno1 on capitoli.elem_id = imp_comp_anno1.elem_id
    LEFT JOIN imp_comp_anno2 on capitoli.elem_id = imp_comp_anno2.elem_id
    LEFT JOIN variaz_stanz_anno on capitoli.elem_id = variaz_stanz_anno.elem_id
    LEFT JOIN variaz_stanz_anno1 on capitoli.elem_id = variaz_stanz_anno1.elem_id
    LEFT JOIN variaz_stanz_anno2 on capitoli.elem_id = variaz_stanz_anno2.elem_id;                               
            
delete from siac_rep_var_entrate where utente=user_table;

raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;     
	when others  THEN
        RTN_MESSAGGIO:='Ricerca dati capitolo';
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

ALTER FUNCTION siac."BILR217_equilibri_bilancio_regione_assest_entrate" (p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar)
  OWNER TO siac;