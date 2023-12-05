/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_bilr144_tab_ncd (
  p_ente_prop_id integer
)
RETURNS TABLE (
  doc_id integer,
  num_doc_ncd varchar
) AS
$body$
DECLARE
RTN_MESSAGGIO varchar;
elencoNoteCredito record;

BEGIN
doc_id:=null;


RTN_MESSAGGIO:='Funzione di ricerca delle note di credito';

num_doc_ncd:='';

for elencoNoteCredito in 
    SELECT r_doc.doc_id_a ,r_doc.doc_id_da doc_id,
    			d_relaz_tipo.relaz_tipo_code,t_doc.doc_anno,
            	COALESCE(t_doc.doc_numero,'') doc_numero, 
                COALESCE(t_doc.doc_importo,0) doc_importo, 
                COALESCE(d_doc_tipo.doc_tipo_code,'') doc_tipo_code
            FROM 	siac_r_doc r_doc, 
            		siac_d_relaz_tipo d_relaz_tipo,
                    siac_t_doc t_doc,
                    siac_d_doc_tipo d_doc_tipo
            WHERE r_doc.relaz_tipo_id=d_relaz_tipo.relaz_tipo_id
            	AND t_doc.doc_id=r_doc.doc_id_a
                AND d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id
                --AND r_doc.doc_id_da = elencoMandati.doc_id
                AND t_doc.ente_proprietario_id=p_ente_prop_id
                AND d_relaz_tipo.relaz_tipo_code='NCD' -- note di credito
                AND r_doc.data_cancellazione IS NULL
                AND d_relaz_tipo.data_cancellazione IS NULL
                AND t_doc.data_cancellazione IS NULL
                AND d_doc_tipo.data_cancellazione IS NULL
            ORDER BY r_doc.doc_id_da
  loop
        	--raise notice 'ORD_ID = % IMPEGNO % % %',elencoImpegni.ord_id, elencoImpegni.movgest_anno, elencoImpegni.movgest_numero,
            --	elencoImpegni.movgest_ts_code;
            -- se cambio ordinativo restituisco il record.
            if doc_id is not null and 
            	doc_id <> elencoNoteCredito.doc_id THEN
                  return next;
                  num_doc_ncd:='';				  
           	end if;
                        
            doc_id=elencoNoteCredito.doc_id;
            
             if num_doc_ncd = '' THEN
            	num_doc_ncd=elencoNoteCredito.doc_anno ||' - '||elencoNoteCredito.doc_tipo_code||' - '||elencoNoteCredito.doc_numero;               
            else 
            	num_doc_ncd=num_doc_ncd||', '||elencoNoteCredito.doc_anno ||' - '||elencoNoteCredito.doc_tipo_code||' - '||elencoNoteCredito.doc_numero;               
            END IF;   
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