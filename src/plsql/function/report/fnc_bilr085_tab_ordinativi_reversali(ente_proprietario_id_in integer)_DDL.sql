/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_bilr085_tab_ordinativi_reversali (
  ente_proprietario_id_in integer
)
RETURNS TABLE (
  ord_id_da integer,
  elenco_reversali text,
  split_reverse text,
  onere_tipo_code varchar,
  relaz_tipo_code varchar,
  importo_split numeric,
  importo_imponibile numeric,
  onere_code_irpef varchar,
  importo_irpef_imponibile numeric,
  importo_irpef_imposta numeric,
  importo_inps_imponibile numeric,
  importo_inps_imposta numeric
) AS
$body$
DECLARE
RTN_MESSAGGIO varchar;
reversale record;
begin 
ord_id_da:=null;
elenco_reversali:='';
split_reverse:='';
onere_code_irpef:='';
importo_split:=0;
importo_irpef_imponibile:=0;
importo_irpef_imposta:=0;
importo_inps_imponibile:=0;
importo_inps_imposta:=0;

RTN_MESSAGGIO:='Errore generico';

/* 14/09/2017: Function modificata per restituire importi diversi per ogni tipologia
	di imposta.
*/
for reversale in 
select 
a.ord_id_da,
b.ord_numero, b.ord_emissione_data,
                    b.ord_id,d.relaz_tipo_code,
                    f.ord_ts_det_importo importo_ord,
                    i.importo_carico_ente, i.importo_imponibile,
              		m.onere_tipo_code, l.onere_code
            from  siac_r_ordinativo a, siac_t_ordinativo b,
                  siac_d_ordinativo_tipo c,
                  siac_d_relaz_tipo d, siac_t_ordinativo_ts e,
                  siac_t_ordinativo_ts_det f, 
                  siac_d_ordinativo_ts_det_tipo g,
                  siac_r_doc_onere_ordinativo_ts h,
             	  siac_r_doc_onere i, siac_d_onere l,
              	  siac_d_onere_tipo  m
                  where 
                  a.ente_proprietario_id=ente_proprietario_id_in  and 
                  b.ord_id=a.ord_id_a
                  	AND c.ord_tipo_id=b.ord_tipo_id
                    AND d.relaz_tipo_id=a.relaz_tipo_id
                    AND e.ord_id=b.ord_id
                    AND f.ord_ts_id=e.ord_ts_id
                    AND g.ord_ts_det_tipo_id=f.ord_ts_det_tipo_id
                    AND h.ord_ts_id=e.ord_ts_id
                  	AND i.doc_onere_id=h.doc_onere_id
                  	AND l.onere_id=i.onere_id
                  	AND m.onere_tipo_id=l.onere_tipo_id
                    AND c.ord_tipo_code ='I'
                    AND g.ord_ts_det_tipo_code='A'
                    --AND m.onere_tipo_code in('SPR','IRPEF','INPS')
                AND d.data_cancellazione IS NULL
                AND b.data_cancellazione IS NULL
                AND a.data_cancellazione IS NULL
                AND c.data_cancellazione IS NULL
                AND e.data_cancellazione IS NULL
                AND f.data_cancellazione IS NULL
                AND g.data_cancellazione IS NULL
                AND h.data_cancellazione IS NULL
                AND i.data_cancellazione IS NULL
                AND l.data_cancellazione IS NULL
                AND m.data_cancellazione IS NULL
                order by 1,2
loop


--raise notice 'ord_id_da: %  ord_id_da_cursore: %',ord_id_da::varchar, reversale.ord_id_da::varchar ;
     if ord_id_da<>reversale.ord_id_da THEN
        return next;
        elenco_reversali:='';
        split_reverse:='';
        onere_code_irpef:='';
        importo_split:=0;
        importo_irpef_imponibile:=0;
        importo_irpef_imposta:=0;
        importo_inps_imponibile:=0;
        importo_inps_imposta:=0;
     end if;

    ord_id_da:=reversale.ord_id_da;
    onere_tipo_code:=reversale.onere_tipo_code;

    relaz_tipo_code:=reversale.relaz_tipo_code;


    importo_imponibile:=reversale.importo_imponibile;



      if elenco_reversali = '' THEN
        elenco_reversali = reversale.ord_numero ::VARCHAR ||' del '|| to_char(reversale.ord_emissione_data,'dd/mm/yyyy');
     -- raise notice 'elenco_reversali: %',elenco_reversali ;
      else
        elenco_reversali = elenco_reversali||', '||reversale.ord_numero ::VARCHAR ||' del '|| to_char(reversale.ord_emissione_data,'dd/mm/yyyy');
      end if;
      
    if reversale.relaz_tipo_code='SPR' then 
        importo_split:=importo_split+reversale.importo_ord;
      if split_reverse = '' THEN	
        split_reverse=reversale.ord_numero ::VARCHAR ||' del '|| to_char(reversale.ord_emissione_data,'dd/mm/yyyy');
     --    raise notice 'split_reverse: %',split_reverse ;
      else
        split_reverse=split_reverse||', '||reversale.ord_numero ::VARCHAR ||' del '|| to_char(reversale.ord_emissione_data,'dd/mm/yyyy');
      end if;
    elsif upper(onere_tipo_code) = 'IRPEF' THEN  
        importo_irpef_imponibile:=importo_irpef_imponibile+reversale.importo_imponibile;
        importo_irpef_imposta:=importo_irpef_imposta+reversale.importo_ord;
        onere_code_irpef:=reversale.onere_code;
    elsif upper(onere_tipo_code) = 'INPS' THEN
        importo_inps_imponibile:=importo_inps_imponibile+reversale.importo_imponibile;
        importo_inps_imposta:=importo_inps_imposta+reversale.importo_ord;
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