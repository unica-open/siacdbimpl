/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR173_indic_ana_ent_bp_org_er" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  code_titolo varchar,
  desc_titolo varchar,
  code_tipologia varchar,
  desc_tipologia varchar,
  cap_id integer,
  prev_stanz_anno1 numeric,
  prev_stanz_anno2 numeric,
  prev_stanz_anno3 numeric,
  prev_cassa_anno1 numeric,
  prev_residui_anno1 numeric
) AS
$body$
DECLARE
  	DEF_NULL	constant varchar:=''; 
	RTN_MESSAGGIO varchar(1000):=DEF_NULL;
    bilId INTEGER;
    annoCap1 varchar;
    annoCap2 varchar;
    annoCap3 varchar;
    annoIniRend varchar;
    tipoCapitolo varchar;
    
    
BEGIN
 
/*
	Funzione che estrae i dati dei capitoli di entrata/previsione suddivisi per Titolo 
    e Tipologia.
    Gli importi sono restituiti nei 3 anni di previsione.
    La funzione e' utilizzata dai report:
    	- BILR173 - Indicatori analitici di entrata per Organismi ed enti strumentali delle Regioni e delle Province aut.
        - BILR176 - Indicatori analitici di entrata per Regioni
    	- BILR179 - Indicatori analitici di entrata per Enti Locali.

*/

--annoIniRend:= (p_anno::integer + 1)::varchar;
annoIniRend:= p_anno;

annoCap1 := annoIniRend;
annoCap2 := (annoIniRend::INTEGER+1)::varchar;
annoCap3 := (annoIniRend::INTEGER+2)::varchar;
tipoCapitolo:= 'CAP-EP';

SELECT t_bil.bil_id 
	into bilId 
FROM siac_t_bil t_bil,
    siac_t_periodo t_periodo
WHERE t_bil.periodo_id = t_periodo.periodo_id
	AND t_bil.ente_proprietario_id = p_ente_prop_id
    AND t_periodo.anno = annoIniRend
	AND t_bil.data_cancellazione IS NULL
    AND t_periodo.data_cancellazione IS NULL;
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Codice del bilancio non trovato';
    raise exception 'Codice del bilancio non trovato per l''anno %', p_anno;
    return;
END IF;

raise notice 'bilId = %', bilId;

return query 
with strut_bilancio as(
     		select  *--distinct missione_id, missione_code,  missione_desc,
            	--programma_id, programma_code, programma_desc
            from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id,annoIniRend,'')),
capitoli as(
select cl.classif_id categoria_id,
	annoIniRend anno_bilancio,
    capitolo.elem_code, capitolo.elem_desc, capitolo.elem_code2,
        capitolo.elem_desc2, capitolo.elem_code3, capitolo.elem_id,
        cat_del_capitolo.elem_cat_code tipo_capitolo
 from 	siac_r_bil_elem_class rc,
 		siac_t_bil_elem capitolo,
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
and capitolo.bil_id						=	bilancio.bil_id 
and capitolo.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and capitolo.elem_id						=	rc.elem_id 
and	capitolo.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	capitolo.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and capitolo.ente_proprietario_id			=	p_ente_prop_id
and capitolo.bil_id = bilId
and tipo_elemento.elem_tipo_code 	= 	tipoCapitolo --'CAP-EP'
and	stato_capitolo.elem_stato_code	=	'VA'
and ct.classif_tipo_code			=	'CATEGORIA'
and	cat_del_capitolo.elem_cat_code	=	'STD'
and capitolo.data_cancellazione 		is null
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
) ,
importi_cap as  (
    select tab.elem_id, 
            sum(tab.importo_comp_anno1) importo_comp_anno1,
            sum(tab.importo_comp_anno2) importo_comp_anno2,
            sum(tab.importo_comp_anno3) importo_comp_anno3,
            sum(tab.importo_cassa_anno1) importo_cassa_anno1,
            sum(tab.importo_residui_anno1) importo_residui_anno1            
from (select 	capitolo_importi.elem_id,
                capitolo_imp_periodo.anno 			BIL_ELE_IMP_ANNO,
                capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
                case when capitolo_imp_periodo.anno =annoCap1 and capitolo_imp_tipo.elem_det_tipo_code = 'STA'
                	then sum(capitolo_importi.elem_det_importo) end importo_comp_anno1,
                case when capitolo_imp_periodo.anno =annoCap2 and capitolo_imp_tipo.elem_det_tipo_code = 'STA'
                	then sum(capitolo_importi.elem_det_importo) end importo_comp_anno2,   
                case when capitolo_imp_periodo.anno =annoCap3 and capitolo_imp_tipo.elem_det_tipo_code = 'STA'
                	then sum(capitolo_importi.elem_det_importo) end importo_comp_anno3,
                case when capitolo_imp_periodo.anno =annoCap1 and capitolo_imp_tipo.elem_det_tipo_code = 'SCA' --cassa
                	then sum(capitolo_importi.elem_det_importo) end importo_cassa_anno1,
                case when capitolo_imp_periodo.anno =annoCap1 and capitolo_imp_tipo.elem_det_tipo_code = 'STR' --residui
                	then sum(capitolo_importi.elem_det_importo) end importo_residui_anno1 
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
        where bilancio.periodo_id				=anno_eserc.periodo_id 								
            and	capitolo.bil_id					=bilancio.bil_id 			 
            and	capitolo.elem_id	=	capitolo_importi.elem_id 
            and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						            
            and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
            and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 			              
            and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
            and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		            								
            and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
            and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
            and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id
            and	anno_eserc.anno					= annoIniRend
            and	tipo_elemento.elem_tipo_code = tipoCapitolo --'CAP-EP'
            and	stato_capitolo.elem_stato_code	=	'VA'
            and	cat_del_capitolo.elem_cat_code	= 'STD'
            and	capitolo_imp_periodo.anno in (annoCap1,annoCap2,annoCap3)						
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
        capitolo_imp_periodo.anno) tab
        group by elem_id)
SELECT  annoIniRend::varchar bil_anno,
		strut_bilancio.titolo_code::varchar code_titolo, 
		strut_bilancio.titolo_desc::varchar desc_titolo, 
        strut_bilancio.tipologia_code::varchar code_tipologia,
        strut_bilancio.tipologia_desc::varchar desc_tipologia,
        capitoli.elem_id::integer cap_id,
        importi_cap.importo_comp_anno1::numeric prev_stanz_anno1,          
        importi_cap.importo_comp_anno2::numeric prev_stanz_anno2,   
        importi_cap.importo_comp_anno3::numeric prev_stanz_anno3,
        importi_cap.importo_cassa_anno1::numeric prev_cassa_anno1,
        importi_cap.importo_residui_anno1::numeric prev_residui_anno1
FROM strut_bilancio
	LEFT JOIN capitoli on strut_bilancio.categoria_id = capitoli.categoria_id
    LEFT JOIN importi_cap on importi_cap.elem_id = capitoli.elem_id ;
                    
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