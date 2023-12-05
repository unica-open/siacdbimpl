/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR152_elenco_doc_entrata" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_provv integer,
  p_anno_provv varchar,
  p_tipo_provv varchar,
  p_cdr varchar,
  p_cdc varchar
)
RETURNS TABLE (
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_code3 varchar,
  doc_anno integer,
  doc_numero varchar,
  subdoc_numero integer,
  tipo_doc varchar,
  conto_dare varchar,
  conto_avere varchar,
  num_accertamento numeric,
  anno_accertamento integer,
  num_subaccertamento varchar,
  tipo_accert varchar,
  code_soggetto varchar,
  desc_soggetto varchar,
  num_reversale varchar,
  anno_reversale integer,
  importo_quota numeric,
  doc_id integer,
  subdoc_id integer,
  display_error varchar
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
anno_eser_int integer;
 
tipo_sac varchar;
var_sac varchar;
estremi_provv varchar;
atto_id integer;

BEGIN

bil_ele_code:='';
bil_ele_desc:='';
bil_ele_code2:='';
bil_ele_desc2:='';
bil_ele_code3:='';
doc_anno:=0;
doc_numero:='';
subdoc_numero:=0;
tipo_doc:='';
conto_dare:='';
conto_avere:='';
num_accertamento:=0;
anno_accertamento:=0;
num_subaccertamento:='';
tipo_accert:='';
code_soggetto:='';
desc_soggetto:=0;
num_reversale:='';
anno_reversale:=0;
importo_quota:=0;


anno_eser_int=p_anno ::INTEGER;

--15/04/2020 SIAC-7498.
-- Introdotte le modifiche per la gestione della SAC (Direzione/Settore) collegata all'atto.
-- La SAC puo' non essere specificata; viene verificata l'esistenza dell'atto indicato in
-- input e nel caso non esista o ne esista piu' di 1 e' restituito un errore.

display_error:='';
estremi_provv:= ' Numero: '|| p_numero_provv|| ' Anno: '||p_anno_provv||' Tipo: '||p_tipo_provv;

if p_cdr IS not null and trim(p_cdr) <> '' and p_cdr <> '999' then
	if p_cdc IS not null and trim(p_cdc) <> '' and p_cdc <> '999' then
    	tipo_sac:= 'CDC';
        var_sac:=p_cdc;
        estremi_provv:=estremi_provv|| ' SAC: '||p_cdc;
    else
    	tipo_sac:= 'CDR';
        var_sac:=p_cdr;
        estremi_provv:=estremi_provv|| ' SAC: '||p_cdr;
    end if;
else
	tipo_sac:= '';
    var_sac:='';
end if;

--specificata la SAC
if tipo_sac <> '' then
  begin
      select t_atto_amm.attoamm_id
          into STRICT  atto_id
      from siac_t_atto_amm t_atto_amm,
          siac_r_atto_amm_class r_atto_amm_class,
          siac_t_class t_class,
          siac_d_class_tipo d_class_tipo,
          siac_d_atto_amm_tipo	tipo_atto
      where t_atto_amm.attoamm_id=r_atto_amm_class.attoamm_id
        and r_atto_amm_class.classif_id=t_class.classif_id
        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
        and t_atto_amm.attoamm_tipo_id=tipo_atto.attoamm_tipo_id
        and t_atto_amm.ente_proprietario_id =p_ente_prop_id
        and t_atto_amm.attoamm_anno=p_anno_provv
        and t_atto_amm.attoamm_numero=p_numero_provv
        and tipo_atto.attoamm_tipo_code=p_tipo_provv
        and t_class.classif_code=var_sac
        and t_atto_amm.data_cancellazione IS NULL
        and r_atto_amm_class.data_cancellazione IS NULL
        and t_class.data_cancellazione IS NULL
        and d_class_tipo.data_cancellazione IS NULL
        and tipo_atto.data_cancellazione IS NULL;  
  EXCEPTION        
  WHEN NO_DATA_FOUND THEN
        raise notice 'atto_id = %', atto_id;
            display_error := 'Non esiste un provvedimento '||estremi_provv;
            return next;
            return;         
     WHEN TOO_MANY_ROWS THEN
        raise notice 'atto_id = %', atto_id;
              display_error := 'Esistono  piu'' provvedimenti '||estremi_provv;
              return next;
              return;     
  end;
ELSE
	begin
        select t_atto_amm.attoamm_id
            into STRICT atto_id
        from siac_t_atto_amm t_atto_amm,        
            siac_d_atto_amm_tipo	tipo_atto
        where t_atto_amm.attoamm_tipo_id=tipo_atto.attoamm_tipo_id
          and t_atto_amm.ente_proprietario_id =p_ente_prop_id
          and t_atto_amm.attoamm_anno=p_anno_provv
          and t_atto_amm.attoamm_numero=p_numero_provv
          and tipo_atto.attoamm_tipo_code=p_tipo_provv
          and t_atto_amm.data_cancellazione IS NULL
          and tipo_atto.data_cancellazione IS NULL
        group by t_atto_amm.attoamm_id;
      EXCEPTION        
        WHEN NO_DATA_FOUND THEN
              raise notice 'atto_id = %', atto_id;
                  display_error := 'Non esiste un provvedimento '||estremi_provv;
                  return next;
                  return;         
           WHEN TOO_MANY_ROWS THEN
              raise notice 'atto_id = %', atto_id;
                    display_error := 'Esistono piu'' provvedimenti '||estremi_provv;
                    return next;
                    return;             
    end;
end if;

raise notice 'attoamm_id = %',atto_id;

RTN_MESSAGGIO:='Estrazione dei dati dei documenti di entrata ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
return query 
select query_totale.* from  (
with doc as (     
-- SIAC-6270: aggiunto filtro sullo stato dei documenti e restituiti anche
-- doc_id e subdoc_id che sono utilizzati nel report per il raggruppamento
-- in modo da evitare problemi in caso di documenti con stesso numero/anno
      select r_subdoc_atto_amm.subdoc_id,
              t_doc.doc_id,
                COALESCE(t_doc.doc_numero,'''') doc_numero, 
                COALESCE(t_doc.doc_anno,0) doc_anno, 
                COALESCE(t_doc.doc_importo,0) doc_importo,
                COALESCE(t_subdoc.subdoc_numero,0) subdoc_numero, 
                COALESCE(t_subdoc.subdoc_importo,0) subdoc_importo, 
                COALESCE(t_subdoc.subdoc_importo_da_dedurre,0) subdoc_importo_da_dedurre,                 
                COALESCE(d_doc_tipo.doc_tipo_code,'''') tipo_doc,
                 t_atto_amm.attoamm_numero,
                  t_atto_amm.attoamm_anno,
                  tipo_atto.attoamm_tipo_code,
                  r_subdoc_movgest_ts.movgest_ts_id
          from siac_r_subdoc_atto_amm r_subdoc_atto_amm,
                  siac_t_subdoc t_subdoc
                  LEFT JOIN siac_r_subdoc_movgest_ts r_subdoc_movgest_ts
                      ON (r_subdoc_movgest_ts.subdoc_id=t_subdoc.subdoc_id
                          AND r_subdoc_movgest_ts.data_cancellazione IS NULL),
                  siac_t_doc 	t_doc
                  LEFT JOIN siac_d_doc_tipo d_doc_tipo
                      ON (d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id
                          AND d_doc_tipo.data_cancellazione IS NULL)
                  LEFT JOIN siac_d_doc_fam_tipo d_doc_fam_tipo
                      ON (d_doc_fam_tipo.doc_fam_tipo_id=d_doc_tipo.doc_fam_tipo_id
                          AND d_doc_fam_tipo.data_cancellazione IS NULL),
                  siac_r_doc_stato r_doc_stato,
                  siac_d_doc_stato d_doc_stato,
                  siac_t_atto_amm t_atto_amm  ,
                  siac_d_atto_amm_tipo	tipo_atto
          where t_subdoc.subdoc_id= r_subdoc_atto_amm.subdoc_id
              AND t_doc.doc_id=  t_subdoc.doc_id
              AND t_atto_amm.attoamm_id=r_subdoc_atto_amm.attoamm_id
              AND tipo_atto.attoamm_tipo_id=t_atto_amm.attoamm_tipo_id
              and t_doc.doc_id = r_doc_stato.doc_id
              and r_doc_stato.doc_stato_id = d_doc_stato.doc_stato_id
              and r_subdoc_atto_amm.ente_proprietario_id=p_ente_prop_id
              and t_atto_amm.attoamm_id = atto_id
              --AND t_atto_amm.attoamm_numero=p_numero_provv
             -- AND t_atto_amm.attoamm_anno=p_anno_provv
             -- AND tipo_atto.attoamm_tipo_code=p_tipo_provv
             AND d_doc_fam_tipo.doc_fam_tipo_code='E' --doc di Entrata
             and d_doc_stato.doc_stato_code <> 'A'
              AND r_subdoc_atto_amm.data_cancellazione IS NULL
              AND t_atto_amm.data_cancellazione IS NULL
              AND tipo_atto.data_cancellazione IS NULL
              AND t_subdoc.data_cancellazione IS NULL
              AND t_doc.data_cancellazione IS NULL
              AND d_doc_stato.data_cancellazione IS NULL 
              AND r_doc_stato.data_cancellazione IS NULL   ),
 accert as (
		SELECT t_movgest.movgest_id, t_movgest_ts.movgest_ts_id,
        		t_movgest.movgest_anno, 
      			t_movgest.movgest_numero,
            	t_movgest_ts.movgest_ts_code,
                 d_movgest_ts_tipo.movgest_ts_tipo_code,
                t_movgest_ts_det.movgest_ts_det_importo
            FROM siac_t_movgest t_movgest,
            	siac_t_bil t_bil,
                siac_t_periodo t_periodo,
            	siac_t_movgest_ts t_movgest_ts,    
                siac_d_movgest_tipo d_movgest_tipo,            
                siac_t_movgest_ts_det t_movgest_ts_det,
                siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                siac_d_movgest_ts_tipo d_movgest_ts_tipo,
                siac_r_movgest_ts_stato r_movgest_ts_stato,
                siac_d_movgest_stato d_movgest_stato 
          	WHERE t_movgest.movgest_id=t_movgest_ts.movgest_id    
            	AND t_bil.bil_id= t_movgest.bil_id   
                AND t_periodo.periodo_id=t_bil.periodo_id    
            	AND d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id 
                 AND r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id     
               AND r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id   	
               AND t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
               AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
                AND d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
                AND t_movgest.ente_proprietario_id=p_ente_prop_id
                AND t_periodo.anno =p_anno
                AND d_movgest_tipo.movgest_tipo_code='A'    --accertamento  
                AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A' -- importo attuale 
                AND d_movgest_stato.movgest_stato_code<>'A' -- non gli annullati
                AND  t_movgest_ts.data_cancellazione IS NULL
                AND  t_movgest.data_cancellazione IS NULL   
                AND t_bil.data_cancellazione IS NULL 
                AND t_periodo.data_cancellazione IS NULL
                AND  d_movgest_tipo.data_cancellazione IS NULL            
                AND t_movgest_ts_det.data_cancellazione IS NULL
                AND d_movgest_ts_det_tipo.data_cancellazione IS NULL
                AND d_movgest_ts_tipo.data_cancellazione IS NULL
                AND r_movgest_ts_stato.data_cancellazione IS NULL
                AND d_movgest_stato.data_cancellazione IS NULL),
	soggetto as (
    		SELECT r_doc_sog.doc_id,
                t_soggetto.soggetto_code,
                t_soggetto.soggetto_desc
            FROM siac_r_doc_sog r_doc_sog,
                siac_t_soggetto t_soggetto
            WHERE r_doc_sog.soggetto_id=   t_soggetto.soggetto_id
                and t_soggetto.ente_proprietario_id=p_ente_prop_id
                AND t_soggetto.data_cancellazione IS NULL  
                AND r_doc_sog.data_cancellazione IS NULL) ,   
    	capitoli as(
        	select r_movgest_bil_elem.movgest_id,
            	t_bil_elem.elem_id,
            	t_bil_elem.elem_code,
                t_bil_elem.elem_code2,
                t_bil_elem.elem_code3,
                t_bil_elem.elem_desc,
                t_bil_elem.elem_desc2
            from 	siac_r_movgest_bil_elem r_movgest_bil_elem,
            	siac_t_bil_elem t_bil_elem
            where r_movgest_bil_elem.elem_id=t_bil_elem.elem_id            
            	AND r_movgest_bil_elem.ente_proprietario_id=p_ente_prop_id
            	AND t_bil_elem.data_cancellazione IS NULL
                AND r_movgest_bil_elem.data_cancellazione IS NULL) ,
	conto_integrato as (    	
      select distinct t_subdoc.subdoc_id, 
          t_mov_ep_det.movep_det_segno,
          t_pdce_conto.pdce_conto_code
      from siac_r_evento_reg_movfin r_ev_reg_movfin,
          siac_t_subdoc t_subdoc,
          siac_d_evento d_evento,
          siac_d_collegamento_tipo d_coll_tipo,
          siac_t_reg_movfin t_reg_movfin,
          siac_t_mov_ep t_mov_ep,
          siac_t_mov_ep_det t_mov_ep_det,
          siac_t_pdce_conto t_pdce_conto
      where t_subdoc.subdoc_id=r_ev_reg_movfin.campo_pk_id
          and d_evento.evento_id=r_ev_reg_movfin.evento_id
          and d_coll_tipo.collegamento_tipo_id=d_evento.collegamento_tipo_id
          and t_reg_movfin.regmovfin_id=r_ev_reg_movfin.regmovfin_id
          and t_mov_ep.regmovfin_id=t_reg_movfin.regmovfin_id
          and t_mov_ep_det.movep_id=t_mov_ep.movep_id
          and t_pdce_conto.pdce_conto_id=t_mov_ep_det.pdce_conto_id
          and t_subdoc.ente_proprietario_id=p_ente_prop_id
          and d_coll_tipo.collegamento_tipo_code='SE' --Subdocumento Entrata   
          and r_ev_reg_movfin.data_cancellazione is null
          and t_subdoc.data_cancellazione is null
          and d_evento.data_cancellazione is null
          and d_coll_tipo.data_cancellazione is null
          and t_reg_movfin.data_cancellazione is null
          and t_mov_ep.data_cancellazione is null
          and t_mov_ep_det.data_cancellazione is null
          and t_pdce_conto.data_cancellazione is null )   ,
      reversali as (    
      select t_ordinativo.ord_anno,
          t_ordinativo.ord_numero,
          r_subdoc_ord_ts.subdoc_id         
       from  
                siac_t_ordinativo t_ordinativo,
                siac_d_ordinativo_tipo d_ordinativo_tipo,              
                siac_t_ordinativo_ts t_ord_ts,
                siac_r_subdoc_ordinativo_ts r_subdoc_ord_ts,
                siac_t_ordinativo_ts_det t_ord_ts_det, 
               siac_d_ordinativo_ts_det_tipo ts_det_tipo  
      where t_ordinativo.ord_tipo_id=   d_ordinativo_tipo.ord_tipo_id
          and t_ordinativo.ord_id= t_ord_ts.ord_id
          AND r_subdoc_ord_ts.ord_ts_id=t_ord_ts.ord_ts_id
          and t_ord_ts_det.ord_ts_id= t_ord_ts.ord_ts_id  
          and ts_det_tipo.ord_ts_det_tipo_id=  t_ord_ts_det.ord_ts_det_tipo_id
          AND t_ordinativo.ente_proprietario_id=p_ente_prop_id
           AND d_ordinativo_tipo.ord_tipo_code ='I' --Incasso
           AND ts_det_tipo.ord_ts_det_tipo_code='A' --importo Attuale
           AND t_ordinativo.data_cancellazione IS NULL
           AND d_ordinativo_tipo.data_cancellazione IS NULL 
           AND t_ord_ts.data_cancellazione IS NULL
           AND t_ord_ts_det.data_cancellazione IS NULL
           AND ts_det_tipo.data_cancellazione IS NULL
           AND r_subdoc_ord_ts.data_cancellazione IS NULL)                                    
SELECT COALESCE(capitoli.elem_code,'')::varchar bil_ele_code,
	COALESCE(capitoli.elem_desc,'')::varchar bil_ele_desc,
    COALESCE(capitoli.elem_code2,'')::varchar bil_ele_code2,
   	COALESCE(capitoli.elem_desc2,'')::varchar bil_ele_desc2,
    COALESCE(capitoli.elem_code3,'')::varchar bil_ele_code3,
    doc.doc_anno::integer,
    doc.doc_numero::varchar,
    doc.subdoc_numero::integer,
    doc.tipo_doc::varchar,
    CASE WHEN COALESCE(upper(conto_integrato.movep_det_segno),'')='DARE'
    	THEN COALESCE(conto_integrato.pdce_conto_code,'')::varchar 
        ELSE ''::varchar end conto_dare,
     CASE WHEN COALESCE(upper(conto_integrato.movep_det_segno),'')='AVERE'
    	THEN COALESCE(conto_integrato.pdce_conto_code,'')::varchar 
        ELSE ''::varchar end conto_avere,
    accert.movgest_numero::numeric num_accertamento,
    accert.movgest_anno::integer anno_accertamento,
    accert.movgest_ts_code::varchar num_subaccertamento,
    CASE WHEN accert.movgest_ts_tipo_code = 'T'
    	THEN 'ACC'::varchar 
        ELSE 'SUB'::varchar end tipo_accert,
    COALESCE(soggetto.soggetto_code,'')::varchar code_soggetto,
    COALESCE(soggetto.soggetto_desc,'')::varchar desc_soggetto,
    COALESCE(reversali.ord_numero,'0')::varchar num_reversale,
    COALESCE(reversali.ord_anno,0)::integer anno_reversale,
    COALESCE(doc.subdoc_importo,0)-
    COALESCE(doc.subdoc_importo_da_dedurre,0) ::numeric importo_quota,
    doc.doc_id::integer doc_id,
    doc.subdoc_id::integer subdoc_id,
    ''::varchar display_error	
FROM doc
	LEFT JOIN accert on accert.movgest_ts_id=doc.movgest_ts_id
	LEFT JOIN soggetto on soggetto.doc_id=doc.doc_id    
	LEFT JOIN capitoli on capitoli.movgest_id = accert.movgest_id
    LEFT JOIN conto_integrato on conto_integrato.subdoc_id = doc.subdoc_id 
    LEFT JOIN reversali on reversali.subdoc_id = doc.subdoc_id       
ORDER BY doc_anno, doc_numero, subdoc_numero) query_totale;

RTN_MESSAGGIO:='Fine estrazione dei dati dei documenti di entrata  ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;



exception
	when no_data_found THEN
		raise notice 'Nessun documento di entrata trovato' ;
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