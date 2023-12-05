/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
----- all.sql 4.10
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

-- 07.05.2019 SofiaElisa
SELECT * from fnc_dba_add_column_params ('siac_dwh_documento_entrata', 'stato_sdi', 'varchar(2)');


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

drop VIEW IF EXISTS siac.siac_v_dwh_fattura_sirfel;

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
----- all.sql 4.10

--SIAC-6688

DROP FUNCTION IF EXISTS fnc_siac_controllo_importo_impegni_vincolati ( text);

CREATE OR REPLACE FUNCTION fnc_siac_controllo_importo_impegni_vincolati (listaIdAlAtto text)
RETURNS  TABLE (
  v_doc_anno		integer,
  v_doc_numero      varchar(200),
  v_subdoc_numero   integer,
  v_eldoc_anno      integer,
  v_eldoc_numero    integer,   
  v_subdoc_importo 	NUMERIC,
  v_acc_anno		integer,
  v_acc_numero      NUMERIC,
  v_importoOrd 		NUMERIC
)AS
$body$
DECLARE
 arrayIdAlAtto 		integer[];
 indice     		integer:=1;
 idAttoAll  		integer; 
 
 /* v_doc_anno		integer;
  v_doc_numero      VARCHAR(200);
  v_subdoc_numero   integer;
  v_eldoc_numero    integer; 
  v_eldoc_anno      integer; 
  v_subdoc_importo 	NUMERIC;
  v_acc_anno		integer;
  v_acc_numero      NUMERIC;
  v_importoOrd 		NUMERIC;*/
  strMessaggio		varchar(200);
  recVincolati      record;
begin

	arrayIdAlAtto = string_to_array(listaIdAlAtto,',');

    execute 'DROP TABLE IF EXISTS tmp_spesa_vincolata_non_finanziata;';
    execute 'CREATE TABLE tmp_spesa_vincolata_non_finanziata (
                                                                doc_anno			integer,
                                                                doc_numero      	VARCHAR(200),
                                                                subdoc_numero   	integer,
                                                                eldoc_anno      	integer,
                                                                eldoc_numero    	integer,                                                                 
                                                                subdoc_importo 		NUMERIC,
                                                                acc_anno            integer,
																acc_numero          NUMERIC,
                                                                importoOrd 			NUMERIC
    );';

while coalesce(arrayIdAlAtto[indice],0)!=0
  loop
    idAttoAll:=arrayIdAlAtto[indice];
    --raise notice 'idAttoAll=% ',idAttoAll;
    indice:=indice+1;
	for recVincolati in (
	 select 
       sum(subdoc.subdoc_importo) as totale_importo_subdoc
      ,r_movgest.movgest_ts_a_id as acc_ts_id
       ,r_movgest.movgest_ts_b_id as imp_ts_id					 
	from 
		 siac_t_atto_allegato allegato
		,siac_r_atto_allegato_elenco_doc r_allegato_elenco
		,siac_t_elenco_doc elenco
		,siac_r_elenco_doc_subdoc r_elenco_subdoc
		,siac_r_subdoc_movgest_ts r_subdoc_movgest_ts
		,siac_t_movgest_ts imp_ts
		,siac_r_movgest_ts r_movgest 
		,siac_t_subdoc subdoc
	where
		-- condizioni di join
			allegato.attoal_id =  r_allegato_elenco.attoal_id
		and r_allegato_elenco.eldoc_id =  elenco.eldoc_id
		and elenco.eldoc_id =  r_elenco_subdoc.eldoc_id
		and r_elenco_subdoc.subdoc_id =  r_subdoc_movgest_ts.subdoc_id
		and r_subdoc_movgest_ts.movgest_ts_id =  imp_ts.movgest_ts_id
		and imp_ts.movgest_ts_id = r_movgest.movgest_ts_b_id --impegno 	
		and r_elenco_subdoc.subdoc_id = subdoc.subdoc_id 
		-- filtro su data cancellazione
		and allegato.data_cancellazione is null 
		and r_allegato_elenco.data_cancellazione is null
        and now() >= r_allegato_elenco.validita_inizio
		and now() <= coalesce(r_allegato_elenco.validita_fine::timestamp with time zone, now())		
		and elenco.data_cancellazione is null 
		and r_elenco_subdoc.data_cancellazione is null
        and now() >= r_elenco_subdoc.validita_inizio
		and now() <= coalesce(r_elenco_subdoc.validita_fine::timestamp with time zone, now())			
		and r_subdoc_movgest_ts.data_cancellazione is null 
		and now() >= r_subdoc_movgest_ts.validita_inizio
		and now() <= coalesce(r_subdoc_movgest_ts.validita_fine::timestamp with time zone, now())
		and imp_ts.data_cancellazione is null 
		and subdoc.data_cancellazione is null
		and r_movgest.data_cancellazione is null 
		and now() >= r_movgest.validita_inizio
		and now() <= coalesce(r_movgest.validita_fine::timestamp with time zone, now())
		-- filtro su id atto allegato		
		and allegato.attoal_id = idAttoAll
		-- gli accertamenti devono essere validi
		and exists (
			select 1
			from siac_r_movgest_ts_stato r_stato_acc
			,siac_d_movgest_stato acc_stato
			where r_stato_acc.data_cancellazione is null
			and acc_stato.movgest_stato_id = r_stato_acc.movgest_stato_id
			and r_stato_acc.movgest_ts_id = r_movgest.movgest_ts_a_id
			and now() >= r_stato_acc.validita_inizio
		    and now() <= coalesce(r_stato_acc.validita_fine::timestamp with time zone, now())
			and acc_stato.movgest_stato_code <> 'A'
		)
		--gli accertamenti devono essere di tipo accertamento
		and exists(
			select 1
			from siac_t_movgest_ts tmt
			,siac_t_movgest tm
			,siac_d_movgest_tipo dmt
			where tm.movgest_id = tmt.movgest_id
			and tmt.movgest_ts_id = r_movgest.movgest_ts_a_id
			and dmt.movgest_tipo_id = tm.movgest_tipo_id
			and dmt.movgest_tipo_code='A'
			and now() >= tm.validita_inizio
		    and now() <= coalesce(tm.validita_fine::timestamp with time zone, now())
			and now() >= tmt.validita_inizio
		    and now() <= coalesce(tmt.validita_fine::timestamp with time zone, now())
		)
		group by r_movgest.movgest_ts_a_id,r_movgest.movgest_ts_b_id
	)loop
	
	 v_doc_anno:=null;
	 v_doc_numero:=null;
	 v_subdoc_numero:=null;
	 v_eldoc_numero:=null; 
	 v_eldoc_anno:=null; 
	 v_subdoc_importo :=null;
	 v_acc_anno:=null;
	 v_acc_numero:=null;
	 v_importoOrd:=null;
  
	--calcolo l'importo riscosso
	SELECT	coalesce(sum(detA.ord_ts_det_importo),0) into v_importoOrd
		FROM  siac_t_ordinativo ordinativo, 
			  --siac_d_ordinativo_tipo tipo,
			  siac_r_ordinativo_stato rs, 
			  siac_d_ordinativo_stato stato,
			  siac_t_ordinativo_ts ts,
			  siac_t_ordinativo_ts_det detA , 
			  siac_d_ordinativo_ts_det_tipo tipoA,
			  siac_r_ordinativo_ts_movgest_ts r_ordinativo_movgest
		WHERE  r_ordinativo_movgest.movgest_ts_id = recVincolati.acc_ts_id
		and    ts.ord_ts_id=r_ordinativo_movgest.ord_ts_id
		and    ordinativo.ord_id=ts.ord_id
		and    rs.ord_id=ordinativo.ord_id
	    and    stato.ord_stato_id=rs.ord_stato_id
		and    stato.ord_stato_code!='A'
--		and    tipo.ord_tipo_id=ordinativo.ord_tipo_id		
--      and    tipo.ord_tipo_code='I'
		and    detA.ord_ts_id=ts.ord_ts_id
		and    tipoA.ord_ts_det_tipo_id=detA.ord_ts_det_tipo_id
		and    tipoA.ord_ts_det_tipo_code='A'
		and    ordinativo.data_cancellazione is null
		and    now() >= ordinativo.validita_inizio
		and    now() <= coalesce(ordinativo.validita_fine::timestamp with time zone, now())
		and    ts.data_cancellazione is null
		and    now() >= ts.validita_inizio
		and    now() <= coalesce(ts.validita_fine::timestamp with time zone, now())
		and    detA.data_cancellazione is null
		and    now() >= detA.validita_inizio
		and    now() <= coalesce(detA.validita_fine::timestamp with time zone, now())
		and    rs.data_cancellazione is null
		and    now() >= rs.validita_inizio
		and    now() <= coalesce(rs.validita_fine::timestamp with time zone, now())
		and    now() >= r_ordinativo_movgest.validita_inizio
		and    now() <= coalesce(r_ordinativo_movgest.validita_fine::timestamp with time zone, now());
		
		
		if v_importoOrd < recVincolati.totale_importo_subdoc then
			--SIAC-6688
			select distinct tm.movgest_anno, tm.movgest_numero into v_acc_anno, v_acc_numero
			from siac_t_movgest tm
			,siac_t_movgest_ts tmt
			where tm.movgest_id = tmt.movgest_id
			and tmt.movgest_ts_id = recVincolati.acc_ts_id;
			
            --versione con tabella
			--/*
            insert into tmp_spesa_vincolata_non_finanziata
				select doc.doc_anno
				,doc.doc_numero 
				,subdoc.subdoc_numero 
                ,elenco.eldoc_anno  
				,elenco.eldoc_numero				
				,subdoc.subdoc_importo			
				,v_acc_anno
				,v_acc_numero
				,v_importoOrd
		  -- */
           --versione con next
			/*select doc.doc_anno::integer
				  ,doc.doc_numero 
				  ,subdoc.subdoc_numero::integer   
				  ,elenco.eldoc_numero::integer    
				  ,elenco.eldoc_anno::integer
				  ,subdoc.subdoc_importo
            into 
				  v_doc_anno,
			      v_doc_numero,
				  v_subdoc_numero,
				  v_eldoc_numero,
				  v_eldoc_anno, 
				  v_subdoc_importo
            */
			from siac_t_subdoc subdoc
				,siac_t_doc doc
				,siac_r_elenco_doc_subdoc r_elenco_sub
				,siac_t_elenco_doc elenco
                ,siac_r_subdoc_movgest_ts r_subdoc_movgest
                ,siac_r_atto_allegato_elenco_doc r_allegato_elenco				
				where doc.doc_id = subdoc.doc_id
				and  r_elenco_sub.subdoc_id = subdoc.subdoc_id
			    and  elenco.eldoc_id = r_elenco_sub.eldoc_id
                and r_allegato_elenco.eldoc_id = elenco.eldoc_id
                and r_allegato_elenco.attoal_id = idAttoAll 
                and r_subdoc_movgest.subdoc_id = r_elenco_sub.subdoc_id
				and r_subdoc_movgest.movgest_ts_id = recVincolati.imp_ts_id
                and r_subdoc_movgest.data_cancellazione is null				
				and doc.data_cancellazione is null
				and subdoc.data_cancellazione is null
				and r_elenco_sub.data_cancellazione is null
				and elenco.data_cancellazione is null
                and r_allegato_elenco.data_cancellazione is null
                and exists(
                	select 1 
                	from siac_r_elenco_doc_stato r_elenco_stato
                	,siac_d_elenco_doc_stato elenco_stato
                	where r_elenco_stato.eldoc_id = elenco.eldoc_id
                	and r_elenco_stato.eldoc_stato_id = elenco_stato.eldoc_stato_id
                	and elenco_stato.eldoc_stato_code = 'B'
                	and r_elenco_stato.data_cancellazione is null
                );
		-- return next;
		 
		end if;
    end loop;   
  end loop;

	RETURN QUERY 
    
    SELECT 
      *
    from
    	tmp_spesa_vincolata_non_finanziata
        order by acc_anno, acc_numero, eldoc_anno, eldoc_numero;
 
  -- return;
 
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

--FINE SIAC-6688

--SIAC-6775 INIZIO
INSERT INTO siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, verificauo, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dat.azione_tipo_id, dga.gruppo_azioni_id, '/../siacbilapp/azioneRichiesta.do', FALSE, to_timestamp('01/01/2013','dd/mm/yyyy'), tep.ente_proprietario_id, 'admin'
FROM siac_d_azione_tipo dat
JOIN siac_t_ente_proprietario tep ON (dat.ente_proprietario_id = tep.ente_proprietario_id)
JOIN siac_d_gruppo_azioni dga ON (dga.ente_proprietario_id = tep.ente_proprietario_id)
CROSS JOIN (VALUES ('OP-COM-complAttoAllegatoNoContr', 
	'Completamento atto allegato senza effettuare controlli', 
	'AZIONE_SECONDARIA', 
	'FIN_BASE1')) AS tmp(code, descr, tipo, gruppo)
