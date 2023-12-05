/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR1000_estrazione_spese_previsione" (
  p_ente_prop_id integer,
  p_anno varchar
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
  stanziamento_fpv_anno_prec numeric,
  stanziamento_fpv_anno numeric,
  stanziamento_fpv_anno1 numeric,
  stanziamento_fpv_anno2 numeric,
  fase_bilancio varchar,
  capitolo_prec integer,
  bil_ele_code3 varchar,
  codice_pdc varchar,
  direz_code varchar,
  direz_descr varchar,
  sett_code varchar,
  sett_descr varchar,
  note varchar,
  funzioni_delegate varchar,
  ricorrente varchar,
  codice_transazione varchar,
  descrizione_transazione varchar
) AS
$body$
DECLARE

classifBilRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
annoCapImp_int integer;
annoCapImp1_int integer;
annoCapImp2_int integer;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
elemTipoCode_UG	varchar;
TipoImpstanzresidui varchar;
anno_bil_impegni	varchar;
tipo_capitolo	varchar;
h_count integer :=0;
importo integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
tipologia_capitolo	varchar;
esiste_siac_t_dicuiimpegnato_bilprev integer;
classif_id_padre integer;


BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
elemTipoCode:='CAP-UP'; -- tipo capitolo previsione
elemTipoCode_UG:='CAP-UG';	--- Capitolo gestione

anno_bil_impegni:= ((p_anno::INTEGER)-1)::VARCHAR;


annoCapImp_int:= p_anno::INTEGER; 
annoCapImp1_int:= annoCapImp_int+1;   
annoCapImp2_int:= annoCapImp_int+2; 


select fnc_siac_random_user()
into	user_table;

raise notice 'ora prima lettura anno di bilancio : % ',clock_timestamp()::varchar;
begin
     RTN_MESSAGGIO:='lettura anno di bilancio''.';  
for classifBilRec in
select 	anno_eserc.anno BIL_ANNO, 
        r_fase.bil_fase_operativa_id, 
        fase.fase_operativa_desc, 
        fase.fase_operativa_code fase_bilancio
from 	siac_t_bil 						bilancio,
		siac_t_periodo 					anno_eserc,
        siac_d_periodo_tipo				tipo_periodo,
        siac_r_bil_fase_operativa 		r_fase,
        siac_d_fase_operativa  			fase
where	anno_eserc.anno						=	p_anno							and	
		bilancio.periodo_id					=	anno_eserc.periodo_id			and
        tipo_periodo.periodo_tipo_code		=	'SY'							and
        anno_eserc.ente_proprietario_id		=	p_ente_prop_id					and
/*        bilancio.ente_proprietario_id		=	anno_eserc.ente_proprietario_id	and
        tipo_periodo.ente_proprietario_id	=	anno_eserc.ente_proprietario_id	and
        r_fase.ente_proprietario_id			=	anno_eserc.ente_proprietario_id	and
        fase.ente_proprietario_id			=	anno_eserc.ente_proprietario_id	and*/
        tipo_periodo.periodo_tipo_id		=	anno_eserc.periodo_tipo_id		and
        r_fase.bil_id						=	bilancio.bil_id					AND
        r_fase.fase_operativa_id			=	fase.fase_operativa_id			and
        bilancio.data_cancellazione			is null								and							
		anno_eserc.data_cancellazione		is null								and	
        tipo_periodo.data_cancellazione		is null								and	
       	r_fase.data_cancellazione			is null								and	
        fase.data_cancellazione				is null								and
        now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())			and		
        now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())		and
        now() between tipo_periodo.validita_inizio and coalesce (tipo_periodo.validita_fine, now())	and        
        now() between r_fase.validita_inizio and coalesce (r_fase.validita_fine, now())				and
		now() between fase.validita_inizio and coalesce (fase.validita_fine, now())

loop
   fase_bilancio:=classifBilRec.fase_bilancio;
raise notice 'Fase bilancio  %',classifBilRec.fase_bilancio;

anno_bil_impegni:=p_anno;

  if classifBilRec.fase_bilancio = 'P'  then
      anno_bil_impegni:= ((p_anno::INTEGER)-1)::VARCHAR;
  else
      anno_bil_impegni:=p_anno;
  end if;
end loop;

exception
	when no_data_found THEN
		raise notice 'Fase del bilancio non trovata';
	return;
	when others  THEN
        RTN_MESSAGGIO:='errore ricerca fase bilancio';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
       return;
end;

raise notice 'ora dopo lettura anno di bilancio : % ',clock_timestamp()::varchar;
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
stanziamento_fpv_anno_prec=0;
stanziamento_fpv_anno=0;
stanziamento_fpv_anno1=0;
stanziamento_fpv_anno2=0;
tipologia_capitolo='';
note='';
funzioni_delegate='';
ricorrente='';
codice_transazione='';
descrizione_transazione=''; 

     RTN_MESSAGGIO:='lettura struttura del bilancio''.';  
raise notice 'ora prima siac_rep_mis_pro_tit_mac_riga_anni : % ',clock_timestamp()::varchar;
insert into siac_rep_mis_pro_tit_mac_riga_anni
select v.*,user_table from
(SELECT missione_tipo.classif_tipo_desc AS missione_tipo_desc,
    missione.classif_id AS missione_id, missione.classif_code AS missione_code,
    missione.classif_desc AS missione_desc,
    missione.validita_inizio AS missione_validita_inizio,
    missione.validita_fine AS missione_validita_fine,
    programma_tipo.classif_tipo_desc AS programma_tipo_desc,
    programma.classif_id AS programma_id,
    programma.classif_code AS programma_code,
    programma.classif_desc AS programma_desc,
    programma.validita_inizio AS programma_validita_inizio,
    programma.validita_fine AS programma_validita_fine,
    titusc_tipo.classif_tipo_desc AS titusc_tipo_desc,
    titusc.classif_id AS titusc_id, titusc.classif_code AS titusc_code,
    titusc.classif_desc AS titusc_desc,
    titusc.validita_inizio AS titusc_validita_inizio,
    titusc.validita_fine AS titusc_validita_fine,
    macroaggr_tipo.classif_tipo_desc AS macroag_tipo_desc,
    macroaggr.classif_id AS macroag_id, macroaggr.classif_code AS macroag_code,
    macroaggr.classif_desc AS macroag_desc,
    macroaggr.validita_inizio AS macroag_validita_inizio,
    macroaggr.validita_fine AS macroag_validita_fine,
    macroaggr.ente_proprietario_id
FROM siac_d_class_fam missione_fam, siac_t_class_fam_tree missione_tree,
    siac_r_class_fam_tree missione_r_cft, siac_t_class missione,
    siac_d_class_tipo missione_tipo, siac_d_class_tipo programma_tipo,
    siac_t_class programma, siac_d_class_fam titusc_fam,
    siac_t_class_fam_tree titusc_tree, siac_r_class_fam_tree titusc_r_cft,
    siac_t_class titusc, siac_d_class_tipo titusc_tipo,
    siac_d_class_tipo macroaggr_tipo, siac_t_class macroaggr
WHERE missione_fam.classif_fam_desc::text = 'Spesa - MissioniProgrammi'::text
    AND missione_fam.classif_fam_id = missione_tree.classif_fam_id 
    AND missione_tree.classif_fam_tree_id = missione_r_cft.classif_fam_tree_id 
    AND missione_r_cft.classif_id_padre = missione.classif_id 
    AND missione.classif_tipo_id = missione_tipo.classif_tipo_id 
    AND missione_tipo.classif_tipo_code::text = 'MISSIONE'::text 
    AND programma_tipo.classif_tipo_code::text = 'PROGRAMMA'::text 
    AND missione_r_cft.classif_id = programma.classif_id 
    AND programma.classif_tipo_id = programma_tipo.classif_tipo_id 
    AND titusc_fam.classif_fam_desc::text = 'Spesa - TitoliMacroaggregati'::text 
    AND titusc_fam.classif_fam_id = titusc_tree.classif_fam_id 
    AND titusc_tree.classif_fam_tree_id = titusc_r_cft.classif_fam_tree_id 
    AND titusc_r_cft.classif_id_padre = titusc.classif_id 
    AND titusc_tipo.classif_tipo_code::text = 'TITOLO_SPESA'::text 
    AND titusc.classif_tipo_id = titusc_tipo.classif_tipo_id 
    AND macroaggr_tipo.classif_tipo_code::text = 'MACROAGGREGATO'::text 
    AND titusc_r_cft.classif_id = macroaggr.classif_id 
    AND macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 
    AND missione.ente_proprietario_id = programma.ente_proprietario_id 
    AND programma.ente_proprietario_id = titusc.ente_proprietario_id 
    AND titusc.ente_proprietario_id = macroaggr.ente_proprietario_id
ORDER BY missione.classif_code, programma.classif_code, titusc.classif_code,
    macroaggr.classif_code) v
