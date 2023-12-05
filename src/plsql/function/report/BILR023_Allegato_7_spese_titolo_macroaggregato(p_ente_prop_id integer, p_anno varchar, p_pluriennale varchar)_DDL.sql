/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR023_Allegato_7_spese_titolo_macroaggregato" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_pluriennale varchar = 'S'::character varying
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
  macroag_id numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  spesa_ricorrente_anno numeric,
  spesa_ricorrente_anno1 numeric,
  spesa_ricorrente_anno2 numeric
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
missione_tipo_code varchar;
missione_tipo_desc varchar;
missione_code varchar;
missione_desc varchar;
programma_tipo_code varchar;
programma_tipo_desc varchar;
programma_code varchar;
programma_desc varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
importo integer :=0;
user_table	varchar;
cap_std	varchar;
cap_fpv	varchar;
cap_fsc	varchar;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
elemTipoCode:='CAP-UP'; -- tipo capitolo previsione
elemTipoCode_UG:='CAP_UG';	--- Capitolo gestione


anno_bil_impegni:= ((p_anno::INTEGER)-1)::VARCHAR;

cap_std:='STD';
cap_fpv:='FPV';
cap_fsc:='FSC';


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
stanziamento_prev_anno=0;


select fnc_siac_random_user()
into	user_table;

/*
insert into siac_rep_tit_mac_riga
select v.*,user_table from
(SELECT titusc_tipo.classif_tipo_desc AS titusc_tipo_desc,
    titusc.classif_id AS titusc_id, titusc.classif_code AS titusc_code,
    titusc.classif_desc AS titusc_desc,
    macroaggr_tipo.classif_tipo_desc AS macroag_tipo_desc,
    macroaggr.classif_id AS macroag_id, macroaggr.classif_code AS macroag_code,
    macroaggr.classif_desc AS macroag_desc, macroaggr.ente_proprietario_id
FROM siac_t_class_fam_tree titusc_tree, siac_d_class_fam titusc_fam,
    siac_r_class_fam_tree titusc_r_cft, siac_t_class titusc,
    siac_d_class_tipo titusc_tipo, siac_d_class_tipo macroaggr_tipo,
    siac_t_class macroaggr
WHERE titusc_fam.classif_fam_desc::text = 'Spesa - TitoliMacroaggregati'::text
    AND titusc_tree.classif_fam_id = titusc_fam.classif_fam_id 
    AND titusc_r_cft.classif_fam_tree_id = titusc_tree.classif_fam_tree_id 
    AND titusc.classif_id = titusc_r_cft.classif_id_padre 
    AND titusc_tipo.classif_tipo_code::text = 'TITOLO_SPESA'::text 
    AND titusc.classif_tipo_id = titusc_tipo.classif_tipo_id 
    AND macroaggr_tipo.classif_tipo_code::text = 'MACROAGGREGATO'::text 
    AND macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 
    AND titusc_r_cft.classif_id = macroaggr.classif_id 
    AND titusc.ente_proprietario_id = macroaggr.ente_proprietario_id 
    AND to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
		between macroaggr.validita_inizio and
		COALESCE(macroaggr.validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
    AND to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
		between titusc.validita_inizio and
		COALESCE(titusc.validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
    AND to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
		between titusc_r_cft.validita_inizio and
		COALESCE(titusc_r_cft.validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
ORDER BY titusc.classif_code, macroaggr.classif_code) v
--------siac_v_bko_titolo_macroaggregato v 
where v.ente_proprietario_id=p_ente_prop_id 
order by titusc_code,macroag_code;
*/


/* 29/09/2016: la query per caricare i dati di struttura è stata sostituita
	da quella più completa che estrae anche i dati di missione e programma
    per poter escludere i titoli/missione che non sono corretti.

*/
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
insert into siac_rep_tit_mac_riga
select distinct  titusc.titusc_tipo_desc,
titusc.titusc_id,
titusc.titusc_code,
titusc.titusc_desc,
macroag.macroag_tipo_desc,
macroag.macroag_id,
macroag.macroag_code,
macroag.macroag_desc,
missione.ente_proprietario_id
,user_table
from missione , programma,titusc, macroag
    /* 29/09/2016: start filtro per mis-prog-macro*/
  , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 29/09/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;