WHERE dga.gruppo_azioni_code = tmp.gruppo
AND dat.azione_tipo_code = tmp.tipo
AND NOT EXISTS (
	SELECT 1
	FROM siac_t_azione ta
	WHERE ta.azione_tipo_id = dat.azione_tipo_id
	AND ta.azione_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;
--SIAC-6775 FINE

-- SIAC-6788 - Sofia inizio
drop FUNCTION if exists fnc_fasi_bil_gest_reimputa_elabora( p_fasebilelabid   INTEGER ,
                                                              enteproprietarioid INTEGER,
                                                              annobilancio       INTEGER,
                                                              impostaProvvedimento boolean, 
                                                              loginoperazione    VARCHAR,
                                                              dataelaborazione TIMESTAMP,
                                                              p_movgest_tipo_code     VARCHAR,
                                                              OUT outfasebilelabretid INTEGER,
                                                              OUT codicerisultato     INTEGER,
                                                              OUT messaggiorisultato  VARCHAR );
															  
															  
CREATE OR replace FUNCTION fnc_fasi_bil_gest_reimputa_elabora( p_fasebilelabid   INTEGER ,
                                                              enteproprietarioid INTEGER,
                                                              annobilancio       INTEGER,
                                                              impostaProvvedimento boolean, -- 07.02.2018 Sofia siac-5368
                                                              loginoperazione    VARCHAR,
                                                              dataelaborazione TIMESTAMP,
                                                              p_movgest_tipo_code     VARCHAR,
                                                              OUT outfasebilelabretid INTEGER,
                                                              OUT codicerisultato     INTEGER,
                                                              OUT messaggiorisultato  VARCHAR )
returns RECORD
AS
$body$
  DECLARE
    strmessaggiotemp   				VARCHAR(1000):='';
    tipomovgestid      				INTEGER:=NULL;
    movgesttstipoid    				INTEGER:=NULL;
    tipomovgesttssid   				INTEGER:=NULL;
    tipomovgesttstid   				INTEGER:=NULL;
    tipocapitologestid 				INTEGER:=NULL;
    bilancioid         				INTEGER:=NULL;
    bilancioprecid     				INTEGER:=NULL;
    periodoid          				INTEGER:=NULL;
    periodoprecid      				INTEGER:=NULL;
    datainizioval      				timestamp:=NULL;
    movgestidret      				INTEGER:=NULL;
    movgesttsidret    				INTEGER:=NULL;
    v_elemid          				INTEGER:=NULL;
    movgesttstipotid  				INTEGER:=NULL;
    movgesttstiposid  				INTEGER:=NULL;
    movgesttstipocode 				VARCHAR(10):=NULL;
    movgeststatoaid   				INTEGER:=NULL;
    v_importomodifica 				NUMERIC;
    movgestrec 						RECORD;
    aggprogressivi 					RECORD;
    cleanrec						RECORD;
    v_movgest_numero                INTEGER;
    v_prog_id                       INTEGER;
    v_flagdariaccertamento_attr_id  INTEGER;
    v_annoriaccertato_attr_id       INTEGER;
    v_numeroriaccertato_attr_id     INTEGER;
    v_numero_el                     integer;
    -- tipo periodo annuale
    sy_per_tipo CONSTANT VARCHAR:='SY';
    -- tipo anno ordinario annuale
    bil_ord_tipo        CONSTANT VARCHAR:='BIL_ORD';
    imp_movgest_tipo    CONSTANT VARCHAR:='I';
    acc_movgest_tipo    CONSTANT VARCHAR:='A';
    sim_movgest_ts_tipo CONSTANT VARCHAR:='SIM';
    sac_movgest_ts_tipo CONSTANT VARCHAR:='SAC';
    a_mov_gest_stato    CONSTANT VARCHAR:='A';
    strmessaggio        VARCHAR(1500):='';
    strmessaggiofinale  VARCHAR(1500):='';
    codresult           INTEGER;
    v_bil_attr_id       INTEGER;
    v_attr_code         VARCHAR;
    movgest_ts_t_tipo   CONSTANT VARCHAR:='T';
    movgest_ts_s_tipo   CONSTANT VARCHAR:='S';
    cap_ug_tipo         CONSTANT VARCHAR:='CAP-UG';
    cap_eg_tipo         CONSTANT VARCHAR:='CAP-EG';
    ape_gest_reimp      CONSTANT VARCHAR:='APE_GEST_REIMP';
    faserec RECORD;
    faseelabrec RECORD;
    recmovgest RECORD;
    v_maxcodgest      INTEGER;
    v_movgest_ts_id   INTEGER;
    v_ambito_id       INTEGER;
    v_inizio          VARCHAR;
    v_fine            VARCHAR;
    v_bil_tipo_id     INTEGER;
    v_periodo_id      INTEGER;
    v_periodo_tipo_id INTEGER;
    v_tmp             VARCHAR;


    -- 15.02.2017 Sofia SIAC-4425
	FRAZIONABILE_ATTR CONSTANT varchar:='flagFrazionabile';
    flagFrazAttrId integer:=null;
	-- 07.03.2017 Sofia SIAC-4568
    dataEmissione     timestamp:=null;

	-- 07.02.2018 Sofia siac-5368
    movGestStatoId INTEGER:=null;
    movGestStatoPId INTEGER:=null;
	MOVGEST_STATO_CODE_P CONSTANT VARCHAR:='P';

  BEGIN
    codicerisultato:=NULL;
    messaggiorisultato:=NULL;
    strmessaggiofinale:='Inizio.';
    datainizioval:= clock_timestamp();
    -- 07.03.2017 Sofia SIAC-4568
    dataEmissione:=(annoBilancio::varchar||'-01-01')::timestamp;

    SELECT attr.attr_id
    INTO   v_flagdariaccertamento_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code ='flagDaRiaccertamento'
    AND    attr.ente_proprietario_id = enteproprietarioid;

    SELECT attr.attr_id
    INTO   v_annoriaccertato_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code ='annoRiaccertato'
    AND    attr.ente_proprietario_id = enteproprietarioid;

    SELECT attr.attr_id
    INTO   v_numeroriaccertato_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code ='numeroRiaccertato'
    AND    attr.ente_proprietario_id = enteproprietarioid;

    -- estraggo il bilancio nuovo
    SELECT bil_id
    INTO   strict bilancioid
    FROM   siac_t_bil
    WHERE  bil_code = 'BIL_'
                  ||annobilancio::VARCHAR
    AND    ente_proprietario_id = enteproprietarioid;

	-- 07.02.2018 Sofia siac-5368
    strMessaggio:='Lettura identificativo per stato='||MOVGEST_STATO_CODE_P||'.';
	select stato.movgest_stato_id
    into   strict movGestStatoPId
    from siac_d_movgest_stato stato
    where stato.ente_proprietario_id=enteproprietarioid
    and   stato.movgest_stato_code=MOVGEST_STATO_CODE_P;

    -- 15.02.2017 Sofia Sofia SIAC-4425
	if p_movgest_tipo_code=imp_movgest_tipo then
    	strMessaggio:='Lettura identificativo per flagFrazAttrCode='||FRAZIONABILE_ATTR||'.';
     	select attr.attr_id into strict flagFrazAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FRAZIONABILE_ATTR
        and   attr.data_cancellazione is null
        and   attr.validita_fine is null;

        strMessaggio:='Lettura identificativo per movGestTipoCode='||imp_movgest_tipo||'.';
        select tipo.movgest_tipo_id into strict tipoMovGestId
        from siac_d_movgest_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.movgest_tipo_code=imp_movgest_tipo
        and   tipo.data_cancellazione is null
        and   tipo.validita_fine is null;

        strMessaggio:='Lettura identificativo per movGestTsTTipoCode='||movgest_ts_t_tipo||'.';
        select tipo.movgest_ts_tipo_id into strict tipoMovGestTsTId
        from siac_d_movgest_ts_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.movgest_ts_tipo_code=movgest_ts_t_tipo
        and   tipo.data_cancellazione is null
        and   tipo.validita_fine is null;

    end if;


    FOR movgestrec IN
    (
           SELECT reimputazione_id ,
                  bil_id ,
                  elemid_old ,
                  elem_code ,
                  elem_code2 ,
                  elem_code3 ,
                  elem_tipo_code ,
                  movgest_id ,
                  movgest_anno ,
                  movgest_numero ,
                  movgest_desc ,
                  movgest_tipo_id ,
                  parere_finanziario ,
                  parere_finanziario_data_modifica ,
                  parere_finanziario_login_operazione ,
                  movgest_ts_id ,
                  movgest_ts_code ,
                  movgest_ts_desc ,
                  movgest_ts_tipo_id ,
                  movgest_ts_id_padre ,
                  ordine ,
                  livello ,
                  movgest_ts_scadenza_data ,
                  movgest_ts_det_tipo_id ,
                  impoinizimpegno ,
                  impoattimpegno ,
                  importomodifica ,
                  tipo ,
                  movgest_ts_det_tipo_code ,
                  movgest_ts_det_importo ,
                  mtdm_reimputazione_anno ,
                  mtdm_reimputazione_flag ,
                  mod_tipo_code ,
                  attoamm_id,       -- 07.02.2018 Sofia siac-5368
                  movgest_stato_id, -- 07.02.2018 Sofia siac-5368
                  login_operazione ,
                  ente_proprietario_id,
                  siope_tipo_debito_id,
		          siope_assenza_motivazione_id
           FROM   fase_bil_t_reimputazione
           WHERE  ente_proprietario_id = enteproprietarioid
           AND    fasebilelabid = p_fasebilelabid
           AND    fl_elab = 'N'
           order by  1) -- 19.04.2019 Sofia JIRA SIAC-6788
    LOOP
      movgesttsidret:=NULL;
      movgestidret:=NULL;
      codresult:=NULL;
      v_elemid:=NULL;
      v_inizio := movgestrec.mtdm_reimputazione_anno::VARCHAR ||'-01-01';
      v_fine := movgestrec.mtdm_reimputazione_anno::VARCHAR ||'-12-31';

	  --caso in cui si tratta di impegno/ accertamento creo la struttua a partire da movgest
      --tipots.movgest_ts_tipo_code tipo

      IF movgestrec.tipo !='S' THEN

        v_movgest_ts_id = NULL;
        --v_maxcodgest= movgestrec.movgest_ts_code::INTEGER;

        IF p_movgest_tipo_code = 'I' THEN
          strmessaggio:='progressivo per Impegno ' ||'imp_'||movgestrec.mtdm_reimputazione_anno::VARCHAR ||'.';
          SELECT prog_value + 1 ,
                 prog_id
          INTO   strict v_movgest_numero ,
                 v_prog_id
          FROM   siac_t_progressivo ,
                 siac_d_ambito
          WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
          AND    siac_t_progressivo.ente_proprietario_id = enteproprietarioid
          AND    siac_t_progressivo.prog_key = 'imp_'  ||movgestrec.mtdm_reimputazione_anno::VARCHAR
          AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          IF v_movgest_numero IS NULL THEN
            strmessaggio:='aggiungo progressivo per anno ' ||'imp_' ||movgestrec.mtdm_reimputazione_anno::VARCHAR ||'.';
            SELECT ambito_id
            INTO   strict v_ambito_id
            FROM   siac_d_ambito
            WHERE  ambito_code = 'AMBITO_FIN'
            AND    ente_proprietario_id = enteproprietarioid
            AND    data_cancellazione IS NULL;

            INSERT INTO siac_t_progressivo
            (
                        prog_value,
                        prog_key ,
                        ambito_id ,
                        validita_inizio ,
                        validita_fine ,
                        ente_proprietario_id ,
                        data_cancellazione ,
                        login_operazione
            )
            VALUES
            (
                        0,
                        'imp_' ||movgestrec.mtdm_reimputazione_anno::VARCHAR,
                        v_ambito_id ,
                        v_inizio::timestamp,
                        v_fine::timestamp,
                        enteproprietarioid ,
                        NULL,
                        loginoperazione
            )
            returning   prog_id  INTO        v_prog_id ;

            SELECT prog_value + 1 ,
                   prog_id
            INTO   v_movgest_numero ,
                   v_prog_id
            FROM   siac_t_progressivo ,
                   siac_d_ambito
            WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
            AND    siac_t_progressivo .ente_proprietario_id = enteproprietarioid
            AND    siac_t_progressivo.prog_key = 'imp_'
                          ||movgestrec.mtdm_reimputazione_anno::VARCHAR
            AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          END IF;

        ELSE --IF p_movgest_tipo_code = 'I'

          --Accertamento
          SELECT prog_value + 1,
                 prog_id
          INTO   v_movgest_numero,
                 v_prog_id
          FROM   siac_t_progressivo ,
                 siac_d_ambito
          WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
          AND    siac_t_progressivo .ente_proprietario_id = enteproprietarioid
          AND    siac_t_progressivo.prog_key = 'acc_'
                        ||movgestrec.mtdm_reimputazione_anno::VARCHAR
          AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          IF v_movgest_numero IS NULL THEN

            strmessaggio:='aggiungo progressivo per anno ' ||'acc_' ||movgestrec.mtdm_reimputazione_anno::VARCHAR ||'.';
            SELECT ambito_id
            INTO   v_ambito_id
            FROM   siac_d_ambito
            WHERE  ambito_code = 'AMBITO_FIN'
            AND    ente_proprietario_id = enteproprietarioid
            AND    data_cancellazione IS NULL;

            v_inizio := movgestrec.mtdm_reimputazione_anno::VARCHAR||'-01-01'; v_fine := movgestrec.mtdm_reimputazione_anno::VARCHAR||'-12-31';
            INSERT INTO siac_t_progressivo
			(
				prog_value ,
				prog_key ,
				ambito_id ,
				validita_inizio ,
				validita_fine ,
				ente_proprietario_id ,
				data_cancellazione ,
				login_operazione
			)
			VALUES
			(
				0,
				'acc_'||movgestrec.mtdm_reimputazione_anno::VARCHAR,
				v_ambito_id ,
				v_inizio::timestamp,
				v_fine::timestamp,
				enteproprietarioid ,
				NULL,
				loginoperazione
			)
            returning   prog_id INTO        v_prog_id ;

            SELECT prog_value + 1 ,
                   prog_id
            INTO   strict v_movgest_numero ,
                   v_prog_id
            FROM   siac_t_progressivo ,
                   siac_d_ambito
            WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
            AND    siac_t_progressivo .ente_proprietario_id = enteproprietarioid
            AND    siac_t_progressivo.prog_key = 'acc_'
                          ||movgestrec.mtdm_reimputazione_anno::VARCHAR
            AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          END IF; --fine if v_movgest_numero

        END IF;

        strmessaggio:='inserisco il siac_t_movgest.';
        INSERT INTO siac_t_movgest
        (
			movgest_anno,
			movgest_numero,
			movgest_desc,
			movgest_tipo_id,
			bil_id,
			validita_inizio,
			ente_proprietario_id,
			login_operazione,
			parere_finanziario,
			parere_finanziario_data_modifica,
			parere_finanziario_login_operazione
        )
        VALUES
        (
			movgestrec.mtdm_reimputazione_anno,
            v_movgest_numero,
			movgestrec.movgest_desc,
			movgestrec.movgest_tipo_id,
			bilancioid,
			datainizioval,
			enteproprietarioid,
			loginoperazione,
			movgestrec.parere_finanziario,
			movgestrec.parere_finanziario_data_modifica,
			movgestrec.parere_finanziario_login_operazione
        )
        returning   movgest_id INTO        movgestidret;

        IF movgestidret IS NULL THEN
          strmessaggiotemp:=strmessaggio;
          codresult:=-1;
        END IF;

        RAISE notice 'dopo inserimento siac_t_movgest movGestIdRet=%',movgestidret;

        strmessaggio:='aggiornamento progressivo v_prog_id ' ||v_prog_id::VARCHAR;
        UPDATE siac_t_progressivo
        SET    prog_value = prog_value + 1
        WHERE  prog_id = v_prog_id;

        strmessaggio:='estraggo il capitolo =elem_code ' || movgestrec.elem_code ||' elem_code2 ' || movgestrec.elem_code2 ||' elem_code3' || movgestrec.elem_code3 ||' elem_tipo_code =' || movgestrec.elem_tipo_code ||' bilancioId='||bilancioid::VARCHAR ||'.';
        --raise notice 'strMessaggio=%',strMessaggio;
        SELECT be.elem_id
        INTO   v_elemid
        FROM   siac_t_bil_elem be,
               siac_r_bil_elem_stato rbes,
               siac_d_bil_elem_stato bbes,
               siac_d_bil_elem_tipo bet
        WHERE  be.elem_tipo_id = bet.elem_tipo_id
        AND    be.elem_code=movgestrec.elem_code
        AND    be.elem_code2=movgestrec.elem_code2
        AND    be.elem_code3=movgestrec.elem_code3
        AND    bet.elem_tipo_code = movgestrec.elem_tipo_code
        AND    be.elem_id = rbes.elem_id
        AND    rbes.elem_stato_id = bbes.elem_stato_id
        AND    bbes.elem_stato_code !='AN'
        AND    rbes.data_cancellazione IS NULL
        AND    be.bil_id = bilancioid
        AND    be.ente_proprietario_id = enteproprietarioid
        AND    be.data_cancellazione IS NULL
        AND    be.validita_fine IS NULL;

        IF v_elemid IS NULL THEN
          codresult:=-1;
          strmessaggio:= ' impegno/accertamento privo di capitolo nel nuovo bilancio elem_code ' || movgestrec.elem_code ||' elem_code2 ' || movgestrec.elem_code2 ||' elem_code3' || movgestrec.elem_code3 ||' elem_tipo_code =' || movgestrec.elem_tipo_code ||' bilancioId='||bilancioid::VARCHAR ||'.';

          update fase_bil_t_reimputazione
          set fl_elab='X'
            ,movgestnew_ts_id = movgesttsidret
            ,movgestnew_id    = movgestidret
            ,data_modifica = clock_timestamp()
            ,scarto_code='IMAC1'
            ,scarto_desc=' impegno/accertamento privo di capitolo nel nuovo bilancio elem_code ' || movgestrec.elem_code ||' elem_code2 ' || movgestrec.elem_code2 ||' elem_code3' || movgestrec.elem_code3 ||' elem_tipo_code =' || movgestrec.elem_tipo_code ||' bilancioId='||bilancioid::VARCHAR ||'.'
      	  where
      	  	fase_bil_t_reimputazione.reimputazione_id = movgestrec.reimputazione_id;
          continue;
        END IF;


        -- relazione tra capitolo e movimento
        strmessaggio:='Inserimento relazione movimento capitolo anno='||movgestrec.movgest_anno ||' numero=' ||movgestrec.movgest_numero || ' v_elemId='||v_elemid::varchar ||' [siac_r_movgest_bil_elem]';

        INSERT INTO siac_r_movgest_bil_elem
        (
          movgest_id,
          elem_id,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
        )
        VALUES
        (
          movgestidret,
          v_elemid,--movGestRec.elemId_old,
          datainizioval,
          enteproprietarioid,
          loginoperazione
        )
        returning   movgest_atto_amm_id  INTO        codresult;

        IF codresult IS NULL THEN
          codresult:=-1;
          strmessaggiotemp:=strmessaggio;
        ELSE
          codresult:=NULL;
        END IF;
        strmessaggio:='Inserimento movimento movGestTipo=' ||movgestrec.tipo || ' anno=' ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero|| ' sub=' ||movgestrec.movgest_ts_code || ' [siac_t_movgest_ts].';
        RAISE notice 'strMessaggio=% ',strmessaggio;

        v_maxcodgest := v_movgest_numero;



      ELSE --caso in cui si tratta di subimpegno/ subaccertamento estraggo il movgest_id padre e movgest_ts_id_padre IF movgestrec.tipo =='S'

        -- todo calcolare il papa' sel subimpegno movgest_id  del padre  ed anche movgest_ts_id_padre
        strmessaggio:='caso SUB movGestTipo=' ||movgestrec.tipo ||'.';

        SELECT count(*)
        INTO v_numero_el
        FROM   fase_bil_t_reimputazione
        WHERE  fase_bil_t_reimputazione.movgest_anno = movgestrec.movgest_anno
        AND    fase_bil_t_reimputazione.movgest_numero = movgestrec.movgest_numero
        AND    fase_bil_t_reimputazione.fasebilelabid = p_fasebilelabid
        AND    fase_bil_t_reimputazione.mod_tipo_code =  movgestrec.mod_tipo_code
        AND    fase_bil_t_reimputazione.tipo = 'T'
        and    fase_bil_t_reimputazione.mtdm_reimputazione_anno=movgestrec.mtdm_reimputazione_anno; -- 28.02.2018 Sofia jira siac-5964
        raise notice 'strMessaggio anno=% numero=% v_numero_el=%', movgestrec.movgest_anno, movgestrec.movgest_numero,v_numero_el;

        SELECT fase_bil_t_reimputazione.movgestnew_id ,
               fase_bil_t_reimputazione.movgestnew_ts_id
        INTO strict  movgestidret ,
               v_movgest_ts_id
        FROM   fase_bil_t_reimputazione
        WHERE  fase_bil_t_reimputazione.movgest_anno = movgestrec.movgest_anno
        AND    fase_bil_t_reimputazione.movgest_numero = movgestrec.movgest_numero
        AND    fase_bil_t_reimputazione.fasebilelabid = p_fasebilelabid
        AND    fase_bil_t_reimputazione.mod_tipo_code =  movgestrec.mod_tipo_code
        AND    fase_bil_t_reimputazione.tipo = 'T'
        and    fase_bil_t_reimputazione.mtdm_reimputazione_anno=movgestrec.mtdm_reimputazione_anno; -- 28.02.2018 Sofia jira siac-5964



        if movgestidret is null then
          update fase_bil_t_reimputazione
          set fl_elab        ='X'
            ,scarto_code      ='IMACNP'
            ,scarto_desc      =' subimpegno/subaccertamento privo di testata modificata movGestTipo=' ||movgestrec.tipo || ' anno=' ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero|| ' v_numero_el = ' ||v_numero_el::varchar||'.'
      	    ,movgestnew_ts_id = movgesttsidret
            ,movgestnew_id    = movgestidret
            ,data_modifica = clock_timestamp()
          from
          	siac_t_bil_elem elem
      	  where
      	  	fase_bil_t_reimputazione.reimputazione_id = movgestrec.reimputazione_id;
        	continue;
        end if;


        strmessaggio:=' estraggo movGest padre movGestRec.movgest_id='||movgestrec.movgest_id::VARCHAR ||' p_fasebilelabid'||p_fasebilelabid::VARCHAR ||'' ||'.';
        --strMessaggio:='calcolo il max siac_t_movgest_ts.movgest_ts_code  movGestIdRet='||movGestIdRet::varchar ||'.';

        SELECT max(siac_t_movgest_ts.movgest_ts_code::INTEGER)
        INTO   v_maxcodgest
        FROM   siac_t_movgest ,
               siac_t_movgest_ts ,
               siac_d_movgest_tipo,
               siac_d_movgest_ts_tipo
        WHERE  siac_t_movgest.movgest_id = siac_t_movgest_ts.movgest_id
        AND    siac_t_movgest.movgest_tipo_id = siac_d_movgest_tipo.movgest_tipo_id
        AND    siac_d_movgest_tipo.movgest_tipo_code = p_movgest_tipo_code
        AND    siac_t_movgest_ts.movgest_ts_tipo_id = siac_d_movgest_ts_tipo.movgest_ts_tipo_id
        AND    siac_d_movgest_ts_tipo.movgest_ts_tipo_code = 'S'
        AND    siac_t_movgest.bil_id = bilancioid
        AND    siac_t_movgest.ente_proprietario_id = enteproprietarioid
        AND    siac_t_movgest.movgest_id = movgestidret;

        IF v_maxcodgest IS NULL THEN
          v_maxcodgest:=0;
        END IF;
        v_maxcodgest := v_maxcodgest+1;

     END IF; -- fine cond se sub o non sub





      -- caso di sub



      INSERT INTO siac_t_movgest_ts
      (
        movgest_ts_code,
        movgest_ts_desc,
        movgest_id,
        movgest_ts_tipo_id,
        movgest_ts_id_padre,
        movgest_ts_scadenza_data,
        ordine,
        livello,
        validita_inizio,
        ente_proprietario_id,
        login_operazione,
        login_creazione,
		siope_tipo_debito_id,
		siope_assenza_motivazione_id
      )
      VALUES
      (
        v_maxcodgest::VARCHAR, --movGestRec.movgest_ts_code,
        movgestrec.movgest_ts_desc,
        movgestidret, -- inserito se I/A, per SUB ricavato
        movgestrec.movgest_ts_tipo_id,
        v_movgest_ts_id, -- ????? valorizzato se SUB come quello da cui deriva diversamente null
        movgestrec.movgest_ts_scadenza_data,
        movgestrec.ordine,
        movgestrec.livello,
--        dataelaborazione, -- 07.03.2017 Sofia SIAC-4568
		dataEmissione,      -- 07.03.2017 Sofia SIAC-4568
        enteproprietarioid,
        loginoperazione,
        loginoperazione,
        movgestrec.siope_tipo_debito_id,
		movgestrec.siope_assenza_motivazione_id
      )
      returning   movgest_ts_id
      INTO        movgesttsidret;

      IF movgesttsidret IS NULL THEN
        codresult:=-1;
        strmessaggiotemp:=strmessaggio;
      END IF;
      RAISE notice 'dopo inserimento siac_t_movgest_ts movGestTsIdRet=% codResult=%', movgesttsidret,codresult;

      -- siac_r_movgest_ts_stato
      strmessaggio:='Inserimento movimento ' || ' anno='  ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero || ' sub=' ||movgestrec.movgest_ts_code || ' [siac_r_movgest_ts_stato].';
      -- 07.02.2018 Sofia siac-5368
      /*INSERT INTO siac_r_movgest_ts_stato
	  (
          movgest_ts_id,
          movgest_stato_id,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
	  )
	  (
         SELECT movgesttsidret,
                r.movgest_stato_id,
                datainizioval,
                enteproprietarioid,
                loginoperazione
         FROM   siac_r_movgest_ts_stato r,
                siac_d_movgest_stato stato
         WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
         AND    stato.movgest_stato_id=r.movgest_stato_id
         AND    r.data_cancellazione IS NULL
         AND    r.validita_fine IS NULL
         AND    stato.data_cancellazione IS NULL
         AND    stato.validita_fine IS NULL )
      returning   movgest_stato_r_id INTO        codresult;*/

      -- 07.02.2018 Sofia siac-5368
	  if impostaProvvedimento=true then
      	     movGestStatoId:=movGestRec.movgest_stato_id;
      else   movGestStatoId:=movGestStatoPId;
      end if;

      INSERT INTO siac_r_movgest_ts_stato
	  (
          movgest_ts_id,
          movgest_stato_id,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
	  )
      values
      (
      	movgesttsidret,
        movGestStatoId,
        datainizioval,
        enteProprietarioId,
        loginoperazione
      )
      returning   movgest_stato_r_id INTO        codresult;


      IF codresult IS NULL THEN
        codresult:=-1;
        strmessaggiotemp:=strmessaggio;
      ELSE
        codresult:=NULL;
      END IF;
      RAISE notice 'dopo inserimento siac_r_movgest_ts_stato movGestTsIdRet=% codResult=%', movgesttsidret,codresult;
      -- siac_t_movgest_ts_det
      strmessaggio:='Inserimento movimento ' || ' anno=' ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero || ' sub=' ||movgestrec.movgest_ts_code|| ' [siac_t_movgest_ts_det].';
      RAISE notice ' inserimento siac_t_movgest_ts_det movGestTsIdRet=% movGestRec.movgest_ts_id=%', movgesttsidret,movgestrec.movgest_ts_id;
      v_importomodifica := movgestrec.importomodifica * -1;
      INSERT INTO siac_t_movgest_ts_det
	  (
        movgest_ts_id,
        movgest_ts_det_tipo_id,
        movgest_ts_det_importo,
        validita_inizio,
        ente_proprietario_id,
        login_operazione
	  )
	  (
       SELECT movgesttsidret,
              r.movgest_ts_det_tipo_id,
              v_importomodifica,
              datainizioval,
              enteproprietarioid,
              loginoperazione
       FROM   siac_t_movgest_ts_det r
       WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
       AND    r.data_cancellazione IS NULL
       AND    r.validita_fine IS NULL );

      IF codresult IS NULL THEN
        codresult:=-1;
        strmessaggiotemp:=strmessaggio;
      ELSE
        codresult:=NULL;
      END IF;
      strmessaggio:='Inserimento classificatori  movgest_ts_id='||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_class].';
      -- siac_r_movgest_class
      INSERT INTO siac_r_movgest_class
	  (
				  movgest_ts_id,
				  classif_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.classif_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_class r,
					siac_t_class class
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    class.classif_id=r.classif_id
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL
			 AND    class.data_cancellazione IS NULL
			 AND    class.validita_fine IS NULL );

      strmessaggio:='Inserimento attributi  movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_attr].';
      -- siac_r_movgest_ts_attr
      INSERT INTO siac_r_movgest_ts_attr
	  (
        movgest_ts_id,
        attr_id,
        tabella_id,
        BOOLEAN,
        percentuale,
        testo,
        numerico,
        validita_inizio,
        ente_proprietario_id,
        login_operazione
	  )
	  (
         SELECT movgesttsidret,
                r.attr_id,
                r.tabella_id,
                r.BOOLEAN,
                r.percentuale,
                r.testo,
                r.numerico,
                datainizioval,
                enteproprietarioid,
                loginoperazione
         FROM   siac_r_movgest_ts_attr r,
                siac_t_attr attr
         WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
         AND    attr.attr_id=r.attr_id
         AND    r.data_cancellazione IS NULL
         AND    r.validita_fine IS NULL
         AND    attr.data_cancellazione IS NULL
         AND    attr.validita_fine IS NULL
         AND    attr.attr_code NOT IN ('flagDaRiaccertamento',
                                       'annoRiaccertato',
                                       'numeroRiaccertato') );

      INSERT INTO siac_r_movgest_ts_attr
	  (
				  movgest_ts_id ,
				  attr_id ,
				  tabella_id ,
				  "boolean" ,
				  percentuale,
				  testo,
				  numerico ,
				  validita_inizio ,
				  validita_fine ,
				  ente_proprietario_id ,
				  data_cancellazione ,
				  login_operazione
	  )  VALUES (
				  movgesttsidret ,
				  v_flagdariaccertamento_attr_id ,
				  NULL,
				  'S',
				  NULL,
				  NULL ,
				  NULL,
				  now() ,
				  NULL ,
				  enteproprietarioid ,
				  NULL ,
				  loginoperazione
	  );

      INSERT INTO siac_r_movgest_ts_attr
	  (
        movgest_ts_id ,
        attr_id ,
        tabella_id ,
        "boolean" ,
        percentuale,
        testo,
        numerico ,
        validita_inizio ,
        validita_fine ,
        ente_proprietario_id ,
        data_cancellazione ,
        login_operazione
	  )
	  VALUES
	  (
        movgesttsidret ,
        v_annoriaccertato_attr_id,
        NULL,
        NULL,
        NULL,
        movgestrec.movgest_anno ,
        NULL ,
        now() ,
        NULL,
        enteproprietarioid,
        NULL,
        loginoperazione
	  );

      INSERT INTO siac_r_movgest_ts_attr
	  (
        movgest_ts_id ,
        attr_id ,
        tabella_id ,
        "boolean" ,
        percentuale,
        testo,
        numerico ,
        validita_inizio ,
        validita_fine ,
        ente_proprietario_id ,
        data_cancellazione ,
        login_operazione
	  )
	  VALUES
	  (
        movgesttsidret ,
        v_numeroriaccertato_attr_id ,
        NULL,
        NULL,
        NULL,
        movgestrec.movgest_numero ,
        NULL,
        now() ,
        NULL ,
        enteproprietarioid ,
        NULL,
        loginoperazione
	  );

      -- siac_r_movgest_ts_atto_amm
      /*strmessaggio:='Inserimento   movgest_ts_id='
      ||movgestrec.movgest_ts_id::VARCHAR
      || ' [siac_r_movgest_ts_atto_amm].';
      INSERT INTO siac_r_movgest_ts_atto_amm
	  (
				  movgest_ts_id,
				  attoamm_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.attoamm_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_atto_amm r,
					siac_t_atto_amm atto
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    atto.attoamm_id=r.attoamm_id
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL
       );*/
