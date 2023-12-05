/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR165_rend_trasparenza_spese" (
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
id_bil integer;

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


/* SIAC-7014 19/09/2019.
	Modifiche alla prcedura per motivi di prestazioni:
    - inserita la gestione con with togliendo le tabelle di appoggio;
    - id del bilancio letto all'inizio.

*/

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

select bilancio.bil_id
into id_bil
from siac_t_bil bilancio,
     siac_t_periodo anno_eserc
where bilancio.periodo_id=anno_eserc.periodo_id
	and bilancio.ente_proprietario_id=p_ente_prop_id
    and anno_eserc.anno=p_anno
	and anno_eserc.data_cancellazione IS NULL
	and anno_eserc.data_cancellazione IS NULL;
    
return query 
	with struttura_capitoli as (
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
              --insert into siac_rep_mis_pro_tit_mac_riga_anni
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
             -- ,user_table
              from missione , programma,titusc, macroag
                  /* 02/09/2016: start filtro per mis-prog-macro*/
                  --, siac_r_class progmacro
                  /*end filtro per mis-prog-macro*/
               where programma.missione_id=missione.missione_id
               and titusc.titusc_id=macroag.titusc_id
                /* 02/09/2016: start filtro per mis-prog-macro*/
               --AND programma.programma_id = progmacro.classif_a_id
              --AND titusc.titusc_id = progmacro.classif_b_id
               /* end filtro per mis-prog-macro*/ 
               and titusc.ente_proprietario_id=missione.ente_proprietario_id),
    	capitoli as (
        	select 	programma.classif_id programma_id,
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
              where               			
                  programma.classif_tipo_id=programma_tipo.classif_tipo_id 				
                  and programma.classif_id=r_capitolo_programma.classif_id			    
                  and macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				
                  and macroaggr.classif_id=r_capitolo_macroaggr.classif_id					                       								                  										
                  and capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 											     	 
                  and capitolo.elem_id=r_capitolo_programma.elem_id							
                  and capitolo.elem_id=r_capitolo_macroaggr.elem_id							
                  and capitolo.elem_id				=	r_capitolo_stato.elem_id			
                  and r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id			
                  and capitolo.elem_id				=	r_cat_capitolo.elem_id				
                  and r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		
                  and capitolo.ente_proprietario_id=p_ente_prop_id    
                  and capitolo.bil_id=id_bil  						   								
                  and tipo_elemento.elem_tipo_code = elemTipoCode				
                  and stato_capitolo.elem_stato_code	=	'VA'								
                  -- 02/09/2016: aggiunto FPVC
                  and cat_del_capitolo.elem_cat_code	in	('STD','FPV','FSC','FPVC')			
                  and programma_tipo.classif_tipo_code='PROGRAMMA' 							
                  and macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						
                      -- ANNA 2206 FSC			
                  and r_capitolo_programma.validita_fine is null
                  and r_capitolo_macroaggr.validita_fine is null
                  and stato_capitolo.validita_fine is null
                  and r_capitolo_stato.validita_fine is null
                  and cat_del_capitolo.validita_fine is null
                  and r_cat_capitolo.validita_fine is null                  
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
            impegni as (
            	select r_mov_capitolo.elem_id,
              		  sum (dt_movimento.movgest_ts_det_importo) importo_impegni
                  from siac_r_movgest_bil_elem   r_mov_capitolo, 
                    siac_t_movgest     movimento, 
                    siac_d_movgest_tipo    tipo_mov, 
                    siac_t_movgest_ts    ts_movimento, 
                    siac_r_movgest_ts_stato   r_movimento_stato, 
                    siac_d_movgest_stato    tipo_stato, 
                    siac_t_movgest_ts_det   dt_movimento, 
                    siac_d_movgest_ts_det_tipo  dt_mov_tipo 
                    where r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
                    and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id                      
                    and movimento.movgest_id      		= 	ts_movimento.movgest_id 
                    and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
                    and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
                    and movimento.ente_proprietario_id   = p_ente_prop_id
                    and movimento.bil_id = id_bil
                    and movimento.movgest_anno = p_anno_int
                    and tipo_mov.movgest_tipo_code    	= 'I'
                    -- D= DEFINITIVO, N= DEFINITIVO NON LIQUIDABILE
                    -- P=PROVVISORIO, A= ANNULLATO
                    and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N       
                    and ts_movimento.movgest_ts_id_padre is null
                    and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
                    and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
                    and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale       
                    and movimento.validita_fine is null
                    and ts_movimento.validita_fine is null
                    and r_mov_capitolo.validita_fine is null
                    and r_movimento_stato.validita_fine is null                   
                    and r_mov_capitolo.data_cancellazione is null 
                    and movimento.data_cancellazione     	is null 
                    and tipo_mov.data_cancellazione     	is null 
                    and r_movimento_stato.data_cancellazione   is null 
                    and ts_movimento.data_cancellazione   is null 
                    and tipo_stato.data_cancellazione    	is null 
                    and dt_movimento.data_cancellazione   is null  
                    and dt_mov_tipo.data_cancellazione    is null
              group by r_mov_capitolo.elem_id),
            pagamenti as (
            	select 		r_capitolo_ordinativo.elem_id,
                            sum(ordinativo_imp.ord_ts_det_importo) importo_pag
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
                            siac_r_liquidazione_movgest     r_liqmovgest,
                            siac_r_liquidazione_ord         r_liqord     
                    where 	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
                        and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id		
                        and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
                        and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id                               
                        and	ordinativo.ord_id					=	ordinativo_det.ord_id
                        and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
                        and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
                        and r_liqord.sord_id                    =   ordinativo_det.ord_ts_id
                        and	r_liqord.liq_id		                =	r_liqmovgest.liq_id
                        and	r_liqmovgest.movgest_ts_id	        =	ts_movimento.movgest_ts_id
                        and	ts_movimento.movgest_id				=	movimento.movgest_id
                        and ordinativo.bil_id					=	id_bil	
                        and	ordinativo.ente_proprietario_id	=	p_ente_prop_id
                        and	tipo_ordinativo.ord_tipo_code		= 	'P'		------ PAGATO
                         ------------------------------------------------------------------------------------------		
                        ----------------------    si prendono gli stati Q, F, T
                        ----------------------	  da verificare se + giusto.
                        -- Q= QUIETANZATO, F= FIRMATO, T= TRASMESSO
                        -- I= INSERITO, A= ANNULLATO
                        and	stato_ordinativo.ord_stato_code		<>'A' --- 
                        and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' ---- importo attuale        
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
                        and r_capitolo_ordinativo.validita_fine is null
                        and r_stato_ordinativo.validita_fine is null
                        and r_liqord.validita_fine is null
                        and r_liqmovgest.validita_fine is null
                        group by r_capitolo_ordinativo.elem_id),
     capitoli_fpv as (
     	select 	capitolo_importi.elem_id,			
           	sum(capitolo_importi.elem_det_importo) importo_fpv      
	from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_d_bil_elem_tipo 		tipo_elemento,            
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
    where 	capitolo.elem_id						=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id					=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 			= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id		=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id												
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		
        and capitolo_importi.ente_proprietario_id 	=	p_ente_prop_id  
        and	capitolo.bil_id							=	id_bil
        and	capitolo_imp_periodo.anno = annoCapImp
        and capitolo_imp_tipo.elem_det_tipo_code = TipoImpstanz
        and	stato_capitolo.elem_stato_code	=	'VA'
		-- 02/09/2016: aggiunto FPVC
        and	cat_del_capitolo.elem_cat_code	in	('FPV','FPVC')								
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
    group by	capitolo_importi.elem_id)
select p_anno::varchar bil_anno,
		''::varchar missione_tipo_code,
        struttura_capitoli.missione_tipo_desc::varchar missione_tipo_desc,
        struttura_capitoli.missione_code::varchar missione_code,
        struttura_capitoli.missione_desc::varchar missione_desc,
        ''::varchar programma_tipo_code,
        struttura_capitoli.programma_tipo_desc::varchar programma_tipo_desc,
        struttura_capitoli.programma_code::varchar programma_code,
        struttura_capitoli.programma_desc::varchar programma_desc,
        ''::varchar titusc_tipo_code,
        struttura_capitoli.titusc_tipo_desc::varchar titusc_tipo_desc,
        struttura_capitoli.titusc_code::varchar titusc_code,
        struttura_capitoli.titusc_desc::varchar titusc_desc,
        ''::varchar macroag_tipo_code,
        struttura_capitoli.macroag_tipo_desc::varchar macroag_tipo_desc,
        struttura_capitoli.macroag_code::varchar macroag_code,
        struttura_capitoli.macroag_desc::varchar macroag_desc,
        capitoli.elem_code::varchar bil_ele_code,
        capitoli.elem_desc::varchar bil_ele_desc,
        capitoli.elem_code2::varchar bil_ele_code2,
        capitoli.elem_desc2::varchar bil_ele_desc2,
        capitoli.elem_id::integer bil_ele_id,
        capitoli.elem_id_padre::integer bil_ele_id_padre,
        COALESCE(impegni.importo_impegni,0)::numeric impegnato,
        COALESCE(pagamenti.importo_pag,0)::numeric pagato,
        COALESCE(capitoli_fpv.importo_fpv,0)::numeric fpv
	from struttura_capitoli 
    	left join  capitoli 
        	on (capitoli.programma_id= struttura_capitoli.programma_id and
            	capitoli.macroag_id= struttura_capitoli.macroag_id) 
        left join impegni
        	on impegni.elem_id = capitoli.elem_id
    	left join pagamenti
        	on pagamenti.elem_id = capitoli.elem_id
        left join capitoli_fpv
        	on capitoli_fpv.elem_id = capitoli.elem_id
    order by missione_code,programma_code,titusc_code,macroag_code;


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