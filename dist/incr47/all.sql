/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--SIAC-6237: Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR064_Riepilogo_generale_spese"(p_ente_prop_id integer, p_anno varchar, p_bilancio varchar);

DROP FUNCTION if exists siac."BILR064_Riepilogo_generale_spese_entrate"(p_ente_prop_id integer, p_anno varchar, p_bilancio varchar);

DROP FUNCTION if exists siac."BILR998_tipo_capitolo_dei_report"(p_ente_prop_id integer, p_anno varchar);

DROP FUNCTION if exists siac."BILR998_tipo_capitolo_dei_report_tipobil"(p_ente_prop_id integer, p_anno varchar, p_fase_bilancio varchar);

CREATE OR REPLACE FUNCTION siac."BILR064_Riepilogo_generale_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_bilancio varchar
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
  spese_effettive_anno numeric
) AS
$body$
DECLARE
classifBilRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
elemTipoCode_UG	varchar;
TipoImpstanzresidui varchar;
anno_bil_impegni	varchar;
tipo_capitolo	varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;

importo integer :=0;
v_fam_missioneprogramma varchar;
v_fam_titolomacroaggregato varchar;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo

v_fam_missioneprogramma :='00001';
v_fam_titolomacroaggregato := '00002';

/* in input c'e' la scelta del tipo di bilancio:
	- P = Bilancio di Previsione
    - G = Bilancio di Gestione
*/
CASE 
    WHEN p_bilancio='P' THEN
      elemTipoCode:='CAP-UP'; -- tipo capitolo previsione
 WHEN p_bilancio='G' THEN
      elemTipoCode:='CAP-UG'; -- tipo capitolo gestione      
 
END CASE;

anno_bil_impegni:= ((p_anno::INTEGER)-1)::VARCHAR;




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
spese_effettive_anno=0;


select fnc_siac_random_user()
into	user_table;

/*
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
 --and	   v.titusc_code = '1' 
 --and v.titusc_code IN ('1','2','3','4')
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
*/


-- 02/09/2016: sostituita la query di caricamento struttura del bilancio
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
    /* 02/09/2016: start filtro per mis-prog-macro*/
    /* 26/09/2016: nei report di utilita' non deve essere inserito 
    	questo filtro */
  --  , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 02/09/2016: start filtro per mis-prog-macro*/
-- AND programma.programma_id = progmacro.classif_a_id
-- AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;
 
 
 
insert into siac_rep_cap_up
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
    /*capitolo.ente_proprietario_id= bilancio.ente_proprietario_id			and
	capitolo.ente_proprietario_id= tipo_elemento.ente_proprietario_id		and
	capitolo.ente_proprietario_id= anno_eserc.ente_proprietario_id 			and
    capitolo.ente_proprietario_id= programma_tipo.ente_proprietario_id 		and
    capitolo.ente_proprietario_id= programma.ente_proprietario_id 			and
    capitolo.ente_proprietario_id= macroaggr_tipo.ente_proprietario_id 		and
    capitolo.ente_proprietario_id= macroaggr.ente_proprietario_id 			and
    capitolo.ente_proprietario_id= r_capitolo_programma.ente_proprietario_id and
    capitolo.ente_proprietario_id= r_capitolo_macroaggr.ente_proprietario_id and
    capitolo.ente_proprietario_id= stato_capitolo.ente_proprietario_id 		 and
    capitolo.ente_proprietario_id= r_capitolo_stato.ente_proprietario_id 	 and
    capitolo.ente_proprietario_id= cat_del_capitolo.ente_proprietario_id 	 and
    capitolo.ente_proprietario_id= r_cat_capitolo.ente_proprietario_id 		 and*/
   	anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id						and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
	cat_del_capitolo.elem_cat_code	=	'STD'								
    and	now() between programma.validita_inizio and coalesce (programma.validita_fine, now()) 
	and	now() between macroaggr.validita_inizio and coalesce (macroaggr.validita_fine, now())
    and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
    and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
    and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
    and	now() between programma_tipo.validita_inizio and coalesce (programma_tipo.validita_fine, now())
    and	now() between macroaggr_tipo.validita_inizio and coalesce (macroaggr_tipo.validita_fine, now())
    and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
    and	now() between r_capitolo_programma.validita_inizio and coalesce (r_capitolo_programma.validita_fine, now())
    and	now() between r_capitolo_macroaggr.validita_inizio and coalesce (r_capitolo_macroaggr.validita_fine, now())
    and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
    and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
    and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
    and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
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
  

insert into siac_rep_cap_up_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo)       
from 		siac_t_bil_elem_det 			capitolo_importi,
         	siac_d_bil_elem_det_tipo 		capitolo_imp_tipo,
         	siac_t_periodo 					capitolo_imp_periodo,
            siac_t_bil_elem 				capitolo,
            siac_d_bil_elem_tipo 			tipo_elemento,
            siac_t_bil 						bilancio,	
	 		siac_t_periodo 					anno_eserc, 
	 		siac_d_bil_elem_stato 			stato_capitolo, 
     		siac_r_bil_elem_stato 			r_capitolo_stato,
	 		siac_d_bil_elem_categoria	 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 		r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
    	and	anno_eserc.anno							=p_anno 												
    	and	bilancio.periodo_id						=anno_eserc.periodo_id 								
        and	capitolo.bil_id							=bilancio.bil_id 			 
        and	capitolo.elem_id						=capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id					=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 			=elemTipoCode
        and	capitolo_importi.elem_det_tipo_id		=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)       
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		
		and	cat_del_capitolo.elem_cat_code	=	'STD'								
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
    group by   capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_up_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		spese_effettive_anno,--stanziamento_prev_anno,
    	0,
    	0,
   	 	0,
    	0,
    	0,
          0,0,0,0,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_up_imp tb1
	where			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	;
                    
                 

for classifBilRec in
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
        --COALESCE(tb1.stanziamento_prev_anno,0)	stanziamento_prev_anno
        COALESCE(tb1.stanziamento_prev_anno,0)	spese_effettive_anno        
from   
-- 02/07/2018. Nell'ambito della SIAC-6237, corretta l'estrazione dati
--  per quanto riguarda la gestione dell'utente.
	siac_rep_mis_pro_tit_mac_riga_anni v1
			-----FULL  join siac_rep_cap_up tb
         	LEFT  join siac_rep_cap_up tb
           on    	(v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					AND TB.utente=V1.utente)     
            LEFT	join    siac_rep_cap_up_imp_riga tb1  
            	on (tb1.elem_id	=	tb.elem_id 	 
                	and tb1.utente = tb.utente)
where  v1.utente=user_table
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
  bil_anno:=p_anno;
  --stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
  
  spese_effettive_anno:=classifBilRec.spese_effettive_anno;

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
  --stanziamento_prev_anno=0;
  spese_effettive_anno=0;

end loop;

raise notice 'fine OK';

delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;
delete from siac_rep_cap_up where utente=user_table;
delete from siac_rep_cap_up_imp where utente=user_table;
delete from siac_rep_cap_up_imp_riga where utente=user_table;

exception
when no_data_found THEN
raise notice 'nessun dato trovato per struttura bilancio';
return;
when others  THEN
RTN_MESSAGGIO:='struttura bilancio altro errore';
RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR064_Riepilogo_generale_spese_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_bilancio varchar
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
  stanziamento_prev_anno numeric
) AS
$body$
DECLARE
classifBilRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
TipoImpresidui varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
v_fam_titolotipologiacategoria varchar:='00003';


BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpresidui='STR'; -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
TipoImpCassa ='SCA'; ----- previsioni di cassa

/* in input c'e' la scelta del tipo di bilancio:
	- P = Bilancio di Previsione
    - G = Bilancio di Gestione
*/
CASE 
    WHEN p_bilancio='P' THEN
      elemTipoCode:='CAP-EP'; -- tipo capitolo previsione
 WHEN p_bilancio='G' THEN
      elemTipoCode:='CAP-EG'; -- tipo capitolo gestione      
 
END CASE;
--elemTipoCode:='CAP-EP'; -- tipo capitolo previsione

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
stanziamento_prev_anno=0;
--stanziamento_prev_anno1=0;
--stanziamento_prev_anno2=0;
--residui_presunti:=0;
--previsioni_anno_prec:=0;
--stanziamento_prev_cassa_anno:=0;


select fnc_siac_random_user()
into	user_table;


/*
insert into  siac_rep_tit_tip_cat_riga_anni
select v.*,user_table from
(SELECT v3.classif_tipo_desc AS classif_tipo_desc1, v3.classif_id AS titolo_id,
    v3.classif_code AS titolo_code, v3.classif_desc AS titolo_desc,
    v3.validita_inizio AS titolo_validita_inizio,
    v3.validita_fine AS titolo_validita_fine,
    v2.classif_tipo_desc AS classif_tipo_desc2, v2.classif_id AS tipologia_id,
    v2.classif_code AS tipologia_code, v2.classif_desc AS tipologia_desc,
    v2.validita_inizio AS tipologia_validita_inizio,
    v2.validita_fine AS tipologia_validita_fine,
    v1.classif_tipo_desc AS classif_tipo_desc3, v1.classif_id AS categoria_id,
    v1.classif_code AS categoria_code, v1.classif_desc AS categoria_desc,
    v1.validita_inizio AS categoria_validita_inizio,
    v1.validita_fine AS categoria_validita_fine, v1.ente_proprietario_id
FROM (SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v1,
-------------siac_v_tit_tip_cat_anni v1,
(SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v2, 
----------siac_v_tit_tip_cat_anni v2,
(SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id
     AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v3
---------------    siac_v_tit_tip_cat_anni v3
WHERE v1.classif_id_padre = v2.classif_id AND v1.classif_tipo_desc::text =
    'Categoria'::text AND v2.classif_tipo_desc::text = 'Tipologia'::text 
    AND v2.classif_id_padre = v3.classif_id AND v3.classif_tipo_desc::text = 'Titolo Entrata'::text 
    AND v1.ente_proprietario_id = v2.ente_proprietario_id AND v2.ente_proprietario_id = v3.ente_proprietario_id) v
---------siac_v_tit_tip_cat_riga_anni 
where v.ente_proprietario_id=p_ente_prop_id 
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.categoria_validita_inizio and
COALESCE(v.categoria_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.tipologia_validita_inizio and
COALESCE(v.tipologia_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.titolo_validita_inizio and
COALESCE(v.titolo_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
order by titolo_code, tipologia_code,categoria_code;
*/