--			 AND    atto.data_cancellazione IS NULL Sofia HD-INC000001535447
--			 AND    atto.validita_fine IS NULL );

	   -- 07.02.2018 Sofia siac-5368
	   if impostaProvvedimento=true then
       	strmessaggio:='Inserimento   movgest_ts_id='
	      ||movgestrec.movgest_ts_id::VARCHAR
    	  || ' [siac_r_movgest_ts_atto_amm].';
       	INSERT INTO siac_r_movgest_ts_atto_amm
	  	(
		 movgest_ts_id,
	     attoamm_id,
	     validita_inizio,
	     ente_proprietario_id,
	     login_operazione
	  	)
        values
        (
         movgesttsidret,
         movgestrec.attoamm_id,
         datainizioval,
	 	 enteproprietarioid,
	 	 loginoperazione
        );
       end if;


      -- siac_r_movgest_ts_sog
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_sog].';
      INSERT INTO siac_r_movgest_ts_sog
	  (
				  movgest_ts_id,
				  soggetto_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.soggetto_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_sog r,
					siac_t_soggetto sogg
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    sogg.soggetto_id=r.soggetto_id
			 AND    sogg.data_cancellazione IS NULL
			 AND    sogg.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_movgest_ts_sogclasse
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_sogclasse].';
      INSERT INTO siac_r_movgest_ts_sogclasse
	  (
				  movgest_ts_id,
				  soggetto_classe_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.soggetto_classe_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_sogclasse r,
					siac_d_soggetto_classe classe
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    classe.soggetto_classe_id=r.soggetto_classe_id
			 AND    classe.data_cancellazione IS NULL
			 AND    classe.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_movgest_ts_programma
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_programma].';
      INSERT INTO siac_r_movgest_ts_programma
	  (
				  movgest_ts_id,
				  programma_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.programma_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_programma r,
					siac_t_programma prog
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    prog.programma_id=r.programma_id
			 AND    prog.data_cancellazione IS NULL
			 AND    prog.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_mutuo_voce_movgest
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_mutuo_voce_movgest].';
      INSERT INTO siac_r_mutuo_voce_movgest
	  (
				  movgest_ts_id,
				  mut_voce_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.mut_voce_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_mutuo_voce_movgest r,
					siac_t_mutuo_voce voce
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    voce.mut_voce_id=r.mut_voce_id
			 AND    voce.data_cancellazione IS NULL
			 AND    voce.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_causale_movgest_ts
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_causale_movgest_ts].';
      INSERT INTO siac_r_causale_movgest_ts
	  (
				  movgest_ts_id,
				  caus_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.caus_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_causale_movgest_ts r,
					siac_d_causale caus
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    caus.caus_id=r.caus_id
			 AND    caus.data_cancellazione IS NULL
			 AND    caus.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- 05.05.2017 Sofia HD-INC000001737424
      -- siac_r_subdoc_movgest_ts
      /*
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_subdoc_movgest_ts].';
      INSERT INTO siac_r_subdoc_movgest_ts
	  (
				  movgest_ts_id,
				  subdoc_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.subdoc_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_subdoc_movgest_ts r,
					siac_t_subdoc sub
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    sub.subdoc_id=r.subdoc_id
			 AND    sub.data_cancellazione IS NULL
			 AND    sub.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_predoc_movgest_ts
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_predoc_movgest_ts].';
      INSERT INTO siac_r_predoc_movgest_ts
                  (
                              movgest_ts_id,
                              predoc_id,
                              validita_inizio,
                              ente_proprietario_id,
                              login_operazione
                  )
                  (
                         SELECT movgesttsidret,
                                r.predoc_id,
                                datainizioval,
                                enteproprietarioid,
                                loginoperazione
                         FROM   siac_r_predoc_movgest_ts r,
                                siac_t_predoc sub
                         WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
                         AND    sub.predoc_id=r.predoc_id
                         AND    sub.data_cancellazione IS NULL
                         AND    sub.validita_fine IS NULL
                         AND    r.data_cancellazione IS NULL
                         AND    r.validita_fine IS NULL );
	  */
      -- 05.05.2017 Sofia HD-INC000001737424


      strmessaggio:='aggiornamento tabella di appoggio';
      UPDATE fase_bil_t_reimputazione
      SET   movgestnew_ts_id =movgesttsidret
      		,movgestnew_id =movgestidret
            ,data_modifica = clock_timestamp()
       		,fl_elab='S'
      WHERE  reimputazione_id = movgestrec.reimputazione_id;



    END LOOP;

    -- bonifica eventuali scarti
    select * into cleanrec from fnc_fasi_bil_gest_reimputa_clean(  p_fasebilelabid ,enteproprietarioid );

	-- 15.02.2017 Sofia Sofia SIAC-4425
	if p_movgest_tipo_code=imp_movgest_tipo and cleanrec.codicerisultato =0 then
     -- insert N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
     -- essendo reimputazioni consideriamo solo mov.movgest_anno::integer>annoBilancio
     -- che non hanno ancora attributo
	 strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore N per impegni pluriennali.';
     INSERT INTO siac_r_movgest_ts_attr
	 (
	  movgest_ts_id,
	  attr_id,
	  boolean,
	  validita_inizio,
	  ente_proprietario_id,
	  login_operazione
	 )
	 select ts.movgest_ts_id,
	        flagFrazAttrId,
            'N',
		    dataInizioVal,
		    ts.ente_proprietario_id,
		    loginOperazione
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio)
     and   mov.movgest_anno::integer>annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   not exists (select 1 from siac_r_movgest_ts_attr r1
       		           where r1.movgest_ts_id=ts.movgest_ts_id
                       and   r1.attr_id=flagFrazAttrId
                       and   r1.data_cancellazione is null
                       and   r1.validita_fine is null);

     -- insert S per impegni mov.movgest_anno::integer=annoBilancio
     -- che non hanno ancora attributo
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore S per impegni di competenza senza atto amministrativo antecedente.';
	 INSERT INTO siac_r_movgest_ts_attr
	 (
	  movgest_ts_id,
	  attr_id,
	  boolean,
	  validita_inizio,
	  ente_proprietario_id,
	  login_operazione
	 )
	 select ts.movgest_ts_id,
	        flagFrazAttrId,
            'S',
	        dataInizioVal,
	        ts.ente_proprietario_id,
	        loginOperazione
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where mov.bil_id=bilancioId
	 and   mov.movgest_anno::integer=annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   not exists (select 1 from siac_r_movgest_ts_attr r1
       		           where r1.movgest_ts_id=ts.movgest_ts_id
                       and   r1.attr_id=flagFrazAttrId
                       and   r1.data_cancellazione is null
                       and   r1.validita_fine is null)
     and  not exists (select 1 from siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
					  where ra.movgest_ts_id=ts.movgest_ts_id
					  and   atto.attoamm_id=ra.attoamm_id
				 	  and   atto.attoamm_anno::integer < annoBilancio
		     		  and   ra.data_cancellazione is null
				      and   ra.validita_fine is null);

     -- aggiornamento N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
     -- essendo reimputazioni consideriamo solo mov.movgest_anno::integer>annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni pluriennali.';
	 update  siac_r_movgest_ts_attr r set boolean='N'
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where  mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<2017 or mov.movgest_anno::integer>2017)
	 and   mov.movgest_anno::integer>annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   r.movgest_ts_id=ts.movgest_ts_id
     and   r.attr_id=flagFrazAttrId
	 and   r.boolean='S'
     and   r.login_operazione=loginOperazione
     and   r.data_cancellazione is null
     and   r.validita_fine is null;

     -- aggiornamento N per impegni mov.movgest_anno::integer=annoBilancio e atto.attoamm_anno::integer < annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni di competenza con atto amministrativo antecedente.';
     update siac_r_movgest_ts_attr r set boolean='N'
  	 from siac_t_movgest mov, siac_t_movgest_ts ts,
	      siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
  	 where mov.bil_id=bilancioId
	 and   mov.movgest_anno::INTEGER=annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   r.movgest_ts_id=ts.movgest_ts_id
     and   r.attr_id=flagFrazAttrId
	 and   ra.movgest_ts_id=ts.movgest_ts_id
	 and   atto.attoamm_id=ra.attoamm_id
	 and   atto.attoamm_anno::integer < annoBilancio
	 and   r.boolean='S'
     and   r.login_operazione=loginOperazione
     and   r.data_cancellazione is null
     and   r.validita_fine is null
     and   ra.data_cancellazione is null
     and   ra.validita_fine is null;
    end if;
    -- 15.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile


    outfasebilelabretid:=p_fasebilelabid;
    if cleanrec.codicerisultato = -1 then
	    codicerisultato:=cleanrec.codicerisultato;
	    messaggiorisultato:=cleanrec.messaggiorisultato;
    else
	    codicerisultato:=0;
	    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||' FINE';
    end if;



    outfasebilelabretid:=p_fasebilelabid;
    codicerisultato:=0;
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||' FINE';
    RETURN;
  EXCEPTION
  WHEN raise_exception THEN
    RAISE notice '% % ERRORE : %',strmessaggiofinale,strmessaggio,substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'ERRORE :' ||' ' ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice ' % % Nessun elemento trovato.' ,strmessaggiofinale,strmessaggio;
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'Nessun elemento trovato.' ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE,substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'Errore DB ' ||SQLSTATE ||' ' ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  END;
  $body$ LANGUAGE 'plpgsql' volatile called ON NULL input security invoker cost 100;
  
-- SIAC-6788 - Sofia fine

-- SIAC-6791 - Maurizio INIZIO

DROP FUNCTION if exists siac."BILR052_quadro_generale_entrate"(p_ente_prop_id integer, p_anno varchar);
DROP FUNCTION if exists siac."BILR052_quadro_generale_spese"(p_ente_prop_id integer, p_anno varchar);

CREATE OR REPLACE FUNCTION siac."BILR052_quadro_generale_entrate" (
  p_ente_prop_id integer,
  p_anno varchar
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
  accertato numeric,
  incassato numeric
) AS
$body$
DECLARE
classifBilRec record;

annoCapImp varchar;
annoCapImp_int integer;
TipoImpstanz varchar;
tipoImpCassa varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:='';
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
v_fam_titolotipologiacategoria varchar:='00003';

BEGIN

annoCapImp:= p_anno;
annoCapImp_int:= p_anno::integer;

elemTipoCode:='CAP-EG'; -- tipo capitolo gestione

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

 RTN_MESSAGGIO:='lettura user table ''.';

select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='acquisizione struttura de bilancio ''.';

raise notice 'acquisizione struttura de bilancio';
raise notice 'ora: % ',clock_timestamp()::varchar;
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

--02/09/2016: cambiata la query che carica la struttura di bilancio
--  per motivi prestazionali
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


RTN_MESSAGGIO:='inserimento tabella di comodo dei capitoli ''.';
raise notice 'inserimento tabella di comodo dei capitoli ';

raise notice '2 - %' , clock_timestamp()::text;

/*  MA QUESTA QUERY A COSA SERVE????
 Ce ne sono 2 uguali.
  PER ORA QUESTA E' STATA TOLTA.

insert into siac_rep_cap_eg
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
and e.ente_proprietario_id			=	p_ente_prop_id
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
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy')
between rc.validita_inizio and COALESCE(rc.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy')
between r_cat_capitolo.validita_inizio and COALESCE(r_cat_capitolo.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'));

*/

 RTN_MESSAGGIO:='acquisizione capitoli di entrata gestione ''.';

 raise notice 'acquisizione capitoli di entrata gestione';
raise notice 'ora: % ',clock_timestamp()::varchar;

insert into siac_rep_cap_eg
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
and e.ente_proprietario_id			=	p_ente_prop_id
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
/*and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
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
*/
and rc.validita_fine is null
and stato_capitolo.validita_fine is null
and r_capitolo_stato.validita_fine is null
and r_cat_capitolo.validita_fine is null;
raise notice 'ora: % ',clock_timestamp()::varchar;

-----------------------------------------------------------------------------------------------------------------------------------
-------		ACQUISIZIONE DEGLI ACCERTAMENTI AFFERENTI L'ANNO DI ESERCIZIO COMPRESI I RESIDUI
-----------------------------------------------------------------------------------------------------------------------------------
  RTN_MESSAGGIO:='acquisizione degli accertamenti ''.';

  raise notice 'acquisizione degli accertamenti';
raise notice 'ora: % ',clock_timestamp()::varchar;

insert into siac_rep_accertamenti
select
r_mov_capitolo.elem_id,
sum (dt_movimento.movgest_ts_det_importo) importo,
p_ente_prop_id,
		user_table utente
    from
      siac_t_bil      bilancio,
      siac_t_periodo     anno_eserc,
      --siac_t_bil_elem     capitolo ,
      siac_r_movgest_bil_elem   r_mov_capitolo,
      --siac_d_bil_elem_tipo    t_capitolo,
      siac_t_movgest     movimento,
      siac_d_movgest_tipo    tipo_mov,
      siac_t_movgest_ts    ts_movimento,
      siac_r_movgest_ts_stato   r_movimento_stato,
      siac_d_movgest_stato    tipo_stato,
      siac_t_movgest_ts_det   dt_movimento,
      --siac_d_movgest_ts_tipo   ts_mov_tipo,
      -- 28.03.2018 Sofia HD-INC000002408655
      siac_d_movgest_ts_tipo   ts_mov_tipo,
      -- 28.03.2018 Sofia HD-INC000002408655
      siac_d_movgest_ts_det_tipo  dt_mov_tipo
      where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id
      and anno_eserc.anno       			=   p_anno
      and bilancio.bil_id      				=	movimento.bil_id
      --and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      --and t_capitolo.elem_tipo_code    		= 	elemTipoCode
      and movimento.movgest_anno	  		= 	annoCapImp_int
      and movimento.bil_id					=	bilancio.bil_id
      --and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id
      and tipo_mov.movgest_tipo_code    	= 'A'
      and movimento.movgest_id      		= 	ts_movimento.movgest_id
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N
      --and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id
      --and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
      -- 28.03.2018 Sofia HD-INC000002408655
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
      -- 28.03.2018 Sofia HD-INC000002408655
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale
      /*and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
      and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
      and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
      and	now() between t_capitolo.validita_inizio and coalesce (t_capitolo.validita_fine, now())
      and	now() between movimento.validita_inizio and coalesce (movimento.validita_fine, now())
      and	now() between ts_movimento.validita_inizio and coalesce (ts_movimento.validita_fine, now())
      */
      --and	now() between r_mov_capitolo.validita_inizio and coalesce (r_mov_capitolo.validita_fine, now())
      ---and	now() between r_movimento_stato.validita_inizio and coalesce (r_movimento_stato.validita_fine, now())
      --and capitolo.validita_fine is null
      --and t_capitolo.validita_fine is null
      and movimento.validita_fine is null
      and ts_movimento.validita_fine is null
      and anno_eserc.data_cancellazione    	is null
      and bilancio.data_cancellazione     	is null
      --and capitolo.data_cancellazione     	is null
      and r_mov_capitolo.data_cancellazione is null
      --and t_capitolo.data_cancellazione    	is null
      and movimento.data_cancellazione     	is null
      and tipo_mov.data_cancellazione     	is null
      and r_movimento_stato.data_cancellazione   is null
      and ts_movimento.data_cancellazione   is null
      and tipo_stato.data_cancellazione    	is null
      and dt_movimento.data_cancellazione   is null
      --and ts_mov_tipo.data_cancellazione    is null
      and dt_mov_tipo.data_cancellazione    is null
group by r_mov_capitolo.elem_id;

/*select 	tb2.elem_id,
		tb.importo,
		p_ente_prop_id,
		user_table utente
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
      --siac_d_movgest_ts_tipo   ts_mov_tipo,
      siac_d_movgest_ts_det_tipo  dt_mov_tipo
      where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id
      and anno_eserc.anno       			=   p_anno
      and bilancio.bil_id      				=	capitolo.bil_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and t_capitolo.elem_tipo_code    		= 	elemTipoCode
      and movimento.movgest_anno	  	= 	annoCapImp_int
      and movimento.bil_id					=	bilancio.bil_id
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id
      and tipo_mov.movgest_tipo_code    	= 'A'
      and movimento.movgest_id      		= 	ts_movimento.movgest_id
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N
      --and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id
      --and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale
      /*and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
      and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
      and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
      and	now() between t_capitolo.validita_inizio and coalesce (t_capitolo.validita_fine, now())
      and	now() between movimento.validita_inizio and coalesce (movimento.validita_fine, now())
      and	now() between ts_movimento.validita_inizio and coalesce (ts_movimento.validita_fine, now())
      */
      --and	now() between r_mov_capitolo.validita_inizio and coalesce (r_mov_capitolo.validita_fine, now())
      ---and	now() between r_movimento_stato.validita_inizio and coalesce (r_movimento_stato.validita_fine, now())
      and capitolo.validita_fine is null
      and t_capitolo.validita_fine is null
      and movimento.validita_fine is null
      and ts_movimento.validita_fine is null
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
      --and ts_mov_tipo.data_cancellazione    is null
      and dt_mov_tipo.data_cancellazione    is null
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id
group by capitolo.elem_id)
tb
,
(select * from  siac_t_bil_elem    			capitolo_eg,
      			siac_d_bil_elem_tipo    	t_capitolo_eg
      where capitolo_eg.elem_tipo_id		=	t_capitolo_eg.elem_tipo_id
      and 	t_capitolo_eg.elem_tipo_code 	= 	elemTipoCode) tb2
where
 tb2.elem_id	=	tb.elem_id;*/


raise notice 'ora: % ',clock_timestamp()::varchar;
-----------------------------------------------------------------------------------------------------------------------------------
-------		ACQUISIZIONE DEGLI INCASSI AFFERENTI L'ANNO DI ESERCIZIO COMPRESI I RESIDUI
-----------------------------------------------------------------------------------------------------------------------------------
  RTN_MESSAGGIO:='acquisizione degli incassi ''.';

raise notice 'acquisizione degli incassi';
raise notice 'ora: % ',clock_timestamp()::varchar;


