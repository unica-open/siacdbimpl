/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 03-01-2020    Haitham - Maurizio    SIAC-7311 - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR024_Allegato_7_Allegato_delibera_variazione_su_spese"(p_ente_prop_id integer, p_anno character varying, p_numero_delibera integer, p_anno_delibera character varying, p_tipo_delibera character varying, p_anno_competenza character varying, p_ele_variazioni character varying)
 RETURNS TABLE(bil_anno character varying, missione_tipo_desc character varying, missione_code character varying, missione_desc character varying, programma_tipo_desc character varying, programma_code character varying, programma_desc character varying, titusc_tipo_desc character varying, titusc_code character varying, titusc_desc character varying, macroag_tipo_desc character varying, macroag_code character varying, macroag_desc character varying, bil_ele_code character varying, bil_ele_desc character varying, bil_ele_code2 character varying, bil_ele_desc2 character varying, bil_ele_id integer, bil_ele_id_padre integer, stanziamento numeric, cassa numeric, residuo numeric, variazione_aumento_stanziato numeric, variazione_diminuzione_stanziato numeric, variazione_aumento_cassa numeric, variazione_diminuzione_cassa numeric, variazione_aumento_residuo numeric, variazione_diminuzione_residuo numeric, display_error character varying)
 LANGUAGE plpgsql
AS $function$
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

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione

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
display_error:='';

contaParametriParz:=0;
contaParametri:=0;

/* 06/12/2019. SIAC-7226.
	Procedura rivista nell'ottica di ottimizzarla.
    Sono usate 2 tabelle di appoggio per il calcolo degli importi dei capitoli
    (siac_rep_cap_ug_imp) e per l'elenco dell variazioni (siac_rep_var_spese)
    perche' i parametri in input cambiano e le query devono essere cosatruite
    dinamicamente.
    In particolare la query dei capitoli e' piu' complessa perche' nel calcolo
    degli importi deve tenere conto delle variazioni definitive che sono state inserite
    in momenti successivi alle variazioni in input.
    Gli importi delle variazioni successive devono essere decrementati dagli importi
    di stanziamento, cassa e residuo.

*/

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

if contaParametriParz = 1 OR contaParametriParz = 2 then
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
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
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN    
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;


select fnc_siac_random_user()
into	user_table;

select a.bil_id 
	into bilancio_id 
from siac_t_bil a,siac_t_periodo b
where b.periodo_id=a.periodo_id
	and a.ente_proprietario_id=p_ente_prop_id 
	and b.anno=p_anno;
    
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
raise notice 'Fine query importi capitoli - % - Inizio query variazioni' , clock_timestamp()::text;
-----------------------------

--Caricamento degli importi delle variazioni.  
--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.            
--Parametro specificato: atto di variazione.
if p_numero_delibera is not null THEN        
    insert into siac_rep_var_spese    
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),        
            tipo_elemento.elem_det_tipo_code, 
            user_table utente,
            atto.ente_proprietario_id	      	
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
            siac_t_bil					t_bil,
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
    and 	t_bil.periodo_id 									=	anno_eserc.periodo_id		
    and 	t_bil.bil_id 										= testata_variazione.bil_id
    and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id	
    and 	atto.ente_proprietario_id 							= 	p_ente_prop_id 
    and		anno_eserc.anno										= 	p_anno				 	
    and		atto.attoamm_numero 								= 	p_numero_delibera
    and		atto.attoamm_anno									=	p_anno_delibera
    and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
    and		stato_atto.attoamm_stato_code						=	'DEFINITIVO'	
        -- 27/04:2017 l'anno di esercizio deve essere collegato a siac_t_bil									
        --and		anno_eserc.periodo_id 								=	testata_variazione.periodo_id								
    and		anno_importi.anno									= 	annoCapImp 									
     -- 15/06/2016: cambiati i tipi di variazione. Aggiunto 'AS'.
    --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF')
    -- 19/07/2016: tolto il test sul tipo di variazione: accettate tutte.
    --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF', 'AS')
    and		tipologia_stato_var.variazione_stato_tipo_code		=	'D'
    and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
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
    and		t_bil.data_cancellazione					is null
    group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                atto.ente_proprietario_id   ;
ELSE  --specificata la variazione
	strQuery:= '
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),        
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
        testata_variazione.ente_proprietario_id	      	
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
        and		anno_importi.anno									= 	'''||annoCapImp||'''									
        and		tipologia_stato_var.variazione_stato_tipo_code		=	''D''
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
                    testata_variazione.ente_proprietario_id';                    

	raise notice 'Query2 = %', strQuery;
    execute  strQuery;
    
end if;    
raise notice 'Fine query Variazioni - % - inizio query finale' , clock_timestamp()::text;


return query 
with strutt_bilancio as (select *
        		from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id,p_anno,'')),
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
                    and capitolo.ente_proprietario_id=p_ente_prop_id   		
                    and capitolo.bil_id= bilancio_id		
                    and programma_tipo.classif_tipo_code='PROGRAMMA'	
                    and macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'	                     							                    	
                    and tipo_elemento.elem_tipo_code = elemTipoCode			                     			                    
                    and stato_capitolo.elem_stato_code	=	'VA'				
                    and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')                    
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
         importi_stanz as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_ug_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno_competenza
                        and a.tipo_imp=TipoImpComp -- ''STA''
                        and a.utente=user_table
                        group by  a.elem_id),
         importi_cassa as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_ug_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno_competenza
                        and a.tipo_imp=TipoImpCassa -- ''SCA''
                        and a.utente=user_table
                        group by  a.elem_id),
         importi_residui as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_ug_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno_competenza
                        and a.tipo_imp=TipoImpRes -- ''STR''
                        and a.utente=user_table
                        group by  a.elem_id),
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
                        where a.ente_proprietario =p_ente_prop_id                        and a.tipologia='''||TipoImpRes||''' -- ''STR''
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
            COALESCE(importi_stanz.importo_cap,0)::numeric stanziamento,
            COALESCE(importi_cassa.importo_cap,0)::numeric cassa,
            COALESCE(importi_residui.importo_cap,0)::numeric residuo,
            COALESCE(variaz_stanz_pos.importo_var,0)::numeric variazione_aumento_stanziato,
            COALESCE(variaz_stanz_neg.importo_var *-1,0)::numeric variazione_diminuzione_stanziato,
            COALESCE(variaz_cassa_pos.importo_var,0)::numeric variazione_aumento_cassa,
            COALESCE(variaz_cassa_neg.importo_var *-1,0)::numeric variazione_diminuzione_cassa,
            COALESCE(variaz_residui_pos.importo_var,0)::numeric variazione_aumento_residuo,
            COALESCE(variaz_residui_neg.importo_var *-1,0)::numeric variazione_diminuzione_residuo,
            ''::varchar display_error		                                        
         from strutt_bilancio
         	LEFT JOIN capitoli
            	ON (strutt_bilancio.programma_id = capitoli.programma_id
                	and strutt_bilancio.macroag_id = capitoli.macroaggregato_id)
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
          where exists (select 1 from siac_r_class_fam_tree aa,
        				capitoli bb,
                        siac_rep_cap_ug_imp cc
        			where bb.elem_id =cc.elem_id
                    	and bb.macroaggregato_id = aa.classif_id
                 		and aa.classif_id_padre = strutt_bilancio.titusc_id 
                        and bb.programma_id=strutt_bilancio.programma_id
                        and cc.utente=user_table);
                	
    
raise notice 'Fine query finale - %' , clock_timestamp()::text;

delete from siac_rep_cap_ug_imp where utente=user_table;
delete from siac_rep_var_spese where utente=user_table;



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
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$function$
;

CREATE OR REPLACE FUNCTION siac."BILR024_Allegato_7_Allegato_delibera_variazione_su_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
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
  stanziamento numeric,
  cassa numeric,
  residuo numeric,
  variazione_aumento_stanziato numeric,
  variazione_diminuzione_stanziato numeric,
  variazione_aumento_cassa numeric,
  variazione_diminuzione_cassa numeric,
  variazione_aumento_residuo numeric,
  variazione_diminuzione_residuo numeric,
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
display_error:='';

contaParametriParz:=0;
contaParametri:=0;

/* 06/12/2019. SIAC-7226.
	Procedura rivista nell'ottica di ottimizzarla.
    Sono usate 2 tabelle di appoggio per il calcolo degli importi dei capitoli
    (siac_rep_cap_eg_imp) e per l'elenco dell variazioni (siac_rep_var_entrate)
    perche' i parametri in input cambiano e le query devono essere cosatruite
    dinamicamente.
    In particolare la query dei capitoli e' piu' complessa perche' nel calcolo
    degli importi deve tenere conto delle variazioni definitive che sono state inserite
    in momenti successivi alle variazioni in input.
    Gli importi delle variazioni successive devono essere decrementati dagli importi
    di stanziamento, cassa e residuo.

*/

--SIAC-6163: 16/05/2018.
-- Introdotti il paramentro p_ele_variazioni  con l'elenco delle 
-- variazioni.
-- Introdotti i controlli sui parametri.
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

if contaParametriParz = 1 OR contaParametriParz = 2 then
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
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
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN    
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;


select fnc_siac_random_user()
into	user_table;

select a.bil_id 
	into bilancio_id 
from siac_t_bil a,siac_t_periodo b
where b.periodo_id=a.periodo_id
	and a.ente_proprietario_id=p_ente_prop_id 
	and b.anno=p_anno;
    
raise notice '1 - %' , clock_timestamp()::text;

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

raise notice 'Fine query importi capitoli - % - Inizio query variazioni' , clock_timestamp()::text;

--Caricamento degli importi delle variazioni. 
--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
if p_numero_delibera IS NOT NULL THEN
    insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),        
            tipo_elemento.elem_det_tipo_code, 
            user_table utente,
            atto.ente_proprietario_id	      	
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
            siac_t_bil					t_bil,
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
    and 	t_bil.periodo_id 									=	anno_eserc.periodo_id		
    and 	t_bil.bil_id 										= testata_variazione.bil_id
    and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id	
    and 	atto.ente_proprietario_id 							= 	p_ente_prop_id 
    and		atto.attoamm_numero 								= 	p_numero_delibera
    and		atto.attoamm_anno									=	p_anno_delibera
    and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
    and		stato_atto.attoamm_stato_code						=	'DEFINITIVO'	
    and		anno_importi.anno									= 	annoCapImp
    and		anno_eserc.anno	= 	p_anno										
 	and		tipologia_stato_var.variazione_stato_tipo_code		=	'D'
    and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
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
    and		t_bil.data_cancellazione					is null
    group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                atto.ente_proprietario_id;
else 
	strQuery:='
    insert into siac_rep_var_entrate
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),        
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
        testata_variazione.ente_proprietario_id	      	
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
	-- 27/04:2017 l''anno di esercizio deve essere collegato a siac_t_bil									
	--and		anno_eserc.periodo_id 								=	testata_variazione.periodo_id								
and 	testata_variazione.ente_proprietario_id	=	'||p_ente_prop_id||'
and		anno_eserc.anno	= 	'''||p_anno||''' 										
and 	testata_variazione.variazione_num in('||p_ele_variazioni||')
and		anno_importi.anno									= 	'''||annoCapImp||'''
and		tipologia_stato_var.variazione_stato_tipo_code		=	''D''
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
        	testata_variazione.ente_proprietario_id';

raise notice 'query variazioni: %', strQuery;      

execute  strQuery;       
     
end if;     
           
return query 
with strutt_bilancio as (select *
        		from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id,p_anno,'')),
		capitoli as (select cl.classif_id categoria_id,
              p_anno anno_bilancio,
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
            and capitolo.ente_proprietario_id	=	p_ente_prop_id
            and capitolo.bil_id					=   bilancio_id
            and ct.classif_tipo_code				=	'CATEGORIA'           
            and tipo_elemento.elem_tipo_code 	= 	elemTipoCode       
            and	stato_capitolo.elem_stato_code	=	'VA'         
            and	cat_del_capitolo.elem_cat_code	=	'STD'
            and capitolo.data_cancellazione 		is null
            and	r_capitolo_stato.data_cancellazione	is null
            and	r_cat_capitolo.data_cancellazione	is null
            and	rc.data_cancellazione				is null
            and	ct.data_cancellazione 				is null
            and	cl.data_cancellazione 				is null
            and	tipo_elemento.data_cancellazione	is null
            and	stato_capitolo.data_cancellazione 	is null
            and	cat_del_capitolo.data_cancellazione	is null),
    	importi_stanz as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_eg_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno_competenza
                        and a.tipo_imp= TipoImpComp -- ''STA''
                        and a.utente= user_table
                        group by  a.elem_id),
         importi_cassa as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_eg_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno_competenza
                        and a.tipo_imp=TipoImpCassa -- ''SCA''
                        and a.utente=user_table
                        group by  a.elem_id),
         importi_residui as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_eg_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno_competenza
                        and a.tipo_imp=TipoImpRes -- ''STR''
                        and a.utente=user_table
                        group by  a.elem_id),
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
                        where a.ente_proprietario =p_ente_prop_id
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
	select capitoli.anno_bilancio::varchar bil_anno,
          ''::varchar titoloe_tipo_code ,
          strutt_bilancio.classif_tipo_desc1::varchar titoloe_tipo_desc,
          strutt_bilancio.titolo_code::varchar titoloe_code,
          strutt_bilancio.titolo_desc::varchar titoloe_desc,
          ''::varchar tipologia_tipo_code,
          strutt_bilancio.classif_tipo_desc2::varchar tipologia_tipo_desc,
          strutt_bilancio.tipologia_code::varchar tipologia_code,
          strutt_bilancio.tipologia_desc::varchar tipologia_desc,
          ''::varchar categoria_tipo_code,
          strutt_bilancio.classif_tipo_desc3::varchar categoria_tipo_desc,
          strutt_bilancio.categoria_code::varchar categoria_code,
          strutt_bilancio.categoria_desc::varchar categoria_desc,
          capitoli.elem_code::varchar bil_ele_code,
          capitoli.elem_desc::varchar bil_ele_desc,
          capitoli.elem_code2::varchar bil_ele_code2,
          capitoli.elem_desc2::varchar bil_ele_desc2,
          capitoli.elem_id::integer bil_ele_id,
          capitoli.elem_id_padre::integer bil_ele_id_padre,
          COALESCE(importi_stanz.importo_cap,0)::numeric stanziamento,
          COALESCE(importi_cassa.importo_cap,0)::numeric cassa,
          COALESCE(importi_residui.importo_cap,0)::numeric residuo,
            COALESCE(variaz_stanz_pos.importo_var,0)::numeric variazione_aumento_stanziato,
          COALESCE(variaz_stanz_neg.importo_var *-1,0)::numeric variazione_diminuzione_stanziato,
          COALESCE(variaz_cassa_pos.importo_var,0)::numeric variazione_aumento_cassa,
          COALESCE(variaz_cassa_neg.importo_var *-1,0)::numeric variazione_diminuzione_cassa,
          COALESCE(variaz_residui_pos.importo_var,0)::numeric variazione_aumento_residuo,
          COALESCE(variaz_residui_neg.importo_var *-1,0)::numeric variazione_diminuzione_residuo,
           /*       
          1::numeric variazione_aumento_stanziato,
          2::numeric variazione_diminuzione_stanziato,
          3::numeric variazione_aumento_cassa,
          4::numeric variazione_diminuzione_cassa,
          5::numeric variazione_aumento_residuo,
          6::numeric variazione_diminuzione_residuo,*/
          ''::varchar display_error
     from strutt_bilancio
     	LEFT JOIN capitoli 
        	ON strutt_bilancio.categoria_id = capitoli.categoria_id  
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
        where exists (select 1 from siac_r_class_fam_tree aa,
        				capitoli bb,
                        siac_rep_cap_eg_imp cc
        			where bb.elem_id =cc.elem_id
                    	and bb.categoria_id = aa.classif_id
                 		and aa.classif_id_padre = strutt_bilancio.tipologia_id                         
                        and cc.utente=user_table);
              
        
    delete from siac_rep_cap_eg_imp where utente=user_table;
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
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- 03-01-2020    Haitham - Maurizio    SIAC-7311 - FINE

