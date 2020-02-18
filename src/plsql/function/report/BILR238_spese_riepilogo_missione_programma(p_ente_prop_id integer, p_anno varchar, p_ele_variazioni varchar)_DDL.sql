/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR238_spese_riepilogo_missione_programma" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar
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
  bil_ele_code3 varchar,
  bil_ele_id integer,
  imp_variaz_stanz_anno numeric,
  imp_variaz_stanz_anno1 numeric,
  imp_variaz_stanz_anno2 numeric,
  imp_variaz_cassa_anno numeric,
  imp_variaz_stanz_fpv_anno numeric,
  imp_variaz_stanz_fpv_anno1 numeric,
  imp_variaz_stanz_fpv_anno2 numeric,
  imp_variaz_residui_anno numeric,
  impegnato_anno numeric,
  impegnato_anno1 numeric,
  impegnato_anno2 numeric,
  display_error varchar
) AS
$body$
DECLARE

classifBilRec record;
ImpegniRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
elemTipoCode_UG	varchar;
TipoImpstanzresidui varchar;
tipo_capitolo	varchar;
h_count integer :=0;
importo integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
tipologia_capitolo	varchar;
cat_capitolo	varchar;
esiste_siac_t_dicuiimpegnato_bilprev integer;
annoPrec VARCHAR;
annobilint integer :=0;
previsioni_anno_prec_cassa_app NUMERIC;
previsioni_anno_prec_comp_app NUMERIC;
tipo_categ_capitolo VARCHAR;
stanziamento_fpv_anno_prec_app NUMERIC;
sql_query VARCHAR;
strApp VARCHAR;
intApp INTEGER;
v_importo_imp   NUMERIC :=0;
v_importo_imp1  NUMERIC :=0;
v_importo_imp2  NUMERIC :=0;
v_conta_rec INTEGER :=0;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
x_array VARCHAR [];

contaParVarPeg integer;
contaParVarBil integer;

BEGIN

/*
	28/10/2019.
	Funzione creata per la richiesta SIAC-7041 usata dai report BILR238, BILR239, BILR240.
    La funzione si basa sul comportamento della funzione "BILR111_Allegato_9_bil_gest_spesa_mpt" 
    ma riceve in input, oltre all'ente ed all'anno bilancio, solo un elenco di variazioni 
    obbligatorio.
    La funzione fornisce in output solo i dati delle variazioni raggruppati per:
    - missione
    - programma
    - titolo
	- macroaggregato
    - capitolo.
    E' compito di ciascun report raggruppare ulteriormente i dati secondo le necessita'.
    Gli importi delle variazioni riguardano:
    - competenza anno bilancio, annobilancio + 1 e anno bilancio + 2;
    - cassa anno bilancio;
    - residui anno bilancio;
    - stanziamento fpv anno bilancio, annobilancio + 1 e anno bilancio + 2.
    
    Gli importi degli impegni sono impostati a 0 perche' nei report esistono i campi ma non
    devono essere valorizzati.
    
    ATTENZIONE: 
    Gli importi delle variazioni riguardano solo i capitoli di tipo ('STD','FSC','FPV','FPVC'),
    cosi' come fatto dalla procedura "BILR111_Allegato_9_bil_gest_spesa_mpt".
    Per questo modivo se si confrontano i totali delle variazioni da applicativo con i totali 
    estratti da questa procedura potrebbero esserci delle differenze, in quanto le variazioni
    potrebbero coinvolgere anche altri tipi di capitoli.    
    
*/

annobilint := p_anno::INTEGER;
annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
elemTipoCode:='CAP-UG'; -- tipo capitolo previsione
elemTipoCode_UG:='CAP-UG';	--- Capitolo gestione

annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;
display_error='';
contaParVarPeg:=0;
contaParVarBil:=0;

-- verifico che il parametro con l'elenco delle variazioni abbia solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  -- ALESSANDRO - SIAC-5208 - non posso castare l'intera stringa a integer: spezzo e parsifico pezzo a pezzo
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    --strApp=REPLACE(p_ele_variazioni,',','');
    --raise notice 'VAR: %', strApp;
    intApp = strApp::INTEGER;
  END LOOP;
  -- ALESSANDRO - SIAC-5208 - FINE
END IF;



select fnc_siac_random_user()
into	user_table;

raise notice '1: %', clock_timestamp()::varchar;  
-- raise notice 'user  %',user_table;

bil_anno='';

missione_code='';
missione_desc='';

programma_code='';
programma_desc='';

titusc_code='';
titusc_desc='';

macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
imp_variaz_stanz_anno=0;
imp_variaz_stanz_anno1=0;
imp_variaz_stanz_anno2=0;
imp_variaz_cassa_anno=0;
imp_variaz_stanz_fpv_anno=0;
imp_variaz_stanz_fpv_anno1=0;
imp_variaz_stanz_fpv_anno2=0;
   
display_error:='';

--uso una tabella di appoggio per le varizioni perche' la query e' di tipo dinamico
--in quanto il parametro con l'elenco delle variazioni e' variabile.

sql_query='
    insert into siac_rep_var_spese
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

raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;                
                
return query 
with struttura as (
	select * from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, p_anno,user_table)),