insert into siac_rep_riscos_eg
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
		and	tipo_ordinativo.ord_tipo_code		= 	'I'		------ incasso
        and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
        and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
        ------------------------------------------------------------------------------------------
        ----------------------    LO STATO DEVE ESSERE MODIFICATO IN Q  --- QUIETANZATO    ------
        and	stato_ordinativo.ord_stato_code			<> 'A' ---
        -----------------------------------------------------------------------------------------------
        and	ordinativo.bil_id					=	bilancio.bil_id
        and	ordinativo.ord_id					=	ordinativo_det.ord_id
        and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
        and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
        and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' 	---- importo attuala
        ---------------------------------------------------------------------------------------------------------------------
        and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
        and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
        and	ts_movimento.movgest_id				=	movimento.movgest_id
        --and	movimento.movgest_anno				<=	annoCapImp_int
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
        /*and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between r_capitolo_ordinativo.validita_inizio and coalesce (r_capitolo_ordinativo.validita_fine, now())
        and	now() between r_stato_ordinativo.validita_inizio	and coalesce (r_stato_ordinativo.validita_fine, now())
        and	now() between r_ordinativo_movgest.validita_inizio	and coalesce (r_ordinativo_movgest.validita_fine, now())*/
        and r_capitolo_ordinativo.validita_fine is null
        and r_stato_ordinativo.validita_fine is null
        and r_ordinativo_movgest.validita_fine is null
        group by r_capitolo_ordinativo.elem_id,r_capitolo_ordinativo.ente_proprietario_id;



raise notice 'ora: % ',clock_timestamp()::varchar;



-----------------------------------------------------------------------------------------------------------------------------------
/*
insert into siac_rep_riscos_eg
select 	tb2.elem_id,
		tb.importo,
		p_ente_prop_id,
		user_table utente
from (select capitolo.elem_id,
            capitolo.ente_proprietario_id,
            user_table utente,
            sum(ordinativo_imp.ord_ts_det_importo) importo
from 		siac_t_bil_elem 				capitolo,
            siac_d_bil_elem_tipo 			tipo_elemento,
            siac_t_bil 						bilancio,
	 		siac_t_periodo 					anno_eserc,
			siac_d_bil_elem_stato 			stato_capitolo,
            siac_r_bil_elem_stato 			r_capitolo_stato,
			siac_d_bil_elem_categoria 		cat_del_capitolo,
            siac_r_bil_elem_categoria 		r_cat_capitolo,
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
    where 	capitolo.ente_proprietario_id 		= 	p_ente_prop_id
        and	anno_eserc.anno						= 	p_anno
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id
        and	capitolo.bil_id						=	bilancio.bil_id
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD'
        and	capitolo.elem_id					=	r_capitolo_ordinativo.elem_id
        and	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
        and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
		and	tipo_ordinativo.ord_tipo_code		= 	'I'		------ incasso
        and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
        and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
        ------------------------------------------------------------------------------------------
        ----------------------    AL MOMENTO VENGONO ESTRATTI QUEGLI INCASSI CON STATO DELL'ORDINATIVO DI INCASSO = I    ------
        -----------------------	DOVRA' ESSERE MODIFICATA IN MODO DA ACQUISIRE SOLO GLI INCASSI SULLE QUOTE (QUIETANZE) FATTE EFFETTIVAMENTE
        ----------------------	NELL'ANNO DI RIFERIMENTO DELL'ESERCIZIO AFFERENTE IL REPORT.
        ---------------------	AD OGGI (20/05/2015)QUESTO NON E' ANCORA DEFINITIVAMENTE ANALIZZATO, PERTANTO LA QUERY DOVRA' ESSERE AGGIORNATA.
        and	stato_ordinativo.ord_stato_code		=	'I' ---
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
        and	movimento.movgest_anno				<=	anno_eserc.anno::integer
        and movimento.bil_id					=	bilancio.bil_id
        --------------------------------------------------------------------------------------------------------------------
        and	capitolo.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione 			is null
        and	bilancio.data_cancellazione 				is null
        and	anno_eserc.data_cancellazione 				is null
        and	stato_capitolo.data_cancellazione 			is null
        and	r_capitolo_stato.data_cancellazione		 	is null
        and	cat_del_capitolo.data_cancellazione 		is null
        and	r_cat_capitolo.data_cancellazione 			is null
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
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
       group by capitolo.elem_id)
tb
,
(select * from  siac_t_bil_elem    			capitolo_eg,
      			siac_d_bil_elem_tipo    	t_capitolo_eg
      where capitolo_eg.elem_tipo_id		=	t_capitolo_eg.elem_tipo_id
      and 	t_capitolo_eg.elem_tipo_code 	= 	elemTipoCode) tb2
where
 tb2.elem_id	=	tb.elem_id;

*/


-----------------------------------------------------------------------------------------------------------------------------------
  RTN_MESSAGGIO:='preparazion dati in output ''.';
---------------------------------------------------------------------------------------------------------------------------------

raise notice 'preparazion dati in output';
raise notice 'ora: % ',clock_timestamp()::varchar;


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
		coalesce(tb1.accertamenti,0)	accertato,
  		COALESCE(tb2.riscossioni,0)		incassato
        --SIAC-6791: aggiunto il join sul valore user_table per le tabelle
        -- di appoggio.
from  	siac_rep_tit_tip_cat_riga_anni v1
			left  join siac_rep_cap_eg tb
           on    	(v1.categoria_id = tb.classif_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
                      left	join    siac_rep_accertamenti 	tb1  	
           		on (tb1.elem_id	=	tb.elem_id 	
                	and tb1.utente=user_table)
           left join	siac_rep_riscos_eg			tb2		
           		on (tb2.elem_id	=	tb.elem_id 	
                	and tb2.utente=user_table)
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
accertato:=classifBilRec.accertato;
incassato:=classifBilRec.incassato;

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
accertato=0;
incassato=0;



end loop;

raise notice 'fine  preparazion dati in output';
raise notice 'ora: % ',clock_timestamp()::varchar;


delete from siac_rep_tit_tip_cat_riga_anni 	where utente=user_table;

delete from siac_rep_cap_eg 				where utente=user_table;

delete from siac_rep_riscos_eg				where utente=user_table;

delete from	siac_rep_accertamenti			where utente=user_table;

raise notice 'dopo cancellazione table';
raise notice 'ora: % ',clock_timestamp()::varchar;

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

CREATE OR REPLACE FUNCTION siac."BILR052_quadro_generale_spese" (
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
  impegnato numeric,
  pagato numeric,
  fpv numeric
) AS
$body$
DECLARE

classifBilRec record;


annoCapImp varchar;
annoCapImp_int integer;
elemTipoCode varchar;

importo integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
TipoImpstanz		varchar;
v_fam_missioneprogramma varchar;
v_fam_titolomacroaggregato varchar;
p_anno_int 	   integer;


BEGIN

annoCapImp:= p_anno; 
annoCapImp_int:= p_anno::integer; 
elemTipoCode:='CAP-UG'; ------- capitolo di spesa gestione

TipoImpstanz='STA'; 	-- stanziamento

v_fam_missioneprogramma :='00001';
v_fam_titolomacroaggregato := '00002';
p_anno_int = p_anno::varchar;

RTN_MESSAGGIO:='lettura user table ''.';  

select fnc_siac_random_user()
into	user_table;


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

 RTN_MESSAGGIO:='acquisizione struttura de bilancio ''.';  
 
 raise notice 'acquisizione struttura de bilancio';
raise notice 'ora: % ',clock_timestamp()::varchar;
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
    , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 02/09/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;
 
 
raise notice 'ora: % ',clock_timestamp()::varchar;
 RTN_MESSAGGIO:='acquisizione capitoli di spesa gestione ''.';  


 raise notice 'acquisizione capitoli di spesa gestione';
raise notice 'ora: % ',clock_timestamp()::varchar;

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
    -- 02/09/2016: aggiunto FPVC
	cat_del_capitolo.elem_cat_code	in	('STD','FPV','FSC','FPVC')				-- ANNA 2206 FSC			
    /*
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
    */
    and r_capitolo_programma.validita_fine is null
    and r_capitolo_macroaggr.validita_fine is null
    and stato_capitolo.validita_fine is null
    and r_capitolo_stato.validita_fine is null
    and cat_del_capitolo.validita_fine is null
    and r_cat_capitolo.validita_fine is null
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

-- Aggiunto per gestire FPV INIZIO
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
		-- 02/09/2016: aggiunto FPVC
        and	cat_del_capitolo.elem_cat_code	in	('FPV','FPVC')								
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


insert into siac_rep_cap_ug_imp_riga
select  tb1.elem_id,      
    	0,
        coalesce (tb1.importo,0)   as fondo,
        0,
        tb1.ente_proprietario,
        user_table utente
from 	siac_rep_cap_ug_imp tb1
where	tb1.periodo_anno = annoCapImp		
and  	tb1.tipo_imp = TipoImpstanz
and     tb1.utente = user_table;

-- Aggiunto per gestire FPV FINE

-----------------------------------------------------------------------------------------------------------------------------------
-------		ACQUISIZIONE DEGLI IMPEGNI AFFERENTI L'ANNO DI ESERCIZIO COMPRESI I RESIDUI
-----------------------------------------------------------------------------------------------------------------------------------
  RTN_MESSAGGIO:='acquisizione degli impegni ''.';   
----------------------------------------------------------------------------------------------------------

raise notice 'acquisizione degli impegni';
raise notice 'ora: % ',clock_timestamp()::varchar;

insert into siac_rep_impegni
select    
		r_mov_capitolo.elem_id,
		p_anno,
		p_ente_prop_id,
		user_table utente,
sum (dt_movimento.movgest_ts_det_importo) importo
    from 
      siac_t_bil      bilancio, 
      siac_t_periodo     anno_eserc, 
      --siac_t_bil_elem     capitolo , 
      siac_r_movgest_bil_elem   r_mov_capitolo, 
      --siac_d_bil_elem_tipo    t_capitolo, 
      siac_t_movgest     movimento, 
      siac_d_movgest_tipo    tipo_mov, 
      siac_t_movgest_ts    ts_movimento, 
      siac_r_movgest_ts_stato   r_movimento_stato, 
      siac_d_movgest_stato    tipo_stato, 
      siac_t_movgest_ts_det   dt_movimento, 
      --siac_d_movgest_ts_tipo   ts_mov_tipo, 
      siac_d_movgest_ts_det_tipo  dt_mov_tipo 
      where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id
      and anno_eserc.anno       			=   p_anno 
      and bilancio.bil_id      				=	movimento.bil_id
      --and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      --and t_capitolo.elem_tipo_code    		= 	elemTipoCode
      --and movimento.movgest_anno ::text  	= 	p_anno
      and movimento.movgest_anno = p_anno_int
      and movimento.bil_id					=	bilancio.bil_id
      --and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and tipo_mov.movgest_tipo_code    	= 'I' 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      -- D= DEFINITIVO, N= DEFINITIVO NON LIQUIDABILE
      -- P=PROVVISORIO, A= ANNULLATO
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      --and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      --and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
      and ts_movimento.movgest_ts_id_padre is null
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      /*and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
      and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
      and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
      and	now() between t_capitolo.validita_inizio and coalesce (t_capitolo.validita_fine, now())
      and	now() between movimento.validita_inizio and coalesce (movimento.validita_fine, now())
      and	now() between ts_movimento.validita_inizio and coalesce (ts_movimento.validita_fine, now())
      and	now() between r_mov_capitolo.validita_inizio and coalesce (r_mov_capitolo.validita_fine, now())
      and	now() between r_movimento_stato.validita_inizio and coalesce (r_movimento_stato.validita_fine, now())
      */
      --and capitolo.validita_fine is null
      --and t_capitolo.validita_fine is null
      and movimento.validita_fine is null
      and ts_movimento.validita_fine is null
      and r_mov_capitolo.validita_fine is null
      and r_movimento_stato.validita_fine is null
      and anno_eserc.data_cancellazione    	is null 
      and bilancio.data_cancellazione     	is null 
      --and capitolo.data_cancellazione     	is null 
      and r_mov_capitolo.data_cancellazione is null 
      --and t_capitolo.data_cancellazione    	is null 
      and movimento.data_cancellazione     	is null 
      and tipo_mov.data_cancellazione     	is null 
      and r_movimento_stato.data_cancellazione   is null 
      and ts_movimento.data_cancellazione   is null 
      and tipo_stato.data_cancellazione    	is null 
      and dt_movimento.data_cancellazione   is null 
      --and ts_mov_tipo.data_cancellazione    is null 
      and dt_mov_tipo.data_cancellazione    is null
group by r_mov_capitolo.elem_id;
/*
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
      --siac_d_movgest_ts_tipo   ts_mov_tipo, 
      siac_d_movgest_ts_det_tipo  dt_mov_tipo 
      where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id
      and anno_eserc.anno       			=   p_anno 
      and bilancio.bil_id      				=	capitolo.bil_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and t_capitolo.elem_tipo_code    		= 	elemTipoCode
      --and movimento.movgest_anno ::text  	= 	p_anno
      and movimento.movgest_anno = p_anno_int
      and movimento.bil_id					=	bilancio.bil_id
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and tipo_mov.movgest_tipo_code    	= 'I' 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      -- D= DEFINITIVO, N= DEFINITIVO NON LIQUIDABILE
      -- P=PROVVISORIO, A= ANNULLATO
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      --and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      --and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
      and ts_movimento.movgest_ts_id_padre is null
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      /*and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
      and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
      and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
      and	now() between t_capitolo.validita_inizio and coalesce (t_capitolo.validita_fine, now())
      and	now() between movimento.validita_inizio and coalesce (movimento.validita_fine, now())
      and	now() between ts_movimento.validita_inizio and coalesce (ts_movimento.validita_fine, now())
      and	now() between r_mov_capitolo.validita_inizio and coalesce (r_mov_capitolo.validita_fine, now())
      and	now() between r_movimento_stato.validita_inizio and coalesce (r_movimento_stato.validita_fine, now())
      */
      and capitolo.validita_fine is null
      and t_capitolo.validita_fine is null
      and movimento.validita_fine is null
      and ts_movimento.validita_fine is null
      and r_mov_capitolo.validita_fine is null
      and r_movimento_stato.validita_fine is null
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
      --and ts_mov_tipo.data_cancellazione    is null 
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
*/
/*




insert into siac_rep_impegni
select tb2.elem_id,
0,
p_ente_prop_id,
user_table utente,
tb.importo 
from (
select    
capitolo.elem_id,
sum (dt_movimento.movgest_ts_det_importo) importo
    from 
      siac_t_bil      				bilancio, 
      siac_t_periodo     			anno_eserc, 
      siac_t_bil_elem     			capitolo , 
      siac_r_movgest_bil_elem   	r_mov_capitolo, 
      siac_d_bil_elem_tipo    		t_capitolo, 
      siac_t_movgest     			movimento, 
      siac_d_movgest_tipo    		tipo_mov, 
      siac_t_movgest_ts    			ts_movimento, 
      siac_r_movgest_ts_stato   	r_movimento_stato, 
      siac_d_movgest_stato    		tipo_stato, 
      siac_t_movgest_ts_det   		dt_movimento, 
      siac_d_movgest_ts_tipo   		ts_mov_tipo, 
      siac_d_movgest_ts_det_tipo  	dt_mov_tipo 
      where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
      -------and anno_eserc.anno       			=   '2015' 
      and anno_eserc.anno       			=   p_anno 
      and bilancio.bil_id      				=	capitolo.bil_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and t_capitolo.elem_tipo_code    		= 	elemTipoCode
      --------      and t_capitolo.elem_tipo_code    		= 	'CAP-UG'
      and movimento.movgest_anno   	<= annoCapImp_int
      ------------ and movimento.movgest_anno   	<= 	2015
      and movimento.bil_id					=	bilancio.bil_id
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and tipo_mov.movgest_tipo_code    	= 'I' 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
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
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id
group by capitolo.elem_id)
tb 
,
(select * from  siac_t_bil_elem    			capitolo_ug,
      			siac_d_bil_elem_tipo    	t_capitolo_ug
      where capitolo_ug.elem_tipo_id		=	t_capitolo_ug.elem_tipo_id 
      and 	t_capitolo_ug.elem_tipo_code 	= 	elemTipoCode) tb2
where
 tb2.elem_id	=	tb.elem_id;
 
*/
/*
 
 insert into siac_rep_impegni
select tb2.elem_id,
0,
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
      and anno_eserc.anno       			=   p_anno 
      and bilancio.bil_id      				=	capitolo.bil_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and t_capitolo.elem_tipo_code    		= 	elemTipoCode
      and movimento.movgest_anno 		  	<= 	annoCapImp_int
      and movimento.bil_id					=	bilancio.bil_id
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and tipo_mov.movgest_tipo_code    	= 'I' 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
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
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id
group by capitolo.elem_id)
tb 
,
(select * from  siac_t_bil_elem    			capitolo_ug,
      			siac_d_bil_elem_tipo    	t_capitolo_ug
      where capitolo_ug.elem_tipo_id		=	t_capitolo_ug.elem_tipo_id 
      and 	t_capitolo_ug.elem_tipo_code 	= 	elemTipoCode) tb2
where
 tb2.elem_id	=	tb.elem_id;

 */

raise notice 'ora: % ',clock_timestamp()::varchar;

-----------------------------------------------------------------------------------------------------------------------------------
-------		ACQUISIZIONE DEGI PAGAMENTI AFFERENTI L'ANNO DI ESERCIZIO COMPRESI I RESIDUI
-----------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------
  RTN_MESSAGGIO:='acquisizione DEI PAGAMENTI ''.';  
 

raise notice 'acquisizione DEI PAGAMENTI';
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
            siac_r_liquidazione_movgest     r_liqmovgest,
            siac_r_liquidazione_ord         r_liqord     
    where 	anno_eserc.anno						= 	p_anno											
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id
        and	bilancio.ente_proprietario_id	=	p_ente_prop_id
        and	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
        and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
		and	tipo_ordinativo.ord_tipo_code		= 	'P'		------ PAGATO
        and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
        and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
        ------------------------------------------------------------------------------------------		
        ----------------------    si prendono gli stati Q, F, T
        ----------------------	  da verificare se e' giusto.
        -- Q= QUIETANZATO, F= FIRMATO, T= TRASMESSO
        -- I= INSERITO, A= ANNULLATO
        and	stato_ordinativo.ord_stato_code		<>'A' --- 
        -----------------------------------------------------------------------------------------------
        and	ordinativo.bil_id					=	bilancio.bil_id
        and	ordinativo.ord_id					=	ordinativo_det.ord_id
        and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
        and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
        and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' 	---- importo attuale
        ---------------------------------------------------------------------------------------------------------------------
        and r_liqord.sord_id                    =   ordinativo_det.ord_ts_id
        and	r_liqord.liq_id		                =	r_liqmovgest.liq_id
        and	r_liqmovgest.movgest_ts_id	        =	ts_movimento.movgest_ts_id
        and	ts_movimento.movgest_id				=	movimento.movgest_id
        --and	movimento.movgest_anno				<=	annoCapImp_int	
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
        and	r_liqord.data_cancellazione		            is null
        and	r_liqmovgest.data_cancellazione		        is null
        /*and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between r_capitolo_ordinativo.validita_inizio and coalesce (r_capitolo_ordinativo.validita_fine, now())
        and	now() between r_stato_ordinativo.validita_inizio and coalesce (r_stato_ordinativo.validita_fine, now())
        and	now() between r_liqord.validita_inizio and coalesce (r_liqord.validita_fine, now())
        and	now() between r_liqmovgest.validita_inizio and coalesce (r_liqmovgest.validita_fine, now())*/
        and r_capitolo_ordinativo.validita_fine is null
        and r_stato_ordinativo.validita_fine is null
        and r_liqord.validita_fine is null
        and r_liqmovgest.validita_fine is null
        group by r_capitolo_ordinativo.elem_id,r_capitolo_ordinativo.ente_proprietario_id;
        



raise notice 'ora: % ',clock_timestamp()::varchar;



 
/*

insert into siac_rep_pagam_ug
select 	tb2.elem_id,
		tb.importo,
		p_ente_prop_id,
		user_table utente
from (select 	capitolo.elem_id,
            	capitolo.ente_proprietario_id,
            	user_table utente,
            	sum(ordinativo_imp.ord_ts_det_importo) importo
from 		siac_t_bil_elem 				capitolo,
            siac_d_bil_elem_tipo 			tipo_elemento,
            siac_t_bil 						bilancio,
	 		siac_t_periodo 					anno_eserc, 
			siac_d_bil_elem_stato 			stato_capitolo, 
            siac_r_bil_elem_stato 			r_capitolo_stato,
			siac_d_bil_elem_categoria 		cat_del_capitolo, 
            siac_r_bil_elem_categoria 		r_cat_capitolo,
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
    where 	capitolo.ente_proprietario_id 		= 	p_ente_prop_id 
        and	anno_eserc.anno						= 	p_anno											
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD'
        and	capitolo.elem_id					=	r_capitolo_ordinativo.elem_id
        and	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
        and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
		and	tipo_ordinativo.ord_tipo_code		= 	'P'		------ Pagamento
        and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
        and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
        ------------------------------------------------------------------------------------------		
        ----------------------    AL MOMENTO VENGONO ESTRATTI I PAGAMENTI CON STATO DELL'ORDINATIVO DI PAGAMENTO = I    ------
        -----------------------	DOVRA' ESSERE MODIFICATA IN MODO DA ACQUISIRE SOLO I PAGAMENTI SULLE QUOTE (QUIETANZE) FATTE EFFETTIVAMENTE 
        ----------------------	NELL'ANNO DI RIFERIMENTO DELL'ESERCIZIO AFFERENTE IL REPORT.
        ---------------------	AD OGGI (20/05/2015)QUESTO NON E' ANCORA DEFINITIVAMENTE ANALIZZATO, PERTANTO LA QUERY DOVRA' ESSERE AGGIORNATA.
        and	stato_ordinativo.ord_stato_code		=	'I' --- 
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
        and	movimento.movgest_anno				<=	annoCapImp_int
        and movimento.bil_id					=	bilancio.bil_id	
        --------------------------------------------------------------------------------------------------------------------		
        and	capitolo.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione 			is null
        and	bilancio.data_cancellazione 				is null
        and	anno_eserc.data_cancellazione 				is null
        and	stato_capitolo.data_cancellazione 			is null
        and	r_capitolo_stato.data_cancellazione		 	is null
        and	cat_del_capitolo.data_cancellazione 		is null
        and	r_cat_capitolo.data_cancellazione 			is null
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
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
       group by capitolo.elem_id)
tb 
,
(select * from  siac_t_bil_elem    			capitolo_ug,
      			siac_d_bil_elem_tipo    	t_capitolo_ug
      where capitolo_ug.elem_tipo_id		=	t_capitolo_ug.elem_tipo_id 
      and 	t_capitolo_ug.elem_tipo_code 	= 	elemTipoCode) tb2
where
 tb2.elem_id	=	tb.elem_id;
 
*/
------------------------------------------------------------------------------------------------------------
-------------  MANCA LA QUERY PER ACQUISIRE L'IMPORTO DEL FONDO PLURIENNALE VINCOLATO
-------------
-------------	DA INSERIRE------ CAPIRE COME FARE..
------------------------------------------------------------------------------------------------------------


  RTN_MESSAGGIO:='preparazion dati in output ''.';  

raise notice 'preparazion dati in output';
raise notice 'ora: % ',clock_timestamp()::varchar;

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
    	t2.bil_anno 			BIL_ANNO,
        t2.elem_code     		BIL_ELE_CODE,
        t2.elem_code2     		BIL_ELE_CODE2,
        t2.elem_code3			BIL_ELE_CODE3,
		t2.elem_desc     		BIL_ELE_DESC,
        t2.elem_desc2     		BIL_ELE_DESC2,
        t2.elem_id      		BIL_ELE_ID,
       	t2.elem_id_padre 		BIL_ELE_ID_PADRE, 
        coalesce(t3.importo,0)				impegnato,
        coalesce(t4.pagamenti_competenza,0)	pagato,
        coalesce (t5.previsioni_definitive_comp,0)   as fondo 
        --SIAC-6791: aggiunto il join sul valore user_table per le tabelle
        -- di appoggio.
from siac_rep_mis_pro_tit_mac_riga_anni t1
        left join siac_rep_cap_ug  t2
        on (t1.programma_id = t2.programma_id    
           			and	t1.macroag_id	= t2.macroaggregato_id
           			and t1.ente_proprietario_id=p_ente_prop_id
					AND t1.utente=t2.utente
                    and t1.utente=user_table)
        left join 	siac_rep_impegni 	t3	
        	on (t3.elem_id	=	t2.elem_id
            	and t3.utente=user_table)
        left join	siac_rep_pagam_ug	t4	
        	on (t4.elem_id	=	t2.elem_id
            	and t4.utente=user_table)
        left join   siac_rep_cap_ug_imp_riga    t5      
        	on (t5.elem_id	=	t2.elem_id 
             	and t5.utente=user_table) 
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
impegnato:=classifBilRec.impegnato;
pagato:=classifBilRec.pagato;
fpv:=classifBilRec.fondo;
----------fpv:=300;
  		 
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
impegnato=0;
pagato=0;
fpv=0;

end loop;

raise notice 'fine preparazion dati in output';
raise notice 'ora: % ',clock_timestamp()::varchar;

delete from siac_rep_mis_pro_tit_mac_riga_anni 	where utente=user_table;
delete from siac_rep_cap_ug 					where utente=user_table;
delete from siac_rep_impegni 					where utente=user_table;
delete from siac_rep_pagam_ug  					where utente=user_table;

delete from siac_rep_cap_ug_imp  				where utente=user_table;
delete from siac_rep_cap_ug_imp_riga  			where utente=user_table;


raise notice 'fine OK';
raise notice 'fine cancellazione table';
raise notice 'ora: % ',clock_timestamp()::varchar;
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

-- SIAC-6791 - Maurizio FINE


---- 07.05.2019 Sofia Elisa 

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
v_stato_sdi VARCHAR(2) := null; -- SIAC-6565
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
       case when ts.subdoc_pagato_cec = FALSE then 'f' when ts.subdoc_pagato_cec = TRUE then 't' end subdoc_pagato_cec,
       ts.subdoc_data_pagamento_cec,
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
        data_riattiva_atto_allegato,
        stato_sdi -- SIAC-6565 07.05.2019 SofiaElisa
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
	          v_data_riattiva_atto_allegato,
              v_stato_sdi -- SIAC-6565 07.05.2019 SofiaElisa
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
---- 07.05.2019 Sofia Elisa  - fine 

--- 05.06.2019 Sofia SIAC-6893 - patch - inizio 

drop FUNCTION is exists fnc_pagopa_t_elaborazione_riconc_esegui
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
);