--SIAC-7162 - Maurizio - INIZIO

--MENU' PREVISIONE
--ENTI LOCALI 
insert into   siac_t_azione (
  azione_code,  azione_desc,
  azione_tipo_id,  
  gruppo_azioni_id,  
  urlapplicazione,  nomeprocesso,  nometask ,  verificauo,
  validita_inizio,  validita_fine,  ente_proprietario_id,
  data_creazione,  data_modifica,  data_cancellazione,  login_operazione)
select 'OP-GESREP1-BilPrev-2019', 'Reportistica Bilancio di Previsione 2019 (Enti Locali)',
	(select a.azione_tipo_id from siac_d_azione_tipo a
    	where a.azione_tipo_code='ATTIVITA_SINGOLA'
        	and a.ente_proprietario_id=ente.ente_proprietario_id
            and a.data_cancellazione IS NULL),
    (select b.gruppo_azioni_id from siac_d_gruppo_azioni b
    	where b.gruppo_azioni_code='BIL_CAP_PREV'
        	and b.ente_proprietario_id=ente.ente_proprietario_id
            and b.data_cancellazione IS NULL),
    '/../siacrepapp/azioneRichiesta.do', NULL, NULL , FALSE, 
    now(), NULL, ente.ente_proprietario_id,
    now(), now(), NULL, 'SIAC-7162'
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_azione az
        where az.ente_proprietario_id=ente.ente_proprietario_id
        	and az.azione_code='OP-GESREP1-BilPrev-2019');
            
            
insert into   siac_t_azione (
  azione_code,  azione_desc,
  azione_tipo_id,  
  gruppo_azioni_id,  
  urlapplicazione,  nomeprocesso,  nometask ,  verificauo,
  validita_inizio,  validita_fine,  ente_proprietario_id,
  data_creazione,  data_modifica,  data_cancellazione,  login_operazione)
select 'OP-GESREP1-BilPrev-2020', 'Reportistica Bilancio di Previsione - DM 01.08.2019 (Enti Locali)',
	(select a.azione_tipo_id from siac_d_azione_tipo a
    	where a.azione_tipo_code='ATTIVITA_SINGOLA'
        	and a.ente_proprietario_id=ente.ente_proprietario_id
            and a.data_cancellazione IS NULL),
    (select b.gruppo_azioni_id from siac_d_gruppo_azioni b
    	where b.gruppo_azioni_code='BIL_CAP_PREV'
        	and b.ente_proprietario_id=ente.ente_proprietario_id
            and b.data_cancellazione IS NULL),
    '/../siacrepapp/azioneRichiesta.do', NULL, NULL , FALSE, 
    now(), NULL, ente.ente_proprietario_id,
    now(), now(), NULL, 'SIAC-7162'
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_azione az
        where az.ente_proprietario_id=ente.ente_proprietario_id
        	and az.azione_code='OP-GESREP1-BilPrev-2020');          
  
--REGIONI
insert into   siac_t_azione (
  azione_code,  azione_desc,
  azione_tipo_id,  
  gruppo_azioni_id,  
  urlapplicazione,  nomeprocesso,  nometask ,  verificauo,
  validita_inizio,  validita_fine,  ente_proprietario_id,
  data_creazione,  data_modifica,  data_cancellazione,  login_operazione)
select 'OP-GESREP2-BilPrev-2019', 'Reportistica Bilancio di Previsione 2019 (Regioni)',
	(select a.azione_tipo_id from siac_d_azione_tipo a
    	where a.azione_tipo_code='ATTIVITA_SINGOLA'
        	and a.ente_proprietario_id=ente.ente_proprietario_id
            and a.data_cancellazione IS NULL),
    (select b.gruppo_azioni_id from siac_d_gruppo_azioni b
    	where b.gruppo_azioni_code='BIL_CAP_PREV'
        	and b.ente_proprietario_id=ente.ente_proprietario_id
            and b.data_cancellazione IS NULL),
    '/../siacrepapp/azioneRichiesta.do', NULL, NULL , FALSE, 
    now(), NULL, ente.ente_proprietario_id,
    now(), now(), NULL, 'SIAC-7162'
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_azione az
        where az.ente_proprietario_id=ente.ente_proprietario_id
        	and az.azione_code='OP-GESREP2-BilPrev-2019');
            
            
insert into   siac_t_azione (
  azione_code,  azione_desc,
  azione_tipo_id,  
  gruppo_azioni_id,  
  urlapplicazione,  nomeprocesso,  nometask ,  verificauo,
  validita_inizio,  validita_fine,  ente_proprietario_id,
  data_creazione,  data_modifica,  data_cancellazione,  login_operazione)
select 'OP-GESREP2-BilPrev-2020', 'Reportistica Bilancio di Previsione - DM 01.08.2019 (Regioni)',
	(select a.azione_tipo_id from siac_d_azione_tipo a
    	where a.azione_tipo_code='ATTIVITA_SINGOLA'
        	and a.ente_proprietario_id=ente.ente_proprietario_id
            and a.data_cancellazione IS NULL),
    (select b.gruppo_azioni_id from siac_d_gruppo_azioni b
    	where b.gruppo_azioni_code='BIL_CAP_PREV'
        	and b.ente_proprietario_id=ente.ente_proprietario_id
            and b.data_cancellazione IS NULL),
    '/../siacrepapp/azioneRichiesta.do', NULL, NULL , FALSE, 
    now(), NULL, ente.ente_proprietario_id,
    now(), now(), NULL, 'SIAC-7162'
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_azione az
        where az.ente_proprietario_id=ente.ente_proprietario_id
        	and az.azione_code='OP-GESREP2-BilPrev-2020');          
            
            
update  siac_t_azione
set azione_desc ='Reportistica Bilancio di Previsione 2018 (Enti Locali)',
	data_modifica=now(),
    login_operazione=login_operazione||' - SIAC-7162'
where azione_code = 'OP-GESREP1-BilPrev-2018'
	and azione_desc='Reportistica Bilancio di Previsione - DM 01.08.2019 (Enti Locali)';

update  siac_t_azione
set azione_desc ='Reportistica Bilancio di Previsione 2018 (Regioni)',
	data_modifica=now(),
    login_operazione=login_operazione||' - SIAC-7162'
where azione_code = 'OP-GESREP2-BilPrev-2018'
	and azione_desc='Reportistica Bilancio di Previsione - DM 01.08.2019 (Regioni)';
	
	
--INSERIMENTO DELLA CONFIGURAZIONE DEI RUOLI COPIANDOLI DALLE CARTELLE 2018.	
insert into siac_r_ruolo_op_azione (
ruolo_op_id ,  azione_id ,  validita_inizio,  validita_fine ,
  ente_proprietario_id ,  data_creazione,  data_modifica ,
  data_cancellazione,  login_operazione )
select ruolo.ruolo_op_id, (select azione_id from siac_t_azione a  
				where a.azione_code='OP-GESREP1-BilPrev-2019'
                	and a.ente_proprietario_id=ruolo.ente_proprietario_id
                    and a.data_cancellazione IS NULL), now(), NULL,
       ruolo.ente_proprietario_id, now(), now(),
       NULL, 'SIAC-7162'
from siac_r_ruolo_op_azione ruolo, 
	siac_t_azione az,
    siac_t_ente_proprietario ente
where ruolo.azione_id=az.azione_id
	and ente.ente_proprietario_id=az.ente_proprietario_id
	and az.azione_code='OP-GESREP1-BilPrev-2018'
    and ruolo.data_cancellazione IS NULL
    and ruolo.validita_fine IS NULL
    and az.data_cancellazione IS NULL
    and az.validita_fine IS NULL
    and ente.data_cancellazione IS NULL
    and ente.validita_fine IS NULL 
    and not exists (select 1
    	from siac_r_ruolo_op_azione ruolo1, 
			siac_t_azione az1
		where ruolo1.azione_id=az1.azione_id
        	and az1.azione_code='OP-GESREP1-BilPrev-2019');

insert into siac_r_ruolo_op_azione (
ruolo_op_id ,  azione_id ,  validita_inizio,  validita_fine ,
  ente_proprietario_id ,  data_creazione,  data_modifica ,
  data_cancellazione,  login_operazione )
select ruolo.ruolo_op_id, (select azione_id from siac_t_azione a  
				where a.azione_code='OP-GESREP1-BilPrev-2020'
                	and a.ente_proprietario_id=ruolo.ente_proprietario_id
                    and a.data_cancellazione IS NULL), now(), NULL,
       ruolo.ente_proprietario_id, now(), now(),
       NULL, 'SIAC-7162'
from siac_r_ruolo_op_azione ruolo, 
	siac_t_azione az,
    siac_t_ente_proprietario ente
where ruolo.azione_id=az.azione_id
	and ente.ente_proprietario_id=az.ente_proprietario_id
	and az.azione_code='OP-GESREP1-BilPrev-2018'
    and ruolo.data_cancellazione IS NULL
    and ruolo.validita_fine IS NULL
    and az.data_cancellazione IS NULL
    and az.validita_fine IS NULL
    and ente.data_cancellazione IS NULL
    and ente.validita_fine IS NULL 
    and not exists (select 1
    	from siac_r_ruolo_op_azione ruolo1, 
			siac_t_azione az1
		where ruolo1.azione_id=az1.azione_id
        	and az1.azione_code='OP-GESREP1-BilPrev-2020'); 

			
                    
insert into siac_r_ruolo_op_azione (
ruolo_op_id ,  azione_id ,  validita_inizio,  validita_fine ,
  ente_proprietario_id ,  data_creazione,  data_modifica ,
  data_cancellazione,  login_operazione )
select ruolo.ruolo_op_id, (select azione_id from siac_t_azione a  
				where a.azione_code='OP-GESREP2-BilPrev-2019'
                	and a.ente_proprietario_id=ruolo.ente_proprietario_id
                    and a.data_cancellazione IS NULL), now(), NULL,
       ruolo.ente_proprietario_id, now(), now(),
       NULL, 'SIAC-7162'
from siac_r_ruolo_op_azione ruolo, 
	siac_t_azione az,
    siac_t_ente_proprietario ente
where ruolo.azione_id=az.azione_id
	and ente.ente_proprietario_id=az.ente_proprietario_id
	and az.azione_code='OP-GESREP2-BilPrev-2018'
    and ruolo.data_cancellazione IS NULL
    and ruolo.validita_fine IS NULL
    and az.data_cancellazione IS NULL
    and az.validita_fine IS NULL
    and ente.data_cancellazione IS NULL
    and ente.validita_fine IS NULL 
    and not exists (select 1
    	from siac_r_ruolo_op_azione ruolo1, 
			siac_t_azione az1
		where ruolo1.azione_id=az1.azione_id
        	and az1.azione_code='OP-GESREP2-BilPrev-2019');

insert into siac_r_ruolo_op_azione (
ruolo_op_id ,  azione_id ,  validita_inizio,  validita_fine ,
  ente_proprietario_id ,  data_creazione,  data_modifica ,
  data_cancellazione,  login_operazione )
select ruolo.ruolo_op_id, (select azione_id from siac_t_azione a  
				where a.azione_code='OP-GESREP2-BilPrev-2020'
                	and a.ente_proprietario_id=ruolo.ente_proprietario_id
                    and a.data_cancellazione IS NULL), now(), NULL,
       ruolo.ente_proprietario_id, now(), now(),
       NULL, 'SIAC-7162'
from siac_r_ruolo_op_azione ruolo, 
	siac_t_azione az,
    siac_t_ente_proprietario ente
where ruolo.azione_id=az.azione_id
	and ente.ente_proprietario_id=az.ente_proprietario_id
	and az.azione_code='OP-GESREP2-BilPrev-2018'
    and ruolo.data_cancellazione IS NULL
    and ruolo.validita_fine IS NULL
    and az.data_cancellazione IS NULL
    and az.validita_fine IS NULL
    and ente.data_cancellazione IS NULL
    and ente.validita_fine IS NULL 
    and not exists (select 1
    	from siac_r_ruolo_op_azione ruolo1, 
			siac_t_azione az1
		where ruolo1.azione_id=az1.azione_id
        	and az1.azione_code='OP-GESREP2-BilPrev-2020');             
            	
				
--MENU' GESTIONE
--ENTI LOCALI
insert into   siac_t_azione (
  azione_code,  azione_desc,
  azione_tipo_id,  
  gruppo_azioni_id,  
  urlapplicazione,  nomeprocesso,  nometask ,  verificauo,
  validita_inizio,  validita_fine,  ente_proprietario_id,
  data_creazione,  data_modifica,  data_cancellazione,  login_operazione)
select 'OP-GESREP1-BilCons-2019', 'Reportistica Gestione 2019 (Enti Locali)',
	(select a.azione_tipo_id from siac_d_azione_tipo a
    	where a.azione_tipo_code='ATTIVITA_SINGOLA'
        	and a.ente_proprietario_id=ente.ente_proprietario_id
            and a.data_cancellazione IS NULL),
    (select b.gruppo_azioni_id from siac_d_gruppo_azioni b
    	where b.gruppo_azioni_code='BIL_CAP_GES'
        	and b.ente_proprietario_id=ente.ente_proprietario_id
            and b.data_cancellazione IS NULL),
    '/../siacrepapp/azioneRichiesta.do', NULL, NULL , FALSE, 
    now(), NULL, ente.ente_proprietario_id,
    now(), now(), NULL, 'SIAC-7162'
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_azione az
        where az.ente_proprietario_id=ente.ente_proprietario_id
        	and az.azione_code='OP-GESREP1-BilCons-2019');
            
            
insert into   siac_t_azione (
  azione_code,  azione_desc,
  azione_tipo_id,  
  gruppo_azioni_id,  
  urlapplicazione,  nomeprocesso,  nometask ,  verificauo,
  validita_inizio,  validita_fine,  ente_proprietario_id,
  data_creazione,  data_modifica,  data_cancellazione,  login_operazione)
select 'OP-GESREP1-BilCons-2020', 'Reportistica Gestione 2020 (Enti Locali)',
	(select a.azione_tipo_id from siac_d_azione_tipo a
    	where a.azione_tipo_code='ATTIVITA_SINGOLA'
        	and a.ente_proprietario_id=ente.ente_proprietario_id
            and a.data_cancellazione IS NULL),
    (select b.gruppo_azioni_id from siac_d_gruppo_azioni b
    	where b.gruppo_azioni_code='BIL_CAP_GES'
        	and b.ente_proprietario_id=ente.ente_proprietario_id
            and b.data_cancellazione IS NULL),
    '/../siacrepapp/azioneRichiesta.do', NULL, NULL , FALSE, 
    now(), NULL, ente.ente_proprietario_id,
    now(), now(), NULL, 'SIAC-7162'
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_azione az
        where az.ente_proprietario_id=ente.ente_proprietario_id
        	and az.azione_code='OP-GESREP1-BilCons-2020');         
  
