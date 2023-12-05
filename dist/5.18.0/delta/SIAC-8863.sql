/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


-- SIAC-8863 Haitham 05.07.2023 inizio

select fnc_dba_add_column_params ('siac_dwh_contabilita_generale', 'codice_missione', 'varchar(10)');
select fnc_dba_add_column_params ('siac_dwh_contabilita_generale', 'descri_missione', 'varchar(500)');
select fnc_dba_add_column_params ('siac_dwh_contabilita_generale', 'codice_programma', 'varchar(10)');
select fnc_dba_add_column_params ('siac_dwh_contabilita_generale', 'descri_programma', 'varchar(500)');



CREATE OR REPLACE FUNCTION siac.fnc_prima_nota_missione_programma(p_ente_prop_id integer, p_anno character varying)
 RETURNS TABLE(pnota_id integer, pnota_numero integer, pnota_progressivogiornale integer, code_missione character varying, desc_missione character varying, code_programma character varying, desc_programma character varying, tipo_prima_nota character varying, collegamento_tipo_code character varying, elem_id integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
 
DEF_NULL	constant varchar:='';  
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
anno_competenza_int integer;
 
sqlQuery varchar;
idBilancio integer;
anno_bil_int integer;

BEGIN
 
	

/* 01/06/2023 .
	Funzione simile alla  BILR258_rend_gest_costi_missione_all_h_cont_gen
	ma con meno dati e  serve  per fnc_siac_dwh_contabilita_generale per la SIAC-8863.
*/

code_missione:='';
desc_missione:='';
code_programma:='';
desc_programma:='';
elem_id:=0;
collegamento_tipo_code:='';

anno_competenza_int=p_anno ::INTEGER;

anno_bil_int:=p_anno::INTEGER;

RTN_MESSAGGIO:='Estrazione dei dati degli impegni ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
-- leggo l'ID del bilancio x velocizzare.
 select a.bil_id
 into idBilancio
 from siac_t_bil a, siac_t_periodo b
 where a.periodo_id=b.periodo_id
 and a.ente_proprietario_id =p_ente_prop_id
 and b.anno = p_anno
 and a.data_cancellazione IS NULL
 and b.data_cancellazione IS NULL;
 

return query 

select distinct
   query_totale.pnota_id,
   query_totale.pnota_numero,
   query_totale.pnota_progressivogiornale,
 case when query_totale.causale_ep_tipo_code = 'LIB' THEN
   		COALESCE(query_totale.code_miss_lib,'')::varchar
   else 
   		COALESCE(missioni.code_missione,'')::varchar end code_missione,
   case when query_totale.causale_ep_tipo_code = 'LIB' THEN
   		COALESCE(query_totale.desc_miss_lib,'')::varchar
   else
   		COALESCE(missioni.desc_missione,'')::varchar end desc_missione,
   		
   case when query_totale.causale_ep_tipo_code = 'LIB' THEN
   		COALESCE(query_totale.code_progr_lib,'')::varchar
     else 
   		COALESCE(missioni.code_programma,'')::varchar end code_programma,
   
   case when query_totale.causale_ep_tipo_code = 'LIB' THEN
   		COALESCE(query_totale.desc_progr_lib,'')::varchar
     else
   		COALESCE(missioni.desc_programma,'')::varchar end desc_programma,	

   COALESCE(query_totale.causale_ep_tipo_code,'') tipo_prima_nota,
   COALESCE(query_totale.collegamento_tipo_code,'') collegamento_tipo_code,
   COALESCE(query_totale.elem_id,0) elem_id
   		
   	from (
    	--Estraggo i capitoli di spesa gestione e i relativi dati di struttura
        --per poter avere le missioni.
	with capitoli as(
  select distinct programma.classif_id programma_id,
          macroaggr.classif_id macroaggregato_id,          
          capitolo.elem_id
  from siac_d_class_tipo programma_tipo,
       siac_t_class programma,
       siac_d_class_tipo macroaggr_tipo,
       siac_t_class macroaggr,
       siac_t_bil_elem capitolo,
       siac_d_bil_elem_tipo tipo_elemento,
       siac_r_bil_elem_class r_capitolo_programma,
       siac_r_bil_elem_class r_capitolo_macroaggr, 
       siac_d_bil_elem_stato stato_capitolo, 
       siac_r_bil_elem_stato r_capitolo_stato,
       siac_d_bil_elem_categoria cat_del_capitolo,
       siac_r_bil_elem_categoria r_cat_capitolo 
  where 	
      programma.classif_tipo_id=programma_tipo.classif_tipo_id 		
      and	programma.classif_id=r_capitolo_programma.classif_id			    
      and	macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 		
      and	macroaggr.classif_id=r_capitolo_macroaggr.classif_id			    
      and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 					
      and	capitolo.elem_id=r_capitolo_programma.elem_id					
      and	capitolo.elem_id=r_capitolo_macroaggr.elem_id						
      and	capitolo.elem_id				=	r_capitolo_stato.elem_id	
      and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
      and	capitolo.elem_id				=	r_cat_capitolo.elem_id		
      and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id	   	
      and	capitolo.ente_proprietario_id=p_ente_prop_id 	
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.				
      --and	capitolo.bil_id = idBilancio										 
      and	programma_tipo.classif_tipo_code='PROGRAMMA'							
      and	macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						
      and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     	
      and	stato_capitolo.elem_stato_code	=	'VA'						     							
      and	programma_tipo.data_cancellazione 			is null
      and	programma.data_cancellazione 				is null
      and	macroaggr_tipo.data_cancellazione 			is null
      and	macroaggr.data_cancellazione 				is null
      and	capitolo.data_cancellazione 				is null
      and	tipo_elemento.data_cancellazione 			is null
      and	r_capitolo_programma.data_cancellazione 	is null
      and	r_capitolo_macroaggr.data_cancellazione 	is null 
      and	stato_capitolo.data_cancellazione 			is null 
      and	r_capitolo_stato.data_cancellazione 		is null
      and	cat_del_capitolo.data_cancellazione 		is null
      and	r_cat_capitolo.data_cancellazione 			is null),
   strut_bilancio as(
        select *
        from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id,p_anno,'')) 
  select COALESCE(strut_bilancio.missione_code,'') code_missione,
         COALESCE(strut_bilancio.missione_desc,'') desc_missione,
         COALESCE(strut_bilancio.programma_code,'') code_programma,
         COALESCE(strut_bilancio.programma_desc,'') desc_programma,    
         capitoli.elem_id
  from capitoli  
    left JOIN strut_bilancio on (strut_bilancio.programma_id =  capitoli.programma_id
        			AND strut_bilancio.macroag_id =  capitoli.macroaggregato_id)
  ) missioni 
  --devo estrarre con full join perche' nella query seguente ci sono anche le
  --prime note libere che non hanno il collegamento con i capitoli.
  full join  (     
  	--Estraggo i dati dei classificatori.
    --Questa parte della query e' la stessa del report BILR125.
        with classificatori as (
  SELECT classif_tot.classif_code AS codice_codifica, 
         classif_tot.classif_desc AS descrizione_codifica,
         classif_tot.ordine AS codice_codifica_albero, 
         case when classif_tot.ordine='E.26' then 3 
         	else classif_tot.level end livello_codifica,
         classif_tot.classif_id
  FROM (
      SELECT tb.classif_classif_fam_tree_id,
             tb.classif_fam_tree_id, t1.classif_code,
             t1.classif_desc, ti1.classif_tipo_code,
             tb.classif_id, tb.classif_id_padre,
             tb.ente_proprietario_id, 
             CASE WHEN tb.ordine = 'B.9' THEN 'B.09'
             ELSE tb.ordine
             END  ordine,
             tb.level,
             tb.arrhierarchy
      FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id,
                                   classif_fam_tree_id, 
                                   classif_id, 
                                   classif_id_padre, 
                                   ente_proprietario_id, 
                                   ordine, 
                                   livello, 
                                   level, arrhierarchy) AS (
             SELECT rt1.classif_classif_fam_tree_id,
                    rt1.classif_fam_tree_id,
                    rt1.classif_id,
                    rt1.classif_id_padre,
                    rt1.ente_proprietario_id,
                    rt1.ordine,
                    rt1.livello, 1,
                    ARRAY[COALESCE(rt1.classif_id,0)] AS "array"
             FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1, siac_d_class_fam cf, siac_t_class c
             WHERE cf.classif_fam_id = tt1.classif_fam_id 
             and c.classif_id=rt1.classif_id
             AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
             AND rt1.classif_id_padre IS NULL 
             AND   (cf.classif_fam_code = '00020')-- OR cf.classif_fam_code = v_classificatori1)
             AND tt1.ente_proprietario_id = rt1.ente_proprietario_id 
             AND anno_bil_int BETWEEN date_part('year',tt1.validita_inizio) AND 
             date_part('year',COALESCE(tt1.validita_fine,now())) 
             AND anno_bil_int BETWEEN date_part('year',rt1.validita_inizio) AND 
             date_part('year',COALESCE(rt1.validita_fine,now())) 
             AND anno_bil_int BETWEEN date_part('year',c.validita_inizio) AND 
             date_part('year',COALESCE(c.validita_fine,now())) 
             AND tt1.ente_proprietario_id = p_ente_prop_id
             UNION ALL
             SELECT tn.classif_classif_fam_tree_id,
                    tn.classif_fam_tree_id,
                    tn.classif_id,
                    tn.classif_id_padre,
                    tn.ente_proprietario_id,
                    tn.ordine,
                    tn.livello,
                    tp.level + 1,
                    tp.arrhierarchy || tn.classif_id
          FROM rqname tp, siac_r_class_fam_tree tn,siac_t_class c2
          WHERE tp.classif_id = tn.classif_id_padre 
          and c2.classif_id=tn.classif_id
          AND tn.ente_proprietario_id = tp.ente_proprietario_id
          AND anno_bil_int BETWEEN date_part('year',tn.validita_inizio) AND 
             date_part('year',COALESCE(tn.validita_fine,now())) 
  AND anno_bil_int BETWEEN date_part('year',c2.validita_inizio) AND 
             date_part('year',COALESCE(c2.validita_fine,now()))            
          )
          SELECT rqname.classif_classif_fam_tree_id,
                 rqname.classif_fam_tree_id,
                 rqname.classif_id,
                 rqname.classif_id_padre,
                 rqname.ente_proprietario_id,
                 rqname.ordine, rqname.livello,
                 rqname.level,
                 rqname.arrhierarchy
          FROM rqname
          ORDER BY rqname.arrhierarchy
          ) tb,
          siac_t_class t1, siac_d_class_tipo ti1
      WHERE t1.classif_id = tb.classif_id 
      AND ti1.classif_tipo_id = t1.classif_tipo_id 
      AND t1.ente_proprietario_id = tb.ente_proprietario_id 
      AND ti1.ente_proprietario_id = t1.ente_proprietario_id
      AND anno_bil_int BETWEEN date_part('year',t1.validita_inizio) 
      AND date_part('year',COALESCE(t1.validita_fine,now()))
  ) classif_tot
  ORDER BY classif_tot.classif_tipo_code desc, classif_tot.ordine),
