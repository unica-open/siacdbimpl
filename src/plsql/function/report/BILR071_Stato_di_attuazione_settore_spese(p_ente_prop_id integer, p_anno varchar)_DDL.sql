/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR071_Stato_di_attuazione_settore_spese" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titusc_tipo_code varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_code3 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  sett_code varchar,
  sett_desc varchar,
  stanz_attuale numeric,
  variazioni_provv numeric,
  impegnato numeric,
  mandati_emessi numeric,
  esiste_vincolo varchar,
  macroagg_code varchar,
  macroagg_desc varchar,
  tipo_finanziamento varchar
) AS
$body$
DECLARE

classifBilRec record;


annoCapImp 			varchar;
annoCapImp_int integer;
tipoImpCassa 		varchar;
TipoImpstanz		varchar;
elemTipoCode 		varchar;
TipoImpstanzresidui varchar;
tipo_capitolo		varchar;
importo 			integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO 		varchar(1000):=DEF_NULL;
user_table			varchar;
numCapitoli	integer;
num_vincoli integer;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';

BEGIN

annoCapImp:= p_anno; 
annoCapImp_int:= p_anno::integer;  



TipoImpstanzresidui='SRI'; 	-- stanziamento residuo iniziale (RS)
TipoImpstanz='STA'; 		-- stanziamento  (CP)
TipoImpCassa ='SCA'; 		----- cassa	(CS)
elemTipoCode:='CAP-UG'; 	-- tipo capitolo gestione

RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into	user_table;

bil_anno='';
titusc_tipo_code='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';

bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_code3='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanz_attuale=0;
variazioni_provv=0;
impegnato=0;
mandati_emessi=0;

sett_code='';
sett_desc='';
macroagg_code='';
macroagg_desc='';

raise notice 'ora: % ',clock_timestamp()::varchar;



RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';
raise notice 'inserimento tabella di comodo STRUTTURA DEL BILANCIO ''. ';

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


-- 05/09/2016: sostituita la query di caricamento struttura del bilancio
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
    /* 05/09/2016: start filtro per mis-prog-macro*/
	/* 27/09/2016: nei report di utilità non deve essere inserito 
    	questo filtro */        
  -- , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 05/09/2016: start filtro per mis-prog-macro*/
-- AND programma.programma_id = progmacro.classif_a_id
 --AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;
 
 
raise notice 'ora: % ',clock_timestamp()::varchar;


RTN_MESSAGGIO:='inserimento tabella di comodo dei capitoli ''.';
raise notice 'inserimento tabella di comodo dei capitoli ''.';


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

raise notice 'ora: % ',clock_timestamp()::varchar;


RTN_MESSAGGIO:='inserimento tabella di comodo degli importi per capitolo ''.';
raise notice 'inserimento tabella di comodo degli importi per capitolo ''.';


insert into siac_rep_cap_ug_imp 
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
        and	tipo_elemento.elem_tipo_code 			= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id		=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		
		and	cat_del_capitolo.elem_cat_code	=	'STD'	
        	/* estraggo solo gli stanziamenti */
        --and capitolo_imp_tipo.elem_det_tipo_code = TipoImpstanz 							
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


RTN_MESSAGGIO:='inserimento tabella di comodo importi capitoli per riga ''.';
raise notice 'inserimento tabella di comodo importi capitoli per riga ''.';


insert into siac_rep_cap_ug_imp_riga
select  tb1.elem_id,      
    	coalesce (tb1.importo,0)   as 		residui_passivi,
        coalesce (tb2.importo,0)   as 		previsioni_definitive_comp ,
        coalesce (tb3.importo,0)   as 		previsioni_definitive_cassa,
        tb1.ente_proprietario,
        user_table utente 
