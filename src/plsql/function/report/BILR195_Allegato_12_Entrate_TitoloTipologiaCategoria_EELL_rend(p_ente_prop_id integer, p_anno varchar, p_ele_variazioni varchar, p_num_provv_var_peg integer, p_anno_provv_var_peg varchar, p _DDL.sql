/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac."BILR195_Allegato_12_Entrate_TitoloTipologiaCategoria_EELL_rend" (
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
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  elem_id integer,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  entrata_ricorrente_anno numeric,
  entrata_ricorrente_anno1 numeric,
  entrata_ricorrente_anno2 numeric,
  display_error varchar
) AS
$body$
DECLARE

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
elemTipoCode varchar;
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
elemTipoCode := 'CAP-EG'; -- tipo capitolo gestione

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
zz.*
FROM (
with strut_bilancio as(
select  *
from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno, null)
),
capitoli as(
select cl.classif_id categoria_id,
e.elem_id,
e.elem_code,
e.elem_code2,
e.elem_code3,
e.elem_desc
from  siac_r_bil_elem_class rc,
      siac_t_bil_elem e,
      siac_d_class_tipo ct,
      siac_t_class cl,
      siac_d_bil_elem_tipo tipo_elemento, 
      siac_d_bil_elem_stato stato_capitolo,
      siac_r_bil_elem_stato r_capitolo_stato,
      siac_d_bil_elem_categoria cat_del_capitolo,
      siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_id			=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and e.ente_proprietario_id			=	p_ente_prop_id
and e.bil_id                        =   bilancio_id
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and	stato_capitolo.elem_stato_code	=	'VA'
and ct.classif_tipo_code			=	'CATEGORIA'
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	rc.data_cancellazione				is null
and	ct.data_cancellazione 				is null
and	cl.data_cancellazione 				is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
),
stanziamento as (
select 	capitolo_importi.elem_id,
        capitolo_imp_periodo.anno 				anno_stanziamento_parziale,
        capitolo_imp_tipo.elem_det_tipo_code 	tipo_elem_det,
        sum(capitolo_importi.elem_det_importo)  imp_stanziamento_parziale     
from 	siac_t_bil_elem_det 			capitolo_importi,
        siac_d_bil_elem_det_tipo 		capitolo_imp_tipo,
        siac_t_periodo 					capitolo_imp_periodo,
        siac_t_bil_elem 				capitolo,
        siac_d_bil_elem_tipo 			tipo_elemento,
        siac_d_bil_elem_stato 			stato_capitolo, 
        siac_r_bil_elem_stato 			r_capitolo_stato,
        siac_d_bil_elem_categoria 		cat_del_capitolo, 
        siac_r_bil_elem_categoria 		r_cat_capitolo
where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  			
and capitolo.bil_id						= bilancio_id											
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
and	cat_del_capitolo.elem_cat_code		= 'STD'
and	capitolo_importi.data_cancellazione 	is null
and	capitolo_imp_tipo.data_cancellazione 	is null
and	capitolo_imp_periodo.data_cancellazione is null
and	capitolo.data_cancellazione 			is null
and	tipo_elemento.data_cancellazione 		is null
and	stato_capitolo.data_cancellazione 		is null
and	r_capitolo_stato.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione 	is null
and	r_cat_capitolo.data_cancellazione 		is null
group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id
),
entrate_non_ricorrenti as (
select capitolo_importi.elem_id,
       capitolo_imp_periodo.anno 				anno_entrate_non_ricorrenti,
       capitolo_imp_tipo.elem_det_tipo_code 	tipo_elem_det,
       sum(capitolo_importi.elem_det_importo)   imp_entrate_non_ricorrenti    
from   siac_t_bil_elem_det 			    capitolo_importi,
       siac_d_bil_elem_det_tipo 		capitolo_imp_tipo,
       siac_t_periodo 					capitolo_imp_periodo,
       siac_t_bil_elem 				    capitolo,
       siac_d_bil_elem_tipo 			tipo_elemento,
       siac_t_bil 						bilancio,
       siac_t_periodo 					anno_eserc,
       siac_d_bil_elem_stato			stato_capitolo, 
       siac_r_bil_elem_stato 			r_capitolo_stato,
       siac_d_bil_elem_categoria 		cat_del_capitolo, 
       siac_r_bil_elem_categoria 		r_cat_capitolo
where  capitolo_importi.ente_proprietario_id = p_ente_prop_id  
and	anno_eserc.anno						= p_anno 												
and	bilancio.periodo_id					=anno_eserc.periodo_id 								
and	capitolo.bil_id						=bilancio.bil_id 			 
and	capitolo.elem_id					=capitolo_importi.elem_id 
and	capitolo.elem_tipo_id				=tipo_elemento.elem_tipo_id 						
and	tipo_elemento.elem_tipo_code 		= elemTipoCode
and	capitolo_importi.elem_det_tipo_id	=capitolo_imp_tipo.elem_det_tipo_id 		
and	capitolo_imp_periodo.periodo_id		=capitolo_importi.periodo_id 			  
and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2) 
and	capitolo.elem_id					=r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id		=stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code		='VA'
and	capitolo.elem_id					=r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id			=cat_del_capitolo.elem_cat_id
and	cat_del_capitolo.elem_cat_code		='STD'
and capitolo_importi.elem_id not in
    (select r_class.elem_id   
    from  	siac_r_bil_elem_class	r_class,
            siac_t_class 			b,
            siac_d_class_tipo 		c
    where 	b.classif_id 		 = 	r_class.classif_id
    and 	b.classif_tipo_id 	 = 	c.classif_tipo_id
    and 	c.classif_tipo_code  = 'RICORRENTE_ENTRATA'
    and		b.classif_desc	     = 'Ricorrente'
    and	r_class.data_cancellazione				is null
    and	b.data_cancellazione					is null
    and c.data_cancellazione					is null) 
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
group by  capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id
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
where tipo_capitolo = 'STD'
)
select
p_anno::varchar,
--strut_bilancio.titolo_id::integer titolo_id,
strut_bilancio.titolo_code::varchar as code_titolo, 
strut_bilancio.titolo_desc::varchar as desc_titolo, 
--strut_bilancio.tipologia_id::integer tipologia_id,
strut_bilancio.tipologia_code::varchar as code_tipologia,
strut_bilancio.tipologia_desc::varchar as desc_tipologia,
--strut_bilancio.categoria_id::integer categoria_id,
strut_bilancio.categoria_code::varchar as code_categoria,
strut_bilancio.categoria_desc::varchar as desc_categoria,
capitoli.elem_id::integer as elem_id,
--capitoli.elem_code::varchar elem_code,
--capitoli.elem_code2::varchar elem_code2,
--capitoli.elem_code3::varchar elem_code3,
--capitoli.elem_desc::varchar elem_desc,
--COALESCE(stanziamento1.imp_stanziamento_parziale,0)::numeric as imp_stanziamento_parziale1,
--COALESCE(stanziamento2.imp_stanziamento_parziale,0)::numeric as imp_stanziamento_parziale2,
--COALESCE(stanziamento3.imp_stanziamento_parziale,0)::numeric as imp_stanziamento_parziale3,
--COALESCE(variazioni1.imp_variazioni,0)::numeric as imp_variazioni1,
--COALESCE(variazioni2.imp_variazioni,0)::numeric as imp_variazioni2,
--COALESCE(variazioni3.imp_variazioni,0)::numeric as imp_variazioni3,
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
COALESCE(entrate1.imp_entrate_non_ricorrenti,0)::numeric + COALESCE(variazioni1.imp_variazioni,0)::numeric as imp_entrate_non_ricorrenti1,
CASE
	WHEN p_pluriennale = 'N' THEN
         0
    ELSE
         COALESCE(entrate2.imp_entrate_non_ricorrenti,0)::numeric + COALESCE(variazioni2.imp_variazioni,0)::numeric
END imp_entrate_non_ricorrenti2,
CASE
	WHEN p_pluriennale = 'N' THEN
         0
    ELSE
         COALESCE(entrate3.imp_entrate_non_ricorrenti,0)::numeric + COALESCE(variazioni3.imp_variazioni,0)::numeric
END imp_entrate_non_ricorrenti3,
display_error::varchar
from  strut_bilancio
full  join capitoli on strut_bilancio.categoria_id = capitoli.categoria_id
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
left join entrate_non_ricorrenti entrate1 on entrate1.elem_id = capitoli.elem_id 
                                 and entrate1.anno_entrate_non_ricorrenti = annoCapImp
                                 and entrate1.tipo_elem_det = tipoImpComp  
left join entrate_non_ricorrenti entrate2 on entrate2.elem_id = capitoli.elem_id 
                                 and entrate2.anno_entrate_non_ricorrenti = annoCapImp1
                                 and entrate2.tipo_elem_det = tipoImpComp 
left join entrate_non_ricorrenti entrate3 on entrate3.elem_id = capitoli.elem_id 
                                 and entrate3.anno_entrate_non_ricorrenti = annoCapImp2
                                 and entrate3.tipo_elem_det = tipoImpComp     
) as zz;

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