/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR024_Allegato_7_Allegato_delibera_variaz_totali_spese_txt" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  stanziato_totale numeric,
  cassa_totale numeric,
  residuo_totale numeric
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
cassa_totale=0;
residuo_totale=0;

    
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
select sum(stanziato)-sum(variazione_aumento)+sum(variazione_diminuzione)
	into importi_var_capitoli
from "BILR024_Allegato_7_Allegato_delibera_variazione_variabili" 
	(p_ente_prop_id,p_anno,p_numero_delibera,p_anno_delibera,p_tipo_delibera,
    p_anno_competenza,p_ele_variazioni,' ') 
where tipologia_capitolo in('DAM');

 /* carico sulla tabella di appoggio siac_rep_cap_ug_imp gli importi dei capitoli
    	decrementando gli importi delle varizioni successive a quelle 
        specificate in input. */
strQuery:= 'with cap as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,           
            capitolo_imp_tipo.elem_det_tipo_id,
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
     where 	capitolo_importi.ente_proprietario_id 	='||p_ente_prop_id||' 
        and	anno_eserc.anno						= 	'''||p_anno||'''												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno  =  '''||p_anno_competenza||'''
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code		=	''VA''								
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and cat_del_capitolo.elem_cat_code	in (''STD'',''FPV'',''FSC'',''FPVC'')
        and capitolo_imp_tipo.elem_det_tipo_code in (''STA'',''SCA'',''STR'')						
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
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id,  cat_del_capitolo.elem_cat_code,
    	capitolo_imp_tipo.elem_det_tipo_id),
        -- SIAC-7200 nella query che estrae le variazioni successive, aggiunto
        --  il test sull''anno (periodo_id) che lega la variazione corrente
        --  (siac_t_variazione avar) a quelle successive (siac_t_variazione avarsucc).
 importi_variaz as(    with varcurr as (              
      select dvar.elem_id elem_id_var, bvar.validita_inizio, dvar.periodo_id,
          dvar.elem_det_tipo_id
      from 
      siac_t_variazione avar, siac_r_variazione_stato bvar,
      siac_d_variazione_stato cvar, siac_t_bil_elem_det_var dvar, siac_t_periodo periodo_importo_variazione
      where avar.variazione_id=bvar.variazione_id
      and bvar.variazione_stato_tipo_id=cvar.variazione_stato_tipo_id
      and dvar.variazione_stato_id=bvar.variazione_stato_id         
      and cvar.variazione_stato_tipo_code=''D''                            
      and bvar.data_cancellazione is null
      and bvar.variazione_stato_id in (';
if p_numero_delibera IS NOT NULL THEN  --specifico un atto.
strQuery:=strQuery||'                      
            select max(var_stato.variazione_stato_id)
            from siac_t_atto_amm             atto,
              siac_d_atto_amm_tipo        tipo_atto,
              siac_r_atto_amm_stato         r_atto_stato,
              siac_d_atto_amm_stato         stato_atto,
              siac_r_variazione_stato     var_stato
            where
              (var_stato.attoamm_id = atto.attoamm_id 
                 or var_stato.attoamm_id_varbil = atto.attoamm_id )                  
              and     r_atto_stato.attoamm_id   =   atto.attoamm_id 
              and     r_atto_stato.attoamm_stato_id     =   stato_atto.attoamm_stato_id
              and     atto.ente_proprietario_id   =   '||p_ente_prop_id||'
              and     atto.attoamm_numero=  '||p_numero_delibera||'
              and     atto.attoamm_anno  =  '''||p_anno_delibera||'''                 
              and     tipo_atto.attoamm_tipo_code  = '''||p_tipo_delibera||'''
              and     stato_atto.attoamm_stato_code   =   ''DEFINITIVO'') ';
else        -- specificato l'elenco delle variazione.          
      	strQuery:=strQuery||'     
                select max(var_stato.variazione_stato_id)
                from siac_t_variazione t_var,
                  siac_r_variazione_stato     var_stato
                where
                  t_var.variazione_id = var_stato.variazione_id
                  and t_var.ente_proprietario_id = '||p_ente_prop_id||'
                  and t_var.variazione_num in('||p_ele_variazioni||')
                  and t_var.data_cancellazione IS NULL
                  and var_stato.data_cancellazione IS NULL )
                  and periodo_importo_variazione.periodo_id = dvar.periodo_id                     	--  SIAC-7311
                  and periodo_importo_variazione.anno =  '''||p_anno_competenza||'''';              -- 	SIAC-7311  
end if;                
		
strQuery:=strQuery||'),
      varsuccess as (select dvarsucc.elem_id elem_id_var, tipoimp.elem_det_tipo_id,
          dvarsucc.periodo_id, bvarsucc.validita_inizio,
          COALESCE(dvarsucc.elem_det_importo,0) importo_var
          from siac_t_variazione avarsucc, siac_r_variazione_stato bvarsucc,              
          siac_d_variazione_stato cvarsucc,
          siac_t_bil_elem_det_var dvarsucc,
          siac_d_bil_elem_det_tipo tipoimp,
          siac_t_periodo periodo_importo_variazione
          where avarsucc.variazione_id= bvarsucc.variazione_id
          and bvarsucc.variazione_stato_tipo_id=cvarsucc.variazione_stato_tipo_id
          and dvarsucc.variazione_stato_id = bvarsucc.variazione_stato_id
          and tipoimp.elem_det_tipo_id = dvarsucc.elem_det_tipo_id
          and dvarsucc.ente_proprietario_id= '||p_ente_prop_id||'                            
          and cvarsucc.variazione_stato_tipo_code=''D''                                          
          and periodo_importo_variazione.periodo_id = dvarsucc.periodo_id                             --  SIAC-7311
          and periodo_importo_variazione.anno =   '''||p_anno_competenza||'''                         --  SIAC-7311
                    and bvarsucc.data_cancellazione is null
          and dvarsucc.data_cancellazione IS NULL)
      select  varsuccess.elem_id_var, varsuccess.elem_det_tipo_id,
              sum(varsuccess.importo_var) totale_var_succ
      from varcurr
            JOIN varsuccess
              on (varcurr.elem_det_tipo_id = varsuccess.elem_det_tipo_id
                    and varcurr.periodo_id = varsuccess.periodo_id
                    and varsuccess.validita_inizio > varcurr.validita_inizio
                    and varcurr.elem_id_var = varsuccess.elem_id_var)                                --  SIAC-7311
      group by varsuccess.elem_id_var, varsuccess.elem_det_tipo_id  )    
                    INSERT INTO siac_rep_cap_ug_imp
                    select 	cap.elem_id, 
                              cap.BIL_ELE_IMP_ANNO, 
                              cap.TIPO_IMP,
                              cap.ente_proprietario_id, 
                              '''||user_table||''' utente,               
                              (cap.importo_cap  - COALESCE(importi_variaz.totale_var_succ,0)) diff
                    from cap LEFT  JOIN importi_variaz 
                    ON (cap.elem_id = importi_variaz.elem_id_var
                      and cap.elem_det_tipo_id= importi_variaz.elem_det_tipo_id);';
raise notice 'Query1 = %', strQuery;                

raise notice 'Inizio query importi capitoli - %' , clock_timestamp()::text;
execute  strQuery;


	--stanziato totale
select sum(importo)
into stanziato_totale
from siac_rep_cap_ug_imp
where ente_proprietario=p_ente_prop_id
and tipo_imp= 'STA'
and periodo_anno=p_anno_competenza
and utente = user_table;

	--allo stanziato aggiungo i dati dei capitoli.
stanziato_totale:=stanziato_totale+importi_var_capitoli;

	--cassa
select sum(importo)
into cassa_totale
from siac_rep_cap_ug_imp
where ente_proprietario=p_ente_prop_id
and tipo_imp= 'SCA'
and periodo_anno=p_anno_competenza
and utente = user_table;

	--residuo
select sum(importo)
into residuo_totale
from siac_rep_cap_ug_imp
where ente_proprietario=p_ente_prop_id
and tipo_imp= 'STR'
and periodo_anno=p_anno_competenza
and utente = user_table;

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