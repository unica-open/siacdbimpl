/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR263_stampa_variazione_definitiva_pluriennale_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_stampa_stanz varchar
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
  stanziamento_anno1 numeric,
  variazione_aumento_stanziato_anno1 numeric,
  variazione_diminuzione_stanziato_anno1 numeric,
  stanziamento_anno2 numeric,
  variazione_aumento_stanziato_anno2 numeric,
  variazione_diminuzione_stanziato_anno2 numeric,
  display_error varchar,
  flag_visualizzazione numeric
) AS
$body$
DECLARE


classifBilRec record;


annoCapImp1 varchar;
annoCapImp2 varchar;
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
bilancio_id	integer;
strQuery varchar;


BEGIN

annocapimp1:=(p_anno::INTEGER + 1)::varchar;
annocapimp2:=(p_anno::INTEGER + 2)::varchar;



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
display_error='';
flag_visualizzazione = -111;
---------------------------------------------------------------------------------------------------------------------

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
    
 RTN_MESSAGGIO:='Estrazione delle variazioni.';  

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
sql_query=sql_query ||' and		tipologia_stato_var.variazione_stato_tipo_code		 in	(''D'') and 
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

raise notice 'Query variazioni = %', sql_query;
execute  sql_query;
              
 RTN_MESSAGGIO:='Estrazione degli importi dei capitoli.';  
 
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
              and stato_capitolo.elem_stato_code	in (''VA'')--, ''PR'')                  
              --and cat_del_capitolo.elem_cat_code		in (''STD'')   
              and cat_del_capitolo.elem_cat_code	in (''STD'',''FPV'',''FSC'',''FPVC'')     
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
                      INSERT INTO siac_rep_cap_ug_imp
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
          where    capitolo.elem_id					=	capitolo_importi.elem_id
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
              INSERT INTO siac_rep_cap_ug_imp
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


 RTN_MESSAGGIO:='Return dei dati.';       
        
return QUERY
with strutt_bilancio as (select * 
		from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id,p_anno,'')),