from 	siac_rep_cap_ug_imp tb1, siac_rep_cap_ug_imp tb2, siac_rep_cap_ug_imp tb3
         where		tb1.elem_id	=	tb2.elem_id													and			
        			tb2.elem_id	=	tb3.elem_id													and
        			tb1.periodo_anno = annoCapImp		AND	tb1.tipo_imp =	TipoImpstanzresidui	AND
        			tb2.periodo_anno = tb1.periodo_anno	AND	tb2.tipo_imp = 	TipoImpstanz		AND
        			tb3.periodo_anno = tb1.periodo_anno	AND	tb3.tipo_imp = 	TipoImpCassa;	
                    




raise notice 'ora: % ',clock_timestamp()::varchar;


RTN_MESSAGGIO:='inserimento tabella di comodo impegnato ''.';
raise notice 'inserimento tabella di comodo impegnato ''.';


insert into siac_rep_impegni
select 	tb2.elem_id,
		p_anno,
		p_ente_prop_id,
		user_table utente,
        tb.importo
from (
select    
capitolo.elem_id,
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
      where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
      and bilancio.bil_id      				=	capitolo.bil_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and movimento.bil_id					=	bilancio.bil_id
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id    
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id              
      and anno_eserc.anno       			=   p_anno 
      and tipo_mov.movgest_tipo_code    	= 'I' /* IMPEGNI */
      and t_capitolo.elem_tipo_code    		= 	elemTipoCode
      and movimento.movgest_anno		 	= 	annoCapImp_int
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id      
      and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
      and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
      and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
      and	now() between t_capitolo.validita_inizio and coalesce (t_capitolo.validita_fine, now())
      and	now() between movimento.validita_inizio and coalesce (movimento.validita_fine, now())
      and	now() between ts_movimento.validita_inizio and coalesce (ts_movimento.validita_fine, now())
      and anno_eserc.data_cancellazione    	is null 
      and bilancio.data_cancellazione     	is null 
      and capitolo.data_cancellazione     	is null 
      and r_mov_capitolo.data_cancellazione is null 
      and t_capitolo.data_cancellazione    	is null 
      and movimento.data_cancellazione     	is null 
      and tipo_mov.data_cancellazione     	is null 
      and r_movimento_stato.data_cancellazione   is null 
      and ts_movimento.data_cancellazione   is null 
      and tipo_stato.data_cancellazione    	is null 
      and dt_movimento.data_cancellazione   is null 
      and ts_mov_tipo.data_cancellazione    is null 
      and dt_mov_tipo.data_cancellazione    is null
group by capitolo.elem_id)
tb 
,
(select * from  siac_t_bil_elem    			capitolo_ug,
      			siac_d_bil_elem_tipo    	t_capitolo_ug
      where capitolo_ug.elem_tipo_id		=	t_capitolo_ug.elem_tipo_id 
      and 	t_capitolo_ug.elem_tipo_code 	= 	elemTipoCode) tb2
where
 tb2.elem_id	=	tb.elem_id;

raise notice 'ora: % ',clock_timestamp()::varchar;


RTN_MESSAGGIO:='inserimento tabella di comodo delle variazioni ''.';
raise notice 'inserimento tabella di comodo delle variazioni ''.';

insert into siac_rep_var_spese
select bil_elem_det_var.elem_id, sum(bil_elem_det_var.elem_det_importo) IMPORTO,
      bil_elem_det_tipo.elem_det_tipo_code, user_table utente, bil_elem_det_var.ente_proprietario_id
from siac_t_bil_elem_det_var bil_elem_det_var,
	 siac_r_variazione_stato r_variazione_stato,
     siac_d_variazione_stato variazione_stato ,
     siac_d_bil_elem_det_tipo bil_elem_det_tipo,
     siac_t_bil_elem		capitolo,
     siac_d_bil_elem_tipo    t_capitolo
