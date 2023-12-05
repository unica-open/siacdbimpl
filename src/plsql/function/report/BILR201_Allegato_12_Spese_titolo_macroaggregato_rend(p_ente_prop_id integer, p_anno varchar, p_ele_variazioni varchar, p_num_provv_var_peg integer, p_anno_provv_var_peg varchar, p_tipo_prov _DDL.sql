/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac."BILR201_Allegato_12_Spese_titolo_macroaggregato_rend" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_num_provv_var_peg integer,
  p_anno_provv_var_peg varchar,
  p_tipo_provv_var_peg varchar,
  p_num_provv_var_bil integer,
  p_anno_provv_var_bil varchar,
  p_tipo_provv_var_bil varchar,
  p_code_sac_direz_peg varchar,
  p_code_sac_sett_peg varchar,
  p_code_sac_direz_bil varchar,
  p_code_sac_sett_bil varchar,
  p_pluriennale varchar = 'S'::character varying
)
RETURNS TABLE (
  bil_anno varchar,
  titusc_tipo_code varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_code varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  macroag_id numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  spesa_ricorrente_anno numeric,
  spesa_ricorrente_anno1 numeric,
  spesa_ricorrente_anno2 numeric,
  display_error varchar
) AS
$body$
DECLARE

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
elemTipoCode varchar;
cap_std	varchar;
cap_fpv	varchar;
cap_fsc	varchar;
bilancio_id integer;

intApp integer;
strApp varchar;
x_array varchar [];

contaParVarPeg integer;
contaParVarBil integer;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

BEGIN

display_error :='';
contaParVarPeg:=0;
contaParVarBil:=0;

annoCapImp  := p_anno; 
annoCapImp1 := ((p_anno::integer)+1)::varchar;   
annoCapImp2 := ((p_anno::integer)+2)::varchar; 

TipoImpComp  := 'STA';  -- competenza
elemTipoCode := 'CAP-UG'; -- tipo capitolo gestione
cap_std:='STD';
cap_fpv:='FPV';
cap_fsc:='FSC';

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  -- ALESSANDRO - SIAC-5208 - non posso castare l'intera stringa a integer: spezzo e parsifico pezzo a pezzo
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    --strApp=REPLACE(p_ele_variazioni,',','');
    --raise notice 'VAR: %', strApp;
    intApp = strApp::INTEGER;
  END LOOP;
  -- ALESSANDRO - SIAC-5208 - FINE
END IF;

/*  22/09/2017: parametri nuovi, controllo che se e' passato uno tra numero/anno/tipo
    provvedimento di variazione di PEG o di BILANCIO, siano passati anche
    gli altri 2. */
IF p_num_provv_var_peg IS NOT  NULL THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF p_anno_provv_var_peg IS NOT  NULL AND p_anno_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF p_tipo_provv_var_peg IS NOT  NULL AND p_tipo_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF contaParVarPeg not in (0,3) THEN
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di PEG''';
    return next;
    return;        
END IF;

IF p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF contaParVarBil not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di Bilancio''';
    return next;
    return;        
END IF;

select a.bil_id 
into  bilancio_id 
from  siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id
and   b.periodo_id = a.periodo_id
and   b.anno = p_anno;

