/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR121_riep_spese_macroaggregati" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
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
  impegni numeric,
  flag_ricorrente varchar,
  impegni_non_ricorrenti numeric
) AS
$body$
DECLARE

classifBilRec record;

annoPrec varchar;
elemTipoCode varchar;
user_table	 varchar;
ricorrente   integer;
DEF_NULL	 constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';

BEGIN

elemTipoCode:='CAP-UG'; -- tipo capitolo gestione
annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
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
flag_ricorrente='';
impegni_non_ricorrenti=0;

RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into	user_table;

RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';

-- Parte valida se NON si considera la tabella siac_r_class progmacro INIZIO
/*INSERT INTO siac_rep_tit_mac_riga
SELECT v.*,user_table FROM 
(SELECT 
    titusc_tipo.classif_tipo_desc AS titusc_tipo_desc,
    titusc.classif_id AS titusc_id, 
    titusc.classif_code AS titusc_code,
    titusc.classif_desc AS titusc_desc,
    macroaggr_tipo.classif_tipo_desc AS macroag_tipo_desc,
    macroaggr.classif_id AS macroag_id, 
    macroaggr.classif_code AS macroag_code,
    macroaggr.classif_desc AS macroag_desc,
    macroaggr.ente_proprietario_id
FROM 
    siac_d_class_fam titusc_fam,
    siac_t_class_fam_tree titusc_tree, 
    siac_r_class_fam_tree titusc_r_cft,
    siac_t_class titusc, 
    siac_d_class_tipo titusc_tipo,
    siac_d_class_tipo macroaggr_tipo, 
    siac_t_class macroaggr
WHERE titusc_fam.classif_fam_desc::text = 'Spesa - TitoliMacroaggregati'::text 
    AND titusc_fam.classif_fam_id = titusc_tree.classif_fam_id 
    AND titusc_tree.classif_fam_tree_id = titusc_r_cft.classif_fam_tree_id 
    AND titusc_r_cft.classif_id_padre = titusc.classif_id
    AND titusc_tipo.classif_tipo_code::text = 'TITOLO_SPESA'::text 
    AND titusc.classif_tipo_id = titusc_tipo.classif_tipo_id 
    AND macroaggr_tipo.classif_tipo_code::text = 'MACROAGGREGATO'::text 
    AND titusc_r_cft.classif_id = macroaggr.classif_id 
    AND macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id
    AND titusc.ente_proprietario_id = macroaggr.ente_proprietario_id
    AND to_timestamp('01/01/'||p_anno,'dd/mm/yyyy') BETWEEN  macroaggr.validita_inizio AND COALESCE(macroaggr.validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
    AND to_timestamp('01/01/'||p_anno,'dd/mm/yyyy') BETWEEN  titusc.validita_inizio AND COALESCE(titusc.validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))    
) v   
WHERE v.ente_proprietario_id = p_ente_prop_id 
ORDER BY v.titusc_code ,v. macroag_code;*/
-- Parte valida se NON si considera la tabella siac_r_class progmacro FINE

