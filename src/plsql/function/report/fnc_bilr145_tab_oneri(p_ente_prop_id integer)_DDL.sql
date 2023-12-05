/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_bilr145_tab_oneri (
  p_ente_prop_id integer
)
RETURNS TABLE (
  ord_id integer,
  importo_imposta numeric,
  importo_ritenuta numeric
) AS
$body$
DECLARE
RTN_MESSAGGIO varchar;
elencoOneri record;


BEGIN
ord_id:=null;


RTN_MESSAGGIO:='Funzione di ricerca degli oneri';

importo_imposta:=0;
importo_ritenuta:=0;

for elencoOneri in 
     SELECT t_ordinativo_ts.ord_id,
           	  d_onere_tipo.onere_tipo_code, d_onere.onere_code,
              sum(r_doc_onere.importo_imponibile) IMPORTO_ONERE,
              sum(r_doc_onere.importo_carico_soggetto) IMPOSTA
            from siac_t_ordinativo_ts t_ordinativo_ts,            
                siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts,            
                siac_t_doc t_doc, 
                siac_t_subdoc t_subdoc,
                siac_r_doc_onere r_doc_onere,
                siac_d_onere d_onere,
                siac_d_onere_tipo d_onere_tipo
            WHERE r_subdoc_ordinativo_ts.ord_ts_id=t_ordinativo_ts.ord_ts_id
                AND t_doc.doc_id=t_subdoc.doc_id
                and t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id
                AND r_doc_onere.doc_id=t_doc.doc_id
                AND d_onere.onere_id=r_doc_onere.onere_id
                AND d_onere_tipo.onere_tipo_id=d_onere.onere_tipo_id         
                --AND t_ordinativo_ts.ord_id=elencoReversali.ord_id     
                AND t_ordinativo_ts.ente_proprietario_id=p_ente_prop_id     
                AND t_doc.data_cancellazione IS NULL
                AND t_subdoc.data_cancellazione IS NULL
                AND r_doc_onere.data_cancellazione IS NULL
                AND d_onere.data_cancellazione IS NULL
                AND d_onere_tipo.data_cancellazione IS NULL
                AND t_ordinativo_ts.data_cancellazione IS NULL
                AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL
                GROUP BY t_ordinativo_ts.ord_id, d_onere_tipo.onere_tipo_code,
                	d_onere.onere_code
        loop       
                  

     
            --	elencoAccertamenti.movgest_ts_code;
            -- se cambio ordinativo restituisco il record.
            if ord_id is not null and 
            	ord_id <> elencoOneri.ord_id THEN
                  return next;                  
                  importo_imposta:=0;
                  importo_ritenuta:=0;
           	end if;
                        
            ord_id=elencoOneri.ord_id;
            IF elencoOneri.onere_tipo_code = 'IRPEF' THEN
                  importo_imposta = elencoOneri.IMPOSTA; 
            ELSIF  elencoOneri.onere_tipo_code = 'INPS' THEN
                  importo_ritenuta = elencoOneri.IMPOSTA;  
            END IF;  
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