where bil_elem_det_var.variazione_stato_id=r_variazione_stato.variazione_stato_id
	AND r_variazione_stato.variazione_stato_tipo_id=variazione_stato.variazione_stato_tipo_id   
    and bil_elem_det_var.elem_det_tipo_id= bil_elem_det_tipo.elem_det_tipo_id
    and capitolo.elem_id=bil_elem_det_var.elem_id
    AND  capitolo.elem_tipo_id     = 	t_capitolo.elem_tipo_id
    AND bil_elem_det_var.data_cancellazione IS NULL
    AND r_variazione_stato.data_cancellazione IS NULL
    AND variazione_stato.data_cancellazione IS NULL
    AND bil_elem_det_tipo.data_cancellazione IS NULL
    AND capitolo.data_cancellazione IS NULL
    	/* devo prendere le variazioni PROVVISORIE.
        	Quindi oltre a quelle ANNULLATE, escludo le DEFINITIVE */
    AND variazione_stato.variazione_stato_tipo_code NOT IN ('A', 'D')
    and bil_elem_det_tipo.elem_det_tipo_code='STA'
    and t_capitolo.elem_tipo_code    		= 	elemTipoCode
    AND bil_elem_det_var.ente_proprietario_id =p_ente_prop_id
       group by bil_elem_det_var.elem_id,  bil_elem_det_tipo.elem_det_tipo_code,
       UTENTE, bil_elem_det_var.ente_proprietario_id  ;
        
raise notice 'ora: % ',clock_timestamp()::varchar;


-----------------------------------------------------------------------------------------------------------------------------------
-------		ACQUISIZIONE dei MANDATI
-----------------------------------------------------------------------------------------------------------------------------------

RTN_MESSAGGIO:='inserimento tabella di comodo dei mandati  ''.';
raise notice 'inserimento tabella di comodo mandati  ';
raise notice 'ora: % ',clock_timestamp()::varchar;


insert into siac_rep_pagam_ug
select 		r_capitolo_ordinativo.elem_id,
            sum(ordinativo_imp.ord_ts_det_importo),
            p_ente_prop_id,
            user_table utente
from 		siac_t_bil 						bilancio,
	 		siac_t_periodo 					anno_eserc, 
            siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
            siac_t_ordinativo				ordinativo,
            siac_d_ordinativo_tipo			tipo_ordinativo,
            siac_r_ordinativo_stato			r_stato_ordinativo,
            siac_d_ordinativo_stato			stato_ordinativo,
            siac_t_ordinativo_ts 			ordinativo_det,
			siac_t_ordinativo_ts_det 		ordinativo_imp,
        	siac_d_ordinativo_ts_det_tipo 	ordinativo_imp_tipo,
            siac_t_movgest     				movimento,
            siac_t_movgest_ts    			ts_movimento, 
            siac_r_ordinativo_ts_movgest_ts	r_ordinativo_movgest
    where 	anno_eserc.anno						= 	p_anno											
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id
        and	bilancio.ente_proprietario_id	=	p_ente_prop_id
        and	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
        and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
		and	tipo_ordinativo.ord_tipo_code		= 	'P'		------ Pagamento
        and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
        and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
        ------------------------------------------------------------------------------------------		
        ----------------------    PRENDO GLI STATI "INSERITO" E "TRASMESSO"
		------------------------------------------------------------------------------------------		
        and	stato_ordinativo.ord_stato_code		IN	('I','T') --- 
        -----------------------------------------------------------------------------------------------
        and	ordinativo.bil_id					=	bilancio.bil_id
        and	ordinativo.ord_id					=	ordinativo_det.ord_id
        and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
        and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
        and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' 	---- importo attuale
        ---------------------------------------------------------------------------------------------------------------------
        and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
        and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
        and	ts_movimento.movgest_id				=	movimento.movgest_id
        and	movimento.movgest_anno				=	annoCapImp_int	
        and movimento.bil_id					=	bilancio.bil_id	
        --------------------------------------------------------------------------------------------------------------------		
        and	bilancio.data_cancellazione 				is null
        and	anno_eserc.data_cancellazione 				is null
        and	r_capitolo_ordinativo.data_cancellazione	is null
        and	ordinativo.data_cancellazione				is null
        AND	tipo_ordinativo.data_cancellazione			is null
        and	r_stato_ordinativo.data_cancellazione		is null
        AND	stato_ordinativo.data_cancellazione			is null
        AND ordinativo_det.data_cancellazione			is null
 	  	aND ordinativo_imp.data_cancellazione			is null
        and ordinativo_imp_tipo.data_cancellazione		is null
        and	movimento.data_cancellazione				is null
        and	ts_movimento.data_cancellazione				is null
        and	r_ordinativo_movgest.data_cancellazione		is null
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        ---and	now() between	r_capitolo_ordinativo.validita_inizio and coalesce (r_capitolo_ordinativo.validita_fine, now())
        ---and	now() between	r_stato_ordinativo.validita_inizio and coalesce (r_stato_ordinativo.validita_fine, now())
        ---and	now() between	r_ordinativo_movgest.validita_inizio and coalesce (r_ordinativo_movgest.validita_fine, now())
        group by r_capitolo_ordinativo.elem_id,r_capitolo_ordinativo.ente_proprietario_id;

