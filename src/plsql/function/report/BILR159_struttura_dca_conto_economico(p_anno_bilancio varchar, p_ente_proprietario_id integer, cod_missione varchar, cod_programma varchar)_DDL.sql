/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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
  livello integer,
  pnota_id integer
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
  
  --siac 5536: 10/11/2017.
  --	Nella query dinamica si ottiene un errore se il nome ente 
  -- 	contiene un apice. Sostituisco l'apice con uno doppio.  
  nome_ente:=REPLACE(nome_ente,'''','''''');  
  
  select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
  where a.ente_proprietario_id = p_ente_proprietario_id 
  and b.periodo_id = a.periodo_id
  and b.anno = p_anno_bilancio;

/* 18/10/2017: resa dinamica la query perche' sono stati aggiunti i parametri 
	cod_missione e cod_programma */

/*SIAC-5525 Sostituito l'ordine delle tabelle nella query
Prima era:
  from cap
  left join dati_prime_note on cap.elem_id = dati_prime_note.elem_id 
e
  from clas left join capall on 
  clas.programma_id = capall.programma_id and    
  clas.macroag_id=capall.macroag_id 
Aggiunta inoltre la condizione

  where (dati_prime_note.elem_id is null or exists (select 1 
  from siac_t_bil_elem a
  where a.ente_proprietario_id = '||p_ente_proprietario_id||'
  and   a.elem_id = dati_prime_note.elem_id
  and   a.bil_id ='||bilancio_id||'
  and   a.data_cancellazione is null))   
  
per evitare di prendere in considerazione dati con capitoli appartenenti ad un anno di bilancio
diverso da quello inserito
  */ 
    
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
  b.livello,
  -- 03/06/2019 SIAC-6875
  -- aggiunto l''id della nota per essere certo di estrarre tutte le prime note anche
  -- a parita'' degli altri valori estratti.
  g.pnota_id
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
  -- 03/06/2019 SIAC-6875
  -- aggiunto l''id della nota per essere certo di estrarre tutte le prime note anche
  -- a parita'' degli altri valori estratti.
  prime_note.pnota_id,
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
  from dati_prime_note
  left join cap on cap.elem_id = dati_prime_note.elem_id
  where (dati_prime_note.elem_id is null or exists (select 1 
  from siac_t_bil_elem a
  where a.ente_proprietario_id = '||p_ente_proprietario_id||'
  and   a.elem_id = dati_prime_note.elem_id
  and   a.bil_id ='||bilancio_id||'
  and   a.data_cancellazione is null)) 
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
      capall.livello::integer,
      	-- 03/06/2019 SIAC-6875
  		-- aggiunto l''id della nota per essere certo di estrarre tutte le prime note anche
  		-- a parita'' degli altri valori estratti.
  	  capall.pnota_id
  from capall 
  left join clas on 
  clas.programma_id = capall.programma_id and    
  clas.macroag_id = capall.macroag_id
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
      capall.livello::integer,
      	-- 03/06/2019 SIAC-6875
  		-- aggiunto l''id della nota per essere certo di estrarre tutte le prime note anche
  		-- a parita'' degli altri valori estratti.
  	  capall.pnota_id      
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
      capall.livello::integer,
      	-- 03/06/2019 SIAC-6875
  		-- aggiunto l''id della nota per essere certo di estrarre tutte le prime note anche
  		-- a parita'' degli altri valori estratti.
  	  capall.pnota_id      
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
  b.livello,e.movep_det_id,
  -- 03/06/2019 SIAC-6875
  -- aggiunto l''id della nota per essere certo di estrarre tutte le prime note anche
  -- a parita'' degli altri valori estratti.
  g.pnota_id
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
    prime_note_lib.livello::integer,
    prime_note_lib.pnota_id  
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
    prime_note_lib.livello::integer,
      	-- 03/06/2019 SIAC-6875
  		-- aggiunto l''id della nota per essere certo di estrarre tutte le prime note anche
  		-- a parita'' degli altri valori estratti.
  	prime_note_lib.pnota_id      
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
    prime_note_lib.livello::integer,
      	-- 03/06/2019 SIAC-6875
  		-- aggiunto l''id della nota per essere certo di estrarre tutte le prime note anche
  		-- a parita'' degli altri valori estratti.
  	prime_note_lib.pnota_id         
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