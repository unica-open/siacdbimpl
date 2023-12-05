/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_bilr151_tab_classif (
  p_ente_prop_id integer
)
RETURNS TABLE (
  elem_id integer,
  settore_code varchar,
  settore_desc varchar,
  direz_code varchar,
  direz_desc varchar,
  pdce_code varchar,
  pdce_desc varchar
) AS
$body$
DECLARE
RTN_MESSAGGIO varchar;
elencoClass record;

/*
	Funzione per estrarre la struttura amministrativa e il PDCE finanziario
    utilizzata dal report BILR151.
*/

BEGIN

elem_id:=null;
settore_code:='';
settore_desc:='';
direz_code:='';
direz_code:='';
pdce_code:='';
pdce_desc:='';


for elencoClass in                             
        with struttura as ( 
 with elenco_settori as (
SELECT distinct r_bil_elem_class.elem_id elem_id_sett,
		t_class.classif_code settore_code, 
		t_class.classif_desc settore_desc		      
            from siac_r_bil_elem_class r_bil_elem_class,
            	siac_r_class_fam_tree r_class_fam_tree,
                siac_t_class			t_class,
                siac_d_class_tipo		d_class_tipo                   
        where 
            t_class.classif_id 					= 	r_bil_elem_class.classif_id
            and t_class.classif_id 					= 	r_class_fam_tree.classif_id
            and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
            and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
           AND d_class_tipo.classif_tipo_desc='Cdc(Settore)'
             AND r_bil_elem_class.data_cancellazione is NULL
             AND t_class.data_cancellazione is NULL
             AND d_class_tipo.data_cancellazione is NULL
             and r_class_fam_tree.data_cancellazione is NULL),
elenco_direzioni as (
		SELECT  r_bil_elem_class.elem_id elem_id_direz,
            t_class.classif_code direz_code, 
            t_class.classif_desc direz_desc 
        from siac_r_bil_elem_class r_bil_elem_class,
            siac_t_class			t_class,
            siac_d_class_tipo		d_class_tipo           
              where 
                   t_class.classif_id 					= 	r_bil_elem_class.classif_id
                  and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
                 and d_class_tipo.classif_tipo_code='CDR'
                 and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                   AND r_bil_elem_class.data_cancellazione is NULL
                   AND t_class.data_cancellazione is NULL
                   AND d_class_tipo.data_cancellazione is NULL    )
select  case 
		when elem_id_sett is not null THEN elem_id_sett
        ELSE elem_id_direz end elem_id_strut,
        COALESCE(elenco_settori.settore_code,'') settore_code, 
        COALESCE(elenco_settori.settore_desc,'') settore_desc, 
		COALESCE(elenco_direzioni.direz_code,'') direz_code, 
        COALESCE(elenco_direzioni.direz_desc,'') direz_desc
from elenco_settori
	full join elenco_direzioni 
    	on elenco_settori.elem_id_sett=elenco_direzioni.elem_id_direz ),        
elenco_pdce_finanz as (        
SELECT  r_bil_elem_class.elem_id elem_id_pdce,
           COALESCE( t_class.classif_code,'') pdce_code, 
            COALESCE(t_class.classif_desc,'') pdce_desc 
        from siac_r_bil_elem_class r_bil_elem_class,
            siac_t_class			t_class,
            siac_d_class_tipo		d_class_tipo           
              where 
                   t_class.classif_id 					= 	r_bil_elem_class.classif_id
                  and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
                 and d_class_tipo.classif_tipo_code like 'PDC_%'			
                 and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                   AND r_bil_elem_class.data_cancellazione is NULL
                   AND t_class.data_cancellazione is NULL
                   AND d_class_tipo.data_cancellazione is NULL    )    
select case 
        when struttura.elem_id_strut is not null THEN struttura.elem_id_strut
            ELSE elenco_pdce_finanz.elem_id_pdce end elem_id,
		COALESCE(struttura.settore_code,'') settore_code, 
        COALESCE(struttura.settore_desc,'') settore_desc,
		COALESCE(struttura.direz_code,'') direz_code, 
        COALESCE(struttura.direz_desc,'') direz_desc,
        COALESCE(elenco_pdce_finanz.pdce_code,'') pdce_code,
        COALESCE(elenco_pdce_finanz.pdce_desc,'') pdce_desc
from struttura
	full join elenco_pdce_finanz
    	on elenco_pdce_finanz.elem_id_pdce= struttura.elem_id_strut                                         
                                	               
           
    loop
     if elem_id is not null and 
            elem_id <> elencoClass.elem_id THEN                                    
            
            return next;
            
            elem_id:=null;
            settore_code:='';
            settore_desc:='';
            direz_code:='';
            direz_desc:='';
            pdce_code:='';
            pdce_desc:='';           
      end if;
      
	  elem_id=elencoClass.elem_id;
      settore_code:=elencoClass.settore_code;
      settore_desc:=elencoClass.settore_desc;
      direz_code:=elencoClass.direz_code;
      direz_desc:=elencoClass.direz_desc;
      pdce_code:=elencoClass.pdce_code;
      pdce_desc:=elencoClass.pdce_desc;                                                             
              
    end loop;
               
    return next;


exception
    when no_data_found THEN
        raise notice 'nessuna classificazione trovata' ;
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