/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR123_impegni_pluriennali" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
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
  prev_comp_anno1 numeric,
  prev_comp_anno2 numeric,
  prev_comp_anno_succ numeric,
  impegnato_anno1 numeric,
  impegnato_anno2 numeric,
  impegnato_anno_succ numeric,
  prev_fpv_anno1 numeric,
  prev_fpv_anno2 numeric,
  prev_fpv_anno_succ numeric
) AS
$body$
DECLARE

classifBilRec record;
ImpegniRec record;

annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
elemTipoCode varchar;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
annoPrec VARCHAR;

v_importo_imp1   NUMERIC :=0;
v_importo_imp2  NUMERIC :=0;
v_importo_imp_succ  NUMERIC :=0;

var_id_elem  integer :=0;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';

BEGIN

annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione

annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;

select fnc_siac_random_user()
into	user_table;

raise notice '1: %', clock_timestamp()::varchar;  
raise notice 'user  %',user_table;
 
bil_anno='';
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
prev_comp_anno1=0;
prev_comp_anno2=0;
prev_comp_anno_succ=0;
impegnato_anno1=0;
impegnato_anno2=0;
impegnato_anno_succ=0;
prev_fpv_anno1=0;
prev_fpv_anno2=0;
prev_fpv_anno_succ=0;
      
RTN_MESSAGGIO:='lettura struttura del bilancio''.';  
raise notice '2: %', clock_timestamp()::varchar;  

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
    /*start filtro per mis-prog-macro*/
    , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
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
    /*start filtro per mis-prog-macro*/
    AND programma.classif_id = progmacro.classif_a_id
    AND titusc.classif_id = progmacro.classif_b_id
    /*end filtro per mis-prog-macro*/    
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

raise notice '3: %', clock_timestamp()::varchar; 
RTN_MESSAGGIO:='insert tabella siac_rep_cap_up''.';  

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
    and	r_cat_capitolo.data_cancellazione 	 		is null;	

--09/05/2016: carico nella tabella di appoggio con i capitoli gli eventuali 
-- capitoli presenti sulla tabella con gli importi previsti anni precedenti
-- che possono avere cambiato numero di capitolo. 
/*insert into siac_rep_cap_up 
select programma.classif_id, macroaggr.classif_id, p_anno, NULL, prec.elem_code, prec.elem_code2, 
      	prec.elem_code3, NULL, NULL,  NULL, NULL, NULL, NULL, NULL,NULL,NULL,
        prec.ente_proprietario_id, prec.data_creazione, prec.data_modifica,
        prec.data_cancellazione,prec.login_operazione, NULL, user_table utente
      from siac_t_cap_u_importi_anno_prec prec,
        siac_d_class_tipo programma_tipo,
        siac_d_class_tipo macroaggr_tipo,
        siac_t_class programma,
        siac_t_class macroaggr
      where programma_tipo.classif_tipo_id	=	programma.classif_tipo_id
      and programma.classif_code=prec.programma_code
      and programma_tipo.classif_tipo_code	=	'PROGRAMMA'
      and macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 	
      and macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'
      and macroaggr.classif_code=prec.macroagg_code
      and programma.ente_proprietario_id =prec.ente_proprietario_id
      and macroaggr.ente_proprietario_id =prec.ente_proprietario_id
      and prec.ente_proprietario_id=p_ente_prop_id       
      and to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy')
		between programma.validita_inizio and
       COALESCE(programma.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
      and to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy')
		between macroaggr.validita_inizio and
       COALESCE(macroaggr.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
      and not exists (select 1 from siac_rep_cap_up up
      				where up.elem_code=prec.elem_code
                    	AND up.elem_code2=prec.elem_code2
                        and up.elem_code3=prec.elem_code3
                        and up.macroaggregato_id = macroaggr.classif_id
                        and up.programma_id = programma.classif_id
                        and up.utente=user_table
                        and up.ente_proprietario_id=p_ente_prop_id);*/
                        
