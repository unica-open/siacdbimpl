/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR256_Allegato_8_delibera_variazione_definitive_Prev_spese" (
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
  display_error varchar
) AS
$body$
DECLARE

/* 02/07/2021 SIAC-8152.
	Funzione copia della BILR227_Allegato_7_delibera_variazione_su_spese_bozza_Prev
    per il nuovo report BILR257 che differisce dal BILR227 per il fatto 
    che le variazioni estratte sono in stato DEFINITIVO.
*/

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
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;


BEGIN

annoCapImp:= p_anno; 
annocapimp2:=(p_anno::INTEGER + 1)::varchar;
annocapimp3:=(p_anno::INTEGER + 2)::varchar;

raise notice '%', annoCapImp;


TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 04/04/2019: il report funziona solo per la previsione
elemTipoCode:='CAP-UP'; -- tipo capitolo previsione

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
display_error:='';


-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

contaParametriParz:=0;
contaParametri:=0;

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

 RTN_MESSAGGIO:='insert tabella siac_rep_mis_pro_tit_mac_riga_anni''.'; 
 
 -- carico struttura del bilancio
insert into siac_rep_mis_pro_tit_mac_riga_anni
select * from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, 
													p_anno, user_table);

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
    stato_capitolo.elem_stato_code		in ('VA', 'PR')						and			
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
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
    and	r_cat_capitolo.data_cancellazione 			is null;	

  

RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug_imp standard''.';  


/* Si deve tener conto di eventuali variazioni successive e decrementare 
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
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code		in ('VA', 'PR')								
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')	
        and capitolo_imp_periodo.anno =	p_anno_competenza					
        and	capitolo_imp_tipo.elem_det_tipo_code in ('STA','SCA','STR') 		
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
        		--tb1.periodo_anno 		= annoCapImp		AND	 
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
     
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
if p_numero_delibera IS NOT NULL THEN
insert into siac_rep_var_spese            
  select	dettaglio_variazione.elem_id,
          sum(dettaglio_variazione.elem_det_importo),
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
  where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
  and		r_atto_stato.attoamm_id								=	atto.attoamm_id
  and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
  and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id
            or r_variazione_stato.attoamm_id_varbil           =	atto.attoamm_id) 
  and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
  and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
  and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id										
  and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
  and     anno_eserc.periodo_id                               = bilancio.periodo_id
  and     testata_variazione.bil_id                           = bilancio.bil_id 
  and     capitolo.bil_id                                     = bilancio.bil_id  
  and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
  and		dettaglio_variazione.elem_id						=	capitolo.elem_id
  and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
  and 	atto.ente_proprietario_id 							= 	p_ente_prop_id
  and		anno_eserc.anno										= 	p_anno	
  and		atto.attoamm_numero 								= 	p_numero_delibera
  and		atto.attoamm_anno									=	p_anno_delibera
  and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
  and     anno_importo.anno                                   =   p_anno_competenza		
  and		tipologia_stato_var.variazione_stato_tipo_code		 in	('D')
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
  and 		dettaglio_variazione.data_cancellazione		is null
  and 		capitolo.data_cancellazione					is null
  and		tipo_capitolo.data_cancellazione			is null
  and		tipo_elemento.data_cancellazione			is null
  group by 	dettaglio_variazione.elem_id,
              tipo_elemento.elem_det_tipo_code, 
              utente,
              atto.ente_proprietario_id,
              anno_importo.anno	  ;       
else --specificati i numeri di variazione.
	strQuery:='
	insert into siac_rep_var_spese 
    select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
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
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id										
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id  
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and 	testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id||'
and		anno_eserc.anno										= 	'''||p_anno||'''
and 	testata_variazione.variazione_num					in ('||p_ele_variazioni||')
and     anno_importo.anno                                   =   '''||p_anno_competenza||'''				
and		tipologia_stato_var.variazione_stato_tipo_code		 in	(''D'')
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
group by 	dettaglio_variazione.elem_id,
        	tipo_elemento.elem_det_tipo_code, 
        	utente,
        	testata_variazione.ente_proprietario_id,
            anno_importo.anno	  ';
raise notice 'query: %', strQuery;      

execute  strQuery;     
end if;                               
        

--/13/02/2017 : e'  rimasto solo il filtro su anno_competenza
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
        p_anno_competenza 
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno_competenza
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=p_anno_competenza
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=p_anno_competenza
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=p_anno_competenza
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=p_anno_competenza
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=p_anno_competenza
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  ; 
        
        
     RTN_MESSAGGIO:='preparazione file output ''.';  
         
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
from  	siac_rep_mis_pro_tit_mac_riga_anni v1
			join siac_rep_cap_ug tb
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
    where v1.utente = user_table 
    and exists ( select 1 from siac_rep_var_spese_riga x, siac_rep_cap_ug y, 
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.macroaggregato_id = z.classif_id
                 and z.classif_id_padre = v1.titusc_id
                 and y.programma_id=v1.programma_id                                     
    )	
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

--SIAC-8687: 11/04/2022.
--L'importo di stanziamento, cassa e residuo deve essere quello prima 
-- della modifica, quindi dal totale calcolato escludo l'importo della
--modifica.
--stanziamento:=classifBilRec.stanziamento;
--cassa:=classifBilRec.cassa;
--residuo:=classifBilRec.residuo;
variazione_aumento_stanziato:=classifBilRec.variazione_aumento_stanziato;
variazione_diminuzione_stanziato:=classifBilRec.variazione_diminuzione_stanziato;
variazione_aumento_cassa:=classifBilRec.variazione_aumento_cassa;
variazione_diminuzione_cassa:=classifBilRec.variazione_diminuzione_cassa;
variazione_aumento_residuo:=classifBilRec.variazione_aumento_residuo;
variazione_diminuzione_residuo:=classifBilRec.variazione_diminuzione_residuo;
anno_riferimento:=classifBilRec.anno_riferimento;

--INC000006082542
stanziamento:=classifBilRec.stanziamento-variazione_aumento_stanziato+
	variazione_diminuzione_stanziato;
cassa:=classifBilRec.cassa-variazione_aumento_cassa + 
	variazione_diminuzione_cassa;
residuo:=classifBilRec.residuo - variazione_aumento_residuo +
	variazione_diminuzione_residuo;
    
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

ALTER FUNCTION siac."BILR256_Allegato_8_delibera_variazione_definitive_Prev_spese" (p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar, p_ele_variazioni varchar)
  OWNER TO siac;