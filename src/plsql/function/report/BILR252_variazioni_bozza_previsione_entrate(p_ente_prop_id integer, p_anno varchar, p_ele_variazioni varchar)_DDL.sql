/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR252_variazioni_bozza_previsione_entrate" (
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
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  residui_presunti numeric,
  previsioni_anno_prec numeric,
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




BEGIN

/*
	20/05/2021. SIAC-8000.
    La funzione nasce come copia della BILR236_entrate_riepilogo_titoli_tipologie ma
    gestisce i dati della PREVISIONE.
    E' stata rivista per renderla piu' veloce.
*/    

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;  

TipoImpComp='STA';  -- competenza
TipoImpresidui='STR'; -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
TipoImpCassa ='SCA'; ----- previsioni di cassa
elemTipoCode:='CAP-EP'; -- tipo capitolo previsione

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
residui_presunti:=0;
previsioni_anno_prec:=0;
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

select fnc_siac_random_user()
into	user_table;

--uso una tabella di appoggio per le varizioni perche' la query e' di tipo dinamico
--in quanto il parametro con l'elenco delle variazioni e' variabile.
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
            siac_t_bil                  bilancio  ';          
       
    sql_query=sql_query||' where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
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
  
    sql_query=sql_query || ' and testata_variazione.ente_proprietario_id	=  ' || p_ente_prop_id ||'     
    and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code != ''A''              --SIAC-7244   in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';

    sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
       
    sql_query=sql_query||'
    and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
    
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	    

raise notice 'Query variazioni: % ',  sql_query;      
EXECUTE sql_query;                
         
sql_query:='
insert into siac_rep_cap_ep
select cl.classif_id,
    anno_eserc.anno anno_bilancio,
    e.*, '''||user_table||''' utente
   from 	siac_r_bil_elem_class rc,
          siac_t_bil_elem e,
          siac_d_class_tipo ct,
          siac_t_class cl,
          siac_t_bil bilancio,
          siac_t_periodo anno_eserc,
          siac_d_bil_elem_tipo tipo_elemento, 
          siac_d_bil_elem_stato stato_capitolo,
          siac_r_bil_elem_stato r_capitolo_stato,
          siac_d_bil_elem_categoria cat_del_capitolo,
          siac_r_bil_elem_categoria r_cat_capitolo
  where ct.classif_tipo_id				=	cl.classif_tipo_id
  and cl.classif_id					=	rc.classif_id 
  and bilancio.periodo_id				=	anno_eserc.periodo_id 
  and e.bil_id						=	bilancio.bil_id 
  and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
  and e.elem_id						=	rc.elem_id 
  and	e.elem_id						=	r_capitolo_stato.elem_id
  and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
  and	e.elem_id						=	r_cat_capitolo.elem_id
  and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
  and e.ente_proprietario_id='||p_ente_prop_id||
  'and anno_eserc.anno					= 	'''||p_anno||'''
  and ct.classif_tipo_code			=	''CATEGORIA''
  and tipo_elemento.elem_tipo_code 	= 	'''||elemTipoCode||'''
  and	stato_capitolo.elem_stato_code	=	''VA''
  and e.data_cancellazione 				is null
  and	r_capitolo_stato.data_cancellazione	is null
  and	r_cat_capitolo.data_cancellazione	is null
  and	rc.data_cancellazione				is null
  and	ct.data_cancellazione 				is null
  and	cl.data_cancellazione 				is null
  and	bilancio.data_cancellazione 		is null
  and	anno_eserc.data_cancellazione 		is null
  and	tipo_elemento.data_cancellazione	is null
  and	stato_capitolo.data_cancellazione 	is null
  and	cat_del_capitolo.data_cancellazione	is null
  and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
  and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
  and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
  and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
  and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
  and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
  and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
  and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
  and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
  and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
  and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())';
  
raise notice 'Query1 capitoli: % ',  sql_query;      
EXECUTE sql_query; 

--carico anche i capitoli su una tabella di appoggio 
sql_query:='
insert into siac_rep_cap_ep             
with prec as (       
select * From siac_t_cap_e_importi_anno_prec a
where a.anno='''||annoPrec||'''       
and a.ente_proprietario_id='||p_ente_prop_id||'), 
categ as (
select * from siac_t_class a, siac_d_class_tipo b
where a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code = ''CATEGORIA''
and a.data_cancellazione is null
and b.data_cancellazione is null
and a.ente_proprietario_id='||p_ente_prop_id||'
and to_timestamp(''01/01/'||annoPrec||''',''dd/mm/yyyy'') between
a.validita_inizio and COALESCE(a.validita_fine, to_timestamp(''31/12/'||annoPrec||''',''dd/mm/yyyy''))
)  
select categ.classif_id classif_id_categ,  '||p_anno||',
NULL, prec.elem_code, prec.elem_code2,
       prec.elem_code3, NULL, NULL,  NULL, NULL, NULL, NULL, NULL,NULL,NULL,
        prec.ente_proprietario_id, prec.data_creazione, prec.data_modifica,
        prec.data_cancellazione,prec.login_operazione, '''||user_table||''' utente
 from prec
