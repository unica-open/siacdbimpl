/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR152_elenco_doc_spesa" (
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
  num_impegno numeric,
  anno_impegno integer,
  num_subimpegno varchar,
  tipo_impegno varchar,
  code_soggetto varchar,
  desc_soggetto varchar,
  num_liquidazione varchar,
  anno_liquidazione integer,
  importo_quota numeric,
  penale_anno integer,
  penale_numero varchar,
  ncd_anno integer,
  ncd_numero varchar,
  tipo_iva_split_reverse varchar,
  importo_split_reverse numeric,
  codice_onere varchar,
  aliquota_carico_sogg numeric,
  doc_id integer,
  subdoc_id integer,
  display_error varchar
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
anno_eser_int integer;

-- CR944 inizio
tipo_cessione varchar:=''; 
-- CR944 fine
 
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
num_impegno:=0;
anno_impegno:=0;
num_subimpegno:='';
tipo_impegno:='';
code_soggetto:='';
desc_soggetto:=0;
num_liquidazione:='';
anno_liquidazione:=0;
importo_quota:=0;
penale_anno:=0;
penale_numero:='';
ncd_anno:=0;
ncd_numero:='';
tipo_iva_split_reverse:='';
importo_split_reverse:=0;
codice_onere:='';
aliquota_carico_sogg:=0;

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

