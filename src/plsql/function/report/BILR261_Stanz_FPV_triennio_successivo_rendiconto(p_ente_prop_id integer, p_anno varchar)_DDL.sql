/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR261_Stanz_FPV_triennio_successivo_rendiconto" (
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

/* 
	SIAC-8721 - 18/05/2022.
La funzione si chiamava "BILR147_Allegato_B_Fondo_Pluriennale_vincolato_Rend"
ed era richiamata nel menu' 2 dei report di Gestione come report BILR147.
Viene rinominata in "BILR261_Stanz_FPV_triennio_successivo_rendiconto" e
richiamata dal dal report BILR261 presente nel menu' 7 di Utilita'.
In pratica e' la versione vecchia del report BILR147 prima delle modifiche
per la SIAC-8250.

*/

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
          and i.movgest_id=a.movgest_id 
          and aa.avav_id=v.avav_id     
          and v.avav_tipo_id=vt.avav_tipo_id            
                --and aa.ente_proprietario_id=p_ente_prop_id
          and e.movgest_ts_id = aa.movgest_ts_b_id 
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
          and vt.avav_tipo_code like'FPV%'
          and e.movgest_ts_id_padre is NULL  
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
          and aa.data_cancellazione is null
          and aa.validita_fine is null            
          	--21/05/2020 SIAC-7643 
            --aggiunti i test sulle date che mancavano
          and a.data_cancellazione is null
          and a.validita_fine is NULL
          and b.data_cancellazione is null
          and b.validita_fine is NULL 
          and c.data_cancellazione is null
          and c.validita_fine is NULL 
          and e.data_cancellazione is null
          and e.validita_fine is NULL   
          and f.data_cancellazione is null
          and f.validita_fine is NULL   
          and g.data_cancellazione is null
          and g.validita_fine is NULL   
          and h.data_cancellazione is null
          and h.validita_fine is NULL   
          and m.data_cancellazione is null
          and m.validita_fine is NULL   
          and o.data_cancellazione is null
          and o.validita_fine is NULL   
          and p.data_cancellazione is null
          and p.validita_fine is NULL   
          and r.data_cancellazione is null
          and r.validita_fine is NULL   
          and v.data_cancellazione is null
          --and v.validita_fine is NULL 
          and vt.data_cancellazione is null
          and vt.validita_fine is NULL              
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
      siac_r_movgest_ts_atto_amm qa, siac_t_atto_amm ra ,
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
                        	--21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano
                        and a.validita_fine is null
                        and a.data_cancellazione is null
                        and e.validita_fine is null
                        and e.data_cancellazione is null
                        and g.validita_fine is null
                        and g.data_cancellazione is null
                        and h.validita_fine is null
                        and h.data_cancellazione is null
                        and o.validita_fine is null
                        and o.data_cancellazione is null
                        and p.validita_fine is null
                        and p.data_cancellazione is null
                        and r.validita_fine is null
                        and r.data_cancellazione is null
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
                        	--21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano                        
                        and a.validita_fine is null
                        and a.data_cancellazione is null
                        and g.validita_fine is null
                        and g.data_cancellazione is null
                        and h.validita_fine is null
                        and h.data_cancellazione is null
                        and m.validita_fine is null
                        and m.data_cancellazione is null
                        and o.validita_fine is null
                        and o.data_cancellazione is null
                        and p.validita_fine is null
                        and p.data_cancellazione is null
                        --and v.validita_fine is null
                        and v.data_cancellazione is null
                        and vt.validita_fine is null
                        and vt.data_cancellazione is null
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
                            --21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano                        
                        and a.validita_fine is null
                        and a.data_cancellazione is null
                        and g.validita_fine is null
                        and g.data_cancellazione is null
                        and h.validita_fine is null
                        and h.data_cancellazione is null
                        and m.validita_fine is null
                        and m.data_cancellazione is null
                        and o.validita_fine is null
                        and o.data_cancellazione is null
                        and p.validita_fine is null
                        and p.data_cancellazione is null
                        --and v.validita_fine is null
                        and v.data_cancellazione is null
                        and vt.validita_fine is null
                        and vt.data_cancellazione is null
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
                            --21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano                        
                        and a.validita_fine is null
                        and a.data_cancellazione is null
                        and g.validita_fine is null
                        and g.data_cancellazione is null
                        and h.validita_fine is null
                        and h.data_cancellazione is null
                        and m.validita_fine is null
                        and m.data_cancellazione is null
                        and o.validita_fine is null
                        and o.data_cancellazione is null
                        and p.validita_fine is null
                        and p.data_cancellazione is null
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
                            --21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano                        
                        and a.validita_fine is null
                        and a.data_cancellazione is null
                        and g.validita_fine is null
                        and g.data_cancellazione is null
                        and h.validita_fine is null
                        and h.data_cancellazione is null
                        and m.validita_fine is null
                        and m.data_cancellazione is null
                        and o.validita_fine is null
                        and o.data_cancellazione is null
                        and p.validita_fine is null
                        and p.data_cancellazione is null
                        --and v.validita_fine is null
                        and v.data_cancellazione is null
                        and vt.validita_fine is null
                        and vt.data_cancellazione is null                         
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
                            --21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano                        
                        and a.validita_fine is null
                        and a.data_cancellazione is null
                        and g.validita_fine is null
                        and g.data_cancellazione is null
                        and h.validita_fine is null
                        and h.data_cancellazione is null
                        and m.validita_fine is null
                        and m.data_cancellazione is null
                        and o.validita_fine is null
                        and o.data_cancellazione is null
                        and p.validita_fine is null
                        and p.data_cancellazione is null
                        --and v.validita_fine is null
                        and v.data_cancellazione is null
                        and vt.validita_fine is null
                        and vt.data_cancellazione is null                        
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
                            --21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano                        
                        and a.validita_fine is null
                        and a.data_cancellazione is null
                        and g.validita_fine is null
                        and g.data_cancellazione is null
                        and h.validita_fine is null
                        and h.data_cancellazione is null
                        and m.validita_fine is null
                        and m.data_cancellazione is null
                        and o.validita_fine is null
                        and o.data_cancellazione is null
                        and p.validita_fine is null
                        and p.data_cancellazione is null                      
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
                            --21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano                        
                        and a.validita_fine is null
                        and a.data_cancellazione is null
                        and g.validita_fine is null
                        and g.data_cancellazione is null
                        and h.validita_fine is null
                        and h.data_cancellazione is null
                        and m.validita_fine is null
                        and m.data_cancellazione is null
                        and o.validita_fine is null
                        and o.data_cancellazione is null
                        and p.validita_fine is null
                        and p.data_cancellazione is null
                        --and v.validita_fine is null
                        and v.data_cancellazione is null
                        and vt.validita_fine is null
                        and vt.data_cancellazione is null                        
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
                            --21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano                        
                        and a.validita_fine is null
                        and a.data_cancellazione is null
                        and g.validita_fine is null
                        and g.data_cancellazione is null
                        and h.validita_fine is null
                        and h.data_cancellazione is null
                        and m.validita_fine is null
                        and m.data_cancellazione is null
                        and o.validita_fine is null
                        and o.data_cancellazione is null
                        and p.validita_fine is null
                        and p.data_cancellazione is null
                        --and v.validita_fine is null
                        and v.data_cancellazione is null
                        and vt.validita_fine is null
                        and vt.data_cancellazione is null                        
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
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR261_Stanz_FPV_triennio_successivo_rendiconto" (p_ente_prop_id integer, p_anno varchar)
  OWNER TO siac;