CREATE OR REPLACE FUNCTION fnc_pagopa_t_elaborazione_riconc_esegui
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioBck VARCHAR(1500):='';
    strMessaggioLog VARCHAR(2500):='';

	strMessaggioFinale VARCHAR(1500):='';
    strErrore  VARCHAR(1500):='';
    pagoPaCodeErr varchar(50):='';
	codResult integer:=null;
    codResult1 integer:=null;
    docid integer:=null;
    subDocId integer:=null;
    nProgressivo integer=null;

    -- stati ammessi per procedere con elaborazione
    -- file XML caricato correttamente pronto x elaborazione
	ACQUISITO_ST              CONSTANT  varchar :='ACQUISITO';
    -- file XML caricato correttamente, elaborazione in corso, flussi in fase di elaborazione
    ELABORATO_IN_CORSO_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO'; -- senza errori  e scarti
    ELABORATO_IN_CORSO_ER_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_ER';  -- con errori
    ELABORATO_IN_CORSO_SC_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_SC'; -- con scarti
    -- stati ammessi per procedere con elaborazione


    -- stati per chiusura con errore
    ELABORATO_SCARTATO_ST     CONSTANT  varchar :='ELABORATO_SCARTATO';
    ELABORATO_ERRATO_ST       CONSTANT  varchar :='ELABORATO_ERRATO';
    ANNULLATO_ST              CONSTANT  varchar :='ANNULLATO';
	RIFIUTATO_ST              CONSTANT  varchar :='RIFIUTATO';
    -- stati per chiusura con errore

    -- stati per chiusura con successo con o senza scarti
    -- file XML caricato, ELABORAZIONE TERMINATA E CONCLUSA
    ELABORATO_OK_ST           CONSTANT  varchar :='ELABORATO_OK'; -- documenti  emessi
    ELABORATO_KO_ST           CONSTANT  varchar :='ELABORATO_KO'; -- documenti emessi - presenza di errori-scarti
    -- stati per chiusura con successo con o senza scarti

	ESERCIZIO_PROVVISORIO_ST CONSTANT  varchar :='E'; -- esercizio provvisorio
    ESERCIZIO_GESTIONE_ST    CONSTANT  varchar :='G'; -- esercizio gestione

	-- errori di elaborazione su dettagli
	PAGOPA_ERR_1	CONSTANT  varchar :='1'; --ANNULLATO
	PAGOPA_ERR_2	CONSTANT  varchar :='2'; --SCARTATO
	PAGOPA_ERR_3	CONSTANT  varchar :='3'; --ERRORE GENERICO
	PAGOPA_ERR_4	CONSTANT  varchar :='4'; --FILE NON ESISTENTE O STATO NON RICHIESTO
	PAGOPA_ERR_5	CONSTANT  varchar :='5'; --FILE CARICATO DIVERSE VOLTE PER filepagopaFileXMLId
	PAGOPA_ERR_6	CONSTANT  varchar :='6'; --DATI DI RICONCILIAZIONE NON PRESENTI
	PAGOPA_ERR_7	CONSTANT  varchar :='7'; --DATI DI RICONCILIAZIONE DA ELABORARE NON PRESENTI
	PAGOPA_ERR_8	CONSTANT  varchar :='8'; --DATI DI RICONCILIAZIONE NON PRESENTI PER filepagopaFileXMLId
	PAGOPA_ERR_9	CONSTANT  varchar :='9'; --DATI DI RICONCILIAZIONE PRESENTI PER DIVERSO FILE E STESSO filepagopaFileXMLId
	PAGOPA_ERR_10	CONSTANT  varchar :='10';--DATI DI RICONCILIAZIONE ASSOCIATI A DIVERSI VALORI DI ANNO ESERCIZIO
	PAGOPA_ERR_11	CONSTANT  varchar :='11';--DATI DI RICONCILIAZIONE ASSOCIATI A ANNO ESERCIZIO SUCCESSIVO A ANNO BILANCIO
	PAGOPA_ERR_12	CONSTANT  varchar :='12';--DATI DI RICONCILIAZIONE SENZA ANNO ESERCIZIO INDICATO
	PAGOPA_ERR_13	CONSTANT  varchar :='13';--DATI DI RICONCILIAZIONE SENZA ESTREMI PROVVISORIO DI CASSA
	PAGOPA_ERR_14	CONSTANT  varchar :='14';--DATI DI RICONCILIAZIONE SENZA ESTREMI ACCERTAMENTO
	PAGOPA_ERR_15	CONSTANT  varchar :='15';--DATI DI RICONCILIAZIONE SENZA ESTREMI VOCE/SOTTOVOCE
	PAGOPA_ERR_16	CONSTANT  varchar :='16';--DATI DI RICONCILIAZIONE SENZA IMPORTO
	PAGOPA_ERR_17	CONSTANT  varchar :='17';--ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FILE
	PAGOPA_ERR_18	CONSTANT  varchar :='18';--ANNO BILANCIO DI ELABORAZIONE NON ESISTENTE O FASE NON AMMESSA
	PAGOPA_ERR_19	CONSTANT  varchar :='19';--ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FLUSSO DI RICONCILIAZIONE
	PAGOPA_ERR_20	CONSTANT  varchar :='20';--DATI DI ELABORAZIONE NON ESISTENTI O IN STATO NON AMMESSO
	PAGOPA_ERR_21	CONSTANT  varchar :='21';--ERRORE IN INSERIMENTO DATI DI DETTAGLIO ELABORAZIONE FLUSSO DI RICONCILIAZIONE
	PAGOPA_ERR_22	CONSTANT  varchar :='22';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA NON ESISTENTE
	PAGOPA_ERR_23	CONSTANT  varchar :='23';--DATI DI RICONCILIAZIONE ASSOCIATI A ACCERTAMENTO NON ESISTENTE
  	PAGOPA_ERR_24	CONSTANT  varchar :='24';--TIPO DOCUMENTO IPA NON ESISTENTE
    PAGOPA_ERR_25   CONSTANT  varchar :='25';--BOLLO ESENTE NON ESISTENTE
    PAGOPA_ERR_26   CONSTANT  varchar :='26';--STATO VALIDO DOCUMENTO NON ESISTENTE
    PAGOPA_ERR_27   CONSTANT  varchar :='27';--IDENTIFICATIVO CDC/CDR NON ESISTENTE
    PAGOPA_ERR_28   CONSTANT  varchar :='28';--IDENTIFICATIVO TIPO QUOTA DOCUMENTO NON ESISTENTE
    PAGOPA_ERR_29   CONSTANT  varchar :='29';--IDENTIFICATIVI VARI INESISTENTI
    PAGOPA_ERR_30   CONSTANT  varchar :='30';--ERRORE IN FASE DI INSERIMENTO DOCUMENTO
    PAGOPA_ERR_31   CONSTANT  varchar :='31';--ERRORE IN FASE DI ADEGUAMENTO IMPORTO ACCERTAMENTO
    PAGOPA_ERR_32   CONSTANT  varchar :='32';--ERRORE IN FASE DI VERIFICA DISPONIBILITA PROVVOSORIO DI CASSA
    PAGOPA_ERR_33   CONSTANT  varchar :='33';--DISPONIBILITA INSUFFICIENTE PER PROVVOSORIO DI CASSA
    PAGOPA_ERR_34   CONSTANT  varchar :='34';--DATI DI RICONCILIAZIONE ASSOCIATI A SOGGETTO NON ESISTENTE
    PAGOPA_ERR_35   CONSTANT  varchar :='35';--DATI DI RICONCILIAZIONE ASSOCIATI A STRUTTURA AMMINISTRATIVA NON ESISTENTE

    PAGOPA_ERR_36   CONSTANT  varchar :='36';--DATI DI RICONCILIAZIONE SCARTATI PER ANOMALIA SU GENERAZIONE DOC. PER PROV. CASSA

    PAGOPA_ERR_37   CONSTANT  varchar :='37';--ERRORE IN LETTURA PROGRESSIVI DOCUMENTI
    PAGOPA_ERR_38   CONSTANT  varchar :='38';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA REGOLARIZZATO
    PAGOPA_ERR_39   CONSTANT  varchar :='39';--PROVVISORIO DI CASSA REGOLARIZZATO

    DOC_STATO_VALIDO    CONSTANT  varchar :='V';
	DOC_TIPO_IPA    CONSTANT  varchar :='IPA';

    -- attributi siac_t_doc
	ANNO_REPERTORIO_ATTR CONSTANT varchar:='anno_repertorio';
	NUM_REPERTORIO_ATTR CONSTANT varchar:='num_repertorio';
	DATA_REPERTORIO_ATTR CONSTANT varchar:='data_repertorio';
	REG_REPERTORIO_ATTR CONSTANT varchar:='registro_repertorio';
	ARROTONDAMENTO_ATTR CONSTANT varchar:='arrotondamento';

	CAUS_SOSPENSIONE_ATTR CONSTANT varchar:='causale_sospensione';
	DATA_SOSPENSIONE_ATTR CONSTANT varchar:='data_sospensione';
    DATA_RIATTIVAZIONE_ATTR CONSTANT varchar:='data_riattivazione';
    DATA_SCAD_SOSP_ATTR CONSTANT varchar:='dataScadenzaDopoSospensione';
    TERMINE_PAG_ATTR CONSTANT varchar:='terminepagamento';
    NOTE_PAG_INC_ATTR CONSTANT varchar:='notePagamentoIncasso';
    DATA_PAG_INC_ATTR CONSTANT varchar:='dataOperazionePagamentoIncasso';

	FL_AGG_QUOTE_ELE_ATTR CONSTANT varchar:='flagAggiornaQuoteDaElenco';
    FL_SENZA_NUM_ATTR CONSTANT varchar:='flagSenzaNumero';
    FL_REG_RES_ATTR CONSTANT varchar:='flagDisabilitaRegistrazioneResidui';
    FL_PAGATA_INC_ATTR CONSTANT varchar:='flagPagataIncassata';
    COD_FISC_PIGN_ATTR CONSTANT varchar:='codiceFiscalePignorato';
    DATA_RIC_PORTALE_ATTR CONSTANT varchar:='dataRicezionePortale';

	FL_AVVISO_ATTR	 CONSTANT varchar:='flagAvviso';
    FL_ESPROPRIO_ATTR	 CONSTANT varchar:='flagEsproprio';
    FL_ORD_MANUALE_ATTR	 CONSTANT varchar:='flagOrdinativoManuale';
    FL_ORD_SINGOLO_ATTR	 CONSTANT varchar:='flagOrdinativoSingolo';
    FL_RIL_IVA_ATTR	 CONSTANT varchar:='flagRilevanteIVA';

    CAUS_ORDIN_ATTR	 CONSTANT varchar:='causaleOrdinativo';
    DATA_ESEC_PAG_ATTR	 CONSTANT varchar:='dataEsecuzionePagamento';


    TERMINE_PAG_DEF  CONSTANT integer=30;

    provvisorioId integer:=null;
    bilancioId integer:=null;
    periodoId integer:=null;

    filePagoPaId                    integer:=null;
    filePagoPaFileXMLId             varchar:=null;

    bElabora boolean:=true;
    bErrore boolean:=false;

    docTipoId integer:=null;
    codBolloId integer:=null;
    dDocImporto numeric:=null;
    dispAccertamento numeric:=null;
	dispProvvisorioCassa numeric:=null;

    strElencoFlussi varchar:=null;
    docStatoValId   integer:=null;
    cdrTipoId integer:=null;
    cdcTipoId integer:=null;
    subDocTipoId integer:=null;
	movgestTipoId  integer:=null;
    movgestTsTipoId integer:=null;
    movgestStatoId integer:=null;
    provvisorioTipoId integer:=null;
	movgestTsDetTipoId integer:=null;
	dnumQuote integer:=0;
    movgestTsId integer:=null;
    subdocMovgestTsId integer:=null;

    annoBilancio integer:=null;

    fncRec record;
    pagoPaFlussoRec record;
    pagoPaFlussoQuoteRec record;
    elabRec record;

BEGIN

	strMessaggioFinale:='Elaborazione rinconciliazione PAGOPA per '||
                        'Id. elaborazione filePagoPaElabId='||filePagoPaElabId::varchar||
                        ' AnnoBilancioElab='||annoBilancioElab::varchar||'.';

    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale;
	insert into pagopa_t_elaborazione_log
    (
     pagopa_elab_id,
     pagopa_elab_file_id,
     pagopa_elab_log_operazione,
     ente_proprietario_id,
     login_operazione,
     data_creazione
    )
    values
    (
     filePagoPaElabId,
     null,
     strMessaggioLog,
	 enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );

    codiceRisultato:=0;
    messaggioRisultato:='';


    strMessaggio:='Verifica esistenza elaborazione.';
    --select elab.file_pagopa_id, elab.pagopa_elab_file_id into filePagoPaId, filePagoPaFileXMLId
    select 1 into codResult
    from pagopa_t_elaborazione elab, pagopa_d_elaborazione_stato stato
    where elab.pagopa_elab_id=filePagoPaElabId
    and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
    and   stato.pagopa_elab_stato_code in (ELABORATO_IN_CORSO_ST, ELABORATO_IN_CORSO_ER_ST,ELABORATO_IN_CORSO_SC_ST)
    and   stato.ente_proprietario_id=enteProprietarioId
    and   elab.data_cancellazione is null
    and   elab.validita_fine  is null;

--	if filePagoPaId is null or filePagoPaFileXMLId is null then
    if codResult is null then
        pagoPaCodeErr:=PAGOPA_ERR_20;
        strErrore:=' Non esistente.';
        codResult:=-1;
        bElabora:=false;
    else codResult:=null;
    end if;

