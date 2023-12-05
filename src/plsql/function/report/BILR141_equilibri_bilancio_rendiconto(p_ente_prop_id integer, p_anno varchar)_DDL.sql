/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR141_equilibri_bilancio_rendiconto" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  anno varchar,
  titolo varchar,
  cap_entrata_spesa varchar,
  tipo_capitolo varchar,
  codice_importo varchar,
  pdc_fin varchar,
  importo numeric,
  macroagg varchar
) AS
$body$
DECLARE

DEF_NULL	  constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

rec_imp_acc    record;
rec_capitoli_1 record; 
rec_capitoli_2 record; 
rec_fin        record;
user_table	   varchar;
p_anno_int 	   integer;
BEGIN

--SIAC-7192 24/02/2020.
-- Aggiunta la colonna macroagg in output.

  RTN_MESSAGGIO:='lettura user table ''.';
  select fnc_siac_random_user()
  into	user_table;

  anno := '';
  titolo := '';
  cap_entrata_spesa := '';
  tipo_capitolo := '';
  codice_importo := '';
  pdc_fin :=  '';
  importo := 0;
  p_anno_int = p_anno::varchar;

  RTN_MESSAGGIO:='acquisizione importi per impegni e accertamenti''.';  
  raise notice 'acquisizione importi per impegni e accertamenti';
  raise notice 'ora: % ',clock_timestamp()::varchar;


   FOR rec_imp_acc IN 
   WITH movimenti_imp_acc AS 
         (select    
          m.movgest_anno::VARCHAR,
          ts.movgest_ts_id,
          e.elem_id,
          d_bil_elem_cat.elem_cat_code,
          --et.elem_tipo_code,
          --mt.movgest_tipo_code,        
          --sum (tsd.movgest_ts_det_importo) importo
          tsd.movgest_ts_det_importo
          from 
            siac_t_bil b, 
            siac_t_periodo p, 
            siac_t_bil_elem e,
            siac_d_bil_elem_tipo et,
            siac_r_movgest_bil_elem rm, 
            siac_t_movgest m,
            siac_d_movgest_tipo mt,
            siac_t_movgest_ts ts  ,
            siac_d_movgest_ts_tipo   tsti, 
            siac_r_movgest_ts_stato tsrs,
            siac_d_movgest_stato mst, 
            siac_t_movgest_ts_det   tsd ,
            siac_d_movgest_ts_det_tipo  tsdt,
            siac_r_bil_elem_categoria r_bil_elem_cat,
            siac_d_bil_elem_categoria d_bil_elem_cat
          where 
          b.periodo_id					=	p.periodo_id 
          and p.ente_proprietario_id   	= 	p_ente_prop_id
          and p.anno          			=   p_anno 
          and b.bil_id 					= 	e.bil_id
          and e.elem_tipo_id			=	et.elem_tipo_id
          and et.elem_tipo_code      	in 	('CAP-UG','CAP-EG')
          and rm.elem_id      			= 	e.elem_id
          and rm.movgest_id      		=  	m.movgest_id 
          -- and now() between rm.validita_inizio and coalesce (rm.validita_fine, now())
          and m.movgest_anno            =   p_anno_int
          and m.movgest_tipo_id			= 	mt.movgest_tipo_id 
          and mt.movgest_tipo_code		in ('I','A') 
          and m.movgest_id				=	ts.movgest_id
          and ts.movgest_ts_id			=	tsrs.movgest_ts_id 
          and tsrs.movgest_stato_id  	= 	mst.movgest_stato_id 
          and tsti.movgest_ts_tipo_code  = 'T' 
          and mst.movgest_stato_code   in ('D','N') -- Definitivo e definitivo non liquidabile
          ---and now() between tsrs.validita_inizio and coalesce (tsrs.validita_fine, now())
          and ts.movgest_ts_tipo_id  	= 	tsti.movgest_ts_tipo_id 
          and ts.movgest_ts_id     		= 	tsd.movgest_ts_id 
          and tsd.movgest_ts_det_tipo_id  = tsdt.movgest_ts_det_tipo_id 
          and r_bil_elem_cat.elem_id = e.elem_id
          and r_bil_elem_cat.elem_cat_id= d_bil_elem_cat.elem_cat_id
          and tsdt.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
/*          and now() between b.validita_inizio and coalesce (b.validita_fine, now())
          and now() between p.validita_inizio and coalesce (p.validita_fine, now())
          and now() between e.validita_inizio and coalesce (e.validita_fine, now())
          and now() between et.validita_inizio and coalesce (et.validita_fine, now())
          and now() between rm.validita_inizio and coalesce (rm.validita_fine, now())
          and now() between m.validita_inizio and coalesce (m.validita_fine, now())
          and now() between mt.validita_inizio and coalesce (mt.validita_fine, now())
          and now() between ts.validita_inizio and coalesce (ts.validita_fine, now())          
          and now() between tsti.validita_inizio and coalesce (tsti.validita_fine, now())
          and now() between tsrs.validita_inizio and coalesce (tsrs.validita_fine, now())
          and now() between mst.validita_inizio and coalesce (mst.validita_fine, now())
          and now() between tsd.validita_inizio and coalesce (tsd.validita_fine, now())
          and now() between tsdt.validita_inizio and coalesce (tsdt.validita_fine, now())*/
          and b.validita_fine is null
          and p.validita_fine is null
          and e.validita_fine is null
          and et.validita_fine is null
          and rm.validita_fine is null
          and m.validita_fine is null
          and mt.validita_fine is null
          and ts.validita_fine is null
          and tsti.validita_fine is null
          and tsrs.validita_fine is null
          and mst.validita_fine is null
          and tsd.validita_fine is null
          and tsdt.validita_fine is null
          and p.data_cancellazione     	is null 
          and b.data_cancellazione      is null 
          and e.data_cancellazione      is null     
          and et.data_cancellazione     is null 
          and rm.data_cancellazione 	is null 
          and m.data_cancellazione      is null 
          and mt.data_cancellazione     is null 
          and ts.data_cancellazione   	is null 
          and tsti.data_cancellazione   is null 
          and tsrs.data_cancellazione   is null 
          and mst.data_cancellazione    is null 
          and tsd.data_cancellazione   	is null 
          and tsdt.data_cancellazione   is null     
          and r_bil_elem_cat.data_cancellazione   is null  
          and d_bil_elem_cat.data_cancellazione   is null  
          --group by m.movgest_anno, ts.movgest_ts_id
  ),
  /*pdc_finanziario as
  ( select tc.classif_code, rmc.movgest_ts_id
   from   siac_r_movgest_class rmc, siac_t_class tc, siac_d_class_tipo dct
   where  dct.ente_proprietario_id = p_ente_prop_id
   and    rmc.classif_id = tc.classif_id
   and    tc.classif_tipo_id = dct.classif_tipo_id
   and    dct.classif_tipo_code = 'PDC_V'
   and    rmc.data_cancellazione  is null
   and    tc.data_cancellazione   is null 
   and    dct.data_cancellazione  is null
   and    rmc.validita_fine  is null
   and    tc.validita_fine   is null 
   and    dct.validita_fine  is null   
/*   and now() between rmc.validita_inizio and coalesce (rmc.validita_fine, now())
   and now() between tc.validita_inizio and coalesce (tc.validita_fine, now())
   and now() between dct.validita_inizio and coalesce (dct.validita_fine, now())*/
   )*/ 
   pdc_finanziario as
  ( select tc.classif_code, rmc.elem_id
   from   siac_r_bil_elem_class rmc, siac_t_class tc, siac_d_class_tipo dct,
   			siac_t_bil b, 
            siac_t_periodo p, 
            siac_t_bil_elem e
   where  dct.ente_proprietario_id = p_ente_prop_id
   and    rmc.classif_id = tc.classif_id
   and    tc.classif_tipo_id = dct.classif_tipo_id
   and    dct.classif_tipo_code in ( 'PDC_V', 'PDC_IV')
   and    e.elem_id = rmc.elem_id
   and    e.bil_id = b.bil_id
   and    b.periodo_id = p.periodo_id 
   and    p.anno = p_anno
   and    rmc.data_cancellazione  is null
   and    tc.data_cancellazione   is null 
   and    dct.data_cancellazione  is null
   -- and   rmc.validita_fine  is null -- INC000001838287
   and    to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between rmc.validita_inizio and COALESCE(rmc.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy')) -- INC000001838287    
   -- and   tc.validita_fine is null    -- INC000001838287
   -- and   dct.validita_fine  is null  -- INC000001838287  
/*   and now() between rmc.validita_inizio and coalesce (rmc.validita_fine, now())
   and now() between tc.validita_inizio and coalesce (tc.validita_fine, now())
   and now() between dct.validita_inizio and coalesce (dct.validita_fine, now())*/
   )
  select
  movimenti_imp_acc.movgest_anno,
  movimenti_imp_acc.elem_cat_code,
  --movimenti_imp_acc.elem_tipo_code,
  --movimenti_imp_acc.movgest_tipo_code, 
  SUM(COALESCE(movimenti_imp_acc.movgest_ts_det_importo,0)) importo,
  pdc_finanziario.classif_code pdc
  from movimenti_imp_acc, pdc_finanziario
  where 
  --movimenti_imp_acc.movgest_ts_id = pdc_finanziario.movgest_ts_id
  movimenti_imp_acc.elem_id = pdc_finanziario.elem_id
  group by 
  movimenti_imp_acc.movgest_anno, 
  movimenti_imp_acc.elem_cat_code,
  --movimenti_imp_acc.elem_tipo_code,
  --movimenti_imp_acc.movgest_tipo_code, 
  pdc_finanziario.classif_code  

  LOOP
  
    INSERT INTO siac_rep_gest_equi_bil_imp
      ( ente_proprietario_id,
        anno,
        titolo,
        cap_entrata_spesa,
        tipo_capitolo,
        codice_importo,
        pdc_fin,
        importo,
        utente,
        macroagg
      )  
    VALUES
      ( p_ente_prop_id,
        rec_imp_acc.movgest_anno,
        null,
        null,
        rec_imp_acc.elem_cat_code,-- null,
        null,
        rec_imp_acc.pdc,
        rec_imp_acc.importo,
        user_table,
        null
      );  
  
  END LOOP;
  
raise notice 'ora: % ',clock_timestamp()::varchar;  
RTN_MESSAGGIO:='acquisizione importi per capitoli AAM, FPVCC, FPVSC''.';  
raise notice 'acquisizione importi per capitoli AAM, FPVCC, FPVSC';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
  FOR rec_capitoli_1 IN
        select 		
			capitolo_imp_periodo.anno            anno_competenza,
			tipo_elemento.elem_tipo_code         tipo_capitolo_cod,
            capitolo_imp_tipo.elem_det_tipo_code tipo_capitolo,			
            cat_del_capitolo.elem_cat_code	     codice_importo,			
            sum(coalesce(capitolo_importi.elem_det_importo,0)) importo            
        from 		
            siac_t_bil_elem_det capitolo_importi,
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
        where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id
        and	anno_eserc.anno						= 	p_anno						
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 'CAP-EG'
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
        and	capitolo_imp_tipo.elem_det_tipo_code	= 'STI'
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno           =   p_anno
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=   'AAM'	
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
        and	capitolo_importi.validita_fine	is null
        and	capitolo_imp_tipo.validita_fine 	is null
        and	capitolo_imp_periodo.validita_fine is null
        and	capitolo.validita_fine 			is null
        and	tipo_elemento.validita_fine 		is null
        and	bilancio.validita_fine 			is null
        and	anno_eserc.validita_fine 			is null
        and	stato_capitolo.validita_fine 		is null
        and	r_capitolo_stato.validita_fine 	is null
        and	cat_del_capitolo.validita_fine 	is null
        and	r_cat_capitolo.validita_fine 		is null        
        group by 
		capitolo_imp_periodo.anno,
		tipo_elemento.elem_tipo_code,
		capitolo_imp_tipo.elem_det_tipo_code,		
		cat_del_capitolo.elem_cat_code
        UNION
        select 		
			capitolo_imp_periodo.anno            anno_competenza,
			tipo_elemento.elem_tipo_code         tipo_capitolo_cod,
            capitolo_imp_tipo.elem_det_tipo_code tipo_capitolo,			
            cat_del_capitolo.elem_cat_code	     codice_importo,			
            sum(coalesce(capitolo_importi.elem_det_importo,0)) importo            
        from 		
            siac_t_bil_elem_det capitolo_importi,
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
        where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id
        and	anno_eserc.anno						= 	p_anno						
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		=   'CAP-EG'
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
        and	capitolo_imp_tipo.elem_det_tipo_code	= 'STA'
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno           =   p_anno
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		in ('AAM','FPVCC','FPVSC')	
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
        and	capitolo_importi.validita_fine 	is null
        and	capitolo_imp_tipo.validita_fine 	is null
        and	capitolo_imp_periodo.validita_fine is null
        and	capitolo.validita_fine 			is null
        and	tipo_elemento.validita_fine 		is null
        and	bilancio.validita_fine 			is null
        and	anno_eserc.validita_fine 			is null
        and	stato_capitolo.validita_fine 		is null
        and	r_capitolo_stato.validita_fine 	is null
        and	cat_del_capitolo.validita_fine 	is null
        and	r_cat_capitolo.validita_fine 		is null        
        group by 
		capitolo_imp_periodo.anno,
		tipo_elemento.elem_tipo_code,
		capitolo_imp_tipo.elem_det_tipo_code,		
		cat_del_capitolo.elem_cat_code  
  
        LOOP
        
          INSERT INTO siac_rep_gest_equi_bil_imp
            ( ente_proprietario_id,
              anno,
              titolo,
              cap_entrata_spesa,
              tipo_capitolo,
              codice_importo,
              pdc_fin,
              importo,
              utente,
              macroagg
            )  
          VALUES
            ( p_ente_prop_id,
              rec_capitoli_1.anno_competenza,
              null,
              rec_capitoli_1.tipo_capitolo_cod,
              rec_capitoli_1.tipo_capitolo,
              rec_capitoli_1.codice_importo,
              null,
              rec_capitoli_1.importo,
              user_table,
              null 
            );          
        
        END LOOP;
  
raise notice 'ora: % ',clock_timestamp()::varchar;  
RTN_MESSAGGIO:='acquisizione importi per capitoli FPV''.';  
raise notice 'acquisizione importi per capitoli FPV';
raise notice 'ora: % ',clock_timestamp()::varchar;  
  
  FOR rec_capitoli_2 IN  
  with capitoli as (
          select
              capitolo_imp_periodo.anno            anno_competenza,
              tipo_elemento.elem_tipo_code         tipo_capitolo_cod,
              capitolo_imp_tipo.elem_det_tipo_code tipo_capitolo,			
              cat_del_capitolo.elem_cat_code	     codice_importo,			
              sum(coalesce(capitolo_importi.elem_det_importo,0)) importo,            
              d_class_tipo.classif_tipo_code,
              t_class.classif_id/*,
              capitolo_importi.elem_det_importo*/
          from 
              siac_t_bil_elem_det capitolo_importi,
              siac_d_bil_elem_det_tipo capitolo_imp_tipo,
              siac_t_periodo capitolo_imp_periodo,
              siac_t_bil_elem capitolo,
              siac_d_bil_elem_tipo tipo_elemento,
              siac_t_bil bilancio,
              siac_t_periodo anno_eserc, 
              siac_d_bil_elem_stato stato_capitolo, 
              siac_r_bil_elem_stato r_capitolo_stato,
              siac_d_bil_elem_categoria cat_del_capitolo, 
              siac_r_bil_elem_categoria r_cat_capitolo,
              siac_r_bil_elem_class     r_bil_elem_class,
              siac_t_class              t_class,
              siac_d_class_tipo         d_class_tipo 
          where bilancio.periodo_id					=	anno_eserc.periodo_id
              and	capitolo.bil_id						=	bilancio.bil_id 			 
              and	capitolo.elem_id					=	capitolo_importi.elem_id 
              and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 	
              and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
              and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 
              and	capitolo.elem_id					=	r_capitolo_stato.elem_id
              and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
              and	capitolo.elem_id					=	r_cat_capitolo.elem_id
              and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
              and r_bil_elem_class.elem_id            =   capitolo.elem_id
              and r_bil_elem_class.classif_id         =   t_class.classif_id
              and t_class.classif_tipo_id             =   d_class_tipo.classif_tipo_id          
              and 	capitolo_importi.ente_proprietario_id = p_ente_prop_id
              and	anno_eserc.anno						= 	p_anno														          					
              and	tipo_elemento.elem_tipo_code 		= 'CAP-UG'          
              and	capitolo_imp_tipo.elem_det_tipo_code	= 'STA'          			  
              and	capitolo_imp_periodo.anno           =   p_anno          
              and	stato_capitolo.elem_stato_code		=	'VA'          
              and	cat_del_capitolo.elem_cat_code		=   'FPV'	          
              and d_class_tipo.classif_tipo_code      = 'MACROAGGREGATO'
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
              --siac-tasks-Issues#75 20/04/2023.
              --Mancava il test su data_cancellazione su siac_r_bil_elem_class
              and 	r_bil_elem_class.data_cancellazione 	is null
              and	capitolo_importi.validita_fine 	is null
              and	capitolo_imp_tipo.validita_fine 	is null
              and	capitolo_imp_periodo.validita_fine is null
              and	capitolo.validita_fine 			is null
              and	tipo_elemento.validita_fine 		is null
              and	bilancio.validita_fine 			is null
              and	anno_eserc.validita_fine 			is null
              and	stato_capitolo.validita_fine 		is null
              and	r_capitolo_stato.validita_fine 	is null
              and	cat_del_capitolo.validita_fine 	is null
              and	r_cat_capitolo.validita_fine 		is null 
              --siac-tasks-Issues#75 20/04/2023.
              --Mancava il test su validita_fine su siac_r_bil_elem_class              
              and 	r_bil_elem_class.validita_fine 	is null         
          group by capitolo_imp_periodo.anno,
              tipo_elemento.elem_tipo_code,
              capitolo_imp_tipo.elem_det_tipo_code,		
              cat_del_capitolo.elem_cat_code,
              d_class_tipo.classif_tipo_code,
              t_class.classif_id
  ),
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
  where a.ente_proprietario_id= p_ente_prop_id
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = '00002'
  --and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
  and b.classif_id_padre is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null  
  and a.validita_fine is null
  and b.validita_fine is null
  and c.validita_fine is null
  and d.validita_fine is null  
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
  and d.classif_fam_code = '00002'
  --and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
  and b.classif_id_padre is not null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and a.validita_fine is null
  and b.validita_fine is null
  and c.validita_fine is null
  and d.validita_fine is null  
  and e.classif_tipo_id=a.classif_tipo_id
  )
  select  
  titusc.titusc_code,
  capitoli.anno_competenza,
  capitoli.tipo_capitolo_cod,
  capitoli.tipo_capitolo,
  capitoli.codice_importo,
  capitoli.importo,
  macroag.macroag_code
  from titusc, macroag,  	capitoli     	
  where titusc.titusc_id=macroag.titusc_id 
  and   capitoli.classif_id = macroag.macroag_id
  and   titusc.titusc_code in ('1','2','3')  
  
        LOOP
        
          INSERT INTO siac_rep_gest_equi_bil_imp
            ( ente_proprietario_id,
              anno,
              titolo,
              cap_entrata_spesa,
              tipo_capitolo,
              codice_importo,
              pdc_fin,
              importo,
              utente,
              macroagg 
            )  
          VALUES
            ( p_ente_prop_id,
              rec_capitoli_2.anno_competenza,
              rec_capitoli_2.titusc_code,
              rec_capitoli_2.tipo_capitolo_cod,
              rec_capitoli_2.tipo_capitolo,
              rec_capitoli_2.codice_importo,
              null,
              rec_capitoli_2.importo,
              user_table,
              rec_capitoli_2.macroag_code
            );          
        
        END LOOP;
  raise notice 'ora: % ',clock_timestamp()::varchar;  
  FOR rec_fin IN
  SELECT a.anno, a.titolo, a.cap_entrata_spesa, a.tipo_capitolo, a.codice_importo,
         a.pdc_fin, a.importo, a.macroagg
  FROM  siac_rep_gest_equi_bil_imp a
  WHERE a.ente_proprietario_id = p_ente_prop_id
  AND   a.anno = p_anno
  AND   a.utente = user_table

  LOOP
  
  	anno := rec_fin.anno;
    titolo := rec_fin.titolo;
    cap_entrata_spesa := rec_fin.cap_entrata_spesa;
    tipo_capitolo := rec_fin.tipo_capitolo;
    codice_importo := rec_fin.codice_importo;
    pdc_fin := rec_fin.pdc_fin;
    importo := rec_fin.importo;
    macroagg := rec_fin.macroagg;
    return next;
    anno := '';
    titolo := '';
    cap_entrata_spesa := '';
    tipo_capitolo := '';
    codice_importo := '';
    pdc_fin :=  '';
    importo := 0;
  
  END LOOP;

  delete from siac_rep_gest_equi_bil_imp where utente=user_table;

  raise notice 'fine OK';
  raise notice 'ora: % ',clock_timestamp()::varchar;  
  
  EXCEPTION
  when no_data_found THEN
  raise notice 'nessun dato trovato per gestione equilibrio bilancio';
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
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR141_equilibri_bilancio_rendiconto" (p_ente_prop_id integer, p_anno varchar)
  OWNER TO siac;