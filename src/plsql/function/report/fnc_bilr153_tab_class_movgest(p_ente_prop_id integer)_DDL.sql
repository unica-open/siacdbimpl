/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_bilr153_tab_class_movgest (
  p_ente_prop_id integer
)
RETURNS TABLE (
  movgest_id integer,
  code_cofog varchar,
  code_transaz_ue varchar,
  perim_sanitario_spesa varchar,
  ricorrente_spesa varchar,
  perim_sanitario_entrata varchar,
  code_transaz_ue_entrata varchar,
  pdc_v varchar,
  ricorrente_entrata varchar
) AS
$body$
DECLARE

RTN_MESSAGGIO varchar;
elencoClass record;

BEGIN

movgest_id:=null;
code_cofog:='';
code_transaz_ue:='';
perim_sanitario_spesa:='';
ricorrente_spesa:='';
perim_sanitario_entrata:='';
code_transaz_ue_entrata:='';
pdc_v:='';
ricorrente_entrata:='';

for elencoClass in                                                
        select distinct 
            COALESCE(d_class_tipo.classif_tipo_code,'') classif_tipo_code, 
                COALESCE(t_class.classif_code,'') classif_code, 
                	t_movgest_ts.movgest_id
                FROM
          			siac_t_class t_class,
                   	siac_d_class_tipo d_class_tipo,
                    siac_r_movgest_class r_movgest_class,
                    siac_r_movgest_bil_elem   r_movgest_bil_elem,
                    siac_t_movgest_ts t_movgest_ts
                -- 07/'8/2017: AGGIUNTO RICORRENTE_ENTRATA
                WHERE d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
                      and r_movgest_class.classif_id=t_class.classif_id
                	  and r_movgest_bil_elem.movgest_id = t_movgest_ts.movgest_id
                      and t_movgest_ts.movgest_ts_id = r_movgest_class.movgest_ts_id
                      AND t_class.ente_proprietario_id = p_ente_prop_id
                      and d_class_tipo.classif_tipo_code in ('GRUPPO_COFOG',
                        'PERIMETRO_SANITARIO_SPESA', 'PERIMETRO_SANITARIO_ENTRATA',                 
                        'TRANSAZIONE_UE_SPESA', 'RICORRENTE_SPESA',
                        'TRANSAZIONE_UE_ENTRATA', 'PDC_V','RICORRENTE_ENTRATA')
                      AND t_class.data_cancellazione IS NULL
                      AND d_class_tipo.data_cancellazione IS NULL
                      AND r_movgest_class.data_cancellazione IS NULL
                      AND r_movgest_bil_elem.data_cancellazione IS NULL
                      AND t_movgest_ts.data_cancellazione IS NULL     
      order by movgest_id, classif_tipo_code
    loop
       if movgest_id is not null and 
       		movgest_id <> elencoClass.movgest_id THEN
                                                 
              return next;
                         
              movgest_id:=null;
              code_cofog:='';
              code_transaz_ue:='';
              perim_sanitario_spesa:='';
              ricorrente_spesa:='';
              perim_sanitario_entrata:='';
              code_transaz_ue_entrata:='';
              pdc_v:='';
              ricorrente_entrata:='';
              
        end if;
        
        movgest_id=elencoClass.movgest_id;
        
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
        elsif elencoClass.classif_tipo_code ='PDC_V' THEN        
          pdc_v:=COALESCE(elencoClass.classif_code,'');  
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