-- 02/09/2016: cambiata la query che carica la struttura di bilancio
--   per motivi prestazionali
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
 titent.titent_code, tipologia.tipologia_code,categoria.categoria_code
 ;

insert into siac_rep_cap_ep
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
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and	cat_del_capitolo.elem_cat_code	=	'STD'
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
and	cat_del_capitolo.data_cancellazione	is null
and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now());


insert into siac_rep_cap_ep_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	------coalesce (sum(capitolo_importi.elem_det_importo),0)    
            sum(capitolo_importi.elem_det_importo)     
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
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD'
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
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
    group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id, 
  		coalesce (tb1.importo,0)   as 		stanziamento_prev_anno,
        coalesce (tb2.importo,0)   as 		stanziamento_prev_anno1,
        coalesce (tb3.importo,0)   as 		stanziamento_prev_anno2,
        coalesce (tb4.importo,0)   as 		residui_presunti,
        coalesce (tb5.importo,0)   as 		previsioni_anno_prec,
        coalesce (tb6.importo,0)   as 		stanziamento_prev_cassa_anno,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1, siac_rep_cap_ep_imp tb2, siac_rep_cap_ep_imp tb3,
	siac_rep_cap_ep_imp tb4, siac_rep_cap_ep_imp tb5, siac_rep_cap_ep_imp tb6
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb3.elem_id	=	tb4.elem_id								and
        			tb4.elem_id	=	tb5.elem_id								and
        			tb5.elem_id	=	tb6.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp	AND
        			tb4.periodo_anno = tb1.periodo_anno	AND	tb4.tipo_imp = 	TipoImpresidui	AND
        			tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzresidui	AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	TipoImpCassa;
--------raise notice 'dopo insert siac_rep_cap_ep_imp_riga' ;                    

for classifBilRec in
select 	v1.classif_tipo_desc1    		titoloe_TIPO_DESC,
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
	   	COALESCE (tb1.stanziamento_prev_anno,0)			stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2,
   	 	COALESCE (tb1.residui_presunti,0)				residui_presunti,
    	COALESCE (tb1.previsioni_anno_prec,0)			previsioni_anno_prec,
    	COALESCE (tb1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno
from  	
	-- 02/07/2018. Nell'ambito della SIAC-6237, corretta l'estrazione dati
	--  per quanto riguarda la gestione dell'utente.
	siac_rep_tit_tip_cat_riga_anni v1
			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					--and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente)
           --------RIGHT	join    siac_rep_cap_ep_imp_riga tb1  on tb1.elem_id	=	tb.elem_id 	
           left	join    siac_rep_cap_ep_imp_riga tb1  
           			on (tb1.elem_id	=	tb.elem_id 
                    	and tb1.utente = tb.utente)
where  v1.utente=user_table
order by titoloe_CODE,tipologia_CODE,categoria_CODE            

loop

/*raise notice 'Dentro loop estrazione capitoli elem_id % ',classifBilRec.bil_ele_id;*/

-- dati capitolo

titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
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
stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
----stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
----stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
----stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
----residui_presunti:=classifBilRec.residui_presunti;
----previsioni_anno_prec:=classifBilRec.previsioni_anno_prec;


-- importi capitolo

/*raise notice 'record';*/
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
stanziamento_prev_anno=0;
--stanziamento_prev_anno1=0;
--stanziamento_prev_anno2=0;
--residui_presunti:=0;
--previsioni_anno_prec:=0;
--stanziamento_prev_cassa_anno:=0;

end loop;
delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_tit_tip_cat_riga where utente=user_table;

delete from siac_rep_cap_ep where utente=user_table;

delete from siac_rep_cap_ep_imp where utente=user_table;

delete from siac_rep_cap_ep_imp_riga where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='capitolo altro errore';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR998_tipo_capitolo_dei_report" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  anno_competenza varchar,
  importo numeric,
  descrizione varchar,
  posizione_nel_report integer,
  codice_importo varchar
) AS
$body$
DECLARE

classifBilRec record;
tipo_capitolo record;
tipoAvanzo varchar;
tipoDisavanzo varchar;
tipoFpvcc varchar;
tipoFpvsc varchar;
tipoFCassaIni varchar;
elemTipoCodeE varchar;
elemTipoCodeS varchar;
RTN_MESSAGGIO varchar(1000):='';

fase_bilancio varchar;

BEGIN

anno_competenza='';
importo=0;
descrizione='';
posizione_nel_report=0;
codice_importo='';
tipoAvanzo='AAM';
tipoDisavanzo='DAM';
tipoFpvcc='FPVCC';
tipoFpvsc='FPVSC';
tipoFCassaIni='FCI';

begin
for classifBilRec in
select 	anno_eserc.anno bil_anno, 
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

raise notice 'Fase bilancio  %',classifBilRec.fase_bilancio;

-- 02/07/2018: nell'ambito della SIAC-6237 corretto un errore:
-- la variabile "fase_bilancio" era utilizzata nel test ma mai assegnata,
-- di conseguenza il report estraeva sempre i dati di gestione 
--indipendentemente dalla fase bilancio.
fase_bilancio := classifBilRec.fase_bilancio;

  if fase_bilancio = 'P'  then
     	elemTipoCodeE:='CAP-EP'; -- tipo capitolo previsione
    	elemTipoCodeS:='CAP-UP'; -- tipo capitolo previsione
  else
      	elemTipoCodeE:='CAP-EG'; -- tipo capitolo previsione
    	elemTipoCodeS:='CAP-UG'; -- tipo capitolo previsione
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

        for tipo_capitolo in 
        select 		
			capitolo_imp_periodo.anno          anno_competenza,
            cat_del_capitolo.elem_cat_code	   codice_importo,
            sum(coalesce(capitolo_importi.elem_det_importo,0)) importo  
        from 		
            siac_t_bil_elem_det capitolo_importi,
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
        and	tipo_elemento.elem_tipo_code 		in (elemTipoCodeE,elemTipoCodeS)
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
        and	capitolo_imp_tipo.elem_det_tipo_code	=	'STA' 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno           = p_anno
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
--		and	cat_del_capitolo.elem_cat_code		in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc,tipoFCassaIni)	
        and	cat_del_capitolo.elem_cat_code		in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc)	
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
        group by cat_del_capitolo.elem_cat_code, capitolo_imp_periodo.anno
        union
                select 		
			capitolo_imp_periodo.anno          anno_competenza,
            cat_del_capitolo.elem_cat_code	   codice_importo,
            sum(coalesce(capitolo_importi.elem_det_importo,0)) importo  
        from 		
            siac_t_bil_elem_det capitolo_importi,
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
        and	tipo_elemento.elem_tipo_code 		in (elemTipoCodeE,elemTipoCodeS)
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
        and	capitolo_imp_tipo.elem_det_tipo_code	=	'SCA' 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno           = p_anno
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
--		and	cat_del_capitolo.elem_cat_code		in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc,tipoFCassaIni)	
        and	cat_del_capitolo.elem_cat_code		in (tipoFCassaIni)	
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
        group by cat_del_capitolo.elem_cat_code, capitolo_imp_periodo.anno
        
loop
     
       anno_competenza := tipo_capitolo.anno_competenza;
       codice_importo := tipo_capitolo.codice_importo;
       importo := tipo_capitolo.importo;
       descrizione := '';
       posizione_nel_report := 0;

       return next;

       anno_competenza='';
       importo=0;
       descrizione='';
       posizione_nel_report=0;
       codice_importo='';

end loop;

raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
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

CREATE OR REPLACE FUNCTION siac."BILR998_tipo_capitolo_dei_report_tipobil" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_fase_bilancio varchar
)
RETURNS TABLE (
  anno_competenza varchar,
  importo numeric,
  descrizione varchar,
  posizione_nel_report integer,
  codice_importo varchar
) AS
$body$
DECLARE

classifBilRec record;
tipo_capitolo record;
tipoAvanzo varchar;
tipoDisavanzo varchar;
tipoFpvcc varchar;
tipoFpvsc varchar;
tipoFCassaIni varchar;
elemTipoCodeE varchar;
elemTipoCodeS varchar;
RTN_MESSAGGIO varchar(1000):='';

fase_bilancio varchar;

BEGIN

anno_competenza='';
importo=0;
descrizione='';
posizione_nel_report=0;
codice_importo='';
tipoAvanzo='AAM';
tipoDisavanzo='DAM';
tipoFpvcc='FPVCC';
tipoFpvsc='FPVSC';
tipoFCassaIni='FCI';

/* funzione creata per il report BILR064 per permettere di leggere i valori
   di Previsione / Gestione in base ad un paramentro di input */
   
if p_fase_bilancio = 'P'  then
      elemTipoCodeE:='CAP-EP'; -- tipo capitolo previsione
      elemTipoCodeS:='CAP-UP'; -- tipo capitolo previsione
else
      elemTipoCodeE:='CAP-EG'; -- tipo capitolo previsione
      elemTipoCodeS:='CAP-UG'; -- tipo capitolo previsione
end if;


for tipo_capitolo in 
  select 		
      capitolo_imp_periodo.anno          anno_competenza,
      cat_del_capitolo.elem_cat_code	   codice_importo,
      sum(coalesce(capitolo_importi.elem_det_importo,0)) importo  
  from 		
      siac_t_bil_elem_det capitolo_importi,
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
  and	tipo_elemento.elem_tipo_code 		in (elemTipoCodeE,elemTipoCodeS)
  and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
  and	capitolo_imp_tipo.elem_det_tipo_code	=	'STA' 		
  and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
  and	capitolo_imp_periodo.anno           = p_anno
  and	capitolo.elem_id					=	r_capitolo_stato.elem_id
  and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
  and	stato_capitolo.elem_stato_code		=	'VA'
  and	capitolo.elem_id					=	r_cat_capitolo.elem_id
  and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