join categ on prec.categoria_code=categ.classif_code
and not exists (select 1 from siac_rep_cap_ep ep
                      where ep.elem_code=prec.elem_code
                        AND ep.elem_code2=prec.elem_code2
                        and ep.elem_code3=prec.elem_code3
                        and ep.classif_id = categ.classif_id
                        and ep.utente='''||user_table||'''
                        and ep.ente_proprietario_id='||p_ente_prop_id||')'; 
raise notice 'Query2 capitoli: % ',  sql_query;                          
EXECUTE sql_query; 
                        
return query
with struttura as (
	select * from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno,user_table)),
capitoli as (select *
			from siac_rep_cap_ep a
            where a.ente_proprietario_id=p_ente_prop_id
            	and utente = user_table),
	variaz_stanz_anno as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_entrate variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('STD')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_stanz_anno1 as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_entrate variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp1
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('STD')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_stanz_anno2 as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_entrate variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp2
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('STD')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_cassa_anno as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_entrate variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp
                and variaz.tipologia = TipoImpCassa  --'SCA' -- cassa
                and d_bil_elem_categ.elem_cat_code in ('STD')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id )  ,
    variaz_residui_anno as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_entrate variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp
                and variaz.tipologia = TipoImpresidui --'STR'  residui
                and d_bil_elem_categ.elem_cat_code in ('STD')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id )  
select
  capitoli.anno_bilancio::varchar bil_anno,
  ''::varchar titoloe_tipo_code,
  struttura.classif_tipo_desc1::varchar titoloe_tipo_desc,
  struttura.titolo_code:: varchar titoloe_code,
  struttura.titolo_desc:: varchar titoloe_desc,
  ''::varchar tipologia_tipo_code,
  struttura.classif_tipo_desc2::varchar tipologia_tipo_desc,
  struttura.tipologia_code::varchar tipologia_code,
  struttura.tipologia_desc::varchar tipologia_desc,
  ''::varchar categoria_tipo_code,
  struttura.classif_tipo_desc3::varchar categoria_tipo_desc,
  struttura.categoria_code::varchar categoria_code,
  struttura.categoria_desc::varchar categoria_desc,
  capitoli.elem_code::varchar bil_ele_code,
  capitoli.elem_desc::varchar bil_ele_desc,
  capitoli.elem_code2::varchar bil_ele_code2,
  capitoli.elem_desc2::varchar bil_ele_desc2,
  capitoli.elem_id::integer bil_ele_id,
  capitoli.elem_id_padre::integer bil_ele_id_padre,
  COALESCE(variaz_cassa_anno.importo_variaz,0)::numeric stanziamento_prev_cassa_anno,
  COALESCE(variaz_stanz_anno.importo_variaz,0)::numeric stanziamento_prev_anno,
  COALESCE(variaz_stanz_anno1.importo_variaz,0)::numeric stanziamento_prev_anno1,
  COALESCE(variaz_stanz_anno2.importo_variaz,0)::numeric stanziamento_prev_anno2,
  COALESCE(variaz_residui_anno.importo_variaz,0)::numeric residui_presunti,  
  0::numeric previsioni_anno_prec,
  ''::varchar display_error  
from struttura 
	left join capitoli
    	on struttura.categoria_id = capitoli.classif_id
    left join variaz_stanz_anno
      on variaz_stanz_anno.elem_id = capitoli.elem_id
    left join variaz_stanz_anno1
      on variaz_stanz_anno1.elem_id = capitoli.elem_id
    left join variaz_stanz_anno2
      on variaz_stanz_anno2.elem_id = capitoli.elem_id 
    left join variaz_cassa_anno
      on variaz_cassa_anno.elem_id = capitoli.elem_id    
    left join variaz_residui_anno
      on variaz_residui_anno.elem_id = capitoli.elem_id;



delete from siac_rep_var_entrate where utente=user_table;
delete from siac_rep_cap_ep where utente=user_table;

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