insert into siac_rep_cap_up
select 	0,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
       user_table utente
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_class r_capitolo_macroaggr, 
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where 
    macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
    anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    capitolo.elem_id=r_capitolo_macroaggr.elem_id						and
     capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
    -- 05/08/2016: aggiunto FPVC
    cat_del_capitolo.elem_cat_code	in (cap_std, cap_fpv, cap_fsc,'FPVC')					and
	------cat_del_capitolo.elem_cat_code	=	'STD'								and	
    bilancio.data_cancellazione 				is null						and
	anno_eserc.data_cancellazione 				is null						and
    macroaggr_tipo.data_cancellazione 			is null						and
    macroaggr.data_cancellazione 				is null						and
	capitolo.data_cancellazione 				is null						and
	tipo_elemento.data_cancellazione 			is null						and
    r_capitolo_macroaggr.data_cancellazione 	is null						and 
	stato_capitolo.data_cancellazione 			is null						and 
    r_capitolo_stato.data_cancellazione 		is null						and
	cat_del_capitolo.data_cancellazione 		is null						and
    r_cat_capitolo.data_cancellazione 			is null;					-----	and    
    
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
             siac_t_bil 					bilancio,
	 		siac_t_periodo 					anno_eserc, 
			siac_d_bil_elem_stato 			stato_capitolo, 
            siac_r_bil_elem_stato 			r_capitolo_stato,
			siac_d_bil_elem_categoria 		cat_del_capitolo, 
            siac_r_bil_elem_categoria 		r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
    	and	anno_eserc.anno						=p_anno 												
    	and	bilancio.periodo_id					=anno_eserc.periodo_id 								
        and	capitolo.bil_id						=bilancio.bil_id 			 
        and	capitolo.elem_id					=capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		=elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)       
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		-- 05/08/2016: aggiunto FPVC
        and cat_del_capitolo.elem_cat_code	in (cap_std, cap_fpv, cap_fsc,'FPVC')
		----------and	cat_del_capitolo.elem_cat_code		=	'STD'
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
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   	capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;

insert into siac_rep_cap_up_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	tb2.importo 	as		stanziamento_prev_anno1,
    	tb3.importo		as		stanziamento_prev_anno2,
   	 	0,
    	0,
    	0,
          0,0,0,0,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_up_imp tb1, siac_rep_cap_up_imp tb2, siac_rep_cap_up_imp tb3
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp
                    and tb1.utente 	= 	tb2.utente	
        			and	tb2.utente	=	tb3.utente
        			and	tb3.utente	=	user_table;
        
--------------  NON RICORRENTI    ----------------------------------------------


insert into siac_rep_up_imp_ricorrenti
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
            siac_d_bil_elem_stato			stato_capitolo, 
            siac_r_bil_elem_stato 			r_capitolo_stato,
			siac_d_bil_elem_categoria 		cat_del_capitolo, 
            siac_r_bil_elem_categoria 		r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
    	/*and	capitolo_importi.ente_proprietario_id =capitolo_imp_tipo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id =capitolo_imp_periodo.ente_proprietario_id
        and capitolo_importi.ente_proprietario_id=capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id=tipo_elemento.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id=bilancio.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id=anno_eserc.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id=stato_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id=r_capitolo_stato.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id=cat_del_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id=r_cat_capitolo.ente_proprietario_id*/
        and	anno_eserc.anno						=p_anno 												
    	and	bilancio.periodo_id					=anno_eserc.periodo_id 								
        and	capitolo.bil_id						=bilancio.bil_id 			 
        and	capitolo.elem_id					=capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		=elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id					=r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		='VA'
		and	capitolo.elem_id					=r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		in (cap_std, cap_fpv, cap_fsc,'FPVC')
        and capitolo_imp_tipo.elem_det_tipo_code	= TipoImpComp
        and capitolo_importi.elem_id    not in
        (select r_class.elem_id   
        from  	siac_r_bil_elem_class	r_class,
				siac_t_class 			b,
        		siac_d_class_tipo 		c
		where 	b.classif_id 		= 	r_class.classif_id
		and 	b.classif_tipo_id 	= 	c.classif_tipo_id
		and 	c.classif_tipo_code  = 'RICORRENTE_SPESA'
        and		b.classif_desc	=	'Ricorrente'
        and	r_class.data_cancellazione				is null
        and	b.data_cancellazione					is null
        and c.data_cancellazione					is null)
        /*
        and capitolo_importi.elem_id   in
        	(select attributo_capitolo.elem_id 
        	from 	siac_r_bil_elem_attr attributo_capitolo, 
             		siac_t_attr elenco_attributi
        	where 
        		elenco_attributi.attr_code ='FlagSpeseRicorrenti' 					and
      			elenco_attributi.attr_id = attributo_capitolo.attr_id)      */    
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
        /*and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
    	and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
    	and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())*/
    group by  capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by  capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_up_imp_ricorrenti_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		spesa_ricorrente_anno,
    	tb2.importo 	as		spesa_ricorrente_anno1,
    	tb3.importo		as		spesa_ricorrente_anno2,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_up_imp_ricorrenti tb1, siac_rep_up_imp_ricorrenti tb2, siac_rep_up_imp_ricorrenti tb3
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb1.elem_id	=	tb3.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp
                    and tb1.utente 	= 	tb2.utente	
        			and	tb2.utente	=	tb3.utente
        			and	tb3.utente	=	user_table;
 