--		and	cat_del_capitolo.elem_cat_code		in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc,tipoFCassaIni)	
  and	cat_del_capitolo.elem_cat_code		in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc)	
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
  group by cat_del_capitolo.elem_cat_code, capitolo_imp_periodo.anno
  union
  select 		
      capitolo_imp_periodo.anno          anno_competenza,
      cat_del_capitolo.elem_cat_code	   codice_importo,
      sum(coalesce(capitolo_importi.elem_det_importo,0)) importo  
  from 		
      siac_t_bil_elem_det capitolo_importi,
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
  and	tipo_elemento.elem_tipo_code 		in (elemTipoCodeE,elemTipoCodeS)
  and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
  and	capitolo_imp_tipo.elem_det_tipo_code	=	'SCA' 		
  and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
  and	capitolo_imp_periodo.anno           = p_anno
  and	capitolo.elem_id					=	r_capitolo_stato.elem_id
  and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
  and	stato_capitolo.elem_stato_code		=	'VA'
  and	capitolo.elem_id					=	r_cat_capitolo.elem_id
  and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
--		and	cat_del_capitolo.elem_cat_code		in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc,tipoFCassaIni)	
  and	cat_del_capitolo.elem_cat_code		in (tipoFCassaIni)	
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
  group by cat_del_capitolo.elem_cat_code, capitolo_imp_periodo.anno
        
loop
     
       anno_competenza := tipo_capitolo.anno_competenza;
       codice_importo := tipo_capitolo.codice_importo;
       importo := tipo_capitolo.importo;

       descrizione := '';
       posizione_nel_report := 0;

       return next;

       anno_competenza='';
       importo=0;
       descrizione='';
       posizione_nel_report=0;
       codice_importo='';

end loop;

raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
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




/* annullamento variabili report BILR052 */
UPDATE
  siac.siac_t_report_importi
SET
  validita_fine = now(),
  data_cancellazione = now(),
  data_modifica = now(),
  login_operazione = login_operazione ||' - SIAC-6237'
WHERE
  repimp_id in ( 
select a.repimp_id
from siac_t_report_importi a, siac_t_bil b, siac_t_report c,
 siac_r_report_importi d
where 
a.repimp_codice in ('fondo_cassa_rend')
and a.bil_id=b.bil_id
and a.repimp_id= d.repimp_id
and c.rep_id=d.rep_id
and b.bil_code in ('BIL_2017','BIL_2018')
and c.rep_codice='BILR052'
and a.data_cancellazione IS NULL);


UPDATE
  siac.siac_r_report_importi
SET
  validita_fine = now(),
  data_cancellazione = now(),
  data_modifica = now(),
  login_operazione = login_operazione ||' - SIAC-6237'
WHERE
  reprimp_id in (
select c.reprimp_id
from siac_t_report_importi a, siac_t_bil b,
siac_r_report_importi c, siac_t_report d
where
a.repimp_codice in ('fondo_cassa_rend')
and a.bil_id=b.bil_id
and c.repimp_id=a.repimp_id
and c.rep_id = d.rep_id
and b.bil_code in ('BIL_2017','BIL_2018')
and d.rep_codice='BILR052'
and c.data_cancellazione IS NULL
); 

/* annullamento variabili report BILR062 */
UPDATE
  siac.siac_t_report_importi
SET
  validita_fine = now(),
  data_cancellazione = now(),
  data_modifica = now(),
  login_operazione = login_operazione ||' - SIAC-6237'
WHERE
  repimp_id in ( 
select a.repimp_id
from siac_t_report_importi a, siac_t_bil b, siac_t_report c,
 siac_r_report_importi d
where 
a.repimp_codice in ('ava_amm','fpv_sc','fpv_scc')
and a.bil_id=b.bil_id
and a.repimp_id= d.repimp_id
and c.rep_id=d.rep_id
and b.bil_code in ('BIL_2017','BIL_2018')
and c.rep_codice='BILR062'
and a.data_cancellazione IS NULL);


UPDATE
  siac.siac_r_report_importi
SET
  validita_fine = now(),
  data_cancellazione = now(),
  data_modifica = now(),
  login_operazione = login_operazione ||' - SIAC-6237'
WHERE
  reprimp_id in (
select c.reprimp_id
from siac_t_report_importi a, siac_t_bil b,
siac_r_report_importi c, siac_t_report d
where
a.repimp_codice in ('ava_amm','fpv_sc','fpv_scc')
and a.bil_id=b.bil_id
and c.repimp_id=a.repimp_id
and c.rep_id = d.rep_id
and b.bil_code in ('BIL_2017','BIL_2018')
and d.rep_codice='BILR062'
and c.data_cancellazione IS NULL
); 


/* annullamento variabili report BILR064 */
UPDATE
  siac.siac_t_report_importi
SET
  validita_fine = now(),
  data_cancellazione = now(),
  data_modifica = now(),
  login_operazione = login_operazione ||' - SIAC-6237'
WHERE
  repimp_id in ( 
select a.repimp_id
from siac_t_report_importi a, siac_t_bil b, siac_t_report c,
 siac_r_report_importi d
where 
a.repimp_codice in ('ava_amm','disava_amm','fpv_sc','fpv_scc')
and a.bil_id=b.bil_id
and a.repimp_id= d.repimp_id
and c.rep_id=d.rep_id
and b.bil_code in ('BIL_2017','BIL_2018')
and c.rep_codice='BILR064'
and a.data_cancellazione IS NULL);


UPDATE
  siac.siac_r_report_importi
SET
  validita_fine = now(),
  data_cancellazione = now(),
  data_modifica = now(),
  login_operazione = login_operazione ||' - SIAC-6237'
WHERE
  reprimp_id in (
select c.reprimp_id
from siac_t_report_importi a, siac_t_bil b,
siac_r_report_importi c, siac_t_report d
where
a.repimp_codice in ('ava_amm','disava_amm','fpv_sc','fpv_scc')
and a.bil_id=b.bil_id
and c.repimp_id=a.repimp_id
and c.rep_id = d.rep_id
and b.bil_code in ('BIL_2017','BIL_2018')
and d.rep_codice='BILR064'
and c.data_cancellazione IS NULL
); 


/* cancellazione delle variabili dalla tabella BKO per evitare che siano ricreate l'anno prossimo */
delete from  bko_t_report_importi
where rep_codice = 'BILR052'
and repimp_codice in ('fondo_cassa_rend');

delete from  bko_t_report_importi
where rep_codice = 'BILR062'
and repimp_codice in ('ava_amm','fpv_sc','fpv_scc');

delete from  bko_t_report_importi
where rep_codice = 'BILR064'
and repimp_codice in ('ava_amm','disava_amm','fpv_sc','fpv_scc');

--SIAC-6237: Maurizio - FINE


--SIAC-6275: Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR116_Stampa_riepilogo_iva"(p_ente_prop_id integer, p_anno varchar, p_mese varchar);

CREATE OR REPLACE FUNCTION siac."BILR116_Stampa_riepilogo_iva" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_mese varchar
)
RETURNS TABLE (
  bil_anno varchar,
  desc_ente varchar,
  data_registrazione date,
  cod_fisc_ente varchar,
  desc_periodo varchar,
  cod_tipo_registro varchar,
  desc_tipo_registro varchar,
  cod_registro varchar,
  desc_registro varchar,
  cod_aliquota_iva varchar,
  desc_aliquota_iva varchar,
  importo_iva_imponibile numeric,
  importo_iva_imposta numeric,
  importo_iva_totale numeric,
  tipo_reg_completa varchar,
  cod_reg_completa varchar,
  aliquota_completa varchar,
  tipo_registro varchar,
  data_emissione date,
  data_prot_def date,
  importo_iva_detraibile numeric,
  importo_iva_indetraibile numeric,
  importo_esente numeric,
  importo_split numeric,
  importo_fuori_campo numeric,
  percent_indetr numeric,
  pro_rata numeric,
  aliquota_perc numeric,
  importo_iva_split numeric,
  importo_detraibile numeric,
  importo_indetraibile numeric
) AS
$body$
DECLARE
classifBilRec record;
elencoRegistriIva record;

mese1 varchar;
anno1 varchar;

annoCapImp varchar;
annoCapImp_int integer;
TipoImpstanz varchar;
tipoImpCassa varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
ricorrente varchar;
v_id_doc integer;
v_tipo_doc varchar;

BEGIN

annoCapImp:= p_anno;
annoCapImp_int:= p_anno::integer;   

TipoImpstanzresidui='SRI'; -- stanziamento residuo iniziale (RS)
TipoImpstanz='STA'; -- stanziamento  (CP)
TipoImpCassa ='SCA'; ----- cassa	(CS)
elemTipoCode:='CAP-EG'; -- tipo capitolo previsione

bil_anno='';
desc_ente='';
data_registrazione=NULL;
cod_fisc_ente='';
desc_periodo='';
cod_tipo_registro='';
desc_tipo_registro='';
cod_registro='';
desc_registro='';
cod_aliquota_iva='';
desc_aliquota_iva='';
importo_iva_imponibile=0;
importo_iva_imposta=0;
importo_iva_totale=0;
tipo_reg_completa='';
cod_reg_completa='';
aliquota_completa='';
tipo_registro='';
data_emissione=NULL;
data_prot_def=NULL;
importo_iva_detraibile=0;
importo_iva_indetraibile=0;
importo_esente=0;
importo_split=0;
importo_fuori_campo=0;
importo_iva_split=0;
percent_indetr=0;
pro_rata=0;
aliquota_perc=0;

RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into	user_table;

if p_mese = '12' THEN
	mese1='01';
    anno1=(p_anno ::integer +1) ::varchar;
else 
	mese1=(p_mese ::integer +1) ::varchar;
    anno1=p_anno;
end if;
raise notice 'mese = %, anno = %', mese1,anno1;
raise notice 'DATA A = %', to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy');
--raise notice 'DATA A meno uno = %', to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy')-1;
 
RTN_MESSAGGIO:='Estrazione dei dati Registri IVA ''.';

FOR elencoRegistriIva IN      
  select t_subdoc_iva.subdociva_id , t_subdoc_iva.dociva_r_id , t_subdoc_iva.subdociva_data_emissione, t_subdoc_iva.subdociva_numero,
	round(t_ivamov.ivamov_imponibile,2) as ivamov_imponibile, round(t_ivamov.ivamov_imposta,2) as ivamov_imposta, 
    round(t_ivamov.ivamov_totale,2) as ivamov_totale,
    t_iva_aliquota.ivaaliquota_code, t_iva_aliquota.ivaaliquota_desc,
	 t_reg_iva.ivareg_code, t_reg_iva.ivareg_desc,
		d_iva_reg_tipo.ivareg_tipo_code, d_iva_reg_tipo.ivareg_tipo_desc,
        ente_prop.ente_denominazione, ente_prop.codice_fiscale,
        t_subdoc_iva.subdociva_data_emissione data_emissione,
        t_subdoc_iva.subdociva_data_prot_def data_prot_def,
        t_iva_aliquota.ivaaliquota_perc_indetr,
        tipo_oper.ivaop_tipo_code,
        t_iva_aliquota.ivaaliquota_perc,
        prorata.ivapro_perc,
        t_iva_aliquota.ivaaliquota_split
