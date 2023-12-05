/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
´╗┐-- Function: "BILR165_calcolo_disavanzo_cassa"(integer, character varying)

-- DROP FUNCTION "BILR165_calcolo_disavanzo_cassa"(integer, character varying);

CREATE OR REPLACE FUNCTION "BILR165_calcolo_disavanzo_cassa"(p_ente_prop_id integer, p_anno character varying)
  RETURNS numeric AS
$BODY$
DECLARE
   importo 	numeric :=0;
   importo_acc numeric :=0;
   importo_imp numeric :=0;
   importo_fpv numeric :=0;
   importo_ent numeric :=0;


   annoCapImp varchar;
   annoCapImp_int integer;

   DEF_NULL	constant varchar:=''; 
   RTN_MESSAGGIO varchar(1000):=DEF_NULL;
BEGIN
    annoCapImp:= p_anno; 
    annoCapImp_int:= p_anno::integer; 



select 		
            COALESCE( sum(ordinativo_imp.ord_ts_det_importo),0) into importo_acc
            
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
        and r_ordinativo_movgest.validita_fine is null;



select 	
            COALESCE( sum(ordinativo_imp.ord_ts_det_importo),0) into importo_imp
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
        ----------------------	  da verificare se ├¿ giusto.
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
        and r_liqmovgest.validita_fine is null;
        




select 		
 		    COALESCE( sum(capitolo_importi.elem_det_importo),0)    into importo_ent   
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
        and	tipo_elemento.elem_tipo_code 			= 	'CAP-EG'
        and	capitolo_importi.elem_det_tipo_id		=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno = p_anno
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		
		-- 02/09/2016: aggiunto FPVC
        and	cat_del_capitolo.elem_cat_code	in ('FCI')		
        and capitolo_imp_tipo.elem_det_tipo_code='SCA'						
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
    	and	r_cat_capitolo.data_cancellazione 			is null;




      raise notice 'importo_acc: % ', importo_acc::varchar;
      raise notice 'importo_imp: % ', importo_imp::varchar;
      raise notice 'importo_fpv: % ', importo_fpv::varchar;
      raise notice 'importo_ent: % ', importo_ent::varchar;
      
      raise notice 'totale spese: % ', (importo_imp+importo_fpv)::varchar;
      raise notice 'totale entrate: % ', (importo_acc+importo_ent)::varchar;
      
      raise notice 'Disavanzo calcolato: % ', (-importo_imp-importo_fpv+importo_acc+importo_ent)::varchar;

     if   (importo_acc+importo_ent) > (importo_imp+importo_fpv) then
          importo:=importo_acc + importo_ent - importo_imp - importo_fpv;
	  else 
          importo:=0; 
      end if;
      
      return importo;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return importo;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return importo;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION "BILR165_calcolo_disavanzo_cassa"(integer, character varying)
  OWNER TO siac;
GRANT EXECUTE ON FUNCTION "BILR165_calcolo_disavanzo_cassa"(integer, character varying) TO public;
GRANT EXECUTE ON FUNCTION "BILR165_calcolo_disavanzo_cassa"(integer, character varying) TO siac;
GRANT EXECUTE ON FUNCTION "BILR165_calcolo_disavanzo_cassa"(integer, character varying) TO siac_rw;