-- Parte valida se si considera la tabella siac_r_class progmacro INIZIO
/*INSERT INTO siac_rep_mis_pro_tit_mac_riga_anni
SELECT v.*,user_table FROM
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
ORDER BY missione.classif_code, programma.classif_code, titusc.classif_code, macroaggr.classif_code) v
WHERE v.ente_proprietario_id=p_ente_prop_id 
AND  to_timestamp('01/01/'||p_anno,'dd/mm/yyyy') BETWEEN  v.macroag_validita_inizio AND COALESCE(v.macroag_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
AND  to_timestamp('01/01/'||p_anno,'dd/mm/yyyy') BETWEEN  v.missione_validita_inizio AND COALESCE(v.missione_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
AND  to_timestamp('01/01/'||p_anno,'dd/mm/yyyy') BETWEEN  v.programma_validita_inizio AND COALESCE(v.programma_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
AND  to_timestamp('01/01/'||p_anno,'dd/mm/yyyy') BETWEEN  v.titusc_validita_inizio and COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
ORDER BY missione_code, programma_code,titusc_code,macroag_code;
-- Parte valida se si considera la tabella siac_r_class progmacro FINE
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
 
RTN_MESSAGGIO:='inserimento tabella di comodo dei capitoli ''.';

-- Parte valida se NON si considera la tabella siac_r_class progmacro INIZIO
/*INSERT INTO siac_rep_cap_ug
SELECT  0,cl.classif_id, anno_eserc.anno anno_bilancio, e.*, null, user_table utente
FROM 	siac_r_bil_elem_class rc,
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
WHERE ct.classif_tipo_code			=	'MACROAGGREGATO'
AND ct.classif_tipo_id				=	cl.classif_tipo_id
AND cl.classif_id					=	rc.classif_id 
AND e.ente_proprietario_id			=	p_ente_prop_id
AND anno_eserc.anno					= 	p_anno
AND bilancio.periodo_id				=	anno_eserc.periodo_id 
AND e.bil_id						=	bilancio.bil_id 
AND e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
AND tipo_elemento.elem_tipo_code 	= 	elemTipoCode
AND e.elem_id						=	rc.elem_id 
AND	e.elem_id						=	r_capitolo_stato.elem_id
AND	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
AND	stato_capitolo.elem_stato_code	=	'VA'
AND	e.elem_id						=	r_cat_capitolo.elem_id
AND	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
AND	cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')	
AND e.data_cancellazione 				is null
AND	r_capitolo_stato.data_cancellazione	is null
AND	r_cat_capitolo.data_cancellazione	is null
AND	rc.data_cancellazione				is null
AND	ct.data_cancellazione 				is null
AND	cl.data_cancellazione 				is null
AND	bilancio.data_cancellazione 		is null
AND	anno_eserc.data_cancellazione 		is null
AND	tipo_elemento.data_cancellazione	is null
AND	stato_capitolo.data_cancellazione 	is null
AND	cat_del_capitolo.data_cancellazione	is null
AND	now() BETWEEN rc.validita_inizio AND COALESCE (rc.validita_fine, now())
AND	now() BETWEEN e.validita_inizio AND COALESCE (e.validita_fine, now())
AND	now() BETWEEN bilancio.validita_inizio AND COALESCE (bilancio.validita_fine, now())
AND	now() BETWEEN anno_eserc.validita_inizio AND COALESCE (anno_eserc.validita_fine, now())
AND	now() BETWEEN ct.validita_inizio AND COALESCE (ct.validita_fine, now())
AND	now() BETWEEN cl.validita_inizio AND COALESCE (cl.validita_fine, now())
AND	now() BETWEEN tipo_elemento.validita_inizio AND COALESCE (tipo_elemento.validita_fine, now())
AND	now() BETWEEN stato_capitolo.validita_inizio AND COALESCE (stato_capitolo.validita_fine, now())
AND	now() BETWEEN r_capitolo_stato.validita_inizio AND COALESCE (r_capitolo_stato.validita_fine, now())
AND	now() BETWEEN cat_del_capitolo.validita_inizio AND COALESCE (cat_del_capitolo.validita_fine, now())
AND	now() BETWEEN r_cat_capitolo.validita_inizio AND COALESCE (r_cat_capitolo.validita_fine, now());

--10/05/2016: carico nella tabella di appoggio dei capitoli gli eventuali 
-- capitoli presenti sulla tabella con gli importi previsti anni precedenti
-- che possono avere cambiato numero di capitolo. 
INSERT INTO siac_rep_cap_ug 
SELECT  0,macroaggr.classif_id, p_anno, NULL, prec.elem_code, prec.elem_code2, 
      	prec.elem_code3, NULL, NULL,  NULL, NULL, NULL, NULL, NULL,NULL,NULL,
        prec.ente_proprietario_id, prec.data_creazione, prec.data_modifica,
        prec.data_cancellazione,prec.login_operazione, NULL, user_table utente
FROM    siac_t_cap_u_importi_anno_prec prec,
        siac_d_class_tipo macroaggr_tipo,
        siac_t_class macroaggr
WHERE macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 	
AND macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'
AND macroaggr.classif_code=prec.macroagg_code
AND macroaggr.ente_proprietario_id =prec.ente_proprietario_id
AND prec.ente_proprietario_id=p_ente_prop_id       	
AND	prec.elem_cat_code	in ('STD','FPV','FSC','FPVC')
AND to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy') BETWEEN macroaggr.validita_inizio AND COALESCE(macroaggr.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
AND NOT EXISTS (SELECT 1 FROM siac_rep_cap_ug up
                WHERE up.elem_code=prec.elem_code
                AND up.elem_code2=prec.elem_code2
                AND up.elem_code3=prec.elem_code3
                AND up.macroaggregato_id = macroaggr.classif_id
                AND up.utente=user_table
                AND up.ente_proprietario_id=p_ente_prop_id);*/