/*  elaborazioni multi file
    if codResult is null then
     strMessaggio:='Verifica esistenza file di elaborazione per filePagoPaId='||filePagoPaId::varchar||
                   ' filePagoPaFileXMLId='||filePagoPaFileXMLId||'.';
     select 1 into codResult
     from siac_t_file_pagopa file, siac_d_file_pagopa_stato stato
     where file.file_pagopa_id=filePagoPaId
     and   file.file_pagopa_code=filePagoPaFileXMLId
     and   stato.file_pagopa_stato_id=file.file_pagopa_stato_id
     and   stato.file_pagopa_stato_code in (ELABORATO_IN_CORSO_ST, ELABORATO_IN_CORSO_ER_ST,ELABORATO_IN_CORSO_SC_ST)
     and   stato.ente_proprietario_id=enteProprietarioId
     and   file.data_cancellazione is null
     and   file.validita_fine  is null;

     if codResult is null then
    	pagoPaCodeErr:=PAGOPA_ERR_4;
        strErrore:=' Non esistente.';
        codResult:=-1;
        bElabora:=false;
     else codResult:=null;
     end if;
    end if;
*/


   if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_IPA||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoId
      from siac_d_doc_tipo tipo
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_IPA;
      if docTipoId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      end if;
   end if;


   if codResult is null then
    	strMessaggio:='Lettura identificativo bollo esente.';
    	-- lettura tipodocumento
		select cod.codbollo_id into codBolloId
		from siac_d_codicebollo cod
		where cod.ente_proprietario_id=enteProprietarioId
		and   cod.codbollo_desc='ESENTE BOLLO';
        if codBolloId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_25;
    	    strErrore:=' Non riuscita.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;


   if codResult is null then
    	strMessaggio:='Lettura identificativo documento stato='||DOC_STATO_VALIDO||'.';
		select stato.doc_stato_id into docStatoValId
		from siac_d_doc_stato Stato
		where stato.ente_proprietario_id=enteProprietarioId
		and   stato.doc_stato_code=DOC_STATO_VALIDO;
        if docTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_26;
    	    strErrore:=' Non riuscita.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

    if codResult is null then
    	strMessaggio:='Lettura identificativo tipo CDC.';
		select tipo.classif_tipo_id into cdcTipoId
		from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code='CDC';
        if cdcTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_27;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo CDR.';
		select tipo.classif_tipo_id into cdrTipoId
		from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code='CDR';
        if cdrTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_27;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;


	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo subdocumento SE.';
		select tipo.subdoc_tipo_id into subDocTipoId
		from siac_d_subdoc_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.subdoc_tipo_code='SE';
        if subDocTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_28;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo accertamento.';
		select tipo.movgest_tipo_id into movgestTipoId
		from siac_d_movgest_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_tipo_code='A';
        if movgestTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo testata accertamento.';
		select tipo.movgest_ts_tipo_id into movgestTsTipoId
		from siac_d_movgest_ts_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_ts_tipo_code='T';
        if movgestTsTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo stato DEFINITIVO accertamento.';
		select tipo.movgest_stato_id into movgestStatoId
		from siac_d_movgest_stato tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_stato_code='D';
        if movgestStatoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo importo ATTUALE accertamento.';
		select tipo.movgest_ts_det_tipo_id into movgestTsDetTipoId
		from siac_d_movgest_ts_det_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_ts_det_tipo_code='A';
        if movgestTsDetTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;



	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo provvissorio cassa entrata.';
		select tipo.provc_tipo_id into provvisorioTipoId
		from siac_d_prov_cassa_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.provc_tipo_code='E';
        if provvisorioTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;

	if codResult is null then
     strMessaggio:='Gestione scarti di elaborazione. Verifica annoBilancio indicato su dettagli di riconciliazione.';
     select  distinct doc.pagopa_ric_doc_anno_esercizio into annoBilancio
     from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
     where flusso.pagopa_elab_id=filePagoPaElabId
     and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc.pagopa_ric_doc_stato_elab='N'
     and   doc.pagopa_ric_doc_subdoc_id is null
     and   not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and   doc.data_cancellazione is null
     and   doc.validita_fine is null
     and   flusso.data_cancellazione is null
     and   flusso.validita_fine is null
     limit 1;
     if annoBilancio is null then
       	pagoPaCodeErr:=PAGOPA_ERR_12;
        strErrore:=' Dati non presenti.';
        codResult:=-1;
        bElabora:=false;
     else
     	if annoBilancio>annoBilancioElab then
           	pagoPaCodeErr:=PAGOPA_ERR_11;
	        strErrore:=' Anno bilancio successivo ad anno di elaborazione.';
    	    codResult:=-1;
        	bElabora:=false;
        end if;
     end if;
	end if;


    if codResult is null then
	 strMessaggio:='Gestione scarti di elaborazione. Verifica fase bilancio per elaborazione.';
	 select bil.bil_id, per.periodo_id into bilancioId , periodoId
     from siac_t_bil bil,siac_t_periodo per,
          siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where per.ente_proprietario_id=enteProprietarioid
     and   per.anno::integer=annoBilancio
     and   bil.periodo_id=per.periodo_id
     and   r.bil_id=bil.bil_id
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST);
     if bilancioId is null then
     	pagoPaCodeErr:=PAGOPA_ERR_18;
        strErrore:=' Fase non ammessa per elaborazione.';
        codResult:=-1;
        bElabora:=false;
	 end if;
   end if;

   if codResult is null then
	  strMessaggio:='Gestione scarti di elaborazione. Lettura progressivo doc. siac_t_doc_num per anno='||annoBilancio::varchar||'.';

      nProgressivo:=0;
      insert into  siac_t_doc_num
      (
        doc_anno,
        doc_numero,
        doc_tipo_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
      )
      select annoBilancio,
             nProgressivo,
             docTipoId,
             clock_timestamp(),
             loginOperazione,
             bil.ente_proprietario_id
      from siac_t_bil bil
      where bil.bil_id=bilancioId
      and not exists
      (
      select 1
      from siac_t_doc_num num
      where num.ente_proprietario_id=bil.ente_proprietario_id
      and   num.doc_anno::integer=annoBilancio
      and   num.doc_tipo_id=docTipoId
      and   num.data_cancellazione is null
      and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
      )
      returning doc_num_id into codResult;

      if codResult is null then
      	select num.doc_numero into codResult
        from siac_t_doc_num num
        where num.ente_proprietario_id=enteProprietarioId
        and   num.doc_anno::integer=annoBilancio
        and   num.doc_tipo_id=docTipoId;

        if codResult is not null then
        	nProgressivo:=codResult;
            codResult:=null;
        else
            pagoPaCodeErr:=PAGOPA_ERR_37;
        	strErrore:=' Progressivo non reperito.';
	        codResult:=-1;
    	    bElabora:=false;
        end if;
      else codResult:=null;
      end if;

   end if;

   if codResult is null then
    strMessaggio:='Gestione scarti di elaborazione. Inserimento siac_t_registrounico_doc_num per anno='||annoBilancio::varchar||'.';

	insert into  siac_t_registrounico_doc_num
    (
	  rudoc_registrazione_anno,
	  rudoc_registrazione_numero,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select annoBilancio,
           0,
           clock_timestamp(),
           loginOperazione,
           bil.ente_proprietario_id
    from siac_t_bil bil
    where bil.bil_id=bilancioId
    and not exists
    (
    select 1
    from siac_t_registrounico_doc_num num
    where num.ente_proprietario_id=bil.ente_proprietario_id
    and   num.rudoc_registrazione_anno::integer=annoBilancio
    and   num.data_cancellazione is null
    and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
    );
   end if;



    -- gestione scarti
    -- provvisorio non esistente
    if codResult is null then

 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_22||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select 1
     from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.provc_tipo_code='E'
     and   prov.provc_tipo_id=tipo.provc_tipo_id
     and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
     and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
     and   prov.provc_data_annullamento is null
     and   prov.provc_data_regolarizzazione is null
     and   prov.data_cancellazione is null
     and   prov.validita_fine is null
     )
     and    not exists -- esclusione flussi ( per provvisorio ) con scarti
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_22
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_22;
        strErrore:=' Provvisori di cassa non esistenti.';
     end if;
	 codResult:=null;
    end if;
--    raise notice 'strErrore=%',strErrore;

    --- provvisorio esistente , ma regolarizzato
    if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_38||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     select 1
     from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo, siac_r_ordinativo_prov_cassa rp
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.provc_tipo_code='E'
     and   prov.provc_tipo_id=tipo.provc_tipo_id
     and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
     and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
     and   rp.provc_id=prov.provc_id
     and   prov.provc_data_annullamento is null
     and   prov.provc_data_regolarizzazione is null
     and   prov.data_cancellazione is null
     and   prov.validita_fine is null
     and   rp.data_cancellazione is null
     and   rp.validita_fine is null
     )
     and    not exists -- esclusione flussi ( per provvisorio ) con scarti
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_22
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)=0 then
       update pagopa_t_riconciliazione_doc doc
       set    pagopa_ric_doc_stato_elab='X',
        	   pagopa_ric_errore_id=err.pagopa_ric_errore_id,
               data_modifica=clock_timestamp(),
               login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
   	   from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
	   where  flusso.pagopa_elab_id=filePagoPaElabId
       and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
       and    doc.pagopa_ric_doc_stato_elab='N'
       and    doc.pagopa_ric_doc_subdoc_id is null
       and    exists
       (
       select 1
       from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo, siac_r_subdoc_prov_cassa rp
       where tipo.ente_proprietario_id=doc.ente_proprietario_id
       and   tipo.provc_tipo_code='E'
       and   prov.provc_tipo_id=tipo.provc_tipo_id
       and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
       and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
       and   rp.provc_id=prov.provc_id
       and   prov.provc_data_annullamento is null
       and   prov.provc_data_regolarizzazione is null
       and   prov.data_cancellazione is null
       and   prov.validita_fine is null
       and   rp.data_cancellazione is null
       and   rp.validita_fine is null
       )
       and    not exists -- esclusione flussi ( per provvisorio ) con scarti
       (
       select 1
       from pagopa_t_riconciliazione_doc doc1
       where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
       and   doc1.pagopa_ric_doc_stato_elab!='N'
       and   doc1.data_cancellazione is null
       and   doc1.validita_fine is null
       )
       and    err.ente_proprietario_id=flusso.ente_proprietario_id
       and    err.pagopa_ric_errore_code=PAGOPA_ERR_22
       and    flusso.data_cancellazione is null
       and    flusso.validita_fine is null
       and    doc.data_cancellazione is null
       and    doc.validita_fine is null;
       GET DIAGNOSTICS codResult = ROW_COUNT;
     end if;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_38;
        strErrore:=' Provvisori di cassa regolarizzati.';
     end if;
	 codResult:=null;
    end if;

    if codResult is null then
     -- accertamento non esistente
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_23||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select 1
     from siac_t_movgest mov, siac_d_movgest_tipo tipo,
          siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
          siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.movgest_tipo_code='A'
     and   mov.movgest_tipo_id=tipo.movgest_tipo_id
     and   mov.bil_id=bilancioId
     and   ts.movgest_id=mov.movgest_id
     and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
     and   tipots.movgest_ts_tipo_code='T'
     and   rs.movgest_ts_id=ts.movgest_ts_id
     and   stato.movgest_stato_id=rs.movgest_stato_id
     and   stato.movgest_stato_code='D'
     and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
     and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
     and   mov.data_cancellazione is null
     and   mov.validita_fine is null
     and   ts.data_cancellazione is null
     and   ts.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_23
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0  then
     	pagoPaCodeErr:=PAGOPA_ERR_23;
        strErrore:=' Accertamenti non esistenti.';
     end if;
     codResult:=null;
   end if;

--   raise notice 'strErrore=%',strErrore;

   -- soggetto indicato non esistente non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_34||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_codice_benef is not null
     and    not exists
     (
     select 1
     from siac_t_soggetto sog
     where sog.ente_proprietario_id=doc.ente_proprietario_id
     and   sog.soggetto_code=doc.pagopa_ric_doc_codice_benef
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_34
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_34;
        strErrore:=' Soggetto indicato non esistente.';
     end if;
     codResult:=null;
   end if;

   -- struttura amministrativa indicata non esistente indicato non esistente non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_35||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    coalesce(doc.pagopa_ric_doc_str_amm,'')!=''
     and    not exists
     (
     select 1
     from siac_t_class c
     where c.ente_proprietario_id=doc.ente_proprietario_id
     and   c.classif_code=doc.pagopa_ric_doc_str_amm
     and   c.classif_tipo_id in (cdcTipoId,cdrTipoId)
     and   c.data_cancellazione is null
     and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine, date_trunc('DAY',now())))
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_35
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_35;
        strErrore:=' Struttura amministrativa indicata non esistente o non valida.';
     end if;
     codResult:=null;
   end if;


  ---  aggiornamento di pagopa_t_riconciliazione a partire da pagopa_t_riconciliazione_doc
  ---  per gli scarti prodotti in questa elaborazione
  if codResult is null then
   strMessaggio:='Gestione scarti di elaborazione. Aggiornamento pagopa_t_riconciliazione da pagopa_t_riconciliazione_doc.';

   update pagopa_t_riconciliazione ric
   set    pagopa_ric_flusso_stato_elab='X',
  	      pagopa_ric_errore_id=doc.pagopa_ric_errore_id,
          data_modifica=clock_timestamp(),
          login_operazione=ric.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
   from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
   where flusso.pagopa_elab_id=filePagoPaElabId
   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
   and   doc.pagopa_ric_doc_stato_elab='X'
   and   doc.login_operazione like '%@ELAB-'|| filePagoPaElabId::varchar||'%'
   and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId --- per elab_id
   and   ric.pagopa_ric_id=doc.pagopa_ric_id;
  end if;
  ---

   if codResult is null then
     strMessaggio:='Verifica esistenza dettagli di riconciliazione da elaborare.';

--     raise notice 'strMessaggio=%',strMessaggio;
     select 1 into codresult
     from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
     where flusso.pagopa_elab_id=filePagoPaElabId
     and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc.pagopa_ric_doc_stato_elab='N'
     and   doc.pagopa_ric_doc_subdoc_id is null
     and   not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and   doc.data_cancellazione is null
     and   doc.validita_fine is null
     and   flusso.data_cancellazione is null
     and   flusso.validita_fine is null;
 --    raise notice 'codREsult=%',codResult;
     if codResult is null then
       	pagoPaCodeErr:=PAGOPA_ERR_7;
        strErrore:=' Dati non presenti.';
        codResult:=-1;
        bElabora:=false;
     else codResult:=null;
     end if;
   end if;



   if pagoPaCodeErr is not null then
     -- aggiornare anche pagopa_t_riconciliazione e pagopa_t_riconciliazione_doc
     strmessaggioBck:=strMessaggio;
     strMessaggio:=strMessaggio||' '||strErrore||' Aggiornamento pagopa_t_elaborazione.';
	 update pagopa_t_elaborazione elab
     set    data_modifica=clock_timestamp(),
            validita_fine=(case when bElabora=false then clock_timestamp() else null end ),
            pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
            pagopa_elab_errore_id=err.pagopa_ric_errore_id,
            pagopa_elab_note=upper(strMessaggioFinale||' '||strMessaggio)
     from  pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
     where elab.pagopa_elab_id=filePagoPaElabId
     and   statonew.ente_proprietario_id=elab.ente_proprietario_id
     and   statonew.pagopa_elab_stato_code=(case when bElabora=false then ELABORATO_ERRATO_ST else ELABORATO_IN_CORSO_SC_ST end)
     and   err.ente_proprietario_id=statonew.ente_proprietario_id
     and   err.pagopa_ric_errore_code=pagoPaCodeErr
     and   elab.data_cancellazione is null
     and   elab.validita_fine is null;


     strMessaggio:=strmessaggioBck||' '||strErrore||' Aggiornamento siac_t_file_pagopa.';
     update siac_t_file_pagopa file
     set    data_modifica=clock_timestamp(),
            file_pagopa_stato_id=stato.file_pagopa_stato_id,
            file_pagopa_errore_id=err.pagopa_ric_errore_id,
            file_pagopa_note=upper(strMessaggioFinale||' '||strMessaggio),
            login_operazione=file.login_operazione||'-'||loginOperazione
        from  pagopa_r_elaborazione_file r,
              siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
        where r.pagopa_elab_id=filePagoPaElabId
        and   file.file_pagopa_id=r.file_pagopa_id
        and   stato.ente_proprietario_id=file.ente_proprietario_id
        and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ER_ST
        and   err.ente_proprietario_id=stato.ente_proprietario_id
        and   err.pagopa_ric_errore_code=pagoPaCodeErr
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

     if bElabora= false then
      codiceRisultato:=-1;
      messaggioRisultato:= upper(strMessaggioFinale||' '||strmessaggioBck||' '||strErrore||'.');
      strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_esegui - '||messaggioRisultato;
      insert into pagopa_t_elaborazione_log
      (
       pagopa_elab_id,
       pagopa_elab_file_id,
       pagopa_elab_log_operazione,
       ente_proprietario_id,
       login_operazione,
       data_creazione
      )
      values
      (
       filePagoPaElabId,
       null,
       strMessaggioLog,
       enteProprietarioId,
       loginOperazione,
       clock_timestamp()
      );

      return;
     end if;
   end if;


  pagoPaCodeErr:=null;
  strMessaggio:='Inizio inserimento documenti.';
  strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
  insert into pagopa_t_elaborazione_log
  (
   pagopa_elab_id,
   pagopa_elab_file_id,
   pagopa_elab_log_operazione,
   ente_proprietario_id,
   login_operazione,
   data_creazione
  )
  values
  (
   filePagoPaElabId,
   null,
   strMessaggioLog,
   enteProprietarioId,
   loginOperazione,
   clock_timestamp()
  );

  raise notice 'strMessaggio=%',strMessaggio;
  for pagoPaFlussoRec in
  (
   with
   pagopa_sogg as
   (
   with
   pagopa as
   (
   select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
		  doc.pagopa_ric_doc_str_amm pagopa_str_amm ,
          doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
		  doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
          doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
          doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento
   from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
   where flusso.pagopa_elab_id=filePagoPaElabId
   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
   and   doc.pagopa_ric_doc_stato_elab='N'
   and   doc.pagopa_ric_doc_subdoc_id is null
   and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
   )
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null
   and   flusso.data_cancellazione is null
   and   flusso.validita_fine is null
   group by doc.pagopa_ric_doc_codice_benef,
			doc.pagopa_ric_doc_str_amm,
            doc.pagopa_ric_doc_voce_tematica,
            doc.pagopa_ric_doc_voce_code,
            doc.pagopa_ric_doc_voce_desc,
            doc.pagopa_ric_doc_anno_accertamento,
            doc.pagopa_ric_doc_num_accertamento
   ),
   sogg as
   (
   select sog.soggetto_id, sog.soggetto_code,sog.soggetto_desc
   from siac_t_soggetto sog
   where sog.ente_proprietario_id=enteProprietarioId
   and   sog.data_cancellazione is null
   and   sog.validita_fine is null
   )
   select pagopa.*,
          sogg.soggetto_id,
          sogg.soggetto_desc
   from pagopa
        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code)
   ),
   accertamenti_sogg as
   (
   with
   accertamenti as
   (
   	select mov.movgest_anno::integer, mov.movgest_numero::integer,
           mov.movgest_id, ts.movgest_ts_id
    from siac_t_movgest mov , siac_d_movgest_tipo tipo,
         siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code='A'
    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
    and   mov.bil_id=bilancioId
    and   ts.movgest_id=mov.movgest_id
    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   tipots.movgest_ts_tipo_code='T'
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code='D'
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
   ),
   soggetto_acc as
   (
   select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc,rsog.movgest_ts_id
   from siac_r_movgest_ts_sog rsog, siac_t_soggetto sog
   where sog.ente_proprietario_id=enteProprietarioId
   and   rsog.soggetto_id=sog.soggetto_id
   and   rsog.data_cancellazione is null
   and   rsog.validita_fine is null
   )
   select accertamenti.*,soggetto_acc.soggetto_id, soggetto_acc.soggetto_code,soggetto_acc.soggetto_desc
   from   accertamenti , soggetto_acc
   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id
   )
   select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
   		   ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc,
		   ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
           pagopa_sogg.pagopa_str_amm,
           pagopa_sogg.pagopa_voce_tematica,
           pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc
   from  pagopa_sogg, accertamenti_sogg
   where pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
   and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
   group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
            ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
            ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )  ,
            pagopa_sogg.pagopa_str_amm,
            pagopa_sogg.pagopa_voce_tematica,
            pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc
   order by  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
   			 pagopa_sogg.pagopa_str_amm,
             pagopa_sogg.pagopa_voce_tematica,
			 pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc
  )
  loop
   		-- filePagoPaElabId - elaborazione id
        -- filePagoPaId     - file pagopa id
        -- filePagoPaFileXMLId  - file pagopa id XML
        -- pagopa_soggetto_id
        -- pagopa_soggetto_code
        -- pagopa_voce_code
        -- pagopa_voce_desc
        -- pagopa_str_amm

        -- elementi per inserimento documento

        -- inserimento documento
        -- siac_t_doc ok
        -- siac_r_doc_sog ok
        -- siac_r_doc_stato ok
        -- siac_r_doc_class ok struttura amministrativa
        -- siac_r_doc_attr ok
        -- siac_t_registrounico_doc ok
        -- siac_t_subdoc_num ok

        -- siac_t_subdoc ok
        -- siac_r_subdoc_attr ok
        -- siac_r_subdoc_class -- non ce ne sono

        -- siac_r_subdoc_atto_amm ok
        -- siac_r_subdoc_movgest_ts ok
        -- siac_r_subdoc_prov_cassa ok

        dDocImporto:=0;
        strElencoFlussi:=' ';
        dnumQuote:=0;
        bErrore:=false;

		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_t_doc].';
		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;

        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );
		docId:=null;
        nProgressivo:=nProgressivo+1;
		-- siac_t_doc
        insert into siac_t_doc
        (
        	doc_anno,
		    doc_numero,
			doc_desc,
		    doc_importo,
		    doc_data_emissione, -- dataElaborazione
			doc_data_scadenza,  -- dataSistema
		    doc_tipo_id,
		    codbollo_id,
		    validita_inizio,
		    ente_proprietario_id,
		    login_operazione,
		    login_creazione,
            login_modifica,
			pcccod_id, -- null ??
	        pccuff_id -- null ??
        )
        select annoBilancio,
               pagoPaFlussoRec.pagopa_voce_code||' '||dataElaborazione||' '||nProgressivo::varchar,
               upper('Incassi '
               		 ||substring(coalesce(pagoPaFlussoRec.pagopa_voce_tematica,' '),1,30)||' '
                     ||pagoPaFlussoRec.pagopa_voce_code||' '
                     ||substring(coalesce(pagoPaFlussoRec.pagopa_voce_desc,' '),1,30) ||' '||strElencoFlussi),
			   dDocImporto,
               dataElaborazione,
               dataElaborazione,
			   docTipoId,
               codBolloId,
               clock_timestamp(),
               enteProprietarioId,
               loginOperazione,
               loginOperazione,
               loginOperazione,
               null,
               null
        returning doc_id into docId;
	    raise notice 'docid=%',docId;
		if docId is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
        end if;

		if bErrore=false then
		 codResult:=null;
	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_r_doc_sog].';
		 -- siac_r_doc_sog
         insert into siac_r_doc_sog
         (
        	doc_id,
            soggetto_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
         )
         select  docId,
                 pagoPaFlussoRec.pagopa_soggetto_id,
                 clock_timestamp(),
                 loginOperazione,
                 enteProprietarioId
         returning  doc_sog_id into codResult;

         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';

         end if;
        end if;

	    if bErrore=false then
         codResult:=null;
	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_r_doc_stato].';
         insert into siac_r_doc_stato
         (
        	doc_id,
            doc_stato_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
         )
         select docId,
                docStatoValId,
                clock_timestamp(),
                loginOperazione,
                enteProprietarioId
         returning doc_stato_r_id into codResult;
		 if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
		end if;

        if bErrore=false then
         -- siac_r_doc_attr
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||ANNO_REPERTORIO_ATTR||' [siac_r_doc_attr].';

         -- anno_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
         	    --annoBilancio::varchar,
                NULL,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=ANNO_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then

	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||NUM_REPERTORIO_ATTR||' [siac_r_doc_attr].';

         -- num_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
         	    null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=NUM_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||DATA_REPERTORIO_ATTR||' [siac_r_doc_attr].';
		 -- data_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
