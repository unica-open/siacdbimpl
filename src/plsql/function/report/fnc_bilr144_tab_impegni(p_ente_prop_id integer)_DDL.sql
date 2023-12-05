/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_bilr144_tab_impegni (
  p_ente_prop_id integer
)
RETURNS TABLE (
  ord_id integer,
  num_impegno varchar,
  anno_primo_impegno varchar
) AS
$body$
DECLARE
RTN_MESSAGGIO varchar;
elencoImpegni record;


BEGIN
ord_id:=null;


RTN_MESSAGGIO:='Funzione di ricerca degli impegni';

anno_primo_impegno='';
num_impegno='';

for elencoImpegni in 
      SELECT t_movgest.movgest_anno, t_movgest.movgest_numero,
          t_movgest_ts.movgest_ts_code, t_ord_ts.ord_id
      FROM siac_t_movgest t_movgest,
          siac_t_movgest_ts t_movgest_ts,
          siac_r_liquidazione_movgest r_liquid_movgest,
          siac_r_liquidazione_ord r_liquid_ord,
          siac_t_ordinativo_ts t_ord_ts
      WHERE t_movgest.movgest_id=t_movgest_ts.movgest_id
          AND r_liquid_movgest.movgest_ts_id= t_movgest_ts.movgest_ts_id
          AND r_liquid_ord.liq_id=r_liquid_movgest.liq_id
          AND t_ord_ts.ord_ts_id=r_liquid_ord.sord_id
          --AND r_liquid_movgest.liq_id=elencoMandati.liq_id
          AND t_movgest.ente_proprietario_id=p_ente_prop_id
          AND r_liquid_movgest.data_cancellazione IS NULL
          AND t_movgest_ts.data_cancellazione IS NULL
          AND t_movgest.data_cancellazione IS NULL
          AND r_liquid_ord.data_cancellazione IS NULL
          AND t_ord_ts.data_cancellazione IS NULL
      ORDER BY t_ord_ts.ord_id, t_movgest.movgest_anno, t_movgest.movgest_numero
  loop
        	--raise notice 'ORD_ID = % IMPEGNO % % %',elencoImpegni.ord_id, elencoImpegni.movgest_anno, elencoImpegni.movgest_numero,
            --	elencoImpegni.movgest_ts_code;
            -- se cambio ordinativo restituisco il record.
            if ord_id is not null and 
            	ord_id <> elencoImpegni.ord_id THEN
                  return next;
                  num_impegno='';
                  anno_primo_impegno='';
           	end if;
                        
            ord_id=elencoImpegni.ord_id;
            /* devo restituire l'anno dell'impegno perchè sulla stampa
                    devo distinguere tra COMPETENZA/RESIDUI.
                    Se ci sono più impegni restituisco solo il primo */
              if anno_primo_impegno='' THEN
                  anno_primo_impegno= elencoImpegni.movgest_anno;               
              end if;
              if num_impegno = '' then
              	num_impegno=elencoImpegni.movgest_anno||'/'||elencoImpegni.movgest_numero;
              else
              	num_impegno=num_impegno||' ' ||elencoImpegni.movgest_anno||
                	'/'||elencoImpegni.movgest_numero;
              end if;
              	--se il sub-impegno è diverso dall'impegno lo concateno
              if elencoImpegni.movgest_numero <> 
              	elencoImpegni.movgest_ts_code ::INTEGER THEN
              	num_impegno=num_impegno||'/'||elencoImpegni.movgest_ts_code;
              end if;
    end loop;
        
 return next;


exception
    when no_data_found THEN
        raise notice 'nessun mandato trovato' ;
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