capitoli as (   
    select 	programma.classif_id classif_id_programma,
            macroaggr.classif_id classif_id_macroaggregato,
            anno_eserc.anno anno_bilancio,
            capitolo.elem_code, 
            capitolo.elem_code2,
            capitolo.elem_code3,
            capitolo.elem_desc,
            capitolo.elem_id,
            capitolo.elem_desc2
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
        programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
        programma.classif_id=r_capitolo_programma.classif_id					and
        macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
        macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
        bilancio.periodo_id=anno_eserc.periodo_id 								and
        capitolo.bil_id=bilancio.bil_id 										and
        capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
        tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
        capitolo.elem_id=r_capitolo_programma.elem_id							and
        capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
        capitolo.elem_id				=	r_capitolo_stato.elem_id			and
        r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
        capitolo.elem_id				=	r_cat_capitolo.elem_id				and
        r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and                
        capitolo.ente_proprietario_id=p_ente_prop_id      						and
        anno_eserc.anno= p_anno 												and
        programma_tipo.classif_tipo_code='PROGRAMMA' 							and
        macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
        stato_capitolo.elem_stato_code	=	'VA'								and
        cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
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
        and	r_cat_capitolo.data_cancellazione 	 		is null),
	variaz_stanz_anno as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('STD','FSC','FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_stanz_anno1 as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp1
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('STD','FSC','FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_stanz_anno2 as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp2
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('STD','FSC','FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_cassa_anno as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp
                and variaz.tipologia = TipoImpCassa  --'SCA' -- cassa
                and d_bil_elem_categ.elem_cat_code in ('STD','FSC','FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id )  ,
      variaz_stanz_fpv_anno as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_stanz_fpv_anno1 as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp1
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_stanz_fpv_anno2 as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp2
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id )  ,
    variaz_residui_anno as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp
                and variaz.tipologia = TipoImpRes --'STR'  residui
                and d_bil_elem_categ.elem_cat_code in ('STD','FSC','FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id )              		                                    
select 
  p_anno::varchar bil_anno,
  struttura.missione_tipo_desc::varchar missione_tipo_desc,
  struttura.missione_code::varchar missione_code,
  struttura.missione_desc:: varchar missione_desc,
  struttura.programma_tipo_desc:: varchar programma_tipo_desc,
  struttura.programma_code::varchar programma_code,
  struttura.programma_desc::varchar programma_desc,
  struttura.titusc_tipo_desc::varchar titusc_tipo_desc,
  struttura.titusc_code::varchar titusc_code,
  struttura.titusc_desc::varchar titusc_desc,
  struttura.macroag_tipo_desc::varchar macroag_tipo_desc,
  struttura.macroag_code::varchar macroag_code,
  struttura.macroag_desc::varchar macroag_desc,
  capitoli.elem_code::varchar bil_ele_code,
  capitoli.elem_desc::varchar bil_ele_desc,
  capitoli.elem_code2::varchar bil_ele_code2,
  capitoli.elem_desc2::varchar bil_ele_desc2,
  capitoli.elem_code3::varchar bil_ele_code3,
  capitoli.elem_id::integer bil_ele_id,
  COALESCE(variaz_stanz_anno.importo_variaz,0)::numeric imp_variaz_stanz_anno,
  COALESCE(variaz_stanz_anno1.importo_variaz,0)::numeric imp_variaz_stanz_anno1,
  COALESCE(variaz_stanz_anno2.importo_variaz,0)::numeric imp_variaz_stanz_anno2,
  COALESCE(variaz_cassa_anno.importo_variaz,0)::numeric imp_variaz_cassa_anno,
  COALESCE(variaz_stanz_fpv_anno.importo_variaz,0)::numeric imp_variaz_stanz_fpv_anno,
  COALESCE(variaz_stanz_fpv_anno1.importo_variaz,0)::numeric imp_variaz_stanz_fpv_anno1,
  COALESCE(variaz_stanz_fpv_anno2.importo_variaz,0)::numeric imp_variaz_stanz_fpv_anno2,
  COALESCE(variaz_residui_anno.importo_variaz,0)::numeric imp_variaz_residui_anno,  
  0::numeric impegnato_anno,
  0::numeric impegnato_anno1,
  0::numeric impegnato_anno2,
  ''::varchar display_error  
from struttura 
	left join capitoli
    	on (struttura.programma_id = capitoli.classif_id_programma    
           	and	struttura.macroag_id = capitoli.classif_id_macroaggregato)
    left join variaz_stanz_anno
      on variaz_stanz_anno.elem_id = capitoli.elem_id
    left join variaz_stanz_anno1
      on variaz_stanz_anno1.elem_id = capitoli.elem_id
    left join variaz_stanz_anno2
      on variaz_stanz_anno2.elem_id = capitoli.elem_id 
    left join variaz_cassa_anno
      on variaz_cassa_anno.elem_id = capitoli.elem_id
    left join variaz_stanz_fpv_anno
      on variaz_stanz_fpv_anno.elem_id = capitoli.elem_id
    left join variaz_stanz_fpv_anno1
      on variaz_stanz_fpv_anno1.elem_id = capitoli.elem_id
    left join variaz_stanz_fpv_anno2
      on variaz_stanz_fpv_anno2.elem_id = capitoli.elem_id
    left join variaz_residui_anno
      on variaz_residui_anno.elem_id = capitoli.elem_id;
                    
       
                          
delete from siac_rep_var_spese  where utente=user_table;

raise notice 'fine OK';
    exception
    when no_data_found THEN
      raise notice 'Nessun dato trovato riguardo la struttura di bilancio.';
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