raise notice 'ora: % ',clock_timestamp()::varchar;


RTN_MESSAGGIO:='estrazione dei dati dalle tabelle di comodo e preparazione dati in output ''.';
raise notice 'estrazione dei dati dalle tabelle di comodo e preparazione dati in output ''.';

                
for classifBilRec in
select 	v1.missione_tipo_desc			missione_tipo_desc,
		v1.missione_code				missione_code,
		v1.missione_desc				missione_desc,
		v1.programma_tipo_desc			programma_tipo_desc,
		v1.programma_code				programma_code,
		v1.programma_desc				programma_desc,
		v1.titusc_tipo_desc				titusc_tipo_code,
        v1.titusc_tipo_desc				titusc_tipo_desc,
		v1.titusc_code					titusc_code,
		v1.titusc_desc					titusc_desc,
		v1.macroag_tipo_desc			macroag_tipo_desc,
		v1.macroag_code					macroag_code,
		v1.macroag_desc					macroag_desc,
        tb.elem_id						ELEM_ID,
    	tb.bil_anno   					BIL_ANNO,
        tb.elem_code     				BIL_ELE_CODE,
        tb.elem_code2     				BIL_ELE_CODE2,
        tb.elem_code3					BIL_ELE_CODE3,
		tb.elem_desc     				BIL_ELE_DESC,
        tb.elem_desc2     				BIL_ELE_DESC2,
        tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
        tb3.periodo_anno				ANNO_IMPEGNO,
        --tb2.stato						STATO_AVANZAM_PAG,
    	COALESCE(tb1.residui_passivi,0)				residui_passivi,
    	COALESCE(tb1.previsioni_definitive_comp,0)	stanziamento_attuale,
    	COALESCE(tb1.previsioni_definitive_cassa,0)	previsioni_definitive_cassa,
    	COALESCE(tb2.importo,0)						variazioni_provv,
        COALESCE(tb3.importo,0)						impegni,
        COALESCE(tb4.pagamenti_competenza,0)		mandati
from   
	siac_rep_mis_pro_tit_mac_riga_anni v1
			left  join siac_rep_cap_ug tb
           on    	(v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)     
            left	join    siac_rep_cap_ug_imp_riga 	tb1  	on tb1.elem_id	=	tb.elem_id 				
            left 	join	siac_rep_var_spese			tb2		on tb2.elem_id	=	tb.elem_id
            left    join 	siac_rep_impegni			tb3		on tb3.elem_id	=	tb.elem_id
            left    join 	siac_rep_pagam_ug			tb4		on tb4.elem_id	=	tb.elem_id			            
           WHERE tb.elem_id IS NOT NULL
           order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID


loop

titusc_tipo_code=classifBilRec.titusc_tipo_code;
titusc_tipo_desc=classifBilRec.titusc_tipo_desc;
titusc_code=classifBilRec.titusc_code;
titusc_desc=classifBilRec.titusc_desc;
macroagg_code=classifBilRec.macroag_code;
macroagg_desc=classifBilRec.macroag_desc;

bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_code3=classifBilRec.BIL_ELE_CODE3;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
bil_anno:=p_anno;