-- Parte valida se NON si considera la tabella siac_r_class progmacro FINE

-- Parte valida se si considera la tabella siac_r_class progmacro INIZIO
INSERT INTO siac_rep_cap_ug
SELECT 	programma.classif_id,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
       user_table utente
FROM siac_t_bil bilancio,
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
WHERE   programma_tipo.classif_tipo_code='PROGRAMMA' 									
    AND programma.classif_tipo_id=programma_tipo.classif_tipo_id 				
    AND programma.classif_id=r_capitolo_programma.classif_id				
    AND macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'					
    AND macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 			
    AND macroaggr.classif_id=r_capitolo_macroaggr.classif_id					
    AND capitolo.ente_proprietario_id=p_ente_prop_id      					
   	AND anno_eserc.anno= p_anno 											
    AND bilancio.periodo_id=anno_eserc.periodo_id 							
    AND capitolo.bil_id=bilancio.bil_id 										
   	AND capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 					
    AND tipo_elemento.elem_tipo_code = elemTipoCode						      
    AND capitolo.elem_id=r_capitolo_programma.elem_id						
    AND capitolo.elem_id=r_capitolo_macroaggr.elem_id							
    AND capitolo.elem_id				=	r_capitolo_stato.elem_id			
	AND r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
	AND stato_capitolo.elem_stato_code	=	'VA'								
    AND capitolo.elem_id				=	r_cat_capitolo.elem_id			
	AND r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id	
	AND cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
    AND	bilancio.data_cancellazione 				IS NULL
	AND	anno_eserc.data_cancellazione 				IS NULL
   	AND	programma_tipo.data_cancellazione 			IS NULL
    AND	programma.data_cancellazione 				IS NULL
    AND	macroaggr_tipo.data_cancellazione 			IS NULL
    AND	macroaggr.data_cancellazione 				IS NULL
	AND	capitolo.data_cancellazione 				IS NULL
	AND	tipo_elemento.data_cancellazione 			IS NULL
    AND	r_capitolo_programma.data_cancellazione 	IS NULL
   	AND	r_capitolo_macroaggr.data_cancellazione 	IS NULL 
	AND	stato_capitolo.data_cancellazione 			IS NULL
    AND	r_capitolo_stato.data_cancellazione 		IS NULL
	AND	cat_del_capitolo.data_cancellazione 		IS NULL
    AND	r_cat_capitolo.data_cancellazione 	 		IS NULL;	
    
--09/05/2016: carico nella tabella di appoggio con i capitoli gli eventuali 
-- capitoli presenti sulla tabella con gli importi previsti anni precedenti
-- che possono avere cambiato numero di capitolo. 
/*INSERT INTO siac_rep_cap_ug 
SELECT  programma.classif_id, macroaggr.classif_id, p_anno, NULL, prec.elem_code, prec.elem_code2, 
      	prec.elem_code3, NULL, NULL,  NULL, NULL, NULL, NULL, NULL,NULL,NULL,
        prec.ente_proprietario_id, prec.data_creazione, prec.data_modifica,
        prec.data_cancellazione,prec.login_operazione, NULL, user_table utente
FROM    siac_t_cap_u_importi_anno_prec prec,
        siac_d_class_tipo programma_tipo,
        siac_d_class_tipo macroaggr_tipo,
        siac_t_class programma,
        siac_t_class macroaggr
WHERE programma_tipo.classif_tipo_id	=	programma.classif_tipo_id
AND programma.classif_code=prec.programma_code
AND programma_tipo.classif_tipo_code	=	'PROGRAMMA'
AND macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 	
AND macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'
AND macroaggr.classif_code=prec.macroagg_code
AND programma.ente_proprietario_id =prec.ente_proprietario_id
AND macroaggr.ente_proprietario_id =prec.ente_proprietario_id
AND prec.ente_proprietario_id=p_ente_prop_id       
AND to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy') BETWEEN programma.validita_inizio AND COALESCE(programma.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
AND to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy') BETWEEN macroaggr.validita_inizio AND COALESCE(macroaggr.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
AND NOT EXISTS (SELECT 1 
                FROM siac_rep_cap_up up
                WHERE up.elem_code=prec.elem_code
                AND up.elem_code2=prec.elem_code2
                AND up.elem_code3=prec.elem_code3
                AND up.macroaggregato_id = macroaggr.classif_id
                AND up.programma_id = programma.classif_id
                AND up.utente=user_table
                AND up.ente_proprietario_id=p_ente_prop_id); */
               