--REGIONI
insert into   siac_t_azione (
  azione_code,  azione_desc,
  azione_tipo_id,  
  gruppo_azioni_id,  
  urlapplicazione,  nomeprocesso,  nometask ,  verificauo,
  validita_inizio,  validita_fine,  ente_proprietario_id,
  data_creazione,  data_modifica,  data_cancellazione,  login_operazione)
select 'OP-GESREP2-BilCons-2019', 'Reportistica Gestione 2019 (Regione)',
	(select a.azione_tipo_id from siac_d_azione_tipo a
    	where a.azione_tipo_code='ATTIVITA_SINGOLA'
        	and a.ente_proprietario_id=ente.ente_proprietario_id
            and a.data_cancellazione IS NULL),
    (select b.gruppo_azioni_id from siac_d_gruppo_azioni b
    	where b.gruppo_azioni_code='BIL_CAP_GES'
        	and b.ente_proprietario_id=ente.ente_proprietario_id
            and b.data_cancellazione IS NULL),
    '/../siacrepapp/azioneRichiesta.do', NULL, NULL , FALSE, 
    now(), NULL, ente.ente_proprietario_id,
    now(), now(), NULL, 'SIAC-7162'
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_azione az
        where az.ente_proprietario_id=ente.ente_proprietario_id
        	and az.azione_code='OP-GESREP2-BilCons-2019');
            
insert into   siac_t_azione (
  azione_code,  azione_desc,
  azione_tipo_id,  
  gruppo_azioni_id,  
  urlapplicazione,  nomeprocesso,  nometask ,  verificauo,
  validita_inizio,  validita_fine,  ente_proprietario_id,
  data_creazione,  data_modifica,  data_cancellazione,  login_operazione)
select 'OP-GESREP2-BilCons-2020', 'Reportistica Gestione 2020 (Regione)',
	(select a.azione_tipo_id from siac_d_azione_tipo a
    	where a.azione_tipo_code='ATTIVITA_SINGOLA'
        	and a.ente_proprietario_id=ente.ente_proprietario_id
            and a.data_cancellazione IS NULL),
    (select b.gruppo_azioni_id from siac_d_gruppo_azioni b
    	where b.gruppo_azioni_code='BIL_CAP_GES'
        	and b.ente_proprietario_id=ente.ente_proprietario_id
            and b.data_cancellazione IS NULL),
    '/../siacrepapp/azioneRichiesta.do', NULL, NULL , FALSE, 
    now(), NULL, ente.ente_proprietario_id,
    now(), now(), NULL, 'SIAC-7162'
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_azione az
        where az.ente_proprietario_id=ente.ente_proprietario_id
        	and az.azione_code='OP-GESREP2-BilCons-2020');         
            
            
update  siac_t_azione
set azione_desc ='Reportistica Gestione 2018 (Enti Locali)',
	data_modifica=now(),
    login_operazione=login_operazione||' - SIAC-7162'
where azione_code = 'OP-GESREP1-BilCons-2018'
	and data_cancellazione is null;

update  siac_t_azione
set azione_desc ='Reportistica Gestione 2018 (Regione)',
	data_modifica=now(),
    login_operazione=login_operazione||' - SIAC-7162'
where azione_code = 'OP-GESREP2-BilCons-2018'
	and data_cancellazione is NULL;
	
	
--INSERIMENTO DELLA CONFIGURAZIONE DEI RUOLI COPIANDOLI DALLE CARTELLE 2018.	
insert into siac_r_ruolo_op_azione (
ruolo_op_id ,  azione_id ,  validita_inizio,  
  ente_proprietario_id ,  data_creazione,  data_modifica ,
  login_operazione )
select ruolo.ruolo_op_id, (select azione_id from siac_t_azione a  
				where a.azione_code='OP-GESREP1-BilCons-2019'
                	and a.ente_proprietario_id=ruolo.ente_proprietario_id
                    and a.data_cancellazione IS NULL), now(), 
       ruolo.ente_proprietario_id, now(), now(),
       'SIAC-7162'
from siac_r_ruolo_op_azione ruolo, 
	siac_t_azione az,
    siac_t_ente_proprietario ente
where ruolo.azione_id=az.azione_id
	and ente.ente_proprietario_id=az.ente_proprietario_id
	and az.azione_code='OP-GESREP1-BilCons-2018'
    and ruolo.data_cancellazione IS NULL
    and ruolo.validita_fine IS NULL
    and az.data_cancellazione IS NULL
    and az.validita_fine IS NULL
    and ente.data_cancellazione IS NULL
    and ente.validita_fine IS NULL 
    and not exists (select 1
    	from siac_r_ruolo_op_azione ruolo1, 
			siac_t_azione az1
		where ruolo1.azione_id=az1.azione_id
        	and az1.azione_code='OP-GESREP1-BilCons-2019');
            
            
insert into siac_r_ruolo_op_azione (
ruolo_op_id ,  azione_id ,  validita_inizio,  
  ente_proprietario_id ,  data_creazione,  data_modifica ,
  login_operazione )
select distinct ruolo.ruolo_op_id, (select azione_id from siac_t_azione a  
				where a.azione_code='OP-GESREP1-BilCons-2020'
                	and a.ente_proprietario_id=ruolo.ente_proprietario_id
                    and a.data_cancellazione IS NULL), now(), 
       ruolo.ente_proprietario_id, now(), now(),
       'SIAC-7162'
from siac_r_ruolo_op_azione ruolo, 
	siac_t_azione az,
    siac_t_ente_proprietario ente
where ruolo.azione_id=az.azione_id
	and ente.ente_proprietario_id=az.ente_proprietario_id
	and az.azione_code='OP-GESREP1-BilCons-2018'
    and ruolo.data_cancellazione IS NULL
    and ruolo.validita_fine IS NULL
    and az.data_cancellazione IS NULL
    and az.validita_fine IS NULL
    and ente.data_cancellazione IS NULL
    and ente.validita_fine IS NULL
    and not exists (select 1
    	from siac_r_ruolo_op_azione ruolo1, 
			siac_t_azione az1
		where ruolo1.azione_id=az1.azione_id
        	and az1.azione_code='OP-GESREP1-BilCons-2020');  
     
           
                      
insert  into siac_r_ruolo_op_azione (
ruolo_op_id ,  azione_id ,  validita_inizio,  
  ente_proprietario_id ,  data_creazione,  data_modifica ,
  login_operazione )
select distinct ruolo.ruolo_op_id, (select azione_id from siac_t_azione a  
				where a.azione_code='OP-GESREP2-BilCons-2019'
                	and a.ente_proprietario_id=ruolo.ente_proprietario_id
                    and a.data_cancellazione IS NULL), now(), 
       ruolo.ente_proprietario_id, now(), now(),
       'SIAC-7162'
from siac_r_ruolo_op_azione ruolo, 
	siac_t_azione az,
    siac_t_ente_proprietario ente
where ruolo.azione_id=az.azione_id
	and ente.ente_proprietario_id=az.ente_proprietario_id
	and az.azione_code='OP-GESREP2-BilCons-2018'
    and ruolo.data_cancellazione IS NULL
    and ruolo.validita_fine IS NULL
    and az.data_cancellazione IS NULL
    and az.validita_fine IS NULL
    and ente.data_cancellazione IS NULL
    and ente.validita_fine IS NULL
    and not exists (select 1
    	from siac_r_ruolo_op_azione ruolo1, 
			siac_t_azione az1
		where ruolo1.azione_id=az1.azione_id
        	and az1.azione_code='OP-GESREP2-BilCons-2019');
            
          

insert into siac_r_ruolo_op_azione (
ruolo_op_id ,  azione_id ,  validita_inizio,  
  ente_proprietario_id ,  data_creazione,  data_modifica ,
  login_operazione )
select distinct ruolo.ruolo_op_id, (select azione_id from siac_t_azione a  
				where a.azione_code='OP-GESREP2-BilCons-2020'
                	and a.ente_proprietario_id=ruolo.ente_proprietario_id
                    and a.data_cancellazione IS NULL), now(), 
       ruolo.ente_proprietario_id, now(), now(),
       'SIAC-7162'
from siac_r_ruolo_op_azione ruolo, 
	siac_t_azione az,
    siac_t_ente_proprietario ente
where ruolo.azione_id=az.azione_id
	and ente.ente_proprietario_id=az.ente_proprietario_id
	and az.azione_code='OP-GESREP2-BilCons-2018'
    and ruolo.data_cancellazione IS NULL
    and ruolo.validita_fine IS NULL
    and az.data_cancellazione IS NULL
    and az.validita_fine IS NULL
    and ente.data_cancellazione IS NULL
    and ente.validita_fine IS NULL
    and not exists (select 1
    	from siac_r_ruolo_op_azione ruolo1, 
			siac_t_azione az1
		where ruolo1.azione_id=az1.azione_id
        	and az1.azione_code='OP-GESREP2-BilCons-2020');         
            	
		

--SIAC-7162 - Maurizio - INIZIO

--SIAC 7271 - INIZIO
--elimino i vecchi record sulla tabella
delete from siac_t_elaborazioni_attive where data_creazione < (now() - '1 week'::interval);
-- se ci fossero delle elaborazioni iniziate prima dello spegnimento del server, le invalido (i processi che le hanno generate sono ormai morti) indicando la morivazione
update siac_t_elaborazioni_attive set data_cancellazione = now(), validita_fine = now(), login_operazione = login_operazione || ' - riavvio del server' where data_cancellazione is null;
--SIAC-7271 - FINE
--SIAC-7327 - INIZIO
select * from fnc_dba_add_fk_constraint('siac_t_prima_nota', 'siac_t_soggetto_siac_t_prima_nota_fk', 'soggetto_id', 'siac_t_soggetto', 'soggetto_id');
--siac-7327 - FINE


-- SIAC-7320 - Sofia 17.01.2020  - Inizio


select fnc_dba_add_column_params ('siac_dwh_programma_cronop',  'programma_cronop_stato_code',  'VARCHAR(200)');
select fnc_dba_add_column_params ('siac_dwh_programma_cronop',  'programma_cronop_stato_desc',  'VARCHAR(500)');

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
      programma_cronop_descr_entrata,
      -- siac-7320 sofia 17.01.2020
      programma_cronop_stato_code,
      programma_cronop_stato_desc
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
        else ''::varchar end) programma_cronop_descr_entrata,
      -- siac-7320 sofia 17.01.2020
      query.programma_cronop_stato_code,
      query.programma_cronop_stato_desc
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
                  cronop_elem.cronop_elem_id,
                  stato.cronop_stato_code programma_cronop_stato_code, -- 14.01.2020 Sofia SIAC-7320
                  stato.cronop_stato_desc  programma_cronop_stato_desc  -- 14.01.2020 Sofia SIAC-7320
           from siac_t_cronop cronop,siac_r_cronop_stato rs, siac_d_cronop_stato stato,
                siac_t_bil bil, siac_t_periodo per_bil,
                siac_t_periodo per,
                siac_t_cronop_elem cronop_elem,
                siac_d_bil_elem_tipo tipo,
                siac_t_cronop_elem_det cronop_elem_det
           where stato.ente_proprietario_id=p_ente_proprietario_id
--           and   stato.cronop_stato_code='VA' 14.01.2020 Sofia jira siac-7320
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
                 cronop_atto_amm.cronop_desc_cdc_atto_amm,
                 ce.programma_cronop_stato_code, -- 14.01.2020 Sofia SIAC-7320
                 ce.programma_cronop_stato_desc  -- 14.01.2020 Sofia SIAC-7320
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
              cronop_elem.cronop_elem_id,
              stato.cronop_stato_code programma_cronop_stato_code, -- 14.01.2020 Sofia SIAC-7320
              stato.cronop_stato_desc  programma_cronop_stato_desc  -- 14.01.2020 Sofia SIAC-7320
       from siac_t_cronop cronop,siac_r_cronop_stato rs, siac_d_cronop_stato stato,
            siac_t_bil bil, siac_t_periodo per_bil,
            siac_t_periodo per,
            siac_t_cronop_elem cronop_elem,
            siac_d_bil_elem_tipo tipo,
            siac_t_cronop_elem_det cronop_elem_det
       where stato.ente_proprietario_id=p_ente_proprietario_id
--       and   stato.cronop_stato_code='VA'  14.01.2020 Sofia jira siac-7320
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
            cronop_atto_amm.cronop_desc_cdc_atto_amm,
            ce.programma_cronop_stato_code, -- 14.01.2020 Sofia SIAC-7320
            ce.programma_cronop_stato_desc -- 14.01.2020 Sofia SIAC-7320
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
            cronop_entrata.cronop_desc_cdc_atto_amm,
            cronop_entrata.programma_cronop_stato_code, -- 14.01.2020 Sofia SIAC-7320
            cronop_entrata.programma_cronop_stato_desc -- 14.01.2020 Sofia SIAC-7320
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
            cronop_uscita.cronop_desc_cdc_atto_amm,
            cronop_uscita.programma_cronop_stato_code, -- 14.01.2020 Sofia SIAC-7320
            cronop_uscita.programma_cronop_stato_desc -- 14.01.2020 Sofia SIAC-7320
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
           cronop_progr.cronop_desc_cdc_atto_amm,
           cronop_progr.programma_cronop_stato_code, -- 14.01.2020 Sofia SIAC-7320
           cronop_progr.programma_cronop_stato_desc -- 14.01.2020 Sofia SIAC-7320
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

-- SIAC-7320 - Sofia 17.01.2020  - Fine 


-- SIAC-7291 - Maurizio - INIZIO

--configurazione XBRL report BILR007
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR007', 'ant_liq_spese', 'QGEN_SpeseTitolo4_CP-FAL', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-7291', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR007'
		and xbrl_mapfat_variabile='ant_liq_spese');	
        
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR007', 'ant_liq_spese1', 'QGEN_SpeseTitolo4_CP-FAL', NULL, 
   NULL, 'd_anno/anno_bilancio*1//', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-7291', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR007'
		and xbrl_mapfat_variabile='ant_liq_spese1');	
                
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR007', 'ant_liq_spese2', 'QGEN_SpeseTitolo4_CP-FAL', NULL, 
   NULL, 'd_anno/anno_bilancio*2//', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-7291', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR007'
		and xbrl_mapfat_variabile='ant_liq_spese2');	        

--configurazione XBRL report BILR006
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR006', 'ant_liq_spese', 'QGEN_SpeseTitolo4_CP-FAL', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-7291', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR006'
		and xbrl_mapfat_variabile='ant_liq_spese');	
        
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR006', 'ant_liq_spese1', 'QGEN_SpeseTitolo4_CP-FAL', NULL, 
   NULL, 'd_anno/anno_bilancio*1//', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-7291', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR006'
		and xbrl_mapfat_variabile='ant_liq_spese1');	
                
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR006', 'ant_liq_spese2', 'QGEN_SpeseTitolo4_CP-FAL', NULL, 
   NULL, 'd_anno/anno_bilancio*2//', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-7291', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR006'
		and xbrl_mapfat_variabile='ant_liq_spese2');
		
--INSERISCO la nuova variabile di_cui_fondo_ant_liq_spese
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'di_cui_fondo_ant_liq_spese',
        'Rimborso prestiti - di cui Utilizzo Fondo anticipazioni di liquidita'' (DL 35/2013 e successive modifiche e rifinanziamenti)',
        0,
        'N',
        21,  
        t_bil.bil_id,
        t_periodo_imp.periodo_id,
        now(),
        null,
        t_bil.ente_proprietario_id,
        now(),
        now(),
        null,
        'siac-7291'