pdce as(  
	--Estraggo le prime note collegate ai classificatori ed anche i relativi ID
    --degli eventi coinvolti per poterli poi collegare ai capitoli.
SELECT r_pdce_conto_class.classif_id,
		d_pdce_fam.pdce_fam_code, t_mov_ep_det.movep_det_segno, 
        d_coll_tipo.collegamento_tipo_code,
        r_ev_reg_movfin.campo_pk_id, r_ev_reg_movfin.campo_pk_id_2,
        COALESCE(t_mov_ep_det.movep_det_importo,0) importo,
         t_mov_ep_det.movep_det_id,d_caus_tipo.causale_ep_tipo_code,
         t_prima_nota.pnota_id,
         t_prima_nota.pnota_numero,
         t_prima_nota.pnota_progressivogiornale
    FROM  siac_r_pdce_conto_class r_pdce_conto_class
    INNER JOIN siac_t_pdce_conto pdce_conto 
    	ON r_pdce_conto_class.pdce_conto_id = pdce_conto.pdce_conto_id
    INNER JOIN siac_t_pdce_fam_tree t_pdce_fam_tree 
    	ON pdce_conto.pdce_fam_tree_id = t_pdce_fam_tree.pdce_fam_tree_id
    INNER JOIN siac_d_pdce_fam d_pdce_fam 
    	ON t_pdce_fam_tree.pdce_fam_id = d_pdce_fam.pdce_fam_id    
    INNER JOIN siac_t_mov_ep_det t_mov_ep_det 
    	ON t_mov_ep_det.pdce_conto_id = pdce_conto.pdce_conto_id
    INNER JOIN siac_t_mov_ep t_mov_ep 
    	ON t_mov_ep_det.movep_id = t_mov_ep.movep_id
    INNER JOIN siac_t_prima_nota t_prima_nota 
    	ON t_mov_ep.regep_id = t_prima_nota.pnota_id    
    INNER JOIN siac_r_prima_nota_stato r_prima_nota_stato 
    	ON t_prima_nota.pnota_id = r_prima_nota_stato.pnota_id
    INNER JOIN siac_d_prima_nota_stato d_prima_nota_stato 
    	ON r_prima_nota_stato.pnota_stato_id = d_prima_nota_stato.pnota_stato_id
    --devo estrarre con left join per prendere anche le prime note libere
    --che non hanno eventi.
    LEFT JOIN siac_r_evento_reg_movfin r_ev_reg_movfin 
    	ON r_ev_reg_movfin.regmovfin_id = t_mov_ep.regmovfin_id
    LEFT JOIN siac_d_evento d_evento 
    	ON d_evento.evento_id = r_ev_reg_movfin.evento_id
    LEFT JOIN siac_d_collegamento_tipo d_coll_tipo
    	ON d_coll_tipo.collegamento_tipo_id = d_evento.collegamento_tipo_id
    inner join siac_d_causale_ep_tipo d_caus_tipo
    	on d_caus_tipo.causale_ep_tipo_id=t_prima_nota.causale_ep_tipo_id
    WHERE r_pdce_conto_class.ente_proprietario_id = p_ente_prop_id
    AND   t_prima_nota.bil_id = idBilancio 
    AND   d_prima_nota_stato.pnota_stato_code = 'D'
    AND   r_pdce_conto_class.data_cancellazione IS NULL
    AND   pdce_conto.data_cancellazione IS NULL
    AND   t_pdce_fam_tree.data_cancellazione IS NULL
    AND   d_pdce_fam.data_cancellazione IS NULL
    AND   t_mov_ep_det.data_cancellazione IS NULL
    AND   t_mov_ep.data_cancellazione IS NULL
    AND   t_prima_nota.data_cancellazione IS NULL
    AND   r_prima_nota_stato.data_cancellazione IS NULL
    AND   d_prima_nota_stato.data_cancellazione IS NULL
    AND   r_ev_reg_movfin.data_cancellazione IS NULL
    AND   d_evento.data_cancellazione IS NULL
    AND   d_coll_tipo.data_cancellazione IS NULL
    AND   anno_bil_int BETWEEN date_part('year',pdce_conto.validita_inizio) 
    		AND date_part('year',COALESCE(pdce_conto.validita_fine,now()))  
    AND  anno_bil_int BETWEEN date_part('year',r_pdce_conto_class.validita_inizio)::integer
    		AND coalesce (date_part('year',r_pdce_conto_class.validita_fine)::integer ,anno_bil_int) 
   ),
   --Di seguito tutti gli eventi da collegarsi alle prime note come quelli estratti
   --dal report BILR159.
collegamento_MMGS_MMGE_a AS (
  SELECT DISTINCT rmbe.elem_id, tm.mod_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_t_movgest_ts_det_mod tmtdm, siac_t_movgest_ts tmt,
        siac_r_movgest_bil_elem rmbe, siac_t_bil_elem t_bil_elem 
  WHERE tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   tmtdm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = tmtdm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND	t_bil_elem.elem_id = rmbe.elem_id
  AND	rms.ente_proprietario_id = p_ente_prop_id
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	  
  --AND 	t_bil_elem.bil_id = idBilancio
  AND   dms.mod_stato_code = 'V'
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   tmtdm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL
  AND   t_bil_elem.data_cancellazione IS NULL),
  collegamento_MMGS_MMGE_b AS (
  SELECT DISTINCT rmbe.elem_id, tm.mod_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_r_movgest_ts_sog_mod rmtsm, siac_t_movgest_ts tmt,
        siac_r_movgest_bil_elem rmbe, siac_t_bil_elem t_bil_elem 
  WHERE tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   rmtsm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = rmtsm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND	t_bil_elem.elem_id = rmbe.elem_id
  AND 	rms.ente_proprietario_id = p_ente_prop_id
  AND   dms.mod_stato_code = 'V'
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	  
  --AND 	t_bil_elem.bil_id = idBilancio
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   rmtsm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL),
  collegamento_I_A AS ( --Impegni e Accertamenti
    SELECT DISTINCT r_mov_bil_elem.elem_id, r_mov_bil_elem.movgest_id
      FROM   siac_r_movgest_bil_elem r_mov_bil_elem, siac_t_bil_elem t_bil_elem 
      WHERE  t_bil_elem.elem_id=r_mov_bil_elem.elem_id
      AND	 r_mov_bil_elem.ente_proprietario_id = p_ente_prop_id
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	      
     -- AND 	 t_bil_elem.bil_id = idBilancio
      AND    r_mov_bil_elem.data_cancellazione IS NULL
      AND    t_bil_elem.data_cancellazione IS NULL),
  collegamento_SI_SA AS ( --Subimpegni e Subaccertamenti
  SELECT DISTINCT r_mov_bil_elem.elem_id, mov_ts.movgest_ts_id
  FROM  siac_t_movgest_ts mov_ts, siac_r_movgest_bil_elem r_mov_bil_elem,
  		siac_t_bil_elem t_bil_elem 
  WHERE mov_ts.movgest_id = r_mov_bil_elem.movgest_id
  AND	t_bil_elem.elem_id = r_mov_bil_elem.elem_id
  AND   mov_ts.ente_proprietario_id = p_ente_prop_id
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	  
  --AND 	t_bil_elem.bil_id = idBilancio
  AND   mov_ts.data_cancellazione IS NULL
  AND   r_mov_bil_elem.data_cancellazione IS NULL
  AND   t_bil_elem.data_cancellazione IS NULL),
  collegamento_SS_SE AS ( --SUBDOC
  SELECT DISTINCT r_mov_bil_elem.elem_id, r_subdoc_mov_ts.subdoc_id
  FROM   siac_r_subdoc_movgest_ts r_subdoc_mov_ts, siac_t_movgest_ts mov_ts, 
  		 siac_r_movgest_bil_elem r_mov_bil_elem, siac_t_bil_elem t_bil_elem
  WHERE  r_subdoc_mov_ts.movgest_ts_id = mov_ts.movgest_ts_id
  AND    mov_ts.movgest_id = r_mov_bil_elem.movgest_id 
  AND	t_bil_elem.elem_id = r_mov_bil_elem.elem_id
  AND 	 mov_ts.ente_proprietario_id = p_ente_prop_id
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	  
  --AND	 t_bil_elem.bil_id = idBilancio
  AND    (r_subdoc_mov_ts.data_cancellazione IS NULL OR 
  				(r_subdoc_mov_ts.data_cancellazione IS NOT NULL
  				AND r_subdoc_mov_ts.validita_fine IS NOT NULL AND
                r_subdoc_mov_ts.validita_fine > to_timestamp('31/12/'||p_anno||'','dd/mm/yyyy')))
  AND    mov_ts.data_cancellazione IS NULL
  AND    r_mov_bil_elem.data_cancellazione IS NULL
  AND    t_bil_elem.data_cancellazione IS NULL),
  collegamento_OP_OI AS ( --Ordinativi di pagamento e incasso.
    SELECT DISTINCT r_ord_bil_elem.elem_id, r_ord_bil_elem.ord_id
      FROM   siac_r_ordinativo_bil_elem r_ord_bil_elem, siac_t_bil_elem t_bil_elem
      WHERE  r_ord_bil_elem.elem_id=t_bil_elem.elem_id 
      AND	 r_ord_bil_elem.ente_proprietario_id = p_ente_prop_id
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	      
      --AND	 t_bil_elem.bil_id = idBilancio  
      AND    r_ord_bil_elem.data_cancellazione IS NULL
      AND    t_bil_elem.data_cancellazione IS NULL),
  collegamento_L AS ( --Liquidazioni
    SELECT DISTINCT c.elem_id, a.liq_id
      FROM   siac_r_liquidazione_movgest a, siac_t_movgest_ts b, 
             siac_r_movgest_bil_elem c
      WHERE  a.movgest_ts_id = b.movgest_ts_id
      AND    b.movgest_id = c.movgest_id
      AND	 b.ente_proprietario_id = p_ente_prop_id
      AND    a.data_cancellazione IS NULL
      AND    b.data_cancellazione IS NULL
      AND    c.data_cancellazione IS NULL),
  collegamento_RR AS ( --Giustificativi.
  	SELECT DISTINCT d.elem_id, a.gst_id
      FROM  siac_t_giustificativo a, siac_r_richiesta_econ_movgest b, siac_t_movgest_ts c, siac_r_movgest_bil_elem d
      WHERE a.ente_proprietario_id = p_ente_prop_id
      AND   a.ricecon_id = b.ricecon_id
      AND   b.movgest_ts_id = c.movgest_ts_id
      AND   c.movgest_id = d.movgest_id
      AND   a.data_cancellazione  IS NULL
      AND   b.data_cancellazione  IS NULL
      AND   c.data_cancellazione  IS NULL
      AND   d.data_cancellazione  IS NULL),
  collegamento_RE AS ( --Richieste economali.
  SELECT DISTINCT c.elem_id, a.ricecon_id
    FROM  siac_r_richiesta_econ_movgest a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
    WHERE b.ente_proprietario_id = p_ente_prop_id
    AND   a.movgest_ts_id = b.movgest_ts_id
    AND   b.movgest_id = c.movgest_id
    AND   a.data_cancellazione  IS NULL
    AND   b.data_cancellazione  IS NULL
    AND   c.data_cancellazione  IS NULL),
  collegamento_SS_SE_NCD AS ( --Note di credito
    select c.elem_id, a.subdoc_id
    from  siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
    where a.movgest_ts_id = b.movgest_ts_id
    AND    b.movgest_id = c.movgest_id
    AND b.ente_proprietario_id = p_ente_prop_id
    AND    (a.data_cancellazione IS NULL OR (a.data_cancellazione IS NOT NULL
                  AND a.validita_fine IS NOT NULL AND
                  a.validita_fine > to_timestamp('31/12/'||p_anno||'','dd/mm/yyyy')))
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL),      
--estraggo la missione collegata a siac_r_mov_ep_det_class per le 
--prime note libere.    
ele_prime_note_lib_miss as (
  	select t_class.classif_code code_miss_lib,
    t_class.classif_desc desc_miss_lib,
     r_mov_ep_det_class.*
    from siac_r_mov_ep_det_class r_mov_ep_det_class,
    	siac_t_class t_class ,  	
        siac_d_class_tipo d_class_tipo	
    where t_class.classif_id=r_mov_ep_det_class.classif_id
    	and d_class_tipo.classif_tipo_id = t_class.classif_tipo_id
        AND r_mov_ep_det_class.ente_proprietario_id=p_ente_prop_id
        and d_class_tipo.classif_tipo_code='MISSIONE'
        and r_mov_ep_det_class.data_cancellazione IS NULL
        and t_class.data_cancellazione IS NULL
        and d_class_tipo.data_cancellazione IS NULL),
ele_prime_note_lib_programma as (
  	select t_class.classif_code code_progr_lib,
    t_class.classif_desc desc_progr_lib,
     r_mov_ep_det_class.*
    from siac_r_mov_ep_det_class r_mov_ep_det_class,
    	siac_t_class t_class ,  	
        siac_d_class_tipo d_class_tipo	
    where t_class.classif_id=r_mov_ep_det_class.classif_id
    	and d_class_tipo.classif_tipo_id = t_class.classif_tipo_id
        AND r_mov_ep_det_class.ente_proprietario_id=p_ente_prop_id
        and d_class_tipo.classif_tipo_code='PROGRAMMA'
        and r_mov_ep_det_class.data_cancellazione IS NULL
        and t_class.data_cancellazione IS NULL
        and d_class_tipo.data_cancellazione IS NULL)                                    
        
