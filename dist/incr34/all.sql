/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-6068: modifica da parte del CSI - Maurizio - INIZIO

DROP FUNCTION IF EXISTS siac."BILR147_Allegato_B_Fondo_Pluriennale_vincolato_Rend"(p_ente_prop_id integer, p_anno varchar);

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
coalesce(tbfpvprec.spese_fpv_anni_prec,0) as fondo_plur_anno_prec_a,
--coalesce(var_spese_impe_anni_prec_b,0) as spese_impe_anni_prec_b,
coalesce(tbimpaprec.spese_impe_anni_prec,0) as spese_impe_anni_prec_b,
coalesce(tbfpvprec.spese_fpv_anni_prec,0)-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0)  as quota_fond_plur_anni_prec_c,
coalesce(tbimpanno1.spese_da_impeg_anno1_d,0) spese_da_impeg_anno1_d,
coalesce(tbimpanno2.spese_da_impeg_anno2_e,0) spese_da_impeg_anno2_e,
coalesce(tbimpannisuc.spese_da_impeg_anni_succ_f,0) spese_da_impeg_anni_succ_f,
coalesce(tbriaccx.riacc_colonna_x,0) riacc_colonna_x,
coalesce(tbriaccy.riacc_colonna_y,0) riacc_colonna_y,
coalesce(tbfpvprec.spese_fpv_anni_prec,0)-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0) +
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
on tbclass.programma_code=tbimpannisuc.programma_code;

          
      
    
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

-- SIAC-6068: modifica da parte del CSI - Maurizio - FINE

-- SIAC-6070 INIZIO
DROP VIEW IF EXISTS siac.siac_v_dwh_allegato_atto_flux;

CREATE OR REPLACE VIEW siac.siac_v_dwh_allegato_atto_flux (
    attoamm_anno,
    attoamm_numero,
    attoamm_tipo_code,
    tipo_sac_atto_amm,
    sac_atto_amm,
    stato_atto_allegato,
    stato_desc_atto_allegato,
    validita_stato_atto_allegato,
    attoal_causale,
    attoal_data_invio_firma,
    ente_proprietario_id)
AS
SELECT d.attoamm_anno, d.attoamm_numero, e.attoamm_tipo_code,
    z.classif_tipo_code AS tipo_sac_atto_amm, y.classif_code AS sac_atto_amm,
    c.attoal_stato_code AS stato_atto_allegato,
    c.attoal_stato_desc AS stato_desc_atto_allegato,
    b.validita_inizio AS validita_stato_atto_allegato, a.attoal_causale,
    a.attoal_data_invio_firma, a.ente_proprietario_id
FROM siac_t_atto_allegato a, siac_r_atto_allegato_stato b,
    siac_d_atto_allegato_stato c,
    siac_t_atto_amm d
   LEFT JOIN siac_r_atto_amm_class x ON x.attoamm_id = d.attoamm_id AND
       x.data_cancellazione IS NULL
   LEFT JOIN siac_t_class y ON x.classif_id = y.classif_id
   LEFT JOIN siac_d_class_tipo z ON z.classif_tipo_id = y.classif_tipo_id AND
       (z.classif_tipo_code::text = ANY (ARRAY['CDC'::character varying::text, 'CDR'::character varying::text])),
    siac_d_atto_amm_tipo e
WHERE a.attoal_id = b.attoal_id AND b.attoal_stato_id = c.attoal_stato_id AND
    b.data_cancellazione IS NULL AND b.validita_fine IS NULL AND a.attoamm_id = d.attoamm_id AND e.attoamm_tipo_id = d.attoamm_tipo_id;
-- SIAC-6070 FINE


-- SIAC-5463 e SIAC-6071 - Report indicatori di rendiconto - Maurizio - INIZIO 

DROP FUNCTION IF EXISTS siac."BILR181_indic_ana_ent_rend_org_er"(p_ente_prop_id integer, p_anno varchar);

CREATE OR REPLACE FUNCTION siac."BILR181_indic_ana_ent_rend_org_er" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  id_titolo integer,
  code_titolo varchar,
  desc_titolo varchar,
  id_tipologia integer,
  code_tipologia varchar,
  desc_tipologia varchar,
  importo_accertato_a numeric,
  importo_prev_def_cassa_cs numeric,
  importo_res_attivi_rs numeric,
  importo_risc_conto_res_rr numeric,
  importo_risc_conto_comp_rc numeric,
  importo_tot_risc_tr numeric,
  importo_prev_def_comp_cp numeric,
  display_error varchar
) AS
$body$
DECLARE
  	DEF_NULL	constant varchar:=''; 
	RTN_MESSAGGIO varchar(1000):=DEF_NULL;

    annoBilInt integer;   
    bilId integer;
    
    
BEGIN
 
/*
	Funzione che estrae i dati di rendiconto di entrata dell'anno di bilancio in input
    suddivisi per titolo e tipologia.
    
    I dati restituiti sono:
    	- importo ACCERTAMENTI (A)
 		- importo PREVISIONI DEFINITIVE DI CASSA (CS)
  		- importo RESIDUI ATTIVI (RS)
  		- importo RISCOSSIONI IN C/RESIDUI (RR)
  		- importo RISCOSSIONI IN C/COMPETENZA (RC)
  		- importo TOTALE RISCOSSIONI (TR)
  		- importo PREVISIONI DEFINITIVE DI COMPETENZA (CP).
*/

annoBilInt:=p_anno::integer;
     
	/* Leggo l'id dell'anno del rendiconto */     
bilId:=0;     
select a.bil_id 
	INTO bilId
from siac_t_bil a, siac_t_periodo b
where a.periodo_id=b.periodo_id
and a.ente_proprietario_id=p_ente_prop_id
and b.anno = p_anno;
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Codice del bilancio non trovato';
    bilId:=0;
    display_error := 'Codice del bilancio non trovato per l''anno %', anno3;
    return next;
    return;
END IF;
   




return query 
with strut_bilancio as(
     		select  *
            from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno,'')),
capitoli as(
select cl.classif_id categoria_id,
  anno_eserc.anno anno_bilancio,
  e.elem_id
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
where ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and e.ente_proprietario_id			=	p_ente_prop_id
and e.bil_id in (bilId)
and tipo_elemento.elem_tipo_code 	= 	'CAP-EG'
and	stato_capitolo.elem_stato_code	=	'VA'
and ct.classif_tipo_code			=	'CATEGORIA'
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
and now() between rc.validita_inizio and COALESCE(rc.validita_fine,now())
and now() between r_cat_capitolo.validita_inizio and COALESCE(r_cat_capitolo.validita_fine,now())
),
 a_accertamenti as (
 	select capitolo.elem_id,
		sum (dt_movimento.movgest_ts_det_importo) importo_accert
    from 
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
      where capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id      
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id  
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id  
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and movimento.ente_proprietario_id   = p_ente_prop_id         
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      and movimento.movgest_anno = annoBilInt 
      and movimento.bil_id =bilId
      and tipo_mov.movgest_tipo_code    	= 'A' 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N       
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      and now() 
 		between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
      and now() 
 		between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now()) 
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
group by capitolo.elem_id),
rr_riscos_residui as (
select 		r_capitolo_ordinativo.elem_id,
            sum(ordinativo_imp.ord_ts_det_importo) importo_riscoss
from 		siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
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
    where 	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
        and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id 
        and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
        and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id   ------		           
        and	ordinativo.ord_id					=	ordinativo_det.ord_id
        and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
        and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
        and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
        and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
        and	ts_movimento.movgest_id				=	movimento.movgest_id    
        and	ordinativo.ente_proprietario_id	=	p_ente_prop_id
        and movimento.movgest_anno < annoBilInt 
        and movimento.bil_id =bilId
		and	tipo_ordinativo.ord_tipo_code		= 	'I'		------ incasso
        and	stato_ordinativo.ord_stato_code			<> 'A'      
        and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' 	---- importo attuala        
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
    and now()
between r_capitolo_ordinativo.validita_inizio 
    and COALESCE(r_capitolo_ordinativo.validita_fine,now())
    and now()
between r_stato_ordinativo.validita_inizio 
    and COALESCE(r_stato_ordinativo.validita_fine,now())
    and now()
between r_ordinativo_movgest.validita_inizio 
    and COALESCE(r_ordinativo_movgest.validita_fine,now())
        group by r_capitolo_ordinativo.elem_id) ,
rc_riscos_conto_comp as (
select 		r_capitolo_ordinativo.elem_id,
            sum(ordinativo_imp.ord_ts_det_importo) importo_riscoss
from 		siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
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
    where 	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
        and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id 
        and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
        and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
        and	ordinativo.ord_id					=	ordinativo_det.ord_id
        and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
        and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
        and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
        and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
        and	ts_movimento.movgest_id				=	movimento.movgest_id    
        and	ordinativo.ente_proprietario_id	=	p_ente_prop_id
        and movimento.movgest_anno = annoBilInt 
        and movimento.bil_id =bilId
		and	tipo_ordinativo.ord_tipo_code		= 	'I'		------ incasso
        and	stato_ordinativo.ord_stato_code			<> 'A'      
        and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' 	---- importo attuala
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
    and now()
between r_capitolo_ordinativo.validita_inizio 
    and COALESCE(r_capitolo_ordinativo.validita_fine,now())
    and now()
between r_stato_ordinativo.validita_inizio 
    and COALESCE(r_stato_ordinativo.validita_fine,now())
    and now()
between r_ordinativo_movgest.validita_inizio 
    and COALESCE(r_ordinativo_movgest.validita_fine,now())
        group by r_capitolo_ordinativo.elem_id),
prev_def_comp as (
select 		capitolo_importi.elem_id,
            sum(capitolo_importi.elem_det_importo) importo_prev_def_comp   
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						       
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno
        and	tipo_elemento.elem_tipo_code 		= 	'CAP-EG' 												
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo_imp_periodo.anno = 		p_anno
		and	cat_del_capitolo.elem_cat_code		=	'STD'
        and capitolo_imp_tipo.elem_det_tipo_code  = 'STA' -- stanziamento  (CP)
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
    group by capitolo_importi.elem_id),        
stanz_residui as (
select    
capitolo.elem_id,
sum (dt_movimento.movgest_ts_det_importo) importo_stanz_residui
    from       
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
      where capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id      
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id       
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id       
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id       
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and capitolo.ente_proprietario_id   = p_ente_prop_id
      and capitolo.bil_id = bilId      
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      and movimento.movgest_anno  	< p_anno::integer
      and tipo_mov.movgest_tipo_code    	= 'A'
      and tipo_stato.movgest_stato_code   in ('D','N') 
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'I' 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
   	  and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
      and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())      
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
group by capitolo.elem_id      ) ,     
prev_def_cassa as (
select 		capitolo_importi.elem_id,
            sum(capitolo_importi.elem_det_importo) importo_prev_def_cassa  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						       
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno
        and	tipo_elemento.elem_tipo_code 		= 	'CAP-EG' 												
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo_imp_periodo.anno = 		p_anno
		and	cat_del_capitolo.elem_cat_code		=	'STD'
        and capitolo_imp_tipo.elem_det_tipo_code  = 'SCA' --  cassa	(CS)
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
    group by capitolo_importi.elem_id)      
SELECT  strut_bilancio.titolo_id::integer id_titolo,
		strut_bilancio.titolo_code::varchar code_titolo, 
		strut_bilancio.titolo_desc::varchar desc_titolo, 
        strut_bilancio.tipologia_id::integer id_tipologia,
        strut_bilancio.tipologia_code::varchar code_tipologia,
        strut_bilancio.tipologia_desc::varchar desc_tipologia,
        sum(COALESCE(a_accertamenti.importo_accert,0))::numeric importo_accertato_a,  
        sum(COALESCE(prev_def_cassa.importo_prev_def_cassa,0))::numeric importo_prev_def_cassa_cs,    
        sum(COALESCE(stanz_residui.importo_stanz_residui,0))::numeric importo_res_attivi_rs,
        sum(COALESCE(rr_riscos_residui.importo_riscoss,0))::numeric importo_risc_conto_res_rr,
        sum(COALESCE(rc_riscos_conto_comp.importo_riscoss,0))::numeric importo_risc_conto_comp_rc,
        sum(COALESCE(rr_riscos_residui.importo_riscoss,0)+
        	COALESCE(rc_riscos_conto_comp.importo_riscoss,0))::numeric importo_tot_risc_tr,
        sum(COALESCE(prev_def_comp.importo_prev_def_comp,0))::numeric importo_prev_def_comp_cp,
        ''::varchar display_error
FROM strut_bilancio
	LEFT JOIN capitoli on strut_bilancio.categoria_id = capitoli.categoria_id
    LEFT JOIN a_accertamenti on a_accertamenti.elem_id = capitoli.elem_id
    LEFT JOIN rr_riscos_residui on rr_riscos_residui.elem_id = capitoli.elem_id   
    LEFT JOIN rc_riscos_conto_comp on rc_riscos_conto_comp.elem_id = capitoli.elem_id             
    LEFT JOIN prev_def_comp on prev_def_comp.elem_id = capitoli.elem_id   
    LEFT JOIN stanz_residui on stanz_residui.elem_id = capitoli.elem_id  
    LEFT JOIN prev_def_cassa on prev_def_cassa.elem_id = capitoli.elem_id                       
GROUP BY id_titolo, code_titolo, desc_titolo, 
		id_tipologia, code_tipologia, desc_tipologia
ORDER BY code_titolo, code_tipologia;
                    
EXCEPTION
	when no_data_found THEN
		raise notice 'Nessun dato trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;


DROP FUNCTION IF EXISTS siac."BILR184_indic_ana_spe_rend_org_er"(p_ente_prop_id integer, p_anno varchar);

CREATE OR REPLACE FUNCTION siac."BILR184_indic_ana_spe_rend_org_er" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  id_missione integer,
  code_missione varchar,
  desc_missione varchar,
  id_programma integer,
  code_programma varchar,
  desc_programma varchar,
  tipo_capitolo varchar,
  imp_impegnato_i numeric,
  imp_fondo_fpv numeric,
  imp_prev_def_comp_cp numeric,
  imp_residui_passivi_rs numeric,
  imp_prev_def_cassa_cs numeric,
  imp_pagam_comp_pc numeric,
  imp_pagam_res_pr numeric,
  imp_econ_comp_ecp numeric,
  display_error varchar
) AS
$body$
DECLARE
  	DEF_NULL	constant varchar:=''; 
	RTN_MESSAGGIO varchar(1000):=DEF_NULL;

    annoBilInt integer;   
    bilId integer;
    
    
BEGIN
 
/*
	Funzione che estrae i dati di rendiconto di spesa dell'anno di bilancio in input
    suddivisi per missione e programma.
    
    I dati restituiti sono:
  		- importo IMPEGNI (I);
        - importo FONDO PLURIENNALE VINCOLATO (FPV);
        - importo PREVISIONI DEFINITIVE DI COMPETENZA (CP);
  		- importo RESIDUI PASSIVI AL (RS) ;
        - importo PREVISIONI DEFINITIVE DI CASSA (CS);
        - importo PAGAMENTI IN C/COMPETENZA (PC);
        - importo PAGAMENTI IN C/RESIDUI (PR);
        - importo ECONOMIE DI COMPETENZA (ECP= CP-I-FPV).
*/

annoBilInt:=p_anno::integer;
     
	/* Leggo l'id dell'anno del rendiconto */     
bilId:=0;     
select a.bil_id 
	INTO bilId
from siac_t_bil a, siac_t_periodo b
where a.periodo_id=b.periodo_id
and a.ente_proprietario_id=p_ente_prop_id
and b.anno = p_anno;
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Codice del bilancio non trovato';
    bilId:=0;
    display_error := 'Codice del bilancio non trovato per l''anno %', anno3;
    return next;
    return;
END IF;
   




return query 
with strut_bilancio as(
     		select  *
            from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, p_anno,'')),
