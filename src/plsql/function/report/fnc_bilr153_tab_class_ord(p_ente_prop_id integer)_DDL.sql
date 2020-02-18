/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_bilr153_tab_class_ord (
  p_ente_prop_id integer
)
RETURNS TABLE (
  ord_id integer,
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

ord_id:=null;
code_cofog:='';
code_transaz_ue:='';
perim_sanitario_spesa:='';
ricorrente_spesa:='';
perim_sanitario_entrata:='';
code_transaz_ue_entrata:='';
ricorrente_entrata:='';

for elencoClass in                                                
	with classif_ord as (
        select distinct 
        	COALESCE(d_class_tipo.classif_tipo_code,'') classif_tipo_code_ord, 
            COALESCE(t_class.classif_code,'') classif_code_ord,
            r_ordinativo_class.ord_id ord_id_ord           
            from 
             siac_t_class t_class,
             siac_d_class_tipo d_class_tipo,
             siac_r_ordinativo_class r_ordinativo_class,
             siac_t_ordinativo t_ordinativo
            where  d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
                and r_ordinativo_class.classif_id=t_class.classif_id
                AND t_ordinativo.ord_id = r_ordinativo_class.ord_id
                and t_class.ente_proprietario_id=p_ente_prop_id   
                and d_class_tipo.classif_tipo_code in ('GRUPPO_COFOG',
                  'PERIMETRO_SANITARIO_SPESA',   'PERIMETRO_SANITARIO_ENTRATA',                 
                  'TRANSAZIONE_UE_SPESA', 'RICORRENTE_SPESA',
                  'TRANSAZIONE_UE_ENTRATA')                                  
                and t_class.data_cancellazione IS NULL
                and d_class_tipo.data_cancellazione IS NULL
                and r_ordinativo_class.data_cancellazione IS NULL
                AND t_ordinativo.data_cancellazione IS NULL ),
		classif_liq as(    
          select distinct  COALESCE(d_class_tipo.classif_tipo_code,'') classif_tipo_code_liq, 
              COALESCE(t_class.classif_code,'') classif_code_liq, 
              t_ord_ts.ord_id ord_id_liq            
                  from 
                   siac_t_class t_class,
                   siac_d_class_tipo d_class_tipo,
                   siac_r_liquidazione_class r_liquidazione_class,
                   siac_r_liquidazione_ord r_liquid_ord,
                   siac_t_ordinativo_ts t_ord_ts,
                   siac_t_ordinativo t_ordinativo
                   -- 07/'8/2017: AGGIUNTO RICORRENTE_ENTRATA
                  where  d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
                      and r_liquidazione_class.classif_id=t_class.classif_id
                      AND r_liquid_ord.liq_id=r_liquidazione_class.liq_id
                      AND t_ord_ts.ord_ts_id=r_liquid_ord.sord_id
                      AND t_ordinativo.ord_id = t_ord_ts.ord_id                      
                      and r_liquidazione_class.ente_proprietario_id=p_ente_prop_id
                      and d_class_tipo.classif_tipo_code in ('GRUPPO_COFOG',
                        'PERIMETRO_SANITARIO_SPESA',   'PERIMETRO_SANITARIO_ENTRATA',                 
                        'TRANSAZIONE_UE_SPESA', 'RICORRENTE_SPESA',
                        'TRANSAZIONE_UE_ENTRATA','RICORRENTE_ENTRATA')                              
                      and t_class.data_cancellazione IS NULL
                      and d_class_tipo.data_cancellazione IS NULL
                      and r_liquidazione_class.data_cancellazione IS NULL
                      AND r_liquid_ord.data_cancellazione IS NULL
                      AND t_ord_ts.data_cancellazione IS NULL
                      AND t_ordinativo.data_cancellazione IS NULL)  
          SELECT 
          		classif_ord.ord_id_ord ord_id,
          		CASE WHEN COALESCE(classif_ord.classif_tipo_code_ord,'') = ''
       				THEN COALESCE(classif_liq.classif_tipo_code_liq,'')                	                   
                	ELSE classif_ord.classif_tipo_code_ord
                	END classif_tipo_code,
                CASE WHEN COALESCE(classif_ord.classif_code_ord,'') = ''
       				THEN COALESCE(classif_liq.classif_code_liq,'')                	                   
                	ELSE classif_ord.classif_code_ord
                	END classif_code     
          FROM classif_ord
          		LEFT JOIN classif_liq
                    ON (classif_liq.ord_id_liq= classif_ord.ord_id_ord
                    	AND classif_liq.classif_tipo_code_liq= classif_ord.classif_tipo_code_ord)                        
          order by ord_id, classif_tipo_code
    loop
       if ord_id is not null and 
       		ord_id <> elencoClass.ord_id THEN
                                                 
              return next;
                         
              ord_id:=null;
              code_cofog:='';
              code_transaz_ue:='';            
              perim_sanitario_spesa:='';
              ricorrente_spesa:='';
              perim_sanitario_entrata:='';
              code_transaz_ue_entrata:='';
              ricorrente_entrata:='';
              
        end if;
        
        ord_id=elencoClass.ord_id;
        
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