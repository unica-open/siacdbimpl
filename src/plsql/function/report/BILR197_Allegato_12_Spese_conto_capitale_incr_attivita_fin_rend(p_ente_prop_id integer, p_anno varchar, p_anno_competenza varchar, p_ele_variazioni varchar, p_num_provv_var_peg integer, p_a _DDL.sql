/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac."BILR197_Allegato_12_Spese_conto_capitale_incr_attivita_fin_rend" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_competenza varchar,
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
  stanziamento_prev_anno numeric,
  display_error varchar
) AS
$body$
DECLARE

tipoImpComp varchar;
elemTipoCode varchar;
cap_std	varchar;
cap_fpv	varchar;
cap_fsc	varchar;
bilancio_id integer;

intApp integer;
strApp varchar;
x_array varchar [];

contaParVarPeg integer;
contaParVarBil integer;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';

BEGIN

display_error :='';
contaParVarPeg:=0;
contaParVarBil:=0;

TipoImpComp='STA';      -- competenza
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione
cap_std:='STD';
cap_fpv:='FPV';
cap_fsc:='FSC';

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
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

/*  22/09/2017: parametri nuovi, controllo che se e' passato uno tra numero/anno/tipo
    provvedimento di variazione di PEG o di BILANCIO, siano passati anche
    gli altri 2. */
IF p_num_provv_var_peg IS NOT  NULL THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF p_anno_provv_var_peg IS NOT  NULL AND p_anno_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF p_tipo_provv_var_peg IS NOT  NULL AND p_tipo_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF contaParVarPeg not in (0,3) THEN
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di PEG''';
    return next;
    return;        
END IF;

IF p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF contaParVarBil not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di Bilancio''';
    return next;
    return;        
END IF;

select a.bil_id 
into  bilancio_id 
from  siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id
and   b.periodo_id = a.periodo_id
and   b.anno = p_anno;