capitoli as(
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
        cat_del_capitolo.elem_cat_code tipo_capitolo,
       	capitolo.elem_id
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
where 		
	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 					    
    and capitolo.elem_id=	r_capitolo_stato.elem_id							
    and r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
    and capitolo.elem_id=r_capitolo_programma.elem_id							
    and capitolo.elem_id=r_capitolo_macroaggr.elem_id							
    and programma.classif_tipo_id=programma_tipo.classif_tipo_id 				
    and programma.classif_id=r_capitolo_programma.classif_id					    
    and macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				
    and macroaggr.classif_id=r_capitolo_macroaggr.classif_id						
    and capitolo.elem_id				=	r_cat_capitolo.elem_id				
	and r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		    
    and capitolo.ente_proprietario_id=p_ente_prop_id	
    and capitolo.bil_id =bilId												
    and programma_tipo.classif_tipo_code='PROGRAMMA'								
    and macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						
    and tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
    and stato_capitolo.elem_stato_code	='VA'     
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
  i_impegni as (
    select-- t_periodo.anno anno_bil,     
        sum(t_movgest_ts_det.movgest_ts_det_importo) importo_impegno,
        r_movgest_bil_elem.elem_id
     from siac_t_movgest t_movgest,
          siac_d_movgest_tipo d_movgest_tipo,
          siac_t_movgest_ts t_movgest_ts,
          siac_d_movgest_ts_tipo d_movgest_ts_tipo,
          siac_r_movgest_ts_stato r_movgest_ts_stato,
          siac_d_movgest_stato d_movgest_stato,
          siac_t_movgest_ts_det t_movgest_ts_det,
          siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
          siac_r_movgest_bil_elem r_movgest_bil_elem
    where d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
    and t_movgest_ts.movgest_id=t_movgest.movgest_id
    and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
    and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
    and d_movgest_stato.movgest_stato_id=r_movgest_ts_stato.movgest_stato_id
    and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
    and t_movgest_ts_det.movgest_ts_det_tipo_id=d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
    and r_movgest_bil_elem.movgest_id = t_movgest_ts.movgest_id
    and t_movgest.ente_proprietario_id =p_ente_prop_id
    and d_movgest_tipo.movgest_tipo_code='I'
    and d_movgest_ts_tipo.movgest_ts_tipo_code='T'
    and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
    --and d_movgest_stato.movgest_stato_code<>'A'
    -- D = DEFINITIVO
    -- N = DEFINITIVO NON LIQUIDABILE
    -- Devo prendere anche P - PROVVISORIO????
    and d_movgest_stato.movgest_stato_code in ('D','N') 
    and t_movgest.movgest_anno = annoBilInt
    and t_movgest.bil_id =bilId
    and now() BETWEEN d_movgest_stato.validita_inizio and COALESCE(d_movgest_stato.validita_fine,now())
    and r_movgest_ts_stato.validita_fine is NULL
    and t_movgest.data_cancellazione is null
    and d_movgest_tipo.data_cancellazione is null
    and t_movgest_ts.data_cancellazione is null
    and d_movgest_ts_tipo.data_cancellazione is null
    and r_movgest_ts_stato.data_cancellazione is null
    and r_movgest_bil_elem.data_cancellazione is null
    and t_movgest_ts_det.data_cancellazione is null
    and d_movgest_ts_det_tipo.data_cancellazione is null
  GROUP BY elem_id),
fpv as (
select t_bil_elem.elem_id, 
sum (coalesce(t_bil_elem_det.elem_det_importo,0)) as imp_fpv
from siac_t_bil_elem t_bil_elem,
	siac_r_bil_elem_stato r_bil_elem_stato, 
	siac_d_bil_elem_stato d_bil_elem_stato,
	siac_r_bil_elem_categoria r_bil_elem_categoria,
    siac_d_bil_elem_categoria d_bil_elem_categoria,
	siac_t_bil_elem_det t_bil_elem_det,
    siac_d_bil_elem_det_tipo d_bil_elem_det_tipo,
    siac_t_bil t_bil,
    siac_t_periodo t_periodo
where  r_bil_elem_stato.elem_id=t_bil_elem.elem_id
    and d_bil_elem_stato.elem_stato_id=r_bil_elem_stato.elem_stato_id
    and r_bil_elem_categoria.elem_id=t_bil_elem.elem_id 
    and d_bil_elem_categoria.elem_cat_id=r_bil_elem_categoria.elem_cat_id
    and t_bil_elem_det.elem_id=t_bil_elem.elem_id 
    and d_bil_elem_det_tipo.elem_det_tipo_id=t_bil_elem_det.elem_det_tipo_id
    and t_bil.bil_id=t_bil_elem.bil_id
    and t_bil.periodo_id=t_periodo.periodo_id
    and t_periodo.periodo_id=t_bil_elem_det.periodo_id
    and t_bil_elem.ente_proprietario_id=p_ente_prop_id	
    and t_periodo.anno  = p_anno
    and d_bil_elem_stato.elem_stato_code='VA'
    and d_bil_elem_categoria.elem_cat_code	in	('FPV','FPVCC','FPVSC')
    and d_bil_elem_det_tipo.elem_det_tipo_code='STA'
    and r_bil_elem_categoria.validita_fine is NULL
    and r_bil_elem_stato.validita_fine is NULL
    and t_bil_elem.data_cancellazione is null
    and r_bil_elem_stato.data_cancellazione is null
    and d_bil_elem_stato.data_cancellazione is null
    and r_bil_elem_categoria.data_cancellazione is null
    and d_bil_elem_categoria.data_cancellazione is null
    and t_bil_elem_det.data_cancellazione is null
    and d_bil_elem_det_tipo.data_cancellazione is null
    and t_bil.data_cancellazione is null
    and t_periodo.data_cancellazione is null
group by t_bil_elem.elem_id),  
cp_prev_def_comp as (
select t_bil_elem.elem_id, 
sum(coalesce (t_bil_elem_det.elem_det_importo,0))   as previsioni_definitive_comp
from siac_t_bil_elem t_bil_elem,
siac_r_bil_elem_stato r_bil_elem_stato, 
siac_d_bil_elem_stato d_bil_elem_stato,
siac_r_bil_elem_categoria r_bil_elem_categ,
siac_d_bil_elem_categoria d_bil_elem_categ,
siac_t_bil_elem_det t_bil_elem_det,
siac_d_bil_elem_det_tipo d_bil_elem_det_tipo
,siac_t_periodo t_periodo
where  r_bil_elem_stato.elem_id=t_bil_elem.elem_id
and d_bil_elem_stato.elem_stato_id=r_bil_elem_stato.elem_stato_id
and r_bil_elem_categ.elem_id=t_bil_elem.elem_id 
and d_bil_elem_categ.elem_cat_id=r_bil_elem_categ.elem_cat_id
and t_bil_elem_det.elem_id=t_bil_elem.elem_id 
and d_bil_elem_det_tipo.elem_det_tipo_id=t_bil_elem_det.elem_det_tipo_id
and t_periodo.periodo_id=t_bil_elem_det.periodo_id
and d_bil_elem_stato.elem_stato_code='VA'
and t_bil_elem.ente_proprietario_id=p_ente_prop_id
and d_bil_elem_categ.elem_cat_code	in	('STD','FSC','FPV',  'FPVCC','FPVSC')
and d_bil_elem_det_tipo.elem_det_tipo_code='STA'
and t_periodo.anno=p_anno
and t_bil_elem.bil_id = bilId
and r_bil_elem_categ.validita_fine is NULL
and r_bil_elem_stato.validita_fine is NULL
and t_bil_elem.data_cancellazione is null
and r_bil_elem_stato.data_cancellazione is null
and d_bil_elem_stato.data_cancellazione is null
and r_bil_elem_categ.data_cancellazione is null
and d_bil_elem_categ.data_cancellazione is null
and t_bil_elem_det.data_cancellazione is null
and d_bil_elem_det_tipo.data_cancellazione is null
and t_periodo.data_cancellazione is null
group by t_bil_elem.elem_id),
rs_residui_pass as(
select r_movgest_bil_elem.elem_id,
	sum(coalesce(t_movgest_ts_det.movgest_ts_det_importo,0)) residui_passivi 
from siac_t_movgest t_movgest,
	siac_t_movgest_ts t_movgest_ts,
    siac_t_movgest_ts_det t_movgest_ts_det,
	siac_r_movgest_bil_elem r_movgest_bil_elem,
    siac_d_movgest_tipo d_movgest_tipo,
    siac_r_movgest_ts_stato r_movgest_ts_stato,
    siac_d_movgest_stato d_movgest_stato,
	siac_d_movgest_ts_tipo d_movgest_ts_tipo,
    siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
    siac_t_bil t_bil,
    siac_t_periodo t_periodo
 where  t_movgest_ts.movgest_id=t_movgest.movgest_id
     and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
     and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
     and d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id  
     and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
     and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id  
     and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id 
     and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
     and t_bil.bil_id = t_movgest.bil_id
    and t_periodo.periodo_id= t_bil.periodo_id
     and t_movgest.ente_proprietario_id=p_ente_prop_id
     and t_movgest.movgest_anno < t_periodo.anno::integer
     and d_movgest_tipo.movgest_tipo_code='I'     
     and d_movgest_stato.movgest_stato_code in ('D','N')  
     and d_movgest_ts_tipo.movgest_ts_tipo_code='T'      
     and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='I'
     and t_periodo.anno = p_anno   
     and r_movgest_ts_stato.validita_fine is NULL
     and t_movgest.data_cancellazione is null
     and t_movgest_ts.data_cancellazione is null
     and t_movgest_ts_det.data_cancellazione is null
     and r_movgest_bil_elem.data_cancellazione is null
     and d_movgest_tipo.data_cancellazione is null
     and r_movgest_ts_stato.data_cancellazione is null
     and d_movgest_stato.data_cancellazione is null
     and d_movgest_ts_tipo.data_cancellazione is null
     and d_movgest_ts_det_tipo.data_cancellazione is null
     and t_bil.data_cancellazione is null
     and t_periodo.data_cancellazione is null     
group by r_movgest_bil_elem.elem_id),
cs_prev_def_cassa as (
select t_bil_elem.elem_id, 
sum(coalesce (t_bil_elem_det.elem_det_importo,0)) as previsioni_definitive_cassa
from siac_t_bil_elem t_bil_elem,
siac_r_bil_elem_stato r_bil_elem_stato, 
siac_d_bil_elem_stato d_bil_elem_stato,
siac_r_bil_elem_categoria r_bil_elem_categ,
siac_d_bil_elem_categoria d_bil_elem_categ,
siac_t_bil_elem_det t_bil_elem_det,
siac_d_bil_elem_det_tipo d_bil_elem_det_tipo,
siac_t_periodo t_periodo
where  r_bil_elem_stato.elem_id=t_bil_elem.elem_id
  and d_bil_elem_stato.elem_stato_id=r_bil_elem_stato.elem_stato_id
  and r_bil_elem_categ.elem_id=t_bil_elem.elem_id 
  and d_bil_elem_categ.elem_cat_id=r_bil_elem_categ.elem_cat_id
  and t_bil_elem_det.elem_id=t_bil_elem.elem_id 
  and d_bil_elem_det_tipo.elem_det_tipo_id=t_bil_elem_det.elem_det_tipo_id
  and t_periodo.periodo_id=t_bil_elem_det.periodo_id
  and t_bil_elem.ente_proprietario_id=p_ente_prop_id
  and t_periodo.anno = p_anno
  and t_bil_elem.bil_id = bilId
  and d_bil_elem_stato.elem_stato_code='VA'
  and d_bil_elem_categ.elem_cat_code	in	('STD','FSC')
  and d_bil_elem_det_tipo.elem_det_tipo_code='SCA'
  and r_bil_elem_stato.validita_fine is NULL
  and r_bil_elem_categ.validita_fine is NULL
  and t_bil_elem.data_cancellazione is null
  and r_bil_elem_stato.data_cancellazione is null
  and d_bil_elem_stato.data_cancellazione is null
  and r_bil_elem_categ.data_cancellazione is null
  and d_bil_elem_categ.data_cancellazione is null
  and t_bil_elem_det.data_cancellazione is null
  and d_bil_elem_det_tipo.data_cancellazione is null
  and t_periodo.data_cancellazione is null
group by t_bil_elem.elem_id),
pc_pagam_comp as (
select 
	r_ord_bil_elem.elem_id,
    sum(coalesce(t_ord_ts_det.ord_ts_det_importo,0)) pagamenti_competenza
 from  siac_t_movgest t_movgest, 
 	siac_t_movgest_ts t_movgest_ts,
    siac_r_liquidazione_movgest r_liq_movgest,
    siac_r_liquidazione_ord r_liq_ord,
	siac_t_ordinativo_ts t_ord_ts,
    siac_t_ordinativo t_ord,
    siac_d_ordinativo_tipo d_ord_tipo,
    siac_r_ordinativo_stato r_ord_stato,
	siac_d_ordinativo_stato d_ord_stato,
    siac_r_ordinativo_bil_elem r_ord_bil_elem,
    siac_t_ordinativo_ts_det t_ord_ts_det,
	siac_d_ordinativo_ts_det_tipo d_ord_ts_det_tipo
where t_movgest_ts.movgest_id=t_movgest.movgest_id
    and r_liq_movgest.movgest_ts_id=t_movgest_ts.movgest_ts_id
    and r_liq_ord.liq_id=r_liq_movgest.liq_id
    and t_ord.ord_id=t_ord_ts.ord_id
    and r_liq_ord.sord_id=t_ord_ts.ord_ts_id
    and t_ord.ord_id=t_ord_ts.ord_id
    and d_ord_tipo.ord_tipo_id=t_ord.ord_tipo_id
    and r_ord_stato.ord_id=t_ord.ord_id
    and d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
    and r_ord_bil_elem.ord_id=t_ord.ord_id
    and t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
    and d_ord_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
    and t_movgest.ente_proprietario_id=p_ente_prop_id
    and d_ord_tipo.ord_tipo_code = 'P'
    and d_ord_stato.ord_stato_code <> 'A'
    and d_ord_ts_det_tipo.ord_ts_det_tipo_code = 'A'
	and t_movgest.movgest_anno = annoBilInt 
    and t_movgest.bil_id=bilId
    and r_liq_movgest.validita_fine is NULL
    and r_liq_ord.validita_fine is NULL
    and r_ord_bil_elem.validita_fine is NULL
    and r_ord_stato.validita_fine is NULL
    and t_movgest.data_cancellazione is null
    and t_movgest_ts.data_cancellazione is null
    and r_liq_movgest.data_cancellazione is null
    and r_liq_ord.data_cancellazione is null
    and t_ord_ts.data_cancellazione is null
    and t_ord.data_cancellazione is null
    and d_ord_tipo.data_cancellazione is null
    and r_ord_stato.data_cancellazione is null
    and d_ord_stato.data_cancellazione is null
    and r_ord_bil_elem.data_cancellazione is null
    and t_ord_ts_det.data_cancellazione is null
    and d_ord_ts_det_tipo.data_cancellazione is null
group by r_ord_bil_elem.elem_id),
pr_pagamenti_residui as (
select 
	r_ord_bil_elem.elem_id,
	sum(coalesce(t_ord_ts_det.ord_ts_det_importo,0)) pagamenti_residui
 from  siac_t_movgest t_movgest, 
 	siac_t_movgest_ts t_movgest_ts,
    siac_r_liquidazione_movgest r_liq_movgest,
    siac_r_liquidazione_ord r_liq_ord,
	siac_t_ordinativo_ts t_ord_ts,
    siac_t_ordinativo t_ord,
    siac_d_ordinativo_tipo d_ord_tipo,
    siac_r_ordinativo_stato r_ord_stato,
	siac_d_ordinativo_stato d_ord_stato,
    siac_r_ordinativo_bil_elem r_ord_bil_elem,
    siac_t_ordinativo_ts_det t_ord_ts_det,
	siac_d_ordinativo_ts_det_tipo d_ord_ts_det_tipo,
    siac_t_bil t_bil,
    siac_t_periodo t_periodo
where t_movgest_ts.movgest_id=t_movgest.movgest_id
    and r_liq_movgest.movgest_ts_id=t_movgest_ts.movgest_ts_id
    and r_liq_ord.liq_id=r_liq_movgest.liq_id
    and r_liq_ord.sord_id=t_ord_ts.ord_ts_id
    and t_ord.ord_id=t_ord_ts.ord_id
    and d_ord_tipo.ord_tipo_id=t_ord.ord_tipo_id
    and t_ord.ord_id=t_ord_ts.ord_id
    and d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
    and r_ord_bil_elem.ord_id=t_ord.ord_id
    and t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
    and d_ord_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
    and r_ord_stato.ord_id=t_ord.ord_id    
    and t_bil.bil_id = t_movgest.bil_id
    and t_periodo.periodo_id= t_bil.periodo_id
    and t_movgest.ente_proprietario_id=p_ente_prop_id
    and t_movgest.movgest_anno < t_periodo.anno::integer
    and d_ord_tipo.ord_tipo_code='P'        
    and d_ord_stato.ord_stato_code<>'A'
    and d_ord_ts_det_tipo.ord_ts_det_tipo_code='A'
    and t_periodo.anno = p_anno 
    and r_liq_movgest.validita_fine is NULL
    and r_liq_ord.validita_fine is NULL
    and r_ord_bil_elem.validita_fine is NULL
    and r_ord_stato.validita_fine is NULL
    and t_movgest.data_cancellazione is null
    and t_movgest_ts.data_cancellazione is null
    and r_liq_movgest.data_cancellazione is null
    and r_liq_ord.data_cancellazione is null
    and t_ord_ts.data_cancellazione is null
    and t_ord.data_cancellazione is null
    and d_ord_tipo.data_cancellazione is null
    and r_ord_stato.data_cancellazione is null
    and d_ord_stato.data_cancellazione is null
    and r_ord_bil_elem.data_cancellazione is null
    and t_ord_ts_det.data_cancellazione is null
    and d_ord_ts_det_tipo.data_cancellazione is null
    and t_bil.data_cancellazione is null
    and t_periodo.data_cancellazione is null
group by r_ord_bil_elem.elem_id)
SELECT  strut_bilancio.missione_id::integer id_missione,
		strut_bilancio.missione_code::varchar code_missione, 
		strut_bilancio.missione_desc::varchar desc_missione, 
        strut_bilancio.programma_id::integer id_programma,
        strut_bilancio.programma_code::varchar code_programma,
        strut_bilancio.programma_desc::varchar desc_programma,
        capitoli.tipo_capitolo::varchar tipo_capitolo,
        sum(COALESCE(i_impegni.importo_impegno,0))::numeric imp_impegnato_i,  
        sum(COALESCE(fpv.imp_fpv,0))::numeric imp_fondo_fpv,    
        sum(COALESCE(cp_prev_def_comp.previsioni_definitive_comp,0))::numeric imp_prev_def_comp_cp,
        sum(COALESCE(rs_residui_pass.residui_passivi,0))::numeric imp_residui_passivi_rs,
        sum(COALESCE(cs_prev_def_cassa.previsioni_definitive_cassa,0))::numeric imp_prev_def_cassa_cs,      
        sum(COALESCE(pc_pagam_comp.pagamenti_competenza,0))::numeric imp_pagam_comp_pc,         
        sum(COALESCE(pr_pagamenti_residui.pagamenti_residui,0))::numeric imp_pagam_res_pr, 
        sum(COALESCE(cp_prev_def_comp.previsioni_definitive_comp,0) -
        	COALESCE(i_impegni.importo_impegno,0) -
            COALESCE(fpv.imp_fpv,0)) imp_econ_comp_ecp,                        
        ''::varchar display_error
FROM strut_bilancio
	LEFT JOIN capitoli on (strut_bilancio.programma_id = capitoli.programma_id
    						AND strut_bilancio.macroag_id = capitoli.macroaggregato_id)
    LEFT JOIN i_impegni on i_impegni.elem_id = capitoli.elem_id
    LEFT JOIN fpv 	on fpv.elem_id = capitoli.elem_id    
    LEFT JOIN cp_prev_def_comp on cp_prev_def_comp.elem_id = capitoli.elem_id   
	LEFT JOIN rs_residui_pass on rs_residui_pass.elem_id = capitoli.elem_id             
    LEFT JOIN cs_prev_def_cassa on cs_prev_def_cassa.elem_id = capitoli.elem_id   
    LEFT JOIN pc_pagam_comp on pc_pagam_comp.elem_id = capitoli.elem_id  
    LEFT JOIN pr_pagamenti_residui on pr_pagamenti_residui.elem_id = capitoli.elem_id                      
GROUP BY id_missione, code_missione, desc_missione, 
		id_programma, code_programma, desc_programma, capitoli.tipo_capitolo
ORDER BY code_missione, code_programma;
                    
EXCEPTION
	when no_data_found THEN
		raise notice 'Nessun dato trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

DROP FUNCTION IF EXISTS siac."BILR186_indic_sint_ent_rend_org_er"(p_ente_prop_id integer, p_anno varchar);

CREATE OR REPLACE FUNCTION siac."BILR186_indic_sint_ent_rend_org_er" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  id_titolo integer,
  code_titolo varchar,
  desc_titolo varchar,
  id_tipologia integer,
  code_tipologia varchar,
  desc_tipologia varchar,
  code_categoria varchar,
  cap_id integer,
  pdce_code varchar,
  cap_dubbia_esig boolean,
  importo_accertato_a numeric,
  importo_prev_def_cassa_cs numeric,
  importo_res_attivi_rs numeric,
  importo_risc_conto_res_rr numeric,
  importo_risc_conto_comp_rc numeric,
  importo_tot_risc_tr numeric,
  importo_prev_def_comp_cp numeric,
  importo_riacc_residui_r numeric,
  importo_res_attivi_eser_comp_ec numeric,
  importo_tot_residui_attivi_ripor_tr numeric,
  display_error varchar
) AS
$body$
DECLARE
  	DEF_NULL	constant varchar:=''; 
	RTN_MESSAGGIO varchar(1000):=DEF_NULL;

    annoBilInt integer;   
    bilId integer;
    
    