--------siac_v_mis_pro_tit_macr_anni 
 where v.ente_proprietario_id=p_ente_prop_id 
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.macroag_validita_inizio and
COALESCE(v.macroag_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.missione_validita_inizio and
COALESCE(v.missione_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.programma_validita_inizio and
COALESCE(v.programma_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.titusc_validita_inizio and
COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
order by missione_code, programma_code,titusc_code,macroag_code;

raise notice 'ora dopo siac_rep_mis_pro_tit_mac_riga_anni : % ',clock_timestamp()::varchar;

     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up''.';  
raise notice 'ora prima siac_rep_cap_up : % ',clock_timestamp()::varchar;     

insert into siac_rep_cap_up
select 	programma.classif_id,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
  		pdc.classif_code,
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
     siac_r_bil_elem_class r_capitolo_pdc,
     siac_t_class pdc,
     siac_d_class_tipo pdc_tipo,
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
	capitolo.ente_proprietario_id=p_ente_prop_id      							and
   	anno_eserc.anno= p_anno 													and
    bilancio.periodo_id=anno_eserc.periodo_id 									and
    capitolo.bil_id=bilancio.bil_id 											and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 							and
    tipo_elemento.elem_tipo_code = elemTipoCode						    	 	and 
    capitolo.elem_id=r_capitolo_programma.elem_id								and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id								and
    r_capitolo_pdc.classif_id = pdc.classif_id									and
    pdc.classif_tipo_id = pdc_tipo.classif_tipo_id								and
    pdc_tipo.classif_tipo_code like 'PDC%'										and
    capitolo.elem_id = r_capitolo_pdc.elem_id									and
    capitolo.elem_id				=	r_capitolo_stato.elem_id				and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id			and
	stato_capitolo.elem_stato_code	=	'VA'									and
    capitolo.elem_id				=	r_cat_capitolo.elem_id					and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id			
    -------cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC')	
    and	bilancio.data_cancellazione 				is null
    and	anno_eserc.data_cancellazione 				is null
    and	programma_tipo.data_cancellazione 			is null
    and	programma.data_cancellazione 				is null
    and	macroaggr_tipo.data_cancellazione 			is null
    and	macroaggr.data_cancellazione 				is null
    and	capitolo.data_cancellazione 				is null
    and	tipo_elemento.data_cancellazione 			is null
    and	r_capitolo_programma.data_cancellazione		is null
    and	r_capitolo_macroaggr.data_cancellazione		is null
    and	r_capitolo_pdc.data_cancellazione 			is null
    and	pdc.data_cancellazione 						is null
    and	pdc_tipo.data_cancellazione 				is null
    and	stato_capitolo.data_cancellazione 			is null
    and	r_capitolo_stato.data_cancellazione 		is null
    and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione 			is null;

-----------------   importo capitoli di tipo standard ------------------------
raise notice 'ora dopo siac_rep_cap_up : % ',clock_timestamp()::varchar;  
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp standard''.';  

raise notice 'ora prima siac_rep_cap_up_imp : % ',clock_timestamp()::varchar;  

insert into siac_rep_cap_up_imp 
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo),
       		cat_del_capitolo.elem_cat_code tipologia_capitolo       
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
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
    	/*and	capitolo_importi.ente_proprietario_id 	=capitolo_imp_tipo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id 	=capitolo_imp_periodo.ente_proprietario_id
   		and capitolo_importi.ente_proprietario_id	=tipo_elemento.ente_proprietario_id	
        and capitolo_importi.ente_proprietario_id	=capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=bilancio.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=anno_eserc.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=stato_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=r_capitolo_stato.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=cat_del_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=r_cat_capitolo.ente_proprietario_id*/
        and	anno_eserc.anno					= p_anno 												
    	and	bilancio.periodo_id				=anno_eserc.periodo_id 								
        and	capitolo.bil_id					=bilancio.bil_id 			 
        and	capitolo.elem_id	=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code = elemTipoCode
        and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
		-----and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')						
        ----and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
    	----and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
    	----and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
        -----and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
    	----and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        ----and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        ----and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        -------and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        -----and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        ------and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        ----and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
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
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente, cat_del_capitolo.elem_cat_code
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;

-----------------   importo capitoli di tipo fondo pluriennale vincolato ------------------------
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp fpv''.';  
raise notice 'ora dopo siac_rep_cap_up_imp : % ',clock_timestamp()::varchar;  

raise notice 'ora prima siac_rep_cap_up_imp : % ',clock_timestamp()::varchar;  
/*
insert into siac_rep_cap_up_imp 
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo),
       		cat_del_capitolo.elem_cat_code tipologia_capitolo       
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
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
    	/*and	capitolo_importi.ente_proprietario_id 	=capitolo_imp_tipo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id 	=capitolo_imp_periodo.ente_proprietario_id
   		and capitolo_importi.ente_proprietario_id	=tipo_elemento.ente_proprietario_id	
        and capitolo_importi.ente_proprietario_id	=capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=bilancio.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=anno_eserc.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=stato_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=r_capitolo_stato.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=cat_del_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=r_cat_capitolo.ente_proprietario_id*/
        and	anno_eserc.anno					= p_anno 												
    	and	bilancio.periodo_id				=anno_eserc.periodo_id 								
        and	capitolo.bil_id					=bilancio.bil_id 			 
        and	capitolo.elem_id	=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code = elemTipoCode
        and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code	=	'FPV'								
        ----and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
    	-----and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
    	----and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
        ------and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
    	----and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        -----and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        ----and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        ------and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        ---and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        ------and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        ---and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
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
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente, cat_del_capitolo.elem_cat_code
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;*/

raise notice 'ora dopo fpv siac_rep_cap_up_imp : % ',clock_timestamp()::varchar; 

-----------------------------------------------------------------------------------------------
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp_riga STD''.';  
/*
insert into siac_rep_cap_up_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	tb2.importo 	as		stanziamento_prev_anno1,
    	tb3.importo		as		stanziamento_prev_anno2,
   	 	tb4.importo		as		stanziamento_prev_res_anno,
    	tb5.importo		as		stanziamento_anno_prec,
    	tb6.importo		as		stanziamento_prev_cassa_anno,
        tb7.importo		as		stanziamento_fpv_anno_prec,
  		tb8.importo		as		stanziamento_fpv_anno,
  		tb9.importo		as		stanziamento_fpv_anno1,
  		tb10.importo	as		stanziamento_fpv_anno2,
        tb1.ente_proprietario,
        user_table utente from 
        siac_rep_cap_up_imp tb1, siac_rep_cap_up_imp tb2, siac_rep_cap_up_imp tb3,
		siac_rep_cap_up_imp tb4, siac_rep_cap_up_imp tb5, siac_rep_cap_up_imp tb6,
        siac_rep_cap_up_imp tb7, siac_rep_cap_up_imp tb8, siac_rep_cap_up_imp tb9,
        siac_rep_cap_up_imp tb10
         where			
    	tb1.elem_id	=	tb2.elem_id
        and 
        tb2.elem_id	=	tb3.elem_id
        and 
        tb3.elem_id	=	tb4.elem_id
        and 
        tb4.elem_id	=	tb5.elem_id
        and 
        tb5.elem_id	=	tb6.elem_id
        and
        tb6.elem_id	=	tb7.elem_id
        and
        tb7.elem_id	=	tb8.elem_id
        and
		tb8.elem_id	=	tb9.elem_id
        and
        tb9.elem_id	=	tb10.elem_id 
        and
    	tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp			and	tb1.tipo_capitolo 		= 'STD'
        AND
        tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp 		and	tb2.tipo_capitolo		= 'STD'
        and
        tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp		and	tb3.tipo_capitolo		= 'STD'			 
        and 
    	tb4.periodo_anno = tb1.periodo_anno AND	tb4.tipo_imp = 	TipoImpRes		and	tb4.tipo_capitolo		= 'STD'
        and 
    	tb5.periodo_anno = tb1.periodo_anno AND	tb5.tipo_imp = 	TipoImpstanzresidui	and	tb5.tipo_capitolo	= 'STD'
        and 
    	tb6.periodo_anno = tb1.periodo_anno AND	tb6.tipo_imp = 	TipoImpCassa	and	tb6.tipo_capitolo		= 'STD'
        and 
    	tb7.periodo_anno = tb1.periodo_anno AND	tb7.tipo_imp = 	TipoImpstanzresidui	and	tb7.tipo_capitolo	= 'FPV'
        and
    	tb8.periodo_anno = annoCapImp	AND	tb8.tipo_imp =	TipoImpComp			and	tb8.tipo_capitolo 		= 'FPV'
        AND
        tb9.periodo_anno = annoCapImp1	AND	tb9.tipo_imp =	tb8.tipo_imp 		and	tb9.tipo_capitolo		= 'FPV'
        and
        tb10.periodo_anno = annoCapImp2	AND	tb10.tipo_imp =	tb8.tipo_imp		and	tb10.tipo_capitolo		= 'FPV' 		 ;

     RTN_MESSAGGIO:='insert tabella siac_rep_mptm_up_cap_importi''.';  
*/

raise notice 'ora prima siac_rep_cap_up_imp_riga : % ',clock_timestamp()::varchar; 

insert into siac_rep_cap_up_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	tb2.importo 	as		stanziamento_prev_anno1,
    	tb3.importo		as		stanziamento_prev_anno2,
   	 	tb4.importo		as		stanziamento_prev_res_anno,
    	tb5.importo		as		stanziamento_anno_prec,
    	tb6.importo		as		stanziamento_prev_cassa_anno,
        0,0,0,0,
        tb1.ente_proprietario,
        user_table utente from 
        siac_rep_cap_up_imp tb1, siac_rep_cap_up_imp tb2, siac_rep_cap_up_imp tb3,
		siac_rep_cap_up_imp tb4, siac_rep_cap_up_imp tb5, siac_rep_cap_up_imp tb6
         where			
    	tb1.elem_id	=	tb2.elem_id
        and 
        tb2.elem_id	=	tb3.elem_id
        and 
        tb3.elem_id	=	tb4.elem_id
        and 
        tb4.elem_id	=	tb5.elem_id
        and 
        tb5.elem_id	=	tb6.elem_id
        and
    	tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	
        AND
        tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp 
        and
        tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp	 
        and 
    	tb4.periodo_anno = tb1.periodo_anno AND	tb4.tipo_imp = 	TipoImpRes
        and 
    	tb5.periodo_anno = tb1.periodo_anno AND	tb5.tipo_imp = 	TipoImpstanzresidui
        and 
    	tb6.periodo_anno = tb1.periodo_anno AND	tb6.tipo_imp = 	TipoImpCassa
        and tb1.utente 	= 	tb2.utente	
        and	tb2.utente	=	tb3.utente
        and	tb3.utente	=	tb4.utente
        and	tb4.utente	=	tb5.utente
        and tb5.utente	=	tb6.utente
        and	tb6.utente	=	user_table;

raise notice 'ora dopo siac_rep_cap_up_imp_riga : % ',clock_timestamp()::varchar; 

raise notice 'ora prima fpv siac_rep_cap_up_imp_riga : % ',clock_timestamp()::varchar; 

     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp_riga FPV''.'; 
     
/* 
insert into siac_rep_cap_up_imp_riga
select  tb7.elem_id,      
    	0,
    	0,
    	0,
   	 	0,
    	0,
    	0,
        tb7.importo		as		stanziamento_fpv_anno_prec,
  		tb8.importo		as		stanziamento_fpv_anno,
  		tb9.importo		as		stanziamento_fpv_anno1,
  		tb10.importo	as		stanziamento_fpv_anno2,
        tb7.ente_proprietario,
        user_table utente from 
        siac_rep_cap_up_imp tb7, siac_rep_cap_up_imp tb8, siac_rep_cap_up_imp tb9,
        siac_rep_cap_up_imp tb10
         where		
        tb7.elem_id	=	tb8.elem_id
        and
		tb8.elem_id	=	tb9.elem_id
        and
        tb9.elem_id	=	tb10.elem_id 
        AND
    	tb7.periodo_anno = annoCapImp AND	tb7.tipo_imp = 	TipoImpstanzresidui	and	tb7.tipo_capitolo	= 'FPV'
        and
    	tb8.periodo_anno = annoCapImp	AND	tb8.tipo_imp =	TipoImpComp			and	tb8.tipo_capitolo 		= 'FPV'
        AND
        tb9.periodo_anno = annoCapImp1	AND	tb9.tipo_imp =	tb8.tipo_imp 		and	tb9.tipo_capitolo		= 'FPV'
        and
        tb10.periodo_anno = annoCapImp2	AND	tb10.tipo_imp =	tb8.tipo_imp		and	tb10.tipo_capitolo		= 'FPV'
        and tb7.utente 	= 	tb8.utente	
        and	tb8.utente	=	tb9.utente
        and	tb9.utente	=	tb10.utente	
        and	tb10.utente	=	user_table;*/
        
raise notice 'ora dopo fpv siac_rep_cap_up_imp_riga : % ',clock_timestamp()::varchar; 
     RTN_MESSAGGIO:='insert tabella siac_rep_mptm_up_cap_importi''.';  

raise notice 'ora prima siac_rep_mptm_up_cap_importi : % ',clock_timestamp()::varchar; 

insert into siac_rep_mptm_up_cap_importi
select 	v1.missione_tipo_desc			missione_tipo_desc,
		v1.missione_code				missione_code,
		v1.missione_desc				missione_desc,
		v1.programma_tipo_desc			programma_tipo_desc,
		v1.programma_code				programma_code,
		v1.programma_desc				programma_desc,
		v1.titusc_tipo_desc				titusc_tipo_desc,
		v1.titusc_code					titusc_code,
		v1.titusc_desc					titusc_desc,
		v1.macroag_tipo_desc			macroag_tipo_desc,
		v1.macroag_code					macroag_code,
		v1.macroag_desc					macroag_desc,
    	tb.bil_anno   					BIL_ANNO,
        tb.elem_code     				BIL_ELE_CODE,
        tb.elem_code2     				BIL_ELE_CODE2,
        tb.elem_code3					BIL_ELE_CODE3,
		tb.elem_desc     				BIL_ELE_DESC,
        tb.elem_desc2     				BIL_ELE_DESC2,
        tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
    	tb1.stanziamento_prev_anno		stanziamento_prev_anno,
    	tb1.stanziamento_prev_anno1		stanziamento_prev_anno1,
    	tb1.stanziamento_prev_anno2		stanziamento_prev_anno2,
   	 	tb1.stanziamento_prev_res_anno	stanziamento_prev_res_anno,
    	tb1.stanziamento_anno_prec		stanziamento_anno_prec,
    	tb1.stanziamento_prev_cassa_anno	stanziamento_prev_cassa_anno,
        v1.ente_proprietario_id,
        user_table utente,
        tbprec.elem_id_old,
        tb.codice_pdc					codice_pdc,
        tb1.stanziamento_fpv_anno_prec	stanziamento_fpv_anno_prec,
  		tb1.stanziamento_fpv_anno		stanziamento_fpv_anno,
  		tb1.stanziamento_fpv_anno1		stanziamento_fpv_anno1,
  		tb1.stanziamento_fpv_anno2		stanziamento_fpv_anno2
from   
	siac_rep_mis_pro_tit_mac_riga_anni v1
			FULL  join siac_rep_cap_up tb
           on    	(v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					--and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)     
            left	join    siac_rep_cap_up_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id
            	and	tb.utente=user_table
                and tb1.utente	=	tb.utente) 	
            left JOIN siac_r_bil_elem_rel_tempo tbprec 
            ON tbprec.elem_id = tb.elem_id
    where v1.utente = user_table      
           order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID;

raise notice 'ora dopo siac_rep_mptm_up_cap_importi : % ',clock_timestamp()::varchar; 

/*
 if classifBilRec.fase_bilancio = 'P'  then
 	tipo_capitolo:=elemTipoCode_UG;
 else
 	tipo_capitolo:=elemTipoCode;
 end if;
 */
 
 tipo_capitolo:=elemTipoCode_UG;
 
 raise notice 'anno_bil_impegni  %',anno_bil_impegni;
 raise notice 'tipo_capitolo  %',tipo_capitolo;
 
 raise notice 'tipo capitolo % ', tipo_capitolo;
 
 /*
      insert into siac_rep_impegni	
      select 
      capitolo.elem_id,
      movimento.movgest_anno,
      p_ente_prop_id, -------anno_eserc.ente_proprietario_id,
      user_table utente,
      sum (dt_movimento.movgest_ts_det_importo)importo
 	  from siac_t_bil 				bilancio, 
      siac_t_periodo 				anno_eserc, 
      siac_t_bil_elem 				capitolo , 
      siac_r_movgest_bil_elem 		r_mov_capitolo, 
      siac_d_bil_elem_tipo 			t_capitolo, 
      siac_t_movgest 				movimento, 
      siac_d_movgest_tipo 			tipo_mov, 
      siac_t_movgest_ts 			ts_movimento, 
      siac_r_movgest_ts_stato 		r_movimento_stato, 
      siac_d_movgest_stato 			tipo_stato, 
      siac_t_movgest_ts_det 		dt_movimento, 
      siac_d_movgest_ts_tipo 		ts_mov_tipo, 
      siac_d_movgest_ts_det_tipo 	dt_mov_tipo 
      where bilancio.periodo_id 				= anno_eserc.periodo_id 
      and anno_eserc.anno 						=  anno_bil_impegni 
      and bilancio.bil_id						=capitolo.bil_id
      and movimento.bil_id 						= bilancio.bil_id 
      and capitolo.elem_tipo_id	 				= t_capitolo.elem_tipo_id
      and t_capitolo.elem_tipo_code				=	tipo_capitolo	
      and movimento.movgest_anno::text in (annoCapImp, annoCapImp1, annoCapImp2) 
      and r_mov_capitolo.elem_id				=capitolo.elem_id
      and r_mov_capitolo.movgest_id 			= movimento.movgest_id 
      and movimento.movgest_tipo_id 			= tipo_mov.movgest_tipo_id 
      and tipo_mov.movgest_tipo_code 			= 'I' 
      and movimento.movgest_id 					= ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id 			= r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id 	= tipo_stato.movgest_stato_id 
      and tipo_stato.movgest_stato_code 		in ('D','N') ------ P,A,N 
      and ts_movimento.movgest_ts_tipo_id		= ts_mov_tipo.movgest_ts_tipo_id 
      and ts_mov_tipo.movgest_ts_tipo_code		= 'T' 
      and ts_movimento.movgest_ts_id 			= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id 	= dt_mov_tipo.movgest_ts_det_tipo_id 
      and dt_mov_tipo.movgest_ts_det_tipo_code	= 'A' ----- importo attuale 
      and anno_eserc.data_cancellazione 			is null 
      and bilancio.data_cancellazione 				is null 
      and capitolo.data_cancellazione 				is null 
      and r_mov_capitolo.data_cancellazione 		is null 
      and t_capitolo.data_cancellazione 			is null 
      and movimento.data_cancellazione 				is null 
      and tipo_mov.data_cancellazione 				is null 
      and r_movimento_stato.data_cancellazione 		is null 
      and ts_movimento.data_cancellazione 			is null 
      and tipo_stato.data_cancellazione 			is null 
      and dt_movimento.data_cancellazione 			is null 
      and ts_mov_tipo.data_cancellazione 			is null 
      and dt_mov_tipo.data_cancellazione 			is null
      and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
      and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
      and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
      and	now() between r_mov_capitolo.validita_inizio and coalesce (r_mov_capitolo.validita_fine, now())
      and	now() between t_capitolo.validita_inizio and coalesce (t_capitolo.validita_fine, now())
      and	now() between movimento.validita_inizio and coalesce (movimento.validita_fine, now())
      and	now() between tipo_mov.validita_inizio and coalesce (tipo_mov.validita_fine, now())
      and	now() between ts_movimento.validita_inizio and coalesce (ts_movimento.validita_fine, now())
      and	now() between r_movimento_stato.validita_inizio and coalesce (r_movimento_stato.validita_fine, now())
      and	now() between tipo_stato.validita_inizio and coalesce (tipo_stato.validita_fine, now())
      and	now() between dt_movimento.validita_inizio and coalesce (dt_movimento.validita_fine, now())
      and	now() between dt_mov_tipo.validita_inizio and coalesce (dt_mov_tipo.validita_fine, now())  
      and	now() between ts_mov_tipo.validita_inizio and coalesce (ts_mov_tipo.validita_fine, now()) 
      and anno_eserc.ente_proprietario_id 		= p_ente_prop_id 
      and bilancio.ente_proprietario_id 		= anno_eserc.ente_proprietario_id
      and capitolo.ente_proprietario_id 		= anno_eserc.ente_proprietario_id
      and r_mov_capitolo.ente_proprietario_id	= anno_eserc.ente_proprietario_id 
      and t_capitolo.ente_proprietario_id 		= anno_eserc.ente_proprietario_id
      and movimento.ente_proprietario_id 		= anno_eserc.ente_proprietario_id
      and tipo_mov.ente_proprietario_id 		= anno_eserc.ente_proprietario_id 
      and ts_movimento.ente_proprietario_id 	= anno_eserc.ente_proprietario_id 
      and r_movimento_stato.ente_proprietario_id = anno_eserc.ente_proprietario_id
      and tipo_stato.ente_proprietario_id 		= anno_eserc.ente_proprietario_id
      and dt_movimento.ente_proprietario_id 	= anno_eserc.ente_proprietario_id
      and ts_mov_tipo.ente_proprietario_id 		= anno_eserc.ente_proprietario_id
      and dt_mov_tipo.ente_proprietario_id 		= anno_eserc.ente_proprietario_id
      group by capitolo.elem_id, movimento.movgest_anno; ----------, anno_eserc.ente_proprietario_id;
 */
 
      RTN_MESSAGGIO:='insert tabella siac_rep_impegni''.'; 
 
 raise notice 'ora prima siac_rep_impegni : % ',clock_timestamp()::varchar; 
 
----------------------------------------------------------------------------------------------------
--------  TABELLA TEMPORANEA PER ACQUISIRE L'IMPORTO DEL CUI GIA' IMPEGNATO 
--------  sostituisce momentaneamente le due query successive.
raise notice '9: %', clock_timestamp()::varchar;      
      RTN_MESSAGGIO:='insert tabella siac_rep_impegni_riga''.'; 
insert into  siac_rep_impegni_riga
select 	tb2.elem_id,
		tb2.dicuiimpegnato_anno1,
        tb2.dicuiimpegnato_anno2,
        tb2.dicuiimpegnato_anno3,
        p_ente_prop_id,
        user_table utente
from 	siac_t_dicuiimpegnato_bilprev 	tb2,
		siac_t_periodo 					anno_eserc,
    	siac_t_bil 						bilancio
where 	tb2.ente_proprietario_id = p_ente_prop_id				AND
		anno_eserc.anno= p_anno									and
        bilancio.periodo_id=anno_eserc.periodo_id				and
		tb2.bil_id = bilancio.bil_id;
	 
/*    
insert into siac_rep_impegni
select tb2.elem_id,
tb.movgest_anno,
p_ente_prop_id,
user_table utente,
tb.importo 
from (
select    
capitolo.elem_id,
movimento.movgest_anno,
capitolo.elem_code,
capitolo.elem_code2,
capitolo.elem_code3,
sum (dt_movimento.movgest_ts_det_importo) importo
    from 
      siac_t_bil      bilancio, 
      siac_t_periodo     anno_eserc, 
      siac_t_bil_elem     capitolo , 
      siac_r_movgest_bil_elem   r_mov_capitolo, 
      siac_d_bil_elem_tipo    t_capitolo, 
      siac_t_movgest     movimento, 
      siac_d_movgest_tipo    tipo_mov, 
      siac_t_movgest_ts    ts_movimento, 
      siac_r_movgest_ts_stato   r_movimento_stato, 
      siac_d_movgest_stato    tipo_stato, 
      siac_t_movgest_ts_det   dt_movimento, 
      siac_d_movgest_ts_tipo   ts_mov_tipo, 
      siac_d_movgest_ts_det_tipo  dt_mov_tipo 
      where 
           bilancio.periodo_id     = anno_eserc.periodo_id 
      and anno_eserc.anno       =   anno_bil_impegni  
      and bilancio.bil_id      =capitolo.bil_id
      -----and movimento.bil_id       = bilancio.bil_id 
      and capitolo.elem_tipo_id      = t_capitolo.elem_tipo_id
      and t_capitolo.elem_tipo_code    = 'CAP-UG' 
      -------and movimento.movgest_anno ::text in (annoCapImp, annoCapImp1, annoCapImp2)
      and movimento.movgest_anno  in (annoCapImp_int, annoCapImp1_int, annoCapImp2_int)
      and r_mov_capitolo.elem_id    =capitolo.elem_id
      and r_mov_capitolo.movgest_id    = movimento.movgest_id 
      and movimento.movgest_tipo_id    = tipo_mov.movgest_tipo_id 
      and tipo_mov.movgest_tipo_code    = 'I' 
      and movimento.movgest_id      = ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    = r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
      and ts_movimento.movgest_ts_id    = dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      ------and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
      ------and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
      -------and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
      ---------and	now() between r_mov_capitolo.validita_inizio and coalesce (r_mov_capitolo.validita_fine, now())
      ------and	now() between t_capitolo.validita_inizio and coalesce (t_capitolo.validita_fine, now())
      -----and	now() between movimento.validita_inizio and coalesce (movimento.validita_fine, now())
      ---------and	now() between tipo_mov.validita_inizio and coalesce (tipo_mov.validita_fine, now())
      -------and	now() between ts_movimento.validita_inizio and coalesce (ts_movimento.validita_fine, now())
      -------and	now() between r_movimento_stato.validita_inizio and coalesce (r_movimento_stato.validita_fine, now())
      --------and	now() between tipo_stato.validita_inizio and coalesce (tipo_stato.validita_fine, now())
      -------and	now() between dt_movimento.validita_inizio and coalesce (dt_movimento.validita_fine, now())
      ------and	now() between dt_mov_tipo.validita_inizio and coalesce (dt_mov_tipo.validita_fine, now())  
      --------and	now() between ts_mov_tipo.validita_inizio and coalesce (ts_mov_tipo.validita_fine, now()) 
      and anno_eserc.data_cancellazione    is null 
      and bilancio.data_cancellazione     is null 
      and capitolo.data_cancellazione     is null 
      and r_mov_capitolo.data_cancellazione   is null 
      and t_capitolo.data_cancellazione    is null 
      and movimento.data_cancellazione     is null 
      and tipo_mov.data_cancellazione     is null 
      and r_movimento_stato.data_cancellazione   is null 
      and ts_movimento.data_cancellazione    is null 
      and tipo_stato.data_cancellazione    is null 
      and dt_movimento.data_cancellazione    is null 
      and ts_mov_tipo.data_cancellazione    is null 
      and dt_mov_tipo.data_cancellazione    is null
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id
group by capitolo.elem_id, movimento.movgest_anno)
tb 
,
(select * from  siac_t_bil_elem    capitolo_up,
      siac_d_bil_elem_tipo    t_capitolo_up
      where capitolo_up.elem_tipo_id=t_capitolo_up.elem_tipo_id 
      and t_capitolo_up.elem_tipo_code = 'CAP-UP') tb2
where
 tb2.elem_code =tb.elem_code and 
 tb2.elem_code2 =tb.elem_code2 
and tb2.elem_code3 =tb.elem_code3
;    
      

raise notice 'anno  %',annoCapImp;
raise notice 'anno  %',annoCapImp1;
raise notice 'anno  %',annoCapImp2;

      RTN_MESSAGGIO:='insert tabella siac_rep_impegni_riga''.'; 
      
  raise notice 'ora dopo siac_rep_impegni : % ',clock_timestamp()::varchar; 
 
  raise notice 'ora prima siac_rep_impegni_riga : % ',clock_timestamp()::varchar; 
      
insert into siac_rep_impegni_riga
select 
    v1.elem_id,
    v1.importo	as impegnato_anno,
    v2.importo	as impegnato_anno1,
    v3.importo	as impegnato_anno2,
    v1.ente_proprietario,
    v1.utente	         
         from siac_rep_impegni v1, siac_rep_impegni v2, siac_rep_impegni v3
where v1.elem_id=v2.elem_id
and v1.periodo_anno::integer+1=v2.periodo_anno::INTEGER
and v3.elem_id=v1.elem_id
and v1.periodo_anno::integer+2=v3.periodo_anno::INTEGER
and v1.periodo_anno=annoCapImp
union
--2015, 2016 
 select v1.elem_id,
    v1.importo	as impegnato_anno,
    v2.importo	as impegnato_anno1,
    NULL as impegnato_anno2,
    v1.ente_proprietario,
    v1.utente	         
         from siac_rep_impegni v1, siac_rep_impegni v2--, siac_rep_impegni v3
where v1.elem_id=v2.elem_id
and v1.periodo_anno::integer+1=v2.periodo_anno::INTEGER
and v1.periodo_anno=annoCapImp
and not exists (select 1 from siac_rep_impegni v3 where v3.elem_id=v1.elem_id and 
v1.periodo_anno::integer+2=v3.periodo_anno::INTEGER
)
union
--2015, 2017
select 
v1.elem_id,
    v1.importo	as impegnato_anno,
    NULL as impegnato_anno1,
    v2.importo	as impegnato_anno2,
    v1.ente_proprietario,
    v1.utente	         
         from siac_rep_impegni v1, siac_rep_impegni v2--, siac_rep_impegni v3
where v1.elem_id=v2.elem_id
and v1.periodo_anno::integer+2=v2.periodo_anno::INTEGER
and v1.periodo_anno=annoCapImp
and not exists (select 1 from siac_rep_impegni v3 where v3.elem_id=v1.elem_id and 
v1.periodo_anno::integer+1=v3.periodo_anno::INTEGER
)
union
--2016, 2017
 select 
 v1.elem_id,
    NULL as impegnato_anno,
    v1.importo	as impegnato_anno1,
    v2.importo	as impegnato_anno2,
    v1.ente_proprietario,
    v1.utente	         
         from siac_rep_impegni v1, siac_rep_impegni v2--, siac_rep_impegni v3
where v1.elem_id=v2.elem_id
and v1.periodo_anno::integer+1=v2.periodo_anno::INTEGER
and v1.periodo_anno=annoCapImp1
and not exists (select 1 from siac_rep_impegni v3 where v3.elem_id=v1.elem_id and 
v1.periodo_anno::integer-1=v3.periodo_anno::INTEGER
)
 union --solo 2015
select 
v1.elem_id,
    v1.importo	as impegnato_anno,
    NULL as impegnato_anno1,
    NULL as impegnato_anno2,
    v1.ente_proprietario,
    v1.utente	
from siac_rep_impegni v1 where  v1.periodo_anno=annoCapImp
and v1.elem_id in (         
select v.elem_id from siac_rep_impegni v
group by v.elem_id
having count(*)=1)
 union --solo 2016
select 
v1.elem_id,
    null as impegnato_anno,
    v1.importo as impegnato_anno1,
    NULL as impegnato_anno2,
    v1.ente_proprietario,
    v1.utente	
from siac_rep_impegni v1 where  v1.periodo_anno=annoCapImp1
and v1.elem_id in (         
select v.elem_id from siac_rep_impegni v
group by v.elem_id
having count(*)=1)
 union --solo 2017
select 
v1.elem_id,
null 	as impegnato_anno,
NULL as impegnato_anno1,
v1.importo as impegnato_anno2,  
    v1.ente_proprietario,
    v1.utente	
from siac_rep_impegni v1 where  v1.periodo_anno=annoCapImp2
and v1.elem_id in (         
select v.elem_id from siac_rep_impegni v
group by v.elem_id
having count(*)=1)
; 

*/     
  raise notice 'ora dopo siac_rep_impegni_riga : % ',clock_timestamp()::varchar;       
      
/*    
insert into siac_rep_impegni_riga
select v1.elem_id,
	v1.importo	as impegnato_anno,
    v2.importo	as impegnato_anno1,
    v3.importo	as impegnato_anno2,
    v1.ente_proprietario,
    v1.utente	
from 	siac_rep_impegni v1
		   FULL  join siac_rep_impegni v2
           on    	(v1.elem_id	=	v2.elem_id
           				and v2.periodo_anno = annoCapImp1
                        )
         FULL  join siac_rep_impegni v3
           on    	(v2.elem_id	=	v3.elem_id	 
           				and v3.periodo_anno = annoCapImp2
                        )
         where	v1.periodo_anno = annoCapImp;
*/
      RTN_MESSAGGIO:='preparazione file output per fase bilancio previsione ''.'; 
      
  raise notice 'ora prima preparo output : % ',clock_timestamp()::varchar;    
select case when count(*) is null then 0 else 1 end into esiste_siac_t_dicuiimpegnato_bilprev 
from siac_t_dicuiimpegnato_bilprev where ente_proprietario_id=p_ente_prop_id limit 1;      
      
if classifBilRec.fase_bilancio = 'P' and esiste_siac_t_dicuiimpegnato_bilprev<>1 then
 	for classifBilRec in
select 	t1.missione_tipo_desc	missione_tipo_desc,
		t1.missione_code		missione_code,
		t1.missione_desc		missione_desc,
		t1.programma_tipo_desc	programma_tipo_desc,
		t1.programma_code		programma_code,
		t1.programma_desc		programma_desc,
		t1.titusc_tipo_desc		titusc_tipo_desc,
		t1.titusc_code			titusc_code,
		t1.titusc_desc			titusc_desc,
		t1.macroag_tipo_desc	macroag_tipo_desc,
		t1.macroag_code			macroag_code,
		t1.macroag_desc			macroag_desc,
    	t1.bil_anno   			BIL_ANNO,
        t1.elem_code     		BIL_ELE_CODE,
        t1.elem_code2     		BIL_ELE_CODE2,
        t1.elem_code3			BIL_ELE_CODE3,
		t1.elem_desc     		BIL_ELE_DESC,
        t1.elem_desc2     		BIL_ELE_DESC2,
        t1.elem_id      		BIL_ELE_ID,
       	t1.elem_id_padre    	BIL_ELE_ID_PADRE,
        t1.codice_pdc			codice_pdc,  
        COALESCE(t1.stanziamento_prev_anno,0)	stanziamento_prev_anno,
        COALESCE(t1.stanziamento_prev_anno1,0)	stanziamento_prev_anno1,
        COALESCE(t1.stanziamento_prev_anno2,0)	stanziamento_prev_anno2,
        COALESCE(t1.stanziamento_prev_res_anno,0)	stanziamento_prev_res_anno,
        COALESCE(t1.stanziamento_anno_prec,0)	stanziamento_anno_prec,
        COALESCE(t1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
        COALESCE(t1.stanziamento_fpv_anno_prec,0)	stanziamento_fpv_anno_prec,
        COALESCE(t1.stanziamento_fpv_anno,0)	stanziamento_fpv_anno, 
        COALESCE(t1.stanziamento_fpv_anno1,0)	stanziamento_fpv_anno1, 
        COALESCE(t1.stanziamento_fpv_anno2,0)	stanziamento_fpv_anno2, 
            --------t1.elem_id_old		elem_id_old,
        COALESCE(t2.impegnato_anno,0) impegnato_anno,
        COALESCE(t2.impegnato_anno1,0) impegnato_anno1,
        COALESCE(t2.impegnato_anno2,0) impegnato_anno2
from siac_rep_mptm_up_cap_importi t1
        left join siac_rep_impegni_riga  t2
        on (t1.elem_id_old	=	t2.elem_id
        	--and	t1.ente_proprietario_id	=	t2.ente_proprietario
            and	t1.utente	=	t2.utente
            and	t1.utente	=	user_table)
        order by missione_code,programma_code,titusc_code,macroag_code
          loop
          missione_tipo_desc:= classifBilRec.missione_tipo_desc;
          missione_code:= classifBilRec.missione_code;
          missione_desc:= classifBilRec.missione_desc;
          programma_tipo_desc:= classifBilRec.programma_tipo_desc;
          programma_code:= classifBilRec.programma_code;
          programma_desc:= classifBilRec.programma_desc;
          titusc_tipo_desc:= classifBilRec.titusc_tipo_desc;
          titusc_code:= classifBilRec.titusc_code;
          titusc_desc:= classifBilRec.titusc_desc;
          macroag_tipo_desc:= classifBilRec.macroag_tipo_desc;
          macroag_code:= classifBilRec.macroag_code;
          macroag_desc:= classifBilRec.macroag_desc;
          bil_anno:=classifBilRec.bil_anno;
          bil_ele_code:=classifBilRec.bil_ele_code;
          bil_ele_desc:=classifBilRec.bil_ele_desc;
          bil_ele_code2:=classifBilRec.bil_ele_code2;
          bil_ele_desc2:=classifBilRec.bil_ele_desc2;
          bil_ele_id:=classifBilRec.bil_ele_id;
          bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
          codice_pdc:=classifBilRec.codice_pdc;
          bil_anno:=p_anno;
          stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
          stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
          stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
          stanziamento_prev_res_anno:=classifBilRec.stanziamento_prev_res_anno;
          stanziamento_anno_prec:=classifBilRec.stanziamento_anno_prec;
          stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
          stanziamento_fpv_anno_prec:=classifBilRec.stanziamento_fpv_anno_prec;
          stanziamento_fpv_anno:=classifBilRec.stanziamento_fpv_anno; 
          stanziamento_fpv_anno1:=classifBilRec.stanziamento_fpv_anno1; 
          stanziamento_fpv_anno2:=classifBilRec.stanziamento_fpv_anno2;
          impegnato_anno:=classifBilRec.impegnato_anno;
          impegnato_anno1:=classifBilRec.impegnato_anno1;
          impegnato_anno2=classifBilRec.impegnato_anno2;
IF classifBilRec.BIL_ELE_ID IS NOT NULL THEN
		/* Cerco il settore e prendo anche l'ID dell'elemento padre per cercare poi
        	la direzione */
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
     			sett_code='999';
				sett_descr='SETTORE NON CONFIGURATO';
        
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
                 -- AND d_class_tipo.classif_tipo_desc='Centro di Respondabilità (Direzione)'
                 and d_class_tipo.classif_tipo_code='CDR'
                  and capitolo.elem_id=classifBilRec.BIL_ELE_ID
                   AND r_bil_elem_class.data_cancellazione is NULL
                   AND t_class.data_cancellazione is NULL
                   AND d_class_tipo.data_cancellazione is NULL
                   AND capitolo.data_cancellazione is NULL;	
             IF NOT FOUND THEN
             	/* se non esiste la direzione restituisco un codice fittizio */
              direz_code='999';
              direz_descr='DIREZIONE NON CONFIGURATA';         
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
          	direz_code='999';
			direz_descr='DIREZIONE NON CONFIGURATA';  
          END IF;
          END;
        
        END IF;
    END;    

ELSE
		/* se non c'è l'ID capitolo restituisco i campi vuoti */
	direz_code='';
	direz_descr='';
	sett_code='';
	sett_descr='';
END IF;      
          
--------------------------------------------------------
IF classifBilRec.BIL_ELE_ID IS NOT NULL THEN

	BEGIN    
		SELECT    d.testo 
		INTO note     
            from  	siac_t_attr    c,
        			siac_r_bil_elem_attr d    
        where 	d.elem_id =classifBilRec.BIL_ELE_ID
    	and     d.attr_id    			= 	c.attr_id
    	and     c.attr_code 			= 	'Note';
    END; 
END IF;

--------------------------------------------------------
IF classifBilRec.BIL_ELE_ID IS NOT NULL THEN

	BEGIN    
		SELECT     f."boolean"
		INTO funzioni_delegate     
            from  	siac_t_attr    			e,
        			siac_r_bil_elem_attr 	f
        where 	f.elem_id =classifBilRec.BIL_ELE_ID
    	and     f.attr_id    		=   e.attr_id
    	and     e.attr_code 		= 	'FlagFunzioniDelegate';
    END; 
END IF;

--------------------------------------------------------
IF classifBilRec.BIL_ELE_ID IS NOT NULL THEN

	BEGIN    
		SELECT    	f.classif_desc
		INTO 		ricorrente 
            from  	siac_d_class_tipo    e,
        			siac_t_class f,
        			siac_r_bil_elem_class	g 
        where 		g.elem_id =classifBilRec.BIL_ELE_ID
    	and        	g.classif_id   			= 	f.classif_id
    	and			f.classif_tipo_id		=	e.classif_tipo_id
    	and			e.classif_tipo_code		=	'RICORRENTE_SPESA';
    END; 
END IF;


-----------------------------


--------------------------------------------------------
IF classifBilRec.BIL_ELE_ID IS NOT NULL THEN

	BEGIN    
		SELECT    	f1.classif_code,
        			f1.classif_desc	
		INTO 		codice_transazione,
        			descrizione_transazione 
        from  	siac_d_class_tipo    	e1,
        		siac_t_class 			f1,
        		siac_r_bil_elem_class	g1
        where 		g1.elem_id =classifBilRec.BIL_ELE_ID
    	and        	g1.classif_id   		=   f1.classif_id
    	and			f1.classif_tipo_id		=	e1.classif_tipo_id
    	and			e1.classif_tipo_code	=	'TRANSAZIONE_UE_SPESA'
   	 	and			g1.data_cancellazione	is null;
    END; 
END IF;


return next;
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
stanziamento_fpv_anno_prec=0;
stanziamento_fpv_anno=0;
stanziamento_fpv_anno1=0;
stanziamento_fpv_anno2=0;
codice_pdc=0;
note='';
funzioni_delegate='';
ricorrente='';
codice_transazione='';
descrizione_transazione=''; 

end loop;

else
      RTN_MESSAGGIO:='preparazione file output per fase diversa da  bilancio previsione ''.'; 
 for classifBilRec in
	select 	t1.missione_tipo_desc	missione_tipo_desc,
            t1.missione_code		missione_code,
            t1.missione_desc		missione_desc,
            t1.programma_tipo_desc	programma_tipo_desc,
            t1.programma_code		programma_code,
            t1.programma_desc		programma_desc,
            t1.titusc_tipo_desc		titusc_tipo_desc,
            t1.titusc_code			titusc_code,
            t1.titusc_desc			titusc_desc,
            t1.macroag_tipo_desc	macroag_tipo_desc,
            t1.macroag_code			macroag_code,
            t1.macroag_desc			macroag_desc,
            t1.bil_anno   			BIL_ANNO,
            t1.elem_code     		BIL_ELE_CODE,
            t1.elem_code2     		BIL_ELE_CODE2,
            t1.elem_code3			BIL_ELE_CODE3,
            t1.elem_desc     		BIL_ELE_DESC,
            t1.elem_desc2     		BIL_ELE_DESC2,
            t1.elem_id      		BIL_ELE_ID,
            t1.elem_id_padre    	BIL_ELE_ID_PADRE,
            t1.codice_pdc			codice_pdc,  
            COALESCE(t1.stanziamento_prev_anno,0)	stanziamento_prev_anno,
            COALESCE(t1.stanziamento_prev_anno1,0)	stanziamento_prev_anno1,
            COALESCE(t1.stanziamento_prev_anno2,0)	stanziamento_prev_anno2,
            COALESCE(t1.stanziamento_prev_res_anno,0)	stanziamento_prev_res_anno,
            COALESCE(t1.stanziamento_anno_prec,0)	stanziamento_anno_prec,
            COALESCE(t1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
            COALESCE(t1.stanziamento_fpv_anno_prec,0)	stanziamento_fpv_anno_prec,
        	COALESCE(t1.stanziamento_fpv_anno,0)	stanziamento_fpv_anno, 
        	COALESCE(t1.stanziamento_fpv_anno1,0)	stanziamento_fpv_anno1, 
        	COALESCE(t1.stanziamento_fpv_anno2,0)	stanziamento_fpv_anno2,  
            --------t1.elem_id_old		elem_id_old,
            COALESCE(t2.impegnato_anno,0) impegnato_anno,
            COALESCE(t2.impegnato_anno1,0) impegnato_anno1,
            COALESCE(t2.impegnato_anno2,0) impegnato_anno2
    from siac_rep_mptm_up_cap_importi t1
            ----full join siac_rep_impegni_riga  t2
            left join siac_rep_impegni_riga  t2
            on (t1.elem_id	=	t2.elem_id  ---------da sostituire con   --------t1.elem_id_old	=	t2.elem_id
                --and	t1.ente_proprietario_id	=	t2.ente_proprietario
                and	t1.utente	=	t2.utente
                and	t1.utente	=	user_table)
            order by missione_code,programma_code,titusc_code,macroag_code   	
loop
      missione_tipo_desc:= classifBilRec.missione_tipo_desc;
      missione_code:= classifBilRec.missione_code;
      missione_desc:= classifBilRec.missione_desc;
      programma_tipo_desc:= classifBilRec.programma_tipo_desc;
      programma_code:= classifBilRec.programma_code;
      programma_desc:= classifBilRec.programma_desc;
      titusc_tipo_desc:= classifBilRec.titusc_tipo_desc;
      titusc_code:= classifBilRec.titusc_code;
      titusc_desc:= classifBilRec.titusc_desc;
      macroag_tipo_desc:= classifBilRec.macroag_tipo_desc;
      macroag_code:= classifBilRec.macroag_code;
      macroag_desc:= classifBilRec.macroag_desc;
      bil_anno:=classifBilRec.bil_anno;
      bil_ele_code:=classifBilRec.bil_ele_code;
      bil_ele_desc:=classifBilRec.bil_ele_desc;
      bil_ele_code2:=classifBilRec.bil_ele_code2;
      bil_ele_desc2:=classifBilRec.bil_ele_desc2;
      bil_ele_id:=classifBilRec.bil_ele_id;
      bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
      codice_pdc:=classifBilRec.codice_pdc;
      bil_anno:=p_anno;
      stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
      stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
      stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
      stanziamento_prev_res_anno:=classifBilRec.stanziamento_prev_res_anno;
      stanziamento_anno_prec:=classifBilRec.stanziamento_anno_prec;
      stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
      stanziamento_fpv_anno_prec:=classifBilRec.stanziamento_fpv_anno_prec;
      stanziamento_fpv_anno:=classifBilRec.stanziamento_fpv_anno; 
      stanziamento_fpv_anno1:=classifBilRec.stanziamento_fpv_anno1; 
      stanziamento_fpv_anno2:=classifBilRec.stanziamento_fpv_anno2;
      impegnato_anno:=classifBilRec.impegnato_anno;
      impegnato_anno1:=classifBilRec.impegnato_anno1;
      impegnato_anno2=classifBilRec.impegnato_anno2;
      IF classifBilRec.BIL_ELE_ID IS NOT NULL THEN
		/* Cerco il settore e prendo anche l'ID dell'elemento padre per cercare poi
        	la direzione */
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
     			sett_code='999';
				sett_descr='SETTORE NON CONFIGURATO';
        
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
                 -- AND d_class_tipo.classif_tipo_desc='Centro di Respondabilità (Direzione)'
                 and d_class_tipo.classif_tipo_code='CDR'
                  and capitolo.elem_id=classifBilRec.BIL_ELE_ID
                   AND r_bil_elem_class.data_cancellazione is NULL
                   AND t_class.data_cancellazione is NULL
                   AND d_class_tipo.data_cancellazione is NULL
                   AND capitolo.data_cancellazione is NULL;	
             IF NOT FOUND THEN
             	/* se non esiste la direzione restituisco un codice fittizio */
              direz_code='999';
              direz_descr='DIREZIONE NON CONFIGURATA';         
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
          	direz_code='999';
			direz_descr='DIREZIONE NON CONFIGURATA';  
          END IF;
          END;
        
        END IF;
    END;    

ELSE
		/* se non c'è l'ID capitolo restituisco i campi vuoti */
	direz_code='';
	direz_descr='';
	sett_code='';
	sett_descr='';
END IF;


--------------------------------------------------------
IF classifBilRec.BIL_ELE_ID IS NOT NULL THEN

	BEGIN    
		SELECT    d.testo 
		INTO note     
            from  	siac_t_attr    c,
        			siac_r_bil_elem_attr d    
        where 	d.elem_id =classifBilRec.BIL_ELE_ID
    	and     d.attr_id    			= 	c.attr_id
    	and     c.attr_code 			= 	'Note';
    END; 
END IF;

--------------------------------------------------------
IF classifBilRec.BIL_ELE_ID IS NOT NULL THEN

	BEGIN    
		SELECT     f."boolean"
		INTO funzioni_delegate     
            from  	siac_t_attr    			e,
        			siac_r_bil_elem_attr 	f
        where 	f.elem_id =classifBilRec.BIL_ELE_ID
    	and     f.attr_id    		=   e.attr_id
    	and     e.attr_code 		= 	'FlagFunzioniDelegate';
    END; 
END IF;

--------------------------------------------------------
IF classifBilRec.BIL_ELE_ID IS NOT NULL THEN

	BEGIN    
		SELECT    	f.classif_desc
		INTO 		ricorrente 
            from  	siac_d_class_tipo    e,
        			siac_t_class f,
        			siac_r_bil_elem_class	g 
        where 		g.elem_id =classifBilRec.BIL_ELE_ID
    	and        	g.classif_id   			= 	f.classif_id
    	and			f.classif_tipo_id		=	e.classif_tipo_id
    	and			e.classif_tipo_code		=	'RICORRENTE_SPESA';
    END; 
END IF;


-----------------------------


--------------------------------------------------------
IF classifBilRec.BIL_ELE_ID IS NOT NULL THEN

	BEGIN    
		SELECT    	f1.classif_code,
        			f1.classif_desc	
		INTO 		codice_transazione,
        			descrizione_transazione 
        from  	siac_d_class_tipo    	e1,
        		siac_t_class 			f1,
        		siac_r_bil_elem_class	g1
        where 		g1.elem_id =classifBilRec.BIL_ELE_ID
    	and        	g1.classif_id   		=   f1.classif_id
    	and			f1.classif_tipo_id		=	e1.classif_tipo_id
    	and			e1.classif_tipo_code	=	'TRANSAZIONE_UE_SPESA'
   	 	and			g1.data_cancellazione	is null;
    END; 
END IF;
	return next;
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
    stanziamento_fpv_anno_prec=0;
    stanziamento_fpv_anno=0;
    stanziamento_fpv_anno1=0;
    stanziamento_fpv_anno2=0;
    codice_pdc=0;
    note='';
    funzioni_delegate='';
    ricorrente='';
	codice_transazione='';
	descrizione_transazione=''; 

end loop;
end if;


  raise notice 'ora dopo preparo output : % ',clock_timestamp()::varchar;   

delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;
delete from siac_rep_cap_up where utente=user_table;
delete from siac_rep_cap_up_imp where utente=user_table;
delete from siac_rep_cap_up_imp_riga	where utente=user_table;
delete from siac_rep_mptm_up_cap_importi where utente=user_table;
delete from siac_rep_impegni where utente=user_table;
delete from siac_rep_impegni_riga  where utente=user_table;


raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
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