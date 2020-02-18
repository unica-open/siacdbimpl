/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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