BEGIN
 
/*
	Funzione che estrae i dati di rendiconto di entrata dell'anno di bilancio in input
    suddivisi per titolo, tipologia, capitolo, pdce.
    
    I dati restituiti sono:
    	- importo ACCERTAMENTI (A)
 		- importo PREVISIONI DEFINITIVE DI CASSA (CS)
  		- importo RESIDUI ATTIVI (RS)
  		- importo RISCOSSIONI IN C/RESIDUI (RR)
  		- importo RISCOSSIONI IN C/COMPETENZA (RC)
  		- importo TOTALE RISCOSSIONI (TR)
  		- importo PREVISIONI DEFINITIVE DI COMPETENZA (CP)
        - importo RIACCERTAMENTI RESIDUI (R)
        - importo RESIDUI ATTIVI DA ESERCIZIO DI COMPETENZA (EC=A-RC)
        - importo TOTALE RESIDUI ATTIVI DA RIPORTARE (TR=EP+EC).
*/

annoBilInt:=p_anno::integer;
     
	/* Leggo l'id dell'anno del rendiconto */     
bilId:=0;     
select a.bil_id 
	INTO bilId
from siac_t_bil a, siac_t_periodo b
where a.periodo_id=b.periodo_id
and a.ente_proprietario_id=p_ente_prop_id
and b.anno = p_anno;
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Codice del bilancio non trovato';
    bilId:=0;
    display_error := 'Codice del bilancio non trovato per l''anno %', anno3;
    return next;
    return;
END IF;
   




return query 
with strut_bilancio as(
     		select  *
            from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno,'')),
capitoli as(
select cl.classif_id categoria_id,
  anno_eserc.anno anno_bilancio,
  e.elem_id,
  r_bil_elem_dubbia_esig.bil_elem_acc_fde_id
 from 	siac_r_bil_elem_class rc,
 		siac_t_bil_elem e
        	LEFT JOIN siac_r_bil_elem_acc_fondi_dubbia_esig r_bil_elem_dubbia_esig
        	on (r_bil_elem_dubbia_esig.elem_id=e.elem_id
            	and r_bil_elem_dubbia_esig.data_cancellazione IS NULL),
        siac_d_class_tipo ct,
		siac_t_class cl,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and e.ente_proprietario_id			=	p_ente_prop_id
and e.bil_id in (bilId)
and tipo_elemento.elem_tipo_code 	= 	'CAP-EG'
and	stato_capitolo.elem_stato_code	=	'VA'
and ct.classif_tipo_code			=	'CATEGORIA'
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
and now() between rc.validita_inizio and COALESCE(rc.validita_fine,now())
and now() between r_cat_capitolo.validita_inizio and COALESCE(r_cat_capitolo.validita_fine,now())
),
 a_accertamenti as (
 	select capitolo.elem_id,
		sum (dt_movimento.movgest_ts_det_importo) importo_accert
    from 
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
      where capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id      
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id  
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id  
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and movimento.ente_proprietario_id   = p_ente_prop_id         
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      and movimento.movgest_anno = annoBilInt 
      and movimento.bil_id =bilId
      and tipo_mov.movgest_tipo_code    	= 'A' 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N       
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      and now() 
 		between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
      and now() 
 		between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now()) 
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
group by capitolo.elem_id),
rr_riscos_residui as (
select 		r_capitolo_ordinativo.elem_id,
            sum(ordinativo_imp.ord_ts_det_importo) importo_riscoss
from 		siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
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
    where 	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
        and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id 
        and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
        and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id   ------		           
        and	ordinativo.ord_id					=	ordinativo_det.ord_id
        and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
        and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
        and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
        and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
        and	ts_movimento.movgest_id				=	movimento.movgest_id    
        and	ordinativo.ente_proprietario_id	=	p_ente_prop_id
        and movimento.movgest_anno < annoBilInt 
        and movimento.bil_id =bilId
		and	tipo_ordinativo.ord_tipo_code		= 	'I'		------ incasso
        and	stato_ordinativo.ord_stato_code			<> 'A'      
        and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' 	---- importo attuala        
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
    and now()
between r_capitolo_ordinativo.validita_inizio 
    and COALESCE(r_capitolo_ordinativo.validita_fine,now())
    and now()
between r_stato_ordinativo.validita_inizio 
    and COALESCE(r_stato_ordinativo.validita_fine,now())
    and now()
between r_ordinativo_movgest.validita_inizio 
    and COALESCE(r_ordinativo_movgest.validita_fine,now())
        group by r_capitolo_ordinativo.elem_id) ,
rc_riscos_conto_comp as (
select 		r_capitolo_ordinativo.elem_id,
            sum(ordinativo_imp.ord_ts_det_importo) importo_riscoss
from 		siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
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
    where 	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
        and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id 
        and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
        and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
        and	ordinativo.ord_id					=	ordinativo_det.ord_id
        and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
        and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
        and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
        and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
        and	ts_movimento.movgest_id				=	movimento.movgest_id    
        and	ordinativo.ente_proprietario_id	=	p_ente_prop_id
        and movimento.movgest_anno = annoBilInt 
        and movimento.bil_id =bilId
		and	tipo_ordinativo.ord_tipo_code		= 	'I'		------ incasso
        and	stato_ordinativo.ord_stato_code			<> 'A'      
        and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' 	---- importo attuala
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
    and now()
between r_capitolo_ordinativo.validita_inizio 
    and COALESCE(r_capitolo_ordinativo.validita_fine,now())
    and now()
between r_stato_ordinativo.validita_inizio 
    and COALESCE(r_stato_ordinativo.validita_fine,now())
    and now()
between r_ordinativo_movgest.validita_inizio 
    and COALESCE(r_ordinativo_movgest.validita_fine,now())
        group by r_capitolo_ordinativo.elem_id),
prev_def_comp as (
select 		capitolo_importi.elem_id,
            sum(capitolo_importi.elem_det_importo) importo_prev_def_comp   
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						       
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno
        and	tipo_elemento.elem_tipo_code 		= 	'CAP-EG' 												
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo_imp_periodo.anno = 		p_anno
		and	cat_del_capitolo.elem_cat_code		=	'STD'
        and capitolo_imp_tipo.elem_det_tipo_code  = 'STA' -- stanziamento  (CP)
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
    group by capitolo_importi.elem_id),        
stanz_residui as (
select    
capitolo.elem_id,
sum (dt_movimento.movgest_ts_det_importo) importo_stanz_residui
    from       
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
      where capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id      
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id       
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id       
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id       
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and capitolo.ente_proprietario_id   = p_ente_prop_id
      and capitolo.bil_id = bilId      
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      and movimento.movgest_anno  	< p_anno::integer
      and tipo_mov.movgest_tipo_code    	= 'A'
      and tipo_stato.movgest_stato_code   in ('D','N') 
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'I' 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
   	  and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
      and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())      
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
group by capitolo.elem_id      ) ,     
prev_def_cassa as (
select 		capitolo_importi.elem_id,
            sum(capitolo_importi.elem_det_importo) importo_prev_def_cassa  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						       
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno
        and	tipo_elemento.elem_tipo_code 		= 	'CAP-EG' 												
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo_imp_periodo.anno = 		p_anno
		and	cat_del_capitolo.elem_cat_code		=	'STD'
        and capitolo_imp_tipo.elem_det_tipo_code  = 'SCA' --  cassa	(CS)
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
    group by capitolo_importi.elem_id),
riacc_residui as (
select    
   capitolo.elem_id,
   sum (t_movgest_ts_det_mod.movgest_ts_det_importo) importo_riacc_res
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
      siac_d_movgest_ts_det_tipo  dt_mov_tipo ,
      siac_t_modifica t_modifica,
      siac_r_modifica_stato r_mod_stato,
      siac_d_modifica_stato d_mod_stato,
      siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
      where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
      and movimento.bil_id					=	bilancio.bil_id
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and bilancio.bil_id      				=	capitolo.bil_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
      and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
      and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and r_mod_stato.mod_id=t_modifica.mod_id
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id                                    
      and anno_eserc.anno       			=   p_anno 
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      and movimento.movgest_anno   	< 		annoBilInt
      and tipo_mov.movgest_tipo_code    	= 'A' 
      and tipo_stato.movgest_stato_code   in ('D','N') 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      and d_mod_stato.mod_stato_code='V'      
	  and now()       
		between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
 	  and now() 
 		between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
	  and now()
 		between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
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
      and t_movgest_ts_det_mod.data_cancellazione    is null
      and r_mod_stato.data_cancellazione    is null
      and t_modifica.data_cancellazione    is null      
group by capitolo.elem_id),    
conto_pdce as(
        select t_class_upb.classif_code, r_capitolo_upb.elem_id
        	from 
                siac_d_class_tipo	class_upb,
                siac_t_class		t_class_upb,
                siac_r_bil_elem_class r_capitolo_upb
        	where 		
                t_class_upb.classif_tipo_id=class_upb.classif_tipo_id 
                and t_class_upb.classif_id=r_capitolo_upb.classif_id
                and t_class_upb.ente_proprietario_id=p_ente_prop_id
                and class_upb.classif_tipo_code like 'PDC_%'
                and	class_upb.data_cancellazione 			is null
                and t_class_upb.data_cancellazione 			is null
                and r_capitolo_upb.data_cancellazione 			is null)           
SELECT  strut_bilancio.titolo_id::integer id_titolo,
		strut_bilancio.titolo_code::varchar code_titolo, 
		strut_bilancio.titolo_desc::varchar desc_titolo, 
        strut_bilancio.tipologia_id::integer id_tipologia,
        strut_bilancio.tipologia_code::varchar code_tipologia,
        strut_bilancio.tipologia_desc::varchar desc_tipologia,
        strut_bilancio.categoria_code::varchar code_categoria,
        capitoli.elem_id::integer cap_id,
        conto_pdce.classif_code::varchar pdce_code,
        case when capitoli.bil_elem_acc_fde_id IS NULL 
        	then FALSE::boolean
            else true::boolean end cap_dubbia_esig,
        sum(COALESCE(a_accertamenti.importo_accert,0))::numeric importo_accertato_a,  
        sum(COALESCE(prev_def_cassa.importo_prev_def_cassa,0))::numeric importo_prev_def_cassa_cs,    
        sum(COALESCE(stanz_residui.importo_stanz_residui,0))::numeric importo_res_attivi_rs,
        sum(COALESCE(rr_riscos_residui.importo_riscoss,0))::numeric importo_risc_conto_res_rr,
        sum(COALESCE(rc_riscos_conto_comp.importo_riscoss,0))::numeric importo_risc_conto_comp_rc,
        sum(COALESCE(rr_riscos_residui.importo_riscoss,0)+
        	COALESCE(rc_riscos_conto_comp.importo_riscoss,0))::numeric importo_tot_risc_tr,
        sum(COALESCE(prev_def_comp.importo_prev_def_comp,0))::numeric importo_prev_def_comp_cp,
        sum(COALESCE(riacc_residui.importo_riacc_res,0))::numeric importo_riacc_residui_r,
        sum(COALESCE(a_accertamenti.importo_accert,0) -
        	COALESCE(rc_riscos_conto_comp.importo_riscoss,0)) importo_res_attivi_eser_comp_ec,        
        sum(COALESCE(stanz_residui.importo_stanz_residui,0) -
        	COALESCE(rr_riscos_residui.importo_riscoss,0) +
            COALESCE(riacc_residui.importo_riacc_res,0) +
            COALESCE(a_accertamenti.importo_accert,0) -
            COALESCE(rc_riscos_conto_comp.importo_riscoss,0)) importo_tot_residui_attivi_ripor_tr,        
        ''::varchar display_error
FROM strut_bilancio
	LEFT JOIN capitoli on strut_bilancio.categoria_id = capitoli.categoria_id
    LEFT JOIN a_accertamenti on a_accertamenti.elem_id = capitoli.elem_id
    LEFT JOIN rr_riscos_residui on rr_riscos_residui.elem_id = capitoli.elem_id   
    LEFT JOIN rc_riscos_conto_comp on rc_riscos_conto_comp.elem_id = capitoli.elem_id             
    LEFT JOIN prev_def_comp on prev_def_comp.elem_id = capitoli.elem_id   
    LEFT JOIN stanz_residui on stanz_residui.elem_id = capitoli.elem_id  
    LEFT JOIN prev_def_cassa on prev_def_cassa.elem_id = capitoli.elem_id   
    LEFT JOIN riacc_residui on riacc_residui.elem_id = capitoli.elem_id 
    LEFT JOIN conto_pdce on conto_pdce.elem_id = capitoli.elem_id                            
