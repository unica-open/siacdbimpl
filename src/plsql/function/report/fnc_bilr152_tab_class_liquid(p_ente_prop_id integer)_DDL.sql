/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_bilr152_tab_class_liquid (
  p_ente_prop_id integer
)
RETURNS TABLE (
  liquid_id integer,
  code_transaz_ue varchar,
  ricorrente_spesa varchar,
  pdc_v varchar
) AS
$body$
DECLARE

RTN_MESSAGGIO varchar;
elencoClass record;

BEGIN

liquid_id:=null;
code_transaz_ue:='';
ricorrente_spesa:='';
pdc_v:='';

for elencoClass in                                                
        select distinct 
            COALESCE(d_class_tipo.classif_tipo_code,'') classif_tipo_code, 
                COALESCE(t_class.classif_code,'') classif_code, 
                COALESCE(t_class.classif_desc,'') classif_desc, 
                	r_liq_class.liq_id
                FROM
          			siac_t_class t_class,
                   	siac_d_class_tipo d_class_tipo,
                    siac_r_liquidazione_class r_liq_class
                WHERE d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
                      and r_liq_class.classif_id=t_class.classif_id                	  
                      AND t_class.ente_proprietario_id = p_ente_prop_id
                      and d_class_tipo.classif_tipo_code in (
                      'TRANSAZIONE_UE_SPESA',                 
                      'RICORRENTE_SPESA', 'PDC_V')
                      AND t_class.data_cancellazione IS NULL
                      AND d_class_tipo.data_cancellazione IS NULL
                      AND r_liq_class.data_cancellazione IS NULL    
      order by liq_id, classif_tipo_code
    loop
       if liquid_id is not null and 
       		liquid_id <> elencoClass.liq_id THEN
                                                 
              return next;
                         
              liquid_id:=null;
              code_transaz_ue:='';
              ricorrente_spesa:='';
              pdc_v:='';
              
        end if;
        
        liquid_id=elencoClass.liq_id;
        
        IF elencoClass.classif_tipo_code ='TRANSAZIONE_UE_SPESA' THEN
          code_transaz_ue:=COALESCE(elencoClass.classif_code,'');    
         elsif elencoClass.classif_tipo_code ='RICORRENTE_SPESA' THEN
          ricorrente_spesa:=COALESCE(elencoClass.classif_desc,'');  
        elsif elencoClass.classif_tipo_code ='PDC_V' THEN
          pdc_v:=COALESCE(elencoClass.classif_code,'');                                                       
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