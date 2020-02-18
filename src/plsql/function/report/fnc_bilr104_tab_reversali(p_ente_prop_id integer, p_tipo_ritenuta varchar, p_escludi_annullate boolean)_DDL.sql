/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_bilr104_tab_reversali (
  p_ente_prop_id integer,
  p_tipo_ritenuta varchar,
  p_escludi_annullate boolean
)
RETURNS TABLE (
  ord_id integer,
  conta_reversali integer,
  codice_risc varchar,
  onere_code varchar,
  onere_tipo_code varchar,
  importo_imponibile numeric,
  importo_ente numeric,
  importo_imposta numeric,
  importo_ritenuta numeric,
  importo_reversale numeric,
  importo_ord numeric,
  attivita_inizio date,
  attivita_fine date,
  attivita_code varchar,
  attivita_desc varchar,
  code_caus_770 varchar,
  desc_caus_770 varchar,
  code_caus_esenz varchar,
  desc_caus_esenz varchar,
  stato_reversale varchar,
  num_reversale integer
) AS
$body$
DECLARE
RTN_MESSAGGIO varchar;
elencoReversali record;
ciclo integer;
sql_query VARCHAR;

/*
Funzione utilizzata dal report BILR104 per estrarre le ritenute ed i relativi importi
per ogni ordinativo.
*/

BEGIN

ord_id:=null;
conta_reversali:=0;
importo_reversale:=0;
codice_risc:='';
onere_code:='';
onere_tipo_code:='';
importo_imponibile:=0;
importo_imposta:=0;
importo_ritenuta:=0;
importo_ente:=0;
importo_ord:=0;
attivita_inizio:=NULL;
attivita_fine:=NULL;
attivita_code:='';
attivita_desc:='';
code_caus_770:='';
desc_caus_770:='';
code_caus_esenz:='';
desc_caus_esenz:='';
stato_reversale:='';
num_reversale:=0;

/* 16/10/2017: resa dinamica la query.
		SIAC-5337: aggiunto parametro p_escludi_annullate perche' per alcuni casi
        	la procedura deve estrarre anche le reversali annullate mentre in
            altri casi deve escluderle.
	*/