SELECT classificatori.codice_codifica::varchar codice_codifica,
    classificatori.descrizione_codifica::varchar descrizione_codifica,
    classificatori.codice_codifica_albero::varchar codice_codifica_albero,
    classificatori.livello_codifica::integer livello_codifica,       
    case when upper(pdce.movep_det_segno)='DARE' then pdce.importo
    	else 0::numeric end importo_dare,
    case when upper(pdce.movep_det_segno)='AVERE' then pdce.importo
    	else 0::numeric end importo_avere,
    COALESCE(collegamento_MMGS_MMGE_a.elem_id, 
    	COALESCE(collegamento_MMGS_MMGE_b.elem_id,
        	COALESCE(collegamento_I_A.elem_id,
        		COALESCE(collegamento_SI_SA.elem_id,
                	COALESCE(collegamento_SS_SE.elem_id,
                    	COALESCE(collegamento_OP_OI.elem_id,
                        	COALESCE(collegamento_L.elem_id,
                            	COALESCE(collegamento_RR.elem_id,
                                	COALESCE(collegamento_RE.elem_id,
                                    	COALESCE(collegamento_SS_SE_NCD.elem_id,
                                          	0),0),0),0),0),0),0),0),0),0) elem_id,
	pdce.collegamento_tipo_code,--, pdce.campo_pk_id, pdce.campo_pk_id_2                                            
    ele_prime_note_lib_miss.code_miss_lib,
	ele_prime_note_lib_miss.desc_miss_lib,
    ele_prime_note_lib_programma.code_progr_lib,
	ele_prime_note_lib_programma.desc_progr_lib,
	pdce.movep_det_id, pdce.causale_ep_tipo_code, pdce.pnota_id, pdce.pnota_numero,  pdce.pnota_progressivogiornale,
    --SIAC-8698 21/04/2022. Aggiungo questi campi.
    pdce.campo_pk_id, pdce.campo_pk_id_2
from classificatori
	inner join pdce
    	ON pdce.classif_id = classificatori.classif_id     
  LEFT   JOIN collegamento_MMGS_MMGE_a ON collegamento_MMGS_MMGE_a.mod_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('MMGS','MMGE') 
  LEFT   JOIN collegamento_MMGS_MMGE_b ON collegamento_MMGS_MMGE_b.mod_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('MMGS','MMGE')
  LEFT   JOIN collegamento_I_A ON collegamento_I_A.movgest_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('I','A')
  LEFT   JOIN collegamento_SI_SA ON collegamento_SI_SA.movgest_ts_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('SI','SA')                                     
  LEFT   JOIN collegamento_SS_SE ON collegamento_SS_SE.subdoc_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('SS','SE')
  LEFT   JOIN collegamento_OP_OI ON collegamento_OP_OI.ord_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('OP','OI')
  LEFT   JOIN collegamento_L ON collegamento_L.liq_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code = 'L'
  LEFT   JOIN collegamento_RR ON collegamento_RR.gst_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code = 'RR'
  LEFT   JOIN collegamento_RE ON collegamento_RE.ricecon_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code = 'RE'
  --collegamento per note di credito. Si usa campo_pk_id_2
  LEFT	 JOIN collegamento_SS_SE_NCD ON collegamento_SS_SE_NCD.subdoc_id = pdce.campo_pk_id_2
  										AND pdce.collegamento_tipo_code IN ('SS','SE')                
  LEFT JOIN ele_prime_note_lib_miss ON ele_prime_note_lib_miss.movep_det_id=pdce.movep_det_id
  LEFT JOIN ele_prime_note_lib_programma ON ele_prime_note_lib_programma.movep_det_id=pdce.movep_det_id
 ) query_totale
on missioni.elem_id =query_totale.elem_id  
where COALESCE(query_totale.code_miss_lib,'') <> '' OR
	COALESCE(missioni.code_missione,'')  <> ''
order by 1;

RTN_MESSAGGIO:='Fine estrazione dei dati''.';
raise notice 'ora: % ',clock_timestamp()::varchar;



exception
	when no_data_found THEN
		raise notice 'Nessun dato trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$function$
;



CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_contabilita_generale(p_anno_bilancio character varying, p_ente_proprietario_id integer, p_data timestamp without time zone)
 RETURNS TABLE(esito character varying)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
/*
pdc        record;

impegni record;
documenti record;
liquidazioni_doc record;
liquidazioni_imp record;
ordinativi record;
ordinativi_imp record;

prima_nota record;
movimenti  record;
causale    record;
class      record;*/

v_user_table varchar;
params varchar;

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
   --IF p_anno_bilancio::integer < to_char(now(),'YYYY')::integer THEN
      --p_data = to_timestamp('31/12/'||p_anno_bilancio, 'dd/mm/yyyy');
   --ELSE
      p_data := now();
   --END IF;
END IF;

select fnc_siac_random_user()
into	v_user_table;

params := p_anno_bilancio||' - '||p_ente_proprietario_id::varchar||' - '||p_data::varchar;