from  siac_t_bil t_bil, siac_t_ente_proprietario ente,
siac_t_periodo t_periodo_bil, siac_d_periodo_tipo d_per_tipo_bil,
siac_t_periodo t_periodo_imp, siac_d_periodo_tipo d_per_tipo_imp
where t_bil.periodo_id = t_periodo_bil.periodo_id
and d_per_tipo_bil.periodo_tipo_id=t_periodo_bil.periodo_tipo_id
and t_periodo_imp.ente_proprietario_id=t_periodo_bil.ente_proprietario_id
and d_per_tipo_imp.periodo_tipo_id=t_periodo_imp.periodo_tipo_id
and t_bil.ente_proprietario_id=ente.ente_proprietario_id
and t_periodo_bil.anno = '2018' --anno bilancio
and d_per_tipo_bil.periodo_tipo_code='SY'
and t_periodo_imp.anno in( '2018', '2019','2020')   --anno importo
and d_per_tipo_imp.periodo_tipo_code='SY'
and t_bil.data_cancellazione is null
and ente.data_cancellazione is null
and t_periodo_bil.data_cancellazione is null
and d_per_tipo_bil.data_cancellazione is null
and t_periodo_imp.data_cancellazione is null
and d_per_tipo_imp.data_cancellazione is null
and not exists (select 1
	from siac_t_report_importi a
    where a.repimp_codice =  'di_cui_fondo_ant_liq_spese'
    	and a.bil_id = t_bil.bil_id
        and a.periodo_id = t_periodo_imp.periodo_id
        and a.ente_proprietario_id = ente.ente_proprietario_id
        and a.data_cancellazione IS NULL);    
		
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'di_cui_fondo_ant_liq_spese',
        'Rimborso prestiti - di cui Utilizzo Fondo anticipazioni di liquidita'' (DL 35/2013 e successive modifiche e rifinanziamenti)',
        0,
        'N',
        21,  
        t_bil.bil_id,
        t_periodo_imp.periodo_id,
        now(),
        null,
        t_bil.ente_proprietario_id,
        now(),
        now(),
        null,
        'siac-7291'
from  siac_t_bil t_bil, siac_t_ente_proprietario ente,
siac_t_periodo t_periodo_bil, siac_d_periodo_tipo d_per_tipo_bil,
siac_t_periodo t_periodo_imp, siac_d_periodo_tipo d_per_tipo_imp
where t_bil.periodo_id = t_periodo_bil.periodo_id
and d_per_tipo_bil.periodo_tipo_id=t_periodo_bil.periodo_tipo_id
and t_periodo_imp.ente_proprietario_id=t_periodo_bil.ente_proprietario_id
and d_per_tipo_imp.periodo_tipo_id=t_periodo_imp.periodo_tipo_id
and t_bil.ente_proprietario_id=ente.ente_proprietario_id
and t_periodo_bil.anno = '2019' --anno bilancio
and d_per_tipo_bil.periodo_tipo_code='SY'
and t_periodo_imp.anno in( '2019', '2020','2021')   --anno importo
and d_per_tipo_imp.periodo_tipo_code='SY'
and t_bil.data_cancellazione is null
and ente.data_cancellazione is null
and t_periodo_bil.data_cancellazione is null
and d_per_tipo_bil.data_cancellazione is null
and t_periodo_imp.data_cancellazione is null
and d_per_tipo_imp.data_cancellazione is null
and not exists (select 1
	from siac_t_report_importi a
    where a.repimp_codice =  'di_cui_fondo_ant_liq_spese'
    	and a.bil_id = t_bil.bil_id
        and a.periodo_id = t_periodo_imp.periodo_id
        and a.ente_proprietario_id = ente.ente_proprietario_id
        and a.data_cancellazione IS NULL);      
        
        
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'di_cui_fondo_ant_liq_spese',
        'Rimborso prestiti - di cui Fondo anticipazioni di liquidita''',
        0,
        'N',
        21,  
        t_bil.bil_id,
        t_periodo_imp.periodo_id,
        now(),
        null,
        t_bil.ente_proprietario_id,
        now(),
        now(),
        null,
        'siac-7291'
from  siac_t_bil t_bil, siac_t_ente_proprietario ente,
siac_t_periodo t_periodo_bil, siac_d_periodo_tipo d_per_tipo_bil,
siac_t_periodo t_periodo_imp, siac_d_periodo_tipo d_per_tipo_imp
where t_bil.periodo_id = t_periodo_bil.periodo_id
and d_per_tipo_bil.periodo_tipo_id=t_periodo_bil.periodo_tipo_id
and t_periodo_imp.ente_proprietario_id=t_periodo_bil.ente_proprietario_id
and d_per_tipo_imp.periodo_tipo_id=t_periodo_imp.periodo_tipo_id
and t_bil.ente_proprietario_id=ente.ente_proprietario_id
and t_periodo_bil.anno = '2020' --anno bilancio
and d_per_tipo_bil.periodo_tipo_code='SY'
and t_periodo_imp.anno in ('2020','2021','2022')   --anno importo
and d_per_tipo_imp.periodo_tipo_code='SY'
and t_bil.data_cancellazione is null
and ente.data_cancellazione is null
and t_periodo_bil.data_cancellazione is null
and d_per_tipo_bil.data_cancellazione is null
and t_periodo_imp.data_cancellazione is null
and d_per_tipo_imp.data_cancellazione is null
and not exists (select 1
	from siac_t_report_importi a
    where a.repimp_codice =  'di_cui_fondo_ant_liq_spese'
    	and a.bil_id = t_bil.bil_id
        and a.periodo_id = t_periodo_imp.periodo_id
        and a.ente_proprietario_id = ente.ente_proprietario_id
        and a.data_cancellazione IS NULL);      
        

--Legame con il report BILR007.
INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select t_report.rep_id
from   siac_t_report t_report
where t_report.rep_codice = 'BILR007'
  and t_report.ente_proprietario_id = t_report_imp.ente_proprietario_id
  and t_report.data_cancellazione IS NULL) rep_id,
t_report_imp.repimp_id,
1 posizione_stampa,
now() validita_inizio,
null validita_fine,
t_report_imp.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'siac-7291' login_operazione
from   siac_t_report_importi t_report_imp
where  t_report_imp.repimp_codice = 'di_cui_fondo_ant_liq_spese'
	and t_report_imp.data_cancellazione IS NULL
    and not exists (select 1
    		from siac_r_report_importi a,
            	siac_t_report b
            where a.rep_id=b.rep_id
            	and a.repimp_id = t_report_imp.repimp_id
            	and a.ente_proprietario_id =t_report_imp.ente_proprietario_id
                and b.rep_codice ='BILR007'
                and a.data_cancellazione IS NULL
                and b.data_cancellazione IS NULL);	
                


--per il report BILR006 inserisco lo stesso legame con l'importo di_cui_fondo_ant_liq_spese del report BILR007.
INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select t_report.rep_id
from   siac_t_report t_report
where t_report.rep_codice = 'BILR006'
  and t_report.ente_proprietario_id = t_report_imp.ente_proprietario_id
  and t_report.data_cancellazione IS NULL) rep_id,
r_report_imp.repimp_id,
1 posizione_stampa,
now() validita_inizio,
null validita_fine,
t_report_imp.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'siac-7291' login_operazione
from siac_t_report t_rep,
	siac_t_report_importi t_report_imp,
	siac_r_report_importi r_report_imp
where t_rep.rep_id=r_report_imp.rep_id
	and t_report_imp.repimp_id=r_report_imp.repimp_id
	and t_rep.rep_codice='BILR007'
	and t_report_imp.repimp_codice = 'di_cui_fondo_ant_liq_spese'
    and t_rep.data_cancellazione IS NULL 
    and t_report_imp.data_cancellazione IS NULL
    and r_report_imp.data_cancellazione IS NULL
    and not exists (select 1
    		from siac_r_report_importi aa,
            	siac_t_report bb
            where aa.rep_id=bb.rep_id
            	and aa.repimp_id = t_report_imp.repimp_id
            	and aa.ente_proprietario_id =t_report_imp.ente_proprietario_id
                and bb.rep_codice ='BILR006'
                and aa.data_cancellazione IS NULL
                and bb.data_cancellazione IS NULL)
    and exists (select 1
    		from siac_t_report aaa
            where aaa.ente_proprietario_id =t_report_imp.ente_proprietario_id
            	and aaa.rep_codice ='BILR006') ;	


--aggiorno la descrizione della variabile di_cui_ant_liq del BILR007
update siac_t_report_importi
set repimp_desc='Utilizzo avanzo presunto di amministrazione - di cui Utilizzo Fondo anticipazioni di liquidità (DL 35/2013 e successive modifiche e rifinanziamenti)',
	data_modifica = now(),
    login_operazione = login_operazione || ' - siac-7291'
where repimp_codice='di_cui_ant_liq'
	and repimp_desc <> 'Utilizzo avanzo presunto di amministrazione - di cui Utilizzo Fondo anticipazioni di liquidità (DL 35/2013 e successive modifiche e rifinanziamenti)'
	and bil_id in (select a.bil_id
    	from siac_t_bil a,
        	siac_t_periodo b
        where a.periodo_id = b.periodo_id    
            and b.anno in ('2018','2019')
            and a.data_cancellazione IS NULL
            and b.data_cancellazione IS NULL)
	and repimp_id in (select repimp_id
    	from siac_t_report c,
            siac_r_report_importi d            
        where c.rep_id=d.rep_id
            and c.rep_codice ='BILR007'
            and c.data_cancellazione IS NULL
            and d.data_cancellazione IS NULL);
            
update siac_t_report_importi
set repimp_desc='Utilizzo avanzo presunto di amministrazione - di cui Utilizzo Fondo anticipazioni di liquidita''',
	data_modifica = now(),
    login_operazione = login_operazione || ' - siac-7291'
where repimp_codice='di_cui_ant_liq'
	and repimp_desc <> 'Utilizzo avanzo presunto di amministrazione - di cui Utilizzo Fondo anticipazioni di liquidita'''
	and bil_id in (select a.bil_id
    	from siac_t_bil a,
        	siac_t_periodo b
        where a.periodo_id = b.periodo_id    
            and b.anno in ('2020')
            and a.data_cancellazione IS NULL
            and b.data_cancellazione IS NULL)
	and repimp_id in (select repimp_id
    	from siac_t_report c,
            siac_r_report_importi d            
        where c.rep_id=d.rep_id
            and c.rep_codice ='BILR007'
            and c.data_cancellazione IS NULL
            and d.data_cancellazione IS NULL);            
  
                    
insert into bko_t_report_importi(
rep_codice,  rep_desc,  repimp_codice,  repimp_desc,
  repimp_importo,  repimp_modificabile,  repimp_progr_riga)
SELECT DISTINCT t_rep.rep_codice, t_rep.rep_desc, t_report_imp.repimp_codice,  
		t_report_imp.repimp_desc, 0, t_report_imp.repimp_modificabile,
        t_report_imp.repimp_progr_riga   
    from siac_t_report t_rep,
        siac_t_report_importi t_report_imp,
        siac_r_report_importi r_report_imp,
        siac_t_bil t_bil,
        siac_t_periodo t_periodo
    where t_rep.rep_id=r_report_imp.rep_id
        and t_report_imp.repimp_id=r_report_imp.repimp_id
        and t_report_imp.bil_id=t_bil.bil_id
        and t_bil.periodo_id=t_periodo.periodo_id
        and t_rep.rep_codice in('BILR006','BILR007')
        and t_report_imp.repimp_codice = 'di_cui_fondo_ant_liq_spese'
        and t_periodo.anno in('2020')
        and t_rep.data_cancellazione IS NULL 
        and t_report_imp.data_cancellazione IS NULL  
		and not exists (select 1
            from bko_t_report_importi bko
            where bko.rep_codice = t_rep.rep_codice
               and bko.repimp_codice=  t_report_imp.repimp_codice) ;   
               			   
-- SIAC-7291 - Maurizio - FINE


-- SIAC-7278 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR093_elenco_capitoli_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_tipo_capitolo varchar,
  p_tipo varchar
)
RETURNS TABLE (
  nome_ente varchar,
  bil_anno varchar,
  tipo_capitolo_pg varchar,
  anno_capitolo integer,
  cod_capitolo varchar,
  cod_articolo varchar,
  ueb varchar,
  descr_capitolo varchar,
  descr_articolo varchar,
  cod_titolo varchar,
  descr_titolo varchar,
  cod_tipologia varchar,
  descr_tipologia varchar,
  cod_categoria varchar,
  descr_categoria varchar,
  siope varchar,
  descr_strutt_amm varchar,
  tipo_capitolo varchar,
  accertabile varchar,
  cassa_anno numeric,
  cassa_anno1 numeric,
  cassa_anno2 numeric,
  cassa_iniz_anno numeric,
  cassa_iniz_anno1 numeric,
  cassa_iniz_anno2 numeric,
  residuo_anno numeric,
  residuo_anno1 numeric,
  residuo_anno2 numeric,
  residuo_iniz_anno numeric,
  residuo_iniz_anno1 numeric,
  residuo_iniz_anno2 numeric,
  stanziamento_anno numeric,
  stanziamento_anno1 numeric,
  stanziamento_anno2 numeric,
  stanziamento_iniz_anno numeric,
  stanziamento_iniz_anno1 numeric,
  stanziamento_iniz_anno2 numeric,
  pdc_finanziario varchar,
  disp_stanz_anno numeric,
  disp_stanz_anno1 numeric,
  disp_stanz_anno2 numeric
) AS
$body$
DECLARE
classifBilRec record;
elencoAttrib	record;
elencoClass	record;
elencoDispon  record;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO 		varchar(1000):=DEF_NULL;
user_table			varchar;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;

annoCapImp_int integer;

TipoImpstanz varchar;
tipoImpCassa varchar;
TipoImpResiduo varchar;

TipoImpstanzresiduiIniz varchar;
tipoImpCassaIniz varchar;
TipoImpstanzIniz varchar;	

sett_code varchar;
sett_descr varchar;
classif_id_padre integer;
direz_code	varchar;
direz_descr varchar;
v_fam_titolotipologiacategoria varchar:='00003';
ente_prop varchar;
bilancio_id integer;

BEGIN

  annoCapImp_int:= p_anno::integer; 
  annoCapImp:= p_anno;
  annoCapImp1:= (annoCapImp_int+1) ::varchar;
  annoCapImp2:= (annoCapImp_int+2) ::varchar;
   
