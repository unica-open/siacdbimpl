/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR258_rend_gest_costi_missione_all_h_cont_gen" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  code_missione varchar,
  desc_missione varchar,
  codice_codifica varchar,
  descrizione_codifica varchar,
  codice_codifica_albero varchar,
  livello_codifica integer,
  importo_dare numeric,
  importo_avere numeric,
  elem_id integer,
  collegamento_tipo_code varchar,
  tipo_prima_nota varchar,
  pnota_id integer,
  campo_pk_id integer,
  campo_pk_id_2 integer
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
anno_competenza_int integer;
 
sqlQuery varchar;
idBilancio integer;
anno_bil_int integer;

BEGIN


/* 16/12/2021 - SIAC-8238.
	Funzione creata per il report BILR258 per la SIAC-8238.
    Questo report sistituisce a partire dal 2021 il report di rendiconto BILR166
    che rimane per gli anni precedenti.
    Rispetto al BILR166 i dati sono presi dalle scritture contabili (prime note)
    invece che dalla contabilita' finanziaria (capitoli).
    I dati estratti corrispondono esattamente a quelli del report BILR125 dove pero' 
    non sono raggruppati per missione.
    Per poter raggruppare per missione e' necessario passare dai capitoli che sono
    estratti partendo dalle prime note ed i relativi eventi differenti a seconda
    dell'entita' coinvolta (impegni, accertamenti, liquidazioni, modifiche...).

*/

code_missione:='';
desc_missione:='';
codice_codifica:='';
descrizione_codifica:='';
codice_codifica_albero:='';
livello_codifica:=0;
importo_dare:=0;
importo_avere:=0;
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
--SIAC-8698 21/04/2022.
--Devo estrarre con distinct senza estrarre l'elem_id perche' ci sono prime
--note di un anno bilancio collegate a capitoli sia dell'anno corrente che
--dell'anno successivi; in questo caso l'importo della prima nota
--veniva duplicato.
--Inoltre aggiungo anche campo_pk_id, campo_pk_id_2 nella query per essere
--certo di non escludere a causa del distinct le registrazioni che hanno
--2 importi uguali. 
select distinct
   case when query_totale.causale_ep_tipo_code = 'LIB' THEN
   		COALESCE(query_totale.code_miss_lib,'')::varchar
   else 
   		COALESCE(missioni.code_missione,'')::varchar end code_missione,
   case when query_totale.causale_ep_tipo_code = 'LIB' THEN
   		COALESCE(query_totale.desc_miss_lib,'')::varchar
   else
   		COALESCE(missioni.desc_missione,'')::varchar end desc_missione,
   COALESCE(query_totale.codice_codifica,'') codice_codifica,
   COALESCE(query_totale.descrizione_codifica,'') descrizione_codifica,
   COALESCE(query_totale.codice_codifica_albero,'') codice_codifica_albero,
   COALESCE(query_totale.livello_codifica,0) livello_codifica,
   COALESCE(query_totale.importo_dare,0) importo_dare,
   COALESCE(query_totale.importo_avere,0) importo_avere,
   --SIAC-8698 21/04/2022. Non estraggo il capitolo.
   0::integer elem_id,--COALESCE(query_totale.elem_id,0) elem_id,
   COALESCE(query_totale.collegamento_tipo_code,'') collegamento_tipo_code,
   COALESCE(query_totale.causale_ep_tipo_code,'') tipo_prima_nota,
   query_totale.pnota_id,
   --SIAC-8698 21/04/2022. Aggiungo questi campi
   query_totale.campo_pk_id, query_totale.campo_pk_id_2
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
    capitoli.elem_id
  from capitoli  
    full JOIN strut_bilancio on (strut_bilancio.programma_id =  capitoli.programma_id
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
         t_prima_nota.pnota_id         
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
        	--SIAC-8696 19/04/2022.
            --Era rimasto l'ide ente 3 invece che la variabile p_ente_prop_id
        --AND r_mov_ep_det_class.ente_proprietario_id=3
        AND r_mov_ep_det_class.ente_proprietario_id=p_ente_prop_id
        and d_class_tipo.classif_tipo_code='MISSIONE'
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
	pdce.movep_det_id, pdce.causale_ep_tipo_code, pdce.pnota_id,
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
 ) query_totale
on missioni.elem_id =query_totale.elem_id  
where COALESCE(query_totale.code_miss_lib,'') <> '' OR
	COALESCE(missioni.code_missione,'')  <> ''
--where (query_totale.codice_codifica_albero = '' OR
--		left(query_totale.codice_codifica_albero,1) <> 'A')
--order by missioni.code_missione, query_totale.codice_codifica;
order by 1, 3;

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
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR258_rend_gest_costi_missione_all_h_cont_gen" (p_ente_prop_id integer, p_anno varchar)
  OWNER TO siac;