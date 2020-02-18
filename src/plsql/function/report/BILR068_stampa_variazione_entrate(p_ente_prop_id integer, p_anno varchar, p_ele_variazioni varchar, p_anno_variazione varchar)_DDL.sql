/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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
sql_query varchar;

BEGIN

annoCapImp:= p_anno; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-EG'; -- tipo capitolo gestione

-- se ?? presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 --intApp= strApp ::numeric/ 1;
 intApp = strApp::numeric;
END IF;

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
ente_denominazione ='';
display_error='';
flag_visualizzazione = -111;

select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_tit_tip_cat_riga_anni''.';  



/* carico la struttura di bilancio completa */
with titent as 
(select 
e.classif_tipo_desc titent_tipo_desc,
a.classif_id titent_id,
a.classif_code titent_code,
a.classif_desc titent_desc,
a.validita_inizio titent_validita_inizio,
a.validita_fine titent_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
tipologia as
(
select 
e.classif_tipo_desc tipologia_tipo_desc,
b.classif_id_padre titent_id,
a.classif_id tipologia_id,
a.classif_code tipologia_code,
a.classif_desc tipologia_desc,
a.validita_inizio tipologia_validita_inizio,
a.validita_fine tipologia_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=2
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
categoria as (
select 
e.classif_tipo_desc categoria_tipo_desc,
b.classif_id_padre tipologia_id,
a.classif_id categoria_id,
a.classif_code categoria_code,
a.classif_desc categoria_desc,
a.validita_inizio categoria_validita_inizio,
a.validita_fine categoria_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=3
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into  siac_rep_tit_tip_cat_riga_anni
select 
titent.titent_tipo_desc,
titent.titent_id,
titent.titent_code,
titent.titent_desc,
titent.titent_validita_inizio,
titent.titent_validita_fine,
tipologia.tipologia_tipo_desc,
tipologia.tipologia_id,
tipologia.tipologia_code,
tipologia.tipologia_desc,
tipologia.tipologia_validita_inizio,
tipologia.tipologia_validita_fine,
categoria.categoria_tipo_desc,
categoria.categoria_id,
categoria.categoria_code,
categoria.categoria_desc,
categoria.categoria_validita_inizio,
categoria.categoria_validita_fine,
categoria.ente_proprietario_id,
user_table
 from titent,tipologia,categoria
where 
titent.titent_id=tipologia.titent_id
 and tipologia.tipologia_id=categoria.tipologia_id
 order by 
 titent.titent_code, tipologia.tipologia_code,categoria.categoria_code ;

 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep''.';  

insert into siac_rep_cap_eg
select cl.classif_id,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
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
where ct.classif_tipo_code			=	'CATEGORIA'
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
-- INC000001570761 and	stato_capitolo.elem_stato_code	=	'VA'
and	stato_capitolo.elem_stato_code	in ('VA', 'PR')
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
--and	cat_del_capitolo.elem_cat_code	=	'STD'
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
and	cat_del_capitolo.data_cancellazione	is null;


insert into siac_rep_cap_eg
select null,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	
 		siac_t_bil_elem e,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato
where e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
-- INC000001570761 and	stato_capitolo.elem_stato_code	=	'VA'
and	stato_capitolo.elem_stato_code	in ('VA', 'PR')
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and not EXISTS
(
   select 1 from siac_rep_cap_eg x
   where x.elem_id = e.elem_id
   and x.utente=user_table
);




 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep_imp''.';  

/* 18/05/2016: introdotta modifica all'estrazione degli importi dei capitoli.
	Si deve tener conto di eventuali variazioni successive e decrementare 
    l'importo del capitolo.
*/

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
       -- and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		-- INC000001570761 and	stato_capitolo.elem_stato_code	=	'VA'
		and	stato_capitolo.elem_stato_code	in ('VA', 'PR')
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		--and	cat_del_capitolo.elem_cat_code		=	'STD'
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

     RTN_MESSAGGIO:='preparazione tabella importi riga capitolo ''.';  


insert into siac_rep_cap_eg_imp_riga
select  tb1.elem_id,
		tb4.importo		as		residui_attivi,
        tb1.importo 	as 		previsioni_definitive_comp,
        tb2.importo		as		previsioni_definitive_cassa,
        tb1.ente_proprietario,
        user_table utente,
        tb1.periodo_anno
from   
	siac_rep_cap_eg_imp tb1, siac_rep_cap_eg_imp tb2, siac_rep_cap_eg_imp tb4
	where			tb1.elem_id	=	tb2.elem_id	 								and
    				tb1.elem_id	=	tb4.elem_id	 								and												
        			--tb1.periodo_anno 	= annoCapImp		AND	
                    tb1.tipo_imp =	tipoImpComp		        and  
        			tb2.periodo_anno	= tb1.periodo_anno	AND	
                    tb2.tipo_imp = 	tipoImpCassa	        and
                    tb4.periodo_anno	= tb1.periodo_anno	AND	
                    tb4.tipo_imp = 	tipoImpRes		        and
                    tb1.ente_proprietario =	p_ente_prop_id						and
                  	tb2.ente_proprietario	=	tb1.ente_proprietario			and
                    tb4.ente_proprietario	=	tb1.ente_proprietario			and
                    tb1.utente				=	user_table						and
                    tb2.utente				=	tb1.utente						and
                    tb4.utente				=	tb1.utente;
                  
     RTN_MESSAGGIO:='preparazione tabella variazioni''.';  

/*
insert into siac_rep_var_entrate
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        ------dettaglio_variazione.elem_det_importo,
        tipo_elemento.elem_det_tipo_code, 
        user_table utente,
        atto.ente_proprietario_id	,
        anno_importo.anno	      	
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
        siac_t_periodo 				anno_eserc ,
        siac_t_periodo              anno_importo,
        siac_t_bil                  bilancio  
where 	atto.ente_proprietario_id 							= 	p_ente_prop_id
--and testata_variazione.variazione_num in 
--and		atto.attoamm_numero 								= 	p_numero_delibera
--and		atto.attoamm_anno									=	p_anno_delibera
and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
---------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera-----------   deve essere un parametro di input 
--------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
and		r_atto_stato.attoamm_id								=	atto.attoamm_id
and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
--and		stato_atto.attoamm_stato_code						=	'DEFINITIVO'
and		r_variazione_stato.attoamm_id						=	atto.attoamm_id
and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
and		anno_eserc.anno										= 	p_anno 												
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id   
-- 15/06/2016: cambiati i tipi di variazione. Aggiunto 'AS'.
--and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF')
-- 19/07/2016: tolto il test sul tipo di variazione: accettate tutte.
--and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF', 'AS')
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		tipologia_stato_var.variazione_stato_tipo_code		 in	('B','G', 'C', 'P')
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and		tipo_elemento.elem_det_tipo_code					in ('STA','SCA','STR')
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
group by 	dettaglio_variazione.elem_id,
        	tipo_elemento.elem_det_tipo_code, 
        	utente,
        	atto.ente_proprietario_id,
            anno_importo.anno	  ;*/

sql_query='insert into siac_rep_var_entrate
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),        
        tipo_elemento.elem_det_tipo_code, '''; 
sql_query=sql_query ||user_table||''' utente, 
        testata_variazione.ente_proprietario_id	,
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
where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id 
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id  
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id ';
sql_query=sql_query ||' and		tipo_capitolo.elem_tipo_code =	'''||elemTipoCode||'''';
sql_query=sql_query ||' and 	testata_variazione.ente_proprietario_id 	= 	'||p_ente_prop_id;
sql_query=sql_query ||' and		anno_eserc.anno					= 	'''||p_anno||''''; 												
sql_query=sql_query ||' and 	testata_variazione.variazione_num in ('||p_ele_variazioni||') ';  
sql_query=sql_query ||' and		tipologia_stato_var.variazione_stato_tipo_code		 in	(''B'',''G'', ''C'', ''P'')
and		tipo_elemento.elem_det_tipo_code					in (''STA'',''SCA'',''STR'')
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
            anno_importo.anno'  ;    
            
raise notice 'sql_query = %',sql_query;
                    
EXECUTE sql_query;

    
     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

insert into siac_rep_var_entrate_riga
select  tb0.elem_id,    
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo >= 0	
        and tb1.periodo_anno=p_anno
        and tb1.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo <= 0	
        and tb2.periodo_anno=p_anno
        and tb2.utente = tb0.utente )
    left join siac_rep_var_entrate tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo >= 0	
        and tb3.periodo_anno=p_anno
        and tb3.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo <= 0	
        and tb4.periodo_anno=p_anno
        and tb4.utente = tb0.utente )
    left join siac_rep_var_entrate tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo >= 0	
        and tb5.periodo_anno=p_anno
        and tb5.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo <= 0
        and tb6.periodo_anno=p_anno
        and tb6.utente = tb0.utente 	)
  union 
     select  tb0.elem_id,     
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        (p_anno::INTEGER + 1)::varchar from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo >= 0	
        and tb1.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb1.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo <= 0	
        and tb2.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb2.utente = tb0.utente )
    left join siac_rep_var_entrate tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo >= 0	
        and tb3.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb3.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo <= 0	
        and tb4.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb4.utente = tb0.utente )
    left join siac_rep_var_entrate tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo >= 0	
        and tb5.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb5.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo <= 0
        and tb6.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb6.utente = tb0.utente 	)
    union 
    select  tb0.elem_id,     
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        (p_anno::INTEGER + 2)::varchar	from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo >= 0	
        and tb1.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb1.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo <= 0	
        and tb2.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb2.utente = tb0.utente )
    left join siac_rep_var_entrate tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo >= 0	
        and tb3.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb3.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo <= 0	
        and tb4.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb4.utente = tb0.utente )
    left join siac_rep_var_entrate tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo >= 0	
        and tb5.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb5.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo <= 0
        and tb6.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb6.utente = tb0.utente 	);


        
     RTN_MESSAGGIO:='preparazione file output ''.';          
  
/* 20/05/2016: aggiunto il controllo se il capitolo ha subito delle variazioni, tramite
	il test su siac_rep_var_entrate_riga x, siac_rep_cap_eg y, siac_r_class_fam_tree z
*/
for classifBilRec in
select 	t_ente.ente_denominazione 		ente_denominazione,
		v1.classif_tipo_desc1    		titoloe_TIPO_DESC,
       	v1.titolo_id              		titoloe_ID,
       	v1.titolo_code             		titoloe_CODE,
       	v1.titolo_desc             		titoloe_DESC,
       	v1.classif_tipo_desc2  			tipologia_TIPO_DESC,
       	v1.tipologia_id              	tipologia_ID,
       	v1.tipologia_code            	tipologia_CODE,
       	v1.tipologia_desc            	tipologia_DESC,
       	v1.classif_tipo_desc3     		categoria_TIPO_DESC,
      	v1.categoria_id              	categoria_ID,
       	v1.categoria_code            	categoria_CODE,
       	v1.categoria_desc            	categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_attivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)		variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)			variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
        tb1.periodo_anno  anno_riferimento
           ,COALESCE (ve.elem_id,-111) flag_visualizzazione   ---- cle -nuovo 
from  	siac_t_ente_proprietario t_ente,
		siac_rep_tit_tip_cat_riga_anni v1
			left  join siac_rep_cap_eg tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_eg_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id 
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table)
            left	join    siac_rep_var_entrate_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    and tb2.periodo_anno=tb1.periodo_anno)
---- cle -nuovo  
       left join siac_rep_var_entrate ve
     on (	tb.elem_id	=ve.elem_id	
     --14/05/2019 - SIAC-6819: i capitoli variati non erano estratti se l'anno di 
     -- variazione era maggiore di quello del bilancio. 
        --and ve.periodo_anno=p_anno
        and ve.periodo_anno=p_anno_variazione     
        and ve.utente = TB.utente ) 
---- fine cle -nuovo  
    where t_ente.ente_proprietario_id=v1.ente_proprietario_id
    and v1.utente = user_table    	
    and  tb1.periodo_anno=p_anno_variazione
   and exists ( select 1 from siac_rep_var_entrate_riga x, siac_rep_cap_eg y, 
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.classif_id = z.classif_id
                 and z.classif_id_padre = v1.tipologia_id
            /*  AND (COALESCE(x.variazione_aumento_cassa,0) <>0 OR
                 		COALESCE(x.variazione_aumento_residuo,0) <>0  OR
                        COALESCE(x.variazione_aumento_stanziato,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_cassa,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_residuo,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_stanziato,0) <>0)*/
                        
    )	
    union
    select 	t_ente.ente_denominazione 		ente_denominazione,
		'Titolo'    			titoloe_TIPO_DESC,
       	NULL              		titoloe_ID,
       	'0'            			titoloe_CODE,
       	' '             	titoloe_DESC,
       	'Tipologia'	  			tipologia_TIPO_DESC,
       	null	              	tipologia_ID,
       	'0000000'            	tipologia_CODE,
       	' '           tipologia_DESC,
       	'Categoria'     		categoria_TIPO_DESC,
      	null	              	categoria_ID,
       	'0000000'            	categoria_CODE,
       	' '           categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_attivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)		variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)			variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
        tb1.periodo_anno  anno_riferimento
        	,COALESCE (ve.elem_id,-111) flag_visualizzazione  
from  	siac_t_ente_proprietario t_ente,
		 siac_rep_cap_eg tb
            left	join    siac_rep_cap_eg_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id 
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table)
            left	join    siac_rep_var_entrate_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    and tb2.periodo_anno=tb1.periodo_anno) 
 ---- cle -nuovo  
       left join siac_rep_var_entrate ve
     on (	tb.elem_id	=ve.elem_id	
     --14/05/2019 - SIAC-6819: i capitoli variati non erano estratti se l'anno di 
     -- variazione era maggiore di quello del bilancio. 
        --and ve.periodo_anno=p_anno
        and ve.periodo_anno=p_anno_variazione
        and ve.utente = TB.utente ) 
---- fine cle -nuovo  
    where t_ente.ente_proprietario_id=tb.ente_proprietario_id
    and tb.utente = user_table    	
    and  tb1.periodo_anno=p_anno_variazione
   and tb.classif_id is null
			order by titoloe_CODE,tipologia_CODE,categoria_CODE

loop



---titoloe_tipo_code := classifBilRec.titoloe_tipo_code;
titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
--------tipologia_tipo_code := classifBilRec.tipologia_tipo_code;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
-------categoria_tipo_code := classifBilRec.categoria_tipo_code;
categoria_tipo_desc := classifBilRec.categoria_tipo_desc;
categoria_code := classifBilRec.categoria_code;
categoria_desc := classifBilRec.categoria_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
stanziamento:=classifBilRec.stanziamento;
cassa:=classifBilRec.cassa;
residuo:=classifBilRec.residuo;
variazione_aumento_stanziato:=classifBilRec.variazione_aumento_stanziato;
variazione_diminuzione_stanziato:=classifBilRec.variazione_diminuzione_stanziato;
variazione_aumento_cassa:=classifBilRec.variazione_aumento_cassa;
variazione_diminuzione_cassa:=classifBilRec.variazione_diminuzione_cassa;
variazione_aumento_residuo:=classifBilRec.variazione_aumento_residuo;
variazione_diminuzione_residuo:=classifBilRec.variazione_diminuzione_residuo;
anno_riferimento:=classifBilRec.anno_riferimento;
ente_denominazione =classifBilRec.ente_denominazione;
flag_visualizzazione  =  classifBilRec.flag_visualizzazione ; 


return next;

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
ente_denominazione ='';
flag_visualizzazione = -111;

end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;


delete from siac_rep_cap_eg where utente=user_table;

delete from siac_rep_cap_eg_imp where utente=user_table;

delete from siac_rep_cap_eg_imp_riga where utente=user_table;

delete from	siac_rep_var_entrate	where utente=user_table;

delete from siac_rep_var_entrate_riga where utente=user_table; 


raise notice 'fine OK';

exception
	when no_data_found THEN
		raise notice 'Variazioni non trovate' ;
		--return next;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
	when others  THEN
		--raise notice 'errore nella lettura delle variazioni ';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;