-- REMEDY INC000001514672
-- Select ricostruita considerando la condizione sull'anno nella tabella siac_t_cap_u_importi_anno_prec                        
insert into siac_rep_cap_ug                        
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
and not exists (select 1 from siac_rep_cap_ug ug
                      where ug.elem_code=prec.elem_code
                        AND ug.elem_code2=prec.elem_code2
                        and ug.elem_code3=prec.elem_code3
                        and ug.macroaggregato_id = macro.classif_id
                        and ug.programma_id = progr.classif_id
                        and ug.utente=user_table
                        and ug.ente_proprietario_id=prec.ente_proprietario_id);
                        
-- Parte valida se si considera la tabella siac_r_class progmacro FINE
RTN_MESSAGGIO:='acquisizione degli impegni ''.';   

INSERT INTO siac_rep_impegni
SELECT 	tb2.elem_id,
        p_anno,
        p_ente_prop_id,
        user_table utente,
		tb.importo				
FROM (
SELECT capitolo.elem_id, SUM(dt_movimento.movgest_ts_det_importo) importo
FROM 
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
WHERE bilancio.periodo_id    		= 	anno_eserc.periodo_id 
AND anno_eserc.anno       			=   p_anno 
AND bilancio.bil_id      			=	capitolo.bil_id
AND capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
AND t_capitolo.elem_tipo_code    	= 	elemTipoCode
AND movimento.movgest_anno ::text  	= 	p_anno
AND movimento.bil_id				=	bilancio.bil_id
AND r_mov_capitolo.elem_id    		=	capitolo.elem_id
AND r_mov_capitolo.movgest_id    	= 	movimento.movgest_id 
AND movimento.movgest_tipo_id    	= 	tipo_mov.movgest_tipo_id 
AND tipo_mov.movgest_tipo_code    	=  'I' 
AND movimento.movgest_id      		= 	ts_movimento.movgest_id 
AND ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
AND r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
AND tipo_stato.movgest_stato_code   in ('D','N') -- Definitivo e definitivo non liquidabile
AND ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
AND ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
AND ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
AND dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
AND dt_mov_tipo.movgest_ts_det_tipo_code = 'A' -- Importo attuale 
AND	now() BETWEEN bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
AND	now() BETWEEN anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
AND	now() BETWEEN capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
AND	now() BETWEEN t_capitolo.validita_inizio and coalesce (t_capitolo.validita_fine, now())
AND	now() BETWEEN movimento.validita_inizio and coalesce (movimento.validita_fine, now())
AND	now() BETWEEN ts_movimento.validita_inizio and coalesce (ts_movimento.validita_fine, now())
-- 12/05/2017: aggiunto questo controllo sulla data di validità della
      --    tabella siac_r_movgest_ts_stato a seguito di un'anomalia segnalata.
and	now() between r_movimento_stato.validita_inizio and coalesce (r_movimento_stato.validita_fine, now())
AND anno_eserc.data_cancellazione    	is null 
AND bilancio.data_cancellazione     	is null 
AND capitolo.data_cancellazione     	is null 
AND r_mov_capitolo.data_cancellazione is null 
AND t_capitolo.data_cancellazione    	is null 
AND movimento.data_cancellazione     	is null 
AND tipo_mov.data_cancellazione     	is null 
AND r_movimento_stato.data_cancellazione   is null 
AND ts_movimento.data_cancellazione   is null 
AND tipo_stato.data_cancellazione    	is null 
AND dt_movimento.data_cancellazione   is null 
AND ts_mov_tipo.data_cancellazione    is null 
AND dt_mov_tipo.data_cancellazione    is null
AND anno_eserc.ente_proprietario_id   = p_ente_prop_id
GROUP BY capitolo.elem_id) tb,
(SELECT capitolo_eg.elem_id 
 FROM  siac_t_bil_elem capitolo_eg, siac_d_bil_elem_tipo t_capitolo_eg
 WHERE capitolo_eg.elem_tipo_id		=	t_capitolo_eg.elem_tipo_id 
 AND   t_capitolo_eg.elem_tipo_code 	= 	elemTipoCode) tb2
WHERE  tb2.elem_id	=	tb.elem_id;

