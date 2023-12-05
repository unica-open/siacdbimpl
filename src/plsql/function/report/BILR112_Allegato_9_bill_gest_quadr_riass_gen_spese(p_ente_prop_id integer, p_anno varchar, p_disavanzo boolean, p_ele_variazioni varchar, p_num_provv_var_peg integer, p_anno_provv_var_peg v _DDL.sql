/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR112_Allegato_9_bill_gest_quadr_riass_gen_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_disavanzo boolean,
  p_ele_variazioni varchar,
  p_num_provv_var_peg integer,
  p_anno_provv_var_peg varchar,
  p_tipo_provv_var_peg varchar,
  p_num_provv_var_bil integer,
  p_anno_provv_var_bil varchar,
  p_tipo_provv_var_bil varchar,
  p_code_sac_direz_peg varchar,
  p_code_sac_sett_peg varchar,
  p_code_sac_direz_bil varchar,
  p_code_sac_sett_bil varchar
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
  display_error varchar
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
BIL_ELE_CODE3	varchar;
h_count integer :=0;
importo integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
tipologia_capitolo	varchar;
cat_capitolo	varchar;
sql_query VARCHAR;
strApp VARCHAR;
intApp INTEGER;
-- DAVIDE - SIAC-5202 - oltre 4 variazioni, il codice si sfonda
x_array VARCHAR [];
-- DAVIDE - SIAC-5202 - FINE
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';

contaParVarPeg integer;
contaParVarBil integer;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
elemTipoCode:='CAP-UG'; -- tipo capitolo previsione
elemTipoCode_UG:='CAP_UG';	--- Capitolo gestione

anno_bil_impegni:= ((p_anno::INTEGER)-1)::VARCHAR;
contaParVarPeg:=0;
contaParVarBil:=0;

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
display_error='';

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  -- DAVIDE - SIAC-5202 - oltre 4 variazioni, il codice si sfonda
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    --strApp=REPLACE(p_ele_variazioni,',','');
    --raise notice 'VAR: %', strApp;
    intApp = strApp::INTEGER;
  END LOOP;
  -- DAVIDE - SIAC-5202 - FINE

END IF;

--INC000004803136 10/03/2021.
--Controllo aggiunto per ovviare ad un errato passaggio di parametri dal report.
--Dovra' essere tolto quando il report sara' corretto.
if p_code_sac_direz_peg = '99' then
	p_code_sac_direz_peg:='999';
end if;
if p_code_sac_direz_bil = '99' then
	p_code_sac_direz_bil:='999';
end if;


/* 26/09/2017: parametri nuovi, controllo che se e' passato uno tra numero/anno/tipo
    	provvedimento di variazione di PEG o di BILANCIO, siano passati anche
        gli altri 2. */
if p_num_provv_var_peg IS NOT  NULL THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_anno_provv_var_peg IS NOT  NULL AND p_anno_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_tipo_provv_var_peg IS NOT  NULL AND p_tipo_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if contaParVarPeg not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di PEG''';
    return next;
    return;        
end if;

if p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if contaParVarBil not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di Bilancio''';
    return next;
    return;        
end if;

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
-------siac_v_mis_pro_tit_macr_anni v 
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
*/


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
  , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 06/09/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
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
    anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
	-----cat_del_capitolo.elem_cat_code	=	'STD'
    -- 06/09/2016: aggiunto FPVC
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
   


insert into siac_rep_cap_up_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo),
       		cat_del_capitolo.elem_cat_code tipologia_capitolo           
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
    	/*and	capitolo_importi.ente_proprietario_id 	=capitolo_imp_tipo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id 	=capitolo_imp_periodo.ente_proprietario_id
   		and capitolo_importi.ente_proprietario_id	=capitolo_imp_tipo.ente_proprietario_id	
        and capitolo_importi.ente_proprietario_id	=capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=bilancio.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=anno_eserc.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=stato_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=r_capitolo_stato.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=cat_del_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=r_cat_capitolo.ente_proprietario_id*/
        and	anno_eserc.anno							= p_anno 													
    	and	bilancio.periodo_id						=anno_eserc.periodo_id 								
        and	capitolo.bil_id							=bilancio.bil_id 			 
        and	capitolo.elem_id						=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id					=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 			= elemTipoCode
        and	capitolo_importi.elem_det_tipo_id		=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
        -- 06/09/2016: aggiunto FPV (che era in query successiva che 
        -- e' stata tolta) e FPVC        		
		and	cat_del_capitolo.elem_cat_code	in ('STD','FSC','FPV','FPVC')								
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
    group by   capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente, cat_del_capitolo.elem_cat_code
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


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
        user_table utente
from   
	siac_rep_cap_up_imp tb1, siac_rep_cap_up_imp tb2, siac_rep_cap_up_imp tb3,
	siac_rep_cap_up_imp tb4, siac_rep_cap_up_imp tb5, siac_rep_cap_up_imp tb6
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb3.elem_id	=	tb4.elem_id								and
        			tb4.elem_id	=	tb5.elem_id								and
        			tb5.elem_id	=	tb6.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	and	tb1.tipo_capitolo 		in ('STD','FSC')
                    AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	and	tb2.tipo_capitolo 		in ('STD','FSC')
                    AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp	and	tb3.tipo_capitolo 	in ('STD','FSC')
                    AND
        			tb4.periodo_anno = tb1.periodo_anno	AND	tb4.tipo_imp = 	TipoImpRes	and	tb4.tipo_capitolo 		in ('STD','FSC')
                    AND
        			tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzresidui	and	tb5.tipo_capitolo 		in ('STD','FSC')
                    AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	TipoImpCassa and	tb6.tipo_capitolo 		in ('STD','FSC')
                    and tb1.utente 	= 	tb2.utente	
        			and	tb2.utente	=	tb3.utente
        			and	tb3.utente	=	tb4.utente
        			and	tb4.utente	=	tb5.utente
        			and tb5.utente	=	tb6.utente
        			and	tb6.utente	=	user_table;
                
/* SIAC-8785 03/08/2022.
   Per gli importi dei capitoli FPV occorre inserire anche la cassa e
   i residui per prevenire eventuali errori di importi inseriti come FPV che poi
   eventualmente potrebbero essere tolti tramite variazione */                    
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
        AND  -- 06/09/2016: aggiunto FPVC
    	tb7.periodo_anno = annoCapImp AND	tb7.tipo_imp = 	TipoImpstanzresidui	and	tb7.tipo_capitolo	IN ('FPV','FPVC')
        and
    	tb8.periodo_anno = annoCapImp	AND	tb8.tipo_imp =	TipoImpComp			and	tb8.tipo_capitolo 		IN ('FPV','FPVC')
        AND
        tb9.periodo_anno = annoCapImp1	AND	tb9.tipo_imp =	tb8.tipo_imp 		and	tb9.tipo_capitolo		IN ('FPV','FPVC')
        and
        tb10.periodo_anno = annoCapImp2	AND	tb10.tipo_imp =	tb8.tipo_imp		and	tb10.tipo_capitolo		IN ('FPV','FPVC')
        and tb7.utente 	= 	tb8.utente	
        and	tb8.utente	=	tb9.utente
        and	tb9.utente	=	tb10.utente	
        and	tb10.utente	=	user_table;

*/
-- insert modificata per SIAC-8785: inseriti anche cassa e residui per PFV.
insert into siac_rep_cap_up_imp_riga
select  tb7.elem_id,      
    	0,
    	0,
    	0,
   	 	tb11.importo	as		stanziamento_prev_res_anno,
    	0,
    	tb12.importo 	as 		stanziamento_prev_cassa_anno,
        tb7.importo		as		stanziamento_fpv_anno_prec,
  		tb8.importo		as		stanziamento_fpv_anno,
  		tb9.importo		as		stanziamento_fpv_anno1,
  		tb10.importo	as		stanziamento_fpv_anno2,
        tb7.ente_proprietario,
        user_table utente 
from 
        siac_rep_cap_up_imp tb7, siac_rep_cap_up_imp tb8, siac_rep_cap_up_imp tb9,
        siac_rep_cap_up_imp tb10, siac_rep_cap_up_imp tb11, siac_rep_cap_up_imp tb12
where tb7.elem_id	=	tb8.elem_id 
and tb8.elem_id	=	tb9.elem_id
and  tb9.elem_id	=	tb10.elem_id 
and  tb10.elem_id	=	tb11.elem_id 
and  tb11.elem_id	=	tb12.elem_id 
AND  -- 06/09/2016: aggiunto FPVC
	tb7.periodo_anno = annoCapImp AND	tb7.tipo_imp = 	TipoImpstanzresidui	and	tb7.tipo_capitolo	IN ('FPV','FPVC')
and tb8.periodo_anno = annoCapImp	AND	tb8.tipo_imp =	TipoImpComp			and	tb8.tipo_capitolo 		IN ('FPV','FPVC')
AND tb9.periodo_anno = annoCapImp1	AND	tb9.tipo_imp =	tb8.tipo_imp 		and	tb9.tipo_capitolo		IN ('FPV','FPVC')
and tb10.periodo_anno = annoCapImp2	AND	tb10.tipo_imp =	tb8.tipo_imp		and	tb10.tipo_capitolo		IN ('FPV','FPVC')
and tb11.periodo_anno = annoCapImp	AND	tb11.tipo_imp =	TipoImpRes			and	tb11.tipo_capitolo 		IN ('FPV','FPVC')
and tb12.periodo_anno = annoCapImp	AND	tb12.tipo_imp =	TipoImpCassa		and	tb12.tipo_capitolo 		IN ('FPV','FPVC')
and tb7.utente 	= 	tb8.utente	
and	tb8.utente	=	tb9.utente
and	tb9.utente	=	tb10.utente	
and	tb10.utente	=	tb11.utente	
and	tb11.utente	=	tb12.utente	
and	tb12.utente	=	user_table;                 
                                       
                   


/*
insert into siac_rep_cap_up_imp_riga
select  tb7.elem_id,      
    	0,
    	0,
    	0,
   	 	0,
    	0,
    	tb6.importo		as		stanziamento_prev_cassa_anno,
        tb7.importo		as		stanziamento_fpv_anno_prec,
  		tb8.importo		as		stanziamento_fpv_anno,
  		tb9.importo		as		stanziamento_fpv_anno1,
  		tb10.importo	as		stanziamento_fpv_anno2,
        tb7.ente_proprietario,
        user_table utente from 
        siac_rep_cap_up_imp tb6,siac_rep_cap_up_imp tb7, siac_rep_cap_up_imp tb8, siac_rep_cap_up_imp tb9,
        siac_rep_cap_up_imp tb10
         where	
        tb6.elem_id	=	tb7.elem_id
        and 	
        tb7.elem_id	=	tb8.elem_id
        and
		tb8.elem_id	=	tb9.elem_id
        and
        tb9.elem_id	=	tb10.elem_id 
        AND
        tb6.periodo_anno = annoCapImp	AND	tb6.tipo_imp = 	TipoImpCassa and	tb6.tipo_capitolo 		= 'FPV'
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
        and	tb10.utente	=	user_table;
        
*/

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
        0,
        '',
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
            -----------left JOIN siac_r_bil_elem_rel_tempo tbprec ON tbprec.elem_id = tb.elem_id
    where v1.utente = user_table      
           order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID;           

 -------------------------------------
--26/07/2016:
--se sono state specificate delle variazioni cerco i relativi valori
/*25/09/2017: aggiunto anche il controllo relativo ai parametri degli atti.
	Nelle variabili contaParVarPeg e contaParVarBil sono contenuti il numero di parametri 
	riguardanti le delibere PEG e Bilancio; se sono 3 (numero, anno e tipo) significa
    che quel parametro e' stato passato e quindi devo aggiungere il filtro. 
    Aggiunto anche il controllo relativo alle direzione e settori.
    Se p_code_sac_direz_peg e p_code_sac_direz_bil sono uguali a 999 significa che NON
    sono stati specificati. */
--IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') OR
	 contaParVarPeg= 3 OR contaParVarBil = 3 OR p_code_sac_direz_peg <> '999' OR
     p_code_sac_direz_bil <> '999' THEN
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
            siac_t_bil                  bilancio ';
	if contaParVarPeg = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto ,
            siac_d_atto_amm_tipo		tipo_atto,
			siac_r_atto_amm_stato 		r_atto_stato,
	        siac_d_atto_amm_stato 		stato_atto ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto2 ,
            siac_d_atto_amm_tipo		tipo_atto2,
			siac_r_atto_amm_stato 		r_atto_stato2,
	        siac_d_atto_amm_stato 		stato_atto2 ';
    end if;
    IF p_code_sac_direz_peg <> '999'  THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti'; 
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti2'; 
    END IF;                      
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
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id						=	atto.attoamm_id
    	and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    	and 	atto.attoamm_id										= 	r_atto_stato.attoamm_id
    	and 	r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id_varbil				=	atto2.attoamm_id
    	and		atto2.attoamm_tipo_id								=	tipo_atto2.attoamm_tipo_id
    	and 	atto2.attoamm_id									= 	r_atto_stato2.attoamm_id
    	and 	r_atto_stato2.attoamm_stato_id						=	stato_atto2.attoamm_stato_id ';
    end if;        
    IF p_code_sac_direz_peg <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id =ele_dir_sett_atti.attoamm_id ';
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id_varbil =ele_dir_sett_atti2.attoamm_id ';
    END IF;
    sql_query=sql_query || ' and		testata_variazione.ente_proprietario_id	= ' || p_ente_prop_id|| '
    and		anno_eserc.anno			= 	'''||p_anno||'''
    --10/10/2022 SIAC-8827  Aggiunto lo stato BD.
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'',''BD'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';
	IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    end if;
    if contaParVarPeg = 3 then 
    	sql_query=sql_query|| ' AND stato_atto.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto.attoamm_numero ='||p_num_provv_var_peg||' 
    	and 	atto.attoamm_anno ='''||p_anno_provv_var_peg||'''
    	and		tipo_atto.attoamm_tipo_code='''||p_tipo_provv_var_peg||''' ';
    end if;
   
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' AND stato_atto2.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto2.attoamm_numero ='||p_num_provv_var_bil||' 
    	and 	atto2.attoamm_anno ='''||p_anno_provv_var_bil||'''
    	and		tipo_atto2.attoamm_tipo_code='''||p_tipo_provv_var_bil||''' ';
    end if;
    IF p_code_sac_direz_peg <> '999' THEN
    	IF p_code_sac_sett_peg = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' ';
        ELSIF p_code_sac_sett_peg = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificati un settore.
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''||p_code_sac_sett_peg||'''';
        END IF;
    END IF;

    IF p_code_sac_direz_bil <> '999' THEN
    	IF p_code_sac_sett_bil = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' ';
        ELSIF p_code_sac_sett_bil = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificato un settore.
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''||p_code_sac_sett_bil||'''';
        END IF;
    END IF;
    sql_query=sql_query||' and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query || ' and 	atto.data_cancellazione						is null
    	and 	tipo_atto.data_cancellazione				is null
    	and 	r_atto_stato.data_cancellazione				is null ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query || ' and 	atto2.data_cancellazione		is null
    	and 	tipo_atto2.data_cancellazione				is null
    	and 	r_atto_stato2.data_cancellazione			is null ';
    end if;
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query: % ',  sql_query;        

EXECUTE sql_query;

RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

   insert into siac_rep_var_spese_riga
select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
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
	siac_rep_cap_up tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=p_anno
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=p_anno
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=p_anno
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=p_anno
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=p_anno
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
   union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
       annocapimp1
from   
	siac_rep_cap_up tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp1
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp1
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp1
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp1
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp1
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp1
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
        union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
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
	siac_rep_cap_up tb0 
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
        where  tb0.utente = user_table    ; 
end if;

-------------------------------------

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
    	COALESCE (t1.stanziamento_prev_anno,0)			stanziamento_prev_anno,
    	COALESCE (t1.stanziamento_prev_anno1,0)			stanziamento_prev_anno1,
    	COALESCE (t1.stanziamento_prev_anno2,0)			stanziamento_prev_anno2,
   	 	COALESCE (t1.stanziamento_prev_res_anno,0)		stanziamento_prev_res_anno,
    	COALESCE (t1.stanziamento_anno_prec,0)			stanziamento_anno_prec,
    	COALESCE (t1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
        COALESCE(t1.stanziamento_fpv_anno_prec,0)	stanziamento_fpv_anno_prec,
        COALESCE(t1.stanziamento_fpv_anno,0)	stanziamento_fpv_anno, 
        COALESCE(t1.stanziamento_fpv_anno1,0)	stanziamento_fpv_anno1, 
        COALESCE(t1.stanziamento_fpv_anno2,0)	stanziamento_fpv_anno2 ,
        COALESCE (var_anno.variazione_aumento_cassa, 0)		variazione_aumento_cassa,
        COALESCE (var_anno.variazione_aumento_residuo, 0)	variazione_aumento_residuo,
        COALESCE (var_anno.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato,
        COALESCE (var_anno.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa,
        COALESCE (var_anno.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo,
        COALESCE (var_anno.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato,
        COALESCE (var_anno1.variazione_aumento_cassa, 0)		variazione_aumento_cassa1,
        COALESCE (var_anno1.variazione_aumento_residuo, 0)	variazione_aumento_residuo1,
        COALESCE (var_anno1.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato1,
        COALESCE (var_anno1.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa1,
        COALESCE (var_anno1.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo1,
        COALESCE (var_anno1.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato1,
        COALESCE (var_anno2.variazione_aumento_cassa, 0)		variazione_aumento_cassa2,
        COALESCE (var_anno2.variazione_aumento_residuo, 0)	variazione_aumento_residuo2,
        COALESCE (var_anno2.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato2,
        COALESCE (var_anno2.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa2,
        COALESCE (var_anno2.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo2,
        COALESCE (var_anno2.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato2                    
from siac_rep_mptm_up_cap_importi t1
		left	join  siac_rep_var_spese_riga var_anno 
           			on (var_anno.elem_id	=	t1.elem_id
                    	and var_anno.periodo_anno= annoCapImp
                    	and	t1.utente=user_table
                        and var_anno.utente	=	t1.utente)         
			left	join  siac_rep_var_spese_riga var_anno1
           			on (var_anno1.elem_id	=	t1.elem_id
                    	and var_anno1.periodo_anno= annoCapImp1
                    	and	t1.utente=user_table
                        and var_anno1.utente	=	t1.utente)  
			left	join  siac_rep_var_spese_riga var_anno2
           			on (var_anno2.elem_id	=	t1.elem_id
                    	and var_anno2.periodo_anno= annoCapImp2
                    	and	t1.utente=user_table
                        and var_anno2.utente	=	t1.utente)   
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
          impegnato_anno:=0;
          impegnato_anno1:=0;
          impegnato_anno2=0;

--25/07/2016: sommo gli eventuali valori delle variazioni
--stanziamento_prev_anno=stanziamento_prev_anno+classifBilRec.variazione_aumento_stanziato+
---            					    classifBilRec.variazione_diminuzione_stanziato;
stanziamento_prev_cassa_anno=stanziamento_prev_cassa_anno+classifBilRec.variazione_aumento_cassa+
            					    classifBilRec.variazione_diminuzione_cassa;                                    
--stanziamento_prev_anno1=stanziamento_prev_anno1+classifBilRec.variazione_aumento_stanziato1+
--            					    classifBilRec.variazione_diminuzione_stanziato1;
--stanziamento_prev_anno2=stanziamento_prev_anno2+classifBilRec.variazione_aumento_stanziato2+
--            					    classifBilRec.variazione_diminuzione_stanziato2;
stanziamento_prev_res_anno=stanziamento_prev_res_anno+classifBilRec.variazione_aumento_residuo+
            					    classifBilRec.variazione_diminuzione_residuo;


select b.elem_cat_code into cat_capitolo from siac_r_bil_elem_categoria a, siac_d_bil_elem_categoria b
where a.elem_id=classifBilRec.bil_ele_id 
and a.data_cancellazione is null
and a.validita_fine is null
and a.elem_cat_id=b.elem_cat_id;

--raise notice 'XXXX tipo_categ_capitolo = %', cat_capitolo;
--raise notice 'XXXX elem id = %', classifBilRec.bil_ele_id ;


if cat_capitolo = 'FPV' or cat_capitolo = 'FPVC' then 
stanziamento_fpv_anno=stanziamento_fpv_anno+classifBilRec.variazione_aumento_stanziato+
            					    classifBilRec.variazione_diminuzione_stanziato;

stanziamento_fpv_anno1=stanziamento_fpv_anno1+classifBilRec.variazione_aumento_stanziato1+
            					    classifBilRec.variazione_diminuzione_stanziato1;
stanziamento_fpv_anno2=stanziamento_fpv_anno2+classifBilRec.variazione_aumento_stanziato2+
            					    classifBilRec.variazione_diminuzione_stanziato2;
else

stanziamento_prev_anno=stanziamento_prev_anno+classifBilRec.variazione_aumento_stanziato+
            					    classifBilRec.variazione_diminuzione_stanziato;
	
stanziamento_prev_anno1=stanziamento_prev_anno1+classifBilRec.variazione_aumento_stanziato1+
            					    classifBilRec.variazione_diminuzione_stanziato1;
                                    
stanziamento_prev_anno2=stanziamento_prev_anno2+classifBilRec.variazione_aumento_stanziato2+
            					    classifBilRec.variazione_diminuzione_stanziato2;

end if;


/*          
if classifBilRec.variazione_aumento_stanziato <> 0 OR
	classifBilRec.variazione_diminuzione_stanziato <> 0 OR
    classifBilRec.variazione_aumento_cassa <> 0 OR
    classifBilRec.variazione_diminuzione_cassa <> 0 OR    
    classifBilRec.variazione_aumento_stanziato1 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato1 <> 0 OR
    classifBilRec.variazione_aumento_stanziato2 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato2 <> 0 OR  
    classifBilRec.variazione_aumento_residuo <> 0 OR
    classifBilRec.variazione_diminuzione_residuo <> 0 THEN
raise notice 'Cap %, ID = %, Missione = %, Programma = %, Titolo %', bil_ele_code, bil_ele_id, missione_code, programma_code, titusc_code;
raise notice '  variazione_aumento_stanziato = %',classifBilRec.variazione_aumento_stanziato;
raise notice '  variazione_diminuzione_stanziato = %',classifBilRec.variazione_diminuzione_stanziato;
raise notice '  variazione_aumento_cassa = %',classifBilRec.variazione_aumento_cassa;
raise notice '  variazione_diminuzione_cassa = %',classifBilRec.variazione_diminuzione_cassa;
raise notice '  variazione_aumento_stanziato1 = %',classifBilRec.variazione_aumento_stanziato1;
raise notice '  variazione_diminuzione_stanziato1 = %',classifBilRec.variazione_diminuzione_stanziato1;
raise notice '  variazione_aumento_stanziato2 = %',classifBilRec.variazione_aumento_stanziato2;
raise notice '  variazione_diminuzione_stanziato2 = %',classifBilRec.variazione_diminuzione_stanziato2;
raise notice '  variazione_aumento_residuo = %',classifBilRec.variazione_aumento_residuo;
raise notice '  variazione_diminuzione_residuo = %',classifBilRec.variazione_diminuzione_residuo;

end if;            */

-- restituisco il record complessivo
/*raise notice 'record %', classifBilRec.bil_ele_id;
 h_count:=h_count+1;
 raise notice 'n. record %', h_count;*/
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

end loop;

delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;
delete from siac_rep_cap_up where utente=user_table;
delete from siac_rep_cap_up_imp where utente=user_table;
delete from siac_rep_cap_up_imp_riga where utente=user_table;
delete from siac_rep_mptm_up_cap_importi where utente=user_table;
delete from siac_rep_var_spese  					where utente=user_table;
delete from siac_rep_var_spese_riga  				where utente=user_table;


raise notice 'fine OK';
    exception
    when no_data_found THEN
      raise notice 'nessun dato trovato per struttura bilancio';
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
      RTN_MESSAGGIO:='struttura bilancio altro errore';
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

ALTER FUNCTION siac."BILR112_Allegato_9_bill_gest_quadr_riass_gen_spese" (p_ente_prop_id integer, p_anno varchar, p_disavanzo boolean, p_ele_variazioni varchar, p_num_provv_var_peg integer, p_anno_provv_var_peg varchar, p_tipo_provv_var_peg varchar, p_num_provv_var_bil integer, p_anno_provv_var_bil varchar, p_tipo_provv_var_bil varchar, p_code_sac_direz_peg varchar, p_code_sac_sett_peg varchar, p_code_sac_direz_bil varchar, p_code_sac_sett_bil varchar)
  OWNER TO siac;