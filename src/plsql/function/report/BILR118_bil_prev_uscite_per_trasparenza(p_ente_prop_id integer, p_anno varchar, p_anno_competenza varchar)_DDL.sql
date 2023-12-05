/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR118_bil_prev_uscite_per_trasparenza" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_competenza varchar
)
RETURNS TABLE (
  missione_code_01 varchar,
  missione_desc_01 varchar,
  imp_competenza_01 numeric,
  imp_fpv_01 numeric,
  imp_cassa_01 numeric,
  missione_code_02 varchar,
  missione_desc_02 varchar,
  imp_competenza_02 numeric,
  imp_fpv_02 numeric,
  imp_cassa_02 numeric,
  missione_code_03 varchar,
  missione_desc_03 varchar,
  imp_competenza_03 numeric,
  imp_fpv_03 numeric,
  imp_cassa_03 numeric,
  missione_code_04 varchar,
  missione_desc_04 varchar,
  imp_competenza_04 numeric,
  imp_fpv_04 numeric,
  imp_cassa_04 numeric,
  missione_code_05 varchar,
  missione_desc_05 varchar,
  imp_competenza_05 numeric,
  imp_fpv_05 numeric,
  imp_cassa_05 numeric,
  missione_code_06 varchar,
  missione_desc_06 varchar,
  imp_competenza_06 numeric,
  imp_fpv_06 numeric,
  imp_cassa_06 numeric,
  missione_code_07 varchar,
  missione_desc_07 varchar,
  imp_competenza_07 numeric,
  imp_fpv_07 numeric,
  imp_cassa_07 numeric,
  missione_code_08 varchar,
  missione_desc_08 varchar,
  imp_competenza_08 numeric,
  imp_fpv_08 numeric,
  imp_cassa_08 numeric,
  missione_code_09 varchar,
  missione_desc_09 varchar,
  imp_competenza_09 numeric,
  imp_fpv_09 numeric,
  imp_cassa_09 numeric,
  missione_code_10 varchar,
  missione_desc_10 varchar,
  imp_competenza_10 numeric,
  imp_fpv_10 numeric,
  imp_cassa_10 numeric,
  missione_code_11 varchar,
  missione_desc_11 varchar,
  imp_competenza_11 numeric,
  imp_fpv_11 numeric,
  imp_cassa_11 numeric,
  missione_code_12 varchar,
  missione_desc_12 varchar,
  imp_competenza_12 numeric,
  imp_fpv_12 numeric,
  imp_cassa_12 numeric,
  missione_code_13 varchar,
  missione_desc_13 varchar,
  imp_competenza_13 numeric,
  imp_fpv_13 numeric,
  imp_cassa_13 numeric,
  missione_code_14 varchar,
  missione_desc_14 varchar,
  imp_competenza_14 numeric,
  imp_fpv_14 numeric,
  imp_cassa_14 numeric,
  missione_code_15 varchar,
  missione_desc_15 varchar,
  imp_competenza_15 numeric,
  imp_fpv_15 numeric,
  imp_cassa_15 numeric,
  missione_code_16 varchar,
  missione_desc_16 varchar,
  imp_competenza_16 numeric,
  imp_fpv_16 numeric,
  imp_cassa_16 numeric,
  missione_code_17 varchar,
  missione_desc_17 varchar,
  imp_competenza_17 numeric,
  imp_fpv_17 numeric,
  imp_cassa_17 numeric,
  missione_code_18 varchar,
  missione_desc_18 varchar,
  imp_competenza_18 numeric,
  imp_fpv_18 numeric,
  imp_cassa_18 numeric,
  missione_code_19 varchar,
  missione_desc_19 varchar,
  imp_competenza_19 numeric,
  imp_fpv_19 numeric,
  imp_cassa_19 numeric,
  missione_code_20 varchar,
  missione_desc_20 varchar,
  imp_competenza_20 numeric,
  imp_fpv_20 numeric,
  imp_cassa_20 numeric,
  missione_code_50 varchar,
  missione_desc_50 varchar,
  imp_competenza_50 numeric,
  imp_fpv_50 numeric,
  imp_cassa_50 numeric,
  missione_code_60 varchar,
  missione_desc_60 varchar,
  imp_competenza_60 numeric,
  imp_fpv_60 numeric,
  imp_cassa_60 numeric,
  missione_code_99 varchar,
  missione_desc_99 varchar,
  imp_competenza_99 numeric,
  imp_fpv_99 numeric,
  imp_cassa_99 numeric,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  ripiano_disavanzo numeric,
  imp_competenza_tot numeric,
  imp_cassa_tot numeric,
  imp_fpv_tot numeric
) AS
$body$
DECLARE
classifBilRec record;
trasparenza record;


annoCapImp varchar;

tipoImpComp varchar;
tipoImpCassa varchar;

elemTipoCode varchar;

tipo_capitolo	varchar;
h_count integer :=0;
importo integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
tipologia_capitolo	varchar;
esiste_siac_t_dicuiimpegnato_bilprev integer;
annoPrec varchar;
tipo_categ_capitolo varchar;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
 
BEGIN

--raise notice '1: %', clock_timestamp()::varchar;

annoCapImp:= p_anno_competenza; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
elemTipoCode:='CAP-UP'; -- tipo capitolo previsione

annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;
     