-- REMEDY INC000001514672
-- Select ricostruita considerando la condizione sull'anno nella tabella siac_t_cap_u_importi_anno_prec                        
insert into siac_rep_cap_up                        
with prec as (       
select * From siac_t_cap_u_importi_anno_prec a
where a.anno=annoPrec       
and a.ente_proprietario_id=p_ente_prop_id
)
, progr as (
select * from siac_t_class a, siac_d_class_tipo b
where a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code = 'PROGRAMMA'
and a.data_cancellazione is null
and b.data_cancellazione is null
and a.ente_proprietario_id=p_ente_prop_id
and to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy') between
a.validita_inizio and COALESCE(a.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
)
, macro as (
select * from siac_t_class a, siac_d_class_tipo b
where a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code = 'MACROAGGREGATO'
and a.data_cancellazione is null
and b.data_cancellazione is null
and a.ente_proprietario_id=p_ente_prop_id
and to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy') between
a.validita_inizio and COALESCE(a.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
)
select progr.classif_id classif_id_programma, macro.classif_id classif_id_macroaggregato, p_anno,
NULL, prec.elem_code, prec.elem_code2,
       prec.elem_code3, NULL, NULL,  NULL, NULL, NULL, NULL, NULL,NULL,NULL,
        prec.ente_proprietario_id, prec.data_creazione, prec.data_modifica,
        prec.data_cancellazione,prec.login_operazione, NULL, user_table utente
 from prec
join progr on prec.programma_code=progr.classif_code
join macro on prec.macroagg_code=macro.classif_code
and not exists (select 1 from siac_rep_cap_up up
                      where up.elem_code=prec.elem_code
                        AND up.elem_code2=prec.elem_code2
                        and up.elem_code3=prec.elem_code3
                        and up.macroaggregato_id = macro.classif_id
                        and up.programma_id = progr.classif_id
                        and up.utente=user_table
                        and up.ente_proprietario_id=prec.ente_proprietario_id);
                                            
-----------------   importo capitoli di tipo standard ------------------------

RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp standard''.';  
raise notice '4: %', clock_timestamp()::varchar; 

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
        and	anno_eserc.anno					= p_anno 												
    	and	bilancio.periodo_id				=anno_eserc.periodo_id 								
        and	capitolo.bil_id					=bilancio.bil_id 			 
        and	capitolo.elem_id	=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code = elemTipoCode
        and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 			  
        --and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo_imp_periodo.anno >= annoCapImp1
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code	in ('STD','FSC', 'FPV', 'FPVC')						
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

raise notice '6: %', clock_timestamp()::varchar; 

insert into siac_rep_cap_up_imp_riga
select  tb1.elem_id,         
        tb1.importo 	as 		prev_comp_anno1, -- stanziamento_prev_anno,
        tb2.importo 	as		prev_comp_anno2,
        0,--tb3.importo		as		prev_comp_anno_succ,
        0,--tb4.importo		as		stanziamento_prev_res_anno,
        0,--tb5.importo		as		stanziamento_anno_prec,
        0,--tb6.importo		as		stanziamento_prev_cassa_anno,
        0,0,0,0,  
        tb1.ente_proprietario,      
        user_table utente 
from    siac_rep_cap_up_imp tb1, siac_rep_cap_up_imp tb2
/*left join siac_rep_cap_up_imp tb3 on tb2.elem_id = tb3.elem_id 
                                  and tb3.periodo_anno > annoCapImp2
                                  and tb2.tipo_imp = tb3.tipo_imp
                                  and tb3.tipo_capitolo in ('STD','FSC')
                                  and tb2.utente = tb3.utente*/
where	tb1.elem_id	=	tb2.elem_id     
and     tb1.periodo_anno = annoCapImp1	
and	    tb1.tipo_imp =	TipoImpComp			
and	    tb1.tipo_capitolo in ('STD','FSC')
and     tb2.periodo_anno = annoCapImp2 
and	    tb1.tipo_imp =	tb2.tipo_imp 		
and	    tb2.tipo_capitolo in ('STD','FSC')		   
and 	tb1.utente 	= 	tb2.utente	
and		tb1.utente	=	user_table;

raise notice '7: %', clock_timestamp()::varchar; 
RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp_riga FPV''.'; 
 
insert into siac_rep_cap_up_imp_riga
select  tb8.elem_id,      
    	0,
    	0,
    	0,
   	 	0,
    	0,
    	0,
        0,--tb7.importo		as		              stanziamento_fpv_anno_prec,
  		tb8.importo		as		prev_fpv_anno1,-- stanziamento_fpv_anno,
  		tb9.importo		as		prev_fpv_anno2,-- stanziamento_fpv_anno1,
  		0,--tb10.importo	as		prev_fpv_anno_succ,-- stanziamento_fpv_anno2,
        tb8.ente_proprietario,
        user_table utente 
from    siac_rep_cap_up_imp tb8, siac_rep_cap_up_imp tb9
/*left join siac_rep_cap_up_imp tb10 on tb9.elem_id	=	tb10.elem_id  
                                  and tb10.periodo_anno > annoCapImp2	
                                  and tb9.tipo_imp = tb10.tipo_imp
                                  and tb10.tipo_capitolo in( 'FPV','FPVC')
                                  and tb9.utente = tb10.utente	*/
where	tb8.elem_id	=	tb9.elem_id   
AND     tb8.periodo_anno = annoCapImp1 
AND	    tb8.tipo_imp = 	TipoImpComp	
and	    tb8.tipo_capitolo	in( 'FPV','FPVC')
and     tb9.periodo_anno = annoCapImp2	
AND	    tb8.tipo_imp =	tb9.tipo_imp			
and	    tb9.tipo_capitolo in( 'FPV','FPVC') 		
and	    tb8.utente	=	tb9.utente
and	    tb8.utente	=	user_table;
        
RTN_MESSAGGIO:='insert tabella siac_rep_mptm_up_cap_importi''.';  

-----------------------------------------------------------------------------------
-- EVENTUALMENTE DA AGGIUNGERE
/*raise notice '8: %', clock_timestamp()::varchar; 
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
					AND v1.utente=user_table
                    and	TB.utente=V1.utente)
            left	join    siac_rep_cap_up_imp_riga tb1  
            		on (tb1.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb1.utente	=	tb.utente)
            left JOIN siac_r_bil_elem_rel_tempo tbprec ON tbprec.elem_id = tb.elem_id
    where v1.utente = user_table
    		------and TB.utente=V1.utente
            ------and	tb1.utente	=	tb.utente
           order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID;
*/

-- Gestione impegni
for ImpegniRec in
  select tb2.elem_id,
  tb.movgest_anno,
  p_ente_prop_id,
  user_table utente,
  tb.importo
  from (select    
  m.movgest_anno::VARCHAR, 
  e.elem_id,
  sum (tsd.movgest_ts_det_importo) importo
      from 
          siac_t_bil b, 
          siac_t_periodo p, 
          siac_t_bil_elem e,
          siac_d_bil_elem_tipo et,
          siac_r_movgest_bil_elem rm, 
          siac_t_movgest m,
          siac_d_movgest_tipo mt,
          siac_t_movgest_ts ts  ,
          siac_d_movgest_ts_tipo   tsti, 
          siac_r_movgest_ts_stato tsrs,
          siac_d_movgest_stato mst, 
          siac_t_movgest_ts_det   tsd ,
          siac_d_movgest_ts_det_tipo  tsdt
        where 
        b.periodo_id					=	p.periodo_id 
        and p.ente_proprietario_id   	= 	p_ente_prop_id
        and p.anno          			=   p_anno 
        and b.bil_id 					= 	e.bil_id
        and e.elem_tipo_id			=	et.elem_tipo_id
        and et.elem_tipo_code      	=  	elemTipoCode
        and rm.elem_id      			= 	e.elem_id
        and rm.movgest_id      		=  	m.movgest_id 
        and now() between rm.validita_inizio and coalesce (rm.validita_fine, now())
        --and m.movgest_anno::VARCHAR   			 in (annoCapImp, annoCapImp1, annoCapImp2)
        and m.movgest_anno::VARCHAR   	>= annoCapImp1
        and m.movgest_tipo_id			= 	mt.movgest_tipo_id 
        and mt.movgest_tipo_code		='I' 
        and m.movgest_id				=	ts.movgest_id
        and ts.movgest_ts_id			=	tsrs.movgest_ts_id 
        and tsrs.movgest_stato_id  	= 	mst.movgest_stato_id 
        and tsti.movgest_ts_tipo_code  = 'T' 
        and mst.movgest_stato_code   in ('D','N') -- Definitivo e definitivo non liquidabile
        and now() between tsrs.validita_inizio and coalesce (tsrs.validita_fine, now())
        and ts.movgest_ts_tipo_id  	= 	tsti.movgest_ts_tipo_id 
        and ts.movgest_ts_id     		= 	tsd.movgest_ts_id 
        and tsd.movgest_ts_det_tipo_id  = tsdt.movgest_ts_det_tipo_id 
        and tsdt.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
        and now() between b.validita_inizio and coalesce (b.validita_fine, now())
        and now() between p.validita_inizio and coalesce (p.validita_fine, now())
        and now() between e.validita_inizio and coalesce (e.validita_fine, now())
        and now() between et.validita_inizio and coalesce (et.validita_fine, now())
        and now() between m.validita_inizio and coalesce (m.validita_fine, now())
        and now() between ts.validita_inizio and coalesce (ts.validita_fine, now())
        and now() between mt.validita_inizio and coalesce (ts.validita_fine, now())
        and now() between tsti.validita_inizio and coalesce (tsti.validita_fine, now())
        and now() between mst.validita_inizio and coalesce (mst.validita_fine, now())
        and now() between tsd.validita_inizio and coalesce (tsd.validita_fine, now())
        and now() between tsdt.validita_inizio and coalesce (tsdt.validita_fine, now())
        and p.data_cancellazione     	is null 
        and b.data_cancellazione      is null 
        and e.data_cancellazione      is null     
        and et.data_cancellazione     is null 
        and rm.data_cancellazione 	is null 
        and m.data_cancellazione      is null 
        and mt.data_cancellazione     is null 
        and ts.data_cancellazione   	is null 
        and tsti.data_cancellazione   is null 
        and tsrs.data_cancellazione   is null 
        and mst.data_cancellazione    is null 
        and tsd.data_cancellazione   	is null 
        and tsdt.data_cancellazione   is null      
  group by m.movgest_anno, e.elem_id )
  tb 
  ,
  (select * from  siac_t_bil_elem    			capitolo_ug,
                  siac_d_bil_elem_tipo    	t_capitolo_ug
        where capitolo_ug.elem_tipo_id		=	t_capitolo_ug.elem_tipo_id 
        and 	t_capitolo_ug.elem_tipo_code 	= 	elemTipoCode) tb2
  where
   tb2.elem_id	=	tb.elem_id
   
  LOOP
    
    v_importo_imp_succ  :=0;
    v_importo_imp1 :=0;
    v_importo_imp2 :=0;
    
    
    
    var_id_elem := 0;  
   
    SELECT rep_imp_riga.elem_id
    INTO var_id_elem
    FROM SIAC_REP_IMPEGNI_RIGA rep_imp_riga
    WHERE rep_imp_riga.elem_id=ImpegniRec.elem_id;
      
          IF var_id_elem IS NULL OR var_id_elem = 0 THEN
                 
          IF ImpegniRec.movgest_anno = annoCapImp1 THEN
             v_importo_imp1 := ImpegniRec.importo;
          ELSIF ImpegniRec.movgest_anno = annoCapImp2 THEN
             v_importo_imp2 := ImpegniRec.importo;
          ELSIF ImpegniRec.movgest_anno > annoCapImp2 THEN  
             v_importo_imp_succ := ImpegniRec.importo;
          END IF;   
      
          INSERT INTO SIAC_REP_IMPEGNI_RIGA
              (elem_id,
               impegnato_anno,
               impegnato_anno1,
               impegnato_anno2,
               ente_proprietario,
               utente)
          VALUES
              (ImpegniRec.elem_id,
               v_importo_imp1,
               v_importo_imp2,
               v_importo_imp_succ,
               p_ente_prop_id,
               ImpegniRec.utente
              );      
    ELSE 
          IF ImpegniRec.movgest_anno = annoCapImp1 THEN
             v_importo_imp1 := ImpegniRec.importo;
                       
            UPDATE 
              siac.SIAC_REP_IMPEGNI_RIGA 
            SET 
              impegnato_anno = v_importo_imp1
            WHERE 
                elem_id = ImpegniRec.elem_id AND
                ente_proprietario = p_ente_prop_id AND
 				utente = ImpegniRec.utente
              ;
                       
          ELSIF ImpegniRec.movgest_anno = annoCapImp2 THEN
             v_importo_imp2 := ImpegniRec.importo;
           
            UPDATE 
              siac.SIAC_REP_IMPEGNI_RIGA 
            SET 
              impegnato_anno1 = v_importo_imp2
            WHERE 
                elem_id = ImpegniRec.elem_id AND
                ente_proprietario = p_ente_prop_id AND
 				utente = ImpegniRec.utente
              ;
           
           
          ELSIF ImpegniRec.movgest_anno > annoCapImp2 THEN  
             v_importo_imp_succ := ImpegniRec.importo;
           
            UPDATE 
              siac.SIAC_REP_IMPEGNI_RIGA 
            SET 
              impegnato_anno2 = v_importo_imp_succ
            WHERE 
                elem_id = ImpegniRec.elem_id AND
                ente_proprietario = p_ente_prop_id AND
 				utente = ImpegniRec.utente
              ;
           
        END IF;    
    
    END IF;
            
  
      
    
    
    
    
    /*
    IF ImpegniRec.movgest_anno = annoCapImp1 THEN
       v_importo_imp1 := ImpegniRec.importo;
    ELSIF ImpegniRec.movgest_anno = annoCapImp2 THEN
       v_importo_imp2 := ImpegniRec.importo;
    ELSIF ImpegniRec.movgest_anno > annoCapImp2 THEN  
       v_importo_imp_succ := ImpegniRec.importo;
    END IF;     
       
    INSERT INTO SIAC_REP_IMPEGNI_RIGA
    	(elem_id,
  		 impegnato_anno,
         impegnato_anno1,
         impegnato_anno2,
         ente_proprietario,
         utente)
    VALUES
        (ImpegniRec.elem_id,
         v_importo_imp1,
         v_importo_imp2,
         v_importo_imp_succ,
         p_ente_prop_id,
         ImpegniRec.utente
        );     
  */
  END LOOP; 
   
 RTN_MESSAGGIO:='preparazione file output''.'; 
 
FOR classifBilRec IN
SELECT 	v1.titusc_tipo_desc    		    titusc_tipo_desc,
       	v1.titusc_id              		titusc_id,
       	v1.titusc_code             		titusc_code,
       	v1.titusc_desc                  titusc_desc,
        v1.macroag_tipo_desc            macroag_tipo_desc,		
      	v1.macroag_id             	    macroag_ID,
       	v1.macroag_code           	    macroag_CODE,
       	v1.macroag_desc           	    macroag_DESC,
    	tb.bil_anno    			        BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
        COALESCE(tb4.stanziamento_prev_anno,0)	  prev_comp_anno1,
        COALESCE(tb4.stanziamento_prev_anno1,0)	  prev_comp_anno2,
        --COALESCE(tb4.stanziamento_prev_anno2,0)	  prev_comp_anno_succ,
        COALESCE(tb4.stanziamento_fpv_anno,0)	  prev_fpv_anno1,
        COALESCE(tb4.stanziamento_fpv_anno1,0)	  prev_fpv_anno2,
        --COALESCE(tb4.stanziamento_fpv_anno2,0)	  prev_fpv_anno_succ,
        COALESCE(tb5.impegnato_anno,0) impegnato_anno1,
        COALESCE(tb5.impegnato_anno1,0) impegnato_anno2,
        COALESCE(tb5.impegnato_anno2,0) impegnato_anno_succ
FROM  	  siac_rep_mis_pro_tit_mac_riga_anni v1
LEFT JOIN siac_rep_cap_up tb ON ( v1.programma_id = tb.programma_id
                                  AND v1.macroag_id = tb.macroaggregato_id 
                                  AND v1.ente_proprietario_id = p_ente_prop_id
					              AND tb.utente = v1.utente
                                  AND v1.utente = user_table)	
LEFT JOIN  siac_rep_cap_up_imp_riga tb4 ON tb4.elem_id = tb.elem_id
LEFT JOIN  siac_rep_impegni_riga tb5 ON tb5.elem_id = tb.elem_id          	
ORDER BY titusc_code, macroag_CODE   
    	
loop

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
      prev_comp_anno1:=classifBilRec.prev_comp_anno1;
      prev_comp_anno2:=classifBilRec.prev_comp_anno2;
      --prev_comp_anno_succ:=classifBilRec.prev_comp_anno_succ;
      prev_fpv_anno1:=classifBilRec.prev_fpv_anno1; 
      prev_fpv_anno2:=classifBilRec.prev_fpv_anno2; 
      --prev_fpv_anno_succ:=classifBilRec.prev_fpv_anno_succ;
      impegnato_anno1:=classifBilRec.impegnato_anno1;
      impegnato_anno2:=classifBilRec.impegnato_anno2;
      impegnato_anno_succ=classifBilRec.impegnato_anno_succ;

	return next;
    bil_anno='';
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
    prev_comp_anno1=0;
    prev_comp_anno2=0;
    prev_comp_anno_succ=0;
    impegnato_anno1=0;
    impegnato_anno2=0;
    impegnato_anno_succ=0;
    prev_fpv_anno1=0;
    prev_fpv_anno2=0;
    prev_fpv_anno_succ=0;

end loop;

delete from siac_rep_mis_pro_tit_mac_riga_anni 		where utente=user_table;
delete from siac_rep_cap_up 						where utente=user_table;
delete from siac_rep_cap_up_imp 					where utente=user_table;
delete from siac_rep_cap_up_imp_riga				where utente=user_table;
----delete from siac_rep_mptm_up_cap_importi 			where utente=user_table;
----delete from siac_rep_impegni 						where utente=user_table;
delete from siac_rep_impegni_riga  					where utente=user_table;
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