stanz_attuale=classifBilRec.stanziamento_attuale;
variazioni_provv=classifBilRec.variazioni_provv;
impegnato=classifBilRec.impegni;
mandati_emessi=classifBilRec.mandati;


num_vincoli=0;

BEGIN
	SELECT  count(r_vinc_bil_elem.vincolo_elem_id)
        INTO num_vincoli
        from siac_r_vincolo_bil_elem  r_vinc_bil_elem          
    where 
        r_vinc_bil_elem.elem_id 			= 	classifBilRec.ELEM_ID
        AND r_vinc_bil_elem.data_cancellazione IS NULL;
   IF NOT FOUND THEN
      RAISE EXCEPTION 'Errore nella ricerca dei vincoli per %', classifBilRec.ELEM_ID;
      return;   
    END IF;
END;

IF num_vincoli>0 THEN
	esiste_vincolo='S';
ELSE
	esiste_vincolo='N';
END IF;



IF classifBilRec.ELEM_ID IS NOT NULL THEN
  BEGIN
        select c.classif_code
        into tipo_finanziamento
        from siac_t_class c, siac_d_class_tipo t, siac_r_bil_elem_class 	r
        where c.classif_tipo_id=t.classif_tipo_id
        and r.classif_id=c.classif_id
        and t.classif_tipo_code in('TIPO_FINANZIAMENTO')
        and c.ente_proprietario_id=p_ente_prop_id
        AND c.data_cancellazione IS NULL
        AND t.data_cancellazione IS NULL
        AND r.data_cancellazione IS NULL
        and r.elem_id=classifBilRec.ELEM_ID;
     IF NOT FOUND THEN
       -- RAISE EXCEPTION 'Errore nella ricerca del tipo finanziamento %', classifBilRec.ELEM_ID;
        --return;  
        tipo_finanziamento='';
      END IF;
  END;

	BEGIN
        SELECT  t_class.classif_code, t_class.classif_desc
            INTO sett_code, sett_desc
            from siac_r_bil_elem_class r_bil_elem_class,
                siac_t_class			t_class,
                siac_d_class_tipo		d_class_tipo ,
                siac_t_bil_elem    		capitolo               
        where 
            r_bil_elem_class.elem_id 			= 	capitolo.elem_id
            and t_class.classif_id 					= 	r_bil_elem_class.classif_id
            and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
            AND d_class_tipo.classif_tipo_desc='Cdc(Settore)'
            and capitolo.ente_proprietario_id=p_ente_prop_id
            and capitolo.elem_id=classifBilRec.ELEM_ID
             AND r_bil_elem_class.data_cancellazione is NULL
             AND t_class.data_cancellazione is NULL
             AND d_class_tipo.data_cancellazione is NULL
             AND capitolo.data_cancellazione is NULL;	
       IF NOT FOUND THEN
         -- RAISE EXCEPTION 'Non esiste il Settore per  %', classifBilRec.ELEM_ID;
         -- return;   
         sett_code=''; 
         sett_desc='';
        END IF;
    END;    
ELSE
  sett_code='';
  sett_desc='';
END IF;



return next;
bil_anno='';
titusc_tipo_code='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';

bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_code3='';
bil_ele_id=0;
bil_ele_id_padre=0;

stanz_attuale=0;
variazioni_provv=0;
impegnato=0;
mandati_emessi=0;

sett_code='';
sett_desc='';
macroagg_code='';
macroagg_desc='';
tipo_finanziamento='';

end loop;
raise notice 'ora: % ',clock_timestamp()::varchar;




delete from siac_rep_mis_pro_tit_mac_riga_anni 		where utente=user_table;
delete from siac_rep_cap_ug					 		where utente=user_table;
delete from siac_rep_cap_ug_imp 					where utente=user_table;
delete from siac_rep_cap_ug_imp_riga				where utente=user_table;
delete from	siac_rep_pagam_ug						where utente=user_table;
delete from	siac_rep_impegni						where utente=user_table;
delete from	siac_rep_var_spese						where utente=user_table;


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