GROUP BY id_titolo, code_titolo, desc_titolo, 
		id_tipologia, code_tipologia, desc_tipologia, code_categoria,
        cap_id, pdce_code, cap_dubbia_esig
ORDER BY code_titolo, code_tipologia;
                    
EXCEPTION
	when no_data_found THEN
		raise notice 'Nessun dato trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

DROP FUNCTION IF EXISTS siac."BILR186_indic_sint_spe_rend_FPV_anno_prec"(p_ente_prop_id integer, p_anno varchar);

CREATE OR REPLACE FUNCTION siac."BILR186_indic_sint_spe_rend_FPV_anno_prec" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  id_missione integer,
  code_missione varchar,
  desc_missione varchar,
  id_programma integer,
  code_programma varchar,
  desc_programma varchar,
  code_titolo varchar,
  code_macroagg varchar,
  tipo_capitolo varchar,
  cap_id integer,
  pdce_code varchar,
  spese_fpv_anni_prec numeric,
  display_error varchar
) AS
$body$
DECLARE
  	DEF_NULL	constant varchar:=''; 
	RTN_MESSAGGIO varchar(1000):=DEF_NULL;

    annoBilInt integer;   
    annoBilAnnoPrecStr varchar;
    bilId integer;
    
    
BEGIN
 
/*
	Funzione che estrae i dati di rendiconto di spesa FPV dell'anno di bilancio 
    precedente quello in input suddivisi per missione, programma, titolo, macroaggregato 
    e capitolo.
    
    I dati restituiti sono:
  		- importo FPV.
*/

annoBilInt:=p_anno::integer-1;
annoBilAnnoPrecStr:=(p_anno::INTEGER-1)::varchar;
     
	/* Leggo l'id dell'anno del rendiconto -1 */     
bilId:=0;     
select a.bil_id 
	INTO bilId
from siac_t_bil a, siac_t_periodo b
where a.periodo_id=b.periodo_id
and a.ente_proprietario_id=p_ente_prop_id
and b.anno = annoBilAnnoPrecStr;
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Codice del bilancio non trovato';
    bilId:=0;
    display_error := 'Codice del bilancio non trovato per l''anno %', anno3;
    return next;
    return;
END IF;
   

return query 
with strut_bilancio as(
     		select  *
            from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, annoBilAnnoPrecStr,'')),
capitoli as(
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
        cat_del_capitolo.elem_cat_code tipo_capitolo,
       	capitolo.elem_id
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
where 		
	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 					    
    and capitolo.elem_id=	r_capitolo_stato.elem_id							
    and r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
    and capitolo.elem_id=r_capitolo_programma.elem_id							
    and capitolo.elem_id=r_capitolo_macroaggr.elem_id							
    and programma.classif_tipo_id=programma_tipo.classif_tipo_id 				
    and programma.classif_id=r_capitolo_programma.classif_id					    
    and macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				
    and macroaggr.classif_id=r_capitolo_macroaggr.classif_id						
    and capitolo.elem_id				=	r_cat_capitolo.elem_id				
	and r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		    
    and capitolo.ente_proprietario_id=p_ente_prop_id	
    and capitolo.bil_id =bilId												
    and programma_tipo.classif_tipo_code='PROGRAMMA'								
    and macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						
    and tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
    and stato_capitolo.elem_stato_code	='VA'     
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
fpv as (
select t_bil_elem.elem_id, 
sum (coalesce(t_bil_elem_det.elem_det_importo,0)) as imp_fpv
from siac_t_bil_elem t_bil_elem,
	siac_r_bil_elem_stato r_bil_elem_stato, 
	siac_d_bil_elem_stato d_bil_elem_stato,
	siac_r_bil_elem_categoria r_bil_elem_categoria,
    siac_d_bil_elem_categoria d_bil_elem_categoria,
	siac_t_bil_elem_det t_bil_elem_det,
    siac_d_bil_elem_det_tipo d_bil_elem_det_tipo,
    siac_t_bil t_bil,
    siac_t_periodo t_periodo
where  r_bil_elem_stato.elem_id=t_bil_elem.elem_id
    and d_bil_elem_stato.elem_stato_id=r_bil_elem_stato.elem_stato_id
    and r_bil_elem_categoria.elem_id=t_bil_elem.elem_id 
    and d_bil_elem_categoria.elem_cat_id=r_bil_elem_categoria.elem_cat_id
    and t_bil_elem_det.elem_id=t_bil_elem.elem_id 
    and d_bil_elem_det_tipo.elem_det_tipo_id=t_bil_elem_det.elem_det_tipo_id
    and t_bil.bil_id=t_bil_elem.bil_id
    and t_bil.periodo_id=t_periodo.periodo_id
    and t_periodo.periodo_id=t_bil_elem_det.periodo_id
    and t_bil_elem.ente_proprietario_id=p_ente_prop_id	
    and t_periodo.anno  = annoBilAnnoPrecStr
    and d_bil_elem_stato.elem_stato_code='VA'
    and d_bil_elem_categoria.elem_cat_code	in	('FPV','FPVCC','FPVSC')
    and d_bil_elem_det_tipo.elem_det_tipo_code='STA'
    and r_bil_elem_categoria.validita_fine is NULL
    and r_bil_elem_stato.validita_fine is NULL
    and t_bil_elem.data_cancellazione is null
    and r_bil_elem_stato.data_cancellazione is null
    and d_bil_elem_stato.data_cancellazione is null
    and r_bil_elem_categoria.data_cancellazione is null
    and d_bil_elem_categoria.data_cancellazione is null
    and t_bil_elem_det.data_cancellazione is null
    and d_bil_elem_det_tipo.data_cancellazione is null
    and t_bil.data_cancellazione is null
    and t_periodo.data_cancellazione is null
group by t_bil_elem.elem_id),
conto_pdce as(
        select t_class_upb.classif_code, r_capitolo_upb.elem_id
        	from 
                siac_d_class_tipo	class_upb,
                siac_t_class		t_class_upb,
                siac_r_bil_elem_class r_capitolo_upb
        	where 		
                t_class_upb.classif_tipo_id=class_upb.classif_tipo_id 
                and t_class_upb.classif_id=r_capitolo_upb.classif_id
                and t_class_upb.ente_proprietario_id=p_ente_prop_id
                and class_upb.classif_tipo_code like 'PDC_%'
                and	class_upb.data_cancellazione 			is null
                and t_class_upb.data_cancellazione 			is null)          
SELECT  strut_bilancio.missione_id::integer id_missione,
		strut_bilancio.missione_code::varchar code_missione, 
		strut_bilancio.missione_desc::varchar desc_missione, 
        strut_bilancio.programma_id::integer id_programma,
        strut_bilancio.programma_code::varchar code_programma,
        strut_bilancio.programma_desc::varchar desc_programma,
        strut_bilancio.titusc_code::varchar code_titolo,
        strut_bilancio.macroag_code::varchar  code_macroagg,
        case when capitoli.tipo_capitolo = 'FPVC'
        	then 'FPV'::varchar
            else capitoli.tipo_capitolo::varchar end tipo_capitolo,
        capitoli.elem_id::integer cap_id,
        conto_pdce.classif_code::varchar pdce_code,            
        sum(COALESCE(fpv.imp_fpv,0))::numeric spese_fpv_anni_prec,                    
        ''::varchar display_error
FROM strut_bilancio
	LEFT JOIN capitoli on (strut_bilancio.programma_id = capitoli.programma_id
    						AND strut_bilancio.macroag_id = capitoli.macroaggregato_id)       
    LEFT JOIN fpv 	on fpv.elem_id = capitoli.elem_id    
    LEFT JOIN conto_pdce on conto_pdce.elem_id = capitoli.elem_id        
GROUP BY id_missione, code_missione, desc_missione, 
		id_programma, code_programma, desc_programma, 
        code_titolo, code_macroagg, capitoli.tipo_capitolo,
        cap_id, pdce_code
ORDER BY code_missione, code_programma;
                    
EXCEPTION
	when no_data_found THEN
		raise notice 'Nessun dato trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

DROP FUNCTION IF EXISTS  siac."BILR186_indic_sint_spe_rend_org_er"(p_ente_prop_id integer, p_anno varchar);

CREATE OR REPLACE FUNCTION siac."BILR186_indic_sint_spe_rend_org_er" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  id_missione integer,
  code_missione varchar,
  desc_missione varchar,
  id_programma integer,
  code_programma varchar,
  desc_programma varchar,
  code_titolo varchar,
  code_macroagg varchar,
  tipo_capitolo varchar,
  cap_id integer,
  pdce_code varchar,
  imp_impegnato_i numeric,
  imp_impegni_residui_ir numeric,
  imp_fondo_fpv numeric,
  imp_prev_def_comp_cp numeric,
  imp_residui_passivi_rs numeric,
  imp_prev_def_cassa_cs numeric,
  imp_pagam_comp_pc numeric,
  imp_pagam_res_pr numeric,
  imp_riacc_residui_r numeric,
  imp_econ_comp_ecp numeric,
  imp_res_pass_comp_ec numeric,
  imp_tot_res_pass_rip_tr numeric,
  display_error varchar
) AS
$body$
DECLARE
  	DEF_NULL	constant varchar:=''; 
	RTN_MESSAGGIO varchar(1000):=DEF_NULL;

    annoBilInt integer;   
    bilId integer;
    
    
BEGIN
 
/*
	Funzione che estrae i dati di rendiconto di spesa dell'anno di bilancio in input
    suddivisi per missione, programma, titolo, macroaggregato e capitolo.
    
    I dati restituiti sono:
  		- importo IMPEGNI (I);
        - importo FONDO PLURIENNALE VINCOLATO (FPV);
        - importo PREVISIONI DEFINITIVE DI COMPETENZA (CP);
  		- importo RESIDUI PASSIVI AL (RS) ;
        - importo PREVISIONI DEFINITIVE DI CASSA (CS);
        - importo PAGAMENTI IN C/COMPETENZA (PC);
        - importo PAGAMENTI IN C/RESIDUI (PR);
        - importo RIACCERTAMENTO RESIDUI (R);
        - importo ECONOMIE DI COMPETENZA (ECP= CP-I-FPV);
        - importo RESIDUI PASSIVI DA ESERCIZIO DI COMPETENZA (EC= I-PC);
        - importo TOTALE RESIDUI PASSIVI DA RIPORTARE (TR=EP+EC).
*/

annoBilInt:=p_anno::integer;
     
	/* Leggo l'id dell'anno del rendiconto */     
bilId:=0;     
select a.bil_id 
	INTO bilId
from siac_t_bil a, siac_t_periodo b
where a.periodo_id=b.periodo_id
and a.ente_proprietario_id=p_ente_prop_id
and b.anno = p_anno;
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Codice del bilancio non trovato';
    bilId:=0;
    display_error := 'Codice del bilancio non trovato per l''anno %', anno3;
    return next;
    return;
END IF;
   

return query 
with strut_bilancio as(
     		select  *
            from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, p_anno,'')),
