/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR263_stampa_variazione_definitiva_pluriennale_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_stampa_stanz varchar
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
  stanziamento_anno1 numeric,
  cassa numeric,
  residuo numeric,
  variazione_aumento_stanziato_anno1 numeric,
  variazione_diminuzione_stanziato_anno1 numeric,
  variazione_aumento_cassa numeric,
  variazione_diminuzione_cassa numeric,
  variazione_aumento_residuo numeric,
  variazione_diminuzione_residuo numeric,
  stanziamento_anno2 numeric,
  variazione_aumento_stanziato_anno2 numeric,
  variazione_diminuzione_stanziato_anno2 numeric,
  stanziamento_anno3 numeric,
  variazione_aumento_stanziato_anno3 numeric,
  variazione_diminuzione_stanziato_anno3 numeric,
  flag_visualizzazione numeric,
  display_error varchar
) AS
$body$
DECLARE

classifBilRec record;


annoCapImp1 varchar;
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
v_fam_titolotipologiacategoria varchar:='00003';
strApp varchar;
intApp numeric;
sql_query varchar;
bilancio_id integer;

BEGIN

annoCapImp1:= p_anno; 
annoCapImp2:=(p_anno::integer+1)::varchar;
annoCapImp3:=(p_anno::integer+2)::varchar;

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
stanziamento_anno1=0;
cassa=0;
residuo=0;
variazione_aumento_stanziato_anno1=0;
variazione_diminuzione_stanziato_anno1=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
stanziamento_anno2 =0;
variazione_aumento_stanziato_anno2 =0;
variazione_diminuzione_stanziato_anno2 =0;
stanziamento_anno3  =0;
variazione_aumento_stanziato_anno3 =0;
variazione_diminuzione_stanziato_anno3 =0;
flag_visualizzazione = -111;
display_error='';


select fnc_siac_random_user()
into	user_table;


select bilancio.bil_id
	into bilancio_id
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc
where bilancio.periodo_id=anno_eserc.periodo_id
	and bilancio.ente_proprietario_id=p_ente_prop_id
    and anno_eserc.anno=p_anno
    and bilancio.data_cancellazione IS NULL    
    and anno_eserc.data_cancellazione IS NULL;
    
raise notice 'bilancio_id = %', bilancio_id;

 RTN_MESSAGGIO:='insert tabella siac_rep_tit_tip_cat_riga_anni''.';  

/* carico la struttura di bilancio completa */

insert into  siac_rep_tit_tip_cat_riga_anni
select strutt.*
from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno, user_table) strutt;


 RTN_MESSAGGIO:='insert tabella siac_rep_cap_eg''.';  
 
--carico tutti i capitoli dell'anno bilancio di Entrata Gestione.
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
and e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and	stato_capitolo.elem_stato_code	in ('VA', 'PR')
and ct.classif_tipo_code			=	'CATEGORIA'
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

--carico i capitoli senza struttura.
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
where e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
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

sql_query:='';