from siac_t_iva_registro t_reg_iva,
		siac_d_iva_registro_tipo d_iva_reg_tipo,
        siac_t_subdoc_iva t_subdoc_iva,
        siac_r_ivamov r_ivamov,
        siac_t_ivamov t_ivamov,
        siac_t_iva_aliquota t_iva_aliquota,
        siac_t_ente_proprietario ente_prop,
        siac_d_iva_operazione_tipo tipo_oper,
        siac_t_iva_gruppo iva_gruppo,
        siac_r_iva_registro_gruppo riva_gruppo,
        siac_r_iva_gruppo_prorata rprorata,
        siac_t_iva_prorata prorata,
        siac_r_subdoc_subdoc_iva rssi, siac_t_doc td, siac_t_subdoc ts
where  t_reg_iva.ivareg_tipo_id=d_iva_reg_tipo.ivareg_tipo_id
		AND t_subdoc_iva.ivareg_id=t_reg_iva.ivareg_id
        AND r_ivamov.subdociva_id=t_subdoc_iva.subdociva_id
        AND r_ivamov.ivamov_id=t_ivamov.ivamov_id
        AND t_iva_aliquota.ivaaliquota_id=t_ivamov.ivaaliquota_id
        AND ente_prop.ente_proprietario_id=t_reg_iva.ente_proprietario_id
		AND t_reg_iva.ente_proprietario_id=p_ente_prop_id
        AND tipo_oper.ivaop_tipo_id= t_iva_aliquota.ivaop_tipo_id
        AND riva_gruppo.ivareg_id=t_reg_iva.ivareg_id
        AND iva_gruppo.ivagru_id = riva_gruppo.ivagru_id 
        AND rprorata.ivagru_id = iva_gruppo.ivagru_id
        AND prorata.ivapro_id=rprorata.ivapro_id
        AND rprorata.ivagrupro_anno = p_anno::integer
       --AND t_subdoc_iva.subdociva_data_prot_def between  
      -- 	to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
      --      to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy')
       AND (t_subdoc_iva.subdociva_data_prot_def >=  
       	to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
        t_subdoc_iva.subdociva_data_prot_def <  
       to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))  
       --03/07/2018 SIAC-6275: occorre escludere i registri IVA
       -- con ivareg_flagliquidazioneiva = false
        AND t_reg_iva.ivareg_flagliquidazioneiva = true
        AND t_reg_iva.data_cancellazione IS NULL
        AND d_iva_reg_tipo.data_cancellazione IS NULL    
        AND t_subdoc_iva.data_cancellazione IS NULL 
        AND r_ivamov.data_cancellazione IS NULL
        AND t_ivamov.data_cancellazione IS NULL
        AND riva_gruppo.data_cancellazione is NULL
        AND t_iva_aliquota.data_cancellazione IS NULL
        AND rprorata.data_cancellazione is null
        --- AGGIUNTO DA QUI
        AND    rssi.subdociva_id = t_subdoc_iva.subdociva_id
        AND    td.ente_proprietario_id = t_reg_iva.ente_proprietario_id
        AND    rssi.subdoc_id = ts.subdoc_id
        AND    ts.doc_id = td.doc_id
        AND    rssi.data_cancellazione IS NULL
        AND    ts.data_cancellazione IS NULL
        AND    td.data_cancellazione IS NULL
        --AND    p_data BETWEEN rssi.validita_inizio AND COALESCE(rssi.validita_fine, p_data)
        --AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
        --AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
        --AND    t_subdoc_iva.dociva_r_id IS NULL
        /*AND not exists 
        (select 1 from siac_r_doc_iva b
            where b.doc_id = td.doc_id 
            and b.data_cancellazione is null )   */
/*ORDER BY d_iva_reg_tipo.ivareg_tipo_code, t_reg_iva.ivareg_code,
			t_iva_aliquota.ivaaliquota_code   */       
UNION
select t_subdoc_iva.subdociva_id , t_subdoc_iva.dociva_r_id , t_subdoc_iva.subdociva_data_emissione, t_subdoc_iva.subdociva_numero,
	round(t_ivamov.ivamov_imponibile,2) as ivamov_imponibile, round(t_ivamov.ivamov_imposta,2) as ivamov_imposta, 
    round(t_ivamov.ivamov_totale,2) as ivamov_totale,
    t_iva_aliquota.ivaaliquota_code, t_iva_aliquota.ivaaliquota_desc,
	 t_reg_iva.ivareg_code, t_reg_iva.ivareg_desc,
		d_iva_reg_tipo.ivareg_tipo_code, d_iva_reg_tipo.ivareg_tipo_desc,
        ente_prop.ente_denominazione, ente_prop.codice_fiscale,
        t_subdoc_iva.subdociva_data_emissione data_emissione,
        t_subdoc_iva.subdociva_data_prot_def data_prot_def,
        t_iva_aliquota.ivaaliquota_perc_indetr,
        tipo_oper.ivaop_tipo_code,
        t_iva_aliquota.ivaaliquota_perc,
        prorata.ivapro_perc,
        t_iva_aliquota.ivaaliquota_split
from siac_t_iva_registro t_reg_iva,
		siac_d_iva_registro_tipo d_iva_reg_tipo,
        siac_t_subdoc_iva t_subdoc_iva,
        siac_r_ivamov r_ivamov,
        siac_t_ivamov t_ivamov,
        siac_t_iva_aliquota t_iva_aliquota,
        siac_t_ente_proprietario ente_prop,
        siac_d_iva_operazione_tipo tipo_oper,
        siac_t_iva_gruppo iva_gruppo,
        siac_r_iva_registro_gruppo riva_gruppo,
        siac_r_iva_gruppo_prorata rprorata,
        siac_t_iva_prorata prorata,
        siac_r_doc_iva rdi, siac_t_doc td
where  t_reg_iva.ivareg_tipo_id=d_iva_reg_tipo.ivareg_tipo_id
		AND t_subdoc_iva.ivareg_id=t_reg_iva.ivareg_id
        AND r_ivamov.subdociva_id=t_subdoc_iva.subdociva_id
        AND r_ivamov.ivamov_id=t_ivamov.ivamov_id
        AND t_iva_aliquota.ivaaliquota_id=t_ivamov.ivaaliquota_id
        AND ente_prop.ente_proprietario_id=t_reg_iva.ente_proprietario_id
		AND t_reg_iva.ente_proprietario_id=p_ente_prop_id
        AND tipo_oper.ivaop_tipo_id= t_iva_aliquota.ivaop_tipo_id
        AND riva_gruppo.ivareg_id=t_reg_iva.ivareg_id
        AND iva_gruppo.ivagru_id = riva_gruppo.ivagru_id 
        AND rprorata.ivagru_id = iva_gruppo.ivagru_id
        AND prorata.ivapro_id=rprorata.ivapro_id
        AND rprorata.ivagrupro_anno = p_anno::integer
       --AND t_subdoc_iva.subdociva_data_prot_def between  
      -- 	to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
      --      to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy')
       AND (t_subdoc_iva.subdociva_data_prot_def >=  
       	to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
        t_subdoc_iva.subdociva_data_prot_def <  
       to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))  
       --03/07/2018 SIAC-6275: occorre escludere i registri IVA
       -- con ivareg_flagliquidazioneiva = false
        AND t_reg_iva.ivareg_flagliquidazioneiva = true
        AND t_reg_iva.data_cancellazione IS NULL
        AND d_iva_reg_tipo.data_cancellazione IS NULL    
        AND t_subdoc_iva.data_cancellazione IS NULL 
        AND r_ivamov.data_cancellazione IS NULL
        AND t_ivamov.data_cancellazione IS NULL
        AND riva_gruppo.data_cancellazione is NULL
        AND t_iva_aliquota.data_cancellazione IS NULL
        AND rprorata.data_cancellazione is null
        ---- DA QUI
        AND      rdi.dociva_r_id = t_subdoc_iva.dociva_r_id
        AND    td.ente_proprietario_id = t_reg_iva.ente_proprietario_id
        AND    rdi.doc_id = td.doc_id
        AND    rdi.data_cancellazione IS NULL
        AND    td.data_cancellazione IS NULL
        --AND    p_data BETWEEN rdi.validita_inizio AND COALESCE(rdi.validita_fine, p_data)
        --AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
        --AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
        AND    t_subdoc_iva.dociva_r_id  IS NOT NULL
        and not exists (select 1 from siac_r_subdoc_subdoc_iva x
   			 where x.data_cancellazione is null and x.validita_fine is null 
             --and x.subdociva_id = t_subdoc_iva.subdociva_id
             and exists   (
             select y.subdoc_id from siac_t_subdoc y
             where y.doc_id=td.doc_id
             and x.subdoc_id = y.subdoc_id
             and y.data_cancellazione is null
  		) )
        
/*ORDER BY d_iva_reg_tipo.ivareg_tipo_code, t_reg_iva.ivareg_code,
			t_iva_aliquota.ivaaliquota_code     */     
loop

--COALESCE(v.titolo_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))