--raise notice '2: %', clock_timestamp()::varchar;

  missione_code_01=''; 
  missione_desc_01=''; 
  imp_competenza_01=0;
  imp_fpv_01=0;
  imp_cassa_01=0;
  missione_code_02=''; 
  missione_desc_02='';
  imp_competenza_02=0;
  imp_fpv_02=0;
  imp_cassa_02=0;  
  missione_code_03='';
  missione_desc_03='';
  imp_competenza_03=0;
  imp_fpv_03=0;
  imp_cassa_03=0;
  missione_code_04='';
  missione_desc_04='';
  imp_competenza_04=0;
  imp_fpv_04=0;
  imp_cassa_04=0;
  missione_code_05='';
  missione_desc_05='';
  imp_competenza_05=0;
  imp_fpv_05=0;
  imp_cassa_05=0;
  missione_code_06='';
  missione_desc_06='';
  imp_competenza_06=0;
  imp_fpv_06=0;
  imp_cassa_06=0;
  missione_code_07='';
  missione_desc_07='';
  imp_competenza_07=0;
  imp_fpv_07=0;
  imp_cassa_07=0;
  missione_code_08='';
  missione_desc_08='';
  imp_competenza_08=0;
  imp_fpv_08=0;
  imp_cassa_08=0;
  missione_code_09='';
  missione_desc_09='';
  imp_competenza_09=0;
  imp_fpv_09=0;
  imp_cassa_09=0;
  missione_code_10='';
  missione_desc_10='';
  imp_competenza_10=0;
  imp_fpv_10=0;
  imp_cassa_10=0;
  missione_code_11='';
  missione_desc_11='';
  imp_competenza_11=0;
  imp_fpv_11=0;
  imp_cassa_11=0;
  missione_code_12='';
  missione_desc_12='';
  imp_competenza_12=0;
  imp_fpv_12=0;
  imp_cassa_12=0;
  missione_code_13='';
  missione_desc_13='';
  imp_competenza_13=0;
  imp_fpv_13=0;
  imp_cassa_13=0;
  missione_code_14='';
  missione_desc_14='';
  imp_competenza_14=0;
  imp_fpv_14=0;
  imp_cassa_14=0;
  missione_code_15='';
  missione_desc_15='';
  imp_competenza_15=0;
  imp_fpv_15=0;
  imp_cassa_15=0;
  missione_code_16='';
  missione_desc_16='';
  imp_competenza_16=0;
  imp_fpv_16=0;
  imp_cassa_16=0;
  missione_code_17='';
  missione_desc_17='';
  imp_competenza_17=0;
  imp_fpv_17=0;
  imp_cassa_17=0;
  missione_code_18='';
  missione_desc_18='';
  imp_competenza_18=0;
  imp_fpv_18=0;
  imp_cassa_18=0;
  missione_code_19='';
  missione_desc_19='';
  imp_competenza_19=0;
  imp_fpv_19=0;
  imp_cassa_19=0;
  missione_code_20='';
  missione_desc_20='';
  imp_competenza_20=0;
  imp_fpv_20=0;
  imp_cassa_20=0;
  missione_code_50='';
  missione_desc_50='';
  imp_competenza_50=0;
  imp_fpv_50=0;
  imp_cassa_50=0;
  missione_code_60='';
  missione_desc_60='';
  imp_competenza_60=0;
  imp_fpv_60=0;
  imp_cassa_60=0;
  missione_code_99='';
  missione_desc_99='';
  imp_competenza_99=0;
  imp_fpv_99=0;
  imp_cassa_99=0;
  titusc_code='';
  titusc_desc='';
  macroag_code='';
  macroag_desc='';
  ripiano_disavanzo=0;
  imp_competenza_tot=0;
  imp_cassa_tot=0;
  imp_fpv_tot=0;

select fnc_siac_random_user()
into	user_table;

RTN_MESSAGGIO:='preparazione tabella siac_rep_mis_pro_tit_mac_riga_anni ''.';   

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
    AND missione_fam.classif_fam_id = missione_tree.classif_fam_id AND missione_tree.classif_fam_tree_id = missione_r_cft.classif_fam_tree_id AND missione_r_cft.classif_id_padre = missione.classif_id AND missione.classif_tipo_id = missione_tipo.classif_tipo_id AND missione_tipo.classif_tipo_code::text = 'MISSIONE'::text AND programma_tipo.classif_tipo_code::text = 'PROGRAMMA'::text AND missione_r_cft.classif_id = programma.classif_id AND programma.classif_tipo_id = programma_tipo.classif_tipo_id AND titusc_fam.classif_fam_desc::text = 'Spesa - TitoliMacroaggregati'::text AND titusc_fam.classif_fam_id = titusc_tree.classif_fam_id AND titusc_tree.classif_fam_tree_id = titusc_r_cft.classif_fam_tree_id AND titusc_r_cft.classif_id_padre = titusc.classif_id AND titusc_tipo.classif_tipo_code::text = 'TITOLO_SPESA'::text AND titusc.classif_tipo_id = titusc_tipo.classif_tipo_id AND macroaggr_tipo.classif_tipo_code::text = 'MACROAGGREGATO'::text AND titusc_r_cft.classif_id = macroaggr.classif_id AND macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id AND missione.ente_proprietario_id = programma.ente_proprietario_id AND programma.ente_proprietario_id = titusc.ente_proprietario_id AND titusc.ente_proprietario_id = macroaggr.ente_proprietario_id
ORDER BY missione.classif_code, programma.classif_code, titusc.classif_code,
    macroaggr.classif_code) v 
-------siac_v_mis_pro_tit_macr_anni 
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
  --, siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 06/09/2016: start filtro per mis-prog-macro*/
 --AND programma.programma_id = progmacro.classif_a_id
 --AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;
 
--raise notice '3: %', clock_timestamp()::varchar;
RTN_MESSAGGIO:='preparazione tabella siac_rep_cap_up ''.';   
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
    capitolo.elem_id						=	r_capitolo_stato.elem_id	and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
	--------cat_del_capitolo.elem_cat_code	=	'STD'	
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


--10/05/2016: carico nella tabella di appoggio con i capitoli gli eventuali 
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
      -- 06/09/2016: aggiunto FPVC     
      AND prec.elem_cat_code	in ('STD','FPV','FSC','FPVC')		
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
AND a.elem_cat_code in ('STD','FPV','FSC','FPVC')   
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
                                                                    
--raise notice '4: %', clock_timestamp()::varchar;

RTN_MESSAGGIO:='preparazione tabella siac_rep_cap_up_imp ''.';  

insert into siac_rep_cap_up_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(COALESCE( capitolo_importi.elem_det_importo,0)),
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
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno= p_anno 												
    	and	bilancio.periodo_id=anno_eserc.periodo_id 								
        and	capitolo.bil_id=bilancio.bil_id 			 
        and	capitolo.elem_id	=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code = elemTipoCode
        and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
        -- 06/09/2016: aggiunto FPV (che era in query successiva che 
        -- è stata tolta) e FPVC		
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
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente, cat_del_capitolo.elem_cat_code
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;

-----------------   importo capitoli di tipo fondo pluriennale vincolato ------------------------
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp fpv''.';  
/* insert into siac_rep_cap_up_imp
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
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno= p_anno 												
    	and	bilancio.periodo_id=anno_eserc.periodo_id 								
        and	capitolo.bil_id=bilancio.bil_id 			 
        and	capitolo.elem_id	=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code = elemTipoCode
        and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		
		and	cat_del_capitolo.elem_cat_code	=	'FPV'								       
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
*/