if upper(p_stampa_stanz) = 'S' then
    --Se e' richiesto di visualizzare lo stanziamento iniziale dei capitoli devo tener conto delle variazioni avvenute
    --successivamente.
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
                  siac_d_bil_elem_stato 		stato_capitolo,
                  siac_r_bil_elem_stato 		r_capitolo_stato,
                  siac_d_bil_elem_categoria 	cat_del_capitolo,
                  siac_r_bil_elem_categoria 	r_cat_capitolo,
                  siac_t_bil_elem 			capitolo
          where 	capitolo.elem_id					=	capitolo_importi.elem_id
              and	capitolo.elem_id					=	capitolo_importi.elem_id
              and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id
              and	capitolo.elem_id					=	capitolo_importi.elem_id
              and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id
              and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
              and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id
              and	capitolo.elem_id					=	r_capitolo_stato.elem_id
              and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
              and	capitolo.elem_id					=	r_cat_capitolo.elem_id
              and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id            
              and capitolo_importi.ente_proprietario_id 	='||p_ente_prop_id ||'
              and	capitolo.bil_id						= '||bilancio_id ||'                        
              and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''            
              and stato_capitolo.elem_stato_code	in (''VA'', ''PR'')    
              and cat_del_capitolo.elem_cat_code		in (''STD'')        
              and capitolo_imp_tipo.elem_det_tipo_code in (''STA'', ''SCA'',''STR'')
              and	capitolo_importi.data_cancellazione 		is null
              and	capitolo_imp_tipo.data_cancellazione 		is null
              and	capitolo_imp_periodo.data_cancellazione 	is null
              and	capitolo.data_cancellazione 				is null
              and	tipo_elemento.data_cancellazione 			is null
              and	stato_capitolo.data_cancellazione 			is null
              and	r_capitolo_stato.data_cancellazione 		is null
              and cat_del_capitolo.data_cancellazione 		is null
              and	r_cat_capitolo.data_cancellazione 			is null
          group by	capitolo_importi.elem_id,
          capitolo_imp_tipo.elem_det_tipo_code,
          capitolo_imp_periodo.anno,
          capitolo_importi.ente_proprietario_id,
          capitolo_imp_tipo.elem_det_tipo_id),
      importi_variaz as (with varcurr as (              
        select dvar.elem_id elem_id_var, bvar.validita_inizio, dvar.periodo_id,
            dvar.elem_det_tipo_id, periodo_importo_variazione.anno anno_comp
        from 
        siac_t_variazione avar, siac_r_variazione_stato bvar,
        siac_d_variazione_stato cvar, siac_t_bil_elem_det_var dvar, siac_t_periodo periodo_importo_variazione
        where avar.variazione_id=bvar.variazione_id
        and bvar.variazione_stato_tipo_id=cvar.variazione_stato_tipo_id
        and dvar.variazione_stato_id=bvar.variazione_stato_id         
        and cvar.variazione_stato_tipo_code=''D''
        and avar.bil_id = '||bilancio_id ||'                             
        and bvar.data_cancellazione is null
        and bvar.variazione_stato_id in (     
                  select max(var_stato.variazione_stato_id)
                  from siac_t_variazione t_var,
                    siac_r_variazione_stato     var_stato
                  where
                    t_var.variazione_id = var_stato.variazione_id
                    and t_var.ente_proprietario_id = '|| p_ente_prop_id||'
                    and t_var.variazione_num in('||p_ele_variazioni||')
                    and t_var.bil_id = '||bilancio_id ||'
                    and t_var.data_cancellazione IS NULL
                    and var_stato.data_cancellazione IS NULL )
                    and periodo_importo_variazione.periodo_id = dvar.periodo_id   ),
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
            and dvarsucc.ente_proprietario_id= '|| p_ente_prop_id||'                            
            and cvarsucc.variazione_stato_tipo_code=''D''   
            and avarsucc.bil_id = '||bilancio_id ||'  
            and periodo_importo_variazione.periodo_id = dvarsucc.periodo_id                                               
            and bvarsucc.data_cancellazione is null
            and dvarsucc.data_cancellazione IS NULL)
        select  varsuccess.elem_id_var, varsuccess.elem_det_tipo_id, varcurr.anno_comp,
                sum(varsuccess.importo_var) totale_var_succ
        from varcurr
              JOIN varsuccess
                on (varcurr.elem_det_tipo_id = varsuccess.elem_det_tipo_id
                      and varcurr.periodo_id = varsuccess.periodo_id
                      and varsuccess.validita_inizio > varcurr.validita_inizio
                      and varcurr.elem_id_var = varsuccess.elem_id_var) 
        group by varsuccess.elem_id_var, varsuccess.elem_det_tipo_id,varcurr.anno_comp  )    
                      INSERT INTO siac_rep_cap_eg_imp
                      select 	cap.elem_id, 
                                cap.BIL_ELE_IMP_ANNO, 
                                cap.TIPO_IMP,
                                cap.ente_proprietario_id, 
                                 '''||user_table||''' utente,                                        
                                (cap.importo_cap  - COALESCE(importi_variaz.totale_var_succ,0)) diff
                      from cap LEFT  JOIN importi_variaz 
                      ON (cap.elem_id = importi_variaz.elem_id_var
                        and cap.elem_det_tipo_id= importi_variaz.elem_det_tipo_id
                         and cap.BIL_ELE_IMP_ANNO=importi_variaz.anno_comp)';                    
