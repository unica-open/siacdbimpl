/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--SIAC-6956 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR209_stampa_variazione_entrate_def"(p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar, p_anno_variazione varchar);
DROP FUNCTION if exists siac."BILR209_stampa_variazione_spese_def"(p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar, p_anno_variazione varchar);
DROP FUNCTION if exists siac."BILR068_stampa_variazione_spese"(p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar, p_anno_variazione varchar);

CREATE OR REPLACE FUNCTION siac."BILR209_stampa_variazione_entrate_def" (
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
  display_error varchar
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

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
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
/*
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
*/

-- 03/07/2019: SIAC-6956.
-- In caso di variazioni l'importo iniziale dei capitoli non deve tenere
-- conto delle variazioni avvenute.
sql_query:='
with cap as (
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
    where 	capitolo_importi.ente_proprietario_id 	='||p_ente_prop_id ||'
        and	anno_eserc.anno						= '''||p_anno ||'''
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id
        and	capitolo.bil_id						=	bilancio.bil_id
        and	capitolo.elem_id					=	capitolo_importi.elem_id
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id
        and	capitolo_imp_periodo.anno = '''||p_anno_variazione||'''
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
	 	-- INC000001570761 and stato_capitolo.elem_stato_code	=	''VA''
        and stato_capitolo.elem_stato_code	in (''VA'', ''PR'')
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_imp_tipo.elem_det_tipo_code in (''STA'', ''SCA'',''STR'')
        -- 06/09/2016: aggiunto FPVC
        --and cat_del_capitolo.elem_cat_code	in (''STD'',''FPV'',''FSC'',''FPVC'')
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
    capitolo_importi.ente_proprietario_id,
    capitolo_imp_tipo.elem_det_tipo_id),
importi_variaz as (
		select
              dvarsucc.elem_id elem_id_var,
			  tipoimp.elem_det_tipo_id,
              sum(COALESCE(dvarsucc.elem_det_importo,0)) totale_var_succ
          from siac_t_variazione avarsucc, siac_r_variazione_stato bvarsucc,
              siac_t_variazione avar, siac_r_variazione_stato bvar,
              siac_d_variazione_stato cvarsucc,
              siac_d_variazione_stato cvar, siac_t_bil_elem_det_var dvarsucc,
              siac_d_bil_elem_det_tipo tipoimp
          where bvarsucc.validita_inizio >= bvar.validita_inizio
              and avar.ente_proprietario_id=avarsucc.ente_proprietario_id
              and avarsucc.variazione_id= bvarsucc.variazione_id
              and avar.variazione_id=bvar.variazione_id
              and bvarsucc.variazione_stato_tipo_id=cvarsucc.variazione_stato_tipo_id
              and cvarsucc.variazione_stato_tipo_code=''D''
              and bvar.variazione_stato_tipo_id=cvar.variazione_stato_tipo_id
              and cvar.variazione_stato_tipo_code=''D''
              and dvarsucc.variazione_stato_id = bvarsucc.variazione_stato_id
              and tipoimp.elem_det_tipo_id = dvarsucc.elem_det_tipo_id
              and bvarsucc.data_cancellazione is null
               --03/07/2019: SIAC-6956. Aggiunto test su data_cancellazione
              and dvarsucc.data_cancellazione is null
              and bvar.variazione_stato_id in (
                select max(var_stato.variazione_stato_id)
                from siac_t_variazione t_var,
                  siac_r_variazione_stato     var_stato
                where
                  t_var.variazione_id = var_stato.variazione_id
                  and t_var.ente_proprietario_id  	='||p_ente_prop_id ||'
                  and t_var.variazione_num in('||p_ele_variazioni||')
                  and t_var.data_cancellazione IS NULL
                  and var_stato.data_cancellazione IS NULL )
			group by dvarsucc.elem_id, tipoimp.elem_det_tipo_id) ' ;


sql_query:=sql_query||'
              INSERT INTO siac_rep_cap_eg_imp
              select 	cap.elem_id,
              			cap.BIL_ELE_IMP_ANNO,
                		cap.TIPO_IMP,
              			cap.ente_proprietario_id,
                        '''||user_table||''' utente,
                		(cap.importo_cap  - COALESCE(importi_variaz.totale_var_succ,0)) diff
              from cap LEFT  JOIN importi_variaz
              ON (cap.elem_id = importi_variaz.elem_id_var
              	and cap.elem_det_tipo_id= importi_variaz.elem_det_tipo_id)';

raise notice 'query: %', sql_query;

execute  sql_query;

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
sql_query=sql_query ||' and		tipologia_stato_var.variazione_stato_tipo_code	=''D''
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
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and tb1.periodo_anno=p_anno
        and tb1.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and tb2.periodo_anno=p_anno
        and tb2.utente = tb0.utente )
    left join siac_rep_var_entrate tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and tb3.periodo_anno=p_anno
        and tb3.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and tb4.periodo_anno=p_anno
        and tb4.utente = tb0.utente )
    left join siac_rep_var_entrate tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
        and tb5.periodo_anno=p_anno
        and tb5.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
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
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and tb1.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb1.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and tb2.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb2.utente = tb0.utente )
    left join siac_rep_var_entrate tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and tb3.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb3.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and tb4.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb4.utente = tb0.utente )
    left join siac_rep_var_entrate tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
        and tb5.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb5.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
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
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and tb1.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb1.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and tb2.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb2.utente = tb0.utente )
    left join siac_rep_var_entrate tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and tb3.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb3.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and tb4.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb4.utente = tb0.utente )
    left join siac_rep_var_entrate tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
        and tb5.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb5.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
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
variazione_aumento_stanziato:=COALESCE(classifBilRec.variazione_aumento_stanziato,0);
variazione_diminuzione_stanziato:=COALESCE(classifBilRec.variazione_diminuzione_stanziato,0);
variazione_aumento_cassa:=COALESCE(classifBilRec.variazione_aumento_cassa,0);
variazione_diminuzione_cassa:=COALESCE(classifBilRec.variazione_diminuzione_cassa,0);
variazione_aumento_residuo:=COALESCE(classifBilRec.variazione_aumento_residuo,0);
variazione_diminuzione_residuo:=COALESCE(classifBilRec.variazione_diminuzione_residuo,0);
anno_riferimento:=classifBilRec.anno_riferimento;
ente_denominazione =classifBilRec.ente_denominazione;

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

-- se ?? presente il parametro con l'elenco delle variazioni verifico che abbia
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
---------------------------------------------------------------------------------------------------------------------

select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_mis_pro_tit_mac_riga_anni''.';  


-- carico struttura del bilancio
with missione as 
(select 
e.classif_tipo_desc missione_tipo_desc,
a.classif_id missione_id,
a.classif_code missione_code,
a.classif_desc missione_desc,
a.validita_inizio missione_validita_inizio,
a.validita_fine missione_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
--and to_timestamp('01/01/'||p_anno,'dd/mm/yyyy') between  v.titusc_validita_inizio and COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, programma as (
select 
e.classif_tipo_desc programma_tipo_desc,
b.classif_id_padre missione_id,
a.classif_id programma_id,
a.classif_code programma_code,
a.classif_desc programma_desc,
a.validita_inizio programma_validita_inizio,
a.validita_fine programma_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not  null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
,
titusc as (
select 
e.classif_tipo_desc titusc_tipo_desc,
a.classif_id titusc_id,
a.classif_code titusc_code,
a.classif_desc titusc_desc,
a.validita_inizio titusc_validita_inizio,
a.validita_fine titusc_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, macroag as (
select 
e.classif_tipo_desc macroag_tipo_desc,
b.classif_id_padre titusc_id,
a.classif_id macroag_id,
a.classif_code macroag_code,
a.classif_desc macroag_desc,
a.validita_inizio macroag_validita_inizio,
a.validita_fine macroag_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into siac_rep_mis_pro_tit_mac_riga_anni
select  missione.missione_tipo_desc,
missione.missione_id,
missione.missione_code,
missione.missione_desc,
missione.missione_validita_inizio,
missione.missione_validita_fine,
programma.programma_tipo_desc,
programma.programma_id,
programma.programma_code,
programma.programma_desc,
programma.programma_validita_inizio,
programma.programma_validita_fine,
titusc.titusc_tipo_desc,
titusc.titusc_id,
titusc.titusc_code,
titusc.titusc_desc,
titusc.titusc_validita_inizio,
titusc.titusc_validita_fine,
macroag.macroag_tipo_desc,
macroag.macroag_id,
macroag.macroag_code,
macroag.macroag_desc,
macroag.macroag_validita_inizio,
macroag.macroag_validita_fine,
missione.ente_proprietario_id
,user_table
from missione , programma,titusc, macroag
    /* 06/09/2016: start filtro per mis-prog-macro*/
  , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 06/09/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;



 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug''.';  
insert into siac_rep_cap_ug 
select 	programma.classif_id,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
       user_table utente
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
     siac_d_class_tipo programma_tipo,
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
where 
	programma_tipo.classif_tipo_code='PROGRAMMA' 							and		
    programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and
    macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
   	anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	-- INC000001570761 stato_capitolo.elem_stato_code	=	'VA'								and
    stato_capitolo.elem_stato_code	in ('VA', 'PR')							and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		
    ------cat_del_capitolo.elem_cat_code	=	'STD'	
    -- 06/09/2016: aggiunto FPVC
	--and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
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
    and	r_cat_capitolo.data_cancellazione 			is null;	

          
    insert into siac_rep_cap_ug
      select null, null,
        anno_eserc.anno anno_bilancio,
        e.*, ' ', user_table utente
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
	  -- INC000001570761 and stato_capitolo.elem_stato_code	=	'VA'								
      and stato_capitolo.elem_stato_code	in ('VA', 'PR')			
      and e.data_cancellazione 				is null
      and	r_capitolo_stato.data_cancellazione	is null
      and	bilancio.data_cancellazione 		is null
      and	anno_eserc.data_cancellazione 		is null
      and	tipo_elemento.data_cancellazione	is null
      and	stato_capitolo.data_cancellazione 	is null
      and not EXISTS
      (
         select 1 from siac_rep_cap_ug x
         where x.elem_id = e.elem_id
         and x.utente=user_table
    );

RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug_imp standard''.';  
  

/* 18/05/2016: introdotta modifica all'estrazione degli importi dei capitoli.
	Si deve tener conto di eventuali variazioni successive e decrementare 
    l'importo del capitolo.
*/

INSERT INTO siac_rep_cap_ug_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
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
        and	capitolo_imp_periodo.anno = p_anno_variazione
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
	 	-- INC000001570761 and stato_capitolo.elem_stato_code	=	'VA'								
        and stato_capitolo.elem_stato_code	in ('VA', 'PR')			
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_imp_tipo.elem_det_tipo_code in ('STA', 'SCA','STR')
        -- 06/09/2016: aggiunto FPVC
        --and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')						
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
 
     RTN_MESSAGGIO:='preparazione tabella importi riga capitolo ''.';  

insert into siac_rep_cap_ug_imp_riga
select  tb1.elem_id, 
   	 	tb4.importo		as		residui_passivi,
    	tb1.importo 	as 		previsioni_definitive_comp,
        tb2.importo		as		previsioni_definitive_cassa,
        tb1.ente_proprietario,
        user_table utente ,
        tb1.periodo_anno
from 
        siac_rep_cap_ug_imp tb1, siac_rep_cap_ug_imp tb2, siac_rep_cap_ug_imp tb4
where			tb1.elem_id				= tb2.elem_id							and
				tb1.elem_id 			= tb4.elem_id							and
        		tb1.periodo_anno 		= p_anno_variazione	AND	 
                tb1.tipo_imp 	=	tipoImpComp		        AND      
        		tb2.periodo_anno		= tb1.periodo_anno	AND	
                tb2.tipo_imp 	= 	tipoImpCassa	        and
                tb4.periodo_anno    	= tb1.periodo_anno 	AND	
                tb4.tipo_imp 	= 	TipoImpRes		        and 	
                tb1.ente_proprietario 	=	p_ente_prop_id						and	
                tb2.ente_proprietario	=	tb1.ente_proprietario				and	
                tb4.ente_proprietario	=	tb1.ente_proprietario				and
                tb1.utente				=	user_table							AND
                tb2.utente				=	tb1.utente							and	
                tb4.utente				=	tb1.utente;
                  
     RTN_MESSAGGIO:='preparazione tabella variazioni''.';  
     
/*   
insert into siac_rep_var_spese
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        ------dettaglio_variazione.elem_det_importo,
        tipo_elemento.elem_det_tipo_code, 
        user_table utente,
        atto.ente_proprietario_id,
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
        siac_t_periodo              anno_importo ,
        siac_t_bil                  bilancio  
where 	atto.ente_proprietario_id 							= 	p_ente_prop_id
and		atto.attoamm_numero 								= 	p_numero_delibera
and		atto.attoamm_anno									=	p_anno_delibera
and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera-----------   deve essere un parametro di input 
and		r_atto_stato.attoamm_id								=	atto.attoamm_id
and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
and		r_variazione_stato.attoamm_id						=	atto.attoamm_id
and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id
and		anno_eserc.anno										= 	p_anno 												
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id   
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		tipologia_stato_var.variazione_stato_tipo_code		in	('B','G', 'C', 'P')
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
            anno_importo.anno	    ;*/

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

        
     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  
     
insert into siac_rep_var_spese_riga
select  tb0.elem_id,        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno_variazione
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo >= 0	
        and     tb1.periodo_anno=p_anno_variazione
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo <= 0	
        and     tb2.periodo_anno=p_anno_variazione
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo >= 0	
        and     tb3.periodo_anno=p_anno_variazione
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo <= 0	
        and     tb4.periodo_anno=p_anno_variazione
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo >= 0
        and     tb5.periodo_anno=p_anno_variazione
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo <= 0
        and     tb6.periodo_anno=p_anno_variazione
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
   /*
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
       annocapimp2
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp2
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp2
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp2
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp2
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp2
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp2
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
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
        annocapimp3
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp3
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp3
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp3
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp3
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp3
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp3
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table   */ ; 
        
        
     RTN_MESSAGGIO:='preparazione file output ''.';  

/* 20/05/2016: aggiunto il controllo se il capitolo ha subito delle variazioni, tramite
	il test su siac_rep_var_spese_riga x, siac_rep_cap_ug y, siac_r_class_fam_tree z
*/     
for classifBilRec in
select	v1.macroag_code						macroag_code,
      	v1.macroag_desc						macroag_desc,
        v1.macroag_tipo_desc				macroag_tipo_desc,
        v1.missione_code					missione_code,
        v1.missione_desc					missione_desc,
        v1.missione_tipo_desc				missione_tipo_desc,
        v1.programma_code					programma_code,
        v1.programma_desc					programma_desc,
        v1.programma_tipo_desc				programma_tipo_desc,
        v1.titusc_code						titusc_code,
        v1.titusc_desc						titusc_desc,
        v1.titusc_tipo_desc					titusc_tipo_desc,
    	tb.bil_anno   						BIL_ANNO,
       	tb.elem_code     					BIL_ELE_CODE,
       	tb.elem_desc     					BIL_ELE_DESC,
       	tb.elem_code2     					BIL_ELE_CODE2,
       	tb.elem_desc2     					BIL_ELE_DESC2,
       	tb.elem_id      					BIL_ELE_ID,
       	tb.elem_id_padre   		 			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_passivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)	variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)		variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
        tb1.periodo_anno  anno_riferimento
		,COALESCE (vu.elem_id,-111) flag_visualizzazione   ---- cle -nuovo 
from  	siac_rep_mis_pro_tit_mac_riga_anni v1
         	LEFT join siac_rep_cap_ug tb
           on    	(v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)     
            left	join    siac_rep_cap_ug_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table
                    )      	
            left	join    siac_rep_var_spese_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    and tb2.periodo_anno=tb1.periodo_anno)     
	---- cle -nuovo  
       left join siac_rep_var_spese vu
     on (	tb.elem_id	=vu.elem_id	
        and  vu.periodo_anno=p_anno_variazione
        and vu.utente = tb.utente ) 
---- fine cle -nuovo  
    where v1.utente = user_table 
    	and tb1.periodo_anno = p_anno_variazione
    and exists ( select 1 from siac_rep_var_spese_riga x, siac_rep_cap_ug y, 
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.macroaggregato_id = z.classif_id
                 and z.classif_id_padre = v1.titusc_id
                 and y.programma_id=v1.programma_id
             /*  AND (COALESCE(x.variazione_aumento_cassa,0) <>0 OR
                 		COALESCE(x.variazione_aumento_residuo,0) <>0  OR
                        COALESCE(x.variazione_aumento_stanziato,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_cassa,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_residuo,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_stanziato,0) <>0)*/
                        
    )	
    union
    select	
    	'0000000'							macroag_code,
      	' '									macroag_desc,
        'Macroaggregato'					macroag_tipo_desc,
        '00'								missione_code,
        ' '									missione_desc,
        'Missione'							missione_tipo_desc,
        '0000'								programma_code,
        ' '									programma_desc,
        'Programma'							programma_tipo_desc,
        '0'									titusc_code,
        ' '									titusc_desc,
        'Titolo Spesa'						titusc_tipo_desc,
    	tb.bil_anno   						BIL_ANNO,
       	tb.elem_code     					BIL_ELE_CODE,
       	tb.elem_desc     					BIL_ELE_DESC,
       	tb.elem_code2     					BIL_ELE_CODE2,
       	tb.elem_desc2     					BIL_ELE_DESC2,
       	tb.elem_id      					BIL_ELE_ID,
       	tb.elem_id_padre   		 			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_passivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)	variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)		variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
        tb1.periodo_anno  anno_riferimento
	,COALESCE (vu.elem_id,-111) flag_visualizzazione  
from  	siac_t_ente_proprietario t_ente,
		 siac_rep_cap_ug tb
            left	join    siac_rep_cap_ug_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id 
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table)
            left	join    siac_rep_var_spese_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    and tb2.periodo_anno=tb1.periodo_anno) 
---- cle -nuovo  
       left join siac_rep_var_spese vu
     on (	tb.elem_id	=vu.elem_id	
        and  vu.periodo_anno=p_anno_variazione
        and vu.utente = tb.utente ) 
---- fine cle -nuovo  
    where t_ente.ente_proprietario_id=tb.ente_proprietario_id
    and tb.utente = user_table    	
    and  tb1.periodo_anno=p_anno_variazione
   and (tb.programma_id is null or tb.macroaggregato_id is NULL)
   
                        	
			order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID

loop



missione_tipo_desc:= classifBilRec.missione_tipo_desc;
missione_code:= classifBilRec.missione_code;
missione_desc:= classifBilRec.missione_desc;
programma_tipo_desc := classifBilRec.programma_tipo_desc;
programma_code := classifBilRec.programma_code;
programma_desc := classifBilRec.programma_desc;
titusc_tipo_desc := classifBilRec.titusc_tipo_desc;
titusc_code := classifBilRec.titusc_code;
titusc_desc := classifBilRec.titusc_desc;
macroag_tipo_desc := classifBilRec.macroag_tipo_desc;
macroag_code := classifBilRec.macroag_code;
macroag_desc := classifBilRec.macroag_desc;
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
flag_visualizzazione  =  classifBilRec.flag_visualizzazione ; 

return next;
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
flag_visualizzazione = -111;

end loop;


delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;

delete from siac_rep_cap_ug where utente=user_table;

delete from siac_rep_cap_ug_imp where utente=user_table;

delete from siac_rep_cap_ug_imp_riga where utente=user_table;

delete from	siac_rep_var_spese	where utente=user_table;

delete from siac_rep_var_spese_riga where utente=user_table;




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

-- se ?? presente il parametro con l'elenco delle variazioni verifico che abbia
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
---------------------------------------------------------------------------------------------------------------------

select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_mis_pro_tit_mac_riga_anni''.';  


-- carico struttura del bilancio
with missione as 
(select 
e.classif_tipo_desc missione_tipo_desc,
a.classif_id missione_id,
a.classif_code missione_code,
a.classif_desc missione_desc,
a.validita_inizio missione_validita_inizio,
a.validita_fine missione_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
--and to_timestamp('01/01/'||p_anno,'dd/mm/yyyy') between  v.titusc_validita_inizio and COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, programma as (
select 
e.classif_tipo_desc programma_tipo_desc,
b.classif_id_padre missione_id,
a.classif_id programma_id,
a.classif_code programma_code,
a.classif_desc programma_desc,
a.validita_inizio programma_validita_inizio,
a.validita_fine programma_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not  null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
,
titusc as (
select 
e.classif_tipo_desc titusc_tipo_desc,
a.classif_id titusc_id,
a.classif_code titusc_code,
a.classif_desc titusc_desc,
a.validita_inizio titusc_validita_inizio,
a.validita_fine titusc_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, macroag as (
select 
e.classif_tipo_desc macroag_tipo_desc,
b.classif_id_padre titusc_id,
a.classif_id macroag_id,
a.classif_code macroag_code,
a.classif_desc macroag_desc,
a.validita_inizio macroag_validita_inizio,
a.validita_fine macroag_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into siac_rep_mis_pro_tit_mac_riga_anni
select  missione.missione_tipo_desc,
missione.missione_id,
missione.missione_code,
missione.missione_desc,
missione.missione_validita_inizio,
missione.missione_validita_fine,
programma.programma_tipo_desc,
programma.programma_id,
programma.programma_code,
programma.programma_desc,
programma.programma_validita_inizio,
programma.programma_validita_fine,
titusc.titusc_tipo_desc,
titusc.titusc_id,
titusc.titusc_code,
titusc.titusc_desc,
titusc.titusc_validita_inizio,
titusc.titusc_validita_fine,
macroag.macroag_tipo_desc,
macroag.macroag_id,
macroag.macroag_code,
macroag.macroag_desc,
macroag.macroag_validita_inizio,
macroag.macroag_validita_fine,
missione.ente_proprietario_id
,user_table
from missione , programma,titusc, macroag
    /* 06/09/2016: start filtro per mis-prog-macro*/
  , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 06/09/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;



 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug''.';  
insert into siac_rep_cap_ug 
select 	programma.classif_id,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
       user_table utente
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
     siac_d_class_tipo programma_tipo,
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
where 
	programma_tipo.classif_tipo_code='PROGRAMMA' 							and		
    programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and
    macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
   	anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	-- INC000001570761 stato_capitolo.elem_stato_code	=	'VA'								and
    stato_capitolo.elem_stato_code	in ('VA', 'PR')							and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		
    ------cat_del_capitolo.elem_cat_code	=	'STD'	
    -- 06/09/2016: aggiunto FPVC
	--and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
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
    and	r_cat_capitolo.data_cancellazione 			is null;	

          
    insert into siac_rep_cap_ug
      select null, null,
        anno_eserc.anno anno_bilancio,
        e.*, ' ', user_table utente
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
	  -- INC000001570761 and stato_capitolo.elem_stato_code	=	'VA'								
      and stato_capitolo.elem_stato_code	in ('VA', 'PR')			
      and e.data_cancellazione 				is null
      and	r_capitolo_stato.data_cancellazione	is null
      and	bilancio.data_cancellazione 		is null
      and	anno_eserc.data_cancellazione 		is null
      and	tipo_elemento.data_cancellazione	is null
      and	stato_capitolo.data_cancellazione 	is null
      and not EXISTS
      (
         select 1 from siac_rep_cap_ug x
         where x.elem_id = e.elem_id
         and x.utente=user_table
    );

RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug_imp standard''.';  
  

/* 18/05/2016: introdotta modifica all'estrazione degli importi dei capitoli.
	Si deve tener conto di eventuali variazioni successive e decrementare 
    l'importo del capitolo.
*/

INSERT INTO siac_rep_cap_ug_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
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
        and	capitolo_imp_periodo.anno = p_anno_variazione
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
	 	-- INC000001570761 and stato_capitolo.elem_stato_code	=	'VA'								
        and stato_capitolo.elem_stato_code	in ('VA', 'PR')			
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_imp_tipo.elem_det_tipo_code in ('STA', 'SCA','STR')
        -- 06/09/2016: aggiunto FPVC
        --and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')						
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
 
     RTN_MESSAGGIO:='preparazione tabella importi riga capitolo ''.';  

insert into siac_rep_cap_ug_imp_riga
select  tb1.elem_id, 
   	 	tb4.importo		as		residui_passivi,
    	tb1.importo 	as 		previsioni_definitive_comp,
        tb2.importo		as		previsioni_definitive_cassa,
        tb1.ente_proprietario,
        user_table utente ,
        tb1.periodo_anno
from 
        siac_rep_cap_ug_imp tb1, siac_rep_cap_ug_imp tb2, siac_rep_cap_ug_imp tb4
where			tb1.elem_id				= tb2.elem_id							and
				tb1.elem_id 			= tb4.elem_id							and
        		tb1.periodo_anno 		= p_anno_variazione	AND	 
                tb1.tipo_imp 	=	tipoImpComp		        AND      
        		tb2.periodo_anno		= tb1.periodo_anno	AND	
                tb2.tipo_imp 	= 	tipoImpCassa	        and
                tb4.periodo_anno    	= tb1.periodo_anno 	AND	
                tb4.tipo_imp 	= 	TipoImpRes		        and 	
                tb1.ente_proprietario 	=	p_ente_prop_id						and	
                tb2.ente_proprietario	=	tb1.ente_proprietario				and	
                tb4.ente_proprietario	=	tb1.ente_proprietario				and
                tb1.utente				=	user_table							AND
                tb2.utente				=	tb1.utente							and	
                tb4.utente				=	tb1.utente;
                  
     RTN_MESSAGGIO:='preparazione tabella variazioni''.';  
     
/*   
insert into siac_rep_var_spese
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        ------dettaglio_variazione.elem_det_importo,
        tipo_elemento.elem_det_tipo_code, 
        user_table utente,
        atto.ente_proprietario_id,
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
        siac_t_periodo              anno_importo ,
        siac_t_bil                  bilancio  
where 	atto.ente_proprietario_id 							= 	p_ente_prop_id
and		atto.attoamm_numero 								= 	p_numero_delibera
and		atto.attoamm_anno									=	p_anno_delibera
and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera-----------   deve essere un parametro di input 
and		r_atto_stato.attoamm_id								=	atto.attoamm_id
and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
and		r_variazione_stato.attoamm_id						=	atto.attoamm_id
and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id
and		anno_eserc.anno										= 	p_anno 												
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id   
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		tipologia_stato_var.variazione_stato_tipo_code		in	('B','G', 'C', 'P')
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
            anno_importo.anno	    ;*/

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

        
     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  
     
insert into siac_rep_var_spese_riga
select  tb0.elem_id,        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno_variazione
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo >= 0	
        and     tb1.periodo_anno=p_anno_variazione
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo <= 0	
        and     tb2.periodo_anno=p_anno_variazione
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo >= 0	
        and     tb3.periodo_anno=p_anno_variazione
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo <= 0	
        and     tb4.periodo_anno=p_anno_variazione
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo >= 0
        and     tb5.periodo_anno=p_anno_variazione
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo <= 0
        and     tb6.periodo_anno=p_anno_variazione
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
   /*
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
       annocapimp2
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp2
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp2
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp2
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp2
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp2
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp2
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
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
        annocapimp3
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp3
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp3
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp3
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp3
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp3
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp3
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table   */ ; 
        
        
     RTN_MESSAGGIO:='preparazione file output ''.';  

/* 20/05/2016: aggiunto il controllo se il capitolo ha subito delle variazioni, tramite
	il test su siac_rep_var_spese_riga x, siac_rep_cap_ug y, siac_r_class_fam_tree z
*/     
for classifBilRec in
select	v1.macroag_code						macroag_code,
      	v1.macroag_desc						macroag_desc,
        v1.macroag_tipo_desc				macroag_tipo_desc,
        v1.missione_code					missione_code,
        v1.missione_desc					missione_desc,
        v1.missione_tipo_desc				missione_tipo_desc,
        v1.programma_code					programma_code,
        v1.programma_desc					programma_desc,
        v1.programma_tipo_desc				programma_tipo_desc,
        v1.titusc_code						titusc_code,
        v1.titusc_desc						titusc_desc,
        v1.titusc_tipo_desc					titusc_tipo_desc,
    	tb.bil_anno   						BIL_ANNO,
       	tb.elem_code     					BIL_ELE_CODE,
       	tb.elem_desc     					BIL_ELE_DESC,
       	tb.elem_code2     					BIL_ELE_CODE2,
       	tb.elem_desc2     					BIL_ELE_DESC2,
       	tb.elem_id      					BIL_ELE_ID,
       	tb.elem_id_padre   		 			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_passivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)	variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)		variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
        tb1.periodo_anno  anno_riferimento
		,COALESCE (vu.elem_id,-111) flag_visualizzazione   ---- cle -nuovo 
from  	siac_rep_mis_pro_tit_mac_riga_anni v1
         	LEFT join siac_rep_cap_ug tb
           on    	(v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)     
            left	join    siac_rep_cap_ug_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table
                    )      	
            left	join    siac_rep_var_spese_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    and tb2.periodo_anno=tb1.periodo_anno)     
	---- cle -nuovo  
       left join siac_rep_var_spese vu
     on (	tb.elem_id	=vu.elem_id	
        and  vu.periodo_anno=p_anno_variazione
        and vu.utente = tb.utente ) 
---- fine cle -nuovo  
    where v1.utente = user_table 
    	and tb1.periodo_anno = p_anno_variazione
    and exists ( select 1 from siac_rep_var_spese_riga x, siac_rep_cap_ug y, 
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.macroaggregato_id = z.classif_id
                 and z.classif_id_padre = v1.titusc_id
                 and y.programma_id=v1.programma_id
             /*  AND (COALESCE(x.variazione_aumento_cassa,0) <>0 OR
                 		COALESCE(x.variazione_aumento_residuo,0) <>0  OR
                        COALESCE(x.variazione_aumento_stanziato,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_cassa,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_residuo,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_stanziato,0) <>0)*/
                        
    )	
    union
    select	
    	'0000000'							macroag_code,
      	' '									macroag_desc,
        'Macroaggregato'					macroag_tipo_desc,
        '00'								missione_code,
        ' '									missione_desc,
        'Missione'							missione_tipo_desc,
        '0000'								programma_code,
        ' '									programma_desc,
        'Programma'							programma_tipo_desc,
        '0'									titusc_code,
        ' '									titusc_desc,
        'Titolo Spesa'						titusc_tipo_desc,
    	tb.bil_anno   						BIL_ANNO,
       	tb.elem_code     					BIL_ELE_CODE,
       	tb.elem_desc     					BIL_ELE_DESC,
       	tb.elem_code2     					BIL_ELE_CODE2,
       	tb.elem_desc2     					BIL_ELE_DESC2,
       	tb.elem_id      					BIL_ELE_ID,
       	tb.elem_id_padre   		 			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_passivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)	variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)		variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
        tb1.periodo_anno  anno_riferimento
	,COALESCE (vu.elem_id,-111) flag_visualizzazione  
from  	siac_t_ente_proprietario t_ente,
		 siac_rep_cap_ug tb
            left	join    siac_rep_cap_ug_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id 
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table)
            left	join    siac_rep_var_spese_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    and tb2.periodo_anno=tb1.periodo_anno) 
---- cle -nuovo  
       left join siac_rep_var_spese vu
     on (	tb.elem_id	=vu.elem_id	
        and  vu.periodo_anno=p_anno_variazione
        and vu.utente = tb.utente ) 
---- fine cle -nuovo  
    where t_ente.ente_proprietario_id=tb.ente_proprietario_id
    and tb.utente = user_table    	
    and  tb1.periodo_anno=p_anno_variazione
   and (tb.programma_id is null or tb.macroaggregato_id is NULL)
   
                        	
			order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID

loop



missione_tipo_desc:= classifBilRec.missione_tipo_desc;
missione_code:= classifBilRec.missione_code;
missione_desc:= classifBilRec.missione_desc;
programma_tipo_desc := classifBilRec.programma_tipo_desc;
programma_code := classifBilRec.programma_code;
programma_desc := classifBilRec.programma_desc;
titusc_tipo_desc := classifBilRec.titusc_tipo_desc;
titusc_code := classifBilRec.titusc_code;
titusc_desc := classifBilRec.titusc_desc;
macroag_tipo_desc := classifBilRec.macroag_tipo_desc;
macroag_code := classifBilRec.macroag_code;
macroag_desc := classifBilRec.macroag_desc;
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
flag_visualizzazione  =  classifBilRec.flag_visualizzazione ; 

return next;
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
flag_visualizzazione = -111;

end loop;


delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;

delete from siac_rep_cap_ug where utente=user_table;

delete from siac_rep_cap_ug_imp where utente=user_table;

delete from siac_rep_cap_ug_imp_riga where utente=user_table;

delete from	siac_rep_var_spese	where utente=user_table;

delete from siac_rep_var_spese_riga where utente=user_table;




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


--SIAC-6956 - Maurizio - FINE

