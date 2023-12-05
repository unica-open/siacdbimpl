/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_bilr144_tab_classif (
  p_ente_prop_id integer
)
RETURNS TABLE (
  ord_id integer,
  cod_gestione varchar,
  cod_cofog varchar,
  cod_trans_europea varchar,
  cod_v_livello varchar,
  ricorrente_spesa varchar,
  perimetro_sanitario varchar,
  politiche_reg_unitarie varchar,
  cod_siope varchar
) AS
$body$
DECLARE
RTN_MESSAGGIO varchar;
elencoClass record;
salva_pdc varchar;

BEGIN

ord_id:=null;
cod_gestione:='';
cod_cofog:='';
cod_trans_europea:='';
cod_v_livello:='';
ricorrente_spesa:='';
perimetro_sanitario:='';
politiche_reg_unitarie:='';
cod_siope:='';

for elencoClass in                             
        with classif_ord as(                
        select distinct COALESCE(d_class_tipo.classif_tipo_code,'') classif_tipo_code_ord, 
            COALESCE(t_class.classif_code,'') classif_code_ord,
            r_ordinativo_class.ord_id ord_id_ord, 
            t_ordinativo.ord_emissione_data ord_emissione_data_ord
            from 
             siac_t_class t_class,
             siac_d_class_tipo d_class_tipo,
             siac_r_ordinativo_class r_ordinativo_class,
             siac_t_ordinativo t_ordinativo
            where  d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
                and r_ordinativo_class.classif_id=t_class.classif_id
                AND t_ordinativo.ord_id = r_ordinativo_class.ord_id
               -- and r_ordinativo_class.ord_id = elencoMandati.ord_id
                and t_class.ente_proprietario_id=p_ente_prop_id                     
                and t_class.data_cancellazione IS NULL
                and d_class_tipo.data_cancellazione IS NULL
                and r_ordinativo_class.data_cancellazione IS NULL
                AND t_ordinativo.data_cancellazione IS NULL),
        classif_liq as(    
        select distinct  COALESCE(d_class_tipo.classif_tipo_code,'') classif_tipo_code_liq, 
            COALESCE(t_class.classif_code,'') classif_code_liq, 
            t_ord_ts.ord_id ord_id_liq,
            t_ordinativo.ord_emissione_data ord_emissione_data_liq
                from 
                 siac_t_class t_class,
                 siac_d_class_tipo d_class_tipo,
                 siac_r_liquidazione_class r_liquidazione_class,
                 siac_r_liquidazione_ord r_liquid_ord,
                 siac_t_ordinativo_ts t_ord_ts,
                 siac_t_ordinativo t_ordinativo 
                where  d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
                    and r_liquidazione_class.classif_id=t_class.classif_id
                    AND r_liquid_ord.liq_id=r_liquidazione_class.liq_id
                    AND t_ord_ts.ord_ts_id=r_liquid_ord.sord_id
                    AND t_ordinativo.ord_id = t_ord_ts.ord_id
                   -- and r_liquidazione_class.liq_id=elencoMandati.liq_id
                    and r_liquidazione_class.ente_proprietario_id=p_ente_prop_id                              
                    and t_class.data_cancellazione IS NULL
                    and d_class_tipo.data_cancellazione IS NULL
                    and r_liquidazione_class.data_cancellazione IS NULL
                    AND r_liquid_ord.data_cancellazione IS NULL
                    AND t_ord_ts.data_cancellazione IS NULL
                    AND t_ordinativo.data_cancellazione IS NULL)                        
        select  case when COALESCE(classif_code_ord,'')='' 
                  then ord_id_liq 
                  else ord_id_ord end ord_id, 
                case when COALESCE(classif_code_ord,'')='' 
                  then ord_emissione_data_liq 
                  else ord_emissione_data_ord end ord_emissione_data,
        		case when COALESCE(classif_tipo_code_ord,'')='' 
                  then COALESCE(classif_tipo_code_liq,'') 
                  else classif_tipo_code_ord end classif_tipo_code,
             	case when COALESCE(classif_code_ord,'')='' 
                  then COALESCE(classif_code_liq,'') 
                  else classif_code_ord end classif_code 
        from classif_ord
         	full join classif_liq
         	on (classif_ord.classif_tipo_code_ord=classif_liq.classif_tipo_code_liq 
        		and classif_ord.ord_id_ord=classif_liq.ord_id_liq)
        order by ord_id             
    loop
     if ord_id is not null and 
            ord_id <> elencoClass.ord_id THEN
            
                    /* se la data mandato è superiore al 31/12/2016 il siope equivale al
        	cod_v_livello senza punti */
              if to_date(to_char(elencoClass.ord_emissione_data,'dd/mm/yyyy'),'dd/mm/yyyy') 
                  > to_date('31/12/2016','dd/mm/yyyy') THEN 
                if salva_pdc <> '' THEN
                    cod_siope =  '-'||replace(substr(salva_pdc,2, char_length(salva_pdc)-1),'.','');       
                    cod_gestione:=replace(substr(salva_pdc,2, char_length(salva_pdc)-1),'.','');
                else
                    cod_siope = '';
                end if;
              end if;              
            
            return next;
            
            cod_gestione:='';
            cod_cofog:='';
            cod_trans_europea:='';
            cod_v_livello:='';
            ricorrente_spesa:='';
            perimetro_sanitario:='';
            politiche_reg_unitarie:='';
            cod_siope:='';            
      end if;
      
	  ord_id=elencoClass.ord_id;
      
      IF elencoClass.classif_tipo_code ='GRUPPO_COFOG' THEN
        cod_cofog='-'||elencoClass.classif_code;
      elsif elencoClass.classif_tipo_code ='TRANSAZIONE_UE_SPESA' THEN
        cod_trans_europea='-'||elencoClass.classif_code;
      elsif elencoClass.classif_tipo_code ='PDC_V' THEN
        cod_v_livello='-'||elencoClass.classif_code;
        salva_pdc:=elencoClass.classif_code;
      elsif elencoClass.classif_tipo_code ='RICORRENTE_SPESA' THEN
        ricorrente_spesa='-'||elencoClass.classif_code;
      elsif elencoClass.classif_tipo_code ='PERIMETRO_SANITARIO_SPESA' THEN
        perimetro_sanitario='-'||elencoClass.classif_code;            
      elsif elencoClass.classif_tipo_code ='POLITICHE_REGIONALI_UNITARIE' THEN
        politiche_reg_unitarie='-'||elencoClass.classif_code;   
      elsif substr(elencoClass.classif_tipo_code,1,11) ='SIOPE_SPESA' THEN 
      raise notice 'SIOPE = %', elencoClass.classif_code;           
        if elencoClass.classif_code <> 'XXXX' THEN --SIOPE NON PREVISTO
            cod_siope='-'||elencoClass.classif_code;  
            cod_gestione =elencoClass.classif_code;          
        else 
            cod_siope = '';
        end if;                          
        
       -- raise notice 'Tipo SIOPE =%',     elencoClass.classif_tipo_code;                            
      end if;    
              
    end loop;
        
        --raise notice 'cod_v_livello1 = %', replace(substr(cod_v_livello,2, char_length(cod_v_livello)-1),'.','');       
        
    if to_date(to_char(elencoClass.ord_emissione_data,'dd/mm/yyyy'),'dd/mm/yyyy') 
                  > to_date('31/12/2016','dd/mm/yyyy') THEN 
      if salva_pdc <> '' THEN
          cod_siope =  '-'||replace(substr(salva_pdc,2, char_length(salva_pdc)-1),'.','');       
          cod_gestione:=replace(substr(salva_pdc,2, char_length(salva_pdc)-1),'.','');
      else
          cod_siope = '';
      end if;
    end if;
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