insert into
siac_dwh_log_elaborazioni (
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values (
p_ente_proprietario_id,
'fnc_siac_dwh_contabilita_generale',
params,
clock_timestamp(),
v_user_table
);

esito:= 'Inizio funzione carico dati contabilita_generale (FNC_SIAC_DWH_CONTABILITA_GENERALE) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;
DELETE FROM siac.siac_dwh_contabilita_generale
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;

insert into siac_dwh_contabilita_generale

select
tb.ente_proprietario_id,
tb.ente_denominazione,
tb.bil_anno,
tb.desc_prima_nota,
tb.num_provvisorio_prima_nota,
tb.num_definitivo_prima_nota,
tb.data_registrazione_prima_nota,
tb.cod_stato_prima_nota,
tb.desc_stato_prima_nota,
tb.cod_mov_ep,
tb.desc_mov_ep,
tb.cod_mov_ep_dettaglio,
tb.desc_mov_ep_dettaglio,
tb.importo_mov_ep,
tb.segno_mov_ep,
tb.cod_piano_dei_conti,
tb.desc_piano_dei_conti,
tb.livello_piano_dei_conti,
tb.ordine_piano_dei_conti,
tb.cod_pdce_fam,
tb.desc_pdce_fam,
tb.cod_ambito,
tb.desc_ambito,
tb.cod_causale,
tb.desc_causale,
tb.cod_tipo_causale,
tb.desc_tipo_causale,
tb.cod_stato_causale,
tb.desc_stato_causale,
tb.cod_evento,
tb.desc_evento,
tb.cod_tipo_mov_finanziario,
tb.desc_tipo_mov_finanziario,
tb.cod_piano_finanziario,
tb.desc_piano_finanziario,
tb.anno_movimento,
tb.numero_movimento,
tb.cod_submovimento,
anno_ordinativo,
num_ordinativo,
num_subordinativo,
anno_liquidazione,
num_liquidazione,
anno_doc,
num_doc,
cod_tipo_doc,
data_emissione_doc,
cod_sogg_doc,
num_subdoc,
modifica_impegno,
entrate_uscite,
tb.cod_bilancio,
p_data data_elaborazione,
numero_ricecon,
tipo_evento -- SIAC-5641
,doc_id -- SIAC-5573
from
(
-- documenti
select tbdoc.*
from
(
  with
  movep as
  (
   select distinct
  	  a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno,
      m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,
      m.pnota_progressivogiornale num_definitivo_prima_nota,
	  m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
	  o.pnota_stato_code cod_stato_prima_nota,
	  o.pnota_stato_desc desc_stato_prima_nota,
	  l.movep_id, --da non visualizzare
	  l.movep_code cod_mov_ep,
	  l.movep_desc desc_mov_ep,
	  q.causale_ep_code cod_causale,
	  q.causale_ep_desc desc_causale,
	  r.causale_ep_tipo_code cod_tipo_causale,
	  r.causale_ep_tipo_desc desc_tipo_causale,
	  t.causale_ep_stato_code cod_stato_causale,
	  t.causale_ep_stato_desc desc_stato_causale,
      c.evento_code cod_evento,
      c.evento_desc desc_evento,
      d.collegamento_tipo_code cod_tipo_mov_finanziario,
      d.collegamento_tipo_desc desc_tipo_mov_finanziario,
      b.campo_pk_id ,
      q.causale_ep_id,
      g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
/*         left join siac_r_causale_ep_stato s on s.causale_ep_id=q.causale_ep_id  -- SIAC-5696 INIZIO
                                             and s.data_cancellazione is null
                                             and s.validita_fine is null
         left join siac_d_causale_ep_stato t on s.causale_ep_stato_id=t.causale_ep_stato_id
                                             and t.data_cancellazione is null,   -- SIAC-5696 FINE  */
         siac_r_causale_ep_stato s, -- SIAC-5941
         siac_d_causale_ep_stato t, -- SIAC-5941
         siac_d_causale_ep_tipo r
    WHERE
 		  a.ente_proprietario_id=p_ente_proprietario_id and
		  i.anno=p_anno_bilancio and
		  a.regmovfin_id = b.regmovfin_id and
          c.evento_id = b.evento_id AND
          d.collegamento_tipo_id = c.collegamento_tipo_id AND
          g.evento_tipo_id = c.evento_tipo_id AND
          e.regmovfin_id = a.regmovfin_id AND
          f.regmovfin_stato_id = e.regmovfin_stato_id AND
          p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data) and
          --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
          p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data) and
          --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
          h.bil_id = a.bil_id AND
          i.periodo_id = h.periodo_id AND
          l.regmovfin_id = a.regmovfin_id AND
          l.regep_id = m.pnota_id AND
          m.pnota_id = n.pnota_id AND
          o.pnota_stato_id = n.pnota_stato_id AND
          p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data) and
          --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
          p.ente_proprietario_id=a.ente_proprietario_id and
          q.causale_ep_id=l.causale_ep_id AND
          r.causale_ep_tipo_id=q.causale_ep_tipo_id and
          s.causale_ep_id=q.causale_ep_id AND -- SIAC-5941 -- SIAC-5696
          s.causale_ep_stato_id=t.causale_ep_stato_id and -- SIAC-5941 -- SIAC-5696
          --s.validita_fine is NULL and -- SIAC-5696
          o.pnota_stato_code <> 'A' and
          a.data_cancellazione IS NULL AND
          b.data_cancellazione IS NULL AND
          c.data_cancellazione IS NULL AND
          d.data_cancellazione IS NULL AND
          e.data_cancellazione IS NULL AND
          f.data_cancellazione IS NULL AND
          g.data_cancellazione IS NULL AND
          h.data_cancellazione IS NULL AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          m.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL AND
          o.data_cancellazione IS NULL AND
          p.data_cancellazione IS NULL AND
          --q.data_cancellazione IS NULL AND -- SIAC-5696
          r.data_cancellazione IS NULL AND
          --s.data_cancellazione IS NULL AND -- SIAC-5696
          --t.data_cancellazione IS NULL -- SIAC-5696
          (q.data_cancellazione IS NULL -- SIAC-5696 INIZIO
               OR
               q.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
               ) -- SIAC-5696 FINE
          and d.collegamento_tipo_code in ('SE','SS')
          and ((s.data_cancellazione is null and s.validita_fine is null) -- SIAC-5941 Integrazione INIZIO
                or s.causale_ep_stato_id =
               (select d_caus_stato.causale_ep_stato_id
                from   siac_d_causale_ep_stato d_caus_stato
                where  d_caus_stato.causale_ep_stato_id = s.causale_ep_stato_id
                and    d_caus_stato.causale_ep_stato_code = 'V'
                )
               )  -- SIAC-5941 Integrazione FINE
  ),
  movepdet as
  (
	with
    aa as
    (
	  select a.movep_id,
             b.pdce_conto_id,
	         a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
		     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
			 b.pdce_conto_code cod_piano_dei_conti,
		     b.pdce_conto_desc desc_piano_dei_conti,
	         b.livello livello_piano_dei_conti,
		     b.ordine ordine_piano_dei_conti,
		     d.pdce_fam_code cod_pdce_fam,
			 d.pdce_fam_desc desc_pdce_fam,
 		     e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c,siac_d_pdce_fam d,siac_d_ambito e
      where a.ente_proprietario_id= p_ente_proprietario_id
      and   b.pdce_conto_id=a.pdce_conto_id
      and   c.pdce_fam_tree_id=b.pdce_fam_tree_id
      and   d.pdce_fam_id=c.pdce_fam_id
      and   c.validita_fine is null
      and   e.ambito_id=a.ambito_id
	  and   a.data_cancellazione is null
--	  and   b.data_cancellazione is null -- 27.06.2018 Sofia jira siac-6282
	  and   c.data_cancellazione is null
	  and   d.data_cancellazione is null
	  and   e.data_cancellazione is null
   ),
   bb as
   (
   SELECT c.pdce_conto_id,
         case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
              when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
		      when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
		      when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
		      when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
		      when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
			  when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
			  else ''::varchar end as tipo_codifica,
		      a.codice_codifica_albero
   FROM siac_v_dwh_codifiche_econpatr a,
        siac_r_pdce_conto_class b,
        siac_t_pdce_conto c
   WHERE b.classif_id = a.classif_id
   AND   c.pdce_conto_id = b.pdce_conto_id
   and   c.ente_proprietario_id= p_ente_proprietario_id
--   and   c.data_cancellazione is null -- 27.06.2018 Sofia jira siac-6282
   and   b.data_cancellazione is NULL
   and   b.validita_fine is null
  )
  select aa.*,
         bb.tipo_codifica||'.'||  bb.codice_codifica_albero cod_bilancio
  from aa
       left join bb on aa.pdce_conto_id=bb.pdce_conto_id
  ),
  doc as
  (with
   aa as
   (
	select a.doc_id,
		   b.subdoc_id, b.subdoc_numero  num_subdoc,
		   a.doc_anno anno_doc,
		   a.doc_numero num_doc,
	       a.doc_data_emissione data_emissione_doc ,
		   c.doc_tipo_code cod_tipo_doc
	 from siac_t_doc a,siac_t_subdoc b,siac_d_doc_tipo c
	 where b.doc_id=a.doc_id
     and   a.ente_proprietario_id=p_ente_proprietario_id
     and   c.doc_tipo_id=a.doc_tipo_id
     and   a.data_cancellazione is null
     and   b.data_cancellazione is null
     and   c.data_cancellazione is NULL
   ),
   bb as
  (SELECT  a.doc_id,
           b.soggetto_code v_soggetto_code
   FROM   siac_r_doc_sog a, siac_t_soggetto b
   WHERE a.soggetto_id = b.soggetto_id
     and a.ente_proprietario_id=p_ente_proprietario_id
     and a.data_cancellazione is null
     and b.data_cancellazione is null
     and a.validita_fine is null
  )
  select -- SIAC-5573
         -- *
         aa.*,
         bb.v_soggetto_code
  From aa left join bb ON aa.doc_id=bb.doc_id
 ),
 pdc as
 (select distinct
         a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
         b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
  from siac_t_class a,siac_r_causale_ep_class b
  where a.ente_proprietario_id=p_ente_proprietario_id
  and   b.classif_id=a.classif_id
  -- and b.validita_fine is null
  and a.data_cancellazione is null
  -- and b.data_cancellazione is null
  and (b.data_cancellazione IS NULL -- SIAC-5941 Integrazione
       or
       b.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
      )
  )
  select movep.*,
         movepdet.* ,
         pdc.cod_piano_finanziario,pdc.desc_piano_finanziario,
        null::integer anno_movimento,
        null::numeric numero_movimento,
        null::varchar cod_submovimento,
        null::integer anno_ordinativo,
        null::numeric num_ordinativo,
        null::varchar num_subordinativo,
        null::integer anno_liquidazione,
        null::numeric num_liquidazione,
        -- SIAC-5573
        doc.doc_id,
        doc.anno_doc,
        doc.num_doc,
	    doc.cod_tipo_doc,
	    doc.data_emissione_doc,
	    doc.v_soggetto_code cod_sogg_doc,
	    doc.num_subdoc,
	    null::varchar modifica_impegno,
	    case -- SIAC-5601
	      when movepdet.cod_ambito = 'AMBITO_GSA' then
          case when movep.cod_tipo_mov_finanziario = 'SE' then 'E' else 'U' end
		  else  pdc.entrate_uscite
		end entrate_uscite,
       -- pdc.entrate_uscite,
       p_data data_elaborazione,
       null::integer numero_ricecon
    from movep
         left join movepdet on movep.movep_id=movepdet.movep_id
         left join doc      on movep.campo_pk_id=doc.subdoc_id
         left join pdc      on movep.causale_ep_id=pdc.causale_ep_id
) as tbdoc
-- impegni
UNION
select tbimp.*
from
(
-- imp
with
movep as
(
  select distinct
		 a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno,
	     m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,
	     m.pnota_progressivogiornale num_definitivo_prima_nota,
		 m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
		 o.pnota_stato_code cod_stato_prima_nota,
	     o.pnota_stato_desc desc_stato_prima_nota,
	     l.movep_id, --da non visualizzare
		 l.movep_code cod_mov_ep,
		 l.movep_desc desc_mov_ep,
	     q.causale_ep_code cod_causale,
	     q.causale_ep_desc desc_causale,
	     r.causale_ep_tipo_code cod_tipo_causale,
	     r.causale_ep_tipo_desc desc_tipo_causale,
	     t.causale_ep_stato_code cod_stato_causale,
	     t.causale_ep_stato_desc desc_stato_causale,
	     c.evento_code cod_evento,
         c.evento_desc desc_evento,
         d.collegamento_tipo_code cod_tipo_mov_finanziario,
         d.collegamento_tipo_desc desc_tipo_mov_finanziario,
         b.campo_pk_id ,
         q.causale_ep_id,
         g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
/*         left join siac_r_causale_ep_stato s on s.causale_ep_id=q.causale_ep_id -- SIAC-5696 INIZIO
                                             and s.data_cancellazione is null
                                             and s.validita_fine is null
         left join siac_d_causale_ep_stato t on s.causale_ep_stato_id=t.causale_ep_stato_id
                                             and t.data_cancellazione is null, -- SIAC-5696 FINE   */
         siac_r_causale_ep_stato s, -- SIAC-5941
         siac_d_causale_ep_stato t, -- SIAC-5941
         siac_d_causale_ep_tipo r
    WHERE  a.ente_proprietario_id=p_ente_proprietario_id
    and    i.anno=p_anno_bilancio
    and    a.regmovfin_id = b.regmovfin_id
    and    c.evento_id = b.evento_id
    AND    d.collegamento_tipo_id = c.collegamento_tipo_id
    AND    g.evento_tipo_id = c.evento_tipo_id
    AND    e.regmovfin_id = a.regmovfin_id
    AND    f.regmovfin_stato_id = e.regmovfin_stato_id
    AND    p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data)
    and    p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data)
          --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
          --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
    and   h.bil_id = a.bil_id
    AND   i.periodo_id = h.periodo_id
    AND   l.regmovfin_id = a.regmovfin_id
    AND   l.regep_id = m.pnota_id
    AND   m.pnota_id = n.pnota_id
    AND   o.pnota_stato_id = n.pnota_stato_id
    AND   p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data)
          --p_data >= n.validita_inizio AND  p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
    and   p.ente_proprietario_id=a.ente_proprietario_id
    and   q.causale_ep_id=l.causale_ep_id
    AND   r.causale_ep_tipo_id=q.causale_ep_tipo_id
    and   s.causale_ep_id=q.causale_ep_id  -- SIAC-5941 -- SIAC-5696
    and   s.causale_ep_stato_id=t.causale_ep_stato_id  -- SIAC-5941 -- SIAC-5696
          --s.validita_fine is NULL and -- SIAC-5696
    and   o.pnota_stato_code <> 'A'
    and   a.data_cancellazione IS NULL
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
    AND   o.data_cancellazione IS NULL
    AND   p.data_cancellazione IS NULL
    --q.data_cancellazione IS NULL AND -- SIAC-5696
    and   r.data_cancellazione IS NULL
    --s.data_cancellazione IS NULL AND -- SIAC-5696
    --t.data_cancellazione IS NULL -- SIAC-5696
    and (q.data_cancellazione is NULL -- SIAC-5696 INIZIO
               OR
               q.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
         ) -- SIAC-5696 FINE
    and d.collegamento_tipo_code in ('A','I')
    and ((s.data_cancellazione is null and s.validita_fine is null) -- SIAC-5941 Integrazione INIZIO
                or s.causale_ep_stato_id =
               (select d_caus_stato.causale_ep_stato_id
                from   siac_d_causale_ep_stato d_caus_stato
                where  d_caus_stato.causale_ep_stato_id = s.causale_ep_stato_id
                and    d_caus_stato.causale_ep_stato_code = 'V'
                )
               )  -- SIAC-5941 Integrazione FINE
  ),
  movepdet as
  (
	with aa as
    (
	  select a.movep_id, b.pdce_conto_id,
    		 a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
		     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
			 b.pdce_conto_code cod_piano_dei_conti,
		     b.pdce_conto_desc desc_piano_dei_conti,
	         b.livello livello_piano_dei_conti,
		     b.ordine ordine_piano_dei_conti,
	         d.pdce_fam_code cod_pdce_fam,
	         d.pdce_fam_desc desc_pdce_fam,
	         e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c,siac_d_pdce_fam d,siac_d_ambito e
      where a.ente_proprietario_id=p_ente_proprietario_id
        and b.pdce_conto_id=a.pdce_conto_id
        and c.pdce_fam_tree_id=b.pdce_fam_tree_id
        and d.pdce_fam_id=c.pdce_fam_id
        and c.validita_fine is null
        and e.ambito_id=a.ambito_id
        and a.data_cancellazione is null
--        and b.data_cancellazione is null 27.06.2018 Sofia Jira siac-6282
        and c.data_cancellazione is null
        and d.data_cancellazione is null
        and e.data_cancellazione is null
   ),
   bb as
   ( /*SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
	SELECT c.pdce_conto_id,
           case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
				when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
				when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
				when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
				when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
				when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
				when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
				else ''::varchar end as tipo_codifica,
				a.codice_codifica_albero
	FROM siac_v_dwh_codifiche_econpatr a,
	     siac_r_pdce_conto_class b,
	     siac_t_pdce_conto c
    WHERE b.classif_id = a.classif_id
    AND   c.pdce_conto_id = b.pdce_conto_id
    and   c.ente_proprietario_id=p_ente_proprietario_id
--	and   c.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
	and   b.data_cancellazione is NULL
	and   b.validita_fine is null
   )
   select aa.*,
          bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio
   from aa left join bb on aa.pdce_conto_id=bb.pdce_conto_id
  ),
  imp as
  (
  select a.movgest_id,a.movgest_anno anno_movimento,a.movgest_numero numero_movimento
  from siac_t_movgest a
  where a.ente_proprietario_id=p_ente_proprietario_id
  and   a.data_cancellazione is null
  ),
  pdc as
  (select distinct a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
		  b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
   from siac_t_class a,siac_r_causale_ep_class b
   where a.ente_proprietario_id=p_ente_proprietario_id
   and   b.classif_id=a.classif_id
  -- and b.validita_fine is null
   and   a.data_cancellazione is null
  -- and b.data_cancellazione is null
  and (b.data_cancellazione IS NULL -- SIAC-5941 Integrazione
       or
       b.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
      )
  )
  select movep.*,
         movepdet.*,
         pdc.cod_piano_finanziario,pdc.desc_piano_finanziario,
         imp.anno_movimento,imp.numero_movimento,
         null::varchar cod_submovimento,
         null::integer anno_ordinativo,
         null::numeric num_ordinativo,
		 null::varchar num_subordinativo,
	     null::integer anno_liquidazione,
	     null::numeric num_liquidazione,
	     -- SIAC-5573
	     null::integer doc_id,
	     null::integer anno_doc,
	     null::varchar num_doc,
	     null::varchar cod_tipo_doc,
 		 null::timestamp data_emissione_doc,
	     null::varchar cod_sogg_doc,
	     null::integer num_subdoc,
	     null::varchar modifica_impegno,
	     case -- SIAC-5601
		 when movepdet.cod_ambito = 'AMBITO_GSA' then
		      case when movep.cod_tipo_mov_finanziario = 'A' then 'E' else 'U' end
			  else pdc.entrate_uscite
			  end entrate_uscite,
			-- pdc.entrate_uscite,
		p_data data_elaborazione,
		null::integer numero_ricecon
 from movep
      left join movepdet on movep.movep_id=movepdet.movep_id
      left join imp on movep.campo_pk_id=imp.movgest_id
      left join pdc on movep.causale_ep_id=pdc.causale_ep_id
) as tbimp

UNION
--subimp subacc
select tbimp.*
from
(
-- imp
with
movep as
(
  select distinct
		 a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno,
	     m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,
	     m.pnota_progressivogiornale num_definitivo_prima_nota,
		 m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
		 o.pnota_stato_code cod_stato_prima_nota,
		 o.pnota_stato_desc desc_stato_prima_nota,
		 l.movep_id, --da non visualizzare
		 l.movep_code cod_mov_ep,
	     l.movep_desc desc_mov_ep,
	     q.causale_ep_code cod_causale,
	     q.causale_ep_desc desc_causale,
	     r.causale_ep_tipo_code cod_tipo_causale,
	     r.causale_ep_tipo_desc desc_tipo_causale,
	     t.causale_ep_stato_code cod_stato_causale,
	     t.causale_ep_stato_desc desc_stato_causale,
         c.evento_code cod_evento,
         c.evento_desc desc_evento,
         d.collegamento_tipo_code cod_tipo_mov_finanziario,
         d.collegamento_tipo_desc desc_tipo_mov_finanziario,
         b.campo_pk_id ,
         q.causale_ep_id,
         g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
/*         left join siac_r_causale_ep_stato s on s.causale_ep_id=q.causale_ep_id -- SIAC-5696 INIZIO
                                             and s.data_cancellazione is null
                                             and s.validita_fine is null
         left join siac_d_causale_ep_stato t on s.causale_ep_stato_id=t.causale_ep_stato_id
                                             and t.data_cancellazione is null, -- SIAC-5696 FINE  */
         siac_r_causale_ep_stato s, -- SIAC-5941
         siac_d_causale_ep_stato t, -- SIAC-5941
         siac_d_causale_ep_tipo r
    WHERE a.ente_proprietario_id=p_ente_proprietario_id
    and   i.anno=p_anno_bilancio
    and   a.regmovfin_id = b.regmovfin_id
    and   c.evento_id = b.evento_id
    AND   d.collegamento_tipo_id = c.collegamento_tipo_id
    AND   g.evento_tipo_id = c.evento_tipo_id
    AND   e.regmovfin_id = a.regmovfin_id
    AND   f.regmovfin_stato_id = e.regmovfin_stato_id
    AND   p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data)
    and   p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data)
    --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
     --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
    and   h.bil_id = a.bil_id
    AND   i.periodo_id = h.periodo_id
    AND   l.regmovfin_id = a.regmovfin_id
    AND   l.regep_id = m.pnota_id
    AND   m.pnota_id = n.pnota_id
    AND   o.pnota_stato_id = n.pnota_stato_id
    AND   p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data)
     --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
    and   p.ente_proprietario_id=a.ente_proprietario_id
    and   q.causale_ep_id=l.causale_ep_id
    AND   r.causale_ep_tipo_id=q.causale_ep_tipo_id
    and   s.causale_ep_id=q.causale_ep_id
     -- SIAC-5941 -- SIAC-5696
    and   s.causale_ep_stato_id=t.causale_ep_stato_id -- SIAC-5941 -- SIAC-5696
          --s.validita_fine is NULL and -- SIAC-5696
    and   o.pnota_stato_code <> 'A'
    and   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL
    AND   c.data_cancellazione IS NULL AND
          d.data_cancellazione IS NULL AND
          e.data_cancellazione IS NULL AND
          f.data_cancellazione IS NULL AND
          g.data_cancellazione IS NULL AND
          h.data_cancellazione IS NULL AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          m.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL AND
          o.data_cancellazione IS NULL AND
          p.data_cancellazione IS NULL AND
          --q.data_cancellazione IS NULL AND -- SIAC-5696
          r.data_cancellazione IS NULL AND
          --s.data_cancellazione IS NULL AND -- SIAC-5696
          --t.data_cancellazione IS NULL -- SIAC-5696
          (q.data_cancellazione is NULL -- SIAC-5696 INIZIO
               OR
               q.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
               )-- SIAC-5696 FINE
          and d.collegamento_tipo_code in ('SA','SI')
          and ((s.data_cancellazione is null and s.validita_fine is null) -- SIAC-5941 Integrazione INIZIO
                or s.causale_ep_stato_id =
               (select d_caus_stato.causale_ep_stato_id
                from   siac_d_causale_ep_stato d_caus_stato
                where  d_caus_stato.causale_ep_stato_id = s.causale_ep_stato_id
                and    d_caus_stato.causale_ep_stato_code = 'V'
                )
               )  -- SIAC-5941 Integrazione FINE
  ),
  movepdet as
  (
	with aa as
    (
     select a.movep_id, b.pdce_conto_id,
    		a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
		    a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
		    b.pdce_conto_code cod_piano_dei_conti,
		    b.pdce_conto_desc desc_piano_dei_conti,
	        b.livello livello_piano_dei_conti,
	        b.ordine ordine_piano_dei_conti,
			d.pdce_fam_code cod_pdce_fam,
			d.pdce_fam_desc desc_pdce_fam,
			e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c,siac_d_pdce_fam d,siac_d_ambito e
      where a.ente_proprietario_id=p_ente_proprietario_id
	    and b.pdce_conto_id=a.pdce_conto_id
        and c.pdce_fam_tree_id=b.pdce_fam_tree_id
        and d.pdce_fam_id=c.pdce_fam_id
        and c.validita_fine is null
        and e.ambito_id=a.ambito_id
        and a.data_cancellazione is null
    --    and b.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
        and c.data_cancellazione is null
        and d.data_cancellazione is null
        and e.data_cancellazione is null
    ),
    bb as
    ( /*SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
	SELECT c.pdce_conto_id,
           case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
				when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
				when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
				when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
				when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
				when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
				when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
				else ''::varchar end as tipo_codifica,
				a.codice_codifica_albero
	FROM siac_v_dwh_codifiche_econpatr a,
	     siac_r_pdce_conto_class b,
		 siac_t_pdce_conto c
	WHERE b.classif_id = a.classif_id
    AND   c.pdce_conto_id = b.pdce_conto_id
	and   c.ente_proprietario_id=p_ente_proprietario_id
--	and   c.data_cancellazione is null 28.06.2018 Sofia jira siac-6282
	and   b.data_cancellazione is NULL
	and   b.validita_fine is null
  )
  select aa.*,
         bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio
  from aa left join bb on aa.pdce_conto_id=bb.pdce_conto_id
  ),
  subimp as
  (
  select a.movgest_id,a.movgest_anno anno_movimento,a.movgest_numero numero_movimento,
  		 b.movgest_ts_id,b.movgest_ts_code cod_submovimento
  from siac_t_movgest a,siac_T_movgest_ts b
  where a.ente_proprietario_id=p_ente_proprietario_id
  and   a.data_cancellazione is null
  and   b.data_cancellazione is null
  and   b.movgest_id=a.movgest_id
  ),
  pdc as
  (select distinct
          a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
		  b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
   from siac_t_class a,siac_r_causale_ep_class b
   where a.ente_proprietario_id=p_ente_proprietario_id
   and   b.classif_id=a.classif_id
  -- and b.validita_fine is null
   and a.data_cancellazione is null
  -- and b.data_cancellazione is null
   and (b.data_cancellazione IS NULL -- SIAC-5941 Integrazione
       or
       b.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
       )
  )
  select movep.*,
         movepdet.* ,
         pdc.cod_piano_finanziario,pdc.desc_piano_finanziario, subimp.anno_movimento,
		 subimp.numero_movimento,
		 subimp.cod_submovimento,
         null::integer anno_ordinativo,
		 null::numeric num_ordinativo,
		 null::varchar num_subordinativo,
	     null::integer anno_liquidazione,
		 null::numeric num_liquidazione,
	     -- SIAC-5573
		 null::integer doc_id,
		 null::integer anno_doc,
		 null::varchar num_doc,
		 null::varchar cod_tipo_doc,
		 null::timestamp data_emissione_doc,
		 null::varchar cod_sogg_doc,
		 null::integer num_subdoc,
		 null::varchar modifica_impegno,
		 case -- SIAC-5601
          when movepdet.cod_ambito = 'AMBITO_GSA' then
		       case when movep.cod_tipo_mov_finanziario = 'SA' then 'E' else 'U' end
		  else pdc.entrate_uscite
		  end entrate_uscite,
		  -- pdc.entrate_uscite,
		  p_data data_elaborazione,
		  null::integer numero_ricecon
   from movep
        left join movepdet on movep.movep_id=movepdet.movep_id
		left join subimp   on movep.campo_pk_id=subimp.movgest_ts_id
        left join pdc      on movep.causale_ep_id=pdc.causale_ep_id
) as tbimp

-- ordinativi
union
select tbord.*
from
(
-- ord
with movep as
(
  select distinct
		 a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno,
		 m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,
		 m.pnota_progressivogiornale num_definitivo_prima_nota,
		 m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
		 o.pnota_stato_code cod_stato_prima_nota,
		 o.pnota_stato_desc desc_stato_prima_nota,
		 l.movep_id, --da non visualizzare
		 l.movep_code cod_mov_ep,
		 l.movep_desc desc_mov_ep,
		 q.causale_ep_code cod_causale,
		 q.causale_ep_desc desc_causale,
	 	 r.causale_ep_tipo_code cod_tipo_causale,
		 r.causale_ep_tipo_desc desc_tipo_causale,
		 t.causale_ep_stato_code cod_stato_causale,
		 t.causale_ep_stato_desc desc_stato_causale,
         c.evento_code cod_evento,
         c.evento_desc desc_evento,
         d.collegamento_tipo_code cod_tipo_mov_finanziario,
         d.collegamento_tipo_desc desc_tipo_mov_finanziario,
         b.campo_pk_id ,
         q.causale_ep_id,
         g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
/*         left join siac_r_causale_ep_stato s on s.causale_ep_id=q.causale_ep_id -- SIAC-5696 INIZIO
                                             and s.data_cancellazione is null
                                             and s.validita_fine is null
         left join siac_d_causale_ep_stato t on s.causale_ep_stato_id=t.causale_ep_stato_id
                                             and t.data_cancellazione is null, -- SIAC-5696 FINE    */
         siac_r_causale_ep_stato s, -- SIAC-5941
         siac_d_causale_ep_stato t, -- SIAC-5941
         siac_d_causale_ep_tipo r
    WHERE a.ente_proprietario_id=p_ente_proprietario_id
    and   i.anno=p_anno_bilancio
    and   a.regmovfin_id = b.regmovfin_id
    and   c.evento_id = b.evento_id
    AND   d.collegamento_tipo_id = c.collegamento_tipo_id
    AND   g.evento_tipo_id = c.evento_tipo_id
    AND   e.regmovfin_id = a.regmovfin_id
    AND   f.regmovfin_stato_id = e.regmovfin_stato_id
    AND   p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data)
    and   p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data)
    --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
    --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
    and   h.bil_id = a.bil_id
    AND   i.periodo_id = h.periodo_id
    AND   l.regmovfin_id = a.regmovfin_id
    AND   l.regep_id = m.pnota_id
    AND   m.pnota_id = n.pnota_id
    AND   o.pnota_stato_id = n.pnota_stato_id
    AND   p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data)
    --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
    and   p.ente_proprietario_id=a.ente_proprietario_id
    and   q.causale_ep_id=l.causale_ep_id
    AND   r.causale_ep_tipo_id=q.causale_ep_tipo_id
    and   s.causale_ep_id=q.causale_ep_id
    -- SIAC-5941 -- SIAC-5696          s.causale_ep_stato_id=t.causale_ep_stato_id and -- SIAC-5941 -- SIAC-5696
     --s.validita_fine is NULL and -- SIAC-5696
    and   o.pnota_stato_code <> 'A'
    and   a.data_cancellazione IS NULL
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
    AND   o.data_cancellazione IS NULL
    AND   p.data_cancellazione IS NULL
    --q.data_cancellazione IS NULL AND -- SIAC-5696
    and r.data_cancellazione IS NULL
    --s.data_cancellazione IS NULL AND -- SIAC-5696
    --t.data_cancellazione IS NULL -- SIAC-5696
   and (q.data_cancellazione is NULL -- SIAC-5696 INIZIO
               OR
               q.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
        )
  -- SIAC-5696 FINE
  and d.collegamento_tipo_code in ('OI', 'OP')
  and ((s.data_cancellazione is null and s.validita_fine is null) -- SIAC-5941 Integrazione INIZIO
                or s.causale_ep_stato_id =
               (select d_caus_stato.causale_ep_stato_id
                from   siac_d_causale_ep_stato d_caus_stato
                where  d_caus_stato.causale_ep_stato_id = s.causale_ep_stato_id
                and    d_caus_stato.causale_ep_stato_code = 'V'
                )
       )  -- SIAC-5941 Integrazione FINE
 ),
 movepdet as
 (
  with aa as
  (
  select a.movep_id, b.pdce_conto_id,
  	     a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
	     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
		 b.pdce_conto_code cod_piano_dei_conti,
		 b.pdce_conto_desc desc_piano_dei_conti,
		 b.livello livello_piano_dei_conti,
		 b.ordine ordine_piano_dei_conti,
		 d.pdce_fam_code cod_pdce_fam,
		 d.pdce_fam_desc desc_pdce_fam,
		 e.ambito_code cod_ambito, e.ambito_desc desc_ambito
  From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c,siac_d_pdce_fam d,siac_d_ambito e
  where a.ente_proprietario_id=p_ente_proprietario_id
    and b.pdce_conto_id=a.pdce_conto_id
    and c.pdce_fam_tree_id=b.pdce_fam_tree_id
    and d.pdce_fam_id=c.pdce_fam_id
    and c.validita_fine is null
    and e.ambito_id=a.ambito_id
    and a.data_cancellazione is null
 --   and b.data_cancellazione is null 27.06.2018 Sofia Jira siac-6282
    and c.data_cancellazione is null
    and d.data_cancellazione is null
    and e.data_cancellazione is null
 ),
 bb as
 (/* SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
  SELECT c.pdce_conto_id,
  	  	 case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
			  when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
			  when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
			  when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
			  when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
			  when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
			  when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
			  else ''::varchar end as tipo_codifica,
			  a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
	   siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id
  AND   c.pdce_conto_id = b.pdce_conto_id
  and   c.ente_proprietario_id=p_ente_proprietario_id
  --and   c.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
  and   b.data_cancellazione is NULL
  and   b.validita_fine is null
 )
 select aa.*,
       bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio
 from aa left join  bb on aa.pdce_conto_id=bb.pdce_conto_id
 ),
 ord as
 (select a.ord_id,a.ord_anno anno_ordinativo,a.ord_numero num_ordinativo
  from siac_t_ordinativo a
  where a.ente_proprietario_id=p_ente_proprietario_id
  and   a.data_cancellazione is null
 ),
 pdc as
 (select distinct
         a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
		 b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
  from siac_t_class a,siac_r_causale_ep_class b
  where a.ente_proprietario_id=p_ente_proprietario_id
  and   b.classif_id=a.classif_id
  -- and b.validita_fine is null
  and a.data_cancellazione is null
  -- and b.data_cancellazione is null
  and (b.data_cancellazione IS NULL -- SIAC-5941 Integrazione
       or
       b.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
      )
  )
/*  ,liq as (select a.liq_id,a.liq_anno anno_liquidazione,a.liq_numero num_liquidazione from siac_t_liquidazione a where a.ente_proprietario_id=3
and a.data_cancellazione is null)  */
   select movep.*,
          movepdet.* ,
          pdc.cod_piano_finanziario,pdc.desc_piano_finanziario,
		  null::integer anno_movimento,null::numeric numero_movimento,
          null::varchar cod_submovimento,
          ord.anno_ordinativo,
		  ord.num_ordinativo,
		  null::varchar num_subordinativo,
		  null::integer anno_liquidazione,
		  null::numeric num_liquidazione,
 		  -- SIAC-5573
		  null::integer doc_id,
		  null::integer anno_doc,
		  null::varchar num_doc,
		  null::varchar cod_tipo_doc,
		  null::timestamp data_emissione_doc,
		  null::varchar cod_sogg_doc,
		  null::integer num_subdoc,
		  null::varchar modifica_impegno,
		  case -- SIAC-5601
			  when movepdet.cod_ambito = 'AMBITO_GSA' then
                   case when movep.cod_tipo_mov_finanziario = 'OI' then 'E' else 'U' end
				   else pdc.entrate_uscite
				   end entrate_uscite,
				   -- pdc.entrate_uscite,
			 p_data data_elaborazione,
		     null::integer numero_ricecon
	   from movep
            left join movepdet on movep.movep_id=movepdet.movep_id
            left join ord on movep.campo_pk_id=ord.ord_id
            left join pdc on movep.causale_ep_id=pdc.causale_ep_id
) as tbord

-- liquidazioni
UNION
-- liq
select tbliq.*
from
(
with movep as
(
  select distinct
		 a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno,
	     m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,
    	 m.pnota_progressivogiornale num_definitivo_prima_nota,
		 m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
		 o.pnota_stato_code cod_stato_prima_nota,
		 o.pnota_stato_desc desc_stato_prima_nota,
		 l.movep_id, --da non visualizzare
		 l.movep_code cod_mov_ep,
		 l.movep_desc desc_mov_ep,
		 q.causale_ep_code cod_causale,
		 q.causale_ep_desc desc_causale,
		 r.causale_ep_tipo_code cod_tipo_causale,
		 r.causale_ep_tipo_desc desc_tipo_causale,
		 t.causale_ep_stato_code cod_stato_causale,
		 t.causale_ep_stato_desc desc_stato_causale,
         c.evento_code cod_evento,
         c.evento_desc desc_evento,
         d.collegamento_tipo_code cod_tipo_mov_finanziario,
         d.collegamento_tipo_desc desc_tipo_mov_finanziario,
         b.campo_pk_id ,
         q.causale_ep_id,
         g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
/*         left join siac_r_causale_ep_stato s on s.causale_ep_id=q.causale_ep_id -- SIAC-5696 INIZIO
                                             and s.data_cancellazione is null
                                             and s.validita_fine is null
         left join siac_d_causale_ep_stato t on s.causale_ep_stato_id=t.causale_ep_stato_id
                                             and t.data_cancellazione is null, -- SIAC-5696 FINE   */
         siac_r_causale_ep_stato s, -- SIAC-5941
         siac_d_causale_ep_stato t, -- SIAC-5941
         siac_d_causale_ep_tipo r
    WHERE a.ente_proprietario_id=p_ente_proprietario_id
    and   i.anno=p_anno_bilancio
    and   a.regmovfin_id = b.regmovfin_id
    and   c.evento_id = b.evento_id
    AND   d.collegamento_tipo_id = c.collegamento_tipo_id
    AND   g.evento_tipo_id = c.evento_tipo_id
    AND   e.regmovfin_id = a.regmovfin_id
    AND   f.regmovfin_stato_id = e.regmovfin_stato_id
    AND   p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data)
    and   p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data)
    --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
    --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
    and   h.bil_id = a.bil_id
    AND   i.periodo_id = h.periodo_id
    AND   l.regmovfin_id = a.regmovfin_id
    AND   l.regep_id = m.pnota_id
    AND   m.pnota_id = n.pnota_id
    AND   o.pnota_stato_id = n.pnota_stato_id
    AND   p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data)
    --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
    and   p.ente_proprietario_id=a.ente_proprietario_id
    and   q.causale_ep_id=l.causale_ep_id
    AND   r.causale_ep_tipo_id=q.causale_ep_tipo_id
    and   s.causale_ep_id=q.causale_ep_id -- SIAC-5941 -- SIAC-5696
    and   s.causale_ep_stato_id=t.causale_ep_stato_id  -- SIAC-5941 -- SIAC-5696
    --s.validita_fine is NULL and -- SIAC-5696
    and   o.pnota_stato_code <> 'A'
    and   a.data_cancellazione IS NULL AND
          b.data_cancellazione IS NULL AND
          c.data_cancellazione IS NULL AND
          d.data_cancellazione IS NULL AND
          e.data_cancellazione IS NULL AND
          f.data_cancellazione IS NULL AND
          g.data_cancellazione IS NULL AND
          h.data_cancellazione IS NULL AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          m.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL AND
          o.data_cancellazione IS NULL AND
          p.data_cancellazione IS NULL AND
          --q.data_cancellazione IS NULL AND -- SIAC-5696
          r.data_cancellazione IS NULL
          --s.data_cancellazione IS NULL AND -- SIAC-5696
          --t.data_cancellazione IS NULL -- SIAC-5696
    and   (q.data_cancellazione is NULL -- SIAC-5696 INIZIO
               OR
               q.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
          )-- SIAC-5696 FINE
    and d.collegamento_tipo_code ='L'
    and ((s.data_cancellazione is null and s.validita_fine is null) -- SIAC-5941 Integrazione INIZIO
                or s.causale_ep_stato_id =
               (select d_caus_stato.causale_ep_stato_id
                from   siac_d_causale_ep_stato d_caus_stato
                where  d_caus_stato.causale_ep_stato_id = s.causale_ep_stato_id
                and    d_caus_stato.causale_ep_stato_code = 'V'
                )
         )  -- SIAC-5941 Integrazione FINE
 ),
 movepdet as
 (
	with aa as
    (
	  select a.movep_id, b.pdce_conto_id,
    		 a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
		     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
			 b.pdce_conto_code cod_piano_dei_conti,
		     b.pdce_conto_desc desc_piano_dei_conti,
		     b.livello livello_piano_dei_conti,
			 b.ordine ordine_piano_dei_conti,
			 d.pdce_fam_code cod_pdce_fam,
			 d.pdce_fam_desc desc_pdce_fam,
			 e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c,siac_d_pdce_fam d,siac_d_ambito e
      where a.ente_proprietario_id=p_ente_proprietario_id
      and   b.pdce_conto_id=a.pdce_conto_id
      and   c.pdce_fam_tree_id=b.pdce_fam_tree_id
      and   d.pdce_fam_id=c.pdce_fam_id
      and   c.validita_fine is null
      and   e.ambito_id=a.ambito_id
      and   a.data_cancellazione is null
--      and   b.data_cancellazione is null 28.06.2018 Sofia jira siac-6282
	  and   c.data_cancellazione is null
	  and   d.data_cancellazione is null
	  and   e.data_cancellazione is null
     ),
     bb as
     ( /*SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
	SELECT c.pdce_conto_id,
           case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
				when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
				when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
				when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
				when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
				when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
				when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
				else ''::varchar end as tipo_codifica,
				a.codice_codifica_albero
	FROM siac_v_dwh_codifiche_econpatr a,
		 siac_r_pdce_conto_class b,
		 siac_t_pdce_conto c
	WHERE b.classif_id = a.classif_id
    AND   c.pdce_conto_id = b.pdce_conto_id
	and   c.ente_proprietario_id=p_ente_proprietario_id
--	and   c.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
    and   b.data_cancellazione is NULL
    and   b.validita_fine is null
  )
  select aa.*,
         bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio
  from aa
       left join  bb on aa.pdce_conto_id=bb.pdce_conto_id
 ),
 liq as
 (
   select a.liq_id,a.liq_anno anno_liquidazione,a.liq_numero num_liquidazione
   from siac_t_liquidazione a
   where a.ente_proprietario_id=p_ente_proprietario_id
   and   a.data_cancellazione is null
 ),
 pdc as
 (select distinct
         a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
         b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
  from siac_t_class a,siac_r_causale_ep_class b
  where a.ente_proprietario_id=p_ente_proprietario_id
  and   b.classif_id=a.classif_id
  -- and b.validita_fine is null
  and a.data_cancellazione is null
  -- and b.data_cancellazione is null
  and (b.data_cancellazione IS NULL -- SIAC-5941 Integrazione
       or
       b.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
      )
 )
 select movep.*,
        movepdet.* ,
        pdc.cod_piano_finanziario,pdc.desc_piano_finanziario,
        null::integer anno_movimento,
        null::numeric numero_movimento,
        null::varchar cod_submovimento,
        null::integer anno_ordinativo,
        null::numeric num_ordinativo,
        null::varchar num_subordinativo,
        liq.anno_liquidazione,
        liq.num_liquidazione,
        -- SIAC-5573
        null::integer doc_id,
        null::integer anno_doc,
        null::varchar num_doc,
        null::varchar cod_tipo_doc,
        null::timestamp data_emissione_doc,
        null::varchar cod_sogg_doc,
        null::integer num_subdoc,
        null::varchar modifica_impegno,
        case -- SIAC-5601
            when movepdet.cod_ambito = 'AMBITO_GSA' then
                 case when movep.cod_tipo_mov_finanziario = 'L' then 'U'  else  'E' end
        else pdc.entrate_uscite
        end entrate_uscite,
        -- pdc.entrate_uscite,
	    p_data data_elaborazione,
		null::integer numero_ricecon
  from movep
       left join  movepdet on movep.movep_id=movepdet.movep_id
       left join liq  on movep.campo_pk_id=liq.liq_id
       left join pdc  on movep.causale_ep_id=pdc.causale_ep_id
) as tbliq


union
--richiesta econ
select tbricecon.*
from
(
 with
 movep as
 (
  select distinct
		 a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno,
	     m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,
    	 m.pnota_progressivogiornale num_definitivo_prima_nota,
		 m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
		 o.pnota_stato_code cod_stato_prima_nota,
		 o.pnota_stato_desc desc_stato_prima_nota,
		 l.movep_id, --da non visualizzare
		 l.movep_code cod_mov_ep,
		 l.movep_desc desc_mov_ep,
		 q.causale_ep_code cod_causale,
		 q.causale_ep_desc desc_causale,
		 r.causale_ep_tipo_code cod_tipo_causale,
		 r.causale_ep_tipo_desc desc_tipo_causale,
		 t.causale_ep_stato_code cod_stato_causale,
		 t.causale_ep_stato_desc desc_stato_causale,
		 c.evento_code cod_evento,
         c.evento_desc desc_evento,
         d.collegamento_tipo_code cod_tipo_mov_finanziario,
         d.collegamento_tipo_desc desc_tipo_mov_finanziario,
         b.campo_pk_id ,
         q.causale_ep_id,
         g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
/*         left join siac_r_causale_ep_stato s on s.causale_ep_id=q.causale_ep_id -- SIAC-5696 INIZIO
                                             and s.data_cancellazione is null
                                             and s.validita_fine is null
         left join siac_d_causale_ep_stato t on s.causale_ep_stato_id=t.causale_ep_stato_id
                                             and t.data_cancellazione is null, -- SIAC-5696 FINE    */
         siac_r_causale_ep_stato s, -- SIAC-5941
         siac_d_causale_ep_stato t, -- SIAC-5941
         siac_d_causale_ep_tipo r
    WHERE a.ente_proprietario_id=p_ente_proprietario_id
    and   i.anno=p_anno_bilancio
    and   a.regmovfin_id = b.regmovfin_id
    and   c.evento_id = b.evento_id
    AND   d.collegamento_tipo_id = c.collegamento_tipo_id
    AND   g.evento_tipo_id = c.evento_tipo_id
    AND   e.regmovfin_id = a.regmovfin_id
    AND   f.regmovfin_stato_id = e.regmovfin_stato_id
    AND   p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data)
    and   p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data)
   --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
  --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
    and   h.bil_id = a.bil_id
    AND   i.periodo_id = h.periodo_id
    AND   l.regmovfin_id = a.regmovfin_id
    AND   l.regep_id = m.pnota_id
    AND   m.pnota_id = n.pnota_id
    AND   o.pnota_stato_id = n.pnota_stato_id
    AND   p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data)
   --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
    and   p.ente_proprietario_id=a.ente_proprietario_id
    and   q.causale_ep_id=l.causale_ep_id
    AND   r.causale_ep_tipo_id=q.causale_ep_tipo_id
    and   s.causale_ep_id=q.causale_ep_id
    -- SIAC-5941 -- SIAC-5696
    and  s.causale_ep_stato_id=t.causale_ep_stato_id  -- SIAC-5941 -- SIAC-5696
    --s.validita_fine is NULL and -- SIAC-5696
    and  o.pnota_stato_code <> 'A'
    and  a.data_cancellazione IS NULL AND
         b.data_cancellazione IS NULL AND
         c.data_cancellazione IS NULL AND
         d.data_cancellazione IS NULL AND
         e.data_cancellazione IS NULL AND
         f.data_cancellazione IS NULL AND
         g.data_cancellazione IS NULL AND
         h.data_cancellazione IS NULL AND
         i.data_cancellazione IS NULL AND
         l.data_cancellazione IS NULL AND
         m.data_cancellazione IS NULL AND
         n.data_cancellazione IS NULL AND
         o.data_cancellazione IS NULL AND
         p.data_cancellazione IS NULL AND
         --q.data_cancellazione IS NULL AND -- SIAC-5696
         r.data_cancellazione IS NULL
          --s.data_cancellazione IS NULL AND -- SIAC-5696
          --t.data_cancellazione IS NULL -- SIAC-5696
     and  (q.data_cancellazione is NULL -- SIAC-5696 INIZIO
               OR
               q.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
          )-- SIAC-5696 FINE
