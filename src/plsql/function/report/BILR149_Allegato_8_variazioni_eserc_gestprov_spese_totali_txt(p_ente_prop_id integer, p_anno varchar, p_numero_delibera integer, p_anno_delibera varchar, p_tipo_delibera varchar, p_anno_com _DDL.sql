/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR149_Allegato_8_variazioni_eserc_gestprov_spese_totali_txt" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  stanziato_totale numeric
) AS
$body$
DECLARE

DataSetAtti record;
contaRec integer;

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
v_fam_titolotipologiacategoria varchar:='00003';
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;
bilancio_id integer;
stanz_tot numeric;
cassa_tot numeric;
residui_tot numeric;
importi_var_capitoli numeric;

BEGIN

--annoCapImp:= p_anno; 
annoCapImp:=p_anno_competenza;

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione


stanziato_totale=0;

    
/* Funzione nata per la SIAC-7195 per la gestione dei file in formato testo 
	per Unicredit.
    La funzione estrae i totali complessivi che comprendono i dati delle variazioni
    considerate da i parametri in input. 
*/

/* 02/07/2020 SIAC-7678.
	Funzione non più utilizzata e mantenuta solo su GIT nel caso si dovesse tornare indietro.
 */


select fnc_siac_random_user()
into	user_table;

select a.bil_id 
	into bilancio_id 
from siac_t_bil a,
		siac_t_periodo b
where b.periodo_id=a.periodo_id
	and a.ente_proprietario_id=p_ente_prop_id 
	and b.anno=p_anno
    and a.data_cancellazione IS NULL
    and b.data_cancellazione IS NULL;
    
raise notice '1 - %' , clock_timestamp()::text;

	--dati variabili dei capitoli.
    --il report BILR149 per questo calcolo richima la procedure del BILR119.
select sum(stanziato)+sum(variazione_aumento)-sum(variazione_diminuzione)
	into importi_var_capitoli
from "BILR119_Allegato_7_Allegato_delibera_variazione_variabili_bozza" 
	(p_ente_prop_id,p_anno,p_numero_delibera,p_anno_delibera,p_tipo_delibera,
    p_anno_competenza,p_ele_variazioni) 
where tipologia_capitolo in('DAM')
	and anno_riferimento=p_anno_competenza;

raise notice 'importi_var_capitoli = %', importi_var_capitoli;

INSERT INTO siac_rep_cap_ug_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_imp_tipo.elem_det_tipo_code    TIPO_IMP,
            capitolo_importi.ente_proprietario_id,  
            user_table utente,            
            sum(capitolo_importi.elem_det_importo) importo_cap
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,            
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_t_bil_elem 			capitolo				            
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
        and	stato_capitolo.elem_stato_code		in ('VA', 'PR')								
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')	
        -- 13/02/2017: aggiunto filtro su anno competenza e sugli importi					
        --and capitolo_imp_periodo.anno = p_anno_competenza
        and capitolo_imp_periodo.anno =	p_anno							
        and	capitolo_imp_tipo.elem_det_tipo_code = 'STA'
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
    group by	capitolo_importi.elem_id,
    capitolo_imp_tipo.elem_det_tipo_code,
    capitolo_imp_periodo.anno,
    capitolo_importi.ente_proprietario_id, utente;
     

	--stanziato totale
select sum(COALESCE(importo,0))
into stanziato_totale
from siac_rep_cap_ug_imp
where ente_proprietario=p_ente_prop_id
and tipo_imp='STA'
and periodo_anno= p_anno_competenza
and utente = user_table;

	--allo stanziato aggiungo i dati dei capitoli.
stanziato_totale:=stanziato_totale+importi_var_capitoli;


return next;

delete from siac_rep_cap_ug_imp where utente = user_table;

raise notice 'fine OK';

exception
	when no_data_found THEN
		raise notice 'nessun atto trovato' ;
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