sql_query:='select distinct t_ordinativo.ord_numero, t_ordinativo.ord_emissione_data,
                t_ordinativo.ord_id,d_relaz_tipo.relaz_tipo_code,
                t_ord_ts_det.ord_ts_det_importo importo_ord, r_ordinativo.ord_id_da,
                r_doc_onere.importo_carico_ente, r_doc_onere.importo_imponibile,
                d_onere_tipo.onere_tipo_code, d_onere.onere_code,
                COALESCE(d_dom_non_sogg_tipo.somma_non_soggetta_tipo_code,'''') somma_non_soggetta_tipo_code,
                COALESCE(d_dom_non_sogg_tipo.somma_non_soggetta_tipo_desc,'''') somma_non_soggetta_tipo_desc,
                caus_770.caus_code_770,
                caus_770.caus_desc_770,r_doc_onere.doc_onere_id,
                r_doc_onere.attivita_inizio,
                r_doc_onere.attivita_fine,
                d_onere_attivita.onere_att_code,
                d_onere_attivita.onere_att_desc,
                d_ord_stato.ord_stato_code
          from  siac_r_ordinativo r_ordinativo, siac_t_ordinativo t_ordinativo,
                siac_d_ordinativo_tipo d_ordinativo_tipo,
                siac_d_relaz_tipo d_relaz_tipo, siac_t_ordinativo_ts t_ord_ts,
                siac_t_ordinativo_ts_det t_ord_ts_det, siac_d_ordinativo_ts_det_tipo ts_det_tipo,
                siac_r_doc_onere_ordinativo_ts r_doc_onere_ord_ts,
                /* 11/10/2017: SIAC-5337 - 
                	aggiunte tabelle per poter testare lo stato della reversale. */
                siac_r_ordinativo_stato r_ord_stato,
                siac_d_ordinativo_stato d_ord_stato,
                siac_r_doc_onere r_doc_onere
                LEFT JOIN siac_d_somma_non_soggetta_tipo d_dom_non_sogg_tipo
                    	ON (d_dom_non_sogg_tipo.somma_non_soggetta_tipo_id=
                        	  r_doc_onere.somma_non_soggetta_tipo_id
                            AND d_dom_non_sogg_tipo.data_cancellazione IS NULL)
                LEFT JOIN siac_d_onere_attivita d_onere_attivita	
                		ON (d_onere_attivita.onere_att_id=
                        	  r_doc_onere.onere_att_id
                            AND d_onere_attivita.data_cancellazione IS NULL)
                /* 01/06/2017: aggiunta gestione delle causali 770 */                    
               LEFT JOIN (SELECT distinct r_onere_caus.onere_id,
               				r_doc_onere.doc_id,t_subdoc.subdoc_id,
               				COALESCE(d_causale.caus_code,'''') caus_code_770,
                            COALESCE(d_causale.caus_desc,'''') caus_desc_770
               			FROM siac_r_doc_onere r_doc_onere,
                        	siac_t_subdoc t_subdoc,
                        	siac_r_onere_causale r_onere_caus,
							siac_d_causale d_causale ,
							siac_d_modello d_modello                                                       
                    WHERE   t_subdoc.doc_id=r_doc_onere.doc_id                    	
                    	AND r_doc_onere.onere_id=r_onere_caus.onere_id
                        AND d_causale.caus_id=r_doc_onere.caus_id
                    	AND d_causale.caus_id=r_onere_caus.caus_id   
                    	AND d_modello.model_id=d_causale.model_id                                                      
                        AND d_modello.model_code=''01'' --Causale 770
                        AND r_doc_onere.ente_proprietario_id ='||p_ente_prop_id||'                     
                        AND r_onere_caus.validita_fine IS NULL                        
                        AND r_doc_onere.data_cancellazione IS NULL 
                        AND d_modello.data_cancellazione IS NULL 
                        AND d_causale.data_cancellazione IS NULL
                        AND t_subdoc.data_cancellazione IS NULL) caus_770
                    ON (caus_770.onere_id=r_doc_onere.onere_id
                    	AND caus_770.doc_id=r_doc_onere.doc_id),
                        --AND caus_770.subdoc_id=irpef.subdoc_id),
                siac_d_onere d_onere,
                siac_d_onere_tipo  d_onere_tipo
                where t_ordinativo.ord_id=r_ordinativo.ord_id_a
                    AND d_ordinativo_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id
                    AND r_ord_stato.ord_id=t_ordinativo.ord_id
                    AND r_ord_stato.ord_stato_id=d_ord_stato.ord_stato_id
                    AND d_relaz_tipo.relaz_tipo_id=r_ordinativo.relaz_tipo_id
                    AND t_ord_ts.ord_id=t_ordinativo.ord_id
                    AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
                    AND ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
                    AND r_doc_onere_ord_ts.ord_ts_id=t_ord_ts_det.ord_ts_id
                    AND r_doc_onere.doc_onere_id=r_doc_onere_ord_ts.doc_onere_id
                    AND d_onere.onere_id=r_doc_onere.onere_id
                      AND d_onere_tipo.onere_tipo_id=d_onere.onere_tipo_id
                     AND d_ordinativo_tipo.ord_tipo_code =''I''
                     AND ts_det_tipo.ord_ts_det_tipo_code=''A''
                        /* cerco tutte le tipologie di relazione,
                            non solo RIT_ORD */
               -- AND d_relaz_tipo.relaz_tipo_code=''RIT_ORD''
                  /* ord_id_da contiene l''ID del mandato
                     ord_id_a contiene l''ID della reversale */
                --AND r_ordinativo.ord_id_da = elencoMandati.ord_id
                AND d_onere_tipo.onere_tipo_code='''||p_tipo_ritenuta||'''';
                /* 11/10/2017: SIAC-5337 - escluse le reversali annullate */
                if p_escludi_annullate = true then
                	sql_query:=sql_query||' AND d_ord_stato.ord_stato_code <> ''A''';
                end if;
                sql_query:=sql_query||' AND d_relaz_tipo.data_cancellazione IS NULL
                AND t_ordinativo.data_cancellazione IS NULL
                AND r_ordinativo.data_cancellazione IS NULL
                AND r_ordinativo.data_cancellazione IS NULL
                AND t_ord_ts.data_cancellazione IS NULL
                AND t_ord_ts_det.data_cancellazione IS NULL
                AND ts_det_tipo.data_cancellazione IS NULL
                AND r_doc_onere_ord_ts.data_cancellazione IS NULL
                AND r_doc_onere.data_cancellazione IS NULL
                AND d_onere.data_cancellazione IS NULL
                AND d_onere_tipo.data_cancellazione IS NULL
                AND r_ord_stato.data_cancellazione IS NULL
                AND r_ord_stato.validita_fine IS NULL 
                AND d_ord_stato.data_cancellazione IS NULL
          ORDER BY r_ordinativo.ord_id_da';
raise notice 'Query: %', sql_query;
          
 for elencoReversali in     
 	execute sql_query                        
 loop
--raise notice 'Tipo rev=%, Importo rev=%, Imponibile=%' , elencoReversali.onere_tipo_code, elencoReversali.importo_ord, elencoReversali.importo_imponibile;          
             if ord_id is not null and 
            	ord_id <> elencoReversali.ord_id_da  THEN
                  return next;
                  conta_reversali:=0;
                  importo_reversale:=0;
                  codice_risc:='';
                  onere_code:='';
                  onere_tipo_code:='';
                  importo_imponibile:=0;
                  importo_imposta:=0;
                  importo_ritenuta:=0;
                  importo_ente:=0;
                  importo_ord:=0;
                  attivita_inizio:=NULL;
                  attivita_fine:=NULL;
                  attivita_code:='';
                  attivita_desc:='';
                  code_caus_770:='';
            	  desc_caus_770:='';
        		  code_caus_esenz:='';
        		  desc_caus_esenz:='';
                  stato_reversale:='';
                  num_reversale:=0;
                end if;
                
            ord_id:=elencoReversali.ord_id_da;
          
           --raise notice 'ord_id_da = % - r_doc_onere_id = % - carico_ente = % - importo_imponibile = % - importo_ord = %',
          -- elencoReversali.ord_id_da, elencoReversali.doc_onere_id,
          -- elencoReversali.importo_carico_ente, elencoReversali.importo_imponibile, elencoReversali.importo_ord;
            conta_reversali=conta_reversali+1;
            importo_reversale=importo_reversale+elencoReversali.importo_ord;
                          
            onere_code=COALESCE(elencoReversali.onere_code,'');
            onere_tipo_code=upper(elencoReversali.onere_tipo_code);           
            importo_imponibile = importo_imponibile+elencoReversali.importo_imponibile;
            importo_ente=importo_ente+elencoReversali.importo_carico_ente;                    
            importo_ritenuta = importo_ritenuta+elencoReversali.importo_ord;  
            importo_ord:=importo_ord+elencoReversali.importo_ord;
            attivita_inizio:=elencoReversali.attivita_inizio;
            attivita_fine:=elencoReversali.attivita_fine;
            attivita_code:=elencoReversali.onere_att_code;
            attivita_desc:=elencoReversali.onere_att_desc;
            
            code_caus_770:=COALESCE(elencoReversali.caus_code_770,'');
            desc_caus_770:=COALESCE(elencoReversali.caus_desc_770,'');
        	code_caus_esenz:=COALESCE(elencoReversali.somma_non_soggetta_tipo_code,'');
        	desc_caus_esenz:=COALESCE(elencoReversali.somma_non_soggetta_tipo_desc,'');
            stato_reversale:=elencoReversali.ord_stato_code;
            num_reversale:=elencoReversali.ord_numero;
            
             /* anche split/reverse e' una reversale, quindi qualunque tipo
                tipo di relazione concateno i risultati ottenuti 
                (possono essere piu' di 1) */              
              if codice_risc = '' THEN
                  codice_risc = elencoReversali.ord_numero ::VARCHAR;
              else
                  codice_risc = codice_risc||', '||elencoReversali.ord_numero ::VARCHAR;
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