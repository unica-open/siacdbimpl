/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_bilr152_tab_attrib (
  p_ente_prop_id integer
)
RETURNS TABLE (
  movgest_ts_id integer,
  anno_riaccertato varchar,
  numero_riaccertato varchar,
  anno_origine_plur varchar,
  numero_origine_plur varchar,
  flag_prenotazione varchar
) AS
$body$
DECLARE
RTN_MESSAGGIO varchar;
elencoAttr record;
mioValore varchar;

BEGIN

movgest_ts_id:=null;
anno_riaccertato:='';
numero_riaccertato:='';
anno_origine_plur:='';
numero_origine_plur:='';
mioValore:='';
flag_prenotazione:='';

for elencoAttr in                             
        select r_movgest_ts_attr.movgest_ts_id,t_attr.attr_code,
            r_movgest_ts_attr.testo, r_movgest_ts_attr.numerico   ,
            r_movgest_ts_attr."boolean"
        from siac_r_movgest_ts_attr r_movgest_ts_attr,
            siac_t_attr t_attr
        where r_movgest_ts_attr.attr_id=t_attr.attr_id
            and r_movgest_ts_attr.ente_proprietario_id=p_ente_prop_id
            and t_attr.attr_code in ('annoRiaccertato','numeroRiaccertato',
                    'annoOriginePlur','numeroOriginePlur',
                    'flagPrenotazione')
            and r_movgest_ts_attr.data_cancellazione is null
            and t_attr.data_cancellazione is null     
        order by r_movgest_ts_attr.movgest_ts_id 
    loop
     if movgest_ts_id is not null and 
            movgest_ts_id <> elencoAttr.movgest_ts_id THEN
                                               
     		return next;
                       
            movgest_ts_id:=null;
            anno_riaccertato:='';
            numero_riaccertato:='';
            anno_origine_plur:='';
            numero_origine_plur:=''; 
            flag_prenotazione:='';
             
            mioValore:='';
            
      end if;
      
	  movgest_ts_id=elencoAttr.movgest_ts_id;
      	--ci sono casi in cui il testo contiene la stringa NULL
        --quindi in questi casi metto stringa vuota.
      if upper(COALESCE(elencoAttr.testo,'')) = 'NULL' then
      	mioValore:='';
      else
      	mioValore:=COALESCE(elencoAttr.testo,'');
      end if;
      
      IF elencoAttr.attr_code ='annoRiaccertato' THEN
      	if mioValore = '0' then
      		anno_riaccertato:='';
      	else
        	anno_riaccertato:=mioValore;
        end if;
      elsif elencoAttr.attr_code ='numeroRiaccertato' THEN
      	numero_riaccertato:=mioValore;
      elsif elencoAttr.attr_code ='annoOriginePlur' THEN 
      	if mioValore = '0' then     
        	anno_origine_plur:='';
        else 	
        	anno_origine_plur:=mioValore; 
        end if;       
      elsif elencoAttr.attr_code ='numeroOriginePlur' THEN
        numero_origine_plur:=mioValore;  
      elsif  elencoAttr.attr_code ='flagPrenotazione' THEN
       	flag_prenotazione:= COALESCE(elencoAttr.boolean,'');                                                               
      end if;    
              
    end loop;
        
        --raise notice 'cod_v_livello1 = %', replace(substr(cod_v_livello,2, char_length(cod_v_livello)-1),'.','');       
   
    return next;


exception
    when no_data_found THEN
        raise notice 'nessun attributo trovato' ;
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