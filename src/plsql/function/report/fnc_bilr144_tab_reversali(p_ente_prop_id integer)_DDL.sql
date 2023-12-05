/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_bilr144_tab_reversali (
  p_ente_prop_id integer
)
RETURNS TABLE (
  ord_id integer,
  conta_reversali integer,
  split_reverse varchar,
  importo_split_reverse numeric,
  elenco_reversali varchar,
  cod_tributo varchar,
  importo_irpef_imponibile numeric,
  importo_imposta numeric,
  importo_inps_inponibile numeric,
  importo_ritenuta numeric,
  importo_reversale numeric
) AS
$body$
DECLARE
RTN_MESSAGGIO varchar;
elencoReversali record;
ciclo integer;



BEGIN
ord_id:=null;

conta_reversali:=0;
importo_reversale:=0;
split_reverse:='';
elenco_reversali:='';
importo_split_reverse:=0;
cod_tributo:='';
importo_irpef_imponibile:=0;
importo_imposta:=0;
importo_inps_inponibile:=0;
importo_ritenuta:=0;

 for elencoReversali in     
        select t_ordinativo.ord_numero, t_ordinativo.ord_emissione_data,
                r_ordinativo.ord_id_da ord_id,d_relaz_tipo.relaz_tipo_code,
                t_ord_ts_det.ord_ts_det_importo importo_ord,
                r_doc_onere.importo_carico_ente, r_doc_onere.importo_imponibile,
                d_onere_tipo.onere_tipo_code, d_onere.onere_code
        from  siac_r_ordinativo r_ordinativo, 
              siac_t_ordinativo t_ordinativo,
              siac_d_ordinativo_tipo d_ordinativo_tipo,
              siac_d_relaz_tipo d_relaz_tipo, 
              siac_t_ordinativo_ts t_ord_ts,
              siac_t_ordinativo_ts_det t_ord_ts_det, 
              siac_d_ordinativo_ts_det_tipo ts_det_tipo,
              siac_r_doc_onere_ordinativo_ts r_doc_onere_ord_ts,
              siac_r_doc_onere r_doc_onere, 
              siac_d_onere d_onere,
              siac_d_onere_tipo  d_onere_tipo
              where t_ordinativo.ord_id=r_ordinativo.ord_id_a
                AND d_ordinativo_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id
                AND d_relaz_tipo.relaz_tipo_id=r_ordinativo.relaz_tipo_id
                AND t_ord_ts.ord_id=t_ordinativo.ord_id
                AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
                AND ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
                AND r_doc_onere_ord_ts.ord_ts_id=t_ord_ts_det.ord_ts_id
                AND r_doc_onere.doc_onere_id=r_doc_onere_ord_ts.doc_onere_id
                AND d_onere.onere_id=r_doc_onere.onere_id
                AND d_onere_tipo.onere_tipo_id=d_onere.onere_tipo_id
                AND d_ordinativo_tipo.ord_tipo_code ='I'
                AND ts_det_tipo.ord_ts_det_tipo_code='A'
                    /* cerco tutte le tipologie di relazione,
                        non solo RIT_ORD */          
              /* ord_id_da contiene l'ID del mandato
                 ord_id_a contiene l'ID della reversale */
            --AND r_ordinativo.ord_id_da = elencoMandati.ord_id
            AND r_ordinativo.ente_proprietario_id=p_ente_prop_id
            AND r_ordinativo.data_cancellazione IS NULL
            AND t_ordinativo.data_cancellazione IS NULL
            AND d_ordinativo_tipo.data_cancellazione IS NULL            
            AND d_relaz_tipo.data_cancellazione IS NULL
            AND t_ord_ts.data_cancellazione IS NULL
            AND t_ord_ts_det.data_cancellazione IS NULL
            AND ts_det_tipo.data_cancellazione IS NULL            
            AND r_doc_onere_ord_ts.data_cancellazione IS NULL
            AND r_doc_onere.data_cancellazione IS NULL
            AND d_onere.data_cancellazione IS NULL
            AND d_onere_tipo.data_cancellazione IS NULL
      order by r_ordinativo.ord_id_da  ,r_ordinativo.ord_id_a     
      loop
--raise notice 'Tipo rev=%, Importo rev=%, Imponibile=%' , elencoReversali.onere_tipo_code, elencoReversali.importo_ord, elencoReversali.importo_imponibile;          
             if ord_id is not null and 
            	ord_id <> elencoReversali.ord_id THEN
                  return next;
                  conta_reversali:=0;
                  importo_reversale:=0;
                  split_reverse:='';
                  elenco_reversali:='';
                  importo_split_reverse:=0;
                  cod_tributo:='';
                  importo_irpef_imponibile:=0;
                  importo_imposta:=0;
                  importo_inps_inponibile:=0;
                  importo_ritenuta:=0;
                end if;
            ord_id:=elencoReversali.ord_id;
            conta_reversali=conta_reversali+1;
            importo_reversale=elencoReversali.importo_ord;
                /* se il tipo di relazione è SPR, è SPLIT/REVERSE, carico l'importo */            
            if upper(elencoReversali.relaz_tipo_code)='SPR' THEN
                importo_split_reverse=importo_split_reverse+elencoReversali.importo_ord;
                if split_reverse = '' THEN
                    split_reverse=elencoReversali.ord_numero ::VARCHAR ||' del '|| to_char(elencoReversali.ord_emissione_data,'dd/mm/yyyy');
                else
                    split_reverse=split_reverse||', '||elencoReversali.ord_numero ::VARCHAR ||' del '|| to_char(elencoReversali.ord_emissione_data,'dd/mm/yyyy');
                end if;
            end if;
             /* anche split/reverse è una reversale, quindi qualunque tipo
                tipo di relazione concateno i risultati ottenuti 
                (possono essere più di 1) */
              
--raise notice 'elencoReversali.ord_numero =%', elencoReversali.ord_numero;              
              if elenco_reversali = '' THEN
                  elenco_reversali = elencoReversali.ord_numero ::VARCHAR ||' del '|| to_char(elencoReversali.ord_emissione_data,'dd/mm/yyyy');
              else
                  elenco_reversali = elenco_reversali||', '||elencoReversali.ord_numero ::VARCHAR ||' del '|| to_char(elencoReversali.ord_emissione_data,'dd/mm/yyyy');
              end if;
              /* utilizzando il legame con la tabella siac_r_doc_onere_ordinativo_ts
              	si può capire se la reversale ha un onere INPS/IRPEF e recuperarne
                gli importi */
              /* devono essere considerati gli importi di tutte le
              	reversali, quindi li sommo */
              IF upper(elencoReversali.onere_tipo_code) = 'IRPEF' THEN
              	cod_tributo=elencoReversali.onere_code;            
              	importo_irpef_imponibile= importo_irpef_imponibile+elencoReversali.importo_imponibile;
                importo_imposta=importo_imposta+elencoReversali.importo_ord;
              elsif upper(elencoReversali.onere_tipo_code) = 'INPS' THEN
                importo_inps_inponibile=importo_inps_inponibile+elencoReversali.importo_imponibile;
                importo_ritenuta=importo_ritenuta+elencoReversali.importo_ord;
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