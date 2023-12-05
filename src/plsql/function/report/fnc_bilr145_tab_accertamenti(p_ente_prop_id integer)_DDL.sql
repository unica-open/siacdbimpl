/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_bilr145_tab_accertamenti (
  p_ente_prop_id integer
)
RETURNS TABLE (
  ord_id integer,
  num_accertamento varchar,
  anno_primo_accertamento varchar
) AS
$body$
DECLARE
RTN_MESSAGGIO varchar;
elencoAccertamenti record;


BEGIN
ord_id:=null;


RTN_MESSAGGIO:='Funzione di ricerca degli accertamenti';

anno_primo_accertamento='';
num_accertamento='';

for elencoAccertamenti in 
      SELECT t_ord_ts.ord_id, t_movgest.movgest_anno, 
      			t_movgest.movgest_numero,
            	t_movgest_ts.movgest_ts_code
            FROM siac_t_movgest t_movgest,
            	siac_t_movgest_ts t_movgest_ts,
                siac_r_ordinativo_ts_movgest_ts r_ord_ts_movgest_ts,
                siac_t_ordinativo_ts t_ord_ts,
                siac_d_movgest_tipo d_movgest_tipo 
          	WHERE t_movgest.movgest_id=t_movgest_ts.movgest_id
            	AND r_ord_ts_movgest_ts.movgest_ts_id= t_movgest_ts.movgest_ts_id
                AND t_ord_ts.ord_ts_id=r_ord_ts_movgest_ts.ord_ts_id
                AND d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id                
                AND r_ord_ts_movgest_ts.ente_proprietario_id=p_ente_prop_id
                AND d_movgest_tipo.movgest_tipo_code='A' --accertamenti
                AND r_ord_ts_movgest_ts.data_cancellazione IS NULL
              	AND  t_movgest_ts.data_cancellazione IS NULL
                AND  t_movgest.data_cancellazione IS NULL
                AND t_ord_ts.data_cancellazione IS NULL
                AND d_movgest_tipo.data_cancellazione IS NULL
      ORDER BY t_ord_ts.ord_id, t_movgest.movgest_anno, t_movgest.movgest_numero
  loop
        	--raise notice 'ORD_ID = % ACCERT % % %',elencoAccertamenti.ord_id, elencoAccertamenti.movgest_anno, elencoAccertamenti.movgest_numero,
            --	elencoAccertamenti.movgest_ts_code;
            -- se cambio ordinativo restituisco il record.
            if ord_id is not null and 
            	ord_id <> elencoAccertamenti.ord_id THEN
                  return next;
                  num_accertamento='';
                  anno_primo_accertamento='';
           	end if;
                        
            ord_id=elencoAccertamenti.ord_id;
            /* devo restituire l'anno dell'accertamento perchè sulla stampa
                    devo distinguere tra COMPETENZA/RESIDUI.
                    Se ci sono più accertamenti restituisco solo il primo */
              if anno_primo_accertamento='' THEN
                  anno_primo_accertamento= elencoAccertamenti.movgest_anno;               
              end if;
              if num_accertamento = '' then
              	num_accertamento=elencoAccertamenti.movgest_anno||'/'||elencoAccertamenti.movgest_numero;
              else
              	num_accertamento=num_accertamento||' ' ||elencoAccertamenti.movgest_anno||
                	'/'||elencoAccertamenti.movgest_numero;
              end if;
              	--se il sub-accertamento è diverso dall'accertamento lo concateno
              if elencoAccertamenti.movgest_numero <> 
              	elencoAccertamenti.movgest_ts_code ::INTEGER THEN
              	num_accertamento=num_accertamento||'/'||elencoAccertamenti.movgest_ts_code;
              end if;
    end loop;
        
 return next;


exception
    when no_data_found THEN
        raise notice 'nessun accertamento trovato' ;
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