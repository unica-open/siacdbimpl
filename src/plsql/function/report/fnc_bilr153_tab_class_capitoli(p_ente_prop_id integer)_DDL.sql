/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_bilr153_tab_class_capitoli (
  p_ente_prop_id integer
)
RETURNS TABLE (
  elem_id integer,
  code_cofog varchar,
  code_transaz_ue varchar,
  perim_sanitario_spesa varchar,
  ricorrente_spesa varchar,
  perim_sanitario_entrata varchar,
  code_transaz_ue_entrata varchar,
  ricorrente_entrata varchar
) AS
$body$
DECLARE
RTN_MESSAGGIO varchar;
elencoClass record;

BEGIN

elem_id:=null;
code_cofog:='';
code_transaz_ue:='';

perim_sanitario_spesa:='';
ricorrente_spesa:='';
perim_sanitario_entrata:='';
code_transaz_ue_entrata:='';
ricorrente_entrata:='';

for elencoClass in                             
      select d_class_tipo.classif_tipo_code,
              r_bil_elem_class.elem_id,
              t_class.classif_code, t_class.classif_desc
      from siac_t_class t_class,
      		siac_d_class_tipo d_class_tipo,
            siac_r_bil_elem_class r_bil_elem_class
      -- 07/'8/2017: AGGIUNTO RICORRENTE_ENTRATA
      where  t_class.classif_tipo_id= d_class_tipo.classif_tipo_id
            and r_bil_elem_class.classif_id= t_class.classif_id
            and d_class_tipo.classif_tipo_code in('GRUPPO_COFOG',
                'PERIMETRO_SANITARIO_SPESA', 'PERIMETRO_SANITARIO_ENTRATA',                 
                'TRANSAZIONE_UE_SPESA', 'RICORRENTE_SPESA',
                'TRANSAZIONE_UE_ENTRATA','RICORRENTE_ENTRATA')
            and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
            and t_class.data_cancellazione is null
            and d_class_tipo.data_cancellazione is null
            and r_bil_elem_class.data_cancellazione is null  
            and r_bil_elem_class.validita_fine is null                                               
      order by r_bil_elem_class.elem_id 
    loop
       if elem_id is not null and 
       		elem_id <> elencoClass.elem_id THEN
                                                 
              return next;
                         
              elem_id:=null;
              code_cofog:='';
              code_transaz_ue:='';
              perim_sanitario_spesa:='';
              ricorrente_spesa:='';
              perim_sanitario_entrata:='';
              code_transaz_ue_entrata:='';
              ricorrente_entrata:='';
              
        end if;
        
        elem_id=elencoClass.elem_id;
        
        IF elencoClass.classif_tipo_code ='GRUPPO_COFOG' THEN
          code_cofog:=COALESCE(elencoClass.classif_code,'');
        elsif elencoClass.classif_tipo_code ='TRANSAZIONE_UE_SPESA' THEN
          code_transaz_ue:=COALESCE(elencoClass.classif_code,'');
        elsif elencoClass.classif_tipo_code ='PERIMETRO_SANITARIO_SPESA' THEN
          perim_sanitario_spesa:=COALESCE(elencoClass.classif_code,'');     
         elsif elencoClass.classif_tipo_code ='RICORRENTE_SPESA' THEN
          ricorrente_spesa:=COALESCE(elencoClass.classif_code,'');  
        elsif elencoClass.classif_tipo_code ='PERIMETRO_SANITARIO_ENTRATA' THEN
          perim_sanitario_entrata:=COALESCE(elencoClass.classif_code,''); 
        elsif elencoClass.classif_tipo_code ='TRANSAZIONE_UE_ENTRATA' THEN
          code_transaz_ue_entrata:=COALESCE(elencoClass.classif_code,''); 
        elsif elencoClass.classif_tipo_code ='RICORRENTE_ENTRATA' THEN
          ricorrente_entrata:=COALESCE(elencoClass.classif_code,'');                                          
        end if;    
              
    end loop;
        
        --raise notice 'cod_v_livello1 = %', replace(substr(cod_v_livello,2, char_length(cod_v_livello)-1),'.','');       
   
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