RETURN query
SELECT
zz.*
FROM (
with strut_bilancio as (
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
and d.classif_fam_code = v_fam_missioneprogramma
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
and d.classif_fam_code = v_fam_missioneprogramma
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
and d.classif_fam_code = v_fam_titolomacroaggregato
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
and d.classif_fam_code = v_fam_titolomacroaggregato
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
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
from missione , programma,titusc, macroag
/* 07/09/2016: start filtro per mis-prog-macro*/
-- forzatura schemi 2017 , siac_r_class progmacro
/*end filtro per mis-prog-macro*/
where programma.missione_id=missione.missione_id
and titusc.titusc_id=macroag.titusc_id
/* 07/09/2016: start filtro per mis-prog-macro*/
-- forzatura schemi 2017 AND programma.programma_id = progmacro.classif_a_id
-- forzatura schemi 2017 AND titusc.titusc_id = progmacro.classif_b_id
/* end filtro per mis-prog-macro*/ 
and titusc.titusc_code in ('2','3')
and titusc.ente_proprietario_id=missione.ente_proprietario_id
 -- forzatura schemi 2017
and exists ( select 1 
             from siac_r_class x, siac_t_class y, siac_d_class_tipo z
             where programma.programma_id = x.classif_a_id
             and y.classif_id = x.classif_b_id 
             and y.classif_tipo_id=z.classif_tipo_id
             and z.classif_tipo_code ='TITOLO_SPESA'
             and y.classif_code in ('2','3')
           )
 -- forzatura schemi 2017
),
capitoli as (
select 	programma.classif_id as programma_id,
		macroaggr.classif_id as macroaggr_id,
        -- anno_eserc.anno anno_bilancio,
       	capitolo.elem_id
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
where programma_tipo.classif_tipo_code = 'PROGRAMMA' 									
and   programma.classif_tipo_id		   = programma_tipo.classif_tipo_id 				
and   programma.classif_id			   = r_capitolo_programma.classif_id					
and   macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
and   macroaggr.classif_tipo_id		   = macroaggr_tipo.classif_tipo_id 				
and   macroaggr.classif_id			   = r_capitolo_macroaggr.classif_id					
and   capitolo.ente_proprietario_id	   = p_ente_prop_id      												
and   capitolo.bil_id				   = bilancio_id										
and   capitolo.elem_tipo_id			   = tipo_elemento.elem_tipo_id 						
and   tipo_elemento.elem_tipo_code 	   = elemTipoCode						     	 
and   capitolo.elem_id				   = r_capitolo_programma.elem_id							
and   capitolo.elem_id				   = r_capitolo_macroaggr.elem_id						    
and   capitolo.elem_id				   = r_capitolo_stato.elem_id			
and	  r_capitolo_stato.elem_stato_id   = stato_capitolo.elem_stato_id		
and	  stato_capitolo.elem_stato_code   = 'VA'								
and   capitolo.elem_id				   = r_cat_capitolo.elem_id				
and	  r_cat_capitolo.elem_cat_id	   = cat_del_capitolo.elem_cat_id		
-- 05/08/2016: aggiunto FPVC
and   cat_del_capitolo.elem_cat_code	in (cap_std, cap_fpv, cap_fsc,'FPVC')
-- cat_del_capitolo.elem_cat_code	=	'STD'		
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
),
stanziamento as (
select 	capitolo_importi.elem_id,
        capitolo_imp_periodo.anno 				anno_stanziamento_parziale,
        capitolo_imp_tipo.elem_det_tipo_code 	tipo_elem_det,
        sum(capitolo_importi.elem_det_importo)  imp_stanziamento_parziale   
from 	siac_t_bil_elem_det 			capitolo_importi,
        siac_d_bil_elem_det_tipo 		capitolo_imp_tipo,
        siac_t_periodo 					capitolo_imp_periodo,
        siac_t_bil_elem 				capitolo,
        siac_d_bil_elem_tipo 			tipo_elemento,
        siac_d_bil_elem_stato 			stato_capitolo, 
        siac_r_bil_elem_stato 			r_capitolo_stato,
        siac_d_bil_elem_categoria	 	cat_del_capitolo,
        siac_r_bil_elem_categoria 		r_cat_capitolo
where 	capitolo_importi.ente_proprietario_id   = p_ente_prop_id  							
and	    capitolo.bil_id							= bilancio_id			 
and	    capitolo.elem_id						= capitolo_importi.elem_id 
and	    capitolo.elem_tipo_id					= tipo_elemento.elem_tipo_id 						
and	    tipo_elemento.elem_tipo_code 			= elemTipoCode
and	    capitolo_importi.elem_det_tipo_id		= capitolo_imp_tipo.elem_det_tipo_id 		
and	    capitolo_imp_periodo.periodo_id			= capitolo_importi.periodo_id 			  
and	    capitolo_imp_periodo.anno               = p_anno_competenza       
and	    capitolo.elem_id				        = r_capitolo_stato.elem_id			
and	    r_capitolo_stato.elem_stato_id			= stato_capitolo.elem_stato_id		
and	    stato_capitolo.elem_stato_code			= 'VA'								
and	    capitolo.elem_id						= r_cat_capitolo.elem_id				
and	    r_cat_capitolo.elem_cat_id				= cat_del_capitolo.elem_cat_id
-- 05/08/2016: aggiunto FPVC
and	    cat_del_capitolo.elem_cat_code	in (cap_std, cap_fpv, cap_fsc, 'FPVC')	
-- and	cat_del_capitolo.elem_cat_code	=	'STD'								
and	    capitolo_importi.data_cancellazione 		is null
and	    capitolo_imp_tipo.data_cancellazione 		is null
and	    capitolo_imp_periodo.data_cancellazione 	is null
and	    capitolo.data_cancellazione 				is null
and	    tipo_elemento.data_cancellazione 			is null
and	    stato_capitolo.data_cancellazione 			is null 
and	    r_capitolo_stato.data_cancellazione 		is null
and     cat_del_capitolo.data_cancellazione 		is null
and	    r_cat_capitolo.data_cancellazione 			is null
group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno
),
variazioni as (
select *
from fnc_variazioni_bozza (
  p_ente_prop_id,
  p_anno_competenza,
  p_ele_variazioni,
  p_num_provv_var_peg,
  p_anno_provv_var_peg,
  p_tipo_provv_var_peg,
  p_num_provv_var_bil,
  p_anno_provv_var_bil,
  p_tipo_provv_var_bil,
  p_code_sac_direz_peg,
  p_code_sac_sett_peg,
  p_code_sac_direz_bil,
  p_code_sac_sett_bil,
  contaParVarPeg,
  contaParVarBil,
  elemTipoCode
)
where tipo_capitolo in (cap_std, cap_fpv, cap_fsc, 'FPVC')
)
select 
p_anno::varchar,
null::varchar  missione_tipo_code,
strut_bilancio.missione_tipo_desc::varchar,
strut_bilancio.missione_code::varchar,
strut_bilancio.missione_desc::varchar,
null::varchar  programma_tipo_code,
strut_bilancio.programma_tipo_desc::varchar,
SUBSTRING(strut_bilancio.programma_code from 3)::varchar programma_code,
strut_bilancio.programma_desc::varchar,
null::varchar  titusc_tipo_code,
strut_bilancio.titusc_tipo_desc::varchar,
strut_bilancio.titusc_code::varchar,
strut_bilancio.titusc_desc::varchar,
null::varchar  macroag_tipo_code,
strut_bilancio.macroag_tipo_desc::varchar,
strut_bilancio.macroag_code::varchar,
strut_bilancio.macroag_desc::varchar,
--capitoli.elem_id::integer,
COALESCE(stanziamento.imp_stanziamento_parziale,0)::numeric + COALESCE(variazioni.imp_variazioni,0)::numeric as imp_stanziamento,     
display_error::varchar
from   strut_bilancio
left   join capitoli on  strut_bilancio.programma_id = capitoli.programma_id
                     and strut_bilancio.macroag_id = capitoli.macroaggr_id
left   join stanziamento on stanziamento.elem_id = capitoli.elem_id 
                         and stanziamento.anno_stanziamento_parziale = p_anno_competenza
                         and stanziamento.tipo_elem_det = tipoImpComp 
left join variazioni on variazioni.elem_id = capitoli.elem_id 
                     and variazioni.anno_variazioni = p_anno_competenza
                     and variazioni.tipo_elem_det = tipoImpComp                                              
) as zz; 
                    
raise notice 'fine OK';

EXCEPTION    
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce record solo per struttura' ;
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
        RTN_MESSAGGIO:='';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;