--     and d.collegamento_tipo_code ='RE'
     and d.collegamento_tipo_code IN ('RE','RR') -- SIAC-8717 Sofia 12.05.2022
     and ((s.data_cancellazione is null and s.validita_fine is null) -- SIAC-5941 Integrazione INIZIO
                or s.causale_ep_stato_id =
               (select d_caus_stato.causale_ep_stato_id
                from   siac_d_causale_ep_stato d_caus_stato
                where  d_caus_stato.causale_ep_stato_id = s.causale_ep_stato_id
                and    d_caus_stato.causale_ep_stato_code = 'V'
                )
          )   -- SIAC-5941 Integrazione FINE
  ),
  movepdet as
  (
	with
    aa as
    (
      select a.movep_id, b.pdce_conto_id,
     		 a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
		     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
		     b.pdce_conto_code cod_piano_dei_conti,
			 b.pdce_conto_desc desc_piano_dei_conti,
			 b.livello livello_piano_dei_conti,
			 b.ordine ordine_piano_dei_conti,
			 d.pdce_fam_code cod_pdce_fam,
			 d.pdce_fam_desc desc_pdce_fam,
			 e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c,siac_d_pdce_fam d,siac_d_ambito e
      where a.ente_proprietario_id=p_ente_proprietario_id
      and   b.pdce_conto_id=a.pdce_conto_id
      and   c.pdce_fam_tree_id=b.pdce_fam_tree_id
      and   d.pdce_fam_id=c.pdce_fam_id
      and   c.validita_fine is null
      and   e.ambito_id=a.ambito_id
      and a.data_cancellazione is null
   --   and b.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
      and c.data_cancellazione is null
      and d.data_cancellazione is null
      and e.data_cancellazione is null
    ),
    bb as
    ( /*SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
    SELECT c.pdce_conto_id,
           case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
		  	    when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
		        when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
				when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
				when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
				when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
				when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
				else ''::varchar end as tipo_codifica,
		  a.codice_codifica_albero
	FROM siac_v_dwh_codifiche_econpatr a,
		 siac_r_pdce_conto_class b,
		 siac_t_pdce_conto c
	WHERE b.classif_id = a.classif_id
    AND   c.pdce_conto_id = b.pdce_conto_id
	and   c.ente_proprietario_id=p_ente_proprietario_id
--	and   c.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
    and   b.data_cancellazione is NULL
    and   b.validita_fine is null
  )
  select aa.*,
         bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio
   from aa left join bb on aa.pdce_conto_id=bb.pdce_conto_id
  ),
  ricecon as
  (select a.ricecon_id,
          a.ricecon_numero numero_ricecon
   from siac_t_richiesta_econ a
   where a.ente_proprietario_id=p_ente_proprietario_id
    and  a.data_cancellazione is null
  ),
  pdc as
  (
   select distinct
          a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
		  b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
   from siac_t_class a,siac_r_causale_ep_class b
   where a.ente_proprietario_id=p_ente_proprietario_id
   and   b.classif_id=a.classif_id
  -- and b.validita_fine is null
   and   a.data_cancellazione is null
  -- and b.data_cancellazione is null
   and (b.data_cancellazione IS NULL -- SIAC-5941 Integrazione
       or
       b.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
      )
  )
  select movep.*,
         movepdet.* ,
         pdc.cod_piano_finanziario,pdc.desc_piano_finanziario,
         null::integer anno_movimento,
         null::numeric numero_movimento,
         null::varchar cod_submovimento,
         null::integer anno_ordinativo,
		 null::numeric num_ordinativo,
		 null::varchar num_subordinativo,
		 null::integer anno_liquidazione,
		 null::numeric num_liquidazione,
		 -- SIAC-5573
		 null::integer doc_id,
		 null::integer anno_doc,
		 null::varchar num_doc,
		 null::varchar cod_tipo_doc,
		 null::timestamp data_emissione_doc,
		 null::varchar cod_sogg_doc,
		 null::integer num_subdoc,
		 null::varchar modifica_impegno,
		 case -- SIAC-5601
		  when movepdet.cod_ambito = 'AMBITO_GSA' then
	       case when movep.cod_tipo_mov_finanziario = 'RE' then 'U' else 'E' end
		  else pdc.entrate_uscite
		  end entrate_uscite,
		  -- pdc.entrate_uscite,
		 p_data data_elaborazione,
	     ricecon.numero_ricecon
   from movep
        left join movepdet on movep.movep_id=movepdet.movep_id
        left join ricecon  on movep.campo_pk_id=ricecon.ricecon_id
        left join pdc      on movep.causale_ep_id=pdc.causale_ep_id
) as tbricecon

union
-- mod
select tbmod.*
from
(
 with
 movep as
 (
  select distinct
		 a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno,
	     m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,
    	 m.pnota_progressivogiornale num_definitivo_prima_nota,
		 m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
		 o.pnota_stato_code cod_stato_prima_nota,
		 o.pnota_stato_desc desc_stato_prima_nota,
		 l.movep_id, --da non visualizzare
		 l.movep_code cod_mov_ep,
		 l.movep_desc desc_mov_ep,
		 q.causale_ep_code cod_causale,
		 q.causale_ep_desc desc_causale,
	  	 r.causale_ep_tipo_code cod_tipo_causale,
		 r.causale_ep_tipo_desc desc_tipo_causale,
	     t.causale_ep_stato_code cod_stato_causale,
	     t.causale_ep_stato_desc desc_stato_causale,
	     c.evento_code cod_evento,
         c.evento_desc desc_evento,
         d.collegamento_tipo_code cod_tipo_mov_finanziario,
         d.collegamento_tipo_desc desc_tipo_mov_finanziario,
         b.campo_pk_id ,
         q.causale_ep_id,
         g.evento_tipo_code as tipo_evento -- SIAC-5641
   FROM siac_t_reg_movfin a,
        siac_r_evento_reg_movfin b,
        siac_d_evento c,
        siac_d_collegamento_tipo d,
        siac_r_reg_movfin_stato e,
        siac_d_reg_movfin_stato f,
        siac_d_evento_tipo g,
        siac_t_bil h,
        siac_t_periodo i,
        siac_t_mov_ep l,
        siac_t_prima_nota m,
        siac_r_prima_nota_stato n,
        siac_d_prima_nota_stato o,
        siac_t_ente_proprietario p,
        siac_t_causale_ep q,
/*        left join siac_r_causale_ep_stato s on s.causale_ep_id=q.causale_ep_id -- SIAC-5696 INIZIO
                                             and s.data_cancellazione is null
                                             and s.validita_fine is null
         left join siac_d_causale_ep_stato t on s.causale_ep_stato_id=t.causale_ep_stato_id
                                             and t.data_cancellazione is null, -- SIAC-5696 FINE  */
        siac_r_causale_ep_stato s, -- SIAC-5941
        siac_d_causale_ep_stato t, -- SIAC-5941
        siac_d_causale_ep_tipo r
   WHERE a.ente_proprietario_id=p_ente_proprietario_id
   and   i.anno=p_anno_bilancio
   and   a.regmovfin_id = b.regmovfin_id
   and   c.evento_id = b.evento_id
   AND   d.collegamento_tipo_id = c.collegamento_tipo_id
   AND   g.evento_tipo_id = c.evento_tipo_id
   AND   e.regmovfin_id = a.regmovfin_id
   AND   f.regmovfin_stato_id = e.regmovfin_stato_id
   AND   p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data)
   and   p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data)
 --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
 --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
   and   h.bil_id = a.bil_id
   AND   i.periodo_id = h.periodo_id
   AND   l.regmovfin_id = a.regmovfin_id
   AND   l.regep_id = m.pnota_id
   AND   m.pnota_id = n.pnota_id
   AND   o.pnota_stato_id = n.pnota_stato_id
   AND   p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data)
 --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
   and   p.ente_proprietario_id=a.ente_proprietario_id
   and   q.causale_ep_id=l.causale_ep_id
   AND   r.causale_ep_tipo_id=q.causale_ep_tipo_id
   and   s.causale_ep_id=q.causale_ep_id -- SIAC-5941 -- SIAC-5696
   and   s.causale_ep_stato_id=t.causale_ep_stato_id  -- SIAC-5941 -- SIAC-5696
 --s.validita_fine is NULL and -- SIAC-5696
   and   o.pnota_stato_code <> 'A'
   and   a.data_cancellazione IS NULL AND
         b.data_cancellazione IS NULL AND
         c.data_cancellazione IS NULL AND
         d.data_cancellazione IS NULL AND
         e.data_cancellazione IS NULL AND
         f.data_cancellazione IS NULL AND
         g.data_cancellazione IS NULL AND
         h.data_cancellazione IS NULL AND
         i.data_cancellazione IS NULL AND
         l.data_cancellazione IS NULL AND
         m.data_cancellazione IS NULL AND
         n.data_cancellazione IS NULL AND
         o.data_cancellazione IS NULL AND
         p.data_cancellazione IS NULL AND
        --q.data_cancellazione IS NULL AND -- SIAC-5696
         r.data_cancellazione IS NULL
          --s.data_cancellazione IS NULL AND -- SIAC-5696
          --t.data_cancellazione IS NULL -- SIAC-5696
  and (q.data_cancellazione is NULL -- SIAC-5696 INIZIO
               OR
               q.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
       )-- SIAC-5696 FINE
  and d.collegamento_tipo_code in ('MMGE','MMGS')
  and ((s.data_cancellazione is null and s.validita_fine is null) -- SIAC-5941 Integrazione INIZIO
                or s.causale_ep_stato_id =
               (select d_caus_stato.causale_ep_stato_id
                from   siac_d_causale_ep_stato d_caus_stato
                where  d_caus_stato.causale_ep_stato_id = s.causale_ep_stato_id
                and    d_caus_stato.causale_ep_stato_code = 'V'
                )
       )  -- SIAC-5941 Integrazione FINE
),
movepdet as
(
 with
 aa as
 (
  select a.movep_id, b.pdce_conto_id,
  	     a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
	     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
	     b.pdce_conto_code cod_piano_dei_conti,
	     b.pdce_conto_desc desc_piano_dei_conti,
	     b.livello livello_piano_dei_conti,
	     b.ordine ordine_piano_dei_conti,
	     d.pdce_fam_code cod_pdce_fam,
	     d.pdce_fam_desc desc_pdce_fam,
		 e.ambito_code cod_ambito, e.ambito_desc desc_ambito
  From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c,siac_d_pdce_fam d,siac_d_ambito e
  where a.ente_proprietario_id=p_ente_proprietario_id
    and b.pdce_conto_id=a.pdce_conto_id
    and c.pdce_fam_tree_id=b.pdce_fam_tree_id
    and d.pdce_fam_id=c.pdce_fam_id
    and c.validita_fine is null
    and e.ambito_id=a.ambito_id
    and a.data_cancellazione is null
 --   and b.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
    and c.data_cancellazione is null
    and d.data_cancellazione is null
    and e.data_cancellazione is null
 ),
 bb as
 (
/*
SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
 SELECT c.pdce_conto_id,
        case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
			 when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
			 when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
		     when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
			 when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
	         when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
			 when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
			 else ''::varchar end as tipo_codifica,
		     a.codice_codifica_albero
 FROM siac_v_dwh_codifiche_econpatr a,
      siac_r_pdce_conto_class b,
	  siac_t_pdce_conto c
 WHERE b.classif_id = a.classif_id
 AND   c.pdce_conto_id = b.pdce_conto_id
 and   c.ente_proprietario_id=p_ente_proprietario_id
-- and   c.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
 and   b.data_cancellazione is NULL
 and   b.validita_fine is null
)
select aa.*,
       bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio
from aa left join  bb on aa.pdce_conto_id=bb.pdce_conto_id
) ,
mod as
(
 select d.mod_id,
 	    c.movgest_anno v_movgest_anno, c.movgest_numero v_movgest_numero,
		b.movgest_ts_code cod_submovimento,
        tsTipo.movgest_ts_tipo_code
 FROM   siac_t_movgest_ts_det_mod a,siac_T_movgest_ts b,
        siac_t_movgest c,siac_t_modifica d, siac_r_modifica_stato e, siac_d_modifica_stato f,siac_d_movgest_ts_tipo tsTipo
 WHERE a.ente_proprietario_id = p_ente_proprietario_id
   and a.mod_stato_r_id=e.mod_stato_r_id
   and e.mod_id=d.mod_id
   and f.mod_stato_id=e.mod_stato_id
   and a.movgest_ts_id=b.movgest_ts_id
   and b.movgest_id=c.movgest_id
   AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
   AND    p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
   AND    a.data_cancellazione IS NULL
   AND    b.data_cancellazione IS NULL
   AND    c.data_cancellazione IS NULL
   AND    d.data_cancellazione IS NULL
   AND    e.data_cancellazione IS NULL
   AND    f.data_cancellazione IS NULL
   AND tsTipo.movgest_ts_tipo_id = b.movgest_ts_tipo_id
 UNION
  select d.mod_id,
  		 c.movgest_anno v_movgest_anno, c.movgest_numero v_movgest_numero,
		 b.movgest_ts_code cod_submovimento,
         tsTipo.movgest_ts_tipo_code
  FROM   siac_r_movgest_ts_sog_mod a,siac_T_movgest_ts b, siac_t_movgest c,
         siac_t_modifica d, siac_r_modifica_stato e, siac_d_modifica_stato f,siac_d_movgest_ts_tipo tsTipo
  WHERE  a.ente_proprietario_id = p_ente_proprietario_id
	and  a.mod_stato_r_id=e.mod_stato_r_id
	and  e.mod_id=d.mod_id
	and  f.mod_stato_id=e.mod_stato_id
	and  a.movgest_ts_id=b.movgest_ts_id
	and  b.movgest_id=c.movgest_id
	AND  p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
    AND  p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
    AND  a.data_cancellazione IS NULL
    AND  b.data_cancellazione IS NULL
    AND  c.data_cancellazione IS NULL
    AND  d.data_cancellazione IS NULL
    AND  e.data_cancellazione IS NULL
    AND  f.data_cancellazione IS NULL
    AND  tsTipo.movgest_ts_tipo_id = b.movgest_ts_tipo_id
),
pdc as
(
 select distinct a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
	    b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
 from siac_t_class a,siac_r_causale_ep_class b
 where a.ente_proprietario_id=p_ente_proprietario_id
  and  b.classif_id=a.classif_id
  -- and b.validita_fine is null
  and  a.data_cancellazione is null
  -- and b.data_cancellazione is null
  and (b.data_cancellazione IS NULL -- SIAC-5941 Integrazione
       or
       b.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
      )
)
select movep.*,
       movepdet.*,--, case when mod.mod_id is not null then 'S' else 'N' end modifica_impegno
       pdc.cod_piano_finanziario,pdc.desc_piano_finanziario,
       mod.v_movgest_anno anno_movimento,mod.v_movgest_numero numero_movimento,
   -- SIAC-5685
   -- mod.cod_submovimento
      case when mod.movgest_ts_tipo_code='T' then null::varchar else mod.cod_submovimento end cod_submovimento,
      null::integer anno_ordinativo,
      null::numeric num_ordinativo,
	  null::varchar num_subordinativo,
	  null::integer anno_liquidazione,
	  null::numeric num_liquidazione,
	  -- SIAC-5573
	  null::integer doc_id,
	  null::integer anno_doc,
	  null::varchar num_doc,
	  null::varchar cod_tipo_doc,
	  null::timestamp data_emissione_doc,
	  null::varchar cod_sogg_doc,
	  null::integer num_subdoc,
	  case when mod.mod_id is not null then 'S' else 'N' end modifica_impegno,
	  case -- SIAC-5601
	   when movepdet.cod_ambito = 'AMBITO_GSA' then
        case
         when movep.cod_tipo_mov_finanziario = 'MMGE' then 'E' else 'U' end
      else  pdc.entrate_uscite
	  end entrate_uscite,
	  -- pdc.entrate_uscite,
	  p_data data_elaborazione,
	  null::integer numero_ricecon
   from movep
        left join  movepdet on movep.movep_id=movepdet.movep_id
	    left join mod on  movep.campo_pk_id=  mod.mod_id
        left join pdc on movep.causale_ep_id=pdc.causale_ep_id
) as tbmod

--lib
union
select lib.*
from
(
with
movep as
(
select distinct
m.ente_proprietario_id,
p.ente_denominazione,
i.anno AS bil_anno,
m.pnota_desc desc_prima_nota,
m.pnota_numero num_provvisorio_prima_nota,
m.pnota_progressivogiornale num_definitivo_prima_nota,
m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
o.pnota_stato_code cod_stato_prima_nota,
o.pnota_stato_desc desc_stato_prima_nota,
l.movep_id,
l.movep_code cod_mov_ep,
l.movep_desc desc_mov_ep,
q.causale_ep_code cod_causale,
q.causale_ep_desc desc_causale,
r.causale_ep_tipo_code cod_tipo_causale,
r.causale_ep_tipo_desc desc_tipo_causale,
t.causale_ep_stato_code cod_stato_causale,
t.causale_ep_stato_desc desc_stato_causale,
NULL::varchar cod_evento,
NULL::varchar desc_evento,
NULL::varchar cod_tipo_mov_finanziario,
NULL::varchar desc_tipo_mov_finanziario,
NULL::integer campo_pk_id ,
q.causale_ep_id,
NULL::varchar evento_tipo_code
FROM
siac_t_prima_nota m,siac_d_causale_ep_tipo r,
siac_t_bil h,
siac_t_periodo i,
siac_t_mov_ep l,
siac_r_prima_nota_stato n,
siac_d_prima_nota_stato o,
siac_t_ente_proprietario p,
siac_t_causale_ep q,
siac_r_causale_ep_stato s,
siac_d_causale_ep_stato t
WHERE m.ente_proprietario_id=p_ente_proprietario_id
and r.causale_ep_tipo_code='LIB'
and i.anno=p_anno_bilancio
and h.bil_id = m.bil_id
AND i.periodo_id = h.periodo_id
AND l.regep_id = m.pnota_id
AND m.pnota_id = n.pnota_id
AND o.pnota_stato_id = n.pnota_stato_id
--p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
and p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data)
and p.ente_proprietario_id=m.ente_proprietario_id
and q.causale_ep_id=l.causale_ep_id
AND r.causale_ep_tipo_id=q.causale_ep_tipo_id
and s.causale_ep_id=q.causale_ep_id
AND s.causale_ep_stato_id=t.causale_ep_stato_id
and s.validita_fine is NULL
and o.pnota_stato_code <> 'A'
and
h.data_cancellazione IS NULL AND
i.data_cancellazione IS NULL AND
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
q.data_cancellazione IS NULL AND
r.data_cancellazione IS NULL AND
s.data_cancellazione IS NULL AND
t.data_cancellazione IS NULL
),
movepdet as
(
with aa as
(
select a.movep_id, b.pdce_conto_id,
a.movep_det_code cod_mov_ep_dettaglio,
a.movep_det_desc desc_mov_ep_dettaglio,
a.movep_det_importo importo_mov_ep,
a.movep_det_segno segno_mov_ep,
b.pdce_conto_code cod_piano_dei_conti,
b.pdce_conto_desc desc_piano_dei_conti,
b.livello livello_piano_dei_conti,
b.ordine ordine_piano_dei_conti,
d.pdce_fam_code cod_pdce_fam,
d.pdce_fam_desc desc_pdce_fam,
e.ambito_code cod_ambito,
e.ambito_desc desc_ambito
From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c ,siac_d_pdce_fam d,siac_d_ambito e
where a.ente_proprietario_id= p_ente_proprietario_id
and b.pdce_conto_id=a.pdce_conto_id
and c.pdce_fam_tree_id=b.pdce_fam_tree_id
and d.pdce_fam_id=c.pdce_fam_id
and c.validita_fine is null
and e.ambito_id=a.ambito_id
and a.data_cancellazione is null
--and b.data_cancellazione is null 28.06.2018 Sofia jira siac-6282
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
),
bb as
(
SELECT c.pdce_conto_id,
	   case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
			when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
			when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
			when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
			when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
			when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
			when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
			else ''::varchar end as tipo_codifica,
	a.codice_codifica_albero
FROM siac_v_dwh_codifiche_econpatr a,siac_r_pdce_conto_class b,siac_t_pdce_conto c
WHERE b.classif_id = a.classif_id
AND c.pdce_conto_id = b.pdce_conto_id
and c.ente_proprietario_id=p_ente_proprietario_id
--and c.data_cancellazione is null 28.06.2018 Sofia jira siac-6282
and b.data_cancellazione is NULL
and b.validita_fine is null
)
select aa.*,
	   bb.tipo_codifica||'.'||  bb.codice_codifica_albero cod_bilancio
from aa left join bb on aa.pdce_conto_id=bb.pdce_conto_id
)
select movep.*,
       movepdet.*,
	   null::varchar cod_piano_finanziario,
	   null::varchar desc_piano_finanziario,
	   null::integer anno_movimento,
	   null::numeric numero_movimento,
	   null::varchar cod_submovimento,
	   null::integer anno_ordinativo,
	   null::numeric num_ordinativo,
	   null::varchar num_subordinativo,
	   null::integer anno_liquidazione,
	   null::numeric num_liquidazione,
	   -- SIAC-5573
	   null::integer doc_id,
	   null::integer anno_doc,
	   null::varchar num_doc,
	   null::varchar cod_tipo_doc,
	   null::timestamp data_emissione_doc,
	   null::varchar cod_sogg_doc,
	   null::integer num_subdoc,
	   null::varchar modifica_impegno,
	   null::varchar entrate_uscite,
	   p_data data_elaborazione,
	   null::integer numero_ricecon
from movep left join movepdet on movep.movep_id=movepdet.movep_id
) as lib

) as tb;

esito:= 'Fine funzione carico contabilita_generale (FNC_SIAC_DWH_CONTABILITA_GENERALE) - '||clock_timestamp();
RETURN NEXT;


update siac_dwh_contabilita_generale dwh
  set codice_missione = fnc.code_missione,
      descri_missione = fnc.desc_missione,
      codice_programma = fnc.code_programma,
      descri_programma = fnc.desc_programma
from      "fnc_prima_nota_missione_programma"(p_ente_proprietario_id,p_anno_bilancio) fnc 
 where dwh.num_provvisorio_prima_nota  = fnc.pnota_numero 
 and   dwh.num_definitivo_prima_nota = fnc.pnota_progressivogiornale ;



update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;


EXCEPTION
WHEN others THEN
  esito:='Funzione carico contabilita_generale (FNC_SIAC_DWH_CONTABILITA_GENERALE) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$function$
;

-- SIAC-8863 Haitham 05.07.2023 fine

