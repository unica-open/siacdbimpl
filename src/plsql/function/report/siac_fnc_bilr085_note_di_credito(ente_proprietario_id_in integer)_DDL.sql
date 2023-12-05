/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_bilr085_note_di_credito (
  ente_proprietario_id_in integer
)
RETURNS TABLE (
  doc_id integer,
  num_doc_ncd text
) AS
$body$
DECLARE
RTN_MESSAGGIO varchar;
ndc record;
begin 
doc_id:=null;
num_doc_ncd:='';

RTN_MESSAGGIO:='Errore generico';
for ndc in 
 SELECT 
         a.doc_id_da,c.doc_anno,c.doc_numero, d.doc_tipo_code
            FROM siac_r_doc a, 
            		siac_d_relaz_tipo b,
                    siac_t_doc c,
                    siac_d_doc_tipo d
            WHERE a.relaz_tipo_id=b.relaz_tipo_id
            	AND c.doc_id=a.doc_id_a
                AND d.doc_tipo_id=c.doc_tipo_id
                AND b.relaz_tipo_code='NCD' -- note di credito
                AND a.data_cancellazione IS NULL
                AND b.data_cancellazione IS NULL
                AND c.data_cancellazione IS NULL
                AND d.data_cancellazione IS NULL
                and a.ente_proprietario_id=ente_proprietario_id_in
                order by 1,2,3
loop


--raise notice 'ord_id_da: %  ord_id_da_cursore: %',ord_id_da::varchar, ndc.ord_id_da::varchar ;

if doc_id<>ndc.doc_id_da THEN
return next;
num_doc_ncd:='';
end if;

doc_id:=ndc.doc_id_da;

  if num_doc_ncd = '' THEN
  	num_doc_ncd = ndc.doc_anno ::VARCHAR ||' - '|| ndc.doc_tipo_code::varchar||' - '|| ndc.doc_numero::varchar;
 -- raise notice 'num_doc_ncd: %',num_doc_ncd ;
  else
  	num_doc_ncd = num_doc_ncd||', '||ndc.doc_anno ::VARCHAR ||' - '|| ndc.doc_tipo_code::varchar||' - '|| ndc.doc_numero::varchar;
  end if;


end loop;

return next;
exception
	when no_data_found THEN
		raise notice 'nessuna nota di credito trovata' ;
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