--        	    extract( 'day' from now())::varchar||'/'||
--               lpad(extract( 'month' from now())::varchar,2,'0')||'/'||
--               extract( 'year' from now())::varchar,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=DATA_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

        if bErrore=false then
		 -- registro_repertorio
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||REG_REPERTORIO_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=REG_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
		 -- arrotondamento
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||ARROTONDAMENTO_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            numerico,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                0,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=ARROTONDAMENTO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		/*if bErrore=false then
         -- causale_sospensione
 		 -- data_sospensione
 		 -- data_riattivazione
   		 -- dataScadenzaDopoSospensione
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi sospensione [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code in (CAUS_SOSPENSIONE_ATTR,DATA_SOSPENSIONE_ATTR,DATA_RIATTIVAZIONE_ATTR/*,DATA_SCAD_SOSP_ATTR*/);
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;*/

        if bErrore=false then
		 -- terminepagamento
		 strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||TERMINE_PAG_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            numerico,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                TERMINE_PAG_DEF,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=TERMINE_PAG_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		/*if bErrore=false then
	     -- notePagamentoIncasso
    	 -- dataOperazionePagamentoIncasso
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi pagamento incasso [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code in (NOTE_PAG_INC_ATTR,DATA_PAG_INC_ATTR);
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;*/

		if bErrore=false then
         -- flagAggiornaQuoteDaElenco
		 -- flagSenzaNumero
		 -- flagDisabilitaRegistrazioneResidui
		 -- flagPagataIncassata
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi flag [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            boolean,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                'N',
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
--         and   a.attr_code in (/*FL_AGG_QUOTE_ELE_ATTR,*/FL_SENZA_NUM_ATTR,FL_REG_RES_ATTR);--,FL_PAGATA_INC_ATTR);
         and   a.attr_code=FL_REG_RES_ATTR;

         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
		 -- codiceFiscalePignorato
		 -- dataRicezionePortale

		 strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi vari [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
--         and   a.attr_code in (COD_FISC_PIGN_ATTR,DATA_RIC_PORTALE_ATTR);
         and   a.attr_code=DATA_RIC_PORTALE_ATTR;
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;
        if bErrore=false then
		 -- siac_r_doc_class
         if coalesce(pagoPaFlussoRec.pagopa_str_amm ,'')!='' then
            strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa [siac_r_doc_class]'
                         ||'. Verifica esistenza come CDC.';

        	codResult:=null;
            select c.classif_id into codResult
            from siac_t_class c
            where c.classif_tipo_id=cdcTipoId
            and   c.classif_code=pagoPaFlussoRec.pagopa_str_amm
            and   c.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine,date_trunc('DAY',now())));
            if codResult is null then
                strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa  [siac_r_doc_class]'
                         ||'. Verifica esistenza come CDR.';
	            select c.classif_id into codResult
    	        from siac_t_class c
        	    where c.classif_tipo_id=cdrTipoId
	           	and   c.classif_code=pagoPaFlussoRec.pagopa_str_amm
    	        and   c.data_cancellazione is null
        	    and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine,date_trunc('DAY',now())));
            end if;
            if codResult is not null then
               codResult1:=codResult;
               codResult:=null;
	           strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa  [siac_r_doc_class].';

            	insert into siac_r_doc_class
                (
                	doc_id,
                    classif_id,
                    validita_inizio,
                    login_operazione,
                    ente_proprietario_id
                )
                values
                (
                	docId,
                    codResult1,
                    clock_timestamp(),
                    loginOperazione,
                    enteProprietarioId
                )
                returning doc_classif_id into codResult;

                if codResult is null then
                	bErrore:=true;
		            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
                end if;
            end if;
         end if;
        end if;

		if bErrore =false then
		 --  siac_t_registrounico_doc
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento registro unico documento [siac_t_registrounico_doc].';

      	 codResult:=null;
         insert into siac_t_registrounico_doc
         (
        	rudoc_registrazione_anno,
 			rudoc_registrazione_numero,
			rudoc_registrazione_data,
			doc_id,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select num.rudoc_registrazione_anno,
                num.rudoc_registrazione_numero+1,
                clock_timestamp(),
                docId,
                loginOperazione,
                clock_timestamp(),
                num.ente_proprietario_id
         from siac_t_registrounico_doc_num num
         where num.ente_proprietario_id=enteProprietarioId
         and   num.rudoc_registrazione_anno=annoBilancio
         and   num.data_cancellazione is null
         and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
         returning rudoc_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
         if bErrore=false then
            codResult:=null;
         	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento registro unico documento [siac_t_registrounico_doc_num].';
         	update siac_t_registrounico_doc_num num
            set    rudoc_registrazione_numero=num.rudoc_registrazione_numero+1,
                   data_modifica=clock_timestamp()
        	where num.ente_proprietario_id=enteProprietarioId
	        and   num.rudoc_registrazione_anno=annoBilancio
         	and   num.data_cancellazione is null
	        and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
            returning num.rudoc_num_id into codResult;
            if codResult is null  then
               bErrore:=true;
               strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
            end if;
         end if;
        end if;

		if bErrore =false then
         codResult:=null;
		 --  siac_t_doc_num
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento progressivi documenti [siac_t_doc_num].';
         update siac_t_doc_num num
         set    doc_numero=num.doc_numero+1,
         	    data_modifica=clock_timestamp()
         where  num.ente_proprietario_id=enteProprietarioid
         and    num.doc_anno=annoBilancio
         and    num.doc_tipo_id=docTipoId
         returning num.doc_num_id into codResult;
         if codResult is null then
         	 bErrore:=true;
             strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
         end if;
        end if;

        if bErrore=true then
            strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
        end if;


		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento.';
        raise notice 'strMessaggio=%',strMessaggio;
		if bErrore=false then
			strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
	    end if;

        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );

        for pagoPaFlussoQuoteRec in
  		(
  	     with
           pagopa_sogg as
		   (
           with
		   pagopa as
		   (
		   select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
			      doc.pagopa_ric_doc_str_amm pagopa_str_amm,
                  doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
           		  doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
                  doc.pagopa_ric_doc_sottovoce_code pagopa_sottovoce_code, doc.pagopa_ric_doc_sottovoce_desc pagopa_sottovoce_desc,
                  flusso.pagopa_elab_flusso_anno_provvisorio pagopa_anno_provvisorio,
                  flusso.pagopa_elab_flusso_num_provvisorio pagopa_num_provvisorio,
                  flusso.pagopa_elab_ric_flusso_id pagopa_flusso_id,
                  flusso.pagopa_elab_flusso_nome_mittente pagopa_flusso_nome_mittente,
        		  doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
		          doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento,
                  doc.pagopa_ric_doc_sottovoce_importo pagopa_sottovoce_importo
		   from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
		   where flusso.pagopa_elab_id=filePagoPaElabId
		   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
           and   coalesce(doc.pagopa_ric_doc_voce_tematica,'')=coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
           and   doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
           and   coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
           and   coalesce(doc.pagopa_ric_doc_str_amm,'')=coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
		   and   doc.pagopa_ric_doc_stato_elab='N'
		   and   doc.pagopa_ric_doc_subdoc_id is null
		   and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
		   (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		   )
		   and   doc.data_cancellazione is null
		   and   doc.validita_fine is null
		   and   flusso.data_cancellazione is null
		   and   flusso.validita_fine is null
		   ),
		   sogg as
		   (
			   select sog.soggetto_id, sog.soggetto_code,sog.soggetto_desc
			   from siac_t_soggetto sog
			   where sog.ente_proprietario_id=enteProprietarioId
			   and   sog.data_cancellazione is null
			   and   sog.validita_fine is null
		   )
		   select pagopa.*,
		          sogg.soggetto_id,
        		  sogg.soggetto_desc
		   from pagopa
		        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code)
		   ),
		   accertamenti_sogg as
		   (
             with
			 accertamenti as
			 (
			   	select mov.movgest_anno::integer, mov.movgest_numero::integer,
		    	       mov.movgest_id, ts.movgest_ts_id
			    from siac_t_movgest mov , siac_d_movgest_tipo tipo,
			         siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
			         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
			    where tipo.ente_proprietario_id=enteProprietarioId
			    and   tipo.movgest_tipo_code='A'
			    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
			    and   mov.bil_id=bilancioId
			    and   ts.movgest_id=mov.movgest_id
			    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
			    and   tipots.movgest_ts_tipo_code='T'
			    and   rs.movgest_ts_id=ts.movgest_ts_id
			    and   stato.movgest_stato_id=rs.movgest_stato_id
			    and   stato.movgest_stato_code='D'
			    and   mov.data_cancellazione is null
			    and   mov.validita_fine is null
			    and   ts.data_cancellazione is null
			    and   ts.validita_fine is null
			    and   rs.data_cancellazione is null
			    and   rs.validita_fine is null
		   ),
		   soggetto_acc as
		   (
			   select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc,rsog.movgest_ts_id
			   from siac_r_movgest_ts_sog rsog, siac_t_soggetto sog
			   where sog.ente_proprietario_id=enteProprietarioId
			   and   rsog.soggetto_id=sog.soggetto_id
			   and   rsog.data_cancellazione is null
			   and   rsog.validita_fine is null
		   )
		   select accertamenti.*,soggetto_acc.soggetto_id, soggetto_acc.soggetto_code,soggetto_acc.soggetto_desc
		   from   accertamenti , soggetto_acc
		   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id
	  	 )
		 select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
   				 ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc	,
                 ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
                 pagopa_sogg.pagopa_str_amm,
                 pagopa_sogg.pagopa_voce_tematica,
                 pagopa_sogg.pagopa_voce_code,  pagopa_sogg.pagopa_voce_desc,
                 pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                 pagopa_sogg.pagopa_flusso_id,
                 pagopa_sogg.pagopa_flusso_nome_mittente,
                 pagopa_sogg.pagopa_anno_provvisorio,
                 pagopa_sogg.pagopa_num_provvisorio,
                 pagopa_sogg.pagopa_anno_accertamento,
		         pagopa_sogg.pagopa_num_accertamento,
                 sum(pagopa_sogg.pagopa_sottovoce_importo) pagopa_sottovoce_importo
  	     from  pagopa_sogg, accertamenti_sogg
 	     where bErrore=false
         and   pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
	   	 and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
         and   (case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )=
	           pagoPaFlussoRec.pagopa_soggetto_id
	     group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
        	      ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
                  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ),
                  pagopa_sogg.pagopa_str_amm,
                  pagopa_sogg.pagopa_voce_tematica,
                  pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                  pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                  pagopa_sogg.pagopa_flusso_id,pagopa_sogg.pagopa_flusso_nome_mittente,
                  pagopa_sogg.pagopa_anno_provvisorio,
                  pagopa_sogg.pagopa_num_provvisorio,
                  pagopa_sogg.pagopa_anno_accertamento,
		          pagopa_sogg.pagopa_num_accertamento
	     order by  pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                   pagopa_sogg.pagopa_anno_provvisorio,
                   pagopa_sogg.pagopa_num_provvisorio,
				   pagopa_sogg.pagopa_anno_accertamento,
		           pagopa_sogg.pagopa_num_accertamento
  	   )
       loop

        codResult:=null;
        codResult1:=null;
        subdocId:=null;
        subdocMovgestTsId:=null;
		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_t_subdoc].';
        raise notice 'strMessagio=%',strMessaggio;
		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );

		-- siac_t_subdoc
        insert into siac_t_subdoc
        (
        	subdoc_numero,
			subdoc_desc,
			subdoc_importo,
--		    subdoc_nreg_iva,
	        subdoc_data_scadenza,
	        subdoc_convalida_manuale,
	        subdoc_importo_da_dedurre, -- 05.06.2019 SIAC-6893
--	        subdoc_splitreverse_importo,
--	        subdoc_pagato_cec,
--	        subdoc_data_pagamento_cec,
--	        contotes_id INTEGER,
--	        dist_id INTEGER,
--	        comm_tipo_id INTEGER,
	        doc_id,
	        subdoc_tipo_id,
--	        notetes_id INTEGER,
	        validita_inizio,
			ente_proprietario_id,
		    login_operazione,
	        login_creazione,
            login_modifica
        )
        values
        (
        	dnumQuote+1,
            upper('Voce '||pagoPaFlussoQuoteRec.pagopa_voce_code||'/'||pagoPaFlussoQuoteRec.pagopa_sottovoce_code||' '||
            substring(coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,' ' ),1,30)||
            pagoPaFlussoQuoteRec.pagopa_flusso_id||' PSP '||pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente||
            ' Prov. '||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio::varchar||'/'||
            pagoPaFlussoQuoteRec.pagopa_num_provvisorio),
            pagoPaFlussoQuoteRec.pagopa_sottovoce_importo,
            dataElaborazione,
            'M', -- 13.12.2018 Sofia siac-6602
            0,   --- 05.06.2019 SIAC-6893
  			docId,
            subDocTipoId,
            clock_timestamp(),
            enteProprietarioId,
            loginOperazione,
            loginOperazione,
            loginOperazione
        )
        returning subdoc_id into subDocId;
        raise notice 'subdocId=%',subdocId;
        if subDocId is null then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;

		-- siac_r_subdoc_attr
		-- flagAvviso
		-- flagEsproprio
		-- flagOrdinativoManuale
		-- flagOrdinativoSingolo
		-- flagRilevanteIVA
        codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr vari].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            boolean,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               'N',
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code in
        (
         FL_AVVISO_ATTR,
	     FL_ESPROPRIO_ATTR,
	     FL_ORD_MANUALE_ATTR,
		 FL_ORD_SINGOLO_ATTR,
	     FL_RIL_IVA_ATTR
        );
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if coalesce(codResult,0)=0 then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;

        end if;

		-- causaleOrdinativo
        /*codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr='||CAUS_ORDIN_ATTR||'].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            testo,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               upper('Regolarizzazione incasso voce '||pagoPaFlussoQuoteRec.pagopa_voce_code||'/'||pagoPaFlussoQuoteRec.pagopa_sottovoce_code||' '||
	            substring(coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,' '),1,30)||
    	        ' Prov. '||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio::varchar||'/'||
        	    pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' '),
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code=CAUS_ORDIN_ATTR
        returning subdoc_attr_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;*/

		-- dataEsecuzionePagamento
    	/*codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr='||DATA_ESEC_PAG_ATTR||'].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            testo,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               null,
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code=DATA_ESEC_PAG_ATTR
        returning subdoc_attr_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;*/

  	    -- controllo sfondamento e adeguamento accertamento
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||'. Verifica esistenza accertamento.';

		codResult:=null;
        dispAccertamento:=null;
        movgestTsId:=null;
        select ts.movgest_ts_id into movgestTsId
        from siac_t_movgest mov, siac_t_movgest_ts ts,
             siac_r_movgest_ts_stato rs
        where mov.bil_id=bilancioId
        and   mov.movgest_tipo_id=movgestTipoId
        and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
        and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
        and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=movgestTsTipoId
        and   rs.movgest_ts_id=ts.movgest_ts_id
        and   rs.movgest_stato_id=movgestStatoId
        and   rs.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
        and   ts.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
        and   mov.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())));

        if movgestTsId is not null then
       		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||'. Verifica dispon. accertamento.';

	        select * into dispAccertamento
            from fnc_siac_disponibilitaincassaremovgest (movgestTsId) disponibilita;
		    raise notice 'dispAccertamento=%',dispAccertamento;
            if dispAccertamento is not null then
            	if dispAccertamento-pagoPaFlussoQuoteRec.pagopa_sottovoce_importo<0 then
		      		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||'. Verifica dispon. accertamento.'
                         ||' Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
      						  ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'.';

                	update siac_t_movgest_ts_det det
                    set    movgest_ts_det_importo=det.movgest_ts_det_importo+
                                                  (pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento),
                           data_modifica=clock_timestamp(),
                           login_operazione=det.login_operazione||'-'||loginOperazione
                    where det.movgest_ts_id=movgestTsId
                    and   det.movgest_ts_det_tipo_id=movgestTsDetTipoId
                    and   det.data_cancellazione is null
                    and   date_trunc('DAY',now())>=date_trunc('DAY',det.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(det.validita_fine,date_trunc('DAY',now())))
                    returning det.movgest_ts_det_id into codResult;
                    if codResult is null then
                        bErrore:=true;
                        pagoPaCodeErr:=PAGOPA_ERR_31;
                    	strMessaggio:=strMessaggio||' Errore in adeguamento.';
                        continue;
                    end if;
                end if;
            else
            	bErrore:=true;
           		pagoPaCodeErr:=PAGOPA_ERR_31;
                strMessaggio:=strMessaggio||' Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
            						  ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||' errore.';
	            continue;
            end if;
        else
            bErrore:=true;
            pagoPaCodeErr:=PAGOPA_ERR_31;
            strMessaggio:=strMessaggio||' Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
            						  ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||' non esistente.';
            continue;
        end if;


		codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' movgest_ts_id='||movgestTsId::varchar||' [siac_r_subdoc_movgest_ts].';
		-- siac_r_subdoc_movgest_ts
        insert into siac_r_subdoc_movgest_ts
        (
        	subdoc_id,
            movgest_ts_id,
            validita_inizio,
            login_Operazione,
            ente_proprietario_id
        )
        values
        (
               subdocId,
               movgestTsId,
               clock_timestamp(),
               loginOperazione,
               enteProprietarioId
        )
		returning subdoc_movgest_ts_id into codResult;
		if codResult is null then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;
		subdocMovgestTsId:=  codResult;
raise notice 'subdocMovgestTsId=%',subdocMovgestTsId;
        -- siac_r_subdoc_atto_amm
        codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_atto_amm].';
        insert into siac_r_subdoc_atto_amm
        (
        	subdoc_id,
            attoamm_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               atto.attoamm_id,
               clock_timestamp(),
               loginOperazione,
               atto.ente_proprietario_id
        from siac_r_subdoc_movgest_ts rts, siac_r_movgest_ts_atto_amm atto
        where rts.subdoc_movgest_ts_id=subdocMovgestTsId
        and   atto.movgest_ts_id=rts.movgest_ts_id
        and   atto.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',atto.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(atto.validita_fine,date_trunc('DAY',now())))
        returning subdoc_atto_amm_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;

		-- controllo esistenza e sfondamento disp. provvisorio
        codResult:=null;
        provvisorioId:=null;
        dispProvvisorioCassa:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa].';
        select prov.provc_id into provvisorioId
        from siac_t_prov_cassa prov
        where prov.provc_tipo_id=provvisorioTipoId
        and   prov.provc_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
        and   prov.provc_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
        and   prov.provc_data_annullamento is null
        and   prov.provc_data_regolarizzazione is null
        and   prov.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',prov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(prov.validita_fine,date_trunc('DAY',now())));
        raise notice 'provvisorioId=%',provvisorioId;

        if provvisorioId is not null then
        	select 1 into codResult
            from siac_r_ordinativo_prov_cassa r
            where r.provc_id=provvisorioId
            and   r.data_cancellazione is null
            and   r.validita_fine is null;
            if codResult is null then
            	select 1 into codResult
	            from siac_r_subdoc_prov_cassa r
    	        where r.provc_id=provvisorioId
                and   r.login_operazione not like '%@PAGOPA-'||filePagoPaElabId::varchar||'%'
        	    and   r.data_cancellazione is null
            	and   r.validita_fine is null;
            end if;
            if codResult is not null then
            	pagoPaCodeErr:=PAGOPA_ERR_39;
	            bErrore:=true;
                strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' regolarizzato.';
       		    continue;
            end if;
        end if;
        if provvisorioId is not null then
           strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa] provc_id='
                         ||provvisorioId::VARCHAR||'. Verifica disponibilita''.';
			select * into dispProvvisorioCassa
            from fnc_siac_daregolarizzareprovvisorio(provvisorioId) disponibilita;
            raise notice 'dispProvvisorioCassa=%',dispProvvisorioCassa;
            raise notice 'pagoPaFlussoQuoteRec.pagopa_sottovoce_importo=%',pagoPaFlussoQuoteRec.pagopa_sottovoce_importo;

            if dispProvvisorioCassa is not null then
            	if dispProvvisorioCassa-pagoPaFlussoQuoteRec.pagopa_sottovoce_importo<0 then
                	pagoPaCodeErr:=PAGOPA_ERR_33;
		            bErrore:=true;
                    strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' disp. insufficiente.';
        		    continue;
                end if;
            else
            	pagoPaCodeErr:=PAGOPA_ERR_32;
	            bErrore:=true;
               strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' Errore.';

    	        continue;
            end if;
        else
        	pagoPaCodeErr:=PAGOPA_ERR_32;
            bErrore:=true;
            strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' non esistente.';
            continue;
        end if;


		codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa] provc_id='
                         ||provvisorioId::varchar||'.';
		-- siac_r_subdoc_prov_cassa
        insert into siac_r_subdoc_prov_cassa
        (
        	subdoc_id,
            provc_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        VALUES
        (
               subdocId,
               provvisorioId,
               clock_timestamp(),
               loginOperazione||'@PAGOPA-'||filePagoPaElabId::varchar,
               enteProprietarioId
        )
        returning subdoc_provc_id into codResult;
        raise notice 'subdoc_provc_id=%',codResult;

        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end  if;

		codResult:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento pagopa_t_riconciliazione_doc per subdoc_id.';
        -- aggiornare pagopa_t_riconciliazione_doc
        update pagopa_t_riconciliazione_doc docUPD
        set    pagopa_ric_doc_subdoc_id=subdocId,
		       pagopa_ric_doc_stato_elab='S',
               pagopa_ric_errore_id=null,
               pagopa_ric_doc_movgest_ts_id=movgestTsId,
               pagopa_ric_doc_provc_id=provvisorioId,
               data_modifica=clock_timestamp(),
               login_operazione=docUPD.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
        from
        (
         with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
            and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
            and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
                   coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
            and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
            and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
            and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
            and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
            and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
    		and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab='N'
     	    and    doc.pagopa_ric_doc_subdoc_id is null
     		and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          accertamenti as
          (
          select ts.movgest_ts_id, rsog.soggetto_id
          from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs,
               siac_r_movgest_ts_sog rsog
          where mov.bil_id=bilancioId
          and   mov.movgest_tipo_id=movgestTipoId
          and   ts.movgest_id=mov.movgest_id
          and   ts.movgest_ts_tipo_id=movgestTsTipoId
          and   rs.movgest_ts_id=ts.movgest_ts_id
          and   rs.movgest_stato_id=movgestStatoId
          and   rsog.movgest_ts_id=ts.movgest_ts_id
          and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
          and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
          and   mov.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
          and   ts.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
          and   rs.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
          and   rsog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else s2.soggetto_id end ) pagopa_soggetto_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id)
        ) QUERY
        where docUPD.ente_proprietario_id=enteProprietarioId
        and   docUPD.pagopa_ric_doc_stato_elab='N'
        and   docUPD.pagopa_ric_doc_subdoc_id is null
        and   docUPD.pagopa_ric_doc_id=QUERY.pagopa_ric_doc_id
        and   QUERY.pagopa_soggetto_id=pagoPaFlussoQuoteRec.pagopa_soggetto_id
        and   docUPD.data_cancellazione is null
        and   docUPD.validita_fine is null;
        GET DIAGNOSTICS codResult = ROW_COUNT;
		raise notice 'Aggiornati pagopa_t_riconciliazione_doc=%',codResult;
		if coalesce(codResult,0)=0 then
            raise exception ' Errore in aggiornamento.';
        end if;

		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );

        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento pagopa_t_riconciliazione per subdoc_id.';
		codResult:=null;
        -- aggiornare pagopa_t_riconciliazione
        update pagopa_t_riconciliazione ric
        set    pagopa_ric_flusso_stato_elab='S',
			   pagopa_ric_errore_id=null,
               data_modifica=clock_timestamp(),
               login_operazione=ric.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
		from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
        where flusso.pagopa_elab_id=filePagoPaElabId
        and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
        and   doc.pagopa_ric_doc_subdoc_id=subdocId
        and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
        and   ric.pagopa_ric_id=doc.pagopa_ric_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
   		raise notice 'Aggiornati pagopa_t_riconciliazione=%',codResult;