--raise notice '5: %', clock_timestamp()::varchar;
RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp_riga STD''.'; 
     
insert into siac_rep_cap_up_imp_riga
select  tb1.elem_id,      
    	COALESCE( tb1.importo,0) 	as 		stanziamento_prev_anno,
        0,0,0,0,
    	COALESCE( tb6.importo,0)		as		stanziamento_prev_cassa_anno,
        0,0,0,0,
        tb1.ente_proprietario,
        user_table utente 
        from 
        siac_rep_cap_up_imp tb1, siac_rep_cap_up_imp tb6
        where			
    	tb1.elem_id	= tb6.elem_id	        and
    	tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp			and	tb1.tipo_capitolo 		in ('STD','FSC')
        AND 
    	tb6.periodo_anno = tb1.periodo_anno AND	tb6.tipo_imp = 	TipoImpCassa	and	tb6.tipo_capitolo		in ('STD','FSC')
        and tb1.utente 	= 	tb6.utente	
        and	tb6.utente	=	user_table;    
     
RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp_riga FPV''.';  
insert into siac_rep_cap_up_imp_riga
select  tb8.elem_id,      
    	0,
    	0,
    	0,
   	 	0,
    	0,
    	0,
        0,
  		COALESCE( tb8.importo,0)		as		stanziamento_fpv_anno,
        0,
        0,
        tb8.ente_proprietario,
        user_table utente 
from   siac_rep_cap_up_imp tb8
where  tb8.periodo_anno = annoCapImp	
and	tb8.tipo_imp =	TipoImpComp			
-- 06/09/2016: aggiunto FPVC
and	tb8.tipo_capitolo 		IN ('FPV','FPVC')
and tb8.utente = user_table;    

