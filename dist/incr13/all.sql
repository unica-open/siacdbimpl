/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-5373
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_soggetto_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_accertamento_from_soggetto_total (
  _uid_soggetto integer,
  _anno varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	select coalesce(count(*), 0)
	into total
	from
		siac_t_bil_elem a,
		siac_t_bil b2,
		siac_t_periodo c2,
		siac_r_movgest_bil_elem b,
		siac_t_movgest c,
		siac_d_movgest_tipo d,
		siac_t_movgest_ts e,
		siac_t_movgest_ts_det f,
		siac_d_movgest_ts_tipo g,
		siac_d_movgest_ts_det_tipo h,
		siac_r_movgest_ts_stato i,
		siac_d_movgest_stato l,
		siac_r_movgest_ts_sog m,
		siac_t_soggetto n,
		siac_r_movgest_class o,
		siac_t_class p,
		siac_d_class_tipo q,
		siac_t_bil r,
		siac_t_periodo s
	where a.bil_id=b2.bil_id
	and c2.periodo_id=b2.periodo_id 
	and c.movgest_id=b.movgest_id
	and b.elem_id=a.elem_id
	and d.movgest_tipo_id=c.movgest_tipo_id
	and e.movgest_id=c.movgest_id
	and f.movgest_ts_id=e.movgest_ts_id
	and g.movgest_ts_tipo_id=e.movgest_ts_tipo_id
	and h.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
	and i.movgest_ts_id=e.movgest_ts_id
	and l.movgest_stato_id=i.movgest_stato_id
	and m.movgest_ts_id=e.movgest_ts_id
	and n.soggetto_id=m.soggetto_id
	and o.movgest_ts_id=e.movgest_ts_id
	and p.classif_id=o.classif_id
	and q.classif_tipo_id=p.classif_tipo_id
	and r.bil_id = c.bil_id
	and s.periodo_id = r.periodo_id
	and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
	and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
	and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
	and now() BETWEEN o.validita_inizio and COALESCE(o.validita_fine,now())
	and m.data_cancellazione is null
	and b.data_cancellazione is null
	and c.data_cancellazione is null
	and d.data_cancellazione is null
	and e.data_cancellazione is null
	and f.data_cancellazione is null
	and g.data_cancellazione is null
	and h.data_cancellazione is null
	and i.data_cancellazione is null
	and l.data_cancellazione is null
	and m.data_cancellazione is null
	and n.data_cancellazione is null
	and o.data_cancellazione is null
	and p.data_cancellazione is null
	and q.data_cancellazione is null
	and r.data_cancellazione is null
	and s.data_cancellazione is null	
	and q.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')	
	and d.movgest_tipo_code='A'
	and g.movgest_ts_tipo_code='T'
	and h.movgest_ts_det_tipo_code='A'
	and n.soggetto_id=_uid_soggetto
	and s.anno = _anno;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_provvedimento_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_accertamento_from_provvedimento_total (
  _uid_provvedimento integer,
  _anno varchar
)
RETURNS bigint AS
$body$
DECLARE
	total BIGINT;
BEGIN
			
	SELECT COALESCE(COUNT(*),0) INTO total
	FROM siac_t_atto_amm a,
		siac_d_atto_amm_tipo b,
		siac_r_atto_amm_stato c,
		siac_d_atto_amm_stato d,
		siac_r_movgest_ts_atto_amm e,
		siac_t_movgest_ts f,
		siac_t_movgest g,
		siac_d_movgest_tipo h,
		siac_d_movgest_ts_tipo i,
		siac_r_movgest_ts_stato l,
		siac_d_movgest_stato m,
		siac_t_movgest_ts_det n,
		siac_d_movgest_ts_det_tipo o,
		siac_r_movgest_class p,
		siac_t_class q,
		siac_d_class_tipo r,
		siac_t_bil s,
		siac_t_periodo t
	WHERE b.attoamm_tipo_id=a.attoamm_tipo_id
	AND c.attoamm_id=a.attoamm_id
	AND d.attoamm_stato_id=c.attoamm_stato_id
	AND e.attoamm_id=a.attoamm_id
	AND f.movgest_ts_id=e.movgest_ts_id
	AND g.movgest_id=f.movgest_id
	AND h.movgest_tipo_id=g.movgest_tipo_id
	AND i.movgest_ts_tipo_id=f.movgest_ts_tipo_id
	AND l.movgest_ts_id=f.movgest_ts_id
	AND l.movgest_stato_id=m.movgest_stato_id
	AND n.movgest_ts_id=f.movgest_ts_id
	AND o.movgest_ts_det_tipo_id=n.movgest_ts_det_tipo_id
	AND p.movgest_ts_id = f.movgest_ts_id
	AND q.classif_id = p.classif_id
	AND r.classif_tipo_id = q.classif_tipo_id
	AND s.bil_id = g.bil_id
	AND t.periodo_id = s.periodo_id
	AND now() BETWEEN c.validita_inizio AND COALESCE(c.validita_fine,now())
	AND now() BETWEEN e.validita_inizio AND COALESCE(e.validita_fine,now())
	AND now() BETWEEN l.validita_inizio AND COALESCE(l.validita_fine,now())
	AND now() BETWEEN p.validita_inizio AND COALESCE(p.validita_fine,now())
	AND s.data_cancellazione IS NULL
	AND t.data_cancellazione IS NULL
	AND a.data_cancellazione IS NULL
	AND b.data_cancellazione IS NULL
	AND c.data_cancellazione IS NULL
	AND d.data_cancellazione IS NULL
	AND e.data_cancellazione IS NULL
	AND f.data_cancellazione IS NULL
	AND g.data_cancellazione IS NULL
	AND h.data_cancellazione IS NULL
	AND i.data_cancellazione IS NULL
	AND l.data_cancellazione IS NULL
	AND m.data_cancellazione IS NULL
	AND n.data_cancellazione IS NULL
	AND o.data_cancellazione IS NULL
	AND p.data_cancellazione is null
	AND q.data_cancellazione is null
	AND r.data_cancellazione is null
	AND s.data_cancellazione is null
	AND r.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
	AND h.movgest_tipo_code='A'
	AND i.movgest_ts_tipo_code='T'
	AND o.movgest_ts_det_tipo_code='A'
	AND a.attoamm_id=_uid_provvedimento
	AND t.anno = _anno;
	
	RETURN total;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata_total (
  _uid_capitoloentrata integer,
  _anno varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT coalesce(count(*),0) into total
	from
		siac_t_bil_elem a,
		siac_t_bil b2,
		siac_t_periodo c2,
		siac_r_movgest_bil_elem b,
		siac_t_movgest c,
		siac_d_movgest_tipo d,
		siac_t_movgest_ts e,
		siac_t_movgest_ts_det f,
		siac_d_movgest_ts_tipo g,
		siac_d_movgest_ts_det_tipo h,
		siac_r_movgest_ts_stato i,
		siac_d_movgest_stato l,
		siac_r_movgest_class m,
		siac_t_class n,
		siac_d_class_tipo o,
		siac_t_bil p,
		siac_t_periodo q
	where a.bil_id=b2.bil_id
	and c2.periodo_id=b2.periodo_id
	and c.movgest_id=b.movgest_id
	and b.elem_id=a.elem_id
	and d.movgest_tipo_id=c.movgest_tipo_id
	and e.movgest_id=c.movgest_id
	and f.movgest_ts_id=e.movgest_ts_id
	and g.movgest_ts_tipo_id=e.movgest_ts_tipo_id
	and h.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
	and i.movgest_ts_id=e.movgest_ts_id
	and m.movgest_ts_id = e.movgest_ts_id
	and n.classif_id = m.classif_id
	and o.classif_tipo_id = n.classif_tipo_id
	and l.movgest_stato_id=i.movgest_stato_id
	and p.bil_id = c.bil_id
	and q.periodo_id = p.periodo_id
	and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
	and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
	and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
	and b.data_cancellazione is null
	and c.data_cancellazione is null
	and d.data_cancellazione is null
	and e.data_cancellazione is null
	and f.data_cancellazione is null
	and g.data_cancellazione is null
	and h.data_cancellazione is null
	and i.data_cancellazione is null
	and l.data_cancellazione is null
	and m.data_cancellazione is null
	and n.data_cancellazione is null
	and o.data_cancellazione is null
	and p.data_cancellazione is null
	and q.data_cancellazione is null
	and d.movgest_tipo_code='A'
	and g.movgest_ts_tipo_code='T'
	and h.movgest_ts_det_tipo_code='A'
	and o.classif_tipo_code IN ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
	and a.elem_id=_uid_capitoloentrata
	and q.anno = _anno;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
-- FINE SIAC-5373


--SIAC-5337 INIZIO - Maurizio

DROP FUNCTION  IF EXISTS siac.fnc_bilr104_tab_reversali(p_ente_prop_id integer, p_tipo_ritenuta varchar);
DROP FUNCTION  IF EXISTS siac.fnc_bilr104_tab_reversali(p_ente_prop_id integer, p_tipo_ritenuta varchar, p_escludi_annullate boolean);

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


DROP FUNCTION  IF EXISTS siac."BILR104_stampa_ritenute"(p_ente_prop_id integer, p_anno varchar, p_data_mandato_da date, p_data_mandato_a date, p_data_trasm_da date, p_data_trasm_a date, p_tipo_ritenuta varchar, p_data_quietanza_da date, p_data_quietanza_a date);

CREATE OR REPLACE FUNCTION siac."BILR104_stampa_ritenute" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_mandato_da date,
  p_data_mandato_a date,
  p_data_trasm_da date,
  p_data_trasm_a date,
  p_tipo_ritenuta varchar,
  p_data_quietanza_da date,
  p_data_quietanza_a date
)
RETURNS TABLE (
  nome_ente varchar,
  partita_iva_ente varchar,
  anno_ese_finanz integer,
  anno_mandato integer,
  numero_mandato integer,
  data_mandato date,
  desc_mandato varchar,
  benef_codice varchar,
  benef_cod_fiscale varchar,
  benef_partita_iva varchar,
  benef_nome varchar,
  stato_mandato varchar,
  importo_lordo_mandato numeric,
  tipo_ritenuta_irpef varchar,
  codice_tributo_irpef varchar,
  importo_ritenuta_irpef numeric,
  importo_netto_irpef numeric,
  importo_imponibile_irpef numeric,
  codice_risc varchar,
  tipo_ritenuta_inps varchar,
  codice_tributo_inps varchar,
  importo_ritenuta_inps numeric,
  importo_netto_inps numeric,
  importo_imponibile_inps numeric,
  importo_ente_inps numeric,
  tipo_ritenuta_irap varchar,
  importo_ritenuta_irap numeric,
  importo_netto_irap numeric,
  importo_imponibile_irap numeric,
  codice_ritenuta_irap varchar,
  desc_ritenuta_irap varchar,
  importo_ente_irap numeric,
  display_error varchar,
  tipo_ritenuta_irpeg varchar,
  codice_tributo_irpeg varchar,
  importo_ritenuta_irpeg numeric,
  importo_netto_irpeg numeric,
  importo_imponibile_irpeg numeric,
  codice_ritenuta_irpeg varchar,
  desc_ritenuta_irpeg varchar,
  importo_ente_irpeg numeric,
  code_caus_770 varchar,
  desc_caus_770 varchar,
  code_caus_esenz varchar,
  desc_caus_esenz varchar,
  attivita_inizio date,
  attivita_fine date,
  attivita_code varchar,
  attivita_desc varchar
) AS
$body$
DECLARE
elencoMandati record;
elencoOneri	record;
elencoReversali record;


DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
importoSubDoc NUMERIC;
imponibileInpsApp NUMERIC;
impostaInpsApp	NUMERIC;
enteInpsApp NUMERIC;
imponibileIrpefApp NUMERIC;
impostaIrpefApp	NUMERIC;
imponibileIrapApp NUMERIC;
impostaIrapApp	NUMERIC;
contaQuotaIrap integer;
importoParzIrapImpon NUMERIC;
importoParzIrapNetto NUMERIC;
importoParzIrapRiten NUMERIC;
importoParzIrapEnte NUMERIC;

contaQuotaIrpef integer;
importoParzIrpefImpon NUMERIC;
importoParzIrpefNetto NUMERIC;
importoParzIrpefRiten NUMERIC;
importoParzIrpefEnte NUMERIC;
importoTotDaDedurreFattura NUMERIC;

percQuota NUMERIC;
idFatturaOld INTEGER;
numeroQuoteFattura INTEGER;
numeroParametriData Integer;
docIdApp integer;

ente_denominazione VARCHAR;
cod_fisc_ente VARCHAR;
bilancio_id  INTEGER;
miaQuery VARCHAR;

BEGIN

nome_ente='';
partita_iva_ente='';
anno_ese_finanz=0;
anno_mandato=0;
numero_mandato=0;
data_mandato=NULL;
desc_mandato='';
benef_cod_fiscale='';
benef_partita_iva='';
benef_nome='';
stato_mandato='';

codice_risc='';
importo_lordo_mandato=0;
importo_netto_irpef=0;
importo_imponibile_irpef=0;
importo_ritenuta_irpef=0;
importo_netto_inps=0;
importo_imponibile_inps=0;
importo_ritenuta_inps=0;
importo_netto_irap=0;
importo_imponibile_irap=0;
importo_ritenuta_irap=0;

tipo_ritenuta_inps='';
tipo_ritenuta_irpef='';
tipo_ritenuta_irap='';

codice_tributo_irpef='';
codice_tributo_inps='';

codice_ritenuta_irap='';
desc_ritenuta_irap='';
benef_codice='';
importo_ente_irap=0;
importo_ente_inps=0;
code_caus_770:='';
desc_caus_770:='';
code_caus_esenz:='';
desc_caus_esenz:='';
attivita_inizio:=NULL;
attivita_fine:=NULL;
attivita_code:='';
attivita_desc:='';

tipo_ritenuta_irpeg='';
codice_tributo_irpeg='';
importo_ritenuta_irpeg=0;
importo_netto_irpeg=0;
importo_imponibile_irpeg=0;
codice_ritenuta_irpeg='';
desc_ritenuta_irpeg='';
importo_ente_irpeg=0;
numeroParametriData=0;


display_error='';
/*
if p_data_trasm_da IS NULL AND p_data_trasm_a IS NULL AND p_data_mandato_da IS NULL AND
	p_data_mandato_a IS NULL AND p_data_quietanza_da IS NULL AND p_data_quietanza_a IS NULL THEN
	display_error='OCCORRE SPECIFICARE UNO TRA GLI INTERVALLI "DATA MANDATO DA/A",  "DATA TRASMISSIONE DA/A" E "DATA QUIETANZA DA/A".';
    return next;
    return;
end if;


if p_data_trasm_da IS NOT NULL AND p_data_trasm_a IS NOT NULL 
	AND p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL THEN
	display_error='OCCORRE SPECIFICARE UNO SOLO DEI TRE INTERVALLI DI DATA "DATA MANDATO DA/A", "DATA TRASMISSIONE DA/A" E "DATA QUIETANZA DA/A".';
    return next;
    return;
end if;*/

if (p_data_trasm_da IS NOT NULL OR p_data_trasm_a IS NOT NULL) THEN
	numeroParametriData=numeroParametriData+1;
end if;
if (p_data_mandato_da IS NOT NULL OR p_data_mandato_a IS NOT NULL) THEN
	numeroParametriData=numeroParametriData+1;
end if;
if (p_data_quietanza_da IS NOT NULL OR p_data_quietanza_a IS NOT NULL) THEN
	numeroParametriData=numeroParametriData+1;
end if;

if numeroParametriData = 0 THEN
	display_error='OCCORRE SPECIFICARE UNO TRA GLI INTERVALLI "DATA MANDATO DA/A",  "DATA TRASMISSIONE DA/A" E "DATA QUIETANZA DA/A".';
    return next;
    return;
end if;

if numeroParametriData>=2 THEN
	display_error='OCCORRE SPECIFICARE UNO SOLO DEI TRE INTERVALLI DI DATA "DATA MANDATO DA/A", "DATA TRASMISSIONE DA/A" E "DATA QUIETANZA DA/A".';
    return next;
    return;
end if;

if (p_data_trasm_da IS NULL AND p_data_trasm_a IS NOT NULL) OR 
	(p_data_trasm_da IS NOT NULL AND p_data_trasm_a IS  NULL) THEN
	display_error='OCCORRE SPECIFICARE ENTRAMBE LE DATE "DATA TRASMISSIONE DA/A".';
    return next;
    return;
end if;

if (p_data_mandato_da IS NULL AND p_data_mandato_a IS NOT NULL) OR 
	(p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS  NULL) THEN
	display_error='OCCORRE SPECIFICARE ENTRAMBE LE DATE "DATA MANDATO DA/A".';
    return next;
    return;
end if;

if (p_data_quietanza_da IS NULL AND p_data_quietanza_a IS NOT NULL) OR 
	(p_data_quietanza_da IS NOT NULL AND p_data_quietanza_a IS  NULL) THEN
	display_error='OCCORRE SPECIFICARE ENTRAMBE LE DATE "DATA QUIETANZA DA/A".';
    return next;
    return;
end if;

RTN_MESSAGGIO:='Estrazione dei dati dei mandati ''.';
raise notice 'Estrazione dei dati dei mandati ';
raise notice 'ora: % ',clock_timestamp()::varchar;

    	/* 11/10/2016: cerco i mandati di tutte le ritenute tranne l'IRAP che 
        	deve essere estratta in modo diverso */
/* 30/05/2017: L'IRPEF deve essere gestita in modo simile all'IRAP in quanto 
	e' necessario calcolare il dato della ritenuta proporzionandola con la
    percentuale calcolata delle relativie quote della fattura */
--if p_tipo_ritenuta <> 'IRAP' THEN
if p_tipo_ritenuta in ('INPS','IRPEG') THEN

select a.ente_denominazione, a.codice_fiscale
into  ente_denominazione, cod_fisc_ente
from  siac_t_ente_proprietario a
where a.ente_proprietario_id = p_ente_prop_id;
    
select a.bil_id 
into bilancio_id 
from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id 
and b.periodo_id = a.periodo_id
and b.anno = p_anno;

/* 07/09/2017: rivista la modalita' di estrazione dei dati INPS e IRPEG per velocizzare 
    la procedura.
    In particolare e' stata creata la function fnc_bilr104_tab_reversali per estrarre
    tutte le reversali per mandato in modo da estrarre tutte le informazioni in un
    colpo solo senza dover cercare le reversali nel ciclo per ogni mandato. 
    Corretto anche un problema relativo ai casi in cui un mandato ha piu' reversali 
    collegate, fatto in modo di sommare gli importi IMPONIBILE, ENTE e RITENUTA ma
    solo se la reversale collegata ha un onere del tipo richiesto (INPS o IRPEG). */

miaQuery ='
with ordinativo as (
    select t_ordinativo.ord_anno,
           t_ordinativo.ord_desc, 
           t_ordinativo.ord_numero,
           t_ordinativo.ord_emissione_data,        
           t_ord_ts_det.ord_ts_det_importo,
           d_ord_stato.ord_stato_code,
           t_ordinativo.ord_id,
           t_ord_ts_det.ord_ts_id
    from  siac_t_ordinativo t_ordinativo,
          siac_t_ordinativo_ts t_ord_ts,
          siac_t_ordinativo_ts_det t_ord_ts_det,
          siac_d_ordinativo_ts_det_tipo d_ts_det_tipo,
          siac_r_ordinativo_stato r_ord_stato,
          siac_d_ordinativo_stato d_ord_stato,
          siac_d_ordinativo_tipo  d_ord_tipo
    where t_ordinativo.ente_proprietario_id = ' ||p_ente_prop_id||'
    and   t_ordinativo.bil_id =  '||bilancio_id ||'    
    and   d_ts_det_tipo.ord_ts_det_tipo_code = ''A''            
    and   d_ord_stato.ord_stato_code <> ''A''
    and   d_ord_tipo.ord_tipo_code = ''P''
    and   r_ord_stato.validita_fine is null 
    and   t_ordinativo.ord_id = t_ord_ts.ord_id
    and   t_ord_ts.ord_ts_id = t_ord_ts_det.ord_ts_id
    and   t_ord_ts_det.ord_ts_det_tipo_id = d_ts_det_tipo.ord_ts_det_tipo_id
    and   t_ordinativo.ord_id = r_ord_stato.ord_id
    and   r_ord_stato.ord_stato_id = d_ord_stato.ord_stato_id
    and   t_ordinativo.ord_tipo_id = d_ord_tipo.ord_tipo_id ';
	if p_data_mandato_da is not null and p_data_mandato_a is not null THEN
		miaQuery=miaQuery||' and to_timestamp(to_char(t_ordinativo.ord_emissione_data,''dd/MM/yyyy''),''dd/MM/yyyy'') between '''||p_data_mandato_da ||''' and '''||p_data_mandato_a||'''';
	elsif p_data_trasm_da is not null and p_data_trasm_a is not null THEN 
		miaQuery=miaQuery||' and to_timestamp(to_char(t_ordinativo.ord_trasm_oil_data,''dd/MM/yyyy''),''dd/MM/yyyy'') between '''||p_data_trasm_da || ''' and '''||p_data_trasm_a||'''';
	end if;
    
    miaQuery=miaQuery||' 
    and   t_ordinativo.data_cancellazione is null
    and   t_ord_ts.data_cancellazione is null
    and   t_ord_ts_det.data_cancellazione is null
    and   d_ts_det_tipo.data_cancellazione is null
    and   r_ord_stato.data_cancellazione is null
    and   d_ord_stato.data_cancellazione is null
    and   d_ord_tipo.data_cancellazione is null
    )
    , capitolo as (
    select t_bil_elem.elem_code, 
           t_bil_elem.elem_code2,
           r_ordinativo_bil_elem.ord_id,
           t_bil_elem.elem_id       
    from   siac_r_ordinativo_bil_elem r_ordinativo_bil_elem, 
           siac_t_bil_elem t_bil_elem
    where  r_ordinativo_bil_elem.elem_id = t_bil_elem.elem_id
    and    r_ordinativo_bil_elem.ente_proprietario_id = '||p_ente_prop_id||'
    and    r_ordinativo_bil_elem.data_cancellazione is null
    and    t_bil_elem.data_cancellazione is null     
    )
    , movimento as (
    select distinct t_movgest.movgest_anno,
           r_liq_ord.sord_id
    from  siac_r_liquidazione_ord r_liq_ord,
          siac_r_liquidazione_movgest r_liq_movgest,
          siac_t_movgest t_movgest,
          siac_t_movgest_ts t_movgest_ts
    where r_liq_ord.liq_id = r_liq_movgest.liq_id
    and   r_liq_movgest.movgest_ts_id = t_movgest_ts.movgest_ts_id
    and   t_movgest_ts.movgest_id = t_movgest.movgest_id
    and   t_movgest.ente_proprietario_id = '||p_ente_prop_id||'
    and   r_liq_ord.data_cancellazione is null
    and   r_liq_movgest.data_cancellazione is null
    and   t_movgest.data_cancellazione is null
    and   t_movgest_ts.data_cancellazione is null
    )
    , soggetto as (
    select t_soggetto.soggetto_code, 
           t_soggetto.soggetto_desc,  
           t_soggetto.partita_iva,
           t_soggetto.codice_fiscale,
           r_ord_soggetto.ord_id
    from   siac_r_ordinativo_soggetto r_ord_soggetto,
           siac_t_soggetto t_soggetto
    where  r_ord_soggetto.soggetto_id = t_soggetto.soggetto_id
    and    t_soggetto.ente_proprietario_id = '||p_ente_prop_id||'
    and    r_ord_soggetto.data_cancellazione is null  
    and    t_soggetto.data_cancellazione is null
    )
    , reversali as (select * from "fnc_bilr104_tab_reversali"('||p_ente_prop_id||','''||p_tipo_ritenuta||''',true))
    select '''||ente_denominazione||''' ente_denominazione, '''||
           cod_fisc_ente||''' cod_fisc_ente, '''||
           p_anno||''' anno_eser,
           ordinativo.ord_anno,
           ordinativo.ord_desc, 
           ordinativo.ord_numero,
           ordinativo.ord_emissione_data,        
           -- ordinativo.ord_ts_det_importo,
           SUM(ordinativo.ord_ts_det_importo) IMPORTO_TOTALE,
           ordinativo.ord_stato_code,
           ordinativo.ord_id,
           capitolo.elem_code cod_cap, 
           capitolo.elem_code2 cod_art,
           capitolo.elem_id,
           movimento.movgest_anno anno_impegno,
           soggetto.soggetto_code, 
           soggetto.soggetto_desc,  
           soggetto.partita_iva,
           soggetto.codice_fiscale,
           reversali.*
    from  ordinativo         
    inner join capitolo  on ordinativo.ord_id = capitolo.ord_id
    inner join movimento on ordinativo.ord_ts_id = movimento.sord_id
    inner join soggetto  on ordinativo.ord_id = soggetto.ord_id
    inner join reversali  on ordinativo.ord_id = reversali.ord_id
    left  join siac_r_ordinativo_quietanza r_ord_quietanza  
    	ON (ordinativo.ord_id = r_ord_quietanza.ord_id 
            and r_ord_quietanza.data_cancellazione is null 
            -- 10/10/2017: aggiunto test sulla data di fine validita'' 
            -- per prendere la quietanza corretta.
            and r_ord_quietanza.validita_fine is null )
	where reversali.onere_tipo_code='''||p_tipo_ritenuta||'''';
    if p_data_quietanza_da is not null and p_data_quietanza_a is not null THEN
		miaQuery=miaQuery||' 
		and to_timestamp(to_char(r_ord_quietanza.ord_quietanza_data,''dd/MM/yyyy''),''dd/MM/yyyy'') 
        	between ''' ||p_data_quietanza_da ||''' and ''' ||p_data_quietanza_a||'''';
    end if;
	miaQuery=miaQuery||' 
    group by ente_denominazione, cod_fisc_ente, anno_eser,
             ordinativo.ord_anno,
             ordinativo.ord_desc, 
             ordinativo.ord_numero,
             ordinativo.ord_emissione_data,
             ordinativo.ord_stato_code,
             ordinativo.ord_id,
             capitolo.elem_code, 
             capitolo.elem_code2,
             capitolo.elem_id,  
             movimento.movgest_anno,
             soggetto.soggetto_code, 
             soggetto.soggetto_desc,  
             soggetto.partita_iva,
             soggetto.codice_fiscale,
             reversali.ord_id,      
             reversali.conta_reversali,  
             reversali.codice_risc,  
             reversali.onere_code,  
             reversali.onere_tipo_code,  
             reversali.importo_imponibile,  
             reversali.importo_ente,  
             reversali.importo_imposta,  
             reversali.importo_ritenuta,  
             --reversali.importo_netto,  
             reversali.importo_reversale,  
             reversali.importo_ord,  
             reversali.attivita_inizio,  
             reversali.attivita_fine,  
             reversali.attivita_code,  
             reversali.attivita_desc,
             reversali.code_caus_770,
			 reversali.desc_caus_770,
			 reversali.code_caus_esenz,
			 reversali.desc_caus_esenz,
             reversali.stato_reversale ,
             reversali.num_reversale  
    order by ordinativo.ord_numero, ordinativo.ord_emissione_data ';
raise notice 'miaQuery = %', miaQuery;


  for 
  	elencoMandati in execute miaQuery    
          
  loop

      importo_lordo_mandato= COALESCE(elencoMandati.IMPORTO_TOTALE,0);

      codice_risc:=elencoMandati.codice_risc;
      if upper(elencoMandati.onere_tipo_code) = 'INPS' THEN
        codice_tributo_inps=COALESCE(elencoMandati.onere_code,'');
        tipo_ritenuta_inps=upper(elencoMandati.onere_tipo_code);        
        importo_imponibile_inps = elencoMandati.importo_imponibile;
        --raise notice 'ord_id = % - IMPON = %', elencoMandati.ord_id, elencoMandati.importo_imponibile;
        importo_ente_inps=elencoMandati.importo_ente;                   
        importo_ritenuta_inps = elencoMandati.importo_ord;    
        importo_netto_inps=importo_lordo_mandato-elencoMandati.importo_ritenuta;-- elencoMandati.importo_netto;-- importo_lordo_mandato-importo_ritenuta_inps;
        attivita_inizio:=elencoMandati.attivita_inizio;
        attivita_fine:=elencoMandati.attivita_fine;
        attivita_code:=elencoMandati.attivita_code;
        attivita_desc:=elencoMandati.attivita_desc;
      elsif upper(elencoMandati.onere_tipo_code) = 'IRPEG' THEN

        codice_tributo_irpeg=COALESCE(elencoMandati.onere_code,'');
        tipo_ritenuta_irpeg=upper(elencoMandati.onere_tipo_code);    		
        importo_imponibile_irpeg = elencoMandati.importo_imponibile;
        importo_ritenuta_irpeg = elencoMandati.importo_ord;    
                                        
        importo_netto_irpeg=importo_lordo_mandato-elencoMandati.importo_ritenuta;  
        code_caus_770:=COALESCE(elencoMandati.code_caus_770,'');
        desc_caus_770:=COALESCE(elencoMandati.desc_caus_770,'');
        code_caus_esenz:=COALESCE(elencoMandati.code_caus_esenz,'');
        desc_caus_esenz:=COALESCE(elencoMandati.desc_caus_esenz,'');
      end if; 
      
        /* 07/09/2017: restituisco solo i dati relativi alla ritenuta richiesta */
       if (p_tipo_ritenuta='INPS' AND tipo_ritenuta_inps <> '') OR
               (p_tipo_ritenuta='IRPEG' AND tipo_ritenuta_irpeg <> '') THEN
            stato_mandato= elencoMandati.ord_stato_code;

            nome_ente=elencoMandati.ente_denominazione;
            partita_iva_ente=elencoMandati.cod_fisc_ente;
            anno_ese_finanz=elencoMandati.anno_eser;
            desc_mandato=COALESCE(elencoMandati.ord_desc,'');

            anno_mandato=elencoMandati.ord_anno;
            numero_mandato=elencoMandati.ord_numero;
            data_mandato=elencoMandati.ord_emissione_data;
            benef_cod_fiscale=COALESCE(elencoMandati.codice_fiscale,'');
            benef_partita_iva=COALESCE(elencoMandati.partita_iva,'');
            benef_nome=COALESCE(elencoMandati.soggetto_desc,'');
            benef_codice=COALESCE(elencoMandati.soggetto_code,'');
            
            return next;
         end if;
     
  nome_ente='';
  partita_iva_ente='';
  anno_ese_finanz=0;
  anno_mandato=0;
  numero_mandato=0;
  data_mandato=NULL;
  desc_mandato='';
  benef_cod_fiscale='';
  benef_partita_iva='';
  benef_nome='';
  stato_mandato='';
  codice_tributo_irpef='';
  codice_tributo_inps='';
  codice_risc='';
  importo_lordo_mandato=0;
  importo_netto_irpef=0;
  importo_imponibile_irpef=0;
  importo_ritenuta_irpef=0;
  importo_netto_inps=0;
  importo_imponibile_inps=0;
  importo_ritenuta_inps=0;
  importo_netto_irap=0;
  importo_imponibile_irap=0;
  importo_ritenuta_irap=0;
  tipo_ritenuta_inps='';
  tipo_ritenuta_irpef='';
  tipo_ritenuta_irap='';
  codice_ritenuta_irap='';
  desc_ritenuta_irap='';
  benef_codice='';
  importo_ente_irap=0;
  importo_ente_inps=0;

  tipo_ritenuta_irpeg='';
  codice_tributo_irpeg='';
  importo_ritenuta_irpeg=0;
  importo_netto_irpeg=0;
  importo_imponibile_irpeg=0;
  codice_ritenuta_irpeg='';
  desc_ritenuta_irpeg='';
  importo_ente_irpeg=0;
  code_caus_770:='';
  desc_caus_770:='';
  code_caus_esenz:='';
  desc_caus_esenz:='';
  attivita_inizio:=NULL;
  attivita_fine:=NULL;
  attivita_code:='';
  attivita_desc:='';
  
end loop;

	/* 11/10/2016: e' stata richiesta IRAP, estraggo solo i dati relativi */
elsif p_tipo_ritenuta = 'IRAP' THEN
	idFatturaOld=0;
	contaQuotaIrap=0;
    importoParzIrapImpon =0;
    importoParzIrapNetto =0;
    importoParzIrapRiten =0;
    importoParzIrapEnte =0;
    
    	/* 11/10/2016: la query deve estrarre insieme mandati e dati IRAP e
        	ordinare i dati per id fattura (doc_id) perche' ci sono
            fatture che sono legate a differenti mandati.
            In questo caso e' necessario riproporzionare l'importo
            dell'aliquota a seconda della percentuale della quota fattura
            relativa al mandato rispetto al totale fattura */    
	/* 16/10/2017: ottimizzata e resa dinamica la query */              
 miaQuery:='WITH irap as
		(SELECT d_onere_tipo.onere_tipo_code, d_onere_tipo.onere_tipo_desc,
            d_onere.onere_code, d_onere.onere_desc, t_ordinativo_ts.ord_id,
            t_subdoc.subdoc_id,t_doc.doc_id,
              t_doc.doc_importo IMPORTO_FATTURA,
              t_subdoc.subdoc_importo IMPORTO_QUOTA,
              t_subdoc.subdoc_importo_da_dedurre IMP_DEDURRE,
              sum(r_doc_onere.importo_imponibile) IMPORTO_IMPONIBILE,
              sum(r_doc_onere.importo_carico_soggetto) IMPOSTA,
              sum(r_doc_onere.importo_carico_ente) IMPORTO_CARICO_ENTE
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
               -- AND t_ordinativo_ts.ord_id=mandati.ord_id
                AND t_ordinativo_ts.ente_proprietario_id = '||p_ente_prop_id||'
                AND upper(d_onere_tipo.onere_tipo_code) in(''IRAP'')
                AND t_doc.data_cancellazione IS NULL
                AND t_subdoc.data_cancellazione IS NULL
                AND r_doc_onere.data_cancellazione IS NULL
                AND d_onere.data_cancellazione IS NULL
                AND d_onere_tipo.data_cancellazione IS NULL
                AND t_ordinativo_ts.data_cancellazione IS NULL
                AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL
                GROUP BY d_onere_tipo.onere_tipo_code, d_onere_tipo.onere_tipo_desc,
                	t_ordinativo_ts.ord_id, t_subdoc.subdoc_id,
                    t_doc.doc_id,
                    d_onere.onere_code, d_onere.onere_desc,
                     t_doc.doc_importo, t_subdoc.subdoc_importo , 
                     t_subdoc.subdoc_importo_da_dedurre) ,
     mandati as  (select ep.ente_denominazione, ep.codice_fiscale cod_fisc_ente, 
            t_periodo.anno anno_eser, t_ordinativo.ord_anno,
             t_ordinativo.ord_desc, t_ordinativo.ord_id,
            t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,     
            t_soggetto.soggetto_code, t_soggetto.soggetto_desc,  
            t_soggetto.partita_iva,t_soggetto.codice_fiscale,
            t_bil_elem.elem_code cod_cap, t_bil_elem.elem_code2 cod_art,
            t_bil_elem.elem_id, d_ord_stato.ord_stato_code, 
            SUM(t_ord_ts_det.ord_ts_det_importo) IMPORTO_TOTALE,
            t_movgest.movgest_anno anno_impegno
            FROM  	siac_t_ente_proprietario ep,
                    siac_t_bil t_bil,
                    siac_t_periodo t_periodo,
                    siac_r_ordinativo_bil_elem r_ordinativo_bil_elem,
                    siac_t_bil_elem t_bil_elem,                  
                    siac_t_ordinativo t_ordinativo
                  --09/02/2017: aggiunta la tabella della quietanza per testare
                  -- la data quietanza se specificata in input.
                  	LEFT JOIN siac_r_ordinativo_quietanza r_ord_quietanza
                   	on (r_ord_quietanza.ord_id=t_ordinativo.ord_id
                       	and r_ord_quietanza.data_cancellazione IS NULL
                        -- 10/10/2017: aggiunto test sulla data di fine validita'' 
            			-- per prendere la quietanza corretta.
            			and r_ord_quietanza.validita_fine is null ),  
                    siac_t_ordinativo_ts t_ord_ts,
                    siac_r_liquidazione_ord r_liq_ord,
                    siac_r_liquidazione_movgest r_liq_movgest,
                    siac_t_movgest t_movgest,
                    siac_t_movgest_ts t_movgest_ts,
                    siac_t_ordinativo_ts_det t_ord_ts_det,
                    siac_d_ordinativo_ts_det_tipo d_ts_det_tipo,
                    siac_r_ordinativo_stato r_ord_stato,  
                    siac_d_ordinativo_stato d_ord_stato ,
                     siac_d_ordinativo_tipo d_ord_tipo,
                     siac_r_ordinativo_soggetto r_ord_soggetto ,
                     siac_t_soggetto t_soggetto  		    	
            WHERE  t_ordinativo.ente_proprietario_id=ep.ente_proprietario_id        	
                AND r_ordinativo_bil_elem.elem_id=t_bil_elem.elem_id            
                AND  r_ordinativo_bil_elem.ord_id=t_ordinativo.ord_id                    
               AND t_ordinativo.ord_id=r_ord_stato.ord_id
               AND t_bil.bil_id=t_ordinativo.bil_id
               AND t_periodo.periodo_id=t_bil.periodo_id
               AND t_ord_ts.ord_id=t_ordinativo.ord_id           
               AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
               AND d_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
               AND d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
               AND d_ord_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id 
               AND t_soggetto.soggetto_id=r_ord_soggetto.soggetto_id
               AND r_ord_soggetto.ord_id=t_ordinativo.ord_id
               AND r_liq_ord.sord_id= t_ord_ts.ord_ts_id
               AND r_liq_movgest.liq_id=r_liq_ord.liq_id
               AND t_movgest_ts.movgest_ts_id=r_liq_movgest.movgest_ts_id
               AND t_movgest_ts.movgest_id=t_movgest.movgest_id '; 
               -- inizio INC000001342288      
			   if p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL THEN
                   miaQuery:=miaQuery||' AND (to_timestamp(to_char(t_ordinativo.ord_emissione_data,''dd/MM/yyyy''),''dd/MM/yyyy'')                                                
                      between '''||p_data_mandato_da||''' AND '''||p_data_mandato_a||''') ';
               end if;
               if p_data_trasm_da IS NOT NULL AND p_data_trasm_a IS NOT NULL THEN
                  miaQuery:=miaQuery||' AND (to_timestamp(to_char(t_ordinativo.ord_trasm_oil_data,''dd/MM/yyyy''),''dd/MM/yyyy'') 
                      between '''||p_data_trasm_da ||''' AND '''||p_data_trasm_a||''') ';
               end if;
               if p_data_quietanza_da IS NOT NULL AND p_data_quietanza_a IS NOT NULL THEN
                   miaQuery:=miaQuery||' AND (to_timestamp(to_char(r_ord_quietanza.ord_quietanza_data,''dd/MM/yyyy''),''dd/MM/yyyy'') 
                      between '''||p_data_quietanza_da||''' AND '''||p_data_quietanza_a||''') ';          
               end if;    
                miaQuery:=miaQuery||' AND t_ordinativo.ente_proprietario_id = '||p_ente_prop_id||'
                AND t_periodo.anno='''||p_anno||'''
                    /* Gli stati possibili sono:
                        I = INSERITO
                        T = TRASMESSO 
                        Q = QUIETANZIATO
                        F = FIRMATO
                        A = ANNULLATO 
                        Prendo tutti tranne gli annullati.
                       */
                AND d_ord_stato.ord_stato_code <> ''A''
                AND d_ord_tipo.ord_tipo_code=''P'' /* Ordinativi di pagamento */
                AND d_ts_det_tipo.ord_ts_det_tipo_code=''A'' /* importo attuale */
                    /* devo testare la data di fine validita'' perche''
                        quando un ordinativo e'' annullato, lo trovo 2 volte,
                        uno con stato inserito e l''altro annullato */
                AND r_ord_stato.validita_fine IS NULL 
                AND ep.data_cancellazione IS NULL
                AND r_ord_stato.data_cancellazione IS NULL
                AND r_ordinativo_bil_elem.data_cancellazione IS NULL
                AND t_bil_elem.data_cancellazione IS NULL
                AND  t_bil.data_cancellazione IS NULL
                AND  t_periodo.data_cancellazione IS NULL
                AND  t_ordinativo.data_cancellazione IS NULL
                AND  t_ord_ts.data_cancellazione IS NULL
                AND  t_ord_ts_det.data_cancellazione IS NULL
                AND  d_ts_det_tipo.data_cancellazione IS NULL
                AND  r_ord_stato.data_cancellazione IS NULL
                AND  d_ord_stato.data_cancellazione IS NULL
                AND  d_ord_tipo.data_cancellazione IS NULL  
                AND r_ord_soggetto.data_cancellazione IS NULL
                AND t_soggetto.data_cancellazione IS NULL
                AND r_liq_ord.data_cancellazione IS NULL 
                AND r_liq_movgest.data_cancellazione IS NULL 
                AND t_movgest.data_cancellazione IS NULL
                AND t_movgest_ts.data_cancellazione IS NULL
                AND t_ord_ts.data_cancellazione IS NULL
                GROUP BY ep.ente_denominazione, ep.codice_fiscale, 
                  t_periodo.anno , t_ordinativo.ord_anno,
                   t_ordinativo.ord_desc, t_ordinativo.ord_id,
                  t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,   
                  t_soggetto.soggetto_code, t_soggetto.soggetto_desc,  
                  t_soggetto.partita_iva,t_soggetto.codice_fiscale,                  
                  t_bil_elem.elem_code , t_bil_elem.elem_code2 ,
                  t_bil_elem.elem_id, d_ord_stato.ord_stato_code, t_movgest.movgest_anno
                   )  
		select  *
          from  mandati
               join irap on mandati.ord_id = irap.ord_id   
                ORDER BY irap.doc_id, irap.subdoc_id   ';    
 raise notice 'Query IRAP: %', miaQuery;          
	FOR elencoMandati IN
    	execute miaQuery
    loop           
        percQuota=0;    	          
       
   			/* verifico quante quote ci sono relative alla fattura */
		numeroQuoteFattura=0;
        SELECT count(*)
        INTO numeroQuoteFattura
        from siac_t_subdoc s
        where s.doc_id= elencoMandati.doc_id
        		--19/07/2017: prendo solo le quote NON STORNATE completamente.
            and s.subdoc_importo-s.subdoc_importo_da_dedurre>0;
        IF NOT FOUND THEN
        	numeroQuoteFattura=0;
        END IF;
        --19/07/2017: devo calcolare il totale da dedurre su tutta la fattura
        --	per calcolare correttamente la percentuale della quota.
        importoTotDaDedurreFattura:=0;
        SELECT sum(s.subdoc_importo_da_dedurre)
          INTO importoTotDaDedurreFattura
          from siac_t_subdoc s
          where s.doc_id= elencoMandati.doc_id;
          IF NOT FOUND THEN
              importoTotDaDedurreFattura:=0;
        END IF;
        
        raise notice 'contaQuotaIrapXXX= %', contaQuotaIrap;
        
        stato_mandato= elencoMandati.ord_stato_code;

        nome_ente=elencoMandati.ente_denominazione;
        partita_iva_ente=elencoMandati.cod_fisc_ente;
        anno_ese_finanz=elencoMandati.anno_eser;
        desc_mandato=COALESCE(elencoMandati.ord_desc,'');

        anno_mandato=elencoMandati.ord_anno;
        numero_mandato=elencoMandati.ord_numero;
        data_mandato=elencoMandati.ord_emissione_data;
        benef_cod_fiscale=COALESCE(elencoMandati.codice_fiscale,'');
        benef_partita_iva=COALESCE(elencoMandati.partita_iva,'');
        benef_nome=COALESCE(elencoMandati.soggetto_desc,'');
        benef_codice=COALESCE(elencoMandati.soggetto_code,'');
                
        tipo_ritenuta_irap=upper(elencoMandati.onere_tipo_code);
                				
        codice_ritenuta_irap=elencoMandati.onere_code;
        desc_ritenuta_irap=elencoMandati.onere_desc;
        
        	-- calcolo la percentuale della quota corrente rispetto
            -- al totale fattura.
        --19/07/2017: La percentuale della quota deve essere calcolata tenendo conto
        --	della quota da dedurre.
        --percQuota = elencoMandati.IMPORTO_QUOTA*100/ elencoMandati.IMPORTO_FATTURA;  
        percQuota = (elencoMandati.IMPORTO_QUOTA-elencoMandati.IMP_DEDURRE)*100/ 
        	(elencoMandati.IMPORTO_FATTURA-importoTotDaDedurreFattura);               
        
        importo_lordo_mandato= COALESCE(elencoMandati.IMPORTO_TOTALE,0);         
        raise notice 'IRAP ORD_ID=%,  ORD_NUM =%', elencoMandati.ord_id,numero_mandato; 
        raise notice 'ESTRATTO: IMPON =%, RITEN = %, ENTE =%', elencoMandati.IMPORTO_IMPONIBILE,elencoMandati.IMPOSTA,elencoMandati.IMPORTO_CARICO_ENTE;          
        raise notice 'FATTURA_ID = %, NUMERO_QUOTE = %, IMPORTO FATT = %, IMPORTO QUOTA = %, PERC_QUOTA = %',elencoMandati.doc_id,numeroQuoteFattura, elencoMandati.IMPORTO_FATTURA, elencoMandati.IMPORTO_QUOTA,  percQuota;
        raise notice 'Importo da Dedurre= %', elencoMandati.IMP_DEDURRE;
        raise notice 'Perc quota = %', percQuota;
        
        	-- la fattura e' la stessa della quota precedente. 
		IF  idFatturaOld = elencoMandati.doc_id THEN
        	contaQuotaIrap=contaQuotaIrap+1;
        	raise notice 'Fattura uguale alla prec: %, num_quota = %',idFatturaOld, contaQuotaIrap;
            	-- e' l'ultima quota della fattura:
                -- gli importi sono quelli totali meno quelli delle quote
                -- precedenti, per evitare problemi di arrotondamento.            
            if contaQuotaIrap= numeroQuoteFattura THEN
            	raise notice 'ULTIMA QUOTA';
            	importo_imponibile_irap=elencoMandati.IMPORTO_IMPONIBILE-importoParzIrapImpon;
                importo_ritenuta_irap=elencoMandati.IMPOSTA-importoParzIrapRiten;
                importo_ente_irap=elencoMandati.IMPORTO_CARICO_ENTE-importoParzIrapEnte;
                
                	-- azzero gli importi parziali per fattura
                importoParzIrapImpon=0;
        		importoParzIrapRiten=0;
        		importoParzIrapEnte=0;
        		importoParzIrapNetto=0;
                contaQuotaIrap=0;
            ELSE
            	raise notice 'ALTRA QUOTA';
            	importo_imponibile_irap = elencoMandati.IMPORTO_IMPONIBILE*percQuota/100;
        		importo_ritenuta_irap = elencoMandati.IMPOSTA*percQuota/100; 
        		importo_ente_irap=elencoMandati.IMPORTO_CARICO_ENTE*percQuota/100;
                importo_netto_irap=importo_lordo_mandato-importo_ritenuta_irap;
                
                	-- sommo l'importo della quota corrente
                    -- al parziale per fattura.
                importoParzIrapImpon=importoParzIrapImpon+importo_imponibile_irap;
                importoParzIrapRiten=importoParzIrapRiten+ importo_ritenuta_irap;
                importoParzIrapEnte=importoParzIrapEnte+importo_ente_irap;
                importoParzIrapNetto=importoParzIrapNetto+importo_netto_irap;
                --contaQuotaIrap=contaQuotaIrap+1;
                
            END IF;
        ELSE -- fattura diversa dalla precedente
        	raise notice 'Fattura diversa dalla prec: %, %',idFatturaOld,elencoMandati.doc_id;
            importo_imponibile_irap = elencoMandati.IMPORTO_IMPONIBILE*percQuota/100;
        	importo_ritenuta_irap = elencoMandati.IMPOSTA*percQuota/100; 
        	importo_ente_irap=elencoMandati.IMPORTO_CARICO_ENTE*percQuota/100;
            importo_netto_irap=importo_lordo_mandato-importo_ritenuta_irap;

                -- imposto l'importo della quota corrente
                -- al parziale per fattura.            
            importoParzIrapImpon=importo_imponibile_irap;
        	importoParzIrapRiten= importo_ritenuta_irap;
        	importoParzIrapEnte=importo_ente_irap;
       		importoParzIrapNetto=importo_netto_irap;
            contaQuotaIrap=1;            
        END IF;
        
                
      raise notice 'ParzImpon = %, ParzRiten = %, ParzEnte = %, ParzNetto = %', importoParzIrapImpon,importoParzIrapRiten,importoParzIrapEnte,importoParzIrapNetto;                
      raise notice 'IMPON =%, RITEN = %, ENTE =%, NETTO= %', importo_imponibile_irap, importo_ritenuta_irap,importo_ente_irap,importo_ente_irap; 
      idFatturaOld=elencoMandati.doc_id;
            
      return next;
      raise notice '';
      
      nome_ente='';
      partita_iva_ente='';
      anno_ese_finanz=0;
      anno_mandato=0;
      numero_mandato=0;
      data_mandato=NULL;
      desc_mandato='';
      benef_cod_fiscale='';
      benef_partita_iva='';
      benef_nome='';
      stato_mandato='';
      codice_tributo_irpef='';
      codice_tributo_inps='';
      codice_risc='';
      importo_lordo_mandato=0;
      importo_netto_irpef=0;
      importo_imponibile_irpef=0;
      importo_ritenuta_irpef=0;
      importo_netto_inps=0;
      importo_imponibile_inps=0;
      importo_ritenuta_inps=0;
      importo_netto_irap=0;
      importo_imponibile_irap=0;
      importo_ritenuta_irap=0;
      tipo_ritenuta_inps='';
      tipo_ritenuta_irpef='';
      tipo_ritenuta_irap='';
      codice_ritenuta_irap='';
      desc_ritenuta_irap='';
      benef_codice='';
      importo_ente_irap=0;
      importo_ente_inps=0;

      tipo_ritenuta_irpeg='';
      codice_tributo_irpeg='';
      importo_ritenuta_irpeg=0;
      importo_netto_irpeg=0;
      importo_imponibile_irpeg=0;
      codice_ritenuta_irpeg='';
      desc_ritenuta_irpeg='';
      importo_ente_irpeg=0;
      code_caus_770:='';
      desc_caus_770:='';
      code_caus_esenz:='';
      desc_caus_esenz:='';
      attivita_inizio:=NULL;
      attivita_fine:=NULL;
      attivita_code:='';
      attivita_desc:='';
      
    end loop;        
      --end if;
elsif p_tipo_ritenuta = 'IRPEF' THEN
	idFatturaOld=0;
	contaQuotaIrpef=0;
    importoParzIrpefImpon =0;
    importoParzIrpefNetto =0;
    importoParzIrpefRiten =0;
    --importoParzIrpefEnte =0;
    
    	/* 11/10/2016: la query deve estrarre insieme mandati e dati IRPEF e
        	ordinare i dati per id fattura (doc_id) perche' ci sono
            fatture che sono legate a differenti mandati.
            In questo caso e' necessario riproporzionare l'importo
            dell'aliquota a seconda della percentuale della quota fattura
            relativa al mandato rispetto al totale fattura */   
    /* 16/10/2017: ottimizzata e resa dinamica la query */
    /* 16/10/2017: SIAC-5337
        Occorre estrarre le reversali anche se annullate.
        Se la reversale e' annullata mettere l''importo ritenuta =0.
        Riproporzione sempre tranne quando importo lordo = importo reversale.
    */
 	miaQuery:='WITH irpef as
		(SELECT d_onere_tipo.onere_tipo_code, d_onere_tipo.onere_tipo_desc,
            d_onere.onere_code, d_onere.onere_desc, t_ordinativo_ts.ord_id,
            t_subdoc.subdoc_id,t_doc.doc_id,d_onere.onere_id ,
            d_dom_non_sogg_tipo.somma_non_soggetta_tipo_code,
            d_dom_non_sogg_tipo.somma_non_soggetta_tipo_desc,
              t_doc.doc_importo IMPORTO_FATTURA,
              t_subdoc.subdoc_importo IMPORTO_QUOTA,
              t_subdoc.subdoc_importo_da_dedurre IMP_DEDURRE,
              sum(r_doc_onere.importo_imponibile) IMPORTO_IMPONIBILE,
              sum(r_doc_onere.importo_carico_soggetto) IMPOSTA,
              sum(r_doc_onere.importo_carico_ente) IMPORTO_CARICO_ENTE
            from siac_t_ordinativo_ts t_ordinativo_ts,
                siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts,          
                siac_t_doc t_doc, 
                siac_t_subdoc t_subdoc,
                siac_r_doc_onere r_doc_onere
                	LEFT JOIN siac_d_somma_non_soggetta_tipo d_dom_non_sogg_tipo
                    	ON (d_dom_non_sogg_tipo.somma_non_soggetta_tipo_id=
                        	  r_doc_onere.somma_non_soggetta_tipo_id
                            AND d_dom_non_sogg_tipo.data_cancellazione IS NULL),
                siac_d_onere d_onere,                	
                siac_d_onere_tipo d_onere_tipo ,
                /* 11/10/2017: SIAC-5337 - 
                	aggiunte tabelle per poter testare lo stato. */
                siac_r_ordinativo_stato r_ord_stato,
                siac_d_ordinativo_stato d_ord_stato             
            WHERE r_subdoc_ordinativo_ts.ord_ts_id=t_ordinativo_ts.ord_ts_id
                AND t_doc.doc_id=t_subdoc.doc_id
                and t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id
                AND r_ord_stato.ord_id=t_ordinativo_ts.ord_id
                AND r_ord_stato.ord_stato_id=d_ord_stato.ord_stato_id
                AND r_doc_onere.doc_id=t_doc.doc_id
                AND d_onere.onere_id=r_doc_onere.onere_id
                AND d_onere_tipo.onere_tipo_id=d_onere.onere_tipo_id                                      
               -- AND t_ordinativo_ts.ord_id=mandati.ord_id
                AND t_ordinativo_ts.ente_proprietario_id='||p_ente_prop_id||'
                AND upper(d_onere_tipo.onere_tipo_code) in(''IRPEF'')                
                AND t_doc.data_cancellazione IS NULL
                AND t_subdoc.data_cancellazione IS NULL
                AND r_doc_onere.data_cancellazione IS NULL
                AND d_onere.data_cancellazione IS NULL
                AND d_onere_tipo.data_cancellazione IS NULL
                AND t_ordinativo_ts.data_cancellazione IS NULL
                AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL  
                AND r_ord_stato.validita_fine IS NULL 
                AND d_ord_stato.data_cancellazione IS NULL                              
                GROUP BY d_onere_tipo.onere_tipo_code, d_onere_tipo.onere_tipo_desc,
                	t_ordinativo_ts.ord_id, t_subdoc.subdoc_id,
                    d_dom_non_sogg_tipo.somma_non_soggetta_tipo_code,
            		d_dom_non_sogg_tipo.somma_non_soggetta_tipo_desc,
                    t_doc.doc_id,d_onere.onere_id ,
                    d_onere.onere_code, d_onere.onere_desc,
                     t_doc.doc_importo, t_subdoc.subdoc_importo,
                     t_subdoc.subdoc_importo_da_dedurre  ),               
				/* 01/06/2017: aggiunta gestione delle causali 770 */     
               caus_770 as (SELECT distinct r_onere_caus.onere_id,
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
                        AND r_doc_onere.ente_proprietario_id ='||p_ente_prop_id||'                         --AND r_doc_onere.onere_id=5
                        AND r_onere_caus.validita_fine IS NULL                        
                        AND r_doc_onere.data_cancellazione IS NULL 
                        AND d_modello.data_cancellazione IS NULL 
                        AND d_causale.data_cancellazione IS NULL
                        AND t_subdoc.data_cancellazione IS NULL) ,                   
       mandati as  (select 	ep.ente_denominazione, ep.codice_fiscale cod_fisc_ente, 
            t_periodo.anno anno_eser, t_ordinativo.ord_anno,
             t_ordinativo.ord_desc, t_ordinativo.ord_id,
            t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,     
            t_soggetto.soggetto_code, t_soggetto.soggetto_desc,  
            t_soggetto.partita_iva,t_soggetto.codice_fiscale,
            t_bil_elem.elem_code cod_cap, t_bil_elem.elem_code2 cod_art,
            t_bil_elem.elem_id, d_ord_stato.ord_stato_code, 
            SUM(t_ord_ts_det.ord_ts_det_importo) IMPORTO_TOTALE,
            t_movgest.movgest_anno anno_impegno
            FROM  	siac_t_ente_proprietario ep,
                    siac_t_bil t_bil,
                    siac_t_periodo t_periodo,
                    siac_r_ordinativo_bil_elem r_ordinativo_bil_elem,
                    siac_t_bil_elem t_bil_elem,                  
                    siac_t_ordinativo t_ordinativo
                  --09/02/2017: aggiunta la tabella della quietanza per testare
                  -- la data quietanza se specificata in input.
                  	LEFT JOIN siac_r_ordinativo_quietanza r_ord_quietanza
                   	on (r_ord_quietanza.ord_id=t_ordinativo.ord_id
                       	and r_ord_quietanza.data_cancellazione IS NULL
                        -- 10/10/2017: aggiunto test sulla data di fine validita'' 
            			-- per prendere la quietanza corretta.
            			and r_ord_quietanza.validita_fine is null )  ,
                    siac_t_ordinativo_ts t_ord_ts,
                    siac_r_liquidazione_ord r_liq_ord,
                    siac_r_liquidazione_movgest r_liq_movgest,
                    siac_t_movgest t_movgest,
                    siac_t_movgest_ts t_movgest_ts,
                    siac_t_ordinativo_ts_det t_ord_ts_det,
                    siac_d_ordinativo_ts_det_tipo d_ts_det_tipo,
                    siac_r_ordinativo_stato r_ord_stato,  
                    siac_d_ordinativo_stato d_ord_stato ,
                     siac_d_ordinativo_tipo d_ord_tipo,
                     siac_r_ordinativo_soggetto r_ord_soggetto ,
                     siac_t_soggetto t_soggetto  		    	
            WHERE  t_ordinativo.ente_proprietario_id=ep.ente_proprietario_id        	
                AND r_ordinativo_bil_elem.elem_id=t_bil_elem.elem_id            
                AND  r_ordinativo_bil_elem.ord_id=t_ordinativo.ord_id                    
               AND t_ordinativo.ord_id=r_ord_stato.ord_id
               AND t_bil.bil_id=t_ordinativo.bil_id
               AND t_periodo.periodo_id=t_bil.periodo_id
               AND t_ord_ts.ord_id=t_ordinativo.ord_id           
               AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
               AND d_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
               AND d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
               AND d_ord_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id 
               AND t_soggetto.soggetto_id=r_ord_soggetto.soggetto_id
               AND r_ord_soggetto.ord_id=t_ordinativo.ord_id
               AND r_liq_ord.sord_id= t_ord_ts.ord_ts_id
               AND r_liq_movgest.liq_id=r_liq_ord.liq_id
               AND t_movgest_ts.movgest_ts_id=r_liq_movgest.movgest_ts_id
               AND t_movgest_ts.movgest_id=t_movgest.movgest_id ';
               if p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL THEN
                   miaQuery:=miaQuery||' AND (to_timestamp(to_char(t_ordinativo.ord_emissione_data,''dd/MM/yyyy''),''dd/MM/yyyy'')                                                
                      between '''||p_data_mandato_da||''' AND '''||p_data_mandato_a||''') ';
               end if;
               if p_data_trasm_da IS NOT NULL AND p_data_trasm_a IS NOT NULL THEN
                  miaQuery:=miaQuery||' AND (to_timestamp(to_char(t_ordinativo.ord_trasm_oil_data,''dd/MM/yyyy''),''dd/MM/yyyy'') 
                      between '''||p_data_trasm_da ||''' AND '''||p_data_trasm_a||''') ';
               end if;
               if p_data_quietanza_da IS NOT NULL AND p_data_quietanza_a IS NOT NULL THEN
                   miaQuery:=miaQuery||' AND (to_timestamp(to_char(r_ord_quietanza.ord_quietanza_data,''dd/MM/yyyy''),''dd/MM/yyyy'') 
                      between '''||p_data_quietanza_da||''' AND '''||p_data_quietanza_a||''') ';          
               end if;    
                miaQuery:=miaQuery||' AND t_ordinativo.ente_proprietario_id ='|| p_ente_prop_id||'
                --and t_ordinativo.ord_numero in (6744,6745,6746)
                --and t_ordinativo.ord_numero in (7578,7579,7580)                
                AND t_periodo.anno='''||p_anno||'''
                    /* Gli stati possibili sono:
                        I = INSERITO
                        T = TRASMESSO 
                        Q = QUIETANZIATO
                        F = FIRMATO
                        A = ANNULLATO 
                        Prendo tutti tranne gli annullati.
                       */
                AND d_ord_stato.ord_stato_code <> ''A''
                AND d_ord_tipo.ord_tipo_code=''P'' /* Ordinativi di pagamento */
                AND d_ts_det_tipo.ord_ts_det_tipo_code=''A'' /* importo attuale */
                    /* devo testare la data di fine validita'' perche''
                        quando un ordinativo e'' annullato, lo trovo 2 volte,
                        uno con stato inserito e l''altro annullato */
                AND r_ord_stato.validita_fine IS NULL 
                AND ep.data_cancellazione IS NULL
                AND r_ord_stato.data_cancellazione IS NULL
                AND r_ordinativo_bil_elem.data_cancellazione IS NULL
                AND t_bil_elem.data_cancellazione IS NULL
                AND  t_bil.data_cancellazione IS NULL
                AND  t_periodo.data_cancellazione IS NULL
                AND  t_ordinativo.data_cancellazione IS NULL
                AND  t_ord_ts.data_cancellazione IS NULL
                AND  t_ord_ts_det.data_cancellazione IS NULL
                AND  d_ts_det_tipo.data_cancellazione IS NULL
                AND  r_ord_stato.data_cancellazione IS NULL
                AND  d_ord_stato.data_cancellazione IS NULL
                AND  d_ord_tipo.data_cancellazione IS NULL  
                AND r_ord_soggetto.data_cancellazione IS NULL
                AND t_soggetto.data_cancellazione IS NULL
                AND r_liq_ord.data_cancellazione IS NULL 
                AND r_liq_movgest.data_cancellazione IS NULL 
                AND t_movgest.data_cancellazione IS NULL
                AND t_movgest_ts.data_cancellazione IS NULL
                AND t_ord_ts.data_cancellazione IS NULL
                GROUP BY ep.ente_denominazione, ep.codice_fiscale, 
                  t_periodo.anno , t_ordinativo.ord_anno,
                   t_ordinativo.ord_desc, t_ordinativo.ord_id,
                  t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,   
                  t_soggetto.soggetto_code, t_soggetto.soggetto_desc,  
                  t_soggetto.partita_iva,t_soggetto.codice_fiscale,                  
                  t_bil_elem.elem_code , t_bil_elem.elem_code2 ,
                  t_bil_elem.elem_id, d_ord_stato.ord_stato_code, t_movgest.movgest_anno
                   ) ,
            reversali as (select a.ord_id ord_id_rev, 
                  a.codice_risc codice_risc_rev,
				  a.importo_imponibile importo_imponibile_rev,
  				  a.importo_ente importo_ente_rev,
                  a.importo_imposta importo_imposta_rev,
                  a.importo_ritenuta importo_ritenuta_rev,
                  a.importo_reversale importo_reversale_rev,
                  a.importo_ord importo_ord_rev,
                  a.stato_reversale,
  				  a.num_reversale                  
                from "fnc_bilr104_tab_reversali"('||p_ente_prop_id||','''||p_tipo_ritenuta||''',false) a) 
       select  *
          from  mandati
               join irpef on mandati.ord_id =     irpef.ord_id 
               join reversali on mandati.ord_id =  reversali.ord_id_rev 
               left join caus_770  ON (caus_770.onere_id=irpef.onere_id
                    	AND caus_770.doc_id=irpef.doc_id
                        AND caus_770.subdoc_id=irpef.subdoc_id)   
    ORDER BY irpef.doc_id, irpef.subdoc_id '; 
raise notice 'Query: %', miaQuery;                                
	FOR elencoMandati IN
    	execute miaQuery
   	loop           
        percQuota=0;    
raise notice 'Mandato: % ',  elencoMandati.ord_numero;      	          
raise notice '  Ord_id reversale = %, Importo ritenuta da reversale: % ', 
	elencoMandati.ord_id_rev, elencoMandati.importo_ritenuta_rev;
       
   			/* se la fattura e' nuova verifico quante quote ci sono 
            	relative alla fattura */
        IF  idFatturaOld <> elencoMandati.doc_id THEN
          numeroQuoteFattura=0;
          SELECT count(*)
          INTO numeroQuoteFattura
          from siac_t_subdoc s
          where s.doc_id= elencoMandati.doc_id
          	--19/07/2017: prendo solo le quote NON STORNATE completamente.
          	and s.subdoc_importo-s.subdoc_importo_da_dedurre>0;
          IF NOT FOUND THEN
              numeroQuoteFattura=0;
          END IF;
       
        --19/07/2017: devo calcolare il totale da dedurre su tutta la fattura
        --	per calcolare correttamente la percentuale della quota.
        importoTotDaDedurreFattura:=0;
        SELECT sum(s.subdoc_importo_da_dedurre)
          INTO importoTotDaDedurreFattura
          from siac_t_subdoc s
          where s.doc_id= elencoMandati.doc_id;
          IF NOT FOUND THEN
              importoTotDaDedurreFattura:=0;
          END IF;
        END IF;

        raise notice 'contaQuotaIrpefXXX= %', contaQuotaIrpef;
        stato_mandato= elencoMandati.ord_stato_code;

        nome_ente=elencoMandati.ente_denominazione;
        partita_iva_ente=elencoMandati.cod_fisc_ente;
        anno_ese_finanz=elencoMandati.anno_eser;
        desc_mandato=COALESCE(elencoMandati.ord_desc,'');

        anno_mandato=elencoMandati.ord_anno;
        numero_mandato=elencoMandati.ord_numero;
        data_mandato=elencoMandati.ord_emissione_data;
        benef_cod_fiscale=COALESCE(elencoMandati.codice_fiscale,'');
        benef_partita_iva=COALESCE(elencoMandati.partita_iva,'');
        benef_nome=COALESCE(elencoMandati.soggetto_desc,'');
        benef_codice=COALESCE(elencoMandati.soggetto_code,'');
                
        tipo_ritenuta_irpef=upper(elencoMandati.onere_tipo_code);
                				
        codice_tributo_irpef=elencoMandati.onere_code;
        --desc_ritenuta_irpef=elencoMandati.onere_desc;
        code_caus_770:=COALESCE(elencoMandati.caus_code_770,'');
		desc_caus_770:=COALESCE(elencoMandati.caus_desc_770,'');
        code_caus_esenz:=COALESCE(elencoMandati.somma_non_soggetta_tipo_code,'');
		desc_caus_esenz:=COALESCE(elencoMandati.somma_non_soggetta_tipo_desc,'');
        
        	-- calcolo la percentuale della quota corrente rispetto
            -- al totale fattura.
        --19/07/2017: La percentuale della quota deve essere calcolata tenendo conto
        --	della quota da dedurre.
        --percQuota = elencoMandati.IMPORTO_QUOTA*100/ elencoMandati.IMPORTO_FATTURA;  
        percQuota = (elencoMandati.IMPORTO_QUOTA-elencoMandati.IMP_DEDURRE)*100/ 
        	(elencoMandati.IMPORTO_FATTURA-importoTotDaDedurreFattura);               
        
        importo_lordo_mandato= COALESCE(elencoMandati.IMPORTO_TOTALE,0); 
          
        raise notice 'irpef ORD_ID=%,  ORD_NUM =%', elencoMandati.ord_id,numero_mandato; 
        raise notice 'ESTRATTO: IMPON =%, RITEN = %, LORDO MANDATO = %', elencoMandati.IMPORTO_IMPONIBILE,elencoMandati.IMPOSTA,importo_lordo_mandato;          
        raise notice 'FATTURA_ID = %, NUMERO_QUOTE = %, IMPORTO FATT = %, IMPORTO QUOTA = %, PERC_QUOTA = %',elencoMandati.doc_id,numeroQuoteFattura, elencoMandati.IMPORTO_FATTURA, elencoMandati.IMPORTO_QUOTA,  percQuota;
        raise notice 'importo da dedurre quota: %; Importo da dedurre TOTALE = % ', 
        	elencoMandati.IMP_DEDURRE, importoTotDaDedurreFattura;
        raise notice 'Perc quota = %', percQuota;
        
        IF elencoMandati.stato_reversale = 'A' THEN
        	importo_ritenuta_irpef:=0;
        else
        	IF elencoMandati.importo_ritenuta_rev = importo_lordo_mandato THEN
        		importo_ritenuta_irpef:=elencoMandati.importo_ritenuta_rev;
            end if;
        end if;
            -- la fattura e' la stessa della quota precedente.         
        IF  idFatturaOld = elencoMandati.doc_id THEN
            contaQuotaIrpef=contaQuotaIrpef+1;
            raise notice 'Fattura uguale alla prec: %, num_quota = %',idFatturaOld, contaQuotaIrpef;
                  	
                -- e' l'ultima quota della fattura:
                -- gli importi sono quelli totali meno quelli delle quote
                -- precedenti, per evitare problemi di arrotondamento.            
            if contaQuotaIrpef= numeroQuoteFattura THEN
                raise notice 'ULTIMA QUOTA';
                importo_imponibile_irpef=elencoMandati.IMPORTO_IMPONIBILE-importoParzIrpefImpon;
                IF elencoMandati.stato_reversale <> 'A' AND 
                	elencoMandati.importo_ritenuta_rev <> importo_lordo_mandato THEN
                	importo_ritenuta_irpef=round(elencoMandati.IMPOSTA-importoParzIrpefRiten,2);
                end if;
                --importo_ente_irpef=elencoMandati.IMPORTO_CARICO_ENTE-importoParzIrpefEnte;
        raise notice 'importo_lordo_mandato = %, importo_ritenuta_irpef = %,
                        importoParzIrpefRiten = %',
                     importo_lordo_mandato, importo_ritenuta_irpef, importoParzIrpefRiten;
                importo_netto_irpef=importo_lordo_mandato-importo_ritenuta_irpef;
                      
                raise notice 'Dopo ultima rata - ParzImpon = %, ParzRiten = %, ParzNetto = %', importoParzIrpefImpon,importoParzIrpefRiten,importoParzIrpefNetto;    
                    -- azzero gli importi parziali per fattura
                importoParzIrpefImpon=0;
                importoParzIrpefRiten=0;
                importoParzIrpefNetto=0;
                contaQuotaIrpef=0;
            ELSE
                raise notice 'ALTRA QUOTA';
                importo_imponibile_irpef = round(elencoMandati.IMPORTO_IMPONIBILE*percQuota/100,2);
                IF elencoMandati.stato_reversale <> 'A' AND 
                	elencoMandati.importo_ritenuta_rev <> importo_lordo_mandato THEN
                	importo_ritenuta_irpef = round(elencoMandati.IMPOSTA*percQuota/100,2);         		
                end if;
                importo_netto_irpef=importo_lordo_mandato-importo_ritenuta_irpef;
                      
                    -- sommo l'importo della quota corrente
                    -- al parziale per fattura.
                importoParzIrpefImpon=round(importoParzIrpefImpon+importo_imponibile_irpef,2);
                importoParzIrpefRiten=round(importoParzIrpefRiten+ importo_ritenuta_irpef,2);                
                importoParzIrpefNetto=round(importoParzIrpefNetto+importo_netto_irpef,2);
                raise notice 'Dopo altra quota - ParzImpon = %, ParzRiten = %, ParzNetto = %', importoParzIrpefImpon,importoParzIrpefRiten,importoParzIrpefNetto;    
            END IF;
        ELSE -- fattura diversa dalla precedente
            raise notice 'Fattura diversa dalla prec: %, %',idFatturaOld,elencoMandati.doc_id;
            importo_imponibile_irpef = round(elencoMandati.IMPORTO_IMPONIBILE*percQuota/100,2);
            IF elencoMandati.stato_reversale <> 'A' AND 
                	elencoMandati.importo_ritenuta_rev <> importo_lordo_mandato THEN
            	importo_ritenuta_irpef = round(elencoMandati.IMPOSTA*percQuota/100,2);    
            end if;
            importo_netto_irpef=importo_lordo_mandato-importo_ritenuta_irpef;

                -- imposto l'importo della quota corrente
                -- al parziale per fattura.            
            importoParzIrpefImpon=round(importo_imponibile_irpef,2);
            importoParzIrpefRiten= round(importo_ritenuta_irpef,2);
            importoParzIrpefNetto=round(importo_netto_irpef,2);
                  
            raise notice 'Dopo prima quota - ParzImpon = %, ParzRiten = %, ParzNetto = %', importoParzIrpefImpon,importoParzIrpefRiten,importoParzIrpefNetto;    
            contaQuotaIrpef=1;            
        END IF;

      raise notice 'IMPON =%, RITEN = %,  NETTO= %', importo_imponibile_irpef, importo_ritenuta_irpef,importo_netto_irpef; 
      idFatturaOld=elencoMandati.doc_id;
      
      -- codice delle reversali
      if codice_risc = '' THEN
      	codice_risc = elencoMandati.codice_risc_rev;
      else
    	codice_risc = codice_risc||', '||elencoMandati.codice_risc_rev;
      end if;
      
      return next;
      
      raise notice '';
      
      nome_ente='';
      partita_iva_ente='';
      anno_ese_finanz=0;
      anno_mandato=0;
      numero_mandato=0;
      data_mandato=NULL;
      desc_mandato='';
      benef_cod_fiscale='';
      benef_partita_iva='';
      benef_nome='';
      stato_mandato='';
      codice_tributo_irpef='';
      codice_tributo_inps='';
      codice_risc='';
      importo_lordo_mandato=0;
      importo_netto_irpef=0;
      importo_imponibile_irpef=0;
      importo_ritenuta_irpef=0;
      importo_netto_inps=0;
      importo_imponibile_inps=0;
      importo_ritenuta_inps=0;
      importo_netto_irap=0;
      importo_imponibile_irap=0;
      importo_ritenuta_irap=0;
      tipo_ritenuta_inps='';
      tipo_ritenuta_irpef='';
      tipo_ritenuta_irap='';
      codice_ritenuta_irap='';
      desc_ritenuta_irap='';
      benef_codice='';
      importo_ente_irap=0;
      importo_ente_inps=0;

      tipo_ritenuta_irpeg='';
      codice_tributo_irpeg='';
      importo_ritenuta_irpeg=0;
      importo_netto_irpeg=0;
      importo_imponibile_irpeg=0;
      codice_ritenuta_irpeg='';
      desc_ritenuta_irpeg='';
      importo_ente_irpeg=0;
      code_caus_770:='';
      desc_caus_770:='';
      code_caus_esenz:='';
	  desc_caus_esenz:='';
      attivita_inizio:=NULL;
      attivita_fine:=NULL;
      attivita_code:='';
      attivita_desc:='';
      
   end loop;   
   
end if; -- FINE IF p_tipo_ritenuta

raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'fine estrazione dei dati e preparazione dati in output ';  

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

--SIAC-5337 FINE - Maurizio


--SIAC-5287 INIZIO - Maurizio

DROP FUNCTION  IF EXISTS siac."BILR159_struttura_dca_conto_economico"(p_anno_bilancio varchar, p_ente_proprietario_id integer);
DROP FUNCTION  IF EXISTS siac."BILR159_struttura_dca_conto_economico"(p_anno_bilancio varchar, p_ente_proprietario_id integer, cod_missione varchar, cod_programma varchar);

CREATE OR REPLACE FUNCTION siac."BILR159_struttura_dca_conto_economico" (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  cod_missione varchar,
  cod_programma varchar
)
RETURNS TABLE (
  nome_ente varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  segno_importo varchar,
  importo numeric,
  pdce_conto_code varchar,
  pdce_conto_desc varchar,
  livello integer
) AS
$body$
DECLARE

nome_ente varchar;
bilancio_id integer;
RTN_MESSAGGIO text;
sql_query VARCHAR;

BEGIN
  RTN_MESSAGGIO:='select 1';
  
  SELECT a.ente_denominazione
  INTO  nome_ente
  FROM  siac_t_ente_proprietario a
  WHERE a.ente_proprietario_id = p_ente_proprietario_id;
    
  select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
  where a.ente_proprietario_id = p_ente_proprietario_id 
  and b.periodo_id = a.periodo_id
  and b.anno = p_anno_bilancio;

/* 18/10/2017: resa dinamica la query perche' sono stati aggiunti i parametri 
	cod_missione e cod_programma */
    
sql_query:='select zz.* from (
  with clas as (
  with missione as 
  (select 
  e.classif_tipo_desc missione_tipo_desc,
  a.classif_id missione_id,
  a.classif_code missione_code,
  a.classif_desc missione_desc,
  a.validita_inizio missione_validita_inizio,
  a.validita_fine missione_validita_fine,
  a.ente_proprietario_id
  from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
  where 
  a.ente_proprietario_id='||p_ente_proprietario_id||'
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = ''00001''
  and to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))
  and b.classif_id_padre is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.classif_tipo_id=a.classif_tipo_id)
  , programma as (
  select 
  e.classif_tipo_desc programma_tipo_desc,
  b.classif_id_padre missione_id,
  a.classif_id programma_id,
  a.classif_code programma_code,
  a.classif_desc programma_desc,
  a.validita_inizio programma_validita_inizio,
  a.validita_fine programma_validita_fine,
  a.ente_proprietario_id
  from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
  where 
  a.ente_proprietario_id='||p_ente_proprietario_id||'
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = ''00001''
  and to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))
  and b.classif_id_padre is not  null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.classif_tipo_id=a.classif_tipo_id)
  ,
  titusc as (
  select 
  e.classif_tipo_desc titusc_tipo_desc,
  a.classif_id titusc_id,
  a.classif_code titusc_code,
  a.classif_desc titusc_desc,
  a.validita_inizio titusc_validita_inizio,
  a.validita_fine titusc_validita_fine,
  a.ente_proprietario_id
  from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
  where a.ente_proprietario_id='||p_ente_proprietario_id||'
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = ''00002''
  and to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))
  and b.classif_id_padre is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.classif_tipo_id=a.classif_tipo_id)
  , macroag as (
  select 
  e.classif_tipo_desc macroag_tipo_desc,
  b.classif_id_padre titusc_id,
  a.classif_id macroag_id,
  a.classif_code macroag_code,
  a.classif_desc macroag_desc,
  a.validita_inizio macroag_validita_inizio,
  a.validita_fine macroag_validita_fine,
  a.ente_proprietario_id
  from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
  where a.ente_proprietario_id='||p_ente_proprietario_id||'
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = ''00002''
  and to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))
  and b.classif_id_padre is not null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.classif_tipo_id=a.classif_tipo_id
  )
  select  missione.missione_tipo_desc,
  missione.missione_id,
  missione.missione_code,
  missione.missione_desc,
  missione.missione_validita_inizio,
  missione.missione_validita_fine,
  programma.programma_tipo_desc,
  programma.programma_id,
  programma.programma_code,
  programma.programma_desc,
  programma.programma_validita_inizio,
  programma.programma_validita_fine,
  titusc.titusc_tipo_desc,
  titusc.titusc_id,
  titusc.titusc_code,
  titusc.titusc_desc,
  titusc.titusc_validita_inizio,
  titusc.titusc_validita_fine,
  macroag.macroag_tipo_desc,
  macroag.macroag_id,
  macroag.macroag_code,
  macroag.macroag_desc,
  macroag.macroag_validita_inizio,
  macroag.macroag_validita_fine,
  missione.ente_proprietario_id
  from missione , programma,titusc, macroag, siac_r_class progmacro
  where programma.missione_id=missione.missione_id
  and titusc.titusc_id=macroag.titusc_id
  AND programma.programma_id = progmacro.classif_a_id
  AND titusc.titusc_id = progmacro.classif_b_id
  and titusc.ente_proprietario_id=missione.ente_proprietario_id
   ),
  capall as (
  with
  cap as (
  select a.elem_id,
  a.elem_code ,
  a.elem_desc ,
  a.elem_code2 ,
  a.elem_desc2 ,
  a.elem_id_padre ,
  a.elem_code3,
  d.classif_id programma_id,d2.classif_id macroag_id
  from siac_t_bil_elem a,siac_d_bil_elem_tipo b, siac_r_bil_elem_class c,
  siac_r_bil_elem_class c2,
  siac_t_class d,siac_t_class d2,
  siac_d_class_tipo e,siac_d_class_tipo e2, siac_r_bil_elem_categoria f, 
  siac_d_bil_elem_categoria g,siac_r_bil_elem_stato h,siac_d_bil_elem_stato i
  where a.ente_proprietario_id='||p_ente_proprietario_id||'
  and a.bil_id='||bilancio_id||'
  and b.elem_tipo_id=a.elem_tipo_id
  and b.elem_tipo_code = ''CAP-UG''
  and c.elem_id=a.elem_id
  and c2.elem_id=a.elem_id
  and d.classif_id=c.classif_id
  and d2.classif_id=c2.classif_id
  and e.classif_tipo_id=d.classif_tipo_id
  and e2.classif_tipo_id=d2.classif_tipo_id
  and e.classif_tipo_code=''PROGRAMMA''
  and e2.classif_tipo_code=''MACROAGGREGATO''
  and g.elem_cat_id=f.elem_cat_id
  and f.elem_id=a.elem_id
  and g.elem_cat_code in	(''STD'',''FPV'',''FSC'',''FPVC'')
  and h.elem_id=a.elem_id
  and i.elem_stato_id=h.elem_stato_id
  and i.elem_stato_code = ''VA''
  and h.validita_fine is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and c2.data_cancellazione is null
  and d.data_cancellazione is null
  and d2.data_cancellazione is null
  and e.data_cancellazione is null
  and e2.data_cancellazione is null
  and f.data_cancellazione is null
  and g.data_cancellazione is null
  and h.data_cancellazione is null
  and i.data_cancellazione is null
  ), 
  dati_prime_note as(
  WITH prime_note AS (
  SELECT d.pdce_fam_code, d.pdce_fam_desc,
  e.movep_det_segno,
  e.movep_det_importo importo,
  CASE 
   WHEN b.livello = 7 THEN
      (SELECT o.pdce_conto_code
      FROM   siac_t_pdce_conto o
      WHERE  o.pdce_conto_id = b.pdce_conto_id_padre
      AND    o.data_cancellazione IS NULL)
   ELSE
       b.pdce_conto_code
  END pdce_conto_code,   
  CASE 
   WHEN b.livello = 7 THEN
      (SELECT o.pdce_conto_desc
      FROM   siac_t_pdce_conto o
      WHERE  o.pdce_conto_id = b.pdce_conto_id_padre
      AND    o.data_cancellazione IS NULL)
   ELSE
       b.pdce_conto_desc
  END pdce_conto_desc,
  n.campo_pk_id,n.campo_pk_id_2,
  q.collegamento_tipo_code,
  b.livello
  FROM  siac_t_pdce_conto b
  INNER JOIN siac_t_pdce_fam_tree c ON b.pdce_fam_tree_id = c.pdce_fam_tree_id
  INNER JOIN siac_d_pdce_fam d ON c.pdce_fam_id = d.pdce_fam_id    
  INNER JOIN siac_t_mov_ep_det e ON e.pdce_conto_id = b.pdce_conto_id
  INNER JOIN siac_t_mov_ep f ON e.movep_id = f.movep_id
  INNER JOIN siac_t_prima_nota g ON f.regep_id = g.pnota_id
  INNER JOIN siac_t_bil h ON g.bil_id = h.bil_id
  INNER JOIN siac_t_periodo i ON h.periodo_id = i.periodo_id
  INNER JOIN siac_r_prima_nota_stato l ON g.pnota_id = l.pnota_id
  INNER JOIN siac_d_prima_nota_stato m ON l.pnota_stato_id = m.pnota_stato_id 
  INNER JOIN siac_r_evento_reg_movfin n ON n.regmovfin_id = f.regmovfin_id
  INNER JOIN siac_d_evento p ON p.evento_id = n.evento_id
  INNER JOIN siac_d_collegamento_tipo q ON q.collegamento_tipo_id = p.collegamento_tipo_id
  WHERE b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   m.pnota_stato_code = ''D''
  AND   i.anno = '''||p_anno_bilancio||'''
  AND   d.pdce_fam_code in (''CE'',''RE'')
  AND   b.data_cancellazione IS NULL
  AND   c.data_cancellazione IS NULL
  AND   d.data_cancellazione IS NULL
  AND   e.data_cancellazione IS NULL
  AND   f.data_cancellazione IS NULL
  AND   g.data_cancellazione IS NULL
  AND   h.data_cancellazione IS NULL
  AND   i.data_cancellazione IS NULL
  AND   l.data_cancellazione IS NULL
  AND   m.data_cancellazione IS NULL
  AND   n.data_cancellazione IS NULL
  AND   p.data_cancellazione IS NULL
  AND   q.data_cancellazione IS NULL
  ), collegamento_MMGS_MMGE_a AS (
  SELECT DISTINCT rmbe.elem_id, tm.mod_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_t_movgest_ts_det_mod tmtdm, siac_t_movgest_ts tmt,
        siac_r_movgest_bil_elem rmbe
  WHERE rms.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   tmtdm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = tmtdm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND   dms.mod_stato_code = ''V''
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   tmtdm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL
  ),
  collegamento_MMGS_MMGE_b AS (
  SELECT DISTINCT rmbe.elem_id, tm.mod_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_r_movgest_ts_sog_mod rmtsm, siac_t_movgest_ts tmt,
        siac_r_movgest_bil_elem rmbe
  WHERE rms.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   rmtsm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = rmtsm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND   dms.mod_stato_code = ''V''
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   rmtsm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL
  ),
  collegamento_I_A AS (
  SELECT DISTINCT a.elem_id, a.movgest_id
  FROM   siac_r_movgest_bil_elem a
  WHERE  a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND    a.data_cancellazione IS NULL
  ),
  collegamento_SI_SA AS (
  SELECT DISTINCT b.elem_id, a.movgest_ts_id
  FROM  siac_t_movgest_ts a, siac_r_movgest_bil_elem b
  WHERE a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   a.movgest_id = b.movgest_id
  AND   a.data_cancellazione IS NULL
  AND   b.data_cancellazione IS NULL
  ),
  collegamento_SS_SE AS (
  SELECT DISTINCT c.elem_id, a.subdoc_id
  FROM   siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
  WHERE  b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND    a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  /* 19/09/2017: SIAC-5216.
  	Si deve testare la data di fine validita'' perche'' (da mail di Irene):
     "a causa della doppia gestione che purtroppo non e'' stata implementata sui documenti!!!! 
     E'' stato trovato questo escamotage per cui la relazione 2016 viene chiusa con una
data dell''anno nuovo (in questo caso 2017) e viene creata quella nuova del 2017
(quella che tra l''altro vediamo da sistema anche sul 2016).
Per cui l''unica soluzione e'' recuperare nella tabella r_subdoc_movgest_ts  la
relazione 2016 che troverai non piu'' valida."
  */
    --and a.data_cancellazione IS NULL
  AND    (a.data_cancellazione IS NULL OR (a.data_cancellazione IS NOT NULL
  				AND a.validita_fine IS NOT NULL AND
                a.validita_fine > to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'')))
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  ),
  collegamento_OP_OI AS (
  SELECT DISTINCT a.elem_id, a.ord_id
  FROM   siac_r_ordinativo_bil_elem a
  WHERE  a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND    a.data_cancellazione IS NULL
  ),
  collegamento_L AS (
  SELECT DISTINCT c.elem_id, a.liq_id
  FROM   siac_r_liquidazione_movgest a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
  WHERE  b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND    a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  AND    a.data_cancellazione IS NULL
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  ),
  collegamento_RR AS (
  SELECT DISTINCT d.elem_id, a.gst_id
  FROM  siac_t_giustificativo a, siac_r_richiesta_econ_movgest b, siac_t_movgest_ts c, siac_r_movgest_bil_elem d
  WHERE a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   a.ricecon_id = b.ricecon_id
  AND   b.movgest_ts_id = c.movgest_ts_id
  AND   c.movgest_id = d.movgest_id
  AND   a.data_cancellazione  IS NULL
  AND   b.data_cancellazione  IS NULL
  AND   c.data_cancellazione  IS NULL
  AND   d.data_cancellazione  IS NULL
  ),
  collegamento_RE AS (
  SELECT DISTINCT c.elem_id, a.ricecon_id
  FROM  siac_r_richiesta_econ_movgest a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
  WHERE b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   a.movgest_ts_id = b.movgest_ts_id
  AND   b.movgest_id = c.movgest_id
  AND   a.data_cancellazione  IS NULL
  AND   b.data_cancellazione  IS NULL
  AND   c.data_cancellazione  IS NULL
  ),
  /* 20/09/2017: SIAC-5216..
  	Aggiunto collegamento per estrarre il capitolo nel caso il documento
  	sia una nota di Credito.
    In questo caso occorre prendere l''impegno del documento collegato e non quello della nota di 
    credito che non esiste */
  collegamento_SS_SE_NCD AS (
  select c.elem_id, a.subdoc_id
  from  siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
  where a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  AND b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND    (a.data_cancellazione IS NULL OR (a.data_cancellazione IS NOT NULL
  				AND a.validita_fine IS NOT NULL AND
                a.validita_fine > to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'')))
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  )
  SELECT 
  prime_note.movep_det_segno,
  prime_note.importo,
  prime_note.pdce_conto_code,
  prime_note.pdce_conto_desc,
  prime_note.livello,
  -- COALESCE(collegamento_MMGS_MMGE_a.elem_id, collegamento_MMGS_MMGE_b.elem_id),
  -- collegamento_SS_SE.elem_id,
  -- collegamento_I_A.elem_id,
  -- collegamento_SI_SA.elem_id
  -- collegamento_OP_OI.elem_id
  -- collegamento_L.elem_id
  -- collegamento_RR.elem_id
  -- collegamento_RE.elem_id
  --COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.elem_id, collegamento_MMGS_MMGE_b.elem_id),collegamento_SS_SE.elem_id),collegamento_I_A.elem_id),collegamento_SI_SA.elem_id),collegamento_OP_OI.elem_id),collegamento_L.elem_id),collegamento_RR.elem_id),collegamento_RE.elem_id) elem_id
  COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.elem_id, collegamento_MMGS_MMGE_b.elem_id),collegamento_SS_SE.elem_id),collegamento_I_A.elem_id),collegamento_SI_SA.elem_id),collegamento_OP_OI.elem_id),collegamento_L.elem_id),collegamento_RR.elem_id),collegamento_RE.elem_id), collegamento_SS_SE_NCD.elem_id) elem_id
  FROM   prime_note
  LEFT   JOIN collegamento_MMGS_MMGE_a ON collegamento_MMGS_MMGE_a.mod_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN (''MMGS'',''MMGE'') 
  LEFT   JOIN collegamento_MMGS_MMGE_b ON collegamento_MMGS_MMGE_b.mod_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN (''MMGS'',''MMGE'')
  LEFT   JOIN collegamento_I_A ON collegamento_I_A.movgest_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN (''I'',''A'')
  LEFT   JOIN collegamento_SI_SA ON collegamento_SI_SA.movgest_ts_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN (''SI'',''SA'')                                     
  LEFT   JOIN collegamento_SS_SE ON collegamento_SS_SE.subdoc_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN (''SS'',''SE'')
  LEFT   JOIN collegamento_OP_OI ON collegamento_OP_OI.ord_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN (''OP'',''OI'')
  LEFT   JOIN collegamento_L ON collegamento_L.liq_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code = ''L''
  LEFT   JOIN collegamento_RR ON collegamento_RR.gst_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code = ''RR''
  LEFT   JOIN collegamento_RE ON collegamento_RE.ricecon_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code = ''RE''
  --20/09/2017: collegamento per note di credito. Si usa campo_pk_id_2
  LEFT	 JOIN collegamento_SS_SE_NCD ON collegamento_SS_SE_NCD.subdoc_id = prime_note.campo_pk_id_2
  										AND prime_note.collegamento_tipo_code IN (''SS'',''SE'')                      
  )                      
  select -- distinct
  cap.elem_id bil_ele_id,
  cap.elem_code bil_ele_code,
  cap.elem_desc bil_ele_desc,
  cap.elem_code2 bil_ele_code2,
  cap.elem_desc2 bil_ele_desc2,
  cap.elem_id_padre bil_ele_id_padre,
  cap.elem_code3 bil_ele_code3,
  cap.programma_id,cap.macroag_id,
  dati_prime_note.*
  from cap
  left join dati_prime_note on cap.elem_id = dati_prime_note.elem_id  
  )
  select 
      '''||nome_ente||'''::varchar,
      clas.missione_code::varchar,
      clas.missione_desc::varchar,
      clas.programma_code::varchar,
      clas.programma_desc::varchar,
      capall.movep_det_segno::varchar,
      capall.importo::numeric,
      capall.pdce_conto_code::varchar,
      capall.pdce_conto_desc::varchar,
      capall.livello::integer
  from clas left join capall on 
  clas.programma_id = capall.programma_id and    
  clas.macroag_id=capall.macroag_id
  where capall.importo is not null ';
/*  16/10/2017: SIAC-5287.
	Aggiunto filtro su missione/programma */      
  if cod_missione <> 'T' THEN
  	sql_query:=sql_query||' AND clas.missione_code ='''||cod_missione||'''';
  end if;
  if cod_programma <> 'T' THEN
  	sql_query:=sql_query||' AND clas.programma_code ='''||cod_programma||'''';
  end if;
  sql_query:=sql_query||' 
  union all
    select 
      '''||nome_ente||'''::varchar,
      clas.missione_code::varchar,
      clas.missione_desc::varchar,
      clas.programma_code::varchar,
      clas.programma_desc::varchar,
      ''Avere'',
      0.00::numeric(15,2) ,
      capall.pdce_conto_code::varchar,
      capall.pdce_conto_desc::varchar,
      capall.livello::integer
  from clas left join capall on 
  	clas.programma_id = capall.programma_id and    
 	 clas.macroag_id=capall.macroag_id
  where capall.importo is not null ';
/*  16/10/2017: SIAC-5287.
	Aggiunto filtro su missione/programma */      
  if cod_missione <> 'T' THEN
  	sql_query:=sql_query||' AND clas.missione_code ='''||cod_missione||'''';
  end if;
  if cod_programma <> 'T' THEN
  	sql_query:=sql_query||' AND clas.programma_code ='''||cod_programma||'''';
  end if;
  sql_query:=sql_query||' 
  union all
      select 
      '''||nome_ente||'''::varchar,
      clas.missione_code::varchar,
      clas.missione_desc::varchar,
      clas.programma_code::varchar,
      clas.programma_desc::varchar,
      ''Dare'',
      0.00::numeric(15,2) ,
      capall.pdce_conto_code::varchar,
      capall.pdce_conto_desc::varchar,
      capall.livello::integer
  from clas left join capall on 
  clas.programma_id = capall.programma_id and    
  clas.macroag_id=capall.macroag_id
  where capall.importo is not null ';
/*  16/10/2017: SIAC-5287.
	Aggiunto filtro su missione/programma */      
  if cod_missione <> 'T' THEN
  	sql_query:=sql_query||' AND clas.missione_code ='''||cod_missione||'''';
  end if;
  if cod_programma <> 'T' THEN
  	sql_query:=sql_query||' AND clas.programma_code ='''||cod_programma||'''';
  end if;
  sql_query:=sql_query||' ) as zz ';
/*  16/10/2017: SIAC-5287.
    	Aggiunta gestione delle prime note libere.
*/  
sql_query:=sql_query||' 
UNION
  select xx.* from (
  WITH prime_note_lib AS (
  SELECT b.ente_proprietario_id, d_caus_ep.causale_ep_tipo_code, d.pdce_fam_code, d.pdce_fam_desc,
  e.movep_det_segno,
  e.movep_det_importo importo,
  CASE 
   WHEN b.livello = 7 THEN
      (SELECT o.pdce_conto_code
      FROM   siac_t_pdce_conto o
      WHERE  o.pdce_conto_id = b.pdce_conto_id_padre
      AND    o.data_cancellazione IS NULL)
   ELSE
       b.pdce_conto_code
  END pdce_conto_code,   
  CASE 
   WHEN b.livello = 7 THEN
      (SELECT o.pdce_conto_desc
      FROM   siac_t_pdce_conto o
      WHERE  o.pdce_conto_id = b.pdce_conto_id_padre
      AND    o.data_cancellazione IS NULL)
   ELSE
       b.pdce_conto_desc
  END pdce_conto_desc,
  b.livello,e.movep_det_id
  FROM  siac_t_pdce_conto b
  INNER JOIN siac_t_pdce_fam_tree c ON b.pdce_fam_tree_id = c.pdce_fam_tree_id
  INNER JOIN siac_d_pdce_fam d ON c.pdce_fam_id = d.pdce_fam_id    
  INNER JOIN siac_t_mov_ep_det e ON e.pdce_conto_id = b.pdce_conto_id
  --LEFT JOIN  siac_r_mov_ep_det_class r_mov_ep_det_class 
  --		ON (r_mov_ep_det_class.movep_det_id=e.movep_det_id
   --     	AND r_mov_ep_det_class.data_cancellazione IS NULL)
  INNER JOIN siac_t_mov_ep f ON e.movep_id = f.movep_id
  INNER JOIN siac_t_prima_nota g ON f.regep_id = g.pnota_id
  INNER JOIN siac_t_bil h ON g.bil_id = h.bil_id
  INNER JOIN siac_t_periodo i ON h.periodo_id = i.periodo_id
  INNER JOIN siac_r_prima_nota_stato l ON g.pnota_id = l.pnota_id
  INNER JOIN siac_d_prima_nota_stato m ON l.pnota_stato_id = m.pnota_stato_id 
  INNER JOIN siac_t_causale_ep t_caus_ep ON t_caus_ep.causale_ep_id=f.causale_ep_id
  INNER JOIN siac_d_causale_ep_tipo d_caus_ep ON d_caus_ep.causale_ep_tipo_id=t_caus_ep.causale_ep_tipo_id
  WHERE b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   m.pnota_stato_code = ''D''
  AND   i.anno = '''||p_anno_bilancio||'''
  AND   d.pdce_fam_code in (''CE'',''RE'')
  AND   d_caus_ep.causale_ep_tipo_code =''LIB''
  AND   b.data_cancellazione IS NULL
  AND   c.data_cancellazione IS NULL
  AND   d.data_cancellazione IS NULL
  AND   e.data_cancellazione IS NULL
  AND   f.data_cancellazione IS NULL
  AND   g.data_cancellazione IS NULL
  AND   h.data_cancellazione IS NULL
  AND   i.data_cancellazione IS NULL
  AND   l.data_cancellazione IS NULL
  AND   m.data_cancellazione IS NULL
  ),
ele_prime_note_progr as (
  	select r_mov_ep_det_class.*
    from siac_r_mov_ep_det_class r_mov_ep_det_class,
    	siac_t_class t_class ,  	
        siac_d_class_tipo d_class_tipo	
    where t_class.classif_id=r_mov_ep_det_class.classif_id
    	and d_class_tipo.classif_tipo_id = t_class.classif_tipo_id
        AND r_mov_ep_det_class.ente_proprietario_id='||p_ente_proprietario_id||'
        and d_class_tipo.classif_tipo_code=''PROGRAMMA''
        and r_mov_ep_det_class.data_cancellazione IS NULL
        and t_class.data_cancellazione IS NULL
        and d_class_tipo.data_cancellazione IS NULL),
ele_prime_note_miss as (
  	select r_mov_ep_det_class.*
    from siac_r_mov_ep_det_class r_mov_ep_det_class,
    	siac_t_class t_class ,  	
        siac_d_class_tipo d_class_tipo	
    where t_class.classif_id=r_mov_ep_det_class.classif_id
    	and d_class_tipo.classif_tipo_id = t_class.classif_tipo_id
        AND r_mov_ep_det_class.ente_proprietario_id='||p_ente_proprietario_id||'
        and d_class_tipo.classif_tipo_code=''MISSIONE''
        and r_mov_ep_det_class.data_cancellazione IS NULL
        and t_class.data_cancellazione IS NULL
        and d_class_tipo.data_cancellazione IS NULL),        
  missione as 
  (select 
  e.classif_tipo_desc missione_tipo_desc,
  a.classif_id missione_id,
  a.classif_code missione_code,
  a.classif_desc missione_desc,
  a.validita_inizio missione_validita_inizio,
  a.validita_fine missione_validita_fine,
  a.ente_proprietario_id
  from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
  where 
  a.ente_proprietario_id='||p_ente_proprietario_id||'
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = ''00001''
  and to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))
  and b.classif_id_padre is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.classif_tipo_id=a.classif_tipo_id)
  , programma as (
  select 
  e.classif_tipo_desc programma_tipo_desc,
  b.classif_id_padre missione_id,
  a.classif_id programma_id,
  a.classif_code programma_code,
  a.classif_desc programma_desc,
  a.validita_inizio programma_validita_inizio,
  a.validita_fine programma_validita_fine,
  a.ente_proprietario_id
  from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
  where 
  a.ente_proprietario_id='||p_ente_proprietario_id||'
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = ''00001''
  and to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))
  and b.classif_id_padre is not  null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.classif_tipo_id=a.classif_tipo_id)
select '''||nome_ente||'''::varchar nome_ente, 
	COALESCE(missione.missione_code,'''')::varchar missione_code, 
    COALESCE(missione.missione_desc,'''')::varchar missione_desc,
	COALESCE(programma.programma_code,'''')::varchar programma_code, 
	COALESCE(programma.programma_desc,'''')::varchar programma_desc,
	prime_note_lib.movep_det_segno::varchar segno_importo,
    prime_note_lib.importo::numeric ,
	prime_note_lib.pdce_conto_code::varchar,
    prime_note_lib.pdce_conto_desc::varchar,
    prime_note_lib.livello::integer  
from prime_note_lib
	LEFT JOIN ele_prime_note_progr ON ele_prime_note_progr.movep_det_id=prime_note_lib.movep_det_id
    LEFT JOIN ele_prime_note_miss ON ele_prime_note_miss.movep_det_id=prime_note_lib.movep_det_id
	LEFT JOIN programma ON programma.programma_id = ele_prime_note_progr.classif_id
    LEFT JOIN missione ON missione.missione_id=ele_prime_note_miss.classif_id ';  
  if cod_missione <> 'T' THEN
  	sql_query:=sql_query||' 
    	WHERE (missione.missione_code ='''||cod_missione||''' OR ele_prime_note_miss.movep_det_id is null) ';
  end if;
  if cod_programma <> 'T' THEN
  	sql_query:=sql_query||' 
    	AND (programma.programma_code ='''||cod_programma||''' OR ele_prime_note_progr.movep_det_id is null) ';
  end if;
  sql_query:=sql_query||'
union select '''||nome_ente||'''::varchar nome_ente, 
	COALESCE(missione.missione_code,'''')::varchar missione_code, 
    COALESCE(missione.missione_desc,'''')::varchar missione_desc,
	COALESCE(programma.programma_code,'''')::varchar programma_code, 
	COALESCE(programma.programma_desc,'''')::varchar programma_desc,
	''Dare''::varchar segno_importo,
    0.00::numeric(15,2),
	prime_note_lib.pdce_conto_code::varchar,
    prime_note_lib.pdce_conto_desc::varchar,
    prime_note_lib.livello::integer  
from prime_note_lib
	LEFT JOIN ele_prime_note_progr ON ele_prime_note_progr.movep_det_id=prime_note_lib.movep_det_id
    LEFT JOIN ele_prime_note_miss ON ele_prime_note_miss.movep_det_id=prime_note_lib.movep_det_id
	LEFT JOIN programma ON programma.programma_id = ele_prime_note_progr.classif_id
    LEFT JOIN missione ON missione.missione_id=ele_prime_note_miss.classif_id ';  
if cod_missione <> 'T' THEN
  	sql_query:=sql_query||' 
    	WHERE (missione.missione_code ='''||cod_missione||''' OR ele_prime_note_miss.movep_det_id is null) ';
  end if;
  if cod_programma <> 'T' THEN
  	sql_query:=sql_query||' 
    	AND (programma.programma_code ='''||cod_programma||''' OR ele_prime_note_progr.movep_det_id is null) ';
  end if; 
sql_query:=sql_query||' 
union select '''||nome_ente||'''::varchar nome_ente, 
	COALESCE(missione.missione_code,'''')::varchar missione_code, 
    COALESCE(missione.missione_desc,'''')::varchar missione_desc,
	COALESCE(programma.programma_code,'''')::varchar programma_code, 
	COALESCE(programma.programma_desc,'''')::varchar programma_desc,
	''Avere''::varchar segno_importo,
    0.00::numeric(15,2),
	prime_note_lib.pdce_conto_code::varchar,
    prime_note_lib.pdce_conto_desc::varchar,
    prime_note_lib.livello::integer  
from prime_note_lib
	LEFT JOIN ele_prime_note_progr ON ele_prime_note_progr.movep_det_id=prime_note_lib.movep_det_id
    LEFT JOIN ele_prime_note_miss ON ele_prime_note_miss.movep_det_id=prime_note_lib.movep_det_id
	LEFT JOIN programma ON programma.programma_id = ele_prime_note_progr.classif_id
    LEFT JOIN missione ON missione.missione_id=ele_prime_note_miss.classif_id ';  
if cod_missione <> 'T' THEN
  	sql_query:=sql_query||' 
    	WHERE (missione.missione_code ='''||cod_missione||''' OR ele_prime_note_miss.movep_det_id is null) ';
  end if;
  if cod_programma <> 'T' THEN
  	sql_query:=sql_query||' 
    	AND (programma.programma_code ='''||cod_programma||''' OR ele_prime_note_progr.movep_det_id is null) ';
  end if; 
sql_query:=sql_query||'
    ) as xx';
    
raise notice 'sql_query= %',     sql_query;

  return query execute sql_query;
  

  exception
  when no_data_found THEN
  raise notice 'nessun dato trovato per struttura bilancio';
  return;
  when others  THEN
  RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
  return;
    
    
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

--SIAC-5287 FINE - Maurizio

-- SIAC-5313 INIZIO
DROP VIEW IF EXISTS siac_v_dwh_predocumenti_pagamento;

CREATE OR REPLACE VIEW siac.siac_v_dwh_predocumenti_pagamento (
    ente_proprietario_id,
    predoc_id,
    predoc_numero,
    predoc_periodo_competenza,
    predoc_data_competenza,
    data_esecuzione,
    predoc_data_trasmissione,
    predoc_importo,
    descrizione,
    predoc_codice_iuv,
    predoc_note,
    predoc_stato_code,
    predoc_stato_desc,
    struttura_code,
    struttura_desc,
    struttura_tipo_code,
    famiglia_causale_code,
    famiglia_causale_desc,
    tipo_causale_code,
    tipo_causale_desc,
    causale_code,
    causale_desc,
    predocan_ragione_sociale,
    predocan_cognome,
    predocan_nome,
    predocan_codice_fiscale,
    predocan_partita_iva,
    soggetto_id,
    soggetto_codice,
    soggetto_desc,
    movgest_anno,
    movgest_numero,
    sub,
    doc_id,
    doc_numero,
    doc_anno,
    doc_data_emissione,
    doc_tipo_code,
    doc_tipo_desc,
    doc_fam_tipo_code,
    doc_fam_tipo_desc,
    numero_elenco)
AS
 WITH pred AS (
SELECT a.ente_proprietario_id, a.predoc_id, a.predoc_numero,
            a.predoc_periodo_competenza, a.predoc_data_competenza,
            a.predoc_data, a.predoc_data_trasmissione, a.predoc_importo,
            replace(a.predoc_desc::text, '\r\n'::text, ' '::text) AS predoc_desc,
            a.predoc_codice_iuv, a.predoc_note, c.predoc_stato_code,
            c.predoc_stato_desc, i.caus_fam_tipo_code, i.caus_fam_tipo_desc,
            g.caus_tipo_code, g.caus_tipo_desc, e.caus_code,
            replace(e.caus_desc::text, '\r\n'::text, ' '::text) AS caus_desc,
            h.predocan_ragione_sociale, h.predocan_cognome, h.predocan_nome,
            h.predocan_codice_fiscale, h.predocan_partita_iva,
            l.doc_fam_tipo_code, l.doc_fam_tipo_desc
FROM siac_t_predoc a, siac_r_predoc_stato b, siac_d_predoc_stato c,
            siac_r_predoc_causale d, siac_d_causale e, siac_r_causale_tipo f,
            siac_d_causale_tipo g, siac_t_predoc_anagr h,
            siac_d_causale_fam_tipo i, siac_d_doc_fam_tipo l
WHERE b.predoc_id = a.predoc_id AND c.predoc_stato_id = b.predoc_stato_id AND
    d.predoc_id = a.predoc_id AND e.caus_id = d.caus_id AND f.caus_id = e.caus_id AND g.caus_tipo_id = f.caus_tipo_id AND h.predoc_id = a.predoc_id AND i.caus_fam_tipo_id = g.caus_fam_tipo_id AND a.doc_fam_tipo_id = l.doc_fam_tipo_id AND l.doc_fam_tipo_code::text = 'S'::text AND a.data_cancellazione IS NULL AND b.data_cancellazione IS NULL AND c.data_cancellazione IS NULL AND d.data_cancellazione IS NULL AND e.data_cancellazione IS NULL AND f.data_cancellazione IS NULL AND g.data_cancellazione IS NULL AND h.data_cancellazione IS NULL AND i.data_cancellazione IS NULL AND l.data_cancellazione IS NULL
        ), sog AS (
    SELECT a.predoc_id, b.soggetto_id, b.soggetto_code, b.soggetto_desc
    FROM siac_r_predoc_sog a, siac_t_soggetto b
    WHERE b.soggetto_id = a.soggetto_id AND a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL
    ), movgest AS (
    SELECT a.predoc_id, c.movgest_anno, c.movgest_numero,
                CASE
                    WHEN d.movgest_ts_tipo_code::text = 'T'::text THEN
                        '0'::character varying
                    ELSE b.movgest_ts_code
                END AS movgest_ts_code
    FROM siac_r_predoc_movgest_ts a, siac_t_movgest_ts b,
            siac_t_movgest c, siac_d_movgest_ts_tipo d
    WHERE a.movgest_ts_id = b.movgest_ts_id AND c.movgest_id = b.movgest_id AND
        d.movgest_ts_tipo_id = b.movgest_ts_tipo_id AND a.data_cancellazione IS NULL AND b.data_cancellazione IS NULL AND c.data_cancellazione IS NULL AND d.data_cancellazione IS NULL
    ), sac AS (
    SELECT a.predoc_id, b.classif_code, b.classif_desc,
            c.classif_tipo_code
    FROM siac_r_predoc_class a, siac_t_class b, siac_d_class_tipo c
    WHERE a.classif_id = b.classif_id AND c.classif_tipo_id = b.classif_tipo_id
        AND (c.classif_tipo_code::text = ANY (ARRAY['CDC'::character varying, 'CDR'::character varying]::text[])) AND a.data_cancellazione IS NULL AND b.data_cancellazione IS NULL AND c.data_cancellazione IS NULL
    ), doc AS (
    SELECT e.predoc_id, a.doc_id, a.doc_numero, a.doc_anno,
            a.doc_data_emissione, c.doc_tipo_code, c.doc_tipo_desc
    FROM siac_t_doc a, siac_t_subdoc b, siac_d_doc_tipo c,
            siac_r_predoc_subdoc e
    WHERE a.doc_id = b.doc_id AND c.doc_tipo_id = a.doc_tipo_id AND e.subdoc_id
        = b.subdoc_id AND e.validita_fine IS NULL AND a.data_cancellazione IS NULL AND b.data_cancellazione IS NULL AND c.data_cancellazione IS NULL AND e.data_cancellazione IS NULL
    ), elenco AS (
    SELECT a.predoc_id, b.eldoc_numero
    FROM siac_r_elenco_doc_predoc a, siac_t_elenco_doc b
    WHERE a.eldoc_id = b.eldoc_id AND a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL
    )
    SELECT pred.ente_proprietario_id, pred.predoc_id, pred.predoc_numero,
    pred.predoc_periodo_competenza, pred.predoc_data_competenza,
    pred.predoc_data AS data_esecuzione, pred.predoc_data_trasmissione,
    pred.predoc_importo, pred.predoc_desc AS descrizione,
    pred.predoc_codice_iuv, pred.predoc_note, pred.predoc_stato_code,
    pred.predoc_stato_desc, sac.classif_code AS struttura_code,
    sac.classif_desc AS struttura_desc,
    sac.classif_tipo_code AS struttura_tipo_code,
    pred.caus_fam_tipo_code AS famiglia_causale_code,
    pred.caus_fam_tipo_desc AS famiglia_causale_desc,
    pred.caus_tipo_code AS tipo_causale_code,
    pred.caus_tipo_desc AS tipo_causale_desc, pred.caus_code AS causale_code,
    pred.caus_desc AS causale_desc, pred.predocan_ragione_sociale,
    pred.predocan_cognome, pred.predocan_nome, pred.predocan_codice_fiscale,
    pred.predocan_partita_iva, sog.soggetto_id,
    sog.soggetto_code AS soggetto_codice, sog.soggetto_desc,
    movgest.movgest_anno, movgest.movgest_numero,
    movgest.movgest_ts_code AS sub, doc.doc_id, doc.doc_numero, doc.doc_anno,
    doc.doc_data_emissione, doc.doc_tipo_code, doc.doc_tipo_desc,
    pred.doc_fam_tipo_code, pred.doc_fam_tipo_desc,
    elenco.eldoc_numero AS numero_elenco
    FROM pred
   LEFT JOIN sog ON pred.predoc_id = sog.predoc_id
   LEFT JOIN movgest ON pred.predoc_id = movgest.predoc_id
   LEFT JOIN sac ON pred.predoc_id = sac.predoc_id
   LEFT JOIN doc ON pred.predoc_id = doc.predoc_id
   LEFT JOIN elenco ON pred.predoc_id = elenco.predoc_id
    ORDER BY pred.ente_proprietario_id, pred.predoc_numero, pred.predoc_data_competenza;
-- SIAC-5313 FINE

--SIAC-5417 - INIZIO - Maurizio

CREATE OR REPLACE FUNCTION siac."BILR997_tipo_capitolo_dei_report_variaz" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_num_provv_var_peg integer,
  p_anno_provv_var_peg varchar,
  p_tipo_provv_var_peg varchar,
  p_num_provv_var_bil integer,
  p_anno_provv_var_bil varchar,
  p_tipo_provv_var_bil varchar,
  p_code_sac_direz_peg varchar,
  p_code_sac_sett_peg varchar,
  p_code_sac_direz_bil varchar,
  p_code_sac_sett_bil varchar
)
RETURNS TABLE (
  anno_competenza varchar,
  importo numeric,
  descrizione varchar,
  posizione_nel_report integer,
  codice_importo varchar,
  tipo_capitolo_cod varchar
) AS
$body$
DECLARE

classifBilRec record;
tipo_capitolo record;
tipoAvanzo varchar;
tipoDisavanzo varchar;
tipoFpvcc varchar;
tipoFpvsc varchar;
tipoFCassaIni varchar;
tipoFpv varchar;
elemTipoCodeE varchar;
elemTipoCodeS varchar;
RTN_MESSAGGIO varchar(1000):='';
sql_query VARCHAR;
user_table	varchar;
elemTipoCode VARCHAR;
elemCatCode  VARCHAR;
variazione_aumento_stanziato NUMERIC;
variazione_diminuzione_stanziato NUMERIC;
variazione_aumento_cassa NUMERIC;
variazione_diminuzione_cassa NUMERIC;
variazione_aumento_residuo NUMERIC;
variazione_diminuzione_residuo NUMERIC;

--fase_bilancio varchar;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
contaParVarPeg integer;
contaParVarBil integer;

BEGIN

anno_competenza='';
importo=0;
descrizione='';
posizione_nel_report=0;
codice_importo='';
tipoAvanzo='AAM';
tipoDisavanzo='DAM';
tipoFpvcc='FPVCC';
tipoFpvsc='FPVSC';
tipoFCassaIni='FCI';
tipoFpv='FPV'; 
tipo_capitolo_cod='';


elemTipoCodeE:='CAP-EG'; -- tipo capitolo gestione
elemTipoCodeS:='CAP-UG'; -- tipo capitolo gestione

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

elemTipoCode:='CAP-EG'; -- tipo capitolo previsione

variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;

contaParVarPeg:=0;
contaParVarBil:=0;

  /* 22/09/2017: parametri nuovi, controllo che se e' passato uno tra numero/anno/tipo
    	provvedimento di variazione di PEG o di BILANCIO, siano passati anche
        gli altri 2. */
if p_num_provv_var_peg IS NOT  NULL THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_anno_provv_var_peg IS NOT  NULL AND p_anno_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_tipo_provv_var_peg IS NOT  NULL AND p_tipo_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if contaParVarPeg not in (0,3) then
	--display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di PEG''';
    return next;
    return;        
end if;

if p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if contaParVarBil not in (0,3) then
	--display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di Bilancio''';
    return next;
    return;        
end if;
select fnc_siac_random_user()
into	user_table;

-------------------------------------
--22/07/2016:
--se sono state specificate delle variazioni cerco i relativi valori


insert into siac_rep_cap_ep
select --cl.classif_id,
  NULL,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	--siac_r_bil_elem_class rc,
 		siac_t_bil_elem e,
        --siac_d_class_tipo ct,
		--siac_t_class cl,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where-- ct.classif_tipo_code			=	'CATEGORIA'
--and ct.classif_tipo_id				=	cl.classif_tipo_id
--and cl.classif_id					=	rc.classif_id 
--and 
e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCodeE
--and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
--and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
--and	rc.data_cancellazione				is null
--and	ct.data_cancellazione 				is null
--and	cl.data_cancellazione 				is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
--and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
--and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
--and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now());


/* 05/10/2017: aggiunto anche il controllo relativo ai parametri degli atti.
	Nelle variabili contaParVarPeg e contaParVarBil sono contenuti il numero di parametri 
	riguardanti le delibere PEG e Bilancio; se sono 3 (numero, anno e tipo) significa
    che quel parametro e' stato passato e quindi devo aggiungere il filtro. 
    Aggiunto anche il controllo relativo alle direzione e settori.
    Se p_code_sac_direz_peg e p_code_sac_direz_bil sono uguali a 999 significa che NON
    sono stati specificati. */
--IF ele_variazioni IS NOT NULL AND ele_variazioni <> '' THEN
IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') OR
	 contaParVarPeg= 3 OR contaParVarBil = 3 OR p_code_sac_direz_peg <> '999' OR
     p_code_sac_direz_bil <> '999' THEN
	sql_query='
    insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio  ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto ,
            siac_d_atto_amm_tipo		tipo_atto,
			siac_r_atto_amm_stato 		r_atto_stato,
	        siac_d_atto_amm_stato 		stato_atto ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto2 ,
            siac_d_atto_amm_tipo		tipo_atto2,
			siac_r_atto_amm_stato 		r_atto_stato2,
	        siac_d_atto_amm_stato 		stato_atto2 ';
    end if;
    IF p_code_sac_direz_peg <> '999'  THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti'; 
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti2'; 
    END IF;
    sql_query=sql_query||'  where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id						=	atto.attoamm_id
    	and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    	and 	atto.attoamm_id										= 	r_atto_stato.attoamm_id
    	and 	r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id_varbil				=	atto2.attoamm_id
    	and		atto2.attoamm_tipo_id								=	tipo_atto2.attoamm_tipo_id
    	and 	atto2.attoamm_id									= 	r_atto_stato2.attoamm_id
    	and 	r_atto_stato2.attoamm_stato_id						=	stato_atto2.attoamm_stato_id ';
    end if;
        
    IF p_code_sac_direz_peg <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id =ele_dir_sett_atti.attoamm_id ';
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id_varbil =ele_dir_sett_atti2.attoamm_id ';
    END IF;
    sql_query=sql_query || ' and		testata_variazione.ente_proprietario_id				= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCodeE|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';
    
    IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    end if;
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||' AND stato_atto.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto.attoamm_numero ='||p_num_provv_var_peg||' 
    	and 	atto.attoamm_anno ='''||p_anno_provv_var_peg||'''
    	and		tipo_atto.attoamm_tipo_code='''||p_tipo_provv_var_peg||''' ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' AND stato_atto2.attoamm_stato_code <> ''ANNULLATO''
        and 	atto2.attoamm_numero ='||p_num_provv_var_bil||' 
    	and 	atto2.attoamm_anno ='''||p_anno_provv_var_bil||'''
    	and		tipo_atto2.attoamm_tipo_code='''||p_tipo_provv_var_bil||''' ';
    end if;
    IF p_code_sac_direz_peg <> '999' THEN
    	IF p_code_sac_sett_peg = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' ';
        ELSIF p_code_sac_sett_peg = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificati un settore.
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''||p_code_sac_sett_peg||'''';
        END IF;
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	IF p_code_sac_sett_bil = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' ';
        ELSIF p_code_sac_sett_bil = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificato un settore.
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''||p_code_sac_sett_bil||'''';
        END IF;
    END IF;
    sql_query=sql_query||' and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query || ' and 	atto.data_cancellazione						is null
    	and 	tipo_atto.data_cancellazione				is null
    	and 	r_atto_stato.data_cancellazione				is null ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query || ' and 	atto2.data_cancellazione		is null
    	and 	tipo_atto2.data_cancellazione				is null
    	and 	r_atto_stato2.data_cancellazione			is null ';
    end if;
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query Var Entrate: % ',  sql_query;      
EXECUTE sql_query;

RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

    insert into siac_rep_var_entrate_riga
    select  tb0.elem_id,     
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            p_anno
    from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno=p_anno
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno=p_anno
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno=p_anno
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno=p_anno
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno=p_anno
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno=p_anno
            and tb6.utente = tb0.utente 	)
      union 
         select  tb0.elem_id,   
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            (p_anno::INTEGER + 1)::varchar
    from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb6.utente = tb0.utente 	)
        union 
        select  tb0.elem_id,    
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            (p_anno::INTEGER + 2)::varchar
        from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb6.utente = tb0.utente 	);



insert into siac_rep_cap_ug 
select 	NULL, --programma.classif_id,
		NULL, --macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
       user_table utente
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
     --siac_d_class_tipo programma_tipo,
     --siac_t_class programma,
    -- siac_d_class_tipo macroaggr_tipo,
     --siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     --siac_r_bil_elem_class r_capitolo_programma,
     --siac_r_bil_elem_class r_capitolo_macroaggr, 
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where 
	--programma_tipo.classif_tipo_code='PROGRAMMA' 							and		
    --programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
   -- programma.classif_id=r_capitolo_programma.classif_id					and
    --macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    --macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    --macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
   	anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCodeS						     	and 
    --capitolo.elem_id=r_capitolo_programma.elem_id							and
    --capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		
    ------cat_del_capitolo.elem_cat_code	=	'STD'	
	--cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC')
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
   	--and	programma_tipo.data_cancellazione 			is null
    --and	programma.data_cancellazione 				is null
    --and	macroaggr_tipo.data_cancellazione 			is null
    --and	macroaggr.data_cancellazione 				is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
    --and	r_capitolo_programma.data_cancellazione 	is null
   	--and	r_capitolo_macroaggr.data_cancellazione 	is null 
	and	stato_capitolo.data_cancellazione 			is null 
    and	r_capitolo_stato.data_cancellazione 		is null
	and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione 			is null;	
    
    
sql_query='
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio  ';
	if contaParVarPeg = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto ,
            siac_d_atto_amm_tipo		tipo_atto,
			siac_r_atto_amm_stato 		r_atto_stato,
	        siac_d_atto_amm_stato 		stato_atto ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto2 ,
            siac_d_atto_amm_tipo		tipo_atto2,
			siac_r_atto_amm_stato 		r_atto_stato2,
	        siac_d_atto_amm_stato 		stato_atto2 ';
    end if;
    IF p_code_sac_direz_peg <> '999'  THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti'; 
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti2'; 
    END IF;                      
    
    sql_query=sql_query||' where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id						=	atto.attoamm_id
    	and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    	and 	atto.attoamm_id										= 	r_atto_stato.attoamm_id
    	and 	r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id_varbil				=	atto2.attoamm_id
    	and		atto2.attoamm_tipo_id								=	tipo_atto2.attoamm_tipo_id
    	and 	atto2.attoamm_id									= 	r_atto_stato2.attoamm_id
    	and 	r_atto_stato2.attoamm_stato_id						=	stato_atto2.attoamm_stato_id ';
    end if;
        
    IF p_code_sac_direz_peg <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id =ele_dir_sett_atti.attoamm_id ';
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id_varbil =ele_dir_sett_atti2.attoamm_id ';
    END IF;
    sql_query=sql_query || ' and		testata_variazione.ente_proprietario_id	= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCodeS|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';
    
IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    end if;
    if contaParVarPeg = 3 then 
    	sql_query=sql_query|| ' AND stato_atto.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto.attoamm_numero ='||p_num_provv_var_peg||' 
    	and 	atto.attoamm_anno ='''||p_anno_provv_var_peg||'''
    	and		tipo_atto.attoamm_tipo_code='''||p_tipo_provv_var_peg||''' ';
    end if;
   
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' AND stato_atto2.attoamm_stato_code <> ''ANNULLATO''  
        and 	atto2.attoamm_numero ='||p_num_provv_var_bil||' 
    	and 	atto2.attoamm_anno ='''||p_anno_provv_var_bil||'''
    	and		tipo_atto2.attoamm_tipo_code='''||p_tipo_provv_var_bil||''' ';
    end if;
    
    IF p_code_sac_direz_peg <> '999' THEN
    	IF p_code_sac_sett_peg = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' ';
        ELSIF p_code_sac_sett_peg = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificati un settore.
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''||p_code_sac_sett_peg||'''';
        END IF;
    END IF;

    IF p_code_sac_direz_bil <> '999' THEN
    	IF p_code_sac_sett_bil = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' ';
        ELSIF p_code_sac_sett_bil = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificato un settore.
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''||p_code_sac_sett_bil||'''';
        END IF;
    END IF;
    
    sql_query=sql_query||' and		r_variazione_stato.data_cancellazione	is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query || ' and 	atto.data_cancellazione						is null
    	and 	tipo_atto.data_cancellazione				is null
    	and 	r_atto_stato.data_cancellazione				is null ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query || ' and 	atto2.data_cancellazione		is null
    	and 	tipo_atto2.data_cancellazione				is null
    	and 	r_atto_stato2.data_cancellazione			is null ';
    end if;
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;


   insert into siac_rep_var_spese_riga
select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=p_anno
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=p_anno
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=p_anno
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=p_anno
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=p_anno
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
   union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
       annocapimp1
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp1
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp1
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp1
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp1
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp1
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp1
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
        union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        annocapimp2
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp2
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp2
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp2
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp2
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp2
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp2
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table    ; 
        
        
end if;

    
-------------------------------------
/*
for tipo_capitolo in
        select t0.anno_competenza, t0.importo, t0.descrizione,
        		t0.posizione_nel_report, t0.codice_importo, t0.tipo_capitolo_cod,
                sum (t1.variazione_aumento_stanziato) variazione_aumento_stanziato,
                sum (t1.variazione_diminuzione_stanziato) variazione_diminuzione_stanziato,
                sum (t1.variazione_aumento_cassa) variazione_aumento_cassa,
                sum (t1.variazione_diminuzione_cassa) variazione_diminuzione_cassa,
                sum (t1.variazione_aumento_residuo) variazione_aumento_residuo,
                sum (t1.variazione_diminuzione_residuo)   variazione_diminuzione_residuo                                                                                              
			from "BILR997_tipo_capitolo_dei_report" (p_ente_prop_id, p_anno) t0,
            	siac_rep_var_entrate_riga t1,
                siac_d_bil_elem_categoria cat_del_capitolo,
    			siac_r_bil_elem_categoria r_cat_capitolo
        	where r_cat_capitolo.elem_cat_id=cat_del_capitolo.elem_cat_id
            	and r_cat_capitolo.elem_id=t1.elem_id
                and cat_del_capitolo.elem_cat_code=t0.codice_importo
                and t1.periodo_anno=t0.anno_competenza
                and t1.utente=user_table
            group by t0.anno_competenza, t0.importo, t0.descrizione,
        		t0.posizione_nel_report, t0.codice_importo, t0.tipo_capitolo_cod
                */
-- INC000001599997 Inizio
/*for tipo_capitolo in
        select t0.*               
			from "BILR997_tipo_capitolo_dei_report" (p_ente_prop_id, p_anno) t0
            	ORDER BY t0.anno_competenza
loop*/
for tipo_capitolo in
        select t0.*               
			from "BILR000_tipo_capitolo_dei_report" (p_ente_prop_id, p_anno, 'G') t0
            	ORDER BY t0.anno_competenza
loop
-- INC000001599997 Fine

importo = tipo_capitolo.importo;
elemCatCode= tipo_capitolo.codice_importo;

IF tipo_capitolo.tipo_capitolo_cod ='CAP-EG' THEN  
	--Cerco i dati delle eventuali variazioni di spesa
--raise notice 'codice importo =%', tipo_capitolo.codice_importo;      
	
--16/03/2017: nel caso di capitoli FPV di entrata devo sommare gli importi
--	dei capitoli FPVSC e FPVCC.
		if tipo_capitolo.codice_importo = 'FPV' then
              --raise notice 'tipo_capitolo.codice_importo=%', variazione_diminuzione_stanziato;
              select      'FPV' elem_cat_code , 
                  coalesce (sum (t1.variazione_aumento_stanziato),0) variazione_aumento_stanziato,
                  coalesce (sum (t1.variazione_diminuzione_stanziato),0) variazione_diminuzione_stanziato,
                  coalesce (sum (t1.variazione_aumento_cassa),0) variazione_aumento_cassa,
                  coalesce (sum (t1.variazione_diminuzione_cassa),0) variazione_diminuzione_cassa,
                  coalesce (sum (t1.variazione_aumento_residuo),0) variazione_aumento_residuo,
                  coalesce (sum (t1.variazione_diminuzione_residuo),0) variazione_diminuzione_residuo                                                                                           
              into elemCatCode,variazione_aumento_stanziato, variazione_diminuzione_stanziato,
                  variazione_aumento_cassa, variazione_diminuzione_cassa,variazione_aumento_residuo,
              variazione_diminuzione_residuo 
              from siac_rep_var_entrate_riga t1,
                  siac_r_bil_elem_categoria r_cat_capitolo,
                  siac_d_bil_elem_categoria cat_del_capitolo            
              WHERE  r_cat_capitolo.elem_id=t1.elem_id
                  AND r_cat_capitolo.elem_cat_id=cat_del_capitolo.elem_cat_id
                  AND t1.utente=user_table
                  AND cat_del_capitolo.elem_cat_code in (tipoFpvcc, tipoFpvsc)
                  AND r_cat_capitolo.data_cancellazione IS NULL
                  AND cat_del_capitolo.data_cancellazione IS NULL
                  AND t1.periodo_anno = tipo_capitolo.anno_competenza
             -- 17/07/2017: commentata la group by per jira SIAC-5105
             	--group by  elem_cat_code  
             ;             
            IF NOT FOUND THEN
                  variazione_aumento_stanziato=0;
                  variazione_diminuzione_stanziato=0;
                  variazione_aumento_cassa=0;
                  variazione_diminuzione_cassa=0;
                  variazione_aumento_residuo=0;
                  variazione_diminuzione_residuo=0;
            end if;
            
            raise notice 'variazione_aumento_stanziato=%', variazione_aumento_stanziato;
            raise notice 'variazione_diminuzione_stanziato=%', variazione_diminuzione_stanziato;

            importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato; 
            else 


               select      cat_del_capitolo.elem_cat_code,
                    coalesce (sum (t1.variazione_aumento_stanziato),0) variazione_aumento_stanziato,
                    coalesce (sum (t1.variazione_diminuzione_stanziato),0) variazione_diminuzione_stanziato,
                    coalesce (sum (t1.variazione_aumento_cassa),0) variazione_aumento_cassa,
                    coalesce (sum (t1.variazione_diminuzione_cassa),0) variazione_diminuzione_cassa,
                    coalesce (sum (t1.variazione_aumento_residuo),0) variazione_aumento_residuo,
                    coalesce (sum (t1.variazione_diminuzione_residuo),0) variazione_diminuzione_residuo                                                                                           
                into elemCatCode,variazione_aumento_stanziato, variazione_diminuzione_stanziato,
                    variazione_aumento_cassa, variazione_diminuzione_cassa,variazione_aumento_residuo,
                variazione_diminuzione_residuo 
                from siac_rep_var_entrate_riga t1,
                    siac_r_bil_elem_categoria r_cat_capitolo,
                    siac_d_bil_elem_categoria cat_del_capitolo            
                WHERE  r_cat_capitolo.elem_id=t1.elem_id
                    AND r_cat_capitolo.elem_cat_id=cat_del_capitolo.elem_cat_id
                    AND t1.utente=user_table
                    AND cat_del_capitolo.elem_cat_code=tipo_capitolo.codice_importo
                    AND r_cat_capitolo.data_cancellazione IS NULL
                    AND cat_del_capitolo.data_cancellazione IS NULL
                    AND t1.periodo_anno = tipo_capitolo.anno_competenza
                group by cat_del_capitolo.elem_cat_code   ; 
                
                IF NOT FOUND THEN
                  variazione_aumento_stanziato=0;
                  variazione_diminuzione_stanziato=0;
                  variazione_aumento_cassa=0;
                  variazione_diminuzione_cassa=0;
                  variazione_aumento_residuo=0;
                  variazione_diminuzione_residuo=0;
                ELSE
                 -- raise notice 'elemCatCode=%', elemCatCode;
                
                  
                  /*IF elemCatCode = tipoAvanzo OR elemCatCode= tipoDisavanzo OR 
                      elemCatCode=tipoFpvcc OR elemCatCode=tipoFpvsc  THEN            
                          importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato;
                  ELSIF elemCatCode = tipoFCassaIni THEN
                      importo =importo+variazione_aumento_cassa+variazione_diminuzione_cassa;              	
                  END IF;    */ 
                  
                  IF elemCatCode = tipoFCassaIni THEN
                      importo =tipo_capitolo.importo+variazione_aumento_cassa+variazione_diminuzione_cassa;  
                  ELSE         
                      importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato;   	
                  END IF;
              
            end if;  
                  
            END IF;     
            
ELSE  --Cerco i dati delle eventuali variazioni di spesa
--raise notice 'codice importo =%', tipo_capitolo.codice_importo;
	select      cat_del_capitolo.elem_cat_code,
			    coalesce (sum (t1.variazione_aumento_stanziato),0) variazione_aumento_stanziato,
                coalesce (sum (t1.variazione_diminuzione_stanziato),0) variazione_diminuzione_stanziato,
                coalesce (sum (t1.variazione_aumento_cassa),0) variazione_aumento_cassa,
                coalesce (sum (t1.variazione_diminuzione_cassa),0) variazione_diminuzione_cassa,
                coalesce (sum (t1.variazione_aumento_residuo),0) variazione_aumento_residuo,
                coalesce (sum (t1.variazione_diminuzione_residuo),0) variazione_diminuzione_residuo                                                                                               
			into elemCatCode,variazione_aumento_stanziato, variazione_diminuzione_stanziato,
            	variazione_aumento_cassa, variazione_diminuzione_cassa,variazione_aumento_residuo,
			variazione_diminuzione_residuo 
            from siac_rep_var_spese_riga t1,
            	siac_r_bil_elem_categoria r_cat_capitolo,
                siac_d_bil_elem_categoria cat_del_capitolo            
            WHERE  r_cat_capitolo.elem_id=t1.elem_id
            	AND r_cat_capitolo.elem_cat_id=cat_del_capitolo.elem_cat_id
            	AND t1.utente=user_table
                AND cat_del_capitolo.elem_cat_code=tipo_capitolo.codice_importo
                AND r_cat_capitolo.data_cancellazione IS NULL
                AND cat_del_capitolo.data_cancellazione IS NULL
                AND t1.periodo_anno = tipo_capitolo.anno_competenza
            group by cat_del_capitolo.elem_cat_code   ; 
            IF NOT FOUND THEN
              variazione_aumento_stanziato=0;
              variazione_diminuzione_stanziato=0;
              variazione_aumento_cassa=0;
              variazione_diminuzione_cassa=0;
              variazione_aumento_residuo=0;
              variazione_diminuzione_residuo=0;
            ELSE
            --raise notice 'elemCatCode=%', elemCatCode;
             /* IF elemCatCode = tipoAvanzo OR elemCatCode= tipoDisavanzo OR 
                  elemCatCode=tipoFpvcc OR elemCatCode=tipoFpvsc OR 
                  elemCatCode= tipoFpvcc OR elemCatCode =tipoFpvsc THEN            
                      importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato;
              ELSIF elemCatCode = tipoFCassaIni THEN
                  importo = importo+variazione_aumento_cassa+variazione_diminuzione_cassa;
              END IF; */  
              importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato;               
            END IF;                    
END IF;
            
--raise notice 'anno_competenza=%', tipo_capitolo.anno_competenza;
--raise notice 'codice_importo=%', tipo_capitolo.codice_importo;
--raise notice 'importo=%', tipo_capitolo.importo;
--raise notice 'variazione_aumento_stanziato=%', variazione_aumento_stanziato;
--raise notice 'variazione_diminuzione_stanziato=%', variazione_diminuzione_stanziato;
--raise notice 'variazione_aumento_cassa=%', variazione_aumento_cassa;
--raise notice 'variazione_diminuzione_cassa=%', variazione_diminuzione_cassa;
--raise notice 'variazione_aumento_residuo=%', variazione_aumento_residuo;
--raise notice 'variazione_diminuzione_residuo=%', variazione_diminuzione_residuo;


anno_competenza = tipo_capitolo.anno_competenza;
descrizione = tipo_capitolo.descrizione;
posizione_nel_report = tipo_capitolo.posizione_nel_report;
codice_importo = tipo_capitolo.codice_importo;
tipo_capitolo_cod = tipo_capitolo.tipo_capitolo_cod;

return next;

variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
anno_competenza = '';
descrizione = '';
posizione_nel_report = 0;
codice_importo = '';
tipo_capitolo_cod = '';
importo=0;

end loop;


delete from siac_rep_cap_ep where utente=user_table;
delete from siac_rep_cap_ug where utente=user_table;

delete from siac_rep_var_entrate where utente=user_table;

delete from siac_rep_var_entrate_riga where utente=user_table;

delete from siac_rep_var_spese where utente=user_table;
delete from siac_rep_var_spese_riga where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
--SIAC-5417 - FINE - Maurizio
--correzione function sovrascritta FINE
CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_liquidazione (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;
IF p_anno_bilancio IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Anno di bilancio nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

esito:= 'Inizio funzione carico liquidazione (FNC_SIAC_DWH_LIQUIDAZIONE) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_liquidazione
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;


INSERT INTO siac.siac_dwh_liquidazione
  (ente_proprietario_id,
   ente_denominazione,
   bil_anno,
   cod_fase_operativa,
   desc_fase_operativa,
   anno_liquidazione,
   num_liquidazione,
   desc_liquidazione,
   data_emissione_liquidazione,
   importo_liquidazione,
   liquidazione_automatica,
   liquidazione_convalida_manuale,
   cod_stato_liquidazione,
   desc_stato_liquidazione,
   cod_conto_tesoreria,
   decrizione_conto_tesoreria,
   cod_distinta,
   desc_distinta,
   soggetto_id,
   cod_soggetto,
   desc_soggetto,
   cf_soggetto,
   cf_estero_soggetto,
   p_iva_soggetto,
   soggetto_id_mod_pag,
   cod_soggetto_mod_pag,
   desc_soggetto_mod_pag,
   cf_soggetto_mod_pag,
   cf_estero_soggetto_mod_pag,
   p_iva_soggetto_mod_pag,
   cod_tipo_accredito,
   desc_tipo_accredito,
   mod_pag_id,
   quietanziante,
   data_nascita_quietanziante,
   luogo_nascita_quietanziante,
   stato_nascita_quietanziante,
   bic,
   contocorrente,
   intestazione_contocorrente,
   iban,
   note_mod_pag,
   data_scadenza_mod_pag,
   anno_impegno,
   num_impegno,
   cod_impegno,
   desc_impegno,
   cod_subimpegno,
   desc_subimpegno,
   cod_tipo_atto_amministrativo,
   desc_tipo_atto_amministrativo,
   desc_stato_atto_amministrativo,
   anno_atto_amministrativo,
   num_atto_amministrativo,
   oggetto_atto_amministrativo,
   note_atto_amministrativo,
   cod_spesa_ricorrente,
   desc_spesa_ricorrente,
   cod_perimetro_sanita_spesa,
   desc_perimetro_sanita_spesa,
   cod_politiche_regionali_unit,
   desc_politiche_regionali_unit,
   cod_transazione_ue_spesa,
   desc_transazione_ue_spesa,
   cod_pdc_finanziario_i,
   desc_pdc_finanziario_i,
   cod_pdc_finanziario_ii,
   desc_pdc_finanziario_ii,
   cod_pdc_finanziario_iii,
   desc_pdc_finanziario_iii,
   cod_pdc_finanziario_iv,
   desc_pdc_finanziario_iv,
   cod_pdc_finanziario_v,
   desc_pdc_finanziario_v,
   cod_pdc_economico_i,
   desc_pdc_economico_i,
   cod_pdc_economico_ii,
   desc_pdc_economico_ii,
   cod_pdc_economico_iii,
   desc_pdc_economico_iii,
   cod_pdc_economico_iv,
   desc_pdc_economico_iv,
   cod_pdc_economico_v,
   desc_pdc_economico_v,
   cod_cofog_divisione,
   desc_cofog_divisione,
   cod_cofog_gruppo,
   desc_cofog_gruppo,
   cup,
   cig,
   cod_cdr_atto_amministrativo,
   desc_cdr_atto_amministrativo,
   cod_cdc_atto_amministrativo,
   desc_cdc_atto_amministrativo,
   data_inizio_val_stato_liquidaz,
   data_inizio_val_liquidaz,
   data_creazione_liquidaz,
   data_modifica_liquidaz,
   tipo_cessione, -- 04.07.2017 Sofia SIAC-5040
   cod_cessione,  -- 04.07.2017 Sofia SIAC-5040
   desc_cessione,  -- 04.07.2017 Sofia SIAC-5040
   soggetto_csc_id
   )
select tb.ente_proprietario_id v_ente_proprietario_id,
tb.ente_denominazione v_ente_denominazione, tb.anno v_anno, tb.v_fase_operativa_code v_fase_operativa_code,
tb.v_fase_operativa_desc v_fase_operativa_desc, tb.liq_anno v_liq_anno,tb.liq_numero v_liq_numero,
tb.liq_desc,
tb.liq_emissione_data::date v_liq_emissione_data,tb.liq_importo v_liq_importo, tb.liq_automatica v_liq_automatica,
tb.liq_convalida_manuale v_liq_convalida_manuale,tb.liq_stato_code v_liq_stato_code,tb.liq_stato_desc v_liq_stato_desc,
tb.contotes_code v_contotes_code,tb.contotes_desc v_contotes_desc,tb.dist_code v_dist_code,tb.dist_desc v_dist_desc,
tb.soggetto_id v_sogg_id,tb.v_codice_soggetto,tb.v_descrizione_soggetto,tb.v_codice_fiscale_soggetto,
tb.v_codice_fiscale_estero_soggetto,tb.v_partita_iva_soggetto,tb.v_soggetto_id_modpag,tb.v_codice_soggetto_modpag,
tb.v_descrizione_soggetto_modpag,
tb.v_codice_fiscale_soggetto_modpag,
tb.v_codice_fiscale_estero_soggetto_modpag,
tb.v_partita_iva_soggetto_modpag,
tb.v_codice_tipo_accredito,tb.v_descrizione_tipo_accredito,
tb.v_modpag_cessione_id,
tb.v_quietanziante,tb.v_data_nascita_quietanziante,
tb.v_luogo_nascita_quietanziante,
tb.v_stato_nascita_quietanziante,
tb.v_bic,
tb.v_contocorrente,
tb.v_intestazione_contocorrente,
tb.v_iban,
tb.v_note_modalita_pagamento, --case when tb.v_note_modalita_pagamento ='' then null else tb.v_note_modalita_pagamento end v_note_modalita_pagamento,
tb.v_data_scadenza_modalita_pagamento,
tb.v_anno_impegno,tb.v_numero_impegno,
tb.v_codice_impegno,
tb.v_descrizione_impegno,
tb.v_codice_subimpegno,
tb.v_descrizione_subimpegno,
tb.attoamm_tipo_code v_codice_tipo_atto_amministrativo, tb.attoamm_tipo_desc v_descrizione_tipo_atto_amministrativo, 
tb.attoamm_stato_desc v_descrizione_stato_atto_amministrativo,tb.attoamm_anno v_anno_atto_amministrativo,
tb.attoamm_numero v_numero_atto_amministrativo, 
tb.attoamm_oggetto,
tb.attoamm_note,
tb.v_codice_spesa_ricorrente, tb.v_descrizione_spesa_ricorrente,
tb.v_codice_perimetro_sanitario_spesa, tb.v_descrizione_perimetro_sanitario_spesa,
tb.v_codice_politiche_regionali_unitarie, tb.v_descrizione_politiche_regionali_unitarie,
tb.v_codice_transazione_spesa_ue, tb.v_descrizione_transazione_spesa_ue,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_I else tb.pdc4_codice_pdc_finanziario_I end v_codice_pdc_finanziario_I,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_I else tb.pdc4_descrizione_pdc_finanziario_I end v_descrizione_pdc_finanziario_I,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_II else tb.pdc4_codice_pdc_finanziario_II end v_codice_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_II else tb.pdc4_descrizione_pdc_finanziario_II end v_descrizione_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_III else tb.pdc4_codice_pdc_finanziario_III end v_codice_pdc_finanziario_III,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_III else tb.pdc4_descrizione_pdc_finanziario_III end v_descrizione_pdc_finanziario_III,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_IV else tb.pdc4_codice_pdc_finanziario_IV end v_codice_pdc_finanziario_IV  ,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_IV else tb.pdc4_descrizione_pdc_finanziario_IV end v_descrizione_pdc_finanziario_IV,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_V end v_codice_pdc_finanziario_V  ,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_V end v_descrizione_pdc_finanziario_V,
null::varchar v_codice_pdc_economico_I,--case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_I else tb.pce4_codice_pdc_economico_I end codice_pdc_economico_I,
null::varchar v_descrizione_pdc_economico_I,--case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_I else tb.pce4_descrizione_pdc_economico_I end descrizione_pdc_economico_I,
null::varchar v_codice_pdc_economico_II,--case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_II else tb.pce4_codice_pdc_economico_II end codice_pdc_economico_II,
null::varchar v_descrizione_pdc_economico_II,--case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_II else tb.pce4_descrizione_pdc_economico_II end descrizione_pdc_economico_II,
null::varchar v_codice_pdc_economico_III,--case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_III else tb.pce4_codice_pdc_economico_III end codice_pdc_economico_III,
null::varchar v_descrizione_pdc_economico_III,--case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_III else tb.pce4_descrizione_pdc_economico_III end descrizione_pdc_economico_III,
null::varchar v_codice_pdc_economico_IV,--case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_IV else tb.pce4_codice_pdc_economico_IV end codice_pdc_economico_IV  ,
null::varchar v_descrizione_pdc_economico_IV,--case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_IV else tb.pce4_descrizione_pdc_economico_IV end descrizione_pdc_economico_IV,
null::varchar v_codice_pdc_economico_V,--case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_V end codice_pdc_economico_V  ,
null::varchar v_descrizione_pdc_economico_V,--case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_V end descrizione_pdc_economico_V
tb.codice_cofog_divisione v_codice_cofog_divisione,
tb.descrizione_cofog_divisione v_escrizione_cofog_divisione,
tb.codice_cofog_gruppo v_codice_cofog_gruppo,
tb.descrizione_cofog_gruppo v_descrizione_cofog_gruppo,
tb.v_cup,
tb.v_cig,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdr_code::varchar else tb.cdr_cdr_code::varchar end v_cod_cdr_atto_amministrativo,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdr_desc::varchar else tb.cdr_cdr_desc::varchar end v_desc_cdr_atto_amministrativo,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdc_code::varchar else tb.cdr_cdc_code::varchar end v_cod_cdc_atto_amministrativo,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdc_desc::varchar else tb.cdr_cdc_desc::varchar end v_desc_cdc_atto_amministrativo,
tb.data_inizio_val_stato_liquidaz v_data_inizio_val_stato_liquidaz,
tb.data_inizio_val_liquidaz v_data_inizio_val_liquidaz,
tb.data_creazione_liquidaz v_data_creazione_liquidaz,
tb.data_modifica_liquidaz v_data_modifica_liquidaz,
tb.v_tipo_cessione,
tb.v_cod_cessione,
tb.v_desc_cessione,
tb.v_soggetto_csc_id
from (
with liq as (
SELECT 
a.dist_id,
 a.contotes_id,
b.ente_proprietario_id, b.ente_denominazione, d.anno,
a.liq_anno, a.liq_numero, a.liq_desc, a.liq_emissione_data, a.liq_importo, a.liq_automatica,
a.liq_convalida_manuale, a.modpag_id, a.soggetto_relaz_id, -- 04.07.2017 Sofia SIAC-5040
f.liq_stato_code, f.liq_stato_desc,
h.fase_operativa_code v_fase_operativa_code, h.fase_operativa_desc v_fase_operativa_desc,
a.liq_id, c.bil_id,
e.validita_inizio as data_inizio_val_stato_liquidaz,
a.validita_inizio as data_inizio_val_liquidaz,
a.data_creazione as data_creazione_liquidaz,
a.data_modifica as data_modifica_liquidaz
FROM   siac_t_liquidazione a
, siac_t_ente_proprietario b 
, siac_t_bil c  
, siac_t_periodo d 
, siac_r_liquidazione_stato e  
, siac_d_liquidazione_stato f  
, siac_r_bil_fase_operativa g
, siac_d_fase_operativa h
where 
 b.ente_proprietario_id = a.ente_proprietario_id and
 a.bil_id = c.bil_id and 
 d.periodo_id = c.periodo_id and 
 a.liq_id = e.liq_id and 
 e.liq_stato_id = f.liq_stato_id and 
 b.ente_proprietario_id = p_ente_proprietario_id
AND d.anno = p_anno_bilancio
and g.bil_id=c.bil_id
and h.fase_operativa_id = g.fase_operativa_id
and p_data BETWEEN g.validita_inizio AND COALESCE(g.validita_fine, p_data)
and g.data_cancellazione is null
and h.data_cancellazione is null
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND a.data_cancellazione IS NULL
AND p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
AND b.data_cancellazione IS NULL
AND p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
AND c.data_cancellazione IS NULL
AND p_data BETWEEN d.validita_inizio AND COALESCE(d.validita_fine, p_data)
AND d.data_cancellazione IS NULL
AND p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
AND e.data_cancellazione IS NULL
AND p_data BETWEEN f.validita_inizio AND COALESCE(f.validita_fine, p_data)
AND f.data_cancellazione IS NULL)
,
contotes as (
select contotes_id,validita_inizio, data_cancellazione,
contotes_code, contotes_desc
  From siac_d_contotesoreria a where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null and 
  p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
dist as (  
  select dist_id,dist_code, dist_desc
  From siac_d_distinta a where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null and 
  p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)  
),
sog as (
select tb2.* from (
 with soggtot as (
select tb.soggetto_id,tb.liq_id from ( 
with sogg as (  
select 
a.soggetto_id, a.liq_id
  From siac_r_liquidazione_soggetto a where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null and 
  p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data))    
, soggintest as (  
SELECT a.soggetto_id_da v_soggetto_id_intestatario
FROM siac_r_soggetto_relaz a, siac_d_relaz_tipo b
WHERE 
a.ente_proprietario_id = p_ente_proprietario_id and 
a.relaz_tipo_id = b.relaz_tipo_id
AND   b.relaz_tipo_code  = 'SEDE_SECONDARIA'
--AND   a.soggetto_id_a = v_soggetto_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
--AND   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL)
select case when soggintest.v_soggetto_id_intestatario
is null then sogg.soggetto_id else soggintest.v_soggetto_id_intestatario END as soggetto_id,
sogg.liq_id
  from sogg left join soggintest
on soggintest.v_soggetto_id_intestatario = sogg.soggetto_id
) as tb 
),
tsog as (
select * from siac_t_soggetto c where c.ente_proprietario_id=p_ente_proprietario_id and c.data_cancellazione is null)
select 
soggtot.liq_id,
soggtot.soggetto_id,
tsog.soggetto_code v_codice_soggetto, 
tsog.soggetto_desc v_descrizione_soggetto,
 tsog.codice_fiscale v_codice_fiscale_soggetto, 
 tsog.codice_fiscale_estero v_codice_fiscale_estero_soggetto, 
 tsog.partita_iva v_partita_iva_soggetto
 from  soggtot join tsog
on soggtot.soggetto_id=tsog.soggetto_id
) as tb2
),
modpag as 
(select a.soggetto_id , a.modpag_id,
a.accredito_tipo_id, a.quietanziante, a.quietanzante_nascita_data, a.quietanziante_nascita_luogo,
a.quietanziante_nascita_stato, a.bic, a.contocorrente, a.contocorrente_intestazione, a.iban,
a.note, a.data_scadenza ,
null::varchar oil_relaz_tipo_code, null::varchar relaz_tipo_code, null::varchar relaz_tipo_desc,
s.soggetto_code, s.soggetto_desc, s.codice_fiscale, s.codice_fiscale_estero, s.partita_iva,
b.accredito_tipo_code , b.accredito_tipo_desc 
FROM  siac_t_modpag a, siac_t_soggetto s ,siac_d_accredito_tipo b
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id and 
p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
and s.soggetto_id=a.soggetto_id
and b.accredito_tipo_id=a.accredito_tipo_id
and b.data_Cancellazione is null
),
modpagoil as 
(select 
rel.soggetto_relaz_id,
rel.soggetto_id_a soggetto_id, mdp.modpag_id,
        mdp.accredito_tipo_id, mdp.quietanziante, mdp.quietanzante_nascita_data, mdp.quietanziante_nascita_luogo,
        mdp.quietanziante_nascita_stato, mdp.bic, mdp.contocorrente, mdp.contocorrente_intestazione, mdp.iban,
        mdp.note, mdp.data_scadenza,
        oil.oil_relaz_tipo_code,tipo.relaz_tipo_code, tipo.relaz_tipo_desc,
s.soggetto_code, s.soggetto_desc, s.codice_fiscale, s.codice_fiscale_estero, s.partita_iva,
b.accredito_tipo_code , b.accredito_tipo_desc          
 FROM  siac_r_soggetto_relaz rel, siac_r_soggrel_modpag sogrel, siac_t_modpag mdp,
       siac_r_oil_relaz_tipo roil, siac_d_relaz_tipo tipo , siac_d_oil_relaz_tipo oil,
       siac_t_soggetto s,siac_d_accredito_tipo b
 WHERE
 rel.ente_proprietario_id=p_ente_proprietario_id 
 and   sogrel.soggetto_relaz_id=rel.soggetto_relaz_id
 and   mdp.modpag_id=sogrel.modpag_id
 and   tipo.relaz_tipo_id=rel.relaz_tipo_id
 and   roil.relaz_tipo_id=tipo.relaz_tipo_id
 and   oil.oil_relaz_tipo_id=roil.oil_relaz_tipo_id
 AND   p_data BETWEEN rel.validita_inizio AND COALESCE(rel.validita_fine, p_data)
 AND   p_data BETWEEN sogrel.validita_inizio AND COALESCE(sogrel.validita_fine, p_data)
 AND   p_data BETWEEN mdp.validita_inizio AND COALESCE(mdp.validita_fine, p_data)
 AND   p_data BETWEEN roil.validita_inizio AND COALESCE(roil.validita_fine, p_data)
 AND   rel.data_cancellazione IS NULL
 AND   sogrel.data_cancellazione IS NULL
 AND   mdp.data_cancellazione IS NULL
 AND   roil.data_cancellazione IS NULL
 and s.soggetto_id=rel.soggetto_id_a
 and b.accredito_tipo_id=mdp.accredito_tipo_id
and b.data_Cancellazione is null
 ),
movgest as (
SELECT d.liq_id,
a.movgest_ts_id,
a.movgest_ts_code, a.movgest_ts_desc, b.movgest_ts_tipo_code,
       c.movgest_anno, c.movgest_numero
FROM  siac_t_movgest_ts a, siac_d_movgest_ts_tipo b, siac_t_movgest c,
siac_r_liquidazione_movgest d
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id  
and d.movgest_ts_id=a.movgest_ts_id
AND   a.movgest_ts_tipo_id = b.movgest_ts_tipo_id
AND   c.movgest_id = a.movgest_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
AND   p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
AND   p_data BETWEEN d.validita_inizio AND COALESCE(c.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
)
, pdc5 as (
select distinct 
r.liq_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
a2.classif_code pdc5_codice_pdc_finanziario_IV,a2.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_liquidazione_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pdc4 as (
select distinct r.liq_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
a2.classif_code pdc4_codice_pdc_finanziario_III,a2.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_liquidazione_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
),
ricspesa as (
SELECT 
a.liq_id ,b.classif_code v_codice_spesa_ricorrente, b.classif_desc v_descrizione_spesa_ricorrente
 from siac_r_liquidazione_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='RICORRENTE_SPESA'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
transue as (
SELECT 
a.liq_id ,b.classif_code v_codice_transazione_spesa_ue, b.classif_desc v_descrizione_transazione_spesa_ue
 from siac_r_liquidazione_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
), 
perss as (
SELECT 
a.liq_id ,b.classif_code v_codice_perimetro_sanitario_spesa, b.classif_desc v_descrizione_perimetro_sanitario_spesa
from siac_r_liquidazione_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='PERIMETRO_SANITARIO_SPESA'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
), 
pru as (
SELECT 
a.liq_id ,b.classif_code v_codice_politiche_regionali_unitarie, b.classif_desc v_descrizione_politiche_regionali_unitarie
from siac_r_liquidazione_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='POLITICHE_REGIONALI_UNITARIE'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
),
cofog as (
select distinct r.liq_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
a2.classif_code codice_cofog_divisione,a2.classif_desc descrizione_cofog_divisione
from 
siac_r_liquidazione_class r,
siac_t_class a,siac_d_class_tipo b, 
--DIVISIONE_COFOG
siac_r_class_fam_tree d2,
siac_t_class a2
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='GRUPPO_COFOG'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine, p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null),
cig as (
SELECT 
a.liq_id
, a.testo v_cig
FROM   siac_r_liquidazione_attr a, siac_t_attr b
WHERE 
b.attr_code='cig' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL),
csc as (SELECT 
a.liq_id,
d.soggetto_id_da v_soggetto_csc_id,
             g.oil_relaz_tipo_code v_tipo_cessione,
             f.relaz_tipo_code v_cod_cessione,
             f.relaz_tipo_desc v_desc_cessione
      FROM siac_r_subdoc_liquidazione a,
           siac_r_subdoc_modpag b,
           siac_r_soggrel_modpag c,
           siac_r_soggetto_relaz d,
           siac_r_oil_relaz_tipo e,
           siac_d_relaz_tipo f,
           siac_d_oil_relaz_tipo g
      WHERE 
      a.ente_proprietario_id=p_ente_proprietario_id and 
            g.oil_relaz_tipo_code = 'CSC' AND
            a.subdoc_id = b.subdoc_id AND
            c.modpag_id = b.modpag_id AND
            c.soggetto_relaz_id = d.soggetto_relaz_id AND
            d.relaz_tipo_id = e.relaz_tipo_id AND
            f.relaz_tipo_id = e.relaz_tipo_id AND
            g.oil_relaz_tipo_id = e.oil_relaz_tipo_id AND
            p_data BETWEEN a.validita_inizio AND
            COALESCE(a.validita_fine, p_data) AND
            p_data BETWEEN b.validita_inizio AND
            COALESCE(b.validita_fine, p_data) AND
            p_data BETWEEN c.validita_inizio AND
            COALESCE(c.validita_fine, p_data) AND
            p_data BETWEEN d.validita_inizio AND
            COALESCE(d.validita_fine, p_data) AND
            p_data BETWEEN e.validita_inizio AND
            COALESCE(e.validita_fine, p_data) AND
            a.data_cancellazione is null AND
            b.data_cancellazione is null AND
            c.data_cancellazione is null AND
            d.data_cancellazione is null AND
            e.data_cancellazione is null AND
            f.data_cancellazione is null AND
            g.data_cancellazione is null),
cup as (
SELECT 
a.liq_id
, a.testo v_cup
FROM   siac_r_liquidazione_attr a, siac_t_attr b
WHERE 
b.attr_code='cup' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL),
--atto amm
attoamm as (
with atmc as (
with atm as (
SELECT 
a.liq_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM 
siac.siac_r_liquidazione_atto_amm a, 
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c, 
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id 
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
--AND  
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
)
, atmrclass as (select a.attoamm_id,a.classif_id from siac_r_atto_amm_class a where 
a.ente_proprietario_id=p_ente_proprietario_id and 
a.data_cancellazione is null and 
 p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
select atm.*,atmrclass.classif_id from atm left join atmrclass
on atmrclass.attoamm_id=atm.attoamm_id
)
,
cdc as (
select a.classif_id,a.classif_code cdc_cdc_code,a.classif_desc cdc_cdc_desc
,a2.classif_code cdc_cdr_code,a2.classif_desc cdc_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b, siac_r_class_fam_tree c,siaC_t_class a2
where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDC'
and c.classif_id=a.classif_id
and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
and a2.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a2.data_cancellazione is null)
,cdr as (
select a.classif_id,null cdr_cdc_code,null cdr_cdc_desc
,a.classif_code cdr_cdr_code,a.classif_desc cdr_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b
 where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDR'
and a.data_cancellazione is null
and b.data_cancellazione is null)
select 
atmc.liq_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on 
atmc.classif_id=cdc.classif_id
left join cdr on 
atmc.classif_id=cdr.classif_id)
select liq.*, contotes.validita_inizio, contotes.data_cancellazione ,
contotes.contotes_code, contotes.contotes_desc, dist.dist_code, dist.dist_desc,
sog.soggetto_id,
sog.v_codice_soggetto, 
sog.v_descrizione_soggetto,
sog.v_codice_fiscale_soggetto, 
sog.v_codice_fiscale_estero_soggetto, 
sog.v_partita_iva_soggetto,
case when modpagoil.modpag_id is null then 
modpag.soggetto_id else modpagoil.soggetto_id end v_soggetto_id_modpag,
case when modpagoil.modpag_id is null then 
modpag.modpag_id else modpagoil.modpag_id end v_modpag_cessione_id,
case when modpagoil.modpag_id is null then 
modpag.accredito_tipo_id else modpagoil.accredito_tipo_id end v_accredito_tipo_id,
case when modpagoil.modpag_id is null then 
modpag.quietanziante else modpagoil.quietanziante end v_quietanziante,
case when modpagoil.modpag_id is null then 
modpag.quietanzante_nascita_data else modpagoil.quietanzante_nascita_data end v_data_nascita_quietanziante,
case when modpagoil.modpag_id is null then 
modpag.quietanziante_nascita_luogo else modpagoil.quietanziante_nascita_luogo end v_luogo_nascita_quietanziante,
case when modpagoil.modpag_id is null then 
modpag.quietanziante_nascita_stato else modpagoil.quietanziante_nascita_stato end v_stato_nascita_quietanziante,
case when modpagoil.modpag_id is null then 
modpag.bic else modpagoil.bic end v_bic,
case when modpagoil.modpag_id is null then 
modpag.contocorrente else modpagoil.contocorrente end v_contocorrente,
case when modpagoil.modpag_id is null then 
modpag.contocorrente_intestazione else modpagoil.contocorrente_intestazione end v_intestazione_contocorrente,
case when modpagoil.modpag_id is null then 
modpag.iban else modpagoil.iban end v_iban,
case when modpagoil.modpag_id is null then 
modpag.note else modpagoil.note end v_note_modalita_pagamento,
case when modpagoil.modpag_id is null then 
modpag.data_scadenza else modpagoil.data_scadenza end v_data_scadenza_modalita_pagamento,
case when modpagoil.modpag_id is null then 
modpag.oil_relaz_tipo_code else modpagoil.oil_relaz_tipo_code end v_tipo_cessione,
case when modpagoil.modpag_id is null then 
modpag.relaz_tipo_code else modpagoil.relaz_tipo_code end v_cod_cessione,
case when modpagoil.modpag_id is null then 
modpag.relaz_tipo_desc else modpagoil.relaz_tipo_desc end v_desc_cessione,
case when modpagoil.modpag_id is null then 
modpag.soggetto_code else modpagoil.soggetto_code end v_codice_soggetto_modpag,
case when modpagoil.modpag_id is null then 
modpag.soggetto_desc else modpagoil.soggetto_desc end v_descrizione_soggetto_modpag,
case when modpagoil.modpag_id is null then 
modpag.codice_fiscale else modpagoil.codice_fiscale end v_codice_fiscale_soggetto_modpag,
case when modpagoil.modpag_id is null then 
modpag.codice_fiscale_estero else modpagoil.codice_fiscale_estero end v_codice_fiscale_estero_soggetto_modpag,
case when modpagoil.modpag_id is null then   
modpag.partita_iva else modpagoil.partita_iva end v_partita_iva_soggetto_modpag,
case when modpagoil.modpag_id is null then   
modpag.accredito_tipo_code else modpagoil.accredito_tipo_code end v_codice_tipo_accredito,
case when modpagoil.modpag_id is null then   
modpag.accredito_tipo_desc else modpagoil.accredito_tipo_desc end v_descrizione_tipo_accredito,
case when movgest.movgest_ts_tipo_code = 'T' then  movgest.movgest_ts_code else NULL::varchar end v_codice_impegno,
case when movgest.movgest_ts_tipo_code = 'T' then  movgest.movgest_ts_desc else NULL::varchar end v_descrizione_impegno,
case when movgest.movgest_ts_tipo_code = 'S' then  movgest.movgest_ts_code else NULL::varchar end v_codice_subimpegno,
case when movgest.movgest_ts_tipo_code = 'S' then  movgest.movgest_ts_desc else NULL::varchar end v_descrizione_subimpegno,
movgest.movgest_ts_tipo_code v_movgest_ts_tipo_code,movgest.movgest_anno v_anno_impegno, movgest.movgest_numero v_numero_impegno,
pdc5.pdc5_codice_pdc_finanziario_V,pdc5.pdc5_descrizione_pdc_finanziario_V,
pdc5.pdc5_codice_pdc_finanziario_IV,pdc5.pdc5_descrizione_pdc_finanziario_IV,
pdc5.pdc5_codice_pdc_finanziario_III,pdc5.pdc5_descrizione_pdc_finanziario_III,
pdc5.pdc5_codice_pdc_finanziario_II,pdc5.pdc5_descrizione_pdc_finanziario_II,
pdc5.pdc5_codice_pdc_finanziario_I,pdc5.pdc5_descrizione_pdc_finanziario_I,
pdc4.pdc4_codice_pdc_finanziario_IV,pdc4.pdc4_descrizione_pdc_finanziario_IV,
pdc4.pdc4_codice_pdc_finanziario_III,pdc4.pdc4_descrizione_pdc_finanziario_III,
pdc4.pdc4_codice_pdc_finanziario_II,pdc4.pdc4_descrizione_pdc_finanziario_II,
pdc4.pdc4_codice_pdc_finanziario_I,pdc4.pdc4_descrizione_pdc_finanziario_I,
ricspesa.v_codice_spesa_ricorrente, ricspesa.v_descrizione_spesa_ricorrente,
transue.v_codice_transazione_spesa_ue, transue.v_descrizione_transazione_spesa_ue,
perss.v_codice_perimetro_sanitario_spesa, perss.v_descrizione_perimetro_sanitario_spesa,
pru.v_codice_politiche_regionali_unitarie, pru.v_descrizione_politiche_regionali_unitarie,
cofog.codice_cofog_gruppo,
cofog.descrizione_cofog_gruppo,
cofog.codice_cofog_divisione,
cofog.descrizione_cofog_divisione,
cup.v_cup,
cig.v_cig,
attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,
csc.v_soggetto_csc_id
from liq
left join contotes on contotes.contotes_id=liq.contotes_id
left join dist on dist.dist_id=liq.dist_id
left join sog on sog.liq_id=liq.liq_id
left join modpag on modpag.modpag_id=liq.modpag_id
left join modpagoil on modpagoil.soggetto_relaz_id=liq.soggetto_relaz_id
left join movgest on movgest.liq_id=liq.liq_id
left join pdc5
on liq.liq_id=pdc5.liq_id  
left join pdc4
on liq.liq_id=pdc4.liq_id 
left join ricspesa
on liq.liq_id=ricspesa.liq_id 
left join transue
on liq.liq_id=transue.liq_id 
left join perss
on liq.liq_id=perss.liq_id 
left join pru
on liq.liq_id=pru.liq_id 
left join cofog
on liq.liq_id=cofog.liq_id  
left join cig
on liq.liq_id=cig.liq_id  
left join cup
on liq.liq_id=cup.liq_id  
left join attoamm 
on liq.liq_id=attoamm.liq_id
left join csc 
on liq.liq_id=csc.liq_id
) as tb;   
  

esito:= 'Fine funzione carico liquidazione (FNC_SIAC_DWH_LIQUIDAZIONE) - '||clock_timestamp();
RETURN NEXT;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico liquidazione (FNC_SIAC_DWH_LIQUIDAZIONE) terminata con errori';
  RAISE EXCEPTION '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;
--correzione function sovrascritta INIZIO