/* METTERE ANCHE GLI IMPORTI GIA' SPESI (DA CALCOLARE)

*/

	TipoImpstanz='STA'; 		-- stanziamento  (CP)
    TipoImpCassa ='SCA'; 		----- cassa	(CS)
    TipoImpResiduo='STR';	-- stanziamento residuo
        
    TipoImpstanzresiduiIniz='SRI'; 	-- stanziamento residuo iniziale (RS)
    tipoImpCassaIniz='SCI';			--Stanziamento Cassa Iniziale
    TipoImpstanzIniz='STI';			--Stanziamento  Iniziale

	nome_ente='';
    bil_anno='';
    tipo_capitolo_pg='';    
    anno_capitolo=0;
    cod_capitolo='';
    cod_articolo='';
    ueb='';
    descr_capitolo='';
    descr_articolo='';
    cod_tipologia='';
    descr_tipologia='';
    cod_categoria='';
    descr_categoria='';
    cod_titolo='';
    descr_titolo='';
    siope='';

    descr_strutt_amm='';
    tipo_capitolo='';
    accertabile='';
	cassa_anno=0;
    cassa_anno1=0;
    cassa_anno2=0;
    cassa_iniz_anno=0;	
    cassa_iniz_anno1=0;		
    cassa_iniz_anno2=0;	
    residuo_anno=0;	
    residuo_anno1=0;
    residuo_anno2=0;
    residuo_iniz_anno=0;
    residuo_iniz_anno1=0;
    residuo_iniz_anno2=0;
    stanziamento_anno=0;
    stanziamento_anno1=0;
    stanziamento_anno2=0;
    stanziamento_iniz_anno=0;
    stanziamento_iniz_anno1=0;
    stanziamento_iniz_anno2=0;
    pdc_finanziario='';
    disp_stanz_anno=0;
    disp_stanz_anno1=0;
    disp_stanz_anno2=0;    
    
    /* il parametro p_tipo indica se dal report e' stata richiesta la
    	visualizzazione di:
        - S - Spese;
        - E - Entrate;
        - T - Tutti.
        Nel caso siano richieste solo le spese, questa procedura non
        esegue alcuna estrazione, visto che la relativa tabella
        nel report non sara' visualizzata */
    if p_tipo = 'S' THEN
    	return;
    end if;
    
    select fnc_siac_random_user()
	into	user_table;
	
SELECT a.ente_denominazione
	into ente_prop
from siac_t_ente_proprietario a
where a.ente_proprietario_id = p_ente_prop_id
	and a.data_cancellazione IS NULL;
    
select bilancio.bil_id 
	into bilancio_id 
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc
where bilancio.periodo_id=anno_eserc.periodo_id
	and bilancio.ente_proprietario_id= p_ente_prop_id
    and anno_eserc.anno = p_anno 
    and bilancio.data_cancellazione IS NULL
    and anno_eserc.data_cancellazione IS NULL;

RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';

raise notice 'Caricamento struttura dei capitoli' ;


--06/09/2016: cambiata la query che carica la struttura di bilancio
--  per motivi prestazionali
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
 
raise notice 'Caricamento dati dei capitoli' ;
insert into siac_rep_cap_entrata_completo
select cl.classif_id,
  p_anno anno_bilancio,
  e.*, user_table utente, pdc.classif_code||' - '||pdc.classif_desc,
  tipo_elemento.elem_tipo_code
 from 	siac_r_bil_elem_class rc,
 		siac_t_bil_elem e,
        siac_d_class_tipo ct,
		siac_t_class cl,
        siac_r_bil_elem_class r_capitolo_pdc,
     	siac_t_class pdc,
     	siac_d_class_tipo pdc_tipo,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_id				=	cl.classif_tipo_id
    and cl.classif_id					=	rc.classif_id 
    and e.bil_id						=	bilancio_id 
    and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
    AND r_capitolo_pdc.classif_id 			= pdc.classif_id
    AND pdc.classif_tipo_id 				= pdc_tipo.classif_tipo_id	
    and e.elem_id 					= 	r_capitolo_pdc.elem_id
    and e.elem_id						=	rc.elem_id 
    and	e.elem_id						=	r_capitolo_stato.elem_id
    and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id 
    and	e.elem_id						=	r_cat_capitolo.elem_id
    and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id   
    and e.ente_proprietario_id=p_ente_prop_id
    and ct.classif_tipo_code			=	'CATEGORIA'    	
    AND	pdc_tipo.classif_tipo_code like 'PDC_%'		
    AND ((p_tipo_capitolo ='T' 
            AND tipo_elemento.elem_tipo_code in ('CAP-EG','CAP-EP')) OR
         (p_tipo_capitolo ='P' AND tipo_elemento.elem_tipo_code ='CAP-EP') OR
         (p_tipo_capitolo ='G' AND tipo_elemento.elem_tipo_code ='CAP-EG'))  
    and	stato_capitolo.elem_stato_code	=	'VA'      
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
    and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now());



-- SIAC-7278: 14/01/2020.
--	Aggiunti anche i capitoli che non hanno la classificazione.
insert into siac_rep_cap_entrata_completo
select NULL,
  p_anno anno_bilancio,
  e.*, user_table utente,
  case when COALESCE(classif_pdce.classif_code,'') = '' then ''
  	else classif_pdce.classif_code||' - '||classif_pdce.classif_desc end,
  tipo_elemento.elem_tipo_code
 from 	siac_t_bil_elem e
 		left join (select r_capitolo_pdc.elem_id,
        			pdc.classif_code, pdc.classif_desc
                  from siac_r_bil_elem_class r_capitolo_pdc,
                    siac_t_class pdc,
                    siac_d_class_tipo pdc_tipo
                  where r_capitolo_pdc.classif_id = pdc.classif_id
    					AND pdc.classif_tipo_id  = pdc_tipo.classif_tipo_id	
                        and r_capitolo_pdc.ente_proprietario_id = p_ente_prop_id
                        AND	pdc_tipo.classif_tipo_code like 'PDC_%'	
                        and r_capitolo_pdc.data_cancellazione IS NULL
                        and pdc.data_cancellazione IS NULL
                        and pdc_tipo.data_cancellazione IS NULL) classif_pdce                        
       		on e.elem_id = classif_pdce.elem_id ,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where e.elem_tipo_id					=	tipo_elemento.elem_tipo_id     
    and	e.elem_id						=	r_capitolo_stato.elem_id
    and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id 
    and	e.elem_id						=	r_cat_capitolo.elem_id
    and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id   
    and e.ente_proprietario_id 			=	p_ente_prop_id 	
    and e.bil_id						=	bilancio_id     	
    AND ((p_tipo_capitolo ='T' 
            AND tipo_elemento.elem_tipo_code in ('CAP-EG','CAP-EP')) OR
         (p_tipo_capitolo ='P' AND tipo_elemento.elem_tipo_code ='CAP-EP') OR
         (p_tipo_capitolo ='G' AND tipo_elemento.elem_tipo_code ='CAP-EG'))  
    and	stato_capitolo.elem_stato_code	=	'VA'   
    and e.data_cancellazione 				is null
    and	r_capitolo_stato.data_cancellazione	is null
    and	r_cat_capitolo.data_cancellazione	is null
    and	tipo_elemento.data_cancellazione	is null
    and	stato_capitolo.data_cancellazione 	is null
    and	cat_del_capitolo.data_cancellazione	is null
    and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
    and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
    and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
    and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
    and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
    and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
    and e.elem_id not in (select a.elem_id
    		from siac_rep_cap_entrata_completo a
            where a.ente_proprietario_id = p_ente_prop_id
            	and a.utente= user_table);  
                
                
RTN_MESSAGGIO:='Caricamento importi dei capitoli ''.';

raise notice 'Caricamento importi dei capitoli' ;
insert into siac_rep_cap_ep_imp 
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo)                    
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id 	=	p_ente_prop_id  
        and	anno_eserc.anno							= 	p_anno 												
    	and	bilancio.periodo_id						=	anno_eserc.periodo_id 								
        and	capitolo.bil_id							=	bilancio.bil_id 			 
        and	capitolo.elem_id						=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id					=	tipo_elemento.elem_tipo_id 						
        and ((p_tipo_capitolo ='T' 
        --SIAC-7268: per errore erano caricati gli importi dei capitoli di spesa.
              AND tipo_elemento.elem_tipo_code in ('CAP-EG','CAP-EP')) OR
           (p_tipo_capitolo ='P' AND tipo_elemento.elem_tipo_code ='CAP-EP') OR
           (p_tipo_capitolo ='G' AND tipo_elemento.elem_tipo_code ='CAP-EG'))         
        and	capitolo_importi.elem_det_tipo_id		=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp,annoCapImp1,annoCapImp2)
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		
		--and	cat_del_capitolo.elem_cat_code	=	'STD'								
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
    	and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
    	and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
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
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;   
    
raise notice 'Caricamento importi per riga dei capitoli' ;    
insert into siac_rep_cap_entrata_imp_completo_riga
select  tb1.elem_id,      
    	coalesce (tb1.importo,0)   as 		residuo_anno,
        coalesce (tb2.importo,0)   as 		stanziamento_anno,
        coalesce (tb3.importo,0)   as 		cassa_anno,
        coalesce (tb4.importo,0)   as 		residuo_anno_ini,
        coalesce (tb5.importo,0)   as 		residuo_iniz_anno,
        coalesce (tb6.importo,0)   as 		cassa_iniz_anno,
        coalesce (tb7.importo,0)   as 		residuo_anno1,
        coalesce (tb8.importo,0)   as 		stanziamento_anno1,
        coalesce (tb9.importo,0)   as 		cassa_anno1,
        coalesce (tb10.importo,0)   as 		residuo_anno_ini1,
        coalesce (tb11.importo,0)   as 		residuo_iniz_anno1,
        coalesce (tb12.importo,0)   as 		cassa_iniz_anno1,
        coalesce (tb13.importo,0)   as 		residuo_anno2,
        coalesce (tb14.importo,0)   as 		stanziamento_anno2,
        coalesce (tb15.importo,0)   as 		cassa_anno2,
        coalesce (tb16.importo,0)   as 		residuo_anno_ini2,
        coalesce (tb17.importo,0)   as 		residuo_iniz_anno2,
        coalesce (tb18.importo,0)   as 		cassa_iniz_anno2,
        tb1.ente_proprietario,
       user_table utente 
       --SIAC-7268 per la tabella tb1 era erroneamente usata la siac_rep_cap_up_imp
from 	siac_rep_cap_ep_imp tb1, siac_rep_cap_ep_imp tb2, siac_rep_cap_ep_imp tb3,
		siac_rep_cap_ep_imp tb4, siac_rep_cap_ep_imp tb5, siac_rep_cap_ep_imp tb6,
        siac_rep_cap_ep_imp tb7, siac_rep_cap_ep_imp tb8, siac_rep_cap_ep_imp tb9,
        siac_rep_cap_ep_imp tb10, siac_rep_cap_ep_imp tb11, siac_rep_cap_ep_imp tb12,
        siac_rep_cap_ep_imp tb13, siac_rep_cap_ep_imp tb14, siac_rep_cap_ep_imp tb15,
        siac_rep_cap_ep_imp tb16, siac_rep_cap_ep_imp tb17, siac_rep_cap_ep_imp tb18        
         where		tb1.elem_id	=	tb2.elem_id	and
        			tb2.elem_id	=	tb3.elem_id AND
                    tb3.elem_id	=	tb4.elem_id AND
                    tb4.elem_id	=	tb5.elem_id AND
                    tb5.elem_id	=	tb6.elem_id AND
                    tb6.elem_id	=	tb7.elem_id	and
        			tb7.elem_id	=	tb8.elem_id AND
                    tb8.elem_id	=	tb9.elem_id AND
                    tb9.elem_id	=	tb10.elem_id AND
                    tb10.elem_id	=	tb11.elem_id AND
                    tb11.elem_id	=	tb12.elem_id AND
                    tb12.elem_id	=	tb13.elem_id AND
                    tb13.elem_id	=	tb14.elem_id AND
                    tb14.elem_id	=	tb15.elem_id AND
                    tb15.elem_id	=	tb16.elem_id AND
                    tb16.elem_id	=	tb17.elem_id AND
                    tb17.elem_id	=	tb18.elem_id AND                                  
        			tb1.periodo_anno in (annoCapImp)		AND	tb1.tipo_imp =	TipoImpResiduo	AND
        			tb2.periodo_anno = tb1.periodo_anno	AND	tb2.tipo_imp = 	TipoImpstanz		AND
        			tb3.periodo_anno = tb1.periodo_anno	AND	tb3.tipo_imp = 	TipoImpCassa AND
                    tb4.periodo_anno = tb1.periodo_anno		AND	tb4.tipo_imp =	TipoImpstanzresiduiIniz AND
        			tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzIniz	AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	tipoImpCassaIniz AND
                    tb7.periodo_anno in (annoCapImp1)		AND	tb7.tipo_imp =	TipoImpResiduo	AND
        			tb8.periodo_anno = tb7.periodo_anno	AND	tb8.tipo_imp = 	TipoImpstanz		AND
        			tb9.periodo_anno = tb7.periodo_anno	AND	tb9.tipo_imp = 	TipoImpCassa AND
                    tb10.periodo_anno = tb7.periodo_anno	AND	tb10.tipo_imp =	TipoImpstanzresiduiIniz AND
        			tb11.periodo_anno = tb7.periodo_anno	AND	tb11.tipo_imp = 	TipoImpstanzIniz	AND
        			tb12.periodo_anno = tb7.periodo_anno	AND	tb12.tipo_imp = 	tipoImpCassaIniz	AND
                    tb13.periodo_anno in(annoCapImp2)		AND	tb13.tipo_imp =	TipoImpResiduo	AND
        			tb14.periodo_anno = tb13.periodo_anno	AND	tb14.tipo_imp = 	TipoImpstanz		AND
        			tb15.periodo_anno = tb13.periodo_anno	AND	tb15.tipo_imp = 	TipoImpCassa AND
                    tb16.periodo_anno = tb13.periodo_anno	AND	tb16.tipo_imp =	TipoImpstanzresiduiIniz AND
        			tb17.periodo_anno = tb13.periodo_anno	AND	tb17.tipo_imp = 	TipoImpstanzIniz	AND
        			tb18.periodo_anno = tb13.periodo_anno	AND	tb18.tipo_imp = 	tipoImpCassaIniz AND
                    tb1.utente=user_table;


/* estrazione dei dati dei capitoli */

-- SIAC-7278: 14/01/2020.
--	Query rivista per poter estrarre anche i capitoli che non 
-- hanno la classificazione.

 RTN_MESSAGGIO:='estrazione dei dati dalle tabelle di comodo e preparazione dati in output ''.';                
 raise notice 'estrazione dei dati dalle tabelle di comodo e preparazione dati in output' ;