select x.* 
into v_id_doc , v_tipo_doc  from (
  SELECT distinct td.doc_id, tipo.doc_tipo_code
  /*INTO   v_doc_anno, v_doc_numero, v_doc_data_emissione,
         v_subdoc_numero,
         v_doc_tipo_id, v_doc_id*/
  FROM   siac_r_subdoc_subdoc_iva rssi, siac_t_doc td, siac_t_subdoc ts, siac_d_doc_tipo tipo
  WHERE  rssi.subdociva_id = elencoRegistriIva.subdociva_id
  AND    td.ente_proprietario_id = p_ente_prop_id
  AND    rssi.subdoc_id = ts.subdoc_id
  AND    ts.doc_id = td.doc_id
  AND	 tipo.doc_tipo_id= td.doc_tipo_id
  AND    rssi.data_cancellazione IS NULL
  AND    ts.data_cancellazione IS NULL
  AND    td.data_cancellazione IS NULL
  --AND    p_data BETWEEN rssi.validita_inizio AND COALESCE(rssi.validita_fine, p_data)
  --AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
  --AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
  AND    elencoRegistriIva.dociva_r_id IS NULL
  UNION 
  SELECT distinct td.doc_id,  tipo.doc_tipo_code
  /*INTO   v_doc_anno, v_doc_numero, v_doc_data_emissione,
         v_subdoc_numero,
         v_doc_tipo_id, v_doc_id*/
  FROM   siac_r_doc_iva rdi, siac_t_doc td, siac_t_subdoc ts, siac_d_doc_tipo tipo
  WHERE  rdi.dociva_r_id = elencoRegistriIva.dociva_r_id 
  AND    td.ente_proprietario_id = p_ente_prop_id
  AND    rdi.doc_id = td.doc_id
  AND    ts.doc_id = td.doc_id
  AND	 tipo.doc_tipo_id= td.doc_tipo_id
  AND    rdi.data_cancellazione IS NULL
  AND    ts.data_cancellazione IS NULL
  AND    td.data_cancellazione IS NULL
  --AND    p_data BETWEEN rdi.validita_inizio AND COALESCE(rdi.validita_fine, p_data)
  --AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
  --AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
  AND    elencoRegistriIva.dociva_r_id  IS NOT NULL
  ) x;

raise notice 'v_id_doc - v_tipo_doc % - %', v_id_doc , v_tipo_doc ; 



bil_anno='';
desc_ente=elencoRegistriIva.ente_denominazione;
data_registrazione=elencoRegistriIva.subdociva_data_emissione;
cod_fisc_ente=elencoRegistriIva.codice_fiscale;
desc_periodo='';
cod_tipo_registro=elencoRegistriIva.ivareg_tipo_code;
desc_tipo_registro=elencoRegistriIva.ivareg_tipo_desc;
cod_registro=elencoRegistriIva.ivareg_code;
desc_registro=elencoRegistriIva.ivareg_desc;
cod_aliquota_iva=elencoRegistriIva.ivaaliquota_code;
desc_aliquota_iva=elencoRegistriIva.ivaaliquota_desc;
importo_iva_imponibile=elencoRegistriIva.ivamov_imponibile;
importo_iva_imposta=elencoRegistriIva.ivamov_imposta;
importo_iva_totale=elencoRegistriIva.ivamov_totale;

tipo_reg_completa=desc_tipo_registro;
cod_reg_completa=desc_registro;
aliquota_completa= desc_aliquota_iva;
data_emissione=elencoRegistriIva.data_emissione;
data_prot_def=elencoRegistriIva.data_prot_def; 


-- CI = CORRISPETTIVI
-- VI = VENDITE IVA IMMEDIATA
-- VD = VENDITE IVA DIFFERITA
-- AI = ACQUISTI IVA IMMEDIATA
-- AD = ACQUISTI IVA DIFFERITA
if cod_tipo_registro = 'CI' OR cod_tipo_registro = 'VI' OR cod_tipo_registro = 'VD' THEN
	tipo_registro='V'; --VENDITE
ELSE
	tipo_registro='A'; --ACQUISTI
END IF;



if v_tipo_doc in ('NCD', 'NCV') and elencoRegistriIva.ivamov_imponibile > 0 
then 
   	importo_iva_imponibile= importo_iva_imponibile*-1;
	importo_iva_imposta=importo_iva_imposta*-1;
	importo_iva_totale=importo_iva_totale*-1;
end if;
       

importo_iva_indetraibile=round((coalesce(importo_iva_imposta,0)/100)*coalesce(elencoRegistriIva.ivaaliquota_perc_indetr,0),2);
importo_iva_detraibile=coalesce(importo_iva_imposta,0) - importo_iva_indetraibile;

importo_indetraibile=round((coalesce(importo_iva_imponibile,0)/100)*coalesce(elencoRegistriIva.ivaaliquota_perc_indetr,0),2);
importo_detraibile=coalesce(importo_iva_imponibile,0) - importo_indetraibile;

importo_esente=0;

if elencoRegistriIva.ivaop_tipo_code = 'ES' then
	importo_esente=importo_iva_imponibile;
end if;

importo_fuori_campo=0;

if elencoRegistriIva.ivaop_tipo_code = 'FCI' then
	importo_fuori_campo=importo_iva_imponibile;
end if;

importo_split=0;
if elencoRegistriIva.ivaaliquota_split = true then
	importo_split=importo_detraibile;
    importo_iva_split=importo_iva_detraibile;
end if;



percent_indetr= elencoRegistriIva.ivaaliquota_perc_indetr;
pro_rata=elencoRegistriIva.ivapro_perc;
aliquota_perc=elencoRegistriIva.ivaaliquota_perc;


return next;

bil_anno='';
desc_ente='';
data_registrazione=NULL;
cod_fisc_ente='';
desc_periodo='';
cod_tipo_registro='';
desc_tipo_registro='';
cod_registro='';
desc_registro='';
cod_aliquota_iva='';
desc_aliquota_iva='';
importo_iva_imponibile=0;
importo_iva_imposta=0;
importo_iva_totale=0;
tipo_reg_completa='';
cod_reg_completa='';
aliquota_completa='';
tipo_registro='';
data_emissione=NULL;
data_prot_def=NULL;
importo_iva_detraibile=0;
importo_iva_indetraibile=0;
importo_esente=0;
importo_split=0;
importo_iva_split=0;
importo_fuori_campo=0;
percent_indetr=0;
pro_rata=0;
aliquota_perc=0;
end loop;




raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'Nessun dato trovato per i registri IVA' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
RETURNS NULL ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

--SIAC-6275: Maurizio - FINE

--SIAC-6270 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR152_elenco_doc_entrata"(p_ente_prop_id integer, p_anno varchar, p_numero_provv integer, p_anno_provv varchar, p_tipo_provv varchar);
DROP FUNCTION if exists siac."BILR152_elenco_doc_spesa"(p_ente_prop_id integer, p_anno varchar, p_numero_provv integer, p_anno_provv varchar, p_tipo_provv varchar);