--------------------------------------------------------------------------------

for classifBilRec in
select 	v1.titusc_tipo_desc				titusc_tipo_desc,
		v1.titusc_code					titusc_code,
		v1.titusc_desc					titusc_desc,
		v1.macroag_tipo_desc			macroag_tipo_desc,
		v1.macroag_code					macroag_code,
		v1.macroag_desc					macroag_desc,
    	tb.bil_anno   					BIL_ANNO,
        COALESCE(sum(tb1.stanziamento_prev_anno),0)		stanziamento_prev_anno,
        COALESCE(sum(tb1.stanziamento_prev_anno1),0)	stanziamento_prev_anno1,
        COALESCE(sum(tb1.stanziamento_prev_anno2),0)	stanziamento_prev_anno2,
        COALESCE (sum(tb2.spesa_ricorrente_anno),0)		spesa_ricorrente_anno,
		COALESCE (sum(tb2.spesa_ricorrente_anno1),0)	spesa_ricorrente_anno1,
		COALESCE (sum(tb2.spesa_ricorrente_anno2),0)	spesa_ricorrente_anno2  
from   
	siac_rep_tit_mac_riga v1
			FULL  join siac_rep_cap_up tb
         	-----LEFT  join siac_rep_cap_up tb
           on    	(v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					------and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)     
            LEFT	join    siac_rep_cap_up_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id
            	AND tb1.utente=tb.utente
                and tb.utente=user_table)   
            left 	join	siac_rep_up_imp_ricorrenti_riga	tb2	
            on	(tb2.elem_id	=	tb.elem_id
            AND tb2.utente=tb.utente
                and tb.utente=user_table)   
    where v1.utente = user_table 	 	
    group by 
    		v1.titusc_tipo_desc,				
			v1.titusc_code,				
        	v1.titusc_desc,					
            v1.macroag_tipo_desc,			
			v1.macroag_code,				
			v1.macroag_desc,		
    		tb.bil_anno   				
    order by titusc_code,macroag_code
loop
  titusc_tipo_desc:= classifBilRec.titusc_tipo_desc;
  titusc_code:= classifBilRec.titusc_code;
  titusc_desc:= classifBilRec.titusc_desc;
  macroag_tipo_desc:= classifBilRec.macroag_tipo_desc;
  macroag_code:= classifBilRec.macroag_code;
  macroag_desc:= classifBilRec.macroag_desc;
  bil_anno:=classifBilRec.bil_anno;
  stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
  spesa_ricorrente_anno:=classifBilRec.spesa_ricorrente_anno;
  IF p_pluriennale = 'N' THEN  
    stanziamento_prev_anno1:=0;
    stanziamento_prev_anno2:=0;  
    spesa_ricorrente_anno1:=0;
    spesa_ricorrente_anno2:=0;    
  ELSE
    stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
    stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;  
    spesa_ricorrente_anno1:=classifBilRec.spesa_ricorrente_anno1;
    spesa_ricorrente_anno2:=classifBilRec.spesa_ricorrente_anno2;  
  END IF;

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
  stanziamento_prev_anno=0;
  stanziamento_prev_anno1=0;
  stanziamento_prev_anno2=0;
  spesa_ricorrente_anno=0;
  spesa_ricorrente_anno1=0;
  spesa_ricorrente_anno2=0;


end loop;

raise notice 'fine OK';
delete from siac_rep_tit_mac_riga				where utente=user_table;
delete from siac_rep_cap_up 					where utente=user_table;
delete from siac_rep_cap_up_imp 				where utente=user_table;
delete from siac_rep_cap_up_imp_riga 			where utente=user_table;
delete from siac_rep_up_imp_ricorrenti 			where utente=user_table;
delete from siac_rep_up_imp_ricorrenti_riga 	where utente=user_table; 

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