for classifBilRec in
  select 	v1.categoria_code		categoria_code,
  			v1.categoria_desc		categoria_desc,
            v1.tipologia_code		tipologia_code,
            v1.tipologia_desc		tipologia_desc,
            v1.titolo_code			titolo_code,
            v1.titolo_desc			titolo_desc,
          tb.anno_bilancio 				BIL_ANNO,
          tb.elem_code     				BIL_ELE_CODE,
          tb.elem_code2     			BIL_ELE_CODE2,
          tb.elem_code3					BIL_ELE_CODE3,
          tb.elem_desc     				BIL_ELE_DESC,
          tb.elem_desc2     			BIL_ELE_DESC2,
          tb.elem_id      				BIL_ELE_ID,
          tb.elem_id_padre    			BIL_ELE_ID_PADRE,
          tb.pdc						pdc_finanziario,
          COALESCE(tb1.cassa_anno,0)	cassa_anno,
          COALESCE(tb1.cassa_anno1,0)	cassa_anno1,
          COALESCE(tb1.cassa_anno2,0)	cassa_anno2,
          COALESCE(tb1.cassa_iniz_anno,0)	cassa_iniz_anno,	
          COALESCE(tb1.cassa_iniz_anno1,0)	cassa_iniz_anno1,		
          COALESCE(tb1.cassa_iniz_anno2,0)	cassa_iniz_anno2,	
          COALESCE(tb1.residuo_anno,0)		residuo_anno,	
          COALESCE(tb1.residuo_anno1,0)	residuo_anno1,
          COALESCE(tb1.residuo_anno2,0)	residuo_anno2,
          COALESCE(tb1.residuo_iniz_anno,0)	residuo_iniz_anno,
          COALESCE(tb1.residuo_iniz_anno1,0)	residuo_iniz_anno1,
          COALESCE(tb1.residuo_iniz_anno2,0)	residuo_iniz_anno2,
          COALESCE(tb1.stanziamento_anno,0)	stanziamento_anno,
          COALESCE(tb1.stanziamento_anno1,0)	stanziamento_anno1,
          COALESCE(tb1.stanziamento_anno2,0)	stanziamento_anno2,
          COALESCE(tb1.stanziamento_iniz_anno,0)	stanziamento_iniz_anno,
          COALESCE(tb1.stanziamento_iniz_anno1,0)	stanziamento_iniz_anno1,
          COALESCE(tb1.stanziamento_iniz_anno2,0)	stanziamento_iniz_anno2,          
          categ.elem_cat_code, categ.elem_cat_desc,
          ente_prop ente_prop_denom,
          tb.tipo_capitolo, attrib_accert."boolean"
   from   
      siac_rep_tit_tip_cat_riga_anni v1
      	full JOIN siac_rep_cap_entrata_completo tb
        	on(v1.categoria_id = tb.classif_id 
            	and  TB.utente=V1.utente)
        left	join    siac_rep_cap_entrata_imp_completo_riga 	tb1  
           			on tb1.elem_id	=	tb.elem_id
        left join (select r_categoria.elem_id,
        		   d_categoria.elem_cat_code, d_categoria.elem_cat_desc
                    from siac_r_bil_elem_categoria  r_categoria,
                    	siac_d_bil_elem_categoria  d_categoria 
                    where r_categoria.elem_cat_id=  d_categoria.elem_cat_id  
                   		and r_categoria.ente_proprietario_id = p_ente_prop_id            
                          and d_categoria.data_cancellazione IS NULL
                          And r_categoria.data_cancellazione IS NULL) categ
         		on tb.elem_id=categ.elem_id
         left join (SELECT a.elem_id, b.attr_code, a.boolean
                    from siac_r_bil_elem_attr a,
                    	siac_t_attr b
                   where a.attr_id=b.attr_id
                    and a.ente_proprietario_id = p_ente_prop_id
                    and b.attr_code='FlagImpegnabile'
                    and a.data_cancellazione IS NULL
                    and b.data_cancellazione IS NULL) attrib_accert 
             on attrib_accert.elem_id= tb.elem_id  
 where tb.ente_proprietario_id = p_ente_prop_id                      
    and tb.utente = user_table 
    and tb.elem_code IS NOT NULL 
  order by v1.titolo_code,v1.tipologia_code,v1.categoria_code,tb.elem_code::INTEGER,tb.elem_code2::INTEGER            

        
    loop
         
    nome_ente=classifBilRec.ente_prop_denom;
    bil_anno=classifBilRec.BIL_ANNO;
    tipo_capitolo_pg=classifBilRec.tipo_capitolo;
    anno_capitolo=classifBilRec.BIL_ANNO;
    cod_capitolo=classifBilRec.BIL_ELE_CODE;
    cod_articolo=classifBilRec.BIL_ELE_CODE2;
    ueb=classifBilRec.BIL_ELE_CODE3;
    descr_capitolo=classifBilRec.BIL_ELE_DESC;
    descr_articolo=COALESCE(classifBilRec.BIL_ELE_DESC2,'');
	cod_tipologia=COALESCE(classifBilRec.tipologia_code,'');
    descr_tipologia=COALESCE(classifBilRec.tipologia_desc,'');
    cod_categoria=COALESCE(classifBilRec.categoria_code,'');
    descr_categoria=COALESCE(classifBilRec.categoria_desc,'');
    cod_titolo=COALESCE(classifBilRec.titolo_code,'');
    descr_titolo=COALESCE(classifBilRec.titolo_desc,'');
    
    tipo_capitolo=classifBilRec.elem_cat_code||' - '||classifBilRec.elem_cat_desc;
    
    cassa_anno=classifBilRec.cassa_anno;
    cassa_anno1=classifBilRec.cassa_anno1;
    cassa_anno2=classifBilRec.cassa_anno2;
    cassa_iniz_anno=classifBilRec.cassa_iniz_anno;	
    cassa_iniz_anno1=classifBilRec.cassa_iniz_anno1;		
    cassa_iniz_anno2=classifBilRec.cassa_iniz_anno2;	
    residuo_anno=classifBilRec.residuo_anno;	
    residuo_anno1=classifBilRec.residuo_anno1;
    residuo_anno2=classifBilRec.residuo_anno2;
    residuo_iniz_anno=classifBilRec.residuo_iniz_anno;
    residuo_iniz_anno1=classifBilRec.residuo_iniz_anno1;
    residuo_iniz_anno2=classifBilRec.residuo_iniz_anno2;
    stanziamento_anno=classifBilRec.stanziamento_anno;
    stanziamento_anno1=classifBilRec.stanziamento_anno1;
    stanziamento_anno2=classifBilRec.stanziamento_anno2;
    stanziamento_iniz_anno=classifBilRec.stanziamento_iniz_anno;
    stanziamento_iniz_anno1=classifBilRec.stanziamento_iniz_anno1;
    stanziamento_iniz_anno2=classifBilRec.stanziamento_iniz_anno2;
    pdc_finanziario=classifBilRec.pdc_finanziario;
    accertabile:=COALESCE(classifBilRec."boolean",''); 
        
  		/* cerco gli elementi di tipo classe per il SIOPE ENTRATA */
    select case when COALESCE(t_class.classif_code,'') = '' then ''
    else t_class.classif_code||' - '||t_class.classif_desc end
    into siope
    from 
     siac_t_class t_class,
     siac_d_class_tipo d_class_tipo,
     siac_r_bil_elem_class r_bil_elem_class
    where  d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
        and r_bil_elem_class.classif_id=t_class.classif_id
        and r_bil_elem_class.elem_id=classifBilRec.BIL_ELE_ID
        and substr(d_class_tipo.classif_tipo_code,1,13) ='SIOPE_ENTRATA'
        and r_bil_elem_class.data_cancellazione IS NULL
        and t_class.data_cancellazione IS NULL
        and d_class_tipo.data_cancellazione IS NULL;

        
    /* cerco la struttura amministrativa */
	BEGIN    
          SELECT   t_class.classif_code, t_class.classif_desc, r_class_fam_tree.classif_id_padre 
          INTO sett_code, sett_descr, classif_id_padre      
              from siac_r_bil_elem_class r_bil_elem_class,
                  siac_r_class_fam_tree r_class_fam_tree,
                  siac_t_class			t_class,
                  siac_d_class_tipo		d_class_tipo ,
                  siac_t_bil_elem    		capitolo               
          where 
              r_bil_elem_class.elem_id 			= 	capitolo.elem_id
              and t_class.classif_id 					= 	r_bil_elem_class.classif_id
              and t_class.classif_id 					= 	r_class_fam_tree.classif_id
              and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
             AND d_class_tipo.classif_tipo_desc='Cdc(Settore)'
              and capitolo.elem_id=classifBilRec.BIL_ELE_ID
               AND r_bil_elem_class.data_cancellazione is NULL
               AND t_class.data_cancellazione is NULL
               AND d_class_tipo.data_cancellazione is NULL
               AND capitolo.data_cancellazione is NULL
               and r_class_fam_tree.data_cancellazione is NULL;    
                                
              IF NOT FOUND THEN
                  /* se il settore non esiste restituisco un codice fittizio
                      e cerco se esiste la direzione */
                  sett_code='';
                  sett_descr='';
              
                BEGIN
                SELECT  t_class.classif_code, t_class.classif_desc
                    INTO direz_code, direz_descr
                    from siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class			t_class,
                        siac_d_class_tipo		d_class_tipo ,
                        siac_t_bil_elem    		capitolo               
                where 
                    r_bil_elem_class.elem_id 			= 	capitolo.elem_id
                    and t_class.classif_id 					= 	r_bil_elem_class.classif_id
                    and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id          
                   and d_class_tipo.classif_tipo_code='CDR'
                    and capitolo.elem_id=classifBilRec.BIL_ELE_ID
                     AND r_bil_elem_class.data_cancellazione is NULL
                     AND t_class.data_cancellazione is NULL
                     AND d_class_tipo.data_cancellazione is NULL
                     AND capitolo.data_cancellazione is NULL;	
               IF NOT FOUND THEN
                  /* se non esiste la direzione restituisco un codice fittizio */
                direz_code='';
                direz_descr='';         
                END IF;
            END;
              
         ELSE
              /* cerco la direzione con l'ID padre del settore */
           BEGIN
            SELECT  t_class.classif_code, t_class.classif_desc
                INTO direz_code, direz_descr
            from siac_t_class t_class
            where t_class.classif_id= classif_id_padre;
            IF NOT FOUND THEN
              direz_code='';
              direz_descr='';  
            END IF;
            END;
              
          END IF;
          
      
      if direz_code <> '' THEN
      	descr_strutt_amm = direz_code||' - ' ||direz_descr;
      else 
      	descr_strutt_amm='';
      end if;
      
      if sett_code <> '' THEN
      	descr_strutt_amm = descr_strutt_amm || ' - ' || sett_code ||' - ' ||sett_descr;
      end if;
     END;   
     
     IF tipo_capitolo_pg = 'CAP-EG' THEN
     -- raise notice 'ora: % ',clock_timestamp()::varchar;
     --raise notice 'ricerca della disponibilita' per ID capitolo % ',classifBilRec.BIL_ELE_ID;		
      BEGIN
        for elencoDispon in
            SELECT * 
            FROM fnc_siac_disponibilitaaccertareeg_3anni(classifBilRec.BIL_ELE_ID)
        loop
            IF elencoDispon.annocompetenza = annoCapImp  THEN
                disp_stanz_anno=elencoDispon.dispaccertare;
            elsif elencoDispon.annocompetenza = annoCapImp1 THEN
                disp_stanz_anno1=elencoDispon.dispaccertare;
            elsif elencoDispon.annocompetenza = annoCapImp2 THEN
                disp_stanz_anno2=elencoDispon.dispaccertare;
            end if;
            
        end loop;
      END;
          
     -- raise notice 'ora: % ',clock_timestamp()::varchar;
    else
        disp_stanz_anno=0;
    	disp_stanz_anno1=0;
    	disp_stanz_anno2=0;
    end if;           
      
      
      
    return next;
    
   	nome_ente='';
    bil_anno='';
    tipo_capitolo_pg='';    
    anno_capitolo=0;
    cod_capitolo='';
    cod_articolo='';
    ueb='';
    descr_capitolo='';
    descr_articolo='';
    cod_tipologia='';
    descr_tipologia='';
    cod_categoria='';
    descr_categoria='';
    cod_titolo='';
    descr_titolo='';
    siope='';
    descr_strutt_amm='';
    tipo_capitolo='';
    accertabile='';
	cassa_anno=0;
    cassa_anno1=0;
    cassa_anno2=0;
    cassa_iniz_anno=0;	
    cassa_iniz_anno1=0;		
    cassa_iniz_anno2=0;	
    residuo_anno=0;	
    residuo_anno1=0;
    residuo_anno2=0;
    residuo_iniz_anno=0;
    residuo_iniz_anno1=0;
    residuo_iniz_anno2=0;
    stanziamento_anno=0;
    stanziamento_anno1=0;
    stanziamento_anno2=0;
    stanziamento_iniz_anno=0;
    stanziamento_iniz_anno1=0;
    stanziamento_iniz_anno2=0;
    pdc_finanziario='';
    disp_stanz_anno=0;
    disp_stanz_anno1=0;
    disp_stanz_anno2=0;    
    
end loop;            
raise notice 'ora: % ',clock_timestamp()::varchar;            

  
  delete from siac_rep_tit_tip_cat_riga_anni 		where utente=user_table;
  delete from siac_rep_cap_entrata_completo			where utente=user_table;
  delete from siac_rep_cap_ep_imp 					where utente=user_table;
  delete from siac_rep_cap_entrata_imp_completo_riga where utente=user_table;	
   
exception
	when no_data_found THEN
		raise notice 'Dati dei capitoli di entrata non trovati.' ;
		--return next;
	when others  THEN
		--raise notice 'errore nella lettura delle prime note ';
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'CAPITOLI',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
RETURNS NULL ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR093_elenco_capitoli_spesa" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_tipo_capitolo varchar,
  p_tipo varchar
)
RETURNS TABLE (
  nome_ente varchar,
  bil_anno varchar,
  tipo_capitolo_pg varchar,
  anno_capitolo integer,
  cod_capitolo varchar,
  cod_articolo varchar,
  ueb varchar,
  descr_capitolo varchar,
  descr_articolo varchar,
  cod_missione varchar,
  descr_missione varchar,
  cod_programma varchar,
  descr_programma varchar,
  cod_titolo varchar,
  descr_titolo varchar,
  cod_cofog varchar,
  descr_cofog varchar,
  cod_macroaggr varchar,
  descr_macroaggr varchar,
  siope varchar,
  descr_strutt_amm varchar,
  tipo_capitolo varchar,
  impegnabile varchar,
  cassa_anno numeric,
  cassa_anno1 numeric,
  cassa_anno2 numeric,
  cassa_iniz_anno numeric,
  cassa_iniz_anno1 numeric,
  cassa_iniz_anno2 numeric,
  residuo_anno numeric,
  residuo_anno1 numeric,
  residuo_anno2 numeric,
  residuo_iniz_anno numeric,
  residuo_iniz_anno1 numeric,
  residuo_iniz_anno2 numeric,
  stanziamento_anno numeric,
  stanziamento_anno1 numeric,
  stanziamento_anno2 numeric,
  stanziamento_iniz_anno numeric,
  stanziamento_iniz_anno1 numeric,
  stanziamento_iniz_anno2 numeric,
  pdc_finanziario varchar,
  disp_stanz_anno numeric,
  disp_stanz_anno1 numeric,
  disp_stanz_anno2 numeric
) AS
$body$
DECLARE
classifBilRec record;
elencoAttrib	record;
elencoClass	record;
elencoDispon record;


DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO 		varchar(1000):=DEF_NULL;
user_table			varchar;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;

annoCapImp_int integer;

TipoImpstanz varchar;
tipoImpCassa varchar;
TipoImpResiduo varchar;

TipoImpstanzresiduiIniz varchar;
tipoImpCassaIniz varchar;
TipoImpstanzIniz varchar;	

sett_code varchar;
sett_descr varchar;
classif_id_padre integer;
direz_code	varchar;
direz_descr varchar;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
ente_prop varchar;
bilancio_id integer;

BEGIN

  annoCapImp_int:= p_anno::integer; 
  annoCapImp:= p_anno;
  annoCapImp1:= (annoCapImp_int+1) ::varchar;
  annoCapImp2:= (annoCapImp_int+2) ::varchar;
   