RETURN query
SELECT
--zz.*
zz.bil_anno   					bil_anno,
zz.titusc_tipo_code             titusc_tipo_code,
zz.titusc_tipo_desc				titusc_tipo_desc,
zz.titusc_code					titusc_code,
zz.titusc_desc					titusc_desc,
zz.macroag_tipo_code            macroag_tipo_code, 
zz.macroag_tipo_desc			macroag_tipo_desc,
zz.macroag_code					macroag_code,
zz.macroag_desc					macroag_desc,
zz.macroag_id                   macroag_id,
COALESCE(sum(zz.imp_stanziamento1),0)		stanziamento_prev_anno,
COALESCE(sum(zz.imp_stanziamento2),0)	    stanziamento_prev_anno1,
COALESCE(sum(zz.imp_stanziamento3),0)	    stanziamento_prev_anno2,
COALESCE (sum(zz.imp_spese_non_ricorrenti1),0)	spesa_ricorrente_anno,
COALESCE (sum(zz.imp_spese_non_ricorrenti2),0)	spesa_ricorrente_anno1,
COALESCE (sum(zz.imp_spese_non_ricorrenti3),0)	spesa_ricorrente_anno2,
zz.display_error
FROM (
with strut_bilancio as (
select  a.titusc_tipo_desc, 
        a.titusc_code, 
        a.titusc_desc, 
        a.macroag_tipo_desc,
        a.macroag_code,
        a.macroag_desc,
        a.macroag_id
from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, p_anno, null) a
group by
a.titusc_tipo_desc, 
a.titusc_code, 
a.titusc_desc, 
a.macroag_tipo_desc,
a.macroag_code,
a.macroag_desc,
a.macroag_id
),
capitoli as (
select 	macroaggr.classif_id as macroaggr_id,
        -- anno_eserc.anno anno_bilancio,
        capitolo.elem_id
from    siac_d_class_tipo macroaggr_tipo,
        siac_t_class macroaggr,
        siac_t_bil_elem capitolo,
        siac_d_bil_elem_tipo tipo_elemento,
        siac_r_bil_elem_class r_capitolo_macroaggr, 
        siac_d_bil_elem_stato stato_capitolo, 
        siac_r_bil_elem_stato r_capitolo_stato,
        siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
and macroaggr.classif_tipo_id          = macroaggr_tipo.classif_tipo_id 				
and macroaggr.classif_id               = r_capitolo_macroaggr.classif_id					
and capitolo.ente_proprietario_id      = p_ente_prop_id								
and capitolo.bil_id                    = bilancio_id										
and capitolo.elem_tipo_id              = tipo_elemento.elem_tipo_id 						
and tipo_elemento.elem_tipo_code       = elemTipoCode					     	 
and capitolo.elem_id                   = r_capitolo_macroaggr.elem_id						
and capitolo.elem_id				   =	r_capitolo_stato.elem_id			
and r_capitolo_stato.elem_stato_id	   =	stato_capitolo.elem_stato_id		
and stato_capitolo.elem_stato_code	   =	'VA'								
and capitolo.elem_id				   =	r_cat_capitolo.elem_id				
and r_cat_capitolo.elem_cat_id		   =	cat_del_capitolo.elem_cat_id		
-- 05/08/2016: aggiunto FPVC
and cat_del_capitolo.elem_cat_code	in (cap_std, cap_fpv, cap_fsc,'FPVC')					
-- cat_del_capitolo.elem_cat_code	=	'STD'														
and macroaggr_tipo.data_cancellazione 			is null						
and macroaggr.data_cancellazione 				is null						
and capitolo.data_cancellazione 				is null						
and tipo_elemento.data_cancellazione 			is null						
and r_capitolo_macroaggr.data_cancellazione 	is null						 
and stato_capitolo.data_cancellazione 			is null						 
and r_capitolo_stato.data_cancellazione 		is null						
and cat_del_capitolo.data_cancellazione 		is null						
and r_cat_capitolo.data_cancellazione 			is null
),
stanziamento as (
select  capitolo_importi.elem_id,
        capitolo_imp_periodo.anno 				anno_stanziamento_parziale,
        capitolo_imp_tipo.elem_det_tipo_code 	tipo_elem_det,
        sum(capitolo_importi.elem_det_importo)  imp_stanziamento_parziale     
from    siac_t_bil_elem_det 			capitolo_importi,
        siac_d_bil_elem_det_tipo 		capitolo_imp_tipo,
        siac_t_periodo 					capitolo_imp_periodo,
        siac_t_bil_elem 				capitolo,
        siac_d_bil_elem_tipo 			tipo_elemento,
        siac_d_bil_elem_stato 			stato_capitolo, 
        siac_r_bil_elem_stato 			r_capitolo_stato,
        siac_d_bil_elem_categoria 		cat_del_capitolo, 
        siac_r_bil_elem_categoria 		r_cat_capitolo
where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  						
and	capitolo.bil_id						= bilancio_id			 
and	capitolo.elem_id					= capitolo_importi.elem_id 
and	capitolo.elem_tipo_id				= tipo_elemento.elem_tipo_id 						
and	tipo_elemento.elem_tipo_code 		= elemTipoCode
and	capitolo_importi.elem_det_tipo_id	= capitolo_imp_tipo.elem_det_tipo_id 		
and	capitolo_imp_periodo.periodo_id		= capitolo_importi.periodo_id 			  
and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)       
and	capitolo.elem_id					=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code		=	'VA'
and	capitolo.elem_id					=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
-- 05/08/2016: aggiunto FPVC
and cat_del_capitolo.elem_cat_code	in (cap_std, cap_fpv, cap_fsc,'FPVC')
-- and	cat_del_capitolo.elem_cat_code		=	'STD'
and	capitolo_importi.data_cancellazione 	is null
and	capitolo_imp_tipo.data_cancellazione 	is null
and	capitolo_imp_periodo.data_cancellazione is null
and	capitolo.data_cancellazione 			is null
and	tipo_elemento.data_cancellazione 		is null
and	stato_capitolo.data_cancellazione 		is null
and	r_capitolo_stato.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione 	is null
and	r_cat_capitolo.data_cancellazione 		is null
group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno
),
spese_non_ricorrenti as (
select 		capitolo_importi.elem_id,
            capitolo_imp_periodo.anno 				anno_spese_non_ricorrenti,
            capitolo_imp_tipo.elem_det_tipo_code 	tipo_elem_det,
            sum(capitolo_importi.elem_det_importo)  imp_spese_non_ricorrenti         
from siac_t_bil_elem_det 		capitolo_importi,
     siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
     siac_t_periodo 			capitolo_imp_periodo,
     siac_t_bil_elem 			capitolo,
     siac_d_bil_elem_tipo 		tipo_elemento,
     siac_d_bil_elem_stato		stato_capitolo, 
     siac_r_bil_elem_stato 		r_capitolo_stato,
     siac_d_bil_elem_categoria 	cat_del_capitolo, 
     siac_r_bil_elem_categoria 	r_cat_capitolo
where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  				
and	capitolo.bil_id						= bilancio_id		 
and	capitolo.elem_id					= capitolo_importi.elem_id 
and	capitolo.elem_tipo_id				= tipo_elemento.elem_tipo_id 						
and	tipo_elemento.elem_tipo_code 		= elemTipoCode
and	capitolo_importi.elem_det_tipo_id	= capitolo_imp_tipo.elem_det_tipo_id 		
and	capitolo_imp_periodo.periodo_id		= capitolo_importi.periodo_id 			  
and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
and	capitolo.elem_id					= r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id		= stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code		= 'VA'
and	capitolo.elem_id					= r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id			= cat_del_capitolo.elem_cat_id		
and	cat_del_capitolo.elem_cat_code		in (cap_std, cap_fpv, cap_fsc,'FPVC')
and capitolo_imp_tipo.elem_det_tipo_code	= TipoImpComp
and capitolo_importi.elem_id    not in
(select r_class.elem_id   
 from  	siac_r_bil_elem_class	r_class,
        siac_t_class 			b,
        siac_d_class_tipo 		c
 where 	b.classif_id 		= 	r_class.classif_id
 and 	b.classif_tipo_id 	= 	c.classif_tipo_id
 and 	c.classif_tipo_code  = 'RICORRENTE_SPESA'
 and	b.classif_desc	=	'Ricorrente'
 and	r_class.data_cancellazione				is null
 and	b.data_cancellazione					is null
 and c.data_cancellazione					is null)  
and	capitolo_importi.data_cancellazione 	is null
and	capitolo_imp_tipo.data_cancellazione 	is null
and	capitolo_imp_periodo.data_cancellazione is null
and	capitolo.data_cancellazione 			is null
and	tipo_elemento.data_cancellazione 		is null
and	stato_capitolo.data_cancellazione 		is null
and	r_capitolo_stato.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione 	is null
and	r_cat_capitolo.data_cancellazione 		is null
group by  capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno
),
variazioni as (
select *
from "fnc_variazioni_bozza" (
  p_ente_prop_id,
  p_anno,
  p_ele_variazioni,
  p_num_provv_var_peg,
  p_anno_provv_var_peg,
  p_tipo_provv_var_peg,
  p_num_provv_var_bil,
  p_anno_provv_var_bil,
  p_tipo_provv_var_bil,
  p_code_sac_direz_peg,
  p_code_sac_sett_peg,
  p_code_sac_direz_bil,
  p_code_sac_sett_bil,
  contaParVarPeg,
  contaParVarBil,
  elemTipoCode
)
where tipo_capitolo in (cap_std, cap_fpv, cap_fsc, 'FPVC')
)
select
p_anno::varchar as bil_anno,
--strut_bilancio.titusc_id::integer titusc_id,
null::varchar as titusc_tipo_code, 
strut_bilancio.titusc_tipo_desc::varchar as titusc_tipo_desc, 
strut_bilancio.titusc_code::varchar as titusc_code, 
strut_bilancio.titusc_desc::varchar as titusc_desc, 
--strut_bilancio.macroag_id::integer macroag_id,
null::varchar as macroag_tipo_code,
strut_bilancio.macroag_tipo_desc::varchar as macroag_tipo_desc,
strut_bilancio.macroag_code::varchar as macroag_code,
strut_bilancio.macroag_desc::varchar as macroag_desc,
strut_bilancio.macroag_id::numeric as macroag_id,
--capitoli.elem_id::integer as elem_id,
--COALESCE(stanziamento1.imp_stanziamento_parziale,0)::numeric as imp_stanziamento_parziale1,
--COALESCE(stanziamento2.imp_stanziamento_parziale,0)::numeric as imp_stanziamento_parziale2,
--COALESCE(stanziamento3.imp_stanziamento_parziale,0)::numeric as imp_stanziamento_parziale3,
--COALESCE(variazioni1.imp_variazioni,0)::numeric as imp_variazioni1,
--COALESCE(variazioni2.imp_variazioni,0)::numeric as imp_variazioni2,
--COALESCE(variazioni3.imp_variazioni,0)::numeric as imp_variazioni3
COALESCE(stanziamento1.imp_stanziamento_parziale,0)::numeric + COALESCE(variazioni1.imp_variazioni,0)::numeric as imp_stanziamento1,
CASE
	WHEN p_pluriennale = 'N' THEN
         0
    ELSE	 
         COALESCE(stanziamento2.imp_stanziamento_parziale,0)::numeric + COALESCE(variazioni2.imp_variazioni,0)::numeric
