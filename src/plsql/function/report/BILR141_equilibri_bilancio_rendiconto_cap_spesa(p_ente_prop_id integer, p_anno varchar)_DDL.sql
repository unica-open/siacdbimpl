/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR141_equilibri_bilancio_rendiconto_cap_spesa" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  missione_code varchar,
  missione_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  stanziamento numeric,
  cassa numeric,
  residuo numeric,
  pdc_finanziario varchar,
  categ_capitolo varchar
) AS
$body$
DECLARE


classifBilRec record;


annoCapImp varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_missioneprogramma  varchar;
v_fam_titolomacroaggregato varchar;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;
bilancio_id integer;

BEGIN

--PROCEDURA NUOVA CREATA PER SIAC-7192

--annoCapImp:= p_anno; 
annoCapImp:=p_anno;


raise notice '%', annoCapImp;


TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
v_fam_missioneprogramma :='00001';
v_fam_titolomacroaggregato := '00002';

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione


missione_code='';
missione_desc='';

programma_code='';
programma_desc='';

titusc_code='';
titusc_desc='';

macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;

stanziamento=0;
cassa=0;
residuo=0;


select fnc_siac_random_user()
into	user_table;

select a.bil_id 
	into bilancio_id 
from siac_t_bil a,siac_t_periodo b
where b.periodo_id=a.periodo_id
	and a.ente_proprietario_id=p_ente_prop_id 
	and b.anno=p_anno;
    
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
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
    where 	capitolo.elem_id						=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id					=	tipo_elemento.elem_tipo_id 						
        and capitolo_importi.elem_det_tipo_id		=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		
		and capitolo_importi.ente_proprietario_id 	=	p_ente_prop_id  
        and	capitolo.bil_id							= bilancio_id
        and	tipo_elemento.elem_tipo_code 			= 	elemTipoCode
        and	capitolo_imp_periodo.anno in (annoCapImp)
        and	stato_capitolo.elem_stato_code	=	'VA'												
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
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


return query 
with strutt_bilancio as (select *
        		from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id,p_anno,'')),
		capitoli as (select programma.classif_id programma_id,
						macroaggr.classif_id macroaggregato_id,        				
       					capitolo.elem_code, capitolo.elem_code2,
                        capitolo.elem_desc, capitolo.elem_desc2,
                        capitolo.elem_id, cat_del_capitolo.elem_cat_code
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
                where programma.classif_tipo_id=programma_tipo.classif_tipo_id 				
                    and programma.classif_id=r_capitolo_programma.classif_id	
                    and macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 
                    and macroaggr.classif_id=r_capitolo_macroaggr.classif_id								
                    and capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
                    and capitolo.elem_id=r_capitolo_programma.elem_id		
                    and capitolo.elem_id=r_capitolo_macroaggr.elem_id	
                    and capitolo.elem_id		=	r_capitolo_stato.elem_id	
                    and r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
                    and capitolo.elem_id				=	r_cat_capitolo.elem_id	
                    and r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
                    and capitolo.ente_proprietario_id=p_ente_prop_id   		
                    and capitolo.bil_id= bilancio_id		
                    and programma_tipo.classif_tipo_code='PROGRAMMA'	
                    and macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'	                     							                    	
                    and tipo_elemento.elem_tipo_code = elemTipoCode			                     			                    
                    and stato_capitolo.elem_stato_code	=	'VA'				
                    and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')                    
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
         importi_stanz as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_ug_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipo_imp=TipoImpComp -- ''STA''
                        and a.utente=user_table
                        group by  a.elem_id),
         importi_cassa as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_ug_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipo_imp=TipoImpCassa -- ''SCA''
                        and a.utente=user_table
                        group by  a.elem_id),
         importi_residui as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_ug_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipo_imp=TipoImpRes -- ''STR''
                        and a.utente=user_table
                        group by  a.elem_id),
          pdc_finanziario as
            ( select tc.classif_code, rmc.elem_id
             from   siac_r_bil_elem_class rmc, siac_t_class tc, siac_d_class_tipo dct,
                      siac_t_bil_elem e
             where  rmc.classif_id = tc.classif_id
             and    tc.classif_tipo_id = dct.classif_tipo_id
             and 	dct.ente_proprietario_id = p_ente_prop_id
             and    dct.classif_tipo_code in ( 'PDC_V', 'PDC_IV')
             and    e.elem_id = rmc.elem_id
             and    e.bil_id = bilancio_id
             and    rmc.data_cancellazione  is null
             and    tc.data_cancellazione   is null 
             and    dct.data_cancellazione  is null    
             	--04/03/2022 Nell'ambito delle modifiche legate alla SIAC-8412
                --e' stato riscontrato un errore (era fisso l'anno 2020 nel controllo
                --delle data validita' invece del parametro p_anno).
            -- and    to_timestamp('31/12/'||'2020','dd/mm/yyyy') between rmc.validita_inizio 
             --and COALESCE(rmc.validita_fine,to_timestamp('31/12/'||'2020','dd/mm/yyyy')) )         
			 and    to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between rmc.validita_inizio 
             and COALESCE(rmc.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy')) )                                                                      
		select 
  			strutt_bilancio.missione_code::varchar missione_code,
            strutt_bilancio.missione_desc::varchar missione_desc,           
            strutt_bilancio.programma_code::varchar programma_code,
            strutt_bilancio.programma_desc::varchar programma_desc,
            strutt_bilancio.titusc_code::varchar titusc_code,
            strutt_bilancio.titusc_desc::varchar titusc_desc,
            strutt_bilancio.macroag_code::varchar macroag_code,
            strutt_bilancio.macroag_desc::varchar macroag_desc,
            capitoli.elem_code::varchar bil_ele_code ,
            capitoli.elem_desc::varchar bil_ele_desc,
            capitoli.elem_code2::varchar bil_ele_code2,
            capitoli.elem_desc2::varchar bil_ele_desc2,
            capitoli.elem_id::integer bil_ele_id,
            COALESCE(importi_stanz.importo_cap,0)::numeric stanziamento,
            COALESCE(importi_cassa.importo_cap,0)::numeric cassa,
            COALESCE(importi_residui.importo_cap,0)::numeric residuo,
            COALESCE(pdc_finanziario.classif_code,'') pdc_finanziario,
            capitoli.elem_cat_code categ_capitolo                 
         from strutt_bilancio
         	LEFT JOIN capitoli
            	ON (strutt_bilancio.programma_id = capitoli.programma_id
                	and strutt_bilancio.macroag_id = capitoli.macroaggregato_id)
            LEFT JOIN importi_stanz
            	ON importi_stanz.elem_id = capitoli.elem_id
            LEFT JOIN importi_cassa
            	ON importi_cassa.elem_id = capitoli.elem_id
            LEFT JOIN importi_residui
            	ON importi_residui.elem_id = capitoli.elem_id
            LEFT JOIN pdc_finanziario
            	ON pdc_finanziario.elem_id = capitoli.elem_id
          where capitoli.elem_id IS NOT NULL;
                	
delete from siac_rep_cap_ug_imp where utente=user_table;    

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
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR141_equilibri_bilancio_rendiconto_cap_spesa" (p_ente_prop_id integer, p_anno varchar)
  OWNER TO siac;