/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR072_variazione_su_impegni_sintesi" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  nome_ente varchar,
  missione_code varchar,
  missione_desc varchar,
  sett_code varchar,
  sett_desc varchar,
  motivo_var_code varchar,
  motivo_var_desc varchar,
  anno_var integer,
  importo_var numeric
) AS
$body$
DECLARE
elencoVariazioni record;

annoCapImp_int integer;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';

BEGIN

annoCapImp_int:= p_anno::integer;  
elemTipoCode:='CAP-UG'; -- tipo capitolo spesa gestione      

nome_ente='';
missione_code='';
missione_desc='';
sett_code='';
sett_desc='';
motivo_var_code='';
motivo_var_desc='';
anno_var=0;
importo_var=0;


select fnc_siac_random_user()
into	user_table;

raise notice 'ora: % ',clock_timestamp()::varchar;
RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';
raise notice 'inserimento tabella di comodo STRUTTURA DEL BILANCIO';

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
   --, siac_r_class progmacro
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

RTN_MESSAGGIO:='inizio estrazione delle variazioni ''.';
raise notice 'inizio estrazione delle variazioni ''.';

for elencoVariazioni in
       
select capitolo.elem_id,v1.missione_code,v1.missione_desc, t_mov_gest.movgest_id,t_modifica.mod_num,
t_mov_gest.movgest_numero NUM_IMPEGNO,t_mov_gest.movgest_anno ANNO_COMP_IMPEGNO, 
t_movgest_ts_det_mod.movgest_ts_det_importo IMPORTO, d_modifica_tipo.mod_tipo_code COD_MOTIVO, 
d_modifica_tipo.mod_tipo_desc DESC_MOTIVO, t_ente_prop.ente_denominazione
from siac_t_movgest t_mov_gest,
	siac_d_movgest_tipo d_mov_gest_tipo,
    siac_t_movgest_ts t_movgest_ts,
    siac_d_movgest_ts_tipo   ts_mov_tipo, 
    siac_t_movgest_ts_det t_movgest_ts_det,
    siac_t_movgest_ts_det_mod t_movgest_ts_det_mod,
    siac_r_modifica_stato r_modifica_stato,
    siac_t_modifica 	t_modifica,
    siac_d_modifica_tipo 	d_modifica_tipo,
    siac_d_modifica_stato 	d_modifica_stato,
    siac_t_bil_elem		capitolo,
    siac_d_bil_elem_tipo    t_capitolo,
    siac_d_bil_elem_stato stato_capitolo,
    siac_r_bil_elem_stato r_capitolo_stato,
    siac_r_movgest_bil_elem r_movgest_bil_elem,
	siac_t_bil			bilancio,
    siac_t_periodo      anno_eserc,
    siac_t_ente_proprietario	t_ente_prop,
    siac_rep_mis_pro_tit_mac_riga_anni v1,
    siac_rep_cap_ug tb
where d_mov_gest_tipo.movgest_tipo_id=t_mov_gest.movgest_tipo_id
		AND t_movgest_ts.movgest_id=t_mov_gest.movgest_id
        and t_movgest_ts.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id       
        AND t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
        AND t_movgest_ts_det_mod.movgest_ts_det_id=t_movgest_ts_det.movgest_ts_det_id
        AND r_modifica_stato.mod_stato_r_id=t_movgest_ts_det_mod.mod_stato_r_id
        and d_modifica_stato.mod_stato_id=r_modifica_stato.mod_stato_id
        and t_modifica.mod_id  = r_modifica_stato.mod_id
        AND d_modifica_tipo.mod_tipo_id =t_modifica.mod_tipo_id
        AND t_capitolo.elem_tipo_id=capitolo.elem_tipo_id
        AND r_capitolo_stato.elem_id=capitolo.elem_id
        AND r_capitolo_stato.elem_stato_id=stato_capitolo.elem_stato_id
        AND r_movgest_bil_elem.elem_id=capitolo.elem_id
        AND r_movgest_bil_elem.movgest_id=t_mov_gest.movgest_id
        AND bilancio.bil_id=capitolo.bil_id
        AND anno_eserc.periodo_id=bilancio.periodo_id
        and t_ente_prop.ente_proprietario_id=capitolo.ente_proprietario_id
        AND v1.programma_id = tb.programma_id    
		and	v1.macroag_id	= tb.macroaggregato_id
        and tb.elem_id=capitolo.elem_id
        AND TB.utente=V1.utente
        and v1.utente=user_table
		AND d_mov_gest_tipo.movgest_tipo_code='I'    
        AND t_capitolo.elem_tipo_code=elemTipoCode
        and anno_eserc.anno=p_anno
        and d_modifica_stato.mod_stato_code='V'
        and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
        and stato_capitolo.elem_stato_code='VA'
        and t_mov_gest.movgest_anno <=annoCapImp_int
        AND t_mov_gest.ente_proprietario_id=p_ente_prop_id
        and t_mov_gest.data_cancellazione is NULL
        and d_mov_gest_tipo.data_cancellazione is NULL
        and t_movgest_ts.data_cancellazione is NULL
        and t_movgest_ts_det.data_cancellazione is NULL
        and t_movgest_ts_det_mod.data_cancellazione is NULL
        and r_modifica_stato.data_cancellazione is NULL
        and t_modifica.data_cancellazione is NULL
        and d_modifica_tipo.data_cancellazione is NULL
        and capitolo.data_cancellazione is NULL
        and t_capitolo.data_cancellazione is NULL
        and r_movgest_bil_elem.data_cancellazione is NULL
        and bilancio.data_cancellazione is NULL
        and anno_eserc.data_cancellazione is NULL
        and d_modifica_stato.data_cancellazione is NULL
        and ts_mov_tipo.data_cancellazione is NULL  
        and stato_capitolo.data_cancellazione is NULL
        and r_capitolo_stato.data_cancellazione is NULL 

loop
 
  	missione_code:= elencoVariazioni.missione_code;
  	missione_desc:= elencoVariazioni.missione_desc;
	nome_ente=elencoVariazioni.ente_denominazione;

	motivo_var_code=elencoVariazioni.COD_MOTIVO;
	motivo_var_desc=elencoVariazioni.DESC_MOTIVO;
	anno_var=elencoVariazioni.ANNO_COMP_IMPEGNO;
	importo_var=elencoVariazioni.IMPORTO;

	IF elencoVariazioni.ELEM_ID IS NOT NULL THEN
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
                and capitolo.elem_id=elencoVariazioni.ELEM_ID
                 AND r_bil_elem_class.data_cancellazione is NULL
                 AND t_class.data_cancellazione is NULL
                 AND d_class_tipo.data_cancellazione is NULL
                 AND capitolo.data_cancellazione is NULL;	
           IF NOT FOUND THEN
              --RAISE EXCEPTION 'Non esiste il Settore per  %', classifBilRec.ELEM_ID;
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
nome_ente='';
missione_code='';
missione_desc='';
sett_code='';
sett_desc='';
motivo_var_code='';
motivo_var_desc='';
anno_var=0;
importo_var=0;

end loop;

raise notice 'ora: % ',clock_timestamp()::varchar;

raise notice 'fine estrazione delle variazioni';

delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;
delete from siac_rep_cap_up where utente=user_table;


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