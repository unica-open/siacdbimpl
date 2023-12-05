/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR253_peg_spese_gestione_variaz" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_code varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_code varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_code varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_code varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_res_anno numeric,
  stanziamento_anno_prec numeric,
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  impegnato_anno numeric,
  impegnato_anno1 numeric,
  impegnato_anno2 numeric,
  num_cap_old varchar,
  num_art_old varchar,
  upb varchar,
  display_error varchar
) AS
$body$
DECLARE

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
TipoImpstanzresidui varchar;
anno_bil_impegni	varchar;
tipo_capitolo	varchar;
h_count integer :=0;
importo integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
bil_elem_id integer;
strQuery varchar;
x_array VARCHAR [];
intApp integer;
strApp varchar;
contaParVarBil integer;

BEGIN

/* 08/06/2021 SIAC-7790.
	Questa Procedura nasce come copia della procedura BILR077_peg_spese_gestione.
    E' stata rivista per motivi prestazionali e sono stati aggiunti i 
    parametri per la gestione delle variazioni, in quanto la jira SIAC-7790
    prevede la creazione di un report identico a BILR077/BIL081 ma che
    tenga conto in modo opzionale i dati delle variazioni in bozza.
*/

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione


anno_bil_impegni:=p_anno;
contaParVarBil:=0;

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    intApp = strApp::INTEGER;
  END LOOP;
END IF;

if p_numero_delibera IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_anno_delibera IS NOT  NULL AND p_anno_delibera <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_tipo_delibera IS NOT  NULL AND p_tipo_delibera <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if contaParVarBil not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione''';
    return next;
    return;        
end if;
strQuery:='';

if contaParVarBil = 3 and (p_ele_variazioni IS NOT NULL 
	AND p_ele_variazioni <> '') then
	display_error='Specificare uno solo tra i parametri ''Elenco numeri Variazione'' e ''Provvedimento di variazione''';
    return next;
    return;        
end if;  

/*
IF (p_ele_variazioni IS  NULL OR p_ele_variazioni = '') AND
	contaParVarBil = 0 AND
    (p_tipo_var IS NULL OR p_tipo_var = '') THEN
    display_error='OCCORRE SPECIFICARE ALMENO 1 PARAMETRO RELATIVO ALLE VARIAZIONI';
    return next;
    return;  
    
end if;*/

strQuery:='';

select fnc_siac_random_user()
into	user_table;

select bil.bil_id
	into bil_elem_id
from siac_t_bil bil,
	siac_t_periodo per
where bil.periodo_id=per.periodo_id
	and bil.ente_proprietario_id=p_ente_prop_id
    and per.anno=p_anno
    and bil.data_cancellazione IS NULL
    and per.data_cancellazione IS NULL;        

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_code='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_code='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_res_anno=0;
stanziamento_anno_prec=0;
stanziamento_prev_cassa_anno=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
impegnato_anno=0;
impegnato_anno1=0;
impegnato_anno2=0;
num_cap_old='';
num_art_old='';
upb='';


--preparo la parte della query relativa alle variazioni.	
if p_numero_delibera is not null THEN        
    insert into siac_rep_var_spese    
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),        
            tipo_elemento.elem_det_tipo_code, 
            user_table utente,
            atto.ente_proprietario_id, anno_importi.anno	      	
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
    --10/10/2022 SIAC-8827  Aggiunto lo stato BD.									
    and		tipologia_stato_var.variazione_stato_tipo_code		 in	('B','G', 'C', 'P', 'BD')
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
                atto.ente_proprietario_id, anno_importi.anno;
ELSE  --specificata la variazione
	if p_ele_variazioni is not null and p_ele_variazioni <>'' then
      strQuery:= '
      insert into siac_rep_var_spese
      select	dettaglio_variazione.elem_id,
          sum(dettaglio_variazione.elem_det_importo),        
          tipo_elemento.elem_det_tipo_code, 
          '''||user_table||''' utente,
          testata_variazione.ente_proprietario_id, anno_importi.anno 	      	
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
          --10/10/2022 SIAC-8827  Aggiunto lo stato BD.
          and		tipologia_stato_var.variazione_stato_tipo_code	 in	(''B'',''G'', ''C'', ''P'', ''BD'') 
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
                      testata_variazione.ente_proprietario_id, anno_importi.anno';                    

      raise notice 'Query variazioni = %', strQuery;
      execute  strQuery;	
    end if;
end if;

return query
with struttura as (
	select * from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, p_anno,'')),