capitoli as(
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
        cat_del_capitolo.elem_cat_code tipo_capitolo,
       	capitolo.elem_id
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
where 		
	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 					    
    and capitolo.elem_id=	r_capitolo_stato.elem_id							
    and r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
    and capitolo.elem_id=r_capitolo_programma.elem_id							
    and capitolo.elem_id=r_capitolo_macroaggr.elem_id							
    and programma.classif_tipo_id=programma_tipo.classif_tipo_id 				
    and programma.classif_id=r_capitolo_programma.classif_id					    
    and macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				
    and macroaggr.classif_id=r_capitolo_macroaggr.classif_id						
    and capitolo.elem_id				=	r_cat_capitolo.elem_id				
	and r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		    
    and capitolo.ente_proprietario_id=p_ente_prop_id	
    and capitolo.bil_id =bilId												
    and programma_tipo.classif_tipo_code='PROGRAMMA'								
    and macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						
    and tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
    and stato_capitolo.elem_stato_code	='VA'     
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
  i_impegni as (
    select-- t_periodo.anno anno_bil,     
        sum(t_movgest_ts_det.movgest_ts_det_importo) importo_impegno,
        r_movgest_bil_elem.elem_id
     from siac_t_movgest t_movgest,
          siac_d_movgest_tipo d_movgest_tipo,
          siac_t_movgest_ts t_movgest_ts,
          siac_d_movgest_ts_tipo d_movgest_ts_tipo,
          siac_r_movgest_ts_stato r_movgest_ts_stato,
          siac_d_movgest_stato d_movgest_stato,
          siac_t_movgest_ts_det t_movgest_ts_det,
          siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
          siac_r_movgest_bil_elem r_movgest_bil_elem
    where d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
    and t_movgest_ts.movgest_id=t_movgest.movgest_id
    and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
    and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
    and d_movgest_stato.movgest_stato_id=r_movgest_ts_stato.movgest_stato_id
    and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
    and t_movgest_ts_det.movgest_ts_det_tipo_id=d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
    and r_movgest_bil_elem.movgest_id = t_movgest_ts.movgest_id
    and t_movgest.ente_proprietario_id =p_ente_prop_id
    and d_movgest_tipo.movgest_tipo_code='I'
    and d_movgest_ts_tipo.movgest_ts_tipo_code='T'
    and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'    
    -- D = DEFINITIVO
    -- N = DEFINITIVO NON LIQUIDABILE
    and d_movgest_stato.movgest_stato_code in ('D','N') 
    and t_movgest.movgest_anno = annoBilInt
    and t_movgest.bil_id =bilId
    and now() BETWEEN d_movgest_stato.validita_inizio and COALESCE(d_movgest_stato.validita_fine,now())
    and r_movgest_ts_stato.validita_fine is NULL
    and t_movgest.data_cancellazione is null
    and d_movgest_tipo.data_cancellazione is null
    and t_movgest_ts.data_cancellazione is null
    and d_movgest_ts_tipo.data_cancellazione is null
    and r_movgest_ts_stato.data_cancellazione is null
    and r_movgest_bil_elem.data_cancellazione is null
    and t_movgest_ts_det.data_cancellazione is null
    and d_movgest_ts_det_tipo.data_cancellazione is null
  GROUP BY elem_id),
i_impegni_residui as (
select --t_periodo.anno anno_bil,     
        sum(t_movgest_ts_det.movgest_ts_det_importo) importo_impegno,
        r_movgest_bil_elem.elem_id
     from siac_t_movgest t_movgest,
          siac_d_movgest_tipo d_movgest_tipo,
          siac_t_movgest_ts t_movgest_ts,
          siac_d_movgest_ts_tipo d_movgest_ts_tipo,
          siac_r_movgest_ts_stato r_movgest_ts_stato,
          siac_d_movgest_stato d_movgest_stato,
          siac_t_movgest_ts_det t_movgest_ts_det,
          siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
          siac_r_movgest_bil_elem r_movgest_bil_elem
    where d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
    and t_movgest_ts.movgest_id=t_movgest.movgest_id
    and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
    and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
    and d_movgest_stato.movgest_stato_id=r_movgest_ts_stato.movgest_stato_id
    and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
    and t_movgest_ts_det.movgest_ts_det_tipo_id=d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
    and r_movgest_bil_elem.movgest_id = t_movgest_ts.movgest_id
    and t_movgest.ente_proprietario_id =p_ente_prop_id
    and d_movgest_tipo.movgest_tipo_code='I'
    and d_movgest_ts_tipo.movgest_ts_tipo_code='T'
    and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
    -- D = DEFINITIVO
    -- N = DEFINITIVO NON LIQUIDABILE
    and d_movgest_stato.movgest_stato_code in ('D','N') 
    and t_movgest.movgest_anno < annoBilInt
    and t_movgest.bil_id =bilId
    and now() BETWEEN d_movgest_stato.validita_inizio and COALESCE(d_movgest_stato.validita_fine,now())
    and r_movgest_ts_stato.validita_fine is NULL
    and t_movgest.data_cancellazione is null
    and d_movgest_tipo.data_cancellazione is null
    and t_movgest_ts.data_cancellazione is null
    and d_movgest_ts_tipo.data_cancellazione is null
    and r_movgest_ts_stato.data_cancellazione is null
    and r_movgest_bil_elem.data_cancellazione is null
    and t_movgest_ts_det.data_cancellazione is null
    and d_movgest_ts_det_tipo.data_cancellazione is null
  GROUP BY elem_id) ,
fpv as (
select t_bil_elem.elem_id, 
sum (coalesce(t_bil_elem_det.elem_det_importo,0)) as imp_fpv
from siac_t_bil_elem t_bil_elem,
	siac_r_bil_elem_stato r_bil_elem_stato, 
	siac_d_bil_elem_stato d_bil_elem_stato,
	siac_r_bil_elem_categoria r_bil_elem_categoria,
    siac_d_bil_elem_categoria d_bil_elem_categoria,
	siac_t_bil_elem_det t_bil_elem_det,
    siac_d_bil_elem_det_tipo d_bil_elem_det_tipo,
    siac_t_bil t_bil,
    siac_t_periodo t_periodo
where  r_bil_elem_stato.elem_id=t_bil_elem.elem_id
    and d_bil_elem_stato.elem_stato_id=r_bil_elem_stato.elem_stato_id
    and r_bil_elem_categoria.elem_id=t_bil_elem.elem_id 
    and d_bil_elem_categoria.elem_cat_id=r_bil_elem_categoria.elem_cat_id
    and t_bil_elem_det.elem_id=t_bil_elem.elem_id 
    and d_bil_elem_det_tipo.elem_det_tipo_id=t_bil_elem_det.elem_det_tipo_id
    and t_bil.bil_id=t_bil_elem.bil_id
    and t_bil.periodo_id=t_periodo.periodo_id
    and t_periodo.periodo_id=t_bil_elem_det.periodo_id
    and t_bil_elem.ente_proprietario_id=p_ente_prop_id	
    and t_periodo.anno  = p_anno
    and d_bil_elem_stato.elem_stato_code='VA'
    and d_bil_elem_categoria.elem_cat_code	in	('FPV','FPVCC','FPVSC')
    and d_bil_elem_det_tipo.elem_det_tipo_code='STA'
    and r_bil_elem_categoria.validita_fine is NULL
    and r_bil_elem_stato.validita_fine is NULL
    and t_bil_elem.data_cancellazione is null
    and r_bil_elem_stato.data_cancellazione is null
    and d_bil_elem_stato.data_cancellazione is null
    and r_bil_elem_categoria.data_cancellazione is null
    and d_bil_elem_categoria.data_cancellazione is null
    and t_bil_elem_det.data_cancellazione is null
    and d_bil_elem_det_tipo.data_cancellazione is null
    and t_bil.data_cancellazione is null
    and t_periodo.data_cancellazione is null
group by t_bil_elem.elem_id),  
cp_prev_def_comp as (
select t_bil_elem.elem_id, 
sum(coalesce (t_bil_elem_det.elem_det_importo,0))   as previsioni_definitive_comp
from siac_t_bil_elem t_bil_elem,
siac_r_bil_elem_stato r_bil_elem_stato, 
siac_d_bil_elem_stato d_bil_elem_stato,
siac_r_bil_elem_categoria r_bil_elem_categ,
siac_d_bil_elem_categoria d_bil_elem_categ,
siac_t_bil_elem_det t_bil_elem_det,
siac_d_bil_elem_det_tipo d_bil_elem_det_tipo
,siac_t_periodo t_periodo
where  r_bil_elem_stato.elem_id=t_bil_elem.elem_id
and d_bil_elem_stato.elem_stato_id=r_bil_elem_stato.elem_stato_id
and r_bil_elem_categ.elem_id=t_bil_elem.elem_id 
and d_bil_elem_categ.elem_cat_id=r_bil_elem_categ.elem_cat_id
and t_bil_elem_det.elem_id=t_bil_elem.elem_id 
and d_bil_elem_det_tipo.elem_det_tipo_id=t_bil_elem_det.elem_det_tipo_id
and t_periodo.periodo_id=t_bil_elem_det.periodo_id
and d_bil_elem_stato.elem_stato_code='VA'
and t_bil_elem.ente_proprietario_id=p_ente_prop_id
and d_bil_elem_categ.elem_cat_code	in	('STD','FSC','FPV',  'FPVCC','FPVSC')
and d_bil_elem_det_tipo.elem_det_tipo_code='STA'
and t_periodo.anno=p_anno
and t_bil_elem.bil_id = bilId
and r_bil_elem_categ.validita_fine is NULL
and r_bil_elem_stato.validita_fine is NULL
and t_bil_elem.data_cancellazione is null
and r_bil_elem_stato.data_cancellazione is null
and d_bil_elem_stato.data_cancellazione is null
and r_bil_elem_categ.data_cancellazione is null
and d_bil_elem_categ.data_cancellazione is null
and t_bil_elem_det.data_cancellazione is null
and d_bil_elem_det_tipo.data_cancellazione is null
and t_periodo.data_cancellazione is null
group by t_bil_elem.elem_id),
rs_residui_pass as(
select r_movgest_bil_elem.elem_id,
	sum(coalesce(t_movgest_ts_det.movgest_ts_det_importo,0)) residui_passivi 
from siac_t_movgest t_movgest,
	siac_t_movgest_ts t_movgest_ts,
    siac_t_movgest_ts_det t_movgest_ts_det,
	siac_r_movgest_bil_elem r_movgest_bil_elem,
    siac_d_movgest_tipo d_movgest_tipo,
    siac_r_movgest_ts_stato r_movgest_ts_stato,
    siac_d_movgest_stato d_movgest_stato,
	siac_d_movgest_ts_tipo d_movgest_ts_tipo,
    siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
    siac_t_bil t_bil,
    siac_t_periodo t_periodo
 where  t_movgest_ts.movgest_id=t_movgest.movgest_id
     and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
     and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
     and d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id  
     and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
     and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id  
     and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id 
     and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
     and t_bil.bil_id = t_movgest.bil_id
    and t_periodo.periodo_id= t_bil.periodo_id
     and t_movgest.ente_proprietario_id=p_ente_prop_id
     and t_movgest.movgest_anno < t_periodo.anno::integer
     and d_movgest_tipo.movgest_tipo_code='I'     
     and d_movgest_stato.movgest_stato_code in ('D','N')  
     and d_movgest_ts_tipo.movgest_ts_tipo_code='T'      
     and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='I'
     and t_periodo.anno = p_anno   
     and r_movgest_ts_stato.validita_fine is NULL
     and t_movgest.data_cancellazione is null
     and t_movgest_ts.data_cancellazione is null
     and t_movgest_ts_det.data_cancellazione is null
     and r_movgest_bil_elem.data_cancellazione is null
     and d_movgest_tipo.data_cancellazione is null
     and r_movgest_ts_stato.data_cancellazione is null
     and d_movgest_stato.data_cancellazione is null
     and d_movgest_ts_tipo.data_cancellazione is null
     and d_movgest_ts_det_tipo.data_cancellazione is null
     and t_bil.data_cancellazione is null
     and t_periodo.data_cancellazione is null     
group by r_movgest_bil_elem.elem_id),
cs_prev_def_cassa as (
select t_bil_elem.elem_id, 
sum(coalesce (t_bil_elem_det.elem_det_importo,0)) as previsioni_definitive_cassa
from siac_t_bil_elem t_bil_elem,
siac_r_bil_elem_stato r_bil_elem_stato, 
siac_d_bil_elem_stato d_bil_elem_stato,
siac_r_bil_elem_categoria r_bil_elem_categ,
siac_d_bil_elem_categoria d_bil_elem_categ,
siac_t_bil_elem_det t_bil_elem_det,
siac_d_bil_elem_det_tipo d_bil_elem_det_tipo,
siac_t_periodo t_periodo
where  r_bil_elem_stato.elem_id=t_bil_elem.elem_id
  and d_bil_elem_stato.elem_stato_id=r_bil_elem_stato.elem_stato_id
  and r_bil_elem_categ.elem_id=t_bil_elem.elem_id 
  and d_bil_elem_categ.elem_cat_id=r_bil_elem_categ.elem_cat_id
  and t_bil_elem_det.elem_id=t_bil_elem.elem_id 
  and d_bil_elem_det_tipo.elem_det_tipo_id=t_bil_elem_det.elem_det_tipo_id
  and t_periodo.periodo_id=t_bil_elem_det.periodo_id
  and t_bil_elem.ente_proprietario_id=p_ente_prop_id
  and t_periodo.anno = p_anno
  and t_bil_elem.bil_id = bilId
  and d_bil_elem_stato.elem_stato_code='VA'
  and d_bil_elem_categ.elem_cat_code	in	('STD','FSC')
  and d_bil_elem_det_tipo.elem_det_tipo_code='SCA'
  and r_bil_elem_stato.validita_fine is NULL
  and r_bil_elem_categ.validita_fine is NULL
  and t_bil_elem.data_cancellazione is null
  and r_bil_elem_stato.data_cancellazione is null
  and d_bil_elem_stato.data_cancellazione is null
  and r_bil_elem_categ.data_cancellazione is null
  and d_bil_elem_categ.data_cancellazione is null
  and t_bil_elem_det.data_cancellazione is null
  and d_bil_elem_det_tipo.data_cancellazione is null
  and t_periodo.data_cancellazione is null
group by t_bil_elem.elem_id),
pc_pagam_comp as (
select 
	r_ord_bil_elem.elem_id,
    sum(coalesce(t_ord_ts_det.ord_ts_det_importo,0)) pagamenti_competenza
 from  siac_t_movgest t_movgest, 
 	siac_t_movgest_ts t_movgest_ts,
    siac_r_liquidazione_movgest r_liq_movgest,
    siac_r_liquidazione_ord r_liq_ord,
	siac_t_ordinativo_ts t_ord_ts,
    siac_t_ordinativo t_ord,
    siac_d_ordinativo_tipo d_ord_tipo,
    siac_r_ordinativo_stato r_ord_stato,
	siac_d_ordinativo_stato d_ord_stato,
    siac_r_ordinativo_bil_elem r_ord_bil_elem,
    siac_t_ordinativo_ts_det t_ord_ts_det,
	siac_d_ordinativo_ts_det_tipo d_ord_ts_det_tipo
where t_movgest_ts.movgest_id=t_movgest.movgest_id
    and r_liq_movgest.movgest_ts_id=t_movgest_ts.movgest_ts_id
    and r_liq_ord.liq_id=r_liq_movgest.liq_id
    and t_ord.ord_id=t_ord_ts.ord_id
    and r_liq_ord.sord_id=t_ord_ts.ord_ts_id
    and t_ord.ord_id=t_ord_ts.ord_id
    and d_ord_tipo.ord_tipo_id=t_ord.ord_tipo_id
    and r_ord_stato.ord_id=t_ord.ord_id
    and d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
    and r_ord_bil_elem.ord_id=t_ord.ord_id
    and t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
    and d_ord_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
    and t_movgest.ente_proprietario_id=p_ente_prop_id
    and d_ord_tipo.ord_tipo_code = 'P'
    and d_ord_stato.ord_stato_code <> 'A'
    and d_ord_ts_det_tipo.ord_ts_det_tipo_code = 'A'
	and t_movgest.movgest_anno = annoBilInt 
    and t_movgest.bil_id=bilId
    and r_liq_movgest.validita_fine is NULL
    and r_liq_ord.validita_fine is NULL
    and r_ord_bil_elem.validita_fine is NULL
    and r_ord_stato.validita_fine is NULL
    and t_movgest.data_cancellazione is null
    and t_movgest_ts.data_cancellazione is null
    and r_liq_movgest.data_cancellazione is null
    and r_liq_ord.data_cancellazione is null
    and t_ord_ts.data_cancellazione is null
    and t_ord.data_cancellazione is null
    and d_ord_tipo.data_cancellazione is null
    and r_ord_stato.data_cancellazione is null
    and d_ord_stato.data_cancellazione is null
    and r_ord_bil_elem.data_cancellazione is null
    and t_ord_ts_det.data_cancellazione is null
    and d_ord_ts_det_tipo.data_cancellazione is null
group by r_ord_bil_elem.elem_id),
pr_pagamenti_residui as (
select 
	r_ord_bil_elem.elem_id,
	sum(coalesce(t_ord_ts_det.ord_ts_det_importo,0)) pagamenti_residui
 from  siac_t_movgest t_movgest, 
 	siac_t_movgest_ts t_movgest_ts,
    siac_r_liquidazione_movgest r_liq_movgest,
    siac_r_liquidazione_ord r_liq_ord,
	siac_t_ordinativo_ts t_ord_ts,
    siac_t_ordinativo t_ord,
    siac_d_ordinativo_tipo d_ord_tipo,
    siac_r_ordinativo_stato r_ord_stato,
	siac_d_ordinativo_stato d_ord_stato,
    siac_r_ordinativo_bil_elem r_ord_bil_elem,
    siac_t_ordinativo_ts_det t_ord_ts_det,
	siac_d_ordinativo_ts_det_tipo d_ord_ts_det_tipo,
    siac_t_bil t_bil,
    siac_t_periodo t_periodo
where t_movgest_ts.movgest_id=t_movgest.movgest_id
    and r_liq_movgest.movgest_ts_id=t_movgest_ts.movgest_ts_id
    and r_liq_ord.liq_id=r_liq_movgest.liq_id
    and r_liq_ord.sord_id=t_ord_ts.ord_ts_id
    and t_ord.ord_id=t_ord_ts.ord_id
    and d_ord_tipo.ord_tipo_id=t_ord.ord_tipo_id
    and t_ord.ord_id=t_ord_ts.ord_id
    and d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
    and r_ord_bil_elem.ord_id=t_ord.ord_id
    and t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
    and d_ord_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
    and r_ord_stato.ord_id=t_ord.ord_id    
    and t_bil.bil_id = t_movgest.bil_id
    and t_periodo.periodo_id= t_bil.periodo_id
    and t_movgest.ente_proprietario_id=p_ente_prop_id
    and t_movgest.movgest_anno < t_periodo.anno::integer
    and d_ord_tipo.ord_tipo_code='P'        
    and d_ord_stato.ord_stato_code<>'A'
    and d_ord_ts_det_tipo.ord_ts_det_tipo_code='A'
    and t_periodo.anno = p_anno 
    and r_liq_movgest.validita_fine is NULL
    and r_liq_ord.validita_fine is NULL
    and r_ord_bil_elem.validita_fine is NULL
    and r_ord_stato.validita_fine is NULL
    and t_movgest.data_cancellazione is null
    and t_movgest_ts.data_cancellazione is null
    and r_liq_movgest.data_cancellazione is null
    and r_liq_ord.data_cancellazione is null
    and t_ord_ts.data_cancellazione is null
    and t_ord.data_cancellazione is null
    and d_ord_tipo.data_cancellazione is null
    and r_ord_stato.data_cancellazione is null
    and d_ord_stato.data_cancellazione is null
    and r_ord_bil_elem.data_cancellazione is null
    and t_ord_ts_det.data_cancellazione is null
    and d_ord_ts_det_tipo.data_cancellazione is null
    and t_bil.data_cancellazione is null
    and t_periodo.data_cancellazione is null
group by r_ord_bil_elem.elem_id),
riacc_residui as(
select r_movgest_bil_elem.elem_id,
sum(coalesce(t_movgest_ts_det_mod.movgest_ts_det_importo,0)) riaccertamenti_residui
from siac_r_movgest_bil_elem r_movgest_bil_elem,
      siac_t_movgest t_movgest,
      siac_d_movgest_tipo d_movgest_tipo,
      siac_t_movgest_ts  t_movgest_ts,
      siac_r_movgest_ts_stato r_movgest_ts_stato,
      siac_d_movgest_stato  d_movgest_stato,
      siac_t_movgest_ts_det t_movgest_ts_det,
      siac_d_movgest_ts_tipo d_movgest_ts_tipo,
      siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
      siac_t_modifica t_modifica,
      siac_r_modifica_stato r_modifica_stato,
      siac_d_modifica_stato d_modifica_stato,
      siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
where r_movgest_bil_elem.movgest_id = t_movgest.movgest_id 
	and t_movgest.movgest_tipo_id = d_movgest_tipo.movgest_tipo_id 
    and t_movgest.movgest_id = t_movgest_ts.movgest_id 
	and t_movgest_ts.movgest_ts_id  = r_movgest_ts_stato.movgest_ts_id 
	and r_movgest_ts_stato.movgest_stato_id  = d_movgest_stato.movgest_stato_id 
    and t_movgest_ts_det.movgest_ts_id = t_movgest_ts.movgest_ts_id
	and d_movgest_ts_tipo.movgest_ts_tipo_id  = t_movgest_ts.movgest_ts_tipo_id 
    and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id  = t_movgest_ts_det.movgest_ts_det_tipo_id 
    and t_movgest_ts_det_mod.movgest_ts_id=t_movgest_ts.movgest_ts_id      
	and t_movgest_ts_det_mod.mod_stato_r_id=r_modifica_stato.mod_stato_r_id
    and d_modifica_stato.mod_stato_id=r_modifica_stato.mod_stato_id 
    and r_modifica_stato.mod_id=t_modifica.mod_id    
	and t_movgest.ente_proprietario_id=p_ente_prop_id
    and t_movgest.bil_id=bilId
    and t_movgest.movgest_anno < p_anno::integer
    and d_movgest_tipo.movgest_tipo_code = 'I'
    and d_movgest_stato.movgest_stato_code   in ('D','N') 
    and d_movgest_ts_tipo.movgest_ts_tipo_code  = 'T' 
    and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code = 'A' 
    and d_modifica_stato.mod_stato_code='V'
    and r_movgest_ts_stato.validita_fine is NULL
    and r_modifica_stato.validita_fine is NULL
    and r_movgest_bil_elem.data_cancellazione is null 
    and t_movgest.data_cancellazione is null 
    and d_movgest_tipo.data_cancellazione is null 
    and r_movgest_ts_stato.data_cancellazione is null 
    and t_movgest_ts.data_cancellazione is null 
    and d_movgest_stato.data_cancellazione is null 
    and t_movgest_ts_det.data_cancellazione is null 
    and d_movgest_ts_tipo.data_cancellazione is null 
    and d_movgest_ts_det_tipo.data_cancellazione is null
    and t_modifica.data_cancellazione is null
    and r_modifica_stato.data_cancellazione is null
    and d_modifica_stato.data_cancellazione is null
    and t_movgest_ts_det_mod.data_cancellazione is null
group by r_movgest_bil_elem.elem_id),
conto_pdce as(
        select t_class_upb.classif_code, r_capitolo_upb.elem_id
        	from 
                siac_d_class_tipo	class_upb,
                siac_t_class		t_class_upb,
                siac_r_bil_elem_class r_capitolo_upb
        	where 		
                t_class_upb.classif_tipo_id=class_upb.classif_tipo_id 
                and t_class_upb.classif_id=r_capitolo_upb.classif_id
                and t_class_upb.ente_proprietario_id=p_ente_prop_id
                and class_upb.classif_tipo_code like 'PDC_%'
                and	class_upb.data_cancellazione 			is null
                and t_class_upb.data_cancellazione 			is null
                and r_capitolo_upb.data_cancellazione 			is null)          
SELECT  strut_bilancio.missione_id::integer id_missione,
		strut_bilancio.missione_code::varchar code_missione, 
		strut_bilancio.missione_desc::varchar desc_missione, 
        strut_bilancio.programma_id::integer id_programma,
        strut_bilancio.programma_code::varchar code_programma,
        strut_bilancio.programma_desc::varchar desc_programma,
        strut_bilancio.titusc_code::varchar code_titolo,
        strut_bilancio.macroag_code::varchar  code_macroagg,
        case when capitoli.tipo_capitolo = 'FPVC'
        	then 'FPV'::varchar
            else capitoli.tipo_capitolo::varchar end tipo_capitolo,
        capitoli.elem_id::integer cap_id,
        conto_pdce.classif_code::varchar pdce_code,
        sum(COALESCE(i_impegni.importo_impegno,0))::numeric imp_impegnato_i, 
        sum(COALESCE(i_impegni_residui.importo_impegno,0))::numeric imp_impegni_residui_ir,         
        sum(COALESCE(fpv.imp_fpv,0))::numeric imp_fondo_fpv,    
        sum(COALESCE(cp_prev_def_comp.previsioni_definitive_comp,0))::numeric imp_prev_def_comp_cp,
        sum(COALESCE(rs_residui_pass.residui_passivi,0))::numeric imp_residui_passivi_rs,
        sum(COALESCE(cs_prev_def_cassa.previsioni_definitive_cassa,0))::numeric imp_prev_def_cassa_cs,      
        sum(COALESCE(pc_pagam_comp.pagamenti_competenza,0))::numeric imp_pagam_comp_pc,         
        sum(COALESCE(pr_pagamenti_residui.pagamenti_residui,0))::numeric imp_pagam_res_pr, 
        sum(COALESCE(riacc_residui.riaccertamenti_residui,0))::numeric imp_riacc_residui_r,
        sum(COALESCE(cp_prev_def_comp.previsioni_definitive_comp,0) -
        	COALESCE(i_impegni.importo_impegno,0) -
            COALESCE(fpv.imp_fpv,0))::numeric imp_econ_comp_ecp,  
        sum(COALESCE(i_impegni.importo_impegno,0) -
        	COALESCE(pc_pagam_comp.pagamenti_competenza,0))::numeric imp_res_pass_comp_ec,   
        sum(COALESCE(rs_residui_pass.residui_passivi,0)-
        	COALESCE(pr_pagamenti_residui.pagamenti_residui,0) +
            COALESCE(riacc_residui.riaccertamenti_residui,0)+
            COALESCE(i_impegni.importo_impegno,0)-
            COALESCE(pc_pagam_comp.pagamenti_competenza,0)) imp_tot_res_pass_rip_tr,        
        ''::varchar display_error
FROM strut_bilancio
	LEFT JOIN capitoli on (strut_bilancio.programma_id = capitoli.programma_id
    						AND strut_bilancio.macroag_id = capitoli.macroaggregato_id)
    LEFT JOIN i_impegni on i_impegni.elem_id = capitoli.elem_id
    LEFT JOIN i_impegni_residui on i_impegni_residui.elem_id = capitoli.elem_id    
    LEFT JOIN fpv 	on fpv.elem_id = capitoli.elem_id    
    LEFT JOIN cp_prev_def_comp on cp_prev_def_comp.elem_id = capitoli.elem_id   
	LEFT JOIN rs_residui_pass on rs_residui_pass.elem_id = capitoli.elem_id             
    LEFT JOIN cs_prev_def_cassa on cs_prev_def_cassa.elem_id = capitoli.elem_id   
    LEFT JOIN pc_pagam_comp on pc_pagam_comp.elem_id = capitoli.elem_id  
    LEFT JOIN pr_pagamenti_residui on pr_pagamenti_residui.elem_id = capitoli.elem_id                      
    LEFT JOIN riacc_residui on riacc_residui.elem_id = capitoli.elem_id
    LEFT JOIN conto_pdce on conto_pdce.elem_id = capitoli.elem_id        
GROUP BY id_missione, code_missione, desc_missione, 
		id_programma, code_programma, desc_programma, 
        code_titolo, code_macroagg, capitoli.tipo_capitolo,
        cap_id, pdce_code
ORDER BY code_missione, code_programma;
                    
EXCEPTION
	when no_data_found THEN
		raise notice 'Nessun dato trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;


/* INIZIO CONFIGURAZIONE PER REPORT SINTETICI */



		/* INDICATORI SINTETICI RENDICONTO per Enti Strumentali
			Esclusi i seguenti enti:
		
		 1 = Citta' di Torino
		 2 = Regione Piemonte
		 3 = Citta' Metropolitana di Torino
		 8 = Ente modello EELL
		15 = Ente Fittizio Per Gestione
		29 = Comune di Alessandria
		30 = Comune di Vercelli
		31 = Provincia di Vercelli
		32 = Provincia di Asti
		33 = Scuola Comunale di Musica F.A. Vallotti
		
		*/
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'ripiano_disav_rnd','Ripiano disavanzo a carico dell''esercizio (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='ripiano_disav_rnd');
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'somm_utilizzi_rnd','Sommatoria degli utilizzi giornalieri delle anticipazioni nell''esercizio (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='somm_utilizzi_rnd');


INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'anticip_tesoreria_rnd','Anticipazione di tesoreria all''inizio dell''esercizio successivo (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='anticip_tesoreria_rnd');

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'max_previsto_norma_rnd','Importo massimo previsto nella norma (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='max_previsto_norma_rnd');
	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'margine_corr_comp_rnd','Margine corrente di competenza (Entrate titolo 1, 2 3 - Spese Titolo 1 - Spese Titolo 4) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='margine_corr_comp_rnd');
	  

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'accens_prest_rinegoz_rnd','Accensione prestiti da rinegoziazioni(rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='accens_prest_rinegoz_rnd');	  
	  

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'giorni_effett_rnd','Giorni effettivi intercorrenti tra la data di scadenza della fattura o richiesta equivalente di pagamento e la data di pagamento ai fornitori moltiplicata per l''importo dovuto (rendiconto)', 0, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='giorni_effett_rnd');	  
	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'somma_imp_pagati_rnd','Somma degli importi pagati nel periodo di riferimento (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='somma_imp_pagati_rnd');	  	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'impegni_estinz_anticip_rnd','Impegni per estinzioni anticipate (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='impegni_estinz_anticip_rnd');

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'debito_finanz_anno_prec_rnd','Debito da finanziamento al 31 dicembre anno precedente (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='debito_finanz_anno_prec_rnd');
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'disav_amm_eser_prec_rnd','Disavanzo di amministrazione esercizio precedente (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_amm_eser_prec_rnd');	 

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'disav_amm_eser_corso_rnd','Disavanzo di amministrazione esercizio in corso (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_amm_eser_corso_rnd');	  
	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'tot_disav_eser_prec_rnd','Totale Disavanzo esercizio precedente (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='tot_disav_eser_prec_rnd');	
	  

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'tot_disav_amm_rnd','Totale Disavanzo amministrazione (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='tot_disav_amm_rnd');	
	  

	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'disav_iscrit_spesa_rnd','Disavanzo iscritto in spesa del conto del bilancio (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_iscrit_spesa_rnd');
	  

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'patrimonio_netto_rnd','Patrimonio netto (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='patrimonio_netto_rnd');
 	  
	 
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'importo_debiti_fuori_bil_ricon_rnd','Importo Debiti fuori bilancio riconosciuti e finanziati (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='importo_debiti_fuori_bil_ricon_rnd');	  

	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'importo_debiti_fuori_bil_corso_ricon_rnd','Importo debiti fuori bilancio in corso di riconoscimento (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='importo_debiti_fuori_bil_corso_ricon_rnd');	  
	  

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'importo_debiti_fuori_bil_ricon_corso_finanz_rnd','Importo Debiti fuori bilancio riconosciuti e in corso di finanziamento (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='importo_debiti_fuori_bil_ricon_corso_finanz_rnd');	  
	  


INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'input_colonna_a_rnd','Input totale colonna A - Allegato b) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='input_colonna_a_rnd');	  
	  
	  

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'input_colonna_c_rnd','Input totale colonna C - Allegato b) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='input_colonna_c_rnd');	  


INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'a_ris_amm_presunto_rnd','A) Risultato di amministrazione presunto al 31/12 anno precedente - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='a_ris_amm_presunto_rnd');	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'b_tot_parte_accant_rnd','B) Totale parte accantonata - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='b_tot_parte_accant_rnd');	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'c_tot_parte_vinc_rnd','C) Totale parte vincolata - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='c_tot_parte_vinc_rnd');	 

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'd_tot_dest_invest_rnd','D) Totale parte destinata agli investimenti - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='d_tot_dest_invest_rnd');	 

	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'e_tot_parte_disp_rnd','E) Totale parte disponibile - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='e_tot_parte_disp_rnd');	 
	  

/* inserimento dei record dove si registrano i valori */
INSERT INTO  siac_t_conf_indicatori_sint (
voce_conf_ind_id,
  bil_id,
  conf_ind_valore_anno,
  conf_ind_valore_anno_1,
  conf_ind_valore_anno_2,
  conf_ind_valore_tot_miss_13_anno,
  conf_ind_valore_tot_miss_13_anno_1 ,
  conf_ind_valore_tot_miss_13_anno_2 ,
  conf_ind_valore_tutte_spese_anno ,
  conf_ind_valore_tutte_spese_anno_1 ,
  conf_ind_valore_tutte_spese_anno_2 ,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  data_creazione,
  data_modifica,
  data_cancellazione,
  login_operazione)
SELECT t_voce_ind.voce_conf_ind_id, t_bil.bil_id, NULL, NULL, NULL, 
	NULL, NULL, NULL, NULL, NULL, NULL, 
	now(), NULL, t_ente.ente_proprietario_id,  now(), now(), NULL, 'admin'
FROM siac_t_ente_proprietario t_ente,
	siac_t_bil t_bil,
    siac_t_periodo t_periodo,
    siac_t_voce_conf_indicatori_sint t_voce_ind
where t_ente.ente_proprietario_id =t_bil.ente_proprietario_id
	and t_bil.periodo_id=t_periodo.periodo_id
    and t_periodo.anno='2017'
    and t_voce_ind.ente_proprietario_id=t_bil.ente_proprietario_id
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and t_ente.data_cancellazione IS NULL
	and	t_bil.data_cancellazione IS NULL
    and not exists (select 1 
      from siac_t_conf_indicatori_sint z 
      where z.bil_id=t_bil.bil_id 
      and z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_id=t_voce_ind.voce_conf_ind_id);
	  
	  
	  
	  

		/* INDICATORI SINTETICI RENDICONTO per REGIONE
		
		*/
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'ripiano_disav_rnd','Ripiano disavanzo a carico dell''esercizio (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='ripiano_disav_rnd');

	  INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'utilizzo_fondo_anticip_rnd','Utilizzo Fondo anticipazioni di liquidità del DL 35/2013 (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where t_ente.ente_proprietario_id in (2)
	and data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='utilizzo_fondo_anticip_rnd');
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'popolaz_residente_rnd','Popolazione residente al 1 gennaio(al 1 gennaio dell''esercizio di riferimento o, se non disponibile, al 1 gennaio dell''ultimo anno disponibile) - (rendiconto)', 0, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where t_ente.ente_proprietario_id in (2)
	and data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='popolaz_residente_rnd');	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'ripiano_disav_rnd','Ripiano disavanzo a carico dell''esercizio (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='ripiano_disav_rnd');
	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'somm_utilizzi_rnd','Sommatoria degli utilizzi giornalieri delle anticipazioni nell''esercizio (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='somm_utilizzi_rnd');


INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'anticip_tesoreria_rnd','Anticipazione di tesoreria all''inizio dell''esercizio successivo (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='anticip_tesoreria_rnd');

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'max_previsto_norma_rnd','Importo massimo previsto nella norma (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='max_previsto_norma_rnd');
	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'margine_corr_comp_rnd','Margine corrente di competenza (Entrate titolo 1, 2 3 - Spese Titolo 1 - Spese Titolo 4) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='margine_corr_comp_rnd');
	  

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'accens_prest_rinegoz_rnd','Accensione prestiti da rinegoziazioni (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='accens_prest_rinegoz_rnd');	  
	  

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'giorni_effett_rnd','Giorni effettivi intercorrenti tra la data di scadenza della fattura o richiesta equivalente di pagamento e la data di pagamento ai fornitori moltiplicata per l''importo dovuto (rendiconto)', 0, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='giorni_effett_rnd');	  
	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'somma_imp_pagati_rnd','Somma degli importi pagati nel periodo di riferimento (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='somma_imp_pagati_rnd');	  	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'impegni_estinz_anticip_rnd','Impegni per estinzioni anticipate (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='impegni_estinz_anticip_rnd');

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'debito_finanz_anno_prec_rnd','Debito da finanziamento al 31 dicembre anno precedente (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='debito_finanz_anno_prec_rnd');
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'disav_amm_eser_prec_rnd','Disavanzo di amministrazione esercizio precedente (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_amm_eser_prec_rnd');	 

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'disav_amm_eser_corso_rnd','Disavanzo di amministrazione esercizio in corso (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_amm_eser_corso_rnd');	  
	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'tot_disav_eser_prec_rnd','Totale Disavanzo esercizio precedente (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='tot_disav_eser_prec_rnd');	
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'disav_debito_aut_non_contr_rnd','Disavanzo derivante da debito autorizzato e non contratto (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_debito_aut_non_contr_rnd');	 

  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'disav_ammin_lettera_e_rnd','Disavanzo di amministrazione di cui alla lettera E dell''allegato al rendiconto riguardante il risultato di amministrazione presunto (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_ammin_lettera_e_rnd');	 
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'tot_disav_amm_rnd','Totale Disavanzo amministrazione (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='tot_disav_amm_rnd');	
	  

	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'disav_iscrit_spesa_rnd','Disavanzo iscritto in spesa del conto del bilancio (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_iscrit_spesa_rnd');
	  

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'patrimonio_netto_rnd','Patrimonio netto (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='patrimonio_netto_rnd');
 	  
	 
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'importo_debiti_fuori_bil_ricon_rnd','Importo Debiti fuori bilancio riconosciuti e finanziati (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='importo_debiti_fuori_bil_ricon_rnd');	  

	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'importo_debiti_fuori_bil_corso_ricon_rnd','Importo debiti fuori bilancio in corso di riconoscimento (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='importo_debiti_fuori_bil_corso_ricon_rnd');	  
	  

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'importo_debiti_fuori_bil_ricon_corso_finanz_rnd','Importo Debiti fuori bilancio riconosciuti e in corso di finanziamento (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='importo_debiti_fuori_bil_ricon_corso_finanz_rnd');	  
	  


INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'input_colonna_a_rnd','Input totale colonna A - Allegato b) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='input_colonna_a_rnd');	  
	  
	  

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'input_colonna_c_rnd','Input totale colonna C - Allegato b) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='input_colonna_c_rnd');	  


INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'a_ris_amm_presunto_rnd','A) Risultato di amministrazione presunto al 31/12 anno precedente - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='a_ris_amm_presunto_rnd');	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'b_tot_parte_accant_rnd','B) Totale parte accantonata - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='b_tot_parte_accant_rnd');	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'c_tot_parte_vinc_rnd','C) Totale parte vincolata - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='c_tot_parte_vinc_rnd');	 

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'd_tot_dest_invest_rnd','D) Totale parte destinata agli investimenti - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='d_tot_dest_invest_rnd');	 

	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'e_tot_parte_disp_rnd','E) Totale parte disponibile - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='e_tot_parte_disp_rnd');	 
	  

/* inserimento dei record dove si registrano i valori */
INSERT INTO  siac_t_conf_indicatori_sint (
voce_conf_ind_id,
  bil_id,
  conf_ind_valore_anno,
  conf_ind_valore_anno_1,
  conf_ind_valore_anno_2,
  conf_ind_valore_tot_miss_13_anno,
  conf_ind_valore_tot_miss_13_anno_1 ,
  conf_ind_valore_tot_miss_13_anno_2 ,
  conf_ind_valore_tutte_spese_anno ,
  conf_ind_valore_tutte_spese_anno_1 ,
  conf_ind_valore_tutte_spese_anno_2 ,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  data_creazione,
  data_modifica,
  data_cancellazione,
  login_operazione)
SELECT t_voce_ind.voce_conf_ind_id, t_bil.bil_id, NULL, NULL, NULL, 
	NULL, NULL, NULL, NULL, NULL, NULL, 
	now(), NULL, t_ente.ente_proprietario_id,  now(), now(), NULL, 'admin'
FROM siac_t_ente_proprietario t_ente,
	siac_t_bil t_bil,
    siac_t_periodo t_periodo,
    siac_t_voce_conf_indicatori_sint t_voce_ind
where t_ente.ente_proprietario_id =t_bil.ente_proprietario_id
	and t_bil.periodo_id=t_periodo.periodo_id
    and t_periodo.anno='2017'
    and t_voce_ind.ente_proprietario_id=t_bil.ente_proprietario_id
	and t_ente.ente_proprietario_id  in (2)
	and t_ente.data_cancellazione IS NULL
	and	t_bil.data_cancellazione IS NULL
    and not exists (select 1 
      from siac_t_conf_indicatori_sint z 
      where z.bil_id=t_bil.bil_id 
      and z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_id=t_voce_ind.voce_conf_ind_id);
	  
	  

		/* INDICATORI SINTETICI RENDICONTO per ENTI LOCALI
		
		*/
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'ripiano_disav_rnd','Ripiano disavanzo a carico dell''esercizio (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='ripiano_disav_rnd');

	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'popolaz_residente_rnd','Popolazione residente al 1 gennaio(al 1 gennaio dell''esercizio di riferimento o, se non disponibile, al 1 gennaio dell''ultimo anno disponibile) - (rendiconto)', 0, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where t_ente.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
	and data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='popolaz_residente_rnd');	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'ripiano_disav_rnd','Ripiano disavanzo a carico dell''esercizio (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='ripiano_disav_rnd');
	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'somm_utilizzi_rnd','Sommatoria degli utilizzi giornalieri delle anticipazioni nell''esercizio (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='somm_utilizzi_rnd');


INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'anticip_tesoreria_rnd','Anticipazione di tesoreria all''inizio dell''esercizio successivo (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='anticip_tesoreria_rnd');

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'max_previsto_norma_rnd','Importo massimo previsto nella norma (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='max_previsto_norma_rnd');
	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'margine_corr_comp_rnd','Margine corrente di competenza (Entrate titolo 1, 2 3 - Spese Titolo 1 - Spese Titolo 4) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='margine_corr_comp_rnd');
	  

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'accens_prest_rinegoz_rnd','Accensione prestiti da rinegoziazioni (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='accens_prest_rinegoz_rnd');	  
	  

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'giorni_effett_rnd','Giorni effettivi intercorrenti tra la data di scadenza della fattura o richiesta equivalente di pagamento e la data di pagamento ai fornitori moltiplicata per l''importo dovuto (rendiconto)', 0, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='giorni_effett_rnd');	  
	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'somma_imp_pagati_rnd','Somma degli importi pagati nel periodo di riferimento (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='somma_imp_pagati_rnd');	  	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'impegni_estinz_anticip_rnd','Impegni per estinzioni anticipate (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='impegni_estinz_anticip_rnd');

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'debito_finanz_anno_prec_rnd','Debito da finanziamento al 31 dicembre anno precedente (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='debito_finanz_anno_prec_rnd');
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'disav_amm_eser_prec_rnd','Disavanzo di amministrazione esercizio precedente (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_amm_eser_prec_rnd');	 

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'disav_amm_eser_corso_rnd','Disavanzo di amministrazione esercizio in corso (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_amm_eser_corso_rnd');	  
	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'tot_disav_eser_prec_rnd','Totale Disavanzo esercizio precedente (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='tot_disav_eser_prec_rnd');	
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'disav_debito_aut_non_contr_rnd','Disavanzo derivante da debito autorizzato e non contratto (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_debito_aut_non_contr_rnd');	 

  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'disav_ammin_lettera_e_rnd','Disavanzo di amministrazione di cui alla lettera E dell''allegato al rendiconto riguardante il risultato di amministrazione presunto (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_ammin_lettera_e_rnd');	 
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'tot_disav_amm_rnd','Totale Disavanzo amministrazione (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='tot_disav_amm_rnd');	
	  

	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'disav_iscrit_spesa_rnd','Disavanzo iscritto in spesa del conto del bilancio (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_iscrit_spesa_rnd');
	  

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'patrimonio_netto_rnd','Patrimonio netto (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='patrimonio_netto_rnd');
 	  
	 
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'importo_debiti_fuori_bil_ricon_rnd','Importo Debiti fuori bilancio riconosciuti e finanziati (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='importo_debiti_fuori_bil_ricon_rnd');	  

	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'importo_debiti_fuori_bil_corso_ricon_rnd','Importo debiti fuori bilancio in corso di riconoscimento (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='importo_debiti_fuori_bil_corso_ricon_rnd');	  
	  

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'importo_debiti_fuori_bil_ricon_corso_finanz_rnd','Importo Debiti fuori bilancio riconosciuti e in corso di finanziamento (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='importo_debiti_fuori_bil_ricon_corso_finanz_rnd');	  
	  


INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'input_colonna_a_rnd','Input totale colonna A - Allegato b) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='input_colonna_a_rnd');	  
	  
	  

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'input_colonna_c_rnd','Input totale colonna C - Allegato b) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='input_colonna_c_rnd');	  


INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'a_ris_amm_presunto_rnd','A) Risultato di amministrazione presunto al 31/12 anno precedente - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='a_ris_amm_presunto_rnd');	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'b_tot_parte_accant_rnd','B) Totale parte accantonata - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='b_tot_parte_accant_rnd');	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'c_tot_parte_vinc_rnd','C) Totale parte vincolata - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='c_tot_parte_vinc_rnd');	 

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'd_tot_dest_invest_rnd','D) Totale parte destinata agli investimenti - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='d_tot_dest_invest_rnd');	 

	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'e_tot_parte_disp_rnd','E) Totale parte disponibile - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='e_tot_parte_disp_rnd');	 
	  

/* inserimento dei record dove si registrano i valori */
INSERT INTO  siac_t_conf_indicatori_sint (
voce_conf_ind_id,
  bil_id,
  conf_ind_valore_anno,
  conf_ind_valore_anno_1,
  conf_ind_valore_anno_2,
  conf_ind_valore_tot_miss_13_anno,
  conf_ind_valore_tot_miss_13_anno_1 ,
  conf_ind_valore_tot_miss_13_anno_2 ,
  conf_ind_valore_tutte_spese_anno ,
  conf_ind_valore_tutte_spese_anno_1 ,
  conf_ind_valore_tutte_spese_anno_2 ,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  data_creazione,
  data_modifica,
  data_cancellazione,
  login_operazione)
SELECT t_voce_ind.voce_conf_ind_id, t_bil.bil_id, NULL, NULL, NULL, 
	NULL, NULL, NULL, NULL, NULL, NULL, 
	now(), NULL, t_ente.ente_proprietario_id,  now(), now(), NULL, 'admin'
FROM siac_t_ente_proprietario t_ente,
	siac_t_bil t_bil,
    siac_t_periodo t_periodo,
    siac_t_voce_conf_indicatori_sint t_voce_ind
where t_ente.ente_proprietario_id =t_bil.ente_proprietario_id
	and t_bil.periodo_id=t_periodo.periodo_id
    and t_periodo.anno='2017'
    and t_voce_ind.ente_proprietario_id=t_bil.ente_proprietario_id
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and t_ente.data_cancellazione IS NULL
	and	t_bil.data_cancellazione IS NULL
    and not exists (select 1 
      from siac_t_conf_indicatori_sint z 
      where z.bil_id=t_bil.bil_id 
      and z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_id=t_voce_ind.voce_conf_ind_id);

-- SIAC-5463 e SIAC-6071 - Report indicatori di rendiconto - Maurizio - FINE 

-- SIAC-6094 INIZIO
DROP FUNCTION siac."BILR182_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_dett_rend"(p_ente_prop_id integer, p_anno varchar);

CREATE OR REPLACE FUNCTION siac."BILR182_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_dett_rend" (
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
  residui_attivi numeric,
  residui_attivi_prec numeric,
  totale_residui_attivi numeric,
  importo_minimo_fondo numeric,
  bil_ele_code3 varchar,
  flag_cassa integer,
  accertamenti_succ numeric,
  crediti_stralciati numeric,
  fondo_dubbia_esig numeric,
  perc_media numeric,
  perc_complementare numeric
) AS
$body$
DECLARE

classifBilRec record;
bilancio_id integer;
annoCapImp_int integer;
tipomedia varchar;
RTN_MESSAGGIO text;
BEGIN
RTN_MESSAGGIO:='select 1';

annoCapImp_int:= p_anno::integer; 

select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id=p_ente_prop_id and 
b.periodo_id=a.periodo_id
and b.anno=p_anno;

select attr_bilancio.testo
into tipomedia from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
siac_r_bil_attr attr_bilancio, siac_t_attr attr
where 
bilancio.periodo_id = anno_eserc.periodo_id and
anno_eserc.anno = 	p_anno and
bilancio.bil_id =  attr_bilancio.bil_id and
attr_bilancio.attr_id= attr.attr_id and
attr.attr_code = 'mediaApplicata' and
attr_bilancio.data_cancellazione is null and
attr_bilancio.ente_proprietario_id=p_ente_prop_id;

if tipomedia is null then
   tipomedia = 'SEMPLICE';
end if;

