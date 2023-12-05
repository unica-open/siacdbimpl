/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--- 18.03.2019 Sofia SIAC-6736 - inizio
drop VIEW if exists siac_v_dwh_vincoli_movgest;
CREATE OR REPLACE VIEW siac_v_dwh_vincoli_movgest
(
    ente_proprietario_id,
    bil_code,
    anno_bilancio,
    programma_code,
    programma_desc,
    tipo_da,
    anno_da,
    numero_da,
    tipo_a,
    anno_a,
    numero_a,
    importo_vincolo,
    tipo_avanzo_vincolo)
AS
SELECT bil.ente_proprietario_id,
       bil.bil_code,
       periodo.anno AS anno_bilancio,
       progetto.programma_code, progetto.programma_desc,
       movtipoda.movgest_tipo_code AS tipo_da,  -- accertamento
       movda.movgest_anno AS anno_da,
       movda.movgest_numero AS numero_da,
       movtipoa.movgest_tipo_code AS tipo_a,    -- impegno
       mova.movgest_anno AS anno_a,
       mova.movgest_numero AS numero_a,
       a.movgest_ts_importo AS importo_vincolo,
       dat.avav_tipo_code AS tipo_avanzo_vincolo
FROM siac_r_movgest_ts a
     JOIN siac_t_movgest_ts movtsa ON a.movgest_ts_b_id = movtsa.movgest_ts_id -- impegno
     JOIN siac_t_movgest mova ON mova.movgest_id = movtsa.movgest_id
     JOIN siac_d_movgest_tipo movtipoa ON movtipoa.movgest_tipo_id = mova.movgest_tipo_id
     JOIN siac_t_bil bil ON bil.bil_id = mova.bil_id
     JOIN siac_t_periodo periodo ON bil.periodo_id = periodo.periodo_id
     LEFT JOIN siac_t_movgest_ts movtsda ON  -- accertamento
               a.movgest_ts_a_id = movtsda.movgest_ts_id AND movtsda.data_cancellazione IS NULL
     LEFT JOIN siac_t_movgest movda ON
               movda.movgest_id = movtsda.movgest_id AND movda.data_cancellazione IS NULL
     LEFT JOIN siac_d_movgest_tipo movtipoda ON movtipoda.movgest_tipo_id = movda.movgest_tipo_id AND movtipoda.data_cancellazione IS NULL
     LEFT JOIN siac_r_movgest_ts_programma rprogramma ON
               rprogramma.movgest_ts_id = movtsa.movgest_ts_id AND rprogramma.data_cancellazione IS NULL
     LEFT JOIN siac_t_programma progetto ON
               progetto.programma_id = rprogramma.programma_id AND progetto.data_cancellazione IS NULL
     LEFT JOIN siac_t_avanzovincolo ta ON ta.avav_id = a.avav_id AND ta.data_cancellazione IS NULL
     LEFT JOIN siac_d_avanzovincolo_tipo dat ON dat.avav_tipo_id =   ta.avav_tipo_id AND dat.data_cancellazione IS NULL
WHERE a.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   movtsa.data_cancellazione IS NULL
AND   movtsa.validita_fine IS NULL
AND   mova.data_cancellazione IS NULL
AND   mova.validita_fine IS NULL
AND   movtipoa.data_cancellazione IS NULL
AND   movtipoa.validita_fine IS NULL
AND   bil.data_cancellazione IS NULL
AND   periodo.data_cancellazione IS NULL
--UNION -- 28.09.2018 Sofia Jira SIAC-6427 - inverto da, a per avere casi di accertamento (a) senza impegno (da)
UNION ALL -- 18.03.2019 Sofia Jira SIAC-6736
SELECT bil.ente_proprietario_id,
       bil.bil_code, periodo.anno AS anno_bilancio,
       progetto.programma_code, progetto.programma_desc,
       movtipoda.movgest_tipo_code AS tipo_da, -- impegno
       movda.movgest_anno AS anno_da,
       movda.movgest_numero AS numero_da,
       movtipoa.movgest_tipo_code AS tipo_a, -- accertamento
       mova.movgest_anno AS anno_a,
       mova.movgest_numero AS numero_a,
       a.movgest_ts_importo AS importo_vincolo,
       dat.avav_tipo_code AS tipo_avanzo_vincolo
FROM siac_r_movgest_ts a
     JOIN siac_t_movgest_ts movtsa ON a.movgest_ts_a_id = movtsa.movgest_ts_id -- accertamento
     JOIN siac_t_movgest mova ON mova.movgest_id = movtsa.movgest_id
     JOIN siac_d_movgest_tipo movtipoa ON movtipoa.movgest_tipo_id = mova.movgest_tipo_id
     JOIN siac_t_bil bil ON bil.bil_id = mova.bil_id
     JOIN siac_t_periodo periodo ON bil.periodo_id = periodo.periodo_id
     LEFT JOIN siac_t_movgest_ts movtsda ON  -- impegno
               a.movgest_ts_b_id = movtsda.movgest_ts_id AND movtsda.data_cancellazione IS NULL
     LEFT JOIN siac_t_movgest movda ON
               movda.movgest_id = movtsda.movgest_id AND movda.data_cancellazione IS NULL
     LEFT JOIN siac_d_movgest_tipo movtipoda ON
               movtipoda.movgest_tipo_id = movda.movgest_tipo_id AND movtipoda.data_cancellazione IS NULL
     LEFT JOIN siac_r_movgest_ts_programma rprogramma ON
               rprogramma.movgest_ts_id = movtsa.movgest_ts_id AND rprogramma.data_cancellazione IS NULL
     LEFT JOIN siac_t_programma progetto ON
               progetto.programma_id = rprogramma.programma_id AND progetto.data_cancellazione IS NULL
     LEFT JOIN siac_t_avanzovincolo ta ON
               ta.avav_id = a.avav_id AND ta.data_cancellazione IS NULL
     LEFT JOIN siac_d_avanzovincolo_tipo dat ON
               dat.avav_tipo_id = ta.avav_tipo_id AND dat.data_cancellazione IS NULL
WHERE a.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   movtsa.data_cancellazione IS NULL
AND   movtsa.validita_fine IS NULL
AND   mova.data_cancellazione IS NULL
AND   mova.validita_fine IS NULL
AND   movtipoa.data_cancellazione IS NULL
AND   movtipoa.validita_fine IS NULL
AND   bil.data_cancellazione IS NULL
AND   periodo.data_cancellazione IS NULL;

--- 18.03.2019 Sofia SIAC-6736 - fine 

-- SIAC-6623 Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR147_Allegato_B_Fondo_Pluriennale_vincolato_Rend"(p_ente_prop_id integer, p_anno varchar);
DROP FUNCTION if exists siac."BILR221_Allegato_B_Fondo_Pluriennale_vincolato_Rend_capitolo"(p_ente_prop_id integer, p_anno varchar);
DROP FUNCTION if exists siac."BILR222_Allegato_B_Fondo_Pluri_vinc_Rend_capitolo_stanz_agg"(p_ente_prop_id integer, p_anno varchar);
DROP FUNCTION if exists siac."BILR011_Allegato_B_Fondo_Pluriennale_vincolato"(p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar);
DROP FUNCTION if exists siac."BILR011_allegato_fpv_previsione_con_dati_gestione"(p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar);
DROP FUNCTION if exists siac."fnc_lancio_BILR011_anni_precedenti_gestione"(p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar);
DROP FUNCTION if exists siac."BILR223_Allegato_B_Fondo_Pluriennale_vincolato_capitolo"(p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar);
DROP FUNCTION if exists siac."BILR223_allegato_fpv_previsione_dati_gestione_capitolo"(p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar);
DROP FUNCTION if exists siac."fnc_lancio_BILR223_anni_precedenti_gestione_capitolo"(p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar);

CREATE OR REPLACE FUNCTION siac."BILR147_Allegato_B_Fondo_Pluriennale_vincolato_Rend" (
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
  fondo_plur_anno_prec_a numeric,
  spese_impe_anni_prec_b numeric,
  quota_fond_plur_anni_prec_c numeric,
  spese_da_impeg_anno1_d numeric,
  spese_da_impeg_anno2_e numeric,
  spese_da_impeg_anni_succ_f numeric,
  riacc_colonna_x numeric,
  riacc_colonna_y numeric,
  fondo_plur_anno_g numeric
) AS
$body$
DECLARE

classifBilRec record;
var_fondo_plur_anno_prec_a numeric;
var_spese_impe_anni_prec_b numeric;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
annoPrec varchar;
annoProspInt integer;
annoBilInt integer;
conflagfpv boolean ;
a_dacapfpv boolean ;
h_dacapfpv boolean ;
flagretrocomp boolean ;

h_count integer :=0;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';


BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
annoPrec:= ((p_anno::INTEGER)-1)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione


annoBilInt=p_anno::INTEGER;

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';

var_fondo_plur_anno_prec_a=0;
var_spese_impe_anni_prec_b=0;
quota_fond_plur_anni_prec_c=0;
spese_da_impeg_anno1_d=0;
spese_da_impeg_anno2_e=0;
spese_da_impeg_anni_succ_f=0;
fondo_plur_anno_g=0;


select fnc_siac_random_user()
into	user_table;

-- 07/09/2016: sostituita la query di caricamento struttura del bilancio
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
    /* 07/09/2016: start filtro per mis-prog-macro*/
  , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 07/09/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id
 /* ANNA 31-05 inizio */
 and missione.missione_code::integer <= 19
 /* ANNA 31-05 fine */
 ;
 
var_fondo_plur_anno_prec_a:=0;
var_spese_impe_anni_prec_b=0;
quota_fond_plur_anni_prec_c=0;
spese_da_impeg_anno1_d=0;
spese_da_impeg_anno2_e=0;  
spese_da_impeg_anni_succ_f=0;
        
        
return query           
with tbclass as (select 	
v1.missione_tipo_desc			missione_tipo_desc,
		v1.missione_code				missione_code,
		v1.missione_desc				missione_desc,
		v1.programma_tipo_desc			programma_tipo_desc,
		v1.programma_code				programma_code,
		v1.programma_desc				programma_desc,
        v1.programma_id					programma_id,
        v1.ente_proprietario_id,
        v1.utente
from   
	siac_rep_mis_pro_tit_mac_riga_anni v1
    where utente=user_table
            group by v1.missione_tipo_desc, v1.missione_code, v1.missione_desc, 
            	v1.programma_tipo_desc, v1.programma_code, v1.programma_desc,
                v1.programma_id,
                v1.ente_proprietario_id, utente 
            order by missione_code,programma_code
           ),
tbfpvprec as (
select  
  importi.repimp_desc programma_code,
 sum(coalesce(importi.repimp_importo,0)) spese_fpv_anni_prec     
from 	siac_t_report					report,
		siac_t_report_importi 			importi,
		siac_r_report_importi 			r_report_importi,
		siac_t_bil 						bilancio,
	 	siac_t_periodo 					anno_eserc,
        siac_t_periodo 					anno_comp
where 	report.rep_codice				=	'BILR147'   				and
      	report.ente_proprietario_id		=	p_ente_prop_id				and
		anno_eserc.anno					=	p_anno 						and
      	bilancio.periodo_id				=	anno_eserc.periodo_id 		and
      	importi.bil_id					=	bilancio.bil_id 			and
        r_report_importi.rep_id			=	report.rep_id				and
        r_report_importi.repimp_id		=	importi.repimp_id			and
        importi.periodo_id 				=	anno_comp.periodo_id		and
        importi.ente_proprietario_id	=	p_ente_prop_id				and
        bilancio.ente_proprietario_id	=	p_ente_prop_id				and
        anno_eserc.ente_proprietario_id	=	p_ente_prop_id				and
		anno_comp.ente_proprietario_id	=	p_ente_prop_id
        and report.data_cancellazione IS NULL
        and importi.data_cancellazione IS NULL
        and r_report_importi.data_cancellazione IS NULL
        and anno_eserc.data_cancellazione IS NULL
        and anno_comp.data_cancellazione IS NULL
        group by importi.repimp_desc
        
        /*
        select a.programma_code as programma_code, 
        sum(a.importo_competenza) as spese_fpv_anni_prec from siac_t_cap_u_importi_anno_prec a
        where a.anno::INTEGER=annoBilInt-1
        and a.ente_proprietario_id=p_ente_prop_id
        and a.elem_cat_code like 'FPV%'
        group by a.programma_code*/
        ),
/*
	22/02/2019: SIAC-6623.
    	E' stato richiesto di estrarre gli importi FPV dell'anno precedente dai capitoli.
        Se per un codice PROGRAMMA non esiste un valore allora si prende il valore
        eventualmente caricato sulle variabili (tbfpvprec). 
*/        
 fpv_anno_prec_da_capitoli as (               
select 	 t_class.classif_code programma_code,
	sum(capitolo_importi.elem_det_importo) importo_fpv_anno_prec
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_t_bil					t_bil,
            siac_t_periodo				t_periodo_bil,
            siac_d_bil_elem_tipo 		tipo_elemento,
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_r_bil_elem_class r_bil_elem_class,
            siac_t_class t_class, 
            siac_d_class_tipo d_class_tipo
where capitolo.elem_id = capitolo_importi.elem_id 
	and	capitolo.bil_id = t_bil.bil_id
	and t_periodo_bil.periodo_id =t_bil.periodo_id	
	and	capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id
	and	capitolo_importi.elem_det_tipo_id = capitolo_imp_tipo.elem_det_tipo_id 		
	and	capitolo_imp_periodo.periodo_id = capitolo_importi.periodo_id 
	and	capitolo.elem_id = r_capitolo_stato.elem_id			
	and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id
	and	capitolo.elem_id = r_cat_capitolo.elem_id				
	and	r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id	
    and d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
    and capitolo.elem_id = r_bil_elem_class.elem_id
    and r_bil_elem_class.classif_id = t_class.classif_id
	and capitolo_importi.ente_proprietario_id = p_ente_prop_id 					
	and	tipo_elemento.elem_tipo_code = 'CAP-UG' -- prendere i capitoli di GESTIONE
	and	t_periodo_bil.anno = annoPrec	--anno bilancio -1	
	and	capitolo_imp_periodo.anno = annoPrec	--anno bilancio -1		  	
	and	stato_capitolo.elem_stato_code = 'VA'								
	and	cat_del_capitolo.elem_cat_code in ('FPV','FPVC')
	and capitolo_imp_tipo.elem_det_tipo_code = 'STA'	
    and d_class_tipo.classif_tipo_code='PROGRAMMA'			
	and	capitolo_importi.data_cancellazione 		is null
	and	capitolo_imp_tipo.data_cancellazione 		is null
	and	capitolo_imp_periodo.data_cancellazione 	is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
	and	stato_capitolo.data_cancellazione 			is null 
	and	r_capitolo_stato.data_cancellazione 		is null
	and cat_del_capitolo.data_cancellazione 		is null
	and	r_cat_capitolo.data_cancellazione 			is null
	and t_bil.data_cancellazione 					is null
	and t_periodo_bil.data_cancellazione 			is null
    and r_bil_elem_class.data_cancellazione 		is null
    and t_class.data_cancellazione 					is null
    and d_class_tipo.data_cancellazione 		is null        
GROUP BY t_class.classif_code ),
tbimpaprec as (
select 
--sum(coalesce(f.movgest_ts_det_importo,0)) spese_impe_anni_prec
--Spese impegnate negli esercizi precedenti e imputate all'esercizio N e coperte dal fondo pluriennale vincolato
-- si prendono le quote di impegni di competenza   
-- gli impegni considerati devono inoltre essere vincolati a fondo
-- l'importo considerato e' quello attuale
sum(coalesce( aa.movgest_ts_importo ,0)) spese_impe_anni_prec
, o.classif_code programma_code
          from siac_t_movgest a,  
          siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
          siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
          siac_r_movgest_ts_stato l, siac_d_movgest_stato m
          , siac_r_bil_elem_class n,
          siac_t_class o, siac_d_class_tipo p, 
          siac_r_movgest_ts_atto_amm q,
          siac_t_atto_amm r,
          --- 
           siac_d_movgest_tipo d_mov_tipo,
           siac_r_movgest_ts aa, 
           siac_t_avanzovincolo v, 
           siac_d_avanzovincolo_tipo vt
          where 
          a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and a.movgest_id = e.movgest_id  
          and e.movgest_ts_id = f.movgest_ts_id
          and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
          and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
          and l.movgest_ts_id=e.movgest_ts_id
          and l.movgest_stato_id=m.movgest_stato_id
          and n.classif_id = o.classif_id
          and o.classif_tipo_id=p.classif_tipo_id
          and n.elem_id = i.elem_id
          and q.movgest_ts_id=e.movgest_ts_id
          and q.attoamm_id = r.attoamm_id
          and a.bil_id = b.bil_id
          and h.elem_id=i.elem_id
          and a.ente_proprietario_id= p_ente_prop_id      
          and c.anno = p_anno -- anno bilancio p_anno
          and p.classif_tipo_code='PROGRAMMA'
--          and o.classif_code = classifBilRec.programma_code
          and a.movgest_anno = annoBilInt -- annoBilInt
          and g.movgest_ts_det_tipo_code='I'
          and m.movgest_stato_code in ('D', 'N')
          and d_mov_tipo.movgest_tipo_code='I' --Impegni      
          --and r.attoamm_anno::integer < annoBilInt    
          --and r.attoamm_anno < p_anno --p_anno   
          and e.movgest_ts_id_padre is NULL    
          and i.movgest_id=a.movgest_id 
          and i.data_cancellazione is null
          and i.validita_fine is NULL          
          and l.data_cancellazione is null
          and l.validita_fine is null
          and d_mov_tipo.data_cancellazione is null
          and d_mov_tipo.validita_fine is null              
          and n.data_cancellazione is null
          and n.validita_fine is null
          and q.data_cancellazione is null
          and q.validita_fine is null
          and f.data_cancellazione is null
          and f.validita_fine is null
          ---
          and aa.avav_id=v.avav_id     
          and v.avav_tipo_id=vt.avav_tipo_id 
          and vt.avav_tipo_code like'FPV%' 
                --and aa.ente_proprietario_id=p_ente_prop_id
          and e.movgest_ts_id = aa.movgest_ts_b_id 
          and aa.data_cancellazione is null
          and aa.validita_fine is null
          /*and exists (select 
          		1 
                from siac_r_movgest_ts aa, 
            	siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt
			where aa.avav_id=v.avav_id     
                and v.avav_tipo_id=vt.avav_tipo_id 
                and vt.avav_tipo_code like'FPV%' 
                --and aa.ente_proprietario_id=p_ente_prop_id
                and e.movgest_ts_id = aa.movgest_ts_b_id 
                and aa.data_cancellazione is null
                and aa.validita_fine is null ) */ 
          group by o.classif_code
          ),
tbriaccx as 
--Riaccertamento degli impegni di cui alla lettera b) effettuata nel corso dell'eserczio N (cd. economie di impegno)
--riduzioni su impegni di competenza con anno atto minore dell'anno di bilancio 
--e coperti anche solo parzialmente da fondo                 
                (
                select sum(COALESCE(b.movgest_ts_det_importo,0)*-1) riacc_colonna_x,
                 s.classif_code programma_code
      from siac_r_modifica_stato a, siac_t_movgest_ts_det_mod b,
      siac_t_movgest_ts c, siac_d_modifica_stato d,
      siac_t_movgest e, siac_d_movgest_tipo f, siac_t_bil g,
      siac_t_periodo h, siac_t_modifica i, siac_d_modifica_tipo l,
      siac_d_modifica_stato m, 
      siac_t_bil_elem p, siac_r_movgest_bil_elem q,
      siac_r_bil_elem_class r, siac_t_class s, siac_d_class_tipo t,
      siac_r_movgest_ts_atto_amm qa,
          siac_t_atto_amm ra ,
      siac_r_movgest_ts_stato sti, siac_d_movgest_stato tipstimp    
      where b.mod_stato_r_id=a.mod_stato_r_id
      and b.movgest_ts_id = c.movgest_ts_id
      and e.movgest_tipo_id=f.movgest_tipo_id
      and d.mod_stato_id=a.mod_stato_id
      and e.movgest_id=c.movgest_id
      and g.bil_id=e.bil_id
      and i.mod_id=a.mod_id
      and i.mod_tipo_id=l.mod_tipo_id
      and m.mod_stato_id=a.mod_stato_id
      and g.periodo_id=h.periodo_id
      and qa.movgest_ts_id=c.movgest_ts_id
      and qa.attoamm_id = ra.attoamm_id
      --and ra.attoamm_anno < p_anno
       and e.movgest_anno = annoBilInt 
      --and c.movgest_ts_id=n.movgest_ts_id
      --and o.programma_id=n.programma_id
      and p.elem_id=q.elem_id
      and q.movgest_id=e.movgest_id
      and r.elem_id=p.elem_id
      and r.classif_id=s.classif_id
      and s.classif_tipo_id=t.classif_tipo_id
      and a.ente_proprietario_id=p_ente_prop_id
      and d.mod_stato_code='V'
      and f.movgest_tipo_code='I'
      --and e.movgest_anno = annoBilInt
      and h.anno=p_anno
      and m.mod_stato_code='V'
      --and l.mod_tipo_code in  ('ECON' , 'ECONB')
      and 
      ( l.mod_tipo_code like  'ECON%'
         or l.mod_tipo_desc like  'ROR%'
      )
      and l.mod_tipo_code <> 'REIMP'
      and t.classif_tipo_code='PROGRAMMA'
      --and s.classif_code = classifBilRec.programma_code
      --and b.movgest_ts_det_importo < 0
      and sti.movgest_ts_id = c.movgest_ts_id
      and sti.movgest_stato_id = tipstimp.movgest_stato_id
      and tipstimp.movgest_stato_code in ('D', 'N')
      and sti.data_cancellazione is NULL
      and sti.validita_fine is null
      and c.movgest_ts_id_padre is null
      and a.data_cancellazione is null
      and a.validita_fine is null
      and b.data_cancellazione is null
      and b.validita_fine is null
      and c.data_cancellazione is null
      and c.validita_fine is null
      and d.data_cancellazione is null
      and d.validita_fine is null
      and e.data_cancellazione is null
      and e.validita_fine is null
      and f.data_cancellazione is null
      and f.validita_fine is null
      and g.data_cancellazione is null
      and g.validita_fine is null
      and h.data_cancellazione is null
      and h.validita_fine is null
      and i.data_cancellazione is null
      and i.validita_fine is null
      and l.data_cancellazione is null
      and l.validita_fine is null
      and m.data_cancellazione is null
      and m.validita_fine is null
      and p.data_cancellazione is null
      and p.validita_fine is null
      and q.data_cancellazione is null
      and q.validita_fine is null
      and r.data_cancellazione is null
      and r.validita_fine is null
      and s.data_cancellazione is null
      and s.validita_fine is null
      and t.data_cancellazione is null
      and t.validita_fine is null
      and qa.data_cancellazione is null
      and qa.validita_fine is null
      and exists (select 
          		1 
                from siac_r_movgest_ts aa, 
            	siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt
			where aa.avav_id=v.avav_id     
                and v.avav_tipo_id=vt.avav_tipo_id 
                and vt.avav_tipo_code like'FPV%' 
                --and aa.ente_proprietario_id=p_ente_prop_id
                and c.movgest_ts_id = aa.movgest_ts_b_id 
                and aa.data_cancellazione is null
                and aa.validita_fine is null 
               )
      group by s.classif_code
      ),
tbriaccy as 
--Riaccertamento degli impegni di cui alla lettera b) effettuata nel corso dell'eserczio N (cd. economie di impegno) su impegni pluriennali finanziati dal FPV e imputati agli esercizi successivi  a N
--riduzioni su impegni di competenza con anno atto minore dell'anno di bilancio 
--e coperti anche solo parzialmente da fondo                 
( select sum(COALESCE(b.movgest_ts_det_importo,0)*-1) riacc_colonna_y,
s.classif_code programma_code
      from siac_r_modifica_stato a, siac_t_movgest_ts_det_mod b,
      siac_t_movgest_ts c, siac_d_modifica_stato d,
      siac_t_movgest e, siac_d_movgest_tipo f, siac_t_bil g,
      siac_t_periodo h, siac_t_modifica i, siac_d_modifica_tipo l,
      siac_d_modifica_stato m, 
      siac_t_bil_elem p, siac_r_movgest_bil_elem q,
      siac_r_bil_elem_class r, siac_t_class s, siac_d_class_tipo t,
      siac_r_movgest_ts_atto_amm qa,
          siac_t_atto_amm ra ,
      siac_r_movgest_ts_stato sti, siac_d_movgest_stato tipstimp    
      where b.mod_stato_r_id=a.mod_stato_r_id
      and b.movgest_ts_id = c.movgest_ts_id
      and e.movgest_tipo_id=f.movgest_tipo_id
      and d.mod_stato_id=a.mod_stato_id
      and e.movgest_id=c.movgest_id
      and g.bil_id=e.bil_id
      and i.mod_id=a.mod_id
      and i.mod_tipo_id=l.mod_tipo_id
      and m.mod_stato_id=a.mod_stato_id
      and g.periodo_id=h.periodo_id
      and qa.movgest_ts_id=c.movgest_ts_id
      and qa.attoamm_id = ra.attoamm_id
      --and ra.attoamm_anno < p_anno
       and e.movgest_anno > annoBilInt 
      and p.elem_id=q.elem_id
      and q.movgest_id=e.movgest_id
      and r.elem_id=p.elem_id
      and r.classif_id=s.classif_id
      and s.classif_tipo_id=t.classif_tipo_id
      and a.ente_proprietario_id=p_ente_prop_id
      and d.mod_stato_code='V'
      and f.movgest_tipo_code='I'
      and h.anno=p_anno
      and m.mod_stato_code='V'
      --and l.mod_tipo_code in  ('ECON' , 'ECONB')
      and 
      ( l.mod_tipo_code like  'ECON%'
         or l.mod_tipo_desc like  'ROR%'
      )
      and l.mod_tipo_code <> 'REIMP'
      and t.classif_tipo_code='PROGRAMMA'
      --and b.movgest_ts_det_importo < 0
      and sti.movgest_ts_id = c.movgest_ts_id
      and sti.movgest_stato_id = tipstimp.movgest_stato_id
      and tipstimp.movgest_stato_code in ('D', 'N')
      and sti.data_cancellazione is NULL
      and sti.validita_fine is null
      and c.movgest_ts_id_padre is null
      and a.data_cancellazione is null
      and a.validita_fine is null
      and b.data_cancellazione is null
      and b.validita_fine is null
      and c.data_cancellazione is null
      and c.validita_fine is null
      and d.data_cancellazione is null
      and d.validita_fine is null
      and e.data_cancellazione is null
      and e.validita_fine is null
      and f.data_cancellazione is null
      and f.validita_fine is null
      and g.data_cancellazione is null
      and g.validita_fine is null
      and h.data_cancellazione is null
      and h.validita_fine is null
      and i.data_cancellazione is null
      and i.validita_fine is null
      and l.data_cancellazione is null
      and l.validita_fine is null
      and m.data_cancellazione is null
      and m.validita_fine is null
      and p.data_cancellazione is null
      and p.validita_fine is null
      and q.data_cancellazione is null
      and q.validita_fine is null
      and r.data_cancellazione is null
      and r.validita_fine is null
      and s.data_cancellazione is null
      and s.validita_fine is null
      and t.data_cancellazione is null
      and t.validita_fine is null
      and qa.data_cancellazione is null
      and qa.validita_fine is null
      and exists (select 
          		1 
                from siac_r_movgest_ts aa, 
            	siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt
			where aa.avav_id=v.avav_id     
                and v.avav_tipo_id=vt.avav_tipo_id 
                and vt.avav_tipo_code like'FPV%' 
                --and aa.ente_proprietario_id=p_ente_prop_id
                and c.movgest_ts_id = aa.movgest_ts_b_id 
                and aa.data_cancellazione is null
                and aa.validita_fine is null )
      group by s.classif_code
      ),
      tbimpanno1 as 
      -- Spese impegnate nell'esercizio N con imputazione all'esercizio N+1 e 
      -- coperte dal fondo pluriennale vincolato
      -- impegni anno + 1 con atto nell'anno legati ad accertamenti 
      -- di competenza oppure ad avanzo
      (
      select sum(x.spese_da_impeg_anno1_d) as spese_da_impeg_anno1_d , x.programma_code as programma_code from (
               (
              select sum(COALESCE(aa.movgest_ts_importo,0))
                      as spese_da_impeg_anno1_d, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        siac_r_movgest_ts_atto_amm q,
                        siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                         siac_r_movgest_ts aa, siac_t_movgest_ts acc_ts,
                         siac_t_movgest acc,
                         siac_r_movgest_ts_stato rstacc,
                         siac_d_movgest_stato dstacc
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        and q.movgest_ts_id=e.movgest_ts_id
                        and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  p_anno 
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno = annoBilInt + 1
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        and q.data_cancellazione is null
                        and q.validita_fine is null
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                        and aa.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_ts_id_padre is null
                        and acc_ts.movgest_id = acc.movgest_id
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null
                        and acc.movgest_anno = annoBilInt
                        and rstacc.movgest_ts_id=acc_ts.movgest_ts_id
                        and rstacc.validita_fine is null
                        and rstacc.data_cancellazione is null
                        and rstacc.movgest_stato_id=dstacc.movgest_stato_id
                        and dstacc.movgest_stato_code in ('D', 'N')
                        /*and ( exists (select 
                              1 
                              from siac_r_movgest_ts aa, siac_t_movgest_ts acc_ts,
                              siac_t_movgest acc
                          where 
                               e.movgest_ts_id = aa.movgest_ts_b_id 
                              and aa.data_cancellazione is null
                              and aa.validita_fine is null 
                              and aa.movgest_ts_a_id = acc_ts.movgest_ts_id
                              and acc_ts.movgest_ts_id_padre is null
                              and acc_ts.movgest_id = acc.movgest_id
                              and acc.validita_fine is null
                              and acc.data_cancellazione is null
                              and acc_ts.validita_fine is null
                              and acc_ts.data_cancellazione is null
                              and acc.movgest_anno = 2017 --annoBilInt 
                              ) 
                        or exists 
                        (select 
                              1 
                              from siac_r_movgest_ts aa, 
                              siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt
                          where aa.avav_id=v.avav_id     
                              and v.avav_tipo_id=vt.avav_tipo_id 
                              and vt.avav_tipo_code = 'AAM' 
                              and e.movgest_ts_id = aa.movgest_ts_b_id 
                              and aa.data_cancellazione is null
                              and aa.validita_fine is null )  
                          )*/
                           group by o.classif_code)
              union(
              select sum(COALESCE(aa.movgest_ts_importo,0)) AS
                      spese_da_impeg_anno1_d, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        siac_r_movgest_ts_atto_amm q,
                        siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                        siac_r_movgest_ts aa, 
                        siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt 
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        and q.movgest_ts_id=e.movgest_ts_id
                        and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  p_anno 
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno = annoBilInt + 1
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        and q.data_cancellazione is null
                        and q.validita_fine is null
                        and aa.avav_id=v.avav_id     
                        and v.avav_tipo_id=vt.avav_tipo_id 
                        and vt.avav_tipo_code = 'AAM' 
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                           group by o.classif_code
              )--- Impegni da riaccertamento - reimputazione nel bilancio successivo 
              union(
              select sum(COALESCE(aa.movgest_ts_importo,0)) AS
                      spese_da_impeg_anno1_d, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        --siac_r_movgest_ts_atto_amm q,
                        --siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                        siac_r_movgest_ts aa, 
                        siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt 
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        --and q.movgest_ts_id=e.movgest_ts_id
                        --and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  (annoBilInt + 1)::varchar  
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno = annoBilInt + 1
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code <> 'A'
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        --and q.data_cancellazione is null
                        --and q.validita_fine is null
                        and aa.avav_id=v.avav_id     
                        and v.avav_tipo_id=vt.avav_tipo_id 
                        and vt.avav_tipo_code like'FPV%' 
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                        and exists (
                        	select 1
                            from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
                                 fase_bil_t_reimputazione fasereimp, siac_t_bil bilprec, siac_t_periodo pprec
                            where tipo.ente_proprietario_id= a.ente_proprietario_id 
                            and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP'
                            and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
                            and   fase.fase_bil_elab_esito='OK'
                            and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
                            and   fasereimp.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
                            and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
                            and   fasereimp.bil_id=bilprec.bil_id
                            and   bilprec.periodo_id = pprec.periodo_id
                            and   pprec.anno=p_anno
                            and   fasereimp.movgestnew_id = a.movgest_id
                            and   fase.data_cancellazione is null
                            and   fase.validita_fine is null
                            and   tipo.data_cancellazione is null
                            and   tipo.validita_fine is null
                        )
                        and not exists 
                        (
                           select 
                             1
                             from fase_bil_t_reimputazione_vincoli vreimp, siac_r_movgest_ts rold,
                             siac_r_movgest_ts rnew, siac_t_avanzovincolo avold, siac_d_avanzovincolo_tipo davold
                             where 
                             vreimp.movgest_ts_r_new_id =  aa.movgest_ts_r_id 
                             and vreimp.movgest_ts_r_id=rold.movgest_ts_r_id
                             and vreimp.movgest_ts_r_new_id = rnew.movgest_ts_r_id
                             and avold.avav_id=rold.avav_id
                             and avold.avav_tipo_id = davold.avav_tipo_id
                             and davold.avav_tipo_code like '%FPV%'
                        )
                        group by o.classif_code
              )    
              ) as x
                group by x.programma_code 
            ),
tbimpanno2 as (
      select sum(x.spese_da_impeg_anno2_e) as spese_da_impeg_anno2_e , x.programma_code as programma_code from (
               (
              select sum(COALESCE(aa.movgest_ts_importo,0))
                      as spese_da_impeg_anno2_e, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        siac_r_movgest_ts_atto_amm q,
                        siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                         siac_r_movgest_ts aa, siac_t_movgest_ts acc_ts,
                         siac_t_movgest acc,
                         siac_r_movgest_ts_stato rstacc,
                         siac_d_movgest_stato dstacc
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        and q.movgest_ts_id=e.movgest_ts_id
                        and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  p_anno 
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno = annoBilInt + 2
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        and q.data_cancellazione is null
                        and q.validita_fine is null
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                        and aa.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_ts_id_padre is null
                        and acc_ts.movgest_id = acc.movgest_id
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null
                        and acc.movgest_anno = annoBilInt
                        and rstacc.movgest_ts_id=acc_ts.movgest_ts_id
                        and rstacc.validita_fine is null
                        and rstacc.data_cancellazione is null
                        and rstacc.movgest_stato_id=dstacc.movgest_stato_id
                        and dstacc.movgest_stato_code in ('D', 'N')
                        /*and ( exists (select 
                              1 
                              from siac_r_movgest_ts aa, siac_t_movgest_ts acc_ts,
                              siac_t_movgest acc
                          where 
                               e.movgest_ts_id = aa.movgest_ts_b_id 
                              and aa.data_cancellazione is null
                              and aa.validita_fine is null 
                              and aa.movgest_ts_a_id = acc_ts.movgest_ts_id
                              and acc_ts.movgest_ts_id_padre is null
                              and acc_ts.movgest_id = acc.movgest_id
                              and acc.validita_fine is null
                              and acc.data_cancellazione is null
                              and acc_ts.validita_fine is null
                              and acc_ts.data_cancellazione is null
                              and acc.movgest_anno = 2017 --annoBilInt 
                              ) 
                        or exists 
                        (select 
                              1 
                              from siac_r_movgest_ts aa, 
                              siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt
                          where aa.avav_id=v.avav_id     
                              and v.avav_tipo_id=vt.avav_tipo_id 
                              and vt.avav_tipo_code = 'AAM' 
                              and e.movgest_ts_id = aa.movgest_ts_b_id 
                              and aa.data_cancellazione is null
                              and aa.validita_fine is null )  
                          )*/
                           group by o.classif_code)
              union(
              select sum(COALESCE(aa.movgest_ts_importo,0)) AS
                      spese_da_impeg_anno2_e, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        siac_r_movgest_ts_atto_amm q,
                        siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                        siac_r_movgest_ts aa, 
                        siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt 
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        and q.movgest_ts_id=e.movgest_ts_id
                        and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  p_anno 
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno = annoBilInt + 2
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        and q.data_cancellazione is null
                        and q.validita_fine is null
                        and aa.avav_id=v.avav_id     
                        and v.avav_tipo_id=vt.avav_tipo_id 
                        and vt.avav_tipo_code = 'AAM' 
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                           group by o.classif_code
              )  
               union(
              select sum(COALESCE(aa.movgest_ts_importo,0)) AS
                      spese_da_impeg_anno1_d, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        --siac_r_movgest_ts_atto_amm q,
              			--siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                        siac_r_movgest_ts aa, 
                        siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt 
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        --and q.movgest_ts_id=e.movgest_ts_id
                        --and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  (annoBilInt + 1)::varchar  
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno = annoBilInt + 2
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code <> 'A'
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        --and q.data_cancellazione is null
                        --and q.validita_fine is null
                        and aa.avav_id=v.avav_id     
                        and v.avav_tipo_id=vt.avav_tipo_id 
                        and vt.avav_tipo_code like'FPV%' 
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                        and exists (
                        	select 1
                            from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
                                 fase_bil_t_reimputazione fasereimp, siac_t_bil bilprec, siac_t_periodo pprec
                            where tipo.ente_proprietario_id= a.ente_proprietario_id 
                            and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP'
                            and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
                            and   fase.fase_bil_elab_esito='OK'
                            and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
                            and   fasereimp.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
                            and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
                            and   fasereimp.bil_id=bilprec.bil_id
                            and   bilprec.periodo_id = pprec.periodo_id
                            and   pprec.anno=p_anno
                            and   fasereimp.movgestnew_id = a.movgest_id
                            and   fase.data_cancellazione is null
                            and   fase.validita_fine is null
                            and   tipo.data_cancellazione is null
                            and   tipo.validita_fine is null
                        )
                        and not exists 
                        (
                           select 
                             1
                             from fase_bil_t_reimputazione_vincoli vreimp, siac_r_movgest_ts rold,
                             siac_r_movgest_ts rnew, siac_t_avanzovincolo avold, siac_d_avanzovincolo_tipo davold
                             where 
                             vreimp.movgest_ts_r_new_id =  aa.movgest_ts_r_id 
                             and vreimp.movgest_ts_r_id=rold.movgest_ts_r_id
                             and vreimp.movgest_ts_r_new_id = rnew.movgest_ts_r_id
                             and avold.avav_id=rold.avav_id
                             and avold.avav_tipo_id = davold.avav_tipo_id
                             and davold.avav_tipo_code like '%FPV%'
                        )
                        group by o.classif_code
              ) 
              ) as x
                group by x.programma_code 
                ),
tbimpannisuc as (
      select sum(x.spese_da_impeg_anni_succ_f) as spese_da_impeg_anni_succ_f , x.programma_code as programma_code from (
               (
              select sum(COALESCE(aa.movgest_ts_importo,0))
                      as spese_da_impeg_anni_succ_f, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        siac_r_movgest_ts_atto_amm q,
                        siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                         siac_r_movgest_ts aa, siac_t_movgest_ts acc_ts,
                         siac_t_movgest acc,
                         siac_r_movgest_ts_stato rstacc,
                         siac_d_movgest_stato dstacc
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        and q.movgest_ts_id=e.movgest_ts_id
                        and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  p_anno 
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno > annoBilInt + 2
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        and q.data_cancellazione is null
                        and q.validita_fine is null
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                        and aa.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_ts_id_padre is null
                        and acc_ts.movgest_id = acc.movgest_id
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null
                        and acc.movgest_anno = annoBilInt
                        and rstacc.movgest_ts_id=acc_ts.movgest_ts_id
                        and rstacc.validita_fine is null
                        and rstacc.data_cancellazione is null
                        and rstacc.movgest_stato_id=dstacc.movgest_stato_id
                        and dstacc.movgest_stato_code in ('D', 'N')
                        /*and ( exists (select 
                              1 
                              from siac_r_movgest_ts aa, siac_t_movgest_ts acc_ts,
                              siac_t_movgest acc
                          where 
                               e.movgest_ts_id = aa.movgest_ts_b_id 
                              and aa.data_cancellazione is null
                              and aa.validita_fine is null 
                              and aa.movgest_ts_a_id = acc_ts.movgest_ts_id
                              and acc_ts.movgest_ts_id_padre is null
                              and acc_ts.movgest_id = acc.movgest_id
                              and acc.validita_fine is null
                              and acc.data_cancellazione is null
                              and acc_ts.validita_fine is null
                              and acc_ts.data_cancellazione is null
                              and acc.movgest_anno = 2017 --annoBilInt 
                              ) 
                        or exists 
                        (select 
                              1 
                              from siac_r_movgest_ts aa, 
                              siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt
                          where aa.avav_id=v.avav_id     
                              and v.avav_tipo_id=vt.avav_tipo_id 
                              and vt.avav_tipo_code = 'AAM' 
                              and e.movgest_ts_id = aa.movgest_ts_b_id 
                              and aa.data_cancellazione is null
                              and aa.validita_fine is null )  
                          )*/
                           group by o.classif_code)
              union(
              select sum(COALESCE(aa.movgest_ts_importo,0)) AS
                      spese_da_impeg_anni_succ_f, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        siac_r_movgest_ts_atto_amm q,
                        siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                        siac_r_movgest_ts aa, 
                        siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt 
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        and q.movgest_ts_id=e.movgest_ts_id
                        and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  p_anno 
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno > annoBilInt + 2
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        and q.data_cancellazione is null
                        and q.validita_fine is null
                        and aa.avav_id=v.avav_id     
                        and v.avav_tipo_id=vt.avav_tipo_id 
                        and vt.avav_tipo_code = 'AAM' 
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                           group by o.classif_code
              )
              union(
              select sum(COALESCE(aa.movgest_ts_importo,0)) AS
                      spese_da_impeg_anno1_d, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        --siac_r_movgest_ts_atto_amm q,
                        --siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                        siac_r_movgest_ts aa, 
                        siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt 
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        --and q.movgest_ts_id=e.movgest_ts_id
                        --and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  (annoBilInt + 1)::varchar  
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno > annoBilInt + 2
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code <> 'A'
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        --and q.data_cancellazione is null
                        --and q.validita_fine is null
                        and aa.avav_id=v.avav_id     
                        and v.avav_tipo_id=vt.avav_tipo_id 
                        and vt.avav_tipo_code like'FPV%' 
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                        and exists (
                        	select 1
                            from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
                                 fase_bil_t_reimputazione fasereimp, siac_t_bil bilprec, siac_t_periodo pprec
                            where tipo.ente_proprietario_id= a.ente_proprietario_id 
                            and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP'
                            and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
                            and   fase.fase_bil_elab_esito='OK'
                            and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
                            and   fasereimp.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
                            and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
                            and   fasereimp.bil_id=bilprec.bil_id
                            and   bilprec.periodo_id = pprec.periodo_id
                            and   pprec.anno=p_anno
                            and   fasereimp.movgestnew_id = a.movgest_id
                            and   fase.data_cancellazione is null
                            and   fase.validita_fine is null
                            and   tipo.data_cancellazione is null
                            and   tipo.validita_fine is null
                        )
                       and not exists 
                        (
                           select 
                             1
                             from fase_bil_t_reimputazione_vincoli vreimp, siac_r_movgest_ts rold,
                             siac_r_movgest_ts rnew, siac_t_avanzovincolo avold, siac_d_avanzovincolo_tipo davold
                             where 
                             vreimp.movgest_ts_r_new_id =  aa.movgest_ts_r_id 
                             and vreimp.movgest_ts_r_id=rold.movgest_ts_r_id
                             and vreimp.movgest_ts_r_new_id = rnew.movgest_ts_r_id
                             and avold.avav_id=rold.avav_id
                             and avold.avav_tipo_id = davold.avav_tipo_id
                             and davold.avav_tipo_code like '%FPV%'
                        )
                        group by o.classif_code
              )   
              ) as x
                group by x.programma_code 
                )                               
select 
p_anno::varchar  bil_anno ,
''::varchar  missione_tipo_code ,
tbclass.missione_tipo_desc ,
tbclass.missione_code ,
tbclass.missione_desc ,
''::varchar programma_tipo_code ,
tbclass.programma_tipo_desc ,
tbclass.programma_code ,
tbclass.programma_desc ,
	--22/02/2019: SIAC-6623. 
--coalesce(tbfpvprec.spese_fpv_anni_prec,0) as fondo_plur_anno_prec_a,
COALESCE(fpv_anno_prec_da_capitoli.importo_fpv_anno_prec,
	coalesce(tbfpvprec.spese_fpv_anni_prec,0)) fondo_plur_anno_prec_a,
--coalesce(var_spese_impe_anni_prec_b,0) as spese_impe_anni_prec_b,
coalesce(tbimpaprec.spese_impe_anni_prec,0) as spese_impe_anni_prec_b,
	--22/02/2019: SIAC-6623. 
--coalesce(tbfpvprec.spese_fpv_anni_prec,0)-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0)  as quota_fond_plur_anni_prec_c,
COALESCE(fpv_anno_prec_da_capitoli.importo_fpv_anno_prec,
	coalesce(tbfpvprec.spese_fpv_anni_prec,0))-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0)  as quota_fond_plur_anni_prec_c,
coalesce(tbimpanno1.spese_da_impeg_anno1_d,0) spese_da_impeg_anno1_d,
coalesce(tbimpanno2.spese_da_impeg_anno2_e,0) spese_da_impeg_anno2_e,
coalesce(tbimpannisuc.spese_da_impeg_anni_succ_f,0) spese_da_impeg_anni_succ_f,
coalesce(tbriaccx.riacc_colonna_x,0) riacc_colonna_x,
coalesce(tbriaccy.riacc_colonna_y,0) riacc_colonna_y,
	--22/02/2019: SIAC-6623.
--coalesce(tbfpvprec.spese_fpv_anni_prec,0)-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0) +
--coalesce(tbimpanno1.spese_da_impeg_anno1_d,0) + coalesce(tbimpanno2.spese_da_impeg_anno2_e,0)+coalesce(tbimpannisuc.spese_da_impeg_anni_succ_f,0)
COALESCE(fpv_anno_prec_da_capitoli.importo_fpv_anno_prec,
	coalesce(tbfpvprec.spese_fpv_anni_prec,0))-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0) +
coalesce(tbimpanno1.spese_da_impeg_anno1_d,0) + coalesce(tbimpanno2.spese_da_impeg_anno2_e,0)+coalesce(tbimpannisuc.spese_da_impeg_anni_succ_f,0)
as fondo_plur_anno_g 
from tbclass left join tbimpaprec     
	on tbclass.programma_code=tbimpaprec.programma_code
left join tbfpvprec 
	on tbclass.programma_code=tbfpvprec.programma_code
left join tbriaccx     
	on tbclass.programma_code=tbriaccx.programma_code
left join tbriaccy   
	on tbclass.programma_code=tbriaccy.programma_code
left join tbimpanno1   
	on tbclass.programma_code=tbimpanno1.programma_code
left join tbimpanno2   
	on tbclass.programma_code=tbimpanno2.programma_code
left join tbimpannisuc   
	on tbclass.programma_code=tbimpannisuc.programma_code
    	--22/02/2019: SIAC-6623.
left join fpv_anno_prec_da_capitoli
	on tbclass.programma_code=fpv_anno_prec_da_capitoli.programma_code;
      
    
delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;




raise notice 'fine OK';
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

CREATE OR REPLACE FUNCTION siac."BILR221_Allegato_B_Fondo_Pluriennale_vincolato_Rend_capitolo" (
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
  elem_id_fpv integer,
  bil_ele_code_fpv varchar,
  bil_ele_desc_fpv varchar,
  bil_ele_code2_fpv varchar,
  bil_ele_desc2_fpv varchar,
  fondo_plur_anno_prec_a numeric,
  spese_impe_anni_prec_b numeric,
  quota_fond_plur_anni_prec_c numeric,
  spese_da_impeg_anno1_d numeric,
  spese_da_impeg_anno2_e numeric,
  spese_da_impeg_anni_succ_f numeric,
  riacc_colonna_x numeric,
  riacc_colonna_y numeric,
  fondo_plur_anno_g numeric,
  fpv_stanziato_anno numeric,
  imp_cronoprogramma numeric
) AS
$body$
DECLARE


classifBilRec record;
var_fondo_plur_anno_prec_a numeric;
var_spese_impe_anni_prec_b numeric;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
annoPrec varchar;
annoProspInt integer;
annoBilInt integer;
conflagfpv boolean ;
a_dacapfpv boolean ;
h_dacapfpv boolean ;
flagretrocomp boolean ;

h_count integer :=0;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
id_bil INTEGER;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
annoPrec:= ((p_anno::INTEGER)-1)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione


annoBilInt=p_anno::INTEGER;

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';

var_fondo_plur_anno_prec_a=0;
var_spese_impe_anni_prec_b=0;
quota_fond_plur_anni_prec_c=0;
spese_da_impeg_anno1_d=0;
spese_da_impeg_anno2_e=0;
spese_da_impeg_anni_succ_f=0;
fondo_plur_anno_g=0;


select fnc_siac_random_user()
into	user_table;

select t_bil.bil_id
	into id_bil
from siac_t_bil t_bil,
	siac_t_periodo t_periodo
where t_bil.periodo_id=t_periodo.periodo_id
	and t_bil.ente_proprietario_id = p_ente_prop_id
    and t_periodo.anno= p_anno    
    and t_bil.data_cancellazione IS NULL
    and t_periodo.data_cancellazione IS NULL;
IF NOT FOUND THEN
	raise notice 'Codice del bilancio non trovato';
    return;
END IF;


        
return query  
	with strut_bilancio as(
     		select  *
            from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, p_anno,'') a
            where a.missione_code::integer <= 19),
    capitoli_fpv as(
    	select 	programma.classif_id programma_id,
			macroaggr.classif_id macroaggregato_id,
        	p_anno anno_bilancio,
       		capitolo.*
		from 
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
		where capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 	and
            programma.classif_tipo_id	=programma_tipo.classif_tipo_id and
            programma.classif_id	=r_capitolo_programma.classif_id and
            macroaggr.classif_tipo_id	=macroaggr_tipo.classif_tipo_id and
    		macroaggr.classif_id	=r_capitolo_macroaggr.classif_id and			     		 
    		capitolo.elem_id=r_capitolo_programma.elem_id	and
    		capitolo.elem_id=r_capitolo_macroaggr.elem_id	and
    		capitolo.elem_id		=	r_capitolo_stato.elem_id and
			r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id and
			capitolo.elem_id				=	r_cat_capitolo.elem_id	and
			r_cat_capitolo.elem_cat_id	=cat_del_capitolo.elem_cat_id and
            capitolo.bil_id 				= id_bil and
            capitolo.ente_proprietario_id	=	p_ente_prop_id	and
    		tipo_elemento.elem_tipo_code = elemTipoCode		and	
			programma_tipo.classif_tipo_code	='PROGRAMMA'  and		        
    		macroaggr_tipo.classif_tipo_code	='MACROAGGREGATO' and   
			stato_capitolo.elem_stato_code	=	'VA'	and
    		--cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC') and 
            cat_del_capitolo.elem_cat_code	in ('FPV','FPVC') and 
			programma_tipo.data_cancellazione			is null 	and
    		programma.data_cancellazione 				is null 	and
    		macroaggr_tipo.data_cancellazione	 		is null 	and
    		macroaggr.data_cancellazione 				is null 	and
    		tipo_elemento.data_cancellazione 			is null 	and
    		r_capitolo_programma.data_cancellazione 	is null 	and
    		r_capitolo_macroaggr.data_cancellazione 	is null 	and    		
    		stato_capitolo.data_cancellazione 			is null 	and 
    		r_capitolo_stato.data_cancellazione 		is null 	and
			cat_del_capitolo.data_cancellazione 		is null 	and
    		r_cat_capitolo.data_cancellazione 			is null 	and
			capitolo.data_cancellazione 				is null), 
fpv_stanziamento_anno as (               
select 	 capitolo.elem_id,
	sum(capitolo_importi.elem_det_importo) importo_fpv_stanz_anno
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_t_bil					t_bil,
            siac_t_periodo				t_periodo_bil,
            siac_d_bil_elem_tipo 		tipo_elemento,
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_r_bil_elem_class r_bil_elem_class,
            siac_t_class t_class, 
            siac_d_class_tipo d_class_tipo
where capitolo.elem_id = capitolo_importi.elem_id 
	and	capitolo.bil_id = t_bil.bil_id
	and t_periodo_bil.periodo_id =t_bil.periodo_id	
	and	capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id
	and	capitolo_importi.elem_det_tipo_id = capitolo_imp_tipo.elem_det_tipo_id 		
	and	capitolo_imp_periodo.periodo_id = capitolo_importi.periodo_id 
	and	capitolo.elem_id = r_capitolo_stato.elem_id			
	and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id
	and	capitolo.elem_id = r_cat_capitolo.elem_id				
	and	r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id	
    and d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
    and capitolo.elem_id = r_bil_elem_class.elem_id
    and r_bil_elem_class.classif_id = t_class.classif_id
	and capitolo_importi.ente_proprietario_id = p_ente_prop_id 					
	and	tipo_elemento.elem_tipo_code = elemTipoCode 
	and	t_periodo_bil.anno = p_anno	
	and	capitolo_imp_periodo.anno = p_anno	
	and	stato_capitolo.elem_stato_code = 'VA'								
	and	cat_del_capitolo.elem_cat_code in ('FPV','FPVC')
	and capitolo_imp_tipo.elem_det_tipo_code = 'STA'	
    and d_class_tipo.classif_tipo_code='PROGRAMMA'			
	and	capitolo_importi.data_cancellazione 		is null
	and	capitolo_imp_tipo.data_cancellazione 		is null
	and	capitolo_imp_periodo.data_cancellazione 	is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
	and	stato_capitolo.data_cancellazione 			is null 
	and	r_capitolo_stato.data_cancellazione 		is null
	and cat_del_capitolo.data_cancellazione 		is null
	and	r_cat_capitolo.data_cancellazione 			is null
	and t_bil.data_cancellazione 					is null
	and t_periodo_bil.data_cancellazione 			is null
    and r_bil_elem_class.data_cancellazione 		is null
    and t_class.data_cancellazione 					is null
    and d_class_tipo.data_cancellazione 		is null        
GROUP BY capitolo.elem_id ),            
 fpv_anno_prec_da_capitoli as (               
select 	 capitolo.elem_id,
		capitolo.elem_code, capitolo.elem_code2, capitolo.elem_code3,
	sum(capitolo_importi.elem_det_importo) importo_fpv_anno_prec
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_t_bil					t_bil,
            siac_t_periodo				t_periodo_bil,
            siac_d_bil_elem_tipo 		tipo_elemento,
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_r_bil_elem_class r_bil_elem_class,
            siac_t_class t_class, 
            siac_d_class_tipo d_class_tipo
where capitolo.elem_id = capitolo_importi.elem_id 
	and	capitolo.bil_id = t_bil.bil_id
	and t_periodo_bil.periodo_id =t_bil.periodo_id	
	and	capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id
	and	capitolo_importi.elem_det_tipo_id = capitolo_imp_tipo.elem_det_tipo_id 		
	and	capitolo_imp_periodo.periodo_id = capitolo_importi.periodo_id 
	and	capitolo.elem_id = r_capitolo_stato.elem_id			
	and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id
	and	capitolo.elem_id = r_cat_capitolo.elem_id				
	and	r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id	
    and d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
    and capitolo.elem_id = r_bil_elem_class.elem_id
    and r_bil_elem_class.classif_id = t_class.classif_id
	and capitolo_importi.ente_proprietario_id = p_ente_prop_id 					
	and	tipo_elemento.elem_tipo_code = elemTipoCode 
	and	t_periodo_bil.anno = annoPrec	--anno bilancio -1	
	and	capitolo_imp_periodo.anno = annoPrec	--anno bilancio -1		  	
	and	stato_capitolo.elem_stato_code = 'VA'								
	and	cat_del_capitolo.elem_cat_code in ('FPV','FPVC')
	and capitolo_imp_tipo.elem_det_tipo_code = 'STA'	
    and d_class_tipo.classif_tipo_code='PROGRAMMA'			
	and	capitolo_importi.data_cancellazione 		is null
	and	capitolo_imp_tipo.data_cancellazione 		is null
	and	capitolo_imp_periodo.data_cancellazione 	is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
	and	stato_capitolo.data_cancellazione 			is null 
	and	r_capitolo_stato.data_cancellazione 		is null
	and cat_del_capitolo.data_cancellazione 		is null
	and	r_cat_capitolo.data_cancellazione 			is null
	and t_bil.data_cancellazione 					is null
	and t_periodo_bil.data_cancellazione 			is null
    and r_bil_elem_class.data_cancellazione 		is null
    and t_class.data_cancellazione 					is null
    and d_class_tipo.data_cancellazione 		is null        
GROUP BY capitolo.elem_id, capitolo.elem_code, capitolo.elem_code2, capitolo.elem_code3 ),
importi_anni_prec as (
select t_bil_elem.elem_id,
	sum(coalesce( r_movgest_ts.movgest_ts_importo ,0)) spese_impe_anni_prec    	
    from siac_t_movgest t_movgest,  
          siac_t_movgest_ts t_movgest_ts, siac_t_movgest_ts_det t_movgest_ts_det,
          siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, siac_t_bil_elem t_bil_elem, 
		  siac_r_movgest_bil_elem r_movgest_bil_elem,
          siac_r_movgest_ts_stato r_movgest_ts_stato, siac_d_movgest_stato d_movgest_stato,
          siac_r_bil_elem_class r_bil_elem_class,
          siac_t_class t_class, siac_d_class_tipo d_class_tipo, 
           siac_d_movgest_tipo d_mov_tipo,
           siac_r_movgest_ts r_movgest_ts, 
           siac_t_avanzovincolo t_avanzovincolo, 
           siac_d_avanzovincolo_tipo d_avanzovincolo_tipo
    where 
           t_movgest.movgest_id = t_movgest_ts.movgest_id  
          and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
          and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
          and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
          and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
          and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
          and r_bil_elem_class.classif_id = t_class.classif_id
          and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
          and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id
          and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
          and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id 
          and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
          and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id 
		  and t_movgest.bil_id = id_bil
          and t_movgest.ente_proprietario_id= p_ente_prop_id      
          and d_class_tipo.classif_tipo_code='PROGRAMMA'
          and t_movgest.movgest_anno =  annoBilInt
          and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='I'
          and d_movgest_stato.movgest_stato_code in ('D', 'N')
          and d_mov_tipo.movgest_tipo_code='I' --Impegni      
          and d_avanzovincolo_tipo.avav_tipo_code like'FPV%'  
          and t_movgest_ts.movgest_ts_id_padre is NULL              
          and r_movgest_bil_elem.data_cancellazione is null
          and r_movgest_bil_elem.validita_fine is NULL          
          and r_movgest_ts_stato.data_cancellazione is null
          and r_movgest_ts_stato.validita_fine is null
          and d_mov_tipo.data_cancellazione is null
          and d_mov_tipo.validita_fine is null              
          and r_bil_elem_class.data_cancellazione is null
          and r_bil_elem_class.validita_fine is null
          and t_movgest_ts_det.data_cancellazione is null
          and t_movgest_ts_det.validita_fine is null
          and r_movgest_ts.avav_id=t_avanzovincolo.avav_id                                  
          and r_movgest_ts.data_cancellazione is null
          and r_movgest_ts.validita_fine is null
		  and t_bil_elem.data_cancellazione is null
    group by t_bil_elem.elem_id ),
riaccert_colonna_x as (
--Riaccertamento degli impegni di cui alla lettera b) effettuata nel corso dell'eserczio N (cd. economie di impegno)
--riduzioni su impegni di competenza con anno atto minore dell'anno di bilancio 
--e coperti anche solo parzialmente da fondo   
	select t_bil_elem.elem_id,
		sum(COALESCE(t_movgest_ts_det_mod.movgest_ts_det_importo,0)*-1) riacc_colonna_x                
      from siac_r_modifica_stato r_modifica_stato, 
      siac_t_movgest_ts_det_mod t_movgest_ts_det_mod,
      siac_t_movgest_ts t_movgest_ts, siac_d_modifica_stato d_modifica_stato,
      siac_t_movgest t_movgest, siac_d_movgest_tipo d_movgest_tipo, 
      siac_t_modifica t_modifica, siac_d_modifica_tipo d_modifica_tipo,
      siac_t_bil_elem t_bil_elem, siac_r_movgest_bil_elem r_movgest_bil_elem,
      siac_r_bil_elem_class r_bil_elem_class, 
      siac_t_class t_class, siac_d_class_tipo d_class_tipo,
      siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
      siac_t_atto_amm t_atto_amm ,
      siac_r_movgest_ts_stato r_movgest_ts_stato, 
      siac_d_movgest_stato d_movgest_stato    
      where t_movgest_ts_det_mod.mod_stato_r_id=r_modifica_stato.mod_stato_r_id
      and t_movgest_ts_det_mod.movgest_ts_id = t_movgest_ts.movgest_ts_id
      and t_movgest.movgest_tipo_id=d_movgest_tipo.movgest_tipo_id
      and d_modifica_stato.mod_stato_id=r_modifica_stato.mod_stato_id      
      and t_movgest.movgest_id=t_movgest_ts.movgest_id
      and t_modifica.mod_id=r_modifica_stato.mod_id
      and t_modifica.mod_tipo_id=d_modifica_tipo.mod_tipo_id
      and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
      and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
      and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
      and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
      and r_bil_elem_class.elem_id=t_bil_elem.elem_id
      and r_bil_elem_class.classif_id=t_class.classif_id
      and r_movgest_ts_stato.movgest_ts_id = t_movgest_ts.movgest_ts_id
      and r_movgest_ts_stato.movgest_stato_id = d_movgest_stato.movgest_stato_id      
      and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
      and t_movgest.bil_id=id_bil
      and r_modifica_stato.ente_proprietario_id=p_ente_prop_id
      and d_modifica_stato.mod_stato_code='V'
      and d_movgest_tipo.movgest_tipo_code='I'
      and 
      (d_modifica_tipo.mod_tipo_code like  'ECON%'
         or d_modifica_tipo.mod_tipo_desc like  'ROR%')
      and d_modifica_tipo.mod_tipo_code <> 'REIMP'
      and d_class_tipo.classif_tipo_code='PROGRAMMA'
      and d_movgest_stato.movgest_stato_code in ('D', 'N')
      and t_movgest.movgest_anno = annoBilInt 
      and r_movgest_ts_stato.data_cancellazione is NULL
      and r_movgest_ts_stato.validita_fine is null
      and t_movgest_ts.movgest_ts_id_padre is null
      and r_modifica_stato.data_cancellazione is null
      and r_modifica_stato.validita_fine is null
      and t_movgest_ts_det_mod.data_cancellazione is null
      and t_movgest_ts_det_mod.validita_fine is null
      and t_movgest_ts.data_cancellazione is null
      and t_movgest_ts.validita_fine is null
      and d_modifica_stato.data_cancellazione is null
      and d_modifica_stato.validita_fine is null
      and t_movgest.data_cancellazione is null
      and t_movgest.validita_fine is null
      and d_movgest_tipo.data_cancellazione is null
      and d_movgest_tipo.validita_fine is null
      and t_modifica.data_cancellazione is null
      and t_modifica.validita_fine is null
      and d_modifica_tipo.data_cancellazione is null
      and d_modifica_tipo.validita_fine is null
      and t_bil_elem.data_cancellazione is null
      and t_bil_elem.validita_fine is null
      and r_movgest_bil_elem.data_cancellazione is null
      and r_movgest_bil_elem.validita_fine is null
      and r_bil_elem_class.data_cancellazione is null
      and r_bil_elem_class.validita_fine is null
      and t_class.data_cancellazione is null
      and t_class.validita_fine is null
      and d_class_tipo.data_cancellazione is null
      and d_class_tipo.validita_fine is null
      and t_atto_amm.data_cancellazione is null
      and t_atto_amm.validita_fine is null      
      and r_movgest_ts_atto_amm.data_cancellazione is null
      and r_movgest_ts_atto_amm.validita_fine is null
      and d_movgest_stato.data_cancellazione is null
      and d_movgest_stato.validita_fine is null      
      and exists (select 
          		1 
                from siac_r_movgest_ts r_movgest_ts, 
            	siac_t_avanzovincolo t_avanzovincolo, 
                siac_d_avanzovincolo_tipo d_avanzovincolo_tipo
			where r_movgest_ts.avav_id=t_avanzovincolo.avav_id     
                and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id 
                and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                and d_avanzovincolo_tipo.avav_tipo_code like'FPV%'                 
                and r_movgest_ts.data_cancellazione is null
                and r_movgest_ts.validita_fine is null 
               )
      group by t_bil_elem.elem_id)  ,
riaccert_colonna_y as (
--Riaccertamento degli impegni di cui alla lettera b) effettuata nel corso dell'eserczio N (cd. economie di impegno) su impegni pluriennali finanziati dal FPV e imputati agli esercizi successivi  a N
--riduzioni su impegni di competenza con anno atto minore dell'anno di bilancio 
--e coperti anche solo parzialmente da fondo 
select t_bil_elem.elem_id,
	sum(COALESCE(t_movgest_ts_det_mod.movgest_ts_det_importo,0)*-1) riacc_colonna_y
      from siac_r_modifica_stato r_modifica_stato, 
      siac_t_movgest_ts_det_mod t_movgest_ts_det_mod,
      siac_t_movgest_ts t_movgest_ts, 
      siac_d_modifica_stato d_modifica_stato,
      siac_t_movgest t_movgest, siac_d_movgest_tipo d_movgest_tipo,  
      siac_t_modifica t_modifica, siac_d_modifica_tipo d_modifica_tipo,
      siac_t_bil_elem t_bil_elem, siac_r_movgest_bil_elem r_movgest_bil_elem,
      siac_r_bil_elem_class r_bil_elem_class, 
      siac_t_class t_class, siac_d_class_tipo d_class_tipo,
      siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
      siac_t_atto_amm t_atto_amm ,
      siac_r_movgest_ts_stato r_movgest_ts_stato, 
      siac_d_movgest_stato d_movgest_stato    
      where t_movgest_ts_det_mod.mod_stato_r_id=r_modifica_stato.mod_stato_r_id
      and t_movgest_ts_det_mod.movgest_ts_id = t_movgest_ts.movgest_ts_id
      and t_movgest.movgest_tipo_id=d_movgest_tipo.movgest_tipo_id
      and d_modifica_stato.mod_stato_id=r_modifica_stato.mod_stato_id      
      and t_movgest.movgest_id=t_movgest_ts.movgest_id
      and t_modifica.mod_id=r_modifica_stato.mod_id
      and t_modifica.mod_tipo_id=d_modifica_tipo.mod_tipo_id      
      and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
      and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
      and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
      and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
      and r_bil_elem_class.elem_id=t_bil_elem.elem_id
      and r_bil_elem_class.classif_id=t_class.classif_id
      and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id    
      and r_movgest_ts_stato.movgest_ts_id = t_movgest_ts.movgest_ts_id
      and r_movgest_ts_stato.movgest_stato_id = d_movgest_stato.movgest_stato_id  
      and t_movgest.bil_id= id_bil
      and r_modifica_stato.ente_proprietario_id=p_ente_prop_id
      and t_movgest.movgest_anno > annoBilInt 
      and d_modifica_stato.mod_stato_code='V'
      and d_movgest_tipo.movgest_tipo_code='I'
      and 
      (d_modifica_tipo.mod_tipo_code like  'ECON%'
         or d_modifica_tipo.mod_tipo_desc like  'ROR%')
      and d_modifica_tipo.mod_tipo_code <> 'REIMP'
      and d_class_tipo.classif_tipo_code='PROGRAMMA'
      and d_movgest_stato.movgest_stato_code in ('D', 'N')
      and r_movgest_ts_stato.data_cancellazione is NULL
      and r_movgest_ts_stato.validita_fine is null
      and t_movgest_ts.movgest_ts_id_padre is null
      and r_modifica_stato.data_cancellazione is null
      and r_modifica_stato.validita_fine is null
      and t_movgest_ts_det_mod.data_cancellazione is null
      and t_movgest_ts_det_mod.validita_fine is null
      and t_movgest_ts.data_cancellazione is null
      and t_movgest_ts.validita_fine is null
      and d_modifica_stato.data_cancellazione is null
      and d_modifica_stato.validita_fine is null
      and t_movgest.data_cancellazione is null
      and t_movgest.validita_fine is null
      and d_movgest_tipo.data_cancellazione is null
      and d_movgest_tipo.validita_fine is null
      and t_modifica.data_cancellazione is null
      and t_modifica.validita_fine is null
      and d_modifica_tipo.data_cancellazione is null
      and d_modifica_tipo.validita_fine is null
      and t_bil_elem.data_cancellazione is null
      and t_bil_elem.validita_fine is null
      and r_movgest_bil_elem.data_cancellazione is null
      and r_movgest_bil_elem.validita_fine is null
      and r_bil_elem_class.data_cancellazione is null
      and r_bil_elem_class.validita_fine is null
      and t_class.data_cancellazione is null
      and t_class.validita_fine is null
      and d_class_tipo.data_cancellazione is null
      and d_class_tipo.validita_fine is null
      and r_movgest_ts_atto_amm.data_cancellazione is null
      and r_movgest_ts_atto_amm.validita_fine is null
      and t_atto_amm.data_cancellazione is null
      and t_atto_amm.validita_fine is null
      and d_movgest_stato.data_cancellazione is null
      and d_movgest_stato.validita_fine is null
      and exists (select 
          		1 
                from siac_r_movgest_ts r_movgest_ts, 
            	siac_t_avanzovincolo t_avanzovincolo, 
                siac_d_avanzovincolo_tipo d_avanzovincolo_tipo
			where r_movgest_ts.avav_id=t_avanzovincolo.avav_id     
                and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id 
                and d_avanzovincolo_tipo.avav_tipo_code like'FPV%' 
                and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                and r_movgest_ts.data_cancellazione is null
                and r_movgest_ts.validita_fine is null )
      group by t_bil_elem.elem_id) ,
impegni_anno1_d as(
      -- Spese impegnate nell'esercizio N con imputazione all'esercizio N+1 e 
      -- coperte dal fondo pluriennale vincolato
      -- impegni anno + 1 con atto nell'anno legati ad accertamenti 
      -- di competenza oppure ad avanzo
select x.elem_id,
	sum(x.spese_da_impeg_anno1_d) as spese_da_impeg_anno1_d   
from (
               (
              select t_bil_elem.elem_id,
              	sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anno1_d              
                        from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
                        siac_t_atto_amm t_atto_amm, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, siac_t_movgest_ts acc_ts,
                        siac_t_movgest acc,
                        siac_r_movgest_ts_stato rstacc,
                        siac_d_movgest_stato dstacc
                where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id
                        and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id 
                        and r_movgest_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_id = acc.movgest_id
                        and rstacc.movgest_ts_id=acc_ts.movgest_ts_id
                        and rstacc.movgest_stato_id=dstacc.movgest_stato_id
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and t_movgest.bil_id =id_bil
                        and t_movgest.ente_proprietario_id= p_ente_prop_id      
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno = annoBilInt + 1
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        and dstacc.movgest_stato_code in ('D', 'N')   
                        and acc.movgest_anno = annoBilInt  
                        and t_movgest_ts.movgest_ts_id_padre is NULL                            
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_movgest_ts_atto_amm.data_cancellazione is null
                        and r_movgest_ts_atto_amm.validita_fine is null                        
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null                         
                        and acc_ts.movgest_ts_id_padre is null                        
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null                                                
                        and rstacc.validita_fine is null
                        and rstacc.data_cancellazione is null   
                        and t_movgest.data_cancellazione is null 
                        and t_movgest.validita_fine is null  
                        and t_bil_elem.data_cancellazione is null 
                        and t_bil_elem.validita_fine is null  
                        and t_class.data_cancellazione is null 
                        and t_class.validita_fine is null                                                                                                           
              	group by t_bil_elem.elem_id)
              union(
              select t_bil_elem.elem_id,
              		sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anno1_d
                from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
                        siac_t_atto_amm t_atto_amm, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, 
                        siac_t_avanzovincolo t_avanzovincolo, 
                        siac_d_avanzovincolo_tipo d_avanzovincolo_tipo 
                      where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id
                        and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
                        and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id
                        and r_movgest_ts.avav_id=t_avanzovincolo.avav_id
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and t_movgest.bil_id =id_bil
                        and t_movgest.ente_proprietario_id = p_ente_prop_id       
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno = annoBilInt + 1
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        and d_avanzovincolo_tipo.avav_tipo_code = 'AAM'
                        and t_movgest_ts.movgest_ts_id_padre is NULL                             
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_movgest_ts_atto_amm.data_cancellazione is null
                        and r_movgest_ts_atto_amm.validita_fine is null                                                                                                       
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null 
                        and t_movgest.data_cancellazione is null
                        and t_movgest.validita_fine is null                        
                   group by t_bil_elem.elem_id
              )--- Impegni da riaccertamento - reimputazione nel bilancio successivo 
              union(
              select t_bil_elem.elem_id,
              		sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anno1_d
                        from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, 
                        siac_t_avanzovincolo t_avanzovincolo, 
                        siac_d_avanzovincolo_tipo d_avanzovincolo_tipo 
                      where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id                        
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_ts.avav_id=t_avanzovincolo.avav_id     
                        and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id 
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
                        and t_movgest.bil_id = id_bil
                        and t_movgest.ente_proprietario_id= p_ente_prop_id     
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno = annoBilInt + 1
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code <> 'A'
                        and d_mov_tipo.movgest_tipo_code='I'
                        and d_avanzovincolo_tipo.avav_tipo_code like'FPV%' 
                        and t_movgest_ts.movgest_ts_id_padre is NULL                             
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null                                                                         
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null 
                        and t_movgest.data_cancellazione is null
                        and t_movgest.validita_fine is null 
                        and exists (
                        	select 1
                            from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
                                 fase_bil_t_reimputazione fasereimp, siac_t_bil bilprec, siac_t_periodo pprec
                            where tipo.ente_proprietario_id= t_movgest.ente_proprietario_id                             
                            and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id                            
                            and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
                            and   fasereimp.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
                            and   fasereimp.bil_id=bilprec.bil_id
                            and   bilprec.periodo_id = pprec.periodo_id
                            and   fasereimp.movgestnew_id = t_movgest.movgest_id                            
                            and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
                            and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP'
                            and   fase.fase_bil_elab_esito='OK'
                            and   pprec.anno=p_anno                            
                            and   fase.data_cancellazione is null
                            and   fase.validita_fine is null
                            and   tipo.data_cancellazione is null
                            and   tipo.validita_fine is null
                        )
                        and not exists 
                        (
                           select 
                             1
                             from fase_bil_t_reimputazione_vincoli vreimp, siac_r_movgest_ts rold,
                             siac_r_movgest_ts rnew, siac_t_avanzovincolo avold, siac_d_avanzovincolo_tipo davold
                             where 
                             vreimp.movgest_ts_r_new_id =  r_movgest_ts.movgest_ts_r_id 
                             and vreimp.movgest_ts_r_id=rold.movgest_ts_r_id
                             and vreimp.movgest_ts_r_new_id = rnew.movgest_ts_r_id
                             and avold.avav_id=rold.avav_id
                             and avold.avav_tipo_id = davold.avav_tipo_id
                             and davold.avav_tipo_code like '%FPV%'
                        )
                        group by t_bil_elem.elem_id
              )    
              ) as x
                group by x.elem_id ),
impegni_anno2_e as(
      -- Spese impegnate nell'esercizio N con imputazione all'esercizio N+1 e 
      -- coperte dal fondo pluriennale vincolato
      -- impegni anno + 1 con atto nell'anno legati ad accertamenti 
      -- di competenza oppure ad avanzo
select x.elem_id,
	sum(x.spese_da_impeg_anno2_e) as spese_da_impeg_anno2_e   
from (
               (
              select t_bil_elem.elem_id,
              	sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anno2_e              
                        from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
                        siac_t_atto_amm t_atto_amm, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, siac_t_movgest_ts acc_ts,
                        siac_t_movgest acc,
                        siac_r_movgest_ts_stato rstacc,
                        siac_d_movgest_stato dstacc
                where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id
                        and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id 
                        and r_movgest_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_id = acc.movgest_id
                        and rstacc.movgest_ts_id=acc_ts.movgest_ts_id
                        and rstacc.movgest_stato_id=dstacc.movgest_stato_id
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and t_movgest.bil_id =id_bil
                        and t_movgest.ente_proprietario_id= p_ente_prop_id      
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno = annoBilInt + 2
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        and dstacc.movgest_stato_code in ('D', 'N')   
                        and acc.movgest_anno = annoBilInt  
                        and t_movgest_ts.movgest_ts_id_padre is NULL                            
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_movgest_ts_atto_amm.data_cancellazione is null
                        and r_movgest_ts_atto_amm.validita_fine is null                        
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null                         
                        and acc_ts.movgest_ts_id_padre is null                        
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null                                                
                        and rstacc.validita_fine is null
                        and rstacc.data_cancellazione is null   
                        and t_movgest.data_cancellazione is null 
                        and t_movgest.validita_fine is null  
                        and t_bil_elem.data_cancellazione is null 
                        and t_bil_elem.validita_fine is null  
                        and t_class.data_cancellazione is null 
                        and t_class.validita_fine is null                                                                                                           
              	group by t_bil_elem.elem_id)
              union(
              select t_bil_elem.elem_id,
              		sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anno2_e
                from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
                        siac_t_atto_amm t_atto_amm, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, 
                        siac_t_avanzovincolo t_avanzovincolo, 
                        siac_d_avanzovincolo_tipo d_avanzovincolo_tipo 
                      where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id
                        and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
                        and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id
                        and r_movgest_ts.avav_id=t_avanzovincolo.avav_id
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and t_movgest.bil_id =id_bil
                        and t_movgest.ente_proprietario_id = p_ente_prop_id       
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno = annoBilInt + 2
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        and d_avanzovincolo_tipo.avav_tipo_code = 'AAM'
                        and t_movgest_ts.movgest_ts_id_padre is NULL                             
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_movgest_ts_atto_amm.data_cancellazione is null
                        and r_movgest_ts_atto_amm.validita_fine is null                                                                                                       
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null 
                        and t_movgest.data_cancellazione is null
                        and t_movgest.validita_fine is null                        
                   group by t_bil_elem.elem_id
              )--- Impegni da riaccertamento - reimputazione nel bilancio successivo 
              union(
              select t_bil_elem.elem_id,
              		sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anno2_e
                        from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, 
                        siac_t_avanzovincolo t_avanzovincolo, 
                        siac_d_avanzovincolo_tipo d_avanzovincolo_tipo 
                      where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id                        
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_ts.avav_id=t_avanzovincolo.avav_id     
                        and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id 
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
                        and t_movgest.bil_id = id_bil
                        and t_movgest.ente_proprietario_id= p_ente_prop_id     
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno = annoBilInt + 2
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code <> 'A'
                        and d_mov_tipo.movgest_tipo_code='I'
                        and d_avanzovincolo_tipo.avav_tipo_code like'FPV%' 
                        and t_movgest_ts.movgest_ts_id_padre is NULL                             
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null                                                                         
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null 
                        and t_movgest.data_cancellazione is null
                        and t_movgest.validita_fine is null 
                        and exists (
                        	select 1
                            from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
                                 fase_bil_t_reimputazione fasereimp, siac_t_bil bilprec, siac_t_periodo pprec
                            where tipo.ente_proprietario_id= t_movgest.ente_proprietario_id                             
                            and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id                            
                            and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
                            and   fasereimp.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
                            and   fasereimp.bil_id=bilprec.bil_id
                            and   bilprec.periodo_id = pprec.periodo_id
                            and   fasereimp.movgestnew_id = t_movgest.movgest_id                            
                            and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
                            and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP'
                            and   fase.fase_bil_elab_esito='OK'
                            and   pprec.anno=p_anno                            
                            and   fase.data_cancellazione is null
                            and   fase.validita_fine is null
                            and   tipo.data_cancellazione is null
                            and   tipo.validita_fine is null
                        )
                        and not exists 
                        (
                           select 
                             1
                             from fase_bil_t_reimputazione_vincoli vreimp, siac_r_movgest_ts rold,
                             siac_r_movgest_ts rnew, siac_t_avanzovincolo avold, siac_d_avanzovincolo_tipo davold
                             where 
                             vreimp.movgest_ts_r_new_id =  r_movgest_ts.movgest_ts_r_id 
                             and vreimp.movgest_ts_r_id=rold.movgest_ts_r_id
                             and vreimp.movgest_ts_r_new_id = rnew.movgest_ts_r_id
                             and avold.avav_id=rold.avav_id
                             and avold.avav_tipo_id = davold.avav_tipo_id
                             and davold.avav_tipo_code like '%FPV%'
                        )
                        group by t_bil_elem.elem_id
              )    
              ) as x
                group by x.elem_id ),
impegni_annisucc_f as(
      -- Spese impegnate nell'esercizio N con imputazione all'esercizio N+1 e 
      -- coperte dal fondo pluriennale vincolato
      -- impegni anno + 1 con atto nell'anno legati ad accertamenti 
      -- di competenza oppure ad avanzo
select x.elem_id,
	sum(x.spese_da_impeg_anni_succ_f) as spese_da_impeg_anni_succ_f   
from (
               (
              select t_bil_elem.elem_id,
              	sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anni_succ_f              
                        from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
                        siac_t_atto_amm t_atto_amm, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, siac_t_movgest_ts acc_ts,
                        siac_t_movgest acc,
                        siac_r_movgest_ts_stato rstacc,
                        siac_d_movgest_stato dstacc
                where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id
                        and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id 
                        and r_movgest_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_id = acc.movgest_id
                        and rstacc.movgest_ts_id=acc_ts.movgest_ts_id
                        and rstacc.movgest_stato_id=dstacc.movgest_stato_id
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and t_movgest.bil_id =id_bil
                        and t_movgest.ente_proprietario_id= p_ente_prop_id      
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno > annoBilInt + 2
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        and dstacc.movgest_stato_code in ('D', 'N')   
                        and acc.movgest_anno = annoBilInt  
                        and t_movgest_ts.movgest_ts_id_padre is NULL                            
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_movgest_ts_atto_amm.data_cancellazione is null
                        and r_movgest_ts_atto_amm.validita_fine is null                        
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null                         
                        and acc_ts.movgest_ts_id_padre is null                        
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null                                                
                        and rstacc.validita_fine is null
                        and rstacc.data_cancellazione is null   
                        and t_movgest.data_cancellazione is null 
                        and t_movgest.validita_fine is null  
                        and t_bil_elem.data_cancellazione is null 
                        and t_bil_elem.validita_fine is null  
                        and t_class.data_cancellazione is null 
                        and t_class.validita_fine is null                                                                                                           
              	group by t_bil_elem.elem_id)
              union(
              select t_bil_elem.elem_id,
              		sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anni_succ_f
                from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
                        siac_t_atto_amm t_atto_amm, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, 
                        siac_t_avanzovincolo t_avanzovincolo, 
                        siac_d_avanzovincolo_tipo d_avanzovincolo_tipo 
                      where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id
                        and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
                        and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id
                        and r_movgest_ts.avav_id=t_avanzovincolo.avav_id
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and t_movgest.bil_id =id_bil
                        and t_movgest.ente_proprietario_id = p_ente_prop_id       
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno > annoBilInt + 2
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        and d_avanzovincolo_tipo.avav_tipo_code = 'AAM'
                        and t_movgest_ts.movgest_ts_id_padre is NULL                             
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_movgest_ts_atto_amm.data_cancellazione is null
                        and r_movgest_ts_atto_amm.validita_fine is null                                                                                                       
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null 
                        and t_movgest.data_cancellazione is null
                        and t_movgest.validita_fine is null                        
                   group by t_bil_elem.elem_id
              )--- Impegni da riaccertamento - reimputazione nel bilancio successivo 
              union(
              select t_bil_elem.elem_id,
              		sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anni_succ_f
                        from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, 
                        siac_t_avanzovincolo t_avanzovincolo, 
                        siac_d_avanzovincolo_tipo d_avanzovincolo_tipo 
                      where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id                        
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_ts.avav_id=t_avanzovincolo.avav_id     
                        and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id 
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
                        and t_movgest.bil_id = id_bil
                        and t_movgest.ente_proprietario_id= p_ente_prop_id     
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno > annoBilInt + 2
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code <> 'A'
                        and d_mov_tipo.movgest_tipo_code='I'
                        and d_avanzovincolo_tipo.avav_tipo_code like'FPV%' 
                        and t_movgest_ts.movgest_ts_id_padre is NULL                             
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null                                                                         
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null 
                        and t_movgest.data_cancellazione is null
                        and t_movgest.validita_fine is null 
                        and exists (
                        	select 1
                            from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
                                 fase_bil_t_reimputazione fasereimp, siac_t_bil bilprec, siac_t_periodo pprec
                            where tipo.ente_proprietario_id= t_movgest.ente_proprietario_id                             
                            and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id                            
                            and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
                            and   fasereimp.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
                            and   fasereimp.bil_id=bilprec.bil_id
                            and   bilprec.periodo_id = pprec.periodo_id
                            and   fasereimp.movgestnew_id = t_movgest.movgest_id                            
                            and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
                            and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP'
                            and   fase.fase_bil_elab_esito='OK'
                            and   pprec.anno=p_anno                            
                            and   fase.data_cancellazione is null
                            and   fase.validita_fine is null
                            and   tipo.data_cancellazione is null
                            and   tipo.validita_fine is null
                        )
                        and not exists 
                        (
                           select 
                             1
                             from fase_bil_t_reimputazione_vincoli vreimp, siac_r_movgest_ts rold,
                             siac_r_movgest_ts rnew, siac_t_avanzovincolo avold, siac_d_avanzovincolo_tipo davold
                             where 
                             vreimp.movgest_ts_r_new_id =  r_movgest_ts.movgest_ts_r_id 
                             and vreimp.movgest_ts_r_id=rold.movgest_ts_r_id
                             and vreimp.movgest_ts_r_new_id = rnew.movgest_ts_r_id
                             and avold.avav_id=rold.avav_id
                             and avold.avav_tipo_id = davold.avav_tipo_id
                             and davold.avav_tipo_code like '%FPV%'
                        )
                        group by t_bil_elem.elem_id
              )    
              ) as x
                group by x.elem_id ),
/* Per la gestione degli importi del cronoprogramma, come da indicazioni di Troiano, 
		occorre:
	- Prendere i dati dei progetti relativi all'ultimo cronoprogrogramma (data_creazione)
      con flag "usato_per_fpv" = true.
    - Se non esiste prendere i dati dell'ultimo cronoprogramma in bozza cioe' con
      "usato_per_fpv" = false i cui progetti non  abbiano impegni collegati.

*/                
 cronoprogrammi_fpv as (select cronop.* from 
 		(select a.cronop_id, a.cronop_code, d.cronop_elem_code,
			d.cronop_elem_code2, d.cronop_elem_code3,
    		COALESCE(sum(e.cronop_elem_det_importo),0)::numeric importo_crono			
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d,          	
          siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where  pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.periodo_id = f.periodo_id
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and pr.ente_proprietario_id=p_ente_prop_id
          and c.anno = p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = true          
          and clt2.classif_tipo_code='PROGRAMMA'        
          and stct.cronop_stato_code='VA'          
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null
          group by a.cronop_id, a.cronop_code, 
          d.cronop_elem_code,
	d.cronop_elem_code2,d.cronop_elem_code3) cronop,
 		(select t_cronop.cronop_id, 
    max(t_cronop.data_creazione) max_data_creazione
    from siac_t_cronop t_cronop, 
    	siac_t_bil t_bil, siac_t_periodo t_periodo
    where t_cronop.bil_id=t_bil.bil_id
    	and t_bil.periodo_id=t_periodo.periodo_id
        and t_cronop.ente_proprietario_id=p_ente_prop_id
        and t_periodo.anno=p_anno
        and t_cronop.usato_per_fpv::boolean=true
        and t_cronop.data_cancellazione IS NULL
        and t_bil.data_cancellazione IS NULL
        and t_periodo.data_cancellazione IS NULL
    group by t_cronop.cronop_id
   order by max_data_creazione DESC
   limit 1) id_cronop_last_versione 
where id_cronop_last_versione.cronop_id =  cronop.cronop_id ),
cronoprogrammi_bozza as(
	select cronop_bozza.* from 
    (select a.cronop_id, a.cronop_code, d.cronop_elem_code,
			d.cronop_elem_code2, d.cronop_elem_code3,
    		COALESCE(sum(e.cronop_elem_det_importo),0)::numeric importo_crono			
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d,          	
          siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where  pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.periodo_id = f.periodo_id
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and pr.ente_proprietario_id=p_ente_prop_id
          and c.anno = p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = false          
          and clt2.classif_tipo_code='PROGRAMMA'        
          and stct.cronop_stato_code='VA'          
          and stprt.programma_stato_code='VA'
          and pr.programma_id not in (
        	select r_movgest_ts_programma.programma_id
            	from siac_r_movgest_ts_programma r_movgest_ts_programma
            	where r_movgest_ts_programma.ente_proprietario_id=p_ente_prop_id
                	and r_movgest_ts_programma.data_cancellazione IS NULL
                    and r_movgest_ts_programma.validita_fine IS NULL)
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null
          group by a.cronop_id, a.cronop_code, 
          d.cronop_elem_code,
	d.cronop_elem_code2,d.cronop_elem_code3) cronop_bozza,  
    (select t_cronop.cronop_id, 
    max(t_cronop.data_creazione) max_data_creazione
    from siac_t_cronop t_cronop, 
    	siac_t_bil t_bil, siac_t_periodo t_periodo,
        siac_t_programma t_programma
    where t_cronop.bil_id=t_bil.bil_id
    	and t_bil.periodo_id=t_periodo.periodo_id
        and t_programma.programma_id= t_cronop.programma_id
        and t_cronop.ente_proprietario_id=p_ente_prop_id
        and t_periodo.anno=p_anno
        and t_cronop.usato_per_fpv::boolean=false
        and t_cronop.data_cancellazione IS NULL
        and t_bil.data_cancellazione IS NULL
        and t_periodo.data_cancellazione IS NULL
       and t_programma.programma_id not in (
        	select r_movgest_ts_programma.programma_id
            	from siac_r_movgest_ts_programma r_movgest_ts_programma
            	where r_movgest_ts_programma.ente_proprietario_id=p_ente_prop_id
                	and r_movgest_ts_programma.data_cancellazione IS NULL
                    and r_movgest_ts_programma.validita_fine IS NULL)
    group by t_cronop.cronop_id
   order by max_data_creazione DESC
   limit 1) id_cronop_bozza 
where id_cronop_bozza.cronop_id =  cronop_bozza.cronop_id ),
exist_last_versione as (select count(*) last_version
    from siac_t_cronop t_cronop, 
    	siac_t_bil t_bil, siac_t_periodo t_periodo
    where t_cronop.bil_id=t_bil.bil_id
    	and t_bil.periodo_id=t_periodo.periodo_id
        and t_cronop.ente_proprietario_id=p_ente_prop_id
        and t_periodo.anno=p_anno
        and t_cronop.usato_per_fpv::boolean=true
        and t_cronop.data_cancellazione IS NULL
        and t_bil.data_cancellazione IS NULL
        and t_periodo.data_cancellazione IS NULL)               
select 
p_anno::varchar  bil_anno ,
''::varchar  missione_tipo_code ,
strut_bilancio.missione_tipo_desc ,
strut_bilancio.missione_code ,
strut_bilancio.missione_desc ,
''::varchar programma_tipo_code ,
strut_bilancio.programma_tipo_desc ,
strut_bilancio.programma_code ,
strut_bilancio.programma_desc ,
capitoli_fpv.elem_id::integer elem_id_fpv,
capitoli_fpv.elem_code::varchar bil_ele_code_fpv,
capitoli_fpv.elem_desc::varchar bil_ele_desc_fpv,
capitoli_fpv.elem_code2::varchar bil_ele_code2_fpv,
capitoli_fpv.elem_desc2::varchar bil_ele_desc2_fpv,
COALESCE(fpv_anno_prec_da_capitoli.importo_fpv_anno_prec,0)::numeric fondo_plur_anno_prec_a,
COALESCE(importi_anni_prec.spese_impe_anni_prec,0)::numeric spese_impe_anni_prec_b,
COALESCE(fpv_anno_prec_da_capitoli.importo_fpv_anno_prec,0) -
	COALESCE(importi_anni_prec.spese_impe_anni_prec,0) -
    COALESCE(riaccert_colonna_x.riacc_colonna_x,0) -
    COALESCE(riaccert_colonna_y.riacc_colonna_y,0)::numeric quota_fond_plur_anni_prec_c,
COALESCE(impegni_anno1_d.spese_da_impeg_anno1_d,0)::numeric spese_da_impeg_anno1_d,
COALESCE(impegni_anno2_e.spese_da_impeg_anno2_e,0)::numeric spese_da_impeg_anno2_e,
COALESCE(impegni_annisucc_f.spese_da_impeg_anni_succ_f,0)::numeric spese_da_impeg_anni_succ_f,
COALESCE(riaccert_colonna_x.riacc_colonna_x,0)::numeric riacc_colonna_x,
COALESCE(riaccert_colonna_y.riacc_colonna_y,0)::numeric riacc_colonna_y,
COALESCE(impegni_anno1_d.spese_da_impeg_anno1_d,0) +
	COALESCE(impegni_anno2_e.spese_da_impeg_anno2_e,0) +
    COALESCE(impegni_annisucc_f.spese_da_impeg_anni_succ_f,0)::numeric fondo_plur_anno_g,
COALESCE(fpv_stanziamento_anno.importo_fpv_stanz_anno,0)::numeric fpv_stanziato_anno,
	--se NON esiste una versione con "usato_per_fpv" = true prendo i dati di
    --cronoprogramma in BOZZA, altrimenti quelli della versione approvata.
CASE WHEN exist_last_versione.last_version = 0
	THEN COALESCE(cronoprogrammi_bozza.importo_crono,0)
    ELSE COALESCE(cronoprogrammi_fpv.importo_crono,0) end ::numeric imp_cronoprogramma
from strut_bilancio
left JOIN capitoli_fpv on (strut_bilancio.programma_id = capitoli_fpv.programma_id
			AND strut_bilancio.macroag_id = capitoli_fpv.macroaggregato_id)
left join fpv_anno_prec_da_capitoli
	on (capitoli_fpv.elem_code=fpv_anno_prec_da_capitoli.elem_code
    	AND capitoli_fpv.elem_code2=fpv_anno_prec_da_capitoli.elem_code2
        AND capitoli_fpv.elem_code3=fpv_anno_prec_da_capitoli.elem_code3)   
left join importi_anni_prec 
	on capitoli_fpv.elem_id = importi_anni_prec.elem_id 
left join riaccert_colonna_x
	on capitoli_fpv.elem_id = riaccert_colonna_x. elem_id
left join riaccert_colonna_y
	on capitoli_fpv.elem_id = riaccert_colonna_y.elem_id
left join impegni_anno1_d
	on capitoli_fpv.elem_id = impegni_anno1_d.elem_id
left join impegni_anno2_e
	on capitoli_fpv.elem_id = impegni_anno2_e.elem_id
left join impegni_annisucc_f
	on capitoli_fpv.elem_id = impegni_annisucc_f.elem_id 
left join fpv_stanziamento_anno
	on capitoli_fpv.elem_id = fpv_stanziamento_anno.elem_id
left join cronoprogrammi_fpv
    on (capitoli_fpv.elem_code=cronoprogrammi_fpv.cronop_elem_code
    	AND capitoli_fpv.elem_code2=cronoprogrammi_fpv.cronop_elem_code2
        AND capitoli_fpv.elem_code3=cronoprogrammi_fpv.cronop_elem_code3)
left join cronoprogrammi_bozza
    on (capitoli_fpv.elem_code=cronoprogrammi_bozza.cronop_elem_code
    	AND capitoli_fpv.elem_code2=cronoprogrammi_bozza.cronop_elem_code2
        AND capitoli_fpv.elem_code3=cronoprogrammi_bozza.cronop_elem_code3),
exist_last_versione        ;            
          
raise notice 'fine OK';
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

CREATE OR REPLACE FUNCTION siac."BILR222_Allegato_B_Fondo_Pluri_vinc_Rend_capitolo_stanz_agg" (
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
  elem_id_fpv integer,
  bil_ele_code_fpv varchar,
  bil_ele_desc_fpv varchar,
  bil_ele_code2_fpv varchar,
  bil_ele_desc2_fpv varchar,
  fondo_plur_anno_prec_a numeric,
  spese_impe_anni_prec_b numeric,
  quota_fond_plur_anni_prec_c numeric,
  spese_da_impeg_anno1_d numeric,
  spese_da_impeg_anno2_e numeric,
  spese_da_impeg_anni_succ_f numeric,
  riacc_colonna_x numeric,
  riacc_colonna_y numeric,
  fondo_plur_anno_g numeric,
  fpv_stanziato_anno numeric,
  imp_cronoprogramma numeric
) AS
$body$
DECLARE


classifBilRec record;
var_fondo_plur_anno_prec_a numeric;
var_spese_impe_anni_prec_b numeric;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
annoPrec varchar;
annoProspInt integer;
annoBilInt integer;
conflagfpv boolean ;
a_dacapfpv boolean ;
h_dacapfpv boolean ;
flagretrocomp boolean ;

h_count integer :=0;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
id_bil INTEGER;

BEGIN

/*
	Funzione identica alla "BILR221_Allegato_B_Fondo_Pluriennale_vincolato_Rend_capitolo"
    fatta eccezione per il calcolo del campo "fondo_plur_anno_prec_a" che in questa 
    funzione tiene conto anche delle varizioni avvenute durante l'anno. 
    
*/
annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
annoPrec:= ((p_anno::INTEGER)-1)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione


annoBilInt=p_anno::INTEGER;

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';

var_fondo_plur_anno_prec_a=0;
var_spese_impe_anni_prec_b=0;
quota_fond_plur_anni_prec_c=0;
spese_da_impeg_anno1_d=0;
spese_da_impeg_anno2_e=0;
spese_da_impeg_anni_succ_f=0;
fondo_plur_anno_g=0;


select fnc_siac_random_user()
into	user_table;

select t_bil.bil_id
	into id_bil
from siac_t_bil t_bil,
	siac_t_periodo t_periodo
where t_bil.periodo_id=t_periodo.periodo_id
	and t_bil.ente_proprietario_id = p_ente_prop_id
    and t_periodo.anno= p_anno    
    and t_bil.data_cancellazione IS NULL
    and t_periodo.data_cancellazione IS NULL;
IF NOT FOUND THEN
	raise notice 'Codice del bilancio non trovato';
    return;
END IF;


        
return query  
	with strut_bilancio as(
     		select  *
            from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, p_anno,'') a
            where a.missione_code::integer <= 19),
    capitoli_fpv as(
    	select 	programma.classif_id programma_id,
			macroaggr.classif_id macroaggregato_id,
        	p_anno anno_bilancio,
       		capitolo.*
		from 
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
		where capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 	and
            programma.classif_tipo_id	=programma_tipo.classif_tipo_id and
            programma.classif_id	=r_capitolo_programma.classif_id and
            macroaggr.classif_tipo_id	=macroaggr_tipo.classif_tipo_id and
    		macroaggr.classif_id	=r_capitolo_macroaggr.classif_id and			     		 
    		capitolo.elem_id=r_capitolo_programma.elem_id	and
    		capitolo.elem_id=r_capitolo_macroaggr.elem_id	and
    		capitolo.elem_id		=	r_capitolo_stato.elem_id and
			r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id and
			capitolo.elem_id				=	r_cat_capitolo.elem_id	and
			r_cat_capitolo.elem_cat_id	=cat_del_capitolo.elem_cat_id and
            capitolo.bil_id 				= id_bil and
            capitolo.ente_proprietario_id	=	p_ente_prop_id	and
    		tipo_elemento.elem_tipo_code = elemTipoCode		and	
			programma_tipo.classif_tipo_code	='PROGRAMMA'  and		        
    		macroaggr_tipo.classif_tipo_code	='MACROAGGREGATO' and   
			stato_capitolo.elem_stato_code	=	'VA'	and
    		--cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC') and 
            cat_del_capitolo.elem_cat_code	in ('FPV','FPVC') and 
			programma_tipo.data_cancellazione			is null 	and
    		programma.data_cancellazione 				is null 	and
    		macroaggr_tipo.data_cancellazione	 		is null 	and
    		macroaggr.data_cancellazione 				is null 	and
    		tipo_elemento.data_cancellazione 			is null 	and
    		r_capitolo_programma.data_cancellazione 	is null 	and
    		r_capitolo_macroaggr.data_cancellazione 	is null 	and    		
    		stato_capitolo.data_cancellazione 			is null 	and 
    		r_capitolo_stato.data_cancellazione 		is null 	and
			cat_del_capitolo.data_cancellazione 		is null 	and
    		r_cat_capitolo.data_cancellazione 			is null 	and
			capitolo.data_cancellazione 				is null), 
fpv_stanziamento_anno as (               
select 	 capitolo.elem_id,
	sum(capitolo_importi.elem_det_importo) importo_fpv_stanz_anno
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_t_bil					t_bil,
            siac_t_periodo				t_periodo_bil,
            siac_d_bil_elem_tipo 		tipo_elemento,
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_r_bil_elem_class r_bil_elem_class,
            siac_t_class t_class, 
            siac_d_class_tipo d_class_tipo
where capitolo.elem_id = capitolo_importi.elem_id 
	and	capitolo.bil_id = t_bil.bil_id
	and t_periodo_bil.periodo_id =t_bil.periodo_id	
	and	capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id
	and	capitolo_importi.elem_det_tipo_id = capitolo_imp_tipo.elem_det_tipo_id 		
	and	capitolo_imp_periodo.periodo_id = capitolo_importi.periodo_id 
	and	capitolo.elem_id = r_capitolo_stato.elem_id			
	and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id
	and	capitolo.elem_id = r_cat_capitolo.elem_id				
	and	r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id	
    and d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
    and capitolo.elem_id = r_bil_elem_class.elem_id
    and r_bil_elem_class.classif_id = t_class.classif_id
	and capitolo_importi.ente_proprietario_id = p_ente_prop_id 					
	and	tipo_elemento.elem_tipo_code = elemTipoCode 
	and	t_periodo_bil.anno = p_anno	
	and	capitolo_imp_periodo.anno = p_anno	
	and	stato_capitolo.elem_stato_code = 'VA'								
	and	cat_del_capitolo.elem_cat_code in ('FPV','FPVC')
	and capitolo_imp_tipo.elem_det_tipo_code = 'STA'	
    and d_class_tipo.classif_tipo_code='PROGRAMMA'			
	and	capitolo_importi.data_cancellazione 		is null
	and	capitolo_imp_tipo.data_cancellazione 		is null
	and	capitolo_imp_periodo.data_cancellazione 	is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
	and	stato_capitolo.data_cancellazione 			is null 
	and	r_capitolo_stato.data_cancellazione 		is null
	and cat_del_capitolo.data_cancellazione 		is null
	and	r_cat_capitolo.data_cancellazione 			is null
	and t_bil.data_cancellazione 					is null
	and t_periodo_bil.data_cancellazione 			is null
    and r_bil_elem_class.data_cancellazione 		is null
    and t_class.data_cancellazione 					is null
    and d_class_tipo.data_cancellazione 		is null        
 GROUP BY capitolo.elem_id ),            
fpv_anno_prec_da_capitoli as (               
select 	 capitolo.elem_id,
		capitolo.elem_code, capitolo.elem_code2, capitolo.elem_code3,
	sum(capitolo_importi.elem_det_importo) importo_fpv_anno_prec
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_t_bil					t_bil,
            siac_t_periodo				t_periodo_bil,
            siac_d_bil_elem_tipo 		tipo_elemento,
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_r_bil_elem_class r_bil_elem_class,
            siac_t_class t_class, 
            siac_d_class_tipo d_class_tipo
where capitolo.elem_id = capitolo_importi.elem_id 
	and	capitolo.bil_id = t_bil.bil_id
	and t_periodo_bil.periodo_id =t_bil.periodo_id	
	and	capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id
	and	capitolo_importi.elem_det_tipo_id = capitolo_imp_tipo.elem_det_tipo_id 		
	and	capitolo_imp_periodo.periodo_id = capitolo_importi.periodo_id 
	and	capitolo.elem_id = r_capitolo_stato.elem_id			
	and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id
	and	capitolo.elem_id = r_cat_capitolo.elem_id				
	and	r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id	
    and d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
    and capitolo.elem_id = r_bil_elem_class.elem_id
    and r_bil_elem_class.classif_id = t_class.classif_id
	and capitolo_importi.ente_proprietario_id = p_ente_prop_id 					
	and	tipo_elemento.elem_tipo_code = elemTipoCode 
	and	t_periodo_bil.anno = annoPrec	--anno bilancio -1	
	and	capitolo_imp_periodo.anno = annoPrec	--anno bilancio -1		  	
	and	stato_capitolo.elem_stato_code = 'VA'								
	and	cat_del_capitolo.elem_cat_code in ('FPV','FPVC')
	and capitolo_imp_tipo.elem_det_tipo_code = 'STA'	
    and d_class_tipo.classif_tipo_code='PROGRAMMA'			
	and	capitolo_importi.data_cancellazione 		is null
	and	capitolo_imp_tipo.data_cancellazione 		is null
	and	capitolo_imp_periodo.data_cancellazione 	is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
	and	stato_capitolo.data_cancellazione 			is null 
	and	r_capitolo_stato.data_cancellazione 		is null
	and cat_del_capitolo.data_cancellazione 		is null
	and	r_cat_capitolo.data_cancellazione 			is null
	and t_bil.data_cancellazione 					is null
	and t_periodo_bil.data_cancellazione 			is null
    and r_bil_elem_class.data_cancellazione 		is null
    and t_class.data_cancellazione 					is null
    and d_class_tipo.data_cancellazione 		is null        
  GROUP BY capitolo.elem_id, capitolo.elem_code, capitolo.elem_code2, capitolo.elem_code3 ),
fpv_variaz_anno_prec as (
select	dettaglio_variazione.elem_id,
			capitolo.elem_code, capitolo.elem_code2, capitolo.elem_code3,
            sum(dettaglio_variazione.elem_det_importo) importo_var            	      	
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
            siac_t_bil                  bilancio ,
            siac_d_bil_elem_categoria 	cat_del_capitolo,
            siac_r_bil_elem_categoria 	r_cat_capitolo
  where 	r_variazione_stato.variazione_id =	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id  
    and 	r_cat_capitolo.elem_id = capitolo.elem_id
    and 	cat_del_capitolo.elem_cat_id = r_cat_capitolo.elem_cat_id
    and		testata_variazione.ente_proprietario_id				= p_ente_prop_id 
    and		anno_eserc.anno			= 	annoPrec
    and		tipologia_stato_var.variazione_stato_tipo_code not in ('D','A')
    and		tipo_capitolo.elem_tipo_code = 'CAP-UG'
    and	    tipo_elemento.elem_det_tipo_code in ('STA')
    and	    cat_del_capitolo.elem_cat_code in ('FPV','FPVC')
    and   	anno_importo.anno = annoPrec 
    and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null  
    and 	r_cat_capitolo.data_cancellazione			is null 
    and 	cat_del_capitolo.data_cancellazione			is null 
    group by 	dettaglio_variazione.elem_id,
    	capitolo.elem_code, capitolo.elem_code2, capitolo.elem_code3),
importi_anni_prec as (
select t_bil_elem.elem_id,
	sum(coalesce( r_movgest_ts.movgest_ts_importo ,0)) spese_impe_anni_prec    	
    from siac_t_movgest t_movgest,  
          siac_t_movgest_ts t_movgest_ts, siac_t_movgest_ts_det t_movgest_ts_det,
          siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, siac_t_bil_elem t_bil_elem, 
		  siac_r_movgest_bil_elem r_movgest_bil_elem,
          siac_r_movgest_ts_stato r_movgest_ts_stato, siac_d_movgest_stato d_movgest_stato,
          siac_r_bil_elem_class r_bil_elem_class,
          siac_t_class t_class, siac_d_class_tipo d_class_tipo, 
           siac_d_movgest_tipo d_mov_tipo,
           siac_r_movgest_ts r_movgest_ts, 
           siac_t_avanzovincolo t_avanzovincolo, 
           siac_d_avanzovincolo_tipo d_avanzovincolo_tipo
    where 
           t_movgest.movgest_id = t_movgest_ts.movgest_id  
          and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
          and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
          and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
          and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
          and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
          and r_bil_elem_class.classif_id = t_class.classif_id
          and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
          and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id
          and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
          and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id 
          and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
          and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id 
		  and t_movgest.bil_id = id_bil
          and t_movgest.ente_proprietario_id= p_ente_prop_id      
          and d_class_tipo.classif_tipo_code='PROGRAMMA'
          and t_movgest.movgest_anno =  annoBilInt
          and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='I'
          and d_movgest_stato.movgest_stato_code in ('D', 'N')
          and d_mov_tipo.movgest_tipo_code='I' --Impegni      
          and d_avanzovincolo_tipo.avav_tipo_code like'FPV%'  
          and t_movgest_ts.movgest_ts_id_padre is NULL              
          and r_movgest_bil_elem.data_cancellazione is null
          and r_movgest_bil_elem.validita_fine is NULL          
          and r_movgest_ts_stato.data_cancellazione is null
          and r_movgest_ts_stato.validita_fine is null
          and d_mov_tipo.data_cancellazione is null
          and d_mov_tipo.validita_fine is null              
          and r_bil_elem_class.data_cancellazione is null
          and r_bil_elem_class.validita_fine is null
          and t_movgest_ts_det.data_cancellazione is null
          and t_movgest_ts_det.validita_fine is null
          and r_movgest_ts.avav_id=t_avanzovincolo.avav_id                                  
          and r_movgest_ts.data_cancellazione is null
          and r_movgest_ts.validita_fine is null
		  and t_bil_elem.data_cancellazione is null
    group by t_bil_elem.elem_id ),
riaccert_colonna_x as (
--Riaccertamento degli impegni di cui alla lettera b) effettuata nel corso dell'eserczio N (cd. economie di impegno)
--riduzioni su impegni di competenza con anno atto minore dell'anno di bilancio 
--e coperti anche solo parzialmente da fondo   
	select t_bil_elem.elem_id,
		sum(COALESCE(t_movgest_ts_det_mod.movgest_ts_det_importo,0)*-1) riacc_colonna_x                
      from siac_r_modifica_stato r_modifica_stato, 
      siac_t_movgest_ts_det_mod t_movgest_ts_det_mod,
      siac_t_movgest_ts t_movgest_ts, siac_d_modifica_stato d_modifica_stato,
      siac_t_movgest t_movgest, siac_d_movgest_tipo d_movgest_tipo, 
      siac_t_modifica t_modifica, siac_d_modifica_tipo d_modifica_tipo,
      siac_t_bil_elem t_bil_elem, siac_r_movgest_bil_elem r_movgest_bil_elem,
      siac_r_bil_elem_class r_bil_elem_class, 
      siac_t_class t_class, siac_d_class_tipo d_class_tipo,
      siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
      siac_t_atto_amm t_atto_amm ,
      siac_r_movgest_ts_stato r_movgest_ts_stato, 
      siac_d_movgest_stato d_movgest_stato    
      where t_movgest_ts_det_mod.mod_stato_r_id=r_modifica_stato.mod_stato_r_id
      and t_movgest_ts_det_mod.movgest_ts_id = t_movgest_ts.movgest_ts_id
      and t_movgest.movgest_tipo_id=d_movgest_tipo.movgest_tipo_id
      and d_modifica_stato.mod_stato_id=r_modifica_stato.mod_stato_id      
      and t_movgest.movgest_id=t_movgest_ts.movgest_id
      and t_modifica.mod_id=r_modifica_stato.mod_id
      and t_modifica.mod_tipo_id=d_modifica_tipo.mod_tipo_id
      and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
      and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
      and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
      and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
      and r_bil_elem_class.elem_id=t_bil_elem.elem_id
      and r_bil_elem_class.classif_id=t_class.classif_id
      and r_movgest_ts_stato.movgest_ts_id = t_movgest_ts.movgest_ts_id
      and r_movgest_ts_stato.movgest_stato_id = d_movgest_stato.movgest_stato_id      
      and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
      and t_movgest.bil_id=id_bil
      and r_modifica_stato.ente_proprietario_id=p_ente_prop_id
      and d_modifica_stato.mod_stato_code='V'
      and d_movgest_tipo.movgest_tipo_code='I'
      and 
      (d_modifica_tipo.mod_tipo_code like  'ECON%'
         or d_modifica_tipo.mod_tipo_desc like  'ROR%')
      and d_modifica_tipo.mod_tipo_code <> 'REIMP'
      and d_class_tipo.classif_tipo_code='PROGRAMMA'
      and d_movgest_stato.movgest_stato_code in ('D', 'N')
      and t_movgest.movgest_anno = annoBilInt 
      and r_movgest_ts_stato.data_cancellazione is NULL
      and r_movgest_ts_stato.validita_fine is null
      and t_movgest_ts.movgest_ts_id_padre is null
      and r_modifica_stato.data_cancellazione is null
      and r_modifica_stato.validita_fine is null
      and t_movgest_ts_det_mod.data_cancellazione is null
      and t_movgest_ts_det_mod.validita_fine is null
      and t_movgest_ts.data_cancellazione is null
      and t_movgest_ts.validita_fine is null
      and d_modifica_stato.data_cancellazione is null
      and d_modifica_stato.validita_fine is null
      and t_movgest.data_cancellazione is null
      and t_movgest.validita_fine is null
      and d_movgest_tipo.data_cancellazione is null
      and d_movgest_tipo.validita_fine is null
      and t_modifica.data_cancellazione is null
      and t_modifica.validita_fine is null
      and d_modifica_tipo.data_cancellazione is null
      and d_modifica_tipo.validita_fine is null
      and t_bil_elem.data_cancellazione is null
      and t_bil_elem.validita_fine is null
      and r_movgest_bil_elem.data_cancellazione is null
      and r_movgest_bil_elem.validita_fine is null
      and r_bil_elem_class.data_cancellazione is null
      and r_bil_elem_class.validita_fine is null
      and t_class.data_cancellazione is null
      and t_class.validita_fine is null
      and d_class_tipo.data_cancellazione is null
      and d_class_tipo.validita_fine is null
      and t_atto_amm.data_cancellazione is null
      and t_atto_amm.validita_fine is null      
      and r_movgest_ts_atto_amm.data_cancellazione is null
      and r_movgest_ts_atto_amm.validita_fine is null
      and d_movgest_stato.data_cancellazione is null
      and d_movgest_stato.validita_fine is null      
      and exists (select 
          		1 
                from siac_r_movgest_ts r_movgest_ts, 
            	siac_t_avanzovincolo t_avanzovincolo, 
                siac_d_avanzovincolo_tipo d_avanzovincolo_tipo
			where r_movgest_ts.avav_id=t_avanzovincolo.avav_id     
                and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id 
                and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                and d_avanzovincolo_tipo.avav_tipo_code like'FPV%'                 
                and r_movgest_ts.data_cancellazione is null
                and r_movgest_ts.validita_fine is null 
               )
      group by t_bil_elem.elem_id)  ,
riaccert_colonna_y as (
--Riaccertamento degli impegni di cui alla lettera b) effettuata nel corso dell'eserczio N (cd. economie di impegno) su impegni pluriennali finanziati dal FPV e imputati agli esercizi successivi  a N
--riduzioni su impegni di competenza con anno atto minore dell'anno di bilancio 
--e coperti anche solo parzialmente da fondo 
select t_bil_elem.elem_id,
	sum(COALESCE(t_movgest_ts_det_mod.movgest_ts_det_importo,0)*-1) riacc_colonna_y
      from siac_r_modifica_stato r_modifica_stato, 
      siac_t_movgest_ts_det_mod t_movgest_ts_det_mod,
      siac_t_movgest_ts t_movgest_ts, 
      siac_d_modifica_stato d_modifica_stato,
      siac_t_movgest t_movgest, siac_d_movgest_tipo d_movgest_tipo,  
      siac_t_modifica t_modifica, siac_d_modifica_tipo d_modifica_tipo,
      siac_t_bil_elem t_bil_elem, siac_r_movgest_bil_elem r_movgest_bil_elem,
      siac_r_bil_elem_class r_bil_elem_class, 
      siac_t_class t_class, siac_d_class_tipo d_class_tipo,
      siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
      siac_t_atto_amm t_atto_amm ,
      siac_r_movgest_ts_stato r_movgest_ts_stato, 
      siac_d_movgest_stato d_movgest_stato    
      where t_movgest_ts_det_mod.mod_stato_r_id=r_modifica_stato.mod_stato_r_id
      and t_movgest_ts_det_mod.movgest_ts_id = t_movgest_ts.movgest_ts_id
      and t_movgest.movgest_tipo_id=d_movgest_tipo.movgest_tipo_id
      and d_modifica_stato.mod_stato_id=r_modifica_stato.mod_stato_id      
      and t_movgest.movgest_id=t_movgest_ts.movgest_id
      and t_modifica.mod_id=r_modifica_stato.mod_id
      and t_modifica.mod_tipo_id=d_modifica_tipo.mod_tipo_id      
      and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
      and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
      and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
      and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
      and r_bil_elem_class.elem_id=t_bil_elem.elem_id
      and r_bil_elem_class.classif_id=t_class.classif_id
      and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id    
      and r_movgest_ts_stato.movgest_ts_id = t_movgest_ts.movgest_ts_id
      and r_movgest_ts_stato.movgest_stato_id = d_movgest_stato.movgest_stato_id  
      and t_movgest.bil_id= id_bil
      and r_modifica_stato.ente_proprietario_id=p_ente_prop_id
      and t_movgest.movgest_anno > annoBilInt 
      and d_modifica_stato.mod_stato_code='V'
      and d_movgest_tipo.movgest_tipo_code='I'
      and 
      (d_modifica_tipo.mod_tipo_code like  'ECON%'
         or d_modifica_tipo.mod_tipo_desc like  'ROR%')
      and d_modifica_tipo.mod_tipo_code <> 'REIMP'
      and d_class_tipo.classif_tipo_code='PROGRAMMA'
      and d_movgest_stato.movgest_stato_code in ('D', 'N')
      and r_movgest_ts_stato.data_cancellazione is NULL
      and r_movgest_ts_stato.validita_fine is null
      and t_movgest_ts.movgest_ts_id_padre is null
      and r_modifica_stato.data_cancellazione is null
      and r_modifica_stato.validita_fine is null
      and t_movgest_ts_det_mod.data_cancellazione is null
      and t_movgest_ts_det_mod.validita_fine is null
      and t_movgest_ts.data_cancellazione is null
      and t_movgest_ts.validita_fine is null
      and d_modifica_stato.data_cancellazione is null
      and d_modifica_stato.validita_fine is null
      and t_movgest.data_cancellazione is null
      and t_movgest.validita_fine is null
      and d_movgest_tipo.data_cancellazione is null
      and d_movgest_tipo.validita_fine is null
      and t_modifica.data_cancellazione is null
      and t_modifica.validita_fine is null
      and d_modifica_tipo.data_cancellazione is null
      and d_modifica_tipo.validita_fine is null
      and t_bil_elem.data_cancellazione is null
      and t_bil_elem.validita_fine is null
      and r_movgest_bil_elem.data_cancellazione is null
      and r_movgest_bil_elem.validita_fine is null
      and r_bil_elem_class.data_cancellazione is null
      and r_bil_elem_class.validita_fine is null
      and t_class.data_cancellazione is null
      and t_class.validita_fine is null
      and d_class_tipo.data_cancellazione is null
      and d_class_tipo.validita_fine is null
      and r_movgest_ts_atto_amm.data_cancellazione is null
      and r_movgest_ts_atto_amm.validita_fine is null
      and t_atto_amm.data_cancellazione is null
      and t_atto_amm.validita_fine is null
      and d_movgest_stato.data_cancellazione is null
      and d_movgest_stato.validita_fine is null
      and exists (select 
          		1 
                from siac_r_movgest_ts r_movgest_ts, 
            	siac_t_avanzovincolo t_avanzovincolo, 
                siac_d_avanzovincolo_tipo d_avanzovincolo_tipo
			where r_movgest_ts.avav_id=t_avanzovincolo.avav_id     
                and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id 
                and d_avanzovincolo_tipo.avav_tipo_code like'FPV%' 
                and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                and r_movgest_ts.data_cancellazione is null
                and r_movgest_ts.validita_fine is null )
      group by t_bil_elem.elem_id) ,
impegni_anno1_d as(
      -- Spese impegnate nell'esercizio N con imputazione all'esercizio N+1 e 
      -- coperte dal fondo pluriennale vincolato
      -- impegni anno + 1 con atto nell'anno legati ad accertamenti 
      -- di competenza oppure ad avanzo
select x.elem_id,
	sum(x.spese_da_impeg_anno1_d) as spese_da_impeg_anno1_d   
from (
               (
              select t_bil_elem.elem_id,
              	sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anno1_d              
                        from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
                        siac_t_atto_amm t_atto_amm, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, siac_t_movgest_ts acc_ts,
                        siac_t_movgest acc,
                        siac_r_movgest_ts_stato rstacc,
                        siac_d_movgest_stato dstacc
                where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id
                        and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id 
                        and r_movgest_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_id = acc.movgest_id
                        and rstacc.movgest_ts_id=acc_ts.movgest_ts_id
                        and rstacc.movgest_stato_id=dstacc.movgest_stato_id
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and t_movgest.bil_id =id_bil
                        and t_movgest.ente_proprietario_id= p_ente_prop_id      
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno = annoBilInt + 1
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        and dstacc.movgest_stato_code in ('D', 'N')   
                        and acc.movgest_anno = annoBilInt  
                        and t_movgest_ts.movgest_ts_id_padre is NULL                            
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_movgest_ts_atto_amm.data_cancellazione is null
                        and r_movgest_ts_atto_amm.validita_fine is null                        
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null                         
                        and acc_ts.movgest_ts_id_padre is null                        
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null                                                
                        and rstacc.validita_fine is null
                        and rstacc.data_cancellazione is null   
                        and t_movgest.data_cancellazione is null 
                        and t_movgest.validita_fine is null  
                        and t_bil_elem.data_cancellazione is null 
                        and t_bil_elem.validita_fine is null  
                        and t_class.data_cancellazione is null 
                        and t_class.validita_fine is null                                                                                                           
              	group by t_bil_elem.elem_id)
              union(
              select t_bil_elem.elem_id,
              		sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anno1_d
                from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
                        siac_t_atto_amm t_atto_amm, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, 
                        siac_t_avanzovincolo t_avanzovincolo, 
                        siac_d_avanzovincolo_tipo d_avanzovincolo_tipo 
                      where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id
                        and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
                        and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id
                        and r_movgest_ts.avav_id=t_avanzovincolo.avav_id
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and t_movgest.bil_id =id_bil
                        and t_movgest.ente_proprietario_id = p_ente_prop_id       
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno = annoBilInt + 1
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        and d_avanzovincolo_tipo.avav_tipo_code = 'AAM'
                        and t_movgest_ts.movgest_ts_id_padre is NULL                             
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_movgest_ts_atto_amm.data_cancellazione is null
                        and r_movgest_ts_atto_amm.validita_fine is null                                                                                                       
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null 
                        and t_movgest.data_cancellazione is null
                        and t_movgest.validita_fine is null                        
                   group by t_bil_elem.elem_id
              )--- Impegni da riaccertamento - reimputazione nel bilancio successivo 
              union(
              select t_bil_elem.elem_id,
              		sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anno1_d
                        from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, 
                        siac_t_avanzovincolo t_avanzovincolo, 
                        siac_d_avanzovincolo_tipo d_avanzovincolo_tipo 
                      where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id                        
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_ts.avav_id=t_avanzovincolo.avav_id     
                        and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id 
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
                        and t_movgest.bil_id = id_bil
                        and t_movgest.ente_proprietario_id= p_ente_prop_id     
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno = annoBilInt + 1
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code <> 'A'
                        and d_mov_tipo.movgest_tipo_code='I'
                        and d_avanzovincolo_tipo.avav_tipo_code like'FPV%' 
                        and t_movgest_ts.movgest_ts_id_padre is NULL                             
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null                                                                         
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null 
                        and t_movgest.data_cancellazione is null
                        and t_movgest.validita_fine is null 
                        and exists (
                        	select 1
                            from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
                                 fase_bil_t_reimputazione fasereimp, siac_t_bil bilprec, siac_t_periodo pprec
                            where tipo.ente_proprietario_id= t_movgest.ente_proprietario_id                             
                            and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id                            
                            and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
                            and   fasereimp.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
                            and   fasereimp.bil_id=bilprec.bil_id
                            and   bilprec.periodo_id = pprec.periodo_id
                            and   fasereimp.movgestnew_id = t_movgest.movgest_id                            
                            and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
                            and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP'
                            and   fase.fase_bil_elab_esito='OK'
                            and   pprec.anno=p_anno                            
                            and   fase.data_cancellazione is null
                            and   fase.validita_fine is null
                            and   tipo.data_cancellazione is null
                            and   tipo.validita_fine is null
                        )
                        and not exists 
                        (
                           select 
                             1
                             from fase_bil_t_reimputazione_vincoli vreimp, siac_r_movgest_ts rold,
                             siac_r_movgest_ts rnew, siac_t_avanzovincolo avold, siac_d_avanzovincolo_tipo davold
                             where 
                             vreimp.movgest_ts_r_new_id =  r_movgest_ts.movgest_ts_r_id 
                             and vreimp.movgest_ts_r_id=rold.movgest_ts_r_id
                             and vreimp.movgest_ts_r_new_id = rnew.movgest_ts_r_id
                             and avold.avav_id=rold.avav_id
                             and avold.avav_tipo_id = davold.avav_tipo_id
                             and davold.avav_tipo_code like '%FPV%'
                        )
                        group by t_bil_elem.elem_id
              )    
              ) as x
                group by x.elem_id ),
impegni_anno2_e as(
      -- Spese impegnate nell'esercizio N con imputazione all'esercizio N+1 e 
      -- coperte dal fondo pluriennale vincolato
      -- impegni anno + 1 con atto nell'anno legati ad accertamenti 
      -- di competenza oppure ad avanzo
select x.elem_id,
	sum(x.spese_da_impeg_anno2_e) as spese_da_impeg_anno2_e   
from (
               (
              select t_bil_elem.elem_id,
              	sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anno2_e              
                        from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
                        siac_t_atto_amm t_atto_amm, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, siac_t_movgest_ts acc_ts,
                        siac_t_movgest acc,
                        siac_r_movgest_ts_stato rstacc,
                        siac_d_movgest_stato dstacc
                where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id
                        and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id 
                        and r_movgest_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_id = acc.movgest_id
                        and rstacc.movgest_ts_id=acc_ts.movgest_ts_id
                        and rstacc.movgest_stato_id=dstacc.movgest_stato_id
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and t_movgest.bil_id =id_bil
                        and t_movgest.ente_proprietario_id= p_ente_prop_id      
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno = annoBilInt + 2
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        and dstacc.movgest_stato_code in ('D', 'N')   
                        and acc.movgest_anno = annoBilInt  
                        and t_movgest_ts.movgest_ts_id_padre is NULL                            
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_movgest_ts_atto_amm.data_cancellazione is null
                        and r_movgest_ts_atto_amm.validita_fine is null                        
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null                         
                        and acc_ts.movgest_ts_id_padre is null                        
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null                                                
                        and rstacc.validita_fine is null
                        and rstacc.data_cancellazione is null   
                        and t_movgest.data_cancellazione is null 
                        and t_movgest.validita_fine is null  
                        and t_bil_elem.data_cancellazione is null 
                        and t_bil_elem.validita_fine is null  
                        and t_class.data_cancellazione is null 
                        and t_class.validita_fine is null                                                                                                           
              	group by t_bil_elem.elem_id)
              union(
              select t_bil_elem.elem_id,
              		sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anno2_e
                from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
                        siac_t_atto_amm t_atto_amm, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, 
                        siac_t_avanzovincolo t_avanzovincolo, 
                        siac_d_avanzovincolo_tipo d_avanzovincolo_tipo 
                      where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id
                        and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
                        and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id
                        and r_movgest_ts.avav_id=t_avanzovincolo.avav_id
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and t_movgest.bil_id =id_bil
                        and t_movgest.ente_proprietario_id = p_ente_prop_id       
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno = annoBilInt + 2
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        and d_avanzovincolo_tipo.avav_tipo_code = 'AAM'
                        and t_movgest_ts.movgest_ts_id_padre is NULL                             
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_movgest_ts_atto_amm.data_cancellazione is null
                        and r_movgest_ts_atto_amm.validita_fine is null                                                                                                       
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null 
                        and t_movgest.data_cancellazione is null
                        and t_movgest.validita_fine is null                        
                   group by t_bil_elem.elem_id
              )--- Impegni da riaccertamento - reimputazione nel bilancio successivo 
              union(
              select t_bil_elem.elem_id,
              		sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anno2_e
                        from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, 
                        siac_t_avanzovincolo t_avanzovincolo, 
                        siac_d_avanzovincolo_tipo d_avanzovincolo_tipo 
                      where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id                        
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_ts.avav_id=t_avanzovincolo.avav_id     
                        and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id 
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
                        and t_movgest.bil_id = id_bil
                        and t_movgest.ente_proprietario_id= p_ente_prop_id     
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno = annoBilInt + 2
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code <> 'A'
                        and d_mov_tipo.movgest_tipo_code='I'
                        and d_avanzovincolo_tipo.avav_tipo_code like'FPV%' 
                        and t_movgest_ts.movgest_ts_id_padre is NULL                             
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null                                                                         
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null 
                        and t_movgest.data_cancellazione is null
                        and t_movgest.validita_fine is null 
                        and exists (
                        	select 1
                            from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
                                 fase_bil_t_reimputazione fasereimp, siac_t_bil bilprec, siac_t_periodo pprec
                            where tipo.ente_proprietario_id= t_movgest.ente_proprietario_id                             
                            and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id                            
                            and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
                            and   fasereimp.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
                            and   fasereimp.bil_id=bilprec.bil_id
                            and   bilprec.periodo_id = pprec.periodo_id
                            and   fasereimp.movgestnew_id = t_movgest.movgest_id                            
                            and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
                            and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP'
                            and   fase.fase_bil_elab_esito='OK'
                            and   pprec.anno=p_anno                            
                            and   fase.data_cancellazione is null
                            and   fase.validita_fine is null
                            and   tipo.data_cancellazione is null
                            and   tipo.validita_fine is null
                        )
                        and not exists 
                        (
                           select 
                             1
                             from fase_bil_t_reimputazione_vincoli vreimp, siac_r_movgest_ts rold,
                             siac_r_movgest_ts rnew, siac_t_avanzovincolo avold, siac_d_avanzovincolo_tipo davold
                             where 
                             vreimp.movgest_ts_r_new_id =  r_movgest_ts.movgest_ts_r_id 
                             and vreimp.movgest_ts_r_id=rold.movgest_ts_r_id
                             and vreimp.movgest_ts_r_new_id = rnew.movgest_ts_r_id
                             and avold.avav_id=rold.avav_id
                             and avold.avav_tipo_id = davold.avav_tipo_id
                             and davold.avav_tipo_code like '%FPV%'
                        )
                        group by t_bil_elem.elem_id
              )    
              ) as x
                group by x.elem_id ),
impegni_annisucc_f as(
      -- Spese impegnate nell'esercizio N con imputazione all'esercizio N+1 e 
      -- coperte dal fondo pluriennale vincolato
      -- impegni anno + 1 con atto nell'anno legati ad accertamenti 
      -- di competenza oppure ad avanzo
select x.elem_id,
	sum(x.spese_da_impeg_anni_succ_f) as spese_da_impeg_anni_succ_f   
from (
               (
              select t_bil_elem.elem_id,
              	sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anni_succ_f              
                        from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
                        siac_t_atto_amm t_atto_amm, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, siac_t_movgest_ts acc_ts,
                        siac_t_movgest acc,
                        siac_r_movgest_ts_stato rstacc,
                        siac_d_movgest_stato dstacc
                where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id
                        and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id 
                        and r_movgest_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_id = acc.movgest_id
                        and rstacc.movgest_ts_id=acc_ts.movgest_ts_id
                        and rstacc.movgest_stato_id=dstacc.movgest_stato_id
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and t_movgest.bil_id =id_bil
                        and t_movgest.ente_proprietario_id= p_ente_prop_id      
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno > annoBilInt + 2
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        and dstacc.movgest_stato_code in ('D', 'N')   
                        and acc.movgest_anno = annoBilInt  
                        and t_movgest_ts.movgest_ts_id_padre is NULL                            
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_movgest_ts_atto_amm.data_cancellazione is null
                        and r_movgest_ts_atto_amm.validita_fine is null                        
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null                         
                        and acc_ts.movgest_ts_id_padre is null                        
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null                                                
                        and rstacc.validita_fine is null
                        and rstacc.data_cancellazione is null   
                        and t_movgest.data_cancellazione is null 
                        and t_movgest.validita_fine is null  
                        and t_bil_elem.data_cancellazione is null 
                        and t_bil_elem.validita_fine is null  
                        and t_class.data_cancellazione is null 
                        and t_class.validita_fine is null                                                                                                           
              	group by t_bil_elem.elem_id)
              union(
              select t_bil_elem.elem_id,
              		sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anni_succ_f
                from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
                        siac_t_atto_amm t_atto_amm, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, 
                        siac_t_avanzovincolo t_avanzovincolo, 
                        siac_d_avanzovincolo_tipo d_avanzovincolo_tipo 
                      where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id
                        and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
                        and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id
                        and r_movgest_ts.avav_id=t_avanzovincolo.avav_id
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and t_movgest.bil_id =id_bil
                        and t_movgest.ente_proprietario_id = p_ente_prop_id       
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno > annoBilInt + 2
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        and d_avanzovincolo_tipo.avav_tipo_code = 'AAM'
                        and t_movgest_ts.movgest_ts_id_padre is NULL                             
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_movgest_ts_atto_amm.data_cancellazione is null
                        and r_movgest_ts_atto_amm.validita_fine is null                                                                                                       
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null 
                        and t_movgest.data_cancellazione is null
                        and t_movgest.validita_fine is null                        
                   group by t_bil_elem.elem_id
              )--- Impegni da riaccertamento - reimputazione nel bilancio successivo 
              union(
              select t_bil_elem.elem_id,
              		sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anni_succ_f
                        from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, 
                        siac_t_avanzovincolo t_avanzovincolo, 
                        siac_d_avanzovincolo_tipo d_avanzovincolo_tipo 
                      where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id                        
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_ts.avav_id=t_avanzovincolo.avav_id     
                        and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id 
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
                        and t_movgest.bil_id = id_bil
                        and t_movgest.ente_proprietario_id= p_ente_prop_id     
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno > annoBilInt + 2
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code <> 'A'
                        and d_mov_tipo.movgest_tipo_code='I'
                        and d_avanzovincolo_tipo.avav_tipo_code like'FPV%' 
                        and t_movgest_ts.movgest_ts_id_padre is NULL                             
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null                                                                         
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null 
                        and t_movgest.data_cancellazione is null
                        and t_movgest.validita_fine is null 
                        and exists (
                        	select 1
                            from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
                                 fase_bil_t_reimputazione fasereimp, siac_t_bil bilprec, siac_t_periodo pprec
                            where tipo.ente_proprietario_id= t_movgest.ente_proprietario_id                             
                            and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id                            
                            and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
                            and   fasereimp.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
                            and   fasereimp.bil_id=bilprec.bil_id
                            and   bilprec.periodo_id = pprec.periodo_id
                            and   fasereimp.movgestnew_id = t_movgest.movgest_id                            
                            and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
                            and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP'
                            and   fase.fase_bil_elab_esito='OK'
                            and   pprec.anno=p_anno                            
                            and   fase.data_cancellazione is null
                            and   fase.validita_fine is null
                            and   tipo.data_cancellazione is null
                            and   tipo.validita_fine is null
                        )
                        and not exists 
                        (
                           select 
                             1
                             from fase_bil_t_reimputazione_vincoli vreimp, siac_r_movgest_ts rold,
                             siac_r_movgest_ts rnew, siac_t_avanzovincolo avold, siac_d_avanzovincolo_tipo davold
                             where 
                             vreimp.movgest_ts_r_new_id =  r_movgest_ts.movgest_ts_r_id 
                             and vreimp.movgest_ts_r_id=rold.movgest_ts_r_id
                             and vreimp.movgest_ts_r_new_id = rnew.movgest_ts_r_id
                             and avold.avav_id=rold.avav_id
                             and avold.avav_tipo_id = davold.avav_tipo_id
                             and davold.avav_tipo_code like '%FPV%'
                        )
                        group by t_bil_elem.elem_id
              )    
              ) as x
                group by x.elem_id ),
/* Per la gestione degli importi del cronoprogramma, come da indicazioni di Troiano, 
		occorre:
	- Prendere i dati dei progetti relativi all'ultimo cronoprogrogramma (data_creazione)
      con flag "usato_per_fpv" = true.
    - Se non esiste prendere i dati dell'ultimo cronoprogramma in bozza cioe' con
      "usato_per_fpv" = false i cui progetti non  abbiano impegni collegati.

*/                
 cronoprogrammi_fpv as (select cronop.* from 
 		(select a.cronop_id, a.cronop_code, d.cronop_elem_code,
			d.cronop_elem_code2, d.cronop_elem_code3,
    		COALESCE(sum(e.cronop_elem_det_importo),0)::numeric importo_crono			
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d,          	
          siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where  pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.periodo_id = f.periodo_id
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and pr.ente_proprietario_id=p_ente_prop_id
          and c.anno = p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = true          
          and clt2.classif_tipo_code='PROGRAMMA'        
          and stct.cronop_stato_code='VA'          
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null
          group by a.cronop_id, a.cronop_code, 
          d.cronop_elem_code,
	d.cronop_elem_code2,d.cronop_elem_code3) cronop,
 		(select t_cronop.cronop_id, 
    max(t_cronop.data_creazione) max_data_creazione
    from siac_t_cronop t_cronop, 
    	siac_t_bil t_bil, siac_t_periodo t_periodo
    where t_cronop.bil_id=t_bil.bil_id
    	and t_bil.periodo_id=t_periodo.periodo_id
        and t_cronop.ente_proprietario_id=p_ente_prop_id
        and t_periodo.anno=p_anno
        and t_cronop.usato_per_fpv::boolean=true
        and t_cronop.data_cancellazione IS NULL
        and t_bil.data_cancellazione IS NULL
        and t_periodo.data_cancellazione IS NULL
    group by t_cronop.cronop_id
   order by max_data_creazione DESC
   limit 1) id_cronop_last_versione 
where id_cronop_last_versione.cronop_id =  cronop.cronop_id ),
cronoprogrammi_bozza as(
	select cronop_bozza.* from 
    (select a.cronop_id, a.cronop_code, d.cronop_elem_code,
			d.cronop_elem_code2, d.cronop_elem_code3,
    		COALESCE(sum(e.cronop_elem_det_importo),0)::numeric importo_crono			
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d,          	
          siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where  pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.periodo_id = f.periodo_id
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and pr.ente_proprietario_id=p_ente_prop_id
          and c.anno = p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = false          
          and clt2.classif_tipo_code='PROGRAMMA'        
          and stct.cronop_stato_code='VA'          
          and stprt.programma_stato_code='VA'
          and pr.programma_id not in (
        	select r_movgest_ts_programma.programma_id
            	from siac_r_movgest_ts_programma r_movgest_ts_programma
            	where r_movgest_ts_programma.ente_proprietario_id=p_ente_prop_id
                	and r_movgest_ts_programma.data_cancellazione IS NULL
                    and r_movgest_ts_programma.validita_fine IS NULL)
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null
          group by a.cronop_id, a.cronop_code, 
          d.cronop_elem_code,
	d.cronop_elem_code2,d.cronop_elem_code3) cronop_bozza,  
    (select t_cronop.cronop_id, 
    max(t_cronop.data_creazione) max_data_creazione
    from siac_t_cronop t_cronop, 
    	siac_t_bil t_bil, siac_t_periodo t_periodo,
        siac_t_programma t_programma
    where t_cronop.bil_id=t_bil.bil_id
    	and t_bil.periodo_id=t_periodo.periodo_id
        and t_programma.programma_id= t_cronop.programma_id
        and t_cronop.ente_proprietario_id=p_ente_prop_id
        and t_periodo.anno=p_anno
        and t_cronop.usato_per_fpv::boolean=false
        and t_cronop.data_cancellazione IS NULL
        and t_bil.data_cancellazione IS NULL
        and t_periodo.data_cancellazione IS NULL
       and t_programma.programma_id not in (
        	select r_movgest_ts_programma.programma_id
            	from siac_r_movgest_ts_programma r_movgest_ts_programma
            	where r_movgest_ts_programma.ente_proprietario_id=p_ente_prop_id
                	and r_movgest_ts_programma.data_cancellazione IS NULL
                    and r_movgest_ts_programma.validita_fine IS NULL)
    group by t_cronop.cronop_id
   order by max_data_creazione DESC
   limit 1) id_cronop_bozza 
where id_cronop_bozza.cronop_id =  cronop_bozza.cronop_id ),
exist_last_versione as (select count(*) last_version
    from siac_t_cronop t_cronop, 
    	siac_t_bil t_bil, siac_t_periodo t_periodo
    where t_cronop.bil_id=t_bil.bil_id
    	and t_bil.periodo_id=t_periodo.periodo_id
        and t_cronop.ente_proprietario_id=p_ente_prop_id
        and t_periodo.anno=p_anno
        and t_cronop.usato_per_fpv::boolean=true
        and t_cronop.data_cancellazione IS NULL
        and t_bil.data_cancellazione IS NULL
        and t_periodo.data_cancellazione IS NULL)               
select 
p_anno::varchar  bil_anno ,
''::varchar  missione_tipo_code ,
strut_bilancio.missione_tipo_desc ,
strut_bilancio.missione_code ,
strut_bilancio.missione_desc ,
''::varchar programma_tipo_code ,
strut_bilancio.programma_tipo_desc ,
strut_bilancio.programma_code ,
strut_bilancio.programma_desc ,
capitoli_fpv.elem_id::integer elem_id_fpv,
capitoli_fpv.elem_code::varchar bil_ele_code_fpv,
capitoli_fpv.elem_desc::varchar bil_ele_desc_fpv,
capitoli_fpv.elem_code2::varchar bil_ele_code2_fpv,
capitoli_fpv.elem_desc2::varchar bil_ele_desc2_fpv,
COALESCE(fpv_anno_prec_da_capitoli.importo_fpv_anno_prec,0) +
	COALESCE(fpv_variaz_anno_prec.importo_var,0)::numeric fondo_plur_anno_prec_a,
COALESCE(importi_anni_prec.spese_impe_anni_prec,0)::numeric spese_impe_anni_prec_b,
COALESCE(fpv_anno_prec_da_capitoli.importo_fpv_anno_prec,0) -
	COALESCE(importi_anni_prec.spese_impe_anni_prec,0) -
    COALESCE(riaccert_colonna_x.riacc_colonna_x,0) -
    COALESCE(riaccert_colonna_y.riacc_colonna_y,0)::numeric quota_fond_plur_anni_prec_c,
COALESCE(impegni_anno1_d.spese_da_impeg_anno1_d,0)::numeric spese_da_impeg_anno1_d,
COALESCE(impegni_anno2_e.spese_da_impeg_anno2_e,0)::numeric spese_da_impeg_anno2_e,
COALESCE(impegni_annisucc_f.spese_da_impeg_anni_succ_f,0)::numeric spese_da_impeg_anni_succ_f,
COALESCE(riaccert_colonna_x.riacc_colonna_x,0)::numeric riacc_colonna_x,
COALESCE(riaccert_colonna_y.riacc_colonna_y,0)::numeric riacc_colonna_y,
COALESCE(impegni_anno1_d.spese_da_impeg_anno1_d,0) +
	COALESCE(impegni_anno2_e.spese_da_impeg_anno2_e,0) +
    COALESCE(impegni_annisucc_f.spese_da_impeg_anni_succ_f,0)::numeric fondo_plur_anno_g,
COALESCE(fpv_stanziamento_anno.importo_fpv_stanz_anno,0)::numeric fpv_stanziato_anno,
	--se NON esiste una versione con "usato_per_fpv" = true prendo i dati di
    --cronoprogramma in BOZZA, altrimenti quelli della versione approvata.
CASE WHEN exist_last_versione.last_version = 0
	THEN COALESCE(cronoprogrammi_bozza.importo_crono,0)
    ELSE COALESCE(cronoprogrammi_fpv.importo_crono,0) end ::numeric imp_cronoprogramma
from strut_bilancio
left JOIN capitoli_fpv on (strut_bilancio.programma_id = capitoli_fpv.programma_id
			AND strut_bilancio.macroag_id = capitoli_fpv.macroaggregato_id)
left join fpv_anno_prec_da_capitoli
	on (capitoli_fpv.elem_code=fpv_anno_prec_da_capitoli.elem_code
    	AND capitoli_fpv.elem_code2=fpv_anno_prec_da_capitoli.elem_code2
        AND capitoli_fpv.elem_code3=fpv_anno_prec_da_capitoli.elem_code3)   
left join importi_anni_prec 
	on capitoli_fpv.elem_id = importi_anni_prec.elem_id 
left join fpv_variaz_anno_prec 
	on (capitoli_fpv.elem_code=fpv_variaz_anno_prec.elem_code
    	AND capitoli_fpv.elem_code2=fpv_variaz_anno_prec.elem_code2
        AND capitoli_fpv.elem_code3=fpv_variaz_anno_prec.elem_code3)      
left join riaccert_colonna_x
	on capitoli_fpv.elem_id = riaccert_colonna_x. elem_id
left join riaccert_colonna_y
	on capitoli_fpv.elem_id = riaccert_colonna_y.elem_id
left join impegni_anno1_d
	on capitoli_fpv.elem_id = impegni_anno1_d.elem_id
left join impegni_anno2_e
	on capitoli_fpv.elem_id = impegni_anno2_e.elem_id
left join impegni_annisucc_f
	on capitoli_fpv.elem_id = impegni_annisucc_f.elem_id 
left join fpv_stanziamento_anno
	on capitoli_fpv.elem_id = fpv_stanziamento_anno.elem_id
left join cronoprogrammi_fpv
    on (capitoli_fpv.elem_code=cronoprogrammi_fpv.cronop_elem_code
    	AND capitoli_fpv.elem_code2=cronoprogrammi_fpv.cronop_elem_code2
        AND capitoli_fpv.elem_code3=cronoprogrammi_fpv.cronop_elem_code3)
left join cronoprogrammi_bozza
    on (capitoli_fpv.elem_code=cronoprogrammi_bozza.cronop_elem_code
    	AND capitoli_fpv.elem_code2=cronoprogrammi_bozza.cronop_elem_code2
        AND capitoli_fpv.elem_code3=cronoprogrammi_bozza.cronop_elem_code3),
exist_last_versione        ;            
          
raise notice 'fine OK';
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

CREATE OR REPLACE FUNCTION siac."BILR223_Allegato_B_Fondo_Pluriennale_vincolato_capitolo" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
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
  bil_elem_code varchar,
  bil_elem_desc varchar,
  bil_elem_code2 varchar,
  bil_elem_desc2 varchar,
  bil_elem_code3 varchar,
  fondo_plur_anno_prec_a numeric,
  spese_impe_anni_prec_b numeric,
  quota_fond_plur_anni_prec_c numeric,
  spese_da_impeg_anno1_d numeric,
  spese_da_impeg_anno2_e numeric,
  spese_da_impeg_anni_succ_f numeric,
  spese_da_impeg_non_def_g numeric,
  fondo_plur_anno_h numeric
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
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
annoPrec varchar;
annoProspInt integer;
annoBilInt integer;
conflagfpv boolean ;
a_dacapfpv boolean ;
h_dacapfpv boolean ;
flagretrocomp boolean ;

h_count integer :=0;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
id_bil INTEGER;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
conflagfpv:=TRUE;
a_dacapfpv:=false;
h_dacapfpv:=false;
flagretrocomp:=false;

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
elemTipoCode:='CAP-UP'; -- tipo capitolo previsione


annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;
annoProspInt=p_anno_prospetto::INTEGER;
annoBilInt=p_anno::INTEGER;

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';

fondo_plur_anno_prec_a=0;
spese_impe_anni_prec_b=0;
quota_fond_plur_anni_prec_c=0;
spese_da_impeg_anno1_d=0;
spese_da_impeg_anno2_e=0;
spese_da_impeg_anni_succ_f=0;
spese_da_impeg_non_def_g=0;
fondo_plur_anno_h=0;

/* 08/03/2019: revisione per SIAC-6623 
	I campi fondo_plur_anno_prec_a, spese_impe_anni_prec_b, quota_fond_plur_anni_prec_c e
    fondo_plur_anno_h anche se valorizzati non sono utilizzati dal report perche'
    prende quelli di gestione calcolati tramite la funzione 
    BILR011_allegato_fpv_previsione_con_dati_gestione (ex BILR171).
*/

select t_bil.bil_id
	into id_bil
from siac_t_bil t_bil,
	siac_t_periodo t_periodo
where t_bil.periodo_id=t_periodo.periodo_id
	and t_bil.ente_proprietario_id = p_ente_prop_id
    and t_periodo.anno= p_anno    
    and t_bil.data_cancellazione IS NULL
    and t_periodo.data_cancellazione IS NULL;
IF NOT FOUND THEN
	raise notice 'Codice del bilancio non trovato';
    return;
END IF;

for classifBilRec in
	with strutt_capitoli as (select *
		from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id,p_anno,'')),
	capitoli as (select programma.classif_id programma_id,
		macroaggr.classif_id macroag_id,
       	capitolo.*
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
	where macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    	macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    	programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    	programma.classif_id=r_capitolo_programma.classif_id					and    		       
    	capitolo.elem_id=r_capitolo_programma.elem_id							and
    	capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
   		capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    	capitolo.elem_id				=	r_capitolo_stato.elem_id			and
		r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
    	capitolo.elem_id				=	r_cat_capitolo.elem_id				and
		r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
        capitolo.ente_proprietario_id=p_ente_prop_id      						and
        capitolo.bil_id= id_bil													and   	
    	tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    	macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    	programma_tipo.classif_tipo_code='PROGRAMMA' 							and	        
		stato_capitolo.elem_stato_code	=	'VA'								and    
			--04/08/2016: aggiunto FPVC 
		cat_del_capitolo.elem_cat_code	in	('FPV','FPVC')								
    	and	now() between programma.validita_inizio and coalesce (programma.validita_fine, now()) 
		and	now() between macroaggr.validita_inizio and coalesce (macroaggr.validita_fine, now())
      	and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between programma_tipo.validita_inizio and coalesce (programma_tipo.validita_fine, now())
        and	now() between macroaggr_tipo.validita_inizio and coalesce (macroaggr_tipo.validita_fine, now())
        and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between r_capitolo_programma.validita_inizio and coalesce (r_capitolo_programma.validita_fine, now())
        and	now() between r_capitolo_macroaggr.validita_inizio and coalesce (r_capitolo_macroaggr.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())        
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
        and	r_cat_capitolo.data_cancellazione 			is null),
    importi_capitoli_anno1 as (select 		capitolo_importi.elem_id,
                capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
                capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
                sum(capitolo_importi.elem_det_importo) stanziamento_fpv_anno1      
    from 		siac_t_bil_elem_det 		capitolo_importi,
                siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
                siac_t_periodo 				capitolo_imp_periodo,
                siac_t_bil_elem 			capitolo,
                siac_d_bil_elem_tipo 		tipo_elemento,                 
                siac_d_bil_elem_stato 		stato_capitolo, 
                siac_r_bil_elem_stato 		r_capitolo_stato,
                siac_d_bil_elem_categoria 	cat_del_capitolo,
                siac_r_bil_elem_categoria 	r_cat_capitolo
        where 	capitolo.elem_id	=	capitolo_importi.elem_id 
            and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
            and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
            and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 	
            and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
            and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
            and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
            and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
            and capitolo.bil_id					= id_bil					
            and	tipo_elemento.elem_tipo_code = elemTipoCode   
            and capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp    --'STA' 			  
            and	capitolo_imp_periodo.anno = annoCapImp --p_anno       		
            and	stato_capitolo.elem_stato_code	=	'VA'								        		
            	--04/08/2016: aggiunto FPVC
            and	cat_del_capitolo.elem_cat_code	in(	'FPV','FPVC')							
            and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
            and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
            and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
            and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
            and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
            and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
            and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
            and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
            and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
            and	capitolo_importi.data_cancellazione 		is null
            and	capitolo_imp_tipo.data_cancellazione 		is null
            and	capitolo_imp_periodo.data_cancellazione 	is null
            and	capitolo.data_cancellazione 				is null
            and	tipo_elemento.data_cancellazione 			is null            
            and	stato_capitolo.data_cancellazione 			is null 
            and	r_capitolo_stato.data_cancellazione 		is null
            and cat_del_capitolo.data_cancellazione 		is null
            and	r_cat_capitolo.data_cancellazione 			is null
        group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
            capitolo_imp_periodo.anno),
	importi_capitoli_anno2 as (select 		capitolo_importi.elem_id,
                capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
                capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
                sum(capitolo_importi.elem_det_importo) stanziamento_fpv_anno2      
    from 		siac_t_bil_elem_det 		capitolo_importi,
                siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
                siac_t_periodo 				capitolo_imp_periodo,
                siac_t_bil_elem 			capitolo,
                siac_d_bil_elem_tipo 		tipo_elemento,
                siac_d_bil_elem_stato 		stato_capitolo, 
                siac_r_bil_elem_stato 		r_capitolo_stato,
                siac_d_bil_elem_categoria 	cat_del_capitolo,
                siac_r_bil_elem_categoria 	r_cat_capitolo
        where  	capitolo.elem_id	=	capitolo_importi.elem_id 
            and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
            and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
            and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 	
            and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
            and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
            and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id            
            and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
            and	capitolo.bil_id					= id_bil					
            and	tipo_elemento.elem_tipo_code = elemTipoCode   
            and capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp    --'STA' 			  
            and	capitolo_imp_periodo.anno = annoCapImp1 --p_anno +1      		
            and	stato_capitolo.elem_stato_code	=	'VA'								        		
            	--04/08/2016: aggiunto FPVC
            and	cat_del_capitolo.elem_cat_code	in(	'FPV','FPVC')							
            and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
            and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
            and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
            and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
            and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
            and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
            and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
            and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
            and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
            and	capitolo_importi.data_cancellazione 		is null
            and	capitolo_imp_tipo.data_cancellazione 		is null
            and	capitolo_imp_periodo.data_cancellazione 	is null
            and	capitolo.data_cancellazione 				is null
            and	tipo_elemento.data_cancellazione 			is null
            and	stato_capitolo.data_cancellazione 			is null 
            and	r_capitolo_stato.data_cancellazione 		is null
            and cat_del_capitolo.data_cancellazione 		is null
            and	r_cat_capitolo.data_cancellazione 			is null
        group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
    		capitolo_imp_periodo.anno),
    importi_capitoli_anno3 as (select 		capitolo_importi.elem_id,
                capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
                capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
                sum(capitolo_importi.elem_det_importo) stanziamento_fpv_anno3      
    from 		siac_t_bil_elem_det 		capitolo_importi,
                siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
                siac_t_periodo 				capitolo_imp_periodo,
                siac_t_bil_elem 			capitolo,
                siac_d_bil_elem_tipo 		tipo_elemento,                 
                siac_d_bil_elem_stato 		stato_capitolo, 
                siac_r_bil_elem_stato 		r_capitolo_stato,
                siac_d_bil_elem_categoria 	cat_del_capitolo,
                siac_r_bil_elem_categoria 	r_cat_capitolo
        where 	capitolo.elem_id	=	capitolo_importi.elem_id 
            and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
            and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
            and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 	
            and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
            and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
            and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
            and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
            and capitolo.bil_id					= id_bil					
            and	tipo_elemento.elem_tipo_code = elemTipoCode   
            and capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp    --'STA' 			  
            and	capitolo_imp_periodo.anno = annoCapImp2 --p_anno +2      		
            and	stato_capitolo.elem_stato_code	=	'VA'								        		
            	--04/08/2016: aggiunto FPVC
            and	cat_del_capitolo.elem_cat_code	in(	'FPV','FPVC')							
            and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
            and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
            and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
            and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
            and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
            and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
            and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
            and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
            and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
            and	capitolo_importi.data_cancellazione 		is null
            and	capitolo_imp_tipo.data_cancellazione 		is null
            and	capitolo_imp_periodo.data_cancellazione 	is null
            and	capitolo.data_cancellazione 				is null
            and	tipo_elemento.data_cancellazione 			is null
            and	stato_capitolo.data_cancellazione 			is null 
            and	r_capitolo_stato.data_cancellazione 		is null
            and cat_del_capitolo.data_cancellazione 		is null
            and	r_cat_capitolo.data_cancellazione 			is null
        group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
            capitolo_imp_periodo.anno)           
    select strutt_capitoli.missione_tipo_desc			missione_tipo_desc,
		strutt_capitoli.missione_code				missione_code,
		strutt_capitoli.missione_desc				missione_desc,
		strutt_capitoli.programma_tipo_desc			programma_tipo_desc,
		strutt_capitoli.programma_code				programma_code,
		strutt_capitoli.programma_desc				programma_desc,
        capitoli.elem_code							elem_code, 
        capitoli.elem_desc							elem_desc, 
        capitoli.elem_code2							elem_code2,
        capitoli.elem_desc2							elem_desc2, 
        capitoli.elem_code3							elem_code3,
        capitoli.elem_id							elem_id,
        COALESCE(SUM(importi_capitoli_anno1.stanziamento_fpv_anno1),0) stanziamento_fpv_anno1,
        COALESCE(SUM(importi_capitoli_anno2.stanziamento_fpv_anno2),0) stanziamento_fpv_anno2,
        COALESCE(SUM(importi_capitoli_anno3.stanziamento_fpv_anno3),0) stanziamento_fpv_anno3,
        0 fondo_pluri_anno_prec
    from  strutt_capitoli 
        full join capitoli 
            on (capitoli.programma_id = strutt_capitoli.programma_id
                AND capitoli.macroag_id = strutt_capitoli.macroag_id)          
        left join importi_capitoli_anno1
            on importi_capitoli_anno1.elem_id = capitoli.elem_id
        left join importi_capitoli_anno2
            on importi_capitoli_anno2.elem_id = capitoli.elem_id
        left join importi_capitoli_anno3
            on importi_capitoli_anno3.elem_id = capitoli.elem_id
    group by strutt_capitoli.missione_tipo_desc, strutt_capitoli.missione_code, 
    	strutt_capitoli.missione_desc, strutt_capitoli.programma_tipo_desc, 
        strutt_capitoli.programma_code, strutt_capitoli.programma_desc,
        capitoli.elem_code, capitoli.elem_desc , capitoli.elem_code2 ,
        capitoli.elem_desc2 , capitoli.elem_code3, capitoli.elem_id
loop
	missione_tipo_desc:= classifBilRec.missione_tipo_desc;
    missione_code:= classifBilRec.missione_code;
    missione_desc:= classifBilRec.missione_desc;
    programma_tipo_desc:= classifBilRec.programma_tipo_desc;
    programma_code:= classifBilRec.programma_code;
    programma_desc:= classifBilRec.programma_desc;
  	bil_elem_code:=  classifBilRec.elem_code;
  	bil_elem_desc:=  classifBilRec.elem_desc;
  	bil_elem_code2:=  classifBilRec.elem_code2;
  	bil_elem_desc2:=  classifBilRec.elem_desc2;
  	bil_elem_code3:=  classifBilRec.elem_code3;
    
    bil_anno:=p_anno;
    
    if annoProspInt = annoBilInt then
		fondo_plur_anno_prec_a=classifBilRec.fondo_pluri_anno_prec;
        fondo_plur_anno_h=classifBilRec.stanziamento_fpv_anno1;
   	elsif  annoProspInt = annoBilInt+1 and a_dacapfpv=true then
    	fondo_plur_anno_prec_a=classifBilRec.stanziamento_fpv_anno1;
        fondo_plur_anno_h=classifBilRec.stanziamento_fpv_anno2;
    elsif  annoProspInt = annoBilInt+2 and a_dacapfpv=true then
    	fondo_plur_anno_prec_a=classifBilRec.stanziamento_fpv_anno2;
        fondo_plur_anno_h=classifBilRec.stanziamento_fpv_anno3;
    end if;      
    
    if  annoProspInt > annoBilInt and a_dacapfpv=false and flagretrocomp=false then

			--il campo spese_impe_anni_prec_b non viene piu' calcolato in questa
            --procedura.
	      spese_impe_anni_prec_b=0;
           
        /*  select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_impe_anni_prec_b
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno = p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata::integer < p_anno_prospetto::integer-1 -- anno prospetto  
          and e.periodo_id = f.periodo_id
          and f.anno= (p_anno_prospetto::integer-1)::varchar -- anno prospetto
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;		*/
       	    
          spese_da_impeg_anno1_d=0;
        
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno1_d 
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id= p_ente_prop_id
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata = (p_anno_prospetto::integer -1)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer  -- anno prospetto + 1
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and d.cronop_elem_code=classifBilRec.elem_code 
  		  and d.cronop_elem_code2=classifBilRec.elem_code2 
  		  and d.cronop_elem_code3=classifBilRec.elem_code3
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;

          spese_da_impeg_anno2_e=0;  
                  
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno2_e  
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          --siac_r_cronop_elem_class rcl1, siac_d_class_tipo clt1,siac_t_class cl1, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno di bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =(p_anno_prospetto::integer-1)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer+1 -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and d.cronop_elem_code=classifBilRec.elem_code 
  		  and d.cronop_elem_code2=classifBilRec.elem_code2 
  		  and d.cronop_elem_code3=classifBilRec.elem_code3
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;

          spese_da_impeg_anni_succ_f=0;
                  
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anni_succ_f 
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =(p_anno_prospetto::INTEGER-1)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer > p_anno_prospetto::INTEGER+1 -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and d.cronop_elem_code=classifBilRec.elem_code 
  		  and d.cronop_elem_code2=classifBilRec.elem_code2 
  		  and d.cronop_elem_code3=classifBilRec.elem_code3
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;


        if  annoProspInt = annoBilInt+1 then
          	fondo_plur_anno_prec_a=classifBilRec.fondo_pluri_anno_prec - spese_impe_anni_prec_b +
            spese_da_impeg_anno1_d + spese_da_impeg_anno2_e + spese_da_impeg_anni_succ_f;
          	raise notice 'Anno prospetto = %',annoProspInt;
            
        elsif  annoProspInt = annoBilInt+2  then
          fondo_plur_anno_prec_a= - spese_impe_anni_prec_b +
          spese_da_impeg_anno1_d + spese_da_impeg_anno2_e + spese_da_impeg_anni_succ_f;
          	
          spese_impe_anni_prec_b=0;
            --il campo spese_impe_anni_prec_b non viene piu' calcolato in questa
            --procedura.
         /* select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_impe_anni_prec_b
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno = p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata::integer < p_anno_prospetto::integer-2 -- anno prospetto  
          and e.periodo_id = f.periodo_id
          and f.anno= (p_anno_prospetto::integer-2)::varchar -- anno prospetto
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;		*/
       	    
          spese_da_impeg_anno1_d=0;
        
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno1_d
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id= p_ente_prop_id
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata = (p_anno_prospetto::integer -2)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer-1  -- anno prospetto + 1
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and d.cronop_elem_code=classifBilRec.elem_code 
  		  and d.cronop_elem_code2=classifBilRec.elem_code2 
  		  and d.cronop_elem_code3=classifBilRec.elem_code3
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;

          spese_da_impeg_anno2_e=0;  
                  
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno2_e  
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno di bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =(p_anno_prospetto::integer-2)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and d.cronop_elem_code=classifBilRec.elem_code 
  		  and d.cronop_elem_code2=classifBilRec.elem_code2 
  		  and d.cronop_elem_code3=classifBilRec.elem_code3          
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;

          spese_da_impeg_anni_succ_f=0;
                  
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anni_succ_f
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =(p_anno_prospetto::INTEGER-2)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer > p_anno_prospetto::INTEGER -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and d.cronop_elem_code=classifBilRec.elem_code 
  		  and d.cronop_elem_code2=classifBilRec.elem_code2 
  		  and d.cronop_elem_code3=classifBilRec.elem_code3          
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;
          --and rcl1.data_cancellazione is null

		fondo_plur_anno_prec_a=fondo_plur_anno_prec_a+classifBilRec.fondo_pluri_anno_prec - spese_impe_anni_prec_b +
            spese_da_impeg_anno1_d + spese_da_impeg_anno2_e + spese_da_impeg_anni_succ_f;            
            
        end if; --if annoProspInt = annoBilInt+1 then 

       end if; -- if  annoProspInt > annoBilInt

/*raise notice 'programma_code = %', programma_code;
raise notice '  spese_impe_anni_prec_b = %', spese_impe_anni_prec_b;
raise notice '  quota_fond_plur_anni_prec_c = %', quota_fond_plur_anni_prec_c;
raise notice '  spese_da_impeg_anno1_d = %', spese_da_impeg_anno1_d;
raise notice '  spese_da_impeg_anno2_e = %', spese_da_impeg_anno2_e;
raise notice '  spese_da_impeg_anni_succ_f = %', spese_da_impeg_anni_succ_f;
raise notice '  spese_da_impeg_non_def_g = %', spese_da_impeg_non_def_g;
*/

/* 17/05/2016: al momento questi campi sono impostati a zero in attesa di
	capire le modalita' di valorizzazione */
		spese_impe_anni_prec_b=0;
        quota_fond_plur_anni_prec_c=0;
        spese_da_impeg_anno1_d=0;
        spese_da_impeg_anno2_e=0;  
        spese_da_impeg_anni_succ_f=0;
        spese_da_impeg_non_def_g=0;
        
        /*COLONNA B -Spese impegnate negli anni precedenti con copertura costituita dal FPV e imputate all'esercizio N
		Occorre prendere tutte le quote di spesa previste nei cronoprogrammi con FPV selezionato, 
		con anno di entrata 2016 (o precedenti) e anno di spesa uguale al 2017.*/ 
       if flagretrocomp = false then
	   		--il campo spese_impe_anni_prec_b non viene piu' calcolato in questa
            --procedura.
            
          /*select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_impe_anni_prec_b
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno = p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata::integer < p_anno_prospetto::integer -- anno prospetto  
          and e.periodo_id = f.periodo_id
          and f.anno=p_anno_prospetto -- anno prospetto
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;*/
          
         -- raise notice 'spese_impe_anni_prec_b %' , spese_impe_anni_prec_b; 
        
        /* 3.	Colonna (c) e' data dalla differenza tra la colonna b e la colonna a genera e
        rappresenta il valore del fondo costituito che verra' utilizzato negli anni 2018 e seguenti; */
        quota_fond_plur_anni_prec_c=fondo_plur_anno_prec_a-spese_impe_anni_prec_b ;  
       -- raise notice 'quota_fond_plur_anni_prec_c = %', quota_fond_plur_anni_prec_c;  
        
        /*
        Colonna d   Occorre prendere tutte le quote di spesa previste nei cronoprogrammi 
        con FPV selezionato, con anno di entrata 2017 e anno di spesa uguale al 2018;
        */
          
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno1_d
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id= p_ente_prop_id
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata = p_anno_prospetto -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer+1  -- anno prospetto + 1
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and d.cronop_elem_code=classifBilRec.elem_code 
  		  and d.cronop_elem_code2=classifBilRec.elem_code2 
  		  and d.cronop_elem_code3=classifBilRec.elem_code3          
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;
          --and rcl1.data_cancellazione is null;
              
        
        /*
        Colonna e - Occorre prendere tutte le quote di spesa previste nei cronoprogrammi 
        con FPV selezionato, con anno di entrata 2017 e anno di spesa uguale al 2019;
        */
                  
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno2_e
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno di bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =p_anno_prospetto -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer+2 -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and d.cronop_elem_code=classifBilRec.elem_code 
  		  and d.cronop_elem_code2=classifBilRec.elem_code2 
  		  and d.cronop_elem_code3=classifBilRec.elem_code3          
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;

        
        
        /* Colonna f - Occorre prendere tutte le quote di 
        spesa previste nei cronoprogrammi con FPV selezionato, 
        con anno di entrata 2017 e anno di spesa uguale al 2020 e successivi;*/
                          
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anni_succ_f 
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =p_anno_prospetto -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer > p_anno_prospetto::INTEGER+2 -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and d.cronop_elem_code=classifBilRec.elem_code 
  		  and d.cronop_elem_code2=classifBilRec.elem_code2 
  		  and d.cronop_elem_code3=classifBilRec.elem_code3          
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;
        
        /*
        d.	Colonna g   Occorre prendere l importo previsto nella sezione spese dei progetti. 
        E  necessario quindi implementare una tipologia  Cronoprogramma da  definire , 
        agganciato al progetto per il quale sono necessarie solo due informazioni: 
        l importo e la Missione/Programma. Rimane incognito l anno relativo alla spesa 
        (anche se apparira' formalmente agganciato al 2017). 
        Nel momento in cui saranno note le altre informazioni relative al progetto, 
        l ente operera' nel modo consueto, ovvero inserendo una nuova versione di cronoprogramma 
        e selezionandone il relativo FPV. Operativamente e' sufficiente inserire un flag "Cronoprogramma da definire". 
        L'operatore entrera' comunque nelle due maschere (cosi' come sono ad oggi) di entrata e 
        spesa e inserira' l'importo e la spesa agganciandola a uno o piu' missioni per la spesa e analogamente per le entrate... 
        Inserira' 2017 sia nelle entrate che nella spesa. Essendo anno entrata=anno spesa non si creera' FPV 
        ma avendo il Flag "Cronoprogramma da Definire" l'unione delle due informazione generera' il 
        popolamento della colonna G. Questo escamotage peraltro potra' essere utilizzato anche dagli enti 
        che vorranno tracciare la loro 
        programmazione anche laddove non ci sia la generazione di FPV, ovviamente senza flaggare il campo citato.
        */
         
        
        /*5.	La colonna h  e' la somma dalla colonna c alla colonna g. 
        	NON e' piu' calcolata in questa procedura. */
        
    	if h_dacapfpv = false then
        	fondo_plur_anno_h=quota_fond_plur_anni_prec_c+spese_da_impeg_anno1_d+
            	spese_da_impeg_anno2_e+spese_da_impeg_anni_succ_f+spese_da_impeg_non_def_g;
        end if;
     end if; --if flagretrocomp = false then
    
/*raise notice 'programma_codeXXX = %', programma_code;
raise notice '  spese_impe_anni_prec_b = %', spese_impe_anni_prec_b;
raise notice '  quota_fond_plur_anni_prec_c = %', quota_fond_plur_anni_prec_c;
raise notice '  spese_da_impeg_anno1_d = %', spese_da_impeg_anno1_d;
raise notice '  spese_da_impeg_anno2_e = %', spese_da_impeg_anno2_e;
raise notice '  spese_da_impeg_anni_succ_f = %', spese_da_impeg_anni_succ_f;
raise notice '  spese_da_impeg_non_def_g = %', spese_da_impeg_non_def_g;*/
    
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

  fondo_plur_anno_prec_a=0;
  spese_impe_anni_prec_b=0;
  quota_fond_plur_anni_prec_c=0;
  spese_da_impeg_anno1_d=0;
  spese_da_impeg_anno2_e=0;
  spese_da_impeg_anni_succ_f=0;
  spese_da_impeg_non_def_g=0;
  fondo_plur_anno_h=0;        
end loop;  

raise notice 'fine OK';
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

CREATE OR REPLACE FUNCTION siac."BILR223_allegato_fpv_previsione_dati_gestione_capitolo" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
)
RETURNS TABLE (
  missione_code varchar,
  missione_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  importi_capitoli numeric,
  spese_impegnate numeric,
  spese_impegnate_anno1 numeric,
  spese_impegnate_anno2 numeric,
  spese_impegnate_anno_succ numeric,
  importo_avanzo numeric,
  importo_avanzo_anno1 numeric,
  importo_avanzo_anno2 numeric,
  importo_avanzo_anno_succ numeric,
  elem_id integer,
  anno_esercizio varchar,
  bil_elem_code varchar,
  bil_elem_desc varchar,
  bil_elem_code2 varchar,
  bil_elem_desc2 varchar,
  bil_elem_code3 varchar
) AS
$body$
DECLARE

RTN_MESSAGGIO text;
bilancio_id integer;
bilancio_id_prec integer;
cod_fase_operativa varchar;
anno_esercizio varchar;
anno_esercizio_prec varchar;
annoimpimpegni_int integer;
annoprospetto_int integer;
annoprospetto_prec_int varchar;

BEGIN

/*
	12/03/2019: SIAC-6623.
    	Funzione copia della BILR171_allegato_fpv_previsione_con_dati_gestione che serve
        per il calcolo dei campi relativi alle prime 2 colonne del report BILR011.
		Poiche' il report BILR171 viene eliminato la funzione 
        BILR171_allegato_fpv_previsione_con_dati_gestione e' superflua ma NON viene
        cancellata perche' serve per gli anni precedenti il 2018.
*/

/*Se la fase di bilancio e' Previsione allora l''anno di esercizio e il bilancio id saranno
quelli di p_anno-1 per tutte le colonne. 

Se la fase di bilancio e' Esercizio Provvisorio allora l''anno di esercizio e il bilancio id saranno
quelli di p_anno per tutte le colonne tranne quella relativa agli importi dei capitolo (colonna a).
In questo caso l''anno di esercizio e il bilancio id saranno quelli di p_anno-1.

L'anno relativo agli importi dei capitoli e' anno_esercizio_prec
L'anno relativo agli importi degli impegni e' annoImpImpegni_int*/


-- SIAC-6063
/*Aggiunto parametro p_anno_prospetto
Variabile annoImpImpegni_int sostituita da annoprospetto_int
Azzerati importi  spese_impegnate_anno1
                  spese_impegnate_anno2
                  spese_impegnate_anno_succ
                  importo_avanzo_anno1
                  importo_avanzo_anno2
                  importo_avanzo_anno_succ*/

RTN_MESSAGGIO := 'select 1'; 

bilancio_id := null;
bilancio_id_prec := null;

select bil.bil_id, fase_operativa.fase_operativa_code
into   bilancio_id, cod_fase_operativa
from  siac_d_fase_operativa fase_operativa, 
      siac_r_bil_fase_operativa bil_fase_operativa, 
      siac_t_bil bil, 
      siac_t_periodo periodo
where fase_operativa.fase_operativa_id = bil_fase_operativa.fase_operativa_id
and   bil_fase_operativa.bil_id = bil.bil_id
and   periodo.periodo_id = bil.periodo_id
and   fase_operativa.fase_operativa_code in ('P','E','G') -- SIAC-5778 Aggiunto G
and   bil.ente_proprietario_id = p_ente_prop_id
and   periodo.anno = p_anno
and   fase_operativa.data_cancellazione is null
and   bil_fase_operativa.data_cancellazione is null 
and   bil.data_cancellazione is null 
and   periodo.data_cancellazione is null;
 
/*if cod_fase_operativa = 'P' then
  
  anno_esercizio := ((p_anno::integer)-1)::varchar;   

  select a.bil_id 
  into bilancio_id 
  from siac_t_bil a,siac_t_periodo b
  where a.ente_proprietario_id = p_ente_prop_id 
  and b.periodo_id = a.periodo_id
  and b.anno = anno_esercizio;
  
  annoprospetto_int := p_anno_prospetto::integer-1;
  
elsif cod_fase_operativa in ('E','G') then

  anno_esercizio := p_anno;
  annoprospetto_int := p_anno_prospetto::integer;
   
end if;*/
 
  anno_esercizio := ((p_anno::integer)-1)::varchar;   

  select a.bil_id 
  into bilancio_id 
  from siac_t_bil a,siac_t_periodo b
  where a.ente_proprietario_id = p_ente_prop_id 
  and b.periodo_id = a.periodo_id
  and b.anno = anno_esercizio;
  
  annoprospetto_int := p_anno_prospetto::integer;
  
  annoprospetto_prec_int := ((p_anno_prospetto::integer)-1)::varchar;

-- anno_esercizio_prec := ((anno_esercizio::integer)-1)::varchar;
anno_esercizio_prec := ((p_anno::integer)-1)::varchar;

select a.bil_id
into bilancio_id_prec 
from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id 
and b.periodo_id = a.periodo_id
and b.anno = anno_esercizio_prec;

-- annoImpImpegni_int := anno_esercizio::integer; 
-- annoImpImpegni_int := p_anno::integer; -- SIAC-6063

return query
select 
zz.*
from (
select 
tab1.*
from (
with struttura as (
select *
from fnc_bilr_struttura_cap_bilancio_spese (p_ente_prop_id,anno_esercizio,null) -- Potrebbe essere anche anno_esercizio_prec
),
capitoli_anno_prec as (
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
       	capitolo.elem_code, capitolo.elem_desc, capitolo.elem_code2,
        capitolo.elem_desc2, capitolo.elem_code3, capitolo.elem_id
from siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_stato r_capitolo_stato,
     siac_d_bil_elem_stato stato_capitolo,      
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 	 
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr
where capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id 						
and capitolo.elem_id = r_capitolo_stato.elem_id							
and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id		
and	capitolo.elem_id = r_capitolo_programma.elem_id							
and capitolo.elem_id = r_capitolo_macroaggr.elem_id							
and programma.classif_tipo_id = programma_tipo.classif_tipo_id 				
and programma.classif_id = r_capitolo_programma.classif_id					
and macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 			
and macroaggr.classif_id = r_capitolo_macroaggr.classif_id					
and	capitolo.elem_id = r_cat_capitolo.elem_id				
and r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id		
and capitolo.ente_proprietario_id = p_ente_prop_id							
and capitolo.bil_id = bilancio_id_prec													
and programma_tipo.classif_tipo_code = 'PROGRAMMA'							
and	macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
and stato_capitolo.elem_stato_code = 'VA' 
and cat_del_capitolo.elem_cat_code in ('FPV','FPVC')    
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
and	r_cat_capitolo.data_cancellazione           is null
),
capitoli_importo as ( -- Fondo pluriennale vincolato al 31 dicembre dell''esercizio N-1
select 		capitolo_importi.elem_id,
           	sum(capitolo_importi.elem_det_importo) importi_capitoli
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_d_bil_elem_tipo 		tipo_elemento,
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
where capitolo_importi.ente_proprietario_id = p_ente_prop_id  								 
and	capitolo.elem_id = capitolo_importi.elem_id 
and	capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id
and	capitolo_importi.elem_det_tipo_id = capitolo_imp_tipo.elem_det_tipo_id 		
and	capitolo_imp_periodo.periodo_id = capitolo_importi.periodo_id 
and	capitolo.elem_id = r_capitolo_stato.elem_id			
and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id
and	capitolo.elem_id = r_cat_capitolo.elem_id				
and	r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id	
and	capitolo.bil_id = bilancio_id_prec							
and	tipo_elemento.elem_tipo_code = 'CAP-UG'
and	capitolo_imp_periodo.anno = annoprospetto_prec_int		  
--and	capitolo_imp_periodo.anno = anno_esercizio_prec	
and	stato_capitolo.elem_stato_code = 'VA'								
and	cat_del_capitolo.elem_cat_code in ('FPV','FPVC')
and capitolo_imp_tipo.elem_det_tipo_code = 'STA'				
and	capitolo_importi.data_cancellazione 		is null
and	capitolo_imp_tipo.data_cancellazione 		is null
and	capitolo_imp_periodo.data_cancellazione 	is null
and	capitolo.data_cancellazione 				is null
and	tipo_elemento.data_cancellazione 			is null
and	stato_capitolo.data_cancellazione 			is null 
and	r_capitolo_stato.data_cancellazione 		is null
and cat_del_capitolo.data_cancellazione 		is null
and	r_cat_capitolo.data_cancellazione 			is null
group by capitolo_importi.elem_id
)
select 
struttura.missione_code::varchar,
struttura.missione_desc::varchar,
struttura.programma_code::varchar,
struttura.programma_desc::varchar,
COALESCE(capitoli_importo.importi_capitoli,0)::numeric,
0::numeric spese_impegnate,
0::numeric spese_impegnate_anno1,
0::numeric spese_impegnate_anno2,
0::numeric spese_impegnate_anno_succ,
0::numeric importo_avanzo,
0::numeric importo_avanzo_anno1,
0::numeric importo_avanzo_anno2,
0::numeric importo_avanzo_anno_succ,
capitoli_anno_prec.elem_id::integer,
anno_esercizio::varchar,
capitoli_anno_prec.elem_code::varchar bil_elem_code, 
capitoli_anno_prec.elem_desc::varchar bil_elem_desc, 
capitoli_anno_prec.elem_code2::varchar bil_elem_code2, 
capitoli_anno_prec.elem_desc2::varchar bil_elem_desc2,
capitoli_anno_prec.elem_code3::varchar bil_elem_code3
from struttura
left join capitoli_anno_prec on struttura.programma_id = capitoli_anno_prec.programma_id
                   and struttura.macroag_id = capitoli_anno_prec.macroaggregato_id
left join capitoli_importo on capitoli_anno_prec.elem_id = capitoli_importo.elem_id
) tab1
union all
select 
tab2.*
from (
with struttura as (
select *
from fnc_bilr_struttura_cap_bilancio_spese (p_ente_prop_id,anno_esercizio,null)
),
capitoli as (
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
       	capitolo.elem_code, capitolo.elem_desc, capitolo.elem_code2,
        capitolo.elem_desc2, capitolo.elem_code3, capitolo.elem_id
from siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_stato r_capitolo_stato,
     siac_d_bil_elem_stato stato_capitolo,      
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 	 
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr
where capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id 						
and capitolo.elem_id = r_capitolo_stato.elem_id							
and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id		
and	capitolo.elem_id = r_capitolo_programma.elem_id							
and capitolo.elem_id = r_capitolo_macroaggr.elem_id							
and programma.classif_tipo_id = programma_tipo.classif_tipo_id 				
and programma.classif_id = r_capitolo_programma.classif_id					
and macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 				
and macroaggr.classif_id = r_capitolo_macroaggr.classif_id					
and	capitolo.elem_id = r_cat_capitolo.elem_id				
and r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id		
and capitolo.ente_proprietario_id = p_ente_prop_id							
and capitolo.bil_id = bilancio_id													
and programma_tipo.classif_tipo_code = 'PROGRAMMA'							
and	macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
and stato_capitolo.elem_stato_code = 'VA' 
-- and cat_del_capitolo.elem_cat_code in ('FPV','FPVC')    
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
and	r_cat_capitolo.data_cancellazione           is null
),
dati_impegni as (
with importo_impegni as (
with   impegni as (
select ts_impegni_legati.movgest_ts_b_id,
       movimento.movgest_anno anno_impegno
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_b_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    movimento.movgest_anno  >= annoprospetto_int
-- and    movimento.movgest_anno  >= annoImpImpegni_int
and    movimento.bil_id = bilancio_id
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    ts_movimento.data_cancellazione is null
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno
),
imp_impegni_accertamenti as (
select ts_impegni_legati.movgest_ts_b_id,
       movimento.movgest_anno anno_accertamento,
       sum(ts_impegni_legati.movgest_ts_importo) movgest_ts_importo       
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_a_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    ts_impegni_legati.avav_id is null
and    movimento.bil_id = bilancio_id
and    movimento.movgest_anno <= annoprospetto_int+2
-- and    movimento.movgest_anno <= annoImpImpegni_int+2
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    ts_movimento.data_cancellazione is null
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno 
),
imp_impegni_avanzo as (
select ts_impegni_legati.movgest_ts_b_id,
       sum(ts_impegni_legati.movgest_ts_importo) movgest_ts_importo,
       movimento.movgest_anno        
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_avanzovincolo avanzovincolo on ts_impegni_legati.avav_id = avanzovincolo.avav_id
inner  join siac_d_avanzovincolo_tipo tipo_avanzovincolo on avanzovincolo.avav_tipo_id = tipo_avanzovincolo.avav_tipo_id
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_b_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    movimento.bil_id = bilancio_id
and    ts_impegni_legati.movgest_ts_a_id is null
and    tipo_avanzovincolo.avav_tipo_code in ('AAM','FPVSC','FPVCC')
and    movimento.movgest_anno >= annoprospetto_int
-- and    movimento.movgest_anno >= annoImpImpegni_int
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    avanzovincolo.data_cancellazione is null 
and    tipo_avanzovincolo.data_cancellazione is null
and    ts_movimento.data_cancellazione is null 
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno 
)
select impegni.movgest_ts_b_id,
       case 
        when impegni.anno_impegno = annoprospetto_int and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int-1 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate,  
       case 
        when impegni.anno_impegno = annoprospetto_int+1 and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate_anno1,   
       case 
        when impegni.anno_impegno = annoprospetto_int+2 and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int+1 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate_anno2,    
       case 
        when impegni.anno_impegno > annoprospetto_int+2 and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int+2 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate_anno_succ,
       case 
        when impegni.anno_impegno = annoprospetto_int then
             sum(imp_impegni_avanzo.movgest_ts_importo)
       end importo_avanzo,    
       case 
        when impegni.anno_impegno = annoprospetto_int+1 then
             sum(imp_impegni_avanzo.movgest_ts_importo)
       end importo_avanzo_anno1,      
       case 
        when impegni.anno_impegno = annoprospetto_int+2 then
             sum(imp_impegni_avanzo.movgest_ts_importo)            
       end importo_avanzo_anno2,
       case 
        when impegni.anno_impegno > annoprospetto_int+2 then
             sum(imp_impegni_avanzo.movgest_ts_importo)            
       end importo_avanzo_anno_succ                      
from   impegni
left   join imp_impegni_accertamenti on impegni.movgest_ts_b_id = imp_impegni_accertamenti.movgest_ts_b_id
left   join imp_impegni_avanzo on impegni.movgest_ts_b_id = imp_impegni_avanzo.movgest_ts_b_id
group by impegni.movgest_ts_b_id, impegni.anno_impegno, imp_impegni_accertamenti.anno_accertamento
),
capitoli_impegni as (
select capitolo.elem_id, ts_movimento.movgest_ts_id,
	capitolo.elem_code, capitolo.elem_code2, capitolo.elem_code3,
    capitolo.elem_desc, capitolo.elem_desc2
from  siac_t_bil_elem                 capitolo
inner join siac_r_movgest_bil_elem    r_mov_capitolo on r_mov_capitolo.elem_id = capitolo.elem_id
inner join siac_d_bil_elem_tipo       t_capitolo on capitolo.elem_tipo_id = t_capitolo.elem_tipo_id
inner join siac_t_movgest             movimento on r_mov_capitolo.movgest_id = movimento.movgest_id
inner join siac_t_movgest_ts          ts_movimento on movimento.movgest_id = ts_movimento.movgest_id
inner join siac_r_movgest_ts_stato    ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner join siac_d_movgest_stato       stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where capitolo.ente_proprietario_id = p_ente_prop_id
and   capitolo.bil_id =	bilancio_id
and   movimento.bil_id = bilancio_id
and   t_capitolo.elem_tipo_code = 'CAP-UG'
and   movimento.movgest_anno >= annoprospetto_int
-- and   movimento.movgest_anno >= annoImpImpegni_int
and   stato.movgest_stato_code in ('D','N')-- SIAC-5778
and   capitolo.data_cancellazione is null 
and   r_mov_capitolo.data_cancellazione is null 
and   t_capitolo.data_cancellazione is null
and   movimento.data_cancellazione is null 
and   ts_movimento.data_cancellazione is null
and   ts_stato.data_cancellazione is null-- SIAC-5778
and   stato.data_cancellazione is null-- SIAC-5778 
)
select 
capitoli_impegni.elem_id,
capitoli_impegni.elem_code, 
capitoli_impegni.elem_code2, 
capitoli_impegni.elem_code3,
capitoli_impegni.elem_desc, 
capitoli_impegni.elem_desc2,
sum(importo_impegni.spese_impegnate) spese_impegnate,
sum(importo_impegni.spese_impegnate_anno1) spese_impegnate_anno1,
sum(importo_impegni.spese_impegnate_anno2) spese_impegnate_anno2,
sum(importo_impegni.spese_impegnate_anno_succ) spese_impegnate_anno_succ,
sum(importo_impegni.importo_avanzo) importo_avanzo,
sum(importo_impegni.importo_avanzo_anno1) importo_avanzo_anno1,
sum(importo_impegni.importo_avanzo_anno2) importo_avanzo_anno2,
sum(importo_impegni.importo_avanzo_anno_succ) importo_avanzo_anno_succ
from capitoli_impegni
left join importo_impegni on capitoli_impegni.movgest_ts_id = importo_impegni.movgest_ts_b_id
group by capitoli_impegni.elem_id,capitoli_impegni.elem_code, 
capitoli_impegni.elem_code2, capitoli_impegni.elem_code3,
capitoli_impegni.elem_desc, capitoli_impegni.elem_desc2
)
select 
struttura.missione_code::varchar,
struttura.missione_desc::varchar,
struttura.programma_code::varchar,
struttura.programma_desc::varchar,
0::numeric importi_capitoli,
COALESCE(dati_impegni.spese_impegnate,0)::numeric spese_impegnate,
/*COALESCE(dati_impegni.spese_impegnate_anno1,0)::numeric spese_impegnate_anno1,
COALESCE(dati_impegni.spese_impegnate_anno2,0)::numeric spese_impegnate_anno2,
COALESCE(dati_impegni.spese_impegnate_anno_succ,0)::numeric spese_impegnate_anno_succ,*/
0::numeric spese_impegnate_anno1,
0::numeric spese_impegnate_anno2,
0::numeric spese_impegnate_anno_succ,
COALESCE(dati_impegni.importo_avanzo,0)::numeric importo_avanzo,
/*COALESCE(dati_impegni.importo_avanzo_anno1,0)::numeric importo_avanzo_anno1,
COALESCE(dati_impegni.importo_avanzo_anno2,0)::numeric importo_avanzo_anno2,
COALESCE(dati_impegni.importo_avanzo_anno_succ,0)::numeric importo_avanzo_anno_succ,*/
0::numeric importo_avanzo_anno1,
0::numeric importo_avanzo_anno2,
0::numeric importo_avanzo_anno_succ,
capitoli.elem_id::integer,
anno_esercizio::varchar,
capitoli.elem_code::varchar bil_elem_code, 
capitoli.elem_desc::varchar bil_elem_desc, 
capitoli.elem_code2::varchar bil_elem_code2, 
capitoli.elem_desc2::varchar bil_elem_desc2,
capitoli.elem_code3::varchar bil_elem_code3
from struttura
left join capitoli on  struttura.programma_id = capitoli.programma_id
                   and struttura.macroag_id = capitoli.macroaggregato_id
left join dati_impegni on  capitoli.elem_id = dati_impegni.elem_id
) tab2
) as zz;

-- raise notice 'Dati % - %',anno_esercizio::varchar,anno_esercizio_prec::varchar;
-- raise notice 'Dati % - %',bilancio_id::varchar,bilancio_id_prec::varchar;

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

CREATE OR REPLACE FUNCTION siac."BILR011_Allegato_B_Fondo_Pluriennale_vincolato" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
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
  fondo_plur_anno_prec_a numeric,
  spese_impe_anni_prec_b numeric,
  quota_fond_plur_anni_prec_c numeric,
  spese_da_impeg_anno1_d numeric,
  spese_da_impeg_anno2_e numeric,
  spese_da_impeg_anni_succ_f numeric,
  spese_da_impeg_non_def_g numeric,
  fondo_plur_anno_h numeric
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
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
annoPrec varchar;
annoProspInt integer;
annoBilInt integer;
conflagfpv boolean ;
a_dacapfpv boolean ;
h_dacapfpv boolean ;
flagretrocomp boolean ;

h_count integer :=0;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
id_bil INTEGER;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
conflagfpv:=TRUE;
a_dacapfpv:=false;
h_dacapfpv:=false;
flagretrocomp:=false;

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
elemTipoCode:='CAP-UP'; -- tipo capitolo previsione

annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;
annoProspInt=p_anno_prospetto::INTEGER;
annoBilInt=p_anno::INTEGER;

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';

fondo_plur_anno_prec_a=0;
spese_impe_anni_prec_b=0;
quota_fond_plur_anni_prec_c=0;
spese_da_impeg_anno1_d=0;
spese_da_impeg_anno2_e=0;
spese_da_impeg_anni_succ_f=0;
spese_da_impeg_non_def_g=0;
fondo_plur_anno_h=0;

/* 08/03/2019: revisione per SIAC-6623 
	I campi fondo_plur_anno_prec_a, spese_impe_anni_prec_b, quota_fond_plur_anni_prec_c e
    fondo_plur_anno_h anche se valorizzati non sono utilizzati dal report perche'
    prende quelli di gestione calcolati tramite la funzione 
    BILR011_allegato_fpv_previsione_con_dati_gestione (ex BILR171).
*/

select t_bil.bil_id
	into id_bil
from siac_t_bil t_bil,
	siac_t_periodo t_periodo
where t_bil.periodo_id=t_periodo.periodo_id
	and t_bil.ente_proprietario_id = p_ente_prop_id
    and t_periodo.anno= p_anno    
    and t_bil.data_cancellazione IS NULL
    and t_periodo.data_cancellazione IS NULL;
IF NOT FOUND THEN
	raise notice 'Codice del bilancio non trovato';
    return;
END IF;

for classifBilRec in
	with strutt_capitoli as (select *
		from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id,p_anno,'')),
	capitoli as (select programma.classif_id programma_id,
		macroaggr.classif_id macroag_id,
       	capitolo.*
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
	where macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    	macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    	programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    	programma.classif_id=r_capitolo_programma.classif_id					and    		       
    	capitolo.elem_id=r_capitolo_programma.elem_id							and
    	capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
   		capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    	capitolo.elem_id				=	r_capitolo_stato.elem_id			and
		r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
    	capitolo.elem_id				=	r_cat_capitolo.elem_id				and
		r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
        capitolo.ente_proprietario_id=p_ente_prop_id      						and
        capitolo.bil_id= id_bil													and   	
    	tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    	macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    	programma_tipo.classif_tipo_code='PROGRAMMA' 							and	        
		stato_capitolo.elem_stato_code	=	'VA'								and    
			--04/08/2016: aggiunto FPVC 
		cat_del_capitolo.elem_cat_code	in	('FPV','FPVC')								
    	and	now() between programma.validita_inizio and coalesce (programma.validita_fine, now()) 
		and	now() between macroaggr.validita_inizio and coalesce (macroaggr.validita_fine, now())
      	and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between programma_tipo.validita_inizio and coalesce (programma_tipo.validita_fine, now())
        and	now() between macroaggr_tipo.validita_inizio and coalesce (macroaggr_tipo.validita_fine, now())
        and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between r_capitolo_programma.validita_inizio and coalesce (r_capitolo_programma.validita_fine, now())
        and	now() between r_capitolo_macroaggr.validita_inizio and coalesce (r_capitolo_macroaggr.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())        
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
        and	r_cat_capitolo.data_cancellazione 			is null),
    importi_capitoli_anno1 as (select 		capitolo_importi.elem_id,
                capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
                capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
                sum(capitolo_importi.elem_det_importo) stanziamento_fpv_anno1      
    from 		siac_t_bil_elem_det 		capitolo_importi,
                siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
                siac_t_periodo 				capitolo_imp_periodo,
                siac_t_bil_elem 			capitolo,
                siac_d_bil_elem_tipo 		tipo_elemento,                 
                siac_d_bil_elem_stato 		stato_capitolo, 
                siac_r_bil_elem_stato 		r_capitolo_stato,
                siac_d_bil_elem_categoria 	cat_del_capitolo,
                siac_r_bil_elem_categoria 	r_cat_capitolo
        where 	capitolo.elem_id	=	capitolo_importi.elem_id 
            and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
            and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
            and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 	
            and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
            and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
            and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
            and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
            and capitolo.bil_id					= id_bil					
            and	tipo_elemento.elem_tipo_code = elemTipoCode   
            and capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp    --'STA' 			  
            and	capitolo_imp_periodo.anno = annoCapImp --p_anno       		
            and	stato_capitolo.elem_stato_code	=	'VA'								        		
            	--04/08/2016: aggiunto FPVC
            and	cat_del_capitolo.elem_cat_code	in(	'FPV','FPVC')							
            and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
            and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
            and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
            and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
            and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
            and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
            and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
            and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
            and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
            and	capitolo_importi.data_cancellazione 		is null
            and	capitolo_imp_tipo.data_cancellazione 		is null
            and	capitolo_imp_periodo.data_cancellazione 	is null
            and	capitolo.data_cancellazione 				is null
            and	tipo_elemento.data_cancellazione 			is null            
            and	stato_capitolo.data_cancellazione 			is null 
            and	r_capitolo_stato.data_cancellazione 		is null
            and cat_del_capitolo.data_cancellazione 		is null
            and	r_cat_capitolo.data_cancellazione 			is null
        group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
            capitolo_imp_periodo.anno),
	importi_capitoli_anno2 as (select 		capitolo_importi.elem_id,
                capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
                capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
                sum(capitolo_importi.elem_det_importo) stanziamento_fpv_anno2      
    from 		siac_t_bil_elem_det 		capitolo_importi,
                siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
                siac_t_periodo 				capitolo_imp_periodo,
                siac_t_bil_elem 			capitolo,
                siac_d_bil_elem_tipo 		tipo_elemento,
                siac_d_bil_elem_stato 		stato_capitolo, 
                siac_r_bil_elem_stato 		r_capitolo_stato,
                siac_d_bil_elem_categoria 	cat_del_capitolo,
                siac_r_bil_elem_categoria 	r_cat_capitolo
        where  	capitolo.elem_id	=	capitolo_importi.elem_id 
            and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
            and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
            and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 	
            and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
            and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
            and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id            
            and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
            and	capitolo.bil_id					= id_bil					
            and	tipo_elemento.elem_tipo_code = elemTipoCode   
            and capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp    --'STA' 			  
            and	capitolo_imp_periodo.anno = annoCapImp1 --p_anno +1      		
            and	stato_capitolo.elem_stato_code	=	'VA'								        		
            	--04/08/2016: aggiunto FPVC
            and	cat_del_capitolo.elem_cat_code	in(	'FPV','FPVC')							
            and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
            and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
            and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
            and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
            and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
            and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
            and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
            and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
            and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
            and	capitolo_importi.data_cancellazione 		is null
            and	capitolo_imp_tipo.data_cancellazione 		is null
            and	capitolo_imp_periodo.data_cancellazione 	is null
            and	capitolo.data_cancellazione 				is null
            and	tipo_elemento.data_cancellazione 			is null
            and	stato_capitolo.data_cancellazione 			is null 
            and	r_capitolo_stato.data_cancellazione 		is null
            and cat_del_capitolo.data_cancellazione 		is null
            and	r_cat_capitolo.data_cancellazione 			is null
        group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
    		capitolo_imp_periodo.anno),
    importi_capitoli_anno3 as (select 		capitolo_importi.elem_id,
                capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
                capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
                sum(capitolo_importi.elem_det_importo) stanziamento_fpv_anno3      
    from 		siac_t_bil_elem_det 		capitolo_importi,
                siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
                siac_t_periodo 				capitolo_imp_periodo,
                siac_t_bil_elem 			capitolo,
                siac_d_bil_elem_tipo 		tipo_elemento,                 
                siac_d_bil_elem_stato 		stato_capitolo, 
                siac_r_bil_elem_stato 		r_capitolo_stato,
                siac_d_bil_elem_categoria 	cat_del_capitolo,
                siac_r_bil_elem_categoria 	r_cat_capitolo
        where 	capitolo.elem_id	=	capitolo_importi.elem_id 
            and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
            and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
            and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 	
            and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
            and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
            and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
            and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
            and capitolo.bil_id					= id_bil					
            and	tipo_elemento.elem_tipo_code = elemTipoCode   
            and capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp    --'STA' 			  
            and	capitolo_imp_periodo.anno = annoCapImp2 --p_anno +2      		
            and	stato_capitolo.elem_stato_code	=	'VA'								        		
            	--04/08/2016: aggiunto FPVC
            and	cat_del_capitolo.elem_cat_code	in(	'FPV','FPVC')							
            and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
            and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
            and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
            and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
            and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
            and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
            and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
            and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
            and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
            and	capitolo_importi.data_cancellazione 		is null
            and	capitolo_imp_tipo.data_cancellazione 		is null
            and	capitolo_imp_periodo.data_cancellazione 	is null
            and	capitolo.data_cancellazione 				is null
            and	tipo_elemento.data_cancellazione 			is null
            and	stato_capitolo.data_cancellazione 			is null 
            and	r_capitolo_stato.data_cancellazione 		is null
            and cat_del_capitolo.data_cancellazione 		is null
            and	r_cat_capitolo.data_cancellazione 			is null
        group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
            capitolo_imp_periodo.anno)            
    select strutt_capitoli.missione_tipo_desc			missione_tipo_desc,
		strutt_capitoli.missione_code				missione_code,
		strutt_capitoli.missione_desc				missione_desc,
		strutt_capitoli.programma_tipo_desc			programma_tipo_desc,
		strutt_capitoli.programma_code				programma_code,
		strutt_capitoli.programma_desc				programma_desc,
        COALESCE(SUM(importi_capitoli_anno1.stanziamento_fpv_anno1),0) stanziamento_fpv_anno1,
        COALESCE(SUM(importi_capitoli_anno2.stanziamento_fpv_anno2),0) stanziamento_fpv_anno2,
        COALESCE(SUM(importi_capitoli_anno3.stanziamento_fpv_anno3),0) stanziamento_fpv_anno3,
        0 fondo_pluri_anno_prec
    from  strutt_capitoli 
        left join capitoli 
            on (capitoli.programma_id = strutt_capitoli.programma_id
                AND capitoli.macroag_id = strutt_capitoli.macroag_id)          
        left join importi_capitoli_anno1
            on importi_capitoli_anno1.elem_id = capitoli.elem_id
        left join importi_capitoli_anno2
            on importi_capitoli_anno2.elem_id = capitoli.elem_id
        left join importi_capitoli_anno3
            on importi_capitoli_anno3.elem_id = capitoli.elem_id
    group by strutt_capitoli.missione_tipo_desc, strutt_capitoli.missione_code, 
    	strutt_capitoli.missione_desc, strutt_capitoli.programma_tipo_desc, 
        strutt_capitoli.programma_code, strutt_capitoli.programma_desc
loop
	missione_tipo_desc:= classifBilRec.missione_tipo_desc;
    missione_code:= classifBilRec.missione_code;
    missione_desc:= classifBilRec.missione_desc;
    programma_tipo_desc:= classifBilRec.programma_tipo_desc;
    programma_code:= classifBilRec.programma_code;
    programma_desc:= classifBilRec.programma_desc;

    bil_anno:=p_anno;
    
    if annoProspInt = annoBilInt then
		fondo_plur_anno_prec_a=classifBilRec.fondo_pluri_anno_prec;
        fondo_plur_anno_h=classifBilRec.stanziamento_fpv_anno1;
   	elsif  annoProspInt = annoBilInt+1 and a_dacapfpv=true then
    	fondo_plur_anno_prec_a=classifBilRec.stanziamento_fpv_anno1;
        fondo_plur_anno_h=classifBilRec.stanziamento_fpv_anno2;
    elsif  annoProspInt = annoBilInt+2 and a_dacapfpv=true then
    	fondo_plur_anno_prec_a=classifBilRec.stanziamento_fpv_anno2;
        fondo_plur_anno_h=classifBilRec.stanziamento_fpv_anno3;
    end if;      
    
    if  annoProspInt > annoBilInt and a_dacapfpv=false and flagretrocomp=false then       
        	--il campo spese_impe_anni_prec_b non viene piu' calcolato in questa
            --procedura.
	      spese_impe_anni_prec_b=0;
           
        /*  select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_impe_anni_prec_b
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno = p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata::integer < p_anno_prospetto::integer-1 -- anno prospetto  
          and e.periodo_id = f.periodo_id
          and f.anno= (p_anno_prospetto::integer-1)::varchar -- anno prospetto
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;		*/
       	    
          spese_da_impeg_anno1_d=0;
        
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno1_d 
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id= p_ente_prop_id
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata = (p_anno_prospetto::integer -1)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer  -- anno prospetto + 1
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;

          spese_da_impeg_anno2_e=0;  
                  
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno2_e  
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          --siac_r_cronop_elem_class rcl1, siac_d_class_tipo clt1,siac_t_class cl1, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno di bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =(p_anno_prospetto::integer-1)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer+1 -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;

          spese_da_impeg_anni_succ_f=0;
                  
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anni_succ_f 
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =(p_anno_prospetto::INTEGER-1)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer > p_anno_prospetto::INTEGER+1 -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;


        if  annoProspInt = annoBilInt+1 then
          	fondo_plur_anno_prec_a=classifBilRec.fondo_pluri_anno_prec - spese_impe_anni_prec_b +
            spese_da_impeg_anno1_d + spese_da_impeg_anno2_e + spese_da_impeg_anni_succ_f;
          	raise notice 'Anno prospetto = %',annoProspInt;
            
        elsif  annoProspInt = annoBilInt+2  then
          fondo_plur_anno_prec_a= - spese_impe_anni_prec_b +
          spese_da_impeg_anno1_d + spese_da_impeg_anno2_e + spese_da_impeg_anni_succ_f;
          	
          	--il campo spese_impe_anni_prec_b non viene piu' calcolato in questa
            --procedura.
          spese_impe_anni_prec_b=0;
            
          /*select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_impe_anni_prec_b
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno = p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata::integer < p_anno_prospetto::integer-2 -- anno prospetto  
          and e.periodo_id = f.periodo_id
          and f.anno= (p_anno_prospetto::integer-2)::varchar -- anno prospetto
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;		
       	    */
          spese_da_impeg_anno1_d=0;
        
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno1_d
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id= p_ente_prop_id
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata = (p_anno_prospetto::integer -2)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer-1  -- anno prospetto + 1
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;

          spese_da_impeg_anno2_e=0;  
                  
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno2_e  
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno di bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =(p_anno_prospetto::integer-2)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;

          spese_da_impeg_anni_succ_f=0;
                  
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anni_succ_f
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =(p_anno_prospetto::INTEGER-2)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer > p_anno_prospetto::INTEGER -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;
          --and rcl1.data_cancellazione is null

		fondo_plur_anno_prec_a=fondo_plur_anno_prec_a+classifBilRec.fondo_pluri_anno_prec - spese_impe_anni_prec_b +
            spese_da_impeg_anno1_d + spese_da_impeg_anno2_e + spese_da_impeg_anni_succ_f;            
            
        end if; --if annoProspInt = annoBilInt+1 then 

       end if; -- if  annoProspInt > annoBilInt

--raise notice 'programma_code = %', programma_code;
--raise notice '  spese_impe_anni_prec_b = %', spese_impe_anni_prec_b;
--raise notice '  quota_fond_plur_anni_prec_c = %', quota_fond_plur_anni_prec_c;
--raise notice '  spese_da_impeg_anno1_d = %', spese_da_impeg_anno1_d;
--raise notice '  spese_da_impeg_anno2_e = %', spese_da_impeg_anno2_e;
--raise notice '  spese_da_impeg_anni_succ_f = %', spese_da_impeg_anni_succ_f;
--raise notice '  spese_da_impeg_non_def_g = %', spese_da_impeg_non_def_g;


/* 17/05/2016: al momento questi campi sono impostati a zero in attesa di
	capire le modalita' di valorizzazione */
		spese_impe_anni_prec_b=0;
        quota_fond_plur_anni_prec_c=0;
        spese_da_impeg_anno1_d=0;
        spese_da_impeg_anno2_e=0;  
        spese_da_impeg_anni_succ_f=0;
        spese_da_impeg_non_def_g=0;
        
        /*COLONNA B -Spese impegnate negli anni precedenti con copertura costituita dal FPV e imputate all'esercizio N
		Occorre prendere tutte le quote di spesa previste nei cronoprogrammi con FPV selezionato, 
		con anno di entrata 2016 (o precedenti) e anno di spesa uguale al 2017.*/ 
       if flagretrocomp = false then

	   		--il campo spese_impe_anni_prec_b non viene piu' calcolato in questa
            --procedura.
         
          /*select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_impe_anni_prec_b
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno = p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata::integer < p_anno_prospetto::integer -- anno prospetto  
          and e.periodo_id = f.periodo_id
          and f.anno=p_anno_prospetto -- anno prospetto
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;*/
          
         -- raise notice 'spese_impe_anni_prec_b %' , spese_impe_anni_prec_b; 
        
        /* 3.	Colonna (c)  e' data dalla differenza tra la colonna b e la colonna a genera e
        rappresenta il valore del fondo costituito che verra' utilizzato negli anni 2018 e seguenti; */
        quota_fond_plur_anni_prec_c=fondo_plur_anno_prec_a-spese_impe_anni_prec_b ;  
       -- raise notice 'quota_fond_plur_anni_prec_c = %', quota_fond_plur_anni_prec_c;  
        
        /*
        Colonna d Occorre prendere tutte le quote di spesa previste nei cronoprogrammi 
        con FPV selezionato, con anno di entrata 2017 e anno di spesa uguale al 2018;
        */
          
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno1_d
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id= p_ente_prop_id
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata = p_anno_prospetto -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer+1  -- anno prospetto + 1
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;
          --and rcl1.data_cancellazione is null;
              
        
        /*
        Colonna e - Occorre prendere tutte le quote di spesa previste nei cronoprogrammi 
        con FPV selezionato, con anno di entrata 2017 e anno di spesa uguale al 2019;
        */
                  
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno2_e
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno di bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =p_anno_prospetto -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer+2 -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;

        
        
        /* Colonna f - Occorre prendere tutte le quote di 
        spesa previste nei cronoprogrammi con FPV selezionato, 
        con anno di entrata 2017 e anno di spesa uguale al 2020 e successivi;*/
                          
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anni_succ_f 
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =p_anno_prospetto -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer > p_anno_prospetto::INTEGER+2 -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;
        
        /*
        d.	Colonna g   Occorre prendere l importo previsto nella sezione spese dei progetti. 
        E  necessario quindi implementare una tipologia  Cronoprogramma da  definire , 
        agganciato al progetto per il quale sono necessarie solo due informazioni: 
        l importo e la Missione/Programma. Rimane incognito l anno relativo alla spesa 
        (anche se apparira' formalmente agganciato al 2017). 
        Nel momento in cui saranno note le altre informazioni relative al progetto, 
        l ente operera' nel modo consueto, ovvero inserendo una nuova versione di cronoprogramma 
        e selezionandone il relativo FPV. Operativamente e' sufficiente inserire un flag "Cronoprogramma da definire". 
        L'operatore entrera' comunque nelle due maschere (cosi' come sono ad oggi) di entrata e 
        spesa e inserira' l'importo e la spesa agganciandola a uno o piu' missioni per la spesa e analogamente per le entrate... 
        Inserira' 2017 sia nelle entrate che nella spesa. Essendo anno entrata=anno spesa non si creera' FPV 
        ma avendo il Flag "Cronoprogramma da Definire" l'unione delle due informazione generera' il 
        popolamento della colonna G. Questo escamotage peraltro potra' essere utilizzato anche dagli enti 
        che vorranno tracciare la loro 
        programmazione anche laddove non ci sia la generazione di FPV, ovviamente senza flaggare il campo citato.
        */
         
        
        /*5.	La colonna h  e' la somma dalla colonna c alla colonna g.
        		NON e' piu' calcolata in questa procedura. */
        
    	if h_dacapfpv = false then
        	fondo_plur_anno_h=quota_fond_plur_anni_prec_c+spese_da_impeg_anno1_d+
            	spese_da_impeg_anno2_e+spese_da_impeg_anni_succ_f+spese_da_impeg_non_def_g;
        end if;
     end if; --if flagretrocomp = false then
    
/*raise notice 'programma_codeXXX = %', programma_code;
raise notice '  spese_impe_anni_prec_b = %', spese_impe_anni_prec_b;
raise notice '  quota_fond_plur_anni_prec_c = %', quota_fond_plur_anni_prec_c;
raise notice '  spese_da_impeg_anno1_d = %', spese_da_impeg_anno1_d;
raise notice '  spese_da_impeg_anno2_e = %', spese_da_impeg_anno2_e;
raise notice '  spese_da_impeg_anni_succ_f = %', spese_da_impeg_anni_succ_f;
raise notice '  spese_da_impeg_non_def_g = %', spese_da_impeg_non_def_g;*/
    

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

  fondo_plur_anno_prec_a=0;
  spese_impe_anni_prec_b=0;
  quota_fond_plur_anni_prec_c=0;
  spese_da_impeg_anno1_d=0;
  spese_da_impeg_anno2_e=0;
  spese_da_impeg_anni_succ_f=0;
  spese_da_impeg_non_def_g=0;
  fondo_plur_anno_h=0;        
end loop;  

raise notice 'fine OK';
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

CREATE OR REPLACE FUNCTION siac."BILR011_allegato_fpv_previsione_con_dati_gestione" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
)
RETURNS TABLE (
  missione_code varchar,
  missione_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  importi_capitoli numeric,
  spese_impegnate numeric,
  spese_impegnate_anno1 numeric,
  spese_impegnate_anno2 numeric,
  spese_impegnate_anno_succ numeric,
  importo_avanzo numeric,
  importo_avanzo_anno1 numeric,
  importo_avanzo_anno2 numeric,
  importo_avanzo_anno_succ numeric,
  elem_id integer,
  anno_esercizio varchar
) AS
$body$
DECLARE

RTN_MESSAGGIO text;
bilancio_id integer;
bilancio_id_prec integer;
cod_fase_operativa varchar;
anno_esercizio varchar;
anno_esercizio_prec varchar;
annoimpimpegni_int integer;
annoprospetto_int integer;
annoprospetto_prec_int varchar;

BEGIN

/*
	12/03/2019: SIAC-6623.
    	Funzione copia della BILR171_allegato_fpv_previsione_con_dati_gestione che serve
        per il calcolo dei campi relativi alle prime 2 colonne del report BILR011.
		Poiche' il report BILR171 viene eliminato la funzione 
        BILR171_allegato_fpv_previsione_con_dati_gestione e' superflua ma NON viene
        cancellata perche' serve per gli anni precedenti il 2018.
*/

/*Se la fase di bilancio e' Previsione allora l''anno di esercizio e il bilancio id saranno
quelli di p_anno-1 per tutte le colonne. 

Se la fase di bilancio e' Esercizio Provvisorio allora l''anno di esercizio e il bilancio id saranno
quelli di p_anno per tutte le colonne tranne quella relativa agli importi dei capitolo (colonna a).
In questo caso l''anno di esercizio e il bilancio id saranno quelli di p_anno-1.

L'anno relativo agli importi dei capitoli e' anno_esercizio_prec
L'anno relativo agli importi degli impegni e' annoImpImpegni_int*/


-- SIAC-6063
/*Aggiunto parametro p_anno_prospetto
Variabile annoImpImpegni_int sostituita da annoprospetto_int
Azzerati importi  spese_impegnate_anno1
                  spese_impegnate_anno2
                  spese_impegnate_anno_succ
                  importo_avanzo_anno1
                  importo_avanzo_anno2
                  importo_avanzo_anno_succ*/

RTN_MESSAGGIO := 'select 1'; 

bilancio_id := null;
bilancio_id_prec := null;

select bil.bil_id, fase_operativa.fase_operativa_code
into   bilancio_id, cod_fase_operativa
from  siac_d_fase_operativa fase_operativa, 
      siac_r_bil_fase_operativa bil_fase_operativa, 
      siac_t_bil bil, 
      siac_t_periodo periodo
where fase_operativa.fase_operativa_id = bil_fase_operativa.fase_operativa_id
and   bil_fase_operativa.bil_id = bil.bil_id
and   periodo.periodo_id = bil.periodo_id
and   fase_operativa.fase_operativa_code in ('P','E','G') -- SIAC-5778 Aggiunto G
and   bil.ente_proprietario_id = p_ente_prop_id
and   periodo.anno = p_anno
and   fase_operativa.data_cancellazione is null
and   bil_fase_operativa.data_cancellazione is null 
and   bil.data_cancellazione is null 
and   periodo.data_cancellazione is null;
 
/*if cod_fase_operativa = 'P' then
  
  anno_esercizio := ((p_anno::integer)-1)::varchar;   

  select a.bil_id 
  into bilancio_id 
  from siac_t_bil a,siac_t_periodo b
  where a.ente_proprietario_id = p_ente_prop_id 
  and b.periodo_id = a.periodo_id
  and b.anno = anno_esercizio;
  
  annoprospetto_int := p_anno_prospetto::integer-1;
  
elsif cod_fase_operativa in ('E','G') then

  anno_esercizio := p_anno;
  annoprospetto_int := p_anno_prospetto::integer;
   
end if;*/
 
  anno_esercizio := ((p_anno::integer)-1)::varchar;   

  select a.bil_id 
  into bilancio_id 
  from siac_t_bil a,siac_t_periodo b
  where a.ente_proprietario_id = p_ente_prop_id 
  and b.periodo_id = a.periodo_id
  and b.anno = anno_esercizio;
  
  annoprospetto_int := p_anno_prospetto::integer;
  
  annoprospetto_prec_int := ((p_anno_prospetto::integer)-1)::varchar;

-- anno_esercizio_prec := ((anno_esercizio::integer)-1)::varchar;
anno_esercizio_prec := ((p_anno::integer)-1)::varchar;

select a.bil_id
into bilancio_id_prec 
from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id 
and b.periodo_id = a.periodo_id
and b.anno = anno_esercizio_prec;

-- annoImpImpegni_int := anno_esercizio::integer; 
-- annoImpImpegni_int := p_anno::integer; -- SIAC-6063

return query
select 
zz.*
from (
select 
tab1.*
from (
with struttura as (
select *
from fnc_bilr_struttura_cap_bilancio_spese (p_ente_prop_id,anno_esercizio,null) -- Potrebbe essere anche anno_esercizio_prec
),
capitoli_anno_prec as (
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
       	capitolo.elem_code, capitolo.elem_desc, capitolo.elem_code2,
        capitolo.elem_desc2, capitolo.elem_code3, capitolo.elem_id
from siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_stato r_capitolo_stato,
     siac_d_bil_elem_stato stato_capitolo,      
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 	 
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr
where capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id 						
and capitolo.elem_id = r_capitolo_stato.elem_id							
and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id		
and	capitolo.elem_id = r_capitolo_programma.elem_id							
and capitolo.elem_id = r_capitolo_macroaggr.elem_id							
and programma.classif_tipo_id = programma_tipo.classif_tipo_id 				
and programma.classif_id = r_capitolo_programma.classif_id					
and macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 			
and macroaggr.classif_id = r_capitolo_macroaggr.classif_id					
and	capitolo.elem_id = r_cat_capitolo.elem_id				
and r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id		
and capitolo.ente_proprietario_id = p_ente_prop_id							
and capitolo.bil_id = bilancio_id_prec													
and programma_tipo.classif_tipo_code = 'PROGRAMMA'							
and	macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
and stato_capitolo.elem_stato_code = 'VA' 
and cat_del_capitolo.elem_cat_code in ('FPV','FPVC')    
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
and	r_cat_capitolo.data_cancellazione           is null
),
capitoli_importo as ( -- Fondo pluriennale vincolato al 31 dicembre dell''esercizio N-1
select 		capitolo_importi.elem_id,
           	sum(capitolo_importi.elem_det_importo) importi_capitoli
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_d_bil_elem_tipo 		tipo_elemento,
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
where capitolo_importi.ente_proprietario_id = p_ente_prop_id  								 
and	capitolo.elem_id = capitolo_importi.elem_id 
and	capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id
and	capitolo_importi.elem_det_tipo_id = capitolo_imp_tipo.elem_det_tipo_id 		
and	capitolo_imp_periodo.periodo_id = capitolo_importi.periodo_id 
and	capitolo.elem_id = r_capitolo_stato.elem_id			
and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id
and	capitolo.elem_id = r_cat_capitolo.elem_id				
and	r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id	
and	capitolo.bil_id = bilancio_id_prec							
and	tipo_elemento.elem_tipo_code = 'CAP-UG'
and	capitolo_imp_periodo.anno = annoprospetto_prec_int		  
--and	capitolo_imp_periodo.anno = anno_esercizio_prec	
and	stato_capitolo.elem_stato_code = 'VA'								
and	cat_del_capitolo.elem_cat_code in ('FPV','FPVC')
and capitolo_imp_tipo.elem_det_tipo_code = 'STA'				
and	capitolo_importi.data_cancellazione 		is null
and	capitolo_imp_tipo.data_cancellazione 		is null
and	capitolo_imp_periodo.data_cancellazione 	is null
and	capitolo.data_cancellazione 				is null
and	tipo_elemento.data_cancellazione 			is null
and	stato_capitolo.data_cancellazione 			is null 
and	r_capitolo_stato.data_cancellazione 		is null
and cat_del_capitolo.data_cancellazione 		is null
and	r_cat_capitolo.data_cancellazione 			is null
group by capitolo_importi.elem_id
)
select 
struttura.missione_code::varchar,
struttura.missione_desc::varchar,
struttura.programma_code::varchar,
struttura.programma_desc::varchar,
COALESCE(capitoli_importo.importi_capitoli,0)::numeric,
0::numeric spese_impegnate,
0::numeric spese_impegnate_anno1,
0::numeric spese_impegnate_anno2,
0::numeric spese_impegnate_anno_succ,
0::numeric importo_avanzo,
0::numeric importo_avanzo_anno1,
0::numeric importo_avanzo_anno2,
0::numeric importo_avanzo_anno_succ,
capitoli_anno_prec.elem_id::integer,
anno_esercizio::varchar
from struttura
left join capitoli_anno_prec on struttura.programma_id = capitoli_anno_prec.programma_id
                   and struttura.macroag_id = capitoli_anno_prec.macroaggregato_id
left join capitoli_importo on capitoli_anno_prec.elem_id = capitoli_importo.elem_id
) tab1
union all
select 
tab2.*
from (
with struttura as (
select *
from fnc_bilr_struttura_cap_bilancio_spese (p_ente_prop_id,anno_esercizio,null)
),
capitoli as (
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
       	capitolo.elem_code, capitolo.elem_desc, capitolo.elem_code2,
        capitolo.elem_desc2, capitolo.elem_code3, capitolo.elem_id
from siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_stato r_capitolo_stato,
     siac_d_bil_elem_stato stato_capitolo,      
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 	 
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr
where capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id 						
and capitolo.elem_id = r_capitolo_stato.elem_id							
and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id		
and	capitolo.elem_id = r_capitolo_programma.elem_id							
and capitolo.elem_id = r_capitolo_macroaggr.elem_id							
and programma.classif_tipo_id = programma_tipo.classif_tipo_id 				
and programma.classif_id = r_capitolo_programma.classif_id					
and macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 				
and macroaggr.classif_id = r_capitolo_macroaggr.classif_id					
and	capitolo.elem_id = r_cat_capitolo.elem_id				
and r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id		
and capitolo.ente_proprietario_id = p_ente_prop_id							
and capitolo.bil_id = bilancio_id													
and programma_tipo.classif_tipo_code = 'PROGRAMMA'							
and	macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
and stato_capitolo.elem_stato_code = 'VA' 
-- and cat_del_capitolo.elem_cat_code in ('FPV','FPVC')    
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
and	r_cat_capitolo.data_cancellazione           is null
),
dati_impegni as (
with importo_impegni as (
with   impegni as (
select ts_impegni_legati.movgest_ts_b_id,
       movimento.movgest_anno anno_impegno
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_b_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    movimento.movgest_anno  >= annoprospetto_int
-- and    movimento.movgest_anno  >= annoImpImpegni_int
and    movimento.bil_id = bilancio_id
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    ts_movimento.data_cancellazione is null
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno
),
imp_impegni_accertamenti as (
select ts_impegni_legati.movgest_ts_b_id,
       movimento.movgest_anno anno_accertamento,
       sum(ts_impegni_legati.movgest_ts_importo) movgest_ts_importo       
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_a_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    ts_impegni_legati.avav_id is null
and    movimento.bil_id = bilancio_id
and    movimento.movgest_anno <= annoprospetto_int+2
-- and    movimento.movgest_anno <= annoImpImpegni_int+2
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    ts_movimento.data_cancellazione is null
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno 
),
imp_impegni_avanzo as (
select ts_impegni_legati.movgest_ts_b_id,
       sum(ts_impegni_legati.movgest_ts_importo) movgest_ts_importo,
       movimento.movgest_anno        
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_avanzovincolo avanzovincolo on ts_impegni_legati.avav_id = avanzovincolo.avav_id
inner  join siac_d_avanzovincolo_tipo tipo_avanzovincolo on avanzovincolo.avav_tipo_id = tipo_avanzovincolo.avav_tipo_id
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_b_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    movimento.bil_id = bilancio_id
and    ts_impegni_legati.movgest_ts_a_id is null
and    tipo_avanzovincolo.avav_tipo_code in ('AAM','FPVSC','FPVCC')
and    movimento.movgest_anno >= annoprospetto_int
-- and    movimento.movgest_anno >= annoImpImpegni_int
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    avanzovincolo.data_cancellazione is null 
and    tipo_avanzovincolo.data_cancellazione is null
and    ts_movimento.data_cancellazione is null 
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno 
)
select impegni.movgest_ts_b_id,
       case 
        when impegni.anno_impegno = annoprospetto_int and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int-1 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate,  
       case 
        when impegni.anno_impegno = annoprospetto_int+1 and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate_anno1,   
       case 
        when impegni.anno_impegno = annoprospetto_int+2 and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int+1 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate_anno2,    
       case 
        when impegni.anno_impegno > annoprospetto_int+2 and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int+2 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate_anno_succ,
       case 
        when impegni.anno_impegno = annoprospetto_int then
             sum(imp_impegni_avanzo.movgest_ts_importo)
       end importo_avanzo,    
       case 
        when impegni.anno_impegno = annoprospetto_int+1 then
             sum(imp_impegni_avanzo.movgest_ts_importo)
       end importo_avanzo_anno1,      
       case 
        when impegni.anno_impegno = annoprospetto_int+2 then
             sum(imp_impegni_avanzo.movgest_ts_importo)            
       end importo_avanzo_anno2,
       case 
        when impegni.anno_impegno > annoprospetto_int+2 then
             sum(imp_impegni_avanzo.movgest_ts_importo)            
       end importo_avanzo_anno_succ                      
from   impegni
left   join imp_impegni_accertamenti on impegni.movgest_ts_b_id = imp_impegni_accertamenti.movgest_ts_b_id
left   join imp_impegni_avanzo on impegni.movgest_ts_b_id = imp_impegni_avanzo.movgest_ts_b_id
group by impegni.movgest_ts_b_id, impegni.anno_impegno, imp_impegni_accertamenti.anno_accertamento
),
capitoli_impegni as (
select capitolo.elem_id, ts_movimento.movgest_ts_id
from  siac_t_bil_elem                 capitolo
inner join siac_r_movgest_bil_elem    r_mov_capitolo on r_mov_capitolo.elem_id = capitolo.elem_id
inner join siac_d_bil_elem_tipo       t_capitolo on capitolo.elem_tipo_id = t_capitolo.elem_tipo_id
inner join siac_t_movgest             movimento on r_mov_capitolo.movgest_id = movimento.movgest_id
inner join siac_t_movgest_ts          ts_movimento on movimento.movgest_id = ts_movimento.movgest_id
inner join siac_r_movgest_ts_stato    ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner join siac_d_movgest_stato       stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where capitolo.ente_proprietario_id = p_ente_prop_id
and   capitolo.bil_id =	bilancio_id
and   movimento.bil_id = bilancio_id
and   t_capitolo.elem_tipo_code = 'CAP-UG'
and   movimento.movgest_anno >= annoprospetto_int
-- and   movimento.movgest_anno >= annoImpImpegni_int
and   stato.movgest_stato_code in ('D','N')-- SIAC-5778
and   capitolo.data_cancellazione is null 
and   r_mov_capitolo.data_cancellazione is null 
and   t_capitolo.data_cancellazione is null
and   movimento.data_cancellazione is null 
and   ts_movimento.data_cancellazione is null
and   ts_stato.data_cancellazione is null-- SIAC-5778
and   stato.data_cancellazione is null-- SIAC-5778 
)
select 
capitoli_impegni.elem_id,
sum(importo_impegni.spese_impegnate) spese_impegnate,
sum(importo_impegni.spese_impegnate_anno1) spese_impegnate_anno1,
sum(importo_impegni.spese_impegnate_anno2) spese_impegnate_anno2,
sum(importo_impegni.spese_impegnate_anno_succ) spese_impegnate_anno_succ,
sum(importo_impegni.importo_avanzo) importo_avanzo,
sum(importo_impegni.importo_avanzo_anno1) importo_avanzo_anno1,
sum(importo_impegni.importo_avanzo_anno2) importo_avanzo_anno2,
sum(importo_impegni.importo_avanzo_anno_succ) importo_avanzo_anno_succ
from capitoli_impegni
left join importo_impegni on capitoli_impegni.movgest_ts_id = importo_impegni.movgest_ts_b_id
group by capitoli_impegni.elem_id
)
select 
struttura.missione_code::varchar,
struttura.missione_desc::varchar,
struttura.programma_code::varchar,
struttura.programma_desc::varchar,
0::numeric importi_capitoli,
COALESCE(dati_impegni.spese_impegnate,0)::numeric spese_impegnate,
/*COALESCE(dati_impegni.spese_impegnate_anno1,0)::numeric spese_impegnate_anno1,
COALESCE(dati_impegni.spese_impegnate_anno2,0)::numeric spese_impegnate_anno2,
COALESCE(dati_impegni.spese_impegnate_anno_succ,0)::numeric spese_impegnate_anno_succ,*/
0::numeric spese_impegnate_anno1,
0::numeric spese_impegnate_anno2,
0::numeric spese_impegnate_anno_succ,
COALESCE(dati_impegni.importo_avanzo,0)::numeric importo_avanzo,
/*COALESCE(dati_impegni.importo_avanzo_anno1,0)::numeric importo_avanzo_anno1,
COALESCE(dati_impegni.importo_avanzo_anno2,0)::numeric importo_avanzo_anno2,
COALESCE(dati_impegni.importo_avanzo_anno_succ,0)::numeric importo_avanzo_anno_succ,*/
0::numeric importo_avanzo_anno1,
0::numeric importo_avanzo_anno2,
0::numeric importo_avanzo_anno_succ,
capitoli.elem_id::integer,
anno_esercizio::varchar
from struttura
left join capitoli on  struttura.programma_id = capitoli.programma_id
                   and struttura.macroag_id = capitoli.macroaggregato_id
left join dati_impegni on  capitoli.elem_id = dati_impegni.elem_id
) tab2
) as zz;

-- raise notice 'Dati % - %',anno_esercizio::varchar,anno_esercizio_prec::varchar;
-- raise notice 'Dati % - %',bilancio_id::varchar,bilancio_id_prec::varchar;

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

CREATE OR REPLACE FUNCTION siac."fnc_lancio_BILR011_anni_precedenti_gestione" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
)
RETURNS TABLE (
  missione varchar,
  programma varchar,
  imp_colonna_h numeric
) AS
$body$
DECLARE

BEGIN

/*
	12/03/2019: SIAC-6623.
    	Funzione copia della fnc_lancio_BILR171_anni_precedenti che serve
        per il calcolo dei campi relativi alle prime 2 colonne del report BILR011.
        Richiama la BILR011_allegato_fpv_previsione_con_dati_gestione con parametri 
        diversi a seconda dell'anno di prospetto.
		Poiche' il report BILR171 viene eliminato per l'anno 2018 la funzione 
        fnc_lancio_BILR171_anni_precedenti rimane per gli anni precedenti.
*/

if p_anno_prospetto::integer = (p_anno::integer)+1 then
   
  return query
  select missione_code, programma_code, 
         sum(importi_capitoli-(importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as importo_colonna_h
  from "BILR011_allegato_fpv_previsione_con_dati_gestione" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-1)::varchar
  )
  group by missione_code, programma_code;

elsif p_anno_prospetto::integer = (p_anno::integer)+2 then

  return query
    select a.missione_code, a.programma_code,
    (a.importo_colonna_h-b.importo_colonna_h) as imp_colonna_h
  from (
  select missione_code, 
         programma_code, 
         sum(importi_capitoli-(importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as importo_colonna_h
  from "BILR011_allegato_fpv_previsione_con_dati_gestione" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-2)::varchar
  )
  group by missione_code, programma_code
  ) a, 
  (select missione_code, programma_code, 
         sum((importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as  importo_colonna_h
  from "BILR011_allegato_fpv_previsione_con_dati_gestione" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-1)::varchar
  )
  group by missione_code, programma_code
  ) b
  where a.missione_code = b.missione_code
  and   a.programma_code = b.programma_code;

end if;
  
EXCEPTION
  when others  THEN
  RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(SQLERRM from 1 for 500);
  return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."fnc_lancio_BILR223_anni_precedenti_gestione_capitolo" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
)
RETURNS TABLE (
  missione varchar,
  programma varchar,
  bil_elem_code varchar,
  bil_elem_desc varchar,
  bil_elem_code2 varchar,
  bil_elem_desc2 varchar,
  bil_elem_code3 varchar,
  imp_colonna_h numeric
) AS
$body$
DECLARE

BEGIN

/*
	12/03/2019: SIAC-6623.
    	Funzione copia della fnc_lancio_BILR011_anni_precedenti_gestione che serve
        per il calcolo dei campi relativi alle prime 2 colonne del report BILR223.
        Richiama la BILR223_allegato_fpv_previsione_dati_gestione_capitolo con parametri 
        diversi a seconda dell'anno di prospetto.
		Rispetto all'analoga del report BILR011 questa restituisce anche i dati del 
        capitolo.
*/

if p_anno_prospetto::integer = (p_anno::integer)+1 then
   
  return query
  select proc1.missione_code, proc1.programma_code, 
    proc1.bil_elem_code, proc1.bil_elem_desc, proc1.bil_elem_code2, 
    proc1.bil_elem_desc2, proc1.bil_elem_code3,
         sum(importi_capitoli-(importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as importo_colonna_h
  from "BILR223_allegato_fpv_previsione_dati_gestione_capitolo" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-1)::varchar
  ) proc1
  group by proc1.missione_code, proc1.programma_code,
  	proc1.bil_elem_code, proc1.bil_elem_desc, proc1.bil_elem_code2, 
    proc1.bil_elem_desc2, proc1.bil_elem_code3;

elsif p_anno_prospetto::integer = (p_anno::integer)+2 then

  return query
    select a.missione_code, a.programma_code,
    a.bil_elem_code, a.bil_elem_desc, a.bil_elem_code2, a.bil_elem_desc2, a.bil_elem_code3,
    (a.importo_colonna_h-b.importo_colonna_h) as imp_colonna_h
  from (
  select proc2.missione_code, 
         proc2.programma_code, 
         proc2.bil_elem_code, proc2.bil_elem_desc, proc2.bil_elem_code2, 
         proc2.bil_elem_desc2, proc2.bil_elem_code3,
         sum(importi_capitoli-(importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as importo_colonna_h
  from "BILR223_allegato_fpv_previsione_dati_gestione_capitolo" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-2)::varchar
  ) proc2
  group by proc2.missione_code, proc2.programma_code,
  	proc2.bil_elem_code, proc2.bil_elem_desc, proc2.bil_elem_code2, 
    proc2.bil_elem_desc2, proc2.bil_elem_code3
  ) a, 
  (select proc3.missione_code, proc3.programma_code, 
  		proc3.bil_elem_code, proc3.bil_elem_desc, proc3.bil_elem_code2, 
        proc3.bil_elem_desc2, proc3.bil_elem_code3,
         sum((importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as  importo_colonna_h
  from "BILR223_allegato_fpv_previsione_dati_gestione_capitolo" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-1)::varchar
  ) proc3
  group by proc3.missione_code, proc3.programma_code,
  	proc3.bil_elem_code, proc3.bil_elem_desc, proc3.bil_elem_code2, 
    proc3.bil_elem_desc2, proc3.bil_elem_code3
  ) b
  where a.missione_code = b.missione_code
  and   a.programma_code = b.programma_code
  and   a.bil_elem_code  = b.bil_elem_code
  and   a.bil_elem_code2  = b.bil_elem_code2
  and	a.bil_elem_code3 = a.bil_elem_code3;

end if;
  
EXCEPTION
  when others  THEN
  RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(SQLERRM from 1 for 500);
  return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-6623 Maurizio - FINE

-- SIAC-6661 Sofia - inizio

drop table if exists siac_bko_t_caricamento_pdce_conto;
CREATE TABLE siac_bko_t_caricamento_pdce_conto
(
  carica_pdce_conto_id SERIAL,
  pdce_conto_code      VARCHAR not null,
  pdce_conto_desc      VARCHAR not null,
  tipo_operazione      varchar not null,
  classe_conto         varchar not null,
  livello              integer not null,
  codifica_bil         varchar not null,
  tipo_conto           varchar not null,
  conto_foglia         varchar,
  conto_di_legge       varchar,
  conto_codifica_interna varchar,
  ammortamento        varchar,
  conto_attivo        varchar not null default 'S',
  conto_segno_negativo varchar,
  caricato BOOLEAN DEFAULT false NOT NULL,
  ambito VARCHAR DEFAULT 'AMBITO_FIN'::character varying NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) DEFAULT 'admin-carica-pdce' NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  validita_fine   TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id integer not null,
  CONSTRAINT pk_siac_bko_t_caricamento_pdce_conto PRIMARY KEY(carica_pdce_conto_id),
  CONSTRAINT siac_t_ente_proprietario_siac_bko_t_caricamento_pdce_conto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX siac_bko_t_caricamento_pdce_conto_idx ON siac_bko_t_caricamento_pdce_conto
  USING btree (pdce_conto_code COLLATE pg_catalog."default",
               pdce_conto_desc COLLATE pg_catalog."default",
               ambito COLLATE pg_catalog."default"
               )
  WHERE (data_cancellazione IS NULL);


CREATE INDEX siac_bko_t_caricamento_pdce_conto_fk_ente_proprietario_id_idx ON siac_bko_t_caricamento_pdce_conto
  USING btree (ente_proprietario_id);


drop table if exists siac_bko_t_caricamento_causali;
CREATE TABLE siac_bko_t_caricamento_causali
(
  carica_cau_id SERIAL,
  pdc_fin VARCHAR,
  codice_causale VARCHAR,
  descrizione_causale VARCHAR,
  pdc_econ_patr VARCHAR,
  conto_iva VARCHAR,
  segno VARCHAR,
  livelli VARCHAR,
  tipo_conto VARCHAR,
  tipo_importo VARCHAR,
  utilizzo_conto VARCHAR,
  utilizzo_importo VARCHAR,
  causale_default VARCHAR,
  caricata BOOLEAN DEFAULT false NOT NULL,
  ambito VARCHAR DEFAULT 'AMBITO_FIN'::character varying NOT NULL,
  causale_tipo VARCHAR DEFAULT 'INT'::character varying NOT NULL,
  eu varchar not null,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) DEFAULT 'admin-carica-cau' NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  validita_fine   TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id integer not null,
  CONSTRAINT pk_siac_bko_t_caricamento_causali PRIMARY KEY(carica_cau_id),
  CONSTRAINT siac_t_ente_proprietario_siac_bko_t_caricamento_causali FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX siac_bko_t_caricamento_causali_idx ON siac_bko_t_caricamento_causali
  USING btree (pdc_fin COLLATE pg_catalog."default",
               codice_causale COLLATE pg_catalog."default",
               descrizione_causale COLLATE pg_catalog."default",
               pdc_econ_patr COLLATE pg_catalog."default", conto_iva COLLATE pg_catalog."default",segno COLLATE pg_catalog."default",
               livelli COLLATE pg_catalog."default",
               tipo_conto COLLATE pg_catalog."default",
               tipo_importo COLLATE pg_catalog."default",
               utilizzo_conto COLLATE pg_catalog."default",
               utilizzo_importo COLLATE pg_catalog."default",
               causale_default COLLATE pg_catalog."default")
  WHERE (data_cancellazione IS NULL);


CREATE INDEX siac_bko_t_caricamento_causali_fk_ente_proprietario_id_idx ON siac_bko_t_caricamento_causali
  USING btree (ente_proprietario_id);

drop table if exists siac_bko_t_causale_evento;
CREATE TABLE siac_bko_t_causale_evento
(
  carica_cau_ev_id SERIAL,
  pdc_fin          varchar not null,
  codice_causale   varchar not null,
  tipo_evento      varchar not null,
  evento           varchar not null,
  eu               varchar not null,
  caricata BOOLEAN DEFAULT false NOT NULL,
  ambito VARCHAR DEFAULT 'AMBITO_FIN'::character varying NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) DEFAULT 'admin-carica-cau-ev' NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  validita_fine   TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id integer not null,
  CONSTRAINT pk_siac_bko_t_causale_evento PRIMARY KEY(carica_cau_ev_id),
  CONSTRAINT siac_t_ente_proprietario_siac_bko_t_causale_evento FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE INDEX siac_bko_t_causale_evento_fk_pdc_fin_idx ON siac_bko_t_causale_evento
  USING btree (pdc_fin);

CREATE INDEX siac_bko_t_causale_evento_fk_codice_causale_idx ON siac_bko_t_causale_evento
  USING btree (codice_causale);



CREATE INDEX siac_bko_t_causale_evento_fk_ente_proprietario_id_idx ON siac_bko_t_causale_evento
  USING btree (ente_proprietario_id);
  
drop function if exists fnc_siac_bko_caricamento_pdce_conto
(
  annoBilancio                    integer,
  enteProprietarioId              integer,
  ambitoCode                      varchar,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
);

drop function if exists fnc_siac_bko_caricamento_causali
(
  annoBilancio                    integer,
  enteProprietarioId              integer,
  ambitoCode                      varchar,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
);

CREATE OR REPLACE FUNCTION fnc_siac_bko_caricamento_pdce_conto
(
  annoBilancio                    integer,
  enteProprietarioId              integer,
  ambitoCode                      varchar,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

    codResult integer:=null;

    dateInizVal timestamp:=null;
BEGIN

	strMessaggioFinale:='Inserimento conti PDC_ECON di generale ambitoCode='||ambitoCode||'.';

    codiceRisultato:=0;
    messaggioRisultato:='';

    strMessaggio:='Verifica esistenza conti da creare in siac_bko_t_caricamento_pdce_conto.';
    select 1 into codResult
    from siac_bko_t_caricamento_pdce_conto bko
    where bko.ente_proprietario_id=enteProprietarioId
    and   bko.ambito=ambitoCode
    and   bko.caricato=false
    and   bko.data_cancellazione is null
	and   bko.validita_fine is null;

    if codResult is null then
    	raise exception ' Conti non presenti.';
    end if;

    dateInizVal:=(annoBilancio::varchar||'-01-01')::timestamp;

	codResult:=null;
	-- siac_t_class B.13.a
    strMessaggio:='Inserimento codice di bilancio B.13.a [siac_t_class].';
    insert into siac_t_class
    (
      classif_code,
      classif_desc,
      classif_tipo_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select
     'a',
     'Personale',
     tipo.classif_tipo_id,
     dateInizVal,
     loginOperazione,
     tipo.ente_proprietario_id
    from siac_v_dwh_codifiche_econpatr dwh,siac_t_class c,siac_d_class_tipo tipo,
         siac_r_class_fam_tree r,siac_t_class_fam_tree tree, siac_d_class_fam fam
    where dwh.ente_proprietario_id=enteProprietarioId
    and   dwh.codice_codifica_albero = 'B.13'
    and   c.classif_id=dwh.classif_id
    and   tipo.classif_tipo_id=c.classif_tipo_id
    and   tipo.classif_tipo_code not like '%GSA'
    and   r.classif_id=c.classif_id
    and   tree.classif_fam_tree_id=r.classif_fam_tree_id
    and   fam.classif_fam_id=tree.classif_fam_id
/*    and   not exists
    (
    select 1
    from siac_t_class c1
    where c1.ente_proprietario_id=tipo.ente_proprietario_id
    and   c1.classif_tipo_id=tipo.classif_tipo_id
    and   c1.classif_code='a'
    and   c1.data_cancellazione is null
    )*/
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    returning classif_id into codResult;
	raise notice 'strMessaggio=% %',strMessaggio,codResult;

    codResult:=null;
 	-- siac_r_class_fam_tree B.13.a

    strMessaggio:='Inserimento codice di bilancio B.13.a [siac_r_class_fam_tree].';
    insert into siac_r_class_fam_tree
    (
      classif_fam_tree_id,
      classif_id,
      classif_id_padre,
      ordine,
      livello,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select tree.classif_fam_tree_id,
           cnew.classif_id,
           c.classif_id,
           r.ordine||'.'||cnew.classif_code,
           r.livello+1,
           dateInizVal,
           loginOperazione,
           tipo.ente_proprietario_id
    from siac_v_dwh_codifiche_econpatr dwh,siac_t_class c,siac_d_class_tipo tipo,
         siac_r_class_fam_tree r,siac_t_class_fam_tree tree, siac_d_class_fam fam,
         siac_t_class cnew
    where dwh.ente_proprietario_id=enteProprietarioId
    and   dwh.codice_codifica_albero = 'B.13'
    and   c.classif_id=dwh.classif_id
    and   tipo.classif_tipo_id=c.classif_tipo_id
    and   tipo.classif_tipo_code not like '%GSA'
    and   r.classif_id=c.classif_id
    and   tree.classif_fam_tree_id=r.classif_fam_tree_id
    and   fam.classif_fam_id=tree.classif_fam_id
    and   cnew.ente_proprietario_id=enteProprietarioId
    and   cnew.login_operazione =loginOperazione
    and   not exists
    (
    select 1 from siac_r_class_fam_tree r1
    where r1.ente_proprietario_id=tipo.ente_proprietario_id
    and   r1.classif_id=cnew.classif_id
    and   r1.classif_id_padre=c.classif_id
    and   r1.classif_fam_tree_id=tree.classif_fam_tree_id
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
    )
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    returning classif_classif_fam_tree_id into codResult;
	raise notice 'strMessaggio=% %',strMessaggio,codResult;


    codResult:=null;
	-- siac_t_pdce_conto
    strMessaggio:='Inserimento conti livello V [siac_t_pdce_conto].';
    insert into siac_t_pdce_conto
    (
      pdce_conto_code,
      pdce_conto_desc,
      pdce_conto_id_padre,
      livello,
      ordine,
      pdce_fam_tree_id,
      pdce_ct_tipo_id,
      ambito_id,
      validita_inizio,
      ente_proprietario_id,
      login_operazione,
      login_creazione
    )
    select
      bko.pdce_conto_code,
      bko.pdce_conto_desc,
      contoPadre.pdce_conto_id,
      bko.livello,
      bko.pdce_conto_code,
      tree.pdce_fam_tree_id,
      tipo.pdce_ct_tipo_id,
      ambito.ambito_id,
      dateInizVal,
      tipo.ente_proprietario_id,
      bko.login_operazione||'-'||loginOperazione||'@'||bko.carica_pdce_conto_id::varchar,
      bko.login_operazione||'-'||loginOperazione
    from siac_t_ente_proprietario ente,
         siac_bko_t_caricamento_pdce_conto bko,
         siac_t_pdce_fam_tree tree,siac_d_pdce_fam fam,
         siac_d_ambito ambito,
         siac_d_pdce_conto_tipo tipo,
         siac_t_pdce_conto contoPadre
    where ente.ente_proprietario_id=enteProprietarioId
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   bko.ente_proprietario_id=ambito.ente_proprietario_id
    and   bko.ambito=ambito.ambito_code
    and   fam.ambito_id=ambito.ambito_id
    and   fam.pdce_fam_code=bko.classe_conto
    and   tree.pdce_fam_id=fam.pdce_fam_id
    and   tipo.pdce_ct_tipo_code=bko.tipo_conto
    and   tipo.ente_proprietario_id=ambito.ente_proprietario_id
    and   bko.tipo_operazione='I'
    and   bko.livello=5
    and   contoPadre.ente_proprietario_id=tipo.ente_proprietario_id
    and   contoPadre.pdce_fam_tree_id=tree.pdce_fam_tree_id
    and   contoPadre.livello=bko.livello-1
    and   contoPadre.ambito_id=ambito.ambito_id
    and   contoPadre.pdce_conto_code =
          SUBSTRING(bko.pdce_conto_code from 1 for length(bko.pdce_conto_code)- position('.' in reverse(bko.pdce_conto_code)))
    and   bko.caricato=false
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null
    and   not exists
    (
    select 1 from siac_t_pdce_conto conto
    where conto.ente_proprietario_id=enteProprietarioId
    and   conto.pdce_conto_code=bko.pdce_conto_code
    and   conto.ambito_id=ambito.ambito_id
    and   conto.livello=5
    and   conto.pdce_ct_tipo_id=tipo.pdce_ct_tipo_id
    and   conto.pdce_fam_tree_id=tree.pdce_fam_tree_id
    and   conto.data_cancellazione is null
    and   conto.validita_fine is null
    );
	GET DIAGNOSTICS codResult = ROW_COUNT;
   	raise notice 'Conti livello V inseriti=%',codResult;


    codResult:=null;
	-- siac_t_pdce_conto
    strMessaggio:='Inserimento conti livello VI [siac_t_pdce_conto].';
   	insert into siac_t_pdce_conto
    (
      pdce_conto_code,
      pdce_conto_desc,
      pdce_conto_id_padre,
      livello,
      ordine,
      pdce_fam_tree_id,
      pdce_ct_tipo_id,
      ambito_id,
      validita_inizio,
      ente_proprietario_id,
      login_operazione,
      login_creazione
    )
    select
      bko.pdce_conto_code,
      bko.pdce_conto_desc,
      contoPadre.pdce_conto_id,
      bko.livello,
      bko.pdce_conto_code,
      tree.pdce_fam_tree_id,
      tipo.pdce_ct_tipo_id,
      ambito.ambito_id,
      dateInizVal,
      tipo.ente_proprietario_id,
      bko.login_operazione||'-'||loginOperazione||'@'||bko.carica_pdce_conto_id::varchar,
      bko.login_operazione||'-'||loginOperazione
    from siac_t_ente_proprietario ente,
         siac_bko_t_caricamento_pdce_conto bko,
         siac_t_pdce_fam_tree tree,siac_d_pdce_fam fam,
         siac_d_ambito ambito,
         siac_d_pdce_conto_tipo tipo,
         siac_t_pdce_conto contoPadre
    where ente.ente_proprietario_id=enteProprietarioId
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   bko.ente_proprietario_id=ambito.ente_proprietario_id
    and   bko.ambito=ambito.ambito_code
    and   fam.ambito_id=ambito.ambito_id
    and   fam.pdce_fam_code=bko.classe_conto
    and   tree.pdce_fam_id=fam.pdce_fam_id
    and   tipo.pdce_ct_tipo_code=bko.tipo_conto
    and   tipo.ente_proprietario_id=ambito.ente_proprietario_id
    and   bko.tipo_operazione='I'
    and   bko.livello=6
    and   contoPadre.ente_proprietario_id=tipo.ente_proprietario_id
    and   contoPadre.pdce_fam_tree_id=tree.pdce_fam_tree_id
    and   contoPadre.livello=bko.livello-1
    and   contoPadre.ambito_id=ambito.ambito_id
    and   contoPadre.pdce_conto_code =
          SUBSTRING(bko.pdce_conto_code from 1 for length(bko.pdce_conto_code)- position('.' in reverse(bko.pdce_conto_code)))
    and   bko.caricato=false
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null
    and   not exists
    (
    select 1 from siac_t_pdce_conto conto
    where conto.ente_proprietario_id=enteProprietarioId
    and   conto.pdce_conto_code=bko.pdce_conto_code
    and   conto.ambito_id=ambito.ambito_id
    and   conto.livello=6
    and   conto.pdce_ct_tipo_id=tipo.pdce_ct_tipo_id
    and   conto.pdce_fam_tree_id=tree.pdce_fam_tree_id
    and   conto.data_cancellazione is null
    and   conto.validita_fine is null
    );
	GET DIAGNOSTICS codResult = ROW_COUNT;
   	raise notice 'Conti livello VI inseriti=%',codResult;

    codResult:=null;
	-- siac_t_pdce_conto
    strMessaggio:='Inserimento conti livello VII [siac_t_pdce_conto].';
    insert into siac_t_pdce_conto
    (
      pdce_conto_code,
      pdce_conto_desc,
      pdce_conto_id_padre,
      livello,
      ordine,
      pdce_fam_tree_id,
      pdce_ct_tipo_id,
      ambito_id,
      validita_inizio,
      ente_proprietario_id,
      login_operazione,
      login_creazione
    )
    select
      bko.pdce_conto_code,
      bko.pdce_conto_desc,
      contoPadre.pdce_conto_id,
      bko.livello,
      bko.pdce_conto_code,
      tree.pdce_fam_tree_id,
      tipo.pdce_ct_tipo_id,
      ambito.ambito_id,
      dateInizVal,
      tipo.ente_proprietario_id,
      bko.login_operazione||'-'||loginOperazione||'@'||bko.carica_pdce_conto_id::varchar,
      bko.login_operazione||'-'||loginOperazione
    from siac_t_ente_proprietario ente,
         siac_bko_t_caricamento_pdce_conto bko,
         siac_t_pdce_fam_tree tree,siac_d_pdce_fam fam,
         siac_d_ambito ambito,
         siac_d_pdce_conto_tipo tipo,
         siac_t_pdce_conto contoPadre
    where ente.ente_proprietario_id=enteProprietarioId
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   bko.ente_proprietario_id=ambito.ente_proprietario_id
    and   bko.ambito=ambito.ambito_code
    and   fam.ambito_id=ambito.ambito_id
    and   fam.pdce_fam_code=bko.classe_conto
    and   tree.pdce_fam_id=fam.pdce_fam_id
    and   tipo.pdce_ct_tipo_code=bko.tipo_conto
    and   tipo.ente_proprietario_id=ambito.ente_proprietario_id
    and   bko.tipo_operazione='I'
    and   bko.livello=7
    and   contoPadre.ente_proprietario_id=tipo.ente_proprietario_id
    and   contoPadre.pdce_fam_tree_id=tree.pdce_fam_tree_id
    and   contoPadre.livello=bko.livello-1
    and   contoPadre.ambito_id=ambito.ambito_id
    and   contoPadre.pdce_conto_code =
          SUBSTRING(bko.pdce_conto_code from 1 for length(bko.pdce_conto_code)- position('.' in reverse(bko.pdce_conto_code)))
    and   bko.caricato=false
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null
    and   not exists
    (
    select 1 from siac_t_pdce_conto conto
    where conto.ente_proprietario_id=enteProprietarioId
    and   conto.pdce_conto_code=bko.pdce_conto_code
    and   conto.ambito_id=ambito.ambito_id
    and   conto.livello=7
    and   conto.pdce_ct_tipo_id=tipo.pdce_ct_tipo_id
    and   conto.pdce_fam_tree_id=tree.pdce_fam_tree_id
    and   conto.data_cancellazione is null
    and   conto.validita_fine is null
    );
    GET DIAGNOSTICS codResult = ROW_COUNT;
   	raise notice 'Conti livello VII inseriti=%',codResult;

    codResult:=null;
    strMessaggio:='Inserimento conti - attributi pdce_conto_foglia [siac_r_pdce_conto_attr].';

    -- siac_r_pdce_conto_attr
    -- pdce_conto_foglia
    insert into siac_r_pdce_conto_attr
    (
        pdce_conto_id,
        attr_id,
        boolean,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    select conto.pdce_conto_id,
           attr.attr_id,
           'S',
           dateInizVal,
           bko.login_operazione||'-'||loginOperazione,
           attr.ente_proprietario_id
    from siac_t_ente_proprietario ente,
         siac_bko_t_caricamento_pdce_conto bko,siac_t_pdce_conto conto,siac_t_attr attr,
         siac_d_ambito ambito
    where ente.ente_proprietario_id=enteProprietarioId
    and   attr.ente_proprietario_id=ente.ente_proprietario_id
    and   attr.attr_code='pdce_conto_foglia'
    and   bko.ente_proprietario_id=attr.ente_proprietario_id
    and   bko.tipo_operazione='I'
    and   ambito.ente_proprietario_id=attr.ente_proprietario_id
    and   ambito.ambito_code=bko.ambito
    and   coalesce(bko.conto_foglia,'')='S'
--    and   conto.login_operazione like '%'||bko.login_operazione||'-'||loginOperazione||'@%'
    and   conto.login_operazione like '%'||loginOperazione||'@%'

    and   conto.pdce_conto_code=bko.pdce_conto_code
    and   conto.ambito_id=ambito.ambito_id
    and   bko.carica_pdce_conto_id=SUBSTRING(conto.login_operazione, POSITION('@' in conto.login_operazione)+1)::integer
    and   bko.caricato=false
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;
	GET DIAGNOSTICS codResult = ROW_COUNT;
   	raise notice 'Attributi pdce_conto_foglia inseriti=%',codResult;

    codResult:=null;
    strMessaggio:='Inserimento conti - attributi pdce_conto_di_legge [siac_r_pdce_conto_attr].';

    -- pdce_conto_di_legge
    insert into siac_r_pdce_conto_attr
    (
        pdce_conto_id,
        attr_id,
        boolean,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    select conto.pdce_conto_id,
           attr.attr_id,
           'S',
           dateInizVal,
           bko.login_operazione||'-'||loginOperazione,
           attr.ente_proprietario_id
    from siac_t_ente_proprietario ente,
         siac_bko_t_caricamento_pdce_conto bko,siac_t_pdce_conto conto,siac_t_attr attr,
         siac_d_ambito ambito
    where ente.ente_proprietario_id=enteProprietarioId
    and   attr.ente_proprietario_id=ente.ente_proprietario_id
    and   attr.attr_code='pdce_conto_di_legge'
    and   bko.ente_proprietario_id=attr.ente_proprietario_id
    and   bko.tipo_operazione='I'
    and   ambito.ente_proprietario_id=attr.ente_proprietario_id
    and   ambito.ambito_code=bko.ambito
    and   coalesce(bko.conto_di_legge,'')='S'
--    and   conto.login_operazione like bko.login_operazione||'-'||loginOperazione||'@%'
    and   conto.login_operazione like '%'||loginOperazione||'@%'
    and   conto.ambito_id=ambito.ambito_id
    and   conto.pdce_conto_code=bko.pdce_conto_code
    and   bko.carica_pdce_conto_id=SUBSTRING(conto.login_operazione, POSITION('@' in conto.login_operazione)+1)::integer
    and   bko.caricato=false
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;
	GET DIAGNOSTICS codResult = ROW_COUNT;
   	raise notice 'Attributi pdce_conto_di_legge inseriti=%',codResult;

    codResult:=null;
    strMessaggio:='Inserimento conti - attributi pdce_ammortamento [siac_r_pdce_conto_attr].';

    -- pdce_ammortamento
    insert into siac_r_pdce_conto_attr
    (
        pdce_conto_id,
        attr_id,
        boolean,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    select conto.pdce_conto_id,
           attr.attr_id,
           'S',
           dateInizVal,
           bko.login_operazione||'-'||loginOperazione,
           attr.ente_proprietario_id
    from siac_t_ente_proprietario ente,
         siac_bko_t_caricamento_pdce_conto bko,siac_t_pdce_conto conto,siac_t_attr attr,
         siac_d_ambito ambito
    where ente.ente_proprietario_id=enteProprietarioId
    and   attr.ente_proprietario_id=ente.ente_proprietario_id
    and   attr.attr_code='pdce_ammortamento'
    and   bko.ente_proprietario_id=attr.ente_proprietario_id
    and   bko.tipo_operazione='I'
    and   ambito.ente_proprietario_id=attr.ente_proprietario_id
    and   ambito.ambito_code=bko.ambito
    and   coalesce(bko.ammortamento,'')='S'
--    and   conto.login_operazione like bko.login_operazione||'-'||loginOperazione||'@%'
    and   conto.login_operazione like '%'||loginOperazione||'@%'
    and   conto.ambito_id=ambito.ambito_id
    and   conto.pdce_conto_code=bko.pdce_conto_code

    and   bko.carica_pdce_conto_id=SUBSTRING(conto.login_operazione, POSITION('@' in conto.login_operazione)+1)::integer
    and   bko.caricato=false
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
   	raise notice 'Attributi pdce_ammortamento inseriti=%',codResult;

    codResult:=null;
    strMessaggio:='Inserimento conti - attributi pdce_conto_attivo [siac_r_pdce_conto_attr].';
    -- pdce_conto_attivo
    insert into siac_r_pdce_conto_attr
    (
        pdce_conto_id,
        attr_id,
        boolean,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    select conto.pdce_conto_id,
           attr.attr_id,
           'S',
           dateInizVal,
           bko.login_operazione||'-'||loginOperazione,
           attr.ente_proprietario_id
    from siac_t_ente_proprietario ente,
         siac_bko_t_caricamento_pdce_conto bko,siac_t_pdce_conto conto,siac_t_attr attr,
         siac_d_ambito ambito
    where ente.ente_proprietario_id=enteProprietarioId
    and   attr.ente_proprietario_id=ente.ente_proprietario_id
    and   attr.attr_code='pdce_conto_attivo'
    and   bko.ente_proprietario_id=attr.ente_proprietario_id
    and   bko.tipo_operazione='I'
    and   ambito.ente_proprietario_id=attr.ente_proprietario_id
    and   ambito.ambito_code=bko.ambito
    and   coalesce(bko.conto_attivo,'')='S'
--    and   conto.login_operazione like bko.login_operazione||'-'||loginOperazione||'@%'
    and   conto.login_operazione like '%'||loginOperazione||'@%'
    and   conto.ambito_id=ambito.ambito_id
    and   conto.pdce_conto_code=bko.pdce_conto_code

    and   bko.carica_pdce_conto_id=SUBSTRING(conto.login_operazione, POSITION('@' in conto.login_operazione)+1)::integer
    and   bko.caricato=false
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;
	GET DIAGNOSTICS codResult = ROW_COUNT;
   	raise notice 'Attributi pdce_conto_attivo inseriti=%',codResult;

    codResult:=null;
    strMessaggio:='Inserimento conti - attributi pdce_conto_segno_negativo [siac_r_pdce_conto_attr].';
    -- pdce_conto_segno_negativo
    insert into siac_r_pdce_conto_attr
    (
        pdce_conto_id,
        attr_id,
        boolean,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    select conto.pdce_conto_id,
           attr.attr_id,
           'S',
           dateInizVal,
           bko.login_operazione||'-'||loginOperazione,
           attr.ente_proprietario_id
    from siac_t_ente_proprietario ente,
         siac_bko_t_caricamento_pdce_conto bko,siac_t_pdce_conto conto,siac_t_attr attr,
         siac_d_ambito ambito
    where ente.ente_proprietario_id=enteProprietarioId
    and   attr.ente_proprietario_id=ente.ente_proprietario_id
    and   attr.attr_code='pdce_conto_segno_negativo'
    and   bko.ente_proprietario_id=attr.ente_proprietario_id
    and   bko.tipo_operazione='I'
    and   ambito.ente_proprietario_id=attr.ente_proprietario_id
    and   ambito.ambito_code=bko.ambito
    and   coalesce(bko.conto_segno_negativo,'')='S'
--    and   conto.login_operazione like bko.login_operazione||'-'||loginOperazione||'@%'
    and   conto.login_operazione like '%'||loginOperazione||'@%'
    and   conto.ambito_id=ambito.ambito_id
    and   conto.pdce_conto_code=bko.pdce_conto_code

    and   bko.carica_pdce_conto_id=SUBSTRING(conto.login_operazione, POSITION('@' in conto.login_operazione)+1)::integer
    and   bko.caricato=false
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;
	GET DIAGNOSTICS codResult = ROW_COUNT;
   	raise notice 'Attributi pdce_conto_segno_negativo inseriti=%',codResult;

    codResult:=null;
    strMessaggio:='Inserimento conti - codifica_bil [siac_r_pdce_conto_class].';
    -- siac_r_pdce_conto_class
    insert into siac_r_pdce_conto_class
    (
        pdce_conto_id,
        classif_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    select conto.pdce_conto_id,
           dwh.classif_id,
           dateInizVal,
           bko.login_operazione||'-'||loginOperazione,
           conto.ente_proprietario_id
    from siac_t_ente_proprietario ente,
         siac_v_dwh_codifiche_econpatr dwh, siac_bko_t_caricamento_pdce_conto bko,
         siac_t_pdce_conto conto, siac_d_ambito ambito
    where ente.ente_proprietario_id=enteProprietarioId
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   bko.ente_proprietario_id=ambito.ente_proprietario_id
    and   bko.tipo_operazione='I'
    and   ambito.ambito_code=bko.ambito
---    and   conto.login_operazione like bko.login_operazione||'-'||loginOperazione||'@%'
    and   conto.login_operazione like '%'||loginOperazione||'@%'
    and   conto.ambito_id=ambito.ambito_id
    and   conto.pdce_conto_code=bko.pdce_conto_code

    and   bko.carica_pdce_conto_id=SUBSTRING(conto.login_operazione, POSITION('@' in conto.login_operazione)+1)::integer
    and   coalesce(bko.codifica_bil,'')!=''
    and   dwh.ente_proprietario_id=conto.ente_proprietario_id
    and   dwh.codice_codifica_albero=bko.codifica_bil
    and   bko.caricato=false
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;

	GET DIAGNOSTICS codResult = ROW_COUNT;
   	raise notice 'Codifiche di bilancio  pdce_conto inserite=%',codResult;


    codResult:=null;
    strMessaggio:='Aggiornamento  conti esistenti - descrizione  [siac_t_pdce_conto].';
    update  siac_t_pdce_conto conto
	set     pdce_conto_desc=bko.pdce_conto_desc,
    	    data_modifica=clock_timestamp(),
        	login_operazione=conto.login_operazione||'-'||bko.login_operazione||'-'||loginOperazione
	from siac_t_ente_proprietario ente,
    	 siac_bko_t_caricamento_pdce_conto bko, siac_d_ambito ambito
	where ente.ente_proprietario_id=enteProprietarioId
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   conto.ambito_id=ambito.ambito_id
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   bko.ambito=ambito.ambito_code
    and   bko.tipo_operazione='A'
    and   bko.pdce_conto_code=conto.pdce_conto_code
    and   bko.caricato=false
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;

	codResult:=null;
    strMessaggio:='Aggiornamento  conti esistenti - codif_bil - chiusura  [siac_r_pdce_conto_class].';
    update siac_r_pdce_conto_class rc
    set     data_cancellazione=clock_timestamp(),
            validita_fine=clock_timestamp(),
            login_operazione=rc.login_operazione||'-'||bko.login_operazione||'-'||loginOperazione
    from siac_t_ente_proprietario ente,siac_d_class_tipo tipo,siac_t_class c,
         siac_bko_t_caricamento_pdce_conto bko, siac_d_ambito ambito , siac_t_pdce_conto conto,
         siac_v_dwh_codifiche_econpatr dwh
    where ente.ente_proprietario_id=enteProprietarioId
    and   tipo.ente_proprietario_id=ente.ente_proprietario_id
    and   tipo.classif_tipo_code in
    (
    'SPA_CODBIL',
    'SPP_CODBIL',
    'CE_CODBIL',
    'CO_CODBIL'
    )
    and   c.classif_tipo_id=tipo.classif_tipo_id
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   conto.ambito_id=ambito.ambito_id
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   bko.ambito=ambito.ambito_code
    and   bko.tipo_operazione='A'
    and   bko.pdce_conto_code=conto.pdce_conto_code
    and   coalesce(bko.codifica_bil,'')!=''
    and   dwh.ente_proprietario_id=ente.ente_proprietario_id
    and   dwh.codice_codifica_albero=bko.codifica_bil
    and   rc.classif_id=c.classif_id
    and   rc.pdce_conto_id=conto.pdce_conto_id
    and   bko.caricato=false
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null
    and   rc.data_cancellazione is null
    and   rc.validita_fine is null;

    codResult:=null;
    strMessaggio:='Aggiornamento  conti esistenti - codif_bil - inserimento  [siac_r_pdce_conto_class].';
    insert into siac_r_pdce_conto_class
    (
        pdce_conto_id,
        classif_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    select conto.pdce_conto_id,
           dwh.classif_id,
           dateInizVal,
           bko.login_operazione||'-'||loginOperazione,
           conto.ente_proprietario_id
    from siac_t_ente_proprietario ente,
         siac_bko_t_caricamento_pdce_conto bko, siac_d_ambito ambito , siac_t_pdce_conto conto,
         siac_v_dwh_codifiche_econpatr dwh
    where ente.ente_proprietario_id=enteProprietarioId
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   conto.ambito_id=ambito.ambito_id
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   bko.ambito=ambito.ambito_code
    and   bko.tipo_operazione='A'
    and   bko.pdce_conto_code=conto.pdce_conto_code
    and   coalesce(bko.codifica_bil,'')!=''
    and   dwh.ente_proprietario_id=ente.ente_proprietario_id
    and   dwh.codice_codifica_albero=bko.codifica_bil
    and   bko.caricato=false
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
   	raise notice 'Codifiche di bilancio  pdce_conto inserite=%',codResult;

    messaggioRisultato:=strMessaggioFinale||' Elaborazione terminata.';

    raise notice '%',messaggioRisultato;

    return;

exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION fnc_siac_bko_caricamento_causali
(
  annoBilancio                    integer,
  enteProprietarioId              integer,
  ambitoCode                      varchar,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

    codResult integer:=null;
    numeroCausali integer:=null;
    dateInizVal timestamp:=null;
BEGIN

	strMessaggioFinale:='Inserimento causale di generale ambitoCode='||ambitoCode||'.';

    codiceRisultato:=0;
    messaggioRisultato:='';

    strMessaggio:='Verifica esistenza causali da creare in siac_bko_t_caricamento_causali.';
    select 1 into codResult
    from siac_bko_t_caricamento_causali bko
    where bko.ente_proprietario_id=enteProprietarioId
    and   bko.ambito=ambitoCode
    and   bko.caricata=false
    and   bko.data_cancellazione is null
	and   bko.validita_fine is null;

    if codResult is null then
    	raise exception ' Causali non presenti.';
    end if;

    strMessaggio:='Pulizia blanck siac_bko_t_caricamento_causali.';
    update siac_bko_t_caricamento_causali bko
    set    pdc_fin=ltrim(rtrim(bko.pdc_fin)),
           codice_causale=ltrim(rtrim(bko.codice_causale)),
           descrizione_causale=ltrim(rtrim(bko.descrizione_causale)),
           pdc_econ_patr=ltrim(rtrim(bko.pdc_econ_patr)),
           segno=ltrim(rtrim(bko.segno)),
           conto_iva=ltrim(rtrim(bko.conto_iva)),
           livelli=ltrim(rtrim(bko.livelli)),
           tipo_conto=ltrim(rtrim(bko.tipo_conto)),
           tipo_importo=ltrim(rtrim(bko.tipo_importo)),
           utilizzo_conto=ltrim(rtrim(bko.utilizzo_conto)),
           utilizzo_importo=ltrim(rtrim(bko.utilizzo_importo)),
           causale_default=ltrim(rtrim(bko.causale_default))
    where bko.ente_proprietario_id=enteProprietarioId
    and   bko.ambito=ambitoCode
    and   bko.caricata=false
    and   bko.data_cancellazione is null
	and   bko.validita_fine is null;

	strMessaggio:='Pulizia blanck siac_bko_t_causale_evento.';
	update siac_bko_t_causale_evento bko
	set    pdc_fin=ltrim(rtrim(bko.pdc_fin)),
    	   codice_causale=ltrim(rtrim(bko.codice_causale)),
		   tipo_evento=ltrim(rtrim(bko.tipo_evento)),
		   evento=ltrim(rtrim(bko.evento))
    where bko.ente_proprietario_id=enteProprietarioId
    and   bko.ambito=ambitoCode
    and   bko.caricata=false
    and   bko.data_cancellazione is null
	and   bko.validita_fine is null;

    dateInizVal:=(annoBilancio::varchar||'-01-01')::timestamp;

    -- siac_t_causale_ep
    strMessaggio:='Inserimento causali [siac_t_causale_ep].';
    insert into siac_t_causale_ep
    (
      causale_ep_code,
      causale_ep_desc,
      causale_ep_tipo_id,
      ambito_id,
      validita_inizio,
      login_operazione,
      login_creazione,
      ente_proprietario_id
    )
    select distinct bko.codice_causale,
           bko.descrizione_causale,
           tipo.causale_ep_tipo_id,
           ambito.ambito_id,
           dateInizVal,
           bko.login_operazione||'-'||loginOperazione||'-'||bko.eu||'@'||bko.pdc_fin,
           bko.login_operazione||'-'||loginOperazione||'-'||bko.eu,
           tipo.ente_proprietario_id
    from siac_bko_t_caricamento_causali bko,siac_t_ente_proprietario ente,siac_d_causale_ep_tipo tipo,
         siac_d_ambito ambito
    where ente.ente_proprietario_id=enteProprietarioId
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   tipo.ente_proprietario_id=ente.ente_proprietario_id
    and   tipo.causale_ep_tipo_code=bko.causale_tipo
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   ambito.ambito_code=bko.ambito
    and   bko.caricata=false
 --   and   bko.eu='U'
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null
    and   not exists
    (
    select 1 from siac_t_causale_ep ep
    where ep.ente_proprietario_id=enteProprietarioId
    and   ep.causale_ep_code=bko.codice_causale
    and   ep.ambito_id=ambito.ambito_id
    and   ep.data_cancellazione is null
    and   ep.validita_fine is null
    );
	GET DIAGNOSTICS numeroCausali = ROW_COUNT;
	if coalesce(numeroCausali,0)=0  then
    	raise exception ' Inserimento non effettuato.';
    end if;

    raise notice 'numeroCausali=%',numeroCausali;

    codResult:=null;
    strMessaggio:='Inserimento causali  - stato [siac_r_causale_ep_stato].';
    -- siac_r_causale_ep_stato
    insert into siac_r_causale_ep_stato
    (
        causale_ep_id,
        causale_ep_stato_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    select ep.causale_ep_id,
           stato.causale_ep_stato_id,
           dateInizVal,
           ep.login_operazione,
           stato.ente_proprietario_id
    from siac_d_causale_ep_stato stato ,siac_t_causale_ep ep, siac_t_ente_proprietario ente
    where ente.ente_proprietario_id=enteProprietarioId
    and   stato.ente_proprietario_id=ente.ente_proprietario_id
    and   stato.causale_ep_stato_code='V'
    and   ep.ente_proprietario_id=ente.ente_proprietario_id
--    and   ep.login_operazione like '%'||loginOperazione||'%U%';
    and   ep.login_operazione like '%'||loginOperazione||'%';

    GET DIAGNOSTICS codResult = ROW_COUNT;
	if coalesce(codResult,0)=0  then
    	raise exception ' Inserimento non effettuato.';
    end if;
    raise notice 'numeroStatoCausali=%',codResult;
    codResult:=null;
    strMessaggio:='Inserimento causali  - PdcFin [siac_r_causale_ep_class].';

    -- siac_r_causale_ep_class
    insert into siac_r_causale_ep_class
    (
        causale_ep_id,
        classif_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    select ep.causale_ep_id,
           c.classif_id,
           dateInizVal,
           ep.login_operazione,
           ente.ente_proprietario_id
    from siac_t_causale_ep ep, siac_t_ente_proprietario ente,siac_t_class c,siac_d_class_tipo tipo
    where ente.ente_proprietario_id=enteProprietarioId
    and   tipo.ente_proprietario_id =ente.ente_proprietario_id
    and   tipo.classif_tipo_code='PDC_V'
    and   c.classif_tipo_id=tipo.classif_tipo_id
    and   ep.ente_proprietario_id=ente.ente_proprietario_id
--    and   ep.login_operazione like '%'||loginOperazione||'%U%'
    and   ep.login_operazione like '%'||loginOperazione||'%'
    and   c.classif_code=substring(ep.login_operazione, position('@' in ep.login_operazione)+1)
    and   c.data_cancellazione is null;
	GET DIAGNOSTICS codResult = ROW_COUNT;
	if coalesce(codResult,0)=0  then
    	raise exception ' Inserimento non effettuato.';
    end if;
    raise notice 'numeroPdcFinCausali=%',codResult;

    codResult:=null;
    strMessaggio:='Inserimento causali - pdcContoEcon - PdcFin [siac_r_causale_ep_pdce_conto].';
    -- siac_r_causale_ep_pdce_conto
    insert into siac_r_causale_ep_pdce_conto
    (
      causale_ep_id,
      pdce_conto_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select distinct
           ep.causale_ep_id,
           conto.pdce_conto_id,
           dateInizVal,
--           bko.login_operazione||'-'||bko.eu||'@'||bko.carica_cau_id::varchar,
           bko.login_operazione||'-'||loginOperazione||'-'||bko.eu,
           conto.ente_proprietario_id
    from siac_t_causale_ep ep, siac_t_ente_proprietario ente, siac_bko_t_caricamento_causali bko,
         siac_t_pdce_conto conto,siac_d_ambito ambito
    where ente.ente_proprietario_id=enteProprietarioId
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   ep.ente_proprietario_id=ente.ente_proprietario_id
--    and   ep.login_operazione like '%'||loginOperazione||'%U%'
    and   ep.login_operazione like '%'||loginOperazione||'-'||bko.eu||'%'
    and   ep.causale_ep_code=bko.codice_causale
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   ambito.ambito_code=bko.ambito
    and   ep.ambito_id=ambito.ambito_id
    and   conto.ente_proprietario_id=ente.ente_proprietario_id
    and   conto.pdce_conto_code=bko.pdc_econ_patr
    and   conto.ambito_id=ep.ambito_id
    and   bko.caricata=false
    and   not exists
    (
    select 1 from siac_r_causale_ep_pdce_conto r1
    where r1.ente_proprietario_id=ente.ente_proprietario_id
    and   r1.causale_ep_id=ep.causale_ep_id
    and   r1.pdce_conto_id=conto.pdce_conto_id
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
    )
--    and   bko.eu='U'
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null
    and   conto.data_cancellazione is null
    and   conto.validita_fine is null;

	GET DIAGNOSTICS codResult = ROW_COUNT;
	if coalesce(codResult,0)=0  then
    	raise exception ' Inserimento non effettuato.';
    end if;
    raise notice 'numeroContiCausali=%',codResult;

    -- segno
    codResult:=null;
    strMessaggio:='Inserimento causali - pdcContoEcon - SEGNO  [siac_r_causale_ep_pdce_conto_oper].';
	insert into siac_r_causale_ep_pdce_conto_oper
    (
      causale_ep_pdce_conto_id,
      oper_ep_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select distinct
           r.causale_ep_pdce_conto_id,
           oper.oper_ep_id,
           dateInizVal,
           r.login_operazione,
           ente.ente_proprietario_id
    from siac_t_ente_proprietario ente, siac_bko_t_caricamento_causali bko , siac_r_causale_ep_pdce_conto r,
         siac_d_operazione_ep oper, siac_t_causale_ep ep,siac_d_ambito ambito,siac_t_pdce_conto conto
    where ente.ente_proprietario_id=enteProprietarioId
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   ep.ente_proprietario_id=ente.ente_proprietario_id
	and   ep.login_operazione like '%'||loginOperazione||'-'||bko.eu||'%'
    and   ep.causale_ep_code=bko.codice_causale
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   ambito.ambito_code=bko.ambito
    and   ep.ambito_id=ambito.ambito_id
    and   conto.ente_proprietario_id=ente.ente_proprietario_id
    and   conto.pdce_conto_code=bko.pdc_econ_patr
    and   conto.ambito_id=ambito.ambito_id
    and   r.ente_proprietario_id=ente.ente_proprietario_id
    and   r.login_operazione like '%'||loginOperazione||'-'||bko.eu--||'%'
    and   r.causale_ep_id=ep.causale_ep_id
    and   r.pdce_conto_id=conto.pdce_conto_id
--    and   bko.carica_cau_id=substring(r.login_operazione, position('@' in r.login_operazione)+1)::integer
    and   oper.ente_proprietario_id=ente.ente_proprietario_id
    and   oper.oper_ep_code=upper(bko.segno)
    and   bko.caricata=false
--    and   bko.eu='U'
	and   not exists
    (
    select 1 from siac_r_causale_ep_pdce_conto_oper r1
    where r1.causale_ep_pdce_conto_id=r.causale_ep_pdce_conto_id
    and   r1.oper_ep_id=oper.oper_ep_id
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
    )
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
	if coalesce(codResult,0)=0  then
    	raise exception ' Inserimento non effettuato.';
    end if;
    raise notice 'numeroContiSEGNOCausali=%',codResult;

    codResult:=null;
    strMessaggio:='Inserimento causali - pdcContoEcon - TIPO IMPORTO  [siac_r_causale_ep_pdce_conto_oper].';
    -- tipo_importo
   /* insert into siac_r_causale_ep_pdce_conto_oper
    (
      causale_ep_pdce_conto_id,
      oper_ep_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select distinct
           r.causale_ep_pdce_conto_id,
           oper.oper_ep_id,
           dateInizVal,
           r.login_operazione,
           ente.ente_proprietario_id
    from siac_t_ente_proprietario ente, siac_bko_t_caricamento_causali bko , siac_r_causale_ep_pdce_conto r,
         siac_d_operazione_ep oper
    where ente.ente_proprietario_id=enteProprietarioId
    and   oper.ente_proprietario_id=ente.ente_proprietario_id
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   r.ente_proprietario_id=ente.ente_proprietario_id
--    and   r.login_operazione like '%'||loginOperazione||'%U%'
    and   r.login_operazione like '%'||loginOperazione||'-'||bko.eu||'%'
    and   bko.carica_cau_id=substring(r.login_operazione, position('@' in r.login_operazione)+1)::integer
    and   oper.ente_proprietario_id=ente.ente_proprietario_id
    and   oper.oper_ep_code=upper(bko.tipo_importo)
    and   bko.caricata=false
    and   not exists
    (
    select 1 from siac_r_causale_ep_pdce_conto_oper r1
    where r1.causale_ep_pdce_conto_id=r.causale_ep_pdce_conto_id
    and   r1.oper_ep_id=oper.oper_ep_id
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
    )
  --  and   bko.eu='U'
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;*/

    insert into siac_r_causale_ep_pdce_conto_oper
    (
      causale_ep_pdce_conto_id,
      oper_ep_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select distinct
           r.causale_ep_pdce_conto_id,
           oper.oper_ep_id,
           dateInizVal,
           r.login_operazione,
           ente.ente_proprietario_id
    from siac_t_ente_proprietario ente, siac_bko_t_caricamento_causali bko , siac_r_causale_ep_pdce_conto r,
         siac_d_operazione_ep oper, siac_t_causale_ep ep,siac_d_ambito ambito,siac_t_pdce_conto conto
    where ente.ente_proprietario_id=enteProprietarioId
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   ep.ente_proprietario_id=ente.ente_proprietario_id
	and   ep.login_operazione like '%'||loginOperazione||'-'||bko.eu||'%'
    and   ep.causale_ep_code=bko.codice_causale
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   ambito.ambito_code=bko.ambito
    and   ep.ambito_id=ambito.ambito_id
    and   conto.ente_proprietario_id=ente.ente_proprietario_id
    and   conto.pdce_conto_code=bko.pdc_econ_patr
    and   conto.ambito_id=ambito.ambito_id
    and   r.ente_proprietario_id=ente.ente_proprietario_id
    and   r.login_operazione like '%'||loginOperazione||'-'||bko.eu--||'%'
    and   r.causale_ep_id=ep.causale_ep_id
    and   r.pdce_conto_id=conto.pdce_conto_id
--    and   bko.carica_cau_id=substring(r.login_operazione, position('@' in r.login_operazione)+1)::integer
    and   oper.ente_proprietario_id=ente.ente_proprietario_id
    and   oper.oper_ep_code=upper(bko.tipo_importo)
    and   bko.caricata=false
--    and   bko.eu='U'
	and   not exists
    (
    select 1 from siac_r_causale_ep_pdce_conto_oper r1
    where r1.causale_ep_pdce_conto_id=r.causale_ep_pdce_conto_id
    and   r1.oper_ep_id=oper.oper_ep_id
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
    )
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
	if coalesce(codResult,0)=0  then
    	raise exception ' Inserimento non effettuato.';
    end if;

    raise notice 'numeroContiTIPOIMPORTOCausali=%',codResult;

    -- utilizzo_conto
    codResult:=null;
    strMessaggio:='Inserimento causali - pdcContoEcon - UTILIZZO CONTO  [siac_r_causale_ep_pdce_conto_oper].';
    /*insert into siac_r_causale_ep_pdce_conto_oper
    (
      causale_ep_pdce_conto_id,
      oper_ep_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select distinct
           r.causale_ep_pdce_conto_id,
           oper.oper_ep_id,
           dateInizVal,
           r.login_operazione,
           ente.ente_proprietario_id
    from siac_t_ente_proprietario ente, siac_bko_t_caricamento_causali bko , siac_r_causale_ep_pdce_conto r,
         siac_d_operazione_ep oper
    where ente.ente_proprietario_id=enteProprietarioId
    and   oper.ente_proprietario_id=ente.ente_proprietario_id
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   r.ente_proprietario_id=ente.ente_proprietario_id
--    and   r.login_operazione like '%'||loginOperazione||'%U%'
    and   r.login_operazione like '%'||loginOperazione||'-'||bko.eu||'%'
    and   bko.carica_cau_id=substring(r.login_operazione, position('@' in r.login_operazione)+1)::integer
    and   oper.ente_proprietario_id=ente.ente_proprietario_id
    and   oper.oper_ep_code=upper(bko.utilizzo_conto)
    and   bko.caricata=false
--    and   bko.eu='U'
    and   not exists
    (
    select 1 from siac_r_causale_ep_pdce_conto_oper r1
    where r1.causale_ep_pdce_conto_id=r.causale_ep_pdce_conto_id
    and   r1.oper_ep_id=oper.oper_ep_id
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
    )
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;*/

    insert into siac_r_causale_ep_pdce_conto_oper
    (
      causale_ep_pdce_conto_id,
      oper_ep_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select distinct
           r.causale_ep_pdce_conto_id,
           oper.oper_ep_id,
           dateInizVal,
           r.login_operazione,
           ente.ente_proprietario_id
    from siac_t_ente_proprietario ente, siac_bko_t_caricamento_causali bko , siac_r_causale_ep_pdce_conto r,
         siac_d_operazione_ep oper, siac_t_causale_ep ep,siac_d_ambito ambito,siac_t_pdce_conto conto
    where ente.ente_proprietario_id=enteProprietarioId
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   ep.ente_proprietario_id=ente.ente_proprietario_id
	and   ep.login_operazione like '%'||loginOperazione||'-'||bko.eu||'%'
    and   ep.causale_ep_code=bko.codice_causale
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   ambito.ambito_code=bko.ambito
    and   ep.ambito_id=ambito.ambito_id
    and   conto.ente_proprietario_id=ente.ente_proprietario_id
    and   conto.pdce_conto_code=bko.pdc_econ_patr
    and   conto.ambito_id=ambito.ambito_id
    and   r.ente_proprietario_id=ente.ente_proprietario_id
    and   r.login_operazione like '%'||loginOperazione||'-'||bko.eu--||'%'
    and   r.causale_ep_id=ep.causale_ep_id
    and   r.pdce_conto_id=conto.pdce_conto_id
--    and   bko.carica_cau_id=substring(r.login_operazione, position('@' in r.login_operazione)+1)::integer
    and   oper.ente_proprietario_id=ente.ente_proprietario_id
    and   oper.oper_ep_code=upper(bko.utilizzo_conto)
    and   bko.caricata=false
--    and   bko.eu='U'
	and   not exists
    (
    select 1 from siac_r_causale_ep_pdce_conto_oper r1
    where r1.causale_ep_pdce_conto_id=r.causale_ep_pdce_conto_id
    and   r1.oper_ep_id=oper.oper_ep_id
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
    )
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
	if coalesce(codResult,0)=0  then
    	raise exception ' Inserimento non effettuato.';
    end if;
    raise notice 'numeroContiUTILIZZOCONTOCausali=%',codResult;

    -- utilizzo_importo
    codResult:=null;
    strMessaggio:='Inserimento causali - pdcContoEcon - UTILIZZO IMPORTO  [siac_r_causale_ep_pdce_conto_oper].';
    /*insert into siac_r_causale_ep_pdce_conto_oper
    (
      causale_ep_pdce_conto_id,
      oper_ep_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select distinct
           r.causale_ep_pdce_conto_id,
           oper.oper_ep_id,
           dateInizVal,
           r.login_operazione,
           ente.ente_proprietario_id
    from siac_t_ente_proprietario ente, siac_bko_t_caricamento_causali bko , siac_r_causale_ep_pdce_conto r,
         siac_d_operazione_ep oper
    where ente.ente_proprietario_id=enteProprietarioId
    and   oper.ente_proprietario_id=ente.ente_proprietario_id
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   r.ente_proprietario_id=ente.ente_proprietario_id
--    and   r.login_operazione like '%'||loginOperazione||'%U%'
    and   r.login_operazione like '%'||loginOperazione||'-'||bko.eu||'%'
    and   bko.carica_cau_id=substring(r.login_operazione, position('@' in r.login_operazione)+1)::integer
    and   oper.ente_proprietario_id=ente.ente_proprietario_id
    and   oper.oper_ep_code=upper(bko.utilizzo_importo)
    and   bko.caricata=false
  --  and   bko.eu='U'
    and   not exists
    (
    select 1 from siac_r_causale_ep_pdce_conto_oper r1
    where r1.causale_ep_pdce_conto_id=r.causale_ep_pdce_conto_id
    and   r1.oper_ep_id=oper.oper_ep_id
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
    )
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;*/

    insert into siac_r_causale_ep_pdce_conto_oper
    (
      causale_ep_pdce_conto_id,
      oper_ep_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select distinct
           r.causale_ep_pdce_conto_id,
           oper.oper_ep_id,
           dateInizVal,
           r.login_operazione,
           ente.ente_proprietario_id
    from siac_t_ente_proprietario ente, siac_bko_t_caricamento_causali bko , siac_r_causale_ep_pdce_conto r,
         siac_d_operazione_ep oper, siac_t_causale_ep ep,siac_d_ambito ambito,siac_t_pdce_conto conto
    where ente.ente_proprietario_id=enteProprietarioId
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   ep.ente_proprietario_id=ente.ente_proprietario_id
	and   ep.login_operazione like '%'||loginOperazione||'-'||bko.eu||'%'
    and   ep.causale_ep_code=bko.codice_causale
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   ambito.ambito_code=bko.ambito
    and   ep.ambito_id=ambito.ambito_id
    and   conto.ente_proprietario_id=ente.ente_proprietario_id
    and   conto.pdce_conto_code=bko.pdc_econ_patr
    and   conto.ambito_id=ambito.ambito_id
    and   r.ente_proprietario_id=ente.ente_proprietario_id
    and   r.login_operazione like '%'||loginOperazione||'-'||bko.eu--||'%'
    and   r.causale_ep_id=ep.causale_ep_id
    and   r.pdce_conto_id=conto.pdce_conto_id
--    and   bko.carica_cau_id=substring(r.login_operazione, position('@' in r.login_operazione)+1)::integer
    and   oper.ente_proprietario_id=ente.ente_proprietario_id
    and   oper.oper_ep_code=upper(bko.utilizzo_importo)
    and   bko.caricata=false
--    and   bko.eu='U'
	and   not exists
    (
    select 1 from siac_r_causale_ep_pdce_conto_oper r1
    where r1.causale_ep_pdce_conto_id=r.causale_ep_pdce_conto_id
    and   r1.oper_ep_id=oper.oper_ep_id
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
    )
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
	if coalesce(codResult,0)=0  then
    	raise exception ' Inserimento non effettuato.';
    end if;
    raise notice 'numeroContiUTILIZZOIMPORTOCausali=%',codResult;

	codResult:=null;
    strMessaggio:='Inserimento causali - evento   [siac_r_causale_evento].';
    -- siac_r_evento_causale
    insert into siac_r_evento_causale
    (
      causale_ep_id,
      evento_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select distinct
           ep.causale_ep_id,
           evento.evento_id,
           dateInizVal,
           bko.login_operazione||'-'||loginOperazione,
           ep.ente_proprietario_id
    from siac_t_ente_proprietario ente,siac_bko_t_causale_evento bko,siac_t_causale_ep ep,
         siac_d_evento evento,siac_d_evento_tipo tipo
    where ente.ente_proprietario_id=enteProprietarioId
    and   ep.ente_proprietario_id=ente.ente_proprietario_id
    and   ep.login_operazione like '%'||loginOperazione||'-'||bko.eu||'%'
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   ep.causale_ep_code=bko.codice_causale
    and   tipo.ente_proprietario_id=ente.ente_proprietario_id
    and   tipo.evento_tipo_code=bko.tipo_evento
    and   evento.evento_tipo_id=tipo.evento_tipo_id
    and   evento.evento_code=bko.evento
    and   bko.caricata=false
    and   not exists
    (
    select 1 from siac_r_evento_causale r1
    where r1.causale_ep_id = ep.causale_ep_id
    and   r1.evento_id=evento.evento_id
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
    )
   -- and   bko.eu='U'
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice 'numeroCausaliEvento=%',codResult;

    messaggioRisultato:=strMessaggioFinale||' Inserite '||numeroCausali::varchar||' causali.';

    raise notice '%',messaggioRisultato;

    return;

exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- SIAC-6661 Sofia - fine

--SIAC-6565 inizio

SELECT * from fnc_dba_add_column_params ('siac_t_soggetto', 'email_pec', 'varchar(256)');

SELECT * from fnc_dba_add_column_params ('siac_t_soggetto', 'cod_destinatario', 'varchar(7)');

SELECT * from fnc_dba_add_column_params ('siac_t_soggetto', 'codice_pa', 'varchar(10)');

SELECT * from fnc_dba_add_column_params ('siac_t_doc', 'stato_sdi', 'varchar(2)');

SELECT * from fnc_dba_add_column_params ('siac_t_doc', 'esito_stato_sdi', 'varchar(500)');

SELECT * from fnc_dba_add_column_params ('siac_t_soggetto_mod', 'email_pec', 'varchar(256)');

SELECT * from fnc_dba_add_column_params ('siac_t_soggetto_mod', 'cod_destinatario', 'varchar(7)');

SELECT * from fnc_dba_add_column_params ('siac_t_soggetto_mod', 'codice_pa', 'varchar(10)');

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_documento_entrata (
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

rec_doc_id record;
rec_subdoc_id record;
rec_attr record;
rec_classif_id record;
rec_classif_id_attr record;
-- Variabili per campi estratti dal cursore rec_doc_id
v_ente_proprietario_id INTEGER := null;
v_ente_denominazione VARCHAR := null;
v_anno_doc INTEGER := null;
v_num_doc VARCHAR := null;
v_stato_sdi VARCHAR := null; -- SIAC-6565
v_desc_doc VARCHAR := null;
v_importo_doc NUMERIC := null;
v_beneficiario_multiplo_doc VARCHAR := null;
v_data_emissione_doc TIMESTAMP := null;
v_data_scadenza_doc TIMESTAMP := null;
v_codice_bollo_doc VARCHAR := null;
v_desc_codice_bollo_doc VARCHAR := null;
v_collegato_cec_doc VARCHAR := null;
v_cod_pcc_doc VARCHAR := null;
v_desc_pcc_doc VARCHAR := null;
v_cod_ufficio_doc VARCHAR := null;
v_desc_ufficio_doc VARCHAR := null;
v_cod_stato_doc VARCHAR := null;
v_desc_stato_doc VARCHAR := null;
v_cod_gruppo_doc VARCHAR := null;
v_desc_gruppo_doc VARCHAR := null;
v_cod_famiglia_doc VARCHAR := null;
v_desc_famiglia_doc VARCHAR := null;
v_cod_tipo_doc VARCHAR := null;
v_desc_tipo_doc VARCHAR := null;
v_sogg_id_doc INTEGER := null;
v_cod_sogg_doc VARCHAR := null;
v_tipo_sogg_doc VARCHAR := null;
v_stato_sogg_doc VARCHAR := null;
v_rag_sociale_sogg_doc VARCHAR := null;
v_p_iva_sogg_doc VARCHAR := null;
v_cf_sogg_doc VARCHAR := null;
v_cf_estero_sogg_doc VARCHAR := null;
v_nome_sogg_doc VARCHAR := null;
v_cognome_sogg_doc VARCHAR := null;
--nuova sezione coge 26-09-2016
v_doc_contabilizza_genpcc VARCHAR := null;
-- Variabili per campi estratti dal cursore rec_subdoc_id
v_num_subdoc INTEGER := null;
v_desc_subdoc VARCHAR := null;
v_importo_subdoc NUMERIC := null;
v_num_reg_iva_subdoc VARCHAR := null;
v_data_scadenza_subdoc TIMESTAMP := null;
v_convalida_manuale_subdoc VARCHAR := null;
v_importo_da_dedurre_subdoc NUMERIC := null;
v_splitreverse_importo_subdoc NUMERIC := null;
v_pagato_cec_subdoc VARCHAR := null;
v_data_pagamento_cec_subdoc TIMESTAMP := null;
v_anno_atto_amministrativo VARCHAR := null;
v_num_atto_amministrativo VARCHAR := null;
v_oggetto_atto_amministrativo VARCHAR := null;
v_note_atto_amministrativo VARCHAR := null;
v_cod_tipo_atto_amministrativo VARCHAR := null;
v_desc_tipo_atto_amministrativo VARCHAR := null;
v_cod_stato_atto_amministrativo VARCHAR := null;
v_desc_stato_atto_amministrativo VARCHAR := null;
v_causale_atto_allegato VARCHAR := null;
v_altri_allegati_atto_allegato VARCHAR := null;
v_dati_sensibili_atto_allegato VARCHAR := null;
v_data_scadenza_atto_allegato TIMESTAMP := null;
v_note_atto_allegato VARCHAR := null;
v_annotazioni_atto_allegato VARCHAR := null;
v_pratica_atto_allegato VARCHAR := null;
v_resp_amm_atto_allegato VARCHAR := null;
v_resp_contabile_atto_allegato VARCHAR := null;
v_anno_titolario_atto_allegato INTEGER := null;
v_num_titolario_atto_allegato VARCHAR := null;
v_vers_invio_firma_atto_allegato INTEGER := null;
v_cod_stato_atto_allegato VARCHAR := null;
v_desc_stato_atto_allegato VARCHAR := null;
v_anno_elenco_doc INTEGER := null;
v_num_elenco_doc INTEGER := null;
v_data_trasmissione_elenco_doc TIMESTAMP := null;
v_tot_quote_entrate_elenco_doc NUMERIC := null;
v_tot_quote_spese_elenco_doc NUMERIC := null;
v_tot_da_pagare_elenco_doc NUMERIC := null;
v_tot_da_incassare_elenco_doc NUMERIC := null;
v_cod_stato_elenco_doc VARCHAR := null;
v_desc_stato_elenco_doc VARCHAR := null;
v_note_tesoriere_subdoc VARCHAR := null;
v_cod_distinta_subdoc VARCHAR := null;
v_desc_distinta_subdoc VARCHAR := null;
v_tipo_commissione_subdoc VARCHAR := null;
v_conto_tesoreria_subdoc VARCHAR := null;
-- Variabili per i soggetti legati all'atto allegato
v_sogg_id_atto_allegato INTEGER := null;
v_cod_sogg_atto_allegato VARCHAR := null;
v_tipo_sogg_atto_allegato VARCHAR := null;
v_stato_sogg_atto_allegato VARCHAR := null;
v_rag_sociale_sogg_atto_allegato VARCHAR := null;
v_p_iva_sogg_atto_allegato VARCHAR := null;
v_cf_sogg_atto_allegato VARCHAR := null;
v_cf_estero_sogg_atto_allegato VARCHAR := null;
v_nome_sogg_atto_allegato VARCHAR := null;
v_cognome_sogg_atto_allegato VARCHAR := null;
-- Variabili per i classificatori
v_cod_cdr_atto_amministrativo VARCHAR := null;
v_desc_cdr_atto_amministrativo VARCHAR := null;
v_cod_cdc_atto_amministrativo VARCHAR := null;
v_desc_cdc_atto_amministrativo VARCHAR := null;
v_cod_tipo_avviso VARCHAR := null;
v_desc_tipo_avviso VARCHAR := null;
-- Variabili per gli attributi
v_rilevante_iva VARCHAR := null;
v_ordinativo_singolo VARCHAR := null;
v_ordinativo_manuale VARCHAR := null;
v_esproprio VARCHAR := null;
v_note VARCHAR := null;
v_avviso VARCHAR := null;
-- Variabili per i soggetti legati al subdoc
v_cod_sogg_subdoc VARCHAR := null;
v_tipo_sogg_subdoc VARCHAR := null;
v_stato_sogg_subdoc VARCHAR := null;
v_rag_sociale_sogg_subdoc VARCHAR := null;
v_p_iva_sogg_subdoc VARCHAR := null;
v_cf_sogg_subdoc VARCHAR := null;
v_cf_estero_sogg_subdoc VARCHAR := null;
v_nome_sogg_subdoc VARCHAR := null;
v_cognome_sogg_subdoc VARCHAR := null;
-- Variabili per gli ordinamenti legati ai documenti
v_bil_anno_ord VARCHAR := null;
v_anno_ord INTEGER := null;
v_num_ord NUMERIC := null;
v_num_subord VARCHAR := null;
-- Variabile per la sede secondaria
v_sede_secondaria_subdoc VARCHAR := null;
-- Variabili per gli accertamenti
v_bil_anno VARCHAR := null;
v_anno_accertamento INTEGER := null;
v_num_accertamento NUMERIC := null;
v_cod_accertamento VARCHAR := null;
v_desc_accertamento VARCHAR := null;
v_cod_subaccertamento VARCHAR := null;
v_desc_subaccertamento VARCHAR := null;
-- Variabili per la modalita' di pagamento
v_quietanziante VARCHAR := null;
v_data_nascita_quietanziante TIMESTAMP := null;
v_luogo_nascita_quietanziante VARCHAR := null;
v_stato_nascita_quietanziante VARCHAR := null;
v_bic VARCHAR := null;
v_contocorrente VARCHAR := null;
v_intestazione_contocorrente VARCHAR := null;
v_iban VARCHAR := null;
v_mod_pag_id INTEGER := null;
v_note_mod_pag VARCHAR := null;
v_data_scadenza_mod_pag TIMESTAMP := null;
v_cod_tipo_accredito VARCHAR := null;
v_desc_tipo_accredito VARCHAR := null;
-- Variabili per i soggetti legati alla modalita' pagamento
v_cod_sogg_mod_pag VARCHAR := null;
v_tipo_sogg_mod_pag VARCHAR := null;
v_stato_sogg_mod_pag VARCHAR := null;
v_rag_sociale_sogg_mod_pag VARCHAR := null;
v_p_iva_sogg_mod_pag VARCHAR := null;
v_cf_sogg_mod_pag VARCHAR := null;
v_cf_estero_sogg_mod_pag VARCHAR := null;
v_nome_sogg_mod_pag VARCHAR := null;
v_cognome_sogg_mod_pag VARCHAR := null;
-- Variabili utili per il caricamento
v_doc_id INTEGER := null;
v_subdoc_id INTEGER := null;
v_attoal_id INTEGER := null;
v_attoamm_id INTEGER := null;
v_soggetto_id INTEGER := null;
v_classif_code VARCHAR := null;
v_classif_desc VARCHAR := null;
v_classif_tipo_code VARCHAR := null;
v_classif_id_part INTEGER := null;
v_classif_id_padre INTEGER := null;
v_classif_tipo_id INTEGER := null;
v_conta_ciclo_classif INTEGER := null;
v_flag_attributo VARCHAR := null;
v_soggetto_id_principale INTEGER := null;
v_movgest_ts_tipo_code VARCHAR := null;
v_movgest_ts_code VARCHAR := null;
v_soggetto_id_modpag_nocess INTEGER := null;
v_soggetto_id_modpag_cess INTEGER := null;
v_soggetto_id_modpag INTEGER := null;
v_soggrelmpag_id INTEGER := null;
v_pcccod_id INTEGER := null;
v_pccuff_id INTEGER := null;
v_attoamm_tipo_id INTEGER := null;
v_comm_tipo_id INTEGER := null;
--nuova sezione coge 26-09-2016
v_registro_repertorio VARCHAR := null;
v_anno_repertorio VARCHAR := null;
v_num_repertorio VARCHAR := null;
v_data_repertorio VARCHAR := null;
v_arrotondamento VARCHAR := null;
v_data_ricezione_portale VARCHAR := null;
rec_doc_attr record;

v_user_table varchar;
params varchar;
fnc_eseguita integer;


-- 22.05.2018 Sofia siac-6124
v_data_ins_atto_allegato TIMESTAMP := null;
v_data_completa_atto_allegato TIMESTAMP := null;
v_data_convalida_atto_allegato TIMESTAMP := null;
v_data_sosp_atto_allegato TIMESTAMP := null;
v_causale_sosp_atto_allegato varchar := null;
v_data_riattiva_atto_allegato TIMESTAMP := null;

BEGIN


select count(*) into fnc_eseguita
from siac_dwh_log_elaborazioni
a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.fnc_elaborazione_inizio >= (now() - interval '13 hours')::timestamp -- non deve esistere  una elaborazione uguale nelle 13 ore che precedono la chimata
and a.fnc_name='fnc_siac_dwh_documento_entrata' ;

if fnc_eseguita> 0 then

return;

else

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

select fnc_siac_random_user()
into	v_user_table;

params := p_ente_proprietario_id::varchar||' - '||p_data::varchar;


insert into
siac_dwh_log_elaborazioni (
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values (
p_ente_proprietario_id,
'fnc_siac_dwh_documento_entrata',
params,
clock_timestamp(),
v_user_table
);

esito:= 'Inizio funzione carico documenti entrata (FNC_SIAC_DWH_DOCUMENTO_ENTRATA) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;
DELETE FROM siac.siac_dwh_documento_entrata
WHERE ente_proprietario_id = p_ente_proprietario_id;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;

-- Ciclo per estrarre doc_id (documenti)
FOR rec_doc_id IN
SELECT tep.ente_proprietario_id, tep.ente_denominazione,
       td.doc_anno, td.doc_numero, td.doc_desc, td.doc_importo, td.doc_beneficiariomult,
       td.doc_data_emissione, td.doc_data_scadenza, dc.codbollo_code, dc.codbollo_desc,
       td.doc_collegato_cec,
       dds.doc_stato_code, dds.doc_stato_desc, ddg.doc_gruppo_tipo_code, ddg.doc_gruppo_tipo_desc,
       ddft.doc_fam_tipo_code, ddft.doc_fam_tipo_desc, ddt.doc_tipo_code, ddt.doc_tipo_desc,
       ts.soggetto_code, dst.soggetto_tipo_desc, dss.soggetto_stato_desc, tpg.ragione_sociale,
       ts.partita_iva, ts.codice_fiscale, ts.codice_fiscale_estero, tpf.nome, tpf.cognome,
       td.doc_id, td.pcccod_id, td.pccuff_id, ts.soggetto_id,
       td.doc_contabilizza_genpcc, td.stato_sdi
FROM siac.siac_t_doc td
INNER JOIN siac.siac_t_ente_proprietario tep ON tep.ente_proprietario_id = td.ente_proprietario_id
                                             AND p_data BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, p_data)
                                             AND tep.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_doc_tipo ddt ON ddt.doc_tipo_id = td.doc_tipo_id
                                    AND p_data BETWEEN ddt.validita_inizio AND COALESCE(ddt.validita_fine, p_data)
                                    AND ddt.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_doc_fam_tipo ddft ON ddft.doc_fam_tipo_id = ddt.doc_fam_tipo_id
                                         AND p_data BETWEEN ddft.validita_inizio AND COALESCE(ddft.validita_fine, p_data)
                                         AND ddft.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_doc_gruppo ddg ON ddg.doc_gruppo_tipo_id = ddt.doc_gruppo_tipo_id
                                     AND p_data BETWEEN ddg.validita_inizio AND COALESCE(ddg.validita_fine, p_data)
                                     AND ddg.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_codicebollo dc ON dc.codbollo_id = td.codbollo_id
LEFT JOIN siac.siac_r_doc_stato rds ON rds.doc_id = td.doc_id
                                    AND p_data BETWEEN rds.validita_inizio AND COALESCE(rds.validita_fine, p_data)
                                    AND rds.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_doc_stato dds ON dds.doc_stato_id = rds.doc_stato_id
                                    AND p_data BETWEEN dds.validita_inizio AND COALESCE(dds.validita_fine, p_data)
                                    AND dds.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_doc_sog srds ON srds.doc_id = td.doc_id
                                   AND p_data BETWEEN srds.validita_inizio AND COALESCE(srds.validita_fine, p_data)
                                   AND srds.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_soggetto ts ON ts.soggetto_id = srds.soggetto_id
                                  AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
                                  AND ts.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
                                        AND p_data BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, p_data)
                                        AND rst.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id = rst.soggetto_tipo_id
                                        AND p_data BETWEEN dst.validita_inizio AND COALESCE(dst.validita_fine, p_data)
                                        AND dst.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_soggetto_stato rss ON rss.soggetto_id = ts.soggetto_id
                                         AND p_data BETWEEN rss.validita_inizio AND COALESCE(rss.validita_fine, p_data)
                                         AND rss.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_soggetto_stato dss ON dss.soggetto_stato_id = rss.soggetto_stato_id
                                         AND p_data BETWEEN dss.validita_inizio AND COALESCE(dss.validita_fine, p_data)
                                         AND dss.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_persona_giuridica tpg ON tpg.soggetto_id = ts.soggetto_id
                                            AND p_data BETWEEN tpg.validita_inizio AND COALESCE(tpg.validita_fine, p_data)
                                            AND tpg.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_persona_fisica tpf ON tpf.soggetto_id = ts.soggetto_id
                                         AND p_data BETWEEN tpf.validita_inizio AND COALESCE(tpf.validita_fine, p_data)
                                         AND tpf.data_cancellazione IS NULL
WHERE tep.ente_proprietario_id = p_ente_proprietario_id
AND ddft.doc_fam_tipo_code in ('E','IE')
AND p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
AND td.data_cancellazione IS NULL

LOOP

v_ente_proprietario_id  := null;
v_ente_denominazione  := null;
v_anno_doc  := null;
v_num_doc  := null;
v_stato_sdi := null; -- SIAC-6565
v_desc_doc  := null;
v_importo_doc  := null;
v_beneficiario_multiplo_doc  := null;
v_data_emissione_doc  := null;
v_data_scadenza_doc  := null;
v_codice_bollo_doc  := null;
v_desc_codice_bollo_doc  := null;
v_collegato_cec_doc  := null;
v_cod_pcc_doc  := null;
v_desc_pcc_doc  := null;
v_cod_ufficio_doc  := null;
v_desc_ufficio_doc  := null;
v_cod_stato_doc  := null;
v_desc_stato_doc  := null;
v_cod_gruppo_doc  := null;
v_desc_gruppo_doc  := null;
v_cod_famiglia_doc  := null;
v_desc_famiglia_doc  := null;
v_cod_tipo_doc  := null;
v_desc_tipo_doc  := null;
v_sogg_id_doc  := null;
v_cod_sogg_doc  := null;
v_tipo_sogg_doc  := null;
v_stato_sogg_doc  := null;
v_rag_sociale_sogg_doc  := null;
v_p_iva_sogg_doc  := null;
v_cf_sogg_doc  := null;
v_cf_estero_sogg_doc  := null;
v_nome_sogg_doc  := null;
v_cognome_sogg_doc  := null;
v_bil_anno_ord := null;
v_anno_ord := null;
v_num_ord := null;
v_num_subord  := null;


v_doc_id  := null;
v_pcccod_id  := null;
v_pccuff_id  := null;

--nuova sezione coge 26-09-2016
v_doc_contabilizza_genpcc := null;

v_ente_proprietario_id := rec_doc_id.ente_proprietario_id;
v_ente_denominazione := rec_doc_id.ente_denominazione;
v_anno_doc := rec_doc_id.doc_anno;
v_num_doc := rec_doc_id.doc_numero;
v_stato_sdi := rec_doc_id.stato_sdi; -- SIAC-6565
v_desc_doc := rec_doc_id.doc_desc;
v_importo_doc := rec_doc_id.doc_importo;
IF rec_doc_id.doc_beneficiariomult = 'FALSE' THEN
   v_beneficiario_multiplo_doc := 'F';
ELSE
   v_beneficiario_multiplo_doc := 'T';
END IF;
v_data_emissione_doc := rec_doc_id.doc_data_emissione;
v_data_scadenza_doc := rec_doc_id.doc_data_scadenza;
v_codice_bollo_doc := rec_doc_id.codbollo_code;
v_desc_codice_bollo_doc := rec_doc_id.codbollo_desc;
v_collegato_cec_doc := rec_doc_id.doc_collegato_cec;
v_cod_stato_doc := rec_doc_id.doc_stato_code;
v_desc_stato_doc := rec_doc_id.doc_stato_desc;
v_cod_gruppo_doc := rec_doc_id.doc_gruppo_tipo_code;
v_desc_gruppo_doc := rec_doc_id.doc_gruppo_tipo_desc;
v_cod_famiglia_doc := rec_doc_id.doc_fam_tipo_code;
v_desc_famiglia_doc := rec_doc_id.doc_fam_tipo_desc;
v_cod_tipo_doc := rec_doc_id.doc_tipo_code;
v_desc_tipo_doc := rec_doc_id.doc_tipo_desc;
v_sogg_id_doc := rec_doc_id.soggetto_id;
v_cod_sogg_doc := rec_doc_id.soggetto_code;
v_tipo_sogg_doc := rec_doc_id.soggetto_tipo_desc;
v_stato_sogg_doc := rec_doc_id.soggetto_stato_desc;
v_rag_sociale_sogg_doc := rec_doc_id.ragione_sociale;
v_p_iva_sogg_doc := rec_doc_id.partita_iva;
v_cf_sogg_doc := rec_doc_id.codice_fiscale;
v_cf_estero_sogg_doc := rec_doc_id.codice_fiscale_estero;
v_nome_sogg_doc := rec_doc_id.nome;
v_cognome_sogg_doc := rec_doc_id.cognome;

v_doc_id  := rec_doc_id.doc_id;
v_pcccod_id := rec_doc_id.pcccod_id;
v_pccuff_id := rec_doc_id.pccuff_id;

--nuova sezione coge 26-09-2016
IF rec_doc_id.doc_contabilizza_genpcc = 'FALSE' THEN
   v_doc_contabilizza_genpcc := 'F';
ELSE
   v_doc_contabilizza_genpcc := 'T';
END IF;

SELECT dpc.pcccod_code, dpc.pcccod_desc
INTO   v_cod_pcc_doc, v_desc_pcc_doc
FROM   siac.siac_d_pcc_codice dpc
WHERE  dpc.pcccod_id = v_pcccod_id
AND p_data BETWEEN dpc.validita_inizio AND COALESCE(dpc.validita_fine, p_data)
AND dpc.data_cancellazione IS NULL;

SELECT dpu.pccuff_code, dpu.pccuff_desc
INTO   v_cod_ufficio_doc, v_desc_ufficio_doc
FROM   siac.siac_d_pcc_ufficio dpu
WHERE  dpu.pccuff_id = v_pccuff_id
AND p_data BETWEEN dpu.validita_inizio AND COALESCE(dpu.validita_fine, p_data)
AND dpu.data_cancellazione IS NULL;

-- Ciclo per estrarre subdoc_id (subdocumenti)
FOR rec_subdoc_id IN
SELECT ts.subdoc_numero, ts.subdoc_desc, ts.subdoc_importo, ts.subdoc_nreg_iva, ts.subdoc_data_scadenza,
       ts.subdoc_convalida_manuale, ts.subdoc_importo_da_dedurre, ts.subdoc_splitreverse_importo,
       ts.subdoc_pagato_cec, ts.subdoc_data_pagamento_cec,
       taa.attoamm_anno, taa.attoamm_numero, taa.attoamm_oggetto, taa.attoamm_note,
       daas.attoamm_stato_code, daas.attoamm_stato_desc,
       staa.attoal_causale, staa.attoal_altriallegati, staa.attoal_dati_sensibili,
       staa.attoal_data_scadenza, staa.attoal_note, staa.attoal_annotazioni, staa.attoal_pratica,
       staa.attoal_responsabile_amm, staa.attoal_responsabile_con, staa.attoal_titolario_anno,
       staa.attoal_titolario_numero, staa.attoal_versione_invio_firma,
       sdaas.attoal_stato_code, sdaas.attoal_stato_desc,
       ted.eldoc_anno, ted.eldoc_numero, ted.eldoc_data_trasmissione, ted.eldoc_tot_quoteentrate,
       ted.eldoc_tot_quotespese, ted.eldoc_tot_dapagare, ted.eldoc_tot_daincassare,
       deds.eldoc_stato_code, deds.eldoc_stato_desc, dnt.notetes_desc, dd.dist_code, dd.dist_desc, dc.contotes_desc,
       ts.subdoc_id, staa.attoal_id, taa.attoamm_id, taa.attoamm_tipo_id, ts.comm_tipo_id,
       staa.data_creazione data_ins_atto_allegato -- 22.05.2018 Sofia siac-6124
FROM siac.siac_t_subdoc ts
LEFT JOIN siac.siac_r_subdoc_atto_amm rsaa ON rsaa.subdoc_id = ts.subdoc_id
                                           AND p_data BETWEEN rsaa.validita_inizio AND COALESCE(rsaa.validita_fine, p_data)
                                           AND rsaa.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_atto_amm taa ON taa.attoamm_id = rsaa.attoamm_id
                                   AND p_data BETWEEN taa.validita_inizio AND COALESCE(taa.validita_fine, p_data)
                                   AND taa.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_atto_amm_stato raas ON raas.attoamm_id = taa.attoamm_id
                                          AND p_data BETWEEN raas.validita_inizio AND COALESCE(raas.validita_fine, p_data)
                                          AND raas.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_atto_amm_stato daas ON daas.attoamm_stato_id = raas.attoamm_stato_id
                                          AND p_data BETWEEN daas.validita_inizio AND COALESCE(daas.validita_fine, p_data)
                                          AND daas.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_elenco_doc_subdoc reds ON reds.subdoc_id = ts.subdoc_id
                                             AND p_data BETWEEN reds.validita_inizio AND COALESCE(reds.validita_fine, p_data)
                                             AND reds.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_elenco_doc ted ON ted.eldoc_id = reds.eldoc_id
                                     AND p_data BETWEEN ted.validita_inizio AND COALESCE(ted.validita_fine, p_data)
                                     AND ted.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_atto_allegato_elenco_doc raaed ON raaed.eldoc_id = ted.eldoc_id
                                                     AND p_data BETWEEN raaed.validita_inizio AND COALESCE(raaed.validita_fine, p_data)
                                                     AND raaed.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_atto_allegato staa ON staa.attoal_id = raaed.attoal_id
                                         AND p_data BETWEEN staa.validita_inizio AND COALESCE(staa.validita_fine, p_data)
                                         AND staa.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_atto_allegato_stato sraas ON sraas.attoal_id = staa.attoal_id
                                                AND p_data BETWEEN sraas.validita_inizio AND COALESCE(sraas.validita_fine, p_data)
                                                AND sraas.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_atto_allegato_stato sdaas ON sdaas.attoal_stato_id = sraas.attoal_stato_id
                                                AND p_data BETWEEN sdaas.validita_inizio AND COALESCE(sdaas.validita_fine, p_data)
                                                AND sdaas.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_elenco_doc_stato  sreds ON sreds.eldoc_id = ted.eldoc_id
                                              AND p_data BETWEEN sreds.validita_inizio AND COALESCE(sreds.validita_fine, p_data)
                                              AND sreds.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_elenco_doc_stato  deds ON deds.eldoc_stato_id = sreds.eldoc_stato_id
                                             AND p_data BETWEEN deds.validita_inizio AND COALESCE(deds.validita_fine, p_data)
                                             AND deds.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_note_tesoriere  dnt ON dnt.notetes_id = ts.notetes_id
LEFT JOIN siac.siac_d_distinta  dd ON dd.dist_id = ts.dist_id
LEFT JOIN siac.siac_d_contotesoreria dc ON dc.contotes_id = ts.contotes_id
WHERE ts.doc_id = v_doc_id
AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
AND ts.data_cancellazione IS NULL

	LOOP

    v_num_subdoc  := null;
    v_desc_subdoc  := null;
    v_importo_subdoc  := null;
    v_num_reg_iva_subdoc  := null;
    v_data_scadenza_subdoc  := null;
    v_convalida_manuale_subdoc  := null;
    v_importo_da_dedurre_subdoc  := null;
    v_splitreverse_importo_subdoc  := null;
    v_pagato_cec_subdoc  := null;
    v_data_pagamento_cec_subdoc  := null;
    v_anno_atto_amministrativo  := null;
    v_num_atto_amministrativo  := null;
    v_oggetto_atto_amministrativo  := null;
    v_note_atto_amministrativo  := null;
    v_cod_tipo_atto_amministrativo  := null;
    v_desc_tipo_atto_amministrativo  := null;
    v_cod_stato_atto_amministrativo  := null;
    v_desc_stato_atto_amministrativo  := null;
    v_causale_atto_allegato  := null;
    v_altri_allegati_atto_allegato  := null;
    v_dati_sensibili_atto_allegato  := null;
    v_data_scadenza_atto_allegato  := null;
    v_note_atto_allegato  := null;
    v_annotazioni_atto_allegato  := null;
    v_pratica_atto_allegato  := null;
    v_resp_amm_atto_allegato  := null;
    v_resp_contabile_atto_allegato  := null;
    v_anno_titolario_atto_allegato  := null;
    v_num_titolario_atto_allegato  := null;
    v_vers_invio_firma_atto_allegato  := null;
    v_cod_stato_atto_allegato  := null;
    v_desc_stato_atto_allegato  := null;
    v_anno_elenco_doc  := null;
    v_num_elenco_doc  := null;
    v_data_trasmissione_elenco_doc  := null;
    v_tot_quote_entrate_elenco_doc  := null;
    v_tot_quote_spese_elenco_doc  := null;
    v_tot_da_pagare_elenco_doc  := null;
    v_tot_da_incassare_elenco_doc  := null;
    v_cod_stato_elenco_doc  := null;
    v_desc_stato_elenco_doc  := null;
    v_note_tesoriere_subdoc  := null;
    v_cod_distinta_subdoc  := null;
    v_desc_distinta_subdoc  := null;
    v_tipo_commissione_subdoc  := null;
    v_conto_tesoreria_subdoc  := null;

    v_sogg_id_atto_allegato  := null;
    v_cod_sogg_atto_allegato  := null;
    v_tipo_sogg_atto_allegato  := null;
    v_stato_sogg_atto_allegato  := null;
    v_rag_sociale_sogg_atto_allegato  := null;
    v_p_iva_sogg_atto_allegato  := null;
    v_cf_sogg_atto_allegato  := null;
    v_cf_estero_sogg_atto_allegato  := null;
    v_nome_sogg_atto_allegato  := null;
    v_cognome_sogg_atto_allegato  := null;

    v_cod_cdr_atto_amministrativo  := null;
    v_desc_cdr_atto_amministrativo  := null;
    v_cod_cdc_atto_amministrativo  := null;
    v_desc_cdc_atto_amministrativo  := null;
    v_cod_tipo_avviso  := null;
    v_desc_tipo_avviso  := null;

    v_cod_sogg_subdoc  := null;
    v_tipo_sogg_subdoc  := null;
    v_stato_sogg_subdoc  := null;
    v_rag_sociale_sogg_subdoc  := null;
    v_p_iva_sogg_subdoc  := null;
    v_cf_sogg_subdoc  := null;
    v_cf_estero_sogg_subdoc  := null;
    v_nome_sogg_subdoc  := null;
    v_cognome_sogg_subdoc  := null;

    v_sede_secondaria_subdoc := null;

    v_bil_anno := null;
    v_anno_accertamento := null;
    v_num_accertamento := null;
    v_cod_accertamento  := null;
    v_desc_accertamento  := null;
    v_cod_subaccertamento  := null;
    v_desc_subaccertamento  := null;

    v_quietanziante := null;
    v_data_nascita_quietanziante := null;
    v_luogo_nascita_quietanziante := null;
    v_stato_nascita_quietanziante := null;
    v_bic := null;
    v_contocorrente := null;
    v_intestazione_contocorrente := null;
    v_iban := null;
    v_mod_pag_id := null;
    v_note_mod_pag := null;
    v_data_scadenza_mod_pag := null;
    v_cod_tipo_accredito := null;
    v_desc_tipo_accredito := null;

    v_cod_sogg_mod_pag := null;
    v_tipo_sogg_mod_pag := null;
    v_stato_sogg_mod_pag := null;
    v_rag_sociale_sogg_mod_pag := null;
    v_p_iva_sogg_mod_pag := null;
    v_cf_sogg_mod_pag := null;
    v_cf_estero_sogg_mod_pag := null;
    v_nome_sogg_mod_pag := null;
    v_cognome_sogg_mod_pag := null;

    v_attoal_id  := null;
    v_subdoc_id  := null;
    v_attoamm_id  := null;
    v_classif_tipo_id := null;
    v_soggetto_id := null;
    v_soggetto_id_principale := null;
    v_movgest_ts_tipo_code := null;
    v_movgest_ts_code := null;
    v_soggetto_id_modpag_nocess := null;
    v_soggetto_id_modpag_cess := null;
    v_soggetto_id_modpag := null;
    v_soggrelmpag_id := null;
    v_attoamm_tipo_id := null;
    v_comm_tipo_id := null;


	-- 22.05.2018 Sofia siac-6124
    v_data_ins_atto_allegato:= null;
    v_data_completa_atto_allegato:= null;
    v_data_convalida_atto_allegato:= null;
    v_data_sosp_atto_allegato:=null;
    v_causale_sosp_atto_allegato:= null;
    v_data_riattiva_atto_allegato:= null;

    v_num_subdoc  := rec_subdoc_id.subdoc_numero;
    v_desc_subdoc  := rec_subdoc_id.subdoc_desc;
    v_importo_subdoc  := rec_subdoc_id.subdoc_importo;
    v_num_reg_iva_subdoc  := rec_subdoc_id.subdoc_nreg_iva;
    v_data_scadenza_subdoc  := rec_subdoc_id.subdoc_data_scadenza;
    v_convalida_manuale_subdoc  := rec_subdoc_id.subdoc_convalida_manuale;
    v_importo_da_dedurre_subdoc  := rec_subdoc_id.subdoc_importo_da_dedurre;
    v_splitreverse_importo_subdoc  := rec_subdoc_id.subdoc_splitreverse_importo;
    v_pagato_cec_subdoc  := rec_subdoc_id.subdoc_pagato_cec;
    v_data_pagamento_cec_subdoc  := rec_subdoc_id.subdoc_data_pagamento_cec;
    v_anno_atto_amministrativo  := rec_subdoc_id.attoamm_anno;
    v_num_atto_amministrativo  := rec_subdoc_id.attoamm_numero;
    v_oggetto_atto_amministrativo  := rec_subdoc_id.attoamm_oggetto;
    v_note_atto_amministrativo  := rec_subdoc_id.attoamm_note;
    v_cod_stato_atto_amministrativo  := rec_subdoc_id.attoamm_stato_code;
    v_desc_stato_atto_amministrativo  := rec_subdoc_id.attoamm_stato_desc;
    v_causale_atto_allegato  := rec_subdoc_id.attoal_causale;
    v_altri_allegati_atto_allegato  := rec_subdoc_id.attoal_altriallegati;
    v_dati_sensibili_atto_allegato  := rec_subdoc_id.attoal_dati_sensibili;
    v_data_scadenza_atto_allegato  := rec_subdoc_id.attoal_data_scadenza;
    v_note_atto_allegato  := rec_subdoc_id.attoal_note;
    v_annotazioni_atto_allegato  := rec_subdoc_id.attoal_annotazioni;
    v_pratica_atto_allegato  := rec_subdoc_id.attoal_pratica;
    v_resp_amm_atto_allegato  := rec_subdoc_id.attoal_responsabile_amm;
    v_resp_contabile_atto_allegato  := rec_subdoc_id.attoal_responsabile_con;
    v_anno_titolario_atto_allegato  := rec_subdoc_id.attoal_titolario_anno;
    v_num_titolario_atto_allegato  := rec_subdoc_id.attoal_titolario_numero;
    v_vers_invio_firma_atto_allegato  := rec_subdoc_id.attoal_versione_invio_firma;
    v_cod_stato_atto_allegato  := rec_subdoc_id.attoal_stato_code;
    v_desc_stato_atto_allegato  := rec_subdoc_id.attoal_stato_desc;
    v_anno_elenco_doc  := rec_subdoc_id.eldoc_anno;
    v_num_elenco_doc  := rec_subdoc_id.eldoc_numero;
    v_data_trasmissione_elenco_doc  := rec_subdoc_id.eldoc_data_trasmissione;
    v_tot_quote_entrate_elenco_doc  := rec_subdoc_id.eldoc_tot_quoteentrate;
    v_tot_quote_spese_elenco_doc  := rec_subdoc_id.eldoc_tot_quotespese;
    v_tot_da_pagare_elenco_doc  := rec_subdoc_id.eldoc_tot_dapagare;
    v_tot_da_incassare_elenco_doc  := rec_subdoc_id.eldoc_tot_daincassare;
    v_cod_stato_elenco_doc  := rec_subdoc_id.eldoc_stato_code;
    v_desc_stato_elenco_doc  := rec_subdoc_id.eldoc_stato_desc;
    v_note_tesoriere_subdoc  := rec_subdoc_id.notetes_desc;
    v_cod_distinta_subdoc  := rec_subdoc_id.dist_code;
    v_desc_distinta_subdoc  := rec_subdoc_id.dist_desc;
    v_conto_tesoreria_subdoc  := rec_subdoc_id.contotes_desc;

    v_attoal_id  := rec_subdoc_id.attoal_id;
    v_subdoc_id  := rec_subdoc_id.subdoc_id;
    v_attoamm_id  := rec_subdoc_id.attoamm_id;
    v_attoamm_tipo_id  := rec_subdoc_id.attoamm_tipo_id;
    v_comm_tipo_id  := rec_subdoc_id.comm_tipo_id;

    -- 22.05.2018 Sofia siac-6124
    v_data_ins_atto_allegato:=rec_subdoc_id.data_ins_atto_allegato;

    -- Sezione per estrarre il tipo di atto amministrativo
    SELECT daat.attoamm_tipo_code, daat.attoamm_tipo_desc
    INTO   v_cod_tipo_atto_amministrativo, v_desc_tipo_atto_amministrativo
    FROM  siac.siac_d_atto_amm_tipo daat
    WHERE daat.attoamm_tipo_id = v_attoamm_tipo_id
    AND p_data BETWEEN daat.validita_inizio AND COALESCE(daat.validita_fine, p_data)
    AND daat.data_cancellazione IS NULL;
    -- Sezione per estrarre il tipo commissione
    SELECT dct.comm_tipo_desc
    INTO  v_tipo_commissione_subdoc
    FROM siac.siac_d_commissione_tipo dct
    WHERE dct.comm_tipo_id = v_comm_tipo_id
    AND p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data)
    AND dct.data_cancellazione IS NULL;

   -- esito:= '    Inizio step per i soggetti legati all''atto allegato @@@@@@@@@@@@@@@@@@ - '||clock_timestamp();
   -- return next;
    --  Sezione per i soggetti legati all'atto allegato
    SELECT ts.soggetto_code, dst.soggetto_tipo_desc, dss.soggetto_stato_desc, tpg.ragione_sociale,
           ts.partita_iva, ts.codice_fiscale, ts.codice_fiscale_estero,
           tpf.nome, tpf.cognome, ts.soggetto_id,
           raas.attoal_sog_data_sosp, raas.attoal_sog_causale_sosp, raas.attoal_sog_data_riatt  -- 22.05.2018 Sofia siac-6124
    INTO   v_cod_sogg_atto_allegato, v_tipo_sogg_atto_allegato, v_stato_sogg_atto_allegato, v_rag_sociale_sogg_atto_allegato,
           v_p_iva_sogg_atto_allegato, v_cf_sogg_atto_allegato, v_cf_estero_sogg_atto_allegato,
           v_nome_sogg_atto_allegato, v_cognome_sogg_atto_allegato, v_sogg_id_atto_allegato,
           v_data_sosp_atto_allegato,v_causale_sosp_atto_allegato, v_data_riattiva_atto_allegato -- 22.05.2018 Sofia siac-6124
    FROM siac.siac_r_atto_allegato_sog raas
    INNER JOIN siac.siac_t_soggetto ts ON ts.soggetto_id = raas.soggetto_id
    LEFT JOIN siac.siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
                                            AND p_data BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, p_data)
                                            AND rst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id = rst.soggetto_tipo_id
                                            AND p_data BETWEEN dst.validita_inizio AND COALESCE(dst.validita_fine, p_data)
                                            AND dst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_r_soggetto_stato rss ON rss.soggetto_id = ts.soggetto_id
                                             AND p_data BETWEEN rss.validita_inizio AND COALESCE(rss.validita_fine, p_data)
                                             AND rss.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_stato dss ON dss.soggetto_stato_id = rss.soggetto_stato_id
                                             AND p_data BETWEEN dss.validita_inizio AND COALESCE(dss.validita_fine, p_data)
                                             AND dss.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_giuridica tpg ON tpg.soggetto_id = ts.soggetto_id
                                                AND p_data BETWEEN tpg.validita_inizio AND COALESCE(tpg.validita_fine, p_data)
                                                AND tpg.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_fisica tpf ON tpf.soggetto_id = ts.soggetto_id
                                             AND p_data BETWEEN tpf.validita_inizio AND COALESCE(tpf.validita_fine, p_data)
                                             AND tpf.data_cancellazione IS NULL
    WHERE raas.attoal_id = v_attoal_id
    AND p_data BETWEEN raas.validita_inizio AND COALESCE(raas.validita_fine, p_data)
    AND raas.data_cancellazione IS NULL
    AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
    AND ts.data_cancellazione IS NULL;

   -- esito:= '    Fine step per i soggetti legati all''atto allegato v_data_sosp_atto_allegato='||coalesce(to_char(v_data_sosp_atto_allegato,'dd/mm/yyyy'),'****' )||' - '||clock_timestamp();
   -- return next;

    esito:= '    Inizio step data completamento, convalida atto_allegato - '||clock_timestamp();
    return next;
	-- 22.05.2018 Sofia siac-6124
    v_data_completa_atto_allegato:=fnc_siac_attoal_getDataStato(v_attoal_id,'C');
    v_data_convalida_atto_allegato:=fnc_siac_attoal_getDataStato(v_attoal_id,'CV');
    esito:= '    Fine step data completamento, convalida atto_allegato - '||clock_timestamp();
    return next;

    -- Sezione per i classificatori legati ai subdocumenti
    esito:= '    Inizio step classificatori per subdocumenti - '||clock_timestamp();
    return next;
    FOR rec_classif_id IN
    SELECT tc.classif_tipo_id, tc.classif_code, tc.classif_desc
    FROM siac.siac_r_subdoc_class rsc, siac.siac_t_class tc
    WHERE tc.classif_id = rsc.classif_id
    AND   rsc.subdoc_id = v_subdoc_id
    AND   rsc.data_cancellazione IS NULL
    AND   tc.data_cancellazione IS NULL
    AND   p_data BETWEEN rsc.validita_inizio AND COALESCE(rsc.validita_fine, p_data)
    AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)

    LOOP

      v_classif_tipo_id :=  rec_classif_id.classif_tipo_id;
      v_classif_code := rec_classif_id.classif_code;
      v_classif_desc := rec_classif_id.classif_desc;

      v_classif_tipo_code := null;

      SELECT dct.classif_tipo_code
      INTO   v_classif_tipo_code
      FROM   siac.siac_d_class_tipo dct
      WHERE  dct.classif_tipo_id = v_classif_tipo_id
      AND    dct.data_cancellazione IS NULL
      AND    p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

      IF v_classif_tipo_code = 'TIPO_AVVISO' THEN
         v_cod_tipo_avviso  := v_classif_code;
         v_desc_tipo_avviso :=  v_classif_desc;
      END IF;

    END LOOP;
    esito:= '    Fine step classificatori per subdocumenti - '||clock_timestamp();
    return next;

    -- Sezione per i classificatori legati agli atti amministrativi
    esito:= '    Inizio step classificatori in gerarchia per atti amministrativi - '||clock_timestamp();
    return next;
    FOR rec_classif_id_attr IN
    SELECT tc.classif_id, tc.classif_tipo_id, tc.classif_code, tc.classif_desc
    FROM siac.siac_r_atto_amm_class raac, siac.siac_t_class tc
    WHERE tc.classif_id = raac.classif_id
    AND   raac.attoamm_id = v_attoamm_id
    AND   raac.data_cancellazione IS NULL
    AND   tc.data_cancellazione IS NULL
    AND   p_data BETWEEN raac.validita_inizio AND COALESCE(raac.validita_fine, p_data)
    AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)

    LOOP

      v_conta_ciclo_classif :=0;
      v_classif_id_padre := null;

      -- Loop per RISALIRE la gerarchia di un dato classificatore
      LOOP

          v_classif_code := null;
          v_classif_desc := null;
          v_classif_id_part := null;
          v_classif_tipo_code := null;

          IF v_conta_ciclo_classif = 0 THEN
             v_classif_id_part := rec_classif_id_attr.classif_id;
          ELSE
             v_classif_id_part := v_classif_id_padre;
          END IF;

          SELECT tc.classif_code, tc.classif_desc, rcft.classif_id_padre, dct.classif_tipo_code
          INTO   v_classif_code, v_classif_desc, v_classif_id_padre, v_classif_tipo_code
          FROM  siac.siac_r_class_fam_tree rcft, siac.siac_t_class tc, siac.siac_d_class_tipo dct
          WHERE rcft.classif_id = tc.classif_id
          AND   dct.classif_tipo_id = tc.classif_tipo_id
          AND   tc.classif_id = v_classif_id_part
          AND   rcft.data_cancellazione IS NULL
          AND   tc.data_cancellazione IS NULL
          AND   dct.data_cancellazione IS NULL
          AND   p_data BETWEEN rcft.validita_inizio AND COALESCE(rcft.validita_fine, p_data)
          AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)
          AND   p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

          IF v_classif_tipo_code = 'CDR' THEN
             v_cod_cdr_atto_amministrativo := v_classif_code;
             v_desc_cdr_atto_amministrativo := v_classif_desc;
          ELSIF v_classif_tipo_code = 'CDC' THEN
             v_cod_cdc_atto_amministrativo := v_classif_code;
             v_desc_cdc_atto_amministrativo := v_classif_desc;
          END IF;

          v_conta_ciclo_classif := v_conta_ciclo_classif +1;
          EXIT WHEN v_classif_id_padre IS NULL;

      END LOOP;
    END LOOP;
    esito:= '    Fine step classificatori in gerarchia per atti amministrativi - '||clock_timestamp();
    return next;

    -- Sezione pe gli attributi
    v_rilevante_iva := null;
    v_ordinativo_singolo := null;
    v_ordinativo_manuale := null;
    v_esproprio := null;
    v_note := null;
    v_avviso := null;

    v_flag_attributo := null;

--nuova sezione coge 26-09-2016
    v_registro_repertorio := null;
    v_anno_repertorio := null;
    v_num_repertorio := null;
    v_data_repertorio := null;

FOR rec_doc_attr IN
    SELECT ta.attr_code, dat.attr_tipo_code,
           rsa.tabella_id, rsa.percentuale, rsa."boolean" true_false, rsa.numerico, rsa.testo
    FROM   siac.siac_r_doc_attr rsa, siac.siac_t_attr ta, siac.siac_d_attr_tipo dat, siac_t_subdoc z
    WHERE  rsa.attr_id = ta.attr_id
    AND    ta.attr_tipo_id = dat.attr_tipo_id
    AND    rsa.data_cancellazione IS NULL
    AND    ta.data_cancellazione IS NULL
    AND    dat.data_cancellazione IS NULL
    and z.doc_id=rsa.doc_id
    and z.subdoc_id = v_subdoc_id
    AND    p_data BETWEEN rsa.validita_inizio AND COALESCE(rsa.validita_fine, p_data)
    AND    p_data BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, p_data)
    AND    p_data BETWEEN dat.validita_inizio AND COALESCE(dat.validita_fine, p_data)
    and ta.attr_code in ( 'registro_repertorio','anno_repertorio','num_repertorio',
    'data_repertorio' ,'dataRicezionePortale','arrotondamento')

LOOP

      IF rec_doc_attr.attr_tipo_code = 'X' THEN
         v_flag_attributo := rec_doc_attr.testo::varchar;
      ELSIF rec_doc_attr.attr_tipo_code = 'N' THEN
         v_flag_attributo := rec_doc_attr.numerico::varchar;
      ELSIF rec_doc_attr.attr_tipo_code = 'P' THEN
         v_flag_attributo := rec_doc_attr.percentuale::varchar;
      ELSIF rec_doc_attr.attr_tipo_code = 'B' THEN
         v_flag_attributo := rec_doc_attr.true_false::varchar;
      ELSIF rec_doc_attr.attr_tipo_code = 'T' THEN
         v_flag_attributo := rec_doc_attr.tabella_id::varchar;
      END IF;

      --nuova sezione coge 26-09-2016
      IF rec_doc_attr.attr_code = 'registro_repertorio' THEN
         v_registro_repertorio := v_flag_attributo;
      ELSIF rec_doc_attr.attr_code = 'anno_repertorio' THEN
         v_anno_repertorio := v_flag_attributo;
	  ELSIF rec_doc_attr.attr_code = 'num_repertorio' THEN
         v_num_repertorio := v_flag_attributo;
	  ELSIF rec_doc_attr.attr_code = 'data_repertorio' THEN
         v_data_repertorio := v_flag_attributo;
      ELSIF rec_doc_attr.attr_code = 'dataRicezionePortale' THEN
         v_data_ricezione_portale := v_flag_attributo;
      ELSIF rec_doc_attr.attr_code = 'arrotondamento' THEN
         v_arrotondamento := v_flag_attributo;
      END IF;

    END LOOP;


    FOR rec_attr IN
    SELECT ta.attr_code, dat.attr_tipo_code,
           rsa.tabella_id, rsa.percentuale, rsa."boolean" true_false, rsa.numerico, rsa.testo
    FROM   siac.siac_r_subdoc_attr rsa, siac.siac_t_attr ta, siac.siac_d_attr_tipo dat
    WHERE  rsa.attr_id = ta.attr_id
    AND    ta.attr_tipo_id = dat.attr_tipo_id
    AND    rsa.subdoc_id = v_subdoc_id
    AND    rsa.data_cancellazione IS NULL
    AND    ta.data_cancellazione IS NULL
    AND    dat.data_cancellazione IS NULL
    AND    p_data BETWEEN rsa.validita_inizio AND COALESCE(rsa.validita_fine, p_data)
    AND    p_data BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, p_data)
    AND    p_data BETWEEN dat.validita_inizio AND COALESCE(dat.validita_fine, p_data)

    LOOP

      IF rec_attr.attr_tipo_code = 'X' THEN
         v_flag_attributo := rec_attr.testo::varchar;
      ELSIF rec_attr.attr_tipo_code = 'N' THEN
         v_flag_attributo := rec_attr.numerico::varchar;
      ELSIF rec_attr.attr_tipo_code = 'P' THEN
         v_flag_attributo := rec_attr.percentuale::varchar;
      ELSIF rec_attr.attr_tipo_code = 'B' THEN
         v_flag_attributo := rec_attr.true_false::varchar;
      ELSIF rec_attr.attr_tipo_code = 'T' THEN
         v_flag_attributo := rec_attr.tabella_id::varchar;
      END IF;

      IF rec_attr.attr_code = 'flagRilevanteIVA' THEN
         v_rilevante_iva := v_flag_attributo;
      ELSIF rec_attr.attr_code = 'flagOrdinativoManuale' THEN
         v_ordinativo_manuale := v_flag_attributo;
      ELSIF rec_attr.attr_code = 'flagOrdinativoSingolo' THEN
         v_ordinativo_singolo := v_flag_attributo;
      ELSIF rec_attr.attr_code = 'flagEsproprio' THEN
         v_esproprio := v_flag_attributo;
      ELSIF rec_attr.attr_code = 'Note' THEN
         v_note := v_flag_attributo;
      ELSIF rec_attr.attr_code = 'flagAvviso' THEN
         v_avviso := v_flag_attributo;
      END IF;

    END LOOP;

    --  Sezione per i soggetti legati al subdoc
    SELECT ts.soggetto_code, dst.soggetto_tipo_desc, dss.soggetto_stato_desc, tpg.ragione_sociale,
           ts.partita_iva, ts.codice_fiscale, ts.codice_fiscale_estero,
           tpf.nome, tpf.cognome, rss.soggetto_id
    INTO v_cod_sogg_subdoc, v_tipo_sogg_subdoc, v_stato_sogg_subdoc, v_rag_sociale_sogg_subdoc,
         v_p_iva_sogg_subdoc, v_cf_sogg_subdoc, v_cf_estero_sogg_subdoc,
         v_nome_sogg_subdoc, v_cognome_sogg_subdoc, v_soggetto_id
    FROM siac.siac_r_subdoc_sog rss
    INNER JOIN siac.siac_t_soggetto ts ON ts.soggetto_id = rss.soggetto_id
    LEFT JOIN siac.siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
                                            AND p_data BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, p_data)
                                            AND rst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id = rst.soggetto_tipo_id
                                            AND p_data BETWEEN dst.validita_inizio AND COALESCE(dst.validita_fine, p_data)
                                            AND dst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_r_soggetto_stato srss ON srss.soggetto_id = ts.soggetto_id
                                              AND p_data BETWEEN srss.validita_inizio AND COALESCE(srss.validita_fine, p_data)
                                              AND srss.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_stato dss ON dss.soggetto_stato_id = srss.soggetto_stato_id
                                             AND p_data BETWEEN dss.validita_inizio AND COALESCE(dss.validita_fine, p_data)
                                             AND dss.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_giuridica tpg ON tpg.soggetto_id = ts.soggetto_id
                                                AND p_data BETWEEN tpg.validita_inizio AND COALESCE(tpg.validita_fine, p_data)
                                                AND tpg.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_fisica tpf ON tpf.soggetto_id = ts.soggetto_id
                                             AND p_data BETWEEN tpf.validita_inizio AND COALESCE(tpf.validita_fine, p_data)
                                             AND tpf.data_cancellazione IS NULL
    WHERE rss.subdoc_id = v_subdoc_id
    AND p_data BETWEEN rss.validita_inizio AND COALESCE(rss.validita_fine, p_data)
    AND rss.data_cancellazione IS NULL
    AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
    AND ts.data_cancellazione IS NULL;

    -- Sezione per valorizzare la sede secondaria
    SELECT rsr.soggetto_id_da
    INTO v_soggetto_id_principale
    FROM siac.siac_r_soggetto_relaz rsr, siac.siac_d_relaz_tipo drt
    WHERE rsr.relaz_tipo_id = drt.relaz_tipo_id
    AND   drt.relaz_tipo_code  = 'SEDE_SECONDARIA'
    AND   rsr.soggetto_id_a = v_soggetto_id
    AND   p_data BETWEEN rsr.validita_inizio AND COALESCE(rsr.validita_fine, p_data)
    AND   p_data BETWEEN drt.validita_inizio AND COALESCE(drt.validita_fine, p_data)
    AND   rsr.data_cancellazione IS NULL
    AND   drt.data_cancellazione IS NULL;

    IF  v_soggetto_id_principale IS NOT NULL THEN
        v_sede_secondaria_subdoc := 'S';
    END IF;

    -- Sezione per gli accertamenti
    SELECT tp.anno, tm.movgest_anno, tm.movgest_numero, dmtt.movgest_ts_tipo_code,
           tmt.movgest_ts_code, tmt.movgest_ts_desc, tm.movgest_desc
    INTO v_bil_anno, v_anno_accertamento, v_num_accertamento, v_movgest_ts_tipo_code,
         v_movgest_ts_code, v_desc_subaccertamento, v_desc_accertamento
    FROM siac.siac_r_subdoc_movgest_ts rsmt
    INNER JOIN siac.siac_t_movgest_ts tmt ON tmt.movgest_ts_id = rsmt.movgest_ts_id
    INNER JOIN siac.siac_t_movgest tm ON tm.movgest_id = tmt.movgest_id
    LEFT JOIN siac.siac_t_bil tb ON tb.bil_id = tm.bil_id
                                 AND p_data BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, p_data)
                                 AND tb.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_periodo tp ON  tp.periodo_id = tb.periodo_id
                                     AND p_data BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, p_data)
                                     AND tp.data_cancellazione IS NULL
    INNER JOIN siac.siac_d_movgest_tipo dmt ON dmt.movgest_tipo_id = tm.movgest_tipo_id
    INNER JOIN siac.siac_d_movgest_ts_tipo dmtt ON dmtt.movgest_ts_tipo_id = tmt.movgest_ts_tipo_id
    WHERE rsmt.subdoc_id = v_subdoc_id
    AND dmt.movgest_tipo_code = 'A'
    AND p_data BETWEEN rsmt.validita_inizio AND COALESCE(rsmt.validita_fine, p_data)
    AND rsmt.data_cancellazione IS NULL
    AND p_data BETWEEN tmt.validita_inizio AND COALESCE(tmt.validita_fine, p_data)
    AND tmt.data_cancellazione IS NULL
    AND p_data BETWEEN tm.validita_inizio AND COALESCE(tm.validita_fine, p_data)
    AND tm.data_cancellazione IS NULL
    AND p_data BETWEEN dmt.validita_inizio AND COALESCE(dmt.validita_fine, p_data)
    AND dmt.data_cancellazione IS NULL
    AND p_data BETWEEN dmtt.validita_inizio AND COALESCE(dmtt.validita_fine, p_data)
    AND dmtt.data_cancellazione IS NULL;

    IF v_movgest_ts_tipo_code = 'T' THEN
       v_cod_accertamento := v_movgest_ts_code;
       v_desc_subaccertamento := NULL;
    ELSIF v_movgest_ts_tipo_code = 'S' THEN
          v_cod_subaccertamento := v_movgest_ts_code;
          v_desc_accertamento := NULL;
    END IF;

    -- Sezione per la modalita' di pagamento
    SELECT tm.quietanziante, tm.quietanzante_nascita_data, tm.quietanziante_nascita_luogo, tm.quietanziante_nascita_stato,
           tm.bic, tm.contocorrente, tm.contocorrente_intestazione, tm.iban, tm.note, tm.data_scadenza,
           dat.accredito_tipo_code, dat.accredito_tipo_desc, tm.soggetto_id, rsm.soggrelmpag_id, tm.modpag_id
    INTO   v_quietanziante, v_data_nascita_quietanziante, v_luogo_nascita_quietanziante, v_stato_nascita_quietanziante,
           v_bic, v_contocorrente, v_intestazione_contocorrente, v_iban, v_note_mod_pag, v_data_scadenza_mod_pag,
           v_cod_tipo_accredito, v_desc_tipo_accredito, v_soggetto_id_modpag_nocess, v_soggrelmpag_id, v_mod_pag_id
    FROM siac.siac_r_subdoc_modpag rsm
    INNER JOIN siac.siac_t_modpag tm ON tm.modpag_id = rsm.modpag_id
    LEFT JOIN siac.siac_d_accredito_tipo dat ON dat.accredito_tipo_id = tm.accredito_tipo_id
                                             AND p_data BETWEEN dat.validita_inizio AND COALESCE(dat.validita_fine, p_data)
                                             AND dat.data_cancellazione IS NULL
    WHERE rsm.subdoc_id = v_subdoc_id
    AND p_data BETWEEN rsm.validita_inizio AND COALESCE(rsm.validita_fine, p_data)
    AND rsm.data_cancellazione IS NULL
    AND p_data BETWEEN tm.validita_inizio AND COALESCE(tm.validita_fine, p_data)
    AND tm.data_cancellazione IS NULL;

    IF v_soggrelmpag_id IS NULL THEN
       v_soggetto_id_modpag := v_soggetto_id_modpag_nocess;
    ELSE
       SELECT rsr.soggetto_id_a
       INTO  v_soggetto_id_modpag_cess
       FROM  siac.siac_r_soggrel_modpag rsm, siac.siac_r_soggetto_relaz rsr
       WHERE rsm.soggrelmpag_id = v_soggrelmpag_id
       AND   rsm.soggetto_relaz_id = rsr.soggetto_relaz_id
       AND   p_data BETWEEN rsm.validita_inizio AND COALESCE(rsm.validita_fine, p_data)
       AND   rsm.data_cancellazione IS NULL
       AND   p_data BETWEEN rsr.validita_inizio AND COALESCE(rsr.validita_fine, p_data)
       AND   rsr.data_cancellazione IS NULL;

       v_soggetto_id_modpag := v_soggetto_id_modpag_cess;
    END IF;

    --  Sezione per i soggetti legati alla modalita' pagamento
    SELECT ts.soggetto_code, dst.soggetto_tipo_desc, dss.soggetto_stato_desc, tpg.ragione_sociale,
           ts.partita_iva, ts.codice_fiscale, ts.codice_fiscale_estero,
           tpf.nome, tpf.cognome
    INTO   v_cod_sogg_mod_pag, v_tipo_sogg_mod_pag, v_stato_sogg_mod_pag, v_rag_sociale_sogg_mod_pag,
           v_p_iva_sogg_mod_pag, v_cf_sogg_mod_pag, v_cf_estero_sogg_mod_pag,
           v_nome_sogg_mod_pag, v_cognome_sogg_mod_pag
    FROM siac.siac_t_soggetto ts
    LEFT JOIN siac.siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
                                            AND p_data BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, p_data)
                                            AND rst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id = rst.soggetto_tipo_id
                                            AND p_data BETWEEN dst.validita_inizio AND COALESCE(dst.validita_fine, p_data)
                                            AND dst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_r_soggetto_stato srss ON srss.soggetto_id = ts.soggetto_id
                                              AND p_data BETWEEN srss.validita_inizio AND COALESCE(srss.validita_fine, p_data)
                                              AND srss.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_stato dss ON dss.soggetto_stato_id = srss.soggetto_stato_id
                                             AND p_data BETWEEN dss.validita_inizio AND COALESCE(dss.validita_fine, p_data)
                                             AND dss.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_giuridica tpg ON tpg.soggetto_id = ts.soggetto_id
                                                AND p_data BETWEEN tpg.validita_inizio AND COALESCE(tpg.validita_fine, p_data)
                                                AND tpg.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_fisica tpf ON tpf.soggetto_id = ts.soggetto_id
                                             AND p_data BETWEEN tpf.validita_inizio AND COALESCE(tpf.validita_fine, p_data)
                                             AND tpf.data_cancellazione IS NULL
    WHERE ts.soggetto_id = v_soggetto_id_modpag
    AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
    AND ts.data_cancellazione IS NULL;

    SELECT sto.ord_anno, sto.ord_numero, tt.ord_ts_code, tp.anno
    INTO  v_anno_ord, v_num_ord, v_num_subord, v_bil_anno_ord
    FROM  siac_r_subdoc_ordinativo_ts rsot, siac_t_ordinativo_ts tt, siac_t_ordinativo sto,
          siac_r_ordinativo_stato ros, siac_d_ordinativo_stato dos,
          siac.siac_t_bil tb, siac.siac_t_periodo tp
    WHERE tt.ord_ts_id = rsot.ord_ts_id
    AND   sto.ord_id = tt.ord_id
    AND   ros.ord_id = sto.ord_id
    AND   ros.ord_stato_id = dos.ord_stato_id
    AND   sto.bil_id = tb.bil_id
    AND   tp.periodo_id = tb.periodo_id
    AND   rsot.subdoc_id = v_subdoc_id
    AND   dos.ord_stato_code <> 'A'
    AND   rsot.data_cancellazione IS NULL
    AND   tt.data_cancellazione IS NULL
    AND   sto.data_cancellazione IS NULL
    AND   ros.data_cancellazione IS NULL
    AND   dos.data_cancellazione IS NULL
    AND   tb.data_cancellazione IS NULL
    AND   tp.data_cancellazione IS NULL
    AND   p_data between rsot.validita_inizio and COALESCE(rsot.validita_fine,p_data)
    AND   p_data between tt.validita_inizio and COALESCE(tt.validita_fine,p_data)
    AND   p_data between sto.validita_inizio and COALESCE(sto.validita_fine,p_data)
    AND   p_data between ros.validita_inizio and COALESCE(ros.validita_fine,p_data)
    AND   p_data between dos.validita_inizio and COALESCE(dos.validita_fine,p_data)
    AND   p_data between tb.validita_inizio and COALESCE(tb.validita_fine,p_data)
    AND   p_data between tp.validita_inizio and COALESCE(tp.validita_fine,p_data);

      INSERT INTO siac.siac_dwh_documento_entrata
      ( ente_proprietario_id,
        ente_denominazione,
        anno_atto_amministrativo,
        num_atto_amministrativo,
        oggetto_atto_amministrativo,
        cod_tipo_atto_amministrativo,
        desc_tipo_atto_amministrativo,
        cod_cdr_atto_amministrativo,
        desc_cdr_atto_amministrativo,
        cod_cdc_atto_amministrativo,
        desc_cdc_atto_amministrativo,
        note_atto_amministrativo,
        cod_stato_atto_amministrativo,
        desc_stato_atto_amministrativo,
        causale_atto_allegato,
        altri_allegati_atto_allegato,
        dati_sensibili_atto_allegato,
        data_scadenza_atto_allegato,
        note_atto_allegato,
        annotazioni_atto_allegato,
        pratica_atto_allegato,
        resp_amm_atto_allegato,
        resp_contabile_atto_allegato,
        anno_titolario_atto_allegato,
        num_titolario_atto_allegato,
        vers_invio_firma_atto_allegato,
        cod_stato_atto_allegato,
        desc_stato_atto_allegato,
        sogg_id_atto_allegato,
        cod_sogg_atto_allegato,
        tipo_sogg_atto_allegato,
        stato_sogg_atto_allegato,
        rag_sociale_sogg_atto_allegato,
        p_iva_sogg_atto_allegato,
        cf_sogg_atto_allegato,
        cf_estero_sogg_atto_allegato,
        nome_sogg_atto_allegato,
        cognome_sogg_atto_allegato,
        anno_doc,
        num_doc,
        desc_doc,
        importo_doc,
        beneficiario_multiplo_doc,
        data_emissione_doc,
        data_scadenza_doc,
        codice_bollo_doc,
        desc_codice_bollo_doc,
        collegato_cec_doc,
        cod_pcc_doc,
        desc_pcc_doc,
        cod_ufficio_doc,
        desc_ufficio_doc,
        cod_stato_doc,
        desc_stato_doc,
        anno_elenco_doc,
        num_elenco_doc,
        data_trasmissione_elenco_doc,
        tot_quote_entrate_elenco_doc,
        tot_quote_spese_elenco_doc,
        tot_da_pagare_elenco_doc,
        tot_da_incassare_elenco_doc,
        cod_stato_elenco_doc,
        desc_stato_elenco_doc,
        cod_gruppo_doc,
        desc_gruppo_doc,
        cod_famiglia_doc,
        desc_famiglia_doc,
        cod_tipo_doc,
        desc_tipo_doc,
        sogg_id_doc,
        cod_sogg_doc,
        tipo_sogg_doc,
        stato_sogg_doc,
        rag_sociale_sogg_doc,
        p_iva_sogg_doc,
        cf_sogg_doc,
        cf_estero_sogg_doc,
        nome_sogg_doc,
        cognome_sogg_doc,
        num_subdoc,
        desc_subdoc,
        importo_subdoc,
        num_reg_iva_subdoc,
        data_scadenza_subdoc,
        convalida_manuale_subdoc,
        importo_da_dedurre_subdoc,
        splitreverse_importo_subdoc,
        pagato_cec_subdoc,
        data_pagamento_cec_subdoc,
        note_tesoriere_subdoc,
        cod_distinta_subdoc,
        desc_distinta_subdoc,
        tipo_commissione_subdoc,
        conto_tesoreria_subdoc,
        rilevante_iva,
        ordinativo_singolo,
        ordinativo_manuale,
        esproprio,
        note,
        avviso,
        cod_tipo_avviso,
        desc_tipo_avviso,
        sogg_id_subdoc,
        cod_sogg_subdoc,
        tipo_sogg_subdoc,
        stato_sogg_subdoc,
        rag_sociale_sogg_subdoc,
        p_iva_sogg_subdoc,
        cf_sogg_subdoc,
        cf_estero_sogg_subdoc,
        nome_sogg_subdoc,
        cognome_sogg_subdoc,
        sede_secondaria_subdoc,
        bil_anno,
        anno_accertamento,
        num_accertamento,
        cod_accertamento,
        desc_accertamento,
        cod_subaccertamento,
        desc_subaccertamento,
        cod_tipo_accredito,
        desc_tipo_accredito,
        mod_pag_id,
        quietanziante,
        data_nascita_quietanziante,
        luogo_nascita_quietanziante,
        stato_nascita_quietanziante,
        bic,
        contocorrente,
        intestazione_contocorrente,
        iban,
        note_mod_pag,
        data_scadenza_mod_pag,
        sogg_id_mod_pag,
        cod_sogg_mod_pag,
        tipo_sogg_mod_pag,
        stato_sogg_mod_pag,
        rag_sociale_sogg_mod_pag,
        p_iva_sogg_mod_pag,
        cf_sogg_mod_pag,
        cf_estero_sogg_mod_pag,
        nome_sogg_mod_pag,
        cognome_sogg_mod_pag,
        bil_anno_ord,
        anno_ord,
        num_ord,
        num_subord,
        --nuova sezione coge 26-09-2016
        registro_repertorio,
		anno_repertorio,
		num_repertorio,
		data_repertorio,
        data_ricezione_portale,
        arrotondamento,
		doc_contabilizza_genpcc,
        doc_id, -- SIAC-5573 ,
        -- 22.05.2018 Sofia siac-6124
        data_ins_atto_allegato,
        data_completa_atto_allegato,
        data_convalida_atto_allegato,
        data_sosp_atto_allegato,
        causale_sosp_atto_allegato,
        data_riattiva_atto_allegato
      )
      VALUES (v_ente_proprietario_id,
              v_ente_denominazione,
              v_anno_atto_amministrativo,
              v_num_atto_amministrativo,
              v_oggetto_atto_amministrativo,
              v_cod_tipo_atto_amministrativo,
              v_desc_tipo_atto_amministrativo,
              v_cod_cdr_atto_amministrativo,
              v_desc_cdr_atto_amministrativo,
              v_cod_cdc_atto_amministrativo,
              v_desc_cdc_atto_amministrativo,
              v_note_atto_amministrativo,
              v_cod_stato_atto_amministrativo,
              v_desc_stato_atto_amministrativo,
              v_causale_atto_allegato,
              v_altri_allegati_atto_allegato,
              v_dati_sensibili_atto_allegato,
              v_data_scadenza_atto_allegato,
              v_note_atto_allegato,
              v_annotazioni_atto_allegato,
              v_pratica_atto_allegato,
              v_resp_amm_atto_allegato,
              v_resp_contabile_atto_allegato,
              v_anno_titolario_atto_allegato,
              v_num_titolario_atto_allegato,
              v_vers_invio_firma_atto_allegato,
              v_cod_stato_atto_allegato,
              v_desc_stato_atto_allegato,
              v_sogg_id_atto_allegato,
              v_cod_sogg_atto_allegato,
              v_tipo_sogg_atto_allegato,
              v_stato_sogg_atto_allegato,
              v_rag_sociale_sogg_atto_allegato,
              v_p_iva_sogg_atto_allegato,
              v_cf_sogg_atto_allegato,
              v_cf_estero_sogg_atto_allegato,
              v_nome_sogg_atto_allegato,
              v_cognome_sogg_atto_allegato,
              v_anno_doc,
              v_num_doc,
	      v_stato_sdi, -- SIAC-6565
              v_desc_doc,
              v_importo_doc,
              v_beneficiario_multiplo_doc,
              v_data_emissione_doc,
              v_data_scadenza_doc,
              v_codice_bollo_doc,
              v_desc_codice_bollo_doc,
              v_collegato_cec_doc,
              v_cod_pcc_doc,
              v_desc_pcc_doc,
              v_cod_ufficio_doc,
              v_desc_ufficio_doc,
              v_cod_stato_doc,
              v_desc_stato_doc,
              v_anno_elenco_doc,
              v_num_elenco_doc,
              v_data_trasmissione_elenco_doc,
              v_tot_quote_entrate_elenco_doc,
              v_tot_quote_spese_elenco_doc,
              v_tot_da_pagare_elenco_doc,
              v_tot_da_incassare_elenco_doc,
              v_cod_stato_elenco_doc,
              v_desc_stato_elenco_doc,
              v_cod_gruppo_doc,
              v_desc_gruppo_doc,
              v_cod_famiglia_doc,
              v_desc_famiglia_doc,
              v_cod_tipo_doc,
              v_desc_tipo_doc,
              v_sogg_id_doc,
              v_cod_sogg_doc,
              v_tipo_sogg_doc,
              v_stato_sogg_doc,
              v_rag_sociale_sogg_doc,
              v_p_iva_sogg_doc,
              v_cf_sogg_doc,
              v_cf_estero_sogg_doc,
              v_nome_sogg_doc,
              v_cognome_sogg_doc,
              v_num_subdoc,
              v_desc_subdoc,
              v_importo_subdoc,
              v_num_reg_iva_subdoc,
              v_data_scadenza_subdoc,
              v_convalida_manuale_subdoc,
              v_importo_da_dedurre_subdoc,
              v_splitreverse_importo_subdoc,
              v_pagato_cec_subdoc,
              v_data_pagamento_cec_subdoc,
              v_note_tesoriere_subdoc,
              v_cod_distinta_subdoc,
              v_desc_distinta_subdoc,
              v_tipo_commissione_subdoc,
              v_conto_tesoreria_subdoc,
              v_rilevante_iva,
              v_ordinativo_singolo,
              v_ordinativo_manuale,
              v_esproprio,
              v_note,
              v_avviso,
              v_cod_tipo_avviso,
              v_desc_tipo_avviso,
              v_soggetto_id,
              v_cod_sogg_subdoc,
              v_tipo_sogg_subdoc,
              v_stato_sogg_subdoc,
              v_rag_sociale_sogg_subdoc,
              v_p_iva_sogg_subdoc,
              v_cf_sogg_subdoc,
              v_cf_estero_sogg_subdoc,
              v_nome_sogg_subdoc,
              v_cognome_sogg_subdoc,
              v_sede_secondaria_subdoc,
              v_bil_anno,
              v_anno_accertamento,
              v_num_accertamento,
              v_cod_accertamento,
              v_desc_accertamento,
              v_cod_subaccertamento,
              v_desc_subaccertamento,
              v_cod_tipo_accredito,
              v_desc_tipo_accredito,
              v_mod_pag_id,
              v_quietanziante,
              v_data_nascita_quietanziante,
              v_luogo_nascita_quietanziante,
              v_stato_nascita_quietanziante,
              v_bic,
              v_contocorrente,
              v_intestazione_contocorrente,
              v_iban,
              v_note_mod_pag,
              v_data_scadenza_mod_pag,
              v_soggetto_id_modpag,
              v_cod_sogg_mod_pag,
              v_tipo_sogg_mod_pag,
              v_stato_sogg_mod_pag,
              v_rag_sociale_sogg_mod_pag,
              v_p_iva_sogg_mod_pag,
              v_cf_sogg_mod_pag,
              v_cf_estero_sogg_mod_pag,
              v_nome_sogg_mod_pag,
              v_cognome_sogg_mod_pag,
              v_bil_anno_ord,
              v_anno_ord,
              v_num_ord,
              v_num_subord,
              --nuova sezione coge 26-09-2016
              v_registro_repertorio,
			  v_anno_repertorio,
			  v_num_repertorio,
			  v_data_repertorio,
              v_data_ricezione_portale,
              v_arrotondamento::numeric,
			  v_doc_contabilizza_genpcc,
              v_doc_id, -- SIAC-5573  ,
              -- 22.05.2018 Sofia siac-6124
	          v_data_ins_atto_allegato,
	          v_data_completa_atto_allegato,
		      v_data_convalida_atto_allegato,
	  	      v_data_sosp_atto_allegato,
        	  v_causale_sosp_atto_allegato,
	          v_data_riattiva_atto_allegato
             );

	END LOOP;

END LOOP;
esito:= 'Fine funzione carico documenti entrata (FNC_SIAC_DWH_DOCUMENTO_ENTRATA) - '||clock_timestamp();
RETURN NEXT;


update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp() - fnc_elaborazione_inizio
where fnc_user=v_user_table;

end if;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico documenti entrata (FNC_SIAC_DWH_DOCUMENTO_ENTRATA) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

drop VIEW siac.siac_v_dwh_fattura_sirfel;

CREATE OR REPLACE VIEW siac_v_dwh_fattura_sirfel (
    ente_proprietario_id,
    fornitore_cod,
    fornitore_desc,
    data_emissione,
    data_ricezione,
    numero_documento,
    documento_fel_tipo_cod,
    documento_fel_tipo_desc,
    data_acquisizione,
    stato_acquisizione,
    importo_lordo,
    arrotondamento_fel,
    importo_netto,
    codice_destinatario,
    tipo_ritenuta,
    aliquota_ritenuta,
    importo_ritenuta,
    anno_protocollo,
    numero_protocollo,
    registro_protocollo,
    data_reg_protocollo,
    modpag_cod,
    modpag_desc,
    aliquota_iva,
    imponibile,
    imposta,
    arrotondamento_onere,
    spese_accessorie,
    doc_id,
    anno_doc,
    num_doc,
    data_emissione_doc,
    cod_tipo_doc,
    cod_sogg_doc,
    esito_stato_fattura_fel, -- siac-6125 Sofia 23.05.2018
    data_scadenza_pagamento_pcc, -- siac-6125 Sofia 23.05.2018
    stato_sdi -- SIAC-6565
    ) 
AS
SELECT tab.ente_proprietario_id, tab.fornitore_cod, tab.fornitore_desc,
    tab.data_emissione, tab.data_ricezione, tab.numero_documento,
    tab.documento_fel_tipo_cod, tab.documento_fel_tipo_desc,
    tab.data_acquisizione, tab.stato_acquisizione, tab.importo_lordo,
    tab.arrotondamento_fel, tab.importo_netto, tab.codice_destinatario,
    tab.tipo_ritenuta, tab.aliquota_ritenuta, tab.importo_ritenuta,
    tab.anno_protocollo, tab.numero_protocollo, tab.registro_protocollo,
    tab.data_reg_protocollo, tab.modpag_cod, tab.modpag_desc, tab.aliquota_iva,
    tab.imponibile, tab.imposta, tab.arrotondamento_onere, tab.spese_accessorie,
    tab.doc_id, tab.anno_doc, tab.num_doc, tab.data_emissione_doc,
    tab.cod_tipo_doc, tab.cod_sogg_doc,
    tab.esito_stato_fattura_fel, -- siac-6125 Sofia 23.05.2018
    tab.data_scadenza_pagamento_pcc, -- siac-6125 Sofia 23.05.2018
    tab.stato_sdi -- SIAC-6565
FROM ( WITH dati_sirfel AS (
    SELECT tf.ente_proprietario_id,
                    tp.codice_prestatore AS fornitore_cod,
                        CASE
                            WHEN tp.denominazione_prestatore IS NULL THEN
                                ((tp.nome_prestatore::text || ' '::text) || tp.cognome_prestatore::text)::character varying
                            ELSE tp.denominazione_prestatore
                        END AS fornitore_desc,
                    tf.data AS data_emissione, tpf.data_ricezione,
                    tf.numero AS numero_documento,
                    dtd.codice AS documento_fel_tipo_cod,
                    dtd.descrizione AS documento_fel_tipo_desc,
                    tf.data_caricamento AS data_acquisizione,
                        CASE
                            WHEN tf.stato_fattura = 'S'::bpchar THEN 'IMPORTATA'::text
                            ELSE
                            CASE
                                WHEN tf.stato_fattura = 'N'::bpchar THEN
                                    'DA ACQUISIRE'::text
                                ELSE 'SOSPESA'::text
                            END
                        END AS stato_acquisizione,
                    tf.importo_totale_documento AS importo_lordo,
                    tf.arrotondamento AS arrotondamento_fel,
                    tf.importo_totale_netto AS importo_netto,
                    tf.codice_destinatario, tf.tipo_ritenuta,
                    tf.aliquota_ritenuta, tf.importo_ritenuta,
                    tpro.anno_protocollo, tpro.numero_protocollo,
                    tpro.registro_protocollo, tpro.data_reg_protocollo,
                    tpagdett.modalita_pagamento AS modpag_cod,
                    dmodpag.descrizione AS modpag_desc, trb.aliquota_iva,
                    trb.imponibile_importo AS imponibile, trb.imposta,
                    trb.arrotondamento AS arrotondamento_onere,
                    trb.spese_accessorie, tf.id_fattura,
                    tpf.esito_stato_fattura esito_stato_fattura_fel, -- siac-6125 Sofia 23.05.2018
                    tpagdett.data_scadenza_pagamento data_scadenza_pagamento_pcc -- siac-6125 Sofia 23.05.2018
    FROM sirfel_t_fattura tf
              JOIN sirfel_t_prestatore tp ON tf.id_prestatore =
                  tp.id_prestatore AND tf.ente_proprietario_id = tp.ente_proprietario_id
         LEFT JOIN sirfel_t_portale_fatture tpf ON tf.id_fattura =
             tpf.id_fattura AND tf.ente_proprietario_id = tpf.ente_proprietario_id
    LEFT JOIN sirfel_d_tipo_documento dtd ON tf.tipo_documento::text =
        dtd.codice::text AND tf.ente_proprietario_id = dtd.ente_proprietario_id
   LEFT JOIN sirfel_t_riepilogo_beni trb ON tf.id_fattura = trb.id_fattura AND
       tf.ente_proprietario_id = trb.ente_proprietario_id
   LEFT JOIN sirfel_t_protocollo tpro ON tf.id_fattura = tpro.id_fattura AND
       tf.ente_proprietario_id = tpro.ente_proprietario_id
   LEFT JOIN sirfel_t_pagamento tpag ON tf.id_fattura = tpag.id_fattura AND
       tf.ente_proprietario_id = tpag.ente_proprietario_id
   LEFT JOIN sirfel_t_dettaglio_pagamento tpagdett ON tpag.id_fattura =
       tpagdett.id_fattura AND tpag.progressivo = tpagdett.progressivo_pagamento AND tpag.ente_proprietario_id = tpagdett.ente_proprietario_id
   LEFT JOIN sirfel_d_modalita_pagamento dmodpag ON
       tpagdett.modalita_pagamento::text = dmodpag.codice::text AND tpagdett.ente_proprietario_id = dmodpag.ente_proprietario_id
    ), dati_fattura AS (
    SELECT rdoc.ente_proprietario_id, rdoc.id_fattura, tdoc.doc_id,
                    tdoc.doc_anno AS anno_doc, tdoc.doc_numero AS num_doc,
                    tdoc.doc_data_emissione AS data_emissione_doc,
                    ddoctipo.doc_tipo_code AS cod_tipo_doc,
                    tdoc.stato_sdi as stato_sdi, -- SIAC-6565
                    tsogg.soggetto_code AS cod_sogg_doc
    FROM siac_r_doc_sirfel rdoc
              JOIN siac_t_doc tdoc ON tdoc.doc_id = rdoc.doc_id
         JOIN siac_d_doc_tipo ddoctipo ON tdoc.doc_tipo_id = ddoctipo.doc_tipo_id
    LEFT JOIN siac_r_doc_sog rdocsog ON tdoc.doc_id = rdocsog.doc_id AND
        rdocsog.data_cancellazione IS NULL AND now() >= rdocsog.validita_inizio AND now() <= COALESCE(rdocsog.validita_fine::timestamp with time zone, now())
   LEFT JOIN siac_t_soggetto tsogg ON rdocsog.soggetto_id = tsogg.soggetto_id
       AND tsogg.data_cancellazione IS NULL
    WHERE rdoc.data_cancellazione IS NULL AND tdoc.data_cancellazione IS NULL
        AND now() >= rdoc.validita_inizio AND now() <= COALESCE(rdoc.validita_fine::timestamp with time zone, now())
    )
    SELECT dati_sirfel.ente_proprietario_id, dati_sirfel.fornitore_cod,
            dati_sirfel.fornitore_desc, dati_sirfel.data_emissione,
            dati_sirfel.data_ricezione, dati_sirfel.numero_documento,
            dati_sirfel.documento_fel_tipo_cod,
            dati_sirfel.documento_fel_tipo_desc, dati_sirfel.data_acquisizione,
            dati_sirfel.stato_acquisizione, dati_sirfel.importo_lordo,
            dati_sirfel.arrotondamento_fel, dati_sirfel.importo_netto,
            dati_sirfel.codice_destinatario, dati_sirfel.tipo_ritenuta,
            dati_sirfel.aliquota_ritenuta, dati_sirfel.importo_ritenuta,
            dati_sirfel.anno_protocollo, dati_sirfel.numero_protocollo,
            dati_sirfel.registro_protocollo, dati_sirfel.data_reg_protocollo,
            dati_sirfel.modpag_cod, dati_sirfel.modpag_desc,
            dati_sirfel.aliquota_iva, dati_sirfel.imponibile,
            dati_sirfel.imposta, dati_sirfel.arrotondamento_onere,
            dati_sirfel.spese_accessorie, dati_sirfel.id_fattura,
            dati_fattura.doc_id, dati_fattura.anno_doc, dati_fattura.num_doc,
            dati_fattura.data_emissione_doc, dati_fattura.cod_tipo_doc,
            dati_fattura.cod_sogg_doc,
            dati_sirfel.esito_stato_fattura_fel, -- siac-6125 Sofia 23.05.2018
            dati_sirfel.data_scadenza_pagamento_pcc, -- siac-6125 Sofia 23.05.2018
            dati_fattura.stato_sdi -- SIAC-6565
    FROM dati_sirfel
      LEFT JOIN dati_fattura ON dati_sirfel.id_fattura =
          dati_fattura.id_fattura AND dati_sirfel.ente_proprietario_id = dati_fattura.ente_proprietario_id
    ) tab;

--SIAC-6565 fine