--SIAC-6939 INIZIO
-- SIAC-5152: DROP FUNZIONE CON UNO (vecchia versione) E DUE (nuova versione) PARAMETRI
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata_importo (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata_importo (integer,varchar);

DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata_importo (integer,varchar,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata_importo (
  _uid_capitoloentrata integer,
  _anno varchar,
 _filtro_crp varchar -- 11.07.2018 Sofia jira SIAC-6193 C,R,P, altro per tutto

)
RETURNS numeric AS
$body$
DECLARE
	total numeric;
BEGIN

	SELECT coalesce(sum(f.movgest_ts_det_importo),0) into total
	from
		siac_t_bil_elem a,
		siac_t_bil b2,
		siac_t_periodo c2,
		siac_r_movgest_bil_elem b,
		siac_t_movgest c,
		siac_d_movgest_tipo d,
		siac_t_movgest_ts e,
		siac_t_movgest_ts_det f,
		siac_d_movgest_ts_tipo g,
		siac_d_movgest_ts_det_tipo h,
		siac_r_movgest_ts_stato i,
		siac_d_movgest_stato l,
		siac_r_movgest_class m,
		siac_t_class n,
		siac_d_class_tipo o,
		siac_t_bil p,
		siac_t_periodo q
	where a.bil_id=b2.bil_id
	and c2.periodo_id=b2.periodo_id
	and c.movgest_id=b.movgest_id
	and b.elem_id=a.elem_id
	and d.movgest_tipo_id=c.movgest_tipo_id
	and e.movgest_id=c.movgest_id
	and f.movgest_ts_id=e.movgest_ts_id
	and g.movgest_ts_tipo_id=e.movgest_ts_tipo_id
	and h.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
	and i.movgest_ts_id=e.movgest_ts_id
	and m.movgest_ts_id = e.movgest_ts_id
	and n.classif_id = m.classif_id
	and o.classif_tipo_id = n.classif_tipo_id
	and l.movgest_stato_id=i.movgest_stato_id
	and p.bil_id = c.bil_id
	and q.periodo_id = p.periodo_id
	and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
	and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
	and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
	and b.data_cancellazione is null
	and c.data_cancellazione is null
	and d.data_cancellazione is null
	and e.data_cancellazione is null
	and f.data_cancellazione is null
	and g.data_cancellazione is null
	and h.data_cancellazione is null
	and i.data_cancellazione is null
	and l.data_cancellazione is null
	and m.data_cancellazione is null
	and n.data_cancellazione is null
	and o.data_cancellazione is null
	and p.data_cancellazione is null
	and q.data_cancellazione is null
	and d.movgest_tipo_code='A'
	and g.movgest_ts_tipo_code='T'
	and h.movgest_ts_det_tipo_code='A'
	and l.movgest_stato_code<>'A'

	and o.classif_tipo_code IN ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
	and a.elem_id=_uid_capitoloentrata
	and q.anno = _anno
    -- 11.07.2018 Sofia jira siac-6193
    and (case when coalesce(_filtro_crp,'X')='R' then c.movgest_anno<_anno::integer
              when coalesce(_filtro_crp,'X')='C' then c.movgest_anno=_anno::integer
              when coalesce(_filtro_crp,'X')='P' then c.movgest_anno>_anno::integer
              else true end );

	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- SIAC-5152: DROP FUNZIONE CON UNO (vecchia versione) E DUE (nuova versione) PARAMETRI
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata_total (integer,varchar);

DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata_total (integer,varchar,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata_total (
  _uid_capitoloentrata integer,
  _anno varchar,
  _filtro_crp varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT coalesce(count(*),0) into total
	from
		siac_t_bil_elem a,
		siac_t_bil b2,
		siac_t_periodo c2,
		siac_r_movgest_bil_elem b,
		siac_t_movgest c,
		siac_d_movgest_tipo d,
		siac_t_movgest_ts e,
		siac_t_movgest_ts_det f,
		siac_d_movgest_ts_tipo g,
		siac_d_movgest_ts_det_tipo h,
		siac_r_movgest_ts_stato i,
		siac_d_movgest_stato l,
		siac_r_movgest_class m,
		siac_t_class n,
		siac_d_class_tipo o,
		siac_t_bil p,
		siac_t_periodo q
	where a.bil_id=b2.bil_id
	and c2.periodo_id=b2.periodo_id
	and c.movgest_id=b.movgest_id
	and b.elem_id=a.elem_id
	and d.movgest_tipo_id=c.movgest_tipo_id
	and e.movgest_id=c.movgest_id
	and f.movgest_ts_id=e.movgest_ts_id
	and g.movgest_ts_tipo_id=e.movgest_ts_tipo_id
	and h.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
	and i.movgest_ts_id=e.movgest_ts_id
	and m.movgest_ts_id = e.movgest_ts_id
	and n.classif_id = m.classif_id
	and o.classif_tipo_id = n.classif_tipo_id
	and l.movgest_stato_id=i.movgest_stato_id
	and p.bil_id = c.bil_id
	and q.periodo_id = p.periodo_id
	and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
	and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
	and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
	and b.data_cancellazione is null
	and c.data_cancellazione is null
	and d.data_cancellazione is null
	and e.data_cancellazione is null
	and f.data_cancellazione is null
	and g.data_cancellazione is null
	and h.data_cancellazione is null
	and i.data_cancellazione is null
	and l.data_cancellazione is null
	and m.data_cancellazione is null
	and n.data_cancellazione is null
	and o.data_cancellazione is null
	and p.data_cancellazione is null
	and q.data_cancellazione is null
	and d.movgest_tipo_code='A'
	and g.movgest_ts_tipo_code='T'
	and h.movgest_ts_det_tipo_code='A'
	and l.movgest_stato_code<>'A'
	and o.classif_tipo_code IN ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
	and a.elem_id=_uid_capitoloentrata
	and q.anno = _anno
    -- 11.07.2018 Sofia jira siac-6193
    and (case when coalesce(_filtro_crp,'X')='R' then c.movgest_anno<_anno::integer
              when coalesce(_filtro_crp,'X')='C' then c.movgest_anno=_anno::integer
              when coalesce(_filtro_crp,'X')='P' then c.movgest_anno>_anno::integer
              else true end );

	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_capitolospesa_importo (integer,varchar,varchar);

-- _filtro_crp da rinominare: e' il filtro che discrimina COMPETENZA, RESIDUO, PLURIENNALE
CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_impegno_from_capitolospesa_importo (
  _uid_capitolospesa integer,
  _anno varchar,
  _filtro_crp varchar
)
RETURNS numeric AS
$body$
DECLARE
	total numeric;
BEGIN

	SELECT coalesce(sum(f.movgest_ts_det_importo),0) into total
	from
		siac_t_bil_elem a,
		siac_t_bil b2,
		siac_t_periodo c2,
		siac_r_movgest_bil_elem b,
		siac_t_movgest c,
		siac_d_movgest_tipo d,
		siac_t_movgest_ts e,
		siac_t_movgest_ts_det f,
		siac_d_movgest_ts_tipo g,
		siac_d_movgest_ts_det_tipo h,
		siac_r_movgest_ts_stato i,
		siac_d_movgest_stato l,
		siac_r_movgest_class m,
		siac_t_class n,
		siac_d_class_tipo o,
		siac_t_bil p,
		siac_t_periodo q
	where a.bil_id=b2.bil_id
	and c2.periodo_id=b2.periodo_id
	and c.movgest_id=b.movgest_id
	and b.elem_id=a.elem_id
	and d.movgest_tipo_id=c.movgest_tipo_id
	and e.movgest_id=c.movgest_id
	and f.movgest_ts_id=e.movgest_ts_id
	and g.movgest_ts_tipo_id=e.movgest_ts_tipo_id
	and h.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
	and i.movgest_ts_id=e.movgest_ts_id
	and l.movgest_stato_id=i.movgest_stato_id
	and m.movgest_ts_id = e.movgest_ts_id
	and n.classif_id = m.classif_id
	and o.classif_tipo_id = n.classif_tipo_id
	and p.bil_id = c.bil_id
	and q.periodo_id = p.periodo_id
	and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
	and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
	and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
	and b.data_cancellazione is null
	and c.data_cancellazione is null
	and d.data_cancellazione is null
	and e.data_cancellazione is null
	and f.data_cancellazione is null
	and g.data_cancellazione is null
	and h.data_cancellazione is null
	and i.data_cancellazione is null
	and l.data_cancellazione is null
	and m.data_cancellazione is null
	and n.data_cancellazione is null
	and o.data_cancellazione is null
	and p.data_cancellazione is null
	and q.data_cancellazione is null
	and d.movgest_tipo_code='I'
	and g.movgest_ts_tipo_code='T'
	and h.movgest_ts_det_tipo_code='A'
	and l.movgest_stato_code<>'A'
	and o.classif_tipo_code IN ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
	and a.elem_id=_uid_capitolospesa
	and q.anno = _anno
    and (case when coalesce(_filtro_crp,'X')='R' then c.movgest_anno<_anno::integer
                     	when coalesce(_filtro_crp,'X')='C' then c.movgest_anno=_anno::integer
                        when coalesce(_filtro_crp,'X')='P' then c.movgest_anno>_anno::integer
		                else true end); -- 02.07.2018 Sofia jira siac-6193

	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


-- SIAC-5152: DROP FUNZIONE CON UNO (vecchia versione) E DUE (nuova versione) PARAMETRI
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_capitolospesa_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_capitolospesa_total (integer,varchar);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_capitolospesa_total (integer,varchar,varchar);

-- _filtro_crp da rinominare: e' il filtro che discrimina COMPETENZA, RESIDUO, PLURIENNALE
CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_impegno_from_capitolospesa_total (
  _uid_capitolospesa integer,
  _anno varchar,
  _filtro_crp varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT coalesce(count(*),0) into total
	from
		siac_t_bil_elem a,
		siac_t_bil b2,
		siac_t_periodo c2,
		siac_r_movgest_bil_elem b,
		siac_t_movgest c,
		siac_d_movgest_tipo d,
		siac_t_movgest_ts e,
		siac_t_movgest_ts_det f,
		siac_d_movgest_ts_tipo g,
		siac_d_movgest_ts_det_tipo h,
		siac_r_movgest_ts_stato i,
		siac_d_movgest_stato l,
		siac_r_movgest_class m,
		siac_t_class n,
		siac_d_class_tipo o,
		siac_t_bil p,
		siac_t_periodo q
	where a.bil_id=b2.bil_id
	and c2.periodo_id=b2.periodo_id
	and c.movgest_id=b.movgest_id
	and b.elem_id=a.elem_id
	and d.movgest_tipo_id=c.movgest_tipo_id
	and e.movgest_id=c.movgest_id
	and f.movgest_ts_id=e.movgest_ts_id
	and g.movgest_ts_tipo_id=e.movgest_ts_tipo_id
	and h.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
	and i.movgest_ts_id=e.movgest_ts_id
	and l.movgest_stato_id=i.movgest_stato_id
	and m.movgest_ts_id = e.movgest_ts_id
	and n.classif_id = m.classif_id
	and o.classif_tipo_id = n.classif_tipo_id
	and p.bil_id = c.bil_id
	and q.periodo_id = p.periodo_id
	and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
	and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
	and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
	and b.data_cancellazione is null
	and c.data_cancellazione is null
	and d.data_cancellazione is null
	and e.data_cancellazione is null
	and f.data_cancellazione is null
	and g.data_cancellazione is null
	and h.data_cancellazione is null
	and i.data_cancellazione is null
	and l.data_cancellazione is null
	and m.data_cancellazione is null
	and n.data_cancellazione is null
	and o.data_cancellazione is null
	and p.data_cancellazione is null
	and q.data_cancellazione is null
	and d.movgest_tipo_code='I'
	and g.movgest_ts_tipo_code='T'
	and h.movgest_ts_det_tipo_code='A'   
    and l.movgest_stato_code<>'A'
	and o.classif_tipo_code IN ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
	and a.elem_id=_uid_capitolospesa
	and q.anno = _anno
    and (case when coalesce(_filtro_crp,'X')='R' then c.movgest_anno<_anno::integer
                     	when coalesce(_filtro_crp,'X')='C' then c.movgest_anno=_anno::integer
                        when coalesce(_filtro_crp,'X')='P' then c.movgest_anno>_anno::integer
		                else true end); -- 02.07.2018 Sofia jira siac-6193

	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

--SIAC-6939 Fine

-- SIAC-6854- Maurizio - INIZIO

update siac_t_xbrl_mapping_fatti
set  xbrl_mapfat_forza_visibilita=true,
	 xbrl_mapfat_unit_code='eur',
     data_modifica=now(),
     login_operazione=login_operazione|| ' - SIAC-6854'
where xbrl_mapfat_rep_codice='BILR159'
	and xbrl_mapfat_variabile in ('ImpDare','ImpAvere')
    and (xbrl_mapfat_unit_code <> 'eur' OR 
    	xbrl_mapfat_forza_visibilita =false);  
		
        
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR159', 'pdce_conto_codeNoMissProgr', 'DareCE', 'DCACE', 
   '${tuple_group_key_NoMissProgr}', 'd_anno/anno_bilancio*0/', NULL, 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6854', 'duration', true
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and z.xbrl_mapfat_rep_codice='BILR159'
		and z.xbrl_mapfat_variabile='pdce_conto_codeNoMissProgr');	

		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR159', 'ImpDareNoMissProgr', 'DareCE', 'DCACE', 
   '${tuple_group_key_NoMissProgr}', 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6854', 'duration', true
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and z.xbrl_mapfat_rep_codice='BILR159'
		and z.xbrl_mapfat_variabile='ImpDareNoMissProgr');
        
        
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR159', 'ImpAvereNoMissProgr', 'DareCE', 'DCACE', 
   '${tuple_group_key_NoMissProgr}', 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6854', 'duration', true
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and z.xbrl_mapfat_rep_codice='BILR159'
		and z.xbrl_mapfat_variabile='ImpAvereNoMissProgr');


-- SIAC-6854- Maurizio - FINE

-- Inizio SIAC-6693		
		INSERT INTO siac_d_gestione_tipo (gestione_tipo_code, gestione_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, to_timestamp('2019-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('BLOCCO_VINCOLO_DEC', 'Gestione vincoloDecentrato')) AS tmp(code, descr)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_tipo dgt
	WHERE dgt.ente_proprietario_id = tep.ente_proprietario_id
	AND dgt.gestione_tipo_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac_d_gestione_livello (gestione_livello_code, gestione_livello_desc, gestione_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dgt.gestione_tipo_id, to_timestamp('2019-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_gestione_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('BLOCCO_VINCOLO_DEC',  'Gestione vincoloDecentrato', 'BLOCCO_VINCOLO_DEC')) AS tmp(code, descr, tipo)
WHERE dgt.gestione_tipo_code = tmp.tipo
AND NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_livello dgl
	WHERE dgl.ente_proprietario_id = tep.ente_proprietario_id
	AND dgl.gestione_tipo_id = dgt.gestione_tipo_id
	AND dgt.gestione_tipo_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

-- RP
INSERT INTO siac_r_gestione_ente (gestione_livello_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT dgl.gestione_livello_id, to_timestamp('2019-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_gestione_livello dgl ON dgl.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('BLOCCO_VINCOLO_DEC', 'REGIONE PIEMONTE')) AS tmp(livello, ente)
WHERE UPPER(TRANSLATE(tep.ente_denominazione, 'àâãäåāăąÀÁÂÃÄÅĀĂĄèééêëēĕėęěĒĔĖĘĚìíîïìĩīĭÌÍÎÏÌĨĪĬóôõöōŏőÒÓÔÕÖŌŎŐùúûüũūŭůÙÚÛÜŨŪŬŮ''', 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeeeeeiiiiiiiiiiiiiiiiooooooooooooooouuuuuuuuuuuuuuuu')) = tmp.ente
AND dgl.gestione_livello_code = tmp.livello
AND NOT EXISTS (
	SELECT 1
	FROM siac_r_gestione_ente rge
	WHERE rge.ente_proprietario_id = tep.ente_proprietario_id
	AND rge.gestione_livello_id = dgl.gestione_livello_id
	AND rge.data_cancellazione IS NULL
);
/*
INSERT INTO siac_r_gestione_ente (gestione_livello_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT dgl.gestione_livello_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_gestione_livello dgl ON dgl.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('BLOCCO_VINCOLO_DEC', 'REGIONE PIEMONTE')) AS tmp(livello, ente)
WHERE 

UPPER(TRANSLATE(tep.ente_denominazione, 'àâãäåāăąÀÁÂÃÄÅĀĂĄèééêëēĕėęěĒĔĖĘĚìíîïìĩīĭÌÍÎÏÌĨĪĬóôõöōŏőÒÓÔÕÖŌŎŐùúûüũūŭůÙÚÛÜŨŪŬŮ''', 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeeeeeiiiiiiiiiiiiiiiiooooooooooooooouuuuuuuuuuuuuuuu')) = tmp.ente
AND 
dgl.gestione_livello_code = tmp.livello
AND NOT EXISTS (
	SELECT 1
	FROM siac_r_gestione_ente rge
	WHERE rge.ente_proprietario_id = tep.ente_proprietario_id
	AND rge.gestione_livello_id = dgl.gestione_livello_id
	AND rge.data_cancellazione IS NULL  
    
);

select tep.ente_denominazione, 
    UPPER(TRANSLATE(tep.ente_denominazione, 'àâãäåāăąÀÁÂÃÄÅĀĂĄèééêëēĕėęěĒĔĖĘĚìíîïìĩīĭÌÍÎÏÌĨĪĬóôõöōŏőÒÓÔÕÖŌŎŐùúûüũūŭůÙÚÛÜŨŪŬŮ''', 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeeeeeiiiiiiiiiiiiiiiiooooooooooooooouuuuuuuuuuuuuuuu'))
     from siac_t_ente_proprietario tep
     where tep.ente_proprietario_id = 2 and 
     'REGIONE PIEMONTE' = UPPER(TRANSLATE(tep.ente_denominazione, 'àâãäåāăąÀÁÂÃÄÅĀĂĄèééêëēĕėęěĒĔĖĘĚìíîïìĩīĭÌÍÎÏÌĨĪĬóôõöōŏőÒÓÔÕÖŌŎŐùúûüũūŭůÙÚÛÜŨŪŬŮ''', 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeeeeeiiiiiiiiiiiiiiiiooooooooooooooouuuuuuuuuuuuuuuu'));
  */   
-- Fine SIAC-6693

--- 22.07.2019 Sofia siac-6973 - inizio

drop FUNCTION if exists fnc_siac_dwh_programma_cronop
(
  p_ente_proprietario_id integer,
  p_anno_bilancio varchar,
  p_data timestamp
);

CREATE OR REPLACE FUNCTION fnc_siac_dwh_programma_cronop
(
  p_ente_proprietario_id integer,
  p_anno_bilancio varchar,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE


v_user_table varchar;
params varchar;
fnc_eseguita integer;
interval_esec integer:=1;

BEGIN

esito:='fnc_siac_dwh_programma_cronop : inizio - '||clock_timestamp()||'.';
return next;

IF p_ente_proprietario_id IS NULL THEN
	   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo.';
END IF;

IF p_anno_bilancio IS NULL THEN
	   RAISE EXCEPTION 'Errore: Parametro Anno Bilancio nullo.';
END IF;


select count(*) into fnc_eseguita
from siac_dwh_log_elaborazioni log
where log.ente_proprietario_id=p_ente_proprietario_id
and	  log.fnc_elaborazione_inizio >= (now() - interval '13 hours' )::timestamp -- non deve esistere  una elaborazione uguale nelle 13 ore che precedono la chimata
and   log.fnc_name='fnc_siac_dwh_programma_cronop';

-- 22.07.2019 Sofia siac-6973
fnc_eseguita:=0;
if fnc_eseguita<= 0 then
	esito:= 'fnc_siac_dwh_programma_cronop : continue - eseguita da piu'' di '|| interval_esec::varchar||' ore - '||clock_timestamp()||'.';
	return next;


	/* 20.06.2019 Sofia siac-6933
     IF p_data IS NULL THEN
	   IF p_anno_bilancio::integer < to_char(now(),'YYYY')::integer THEN
    	  p_data = to_timestamp('31/12/'||p_anno_bilancio, 'dd/mm/yyyy');
	   ELSE
    	  p_data := now();
	   END IF;
	END IF;*/

	-- 22.07.2019 Sofia siac-6973
    p_data := now();

	select fnc_siac_random_user() into	v_user_table;

	params := p_ente_proprietario_id::varchar||' - '||p_anno_bilancio||' - '||p_data::varchar;


	insert into	siac_dwh_log_elaborazioni
    (
		ente_proprietario_id,
		fnc_name ,
		fnc_parameters ,
		fnc_elaborazione_inizio ,
		fnc_user
	)
	values
    (
		p_ente_proprietario_id,
		'fnc_siac_dwh_programma_cronop',
		params,
		clock_timestamp(),
		v_user_table
	);


	esito:= 'fnc_siac_dwh_programma_cronop : continue - inizio eliminazione dati pregressi (siac_dwh_programma_cronop) - '||clock_timestamp()||'.';
	return next;
	DELETE FROM siac_dwh_programma_cronop
    WHERE ente_proprietario_id = p_ente_proprietario_id;
--    and   programma_cronop_bil_anno=p_anno_bilancio; -- 20.06.2019 SIAC-6933
	esito:= 'fnc_siac_dwh_programma_cronop : continue - fine eliminazione dati pregressi (siac_dwh_programma_cronop) - '||clock_timestamp()||'.';
	return next;

	esito:= 'fnc_siac_dwh_programma_cronop : continue - inizio caricamento programmi-cronop (siac_dwh_programma_cronop) - '||clock_timestamp()||'.';
	RETURN NEXT;

    insert into siac_dwh_programma_cronop
    (
      ente_proprietario_id,
      ente_denominazione,
      programma_code,
      programma_desc,
      programma_stato_code,
      programma_stato_desc,
      programma_ambito_code,
      programma_ambito_desc,
      programma_rilevante_fpv,
      programma_valore_complessivo,
      programma_gara_data_indizione,
      programma_gara_data_aggiudic,
      programma_investimento_in_def,
      programma_note,
      programma_anno_atto_amm,
      programma_num_atto_amm,
      programma_oggetto_atto_amm,
      programma_note_atto_amm,
      programma_code_tipo_atto_amm,
      programma_desc_tipo_atto_amm,
      programma_code_stato_atto_amm,
      programma_desc_stato_atto_amm,
      programma_code_cdr_atto_amm,
      programma_desc_cdr_atto_amm,
      programma_code_cdc_atto_amm,
      programma_desc_cdc_atto_amm,
      programma_cronop_bil_anno,
      programma_cronop_tipo,
      programma_cronop_versione,
      programma_cronop_desc,
      programma_cronop_anno_comp,
      programma_cronop_cap_tipo,
      programma_cronop_cap_articolo,
      programma_cronop_classif_bil,
      programma_cronop_anno_entrata,
      programma_cronop_valore_prev,
      -- 29.04.2019 Sofia jira siac-6255
      -- siac_t_programma
      programma_responsabile_unico,
      programma_spazi_finanziari,
      programma_tipo_code,
      programma_tipo_desc,
      programma_affidamento_code,
      programma_affidamento_desc,
      programma_anno_bilancio,
      -- 20.06.2019 Sofia siac-6933
      programma_sac_tipo,
      programma_sac_code,
      programma_sac_desc,
      programma_cup,
      -- 29.04.2019 Sofia siac-6255
      -- siac_t_cronop
      programma_cronop_data_appfat,
      programma_cronop_data_appdef,
      programma_cronop_data_appesec,
      programma_cronop_data_avviopr,
      programma_cronop_data_agglav,
      programma_cronop_data_inizlav,
      programma_cronop_data_finelav,
      programma_cronop_giorni_dur,
      programma_cronop_data_coll,
      programma_cronop_gest_quad_eco,
      programma_cronop_us_per_fpv_pr,
      programma_cronop_ann_atto_amm,
      programma_cronop_num_atto_amm,
      programma_cronop_ogg_atto_amm,
      programma_cronop_nte_atto_amm,
      programma_cronop_tpc_atto_amm,
      programma_cronop_tpd_atto_amm,
      programma_cronop_stc_atto_amm,
      programma_cronop_std_atto_amm,
      programma_cronop_crc_atto_amm,
      programma_cronop_crd_atto_amm,
      programma_cronop_cdc_atto_amm,
      programma_cronop_cdd_atto_amm,
      -- 20.06.2019 Sofia siac-6933
      entrata_prevista_cronop_entrata,
      programma_cronop_descr_spesa,
      programma_cronop_descr_entrata
    )
    select
      ente.ente_proprietario_id,
      ente.ente_denominazione,
      query.programma_code,
      query.programma_desc,
      query.programma_stato_code,
      query.programma_stato_desc,
      query.programma_ambito_code,
      query.programma_ambito_desc,
      query.programma_rilevante_fpv,
      query.programma_valore_complessivo,
      query.programma_gara_data_indizione,
      query.programma_gara_data_aggiudic,
      query.programma_investimento_in_def,
      query.programma_note,
      query.programma_anno_atto_amm,
      query.programma_num_atto_amm,
      query.programma_oggetto_atto_amm,
      query.programma_note_atto_amm,
      query.programma_code_tipo_atto_amm,
      query.programma_desc_tipo_atto_amm,
      query.programma_code_stato_atto_amm,
      query.programma_desc_stato_atto_amm,
      query.programma_code_cdr_atto_amm,
      query.programma_desc_cdr_atto_amm,
      query.programma_code_cdc_atto_amm,
      query.programma_desc_cdc_atto_amm,
      query.programma_cronop_bil_anno,
      query.programma_cronop_tipo,
      query.programma_cronop_versione,
      query.programma_cronop_desc,
      query.programma_cronop_anno_comp,
      query.programma_cronop_cap_tipo,
      query.programma_cronop_cap_articolo,
      query.programma_cronop_classif_bil,
      query.programma_cronop_anno_entrata,
      query.programma_cronop_valore_prev,
      -- 29.04.2019 Sofia jira siac-6255
      -- siac_t_programma
      query.programma_responsabile_unico,
      query.programma_spazi_finanziari,
      query.programma_tipo_code,
      query.programma_tipo_desc,
      query.programma_affidamento_code,
      query.programma_affidamento_desc,
      query.programma_anno_bilancio,
      -- 20.06.2019 Sofia siac-6933
      query.programma_sac_tipo,
      query.programma_sac_code,
      query.programma_sac_desc,
      query.programma_cup,
      -- 29.04.2019 Sofia siac-6255
      -- siac_t_cronop
      query.cronop_data_approvazione_fattibilita,
      query.cronop_data_approvazione_programma_def,
      query.cronop_data_approvazione_programma_esec,
      query.cronop_data_avvio_procedura,
      query.cronop_data_aggiudicazione_lavori,
      query.cronop_data_inizio_lavori,
      query.cronop_data_fine_lavori,
      query.cronop_giorni_durata,
      query.cronop_data_collaudo,
      query.cronop_gestione_quadro_economico,
      query.cronop_usato_per_fpv_prov,
      query.cronop_anno_atto_amm,
      query.cronop_num_atto_amm,
      query.cronop_oggetto_atto_amm,
      query.cronop_note_atto_amm,
      query.cronop_code_tipo_atto_amm,
      query.cronop_desc_tipo_atto_amm,
      query.cronop_code_stato_atto_amm,
      query.cronop_desc_stato_atto_amm,
      query.cronop_code_cdr_atto_amm,
      query.cronop_desc_cdr_atto_amm,
      query.cronop_code_cdc_atto_amm,
      query.cronop_desc_cdc_atto_amm,
      -- 20.06.2019 Sofia siac-6933
      ''::varchar entrata_prevista_cronop_entrata,
      (case when query.programma_cronop_tipo='U' then query.programma_cronop_desc
        else ''::varchar end) programma_cronop_descr_spesa,
      (case when query.programma_cronop_tipo='E' then query.programma_cronop_desc
        else ''::varchar end) programma_cronop_descr_entrata
    from
    (
    with
    programma as
    (
      select progr.ente_proprietario_id,
             progr.programma_id,
             progr.programma_code,
             progr.programma_desc,
             stato.programma_stato_code,
             stato.programma_stato_desc,
             progr.programma_data_gara_indizione programma_gara_data_indizione,
		     progr.programma_data_gara_aggiudicazione programma_gara_data_aggiudic,
		     progr.investimento_in_definizione programma_investimento_in_def,
             -- 29.04.2019 Sofia siac-6255
             progr.programma_responsabile_unico,
             progr.programma_spazi_finanziari,
             progr.programma_affidamento_id,
             progr.bil_id,
             tipo.programma_tipo_code,
             tipo.programma_tipo_desc
      from siac_t_programma progr, siac_r_programma_stato rs, siac_d_programma_stato stato,
           siac_d_programma_tipo tipo              -- 29.04.2019 Sofia siac-6255
      where stato.ente_proprietario_id=p_ente_proprietario_id
      and   rs.programma_stato_id=stato.programma_stato_id
      and   progr.programma_id=rs.programma_id
      -- 29.04.2019 Sofia siac-6255
      and   tipo.programma_tipo_id=progr.programma_tipo_id
      and   p_data BETWEEN progr.validita_inizio AND COALESCE(progr.validita_fine, p_data)
      and   progr.data_cancellazione is null
      AND   p_data BETWEEN rs.validita_inizio AND COALESCE(rs.validita_fine, p_data)
      and   rs.data_cancellazione  is null
    ),
    progr_ambito_class as
    (
    select rc.programma_id,
           c.classif_code programma_ambito_code,
           c.classif_desc  programma_ambito_desc
    from siac_r_programma_class rc, siac_t_class c, siac_d_class_tipo tipo
    where tipo.ente_proprietario_id=p_ente_proprietario_id
    and   tipo.classif_tipo_code='TIPO_AMBITO'
    and   c.classif_tipo_id=tipo.classif_tipo_id
    and   rc.classif_id=c.classif_id
    and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
    and   rc.data_cancellazione is null
    and   c.data_cancellazione is null
    ),
    -- 20.06.2019 Sofia siac-6933 - inizio
    progr_sac as
    (
    select rc.programma_id,
           tipo.classif_tipo_code programma_sac_tipo,
           c.classif_code programma_sac_code,
           c.classif_desc  programma_sac_desc
    from siac_r_programma_class rc, siac_t_class c, siac_d_class_tipo tipo
    where tipo.ente_proprietario_id=p_ente_proprietario_id
    and   tipo.classif_tipo_code in ('CDC','CDR')
    and   c.classif_tipo_id=tipo.classif_tipo_id
    and   rc.classif_id=c.classif_id
    and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
    and   rc.data_cancellazione is null
    and   c.data_cancellazione is null
    ),
    progr_cup as
    (
    select rattr.programma_id,
           rattr.testo programma_cup
    from siac_r_programma_attr rattr,siac_t_attr attr
    where attr.ente_proprietario_id=p_ente_proprietario_id
    and   attr.attr_code='cup'
    and   rattr.attr_id=attr.attr_id
    and   p_data BETWEEN rattr.validita_inizio AND COALESCE(rattr.validita_fine, p_data)
    and   rattr.data_cancellazione is null
    ),
    -- 20.06.2019 Sofia siac-6933 - fine
    progr_note_attr_ril_fpv as
    (
    select rattr.programma_id,
           rattr.boolean programma_rilevante_fpv
    from siac_r_programma_attr rattr,siac_t_attr attr
    where attr.ente_proprietario_id=p_ente_proprietario_id
    and   attr.attr_code='FlagRilevanteFPV'
    and   rattr.attr_id=attr.attr_id
    and   p_data BETWEEN rattr.validita_inizio AND COALESCE(rattr.validita_fine, p_data)
    and   rattr.data_cancellazione is null
    ),
    progr_note_attr_note as
    (
    select rattr.programma_id,
           rattr.boolean programma_note
    from siac_r_programma_attr rattr,siac_t_attr attr
    where attr.ente_proprietario_id=p_ente_proprietario_id
    and   attr.attr_code='Note'
    and   rattr.attr_id=attr.attr_id
    and   p_data BETWEEN rattr.validita_inizio AND COALESCE(rattr.validita_fine, p_data)
    and   rattr.data_cancellazione is null
    ),
    progr_note_attr_val_compl as
    (
    select rattr.programma_id,
           rattr.numerico programma_valore_complessivo
    from siac_r_programma_attr rattr,siac_t_attr attr
    where attr.ente_proprietario_id=p_ente_proprietario_id
    and   attr.attr_code='ValoreComplessivoProgramma'
    and   rattr.attr_id=attr.attr_id
    and   p_data BETWEEN rattr.validita_inizio AND COALESCE(rattr.validita_fine, p_data)
    and   rattr.data_cancellazione is null
    ),
    progr_atto_amm as
    (
     with
     progr_atto as
     (
      select ratto.programma_id,
             ratto.attoamm_id,
             atto.attoamm_anno        programma_anno_atto_amm,
             atto.attoamm_numero      programma_num_atto_amm,
             atto.attoamm_oggetto     programma_oggetto_atto_amm,
             atto.attoamm_note        programma_note_atto_amm,
             tipo.attoamm_tipo_code   programma_code_tipo_atto_amm,
             tipo.attoamm_tipo_desc   programma_desc_tipo_atto_amm,
             stato.attoamm_stato_code programma_code_stato_atto_amm,
             stato.attoamm_stato_desc programma_desc_stato_atto_amm
      from siac_r_programma_atto_amm ratto , siac_t_atto_amm atto,siac_d_atto_amm_tipo tipo,
           siac_r_atto_amm_stato rs, siac_d_atto_amm_stato stato
      where ratto.ente_proprietario_id=p_ente_proprietario_id
      and   atto.attoamm_id=ratto.attoamm_id
      and   tipo.attoamm_tipo_id=atto.attoamm_tipo_id
      and   rs.attoamm_id=atto.attoamm_id
      and   stato.attoamm_stato_id=rs.attoamm_stato_id
      and   p_data BETWEEN ratto.validita_inizio AND COALESCE(ratto.validita_fine, p_data)
      and   ratto.data_cancellazione is null
      and   p_data BETWEEN atto.validita_inizio AND COALESCE(atto.validita_fine, p_data)
      and   atto.data_cancellazione is null
      and   p_data BETWEEN rs.validita_inizio AND COALESCE(rs.validita_fine, p_data)
      and   rs.data_cancellazione is null
     ),
     atto_cdr as
     (
     select rc.attoamm_id,
            c.classif_code programma_code_cdr_atto_amm,
            c.classif_desc programma_desc_cdr_atto_amm
     from siac_r_atto_amm_class rc, siac_t_class c , siac_d_class_tipo tipo
     where tipo.ente_proprietario_id=p_ente_proprietario_id
     and   tipo.classif_tipo_code='CDR'
     and   c.classif_tipo_id=tipo.classif_tipo_id
     and   rc.classif_id=c.classif_id
     and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
     and   rc.data_cancellazione is null
     and   c.data_cancellazione is null
     ),
     atto_cdc as
     (
     select rc.attoamm_id,
            c.classif_code programma_code_cdc_atto_amm,
            c.classif_desc programma_desc_cdc_atto_amm
     from siac_r_atto_amm_class rc, siac_t_class c , siac_d_class_tipo tipo
     where tipo.ente_proprietario_id=p_ente_proprietario_id
     and   tipo.classif_tipo_code='CDC'
     and   c.classif_tipo_id=tipo.classif_tipo_id
     and   rc.classif_id=c.classif_id
     and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
     and   rc.data_cancellazione is null
     and   c.data_cancellazione is null
     )
     select progr_atto.*,
            atto_cdr.programma_code_cdr_atto_amm,
            atto_cdr.programma_desc_cdr_atto_amm,
            atto_cdc.programma_code_cdc_atto_amm,
            atto_cdc.programma_desc_cdc_atto_amm
     from progr_atto
           left join atto_cdr on (progr_atto.attoamm_id=atto_cdr.attoamm_id)
           left join atto_cdc on (progr_atto.attoamm_id=atto_cdc.attoamm_id)
    ),
    -- 29.04.2019 Sofia siac-6255
    progr_affid as
    (
     select aff.programma_affidamento_code,
            aff.programma_affidamento_desc,
            aff.programma_affidamento_id
     from  siac_d_programma_affidamento aff
     where aff.ente_proprietario_id=p_ente_proprietario_id
    ),
    progr_bil_anno as
    (
    select bil.bil_id, per.anno anno_bilancio
    from siac_t_bil bil,siac_t_periodo per
    where bil.ente_proprietario_id=p_ente_proprietario_id
    and   per.periodo_id=bil.periodo_id
    ),
    cronop_progr as
    (
    with
     cronop_entrata as
     (
       with
         ce as
         (
           select cronop.programma_id,
                  per_bil.anno::varchar programma_cronop_bil_anno,
                  'E'::varchar programma_cronop_tipo,
                  cronop.cronop_code programma_cronop_versione,
                  cronop.cronop_desc programma_cronop_desc,
                  -- 29.04.2019 Sofia jira siac-6255
                  cronop.cronop_id,
                  cronop.cronop_data_approvazione_fattibilita,
                  cronop.cronop_data_approvazione_programma_def,
                  cronop.cronop_data_approvazione_programma_esec,
                  cronop.cronop_data_avvio_procedura,
                  cronop.cronop_data_aggiudicazione_lavori,
                  cronop.cronop_data_inizio_lavori,
                  cronop.cronop_data_fine_lavori,
                  cronop.cronop_giorni_durata,
                  cronop.cronop_data_collaudo,
                  cronop.gestione_quadro_economico,
                  cronop.usato_per_fpv_prov,
                  -- 29.04.2019 Sofia jira siac-6255
                  per.anno::varchar  programma_cronop_anno_comp,
                  tipo.elem_tipo_code programma_cronop_cap_tipo,
                  cronop_elem.cronop_elem_code||'/'||cronop_elem.cronop_elem_code2 programma_cronop_cap_articolo,
                  ''::varchar programma_cronop_anno_entrata,
                  cronop_elem_det.cronop_elem_det_importo programma_cronop_valore_prev,
                  cronop_elem.cronop_elem_id
           from siac_t_cronop cronop,siac_r_cronop_stato rs, siac_d_cronop_stato stato,
                siac_t_bil bil, siac_t_periodo per_bil,
                siac_t_periodo per,
                siac_t_cronop_elem cronop_elem,
                siac_d_bil_elem_tipo tipo,
                siac_t_cronop_elem_det cronop_elem_det
           where stato.ente_proprietario_id=p_ente_proprietario_id
           and   stato.cronop_stato_code='VA'
           and   rs.cronop_stato_id=stato.cronop_stato_id
           and   cronop.cronop_id=rs.cronop_id
           and   bil.bil_id=cronop.bil_id
           and   per_bil.periodo_id=bil.periodo_id
--           and   per_bil.anno::integer=p_anno_bilancio::integer
--           and   per_bil.anno::integer<=p_anno_bilancio::integer           --- 20.06.2019 Sofia siac-6933
           and   cronop_elem.cronop_id=cronop.cronop_id
           and   tipo.elem_tipo_id=cronop_elem.elem_tipo_id
           and   tipo.elem_tipo_code in ('CAP-EP','CAP-EG')
           and   cronop_elem_det.cronop_elem_id=cronop_elem.cronop_elem_id
           and   per.periodo_id=cronop_elem_det.periodo_id
           and   p_data BETWEEN rs.validita_inizio AND COALESCE(rs.validita_fine, p_data)
           and   rs.data_cancellazione is null
           and   p_data BETWEEN cronop.validita_inizio AND COALESCE(cronop.validita_fine, p_data)
           and   cronop.data_cancellazione is null
           and   p_data BETWEEN cronop_elem.validita_inizio AND COALESCE(cronop_elem.validita_fine, p_data)
           and   cronop_elem.data_cancellazione is null
           and   p_data BETWEEN cronop_elem_det.validita_inizio AND COALESCE(cronop_elem_det.validita_fine, p_data)
           and   cronop_elem_det.data_cancellazione is null
         ),
         classif_bil as
         (
            select distinct
                   r_cronp_class.cronop_elem_id,
		           titolo.classif_code            				titolo_code ,
	               titolo.classif_desc            				titolo_desc,
	               tipologia.classif_code           			tipologia_code,
	               tipologia.classif_desc           			tipologia_desc
            from siac_t_class_fam_tree 			titolo_tree,
            	 siac_d_class_fam 				titolo_fam,
	             siac_r_class_fam_tree 			titolo_r_cft,
	             siac_t_class 					titolo,
	             siac_d_class_tipo 				titolo_tipo,
	             siac_d_class_tipo 				tipologia_tipo,
     	         siac_t_class 					tipologia,
	             siac_r_cronop_elem_class		r_cronp_class
            where 	titolo_fam.classif_fam_desc					=	'Entrata - TitoliTipologieCategorie'
            and 	titolo_tree.classif_fam_id					=	titolo_fam.classif_fam_id
            and 	titolo_r_cft.classif_fam_tree_id			=	titolo_tree.classif_fam_tree_id
            and 	titolo.classif_id							=	titolo_r_cft.classif_id_padre
            and 	titolo_tipo.classif_tipo_code				=	'TITOLO_ENTRATA'
            and 	titolo.classif_tipo_id						=	titolo_tipo.classif_tipo_id
            and 	tipologia_tipo.classif_tipo_code			=	'TIPOLOGIA'
            and 	tipologia.classif_tipo_id					=	tipologia_tipo.classif_tipo_id
            and 	titolo_r_cft.classif_id						=	tipologia.classif_id
            and 	r_cronp_class.classif_id					=	tipologia.classif_id
            and 	titolo.ente_proprietario_id					=	p_ente_proprietario_id
            and 	titolo.data_cancellazione					is null
            and 	tipologia.data_cancellazione				is null
            and		r_cronp_class.data_cancellazione			is null
            and 	titolo_tree.data_cancellazione				is null
            and 	titolo_fam.data_cancellazione				is null
            and 	titolo_r_cft.data_cancellazione				is null
            and 	titolo_tipo.data_cancellazione				is null
            and 	tipologia_tipo.data_cancellazione			is null
          ),
          -- 29.04.2019 Sofia jira siac-6255
          cronop_atto_amm as
          (
           with
           cronop_atto as
           (
            select ratto.cronop_id,
                   ratto.attoamm_id,
                   atto.attoamm_anno        cronop_anno_atto_amm,
                   atto.attoamm_numero      cronop_num_atto_amm,
                   atto.attoamm_oggetto     cronop_oggetto_atto_amm,
                   atto.attoamm_note        cronop_note_atto_amm,
                   tipo.attoamm_tipo_code   cronop_code_tipo_atto_amm,
                   tipo.attoamm_tipo_desc   cronop_desc_tipo_atto_amm,
                   stato.attoamm_stato_code cronop_code_stato_atto_amm,
                   stato.attoamm_stato_desc cronop_desc_stato_atto_amm
            from siac_r_cronop_atto_amm ratto , siac_t_atto_amm atto,siac_d_atto_amm_tipo tipo,
                 siac_r_atto_amm_stato rs, siac_d_atto_amm_stato stato
            where ratto.ente_proprietario_id=p_ente_proprietario_id
            and   atto.attoamm_id=ratto.attoamm_id
            and   tipo.attoamm_tipo_id=atto.attoamm_tipo_id
            and   rs.attoamm_id=atto.attoamm_id
            and   stato.attoamm_stato_id=rs.attoamm_stato_id
            and   p_data BETWEEN ratto.validita_inizio AND COALESCE(ratto.validita_fine, p_data)
            and   ratto.data_cancellazione is null
            and   p_data BETWEEN atto.validita_inizio AND COALESCE(atto.validita_fine, p_data)
            and   atto.data_cancellazione is null
            and   p_data BETWEEN rs.validita_inizio AND COALESCE(rs.validita_fine, p_data)
            and   rs.data_cancellazione is null
           ),
           cronop_atto_cdr as
           (
           select rc.attoamm_id,
                  c.classif_code cronop_code_cdr_atto_amm,
                  c.classif_desc cronop_desc_cdr_atto_amm
           from siac_r_atto_amm_class rc, siac_t_class c , siac_d_class_tipo tipo
           where tipo.ente_proprietario_id=p_ente_proprietario_id
           and   tipo.classif_tipo_code='CDR'
           and   c.classif_tipo_id=tipo.classif_tipo_id
           and   rc.classif_id=c.classif_id
           and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
           and   rc.data_cancellazione is null
           and   c.data_cancellazione is null
           ),
           cronop_atto_cdc as
           (
           select rc.attoamm_id,
                  c.classif_code cronop_code_cdc_atto_amm,
                  c.classif_desc cronop_desc_cdc_atto_amm
           from siac_r_atto_amm_class rc, siac_t_class c , siac_d_class_tipo tipo
           where tipo.ente_proprietario_id=p_ente_proprietario_id
           and   tipo.classif_tipo_code='CDC'
           and   c.classif_tipo_id=tipo.classif_tipo_id
           and   rc.classif_id=c.classif_id
           and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
           and   rc.data_cancellazione is null
           and   c.data_cancellazione is null
           )
           select cronop_atto.*,
                  cronop_atto_cdr.cronop_code_cdr_atto_amm,
                  cronop_atto_cdr.cronop_desc_cdr_atto_amm,
                  cronop_atto_cdc.cronop_code_cdc_atto_amm,
                  cronop_atto_cdc.cronop_desc_cdc_atto_amm
           from cronop_atto
                 left join cronop_atto_cdr on (cronop_atto.attoamm_id=cronop_atto_cdr.attoamm_id)
                 left join cronop_atto_cdc on (cronop_atto.attoamm_id=cronop_atto_cdc.attoamm_id)
          )
          select ce.programma_id,
                 ce.programma_cronop_bil_anno,
                 ce.programma_cronop_tipo,
                 ce.programma_cronop_versione,
                 ce.programma_cronop_desc,
                 ce.programma_cronop_anno_comp,
                 ce.programma_cronop_cap_tipo,
                 ce.programma_cronop_cap_articolo,
                 (coalesce(classif_bil.titolo_code,' ') ||' - ' ||coalesce(classif_bil.tipologia_code,' '))::varchar programma_cronop_classif_bil,
                 ce.programma_cronop_anno_entrata,
                 ce.programma_cronop_valore_prev,
                 -- 29.04.2019 Sofia jira siac-6255
                 ce.cronop_id,
                 ce.cronop_data_approvazione_fattibilita,
                 ce.cronop_data_approvazione_programma_def,
                 ce.cronop_data_approvazione_programma_esec,
                 ce.cronop_data_avvio_procedura,
                 ce.cronop_data_aggiudicazione_lavori,
                 ce.cronop_data_inizio_lavori,
                 ce.cronop_data_fine_lavori,
                 ce.cronop_giorni_durata,
                 ce.cronop_data_collaudo,
                 ce.gestione_quadro_economico cronop_gestione_quadro_economico,
                 ce.usato_per_fpv_prov cronop_usato_per_fpv_prov,
                 cronop_atto_amm.cronop_anno_atto_amm,
		         cronop_atto_amm.cronop_num_atto_amm,
                 cronop_atto_amm.cronop_oggetto_atto_amm,
                 cronop_atto_amm.cronop_note_atto_amm,
                 cronop_atto_amm.cronop_code_tipo_atto_amm,
                 cronop_atto_amm.cronop_desc_tipo_atto_amm,
                 cronop_atto_amm.cronop_code_stato_atto_amm,
                 cronop_atto_amm.cronop_desc_stato_atto_amm,
                 cronop_atto_amm.cronop_code_cdr_atto_amm,
                 cronop_atto_amm.cronop_desc_cdr_atto_amm,
                 cronop_atto_amm.cronop_code_cdc_atto_amm,
                 cronop_atto_amm.cronop_desc_cdc_atto_amm
          from ce
               left join classif_bil on (ce.cronop_elem_id=classif_bil.cronop_elem_id)
               -- 29.04.2019 Sofia jira siac-6255
               left join cronop_atto_amm on (ce.cronop_id=cronop_atto_amm.cronop_id)

     ),
     cronop_uscita as
     (
     with
     ce as
     (
       select cronop.programma_id,
              per_bil.anno::varchar programma_cronop_bil_anno,
              'U'::varchar programma_cronop_tipo,
              cronop.cronop_code programma_cronop_versione,
              cronop.cronop_desc programma_cronop_desc,
              -- 29.04.2019 Sofia jira siac-6255
              cronop.cronop_id,
              cronop.cronop_data_approvazione_fattibilita,
              cronop.cronop_data_approvazione_programma_def,
              cronop.cronop_data_approvazione_programma_esec,
              cronop.cronop_data_avvio_procedura,
              cronop.cronop_data_aggiudicazione_lavori,
              cronop.cronop_data_inizio_lavori,
              cronop.cronop_data_fine_lavori,
              cronop.cronop_giorni_durata,
              cronop.cronop_data_collaudo,
              cronop.gestione_quadro_economico,
              cronop.usato_per_fpv_prov,
              -- 29.04.2019 Sofia jira siac-6255
              per.anno::varchar  programma_cronop_anno_comp,
              tipo.elem_tipo_code programma_cronop_cap_tipo,
              cronop_elem.cronop_elem_code||'/'||cronop_elem.cronop_elem_code2 programma_cronop_cap_articolo,
              cronop_elem_det.anno_entrata::varchar programma_cronop_anno_entrata,
              cronop_elem_det.cronop_elem_det_importo programma_cronop_valore_prev,
              cronop_elem.cronop_elem_id
       from siac_t_cronop cronop,siac_r_cronop_stato rs, siac_d_cronop_stato stato,
            siac_t_bil bil, siac_t_periodo per_bil,
            siac_t_periodo per,
            siac_t_cronop_elem cronop_elem,
            siac_d_bil_elem_tipo tipo,
            siac_t_cronop_elem_det cronop_elem_det
       where stato.ente_proprietario_id=p_ente_proprietario_id
       and   stato.cronop_stato_code='VA'
       and   rs.cronop_stato_id=stato.cronop_stato_id
       and   cronop.cronop_id=rs.cronop_id
       and   bil.bil_id=cronop.bil_id
       and   per_bil.periodo_id=bil.periodo_id
 --      and   per_bil.anno::integer=p_anno_bilancio::integer
 --      and   per_bil.anno::integer<=p_anno_bilancio::integer           --- 20.06.2019 Sofia siac-6933

       and   cronop_elem.cronop_id=cronop.cronop_id
       and   tipo.elem_tipo_id=cronop_elem.elem_tipo_id
       and   tipo.elem_tipo_code in ('CAP-UP','CAP-UG')
       and   cronop_elem_det.cronop_elem_id=cronop_elem.cronop_elem_id
       and   per.periodo_id=cronop_elem_det.periodo_id
       and   p_data BETWEEN rs.validita_inizio AND COALESCE(rs.validita_fine, p_data)
       and   rs.data_cancellazione is null
       and   p_data BETWEEN cronop.validita_inizio AND COALESCE(cronop.validita_fine, p_data)
       and   cronop.data_cancellazione is null
       and   p_data BETWEEN cronop_elem.validita_inizio AND COALESCE(cronop_elem.validita_fine, p_data)
       and   cronop_elem.data_cancellazione is null
       and   p_data BETWEEN cronop_elem_det.validita_inizio AND COALESCE(cronop_elem_det.validita_fine, p_data)
       and   cronop_elem_det.data_cancellazione is null
     ),
     classif_bil as
     (
        select  distinct
        		r_cronp_class_titolo.cronop_elem_id,
		        missione.classif_code 					missione_code,
		        missione.classif_desc 					missione_desc,
		        programma.classif_code 					programma_code,
		        programma.classif_desc 					programma_desc,
		        titusc.classif_code 					titolo_code,
		        titusc.classif_desc 					titolo_desc
        from siac_t_class_fam_tree 			missione_tree,
             siac_d_class_fam 				missione_fam,
	         siac_r_class_fam_tree 			missione_r_cft,
	         siac_t_class 					missione,
	         siac_d_class_tipo 				missione_tipo ,
     	     siac_d_class_tipo 				programma_tipo,
	         siac_t_class 					programma,
      	     siac_t_class_fam_tree 			titusc_tree,
	         siac_d_class_fam 				titusc_fam,
	         siac_r_class_fam_tree 			titusc_r_cft,
	         siac_t_class 					titusc,
	         siac_d_class_tipo 				titusc_tipo,
	         siac_r_cronop_elem_class		r_cronp_class_programma,
	         siac_r_cronop_elem_class		r_cronp_class_titolo
        where missione_fam.classif_fam_desc						=	'Spesa - MissioniProgrammi'
        and	  missione_tree.classif_fam_id				=	missione_fam.classif_fam_id
        and	  missione_r_cft.classif_fam_tree_id			=	missione_tree.classif_fam_tree_id
        and	  missione.classif_id							=	missione_r_cft.classif_id_padre
        and	  missione_tipo.classif_tipo_code				=	'MISSIONE'
        and	  missione.classif_tipo_id					=	missione_tipo.classif_tipo_id
        and	  programma_tipo.classif_tipo_code			=	'PROGRAMMA'
        and	  programma.classif_tipo_id					=	programma_tipo.classif_tipo_id
        and	  missione_r_cft.classif_id					=	programma.classif_id
        and	  programma.classif_id						=	r_cronp_class_programma.classif_id
        and	  titusc_fam.classif_fam_desc					=	'Spesa - TitoliMacroaggregati'
        and	  titusc_tree.classif_fam_id					=	titusc_fam.classif_fam_id
        and	  titusc_r_cft.classif_fam_tree_id			=	titusc_tree.classif_fam_tree_id
        and	  titusc.classif_id							=	titusc_r_cft.classif_id_padre
        and	  titusc_tipo.classif_tipo_code				=	'TITOLO_SPESA'
        and	  titusc.classif_tipo_id						=	titusc_tipo.classif_tipo_id
        and	  titusc.classif_id							=	r_cronp_class_titolo.classif_id
        and   r_cronp_class_programma.cronop_elem_id		= 	r_cronp_class_titolo.cronop_elem_id
        and   missione_tree.ente_proprietario_id			=	p_ente_proprietario_id
        and   missione_tree.data_cancellazione			is null
        and   missione_fam.data_cancellazione			is null
        AND   missione_r_cft.data_cancellazione			is null
        and   missione.data_cancellazione				is null
        AND   missione_tipo.data_cancellazione			is null
        AND   programma_tipo.data_cancellazione			is null
        AND   programma.data_cancellazione				is null
        and   titusc_tree.data_cancellazione			is null
        AND   titusc_fam.data_cancellazione				is null
        and   titusc_r_cft.data_cancellazione			is null
        and   titusc.data_cancellazione					is null
        AND   titusc_tipo.data_cancellazione			is null
        and	  r_cronp_class_titolo.data_cancellazione	is null
     ),
     -- 29.04.2019 Sofia jira siac-6255
     cronop_atto_amm as
     (
       with
       cronop_atto as
       (
        select ratto.cronop_id,
               ratto.attoamm_id,
               atto.attoamm_anno        cronop_anno_atto_amm,
               atto.attoamm_numero      cronop_num_atto_amm,
               atto.attoamm_oggetto     cronop_oggetto_atto_amm,
               atto.attoamm_note        cronop_note_atto_amm,
               tipo.attoamm_tipo_code   cronop_code_tipo_atto_amm,
               tipo.attoamm_tipo_desc   cronop_desc_tipo_atto_amm,
               stato.attoamm_stato_code cronop_code_stato_atto_amm,
               stato.attoamm_stato_desc cronop_desc_stato_atto_amm
        from siac_r_cronop_atto_amm ratto , siac_t_atto_amm atto,siac_d_atto_amm_tipo tipo,
             siac_r_atto_amm_stato rs, siac_d_atto_amm_stato stato
        where ratto.ente_proprietario_id=p_ente_proprietario_id
        and   atto.attoamm_id=ratto.attoamm_id
        and   tipo.attoamm_tipo_id=atto.attoamm_tipo_id
        and   rs.attoamm_id=atto.attoamm_id
        and   stato.attoamm_stato_id=rs.attoamm_stato_id
        and   p_data BETWEEN ratto.validita_inizio AND COALESCE(ratto.validita_fine, p_data)
        and   ratto.data_cancellazione is null
        and   p_data BETWEEN atto.validita_inizio AND COALESCE(atto.validita_fine, p_data)
        and   atto.data_cancellazione is null
        and   p_data BETWEEN rs.validita_inizio AND COALESCE(rs.validita_fine, p_data)
        and   rs.data_cancellazione is null
       ),
       cronop_atto_cdr as
       (
       select rc.attoamm_id,
              c.classif_code cronop_code_cdr_atto_amm,
              c.classif_desc cronop_desc_cdr_atto_amm
       from siac_r_atto_amm_class rc, siac_t_class c , siac_d_class_tipo tipo
       where tipo.ente_proprietario_id=p_ente_proprietario_id
       and   tipo.classif_tipo_code='CDR'
       and   c.classif_tipo_id=tipo.classif_tipo_id
       and   rc.classif_id=c.classif_id
       and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
       and   rc.data_cancellazione is null
       and   c.data_cancellazione is null
       ),
       cronop_atto_cdc as
       (
       select rc.attoamm_id,
              c.classif_code cronop_code_cdc_atto_amm,
              c.classif_desc cronop_desc_cdc_atto_amm
       from siac_r_atto_amm_class rc, siac_t_class c , siac_d_class_tipo tipo
       where tipo.ente_proprietario_id=p_ente_proprietario_id
       and   tipo.classif_tipo_code='CDC'
       and   c.classif_tipo_id=tipo.classif_tipo_id
       and   rc.classif_id=c.classif_id
       and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
       and   rc.data_cancellazione is null
       and   c.data_cancellazione is null
       )
       select cronop_atto.*,
              cronop_atto_cdr.cronop_code_cdr_atto_amm,
              cronop_atto_cdr.cronop_desc_cdr_atto_amm,
              cronop_atto_cdc.cronop_code_cdc_atto_amm,
              cronop_atto_cdc.cronop_desc_cdc_atto_amm
       from cronop_atto
             left join cronop_atto_cdr on (cronop_atto.attoamm_id=cronop_atto_cdr.attoamm_id)
             left join cronop_atto_cdc on (cronop_atto.attoamm_id=cronop_atto_cdc.attoamm_id)
     )
     select ce.programma_id,
            ce.programma_cronop_bil_anno,
            ce.programma_cronop_tipo,
            ce.programma_cronop_versione,
            ce.programma_cronop_desc,
            ce.programma_cronop_anno_comp,
            ce.programma_cronop_cap_tipo,
            ce.programma_cronop_cap_articolo,
            (coalesce(classif_bil.missione_code,' ')||
             ' - '||coalesce(classif_bil.programma_code,' ')||
             ' - '||coalesce(classif_bil.titolo_code,' '))::varchar programma_cronop_classif_bil,
            ce.programma_cronop_anno_entrata,
            ce.programma_cronop_valore_prev,
            -- 29.04.2019 Sofia jira siac-6255
            ce.cronop_id,
            ce.cronop_data_approvazione_fattibilita,
            ce.cronop_data_approvazione_programma_def,
            ce.cronop_data_approvazione_programma_esec,
            ce.cronop_data_avvio_procedura,
            ce.cronop_data_aggiudicazione_lavori,
            ce.cronop_data_inizio_lavori,
            ce.cronop_data_fine_lavori,
            ce.cronop_giorni_durata,
            ce.cronop_data_collaudo,
            ce.gestione_quadro_economico cronop_gestione_quadro_economico,
            ce.usato_per_fpv_prov cronop_usato_per_fpv_prov,
            cronop_atto_amm.cronop_anno_atto_amm,
            cronop_atto_amm.cronop_num_atto_amm,
            cronop_atto_amm.cronop_oggetto_atto_amm,
            cronop_atto_amm.cronop_note_atto_amm,
            cronop_atto_amm.cronop_code_tipo_atto_amm,
            cronop_atto_amm.cronop_desc_tipo_atto_amm,
            cronop_atto_amm.cronop_code_stato_atto_amm,
            cronop_atto_amm.cronop_desc_stato_atto_amm,
            cronop_atto_amm.cronop_code_cdr_atto_amm,
            cronop_atto_amm.cronop_desc_cdr_atto_amm,
            cronop_atto_amm.cronop_code_cdc_atto_amm,
            cronop_atto_amm.cronop_desc_cdc_atto_amm
     from ce
          left join classif_bil on (ce.cronop_elem_id=classif_bil.cronop_elem_id)
          -- 29.04.2019 Sofia jira siac-6255
          left join cronop_atto_amm on ( ce.cronop_id=cronop_atto_amm.cronop_id)
     )
     select cronop_entrata.programma_id,
     	    cronop_entrata.programma_cronop_bil_anno,
            cronop_entrata.programma_cronop_tipo,
            cronop_entrata.programma_cronop_versione,
            cronop_entrata.programma_cronop_desc,
	        cronop_entrata.programma_cronop_anno_comp,
            cronop_entrata.programma_cronop_cap_tipo,
	        cronop_entrata.programma_cronop_cap_articolo,
	        cronop_entrata.programma_cronop_classif_bil,
	        cronop_entrata.programma_cronop_anno_entrata,
            cronop_entrata.programma_cronop_valore_prev,
            -- 29.04.2019 Sofia jira siac-6255
            cronop_entrata.cronop_id,
            cronop_entrata.cronop_data_approvazione_fattibilita,
            cronop_entrata.cronop_data_approvazione_programma_def,
            cronop_entrata.cronop_data_approvazione_programma_esec,
            cronop_entrata.cronop_data_avvio_procedura,
            cronop_entrata.cronop_data_aggiudicazione_lavori,
            cronop_entrata.cronop_data_inizio_lavori,
            cronop_entrata.cronop_data_fine_lavori,
            cronop_entrata.cronop_giorni_durata,
            cronop_entrata.cronop_data_collaudo,
            cronop_entrata.cronop_gestione_quadro_economico,
            cronop_entrata.cronop_usato_per_fpv_prov,
            cronop_entrata.cronop_anno_atto_amm,
            cronop_entrata.cronop_num_atto_amm,
            cronop_entrata.cronop_oggetto_atto_amm,
            cronop_entrata.cronop_note_atto_amm,
            cronop_entrata.cronop_code_tipo_atto_amm,
            cronop_entrata.cronop_desc_tipo_atto_amm,
            cronop_entrata.cronop_code_stato_atto_amm,
            cronop_entrata.cronop_desc_stato_atto_amm,
            cronop_entrata.cronop_code_cdr_atto_amm,
            cronop_entrata.cronop_desc_cdr_atto_amm,
            cronop_entrata.cronop_code_cdc_atto_amm,
            cronop_entrata.cronop_desc_cdc_atto_amm
     from cronop_entrata
     union
     select cronop_uscita.programma_id,
     	    cronop_uscita.programma_cronop_bil_anno,
            cronop_uscita.programma_cronop_tipo,
            cronop_uscita.programma_cronop_versione,
            cronop_uscita.programma_cronop_desc,
	        cronop_uscita.programma_cronop_anno_comp,
            cronop_uscita.programma_cronop_cap_tipo,
	        cronop_uscita.programma_cronop_cap_articolo,
	        cronop_uscita.programma_cronop_classif_bil,
	        cronop_uscita.programma_cronop_anno_entrata,
            cronop_uscita.programma_cronop_valore_prev,
            -- 29.04.2019 Sofia jira siac-6255
            cronop_uscita.cronop_id,
            cronop_uscita.cronop_data_approvazione_fattibilita,
            cronop_uscita.cronop_data_approvazione_programma_def,
            cronop_uscita.cronop_data_approvazione_programma_esec,
            cronop_uscita.cronop_data_avvio_procedura,
            cronop_uscita.cronop_data_aggiudicazione_lavori,
            cronop_uscita.cronop_data_inizio_lavori,
            cronop_uscita.cronop_data_fine_lavori,
            cronop_uscita.cronop_giorni_durata,
            cronop_uscita.cronop_data_collaudo,
            cronop_uscita.cronop_gestione_quadro_economico,
            cronop_uscita.cronop_usato_per_fpv_prov,
            cronop_uscita.cronop_anno_atto_amm,
            cronop_uscita.cronop_num_atto_amm,
            cronop_uscita.cronop_oggetto_atto_amm,
            cronop_uscita.cronop_note_atto_amm,
            cronop_uscita.cronop_code_tipo_atto_amm,
            cronop_uscita.cronop_desc_tipo_atto_amm,
            cronop_uscita.cronop_code_stato_atto_amm,
            cronop_uscita.cronop_desc_stato_atto_amm,
            cronop_uscita.cronop_code_cdr_atto_amm,
            cronop_uscita.cronop_desc_cdr_atto_amm,
            cronop_uscita.cronop_code_cdc_atto_amm,
            cronop_uscita.cronop_desc_cdc_atto_amm
     from cronop_uscita
    )
    select programma.*,
           progr_ambito_class.programma_ambito_code,
           progr_ambito_class.programma_ambito_desc,
           progr_note_attr_ril_fpv.programma_rilevante_fpv,
           progr_note_attr_note.programma_note,
           progr_note_attr_val_compl.programma_valore_complessivo,
           progr_atto_amm.programma_anno_atto_amm,
           progr_atto_amm.programma_num_atto_amm,
           progr_atto_amm.programma_oggetto_atto_amm,
           progr_atto_amm.programma_note_atto_amm,
           progr_atto_amm.programma_code_tipo_atto_amm,
           progr_atto_amm.programma_desc_tipo_atto_amm,
           progr_atto_amm.programma_code_stato_atto_amm,
           progr_atto_amm.programma_desc_stato_atto_amm,
           progr_atto_amm.programma_code_cdr_atto_amm,
           progr_atto_amm.programma_desc_cdr_atto_amm,
           progr_atto_amm.programma_code_cdc_atto_amm,
           progr_atto_amm.programma_desc_cdc_atto_amm,
           -- 29.04.2019 Sofia siac-6255
           progr_affid.programma_affidamento_code,
           progr_affid.programma_affidamento_desc,
           progr_bil_anno.anno_bilancio programma_anno_bilancio,
           -- 20.06.2019 Sofia siac-6933
           progr_sac.programma_sac_tipo,
           progr_sac.programma_sac_code,
           progr_sac.programma_sac_desc,
           progr_cup.programma_cup,
           -- 29.04.2019 Sofia siac-6255
	       cronop_progr.programma_cronop_bil_anno,
           cronop_progr.programma_cronop_tipo,
           cronop_progr.programma_cronop_versione,
      	   cronop_progr.programma_cronop_desc,
	       cronop_progr.programma_cronop_anno_comp,
	       cronop_progr.programma_cronop_cap_tipo,
	       cronop_progr.programma_cronop_cap_articolo,
	       cronop_progr.programma_cronop_classif_bil,
		   cronop_progr.programma_cronop_anno_entrata,
	       cronop_progr.programma_cronop_valore_prev,
           -- 29.04.2019 Sofia siac-6255
           cronop_progr.cronop_data_approvazione_fattibilita,
           cronop_progr.cronop_data_approvazione_programma_def,
           cronop_progr.cronop_data_approvazione_programma_esec,
           cronop_progr.cronop_data_avvio_procedura,
           cronop_progr.cronop_data_aggiudicazione_lavori,
           cronop_progr.cronop_data_inizio_lavori,
           cronop_progr.cronop_data_fine_lavori,
           cronop_progr.cronop_giorni_durata,
           cronop_progr.cronop_data_collaudo,
           cronop_progr.cronop_gestione_quadro_economico,
           cronop_progr.cronop_usato_per_fpv_prov,
           cronop_progr.cronop_anno_atto_amm,
           cronop_progr.cronop_num_atto_amm,
           cronop_progr.cronop_oggetto_atto_amm,
           cronop_progr.cronop_note_atto_amm,
           cronop_progr.cronop_code_tipo_atto_amm,
           cronop_progr.cronop_desc_tipo_atto_amm,
           cronop_progr.cronop_code_stato_atto_amm,
           cronop_progr.cronop_desc_stato_atto_amm,
           cronop_progr.cronop_code_cdr_atto_amm,
           cronop_progr.cronop_desc_cdr_atto_amm,
           cronop_progr.cronop_code_cdc_atto_amm,
           cronop_progr.cronop_desc_cdc_atto_amm
    from cronop_progr,
         programma
          left join progr_ambito_class           on (programma.programma_id=progr_ambito_class.programma_id)
          left join progr_note_attr_ril_fpv      on (programma.programma_id=progr_note_attr_ril_fpv.programma_id)
          left join progr_note_attr_note         on (programma.programma_id=progr_note_attr_note.programma_id)
          left join progr_note_attr_val_compl    on (programma.programma_id=progr_note_attr_val_compl.programma_id)
          left join progr_atto_amm               on (programma.programma_id=progr_atto_amm.programma_id)
          -- 20.06.2019 Sofia siac-6933
          left join progr_sac					 on (programma.programma_id=progr_sac.programma_id)
          left join progr_cup					 on (programma.programma_id=progr_cup.programma_id)
          -- 29.04.2019 Sofia jira siac-6255
          left join  progr_affid                 on (programma.programma_affidamento_id=progr_affid.programma_affidamento_id)
          left  join  progr_bil_anno              on (programma.bil_id=progr_bil_anno.bil_id)
    where programma.programma_id=cronop_progr.programma_id
    ) query,siac_t_ente_proprietario ente
    where ente.ente_proprietario_id=p_ente_proprietario_id
    and   query.ente_proprietario_id=ente.ente_proprietario_id;


	esito:= 'fnc_siac_dwh_programma_cronop : continue - aggiornamento durata su  siac_dwh_log_elaborazioni - '||clock_timestamp()||'.';
	update siac_dwh_log_elaborazioni
    set    fnc_elaborazione_fine = clock_timestamp(),
	       fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
	where  fnc_user=v_user_table;
	return next;

    esito:= 'fnc_siac_dwh_programma_cronop : fine - esito OK  - '||clock_timestamp()||'.';
    return next;
else
	esito:= 'fnc_siac_dwh_programma_cronop : fine - eseguita da meno di '|| interval_esec::varchar||' ore - '||clock_timestamp()||'.';

	return next;

end if;

return;

EXCEPTION
 WHEN RAISE_EXCEPTION THEN
  esito:='fnc_siac_dwh_programma_cronop : fine con errori - '||clock_timestamp();
  esito:=esito||' - '||SQLSTATE||'-'||substring(upper(SQLERRM) from 1 for 2500)||'.';
  RAISE NOTICE '%',esito;
  RETURN next;
  return;
 WHEN others THEN
  esito:='fnc_siac_dwh_programma_cronop : fine con errori - '||clock_timestamp();
  esito:=esito||' - '||SQLSTATE||'-'||substring(upper(SQLERRM) from 1 for 2500)||'.';
  RAISE NOTICE '%',esito;
  RETURN next;
  return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;

--- 22.07.2019 Sofia siac-6973 - fine

-- SIAC-6719 - Maurizio - INIZIO 

create table if not exists siac_t_config_ente_report_param_def (
  report_param_def_id SERIAL,
  rep_codice VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  nome_ente	VARCHAR(200) NOT NULL,
  sigla_prov VARCHAR(4) NOT NULL,
  provincia VARCHAR(200) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_t_ente_report_param_def PRIMARY KEY(report_param_def_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_config_ente_report_param_def FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
  ) 
WITH (oids = false);

-- ENTI COMUNE
-- Report di UTILITA'  
insert into siac_t_config_ente_report_param_def (
	rep_codice, ente_proprietario_id, nome_ente, sigla_prov, provincia,
    validita_inizio, validita_fine,
    data_creazione, data_modifica,data_cancellazione, login_operazione)
select 	'BILR228', ente_proprietario_id, 'Alessandria', 'AL', 'ALESSANDRIA',
	now(), NULL, now(), now(), NULL, 'admin'
from siac_t_ente_proprietario ente
	where ente.ente_proprietario_id in (29)
		and ente.data_cancellazione IS NULL
        and not exists (select 1
        	from siac_t_config_ente_report_param_def param
            	where param.rep_codice = 'BILR228'
                	and param.ente_proprietario_id=ente.ente_proprietario_id
                    	and param.data_cancellazione IS NULL);
						
insert into siac_t_config_ente_report_param_def (
	rep_codice, ente_proprietario_id, nome_ente, sigla_prov, provincia,
    validita_inizio, validita_fine,
    data_creazione, data_modifica,data_cancellazione, login_operazione)
select 	'BILR232', ente_proprietario_id, 'Alessandria', 'AL', 'ALESSANDRIA',
	now(), NULL, now(), now(), NULL, 'admin'
from siac_t_ente_proprietario ente
	where ente.ente_proprietario_id in (29)
		and ente.data_cancellazione IS NULL
        and not exists (select 1
        	from siac_t_config_ente_report_param_def param
            	where param.rep_codice = 'BILR232'
                	and param.ente_proprietario_id=ente.ente_proprietario_id
                    	and param.data_cancellazione IS NULL);
				
--Report di GESTIONE				
insert into siac_t_config_ente_report_param_def (
	rep_codice, ente_proprietario_id, nome_ente, sigla_prov, provincia,
    validita_inizio, validita_fine,
    data_creazione, data_modifica,data_cancellazione, login_operazione)
select 	'BILR230', ente_proprietario_id, 'Alessandria', 'AL', 'ALESSANDRIA',
	now(), NULL, now(), now(), NULL, 'admin'
from siac_t_ente_proprietario ente
	where ente.ente_proprietario_id in (29)
		and ente.data_cancellazione IS NULL
        and not exists (select 1
        	from siac_t_config_ente_report_param_def param
            	where param.rep_codice = 'BILR230'
                	and param.ente_proprietario_id=ente.ente_proprietario_id
                    	and param.data_cancellazione IS NULL);    

-- Report di PREVISIONE  
insert into siac_t_config_ente_report_param_def (
	rep_codice, ente_proprietario_id, nome_ente, sigla_prov, provincia,
    validita_inizio, validita_fine,
    data_creazione, data_modifica,data_cancellazione, login_operazione)
select 	'BILR234', ente_proprietario_id, 'Alessandria', 'AL', 'ALESSANDRIA',
	now(), NULL, now(), now(), NULL, 'admin'
from siac_t_ente_proprietario ente
	where ente.ente_proprietario_id in (29)
		and ente.data_cancellazione IS NULL
        and not exists (select 1
        	from siac_t_config_ente_report_param_def param
            	where param.rep_codice = 'BILR234'
                	and param.ente_proprietario_id=ente.ente_proprietario_id
                    	and param.data_cancellazione IS NULL);   
						
-- ENTI CITTA' METROPOLITANE
-- Report di UTILITA'  
insert into siac_t_config_ente_report_param_def (
	rep_codice, ente_proprietario_id, nome_ente, sigla_prov, provincia,
    validita_inizio, validita_fine,
    data_creazione, data_modifica,data_cancellazione, login_operazione)
select 	'BILR229', ente_proprietario_id, 'Torino', 'TO', 'TORINO',
	now(), NULL, now(), now(), NULL, 'admin'
from siac_t_ente_proprietario ente
	where ente.ente_proprietario_id in (3)
		and ente.data_cancellazione IS NULL
        and not exists (select 1
        	from siac_t_config_ente_report_param_def param
            	where param.rep_codice = 'BILR229'
                	and param.ente_proprietario_id=ente.ente_proprietario_id
                    	and param.data_cancellazione IS NULL);
						
 insert into siac_t_config_ente_report_param_def (
	rep_codice, ente_proprietario_id, nome_ente, sigla_prov, provincia,
    validita_inizio, validita_fine,
    data_creazione, data_modifica,data_cancellazione, login_operazione)
select 	'BILR233', ente_proprietario_id, 'Torino', 'TO', 'TORINO',
	now(), NULL, now(), now(), NULL, 'admin'
from siac_t_ente_proprietario ente
	where ente.ente_proprietario_id in (3)
		and ente.data_cancellazione IS NULL
        and not exists (select 1
        	from siac_t_config_ente_report_param_def param
            	where param.rep_codice = 'BILR233'
                	and param.ente_proprietario_id=ente.ente_proprietario_id
                    	and param.data_cancellazione IS NULL);      
			
--Report di GESTIONE				
insert into siac_t_config_ente_report_param_def (
	rep_codice, ente_proprietario_id, nome_ente, sigla_prov, provincia,
    validita_inizio, validita_fine,
    data_creazione, data_modifica,data_cancellazione, login_operazione)
select 	'BILR231', ente_proprietario_id, 'Torino', 'TO', 'TORINO',
	now(), NULL, now(), now(), NULL, 'admin'
from siac_t_ente_proprietario ente
	where ente.ente_proprietario_id in (3)
		and ente.data_cancellazione IS NULL
        and not exists (select 1
        	from siac_t_config_ente_report_param_def param
            	where param.rep_codice = 'BILR231'
                	and param.ente_proprietario_id=ente.ente_proprietario_id
                    	and param.data_cancellazione IS NULL);                             						                

		             					
-- Report di PREVISIONE
 insert into siac_t_config_ente_report_param_def (
	rep_codice, ente_proprietario_id, nome_ente, sigla_prov, provincia,
    validita_inizio, validita_fine,
    data_creazione, data_modifica,data_cancellazione, login_operazione)
select 	'BILR235', ente_proprietario_id, 'Torino', 'TO', 'TORINO',
	now(), NULL, now(), now(), NULL, 'admin'
from siac_t_ente_proprietario ente
	where ente.ente_proprietario_id in (3)
		and ente.data_cancellazione IS NULL
        and not exists (select 1
        	from siac_t_config_ente_report_param_def param
            	where param.rep_codice = 'BILR235'
                	and param.ente_proprietario_id=ente.ente_proprietario_id
                    	and param.data_cancellazione IS NULL);   
						
DROP FUNCTION if exists siac."BILR228_parametri_obiettivi_per_comuni"(p_ente_prop_id integer, p_anno varchar, p_code_report varchar);

CREATE OR REPLACE FUNCTION siac."BILR228_parametri_obiettivi_per_comuni" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_code_report varchar
)
RETURNS TABLE (
  importo_p1 numeric,
  importo_p2 numeric,
  importo_p3 numeric,
  importo_p4 numeric,
  importo_p5 numeric,
  importo_p6 numeric,
  importo_p7 numeric,
  importo_p8 numeric,
  nome_ente varchar,
  sigla_prov varchar,
  provincia varchar,
  display_error varchar
) AS
$body$
DECLARE

RTN_MESSAGGIO text;
denom_ente varchar;

variabiliRendiconto record;
entrataRendiconto record;
spesaRendiconto record;
fpvAnnoPrecRendiconto record;

ripiano_disav_rnd numeric;
anticip_tesoreria_rnd numeric;
max_previsto_norma_rnd numeric;
impegni_estinz_anticip_rnd numeric;
disav_iscrit_spesa_rnd numeric;
importo_debiti_fuori_bil_ricon_rnd numeric;
importo_debiti_fuori_bil_corso_ricon_rnd numeric;
importo_debiti_fuori_bil_ricon_corso_finanz_rnd numeric;

rend_accert_A_titoli_123 numeric; 
rend_prev_def_cassa_CS_titoli_123 numeric; 
rend_risc_conto_comp_RC_pdce_E_1_01 numeric;
rend_risc_conto_res_RR_pdce_E_1_01 numeric;
rend_risc_conto_comp_RC_pdce_E_1_01_04 numeric;
rend_risc_conto_res_RR_pdce_E_1_01_04 numeric;
rend_risc_conto_comp_RC_pdce_E_3 numeric;
rend_risc_conto_res_RR_pdce_E_3 numeric;
rend_accert_A_pdce_E_4_02_06 numeric;
rend_accert_A_pdce_E_4_03_01 numeric;
rend_accert_A_pdce_E_4_03_04 numeric;
TotaleRiscossioniTR numeric;
TotaleAccertatoA numeric;
TotaleResAttiviRS numeric;

rend_impegni_I_macroagg101 numeric;
rend_FPV_macroagg_101 numeric;
rend_impegni_I_macroagg107 numeric;
rend_impegni_I_titolo_4 numeric;
rend_impegni_I_pdce_U_1_02_01_01 numeric;
rend_FPV_anno_prec_macroagg101 numeric;
rend_impegni_i_pdce_U_1_07_06_02 numeric;
rend_impegni_i_pdce_U_1_07_06_04 numeric;
rend_impegni_I_titoli_1_2 numeric;

indic_13_2_app numeric;
indic_13_3_app numeric;

id_report_config integer;

BEGIN

/*
	Questa procedura e' utilizzata dai report BILR228, BILR229, BILR330, BILR331,
    BILR332, BILR333, BILR334 e BILR335 per estrarre i dati che servono per il 
    calcolo dei paramentri obiettivi.
    I dati sono quelli estratti per gli indicatori di rendiconto.
    Sono estratti i dati delle variabili e per farlo sono richiamate le seguenti 
    procedure usate nei report degli indicatori:
    - BILR186_indic_sint_ent_rend_org_er; per le entrate;
    - BILR186_indic_sint_spe_rend_org_er; per le spese;
    - BILR186_indic_sint_spe_rend_FPV_anno_prec; per l'FPV anno precedente.
    
    La procedura effettua il calcolo dei singoli valori usati per il calcolo
    applicando gli algoritmi che per gli indicatori sono utilizzati all'interno 
    dei report.
    In questo modo la procedura restiruisce i valori degli indicatori gia' calcolati
    ed il report deve solo mostrarne il valore ed eventualmente cambiare il colore
    della cella se il dato e' fuori soglia.
    
*/

importo_p1:=0;
importo_p2:=0;
importo_p3:=0;
importo_p4:=0;
importo_p5:=0;
importo_p6:=0;
importo_p7:=0;
importo_p8:=0;
nome_ente:='';
sigla_prov:='';
provincia:='';
display_error:='';

select ente_denominazione
	into denom_ente
from siac_t_ente_proprietario
where ente_proprietario_id = p_ente_prop_id
	and data_cancellazione IS NULL;

if denom_ente IS NULL THEN
	denom_ente :='';
end if;
    
raise notice 'Ente = %', denom_ente;

--verifico se l'ente e' abilitato all'utilizzo del report.
id_report_config:=NULL;
select a.report_param_def_id, a.nome_ente, a.sigla_prov, a.provincia
into id_report_config, nome_ente, sigla_prov, provincia
from siac_t_config_ente_report_param_def a
where a.ente_proprietario_id = p_ente_prop_id
	and a.rep_codice = p_code_report
    and a.data_cancellazione IS NULL
    and a.validita_fine IS NULL;
 
raise notice 'id_report_config = %', id_report_config;

if id_report_config IS NULL THEN
	display_error := 'L''ENTE ''' || denom_ente || ''' NON E'' ABILITATO ALL''UTILIZZO DEL REPORT '||p_code_report;
    nome_ente:=denom_ente;
    return next;
    return;
end if;


  
--variabili
ripiano_disav_rnd:=0;
anticip_tesoreria_rnd:=0;
max_previsto_norma_rnd:=0;
impegni_estinz_anticip_rnd:=0;
disav_iscrit_spesa_rnd:=0;
importo_debiti_fuori_bil_ricon_rnd:=0;
importo_debiti_fuori_bil_corso_ricon_rnd:=0;
importo_debiti_fuori_bil_ricon_corso_finanz_rnd:=0;
indic_13_2_app:=0;
indic_13_3_app:=0;


--entrate importo_accertato_a titoli 1,2,3
rend_accert_A_titoli_123:=0;
--entrate importo_prev_def_cassa_cs titoli 1,2,3
rend_prev_def_cassa_CS_titoli_123:=0;
--entrate importo_risc_conto_comp_rc pdce 'E.1.01'
rend_risc_conto_comp_RC_pdce_E_1_01 :=0;
--entrate importo_risc_conto_comp_rc pdce  'E.1.01.04'
rend_risc_conto_comp_RC_pdce_E_1_01_04:=0;
--entrate importo_risc_conto_comp_rc pdce   'E.3'
rend_risc_conto_comp_RC_pdce_E_3:=0;
--entrate "importo_risc_conto_res_rr pdce   'E.1.01'
rend_risc_conto_res_RR_pdce_E_1_01:=0;
--entrate "importo_risc_conto_res_rr pdce   'E.1.01.04'
rend_risc_conto_res_RR_pdce_E_1_01_04:=0;
--entrate "importo_risc_conto_res_rr pdce   'E.3'
rend_risc_conto_res_RR_pdce_E_3:=0;
--entrate importo_accertato_a pdce   'E.4.02.06'
rend_accert_A_pdce_E_4_02_06:=0;
--entrate importo_accertato_a pdce   'E.4.03.01'
rend_accert_A_pdce_E_4_03_01:=0;
--entrate importo_accertato_a pdce   'E.4.03.04'
rend_accert_A_pdce_E_4_03_04:=0;
--entrate totale RISCOSSIONI 
TotaleRiscossioniTR:=0;
--entrate totale ACCERTATO
TotaleAccertatoA:=0;
--entrate totale RSIDUI ATTIVI
TotaleResAttiviRS:=0;

--spese imp_impegnato_i macroagg '101'
rend_impegni_I_macroagg101:=0;
--spese imp_impegnato_i FPV macroagg '101'
rend_FPV_macroagg_101:=0;
--spese imp_impegnato_i macroagg '107'
rend_impegni_I_macroagg107:=0;
--spese imp_impegnato_i titolo '4'
rend_impegni_I_titolo_4:=0;
--spese imp_impegnato_i pdce 'U.1.02.01.01'
rend_impegni_I_pdce_U_1_02_01_01:=0;
--spese anno_prec spese_fpv_anni_prec macroagg '101'
rend_FPV_anno_prec_macroagg101:=0;
--spese imp_impegnato_i pdce 'U.1.07.06.02'
rend_impegni_i_pdce_U_1_07_06_02:=0;
--spese imp_impegnato_i pdce 'U.1.07.06.04'
rend_impegni_i_pdce_U_1_07_06_04:=0;
--spese imp_impegnato_i titoli '1', '2'
rend_impegni_I_titoli_1_2:=0;

	-- estraggo la parte relativa alle variabili.
for variabiliRendiconto IN
  select t_voce_conf_indicatori_sint.voce_conf_ind_codice,
      t_voce_conf_indicatori_sint.voce_conf_ind_desc,
      t_conf_indicatori_sint.conf_ind_valore_anno,
      t_conf_indicatori_sint.conf_ind_valore_anno_1,
      t_conf_indicatori_sint.conf_ind_valore_anno_2
  from siac_t_conf_indicatori_sint t_conf_indicatori_sint,
      siac_t_voce_conf_indicatori_sint t_voce_conf_indicatori_sint,
      siac_t_bil t_bil,
      siac_t_periodo t_periodo
  where t_conf_indicatori_sint.bil_id=t_bil.bil_id
      and t_bil.periodo_id=t_periodo.periodo_id
      and t_voce_conf_indicatori_sint.voce_conf_ind_id=t_conf_indicatori_sint.voce_conf_ind_id
      and t_conf_indicatori_sint.ente_proprietario_id =p_ente_prop_id
      and t_periodo.anno=p_anno
      and t_voce_conf_indicatori_sint.voce_conf_ind_tipo='R'
      and t_voce_conf_indicatori_sint.voce_conf_ind_codice in ('ripiano_disav_rnd',
      	'anticip_tesoreria_rnd', 'max_previsto_norma_rnd','impegni_estinz_anticip_rnd',
        'importo_debiti_fuori_bil_ricon_rnd','importo_debiti_fuori_bil_corso_ricon_rnd',
        'importo_debiti_fuori_bil_ricon_corso_finanz_rnd')
      and t_conf_indicatori_sint.data_cancellazione IS NULL
      and t_bil.data_cancellazione IS NULL
      and t_periodo.data_cancellazione IS NULL
      and t_voce_conf_indicatori_sint.data_cancellazione IS NULL
loop
      if variabiliRendiconto.voce_conf_ind_codice = 'ripiano_disav_rnd' THEN
      	ripiano_disav_rnd := COALESCE(variabiliRendiconto.conf_ind_valore_anno,0);
      end if;
      if variabiliRendiconto.voce_conf_ind_codice = 'anticip_tesoreria_rnd' THEN
      	anticip_tesoreria_rnd := COALESCE(variabiliRendiconto.conf_ind_valore_anno,0);
      end if;
      if variabiliRendiconto.voce_conf_ind_codice = 'max_previsto_norma_rnd' THEN
      	max_previsto_norma_rnd := COALESCE(variabiliRendiconto.conf_ind_valore_anno,0);
      end if;
      if variabiliRendiconto.voce_conf_ind_codice = 'impegni_estinz_anticip_rnd' THEN
      	impegni_estinz_anticip_rnd := COALESCE(variabiliRendiconto.conf_ind_valore_anno,0);
      end if;           
      if variabiliRendiconto.voce_conf_ind_codice = 'importo_debiti_fuori_bil_ricon_rnd' THEN
      	importo_debiti_fuori_bil_ricon_rnd := COALESCE(variabiliRendiconto.conf_ind_valore_anno,0);
      end if;   
      if variabiliRendiconto.voce_conf_ind_codice = 'importo_debiti_fuori_bil_corso_ricon_rnd' THEN
      	importo_debiti_fuori_bil_corso_ricon_rnd := COALESCE(variabiliRendiconto.conf_ind_valore_anno,0);
      end if;  
      if variabiliRendiconto.voce_conf_ind_codice = 'importo_debiti_fuori_bil_ricon_corso_finanz_rnd' THEN
      	importo_debiti_fuori_bil_ricon_corso_finanz_rnd := COALESCE(variabiliRendiconto.conf_ind_valore_anno,0);
      end if;        
end loop;


	-- estraggo la parte relativa al rendiconto di ENTRATA e calcolo
    -- i singoli valori.
for entrataRendiconto in  
  select code_titolo, pdce_code,
      sum(importo_accertato_a) importo_accertato_a, 
      sum(importo_prev_def_cassa_cs) importo_prev_def_cassa_cs, 
      sum(importo_risc_conto_comp_rc) importo_risc_conto_comp_rc,
      sum(importo_risc_conto_res_rr) importo_risc_conto_res_rr,
      sum(importo_tot_risc_tr) importo_tot_risc_tr   ,
      sum(importo_res_attivi_rs) importo_res_attivi_rs
  from "BILR186_indic_sint_ent_rend_org_er"(p_ente_prop_id, p_anno)
  group by code_titolo, pdce_code
loop 
	TotaleRiscossioniTR:= TotaleRiscossioniTR +
    	COALESCE(entrataRendiconto.importo_tot_risc_tr,0);
    TotaleAccertatoA:=TotaleAccertatoA +
    	COALESCE(entrataRendiconto.importo_accertato_a,0);   
    TotaleResAttiviRS:= TotaleResAttiviRS +
    	COALESCE(entrataRendiconto.importo_res_attivi_rs,0);      

	if entrataRendiconto.code_titolo in ('1','2','3') THEN
    	rend_accert_A_titoli_123:=rend_accert_A_titoli_123 +
        	COALESCE(entrataRendiconto.importo_accertato_a,0);
        rend_prev_def_cassa_CS_titoli_123:=rend_prev_def_cassa_CS_titoli_123 +
        	COALESCE(entrataRendiconto.importo_prev_def_cassa_cs,0);
    end if;
    if left(entrataRendiconto.pdce_code,6) = 'E.1.01' then
    	rend_risc_conto_comp_RC_pdce_E_1_01:=rend_risc_conto_comp_RC_pdce_E_1_01 +
        	COALESCE(entrataRendiconto.importo_risc_conto_comp_rc,0);
        rend_risc_conto_res_RR_pdce_E_1_01:=rend_risc_conto_res_RR_pdce_E_1_01 +
        	COALESCE(entrataRendiconto.importo_risc_conto_res_rr,0);
    end if;
    if left(entrataRendiconto.pdce_code,9) = 'E.1.01.04' then
    	rend_risc_conto_comp_RC_pdce_E_1_01_04:=rend_risc_conto_comp_RC_pdce_E_1_01_04 +
        	COALESCE(entrataRendiconto.importo_risc_conto_comp_rc,0);
        rend_risc_conto_res_RR_pdce_E_1_01_04:=rend_risc_conto_res_RR_pdce_E_1_01_04 +
        	COALESCE(entrataRendiconto.importo_risc_conto_res_rr,0);
    end if;
    if left(entrataRendiconto.pdce_code,3) = 'E.3' then
    	rend_risc_conto_comp_RC_pdce_E_3:=rend_risc_conto_comp_RC_pdce_E_3 +
        	COALESCE(entrataRendiconto.importo_risc_conto_comp_rc,0);
        rend_risc_conto_res_RR_pdce_E_3:=rend_risc_conto_res_RR_pdce_E_3 +
        	COALESCE(entrataRendiconto.importo_risc_conto_res_rr,0);
    end if;    
    if left(entrataRendiconto.pdce_code,9) = 'E.4.02.06' then
    	rend_accert_A_pdce_E_4_02_06:=rend_accert_A_pdce_E_4_02_06 +
        	COALESCE(entrataRendiconto.importo_risc_conto_comp_rc,0);
    end if;       
    if left(entrataRendiconto.pdce_code,9) = 'E.4.03.01' then
    	rend_accert_A_pdce_E_4_03_01:=rend_accert_A_pdce_E_4_03_01 +
        	COALESCE(entrataRendiconto.importo_risc_conto_comp_rc,0);
    end if;        
    if left(entrataRendiconto.pdce_code,9) = 'E.4.03.04' then
    	rend_accert_A_pdce_E_4_03_04:=rend_accert_A_pdce_E_4_03_04 +
        	COALESCE(entrataRendiconto.importo_risc_conto_comp_rc,0);
    end if;            

    
end loop;

	-- estraggo la parte relativa al rendiconto di SPESA e calcolo
    -- i singoli valori.
for spesaRendiconto in  
  select code_titolo, code_macroagg, tipo_capitolo, pdce_code,
      sum(imp_impegnato_i) imp_impegnato_i 
  from "BILR186_indic_sint_spe_rend_org_er"(p_ente_prop_id, p_anno)
  group by code_titolo, code_macroagg, tipo_capitolo, pdce_code
loop 
	if left(spesaRendiconto.code_macroagg,3) = '101' then
    	rend_impegni_I_macroagg101:=rend_impegni_I_macroagg101+
        	COALESCE(spesaRendiconto.imp_impegnato_i,0);
        if spesaRendiconto.tipo_capitolo = 'FPV' then
        	rend_FPV_macroagg_101:=rend_FPV_macroagg_101+
            	COALESCE(spesaRendiconto.imp_impegnato_i,0);
        end if;
    end if;
    if left(spesaRendiconto.code_macroagg,3) = '107' then
		rend_impegni_I_macroagg107:=rend_impegni_I_macroagg107+
        	COALESCE(spesaRendiconto.imp_impegnato_i,0);
    end if;
    if  spesaRendiconto.code_titolo = '4' then
		rend_impegni_I_titolo_4:=rend_impegni_I_titolo_4+
        	COALESCE(spesaRendiconto.imp_impegnato_i,0);
    end if;    
    if  left(spesaRendiconto.pdce_code,12) = 'U.1.02.01.01' then
		rend_impegni_I_pdce_U_1_02_01_01:=rend_impegni_I_pdce_U_1_02_01_01+
        	COALESCE(spesaRendiconto.imp_impegnato_i,0);
    end if;  
    if  left(spesaRendiconto.pdce_code,12) = 'U.1.07.06.02' then
		rend_impegni_i_pdce_U_1_07_06_02:=rend_impegni_i_pdce_U_1_07_06_02+
        	COALESCE(spesaRendiconto.imp_impegnato_i,0);
    end if;  
    if  left(spesaRendiconto.pdce_code,12) = 'U.1.07.06.04' then
		rend_impegni_i_pdce_U_1_07_06_04:=rend_impegni_i_pdce_U_1_07_06_04+
        	COALESCE(spesaRendiconto.imp_impegnato_i,0);
    end if;  
    if  spesaRendiconto.code_titolo in ('1','2') then
		rend_impegni_I_titoli_1_2:=rend_impegni_I_titoli_1_2+
        	COALESCE(spesaRendiconto.imp_impegnato_i,0);
    end if;  

end loop;

	--estraggo il valore FPV anno precedente per macroaggreagato 101.
select COALESCE(sum(spese_fpv_anni_prec),0) 
	into rend_FPV_anno_prec_macroagg101
   from "BILR186_indic_sint_spe_rend_FPV_anno_prec"(p_ente_prop_id, p_anno)
   where left(code_macroagg,3) = '101';

/* I commenti riportati nel seguito per ogni variabile sono i calcoli che
	vengono effettuati all'interno dei report degli indicatori.
*/    

/* IMPORTO P1 = Indicatore 1.2 = 
	var Denom = row._outer["rend_accert_A_titoli_123"];

	(dataSetRow["ripiano_disav_rnd"]+
	 row._outer._outer._outer["rend_impegni_I_macroagg101"] +
	 row._outer._outer._outer["rend_impegni_I_pdce_U.1.02.01.01"] -
	 row._outer._outer["rend_FPV_anno_prec_macroagg101"] +
 	 row._outer._outer._outer["rend_FPV_macroagg_101"] +
 	 row._outer._outer._outer["rend_impegni_I_macroagg107"] +
 	 row._outer._outer._outer["rend_impegni_I_titolo_4"]) /
 	 Denom;
*/
if rend_accert_A_titoli_123 != 0 then
	importo_p1 :=
		(ripiano_disav_rnd + rend_impegni_I_macroagg101
        + rend_impegni_I_pdce_U_1_02_01_01 
        - rend_FPV_anno_prec_macroagg101 + rend_FPV_macroagg_101
        + rend_impegni_I_macroagg107 + rend_impegni_I_titolo_4) /
        rend_accert_A_titoli_123;
end if;

/* IMPORTO P2 = Indicatore 2.8 = 
	(dataSetRow["rend_risc_conto_comp_RC_pdce_E.1.01"] + dataSetRow["rend_risc_conto_res_RR_pdce_E.1.01"]
	 - dataSetRow["rend_risc_conto_comp_RC_pdce_E.1.01.04"] - dataSetRow["rend_risc_conto_res_RR_pdce_E.1.01.04"]
	 +dataSetRow["rend_risc_conto_comp_RC_pdce_E.3"] +dataSetRow["rend_risc_conto_res_RR_pdce_E.3"]) /
	dataSetRow["rend_prev_def_cassa_CS_titoli_123"]
*/    
if rend_prev_def_cassa_CS_titoli_123 != 0 then
	importo_p2 := 
	(rend_risc_conto_comp_RC_pdce_E_1_01+rend_risc_conto_res_RR_pdce_E_1_01
     - rend_risc_conto_comp_RC_pdce_E_1_01_04 - rend_risc_conto_res_RR_pdce_E_1_01_04 
     + rend_risc_conto_comp_RC_pdce_E_3 + rend_risc_conto_res_RR_pdce_E_3) /
	rend_prev_def_cassa_CS_titoli_123;
end if;

/* IMPORTO P3 = Indicatore 3.2 = 
	dataSetRow["anticip_tesoreria_rnd"] /
	dataSetRow["max_previsto_norma_rnd"];
*/
if max_previsto_norma_rnd != 0 then
	importo_p3 := anticip_tesoreria_rnd / max_previsto_norma_rnd;
end if;

/* IMPORTO P4 = Indicatore 10.3 =
(row._outer._outer["rend_impegni_I_macroagg107"] -
	 row._outer._outer["rend_impegni_I_pdce_U.1.07.06.02"] -
	 row._outer._outer["rend_impegni_I_pdce_U.1.07.06.04"] +
	 row._outer._outer["rend_impegni_I_titolo_4"] -
	 row["impegni_estinz_anticip_rnd"] -
	 (row._outer["rend_accert_A_pdce_E.4.02.06"] +
	  row._outer["rend_accert_A_pdce_E.4.03.01"] +
	  row._outer["rend_accert_A_pdce_E.4.03.04"])) /
	  row._outer["rend_accert_A_titoli_123"];
*/

if rend_accert_A_titoli_123 != 0 then
	importo_p4 := 
    (rend_impegni_I_macroagg107 - rend_impegni_i_pdce_U_1_07_06_02
     - rend_impegni_i_pdce_U_1_07_06_04 + rend_impegni_I_titolo_4
     - impegni_estinz_anticip_rnd
     - (rend_accert_A_pdce_E_4_02_06 + rend_accert_A_pdce_E_4_03_01
        + rend_accert_A_pdce_E_4_03_04)) /
    rend_accert_A_titoli_123;
end if;

/* IMPORTO P5 = Indicatore 12.4 =
	dataSetRow["disav_iscrit_spesa_rnd"] /
	row._outer["rend_accert_A_titoli_123"];
    
*/

if rend_accert_A_titoli_123 != 0 then
	importo_p5 := disav_iscrit_spesa_rnd / rend_accert_A_titoli_123;
end if;    

/* IMPORTO P6 = Indicatore 13.1 =
    	dataSetRow["importo_debiti_fuori_bil_ricon_rnd"] /
	row._outer["rend_impegni_I_titoli_1_2"];
    
*/

if rend_impegni_I_titoli_1_2 != 0 then
	importo_p6 := 
    	importo_debiti_fuori_bil_ricon_rnd/ rend_impegni_I_titoli_1_2;
end if;



/* IMPORTO P7 = Indicatore 13.2 + 13.3 =
	13.2
		dataSetRow["importo_debiti_fuori_bil_corso_ricon_rnd"] /
		row._outer["rend_accert_A_titoli_123"];
    13.3
    dataSetRow["importo_debiti_fuori_bil_ricon_corso_finanz_rnd"] /
		row._outer["rend_accert_A_titoli_123"] ;
*/    
if rend_accert_A_titoli_123 != 0 then
	importo_p7 :=
    	(importo_debiti_fuori_bil_corso_ricon_rnd / rend_accert_A_titoli_123) +
        (importo_debiti_fuori_bil_ricon_corso_finanz_rnd / rend_accert_A_titoli_123);
end if;

/* IMPORTO P8 = Indicatore Analitico report BILR191, colonna
% di riscossione complessiva: (Riscossioni c/comp+ Riscossioni c/residui)/ 
	(Accertamenti + residui definitivi iniziali)
    
    Poiche' la procedura BILR181_indic_ana_ent_rend_org_er (usata nel report BILR91)
    estrae gli stessi dati della BILR186_indic_sint_ent_rend_org_er solo raggruppati
    in modo diverso evito di chiamare la BILR181_indic_ana_ent_rend_org_er in quanto
    serve solo il dato toale.
    
	row._outer["TotaleRiscossioniTR"] / 
	(row._outer["TotaleAccertatoA"] + row._outer["TotaleResAttiviRS"]);    

*/
if TotaleAccertatoA + TotaleResAttiviRS != 0 then	
	importo_p8 :=
		TotaleRiscossioniTR /
		(TotaleAccertatoA + TotaleResAttiviRS);
end if;
        
raise notice '';
raise notice '               IMPORTI VARIABILI';
raise notice 'ripiano_disav_rnd = %', ripiano_disav_rnd;
raise notice 'anticip_tesoreria_rnd = %', anticip_tesoreria_rnd;
raise notice 'max_previsto_norma_rnd = %', max_previsto_norma_rnd;
raise notice 'impegni_estinz_anticip_rnd = %', impegni_estinz_anticip_rnd;
raise notice 'importo_debiti_fuori_bil_ricon_rnd = %', importo_debiti_fuori_bil_ricon_rnd;
raise notice 'importo_debiti_fuori_bil_corso_ricon_rnd = %', importo_debiti_fuori_bil_corso_ricon_rnd;
raise notice 'importo_debiti_fuori_bil_ricon_corso_finanz_rnd = %', importo_debiti_fuori_bil_ricon_corso_finanz_rnd;

raise notice '';
raise notice '               IMPORTI ENTRATE'; 
raise notice 'rend_accert_A_titoli_123 = %', rend_accert_A_titoli_123;
raise notice 'rend_prev_def_cassa_CS_titoli_123 = %', rend_prev_def_cassa_CS_titoli_123;
raise notice 'rend_risc_conto_comp_RC_pdce_E_1_01 = %', rend_risc_conto_comp_RC_pdce_E_1_01;
raise notice 'rend_risc_conto_res_RR_pdce_E_1_01 = %', rend_risc_conto_res_RR_pdce_E_1_01;
raise notice 'rend_risc_conto_comp_RC_pdce_E_1_01_04 = %', rend_risc_conto_comp_RC_pdce_E_1_01_04;
raise notice 'rend_risc_conto_res_RR_pdce_E_1_01_04 = %', rend_risc_conto_res_RR_pdce_E_1_01_04;
raise notice 'rend_risc_conto_comp_RC_pdce_E_3 = %', rend_risc_conto_comp_RC_pdce_E_3;
raise notice 'rend_risc_conto_res_RR_pdce_E_3 = %', rend_risc_conto_res_RR_pdce_E_3;  
raise notice 'rend_accert_A_pdce_E_4_02_06 = %', rend_accert_A_pdce_E_4_02_06;
raise notice 'rend_accert_A_pdce_E_4_03_01 = %', rend_accert_A_pdce_E_4_03_01;
raise notice 'rend_accert_A_pdce_E_4_03_04 = %', rend_accert_A_pdce_E_4_03_04;  
raise notice 'TotaleRiscossioniTR = %', TotaleRiscossioniTR;
raise notice 'TotaleAccertatoA = %', TotaleAccertatoA;
raise notice 'TotaleResAttiviRS = %', TotaleResAttiviRS;
        
raise notice '';
raise notice '               IMPORTI SPESE';   
raise notice 'rend_impegni_I_macroagg101 = %', rend_impegni_I_macroagg101;    
raise notice 'rend_FPV_macroagg_101 = %', rend_FPV_macroagg_101;    
raise notice 'rend_impegni_I_macroagg107 = %', rend_impegni_I_macroagg107; 
raise notice 'rend_impegni_I_titolo_4 = %', rend_impegni_I_titolo_4;
raise notice 'rend_impegni_I_pdce_U_1_02_01_01 = %', rend_impegni_I_pdce_U_1_02_01_01;
raise notice 'rend_FPV_anno_prec_macroagg101 = %', rend_FPV_anno_prec_macroagg101;
raise notice 'rend_impegni_i_pdce_U_1_07_06_02 = %', rend_impegni_i_pdce_U_1_07_06_02;
raise notice 'rend_impegni_i_pdce_U_1_07_06_04 = %', rend_impegni_i_pdce_U_1_07_06_04;
raise notice 'rend_impegni_I_titoli_1_2 = %', rend_impegni_I_titoli_1_2;

return next;

exception
	when no_data_found THEN
		raise notice 'Nessun dato trovato';
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


-- SIAC-6719 - Maurizio - FINE 


--- 23.07.2019 Sofia siac-6963 - inizio

insert into pagopa_d_riconciliazione_errore
(
	pagopa_ric_errore_code,
    pagopa_ric_errore_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select '51',
       'DATI RICONCILIAZIONE CON ACCERTAMENTO PRIVO DI SOGGETTO O INESISTENTE',
       now(),
       'SIAC-6963',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente
WHERE not exists
(select 1
 from pagopa_d_riconciliazione_errore errore
 where errore.ente_proprietario_id=ente.ente_proprietario_id
 and   errore.pagopa_ric_errore_code='51'
 and   errore.data_cancellazione is null
 );
 
insert into siac_t_attr
(
 attr_code,
 attr_desc,
 attr_tipo_id,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select 'flagSenzaNumero',
       'flagSenzaNumero',
       tipo.attr_tipo_id,
       now(),
       'SIAC-6963',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente , siac_d_attr_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.attr_tipo_code='B'
and   not exists
(
select 1
from siac_t_attr attr
where attr.ente_proprietario_id=ente.ente_proprietario_id
and   attr.attr_tipo_id=tipo.attr_tipo_id
and   attr.attr_code='flagSenzaNumero'
and   attr.data_cancellazione is null
);


insert into siac_r_doc_tipo_attr
(
	doc_tipo_id,
    attr_id,
    boolean,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select tipo.doc_tipo_id,
       attr.attr_id,
       'S',
       now(),
       'SIAC-6963',
       attr.ente_proprietario_id
from siac_t_ente_proprietario ente, siac_t_attr attr,   siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
where attr.ente_proprietario_id=ente.ente_proprietario_id
and   attr.attr_code='flagSenzaNumero'
and   tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.doc_tipo_code in ('COR','FTV')
and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
and   fam.doc_fam_tipo_code='E'
and   not exists
(select 1
 from  siac_r_doc_tipo_attr r
 where r.ente_proprietario_id=ente.ente_proprietario_id
 and   r.doc_tipo_id=tipo.doc_tipo_id
 and   r.attr_id=attr.attr_id
 and   r.data_cancellazione is null
);
 
drop FUNCTION if exists fnc_pagopa_t_elaborazione_riconc_esegui
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
);

CREATE OR REPLACE FUNCTION fnc_pagopa_t_elaborazione_riconc_esegui
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioBck VARCHAR(1500):='';
    strMessaggioLog VARCHAR(2500):='';

	strMessaggioFinale VARCHAR(1500):='';
    strErrore  VARCHAR(1500):='';
    pagoPaCodeErr varchar(50):='';
	codResult integer:=null;
    codResult1 integer:=null;
    docid integer:=null;
    subDocId integer:=null;
    nProgressivo integer=null;




    -- stati ammessi per procedere con elaborazione
    -- file XML caricato correttamente pronto x elaborazione
	ACQUISITO_ST              CONSTANT  varchar :='ACQUISITO';
    -- file XML caricato correttamente, elaborazione in corso, flussi in fase di elaborazione
    ELABORATO_IN_CORSO_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO'; -- senza errori  e scarti
    ELABORATO_IN_CORSO_ER_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_ER';  -- con errori
    ELABORATO_IN_CORSO_SC_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_SC'; -- con scarti
    -- stati ammessi per procedere con elaborazione


    -- stati per chiusura con errore
    ELABORATO_SCARTATO_ST     CONSTANT  varchar :='ELABORATO_SCARTATO';
    ELABORATO_ERRATO_ST       CONSTANT  varchar :='ELABORATO_ERRATO';
    ANNULLATO_ST              CONSTANT  varchar :='ANNULLATO';
	RIFIUTATO_ST              CONSTANT  varchar :='RIFIUTATO';
    -- stati per chiusura con errore

    -- stati per chiusura con successo con o senza scarti
    -- file XML caricato, ELABORAZIONE TERMINATA E CONCLUSA
    ELABORATO_OK_ST           CONSTANT  varchar :='ELABORATO_OK'; -- documenti  emessi
    ELABORATO_KO_ST           CONSTANT  varchar :='ELABORATO_KO'; -- documenti emessi - presenza di errori-scarti
    -- stati per chiusura con successo con o senza scarti

	ESERCIZIO_PROVVISORIO_ST CONSTANT  varchar :='E'; -- esercizio provvisorio
    ESERCIZIO_GESTIONE_ST    CONSTANT  varchar :='G'; -- esercizio gestione

	-- errori di elaborazione su dettagli
	PAGOPA_ERR_1	CONSTANT  varchar :='1'; --ANNULLATO
	PAGOPA_ERR_2	CONSTANT  varchar :='2'; --SCARTATO
	PAGOPA_ERR_3	CONSTANT  varchar :='3'; --ERRORE GENERICO
	PAGOPA_ERR_4	CONSTANT  varchar :='4'; --FILE NON ESISTENTE O STATO NON RICHIESTO
	PAGOPA_ERR_5	CONSTANT  varchar :='5'; --FILE CARICATO DIVERSE VOLTE PER filepagopaFileXMLId
	PAGOPA_ERR_6	CONSTANT  varchar :='6'; --DATI DI RICONCILIAZIONE NON PRESENTI
	PAGOPA_ERR_7	CONSTANT  varchar :='7'; --DATI DI RICONCILIAZIONE DA ELABORARE NON PRESENTI
	PAGOPA_ERR_8	CONSTANT  varchar :='8'; --DATI DI RICONCILIAZIONE NON PRESENTI PER filepagopaFileXMLId
	PAGOPA_ERR_9	CONSTANT  varchar :='9'; --DATI DI RICONCILIAZIONE PRESENTI PER DIVERSO FILE E STESSO filepagopaFileXMLId
	PAGOPA_ERR_10	CONSTANT  varchar :='10';--DATI DI RICONCILIAZIONE ASSOCIATI A DIVERSI VALORI DI ANNO ESERCIZIO
	PAGOPA_ERR_11	CONSTANT  varchar :='11';--DATI DI RICONCILIAZIONE ASSOCIATI A ANNO ESERCIZIO SUCCESSIVO A ANNO BILANCIO
	PAGOPA_ERR_12	CONSTANT  varchar :='12';--DATI DI RICONCILIAZIONE SENZA ANNO ESERCIZIO INDICATO
	PAGOPA_ERR_13	CONSTANT  varchar :='13';--DATI DI RICONCILIAZIONE SENZA ESTREMI PROVVISORIO DI CASSA
	PAGOPA_ERR_14	CONSTANT  varchar :='14';--DATI DI RICONCILIAZIONE SENZA ESTREMI ACCERTAMENTO
	PAGOPA_ERR_15	CONSTANT  varchar :='15';--DATI DI RICONCILIAZIONE SENZA ESTREMI VOCE/SOTTOVOCE
	PAGOPA_ERR_16	CONSTANT  varchar :='16';--DATI DI RICONCILIAZIONE SENZA IMPORTO
	PAGOPA_ERR_17	CONSTANT  varchar :='17';--ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FILE
	PAGOPA_ERR_18	CONSTANT  varchar :='18';--ANNO BILANCIO DI ELABORAZIONE NON ESISTENTE O FASE NON AMMESSA
	PAGOPA_ERR_19	CONSTANT  varchar :='19';--ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FLUSSO DI RICONCILIAZIONE
	PAGOPA_ERR_20	CONSTANT  varchar :='20';--DATI DI ELABORAZIONE NON ESISTENTI O IN STATO NON AMMESSO
	PAGOPA_ERR_21	CONSTANT  varchar :='21';--ERRORE IN INSERIMENTO DATI DI DETTAGLIO ELABORAZIONE FLUSSO DI RICONCILIAZIONE
	PAGOPA_ERR_22	CONSTANT  varchar :='22';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA NON ESISTENTE
	PAGOPA_ERR_23	CONSTANT  varchar :='23';--DATI DI RICONCILIAZIONE ASSOCIATI A ACCERTAMENTO NON ESISTENTE
  	PAGOPA_ERR_24	CONSTANT  varchar :='24';--TIPO DOCUMENTO IPA NON ESISTENTE
    PAGOPA_ERR_25   CONSTANT  varchar :='25';--BOLLO ESENTE NON ESISTENTE
    PAGOPA_ERR_26   CONSTANT  varchar :='26';--STATO VALIDO DOCUMENTO NON ESISTENTE
    PAGOPA_ERR_27   CONSTANT  varchar :='27';--IDENTIFICATIVO CDC/CDR NON ESISTENTE
    PAGOPA_ERR_28   CONSTANT  varchar :='28';--IDENTIFICATIVO TIPO QUOTA DOCUMENTO NON ESISTENTE
    PAGOPA_ERR_29   CONSTANT  varchar :='29';--IDENTIFICATIVI VARI INESISTENTI
    PAGOPA_ERR_30   CONSTANT  varchar :='30';--ERRORE IN FASE DI INSERIMENTO DOCUMENTO
    PAGOPA_ERR_31   CONSTANT  varchar :='31';--ERRORE IN FASE DI ADEGUAMENTO IMPORTO ACCERTAMENTO
    PAGOPA_ERR_32   CONSTANT  varchar :='32';--ERRORE IN FASE DI VERIFICA DISPONIBILITA PROVVOSORIO DI CASSA
    PAGOPA_ERR_33   CONSTANT  varchar :='33';--DISPONIBILITA INSUFFICIENTE PER PROVVOSORIO DI CASSA
    PAGOPA_ERR_34   CONSTANT  varchar :='34';--DATI DI RICONCILIAZIONE ASSOCIATI A SOGGETTO NON ESISTENTE
    PAGOPA_ERR_35   CONSTANT  varchar :='35';--DATI DI RICONCILIAZIONE ASSOCIATI A STRUTTURA AMMINISTRATIVA NON ESISTENTE

    PAGOPA_ERR_36   CONSTANT  varchar :='36';--DATI DI RICONCILIAZIONE SCARTATI PER ANOMALIA SU GENERAZIONE DOC. PER PROV. CASSA

    PAGOPA_ERR_37   CONSTANT  varchar :='37';--ERRORE IN LETTURA PROGRESSIVI DOCUMENTI
    PAGOPA_ERR_38   CONSTANT  varchar :='38';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA REGOLARIZZATO
    PAGOPA_ERR_39   CONSTANT  varchar :='39';--PROVVISORIO DI CASSA REGOLARIZZATO


	-- 31.05.2019 siac-6720
	PAGOPA_ERR_41   CONSTANT  varchar :='41';--ESTREMI SOGGETTO NON PRESENTI PER DETTAGLIO
	PAGOPA_ERR_42   CONSTANT  varchar :='42';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO NON PRESENTE
	PAGOPA_ERR_43   CONSTANT  varchar :='43';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO NON VALIDO
 	PAGOPA_ERR_44   CONSTANT  varchar :='44';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO VALIDO NON UNIVOCO COD.FISC.
 	PAGOPA_ERR_45   CONSTANT  varchar :='45';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO VALIDO NON UNIVOCO PIVA
 	PAGOPA_ERR_46   CONSTANT  varchar :='46';--DATI RICONCILIAZIONE DETTAGLIO FAT. SENZA IDENTIFICATIVO SOGGETTO ASSOCIATO
 	PAGOPA_ERR_47   CONSTANT  varchar :='47';--ERRORE IN LETTURA IDENTIFICATIVO ATTRIBUTI ACCERTAMENTO
    PAGOPA_ERR_48   CONSTANT  varchar :='48';--TIPO DOCUMENTO NON PRESENTE SU DATI DI RICONCILIAZIONE
    PAGOPA_ERR_49   CONSTANT  varchar :='49';--DETTAGLI NON PRESENTI SU DATI DI RICONCILIAZIONE CON DETT
    PAGOPA_ERR_50   CONSTANT  varchar :='50';--DATI RICONCILIAZIONE DETTAGLIO FAT. PRIVI DI IMPORTO

    -- 22.07.2019 Sofia siac-6963 - inizio
	PAGOPA_ERR_51   CONSTANT  varchar :='51';--DATI RICONCILIAZIONE CON ACCERTAMENTO PRIVO DI SOGGETTO O INESISTENTE

    DOC_STATO_VALIDO    CONSTANT  varchar :='V';
	DOC_TIPO_IPA    CONSTANT  varchar :='IPA';
    --- 12.06.2019 SIAC-6720
    DOC_TIPO_COR    CONSTANT  varchar :='COR';
    DOC_TIPO_FAT    CONSTANT  varchar :='FTV';

    -- attributi siac_t_doc
	ANNO_REPERTORIO_ATTR CONSTANT varchar:='anno_repertorio';
	NUM_REPERTORIO_ATTR CONSTANT varchar:='num_repertorio';
	DATA_REPERTORIO_ATTR CONSTANT varchar:='data_repertorio';
	REG_REPERTORIO_ATTR CONSTANT varchar:='registro_repertorio';
	ARROTONDAMENTO_ATTR CONSTANT varchar:='arrotondamento';

	CAUS_SOSPENSIONE_ATTR CONSTANT varchar:='causale_sospensione';
	DATA_SOSPENSIONE_ATTR CONSTANT varchar:='data_sospensione';
    DATA_RIATTIVAZIONE_ATTR CONSTANT varchar:='data_riattivazione';
    DATA_SCAD_SOSP_ATTR CONSTANT varchar:='dataScadenzaDopoSospensione';
    TERMINE_PAG_ATTR CONSTANT varchar:='terminepagamento';
    NOTE_PAG_INC_ATTR CONSTANT varchar:='notePagamentoIncasso';
    DATA_PAG_INC_ATTR CONSTANT varchar:='dataOperazionePagamentoIncasso';

	FL_AGG_QUOTE_ELE_ATTR CONSTANT varchar:='flagAggiornaQuoteDaElenco';
    FL_SENZA_NUM_ATTR CONSTANT varchar:='flagSenzaNumero';
    FL_REG_RES_ATTR CONSTANT varchar:='flagDisabilitaRegistrazioneResidui';
    FL_PAGATA_INC_ATTR CONSTANT varchar:='flagPagataIncassata';
    COD_FISC_PIGN_ATTR CONSTANT varchar:='codiceFiscalePignorato';
    DATA_RIC_PORTALE_ATTR CONSTANT varchar:='dataRicezionePortale';

	FL_AVVISO_ATTR	 CONSTANT varchar:='flagAvviso';
    FL_ESPROPRIO_ATTR	 CONSTANT varchar:='flagEsproprio';
    FL_ORD_MANUALE_ATTR	 CONSTANT varchar:='flagOrdinativoManuale';
    FL_ORD_SINGOLO_ATTR	 CONSTANT varchar:='flagOrdinativoSingolo';
    FL_RIL_IVA_ATTR	 CONSTANT varchar:='flagRilevanteIVA';

    CAUS_ORDIN_ATTR	 CONSTANT varchar:='causaleOrdinativo';
    DATA_ESEC_PAG_ATTR	 CONSTANT varchar:='dataEsecuzionePagamento';


    TERMINE_PAG_DEF  CONSTANT integer=30;

    provvisorioId integer:=null;
    bilancioId integer:=null;
    periodoId integer:=null;

    filePagoPaId                    integer:=null;
    filePagoPaFileXMLId             varchar:=null;

    bElabora boolean:=true;
    bErrore boolean:=false;

    docTipoId integer:=null;

    --- 12.06.2019 Siac-6720
    docTipoFatId integer:=null;
    docTipoCorId integer:=null;
    docTipoCorNumAutom integer:=null;
    docTipoFatNumAutom integer:=null;
    nProgressivoFat integer:=null;
    nProgressivoCor integer:=null;
    nProgressivoTemp integer:=null;
	isDocIPA boolean:=false;

    codBolloId integer:=null;
    dDocImporto numeric:=null;
    dispAccertamento numeric:=null;
	dispProvvisorioCassa numeric:=null;

    strElencoFlussi varchar:=null;
    docStatoValId   integer:=null;
    cdrTipoId integer:=null;
    cdcTipoId integer:=null;
    subDocTipoId integer:=null;
	movgestTipoId  integer:=null;
    movgestTsTipoId integer:=null;
    movgestStatoId integer:=null;
    provvisorioTipoId integer:=null;
	movgestTsDetTipoId integer:=null;
	dnumQuote integer:=0;
    movgestTsId integer:=null;
    subdocMovgestTsId integer:=null;

    annoBilancio integer:=null;

    -- 11.06.2019 SIAC-6720
	numModifica  integer:=null;
    attoAmmId    integer:=null;
    modificaTipoId integer:=null;
    modifId       integer:=null;
    modifStatoId  integer:=null;
    modStatoRId   integer:=Null;

    fncRec record;
    pagoPaFlussoRec record;
    pagoPaFlussoQuoteRec record;
    elabRec record;

BEGIN

	strMessaggioFinale:='Elaborazione rinconciliazione PAGOPA per '||
                        'Id. elaborazione filePagoPaElabId='||filePagoPaElabId::varchar||
                        ' AnnoBilancioElab='||annoBilancioElab::varchar||'.';

    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale;
--    raise notice '%',strMessaggioLog;

	insert into pagopa_t_elaborazione_log
    (
     pagopa_elab_id,
     pagopa_elab_file_id,
     pagopa_elab_log_operazione,
     ente_proprietario_id,
     login_operazione,
     data_creazione
    )
    values
    (
     filePagoPaElabId,
     null,
     strMessaggioLog,
	 enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );
    GET DIAGNOSTICS codResult = ROW_COUNT;
--    raise notice '2222%',strMessaggioLog;
--    raise notice '2222-codResult- %',codResult;
    codResult:=null;
    codiceRisultato:=0;
    messaggioRisultato:='';


    strMessaggio:='Verifica esistenza elaborazione.';
    --select elab.file_pagopa_id, elab.pagopa_elab_file_id into filePagoPaId, filePagoPaFileXMLId
    select 1 into codResult
    from pagopa_t_elaborazione elab, pagopa_d_elaborazione_stato stato
    where elab.pagopa_elab_id=filePagoPaElabId
    and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
    and   stato.pagopa_elab_stato_code in (ELABORATO_IN_CORSO_ST, ELABORATO_IN_CORSO_ER_ST,ELABORATO_IN_CORSO_SC_ST)
    and   stato.ente_proprietario_id=enteProprietarioId
    and   elab.data_cancellazione is null
    and   elab.validita_fine  is null;
--    raise notice '2222strMessaggio%',strMessaggio;

--	if filePagoPaId is null or filePagoPaFileXMLId is null then
    if codResult is null then
        pagoPaCodeErr:=PAGOPA_ERR_20;
        strErrore:=' Non esistente.';
        codResult:=-1;
        bElabora:=false;
    else codResult:=null;
    end if;

/*  elaborazioni multi file
    if codResult is null then
     strMessaggio:='Verifica esistenza file di elaborazione per filePagoPaId='||filePagoPaId::varchar||
                   ' filePagoPaFileXMLId='||filePagoPaFileXMLId||'.';
     select 1 into codResult
     from siac_t_file_pagopa file, siac_d_file_pagopa_stato stato
     where file.file_pagopa_id=filePagoPaId
     and   file.file_pagopa_code=filePagoPaFileXMLId
     and   stato.file_pagopa_stato_id=file.file_pagopa_stato_id
     and   stato.file_pagopa_stato_code in (ELABORATO_IN_CORSO_ST, ELABORATO_IN_CORSO_ER_ST,ELABORATO_IN_CORSO_SC_ST)
     and   stato.ente_proprietario_id=enteProprietarioId
     and   file.data_cancellazione is null
     and   file.validita_fine  is null;

     if codResult is null then
    	pagoPaCodeErr:=PAGOPA_ERR_4;
        strErrore:=' Non esistente.';
        codResult:=-1;
        bElabora:=false;
     else codResult:=null;
     end if;
    end if;
*/


   if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_IPA||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoId
      from siac_d_doc_tipo tipo
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_IPA;
      if docTipoId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      end if;
   end if;

  if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_FAT||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoFatId
      from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_FAT
      and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
      and   fam.doc_fam_tipo_code='E';
      if docTipoFatId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      else
	      select 1 into docTipoFatNumAutom
          from siac_r_doc_tipo_attr rattr,siac_t_attr attr
          where rattr.doc_tipo_id=docTipoFatId
          and   attr.attr_id=rattr.attr_id
          and   attr.attr_code='flagSenzaNumero'
          and   coalesce(rattr.boolean,'N')='S'
          and   rattr.data_cancellazione is null
          and   rattr.validita_fine is null;
      end if;

  end if;

  if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_COR||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoCorId
      from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_COR
      and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
      and   fam.doc_fam_tipo_code='E';

      if docTipoCorId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      else
   	      select 1 into docTipoCorNumAutom
          from siac_r_doc_tipo_attr rattr,siac_t_attr attr
          where rattr.doc_tipo_id=docTipoCorId
          and   attr.attr_id=rattr.attr_id
          and   attr.attr_code='flagSenzaNumero'
          and   coalesce(rattr.boolean,'N')='S'
          and   rattr.data_cancellazione is null
          and   rattr.validita_fine is null;

      end if;
   end if;


   if codResult is null then
    	strMessaggio:='Lettura identificativo bollo esente.';
    	-- lettura tipodocumento
		select cod.codbollo_id into codBolloId
		from siac_d_codicebollo cod
		where cod.ente_proprietario_id=enteProprietarioId
		and   cod.codbollo_desc='ESENTE BOLLO';
        if codBolloId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_25;
    	    strErrore:=' Non riuscita.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;


   if codResult is null then
    	strMessaggio:='Lettura identificativo documento stato='||DOC_STATO_VALIDO||'.';
		select stato.doc_stato_id into docStatoValId
		from siac_d_doc_stato Stato
		where stato.ente_proprietario_id=enteProprietarioId
		and   stato.doc_stato_code=DOC_STATO_VALIDO;
        if docStatoValId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_26;
    	    strErrore:=' Non riuscita.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

    if codResult is null then
    	strMessaggio:='Lettura identificativo tipo CDC.';
		select tipo.classif_tipo_id into cdcTipoId
		from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code='CDC';
        if cdcTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_27;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo CDR.';
		select tipo.classif_tipo_id into cdrTipoId
		from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code='CDR';
        if cdrTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_27;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;


	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo subdocumento SE.';
		select tipo.subdoc_tipo_id into subDocTipoId
		from siac_d_subdoc_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.subdoc_tipo_code='SE';
        if subDocTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_28;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo accertamento.';
		select tipo.movgest_tipo_id into movgestTipoId
		from siac_d_movgest_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_tipo_code='A';
        if movgestTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo testata accertamento.';
		select tipo.movgest_ts_tipo_id into movgestTsTipoId
		from siac_d_movgest_ts_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_ts_tipo_code='T';
        if movgestTsTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo stato DEFINITIVO accertamento.';
		select tipo.movgest_stato_id into movgestStatoId
		from siac_d_movgest_stato tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_stato_code='D';
        if movgestStatoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo importo ATTUALE accertamento.';
		select tipo.movgest_ts_det_tipo_id into movgestTsDetTipoId
		from siac_d_movgest_ts_det_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_ts_det_tipo_code='A';
        if movgestTsDetTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;



	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo provvissorio cassa entrata.';
		select tipo.provc_tipo_id into provvisorioTipoId
		from siac_d_prov_cassa_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.provc_tipo_code='E';
        if provvisorioTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;

	if codResult is null then
     strMessaggio:='Gestione scarti di elaborazione. Verifica annoBilancio indicato su dettagli di riconciliazione.';
--    raise notice '2222@@%',strMessaggio;

     select  distinct doc.pagopa_ric_doc_anno_esercizio into annoBilancio
     from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
     where flusso.pagopa_elab_id=filePagoPaElabId
     and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc.pagopa_ric_doc_stato_elab='N'
     and   doc.pagopa_ric_doc_subdoc_id is null
     and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and   not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and   doc.data_cancellazione is null
     and   doc.validita_fine is null
     and   flusso.data_cancellazione is null
     and   flusso.validita_fine is null
     limit 1;
     if annoBilancio is null then
       	pagoPaCodeErr:=PAGOPA_ERR_12;
        strErrore:=' Dati non presenti.';
        codResult:=-1;
        bElabora:=false;
     else
     	if annoBilancio>annoBilancioElab then
           	pagoPaCodeErr:=PAGOPA_ERR_11;
	        strErrore:=' Anno bilancio successivo ad anno di elaborazione.';
    	    codResult:=-1;
        	bElabora:=false;
        end if;
     end if;
--         raise notice '2222@@strErrore%',strErrore;

	end if;


    if codResult is null then
	 strMessaggio:='Gestione scarti di elaborazione. Verifica fase bilancio per elaborazione.';
	 select bil.bil_id, per.periodo_id into bilancioId , periodoId
     from siac_t_bil bil,siac_t_periodo per,
          siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where per.ente_proprietario_id=enteProprietarioid
     and   per.anno::integer=annoBilancio
     and   bil.periodo_id=per.periodo_id
     and   r.bil_id=bil.bil_id
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST);
     if bilancioId is null then
     	pagoPaCodeErr:=PAGOPA_ERR_18;
        strErrore:=' Fase non ammessa per elaborazione.';
        codResult:=-1;
        bElabora:=false;
	 end if;
   end if;

   if codResult is null then
	  strMessaggio:='Gestione scarti di elaborazione. Lettura progressivo doc. siac_t_doc_num per anno='||annoBilancio::varchar||'.';

      nProgressivo:=0;
      insert into  siac_t_doc_num
      (
        doc_anno,
        doc_numero,
        doc_tipo_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
      )
      select annoBilancio,
             nProgressivo,
             docTipoId,
             clock_timestamp(),
             loginOperazione,
             bil.ente_proprietario_id
      from siac_t_bil bil
      where bil.bil_id=bilancioId
      and not exists
      (
      select 1
      from siac_t_doc_num num
      where num.ente_proprietario_id=bil.ente_proprietario_id
      and   num.doc_anno::integer=annoBilancio
      and   num.doc_tipo_id=docTipoId
      and   num.data_cancellazione is null
      and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
      )
      returning doc_num_id into codResult;

      if codResult is null then
      	select num.doc_numero into codResult
        from siac_t_doc_num num
        where num.ente_proprietario_id=enteProprietarioId
        and   num.doc_anno::integer=annoBilancio
        and   num.doc_tipo_id=docTipoId;

        if codResult is not null then
        	nProgressivo:=codResult;
            codResult:=null;
        else
            pagoPaCodeErr:=PAGOPA_ERR_37;
        	strErrore:=' Progressivo non reperito.';
	        codResult:=-1;
    	    bElabora:=false;
        end if;
      else codResult:=null;
      end if;

   end if;

   --- 12.06.2019 Sofia SIAC-6720
   if codResult is null and
      (docTipoCorNumAutom is not null or docTipoFatNumAutom is not null ) then
	  strMessaggio:='Gestione scarti di elaborazione. Lettura progressivo doc. siac_t_doc_num ['
                   ||DOC_TIPO_FAT||'-'
                   ||DOC_TIPO_COR
                   ||'] per anno='||annoBilancio::varchar||'.';

      nProgressivoFat:=0;
      nProgressivoCor:=0;
      insert into  siac_t_doc_num
      (
        doc_anno,
        doc_numero,
        doc_tipo_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
      )
      select annoBilancio,
             nProgressivoFat,
             tipo.doc_tipo_id,
             clock_timestamp(),
             loginOperazione,
             bil.ente_proprietario_id
      from siac_t_bil bil,siac_d_doc_tipo tipo
      where bil.bil_id=bilancioId
      --and   tipo.doc_tipo_id in (docTipoFatId,docTipoCorId)
      and   tipo.doc_tipo_id in
      (select docTipoCorId doc_tipo_id where  docTipoCorNumAutom is not null
       union
       select docTipoFatId doc_tipo_id where  docTipoFatNumAutom is not null
      )
      and not exists
      (
      select 1
      from siac_t_doc_num num
      where num.ente_proprietario_id=bil.ente_proprietario_id
      and   num.doc_anno::integer=annoBilancio
      and   num.doc_tipo_id=tipo.doc_tipo_id
      and   num.data_cancellazione is null
      and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
      );
      GET DIAGNOSTICS codResult = ROW_COUNT;

	  codResult:=null;
      --if codResult is null then
      if docTipoCorNumAutom is not null then
          select num.doc_numero into codResult
          from siac_t_doc_num num
          where num.ente_proprietario_id=enteProprietarioId
          and   num.doc_anno::integer=annoBilancio
          and   num.doc_tipo_id =docTipoCorId;

          if codResult is not null then
              nProgressivoCor:=codResult;
              codResult:=null;
          else
              pagoPaCodeErr:=PAGOPA_ERR_37;
              strErrore:=' Progressivo non reperito.';
              codResult:=-1;
              bElabora:=false;
          end if;
      end if;

      if docTipoFatNumAutom is not null and codResult is null then
          select num.doc_numero into codResult
          from siac_t_doc_num num
          where num.ente_proprietario_id=enteProprietarioId
          and   num.doc_anno::integer=annoBilancio
          and   num.doc_tipo_id =docTipoFatId;

          if codResult is not null then
              nProgressivoFat:=codResult;
              codResult:=null;
          else
              pagoPaCodeErr:=PAGOPA_ERR_37;
              strErrore:=' Progressivo non reperito.';
              codResult:=-1;
              bElabora:=false;
          end if;
      end if;
--    else codResult:=null;
--    end if;

   end if;

   if codResult is null then
    strMessaggio:='Gestione scarti di elaborazione. Inserimento siac_t_registrounico_doc_num per anno='||annoBilancio::varchar||'.';

	insert into  siac_t_registrounico_doc_num
    (
	  rudoc_registrazione_anno,
	  rudoc_registrazione_numero,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select annoBilancio,
           0,
           clock_timestamp(),
           loginOperazione,
           bil.ente_proprietario_id
    from siac_t_bil bil
    where bil.bil_id=bilancioId
    and not exists
    (
    select 1
    from siac_t_registrounico_doc_num num
    where num.ente_proprietario_id=bil.ente_proprietario_id
    and   num.rudoc_registrazione_anno::integer=annoBilancio
    and   num.data_cancellazione is null
    and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
    );
   end if;



    -- gestione scarti
    -- provvisorio non esistente
    if codResult is null then

 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_22||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_22 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    not exists
     (
     select 1
     from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.provc_tipo_code='E'
     and   prov.provc_tipo_id=tipo.provc_tipo_id
     and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
     and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
     and   prov.provc_data_annullamento is null
     and   prov.provc_data_regolarizzazione is null
     and   prov.data_cancellazione is null
     and   prov.validita_fine is null
     )
     and    not exists -- esclusione flussi ( per provvisorio ) con scarti
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_22
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_22;
        strErrore:=' Provvisori di cassa non esistenti.';
     end if;
	 codResult:=null;
    end if;
--    raise notice 'strErrore=%',strErrore;

    --- provvisorio esistente , ma regolarizzato
    if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_38||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_38 %',strMessaggio;
     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     select 1
     from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo, siac_r_ordinativo_prov_cassa rp
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.provc_tipo_code='E'
     and   prov.provc_tipo_id=tipo.provc_tipo_id
     and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
     and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
     and   rp.provc_id=prov.provc_id
     and   prov.provc_data_annullamento is null
     and   prov.provc_data_regolarizzazione is null
     and   prov.data_cancellazione is null
     and   prov.validita_fine is null
     and   rp.data_cancellazione is null
     and   rp.validita_fine is null
     )
     and    not exists -- esclusione flussi ( per provvisorio ) con scarti
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_38
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)=0 then
       update pagopa_t_riconciliazione_doc doc
       set    pagopa_ric_doc_stato_elab='X',
        	   pagopa_ric_errore_id=err.pagopa_ric_errore_id,
               data_modifica=clock_timestamp(),
               login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
   	   from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
	   where  flusso.pagopa_elab_id=filePagoPaElabId
       and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
       and    doc.pagopa_ric_doc_stato_elab='N'
       and    doc.pagopa_ric_doc_subdoc_id is null
       and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
       and    exists
       (
       select 1
       from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo, siac_r_subdoc_prov_cassa rp
       where tipo.ente_proprietario_id=doc.ente_proprietario_id
       and   tipo.provc_tipo_code='E'
       and   prov.provc_tipo_id=tipo.provc_tipo_id
       and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
       and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
       and   rp.provc_id=prov.provc_id
       and   prov.provc_data_annullamento is null
       and   prov.provc_data_regolarizzazione is null
       and   prov.data_cancellazione is null
       and   prov.validita_fine is null
       and   rp.data_cancellazione is null
       and   rp.validita_fine is null
       )
       and    not exists -- esclusione flussi ( per provvisorio ) con scarti
       (
       select 1
       from pagopa_t_riconciliazione_doc doc1
       where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
       and   doc1.pagopa_ric_doc_stato_elab!='N'
       and   doc1.data_cancellazione is null
       and   doc1.validita_fine is null
       )
       and    err.ente_proprietario_id=flusso.ente_proprietario_id
       and    err.pagopa_ric_errore_code=PAGOPA_ERR_38
       and    flusso.data_cancellazione is null
       and    flusso.validita_fine is null
       and    doc.data_cancellazione is null
       and    doc.validita_fine is null;
       GET DIAGNOSTICS codResult = ROW_COUNT;
     end if;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_38;
        strErrore:=' Provvisori di cassa regolarizzati.';
     end if;
	 codResult:=null;
    end if;

    if codResult is null then
     -- accertamento non esistente
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_23||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_23 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    not exists
     (
     select 1
     from siac_t_movgest mov, siac_d_movgest_tipo tipo,
          siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
          siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.movgest_tipo_code='A'
     and   mov.movgest_tipo_id=tipo.movgest_tipo_id
     and   mov.bil_id=bilancioId
     and   ts.movgest_id=mov.movgest_id
     and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
     and   tipots.movgest_ts_tipo_code='T'
     and   rs.movgest_ts_id=ts.movgest_ts_id
     and   stato.movgest_stato_id=rs.movgest_stato_id
     and   stato.movgest_stato_code='D'
     and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
     and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
     and   mov.data_cancellazione is null
     and   mov.validita_fine is null
     and   ts.data_cancellazione is null
     and   ts.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_23
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0  then
     	pagoPaCodeErr:=PAGOPA_ERR_23;
        strErrore:=' Accertamenti non esistenti.';
     end if;
     codResult:=null;
   end if;

--   raise notice 'strErrore=%',strErrore;

   -- siac-6720 31.05.2019 controlli - inizio


   -- dettagli con codice fiscale non indicato
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_41||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_41
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_41;
        strErrore:=' Estremi soggetto non indicati per dati di dettaglio-fatt.';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_42||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select  1
     from  siac_t_soggetto sog
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     select  1
     from  siac_t_soggetto sog
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_42
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_42;
        strErrore:=' Soggetto inesistente per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto esistente ma non valido
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_43||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select  1
     from  siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   rs.soggetto_id=sog.soggetto_id
     and   stato.soggetto_stato_id=rs.soggetto_stato_id
     and   stato.soggetto_stato_code='VALIDO'
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     select  1
     from  siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   rs.soggetto_id=sog.soggetto_id
     and   stato.soggetto_stato_id=rs.soggetto_stato_id
     and   stato.soggetto_stato_code='VALIDO'
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_43
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_43;
        strErrore:=' Soggetto esistente non VALIDO per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto esistente valido ma non univoco (diversi soggetti per stesso codice fiscale)
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_44||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     select (case when 1<count(*) then 1 else 0 end)
	 from siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
	 where sog.ente_proprietario_id=enteProprietarioId
	 and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs.soggetto_id=sog.soggetto_id
	 and   stato.soggetto_stato_id=rs.soggetto_stato_id
	 and   stato.soggetto_stato_code='VALIDO'
	 and   sog.data_cancellazione is null
	 and   sog.validita_fine is null
	 and   rs.data_cancellazione is null
	 and   rs.validita_fine is null
	 group by sog.codice_fiscale
	 having count(*)>1
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_44
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_44;
        strErrore:=' Soggetto esistente VALIDO non univoco (cod.fisc) per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   --  soggetto esistente valido ma non univoco (diversi soggetti per stessa partita iva)
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_45||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     select (case when 1<count(*) then 1 else 0 end)
	 from siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
	 where sog.ente_proprietario_id=enteProprietarioId
	 and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs.soggetto_id=sog.soggetto_id
	 and   stato.soggetto_stato_id=rs.soggetto_stato_id
	 and   stato.soggetto_stato_code='VALIDO'
	 and   sog.data_cancellazione is null
	 and   sog.validita_fine is null
	 and   rs.data_cancellazione is null
	 and   rs.validita_fine is null
	 group by sog.partita_iva
	 having count(*)>1
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_45
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_45;
        strErrore:=' Soggetto esistente VALIDO non univoco (p.iva) per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;


   -- aggiornare tutti i dettagli con il soggetto_id
   -- (anche il codice del soggetto !! adesso funziona già tutto con il codice del soggetto impostato )
   if codResult is null then
 	 strMessaggio:='Aggiornamento dati soggetto su dati di riconciliazione di dettaglio per codice fiscale [pagopa_t_riconciliazione_doc].';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_soggetto_id=sog.soggetto_id,
            pagopa_ric_doc_codice_benef=sog.soggetto_code,
            data_modifica=clock_timestamp()
     from pagopa_t_elaborazione_flusso flusso,siac_t_soggetto sog, siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
     and    sog.ente_proprietario_id=enteProprietarioId
	 and    sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and    rs.soggetto_id=sog.soggetto_id
	 and    stato.soggetto_stato_id=rs.soggetto_stato_id
	 and    stato.soggetto_stato_code='VALIDO'
     and    exists
     (
     select 1
	 from siac_t_soggetto sog1,siac_r_soggetto_stato rs1
	 where sog1.ente_proprietario_id=enteProprietarioId
	 and   sog1.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs1.soggetto_id=sog1.soggetto_id
	 and   rs1.soggetto_stato_id=stato.soggetto_stato_id
	 and   sog1.data_cancellazione is null
	 and   sog1.validita_fine is null
	 and   rs1.data_cancellazione is null
	 and   rs1.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null
  	 and    sog.data_cancellazione is null
	 and    sog.validita_fine is null
	 and    rs.data_cancellazione is null
	 and    rs.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     codResult:=null;
     strMessaggio:='Aggiornamento dati soggetto su dati di riconciliazione di dettaglio per partita iva [pagopa_t_riconciliazione_doc].';
     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_soggetto_id=sog.soggetto_id,
            pagopa_ric_doc_codice_benef=sog.soggetto_code,
            data_modifica=clock_timestamp()
     from pagopa_t_elaborazione_flusso flusso,siac_t_soggetto sog, siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
     and    sog.ente_proprietario_id=enteProprietarioId
	 and    sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and    rs.soggetto_id=sog.soggetto_id
	 and    stato.soggetto_stato_id=rs.soggetto_stato_id
	 and    stato.soggetto_stato_code='VALIDO'
     and    exists
     (
     select 1
	 from siac_t_soggetto sog1,siac_r_soggetto_stato rs1
	 where sog1.ente_proprietario_id=enteProprietarioId
	 and   sog1.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs1.soggetto_id=sog1.soggetto_id
	 and   rs1.soggetto_stato_id=stato.soggetto_stato_id
	 and   sog1.data_cancellazione is null
	 and   sog1.validita_fine is null
	 and   rs1.data_cancellazione is null
	 and   rs1.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null
  	 and    sog.data_cancellazione is null
	 and    sog.validita_fine is null
	 and    rs.data_cancellazione is null
	 and    rs.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     codResult:=null;
   end if;

   --  soggetto_id non aggiornato su dettagli di riconciliazione
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_46||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_46
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_46;
        strErrore:=' Esistanza  dati di dettaglio-fatt. senza estremi soggetto aggiornato. ';
     end if;
     codResult:=null;
   end if;

   --  importo non valorizzato  su dettagli di riconciliazione
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_50||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_sottovoce_importo,0)=0
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_50
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_50;
        strErrore:=' Esistanza  dati di dettaglio-fatt. senza importo valorizzato. ';
     end if;
     codResult:=null;
   end if;

   -- siac-6720 31.05.2019 controlli - fine

   -- siac-6720 31.05.2019 controlli commentare il seguente
   -- soggetto indicato non esistente non esistente
   /*if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_34||'.';
     raise notice '2222@@strMessaggio PAGOPA_ERR_34 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_codice_benef is not null
     and    not exists
     (
     select 1
     from siac_t_soggetto sog
     where sog.ente_proprietario_id=doc.ente_proprietario_id
     and   sog.soggetto_code=doc.pagopa_ric_doc_codice_benef
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_34
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_34;
        strErrore:=' Soggetto indicato non esistente.';
     end if;
     codResult:=null;
   end if;*/

   -- struttura amministrativa indicata non esistente indicato non esistente non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_35||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_35 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_str_amm,'')!=''
     and    not exists
     (
     select 1
     from siac_t_class c
     where c.ente_proprietario_id=doc.ente_proprietario_id
     and   c.classif_code=doc.pagopa_ric_doc_str_amm
     and   c.classif_tipo_id in (cdcTipoId,cdrTipoId)
     and   c.data_cancellazione is null
     and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine, date_trunc('DAY',now())))
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_35
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_35;
        strErrore:=' Struttura amministrativa indicata non esistente o non valida.';
     end if;
     codResult:=null;
   end if;

   -- 22.07.2019 Sofia siac-6963 - inizio
   -- accertamento indicato per IPA,COR senza soggetto o soggetto  non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_51||'.';
     raise notice '2222@@strMessaggio PAGOPA_ERR_51 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false
     and    doc.pagopa_ric_doc_flag_dett=false
     and    not exists
     (
      select 1
      from siac_t_movgest mov, siac_d_movgest_tipo tipo,
           siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
           siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato,
           siac_r_movgest_ts_sog rsog,siac_t_soggetto sog
      where tipo.ente_proprietario_id=doc.ente_proprietario_id
      and   tipo.movgest_tipo_code='A'
      and   mov.movgest_tipo_id=tipo.movgest_tipo_id
      and   mov.bil_id=bilancioId
      and   ts.movgest_id=mov.movgest_id
      and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   tipots.movgest_ts_tipo_code='T'
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code='D'
      and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
      and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
      and   rsog.movgest_ts_id=ts.movgest_ts_id
      and   sog.soggetto_id=rsog.soggetto_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   rsog.data_cancellazione is null
      and   rsog.validita_fine is null
      and   sog.data_cancellazione is null
      and   sog.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_51
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_51;
        strErrore:=' Soggetto non indicato su accertamento o non esistente.';
     end if;
     codResult:=null;
   end if;
   -- 22.07.2019 Sofia siac-6963 - fine

--raise notice '@@@@@@@@@@@@@pagoPaCodeErr   %',pagoPaCodeErr;
--raise notice 'codResult   %',codResult;
  ---  aggiornamento di pagopa_t_riconciliazione a partire da pagopa_t_riconciliazione_doc
  ---  per gli scarti prodotti in questa elaborazione
  if codResult is null then
   strMessaggio:='Gestione scarti di elaborazione. Aggiornamento pagopa_t_riconciliazione da pagopa_t_riconciliazione_doc.';
--   raise notice '2222@@strMessaggio   %',strMessaggio;
--   raise notice '@@@@@@@@@@@@@pagoPaCodeErr   %',pagoPaCodeErr;
   update pagopa_t_riconciliazione ric
   set    pagopa_ric_flusso_stato_elab='X',
  	      pagopa_ric_errore_id=doc.pagopa_ric_errore_id,
          data_modifica=clock_timestamp(),
          login_operazione=ric.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
   from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
   where flusso.pagopa_elab_id=filePagoPaElabId
   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
   and   doc.pagopa_ric_doc_stato_elab='X'
   and   doc.login_operazione like '%@ELAB-'|| filePagoPaElabId::varchar||'%'
   and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId --- per elab_id
   and   ric.pagopa_ric_id=doc.pagopa_ric_id;
  end if;
  ---

   if codResult is null then
     strMessaggio:='Verifica esistenza dettagli di riconciliazione da elaborare.';

--     raise notice 'strMessaggio=%',strMessaggio;
     select 1 into codresult
     from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
     where flusso.pagopa_elab_id=filePagoPaElabId
     and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc.pagopa_ric_doc_stato_elab='N'
     and   doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and   not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and   doc.data_cancellazione is null
     and   doc.validita_fine is null
     and   flusso.data_cancellazione is null
     and   flusso.validita_fine is null;
--    raise notice 'codREsult=%',codResult;
     if codResult is null then
       	pagoPaCodeErr:=PAGOPA_ERR_7;
        strErrore:=' Dati non presenti.';
        codResult:=-1;
        bElabora:=false;
     else codResult:=null;
     end if;
   end if;



   if pagoPaCodeErr is not null then
     -- aggiornare anche pagopa_t_riconciliazione e pagopa_t_riconciliazione_doc
     strmessaggioBck:=strMessaggio;
     strMessaggio:=strMessaggio||' '||strErrore||' Aggiornamento pagopa_t_elaborazione.';
--      raise notice 'strMessaggio=%',strMessaggio;
	 update pagopa_t_elaborazione elab
     set    data_modifica=clock_timestamp(),
            validita_fine=(case when bElabora=false then clock_timestamp() else null end ),
            pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
            pagopa_elab_errore_id=err.pagopa_ric_errore_id,
            pagopa_elab_note=upper(strMessaggioFinale||' '||strMessaggio)
     from  pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
     where elab.pagopa_elab_id=filePagoPaElabId
     and   statonew.ente_proprietario_id=elab.ente_proprietario_id
     and   statonew.pagopa_elab_stato_code=(case when bElabora=false then ELABORATO_ERRATO_ST else ELABORATO_IN_CORSO_SC_ST end)
     and   err.ente_proprietario_id=statonew.ente_proprietario_id
     and   err.pagopa_ric_errore_code=pagoPaCodeErr
     and   elab.data_cancellazione is null
     and   elab.validita_fine is null;


     strMessaggio:=strmessaggioBck||' '||strErrore||' Aggiornamento siac_t_file_pagopa.';
     update siac_t_file_pagopa file
     set    data_modifica=clock_timestamp(),
            file_pagopa_stato_id=stato.file_pagopa_stato_id,
            file_pagopa_errore_id=err.pagopa_ric_errore_id,
            file_pagopa_note=upper(strMessaggioFinale||' '||strMessaggio),
            login_operazione=file.login_operazione||'-'||loginOperazione
        from  pagopa_r_elaborazione_file r,
              siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
        where r.pagopa_elab_id=filePagoPaElabId
        and   file.file_pagopa_id=r.file_pagopa_id
        and   stato.ente_proprietario_id=file.ente_proprietario_id
        and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ER_ST
        and   err.ente_proprietario_id=stato.ente_proprietario_id
        and   err.pagopa_ric_errore_code=pagoPaCodeErr
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

     if bElabora= false then
      codiceRisultato:=-1;
      messaggioRisultato:= upper(strMessaggioFinale||' '||strmessaggioBck||' '||strErrore||'.');
      strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_esegui - '||messaggioRisultato;
      insert into pagopa_t_elaborazione_log
      (
       pagopa_elab_id,
       pagopa_elab_file_id,
       pagopa_elab_log_operazione,
       ente_proprietario_id,
       login_operazione,
       data_creazione
      )
      values
      (
       filePagoPaElabId,
       null,
       strMessaggioLog,
       enteProprietarioId,
       loginOperazione,
       clock_timestamp()
      );

      return;
     end if;
   end if;


  pagoPaCodeErr:=null;
  strMessaggio:='Inizio inserimento documenti.';
  strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
  insert into pagopa_t_elaborazione_log
  (
   pagopa_elab_id,
   pagopa_elab_file_id,
   pagopa_elab_log_operazione,
   ente_proprietario_id,
   login_operazione,
   data_creazione
  )
  values
  (
   filePagoPaElabId,
   null,
   strMessaggioLog,
   enteProprietarioId,
   loginOperazione,
   clock_timestamp()
  );

--  raise notice 'strMessaggio=%',strMessaggio;
  for pagoPaFlussoRec in
  (
   with
   pagopa_sogg as
   (
   with
   pagopa as
   (
   select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
   		  coalesce(doc.pagopa_ric_doc_soggetto_id,-1) pagopa_soggetto_id, -- 04.06.2019 siac-6720
		  doc.pagopa_ric_doc_str_amm pagopa_str_amm ,
          doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
		  doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
          doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
          doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento,
          doc.pagopa_ric_doc_tipo_code pagopa_doc_tipo_code, -- siac-6720
          doc.pagopa_ric_doc_tipo_id pagopa_doc_tipo_id -- siac-6720
   from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
   where flusso.pagopa_elab_id=filePagoPaElabId
   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
   and   doc.pagopa_ric_doc_stato_elab='N'
   and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
   and   doc.pagopa_ric_doc_subdoc_id is null
   and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
   )
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null
   and   flusso.data_cancellazione is null
   and   flusso.validita_fine is null
   group by doc.pagopa_ric_doc_codice_benef,
            coalesce(doc.pagopa_ric_doc_soggetto_id,-1), -- 04.06.2019 siac-6720
			doc.pagopa_ric_doc_str_amm,
            doc.pagopa_ric_doc_voce_tematica,
            doc.pagopa_ric_doc_voce_code,
            doc.pagopa_ric_doc_voce_desc,
            doc.pagopa_ric_doc_anno_accertamento,
            doc.pagopa_ric_doc_num_accertamento,
            doc.pagopa_ric_doc_tipo_code, -- siac-6720
            doc.pagopa_ric_doc_tipo_id -- siac-6720
   ),
   sogg as
   (
   select sog.soggetto_id, sog.soggetto_code,sog.soggetto_desc
   from siac_t_soggetto sog
   where sog.ente_proprietario_id=enteProprietarioId
   and   sog.data_cancellazione is null
   and   sog.validita_fine is null
   )
   select pagopa.*,
          sogg.soggetto_id,
          sogg.soggetto_desc
   from pagopa
---        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code) -- 04.06.2019 siac-6720
        left join sogg on (pagopa.pagopa_soggetto_id=sogg.soggetto_id)
   ),
   accertamenti_sogg as
   (
   with
   accertamenti as
   (
   	select mov.movgest_anno::integer, mov.movgest_numero::integer,
           mov.movgest_id, ts.movgest_ts_id
    from siac_t_movgest mov , siac_d_movgest_tipo tipo,
         siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code='A'
    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
    and   mov.bil_id=bilancioId
    and   ts.movgest_id=mov.movgest_id
    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   tipots.movgest_ts_tipo_code='T'
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code='D'
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
   ),
   soggetto_acc as
   (
   select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc,rsog.movgest_ts_id
   from siac_r_movgest_ts_sog rsog, siac_t_soggetto sog
   where sog.ente_proprietario_id=enteProprietarioId
   and   rsog.soggetto_id=sog.soggetto_id
   and   rsog.data_cancellazione is null
   and   rsog.validita_fine is null
   )
   select accertamenti.*,soggetto_acc.soggetto_id, soggetto_acc.soggetto_code,soggetto_acc.soggetto_desc
   from   accertamenti --, soggetto_acc -- 22.07.2019 siac-6963
          left join soggetto_acc on (accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id) -- 22.07.2019 siac-6963
--   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id -- 22.07.2019 siac-6963
   )
   select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
   		   ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc,
		   ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
           pagopa_sogg.pagopa_str_amm,
           pagopa_sogg.pagopa_voce_tematica,
           pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
           pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id -- siac-6720
   from  pagopa_sogg, accertamenti_sogg
   where pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
   and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
   group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
            ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
            ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )  ,
            pagopa_sogg.pagopa_str_amm,
            pagopa_sogg.pagopa_voce_tematica,
            pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
            pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id  -- siac-6720
   order by  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
   			 pagopa_sogg.pagopa_str_amm,
             pagopa_sogg.pagopa_voce_tematica,
			 pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
             pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id  -- siac-6720

  )
  loop
   		-- filePagoPaElabId - elaborazione id
        -- filePagoPaId     - file pagopa id
        -- filePagoPaFileXMLId  - file pagopa id XML
        -- pagopa_soggetto_id
        -- pagopa_soggetto_code
        -- pagopa_voce_code
        -- pagopa_voce_desc
        -- pagopa_str_amm

        -- elementi per inserimento documento

        -- inserimento documento
        -- siac_t_doc ok
        -- siac_r_doc_sog ok
        -- siac_r_doc_stato ok
        -- siac_r_doc_class ok struttura amministrativa
        -- siac_r_doc_attr ok
        -- siac_t_registrounico_doc ok
        -- siac_t_subdoc_num ok

        -- siac_t_subdoc ok
        -- siac_r_subdoc_attr ok
        -- siac_r_subdoc_class -- non ce ne sono

        -- siac_r_subdoc_atto_amm ok
        -- siac_r_subdoc_movgest_ts ok
        -- siac_r_subdoc_prov_cassa ok

        dDocImporto:=0;
        strElencoFlussi:=' ';
        dnumQuote:=0;
        bErrore:=false;

		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_t_doc].';
		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;

        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );

		docId:=null;

        -- 12.06.2019 SIAC-6720
--        nProgressivo:=nProgressivo+1;
        nProgressivoTemp:=null;
        isDocIPA:=false;
        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_FAT and docTipoFatNumAutom is not null then
        	nProgressivoFat:=nProgressivoFat+1;
            nProgressivoTemp:=nProgressivoFat;
        end if;
        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_COR and docTipoCorNumAutom is not null then
        	nProgressivoCor:=nProgressivoCor+1;
            nProgressivoTemp:=nProgressivoCor;
        end if;
        if nProgressivoTemp is null then
	          nProgressivo:=nProgressivo+1;
              nProgressivoTemp:=nProgressivo;
              isDocIPA:=true;
        end if;
--        raise notice 'pagoPaFlussoRec.pagopa_doc_tipo_code=%',pagoPaFlussoRec.pagopa_doc_tipo_code;
--        raise notice 'isDocIPA=%',isDocIPA;
--		raise notice 'nProgressivo=%',nProgressivo;
--        raise notice 'nProgressivoCor=%',nProgressivoCor;
--        raise notice 'nProgressivoFat=%',nProgressivoFat;
		-- siac_t_doc
        insert into siac_t_doc
        (
        	doc_anno,
		    doc_numero,
			doc_desc,
		    doc_importo,
		    doc_data_emissione, -- dataElaborazione
			doc_data_scadenza,  -- dataSistema
		    doc_tipo_id,
		    codbollo_id,
		    validita_inizio,
		    ente_proprietario_id,
		    login_operazione,
		    login_creazione,
            login_modifica,
			pcccod_id, -- null ??
	        pccuff_id -- null ??
        )
        select annoBilancio,
               pagoPaFlussoRec.pagopa_voce_code||' '||dataElaborazione||' '||nProgressivoTemp::varchar,
               upper('Incassi '
               		 ||substring(coalesce(pagoPaFlussoRec.pagopa_voce_tematica,' '),1,30)||' '
                     ||pagoPaFlussoRec.pagopa_voce_code||' '
                     ||substring(coalesce(pagoPaFlussoRec.pagopa_voce_desc,' '),1,30) ||' '||strElencoFlussi),
			   dDocImporto,
               dataElaborazione,
               dataElaborazione,
--			   docTipoId, siac-6720 28.05.2019 Sofia
               pagoPaFlussoRec.pagopa_doc_tipo_id, -- siac-6720 28.05.2019 Sofia
               codBolloId,
               clock_timestamp(),
               enteProprietarioId,
               loginOperazione,
               loginOperazione,
               loginOperazione,
               null,
               null
        returning doc_id into docId;
--	    raise notice 'docid=%',docId;
		if docId is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
        end if;

		if bErrore=false then
		 codResult:=null;
	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_r_doc_sog].';
		 -- siac_r_doc_sog
         insert into siac_r_doc_sog
         (
        	doc_id,
            soggetto_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
         )
         select  docId,
                 pagoPaFlussoRec.pagopa_soggetto_id,
                 clock_timestamp(),
                 loginOperazione,
                 enteProprietarioId
         returning  doc_sog_id into codResult;

         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';

         end if;
        end if;

	    if bErrore=false then
         codResult:=null;
	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_r_doc_stato].';
         insert into siac_r_doc_stato
         (
        	doc_id,
            doc_stato_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
         )
         select docId,
                docStatoValId,
                clock_timestamp(),
                loginOperazione,
                enteProprietarioId
         returning doc_stato_r_id into codResult;
		 if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
		end if;

        if bErrore=false then
         -- siac_r_doc_attr
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||ANNO_REPERTORIO_ATTR||' [siac_r_doc_attr].';

         -- anno_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
         	    --annoBilancio::varchar,
                NULL,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=ANNO_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then

	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||NUM_REPERTORIO_ATTR||' [siac_r_doc_attr].';

         -- num_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
         	    null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=NUM_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||DATA_REPERTORIO_ATTR||' [siac_r_doc_attr].';
		 -- data_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
--        	    extract( 'day' from now())::varchar||'/'||
--               lpad(extract( 'month' from now())::varchar,2,'0')||'/'||
--               extract( 'year' from now())::varchar,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=DATA_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

        if bErrore=false then
		 -- registro_repertorio
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||REG_REPERTORIO_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=REG_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
		 -- arrotondamento
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||ARROTONDAMENTO_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            numerico,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                0,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=ARROTONDAMENTO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		/*if bErrore=false then
         -- causale_sospensione
 		 -- data_sospensione
 		 -- data_riattivazione
   		 -- dataScadenzaDopoSospensione
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi sospensione [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code in (CAUS_SOSPENSIONE_ATTR,DATA_SOSPENSIONE_ATTR,DATA_RIATTIVAZIONE_ATTR/*,DATA_SCAD_SOSP_ATTR*/);
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;*/

        if bErrore=false then
		 -- terminepagamento
		 strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||TERMINE_PAG_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            numerico,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                TERMINE_PAG_DEF,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=TERMINE_PAG_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		/*if bErrore=false then
	     -- notePagamentoIncasso
    	 -- dataOperazionePagamentoIncasso
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi pagamento incasso [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code in (NOTE_PAG_INC_ATTR,DATA_PAG_INC_ATTR);
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;*/

		if bErrore=false then
         -- flagAggiornaQuoteDaElenco
		 -- flagSenzaNumero
		 -- flagDisabilitaRegistrazioneResidui
		 -- flagPagataIncassata
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi flag [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            boolean,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                'N',
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
--         and   a.attr_code in (/*FL_AGG_QUOTE_ELE_ATTR,*/FL_SENZA_NUM_ATTR,FL_REG_RES_ATTR);--,FL_PAGATA_INC_ATTR);
         and   a.attr_code=FL_REG_RES_ATTR;

         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
		 -- codiceFiscalePignorato
		 -- dataRicezionePortale

		 strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi vari [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
--         and   a.attr_code in (COD_FISC_PIGN_ATTR,DATA_RIC_PORTALE_ATTR);
         and   a.attr_code=DATA_RIC_PORTALE_ATTR;
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;
        if bErrore=false then
		 -- siac_r_doc_class
         if coalesce(pagoPaFlussoRec.pagopa_str_amm ,'')!='' then
            strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa [siac_r_doc_class]'
                         ||'. Verifica esistenza come CDC.';

        	codResult:=null;
            select c.classif_id into codResult
            from siac_t_class c
            where c.classif_tipo_id=cdcTipoId
            and   c.classif_code=pagoPaFlussoRec.pagopa_str_amm
            and   c.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine,date_trunc('DAY',now())));
            if codResult is null then
                strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa  [siac_r_doc_class]'
                         ||'. Verifica esistenza come CDR.';
	            select c.classif_id into codResult
    	        from siac_t_class c
        	    where c.classif_tipo_id=cdrTipoId
	           	and   c.classif_code=pagoPaFlussoRec.pagopa_str_amm
    	        and   c.data_cancellazione is null
        	    and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine,date_trunc('DAY',now())));
            end if;
            if codResult is not null then
               codResult1:=codResult;
               codResult:=null;
	           strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa  [siac_r_doc_class].';

            	insert into siac_r_doc_class
                (
                	doc_id,
                    classif_id,
                    validita_inizio,
                    login_operazione,
                    ente_proprietario_id
                )
                values
                (
                	docId,
                    codResult1,
                    clock_timestamp(),
                    loginOperazione,
                    enteProprietarioId
                )
                returning doc_classif_id into codResult;

                if codResult is null then
                	bErrore:=true;
		            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
                end if;
            end if;
         end if;
        end if;

		if bErrore =false then
		 --  siac_t_registrounico_doc
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento registro unico documento [siac_t_registrounico_doc].';

      	 codResult:=null;
         insert into siac_t_registrounico_doc
         (
        	rudoc_registrazione_anno,
 			rudoc_registrazione_numero,
			rudoc_registrazione_data,
			doc_id,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select num.rudoc_registrazione_anno,
                num.rudoc_registrazione_numero+1,
                clock_timestamp(),
                docId,
                loginOperazione,
                clock_timestamp(),
                num.ente_proprietario_id
         from siac_t_registrounico_doc_num num
         where num.ente_proprietario_id=enteProprietarioId
         and   num.rudoc_registrazione_anno=annoBilancio
         and   num.data_cancellazione is null
         and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
         returning rudoc_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
         if bErrore=false then
            codResult:=null;
         	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento registro unico documento [siac_t_registrounico_doc_num].';
         	update siac_t_registrounico_doc_num num
            set    rudoc_registrazione_numero=num.rudoc_registrazione_numero+1,
                   data_modifica=clock_timestamp()
        	where num.ente_proprietario_id=enteProprietarioId
	        and   num.rudoc_registrazione_anno=annoBilancio
         	and   num.data_cancellazione is null
	        and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
            returning num.rudoc_num_id into codResult;
            if codResult is null  then
               bErrore:=true;
               strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
            end if;
         end if;
        end if;

		if bErrore =false then
         codResult:=null;
		 --  siac_t_doc_num
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento progressivi documenti [siac_t_doc_num].';
         --- 12.06.2019 Siac-6720
--         raise notice 'pagoPaFlussoRec.pagopa_doc_tipo_code2=%',pagoPaFlussoRec.pagopa_doc_tipo_code;
         if isDocIPA=true then
           update siac_t_doc_num num
           set    doc_numero=num.doc_numero+1,
                  data_modifica=clock_timestamp()
           where  num.ente_proprietario_id=enteProprietarioid
           and    num.doc_anno=annoBilancio
           and    num.doc_tipo_id=docTipoId
           returning num.doc_num_id into codResult;
         else
           update siac_t_doc_num num
           set    doc_numero=num.doc_numero+1,
                  data_modifica=clock_timestamp()
           where  num.ente_proprietario_id=enteProprietarioid
           and    num.doc_anno=annoBilancio
           and    num.doc_tipo_id =pagoPaFlussoRec.pagopa_doc_tipo_id
           returning num.doc_num_id into codResult;
         end if;
         if codResult is null then
         	 bErrore:=true;
             strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
         end if;
        end if;

        if bErrore=true then
            strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
        end if;


		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento.';
--        raise notice 'strMessaggio=%',strMessaggio;
		if bErrore=false then
			strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
	    end if;

        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );

        for pagoPaFlussoQuoteRec in
  		(
  	     with
           pagopa_sogg as
		   (
           with
		   pagopa as
		   (
		   select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
			      doc.pagopa_ric_doc_str_amm pagopa_str_amm,
                  doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
           		  doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
                  doc.pagopa_ric_doc_sottovoce_code pagopa_sottovoce_code, doc.pagopa_ric_doc_sottovoce_desc pagopa_sottovoce_desc,
                  flusso.pagopa_elab_flusso_anno_provvisorio pagopa_anno_provvisorio,
                  flusso.pagopa_elab_flusso_num_provvisorio pagopa_num_provvisorio,
                  flusso.pagopa_elab_ric_flusso_id pagopa_flusso_id,
                  flusso.pagopa_elab_flusso_nome_mittente pagopa_flusso_nome_mittente,
        		  doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
		          doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento,
                  doc.pagopa_ric_doc_sottovoce_importo pagopa_sottovoce_importo
		   from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
		   where flusso.pagopa_elab_id=filePagoPaElabId
		   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
           and   doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
           and   coalesce(doc.pagopa_ric_doc_voce_tematica,'')=coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
           and   doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
           and   coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
           and   coalesce(doc.pagopa_ric_doc_str_amm,'')=coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
		   and   doc.pagopa_ric_doc_stato_elab='N'
           and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
		   and   doc.pagopa_ric_doc_subdoc_id is null
		   and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
		   (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		   )
		   and   doc.data_cancellazione is null
		   and   doc.validita_fine is null
		   and   flusso.data_cancellazione is null
		   and   flusso.validita_fine is null
		   ),
		   sogg as
		   (
			   select sog.soggetto_id, sog.soggetto_code,sog.soggetto_desc
			   from siac_t_soggetto sog
			   where sog.ente_proprietario_id=enteProprietarioId
			   and   sog.data_cancellazione is null
			   and   sog.validita_fine is null
		   )
		   select pagopa.*,
		          sogg.soggetto_id,
        		  sogg.soggetto_desc
		   from pagopa
		        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code)
		   ),
		   accertamenti_sogg as
		   (
             with
			 accertamenti as
			 (
			   	select mov.movgest_anno::integer, mov.movgest_numero::integer,
		    	       mov.movgest_id, ts.movgest_ts_id
			    from siac_t_movgest mov , siac_d_movgest_tipo tipo,
			         siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
			         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
			    where tipo.ente_proprietario_id=enteProprietarioId
			    and   tipo.movgest_tipo_code='A'
			    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
			    and   mov.bil_id=bilancioId
			    and   ts.movgest_id=mov.movgest_id
			    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
			    and   tipots.movgest_ts_tipo_code='T'
			    and   rs.movgest_ts_id=ts.movgest_ts_id
			    and   stato.movgest_stato_id=rs.movgest_stato_id
			    and   stato.movgest_stato_code='D'
			    and   mov.data_cancellazione is null
			    and   mov.validita_fine is null
			    and   ts.data_cancellazione is null
			    and   ts.validita_fine is null
			    and   rs.data_cancellazione is null
			    and   rs.validita_fine is null
		   ),
		   soggetto_acc as
		   (
			   select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc,rsog.movgest_ts_id
			   from siac_r_movgest_ts_sog rsog, siac_t_soggetto sog
			   where sog.ente_proprietario_id=enteProprietarioId
			   and   rsog.soggetto_id=sog.soggetto_id
			   and   rsog.data_cancellazione is null
			   and   rsog.validita_fine is null
		   )
		   select accertamenti.*,soggetto_acc.soggetto_id, soggetto_acc.soggetto_code,soggetto_acc.soggetto_desc
		   from   accertamenti -- , soggetto_acc -- 22.07.2019 siac-6963
                  left join soggetto_acc on (accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id) -- 22.07.2019 siac-6963
--		   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id -- 22.07.2019 siac-6963
	  	 )
		 select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
   				 ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc	,
                 ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
                 pagopa_sogg.pagopa_str_amm,
                 pagopa_sogg.pagopa_voce_tematica,
                 pagopa_sogg.pagopa_voce_code,  pagopa_sogg.pagopa_voce_desc,
                 pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                 pagopa_sogg.pagopa_flusso_id,
                 pagopa_sogg.pagopa_flusso_nome_mittente,
                 pagopa_sogg.pagopa_anno_provvisorio,
                 pagopa_sogg.pagopa_num_provvisorio,
                 pagopa_sogg.pagopa_anno_accertamento,
		         pagopa_sogg.pagopa_num_accertamento,
                 sum(pagopa_sogg.pagopa_sottovoce_importo) pagopa_sottovoce_importo
  	     from  pagopa_sogg, accertamenti_sogg
 	     where bErrore=false
         and   pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
	   	 and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
         and   (case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )=
	           pagoPaFlussoRec.pagopa_soggetto_id
	     group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
        	      ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
                  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ),
                  pagopa_sogg.pagopa_str_amm,
                  pagopa_sogg.pagopa_voce_tematica,
                  pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                  pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                  pagopa_sogg.pagopa_flusso_id,pagopa_sogg.pagopa_flusso_nome_mittente,
                  pagopa_sogg.pagopa_anno_provvisorio,
                  pagopa_sogg.pagopa_num_provvisorio,
                  pagopa_sogg.pagopa_anno_accertamento,
		          pagopa_sogg.pagopa_num_accertamento
	     order by  pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                   pagopa_sogg.pagopa_anno_provvisorio,
                   pagopa_sogg.pagopa_num_provvisorio,
				   pagopa_sogg.pagopa_anno_accertamento,
		           pagopa_sogg.pagopa_num_accertamento
  	   )
       loop

        codResult:=null;
        codResult1:=null;
        subdocId:=null;
        subdocMovgestTsId:=null;
		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_t_subdoc].';
--        raise notice 'strMessagio=%',strMessaggio;
		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );

		-- siac_t_subdoc
        insert into siac_t_subdoc
        (
        	subdoc_numero,
			subdoc_desc,
			subdoc_importo,
--		    subdoc_nreg_iva,
	        subdoc_data_scadenza,
	        subdoc_convalida_manuale,
	        subdoc_importo_da_dedurre, -- 05.06.2019 SIAC-6893
--	        subdoc_splitreverse_importo,
--	        subdoc_pagato_cec,
--	        subdoc_data_pagamento_cec,
--	        contotes_id INTEGER,
--	        dist_id INTEGER,
--	        comm_tipo_id INTEGER,
	        doc_id,
	        subdoc_tipo_id,
--	        notetes_id INTEGER,
	        validita_inizio,
			ente_proprietario_id,
		    login_operazione,
	        login_creazione,
            login_modifica
        )
        values
        (
        	dnumQuote+1,
            upper('Voce '||pagoPaFlussoQuoteRec.pagopa_voce_code||'/'||pagoPaFlussoQuoteRec.pagopa_sottovoce_code||' '||
            substring(coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,' ' ),1,30)||
            pagoPaFlussoQuoteRec.pagopa_flusso_id||' PSP '||pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente||
            ' Prov. '||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio::varchar||'/'||
            pagoPaFlussoQuoteRec.pagopa_num_provvisorio),
            pagoPaFlussoQuoteRec.pagopa_sottovoce_importo,
            dataElaborazione,
            'M', --- 13.12.2018 Sofia siac-6602
            0,   --- 05.06.2019 SIAC-6893
  			docId,
            subDocTipoId,
            clock_timestamp(),
            enteProprietarioId,
            loginOperazione,
            loginOperazione,
            loginOperazione
        )
        returning subdoc_id into subDocId;
--        raise notice 'subdocId=%',subdocId;
        if subDocId is null then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;

		-- siac_r_subdoc_attr
		-- flagAvviso
		-- flagEsproprio
		-- flagOrdinativoManuale
		-- flagOrdinativoSingolo
		-- flagRilevanteIVA
        codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr vari].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            boolean,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               'N',
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code in
        (
         FL_AVVISO_ATTR,
	     FL_ESPROPRIO_ATTR,
	     FL_ORD_MANUALE_ATTR,
		 FL_ORD_SINGOLO_ATTR,
	     FL_RIL_IVA_ATTR
        );
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if coalesce(codResult,0)=0 then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;

        end if;

		-- causaleOrdinativo
        /*codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr='||CAUS_ORDIN_ATTR||'].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            testo,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               upper('Regolarizzazione incasso voce '||pagoPaFlussoQuoteRec.pagopa_voce_code||'/'||pagoPaFlussoQuoteRec.pagopa_sottovoce_code||' '||
	            substring(coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,' '),1,30)||
    	        ' Prov. '||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio::varchar||'/'||
        	    pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' '),
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code=CAUS_ORDIN_ATTR
        returning subdoc_attr_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;*/

		-- dataEsecuzionePagamento
    	/*codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr='||DATA_ESEC_PAG_ATTR||'].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            testo,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               null,
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code=DATA_ESEC_PAG_ATTR
        returning subdoc_attr_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;*/

  	    -- controllo sfondamento e adeguamento accertamento
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||'. Verifica esistenza accertamento.';

		codResult:=null;
        dispAccertamento:=null;
        movgestTsId:=null;
        select ts.movgest_ts_id into movgestTsId
        from siac_t_movgest mov, siac_t_movgest_ts ts,
             siac_r_movgest_ts_stato rs
        where mov.bil_id=bilancioId
        and   mov.movgest_tipo_id=movgestTipoId
        and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
        and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
        and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=movgestTsTipoId
        and   rs.movgest_ts_id=ts.movgest_ts_id
        and   rs.movgest_stato_id=movgestStatoId
        and   rs.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
        and   ts.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
        and   mov.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())));

        if movgestTsId is not null then
       		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||'. Verifica dispon. accertamento.';

	        select * into dispAccertamento
            from fnc_siac_disponibilitaincassaremovgest (movgestTsId) disponibilita;
--		    raise notice 'dispAccertamento=%',dispAccertamento;
            if dispAccertamento is not null then
            	if dispAccertamento-pagoPaFlussoQuoteRec.pagopa_sottovoce_importo<0 then
                     -- 11.06.2019 SIAC-6720 - inserimento movimento di modifica acc automatico
		      		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                         ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
      					 ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento mov. modifica. Calcolo numero.';


                    numModifica:=null;
                    codResult:=null;
                    select coalesce(max(query.mod_num),0) into numModifica
                    from
                    (
					select  modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_t_movgest_ts_det_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    union
					select modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_r_movgest_ts_sog_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    union
					select modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_r_movgest_ts_sogclasse_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    ) query;

                    if numModifica is null then
                     numModifica:=0;
                    end if;

                    strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                         ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
      					 ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento mov. modifica.';
                    attoAmmId:=null;
                    select ratto.attoamm_id into attoAmmId
                    from siac_r_movgest_ts_atto_amm ratto
                    where ratto.movgest_ts_id=movgestTsId
                    and   ratto.data_cancellazione is null
                    and   ratto.validita_fine is null;
					if attoAmmId is null then
                    	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in lettura atto amministrativo.';
                    end if;

                    if codResult is null and modificaTipoId is null then
                    	select tipo.mod_tipo_id into modificaTipoId
                        from siac_d_modifica_tipo tipo
                        where tipo.ente_proprietario_id=enteProprietarioId
                        and   tipo.mod_tipo_code='ALT';
                        if modificaTipoId is null then
                        	codResult:=-1;
	                        strMessaggio:=strMessaggio||' Errore in lettura modifica tipo.';
                        end if;
                    end if;

                    if codResult is null then
                      modifId:=null;
                      insert into siac_t_modifica
                      (
                          mod_num,
                          mod_desc,
                          mod_data,
                          mod_tipo_id,
                          attoamm_id,
                          login_operazione,
                          validita_inizio,
                          ente_proprietario_id
                      )
                      values
                      (
                          numModifica+1,
                          'Modifica automatica per predisposizione di incasso',
                          dataElaborazione,
                          modificaTipoId,
                          attoAmmId,
                          loginOperazione,
                          clock_timestamp(),
                          enteProprietarioId
                      )
                      returning mod_id into modifId;
                      if modifId is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_t_modifica.';
                      end if;
					end if;

                    if codResult is null and modifStatoId is null then
	                    select stato.mod_stato_id into modifStatoId
                        from siac_d_modifica_stato stato
                        where stato.ente_proprietario_id=enteProprietarioId
                        and   stato.mod_stato_code='V';
                        if modifStatoId is null then
                        	codResult:=-1;
	                        strMessaggio:=strMessaggio||' Errore in lettura stato modifica.';
                        end if;
                    end if;
                    if codResult is null then
                      modStatoRId:=null;
                      insert into siac_r_modifica_stato
                      (
                          mod_id,
                          mod_stato_id,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      values
                      (
                          modifId,
                          modifStatoId,
                          clock_timestamp(),
                          loginOperazione,
                          enteProprietarioId
                      )
                      returning mod_stato_r_id into modStatoRId;
                      if modStatoRId is  null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_r_modifica_stato.';
                      end if;
                    end if;
                    if codResult is null then
                      insert into siac_t_movgest_ts_det_mod
                      (
                          mod_stato_r_id,
                          movgest_ts_det_id,
                          movgest_ts_id,
                          movgest_ts_det_tipo_id,
                          movgest_ts_det_importo,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      select modStatoRId,
                             det.movgest_ts_det_id,
                             det.movgest_ts_id,
                             det.movgest_ts_det_tipo_id,
                             pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento,
                             clock_timestamp(),
                             loginOperazione,
                             det.ente_proprietario_id
                      from siac_t_movgest_ts_det det
                      where det.movgest_ts_id=movgestTsId
                      and   det.movgest_ts_det_tipo_id=movgestTsDetTipoId
                      returning movgest_ts_det_mod_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_t_movgest_ts_det_mod.';
                      else
                        codResult:=null;
                      end if;
                	end if;

                    if codResult is null then
                      strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                           ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                           ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                           ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                           ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
                           ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'.';
                      update siac_t_movgest_ts_det det
                      set    movgest_ts_det_importo=det.movgest_ts_det_importo+
                                                    (pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento),
                             data_modifica=clock_timestamp(),
                             login_operazione=det.login_operazione||'-'||loginOperazione
                      where det.movgest_ts_id=movgestTsId
                      and   det.movgest_ts_det_tipo_id=movgestTsDetTipoId
                      and   det.data_cancellazione is null
                      and   date_trunc('DAY',now())>=date_trunc('DAY',det.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(det.validita_fine,date_trunc('DAY',now())))
                      returning det.movgest_ts_det_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in aggiornamento siac_t_movgest_ts_det.';
                      else codResult:=null;
                      end if;
                    end if;

                    if codResult is null then
                      strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                           ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                           ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                           ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                           ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
                           ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento pagopa_t_modifica_elab.';
                      insert into pagopa_t_modifica_elab
                      (
                          pagopa_modifica_elab_importo,
                          pagopa_elab_id,
                          subdoc_id,
                          mod_id,
                          movgest_ts_id,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      values
                      (
                          pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento,
                          filePagoPaElabId,
                          subDocId,
                          modifId,
                          movgestTsId,
                          clock_timestamp(),
                          loginOperazione,
                          enteProprietarioId
                      )
                      returning pagopa_modifica_elab_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento pagopa_t_modifica_elab.';
                      else codResult:=null;
                      end if;
                    end if;

                    if codResult is not null then
                        --bErrore:=true;
                        pagoPaCodeErr:=PAGOPA_ERR_31;
                    	strMessaggioBck:=strMessaggio||' PAGOPA_ERR_31='||PAGOPA_ERR_31||' .';
--                        raise notice '%', strMessaggioBck;
                        strMessaggio:=' ';
                        raise exception '%', strMessaggioBck;
                    end if;
                     -- 11.06.2019 SIAC-6720 - inserimento movimento di modifica acc automatico
                end if;
            else
            	bErrore:=true;
           		pagoPaCodeErr:=PAGOPA_ERR_31;
                strMessaggio:=strMessaggio||' Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
            						  ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||' errore.';
	            continue;
            end if;
        else
            bErrore:=true;
            pagoPaCodeErr:=PAGOPA_ERR_31;
            strMessaggio:=strMessaggio||' Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
            						  ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||' non esistente.';
            continue;
        end if;


		codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' movgest_ts_id='||movgestTsId::varchar||' [siac_r_subdoc_movgest_ts].';
		-- siac_r_subdoc_movgest_ts
        insert into siac_r_subdoc_movgest_ts
        (
        	subdoc_id,
            movgest_ts_id,
            validita_inizio,
            login_Operazione,
            ente_proprietario_id
        )
        values
        (
               subdocId,
               movgestTsId,
               clock_timestamp(),
               loginOperazione,
               enteProprietarioId
        )
		returning subdoc_movgest_ts_id into codResult;
		if codResult is null then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;
		subdocMovgestTsId:=  codResult;
--        raise notice 'subdocMovgestTsId=%',subdocMovgestTsId;

        -- siac-6720 30.05.2019 - per i corrispettivi non collegare atto_amm
        if pagoPaFlussoRec.pagopa_doc_tipo_code!=DOC_TIPO_COR  then

          -- siac_r_subdoc_atto_amm
          codResult:=null;
          strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                           ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                           ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                           ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_atto_amm].';
          insert into siac_r_subdoc_atto_amm
          (
              subdoc_id,
              attoamm_id,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
          )
          select subdocId,
                 atto.attoamm_id,
                 clock_timestamp(),
                 loginOperazione,
                 atto.ente_proprietario_id
          from siac_r_subdoc_movgest_ts rts, siac_r_movgest_ts_atto_amm atto
          where rts.subdoc_movgest_ts_id=subdocMovgestTsId
          and   atto.movgest_ts_id=rts.movgest_ts_id
          and   atto.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',atto.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(atto.validita_fine,date_trunc('DAY',now())))
          returning subdoc_atto_amm_id into codResult;
          if codResult is null then
              bErrore:=true;
              strMessaggio:=strMessaggio||' Errore in inserimento.';
              continue;
          end if;
        end if;

		-- controllo esistenza e sfondamento disp. provvisorio
        codResult:=null;
        provvisorioId:=null;
        dispProvvisorioCassa:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa].';
        select prov.provc_id into provvisorioId
        from siac_t_prov_cassa prov
        where prov.provc_tipo_id=provvisorioTipoId
        and   prov.provc_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
        and   prov.provc_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
        and   prov.provc_data_annullamento is null
        and   prov.provc_data_regolarizzazione is null
        and   prov.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',prov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(prov.validita_fine,date_trunc('DAY',now())));
--        raise notice 'provvisorioId=%',provvisorioId;

        if provvisorioId is not null then
        	select 1 into codResult
            from siac_r_ordinativo_prov_cassa r
            where r.provc_id=provvisorioId
            and   r.data_cancellazione is null
            and   r.validita_fine is null;
            if codResult is null then
            	select 1 into codResult
	            from siac_r_subdoc_prov_cassa r
    	        where r.provc_id=provvisorioId
                and   r.login_operazione not like '%@PAGOPA-'||filePagoPaElabId::varchar||'%'
        	    and   r.data_cancellazione is null
            	and   r.validita_fine is null;
            end if;
            if codResult is not null then
            	pagoPaCodeErr:=PAGOPA_ERR_39;
	            bErrore:=true;
                strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' regolarizzato.';
       		    continue;
            end if;
        end if;
        if provvisorioId is not null then
           strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa] provc_id='
                         ||provvisorioId::VARCHAR||'. Verifica disponibilita''.';
			select * into dispProvvisorioCassa
            from fnc_siac_daregolarizzareprovvisorio(provvisorioId) disponibilita;
--            raise notice 'dispProvvisorioCassa=%',dispProvvisorioCassa;
--            raise notice 'pagoPaFlussoQuoteRec.pagopa_sottovoce_importo=%',pagoPaFlussoQuoteRec.pagopa_sottovoce_importo;

            if dispProvvisorioCassa is not null then
            	if dispProvvisorioCassa-pagoPaFlussoQuoteRec.pagopa_sottovoce_importo<0 then
                	pagoPaCodeErr:=PAGOPA_ERR_33;
		            bErrore:=true;
                    strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' disp. insufficiente.';
        		    continue;
                end if;
            else
            	pagoPaCodeErr:=PAGOPA_ERR_32;
	            bErrore:=true;
               strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' Errore.';

    	        continue;
            end if;
        else
        	pagoPaCodeErr:=PAGOPA_ERR_32;
            bErrore:=true;
            strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' non esistente.';
            continue;
        end if;


		codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa] provc_id='
                         ||provvisorioId::varchar||'.';
		-- siac_r_subdoc_prov_cassa
        insert into siac_r_subdoc_prov_cassa
        (
        	subdoc_id,
            provc_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        VALUES
        (
               subdocId,
               provvisorioId,
               clock_timestamp(),
               loginOperazione||'@PAGOPA-'||filePagoPaElabId::varchar,
               enteProprietarioId
        )
        returning subdoc_provc_id into codResult;
---        raise notice 'subdoc_provc_id=%',codResult;

        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end  if;

		codResult:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento pagopa_t_riconciliazione_doc per subdoc_id.';
        -- aggiornare pagopa_t_riconciliazione_doc
        update pagopa_t_riconciliazione_doc docUPD
        set    pagopa_ric_doc_subdoc_id=subdocId,
		       pagopa_ric_doc_stato_elab='S',
               pagopa_ric_errore_id=null,
               pagopa_ric_doc_movgest_ts_id=movgestTsId,
               pagopa_ric_doc_provc_id=provvisorioId,
               data_modifica=clock_timestamp(),
               login_operazione=docUPD.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
        from
        (
         with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
			and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
            and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
            and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
                   coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
            and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
            and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
            and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
            and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
            and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
    		and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab='N'
            and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     	    and    doc.pagopa_ric_doc_subdoc_id is null
     		and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          -- 23.07.2019 siac-6963
          accertamenti_sog as
          (
           with
           accertamenti as
           (
              select ts.movgest_ts_id
              from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
              where mov.bil_id=bilancioId
              and   mov.movgest_tipo_id=movgestTipoId
              and   ts.movgest_id=mov.movgest_id
              and   ts.movgest_ts_tipo_id=movgestTsTipoId
              and   rs.movgest_ts_id=ts.movgest_ts_id
              and   rs.movgest_stato_id=movgestStatoId
              and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
              and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
              and   mov.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
              and   ts.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
              and   rs.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
              select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
              from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
              where sog.ente_proprietario_id=enteProprietarioId
              and   rsog.soggetto_id=sog.soggetto_id
              and   sog.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
              and   rsog.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))

           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
--               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog -- 22.07.2019 siac-6963
        ) QUERY
        where docUPD.ente_proprietario_id=enteProprietarioId
        and   docUPD.pagopa_ric_doc_stato_elab='N'
        and   docUPD.pagopa_ric_doc_subdoc_id is null
        and   docUPD.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
        and   docUPD.pagopa_ric_doc_id=QUERY.pagopa_ric_doc_id
        and   QUERY.pagopa_soggetto_id=pagoPaFlussoQuoteRec.pagopa_soggetto_id
        and   docUPD.data_cancellazione is null
        and   docUPD.validita_fine is null;
        GET DIAGNOSTICS codResult = ROW_COUNT;
--		raise notice 'Aggiornati pagopa_t_riconciliazione_doc=%',codResult;
		if coalesce(codResult,0)=0 then
            raise exception ' Errore in aggiornamento.';
        end if;

		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );


        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento pagopa_t_riconciliazione per subdoc_id.';
		codResult:=null;
        -- aggiornare pagopa_t_riconciliazione
        update pagopa_t_riconciliazione ric
        set    pagopa_ric_flusso_stato_elab='S',
			   pagopa_ric_errore_id=null,
               data_modifica=clock_timestamp(),
               login_operazione=ric.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
		from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
        where flusso.pagopa_elab_id=filePagoPaElabId
        and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
        and   doc.pagopa_ric_doc_subdoc_id=subdocId
        and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
        and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
        and   ric.pagopa_ric_id=doc.pagopa_ric_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
--   		raise notice 'Aggiornati pagopa_t_riconciliazione=%',codResult;

--        returning ric.pagopa_ric_id into codResult;
		if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in aggiornamento.';
            strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
            insert into pagopa_t_elaborazione_log
            (
            pagopa_elab_id,
            pagopa_elab_file_id,
            pagopa_elab_log_operazione,
            ente_proprietario_id,
            login_operazione,
            data_creazione
            )
            values
            (
            filePagoPaElabId,
            null,
            strMessaggioLog,
            enteProprietarioId,
            loginOperazione,
            clock_timestamp()
            );


            continue;
        end if;

		dnumQuote:=dnumQuote+1;
        dDocImporto:=dDocImporto+pagoPaFlussoQuoteRec.pagopa_sottovoce_importo;

       end loop;

	   if dnumQuote>0 and bErrore=false then
        -- siac_t_subdoc_num
        codResult:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento numero quote [siac_t_subdoc_num].';
 	    insert into siac_t_subdoc_num
        (
         doc_id,
         subdoc_numero,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
        )
        values
        (
         docId,
         dnumQuote,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
        )
        returning subdoc_num_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
        end if;

		if bErrore =false then
        	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento importo documento.';
        	update siac_t_doc doc
            set    doc_importo=dDocImporto
            where doc.doc_id=docId
            returning doc.doc_id into codResult;
            if codResult is null then
            	bErrore:=true;
            	strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
            end if;
        end if;
       else
        -- non ha inserito quote
        if bErrore=false  then
        	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote non effettuato.';
            bErrore:=true;
        end if;
       end if;



	   if bErrore=true then

    	 strMessaggioBck:=strMessaggio;
         strMessaggio:='Cancellazione dati documento inseriti.'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
--                  raise notice 'pagoPaCodeErr=%',pagoPaCodeErr;

		 if pagoPaCodeErr is null then
         	pagoPaCodeErr:=PAGOPA_ERR_30;
         end if;

         -- pulizia delle tabella pagopa_t_riconciliazione

         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione S].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
  		 update pagopa_t_riconciliazione ric
         set    pagopa_ric_flusso_stato_elab='X',
  			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(ric.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
   	     from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc,
              pagopa_d_riconciliazione_errore errore, siac_t_subdoc sub
         where flusso.pagopa_elab_id=filePagoPaElabId
         and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   sub.doc_id=docId
         and   doc.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
         and   ric.pagopa_ric_id=doc.pagopa_ric_id
         and   exists
         (
         select 1
         from pagopa_t_riconciliazione_doc doc1
         where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc1.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   doc1.pagopa_ric_id=ric.pagopa_ric_id
         and   doc1.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   doc1.validita_fine is null
         and   doc1.data_cancellazione is null
         )
         and   errore.ente_proprietario_id=flusso.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   flusso.data_cancellazione is null
         and   flusso.validita_fine is null
         and   ric.data_cancellazione is null
         and   ric.validita_fine is null
         and   sub.data_cancellazione is null
         and   sub.validita_fine is null;

		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
           pagopa_elab_id,
           pagopa_elab_file_id,
           pagopa_elab_log_operazione,
           ente_proprietario_id,
           login_operazione,
           data_creazione
         )
         values
         (
           filePagoPaElabId,
           null,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
         );

         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione N].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_riconciliazione  docUPD
         set    pagopa_ric_flusso_stato_elab='X',
  			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
         from
         (
		  with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef,
                    doc.pagopa_ric_id
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
            and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
        --    and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
        --    and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
        --           coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
        --    and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
        --    and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
        --    and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
        --    and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
        --   and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
        --	 and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab = 'N'
            and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
			and    doc.pagopa_ric_doc_subdoc_id is null
     	/*	and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )*/
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          -- 23.07.2019 siac-6963
          accertamenti_sog AS
          (
           with
           accertamenti as
           (
                select ts.movgest_ts_id
                from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
                where mov.bil_id=bilancioId
                and   mov.movgest_tipo_id=movgestTipoId
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_tipo_id=movgestTsTipoId
                and   rs.movgest_ts_id=ts.movgest_ts_id
                and   rs.movgest_stato_id=movgestStatoId
            --    and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
             --   and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
                and   mov.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
                and   ts.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
                and   rs.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
	           select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
    		   from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
	           where sog.ente_proprietario_id=enteProprietarioId
               and   rsog.soggetto_id=sog.soggetto_id
	           and   sog.data_cancellazione is null
	           and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
               and   rsog.data_cancellazione is null
               and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
--                accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog -- 22.07.2019 siac-6963
         ) query,pagopa_d_riconciliazione_errore errore
         where docUPD.ente_proprietario_id=enteProprietarioId
--         and   docUPD.pagopa_ric_flusso_stato_elab='N'
         and   docUPD.pagopa_ric_id=QUERY.pagopa_ric_id
         and   QUERY.pagopa_soggetto_id=pagoPaFlussoRec.pagopa_soggetto_id
         and   errore.ente_proprietario_id=docUPD.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   docUPD.data_cancellazione is null
         and   docUPD.validita_fine is null;

         strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );




         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione_doc S].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;

         update pagopa_t_riconciliazione_doc doc
         set    pagopa_ric_doc_stato_elab='X',
			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                pagopa_ric_doc_subdoc_id=null,
                pagopa_ric_doc_movgest_ts_id=null,
                pagopa_ric_doc_provc_id=null,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(doc.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
         from pagopa_t_elaborazione_flusso flusso,
              pagopa_d_riconciliazione_errore errore, siac_t_subdoc sub
         where flusso.pagopa_elab_id=filePagoPaElabId
         and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
         and   doc.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   sub.doc_id=docId
         and   doc.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
         and   errore.ente_proprietario_id=flusso.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   flusso.data_cancellazione is null
         and   flusso.validita_fine is null
         and   sub.data_cancellazione is null
         and   sub.validita_fine is null;

		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );

	     strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione_doc N].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_riconciliazione_doc  docUPD
         set    pagopa_ric_doc_stato_elab='X',
			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                pagopa_ric_doc_subdoc_id=null,
                pagopa_ric_doc_movgest_ts_id=null,
                pagopa_ric_doc_provc_id=null,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
         from
         (
		  with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef,
                    doc.pagopa_ric_id
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
            and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
--            and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
--            and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
--                   coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
--            and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
--            and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
--            and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
--            and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
--            and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
--    		and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab = 'N'
			and    doc.pagopa_ric_doc_subdoc_id is null
            and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
  /*   		and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )*/
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          -- 23.07.2019 siac-6963
          accertamenti_sog as
          (
           with
           accertamenti as
           (
            select ts.movgest_ts_id
            from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
            where mov.bil_id=bilancioID
            and   mov.movgest_tipo_id=movgestTipoId
            and   ts.movgest_id=mov.movgest_id
            and   ts.movgest_ts_tipo_id=movgestTsTipoId
            and   rs.movgest_ts_id=ts.movgest_ts_id
            and   rs.movgest_stato_id=movgestStatoId
            and   rsog.movgest_ts_id=ts.movgest_ts_id
  --          and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
  --          and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and   mov.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
            and   ts.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
            and   rs.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
            select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
            from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
            where sog.ente_proprietario_id=enteProprietarioId
            and   rsog.soggetto_id=sog.soggetto_id
            and   sog.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
            and   rsog.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
---               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog -- 22.07.2019 siac-6963

         ) query,pagopa_d_riconciliazione_errore errore
         where docUPD.ente_proprietario_id=enteProprietarioId
--         and   docUPD.pagopa_ric_doc_stato_elab='N'
         and   docUPD.pagopa_ric_doc_id=QUERY.pagopa_ric_doc_id
         and   QUERY.pagopa_soggetto_id=pagoPaFlussoRec.pagopa_soggetto_id
         and   errore.ente_proprietario_id=docUPD.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   docUPD.data_cancellazione is null
         and   docUPD.validita_fine is null;

  		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );

         -- 11.06.2019 SIAC-6720
         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_modifica_elab].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_modifica_elab r
         set    pagopa_modifica_elab_note='DOCUMENTO CANCELLATO IN ESEGUI PER pagoPaCodeErr='||pagoPaCodeErr||' ',
                subdoc_id=null
         from 	siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;

         strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_movgest_ts].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;

         delete from siac_r_subdoc_movgest_ts r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;

		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_attr].'||strMessaggioBck;
         delete from siac_r_subdoc_attr r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_atto_amm].'||strMessaggioBck;
         delete from siac_r_subdoc_atto_amm r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_prov_cassa].'||strMessaggioBck;
         delete from siac_r_subdoc_prov_cassa r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_subdoc].'||strMessaggioBck;
         delete from siac_t_subdoc doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_sog].'||strMessaggioBck;
         delete from siac_r_doc_sog doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_stato].'||strMessaggioBck;
         delete from siac_r_doc_stato doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_attr].'||strMessaggioBck;
         delete from siac_r_doc_attr doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_class].'||strMessaggioBck;
         delete from siac_r_doc_class doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_registrounico_doc].'||strMessaggioBck;
         delete from siac_t_registrounico_doc doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_subdoc_num].'||strMessaggioBck;
         delete from siac_t_subdoc_num doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_doc].'||strMessaggioBck;
         delete from siac_t_doc doc where doc.doc_id=docId;

		 strMessaggioLog:=strMessaggioFinale||strMessaggio||' - Continue fnc_pagopa_t_elaborazione_riconc_esegui.';
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );

       end if;


  end loop;


  strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - Fine ciclo caricamento documenti - '||strMessaggioFinale;
--  raise notice 'strMessaggioLog=%',strMessaggioLog;
  insert into pagopa_t_elaborazione_log
  (
   pagopa_elab_id,
   pagopa_elab_file_id,
   pagopa_elab_log_operazione,
   ente_proprietario_id,
   login_operazione,
   data_creazione
  )
  values
  (
   filePagoPaElabId,
   null,
   strMessaggioLog,
   enteProprietarioId,
   loginOperazione,
   clock_timestamp()
  );

  -- richiamare function per gestire anomalie e errori su provvisori e flussi in generale
  -- su elaborazione
  -- controllare ogni flusso/provvisorio
  strMessaggio:='Chiamata fnc.';
  select * into  fncRec
  from fnc_pagopa_t_elaborazione_riconc_esegui_clean
  (
    filePagoPaElabId,
    annoBilancioElab,
    enteProprietarioId,
    loginOperazione,
    dataElaborazione
  );
  if fncRec.codiceRisultato=0 then
    if fncRec.pagopaBckSubdoc=true then
    	pagoPaCodeErr:=PAGOPA_ERR_36;
    end if;
  else
  	raise exception '%',fncRec.messaggiorisultato;
  end if;

  -- aggiornare siac_t_registrounico_doc_num
  codResult:=null;
  strMessaggio:='Aggiornamento numerazione su siac_t_registrounico_doc_num.';
  update siac_t_registrounico_doc_num num
  set    rudoc_registrazione_numero= coalesce(QUERY.rudoc_registrazione_numero,0),
         data_modifica=clock_timestamp(),
         login_operazione=num.login_operazione||'-'||loginOperazione
  from
  (
   select max(doc.rudoc_registrazione_numero::integer) rudoc_registrazione_numero
   from  siac_t_registrounico_doc doc
   where doc.ente_proprietario_id=enteProprietarioId
   and   doc.rudoc_registrazione_anno::integer=annoBilancio
   and   doc.data_cancellazione is null
   and   date_trunc('DAY',now())>=date_trunc('DAY',doc.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(doc.validita_fine,date_trunc('DAY',now())))
  ) QUERY
  where num.ente_proprietario_id=enteProprietarioId
  and   num.rudoc_registrazione_anno=annoBilancio
  and   num.data_cancellazione is null
  and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())));
 -- returning num.rudoc_num_id into codResult;
  --if codResult is null then
  --	raise exception 'Errore in fase di aggiornamento.';
  --end if;



  -- chiusura della elaborazione, siac_t_file per errore in generazione per aggiornare pagopa_ric_errore_id
  if coalesce(pagoPaCodeErr,' ') in (PAGOPA_ERR_30,PAGOPA_ERR_31,PAGOPA_ERR_32,PAGOPA_ERR_33,PAGOPA_ERR_36,PAGOPA_ERR_39) then
     strMessaggio:=' Aggiornamento pagopa_t_elaborazione.';
	 update pagopa_t_elaborazione elab
     set    data_modifica=clock_timestamp(),
            pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
            pagopa_elab_errore_id=err.pagopa_ric_errore_id,
            pagopa_elab_note=elab.pagopa_elab_note
            ||' AGGIORNAMENTO PER ERR.='||(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )::varchar||'.'
     from  pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
     where elab.pagopa_elab_id=filePagoPaElabId
     and   statonew.ente_proprietario_id=elab.ente_proprietario_id
     and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_ER_ST
     and   err.ente_proprietario_id=statonew.ente_proprietario_id
     and   err.pagopa_ric_errore_code=(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )
     and   elab.data_cancellazione is null
     and   elab.validita_fine is null;



    strMessaggio:=' Aggiornamento siac_t_file_pagopa.';
    update siac_t_file_pagopa file
    set    data_modifica=clock_timestamp(),
           file_pagopa_stato_id=stato.file_pagopa_stato_id,
           file_pagopa_errore_id=err.pagopa_ric_errore_id,
           file_pagopa_note=file.file_pagopa_note
                    ||' AGGIORNAMENTO PER ERR.='||(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )::varchar||'.',
           login_operazione=file.login_operazione||'-'||loginOperazione
    from  pagopa_r_elaborazione_file r,
          siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
    where r.pagopa_elab_id=filePagoPaElabId
    and   file.file_pagopa_id=r.file_pagopa_id
    and   stato.ente_proprietario_id=file.ente_proprietario_id
    and   err.ente_proprietario_id=stato.ente_proprietario_id
    and   err.pagopa_ric_errore_code=(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

  end if;

  strMessaggio:='Verifica dettaglio elaborati per chiusura pagopa_t_elaborazione.';
--  raise notice 'strMessaggio=%',strMessaggio;

  codResult:=null;
  select 1 into codResult
  from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
  where flusso.pagopa_elab_id=filePagoPaElabId
  and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
  and   doc.pagopa_ric_doc_subdoc_id is not null
  and   doc.pagopa_ric_doc_stato_elab='S'
  and   flusso.data_cancellazione is null
  and   flusso.validita_fine is null
  and   doc.data_cancellazione is null
  and   doc.validita_fine is null;
  -- ELABORATO_KO_ST ELABORATO_OK_SE
  if codResult is not null then
  	  codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is null
      and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
      and   doc.pagopa_ric_doc_stato_elab in ('X','E','N')
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null;
      -- se ci sono S e X,E,N KO
      if codResult is not null then
            pagoPaCodeErr:=ELABORATO_KO_ST;
      -- se si sono solo S OK
      else  pagoPaCodeErr:=ELABORATO_OK_ST;
      end if;
  else -- se non esiste neanche un S allora elaborazione errata o scartata
	  codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is null
      and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
      and   doc.pagopa_ric_doc_stato_elab='X'
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null;
      if codResult is not null then
            pagoPaCodeErr:=ELABORATO_SCARTATO_ST;
      else  pagoPaCodeErr:=ELABORATO_ERRATO_ST;
      end if;
  end if;

  strMessaggio:='Aggiornamento pagopa_t_elaborazione in stato='||pagoPaCodeErr||'.';
  strMessaggioFinale:='CHIUSURA - '||upper(strMessaggioFinale||' '||strMessaggio);
  update pagopa_t_elaborazione elab
  set    data_modifica=clock_timestamp(),
  		 validita_fine=clock_timestamp(),
         pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
         pagopa_elab_note=strMessaggioFinale
  from  pagopa_d_elaborazione_stato statonew
  where elab.pagopa_elab_id=filePagoPaElabId
  and   statonew.ente_proprietario_id=elab.ente_proprietario_id
  and   statonew.pagopa_elab_stato_code=pagoPaCodeErr
  and   elab.data_cancellazione is null
  and   elab.validita_fine is null;

  strMessaggio:='Verifica dettaglio elaborati per chiusura siac_t_file_pagopa.';
  for elabRec in
  (
  select r.file_pagopa_id
  from pagopa_r_elaborazione_file r
  where r.pagopa_elab_id=filePagoPaElabId
  and   r.data_cancellazione is null
  and   r.validita_fine is null
  order by r.file_pagopa_id
  )
  loop

    -- chiusura per siac_t_file_pagopa
    -- capire se ho chiuso per bene pagopa_t_riconciliazione
    -- se esistono S Ok o in corso
    --    se esistono N non elaborati  IN_CORSO no chiusura
    --    se esistono X scartati IN_CORSO_SC no chiusura
    --    se esistono E errati   IN_CORSO_ER no chiusura
    --    se non esistono!=S FINE ELABORATO_Ok con chiusura
    -- se non esistono S, in corso
    --    se esistono N IN_CORSO no chiusura
    --    se esistono X scartati IN_CORSO_SC non chiusura
    --    se esistono E errati IN_CORSO_ER non chiusura
    strMessaggio:='Verifica dettaglio elaborati per chiusura siac_t_file_pagopa file_pagopa_id='||elabRec.file_pagopa_id::varchar||'.';
    codResult:=null;
    pagoPaCodeErr:=null;
    select 1 into codResult
    from  pagopa_t_riconciliazione ric
    where  ric.file_pagopa_id=elabRec.file_pagopa_id
    and   ric.pagopa_ric_flusso_stato_elab='S'
    and   ric.data_cancellazione is null
    and   ric.validita_fine is null;

    if codResult is not null then
      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='N'
  --    and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='X'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_SC_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='E'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ER_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab!='S'
    --  and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is null then
          pagoPaCodeErr:=ELABORATO_OK_ST;
      end if;

    else
      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='N'
   --   and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='X'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_SC_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='E'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ER_ST;
      end if;

    end if;

    if pagoPaCodeErr is not null then
       strMessaggio:='Aggiornamento siac_t_file_pagopa in stato='||pagoPaCodeErr||'.';
       strMessaggioFinale:='CHIUSURA - '||upper(strMessaggioFinale||' '||strMessaggio);
       update siac_t_file_pagopa file
       set    data_modifica=clock_timestamp(),
              validita_fine=(case when pagoPaCodeErr=ELABORATO_OK_ST then clock_timestamp() else null end),
              file_pagopa_stato_id=stato.file_pagopa_stato_id,
              file_pagopa_note=file.file_pagopa_note||upper(strMessaggioFinale),
              login_operazione=file.login_operazione||'-'||loginOperazione
       from  siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
       where file.file_pagopa_id=elabRec.file_pagopa_id
       and   stato.ente_proprietario_id=file.ente_proprietario_id
       and   stato.file_pagopa_stato_code=pagoPaCodeErr;

    end if;

  end loop;

  messaggioRisultato:='OK VERIFICARE STATO ELAB. - '||upper(strMessaggioFinale);
-- raise notice 'messaggioRisultato=%',messaggioRisultato;
  return;


exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

--- 23.07.2019 Sofia siac-6963 - fine


--- 24.07.2019 Sofia siac-6979 - inizio

drop FUNCTION if exists fnc_siac_dwh_programma_cronop
(
  p_ente_proprietario_id integer,
  p_anno_bilancio varchar,
  p_data timestamp
);

CREATE OR REPLACE FUNCTION fnc_siac_dwh_programma_cronop
(
  p_ente_proprietario_id integer,
  p_anno_bilancio varchar,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE


v_user_table varchar;
params varchar;
fnc_eseguita integer;
interval_esec integer:=1;

BEGIN

esito:='fnc_siac_dwh_programma_cronop : inizio - '||clock_timestamp()||'.';
return next;

IF p_ente_proprietario_id IS NULL THEN
	   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo.';
END IF;

IF p_anno_bilancio IS NULL THEN
	   RAISE EXCEPTION 'Errore: Parametro Anno Bilancio nullo.';
END IF;


select count(*) into fnc_eseguita
from siac_dwh_log_elaborazioni log
where log.ente_proprietario_id=p_ente_proprietario_id
and	  log.fnc_elaborazione_inizio >= (now() - interval '13 hours' )::timestamp -- non deve esistere  una elaborazione uguale nelle 13 ore che precedono la chimata
and   log.fnc_name='fnc_siac_dwh_programma_cronop';

-- 22.07.2019 Sofia siac-6973
fnc_eseguita:=0;
if fnc_eseguita<= 0 then
	esito:= 'fnc_siac_dwh_programma_cronop : continue - eseguita da piu'' di '|| interval_esec::varchar||' ore - '||clock_timestamp()||'.';
	return next;


	/* 20.06.2019 Sofia siac-6933
     IF p_data IS NULL THEN
	   IF p_anno_bilancio::integer < to_char(now(),'YYYY')::integer THEN
    	  p_data = to_timestamp('31/12/'||p_anno_bilancio, 'dd/mm/yyyy');
	   ELSE
    	  p_data := now();
	   END IF;
	END IF;*/

	-- 22.07.2019 Sofia siac-6973
    p_data := now();

	select fnc_siac_random_user() into	v_user_table;

	params := p_ente_proprietario_id::varchar||' - '||p_anno_bilancio||' - '||p_data::varchar;


	insert into	siac_dwh_log_elaborazioni
    (
		ente_proprietario_id,
		fnc_name ,
		fnc_parameters ,
		fnc_elaborazione_inizio ,
		fnc_user
	)
	values
    (
		p_ente_proprietario_id,
		'fnc_siac_dwh_programma_cronop',
		params,
		clock_timestamp(),
		v_user_table
	);


	esito:= 'fnc_siac_dwh_programma_cronop : continue - inizio eliminazione dati pregressi (siac_dwh_programma_cronop) - '||clock_timestamp()||'.';
	return next;
	DELETE FROM siac_dwh_programma_cronop
    WHERE ente_proprietario_id = p_ente_proprietario_id;
--    and   programma_cronop_bil_anno=p_anno_bilancio; -- 20.06.2019 SIAC-6933
	esito:= 'fnc_siac_dwh_programma_cronop : continue - fine eliminazione dati pregressi (siac_dwh_programma_cronop) - '||clock_timestamp()||'.';
	return next;

	esito:= 'fnc_siac_dwh_programma_cronop : continue - inizio caricamento programmi-cronop (siac_dwh_programma_cronop) - '||clock_timestamp()||'.';
	RETURN NEXT;

    insert into siac_dwh_programma_cronop
    (
      ente_proprietario_id,
      ente_denominazione,
      programma_code,
      programma_desc,
      programma_stato_code,
      programma_stato_desc,
      programma_ambito_code,
      programma_ambito_desc,
      programma_rilevante_fpv,
      programma_valore_complessivo,
      programma_gara_data_indizione,
      programma_gara_data_aggiudic,
      programma_investimento_in_def,
      programma_note,
      programma_anno_atto_amm,
      programma_num_atto_amm,
      programma_oggetto_atto_amm,
      programma_note_atto_amm,
      programma_code_tipo_atto_amm,
      programma_desc_tipo_atto_amm,
      programma_code_stato_atto_amm,
      programma_desc_stato_atto_amm,
      programma_code_cdr_atto_amm,
      programma_desc_cdr_atto_amm,
      programma_code_cdc_atto_amm,
      programma_desc_cdc_atto_amm,
      programma_cronop_bil_anno,
      programma_cronop_tipo,
      programma_cronop_versione,
      programma_cronop_desc,
      programma_cronop_anno_comp,
      programma_cronop_cap_tipo,
      programma_cronop_cap_articolo,
      programma_cronop_classif_bil,
      programma_cronop_anno_entrata,
      programma_cronop_valore_prev,
      -- 29.04.2019 Sofia jira siac-6255
      -- siac_t_programma
      programma_responsabile_unico,
      programma_spazi_finanziari,
      programma_tipo_code,
      programma_tipo_desc,
      programma_affidamento_code,
      programma_affidamento_desc,
      programma_anno_bilancio,
      -- 20.06.2019 Sofia siac-6933
      programma_sac_tipo,
      programma_sac_code,
      programma_sac_desc,
      programma_cup,
      -- 29.04.2019 Sofia siac-6255
      -- siac_t_cronop
      programma_cronop_data_appfat,
      programma_cronop_data_appdef,
      programma_cronop_data_appesec,
      programma_cronop_data_avviopr,
      programma_cronop_data_agglav,
      programma_cronop_data_inizlav,
      programma_cronop_data_finelav,
      programma_cronop_giorni_dur,
      programma_cronop_data_coll,
      programma_cronop_gest_quad_eco,
      programma_cronop_us_per_fpv_pr,
      programma_cronop_ann_atto_amm,
      programma_cronop_num_atto_amm,
      programma_cronop_ogg_atto_amm,
      programma_cronop_nte_atto_amm,
      programma_cronop_tpc_atto_amm,
      programma_cronop_tpd_atto_amm,
      programma_cronop_stc_atto_amm,
      programma_cronop_std_atto_amm,
      programma_cronop_crc_atto_amm,
      programma_cronop_crd_atto_amm,
      programma_cronop_cdc_atto_amm,
      programma_cronop_cdd_atto_amm,
      -- 20.06.2019 Sofia siac-6933
      entrata_prevista_cronop_entrata,
      programma_cronop_descr_spesa,
      programma_cronop_descr_entrata
    )
    select
      ente.ente_proprietario_id,
      ente.ente_denominazione,
      query.programma_code,
      query.programma_desc,
      query.programma_stato_code,
      query.programma_stato_desc,
      query.programma_ambito_code,
      query.programma_ambito_desc,
      query.programma_rilevante_fpv,
      query.programma_valore_complessivo,
      query.programma_gara_data_indizione,
      query.programma_gara_data_aggiudic,
      query.programma_investimento_in_def,
      query.programma_note,
      query.programma_anno_atto_amm,
      query.programma_num_atto_amm,
      query.programma_oggetto_atto_amm,
      query.programma_note_atto_amm,
      query.programma_code_tipo_atto_amm,
      query.programma_desc_tipo_atto_amm,
      query.programma_code_stato_atto_amm,
      query.programma_desc_stato_atto_amm,
      query.programma_code_cdr_atto_amm,
      query.programma_desc_cdr_atto_amm,
      query.programma_code_cdc_atto_amm,
      query.programma_desc_cdc_atto_amm,
      query.programma_cronop_bil_anno,
      query.programma_cronop_tipo,
      query.programma_cronop_versione,
      query.programma_cronop_desc,
      query.programma_cronop_anno_comp,
      query.programma_cronop_cap_tipo,
      query.programma_cronop_cap_articolo,
      query.programma_cronop_classif_bil,
      query.programma_cronop_anno_entrata,
      query.programma_cronop_valore_prev,
      -- 29.04.2019 Sofia jira siac-6255
      -- siac_t_programma
      query.programma_responsabile_unico,
      query.programma_spazi_finanziari,
      query.programma_tipo_code,
      query.programma_tipo_desc,
      query.programma_affidamento_code,
      query.programma_affidamento_desc,
      query.programma_anno_bilancio,
      -- 20.06.2019 Sofia siac-6933
      query.programma_sac_tipo,
      query.programma_sac_code,
      query.programma_sac_desc,
      query.programma_cup,
      -- 29.04.2019 Sofia siac-6255
      -- siac_t_cronop
      query.cronop_data_approvazione_fattibilita,
      query.cronop_data_approvazione_programma_def,
      query.cronop_data_approvazione_programma_esec,
      query.cronop_data_avvio_procedura,
      query.cronop_data_aggiudicazione_lavori,
      query.cronop_data_inizio_lavori,
      query.cronop_data_fine_lavori,
      query.cronop_giorni_durata,
      query.cronop_data_collaudo,
      query.cronop_gestione_quadro_economico,
      query.cronop_usato_per_fpv_prov,
      query.cronop_anno_atto_amm,
      query.cronop_num_atto_amm,
      query.cronop_oggetto_atto_amm,
      query.cronop_note_atto_amm,
      query.cronop_code_tipo_atto_amm,
      query.cronop_desc_tipo_atto_amm,
      query.cronop_code_stato_atto_amm,
      query.cronop_desc_stato_atto_amm,
      query.cronop_code_cdr_atto_amm,
      query.cronop_desc_cdr_atto_amm,
      query.cronop_code_cdc_atto_amm,
      query.cronop_desc_cdc_atto_amm,
      -- 20.06.2019 Sofia siac-6933
      ''::varchar entrata_prevista_cronop_entrata,
--      (case when query.programma_cronop_tipo='U' then query.programma_cronop_desc -- 24.07.2019 Sofia SIAC-6979
      (case when query.programma_cronop_tipo='U' then query.programma_cronop_cap_desc  -- 24.07.2019 Sofia SIAC-6979
        else ''::varchar end) programma_cronop_descr_spesa,
--      (case when query.programma_cronop_tipo='E' then query.programma_cronop_desc  -- 24.07.2019 Sofia SIAC-6979
      (case when query.programma_cronop_tipo='E' then query.programma_cronop_cap_desc   -- 24.07.2019 Sofia SIAC-6979
        else ''::varchar end) programma_cronop_descr_entrata
    from
    (
    with
    programma as
    (
      select progr.ente_proprietario_id,
             progr.programma_id,
             progr.programma_code,
             progr.programma_desc,
             stato.programma_stato_code,
             stato.programma_stato_desc,
             progr.programma_data_gara_indizione programma_gara_data_indizione,
		     progr.programma_data_gara_aggiudicazione programma_gara_data_aggiudic,
		     progr.investimento_in_definizione programma_investimento_in_def,
             -- 29.04.2019 Sofia siac-6255
             progr.programma_responsabile_unico,
             progr.programma_spazi_finanziari,
             progr.programma_affidamento_id,
             progr.bil_id,
             tipo.programma_tipo_code,
             tipo.programma_tipo_desc
      from siac_t_programma progr, siac_r_programma_stato rs, siac_d_programma_stato stato,
           siac_d_programma_tipo tipo              -- 29.04.2019 Sofia siac-6255
      where stato.ente_proprietario_id=p_ente_proprietario_id
      and   rs.programma_stato_id=stato.programma_stato_id
      and   progr.programma_id=rs.programma_id
      -- 29.04.2019 Sofia siac-6255
      and   tipo.programma_tipo_id=progr.programma_tipo_id
      and   p_data BETWEEN progr.validita_inizio AND COALESCE(progr.validita_fine, p_data)
      and   progr.data_cancellazione is null
      AND   p_data BETWEEN rs.validita_inizio AND COALESCE(rs.validita_fine, p_data)
      and   rs.data_cancellazione  is null
    ),
    progr_ambito_class as
    (
    select rc.programma_id,
           c.classif_code programma_ambito_code,
           c.classif_desc  programma_ambito_desc
    from siac_r_programma_class rc, siac_t_class c, siac_d_class_tipo tipo
    where tipo.ente_proprietario_id=p_ente_proprietario_id
    and   tipo.classif_tipo_code='TIPO_AMBITO'
    and   c.classif_tipo_id=tipo.classif_tipo_id
    and   rc.classif_id=c.classif_id
    and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
    and   rc.data_cancellazione is null
    and   c.data_cancellazione is null
    ),
    -- 20.06.2019 Sofia siac-6933 - inizio
    progr_sac as
    (
    select rc.programma_id,
           tipo.classif_tipo_code programma_sac_tipo,
           c.classif_code programma_sac_code,
           c.classif_desc  programma_sac_desc
    from siac_r_programma_class rc, siac_t_class c, siac_d_class_tipo tipo
    where tipo.ente_proprietario_id=p_ente_proprietario_id
    and   tipo.classif_tipo_code in ('CDC','CDR')
    and   c.classif_tipo_id=tipo.classif_tipo_id
    and   rc.classif_id=c.classif_id
    and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
    and   rc.data_cancellazione is null
    and   c.data_cancellazione is null
    ),
    progr_cup as
    (
    select rattr.programma_id,
           rattr.testo programma_cup
    from siac_r_programma_attr rattr,siac_t_attr attr
    where attr.ente_proprietario_id=p_ente_proprietario_id
    and   attr.attr_code='cup'
    and   rattr.attr_id=attr.attr_id
    and   p_data BETWEEN rattr.validita_inizio AND COALESCE(rattr.validita_fine, p_data)
    and   rattr.data_cancellazione is null
    ),
    -- 20.06.2019 Sofia siac-6933 - fine
    progr_note_attr_ril_fpv as
    (
    select rattr.programma_id,
           rattr.boolean programma_rilevante_fpv
    from siac_r_programma_attr rattr,siac_t_attr attr
    where attr.ente_proprietario_id=p_ente_proprietario_id
    and   attr.attr_code='FlagRilevanteFPV'
    and   rattr.attr_id=attr.attr_id
    and   p_data BETWEEN rattr.validita_inizio AND COALESCE(rattr.validita_fine, p_data)
    and   rattr.data_cancellazione is null
    ),
    progr_note_attr_note as
    (
    select rattr.programma_id,
           rattr.boolean programma_note
    from siac_r_programma_attr rattr,siac_t_attr attr
    where attr.ente_proprietario_id=p_ente_proprietario_id
    and   attr.attr_code='Note'
    and   rattr.attr_id=attr.attr_id
    and   p_data BETWEEN rattr.validita_inizio AND COALESCE(rattr.validita_fine, p_data)
    and   rattr.data_cancellazione is null
    ),
    progr_note_attr_val_compl as
    (
    select rattr.programma_id,
           rattr.numerico programma_valore_complessivo
    from siac_r_programma_attr rattr,siac_t_attr attr
    where attr.ente_proprietario_id=p_ente_proprietario_id
    and   attr.attr_code='ValoreComplessivoProgramma'
    and   rattr.attr_id=attr.attr_id
    and   p_data BETWEEN rattr.validita_inizio AND COALESCE(rattr.validita_fine, p_data)
    and   rattr.data_cancellazione is null
    ),
    progr_atto_amm as
    (
     with
     progr_atto as
     (
      select ratto.programma_id,
             ratto.attoamm_id,
             atto.attoamm_anno        programma_anno_atto_amm,
             atto.attoamm_numero      programma_num_atto_amm,
             atto.attoamm_oggetto     programma_oggetto_atto_amm,
             atto.attoamm_note        programma_note_atto_amm,
             tipo.attoamm_tipo_code   programma_code_tipo_atto_amm,
             tipo.attoamm_tipo_desc   programma_desc_tipo_atto_amm,
             stato.attoamm_stato_code programma_code_stato_atto_amm,
             stato.attoamm_stato_desc programma_desc_stato_atto_amm
      from siac_r_programma_atto_amm ratto , siac_t_atto_amm atto,siac_d_atto_amm_tipo tipo,
           siac_r_atto_amm_stato rs, siac_d_atto_amm_stato stato
      where ratto.ente_proprietario_id=p_ente_proprietario_id
      and   atto.attoamm_id=ratto.attoamm_id
      and   tipo.attoamm_tipo_id=atto.attoamm_tipo_id
      and   rs.attoamm_id=atto.attoamm_id
      and   stato.attoamm_stato_id=rs.attoamm_stato_id
      and   p_data BETWEEN ratto.validita_inizio AND COALESCE(ratto.validita_fine, p_data)
      and   ratto.data_cancellazione is null
      and   p_data BETWEEN atto.validita_inizio AND COALESCE(atto.validita_fine, p_data)
      and   atto.data_cancellazione is null
      and   p_data BETWEEN rs.validita_inizio AND COALESCE(rs.validita_fine, p_data)
      and   rs.data_cancellazione is null
     ),
     atto_cdr as
     (
     select rc.attoamm_id,
            c.classif_code programma_code_cdr_atto_amm,
            c.classif_desc programma_desc_cdr_atto_amm
     from siac_r_atto_amm_class rc, siac_t_class c , siac_d_class_tipo tipo
     where tipo.ente_proprietario_id=p_ente_proprietario_id
     and   tipo.classif_tipo_code='CDR'
     and   c.classif_tipo_id=tipo.classif_tipo_id
     and   rc.classif_id=c.classif_id
     and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
     and   rc.data_cancellazione is null
     and   c.data_cancellazione is null
     ),
     atto_cdc as
     (
     select rc.attoamm_id,
            c.classif_code programma_code_cdc_atto_amm,
            c.classif_desc programma_desc_cdc_atto_amm
     from siac_r_atto_amm_class rc, siac_t_class c , siac_d_class_tipo tipo
     where tipo.ente_proprietario_id=p_ente_proprietario_id
     and   tipo.classif_tipo_code='CDC'
     and   c.classif_tipo_id=tipo.classif_tipo_id
     and   rc.classif_id=c.classif_id
     and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
     and   rc.data_cancellazione is null
     and   c.data_cancellazione is null
     )
     select progr_atto.*,
            atto_cdr.programma_code_cdr_atto_amm,
            atto_cdr.programma_desc_cdr_atto_amm,
            atto_cdc.programma_code_cdc_atto_amm,
            atto_cdc.programma_desc_cdc_atto_amm
     from progr_atto
           left join atto_cdr on (progr_atto.attoamm_id=atto_cdr.attoamm_id)
           left join atto_cdc on (progr_atto.attoamm_id=atto_cdc.attoamm_id)
    ),
    -- 29.04.2019 Sofia siac-6255
    progr_affid as
    (
     select aff.programma_affidamento_code,
            aff.programma_affidamento_desc,
            aff.programma_affidamento_id
     from  siac_d_programma_affidamento aff
     where aff.ente_proprietario_id=p_ente_proprietario_id
    ),
    progr_bil_anno as
    (
    select bil.bil_id, per.anno anno_bilancio
    from siac_t_bil bil,siac_t_periodo per
    where bil.ente_proprietario_id=p_ente_proprietario_id
    and   per.periodo_id=bil.periodo_id
    ),
    cronop_progr as
    (
    with
     cronop_entrata as
     (
       with
         ce as
         (
           select cronop.programma_id,
                  per_bil.anno::varchar programma_cronop_bil_anno,
                  'E'::varchar programma_cronop_tipo,
                  cronop.cronop_code programma_cronop_versione,
                  cronop.cronop_desc programma_cronop_desc,
                  -- 29.04.2019 Sofia jira siac-6255
                  cronop.cronop_id,
                  cronop.cronop_data_approvazione_fattibilita,
                  cronop.cronop_data_approvazione_programma_def,
                  cronop.cronop_data_approvazione_programma_esec,
                  cronop.cronop_data_avvio_procedura,
                  cronop.cronop_data_aggiudicazione_lavori,
                  cronop.cronop_data_inizio_lavori,
                  cronop.cronop_data_fine_lavori,
                  cronop.cronop_giorni_durata,
                  cronop.cronop_data_collaudo,
                  cronop.gestione_quadro_economico,
                  cronop.usato_per_fpv_prov,
                  -- 29.04.2019 Sofia jira siac-6255
                  per.anno::varchar  programma_cronop_anno_comp,
                  tipo.elem_tipo_code programma_cronop_cap_tipo,
                  cronop_elem.cronop_elem_code||'/'||cronop_elem.cronop_elem_code2 programma_cronop_cap_articolo,
                  cronop_elem.cronop_elem_desc programma_cronop_cap_desc, -- 24.07.2019 Sofia SIAC-6979
                  ''::varchar programma_cronop_anno_entrata,
                  cronop_elem_det.cronop_elem_det_importo programma_cronop_valore_prev,
                  cronop_elem.cronop_elem_id
           from siac_t_cronop cronop,siac_r_cronop_stato rs, siac_d_cronop_stato stato,
                siac_t_bil bil, siac_t_periodo per_bil,
                siac_t_periodo per,
                siac_t_cronop_elem cronop_elem,
                siac_d_bil_elem_tipo tipo,
                siac_t_cronop_elem_det cronop_elem_det
           where stato.ente_proprietario_id=p_ente_proprietario_id
           and   stato.cronop_stato_code='VA'
           and   rs.cronop_stato_id=stato.cronop_stato_id
           and   cronop.cronop_id=rs.cronop_id
           and   bil.bil_id=cronop.bil_id
           and   per_bil.periodo_id=bil.periodo_id
--           and   per_bil.anno::integer=p_anno_bilancio::integer
--           and   per_bil.anno::integer<=p_anno_bilancio::integer           --- 20.06.2019 Sofia siac-6933
           and   cronop_elem.cronop_id=cronop.cronop_id
           and   tipo.elem_tipo_id=cronop_elem.elem_tipo_id
           and   tipo.elem_tipo_code in ('CAP-EP','CAP-EG')
           and   cronop_elem_det.cronop_elem_id=cronop_elem.cronop_elem_id
           and   per.periodo_id=cronop_elem_det.periodo_id
           and   p_data BETWEEN rs.validita_inizio AND COALESCE(rs.validita_fine, p_data)
           and   rs.data_cancellazione is null
           and   p_data BETWEEN cronop.validita_inizio AND COALESCE(cronop.validita_fine, p_data)
           and   cronop.data_cancellazione is null
           and   p_data BETWEEN cronop_elem.validita_inizio AND COALESCE(cronop_elem.validita_fine, p_data)
           and   cronop_elem.data_cancellazione is null
           and   p_data BETWEEN cronop_elem_det.validita_inizio AND COALESCE(cronop_elem_det.validita_fine, p_data)
           and   cronop_elem_det.data_cancellazione is null
         ),
         classif_bil as
         (
            select distinct
                   r_cronp_class.cronop_elem_id,
		           titolo.classif_code            				titolo_code ,
	               titolo.classif_desc            				titolo_desc,
	               tipologia.classif_code           			tipologia_code,
	               tipologia.classif_desc           			tipologia_desc
            from siac_t_class_fam_tree 			titolo_tree,
            	 siac_d_class_fam 				titolo_fam,
	             siac_r_class_fam_tree 			titolo_r_cft,
	             siac_t_class 					titolo,
	             siac_d_class_tipo 				titolo_tipo,
	             siac_d_class_tipo 				tipologia_tipo,
     	         siac_t_class 					tipologia,
	             siac_r_cronop_elem_class		r_cronp_class
            where 	titolo_fam.classif_fam_desc					=	'Entrata - TitoliTipologieCategorie'
            and 	titolo_tree.classif_fam_id					=	titolo_fam.classif_fam_id
            and 	titolo_r_cft.classif_fam_tree_id			=	titolo_tree.classif_fam_tree_id
            and 	titolo.classif_id							=	titolo_r_cft.classif_id_padre
            and 	titolo_tipo.classif_tipo_code				=	'TITOLO_ENTRATA'
            and 	titolo.classif_tipo_id						=	titolo_tipo.classif_tipo_id
            and 	tipologia_tipo.classif_tipo_code			=	'TIPOLOGIA'
            and 	tipologia.classif_tipo_id					=	tipologia_tipo.classif_tipo_id
            and 	titolo_r_cft.classif_id						=	tipologia.classif_id
            and 	r_cronp_class.classif_id					=	tipologia.classif_id
            and 	titolo.ente_proprietario_id					=	p_ente_proprietario_id
            and 	titolo.data_cancellazione					is null
            and 	tipologia.data_cancellazione				is null
            and		r_cronp_class.data_cancellazione			is null
            and 	titolo_tree.data_cancellazione				is null
            and 	titolo_fam.data_cancellazione				is null
            and 	titolo_r_cft.data_cancellazione				is null
            and 	titolo_tipo.data_cancellazione				is null
            and 	tipologia_tipo.data_cancellazione			is null
          ),
          -- 29.04.2019 Sofia jira siac-6255
          cronop_atto_amm as
          (
           with
           cronop_atto as
           (
            select ratto.cronop_id,
                   ratto.attoamm_id,
                   atto.attoamm_anno        cronop_anno_atto_amm,
                   atto.attoamm_numero      cronop_num_atto_amm,
                   atto.attoamm_oggetto     cronop_oggetto_atto_amm,
                   atto.attoamm_note        cronop_note_atto_amm,
                   tipo.attoamm_tipo_code   cronop_code_tipo_atto_amm,
                   tipo.attoamm_tipo_desc   cronop_desc_tipo_atto_amm,
                   stato.attoamm_stato_code cronop_code_stato_atto_amm,
                   stato.attoamm_stato_desc cronop_desc_stato_atto_amm
            from siac_r_cronop_atto_amm ratto , siac_t_atto_amm atto,siac_d_atto_amm_tipo tipo,
                 siac_r_atto_amm_stato rs, siac_d_atto_amm_stato stato
            where ratto.ente_proprietario_id=p_ente_proprietario_id
            and   atto.attoamm_id=ratto.attoamm_id
            and   tipo.attoamm_tipo_id=atto.attoamm_tipo_id
            and   rs.attoamm_id=atto.attoamm_id
            and   stato.attoamm_stato_id=rs.attoamm_stato_id
            and   p_data BETWEEN ratto.validita_inizio AND COALESCE(ratto.validita_fine, p_data)
            and   ratto.data_cancellazione is null
            and   p_data BETWEEN atto.validita_inizio AND COALESCE(atto.validita_fine, p_data)
            and   atto.data_cancellazione is null
            and   p_data BETWEEN rs.validita_inizio AND COALESCE(rs.validita_fine, p_data)
            and   rs.data_cancellazione is null
           ),
           cronop_atto_cdr as
           (
           select rc.attoamm_id,
                  c.classif_code cronop_code_cdr_atto_amm,
                  c.classif_desc cronop_desc_cdr_atto_amm
           from siac_r_atto_amm_class rc, siac_t_class c , siac_d_class_tipo tipo
           where tipo.ente_proprietario_id=p_ente_proprietario_id
           and   tipo.classif_tipo_code='CDR'
           and   c.classif_tipo_id=tipo.classif_tipo_id
           and   rc.classif_id=c.classif_id
           and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
           and   rc.data_cancellazione is null
           and   c.data_cancellazione is null
           ),
           cronop_atto_cdc as
           (
           select rc.attoamm_id,
                  c.classif_code cronop_code_cdc_atto_amm,
                  c.classif_desc cronop_desc_cdc_atto_amm
           from siac_r_atto_amm_class rc, siac_t_class c , siac_d_class_tipo tipo
           where tipo.ente_proprietario_id=p_ente_proprietario_id
           and   tipo.classif_tipo_code='CDC'
           and   c.classif_tipo_id=tipo.classif_tipo_id
           and   rc.classif_id=c.classif_id
           and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
           and   rc.data_cancellazione is null
           and   c.data_cancellazione is null
           )
           select cronop_atto.*,
                  cronop_atto_cdr.cronop_code_cdr_atto_amm,
                  cronop_atto_cdr.cronop_desc_cdr_atto_amm,
                  cronop_atto_cdc.cronop_code_cdc_atto_amm,
                  cronop_atto_cdc.cronop_desc_cdc_atto_amm
           from cronop_atto
                 left join cronop_atto_cdr on (cronop_atto.attoamm_id=cronop_atto_cdr.attoamm_id)
                 left join cronop_atto_cdc on (cronop_atto.attoamm_id=cronop_atto_cdc.attoamm_id)
          )
          select ce.programma_id,
                 ce.programma_cronop_bil_anno,
                 ce.programma_cronop_tipo,
                 ce.programma_cronop_versione,
                 ce.programma_cronop_desc,
                 ce.programma_cronop_anno_comp,
                 ce.programma_cronop_cap_tipo,
                 ce.programma_cronop_cap_articolo,
                 ce.programma_cronop_cap_desc, -- 24.07.2019 Sofia SIAC-6979
                 (coalesce(classif_bil.titolo_code,' ') ||' - ' ||coalesce(classif_bil.tipologia_code,' '))::varchar programma_cronop_classif_bil,
                 ce.programma_cronop_anno_entrata,
                 ce.programma_cronop_valore_prev,
                 -- 29.04.2019 Sofia jira siac-6255
                 ce.cronop_id,
                 ce.cronop_data_approvazione_fattibilita,
                 ce.cronop_data_approvazione_programma_def,
                 ce.cronop_data_approvazione_programma_esec,
                 ce.cronop_data_avvio_procedura,
                 ce.cronop_data_aggiudicazione_lavori,
                 ce.cronop_data_inizio_lavori,
                 ce.cronop_data_fine_lavori,
                 ce.cronop_giorni_durata,
                 ce.cronop_data_collaudo,
                 ce.gestione_quadro_economico cronop_gestione_quadro_economico,
                 ce.usato_per_fpv_prov cronop_usato_per_fpv_prov,
                 cronop_atto_amm.cronop_anno_atto_amm,
		         cronop_atto_amm.cronop_num_atto_amm,
                 cronop_atto_amm.cronop_oggetto_atto_amm,
                 cronop_atto_amm.cronop_note_atto_amm,
                 cronop_atto_amm.cronop_code_tipo_atto_amm,
                 cronop_atto_amm.cronop_desc_tipo_atto_amm,
                 cronop_atto_amm.cronop_code_stato_atto_amm,
                 cronop_atto_amm.cronop_desc_stato_atto_amm,
                 cronop_atto_amm.cronop_code_cdr_atto_amm,
                 cronop_atto_amm.cronop_desc_cdr_atto_amm,
                 cronop_atto_amm.cronop_code_cdc_atto_amm,
                 cronop_atto_amm.cronop_desc_cdc_atto_amm
          from ce
               left join classif_bil on (ce.cronop_elem_id=classif_bil.cronop_elem_id)
               -- 29.04.2019 Sofia jira siac-6255
               left join cronop_atto_amm on (ce.cronop_id=cronop_atto_amm.cronop_id)

     ),
     cronop_uscita as
     (
     with
     ce as
     (
       select cronop.programma_id,
              per_bil.anno::varchar programma_cronop_bil_anno,
              'U'::varchar programma_cronop_tipo,
              cronop.cronop_code programma_cronop_versione,
              cronop.cronop_desc programma_cronop_desc,
              -- 29.04.2019 Sofia jira siac-6255
              cronop.cronop_id,
              cronop.cronop_data_approvazione_fattibilita,
              cronop.cronop_data_approvazione_programma_def,
              cronop.cronop_data_approvazione_programma_esec,
              cronop.cronop_data_avvio_procedura,
              cronop.cronop_data_aggiudicazione_lavori,
              cronop.cronop_data_inizio_lavori,
              cronop.cronop_data_fine_lavori,
              cronop.cronop_giorni_durata,
              cronop.cronop_data_collaudo,
              cronop.gestione_quadro_economico,
              cronop.usato_per_fpv_prov,
              -- 29.04.2019 Sofia jira siac-6255
              per.anno::varchar  programma_cronop_anno_comp,
              tipo.elem_tipo_code programma_cronop_cap_tipo,
              cronop_elem.cronop_elem_code||'/'||cronop_elem.cronop_elem_code2 programma_cronop_cap_articolo,
              cronop_elem.cronop_elem_desc programma_cronop_cap_desc, -- 24.07.2019 Sofia SIAC-6979
              cronop_elem_det.anno_entrata::varchar programma_cronop_anno_entrata,
              cronop_elem_det.cronop_elem_det_importo programma_cronop_valore_prev,
              cronop_elem.cronop_elem_id
       from siac_t_cronop cronop,siac_r_cronop_stato rs, siac_d_cronop_stato stato,
            siac_t_bil bil, siac_t_periodo per_bil,
            siac_t_periodo per,
            siac_t_cronop_elem cronop_elem,
            siac_d_bil_elem_tipo tipo,
            siac_t_cronop_elem_det cronop_elem_det
       where stato.ente_proprietario_id=p_ente_proprietario_id
       and   stato.cronop_stato_code='VA'
       and   rs.cronop_stato_id=stato.cronop_stato_id
       and   cronop.cronop_id=rs.cronop_id
       and   bil.bil_id=cronop.bil_id
       and   per_bil.periodo_id=bil.periodo_id
 --      and   per_bil.anno::integer=p_anno_bilancio::integer
 --      and   per_bil.anno::integer<=p_anno_bilancio::integer           --- 20.06.2019 Sofia siac-6933

       and   cronop_elem.cronop_id=cronop.cronop_id
       and   tipo.elem_tipo_id=cronop_elem.elem_tipo_id
       and   tipo.elem_tipo_code in ('CAP-UP','CAP-UG')
       and   cronop_elem_det.cronop_elem_id=cronop_elem.cronop_elem_id
       and   per.periodo_id=cronop_elem_det.periodo_id
       and   p_data BETWEEN rs.validita_inizio AND COALESCE(rs.validita_fine, p_data)
       and   rs.data_cancellazione is null
       and   p_data BETWEEN cronop.validita_inizio AND COALESCE(cronop.validita_fine, p_data)
       and   cronop.data_cancellazione is null
       and   p_data BETWEEN cronop_elem.validita_inizio AND COALESCE(cronop_elem.validita_fine, p_data)
       and   cronop_elem.data_cancellazione is null
       and   p_data BETWEEN cronop_elem_det.validita_inizio AND COALESCE(cronop_elem_det.validita_fine, p_data)
       and   cronop_elem_det.data_cancellazione is null
     ),
     classif_bil as
     (
        select  distinct
        		r_cronp_class_titolo.cronop_elem_id,
		        missione.classif_code 					missione_code,
		        missione.classif_desc 					missione_desc,
		        programma.classif_code 					programma_code,
		        programma.classif_desc 					programma_desc,
		        titusc.classif_code 					titolo_code,
		        titusc.classif_desc 					titolo_desc
        from siac_t_class_fam_tree 			missione_tree,
             siac_d_class_fam 				missione_fam,
	         siac_r_class_fam_tree 			missione_r_cft,
	         siac_t_class 					missione,
	         siac_d_class_tipo 				missione_tipo ,
     	     siac_d_class_tipo 				programma_tipo,
	         siac_t_class 					programma,
      	     siac_t_class_fam_tree 			titusc_tree,
	         siac_d_class_fam 				titusc_fam,
	         siac_r_class_fam_tree 			titusc_r_cft,
	         siac_t_class 					titusc,
	         siac_d_class_tipo 				titusc_tipo,
	         siac_r_cronop_elem_class		r_cronp_class_programma,
	         siac_r_cronop_elem_class		r_cronp_class_titolo
        where missione_fam.classif_fam_desc						=	'Spesa - MissioniProgrammi'
        and	  missione_tree.classif_fam_id				=	missione_fam.classif_fam_id
        and	  missione_r_cft.classif_fam_tree_id			=	missione_tree.classif_fam_tree_id
        and	  missione.classif_id							=	missione_r_cft.classif_id_padre
        and	  missione_tipo.classif_tipo_code				=	'MISSIONE'
        and	  missione.classif_tipo_id					=	missione_tipo.classif_tipo_id
        and	  programma_tipo.classif_tipo_code			=	'PROGRAMMA'
        and	  programma.classif_tipo_id					=	programma_tipo.classif_tipo_id
        and	  missione_r_cft.classif_id					=	programma.classif_id
        and	  programma.classif_id						=	r_cronp_class_programma.classif_id
        and	  titusc_fam.classif_fam_desc					=	'Spesa - TitoliMacroaggregati'
        and	  titusc_tree.classif_fam_id					=	titusc_fam.classif_fam_id
        and	  titusc_r_cft.classif_fam_tree_id			=	titusc_tree.classif_fam_tree_id
        and	  titusc.classif_id							=	titusc_r_cft.classif_id_padre
        and	  titusc_tipo.classif_tipo_code				=	'TITOLO_SPESA'
        and	  titusc.classif_tipo_id						=	titusc_tipo.classif_tipo_id
        and	  titusc.classif_id							=	r_cronp_class_titolo.classif_id
        and   r_cronp_class_programma.cronop_elem_id		= 	r_cronp_class_titolo.cronop_elem_id
        and   missione_tree.ente_proprietario_id			=	p_ente_proprietario_id
        and   missione_tree.data_cancellazione			is null
        and   missione_fam.data_cancellazione			is null
        AND   missione_r_cft.data_cancellazione			is null
        and   missione.data_cancellazione				is null
        AND   missione_tipo.data_cancellazione			is null
        AND   programma_tipo.data_cancellazione			is null
        AND   programma.data_cancellazione				is null
        and   titusc_tree.data_cancellazione			is null
        AND   titusc_fam.data_cancellazione				is null
        and   titusc_r_cft.data_cancellazione			is null
        and   titusc.data_cancellazione					is null
        AND   titusc_tipo.data_cancellazione			is null
        and	  r_cronp_class_titolo.data_cancellazione	is null
     ),
     -- 29.04.2019 Sofia jira siac-6255
     cronop_atto_amm as
     (
       with
       cronop_atto as
       (
        select ratto.cronop_id,
               ratto.attoamm_id,
               atto.attoamm_anno        cronop_anno_atto_amm,
               atto.attoamm_numero      cronop_num_atto_amm,
               atto.attoamm_oggetto     cronop_oggetto_atto_amm,
               atto.attoamm_note        cronop_note_atto_amm,
               tipo.attoamm_tipo_code   cronop_code_tipo_atto_amm,
               tipo.attoamm_tipo_desc   cronop_desc_tipo_atto_amm,
               stato.attoamm_stato_code cronop_code_stato_atto_amm,
               stato.attoamm_stato_desc cronop_desc_stato_atto_amm
        from siac_r_cronop_atto_amm ratto , siac_t_atto_amm atto,siac_d_atto_amm_tipo tipo,
             siac_r_atto_amm_stato rs, siac_d_atto_amm_stato stato
        where ratto.ente_proprietario_id=p_ente_proprietario_id
        and   atto.attoamm_id=ratto.attoamm_id
        and   tipo.attoamm_tipo_id=atto.attoamm_tipo_id
        and   rs.attoamm_id=atto.attoamm_id
        and   stato.attoamm_stato_id=rs.attoamm_stato_id
        and   p_data BETWEEN ratto.validita_inizio AND COALESCE(ratto.validita_fine, p_data)
        and   ratto.data_cancellazione is null
        and   p_data BETWEEN atto.validita_inizio AND COALESCE(atto.validita_fine, p_data)
        and   atto.data_cancellazione is null
        and   p_data BETWEEN rs.validita_inizio AND COALESCE(rs.validita_fine, p_data)
        and   rs.data_cancellazione is null
       ),
       cronop_atto_cdr as
       (
       select rc.attoamm_id,
              c.classif_code cronop_code_cdr_atto_amm,
              c.classif_desc cronop_desc_cdr_atto_amm
       from siac_r_atto_amm_class rc, siac_t_class c , siac_d_class_tipo tipo
       where tipo.ente_proprietario_id=p_ente_proprietario_id
       and   tipo.classif_tipo_code='CDR'
       and   c.classif_tipo_id=tipo.classif_tipo_id
       and   rc.classif_id=c.classif_id
       and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
       and   rc.data_cancellazione is null
       and   c.data_cancellazione is null
       ),
       cronop_atto_cdc as
       (
       select rc.attoamm_id,
              c.classif_code cronop_code_cdc_atto_amm,
              c.classif_desc cronop_desc_cdc_atto_amm
       from siac_r_atto_amm_class rc, siac_t_class c , siac_d_class_tipo tipo
       where tipo.ente_proprietario_id=p_ente_proprietario_id
       and   tipo.classif_tipo_code='CDC'
       and   c.classif_tipo_id=tipo.classif_tipo_id
       and   rc.classif_id=c.classif_id
       and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
       and   rc.data_cancellazione is null
       and   c.data_cancellazione is null
       )
       select cronop_atto.*,
              cronop_atto_cdr.cronop_code_cdr_atto_amm,
              cronop_atto_cdr.cronop_desc_cdr_atto_amm,
              cronop_atto_cdc.cronop_code_cdc_atto_amm,
              cronop_atto_cdc.cronop_desc_cdc_atto_amm
       from cronop_atto
             left join cronop_atto_cdr on (cronop_atto.attoamm_id=cronop_atto_cdr.attoamm_id)
             left join cronop_atto_cdc on (cronop_atto.attoamm_id=cronop_atto_cdc.attoamm_id)
     )
     select ce.programma_id,
            ce.programma_cronop_bil_anno,
            ce.programma_cronop_tipo,
            ce.programma_cronop_versione,
            ce.programma_cronop_desc,
            ce.programma_cronop_anno_comp,
            ce.programma_cronop_cap_tipo,
            ce.programma_cronop_cap_articolo,
            ce.programma_cronop_cap_desc, -- 24.07.2019 Sofia SIAC-6979
            (coalesce(classif_bil.missione_code,' ')||
             ' - '||coalesce(classif_bil.programma_code,' ')||
             ' - '||coalesce(classif_bil.titolo_code,' '))::varchar programma_cronop_classif_bil,
            ce.programma_cronop_anno_entrata,
            ce.programma_cronop_valore_prev,
            -- 29.04.2019 Sofia jira siac-6255
            ce.cronop_id,
            ce.cronop_data_approvazione_fattibilita,
            ce.cronop_data_approvazione_programma_def,
            ce.cronop_data_approvazione_programma_esec,
            ce.cronop_data_avvio_procedura,
            ce.cronop_data_aggiudicazione_lavori,
            ce.cronop_data_inizio_lavori,
            ce.cronop_data_fine_lavori,
            ce.cronop_giorni_durata,
            ce.cronop_data_collaudo,
            ce.gestione_quadro_economico cronop_gestione_quadro_economico,
            ce.usato_per_fpv_prov cronop_usato_per_fpv_prov,
            cronop_atto_amm.cronop_anno_atto_amm,
            cronop_atto_amm.cronop_num_atto_amm,
            cronop_atto_amm.cronop_oggetto_atto_amm,
            cronop_atto_amm.cronop_note_atto_amm,
            cronop_atto_amm.cronop_code_tipo_atto_amm,
            cronop_atto_amm.cronop_desc_tipo_atto_amm,
            cronop_atto_amm.cronop_code_stato_atto_amm,
            cronop_atto_amm.cronop_desc_stato_atto_amm,
            cronop_atto_amm.cronop_code_cdr_atto_amm,
            cronop_atto_amm.cronop_desc_cdr_atto_amm,
            cronop_atto_amm.cronop_code_cdc_atto_amm,
            cronop_atto_amm.cronop_desc_cdc_atto_amm
     from ce
          left join classif_bil on (ce.cronop_elem_id=classif_bil.cronop_elem_id)
          -- 29.04.2019 Sofia jira siac-6255
          left join cronop_atto_amm on ( ce.cronop_id=cronop_atto_amm.cronop_id)
     )
     select cronop_entrata.programma_id,
     	    cronop_entrata.programma_cronop_bil_anno,
            cronop_entrata.programma_cronop_tipo,
            cronop_entrata.programma_cronop_versione,
            cronop_entrata.programma_cronop_desc,
	        cronop_entrata.programma_cronop_anno_comp,
            cronop_entrata.programma_cronop_cap_tipo,
	        cronop_entrata.programma_cronop_cap_articolo,
            cronop_entrata.programma_cronop_cap_desc, -- 24.07.2019 Sofia SIAC-6979
	        cronop_entrata.programma_cronop_classif_bil,
	        cronop_entrata.programma_cronop_anno_entrata,
            cronop_entrata.programma_cronop_valore_prev,
            -- 29.04.2019 Sofia jira siac-6255
            cronop_entrata.cronop_id,
            cronop_entrata.cronop_data_approvazione_fattibilita,
            cronop_entrata.cronop_data_approvazione_programma_def,
            cronop_entrata.cronop_data_approvazione_programma_esec,
            cronop_entrata.cronop_data_avvio_procedura,
            cronop_entrata.cronop_data_aggiudicazione_lavori,
            cronop_entrata.cronop_data_inizio_lavori,
            cronop_entrata.cronop_data_fine_lavori,
            cronop_entrata.cronop_giorni_durata,
            cronop_entrata.cronop_data_collaudo,
            cronop_entrata.cronop_gestione_quadro_economico,
            cronop_entrata.cronop_usato_per_fpv_prov,
            cronop_entrata.cronop_anno_atto_amm,
            cronop_entrata.cronop_num_atto_amm,
            cronop_entrata.cronop_oggetto_atto_amm,
            cronop_entrata.cronop_note_atto_amm,
            cronop_entrata.cronop_code_tipo_atto_amm,
            cronop_entrata.cronop_desc_tipo_atto_amm,
            cronop_entrata.cronop_code_stato_atto_amm,
            cronop_entrata.cronop_desc_stato_atto_amm,
            cronop_entrata.cronop_code_cdr_atto_amm,
            cronop_entrata.cronop_desc_cdr_atto_amm,
            cronop_entrata.cronop_code_cdc_atto_amm,
            cronop_entrata.cronop_desc_cdc_atto_amm
     from cronop_entrata
     union
     select cronop_uscita.programma_id,
     	    cronop_uscita.programma_cronop_bil_anno,
            cronop_uscita.programma_cronop_tipo,
            cronop_uscita.programma_cronop_versione,
            cronop_uscita.programma_cronop_desc,
	        cronop_uscita.programma_cronop_anno_comp,
            cronop_uscita.programma_cronop_cap_tipo,
	        cronop_uscita.programma_cronop_cap_articolo,
            cronop_uscita.programma_cronop_cap_desc, -- 24.07.2019 Sofia SIAC-6979
	        cronop_uscita.programma_cronop_classif_bil,
	        cronop_uscita.programma_cronop_anno_entrata,
            cronop_uscita.programma_cronop_valore_prev,
            -- 29.04.2019 Sofia jira siac-6255
            cronop_uscita.cronop_id,
            cronop_uscita.cronop_data_approvazione_fattibilita,
            cronop_uscita.cronop_data_approvazione_programma_def,
            cronop_uscita.cronop_data_approvazione_programma_esec,
            cronop_uscita.cronop_data_avvio_procedura,
            cronop_uscita.cronop_data_aggiudicazione_lavori,
            cronop_uscita.cronop_data_inizio_lavori,
            cronop_uscita.cronop_data_fine_lavori,
            cronop_uscita.cronop_giorni_durata,
            cronop_uscita.cronop_data_collaudo,
            cronop_uscita.cronop_gestione_quadro_economico,
            cronop_uscita.cronop_usato_per_fpv_prov,
            cronop_uscita.cronop_anno_atto_amm,
            cronop_uscita.cronop_num_atto_amm,
            cronop_uscita.cronop_oggetto_atto_amm,
            cronop_uscita.cronop_note_atto_amm,
            cronop_uscita.cronop_code_tipo_atto_amm,
            cronop_uscita.cronop_desc_tipo_atto_amm,
            cronop_uscita.cronop_code_stato_atto_amm,
            cronop_uscita.cronop_desc_stato_atto_amm,
            cronop_uscita.cronop_code_cdr_atto_amm,
            cronop_uscita.cronop_desc_cdr_atto_amm,
            cronop_uscita.cronop_code_cdc_atto_amm,
            cronop_uscita.cronop_desc_cdc_atto_amm
     from cronop_uscita
    )
    select programma.*,
           progr_ambito_class.programma_ambito_code,
           progr_ambito_class.programma_ambito_desc,
           progr_note_attr_ril_fpv.programma_rilevante_fpv,
           progr_note_attr_note.programma_note,
           progr_note_attr_val_compl.programma_valore_complessivo,
           progr_atto_amm.programma_anno_atto_amm,
           progr_atto_amm.programma_num_atto_amm,
           progr_atto_amm.programma_oggetto_atto_amm,
           progr_atto_amm.programma_note_atto_amm,
           progr_atto_amm.programma_code_tipo_atto_amm,
           progr_atto_amm.programma_desc_tipo_atto_amm,
           progr_atto_amm.programma_code_stato_atto_amm,
           progr_atto_amm.programma_desc_stato_atto_amm,
           progr_atto_amm.programma_code_cdr_atto_amm,
           progr_atto_amm.programma_desc_cdr_atto_amm,
           progr_atto_amm.programma_code_cdc_atto_amm,
           progr_atto_amm.programma_desc_cdc_atto_amm,
           -- 29.04.2019 Sofia siac-6255
           progr_affid.programma_affidamento_code,
           progr_affid.programma_affidamento_desc,
           progr_bil_anno.anno_bilancio programma_anno_bilancio,
           -- 20.06.2019 Sofia siac-6933
           progr_sac.programma_sac_tipo,
           progr_sac.programma_sac_code,
           progr_sac.programma_sac_desc,
           progr_cup.programma_cup,
           -- 29.04.2019 Sofia siac-6255
	       cronop_progr.programma_cronop_bil_anno,
           cronop_progr.programma_cronop_tipo,
           cronop_progr.programma_cronop_versione,
      	   cronop_progr.programma_cronop_desc,
	       cronop_progr.programma_cronop_anno_comp,
	       cronop_progr.programma_cronop_cap_tipo,
	       cronop_progr.programma_cronop_cap_articolo,
	       cronop_progr.programma_cronop_cap_desc, -- 24.07.2019 Sofia SIAC-6979
	       cronop_progr.programma_cronop_classif_bil,
		   cronop_progr.programma_cronop_anno_entrata,
	       cronop_progr.programma_cronop_valore_prev,
           -- 29.04.2019 Sofia siac-6255
           cronop_progr.cronop_data_approvazione_fattibilita,
           cronop_progr.cronop_data_approvazione_programma_def,
           cronop_progr.cronop_data_approvazione_programma_esec,
           cronop_progr.cronop_data_avvio_procedura,
           cronop_progr.cronop_data_aggiudicazione_lavori,
           cronop_progr.cronop_data_inizio_lavori,
           cronop_progr.cronop_data_fine_lavori,
           cronop_progr.cronop_giorni_durata,
           cronop_progr.cronop_data_collaudo,
           cronop_progr.cronop_gestione_quadro_economico,
           cronop_progr.cronop_usato_per_fpv_prov,
           cronop_progr.cronop_anno_atto_amm,
           cronop_progr.cronop_num_atto_amm,
           cronop_progr.cronop_oggetto_atto_amm,
           cronop_progr.cronop_note_atto_amm,
           cronop_progr.cronop_code_tipo_atto_amm,
           cronop_progr.cronop_desc_tipo_atto_amm,
           cronop_progr.cronop_code_stato_atto_amm,
           cronop_progr.cronop_desc_stato_atto_amm,
           cronop_progr.cronop_code_cdr_atto_amm,
           cronop_progr.cronop_desc_cdr_atto_amm,
           cronop_progr.cronop_code_cdc_atto_amm,
           cronop_progr.cronop_desc_cdc_atto_amm
    from cronop_progr,
         programma
          left join progr_ambito_class           on (programma.programma_id=progr_ambito_class.programma_id)
          left join progr_note_attr_ril_fpv      on (programma.programma_id=progr_note_attr_ril_fpv.programma_id)
          left join progr_note_attr_note         on (programma.programma_id=progr_note_attr_note.programma_id)
          left join progr_note_attr_val_compl    on (programma.programma_id=progr_note_attr_val_compl.programma_id)
          left join progr_atto_amm               on (programma.programma_id=progr_atto_amm.programma_id)
          -- 20.06.2019 Sofia siac-6933
          left join progr_sac					 on (programma.programma_id=progr_sac.programma_id)
          left join progr_cup					 on (programma.programma_id=progr_cup.programma_id)
          -- 29.04.2019 Sofia jira siac-6255
          left join  progr_affid                 on (programma.programma_affidamento_id=progr_affid.programma_affidamento_id)
          left  join  progr_bil_anno              on (programma.bil_id=progr_bil_anno.bil_id)
    where programma.programma_id=cronop_progr.programma_id
    ) query,siac_t_ente_proprietario ente
    where ente.ente_proprietario_id=p_ente_proprietario_id
    and   query.ente_proprietario_id=ente.ente_proprietario_id;


	esito:= 'fnc_siac_dwh_programma_cronop : continue - aggiornamento durata su  siac_dwh_log_elaborazioni - '||clock_timestamp()||'.';
	update siac_dwh_log_elaborazioni
    set    fnc_elaborazione_fine = clock_timestamp(),
	       fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
	where  fnc_user=v_user_table;
	return next;

    esito:= 'fnc_siac_dwh_programma_cronop : fine - esito OK  - '||clock_timestamp()||'.';
    return next;
else
	esito:= 'fnc_siac_dwh_programma_cronop : fine - eseguita da meno di '|| interval_esec::varchar||' ore - '||clock_timestamp()||'.';

	return next;

end if;

return;

EXCEPTION
 WHEN RAISE_EXCEPTION THEN
  esito:='fnc_siac_dwh_programma_cronop : fine con errori - '||clock_timestamp();
  esito:=esito||' - '||SQLSTATE||'-'||substring(upper(SQLERRM) from 1 for 2500)||'.';
  RAISE NOTICE '%',esito;
  RETURN next;
  return;
 WHEN others THEN
  esito:='fnc_siac_dwh_programma_cronop : fine con errori - '||clock_timestamp();
  esito:=esito||' - '||SQLSTATE||'-'||substring(upper(SQLERRM) from 1 for 2500)||'.';
  RAISE NOTICE '%',esito;
  RETURN next;
  return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;


--- 24.07.2019 Sofia siac-6979 - fine