return query
select zz.* from (
with clas as (
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
and d.classif_fam_code = '00003'
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
and d.classif_fam_code = '00003'
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
and d.classif_fam_code = '00003'
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
categoria.ente_proprietario_id
from titent,tipologia,categoria
where titent.titent_id=tipologia.titent_id
and tipologia.tipologia_id=categoria.tipologia_id
),
capall as (
with
cap as (
select
a.elem_id,
a.elem_code,
a.elem_desc,
a.elem_code2,
a.elem_desc2,
a.elem_id_padre,
a.elem_code3,
d.classif_id
from siac_t_bil_elem a,	
     siac_d_bil_elem_tipo b,
     siac_r_bil_elem_class c,
 	 siac_t_class d,	
     siac_d_class_tipo e,
	 siac_r_bil_elem_categoria f,	
     siac_d_bil_elem_categoria g, 
     siac_r_bil_elem_stato h, 
     siac_d_bil_elem_stato i 
where a.ente_proprietario_id = p_ente_prop_id
and   a.bil_id               = bilancio_id
and   a.elem_tipo_id		 = b.elem_tipo_id 
and   b.elem_tipo_code 	     = 'CAP-EG'
and   c.elem_id              = a.elem_id
and   d.classif_id           = c.classif_id
and   e.classif_tipo_id      = d.classif_tipo_id
and   e.classif_tipo_code	 = 'CATEGORIA'
and   g.elem_cat_id          = f.elem_cat_id
and   f.elem_id              = a.elem_id
and	  g.elem_cat_code	     = 'STD'
and   h.elem_id              = a.elem_id
and   i.elem_stato_id        = h.elem_stato_id
and	  i.elem_stato_code	     = 'VA'
and   a.data_cancellazione   is null
and	  b.data_cancellazione   is null
and	  c.data_cancellazione	 is null
and	  d.data_cancellazione	 is null
and	  e.data_cancellazione 	 is null
and	  f.data_cancellazione 	 is null
and	  g.data_cancellazione	 is null
and	  h.data_cancellazione   is null
and	  i.data_cancellazione   is null
), 
resatt as ( -- Residui Attivi 
select capitolo.elem_id,
       sum (dt_movimento.movgest_ts_det_importo) residui_accertamenti,
       CASE 
         WHEN movimento.movgest_anno < annoCapImp_int AND dt_mov_tipo.movgest_ts_det_tipo_code = 'I' THEN
            'RESATT' 
         WHEN movimento.movgest_anno = annoCapImp_int AND dt_mov_tipo.movgest_ts_det_tipo_code = 'A' THEN  
            'ACCERT' 
         ELSE
            'ALTRO'
       END tipo_importo         
from siac_t_bil_elem                  capitolo
inner join siac_r_movgest_bil_elem    r_mov_capitolo on r_mov_capitolo.elem_id = capitolo.elem_id
inner join siac_d_bil_elem_tipo       t_capitolo on capitolo.elem_tipo_id = t_capitolo.elem_tipo_id
inner join siac_t_movgest             movimento on r_mov_capitolo.movgest_id = movimento.movgest_id 
inner join siac_d_movgest_tipo        tipo_mov on movimento.movgest_tipo_id = tipo_mov.movgest_tipo_id 
inner join siac_t_movgest_ts          ts_movimento on movimento.movgest_id = ts_movimento.movgest_id 
inner join siac_r_movgest_ts_stato    r_movimento_stato on ts_movimento.movgest_ts_id = r_movimento_stato.movgest_ts_id 
inner join siac_d_movgest_stato       tipo_stato on r_movimento_stato.movgest_stato_id = tipo_stato.movgest_stato_id
inner join siac_t_movgest_ts_det      dt_movimento on ts_movimento.movgest_ts_id = dt_movimento.movgest_ts_id 
inner join siac_d_movgest_ts_tipo     ts_mov_tipo on ts_movimento.movgest_ts_tipo_id = ts_mov_tipo.movgest_ts_tipo_id
inner join siac_d_movgest_ts_det_tipo dt_mov_tipo on dt_movimento.movgest_ts_det_tipo_id = dt_mov_tipo.movgest_ts_det_tipo_id 
where capitolo.ente_proprietario_id     =   p_ente_prop_id
and   capitolo.bil_id      				=	bilancio_id
and   t_capitolo.elem_tipo_code    		= 	'CAP-EG'
and   movimento.movgest_anno 	        <= 	annoCapImp_int
and   movimento.bil_id					=	bilancio_id
and   tipo_mov.movgest_tipo_code    	=   'A' 
and   tipo_stato.movgest_stato_code     in  ('D','N')
and   ts_mov_tipo.movgest_ts_tipo_code  =   'T'
and   dt_mov_tipo.movgest_ts_det_tipo_code in ('I','A')
and   capitolo.data_cancellazione     	is null 
and   r_mov_capitolo.data_cancellazione is null 
and   t_capitolo.data_cancellazione    	is null 
and   movimento.data_cancellazione     	is null 
and   tipo_mov.data_cancellazione     	is null 
and   r_movimento_stato.data_cancellazione is null 
and   ts_movimento.data_cancellazione   is null 
and   tipo_stato.data_cancellazione    	is null 
and   dt_movimento.data_cancellazione   is null 
and   ts_mov_tipo.data_cancellazione    is null 
and   dt_mov_tipo.data_cancellazione    is null
and   now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
and   now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
group by tipo_importo, capitolo.elem_id
),
resrisc as ( -- Riscossione residui
select 		r_capitolo_ordinativo.elem_id,
            sum(ordinativo_imp.ord_ts_det_importo) importo_residui,
            CASE 
             WHEN movimento.movgest_anno < annoCapImp_int THEN
                'RISRES'
             ELSE
                'RISCOMP'
             END tipo_importo                    
from  --siac_t_bil 						bilancio,
      --siac_t_periodo 					anno_eserc, 
      siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
      siac_t_ordinativo				    ordinativo,
      siac_d_ordinativo_tipo			tipo_ordinativo,
      siac_r_ordinativo_stato			r_stato_ordinativo,
      siac_d_ordinativo_stato			stato_ordinativo,
      siac_t_ordinativo_ts 			    ordinativo_det,
      siac_t_ordinativo_ts_det 		    ordinativo_imp,
      siac_d_ordinativo_ts_det_tipo 	ordinativo_imp_tipo,
      siac_t_movgest     				movimento,
      siac_t_movgest_ts    			    ts_movimento, 
      siac_r_ordinativo_ts_movgest_ts	r_ordinativo_movgest
where 	--anno_eserc.anno					= 	p_anno											
--and	bilancio.periodo_id					=	anno_eserc.periodo_id
--and	bilancio.ente_proprietario_id	    =	p_ente_prop_id
ordinativo_det.ente_proprietario_id	    =	p_ente_prop_id
and	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
and	tipo_ordinativo.ord_tipo_code		= 	'I'	-- Incasso
and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
------------------------------------------------------------------------------------------		
----------------------    LO STATO DEVE ESSERE MODIFICATO IN Q  --- QUIETANZATO    ------		
and	stato_ordinativo.ord_stato_code			<> 'A' -- Annullato
-----------------------------------------------------------------------------------------------
--and	ordinativo.bil_id					=	bilancio.bil_id
and	ordinativo.bil_id					=	bilancio_id
and	ordinativo.ord_id					=	ordinativo_det.ord_id
and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' 	-- Importo attuale
---------------------------------------------------------------------------------------------------------------------
and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
and	ts_movimento.movgest_id				=	movimento.movgest_id
and	movimento.movgest_anno				<=	annoCapImp_int	
--and movimento.bil_id					=	bilancio.bil_id	
and movimento.bil_id					=	bilancio_id	
--------------------------------------------------------------------------------------------------------------------		
--and	bilancio.data_cancellazione 				is null
--and	anno_eserc.data_cancellazione 				is null
and	r_capitolo_ordinativo.data_cancellazione	is null
and	ordinativo.data_cancellazione				is null
and	tipo_ordinativo.data_cancellazione			is null
and	r_stato_ordinativo.data_cancellazione		is null
and	stato_ordinativo.data_cancellazione			is null
and ordinativo_det.data_cancellazione			is null
and ordinativo_imp.data_cancellazione			is null
and ordinativo_imp_tipo.data_cancellazione		is null
and	movimento.data_cancellazione				is null
and	ts_movimento.data_cancellazione				is null
and	r_ordinativo_movgest.data_cancellazione		is null
and now() between r_capitolo_ordinativo.validita_inizio and COALESCE(r_capitolo_ordinativo.validita_fine,now())
and now() between r_stato_ordinativo.validita_inizio and COALESCE(r_stato_ordinativo.validita_fine,now())
and now() between r_ordinativo_movgest.validita_inizio and COALESCE(r_ordinativo_movgest.validita_fine,now())
group by tipo_importo, r_capitolo_ordinativo.elem_id
),
resriacc as ( -- Riaccertamenti residui
select capitolo.elem_id,
       sum (t_movgest_ts_det_mod.movgest_ts_det_importo) riaccertamenti_residui
from --siac_t_bil      bilancio, 
     --siac_t_periodo     anno_eserc, 
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
     siac_d_movgest_ts_det_tipo  dt_mov_tipo ,
     siac_t_modifica t_modifica,
     siac_r_modifica_stato r_mod_stato,
     siac_d_modifica_stato d_mod_stato,
     siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
     where --bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
     --and anno_eserc.anno       			=   p_anno
     --and bilancio.bil_id      				=	capitolo.bil_id
     capitolo.bil_id      				=	bilancio_id
     and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
     and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
     and movimento.movgest_anno 	< 	annoCapImp_int
     --and movimento.bil_id					=	bilancio.bil_id
     and movimento.bil_id					=	bilancio_id
     and r_mov_capitolo.elem_id    		=	capitolo.elem_id
     and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
     and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
     and tipo_mov.movgest_tipo_code    	= 'A' 
     and movimento.movgest_id      		= 	ts_movimento.movgest_id 
     and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
     and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
     and tipo_stato.movgest_stato_code   in ('D','N')
     and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
     and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
     and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
     and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
     and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' -- Importo attuale 
     and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
     and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
     and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
     and d_mod_stato.mod_stato_code='V'
     and r_mod_stato.mod_id=t_modifica.mod_id
     and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
     and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
     and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
     --and anno_eserc.data_cancellazione    	is null 
     --and bilancio.data_cancellazione     	is null 
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
     and t_movgest_ts_det_mod.data_cancellazione    is null
     and r_mod_stato.data_cancellazione    is null
     and t_modifica.data_cancellazione    is null
     and capitolo.ente_proprietario_id   = p_ente_prop_id
     group by capitolo.elem_id	
),
minfondo as ( -- Importo minimo del fondo
SELECT
 rbilelem.elem_id, 
 CASE 
   WHEN tipomedia = 'SEMPLICE' THEN
        round((COALESCE(datifcd.perc_acc_fondi,0)+
        COALESCE(datifcd.perc_acc_fondi_1,0)+
        COALESCE(datifcd.perc_acc_fondi_2,0)+
        COALESCE(datifcd.perc_acc_fondi_3,0)+
        COALESCE(datifcd.perc_acc_fondi_4,0))/5,2)
   ELSE
        round((COALESCE(datifcd.perc_acc_fondi,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_1,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_2,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_3,0)*0.35+
        COALESCE(datifcd.perc_acc_fondi_4,0)*0.35),2)
 END perc_media
 -- ,1 flag_cassa -- SIAC-5854
 , 1 flag_fondo -- SIAC-5854
 FROM siac_t_acc_fondi_dubbia_esig datifcd, siac_r_bil_elem_acc_fondi_dubbia_esig rbilelem
 WHERE rbilelem.acc_fde_id = datifcd.acc_fde_id 
 AND   datifcd.ente_proprietario_id = p_ente_prop_id 
 AND   rbilelem.data_cancellazione is null
),
accertcassa as ( -- Accertato per cassa -- SIAC-5854
SELECT rbea.elem_id, 0 flag_cassa
FROM   siac_r_bil_elem_attr rbea, siac_t_attr ta
WHERE  rbea.attr_id = ta.attr_id
AND    rbea.data_cancellazione is null
AND    ta.data_cancellazione is null
AND    ta.attr_code = 'FlagAccertatoPerCassa'
AND    ta.ente_proprietario_id = p_ente_prop_id
AND    rbea."boolean" = 'S'
),
acc_succ as ( -- Accertamenti imputati agli esercizi successivi a quello cui il rendiconto si riferisce

select capitolo.elem_id,
       --sum (t_movgest_ts_det_mod.movgest_ts_det_importo) accertamenti_succ
       sum (dt_movimento.movgest_ts_det_importo) accertamenti_succ
from --siac_t_bil      bilancio, 
     --siac_t_periodo     anno_eserc, 
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
     --,siac_t_modifica t_modifica,
     --siac_r_modifica_stato r_mod_stato,
     --siac_d_modifica_stato d_mod_stato,
     --siac_t_movgest_ts_det_mod t_movgest_ts_det_mod--,
     --siac_r_movgest_ts_attr r_movgest_ts_attr,
     --siac_t_attr t_attr 
     where --bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
     --and anno_eserc.anno       			=   p_anno
     --and bilancio.bil_id      				=	capitolo.bil_id
     capitolo.bil_id      				=	bilancio_id
     and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
     and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
     and movimento.movgest_anno 	> 	annoCapImp_int
     --and movimento.bil_id					=	bilancio.bil_id
     and movimento.bil_id					=	bilancio_id
     and r_mov_capitolo.elem_id    		=	capitolo.elem_id
     and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
     and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
     and tipo_mov.movgest_tipo_code    	= 'A' 
     and movimento.movgest_id      		= 	ts_movimento.movgest_id 
     and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
     and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
     and tipo_stato.movgest_stato_code   in ('D','N')
     and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
     and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
     and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
     and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
     and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' -- Importo attuale 
     --and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
     --and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
     --and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
     --and d_mod_stato.mod_stato_code='V'
     --and r_mod_stato.mod_id=t_modifica.mod_id
     --and r_movgest_ts_attr.movgest_ts_id = ts_movimento.movgest_ts_id
     --and r_movgest_ts_attr.attr_id = t_attr.attr_id
     --and t_attr.attr_code = 'annoOriginePlur'
     --and r_movgest_ts_attr.testo <= p_anno
     and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
     and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
     --and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
     --and anno_eserc.data_cancellazione    	is null 
     --and bilancio.data_cancellazione     	is null 
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
     --and t_movgest_ts_det_mod.data_cancellazione    is null
     --and r_mod_stato.data_cancellazione    is null
     --and t_modifica.data_cancellazione    is null
     and capitolo.ente_proprietario_id   = p_ente_prop_id
     group by capitolo.elem_id	
     
     
     
),
cred_stra as ( -- Crediti stralciati

 select    
   capitolo.elem_id,
   abs(sum (t_movgest_ts_det_mod.movgest_ts_det_importo)) crediti_stralciati
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
      siac_d_movgest_ts_det_tipo  dt_mov_tipo ,
      siac_t_modifica t_modifica,
      siac_d_modifica_tipo d_modif_tipo,
      siac_r_modifica_stato r_mod_stato,
      siac_d_modifica_stato d_mod_stato,
      siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
      where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
      and anno_eserc.anno       			=   p_anno
      and bilancio.bil_id      				=	capitolo.bil_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      and movimento.movgest_anno 	        <= 	annoCapImp_int
      and movimento.bil_id					=	bilancio.bil_id
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and tipo_mov.movgest_tipo_code    	= 'A' 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
      and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
      and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
      and d_mod_stato.mod_stato_code='V'
      and r_mod_stato.mod_id=t_modifica.mod_id
      and d_modif_tipo.mod_tipo_id = t_modifica.mod_tipo_id
      /*and ((d_modif_tipo.mod_tipo_code in ('CROR','ECON') and p_anno <= '2016')
            or
           (d_modif_tipo.mod_tipo_code like 'FCDE%' and p_anno >= '2017')
          ) */
      and d_modif_tipo.mod_tipo_code in ('CROR','ECON')    
      and t_movgest_ts_det_mod.movgest_ts_det_importo < 0
      and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
 	  and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
	  and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
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
      and t_movgest_ts_det_mod.data_cancellazione    is null
      and r_mod_stato.data_cancellazione    is null
      and t_modifica.data_cancellazione    is null
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id
group by capitolo.elem_id
)
select 
cap.elem_id bil_ele_id,
cap.elem_code bil_ele_code,
cap.elem_desc bil_ele_desc,
cap.elem_code2 bil_ele_code2,
cap.elem_desc2 bil_ele_desc2,
cap.elem_id_padre bil_ele_id_padre,
cap.elem_code3 bil_ele_code3,
cap.classif_id categoria_id,
coalesce(resatt1.residui_accertamenti,0) residui_attivi,
(coalesce(resatt1.residui_accertamenti,0) -
coalesce(resrisc1.importo_residui,0) +
coalesce(resriacc.riaccertamenti_residui,0)) residui_attivi_prec,
coalesce(minfondo.perc_media,0) perc_media,
-- minfondo.flag_cassa, -- SIAC-5854
coalesce(minfondo.flag_fondo,0) flag_fondo, -- SIAC-5854
coalesce(accertcassa.flag_cassa,1) flag_cassa, -- SIAC-5854
coalesce(acc_succ.accertamenti_succ,0) accertamenti_succ,
coalesce(cred_stra.crediti_stralciati,0) crediti_stralciati,
coalesce(resrisc2.importo_residui,0) residui_competenza,
coalesce(resatt2.residui_accertamenti,0) accertamenti,
(coalesce(resatt2.residui_accertamenti,0) -
 coalesce(resrisc2.importo_residui,0)) importo_finale
from cap
left join resatt resatt1
on cap.elem_id=resatt1.elem_id and resatt1.tipo_importo = 'RESATT'
left join resatt resatt2
on cap.elem_id=resatt2.elem_id and resatt2.tipo_importo = 'ACCERT'
left join resrisc resrisc1
on cap.elem_id=resrisc1.elem_id and resrisc1.tipo_importo = 'RISRES'
left join resrisc resrisc2
on cap.elem_id=resrisc2.elem_id and resrisc2.tipo_importo = 'RISCOMP'
left join resriacc
on cap.elem_id=resriacc.elem_id
left join minfondo
on cap.elem_id=minfondo.elem_id
left join accertcassa
on cap.elem_id=accertcassa.elem_id
left join acc_succ
on cap.elem_id=acc_succ.elem_id
left join cred_stra
on cap.elem_id=cred_stra.elem_id
),
fondo_dubbia_esig as (
select  importi.repimp_desc programma_code,
        coalesce(importi.repimp_importo,0) imp_fondo_dubbia_esig
from 	siac_t_report					report,
		siac_t_report_importi 			importi,
		siac_r_report_importi 			r_report_importi,
		siac_t_bil 						bilancio,
	 	siac_t_periodo 					anno_eserc,
        siac_t_periodo 					anno_comp
where 	report.rep_codice				=	'BILR148'   				
and     report.ente_proprietario_id		=	p_ente_prop_id				
and		anno_eserc.anno					=	p_anno 						
and     bilancio.periodo_id				=	anno_eserc.periodo_id 		
and     importi.bil_id					=	bilancio.bil_id 			
and     r_report_importi.rep_id			=	report.rep_id				
and     r_report_importi.repimp_id		=	importi.repimp_id			
and     importi.periodo_id 				=	anno_comp.periodo_id
and     report.data_cancellazione is null
and     importi.data_cancellazione is null
and     r_report_importi.data_cancellazione is null
and     anno_eserc.data_cancellazione is null
and     anno_comp.data_cancellazione is null
and     importi.repimp_desc <> ''
and     importi.repimp_codice = 'Colonna E Allegato c) FCDE Rendiconto'
)
select 
p_anno::varchar bil_anno,
''::varchar titent_tipo_code,
clas.titent_tipo_desc::varchar,
clas.titent_code::varchar,
clas.titent_desc::varchar,
''::varchar tipologia_tipo_code,
clas.tipologia_tipo_desc::varchar,
clas.tipologia_code::varchar,
clas.tipologia_desc::varchar,
''::varchar	categoria_tipo_code,
clas.categoria_tipo_desc::varchar,
clas.categoria_code::varchar,
clas.categoria_desc::varchar,
capall.bil_ele_code::varchar,
capall.bil_ele_desc::varchar,
capall.bil_ele_code2::varchar,
capall.bil_ele_desc2::varchar,
capall.bil_ele_id::integer,
capall.bil_ele_id_padre::integer,
COALESCE(capall.importo_finale::numeric,0) residui_attivi,
COALESCE(capall.residui_attivi_prec::numeric,0) residui_attivi_prec,
COALESCE(capall.importo_finale::numeric + capall.residui_attivi_prec::numeric,0) totale_residui_attivi,
CASE
 --WHEN perc_media::numeric <> 0 THEN
 WHEN capall.flag_cassa::numeric = 1 AND capall.flag_fondo::numeric = 1 THEN
  COALESCE(round((capall.importo_finale::numeric + capall.residui_attivi_prec::numeric) * (1 - capall.perc_media::numeric/100),2),0)
 ELSE
 0
END 
importo_minimo_fondo,
capall.bil_ele_code3::varchar,
--COALESCE(capall.flag_cassa::integer,0) flag_cassa, -- SAIC-5854
COALESCE(capall.flag_cassa::integer,1) flag_cassa, -- SAIC-5854       
COALESCE(capall.accertamenti_succ::numeric,0) accertamenti_succ,
COALESCE(capall.crediti_stralciati::numeric,0) crediti_stralciati,
imp_fondo_dubbia_esig,
COALESCE(capall.perc_media::numeric,0) perc_media,
CASE
 --WHEN perc_media::numeric <> 0 THEN
 WHEN capall.flag_cassa::numeric = 1 AND capall.flag_fondo::numeric = 1 THEN
  (100 - COALESCE(capall.perc_media,0))::numeric
 ELSE
 0
END 
perc_complementare
from clas 
left join capall on clas.categoria_id = capall.categoria_id  
left join fondo_dubbia_esig on fondo_dubbia_esig.programma_code = clas.tipologia_code   
) as zz;

/*raise notice 'query: %',queryfin;
RETURN QUERY queryfin;*/

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
-- SIAC-6094 FINE