RTN_MESSAGGIO:='Estrazione dei dati dei documenti di spesa ''.';
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
              --AND t_atto_amm.attoamm_anno=p_anno_provv
             -- AND tipo_atto.attoamm_tipo_code=p_tipo_provv
             AND d_doc_fam_tipo.doc_fam_tipo_code='S' --doc di Spesa
             and d_doc_stato.doc_stato_code <> 'A'
              AND r_subdoc_atto_amm.data_cancellazione IS NULL
              AND t_atto_amm.data_cancellazione IS NULL
              AND tipo_atto.data_cancellazione IS NULL
              AND t_subdoc.data_cancellazione IS NULL
              AND t_doc.data_cancellazione IS NULL  
              AND d_doc_stato.data_cancellazione IS NULL 
              AND r_doc_stato.data_cancellazione IS NULL ),
 impegni as (
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
                AND d_movgest_tipo.movgest_tipo_code='I'    --Impegno  
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
          and d_coll_tipo.collegamento_tipo_code='SS' --Subdocumento Spesa   
          and r_ev_reg_movfin.data_cancellazione is null
          and t_subdoc.data_cancellazione is null
          and d_evento.data_cancellazione is null
          and d_coll_tipo.data_cancellazione is null
          and t_reg_movfin.data_cancellazione is null
          and t_mov_ep.data_cancellazione is null
          and t_mov_ep_det.data_cancellazione is null
          and t_pdce_conto.data_cancellazione is null )   ,
      liquidazioni as (    
          select t_liquidazione.liq_anno,
              -- CR944 inizio
              --t_liquidazione.liq_numero,
              t_liquidazione.liq_numero || ' ' || COALESCE( d_relaz.relaz_tipo_code, '') as liq_numero,
              -- CR944 fine
              r_subdoc_liq.subdoc_id         
           from  siac_t_liquidazione t_liquidazione
             -- CR944 inizio
             left join  siac_r_soggetto_relaz r_relaz on (
                  t_liquidazione.soggetto_relaz_id=  r_relaz.soggetto_relaz_id
                  and r_relaz.data_cancellazione is null
                  and r_relaz.validita_fine is null 
             )
             left join siac_d_relaz_tipo d_relaz on (
                  d_relaz.relaz_tipo_id=r_relaz.relaz_tipo_id
             )
             left join siac_r_soggrel_modpag r_modpag on (
                  r_modpag.soggetto_relaz_id = r_relaz.soggetto_relaz_id
                  and r_modpag.data_cancellazione is null
                  and r_modpag.validita_fine is null
             )
             -- CR944 fine
           ,         
                siac_r_subdoc_liquidazione r_subdoc_liq                
          where t_liquidazione.liq_id=   r_subdoc_liq.liq_id
               AND t_liquidazione.ente_proprietario_id =p_ente_prop_id
               AND t_liquidazione.data_cancellazione IS NULL
               AND r_subdoc_liq.data_cancellazione IS NULL)  ,
      ncd as  (
      		SELECT  r_doc.doc_id_da doc_id,
            	t_doc.doc_anno,
                t_doc.doc_numero, 
                d_doc_tipo.doc_tipo_code
            FROM siac_r_doc r_doc, 
            		siac_d_relaz_tipo d_relaz_tipo,
                    siac_t_doc t_doc,
                    siac_d_doc_tipo d_doc_tipo
            WHERE r_doc.relaz_tipo_id=d_relaz_tipo.relaz_tipo_id
            	AND t_doc.doc_id=r_doc.doc_id_a
                AND d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id
                AND d_relaz_tipo.relaz_tipo_code='NCD' -- note di credito
                and r_doc.ente_proprietario_id=p_ente_prop_id
                AND r_doc.data_cancellazione IS NULL
                AND d_relaz_tipo.data_cancellazione IS NULL
                AND t_doc.data_cancellazione IS NULL
                AND d_doc_tipo.data_cancellazione IS NULL)  ,
			ritenute as (
        		SELECT r_doc_onere.doc_id, r_doc_onere.importo_carico_ente, 
                    r_doc_onere.importo_imponibile,
                    d_onere_tipo.onere_tipo_code, d_onere.onere_code
                FROM siac_r_doc_onere r_doc_onere, siac_d_onere d_onere,
                	siac_d_onere_tipo  d_onere_tipo
                WHERE r_doc_onere.onere_id=d_onere.onere_id
                	AND d_onere.onere_tipo_id=d_onere_tipo.onere_tipo_id
                    AND r_doc_onere.ente_proprietario_id =p_ente_prop_id
                    -- estraggo solo gli oneri con importo carico ente
                    -- e che non sono Split/reverse
                    AND r_doc_onere.importo_carico_ente > 0   
                    AND d_onere_tipo.onere_tipo_code <> 'SP'
                    AND r_doc_onere.data_cancellazione IS NULL
                    AND d_onere.data_cancellazione IS NULL
                    AND d_onere_tipo.data_cancellazione IS NULL)  ,
            split_reverse as (
            	SELECT r_subdoc_split_iva_tipo.subdoc_id,
						d_split_iva_tipo.sriva_tipo_code, 
                        t_subdoc.subdoc_splitreverse_importo
                FROM siac_r_subdoc_splitreverse_iva_tipo r_subdoc_split_iva_tipo,
                  siac_d_splitreverse_iva_tipo d_split_iva_tipo ,
                  siac_t_subdoc t_subdoc    
                WHERE  r_subdoc_split_iva_tipo.sriva_tipo_id= d_split_iva_tipo.sriva_tipo_id
                	AND t_subdoc.subdoc_id=r_subdoc_split_iva_tipo.subdoc_id
                    AND r_subdoc_split_iva_tipo.ente_proprietario_id=p_ente_prop_id
                    AND r_subdoc_split_iva_tipo.data_cancellazione IS NULL
                    AND d_split_iva_tipo.data_cancellazione IS NULL
                    AND t_subdoc.data_cancellazione IS NULL) ,
            penali as (
            	SELECT  r_doc.doc_id_da doc_id,
            	t_doc.doc_anno,
                t_doc.doc_numero, 
                d_doc_tipo.doc_tipo_code
            FROM siac_r_doc r_doc, 
            		siac_d_relaz_tipo d_relaz_tipo,
                    siac_t_doc t_doc,
                    siac_d_doc_tipo d_doc_tipo
            WHERE r_doc.relaz_tipo_id=d_relaz_tipo.relaz_tipo_id
            	AND t_doc.doc_id=r_doc.doc_id_a
                AND d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id
                AND d_relaz_tipo.relaz_tipo_code='SUB' -- subortinati
                AND d_doc_tipo.doc_tipo_code='PNL' -- Penale
                and r_doc.ente_proprietario_id=p_ente_prop_id
                AND r_doc.data_cancellazione IS NULL
                AND d_relaz_tipo.data_cancellazione IS NULL
                AND t_doc.data_cancellazione IS NULL
                AND d_doc_tipo.data_cancellazione IS NULL)
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
    impegni.movgest_numero::numeric num_impegno,
    impegni.movgest_anno::integer anno_impegno,
    impegni.movgest_ts_code::varchar num_subimpegno,
    CASE WHEN impegni.movgest_ts_tipo_code = 'T'
    	THEN 'IMP'::varchar 
        ELSE 'SUB'::varchar end tipo_impegno,
    COALESCE(soggetto.soggetto_code,'')::varchar code_soggetto,
    COALESCE(soggetto.soggetto_desc,'')::varchar desc_soggetto,
    COALESCE(liquidazioni.liq_numero,'0')::varchar num_liquidazione,
    COALESCE(liquidazioni.liq_anno,0)::integer anno_liquidazione,
	COALESCE(doc.subdoc_importo,0)-
    	COALESCE(doc.subdoc_importo_da_dedurre,0) ::numeric importo_quota,
    COALESCE(penali.doc_anno,0)::integer   penale_anno, 
    COALESCE(penali.doc_numero,'')::varchar   penale_numero, 
	COALESCE(ncd.doc_anno,0)::integer ncd_anno,
    COALESCE(ncd.doc_numero,'')::varchar ncd_numero,
   --'1'::varchar ncd_numero,
    COALESCE(split_reverse.sriva_tipo_code,'')::varchar tipo_iva_split_reverse,
	COALESCE(split_reverse.subdoc_splitreverse_importo,0)::numeric importo_split_reverse,
    COALESCE(ritenute.onere_code,'')::varchar codice_onere,
    COALESCE(ritenute.importo_carico_ente,0)::numeric aliquota_carico_sogg,
    doc.doc_id::integer doc_id,
    doc.subdoc_id::integer subdoc_id,
    ''::varchar display_error
FROM doc
	LEFT JOIN impegni on impegni.movgest_ts_id=doc.movgest_ts_id
	LEFT JOIN soggetto on soggetto.doc_id=doc.doc_id    
	LEFT JOIN capitoli on capitoli.movgest_id = impegni.movgest_id
    LEFT JOIN conto_integrato on conto_integrato.subdoc_id = doc.subdoc_id 
    LEFT JOIN liquidazioni on liquidazioni.subdoc_id = doc.subdoc_id 
    LEFT JOIN ncd on ncd.doc_id =doc.doc_id         
    LEFT JOIN ritenute on ritenute.doc_id =doc.doc_id  
    LEFT JOIN split_reverse on split_reverse.subdoc_id =doc.subdoc_id  
    LEFT JOIN penali on ncd.doc_id =penali.doc_id           
ORDER BY doc_anno, doc_numero, subdoc_numero) query_totale;

RTN_MESSAGGIO:='Fine estrazione dei dati dei documenti di spesa ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;



exception
	when no_data_found THEN
		raise notice 'Nessun documento trovato' ;
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