RTN_MESSAGGIO:='insert tabella siac_rep_mptm_up_cap_importi''.';  

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
    	COALESCE( tb1.stanziamento_prev_anno,0)		stanziamento_prev_anno,
    	0,--tb1.stanziamento_prev_anno1		stanziamento_prev_anno1,
    	0,--tb1.stanziamento_prev_anno2		stanziamento_prev_anno2,
   	 	0,--tb1.stanziamento_prev_res_anno	stanziamento_prev_res_anno,
    	0,--tb1.stanziamento_anno_prec		stanziamento_anno_prec,
    	COALESCE( tb1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
        v1.ente_proprietario_id,
        user_table utente,
        tbprec.elem_id_old,
        '',
        0,--tb1.stanziamento_fpv_anno_prec	stanziamento_fpv_anno_prec,
  		COALESCE( tb1.stanziamento_fpv_anno,0)		stanziamento_fpv_anno,
  		0,--tb1.stanziamento_fpv_anno1		stanziamento_fpv_anno1,
  		0--tb1.stanziamento_fpv_anno2		stanziamento_fpv_anno2
from   
	siac_rep_mis_pro_tit_mac_riga_anni v1
			FULL  join siac_rep_cap_up tb
           on    	(v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)     
            left	join    siac_rep_cap_up_imp_riga tb1  
            		on (tb1.elem_id	=	tb.elem_id 
            			and	tb.utente=user_table
                        and tb1.utente	=	tb.utente)	
            left JOIN siac_r_bil_elem_rel_tempo tbprec ON tbprec.elem_id = tb.elem_id AND tbprec.data_cancellazione IS NULL
        where v1.utente = user_table     
           order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID;

-- raise notice '7: %', clock_timestamp()::varchar;
      
raise notice '9: %', clock_timestamp()::varchar;      
	
 RTN_MESSAGGIO:='preparazione file output per fase bilancio previsione ''.'; 

 for classifBilRec in
	select 	t1.titusc_code			titusc_code_r,
            t1.titusc_desc			titusc_desc_r,
            t1.macroag_code			macroag_code_r,
            t1.macroag_desc			macroag_desc_r,
            t1.missione_code		missione_code_r,
            t1.missione_desc		missione_desc_r,
            SUM(COALESCE(t1.stanziamento_prev_anno,0))	stanziamento_prev_anno,
        	SUM(COALESCE(t1.stanziamento_prev_cassa_anno,0))	stanziamento_prev_cassa_anno,
        	SUM(COALESCE(t1.stanziamento_fpv_anno,0))	stanziamento_fpv_anno 
    from siac_rep_mptm_up_cap_importi t1
    where t1.utente	=	user_table
    group by t1.titusc_code, t1.titusc_desc, t1.macroag_code, t1.macroag_desc, t1.missione_code, t1.missione_desc          
    order by t1.titusc_code, t1.macroag_code, t1.missione_code  	
loop

  if classifBilRec.missione_code_r = '01' THEN
     insert into siac_rep_prev_trasparenza_u 
                 (missione_code_01, 
                  missione_desc_01,
                  imp_competenza_01,
                  imp_fpv_01,
                  imp_cassa_01,
                  titusc_code,
                  titusc_desc,
                  macroag_code,
                  macroag_desc,
                  ripiano_disavanzo,
                  utente                  
                  )             
            values (classifBilRec.missione_code_r,
                    classifBilRec.missione_desc_r,
                    classifBilRec.stanziamento_prev_anno,
                    classifBilRec.stanziamento_fpv_anno,
                    classifBilRec.stanziamento_prev_cassa_anno,
                    classifBilRec.titusc_code_r,
                    classifBilRec.titusc_desc_r,
                    classifBilRec.macroag_code_r,
                    classifBilRec.macroag_desc_r,
                    0,
                    user_table
            );
   else
    
  	if classifBilRec.missione_code_r = '02' then 
       update siac_rep_prev_trasparenza_u a
       set  missione_code_02 = classifBilRec.missione_code_r,
            missione_desc_02 = classifBilRec.missione_desc_r,
            imp_competenza_02 = classifBilRec.stanziamento_prev_anno,
            imp_fpv_02 = classifBilRec.stanziamento_fpv_anno,
            imp_cassa_02 = classifBilRec.stanziamento_prev_cassa_anno
       where a.titusc_code = classifBilRec.titusc_code_r
       and   a.titusc_desc = classifBilRec.titusc_desc_r
       and   a.macroag_code = classifBilRec.macroag_code_r
       and   a.macroag_desc = classifBilRec.macroag_desc_r
       and   a.utente = user_table;
    elsif classifBilRec.missione_code_r = '03' then 
       update siac_rep_prev_trasparenza_u a
       set  missione_code_03 = classifBilRec.missione_code_r,
            missione_desc_03 = classifBilRec.missione_desc_r,
            imp_competenza_03 = classifBilRec.stanziamento_prev_anno,
            imp_fpv_03 = classifBilRec.stanziamento_fpv_anno,
            imp_cassa_03 = classifBilRec.stanziamento_prev_cassa_anno
       where a.titusc_code = classifBilRec.titusc_code_r
       and   a.titusc_desc = classifBilRec.titusc_desc_r
       and   a.macroag_code = classifBilRec.macroag_code_r
       and   a.macroag_desc = classifBilRec.macroag_desc_r
       and   a.utente = user_table;  
    elsif classifBilRec.missione_code_r = '04' then 
       update siac_rep_prev_trasparenza_u a
       set  missione_code_04 = classifBilRec.missione_code_r,
            missione_desc_04 = classifBilRec.missione_desc_r,
            imp_competenza_04 = classifBilRec.stanziamento_prev_anno,
            imp_fpv_04 = classifBilRec.stanziamento_fpv_anno,
            imp_cassa_04 = classifBilRec.stanziamento_prev_cassa_anno
       where a.titusc_code = classifBilRec.titusc_code_r
       and   a.titusc_desc = classifBilRec.titusc_desc_r
       and   a.macroag_code = classifBilRec.macroag_code_r
       and   a.macroag_desc = classifBilRec.macroag_desc_r
       and   a.utente = user_table;
    elsif classifBilRec.missione_code_r = '05' then 
       update siac_rep_prev_trasparenza_u a
       set  missione_code_05 = classifBilRec.missione_code_r,
            missione_desc_05 = classifBilRec.missione_desc_r,
            imp_competenza_05 = classifBilRec.stanziamento_prev_anno,
            imp_fpv_05 = classifBilRec.stanziamento_fpv_anno,
            imp_cassa_05 = classifBilRec.stanziamento_prev_cassa_anno
       where a.titusc_code = classifBilRec.titusc_code_r
       and   a.titusc_desc = classifBilRec.titusc_desc_r
       and   a.macroag_code = classifBilRec.macroag_code_r
       and   a.macroag_desc = classifBilRec.macroag_desc_r
       and   a.utente = user_table;
    elsif classifBilRec.missione_code_r = '06' then 
       update siac_rep_prev_trasparenza_u a
       set  missione_code_06 = classifBilRec.missione_code_r,
            missione_desc_06 = classifBilRec.missione_desc_r,
            imp_competenza_06 = classifBilRec.stanziamento_prev_anno,
            imp_fpv_06 = classifBilRec.stanziamento_fpv_anno,
            imp_cassa_06 = classifBilRec.stanziamento_prev_cassa_anno
       where a.titusc_code = classifBilRec.titusc_code_r
       and   a.titusc_desc = classifBilRec.titusc_desc_r
       and   a.macroag_code = classifBilRec.macroag_code_r
       and   a.macroag_desc = classifBilRec.macroag_desc_r
       and   a.utente = user_table;
    elsif classifBilRec.missione_code_r = '07' then 
       update siac_rep_prev_trasparenza_u a
       set  missione_code_07 = classifBilRec.missione_code_r,
            missione_desc_07 = classifBilRec.missione_desc_r,
            imp_competenza_07 = classifBilRec.stanziamento_prev_anno,
            imp_fpv_07 = classifBilRec.stanziamento_fpv_anno,
            imp_cassa_07 = classifBilRec.stanziamento_prev_cassa_anno
       where a.titusc_code = classifBilRec.titusc_code_r
       and   a.titusc_desc = classifBilRec.titusc_desc_r
       and   a.macroag_code = classifBilRec.macroag_code_r
       and   a.macroag_desc = classifBilRec.macroag_desc_r
       and   a.utente = user_table;
    elsif classifBilRec.missione_code_r = '08' then 
       update siac_rep_prev_trasparenza_u a
       set  missione_code_08 = classifBilRec.missione_code_r,
            missione_desc_08 = classifBilRec.missione_desc_r,
            imp_competenza_08 = classifBilRec.stanziamento_prev_anno,
            imp_fpv_08 = classifBilRec.stanziamento_fpv_anno,
            imp_cassa_08 = classifBilRec.stanziamento_prev_cassa_anno
       where a.titusc_code = classifBilRec.titusc_code_r
       and   a.titusc_desc = classifBilRec.titusc_desc_r
       and   a.macroag_code = classifBilRec.macroag_code_r
       and   a.macroag_desc = classifBilRec.macroag_desc_r
       and   a.utente = user_table;
    elsif classifBilRec.missione_code_r = '09' then 
       update siac_rep_prev_trasparenza_u a
       set  missione_code_09 = classifBilRec.missione_code_r,
            missione_desc_09 = classifBilRec.missione_desc_r,
            imp_competenza_09 = classifBilRec.stanziamento_prev_anno,
            imp_fpv_09 = classifBilRec.stanziamento_fpv_anno,
            imp_cassa_09 = classifBilRec.stanziamento_prev_cassa_anno
       where a.titusc_code = classifBilRec.titusc_code_r
       and   a.titusc_desc = classifBilRec.titusc_desc_r
       and   a.macroag_code = classifBilRec.macroag_code_r
       and   a.macroag_desc = classifBilRec.macroag_desc_r
       and   a.utente = user_table;
    elsif classifBilRec.missione_code_r = '10' then 
       update siac_rep_prev_trasparenza_u a
       set  missione_code_10 = classifBilRec.missione_code_r,
            missione_desc_10 = classifBilRec.missione_desc_r,
            imp_competenza_10 = classifBilRec.stanziamento_prev_anno,
            imp_fpv_10 = classifBilRec.stanziamento_fpv_anno,
            imp_cassa_10 = classifBilRec.stanziamento_prev_cassa_anno
       where a.titusc_code = classifBilRec.titusc_code_r
       and   a.titusc_desc = classifBilRec.titusc_desc_r
       and   a.macroag_code = classifBilRec.macroag_code_r
       and   a.macroag_desc = classifBilRec.macroag_desc_r
       and   a.utente = user_table;
    elsif classifBilRec.missione_code_r = '11' then 
       update siac_rep_prev_trasparenza_u a
       set  missione_code_11 = classifBilRec.missione_code_r,
            missione_desc_11 = classifBilRec.missione_desc_r,
            imp_competenza_11 = classifBilRec.stanziamento_prev_anno,
            imp_fpv_11 = classifBilRec.stanziamento_fpv_anno,
            imp_cassa_11 = classifBilRec.stanziamento_prev_cassa_anno
       where a.titusc_code = classifBilRec.titusc_code_r
       and   a.titusc_desc = classifBilRec.titusc_desc_r
       and   a.macroag_code = classifBilRec.macroag_code_r
       and   a.macroag_desc = classifBilRec.macroag_desc_r
       and   a.utente = user_table;
    elsif classifBilRec.missione_code_r = '12' then 
       update siac_rep_prev_trasparenza_u a
       set  missione_code_12 = classifBilRec.missione_code_r,
            missione_desc_12 = classifBilRec.missione_desc_r,
            imp_competenza_12 = classifBilRec.stanziamento_prev_anno,
            imp_fpv_12 = classifBilRec.stanziamento_fpv_anno,
            imp_cassa_12 = classifBilRec.stanziamento_prev_cassa_anno
       where a.titusc_code = classifBilRec.titusc_code_r
       and   a.titusc_desc = classifBilRec.titusc_desc_r
       and   a.macroag_code = classifBilRec.macroag_code_r
       and   a.macroag_desc = classifBilRec.macroag_desc_r
       and   a.utente = user_table;
    elsif classifBilRec.missione_code_r = '13' then 
       update siac_rep_prev_trasparenza_u a
       set  missione_code_13 = classifBilRec.missione_code_r,
            missione_desc_13 = classifBilRec.missione_desc_r,
            imp_competenza_13 = classifBilRec.stanziamento_prev_anno,
            imp_fpv_13 = classifBilRec.stanziamento_fpv_anno,
            imp_cassa_13 = classifBilRec.stanziamento_prev_cassa_anno
       where a.titusc_code = classifBilRec.titusc_code_r
       and   a.titusc_desc = classifBilRec.titusc_desc_r
       and   a.macroag_code = classifBilRec.macroag_code_r
       and   a.macroag_desc = classifBilRec.macroag_desc_r
       and   a.utente = user_table;
    elsif classifBilRec.missione_code_r = '14' then 
       update siac_rep_prev_trasparenza_u a
       set  missione_code_14 = classifBilRec.missione_code_r,
            missione_desc_14 = classifBilRec.missione_desc_r,
            imp_competenza_14 = classifBilRec.stanziamento_prev_anno,
            imp_fpv_14 = classifBilRec.stanziamento_fpv_anno,
            imp_cassa_14 = classifBilRec.stanziamento_prev_cassa_anno
       where a.titusc_code = classifBilRec.titusc_code_r
       and   a.titusc_desc = classifBilRec.titusc_desc_r
       and   a.macroag_code = classifBilRec.macroag_code_r
       and   a.macroag_desc = classifBilRec.macroag_desc_r
       and   a.utente = user_table;
    elsif classifBilRec.missione_code_r = '15' then 
       update siac_rep_prev_trasparenza_u a
       set  missione_code_15 = classifBilRec.missione_code_r,
            missione_desc_15 = classifBilRec.missione_desc_r,
            imp_competenza_15 = classifBilRec.stanziamento_prev_anno,
            imp_fpv_15 = classifBilRec.stanziamento_fpv_anno,
            imp_cassa_15 = classifBilRec.stanziamento_prev_cassa_anno
       where a.titusc_code = classifBilRec.titusc_code_r
       and   a.titusc_desc = classifBilRec.titusc_desc_r
       and   a.macroag_code = classifBilRec.macroag_code_r
       and   a.macroag_desc = classifBilRec.macroag_desc_r
       and   a.utente = user_table;
    elsif classifBilRec.missione_code_r = '16' then 
       update siac_rep_prev_trasparenza_u a
       set  missione_code_16 = classifBilRec.missione_code_r,
            missione_desc_16 = classifBilRec.missione_desc_r,
            imp_competenza_16 = classifBilRec.stanziamento_prev_anno,
            imp_fpv_16 = classifBilRec.stanziamento_fpv_anno,
            imp_cassa_16 = classifBilRec.stanziamento_prev_cassa_anno
       where a.titusc_code = classifBilRec.titusc_code_r
       and   a.titusc_desc = classifBilRec.titusc_desc_r
       and   a.macroag_code = classifBilRec.macroag_code_r
       and   a.macroag_desc = classifBilRec.macroag_desc_r
       and   a.utente = user_table;
    elsif classifBilRec.missione_code_r = '17' then 
       update siac_rep_prev_trasparenza_u a
       set  missione_code_17 = classifBilRec.missione_code_r,
            missione_desc_17 = classifBilRec.missione_desc_r,
            imp_competenza_17 = classifBilRec.stanziamento_prev_anno,
            imp_fpv_17 = classifBilRec.stanziamento_fpv_anno,
            imp_cassa_17 = classifBilRec.stanziamento_prev_cassa_anno
       where a.titusc_code = classifBilRec.titusc_code_r
       and   a.titusc_desc = classifBilRec.titusc_desc_r
       and   a.macroag_code = classifBilRec.macroag_code_r
       and   a.macroag_desc = classifBilRec.macroag_desc_r
       and   a.utente = user_table;
    elsif classifBilRec.missione_code_r = '18' then 
       update siac_rep_prev_trasparenza_u a
       set  missione_code_18 = classifBilRec.missione_code_r,
            missione_desc_18 = classifBilRec.missione_desc_r,
            imp_competenza_18 = classifBilRec.stanziamento_prev_anno,
            imp_fpv_18 = classifBilRec.stanziamento_fpv_anno,
            imp_cassa_18 = classifBilRec.stanziamento_prev_cassa_anno
       where a.titusc_code = classifBilRec.titusc_code_r
       and   a.titusc_desc = classifBilRec.titusc_desc_r
       and   a.macroag_code = classifBilRec.macroag_code_r
       and   a.macroag_desc = classifBilRec.macroag_desc_r
       and   a.utente = user_table;
    elsif classifBilRec.missione_code_r = '19' then 
       update siac_rep_prev_trasparenza_u a
       set  missione_code_19 = classifBilRec.missione_code_r,
            missione_desc_19 = classifBilRec.missione_desc_r,
            imp_competenza_19 = classifBilRec.stanziamento_prev_anno,
            imp_fpv_19 = classifBilRec.stanziamento_fpv_anno,
            imp_cassa_19 = classifBilRec.stanziamento_prev_cassa_anno
       where a.titusc_code = classifBilRec.titusc_code_r
       and   a.titusc_desc = classifBilRec.titusc_desc_r
       and   a.macroag_code = classifBilRec.macroag_code_r
       and   a.macroag_desc = classifBilRec.macroag_desc_r
       and   a.utente = user_table;
    elsif classifBilRec.missione_code_r = '20' then 
       update siac_rep_prev_trasparenza_u a
       set  missione_code_20 = classifBilRec.missione_code_r,
            missione_desc_20 = classifBilRec.missione_desc_r,
            imp_competenza_20 = classifBilRec.stanziamento_prev_anno,
            imp_fpv_20 = classifBilRec.stanziamento_fpv_anno,
            imp_cassa_20 = classifBilRec.stanziamento_prev_cassa_anno
       where a.titusc_code = classifBilRec.titusc_code_r
       and   a.titusc_desc = classifBilRec.titusc_desc_r
       and   a.macroag_code = classifBilRec.macroag_code_r
       and   a.macroag_desc = classifBilRec.macroag_desc_r
       and   a.utente = user_table;
    elsif classifBilRec.missione_code_r = '50' then 
       update siac_rep_prev_trasparenza_u a
       set  missione_code_50 = classifBilRec.missione_code_r,
            missione_desc_50 = classifBilRec.missione_desc_r,
            imp_competenza_50 = classifBilRec.stanziamento_prev_anno,
            imp_fpv_50 = classifBilRec.stanziamento_fpv_anno,
            imp_cassa_50 = classifBilRec.stanziamento_prev_cassa_anno
       where a.titusc_code = classifBilRec.titusc_code_r
       and   a.titusc_desc = classifBilRec.titusc_desc_r
       and   a.macroag_code = classifBilRec.macroag_code_r
       and   a.macroag_desc = classifBilRec.macroag_desc_r
       and   a.utente = user_table;
    elsif classifBilRec.missione_code_r = '60' then 
       update siac_rep_prev_trasparenza_u a
       set  missione_code_60 = classifBilRec.missione_code_r,
            missione_desc_60 = classifBilRec.missione_desc_r,
            imp_competenza_60 = classifBilRec.stanziamento_prev_anno,
            imp_fpv_60 = classifBilRec.stanziamento_fpv_anno,
            imp_cassa_60 = classifBilRec.stanziamento_prev_cassa_anno
       where a.titusc_code = classifBilRec.titusc_code_r
       and   a.titusc_desc = classifBilRec.titusc_desc_r
       and   a.macroag_code = classifBilRec.macroag_code_r
       and   a.macroag_desc = classifBilRec.macroag_desc_r
       and   a.utente = user_table;  
    elsif classifBilRec.missione_code_r = '99' then 
       update siac_rep_prev_trasparenza_u a
       set  missione_code_99 = classifBilRec.missione_code_r,
            missione_desc_99 = classifBilRec.missione_desc_r,
            imp_competenza_99 = classifBilRec.stanziamento_prev_anno,
            imp_fpv_99 = classifBilRec.stanziamento_fpv_anno,
            imp_cassa_99 = classifBilRec.stanziamento_prev_cassa_anno
       where a.titusc_code = classifBilRec.titusc_code_r
       and   a.titusc_desc = classifBilRec.titusc_desc_r
       and   a.macroag_code = classifBilRec.macroag_code_r
       and   a.macroag_desc = classifBilRec.macroag_desc_r
       and   a.utente = user_table;                                                                                                                                           
    end if;  
       
   end if;      
        
end loop;

for trasparenza in
select *
from siac_rep_prev_trasparenza_u
where utente = user_table
order by titusc_code, macroag_code

loop

  missione_code_01 := trasparenza.missione_code_01; 
  missione_desc_01 := trasparenza.missione_desc_01; 
  imp_competenza_01 := trasparenza.imp_competenza_01; 
  imp_fpv_01 := trasparenza.imp_fpv_01; 
  imp_cassa_01 := trasparenza.imp_cassa_01; 
  missione_code_02 := trasparenza.missione_code_02;  
  missione_desc_02 := trasparenza.missione_desc_02; 
  imp_competenza_02 := trasparenza.imp_competenza_02; 
  imp_fpv_02 := trasparenza.imp_fpv_02; 
  imp_cassa_02 := trasparenza.imp_cassa_02; 
  missione_code_03 := trasparenza.missione_code_03; 
  missione_desc_03 := trasparenza.missione_desc_03; 
  imp_competenza_03 := trasparenza.imp_competenza_03; 
  imp_fpv_03 := trasparenza.imp_fpv_03; 
  imp_cassa_03 := trasparenza.imp_cassa_03; 
  missione_code_04 := trasparenza.missione_code_04; 
  missione_desc_04 := trasparenza.missione_desc_04; 
  imp_competenza_04 := trasparenza.imp_competenza_04; 
  imp_fpv_04 := trasparenza.imp_fpv_04; 
  imp_cassa_04 := trasparenza.imp_cassa_04; 
  missione_code_05 := trasparenza.missione_code_05; 
  missione_desc_05 := trasparenza.missione_desc_05; 
  imp_competenza_05 := trasparenza.imp_competenza_05; 
  imp_fpv_05 := trasparenza.imp_fpv_05; 
  imp_cassa_05 := trasparenza.imp_cassa_05; 
  missione_code_06 := trasparenza.missione_code_06; 
  missione_desc_06 := trasparenza.missione_desc_06; 
  imp_competenza_06 := trasparenza.imp_competenza_06; 
  imp_fpv_06 := trasparenza.imp_fpv_06; 
  imp_cassa_06 := trasparenza.imp_cassa_06; 
  missione_code_07 := trasparenza.missione_code_07; 
  missione_desc_07 := trasparenza.missione_desc_07; 
  imp_competenza_07 := trasparenza.imp_competenza_07; 
  imp_fpv_07 := trasparenza.imp_fpv_07; 
  imp_cassa_07 := trasparenza.imp_cassa_07; 
  missione_code_08 := trasparenza.missione_code_08; 
  missione_desc_08 := trasparenza.missione_desc_08; 
  imp_competenza_08 := trasparenza.imp_competenza_08; 
  imp_fpv_08 := trasparenza.imp_fpv_08; 
  imp_cassa_08 := trasparenza.imp_cassa_08; 
  missione_code_09 := trasparenza.missione_code_09; 
  missione_desc_09 := trasparenza.missione_desc_09; 
  imp_competenza_09 := trasparenza.imp_competenza_09; 
  imp_fpv_09 := trasparenza.imp_fpv_09; 
  imp_cassa_09 := trasparenza.imp_cassa_09; 
  missione_code_10 := trasparenza.missione_code_10;
  missione_desc_10 := trasparenza.missione_desc_10; 
  imp_competenza_10 := trasparenza.imp_competenza_10; 
  imp_fpv_10 := trasparenza.imp_fpv_10; 
  imp_cassa_10 := trasparenza.imp_cassa_10; 
  missione_code_11 := trasparenza.missione_code_11; 
  missione_desc_11 := trasparenza.missione_desc_11; 
  imp_competenza_11 := trasparenza.imp_competenza_11; 
  imp_fpv_11 := trasparenza.imp_fpv_11; 
  imp_cassa_11 := trasparenza.imp_cassa_11; 
  missione_code_12 := trasparenza.missione_code_12; 
  missione_desc_12 := trasparenza.missione_desc_12; 
  imp_competenza_12 := trasparenza.imp_competenza_12; 
  imp_fpv_12 := trasparenza.imp_fpv_12; 
  imp_cassa_12 := trasparenza.imp_cassa_12; 
  missione_code_13 := trasparenza.missione_code_13; 
  missione_desc_13 := trasparenza.missione_desc_13; 
  imp_competenza_13 := trasparenza.imp_competenza_13; 
  imp_fpv_13 := trasparenza.imp_fpv_13; 
  imp_cassa_13 := trasparenza.imp_cassa_13; 
  missione_code_14 := trasparenza.missione_code_14; 
  missione_desc_14 := trasparenza.missione_desc_14; 
  imp_competenza_14 := trasparenza.imp_competenza_14; 
  imp_fpv_14 := trasparenza.imp_fpv_14; 
  imp_cassa_14 := trasparenza.imp_cassa_14; 
  missione_code_15 := trasparenza.missione_code_15; 
  missione_desc_15 := trasparenza.missione_desc_15; 
  imp_competenza_15 := trasparenza.imp_competenza_15; 
  imp_fpv_15 := trasparenza.imp_fpv_15; 
  imp_cassa_15 := trasparenza.imp_cassa_15; 
  missione_code_16 := trasparenza.missione_code_16; 
  missione_desc_16 := trasparenza.missione_desc_16;
  imp_competenza_16 := trasparenza.imp_competenza_16; 
  imp_fpv_16 := trasparenza.imp_fpv_16; 
  imp_cassa_16 := trasparenza.imp_cassa_16; 
  missione_code_17 := trasparenza.missione_code_17; 
  missione_desc_17 := trasparenza.missione_desc_17; 
  imp_competenza_17 := trasparenza.imp_competenza_17; 
  imp_fpv_17 := trasparenza.imp_fpv_17; 
  imp_cassa_17 := trasparenza.imp_cassa_17; 
  missione_code_18 := trasparenza.missione_code_18; 
  missione_desc_18 := trasparenza.missione_desc_18; 
  imp_competenza_18 := trasparenza.imp_competenza_18; 
  imp_fpv_18 := trasparenza.imp_fpv_18; 
  imp_cassa_18 := trasparenza.imp_cassa_18; 
  missione_code_19 := trasparenza.missione_code_19; 
  missione_desc_19 := trasparenza.missione_desc_19; 
  imp_competenza_19 := trasparenza.imp_competenza_19; 
  imp_fpv_19 := trasparenza.imp_fpv_19; 
  imp_cassa_19 := trasparenza.imp_cassa_19; 
  missione_code_20 := trasparenza.missione_code_20; 
  missione_desc_20 := trasparenza.missione_desc_20; 
  imp_competenza_20 := trasparenza.imp_competenza_20; 
  imp_fpv_20 := trasparenza.imp_fpv_20; 
  imp_cassa_20 := trasparenza.imp_cassa_20; 
  missione_code_50 := trasparenza.missione_code_50; 
  missione_desc_50 := trasparenza.missione_desc_50; 
  imp_competenza_50 := trasparenza.imp_competenza_50; 
  imp_fpv_50 := trasparenza.imp_fpv_50; 
  imp_cassa_50 := trasparenza.imp_cassa_50; 
  missione_code_60 := trasparenza.missione_code_60; 
  missione_desc_60 := trasparenza.missione_desc_60; 
  imp_competenza_60 := trasparenza.imp_competenza_60; 
  imp_fpv_60 := trasparenza.imp_fpv_60; 
  imp_cassa_60 := trasparenza.imp_cassa_60; 
  missione_code_99 := trasparenza.missione_code_99; 
  missione_desc_99 := trasparenza.missione_desc_99; 
  imp_competenza_99 := trasparenza.imp_competenza_99; 
  imp_fpv_99 := trasparenza.imp_fpv_99; 
  imp_cassa_99 := trasparenza.imp_cassa_99; 
  titusc_code := trasparenza.titusc_code; 
  titusc_desc := trasparenza.titusc_desc; 
  macroag_code := trasparenza.macroag_code; 
  macroag_desc := trasparenza.macroag_desc; 
  ripiano_disavanzo=0; 
  imp_competenza_tot=trasparenza.imp_competenza_01+
                     trasparenza.imp_competenza_02+
                     trasparenza.imp_competenza_03+
                     trasparenza.imp_competenza_04+
                     trasparenza.imp_competenza_05+
                     trasparenza.imp_competenza_06+
                     trasparenza.imp_competenza_07+
                     trasparenza.imp_competenza_08+
                     trasparenza.imp_competenza_09+
                     trasparenza.imp_competenza_10+
                     trasparenza.imp_competenza_11+
                     trasparenza.imp_competenza_12+
                     trasparenza.imp_competenza_13+
                     trasparenza.imp_competenza_14+
                     trasparenza.imp_competenza_15+
                     trasparenza.imp_competenza_16+
                     trasparenza.imp_competenza_17+
                     trasparenza.imp_competenza_18+
                     trasparenza.imp_competenza_19+
                     trasparenza.imp_competenza_20+
                     trasparenza.imp_competenza_50+
                     trasparenza.imp_competenza_60+
                     trasparenza.imp_competenza_99;
  imp_cassa_tot=trasparenza.imp_cassa_01+
                     trasparenza.imp_cassa_02+
                     trasparenza.imp_cassa_03+
                     trasparenza.imp_cassa_04+
                     trasparenza.imp_cassa_05+
                     trasparenza.imp_cassa_06+
                     trasparenza.imp_cassa_07+
                     trasparenza.imp_cassa_08+
                     trasparenza.imp_cassa_09+
                     trasparenza.imp_cassa_10+
                     trasparenza.imp_cassa_11+
                     trasparenza.imp_cassa_12+
                     trasparenza.imp_cassa_13+
                     trasparenza.imp_cassa_14+
                     trasparenza.imp_cassa_15+
                     trasparenza.imp_cassa_16+
                     trasparenza.imp_cassa_17+
                     trasparenza.imp_cassa_18+
                     trasparenza.imp_cassa_19+
                     trasparenza.imp_cassa_20+
                     trasparenza.imp_cassa_50+
                     trasparenza.imp_cassa_60+
                     trasparenza.imp_cassa_99;
  imp_fpv_tot=trasparenza.imp_fpv_01+
                     trasparenza.imp_fpv_02+
                     trasparenza.imp_fpv_03+
                     trasparenza.imp_fpv_04+
                     trasparenza.imp_fpv_05+
                     trasparenza.imp_fpv_06+
                     trasparenza.imp_fpv_07+
                     trasparenza.imp_fpv_08+
                     trasparenza.imp_fpv_09+
                     trasparenza.imp_fpv_10+
                     trasparenza.imp_fpv_11+
                     trasparenza.imp_fpv_12+
                     trasparenza.imp_fpv_13+
                     trasparenza.imp_fpv_14+
                     trasparenza.imp_fpv_15+
                     trasparenza.imp_fpv_16+
                     trasparenza.imp_fpv_17+
                     trasparenza.imp_fpv_18+
                     trasparenza.imp_fpv_19+
                     trasparenza.imp_fpv_20+
                     trasparenza.imp_fpv_50+
                     trasparenza.imp_fpv_60+
                     trasparenza.imp_fpv_99;

  return next;
  missione_code_01=''; 
  missione_desc_01=''; 
  imp_competenza_01=0;
  imp_fpv_01=0;
  imp_cassa_01=0;
  missione_code_02=''; 
  missione_desc_02='';
  imp_competenza_02=0;
  imp_fpv_02=0;
  imp_cassa_02=0;  
  missione_code_03='';
  missione_desc_03='';
  imp_competenza_03=0;
  imp_fpv_03=0;
  imp_cassa_03=0;
  missione_code_04='';
  missione_desc_04='';
  imp_competenza_04=0;
  imp_fpv_04=0;
  imp_cassa_04=0;
  missione_code_05='';
  missione_desc_05='';
  imp_competenza_05=0;
  imp_fpv_05=0;
  imp_cassa_05=0;
  missione_code_06='';
  missione_desc_06='';
  imp_competenza_06=0;
  imp_fpv_06=0;
  imp_cassa_06=0;
  missione_code_07='';
  missione_desc_07='';
  imp_competenza_07=0;
  imp_fpv_07=0;
  imp_cassa_07=0;
  missione_code_08='';
  missione_desc_08='';
  imp_competenza_08=0;
  imp_fpv_08=0;
  imp_cassa_08=0;
  missione_code_09='';
  missione_desc_09='';
  imp_competenza_09=0;
  imp_fpv_09=0;
  imp_cassa_09=0;
  missione_code_10='';
  missione_desc_10='';
  imp_competenza_10=0;
  imp_fpv_10=0;
  imp_cassa_10=0;
  missione_code_11='';
  missione_desc_11='';
  imp_competenza_11=0;
  imp_fpv_11=0;
  imp_cassa_11=0;
  missione_code_12='';
  missione_desc_12='';
  imp_competenza_12=0;
  imp_fpv_12=0;
  imp_cassa_12=0;
  missione_code_13='';
  missione_desc_13='';
  imp_competenza_13=0;
  imp_fpv_13=0;
  imp_cassa_13=0;
  missione_code_14='';
  missione_desc_14='';
  imp_competenza_14=0;
  imp_fpv_14=0;
  imp_cassa_14=0;
  missione_code_15='';
  missione_desc_15='';
  imp_competenza_15=0;
  imp_fpv_15=0;
  imp_cassa_15=0;
  missione_code_16='';
  missione_desc_16='';
  imp_competenza_16=0;
  imp_fpv_16=0;
  imp_cassa_16=0;
  missione_code_17='';
  missione_desc_17='';
  imp_competenza_17=0;
  imp_fpv_17=0;
  imp_cassa_17=0;
  missione_code_18='';
  missione_desc_18='';
  imp_competenza_18=0;
  imp_fpv_18=0;
  imp_cassa_18=0;
  missione_code_19='';
  missione_desc_19='';
  imp_competenza_19=0;
  imp_fpv_19=0;
  imp_cassa_19=0;
  missione_code_20='';
  missione_desc_20='';
  imp_competenza_20=0;
  imp_fpv_20=0;
  imp_cassa_20=0;
  missione_code_50='';
  missione_desc_50='';
  imp_competenza_50=0;
  imp_fpv_50=0;
  imp_cassa_50=0;
  missione_code_60='';
  missione_desc_60='';
  imp_competenza_60=0;
  imp_fpv_60=0;
  imp_cassa_60=0;
  missione_code_99='';
  missione_desc_99='';
  imp_competenza_99=0;
  imp_fpv_99=0;
  imp_cassa_99=0;
  titusc_code='';
  titusc_desc='';
  macroag_code='';
  macroag_desc='';
  ripiano_disavanzo=0; 
  imp_competenza_tot=0;
  imp_cassa_tot=0;
  imp_fpv_tot=0;     

end loop;

--raise notice '11: %', clock_timestamp()::varchar;


delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;
delete from siac_rep_cap_up where utente=user_table;
delete from siac_rep_cap_up_imp where utente=user_table;
delete from siac_rep_cap_up_imp_riga where utente=user_table;
delete from siac_rep_mptm_up_cap_importi where utente=user_table;
delete from siac_rep_impegni where utente=user_table;
delete from siac_rep_impegni_riga  where utente=user_table;
delete from siac_rep_prev_trasparenza_u where utente=user_table; 

--raise notice '12: %', clock_timestamp()::varchar;

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