/* METTERE ANCHE GLI IMPORTI GIA' SPESI (DA CALCOLARE)

*/

	TipoImpstanz='STA'; 		-- stanziamento  (CP)
    TipoImpCassa ='SCA'; 		----- cassa	(CS)
    TipoImpResiduo='STR';	-- stanziamento residuo
    
    
    TipoImpstanzresiduiIniz='SRI'; 	-- stanziamento residuo iniziale (RS)
    tipoImpCassaIniz='SCI';			--Stanziamento Cassa Iniziale
    TipoImpstanzIniz='STI';			--Stanziamento  Iniziale

	nome_ente='';
    bil_anno='';
    tipo_capitolo_pg='';    
    anno_capitolo=0;
    cod_capitolo='';
    cod_articolo='';
    ueb='';
    descr_capitolo='';
    descr_articolo='';
    cod_missione='';
    descr_missione='';
    cod_programma='';
    descr_programma='';
    cod_titolo='';
    descr_titolo='';
    cod_cofog='';
    descr_cofog='';
    cod_macroaggr='';
    descr_macroaggr='';
    siope='';

    descr_strutt_amm='';
    tipo_capitolo='';
    impegnabile='';
	cassa_anno=0;
    cassa_anno1=0;
    cassa_anno2=0;
    cassa_iniz_anno=0;	
    cassa_iniz_anno1=0;		
    cassa_iniz_anno2=0;	
    residuo_anno=0;	
    residuo_anno1=0;
    residuo_anno2=0;
    residuo_iniz_anno=0;
    residuo_iniz_anno1=0;
    residuo_iniz_anno2=0;
    stanziamento_anno=0;
    stanziamento_anno1=0;
    stanziamento_anno2=0;
    stanziamento_iniz_anno=0;
    stanziamento_iniz_anno1=0;
    stanziamento_iniz_anno2=0;
    pdc_finanziario='';
    disp_stanz_anno=0;
    disp_stanz_anno1=0;
    disp_stanz_anno2=0;
        
    
    /* il parametro p_tipo indica se dal report e' stata richiesta la
    	visualizzazione di:
        - S - Spese;
        - E - Entrate;
        - T - Tutti.
        Nel caso siano richieste solo le entrate, questa procedura non
        esegue alcuna estrazione, visto che la relativa tabella
        nel report non sara' visualizzata */
    if p_tipo = 'E' THEN
    	return;
    end if;
        
    select fnc_siac_random_user()
	into	user_table;
	
SELECT a.ente_denominazione
	into ente_prop
from siac_t_ente_proprietario a
where a.ente_proprietario_id = p_ente_prop_id
	and a.data_cancellazione IS NULL;
    
select bilancio.bil_id 
	into bilancio_id 
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc
where bilancio.periodo_id=anno_eserc.periodo_id
	and bilancio.ente_proprietario_id= p_ente_prop_id
    and anno_eserc.anno = p_anno 
    and bilancio.data_cancellazione IS NULL
    and anno_eserc.data_cancellazione IS NULL;

RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'inserimento tabella di comodo STRUTTURA DEL BILANCIO ';


-- 06/09/2016: sostituita la query di caricamento struttura del bilancio
--   per migliorare prestazioni
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
/* 28/09/2016: nei report di utilita' non deve essere inserito 
    	questo filtro */      
 -- , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 06/09/2016: start filtro per mis-prog-macro*/
 --AND programma.programma_id = progmacro.classif_a_id
--AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;
 
RTN_MESSAGGIO:='inserimento tabella di comodo dei capitoli ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'inserimento tabella di comodo dei capitoli  ';

insert into   siac_rep_cap_uscita_completo --siac_rep_cap_up --siac_rep_cap_ug
select 	programma.classif_id,
		macroaggr.classif_id,
        p_anno anno_bilancio,
       	capitolo.*,
        pdc.classif_code||' - '||pdc.classif_desc,
       	user_table utente,
        tipo_elemento.elem_tipo_code
from siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr,
     siac_r_bil_elem_class r_capitolo_pdc,
     siac_t_class pdc,
     siac_d_class_tipo pdc_tipo,
     siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 	
    and programma.classif_tipo_id	=programma_tipo.classif_tipo_id 			
    and programma.classif_id	=r_capitolo_programma.classif_id		
    and macroaggr.classif_tipo_id	=macroaggr_tipo.classif_tipo_id 				
    and macroaggr.classif_id	=r_capitolo_macroaggr.classif_id	
    and capitolo.elem_id=r_capitolo_programma.elem_id							
    and capitolo.elem_id=r_capitolo_macroaggr.elem_id							
    and capitolo.elem_id				=	r_capitolo_stato.elem_id			
	and r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
    and capitolo.elem_id				=	r_cat_capitolo.elem_id				
	and r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id	
    and r_capitolo_pdc.classif_id 			= pdc.classif_id						
  	and pdc.classif_tipo_id 				= pdc_tipo.classif_tipo_id	
    and capitolo.elem_id 					= 	r_capitolo_pdc.elem_id					
    and capitolo.ente_proprietario_id	=	p_ente_prop_id
    and capitolo.bil_id = bilancio_id	  					
 	and ((p_tipo_capitolo ='T' 
        	AND tipo_elemento.elem_tipo_code in ('CAP-UG','CAP-UP')) OR  
  		(p_tipo_capitolo ='P' AND tipo_elemento.elem_tipo_code ='CAP-UP') OR 
  		(p_tipo_capitolo ='G' AND tipo_elemento.elem_tipo_code ='CAP-UG'))  								
	and programma_tipo.classif_tipo_code	='PROGRAMMA' 									    
    and macroaggr_tipo.classif_tipo_code	='MACROAGGREGATO'						
	and stato_capitolo.elem_stato_code	=	'VA'								    		
    --and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC')				
	--and cat_del_capitolo.elem_cat_code	=	'STD'							    					
	and pdc_tipo.classif_tipo_code like 'PDC_%'																		  	
	and programma_tipo.data_cancellazione			is null 	
    and programma.data_cancellazione 				is null 	
    and macroaggr_tipo.data_cancellazione	 		is null 	
    and macroaggr.data_cancellazione 				is null 	
    and tipo_elemento.data_cancellazione 			is null 	
    and r_capitolo_programma.data_cancellazione 	is null 	
    and r_capitolo_macroaggr.data_cancellazione 	is null 	
    and r_capitolo_pdc.data_cancellazione 			is null 	
    and pdc.data_cancellazione 						is null 	
    and pdc_tipo.data_cancellazione 				is null 	
    and stato_capitolo.data_cancellazione 			is null 	 
    and r_capitolo_stato.data_cancellazione 		is null 	
	and cat_del_capitolo.data_cancellazione 		is null 	
    and r_cat_capitolo.data_cancellazione 			is null 	
	and capitolo.data_cancellazione 				is null;    

-- SIAC-7278: 14/01/2020.
--	Aggiunti anche i capitoli che non hanno la classificazione.
insert into   siac_rep_cap_uscita_completo
select  NULL, 
		NULL,
        p_anno anno_bilancio,
       	capitolo.*,
        case when COALESCE(classif_pdce.classif_code,'') = '' then ''
  			else classif_pdce.classif_code||' - '||classif_pdce.classif_desc end,
       	user_table utente,
        tipo_elemento.elem_tipo_code
from siac_t_bil_elem capitolo
        left join (select r_capitolo_pdc.elem_id,
            pdc.classif_code, pdc.classif_desc
          from siac_r_bil_elem_class r_capitolo_pdc,
            siac_t_class pdc,
            siac_d_class_tipo pdc_tipo
          where r_capitolo_pdc.classif_id = pdc.classif_id
                AND pdc.classif_tipo_id  = pdc_tipo.classif_tipo_id	
                and r_capitolo_pdc.ente_proprietario_id = p_ente_prop_id
                AND	pdc_tipo.classif_tipo_code like 'PDC_%'	
                and r_capitolo_pdc.data_cancellazione IS NULL
                and pdc.data_cancellazione IS NULL
                and pdc_tipo.data_cancellazione IS NULL) classif_pdce                        
    	on capitolo.elem_id = classif_pdce.elem_id ,
	 siac_d_bil_elem_tipo tipo_elemento,     
     siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						
    and capitolo.elem_id				=	r_capitolo_stato.elem_id
    and capitolo.elem_id				=	r_cat_capitolo.elem_id				
	and r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
    and stato_capitolo.elem_stato_id 	= 	r_capitolo_stato.elem_stato_id											
    and capitolo.ente_proprietario_id	=	p_ente_prop_id
    and capitolo.bil_id = bilancio_id									 				
 	and (
		(p_tipo_capitolo ='T' 
        	AND tipo_elemento.elem_tipo_code in ('CAP-UG','CAP-UP')) OR  
  		(p_tipo_capitolo ='P' AND tipo_elemento.elem_tipo_code ='CAP-UP') OR 
  		(p_tipo_capitolo ='G' AND tipo_elemento.elem_tipo_code ='CAP-UG'))  														
	and stato_capitolo.elem_stato_code	=	'VA'								  															
    and tipo_elemento.data_cancellazione 			is null 	
    and stato_capitolo.data_cancellazione 			is null 	 
    and r_capitolo_stato.data_cancellazione 		is null 	
	and cat_del_capitolo.data_cancellazione 		is null 	
    and r_cat_capitolo.data_cancellazione 			is null 	
	and capitolo.data_cancellazione 				is null
    and capitolo.elem_id not in (select a.elem_id
    		from siac_rep_cap_uscita_completo a
            where a.ente_proprietario_id=p_ente_prop_id
            	and a.utente= user_table);   
    
RTN_MESSAGGIO:='inserimento tabella di comodo degli importi per capitolo ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'inserimento tabella di comodo degli importi per capitolo ';

insert into siac_rep_cap_up_imp 
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo)                    
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id 	=	p_ente_prop_id  
        and	anno_eserc.anno							= 	p_anno 												
    	and	bilancio.periodo_id						=	anno_eserc.periodo_id 								
        and	capitolo.bil_id							=	bilancio.bil_id 			 
        and	capitolo.elem_id						=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id					=	tipo_elemento.elem_tipo_id 						            
      	and ((p_tipo_capitolo ='T' 
          	AND tipo_elemento.elem_tipo_code in ('CAP-UG','CAP-UP')) OR
     		(p_tipo_capitolo ='P' AND tipo_elemento.elem_tipo_code ='CAP-UP') OR
     		(p_tipo_capitolo ='G' AND tipo_elemento.elem_tipo_code ='CAP-UG'))     
        and	capitolo_importi.elem_det_tipo_id		=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp,annoCapImp1,annoCapImp2)
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		
		--and	cat_del_capitolo.elem_cat_code	=	'STD'								
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
    	and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
    	and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
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
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;
    

raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'inserimento tabella di comodo degli importi per capitolo per riga';    
insert into siac_rep_cap_uscita_imp_completo_riga
select  tb1.elem_id,      
    	coalesce (tb1.importo,0)   as 		residuo_anno,
        coalesce (tb2.importo,0)   as 		stanziamento_anno,
        coalesce (tb3.importo,0)   as 		cassa_anno,
        coalesce (tb4.importo,0)   as 		residuo_anno_ini,
        coalesce (tb5.importo,0)   as 		residuo_iniz_anno,
        coalesce (tb6.importo,0)   as 		cassa_iniz_anno,
        coalesce (tb7.importo,0)   as 		residuo_anno1,
        coalesce (tb8.importo,0)   as 		stanziamento_anno1,
        coalesce (tb9.importo,0)   as 		cassa_anno1,
        coalesce (tb10.importo,0)   as 		residuo_anno_ini1,
        coalesce (tb11.importo,0)   as 		residuo_iniz_anno1,
        coalesce (tb12.importo,0)   as 		cassa_iniz_anno1,
        coalesce (tb13.importo,0)   as 		residuo_anno2,
        coalesce (tb14.importo,0)   as 		stanziamento_anno2,
        coalesce (tb15.importo,0)   as 		cassa_anno2,
        coalesce (tb16.importo,0)   as 		residuo_anno_ini2,
        coalesce (tb17.importo,0)   as 		residuo_iniz_anno2,
        coalesce (tb18.importo,0)   as 		cassa_iniz_anno2,
        tb1.ente_proprietario,
       user_table utente 
from 	siac_rep_cap_up_imp tb1, siac_rep_cap_up_imp tb2, siac_rep_cap_up_imp tb3,
		siac_rep_cap_up_imp tb4, siac_rep_cap_up_imp tb5, siac_rep_cap_up_imp tb6,
        siac_rep_cap_up_imp tb7, siac_rep_cap_up_imp tb8, siac_rep_cap_up_imp tb9,
        siac_rep_cap_up_imp tb10, siac_rep_cap_up_imp tb11, siac_rep_cap_up_imp tb12,
        siac_rep_cap_up_imp tb13, siac_rep_cap_up_imp tb14, siac_rep_cap_up_imp tb15,
        siac_rep_cap_up_imp tb16, siac_rep_cap_up_imp tb17, siac_rep_cap_up_imp tb18        
         where		tb1.elem_id	=	tb2.elem_id	and
        			tb2.elem_id	=	tb3.elem_id AND
                    tb3.elem_id	=	tb4.elem_id AND
                    tb4.elem_id	=	tb5.elem_id AND
                    tb5.elem_id	=	tb6.elem_id AND
                    tb6.elem_id	=	tb7.elem_id	and
        			tb7.elem_id	=	tb8.elem_id AND
                    tb8.elem_id	=	tb9.elem_id AND
                    tb9.elem_id	=	tb10.elem_id AND
                    tb10.elem_id	=	tb11.elem_id AND
                    tb11.elem_id	=	tb12.elem_id AND
                    tb12.elem_id	=	tb13.elem_id AND
                    tb13.elem_id	=	tb14.elem_id AND
                    tb14.elem_id	=	tb15.elem_id AND
                    tb15.elem_id	=	tb16.elem_id AND
                    tb16.elem_id	=	tb17.elem_id AND
                    tb17.elem_id	=	tb18.elem_id AND                                  
        			tb1.periodo_anno in (annoCapImp)		AND	tb1.tipo_imp =	TipoImpResiduo	AND
        			tb2.periodo_anno = tb1.periodo_anno	AND	tb2.tipo_imp = 	TipoImpstanz		AND
        			tb3.periodo_anno = tb1.periodo_anno	AND	tb3.tipo_imp = 	TipoImpCassa AND
                    tb4.periodo_anno = tb1.periodo_anno		AND	tb4.tipo_imp =	TipoImpstanzresiduiIniz AND
        			tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzIniz	AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	tipoImpCassaIniz AND
                    tb7.periodo_anno in (annoCapImp1)		AND	tb7.tipo_imp =	TipoImpResiduo	AND
        			tb8.periodo_anno = tb7.periodo_anno	AND	tb8.tipo_imp = 	TipoImpstanz		AND
        			tb9.periodo_anno = tb7.periodo_anno	AND	tb9.tipo_imp = 	TipoImpCassa AND
                    tb10.periodo_anno = tb7.periodo_anno	AND	tb10.tipo_imp =	TipoImpstanzresiduiIniz AND
        			tb11.periodo_anno = tb7.periodo_anno	AND	tb11.tipo_imp = 	TipoImpstanzIniz	AND
        			tb12.periodo_anno = tb7.periodo_anno	AND	tb12.tipo_imp = 	tipoImpCassaIniz	AND
                    tb13.periodo_anno in(annoCapImp2)		AND	tb13.tipo_imp =	TipoImpResiduo	AND
        			tb14.periodo_anno = tb13.periodo_anno	AND	tb14.tipo_imp = 	TipoImpstanz		AND
        			tb15.periodo_anno = tb13.periodo_anno	AND	tb15.tipo_imp = 	TipoImpCassa AND
                    tb16.periodo_anno = tb13.periodo_anno	AND	tb16.tipo_imp =	TipoImpstanzresiduiIniz AND
        			tb17.periodo_anno = tb13.periodo_anno	AND	tb17.tipo_imp = 	TipoImpstanzIniz	AND
        			tb18.periodo_anno = tb13.periodo_anno	AND	tb18.tipo_imp = 	tipoImpCassaIniz AND
                    tb1.utente=user_table;