RTN_MESSAGGIO:='estrazione dei dati dalle tabelle di comodo e preparazione dati in output ''.';   

-- Parte valida se NON si considera la tabella siac_r_class progmacro INIZIO
/*FOR classifBilRec IN
SELECT 	v1.titusc_tipo_desc    		    titoloe_TIPO_DESC,
       	v1.titusc_id              		titoloe_ID,
       	v1.titusc_code             		titoloe_CODE,
       	v1.titusc_desc                  titoloe_DESC,
        v1.macroag_tipo_desc            macroag_TIPO_DESC,		
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
        COALESCE(tb4.importo,0)	        impegni
FROM  	  siac_rep_tit_mac_riga v1
FULL JOIN siac_rep_cap_ug tb ON (v1.macroag_id = tb.macroaggregato_id 
                                  AND v1.ente_proprietario_id = p_ente_prop_id
					              AND tb.utente = v1.utente
                                  AND v1.utente = user_table)	
LEFT JOIN  siac_rep_impegni tb4 ON tb4.elem_id = tb.elem_id           	
ORDER BY titoloe_CODE, macroag_CODE  */          
-- Parte valida se NON si considera la tabella siac_r_class progmacro FINE

-- Parte valida se si considera la tabella siac_r_class progmacro INIZIO
FOR classifBilRec IN
SELECT 	v1.titusc_tipo_desc    		    titoloe_TIPO_DESC,
       	v1.titusc_id              		titoloe_ID,
       	v1.titusc_code             		titoloe_CODE,
       	v1.titusc_desc                  titoloe_DESC,
        v1.macroag_tipo_desc            macroag_TIPO_DESC,		
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
        COALESCE(tb4.importo,0)	        impegni
FROM  	  siac_rep_mis_pro_tit_mac_riga_anni v1
LEFT JOIN siac_rep_cap_ug tb ON ( v1.programma_id = tb.programma_id
                                  AND v1.macroag_id = tb.macroaggregato_id 
                                  AND v1.ente_proprietario_id = p_ente_prop_id
					              AND tb.utente = v1.utente
                                  AND v1.utente = user_table)	
LEFT JOIN  siac_rep_impegni tb4 ON tb4.elem_id = tb.elem_id           	
ORDER BY titoloe_CODE, macroag_CODE  
-- Parte valida se si considera la tabella siac_r_class progmacro FINE
LOOP

  /* verifico se il capitolo ha il flag RICORRENTE */
  IF classifBilRec.BIL_ELE_ID IS NOT NULL THEN
    ricorrente=0;
    flag_ricorrente := 'N';  
   
    SELECT r_bil_elem_class.elem_id
    INTO ricorrente
    FROM siac_t_class t_class,
         siac_d_class_tipo d_class_tipo,
         siac_r_bil_elem_class r_bil_elem_class
    WHERE d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
    AND   r_bil_elem_class.classif_id=t_class.classif_id
    AND   r_bil_elem_class.elem_id=classifBilRec.BIL_ELE_ID
    AND   d_class_tipo.classif_tipo_code='RICORRENTE_SPESA'
    AND   t_class.classif_code='3'
    AND   r_bil_elem_class.data_cancellazione IS NULL
    AND   d_class_tipo.data_cancellazione IS NULL
    AND   t_class.data_cancellazione IS NULL;
      
    IF ricorrente IS NULL OR ricorrente = 0 THEN
       flag_ricorrente = 'N';
    ELSE
      flag_ricorrente = 'S';
    END IF;
            
  END IF;

  titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
  titoloe_CODE := classifBilRec.titoloe_CODE;
  titoloe_DESC := classifBilRec.titoloe_DESC;
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
  impegni:=classifBilRec.impegni;

  IF flag_ricorrente='S' THEN
      impegni_non_ricorrenti=0;
  ELSE
      impegni_non_ricorrenti=impegni;
  END IF;

  return next;
  bil_anno='';
  titoloe_tipo_code='';
  titoloe_TIPO_DESC='';
  titoloe_CODE='';
  titoloe_DESC='';
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
  impegni=0;
  flag_ricorrente='';
  impegni_non_ricorrenti=0;

END LOOP;

----delete from siac_rep_tit_mac_riga 		where utente=user_table;
delete from siac_rep_mis_pro_tit_mac_riga_anni 		where utente=user_table;
delete from siac_rep_cap_ug 		where utente=user_table;
delete from siac_rep_impegni 		where utente=user_table;

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