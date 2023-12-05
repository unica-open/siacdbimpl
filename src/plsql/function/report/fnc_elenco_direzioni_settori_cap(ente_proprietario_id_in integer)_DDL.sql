/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_elenco_direzioni_settori_cap (
  ente_proprietario_id_in integer
)
RETURNS TABLE (
  cod_direz varchar,
  desc_direz varchar,
  cod_sett varchar,
  desc_sett varchar,
  elem_id integer
) AS
$body$
DECLARE
RTN_MESSAGGIO varchar;
ndc record;
sqlQuery VARCHAR;

BEGIN 


RTN_MESSAGGIO:='Errore generico';


sqlQuery='with 
ele_settori as (
SELECT   t_class2.classif_code cod_direz, t_class2.classif_desc  desc_direz,
 t_class.classif_code cod_sett, t_class.classif_desc  desc_sett, 
	t_class.classif_id
            from siac_r_class_fam_tree r_class_fam_tree,
                siac_t_class			t_class,
                siac_d_class_tipo		d_class_tipo,
                siac_t_class			t_class2               
        where                        
             t_class.classif_id 					= 	r_class_fam_tree.classif_id
            and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
            and t_class2.classif_id = r_class_fam_tree.classif_id_padre            
           --SETTORE
           AND d_class_tipo.classif_tipo_code=''CDC''
           and t_class.ente_proprietario_id='||ente_proprietario_id_in||'            
             AND t_class.data_cancellazione is NULL
             AND d_class_tipo.data_cancellazione is NULL             
             and r_class_fam_tree.data_cancellazione is NULL
                        
            and (t_class.validita_inizio <=now() AND
            	COALESCE(t_class.validita_fine, now()) >=now())  
 ),
 ele_direzioni as (
SELECT t_class.classif_code cod_direz, t_class.classif_desc  desc_direz,
			'''' cod_sett, '''' desc_sett, t_class.classif_id
            from siac_r_class_fam_tree r_class_fam_tree,
                siac_t_class			t_class,
                siac_d_class_tipo		d_class_tipo                           
        where                        
             t_class.classif_id 					= 	r_class_fam_tree.classif_id
            and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id            
            --DIREZIONE
           AND d_class_tipo.classif_tipo_code=''CDR''
           and t_class.ente_proprietario_id='||ente_proprietario_id_in||'          
             AND t_class.data_cancellazione is NULL
             AND d_class_tipo.data_cancellazione is NULL             
             and r_class_fam_tree.data_cancellazione is NULL                     
            and (t_class.validita_inizio <=now() AND
            	COALESCE(t_class.validita_fine, now()) >=now())    
),            
ele_cap as (           
select r_bil_elem_class.elem_id, r_bil_elem_class.classif_id
from siac_r_bil_elem_class 	r_bil_elem_class
where  r_bil_elem_class.ente_proprietario_id='||ente_proprietario_id_in||'       
	and r_bil_elem_class.data_cancellazione is NULL )    
select ele_settori.cod_direz::varchar,
		ele_settori.desc_direz::varchar,
        ele_settori.cod_sett::varchar,
        ele_settori.desc_sett::varchar,
        ele_cap.elem_id::integer
from ele_settori
	INNER JOIN   ele_cap on ele_cap.classif_id = ele_settori.classif_id      
UNION
select ele_direzioni.cod_direz::varchar,
		ele_direzioni.desc_direz::varchar,
        ele_direzioni.cod_sett::varchar,
        ele_direzioni.desc_sett::varchar,
        ele_cap.elem_id::integer
from ele_direzioni
	INNER JOIN   ele_cap on ele_cap.classif_id = ele_direzioni.classif_id            	
ORDER BY cod_direz, cod_sett';

--raise notice 'sqlQuery = %', sqlQuery;

return query execute sqlQuery;

exception
	when no_data_found THEN
		raise notice 'Struttura SAC Direzione/Settore non esistente' ;
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