/* estrazione dei dati dei capitoli */

 RTN_MESSAGGIO:='estrazione dei dati dalle tabelle di comodo e preparazione dati in output ''.';                
raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'estrazione dei dati dalle tabelle di comodo e preparazione dati in output ';

-- SIAC-7278: 14/01/2020.
--	Query rivista per poter estrarre anche i capitoli che non 
-- hanno la classificazione.
for classifBilRec in
  select 	v1.missione_tipo_desc		missione_tipo_desc,
          v1.missione_code				missione_code,
          v1.missione_desc				missione_desc,
          v1.programma_tipo_desc		programma_tipo_desc,
          v1.programma_code				programma_code,
          v1.programma_desc				programma_desc,
          v1.titusc_tipo_desc			titusc_tipo_desc,
          v1.titusc_code				titusc_code,
          v1.titusc_desc				titusc_desc,
          v1.macroag_tipo_desc			macroag_tipo_desc,
          v1.macroag_code				macroag_code,
          v1.macroag_desc				macroag_desc,
          tb.bil_anno   				BIL_ANNO,
          tb.elem_code     				BIL_ELE_CODE,
          tb.elem_code2     			BIL_ELE_CODE2,
          tb.elem_code3					BIL_ELE_CODE3,
          tb.elem_desc     				BIL_ELE_DESC,
          tb.elem_desc2     			BIL_ELE_DESC2,
          tb.elem_id      				BIL_ELE_ID,
          tb.elem_id_padre    			BIL_ELE_ID_PADRE,
          tb.codice_pdc 				pdc_finanziario,
          COALESCE(tb1.cassa_anno,0)	cassa_anno,
          COALESCE(tb1.cassa_anno1,0)	cassa_anno1,
          COALESCE(tb1.cassa_anno2,0)	cassa_anno2,
          COALESCE(tb1.cassa_iniz_anno,0)	cassa_iniz_anno,	
          COALESCE(tb1.cassa_iniz_anno1,0)	cassa_iniz_anno1,		
          COALESCE(tb1.cassa_iniz_anno2,0)	cassa_iniz_anno2,	
          COALESCE(tb1.residuo_anno,0)		residuo_anno,	
          COALESCE(tb1.residuo_anno1,0)	residuo_anno1,
          COALESCE(tb1.residuo_anno2,0)	residuo_anno2,
          COALESCE(tb1.residuo_iniz_anno,0)	residuo_iniz_anno,
          COALESCE(tb1.residuo_iniz_anno1,0)	residuo_iniz_anno1,
          COALESCE(tb1.residuo_iniz_anno2,0)	residuo_iniz_anno2,
          COALESCE(tb1.stanziamento_anno,0)	stanziamento_anno,
          COALESCE(tb1.stanziamento_anno1,0)	stanziamento_anno1,
          COALESCE(tb1.stanziamento_anno2,0)	stanziamento_anno2,
          COALESCE(tb1.stanziamento_iniz_anno,0)	stanziamento_iniz_anno,
          COALESCE(tb1.stanziamento_iniz_anno1,0)	stanziamento_iniz_anno1,
          COALESCE(tb1.stanziamento_iniz_anno2,0)	stanziamento_iniz_anno2,          
          categ.elem_cat_code, categ.elem_cat_desc,
          ente_prop ente_prop_denom,
          tb.tipo_capitolo, attrib_impegn."boolean"
   from   
      siac_rep_mis_pro_tit_mac_riga_anni v1
      	full join siac_rep_cap_uscita_completo tb
        	on (v1.programma_id = tb.programma_id
            	and v1.macroag_id	= tb.macroaggregato_id
                AND TB.utente=V1.utente
                and tb.elem_code IS NOT NULL)
         left	join    siac_rep_cap_uscita_imp_completo_riga 	tb1  
           			on tb1.elem_id	=	tb.elem_id
          join (select r_categoria.elem_id,
          			d_categoria.elem_cat_code, d_categoria.elem_cat_desc
          		from  siac_r_bil_elem_categoria  r_categoria,
                	  siac_d_bil_elem_categoria  d_categoria
                where r_categoria.elem_cat_id=  d_categoria.elem_cat_id
                	and r_categoria.ente_proprietario_id = p_ente_prop_id   
                    and r_categoria.data_cancellazione IS NULL
                    and d_categoria.data_cancellazione IS NULL) categ  
              on tb.elem_id=categ.elem_id   
         left join (SELECT a.elem_id, b.attr_code, a.boolean
                    from siac_r_bil_elem_attr a,
                    	siac_t_attr b
                   where a.attr_id=b.attr_id
                    and a.ente_proprietario_id = p_ente_prop_id
                    and b.attr_code='FlagImpegnabile'
                    and a.data_cancellazione IS NULL
                    and b.data_cancellazione IS NULL) attrib_impegn  
             on attrib_impegn.elem_id= tb.elem_id                     
 	where  tb.ente_proprietario_id=p_ente_prop_id
           and tb.utente=user_table 
  order by missione_code,programma_code,titusc_code,macroag_code, BIL_ELE_ID

        
    loop
         
    nome_ente=classifBilRec.ente_prop_denom;
    bil_anno=classifBilRec.BIL_ANNO;
    tipo_capitolo_pg=classifBilRec.tipo_capitolo;
    anno_capitolo=classifBilRec.BIL_ANNO;
    cod_capitolo=classifBilRec.BIL_ELE_CODE;
    cod_articolo=classifBilRec.BIL_ELE_CODE2;
    ueb=classifBilRec.BIL_ELE_CODE3;
    descr_capitolo=classifBilRec.BIL_ELE_DESC;
    descr_articolo=COALESCE(classifBilRec.BIL_ELE_DESC2,'');
    cod_missione=COALESCE(classifBilRec.missione_code,'');
    descr_missione=COALESCE(classifBilRec.missione_desc,'');
    cod_programma=COALESCE(classifBilRec.programma_code,'');
    descr_programma=COALESCE(classifBilRec.programma_desc,'');
    cod_titolo=COALESCE(classifBilRec.titusc_code,'');
    descr_titolo=COALESCE(classifBilRec.titusc_desc,'');

    cod_macroaggr=COALESCE(classifBilRec.macroag_code,'');
    descr_macroaggr=COALESCE(classifBilRec.macroag_desc,'');
    
    tipo_capitolo=classifBilRec.elem_cat_code||' - '||classifBilRec.elem_cat_desc;
    
    cassa_anno=classifBilRec.cassa_anno;
    cassa_anno1=classifBilRec.cassa_anno1;
    cassa_anno2=classifBilRec.cassa_anno2;
    cassa_iniz_anno=classifBilRec.cassa_iniz_anno;	
    cassa_iniz_anno1=classifBilRec.cassa_iniz_anno1;		
    cassa_iniz_anno2=classifBilRec.cassa_iniz_anno2;	
    residuo_anno=classifBilRec.residuo_anno;	
    residuo_anno1=classifBilRec.residuo_anno1;
    residuo_anno2=classifBilRec.residuo_anno2;
    residuo_iniz_anno=classifBilRec.residuo_iniz_anno;
    residuo_iniz_anno1=classifBilRec.residuo_iniz_anno1;
    residuo_iniz_anno2=classifBilRec.residuo_iniz_anno2;
    stanziamento_anno=classifBilRec.stanziamento_anno;
    stanziamento_anno1=classifBilRec.stanziamento_anno1;
    stanziamento_anno2=classifBilRec.stanziamento_anno2;
    stanziamento_iniz_anno=classifBilRec.stanziamento_iniz_anno;
    stanziamento_iniz_anno1=classifBilRec.stanziamento_iniz_anno1;
    stanziamento_iniz_anno2=classifBilRec.stanziamento_iniz_anno2;
    pdc_finanziario=classifBilRec.pdc_finanziario;
    impegnabile:=COALESCE(classifBilRec."boolean",'');   
    
    	/* cerco gli elementi di tipo classe */
    BEGIN
    	for elencoClass in 
          select distinct d_class_tipo.*, t_class.*
          from 
           siac_t_class t_class,
           siac_d_class_tipo d_class_tipo,
           siac_r_bil_elem_class r_bil_elem_class
          where  d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
              and r_bil_elem_class.classif_id=t_class.classif_id
              and r_bil_elem_class.ente_proprietario_id = p_ente_prop_id
              and r_bil_elem_class.elem_id=classifBilRec.BIL_ELE_ID
              and (d_class_tipo.classif_tipo_code ='GRUPPO_COFOG' OR
              		substr(d_class_tipo.classif_tipo_code,1,11) ='SIOPE_SPESA')
              and r_bil_elem_class.data_cancellazione IS NULL
              and t_class.data_cancellazione IS NULL
              and d_class_tipo.data_cancellazione IS NULL
        loop
          IF elencoClass.classif_tipo_code ='GRUPPO_COFOG' THEN
          	cod_cofog=elencoClass.classif_code;
    		descr_cofog=elencoClass.classif_desc;
          else  --SIOPE_SPESA
          	siope=elencoClass.classif_code||' - '||elencoClass.classif_desc;
          end if;
          
        end loop;
            
    END;
        
    /* cerco la struttura amministrativa */
	BEGIN    
          SELECT   t_class.classif_code, t_class.classif_desc, r_class_fam_tree.classif_id_padre 
          INTO sett_code, sett_descr, classif_id_padre      
              from siac_r_bil_elem_class r_bil_elem_class,
                  siac_r_class_fam_tree r_class_fam_tree,
                  siac_t_class			t_class,
                  siac_d_class_tipo		d_class_tipo ,
                  siac_t_bil_elem    		capitolo               
          where 
              r_bil_elem_class.elem_id 			= 	capitolo.elem_id
              and t_class.classif_id 					= 	r_bil_elem_class.classif_id
              and t_class.classif_id 					= 	r_class_fam_tree.classif_id
              and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
             AND d_class_tipo.classif_tipo_desc='Cdc(Settore)'
              and capitolo.elem_id=classifBilRec.BIL_ELE_ID
               AND r_bil_elem_class.data_cancellazione is NULL
               AND t_class.data_cancellazione is NULL
               AND d_class_tipo.data_cancellazione is NULL
               AND capitolo.data_cancellazione is NULL
               and r_class_fam_tree.data_cancellazione is NULL;    
                                
              IF NOT FOUND THEN
                  /* se il settore non esiste restituisco un codice fittizio
                      e cerco se esiste la direzione */
                  sett_code='';
                  sett_descr='';
              
                BEGIN
                SELECT  t_class.classif_code, t_class.classif_desc
                    INTO direz_code, direz_descr
                    from siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class			t_class,
                        siac_d_class_tipo		d_class_tipo ,
                        siac_t_bil_elem    		capitolo               
                where 
                    r_bil_elem_class.elem_id 			= 	capitolo.elem_id
                    and t_class.classif_id 					= 	r_bil_elem_class.classif_id
                    and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id          
                   and d_class_tipo.classif_tipo_code='CDR'
                    and capitolo.elem_id=classifBilRec.BIL_ELE_ID
                     AND r_bil_elem_class.data_cancellazione is NULL
                     AND t_class.data_cancellazione is NULL
                     AND d_class_tipo.data_cancellazione is NULL
                     AND capitolo.data_cancellazione is NULL;	
               IF NOT FOUND THEN
                  /* se non esiste la direzione restituisco un codice fittizio */
                direz_code='';
                direz_descr='';         
                END IF;
            END;
              
         ELSE
              /* cerco la direzione con l'ID padre del settore */
           BEGIN
            SELECT  t_class.classif_code, t_class.classif_desc
                INTO direz_code, direz_descr
            from siac_t_class t_class
            where t_class.classif_id= classif_id_padre;
            IF NOT FOUND THEN
              direz_code='';
              direz_descr='';  
            END IF;
            END;
              
          END IF;
       if direz_code <> '' THEN
          descr_strutt_amm = direz_code||' - ' ||direz_descr;
        else 
          descr_strutt_amm='';
        end if;
        
        if sett_code <> '' THEN
          descr_strutt_amm = descr_strutt_amm || ' - ' || sett_code ||' - ' ||sett_descr;
        end if;

      END;   
      
    disp_stanz_anno=0;
    disp_stanz_anno1=0;
    disp_stanz_anno2=0;
      
    return next;
    
    nome_ente='';
    bil_anno='';
    tipo_capitolo_pg='';
    anno_capitolo=0;
    cod_capitolo='';
    cod_articolo='';
    ueb='';
    descr_capitolo='';
    descr_articolo='';
    cod_missione='';
    descr_missione='';
    cod_programma='';
    descr_programma='';
    cod_titolo='';
    descr_titolo='';
    cod_cofog='';
    descr_cofog='';
    cod_macroaggr='';
    descr_macroaggr='';
    siope='';
    descr_strutt_amm='';
    tipo_capitolo='';
    impegnabile='';
	cassa_anno=0;
    cassa_anno1=0;
    cassa_anno2=0;
    cassa_iniz_anno=0;	
    cassa_iniz_anno1=0;		
    cassa_iniz_anno2=0;	
    residuo_anno=0;	
    residuo_anno1=0;
    residuo_anno2=0;
    residuo_iniz_anno=0;
    residuo_iniz_anno1=0;
    residuo_iniz_anno2=0;
    stanziamento_anno=0;
    stanziamento_anno1=0;
    stanziamento_anno2=0;
    stanziamento_iniz_anno=0;
    stanziamento_iniz_anno1=0;
    stanziamento_iniz_anno2=0;
    pdc_finanziario='';
    disp_stanz_anno=0;
    disp_stanz_anno1=0;
    disp_stanz_anno2=0;
    
end loop;            
raise notice 'ora: % ',clock_timestamp()::varchar;            

  
  delete from siac_rep_mis_pro_tit_mac_riga_anni 	where utente=user_table;
  delete from  siac_rep_cap_uscita_completo				where utente=user_table;
  delete from siac_rep_cap_up_imp where utente=user_table;
  delete from siac_rep_cap_uscita_imp_completo_riga where utente=user_table;	
   
exception
	when no_data_found THEN
		raise notice 'Dati dei capitoli non trovati.' ;
		--return next;
	when others  THEN
		--raise notice 'errore nella lettura delle prime note ';
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'CAPITOLI',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
RETURNS NULL ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-7278 - Maurizio - FINE

--SIAC-7360 Inizio
INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, verificauo, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.azione_code, tmp.azione_desc, dat.azione_tipo_id, dga.gruppo_azioni_id, '/../siacbilapp/azioneRichiesta.do', FALSE, now(), dat.ente_proprietario_id, 'admin'
FROM siac_d_azione_tipo dat
JOIN siac_d_gruppo_azioni dga ON (dga.ente_proprietario_id = dat.ente_proprietario_id)
JOIN (VALUES
	('OP-ENT-GestisciModifica', 'Gestisci modifica entrata', 'AZIONE_SECONDARIA', 'FIN_BASE1'),
	('OP-SPE-GestisciModifica', 'Gestisci modifica spesa', 'AZIONE_SECONDARIA', 'FIN_BASE1')	
) AS tmp(azione_code, azione_desc, azione_tipo_code, gruppo_azioni_code) ON (tmp.azione_tipo_code = dat.azione_tipo_code AND tmp.gruppo_azioni_code = dga.gruppo_azioni_code)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_t_azione ta
	WHERE ta.azione_code = tmp.azione_code
	AND ta.ente_proprietario_id = dat.ente_proprietario_id
	AND ta.data_cancellazione IS NULL
);

--SIAC-7360 - fine