END imp_stanziamento2,
CASE
	WHEN p_pluriennale = 'N' THEN
         0
    ELSE
         COALESCE(stanziamento3.imp_stanziamento_parziale,0)::numeric + COALESCE(variazioni3.imp_variazioni,0)::numeric
END imp_stanziamento3,
COALESCE(spese1.imp_spese_non_ricorrenti,0)::numeric + COALESCE(variazioni1.imp_variazioni,0)::numeric as imp_spese_non_ricorrenti1,
CASE
	WHEN p_pluriennale = 'N' THEN
         0
    ELSE
         COALESCE(spese2.imp_spese_non_ricorrenti,0)::numeric + COALESCE(variazioni2.imp_variazioni,0)::numeric
END imp_spese_non_ricorrenti2,
CASE
	WHEN p_pluriennale = 'N' THEN
         0
    ELSE
         COALESCE(spese3.imp_spese_non_ricorrenti,0)::numeric + COALESCE(variazioni3.imp_variazioni,0)::numeric
END imp_spese_non_ricorrenti3,
display_error::varchar
from  strut_bilancio
full  join capitoli on strut_bilancio.macroag_id = capitoli.macroaggr_id
left  join stanziamento stanziamento1 on stanziamento1.elem_id = capitoli.elem_id 
                                      and stanziamento1.anno_stanziamento_parziale = annoCapImp
                                      and stanziamento1.tipo_elem_det = tipoImpComp  