CREATE OR REPLACE FUNCTION siac."BILR152_elenco_doc_entrata" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_provv integer,
  p_anno_provv varchar,
  p_tipo_provv varchar
)
RETURNS TABLE (
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_code3 varchar,
  doc_anno integer,
  doc_numero varchar,
  subdoc_numero integer,
  tipo_doc varchar,
  conto_dare varchar,
  conto_avere varchar,
  num_accertamento numeric,
  anno_accertamento integer,
  num_subaccertamento varchar,
  tipo_accert varchar,
  code_soggetto varchar,
  desc_soggetto varchar,
  num_reversale varchar,
  anno_reversale integer,
  importo_quota numeric,
  doc_id integer,
  subdoc_id integer
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
anno_eser_int integer;
 

BEGIN

bil_ele_code:='';
bil_ele_desc:='';
bil_ele_code2:='';
bil_ele_desc2:='';
bil_ele_code3:='';
doc_anno:=0;
doc_numero:='';
subdoc_numero:=0;
tipo_doc:='';
conto_dare:='';
conto_avere:='';
num_accertamento:=0;
anno_accertamento:=0;
num_subaccertamento:='';
tipo_accert:='';
code_soggetto:='';
desc_soggetto:=0;
num_reversale:='';
anno_reversale:=0;
importo_quota:=0;


anno_eser_int=p_anno ::INTEGER;


RTN_MESSAGGIO:='Estrazione dei dati dei documenti di entrata ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
return query 
select query_totale.* from  (
with doc as (     
-- SIAC-6270: aggiunto filtro sullo stato dei documenti e restituiti anche
-- doc_id e subdoc_id che sono utilizzati nel report per il raggruppamento
-- in modo da evitare problemi in caso di documenti con stesso numero/anno
      select r_subdoc_atto_amm.subdoc_id,
              t_doc.doc_id,
                COALESCE(t_doc.doc_numero,'''') doc_numero, 
                COALESCE(t_doc.doc_anno,0) doc_anno, 
                COALESCE(t_doc.doc_importo,0) doc_importo,
                COALESCE(t_subdoc.subdoc_numero,0) subdoc_numero, 
                COALESCE(t_subdoc.subdoc_importo,0) subdoc_importo, 
                COALESCE(t_subdoc.subdoc_importo_da_dedurre,0) subdoc_importo_da_dedurre,                 
                COALESCE(d_doc_tipo.doc_tipo_code,'''') tipo_doc,
                 t_atto_amm.attoamm_numero,
                  t_atto_amm.attoamm_anno,
                  tipo_atto.attoamm_tipo_code,
                  r_subdoc_movgest_ts.movgest_ts_id
          from siac_r_subdoc_atto_amm r_subdoc_atto_amm,
                  siac_t_subdoc t_subdoc
                  LEFT JOIN siac_r_subdoc_movgest_ts r_subdoc_movgest_ts
                      ON (r_subdoc_movgest_ts.subdoc_id=t_subdoc.subdoc_id
                          AND r_subdoc_movgest_ts.data_cancellazione IS NULL),
                  siac_t_doc 	t_doc
                  LEFT JOIN siac_d_doc_tipo d_doc_tipo
                      ON (d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id
                          AND d_doc_tipo.data_cancellazione IS NULL)
                  LEFT JOIN siac_d_doc_fam_tipo d_doc_fam_tipo
                      ON (d_doc_fam_tipo.doc_fam_tipo_id=d_doc_tipo.doc_fam_tipo_id
                          AND d_doc_fam_tipo.data_cancellazione IS NULL),
                  siac_r_doc_stato r_doc_stato,
                  siac_d_doc_stato d_doc_stato,
                  siac_t_atto_amm t_atto_amm  ,
                  siac_d_atto_amm_tipo	tipo_atto
          where t_subdoc.subdoc_id= r_subdoc_atto_amm.subdoc_id
              AND t_doc.doc_id=  t_subdoc.doc_id
              AND t_atto_amm.attoamm_id=r_subdoc_atto_amm.attoamm_id
              AND tipo_atto.attoamm_tipo_id=t_atto_amm.attoamm_tipo_id
              and t_doc.doc_id = r_doc_stato.doc_id
              and r_doc_stato.doc_stato_id = d_doc_stato.doc_stato_id
              and r_subdoc_atto_amm.ente_proprietario_id=p_ente_prop_id
              AND t_atto_amm.attoamm_numero=p_numero_provv
              AND t_atto_amm.attoamm_anno=p_anno_provv
              AND tipo_atto.attoamm_tipo_code=p_tipo_provv
             AND d_doc_fam_tipo.doc_fam_tipo_code='E' --doc di Entrata
             and d_doc_stato.doc_stato_code <> 'A'
              AND r_subdoc_atto_amm.data_cancellazione IS NULL
              AND t_atto_amm.data_cancellazione IS NULL
              AND tipo_atto.data_cancellazione IS NULL
              AND t_subdoc.data_cancellazione IS NULL
              AND t_doc.data_cancellazione IS NULL
              AND d_doc_stato.data_cancellazione IS NULL 
              AND r_doc_stato.data_cancellazione IS NULL   ),
 accert as (
		SELECT t_movgest.movgest_id, t_movgest_ts.movgest_ts_id,
        		t_movgest.movgest_anno, 
      			t_movgest.movgest_numero,
            	t_movgest_ts.movgest_ts_code,
                 d_movgest_ts_tipo.movgest_ts_tipo_code,
                t_movgest_ts_det.movgest_ts_det_importo
            FROM siac_t_movgest t_movgest,
            	siac_t_bil t_bil,
                siac_t_periodo t_periodo,
            	siac_t_movgest_ts t_movgest_ts,    
                siac_d_movgest_tipo d_movgest_tipo,            
                siac_t_movgest_ts_det t_movgest_ts_det,
                siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                siac_d_movgest_ts_tipo d_movgest_ts_tipo,
                siac_r_movgest_ts_stato r_movgest_ts_stato,
                siac_d_movgest_stato d_movgest_stato 
          	WHERE t_movgest.movgest_id=t_movgest_ts.movgest_id    
            	AND t_bil.bil_id= t_movgest.bil_id   
                AND t_periodo.periodo_id=t_bil.periodo_id    
            	AND d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id 
                 AND r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id     
               AND r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id   	
               AND t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
               AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
                AND d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
                AND t_movgest.ente_proprietario_id=p_ente_prop_id
                AND t_periodo.anno =p_anno
                AND d_movgest_tipo.movgest_tipo_code='A'    --accertamento  
                AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A' -- importo attuale 
                AND d_movgest_stato.movgest_stato_code<>'A' -- non gli annullati
                AND  t_movgest_ts.data_cancellazione IS NULL
                AND  t_movgest.data_cancellazione IS NULL   
                AND t_bil.data_cancellazione IS NULL 
                AND t_periodo.data_cancellazione IS NULL
                AND  d_movgest_tipo.data_cancellazione IS NULL            
                AND t_movgest_ts_det.data_cancellazione IS NULL
                AND d_movgest_ts_det_tipo.data_cancellazione IS NULL
                AND d_movgest_ts_tipo.data_cancellazione IS NULL
                AND r_movgest_ts_stato.data_cancellazione IS NULL
                AND d_movgest_stato.data_cancellazione IS NULL),
	soggetto as (
    		SELECT r_doc_sog.doc_id,
                t_soggetto.soggetto_code,
                t_soggetto.soggetto_desc
            FROM siac_r_doc_sog r_doc_sog,
                siac_t_soggetto t_soggetto
            WHERE r_doc_sog.soggetto_id=   t_soggetto.soggetto_id
                and t_soggetto.ente_proprietario_id=p_ente_prop_id
                AND t_soggetto.data_cancellazione IS NULL  
                AND r_doc_sog.data_cancellazione IS NULL) ,   
    	capitoli as(
        	select r_movgest_bil_elem.movgest_id,
            	t_bil_elem.elem_id,
            	t_bil_elem.elem_code,
                t_bil_elem.elem_code2,
                t_bil_elem.elem_code3,
                t_bil_elem.elem_desc,
                t_bil_elem.elem_desc2
            from 	siac_r_movgest_bil_elem r_movgest_bil_elem,
            	siac_t_bil_elem t_bil_elem
            where r_movgest_bil_elem.elem_id=t_bil_elem.elem_id            
            	AND r_movgest_bil_elem.ente_proprietario_id=p_ente_prop_id
            	AND t_bil_elem.data_cancellazione IS NULL
                AND r_movgest_bil_elem.data_cancellazione IS NULL) ,
	conto_integrato as (    	
      select distinct t_subdoc.subdoc_id, 
          t_mov_ep_det.movep_det_segno,
          t_pdce_conto.pdce_conto_code
      from siac_r_evento_reg_movfin r_ev_reg_movfin,
          siac_t_subdoc t_subdoc,
          siac_d_evento d_evento,
          siac_d_collegamento_tipo d_coll_tipo,
          siac_t_reg_movfin t_reg_movfin,
          siac_t_mov_ep t_mov_ep,
          siac_t_mov_ep_det t_mov_ep_det,
          siac_t_pdce_conto t_pdce_conto
      where t_subdoc.subdoc_id=r_ev_reg_movfin.campo_pk_id
          and d_evento.evento_id=r_ev_reg_movfin.evento_id
          and d_coll_tipo.collegamento_tipo_id=d_evento.collegamento_tipo_id
          and t_reg_movfin.regmovfin_id=r_ev_reg_movfin.regmovfin_id
          and t_mov_ep.regmovfin_id=t_reg_movfin.regmovfin_id
          and t_mov_ep_det.movep_id=t_mov_ep.movep_id
          and t_pdce_conto.pdce_conto_id=t_mov_ep_det.pdce_conto_id
          and t_subdoc.ente_proprietario_id=p_ente_prop_id
          and d_coll_tipo.collegamento_tipo_code='SE' --Subdocumento Entrata   
          and r_ev_reg_movfin.data_cancellazione is null
          and t_subdoc.data_cancellazione is null
          and d_evento.data_cancellazione is null
          and d_coll_tipo.data_cancellazione is null
          and t_reg_movfin.data_cancellazione is null
          and t_mov_ep.data_cancellazione is null
          and t_mov_ep_det.data_cancellazione is null
          and t_pdce_conto.data_cancellazione is null )   ,
      reversali as (    
      select t_ordinativo.ord_anno,
          t_ordinativo.ord_numero,
          r_subdoc_ord_ts.subdoc_id         
       from  
                siac_t_ordinativo t_ordinativo,
                siac_d_ordinativo_tipo d_ordinativo_tipo,              
                siac_t_ordinativo_ts t_ord_ts,
                siac_r_subdoc_ordinativo_ts r_subdoc_ord_ts,
                siac_t_ordinativo_ts_det t_ord_ts_det, 
               siac_d_ordinativo_ts_det_tipo ts_det_tipo  
      where t_ordinativo.ord_tipo_id=   d_ordinativo_tipo.ord_tipo_id
          and t_ordinativo.ord_id= t_ord_ts.ord_id
          AND r_subdoc_ord_ts.ord_ts_id=t_ord_ts.ord_ts_id
          and t_ord_ts_det.ord_ts_id= t_ord_ts.ord_ts_id  
          and ts_det_tipo.ord_ts_det_tipo_id=  t_ord_ts_det.ord_ts_det_tipo_id
          AND t_ordinativo.ente_proprietario_id=p_ente_prop_id
           AND d_ordinativo_tipo.ord_tipo_code ='I' --Incasso
           AND ts_det_tipo.ord_ts_det_tipo_code='A' --importo Attuale
           AND t_ordinativo.data_cancellazione IS NULL
           AND d_ordinativo_tipo.data_cancellazione IS NULL 
           AND t_ord_ts.data_cancellazione IS NULL
           AND t_ord_ts_det.data_cancellazione IS NULL
           AND ts_det_tipo.data_cancellazione IS NULL
           AND r_subdoc_ord_ts.data_cancellazione IS NULL)                                    
SELECT COALESCE(capitoli.elem_code,'')::varchar bil_ele_code,
	COALESCE(capitoli.elem_desc,'')::varchar bil_ele_desc,
    COALESCE(capitoli.elem_code2,'')::varchar bil_ele_code2,
   	COALESCE(capitoli.elem_desc2,'')::varchar bil_ele_desc2,
    COALESCE(capitoli.elem_code3,'')::varchar bil_ele_code3,
    doc.doc_anno::integer,
    doc.doc_numero::varchar,
    doc.subdoc_numero::integer,
    doc.tipo_doc::varchar,
    CASE WHEN COALESCE(upper(conto_integrato.movep_det_segno),'')='DARE'
    	THEN COALESCE(conto_integrato.pdce_conto_code,'')::varchar 
        ELSE ''::varchar end conto_dare,
     CASE WHEN COALESCE(upper(conto_integrato.movep_det_segno),'')='AVERE'
    	THEN COALESCE(conto_integrato.pdce_conto_code,'')::varchar 
        ELSE ''::varchar end conto_avere,
    accert.movgest_numero::numeric num_accertamento,
    accert.movgest_anno::integer anno_accertamento,
    accert.movgest_ts_code::varchar num_subaccertamento,
    CASE WHEN accert.movgest_ts_tipo_code = 'T'
    	THEN 'ACC'::varchar 
        ELSE 'SUB'::varchar end tipo_accert,
    COALESCE(soggetto.soggetto_code,'')::varchar code_soggetto,
    COALESCE(soggetto.soggetto_desc,'')::varchar desc_soggetto,
    COALESCE(reversali.ord_numero,'0')::varchar num_reversale,
    COALESCE(reversali.ord_anno,0)::integer anno_reversale,
    COALESCE(doc.subdoc_importo,0)-
    COALESCE(doc.subdoc_importo_da_dedurre,0) ::numeric importo_quota,
    doc.doc_id::integer doc_id,
    doc.subdoc_id::integer subdoc_id	
FROM doc
	LEFT JOIN accert on accert.movgest_ts_id=doc.movgest_ts_id
	LEFT JOIN soggetto on soggetto.doc_id=doc.doc_id    
	LEFT JOIN capitoli on capitoli.movgest_id = accert.movgest_id
    LEFT JOIN conto_integrato on conto_integrato.subdoc_id = doc.subdoc_id 
    LEFT JOIN reversali on reversali.subdoc_id = doc.subdoc_id       
ORDER BY doc_anno, doc_numero, subdoc_numero) query_totale;

RTN_MESSAGGIO:='Fine estrazione dei dati dei documenti di entrata  ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;



exception
	when no_data_found THEN
		raise notice 'Nessun documento di entrata trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR152_elenco_doc_spesa" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_provv integer,
  p_anno_provv varchar,
  p_tipo_provv varchar
)
RETURNS TABLE (
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_code3 varchar,
  doc_anno integer,
  doc_numero varchar,
  subdoc_numero integer,
  tipo_doc varchar,
  conto_dare varchar,
  conto_avere varchar,
  num_impegno numeric,
  anno_impegno integer,
  num_subimpegno varchar,
  tipo_impegno varchar,
  code_soggetto varchar,
  desc_soggetto varchar,
  num_liquidazione varchar,
  anno_liquidazione integer,
  importo_quota numeric,
  penale_anno integer,
  penale_numero varchar,
  ncd_anno integer,
  ncd_numero varchar,
  tipo_iva_split_reverse varchar,
  importo_split_reverse numeric,
  codice_onere varchar,
  aliquota_carico_sogg numeric,
  doc_id integer,
  subdoc_id integer
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
anno_eser_int integer;

-- CR944 inizio
tipo_cessione varchar:=''; 
-- CR944 fine
 

BEGIN

bil_ele_code:='';
bil_ele_desc:='';
bil_ele_code2:='';
bil_ele_desc2:='';
bil_ele_code3:='';
doc_anno:=0;
doc_numero:='';
subdoc_numero:=0;
tipo_doc:='';
conto_dare:='';
conto_avere:='';
num_impegno:=0;
anno_impegno:=0;
num_subimpegno:='';
tipo_impegno:='';
code_soggetto:='';
desc_soggetto:=0;
num_liquidazione:='';
anno_liquidazione:=0;
importo_quota:=0;
penale_anno:=0;
penale_numero:='';
ncd_anno:=0;
ncd_numero:='';
tipo_iva_split_reverse:='';
importo_split_reverse:=0;
codice_onere:='';
aliquota_carico_sogg:=0;

anno_eser_int=p_anno ::INTEGER;


RTN_MESSAGGIO:='Estrazione dei dati dei documenti di spesa ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
return query 
select query_totale.* from  (
with doc as (      
-- SIAC-6270: aggiunto filtro sullo stato dei documenti e restituiti anche
-- doc_id e subdoc_id che sono utilizzati nel report per il raggruppamento
-- in modo da evitare problemi in caso di documenti con stesso numero/anno
      select r_subdoc_atto_amm.subdoc_id,
              t_doc.doc_id,
                COALESCE(t_doc.doc_numero,'''') doc_numero, 
                COALESCE(t_doc.doc_anno,0) doc_anno, 
                COALESCE(t_doc.doc_importo,0) doc_importo,
                COALESCE(t_subdoc.subdoc_numero,0) subdoc_numero, 
                COALESCE(t_subdoc.subdoc_importo,0) subdoc_importo, 
                COALESCE(t_subdoc.subdoc_importo_da_dedurre,0) subdoc_importo_da_dedurre, 
                COALESCE(d_doc_tipo.doc_tipo_code,'''') tipo_doc,
                 t_atto_amm.attoamm_numero,
                  t_atto_amm.attoamm_anno,
                  tipo_atto.attoamm_tipo_code,
                  r_subdoc_movgest_ts.movgest_ts_id
          from siac_r_subdoc_atto_amm r_subdoc_atto_amm,
                  siac_t_subdoc t_subdoc
                  LEFT JOIN siac_r_subdoc_movgest_ts r_subdoc_movgest_ts
                      ON (r_subdoc_movgest_ts.subdoc_id=t_subdoc.subdoc_id
                          AND r_subdoc_movgest_ts.data_cancellazione IS NULL),
                  siac_t_doc 	t_doc
                  LEFT JOIN siac_d_doc_tipo d_doc_tipo
                      ON (d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id
                          AND d_doc_tipo.data_cancellazione IS NULL)
                  LEFT JOIN siac_d_doc_fam_tipo d_doc_fam_tipo
                      ON (d_doc_fam_tipo.doc_fam_tipo_id=d_doc_tipo.doc_fam_tipo_id
                          AND d_doc_fam_tipo.data_cancellazione IS NULL),
                  siac_r_doc_stato r_doc_stato,
                  siac_d_doc_stato d_doc_stato,
                  siac_t_atto_amm t_atto_amm  ,
                  siac_d_atto_amm_tipo	tipo_atto
          where t_subdoc.subdoc_id= r_subdoc_atto_amm.subdoc_id
              AND t_doc.doc_id=  t_subdoc.doc_id
              AND t_atto_amm.attoamm_id=r_subdoc_atto_amm.attoamm_id
              AND tipo_atto.attoamm_tipo_id=t_atto_amm.attoamm_tipo_id
              and t_doc.doc_id = r_doc_stato.doc_id
              and r_doc_stato.doc_stato_id = d_doc_stato.doc_stato_id
              and r_subdoc_atto_amm.ente_proprietario_id=p_ente_prop_id
              AND t_atto_amm.attoamm_numero=p_numero_provv
              AND t_atto_amm.attoamm_anno=p_anno_provv
              AND tipo_atto.attoamm_tipo_code=p_tipo_provv
             AND d_doc_fam_tipo.doc_fam_tipo_code='S' --doc di Spesa
             and d_doc_stato.doc_stato_code <> 'A'
              AND r_subdoc_atto_amm.data_cancellazione IS NULL
              AND t_atto_amm.data_cancellazione IS NULL
              AND tipo_atto.data_cancellazione IS NULL
              AND t_subdoc.data_cancellazione IS NULL
              AND t_doc.data_cancellazione IS NULL  
              AND d_doc_stato.data_cancellazione IS NULL 
              AND r_doc_stato.data_cancellazione IS NULL ),
 impegni as (
		SELECT t_movgest.movgest_id, t_movgest_ts.movgest_ts_id,
        		t_movgest.movgest_anno, 
      			t_movgest.movgest_numero,
            	t_movgest_ts.movgest_ts_code,
                 d_movgest_ts_tipo.movgest_ts_tipo_code,
                t_movgest_ts_det.movgest_ts_det_importo
            FROM siac_t_movgest t_movgest,
            	siac_t_bil t_bil,
                siac_t_periodo t_periodo,
            	siac_t_movgest_ts t_movgest_ts,    
                siac_d_movgest_tipo d_movgest_tipo,            
                siac_t_movgest_ts_det t_movgest_ts_det,
                siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                siac_d_movgest_ts_tipo d_movgest_ts_tipo,
                siac_r_movgest_ts_stato r_movgest_ts_stato,
                siac_d_movgest_stato d_movgest_stato 
          	WHERE t_movgest.movgest_id=t_movgest_ts.movgest_id    
            	AND t_bil.bil_id= t_movgest.bil_id   
                AND t_periodo.periodo_id=t_bil.periodo_id    
            	AND d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id 
                 AND r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id     
               AND r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id   	
               AND t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
               AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
                AND d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
                AND t_movgest.ente_proprietario_id=p_ente_prop_id
                AND t_periodo.anno =p_anno
                AND d_movgest_tipo.movgest_tipo_code='I'    --Impegno  
                AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A' -- importo attuale 
                AND d_movgest_stato.movgest_stato_code<>'A' -- non gli annullati
                AND  t_movgest_ts.data_cancellazione IS NULL
                AND  t_movgest.data_cancellazione IS NULL   
                AND t_bil.data_cancellazione IS NULL 
                AND t_periodo.data_cancellazione IS NULL
                AND  d_movgest_tipo.data_cancellazione IS NULL            
                AND t_movgest_ts_det.data_cancellazione IS NULL
                AND d_movgest_ts_det_tipo.data_cancellazione IS NULL
                AND d_movgest_ts_tipo.data_cancellazione IS NULL
                AND r_movgest_ts_stato.data_cancellazione IS NULL
                AND d_movgest_stato.data_cancellazione IS NULL),                     
	soggetto as (
    		SELECT r_doc_sog.doc_id,
                t_soggetto.soggetto_code,
                t_soggetto.soggetto_desc
            FROM siac_r_doc_sog r_doc_sog,
                siac_t_soggetto t_soggetto
            WHERE r_doc_sog.soggetto_id=   t_soggetto.soggetto_id
                and t_soggetto.ente_proprietario_id=p_ente_prop_id
                AND t_soggetto.data_cancellazione IS NULL  
                AND r_doc_sog.data_cancellazione IS NULL) ,   
    	capitoli as(
        	select r_movgest_bil_elem.movgest_id,
            	t_bil_elem.elem_id,
            	t_bil_elem.elem_code,
                t_bil_elem.elem_code2,
                t_bil_elem.elem_code3,
                t_bil_elem.elem_desc,
                t_bil_elem.elem_desc2
            from 	siac_r_movgest_bil_elem r_movgest_bil_elem,
            	siac_t_bil_elem t_bil_elem
            where r_movgest_bil_elem.elem_id=t_bil_elem.elem_id            
            	AND r_movgest_bil_elem.ente_proprietario_id=p_ente_prop_id
            	AND t_bil_elem.data_cancellazione IS NULL
                AND r_movgest_bil_elem.data_cancellazione IS NULL) ,
	conto_integrato as (    	
      select distinct t_subdoc.subdoc_id, 
          t_mov_ep_det.movep_det_segno,
          t_pdce_conto.pdce_conto_code
      from siac_r_evento_reg_movfin r_ev_reg_movfin,
          siac_t_subdoc t_subdoc,
          siac_d_evento d_evento,
          siac_d_collegamento_tipo d_coll_tipo,
          siac_t_reg_movfin t_reg_movfin,
          siac_t_mov_ep t_mov_ep,
          siac_t_mov_ep_det t_mov_ep_det,
          siac_t_pdce_conto t_pdce_conto
      where t_subdoc.subdoc_id=r_ev_reg_movfin.campo_pk_id
          and d_evento.evento_id=r_ev_reg_movfin.evento_id
          and d_coll_tipo.collegamento_tipo_id=d_evento.collegamento_tipo_id
          and t_reg_movfin.regmovfin_id=r_ev_reg_movfin.regmovfin_id
          and t_mov_ep.regmovfin_id=t_reg_movfin.regmovfin_id
          and t_mov_ep_det.movep_id=t_mov_ep.movep_id
          and t_pdce_conto.pdce_conto_id=t_mov_ep_det.pdce_conto_id
          and t_subdoc.ente_proprietario_id=p_ente_prop_id
          and d_coll_tipo.collegamento_tipo_code='SS' --Subdocumento Spesa   
          and r_ev_reg_movfin.data_cancellazione is null
          and t_subdoc.data_cancellazione is null
          and d_evento.data_cancellazione is null
          and d_coll_tipo.data_cancellazione is null
          and t_reg_movfin.data_cancellazione is null
          and t_mov_ep.data_cancellazione is null
          and t_mov_ep_det.data_cancellazione is null
          and t_pdce_conto.data_cancellazione is null )   ,
      liquidazioni as (    
          select t_liquidazione.liq_anno,
              -- CR944 inizio
              --t_liquidazione.liq_numero,
              t_liquidazione.liq_numero || ' ' || COALESCE( d_relaz.relaz_tipo_code, '') as liq_numero,
              -- CR944 fine
              r_subdoc_liq.subdoc_id         
           from  siac_t_liquidazione t_liquidazione
             -- CR944 inizio
             left join  siac_r_soggetto_relaz r_relaz on (
                  t_liquidazione.soggetto_relaz_id=  r_relaz.soggetto_relaz_id
                  and r_relaz.data_cancellazione is null
                  and r_relaz.validita_fine is null 
             )
             left join siac_d_relaz_tipo d_relaz on (
                  d_relaz.relaz_tipo_id=r_relaz.relaz_tipo_id
             )
             left join siac_r_soggrel_modpag r_modpag on (
                  r_modpag.soggetto_relaz_id = r_relaz.soggetto_relaz_id
                  and r_modpag.data_cancellazione is null
                  and r_modpag.validita_fine is null
             )
             -- CR944 fine
           ,         
                siac_r_subdoc_liquidazione r_subdoc_liq                
          where t_liquidazione.liq_id=   r_subdoc_liq.liq_id
               AND t_liquidazione.ente_proprietario_id =p_ente_prop_id
               AND t_liquidazione.data_cancellazione IS NULL
               AND r_subdoc_liq.data_cancellazione IS NULL)  ,
      ncd as  (
      		SELECT  r_doc.doc_id_da doc_id,
            	t_doc.doc_anno,
                t_doc.doc_numero, 
                d_doc_tipo.doc_tipo_code
            FROM siac_r_doc r_doc, 
            		siac_d_relaz_tipo d_relaz_tipo,
                    siac_t_doc t_doc,
                    siac_d_doc_tipo d_doc_tipo
            WHERE r_doc.relaz_tipo_id=d_relaz_tipo.relaz_tipo_id
            	AND t_doc.doc_id=r_doc.doc_id_a
                AND d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id
                AND d_relaz_tipo.relaz_tipo_code='NCD' -- note di credito
                and r_doc.ente_proprietario_id=p_ente_prop_id
                AND r_doc.data_cancellazione IS NULL
                AND d_relaz_tipo.data_cancellazione IS NULL
                AND t_doc.data_cancellazione IS NULL
                AND d_doc_tipo.data_cancellazione IS NULL)  ,
			ritenute as (
        		SELECT r_doc_onere.doc_id, r_doc_onere.importo_carico_ente, 
                    r_doc_onere.importo_imponibile,
                    d_onere_tipo.onere_tipo_code, d_onere.onere_code
                FROM siac_r_doc_onere r_doc_onere, siac_d_onere d_onere,
                	siac_d_onere_tipo  d_onere_tipo
                WHERE r_doc_onere.onere_id=d_onere.onere_id
                	AND d_onere.onere_tipo_id=d_onere_tipo.onere_tipo_id
                    AND r_doc_onere.ente_proprietario_id =p_ente_prop_id
                    -- estraggo solo gli oneri con importo carico ente
                    -- e che non sono Split/reverse
                    AND r_doc_onere.importo_carico_ente > 0   
                    AND d_onere_tipo.onere_tipo_code <> 'SP'
                    AND r_doc_onere.data_cancellazione IS NULL
                    AND d_onere.data_cancellazione IS NULL
                    AND d_onere_tipo.data_cancellazione IS NULL)  ,
            split_reverse as (
            	SELECT r_subdoc_split_iva_tipo.subdoc_id,
						d_split_iva_tipo.sriva_tipo_code, 
                        t_subdoc.subdoc_splitreverse_importo
                FROM siac_r_subdoc_splitreverse_iva_tipo r_subdoc_split_iva_tipo,
                  siac_d_splitreverse_iva_tipo d_split_iva_tipo ,
                  siac_t_subdoc t_subdoc    
                WHERE  r_subdoc_split_iva_tipo.sriva_tipo_id= d_split_iva_tipo.sriva_tipo_id
                	AND t_subdoc.subdoc_id=r_subdoc_split_iva_tipo.subdoc_id
                    AND r_subdoc_split_iva_tipo.ente_proprietario_id=p_ente_prop_id
                    AND r_subdoc_split_iva_tipo.data_cancellazione IS NULL
                    AND d_split_iva_tipo.data_cancellazione IS NULL
                    AND t_subdoc.data_cancellazione IS NULL) ,
            penali as (
            	SELECT  r_doc.doc_id_da doc_id,
            	t_doc.doc_anno,
                t_doc.doc_numero, 
                d_doc_tipo.doc_tipo_code
            FROM siac_r_doc r_doc, 
            		siac_d_relaz_tipo d_relaz_tipo,
                    siac_t_doc t_doc,
                    siac_d_doc_tipo d_doc_tipo
            WHERE r_doc.relaz_tipo_id=d_relaz_tipo.relaz_tipo_id
            	AND t_doc.doc_id=r_doc.doc_id_a
                AND d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id
                AND d_relaz_tipo.relaz_tipo_code='SUB' -- subortinati
                AND d_doc_tipo.doc_tipo_code='PNL' -- Penale
                and r_doc.ente_proprietario_id=p_ente_prop_id
                AND r_doc.data_cancellazione IS NULL
                AND d_relaz_tipo.data_cancellazione IS NULL
                AND t_doc.data_cancellazione IS NULL
                AND d_doc_tipo.data_cancellazione IS NULL)
SELECT COALESCE(capitoli.elem_code,'')::varchar bil_ele_code,
	COALESCE(capitoli.elem_desc,'')::varchar bil_ele_desc,
    COALESCE(capitoli.elem_code2,'')::varchar bil_ele_code2,
   	COALESCE(capitoli.elem_desc2,'')::varchar bil_ele_desc2,
    COALESCE(capitoli.elem_code3,'')::varchar bil_ele_code3,
    doc.doc_anno::integer,
    doc.doc_numero::varchar,
    doc.subdoc_numero::integer,
    doc.tipo_doc::varchar,
    CASE WHEN COALESCE(upper(conto_integrato.movep_det_segno),'')='DARE'
    	THEN COALESCE(conto_integrato.pdce_conto_code,'')::varchar 
        ELSE ''::varchar end conto_dare,
     CASE WHEN COALESCE(upper(conto_integrato.movep_det_segno),'')='AVERE'
    	THEN COALESCE(conto_integrato.pdce_conto_code,'')::varchar 
        ELSE ''::varchar end conto_avere,
    impegni.movgest_numero::numeric num_impegno,
    impegni.movgest_anno::integer anno_impegno,
    impegni.movgest_ts_code::varchar num_subimpegno,
    CASE WHEN impegni.movgest_ts_tipo_code = 'T'
    	THEN 'IMP'::varchar 
        ELSE 'SUB'::varchar end tipo_impegno,
    COALESCE(soggetto.soggetto_code,'')::varchar code_soggetto,
    COALESCE(soggetto.soggetto_desc,'')::varchar desc_soggetto,
    COALESCE(liquidazioni.liq_numero,'0')::varchar num_liquidazione,
    COALESCE(liquidazioni.liq_anno,0)::integer anno_liquidazione,
	COALESCE(doc.subdoc_importo,0)-
    	COALESCE(doc.subdoc_importo_da_dedurre,0) ::numeric importo_quota,
    COALESCE(penali.doc_anno,0)::integer   penale_anno, 
    COALESCE(penali.doc_numero,'')::varchar   penale_numero, 
	COALESCE(ncd.doc_anno,0)::integer ncd_anno,
    COALESCE(ncd.doc_numero,'')::varchar ncd_numero,
   --'1'::varchar ncd_numero,
    COALESCE(split_reverse.sriva_tipo_code,'')::varchar tipo_iva_split_reverse,
	COALESCE(split_reverse.subdoc_splitreverse_importo,0)::numeric importo_split_reverse,
    COALESCE(ritenute.onere_code,'')::varchar codice_onere,
    COALESCE(ritenute.importo_carico_ente,0)::numeric aliquota_carico_sogg,
    doc.doc_id::integer doc_id,
    doc.subdoc_id::integer subdoc_id
FROM doc
	LEFT JOIN impegni on impegni.movgest_ts_id=doc.movgest_ts_id
	LEFT JOIN soggetto on soggetto.doc_id=doc.doc_id    
	LEFT JOIN capitoli on capitoli.movgest_id = impegni.movgest_id
    LEFT JOIN conto_integrato on conto_integrato.subdoc_id = doc.subdoc_id 
    LEFT JOIN liquidazioni on liquidazioni.subdoc_id = doc.subdoc_id 
    LEFT JOIN ncd on ncd.doc_id =doc.doc_id         
    LEFT JOIN ritenute on ritenute.doc_id =doc.doc_id  
    LEFT JOIN split_reverse on split_reverse.subdoc_id =doc.subdoc_id  
    LEFT JOIN penali on ncd.doc_id =penali.doc_id           
ORDER BY doc_anno, doc_numero, subdoc_numero) query_totale;

RTN_MESSAGGIO:='Fine estrazione dei dati dei documenti di spesa ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;



exception
	when no_data_found THEN
		raise notice 'Nessun documento trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

--SIAC-6270 - Maurizio - FINE



SELECT * FROM fnc_dba_add_column_params ('siac_t_iva_registro', 'ivareg_flagliquidazioneiva' , 'BOOLEAN DEFAULT true NOT NULL');