else                 
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
                  siac_d_bil_elem_stato 		stato_capitolo,
                  siac_r_bil_elem_stato 		r_capitolo_stato,
                  siac_d_bil_elem_categoria 	cat_del_capitolo,
                  siac_r_bil_elem_categoria 	r_cat_capitolo,
                  siac_t_bil_elem 			capitolo
          where   capitolo.elem_id					=	capitolo_importi.elem_id
              and 	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id
          	  and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
              and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id
              and	capitolo.elem_id					=	r_capitolo_stato.elem_id
              and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
              and	capitolo.elem_id					=	r_cat_capitolo.elem_id
              and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id              
          	  and	capitolo_importi.ente_proprietario_id 	='||p_ente_prop_id ||'             
              and	capitolo.bil_id					=	'||bilancio_id ||'  
              and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''                            
              and stato_capitolo.elem_stato_code	in (''VA'', ''PR'')              
              and capitolo_imp_tipo.elem_det_tipo_code in (''STA'', ''SCA'',''STR'')
              and	capitolo_importi.data_cancellazione 		is null
              and	capitolo_imp_tipo.data_cancellazione 		is null
              and	capitolo_imp_periodo.data_cancellazione 	is null
              and	capitolo.data_cancellazione 				is null
              and	tipo_elemento.data_cancellazione 			is null              
              and	stato_capitolo.data_cancellazione 			is null
              and	r_capitolo_stato.data_cancellazione 		is null
              and cat_del_capitolo.data_cancellazione 		is null
              and	r_cat_capitolo.data_cancellazione 			is null
          group by	capitolo_importi.elem_id,
          capitolo_imp_tipo.elem_det_tipo_code,
          capitolo_imp_periodo.anno,
          capitolo_importi.ente_proprietario_id,
          capitolo_imp_tipo.elem_det_tipo_id) ';
	sql_query:=sql_query||'
              INSERT INTO siac_rep_cap_eg_imp
              select 	cap.elem_id,
              			cap.BIL_ELE_IMP_ANNO,
                		cap.TIPO_IMP,
              			cap.ente_proprietario_id,
                        '''||user_table||''' utente,
                		cap.importo_cap 
              from cap ';          
end if;
        
raise notice 'query: %', sql_query;

execute  sql_query;

     RTN_MESSAGGIO:='preparazione tabella importi riga capitolo ''.';  


insert into siac_rep_cap_eg_imp_riga
select  tb1.elem_id,
		tb3.importo		as		residui_attivi,
        tb1.importo 	as 		previsioni_definitive_comp,
        tb2.importo		as		previsioni_definitive_cassa,
        tb1.ente_proprietario,
        user_table utente,
        tb1.periodo_anno
from   
	siac_rep_cap_eg_imp tb1, siac_rep_cap_eg_imp tb2, siac_rep_cap_eg_imp tb3
	where			tb1.elem_id	=	tb2.elem_id	 								and
    				tb1.elem_id	=	tb3.elem_id	 								and												
        			--tb1.periodo_anno 	= annoCapImp1		AND	
                    tb1.tipo_imp =	tipoImpComp		        and  
        			tb2.periodo_anno	= tb1.periodo_anno	AND	
                    tb2.tipo_imp = 	tipoImpCassa	        and
                    tb3.periodo_anno	= tb1.periodo_anno	AND	
                    tb3.tipo_imp = 	tipoImpRes		        and
                    tb1.ente_proprietario =	p_ente_prop_id						and
                  	tb2.ente_proprietario	=	tb1.ente_proprietario			and
                    tb3.ente_proprietario	=	tb1.ente_proprietario			and
                    tb1.utente				=	user_table						and
                    tb2.utente				=	tb1.utente						and
                    tb3.utente				=	tb1.utente;
                  
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
from   --importi del primo anno.
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and tb1.periodo_anno=annoCapImp1
        and tb1.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and tb2.periodo_anno=annoCapImp1
        and tb2.utente = tb0.utente )
    left join siac_rep_var_entrate tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and tb3.periodo_anno=annoCapImp1
        and tb3.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and tb4.periodo_anno=annoCapImp1
        and tb4.utente = tb0.utente )
    left join siac_rep_var_entrate tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
        and tb5.periodo_anno=annoCapImp1
        and tb5.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and tb6.periodo_anno=annoCapImp1
        and tb6.utente = tb0.utente )
    where tb0.ente_proprietario_id=p_ente_prop_id
	and tb0.utente=user_table 
  union --importi del secondo anno.
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
        and tb1.periodo_anno= annoCapImp2
        and tb1.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and tb2.periodo_anno= annoCapImp2
        and tb2.utente = tb0.utente )
    left join siac_rep_var_entrate tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and tb3.periodo_anno= annoCapImp2
        and tb3.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and tb4.periodo_anno= annoCapImp2
        and tb4.utente = tb0.utente )
    left join siac_rep_var_entrate tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
        and tb5.periodo_anno= annoCapImp2
        and tb5.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and tb6.periodo_anno= annoCapImp2
        and tb6.utente = tb0.utente 	)
    where tb0.ente_proprietario_id=p_ente_prop_id
	and tb0.utente=user_table 
    union  --importi del terzo anno.
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
        and tb1.periodo_anno= annoCapImp3
        and tb1.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and tb2.periodo_anno= annoCapImp3
        and tb2.utente = tb0.utente )
    left join siac_rep_var_entrate tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and tb3.periodo_anno= annoCapImp3
        and tb3.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and tb4.periodo_anno= annoCapImp3
        and tb4.utente = tb0.utente )
    left join siac_rep_var_entrate tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
        and tb5.periodo_anno= annoCapImp3
        and tb5.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and tb6.periodo_anno= annoCapImp3
        and tb6.utente = tb0.utente 	)
    where tb0.ente_proprietario_id=p_ente_prop_id
	and tb0.utente=user_table ;


        
     RTN_MESSAGGIO:='preparazione file output ''.';          
  