left  join stanziamento stanziamento2 on stanziamento2.elem_id = capitoli.elem_id 
                                      and stanziamento2.anno_stanziamento_parziale = annoCapImp1
                                      and stanziamento2.tipo_elem_det = tipoImpComp  
left  join stanziamento stanziamento3 on stanziamento3.elem_id = capitoli.elem_id 
                                      and stanziamento3.anno_stanziamento_parziale = annoCapImp2
                                      and stanziamento3.tipo_elem_det = tipoImpComp 
left join variazioni variazioni1 on variazioni1.elem_id = capitoli.elem_id 
                                 and variazioni1.anno_variazioni = annoCapImp
                                 and variazioni1.tipo_elem_det = tipoImpComp
left join variazioni variazioni2 on variazioni2.elem_id = capitoli.elem_id 
                                 and variazioni2.anno_variazioni = annoCapImp1
                                 and variazioni2.tipo_elem_det = tipoImpComp
left join variazioni variazioni3 on variazioni3.elem_id = capitoli.elem_id 
                                 and variazioni3.anno_variazioni = annoCapImp2
                                 and variazioni3.tipo_elem_det = tipoImpComp      
left join spese_non_ricorrenti spese1 on spese1.elem_id = capitoli.elem_id 
                                 and spese1.anno_spese_non_ricorrenti = annoCapImp
                                 and spese1.tipo_elem_det = tipoImpComp  
left join spese_non_ricorrenti spese2 on spese2.elem_id = capitoli.elem_id 
                                 and spese2.anno_spese_non_ricorrenti = annoCapImp1
                                 and spese2.tipo_elem_det = tipoImpComp 
left join spese_non_ricorrenti spese3 on spese3.elem_id = capitoli.elem_id 
                                 and spese3.anno_spese_non_ricorrenti = annoCapImp2
                                 and spese3.tipo_elem_det = tipoImpComp  
) as zz
group by 
zz.bil_anno,
zz.titusc_tipo_desc,				
zz.titusc_code,				
zz.titusc_desc,					
zz.macroag_tipo_desc,
zz.macroag_id,			
zz.macroag_code,				
zz.macroag_desc,		
zz.titusc_tipo_code,
zz.macroag_tipo_code,
zz.display_error;
  
raise notice 'fine OK';

EXCEPTION    
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce record solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;        
	when others  THEN
        RTN_MESSAGGIO:='';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;