capitoli as (
  select 	programma.classif_id programma_id,
          macroaggr.classif_id macroaggregato_id,
          p_anno anno_bilancio,cat_del_capitolo.elem_cat_code,
          capitolo.*, upb.classif_code capitolo_upb,
          COALESCE(cap_old.num_cap_old,'') num_cap_old, 
          COALESCE(cap_old.num_art_old,'') num_art_old
  from  siac_d_class_tipo programma_tipo,
       siac_t_class programma,
       siac_d_class_tipo macroaggr_tipo,
       siac_t_class macroaggr,
       siac_t_bil_elem capitolo
       	left join (select t_class_upb.classif_code, r_capitolo_upb.elem_id
                    from 
                        siac_d_class_tipo	class_upb,
                        siac_t_class		t_class_upb,
                        siac_r_bil_elem_class r_capitolo_upb
                    where t_class_upb.classif_tipo_id=class_upb.classif_tipo_id 
                        and t_class_upb.classif_id=r_capitolo_upb.classif_id
                        and t_class_upb.ente_proprietario_id = p_ente_prop_id
                        and class_upb.classif_tipo_code='CLASSIFICATORE_1' 									
                        and	class_upb.data_cancellazione 		is null
                        and t_class_upb.data_cancellazione 		is null
                        and r_capitolo_upb.data_cancellazione 	is null) upb
         	on upb.elem_id=capitolo.elem_id
         left join (select r_bil_elem_old.elem_id, 
         				cap.elem_code num_cap_old,
         				cap.elem_code2 num_art_old
         			from siac_r_bil_elem_rel_tempo r_bil_elem_old,
                    	siac_t_bil_elem cap
                    where r_bil_elem_old.elem_id_old=cap.elem_id
                    	and r_bil_elem_old.ente_proprietario_id=p_ente_prop_id
                        and r_bil_elem_old.data_cancellazione IS NULL
                        and cap.data_cancellazione IS NULL) cap_old
         	on cap_old.elem_id=capitolo.elem_id,
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
        and capitolo.elem_id=r_capitolo_programma.elem_id							
      	and capitolo.elem_id=r_capitolo_macroaggr.elem_id
        and capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id
        and  capitolo.elem_id				=	r_capitolo_stato.elem_id
      	and r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
        and capitolo.elem_id				=	r_cat_capitolo.elem_id				
      	and r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
      	and capitolo.ente_proprietario_id = p_ente_prop_id      						
       	and capitolo.bil_id = bil_elem_id
      	and programma_tipo.classif_tipo_code='PROGRAMMA'      					
      	and macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						
      	and tipo_elemento.elem_tipo_code = elemTipoCode						     	       							     		
      	and stato_capitolo.elem_stato_code	=	'VA'
      	and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
        and	now() between programma.validita_inizio and coalesce (programma.validita_fine, now()) 
        and	now() between macroaggr.validita_inizio and coalesce (macroaggr.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between programma_tipo.validita_inizio and coalesce (programma_tipo.validita_fine, now())
        and	now() between macroaggr_tipo.validita_inizio and coalesce (macroaggr_tipo.validita_fine, now())
        and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between r_capitolo_programma.validita_inizio and coalesce (r_capitolo_programma.validita_fine, now())
        and	now() between r_capitolo_macroaggr.validita_inizio and coalesce (r_capitolo_macroaggr.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())        
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
imp_comp_anno as (
    select 		capitolo_importi.elem_id,                   
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
        where capitolo.elem_id					=	capitolo_importi.elem_id 
            and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
            and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
            and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
            and	capitolo.elem_id					=	r_capitolo_stato.elem_id
            and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id					=	r_cat_capitolo.elem_id
            and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
            and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
            and	capitolo.bil_id						=	bil_elem_id
            and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
            and	stato_capitolo.elem_stato_code		=	'VA'
            and	capitolo_imp_periodo.anno in (annoCapImp)	
            and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp
            and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
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
        group by capitolo_importi.elem_id),
imp_comp_anno1 as (
    select 		capitolo_importi.elem_id,                   
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
        where capitolo.elem_id					=	capitolo_importi.elem_id 
            and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
            and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
            and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
            and	capitolo.elem_id					=	r_capitolo_stato.elem_id
            and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id					=	r_cat_capitolo.elem_id
            and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
            and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
            and	capitolo.bil_id						=	bil_elem_id
            and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
            and	stato_capitolo.elem_stato_code		=	'VA'
            and	capitolo_imp_periodo.anno in (annoCapImp1)	
            and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp
            and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
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
        group by capitolo_importi.elem_id),
imp_comp_anno2 as (
    select 		capitolo_importi.elem_id,                   
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
        where capitolo.elem_id					=	capitolo_importi.elem_id 
            and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
            and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
            and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
            and	capitolo.elem_id					=	r_capitolo_stato.elem_id
            and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id					=	r_cat_capitolo.elem_id
            and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
            and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
            and	capitolo.bil_id						=	bil_elem_id
            and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
            and	stato_capitolo.elem_stato_code		=	'VA'
            and	capitolo_imp_periodo.anno in (annoCapImp2)	
            and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp
            and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
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
        group by capitolo_importi.elem_id),
imp_stanz_residui_anno as (
    select 		capitolo_importi.elem_id,                   
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
        where capitolo.elem_id					=	capitolo_importi.elem_id 
            and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
            and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
            and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
            and	capitolo.elem_id					=	r_capitolo_stato.elem_id
            and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id					=	r_cat_capitolo.elem_id
            and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
            and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
            and	capitolo.bil_id						=	bil_elem_id
            and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
            and	stato_capitolo.elem_stato_code		=	'VA'
            and	capitolo_imp_periodo.anno in (annoCapImp)	
            and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpstanzresidui
            and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
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
        group by capitolo_importi.elem_id),        
imp_residui_anno as (
    select 		capitolo_importi.elem_id,                   
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
        where capitolo.elem_id					=	capitolo_importi.elem_id 
            and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
            and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
            and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
            and	capitolo.elem_id					=	r_capitolo_stato.elem_id
            and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id					=	r_cat_capitolo.elem_id
            and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
            and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
            and	capitolo.bil_id						=	bil_elem_id
            and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
            and	stato_capitolo.elem_stato_code		=	'VA'
            and	capitolo_imp_periodo.anno in (annoCapImp)	
            and	capitolo_imp_tipo.elem_det_tipo_code = tipoImpRes
            and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
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
        group by capitolo_importi.elem_id),
imp_cassa_anno as (
    select 		capitolo_importi.elem_id,                   
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
        where capitolo.elem_id					=	capitolo_importi.elem_id 
            and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
            and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
            and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
            and	capitolo.elem_id					=	r_capitolo_stato.elem_id
            and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id					=	r_cat_capitolo.elem_id
            and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
            and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
            and	capitolo.bil_id						=	bil_elem_id
            and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
            and	stato_capitolo.elem_stato_code		=	'VA'
            and	capitolo_imp_periodo.anno in (annoCapImp)	
            and	capitolo_imp_tipo.elem_det_tipo_code = tipoImpCassa
            and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
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
        group by capitolo_importi.elem_id),
impegnato_anno as(
select capitolo.elem_id,
sum(t_movgest_ts_det.movgest_ts_det_importo) impegnato 
    from siac_t_bil_elem     capitolo, 
      siac_r_movgest_bil_elem   r_movgest_bil_elem, 
      siac_d_bil_elem_tipo    d_bil_elem_tipo, 
      siac_t_movgest     t_movgest, 
      siac_d_movgest_tipo    d_movgest_tipo, 
      siac_t_movgest_ts    t_movgest_ts, 
      siac_r_movgest_ts_stato   r_movgest_ts_stato, 
      siac_d_movgest_stato    d_movgest_stato, 
      siac_t_movgest_ts_det   t_movgest_ts_det, 
      siac_d_movgest_ts_tipo   d_movgest_ts_tipo, 
      siac_d_movgest_ts_det_tipo  d_movgest_ts_det_tipo 
      where capitolo.elem_tipo_id = d_bil_elem_tipo.elem_tipo_id
        and t_movgest.movgest_id      = t_movgest_ts.movgest_id 
        and t_movgest_ts.movgest_ts_id    = r_movgest_ts_stato.movgest_ts_id 
        and r_movgest_ts_stato.movgest_stato_id  = d_movgest_stato.movgest_stato_id 
        and t_movgest_ts.movgest_ts_tipo_id  = d_movgest_ts_tipo.movgest_ts_tipo_id
        and r_movgest_bil_elem.elem_id  = capitolo.elem_id
        and r_movgest_bil_elem.movgest_id    = t_movgest.movgest_id 
        and t_movgest.movgest_tipo_id    = d_movgest_tipo.movgest_tipo_id 
        and t_movgest_ts.movgest_ts_id    = t_movgest_ts_det.movgest_ts_id 
        and t_movgest_ts_det.movgest_ts_det_tipo_id  = d_movgest_ts_det_tipo.movgest_ts_det_tipo_id 
        and capitolo.ente_proprietario_id   = p_ente_prop_id
        and capitolo.bil_id = bil_elem_id
        and d_bil_elem_tipo.elem_tipo_code    =  elemTipoCode 
        and t_movgest.movgest_anno ::text in (annoCapImp)      
        and d_movgest_tipo.movgest_tipo_code    = 'I' 
        and d_movgest_stato.movgest_stato_code   in ('D','N') ------ P,A,N        
        and d_movgest_ts_tipo.movgest_ts_tipo_code  = 'T'       
        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
        and r_movgest_bil_elem.data_cancellazione is NULL
        and t_movgest.data_cancellazione IS NULL
        and t_movgest_ts.data_cancellazione IS NULL
        and now() between r_movgest_bil_elem.validita_inizio 
          and coalesce (r_movgest_bil_elem.validita_fine, now())
        and now() between r_movgest_ts_stato.validita_inizio 
          and coalesce (r_movgest_ts_stato.validita_fine, now())
    group by  capitolo.elem_id),
impegnato_anno1 as(
select capitolo.elem_id,
sum(t_movgest_ts_det.movgest_ts_det_importo) impegnato 
    from siac_t_bil_elem     capitolo, 
      siac_r_movgest_bil_elem   r_movgest_bil_elem, 
      siac_d_bil_elem_tipo    d_bil_elem_tipo, 
      siac_t_movgest     t_movgest, 
      siac_d_movgest_tipo    d_movgest_tipo, 
      siac_t_movgest_ts    t_movgest_ts, 
      siac_r_movgest_ts_stato   r_movgest_ts_stato, 
      siac_d_movgest_stato    d_movgest_stato, 
      siac_t_movgest_ts_det   t_movgest_ts_det, 
      siac_d_movgest_ts_tipo   d_movgest_ts_tipo, 
      siac_d_movgest_ts_det_tipo  d_movgest_ts_det_tipo 
      where capitolo.elem_tipo_id = d_bil_elem_tipo.elem_tipo_id
        and t_movgest.movgest_id      = t_movgest_ts.movgest_id 
        and t_movgest_ts.movgest_ts_id    = r_movgest_ts_stato.movgest_ts_id 
        and r_movgest_ts_stato.movgest_stato_id  = d_movgest_stato.movgest_stato_id 
        and t_movgest_ts.movgest_ts_tipo_id  = d_movgest_ts_tipo.movgest_ts_tipo_id
        and r_movgest_bil_elem.elem_id  = capitolo.elem_id
        and r_movgest_bil_elem.movgest_id    = t_movgest.movgest_id 
        and t_movgest.movgest_tipo_id    = d_movgest_tipo.movgest_tipo_id 
        and t_movgest_ts.movgest_ts_id    = t_movgest_ts_det.movgest_ts_id 
        and t_movgest_ts_det.movgest_ts_det_tipo_id  = d_movgest_ts_det_tipo.movgest_ts_det_tipo_id 
        and capitolo.ente_proprietario_id   = p_ente_prop_id
        and capitolo.bil_id = bil_elem_id
        and d_bil_elem_tipo.elem_tipo_code    =  elemTipoCode 
        and t_movgest.movgest_anno ::text in (annoCapImp1)      
        and d_movgest_tipo.movgest_tipo_code    = 'I' 
        and d_movgest_stato.movgest_stato_code   in ('D','N') ------ P,A,N        
        and d_movgest_ts_tipo.movgest_ts_tipo_code  = 'T'       
        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
        and r_movgest_bil_elem.data_cancellazione is NULL
        and t_movgest.data_cancellazione IS NULL
        and t_movgest_ts.data_cancellazione IS NULL
        and now() between r_movgest_bil_elem.validita_inizio 
          and coalesce (r_movgest_bil_elem.validita_fine, now())
        and now() between r_movgest_ts_stato.validita_inizio 
          and coalesce (r_movgest_ts_stato.validita_fine, now())
     group by  capitolo.elem_id),
impegnato_anno2 as(
select capitolo.elem_id,
sum(t_movgest_ts_det.movgest_ts_det_importo) impegnato 
    from siac_t_bil_elem     capitolo, 
      siac_r_movgest_bil_elem   r_movgest_bil_elem, 
      siac_d_bil_elem_tipo    d_bil_elem_tipo, 
      siac_t_movgest     t_movgest, 
      siac_d_movgest_tipo    d_movgest_tipo, 
      siac_t_movgest_ts    t_movgest_ts, 
      siac_r_movgest_ts_stato   r_movgest_ts_stato, 
      siac_d_movgest_stato    d_movgest_stato, 
      siac_t_movgest_ts_det   t_movgest_ts_det, 
      siac_d_movgest_ts_tipo   d_movgest_ts_tipo, 
      siac_d_movgest_ts_det_tipo  d_movgest_ts_det_tipo 
      where capitolo.elem_tipo_id = d_bil_elem_tipo.elem_tipo_id
        and t_movgest.movgest_id      = t_movgest_ts.movgest_id 
        and t_movgest_ts.movgest_ts_id    = r_movgest_ts_stato.movgest_ts_id 
        and r_movgest_ts_stato.movgest_stato_id  = d_movgest_stato.movgest_stato_id 
        and t_movgest_ts.movgest_ts_tipo_id  = d_movgest_ts_tipo.movgest_ts_tipo_id
        and r_movgest_bil_elem.elem_id  = capitolo.elem_id
        and r_movgest_bil_elem.movgest_id    = t_movgest.movgest_id 
        and t_movgest.movgest_tipo_id    = d_movgest_tipo.movgest_tipo_id 
        and t_movgest_ts.movgest_ts_id    = t_movgest_ts_det.movgest_ts_id 
        and t_movgest_ts_det.movgest_ts_det_tipo_id  = d_movgest_ts_det_tipo.movgest_ts_det_tipo_id 
        and capitolo.ente_proprietario_id   = p_ente_prop_id
        and capitolo.bil_id = bil_elem_id
        and d_bil_elem_tipo.elem_tipo_code    =  elemTipoCode 
        and t_movgest.movgest_anno ::text in (annoCapImp2)      
        and d_movgest_tipo.movgest_tipo_code    = 'I' 
        and d_movgest_stato.movgest_stato_code   in ('D','N') ------ P,A,N        
        and d_movgest_ts_tipo.movgest_ts_tipo_code  = 'T'       
        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
        and r_movgest_bil_elem.data_cancellazione is NULL
        and t_movgest.data_cancellazione IS NULL
        and t_movgest_ts.data_cancellazione IS NULL
        and now() between r_movgest_bil_elem.validita_inizio 
          and coalesce (r_movgest_bil_elem.validita_fine, now())
        and now() between r_movgest_ts_stato.validita_inizio 
          and coalesce (r_movgest_ts_stato.validita_fine, now())                     
    group by capitolo.elem_id ),
 variaz_stanz_anno as (select a.elem_id, sum(a.importo) importo_var
                  from siac_rep_var_spese a
                  where a.ente_proprietario =p_ente_prop_id
                  and a.tipologia=TipoImpComp -- ''STA''
                  and a.periodo_anno=annoCapImp
                  and a.utente=user_table
                  group by  a.elem_id),   
 variaz_stanz_anno1 as (select a.elem_id, sum(a.importo) importo_var
                  from siac_rep_var_spese a
                  where a.ente_proprietario =p_ente_prop_id
                  and a.tipologia=TipoImpComp -- ''STA''
                  and a.periodo_anno=annoCapImp1
                  and a.utente=user_table
                  group by  a.elem_id),  
 variaz_stanz_anno2 as (select a.elem_id, sum(a.importo) importo_var
                  from siac_rep_var_spese a
                  where a.ente_proprietario =p_ente_prop_id
                  and a.tipologia=TipoImpComp -- ''STA''
                  and a.periodo_anno=annoCapImp2
                  and a.utente=user_table
                  group by  a.elem_id),                                      
 variaz_cassa as (select a.elem_id, sum(a.importo) importo_var
                  from siac_rep_var_spese a
                  where a.ente_proprietario =p_ente_prop_id
                  and a.tipologia=tipoImpCassa -- ''SCA''
                  and a.utente=user_table
                  group by  a.elem_id),  
 variaz_residui as (select a.elem_id, sum(a.importo) importo_var
                  from siac_rep_var_spese a
                  where a.ente_proprietario =p_ente_prop_id
                  and a.tipologia=TipoImpRes -- ''STR''
                  and a.utente=user_table
                  group by  a.elem_id)                                                                         
SELECT p_anno::varchar bil_anno,
	''::varchar missione_tipo_code,
    struttura.missione_tipo_desc::varchar missione_tipo_desc,
	struttura.missione_code::varchar missione_code,
    struttura.missione_desc::varchar missione_desc,
    ''::varchar programma_tipo_code,
    struttura.programma_tipo_desc::varchar programma_tipo_desc,
    struttura.programma_code::varchar programma_code,
    struttura.programma_desc::varchar programma_desc,
    ''::varchar titusc_tipo_code,
    struttura.titusc_tipo_desc::varchar titusc_tipo_desc,    
    struttura.titusc_code::varchar titolo_code,
    struttura.titusc_desc::varchar titolo_desc,
    ''::varchar macroag_tipo_code,
    struttura.macroag_tipo_desc::varchar macroag_tipo_desc,
    struttura.macroag_code::varchar macroaggr_code,
    struttura.macroag_desc::varchar macroaggr_desc,    
    capitoli.elem_code::varchar bil_ele_code,
    capitoli.elem_desc::varchar bil_ele_desc,
    COALESCE(capitoli.elem_code2,'')::varchar bil_ele_code2,
    COALESCE(capitoli.elem_desc2,'')::varchar bil_ele_desc2,
    capitoli.elem_id::integer  bil_ele_id,
    capitoli.elem_id_padre::integer  bil_ele_id_padre,
    (COALESCE(imp_residui_anno.importo,0) + COALESCE(variaz_residui.importo_var,0))
    	::numeric stanziamento_prev_res_anno,
    COALESCE(imp_stanz_residui_anno.importo,0)::numeric stanziamento_anno_prec,
    (COALESCE(imp_cassa_anno.importo,0) + COALESCE(variaz_cassa.importo_var,0))
    	::numeric stanziamento_prev_cassa_anno,
    (COALESCE(imp_comp_anno.importo,0) + COALESCE(variaz_stanz_anno.importo_var,0))
    	::numeric stanziamento_prev_anno,
    (COALESCE(imp_comp_anno1.importo,0) + COALESCE(variaz_stanz_anno1.importo_var,0))
    	::numeric stanziamento_prev_anno1,
    (COALESCE(imp_comp_anno2.importo,0) + COALESCE(variaz_stanz_anno2.importo_var,0))
    	::numeric stanziamento_prev_anno2,
    COALESCE(impegnato_anno.impegnato,0)::numeric impegnato_anno,
    COALESCE(impegnato_anno1.impegnato,0)::numeric impegnato_anno1,
    COALESCE(impegnato_anno2.impegnato,0)::numeric impegnato_anno2,
    COALESCE(capitoli.num_cap_old,'')::varchar num_cap_old,
    COALESCE(capitoli.num_art_old,'')::varchar num_art_old,
    COALESCE(capitoli.capitolo_upb,'')::varchar upb,
    ''::varchar display_error
from struttura
	left join capitoli
    	on struttura.programma_id = capitoli.programma_id    
          and	struttura.macroag_id	= capitoli.macroaggregato_id
   	left join imp_comp_anno
   		on imp_comp_anno.elem_id = capitoli.elem_id
    left join imp_comp_anno1
            on imp_comp_anno1.elem_id = capitoli.elem_id
    left join imp_comp_anno2
            on imp_comp_anno2.elem_id = capitoli.elem_id
    left join imp_residui_anno
            on imp_residui_anno.elem_id = capitoli.elem_id
    left join imp_cassa_anno
            on imp_cassa_anno.elem_id = capitoli.elem_id
    left join impegnato_anno
            on impegnato_anno.elem_id = capitoli.elem_id   
    left join impegnato_anno1
            on impegnato_anno1.elem_id = capitoli.elem_id 
    left join impegnato_anno2
            on impegnato_anno2.elem_id = capitoli.elem_id 
    left join imp_stanz_residui_anno
            on imp_stanz_residui_anno.elem_id = capitoli.elem_id  
    left join variaz_stanz_anno
    		on variaz_stanz_anno.elem_id = capitoli.elem_id  
    left join variaz_stanz_anno1
    		on variaz_stanz_anno1.elem_id = capitoli.elem_id  
    left join variaz_stanz_anno2
    		on variaz_stanz_anno2.elem_id = capitoli.elem_id                          
	left join variaz_cassa
    		on variaz_cassa.elem_id = capitoli.elem_id             
	left join variaz_residui
    		on variaz_residui.elem_id = capitoli.elem_id 
  where capitoli.elem_code IS NOT NULL;

delete from	siac_rep_var_spese	where utente=user_table;   

raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
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
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR253_peg_spese_gestione_variaz" (p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar)
  OWNER TO siac;