--        returning ric.pagopa_ric_id into codResult;
		if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in aggiornamento.';
            strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
            insert into pagopa_t_elaborazione_log
            (
            pagopa_elab_id,
            pagopa_elab_file_id,
            pagopa_elab_log_operazione,
            ente_proprietario_id,
            login_operazione,
            data_creazione
            )
            values
            (
            filePagoPaElabId,
            null,
            strMessaggioLog,
            enteProprietarioId,
            loginOperazione,
            clock_timestamp()
            );


            continue;
        end if;

		dnumQuote:=dnumQuote+1;
        dDocImporto:=dDocImporto+pagoPaFlussoQuoteRec.pagopa_sottovoce_importo;

       end loop;

	   if dnumQuote>0 and bErrore=false then
        -- siac_t_subdoc_num
        codResult:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento numero quote [siac_t_subdoc_num].';
 	    insert into siac_t_subdoc_num
        (
         doc_id,
         subdoc_numero,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
        )
        values
        (
         docId,
         dnumQuote,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
        )
        returning subdoc_num_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
        end if;

		if bErrore =false then
        	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento importo documento.';
        	update siac_t_doc doc
            set    doc_importo=dDocImporto
            where doc.doc_id=docId
            returning doc.doc_id into codResult;
            if codResult is null then
            	bErrore:=true;
            	strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
            end if;
        end if;
       else
        -- non ha inserito quote
        if bErrore=false  then
        	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote non effettuato.';
            bErrore:=true;
        end if;
       end if;



	   if bErrore=true then

    	 strMessaggioBck:=strMessaggio;
         strMessaggio:='Cancellazione dati documento inseriti.'||strMessaggioBck;
         raise notice 'strMessaggio=%',strMessaggio;
                  raise notice 'pagoPaCodeErr=%',pagoPaCodeErr;

		 if pagoPaCodeErr is null then
         	pagoPaCodeErr:=PAGOPA_ERR_30;
         end if;

         -- pulizia delle tabella pagopa_t_riconciliazione

         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione S].'||strMessaggioBck;
         raise notice 'strMessaggio=%',strMessaggio;
  		 update pagopa_t_riconciliazione ric
         set    pagopa_ric_flusso_stato_elab='X',
  			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(ric.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
   	     from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc,
              pagopa_d_riconciliazione_errore errore, siac_t_subdoc sub
         where flusso.pagopa_elab_id=filePagoPaElabId
         and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   sub.doc_id=docId
         and   doc.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
         and   ric.pagopa_ric_id=doc.pagopa_ric_id
         and   exists
         (
         select 1
         from pagopa_t_riconciliazione_doc doc1
         where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc1.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   doc1.pagopa_ric_id=ric.pagopa_ric_id
         and   doc1.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   doc1.validita_fine is null
         and   doc1.data_cancellazione is null
         )
         and   errore.ente_proprietario_id=flusso.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   flusso.data_cancellazione is null
         and   flusso.validita_fine is null
         and   ric.data_cancellazione is null
         and   ric.validita_fine is null
         and   sub.data_cancellazione is null
         and   sub.validita_fine is null;

		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
           pagopa_elab_id,
           pagopa_elab_file_id,
           pagopa_elab_log_operazione,
           ente_proprietario_id,
           login_operazione,
           data_creazione
         )
         values
         (
           filePagoPaElabId,
           null,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
         );

         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione N].'||strMessaggioBck;
         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_riconciliazione  docUPD
         set    pagopa_ric_flusso_stato_elab='X',
  			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
         from
         (
		  with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef,
                    doc.pagopa_ric_id
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
            and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
            and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
                   coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
            and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
            and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
            and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
            and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
            and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
    		and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab = 'N'
			and    doc.pagopa_ric_doc_subdoc_id is null
     		and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          accertamenti as
          (
          select ts.movgest_ts_id, rsog.soggetto_id
          from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs,
               siac_r_movgest_ts_sog rsog
          where mov.bil_id=bilancioId
          and   mov.movgest_tipo_id=movgestTipoId
          and   ts.movgest_id=mov.movgest_id
          and   ts.movgest_ts_tipo_id=movgestTsTipoId
          and   rs.movgest_ts_id=ts.movgest_ts_id
          and   rs.movgest_stato_id=movgestStatoId
          and   rsog.movgest_ts_id=ts.movgest_ts_id
          and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
          and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
          and   mov.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
          and   ts.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
          and   rs.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
          and   rsog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else s2.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id)
         ) query,pagopa_d_riconciliazione_errore errore
         where docUPD.ente_proprietario_id=enteProprietarioId
--         and   docUPD.pagopa_ric_flusso_stato_elab='N'
         and   docUPD.pagopa_ric_id=QUERY.pagopa_ric_id
         and   QUERY.pagopa_soggetto_id=pagoPaFlussoQuoteRec.pagopa_soggetto_id
         and   errore.ente_proprietario_id=docUPD.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   docUPD.data_cancellazione is null
         and   docUPD.validita_fine is null;

         strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );

         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione_doc S].'||strMessaggioBck;
         raise notice 'strMessaggio=%',strMessaggio;

         update pagopa_t_riconciliazione_doc doc
         set    pagopa_ric_doc_stato_elab='X',
			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                pagopa_ric_doc_subdoc_id=null,
                pagopa_ric_doc_movgest_ts_id=null,
                pagopa_ric_doc_provc_id=null,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(doc.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
         from pagopa_t_elaborazione_flusso flusso,
              pagopa_d_riconciliazione_errore errore, siac_t_subdoc sub
         where flusso.pagopa_elab_id=filePagoPaElabId
         and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   sub.doc_id=docId
         and   doc.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
         and   errore.ente_proprietario_id=flusso.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   flusso.data_cancellazione is null
         and   flusso.validita_fine is null
         and   sub.data_cancellazione is null
         and   sub.validita_fine is null;

		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );

	     strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione_doc N].'||strMessaggioBck;
         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_riconciliazione_doc  docUPD
         set    pagopa_ric_doc_stato_elab='X',
			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                pagopa_ric_doc_subdoc_id=null,
                pagopa_ric_doc_movgest_ts_id=null,
                pagopa_ric_doc_provc_id=null,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
         from
         (
		  with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef,
                    doc.pagopa_ric_id
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
            and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
            and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
                   coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
            and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
            and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
            and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
            and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
            and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
    		and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab = 'N'
			and    doc.pagopa_ric_doc_subdoc_id is null
     		and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          accertamenti as
          (
          select ts.movgest_ts_id, rsog.soggetto_id
          from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs,
               siac_r_movgest_ts_sog rsog
          where mov.bil_id=bilancioId
          and   mov.movgest_tipo_id=movgestTipoId
          and   ts.movgest_id=mov.movgest_id
          and   ts.movgest_ts_tipo_id=movgestTsTipoId
          and   rs.movgest_ts_id=ts.movgest_ts_id
          and   rs.movgest_stato_id=movgestStatoId
          and   rsog.movgest_ts_id=ts.movgest_ts_id
          and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
          and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
          and   mov.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
          and   ts.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
          and   rs.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
          and   rsog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else s2.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id)
         ) query,pagopa_d_riconciliazione_errore errore
         where docUPD.ente_proprietario_id=enteProprietarioId
--         and   docUPD.pagopa_ric_doc_stato_elab='N'
         and   docUPD.pagopa_ric_doc_id=QUERY.pagopa_ric_doc_id
         and   QUERY.pagopa_soggetto_id=pagoPaFlussoQuoteRec.pagopa_soggetto_id
         and   errore.ente_proprietario_id=docUPD.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   docUPD.data_cancellazione is null
         and   docUPD.validita_fine is null;

  		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );

         strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_movgest_ts].'||strMessaggioBck;
         raise notice 'strMessaggio=%',strMessaggio;

         delete from siac_r_subdoc_movgest_ts r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;

		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_attr].'||strMessaggioBck;
         delete from siac_r_subdoc_attr r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_atto_amm].'||strMessaggioBck;
         delete from siac_r_subdoc_atto_amm r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_prov_cassa].'||strMessaggioBck;
         delete from siac_r_subdoc_prov_cassa r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_subdoc].'||strMessaggioBck;
         delete from siac_t_subdoc doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_sog].'||strMessaggioBck;
         delete from siac_r_doc_sog doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_stato].'||strMessaggioBck;
         delete from siac_r_doc_stato doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_attr].'||strMessaggioBck;
         delete from siac_r_doc_attr doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_class].'||strMessaggioBck;
         delete from siac_r_doc_class doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_registrounico_doc].'||strMessaggioBck;
         delete from siac_t_registrounico_doc doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_subdoc_num].'||strMessaggioBck;
         delete from siac_t_subdoc_num doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_doc].'||strMessaggioBck;
         delete from siac_t_doc doc where doc.doc_id=docId;

		 strMessaggioLog:=strMessaggioFinale||strMessaggio||' - Continue fnc_pagopa_t_elaborazione_riconc_esegui.';
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );

       end if;


  end loop;


  strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - Fine ciclo caricamento documenti - '||strMessaggioFinale;
  insert into pagopa_t_elaborazione_log
  (
   pagopa_elab_id,
   pagopa_elab_file_id,
   pagopa_elab_log_operazione,
   ente_proprietario_id,
   login_operazione,
   data_creazione
  )
  values
  (
   filePagoPaElabId,
   null,
   strMessaggioLog,
   enteProprietarioId,
   loginOperazione,
   clock_timestamp()
  );

  -- richiamare function per gestire anomalie e errori su provvisori e flussi in generale
  -- su elaborazione
  -- controllare ogni flusso/provvisorio
  strMessaggio:='Chiamata fnc.';
  select * into  fncRec
  from fnc_pagopa_t_elaborazione_riconc_esegui_clean
  (
    filePagoPaElabId,
    annoBilancioElab,
    enteProprietarioId,
    loginOperazione,
    dataElaborazione
  );
  if fncRec.codiceRisultato=0 then
    if fncRec.pagopaBckSubdoc=true then
    	pagoPaCodeErr:=PAGOPA_ERR_36;
    end if;
  else
  	raise exception '%',fncRec.messaggiorisultato;
  end if;

  -- aggiornare siac_t_registrounico_doc_num
  codResult:=null;
  strMessaggio:='Aggiornamento numerazione su siac_t_registrounico_doc_num.';
  update siac_t_registrounico_doc_num num
  set    rudoc_registrazione_numero= coalesce(QUERY.rudoc_registrazione_numero,0),
         data_modifica=clock_timestamp(),
         login_operazione=num.login_operazione||'-'||loginOperazione
  from
  (
   select max(doc.rudoc_registrazione_numero::integer) rudoc_registrazione_numero
   from  siac_t_registrounico_doc doc
   where doc.ente_proprietario_id=enteProprietarioId
   and   doc.rudoc_registrazione_anno::integer=annoBilancio
   and   doc.data_cancellazione is null
   and   date_trunc('DAY',now())>=date_trunc('DAY',doc.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(doc.validita_fine,date_trunc('DAY',now())))
  ) QUERY
  where num.ente_proprietario_id=enteProprietarioId
  and   num.rudoc_registrazione_anno=annoBilancio
  and   num.data_cancellazione is null
  and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())));
 -- returning num.rudoc_num_id into codResult;
  --if codResult is null then
  --	raise exception 'Errore in fase di aggiornamento.';
  --end if;



  -- chiusura della elaborazione, siac_t_file per errore in generazione per aggiornare pagopa_ric_errore_id
  if coalesce(pagoPaCodeErr,' ') in (PAGOPA_ERR_30,PAGOPA_ERR_31,PAGOPA_ERR_32,PAGOPA_ERR_33,PAGOPA_ERR_36,PAGOPA_ERR_39) then
     strMessaggio:=' Aggiornamento pagopa_t_elaborazione.';
	 update pagopa_t_elaborazione elab
     set    data_modifica=clock_timestamp(),
            pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
            pagopa_elab_errore_id=err.pagopa_ric_errore_id,
            pagopa_elab_note=elab.pagopa_elab_note
            ||' AGGIORNAMENTO PER ERR.='||(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )::varchar||'.'
     from  pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
     where elab.pagopa_elab_id=filePagoPaElabId
     and   statonew.ente_proprietario_id=elab.ente_proprietario_id
     and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_ER_ST
     and   err.ente_proprietario_id=statonew.ente_proprietario_id
     and   err.pagopa_ric_errore_code=(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )
     and   elab.data_cancellazione is null
     and   elab.validita_fine is null;



    strMessaggio:=' Aggiornamento siac_t_file_pagopa.';
    update siac_t_file_pagopa file
    set    data_modifica=clock_timestamp(),
           file_pagopa_stato_id=stato.file_pagopa_stato_id,
           file_pagopa_errore_id=err.pagopa_ric_errore_id,
           file_pagopa_note=file.file_pagopa_note
                    ||' AGGIORNAMENTO PER ERR.='||(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )::varchar||'.',
           login_operazione=file.login_operazione||'-'||loginOperazione
    from  pagopa_r_elaborazione_file r,
          siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
    where r.pagopa_elab_id=filePagoPaElabId
    and   file.file_pagopa_id=r.file_pagopa_id
    and   stato.ente_proprietario_id=file.ente_proprietario_id
    and   err.ente_proprietario_id=stato.ente_proprietario_id
    and   err.pagopa_ric_errore_code=(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

  end if;

  strMessaggio:='Verifica dettaglio elaborati per chiusura pagopa_t_elaborazione.';
  codResult:=null;
  select 1 into codResult
  from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
  where flusso.pagopa_elab_id=filePagoPaElabId
  and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
  and   doc.pagopa_ric_doc_subdoc_id is not null
  and   doc.pagopa_ric_doc_stato_elab='S'
  and   flusso.data_cancellazione is null
  and   flusso.validita_fine is null
  and   doc.data_cancellazione is null
  and   doc.validita_fine is null;
  -- ELABORATO_KO_ST ELABORATO_OK_SE
  if codResult is not null then
  	  codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is null
      and   doc.pagopa_ric_doc_stato_elab in ('X','E','N')
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null;
      -- se ci sono S e X,E,N KO
      if codResult is not null then
            pagoPaCodeErr:=ELABORATO_KO_ST;
      -- se si sono solo S OK
      else  pagoPaCodeErr:=ELABORATO_OK_ST;
      end if;
  else -- se non esiste neanche un S allora elaborazione errata o scartata
	  codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is null
      and   doc.pagopa_ric_doc_stato_elab='X'
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null;
      if codResult is not null then
            pagoPaCodeErr:=ELABORATO_SCARTATO_ST;
      else  pagoPaCodeErr:=ELABORATO_ERRATO_ST;
      end if;
  end if;

  strMessaggio:='Aggiornamento pagopa_t_elaborazione in stato='||pagoPaCodeErr||'.';
  strMessaggioFinale:='CHIUSURA - '||upper(strMessaggioFinale||' '||strMessaggio);
  update pagopa_t_elaborazione elab
  set    data_modifica=clock_timestamp(),
  		 validita_fine=clock_timestamp(),
         pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
         pagopa_elab_note=strMessaggioFinale
  from  pagopa_d_elaborazione_stato statonew
  where elab.pagopa_elab_id=filePagoPaElabId
  and   statonew.ente_proprietario_id=elab.ente_proprietario_id
  and   statonew.pagopa_elab_stato_code=pagoPaCodeErr
  and   elab.data_cancellazione is null
  and   elab.validita_fine is null;

  strMessaggio:='Verifica dettaglio elaborati per chiusura siac_t_file_pagopa.';
  for elabRec in
  (
  select r.file_pagopa_id
  from pagopa_r_elaborazione_file r
  where r.pagopa_elab_id=filePagoPaElabId
  and   r.data_cancellazione is null
  and   r.validita_fine is null
  order by r.file_pagopa_id
  )
  loop

    -- chiusura per siac_t_file_pagopa
    -- capire se ho chiuso per bene pagopa_t_riconciliazione
    -- se esistono S Ok o in corso
    --    se esistono N non elaborati  IN_CORSO no chiusura
    --    se esistono X scartati IN_CORSO_SC no chiusura
    --    se esistono E errati   IN_CORSO_ER no chiusura
    --    se non esistono!=S FINE ELABORATO_Ok con chiusura
    -- se non esistono S, in corso
    --    se esistono N IN_CORSO no chiusura
    --    se esistono X scartati IN_CORSO_SC non chiusura
    --    se esistono E errati IN_CORSO_ER non chiusura
    strMessaggio:='Verifica dettaglio elaborati per chiusura siac_t_file_pagopa file_pagopa_id='||elabRec.file_pagopa_id::varchar||'.';
    codResult:=null;
    pagoPaCodeErr:=null;
    select 1 into codResult
    from  pagopa_t_riconciliazione ric
    where  ric.file_pagopa_id=elabRec.file_pagopa_id
    and   ric.pagopa_ric_flusso_stato_elab='S'
    and   ric.data_cancellazione is null
    and   ric.validita_fine is null;

    if codResult is not null then
      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='N'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='X'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_SC_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='E'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ER_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab!='S'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is null then
          pagoPaCodeErr:=ELABORATO_OK_ST;
      end if;

    else
      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='N'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='X'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_SC_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='E'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ER_ST;
      end if;

    end if;

    if pagoPaCodeErr is not null then
       strMessaggio:='Aggiornamento siac_t_file_pagopa in stato='||pagoPaCodeErr||'.';
       strMessaggioFinale:='CHIUSURA - '||upper(strMessaggioFinale||' '||strMessaggio);
       update siac_t_file_pagopa file
       set    data_modifica=clock_timestamp(),
              validita_fine=(case when pagoPaCodeErr=ELABORATO_OK_ST then clock_timestamp() else null end),
              file_pagopa_stato_id=stato.file_pagopa_stato_id,
              file_pagopa_note=file.file_pagopa_note||upper(strMessaggioFinale),
              login_operazione=file.login_operazione||'-'||loginOperazione
       from  siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
       where file.file_pagopa_id=elabRec.file_pagopa_id
       and   stato.ente_proprietario_id=file.ente_proprietario_id
       and   stato.file_pagopa_stato_code=pagoPaCodeErr;

    end if;

  end loop;

  messaggioRisultato:='OK VERIFICARE STATO ELAB. - '||upper(strMessaggioFinale);

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

--- 05.06.2019 Sofia SIAC-6893 - patch - fine 