/* 20/05/2016: aggiunto il controllo se il capitolo ha subito delle variazioni, tramite
	il test su siac_rep_var_entrate_riga x, siac_rep_cap_eg y, siac_r_class_fam_tree z
*/
for classifBilRec in

select distinct	
		struttura.classif_tipo_desc1    		titoloe_TIPO_DESC,
       	struttura.titolo_id              		titoloe_ID,
       	struttura.titolo_code             		titoloe_CODE,
       	struttura.titolo_desc             		titoloe_DESC,
       	struttura.classif_tipo_desc2  			tipologia_TIPO_DESC,
       	struttura.tipologia_id              	tipologia_ID,
       	struttura.tipologia_code            	tipologia_CODE,
       	struttura.tipologia_desc            	tipologia_DESC,
       	struttura.classif_tipo_desc3     		categoria_TIPO_DESC,
      	struttura.categoria_id              	categoria_ID,
       	struttura.categoria_code            	categoria_CODE,
       	struttura.categoria_desc            	categoria_DESC,
    	capitoli.anno_bilancio    			BIL_ANNO,
       	capitoli.elem_code     				BIL_ELE_CODE,
       	capitoli.elem_desc     				BIL_ELE_DESC,
       	capitoli.elem_code2     				BIL_ELE_CODE2,
       	capitoli.elem_desc2     				BIL_ELE_DESC2,
       	capitoli.elem_id      				BIL_ELE_ID,
       	capitoli.elem_id_padre    			BIL_ELE_ID_PADRE,
        COALESCE (importi_anno1.previsioni_definitive_comp,0)	stanziamento_anno1,
    	COALESCE (importi_anno1.previsioni_definitive_cassa,0)	cassa,
        COALESCE (importi_anno1.residui_attivi,0)				residuo,
        COALESCE (importi_anno2.previsioni_definitive_comp,0)	stanziamento_anno2,
        COALESCE (importi_anno3.previsioni_definitive_comp,0) stanziamento_anno3,
              COALESCE (var_stanziato_anno1.variazione_aumento_stanziato,0)			variazione_aumento_stanziato_anno1,
              COALESCE (var_stanziato_anno1.variazione_diminuzione_stanziato* -1,0)		variazione_diminuzione_stanziato_anno1,
              COALESCE (var_stanziato_anno1.variazione_aumento_cassa,0)				variazione_aumento_cassa,
              COALESCE (var_stanziato_anno1.variazione_diminuzione_cassa* -1,0)			variazione_diminuzione_cassa,
              COALESCE (var_stanziato_anno1.variazione_aumento_residuo,0)				variazione_aumento_residuo,
              COALESCE (var_stanziato_anno1.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
              COALESCE (var_stanziato_anno2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato_anno2,
              COALESCE (var_stanziato_anno2.variazione_diminuzione_stanziato* -1,0)		variazione_diminuzione_stanziato_anno2,
              COALESCE (var_stanziato_anno3.variazione_aumento_stanziato,0)			variazione_aumento_stanziato_anno3,
			  COALESCE (var_stanziato_anno3.variazione_diminuzione_stanziato* -1,0)		variazione_diminuzione_stanziato_anno3
from  	siac_rep_tit_tip_cat_riga_anni struttura  
          left  join siac_rep_cap_eg capitoli
             on    	(struttura.categoria_id = capitoli.classif_id    
                      and struttura.ente_proprietario_id=p_ente_prop_id
                      and capitoli.ente_proprietario_id	=struttura.ente_proprietario_id
                      AND capitoli.utente=struttura.utente
                      and struttura.utente=user_table)                    
            left	join    siac_rep_cap_eg_imp_riga importi_anno1  
              on (importi_anno1.elem_id	=	capitoli.elem_id 
                      AND capitoli.utente=importi_anno1.utente
                      and capitoli.ente_proprietario_id	=importi_anno1.ente_proprietario_id
                      and importi_anno1.periodo_anno=annoCapImp1
                      and capitoli.utente=user_table)                    
             left	join    siac_rep_cap_eg_imp_riga importi_anno2  
              on (importi_anno2.elem_id	=	capitoli.elem_id 
                      AND capitoli.utente=importi_anno2.utente
                      and capitoli.ente_proprietario_id	=importi_anno2.ente_proprietario_id
                      and importi_anno2.periodo_anno=annoCapImp2
                      and capitoli.utente=user_table)
             left	join    siac_rep_cap_eg_imp_riga importi_anno3  
              on (importi_anno3.elem_id	=	capitoli.elem_id 
                      AND capitoli.utente=importi_anno3.utente
                      and capitoli.ente_proprietario_id	=importi_anno3.ente_proprietario_id
                      and importi_anno3.periodo_anno=annoCapImp3
                      and capitoli.utente=user_table)                                                      
              left join (select var.elem_id, --variazioni del primo anno
                          sum(COALESCE (var.variazione_aumento_stanziato, 0)) variazione_aumento_stanziato,
                          sum(COALESCE (var.variazione_diminuzione_stanziato, 0)) variazione_diminuzione_stanziato,
                          sum(COALESCE (var.variazione_aumento_cassa, 0)) variazione_aumento_cassa,
                          sum(COALESCE (var.variazione_diminuzione_cassa, 0)) variazione_diminuzione_cassa,
                          sum(COALESCE (var.variazione_aumento_residuo, 0)) variazione_aumento_residuo,
                          sum(COALESCE (var.variazione_diminuzione_residuo, 0)) variazione_diminuzione_residuo
                         from siac_rep_var_entrate_riga var
                         where var.ente_proprietario=p_ente_prop_id
                              and var.utente=user_table
                              and var.periodo_anno=annoCapImp1
                         group by var.elem_id) var_stanziato_anno1
              on var_stanziato_anno1.elem_id = importi_anno1.elem_id
            left join (select var.elem_id, --variazioni del secondo anno
            			sum(COALESCE (var.variazione_aumento_stanziato, 0)) variazione_aumento_stanziato,
                        sum(COALESCE (var.variazione_diminuzione_stanziato, 0)) variazione_diminuzione_stanziato
            	       from siac_rep_var_entrate_riga var
                       where var.ente_proprietario=p_ente_prop_id
                       		and var.utente=user_table
                            and var.periodo_anno=annoCapImp2
                       group by var.elem_id) var_stanziato_anno2
            on var_stanziato_anno2.elem_id = importi_anno2.elem_id
            left join (select var.elem_id, --variazioni del terzo anno
            			sum(COALESCE (var.variazione_aumento_stanziato, 0)) variazione_aumento_stanziato,
                        sum(COALESCE (var.variazione_diminuzione_stanziato, 0)) variazione_diminuzione_stanziato
            	       from siac_rep_var_entrate_riga var
                       where var.ente_proprietario=p_ente_prop_id
                       		and var.utente=user_table
                            and var.periodo_anno=annoCapImp3
                       group by var.elem_id) var_stanziato_anno3
            on var_stanziato_anno3.elem_id = importi_anno3.elem_id            
    where struttura.utente = user_table 
         and exists (  --controllo se il capitolo ha subito delle variazioni, tramite
						--il test su siac_rep_var_entrate_riga x, siac_rep_cap_eg y, siac_r_class_fam_tree z
         			select 1 from siac_rep_var_entrate_riga x, siac_rep_cap_eg y, 
                                      siac_r_class_fam_tree z
                      where x.elem_id= y.elem_id
                       and x.utente=user_table
                       and y.utente=user_table
                       and y.classif_id = z.classif_id
                       and z.classif_id_padre = struttura.tipologia_id     
          )	
    union  --capitoli che non hanno la struttura.
          select 	'Titolo'    			titoloe_TIPO_DESC,
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
              capitoli.anno_bilancio    			BIL_ANNO,
              capitoli.elem_code     				BIL_ELE_CODE,
              capitoli.elem_desc     				BIL_ELE_DESC,
              capitoli.elem_code2     				BIL_ELE_CODE2,
              capitoli.elem_desc2     				BIL_ELE_DESC2,
              capitoli.elem_id      				BIL_ELE_ID,
              capitoli.elem_id_padre    			BIL_ELE_ID_PADRE,
              COALESCE (importi_anno1.previsioni_definitive_comp,0)	stanziamento_anno1,
              COALESCE (importi_anno1.previsioni_definitive_cassa,0)	cassa,
              COALESCE (importi_anno1.residui_attivi,0)				residuo,
              COALESCE (importi_anno2.previsioni_definitive_comp,0)	stanziamento_anno2,
              COALESCE (importi_anno3.previsioni_definitive_comp,0) stanziamento_anno3,
              COALESCE (var_stanziato_anno1.variazione_aumento_stanziato,0)			variazione_aumento_stanziato_anno1,
              COALESCE (var_stanziato_anno1.variazione_diminuzione_stanziato* -1,0)		variazione_diminuzione_stanziato_anno1,
              COALESCE (var_stanziato_anno1.variazione_aumento_cassa,0)				variazione_aumento_cassa,
              COALESCE (var_stanziato_anno1.variazione_diminuzione_cassa* -1,0)			variazione_diminuzione_cassa,
              COALESCE (var_stanziato_anno1.variazione_aumento_residuo,0)				variazione_aumento_residuo,
              COALESCE (var_stanziato_anno1.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
              COALESCE (var_stanziato_anno2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato_anno2,
              COALESCE (var_stanziato_anno2.variazione_diminuzione_stanziato* -1,0)		variazione_diminuzione_stanziato_anno2,
              COALESCE (var_stanziato_anno3.variazione_aumento_stanziato,0)			variazione_aumento_stanziato_anno3,
			  COALESCE (var_stanziato_anno3.variazione_diminuzione_stanziato* -1,0)		variazione_diminuzione_stanziato_anno3
      from  	siac_rep_cap_eg  capitoli
                  left	join    siac_rep_cap_eg_imp_riga importi_anno1  
              on (importi_anno1.elem_id	=	capitoli.elem_id 
                      AND capitoli.utente=importi_anno1.utente
                      and importi_anno1.periodo_anno=annoCapImp1
                      and capitoli.utente=user_table)                    
             left	join    siac_rep_cap_eg_imp_riga importi_anno2  
              on (importi_anno2.elem_id	=	capitoli.elem_id 
                      AND capitoli.utente=importi_anno2.utente
                      and importi_anno2.periodo_anno=annoCapImp2
                      and capitoli.utente=user_table)
             left	join    siac_rep_cap_eg_imp_riga importi_anno3  
              on (importi_anno3.elem_id	=	capitoli.elem_id 
                      AND capitoli.utente=importi_anno3.utente
                      and importi_anno3.periodo_anno=annoCapImp3
                      and capitoli.utente=user_table)                                                      
              left join (select var.elem_id, --variazioni del primo anno
                          sum(COALESCE (var.variazione_aumento_stanziato, 0)) variazione_aumento_stanziato,
                          sum(COALESCE (var.variazione_diminuzione_stanziato, 0)) variazione_diminuzione_stanziato,
                          sum(COALESCE (var.variazione_aumento_cassa, 0)) variazione_aumento_cassa,
                          sum(COALESCE (var.variazione_diminuzione_cassa, 0)) variazione_diminuzione_cassa,
                          sum(COALESCE (var.variazione_aumento_residuo, 0)) variazione_aumento_residuo,
                          sum(COALESCE (var.variazione_diminuzione_residuo, 0)) variazione_diminuzione_residuo
                         from siac_rep_var_entrate_riga var
                         where var.ente_proprietario=p_ente_prop_id
                              and var.utente=user_table
                              and var.periodo_anno=annoCapImp1
                         group by var.elem_id) var_stanziato_anno1
              on var_stanziato_anno1.elem_id = importi_anno1.elem_id
            left join (select var.elem_id, --variazioni del secondo anno
            			sum(COALESCE (var.variazione_aumento_stanziato, 0)) variazione_aumento_stanziato,
                        sum(COALESCE (var.variazione_diminuzione_stanziato, 0)) variazione_diminuzione_stanziato
            	       from siac_rep_var_entrate_riga var
                       where var.ente_proprietario=p_ente_prop_id
                       		and var.utente=user_table
                            and var.periodo_anno=annoCapImp2
                       group by var.elem_id) var_stanziato_anno2
				on var_stanziato_anno2.elem_id = importi_anno2.elem_id                       
            left join (select var.elem_id, --variazioni del terzo anno
            			sum(COALESCE (var.variazione_aumento_stanziato, 0)) variazione_aumento_stanziato,
                        sum(COALESCE (var.variazione_diminuzione_stanziato, 0)) variazione_diminuzione_stanziato
            	       from siac_rep_var_entrate_riga var
                       where var.ente_proprietario=p_ente_prop_id
                       		and var.utente=user_table
                            and var.periodo_anno=annoCapImp3
                       group by var.elem_id) var_stanziato_anno3                       
            on var_stanziato_anno3.elem_id = importi_anno3.elem_id
    where capitoli.utente = user_table 	
         and capitoli.classif_id is null
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
stanziamento_anno1:=classifBilRec.stanziamento_anno1;
stanziamento_anno2:=classifBilRec.stanziamento_anno2;
stanziamento_anno3:=classifBilRec.stanziamento_anno3;
cassa:=classifBilRec.cassa;
residuo:=classifBilRec.residuo;
variazione_aumento_stanziato_anno1:=COALESCE(classifBilRec.variazione_aumento_stanziato_anno1,0);
variazione_diminuzione_stanziato_anno1:=COALESCE(classifBilRec.variazione_diminuzione_stanziato_anno1,0);
variazione_aumento_cassa:=COALESCE(classifBilRec.variazione_aumento_cassa,0);
variazione_diminuzione_cassa:=COALESCE(classifBilRec.variazione_diminuzione_cassa,0);
variazione_aumento_residuo:=COALESCE(classifBilRec.variazione_aumento_residuo,0);
variazione_diminuzione_residuo:=COALESCE(classifBilRec.variazione_diminuzione_residuo,0);
variazione_aumento_stanziato_anno2:=COALESCE(classifBilRec.variazione_aumento_stanziato_anno2,0);
variazione_diminuzione_stanziato_anno2:=COALESCE(classifBilRec.variazione_diminuzione_stanziato_anno2,0);
variazione_aumento_stanziato_anno3:=COALESCE(classifBilRec.variazione_aumento_stanziato_anno3,0);
variazione_diminuzione_stanziato_anno3:=COALESCE(classifBilRec.variazione_diminuzione_stanziato_anno3,0);

if variazione_aumento_stanziato_anno1 = 0 and	
	variazione_diminuzione_stanziato_anno1 = 0 and
    variazione_aumento_cassa = 0 and
    variazione_diminuzione_cassa = 0 and 
    variazione_aumento_residuo = 0 and
    variazione_diminuzione_residuo = 0 and
    variazione_aumento_stanziato_anno2 = 0 and
    variazione_diminuzione_stanziato_anno2 = 0 and
    variazione_aumento_stanziato_anno3 = 0 and
    variazione_diminuzione_stanziato_anno3 = 0 
then flag_visualizzazione:= -111;
else flag_visualizzazione:= bil_ele_id; 
end if;

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
stanziamento_anno1=0;
stanziamento_anno2 =0;
stanziamento_anno3  =0;
cassa=0;
residuo=0;

variazione_aumento_stanziato_anno1=0;
variazione_diminuzione_stanziato_anno1=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
variazione_aumento_stanziato_anno2 =0;
variazione_diminuzione_stanziato_anno2 =0;
variazione_aumento_stanziato_anno3 =0;
variazione_diminuzione_stanziato_anno3 =0;

flag_visualizzazione = -111;
display_error='';

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
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR263_stampa_variazione_definitiva_pluriennale_entrate" (p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar, p_stampa_stanz varchar)
  OWNER TO siac;