capitoli as (select programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
        p_anno anno_bilancio,
       	capitolo.*
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
where programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and        
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and        
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
   	capitolo.bil_id=bilancio_id												and
    programma_tipo.classif_tipo_code='PROGRAMMA' 							and	
    macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    stato_capitolo.elem_stato_code	in ('VA', 'PR')							   		 
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
    and	r_cat_capitolo.data_cancellazione 			is null
    UNION  -- Unisco i capitoli senza struttura
    select null, null,
        p_anno anno_bilancio,
        e.*
       from 	
              siac_t_bil_elem e,              
              siac_d_bil_elem_tipo tipo_elemento, 
              siac_d_bil_elem_stato stato_capitolo,
              siac_r_bil_elem_stato r_capitolo_stato
      where e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
      and	e.elem_id						=	r_capitolo_stato.elem_id
      and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
      and e.ente_proprietario_id			= 	p_ente_prop_id
      and e.bil_id						=	bilancio_id       
      and tipo_elemento.elem_tipo_code 	= 	elemTipoCode      								
      and stato_capitolo.elem_stato_code	in ('VA', 'PR')			
      and e.data_cancellazione 				is null
      and r_capitolo_stato.data_cancellazione	is null
      and tipo_elemento.data_cancellazione	is null
      and stato_capitolo.data_cancellazione 	is null
      and not EXISTS (select 1
      		from siac_d_class_tipo a,
     				siac_t_class b,
                     siac_r_bil_elem_class x
            where a.classif_tipo_id=b.classif_tipo_id
            	and b.classif_id=x.classif_id
            	and x.elem_id = e.elem_id
                and a.classif_tipo_code='PROGRAMMA')),
		importi_stanz_anno as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_ug_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipo_imp=TipoImpComp -- ''STA''
                        and a.utente=user_table
                        group by  a.elem_id),
         importi_cassa_anno as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_ug_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipo_imp=TipoImpCassa -- ''SCA''
                        and a.utente=user_table
                        group by  a.elem_id),
         importi_residui_anno as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_ug_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipo_imp=TipoImpRes -- ''STR''
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_stanz_pos_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_stanz_neg_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id),   
         variaz_cassa_pos_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario = p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipologia=TipoImpCassa -- ''SCA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id), 
         variaz_cassa_neg_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipologia=TipoImpCassa -- ''SCA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id), 
         variaz_residui_pos_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id 
                        and a.periodo_anno=p_anno                       
                        and a.tipologia=TipoImpRes -- ''STR''
                        and a.importo > 0
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_residui_neg_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipologia=TipoImpRes -- ''STR''
                        and a.importo < 0
                        and a.utente=user_table
                        group by  a.elem_id) ,
		importi_stanz_anno1 as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_ug_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp1
                        and a.tipo_imp=TipoImpComp -- ''STA''
                        and a.utente=user_table
                        group by  a.elem_id),   
      	variaz_stanz_pos_anno1 as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp1
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_stanz_neg_anno1 as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp1
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id),     
		importi_stanz_anno2 as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_ug_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp2
                        and a.tipo_imp=TipoImpComp -- ''STA''
                        and a.utente=user_table
                        group by  a.elem_id),   
      	variaz_stanz_pos_anno2 as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp2
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_stanz_neg_anno2 as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp2
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id)                                                                      
select distinct p_anno::varchar bil_anno,
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
        capitoli.elem_id_padre::integer bil_ele_id_padre,
        COALESCE(importi_stanz_anno.importo_cap,0)::numeric stanziamento,
        COALESCE(importi_cassa_anno.importo_cap,0)::numeric cassa,
        COALESCE(importi_residui_anno.importo_cap,0)::numeric residuo,
        COALESCE(variaz_stanz_pos_anno.importo_var,0)::numeric variazione_aumento_stanziato,
        COALESCE(variaz_stanz_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_stanziato,
        COALESCE(variaz_cassa_pos_anno.importo_var,0)::numeric variazione_aumento_cassa,
        COALESCE(variaz_cassa_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_cassa,
        COALESCE(variaz_residui_pos_anno.importo_var,0)::numeric variazione_aumento_residuo,
        COALESCE(variaz_residui_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_residuo,
        COALESCE(importi_stanz_anno1.importo_cap,0)::numeric stanziamento_anno1,
        COALESCE(variaz_stanz_pos_anno1.importo_var,0)::numeric variazione_aumento_stanziato_anno1,
        COALESCE(variaz_stanz_neg_anno1.importo_var *-1,0)::numeric variazione_diminuzione_stanziato_anno1,
        COALESCE(importi_stanz_anno2.importo_cap,0)::numeric stanziamento_anno2,
        COALESCE(variaz_stanz_pos_anno2.importo_var,0)::numeric variazione_aumento_stanziato_anno2,
        COALESCE(variaz_stanz_neg_anno2.importo_var *-1,0)::numeric variazione_diminuzione_stanziato_anno2,        
        ''::varchar display_error,            
        case when (COALESCE(variaz_stanz_pos_anno.importo_var,0) = 0 and
                COALESCE(variaz_stanz_neg_anno.importo_var *-1,0) = 0 and
                COALESCE(variaz_cassa_pos_anno.importo_var,0) = 0 and
                COALESCE(variaz_cassa_neg_anno.importo_var *-1,0) = 0 and
                COALESCE(variaz_residui_pos_anno.importo_var,0) = 0 and
                COALESCE(variaz_residui_neg_anno.importo_var *-1,0) = 0 and               
                COALESCE(variaz_stanz_pos_anno1.importo_var,0) = 0 and
                COALESCE(variaz_stanz_neg_anno1.importo_var *-1,0) = 0 and
                COALESCE(variaz_stanz_pos_anno2.importo_var,0) = 0 and 
                COALESCE(variaz_stanz_neg_anno2.importo_var *-1,0) = 0) 
            then -111::numeric
            else capitoli.elem_id::numeric  end flag_visualizzazione
from strutt_bilancio
      LEFT JOIN capitoli
          ON (strutt_bilancio.programma_id = capitoli.programma_id
              and strutt_bilancio.macroag_id = capitoli.macroaggregato_id)
      LEFT JOIN importi_stanz_anno
          ON importi_stanz_anno.elem_id = capitoli.elem_id
      LEFT JOIN importi_cassa_anno
          ON importi_cassa_anno.elem_id = capitoli.elem_id
      LEFT JOIN importi_residui_anno
          ON importi_residui_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_pos_anno
          ON variaz_stanz_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno
          ON variaz_stanz_neg_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_cassa_pos_anno
          ON variaz_cassa_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_cassa_neg_anno
          ON variaz_cassa_neg_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_residui_pos_anno
          ON variaz_residui_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_residui_neg_anno
          ON variaz_residui_neg_anno.elem_id = capitoli.elem_id
	  LEFT JOIN importi_stanz_anno1
          ON importi_stanz_anno1.elem_id = capitoli.elem_id	
      LEFT JOIN variaz_stanz_pos_anno1
          ON variaz_stanz_pos_anno1.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno1
          ON variaz_stanz_neg_anno1.elem_id = capitoli.elem_id     
	  LEFT JOIN importi_stanz_anno2
          ON importi_stanz_anno2.elem_id = capitoli.elem_id	
      LEFT JOIN variaz_stanz_pos_anno2
          ON variaz_stanz_pos_anno2.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno2
          ON variaz_stanz_neg_anno2.elem_id = capitoli.elem_id            
where capitoli.elem_id is not null
 and exists (select 1 from siac_r_class_fam_tree aa,
        				capitoli bb,
                        siac_rep_cap_ug_imp cc
        			where bb.elem_id =cc.elem_id
                    	and bb.macroaggregato_id = aa.classif_id
                 		and aa.classif_id_padre = strutt_bilancio.titusc_id 
                        and bb.programma_id=strutt_bilancio.programma_id
                        and cc.utente=user_table)
union
select distinct p_anno::varchar bil_anno,
        'Missione'::varchar missione_tipo_desc ,
        '00'::varchar missione_code,
        ' '::varchar missione_desc,
        'Programma'::varchar programma_tipo_desc,
        '0000'::varchar programma_code,
        ' '::varchar programma_desc,
        'Titolo Spesa'::varchar titusc_tipo_desc,
        '0'::varchar titusc_code,
        ' '::varchar titusc_desc,
        'Macroaggregato'::varchar macroag_tipo_desc,
        '0000000'::varchar macroag_code,
        ' '::varchar macroag_desc,
        capitoli.elem_code::varchar bil_ele_code ,
        capitoli.elem_desc::varchar bil_ele_desc,
        capitoli.elem_code2::varchar bil_ele_code2,
        capitoli.elem_desc2::varchar bil_ele_desc2,
        capitoli.elem_id::integer bil_ele_id,
        capitoli.elem_id_padre::integer bil_ele_id_padre,
        COALESCE(importi_stanz_anno.importo_cap,0)::numeric stanziamento,
        COALESCE(importi_cassa_anno.importo_cap,0)::numeric cassa,
        COALESCE(importi_residui_anno.importo_cap,0)::numeric residuo,
        COALESCE(variaz_stanz_pos_anno.importo_var,0)::numeric variazione_aumento_stanziato,
        COALESCE(variaz_stanz_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_stanziato,
        COALESCE(variaz_cassa_pos_anno.importo_var,0)::numeric variazione_aumento_,
        COALESCE(variaz_cassa_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_cassa,
        COALESCE(variaz_residui_pos_anno.importo_var,0)::numeric variazione_aumento_residuo,
        COALESCE(variaz_residui_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_residuo,
        COALESCE(importi_stanz_anno1.importo_cap,0)::numeric stanziamento_anno1,
        COALESCE(variaz_stanz_pos_anno1.importo_var,0)::numeric variazione_aumento_stanziato_anno1,
        COALESCE(variaz_stanz_neg_anno1.importo_var *-1,0)::numeric variazione_diminuzione_stanziato_anno1,
        COALESCE(importi_stanz_anno2.importo_cap,0)::numeric stanziamento_anno2,
        COALESCE(variaz_stanz_pos_anno2.importo_var,0)::numeric variazione_aumento_stanziato_anno2,
        COALESCE(variaz_stanz_neg_anno2.importo_var *-1,0)::numeric variazione_diminuzione_stanziato_anno2,        
        ''::varchar display_error,            
        case when (COALESCE(variaz_stanz_pos_anno.importo_var,0) = 0 and
                COALESCE(variaz_stanz_neg_anno.importo_var *-1,0) = 0 and
                COALESCE(variaz_cassa_pos_anno.importo_var,0) = 0 and
                COALESCE(variaz_cassa_neg_anno.importo_var *-1,0) = 0 and
                COALESCE(variaz_residui_pos_anno.importo_var,0) = 0 and
                COALESCE(variaz_residui_neg_anno.importo_var *-1,0) = 0 and               
                COALESCE(variaz_stanz_pos_anno1.importo_var,0) = 0 and
                COALESCE(variaz_stanz_neg_anno1.importo_var *-1,0) = 0 and
                COALESCE(variaz_stanz_pos_anno2.importo_var,0) = 0 and 
                COALESCE(variaz_stanz_neg_anno2.importo_var *-1,0) = 0) 
            then -111::numeric
            else capitoli.elem_id::numeric  end flag_visualizzazione
from capitoli
      LEFT JOIN importi_stanz_anno
          ON importi_stanz_anno.elem_id = capitoli.elem_id
      LEFT JOIN importi_cassa_anno
          ON importi_cassa_anno.elem_id = capitoli.elem_id
      LEFT JOIN importi_residui_anno
          ON importi_residui_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_pos_anno
          ON variaz_stanz_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno
          ON variaz_stanz_neg_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_cassa_pos_anno
          ON variaz_cassa_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_cassa_neg_anno
          ON variaz_cassa_neg_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_residui_pos_anno
          ON variaz_residui_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_residui_neg_anno
          ON variaz_residui_neg_anno.elem_id = capitoli.elem_id
	  LEFT JOIN importi_stanz_anno1
          ON importi_stanz_anno1.elem_id = capitoli.elem_id	
      LEFT JOIN variaz_stanz_pos_anno1
          ON variaz_stanz_pos_anno1.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno1
          ON variaz_stanz_neg_anno1.elem_id = capitoli.elem_id     
	  LEFT JOIN importi_stanz_anno2
          ON importi_stanz_anno2.elem_id = capitoli.elem_id	
      LEFT JOIN variaz_stanz_pos_anno2
          ON variaz_stanz_pos_anno2.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno2
          ON variaz_stanz_neg_anno2.elem_id = capitoli.elem_id               
where capitoli.elem_id is not null
	and not EXISTS (select 1
      		from siac_d_class_tipo a,
     				siac_t_class b,
                     siac_r_bil_elem_class x
            where a.classif_tipo_id=b.classif_tipo_id
            	and b.classif_id=x.classif_id
            	and x.elem_id = capitoli.elem_id
                and x.ente_proprietario_id = p_ente_prop_id
                and a.classif_tipo_code='PROGRAMMA');          
        
delete from siac_rep_cap_ug_imp where utente=user_table;

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

ALTER FUNCTION siac."BILR263_stampa_variazione_definitiva_pluriennale_spese" (p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar, p_stampa_stanz varchar)
  OWNER TO siac;